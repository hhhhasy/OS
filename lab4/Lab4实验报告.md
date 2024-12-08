# Lab4 实验报告

## 练习 1：分配并初始化一个进程控制块（需要编码）

### 题目

> alloc_proc 函数（位于 kern/process/proc.c 中）负责分配并返回一个新的 struct proc_struct 结构，用于存储新建立的内核线程的管理信息。ucore 需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
>
> 【提示】在 alloc_proc 函数的实现中，需要初始化的 proc_struct 结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请说明 proc_struct 中 `struct context context` 和 `struct trapframe *tf` 成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

### 分析

我们可以在下面的proc_init函数中看到有调用alloc_proc 函数，并且通过判断结构体成员是否满足要求来决定是否正确分配新的结果体。所以我们可以通过这个来对结构体进行基本的初始化。

```c
void
proc_init(void) {
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure 
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");

    }
    …………
}
```



### 解答

#### **代码实现**

```c
/**
 * alloc_proc - 分配并初始化一个新的进程结构体
 *
 * 返回值：
 * 成功：返回指向新分配的进程结构体的指针
 * 失败：返回NULL
 *
 * 描述：
 * 该函数使用kmalloc分配一个proc_struct结构体的内存。
 * 如果分配成功，它将初始化该结构体的各个字段：
 * - cr3：设置为boot_cr3，即启动时的页表基地址
 * - tf：设置为NULL，表示没有陷阱帧
 * - state：设置为PROC_UNINIT，表示进程未初始化
 * - pid：设置为-1，表示进程ID未分配
 * - runs：设置为0，表示进程尚未运行
 * - kstack：设置为0，表示内核栈未分配
 * - need_resched：设置为0，表示不需要重新调度
 * - parent：设置为NULL，表示没有父进程
 * - mm：设置为NULL，表示没有内存管理信息
 * - flags：设置为0，表示没有特殊标志
 * - context：使用memset清零，初始化上下文
 * - name：使用memset清零，初始化进程名称
 */
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        proc->cr3 = boot_cr3;
        proc->tf = NULL;
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        proc->flags = 0;
        memset(&(proc->context), 0, sizeof(struct context));
        memset(proc->name, 0, PROC_NAME_LEN);
    }
    return proc;
}
```



#### **成员变量含义和作用：**

- `struct context context`：存储进程执行的上下文信息，主要包括一些关键寄存器的值。这些信息用于在进程切换时恢复之前的执行状态。当通过`proc_run`函数将进程调度到CPU上执行时，需要调用`switch_to`函数来保存当前进程的寄存器状态，以便在下次切换回该进程时能够恢复其先前的执行状态。
- `struct trapframe *tf`：用于存储进程的中断帧，该中断帧包含了32个通用寄存器以及与异常处理相关的寄存器。当进程从用户空间切换到内核空间时，系统调用会修改这些寄存器的值。通过修改中断帧的内容，我们可以控制系统调用返回时的特定值。例如，可以使用`s0`和`s1`寄存器来传递线程执行的函数及其参数；在创建子线程时，通常会将中断帧中的`a0`寄存器设置为`0`，以指示系统调用的成功或失败状态。



## 练习 2：为新创建的内核线程分配资源（需要编码）

### 题目

> 创建一个内核线程需要分配和设置好很多资源。kernel_thread 函数通过调用 **do_fork** 函数完成具体内核线程的创建工作。do_kernel 函数会调用 alloc_proc 函数来分配并初始化一个进程控制块，但 alloc_proc 只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore 一般通过 do_fork 实际创建新的内核线程。do_fork 的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们 **实际需要 "fork" 的东西就是 stack 和 trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在 kern/process/proc.c 中的 do_fork 函数中的处理过程。它的大致执行步骤包括：
>
> - 调用 alloc_proc，首先获得一块用户信息块。
> - 为进程分配一个内核栈。
> - 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
> - 复制原进程上下文到新进程
> - 将新进程添加到进程列表
> - 唤醒新进程
> - 返回新进程号
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请说明 ucore 是否做到给每个新 fork 的线程一个唯一的 id？请说明你的分析和理由。

### 分析

可以根据实验指导书上的流程，我们可以知道，首先需要调用 `alloc_proc` 分配一个新的 `proc_struct` 结构体来表示新进程。如果分配成功，接着调用 `setup_kstack` 为新进程分配内核栈。然后，设置新进程的父进程为当前进程，并调用 `copy_mm` 根据 `clone_flags` 复制或共享内存管理信息。之后，使用 `copy_thread` 设置新进程的中断帧和上下文。接着，为新进程分配一个进程ID（PID），并将新进程的 `proc_struct` 插入到哈希列表和进程列表中。最后，将新进程的状态设置为 `PROC_RUNNABLE`，表示进程已准备好运行，并将新进程的PID设置为返回值。



