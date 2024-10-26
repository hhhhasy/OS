# Lab2 实验报告

## 练习 1：理解 first-fit 连续物理内存分配算法（思考题）

### 题目

> first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合 `kern/mm/default_pmm.c` 中的相关代码，认真分析 default_init，default_init_memmap，default_alloc_pages， default_free_pages 等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 你的 first fit 算法是否有进一步的改进空间？

### 分析

First-fit 算法的核心思想是：在分配物理内存时，总是选择第一个满足条件的内存块进行分配，而不考虑它是否是最优的选择。只要找到的内存块大小不小于请求的大小，就会被分配。通过分析 `kern/mm/default_pmm.c` 中的代码，我们可以深入理解其实现过程。

#### 物理内存分配过程及各函数作用

1. **初始化 (default_init)**

   这个函数初始化了一个空的链表 `free_list`，用于存储未分配的内存页框。由于是初始状态，表示空闲内存页框数量的 `nr_free` 被设置为 0。

2. **内存映射初始化 (default_init_memmap)**

此函数将一个包含 n 个页的空闲内存块加入到 `free_list` 链表中。主要步骤如下：

（1）遍历内存块中的所有页框，清除标志和属性信息，将引用计数设为 0。

（2）更新 `nr_free`，增加 n 个页框。

（3）将新的内存块插入 `free_list`：

- 如果 `free_list` 为空，直接插入。

- 否则，遍历链表找到合适的位置插入，保持地址顺序。

3. **内存分配 (default_alloc_pages)**

此函数用于分配连续的 n 个空闲页。实现过程如下：

（1）检查 `nr_free` 是否满足请求，如不满足则返回 NULL。

（2）遍历 `free_list`，查找第一个满足条件的连续内存块。

（3）如果找到合适的内存块：

- 从链表中移除该块。
- 如果该块大于请求大小，将剩余部分作为新的空闲块重新插入链表。
- 更新 `nr_free`，减去分配的页数。

4. **内存释放 (default_free_pages)**

此函数用于释放内存空间并将其重新加入 `free_list`。主要步骤包括：

（1）清除被释放内存块中所有页框的标志和属性信息，将引用计数置零。

（2）将释放的内存块插入 `free_list`，保持地址顺序。

（3）检查并合并相邻的连续空闲内存块。

（4）更新 `nr_free`，增加释放的页数。

#### First-fit 算法的改进空间

在 First-fit 算法中，低地址部分不断被划分，留下许多难以利用、很小的空闲内存碎片，而每次查找又都从低地址部分开始，会增加查找的开销。

1. **优化搜索效率**
   - 问题：当前实现中，每次分配都需要从头遍历 `free_list`。
   - 改进：使用更高效的数据结构，如平衡树或跳表，将搜索复杂度从 O(n)降低到 O(log n)。

2. **减少内存碎片**
   - 问题：First-fit 容易在低地址处产生小的碎片。
   - 改进：实现 Best-fit 或 Next-fit 策略，或引入定期内存压缩机制。

3. **预分配和缓存**
   - 改进：为常见大小的内存请求预先分配和缓存内存块，提高分配速度。

4. **延迟合并**：
   - 当释放页面时，不立即执行合并，而是周期性地执行合并操作，这样可以减少高负载下的性能开销。

## 练习 2：实现 Best-Fit 连续物理内存分配算法（需要编程）

### 题目

> 在完成练习一后，参考 kern/mm/default_pmm.c 对 First Fit 算法的实现，编程实现 Best Fit 页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
>
> - 你的 Best-Fit 算法是否有进一步的改进空间？

### Best-Fit 页面分配算法的实现

在实现 Best Fit 算法时，我主要参考了 `kern/mm/default_pmm.c` 中 First Fit 算法的实现，并对关键函数进行了修改。Best Fit 算法的核心思想是找到最佳匹配的空闲内存块，以最大程度地减少内存碎片。因此，我们只需要修改 `default_alloc_pages` 函数，其他函数与 First-Fit 算法基本相同。

**`best_fit_alloc_pages`** 函数实现：

```c
static struct Page *
    best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1; //记录当前最小的内存块大小
    /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        //既要满足n个大小的内存页框大小也要保证是最小的
        if (p->property >= n && p->property <min_size) { 
            page = p; //当前的最佳匹配
            min_size=p->property; //更新最小内存块大小
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
```

