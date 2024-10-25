#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#define MAX_ORDER 11 // Buddy system 的最大阶数
static free_area_t free_area[MAX_ORDER]; // 每个阶数一个空闲列表

// 小块内存管理结构
struct SlubBlock
{
    size_t size;            // 小块的大小
    void *page;             // 指向分配的页面
    struct SlubBlock *next; // 指向下一个小块
};

// 小块内存链表头指针
static struct SlubBlock *slub_small_block_list = NULL;

static void slub_init(void)
{
    for (int i = 0; i < MAX_ORDER; i++)
    {
        list_init(&free_area[i].free_list); // 初始化每个阶的空闲列表
        free_area[i].nr_free = 0;          // 初始化每个阶的空闲页面计数
    }
}

static void slub_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0); // 确保请求的页面数量大于 0

    for (struct Page *p = base; p!= base + n; p++)
    {
        assert(PageReserved(p)); // 确保页面是保留的
        p->flags = p->property = 0; // 清除标志和属性
        set_page_ref(p, 0); // 设置引用计数为 0
    }

    size_t order = MAX_ORDER - 1;
    size_t order_size = 1 << order; // 计算当前阶的大小
    size_t origin_size = n;

    for (struct Page *p = base; origin_size!= 0; p += order_size)
    {
        p->property = order_size;
        SetPageProperty(p);
        free_area[order].nr_free++;
        list_add(&(free_area[order].free_list), &(p->page_link)); // 将页加入空闲列表
        origin_size -= order_size; // 减少剩余未处理的页面数量

        while (order > 0 && origin_size < order_size)
        {
            order_size >>= 1;
            order--;
        }
    }
}

static void cut_page(size_t n)
{
    while (n < MAX_ORDER && free_area[n].nr_free == 0)
    {
        n++; // 查找下一个有空闲页面的阶
    }
    if (n == MAX_ORDER)
        return; // 如果没有可用的阶，则返回

    list_entry_t *le = list_next(&(free_area[n].free_list));
    struct Page *page = le2page(le, page_link); // 获取空闲页
    list_del(&(page->page_link)); // 从空闲列表中删除
    free_area[n].nr_free--; // 更新空闲页面计数

    size_t i = n - 1; // 减小阶数
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
    buddy_page->property = (1 << i); // 设置伙伴页的属性
    page->property = (1 << i); // 设置当前页的属性
    SetPageProperty(buddy_page); // 标记伙伴页

    list_add(&(free_area[i].free_list), &(page->page_link)); // 将当前页加入到较小阶的空闲列表
    list_add(&(buddy_page->page_link), &(free_area[i].free_list)); // 将伙伴页加入到空闲列表
    free_area[i].nr_free += 2; // 更新空闲页面计数
}

static struct Page *buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    size_t order = 0;

    while ((1 << order) < n)
    {
        order++; // 计算所需的阶数
    }

    if (order >= MAX_ORDER)
        return NULL; // 请求的页面数超过最大阶数

    if (free_area[order].nr_free > 0)
    {
        list_entry_t *le = list_next(&(free_area[order].free_list));
        struct Page *page = le2page(le, page_link); // 获取空闲页
        list_del(&(page->page_link)); // 从空闲列表中删除
        free_area[order].nr_free--; // 更新空闲页面计数
        ClearPageProperty(page); // 清除页面属性
        return page; // 返回分配的页面
    }
    else
    {
        cut_page(order + 1); // 切割页面以获取所需大小
        return buddy_alloc_pages(n); // 递归调用以重新分配
    }
}

static void merge_page(size_t order, struct Page *base)
{
    if (order >= MAX_ORDER)
        return; // 超过最大阶数则返回

    list_entry_t *le = list_prev(&(base->page_link));
    if (le!= &(free_area[order].free_list))
    {
        struct Page *prev_page = le2page(le, page_link);
        if (prev_page + prev_page->property == base)
        {
            prev_page->property += base->property; // 合并相邻的页面
            ClearPageProperty(base); // 清除被合并页面的属性
            list_del(&(base->page_link)); // 从空闲列表中删除
            base = prev_page; // 更新基地址
            list_del(&(base->page_link)); // 从空闲列表中删除
            list_add(&(free_area[order + 1].free_list), &(base->page_link)); // 将合并后的页面加入空闲列表
            free_area[order + 1].nr_free++; // 更新空闲页面计数
        }
    }

    le = list_next(&(base->page_link));
    if (le!= &(free_area[order].free_list))
    {
        struct Page *next_page = le2page(le, page_link);
        if (base + base->property == next_page)
        {
            base->property += next_page->property; // 合并相邻的页面
            ClearPageProperty(next_page); // 清除被合并页面的属性
            list_del(&(next_page->page_link)); // 从空闲列表中删除
            list_del(&(base->page_link)); // 从空闲列表中删除
            list_add(&(free_area[order + 1].free_list), &(base->page_link)); // 将合并后的页面加入空闲列表
            free_area[order + 1].nr_free++; // 更新空闲页面计数
        }
    }

    merge_page(order + 1, base); // 递归合并相邻页面
}