### 解答

#### **代码实现**

```c
// 分配一个新的进程结构体
proc = alloc_proc();
// 检查是否成功分配
if (proc == NULL) {
    // 如果分配失败，跳转到fork_out进行错误处理
    goto fork_out;
}
// 为新进程分配内核栈
if (setup_kstack(proc) == ret) {
    // 如果内核栈分配失败，跳转到bad_fork_cleanup_kstack进行错误处理
    goto bad_fork_cleanup_kstack;
}

// 设置新进程的父进程为当前进程
proc->parent = current;

// 根据clone_flags复制或共享内存管理信息
if (copy_mm(clone_flags, proc) != 0) {
    // 如果内存管理信息复制或共享失败，跳转到bad_fork_cleanup_proc进行错误处理
    goto bad_fork_cleanup_proc;
}

// 设置新进程的中断帧和上下文
copy_thread(proc, stack, tf);
// 为新进程分配一个进程ID（PID）
proc->pid = get_pid();
// 将新进程的proc_struct插入到哈希列表中
hash_proc(proc);
// 将新进程的proc_struct插入到进程列表中
list_add(&proc_list, &(proc->list_link));
// 增加进程计数器
nr_process++;
// 将新进程的状态设置为PROC_RUNNABLE，表示进程已准备好运行
proc->state = PROC_RUNNABLE;
// 设置返回值为新进程的PID
ret = proc->pid;

// 错误处理出口
fork_out:
    // 返回新进程的PID或错误代码
    return ret;

// 内核栈分配失败的错误处理
bad_fork_cleanup_kstack:
    // 释放内核栈
    put_kstack(proc);
// 进程结构体分配失败的错误处理
bad_fork_cleanup_proc:
    // 释放进程结构体
    kfree(proc);
    // 跳转到错误处理出口
    goto fork_out;
}
```



#### **问题解答：**

可以知道ucore是通过get_pid()函数来给每个进程分配id。通过分析该函数不难发现ucore 能够做到给每个新 fork 的线程一个唯一的 id。下面是对get_pid函数的详细分析：

1. **初始化变量**：首先检查 `MAX_PID > MAX_PROCESS`，确保系统的PID池足够大，能容纳所有可能的进程。然后通过静态变量 `next_safe` 和 `last_pid` 来追踪已经分配的PID，防止重复分配。`next_safe` 初始值为 `MAX_PID`，`last_pid` 也是 `MAX_PID`，表示开始时没有分配PID。
2. **PID分配逻辑**：每次调用该函数时，`last_pid` 会递增，直到达到 `MAX_PID`。如果 `last_pid` 达到最大值，则会重置为1，开始从头分配。此时，进入 `inside` 标签，重置 `next_safe` 为 `MAX_PID`，然后进入 `repeat` 标签。
3. **检查PID的可用性**：在 `repeat` 标签内，函数遍历进程列表 `proc_list`，检查每个进程的PID。如果发现当前PID `last_pid` 已经被某个进程占用，那么就将 `last_pid` 加1，并继续检查。如果加到超过 `next_safe`，则更新 `next_safe` 为当前进程PID，从而确保下次分配的PID不会与已有的进程PID冲突。
4. **返回唯一PID**：一旦找到未被占用的PID，函数就返回该PID作为分配给新进程的唯一标识符。

```c
static int get_pid(void) {
    // 静态断言，确保最大PID值大于最大进程数
    static_assert(MAX_PID > MAX_PROCESS);

    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    
    // 静态变量，next_safe 记录下一个安全的PID，last_pid记录上次分配的PID
    static int next_safe = MAX_PID, last_pid = MAX_PID;

    // 如果 last_pid 已经达到最大PID，重新从1开始分配
    if (++last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }

    // 如果当前 last_pid 大于等于 next_safe，进入内部检查循环
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        
        // 遍历进程列表，查找是否有与 last_pid 相同的 PID
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);

            // 如果找到与 last_pid 相同的进程PID，则跳过此PID，继续查找下一个
            if (proc->pid == last_pid) {
                if (++last_pid >= next_safe) {
                    // 如果 last_pid 已经超过了 next_safe，重新初始化
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;  // 超过最大PID时从1开始
                    }
                    next_safe = MAX_PID;
                    goto repeat;  // 重新开始查找
                }
            }
            // 如果当前进程的PID大于last_pid，且 next_safe 大于当前进程的PID，则更新 next_safe
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    // 返回唯一的可用 PID
    return last_pid;
}

```





## 练习 3：编写 proc_run 函数（需要编码）

### 题目

