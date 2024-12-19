#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - 分配一个 proc_struct 并初始化 proc_struct 的所有字段
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * 需要初始化 proc_struct 中的以下字段
     *       enum proc_state state;                      // 进程状态
     *       int pid;                                    // 进程ID
     *       int runs;                                   // 进程的运行次数
     *       uintptr_t kstack;                           // 进程内核栈
     *       volatile bool need_resched;                 // 是否需要重新调度以释放CPU？
     *       struct proc_struct *parent;                 // 父进程
     *       struct mm_struct *mm;                       // 进程的内存管理字段
     *       struct context context;                     // 切换到此处运行进程
     *       struct trapframe *tf;                       // 当前中断的陷阱帧
     *       uintptr_t cr3;                              // CR3寄存器：页目录表基地址
     *       uint32_t flags;                             // 进程标志
     *       char name[PROC_NAME_LEN + 1];               // 进程名称
     */
        proc->state = PROC_UNINIT;  // 设置进程为未初始化状态
        proc->pid = -1;             // 未初始化的进程ID为-1
        proc->runs = 0;             // 初始化运行次数
        proc->kstack = 0;           // 内核栈地址
        proc->need_resched = 0;     // 不需要重新调度
        proc->parent = NULL;        // 父进程设为空
        proc->mm = NULL;            // 内存管理结构设为空
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文初始化
        proc->tf = NULL;            // 陷阱帧指针设为空
        proc->cr3 = boot_cr3;       // 页目录表基地址设为内核页目录表基地址
        proc->flags = 0;            // 标志位设为0
        memset(proc->name, 0, PROC_NAME_LEN); // 进程名称初始化为空

     //LAB5 YOUR CODE : (update LAB4 steps)
     /*
     * 需要初始化 proc_struct 中的以下字段（在LAB5中添加）
     *       uint32_t wait_state;                        // 等待状态
     *       struct proc_struct *cptr, *yptr, *optr;     // 进程之间的关系
     */
        proc->wait_state = 0;       // 等待状态设为0
        proc->cptr = NULL;          // 子进程指针设为空
        proc->optr = NULL;          // 上一个兄弟进程指针设为空
        proc->yptr = NULL;          // 下一个兄弟进程指针设为空
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// set_links - 设置进程的关系链接
static void
set_links(struct proc_struct *proc) {
    list_add(&proc_list, &(proc->list_link)); // 将进程添加到进程列表中
    proc->yptr = NULL; // 初始化下一个兄弟进程指针为空
    if ((proc->optr = proc->parent->cptr) != NULL) { // 设置上一个兄弟进程指针为父进程的子进程指针
        proc->optr->yptr = proc; // 如果存在上一个兄弟进程，则将其下一个兄弟进程指针设置为当前进程
    }
    proc->parent->cptr = proc; // 将父进程的子进程指针设置为当前进程
    nr_process ++; // 增加进程数量
}

