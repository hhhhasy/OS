#ifndef __LIBS_UNISTD_H__
#define __LIBS_UNISTD_H__

// 系统调用的中断号
#define T_SYSCALL           0x80

/* 系统调用号定义 */
#define SYS_exit            1    // 进程退出
#define SYS_fork            2    // 创建新进程
#define SYS_wait            3    // 等待子进程
#define SYS_exec            4    // 执行程序
#define SYS_clone           5    // 创建线程
#define SYS_yield           10   // 进程主动让出CPU
#define SYS_sleep           11   // 进程休眠
#define SYS_kill            12   // 终止进程
#define SYS_gettime         17   // 获取系统时间
#define SYS_getpid          18   // 获取进程ID
#define SYS_brk             19   // 修改程序的堆空间
#define SYS_mmap            20   // 内存映射
#define SYS_munmap          21   // 取消内存映射
#define SYS_shmem           22   // 共享内存
#define SYS_putc            30   // 输出字符
#define SYS_pgdir           31   // 获取页目录

/* SYS_fork的标志位 */
#define CLONE_VM            0x00000100  // 设置进程间共享虚拟内存
#define CLONE_THREAD        0x00000200  // 线程组标志

#endif /* !__LIBS_UNISTD_H__ */