> proc_run 用于将指定的进程切换到 CPU 上运行。它的大致执行步骤包括：
>
> - 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
> - 禁用中断。你可以使用 `/kern/sync/sync.h` 中定义好的宏 `local_intr_save(x)` 和 `local_intr_restore(x)` 来实现关、开中断。
> - 切换当前进程为要运行的进程。
> - 切换页表，以便使用新进程的地址空间。`/libs/riscv.h` 中提供了 `lcr3(unsigned int cr3)` 函数，可实现修改 CR3 寄存器值的功能。
> - 实现上下文切换。`/kern/process` 中已经预先编写好了 `switch.S`，其中定义了 `switch_to()` 函数。可实现两个进程的 context 切换。
> - 允许中断。
>
> 请回答如下问题：
>
> - 在本实验的执行过程中，创建且运行了几个内核线程？
>
> 完成代码编写后，编译并运行代码：make qemu
>
> 如果可以得到如 附录 A 所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

### 分析

#### 1. **检查进程是否相同**

在进程切换的开始阶段，操作系统首先检查当前要切换的目标进程是否与当前进程相同。如果目标进程已经是当前进程，那么无需进行切换，直接返回即可。这个步骤的目的是避免不必要的切换开销。

- **理论依据**：进程切换是一个开销较大的操作，包括保存和恢复进程的上下文以及管理资源等。如果目标进程与当前进程相同，跳过上下文切换可以有效提高系统的效率，减少无效的操作。

#### 2. **关闭中断**

在进行进程切换之前，操作系统通常会禁用中断。这是为了确保进程切换的**原子性**，即在切换过程中不被中断打断。中断可能会改变进程的执行状态，导致切换过程中的不一致或错误。

- 理论依据

  ：

  - **原子性**：上下文切换涉及保存和加载寄存器、堆栈、程序计数器等关键信息。如果在切换过程中发生中断，可能会导致部分上下文信息丢失或破损，最终导致系统不稳定。因此，通过禁用中断可以确保上下文切换过程中的操作是原子的，保证进程切换的一致性。
  - **竞争条件**：如果中断发生在上下文切换过程中，可能会导致系统的资源（如进程调度队列、CPU寄存器等）进入不一致状态。禁用中断可以防止这种情况发生，避免产生竞争条件或死锁。

#### 3. **切换页表**

每个进程都有自己的虚拟地址空间，因此每个进程需要使用不同的页表来映射虚拟地址到物理地址。在进程切换时，操作系统需要更新CR3寄存器（或其他特定的控制寄存器），从而切换到目标进程的页表。

- 理论依据

  ：

  - **虚拟内存隔离**：现代操作系统支持虚拟内存，每个进程都有独立的虚拟地址空间。为了保护进程的隐私和系统的安全，必须确保每个进程使用不同的页表。当一个进程切换到另一个进程时，操作系统需要更新页表基址（例如修改CR3寄存器），以确保新的进程能访问到其自己的虚拟内存空间。
  - **硬件支持**：CPU的内存管理单元（MMU）使用CR3等寄存器来控制虚拟地址到物理地址的映射。切换进程时，操作系统需要根据目标进程的页表更新这些寄存器，从而切换进程的虚拟内存空间。

#### 4. **上下文切换**

上下文切换是指将当前进程的状态（寄存器、堆栈、程序计数器等）保存到当前进程的控制块中，然后将目标进程的状态从控制块中加载到CPU中。这个过程通常涉及两个主要步骤：

- 保存当前进程的上下文（保存寄存器、堆栈等）。
- 恢复目标进程的上下文（恢复寄存器、堆栈等）。
- **理论依据**：
  - **进程状态保存与恢复**：进程的状态由多个寄存器、堆栈指针、程序计数器等组成。这些状态信息必须在进程切换时保存，以便下次调度时能够恢复执行。上下文切换的核心操作是保存当前进程的执行状态，并恢复目标进程的执行状态。
  - **效率和复杂性**：上下文切换的效率直接影响操作系统的性能。操作系统需要在有限的时间内完成上下文的保存和恢复，以最小化上下文切换的开销。

#### 5. **启动中断**

完成上下文切换后，操作系统恢复了目标进程的上下文，并且允许系统重新响应中断。恢复中断是为了确保系统的正常运行，尤其是在多任务环境下，进程切换完成后，系统需要继续响应外部事件（如时钟中断、I/O中断等）。

- 理论依据

  ：

  - **中断响应**：禁用中断只是为了保证进程切换的原子性，一旦上下文切换完成，操作系统需要恢复中断处理，以保证外部事件能够得到及时响应。恢复中断确保系统能够处理硬件中断、定时中断、系统调用等外部事件，维持系统的正常调度和操作。
  - **多任务和实时性**：一旦进程切换完成并恢复中断，操作系统能够重新处理外部的中断请求，这对于实时操作系统尤其重要，可以确保及时响应定时任务或硬件事件。



