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

- 设计文档

  1. 数据结构的选择

     ```c
     #define MAX_ORDER 10 // Buddy system 的最大阶数
     static free_area_t free_area[MAX_ORDER]; // 每个阶数一个空闲列表
     static void buddy_init(void) {
         for (int i = 0; i < MAX_ORDER; i++) {
             list_init(&free_area[i].free_list);
             free_area[i].nr_free=0;
         }
     }
     ```

  2. 设计思路

     将原来的单个双向链表数据结构扩展成双向链表的数组

## 
