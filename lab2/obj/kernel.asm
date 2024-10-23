
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	52660613          	addi	a2,a2,1318 # ffffffffc0206560 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	6d2010ef          	jal	ra,ffffffffc020171c <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	6de50513          	addi	a0,a0,1758 # ffffffffc0201730 <etext+0x2>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	7e1000ef          	jal	ra,ffffffffc0201046 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	1a0010ef          	jal	ra,ffffffffc0201246 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	16a010ef          	jal	ra,ffffffffc0201246 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00001517          	auipc	a0,0x1
ffffffffc0200140:	61450513          	addi	a0,a0,1556 # ffffffffc0201750 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00001517          	auipc	a0,0x1
ffffffffc0200156:	61e50513          	addi	a0,a0,1566 # ffffffffc0201770 <etext+0x42>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00001597          	auipc	a1,0x1
ffffffffc0200162:	5d058593          	addi	a1,a1,1488 # ffffffffc020172e <etext>
ffffffffc0200166:	00001517          	auipc	a0,0x1
ffffffffc020016a:	62a50513          	addi	a0,a0,1578 # ffffffffc0201790 <etext+0x62>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <free_area>
ffffffffc020017a:	00001517          	auipc	a0,0x1
ffffffffc020017e:	63650513          	addi	a0,a0,1590 # ffffffffc02017b0 <etext+0x82>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3da58593          	addi	a1,a1,986 # ffffffffc0206560 <end>
ffffffffc020018e:	00001517          	auipc	a0,0x1
ffffffffc0200192:	64250513          	addi	a0,a0,1602 # ffffffffc02017d0 <etext+0xa2>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	7c558593          	addi	a1,a1,1989 # ffffffffc020695f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00001517          	auipc	a0,0x1
ffffffffc02001c0:	63450513          	addi	a0,a0,1588 # ffffffffc02017f0 <etext+0xc2>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00001617          	auipc	a2,0x1
ffffffffc02001ce:	65660613          	addi	a2,a2,1622 # ffffffffc0201820 <etext+0xf2>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	66250513          	addi	a0,a0,1634 # ffffffffc0201838 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00001617          	auipc	a2,0x1
ffffffffc02001ea:	66a60613          	addi	a2,a2,1642 # ffffffffc0201850 <etext+0x122>
ffffffffc02001ee:	00001597          	auipc	a1,0x1
ffffffffc02001f2:	68258593          	addi	a1,a1,1666 # ffffffffc0201870 <etext+0x142>
ffffffffc02001f6:	00001517          	auipc	a0,0x1
ffffffffc02001fa:	68250513          	addi	a0,a0,1666 # ffffffffc0201878 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00001617          	auipc	a2,0x1
ffffffffc0200208:	68460613          	addi	a2,a2,1668 # ffffffffc0201888 <etext+0x15a>
ffffffffc020020c:	00001597          	auipc	a1,0x1
ffffffffc0200210:	6a458593          	addi	a1,a1,1700 # ffffffffc02018b0 <etext+0x182>
ffffffffc0200214:	00001517          	auipc	a0,0x1
ffffffffc0200218:	66450513          	addi	a0,a0,1636 # ffffffffc0201878 <etext+0x14a>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00001617          	auipc	a2,0x1
ffffffffc0200224:	6a060613          	addi	a2,a2,1696 # ffffffffc02018c0 <etext+0x192>
ffffffffc0200228:	00001597          	auipc	a1,0x1
ffffffffc020022c:	6b858593          	addi	a1,a1,1720 # ffffffffc02018e0 <etext+0x1b2>
ffffffffc0200230:	00001517          	auipc	a0,0x1
ffffffffc0200234:	64850513          	addi	a0,a0,1608 # ffffffffc0201878 <etext+0x14a>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	68650513          	addi	a0,a0,1670 # ffffffffc02018f0 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00001517          	auipc	a0,0x1
ffffffffc0200290:	68c50513          	addi	a0,a0,1676 # ffffffffc0201918 <etext+0x1ea>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00001c17          	auipc	s8,0x1
ffffffffc02002a6:	6e6c0c13          	addi	s8,s8,1766 # ffffffffc0201988 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00001917          	auipc	s2,0x1
ffffffffc02002ae:	69690913          	addi	s2,s2,1686 # ffffffffc0201940 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00001497          	auipc	s1,0x1
ffffffffc02002b6:	69648493          	addi	s1,s1,1686 # ffffffffc0201948 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00001b17          	auipc	s6,0x1
ffffffffc02002c0:	694b0b13          	addi	s6,s6,1684 # ffffffffc0201950 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002c4:	00001a17          	auipc	s4,0x1
ffffffffc02002c8:	5aca0a13          	addi	s4,s4,1452 # ffffffffc0201870 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	2f8010ef          	jal	ra,ffffffffc02015c8 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00001d17          	auipc	s10,0x1
ffffffffc02002ea:	6a2d0d13          	addi	s10,s10,1698 # ffffffffc0201988 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	3f4010ef          	jal	ra,ffffffffc02016e8 <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	3e0010ef          	jal	ra,ffffffffc02016e8 <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	3c0010ef          	jal	ra,ffffffffc0201706 <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	382010ef          	jal	ra,ffffffffc0201706 <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	5d250513          	addi	a0,a0,1490 # ffffffffc0201970 <etext+0x242>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	16c30313          	addi	t1,t1,364 # ffffffffc0206518 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00001517          	auipc	a0,0x1
ffffffffc02003de:	5f650513          	addi	a0,a0,1526 # ffffffffc02019d0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	42850513          	addi	a0,a0,1064 # ffffffffc0201818 <etext+0xea>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	276010ef          	jal	ra,ffffffffc0201696 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00001517          	auipc	a0,0x1
ffffffffc0200432:	5c250513          	addi	a0,a0,1474 # ffffffffc02019f0 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	2500106f          	j	ffffffffc0201696 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	zext.b	a0,a0
ffffffffc0200450:	22c0106f          	j	ffffffffc020167c <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	25c0106f          	j	ffffffffc02016b0 <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	2e478793          	addi	a5,a5,740 # ffffffffc020074c <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00001517          	auipc	a0,0x1
ffffffffc0200482:	59250513          	addi	a0,a0,1426 # ffffffffc0201a10 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00001517          	auipc	a0,0x1
ffffffffc0200492:	59a50513          	addi	a0,a0,1434 # ffffffffc0201a28 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00001517          	auipc	a0,0x1
ffffffffc02004a0:	5a450513          	addi	a0,a0,1444 # ffffffffc0201a40 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00001517          	auipc	a0,0x1
ffffffffc02004ae:	5ae50513          	addi	a0,a0,1454 # ffffffffc0201a58 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00001517          	auipc	a0,0x1
ffffffffc02004bc:	5b850513          	addi	a0,a0,1464 # ffffffffc0201a70 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00001517          	auipc	a0,0x1
ffffffffc02004ca:	5c250513          	addi	a0,a0,1474 # ffffffffc0201a88 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00001517          	auipc	a0,0x1
ffffffffc02004d8:	5cc50513          	addi	a0,a0,1484 # ffffffffc0201aa0 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00001517          	auipc	a0,0x1
ffffffffc02004e6:	5d650513          	addi	a0,a0,1494 # ffffffffc0201ab8 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00001517          	auipc	a0,0x1
ffffffffc02004f4:	5e050513          	addi	a0,a0,1504 # ffffffffc0201ad0 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00001517          	auipc	a0,0x1
ffffffffc0200502:	5ea50513          	addi	a0,a0,1514 # ffffffffc0201ae8 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00001517          	auipc	a0,0x1
ffffffffc0200510:	5f450513          	addi	a0,a0,1524 # ffffffffc0201b00 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	5fe50513          	addi	a0,a0,1534 # ffffffffc0201b18 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	60850513          	addi	a0,a0,1544 # ffffffffc0201b30 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00001517          	auipc	a0,0x1
ffffffffc020053a:	61250513          	addi	a0,a0,1554 # ffffffffc0201b48 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00001517          	auipc	a0,0x1
ffffffffc0200548:	61c50513          	addi	a0,a0,1564 # ffffffffc0201b60 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00001517          	auipc	a0,0x1
ffffffffc0200556:	62650513          	addi	a0,a0,1574 # ffffffffc0201b78 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00001517          	auipc	a0,0x1
ffffffffc0200564:	63050513          	addi	a0,a0,1584 # ffffffffc0201b90 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00001517          	auipc	a0,0x1
ffffffffc0200572:	63a50513          	addi	a0,a0,1594 # ffffffffc0201ba8 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00001517          	auipc	a0,0x1
ffffffffc0200580:	64450513          	addi	a0,a0,1604 # ffffffffc0201bc0 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00001517          	auipc	a0,0x1
ffffffffc020058e:	64e50513          	addi	a0,a0,1614 # ffffffffc0201bd8 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	65850513          	addi	a0,a0,1624 # ffffffffc0201bf0 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00001517          	auipc	a0,0x1
ffffffffc02005aa:	66250513          	addi	a0,a0,1634 # ffffffffc0201c08 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	66c50513          	addi	a0,a0,1644 # ffffffffc0201c20 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	67650513          	addi	a0,a0,1654 # ffffffffc0201c38 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00001517          	auipc	a0,0x1
ffffffffc02005d4:	68050513          	addi	a0,a0,1664 # ffffffffc0201c50 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	68a50513          	addi	a0,a0,1674 # ffffffffc0201c68 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	69450513          	addi	a0,a0,1684 # ffffffffc0201c80 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00001517          	auipc	a0,0x1
ffffffffc02005fe:	69e50513          	addi	a0,a0,1694 # ffffffffc0201c98 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	6a850513          	addi	a0,a0,1704 # ffffffffc0201cb0 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00001517          	auipc	a0,0x1
ffffffffc020061a:	6b250513          	addi	a0,a0,1714 # ffffffffc0201cc8 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	6bc50513          	addi	a0,a0,1724 # ffffffffc0201ce0 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00001517          	auipc	a0,0x1
ffffffffc020063a:	6c250513          	addi	a0,a0,1730 # ffffffffc0201cf8 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00001517          	auipc	a0,0x1
ffffffffc020064e:	6c650513          	addi	a0,a0,1734 # ffffffffc0201d10 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00001517          	auipc	a0,0x1
ffffffffc0200666:	6c650513          	addi	a0,a0,1734 # ffffffffc0201d28 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00001517          	auipc	a0,0x1
ffffffffc0200676:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201d40 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00001517          	auipc	a0,0x1
ffffffffc0200686:	6d650513          	addi	a0,a0,1750 # ffffffffc0201d58 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00001517          	auipc	a0,0x1
ffffffffc020069a:	6da50513          	addi	a0,a0,1754 # ffffffffc0201d70 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00001717          	auipc	a4,0x1
ffffffffc02006b4:	7a070713          	addi	a4,a4,1952 # ffffffffc0201e50 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00001517          	auipc	a0,0x1
ffffffffc02006c6:	72650513          	addi	a0,a0,1830 # ffffffffc0201de8 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	6fc50513          	addi	a0,a0,1788 # ffffffffc0201dc8 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00001517          	auipc	a0,0x1
ffffffffc02006da:	6b250513          	addi	a0,a0,1714 # ffffffffc0201d88 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00001517          	auipc	a0,0x1
ffffffffc02006e4:	72850513          	addi	a0,a0,1832 # ffffffffc0201e08 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	e2e68693          	addi	a3,a3,-466 # ffffffffc0206520 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00001517          	auipc	a0,0x1
ffffffffc0200714:	72050513          	addi	a0,a0,1824 # ffffffffc0201e30 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	68e50513          	addi	a0,a0,1678 # ffffffffc0201da8 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	6f450513          	addi	a0,a0,1780 # ffffffffc0201e20 <commands+0x498>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
ffffffffc020073c:	0007c763          	bltz	a5,ffffffffc020074a <trap+0x12>
    switch (tf->cause) {
ffffffffc0200740:	472d                	li	a4,11
ffffffffc0200742:	00f76363          	bltu	a4,a5,ffffffffc0200748 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200746:	8082                	ret
            print_trapframe(tf);
ffffffffc0200748:	bded                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc020074a:	bfa1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f89ff0ef          	jal	ra,ffffffffc0200738 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <buddy_init>:

#define MAX_ORDER 11 // Buddy system 的最大阶数
static free_area_t free_area[MAX_ORDER]; // 每个阶数一个空闲列表

static void buddy_init(void) {
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200802:	00006797          	auipc	a5,0x6
ffffffffc0200806:	80e78793          	addi	a5,a5,-2034 # ffffffffc0206010 <free_area>
ffffffffc020080a:	00006717          	auipc	a4,0x6
ffffffffc020080e:	90e70713          	addi	a4,a4,-1778 # ffffffffc0206118 <buf>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200812:	e79c                	sd	a5,8(a5)
ffffffffc0200814:	e39c                	sd	a5,0(a5)
        list_init(&free_area[i].free_list);
        free_area[i].nr_free = 0;
ffffffffc0200816:	0007a823          	sw	zero,16(a5)
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc020081a:	07e1                	addi	a5,a5,24
ffffffffc020081c:	fee79be3          	bne	a5,a4,ffffffffc0200812 <buddy_init+0x10>
    }
}
ffffffffc0200820:	8082                	ret

ffffffffc0200822 <cut_page>:
        }
        p += order_size;
    }
}

