
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
ffffffffc020003e:	52e60613          	addi	a2,a2,1326 # ffffffffc0206568 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	730010ef          	jal	ra,ffffffffc020177a <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	73e50513          	addi	a0,a0,1854 # ffffffffc0201790 <etext+0x4>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	79c000ef          	jal	ra,ffffffffc0200802 <pmm_init>

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
ffffffffc02000a6:	1fe010ef          	jal	ra,ffffffffc02012a4 <vprintfmt>
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
ffffffffc02000dc:	1c8010ef          	jal	ra,ffffffffc02012a4 <vprintfmt>
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
ffffffffc0200140:	67450513          	addi	a0,a0,1652 # ffffffffc02017b0 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00001517          	auipc	a0,0x1
ffffffffc0200156:	67e50513          	addi	a0,a0,1662 # ffffffffc02017d0 <etext+0x44>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00001597          	auipc	a1,0x1
ffffffffc0200162:	62e58593          	addi	a1,a1,1582 # ffffffffc020178c <etext>
ffffffffc0200166:	00001517          	auipc	a0,0x1
ffffffffc020016a:	68a50513          	addi	a0,a0,1674 # ffffffffc02017f0 <etext+0x64>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <free_area>
ffffffffc020017a:	00001517          	auipc	a0,0x1
ffffffffc020017e:	69650513          	addi	a0,a0,1686 # ffffffffc0201810 <etext+0x84>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3e258593          	addi	a1,a1,994 # ffffffffc0206568 <end>
ffffffffc020018e:	00001517          	auipc	a0,0x1
ffffffffc0200192:	6a250513          	addi	a0,a0,1698 # ffffffffc0201830 <etext+0xa4>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	7cd58593          	addi	a1,a1,1997 # ffffffffc0206967 <end+0x3ff>
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
ffffffffc02001c0:	69450513          	addi	a0,a0,1684 # ffffffffc0201850 <etext+0xc4>
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
ffffffffc02001ce:	6b660613          	addi	a2,a2,1718 # ffffffffc0201880 <etext+0xf4>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	6c250513          	addi	a0,a0,1730 # ffffffffc0201898 <etext+0x10c>
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
ffffffffc02001ea:	6ca60613          	addi	a2,a2,1738 # ffffffffc02018b0 <etext+0x124>
ffffffffc02001ee:	00001597          	auipc	a1,0x1
ffffffffc02001f2:	6e258593          	addi	a1,a1,1762 # ffffffffc02018d0 <etext+0x144>
ffffffffc02001f6:	00001517          	auipc	a0,0x1
ffffffffc02001fa:	6e250513          	addi	a0,a0,1762 # ffffffffc02018d8 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00001617          	auipc	a2,0x1
ffffffffc0200208:	6e460613          	addi	a2,a2,1764 # ffffffffc02018e8 <etext+0x15c>
ffffffffc020020c:	00001597          	auipc	a1,0x1
ffffffffc0200210:	70458593          	addi	a1,a1,1796 # ffffffffc0201910 <etext+0x184>
ffffffffc0200214:	00001517          	auipc	a0,0x1
ffffffffc0200218:	6c450513          	addi	a0,a0,1732 # ffffffffc02018d8 <etext+0x14c>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00001617          	auipc	a2,0x1
ffffffffc0200224:	70060613          	addi	a2,a2,1792 # ffffffffc0201920 <etext+0x194>
ffffffffc0200228:	00001597          	auipc	a1,0x1
ffffffffc020022c:	71858593          	addi	a1,a1,1816 # ffffffffc0201940 <etext+0x1b4>
ffffffffc0200230:	00001517          	auipc	a0,0x1
ffffffffc0200234:	6a850513          	addi	a0,a0,1704 # ffffffffc02018d8 <etext+0x14c>
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
ffffffffc020026e:	6e650513          	addi	a0,a0,1766 # ffffffffc0201950 <etext+0x1c4>
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
ffffffffc0200290:	6ec50513          	addi	a0,a0,1772 # ffffffffc0201978 <etext+0x1ec>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00001c17          	auipc	s8,0x1
ffffffffc02002a6:	746c0c13          	addi	s8,s8,1862 # ffffffffc02019e8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00001917          	auipc	s2,0x1
ffffffffc02002ae:	6f690913          	addi	s2,s2,1782 # ffffffffc02019a0 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00001497          	auipc	s1,0x1
ffffffffc02002b6:	6f648493          	addi	s1,s1,1782 # ffffffffc02019a8 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00001b17          	auipc	s6,0x1
ffffffffc02002c0:	6f4b0b13          	addi	s6,s6,1780 # ffffffffc02019b0 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002c4:	00001a17          	auipc	s4,0x1
ffffffffc02002c8:	60ca0a13          	addi	s4,s4,1548 # ffffffffc02018d0 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	356010ef          	jal	ra,ffffffffc0201626 <readline>
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
ffffffffc02002ea:	702d0d13          	addi	s10,s10,1794 # ffffffffc02019e8 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	452010ef          	jal	ra,ffffffffc0201746 <strcmp>
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
ffffffffc0200308:	43e010ef          	jal	ra,ffffffffc0201746 <strcmp>
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
ffffffffc0200346:	41e010ef          	jal	ra,ffffffffc0201764 <strchr>
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
ffffffffc0200384:	3e0010ef          	jal	ra,ffffffffc0201764 <strchr>
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
ffffffffc02003a2:	63250513          	addi	a0,a0,1586 # ffffffffc02019d0 <etext+0x244>
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
ffffffffc02003de:	65650513          	addi	a0,a0,1622 # ffffffffc0201a30 <commands+0x48>
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
ffffffffc02003f4:	48850513          	addi	a0,a0,1160 # ffffffffc0201878 <etext+0xec>
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
ffffffffc0200420:	2d4010ef          	jal	ra,ffffffffc02016f4 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00001517          	auipc	a0,0x1
ffffffffc0200432:	62250513          	addi	a0,a0,1570 # ffffffffc0201a50 <commands+0x68>
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
ffffffffc0200446:	2ae0106f          	j	ffffffffc02016f4 <sbi_set_timer>

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
ffffffffc0200450:	28a0106f          	j	ffffffffc02016da <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	2ba0106f          	j	ffffffffc020170e <sbi_console_getchar>

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
ffffffffc0200482:	5f250513          	addi	a0,a0,1522 # ffffffffc0201a70 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00001517          	auipc	a0,0x1
ffffffffc0200492:	5fa50513          	addi	a0,a0,1530 # ffffffffc0201a88 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00001517          	auipc	a0,0x1
ffffffffc02004a0:	60450513          	addi	a0,a0,1540 # ffffffffc0201aa0 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00001517          	auipc	a0,0x1
ffffffffc02004ae:	60e50513          	addi	a0,a0,1550 # ffffffffc0201ab8 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00001517          	auipc	a0,0x1
ffffffffc02004bc:	61850513          	addi	a0,a0,1560 # ffffffffc0201ad0 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00001517          	auipc	a0,0x1
ffffffffc02004ca:	62250513          	addi	a0,a0,1570 # ffffffffc0201ae8 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00001517          	auipc	a0,0x1
ffffffffc02004d8:	62c50513          	addi	a0,a0,1580 # ffffffffc0201b00 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00001517          	auipc	a0,0x1
ffffffffc02004e6:	63650513          	addi	a0,a0,1590 # ffffffffc0201b18 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00001517          	auipc	a0,0x1
ffffffffc02004f4:	64050513          	addi	a0,a0,1600 # ffffffffc0201b30 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00001517          	auipc	a0,0x1
ffffffffc0200502:	64a50513          	addi	a0,a0,1610 # ffffffffc0201b48 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00001517          	auipc	a0,0x1
ffffffffc0200510:	65450513          	addi	a0,a0,1620 # ffffffffc0201b60 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	65e50513          	addi	a0,a0,1630 # ffffffffc0201b78 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	66850513          	addi	a0,a0,1640 # ffffffffc0201b90 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00001517          	auipc	a0,0x1
ffffffffc020053a:	67250513          	addi	a0,a0,1650 # ffffffffc0201ba8 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00001517          	auipc	a0,0x1
ffffffffc0200548:	67c50513          	addi	a0,a0,1660 # ffffffffc0201bc0 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00001517          	auipc	a0,0x1
ffffffffc0200556:	68650513          	addi	a0,a0,1670 # ffffffffc0201bd8 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00001517          	auipc	a0,0x1
ffffffffc0200564:	69050513          	addi	a0,a0,1680 # ffffffffc0201bf0 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00001517          	auipc	a0,0x1
ffffffffc0200572:	69a50513          	addi	a0,a0,1690 # ffffffffc0201c08 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00001517          	auipc	a0,0x1
ffffffffc0200580:	6a450513          	addi	a0,a0,1700 # ffffffffc0201c20 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00001517          	auipc	a0,0x1
ffffffffc020058e:	6ae50513          	addi	a0,a0,1710 # ffffffffc0201c38 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	6b850513          	addi	a0,a0,1720 # ffffffffc0201c50 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00001517          	auipc	a0,0x1
ffffffffc02005aa:	6c250513          	addi	a0,a0,1730 # ffffffffc0201c68 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	6cc50513          	addi	a0,a0,1740 # ffffffffc0201c80 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	6d650513          	addi	a0,a0,1750 # ffffffffc0201c98 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00001517          	auipc	a0,0x1
ffffffffc02005d4:	6e050513          	addi	a0,a0,1760 # ffffffffc0201cb0 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	6ea50513          	addi	a0,a0,1770 # ffffffffc0201cc8 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	6f450513          	addi	a0,a0,1780 # ffffffffc0201ce0 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00001517          	auipc	a0,0x1
ffffffffc02005fe:	6fe50513          	addi	a0,a0,1790 # ffffffffc0201cf8 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	70850513          	addi	a0,a0,1800 # ffffffffc0201d10 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00001517          	auipc	a0,0x1
ffffffffc020061a:	71250513          	addi	a0,a0,1810 # ffffffffc0201d28 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	71c50513          	addi	a0,a0,1820 # ffffffffc0201d40 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00001517          	auipc	a0,0x1
ffffffffc020063a:	72250513          	addi	a0,a0,1826 # ffffffffc0201d58 <commands+0x370>
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
ffffffffc020064e:	72650513          	addi	a0,a0,1830 # ffffffffc0201d70 <commands+0x388>
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
ffffffffc0200666:	72650513          	addi	a0,a0,1830 # ffffffffc0201d88 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00001517          	auipc	a0,0x1
ffffffffc0200676:	72e50513          	addi	a0,a0,1838 # ffffffffc0201da0 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00001517          	auipc	a0,0x1
ffffffffc0200686:	73650513          	addi	a0,a0,1846 # ffffffffc0201db8 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00001517          	auipc	a0,0x1
ffffffffc020069a:	73a50513          	addi	a0,a0,1850 # ffffffffc0201dd0 <commands+0x3e8>
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
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	80070713          	addi	a4,a4,-2048 # ffffffffc0201eb0 <commands+0x4c8>
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
ffffffffc02006c6:	78650513          	addi	a0,a0,1926 # ffffffffc0201e48 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	75c50513          	addi	a0,a0,1884 # ffffffffc0201e28 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00001517          	auipc	a0,0x1
ffffffffc02006da:	71250513          	addi	a0,a0,1810 # ffffffffc0201de8 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00001517          	auipc	a0,0x1
ffffffffc02006e4:	78850513          	addi	a0,a0,1928 # ffffffffc0201e68 <commands+0x480>
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
ffffffffc0200714:	78050513          	addi	a0,a0,1920 # ffffffffc0201e90 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201e08 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	75450513          	addi	a0,a0,1876 # ffffffffc0201e80 <commands+0x498>
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

ffffffffc0200802 <pmm_init>:

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    //pmm_manager = &best_fit_pmm_manager; // 修改此处：测试 Best-Fit 算法
    //pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
    pmm_manager = &slub_pmm_manager; // 修改此处：测试 slub 算法
ffffffffc0200802:	00002797          	auipc	a5,0x2
ffffffffc0200806:	a6678793          	addi	a5,a5,-1434 # ffffffffc0202268 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020080a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020080c:	1101                	addi	sp,sp,-32
ffffffffc020080e:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200810:	00001517          	auipc	a0,0x1
ffffffffc0200814:	6d050513          	addi	a0,a0,1744 # ffffffffc0201ee0 <commands+0x4f8>
    pmm_manager = &slub_pmm_manager; // 修改此处：测试 slub 算法