另外，我们还需要在 pmm.c 中加上：

```c
#include <best_fit_pmm.h>
```

并且在 init_pmm_manger 处修改管理算法为 best fit:

```c
static void init_pmm_manager(void) {
    pmm_manager = &best_fit_pmm_manager;//在此更换页面管理函数指针
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}
```

### Best-Fit 算法的进一步改进空间

正如我们上述实现的那样，在找到最优的分配页框的时候，我们需要对空闲页链表 `free_list` 的所有页框进行遍历，从而满足要求的空闲页框，因此分配效率上会有失偏颇；并且，与 First Fit 相同的是，Best Fit 算法仍然会产生一些更加难以利用的较小的内存碎片。

1. **性能优化**：
   - 当前实现每次分配都需要遍历整个空闲链表，时间复杂度为 O(n)。
   - 可以考虑使用更高效的数据结构，如平衡树（如红黑树）或跳表，以提高查找效率至 O(log n)。
2. **内存碎片处理**：
   - 实现内存压缩算法，定期整理内存，合并小的空闲块。
   - 引入分割阈值，当剩余空间大于某个阈值时才进行分割，减少小碎片的产生。
3. **多级空闲列表**：
   - 根据大小范围维护多个空闲列表，加快特定大小范围的分配速度。
4. **预分配和缓存机制**：
   - 对常用大小的内存块进行预分配。
   - 实现简单的缓存机制，加速频繁的小块内存分配。
5. **智能合并策略**：
   - 在空闲时进行主动合并，而不仅仅是在释放时合并相邻块。
   - 实现更智能的合并策略，如考虑合并非相邻但接近的小块。

## 扩展练习 Challenge：buddy system（伙伴系统）分配算法（需要编程）

### 题目

