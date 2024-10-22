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

### 解答

在实现 Best-Fit 算法之前，我们首先要知道 Best-Fit 算法的原理。该算法的核心思想就是找到最佳匹配的空闲内存块，避免内存空间浪费。所以我们只需要修改 `default_alloc_pages` 函数，其它的跟 first-fit 算法都是一样的。

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

**运行截图：**

我们可以使用 make grade 命令来运行测试文件，发现可以通过测试。

![image-20241019173535855](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20241019173535855.png)

## 扩展练习 Challenge：buddy system（伙伴系统）分配算法（需要编程）

### 题目

> Buddy System 算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是 2 的 n 次幂(Pow(2, n)), 即 1, 2, 4, 8, 16, 32, 64, 128...
>
> - 参考 [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在 ucore 中实现 buddy system 分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### 解答

##### **数据结构**

- **`free_area`**: 一个长度为 `MAX_ORDER` 的数组，每个元素是一个双向链表，用于管理不同阶数的空闲内存块。

##### **初始化**

在初始化页表时，根据系统的内存大小将页面分配到对应的链表中：

1. 遍历内存块，根据其大小计算对应的阶数。

2. 将每个页面的属性和标志位清零，并将其加入对应的链表。

3. 更新链表的空闲页面计数。


##### 内存分配

##### 在分配内存时

1. **计算阶数**: 首先计算所需内存块的阶数。

2. 检查链表

	: 查看对应阶数的链表是否为空。

	- **非空**: 从链表中取出一个页面块进行分配。

	- 为空

		: 开始分割更大阶数的页块。

		- 遍历阶数比当前阶数大的链表，找到一个非空的链表，从中取出一个页面块。

		- 将页面块一分为二，分别放入当前阶数对应的链表中。

		- 如果所有更高阶数的链表均为空，递归执行分割页面算法，直到找到可用的页块。


##### **内存释放**

在释放内存时：

1. 将页块放入对应的链表中。

2. 检查前一个和后一个页面块是否可以合并成一个更大的页面块。

	- 如果可以合并，更新合并后的页面属性，并从链表中移除被合并的页面。

	- 递归检查是否可以继续向更高阶数的链表合并。


##### **合并逻辑**

- 在合并过程中，首先检查当前页面块的前后相邻页面块。
- 若相邻页面块可以合并，则更新合并后的页面块的属性，并将其插入到更高阶数的链表中。

**检测函数**

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

```

![osubuntu-2024-10-22-14-10-34](C:\Users\HP\Desktop\osubuntu-2024-10-22-14-10-34.png)

## 扩展练习 Challenge：任意大小的内存单元 slub 分配算法（需要编程）

### 题目

> slub 算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。
>
> - 参考 [linux 的 slub 分配算法/](https://github.com/torvalds/linux/blob/master/mm/slub.c)，在 ucore 中实现 slub 分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### 解答





## 扩展练习 Challenge：硬件的可用物理内存范围的获取方法（思考题）

### 题目

> - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

### 解答



