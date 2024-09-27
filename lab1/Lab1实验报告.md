# Lab1实验报告

## 练习一：理解内核启动中的程序入口操作

### 题目：

>   阅读`kern/init/entry.S`内容代码，结合操作系统内核启动流程，说明指令`la sp, bootstacktop`完成了什么操作，目的是什么？`tail kern_init`完成了什么操作，目的是什么？

### 分析：

#### 查看并分析`kern/init/entry.S`代码：

```assembly
#include <mmu.h>
#include <memlayout.h>

# 从此开始定义.text段，存放可执行代码
    .section .text,"ax",%progbits
# 将符号kern_entry声明为全局，以便链接时能找到该符号
    .globl kern_entry

kern_entry:
    # 将内核栈的顶部地址加载到堆栈指针sp，准备使用栈空间
    la sp, bootstacktop

    # 跳转到内核初始化函数kern_init，并不会返回到当前函数
    tail kern_init

# 从此开始定义.data段，用于存放全局或静态数据
.section .data
# 按页大小对齐内存，确保数据以页为单位对齐，提升内存管理效率
    .align PGSHIFT
# 声明并分配内核堆栈空间
    .global bootstack
bootstack:
    # 分配KSTACKSIZE大小的内存作为内核栈
    .space KSTACKSIZE
# 声明栈顶符号，指向栈的顶部
    .global bootstacktop
bootstacktop:
```

#### `la sp, bootstacktop` 的理解

##### 操作：

- **加载地址到栈指针寄存器（SP）**：指令 `la` 是 RISC-V 的伪指令，用于将标签 `bootstacktop` 代表的内存地址加载到寄存器中。在这个指令中，它将 `bootstacktop` 的地址加载到栈指针寄存器 `sp` 中。

- **设置栈指针**：栈指针 `sp`（Stack Pointer）用来指向当前调用栈的顶部，通过将 `bootstacktop` 的地址加载到 `sp`，栈指针被初始化，指向内核栈的顶部。

##### 目的：

- **初始化内核栈**：`la sp, bootstacktop` 通过设置栈指针，确保内核启动时的堆栈空间可用。操作系统在执行过程中需要栈来保存函数调用的局部变量、返回地址、上下文切换等。因此，在内核启动初期，正确设置栈指针是确保内核正常工作的基础。

- **内核栈的分配与初始化**：`bootstack` 定义了内核栈的底部，而 `bootstacktop` 定义了栈的顶部。由于栈的增长方向是从高地址向低地址，栈指针设置为栈的顶部以开始使用内核栈。

#### `tail kern_init` 的理解

##### 操作：

- **尾调用**：`tail` 是 RISC-V 的尾调用伪指令，它表示跳转到函数 `kern_init`，并且不保存当前函数 `kern_entry` 的返回地址。这种跳转方式不会为新的函数调用分配额外的栈空间，因此 `kern_entry` 的栈帧会被释放。

- **跳转到内核初始化函数**：`kern_init` 是内核的初始化函数，执行操作系统的核心初始化任务。通过 `tail kern_init`，控制权从当前的 `kern_entry` 转移到 `kern_init`，并不会返回到 `kern_entry`。

##### 目的：

- **内核启动流程的转移**：`kern_entry` 是整个内核的启动入口，负责完成基本的设置（如栈的初始化），而真正的内核初始化操作由 `kern_init` 执行。`tail kern_init` 将执行流程从 `kern_entry` 转移到 `kern_init`，开始内核的初始化过程。

- **优化函数调用**：尾调用是一种优化的函数调用方式，它减少了函数调用的开销，避免了多余的栈帧，节省内存空间并提高了性能。在这个场景下，使用 `tail` 可以避免在启动过程中消耗不必要的栈空间，从而使内核的启动更加高效。

### 解答：

1. **`la sp, bootstacktop` 完成了什么操作，目的是什么？**
    - **操作**：将内核栈顶地址 `bootstacktop` 加载到栈指针 `sp`，从而初始化内核栈。
    - **目的**：确保内核启动时有一个有效的栈空间，用于保存函数调用的局部变量、返回地址和其他上下文信息，使内核能够正确执行。

