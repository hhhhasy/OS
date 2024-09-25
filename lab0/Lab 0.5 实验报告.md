#                                         **Lab 0.5 实验报告**

## 一、实验过程

### 练习1:启动GDB验证启动流程

*为了熟悉使用qemu和gdb进行调试工作,使用gdb调试QEMU模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程，说明RISC-V硬件加电后的几条指令在哪里？完成了哪些功能？要求在报告中简要写出练习过程和回答。*

#### 第一阶段：复位

1.首先进入到`riscv64-ucore-labcodes下的lab0中`，打开一个终端使用 `make debug` 进入到调试模式，然后再开一个终端输入`make gdb`进行调试。

2.进入gdb中,输入指令`x/10i $pc`可以查看到接下来要执行的十条指令。因为是刚开始的指令，所以这也是系统通电以后就要执行的十条指令。

```assembly
(gdb) x/10i $pc
=> 0x1000:	auipc	t0,0x0
   0x1004:	addi	a1,t0,32
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	t0,24(t0)
   0x1010:	jr	t0
   0x1014:	unimp
   0x1016:	unimp
   0x1018:	unimp
   0x101a:	0x8000
   0x101c:	unimp
```

3.接着输入指令`si`，可以单步执行指令，并且输入`info r t0`来获得指令涉及到的寄存器结果：

```assembly
(gdb) si
0x0000000000001004 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x0000000000001008 in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x000000000000100c in ?? ()
(gdb) info r t0
t0             0x1000	4096
(gdb) si       
0x0000000000001010 in ?? ()
(gdb) info r t0
t0             0x80000000	2147483648
(gdb) si       
0x0000000080000000 in ?? ()

```

分析一开始的十条指令和寄存器值后可以知道指令干了什么,其中在地址为`0x1010`的指令处会跳转，故实际执行的为以下指令：

```assembly
0x1000:	auipc	t0,0x0       # t0= pc+0x0 = 0x1000 = 4096
0x1004:	addi	a1,t0,32     # a1= t0+32 = 0x1000+32 = 0x1020
0x1008:	csrr	a0,mhartid   # a0= mhartid = 0
0x100c:	ld	    t0,24(t0)    # t0= [0x1000+24] = 0x80000000
0x1010:	jr	    t0           # j   0x80000000
```

#### 第二阶段：Bootloader即OpeSBI启动

1.进入到`0x80000000`后,输入`x/10i 0x80000000`，查看`0x80000000`处的10条数据。该地址处加载的是作为`qemu`的`bootloader`的`OpenSBI.bin`，该处的作用为加载操作系统内核并启动操作系统的执行。代码如下：

```assembly
0x80000000:	csrr	a6,mhartid
0x80000004:	bgtz	a6,0x80000108
0x80000008:	auipc	t0,0x0
0x8000000c:	addi	t0,t0,1032
0x80000010:	auipc	t1,0x0
0x80000014:	addi	t1,t1,-16
0x80000018:	sd	    t1,0(t0)
0x8000001c:	auipc	t0,0x0
0x80000020:	addi	t0,t0,1020
0x80000024:	ld	    t0,0(t0)
```

2.同样的，我们可以使用指令`si`和`info r t0`来了解寄存器的变化，在此就不再演示，直接给出代码解释：

```assembly
0x80000000:	csrr	a6,mhartid     # a6 = mhartid = 0
0x80000004:	bgtz	a6,0x80000108  # if (a6>0) j 0x80000108
0x80000008:	auipc	t0,0x0         # t0 = pc + 0x0 = 0x80000008
0x8000000c:	addi	t0,t0,1032     # t0 = t0 + 0x400 =0x80000408
0x80000010:	auipc	t1,0x0         # t1 = pc + 0x0 = 0x80000010
0x80000014:	addi	t1,t1,-16      # t1 = t0 - 0x10 = 0x80000000
0x80000018:	sd	    t1,0(t0)       # t1 -> [0x80000408]
0x8000001c:	auipc	t0,0x0         # t0 = pc + 0x0 = 0x8000001c
0x80000020:	addi	t0,t0,1020     # t0 = t0 + 1020 = 0x80000400
0x80000024:	ld	    t0,0(t0)       # t0 = [0x80000400]
```

通过实验指导书可以知道， `OpenSBI`启动之后将要跳转到的一段汇编代码：`kern/init/entry.S`。在这里进行内核栈的分配，然后转入C语言编写的内核初始化函数。而这段汇编代码的地址是固定的`0x80200000`。

3.所以我们输入指令`break kern_entry`，在目标函数`kern_entry`的第一条指令处设置断点，输出如下：

