#include <default_pmm.h>
#include <defs.h>
#include <error.h>
#include <kmalloc.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>

// 物理页数组的虚拟地址
struct Page *pages;
// 物理内存大小(以页为单位)
size_t npage = 0;
// 内核镜像被映射在 VA=KERNBASE 和 PA=info.base 处
uint_t va_pa_offset;
// RISC-V中内存从0x80000000开始
const size_t nbase = DRAM_BASE / PGSIZE;

// 启动时页目录的虚拟地址 
pde_t *boot_pgdir = NULL;
// 启动时页目录的物理地址
uintptr_t boot_cr3;

// 物理内存管理器
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// init_pmm_manager - 初始化一个pmm_manager实例
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - 调用pmm->init_memmap为空闲内存建立Page结构
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用pmm->alloc_pages分配连续的n*PAGESIZE大小内存
// memory
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag);
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}

// free_pages - 调用pmm->free_pages释放连续的n*PAGESIZE大小内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - 调用pmm->nr_free_pages获取当前空闲内存大小(nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

/* pmm_init - initialize the physical memory management */
static void page_init(void) {
    extern char kern_entry[];

    va_pa_offset = KERNBASE - 0x80200000;

    uint_t mem_begin = KERNEL_BEGIN_PADDR;
    uint_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint_t mem_end = PHYSICAL_MEMORY_END;

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);

    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
    // BBL has put the initial page table at the first available page after the
    // kernel
    // so stay away from it by adding extra offset to end
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));

    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
    cprintf("vapaofset is %llu\n",va_pa_offset);
}

// boot_map_segment - 设置和启用分页机制
// 参数:
//  la:   需要映射的线性地址(x86段映射后)
//  size: 内存大小
//  pa:   物理地址
//  perm: 该内存的权限
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) {
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm);
    }
}

// boot_alloc_page - 使用pmm->alloc_pages(1)分配一页
// 返回值: 该分配页的内核虚拟地址
// 注意: 该函数用于获取PDT(页目录表)和PT(页表)所需的内存
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page();
    if (p == NULL) {
        panic("boot_alloc_page failed.\n");
    }
    return page2kva(p);
}

// pmm_init - 设置pmm管理物理内存,建立PDT&PT以设置分页机制
//         - 检查pmm和分页机制的正确性,打印PDT&PT 
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other
    // size).
    // So a framework of physical memory manager (struct pmm_manager)is defined
    // in pmm.h
    // First we should init a physical memory manager(pmm) based on the
    // framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a
    // pmm
    check_alloc_page();

    // create boot_pgdir, an initial page directory(Page Directory Table, PDT)
    extern char boot_page_table_sv39[];
    boot_pgdir = (pte_t*)boot_page_table_sv39;
    boot_cr3 = PADDR(boot_pgdir);

    check_pgdir();

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // now the basic virtual memory map(see memalyout.h) is established.
    // check the correctness of the basic virtual memory map.
    check_boot_pgdir();


    kmalloc_init();
}

// get_pte - 获取pte并返回la对应的pte的内核虚拟地址
//        - 如果包含此pte的PT不存在,则为PT分配一页
// 参数:
//  pgdir:  PDT的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 决定是否为PT分配页面的逻辑值
// 返回值: pte的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
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
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL) {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V) {
        return pte2page(*ptep);
    }
    return NULL;
}

// page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
// note: PT is changed, so the TLB need to be invalidate
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
        struct Page *page =
            pte2page(*ptep);  //(2) find corresponding page to pte
        page_ref_dec(page);   //(3) decrease page reference
        if (page_ref(page) ==
            0) {  //(4) and free this page when page reference reachs 0
            free_page(page);
        }
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

//取消映射指定虚拟地址范围的函数
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));

    do {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep != 0) {
            //如果ptep不为NULL且页表项的值*ptep不为零，说明存在有效的页表项
            //调用page_remove_pte函数，将该页表项从页表中移除。
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
}

