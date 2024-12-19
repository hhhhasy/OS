#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>
#include <kmalloc.h>

/**
 * @file vmm.c
 * @brief 虚拟内存管理模块 (Virtual Memory Management Module)
 *
 * @details 虚拟内存管理设计包含两个主要部分:
 * 1. mm_struct (mm) - 内存管理器
 *    - 管理具有相同页目录表的连续虚拟内存区域集合
 * 2. vma_struct (vma) - 虚拟内存区域
 *    - 表示一个连续的虚拟内存区域
 *    - 在mm中以线性链表和红黑树形式组织
 *
 * @section mm相关函数
 * 全局函数:
 * - mm_create(): 创建内存管理器
 * - mm_destroy(): 销毁内存管理器
 * - do_pgfault(): 处理页面故障
 *
 * @section vma相关函数
 * 全局函数:
 * - vma_create(): 创建虚拟内存区域
 * - insert_vma_struct(): 插入虚拟内存区域
 * - find_vma(): 查找虚拟内存区域
 *
 * 局部函数:
 * - check_vma_overlap(): 检查虚拟内存区域重叠
 *
 * @section 正确性检查函数
 * - check_vmm(): 检查虚拟内存管理
 * - check_vma_struct(): 检查虚拟内存区域结构
 * - check_pgfault(): 检查页面故障处理
 */
/* 
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory  
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL) {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        if (swap_init_ok) swap_init_mm(mm);
        else mm->sm_priv = NULL;
        
        set_mm_count(mm, 0);
        lock_init(&(mm->mm_lock));
    }    
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL) {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}


// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL;
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
                break;
            }
            le_prev = le;
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
}

// mm_destroy - free mm and mm internal fields
//释放mm_struct结构及其内部字段的函数
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
        list_del(le);
        //释放虚拟内存区域的内存
        kfree(le2vma(le, list_link));  //kfree vma        
    }
    //释放整个mm结构体的内存
    kfree(mm); //kfree mm
    mm=NULL;
}

// mm_map - 在指定的内存管理器中建立一段虚拟内存映射
// @mm: 内存管理器结构体
// @addr: 待映射的起始地址
// @len: 映射的长度
// @vm_flags: 虚拟内存区域的标志位
// @vma_store: 存储新创建的vma结构体的指针的指针
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
    struct vma_struct **vma_store) {
    // 将地址按页面大小对齐
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    // 检查地址范围是否在用户空间内
    if (!USER_ACCESS(start, end)) {
     return -E_INVAL;
    }

    assert(mm != NULL);

    int ret = -E_INVAL;

    // 检查是否与现有的虚拟内存区域重叠
    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
     goto out;
    }
    ret = -E_NO_MEM;

    // 创建新的虚拟内存区域
    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
     goto out;
    }
    // 将新的虚拟内存区域插入到mm中
    insert_vma_struct(mm, vma);
    // 如果需要，存储新创建的vma
    if (vma_store != NULL) {
     *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}

// dup_mmap - 复制一个进程的内存映射表到另一个进程中
// @to: 目标内存管理器结构
// @from: 源内存管理器结构 
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);
    // 获取源进程的内存映射链表
    list_entry_t *list = &(from->mmap_list), *le = list;
    // 遍历源进程的所有VMA(虚拟内存区域)
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        // 为目标进程创建新的VMA，继承源VMA的起始地址、结束地址和访问权限
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM; // 内存不足，返回错误
        }

        // 将新建的VMA插入到目标进程的mm中
        insert_vma_struct(to, nvma);

        // 实现写时复制(COW)机制：
        // share=1表示启用页面共享，父子进程初始共享物理页面
        bool share = 1;
        // 复制源VMA到目标VMA的具体内容
        // 如果复制失败则返回内存不足错误
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0; // 复制成功
}

/**
 * @brief 清理内存映射
 * 
 * @param mm 内存管理器结构体指针
 * 
 * @details 当进程退出时调用此函数清理其虚拟内存映射。
 * 首先取消页表映射关系，然后处理相关的退出操作。
 */
void
exit_mmap(struct mm_struct *mm) {
    assert(mm != NULL && mm_count(mm) == 0);
    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    // 第一次遍历：取消所有VMA的页表映射
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }
    // 第二次遍历：执行清理操作
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

/**
 * @brief 从用户空间复制数据到内核空间
 * 
 * @param mm 内存管理器结构体指针
 * @param dst 目标地址（内核空间）
 * @param src 源地址（用户空间）
 * @param len 要复制的字节数
 * @param writable 是否可写
 * @return bool 复制是否成功
 */
