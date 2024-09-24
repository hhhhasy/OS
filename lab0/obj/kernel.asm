
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00003117          	auipc	sp,0x3
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	0040006f          	j	8020000c <kern_init>

000000008020000c <kern_init>:
#include <sbi.h>
int kern_init(void) __attribute__((noreturn));

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000c:	00003517          	auipc	a0,0x3
    80200010:	ffc50513          	addi	a0,a0,-4 # 80203008 <edata>
    80200014:	00003617          	auipc	a2,0x3
    80200018:	ff460613          	addi	a2,a2,-12 # 80203008 <edata>
int kern_init(void) {
    8020001c:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001e:	4581                	li	a1,0
    80200020:	8e09                	sub	a2,a2,a0
int kern_init(void) {
    80200022:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200024:	4aa000ef          	jal	ra,802004ce <memset>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    80200028:	00000597          	auipc	a1,0x0
    8020002c:	4b858593          	addi	a1,a1,1208 # 802004e0 <memset+0x12>
    80200030:	00000517          	auipc	a0,0x0
    80200034:	4d050513          	addi	a0,a0,1232 # 80200500 <memset+0x32>
    80200038:	020000ef          	jal	ra,80200058 <cprintf>
   while (1)
        ;
    8020003c:	a001                	j	8020003c <kern_init+0x30>

000000008020003e <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    8020003e:	1141                	addi	sp,sp,-16
    80200040:	e022                	sd	s0,0(sp)
    80200042:	e406                	sd	ra,8(sp)
    80200044:	842e                	mv	s0,a1
    cons_putc(c);
    80200046:	046000ef          	jal	ra,8020008c <cons_putc>
    (*cnt)++;
    8020004a:	401c                	lw	a5,0(s0)
}
    8020004c:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    8020004e:	2785                	addiw	a5,a5,1
    80200050:	c01c                	sw	a5,0(s0)
}
    80200052:	6402                	ld	s0,0(sp)
    80200054:	0141                	addi	sp,sp,16
    80200056:	8082                	ret

0000000080200058 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200058:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    8020005a:	02810313          	addi	t1,sp,40 # 80203028 <edata+0x20>
int cprintf(const char *fmt, ...) {
    8020005e:	f42e                	sd	a1,40(sp)
    80200060:	f832                	sd	a2,48(sp)
    80200062:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200064:	862a                	mv	a2,a0
    80200066:	004c                	addi	a1,sp,4
    80200068:	00000517          	auipc	a0,0x0
    8020006c:	fd650513          	addi	a0,a0,-42 # 8020003e <cputch>
    80200070:	869a                	mv	a3,t1
int cprintf(const char *fmt, ...) {
    80200072:	ec06                	sd	ra,24(sp)
    80200074:	e0ba                	sd	a4,64(sp)
    80200076:	e4be                	sd	a5,72(sp)
    80200078:	e8c2                	sd	a6,80(sp)
    8020007a:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    8020007c:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    8020007e:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    80200080:	080000ef          	jal	ra,80200100 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    80200084:	60e2                	ld	ra,24(sp)
    80200086:	4512                	lw	a0,4(sp)
    80200088:	6125                	addi	sp,sp,96
    8020008a:	8082                	ret

000000008020008c <cons_putc>:

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    8020008c:	0ff57513          	andi	a0,a0,255
    80200090:	3fc0006f          	j	8020048c <sbi_console_putchar>

0000000080200094 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    80200094:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200098:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    8020009a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020009e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    802000a0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    802000a4:	f022                	sd	s0,32(sp)
    802000a6:	ec26                	sd	s1,24(sp)
    802000a8:	e84a                	sd	s2,16(sp)
    802000aa:	f406                	sd	ra,40(sp)
    802000ac:	e44e                	sd	s3,8(sp)
    802000ae:	84aa                	mv	s1,a0
    802000b0:	892e                	mv	s2,a1
    802000b2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802000b6:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
    802000b8:	03067e63          	bleu	a6,a2,802000f4 <printnum+0x60>
    802000bc:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802000be:	00805763          	blez	s0,802000cc <printnum+0x38>
    802000c2:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802000c4:	85ca                	mv	a1,s2
    802000c6:	854e                	mv	a0,s3
    802000c8:	9482                	jalr	s1
        while (-- width > 0)
    802000ca:	fc65                	bnez	s0,802000c2 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    802000cc:	1a02                	slli	s4,s4,0x20
    802000ce:	020a5a13          	srli	s4,s4,0x20
    802000d2:	00000797          	auipc	a5,0x0
    802000d6:	5c678793          	addi	a5,a5,1478 # 80200698 <error_string+0x38>
    802000da:	9a3e                	add	s4,s4,a5
}
    802000dc:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    802000de:	000a4503          	lbu	a0,0(s4)
}
    802000e2:	70a2                	ld	ra,40(sp)
    802000e4:	69a2                	ld	s3,8(sp)
    802000e6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    802000e8:	85ca                	mv	a1,s2
    802000ea:	8326                	mv	t1,s1
}
    802000ec:	6942                	ld	s2,16(sp)
    802000ee:	64e2                	ld	s1,24(sp)
    802000f0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    802000f2:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
    802000f4:	03065633          	divu	a2,a2,a6
    802000f8:	8722                	mv	a4,s0
    802000fa:	f9bff0ef          	jal	ra,80200094 <printnum>
    802000fe:	b7f9                	j	802000cc <printnum+0x38>