// remove_links - clean the relation links of process
static void
remove_links(struct proc_struct *proc) {
    list_del(&(proc->list_link));
    if (proc->optr != NULL) {
        proc->optr->yptr = proc->yptr;
    }
    if (proc->yptr != NULL) {
        proc->yptr->optr = proc->optr;
    }
    else {
       proc->parent->cptr = proc->optr;
    }
    nr_process --;
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag); // 关闭中断
        {
            current = proc; // 切换当前进程
            lcr3(next->cr3); // 加载新进程的页目录表基地址到CR3寄存器
            switch_to(&(prev->context), &(next->context)); // 切换上下文
        }
        local_intr_restore(intr_flag); // 恢复中断
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// unhash_proc - delete proc from proc hash_list
static void
unhash_proc(struct proc_struct *proc) {
    list_del(&(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - 使用 "fn" 函数创建一个内核线程
// 注意: 临时trapframe tf的内容将在do_fork-->copy_thread函数中复制到proc->tf
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn; // 将函数指针存储在s0寄存器中
    tf.gpr.s1 = (uintptr_t)arg; // 将参数存储在s1寄存器中
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE; // 设置状态寄存器
    tf.epc = (uintptr_t)kernel_thread_entry; // 设置程序计数器为kernel_thread_entry
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用do_fork函数创建内核线程
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// setup_pgdir - alloc one page as PDT
static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

// put_pgdir - free the memory space of PDT
//释放页目录表（PDT）的内存空间
static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;

    /* current is a kernel thread */
    // 检查当前进程是否是一个内核线程
    // 如果是内核线程，说明它没有用户空间的内存管理结构，因此直接返回，不需要进行进一步的处理。
    if (oldmm == NULL) {
        return 0;
    }
    // 表示需要共享内存
    // 直接将子进程的 mm 指向当前进程的 mm
    if (clone_flags & CLONE_VM) {
        mm = oldmm;
        goto good_mm;
    }
    int ret = -E_NO_MEM;
    // 复制内存，创建一个新的mm_struct
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    // 分配新的页目录
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    // 锁定当前进程的mm
    lock_mm(oldmm);
    {
        ret = dup_mmap(mm, oldmm); // 复制内存映射
    }
    unlock_mm(oldmm);

    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    mm_count_inc(mm); // 增加mm的引用计数
    proc->mm = mm; // 设置子进程的mm
    proc->cr3 = PADDR(mm->pgdir); // 设置子进程的页目录基地址
    return 0;
bad_dup_cleanup_mmap:
    exit_mmap(mm); // 退出内存映射
    put_pgdir(mm); // 释放页目录
bad_pgdir_cleanup_mm:
    mm_destroy(mm); // 销毁mm结构
bad_mm:
    return ret;
}

// copy_thread - 在进程的内核栈顶设置trapframe，并设置进程的内核入口点和栈
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    // 将trapframe设置在进程的内核栈顶
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;

    // 将a0设置为0，以便子进程知道它刚刚被fork
    proc->tf->gpr.a0 = 0;
    // 设置栈指针，如果esp为0，则使用proc->tf，否则使用传入的esp
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    // 设置进程的上下文，返回地址为forkret，栈指针为proc->tf
    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork -     parent process for a new child process
 * @clone_flags: 用于指导如何克隆子进程
 * @stack: 父进程的用户栈指针。如果stack==0，表示创建一个内核线程。
 * @tf: 将被复制到子进程的proc->tf的trapframe信息
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC; // 初始化返回值为"没有空闲进程"错误
    struct proc_struct *proc;
    // 检查当前进程数量是否已经达到最大值MAX_PROCESS
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM; // 更改返回值为"内存不足"错误

    // 分配并初始化进程控制块
    if((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    proc->parent = current; // 设置新进程的父进程为当前进程
    assert(current->wait_state == 0); // 确保当前进程的等待状态为0

    // 为新进程分配内核栈
    if(setup_kstack(proc)) {
        goto bad_fork_cleanup_proc;
    }

    // 根据clone_flags复制或共享内存管理结构
    if(copy_mm(clone_flags, proc)) {
        goto bad_fork_cleanup_kstack;
    }

    // 设置新进程的中断帧和上下文
    copy_thread(proc, stack, tf);

    // 以下操作需要关中断保护
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid(); // 为新进程分配PID
        hash_proc(proc); // 将新进程添加到哈希表中
        set_links(proc); // 设置进程间的链接关系
    }
    local_intr_restore(intr_flag);

    wakeup_proc(proc); // 将新进程设置为就绪状态
    ret = proc->pid; // 设置返回值为新进程的PID

fork_out: // 正常返回
    return ret;

bad_fork_cleanup_kstack: // 错误处理：清理内核栈
    put_kstack(proc);
bad_fork_cleanup_proc: // 错误处理：清理进程控制块
    kfree(proc);
    goto fork_out;
}

// do_exit - 由sys_exit调用
//   1. 调用exit_mmap & put_pgdir & mm_destroy来释放进程的几乎所有内存空间
//   2. 将进程状态设置为PROC_ZOMBIE，然后调用wakeup_proc(parent)来请求父进程回收自己
//   3. 调用调度器切换到其他进程
int
do_exit(int error_code) {
    // 不允许idle进程退出
    if (current == idleproc) {
        panic("idleproc exit.\n");
    }
    // 不允许init进程退出
    if (current == initproc) {
        panic("initproc exit.\n");
    }
    
    // 获取当前进程的内存管理结构
    struct mm_struct *mm = current->mm;
    if (mm != NULL) {
        lcr3(boot_cr3); // 切换到内核页表
        if (mm_count_dec(mm) == 0) { // 如果mm的引用计数为0
            exit_mmap(mm); // 释放内存映射
            put_pgdir(mm); // 释放页目录表
            mm_destroy(mm); // 销毁mm结构
        }
        current->mm = NULL;
    }

    // 设置进程状态为僵尸状态
    current->state = PROC_ZOMBIE;
    current->exit_code = error_code;

    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag); // 关中断
    {
        proc = current->parent;
        // 如果父进程正在等待子进程，则唤醒父进程
        if (proc->wait_state == WT_CHILD) {
            wakeup_proc(proc);
        }

        // 处理当前进程的所有子进程
        while (current->cptr != NULL) {
            proc = current->cptr;
            current->cptr = proc->optr;
    
            proc->yptr = NULL;
            // 将子进程链接到init进程下
            if ((proc->optr = initproc->cptr) != NULL) {
                initproc->cptr->yptr = proc;
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            // 如果子进程已经是僵尸进程，且init进程正在等待子进程
            // 则唤醒init进程
            if (proc->state == PROC_ZOMBIE) {
                if (initproc->wait_state == WT_CHILD) {
                    wakeup_proc(initproc);
                }
            }
        }
    }
    local_intr_restore(intr_flag); // 开中断
    
    schedule(); // 调度其他进程运行
    
    panic("do_exit will not return!! %d.\n", current->pid);
}

/* load_icode - 加载二进制程序（ELF格式）的内容作为当前进程的新内容
 * @binary:  二进制程序内容的内存地址
 * @size:  二进制程序内容的大小
 */
static int
load_icode(unsigned char *binary, size_t size) {
    // 确保当前进程的内存管理结构为空
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    // 步骤1：为进程创建新的内存管理空间
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    // 步骤2：创建新的页目录表，并设置mm->pgdir
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }

    struct Page *page;
    // 步骤3.1：获取ELF文件头
    struct elfhdr *elf = (struct elfhdr *)binary;
    // 步骤3.2：获取程序段头表
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    // 步骤3.3：验证ELF文件的魔数
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    uint32_t vm_flags, perm;
    struct proghdr *ph_end = ph + elf->e_phnum;
    for (; ph < ph_end; ph ++) {
        // 步骤3.4：遍历并处理每个程序段
        if (ph->p_type != ELF_PT_LOAD) {
            continue ;
        }
        if (ph->p_filesz > ph->p_memsz) {
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        if (ph->p_filesz == 0) {
            // continue ;
        }
        // 步骤3.5：设置内存访问权限标志
        vm_flags = 0, perm = PTE_U | PTE_V;
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;    // 可执行
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;   // 可写
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;    // 可读
        // 设置RISC-V特定的权限位
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;
        // 建立虚拟内存映射
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
            goto bad_cleanup_mmap;
        }

        unsigned char *from = binary + ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

        // 步骤3.6：复制程序段内容到进程内存空间
        end = ph->p_va + ph->p_filesz;
        // 复制TEXT/DATA段
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memcpy(page2kva(page) + off, from, size);
            start += size, from += size;
        }

        // 初始化BSS段
        end = ph->p_va + ph->p_memsz;
        if (start < la) {
            if (start == end) {
                continue ;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }

    // 步骤4：设置用户栈
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    // 为用户栈分配虚拟内存空间（1MB）
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    // 分配用户栈的物理页面
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
    
    // 步骤5：更新进程的内存管理信息
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));

    // 步骤6：设置用户进程的陷阱帧
    struct trapframe *tf = current->tf;
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* 设置用户进程的陷阱帧
     * 需要设置：
     * tf->gpr.sp: 用户栈顶
     * tf->epc: 用户程序入口点
     * tf->status: 用户程序状态（设置SPP和SPIE位）
     */
    tf->gpr.sp = USTACKTOP;          // 设置栈指针
    tf->epc = elf->e_entry;          // 设置程序计数器
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;  // 设置状态寄存器

    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}