ffffffffc0200818:	00006497          	auipc	s1,0x6
ffffffffc020081c:	d2048493          	addi	s1,s1,-736 # ffffffffc0206538 <pmm_manager>
void pmm_init(void) {
ffffffffc0200820:	ec06                	sd	ra,24(sp)
ffffffffc0200822:	e822                	sd	s0,16(sp)
    pmm_manager = &slub_pmm_manager; // 修改此处：测试 slub 算法
ffffffffc0200824:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200826:	88dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc020082a:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020082c:	00006417          	auipc	s0,0x6
ffffffffc0200830:	d2440413          	addi	s0,s0,-732 # ffffffffc0206550 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200834:	679c                	ld	a5,8(a5)
ffffffffc0200836:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200838:	57f5                	li	a5,-3
ffffffffc020083a:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020083c:	00001517          	auipc	a0,0x1
ffffffffc0200840:	6bc50513          	addi	a0,a0,1724 # ffffffffc0201ef8 <commands+0x510>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200844:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0200846:	86dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020084a:	46c5                	li	a3,17
ffffffffc020084c:	06ee                	slli	a3,a3,0x1b
ffffffffc020084e:	40100613          	li	a2,1025
ffffffffc0200852:	16fd                	addi	a3,a3,-1
ffffffffc0200854:	07e005b7          	lui	a1,0x7e00
ffffffffc0200858:	0656                	slli	a2,a2,0x15
ffffffffc020085a:	00001517          	auipc	a0,0x1
ffffffffc020085e:	6b650513          	addi	a0,a0,1718 # ffffffffc0201f10 <commands+0x528>
ffffffffc0200862:	851ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200866:	777d                	lui	a4,0xfffff
ffffffffc0200868:	00007797          	auipc	a5,0x7
ffffffffc020086c:	cff78793          	addi	a5,a5,-769 # ffffffffc0207567 <end+0xfff>
ffffffffc0200870:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0200872:	00006517          	auipc	a0,0x6
ffffffffc0200876:	cb650513          	addi	a0,a0,-842 # ffffffffc0206528 <npage>
ffffffffc020087a:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020087e:	00006597          	auipc	a1,0x6
ffffffffc0200882:	cb258593          	addi	a1,a1,-846 # ffffffffc0206530 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200886:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200888:	e19c                	sd	a5,0(a1)
ffffffffc020088a:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020088c:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020088e:	4885                	li	a7,1
ffffffffc0200890:	fff80837          	lui	a6,0xfff80
ffffffffc0200894:	a011                	j	ffffffffc0200898 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0200896:	619c                	ld	a5,0(a1)
ffffffffc0200898:	97b6                	add	a5,a5,a3
ffffffffc020089a:	07a1                	addi	a5,a5,8
ffffffffc020089c:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02008a0:	611c                	ld	a5,0(a0)
ffffffffc02008a2:	0705                	addi	a4,a4,1
ffffffffc02008a4:	02868693          	addi	a3,a3,40
ffffffffc02008a8:	01078633          	add	a2,a5,a6
ffffffffc02008ac:	fec765e3          	bltu	a4,a2,ffffffffc0200896 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02008b0:	6190                	ld	a2,0(a1)
ffffffffc02008b2:	00279713          	slli	a4,a5,0x2
ffffffffc02008b6:	973e                	add	a4,a4,a5
ffffffffc02008b8:	fec006b7          	lui	a3,0xfec00
ffffffffc02008bc:	070e                	slli	a4,a4,0x3
ffffffffc02008be:	96b2                	add	a3,a3,a2
ffffffffc02008c0:	96ba                	add	a3,a3,a4
ffffffffc02008c2:	c0200737          	lui	a4,0xc0200
ffffffffc02008c6:	08e6ef63          	bltu	a3,a4,ffffffffc0200964 <pmm_init+0x162>
ffffffffc02008ca:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02008cc:	45c5                	li	a1,17
ffffffffc02008ce:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02008d0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02008d2:	04b6e863          	bltu	a3,a1,ffffffffc0200922 <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02008d6:	609c                	ld	a5,0(s1)
ffffffffc02008d8:	7b9c                	ld	a5,48(a5)
ffffffffc02008da:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02008dc:	00001517          	auipc	a0,0x1
ffffffffc02008e0:	6cc50513          	addi	a0,a0,1740 # ffffffffc0201fa8 <commands+0x5c0>
ffffffffc02008e4:	fceff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02008e8:	00004597          	auipc	a1,0x4
ffffffffc02008ec:	71858593          	addi	a1,a1,1816 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02008f0:	00006797          	auipc	a5,0x6
ffffffffc02008f4:	c4b7bc23          	sd	a1,-936(a5) # ffffffffc0206548 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02008f8:	c02007b7          	lui	a5,0xc0200
ffffffffc02008fc:	08f5e063          	bltu	a1,a5,ffffffffc020097c <pmm_init+0x17a>
ffffffffc0200900:	6010                	ld	a2,0(s0)
}
ffffffffc0200902:	6442                	ld	s0,16(sp)
ffffffffc0200904:	60e2                	ld	ra,24(sp)
ffffffffc0200906:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200908:	40c58633          	sub	a2,a1,a2
ffffffffc020090c:	00006797          	auipc	a5,0x6
ffffffffc0200910:	c2c7ba23          	sd	a2,-972(a5) # ffffffffc0206540 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200914:	00001517          	auipc	a0,0x1
ffffffffc0200918:	6b450513          	addi	a0,a0,1716 # ffffffffc0201fc8 <commands+0x5e0>
}
ffffffffc020091c:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020091e:	f94ff06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200922:	6705                	lui	a4,0x1
ffffffffc0200924:	177d                	addi	a4,a4,-1
ffffffffc0200926:	96ba                	add	a3,a3,a4
ffffffffc0200928:	777d                	lui	a4,0xfffff
ffffffffc020092a:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020092c:	00c6d513          	srli	a0,a3,0xc
ffffffffc0200930:	00f57e63          	bgeu	a0,a5,ffffffffc020094c <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc0200934:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200936:	982a                	add	a6,a6,a0
ffffffffc0200938:	00281513          	slli	a0,a6,0x2
ffffffffc020093c:	9542                	add	a0,a0,a6
ffffffffc020093e:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200940:	8d95                	sub	a1,a1,a3
ffffffffc0200942:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0200944:	81b1                	srli	a1,a1,0xc
ffffffffc0200946:	9532                	add	a0,a0,a2
ffffffffc0200948:	9782                	jalr	a5
}
ffffffffc020094a:	b771                	j	ffffffffc02008d6 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc020094c:	00001617          	auipc	a2,0x1
ffffffffc0200950:	62c60613          	addi	a2,a2,1580 # ffffffffc0201f78 <commands+0x590>
ffffffffc0200954:	06b00593          	li	a1,107
ffffffffc0200958:	00001517          	auipc	a0,0x1
ffffffffc020095c:	64050513          	addi	a0,a0,1600 # ffffffffc0201f98 <commands+0x5b0>
ffffffffc0200960:	a4dff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200964:	00001617          	auipc	a2,0x1
ffffffffc0200968:	5dc60613          	addi	a2,a2,1500 # ffffffffc0201f40 <commands+0x558>
ffffffffc020096c:	07200593          	li	a1,114
ffffffffc0200970:	00001517          	auipc	a0,0x1
ffffffffc0200974:	5f850513          	addi	a0,a0,1528 # ffffffffc0201f68 <commands+0x580>
ffffffffc0200978:	a35ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020097c:	86ae                	mv	a3,a1
ffffffffc020097e:	00001617          	auipc	a2,0x1
ffffffffc0200982:	5c260613          	addi	a2,a2,1474 # ffffffffc0201f40 <commands+0x558>
ffffffffc0200986:	08d00593          	li	a1,141
ffffffffc020098a:	00001517          	auipc	a0,0x1
ffffffffc020098e:	5de50513          	addi	a0,a0,1502 # ffffffffc0201f68 <commands+0x580>
ffffffffc0200992:	a1bff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200996 <slub_init>:
// 小块内存链表头指针
static struct SlubBlock *slub_small_block_list = NULL;

static void slub_init(void)
{
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200996:	00005797          	auipc	a5,0x5
ffffffffc020099a:	67a78793          	addi	a5,a5,1658 # ffffffffc0206010 <free_area>
ffffffffc020099e:	00005717          	auipc	a4,0x5
ffffffffc02009a2:	77a70713          	addi	a4,a4,1914 # ffffffffc0206118 <buf>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02009a6:	e79c                	sd	a5,8(a5)
ffffffffc02009a8:	e39c                	sd	a5,0(a5)
    {
        list_init(&free_area[i].free_list); // 初始化每个阶的空闲列表
        free_area[i].nr_free = 0;          // 初始化每个阶的空闲页面计数
ffffffffc02009aa:	0007a823          	sw	zero,16(a5)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc02009ae:	07e1                	addi	a5,a5,24
ffffffffc02009b0:	fee79be3          	bne	a5,a4,ffffffffc02009a6 <slub_init+0x10>
    }
}
ffffffffc02009b4:	8082                	ret

ffffffffc02009b6 <merge_page>:
    }
}

static void merge_page(size_t order, struct Page *base)
{
    if (order >= MAX_ORDER)
ffffffffc02009b6:	47a9                	li	a5,10
ffffffffc02009b8:	06a7e763          	bltu	a5,a0,ffffffffc0200a26 <merge_page+0x70>
ffffffffc02009bc:	00151793          	slli	a5,a0,0x1
ffffffffc02009c0:	953e                	add	a0,a0,a5
ffffffffc02009c2:	050e                	slli	a0,a0,0x3
ffffffffc02009c4:	00005797          	auipc	a5,0x5
ffffffffc02009c8:	64c78793          	addi	a5,a5,1612 # ffffffffc0206010 <free_area>
ffffffffc02009cc:	97aa                	add	a5,a5,a0
ffffffffc02009ce:	00005317          	auipc	t1,0x5
ffffffffc02009d2:	74a30313          	addi	t1,t1,1866 # ffffffffc0206118 <buf>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02009d6:	5e75                	li	t3,-3
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02009d8:	6d94                	ld	a3,24(a1)
        return; // 超过最大阶数则返回

    list_entry_t *le = list_prev(&(base->page_link));
    if (le!= &(free_area[order].free_list))
ffffffffc02009da:	01878513          	addi	a0,a5,24
    {
        struct Page *prev_page = le2page(le, page_link);
ffffffffc02009de:	fe868813          	addi	a6,a3,-24 # fffffffffebfffe8 <end+0x3e9f9a80>
    if (le!= &(free_area[order].free_list))
ffffffffc02009e2:	00f68e63          	beq	a3,a5,ffffffffc02009fe <merge_page+0x48>
        if (prev_page + prev_page->property == base)
ffffffffc02009e6:	ff86a883          	lw	a7,-8(a3)
ffffffffc02009ea:	02089613          	slli	a2,a7,0x20
ffffffffc02009ee:	9201                	srli	a2,a2,0x20
ffffffffc02009f0:	00261713          	slli	a4,a2,0x2
ffffffffc02009f4:	9732                	add	a4,a4,a2
ffffffffc02009f6:	070e                	slli	a4,a4,0x3
ffffffffc02009f8:	9742                	add	a4,a4,a6
ffffffffc02009fa:	02e58763          	beq	a1,a4,ffffffffc0200a28 <merge_page+0x72>
    return listelm->next;
ffffffffc02009fe:	7190                	ld	a2,32(a1)
    }

    le = list_next(&(base->page_link));
    if (le!= &(free_area[order].free_list))
    {
        struct Page *next_page = le2page(le, page_link);
ffffffffc0200a00:	fe860813          	addi	a6,a2,-24
    if (le!= &(free_area[order].free_list))
ffffffffc0200a04:	00f60e63          	beq	a2,a5,ffffffffc0200a20 <merge_page+0x6a>
        if (base + base->property == next_page)
ffffffffc0200a08:	0105a883          	lw	a7,16(a1)
ffffffffc0200a0c:	02089693          	slli	a3,a7,0x20
ffffffffc0200a10:	9281                	srli	a3,a3,0x20
ffffffffc0200a12:	00269713          	slli	a4,a3,0x2
ffffffffc0200a16:	9736                	add	a4,a4,a3
ffffffffc0200a18:	070e                	slli	a4,a4,0x3
ffffffffc0200a1a:	972e                	add	a4,a4,a1
ffffffffc0200a1c:	05070563          	beq	a4,a6,ffffffffc0200a66 <merge_page+0xb0>
    if (order >= MAX_ORDER)
ffffffffc0200a20:	87aa                	mv	a5,a0
ffffffffc0200a22:	faa31be3          	bne	t1,a0,ffffffffc02009d8 <merge_page+0x22>
            free_area[order + 1].nr_free++; // 更新空闲页面计数
        }
    }

    merge_page(order + 1, base); // 递归合并相邻页面
}
ffffffffc0200a26:	8082                	ret
            prev_page->property += base->property; // 合并相邻的页面
ffffffffc0200a28:	4998                	lw	a4,16(a1)
ffffffffc0200a2a:	011708bb          	addw	a7,a4,a7
ffffffffc0200a2e:	ff16ac23          	sw	a7,-8(a3)
ffffffffc0200a32:	00858713          	addi	a4,a1,8
ffffffffc0200a36:	61c7302f          	amoand.d	zero,t3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a3a:	7190                	ld	a2,32(a1)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc0200a3c:	5798                	lw	a4,40(a5)
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
    elm->next = next;
    elm->prev = prev;
ffffffffc0200a3e:	01878513          	addi	a0,a5,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200a42:	e690                	sd	a2,8(a3)
    next->prev = prev;
ffffffffc0200a44:	e214                	sd	a3,0(a2)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a46:	0006b883          	ld	a7,0(a3)
ffffffffc0200a4a:	6690                	ld	a2,8(a3)
ffffffffc0200a4c:	2705                	addiw	a4,a4,1
            base = prev_page; // 更新基地址
ffffffffc0200a4e:	85c2                	mv	a1,a6
    prev->next = next;
ffffffffc0200a50:	00c8b423          	sd	a2,8(a7)
    next->prev = prev;
