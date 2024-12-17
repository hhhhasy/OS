# Lab5 实验报告

## 练习 0：填写已有实验

### 题目

> 本实验依赖实验 2/3/4。请把你做的实验 2/3/4 的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行 lab5 的测试应用程序，可能需对已完成的实验 2/3/4 的代码进行进一步改进。

### 解答

需要更新代码的部分主要在两个函数中：

1. alloc_proc 函数中，需要添加对 PCB 中在 LAB5 中新增成员变量的初始化，涉及的成员变量为： wait_state 、 cptr 、 yptr 、 optr ，具体代码如下：

	```c++
	static struct proc_struct *
	alloc_proc(void) {
	    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
	    if (proc != NULL) {
	    //LAB4:EXERCISE1 YOUR CODE
	        proc->state = PROC_UNINIT;  // 设置进程为未初始化状态
	        proc->pid = -1;             // 未初始化的的进程id为-1
	        proc->runs = 0;             // 初始化时间片
	        proc->kstack = 0;           // 内存栈的地址
	        proc->need_resched = 0;     // 不需要调度
	        proc->parent = NULL;        // 父节点设为空
	        proc->mm = NULL;            // 虚拟内存为空
	        memset(&(proc->context), 0, sizeof(struct context)); // 上下文的初始化
	        proc->tf = NULL;            // 中断帧指针置为空
	        proc->cr3 = boot_cr3;       // 页目录设为内核页目录表的基址
	        proc->flags = 0;            // 标志位
	        memset(proc->name, 0, PROC_NAME_LEN); // 进程名初始化为空
	     //LAB5 YOUR CODE : (update LAB4 steps)
	        proc->wait_state = 0;
	        proc->cptr = NULL; // Child Pointer 表示当前进程的子进程
	        proc->optr = NULL; // Older Sibling Pointer 表示当前进程的上一个兄弟进程
	        proc->yptr = NULL; // Younger Sibling Pointer 表示当前进程的下一个兄弟进程
	    }
	    return proc;
	}
	```

2. do_fork 函数中，需要添加设置当前进程的 wait_state 成员为 0，而且还需要设置进程间的关系链 接，其中设置进程间的关系链接利用到的函数是 set_links ，具体代码如下：

	```c++
	int
	do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
	    int ret = -E_NO_FREE_PROC;
	    struct proc_struct *proc;
	    if (nr_process >= MAX_PROCESS) {
	        goto fork_out;
	    }
	    ret = -E_NO_MEM;
	    //LAB5 YOUR CODE : (update LAB4 steps)
	    if((proc = alloc_proc()) == NULL)//调用alloc_proc来分配一个proc_struct
	    {
	        goto fork_out;
	    }
	    proc->parent = current;//设置子进程的父进程为当前进程
	    assert(current->wait_state == 0);//更新1：当前进程的wait_state是0
	    if(setup_kstack(proc))//调用setup_kstack来为子进程分配一个内核栈
	    {
	        goto bad_fork_cleanup_proc;
	    }
	    if(copy_mm(clone_flags, proc))//调用copy_mm来根据clone_flags复制或共享当前进程的mm
	    {
	        goto bad_fork_cleanup_kstack;
	    }
	    copy_thread(proc, stack, tf);//调用copy_thread来设置子进程的trapframe和context
	    bool intr_flag;
	    local_intr_save(intr_flag);//关闭中断
	    {
	        proc->pid = get_pid();//为子进程分配一个唯一的pid
	        hash_proc(proc);//将子进程加入到hash_list中
	        set_links(proc);//更新5：将子进程插入到proc_list中，并设置进程之间的关系
	    }
	    local_intr_restore(intr_flag);//开启中断
	    wakeup_proc(proc);//唤醒子进程
	    ret = proc->pid;//设置返回值为子进程的pid
	
	fork_out:
	    return ret;
	bad_fork_cleanup_kstack:
	    put_kstack(proc);
	bad_fork_cleanup_proc:
	    kfree(proc);
	    goto fork_out;
	}
	```