```assembly
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
```

4.当然我们也可以输入指令`x/5i 0x80200000`，查看汇编代码：

```assembly
0x80200000 <kern_entry>  :	auipc  sp,0x3
0x80200004 <kern_entry+4>:	mv	   sp,sp
0x80200008 <kern_entry+8>:	j	   0x8020000c <kern_init>
0x8020000c <kern_init>   :	auipc  a0,0x3
0x80200010 <kern_init+4> :	addi   a0,a0,-4
```

不难发现，在`0x80200008`地址处，程序跳转到了`kern_init`，在该函数里完成内核的其他初始化工作。

5.然后输入`continue`执行直到断点，`make debug`终端输出如下：

```assembly
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)

```

可以发现，作为`bootloader`的`opensbi`已经启动。

同时gdb窗口显示：

```assembly
(gdb) c
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7	    la sp, bootstacktop
```

在这行代码中，执行了一个 `la` 指令，用于将栈指针寄存器 `sp` 设置为 `bootstacktop` 的值。

#### 第三阶段：内核镜像启动

1.为了对`kern_init`进行分析，接着输入`break kern_init`,输出如下：

```assembly
Breakpoint 2 at 0x8020000c: file kern/init/init.c, line 8.
```

2.输入`continue`运行到第二个断点处，接着输入`disassemble kern_init`查看`kern_init`函数的反汇编代码：

```assembly
0x000000008020000c <+0>:	auipc	a0,0x3
0x0000000080200010 <+4>:	addi	a0,a0,-4 # 0x80203008
0x0000000080200014 <+8>:	auipc	a2,0x3
0x0000000080200018 <+12>:	addi	a2,a2,-12 # 0x80203008
0x000000008020001c <+16>:	addi	sp,sp,-16
0x000000008020001e <+18>:	li	a1,0
0x0000000080200020 <+20>:	sub	a2,a2,a0
0x0000000080200022 <+22>:	sd	ra,8(sp)
0x0000000080200024 <+24>:	jal	ra,0x802004ce <memset>
0x0000000080200028 <+28>:	auipc	a1,0x0
0x000000008020002c <+32>:	addi	a1,a1,1208 # 0x802004e0
0x0000000080200030 <+36>:	auipc	a0,0x0
0x0000000080200034 <+40>:	addi	a0,a0,1232 # 0x80200500
0x0000000080200038 <+44>:	jal	ra,0x80200058 <cprintf>
0x000000008020003c <+48>:	j	0x8020003c <kern_init+48>     #总是跳到自己
```

通过反汇编代码可以发现，`kern_init`函数最后总是会跳到本身，所以最终会进入到死循环中，我们也可以输入指令`continue`验证结果。`make debug`终端结果如下：

```assembly
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
(THU.CST) os is loading ...
```

## 二、实验结果

### 1、RISC-V硬件加电后的几条指令在哪里？

通过实验可以知道，RISC-V硬件加电后的几条指令从`0x1000`地址开始，直到在`0x1010`处进行跳转结束。

### 2、完成的功能有哪些？

1. `auipc t0,0x0`：用于加载一个20bit的立即数，`t0`中保存的数据为 `pc+0x0`,用于PC相对寻址。
2. `addi	a1,t0,32`：将`t0`加上`32`，赋值给`a1`。
3. `csrr	a0,mhartid`：读取状态寄存器`mhartid`，存入`a0`中。`mhartid`为正在运行代码的硬件线程的整数ID。
4. `ld	    t0,24(t0)`：加载从`t0+24`地址处读取8个字节，存入`t0`。
5. `jr	    t0`：将程序跳到作为`bootloader`的`OpenSBI.bin`此处为`0x80000000`）。

## 三、实验感悟

通过本次实验，我们小组认为的重要知识点有：

1. 要在执行`make debug`之后才能运行`make gdb`，并且两者还必须要在两个终端中运行，要是直接执行`make gdb`的话，程序会输出：

   ```assembly
   localhost:1234: Connection timed out.
   ```

2. 整个最小可执行内核的执行流为:首先要上电，然后`$pc`从`0x1000`开始取指令，到`0x1010`的时候跳转到`0x80000000` 处，也就是`opensbi`处。然后`opensbi`跳转到 `0x80200000` (`kern/init/entry.S`）接着进入`kern_init()`函数（`kern/init/init.c`) 最后调用`cprintf()`输出一行信息然后结束。
3. `Qemu`的内核地址为`0x80200000`，因为`Qemu`的内核代码是地址相关代码，是由处理器，即`Qemu`共同指定的。

## 四、补充知识点