ffffffffc0200a54:	01163023          	sd	a7,0(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a58:	7390                	ld	a2,32(a5)
    prev->next = next->prev = elm;
ffffffffc0200a5a:	e214                	sd	a3,0(a2)
ffffffffc0200a5c:	f394                	sd	a3,32(a5)
    elm->next = next;
ffffffffc0200a5e:	e690                	sd	a2,8(a3)
    elm->prev = prev;
ffffffffc0200a60:	e288                	sd	a0,0(a3)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc0200a62:	d798                	sw	a4,40(a5)
ffffffffc0200a64:	bf71                	j	ffffffffc0200a00 <merge_page+0x4a>
            base->property += next_page->property; // 合并相邻的页面
ffffffffc0200a66:	ff862703          	lw	a4,-8(a2)
ffffffffc0200a6a:	011708bb          	addw	a7,a4,a7
ffffffffc0200a6e:	0115a823          	sw	a7,16(a1)
ffffffffc0200a72:	ff060713          	addi	a4,a2,-16
ffffffffc0200a76:	61c7302f          	amoand.d	zero,t3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a7a:	00063803          	ld	a6,0(a2)
ffffffffc0200a7e:	6610                	ld	a2,8(a2)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc0200a80:	5794                	lw	a3,40(a5)
            list_add(&(free_area[order + 1].free_list), &(base->page_link)); // 将合并后的页面加入空闲列表
ffffffffc0200a82:	01858713          	addi	a4,a1,24
    prev->next = next;
ffffffffc0200a86:	00c83423          	sd	a2,8(a6) # fffffffffff80008 <end+0x3fd79aa0>
    next->prev = prev;
ffffffffc0200a8a:	01063023          	sd	a6,0(a2)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a8e:	0185b803          	ld	a6,24(a1)
ffffffffc0200a92:	7190                	ld	a2,32(a1)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc0200a94:	2685                	addiw	a3,a3,1
    prev->next = next;
ffffffffc0200a96:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200a9a:	01063023          	sd	a6,0(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a9e:	7390                	ld	a2,32(a5)
    prev->next = next->prev = elm;
ffffffffc0200aa0:	e218                	sd	a4,0(a2)
ffffffffc0200aa2:	f398                	sd	a4,32(a5)
    elm->next = next;
ffffffffc0200aa4:	f190                	sd	a2,32(a1)
    elm->prev = prev;
ffffffffc0200aa6:	ed88                	sd	a0,24(a1)
ffffffffc0200aa8:	d794                	sw	a3,40(a5)
ffffffffc0200aaa:	bf9d                	j	ffffffffc0200a20 <merge_page+0x6a>

ffffffffc0200aac <slub_nr_free_pages>:
}

static size_t slub_nr_free_pages(void)
{
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200aac:	00005697          	auipc	a3,0x5
ffffffffc0200ab0:	57468693          	addi	a3,a3,1396 # ffffffffc0206020 <free_area+0x10>
ffffffffc0200ab4:	4781                	li	a5,0
    size_t total = 0;
ffffffffc0200ab6:	4501                	li	a0,0
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ab8:	462d                	li	a2,11
    {
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200aba:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200abe:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ac0:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ac4:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ac6:	953a                	add	a0,a0,a4
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ac8:	fec799e3          	bne	a5,a2,ffffffffc0200aba <slub_nr_free_pages+0xe>
    }
    return total; // 返回总的空闲页面数
}
ffffffffc0200acc:	8082                	ret

ffffffffc0200ace <slub_free_small>:
}

// 释放小块内存
static void slub_free_small(void *ptr, size_t size)
{
    if (ptr == NULL)
ffffffffc0200ace:	cd15                	beqz	a0,ffffffffc0200b0a <slub_free_small+0x3c>
    {
        return;
    }
    struct SlubBlock *block = (struct SlubBlock *)ptr - 1;
    block->size += size;
ffffffffc0200ad0:	fe853683          	ld	a3,-24(a0)
    struct SlubBlock *temp = slub_small_block_list;
ffffffffc0200ad4:	00006717          	auipc	a4,0x6
ffffffffc0200ad8:	a8470713          	addi	a4,a4,-1404 # ffffffffc0206558 <slub_small_block_list>
ffffffffc0200adc:	631c                	ld	a5,0(a4)
    block->size += size;
ffffffffc0200ade:	95b6                	add	a1,a1,a3
ffffffffc0200ae0:	feb53423          	sd	a1,-24(a0)
    struct SlubBlock *block = (struct SlubBlock *)ptr - 1;
ffffffffc0200ae4:	fe850613          	addi	a2,a0,-24
    if (temp == NULL || temp->size > block->size)
ffffffffc0200ae8:	c781                	beqz	a5,ffffffffc0200af0 <slub_free_small+0x22>
ffffffffc0200aea:	6394                	ld	a3,0(a5)
ffffffffc0200aec:	00d5f963          	bgeu	a1,a3,ffffffffc0200afe <slub_free_small+0x30>
    {
        block->next = temp;
ffffffffc0200af0:	fef53c23          	sd	a5,-8(a0)
        slub_small_block_list = block;
ffffffffc0200af4:	e310                	sd	a2,0(a4)
        return;
ffffffffc0200af6:	8082                	ret
    }
    while (temp->next!= NULL && temp->next->size < block->size)
ffffffffc0200af8:	6398                	ld	a4,0(a5)
ffffffffc0200afa:	00b77563          	bgeu	a4,a1,ffffffffc0200b04 <slub_free_small+0x36>
ffffffffc0200afe:	86be                	mv	a3,a5
ffffffffc0200b00:	6b9c                	ld	a5,16(a5)
ffffffffc0200b02:	fbfd                	bnez	a5,ffffffffc0200af8 <slub_free_small+0x2a>
    {
        temp = temp->next;
    }
    block->next = temp->next;
ffffffffc0200b04:	fef53c23          	sd	a5,-8(a0)
    temp->next = block;
ffffffffc0200b08:	ea90                	sd	a2,16(a3)
}
ffffffffc0200b0a:	8082                	ret

ffffffffc0200b0c <slub_free>:
}

