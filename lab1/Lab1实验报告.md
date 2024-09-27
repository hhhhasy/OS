# Lab1实验报告

## 练习一：理解内核启动中的程序入口操作

阅读 `kern/init/entry.S` 内容代码，结合操作系统内核启动流程，说明指令 `la sp, bootstacktop` 完成了什么操作，目的是什么？`tail kern_init` 完成了什么操作，目的是什么？

```assembly
#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop

    tail kern_init

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop:
```



### 回答：

#### `la sp, bootstacktop`完成了什么操作，目的是什么：

**完成的操作：**

1. **加载地址到寄存器**：指令 `la` 的目的是将一个地址加载到指定的寄存器中。在这里，`la sp, bootstacktop` 将 `bootstacktop` 的地址加载到栈指针寄存器 `$sp` 中。
2. **设置栈指针**：栈指针 (`$sp`) 是用来指向当前调用堆栈的顶部的寄存器。通过将 `bootstacktop` 的地址加载到 `$sp` 中，它将被设置为指向 `bootstacktop` 所代表的内存地址。

**目的：**

这个操作的目的是将`OpenSBI`模拟出来的物理内存地址（`bootstacktop`）赋值给栈指针 (`$sp`)。栈指针在操作系统中用于管理函数调用堆栈，确保函数的局部变量和返回地址正确地存储和检索。通过将 `$sp` 设置为 `bootstacktop`，操作系统内核可以开始使用 `bootstack` 作为函数调用堆栈的底部，从而支持函数的执行和任务切换等操作。



#### `tail kern_init` 完成了什么操作，目的是什么？

**完成的操作：**

通过`tail`尾调用方法调用`kern_init`函数，把操作权交给该函数，而且调用结束之后并不返回到`entry.S`。这是因为tail尾调用并不保存调用者的返回地址，而是会直接跳到被调用者的起始地址。

**目的：**

`kern_entry` 是内核的启动点，而 `kern_init` 是内核初始化的入口函数。通过使用 `tail kern_init`，代码直接跳转到了初始化函数，这样可以将执行流程无缝地传递给内核初始化过程，而不会在每次函数调用之间保留额外的调用堆栈帧。这有助于减少内存使用，提高执行效率。





## 练习二：完善中断处理：

请编程完善 trap.c 中的中断处理函数 trap，在对时钟中断进行处理的部分填写 kern/trap/trap.c 函数中处理时钟中断的部分，使操作系统每遇到 100 次时钟中断后，调用 print_ticks 子程序，向屏幕上打印一行文字“100 ticks”，在打印完 10 行后调用 sbi.h 中的 shut_down() 函数关机。

要求完成问题 1 提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明
实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每 1 秒会输出一次”
100 ticks”，输出 10 行。

### 回答：

```c
case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   YOUR CODE : 2210737/2212998/2210351 */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event(); 
            ticks+=1;
            if(ticks==100){
               ticks=0;
               cprintf("100ticks\n");
               num+=1;
            }
            if(num==10){
               sbi_shutdown();
            }
            break;
```

#### 执行`make qemu`：

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

