#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// 进程在其生命周期中的状态
enum proc_state {
    PROC_UNINIT = 0,  // 未初始化
    PROC_SLEEPING,    // 睡眠中
    PROC_RUNNABLE,    // 可运行(可能正在运行)
    PROC_ZOMBIE,      // 僵尸状态，等待父进程回收其资源
};

struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

#define PROC_NAME_LEN               15          // 进程名字的最大长度
#define MAX_PROCESS                 4096        // 系统中最大进程数量
#define MAX_PID                     (MAX_PROCESS * 2)    // 系统中最大的进程ID号

extern list_entry_t proc_list;       // 进程链表

struct proc_struct {
    enum proc_state state;           // 进程状态
    int pid;                         // 进程ID
    int runs;                        // 进程运行次数
    uintptr_t kstack;               // 进程的内核栈
    volatile bool need_resched;      // 布尔值：是否需要重新调度以释放CPU？
    struct proc_struct *parent;      // 父进程
    struct mm_struct *mm;            // 进程的内存管理字段
    struct context context;          // 进程上下文，用于进程切换
    struct trapframe *tf;            // 中断帧，保存中断时的状态
    uintptr_t cr3;                  // CR3寄存器：页目录表的基地址
    uint32_t flags;                 // 进程标志
    char name[PROC_NAME_LEN + 1];   // 进程名称
    list_entry_t list_link;         // 进程链表节点 
    list_entry_t hash_link;         // 进程哈希表节点
    int exit_code;                  // 退出码（发送给父进程）
    uint32_t wait_state;            // 等待状态
    struct proc_struct *cptr, *yptr, *optr;  // 进程间关系：子进程、同级younger进程、同级older进程
};

#define PF_EXITING                  0x00000001      // 进程正在退出

#define WT_CHILD                    (0x00000001 | WT_INTERRUPTED)  // 等待子进程
#define WT_INTERRUPTED               0x80000000                    // 等待状态可被中断


// 从链表元素获取对应的进程控制块指针
// le: 链表元素指针
// member: 链表节点在proc_struct中的字段名
#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

// 重要的全局进程变量
extern struct proc_struct *idleproc,  // 空闲进程，系统初始化时创建
                         *initproc,   // 初始进程，系统初始化后第一个创建的用户进程
                         *current;     // 当前正在运行的进程

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);
int do_yield(void);
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size);
int do_wait(int pid, int *code_store);
int do_kill(int pid);
#endif /* !__KERN_PROCESS_PROC_H__ */

