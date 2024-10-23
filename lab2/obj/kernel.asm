
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
ffffffffc020004a:	638010ef          	jal	ra,ffffffffc0201682 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	64650513          	addi	a0,a0,1606 # ffffffffc0201698 <etext+0x4>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	747000ef          	jal	ra,ffffffffc0200fac <pmm_init>

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
ffffffffc02000a6:	106010ef          	jal	ra,ffffffffc02011ac <vprintfmt>
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
ffffffffc02000dc:	0d0010ef          	jal	ra,ffffffffc02011ac <vprintfmt>
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
ffffffffc0200140:	57c50513          	addi	a0,a0,1404 # ffffffffc02016b8 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00001517          	auipc	a0,0x1
ffffffffc0200156:	58650513          	addi	a0,a0,1414 # ffffffffc02016d8 <etext+0x44>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00001597          	auipc	a1,0x1
ffffffffc0200162:	53658593          	addi	a1,a1,1334 # ffffffffc0201694 <etext>
ffffffffc0200166:	00001517          	auipc	a0,0x1
ffffffffc020016a:	59250513          	addi	a0,a0,1426 # ffffffffc02016f8 <etext+0x64>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <free_area>
ffffffffc020017a:	00001517          	auipc	a0,0x1
ffffffffc020017e:	59e50513          	addi	a0,a0,1438 # ffffffffc0201718 <etext+0x84>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3da58593          	addi	a1,a1,986 # ffffffffc0206560 <end>
ffffffffc020018e:	00001517          	auipc	a0,0x1
ffffffffc0200192:	5aa50513          	addi	a0,a0,1450 # ffffffffc0201738 <etext+0xa4>
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
ffffffffc02001c0:	59c50513          	addi	a0,a0,1436 # ffffffffc0201758 <etext+0xc4>
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
ffffffffc02001ce:	5be60613          	addi	a2,a2,1470 # ffffffffc0201788 <etext+0xf4>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	5ca50513          	addi	a0,a0,1482 # ffffffffc02017a0 <etext+0x10c>
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
ffffffffc02001ea:	5d260613          	addi	a2,a2,1490 # ffffffffc02017b8 <etext+0x124>
ffffffffc02001ee:	00001597          	auipc	a1,0x1
ffffffffc02001f2:	5ea58593          	addi	a1,a1,1514 # ffffffffc02017d8 <etext+0x144>
ffffffffc02001f6:	00001517          	auipc	a0,0x1
ffffffffc02001fa:	5ea50513          	addi	a0,a0,1514 # ffffffffc02017e0 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00001617          	auipc	a2,0x1
ffffffffc0200208:	5ec60613          	addi	a2,a2,1516 # ffffffffc02017f0 <etext+0x15c>
ffffffffc020020c:	00001597          	auipc	a1,0x1
ffffffffc0200210:	60c58593          	addi	a1,a1,1548 # ffffffffc0201818 <etext+0x184>
ffffffffc0200214:	00001517          	auipc	a0,0x1
ffffffffc0200218:	5cc50513          	addi	a0,a0,1484 # ffffffffc02017e0 <etext+0x14c>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00001617          	auipc	a2,0x1
ffffffffc0200224:	60860613          	addi	a2,a2,1544 # ffffffffc0201828 <etext+0x194>
ffffffffc0200228:	00001597          	auipc	a1,0x1
ffffffffc020022c:	62058593          	addi	a1,a1,1568 # ffffffffc0201848 <etext+0x1b4>
ffffffffc0200230:	00001517          	auipc	a0,0x1
ffffffffc0200234:	5b050513          	addi	a0,a0,1456 # ffffffffc02017e0 <etext+0x14c>
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
ffffffffc020026e:	5ee50513          	addi	a0,a0,1518 # ffffffffc0201858 <etext+0x1c4>
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
ffffffffc0200290:	5f450513          	addi	a0,a0,1524 # ffffffffc0201880 <etext+0x1ec>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00001c17          	auipc	s8,0x1
ffffffffc02002a6:	64ec0c13          	addi	s8,s8,1614 # ffffffffc02018f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00001917          	auipc	s2,0x1
ffffffffc02002ae:	5fe90913          	addi	s2,s2,1534 # ffffffffc02018a8 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00001497          	auipc	s1,0x1
ffffffffc02002b6:	5fe48493          	addi	s1,s1,1534 # ffffffffc02018b0 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00001b17          	auipc	s6,0x1
ffffffffc02002c0:	5fcb0b13          	addi	s6,s6,1532 # ffffffffc02018b8 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002c4:	00001a17          	auipc	s4,0x1
ffffffffc02002c8:	514a0a13          	addi	s4,s4,1300 # ffffffffc02017d8 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	25e010ef          	jal	ra,ffffffffc020152e <readline>
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
ffffffffc02002ea:	60ad0d13          	addi	s10,s10,1546 # ffffffffc02018f0 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	35a010ef          	jal	ra,ffffffffc020164e <strcmp>
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
ffffffffc0200308:	346010ef          	jal	ra,ffffffffc020164e <strcmp>
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
ffffffffc0200346:	326010ef          	jal	ra,ffffffffc020166c <strchr>
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
ffffffffc0200384:	2e8010ef          	jal	ra,ffffffffc020166c <strchr>
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
ffffffffc02003a2:	53a50513          	addi	a0,a0,1338 # ffffffffc02018d8 <etext+0x244>
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
ffffffffc02003de:	55e50513          	addi	a0,a0,1374 # ffffffffc0201938 <commands+0x48>
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
ffffffffc02003f4:	39050513          	addi	a0,a0,912 # ffffffffc0201780 <etext+0xec>
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
ffffffffc0200420:	1dc010ef          	jal	ra,ffffffffc02015fc <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0206520 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00001517          	auipc	a0,0x1
ffffffffc0200432:	52a50513          	addi	a0,a0,1322 # ffffffffc0201958 <commands+0x68>
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
ffffffffc0200446:	1b60106f          	j	ffffffffc02015fc <sbi_set_timer>

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
ffffffffc0200450:	1920106f          	j	ffffffffc02015e2 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	1c20106f          	j	ffffffffc0201616 <sbi_console_getchar>

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
ffffffffc0200482:	4fa50513          	addi	a0,a0,1274 # ffffffffc0201978 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00001517          	auipc	a0,0x1
ffffffffc0200492:	50250513          	addi	a0,a0,1282 # ffffffffc0201990 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00001517          	auipc	a0,0x1
ffffffffc02004a0:	50c50513          	addi	a0,a0,1292 # ffffffffc02019a8 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00001517          	auipc	a0,0x1
ffffffffc02004ae:	51650513          	addi	a0,a0,1302 # ffffffffc02019c0 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00001517          	auipc	a0,0x1
ffffffffc02004bc:	52050513          	addi	a0,a0,1312 # ffffffffc02019d8 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00001517          	auipc	a0,0x1
ffffffffc02004ca:	52a50513          	addi	a0,a0,1322 # ffffffffc02019f0 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00001517          	auipc	a0,0x1
ffffffffc02004d8:	53450513          	addi	a0,a0,1332 # ffffffffc0201a08 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00001517          	auipc	a0,0x1
ffffffffc02004e6:	53e50513          	addi	a0,a0,1342 # ffffffffc0201a20 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00001517          	auipc	a0,0x1
ffffffffc02004f4:	54850513          	addi	a0,a0,1352 # ffffffffc0201a38 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00001517          	auipc	a0,0x1
ffffffffc0200502:	55250513          	addi	a0,a0,1362 # ffffffffc0201a50 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00001517          	auipc	a0,0x1
ffffffffc0200510:	55c50513          	addi	a0,a0,1372 # ffffffffc0201a68 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	56650513          	addi	a0,a0,1382 # ffffffffc0201a80 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	57050513          	addi	a0,a0,1392 # ffffffffc0201a98 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00001517          	auipc	a0,0x1
ffffffffc020053a:	57a50513          	addi	a0,a0,1402 # ffffffffc0201ab0 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00001517          	auipc	a0,0x1
ffffffffc0200548:	58450513          	addi	a0,a0,1412 # ffffffffc0201ac8 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00001517          	auipc	a0,0x1
ffffffffc0200556:	58e50513          	addi	a0,a0,1422 # ffffffffc0201ae0 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00001517          	auipc	a0,0x1
ffffffffc0200564:	59850513          	addi	a0,a0,1432 # ffffffffc0201af8 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00001517          	auipc	a0,0x1
ffffffffc0200572:	5a250513          	addi	a0,a0,1442 # ffffffffc0201b10 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00001517          	auipc	a0,0x1
ffffffffc0200580:	5ac50513          	addi	a0,a0,1452 # ffffffffc0201b28 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00001517          	auipc	a0,0x1
ffffffffc020058e:	5b650513          	addi	a0,a0,1462 # ffffffffc0201b40 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	5c050513          	addi	a0,a0,1472 # ffffffffc0201b58 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00001517          	auipc	a0,0x1
ffffffffc02005aa:	5ca50513          	addi	a0,a0,1482 # ffffffffc0201b70 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	5d450513          	addi	a0,a0,1492 # ffffffffc0201b88 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	5de50513          	addi	a0,a0,1502 # ffffffffc0201ba0 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00001517          	auipc	a0,0x1
ffffffffc02005d4:	5e850513          	addi	a0,a0,1512 # ffffffffc0201bb8 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	5f250513          	addi	a0,a0,1522 # ffffffffc0201bd0 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	5fc50513          	addi	a0,a0,1532 # ffffffffc0201be8 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00001517          	auipc	a0,0x1
ffffffffc02005fe:	60650513          	addi	a0,a0,1542 # ffffffffc0201c00 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	61050513          	addi	a0,a0,1552 # ffffffffc0201c18 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00001517          	auipc	a0,0x1
ffffffffc020061a:	61a50513          	addi	a0,a0,1562 # ffffffffc0201c30 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	62450513          	addi	a0,a0,1572 # ffffffffc0201c48 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00001517          	auipc	a0,0x1
ffffffffc020063a:	62a50513          	addi	a0,a0,1578 # ffffffffc0201c60 <commands+0x370>
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
ffffffffc020064e:	62e50513          	addi	a0,a0,1582 # ffffffffc0201c78 <commands+0x388>
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
ffffffffc0200666:	62e50513          	addi	a0,a0,1582 # ffffffffc0201c90 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00001517          	auipc	a0,0x1
ffffffffc0200676:	63650513          	addi	a0,a0,1590 # ffffffffc0201ca8 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00001517          	auipc	a0,0x1
ffffffffc0200686:	63e50513          	addi	a0,a0,1598 # ffffffffc0201cc0 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00001517          	auipc	a0,0x1
ffffffffc020069a:	64250513          	addi	a0,a0,1602 # ffffffffc0201cd8 <commands+0x3e8>
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
ffffffffc02006b4:	70870713          	addi	a4,a4,1800 # ffffffffc0201db8 <commands+0x4c8>
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
ffffffffc02006c6:	68e50513          	addi	a0,a0,1678 # ffffffffc0201d50 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	66450513          	addi	a0,a0,1636 # ffffffffc0201d30 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00001517          	auipc	a0,0x1
ffffffffc02006da:	61a50513          	addi	a0,a0,1562 # ffffffffc0201cf0 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00001517          	auipc	a0,0x1
ffffffffc02006e4:	69050513          	addi	a0,a0,1680 # ffffffffc0201d70 <commands+0x480>
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
ffffffffc0200714:	68850513          	addi	a0,a0,1672 # ffffffffc0201d98 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	5f650513          	addi	a0,a0,1526 # ffffffffc0201d10 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	65c50513          	addi	a0,a0,1628 # ffffffffc0201d88 <commands+0x498>
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
    for (int i = 0; i < MAX_ORDER; i++) {
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
        list_init(&free_area[i].free_list); // 初始化每个阶的空闲列表
        free_area[i].nr_free = 0; // 初始化每个阶的空闲页面计数
ffffffffc0200816:	0007a823          	sw	zero,16(a5)
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc020081a:	07e1                	addi	a5,a5,24
ffffffffc020081c:	fee79be3          	bne	a5,a4,ffffffffc0200812 <buddy_init+0x10>
    }
}
ffffffffc0200820:	8082                	ret

ffffffffc0200822 <merge_page>:
        return buddy_alloc_pages(n); // 递归调用以重新分配
    }
}