// 释放内存
static void slub_free(struct Page *ptr, size_t size)
{
    if (size >= 1 << (MAX_ORDER - 1))
ffffffffc0200b0c:	3ff00713          	li	a4,1023
{
ffffffffc0200b10:	86aa                	mv	a3,a0
    if (size >= 1 << (MAX_ORDER - 1))
ffffffffc0200b12:	08b77563          	bgeu	a4,a1,ffffffffc0200b9c <slub_free+0x90>
    {
        buddy_free_pages(ptr, size >> (MAX_ORDER - 1));
ffffffffc0200b16:	00a5d513          	srli	a0,a1,0xa
    for (; p < base + n; p++)
ffffffffc0200b1a:	00251713          	slli	a4,a0,0x2
ffffffffc0200b1e:	972a                	add	a4,a4,a0
ffffffffc0200b20:	070e                	slli	a4,a4,0x3
ffffffffc0200b22:	9736                	add	a4,a4,a3
ffffffffc0200b24:	87b6                	mv	a5,a3
ffffffffc0200b26:	00e6fa63          	bgeu	a3,a4,ffffffffc0200b3a <slub_free+0x2e>
        p->flags = 0; // 清除标志
ffffffffc0200b2a:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200b2e:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++)
ffffffffc0200b32:	02878793          	addi	a5,a5,40
ffffffffc0200b36:	fee7eae3          	bltu	a5,a4,ffffffffc0200b2a <slub_free+0x1e>
    base->property = n; // 设置释放页面的属性
ffffffffc0200b3a:	ca88                	sw	a0,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200b3c:	4789                	li	a5,2
ffffffffc0200b3e:	00868713          	addi	a4,a3,8
ffffffffc0200b42:	40f7302f          	amoor.d	zero,a5,(a4)
    while (n > 1)
ffffffffc0200b46:	4605                	li	a2,1
    size_t order = 0;
ffffffffc0200b48:	4781                	li	a5,0
    while (n > 1)
ffffffffc0200b4a:	4705                	li	a4,1
ffffffffc0200b4c:	04c50963          	beq	a0,a2,ffffffffc0200b9e <slub_free+0x92>
        n >>= 1; // 计算阶数
ffffffffc0200b50:	8105                	srli	a0,a0,0x1
        order++;
ffffffffc0200b52:	863e                	mv	a2,a5
ffffffffc0200b54:	0785                	addi	a5,a5,1
    while (n > 1)
ffffffffc0200b56:	fee51de3          	bne	a0,a4,ffffffffc0200b50 <slub_free+0x44>
    order++; // 增加阶数
ffffffffc0200b5a:	00260513          	addi	a0,a2,2
ffffffffc0200b5e:	00151793          	slli	a5,a0,0x1
ffffffffc0200b62:	00a78733          	add	a4,a5,a0
ffffffffc0200b66:	00371593          	slli	a1,a4,0x3
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200b6a:	97aa                	add	a5,a5,a0
ffffffffc0200b6c:	00005717          	auipc	a4,0x5
ffffffffc0200b70:	4a470713          	addi	a4,a4,1188 # ffffffffc0206010 <free_area>
ffffffffc0200b74:	078e                	slli	a5,a5,0x3
ffffffffc0200b76:	97ba                	add	a5,a5,a4
ffffffffc0200b78:	0007b803          	ld	a6,0(a5)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200b7c:	4b90                	lw	a2,16(a5)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0200b7e:	01868893          	addi	a7,a3,24
    prev->next = next->prev = elm;
ffffffffc0200b82:	0117b023          	sd	a7,0(a5)
ffffffffc0200b86:	01183423          	sd	a7,8(a6)
    list_entry_t *le = &(free_area[order].free_list);
ffffffffc0200b8a:	972e                	add	a4,a4,a1
    elm->next = next;
ffffffffc0200b8c:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0200b8e:	0106bc23          	sd	a6,24(a3)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200b92:	0016071b          	addiw	a4,a2,1
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200b96:	85b6                	mv	a1,a3
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200b98:	cb98                	sw	a4,16(a5)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200b9a:	bd31                	j	ffffffffc02009b6 <merge_page>
    }
    else
    {
        slub_free_small(ptr, size);
ffffffffc0200b9c:	bf0d                	j	ffffffffc0200ace <slub_free_small>
    while (n > 1)
ffffffffc0200b9e:	45e1                	li	a1,24
ffffffffc0200ba0:	4789                	li	a5,2
ffffffffc0200ba2:	b7e1                	j	ffffffffc0200b6a <slub_free+0x5e>

ffffffffc0200ba4 <buddy_alloc_pages>:
{
ffffffffc0200ba4:	00005817          	auipc	a6,0x5
ffffffffc0200ba8:	46c80813          	addi	a6,a6,1132 # ffffffffc0206010 <free_area>
    if (free_area[order].nr_free > 0)
ffffffffc0200bac:	01082f03          	lw	t5,16(a6)
{
ffffffffc0200bb0:	1141                	addi	sp,sp,-16
ffffffffc0200bb2:	e422                	sd	s0,8(sp)
    while ((1 << order) < n)
ffffffffc0200bb4:	4305                	li	t1,1
ffffffffc0200bb6:	4605                	li	a2,1
    if (order >= MAX_ORDER)
ffffffffc0200bb8:	48a9                	li	a7,10
    while (n < MAX_ORDER && free_area[n].nr_free == 0)
ffffffffc0200bba:	45ad                	li	a1,11
ffffffffc0200bbc:	4e09                	li	t3,2
    while ((1 << order) < n)
ffffffffc0200bbe:	0c650663          	beq	a0,t1,ffffffffc0200c8a <buddy_alloc_pages+0xe6>
    size_t order = 0;
ffffffffc0200bc2:	4701                	li	a4,0
        order++; // 计算所需的阶数
ffffffffc0200bc4:	87ba                	mv	a5,a4
ffffffffc0200bc6:	0705                	addi	a4,a4,1
    while ((1 << order) < n)
ffffffffc0200bc8:	00e616bb          	sllw	a3,a2,a4
ffffffffc0200bcc:	fea6ece3          	bltu	a3,a0,ffffffffc0200bc4 <buddy_alloc_pages+0x20>
    if (order >= MAX_ORDER)
ffffffffc0200bd0:	0ce8e163          	bltu	a7,a4,ffffffffc0200c92 <buddy_alloc_pages+0xee>
    if (free_area[order].nr_free > 0)
ffffffffc0200bd4:	00171e93          	slli	t4,a4,0x1
ffffffffc0200bd8:	00ee86b3          	add	a3,t4,a4
ffffffffc0200bdc:	068e                	slli	a3,a3,0x3
ffffffffc0200bde:	96c2                	add	a3,a3,a6
ffffffffc0200be0:	4a94                	lw	a3,16(a3)
ffffffffc0200be2:	eedd                	bnez	a3,ffffffffc0200ca0 <buddy_alloc_pages+0xfc>
        cut_page(order + 1); // 切割页面以获取所需大小
ffffffffc0200be4:	0789                	addi	a5,a5,2
    while (n < MAX_ORDER && free_area[n].nr_free == 0)
ffffffffc0200be6:	fcf8ece3          	bltu	a7,a5,ffffffffc0200bbe <buddy_alloc_pages+0x1a>
ffffffffc0200bea:	00179713          	slli	a4,a5,0x1
ffffffffc0200bee:	973e                	add	a4,a4,a5
ffffffffc0200bf0:	070e                	slli	a4,a4,0x3
ffffffffc0200bf2:	0741                	addi	a4,a4,16
ffffffffc0200bf4:	9742                	add	a4,a4,a6
ffffffffc0200bf6:	a021                	j	ffffffffc0200bfe <buddy_alloc_pages+0x5a>
        n++; // 查找下一个有空闲页面的阶
ffffffffc0200bf8:	0785                	addi	a5,a5,1
    while (n < MAX_ORDER && free_area[n].nr_free == 0)
ffffffffc0200bfa:	fcb782e3          	beq	a5,a1,ffffffffc0200bbe <buddy_alloc_pages+0x1a>
ffffffffc0200bfe:	4314                	lw	a3,0(a4)
ffffffffc0200c00:	0761                	addi	a4,a4,24
ffffffffc0200c02:	dafd                	beqz	a3,ffffffffc0200bf8 <buddy_alloc_pages+0x54>
    return listelm->next;
ffffffffc0200c04:	00179f13          	slli	t5,a5,0x1
ffffffffc0200c08:	9f3e                	add	t5,t5,a5
ffffffffc0200c0a:	0f0e                	slli	t5,t5,0x3
ffffffffc0200c0c:	9f42                	add	t5,t5,a6
ffffffffc0200c0e:	008f3e83          	ld	t4,8(t5)
    size_t i = n - 1; // 减小阶数
ffffffffc0200c12:	17fd                	addi	a5,a5,-1
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200c14:	00f6143b          	sllw	s0,a2,a5
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c18:	000eb383          	ld	t2,0(t4)
ffffffffc0200c1c:	008eb283          	ld	t0,8(t4)
ffffffffc0200c20:	00241713          	slli	a4,s0,0x2
ffffffffc0200c24:	9722                	add	a4,a4,s0
    prev->next = next;
ffffffffc0200c26:	0053b423          	sd	t0,8(t2)
ffffffffc0200c2a:	070e                	slli	a4,a4,0x3
    next->prev = prev;
ffffffffc0200c2c:	0072b023          	sd	t2,0(t0)
    free_area[n].nr_free--; // 更新空闲页面计数
ffffffffc0200c30:	36fd                	addiw	a3,a3,-1
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200c32:	1721                	addi	a4,a4,-24
    free_area[n].nr_free--; // 更新空闲页面计数
ffffffffc0200c34:	00df2823          	sw	a3,16(t5)
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200c38:	00ee86b3          	add	a3,t4,a4
    buddy_page->property = (1 << i); // 设置伙伴页的属性
ffffffffc0200c3c:	ca80                	sw	s0,16(a3)
    page->property = (1 << i); // 设置当前页的属性
ffffffffc0200c3e:	fe8eac23          	sw	s0,-8(t4)
ffffffffc0200c42:	00868713          	addi	a4,a3,8
ffffffffc0200c46:	41c7302f          	amoor.d	zero,t3,(a4)
    list_add(&(free_area[i].free_list), &(page->page_link)); // 将当前页加入到较小阶的空闲列表
ffffffffc0200c4a:	00179713          	slli	a4,a5,0x1
ffffffffc0200c4e:	97ba                	add	a5,a5,a4
ffffffffc0200c50:	078e                	slli	a5,a5,0x3
ffffffffc0200c52:	97c2                	add	a5,a5,a6
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c54:	0087bf03          	ld	t5,8(a5)
    free_area[i].nr_free += 2; // 更新空闲页面计数
ffffffffc0200c58:	4b98                	lw	a4,16(a5)
    list_add(&(buddy_page->page_link), &(free_area[i].free_list)); // 将伙伴页加入到空闲列表
ffffffffc0200c5a:	01868f93          	addi	t6,a3,24
    prev->next = next->prev = elm;
ffffffffc0200c5e:	01df3023          	sd	t4,0(t5)
ffffffffc0200c62:	01d7b423          	sd	t4,8(a5)
    elm->next = next;
ffffffffc0200c66:	01eeb423          	sd	t5,8(t4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c6a:	0206bf03          	ld	t5,32(a3)
    elm->prev = prev;
ffffffffc0200c6e:	00feb023          	sd	a5,0(t4)
    free_area[i].nr_free += 2; // 更新空闲页面计数
ffffffffc0200c72:	2709                	addiw	a4,a4,2
    prev->next = next->prev = elm;
ffffffffc0200c74:	00ff3023          	sd	a5,0(t5)
ffffffffc0200c78:	f29c                	sd	a5,32(a3)
ffffffffc0200c7a:	cb98                	sw	a4,16(a5)
    elm->next = next;
ffffffffc0200c7c:	01e7b423          	sd	t5,8(a5)
    elm->prev = prev;
ffffffffc0200c80:	01f7b023          	sd	t6,0(a5)
    if (free_area[order].nr_free > 0)
ffffffffc0200c84:	01082f03          	lw	t5,16(a6)
ffffffffc0200c88:	bf1d                	j	ffffffffc0200bbe <buddy_alloc_pages+0x1a>
ffffffffc0200c8a:	000f1863          	bnez	t5,ffffffffc0200c9a <buddy_alloc_pages+0xf6>
        cut_page(order + 1); // 切割页面以获取所需大小
ffffffffc0200c8e:	4785                	li	a5,1
ffffffffc0200c90:	bfa9                	j	ffffffffc0200bea <buddy_alloc_pages+0x46>
}
ffffffffc0200c92:	6422                	ld	s0,8(sp)
        return NULL; // 请求的页面数超过最大阶数
ffffffffc0200c94:	4501                	li	a0,0
}
ffffffffc0200c96:	0141                	addi	sp,sp,16
ffffffffc0200c98:	8082                	ret
    if (free_area[order].nr_free > 0)
ffffffffc0200c9a:	86fa                	mv	a3,t5
    size_t order = 0;
ffffffffc0200c9c:	4701                	li	a4,0
ffffffffc0200c9e:	4e81                	li	t4,0
    return listelm->next;
ffffffffc0200ca0:	00ee87b3          	add	a5,t4,a4
ffffffffc0200ca4:	078e                	slli	a5,a5,0x3
ffffffffc0200ca6:	983e                	add	a6,a6,a5
ffffffffc0200ca8:	00883783          	ld	a5,8(a6)
        free_area[order].nr_free--; // 更新空闲页面计数
ffffffffc0200cac:	36fd                	addiw	a3,a3,-1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cae:	6798                	ld	a4,8(a5)
ffffffffc0200cb0:	6390                	ld	a2,0(a5)
        struct Page *page = le2page(le, page_link); // 获取空闲页
ffffffffc0200cb2:	fe878513          	addi	a0,a5,-24
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200cb6:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200cb8:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200cba:	e310                	sd	a2,0(a4)
        free_area[order].nr_free--; // 更新空闲页面计数
ffffffffc0200cbc:	00d82823          	sw	a3,16(a6)
ffffffffc0200cc0:	5775                	li	a4,-3
ffffffffc0200cc2:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0200cc6:	6422                	ld	s0,8(sp)
ffffffffc0200cc8:	0141                	addi	sp,sp,16
ffffffffc0200cca:	8082                	ret

ffffffffc0200ccc <slub_alloc_small>:
    struct SlubBlock *temp = slub_small_block_list;
ffffffffc0200ccc:	00006617          	auipc	a2,0x6
ffffffffc0200cd0:	88c60613          	addi	a2,a2,-1908 # ffffffffc0206558 <slub_small_block_list>
ffffffffc0200cd4:	621c                	ld	a5,0(a2)
    while (temp!= NULL)
ffffffffc0200cd6:	cf89                	beqz	a5,ffffffffc0200cf0 <slub_alloc_small+0x24>
ffffffffc0200cd8:	c03516d3          	fcvt.lu.s	a3,fa0,rtz
ffffffffc0200cdc:	a011                	j	ffffffffc0200ce0 <slub_alloc_small+0x14>
ffffffffc0200cde:	cb89                	beqz	a5,ffffffffc0200cf0 <slub_alloc_small+0x24>
        if (temp->size >= total_size)
ffffffffc0200ce0:	6398                	ld	a4,0(a5)
ffffffffc0200ce2:	853e                	mv	a0,a5
            slub_small_block_list = temp->next;
ffffffffc0200ce4:	6b9c                	ld	a5,16(a5)
        if (temp->size >= total_size)
ffffffffc0200ce6:	fed76ce3          	bltu	a4,a3,ffffffffc0200cde <slub_alloc_small+0x12>
            slub_small_block_list = temp->next;
ffffffffc0200cea:	e21c                	sd	a5,0(a2)
            return (void *)(block + 1);
ffffffffc0200cec:	0561                	addi	a0,a0,24
}
ffffffffc0200cee:	8082                	ret
{
ffffffffc0200cf0:	1101                	addi	sp,sp,-32
    struct Page *page = buddy_alloc_pages(1); // 分配一个页
ffffffffc0200cf2:	4505                	li	a0,1
{
ffffffffc0200cf4:	ec06                	sd	ra,24(sp)
    struct Page *page = buddy_alloc_pages(1); // 分配一个页
ffffffffc0200cf6:	eafff0ef          	jal	ra,ffffffffc0200ba4 <buddy_alloc_pages>
    if (page == NULL)
ffffffffc0200cfa:	c909                	beqz	a0,ffffffffc0200d0c <slub_alloc_small+0x40>
    current_block->size = 0;                                    // 设置大小
ffffffffc0200cfc:	00053023          	sd	zero,0(a0)
    slub_free_small((void *)(current_block + 1), 1);
ffffffffc0200d00:	4585                	li	a1,1
ffffffffc0200d02:	0561                	addi	a0,a0,24
ffffffffc0200d04:	e42a                	sd	a0,8(sp)
ffffffffc0200d06:	dc9ff0ef          	jal	ra,ffffffffc0200ace <slub_free_small>
ffffffffc0200d0a:	6522                	ld	a0,8(sp)
}
ffffffffc0200d0c:	60e2                	ld	ra,24(sp)
ffffffffc0200d0e:	6105                	addi	sp,sp,32
ffffffffc0200d10:	8082                	ret

ffffffffc0200d12 <slub_alloc>:
    if (size >= (1 << MAX_ORDER))
ffffffffc0200d12:	7ff00793          	li	a5,2047
ffffffffc0200d16:	02a7e863          	bltu	a5,a0,ffffffffc0200d46 <slub_alloc+0x34>
    if (size >= 1 << (MAX_ORDER - 1))
ffffffffc0200d1a:	3ff00793          	li	a5,1023
ffffffffc0200d1e:	00a7ee63          	bltu	a5,a0,ffffffffc0200d3a <slub_alloc+0x28>
        void *small_block_ptr = slub_alloc_small(size);
ffffffffc0200d22:	d0257553          	fcvt.s.l	fa0,a0
{
ffffffffc0200d26:	1141                	addi	sp,sp,-16
ffffffffc0200d28:	e406                	sd	ra,8(sp)
        void *small_block_ptr = slub_alloc_small(size);
ffffffffc0200d2a:	fa3ff0ef          	jal	ra,ffffffffc0200ccc <slub_alloc_small>
        if (small_block_ptr)
ffffffffc0200d2e:	c901                	beqz	a0,ffffffffc0200d3e <slub_alloc+0x2c>
}
ffffffffc0200d30:	60a2                	ld	ra,8(sp)
            return block->page;
ffffffffc0200d32:	ff053503          	ld	a0,-16(a0)
}
ffffffffc0200d36:	0141                	addi	sp,sp,16
ffffffffc0200d38:	8082                	ret
        return buddy_alloc_pages(size >> (MAX_ORDER - 1));
ffffffffc0200d3a:	4505                	li	a0,1
ffffffffc0200d3c:	b5a5                	j	ffffffffc0200ba4 <buddy_alloc_pages>
}
ffffffffc0200d3e:	60a2                	ld	ra,8(sp)
        return NULL;
ffffffffc0200d40:	4501                	li	a0,0
}
ffffffffc0200d42:	0141                	addi	sp,sp,16
ffffffffc0200d44:	8082                	ret
        return NULL;
ffffffffc0200d46:	4501                	li	a0,0
}
ffffffffc0200d48:	8082                	ret

ffffffffc0200d4a <slub_init_memmap>:
{
ffffffffc0200d4a:	1141                	addi	sp,sp,-16
ffffffffc0200d4c:	e406                	sd	ra,8(sp)
    assert(n > 0); // 确保请求的页面数量大于 0
ffffffffc0200d4e:	c5dd                	beqz	a1,ffffffffc0200dfc <slub_init_memmap+0xb2>
    for (struct Page *p = base; p!= base + n; p++)
ffffffffc0200d50:	00259693          	slli	a3,a1,0x2
ffffffffc0200d54:	96ae                	add	a3,a3,a1
ffffffffc0200d56:	068e                	slli	a3,a3,0x3
ffffffffc0200d58:	96aa                	add	a3,a3,a0
ffffffffc0200d5a:	87aa                	mv	a5,a0
ffffffffc0200d5c:	00d50f63          	beq	a0,a3,ffffffffc0200d7a <slub_init_memmap+0x30>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d60:	6798                	ld	a4,8(a5)
        assert(PageReserved(p)); // 确保页面是保留的
ffffffffc0200d62:	8b05                	andi	a4,a4,1
ffffffffc0200d64:	cf25                	beqz	a4,ffffffffc0200ddc <slub_init_memmap+0x92>
        p->flags = p->property = 0; // 清除标志和属性
ffffffffc0200d66:	0007a823          	sw	zero,16(a5)
ffffffffc0200d6a:	0007b423          	sd	zero,8(a5)
ffffffffc0200d6e:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p!= base + n; p++)
ffffffffc0200d72:	02878793          	addi	a5,a5,40
ffffffffc0200d76:	fed795e3          	bne	a5,a3,ffffffffc0200d60 <slub_init_memmap+0x16>
    size_t order = MAX_ORDER - 1;
ffffffffc0200d7a:	4729                	li	a4,10
    size_t order_size = 1 << order; // 计算当前阶的大小
ffffffffc0200d7c:	40000793          	li	a5,1024
ffffffffc0200d80:	00005e17          	auipc	t3,0x5
ffffffffc0200d84:	290e0e13          	addi	t3,t3,656 # ffffffffc0206010 <free_area>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d88:	4309                	li	t1,2
        p->property = order_size;
ffffffffc0200d8a:	c91c                	sw	a5,16(a0)
ffffffffc0200d8c:	00850693          	addi	a3,a0,8
ffffffffc0200d90:	4066b02f          	amoor.d	zero,t1,(a3)
        free_area[order].nr_free++;