### 解答

#### **代码实现**

```c
void proc_run(struct proc_struct *proc) {
    // 如果目标进程和当前进程不同，则进行进程切换
    if (proc != current) {
        // 关闭中断，确保进程切换过程中的原子性
        // `local_intr_save` 会禁用中断并保存当前的中断状态
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;

        local_intr_save(intr_flag);

        {
            // 更新当前进程指针为目标进程
            current = proc;

            // 切换到目标进程的页表。`lcr3` 用于设置CR3寄存器
            // CR3寄存器指向目标进程的页表基址
            lcr3(next->cr3);

            // 执行上下文切换。`switch_to` 函数会保存当前进程的上下文，
            // 并加载目标进程的上下文，完成进程间的切换
            switch_to(&(prev->context), &(next->context));
        }

        // 恢复中断，允许中断处理程序响应系统事件
        local_intr_restore(intr_flag);
    }
}

```



#### **问题解答：**

一共创建了两个线程。

第一个是`idle`，在完成新的内核线程的创建以及各种初始化工作之后，进入死循环，用于调度其他进程或线程；

第二个是执行`init_main`的`init`线程，打印"Hello world!!"。

```c
// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
```



## 扩展练习 Challenge

### 题目

> 说明语句 `local_intr_save(intr_flag);....local_intr_restore(intr_flag);` 是如何实现开关中断的？

### 分析

相关代码如下：

```c
/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

### 解答

#### 1. **`intr_enable` 和 `intr_disable`**

这两个函数分别用于启用和禁用中断，主要通过操作控制寄存器来实现。

- **`intr_enable`**：

  ```
  void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
  ```

  - `set_csr(sstatus, SSTATUS_SIE)` 是设置 CSR（控制和状态寄存器）的操作。具体来说，`sstatus` 是一个用于控制中断的寄存器，`SSTATUS_SIE` 是 `sstatus` 中用于启用中断的位（Supervisor Interrupt Enable）。
  - 当调用 `intr_enable` 时，这条指令将 `SSTATUS_SIE` 位设置为 1，表示启用 IRQ 中断。也就是说，操作系统允许处理外部中断（如时钟中断、I/O中断等）。

- **`intr_disable`**：

  ```
  void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
  ```

  - `clear_csr(sstatus, SSTATUS_SIE)` 则是清除 `sstatus` 中的 `SSTATUS_SIE` 位。这个操作将禁用中断，即中断无法再触发。
  - 调用 `intr_disable` 时，会禁止中断的处理。此时，如果发生中断，系统不会响应，直到恢复中断。

#### 2. **`__intr_save` 和 `__intr_restore`**

这两个内联函数用于保存当前中断状态并在之后恢复。它们用于提供一个便捷的接口来保存和恢复中断状态，通常在需要进行关键操作时（例如上下文切换）使用。

- **`__intr_save`**：

  ```
  static inline bool __intr_save(void) {
      if (read_csr(sstatus) & SSTATUS_SIE) {
          intr_disable();
          return 1;
      }
      return 0;
  }
  ```

  - 调用 `intr_disable()` 禁用中断。
  - 返回 `1`，表示中断之前是启用的。

  - 如果中断已经禁用，则直接返回 `0`。

  这个函数的作用是保存当前中断状态（即是否启用中断），并在需要时禁用中断。

- **`__intr_restore`**：

  ```
  static inline void __intr_restore(bool flag) {
      if (flag) {
          intr_enable();
      }
  }
  ```

  - `__intr_restore` 函数根据 `flag` 参数的值来决定是否恢复中断。如果 `flag` 为 `1`，说明之前启用了中断，那么调用 `intr_enable()` 恢复中断的启用状态。
  - 这样，可以确保在执行完关键操作后恢复原来的中断状态。

#### 3. **宏 `local_intr_save` 和 `local_intr_restore`**

这两个宏封装了 `__intr_save` 和 `__intr_restore`，提供了一种更简洁的方式来保存和恢复中断状态。

- **`local_intr_save(x)`**：

  ```
  #define local_intr_save(x) \
      do {                   \
          x = __intr_save(); \
      } while (0)
  ```

  - `local_intr_save(x)` 调用 `__intr_save()` 来保存当前中断状态，并将结果存储到 `x` 变量中。这个宏确保在关键操作前保存中断状态，避免中断的干扰。

- **`local_intr_restore(x)`**：

  ```
  #define local_intr_restore(x) __intr_restore(x);
  ```

  - `local_intr_restore(x)` 调用 `__intr_restore(x)` 恢复之前保存的中断状态。这样，系统可以恢复到原来的中断状态，确保系统在执行关键操作后能够继续响应中断。
