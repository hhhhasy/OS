# `Lab2` 物理内存和页表

## 胡博浩 阿斯雅 赵一凡

## 练习1：理解first-fit 连续物理内存分配算法（思考题）

**要求：**

`first-fit` 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析`default_init`，`default_init_memmap`，`default_alloc_pages`， `default_free_pages`等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 

**解答：**

首先`first-fit`算法的主要思想就是，当分配物理内存时总是分配第一个满足条件的那个内存块，不管它是不是最佳的，只要它比要求的内存块大小大即可。接下来，将介绍`kern/mm/default_pmm.c`中的一些核心代码的作用。

**`default_init`**：该函数用来初始化一个空的链表`free_list`，而这个链表里面存的就是那些没被分配出去的内存页框。因为是刚开始初始化，所以表示空闲内存页框的`nr_free`也被设置为0。

**`default_init_memmap`**：该函数用来把一个有n个页大小的空闲内存块放进`free_list`链表里面。具体来说的话，该函数首先通过一个for循环，把内存块里面中的全部页框的标志和属性信息清空掉，并将页框的引用计数设置为0。之后在原有的`nr_free`上加新加来的n个内存页框。随后，首先判断`free_list`链表是否为空，如果为空的话，直接在链表里面加入新来的内存块即可。但如果不是为空，程序会把内存快开始地址跟链表里面元素的地址一个个比较，如果找到了一个比新来的内存块开始地址大的元素，就把新来的内存块插入到它前面，如果没有找到，就把新来的内存块插入到链表的队尾。

**`default_alloc_pages`**：该函数用来分配连续的n个空闲页，并将剩余的空闲页放回到空闲页链表中。具体来说的话，首先程序要判断当前链表里面的空闲页个数`nr_free`是否能满足分配n个空闲页，如果不满足的话就返回一个NULL。如果满足的话，程序就从链表结构里面查找第一个满足该条件的连续内存块。如果这个内存块分配完n个页框之后还有剩余页框，程序就要把这个剩余的页框组成的内存块重新放到链表结构里面。最后程序要在原有的`nr_free`中减去n。

**`default_free_pages`**：最后这个函数是用来释放内存空间并将其放入链表结构的。具体来说的话，程序首先要把即将释放掉的内存块中的全部页框的标志和属性信息清空掉，并将页框的引用计数设置为0。然后放入到链表结构中。但之后程序还要做一件事情，就是查看这个新放进的内存块能不能跟前面的或后面的内存块是连续的，如果是连续的，就应该将其合并成一个大内存块，即合二为一。最后也要在原有的`nr_free`上加新加来的n个内存页框。



## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

**要求：**

在完成练习一后，参考`kern/mm/default_pmm.c`对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：

- 你的 Best-Fit 算法是否有进一步的改进空间？

**解答：**

在实现 Best-Fit算法之前，我们首先要知道 Best-Fit算法的原理。该算法的核心思想就是找到最佳匹配的空闲内存块，避免内存空间浪费。所以我们只需要修改`default_alloc_pages`函数，其它的跟first-fit算法都是一样的。

**`best_fit_alloc_pages`**函数实现：

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

我们可以使用make grade 命令来运行测试文件，发现可以通过测试。

![image-20241019173535855](C:\Users\HP\AppData\Roaming\Typora\typora-user-images\image-20241019173535855.png)



## 扩展练习`Challenge`：`buddy system`（伙伴系统）分配算法（需要编程）

**要求：**

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

- 参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在`ucore`中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。



**解答：**

##### **数据结构**

- **`free_area`**: 一个长度为 `MAX_ORDER` 的数组，每个元素是一个双向链表，用于管理不同阶数的空闲内存块。

  

##### **初始化**

在初始化页表时，根据系统的内存大小将页面分配到对应的链表中：

1. 遍历内存块，根据其大小计算对应的阶数。

2. 将每个页面的属性和标志位清零，并将其加入对应的链表。

3. 更新链表的空闲页面计数。

   

##### 内存分配

##### 在分配内存时：

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