2. **`tail kern_init` 完成了什么操作，目的是什么？**
    - **操作**：通过尾调用跳转到 `kern_init` 函数，执行内核初始化操作，并不会返回到 `kern_entry`。
    - **目的**：进入内核初始化阶段，避免多余的函数调用开销，提高内核启动的效率。尾调用避免了不必要的栈帧占用，从而使启动过程更加高效。

## 练习二：完善中断处理 （需要编程）

### 题目：

>   请编程完善`trap.c`中的中断处理函数`trap`，在对时钟中断进行处理的部分填写`kern/trap/trap.c`函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用`print_ticks`子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用`sbi.h`中的`shut_down()`函数关机。
>
>   要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

### 回答：

#### 实现过程：

1. **时钟中断的初始化**：

时钟中断的初始化通过 `clock_init()` 函数完成。该函数主要负责配置处理器的时钟中断，使得系统能够捕获和处理定时器中断。

- **启用时钟中断**：  
    `set_csr(sie, MIP_STIP)`  
    这行代码通过设置处理器的 `sie` 寄存器，启用定时器中断功能。`MIP_STIP` 用于表示 supervisor 模式下的定时器中断允许标志位。

- **设置下一次中断**：  
    `clock_set_next_event()`  
    该函数通过计算下一次定时器触发的时刻，确保时钟中断按固定的时间间隔触发。每次触发时钟中断后，系统会调用该函数设置下一次中断的时间。

2. **中断处理流程**：

当定时器中断触发时，CPU 会根据 `stvec` 寄存器跳转到中断处理函数 `trap()`。在中断处理过程中，操作系统会通过 `trap_dispatch()` 来分发中断，最终调用 `interrupt_handler()` 函数执行具体的中断处理。

中断处理的大致流程如下：

- **trap() 函数**：这是捕获所有中断的入口函数。该函数通过读取 `trapframe` 中的 `cause` 字段来判断是哪种类型的中断，并根据中断类型执行不同的处理逻辑。
- **trap_dispatch() 函数**：根据中断原因（例如定时器中断、外部中断等），将中断分发给相应的处理函数。
- **interrupt_handler() 函数**：具体处理时钟中断的逻辑就在这个函数中实现。在确定是时钟中断 (`IRQ_S_TIMER`) 后，处理时钟中断的逻辑会继续执行。

3. **定时器中断的核心处理**：

在 `trap.c` 中的 `interrupt_handler` 函数内，时钟中断的处理逻辑主要包含以下几个步骤：

- **设置下次时钟中断**：  
    调用 `clock_set_next_event()` 函数设置下一个时钟中断事件，确保定时器按时触发。

- **计数器管理**：  
    通过一个 `ticks` 变量记录已经发生的时钟中断次数。每次发生时钟中断时，`ticks` 自增 1，当 `ticks` 达到 100 时，表示系统已经经历了 100 次时钟中断。

- **输出提示信息**：  
    当 `ticks` 达到 100 时，调用 `print_ticks()` 函数输出 "100 ticks" 到屏幕上，并将 `ticks` 重置为 0，同时增加 `num` 变量，用来记录已经打印 "100 ticks" 的次数。

- **关机处理**：  
    如果 `num` 变量达到 10，表示系统已经打印了 10 次 "100 ticks"，此时调用 `sbi_shutdown()` 函数，关闭系统。

#### 核心代码实现：

以下是对 `trap.c` 中定时器中断部分代码的补充：

```c
case IRQ_S_TIMER:
    // 设置下次时钟中断，确保时钟继续运行
    clock_set_next_event();  
    
    // 每发生一次时钟中断，ticks 自增
    ticks++;  
    
    // 如果 ticks 达到 100，则输出 "100 ticks"
    if (ticks == 100) {
        cprintf("100 ticks\n");
        ticks = 0;  // 重置时钟计数器
        num++;      // 打印次数计数器自增
    }
    
    // 如果已经打印了 10 次 "100 ticks"，则关机
    if (num == 10) {
        sbi_shutdown();  // 调用关机函数
    }
    break;
```

