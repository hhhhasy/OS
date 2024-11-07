# Lab3实验报告

## 练习一、理解基于FIFO的页面替换算法（思考题）

> 描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？

1. **`do_pgfault()`**

   当系统发生缺页异常后，程序会将跳转到该函数进行缺页处理。在该函数中会首先判断出错的虚拟地址在`mm_struct`里是否可用，如果可用：若查找的 `pte` 当前为空（表示该虚拟页没有映射），则调用 `pgdir_alloc_page` 分配物理页并建立页表映射。如果页表项不为空（`*ptep != 0`），使用`swap_in()`函数换入页。

2. **`swap_in()`**

   用来将把已经在页表里面映射过并且当前在磁盘上的页换进内存中。

3. **`swap_out()`**

   当使用`alloc_page`函数已经分配不到内存页的情况下，使用该函数把内存中的页从内存中替换出去。

4. **`get_pte()`**

   从页表中找到指定地址的页表项。

5. **`page_remove_pte()`**

   从页表中删除指定地址的页表项。

6. **`swapfs_write（）`**

   用于将页面写入磁盘。在这里由于需要换出页面，而页面内容如果被修改过那么就与磁盘中的不一致，所以需要将其重新写回磁盘。

7. **`swapfs_read（）`**

   用于将磁盘中的数据写入内存。

8. **`_fifo_swap_out_victim（）`**

   `FIFO`替换方法的核心算法，用来将保存页面队列中最先进来的的内存页替换出去。

9. **`free_page（）`**

   用来将要替换的内存页释放。

10. **`tlb_invalidate（）`**

    在替换内存页或更新页表映射之后用来将`TLB`刷新。



## 练习二、深入理解不同分页模式的工作原理（思考题

> get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
>
> - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
> - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？



### sv32，sv39，sv48的异同

#### 1. 页表层级

- **sv32**: 使用两级页表结构，适用于 32 位虚拟地址空间。地址由两部分组成：页目录项（10 位）和页表项（10 位），加上12位偏移。
- **sv39**: 使用三级页表结构，适用于 39 位虚拟地址空间。地址分为3个页目录项（9 位、9 位和9位），加上12位偏移。
- **sv48**: 使用四级页表结构，适用于 48 位虚拟地址空间。地址分为4个页目录项（9 位、9 位、9 位和9位），加上12位偏移。

#### 2. 虚拟地址空间大小

- **sv32**: 支持4 GB（2^32）虚拟地址空间。
- **sv39**: 支持512 GB（2^39）虚拟地址空间。
- **sv48**: 支持256 TB（2^48）虚拟地址空间。

#### 3. 每个页表项大小

在这三种模式下，每个页表项的大小都是**64位**。这种一致性使得页表项结构和标志位保持统一。

#### 4. 页大小

这三种模式默认页大小均为 **4 KB**。不过，RISC-V 架构也允许使用更大的超页（例如 2 MB 或 1 GB），由页表项的级别决定。



### 对相似性的解释

这两段代码分别获取页目录表（一级表）和页表（二级表）的页表项，确保在页表中找到对应的物理页表地址。第一段代码 `pdep1` 负责找到第一级页目录项，如果该项不存在且 `create` 为 `true`，则分配一个新的物理页，建立表项。第二段代码 `pdep0` 负责进入到二级页表项，再次进行存在性检查，不存在时同样创建。sv32，sv39，sv48三种模式在结构上都要求分级逐步访问页表，确保每一级都分配和初始化，但由于这种分级逻辑的页表层级间的主要差异仅在于页表基地址的变化和每一级索引的位宽不同，查找操作的基本流程保持不变：通过逐级索引定位到目标页表项并确保其存在。所以代码中每层级的处理逻辑因此非常相似，这使得每个层级的代码结构几乎一致，只需调整基地址和索引偏移量即可适应不同层级的查找和分配需求。

```c
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];

    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```



### 是否需要拆分`get_pte()`函数中的查找和分配功能？

我们组认为这种写法是很好的，并不需要拆分。这种写法的优点在于，通常我们只会在获取页表项时遇到缺失的情况，尤其是在页表非法或未分配的情况下，才需要进行页表的创建。将查找和分配合并在同一个函数中，可以有效减少代码的重复性和函数调用的开销，降低代码的复杂度，使得整体逻辑更加清晰。因为我们主要关心的是最终一级页表所给出的页，因此这种合并不仅简化了代码，还提高了性能。（还需要扩展）



