#include <defs.h>
#include <mmu.h>
#include <memlayout.h>
#include <clock.h>
#include <trap.h>
#include <riscv.h>
#include <stdio.h>
#include <assert.h>
#include <console.h>
#include <vmm.h>
#include <swap.h>
#include <kdebug.h>
#include <unistd.h>
#include <syscall.h>
#include <error.h>
#include <sched.h>
#include <sync.h>
#include <sbi.h>

#define TICK_NUM 100

static void print_ticks() {
    cprintf("%d ticks\n",TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    //将sscratch寄存器设置为0，表示内核正在执行。
    write_csr(sscratch, 0);
    /* Set the exception vector address */
    //设置异常地址
    write_csr(stvec, &__alltraps);
    /* Allow kernel to access user memory */
    //允许内核获取用户内存
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
}

void
print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

static inline void print_pgfault(struct trapframe *tf) {
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
    extern struct mm_struct *check_mm_struct;
    // 如果check_mm_struct不为空（用于测试check_swap），打印页面错误信息
    if(check_mm_struct !=NULL) { //used for test check_swap
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
        // 确保当前进程是空闲进程
        assert(current == idleproc);
        mm = check_mm_struct;
    }
    else {
        // 如果当前没有运行进程，打印错误信息并终止
        if (current == NULL) {
            print_trapframe(tf);
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        // 获取当前进程的内存管理结构
        mm = current->mm;
    }
    // 调用do_pgfault处理页面错误，传入内存管理结构、错误原因和错误地址
    return do_pgfault(mm, tf->cause, tf->tval);
}

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
            if (++ticks % TICK_NUM == 0 && current) {
                // print_ticks();
                current->need_resched = 1;
            }
            break;
        case IRQ_H_TIMER:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_TIMER:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
            break;
        case IRQ_H_EXT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    //查看是什么触发了调用
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            //指令地址未对齐
            cprintf("Instruction address misaligned\n");
            break;
        case CAUSE_FETCH_ACCESS:
            //指令访问错误
            cprintf("Instruction access fault\n");
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            //非法指令
            cprintf("Illegal instruction\n");
            break;
        case CAUSE_BREAKPOINT:
            //断点
            cprintf("Breakpoint\n");
            if(tf->gpr.a7 == 10){
                tf->epc += 4;
                syscall();
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
            }
            break;
        case CAUSE_MISALIGNED_LOAD:
            //加载地址未对齐
            cprintf("Load address misaligned\n");
            break;
        case CAUSE_LOAD_ACCESS:
            //加载访问错误
            cprintf("Load access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_MISALIGNED_STORE:
            //原子内存操作地址未对齐
            panic("AMO address misaligned\n");
            break;
        case CAUSE_STORE_ACCESS:
            //存储/原子内存操作访问错误
            cprintf("Store/AMO access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_USER_ECALL:
            //用户态ecall指令触发trap
            tf->epc += 4;  //更新epc指向下一条指令
            syscall();     //处理系统调用
            break;
        case CAUSE_SUPERVISOR_ECALL:
            //监管者模式系统调用
            cprintf("Environment call from S-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_HYPERVISOR_ECALL:
            //虚拟机监控器模式系统调用
            cprintf("Environment call from H-mode\n");
            break;
        case CAUSE_MACHINE_ECALL:
            //机器模式系统调用
            cprintf("Environment call from M-mode\n");
            break;
        case CAUSE_FETCH_PAGE_FAULT:
            //指令页错误
            cprintf("Instruction page fault\n");
            break;
        case CAUSE_LOAD_PAGE_FAULT:
            //加载页错误
            cprintf("Load page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            //存储/原子内存操作页错误
            cprintf("Store/AMO page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        default:
            //未知异常，打印陷阱帧信息
            print_trapframe(tf);
            break;
    }
}

//查看是中断还是异常
static inline void trap_dispatch(struct trapframe* tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        //中断
        interrupt_handler(tf);
    } else {
        // exceptions
        //异常
        exception_handler(tf);
    }
}

/* *
 * trap - 处理或分发异常/中断。当trap()返回时，
 * kern/trap/trapentry.S中的代码会恢复保存在trapframe中的旧CPU状态，
 * 然后使用iret指令从异常中返回。
 * */
void
trap(struct trapframe *tf) {
    // 根据发生的陷阱类型进行分发处理
    if (current == NULL) {
        // 如果当前没有运行进程，直接进行陷阱处理
        trap_dispatch(tf);
    } else {
        // 保存当前进程的trapframe
        struct trapframe *otf = current->tf;
        current->tf = tf;

        // 判断是否发生在内核态
        bool in_kernel = trap_in_kernel(tf);

        // 处理陷阱
        trap_dispatch(tf);

        // 恢复原来的trapframe
        current->tf = otf;
        
        // 如果在用户态发生异常
        if (!in_kernel) {
            // 检查进程是否需要退出
            if (current->flags & PF_EXITING) {
                do_exit(-E_KILLED);
            }
            // 检查是否需要进行调度
            if (current->need_resched) {
                schedule();
            }
        }
    }
}