static void cut_page(size_t n) {
ffffffffc0200822:	7179                	addi	sp,sp,-48
ffffffffc0200824:	e84a                	sd	s2,16(sp)
    if (free_area[n].nr_free == 0) {
ffffffffc0200826:	00151913          	slli	s2,a0,0x1
static void cut_page(size_t n) {
ffffffffc020082a:	e44e                	sd	s3,8(sp)
    if (free_area[n].nr_free == 0) {
ffffffffc020082c:	00a909b3          	add	s3,s2,a0
static void cut_page(size_t n) {
ffffffffc0200830:	ec26                	sd	s1,24(sp)
    if (free_area[n].nr_free == 0) {
ffffffffc0200832:	098e                	slli	s3,s3,0x3
ffffffffc0200834:	00005497          	auipc	s1,0x5
ffffffffc0200838:	7dc48493          	addi	s1,s1,2012 # ffffffffc0206010 <free_area>
ffffffffc020083c:	99a6                	add	s3,s3,s1
ffffffffc020083e:	0109a603          	lw	a2,16(s3)
static void cut_page(size_t n) {
ffffffffc0200842:	f022                	sd	s0,32(sp)
ffffffffc0200844:	f406                	sd	ra,40(sp)
ffffffffc0200846:	842a                	mv	s0,a0
    if (free_area[n].nr_free == 0) {
ffffffffc0200848:	ca2d                	beqz	a2,ffffffffc02008ba <cut_page+0x98>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020084a:	9922                	add	s2,s2,s0
ffffffffc020084c:	090e                	slli	s2,s2,0x3
ffffffffc020084e:	9926                	add	s2,s2,s1
ffffffffc0200850:	00893703          	ld	a4,8(s2)
    list_entry_t* le = list_next(&(free_area[n].free_list));
    struct Page *page = le2page(le, page_link);
    list_del(&(page->page_link));
    free_area[n].nr_free--;

    size_t i = n - 1;
ffffffffc0200854:	147d                	addi	s0,s0,-1
    struct Page *buddy_page = page + (1 << i);
ffffffffc0200856:	4685                	li	a3,1
ffffffffc0200858:	0086983b          	sllw	a6,a3,s0
    __list_del(listelm->prev, listelm->next);
ffffffffc020085c:	6308                	ld	a0,0(a4)
ffffffffc020085e:	670c                	ld	a1,8(a4)
ffffffffc0200860:	00281793          	slli	a5,a6,0x2
ffffffffc0200864:	97c2                	add	a5,a5,a6
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200866:	e50c                	sd	a1,8(a0)
ffffffffc0200868:	078e                	slli	a5,a5,0x3
    next->prev = prev;
ffffffffc020086a:	e188                	sd	a0,0(a1)
    free_area[n].nr_free--;
ffffffffc020086c:	367d                	addiw	a2,a2,-1
    struct Page *buddy_page = page + (1 << i);
ffffffffc020086e:	17a1                	addi	a5,a5,-24
    free_area[n].nr_free--;
ffffffffc0200870:	00c92823          	sw	a2,16(s2)
    struct Page *buddy_page = page + (1 << i);
ffffffffc0200874:	97ba                	add	a5,a5,a4
    buddy_page->property = (1 << i);
ffffffffc0200876:	0107a823          	sw	a6,16(a5)
    page->property = (1 << i);
ffffffffc020087a:	ff072c23          	sw	a6,-8(a4)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020087e:	4689                	li	a3,2
ffffffffc0200880:	00878613          	addi	a2,a5,8
ffffffffc0200884:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200888:	00141513          	slli	a0,s0,0x1
ffffffffc020088c:	942a                	add	s0,s0,a0
ffffffffc020088e:	040e                	slli	s0,s0,0x3
ffffffffc0200890:	9426                	add	s0,s0,s1
ffffffffc0200892:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0200894:	e418                	sd	a4,8(s0)
    SetPageProperty(buddy_page);
    
    list_add(&(free_area[i].free_list), &(page->page_link));
    list_add(&(page->page_link), &(buddy_page->page_link));
    free_area[i].nr_free += 2;
ffffffffc0200896:	4814                	lw	a3,16(s0)
    elm->prev = prev;
ffffffffc0200898:	e300                	sd	s0,0(a4)
    list_add(&(page->page_link), &(buddy_page->page_link));
ffffffffc020089a:	01878593          	addi	a1,a5,24
    prev->next = next->prev = elm;
ffffffffc020089e:	e20c                	sd	a1,0(a2)
ffffffffc02008a0:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008a2:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc02008a4:	ef98                	sd	a4,24(a5)
    free_area[i].nr_free += 2;
ffffffffc02008a6:	0026879b          	addiw	a5,a3,2
}
ffffffffc02008aa:	70a2                	ld	ra,40(sp)
    free_area[i].nr_free += 2;
ffffffffc02008ac:	c81c                	sw	a5,16(s0)
}
ffffffffc02008ae:	7402                	ld	s0,32(sp)
ffffffffc02008b0:	64e2                	ld	s1,24(sp)
ffffffffc02008b2:	6942                	ld	s2,16(sp)
ffffffffc02008b4:	69a2                	ld	s3,8(sp)
ffffffffc02008b6:	6145                	addi	sp,sp,48
ffffffffc02008b8:	8082                	ret
        cut_page(n + 1);
ffffffffc02008ba:	0505                	addi	a0,a0,1
ffffffffc02008bc:	f67ff0ef          	jal	ra,ffffffffc0200822 <cut_page>
    free_area[n].nr_free--;
ffffffffc02008c0:	0109a603          	lw	a2,16(s3)
ffffffffc02008c4:	b759                	j	ffffffffc020084a <cut_page+0x28>

ffffffffc02008c6 <buddy_free_pages>:
    merge_page(order + 1, base);
}

static void buddy_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p!= base + n; p++) {
ffffffffc02008c6:	00259713          	slli	a4,a1,0x2
ffffffffc02008ca:	972e                	add	a4,a4,a1
ffffffffc02008cc:	070e                	slli	a4,a4,0x3
ffffffffc02008ce:	972a                	add	a4,a4,a0
ffffffffc02008d0:	87aa                	mv	a5,a0
ffffffffc02008d2:	00e50a63          	beq	a0,a4,ffffffffc02008e6 <buddy_free_pages+0x20>
        // assert(!PageReserved(p) &&!PageProperty(p));
        p->flags = 0;
ffffffffc02008d6:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008da:	0007a023          	sw	zero,0(a5)
    for (; p!= base + n; p++) {
ffffffffc02008de:	02878793          	addi	a5,a5,40
ffffffffc02008e2:	fee79ae3          	bne	a5,a4,ffffffffc02008d6 <buddy_free_pages+0x10>
        set_page_ref(p, 0);
    }
    base->property = n;
ffffffffc02008e6:	c90c                	sw	a1,16(a0)
ffffffffc02008e8:	4789                	li	a5,2
ffffffffc02008ea:	00850713          	addi	a4,a0,8
ffffffffc02008ee:	40f7302f          	amoor.d	zero,a5,(a4)
    SetPageProperty(base);

    size_t order = 0;
    while (n > 1) {
ffffffffc02008f2:	4705                	li	a4,1
    size_t order = 0;
ffffffffc02008f4:	4781                	li	a5,0
    while (n > 1) {
ffffffffc02008f6:	4685                	li	a3,1
ffffffffc02008f8:	2cb77863          	bgeu	a4,a1,ffffffffc0200bc8 <buddy_free_pages+0x302>
        n >>= 1;
ffffffffc02008fc:	8185                	srli	a1,a1,0x1
        order++;
ffffffffc02008fe:	873e                	mv	a4,a5
ffffffffc0200900:	0785                	addi	a5,a5,1
    while (n > 1) {
ffffffffc0200902:	fed59de3          	bne	a1,a3,ffffffffc02008fc <buddy_free_pages+0x36>
        
    }
    order++;
ffffffffc0200906:	00270693          	addi	a3,a4,2
ffffffffc020090a:	00169e93          	slli	t4,a3,0x1
ffffffffc020090e:	00de85b3          	add	a1,t4,a3
                free_area[order].nr_free++;
            }
        }
    }

    merge_page(order, base);
ffffffffc0200912:	0006861b          	sext.w	a2,a3
ffffffffc0200916:	058e                	slli	a1,a1,0x3
    if (free_area[order].nr_free == 0) {
ffffffffc0200918:	00de88b3          	add	a7,t4,a3
ffffffffc020091c:	00005817          	auipc	a6,0x5
ffffffffc0200920:	6f480813          	addi	a6,a6,1780 # ffffffffc0206010 <free_area>
ffffffffc0200924:	088e                	slli	a7,a7,0x3
ffffffffc0200926:	98c2                	add	a7,a7,a6
ffffffffc0200928:	0108a303          	lw	t1,16(a7)
    __list_add(elm, listelm, listelm->next);
ffffffffc020092c:	0088b783          	ld	a5,8(a7)
        list_add(&(free_area[order].free_list), &(base->page_link));
ffffffffc0200930:	95c2                	add	a1,a1,a6
    if (free_area[order].nr_free == 0) {
ffffffffc0200932:	12031963          	bnez	t1,ffffffffc0200a64 <buddy_free_pages+0x19e>
        list_add(&(free_area[order].free_list), &(base->page_link));
ffffffffc0200936:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020093a:	e398                	sd	a4,0(a5)
ffffffffc020093c:	00e8b423          	sd	a4,8(a7)
    elm->next = next;
ffffffffc0200940:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200942:	ed0c                	sd	a1,24(a0)
        free_area[order].nr_free++;
ffffffffc0200944:	4785                	li	a5,1
ffffffffc0200946:	00f8a823          	sw	a5,16(a7)
    if (order == MAX_ORDER) {
ffffffffc020094a:	47ad                	li	a5,11
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020094c:	5375                	li	t1,-3
                free_area[order + 1].nr_free++;
ffffffffc020094e:	4e05                	li	t3,1
    if (order == MAX_ORDER) {
ffffffffc0200950:	48ad                	li	a7,11
ffffffffc0200952:	16f60263          	beq	a2,a5,ffffffffc0200ab6 <buddy_free_pages+0x1f0>
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200956:	1141                	addi	sp,sp,-16
ffffffffc0200958:	e422                	sd	s0,8(sp)
ffffffffc020095a:	e026                	sd	s1,0(sp)
    if (le!= &(free_area[order].free_list)) {
ffffffffc020095c:	02061713          	slli	a4,a2,0x20
ffffffffc0200960:	9301                	srli	a4,a4,0x20
ffffffffc0200962:	00171793          	slli	a5,a4,0x1
ffffffffc0200966:	97ba                	add	a5,a5,a4
    return listelm->prev;
ffffffffc0200968:	6d18                	ld	a4,24(a0)
ffffffffc020096a:	078e                	slli	a5,a5,0x3
            if (free_area[order + 1].nr_free == 0) {
ffffffffc020096c:	00160e9b          	addiw	t4,a2,1
    if (le!= &(free_area[order].free_list)) {
ffffffffc0200970:	97c2                	add	a5,a5,a6
            if (free_area[order + 1].nr_free == 0) {
ffffffffc0200972:	000e861b          	sext.w	a2,t4
    if (le!= &(free_area[order].free_list)) {
ffffffffc0200976:	02f70063          	beq	a4,a5,ffffffffc0200996 <buddy_free_pages+0xd0>
        if (prev_page + prev_page->property == base) {
ffffffffc020097a:	ff872f83          	lw	t6,-8(a4)
        struct Page *prev_page = le2page(le, page_link);
ffffffffc020097e:	fe870f13          	addi	t5,a4,-24
        if (prev_page + prev_page->property == base) {
ffffffffc0200982:	020f9593          	slli	a1,t6,0x20
ffffffffc0200986:	9181                	srli	a1,a1,0x20
ffffffffc0200988:	00259693          	slli	a3,a1,0x2
ffffffffc020098c:	96ae                	add	a3,a3,a1
ffffffffc020098e:	068e                	slli	a3,a3,0x3
ffffffffc0200990:	96fa                	add	a3,a3,t5
ffffffffc0200992:	08d50363          	beq	a0,a3,ffffffffc0200a18 <buddy_free_pages+0x152>
    return listelm->next;
ffffffffc0200996:	7114                	ld	a3,32(a0)
    if (le!= &(free_area[order].free_list)) {
ffffffffc0200998:	02d78063          	beq	a5,a3,ffffffffc02009b8 <buddy_free_pages+0xf2>
        if (base + base->property == next_page) {
ffffffffc020099c:	01052f03          	lw	t5,16(a0)
        struct Page *next_page = le2page(le, page_link);
ffffffffc02009a0:	fe868713          	addi	a4,a3,-24
        if (base + base->property == next_page) {
ffffffffc02009a4:	020f1593          	slli	a1,t5,0x20
ffffffffc02009a8:	9181                	srli	a1,a1,0x20
ffffffffc02009aa:	00259793          	slli	a5,a1,0x2
ffffffffc02009ae:	97ae                	add	a5,a5,a1
ffffffffc02009b0:	078e                	slli	a5,a5,0x3
ffffffffc02009b2:	97aa                	add	a5,a5,a0
ffffffffc02009b4:	00f70863          	beq	a4,a5,ffffffffc02009c4 <buddy_free_pages+0xfe>
    if (order == MAX_ORDER) {
ffffffffc02009b8:	fb1612e3          	bne	a2,a7,ffffffffc020095c <buddy_free_pages+0x96>
}
ffffffffc02009bc:	6422                	ld	s0,8(sp)
ffffffffc02009be:	6482                	ld	s1,0(sp)
ffffffffc02009c0:	0141                	addi	sp,sp,16
ffffffffc02009c2:	8082                	ret
            base->property += next_page->property;
ffffffffc02009c4:	ff86a783          	lw	a5,-8(a3)
ffffffffc02009c8:	01e78f3b          	addw	t5,a5,t5
ffffffffc02009cc:	01e52823          	sw	t5,16(a0)
ffffffffc02009d0:	ff068793          	addi	a5,a3,-16
ffffffffc02009d4:	6067b02f          	amoand.d	zero,t1,(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02009d8:	6698                	ld	a4,8(a3)
ffffffffc02009da:	628c                	ld	a1,0(a3)
            if (free_area[order + 1].nr_free == 0) {
ffffffffc02009dc:	020e9f93          	slli	t6,t4,0x20
ffffffffc02009e0:	020fdf93          	srli	t6,t6,0x20
    prev->next = next;
ffffffffc02009e4:	e598                	sd	a4,8(a1)
ffffffffc02009e6:	001f9793          	slli	a5,t6,0x1
    next->prev = prev;
ffffffffc02009ea:	e30c                	sd	a1,0(a4)
ffffffffc02009ec:	97fe                	add	a5,a5,t6
    __list_del(listelm->prev, listelm->next);
ffffffffc02009ee:	7118                	ld	a4,32(a0)
ffffffffc02009f0:	6d14                	ld	a3,24(a0)
ffffffffc02009f2:	078e                	slli	a5,a5,0x3
ffffffffc02009f4:	97c2                	add	a5,a5,a6
ffffffffc02009f6:	4b8c                	lw	a1,16(a5)
    prev->next = next;
ffffffffc02009f8:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02009fa:	e314                	sd	a3,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02009fc:	6798                	ld	a4,8(a5)
ffffffffc02009fe:	14059663          	bnez	a1,ffffffffc0200b4a <buddy_free_pages+0x284>
                list_add(&(free_area[order + 1].free_list), &(base->page_link));
ffffffffc0200a02:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0200a06:	e314                	sd	a3,0(a4)
ffffffffc0200a08:	e794                	sd	a3,8(a5)
    elm->next = next;
ffffffffc0200a0a:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200a0c:	ed1c                	sd	a5,24(a0)
                free_area[order + 1].nr_free++;
ffffffffc0200a0e:	01c7a823          	sw	t3,16(a5)
    if (order == MAX_ORDER) {
ffffffffc0200a12:	f51615e3          	bne	a2,a7,ffffffffc020095c <buddy_free_pages+0x96>
ffffffffc0200a16:	b75d                	j	ffffffffc02009bc <buddy_free_pages+0xf6>
            prev_page->property += base->property;
ffffffffc0200a18:	4914                	lw	a3,16(a0)
ffffffffc0200a1a:	01f68fbb          	addw	t6,a3,t6
ffffffffc0200a1e:	fff72c23          	sw	t6,-8(a4)
ffffffffc0200a22:	00850693          	addi	a3,a0,8
ffffffffc0200a26:	6066b02f          	amoand.d	zero,t1,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a2a:	7114                	ld	a3,32(a0)
            if (free_area[order + 1].nr_free == 0) {
ffffffffc0200a2c:	020e9f93          	slli	t6,t4,0x20
ffffffffc0200a30:	020fdf93          	srli	t6,t6,0x20
    prev->next = next;
ffffffffc0200a34:	e714                	sd	a3,8(a4)
ffffffffc0200a36:	001f9593          	slli	a1,t6,0x1
    next->prev = prev;
ffffffffc0200a3a:	e298                	sd	a4,0(a3)
ffffffffc0200a3c:	95fe                	add	a1,a1,t6
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a3e:	6308                	ld	a0,0(a4)
ffffffffc0200a40:	6714                	ld	a3,8(a4)
ffffffffc0200a42:	058e                	slli	a1,a1,0x3
ffffffffc0200a44:	95c2                	add	a1,a1,a6
ffffffffc0200a46:	0105a283          	lw	t0,16(a1)
    prev->next = next;
ffffffffc0200a4a:	e514                	sd	a3,8(a0)
    next->prev = prev;
ffffffffc0200a4c:	e288                	sd	a0,0(a3)
ffffffffc0200a4e:	08029463          	bnez	t0,ffffffffc0200ad6 <buddy_free_pages+0x210>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a52:	6594                	ld	a3,8(a1)
        struct Page *prev_page = le2page(le, page_link);
ffffffffc0200a54:	857a                	mv	a0,t5
    prev->next = next->prev = elm;
ffffffffc0200a56:	e298                	sd	a4,0(a3)
ffffffffc0200a58:	e598                	sd	a4,8(a1)
    elm->next = next;
ffffffffc0200a5a:	e714                	sd	a3,8(a4)
    elm->prev = prev;
ffffffffc0200a5c:	e30c                	sd	a1,0(a4)
                free_area[order + 1].nr_free++;
ffffffffc0200a5e:	01c5a823          	sw	t3,16(a1)
ffffffffc0200a62:	bf1d                	j	ffffffffc0200998 <buddy_free_pages+0xd2>
        while ((le = list_next(le))!= &(free_area[order].free_list)) {
ffffffffc0200a64:	eeb783e3          	beq	a5,a1,ffffffffc020094a <buddy_free_pages+0x84>
ffffffffc0200a68:	2305                	addiw	t1,t1,1
            struct Page* page = le2page(le, page_link);
ffffffffc0200a6a:	fe878713          	addi	a4,a5,-24
        list_add(&(free_area[order].free_list), &(base->page_link));
ffffffffc0200a6e:	01850f13          	addi	t5,a0,24
                free_area[order].nr_free++;
ffffffffc0200a72:	00030e1b          	sext.w	t3,t1
            if (base < page) {
ffffffffc0200a76:	00e56c63          	bltu	a0,a4,ffffffffc0200a8e <buddy_free_pages+0x1c8>
    return listelm->next;
ffffffffc0200a7a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &(free_area[order].free_list)) {
ffffffffc0200a7c:	02b70e63          	beq	a4,a1,ffffffffc0200ab8 <buddy_free_pages+0x1f2>
    while (n > 1) {
ffffffffc0200a80:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200a82:	fe878713          	addi	a4,a5,-24
                free_area[order].nr_free++;
ffffffffc0200a86:	00030e1b          	sext.w	t3,t1
            if (base < page) {
ffffffffc0200a8a:	fee578e3          	bgeu	a0,a4,ffffffffc0200a7a <buddy_free_pages+0x1b4>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200a8e:	638c                	ld	a1,0(a5)
                free_area[order].nr_free++;
ffffffffc0200a90:	00de8733          	add	a4,t4,a3
    prev->next = next->prev = elm;
ffffffffc0200a94:	01e7b023          	sd	t5,0(a5)
ffffffffc0200a98:	01e5b423          	sd	t5,8(a1)
ffffffffc0200a9c:	070e                	slli	a4,a4,0x3
    elm->next = next;
ffffffffc0200a9e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200aa0:	ed0c                	sd	a1,24(a0)
ffffffffc0200aa2:	00e807b3          	add	a5,a6,a4
ffffffffc0200aa6:	01c7a823          	sw	t3,16(a5)
    if (order == MAX_ORDER) {
ffffffffc0200aaa:	47ad                	li	a5,11
ffffffffc0200aac:	5375                	li	t1,-3
                free_area[order + 1].nr_free++;
ffffffffc0200aae:	4e05                	li	t3,1
    if (order == MAX_ORDER) {
ffffffffc0200ab0:	48ad                	li	a7,11
ffffffffc0200ab2:	eaf612e3          	bne	a2,a5,ffffffffc0200956 <buddy_free_pages+0x90>
ffffffffc0200ab6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200ab8:	01e5b023          	sd	t5,0(a1)
ffffffffc0200abc:	01e7b423          	sd	t5,8(a5)
    elm->next = next;
ffffffffc0200ac0:	f10c                	sd	a1,32(a0)
    return listelm->next;
ffffffffc0200ac2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200ac4:	ed1c                	sd	a5,24(a0)
                free_area[order].nr_free++;
ffffffffc0200ac6:	0068a823          	sw	t1,16(a7)
        while ((le = list_next(le))!= &(free_area[order].free_list)) {
ffffffffc0200aca:	e8b700e3          	beq	a4,a1,ffffffffc020094a <buddy_free_pages+0x84>
ffffffffc0200ace:	001e031b          	addiw	t1,t3,1
    while (n > 1) {
ffffffffc0200ad2:	87ba                	mv	a5,a4
ffffffffc0200ad4:	b77d                	j	ffffffffc0200a82 <buddy_free_pages+0x1bc>
    return listelm->next;
ffffffffc0200ad6:	6588                	ld	a0,8(a1)
ffffffffc0200ad8:	2285                	addiw	t0,t0,1
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
ffffffffc0200ada:	0ea58b63          	beq	a1,a0,ffffffffc0200bd0 <buddy_free_pages+0x30a>
                        free_area[order + 1].nr_free++;
ffffffffc0200ade:	02061693          	slli	a3,a2,0x20
ffffffffc0200ae2:	9281                	srli	a3,a3,0x20
ffffffffc0200ae4:	00169413          	slli	s0,a3,0x1
ffffffffc0200ae8:	9436                	add	s0,s0,a3
ffffffffc0200aea:	040e                	slli	s0,s0,0x3
                    struct Page* page = le2page(le, page_link);
ffffffffc0200aec:	fe850693          	addi	a3,a0,-24
                        free_area[order + 1].nr_free++;
ffffffffc0200af0:	9442                	add	s0,s0,a6
                        free_area[order + 1].nr_free++;
ffffffffc0200af2:	0002839b          	sext.w	t2,t0
                    if (base < page) {
ffffffffc0200af6:	00df6c63          	bltu	t5,a3,ffffffffc0200b0e <buddy_free_pages+0x248>
ffffffffc0200afa:	6514                	ld	a3,8(a0)
                    } else if (list_next(le) == &(free_area[order + 1].free_list)) {
ffffffffc0200afc:	02b68963          	beq	a3,a1,ffffffffc0200b2e <buddy_free_pages+0x268>
                free_area[order].nr_free++;
ffffffffc0200b00:	8536                	mv	a0,a3
                    struct Page* page = le2page(le, page_link);
ffffffffc0200b02:	fe850693          	addi	a3,a0,-24
                        free_area[order + 1].nr_free++;
ffffffffc0200b06:	0002839b          	sext.w	t2,t0
                    if (base < page) {
ffffffffc0200b0a:	fedf78e3          	bgeu	t5,a3,ffffffffc0200afa <buddy_free_pages+0x234>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200b0e:	610c                	ld	a1,0(a0)
                        free_area[order + 1].nr_free++;
ffffffffc0200b10:	001f9693          	slli	a3,t6,0x1
    prev->next = next->prev = elm;
ffffffffc0200b14:	e118                	sd	a4,0(a0)
ffffffffc0200b16:	9fb6                	add	t6,t6,a3
ffffffffc0200b18:	e598                	sd	a4,8(a1)
ffffffffc0200b1a:	0f8e                	slli	t6,t6,0x3
    elm->next = next;
ffffffffc0200b1c:	e708                	sd	a0,8(a4)
    elm->prev = prev;
ffffffffc0200b1e:	e30c                	sd	a1,0(a4)
ffffffffc0200b20:	01f80733          	add	a4,a6,t6
                        break;
ffffffffc0200b24:	86aa                	mv	a3,a0
                        free_area[order + 1].nr_free++;
ffffffffc0200b26:	00772823          	sw	t2,16(a4)
                        break;
ffffffffc0200b2a:	857a                	mv	a0,t5
ffffffffc0200b2c:	b5b5                	j	ffffffffc0200998 <buddy_free_pages+0xd2>
    prev->next = next->prev = elm;
ffffffffc0200b2e:	e198                	sd	a4,0(a1)
ffffffffc0200b30:	e518                	sd	a4,8(a0)
    elm->next = next;
ffffffffc0200b32:	e70c                	sd	a1,8(a4)
    return listelm->next;
ffffffffc0200b34:	6504                	ld	s1,8(a0)
    elm->prev = prev;
ffffffffc0200b36:	e308                	sd	a0,0(a4)
                        free_area[order + 1].nr_free++;
ffffffffc0200b38:	00542823          	sw	t0,16(s0)
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
ffffffffc0200b3c:	08b48463          	beq	s1,a1,ffffffffc0200bc4 <buddy_free_pages+0x2fe>
ffffffffc0200b40:	86a6                	mv	a3,s1
ffffffffc0200b42:	0013829b          	addiw	t0,t2,1
                free_area[order].nr_free++;
ffffffffc0200b46:	8536                	mv	a0,a3
ffffffffc0200b48:	bf6d                	j	ffffffffc0200b02 <buddy_free_pages+0x23c>
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
ffffffffc0200b4a:	e6f707e3          	beq	a4,a5,ffffffffc02009b8 <buddy_free_pages+0xf2>
                        free_area[order + 1].nr_free++;
ffffffffc0200b4e:	02061693          	slli	a3,a2,0x20
ffffffffc0200b52:	9281                	srli	a3,a3,0x20
ffffffffc0200b54:	00169f13          	slli	t5,a3,0x1
ffffffffc0200b58:	9f36                	add	t5,t5,a3
ffffffffc0200b5a:	0f0e                	slli	t5,t5,0x3
ffffffffc0200b5c:	2585                	addiw	a1,a1,1
                    struct Page* page = le2page(le, page_link);
ffffffffc0200b5e:	fe870693          	addi	a3,a4,-24
                list_add(&(free_area[order + 1].free_list), &(base->page_link));
ffffffffc0200b62:	01850293          	addi	t0,a0,24
                        free_area[order + 1].nr_free++;
ffffffffc0200b66:	9f42                	add	t5,t5,a6
                        free_area[order + 1].nr_free++;
ffffffffc0200b68:	00058e9b          	sext.w	t4,a1
                    if (base < page) {
ffffffffc0200b6c:	00d56c63          	bltu	a0,a3,ffffffffc0200b84 <buddy_free_pages+0x2be>
    return listelm->next;
ffffffffc0200b70:	6714                	ld	a3,8(a4)
                    } else if (list_next(le) == &(free_area[order + 1].free_list)) {
ffffffffc0200b72:	02f68a63          	beq	a3,a5,ffffffffc0200ba6 <buddy_free_pages+0x2e0>
ffffffffc0200b76:	8736                	mv	a4,a3
                    struct Page* page = le2page(le, page_link);
ffffffffc0200b78:	fe870693          	addi	a3,a4,-24
                        free_area[order + 1].nr_free++;
ffffffffc0200b7c:	00058e9b          	sext.w	t4,a1
                    if (base < page) {
ffffffffc0200b80:	fed578e3          	bgeu	a0,a3,ffffffffc0200b70 <buddy_free_pages+0x2aa>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200b84:	6314                	ld	a3,0(a4)
                        free_area[order + 1].nr_free++;
ffffffffc0200b86:	001f9793          	slli	a5,t6,0x1
    prev->next = next->prev = elm;
ffffffffc0200b8a:	00573023          	sd	t0,0(a4)
ffffffffc0200b8e:	97fe                	add	a5,a5,t6
ffffffffc0200b90:	0056b423          	sd	t0,8(a3)
ffffffffc0200b94:	078e                	slli	a5,a5,0x3
    elm->next = next;
ffffffffc0200b96:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200b98:	ed14                	sd	a3,24(a0)
ffffffffc0200b9a:	97c2                	add	a5,a5,a6
ffffffffc0200b9c:	01d7a823          	sw	t4,16(a5)
    if (order == MAX_ORDER) {
ffffffffc0200ba0:	db161ee3          	bne	a2,a7,ffffffffc020095c <buddy_free_pages+0x96>
ffffffffc0200ba4:	bd21                	j	ffffffffc02009bc <buddy_free_pages+0xf6>
    prev->next = next->prev = elm;
ffffffffc0200ba6:	0057b023          	sd	t0,0(a5)
ffffffffc0200baa:	00573423          	sd	t0,8(a4)
    elm->next = next;
ffffffffc0200bae:	f11c                	sd	a5,32(a0)
    return listelm->next;
ffffffffc0200bb0:	6714                	ld	a3,8(a4)
    elm->prev = prev;
ffffffffc0200bb2:	ed18                	sd	a4,24(a0)
                        free_area[order + 1].nr_free++;
ffffffffc0200bb4:	00bf2823          	sw	a1,16(t5)
                while ((le = list_next(le))!= &(free_area[order + 1].free_list)) {
ffffffffc0200bb8:	e0f680e3          	beq	a3,a5,ffffffffc02009b8 <buddy_free_pages+0xf2>
ffffffffc0200bbc:	001e859b          	addiw	a1,t4,1
ffffffffc0200bc0:	8736                	mv	a4,a3
ffffffffc0200bc2:	bf5d                	j	ffffffffc0200b78 <buddy_free_pages+0x2b2>
ffffffffc0200bc4:	857a                	mv	a0,t5
ffffffffc0200bc6:	bbc9                	j	ffffffffc0200998 <buddy_free_pages+0xd2>
    while (n > 1) {
ffffffffc0200bc8:	45e1                	li	a1,24
ffffffffc0200bca:	4605                	li	a2,1
ffffffffc0200bcc:	4e89                	li	t4,2
ffffffffc0200bce:	b3a9                	j	ffffffffc0200918 <buddy_free_pages+0x52>
    return listelm->next;
ffffffffc0200bd0:	6714                	ld	a3,8(a4)
        struct Page *prev_page = le2page(le, page_link);
ffffffffc0200bd2:	857a                	mv	a0,t5
ffffffffc0200bd4:	b3d1                	j	ffffffffc0200998 <buddy_free_pages+0xd2>

ffffffffc0200bd6 <buddy_nr_free_pages>:

static size_t buddy_nr_free_pages(void) {
    size_t total = 0; // 使用 size_t 以处理较大的总和
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200bd6:	00005697          	auipc	a3,0x5
ffffffffc0200bda:	44a68693          	addi	a3,a3,1098 # ffffffffc0206020 <free_area+0x10>
ffffffffc0200bde:	4781                	li	a5,0
    size_t total = 0; // 使用 size_t 以处理较大的总和
ffffffffc0200be0:	4501                	li	a0,0
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200be2:	462d                	li	a2,11
        // 使用 size_t 进行位移操作，避免潜在的溢出
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200be4:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200be8:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200bea:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200bee:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200bf0:	953a                	add	a0,a0,a4
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200bf2:	fec799e3          	bne	a5,a2,ffffffffc0200be4 <buddy_nr_free_pages+0xe>
    }
    return total;
}
ffffffffc0200bf6:	8082                	ret

ffffffffc0200bf8 <buddy_alloc_pages.part.0>:
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200bf8:	1141                	addi	sp,sp,-16
ffffffffc0200bfa:	e406                	sd	ra,8(sp)
ffffffffc0200bfc:	e022                	sd	s0,0(sp)
    while ((1 << order) < n) {
ffffffffc0200bfe:	4785                	li	a5,1
ffffffffc0200c00:	06a7f063          	bgeu	a5,a0,ffffffffc0200c60 <buddy_alloc_pages.part.0+0x68>
    size_t order = 0;
ffffffffc0200c04:	4781                	li	a5,0
    while ((1 << order) < n) {
ffffffffc0200c06:	4685                	li	a3,1
        order++;
ffffffffc0200c08:	0785                	addi	a5,a5,1
    while ((1 << order) < n) {
ffffffffc0200c0a:	00f6973b          	sllw	a4,a3,a5
ffffffffc0200c0e:	fea76de3          	bltu	a4,a0,ffffffffc0200c08 <buddy_alloc_pages.part.0+0x10>
    if (free_area[order].nr_free > 0) {
ffffffffc0200c12:	00179413          	slli	s0,a5,0x1
ffffffffc0200c16:	943e                	add	s0,s0,a5
ffffffffc0200c18:	00341713          	slli	a4,s0,0x3
ffffffffc0200c1c:	00005417          	auipc	s0,0x5
ffffffffc0200c20:	3f440413          	addi	s0,s0,1012 # ffffffffc0206010 <free_area>
ffffffffc0200c24:	943a                	add	s0,s0,a4
ffffffffc0200c26:	4818                	lw	a4,16(s0)
ffffffffc0200c28:	c315                	beqz	a4,ffffffffc0200c4c <buddy_alloc_pages.part.0+0x54>
ffffffffc0200c2a:	641c                	ld	a5,8(s0)
        free_area[order].nr_free--;
ffffffffc0200c2c:	377d                	addiw	a4,a4,-1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c2e:	6390                	ld	a2,0(a5)
ffffffffc0200c30:	6794                	ld	a3,8(a5)
    prev->next = next;
ffffffffc0200c32:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200c34:	e290                	sd	a2,0(a3)
        struct Page *page = le2page(le, page_link);
ffffffffc0200c36:	fe878513          	addi	a0,a5,-24
        free_area[order].nr_free--;
ffffffffc0200c3a:	c818                	sw	a4,16(s0)
ffffffffc0200c3c:	17c1                	addi	a5,a5,-16
ffffffffc0200c3e:	5775                	li	a4,-3
ffffffffc0200c40:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0200c44:	60a2                	ld	ra,8(sp)
ffffffffc0200c46:	6402                	ld	s0,0(sp)
ffffffffc0200c48:	0141                	addi	sp,sp,16
ffffffffc0200c4a:	8082                	ret
        cut_page(order + 1);
ffffffffc0200c4c:	00178513          	addi	a0,a5,1
ffffffffc0200c50:	bd3ff0ef          	jal	ra,ffffffffc0200822 <cut_page>
    return listelm->next;
ffffffffc0200c54:	641c                	ld	a5,8(s0)
        free_area[order].nr_free--;
ffffffffc0200c56:	4818                	lw	a4,16(s0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c58:	6390                	ld	a2,0(a5)
ffffffffc0200c5a:	6794                	ld	a3,8(a5)
ffffffffc0200c5c:	377d                	addiw	a4,a4,-1
ffffffffc0200c5e:	bfd1                	j	ffffffffc0200c32 <buddy_alloc_pages.part.0+0x3a>
    size_t order = 0;
ffffffffc0200c60:	4781                	li	a5,0
ffffffffc0200c62:	bf45                	j	ffffffffc0200c12 <buddy_alloc_pages.part.0+0x1a>

ffffffffc0200c64 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc0200c64:	c111                	beqz	a0,ffffffffc0200c68 <buddy_alloc_pages+0x4>
ffffffffc0200c66:	bf49                	j	ffffffffc0200bf8 <buddy_alloc_pages.part.0>
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200c68:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	21668693          	addi	a3,a3,534 # ffffffffc0201e80 <commands+0x4f8>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	21660613          	addi	a2,a2,534 # ffffffffc0201e88 <commands+0x500>
ffffffffc0200c7a:	04500593          	li	a1,69
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	22250513          	addi	a0,a0,546 # ffffffffc0201ea0 <commands+0x518>
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200c86:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c88:	f24ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c8c <buddy_check>:


static void buddy_check(void) {
ffffffffc0200c8c:	7139                	addi	sp,sp,-64
ffffffffc0200c8e:	fc06                	sd	ra,56(sp)
ffffffffc0200c90:	f822                	sd	s0,48(sp)
ffffffffc0200c92:	f426                	sd	s1,40(sp)
ffffffffc0200c94:	f04a                	sd	s2,32(sp)
ffffffffc0200c96:	ec4e                	sd	s3,24(sp)
ffffffffc0200c98:	e852                	sd	s4,16(sp)
ffffffffc0200c9a:	e456                	sd	s5,8(sp)
ffffffffc0200c9c:	e05a                	sd	s6,0(sp)
ffffffffc0200c9e:	00005517          	auipc	a0,0x5
ffffffffc0200ca2:	47a50513          	addi	a0,a0,1146 # ffffffffc0206118 <buf>
ffffffffc0200ca6:	00005597          	auipc	a1,0x5
ffffffffc0200caa:	36a58593          	addi	a1,a1,874 # ffffffffc0206010 <free_area>
    int total_free_pages = 0;
ffffffffc0200cae:	4601                	li	a2,0
    return listelm->next;
ffffffffc0200cb0:	659c                	ld	a5,8(a1)

    // 检查每个阶数的空闲列表
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        int count = 0;
ffffffffc0200cb2:	4681                	li	a3,0
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200cb4:	00b78f63          	beq	a5,a1,ffffffffc0200cd2 <buddy_check+0x46>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200cb8:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc0200cbc:	8b09                	andi	a4,a4,2
ffffffffc0200cbe:	22070d63          	beqz	a4,ffffffffc0200ef8 <buddy_check+0x26c>
            count++;
            total_free_pages += p->property;
ffffffffc0200cc2:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200cc6:	679c                	ld	a5,8(a5)
            count++;
ffffffffc0200cc8:	2685                	addiw	a3,a3,1
            total_free_pages += p->property;
ffffffffc0200cca:	9e39                	addw	a2,a2,a4
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200ccc:	feb796e3          	bne	a5,a1,ffffffffc0200cb8 <buddy_check+0x2c>
        }
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc0200cd0:	2681                	sext.w	a3,a3
ffffffffc0200cd2:	499c                	lw	a5,16(a1)
ffffffffc0200cd4:	26d79263          	bne	a5,a3,ffffffffc0200f38 <buddy_check+0x2ac>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cd8:	05e1                	addi	a1,a1,24
ffffffffc0200cda:	fca59be3          	bne	a1,a0,ffffffffc0200cb0 <buddy_check+0x24>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cde:	00005497          	auipc	s1,0x5
ffffffffc0200ce2:	34248493          	addi	s1,s1,834 # ffffffffc0206020 <free_area+0x10>
    }

    // 检查总的空闲页面数是否一致
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200ce6:	86a6                	mv	a3,s1
    size_t total = 0; // 使用 size_t 以处理较大的总和
ffffffffc0200ce8:	4581                	li	a1,0
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cea:	4781                	li	a5,0
ffffffffc0200cec:	482d                	li	a6,11
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200cee:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cf2:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200cf4:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cf8:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200cfa:	95ba                	add	a1,a1,a4
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200cfc:	ff0799e3          	bne	a5,a6,ffffffffc0200cee <buddy_check+0x62>
    return total;
ffffffffc0200d00:	00005697          	auipc	a3,0x5
ffffffffc0200d04:	31068693          	addi	a3,a3,784 # ffffffffc0206010 <free_area>
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200d08:	24b61863          	bne	a2,a1,ffffffffc0200f58 <buddy_check+0x2cc>

    // 检查已分配页面的状态
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
ffffffffc0200d0c:	87b6                	mv	a5,a3
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200d0e:	a031                	j	ffffffffc0200d1a <buddy_check+0x8e>
ffffffffc0200d10:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc0200d14:	8b09                	andi	a4,a4,2
ffffffffc0200d16:	20070163          	beqz	a4,ffffffffc0200f18 <buddy_check+0x28c>
ffffffffc0200d1a:	679c                	ld	a5,8(a5)
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200d1c:	fed79ae3          	bne	a5,a3,ffffffffc0200d10 <buddy_check+0x84>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200d20:	01878693          	addi	a3,a5,24
ffffffffc0200d24:	fea694e3          	bne	a3,a0,ffffffffc0200d0c <buddy_check+0x80>
ffffffffc0200d28:	00005697          	auipc	a3,0x5
ffffffffc0200d2c:	2f868693          	addi	a3,a3,760 # ffffffffc0206020 <free_area+0x10>
    size_t total = 0; // 使用 size_t 以处理较大的总和
ffffffffc0200d30:	4581                	li	a1,0
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200d32:	4781                	li	a5,0
ffffffffc0200d34:	462d                	li	a2,11
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200d36:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200d3a:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200d3c:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200d40:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i;
ffffffffc0200d42:	95ba                	add	a1,a1,a4
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200d44:	fec799e3          	bne	a5,a2,ffffffffc0200d36 <buddy_check+0xaa>
        }
    }

    // 可以添加更多的检查逻辑，例如检查每个页面的引用计数
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages());
ffffffffc0200d48:	00001517          	auipc	a0,0x1
ffffffffc0200d4c:	1d050513          	addi	a0,a0,464 # ffffffffc0201f18 <commands+0x590>
ffffffffc0200d50:	b62ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200d54:	00005417          	auipc	s0,0x5
ffffffffc0200d58:	3d440413          	addi	s0,s0,980 # ffffffffc0206128 <buf+0x10>
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages());
ffffffffc0200d5c:	00005917          	auipc	s2,0x5
ffffffffc0200d60:	2c490913          	addi	s2,s2,708 # ffffffffc0206020 <free_area+0x10>
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200d64:	00001997          	auipc	s3,0x1
ffffffffc0200d68:	1d498993          	addi	s3,s3,468 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200d6c:	00096583          	lwu	a1,0(s2)
ffffffffc0200d70:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200d72:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200d74:	b3eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200d78:	fe891ae3          	bne	s2,s0,ffffffffc0200d6c <buddy_check+0xe0>
    }
    
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("\n首先 p0 请求 5 页\n");
ffffffffc0200d7c:	00001517          	auipc	a0,0x1
ffffffffc0200d80:	1c450513          	addi	a0,a0,452 # ffffffffc0201f40 <commands+0x5b8>
ffffffffc0200d84:	b2eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(n > 0);
ffffffffc0200d88:	4515                	li	a0,5
ffffffffc0200d8a:	e6fff0ef          	jal	ra,ffffffffc0200bf8 <buddy_alloc_pages.part.0>
ffffffffc0200d8e:	8b2a                	mv	s6,a0
    p0 = buddy_alloc_pages(5);
    
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200d90:	00005917          	auipc	s2,0x5
ffffffffc0200d94:	29090913          	addi	s2,s2,656 # ffffffffc0206020 <free_area+0x10>
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200d98:	00001997          	auipc	s3,0x1
ffffffffc0200d9c:	1a098993          	addi	s3,s3,416 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200da0:	00096583          	lwu	a1,0(s2)
ffffffffc0200da4:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200da6:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200da8:	b0aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200dac:	fe891ae3          	bne	s2,s0,ffffffffc0200da0 <buddy_check+0x114>
    }
    
    cprintf("\n然后 p1 请求 5 页\n");
ffffffffc0200db0:	00001517          	auipc	a0,0x1
ffffffffc0200db4:	1b050513          	addi	a0,a0,432 # ffffffffc0201f60 <commands+0x5d8>
ffffffffc0200db8:	afaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(n > 0);
ffffffffc0200dbc:	4515                	li	a0,5
ffffffffc0200dbe:	e3bff0ef          	jal	ra,ffffffffc0200bf8 <buddy_alloc_pages.part.0>
ffffffffc0200dc2:	8aaa                	mv	s5,a0
    p1 = buddy_alloc_pages(5);
    
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200dc4:	00005917          	auipc	s2,0x5
ffffffffc0200dc8:	25c90913          	addi	s2,s2,604 # ffffffffc0206020 <free_area+0x10>
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200dcc:	00001997          	auipc	s3,0x1
ffffffffc0200dd0:	16c98993          	addi	s3,s3,364 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200dd4:	00096583          	lwu	a1,0(s2)
ffffffffc0200dd8:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200dda:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200ddc:	ad6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200de0:	fe891ae3          	bne	s2,s0,ffffffffc0200dd4 <buddy_check+0x148>
    }
    
    cprintf("\n最后 p2 请求 1023页\n");
ffffffffc0200de4:	00001517          	auipc	a0,0x1
ffffffffc0200de8:	19c50513          	addi	a0,a0,412 # ffffffffc0201f80 <commands+0x5f8>
ffffffffc0200dec:	ac6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(n > 0);
ffffffffc0200df0:	3ff00513          	li	a0,1023
ffffffffc0200df4:	e05ff0ef          	jal	ra,ffffffffc0200bf8 <buddy_alloc_pages.part.0>
ffffffffc0200df8:	8a2a                	mv	s4,a0
    p2 = buddy_alloc_pages(1023);
    
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200dfa:	00005917          	auipc	s2,0x5
ffffffffc0200dfe:	22690913          	addi	s2,s2,550 # ffffffffc0206020 <free_area+0x10>
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200e02:	00001997          	auipc	s3,0x1
ffffffffc0200e06:	13698993          	addi	s3,s3,310 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200e0a:	00096583          	lwu	a1,0(s2)
ffffffffc0200e0e:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200e10:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200e12:	aa0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200e16:	fe891ae3          	bne	s2,s0,ffffffffc0200e0a <buddy_check+0x17e>
    }
    
    
    cprintf("\n p0 的虚拟地址 0x%016lx.\n", p0);
ffffffffc0200e1a:	85da                	mv	a1,s6
ffffffffc0200e1c:	00001517          	auipc	a0,0x1
ffffffffc0200e20:	18450513          	addi	a0,a0,388 # ffffffffc0201fa0 <commands+0x618>
ffffffffc0200e24:	a8eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p1 的虚拟地址 0x%016lx.\n", p1);
ffffffffc0200e28:	85d6                	mv	a1,s5
ffffffffc0200e2a:	00001517          	auipc	a0,0x1
ffffffffc0200e2e:	19650513          	addi	a0,a0,406 # ffffffffc0201fc0 <commands+0x638>
ffffffffc0200e32:	a80ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p2 的虚拟地址 0x%016lx.\n", p2);
ffffffffc0200e36:	85d2                	mv	a1,s4
ffffffffc0200e38:	00001517          	auipc	a0,0x1
ffffffffc0200e3c:	1a850513          	addi	a0,a0,424 # ffffffffc0201fe0 <commands+0x658>
ffffffffc0200e40:	a72ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    
    
    cprintf("\n 收回p0\n");
ffffffffc0200e44:	00001517          	auipc	a0,0x1
ffffffffc0200e48:	1bc50513          	addi	a0,a0,444 # ffffffffc0202000 <commands+0x678>
ffffffffc0200e4c:	a66ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    buddy_free_pages(p0,5);
ffffffffc0200e50:	4595                	li	a1,5
ffffffffc0200e52:	855a                	mv	a0,s6
ffffffffc0200e54:	a73ff0ef          	jal	ra,ffffffffc02008c6 <buddy_free_pages>
ffffffffc0200e58:	00005917          	auipc	s2,0x5
ffffffffc0200e5c:	1c890913          	addi	s2,s2,456 # ffffffffc0206020 <free_area+0x10>
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200e60:	00001997          	auipc	s3,0x1
ffffffffc0200e64:	0d898993          	addi	s3,s3,216 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200e68:	00096583          	lwu	a1,0(s2)
ffffffffc0200e6c:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200e6e:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200e70:	a42ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200e74:	fe891ae3          	bne	s2,s0,ffffffffc0200e68 <buddy_check+0x1dc>
    }
    
    cprintf("\n 收回p1\n");
ffffffffc0200e78:	00001517          	auipc	a0,0x1
ffffffffc0200e7c:	19850513          	addi	a0,a0,408 # ffffffffc0202010 <commands+0x688>
ffffffffc0200e80:	a32ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    buddy_free_pages(p1,5);
ffffffffc0200e84:	4595                	li	a1,5
ffffffffc0200e86:	8556                	mv	a0,s5
ffffffffc0200e88:	a3fff0ef          	jal	ra,ffffffffc02008c6 <buddy_free_pages>
ffffffffc0200e8c:	00005917          	auipc	s2,0x5
ffffffffc0200e90:	19490913          	addi	s2,s2,404 # ffffffffc0206020 <free_area+0x10>
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200e94:	00001997          	auipc	s3,0x1
ffffffffc0200e98:	0a498993          	addi	s3,s3,164 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200e9c:	00096583          	lwu	a1,0(s2)
ffffffffc0200ea0:	854e                	mv	a0,s3
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200ea2:	0961                	addi	s2,s2,24
    cprintf("%d ",total);
ffffffffc0200ea4:	a0eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200ea8:	fe891ae3          	bne	s2,s0,ffffffffc0200e9c <buddy_check+0x210>
    }
    
    cprintf("\n 收回p2\n");
ffffffffc0200eac:	00001517          	auipc	a0,0x1
ffffffffc0200eb0:	17450513          	addi	a0,a0,372 # ffffffffc0202020 <commands+0x698>
ffffffffc0200eb4:	9feff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    buddy_free_pages(p2,1023);
ffffffffc0200eb8:	3ff00593          	li	a1,1023
ffffffffc0200ebc:	8552                	mv	a0,s4
ffffffffc0200ebe:	a09ff0ef          	jal	ra,ffffffffc02008c6 <buddy_free_pages>
    for(int i=0;i<MAX_ORDER;i++){
    size_t total =free_area[i].nr_free;
    
    cprintf("%d ",total);
ffffffffc0200ec2:	00001917          	auipc	s2,0x1
ffffffffc0200ec6:	07690913          	addi	s2,s2,118 # ffffffffc0201f38 <commands+0x5b0>
ffffffffc0200eca:	0004e583          	lwu	a1,0(s1)
ffffffffc0200ece:	854a                	mv	a0,s2
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200ed0:	04e1                	addi	s1,s1,24
    cprintf("%d ",total);
ffffffffc0200ed2:	9e0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for(int i=0;i<MAX_ORDER;i++){
ffffffffc0200ed6:	fe849ae3          	bne	s1,s0,ffffffffc0200eca <buddy_check+0x23e>
    }
    
    cprintf("\n");
    
    
}
ffffffffc0200eda:	7442                	ld	s0,48(sp)
ffffffffc0200edc:	70e2                	ld	ra,56(sp)
ffffffffc0200ede:	74a2                	ld	s1,40(sp)
ffffffffc0200ee0:	7902                	ld	s2,32(sp)
ffffffffc0200ee2:	69e2                	ld	s3,24(sp)
ffffffffc0200ee4:	6a42                	ld	s4,16(sp)
ffffffffc0200ee6:	6aa2                	ld	s5,8(sp)
ffffffffc0200ee8:	6b02                	ld	s6,0(sp)
    cprintf("\n");
ffffffffc0200eea:	00001517          	auipc	a0,0x1
ffffffffc0200eee:	92e50513          	addi	a0,a0,-1746 # ffffffffc0201818 <etext+0xea>
}
ffffffffc0200ef2:	6121                	addi	sp,sp,64
    cprintf("\n");
ffffffffc0200ef4:	9beff06f          	j	ffffffffc02000b2 <cprintf>
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc0200ef8:	00001697          	auipc	a3,0x1
ffffffffc0200efc:	fc068693          	addi	a3,a3,-64 # ffffffffc0201eb8 <commands+0x530>
ffffffffc0200f00:	00001617          	auipc	a2,0x1
ffffffffc0200f04:	f8860613          	addi	a2,a2,-120 # ffffffffc0201e88 <commands+0x500>
ffffffffc0200f08:	0e100593          	li	a1,225
ffffffffc0200f0c:	00001517          	auipc	a0,0x1
ffffffffc0200f10:	f9450513          	addi	a0,a0,-108 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0200f14:	c98ff0ef          	jal	ra,ffffffffc02003ac <__panic>
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc0200f18:	00001697          	auipc	a3,0x1
ffffffffc0200f1c:	fa068693          	addi	a3,a3,-96 # ffffffffc0201eb8 <commands+0x530>
ffffffffc0200f20:	00001617          	auipc	a2,0x1
ffffffffc0200f24:	f6860613          	addi	a2,a2,-152 # ffffffffc0201e88 <commands+0x500>
ffffffffc0200f28:	0f000593          	li	a1,240
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	f7450513          	addi	a0,a0,-140 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0200f34:	c78ff0ef          	jal	ra,ffffffffc02003ac <__panic>
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc0200f38:	00001697          	auipc	a3,0x1
ffffffffc0200f3c:	f9068693          	addi	a3,a3,-112 # ffffffffc0201ec8 <commands+0x540>
ffffffffc0200f40:	00001617          	auipc	a2,0x1
ffffffffc0200f44:	f4860613          	addi	a2,a2,-184 # ffffffffc0201e88 <commands+0x500>
ffffffffc0200f48:	0e500593          	li	a1,229
ffffffffc0200f4c:	00001517          	auipc	a0,0x1
ffffffffc0200f50:	f5450513          	addi	a0,a0,-172 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0200f54:	c58ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200f58:	00001697          	auipc	a3,0x1
ffffffffc0200f5c:	f9068693          	addi	a3,a3,-112 # ffffffffc0201ee8 <commands+0x560>
ffffffffc0200f60:	00001617          	auipc	a2,0x1
ffffffffc0200f64:	f2860613          	addi	a2,a2,-216 # ffffffffc0201e88 <commands+0x500>
ffffffffc0200f68:	0e900593          	li	a1,233
ffffffffc0200f6c:	00001517          	auipc	a0,0x1
ffffffffc0200f70:	f3450513          	addi	a0,a0,-204 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0200f74:	c38ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200f78 <buddy_init_memmap>:
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f78:	1141                	addi	sp,sp,-16
ffffffffc0200f7a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f7c:	c5d5                	beqz	a1,ffffffffc0201028 <buddy_init_memmap+0xb0>
    for (; p!= base + n; p++) {
ffffffffc0200f7e:	00259693          	slli	a3,a1,0x2
ffffffffc0200f82:	96ae                	add	a3,a3,a1
ffffffffc0200f84:	068e                	slli	a3,a3,0x3
ffffffffc0200f86:	96aa                	add	a3,a3,a0
ffffffffc0200f88:	87aa                	mv	a5,a0
ffffffffc0200f8a:	00d50f63          	beq	a0,a3,ffffffffc0200fa8 <buddy_init_memmap+0x30>
ffffffffc0200f8e:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0200f90:	8b05                	andi	a4,a4,1
ffffffffc0200f92:	cf25                	beqz	a4,ffffffffc020100a <buddy_init_memmap+0x92>
        p->flags = p->property = 0;
ffffffffc0200f94:	0007a823          	sw	zero,16(a5)
ffffffffc0200f98:	0007b423          	sd	zero,8(a5)
ffffffffc0200f9c:	0007a023          	sw	zero,0(a5)
    for (; p!= base + n; p++) {
ffffffffc0200fa0:	02878793          	addi	a5,a5,40
ffffffffc0200fa4:	fed795e3          	bne	a5,a3,ffffffffc0200f8e <buddy_init_memmap+0x16>
    size_t order = MAX_ORDER-1;
ffffffffc0200fa8:	4729                	li	a4,10
    size_t order_size = 1 << order;
ffffffffc0200faa:	40000793          	li	a5,1024
ffffffffc0200fae:	00005e17          	auipc	t3,0x5
ffffffffc0200fb2:	062e0e13          	addi	t3,t3,98 # ffffffffc0206010 <free_area>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200fb6:	4309                	li	t1,2
        p->property = order_size;
ffffffffc0200fb8:	c91c                	sw	a5,16(a0)
ffffffffc0200fba:	00850693          	addi	a3,a0,8
ffffffffc0200fbe:	4066b02f          	amoor.d	zero,t1,(a3)
        free_area[order].nr_free += 1;
ffffffffc0200fc2:	00171693          	slli	a3,a4,0x1
ffffffffc0200fc6:	96ba                	add	a3,a3,a4
ffffffffc0200fc8:	068e                	slli	a3,a3,0x3
ffffffffc0200fca:	96f2                	add	a3,a3,t3
ffffffffc0200fcc:	0106a803          	lw	a6,16(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200fd0:	0086b883          	ld	a7,8(a3)
        list_add(&(free_area[order].free_list), &(p->page_link));
ffffffffc0200fd4:	01850613          	addi	a2,a0,24
        free_area[order].nr_free += 1;
ffffffffc0200fd8:	2805                	addiw	a6,a6,1
ffffffffc0200fda:	0106a823          	sw	a6,16(a3)
    prev->next = next->prev = elm;
ffffffffc0200fde:	00c8b023          	sd	a2,0(a7)
ffffffffc0200fe2:	e690                	sd	a2,8(a3)
    elm->next = next;
ffffffffc0200fe4:	03153023          	sd	a7,32(a0)
    elm->prev = prev;
ffffffffc0200fe8:	ed14                	sd	a3,24(a0)
        origin_size -= order_size;
ffffffffc0200fea:	8d9d                	sub	a1,a1,a5
        while (order > 0 && origin_size < order_size) {
ffffffffc0200fec:	c711                	beqz	a4,ffffffffc0200ff8 <buddy_init_memmap+0x80>
ffffffffc0200fee:	00f5f563          	bgeu	a1,a5,ffffffffc0200ff8 <buddy_init_memmap+0x80>
            order -= 1;
ffffffffc0200ff2:	177d                	addi	a4,a4,-1
            order_size >>= 1;
ffffffffc0200ff4:	8385                	srli	a5,a5,0x1
        while (order > 0 && origin_size < order_size) {
ffffffffc0200ff6:	ff65                	bnez	a4,ffffffffc0200fee <buddy_init_memmap+0x76>
        p += order_size;
ffffffffc0200ff8:	00279693          	slli	a3,a5,0x2
ffffffffc0200ffc:	96be                	add	a3,a3,a5
ffffffffc0200ffe:	068e                	slli	a3,a3,0x3
ffffffffc0201000:	9536                	add	a0,a0,a3
    while (origin_size!= 0) {
ffffffffc0201002:	f9dd                	bnez	a1,ffffffffc0200fb8 <buddy_init_memmap+0x40>
}
ffffffffc0201004:	60a2                	ld	ra,8(sp)
ffffffffc0201006:	0141                	addi	sp,sp,16
ffffffffc0201008:	8082                	ret
        assert(PageReserved(p));
ffffffffc020100a:	00001697          	auipc	a3,0x1
ffffffffc020100e:	02668693          	addi	a3,a3,38 # ffffffffc0202030 <commands+0x6a8>
ffffffffc0201012:	00001617          	auipc	a2,0x1
ffffffffc0201016:	e7660613          	addi	a2,a2,-394 # ffffffffc0201e88 <commands+0x500>
ffffffffc020101a:	45e1                	li	a1,24
ffffffffc020101c:	00001517          	auipc	a0,0x1
ffffffffc0201020:	e8450513          	addi	a0,a0,-380 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0201024:	b88ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0201028:	00001697          	auipc	a3,0x1
ffffffffc020102c:	e5868693          	addi	a3,a3,-424 # ffffffffc0201e80 <commands+0x4f8>
ffffffffc0201030:	00001617          	auipc	a2,0x1
ffffffffc0201034:	e5860613          	addi	a2,a2,-424 # ffffffffc0201e88 <commands+0x500>
ffffffffc0201038:	45d1                	li	a1,20
ffffffffc020103a:	00001517          	auipc	a0,0x1
ffffffffc020103e:	e6650513          	addi	a0,a0,-410 # ffffffffc0201ea0 <commands+0x518>
ffffffffc0201042:	b6aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201046 <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    //pmm_manager = &best_fit_pmm_manager; // 修改此处：测试 Best-Fit 算法
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc0201046:	00001797          	auipc	a5,0x1
ffffffffc020104a:	01a78793          	addi	a5,a5,26 # ffffffffc0202060 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020104e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201050:	1101                	addi	sp,sp,-32
ffffffffc0201052:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201054:	00001517          	auipc	a0,0x1
ffffffffc0201058:	04450513          	addi	a0,a0,68 # ffffffffc0202098 <buddy_system_pmm_manager+0x38>
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc020105c:	00005497          	auipc	s1,0x5
ffffffffc0201060:	4dc48493          	addi	s1,s1,1244 # ffffffffc0206538 <pmm_manager>
void pmm_init(void) {
ffffffffc0201064:	ec06                	sd	ra,24(sp)
ffffffffc0201066:	e822                	sd	s0,16(sp)
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc0201068:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020106a:	848ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc020106e:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201070:	00005417          	auipc	s0,0x5
ffffffffc0201074:	4e040413          	addi	s0,s0,1248 # ffffffffc0206550 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201078:	679c                	ld	a5,8(a5)
ffffffffc020107a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020107c:	57f5                	li	a5,-3
ffffffffc020107e:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201080:	00001517          	auipc	a0,0x1
ffffffffc0201084:	03050513          	addi	a0,a0,48 # ffffffffc02020b0 <buddy_system_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201088:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc020108a:	828ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020108e:	46c5                	li	a3,17
ffffffffc0201090:	06ee                	slli	a3,a3,0x1b
ffffffffc0201092:	40100613          	li	a2,1025
ffffffffc0201096:	16fd                	addi	a3,a3,-1
ffffffffc0201098:	07e005b7          	lui	a1,0x7e00
ffffffffc020109c:	0656                	slli	a2,a2,0x15
ffffffffc020109e:	00001517          	auipc	a0,0x1
ffffffffc02010a2:	02a50513          	addi	a0,a0,42 # ffffffffc02020c8 <buddy_system_pmm_manager+0x68>
ffffffffc02010a6:	80cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010aa:	777d                	lui	a4,0xfffff
ffffffffc02010ac:	00006797          	auipc	a5,0x6
ffffffffc02010b0:	4b378793          	addi	a5,a5,1203 # ffffffffc020755f <end+0xfff>
ffffffffc02010b4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02010b6:	00005517          	auipc	a0,0x5
ffffffffc02010ba:	47250513          	addi	a0,a0,1138 # ffffffffc0206528 <npage>
ffffffffc02010be:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010c2:	00005597          	auipc	a1,0x5
ffffffffc02010c6:	46e58593          	addi	a1,a1,1134 # ffffffffc0206530 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02010ca:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010cc:	e19c                	sd	a5,0(a1)
ffffffffc02010ce:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010d0:	4701                	li	a4,0
ffffffffc02010d2:	4885                	li	a7,1
ffffffffc02010d4:	fff80837          	lui	a6,0xfff80
ffffffffc02010d8:	a011                	j	ffffffffc02010dc <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc02010da:	619c                	ld	a5,0(a1)
ffffffffc02010dc:	97b6                	add	a5,a5,a3
ffffffffc02010de:	07a1                	addi	a5,a5,8
ffffffffc02010e0:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010e4:	611c                	ld	a5,0(a0)
ffffffffc02010e6:	0705                	addi	a4,a4,1
ffffffffc02010e8:	02868693          	addi	a3,a3,40
ffffffffc02010ec:	01078633          	add	a2,a5,a6
ffffffffc02010f0:	fec765e3          	bltu	a4,a2,ffffffffc02010da <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010f4:	6190                	ld	a2,0(a1)
ffffffffc02010f6:	00279713          	slli	a4,a5,0x2
ffffffffc02010fa:	973e                	add	a4,a4,a5
ffffffffc02010fc:	fec006b7          	lui	a3,0xfec00
ffffffffc0201100:	070e                	slli	a4,a4,0x3
ffffffffc0201102:	96b2                	add	a3,a3,a2
ffffffffc0201104:	96ba                	add	a3,a3,a4
ffffffffc0201106:	c0200737          	lui	a4,0xc0200
ffffffffc020110a:	08e6ef63          	bltu	a3,a4,ffffffffc02011a8 <pmm_init+0x162>
ffffffffc020110e:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc0201110:	45c5                	li	a1,17
ffffffffc0201112:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201114:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201116:	04b6e863          	bltu	a3,a1,ffffffffc0201166 <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020111a:	609c                	ld	a5,0(s1)
ffffffffc020111c:	7b9c                	ld	a5,48(a5)
ffffffffc020111e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201120:	00001517          	auipc	a0,0x1
ffffffffc0201124:	04050513          	addi	a0,a0,64 # ffffffffc0202160 <buddy_system_pmm_manager+0x100>
ffffffffc0201128:	f8bfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020112c:	00004597          	auipc	a1,0x4
ffffffffc0201130:	ed458593          	addi	a1,a1,-300 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201134:	00005797          	auipc	a5,0x5
ffffffffc0201138:	40b7ba23          	sd	a1,1044(a5) # ffffffffc0206548 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020113c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201140:	08f5e063          	bltu	a1,a5,ffffffffc02011c0 <pmm_init+0x17a>
ffffffffc0201144:	6010                	ld	a2,0(s0)
}
ffffffffc0201146:	6442                	ld	s0,16(sp)
ffffffffc0201148:	60e2                	ld	ra,24(sp)
ffffffffc020114a:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020114c:	40c58633          	sub	a2,a1,a2
ffffffffc0201150:	00005797          	auipc	a5,0x5
ffffffffc0201154:	3ec7b823          	sd	a2,1008(a5) # ffffffffc0206540 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201158:	00001517          	auipc	a0,0x1
ffffffffc020115c:	02850513          	addi	a0,a0,40 # ffffffffc0202180 <buddy_system_pmm_manager+0x120>
}
ffffffffc0201160:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201162:	f51fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201166:	6705                	lui	a4,0x1
ffffffffc0201168:	177d                	addi	a4,a4,-1
ffffffffc020116a:	96ba                	add	a3,a3,a4
ffffffffc020116c:	777d                	lui	a4,0xfffff
ffffffffc020116e:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201170:	00c6d513          	srli	a0,a3,0xc
ffffffffc0201174:	00f57e63          	bgeu	a0,a5,ffffffffc0201190 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201178:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020117a:	982a                	add	a6,a6,a0
ffffffffc020117c:	00281513          	slli	a0,a6,0x2
ffffffffc0201180:	9542                	add	a0,a0,a6
ffffffffc0201182:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201184:	8d95                	sub	a1,a1,a3
ffffffffc0201186:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201188:	81b1                	srli	a1,a1,0xc
ffffffffc020118a:	9532                	add	a0,a0,a2
ffffffffc020118c:	9782                	jalr	a5
}
ffffffffc020118e:	b771                	j	ffffffffc020111a <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc0201190:	00001617          	auipc	a2,0x1
ffffffffc0201194:	fa060613          	addi	a2,a2,-96 # ffffffffc0202130 <buddy_system_pmm_manager+0xd0>
ffffffffc0201198:	06b00593          	li	a1,107
ffffffffc020119c:	00001517          	auipc	a0,0x1
ffffffffc02011a0:	fb450513          	addi	a0,a0,-76 # ffffffffc0202150 <buddy_system_pmm_manager+0xf0>
ffffffffc02011a4:	a08ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011a8:	00001617          	auipc	a2,0x1
ffffffffc02011ac:	f5060613          	addi	a2,a2,-176 # ffffffffc02020f8 <buddy_system_pmm_manager+0x98>
ffffffffc02011b0:	07000593          	li	a1,112
ffffffffc02011b4:	00001517          	auipc	a0,0x1
ffffffffc02011b8:	f6c50513          	addi	a0,a0,-148 # ffffffffc0202120 <buddy_system_pmm_manager+0xc0>
ffffffffc02011bc:	9f0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011c0:	86ae                	mv	a3,a1
ffffffffc02011c2:	00001617          	auipc	a2,0x1
ffffffffc02011c6:	f3660613          	addi	a2,a2,-202 # ffffffffc02020f8 <buddy_system_pmm_manager+0x98>
ffffffffc02011ca:	08b00593          	li	a1,139
ffffffffc02011ce:	00001517          	auipc	a0,0x1
ffffffffc02011d2:	f5250513          	addi	a0,a0,-174 # ffffffffc0202120 <buddy_system_pmm_manager+0xc0>
ffffffffc02011d6:	9d6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011da <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02011da:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011de:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02011e0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011e4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02011e6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02011ea:	f022                	sd	s0,32(sp)
ffffffffc02011ec:	ec26                	sd	s1,24(sp)
ffffffffc02011ee:	e84a                	sd	s2,16(sp)
ffffffffc02011f0:	f406                	sd	ra,40(sp)
ffffffffc02011f2:	e44e                	sd	s3,8(sp)
ffffffffc02011f4:	84aa                	mv	s1,a0
ffffffffc02011f6:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02011f8:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02011fc:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02011fe:	03067e63          	bgeu	a2,a6,ffffffffc020123a <printnum+0x60>
ffffffffc0201202:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201204:	00805763          	blez	s0,ffffffffc0201212 <printnum+0x38>
ffffffffc0201208:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020120a:	85ca                	mv	a1,s2
ffffffffc020120c:	854e                	mv	a0,s3
ffffffffc020120e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201210:	fc65                	bnez	s0,ffffffffc0201208 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201212:	1a02                	slli	s4,s4,0x20
ffffffffc0201214:	00001797          	auipc	a5,0x1
ffffffffc0201218:	fac78793          	addi	a5,a5,-84 # ffffffffc02021c0 <buddy_system_pmm_manager+0x160>
ffffffffc020121c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201220:	9a3e                	add	s4,s4,a5
}
ffffffffc0201222:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201224:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201228:	70a2                	ld	ra,40(sp)
ffffffffc020122a:	69a2                	ld	s3,8(sp)
ffffffffc020122c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020122e:	85ca                	mv	a1,s2
ffffffffc0201230:	87a6                	mv	a5,s1
}
ffffffffc0201232:	6942                	ld	s2,16(sp)
ffffffffc0201234:	64e2                	ld	s1,24(sp)
ffffffffc0201236:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201238:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020123a:	03065633          	divu	a2,a2,a6
ffffffffc020123e:	8722                	mv	a4,s0
ffffffffc0201240:	f9bff0ef          	jal	ra,ffffffffc02011da <printnum>
ffffffffc0201244:	b7f9                	j	ffffffffc0201212 <printnum+0x38>

ffffffffc0201246 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201246:	7119                	addi	sp,sp,-128
ffffffffc0201248:	f4a6                	sd	s1,104(sp)
ffffffffc020124a:	f0ca                	sd	s2,96(sp)
ffffffffc020124c:	ecce                	sd	s3,88(sp)
ffffffffc020124e:	e8d2                	sd	s4,80(sp)
ffffffffc0201250:	e4d6                	sd	s5,72(sp)
ffffffffc0201252:	e0da                	sd	s6,64(sp)
ffffffffc0201254:	fc5e                	sd	s7,56(sp)
ffffffffc0201256:	f06a                	sd	s10,32(sp)
ffffffffc0201258:	fc86                	sd	ra,120(sp)
ffffffffc020125a:	f8a2                	sd	s0,112(sp)
ffffffffc020125c:	f862                	sd	s8,48(sp)
ffffffffc020125e:	f466                	sd	s9,40(sp)
ffffffffc0201260:	ec6e                	sd	s11,24(sp)
ffffffffc0201262:	892a                	mv	s2,a0
ffffffffc0201264:	84ae                	mv	s1,a1
ffffffffc0201266:	8d32                	mv	s10,a2
ffffffffc0201268:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020126a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020126e:	5b7d                	li	s6,-1
ffffffffc0201270:	00001a97          	auipc	s5,0x1
ffffffffc0201274:	f84a8a93          	addi	s5,s5,-124 # ffffffffc02021f4 <buddy_system_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201278:	00001b97          	auipc	s7,0x1
ffffffffc020127c:	158b8b93          	addi	s7,s7,344 # ffffffffc02023d0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201280:	000d4503          	lbu	a0,0(s10)
ffffffffc0201284:	001d0413          	addi	s0,s10,1
ffffffffc0201288:	01350a63          	beq	a0,s3,ffffffffc020129c <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020128c:	c121                	beqz	a0,ffffffffc02012cc <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020128e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201290:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201292:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201294:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201298:	ff351ae3          	bne	a0,s3,ffffffffc020128c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020129c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02012a0:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02012a4:	4c81                	li	s9,0
ffffffffc02012a6:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02012a8:	5c7d                	li	s8,-1
ffffffffc02012aa:	5dfd                	li	s11,-1
ffffffffc02012ac:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02012b0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012b2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012b6:	0ff5f593          	zext.b	a1,a1
ffffffffc02012ba:	00140d13          	addi	s10,s0,1
ffffffffc02012be:	04b56263          	bltu	a0,a1,ffffffffc0201302 <vprintfmt+0xbc>
ffffffffc02012c2:	058a                	slli	a1,a1,0x2
ffffffffc02012c4:	95d6                	add	a1,a1,s5
ffffffffc02012c6:	4194                	lw	a3,0(a1)
ffffffffc02012c8:	96d6                	add	a3,a3,s5
ffffffffc02012ca:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012cc:	70e6                	ld	ra,120(sp)
ffffffffc02012ce:	7446                	ld	s0,112(sp)
ffffffffc02012d0:	74a6                	ld	s1,104(sp)
ffffffffc02012d2:	7906                	ld	s2,96(sp)
ffffffffc02012d4:	69e6                	ld	s3,88(sp)
ffffffffc02012d6:	6a46                	ld	s4,80(sp)
ffffffffc02012d8:	6aa6                	ld	s5,72(sp)
ffffffffc02012da:	6b06                	ld	s6,64(sp)
ffffffffc02012dc:	7be2                	ld	s7,56(sp)
ffffffffc02012de:	7c42                	ld	s8,48(sp)
ffffffffc02012e0:	7ca2                	ld	s9,40(sp)
ffffffffc02012e2:	7d02                	ld	s10,32(sp)
ffffffffc02012e4:	6de2                	ld	s11,24(sp)
ffffffffc02012e6:	6109                	addi	sp,sp,128
ffffffffc02012e8:	8082                	ret
            padc = '0';
ffffffffc02012ea:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02012ec:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012f0:	846a                	mv	s0,s10
ffffffffc02012f2:	00140d13          	addi	s10,s0,1
ffffffffc02012f6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02012fa:	0ff5f593          	zext.b	a1,a1
ffffffffc02012fe:	fcb572e3          	bgeu	a0,a1,ffffffffc02012c2 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201302:	85a6                	mv	a1,s1
ffffffffc0201304:	02500513          	li	a0,37
ffffffffc0201308:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020130a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020130e:	8d22                	mv	s10,s0
ffffffffc0201310:	f73788e3          	beq	a5,s3,ffffffffc0201280 <vprintfmt+0x3a>
ffffffffc0201314:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201318:	1d7d                	addi	s10,s10,-1
ffffffffc020131a:	ff379de3          	bne	a5,s3,ffffffffc0201314 <vprintfmt+0xce>
ffffffffc020131e:	b78d                	j	ffffffffc0201280 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201320:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201324:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201328:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020132a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020132e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201332:	02d86463          	bltu	a6,a3,ffffffffc020135a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201336:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020133a:	002c169b          	slliw	a3,s8,0x2
ffffffffc020133e:	0186873b          	addw	a4,a3,s8
ffffffffc0201342:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201346:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201348:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020134c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020134e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201352:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201356:	fed870e3          	bgeu	a6,a3,ffffffffc0201336 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020135a:	f40ddce3          	bgez	s11,ffffffffc02012b2 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020135e:	8de2                	mv	s11,s8
ffffffffc0201360:	5c7d                	li	s8,-1
ffffffffc0201362:	bf81                	j	ffffffffc02012b2 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201364:	fffdc693          	not	a3,s11
ffffffffc0201368:	96fd                	srai	a3,a3,0x3f
ffffffffc020136a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020136e:	00144603          	lbu	a2,1(s0)
ffffffffc0201372:	2d81                	sext.w	s11,s11
ffffffffc0201374:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201376:	bf35                	j	ffffffffc02012b2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201378:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020137c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201380:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201382:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201384:	bfd9                	j	ffffffffc020135a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201386:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201388:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020138c:	01174463          	blt	a4,a7,ffffffffc0201394 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201390:	1a088e63          	beqz	a7,ffffffffc020154c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201394:	000a3603          	ld	a2,0(s4)
ffffffffc0201398:	46c1                	li	a3,16
ffffffffc020139a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020139c:	2781                	sext.w	a5,a5
ffffffffc020139e:	876e                	mv	a4,s11
ffffffffc02013a0:	85a6                	mv	a1,s1
ffffffffc02013a2:	854a                	mv	a0,s2
ffffffffc02013a4:	e37ff0ef          	jal	ra,ffffffffc02011da <printnum>
            break;
ffffffffc02013a8:	bde1                	j	ffffffffc0201280 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02013aa:	000a2503          	lw	a0,0(s4)
ffffffffc02013ae:	85a6                	mv	a1,s1
ffffffffc02013b0:	0a21                	addi	s4,s4,8
ffffffffc02013b2:	9902                	jalr	s2
            break;
ffffffffc02013b4:	b5f1                	j	ffffffffc0201280 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013b8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013bc:	01174463          	blt	a4,a7,ffffffffc02013c4 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02013c0:	18088163          	beqz	a7,ffffffffc0201542 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02013c4:	000a3603          	ld	a2,0(s4)
ffffffffc02013c8:	46a9                	li	a3,10
ffffffffc02013ca:	8a2e                	mv	s4,a1
ffffffffc02013cc:	bfc1                	j	ffffffffc020139c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013ce:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02013d2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013d4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013d6:	bdf1                	j	ffffffffc02012b2 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02013d8:	85a6                	mv	a1,s1
ffffffffc02013da:	02500513          	li	a0,37
ffffffffc02013de:	9902                	jalr	s2
            break;
ffffffffc02013e0:	b545                	j	ffffffffc0201280 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e2:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02013e6:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013ea:	b5e1                	j	ffffffffc02012b2 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02013ec:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013ee:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013f2:	01174463          	blt	a4,a7,ffffffffc02013fa <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02013f6:	14088163          	beqz	a7,ffffffffc0201538 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02013fa:	000a3603          	ld	a2,0(s4)
ffffffffc02013fe:	46a1                	li	a3,8
ffffffffc0201400:	8a2e                	mv	s4,a1
ffffffffc0201402:	bf69                	j	ffffffffc020139c <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201404:	03000513          	li	a0,48
ffffffffc0201408:	85a6                	mv	a1,s1
ffffffffc020140a:	e03e                	sd	a5,0(sp)
ffffffffc020140c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020140e:	85a6                	mv	a1,s1
ffffffffc0201410:	07800513          	li	a0,120
ffffffffc0201414:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201416:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201418:	6782                	ld	a5,0(sp)
ffffffffc020141a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020141c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201420:	bfb5                	j	ffffffffc020139c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201422:	000a3403          	ld	s0,0(s4)
ffffffffc0201426:	008a0713          	addi	a4,s4,8
ffffffffc020142a:	e03a                	sd	a4,0(sp)
ffffffffc020142c:	14040263          	beqz	s0,ffffffffc0201570 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201430:	0fb05763          	blez	s11,ffffffffc020151e <vprintfmt+0x2d8>
ffffffffc0201434:	02d00693          	li	a3,45
ffffffffc0201438:	0cd79163          	bne	a5,a3,ffffffffc02014fa <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020143c:	00044783          	lbu	a5,0(s0)
ffffffffc0201440:	0007851b          	sext.w	a0,a5
ffffffffc0201444:	cf85                	beqz	a5,ffffffffc020147c <vprintfmt+0x236>
ffffffffc0201446:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020144a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020144e:	000c4563          	bltz	s8,ffffffffc0201458 <vprintfmt+0x212>
ffffffffc0201452:	3c7d                	addiw	s8,s8,-1
ffffffffc0201454:	036c0263          	beq	s8,s6,ffffffffc0201478 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201458:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020145a:	0e0c8e63          	beqz	s9,ffffffffc0201556 <vprintfmt+0x310>
ffffffffc020145e:	3781                	addiw	a5,a5,-32
ffffffffc0201460:	0ef47b63          	bgeu	s0,a5,ffffffffc0201556 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201464:	03f00513          	li	a0,63
ffffffffc0201468:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020146a:	000a4783          	lbu	a5,0(s4)
ffffffffc020146e:	3dfd                	addiw	s11,s11,-1
ffffffffc0201470:	0a05                	addi	s4,s4,1
ffffffffc0201472:	0007851b          	sext.w	a0,a5
ffffffffc0201476:	ffe1                	bnez	a5,ffffffffc020144e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201478:	01b05963          	blez	s11,ffffffffc020148a <vprintfmt+0x244>
ffffffffc020147c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020147e:	85a6                	mv	a1,s1
ffffffffc0201480:	02000513          	li	a0,32
ffffffffc0201484:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201486:	fe0d9be3          	bnez	s11,ffffffffc020147c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020148a:	6a02                	ld	s4,0(sp)
ffffffffc020148c:	bbd5                	j	ffffffffc0201280 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020148e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201490:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201494:	01174463          	blt	a4,a7,ffffffffc020149c <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201498:	08088d63          	beqz	a7,ffffffffc0201532 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020149c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02014a0:	0a044d63          	bltz	s0,ffffffffc020155a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02014a4:	8622                	mv	a2,s0
ffffffffc02014a6:	8a66                	mv	s4,s9
ffffffffc02014a8:	46a9                	li	a3,10
ffffffffc02014aa:	bdcd                	j	ffffffffc020139c <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02014ac:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014b0:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02014b2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02014b4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02014b8:	8fb5                	xor	a5,a5,a3
ffffffffc02014ba:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014be:	02d74163          	blt	a4,a3,ffffffffc02014e0 <vprintfmt+0x29a>
ffffffffc02014c2:	00369793          	slli	a5,a3,0x3
ffffffffc02014c6:	97de                	add	a5,a5,s7
ffffffffc02014c8:	639c                	ld	a5,0(a5)
ffffffffc02014ca:	cb99                	beqz	a5,ffffffffc02014e0 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02014cc:	86be                	mv	a3,a5
ffffffffc02014ce:	00001617          	auipc	a2,0x1
ffffffffc02014d2:	d2260613          	addi	a2,a2,-734 # ffffffffc02021f0 <buddy_system_pmm_manager+0x190>
ffffffffc02014d6:	85a6                	mv	a1,s1
ffffffffc02014d8:	854a                	mv	a0,s2
ffffffffc02014da:	0ce000ef          	jal	ra,ffffffffc02015a8 <printfmt>
ffffffffc02014de:	b34d                	j	ffffffffc0201280 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014e0:	00001617          	auipc	a2,0x1
ffffffffc02014e4:	d0060613          	addi	a2,a2,-768 # ffffffffc02021e0 <buddy_system_pmm_manager+0x180>
ffffffffc02014e8:	85a6                	mv	a1,s1
ffffffffc02014ea:	854a                	mv	a0,s2
ffffffffc02014ec:	0bc000ef          	jal	ra,ffffffffc02015a8 <printfmt>
ffffffffc02014f0:	bb41                	j	ffffffffc0201280 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02014f2:	00001417          	auipc	s0,0x1
ffffffffc02014f6:	ce640413          	addi	s0,s0,-794 # ffffffffc02021d8 <buddy_system_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014fa:	85e2                	mv	a1,s8
ffffffffc02014fc:	8522                	mv	a0,s0
ffffffffc02014fe:	e43e                	sd	a5,8(sp)
ffffffffc0201500:	1cc000ef          	jal	ra,ffffffffc02016cc <strnlen>
ffffffffc0201504:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201508:	01b05b63          	blez	s11,ffffffffc020151e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020150c:	67a2                	ld	a5,8(sp)
ffffffffc020150e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201512:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201514:	85a6                	mv	a1,s1
ffffffffc0201516:	8552                	mv	a0,s4
ffffffffc0201518:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020151a:	fe0d9ce3          	bnez	s11,ffffffffc0201512 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020151e:	00044783          	lbu	a5,0(s0)
ffffffffc0201522:	00140a13          	addi	s4,s0,1
ffffffffc0201526:	0007851b          	sext.w	a0,a5
ffffffffc020152a:	d3a5                	beqz	a5,ffffffffc020148a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020152c:	05e00413          	li	s0,94
ffffffffc0201530:	bf39                	j	ffffffffc020144e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201532:	000a2403          	lw	s0,0(s4)
ffffffffc0201536:	b7ad                	j	ffffffffc02014a0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201538:	000a6603          	lwu	a2,0(s4)
ffffffffc020153c:	46a1                	li	a3,8
ffffffffc020153e:	8a2e                	mv	s4,a1
ffffffffc0201540:	bdb1                	j	ffffffffc020139c <vprintfmt+0x156>
ffffffffc0201542:	000a6603          	lwu	a2,0(s4)
ffffffffc0201546:	46a9                	li	a3,10
ffffffffc0201548:	8a2e                	mv	s4,a1
ffffffffc020154a:	bd89                	j	ffffffffc020139c <vprintfmt+0x156>
ffffffffc020154c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201550:	46c1                	li	a3,16
ffffffffc0201552:	8a2e                	mv	s4,a1
ffffffffc0201554:	b5a1                	j	ffffffffc020139c <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201556:	9902                	jalr	s2
ffffffffc0201558:	bf09                	j	ffffffffc020146a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020155a:	85a6                	mv	a1,s1
ffffffffc020155c:	02d00513          	li	a0,45
ffffffffc0201560:	e03e                	sd	a5,0(sp)
ffffffffc0201562:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201564:	6782                	ld	a5,0(sp)
ffffffffc0201566:	8a66                	mv	s4,s9
ffffffffc0201568:	40800633          	neg	a2,s0
ffffffffc020156c:	46a9                	li	a3,10
ffffffffc020156e:	b53d                	j	ffffffffc020139c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201570:	03b05163          	blez	s11,ffffffffc0201592 <vprintfmt+0x34c>
ffffffffc0201574:	02d00693          	li	a3,45
ffffffffc0201578:	f6d79de3          	bne	a5,a3,ffffffffc02014f2 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020157c:	00001417          	auipc	s0,0x1
ffffffffc0201580:	c5c40413          	addi	s0,s0,-932 # ffffffffc02021d8 <buddy_system_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201584:	02800793          	li	a5,40
ffffffffc0201588:	02800513          	li	a0,40
ffffffffc020158c:	00140a13          	addi	s4,s0,1
ffffffffc0201590:	bd6d                	j	ffffffffc020144a <vprintfmt+0x204>
ffffffffc0201592:	00001a17          	auipc	s4,0x1
ffffffffc0201596:	c47a0a13          	addi	s4,s4,-953 # ffffffffc02021d9 <buddy_system_pmm_manager+0x179>
ffffffffc020159a:	02800513          	li	a0,40
ffffffffc020159e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015a2:	05e00413          	li	s0,94
ffffffffc02015a6:	b565                	j	ffffffffc020144e <vprintfmt+0x208>

ffffffffc02015a8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015a8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02015aa:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015ae:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015b0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015b2:	ec06                	sd	ra,24(sp)
ffffffffc02015b4:	f83a                	sd	a4,48(sp)
ffffffffc02015b6:	fc3e                	sd	a5,56(sp)
ffffffffc02015b8:	e0c2                	sd	a6,64(sp)
ffffffffc02015ba:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02015bc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015be:	c89ff0ef          	jal	ra,ffffffffc0201246 <vprintfmt>
}
ffffffffc02015c2:	60e2                	ld	ra,24(sp)
ffffffffc02015c4:	6161                	addi	sp,sp,80
ffffffffc02015c6:	8082                	ret

ffffffffc02015c8 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02015c8:	715d                	addi	sp,sp,-80
ffffffffc02015ca:	e486                	sd	ra,72(sp)
ffffffffc02015cc:	e0a6                	sd	s1,64(sp)
ffffffffc02015ce:	fc4a                	sd	s2,56(sp)
ffffffffc02015d0:	f84e                	sd	s3,48(sp)
ffffffffc02015d2:	f452                	sd	s4,40(sp)
ffffffffc02015d4:	f056                	sd	s5,32(sp)
ffffffffc02015d6:	ec5a                	sd	s6,24(sp)
ffffffffc02015d8:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02015da:	c901                	beqz	a0,ffffffffc02015ea <readline+0x22>
ffffffffc02015dc:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02015de:	00001517          	auipc	a0,0x1
ffffffffc02015e2:	c1250513          	addi	a0,a0,-1006 # ffffffffc02021f0 <buddy_system_pmm_manager+0x190>
ffffffffc02015e6:	acdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc02015ea:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015ec:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02015ee:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02015f0:	4aa9                	li	s5,10
ffffffffc02015f2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02015f4:	00005b97          	auipc	s7,0x5
ffffffffc02015f8:	b24b8b93          	addi	s7,s7,-1244 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02015fc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201600:	b2bfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201604:	00054a63          	bltz	a0,ffffffffc0201618 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201608:	00a95a63          	bge	s2,a0,ffffffffc020161c <readline+0x54>
ffffffffc020160c:	029a5263          	bge	s4,s1,ffffffffc0201630 <readline+0x68>
        c = getchar();
ffffffffc0201610:	b1bfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201614:	fe055ae3          	bgez	a0,ffffffffc0201608 <readline+0x40>
            return NULL;
ffffffffc0201618:	4501                	li	a0,0
ffffffffc020161a:	a091                	j	ffffffffc020165e <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020161c:	03351463          	bne	a0,s3,ffffffffc0201644 <readline+0x7c>
ffffffffc0201620:	e8a9                	bnez	s1,ffffffffc0201672 <readline+0xaa>
        c = getchar();
ffffffffc0201622:	b09fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201626:	fe0549e3          	bltz	a0,ffffffffc0201618 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020162a:	fea959e3          	bge	s2,a0,ffffffffc020161c <readline+0x54>
ffffffffc020162e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201630:	e42a                	sd	a0,8(sp)
ffffffffc0201632:	ab7fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201636:	6522                	ld	a0,8(sp)
ffffffffc0201638:	009b87b3          	add	a5,s7,s1
ffffffffc020163c:	2485                	addiw	s1,s1,1
ffffffffc020163e:	00a78023          	sb	a0,0(a5)
ffffffffc0201642:	bf7d                	j	ffffffffc0201600 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201644:	01550463          	beq	a0,s5,ffffffffc020164c <readline+0x84>
ffffffffc0201648:	fb651ce3          	bne	a0,s6,ffffffffc0201600 <readline+0x38>
            cputchar(c);
ffffffffc020164c:	a9dfe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc0201650:	00005517          	auipc	a0,0x5
ffffffffc0201654:	ac850513          	addi	a0,a0,-1336 # ffffffffc0206118 <buf>
ffffffffc0201658:	94aa                	add	s1,s1,a0
ffffffffc020165a:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020165e:	60a6                	ld	ra,72(sp)
ffffffffc0201660:	6486                	ld	s1,64(sp)
ffffffffc0201662:	7962                	ld	s2,56(sp)
ffffffffc0201664:	79c2                	ld	s3,48(sp)
ffffffffc0201666:	7a22                	ld	s4,40(sp)
ffffffffc0201668:	7a82                	ld	s5,32(sp)
ffffffffc020166a:	6b62                	ld	s6,24(sp)
ffffffffc020166c:	6bc2                	ld	s7,16(sp)
ffffffffc020166e:	6161                	addi	sp,sp,80
ffffffffc0201670:	8082                	ret
            cputchar(c);
ffffffffc0201672:	4521                	li	a0,8
ffffffffc0201674:	a75fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc0201678:	34fd                	addiw	s1,s1,-1
ffffffffc020167a:	b759                	j	ffffffffc0201600 <readline+0x38>

ffffffffc020167c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020167c:	4781                	li	a5,0
ffffffffc020167e:	00005717          	auipc	a4,0x5
ffffffffc0201682:	98a73703          	ld	a4,-1654(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201686:	88ba                	mv	a7,a4
ffffffffc0201688:	852a                	mv	a0,a0
ffffffffc020168a:	85be                	mv	a1,a5
ffffffffc020168c:	863e                	mv	a2,a5
ffffffffc020168e:	00000073          	ecall
ffffffffc0201692:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201694:	8082                	ret

ffffffffc0201696 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201696:	4781                	li	a5,0
ffffffffc0201698:	00005717          	auipc	a4,0x5
ffffffffc020169c:	ec073703          	ld	a4,-320(a4) # ffffffffc0206558 <SBI_SET_TIMER>
ffffffffc02016a0:	88ba                	mv	a7,a4
ffffffffc02016a2:	852a                	mv	a0,a0
ffffffffc02016a4:	85be                	mv	a1,a5
ffffffffc02016a6:	863e                	mv	a2,a5
ffffffffc02016a8:	00000073          	ecall
ffffffffc02016ac:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02016ae:	8082                	ret

ffffffffc02016b0 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02016b0:	4501                	li	a0,0
ffffffffc02016b2:	00005797          	auipc	a5,0x5
ffffffffc02016b6:	94e7b783          	ld	a5,-1714(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc02016ba:	88be                	mv	a7,a5
ffffffffc02016bc:	852a                	mv	a0,a0
ffffffffc02016be:	85aa                	mv	a1,a0
ffffffffc02016c0:	862a                	mv	a2,a0
ffffffffc02016c2:	00000073          	ecall
ffffffffc02016c6:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc02016c8:	2501                	sext.w	a0,a0
ffffffffc02016ca:	8082                	ret

ffffffffc02016cc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02016cc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016ce:	e589                	bnez	a1,ffffffffc02016d8 <strnlen+0xc>
ffffffffc02016d0:	a811                	j	ffffffffc02016e4 <strnlen+0x18>
        cnt ++;
ffffffffc02016d2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016d4:	00f58863          	beq	a1,a5,ffffffffc02016e4 <strnlen+0x18>
ffffffffc02016d8:	00f50733          	add	a4,a0,a5
ffffffffc02016dc:	00074703          	lbu	a4,0(a4)
ffffffffc02016e0:	fb6d                	bnez	a4,ffffffffc02016d2 <strnlen+0x6>
ffffffffc02016e2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02016e4:	852e                	mv	a0,a1
ffffffffc02016e6:	8082                	ret

ffffffffc02016e8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016e8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016ec:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016f0:	cb89                	beqz	a5,ffffffffc0201702 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02016f2:	0505                	addi	a0,a0,1
ffffffffc02016f4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016f6:	fee789e3          	beq	a5,a4,ffffffffc02016e8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016fa:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02016fe:	9d19                	subw	a0,a0,a4
ffffffffc0201700:	8082                	ret
ffffffffc0201702:	4501                	li	a0,0
ffffffffc0201704:	bfed                	j	ffffffffc02016fe <strcmp+0x16>

ffffffffc0201706 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201706:	00054783          	lbu	a5,0(a0)
ffffffffc020170a:	c799                	beqz	a5,ffffffffc0201718 <strchr+0x12>
        if (*s == c) {
ffffffffc020170c:	00f58763          	beq	a1,a5,ffffffffc020171a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201710:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201714:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201716:	fbfd                	bnez	a5,ffffffffc020170c <strchr+0x6>
    }
    return NULL;
ffffffffc0201718:	4501                	li	a0,0
}
ffffffffc020171a:	8082                	ret

ffffffffc020171c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020171c:	ca01                	beqz	a2,ffffffffc020172c <memset+0x10>
ffffffffc020171e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201720:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201722:	0785                	addi	a5,a5,1
ffffffffc0201724:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201728:	fec79de3          	bne	a5,a2,ffffffffc0201722 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020172c:	8082                	ret