//在释放虚拟地址空间时，逐级检查并释放相应的页表和页目录
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));

    uintptr_t d1start, d0start;
    int free_pt, free_pd0;
    pde_t *pd0, *pt, pde1, pde0;
    d1start = ROUNDDOWN(start, PDSIZE);
    d0start = ROUNDDOWN(start, PTSIZE);
    do {
        // level 1 page directory entry
        //获得一级页目录项
        pde1 = pgdir[PDX1(d1start)];
        // if there is a valid entry, get into level 0
        // and try to free all page tables pointed to by
        // all valid entries in level 0 page directory,
        // then try to free this level 0 page directory
        // and update level 1 entry
        //检查是否存在有效的页目录。
        //如果存在，获取对应的二级页表，然后尝试释放所有二级页表，并更新一级页目录项。
        //如果所有二级页表都被释放，再尝试释放一级页目录，并更新相应的一级页目录项。
        if (pde1&PTE_V){
            pd0 = page2kva(pde2page(pde1));
            // try to free all page tables
            free_pd0 = 1;
            do {
                pde0 = pd0[PDX0(d0start)];
                if (pde0&PTE_V) {
                    pt = page2kva(pde2page(pde0));
                    // try to free page table
                    free_pt = 1;
                    for (int i = 0;i <NPTEENTRY;i++)
                        if (pt[i]&PTE_V){
                            free_pt = 0;
                            break;
                        }
                    // free it only when all entry are already invalid
                    if (free_pt) {
                        free_page(pde2page(pde0));
                        pd0[PDX0(d0start)] = 0;
                    }
                } else
                    free_pd0 = 0;
                d0start += PTSIZE;
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
            // free level 0 page directory only when all pde0s in it are already invalid
            if (free_pd0) {
                free_page(pde2page(pde1));
                pgdir[PDX1(d1start)] = 0;
            }
        }
        d1start += PDSIZE;
        d0start = d1start;
    } while (d1start != 0 && d1start < end);
}
/* copy_range - copy content of memory (start, end) of one process A to another
 * process B
 * @to:    the addr of process B's Page Directory
 * @from:  the addr of process A's Page Directory
 * @share: flags to indicate to dup OR share. We just use dup method, so it
 * didn't be used.
 *
 * CALL GRAPH: copy_mm-->dup_mmap-->copy_range
 */
/* copy_range - 将进程 A 的内存内容（start 到 end）复制到进程 B
 * @to:    进程 B 的页目录地址
 * @from:  进程 A 的页目录地址
 * @share: 标志，指示是复制还是共享。我们只使用复制方法，所以它没有被使用。
 *
 * 调用图: copy_mm --> dup_mmap --> copy_range
 */
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    //断言检验start和end是否是页对齐的，该地址范围是否在用户空间内
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // 按页单位复制内容
    do {
        // 调用 get_pte 根据地址 start 找到进程 A 的 pte，若ptep为空，说明在源进程中没有找到对应的页表项
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);//更新2Mib
            continue;
        }
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);//获取五个位的结果
            // 从 ptep 获取页面
            struct Page *page = pte2page(*ptep);
            int ret = 0;

            // 实现COW：映射共享页面
            if (share) {	
                // 如果选择共享，那么就将子进程的页面映射到父进程的页面上
                // 并且将子进程和父进程的页面权限设置为只读
                cprintf("Sharing the page 0x%x\n", page2kva(page));
                page_insert(from, page, start, perm & (~PTE_W));
                ret = page_insert(to, page, start, perm & (~PTE_W));
            } else {
                // 如果不选择共享，那么就直接复制父进程的页面到子进程的页面上
                struct Page *npage = alloc_page();
                assert(page != NULL);
                assert(npage!=NULL);


            /* LAB5:EXERCISE2 YOUR CODE
             * replicate content of page to npage, build the map of phy addr of
             * nage with the linear addr start
             * 复制页的内容到npage，建立nage的物理地址与线性地址start的映射
             *
             * Some Useful MACROs and DEFINEs, you can use them in below
             * implementation.
             * MACROs or Functions:
             *    page2kva(struct Page *page): return the kernel vritual addr of
             * memory which page managed (SEE pmm.h)
             *      返回页管理的内存的内核虚拟地址（查看 pmm.h）
             *    page_insert: build the map of phy addr of an Page with the
             * linear addr la
             *      用线性地址la建立一个Page的物理地址映射
             *    memcpy: typical memory copy function
             *
             * (1) find src_kvaddr: the kernel virtual address of page
             * (2) find dst_kvaddr: the kernel virtual address of npage
             * (3) memory copy from src_kvaddr to dst_kvaddr, size is PGSIZE
             * (4) build the map of phy addr of  nage with the linear addr start
             * (1) 找到 src_kvaddr：页的内核虚拟地址
             * (2) 找到 dst_kvaddr：npage的内核虚拟地址
             * (3) 从 src_kvaddr 复制到 dst_kvaddr，大小为 PGSIZE
             * (4) 用线性地址 start 建立 nage 的物理地址映射
             */
                void *src_kvaddr = page2kva(page);// 获取源页面的内核虚拟地址
                void *dst_kvaddr = page2kva(npage);// 获取目标页面的内核虚拟地址
                memcpy(dst_kvaddr, src_kvaddr, PGSIZE);// 将源页面的内容复制到目标页面
                ret = page_insert(to, npage, start, perm);// 将目标页面插入到目标页表中
            }

            assert(ret == 0);
        }
        start += PGSIZE;//按页来更新
    } while (start != 0 && start < end);
    return 0;
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep);
    }
}

