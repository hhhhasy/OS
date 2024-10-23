#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system.h>
#include <stdio.h>
#include <assert.h>

#define MAX_ORDER 11 // Buddy system 的最大阶数
static free_area_t free_area[MAX_ORDER]; // 每个阶数一个空闲列表

static void buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_init(&free_area[i].free_list);
        free_area[i].nr_free = 0;
    }
}


static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    struct Page *p = base;
    for (; p!= base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }

    size_t order = MAX_ORDER-1;
    size_t order_size = 1 << order;
    size_t origin_size = n;
    p = base;

    while (origin_size!= 0) {
        p->property = order_size;
        SetPageProperty(p);
        free_area[order].nr_free += 1;
        list_add(&(free_area[order].free_list), &(p->page_link));
        origin_size -= order_size;
        while (order > 0 && origin_size < order_size) {
            order_size >>= 1;
            order -= 1;
        }
        p += order_size;
    }
}

static void cut_page(size_t n) {
    if (free_area[n].nr_free == 0) {
        cut_page(n + 1);
    }
    list_entry_t* le = list_next(&(free_area[n].free_list));
    struct Page *page = le2page(le, page_link);
    list_del(&(page->page_link));
    free_area[n].nr_free--;

    size_t i = n - 1;
    struct Page *buddy_page = page + (1 << i);
    buddy_page->property = (1 << i);
    page->property = (1 << i);
    SetPageProperty(buddy_page);
    
    list_add(&(free_area[i].free_list), &(page->page_link));
    list_add(&(page->page_link), &(buddy_page->page_link));
    free_area[i].nr_free += 2;
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    size_t order = 0;

    // 计算所需空间的最小阶数
    while ((1 << order) < n) {
        order++;
    }

    if (free_area[order].nr_free > 0) {
        // 找到第一个空闲块
        list_entry_t* le = list_next(&(free_area[order].free_list));
        struct Page *page = le2page(le, page_link);
        list_del(&(page->page_link));
        free_area[order].nr_free--;
        ClearPageProperty(page);
        return page;
    } else {
        cut_page(order + 1);
        list_entry_t* le = list_next(&(free_area[order].free_list));
        struct Page *page = le2page(le, page_link);
        list_del(&(page->page_link));
        free_area[order].nr_free--;
        ClearPageProperty(page);
        return page;
    }
}

// 该函数参考了学长代码
static void merge_page(uint32_t order, struct Page* base) {
    if (order == MAX_ORDER) {
        return;
    }

    // 尝试合并前一个页面
    list_entry_t* le = list_prev(&(base->page_link));
    if (le!= &(free_area[order].free_list)) {
        struct Page *prev_page = le2page(le, page_link);
        if (prev_page + prev_page->property == base) {
            prev_page->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = prev_page; // 更新 base 为合并后的页面
            list_del(&(base->page_link));
            if (free_area[order + 1].nr_free == 0) {
                list_add(&(free_area[order + 1].free_list), &(base->page_link));
                free_area[order + 1].nr_free++;
            } else {
                list_entry_t* le = &(free_area[order + 1].free_list);
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
                    struct Page* page = le2page(le, page_link);
                    if (base < page) {
                        list_add_before(le, &(base->page_link));
                        free_area[order + 1].nr_free++;
                        break;
                    } else if (list_next(le) == &(free_area[order + 1].free_list)) {
                        list_add(le, &(base->page_link));
                        free_area[order + 1].nr_free++;
                    }
                }
            }
        }
    }

    // 尝试合并后一个页面
    le = list_next(&(base->page_link));
    if (le!= &(free_area[order].free_list)) {
        struct Page *next_page = le2page(le, page_link);
        if (base + base->property == next_page) {
            base->property += next_page->property;
            ClearPageProperty(next_page);
            list_del(&(next_page->page_link));
            list_del(&(base->page_link));

            if (free_area[order + 1].nr_free == 0) {
                list_add(&(free_area[order + 1].free_list), &(base->page_link));
                free_area[order + 1].nr_free++;
            } else {
                list_entry_t* le = &(free_area[order + 1].free_list);
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
                    struct Page* page = le2page(le, page_link);
                    if (base < page) {
                        list_add_before(le, &(base->page_link));
                        free_area[order + 1].nr_free++;
                        break;
                    } else if (list_next(le) == &(free_area[order + 1].free_list)) {
                        list_add(le, &(base->page_link));
                        free_area[order + 1].nr_free++;
                    }
                }
            }
        }
    }

    // 递归合并
    merge_page(order + 1, base);
}

static void buddy_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p!= base + n; p++) {
        // assert(!PageReserved(p) &&!PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);

    size_t order = 0;
    while (n > 1) {
        n >>= 1;
        order++;
        
    }
    order++;
    

    if (free_area[order].nr_free == 0) {
        list_add(&(free_area[order].free_list), &(base->page_link));
        free_area[order].nr_free++;
    } else {
        list_entry_t* le = &(free_area[order].free_list);
        while ((le = list_next(le))!= &(free_area[order].free_list)) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                free_area[order].nr_free++;
                break;
            } else if (list_next(le) == &(free_area[order].free_list)) {
                list_add(le, &(base->page_link));
                free_area[order].nr_free++;
            }
        }
    }

    merge_page(order, base);
}

static size_t buddy_nr_free_pages(void) {
    size_t total = 0; // 使用 size_t 以处理较大的总和
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        // 使用 size_t 进行位移操作，避免潜在的溢出
        total += (size_t)(free_area[i].nr_free) << i;
    }
    return total;
}


static void buddy_check(void) {
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
    assert(total_free_pages == buddy_nr_free_pages());

    // 检查已分配页面的状态
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        while ((le = list_next(le))!= &free_area[i].free_list) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 确保页面的属性是正确的
        }
    }

    // 可以添加更多的检查逻辑，例如检查每个页面的引用计数
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages());
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("\n首先 p0 请求 5 页\n");
    p0 = buddy_alloc_pages(5);
    
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    cprintf("\n然后 p1 请求 5 页\n");
    p1 = buddy_alloc_pages(5);
    
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    cprintf("\n最后 p2 请求 1023页\n");
    p2 = buddy_alloc_pages(1023);
    
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    
    cprintf("\n p0 的虚拟地址 0x%016lx.\n", p0);
    cprintf("\n p1 的虚拟地址 0x%016lx.\n", p1);
    cprintf("\n p2 的虚拟地址 0x%016lx.\n", p2);
    
    
    cprintf("\n 收回p0\n");
    buddy_free_pages(p0,5);
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    cprintf("\n 收回p1\n");
    buddy_free_pages(p1,5);
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    cprintf("\n 收回p2\n");
    buddy_free_pages(p2,1023);
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
    }
    
    cprintf("\n");
    
    
}


const struct pmm_manager buddy_system_pmm_manager = {
   .name = "buddy_system_pmm_manager",
   .init = buddy_init,
   .init_memmap = buddy_init_memmap,
   .alloc_pages = buddy_alloc_pages,
   .free_pages = buddy_free_pages,
   .nr_free_pages = buddy_nr_free_pages,
   .check = buddy_check,
};