static void merge_page(size_t order, struct Page *base) {
    if (order >= MAX_ORDER) return; // 超过最大阶数则返回
ffffffffc0200822:	47a9                	li	a5,10
ffffffffc0200824:	06a7e763          	bltu	a5,a0,ffffffffc0200892 <merge_page+0x70>
ffffffffc0200828:	00151793          	slli	a5,a0,0x1
ffffffffc020082c:	953e                	add	a0,a0,a5
ffffffffc020082e:	050e                	slli	a0,a0,0x3
ffffffffc0200830:	00005797          	auipc	a5,0x5
ffffffffc0200834:	7e078793          	addi	a5,a5,2016 # ffffffffc0206010 <free_area>
ffffffffc0200838:	97aa                	add	a5,a5,a0
ffffffffc020083a:	00006317          	auipc	t1,0x6
ffffffffc020083e:	8de30313          	addi	t1,t1,-1826 # ffffffffc0206118 <buf>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200842:	5e75                	li	t3,-3
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200844:	6d94                	ld	a3,24(a1)

    list_entry_t *le = list_prev(&(base->page_link));
    if (le != &(free_area[order].free_list)) {
ffffffffc0200846:	01878513          	addi	a0,a5,24
        struct Page *prev_page = le2page(le, page_link);
ffffffffc020084a:	fe868813          	addi	a6,a3,-24
    if (le != &(free_area[order].free_list)) {
ffffffffc020084e:	00f68e63          	beq	a3,a5,ffffffffc020086a <merge_page+0x48>
        if (prev_page + prev_page->property == base) {
ffffffffc0200852:	ff86a883          	lw	a7,-8(a3)
ffffffffc0200856:	02089613          	slli	a2,a7,0x20
ffffffffc020085a:	9201                	srli	a2,a2,0x20
ffffffffc020085c:	00261713          	slli	a4,a2,0x2
ffffffffc0200860:	9732                	add	a4,a4,a2
ffffffffc0200862:	070e                	slli	a4,a4,0x3
ffffffffc0200864:	9742                	add	a4,a4,a6
ffffffffc0200866:	02e58763          	beq	a1,a4,ffffffffc0200894 <merge_page+0x72>
    return listelm->next;
ffffffffc020086a:	7190                	ld	a2,32(a1)
        }
    }

    le = list_next(&(base->page_link));
    if (le != &(free_area[order].free_list)) {
        struct Page *next_page = le2page(le, page_link);
ffffffffc020086c:	fe860813          	addi	a6,a2,-24
    if (le != &(free_area[order].free_list)) {
ffffffffc0200870:	00f60e63          	beq	a2,a5,ffffffffc020088c <merge_page+0x6a>
        if (base + base->property == next_page) {
ffffffffc0200874:	0105a883          	lw	a7,16(a1)
ffffffffc0200878:	02089693          	slli	a3,a7,0x20
ffffffffc020087c:	9281                	srli	a3,a3,0x20
ffffffffc020087e:	00269713          	slli	a4,a3,0x2
ffffffffc0200882:	9736                	add	a4,a4,a3
ffffffffc0200884:	070e                	slli	a4,a4,0x3
ffffffffc0200886:	972e                	add	a4,a4,a1
ffffffffc0200888:	05070563          	beq	a4,a6,ffffffffc02008d2 <merge_page+0xb0>
    if (order >= MAX_ORDER) return; // 超过最大阶数则返回
ffffffffc020088c:	87aa                	mv	a5,a0
ffffffffc020088e:	faa31be3          	bne	t1,a0,ffffffffc0200844 <merge_page+0x22>
            free_area[order + 1].nr_free++; // 更新空闲页面计数
        }
    }

    merge_page(order + 1, base); // 递归合并相邻页面
}
ffffffffc0200892:	8082                	ret
            prev_page->property += base->property; // 合并相邻的页面
ffffffffc0200894:	4998                	lw	a4,16(a1)
ffffffffc0200896:	011708bb          	addw	a7,a4,a7
ffffffffc020089a:	ff16ac23          	sw	a7,-8(a3)
ffffffffc020089e:	00858713          	addi	a4,a1,8
ffffffffc02008a2:	61c7302f          	amoand.d	zero,t3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02008a6:	7190                	ld	a2,32(a1)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc02008a8:	5798                	lw	a4,40(a5)
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
    elm->next = next;
    elm->prev = prev;
ffffffffc02008aa:	01878513          	addi	a0,a5,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02008ae:	e690                	sd	a2,8(a3)
    next->prev = prev;
ffffffffc02008b0:	e214                	sd	a3,0(a2)
    __list_del(listelm->prev, listelm->next);
ffffffffc02008b2:	0006b883          	ld	a7,0(a3)
ffffffffc02008b6:	6690                	ld	a2,8(a3)
ffffffffc02008b8:	2705                	addiw	a4,a4,1
            base = prev_page; // 更新基地址
ffffffffc02008ba:	85c2                	mv	a1,a6
    prev->next = next;
ffffffffc02008bc:	00c8b423          	sd	a2,8(a7)
    next->prev = prev;
ffffffffc02008c0:	01163023          	sd	a7,0(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008c4:	7390                	ld	a2,32(a5)
    prev->next = next->prev = elm;
ffffffffc02008c6:	e214                	sd	a3,0(a2)
ffffffffc02008c8:	f394                	sd	a3,32(a5)
    elm->next = next;
ffffffffc02008ca:	e690                	sd	a2,8(a3)
    elm->prev = prev;
ffffffffc02008cc:	e288                	sd	a0,0(a3)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc02008ce:	d798                	sw	a4,40(a5)
ffffffffc02008d0:	bf71                	j	ffffffffc020086c <merge_page+0x4a>
            base->property += next_page->property; // 合并相邻的页面
ffffffffc02008d2:	ff862703          	lw	a4,-8(a2)
ffffffffc02008d6:	011708bb          	addw	a7,a4,a7
ffffffffc02008da:	0115a823          	sw	a7,16(a1)
ffffffffc02008de:	ff060713          	addi	a4,a2,-16
ffffffffc02008e2:	61c7302f          	amoand.d	zero,t3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02008e6:	00063803          	ld	a6,0(a2)
ffffffffc02008ea:	6610                	ld	a2,8(a2)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc02008ec:	5794                	lw	a3,40(a5)
            list_add(&(free_area[order + 1].free_list), &(base->page_link)); // 将合并后的页面加入空闲列表
ffffffffc02008ee:	01858713          	addi	a4,a1,24
    prev->next = next;
ffffffffc02008f2:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc02008f6:	01063023          	sd	a6,0(a2)
    __list_del(listelm->prev, listelm->next);
ffffffffc02008fa:	0185b803          	ld	a6,24(a1)
ffffffffc02008fe:	7190                	ld	a2,32(a1)
            free_area[order + 1].nr_free++; // 更新空闲页面计数
ffffffffc0200900:	2685                	addiw	a3,a3,1
    prev->next = next;
ffffffffc0200902:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200906:	01063023          	sd	a6,0(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020090a:	7390                	ld	a2,32(a5)
    prev->next = next->prev = elm;
ffffffffc020090c:	e218                	sd	a4,0(a2)
ffffffffc020090e:	f398                	sd	a4,32(a5)
    elm->next = next;
ffffffffc0200910:	f190                	sd	a2,32(a1)
    elm->prev = prev;
ffffffffc0200912:	ed88                	sd	a0,24(a1)
ffffffffc0200914:	d794                	sw	a3,40(a5)
ffffffffc0200916:	bf9d                	j	ffffffffc020088c <merge_page+0x6a>

ffffffffc0200918 <buddy_free_pages>:

static void buddy_free_pages(struct Page *base, size_t n) {
    struct Page *p = base;
    for (; p < base + n; p++) {
ffffffffc0200918:	00259693          	slli	a3,a1,0x2
ffffffffc020091c:	96ae                	add	a3,a3,a1
ffffffffc020091e:	068e                	slli	a3,a3,0x3
ffffffffc0200920:	96aa                	add	a3,a3,a0
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200922:	872e                	mv	a4,a1
    for (; p < base + n; p++) {
ffffffffc0200924:	87aa                	mv	a5,a0
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200926:	85aa                	mv	a1,a0
    for (; p < base + n; p++) {
ffffffffc0200928:	00d57a63          	bgeu	a0,a3,ffffffffc020093c <buddy_free_pages+0x24>
        //assert(!PageReserved(p) && !PageProperty(p)); // 确保释放的页面是可用的
        p->flags = 0; // 清除标志
ffffffffc020092c:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200930:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++) {
ffffffffc0200934:	02878793          	addi	a5,a5,40
ffffffffc0200938:	fed7eae3          	bltu	a5,a3,ffffffffc020092c <buddy_free_pages+0x14>
        set_page_ref(p, 0); // 设置引用计数为 0
    }
    base->property = n; // 设置释放页面的属性
ffffffffc020093c:	c998                	sw	a4,16(a1)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020093e:	4789                	li	a5,2
ffffffffc0200940:	00858693          	addi	a3,a1,8
ffffffffc0200944:	40f6b02f          	amoor.d	zero,a5,(a3)
    SetPageProperty(base); // 标记该页为页表

    size_t order = 0;
    while (n > 1) {
ffffffffc0200948:	4685                	li	a3,1
    size_t order = 0;
ffffffffc020094a:	4781                	li	a5,0
    while (n > 1) {
ffffffffc020094c:	4605                	li	a2,1
ffffffffc020094e:	04e6f763          	bgeu	a3,a4,ffffffffc020099c <buddy_free_pages+0x84>
        n >>= 1; // 计算阶数
ffffffffc0200952:	8305                	srli	a4,a4,0x1
        order++;
ffffffffc0200954:	86be                	mv	a3,a5
ffffffffc0200956:	0785                	addi	a5,a5,1
    while (n > 1) {
ffffffffc0200958:	fec71de3          	bne	a4,a2,ffffffffc0200952 <buddy_free_pages+0x3a>
    }
    order++; // 增加阶数
ffffffffc020095c:	00268513          	addi	a0,a3,2
ffffffffc0200960:	00151793          	slli	a5,a0,0x1
ffffffffc0200964:	00a78733          	add	a4,a5,a0
ffffffffc0200968:	00371613          	slli	a2,a4,0x3
    __list_add(elm, listelm->prev, listelm);
ffffffffc020096c:	97aa                	add	a5,a5,a0
ffffffffc020096e:	00005717          	auipc	a4,0x5
ffffffffc0200972:	6a270713          	addi	a4,a4,1698 # ffffffffc0206010 <free_area>
ffffffffc0200976:	078e                	slli	a5,a5,0x3
ffffffffc0200978:	97ba                	add	a5,a5,a4
ffffffffc020097a:	0007b803          	ld	a6,0(a5)

    list_entry_t *le = &(free_area[order].free_list);
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc020097e:	4b94                	lw	a3,16(a5)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0200980:	01858893          	addi	a7,a1,24
    prev->next = next->prev = elm;
ffffffffc0200984:	0117b023          	sd	a7,0(a5)
ffffffffc0200988:	01183423          	sd	a7,8(a6)
    list_entry_t *le = &(free_area[order].free_list);
ffffffffc020098c:	9732                	add	a4,a4,a2
    elm->next = next;
ffffffffc020098e:	f198                	sd	a4,32(a1)
    elm->prev = prev;
ffffffffc0200990:	0105bc23          	sd	a6,24(a1)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200994:	0016871b          	addiw	a4,a3,1
ffffffffc0200998:	cb98                	sw	a4,16(a5)

    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc020099a:	b561                	j	ffffffffc0200822 <merge_page>
    while (n > 1) {
ffffffffc020099c:	4505                	li	a0,1
ffffffffc020099e:	4661                	li	a2,24
ffffffffc02009a0:	4789                	li	a5,2
ffffffffc02009a2:	b7e9                	j	ffffffffc020096c <buddy_free_pages+0x54>

ffffffffc02009a4 <buddy_nr_free_pages>:
}

static size_t buddy_nr_free_pages(void) {
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02009a4:	00005697          	auipc	a3,0x5
ffffffffc02009a8:	67c68693          	addi	a3,a3,1660 # ffffffffc0206020 <free_area+0x10>
ffffffffc02009ac:	4781                	li	a5,0
    size_t total = 0;
ffffffffc02009ae:	4501                	li	a0,0
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02009b0:	462d                	li	a2,11
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc02009b2:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02009b6:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc02009b8:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02009bc:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc02009be:	953a                	add	a0,a0,a4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02009c0:	fec799e3          	bne	a5,a2,ffffffffc02009b2 <buddy_nr_free_pages+0xe>
    }
    return total; // 返回总的空闲页面数
}
ffffffffc02009c4:	8082                	ret

ffffffffc02009c6 <buddy_alloc_pages>:
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc02009c6:	00005817          	auipc	a6,0x5
ffffffffc02009ca:	64a80813          	addi	a6,a6,1610 # ffffffffc0206010 <free_area>
    if (free_area[order].nr_free > 0) { // 如果当前阶有空闲页面
ffffffffc02009ce:	01082f03          	lw	t5,16(a6)
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc02009d2:	1141                	addi	sp,sp,-16
ffffffffc02009d4:	e406                	sd	ra,8(sp)
ffffffffc02009d6:	e022                	sd	s0,0(sp)
    while ((1 << order) < n) {
ffffffffc02009d8:	4305                	li	t1,1
ffffffffc02009da:	4605                	li	a2,1
    if (order >= MAX_ORDER) return NULL; // 请求的页面数超过最大阶数
ffffffffc02009dc:	48a9                	li	a7,10
    while (n < MAX_ORDER && free_area[n].nr_free == 0) {
ffffffffc02009de:	45ad                	li	a1,11
ffffffffc02009e0:	4e09                	li	t3,2
    assert(n > 0);
ffffffffc02009e2:	10050a63          	beqz	a0,ffffffffc0200af6 <buddy_alloc_pages+0x130>
    size_t order = 0;
ffffffffc02009e6:	4701                	li	a4,0
    while ((1 << order) < n) {
ffffffffc02009e8:	0c650563          	beq	a0,t1,ffffffffc0200ab2 <buddy_alloc_pages+0xec>
        order++; // 计算所需的阶数
ffffffffc02009ec:	87ba                	mv	a5,a4
ffffffffc02009ee:	0705                	addi	a4,a4,1
    while ((1 << order) < n) {
ffffffffc02009f0:	00e616bb          	sllw	a3,a2,a4
ffffffffc02009f4:	fea6ece3          	bltu	a3,a0,ffffffffc02009ec <buddy_alloc_pages+0x26>
    if (order >= MAX_ORDER) return NULL; // 请求的页面数超过最大阶数
ffffffffc02009f8:	0ce8e163          	bltu	a7,a4,ffffffffc0200aba <buddy_alloc_pages+0xf4>
    if (free_area[order].nr_free > 0) { // 如果当前阶有空闲页面
ffffffffc02009fc:	00171e93          	slli	t4,a4,0x1
ffffffffc0200a00:	00ee86b3          	add	a3,t4,a4
ffffffffc0200a04:	068e                	slli	a3,a3,0x3
ffffffffc0200a06:	96c2                	add	a3,a3,a6
ffffffffc0200a08:	4a94                	lw	a3,16(a3)
ffffffffc0200a0a:	eedd                	bnez	a3,ffffffffc0200ac8 <buddy_alloc_pages+0x102>
        cut_page(order + 1); // 切割页面以获取所需大小
ffffffffc0200a0c:	0789                	addi	a5,a5,2
    while (n < MAX_ORDER && free_area[n].nr_free == 0) {
ffffffffc0200a0e:	fcf8eae3          	bltu	a7,a5,ffffffffc02009e2 <buddy_alloc_pages+0x1c>
ffffffffc0200a12:	00179713          	slli	a4,a5,0x1
ffffffffc0200a16:	973e                	add	a4,a4,a5
ffffffffc0200a18:	070e                	slli	a4,a4,0x3
ffffffffc0200a1a:	0741                	addi	a4,a4,16
ffffffffc0200a1c:	9742                	add	a4,a4,a6
ffffffffc0200a1e:	a029                	j	ffffffffc0200a28 <buddy_alloc_pages+0x62>
        n++; // 查找下一个有空闲页面的阶
ffffffffc0200a20:	0785                	addi	a5,a5,1
    while (n < MAX_ORDER && free_area[n].nr_free == 0) {
ffffffffc0200a22:	0761                	addi	a4,a4,24
ffffffffc0200a24:	fab78fe3          	beq	a5,a1,ffffffffc02009e2 <buddy_alloc_pages+0x1c>
ffffffffc0200a28:	4314                	lw	a3,0(a4)
ffffffffc0200a2a:	dafd                	beqz	a3,ffffffffc0200a20 <buddy_alloc_pages+0x5a>
    return listelm->next;
ffffffffc0200a2c:	00179f13          	slli	t5,a5,0x1
ffffffffc0200a30:	9f3e                	add	t5,t5,a5
ffffffffc0200a32:	0f0e                	slli	t5,t5,0x3
ffffffffc0200a34:	9f42                	add	t5,t5,a6
ffffffffc0200a36:	008f3e83          	ld	t4,8(t5)
    size_t i = n - 1; // 减小阶数
ffffffffc0200a3a:	17fd                	addi	a5,a5,-1
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200a3c:	00f6143b          	sllw	s0,a2,a5
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a40:	000eb383          	ld	t2,0(t4)
ffffffffc0200a44:	008eb283          	ld	t0,8(t4)
ffffffffc0200a48:	00241713          	slli	a4,s0,0x2
ffffffffc0200a4c:	9722                	add	a4,a4,s0
    prev->next = next;
ffffffffc0200a4e:	0053b423          	sd	t0,8(t2)
ffffffffc0200a52:	070e                	slli	a4,a4,0x3
    next->prev = prev;
ffffffffc0200a54:	0072b023          	sd	t2,0(t0)
    free_area[n].nr_free--; // 更新空闲页面计数
ffffffffc0200a58:	36fd                	addiw	a3,a3,-1
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200a5a:	1721                	addi	a4,a4,-24
    free_area[n].nr_free--; // 更新空闲页面计数
ffffffffc0200a5c:	00df2823          	sw	a3,16(t5)
    struct Page *buddy_page = page + (1 << i); // 计算伙伴页的地址
ffffffffc0200a60:	00ee86b3          	add	a3,t4,a4
    buddy_page->property = (1 << i); // 设置伙伴页的属性
ffffffffc0200a64:	ca80                	sw	s0,16(a3)
    page->property = (1 << i); // 设置当前页的属性
ffffffffc0200a66:	fe8eac23          	sw	s0,-8(t4)
ffffffffc0200a6a:	00868713          	addi	a4,a3,8
ffffffffc0200a6e:	41c7302f          	amoor.d	zero,t3,(a4)
    list_add(&(free_area[i].free_list), &(page->page_link)); // 将当前页加入到较小阶的空闲列表
ffffffffc0200a72:	00179713          	slli	a4,a5,0x1
ffffffffc0200a76:	97ba                	add	a5,a5,a4
ffffffffc0200a78:	078e                	slli	a5,a5,0x3
ffffffffc0200a7a:	97c2                	add	a5,a5,a6
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a7c:	0087bf03          	ld	t5,8(a5)
    free_area[i].nr_free += 2; // 更新空闲页面计数
ffffffffc0200a80:	4b98                	lw	a4,16(a5)
    list_add(&(buddy_page->page_link), &(free_area[i].free_list)); // 将伙伴页加入到空闲列表
ffffffffc0200a82:	01868f93          	addi	t6,a3,24
    prev->next = next->prev = elm;
ffffffffc0200a86:	01df3023          	sd	t4,0(t5)
ffffffffc0200a8a:	01d7b423          	sd	t4,8(a5)
    elm->next = next;
ffffffffc0200a8e:	01eeb423          	sd	t5,8(t4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a92:	0206bf03          	ld	t5,32(a3)
    elm->prev = prev;
ffffffffc0200a96:	00feb023          	sd	a5,0(t4)
    free_area[i].nr_free += 2; // 更新空闲页面计数
ffffffffc0200a9a:	2709                	addiw	a4,a4,2
    prev->next = next->prev = elm;
ffffffffc0200a9c:	00ff3023          	sd	a5,0(t5)
ffffffffc0200aa0:	f29c                	sd	a5,32(a3)
ffffffffc0200aa2:	cb98                	sw	a4,16(a5)
    elm->next = next;
ffffffffc0200aa4:	01e7b423          	sd	t5,8(a5)
    elm->prev = prev;
ffffffffc0200aa8:	01f7b023          	sd	t6,0(a5)
    if (free_area[order].nr_free > 0) { // 如果当前阶有空闲页面
ffffffffc0200aac:	01082f03          	lw	t5,16(a6)
ffffffffc0200ab0:	bf0d                	j	ffffffffc02009e2 <buddy_alloc_pages+0x1c>
ffffffffc0200ab2:	000f1963          	bnez	t5,ffffffffc0200ac4 <buddy_alloc_pages+0xfe>
        cut_page(order + 1); // 切割页面以获取所需大小
ffffffffc0200ab6:	4785                	li	a5,1
ffffffffc0200ab8:	bfa9                	j	ffffffffc0200a12 <buddy_alloc_pages+0x4c>
}
ffffffffc0200aba:	60a2                	ld	ra,8(sp)
ffffffffc0200abc:	6402                	ld	s0,0(sp)
    if (order >= MAX_ORDER) return NULL; // 请求的页面数超过最大阶数
ffffffffc0200abe:	4501                	li	a0,0
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
ffffffffc0200ac2:	8082                	ret
    if (free_area[order].nr_free > 0) { // 如果当前阶有空闲页面
ffffffffc0200ac4:	86fa                	mv	a3,t5
ffffffffc0200ac6:	4e81                	li	t4,0
    return listelm->next;
ffffffffc0200ac8:	00ee87b3          	add	a5,t4,a4
ffffffffc0200acc:	078e                	slli	a5,a5,0x3
ffffffffc0200ace:	983e                	add	a6,a6,a5
ffffffffc0200ad0:	00883783          	ld	a5,8(a6)
        free_area[order].nr_free--; // 更新空闲页面计数
ffffffffc0200ad4:	36fd                	addiw	a3,a3,-1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ad6:	6798                	ld	a4,8(a5)
ffffffffc0200ad8:	6390                	ld	a2,0(a5)
        struct Page *page = le2page(le, page_link); // 获取空闲页
ffffffffc0200ada:	fe878513          	addi	a0,a5,-24
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200ade:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200ae0:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200ae2:	e310                	sd	a2,0(a4)
        free_area[order].nr_free--; // 更新空闲页面计数
ffffffffc0200ae4:	00d82823          	sw	a3,16(a6)
ffffffffc0200ae8:	5775                	li	a4,-3
ffffffffc0200aea:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0200aee:	60a2                	ld	ra,8(sp)
ffffffffc0200af0:	6402                	ld	s0,0(sp)
ffffffffc0200af2:	0141                	addi	sp,sp,16
ffffffffc0200af4:	8082                	ret
    assert(n > 0);
ffffffffc0200af6:	00001697          	auipc	a3,0x1
ffffffffc0200afa:	2f268693          	addi	a3,a3,754 # ffffffffc0201de8 <commands+0x4f8>
ffffffffc0200afe:	00001617          	auipc	a2,0x1
ffffffffc0200b02:	2f260613          	addi	a2,a2,754 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200b06:	04400593          	li	a1,68
ffffffffc0200b0a:	00001517          	auipc	a0,0x1
ffffffffc0200b0e:	2fe50513          	addi	a0,a0,766 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200b12:	89bff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200b16 <buddy_init_memmap>:
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200b16:	1141                	addi	sp,sp,-16
ffffffffc0200b18:	e406                	sd	ra,8(sp)
    assert(n > 0); // 确保请求的页面数量大于 0
ffffffffc0200b1a:	c5d5                	beqz	a1,ffffffffc0200bc6 <buddy_init_memmap+0xb0>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200b1c:	00259693          	slli	a3,a1,0x2
ffffffffc0200b20:	96ae                	add	a3,a3,a1
ffffffffc0200b22:	068e                	slli	a3,a3,0x3
ffffffffc0200b24:	96aa                	add	a3,a3,a0
ffffffffc0200b26:	87aa                	mv	a5,a0
ffffffffc0200b28:	00d50f63          	beq	a0,a3,ffffffffc0200b46 <buddy_init_memmap+0x30>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b2c:	6798                	ld	a4,8(a5)
        assert(PageReserved(p)); // 确保页面是保留的
ffffffffc0200b2e:	8b05                	andi	a4,a4,1
ffffffffc0200b30:	cf25                	beqz	a4,ffffffffc0200ba8 <buddy_init_memmap+0x92>
        p->flags = p->property = 0; // 清除标志和属性
ffffffffc0200b32:	0007a823          	sw	zero,16(a5)
ffffffffc0200b36:	0007b423          	sd	zero,8(a5)
ffffffffc0200b3a:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200b3e:	02878793          	addi	a5,a5,40
ffffffffc0200b42:	fed795e3          	bne	a5,a3,ffffffffc0200b2c <buddy_init_memmap+0x16>
    size_t order = MAX_ORDER - 1;
ffffffffc0200b46:	4729                	li	a4,10
    size_t order_size = 1 << order; // 计算当前阶的大小
ffffffffc0200b48:	40000793          	li	a5,1024
ffffffffc0200b4c:	00005e17          	auipc	t3,0x5
ffffffffc0200b50:	4c4e0e13          	addi	t3,t3,1220 # ffffffffc0206010 <free_area>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200b54:	4309                	li	t1,2
        p->property = order_size;
ffffffffc0200b56:	c91c                	sw	a5,16(a0)
ffffffffc0200b58:	00850693          	addi	a3,a0,8
ffffffffc0200b5c:	4066b02f          	amoor.d	zero,t1,(a3)
        free_area[order].nr_free++;
ffffffffc0200b60:	00171693          	slli	a3,a4,0x1
ffffffffc0200b64:	96ba                	add	a3,a3,a4
ffffffffc0200b66:	068e                	slli	a3,a3,0x3
ffffffffc0200b68:	96f2                	add	a3,a3,t3
ffffffffc0200b6a:	0106a803          	lw	a6,16(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b6e:	0086b883          	ld	a7,8(a3)
        list_add(&(free_area[order].free_list), &(p->page_link)); // 将页加入空闲列表
ffffffffc0200b72:	01850613          	addi	a2,a0,24
        free_area[order].nr_free++;
ffffffffc0200b76:	2805                	addiw	a6,a6,1
ffffffffc0200b78:	0106a823          	sw	a6,16(a3)
    prev->next = next->prev = elm;
ffffffffc0200b7c:	00c8b023          	sd	a2,0(a7)
ffffffffc0200b80:	e690                	sd	a2,8(a3)
    elm->next = next;
ffffffffc0200b82:	03153023          	sd	a7,32(a0)
    elm->prev = prev;
ffffffffc0200b86:	ed14                	sd	a3,24(a0)
        origin_size -= order_size; // 减少剩余未处理的页面数量
ffffffffc0200b88:	8d9d                	sub	a1,a1,a5
        while (order > 0 && origin_size < order_size) {
ffffffffc0200b8a:	c711                	beqz	a4,ffffffffc0200b96 <buddy_init_memmap+0x80>
ffffffffc0200b8c:	00f5f563          	bgeu	a1,a5,ffffffffc0200b96 <buddy_init_memmap+0x80>
            order--;
ffffffffc0200b90:	177d                	addi	a4,a4,-1
            order_size >>= 1;
ffffffffc0200b92:	8385                	srli	a5,a5,0x1
        while (order > 0 && origin_size < order_size) {
ffffffffc0200b94:	ff65                	bnez	a4,ffffffffc0200b8c <buddy_init_memmap+0x76>
    for (struct Page *p = base; origin_size != 0; p += order_size) {
ffffffffc0200b96:	00279693          	slli	a3,a5,0x2
ffffffffc0200b9a:	96be                	add	a3,a3,a5
ffffffffc0200b9c:	068e                	slli	a3,a3,0x3
ffffffffc0200b9e:	9536                	add	a0,a0,a3
ffffffffc0200ba0:	f9dd                	bnez	a1,ffffffffc0200b56 <buddy_init_memmap+0x40>
}
ffffffffc0200ba2:	60a2                	ld	ra,8(sp)
ffffffffc0200ba4:	0141                	addi	sp,sp,16
ffffffffc0200ba6:	8082                	ret
        assert(PageReserved(p)); // 确保页面是保留的
ffffffffc0200ba8:	00001697          	auipc	a3,0x1
ffffffffc0200bac:	27868693          	addi	a3,a3,632 # ffffffffc0201e20 <commands+0x530>
ffffffffc0200bb0:	00001617          	auipc	a2,0x1
ffffffffc0200bb4:	24060613          	addi	a2,a2,576 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200bb8:	45d9                	li	a1,22
ffffffffc0200bba:	00001517          	auipc	a0,0x1
ffffffffc0200bbe:	24e50513          	addi	a0,a0,590 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200bc2:	feaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0); // 确保请求的页面数量大于 0
ffffffffc0200bc6:	00001697          	auipc	a3,0x1
ffffffffc0200bca:	22268693          	addi	a3,a3,546 # ffffffffc0201de8 <commands+0x4f8>
ffffffffc0200bce:	00001617          	auipc	a2,0x1
ffffffffc0200bd2:	22260613          	addi	a2,a2,546 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200bd6:	45cd                	li	a1,19
ffffffffc0200bd8:	00001517          	auipc	a0,0x1
ffffffffc0200bdc:	23050513          	addi	a0,a0,560 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200be0:	fccff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200be4 <buddy_check>:

static void buddy_check(void) {
ffffffffc0200be4:	715d                	addi	sp,sp,-80
ffffffffc0200be6:	e0a2                	sd	s0,64(sp)
ffffffffc0200be8:	00005417          	auipc	s0,0x5
ffffffffc0200bec:	42840413          	addi	s0,s0,1064 # ffffffffc0206010 <free_area>
ffffffffc0200bf0:	e486                	sd	ra,72(sp)
ffffffffc0200bf2:	fc26                	sd	s1,56(sp)
ffffffffc0200bf4:	f84a                	sd	s2,48(sp)
ffffffffc0200bf6:	f44e                	sd	s3,40(sp)
ffffffffc0200bf8:	f052                	sd	s4,32(sp)
ffffffffc0200bfa:	ec56                	sd	s5,24(sp)
ffffffffc0200bfc:	e85a                	sd	s6,16(sp)
ffffffffc0200bfe:	e45e                	sd	s7,8(sp)
ffffffffc0200c00:	e062                	sd	s8,0(sp)
ffffffffc0200c02:	00005517          	auipc	a0,0x5
ffffffffc0200c06:	51650513          	addi	a0,a0,1302 # ffffffffc0206118 <buf>
ffffffffc0200c0a:	85a2                	mv	a1,s0
    int total_free_pages = 0;
ffffffffc0200c0c:	4601                	li	a2,0
    return listelm->next;
ffffffffc0200c0e:	659c                	ld	a5,8(a1)

    // 检查每个阶数的空闲列表
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
        int count = 0;
ffffffffc0200c10:	4681                	li	a3,0
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200c12:	00b78f63          	beq	a5,a1,ffffffffc0200c30 <buddy_check+0x4c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c16:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc0200c1a:	8b09                	andi	a4,a4,2
ffffffffc0200c1c:	30070863          	beqz	a4,ffffffffc0200f2c <buddy_check+0x348>
            count++;
            total_free_pages += p->property;
ffffffffc0200c20:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c24:	679c                	ld	a5,8(a5)
            count++;
ffffffffc0200c26:	2685                	addiw	a3,a3,1
            total_free_pages += p->property;
ffffffffc0200c28:	9e39                	addw	a2,a2,a4
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200c2a:	feb796e3          	bne	a5,a1,ffffffffc0200c16 <buddy_check+0x32>
        }
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc0200c2e:	2681                	sext.w	a3,a3
ffffffffc0200c30:	499c                	lw	a5,16(a1)
ffffffffc0200c32:	32d79d63          	bne	a5,a3,ffffffffc0200f6c <buddy_check+0x388>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200c36:	05e1                	addi	a1,a1,24
ffffffffc0200c38:	fca59be3          	bne	a1,a0,ffffffffc0200c0e <buddy_check+0x2a>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c3c:	00005917          	auipc	s2,0x5
ffffffffc0200c40:	3e490913          	addi	s2,s2,996 # ffffffffc0206020 <free_area+0x10>
    }

    // 检查总的空闲页面数是否一致
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200c44:	86ca                	mv	a3,s2
    size_t total = 0;
ffffffffc0200c46:	4581                	li	a1,0
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c48:	4781                	li	a5,0
ffffffffc0200c4a:	482d                	li	a6,11
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200c4c:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c50:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200c52:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c56:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200c58:	95ba                	add	a1,a1,a4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c5a:	ff0799e3          	bne	a5,a6,ffffffffc0200c4c <buddy_check+0x68>
    return total; // 返回总的空闲页面数
ffffffffc0200c5e:	00005697          	auipc	a3,0x5
ffffffffc0200c62:	3b268693          	addi	a3,a3,946 # ffffffffc0206010 <free_area>
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200c66:	32b61363          	bne	a2,a1,ffffffffc0200f8c <buddy_check+0x3a8>

    // 检查已分配页面的状态
    for (int i = 0; i <= MAX_ORDER-1; i++) {
        list_entry_t *le = &free_area[i].free_list;
ffffffffc0200c6a:	87b6                	mv	a5,a3
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200c6c:	a031                	j	ffffffffc0200c78 <buddy_check+0x94>
ffffffffc0200c6e:	ff07b703          	ld	a4,-16(a5)
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc0200c72:	8b09                	andi	a4,a4,2
ffffffffc0200c74:	2c070c63          	beqz	a4,ffffffffc0200f4c <buddy_check+0x368>
ffffffffc0200c78:	679c                	ld	a5,8(a5)
        while ((le = list_next(le))!= &free_area[i].free_list) {
ffffffffc0200c7a:	fed79ae3          	bne	a5,a3,ffffffffc0200c6e <buddy_check+0x8a>
    for (int i = 0; i <= MAX_ORDER-1; i++) {
ffffffffc0200c7e:	01878693          	addi	a3,a5,24
ffffffffc0200c82:	fea694e3          	bne	a3,a0,ffffffffc0200c6a <buddy_check+0x86>
ffffffffc0200c86:	00005697          	auipc	a3,0x5
ffffffffc0200c8a:	39a68693          	addi	a3,a3,922 # ffffffffc0206020 <free_area+0x10>
    size_t total = 0;
ffffffffc0200c8e:	4581                	li	a1,0
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c90:	4781                	li	a5,0
ffffffffc0200c92:	462d                	li	a2,11
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200c94:	0006e703          	lwu	a4,0(a3)
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c98:	06e1                	addi	a3,a3,24
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200c9a:	00f71733          	sll	a4,a4,a5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200c9e:	2785                	addiw	a5,a5,1
        total += (size_t)(free_area[i].nr_free) << i; // 计算总的空闲页面数
ffffffffc0200ca0:	95ba                	add	a1,a1,a4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200ca2:	fec799e3          	bne	a5,a2,ffffffffc0200c94 <buddy_check+0xb0>
        }
    }

    // 可以添加更多的检查逻辑，例如检查每个页面的引用计数
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages()); // 输出空闲块数
ffffffffc0200ca6:	00001517          	auipc	a0,0x1
ffffffffc0200caa:	1ea50513          	addi	a0,a0,490 # ffffffffc0201e90 <commands+0x5a0>
ffffffffc0200cae:	c04ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200cb2:	00005497          	auipc	s1,0x5
ffffffffc0200cb6:	47648493          	addi	s1,s1,1142 # ffffffffc0206128 <buf+0x10>
    cprintf("总空闲块数目为：%d\n", buddy_nr_free_pages()); // 输出空闲块数
ffffffffc0200cba:	00005997          	auipc	s3,0x5
ffffffffc0200cbe:	36698993          	addi	s3,s3,870 # ffffffffc0206020 <free_area+0x10>
        cprintf("%d ", free_area[i].nr_free); // 输出每个阶的空闲块数
ffffffffc0200cc2:	00001a17          	auipc	s4,0x1
ffffffffc0200cc6:	1eea0a13          	addi	s4,s4,494 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200cca:	0009a583          	lw	a1,0(s3)
ffffffffc0200cce:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200cd0:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free); // 输出每个阶的空闲块数
ffffffffc0200cd2:	be0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200cd6:	ff349ae3          	bne	s1,s3,ffffffffc0200cca <buddy_check+0xe6>
    
    // 请求页面示例
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("\n首先 p0 请求 5 页\n");
ffffffffc0200cda:	00001517          	auipc	a0,0x1
ffffffffc0200cde:	1de50513          	addi	a0,a0,478 # ffffffffc0201eb8 <commands+0x5c8>
ffffffffc0200ce2:	bd0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p0 = buddy_alloc_pages(5);
ffffffffc0200ce6:	4515                	li	a0,5
ffffffffc0200ce8:	cdfff0ef          	jal	ra,ffffffffc02009c6 <buddy_alloc_pages>
ffffffffc0200cec:	8baa                	mv	s7,a0
ffffffffc0200cee:	00005997          	auipc	s3,0x5
ffffffffc0200cf2:	33298993          	addi	s3,s3,818 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200cf6:	00001a17          	auipc	s4,0x1
ffffffffc0200cfa:	1baa0a13          	addi	s4,s4,442 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200cfe:	0009a583          	lw	a1,0(s3)
ffffffffc0200d02:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d04:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200d06:	bacff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d0a:	ff349ae3          	bne	s1,s3,ffffffffc0200cfe <buddy_check+0x11a>
    }
    
    cprintf("\n然后 p1 请求 5 页\n");
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	1ca50513          	addi	a0,a0,458 # ffffffffc0201ed8 <commands+0x5e8>
ffffffffc0200d16:	b9cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p1 = buddy_alloc_pages(5);
ffffffffc0200d1a:	4515                	li	a0,5
ffffffffc0200d1c:	cabff0ef          	jal	ra,ffffffffc02009c6 <buddy_alloc_pages>
ffffffffc0200d20:	8b2a                	mv	s6,a0
ffffffffc0200d22:	00005997          	auipc	s3,0x5
ffffffffc0200d26:	2fe98993          	addi	s3,s3,766 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200d2a:	00001a17          	auipc	s4,0x1
ffffffffc0200d2e:	186a0a13          	addi	s4,s4,390 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200d32:	0009a583          	lw	a1,0(s3)
ffffffffc0200d36:	8552                	mv	a0,s4
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d38:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200d3a:	b78ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d3e:	ff349ae3          	bne	s1,s3,ffffffffc0200d32 <buddy_check+0x14e>
    }
    
    cprintf("\n最后 p2 请求 1023页\n");
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	1b650513          	addi	a0,a0,438 # ffffffffc0201ef8 <commands+0x608>
ffffffffc0200d4a:	b68ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p2 = buddy_alloc_pages(1023);
ffffffffc0200d4e:	3ff00513          	li	a0,1023
ffffffffc0200d52:	c75ff0ef          	jal	ra,ffffffffc02009c6 <buddy_alloc_pages>
ffffffffc0200d56:	8a2a                	mv	s4,a0
ffffffffc0200d58:	00005997          	auipc	s3,0x5
ffffffffc0200d5c:	2c898993          	addi	s3,s3,712 # ffffffffc0206020 <free_area+0x10>
    
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200d60:	00001a97          	auipc	s5,0x1
ffffffffc0200d64:	150a8a93          	addi	s5,s5,336 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200d68:	0009a583          	lw	a1,0(s3)
ffffffffc0200d6c:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d6e:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200d70:	b42ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200d74:	ff349ae3          	bne	s1,s3,ffffffffc0200d68 <buddy_check+0x184>
    }
    
    cprintf("\n p0 的虚拟地址 0x%016lx.\n", p0);
ffffffffc0200d78:	85de                	mv	a1,s7
ffffffffc0200d7a:	00001517          	auipc	a0,0x1
ffffffffc0200d7e:	19e50513          	addi	a0,a0,414 # ffffffffc0201f18 <commands+0x628>
ffffffffc0200d82:	b30ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p1 的虚拟地址 0x%016lx.\n", p1);
ffffffffc0200d86:	85da                	mv	a1,s6
ffffffffc0200d88:	00001517          	auipc	a0,0x1
ffffffffc0200d8c:	1b050513          	addi	a0,a0,432 # ffffffffc0201f38 <commands+0x648>
ffffffffc0200d90:	b22ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("\n p2 的虚拟地址 0x%016lx.\n", p2);
ffffffffc0200d94:	85d2                	mv	a1,s4
ffffffffc0200d96:	00001517          	auipc	a0,0x1
ffffffffc0200d9a:	1c250513          	addi	a0,a0,450 # ffffffffc0201f58 <commands+0x668>
ffffffffc0200d9e:	b14ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    
    
    cprintf("\n 收回p0\n");
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	1d650513          	addi	a0,a0,470 # ffffffffc0201f78 <commands+0x688>
ffffffffc0200daa:	b08ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++) {
ffffffffc0200dae:	0c8b8713          	addi	a4,s7,200
    p0 = buddy_alloc_pages(5);
ffffffffc0200db2:	87de                	mv	a5,s7
        p->flags = 0; // 清除标志
ffffffffc0200db4:	0007b423          	sd	zero,8(a5)
ffffffffc0200db8:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++) {
ffffffffc0200dbc:	02878793          	addi	a5,a5,40
ffffffffc0200dc0:	fef71ae3          	bne	a4,a5,ffffffffc0200db4 <buddy_check+0x1d0>
    base->property = n; // 设置释放页面的属性
ffffffffc0200dc4:	4795                	li	a5,5
ffffffffc0200dc6:	00fba823          	sw	a5,16(s7)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200dca:	008b8713          	addi	a4,s7,8
ffffffffc0200dce:	4789                	li	a5,2
ffffffffc0200dd0:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dd4:	6438                	ld	a4,72(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200dd6:	4c3c                	lw	a5,88(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0200dd8:	018b8693          	addi	a3,s7,24
    prev->next = next->prev = elm;
ffffffffc0200ddc:	e434                	sd	a3,72(s0)
ffffffffc0200dde:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200de0:	00005c17          	auipc	s8,0x5
ffffffffc0200de4:	278c0c13          	addi	s8,s8,632 # ffffffffc0206058 <free_area+0x48>
ffffffffc0200de8:	038bb023          	sd	s8,32(s7)
    elm->prev = prev;
ffffffffc0200dec:	00ebbc23          	sd	a4,24(s7)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200df0:	2785                	addiw	a5,a5,1
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200df2:	85de                	mv	a1,s7
ffffffffc0200df4:	450d                	li	a0,3
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200df6:	cc3c                	sw	a5,88(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200df8:	00005997          	auipc	s3,0x5
ffffffffc0200dfc:	22898993          	addi	s3,s3,552 # ffffffffc0206020 <free_area+0x10>
ffffffffc0200e00:	a23ff0ef          	jal	ra,ffffffffc0200822 <merge_page>
    buddy_free_pages(p0,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200e04:	00001a97          	auipc	s5,0x1
ffffffffc0200e08:	0aca8a93          	addi	s5,s5,172 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200e0c:	0009a583          	lw	a1,0(s3)
ffffffffc0200e10:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200e12:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200e14:	a9eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200e18:	fe999ae3          	bne	s3,s1,ffffffffc0200e0c <buddy_check+0x228>
    }
    
    cprintf("\n 收回p1\n");
ffffffffc0200e1c:	00001517          	auipc	a0,0x1
ffffffffc0200e20:	16c50513          	addi	a0,a0,364 # ffffffffc0201f88 <commands+0x698>
ffffffffc0200e24:	a8eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++) {
ffffffffc0200e28:	0c8b0713          	addi	a4,s6,200
    p1 = buddy_alloc_pages(5);
ffffffffc0200e2c:	87da                	mv	a5,s6
        p->flags = 0; // 清除标志
ffffffffc0200e2e:	0007b423          	sd	zero,8(a5)
ffffffffc0200e32:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++) {
ffffffffc0200e36:	02878793          	addi	a5,a5,40
ffffffffc0200e3a:	fee79ae3          	bne	a5,a4,ffffffffc0200e2e <buddy_check+0x24a>
    base->property = n; // 设置释放页面的属性
ffffffffc0200e3e:	4795                	li	a5,5
ffffffffc0200e40:	00fb2823          	sw	a5,16(s6)
ffffffffc0200e44:	008b0713          	addi	a4,s6,8
ffffffffc0200e48:	4789                	li	a5,2
ffffffffc0200e4a:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e4e:	6438                	ld	a4,72(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200e50:	4c3c                	lw	a5,88(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0200e52:	018b0693          	addi	a3,s6,24
    prev->next = next->prev = elm;
ffffffffc0200e56:	e434                	sd	a3,72(s0)
ffffffffc0200e58:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200e5a:	038b3023          	sd	s8,32(s6)
    elm->prev = prev;
ffffffffc0200e5e:	00eb3c23          	sd	a4,24(s6)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200e62:	2785                	addiw	a5,a5,1
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200e64:	85da                	mv	a1,s6
ffffffffc0200e66:	450d                	li	a0,3
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200e68:	cc3c                	sw	a5,88(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200e6a:	00005997          	auipc	s3,0x5
ffffffffc0200e6e:	1b698993          	addi	s3,s3,438 # ffffffffc0206020 <free_area+0x10>
ffffffffc0200e72:	9b1ff0ef          	jal	ra,ffffffffc0200822 <merge_page>
    buddy_free_pages(p1,5);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200e76:	00001a97          	auipc	s5,0x1
ffffffffc0200e7a:	03aa8a93          	addi	s5,s5,58 # ffffffffc0201eb0 <commands+0x5c0>
ffffffffc0200e7e:	0009a583          	lw	a1,0(s3)
ffffffffc0200e82:	8556                	mv	a0,s5
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200e84:	09e1                	addi	s3,s3,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200e86:	a2cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200e8a:	ff349ae3          	bne	s1,s3,ffffffffc0200e7e <buddy_check+0x29a>
    }
    
    cprintf("\n 收回p2\n");
ffffffffc0200e8e:	00001517          	auipc	a0,0x1
ffffffffc0200e92:	10a50513          	addi	a0,a0,266 # ffffffffc0201f98 <commands+0x6a8>
ffffffffc0200e96:	a1cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (; p < base + n; p++) {
ffffffffc0200e9a:	6729                	lui	a4,0xa
ffffffffc0200e9c:	fd870713          	addi	a4,a4,-40 # 9fd8 <kern_entry-0xffffffffc01f6028>
ffffffffc0200ea0:	9752                	add	a4,a4,s4
    p2 = buddy_alloc_pages(1023);
ffffffffc0200ea2:	87d2                	mv	a5,s4
        p->flags = 0; // 清除标志
ffffffffc0200ea4:	0007b423          	sd	zero,8(a5)
ffffffffc0200ea8:	0007a023          	sw	zero,0(a5)
    for (; p < base + n; p++) {
ffffffffc0200eac:	02878793          	addi	a5,a5,40
ffffffffc0200eb0:	fef71ae3          	bne	a4,a5,ffffffffc0200ea4 <buddy_check+0x2c0>
    base->property = n; // 设置释放页面的属性
ffffffffc0200eb4:	3ff00793          	li	a5,1023
ffffffffc0200eb8:	00fa2823          	sw	a5,16(s4)
ffffffffc0200ebc:	008a0713          	addi	a4,s4,8
ffffffffc0200ec0:	4789                	li	a5,2
ffffffffc0200ec2:	40f7302f          	amoor.d	zero,a5,(a4)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200ec6:	7878                	ld	a4,240(s0)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200ec8:	10042783          	lw	a5,256(s0)
    list_add_before(le, &(base->page_link)); // 将释放的页面加入空闲列表
ffffffffc0200ecc:	018a0693          	addi	a3,s4,24
    prev->next = next->prev = elm;
ffffffffc0200ed0:	f874                	sd	a3,240(s0)
ffffffffc0200ed2:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200ed4:	00005697          	auipc	a3,0x5
ffffffffc0200ed8:	22c68693          	addi	a3,a3,556 # ffffffffc0206100 <free_area+0xf0>
ffffffffc0200edc:	02da3023          	sd	a3,32(s4)
    elm->prev = prev;
ffffffffc0200ee0:	00ea3c23          	sd	a4,24(s4)
    free_area[order].nr_free++; // 更新空闲页面计数
ffffffffc0200ee4:	2785                	addiw	a5,a5,1
ffffffffc0200ee6:	10f42023          	sw	a5,256(s0)
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200eea:	85d2                	mv	a1,s4
ffffffffc0200eec:	4529                	li	a0,10
    buddy_free_pages(p2,1023);
    for (int i = 0; i < MAX_ORDER; i++) {
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200eee:	00001417          	auipc	s0,0x1
ffffffffc0200ef2:	fc240413          	addi	s0,s0,-62 # ffffffffc0201eb0 <commands+0x5c0>
    merge_page(order, base); // 合并相邻的空闲页面
ffffffffc0200ef6:	92dff0ef          	jal	ra,ffffffffc0200822 <merge_page>
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200efa:	00092583          	lw	a1,0(s2)
ffffffffc0200efe:	8522                	mv	a0,s0
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f00:	0961                	addi	s2,s2,24
        cprintf("%d ", free_area[i].nr_free);
ffffffffc0200f02:	9b0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200f06:	fe991ae3          	bne	s2,s1,ffffffffc0200efa <buddy_check+0x316>
    }
    
    cprintf("\n");
}
ffffffffc0200f0a:	6406                	ld	s0,64(sp)
ffffffffc0200f0c:	60a6                	ld	ra,72(sp)
ffffffffc0200f0e:	74e2                	ld	s1,56(sp)
ffffffffc0200f10:	7942                	ld	s2,48(sp)
ffffffffc0200f12:	79a2                	ld	s3,40(sp)
ffffffffc0200f14:	7a02                	ld	s4,32(sp)
ffffffffc0200f16:	6ae2                	ld	s5,24(sp)
ffffffffc0200f18:	6b42                	ld	s6,16(sp)
ffffffffc0200f1a:	6ba2                	ld	s7,8(sp)
ffffffffc0200f1c:	6c02                	ld	s8,0(sp)
    cprintf("\n");
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	86250513          	addi	a0,a0,-1950 # ffffffffc0201780 <etext+0xec>
}
ffffffffc0200f26:	6161                	addi	sp,sp,80
    cprintf("\n");
ffffffffc0200f28:	98aff06f          	j	ffffffffc02000b2 <cprintf>
            assert(PageProperty(p)); // 每个页面应该标记为已分配
ffffffffc0200f2c:	00001697          	auipc	a3,0x1
ffffffffc0200f30:	f0468693          	addi	a3,a3,-252 # ffffffffc0201e30 <commands+0x540>
ffffffffc0200f34:	00001617          	auipc	a2,0x1
ffffffffc0200f38:	ebc60613          	addi	a2,a2,-324 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200f3c:	0a400593          	li	a1,164
ffffffffc0200f40:	00001517          	auipc	a0,0x1
ffffffffc0200f44:	ec850513          	addi	a0,a0,-312 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200f48:	c64ff0ef          	jal	ra,ffffffffc02003ac <__panic>
            assert(PageProperty(p)); // 确保页面的属性是正确的
ffffffffc0200f4c:	00001697          	auipc	a3,0x1
ffffffffc0200f50:	ee468693          	addi	a3,a3,-284 # ffffffffc0201e30 <commands+0x540>
ffffffffc0200f54:	00001617          	auipc	a2,0x1
ffffffffc0200f58:	e9c60613          	addi	a2,a2,-356 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200f5c:	0b300593          	li	a1,179
ffffffffc0200f60:	00001517          	auipc	a0,0x1
ffffffffc0200f64:	ea850513          	addi	a0,a0,-344 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200f68:	c44ff0ef          	jal	ra,ffffffffc02003ac <__panic>
        assert(count == free_area[i].nr_free); // 空闲列表中的页面数应与记录一致
ffffffffc0200f6c:	00001697          	auipc	a3,0x1
ffffffffc0200f70:	ed468693          	addi	a3,a3,-300 # ffffffffc0201e40 <commands+0x550>
ffffffffc0200f74:	00001617          	auipc	a2,0x1
ffffffffc0200f78:	e7c60613          	addi	a2,a2,-388 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200f7c:	0a800593          	li	a1,168
ffffffffc0200f80:	00001517          	auipc	a0,0x1
ffffffffc0200f84:	e8850513          	addi	a0,a0,-376 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200f88:	c24ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total_free_pages == buddy_nr_free_pages());
ffffffffc0200f8c:	00001697          	auipc	a3,0x1
ffffffffc0200f90:	ed468693          	addi	a3,a3,-300 # ffffffffc0201e60 <commands+0x570>
ffffffffc0200f94:	00001617          	auipc	a2,0x1
ffffffffc0200f98:	e5c60613          	addi	a2,a2,-420 # ffffffffc0201df0 <commands+0x500>
ffffffffc0200f9c:	0ac00593          	li	a1,172
ffffffffc0200fa0:	00001517          	auipc	a0,0x1
ffffffffc0200fa4:	e6850513          	addi	a0,a0,-408 # ffffffffc0201e08 <commands+0x518>
ffffffffc0200fa8:	c04ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200fac <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    //pmm_manager = &best_fit_pmm_manager; // 修改此处：测试 Best-Fit 算法
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc0200fac:	00001797          	auipc	a5,0x1
ffffffffc0200fb0:	01c78793          	addi	a5,a5,28 # ffffffffc0201fc8 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fb4:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200fb6:	1101                	addi	sp,sp,-32
ffffffffc0200fb8:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fba:	00001517          	auipc	a0,0x1
ffffffffc0200fbe:	04650513          	addi	a0,a0,70 # ffffffffc0202000 <buddy_system_pmm_manager+0x38>
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc0200fc2:	00005497          	auipc	s1,0x5
ffffffffc0200fc6:	57648493          	addi	s1,s1,1398 # ffffffffc0206538 <pmm_manager>
void pmm_init(void) {
ffffffffc0200fca:	ec06                	sd	ra,24(sp)
ffffffffc0200fcc:	e822                	sd	s0,16(sp)
    pmm_manager = &buddy_system_pmm_manager; // 修改此处：测试 Buddy System 算法
ffffffffc0200fce:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fd0:	8e2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0200fd4:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fd6:	00005417          	auipc	s0,0x5
ffffffffc0200fda:	57a40413          	addi	s0,s0,1402 # ffffffffc0206550 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200fde:	679c                	ld	a5,8(a5)
ffffffffc0200fe0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fe2:	57f5                	li	a5,-3
ffffffffc0200fe4:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200fe6:	00001517          	auipc	a0,0x1
ffffffffc0200fea:	03250513          	addi	a0,a0,50 # ffffffffc0202018 <buddy_system_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fee:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0200ff0:	8c2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200ff4:	46c5                	li	a3,17
ffffffffc0200ff6:	06ee                	slli	a3,a3,0x1b
ffffffffc0200ff8:	40100613          	li	a2,1025
ffffffffc0200ffc:	16fd                	addi	a3,a3,-1
ffffffffc0200ffe:	07e005b7          	lui	a1,0x7e00
ffffffffc0201002:	0656                	slli	a2,a2,0x15
ffffffffc0201004:	00001517          	auipc	a0,0x1
ffffffffc0201008:	02c50513          	addi	a0,a0,44 # ffffffffc0202030 <buddy_system_pmm_manager+0x68>
ffffffffc020100c:	8a6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201010:	777d                	lui	a4,0xfffff
ffffffffc0201012:	00006797          	auipc	a5,0x6
ffffffffc0201016:	54d78793          	addi	a5,a5,1357 # ffffffffc020755f <end+0xfff>
ffffffffc020101a:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020101c:	00005517          	auipc	a0,0x5
ffffffffc0201020:	50c50513          	addi	a0,a0,1292 # ffffffffc0206528 <npage>
ffffffffc0201024:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201028:	00005597          	auipc	a1,0x5
ffffffffc020102c:	50858593          	addi	a1,a1,1288 # ffffffffc0206530 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201030:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201032:	e19c                	sd	a5,0(a1)
ffffffffc0201034:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201036:	4701                	li	a4,0
ffffffffc0201038:	4885                	li	a7,1
ffffffffc020103a:	fff80837          	lui	a6,0xfff80
ffffffffc020103e:	a011                	j	ffffffffc0201042 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201040:	619c                	ld	a5,0(a1)
ffffffffc0201042:	97b6                	add	a5,a5,a3
ffffffffc0201044:	07a1                	addi	a5,a5,8
ffffffffc0201046:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020104a:	611c                	ld	a5,0(a0)
ffffffffc020104c:	0705                	addi	a4,a4,1
ffffffffc020104e:	02868693          	addi	a3,a3,40
ffffffffc0201052:	01078633          	add	a2,a5,a6
ffffffffc0201056:	fec765e3          	bltu	a4,a2,ffffffffc0201040 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020105a:	6190                	ld	a2,0(a1)
ffffffffc020105c:	00279713          	slli	a4,a5,0x2
ffffffffc0201060:	973e                	add	a4,a4,a5
ffffffffc0201062:	fec006b7          	lui	a3,0xfec00
ffffffffc0201066:	070e                	slli	a4,a4,0x3
ffffffffc0201068:	96b2                	add	a3,a3,a2
ffffffffc020106a:	96ba                	add	a3,a3,a4
ffffffffc020106c:	c0200737          	lui	a4,0xc0200
ffffffffc0201070:	08e6ef63          	bltu	a3,a4,ffffffffc020110e <pmm_init+0x162>
ffffffffc0201074:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc0201076:	45c5                	li	a1,17
ffffffffc0201078:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020107a:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020107c:	04b6e863          	bltu	a3,a1,ffffffffc02010cc <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201080:	609c                	ld	a5,0(s1)
ffffffffc0201082:	7b9c                	ld	a5,48(a5)
ffffffffc0201084:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201086:	00001517          	auipc	a0,0x1
ffffffffc020108a:	04250513          	addi	a0,a0,66 # ffffffffc02020c8 <buddy_system_pmm_manager+0x100>
ffffffffc020108e:	824ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201092:	00004597          	auipc	a1,0x4
ffffffffc0201096:	f6e58593          	addi	a1,a1,-146 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020109a:	00005797          	auipc	a5,0x5
ffffffffc020109e:	4ab7b723          	sd	a1,1198(a5) # ffffffffc0206548 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010a2:	c02007b7          	lui	a5,0xc0200
ffffffffc02010a6:	08f5e063          	bltu	a1,a5,ffffffffc0201126 <pmm_init+0x17a>
ffffffffc02010aa:	6010                	ld	a2,0(s0)
}
ffffffffc02010ac:	6442                	ld	s0,16(sp)
ffffffffc02010ae:	60e2                	ld	ra,24(sp)
ffffffffc02010b0:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02010b2:	40c58633          	sub	a2,a1,a2
ffffffffc02010b6:	00005797          	auipc	a5,0x5
ffffffffc02010ba:	48c7b523          	sd	a2,1162(a5) # ffffffffc0206540 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02010be:	00001517          	auipc	a0,0x1
ffffffffc02010c2:	02a50513          	addi	a0,a0,42 # ffffffffc02020e8 <buddy_system_pmm_manager+0x120>
}
ffffffffc02010c6:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02010c8:	febfe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02010cc:	6705                	lui	a4,0x1
ffffffffc02010ce:	177d                	addi	a4,a4,-1
ffffffffc02010d0:	96ba                	add	a3,a3,a4
ffffffffc02010d2:	777d                	lui	a4,0xfffff
ffffffffc02010d4:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02010d6:	00c6d513          	srli	a0,a3,0xc
ffffffffc02010da:	00f57e63          	bgeu	a0,a5,ffffffffc02010f6 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc02010de:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02010e0:	982a                	add	a6,a6,a0
ffffffffc02010e2:	00281513          	slli	a0,a6,0x2
ffffffffc02010e6:	9542                	add	a0,a0,a6
ffffffffc02010e8:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02010ea:	8d95                	sub	a1,a1,a3
ffffffffc02010ec:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02010ee:	81b1                	srli	a1,a1,0xc
ffffffffc02010f0:	9532                	add	a0,a0,a2
ffffffffc02010f2:	9782                	jalr	a5
}
ffffffffc02010f4:	b771                	j	ffffffffc0201080 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc02010f6:	00001617          	auipc	a2,0x1
ffffffffc02010fa:	fa260613          	addi	a2,a2,-94 # ffffffffc0202098 <buddy_system_pmm_manager+0xd0>
ffffffffc02010fe:	06b00593          	li	a1,107
ffffffffc0201102:	00001517          	auipc	a0,0x1
ffffffffc0201106:	fb650513          	addi	a0,a0,-74 # ffffffffc02020b8 <buddy_system_pmm_manager+0xf0>
ffffffffc020110a:	aa2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020110e:	00001617          	auipc	a2,0x1
ffffffffc0201112:	f5260613          	addi	a2,a2,-174 # ffffffffc0202060 <buddy_system_pmm_manager+0x98>
ffffffffc0201116:	07000593          	li	a1,112
ffffffffc020111a:	00001517          	auipc	a0,0x1
ffffffffc020111e:	f6e50513          	addi	a0,a0,-146 # ffffffffc0202088 <buddy_system_pmm_manager+0xc0>
ffffffffc0201122:	a8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201126:	86ae                	mv	a3,a1
ffffffffc0201128:	00001617          	auipc	a2,0x1
ffffffffc020112c:	f3860613          	addi	a2,a2,-200 # ffffffffc0202060 <buddy_system_pmm_manager+0x98>
ffffffffc0201130:	08b00593          	li	a1,139
ffffffffc0201134:	00001517          	auipc	a0,0x1
ffffffffc0201138:	f5450513          	addi	a0,a0,-172 # ffffffffc0202088 <buddy_system_pmm_manager+0xc0>
ffffffffc020113c:	a70ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201140 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201140:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201144:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201146:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020114a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020114c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201150:	f022                	sd	s0,32(sp)
ffffffffc0201152:	ec26                	sd	s1,24(sp)
ffffffffc0201154:	e84a                	sd	s2,16(sp)
ffffffffc0201156:	f406                	sd	ra,40(sp)
ffffffffc0201158:	e44e                	sd	s3,8(sp)
ffffffffc020115a:	84aa                	mv	s1,a0
ffffffffc020115c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020115e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201162:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201164:	03067e63          	bgeu	a2,a6,ffffffffc02011a0 <printnum+0x60>
ffffffffc0201168:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020116a:	00805763          	blez	s0,ffffffffc0201178 <printnum+0x38>
ffffffffc020116e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201170:	85ca                	mv	a1,s2
ffffffffc0201172:	854e                	mv	a0,s3
ffffffffc0201174:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201176:	fc65                	bnez	s0,ffffffffc020116e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201178:	1a02                	slli	s4,s4,0x20
ffffffffc020117a:	00001797          	auipc	a5,0x1
ffffffffc020117e:	fae78793          	addi	a5,a5,-82 # ffffffffc0202128 <buddy_system_pmm_manager+0x160>
ffffffffc0201182:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201186:	9a3e                	add	s4,s4,a5
}
ffffffffc0201188:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020118a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020118e:	70a2                	ld	ra,40(sp)
ffffffffc0201190:	69a2                	ld	s3,8(sp)
ffffffffc0201192:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201194:	85ca                	mv	a1,s2
ffffffffc0201196:	87a6                	mv	a5,s1
}
ffffffffc0201198:	6942                	ld	s2,16(sp)
ffffffffc020119a:	64e2                	ld	s1,24(sp)
ffffffffc020119c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020119e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02011a0:	03065633          	divu	a2,a2,a6
ffffffffc02011a4:	8722                	mv	a4,s0
ffffffffc02011a6:	f9bff0ef          	jal	ra,ffffffffc0201140 <printnum>
ffffffffc02011aa:	b7f9                	j	ffffffffc0201178 <printnum+0x38>

ffffffffc02011ac <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02011ac:	7119                	addi	sp,sp,-128
ffffffffc02011ae:	f4a6                	sd	s1,104(sp)
ffffffffc02011b0:	f0ca                	sd	s2,96(sp)
ffffffffc02011b2:	ecce                	sd	s3,88(sp)
ffffffffc02011b4:	e8d2                	sd	s4,80(sp)
ffffffffc02011b6:	e4d6                	sd	s5,72(sp)
ffffffffc02011b8:	e0da                	sd	s6,64(sp)
ffffffffc02011ba:	fc5e                	sd	s7,56(sp)
ffffffffc02011bc:	f06a                	sd	s10,32(sp)
ffffffffc02011be:	fc86                	sd	ra,120(sp)
ffffffffc02011c0:	f8a2                	sd	s0,112(sp)
ffffffffc02011c2:	f862                	sd	s8,48(sp)
ffffffffc02011c4:	f466                	sd	s9,40(sp)
ffffffffc02011c6:	ec6e                	sd	s11,24(sp)
ffffffffc02011c8:	892a                	mv	s2,a0
ffffffffc02011ca:	84ae                	mv	s1,a1
ffffffffc02011cc:	8d32                	mv	s10,a2
ffffffffc02011ce:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011d0:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02011d4:	5b7d                	li	s6,-1
ffffffffc02011d6:	00001a97          	auipc	s5,0x1
ffffffffc02011da:	f86a8a93          	addi	s5,s5,-122 # ffffffffc020215c <buddy_system_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02011de:	00001b97          	auipc	s7,0x1
ffffffffc02011e2:	15ab8b93          	addi	s7,s7,346 # ffffffffc0202338 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011e6:	000d4503          	lbu	a0,0(s10)
ffffffffc02011ea:	001d0413          	addi	s0,s10,1
ffffffffc02011ee:	01350a63          	beq	a0,s3,ffffffffc0201202 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02011f2:	c121                	beqz	a0,ffffffffc0201232 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02011f4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011f6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02011f8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011fa:	fff44503          	lbu	a0,-1(s0)
ffffffffc02011fe:	ff351ae3          	bne	a0,s3,ffffffffc02011f2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201202:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201206:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020120a:	4c81                	li	s9,0
ffffffffc020120c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020120e:	5c7d                	li	s8,-1
ffffffffc0201210:	5dfd                	li	s11,-1
ffffffffc0201212:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201216:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201218:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020121c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201220:	00140d13          	addi	s10,s0,1
ffffffffc0201224:	04b56263          	bltu	a0,a1,ffffffffc0201268 <vprintfmt+0xbc>
ffffffffc0201228:	058a                	slli	a1,a1,0x2
ffffffffc020122a:	95d6                	add	a1,a1,s5
ffffffffc020122c:	4194                	lw	a3,0(a1)
ffffffffc020122e:	96d6                	add	a3,a3,s5
ffffffffc0201230:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201232:	70e6                	ld	ra,120(sp)
ffffffffc0201234:	7446                	ld	s0,112(sp)
ffffffffc0201236:	74a6                	ld	s1,104(sp)
ffffffffc0201238:	7906                	ld	s2,96(sp)
ffffffffc020123a:	69e6                	ld	s3,88(sp)
ffffffffc020123c:	6a46                	ld	s4,80(sp)
ffffffffc020123e:	6aa6                	ld	s5,72(sp)
ffffffffc0201240:	6b06                	ld	s6,64(sp)
ffffffffc0201242:	7be2                	ld	s7,56(sp)
ffffffffc0201244:	7c42                	ld	s8,48(sp)
ffffffffc0201246:	7ca2                	ld	s9,40(sp)
ffffffffc0201248:	7d02                	ld	s10,32(sp)
ffffffffc020124a:	6de2                	ld	s11,24(sp)
ffffffffc020124c:	6109                	addi	sp,sp,128
ffffffffc020124e:	8082                	ret
            padc = '0';
ffffffffc0201250:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201252:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201256:	846a                	mv	s0,s10
ffffffffc0201258:	00140d13          	addi	s10,s0,1
ffffffffc020125c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201260:	0ff5f593          	zext.b	a1,a1
ffffffffc0201264:	fcb572e3          	bgeu	a0,a1,ffffffffc0201228 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201268:	85a6                	mv	a1,s1
ffffffffc020126a:	02500513          	li	a0,37
ffffffffc020126e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201270:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201274:	8d22                	mv	s10,s0
ffffffffc0201276:	f73788e3          	beq	a5,s3,ffffffffc02011e6 <vprintfmt+0x3a>
ffffffffc020127a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020127e:	1d7d                	addi	s10,s10,-1
ffffffffc0201280:	ff379de3          	bne	a5,s3,ffffffffc020127a <vprintfmt+0xce>
ffffffffc0201284:	b78d                	j	ffffffffc02011e6 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201286:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020128a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020128e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201290:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201294:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201298:	02d86463          	bltu	a6,a3,ffffffffc02012c0 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020129c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02012a0:	002c169b          	slliw	a3,s8,0x2
ffffffffc02012a4:	0186873b          	addw	a4,a3,s8
ffffffffc02012a8:	0017171b          	slliw	a4,a4,0x1
ffffffffc02012ac:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02012ae:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02012b2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02012b4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02012b8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02012bc:	fed870e3          	bgeu	a6,a3,ffffffffc020129c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02012c0:	f40ddce3          	bgez	s11,ffffffffc0201218 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02012c4:	8de2                	mv	s11,s8
ffffffffc02012c6:	5c7d                	li	s8,-1
ffffffffc02012c8:	bf81                	j	ffffffffc0201218 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02012ca:	fffdc693          	not	a3,s11
ffffffffc02012ce:	96fd                	srai	a3,a3,0x3f
ffffffffc02012d0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012d4:	00144603          	lbu	a2,1(s0)
ffffffffc02012d8:	2d81                	sext.w	s11,s11
ffffffffc02012da:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012dc:	bf35                	j	ffffffffc0201218 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02012de:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02012e6:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e8:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02012ea:	bfd9                	j	ffffffffc02012c0 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02012ec:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012ee:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012f2:	01174463          	blt	a4,a7,ffffffffc02012fa <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02012f6:	1a088e63          	beqz	a7,ffffffffc02014b2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02012fa:	000a3603          	ld	a2,0(s4)
ffffffffc02012fe:	46c1                	li	a3,16
ffffffffc0201300:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201302:	2781                	sext.w	a5,a5
ffffffffc0201304:	876e                	mv	a4,s11
ffffffffc0201306:	85a6                	mv	a1,s1
ffffffffc0201308:	854a                	mv	a0,s2
ffffffffc020130a:	e37ff0ef          	jal	ra,ffffffffc0201140 <printnum>
            break;
ffffffffc020130e:	bde1                	j	ffffffffc02011e6 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201310:	000a2503          	lw	a0,0(s4)
ffffffffc0201314:	85a6                	mv	a1,s1
ffffffffc0201316:	0a21                	addi	s4,s4,8
ffffffffc0201318:	9902                	jalr	s2
            break;
ffffffffc020131a:	b5f1                	j	ffffffffc02011e6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020131c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020131e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201322:	01174463          	blt	a4,a7,ffffffffc020132a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201326:	18088163          	beqz	a7,ffffffffc02014a8 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020132a:	000a3603          	ld	a2,0(s4)
ffffffffc020132e:	46a9                	li	a3,10
ffffffffc0201330:	8a2e                	mv	s4,a1
ffffffffc0201332:	bfc1                	j	ffffffffc0201302 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201334:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201338:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020133a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020133c:	bdf1                	j	ffffffffc0201218 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020133e:	85a6                	mv	a1,s1
ffffffffc0201340:	02500513          	li	a0,37
ffffffffc0201344:	9902                	jalr	s2
            break;
ffffffffc0201346:	b545                	j	ffffffffc02011e6 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201348:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020134c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020134e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201350:	b5e1                	j	ffffffffc0201218 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201352:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201354:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201358:	01174463          	blt	a4,a7,ffffffffc0201360 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020135c:	14088163          	beqz	a7,ffffffffc020149e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201360:	000a3603          	ld	a2,0(s4)
ffffffffc0201364:	46a1                	li	a3,8
ffffffffc0201366:	8a2e                	mv	s4,a1
ffffffffc0201368:	bf69                	j	ffffffffc0201302 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020136a:	03000513          	li	a0,48
ffffffffc020136e:	85a6                	mv	a1,s1
ffffffffc0201370:	e03e                	sd	a5,0(sp)
ffffffffc0201372:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201374:	85a6                	mv	a1,s1
ffffffffc0201376:	07800513          	li	a0,120
ffffffffc020137a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020137c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020137e:	6782                	ld	a5,0(sp)
ffffffffc0201380:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201382:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201386:	bfb5                	j	ffffffffc0201302 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201388:	000a3403          	ld	s0,0(s4)
ffffffffc020138c:	008a0713          	addi	a4,s4,8
ffffffffc0201390:	e03a                	sd	a4,0(sp)
ffffffffc0201392:	14040263          	beqz	s0,ffffffffc02014d6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201396:	0fb05763          	blez	s11,ffffffffc0201484 <vprintfmt+0x2d8>
ffffffffc020139a:	02d00693          	li	a3,45
ffffffffc020139e:	0cd79163          	bne	a5,a3,ffffffffc0201460 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013a2:	00044783          	lbu	a5,0(s0)
ffffffffc02013a6:	0007851b          	sext.w	a0,a5
ffffffffc02013aa:	cf85                	beqz	a5,ffffffffc02013e2 <vprintfmt+0x236>
ffffffffc02013ac:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013b0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013b4:	000c4563          	bltz	s8,ffffffffc02013be <vprintfmt+0x212>
ffffffffc02013b8:	3c7d                	addiw	s8,s8,-1
ffffffffc02013ba:	036c0263          	beq	s8,s6,ffffffffc02013de <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02013be:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02013c0:	0e0c8e63          	beqz	s9,ffffffffc02014bc <vprintfmt+0x310>
ffffffffc02013c4:	3781                	addiw	a5,a5,-32
ffffffffc02013c6:	0ef47b63          	bgeu	s0,a5,ffffffffc02014bc <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02013ca:	03f00513          	li	a0,63
ffffffffc02013ce:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013d0:	000a4783          	lbu	a5,0(s4)
ffffffffc02013d4:	3dfd                	addiw	s11,s11,-1
ffffffffc02013d6:	0a05                	addi	s4,s4,1
ffffffffc02013d8:	0007851b          	sext.w	a0,a5
ffffffffc02013dc:	ffe1                	bnez	a5,ffffffffc02013b4 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02013de:	01b05963          	blez	s11,ffffffffc02013f0 <vprintfmt+0x244>
ffffffffc02013e2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02013e4:	85a6                	mv	a1,s1
ffffffffc02013e6:	02000513          	li	a0,32
ffffffffc02013ea:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013ec:	fe0d9be3          	bnez	s11,ffffffffc02013e2 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013f0:	6a02                	ld	s4,0(sp)
ffffffffc02013f2:	bbd5                	j	ffffffffc02011e6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013f4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013f6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02013fa:	01174463          	blt	a4,a7,ffffffffc0201402 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02013fe:	08088d63          	beqz	a7,ffffffffc0201498 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201402:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201406:	0a044d63          	bltz	s0,ffffffffc02014c0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020140a:	8622                	mv	a2,s0
ffffffffc020140c:	8a66                	mv	s4,s9
ffffffffc020140e:	46a9                	li	a3,10
ffffffffc0201410:	bdcd                	j	ffffffffc0201302 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201412:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201416:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201418:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020141a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020141e:	8fb5                	xor	a5,a5,a3
ffffffffc0201420:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201424:	02d74163          	blt	a4,a3,ffffffffc0201446 <vprintfmt+0x29a>
ffffffffc0201428:	00369793          	slli	a5,a3,0x3
ffffffffc020142c:	97de                	add	a5,a5,s7
ffffffffc020142e:	639c                	ld	a5,0(a5)
ffffffffc0201430:	cb99                	beqz	a5,ffffffffc0201446 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201432:	86be                	mv	a3,a5
ffffffffc0201434:	00001617          	auipc	a2,0x1
ffffffffc0201438:	d2460613          	addi	a2,a2,-732 # ffffffffc0202158 <buddy_system_pmm_manager+0x190>
ffffffffc020143c:	85a6                	mv	a1,s1
ffffffffc020143e:	854a                	mv	a0,s2
ffffffffc0201440:	0ce000ef          	jal	ra,ffffffffc020150e <printfmt>
ffffffffc0201444:	b34d                	j	ffffffffc02011e6 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201446:	00001617          	auipc	a2,0x1
ffffffffc020144a:	d0260613          	addi	a2,a2,-766 # ffffffffc0202148 <buddy_system_pmm_manager+0x180>
ffffffffc020144e:	85a6                	mv	a1,s1
ffffffffc0201450:	854a                	mv	a0,s2
ffffffffc0201452:	0bc000ef          	jal	ra,ffffffffc020150e <printfmt>
ffffffffc0201456:	bb41                	j	ffffffffc02011e6 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201458:	00001417          	auipc	s0,0x1
ffffffffc020145c:	ce840413          	addi	s0,s0,-792 # ffffffffc0202140 <buddy_system_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201460:	85e2                	mv	a1,s8
ffffffffc0201462:	8522                	mv	a0,s0
ffffffffc0201464:	e43e                	sd	a5,8(sp)
ffffffffc0201466:	1cc000ef          	jal	ra,ffffffffc0201632 <strnlen>
ffffffffc020146a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020146e:	01b05b63          	blez	s11,ffffffffc0201484 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201472:	67a2                	ld	a5,8(sp)
ffffffffc0201474:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201478:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020147a:	85a6                	mv	a1,s1
ffffffffc020147c:	8552                	mv	a0,s4
ffffffffc020147e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201480:	fe0d9ce3          	bnez	s11,ffffffffc0201478 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201484:	00044783          	lbu	a5,0(s0)
ffffffffc0201488:	00140a13          	addi	s4,s0,1
ffffffffc020148c:	0007851b          	sext.w	a0,a5
ffffffffc0201490:	d3a5                	beqz	a5,ffffffffc02013f0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201492:	05e00413          	li	s0,94
ffffffffc0201496:	bf39                	j	ffffffffc02013b4 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201498:	000a2403          	lw	s0,0(s4)
ffffffffc020149c:	b7ad                	j	ffffffffc0201406 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020149e:	000a6603          	lwu	a2,0(s4)
ffffffffc02014a2:	46a1                	li	a3,8
ffffffffc02014a4:	8a2e                	mv	s4,a1
ffffffffc02014a6:	bdb1                	j	ffffffffc0201302 <vprintfmt+0x156>
ffffffffc02014a8:	000a6603          	lwu	a2,0(s4)
ffffffffc02014ac:	46a9                	li	a3,10
ffffffffc02014ae:	8a2e                	mv	s4,a1
ffffffffc02014b0:	bd89                	j	ffffffffc0201302 <vprintfmt+0x156>
ffffffffc02014b2:	000a6603          	lwu	a2,0(s4)
ffffffffc02014b6:	46c1                	li	a3,16
ffffffffc02014b8:	8a2e                	mv	s4,a1
ffffffffc02014ba:	b5a1                	j	ffffffffc0201302 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02014bc:	9902                	jalr	s2
ffffffffc02014be:	bf09                	j	ffffffffc02013d0 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02014c0:	85a6                	mv	a1,s1
ffffffffc02014c2:	02d00513          	li	a0,45
ffffffffc02014c6:	e03e                	sd	a5,0(sp)
ffffffffc02014c8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02014ca:	6782                	ld	a5,0(sp)
ffffffffc02014cc:	8a66                	mv	s4,s9
ffffffffc02014ce:	40800633          	neg	a2,s0
ffffffffc02014d2:	46a9                	li	a3,10
ffffffffc02014d4:	b53d                	j	ffffffffc0201302 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02014d6:	03b05163          	blez	s11,ffffffffc02014f8 <vprintfmt+0x34c>
ffffffffc02014da:	02d00693          	li	a3,45
ffffffffc02014de:	f6d79de3          	bne	a5,a3,ffffffffc0201458 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02014e2:	00001417          	auipc	s0,0x1
ffffffffc02014e6:	c5e40413          	addi	s0,s0,-930 # ffffffffc0202140 <buddy_system_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014ea:	02800793          	li	a5,40
ffffffffc02014ee:	02800513          	li	a0,40
ffffffffc02014f2:	00140a13          	addi	s4,s0,1
ffffffffc02014f6:	bd6d                	j	ffffffffc02013b0 <vprintfmt+0x204>
ffffffffc02014f8:	00001a17          	auipc	s4,0x1
ffffffffc02014fc:	c49a0a13          	addi	s4,s4,-951 # ffffffffc0202141 <buddy_system_pmm_manager+0x179>
ffffffffc0201500:	02800513          	li	a0,40
ffffffffc0201504:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201508:	05e00413          	li	s0,94
ffffffffc020150c:	b565                	j	ffffffffc02013b4 <vprintfmt+0x208>

ffffffffc020150e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020150e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201510:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201514:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201516:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201518:	ec06                	sd	ra,24(sp)
ffffffffc020151a:	f83a                	sd	a4,48(sp)
ffffffffc020151c:	fc3e                	sd	a5,56(sp)
ffffffffc020151e:	e0c2                	sd	a6,64(sp)
ffffffffc0201520:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201522:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201524:	c89ff0ef          	jal	ra,ffffffffc02011ac <vprintfmt>
}
ffffffffc0201528:	60e2                	ld	ra,24(sp)
ffffffffc020152a:	6161                	addi	sp,sp,80
ffffffffc020152c:	8082                	ret

ffffffffc020152e <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020152e:	715d                	addi	sp,sp,-80
ffffffffc0201530:	e486                	sd	ra,72(sp)
ffffffffc0201532:	e0a6                	sd	s1,64(sp)
ffffffffc0201534:	fc4a                	sd	s2,56(sp)
ffffffffc0201536:	f84e                	sd	s3,48(sp)
ffffffffc0201538:	f452                	sd	s4,40(sp)
ffffffffc020153a:	f056                	sd	s5,32(sp)
ffffffffc020153c:	ec5a                	sd	s6,24(sp)
ffffffffc020153e:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201540:	c901                	beqz	a0,ffffffffc0201550 <readline+0x22>
ffffffffc0201542:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201544:	00001517          	auipc	a0,0x1
ffffffffc0201548:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202158 <buddy_system_pmm_manager+0x190>
ffffffffc020154c:	b67fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201550:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201552:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201554:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201556:	4aa9                	li	s5,10
ffffffffc0201558:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020155a:	00005b97          	auipc	s7,0x5
ffffffffc020155e:	bbeb8b93          	addi	s7,s7,-1090 # ffffffffc0206118 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201562:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201566:	bc5fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020156a:	00054a63          	bltz	a0,ffffffffc020157e <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020156e:	00a95a63          	bge	s2,a0,ffffffffc0201582 <readline+0x54>
ffffffffc0201572:	029a5263          	bge	s4,s1,ffffffffc0201596 <readline+0x68>
        c = getchar();
ffffffffc0201576:	bb5fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020157a:	fe055ae3          	bgez	a0,ffffffffc020156e <readline+0x40>
            return NULL;
ffffffffc020157e:	4501                	li	a0,0
ffffffffc0201580:	a091                	j	ffffffffc02015c4 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201582:	03351463          	bne	a0,s3,ffffffffc02015aa <readline+0x7c>
ffffffffc0201586:	e8a9                	bnez	s1,ffffffffc02015d8 <readline+0xaa>
        c = getchar();
ffffffffc0201588:	ba3fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020158c:	fe0549e3          	bltz	a0,ffffffffc020157e <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201590:	fea959e3          	bge	s2,a0,ffffffffc0201582 <readline+0x54>
ffffffffc0201594:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201596:	e42a                	sd	a0,8(sp)
ffffffffc0201598:	b51fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc020159c:	6522                	ld	a0,8(sp)
ffffffffc020159e:	009b87b3          	add	a5,s7,s1
ffffffffc02015a2:	2485                	addiw	s1,s1,1
ffffffffc02015a4:	00a78023          	sb	a0,0(a5)
ffffffffc02015a8:	bf7d                	j	ffffffffc0201566 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02015aa:	01550463          	beq	a0,s5,ffffffffc02015b2 <readline+0x84>
ffffffffc02015ae:	fb651ce3          	bne	a0,s6,ffffffffc0201566 <readline+0x38>
            cputchar(c);
ffffffffc02015b2:	b37fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02015b6:	00005517          	auipc	a0,0x5
ffffffffc02015ba:	b6250513          	addi	a0,a0,-1182 # ffffffffc0206118 <buf>
ffffffffc02015be:	94aa                	add	s1,s1,a0
ffffffffc02015c0:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02015c4:	60a6                	ld	ra,72(sp)
ffffffffc02015c6:	6486                	ld	s1,64(sp)
ffffffffc02015c8:	7962                	ld	s2,56(sp)
ffffffffc02015ca:	79c2                	ld	s3,48(sp)
ffffffffc02015cc:	7a22                	ld	s4,40(sp)
ffffffffc02015ce:	7a82                	ld	s5,32(sp)
ffffffffc02015d0:	6b62                	ld	s6,24(sp)
ffffffffc02015d2:	6bc2                	ld	s7,16(sp)
ffffffffc02015d4:	6161                	addi	sp,sp,80
ffffffffc02015d6:	8082                	ret
            cputchar(c);
ffffffffc02015d8:	4521                	li	a0,8
ffffffffc02015da:	b0ffe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02015de:	34fd                	addiw	s1,s1,-1
ffffffffc02015e0:	b759                	j	ffffffffc0201566 <readline+0x38>

ffffffffc02015e2 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015e2:	4781                	li	a5,0
ffffffffc02015e4:	00005717          	auipc	a4,0x5
ffffffffc02015e8:	a2473703          	ld	a4,-1500(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015ec:	88ba                	mv	a7,a4
ffffffffc02015ee:	852a                	mv	a0,a0
ffffffffc02015f0:	85be                	mv	a1,a5
ffffffffc02015f2:	863e                	mv	a2,a5
ffffffffc02015f4:	00000073          	ecall
ffffffffc02015f8:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015fa:	8082                	ret

ffffffffc02015fc <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02015fc:	4781                	li	a5,0
ffffffffc02015fe:	00005717          	auipc	a4,0x5
ffffffffc0201602:	f5a73703          	ld	a4,-166(a4) # ffffffffc0206558 <SBI_SET_TIMER>
ffffffffc0201606:	88ba                	mv	a7,a4
ffffffffc0201608:	852a                	mv	a0,a0
ffffffffc020160a:	85be                	mv	a1,a5
ffffffffc020160c:	863e                	mv	a2,a5
ffffffffc020160e:	00000073          	ecall
ffffffffc0201612:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201614:	8082                	ret

ffffffffc0201616 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201616:	4501                	li	a0,0
ffffffffc0201618:	00005797          	auipc	a5,0x5
ffffffffc020161c:	9e87b783          	ld	a5,-1560(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201620:	88be                	mv	a7,a5
ffffffffc0201622:	852a                	mv	a0,a0
ffffffffc0201624:	85aa                	mv	a1,a0
ffffffffc0201626:	862a                	mv	a2,a0
ffffffffc0201628:	00000073          	ecall
ffffffffc020162c:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc020162e:	2501                	sext.w	a0,a0
ffffffffc0201630:	8082                	ret

ffffffffc0201632 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201632:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201634:	e589                	bnez	a1,ffffffffc020163e <strnlen+0xc>
ffffffffc0201636:	a811                	j	ffffffffc020164a <strnlen+0x18>
        cnt ++;
ffffffffc0201638:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020163a:	00f58863          	beq	a1,a5,ffffffffc020164a <strnlen+0x18>
ffffffffc020163e:	00f50733          	add	a4,a0,a5
ffffffffc0201642:	00074703          	lbu	a4,0(a4)
ffffffffc0201646:	fb6d                	bnez	a4,ffffffffc0201638 <strnlen+0x6>
ffffffffc0201648:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020164a:	852e                	mv	a0,a1
ffffffffc020164c:	8082                	ret

ffffffffc020164e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020164e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201652:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201656:	cb89                	beqz	a5,ffffffffc0201668 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201658:	0505                	addi	a0,a0,1
ffffffffc020165a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020165c:	fee789e3          	beq	a5,a4,ffffffffc020164e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201660:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201664:	9d19                	subw	a0,a0,a4
ffffffffc0201666:	8082                	ret
ffffffffc0201668:	4501                	li	a0,0
ffffffffc020166a:	bfed                	j	ffffffffc0201664 <strcmp+0x16>

ffffffffc020166c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020166c:	00054783          	lbu	a5,0(a0)
ffffffffc0201670:	c799                	beqz	a5,ffffffffc020167e <strchr+0x12>
        if (*s == c) {
ffffffffc0201672:	00f58763          	beq	a1,a5,ffffffffc0201680 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201676:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020167a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020167c:	fbfd                	bnez	a5,ffffffffc0201672 <strchr+0x6>
    }
    return NULL;
ffffffffc020167e:	4501                	li	a0,0
}
ffffffffc0201680:	8082                	ret

ffffffffc0201682 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201682:	ca01                	beqz	a2,ffffffffc0201692 <memset+0x10>
ffffffffc0201684:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201686:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201688:	0785                	addi	a5,a5,1
ffffffffc020168a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020168e:	fec79de3          	bne	a5,a2,ffffffffc0201688 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201692:	8082                	ret