ffffffffc0200d94:	00171693          	slli	a3,a4,0x1
ffffffffc0200d98:	96ba                	add	a3,a3,a4
ffffffffc0200d9a:	068e                	slli	a3,a3,0x3
ffffffffc0200d9c:	96f2                	add	a3,a3,t3
ffffffffc0200d9e:	0106a803          	lw	a6,16(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200da2:	0086b883          	ld	a7,8(a3)
        list_add(&(free_area[order].free_list), &(p->page_link)); // 将页加入空闲列表
ffffffffc0200da6:	01850613          	addi	a2,a0,24
        free_area[order].nr_free++;
ffffffffc0200daa:	2805                	addiw	a6,a6,1
ffffffffc0200dac:	0106a823          	sw	a6,16(a3)
    prev->next = next->prev = elm;
ffffffffc0200db0:	00c8b023          	sd	a2,0(a7)
ffffffffc0200db4:	e690                	sd	a2,8(a3)
    elm->next = next;
ffffffffc0200db6:	03153023          	sd	a7,32(a0)
    elm->prev = prev;
ffffffffc0200dba:	ed14                	sd	a3,24(a0)
        origin_size -= order_size; // 减少剩余未处理的页面数量
ffffffffc0200dbc:	8d9d                	sub	a1,a1,a5
        while (order > 0 && origin_size < order_size)
ffffffffc0200dbe:	c711                	beqz	a4,ffffffffc0200dca <slub_init_memmap+0x80>
ffffffffc0200dc0:	00f5f563          	bgeu	a1,a5,ffffffffc0200dca <slub_init_memmap+0x80>
            order--;
ffffffffc0200dc4:	177d                	addi	a4,a4,-1
            order_size >>= 1;
ffffffffc0200dc6:	8385                	srli	a5,a5,0x1
        while (order > 0 && origin_size < order_size)
ffffffffc0200dc8:	ff65                	bnez	a4,ffffffffc0200dc0 <slub_init_memmap+0x76>
    for (struct Page *p = base; origin_size!= 0; p += order_size)
ffffffffc0200dca:	00279693          	slli	a3,a5,0x2
ffffffffc0200dce:	96be                	add	a3,a3,a5
ffffffffc0200dd0:	068e                	slli	a3,a3,0x3
ffffffffc0200dd2:	9536                	add	a0,a0,a3
ffffffffc0200dd4:	f9dd                	bnez	a1,ffffffffc0200d8a <slub_init_memmap+0x40>
}
ffffffffc0200dd6:	60a2                	ld	ra,8(sp)
ffffffffc0200dd8:	0141                	addi	sp,sp,16
ffffffffc0200dda:	8082                	ret
        assert(PageReserved(p)); // 确保页面是保留的
ffffffffc0200ddc:	00001697          	auipc	a3,0x1
ffffffffc0200de0:	26468693          	addi	a3,a3,612 # ffffffffc0202040 <commands+0x658>
ffffffffc0200de4:	00001617          	auipc	a2,0x1
ffffffffc0200de8:	22c60613          	addi	a2,a2,556 # ffffffffc0202010 <commands+0x628>
ffffffffc0200dec:	02500593          	li	a1,37
ffffffffc0200df0:	00001517          	auipc	a0,0x1
ffffffffc0200df4:	23850513          	addi	a0,a0,568 # ffffffffc0202028 <commands+0x640>
ffffffffc0200df8:	db4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0); // 确保请求的页面数量大于 0
ffffffffc0200dfc:	00001697          	auipc	a3,0x1
ffffffffc0200e00:	20c68693          	addi	a3,a3,524 # ffffffffc0202008 <commands+0x620>
ffffffffc0200e04:	00001617          	auipc	a2,0x1
ffffffffc0200e08:	20c60613          	addi	a2,a2,524 # ffffffffc0202010 <commands+0x628>
ffffffffc0200e0c:	02100593          	li	a1,33
ffffffffc0200e10:	00001517          	auipc	a0,0x1
ffffffffc0200e14:	21850513          	addi	a0,a0,536 # ffffffffc0202028 <commands+0x640>
ffffffffc0200e18:	d94ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200e1c <slub_check>:
    }
}

static void slub_check(void) {
ffffffffc0200e1c:	715d                	addi	sp,sp,-80
ffffffffc0200e1e:	e0a2                	sd	s0,64(sp)
ffffffffc0200e20:	00005417          	auipc	s0,0x5
ffffffffc0200e24:	1f040413          	addi	s0,s0,496 # ffffffffc0206010 <free_area>
ffffffffc0200e28:	e486                	sd	ra,72(sp)
ffffffffc0200e2a:	fc26                	sd	s1,56(sp)
ffffffffc0200e2c:	f84a                	sd	s2,48(sp)
ffffffffc0200e2e:	f44e                	sd	s3,40(sp)
ffffffffc0200e30:	f052                	sd	s4,32(sp)
ffffffffc0200e32:	ec56                	sd	s5,24(sp)
ffffffffc0200e34:	e85a                	sd	s6,16(sp)
ffffffffc0200e36:	e45e                	sd	s7,8(sp)
ffffffffc0200e38:	e062                	sd	s8,0(sp)
ffffffffc0200e3a:	00005517          	auipc	a0,0x5
ffffffffc0200e3e:	2de50513          	addi	a0,a0,734 # ffffffffc0206118 <buf>
ffffffffc0200e42:	85a2                	mv	a1,s0
    int total_free_pages = 0;
ffffffffc0200e44:	4601                	li	a2,0
    return listelm->next;
ffffffffc0200e46:	659c                	ld	a5,8(a1)

    // 检查每个阶数的空闲列表
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        int count = 0;
ffffffffc0200e48:	4681                	li	a3,0
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200e4a:	00b78f63          	beq	a5,a1,ffffffffc0200e68 <slub_check+0x4c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e4e:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc0200e52:	8b09                	andi	a4,a4,2
ffffffffc0200e54:	36070263          	beqz	a4,ffffffffc02011b8 <slub_check+0x39c>
            count++;
            total_free_pages += p->property;
ffffffffc0200e58:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e5c:	679c                	ld	a5,8(a5)
            count++;
ffffffffc0200e5e:	2685                	addiw	a3,a3,1
            total_free_pages += p->property;
ffffffffc0200e60:	9e39                	addw	a2,a2,a4
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200e62:	feb796e3          	bne	a5,a1,ffffffffc0200e4e <slub_check+0x32>
        }
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc0200e66:	2681                	sext.w	a3,a3
ffffffffc0200e68:	499c                	lw	a5,16(a1)
ffffffffc0200e6a:	38d79763          	bne	a5,a3,ffffffffc02011f8 <slub_check+0x3dc>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200e6e:	05e1                	addi	a1,a1,24
ffffffffc0200e70:	fca59be3          	bne	a1,a0,ffffffffc0200e46 <slub_check+0x2a>
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200e74:	00005917          	auipc	s2,0x5
ffffffffc0200e78:	1ac90913          	addi	s2,s2,428 # ffffffffc0206020 <free_area+0x10>
    }

    // 检查总的空闲页面数是否一致
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc0200e7c:	86ca                	mv	a3,s2
    size_t total = 0;
ffffffffc0200e7e:	4581                	li	a1,0
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200e80:	4781                	li	a5,0
ffffffffc0200e82:	482d                	li	a6,11
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200e84:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200e88:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200e8a:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200e8e:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200e90:	95ba                	add	a1,a1,a4
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200e92:	ff0799e3          	bne	a5,a6,ffffffffc0200e84 <slub_check+0x68>
    return total; // 返回总的空闲页面数
ffffffffc0200e96:	00005697          	auipc	a3,0x5
ffffffffc0200e9a:	17a68693          	addi	a3,a3,378 # ffffffffc0206010 <free_area>
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc0200e9e:	36b61d63          	bne	a2,a1,ffffffffc0201218 <slub_check+0x3fc>

    // 检查已分配页面的状态
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
ffffffffc0200ea2:	87b6                	mv	a5,a3
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200ea4:	a031                	j	ffffffffc0200eb0 <slub_check+0x94>
ffffffffc0200ea6:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc0200eaa:	8b09                	andi	a4,a4,2
ffffffffc0200eac:	32070663          	beqz	a4,ffffffffc02011d8 <slub_check+0x3bc>
ffffffffc0200eb0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200eb2:	fed79ae3          	bne	a5,a3,ffffffffc0200ea6 <slub_check+0x8a>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200eb6:	01878693          	addi	a3,a5,24
ffffffffc0200eba:	fea694e3          	bne	a3,a0,ffffffffc0200ea2 <slub_check+0x86>
ffffffffc0200ebe:	00005697          	auipc	a3,0x5
ffffffffc0200ec2:	16268693          	addi	a3,a3,354 # ffffffffc0206020 <free_area+0x10>
    size_t total = 0;
ffffffffc0200ec6:	4581                	li	a1,0
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ec8:	4781                	li	a5,0
ffffffffc0200eca:	462d                	li	a2,11
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ecc:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ed0:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ed2:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200ed6:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ed8:	95ba                	add	a1,a1,a4
    for (int i = 0; i < MAX_ORDER; i++)
ffffffffc0200eda:	fec799e3          	bne	a5,a2,ffffffffc0200ecc <slub_check+0xb0>
        }
    }

    // 可以添加更多的检查逻辑，例如检查每个页面的引用计数
    cprintf("总空闲块数目为：%d\n", slub_nr_free_pages()); // 输出空闲块数
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	1d250513          	addi	a0,a0,466 # ffffffffc02020b0 <commands+0x6c8>
ffffffffc0200ee6:	9ccff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200eea:	00005497          	auipc	s1,0x5
ffffffffc0200eee:	23e48493          	addi	s1,s1,574 # ffffffffc0206128 <buf+0x10>
    cprintf("总空闲块数目为：%d\n", slub_nr_free_pages()); // 输出空闲块数
ffffffffc0200ef2:	00005997          	auipc	s3,0x5
ffffffffc0200ef6:	12e98993          	addi	s3,s3,302 # ffffffffc0206020 <free_area+0x10>
        cprintf("%d ", free_area[i].nr_free); // 输出每个阶的空闲块数
ffffffffc0200efa:	00001a17          	auipc	s4,0x1
ffffffffc0200efe:	1d6a0a13          	addi	s4,s4,470 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc0200f02:	0009a583          	lw	a1,0(s3)
ffffffffc0200f06:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f08:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free); // 输出每个阶的空闲块数
ffffffffc0200f0a:	9a8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f0e:	ff349ae3          	bne	s1,s3,ffffffffc0200f02 <slub_check+0xe6>
    
    // 请求页面示例
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("\n首先 p0 请求 5 页\n");
ffffffffc0200f12:	00001517          	auipc	a0,0x1
ffffffffc0200f16:	1c650513          	addi	a0,a0,454 # ffffffffc02020d8 <commands+0x6f0>
ffffffffc0200f1a:	998ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p0 = buddy_alloc_pages(5);
ffffffffc0200f1e:	4515                	li	a0,5
ffffffffc0200f20:	c85ff0ef          	jal	ra,ffffffffc0200ba4 <buddy_alloc_pages>
ffffffffc0200f24:	8baa                	mv	s7,a0
ffffffffc0200f26:	00005997          	auipc	s3,0x5
ffffffffc0200f2a:	0fa98993          	addi	s3,s3,250 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f2e:	00001a17          	auipc	s4,0x1
ffffffffc0200f32:	1a2a0a13          	addi	s4,s4,418 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc0200f36:	0009a583          	lw	a1,0(s3)
ffffffffc0200f3a:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f3c:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f3e:	974ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f42:	ff349ae3          	bne	s1,s3,ffffffffc0200f36 <slub_check+0x11a>
    }
    
    cprintf("\n然后 p1 请求 5 页\n");
ffffffffc0200f46:	00001517          	auipc	a0,0x1
ffffffffc0200f4a:	1b250513          	addi	a0,a0,434 # ffffffffc02020f8 <commands+0x710>
ffffffffc0200f4e:	964ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = buddy_alloc_pages(5);
ffffffffc0200f52:	4515                	li	a0,5
ffffffffc0200f54:	c51ff0ef          	jal	ra,ffffffffc0200ba4 <buddy_alloc_pages>
ffffffffc0200f58:	8b2a                	mv	s6,a0
ffffffffc0200f5a:	00005997          	auipc	s3,0x5
ffffffffc0200f5e:	0c698993          	addi	s3,s3,198 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f62:	00001a17          	auipc	s4,0x1
ffffffffc0200f66:	16ea0a13          	addi	s4,s4,366 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc0200f6a:	0009a583          	lw	a1,0(s3)
ffffffffc0200f6e:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f70:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f72:	940ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f76:	ff349ae3          	bne	s1,s3,ffffffffc0200f6a <slub_check+0x14e>
    }
    
    cprintf("\n最后 p2 请求 1023页\n");
ffffffffc0200f7a:	00001517          	auipc	a0,0x1
ffffffffc0200f7e:	19e50513          	addi	a0,a0,414 # ffffffffc0202118 <commands+0x730>
ffffffffc0200f82:	930ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = buddy_alloc_pages(1023);
ffffffffc0200f86:	3ff00513          	li	a0,1023
ffffffffc0200f8a:	c1bff0ef          	jal	ra,ffffffffc0200ba4 <buddy_alloc_pages>
ffffffffc0200f8e:	8a2a                	mv	s4,a0
ffffffffc0200f90:	00005997          	auipc	s3,0x5
ffffffffc0200f94:	09098993          	addi	s3,s3,144 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f98:	00001a97          	auipc	s5,0x1
ffffffffc0200f9c:	138a8a93          	addi	s5,s5,312 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc0200fa0:	0009a583          	lw	a1,0(s3)
ffffffffc0200fa4:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200fa6:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200fa8:	90aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200fac:	ff349ae3          	bne	s1,s3,ffffffffc0200fa0 <slub_check+0x184>
    }
    
    cprintf("\n p0 的虚拟地址 0x%016lx.\n", p0);
ffffffffc0200fb0:	85de                	mv	a1,s7
ffffffffc0200fb2:	00001517          	auipc	a0,0x1
ffffffffc0200fb6:	18650513          	addi	a0,a0,390 # ffffffffc0202138 <commands+0x750>
ffffffffc0200fba:	8f8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p1 的虚拟地址 0x%016lx.\n", p1);
ffffffffc0200fbe:	85da                	mv	a1,s6
ffffffffc0200fc0:	00001517          	auipc	a0,0x1
ffffffffc0200fc4:	19850513          	addi	a0,a0,408 # ffffffffc0202158 <commands+0x770>
ffffffffc0200fc8:	8eaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p2 的虚拟地址 0x%016lx.\n", p2);
ffffffffc0200fcc:	85d2                	mv	a1,s4
ffffffffc0200fce:	00001517          	auipc	a0,0x1
ffffffffc0200fd2:	1aa50513          	addi	a0,a0,426 # ffffffffc0202178 <commands+0x790>
ffffffffc0200fd6:	8dcff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    
    
    cprintf("\n 收回p0\n");