// do_execve - 调用exit_mmap(mm)和put_pgdir(mm)以回收当前进程的内存空间
//           - 调用load_icode以根据二进制程序设置新的内存空间
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    // 获取当前进程的内存管理结构
    struct mm_struct *mm = current->mm;
    // 检查进程名称所在的内存空间是否可访问
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
        return -E_INVAL;
    }
    // 限制进程名称长度
    if (len > PROC_NAME_LEN) {
        len = PROC_NAME_LEN;
    }

    // 在内核空间中创建进程名称的副本
    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);

    // 如果当前进程已有内存空间，需要先清理
    if (mm != NULL) {
        cputs("mm != NULL");
        // 切换到内核页表
        lcr3(boot_cr3);
        // 如果mm的引用计数降为0，需要完全清理内存空间
        if (mm_count_dec(mm) == 0) {
            exit_mmap(mm);    // 清理内存映射
            put_pgdir(mm);    // 释放页目录表
            mm_destroy(mm);   // 销毁内存管理结构
        }
        current->mm = NULL;   // 清空当前进程的mm指针
    }

    int ret;
    // 加载新的程序到内存中
    if ((ret = load_icode(binary, size)) != 0) {
        goto execve_exit;
    }
    // 设置新的进程名称
    set_proc_name(current, local_name);
    return 0;

