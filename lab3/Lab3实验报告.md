# Lab3 实验报告

## 练习 1：理解基于 FIFO 的页面替换算法（思考题）

> 描述 FIFO 页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将 FIFO 页面置换算法头文件的大部分代码放在了 `kern/mm/swap_fifo.c` 文件中，这点请同学们注意）
>
> - 至少正确指出 10 个不同的函数分别做了什么？如果少于 10 个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响, 删去后会导致输出结果不同的函数（例如 assert）而不是 cprintf 这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如 10 个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这 10 个函数在页面换入时的功能，那么也会扣除一定的分数

1. **`do_pgfault()`**

	当系统发生缺页异常后，程序会将跳转到该函数进行缺页处理。在该函数中会首先判断出错的虚拟地址在 `mm_struct` 里是否可用，如果可用：若查找的 `pte` 当前为空（表示该虚拟页没有映射），则调用 `pgdir_alloc_page` 分配物理页并建立页表映射。如果页表项不为空（`*ptep != 0`），使用 `swap_in()` 函数换入页。

2. **`swap_in()`**

	用来将把已经在页表里面映射过并且当前在磁盘上的页换进内存中。

3. **`swap_out()`**

	当使用 `alloc_page` 函数已经分配不到内存页的情况下，使用该函数把内存中的页从内存中替换出去。

4. **`get_pte()`**

	从页表中找到指定地址的页表项。

5. **`page_remove_pte()`**

	从页表中删除指定地址的页表项。

6. **`swapfs_write()`**

	用于将页面写入磁盘。在这里由于需要换出页面，而页面内容如果被修改过那么就与磁盘中的不一致，所以需要将其重新写回磁盘。

7. **`swapfs_read()`**

	用于将磁盘中的数据写入内存。

8. **`_fifo_swap_out_victim()`**

	`FIFO` 替换方法的核心算法，用来将保存页面队列中最先进来的的内存页替换出去。

9. **`free_page()`**

	用来将要替换的内存页释放。

10. **`tlb_invalidate()`**

	在替换内存页或更新页表映射之后用来将 `TLB` 刷新。

## 练习 2：深入理解不同分页模式的工作原理（思考题）