#### 代码详细说明：

- **时钟中断设置**：  
    在处理每次时钟中断时，首先调用 `clock_set_next_event()` 函数，重新设置下次中断的触发时间。这确保了时钟中断能够持续触发，保证系统的定时功能。

- **计数器管理**：  
    `ticks++` 用于记录系统已经发生的时钟中断次数。每发生一次中断，`ticks` 自增 1。当 `ticks` 达到 100 时，表示系统已经遇到了 100 次时钟中断，此时触发打印 "100 ticks"。

- **打印提示信息**：  
    当系统累计发生 100 次时钟中断后，调用 `cprintf("100 ticks\n")` 将信息输出到控制台。之后，将 `ticks` 重置为 0，重新开始下一轮计数。同时，`num++` 用于记录系统已经输出了多少次 "100 ticks"。

- **关机逻辑**：  
    系统在输出 10 次 "100 ticks" 之后，调用 `sbi_shutdown()` 函数关机。该函数负责关闭系统，确保系统在完成特定任务后能够正确结束。

#### 定时器中断处理流程：

1. **中断触发**：定时器硬件根据预设时间间隔触发中断，处理器收到中断信号。
2. **CPU跳转到中断处理入口**：CPU 根据 `stvec` 寄存器的值跳转到中断处理函数 `trap()`。
3. **保存上下文**：`trap()` 函数首先保存当前程序的上下文信息，以便在中断处理完成后恢复程序的执行状态。
4. **分发中断**：`trap_dispatch()` 根据中断原因（例如定时器中断）分发到相应的中断处理函数。在时钟中断的情况下，最终调用 `interrupt_handler()`。
5. **时钟中断处理**：处理时钟中断，包括设置下次中断时间、管理计数器、打印信息、以及执行关机操作。
6. **恢复上下文**：中断处理完成后，恢复被中断的程序状态，继续执行原来的程序。

#### 实现结果：

通过上述代码的实现，每次时钟中断触发后，`ticks` 变量会自增，每 100 次时钟中断打印一次 "100 ticks"。当系统累计打印 10 次 "100 ticks" 后，调用 `sbi_shutdown()` 函数关闭系统。输出如下：

```assembly
Special kernel symbols:
  entry  0x000000008020000a (virtual)
  etext  0x00000000802009be (virtual)
  edata  0x0000000080204010 (virtual)
  end    0x0000000080204028 (virtual)
Kernel executable memory footprint: 17KB
++ setup timer interrupts
100ticks
100ticks
100ticks
100ticks
100ticks
100ticks
100ticks
100ticks
100ticks
100ticks
```



## 扩展练习Challenge1：描述与理解中断流程

### 题目：

> 描述 ucore 中处理中断异常的流程（从异常的产生开始），其中 mov a0，sp 的目的是什么？SAVE_ALL中寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

### 分析：

#### 查看并分析trapentry.S