execve_exit:
    // 如果执行失败，终止进程
    do_exit(ret);
    panic("already exit: %e.\n", ret);
}

// do_yield - ask the scheduler to reschedule
int
do_yield(void) {
    current->need_resched = 1;
    return 0;
}

// do_wait - 等待一个或任何处于PROC_ZOMBIE状态的子进程，并释放该子进程的内核栈内存空间
//          和进程控制块（proc结构）
// 注意：只有在do_wait函数执行后，子进程的所有资源才会被释放
int
do_wait(int pid, int *code_store) {
    struct mm_struct *mm = current->mm;
    // 检查用户提供的code_store指针是否有效
    if (code_store != NULL) {
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
            return -E_INVAL;
        }
    }

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0) {
        // 如果指定了pid，查找特定的子进程
        proc = find_proc(pid);
        if (proc != NULL && proc->parent == current) {
            haskid = 1;
            if (proc->state == PROC_ZOMBIE) {
                goto found;
            }
        }
    }
    else {
        // 如果pid为0，查找任何一个僵尸子进程
        proc = current->cptr;
        for (; proc != NULL; proc = proc->optr) {
            haskid = 1;
            if (proc->state == PROC_ZOMBIE) {
                goto found;
            }
        }
    }
    // 如果有子进程但都不是僵尸状态，当前进程进入睡眠状态等待
    if (haskid) {
        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
        schedule();
        // 如果当前进程被标记为需要退出，则执行退出操作
        if (current->flags & PF_EXITING) {
            do_exit(-E_KILLED);
        }
        goto repeat;
    }
    return -E_BAD_PROC;

found:
    // 不允许等待idle进程或init进程
    if (proc == idleproc || proc == initproc) {
        panic("wait idleproc or initproc.\n");
    }
    // 如果提供了code_store，保存子进程的退出码
    if (code_store != NULL) {
        *code_store = proc->exit_code;
    }
    // 关中断，保护临界区
    local_intr_save(intr_flag);
    {
        unhash_proc(proc);    // 从进程哈希表中移除
        remove_links(proc);   // 解除进程间的链接关系
    }
    local_intr_restore(intr_flag);
    // 释放子进程的资源
    put_kstack(proc);        // 释放内核栈
    kfree(proc);            // 释放进程控制块
    return 0;
}

// do_kill - kill process with pid by set this process's flags with PF_EXITING
int
do_kill(int pid) {
    struct proc_struct *proc;
    if ((proc = find_proc(pid)) != NULL) {
        if (!(proc->flags & PF_EXITING)) {
            proc->flags |= PF_EXITING;
            if (proc->wait_state & WT_INTERRUPTED) {
                wakeup_proc(proc);
            }
            return 0;
        }
        return -E_KILLED;
    }
    return -E_INVAL;
}