bool
copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable) {
    // 检查用户空间内存是否可访问
    if (!user_mem_check(mm, (uintptr_t)src, len, writable)) {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

/**
 * @brief 从内核空间复制数据到用户空间
 * 
 * @param mm 内存管理器结构体指针
 * @param dst 目标地址（用户空间）
 * @param src 源地址（内核空间）
 * @param len 要复制的字节数
 * @return bool 复制是否成功
 */
bool
copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len) {
    // 检查用户空间内存是否可写
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1)) {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    // size_t nr_free_pages_store = nr_free_pages();
    
    check_vma_struct();
    check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i+1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i+2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i+3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i+4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
    }

    for (i =4; i>=0; i--) {
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0);

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        sum -= *(char *)(addr + i);
    }

    assert(sum == 0);

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    pgdir[0] = 0;
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
    check_mm_struct = NULL;

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
//page fault number
volatile unsigned int pgfault_num=0;

/* do_pgfault - 处理页面故障异常的中断处理程序
 * @mm         : 使用相同页目录表的一组vma的控制结构
 * @error_code : 在trapframe->tf_err中记录的错误代码，由硬件设置
 * @addr       : 导致内存访问异常的地址（CR2寄存器的内容）
 *
 * 调用图: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * 处理器为ucore的do_pgfault函数提供两项信息，以帮助诊断和恢复异常：
 *   (1) CR2寄存器的内容。处理器将产生异常的32位线性地址加载到CR2寄存器中。
 *       do_pgfault函数可以使用此地址来定位相应的页目录和页表项。
 *   (2) 内核栈上的错误代码。页面故障的错误代码格式与其他异常不同。
 *       错误代码向异常处理程序提供三个信息：
 *         -- P标志   (位0) 指示异常是由于页面不存在(0)还是由于访问权限违规或使用保留位(1)。
 *         -- W/R标志 (位1) 指示导致异常的内存访问是读取(0)还是写入(1)。
 *         -- U/S标志 (位2) 指示处理器在异常发生时是在用户模式(1)还是监督模式(0)下执行。
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    // 尝试找到一个包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++; // 页错误计数器增加
    
    // 检查地址是否在任何VMA范围内
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* 检查访问权限:
     * 1. 写入一个已存在的地址
     * 2. 写入一个不存在但可写的地址
     * 3. 读取一个不存在但可读的地址
     */
    uint32_t perm = PTE_U; // 设置基本用户访问权限
    if (vma->vm_flags & VM_WRITE) {
        perm |= READ_WRITE; // 如果VMA可写，添加写权限
    }
    addr = ROUNDDOWN(addr, PGSIZE); // 将地址向下对齐到页面边界

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
  
    // 获取或创建页表项
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // 如果页表项不存在
        // 分配新的物理页面并建立映射
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    
    } else { // 页表项存在
        struct Page *page=NULL;
        // 处理写时复制情况
        if (*ptep & PTE_V) {
            cprintf("\n\nCOW: ptep 0x%x, pte 0x%x\n",ptep, *ptep);
            page = pte2page(*ptep); // 获取物理页面
            
            // 如果页面被多个进程共享
            if(page_ref(page) > 1) {
                // 创建新的物理页面副本
                struct Page* newPage = pgdir_alloc_page(mm->pgdir, addr, perm);
                void * kva_src = page2kva(page);
                void * kva_dst = page2kva(newPage);
                memcpy(kva_dst, kva_src, PGSIZE); // 复制页面内容
            } else {
                // 如果页面只被一个进程使用，直接更新权限
                page_insert(mm->pgdir, page, addr, perm);
            }
        } else {
            // 处理页面置换
            if(swap_init_ok) {
                // 从磁盘加载页面
                if ((ret = swap_in(mm, addr, &page)) != 0) {
                    cprintf("swap_in in do_pgfault failed\n");
                    goto failed;
                }
                // 建立物理页面映射
                page_insert(mm->pgdir, page, addr, perm);
            } else {
                cprintf("no swap_init_ok but ptep is %x, failed\n",*ptep);
                goto failed;
            }
        }
        // 标记页面为可交换
        swap_map_swappable(mm, addr, page, 1);
        page->pra_vaddr = addr;
   }
   ret = 0;
failed:
    return ret;
}

/**
 * @brief 检查用户内存访问的合法性
 * @param mm 内存管理器结构体指针 
 * @param addr 待检查的起始地址
 * @param len 待检查的长度
 * @param write 是否为写访问
 * @return bool 如果访问合法返回1,否则返回0
 */
bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
    if (mm != NULL) { // 如果mm不为空,说明是用户进程
        // 检查访问地址是否在用户空间范围内
        if (!USER_ACCESS(addr, addr + len)) {
            return 0;
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        while (start < end) {
            // 查找包含start地址的VMA
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
                return 0; // 未找到VMA或地址在VMA之前,访问非法
            }
            // 检查访问权限
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0; // 权限不足
            }
            // 对栈区的特殊检查
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { // 检查栈的起始位置和大小
                    return 0;
                }
            }
            start = vma->vm_end; // 移动到下一个VMA
        }
        return 1; // 所有检查都通过
    }
    // 如果mm为空,说明是内核访问,检查是否在内核空间
    return KERN_ACCESS(addr, addr + len);
}