## 练习三、给未被映射的地址映射上物理页（需要编程）

> 补充完成`do_pgfault`（`mm/vmm.c`）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 `VMA` 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
> - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
>   - 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

### 实现代码

```c
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr);
    pgfault_num++;
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
   
    ptep = get_pte(mm->pgdir, addr, 1);  
    if (*ptep == 0) {
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        
        
        if (swap_init_ok) {
            struct Page *page = NULL;
            //我们需要实现的部分
            swap_in(mm,addr,&page); //把从磁盘中得到的页放进内存中
            page_insert(mm->pgdir,page,addr,perm);//在页表中新增加一个映射，并且设置权限
            swap_map_swappable(mm,addr,page,1);//将该内存页设置为可交换，最后一个参数目前还没有用
            page->pra_vaddr = addr;//将虚拟地址addr存储到页面结构
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
failed:
    return ret;
}
```



## 练习四、补充完成Clock页替换算法（需要编程）

> 通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（`mm/swap_clock.c`）。(提示:要输出`curr_ptr`的值才能通过make grade)
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 比较Clock页替换算法和FIFO算法的不同。

### 实现思路

**`_clock_init_mm`**：在该函数中我们首先要初始化`pra_list_head`为空链表，之后初始化当前指针`curr_ptr`指向`pra_list_head`，表示当前页面替换位置为链表头并且将mm的私有成员指针指向`pra_list_head`，用于后续的页面替换算法操作。

```c
static int
_clock_init_mm(struct mm_struct *mm)
{      
     list_init(&pra_list_head);// 初始化pra_list_head为空链表
     mm->sm_priv = &pra_list_head;// 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     curr_ptr=&pra_list_head;// 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     return 0;
}
```



**`_clock_map_swappable`**：在该函数中我们要实现把一个内存页放进交换区里面。因为题目中要求需要放进链表的最后面，并且数据结构是双向链表，所以我们只需放在head前面即可。最后我们需要把刚放进的内存页的访问位置1。

```c
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);//获得要放进的内存页
    assert(entry != NULL && curr_ptr != NULL);
    list_entry_t *head=(list_entry_t*) mm->sm_priv;//获得链表头部
    assert(entry != NULL && head != NULL);
    list_add_before(head,entry); // 将页面page插入到页面链表pra_list_head的末尾
    page->visited = 1;// 将页面的visited标志置为1，表示该页面已被访问
    return 0;
}
```



**`_clock_swap_out_victim`**：在该函数中我们需要实现clock算法的核心代码，也就是换出策略。因为clock算法是遍历环链表，所以刚好可以匹配我们的双向链表结构。所以我们在一个永真的while循环里面使用curr_ptr遍历这个双向链表结构，直到遇见一个访问位为0的内存页，就把它从链表中删除换出。其中我们需要注意两件事情：一个是当我们遇到访问位为1的内存页，我们需要把它的访问位置零。另一个则是，因为是一个双向链表，所以它可能会访问到head，但因为head里面没有存储什么信息，所以我们这时候需要多做一个list_next步骤。

```c
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
    
    while (1) {      
        curr_ptr = list_next(curr_ptr);// 遍历页面链表pra_list_head，查找最早未被访问的页面
        if(curr_ptr == head) {
            curr_ptr = list_next(curr_ptr);//如果访问到了head，多做一个list_next步骤
            if(curr_ptr == head) {
              *ptr_page = NULL;
             break;
            }
        }
    

        struct Page* page = le2page(curr_ptr, pra_page_link);// 获取当前页面对应的Page结构指针
        if(page->visited==0){
            *ptr_page=page;// 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
            list_del(curr_ptr);
            cprintf("curr_ptr %p\n",curr_ptr);;
            break;
        }
        else{
            page->visited=0;// 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        }

    }
    return 0;
}
```



## 练习五、阅读代码和实现手册，理解页表映射方式相关知识（思考题）



## 拓展练习Challenge：实现不考虑实现开销和效率的`LRU`页替换算法（需要编程）

## 