static void buddy_free_pages(struct Page *base, size_t n)
{
    struct Page *p = base;
    for (; p < base + n; p++)
    {
        // assert(!PageReserved(p) &&!PageProperty(p)); // 确保释放的页面是可用的
        p->flags = 0; // 清除标志
        set_page_ref(p, 0); // 设置引用计数为 0
    }
    base->property = n; // 设置释放页面的属性
    SetPageProperty(base); // 标记该页为页表

    size_t order = 0;
    while (n > 1)
    {
        n >>= 1; // 计算阶数
        order++;
    }
    order++; // 增加阶数

    list_entry_t *le = &(free_area[order].free_list);
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
    free_area[order].nr_free++; // 更新空闲页面计数

    merge_page(order, base); // 合并相邻的空闲页面
}

static size_t slub_nr_free_pages(void)
{
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++)
    {
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
    }
    return total; // 返回总的空闲页面数
}

// 初始化小块分配链表
static void slub_init_small_blocks()
{
    slub_small_block_list = NULL;
}

// 释放小块内存
static void slub_free_small(void *ptr, size_t size)
{
    if (ptr == NULL)
    {
        return;
    }
    struct SlubBlock *block = (struct SlubBlock *)ptr - 1;
    block->size += size;
    struct SlubBlock *temp = slub_small_block_list;
    if (temp == NULL || temp->size > block->size)
    {
        block->next = temp;
        slub_small_block_list = block;
        return;
    }
    while (temp->next!= NULL && temp->next->size < block->size)
    {
        temp = temp->next;
    }
    block->next = temp->next;
    temp->next = block;
}

// 分配小块内存
static void *slub_alloc_small(float size)
{
    size_t total_size = size;
    struct SlubBlock *temp = slub_small_block_list;
    while (temp!= NULL)
    {
        if (temp->size >= total_size)
        {
            struct SlubBlock *block = temp;
            slub_small_block_list = temp->next;
            return (void *)(block + 1);
        }
        else
        {
            temp = temp->next;
        }
    }
    // 没有找到匹配项
    struct Page *page = buddy_alloc_pages(1); // 分配一个页
    if (page == NULL)
    {
        return NULL; // 分配失败
    }
    struct SlubBlock *current_block = (struct SlubBlock *)page; // 获取页面指针
    current_block->size = 0;                                    // 设置大小
    slub_free_small((void *)(current_block + 1), 1);
    return (void *)(current_block + 1);
}

// 分配内存
static struct Page *slub_alloc(size_t size)
{
    if (size >= (1 << MAX_ORDER))
    {
        return NULL;
    }
    if (size >= 1 << (MAX_ORDER - 1))
    {
        return buddy_alloc_pages(size >> (MAX_ORDER - 1));
    }
    else
    {
        void *small_block_ptr = slub_alloc_small(size);
        if (small_block_ptr)
        {
            struct SlubBlock *block = (struct SlubBlock *)small_block_ptr - 1;
            return block->page;
        }
        return NULL;
    }
}

// 释放内存
static void slub_free(struct Page *ptr, size_t size)
{
    if (size >= 1 << (MAX_ORDER - 1))
    {
        buddy_free_pages(ptr, size >> (MAX_ORDER - 1));
    }
    else
    {
        slub_free_small(ptr, size);
    }
}
static void slub_check(void) {
    int total_free_pages = 0;

    // 检查每个阶数的空闲列表
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        int count = 0;
        while ((le = list_next(le))!= &free_area[i].free_list) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 每个页面应该标记为已分配
            count++;
            total_free_pages += p->property;
        }
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
    }

    // 检查总的空闲页面数是否一致
    assert(total_free_pages == slub_nr_free_pages());

    // 检查已分配页面的状态
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        while ((le = list_next(le))!= &free_area[i].free_list) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 确保页面的属性是正确的
        }
    }

    // 可以添加更多的检查逻辑，例如检查每个页面的引用计数
    cprintf("总空闲块数目为：%d\n", slub_nr_free_pages()); // 输出空闲块数
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free); // 输出每个阶的空闲块数
    }
    
    // 请求页面示例
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("\n首先 p0 请求 5 页\n");
    p0 = buddy_alloc_pages(5);
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n然后 p1 请求 5 页\n");
    p1 = buddy_alloc_pages(5);
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n最后 p2 请求 1023页\n");
    p2 = buddy_alloc_pages(1023);
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n p0 的虚拟地址 0x%016lx.\n", p0);
    cprintf("\n p1 的虚拟地址 0x%016lx.\n", p1);
    cprintf("\n p2 的虚拟地址 0x%016lx.\n", p2);
    
    
    cprintf("\n 收回p0\n");
    buddy_free_pages(p0,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n 收回p1\n");
    buddy_free_pages(p1,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n 收回p2\n");
    buddy_free_pages(p2,1023);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
    }
    
    cprintf("\n");

    //cprintf("总小块内存数目为：%d\n", total_small_blocks);

    // 请求页面和小块内存示例
    // struct Page *p0 = NULL;
    void *small_block_ptr = NULL;

    

    cprintf("\n然后请求小块内存（大小为 128）\n");
    small_block_ptr = slub_alloc_small(128);
    cprintf("小块内存分配成功\n");

    

    cprintf("\n收回小块内存\n");
    slub_free_small(small_block_ptr, 128);
    cprintf("小块内存回收成功\n");

    cprintf("\n");
}
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc,
    .free_pages = slub_free,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};