// kernel_execve - 通过user_main内核线程调用SYS_exec系统调用来执行用户程序
static int
kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
    // ret = do_execve(name, len, binary, size);
    // ebreak是特权态到特权态的中断
    // 如果a7等于10，是在内核态模拟的syscall
    asm volatile(
        "li a0, %1\n"        // 加载系统调用号(SYS_exec)到a0
        "lw a1, %2\n"        // 加载程序名称到a1
        "lw a2, %3\n"        // 加载名称长度到a2
        "lw a3, %4\n"        // 加载二进制程序到a3
        "lw a4, %5\n"        // 加载程序大小到a4
        "li a7, 10\n"        // 设置a7为10，表示这是一个内核态模拟的系统调用
        "ebreak\n"           // 触发异常中断
        "sw a0, %0\n"        // 保存返回值
        : "=m"(ret)
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
        : "memory");
    cprintf("ret = %d\n", ret);
    return ret;
}

// 用于执行内核程序的宏定义
#define __KERNEL_EXECVE(name, binary, size) ({                          \
            cprintf("kernel_execve: pid = %d, name = \"%s\".\n",        \
                    current->pid, name);                                \
            kernel_execve(name, binary, (size_t)(size));                \
        })

// 用于执行用户程序的宏定义，自动获取程序的起始地址和大小
#define KERNEL_EXECVE(x) ({                                             \
            extern unsigned char _binary_obj___user_##x##_out_start[],  \
                _binary_obj___user_##x##_out_size[];                    \
            __KERNEL_EXECVE(#x, _binary_obj___user_##x##_out_start,     \
                            _binary_obj___user_##x##_out_size);         \
        })

// 用于执行指定地址和大小的程序的宏定义
#define __KERNEL_EXECVE2(x, xstart, xsize) ({                           \
            extern unsigned char xstart[], xsize[];                     \
            __KERNEL_EXECVE(#x, xstart, (size_t)xsize);                 \
        })

// KERNEL_EXECVE2的简化形式
#define KERNEL_EXECVE2(x, xstart, xsize)        __KERNEL_EXECVE2(x, xstart, xsize)

// user_main - 用于执行用户程序的内核线程
static int
user_main(void *arg) {
#ifdef TEST
    // 如果定义了TEST宏,执行测试程序
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    // 否则默认执行exit程序
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n"); // 如果执行失败则触发panic
}

// init_main - 第二个内核线程，用于创建user_main内核线程
static int
init_main(void *arg) {
    // 保存当前空闲页面数量和已分配内存大小
    size_t nr_free_pages_store = nr_free_pages();
    size_t kernel_allocated_store = kallocated();

    // 创建user_main内核线程
    int pid = kernel_thread(user_main, NULL, 0);
    if (pid <= 0) {
        panic("create user_main failed.\n");
    }

    // 等待所有用户进程结束
    while (do_wait(0, NULL) == 0) {
        schedule(); // 调度其他进程运行
    }

    // 所有用户进程结束后的检查
    cprintf("all user-mode processes have quit.\n");
    // 确保init进程没有任何子进程或兄弟进程
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    // 确保系统中只剩下idle和init两个进程
    assert(nr_process == 2);
    // 确保进程列表中只剩下init进程的链接
    assert(list_next(&proc_list) == &(initproc->list_link));
    assert(list_prev(&proc_list) == &(initproc->list_link));

    // 内存检查通过
    cprintf("init check memory pass.\n");
    return 0;
}

// proc_init - 设置第一个内核线程idleproc "idle"，并创建第二个内核线程init_main
void
proc_init(void) {
    int i;

    // 初始化进程列表
    list_init(&proc_list);
    // 初始化进程哈希表
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    // 分配并初始化idle进程
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // 设置idle进程的基本属性
    idleproc->pid = 0;                   // 进程ID设为0
    idleproc->state = PROC_RUNNABLE;     // 设置为可运行状态
    idleproc->kstack = (uintptr_t)bootstack;  // 设置内核栈
    idleproc->need_resched = 1;          // 需要重新调度
    set_proc_name(idleproc, "idle");     // 设置进程名为"idle"
    nr_process ++;                        // 增加进程计数

    // 设置当前运行的进程为idle进程
    current = idleproc;

    // 创建init进程（第二个内核线程）
    int pid = kernel_thread(init_main, NULL, 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    // 查找并初始化init进程
    initproc = find_proc(pid);
    set_proc_name(initproc, "init");     // 设置进程名为"init"

    // 确保idle进程和init进程正确创建
    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) {
            schedule();
        }
    }
}