> get_pte()函数（位于 `kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
>
> - get_pte()函数中有两段形式类似的代码， 结合 sv32，sv39，sv48 的异同，解释这两段代码为什么如此相像。
> - 目前 get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

### sv32，sv39，sv48 的异同

1. **页表层级**

- **sv32**: 使用两级页表结构，适用于 32 位虚拟地址空间。地址由两部分组成：页目录项（10 位）和页表项（10 位），加上 12 位偏移。
- **sv39**: 使用三级页表结构，适用于 39 位虚拟地址空间。地址分为 3 个页目录项（9 位、9 位和 9 位），加上 12 位偏移。
- **sv48**: 使用四级页表结构，适用于 48 位虚拟地址空间。地址分为 4 个页目录项（9 位、9 位、9 位和 9 位），加上 12 位偏移。

2. **虚拟地址空间大小**

- **sv32**: 支持 4 GB（2^32）虚拟地址空间。
- **sv39**: 支持 512 GB（2^39）虚拟地址空间。
- **sv48**: 支持 256 TB（2^48）虚拟地址空间。

3. **每个页表项大小**

在这三种模式下，每个页表项的大小都是 **64 位**。这种一致性使得页表项结构和标志位保持统一。

4. **页大小**

这三种模式默认页大小均为 **4 KB**。不过，RISC-V 架构也允许使用更大的超页（例如 2 MB 或 1 GB），由页表项的级别决定。

### 对相似性的解释

这两段代码分别获取页目录表（一级表）和页表（二级表）的页表项，确保在页表中找到对应的物理页表地址。第一段代码 `pdep1` 负责找到第一级页目录项，如果该项不存在且 `create` 为 `true`，则分配一个新的物理页，建立表项。第二段代码 `pdep0` 负责进入到二级页表项，再次进行存在性检查，不存在时同样创建。sv32，sv39，sv48 三种模式在结构上都要求分级逐步访问页表，确保每一级都分配和初始化，但由于这种分级逻辑的页表层级间的主要差异仅在于页表基地址的变化和每一级索引的位宽不同，查找操作的基本流程保持不变：通过逐级索引定位到目标页表项并确保其存在。所以代码中每层级的处理逻辑因此非常相似，这使得每个层级的代码结构几乎一致，只需调整基地址和索引偏移量即可适应不同层级的查找和分配需求。

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

### 是否需要拆分 `get_pte()` 函数中的查找和分配功能？

我们组认为这种写法是很好的，并不需要拆分。这种写法的优点在于，通常我们只会在获取页表项时遇到缺失的情况，尤其是在页表非法或未分配的情况下，才需要进行页表的创建。将查找和分配合并在同一个函数中，可以有效减少代码的重复性和函数调用的开销，降低代码的复杂度，使得整体逻辑更加清晰。因为我们主要关心的是最终一级页表所给出的页，因此这种合并不仅简化了代码，还提高了性能。（还需要扩展）

## 练习 3：给未被映射的地址映射上物理页（需要编程）

> 补充完成 do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制结构所指定的页表，而不是内核的页表。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对 ucore 实现页替换算法的潜在用处。
> - 如果 ucore 的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
> 	- 数据结构 Page 的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

### 实现代码

页面错误处理函数 do_pgfault 的作用是在发生页面错误时，根据错误地址和错误码进行相应的处理。

```c
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr);//查找包含错误地址的虚拟内存区域 (VMA)
    pgfault_num++;
    if (vma == NULL || vma->vm_start > addr) {//检查地址是否有效
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {//设置页面权限
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
    ret = -E_NO_MEM;
    pte_t *ptep=NULL;
    ptep = get_pte(mm->pgdir, addr, 1);//获取页表项 (PTE)
    /*处理页面错误*/
    if (*ptep == 0) {//页面不存在的情况：分配一个新的页面并建立映射
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {//页面存在但需要从交换区加载
        if (swap_init_ok) {
            struct Page *page = NULL;
            /*我们需要实现的部分*/
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

## 练习 4：补充完成 Clock 页替换算法（需要编程）

> 通过之前的练习，相信大家对 FIFO 的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock 页替换算法（mm/swap_clock.c）。(提示: 要输出 curr_ptr 的值才能通过 make grade)
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 比较 Clock 页替换算法和 FIFO 算法的不同。

### 实现思路

**`_clock_init_mm`**：在该函数中我们首先要初始化 `pra_list_head` 为空链表，之后初始化当前指针 `curr_ptr` 指向 `pra_list_head`，表示当前页面替换位置为链表头并且将 mm 的私有成员指针指向 `pra_list_head`，用于后续的页面替换算法操作。

```c
static int
_clock_init_mm(struct mm_struct *mm)
{
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    /*我们需要实现的部分*/
    list_init(&pra_list_head);    // 初始化pra_list_head为空链表
    curr_ptr = &pra_list_head;    // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
    mm->sm_priv = &pra_list_head; // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    return 0;
}
```

**`_clock_map_swappable`**：在该函数中我们要实现把一个内存页放进交换区里面。因为题目中要求需要放进链表的最后面，并且数据结构是双向链表，所以我们只需放在 head 前面即可。最后我们需要把刚放进的内存页的访问位置 1。

```c
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link); // 获得要放进的内存页
    assert(entry != NULL && curr_ptr != NULL);
    /*我们需要实现的部分*/
    list_entry_t *head = (list_entry_t *)mm->sm_priv; // 获得链表头部
    assert(entry != NULL && head != NULL);
    list_add_before(head, entry); // 将页面page插入到页面链表pra_list_head的末尾
    page->visited = 1;            // 将页面的visited标志置为1，表示该页面已被访问
    return 0;
}
```

**`_clock_swap_out_victim`**：在该函数中我们需要实现 clock 算法的核心代码，也就是换出策略。因为 clock 算法是遍历环链表，所以刚好可以匹配我们的双向链表结构。所以我们在一个永真的 while 循环里面使用 curr_ptr 遍历这个双向链表结构，直到遇见一个访问位为 0 的内存页，就把它从链表中删除换出。其中我们需要注意两件事情：一个是当我们遇到访问位为 1 的内存页，我们需要把它的访问位置零。另一个则是，因为是一个双向链表，所以它可能会访问到 head，但因为 head 里面没有存储什么信息，所以我们这时候需要多做一个 list_next 步骤。

```c
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    /* Select the victim */
    //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
    //(2)  set the addr of addr of this page to ptr_page
    while (1)
    {
        /*我们需要实现的部分*/
        curr_ptr = list_next(curr_ptr); // 遍历页面链表pra_list_head，查找最早未被访问的页面
        if (curr_ptr == head)
        {
            curr_ptr = list_next(curr_ptr); // 如果访问到了head，多做一个list_next步骤
            if (curr_ptr == head)
            {
                *ptr_page = NULL;
                break;
            }
        }
        struct Page *page = le2page(curr_ptr, pra_page_link); // 获取当前页面对应的Page结构指针
        if (page->visited == 0)
        {
            *ptr_page = page; // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
            list_del(curr_ptr);
            cprintf("curr_ptr %p\n", curr_ptr);
            ;
            break;
        }
        else
        {
            page->visited = 0; // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        }
    }
    return 0;
}
```

## 练习 5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）

> 如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？



## 扩展练习 Challenge：实现不考虑实现开销和效率的 LRU 页替换算法（需要编程）

> challenge 部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。



### 实现思路

维护一个活动页链表，当我们访问这个链表内已经有的内存页的虚拟地址时，把对应的内存页从链表中删除，并插入到链表头。而当访问没有在这个链表的内存页时直接插入到链表头即可。这样每次新访问的内存页会一直在链表头，而最久没有访问的页会在链表尾部，我们替换的时候直接替换到尾部即可。

### 具体代码

前几部分的代码跟 FIFO 算法基本一样，不需要太大改变。

```c
static list_entry_t pra_list_head;

static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}

static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation

    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
     assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```



为了检查访问的内存页是否已经在链表中，新增加了一个函数 update_or_ignore，专门来检查访问的虚拟地址是否已经被映射。

```c
static void update_or_ignore(unsigned int addr) {
    list_entry_t *head = &pra_list_head, *le = head;
    
    while ((le = list_prev(le)) != head) {
        struct Page *curr = le2page(le, pra_page_link);
        if (curr->pra_vaddr == addr) {
            list_del(le);         // 删除找到的页
            list_add(head, le);   // 将页移到链表头部
            return;               // 直接返回，不必继续查找
        }
    }
}
```



也稍微修改了一下检查函数，输出每次访问内存过后的链表内部情况。

```c
static void
printlist() {
    cprintf("--------head----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head)
    {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: %x\n", page->pra_vaddr);
    }
    cprintf("---------tail-----------\n");
}

static void write_and_check(unsigned int addr, unsigned char value, int expected_faults) {
    cprintf("write Virt Page %x in lru_check_swap\n", addr);
    update_or_ignore(addr);
    *(unsigned char *)addr = value;
    //assert(pgfault_num == expected_faults);
}

static int _lru_check_swap(void) {
    write_and_check(0x3000, 0x0c, 4);
    printlist();
    write_and_check(0x1000, 0x0a, 4);
    printlist();
    write_and_check(0x4000, 0x0d, 4);
    printlist();
    write_and_check(0x2000, 0x0b, 4);
    printlist();
    write_and_check(0x5000, 0x0e, 5);
    printlist();
    write_and_check(0x2000, 0x0b, 5);
    printlist();
    write_and_check(0x1000, 0x0a, 6);
    printlist();
    write_and_check(0x2000, 0x0b, 7);
    printlist();
    write_and_check(0x3000, 0x0c, 8);
    printlist();
    write_and_check(0x4000, 0x0d, 9);
    printlist();
    write_and_check(0x5000, 0x0e, 10);
    printlist();
    write_and_check(0x1000, 0x0a, 11);
    printlist();

    return 0;
}

```



### 实验结果

```c
write Virt Page 3000 in lru_check_swap
--------head----------
vaddr: 3000
vaddr: 4000
vaddr: 2000
vaddr: 1000
--------tail----------
write Virt Page 1000 in lru_check_swap
--------head----------
vaddr: 1000
vaddr: 3000
vaddr: 4000
vaddr: 2000
--------tail----------
write Virt Page 4000 in lru_check_swap
--------head----------
vaddr: 4000
vaddr: 1000
vaddr: 3000
vaddr: 2000
--------tail----------
write Virt Page 2000 in lru_check_swap
--------head----------
vaddr: 2000
vaddr: 4000
vaddr: 1000
vaddr: 3000
--------tail----------
write Virt Page 5000 in lru_check_swap
Store/AMO page fault
page fault at 0x00005000: K/W
swap_out: i 0, store page in vaddr 0x3000 to disk swap entry 4
--------head----------
vaddr: 5000
vaddr: 2000
vaddr: 4000
vaddr: 1000
--------tail----------
write Virt Page 2000 in lru_check_swap
--------head----------
vaddr: 2000
vaddr: 5000
vaddr: 4000
vaddr: 1000
--------tail----------
write Virt Page 1000 in lru_check_swap
--------head----------
vaddr: 1000
vaddr: 2000
vaddr: 5000
vaddr: 4000
--------tail----------
write Virt Page 2000 in lru_check_swap
--------head----------
vaddr: 2000
vaddr: 1000
vaddr: 5000
vaddr: 4000
--------tail----------
write Virt Page 3000 in lru_check_swap
Store/AMO page fault
page fault at 0x00003000: K/W
swap_out: i 0, store page in vaddr 0x4000 to disk swap entry 5
swap_in: load disk swap entry 4 with swap_page in vadr 0x3000
--------head----------
vaddr: 3000
vaddr: 2000
vaddr: 1000
vaddr: 5000
--------tail----------
write Virt Page 4000 in lru_check_swap
Store/AMO page fault
page fault at 0x00004000: K/W
swap_out: i 0, store page in vaddr 0x5000 to disk swap entry 6
swap_in: load disk swap entry 5 with swap_page in vadr 0x4000
--------head----------
vaddr: 4000
vaddr: 3000
vaddr: 2000
vaddr: 1000
--------tail----------
write Virt Page 5000 in lru_check_swap
Store/AMO page fault
page fault at 0x00005000: K/W
swap_out: i 0, store page in vaddr 0x1000 to disk swap entry 2
swap_in: load disk swap entry 6 with swap_page in vadr 0x5000
--------head----------
vaddr: 5000
vaddr: 4000
vaddr: 3000
vaddr: 2000
--------tail----------
write Virt Page 1000 in lru_check_swap
Store/AMO page fault
page fault at 0x00001000: K/W
swap_out: i 0, store page in vaddr 0x2000 to disk swap entry 3
swap_in: load disk swap entry 2 with swap_page in vadr 0x1000
--------head----------
vaddr: 1000
vaddr: 5000
vaddr: 4000
vaddr: 3000
--------tail----------
count is 1, total is 8
check_swap() succeeded!

```
