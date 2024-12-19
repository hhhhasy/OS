#include <unistd.h>
#include <proc.h>
#include <syscall.h>
#include <trap.h>
#include <stdio.h>
#include <pmm.h>
#include <assert.h>

/**
 * @brief 系统调用：进程退出
 * 
 * @param arg[] 系统调用参数数组:
 *   - arg[0]: 退出码
 * 
 * @return 返回退出状态
 */
static int
sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}

/**
 * @brief 系统调用：创建子进程
 * 
 * @param arg[] 系统调用参数数组（本函数不使用参数数组，而是使用当前进程的trapframe）
 * @return 父进程返回子进程ID，子进程返回0，失败返回负值
 * 
 * @note 复制当前进程的内存空间和上下文来创建子进程
 */
static int
sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}

/**
 * @brief 系统调用：等待子进程结束
 * 
 * @param arg[] 系统调用参数数组:
 *   - arg[0]: 要等待的子进程ID
 *   - arg[1]: 用于存储子进程退出状态的地址
 * 
 * @return 成功返回结束的子进程ID，失败返回错误码
 */
static int
sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}

/**
 * @brief 系统调用：执行可执行文件
 * 
 * 该系统调用用于执行一个新的程序，替换当前进程的代码和数据
 *
 * @param arg[] 系统调用参数数组，包含以下参数:
 *   - arg[0]: 可执行文件名称的指针
 *   - arg[1]: 文件名称的长度
 *   - arg[2]: 可执行文件二进制数据的指针
 *   - arg[3]: 二进制数据的大小
 *
 * @return 如果执行成功返回0，失败返回错误码
 * 
 * @note 该函数通过调用do_execve()来完成实际的程序执行
 */
//执行
static int
sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    return do_execve(name, len, binary, size);
}

static int
sys_yield(uint64_t arg[]) {
    return do_yield();
}

static int
sys_kill(uint64_t arg[]) {
    int pid = (int)arg[0];
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
}

static int
sys_putc(uint64_t arg[]) {
    int c = (int)arg[0];
    cputchar(c);
    return 0;
}

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}

//系统调用函数指针数组，数组下标对应系统调用号
static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,      // 退出进程
    [SYS_fork]              sys_fork,      // 创建子进程
    [SYS_wait]              sys_wait,      // 等待子进程
    [SYS_exec]              sys_exec,      // 执行程序
    [SYS_yield]             sys_yield,     // 进程主动让出CPU
    [SYS_kill]              sys_kill,      // 结束指定进程
    [SYS_getpid]            sys_getpid,    // 获取当前进程ID
    [SYS_putc]              sys_putc,      // 输出字符
    [SYS_pgdir]             sys_pgdir,     // 打印页表信息
};

// 计算系统调用函数的数量
#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

// 系统调用处理主函数
void
syscall(void) {
    struct trapframe *tf = current->tf;
    uint64_t arg[5];
    //系统调用号存储在a0寄存器中
    //从trapframe中获取系统调用号
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
        //检查系统调用号是否合法且对应函数存在
        if (syscalls[num] != NULL) {
            //从寄存器中获取系统调用参数
            arg[0] = tf->gpr.a1;
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            //执行对应的系统调用函数，并将返回值存入a0寄存器
            tf->gpr.a0 = syscalls[num](arg);
            return ;
        }
    }
    //如果系统调用号非法，打印错误信息并终止系统
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}