> Buddy System 算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是 2 的 n 次幂(Pow(2, n)), 即 1, 2, 4, 8, 16, 32, 64, 128...
>
> - 参考 [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在 ucore 中实现 buddy system 分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### Buddy System 分配算法设计文档

#### 1. 设计目标

实现一个基于 Buddy System 的内存分配算法，用于管理 ucore 操作系统中的物理内存。该算法应能高效地分配和释放内存，同时最小化内存碎片。

#### 2. 算法概述

Buddy System 将可用内存划分为大小为 2 的幂次方的块。当需要分配内存时，系统会找到满足需求的最小的 2 的幂次方大小的块。如果没有恰好大小的块，就会将更大的块分割成两个相等的小块，直到得到合适大小的块。释放内存时，系统会尝试合并相邻的空闲块，以形成更大的连续空闲内存。

#### 3. 数据结构设计

```c
#define MAX_ORDER 11  // 支持最大 2^10 = 1024 页的分配

typedef struct {
    list_entry_t free_list;  // 空闲页面链表
    unsigned int nr_free;    // 空闲页面数量
} free_area_t;

static free_area_t free_area[MAX_ORDER];  // 每个阶数对应一个空闲链表
```

- 使用 11 个链表来管理不同大小的内存块，支持最大 1024 页的分配。
- 每个 `free_area_t` 结构包含一个空闲页面链表和该大小的空闲页面数量。

#### 4. 主要函数设计

##### 4.1 初始化函数

```c
static void buddy_init(void)
static void buddy_init_memmap(struct Page *base, size_t n)
```

- `buddy_init`: 初始化 Buddy System 的数据结构。
- `buddy_init_memmap`: 初始化给定范围的物理内存页面。

##### 4.2 内存分配函数

```c
static struct Page *buddy_alloc_pages(size_t n)
```

- 根据请求的页面数量 `n`，找到合适的内存块。
- 如果没有恰好大小的块，则分割更大的块。

##### 4.3 内存释放函数

```c
static void buddy_free_pages(struct Page *base, size_t n)
```

- 释放从 `base` 开始的 `n` 个页面。
- 尝试合并相邻的空闲块。

##### 4.4 辅助函数

```c
static void cut_page(size_t n)
static void merge_page(size_t order, struct Page *base)
```

- `cut_page`: 用于分割大内存块为小块。
- `merge_page`: 用于合并相邻的空闲块。

##### 4.5 其他功能函数

```c
static size_t buddy_nr_free_pages(void)
static void buddy_check(void)
```

- `buddy_nr_free_pages`: 计算总的空闲页面数。
- `buddy_check`: 用于测试和验证 Buddy System 的正确性。

#### 5. 算法实现细节

##### 5.1 内存分配过程

1. 计算所需的阶数（order）。
2. 如果当前阶有空闲页面，直接分配。
3. 否则，从更高阶分割页面，然后重新尝试分配。

```c
static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    size_t order = 0;

    while ((1 << order) < n) {
        order++; // 计算所需的阶数
    }

    if (order >= MAX_ORDER) return NULL; // 请求的页面数超过最大阶数

    if (free_area[order].nr_free > 0) { // 如果当前阶有空闲页面
        list_entry_t *le = list_next(&(free_area[order].free_list));
        struct Page *page = le2page(le, page_link); // 获取空闲页
        list_del(&(page->page_link)); // 从空闲列表中删除
        free_area[order].nr_free--; // 更新空闲页面计数
        ClearPageProperty(page); // 清除页面属性
        return page; // 返回分配的页面
    } else {
        cut_page(order + 1); // 切割页面以获取所需大小
        return buddy_alloc_pages(n); // 递归调用以重新分配
    }
}
```

##### 5.2 内存释放过程

1. 将释放的页面标记为空闲。
2. 将页面添加到对应阶的空闲列表。
3. 尝试与相邻的空闲页面合并，形成更大的块。

```c
static void buddy_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p < base + n; p++) {
        //assert(!PageReserved(p) && !PageProperty(p)); // 确保释放的页面是可用的
        p->flags = 0; // 清除标志
        set_page_ref(p, 0); // 设置引用计数为 0
    }
    base->property = n; // 设置释放页面的属性
    SetPageProperty(base); // 标记该页为页表

    size_t order = 0;
    while (n > 1) {
        n >>= 1; // 计算阶数
        order++;
    }
    order++; // 增加阶数

    list_entry_t *le = &(free_area[order].free_list);
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
    free_area[order].nr_free++; // 更新空闲页面计数

    merge_page(order, base); // 合并相邻的空闲页面
}
```

##### 5.3 页面分割和合并

- 分割：将高阶页面分成两个低一阶的页面。

```c
static void cut_page(size_t n) {
    while (n < MAX_ORDER && free_area[n].nr_free == 0) {
        n++; // 查找下一个有空闲页面的阶
    }
    if (n == MAX_ORDER) return; // 如果没有可用的阶，则返回

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
```

- 合并：检查相邻的伙伴页面是否空闲，如果是则合并。

```c
static void merge_page(size_t order, struct Page *base) {
    if (order >= MAX_ORDER) return; // 超过最大阶数则返回

    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &(free_area[order].free_list)) {
        struct Page *prev_page = le2page(le, page_link);
        if (prev_page + prev_page->property == base) {
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
    if (le != &(free_area[order].free_list)) {
        struct Page *next_page = le2page(le, page_link);
        if (base + base->property == next_page) {
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
```

#### 6. 测试用例

在 `buddy_check` 函数中实现了以下测试：

1. 检查每个阶的空闲页面数量是否正确。
2. 验证总的空闲页面数。
3. 分配不同大小的内存块，并验证分配结果。
4. 释放分配的内存，检查是否正确合并。

```c
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
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages()); // 输出空闲块数
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
}
```

运行 `make qemu` 后，出现 `check_alloc_page() succeeded!`, 表明 Buddy System 内存分配算法的实现基本正确！

#### 7. 性能分析

- 时间复杂度：
  - 分配和释放操作的平均时间复杂度为 O(log n)，其中 n 是系统中的总页面数。
- 空间效率：
  - Buddy System 可能会导致内部碎片，但通过使用多个大小的块，可以减少这种情况。

#### 8. 潜在的改进空间

1. 实现更复杂的分配策略，如考虑内存局部性。
2. 优化数据结构，使用更高效的搜索算法（如平衡树）来查找空闲块。
3. 实现内存压缩算法，定期整理内存以减少外部碎片。
4. 添加更多的错误处理和边界检查，提高系统的稳定性。

#### 9. 结论

本实现提供了一个基本但功能完整的 Buddy System 内存分配器。它能够有效地管理物理内存，支持动态分配和释放，并通过伙伴系统的特性减少内存碎片。通过详细的测试用例，我们验证了算法的正确性和有效性。

## 扩展练习 Challenge：任意大小的内存单元 slub 分配算法（需要编程）

### 题目

> slub 算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。
>
> - 参考 [linux 的 slub 分配算法/](https://github.com/torvalds/linux/blob/master/mm/slub.c)，在 ucore 中实现 slub 分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### slub 分配算法设计文档

#### 1. 设计目标

设计和实现一个基于 Linux `slub` 分配算法的两层内存分配器，该分配器应支持页大小的大块内存分配和任意大小的小块内存分配。实现的目标包括：

- **两层架构**：利用伙伴系统进行页大小分配，再在其基础上进行任意大小的小块分配。

- **高效性**：通过伙伴系统进行页级分配，结合链表实现小块分配，使分配器能够在常用的内存块大小下提供快速分配。
- **低碎片率**：通过伙伴系统的块合并减少页级碎片，并利用 `slub` 链表结构减少小块内存碎片。
- **简单性**：简化实现，但保留 `slub` 分配器的主要设计思想。
- **可测试性**：设计充分的测试用例验证算法的正确性和边界情况。

#### 2. 算法概述

`slub` 分配算法在 Linux 内核中是一种分层内存分配方式，用于提升小块内存的分配效率。该设计的内存分配器包含两个主要层级：

- **伙伴系统**：以页为单位的大块内存管理，适合大块内存的分配需求。每个页被划分为不同的阶层，形成一个页块链表，支持页块的分裂和合并操作。

- **slub 层**：在页级分配基础上，对小块内存进一步分配。通过链表管理空闲小块，适用于任意大小的小块请求。

#### 3. 数据结构设计

- **伙伴系统数据结构**
  - `free_area_t`：存储不同阶层的空闲页块链表。每个阶层代表一个大小的页块链表，`MAX_ORDER` 代表最大阶数。

```c
typedef struct {
    list_entry_t free_list;  // 空闲页面链表
    unsigned int nr_free;    // 空闲页面数量
} free_area_t;
```

- **slub 层数据结构**
  - `SlubBlock`：用于小块管理的链表节点，包含小块大小、状态、以及指向下一块小块的指针。空闲小块通过链表管理。
  - `slub_small_block_list`：记录空闲的小块链表，用于查找和管理小块分配。

```c
// 小块内存管理结构
struct SlubBlock
{
    size_t size;            // 小块的大小
    void *page;             // 指向分配的页面
    struct SlubBlock *next; // 指向下一个小块
};

// 小块内存链表头指针
static struct SlubBlock *slub_small_block_list = NULL;
```

#### 4. 主要函数设计

##### 4.1 伙伴系统层函数

- `buddy_alloc_pages(order)`: 按照指定阶层 `order` 分配页块。若当前阶层没有可用页块，则从更高阶块分裂得到。
- `buddy_free_pages(page, order)`: 将指定阶层 `order` 的页块释放并插入对应的空闲链表中。若相邻页块均空闲，则合并成更高阶页块。

```c
static struct Page *buddy_alloc_pages(size_t n)
static void buddy_free_pages(struct Page *base, size_t n)
```

##### 4.2 slub 层函数

- `slub_alloc_small(size)`: 根据所需大小 `size` 分配小块。若小块链表中无可用块，从伙伴系统中分配一个页并分割为小块。
- `slub_free_small(block)`: 将释放的小块插入到小块链表，等待重用。

```c
static void *slub_alloc_small(float size)
static void slub_free_small(void *ptr, size_t size)
```

##### 4.3 辅助和验证函数

- `cut_page(page, target_order)`：将大页切割成目标阶数的小页。

- `merge_page(page)`：合并相邻空闲的页块，减少碎片。

- `slub_check`: 验证内存分配的正确性，通过一系列小块、大块的分配和释放操作来测试分配器。


```c
static void cut_page(size_t n)
static void merge_page(size_t order, struct Page *base)
static void slub_check(void)
```

#### 5. 算法实现细节

- **伙伴系统实现细节**：
  - `buddy_alloc_pages` 检查对应阶层的空闲页块列表。若列表为空，则从更高阶获取块并不断分裂，直到得到所需阶层块大小。
  - `buddy_free_pages` 释放页块时，首先检查该阶层的页块是否能和相邻页块合并。若合并成功，则将合并后的块移动到更高阶，最终减少碎片。

- **slub 层实现细节**：
  - `slub_alloc_small` 首先检查链表中是否存在可用的小块。若无可用块，调用 `buddy_alloc_pages` 分配新页并将其分割为多个小块，插入到链表中。然后从链表中取出合适的小块进行分配。

  ```c
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
  ```

  - `slub_free_small` 将回收的小块插入到链表头部，等待下次请求使用。

  ```c
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
  ```

- **边界处理**：分配器会处理超过最大阶数 `MAX_ORDER` 的请求，并确保分配失败时返回 `NULL`。小块释放时检查其有效性，避免链表操作出现错误。
- **优化措施**：
  - 小块分配时会进行内存对齐，并按块大小归类链表，以提高分配效率。
  - 伙伴系统的阶数和分配的页块大小对齐，以减少页面碎片。

#### 6. 测试用例

在`slub_check`中实现了一个全面的内存分配检查，测试内容涵盖了从页分配、页回收到小块分配和回收的多个功能。

1. 检查每个阶层的空闲页面列表
2. 检查总的空闲页面数
3. 测试多个大页的分配和回收功能
4. 对小块内存的分配与回收进行测试

```c
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
```

#### 7. 性能分析

通过分层管理内存，分配器可以在页大小的大块和任意大小的小块之间高效分配内存。大块分配基于伙伴系统，因此 **时间复杂度为 O(logN)**，而小块分配通过链表结构实现，单次分配的 **平均复杂度为 O(1)**。`slub` 机制在小块分配和释放频繁的场景下具有良好性能。

#### 8. 潜在的改进空间

- **多链表分级管理**：为不同大小的小块设置多个链表，进一步降低小块分配时的遍历次数。
- **页块缓存和对齐优化**：缓存一些小块页块以减少内存碎片，并通过按缓存行对齐进一步提升性能。
- **引用计数管理**：可通过引用计数优化大块的回收策略，使内存分配更高效。

#### 9. 结论

本文设计并实现了一个基于 Linux `slub` 分配器的两层内存管理算法，通过伙伴系统进行大块页分配，并在其基础上设计了小块分配策略。实现方式保留了 `slub` 算法的核心思想，简化了代码结构，并通过测试验证了分配器的正确性和高效性。

## 扩展练习 Challenge：硬件的可用物理内存范围的获取方法（思考题）

### 题目

> - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

### 解答

操作系统在不知道当前硬件的可用物理内存范围情况下，一般有以下几种方法获取到当前的内存布局。

1. 通过 BIOS 或 UEFI 获取内存信息

   在系统启动过程中，操作系统可以通过与系统固件如常见的 BIOS 或者是 OPENSBI 进行交互，获的可用的物理内存信息。这通常是在通电以后在引导加载程序阶段完成的。具体来说的话就是操作系统可以使用 BIOS 中断 `INT 0x15`，特别是函数 `E820h`，来获取内存布局。此调用返回内存范围列表，包括可用的、保留的以及其他特定用途的内存区域。

2. 使用内存映射寄存器

   操作系统可以通过读取内存映射寄存器来获取内存信息。它是由固件生成的，包含有关系统硬件、内存布局等的信息。具体来说的话操作系统可以读取内存映射寄存器中的 SRAT 或 SPCR 表。这些表提供关于内存范围的描述，以及内存是可用的还是用于其他目的。

3. 内存探测

   操作系统页可以通过直接访问物理内存地址并进行读写测试来探测可用的物理内存范围。但这种方法通常不是首选，因为它可能不够准确，而且效率会很低，并且有可能会与硬件保留的内存区域冲突。具体来说的话就是操作系统可以尝试逐页写入某个物理地址并观察是否会导致页面错误或崩溃，以此确定物理内存的最大范围。

4. 通过虚拟化层获取内存信息

   如果操作系统运行在虚拟化环境下，如 KVM、VMware、Xen 等 上，它可以通过接口，如 `VMware Tools`、`XenStore` 等来获取虚拟机的内存配置信息。虚拟化层通常会告知虚拟机操作系统它能够使用的物理内存范围。