ffffffffc0200fda:	00001517          	auipc	a0,0x1
ffffffffc0200fde:	1be50513          	addi	a0,a0,446 # ffffffffc0202198 <commands+0x7b0>
ffffffffc0200fe2:	8d0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++)
ffffffffc0200fe6:	0c8b8713          	addi	a4,s7,200
    p0 = buddy_alloc_pages(5);
ffffffffc0200fea:	87de                	mv	a5,s7
        p->flags = 0; // 清除标志
ffffffffc0200fec:	0007b423          	sd	zero,8(a5)
ffffffffc0200ff0:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++)
ffffffffc0200ff4:	02878793          	addi	a5,a5,40
ffffffffc0200ff8:	fef71ae3          	bne	a4,a5,ffffffffc0200fec <slub_check+0x1d0>
    base->property = n; // 设置释放页面的属性
ffffffffc0200ffc:	4795                	li	a5,5
ffffffffc0200ffe:	00fba823          	sw	a5,16(s7)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201002:	008b8713          	addi	a4,s7,8
ffffffffc0201006:	4789                	li	a5,2
ffffffffc0201008:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020100c:	6438                	ld	a4,72(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc020100e:	4c3c                	lw	a5,88(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0201010:	018b8693          	addi	a3,s7,24
    prev->next = next->prev = elm;
ffffffffc0201014:	e434                	sd	a3,72(s0)
ffffffffc0201016:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0201018:	00005c17          	auipc	s8,0x5
ffffffffc020101c:	040c0c13          	addi	s8,s8,64 # ffffffffc0206058 <free_area+0x48>
ffffffffc0201020:	038bb023          	sd	s8,32(s7)
    elm->prev = prev;
ffffffffc0201024:	00ebbc23          	sd	a4,24(s7)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0201028:	2785                	addiw	a5,a5,1
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc020102a:	85de                	mv	a1,s7
ffffffffc020102c:	450d                	li	a0,3
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc020102e:	cc3c                	sw	a5,88(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0201030:	00005997          	auipc	s3,0x5
ffffffffc0201034:	ff098993          	addi	s3,s3,-16 # ffffffffc0206020 <free_area+0x10>
ffffffffc0201038:	97fff0ef          	jal	ra,ffffffffc02009b6 <merge_page>
    buddy_free_pages(p0,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc020103c:	00001a97          	auipc	s5,0x1
ffffffffc0201040:	094a8a93          	addi	s5,s5,148 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc0201044:	0009a583          	lw	a1,0(s3)
ffffffffc0201048:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc020104a:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc020104c:	866ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0201050:	fe999ae3          	bne	s3,s1,ffffffffc0201044 <slub_check+0x228>
    }
    
    cprintf("\n 收回p1\n");
ffffffffc0201054:	00001517          	auipc	a0,0x1
ffffffffc0201058:	15450513          	addi	a0,a0,340 # ffffffffc02021a8 <commands+0x7c0>
ffffffffc020105c:	856ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++)
ffffffffc0201060:	0c8b0713          	addi	a4,s6,200
    p1 = buddy_alloc_pages(5);
ffffffffc0201064:	87da                	mv	a5,s6
        p->flags = 0; // 清除标志
ffffffffc0201066:	0007b423          	sd	zero,8(a5)
ffffffffc020106a:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++)
ffffffffc020106e:	02878793          	addi	a5,a5,40
ffffffffc0201072:	fee79ae3          	bne	a5,a4,ffffffffc0201066 <slub_check+0x24a>
    base->property = n; // 设置释放页面的属性
ffffffffc0201076:	4795                	li	a5,5
ffffffffc0201078:	00fb2823          	sw	a5,16(s6)
ffffffffc020107c:	008b0713          	addi	a4,s6,8
ffffffffc0201080:	4789                	li	a5,2
ffffffffc0201082:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201086:	6438                	ld	a4,72(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0201088:	4c3c                	lw	a5,88(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc020108a:	018b0693          	addi	a3,s6,24
    prev->next = next->prev = elm;
ffffffffc020108e:	e434                	sd	a3,72(s0)
ffffffffc0201090:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0201092:	038b3023          	sd	s8,32(s6)
    elm->prev = prev;
ffffffffc0201096:	00eb3c23          	sd	a4,24(s6)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc020109a:	2785                	addiw	a5,a5,1
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc020109c:	85da                	mv	a1,s6
ffffffffc020109e:	450d                	li	a0,3
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc02010a0:	cc3c                	sw	a5,88(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc02010a2:	00005997          	auipc	s3,0x5
ffffffffc02010a6:	f7e98993          	addi	s3,s3,-130 # ffffffffc0206020 <free_area+0x10>
ffffffffc02010aa:	90dff0ef          	jal	ra,ffffffffc02009b6 <merge_page>
    buddy_free_pages(p1,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc02010ae:	00001a97          	auipc	s5,0x1
ffffffffc02010b2:	022a8a93          	addi	s5,s5,34 # ffffffffc02020d0 <commands+0x6e8>
ffffffffc02010b6:	0009a583          	lw	a1,0(s3)
ffffffffc02010ba:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02010bc:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc02010be:	ff5fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02010c2:	ff349ae3          	bne	s1,s3,ffffffffc02010b6 <slub_check+0x29a>
    }
    
    cprintf("\n 收回p2\n");
ffffffffc02010c6:	00001517          	auipc	a0,0x1
ffffffffc02010ca:	0f250513          	addi	a0,a0,242 # ffffffffc02021b8 <commands+0x7d0>
ffffffffc02010ce:	fe5fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++)
ffffffffc02010d2:	6729                	lui	a4,0xa
ffffffffc02010d4:	fd870713          	addi	a4,a4,-40 # 9fd8 <kern_entry-0xffffffffc01f6028>
ffffffffc02010d8:	9752                	add	a4,a4,s4
    p2 = buddy_alloc_pages(1023);
ffffffffc02010da:	87d2                	mv	a5,s4
        p->flags = 0; // 清除标志
ffffffffc02010dc:	0007b423          	sd	zero,8(a5)
ffffffffc02010e0:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++)
ffffffffc02010e4:	02878793          	addi	a5,a5,40
ffffffffc02010e8:	fef71ae3          	bne	a4,a5,ffffffffc02010dc <slub_check+0x2c0>
    base->property = n; // 设置释放页面的属性
ffffffffc02010ec:	3ff00793          	li	a5,1023
ffffffffc02010f0:	00fa2823          	sw	a5,16(s4)
ffffffffc02010f4:	008a0713          	addi	a4,s4,8
ffffffffc02010f8:	4789                	li	a5,2
ffffffffc02010fa:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010fe:	7878                	ld	a4,240(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0201100:	10042783          	lw	a5,256(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0201104:	018a0693          	addi	a3,s4,24
    prev->next = next->prev = elm;
ffffffffc0201108:	f874                	sd	a3,240(s0)
ffffffffc020110a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020110c:	00005697          	auipc	a3,0x5
ffffffffc0201110:	ff468693          	addi	a3,a3,-12 # ffffffffc0206100 <free_area+0xf0>
ffffffffc0201114:	02da3023          	sd	a3,32(s4)
    elm->prev = prev;
ffffffffc0201118:	00ea3c23          	sd	a4,24(s4)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc020111c:	2785                	addiw	a5,a5,1
ffffffffc020111e:	10f42023          	sw	a5,256(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0201122:	85d2                	mv	a1,s4
ffffffffc0201124:	4529                	li	a0,10
    buddy_free_pages(p2,1023);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0201126:	00001417          	auipc	s0,0x1
ffffffffc020112a:	faa40413          	addi	s0,s0,-86 # ffffffffc02020d0 <commands+0x6e8>
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc020112e:	889ff0ef          	jal	ra,ffffffffc02009b6 <merge_page>
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0201132:	00092583          	lw	a1,0(s2)
ffffffffc0201136:	8522                	mv	a0,s0
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0201138:	0961                	addi	s2,s2,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc020113a:	f79fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc020113e:	fe991ae3          	bne	s2,s1,ffffffffc0201132 <slub_check+0x316>
    }
    
    cprintf("\n");
ffffffffc0201142:	00000517          	auipc	a0,0x0
ffffffffc0201146:	73650513          	addi	a0,a0,1846 # ffffffffc0201878 <etext+0xec>
ffffffffc020114a:	f69fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    // struct Page *p0 = NULL;
    void *small_block_ptr = NULL;

    

    cprintf("\n然后请求小块内存（大小为 128）\n");
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	07a50513          	addi	a0,a0,122 # ffffffffc02021c8 <commands+0x7e0>
ffffffffc0201156:	f5dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    small_block_ptr = slub_alloc_small(128);
ffffffffc020115a:	00001797          	auipc	a5,0x1
ffffffffc020115e:	38e7a507          	flw	fa0,910(a5) # ffffffffc02024e8 <error_string+0x38>
ffffffffc0201162:	b6bff0ef          	jal	ra,ffffffffc0200ccc <slub_alloc_small>
ffffffffc0201166:	842a                	mv	s0,a0
    cprintf("小块内存分配成功\n");
ffffffffc0201168:	00001517          	auipc	a0,0x1
ffffffffc020116c:	09050513          	addi	a0,a0,144 # ffffffffc02021f8 <commands+0x810>
ffffffffc0201170:	f43fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    

    cprintf("\n收回小块内存\n");
ffffffffc0201174:	00001517          	auipc	a0,0x1
ffffffffc0201178:	0a450513          	addi	a0,a0,164 # ffffffffc0202218 <commands+0x830>
ffffffffc020117c:	f37fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    slub_free_small(small_block_ptr, 128);
ffffffffc0201180:	8522                	mv	a0,s0
ffffffffc0201182:	08000593          	li	a1,128
ffffffffc0201186:	949ff0ef          	jal	ra,ffffffffc0200ace <slub_free_small>
    cprintf("小块内存回收成功\n");
ffffffffc020118a:	00001517          	auipc	a0,0x1
ffffffffc020118e:	0a650513          	addi	a0,a0,166 # ffffffffc0202230 <commands+0x848>
ffffffffc0201192:	f21fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    cprintf("\n");
}
ffffffffc0201196:	6406                	ld	s0,64(sp)
ffffffffc0201198:	60a6                	ld	ra,72(sp)
ffffffffc020119a:	74e2                	ld	s1,56(sp)
ffffffffc020119c:	7942                	ld	s2,48(sp)
ffffffffc020119e:	79a2                	ld	s3,40(sp)
ffffffffc02011a0:	7a02                	ld	s4,32(sp)
ffffffffc02011a2:	6ae2                	ld	s5,24(sp)
ffffffffc02011a4:	6b42                	ld	s6,16(sp)
ffffffffc02011a6:	6ba2                	ld	s7,8(sp)
ffffffffc02011a8:	6c02                	ld	s8,0(sp)
    cprintf("\n");
ffffffffc02011aa:	00000517          	auipc	a0,0x0
ffffffffc02011ae:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201878 <etext+0xec>
}
ffffffffc02011b2:	6161                	addi	sp,sp,80
    cprintf("\n");
ffffffffc02011b4:	efffe06f          	j	ffffffffc02000b2 <cprintf>
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc02011b8:	00001697          	auipc	a3,0x1
ffffffffc02011bc:	e9868693          	addi	a3,a3,-360 # ffffffffc0202050 <commands+0x668>
ffffffffc02011c0:	00001617          	auipc	a2,0x1
ffffffffc02011c4:	e5060613          	addi	a2,a2,-432 # ffffffffc0202010 <commands+0x628>
ffffffffc02011c8:	12900593          	li	a1,297
ffffffffc02011cc:	00001517          	auipc	a0,0x1
ffffffffc02011d0:	e5c50513          	addi	a0,a0,-420 # ffffffffc0202028 <commands+0x640>
ffffffffc02011d4:	9d8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc02011d8:	00001697          	auipc	a3,0x1
ffffffffc02011dc:	e7868693          	addi	a3,a3,-392 # ffffffffc0202050 <commands+0x668>
ffffffffc02011e0:	00001617          	auipc	a2,0x1
ffffffffc02011e4:	e3060613          	addi	a2,a2,-464 # ffffffffc0202010 <commands+0x628>
ffffffffc02011e8:	13800593          	li	a1,312
ffffffffc02011ec:	00001517          	auipc	a0,0x1
ffffffffc02011f0:	e3c50513          	addi	a0,a0,-452 # ffffffffc0202028 <commands+0x640>
ffffffffc02011f4:	9b8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc02011f8:	00001697          	auipc	a3,0x1
ffffffffc02011fc:	e6868693          	addi	a3,a3,-408 # ffffffffc0202060 <commands+0x678>
ffffffffc0201200:	00001617          	auipc	a2,0x1
ffffffffc0201204:	e1060613          	addi	a2,a2,-496 # ffffffffc0202010 <commands+0x628>
ffffffffc0201208:	12d00593          	li	a1,301
ffffffffc020120c:	00001517          	auipc	a0,0x1
ffffffffc0201210:	e1c50513          	addi	a0,a0,-484 # ffffffffc0202028 <commands+0x640>
ffffffffc0201214:	998ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc0201218:	00001697          	auipc	a3,0x1
ffffffffc020121c:	e6868693          	addi	a3,a3,-408 # ffffffffc0202080 <commands+0x698>
ffffffffc0201220:	00001617          	auipc	a2,0x1
ffffffffc0201224:	df060613          	addi	a2,a2,-528 # ffffffffc0202010 <commands+0x628>
ffffffffc0201228:	13100593          	li	a1,305
ffffffffc020122c:	00001517          	auipc	a0,0x1
ffffffffc0201230:	dfc50513          	addi	a0,a0,-516 # ffffffffc0202028 <commands+0x640>
ffffffffc0201234:	978ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201238 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201238:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020123c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020123e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201242:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201244:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201248:	f022                	sd	s0,32(sp)
ffffffffc020124a:	ec26                	sd	s1,24(sp)
ffffffffc020124c:	e84a                	sd	s2,16(sp)
ffffffffc020124e:	f406                	sd	ra,40(sp)
ffffffffc0201250:	e44e                	sd	s3,8(sp)
ffffffffc0201252:	84aa                	mv	s1,a0
ffffffffc0201254:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201256:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020125a:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020125c:	03067e63          	bgeu	a2,a6,ffffffffc0201298 <printnum+0x60>
ffffffffc0201260:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201262:	00805763          	blez	s0,ffffffffc0201270 <printnum+0x38>
ffffffffc0201266:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201268:	85ca                	mv	a1,s2
ffffffffc020126a:	854e                	mv	a0,s3
ffffffffc020126c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020126e:	fc65                	bnez	s0,ffffffffc0201266 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201270:	1a02                	slli	s4,s4,0x20
ffffffffc0201272:	00001797          	auipc	a5,0x1
ffffffffc0201276:	02e78793          	addi	a5,a5,46 # ffffffffc02022a0 <slub_pmm_manager+0x38>
ffffffffc020127a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020127e:	9a3e                	add	s4,s4,a5
}
ffffffffc0201280:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201282:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201286:	70a2                	ld	ra,40(sp)
ffffffffc0201288:	69a2                	ld	s3,8(sp)
ffffffffc020128a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020128c:	85ca                	mv	a1,s2
ffffffffc020128e:	87a6                	mv	a5,s1
}
ffffffffc0201290:	6942                	ld	s2,16(sp)
ffffffffc0201292:	64e2                	ld	s1,24(sp)
ffffffffc0201294:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201296:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201298:	03065633          	divu	a2,a2,a6
ffffffffc020129c:	8722                	mv	a4,s0
ffffffffc020129e:	f9bff0ef          	jal	ra,ffffffffc0201238 <printnum>
ffffffffc02012a2:	b7f9                	j	ffffffffc0201270 <printnum+0x38>