```assembly
#include <riscv.h>

    .macro SAVE_ALL

    csrw sscratch, sp

    addi sp, sp, -36 * REGBYTES
    # save x registers
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)
    STORE x3, 3*REGBYTES(sp)
    STORE x4, 4*REGBYTES(sp)
    STORE x5, 5*REGBYTES(sp)
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)
    STORE x9, 9*REGBYTES(sp)
    STORE x10, 10*REGBYTES(sp)
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    # get sr, epc, badvaddr, cause
    # Set sscratch register to 0, so that if a recursive exception
    # occurs, the exception vector knows it came from the kernel
    csrrw s0, sscratch, x0
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm

    .macro RESTORE_ALL

    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)

    csrw sstatus, s1
    csrw sepc, s2

    # restore x registers
    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    LOAD x4, 4*REGBYTES(sp)
    LOAD x5, 5*REGBYTES(sp)
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)
    LOAD x9, 9*REGBYTES(sp)
    LOAD x10, 10*REGBYTES(sp)
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    # restore sp last
    LOAD x2, 2*REGBYTES(sp)
    #addi sp, sp, 36 * REGBYTES
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL

    move  a0, sp
    jal trap
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

通过查看并分析代码，可以知道各个代码段的主要功能：

1. **`__alltraps：`**通过调用`SAVE_ALL`宏来保存进程上下文，然后通过指令`move  a0, sp`来初始化参数寄存器a0,接着跳转到`trap`函数处理不同类型的中断。
2. **`SAVE_ALL：`**在该宏里面，首先使用指令`addi sp, sp, -36 * REGBYTES`给寄存器开辟空间，然后把上下文保存到栈里面，其中不止包括通用寄存器，还有各种状态寄存器如`sstatus`，`sepc`,`scause`等。
3. **`RESTORE_ALL：`**在中断或异常处理结束之后，使用该宏来恢复上下文。
4. **`__trapret：`**在该标签里，使用`RESTORE_ALL`来恢复上下文，最后使用`sret`跳转去执行异常出现的下一条指令。



### 解答：

### ucore 中处理中断异常的流程

1. **异常产生**
   - 中断异常是由于某种事件（例如外部硬件触发的事件，例如时钟中断或外部设备输入）而引发的。当这样的事件发生时，处理器会产生一个异常。在我们本次代码中，程序通过`clock_init()`来产生一次时钟中断。

2. **捕获异常**
   - 在程序产生异常或中断之后，程序会捕获到异常，并访问`stvec`寄存器，来定位中断处理程序。若`stvec`寄存器最低2位是00，则说明其高位保存的是唯一的中断处理程序的地址；如果是01，说明其高位保存的是中断向量表的地址，操作系统通过不同的异常原因来索引中断向量表以获取处理程序的地址。在本次实验中，是在第一种情况下进行实验，并且中断处理地址为：`__alltraps`。

3. **处理异常**
   - 进入到`__alltraps`之后，通过`SAVE_ALL`来保存上下文，然后进入`trap()`函数进行处理。在`trap`函数中，首先通过tp->scause来判断异常种类，然后进入到相应的处理函数进行处理。在处理结束之后，跳转到`__trapret`,主要是通过`RESTORE_ALL`汇编宏恢复各个寄存器的值，然后通过`sret`指令把`sepc`的值赋值给`pc`，继续执行中断指令之后的程序指令。

### mov a0，sp 的目的是什么？

首先查看并分析trap函数：

```c
void trap(struct trapframe *tf) { trap_dispatch(tf); }
```

 通过分析可知，trap函数只需要一个指针型参数，而riscv64中，参数寄存器为a0-a7。所以在调用`trap`函数之前，要把栈顶指针寄存器`$sp`的值放到ao寄存器里面，这是因为在执行完`SAVE_ALL`宏之后，`$sp`寄存器里面保存着当前的中断帧，从而实现对中断的处理。



### SAVE_ALL中寄存器保存在栈中的位置是什么确定的？

在`SAVE_ALL`宏中，各个寄存器保存的位置是通过栈顶寄存器sp来索引的。在保存上下文之前程序首先通过指令`addi sp, sp, -36 * REGBYTES`，在内存中开辟出了保存上下文的内存区域，然后我们通过栈顶指针sp来访问该段区域的不同位置，从而把对应的寄存器保存在栈中。              

   

### 对于任何中断，`__alltraps` 中都需要保存所有寄存器吗？

`__alltraps` 需要保存所有寄存器，其目的是为了处理各种类型的异常，以确保在异常处理程序中能够访问所有的寄存器状态。



## 拓展练习Challenge3：完善异常中断

### 题目：

> 编程完善异常中断

### 解答：

```c
case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE :2210737/2212998/2210351  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Illegal instruction\n");
            cprintf("%x",tf->epc);
            tf->epc+=8;//因为是64位，所以需要8个字节
            break;

case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE :2210737/2212998/2210351  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("breakpoint\n");
            cprintf("%x",tf->epc);
            tf->epc+=8;//因为是64位，所以需要8个字节
            break;
```