## 练习 1：加载应用程序并执行（需要编码）

### 题目

> **do_execv** 函数调用 `load_icode`（位于 kern/process/proc.c 中）来加载并解析一个处于内存中的 ELF 执行文件格式的应用程序。你需要补充 `load_icode` 的第 6 步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好 `proc_struct` 结构中的成员变量 trapframe 中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的 trapframe 内容。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 请简要描述这个用户态进程被 ucore 选择占用 CPU 执行（RUNNING 态）到具体执行应用程序第一条指令的整个经过。

### 解答

#### 代码实现

将 `sp` 设置为栈顶，`epc` 设置为文件的入口地址，`sstatus` 的 `SPP` 位清零，代表异常来自用户态，之后需要返回用户态；`SPIE` 位清零，表示不启用中断。

```c++
//(6) 设置用户环境的trapframe
struct trapframe *tf = current->tf;
// Keep sstatus
uintptr_t sstatus = tf->status;
memset(tf, 0, sizeof(struct trapframe));
// LAB5:EXERCISE1 YOUR CODE
tf->gpr.sp = USTACKTOP;// 设置用户栈顶指针
tf->epc = elf->e_entry;// 设置程序入口点
tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;// 设置状态寄存器，清除SPP位并设置SPIE位
```

#### 用户态进程被选择到具体执行的详细过程



## 练习 2：父进程复制自己的内存空间给子进程（需要编码）

### 题目

> 创建子进程的函数 `do_fork` 在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过 `copy_range` 函数（位于 kern/mm/pmm.c 中）实现的，请补充 `copy_range` 的实现，确保能够正确执行。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 如何设计实现 `Copy on Write` 机制？给出概要设计，鼓励给出详细设计。
>
> *Copy-on-write（简称 COW）的基本概念是指如果有多个使用者对一个资源 A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源 A 的指针，就可以该资源了。若某使用者需要对这个资源 A 进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源 A 的“私有”拷贝—资源 B，可对资源 B 进行写操作。该“写操作”使用者对资源 B 的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源 A。*

### 解答

#### 代码实现

在 copy_range 中实现了将父进程的内存空间复制给子进程的功能。逐个内存页进行复制，首先找到父 进程的页表项，然后创建一个子进程新的页表项，设置对应的权限，然后将父进程的页表项对应的内存 页复制到子进程的页表项对应的内存页中，然后将子进程的页表项加入到子进程的页表中。

```c++
void *src_kvaddr = page2kva(page);// 获取源页面的内核虚拟地址
void *dst_kvaddr = page2kva(npage);// 获取目标页面的内核虚拟地址
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);// 将源页面的内容复制到目标页面
ret = page_insert(to, npage, start, perm);// 将目标页面插入到目标页表中
```

#### 如何实现 Copy on Write 机制



## 练习 3：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）

### 题目

> 请在实验报告中简要说明你对 fork/exec/wait/exit 函数的分析。并回答如下问题：
>
> - 请分析 fork/exec/wait/exit 的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
> - 请给出 ucore 中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
>
> 执行：make grade。如果所显示的应用程序检测都输出 ok，则基本正确。（使用的是 qemu-1.0.1）

### 解答

## 扩展练习 Challenge 1

### 题目

> 实现 Copy on Write （COW）机制
>
> 给出实现源码, 测试用例和设计报告（包括在 cow 情况下的各种状态转换（类似有限状态自动机）的说明）。
>
> 这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在 ucore 操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore 会通过 page fault 异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在 ucore 中实现这样的 COW 机制。
>
> 由于 COW 实现比较复杂，容易引入 bug，请参考 <https://dirtycow.ninja/> 看看能否在 ucore 的 COW 实现中模拟这个错误和解决方案。需要有解释。
>
> 这是一个 big challenge.

### 分析

### 解答

## 扩展练习 Challenge 2

### 题目

> 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

### 分析

### 解答