// page_insert - 将一个页的物理地址与线性地址 la 建立映射
// 参数:
//  pgdir: PDT 的内核虚拟基地址
//  page:  需要映射的页
//  la:    需要映射的线性地址
//  perm:  该页的权限，将设置在相关的 pte 中
// 返回值: 始终为 0
// 注意: PT 已更改，因此需要使 TLB 失效
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
        struct Page *p = pte2page(*ptep);
        if (p == page) {
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
    tlb_invalidate(pgdir, la);
    return 0;
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
}

// pgdir_alloc_page - call alloc_page & page_insert functions to
//                  - allocate a page size memory & setup an addr map
//                  - pa<->la with linear address la and the PDT pgdir
//为给定的页目录表分配一页内存的函数
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page();
    if (page != NULL) {
        if (page_insert(pgdir, page, la, perm) != 0) {
            free_page(page);
            return NULL;
        }
        if (swap_init_ok) {
            if (check_mm_struct != NULL) {
                swap_map_swappable(check_mm_struct, la, page, 0);
                page->pra_vaddr = la;
                assert(page_ref(page) == 1);
                // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
                // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
                // page->pra_vaddr,page->pra_page_link.prev,
                // page->pra_page_link.next);
            } else {  // now current is existed, should fix it in the future
                // swap_map_swappable(current->mm, la, page, 0);
                // page->pra_vaddr=la;
                // assert(page_ref(page) == 1);
                // panic("pgdir_alloc_page: no pages. now current is existed,
                // should fix it in the future\n");
            }
        }
    }

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

static void check_pgdir(void) {
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }


    assert(boot_pgdir[0] == 0);

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 1);
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 2);

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);

    *(char *)(page2kva(p) + 0x100) = '\0';
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_boot_pgdir() succeeded!\n");
}

// perm2str - use string 'u,r,w,-' to present the permission
static const char *perm2str(int perm) {
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
    str[1] = 'r';
    str[2] = (perm & PTE_W) ? 'w' : '-';
    str[3] = '\0';
    return str;
}

// get_pgtable_items - In [left, right] range of PDT or PT, find a continuous
// linear addr space
//                  - (left_store*X_SIZE~right_store*X_SIZE) for PDT or PT
//                  - X_SIZE=PTSIZE=4M, if PDT; X_SIZE=PGSIZE=4K, if PT
// paramemters:
//  left:        no use ???
//  right:       the high side of table's range
//  start:       the low side of table's range
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with
// perm permission
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_V)) {
        start++;
    }
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
            start++;
        }
        if (right_store != NULL) {
            *right_store = start;
        }
        return perm;
    }
    return 0;
}