ffffffffc02012a4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012a4:	7119                	addi	sp,sp,-128
ffffffffc02012a6:	f4a6                	sd	s1,104(sp)
ffffffffc02012a8:	f0ca                	sd	s2,96(sp)
ffffffffc02012aa:	ecce                	sd	s3,88(sp)
ffffffffc02012ac:	e8d2                	sd	s4,80(sp)
ffffffffc02012ae:	e4d6                	sd	s5,72(sp)
ffffffffc02012b0:	e0da                	sd	s6,64(sp)
ffffffffc02012b2:	fc5e                	sd	s7,56(sp)
ffffffffc02012b4:	f06a                	sd	s10,32(sp)
ffffffffc02012b6:	fc86                	sd	ra,120(sp)
ffffffffc02012b8:	f8a2                	sd	s0,112(sp)
ffffffffc02012ba:	f862                	sd	s8,48(sp)
ffffffffc02012bc:	f466                	sd	s9,40(sp)
ffffffffc02012be:	ec6e                	sd	s11,24(sp)
ffffffffc02012c0:	892a                	mv	s2,a0
ffffffffc02012c2:	84ae                	mv	s1,a1
ffffffffc02012c4:	8d32                	mv	s10,a2
ffffffffc02012c6:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012c8:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012cc:	5b7d                	li	s6,-1
ffffffffc02012ce:	00001a97          	auipc	s5,0x1
ffffffffc02012d2:	006a8a93          	addi	s5,s5,6 # ffffffffc02022d4 <slub_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012d6:	00001b97          	auipc	s7,0x1
ffffffffc02012da:	1dab8b93          	addi	s7,s7,474 # ffffffffc02024b0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012de:	000d4503          	lbu	a0,0(s10)
ffffffffc02012e2:	001d0413          	addi	s0,s10,1
ffffffffc02012e6:	01350a63          	beq	a0,s3,ffffffffc02012fa <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02012ea:	c121                	beqz	a0,ffffffffc020132a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02012ec:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ee:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02012f0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012f2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02012f6:	ff351ae3          	bne	a0,s3,ffffffffc02012ea <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012fa:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02012fe:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201302:	4c81                	li	s9,0
ffffffffc0201304:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201306:	5c7d                	li	s8,-1
ffffffffc0201308:	5dfd                	li	s11,-1
ffffffffc020130a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020130e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201310:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201314:	0ff5f593          	zext.b	a1,a1
ffffffffc0201318:	00140d13          	addi	s10,s0,1
ffffffffc020131c:	04b56263          	bltu	a0,a1,ffffffffc0201360 <vprintfmt+0xbc>
ffffffffc0201320:	058a                	slli	a1,a1,0x2
ffffffffc0201322:	95d6                	add	a1,a1,s5
ffffffffc0201324:	4194                	lw	a3,0(a1)
ffffffffc0201326:	96d6                	add	a3,a3,s5
ffffffffc0201328:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020132a:	70e6                	ld	ra,120(sp)
ffffffffc020132c:	7446                	ld	s0,112(sp)
ffffffffc020132e:	74a6                	ld	s1,104(sp)
ffffffffc0201330:	7906                	ld	s2,96(sp)
ffffffffc0201332:	69e6                	ld	s3,88(sp)
ffffffffc0201334:	6a46                	ld	s4,80(sp)
ffffffffc0201336:	6aa6                	ld	s5,72(sp)
ffffffffc0201338:	6b06                	ld	s6,64(sp)
ffffffffc020133a:	7be2                	ld	s7,56(sp)
ffffffffc020133c:	7c42                	ld	s8,48(sp)
ffffffffc020133e:	7ca2                	ld	s9,40(sp)
ffffffffc0201340:	7d02                	ld	s10,32(sp)
ffffffffc0201342:	6de2                	ld	s11,24(sp)
ffffffffc0201344:	6109                	addi	sp,sp,128
ffffffffc0201346:	8082                	ret
            padc = '0';
ffffffffc0201348:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc020134a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020134e:	846a                	mv	s0,s10
ffffffffc0201350:	00140d13          	addi	s10,s0,1
ffffffffc0201354:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201358:	0ff5f593          	zext.b	a1,a1
ffffffffc020135c:	fcb572e3          	bgeu	a0,a1,ffffffffc0201320 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201360:	85a6                	mv	a1,s1
ffffffffc0201362:	02500513          	li	a0,37
ffffffffc0201366:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201368:	fff44783          	lbu	a5,-1(s0)
ffffffffc020136c:	8d22                	mv	s10,s0
ffffffffc020136e:	f73788e3          	beq	a5,s3,ffffffffc02012de <vprintfmt+0x3a>
ffffffffc0201372:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201376:	1d7d                	addi	s10,s10,-1
ffffffffc0201378:	ff379de3          	bne	a5,s3,ffffffffc0201372 <vprintfmt+0xce>
ffffffffc020137c:	b78d                	j	ffffffffc02012de <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020137e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201382:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201386:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201388:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020138c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201390:	02d86463          	bltu	a6,a3,ffffffffc02013b8 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201394:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201398:	002c169b          	slliw	a3,s8,0x2
ffffffffc020139c:	0186873b          	addw	a4,a3,s8
ffffffffc02013a0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013a4:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02013a6:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013aa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013ac:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02013b0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013b4:	fed870e3          	bgeu	a6,a3,ffffffffc0201394 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02013b8:	f40ddce3          	bgez	s11,ffffffffc0201310 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02013bc:	8de2                	mv	s11,s8
ffffffffc02013be:	5c7d                	li	s8,-1
ffffffffc02013c0:	bf81                	j	ffffffffc0201310 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02013c2:	fffdc693          	not	a3,s11
ffffffffc02013c6:	96fd                	srai	a3,a3,0x3f
ffffffffc02013c8:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013cc:	00144603          	lbu	a2,1(s0)
ffffffffc02013d0:	2d81                	sext.w	s11,s11
ffffffffc02013d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013d4:	bf35                	j	ffffffffc0201310 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02013d6:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013da:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02013de:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013e0:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02013e2:	bfd9                	j	ffffffffc02013b8 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02013e4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013e6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013ea:	01174463          	blt	a4,a7,ffffffffc02013f2 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02013ee:	1a088e63          	beqz	a7,ffffffffc02015aa <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02013f2:	000a3603          	ld	a2,0(s4)
ffffffffc02013f6:	46c1                	li	a3,16
ffffffffc02013f8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02013fa:	2781                	sext.w	a5,a5
ffffffffc02013fc:	876e                	mv	a4,s11
ffffffffc02013fe:	85a6                	mv	a1,s1
ffffffffc0201400:	854a                	mv	a0,s2
ffffffffc0201402:	e37ff0ef          	jal	ra,ffffffffc0201238 <printnum>
            break;
ffffffffc0201406:	bde1                	j	ffffffffc02012de <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201408:	000a2503          	lw	a0,0(s4)
ffffffffc020140c:	85a6                	mv	a1,s1
ffffffffc020140e:	0a21                	addi	s4,s4,8
ffffffffc0201410:	9902                	jalr	s2
            break;
ffffffffc0201412:	b5f1                	j	ffffffffc02012de <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201414:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201416:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020141a:	01174463          	blt	a4,a7,ffffffffc0201422 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020141e:	18088163          	beqz	a7,ffffffffc02015a0 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201422:	000a3603          	ld	a2,0(s4)
ffffffffc0201426:	46a9                	li	a3,10
ffffffffc0201428:	8a2e                	mv	s4,a1
ffffffffc020142a:	bfc1                	j	ffffffffc02013fa <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020142c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201430:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201432:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201434:	bdf1                	j	ffffffffc0201310 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201436:	85a6                	mv	a1,s1
ffffffffc0201438:	02500513          	li	a0,37
ffffffffc020143c:	9902                	jalr	s2
            break;