0000000080200100 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    80200100:	7119                	addi	sp,sp,-128
    80200102:	f4a6                	sd	s1,104(sp)
    80200104:	f0ca                	sd	s2,96(sp)
    80200106:	e8d2                	sd	s4,80(sp)
    80200108:	e4d6                	sd	s5,72(sp)
    8020010a:	e0da                	sd	s6,64(sp)
    8020010c:	fc5e                	sd	s7,56(sp)
    8020010e:	f862                	sd	s8,48(sp)
    80200110:	f06a                	sd	s10,32(sp)
    80200112:	fc86                	sd	ra,120(sp)
    80200114:	f8a2                	sd	s0,112(sp)
    80200116:	ecce                	sd	s3,88(sp)
    80200118:	f466                	sd	s9,40(sp)
    8020011a:	ec6e                	sd	s11,24(sp)
    8020011c:	892a                	mv	s2,a0
    8020011e:	84ae                	mv	s1,a1
    80200120:	8d32                	mv	s10,a2
    80200122:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    80200124:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
    80200126:	00000a17          	auipc	s4,0x0
    8020012a:	3e2a0a13          	addi	s4,s4,994 # 80200508 <memset+0x3a>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
    8020012e:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200132:	00000c17          	auipc	s8,0x0
    80200136:	52ec0c13          	addi	s8,s8,1326 # 80200660 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020013a:	000d4503          	lbu	a0,0(s10)
    8020013e:	02500793          	li	a5,37
    80200142:	001d0413          	addi	s0,s10,1
    80200146:	00f50e63          	beq	a0,a5,80200162 <vprintfmt+0x62>
            if (ch == '\0') {
    8020014a:	c521                	beqz	a0,80200192 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020014c:	02500993          	li	s3,37
    80200150:	a011                	j	80200154 <vprintfmt+0x54>
            if (ch == '\0') {
    80200152:	c121                	beqz	a0,80200192 <vprintfmt+0x92>
            putch(ch, putdat);
    80200154:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200156:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200158:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020015a:	fff44503          	lbu	a0,-1(s0)
    8020015e:	ff351ae3          	bne	a0,s3,80200152 <vprintfmt+0x52>
    80200162:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200166:	02000793          	li	a5,32
        lflag = altflag = 0;
    8020016a:	4981                	li	s3,0
    8020016c:	4801                	li	a6,0
        width = precision = -1;
    8020016e:	5cfd                	li	s9,-1
    80200170:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
    80200172:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
    80200176:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200178:	fdd6069b          	addiw	a3,a2,-35
    8020017c:	0ff6f693          	andi	a3,a3,255
    80200180:	00140d13          	addi	s10,s0,1
    80200184:	20d5e563          	bltu	a1,a3,8020038e <vprintfmt+0x28e>
    80200188:	068a                	slli	a3,a3,0x2
    8020018a:	96d2                	add	a3,a3,s4
    8020018c:	4294                	lw	a3,0(a3)
    8020018e:	96d2                	add	a3,a3,s4
    80200190:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    80200192:	70e6                	ld	ra,120(sp)
    80200194:	7446                	ld	s0,112(sp)
    80200196:	74a6                	ld	s1,104(sp)
    80200198:	7906                	ld	s2,96(sp)
    8020019a:	69e6                	ld	s3,88(sp)
    8020019c:	6a46                	ld	s4,80(sp)
    8020019e:	6aa6                	ld	s5,72(sp)
    802001a0:	6b06                	ld	s6,64(sp)
    802001a2:	7be2                	ld	s7,56(sp)
    802001a4:	7c42                	ld	s8,48(sp)
    802001a6:	7ca2                	ld	s9,40(sp)
    802001a8:	7d02                	ld	s10,32(sp)
    802001aa:	6de2                	ld	s11,24(sp)
    802001ac:	6109                	addi	sp,sp,128
    802001ae:	8082                	ret
    if (lflag >= 2) {
    802001b0:	4705                	li	a4,1
    802001b2:	008a8593          	addi	a1,s5,8
    802001b6:	01074463          	blt	a4,a6,802001be <vprintfmt+0xbe>
    else if (lflag) {
    802001ba:	26080363          	beqz	a6,80200420 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
    802001be:	000ab603          	ld	a2,0(s5)
    802001c2:	46c1                	li	a3,16
    802001c4:	8aae                	mv	s5,a1
    802001c6:	a06d                	j	80200270 <vprintfmt+0x170>
            goto reswitch;
    802001c8:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    802001cc:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
    802001ce:	846a                	mv	s0,s10
            goto reswitch;
    802001d0:	b765                	j	80200178 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
    802001d2:	000aa503          	lw	a0,0(s5)
    802001d6:	85a6                	mv	a1,s1
    802001d8:	0aa1                	addi	s5,s5,8
    802001da:	9902                	jalr	s2
            break;
    802001dc:	bfb9                	j	8020013a <vprintfmt+0x3a>
    if (lflag >= 2) {
    802001de:	4705                	li	a4,1
    802001e0:	008a8993          	addi	s3,s5,8
    802001e4:	01074463          	blt	a4,a6,802001ec <vprintfmt+0xec>
    else if (lflag) {
    802001e8:	22080463          	beqz	a6,80200410 <vprintfmt+0x310>
        return va_arg(*ap, long);
    802001ec:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
    802001f0:	24044463          	bltz	s0,80200438 <vprintfmt+0x338>
            num = getint(&ap, lflag);
    802001f4:	8622                	mv	a2,s0
    802001f6:	8ace                	mv	s5,s3
    802001f8:	46a9                	li	a3,10
    802001fa:	a89d                	j	80200270 <vprintfmt+0x170>
            err = va_arg(ap, int);
    802001fc:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200200:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200202:	0aa1                	addi	s5,s5,8
            if (err < 0) {
    80200204:	41f7d69b          	sraiw	a3,a5,0x1f
    80200208:	8fb5                	xor	a5,a5,a3
    8020020a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020020e:	1ad74363          	blt	a4,a3,802003b4 <vprintfmt+0x2b4>
    80200212:	00369793          	slli	a5,a3,0x3
    80200216:	97e2                	add	a5,a5,s8
    80200218:	639c                	ld	a5,0(a5)
    8020021a:	18078d63          	beqz	a5,802003b4 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
    8020021e:	86be                	mv	a3,a5
    80200220:	00000617          	auipc	a2,0x0
    80200224:	52860613          	addi	a2,a2,1320 # 80200748 <error_string+0xe8>
    80200228:	85a6                	mv	a1,s1
    8020022a:	854a                	mv	a0,s2
    8020022c:	240000ef          	jal	ra,8020046c <printfmt>
    80200230:	b729                	j	8020013a <vprintfmt+0x3a>
            lflag ++;
    80200232:	00144603          	lbu	a2,1(s0)
    80200236:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200238:	846a                	mv	s0,s10
            goto reswitch;
    8020023a:	bf3d                	j	80200178 <vprintfmt+0x78>
    if (lflag >= 2) {
    8020023c:	4705                	li	a4,1
    8020023e:	008a8593          	addi	a1,s5,8
    80200242:	01074463          	blt	a4,a6,8020024a <vprintfmt+0x14a>
    else if (lflag) {
    80200246:	1e080263          	beqz	a6,8020042a <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
    8020024a:	000ab603          	ld	a2,0(s5)
    8020024e:	46a1                	li	a3,8
    80200250:	8aae                	mv	s5,a1
    80200252:	a839                	j	80200270 <vprintfmt+0x170>
            putch('0', putdat);
    80200254:	03000513          	li	a0,48
    80200258:	85a6                	mv	a1,s1
    8020025a:	e03e                	sd	a5,0(sp)
    8020025c:	9902                	jalr	s2
            putch('x', putdat);
    8020025e:	85a6                	mv	a1,s1
    80200260:	07800513          	li	a0,120
    80200264:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    80200266:	0aa1                	addi	s5,s5,8
    80200268:	ff8ab603          	ld	a2,-8(s5)
            goto number;
    8020026c:	6782                	ld	a5,0(sp)
    8020026e:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
    80200270:	876e                	mv	a4,s11
    80200272:	85a6                	mv	a1,s1
    80200274:	854a                	mv	a0,s2
    80200276:	e1fff0ef          	jal	ra,80200094 <printnum>
            break;
    8020027a:	b5c1                	j	8020013a <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020027c:	000ab603          	ld	a2,0(s5)
    80200280:	0aa1                	addi	s5,s5,8
    80200282:	1c060663          	beqz	a2,8020044e <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
    80200286:	00160413          	addi	s0,a2,1
    8020028a:	17b05c63          	blez	s11,80200402 <vprintfmt+0x302>
    8020028e:	02d00593          	li	a1,45
    80200292:	14b79263          	bne	a5,a1,802003d6 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200296:	00064783          	lbu	a5,0(a2)
    8020029a:	0007851b          	sext.w	a0,a5
    8020029e:	c905                	beqz	a0,802002ce <vprintfmt+0x1ce>
    802002a0:	000cc563          	bltz	s9,802002aa <vprintfmt+0x1aa>
    802002a4:	3cfd                	addiw	s9,s9,-1
    802002a6:	036c8263          	beq	s9,s6,802002ca <vprintfmt+0x1ca>
                    putch('?', putdat);
    802002aa:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    802002ac:	18098463          	beqz	s3,80200434 <vprintfmt+0x334>
    802002b0:	3781                	addiw	a5,a5,-32
    802002b2:	18fbf163          	bleu	a5,s7,80200434 <vprintfmt+0x334>
                    putch('?', putdat);
    802002b6:	03f00513          	li	a0,63
    802002ba:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802002bc:	0405                	addi	s0,s0,1
    802002be:	fff44783          	lbu	a5,-1(s0)
    802002c2:	3dfd                	addiw	s11,s11,-1
    802002c4:	0007851b          	sext.w	a0,a5
    802002c8:	fd61                	bnez	a0,802002a0 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
    802002ca:	e7b058e3          	blez	s11,8020013a <vprintfmt+0x3a>
    802002ce:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    802002d0:	85a6                	mv	a1,s1
    802002d2:	02000513          	li	a0,32
    802002d6:	9902                	jalr	s2
            for (; width > 0; width --) {
    802002d8:	e60d81e3          	beqz	s11,8020013a <vprintfmt+0x3a>
    802002dc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    802002de:	85a6                	mv	a1,s1
    802002e0:	02000513          	li	a0,32
    802002e4:	9902                	jalr	s2
            for (; width > 0; width --) {
    802002e6:	fe0d94e3          	bnez	s11,802002ce <vprintfmt+0x1ce>
    802002ea:	bd81                	j	8020013a <vprintfmt+0x3a>
    if (lflag >= 2) {
    802002ec:	4705                	li	a4,1
    802002ee:	008a8593          	addi	a1,s5,8
    802002f2:	01074463          	blt	a4,a6,802002fa <vprintfmt+0x1fa>
    else if (lflag) {
    802002f6:	12080063          	beqz	a6,80200416 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
    802002fa:	000ab603          	ld	a2,0(s5)
    802002fe:	46a9                	li	a3,10
    80200300:	8aae                	mv	s5,a1
    80200302:	b7bd                	j	80200270 <vprintfmt+0x170>
    80200304:	00144603          	lbu	a2,1(s0)
            padc = '-';
    80200308:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
    8020030c:	846a                	mv	s0,s10
    8020030e:	b5ad                	j	80200178 <vprintfmt+0x78>
            putch(ch, putdat);
    80200310:	85a6                	mv	a1,s1
    80200312:	02500513          	li	a0,37
    80200316:	9902                	jalr	s2
            break;
    80200318:	b50d                	j	8020013a <vprintfmt+0x3a>
            precision = va_arg(ap, int);
    8020031a:	000aac83          	lw	s9,0(s5)
            goto process_precision;
    8020031e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200322:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200324:	846a                	mv	s0,s10
            if (width < 0)
    80200326:	e40dd9e3          	bgez	s11,80200178 <vprintfmt+0x78>
                width = precision, precision = -1;
    8020032a:	8de6                	mv	s11,s9
    8020032c:	5cfd                	li	s9,-1
    8020032e:	b5a9                	j	80200178 <vprintfmt+0x78>
            goto reswitch;
    80200330:	00144603          	lbu	a2,1(s0)
            padc = '0';
    80200334:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
    80200338:	846a                	mv	s0,s10
            goto reswitch;
    8020033a:	bd3d                	j	80200178 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
    8020033c:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
    80200340:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    80200344:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    80200346:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    8020034a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    8020034e:	fcd56ce3          	bltu	a0,a3,80200326 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
    80200352:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    80200354:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
    80200358:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
    8020035c:	0196873b          	addw	a4,a3,s9
    80200360:	0017171b          	slliw	a4,a4,0x1
    80200364:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
    80200368:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
    8020036c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
    80200370:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
    80200374:	fcd57fe3          	bleu	a3,a0,80200352 <vprintfmt+0x252>
    80200378:	b77d                	j	80200326 <vprintfmt+0x226>
            if (width < 0)
    8020037a:	fffdc693          	not	a3,s11
    8020037e:	96fd                	srai	a3,a3,0x3f
    80200380:	00ddfdb3          	and	s11,s11,a3
    80200384:	00144603          	lbu	a2,1(s0)
    80200388:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
    8020038a:	846a                	mv	s0,s10
    8020038c:	b3f5                	j	80200178 <vprintfmt+0x78>
            putch('%', putdat);
    8020038e:	85a6                	mv	a1,s1
    80200390:	02500513          	li	a0,37
    80200394:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    80200396:	fff44703          	lbu	a4,-1(s0)
    8020039a:	02500793          	li	a5,37
    8020039e:	8d22                	mv	s10,s0
    802003a0:	d8f70de3          	beq	a4,a5,8020013a <vprintfmt+0x3a>
    802003a4:	02500713          	li	a4,37
    802003a8:	1d7d                	addi	s10,s10,-1
    802003aa:	fffd4783          	lbu	a5,-1(s10)
    802003ae:	fee79de3          	bne	a5,a4,802003a8 <vprintfmt+0x2a8>
    802003b2:	b361                	j	8020013a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    802003b4:	00000617          	auipc	a2,0x0
    802003b8:	38460613          	addi	a2,a2,900 # 80200738 <error_string+0xd8>
    802003bc:	85a6                	mv	a1,s1
    802003be:	854a                	mv	a0,s2
    802003c0:	0ac000ef          	jal	ra,8020046c <printfmt>
    802003c4:	bb9d                	j	8020013a <vprintfmt+0x3a>
                p = "(null)";
    802003c6:	00000617          	auipc	a2,0x0
    802003ca:	36a60613          	addi	a2,a2,874 # 80200730 <error_string+0xd0>
            if (width > 0 && padc != '-') {
    802003ce:	00000417          	auipc	s0,0x0
    802003d2:	36340413          	addi	s0,s0,867 # 80200731 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802003d6:	8532                	mv	a0,a2
    802003d8:	85e6                	mv	a1,s9
    802003da:	e032                	sd	a2,0(sp)
    802003dc:	e43e                	sd	a5,8(sp)
    802003de:	0ca000ef          	jal	ra,802004a8 <strnlen>
    802003e2:	40ad8dbb          	subw	s11,s11,a0
    802003e6:	6602                	ld	a2,0(sp)
    802003e8:	01b05d63          	blez	s11,80200402 <vprintfmt+0x302>
    802003ec:	67a2                	ld	a5,8(sp)
    802003ee:	2781                	sext.w	a5,a5
    802003f0:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
    802003f2:	6522                	ld	a0,8(sp)
    802003f4:	85a6                	mv	a1,s1
    802003f6:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
    802003f8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    802003fa:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    802003fc:	6602                	ld	a2,0(sp)
    802003fe:	fe0d9ae3          	bnez	s11,802003f2 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200402:	00064783          	lbu	a5,0(a2)
    80200406:	0007851b          	sext.w	a0,a5
    8020040a:	e8051be3          	bnez	a0,802002a0 <vprintfmt+0x1a0>
    8020040e:	b335                	j	8020013a <vprintfmt+0x3a>
        return va_arg(*ap, int);
    80200410:	000aa403          	lw	s0,0(s5)
    80200414:	bbf1                	j	802001f0 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
    80200416:	000ae603          	lwu	a2,0(s5)
    8020041a:	46a9                	li	a3,10
    8020041c:	8aae                	mv	s5,a1
    8020041e:	bd89                	j	80200270 <vprintfmt+0x170>
    80200420:	000ae603          	lwu	a2,0(s5)
    80200424:	46c1                	li	a3,16
    80200426:	8aae                	mv	s5,a1
    80200428:	b5a1                	j	80200270 <vprintfmt+0x170>
    8020042a:	000ae603          	lwu	a2,0(s5)
    8020042e:	46a1                	li	a3,8
    80200430:	8aae                	mv	s5,a1
    80200432:	bd3d                	j	80200270 <vprintfmt+0x170>
                    putch(ch, putdat);
    80200434:	9902                	jalr	s2
    80200436:	b559                	j	802002bc <vprintfmt+0x1bc>
                putch('-', putdat);
    80200438:	85a6                	mv	a1,s1
    8020043a:	02d00513          	li	a0,45
    8020043e:	e03e                	sd	a5,0(sp)
    80200440:	9902                	jalr	s2
                num = -(long long)num;
    80200442:	8ace                	mv	s5,s3
    80200444:	40800633          	neg	a2,s0
    80200448:	46a9                	li	a3,10
    8020044a:	6782                	ld	a5,0(sp)
    8020044c:	b515                	j	80200270 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
    8020044e:	01b05663          	blez	s11,8020045a <vprintfmt+0x35a>
    80200452:	02d00693          	li	a3,45
    80200456:	f6d798e3          	bne	a5,a3,802003c6 <vprintfmt+0x2c6>
    8020045a:	00000417          	auipc	s0,0x0
    8020045e:	2d740413          	addi	s0,s0,727 # 80200731 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200462:	02800513          	li	a0,40
    80200466:	02800793          	li	a5,40
    8020046a:	bd1d                	j	802002a0 <vprintfmt+0x1a0>

000000008020046c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020046c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020046e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200472:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200474:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200476:	ec06                	sd	ra,24(sp)
    80200478:	f83a                	sd	a4,48(sp)
    8020047a:	fc3e                	sd	a5,56(sp)
    8020047c:	e0c2                	sd	a6,64(sp)
    8020047e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    80200480:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200482:	c7fff0ef          	jal	ra,80200100 <vprintfmt>
}
    80200486:	60e2                	ld	ra,24(sp)
    80200488:	6161                	addi	sp,sp,80
    8020048a:	8082                	ret

000000008020048c <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
    8020048c:	00003797          	auipc	a5,0x3
    80200490:	b7478793          	addi	a5,a5,-1164 # 80203000 <bootstacktop>
    __asm__ volatile (
    80200494:	6398                	ld	a4,0(a5)
    80200496:	4781                	li	a5,0
    80200498:	88ba                	mv	a7,a4
    8020049a:	852a                	mv	a0,a0
    8020049c:	85be                	mv	a1,a5
    8020049e:	863e                	mv	a2,a5
    802004a0:	00000073          	ecall
    802004a4:	87aa                	mv	a5,a0
}
    802004a6:	8082                	ret

00000000802004a8 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
    802004a8:	c185                	beqz	a1,802004c8 <strnlen+0x20>
    802004aa:	00054783          	lbu	a5,0(a0)
    802004ae:	cf89                	beqz	a5,802004c8 <strnlen+0x20>
    size_t cnt = 0;
    802004b0:	4781                	li	a5,0
    802004b2:	a021                	j	802004ba <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
    802004b4:	00074703          	lbu	a4,0(a4)
    802004b8:	c711                	beqz	a4,802004c4 <strnlen+0x1c>
        cnt ++;
    802004ba:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802004bc:	00f50733          	add	a4,a0,a5
    802004c0:	fef59ae3          	bne	a1,a5,802004b4 <strnlen+0xc>
    }
    return cnt;
}
    802004c4:	853e                	mv	a0,a5
    802004c6:	8082                	ret
    size_t cnt = 0;
    802004c8:	4781                	li	a5,0
}
    802004ca:	853e                	mv	a0,a5
    802004cc:	8082                	ret

00000000802004ce <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802004ce:	ca01                	beqz	a2,802004de <memset+0x10>
    802004d0:	962a                	add	a2,a2,a0
    char *p = s;
    802004d2:	87aa                	mv	a5,a0
        *p ++ = c;
    802004d4:	0785                	addi	a5,a5,1
    802004d6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802004da:	fec79de3          	bne	a5,a2,802004d4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802004de:	8082                	ret