ffffffffc020143e:	b545                	j	ffffffffc02012de <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201440:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201444:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201446:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201448:	b5e1                	j	ffffffffc0201310 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc020144a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020144c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201450:	01174463          	blt	a4,a7,ffffffffc0201458 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201454:	14088163          	beqz	a7,ffffffffc0201596 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201458:	000a3603          	ld	a2,0(s4)
ffffffffc020145c:	46a1                	li	a3,8
ffffffffc020145e:	8a2e                	mv	s4,a1
ffffffffc0201460:	bf69                	j	ffffffffc02013fa <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201462:	03000513          	li	a0,48
ffffffffc0201466:	85a6                	mv	a1,s1
ffffffffc0201468:	e03e                	sd	a5,0(sp)
ffffffffc020146a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020146c:	85a6                	mv	a1,s1
ffffffffc020146e:	07800513          	li	a0,120
ffffffffc0201472:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201474:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201476:	6782                	ld	a5,0(sp)
ffffffffc0201478:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020147a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020147e:	bfb5                	j	ffffffffc02013fa <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201480:	000a3403          	ld	s0,0(s4)
ffffffffc0201484:	008a0713          	addi	a4,s4,8
ffffffffc0201488:	e03a                	sd	a4,0(sp)
ffffffffc020148a:	14040263          	beqz	s0,ffffffffc02015ce <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020148e:	0fb05763          	blez	s11,ffffffffc020157c <vprintfmt+0x2d8>
ffffffffc0201492:	02d00693          	li	a3,45
ffffffffc0201496:	0cd79163          	bne	a5,a3,ffffffffc0201558 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020149a:	00044783          	lbu	a5,0(s0)
ffffffffc020149e:	0007851b          	sext.w	a0,a5
ffffffffc02014a2:	cf85                	beqz	a5,ffffffffc02014da <vprintfmt+0x236>
ffffffffc02014a4:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014a8:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014ac:	000c4563          	bltz	s8,ffffffffc02014b6 <vprintfmt+0x212>
ffffffffc02014b0:	3c7d                	addiw	s8,s8,-1
ffffffffc02014b2:	036c0263          	beq	s8,s6,ffffffffc02014d6 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02014b6:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014b8:	0e0c8e63          	beqz	s9,ffffffffc02015b4 <vprintfmt+0x310>
ffffffffc02014bc:	3781                	addiw	a5,a5,-32
ffffffffc02014be:	0ef47b63          	bgeu	s0,a5,ffffffffc02015b4 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02014c2:	03f00513          	li	a0,63
ffffffffc02014c6:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014c8:	000a4783          	lbu	a5,0(s4)
ffffffffc02014cc:	3dfd                	addiw	s11,s11,-1
ffffffffc02014ce:	0a05                	addi	s4,s4,1
ffffffffc02014d0:	0007851b          	sext.w	a0,a5
ffffffffc02014d4:	ffe1                	bnez	a5,ffffffffc02014ac <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02014d6:	01b05963          	blez	s11,ffffffffc02014e8 <vprintfmt+0x244>
ffffffffc02014da:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014dc:	85a6                	mv	a1,s1
ffffffffc02014de:	02000513          	li	a0,32
ffffffffc02014e2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014e4:	fe0d9be3          	bnez	s11,ffffffffc02014da <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014e8:	6a02                	ld	s4,0(sp)
ffffffffc02014ea:	bbd5                	j	ffffffffc02012de <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02014ec:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014ee:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02014f2:	01174463          	blt	a4,a7,ffffffffc02014fa <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02014f6:	08088d63          	beqz	a7,ffffffffc0201590 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02014fa:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02014fe:	0a044d63          	bltz	s0,ffffffffc02015b8 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201502:	8622                	mv	a2,s0
ffffffffc0201504:	8a66                	mv	s4,s9
ffffffffc0201506:	46a9                	li	a3,10
ffffffffc0201508:	bdcd                	j	ffffffffc02013fa <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020150a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020150e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201510:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201512:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201516:	8fb5                	xor	a5,a5,a3
ffffffffc0201518:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020151c:	02d74163          	blt	a4,a3,ffffffffc020153e <vprintfmt+0x29a>
ffffffffc0201520:	00369793          	slli	a5,a3,0x3
ffffffffc0201524:	97de                	add	a5,a5,s7
ffffffffc0201526:	639c                	ld	a5,0(a5)
ffffffffc0201528:	cb99                	beqz	a5,ffffffffc020153e <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020152a:	86be                	mv	a3,a5
ffffffffc020152c:	00001617          	auipc	a2,0x1
ffffffffc0201530:	da460613          	addi	a2,a2,-604 # ffffffffc02022d0 <slub_pmm_manager+0x68>
ffffffffc0201534:	85a6                	mv	a1,s1
ffffffffc0201536:	854a                	mv	a0,s2
ffffffffc0201538:	0ce000ef          	jal	ra,ffffffffc0201606 <printfmt>
ffffffffc020153c:	b34d                	j	ffffffffc02012de <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020153e:	00001617          	auipc	a2,0x1
ffffffffc0201542:	d8260613          	addi	a2,a2,-638 # ffffffffc02022c0 <slub_pmm_manager+0x58>
ffffffffc0201546:	85a6                	mv	a1,s1
ffffffffc0201548:	854a                	mv	a0,s2
ffffffffc020154a:	0bc000ef          	jal	ra,ffffffffc0201606 <printfmt>
ffffffffc020154e:	bb41                	j	ffffffffc02012de <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201550:	00001417          	auipc	s0,0x1
ffffffffc0201554:	d6840413          	addi	s0,s0,-664 # ffffffffc02022b8 <slub_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201558:	85e2                	mv	a1,s8
ffffffffc020155a:	8522                	mv	a0,s0
ffffffffc020155c:	e43e                	sd	a5,8(sp)
ffffffffc020155e:	1cc000ef          	jal	ra,ffffffffc020172a <strnlen>
ffffffffc0201562:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201566:	01b05b63          	blez	s11,ffffffffc020157c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020156a:	67a2                	ld	a5,8(sp)
ffffffffc020156c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201570:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201572:	85a6                	mv	a1,s1
ffffffffc0201574:	8552                	mv	a0,s4
ffffffffc0201576:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201578:	fe0d9ce3          	bnez	s11,ffffffffc0201570 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020157c:	00044783          	lbu	a5,0(s0)
ffffffffc0201580:	00140a13          	addi	s4,s0,1
ffffffffc0201584:	0007851b          	sext.w	a0,a5
ffffffffc0201588:	d3a5                	beqz	a5,ffffffffc02014e8 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020158a:	05e00413          	li	s0,94
ffffffffc020158e:	bf39                	j	ffffffffc02014ac <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201590:	000a2403          	lw	s0,0(s4)
ffffffffc0201594:	b7ad                	j	ffffffffc02014fe <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201596:	000a6603          	lwu	a2,0(s4)
ffffffffc020159a:	46a1                	li	a3,8
ffffffffc020159c:	8a2e                	mv	s4,a1
ffffffffc020159e:	bdb1                	j	ffffffffc02013fa <vprintfmt+0x156>
ffffffffc02015a0:	000a6603          	lwu	a2,0(s4)
ffffffffc02015a4:	46a9                	li	a3,10
ffffffffc02015a6:	8a2e                	mv	s4,a1
ffffffffc02015a8:	bd89                	j	ffffffffc02013fa <vprintfmt+0x156>
ffffffffc02015aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ae:	46c1                	li	a3,16
ffffffffc02015b0:	8a2e                	mv	s4,a1
ffffffffc02015b2:	b5a1                	j	ffffffffc02013fa <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02015b4:	9902                	jalr	s2
ffffffffc02015b6:	bf09                	j	ffffffffc02014c8 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02015b8:	85a6                	mv	a1,s1
ffffffffc02015ba:	02d00513          	li	a0,45
ffffffffc02015be:	e03e                	sd	a5,0(sp)
ffffffffc02015c0:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015c2:	6782                	ld	a5,0(sp)
ffffffffc02015c4:	8a66                	mv	s4,s9
ffffffffc02015c6:	40800633          	neg	a2,s0
ffffffffc02015ca:	46a9                	li	a3,10
ffffffffc02015cc:	b53d                	j	ffffffffc02013fa <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02015ce:	03b05163          	blez	s11,ffffffffc02015f0 <vprintfmt+0x34c>
ffffffffc02015d2:	02d00693          	li	a3,45
ffffffffc02015d6:	f6d79de3          	bne	a5,a3,ffffffffc0201550 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02015da:	00001417          	auipc	s0,0x1
ffffffffc02015de:	cde40413          	addi	s0,s0,-802 # ffffffffc02022b8 <slub_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015e2:	02800793          	li	a5,40
ffffffffc02015e6:	02800513          	li	a0,40
ffffffffc02015ea:	00140a13          	addi	s4,s0,1
ffffffffc02015ee:	bd6d                	j	ffffffffc02014a8 <vprintfmt+0x204>
ffffffffc02015f0:	00001a17          	auipc	s4,0x1
ffffffffc02015f4:	cc9a0a13          	addi	s4,s4,-823 # ffffffffc02022b9 <slub_pmm_manager+0x51>
ffffffffc02015f8:	02800513          	li	a0,40
ffffffffc02015fc:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201600:	05e00413          	li	s0,94
ffffffffc0201604:	b565                	j	ffffffffc02014ac <vprintfmt+0x208>

ffffffffc0201606 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201606:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201608:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020160c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020160e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201610:	ec06                	sd	ra,24(sp)
ffffffffc0201612:	f83a                	sd	a4,48(sp)
ffffffffc0201614:	fc3e                	sd	a5,56(sp)
ffffffffc0201616:	e0c2                	sd	a6,64(sp)
ffffffffc0201618:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020161a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020161c:	c89ff0ef          	jal	ra,ffffffffc02012a4 <vprintfmt>
}
ffffffffc0201620:	60e2                	ld	ra,24(sp)
ffffffffc0201622:	6161                	addi	sp,sp,80
ffffffffc0201624:	8082                	ret

ffffffffc0201626 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201626:	715d                	addi	sp,sp,-80
ffffffffc0201628:	e486                	sd	ra,72(sp)
ffffffffc020162a:	e0a6                	sd	s1,64(sp)
ffffffffc020162c:	fc4a                	sd	s2,56(sp)
ffffffffc020162e:	f84e                	sd	s3,48(sp)
ffffffffc0201630:	f452                	sd	s4,40(sp)
ffffffffc0201632:	f056                	sd	s5,32(sp)
ffffffffc0201634:	ec5a                	sd	s6,24(sp)
ffffffffc0201636:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201638:	c901                	beqz	a0,ffffffffc0201648 <readline+0x22>
ffffffffc020163a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020163c:	00001517          	auipc	a0,0x1
ffffffffc0201640:	c9450513          	addi	a0,a0,-876 # ffffffffc02022d0 <slub_pmm_manager+0x68>
ffffffffc0201644:	a6ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201648:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020164a:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020164c:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020164e:	4aa9                	li	s5,10
ffffffffc0201650:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201652:	00005b97          	auipc	s7,0x5
ffffffffc0201656:	ac6b8b93          	addi	s7,s7,-1338 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020165a:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020165e:	acdfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201662:	00054a63          	bltz	a0,ffffffffc0201676 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201666:	00a95a63          	bge	s2,a0,ffffffffc020167a <readline+0x54>
ffffffffc020166a:	029a5263          	bge	s4,s1,ffffffffc020168e <readline+0x68>
        c = getchar();
ffffffffc020166e:	abdfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201672:	fe055ae3          	bgez	a0,ffffffffc0201666 <readline+0x40>
            return NULL;
ffffffffc0201676:	4501                	li	a0,0
ffffffffc0201678:	a091                	j	ffffffffc02016bc <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020167a:	03351463          	bne	a0,s3,ffffffffc02016a2 <readline+0x7c>
ffffffffc020167e:	e8a9                	bnez	s1,ffffffffc02016d0 <readline+0xaa>
        c = getchar();
ffffffffc0201680:	aabfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201684:	fe0549e3          	bltz	a0,ffffffffc0201676 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201688:	fea959e3          	bge	s2,a0,ffffffffc020167a <readline+0x54>
ffffffffc020168c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020168e:	e42a                	sd	a0,8(sp)
ffffffffc0201690:	a59fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201694:	6522                	ld	a0,8(sp)
ffffffffc0201696:	009b87b3          	add	a5,s7,s1
ffffffffc020169a:	2485                	addiw	s1,s1,1
ffffffffc020169c:	00a78023          	sb	a0,0(a5)
ffffffffc02016a0:	bf7d                	j	ffffffffc020165e <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02016a2:	01550463          	beq	a0,s5,ffffffffc02016aa <readline+0x84>
ffffffffc02016a6:	fb651ce3          	bne	a0,s6,ffffffffc020165e <readline+0x38>
            cputchar(c);
ffffffffc02016aa:	a3ffe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02016ae:	00005517          	auipc	a0,0x5
ffffffffc02016b2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0206118 <buf>
ffffffffc02016b6:	94aa                	add	s1,s1,a0
ffffffffc02016b8:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02016bc:	60a6                	ld	ra,72(sp)
ffffffffc02016be:	6486                	ld	s1,64(sp)
ffffffffc02016c0:	7962                	ld	s2,56(sp)
ffffffffc02016c2:	79c2                	ld	s3,48(sp)
ffffffffc02016c4:	7a22                	ld	s4,40(sp)
ffffffffc02016c6:	7a82                	ld	s5,32(sp)
ffffffffc02016c8:	6b62                	ld	s6,24(sp)
ffffffffc02016ca:	6bc2                	ld	s7,16(sp)
ffffffffc02016cc:	6161                	addi	sp,sp,80
ffffffffc02016ce:	8082                	ret
            cputchar(c);
ffffffffc02016d0:	4521                	li	a0,8
ffffffffc02016d2:	a17fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02016d6:	34fd                	addiw	s1,s1,-1
ffffffffc02016d8:	b759                	j	ffffffffc020165e <readline+0x38>

ffffffffc02016da <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02016da:	4781                	li	a5,0
ffffffffc02016dc:	00005717          	auipc	a4,0x5
ffffffffc02016e0:	92c73703          	ld	a4,-1748(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02016e4:	88ba                	mv	a7,a4
ffffffffc02016e6:	852a                	mv	a0,a0
ffffffffc02016e8:	85be                	mv	a1,a5
ffffffffc02016ea:	863e                	mv	a2,a5
ffffffffc02016ec:	00000073          	ecall
ffffffffc02016f0:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02016f2:	8082                	ret

ffffffffc02016f4 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02016f4:	4781                	li	a5,0
ffffffffc02016f6:	00005717          	auipc	a4,0x5
ffffffffc02016fa:	e6a73703          	ld	a4,-406(a4) # ffffffffc0206560 <SBI_SET_TIMER>
ffffffffc02016fe:	88ba                	mv	a7,a4
ffffffffc0201700:	852a                	mv	a0,a0
ffffffffc0201702:	85be                	mv	a1,a5
ffffffffc0201704:	863e                	mv	a2,a5
ffffffffc0201706:	00000073          	ecall
ffffffffc020170a:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc020170c:	8082                	ret

ffffffffc020170e <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc020170e:	4501                	li	a0,0
ffffffffc0201710:	00005797          	auipc	a5,0x5
ffffffffc0201714:	8f07b783          	ld	a5,-1808(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201718:	88be                	mv	a7,a5
ffffffffc020171a:	852a                	mv	a0,a0
ffffffffc020171c:	85aa                	mv	a1,a0
ffffffffc020171e:	862a                	mv	a2,a0
ffffffffc0201720:	00000073          	ecall
ffffffffc0201724:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201726:	2501                	sext.w	a0,a0
ffffffffc0201728:	8082                	ret

ffffffffc020172a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020172a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020172c:	e589                	bnez	a1,ffffffffc0201736 <strnlen+0xc>
ffffffffc020172e:	a811                	j	ffffffffc0201742 <strnlen+0x18>
        cnt ++;
ffffffffc0201730:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201732:	00f58863          	beq	a1,a5,ffffffffc0201742 <strnlen+0x18>
ffffffffc0201736:	00f50733          	add	a4,a0,a5
ffffffffc020173a:	00074703          	lbu	a4,0(a4)
ffffffffc020173e:	fb6d                	bnez	a4,ffffffffc0201730 <strnlen+0x6>
ffffffffc0201740:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201742:	852e                	mv	a0,a1
ffffffffc0201744:	8082                	ret

ffffffffc0201746 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201746:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020174a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020174e:	cb89                	beqz	a5,ffffffffc0201760 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201750:	0505                	addi	a0,a0,1
ffffffffc0201752:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201754:	fee789e3          	beq	a5,a4,ffffffffc0201746 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201758:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020175c:	9d19                	subw	a0,a0,a4
ffffffffc020175e:	8082                	ret
ffffffffc0201760:	4501                	li	a0,0
ffffffffc0201762:	bfed                	j	ffffffffc020175c <strcmp+0x16>

ffffffffc0201764 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201764:	00054783          	lbu	a5,0(a0)
ffffffffc0201768:	c799                	beqz	a5,ffffffffc0201776 <strchr+0x12>
        if (*s == c) {
ffffffffc020176a:	00f58763          	beq	a1,a5,ffffffffc0201778 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020176e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201772:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201774:	fbfd                	bnez	a5,ffffffffc020176a <strchr+0x6>
    }
    return NULL;
ffffffffc0201776:	4501                	li	a0,0
}
ffffffffc0201778:	8082                	ret

ffffffffc020177a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020177a:	ca01                	beqz	a2,ffffffffc020178a <memset+0x10>
ffffffffc020177c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020177e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201780:	0785                	addi	a5,a5,1
ffffffffc0201782:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201786:	fec79de3          	bne	a5,a2,ffffffffc0201780 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020178a:	8082                	ret
