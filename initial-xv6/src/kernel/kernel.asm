
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	95070713          	add	a4,a4,-1712 # 800089a0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	62e78793          	add	a5,a5,1582 # 80006690 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd880f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	add	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	ad2080e7          	jalr	-1326(ra) # 80002bfc <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	95c50513          	add	a0,a0,-1700 # 80010ae0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	94c48493          	add	s1,s1,-1716 # 80010ae0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	9dc90913          	add	s2,s2,-1572 # 80010b78 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	8da080e7          	jalr	-1830(ra) # 80001a8e <myproc>
    800001bc:	00003097          	auipc	ra,0x3
    800001c0:	872080e7          	jalr	-1934(ra) # 80002a2e <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	5b0080e7          	jalr	1456(ra) # 8000277a <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	90270713          	add	a4,a4,-1790 # 80010ae0 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00003097          	auipc	ra,0x3
    80000214:	996080e7          	jalr	-1642(ra) # 80002ba6 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	8b850513          	add	a0,a0,-1864 # 80010ae0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	8a250513          	add	a0,a0,-1886 # 80010ae0 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	90f72523          	sw	a5,-1782(a4) # 80010b78 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	81850513          	add	a0,a0,-2024 # 80010ae0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00003097          	auipc	ra,0x3
    800002f2:	964080e7          	jalr	-1692(ra) # 80002c52 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7ea50513          	add	a0,a0,2026 # 80010ae0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	7c670713          	add	a4,a4,1990 # 80010ae0 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	79c78793          	add	a5,a5,1948 # 80010ae0 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8067a783          	lw	a5,-2042(a5) # 80010b78 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	75a70713          	add	a4,a4,1882 # 80010ae0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	74a48493          	add	s1,s1,1866 # 80010ae0 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	70e70713          	add	a4,a4,1806 # 80010ae0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	78f72c23          	sw	a5,1944(a4) # 80010b80 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	6d278793          	add	a5,a5,1746 # 80010ae0 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	74c7a523          	sw	a2,1866(a5) # 80010b7c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	73e50513          	add	a0,a0,1854 # 80010b78 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	39c080e7          	jalr	924(ra) # 800027de <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	68450513          	add	a0,a0,1668 # 80010ae0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00025797          	auipc	a5,0x25
    80000478:	9e478793          	add	a5,a5,-1564 # 80024e58 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	6407ac23          	sw	zero,1624(a5) # 80010ba0 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	add	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	3ef72223          	sw	a5,996(a4) # 80008960 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	5e8dad83          	lw	s11,1512(s11) # 80010ba0 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	59250513          	add	a0,a0,1426 # 80010b88 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	43450513          	add	a0,a0,1076 # 80010b88 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	41848493          	add	s1,s1,1048 # 80010b88 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	3d850513          	add	a0,a0,984 # 80010ba8 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	1647a783          	lw	a5,356(a5) # 80008960 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	1347b783          	ld	a5,308(a5) # 80008968 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	13473703          	ld	a4,308(a4) # 80008970 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	34aa0a13          	add	s4,s4,842 # 80010ba8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	10248493          	add	s1,s1,258 # 80008968 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	10298993          	add	s3,s3,258 # 80008970 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	f4e080e7          	jalr	-178(ra) # 800027de <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	2dc50513          	add	a0,a0,732 # 80010ba8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0847a783          	lw	a5,132(a5) # 80008960 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	08a73703          	ld	a4,138(a4) # 80008970 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	07a7b783          	ld	a5,122(a5) # 80008968 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	2ae98993          	add	s3,s3,686 # 80010ba8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	06648493          	add	s1,s1,102 # 80008968 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	06690913          	add	s2,s2,102 # 80008970 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	e60080e7          	jalr	-416(ra) # 8000277a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	27848493          	add	s1,s1,632 # 80010ba8 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	02e7b623          	sd	a4,44(a5) # 80008970 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	1f248493          	add	s1,s1,498 # 80010ba8 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	add	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	sll	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00025797          	auipc	a5,0x25
    800009fc:	5f878793          	add	a5,a5,1528 # 80025ff0 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	sll	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	1c890913          	add	s2,s2,456 # 80010be0 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	add	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	add	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	add	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	add	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	add	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	12a50513          	add	a0,a0,298 # 80010be0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00025517          	auipc	a0,0x25
    80000ace:	52650513          	add	a0,a0,1318 # 80025ff0 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	add	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	add	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	0f448493          	add	s1,s1,244 # 80010be0 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	0dc50513          	add	a0,a0,220 # 80010be0 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	add	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	0b050513          	add	a0,a0,176 # 80010be0 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	add	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	add	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	f06080e7          	jalr	-250(ra) # 80001a72 <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	add	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	add	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	ed4080e7          	jalr	-300(ra) # 80001a72 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	ec8080e7          	jalr	-312(ra) # 80001a72 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	add	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	eb0080e7          	jalr	-336(ra) # 80001a72 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srl	s1,s1,0x1
    80000bcc:	8885                	and	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	add	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	add	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	e70080e7          	jalr	-400(ra) # 80001a72 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	add	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	add	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	add	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e44080e7          	jalr	-444(ra) # 80001a72 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	and	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	add	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	add	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	add	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	add	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	add	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	add	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	add	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	add	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	sll	a2,a2,0x20
    80000cda:	9201                	srl	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	add	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	add	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	add	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	sll	a3,a3,0x20
    80000cfe:	9281                	srl	a3,a3,0x20
    80000d00:	0685                	add	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	add	a0,a0,1
    80000d12:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	add	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	add	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	sll	a2,a2,0x20
    80000d38:	9201                	srl	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	add	a1,a1,1
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9011>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	sll	a3,a2,0x20
    80000d5a:	9281                	srl	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addw	a5,a2,-1
    80000d6a:	1782                	sll	a5,a5,0x20
    80000d6c:	9381                	srl	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	add	a4,a4,-1
    80000d76:	16fd                	add	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	add	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	add	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	add	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addw	a2,a2,-1
    80000db6:	0505                	add	a0,a0,1
    80000db8:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	add	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	add	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	add	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	add	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	add	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	add	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addw	a3,a2,-1
    80000e24:	1682                	sll	a3,a3,0x20
    80000e26:	9281                	srl	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	add	a1,a1,1
    80000e32:	0785                	add	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	add	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	add	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	add	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	add	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	add	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	add	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	be8080e7          	jalr	-1048(ra) # 80001a62 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	af670713          	add	a4,a4,-1290 # 80008978 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bcc080e7          	jalr	-1076(ra) # 80001a62 <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	add	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	086080e7          	jalr	134(ra) # 80002f3e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00006097          	auipc	ra,0x6
    80000ec4:	810080e7          	jalr	-2032(ra) # 800066d0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	780080e7          	jalr	1920(ra) # 80002648 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	add	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	add	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	a86080e7          	jalr	-1402(ra) # 800019ae <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	fe6080e7          	jalr	-26(ra) # 80002f16 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	006080e7          	jalr	6(ra) # 80002f3e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	77a080e7          	jalr	1914(ra) # 800066ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	788080e7          	jalr	1928(ra) # 800066d0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	97c080e7          	jalr	-1668(ra) # 800038cc <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	01a080e7          	jalr	26(ra) # 80003f72 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	f90080e7          	jalr	-112(ra) # 80004ef0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00006097          	auipc	ra,0x6
    80000f6c:	870080e7          	jalr	-1936(ra) # 800067d8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	e54080e7          	jalr	-428(ra) # 80001dc4 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9ef72d23          	sw	a5,-1542(a4) # 80008978 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	add	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	9ee7b783          	ld	a5,-1554(a5) # 80008980 <kernel_pagetable>
    80000f9a:	83b1                	srl	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	sll	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	add	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	add	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	add	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srl	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	add	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srl	a5,s1,0xc
    80001006:	07aa                	sll	a5,a5,0xa
    80001008:	0017e793          	or	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd9007>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	and	s2,s2,511
    8000101e:	090e                	sll	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	and	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srl	s1,s1,0xa
    8000102e:	04b2                	sll	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srl	a0,s3,0xc
    80001036:	1ff57513          	and	a0,a0,511
    8000103a:	050e                	sll	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	add	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srl	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	add	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	and	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srl	a5,a5,0xa
    8000108e:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	add	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	add	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	and	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srl	s1,s1,0xc
    800010e8:	04aa                	sll	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	or	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	add	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	add	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	add	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	add	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	add	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	add	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	add	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	add	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	add	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	add	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	sll	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	sll	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	add	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	sll	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	6f0080e7          	jalr	1776(ra) # 80001918 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	add	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	add	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	72a7b923          	sd	a0,1842(a5) # 80008980 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	add	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	add	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	sll	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	sll	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	add	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	add	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	add	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	add	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	add	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	and	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	and	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	sll	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	add	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	add	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	add	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	add	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	add	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	add	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	add	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	add	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	add	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	add	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	add	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	add	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	sll	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	add	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	and	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	and	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	add	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	add	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	add	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	add	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	add	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srl	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	add	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	add	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	and	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srl	a1,a4,0xa
    8000159e:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	add	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	add	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srl	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	add	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	add	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	and	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	add	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	add	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	add	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	add	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	add	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	add	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	add	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	add	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	add	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	add	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	add	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9010>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	add	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	add	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <init_queues>:
// guard page.

struct queue mlfq_queues[total_queue]; // this is mine array of size 4

void init_queues()
{
    80001830:	1141                	add	sp,sp,-16
    80001832:	e422                	sd	s0,8(sp)
    80001834:	0800                	add	s0,sp,16
  for (int i = 0; i < total_queue; i++)
  {
    mlfq_queues[i].head = NULL;
    80001836:	0000f797          	auipc	a5,0xf
    8000183a:	3ca78793          	add	a5,a5,970 # 80010c00 <mlfq_queues>
    8000183e:	0007b023          	sd	zero,0(a5)
    mlfq_queues[i].tail = NULL;
    80001842:	0007b423          	sd	zero,8(a5)
    mlfq_queues[i].head = NULL;
    80001846:	0007b823          	sd	zero,16(a5)
    mlfq_queues[i].tail = NULL;
    8000184a:	0007bc23          	sd	zero,24(a5)
    mlfq_queues[i].head = NULL;
    8000184e:	0207b023          	sd	zero,32(a5)
    mlfq_queues[i].tail = NULL;
    80001852:	0207b423          	sd	zero,40(a5)
    mlfq_queues[i].head = NULL;
    80001856:	0207b823          	sd	zero,48(a5)
    mlfq_queues[i].tail = NULL;
    8000185a:	0207bc23          	sd	zero,56(a5)
  }
}
    8000185e:	6422                	ld	s0,8(sp)
    80001860:	0141                	add	sp,sp,16
    80001862:	8082                	ret

0000000080001864 <enqueue>:

void enqueue(int priority, struct proc *p)
{
  if (priority < 0 || priority >= total_queue)
    80001864:	470d                	li	a4,3
    80001866:	02a76863          	bltu	a4,a0,80001896 <enqueue+0x32>
    8000186a:	87aa                	mv	a5,a0
  {
    printf("Enter valid priority\n");
    return;
  }
  // Set next pointer to NULL
  p->next = NULL;
    8000186c:	2205b423          	sd	zero,552(a1)

  // Insert into the linked list  we need to insert at the end
  if (mlfq_queues[priority].tail)
    80001870:	00451693          	sll	a3,a0,0x4
    80001874:	0000f717          	auipc	a4,0xf
    80001878:	38c70713          	add	a4,a4,908 # 80010c00 <mlfq_queues>
    8000187c:	9736                	add	a4,a4,a3
    8000187e:	6718                	ld	a4,8(a4)
    80001880:	cb1d                	beqz	a4,800018b6 <enqueue+0x52>
  {
    mlfq_queues[priority].tail->next = p; // Append to the end
    80001882:	22b73423          	sd	a1,552(a4)
  }
  else
  {
    mlfq_queues[priority].head = p; // First element
  }
  mlfq_queues[priority].tail = p; // Update tail
    80001886:	0792                	sll	a5,a5,0x4
    80001888:	0000f717          	auipc	a4,0xf
    8000188c:	37870713          	add	a4,a4,888 # 80010c00 <mlfq_queues>
    80001890:	97ba                	add	a5,a5,a4
    80001892:	e78c                	sd	a1,8(a5)
    80001894:	8082                	ret
{
    80001896:	1141                	add	sp,sp,-16
    80001898:	e406                	sd	ra,8(sp)
    8000189a:	e022                	sd	s0,0(sp)
    8000189c:	0800                	add	s0,sp,16
    printf("Enter valid priority\n");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	93a50513          	add	a0,a0,-1734 # 800081d8 <digits+0x198>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce0080e7          	jalr	-800(ra) # 80000586 <printf>
}
    800018ae:	60a2                	ld	ra,8(sp)
    800018b0:	6402                	ld	s0,0(sp)
    800018b2:	0141                	add	sp,sp,16
    800018b4:	8082                	ret
    mlfq_queues[priority].head = p; // First element
    800018b6:	00451693          	sll	a3,a0,0x4
    800018ba:	0000f717          	auipc	a4,0xf
    800018be:	34670713          	add	a4,a4,838 # 80010c00 <mlfq_queues>
    800018c2:	9736                	add	a4,a4,a3
    800018c4:	e30c                	sd	a1,0(a4)
    800018c6:	b7c1                	j	80001886 <enqueue+0x22>

00000000800018c8 <dequeue>:

struct proc *dequeue(int priority)
{
    800018c8:	1141                	add	sp,sp,-16
    800018ca:	e422                	sd	s0,8(sp)
    800018cc:	0800                	add	s0,sp,16
  if (priority < 0 || priority >= total_queue)
    800018ce:	478d                	li	a5,3
    800018d0:	04a7e263          	bltu	a5,a0,80001914 <dequeue+0x4c>
    800018d4:	872a                	mv	a4,a0
  {
    return NULL;
  }
  // Remove from the front of the linked list
  struct proc *p = mlfq_queues[priority].head;
    800018d6:	00451693          	sll	a3,a0,0x4
    800018da:	0000f797          	auipc	a5,0xf
    800018de:	32678793          	add	a5,a5,806 # 80010c00 <mlfq_queues>
    800018e2:	97b6                	add	a5,a5,a3
    800018e4:	6388                	ld	a0,0(a5)
  if (p != NULL)
    800018e6:	cd01                	beqz	a0,800018fe <dequeue+0x36>
  {
    mlfq_queues[priority].head = p->next; // Update head
    800018e8:	22853683          	ld	a3,552(a0)
    800018ec:	00471613          	sll	a2,a4,0x4
    800018f0:	0000f797          	auipc	a5,0xf
    800018f4:	31078793          	add	a5,a5,784 # 80010c00 <mlfq_queues>
    800018f8:	97b2                	add	a5,a5,a2
    800018fa:	e394                	sd	a3,0(a5)
    if (!mlfq_queues[priority].head)
    800018fc:	c681                	beqz	a3,80001904 <dequeue+0x3c>
    {
      mlfq_queues[priority].tail = NULL; // List is empty
    }
  }
  return p;
}
    800018fe:	6422                	ld	s0,8(sp)
    80001900:	0141                	add	sp,sp,16
    80001902:	8082                	ret
      mlfq_queues[priority].tail = NULL; // List is empty
    80001904:	0000f797          	auipc	a5,0xf
    80001908:	2fc78793          	add	a5,a5,764 # 80010c00 <mlfq_queues>
    8000190c:	97b2                	add	a5,a5,a2
    8000190e:	0007b423          	sd	zero,8(a5)
    80001912:	b7f5                	j	800018fe <dequeue+0x36>
    return NULL;
    80001914:	4501                	li	a0,0
    80001916:	b7e5                	j	800018fe <dequeue+0x36>

0000000080001918 <proc_mapstacks>:

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001918:	7139                	add	sp,sp,-64
    8000191a:	fc06                	sd	ra,56(sp)
    8000191c:	f822                	sd	s0,48(sp)
    8000191e:	f426                	sd	s1,40(sp)
    80001920:	f04a                	sd	s2,32(sp)
    80001922:	ec4e                	sd	s3,24(sp)
    80001924:	e852                	sd	s4,16(sp)
    80001926:	e456                	sd	s5,8(sp)
    80001928:	e05a                	sd	s6,0(sp)
    8000192a:	0080                	add	s0,sp,64
    8000192c:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000192e:	00010497          	auipc	s1,0x10
    80001932:	6e248493          	add	s1,s1,1762 # 80012010 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001936:	8b26                	mv	s6,s1
    80001938:	00006a97          	auipc	s5,0x6
    8000193c:	6c8a8a93          	add	s5,s5,1736 # 80008000 <etext>
    80001940:	04000937          	lui	s2,0x4000
    80001944:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001946:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001948:	00019a17          	auipc	s4,0x19
    8000194c:	2c8a0a13          	add	s4,s4,712 # 8001ac10 <tickslock>
    char *pa = kalloc();
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	192080e7          	jalr	402(ra) # 80000ae2 <kalloc>
    80001958:	862a                	mv	a2,a0
    if (pa == 0)
    8000195a:	c131                	beqz	a0,8000199e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000195c:	416485b3          	sub	a1,s1,s6
    80001960:	8591                	sra	a1,a1,0x4
    80001962:	000ab783          	ld	a5,0(s5)
    80001966:	02f585b3          	mul	a1,a1,a5
    8000196a:	2585                	addw	a1,a1,1
    8000196c:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001970:	4719                	li	a4,6
    80001972:	6685                	lui	a3,0x1
    80001974:	40b905b3          	sub	a1,s2,a1
    80001978:	854e                	mv	a0,s3
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	7be080e7          	jalr	1982(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001982:	23048493          	add	s1,s1,560
    80001986:	fd4495e3          	bne	s1,s4,80001950 <proc_mapstacks+0x38>
  }
}
    8000198a:	70e2                	ld	ra,56(sp)
    8000198c:	7442                	ld	s0,48(sp)
    8000198e:	74a2                	ld	s1,40(sp)
    80001990:	7902                	ld	s2,32(sp)
    80001992:	69e2                	ld	s3,24(sp)
    80001994:	6a42                	ld	s4,16(sp)
    80001996:	6aa2                	ld	s5,8(sp)
    80001998:	6b02                	ld	s6,0(sp)
    8000199a:	6121                	add	sp,sp,64
    8000199c:	8082                	ret
      panic("kalloc");
    8000199e:	00007517          	auipc	a0,0x7
    800019a2:	85250513          	add	a0,a0,-1966 # 800081f0 <digits+0x1b0>
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	b96080e7          	jalr	-1130(ra) # 8000053c <panic>

00000000800019ae <procinit>:

// initialize the proc table.
void procinit(void)
{
    800019ae:	7139                	add	sp,sp,-64
    800019b0:	fc06                	sd	ra,56(sp)
    800019b2:	f822                	sd	s0,48(sp)
    800019b4:	f426                	sd	s1,40(sp)
    800019b6:	f04a                	sd	s2,32(sp)
    800019b8:	ec4e                	sd	s3,24(sp)
    800019ba:	e852                	sd	s4,16(sp)
    800019bc:	e456                	sd	s5,8(sp)
    800019be:	e05a                	sd	s6,0(sp)
    800019c0:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019c2:	00007597          	auipc	a1,0x7
    800019c6:	83658593          	add	a1,a1,-1994 # 800081f8 <digits+0x1b8>
    800019ca:	0000f517          	auipc	a0,0xf
    800019ce:	27650513          	add	a0,a0,630 # 80010c40 <pid_lock>
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	170080e7          	jalr	368(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019da:	00007597          	auipc	a1,0x7
    800019de:	82658593          	add	a1,a1,-2010 # 80008200 <digits+0x1c0>
    800019e2:	0000f517          	auipc	a0,0xf
    800019e6:	27650513          	add	a0,a0,630 # 80010c58 <wait_lock>
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	158080e7          	jalr	344(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019f2:	00010497          	auipc	s1,0x10
    800019f6:	61e48493          	add	s1,s1,1566 # 80012010 <proc>
  {
    initlock(&p->lock, "proc");
    800019fa:	00007b17          	auipc	s6,0x7
    800019fe:	816b0b13          	add	s6,s6,-2026 # 80008210 <digits+0x1d0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a02:	8aa6                	mv	s5,s1
    80001a04:	00006a17          	auipc	s4,0x6
    80001a08:	5fca0a13          	add	s4,s4,1532 # 80008000 <etext>
    80001a0c:	04000937          	lui	s2,0x4000
    80001a10:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a12:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a14:	00019997          	auipc	s3,0x19
    80001a18:	1fc98993          	add	s3,s3,508 # 8001ac10 <tickslock>
    initlock(&p->lock, "proc");
    80001a1c:	85da                	mv	a1,s6
    80001a1e:	8526                	mv	a0,s1
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	122080e7          	jalr	290(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001a28:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a2c:	415487b3          	sub	a5,s1,s5
    80001a30:	8791                	sra	a5,a5,0x4
    80001a32:	000a3703          	ld	a4,0(s4)
    80001a36:	02e787b3          	mul	a5,a5,a4
    80001a3a:	2785                	addw	a5,a5,1
    80001a3c:	00d7979b          	sllw	a5,a5,0xd
    80001a40:	40f907b3          	sub	a5,s2,a5
    80001a44:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a46:	23048493          	add	s1,s1,560
    80001a4a:	fd3499e3          	bne	s1,s3,80001a1c <procinit+0x6e>
  }
}
    80001a4e:	70e2                	ld	ra,56(sp)
    80001a50:	7442                	ld	s0,48(sp)
    80001a52:	74a2                	ld	s1,40(sp)
    80001a54:	7902                	ld	s2,32(sp)
    80001a56:	69e2                	ld	s3,24(sp)
    80001a58:	6a42                	ld	s4,16(sp)
    80001a5a:	6aa2                	ld	s5,8(sp)
    80001a5c:	6b02                	ld	s6,0(sp)
    80001a5e:	6121                	add	sp,sp,64
    80001a60:	8082                	ret

0000000080001a62 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a62:	1141                	add	sp,sp,-16
    80001a64:	e422                	sd	s0,8(sp)
    80001a66:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a68:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a6a:	2501                	sext.w	a0,a0
    80001a6c:	6422                	ld	s0,8(sp)
    80001a6e:	0141                	add	sp,sp,16
    80001a70:	8082                	ret

0000000080001a72 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a72:	1141                	add	sp,sp,-16
    80001a74:	e422                	sd	s0,8(sp)
    80001a76:	0800                	add	s0,sp,16
    80001a78:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a7a:	2781                	sext.w	a5,a5
    80001a7c:	079e                	sll	a5,a5,0x7
  return c;
}
    80001a7e:	0000f517          	auipc	a0,0xf
    80001a82:	1f250513          	add	a0,a0,498 # 80010c70 <cpus>
    80001a86:	953e                	add	a0,a0,a5
    80001a88:	6422                	ld	s0,8(sp)
    80001a8a:	0141                	add	sp,sp,16
    80001a8c:	8082                	ret

0000000080001a8e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a8e:	1101                	add	sp,sp,-32
    80001a90:	ec06                	sd	ra,24(sp)
    80001a92:	e822                	sd	s0,16(sp)
    80001a94:	e426                	sd	s1,8(sp)
    80001a96:	1000                	add	s0,sp,32
  push_off();
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	0ee080e7          	jalr	238(ra) # 80000b86 <push_off>
    80001aa0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa2:	2781                	sext.w	a5,a5
    80001aa4:	079e                	sll	a5,a5,0x7
    80001aa6:	0000f717          	auipc	a4,0xf
    80001aaa:	15a70713          	add	a4,a4,346 # 80010c00 <mlfq_queues>
    80001aae:	97ba                	add	a5,a5,a4
    80001ab0:	7ba4                	ld	s1,112(a5)
  pop_off();
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	174080e7          	jalr	372(ra) # 80000c26 <pop_off>
  return p;
}
    80001aba:	8526                	mv	a0,s1
    80001abc:	60e2                	ld	ra,24(sp)
    80001abe:	6442                	ld	s0,16(sp)
    80001ac0:	64a2                	ld	s1,8(sp)
    80001ac2:	6105                	add	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ac6:	1141                	add	sp,sp,-16
    80001ac8:	e406                	sd	ra,8(sp)
    80001aca:	e022                	sd	s0,0(sp)
    80001acc:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ace:	00000097          	auipc	ra,0x0
    80001ad2:	fc0080e7          	jalr	-64(ra) # 80001a8e <myproc>
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	1b0080e7          	jalr	432(ra) # 80000c86 <release>

  if (first)
    80001ade:	00007797          	auipc	a5,0x7
    80001ae2:	e027a783          	lw	a5,-510(a5) # 800088e0 <first.1>
    80001ae6:	eb89                	bnez	a5,80001af8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ae8:	00001097          	auipc	ra,0x1
    80001aec:	46e080e7          	jalr	1134(ra) # 80002f56 <usertrapret>
}
    80001af0:	60a2                	ld	ra,8(sp)
    80001af2:	6402                	ld	s0,0(sp)
    80001af4:	0141                	add	sp,sp,16
    80001af6:	8082                	ret
    first = 0;
    80001af8:	00007797          	auipc	a5,0x7
    80001afc:	de07a423          	sw	zero,-536(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001b00:	4505                	li	a0,1
    80001b02:	00002097          	auipc	ra,0x2
    80001b06:	3f0080e7          	jalr	1008(ra) # 80003ef2 <fsinit>
    80001b0a:	bff9                	j	80001ae8 <forkret+0x22>

0000000080001b0c <allocpid>:
{
    80001b0c:	1101                	add	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b18:	0000f917          	auipc	s2,0xf
    80001b1c:	12890913          	add	s2,s2,296 # 80010c40 <pid_lock>
    80001b20:	854a                	mv	a0,s2
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	0b0080e7          	jalr	176(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001b2a:	00007797          	auipc	a5,0x7
    80001b2e:	dc678793          	add	a5,a5,-570 # 800088f0 <nextpid>
    80001b32:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b34:	0014871b          	addw	a4,s1,1
    80001b38:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3a:	854a                	mv	a0,s2
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	14a080e7          	jalr	330(ra) # 80000c86 <release>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	add	sp,sp,32
    80001b50:	8082                	ret

0000000080001b52 <proc_pagetable>:
{
    80001b52:	1101                	add	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	add	s0,sp,32
    80001b5e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	7c2080e7          	jalr	1986(ra) # 80001322 <uvmcreate>
    80001b68:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b6a:	c121                	beqz	a0,80001baa <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b6c:	4729                	li	a4,10
    80001b6e:	00005697          	auipc	a3,0x5
    80001b72:	49268693          	add	a3,a3,1170 # 80007000 <_trampoline>
    80001b76:	6605                	lui	a2,0x1
    80001b78:	040005b7          	lui	a1,0x4000
    80001b7c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7e:	05b2                	sll	a1,a1,0xc
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	518080e7          	jalr	1304(ra) # 80001098 <mappages>
    80001b88:	02054863          	bltz	a0,80001bb8 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b8c:	4719                	li	a4,6
    80001b8e:	05893683          	ld	a3,88(s2)
    80001b92:	6605                	lui	a2,0x1
    80001b94:	020005b7          	lui	a1,0x2000
    80001b98:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b9a:	05b6                	sll	a1,a1,0xd
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	4fa080e7          	jalr	1274(ra) # 80001098 <mappages>
    80001ba6:	02054163          	bltz	a0,80001bc8 <proc_pagetable+0x76>
}
    80001baa:	8526                	mv	a0,s1
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6902                	ld	s2,0(sp)
    80001bb4:	6105                	add	sp,sp,32
    80001bb6:	8082                	ret
    uvmfree(pagetable, 0);
    80001bb8:	4581                	li	a1,0
    80001bba:	8526                	mv	a0,s1
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	96c080e7          	jalr	-1684(ra) # 80001528 <uvmfree>
    return 0;
    80001bc4:	4481                	li	s1,0
    80001bc6:	b7d5                	j	80001baa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc8:	4681                	li	a3,0
    80001bca:	4605                	li	a2,1
    80001bcc:	040005b7          	lui	a1,0x4000
    80001bd0:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bd2:	05b2                	sll	a1,a1,0xc
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	688080e7          	jalr	1672(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001bde:	4581                	li	a1,0
    80001be0:	8526                	mv	a0,s1
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	946080e7          	jalr	-1722(ra) # 80001528 <uvmfree>
    return 0;
    80001bea:	4481                	li	s1,0
    80001bec:	bf7d                	j	80001baa <proc_pagetable+0x58>

0000000080001bee <proc_freepagetable>:
{
    80001bee:	1101                	add	sp,sp,-32
    80001bf0:	ec06                	sd	ra,24(sp)
    80001bf2:	e822                	sd	s0,16(sp)
    80001bf4:	e426                	sd	s1,8(sp)
    80001bf6:	e04a                	sd	s2,0(sp)
    80001bf8:	1000                	add	s0,sp,32
    80001bfa:	84aa                	mv	s1,a0
    80001bfc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfe:	4681                	li	a3,0
    80001c00:	4605                	li	a2,1
    80001c02:	040005b7          	lui	a1,0x4000
    80001c06:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c08:	05b2                	sll	a1,a1,0xc
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	654080e7          	jalr	1620(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c12:	4681                	li	a3,0
    80001c14:	4605                	li	a2,1
    80001c16:	020005b7          	lui	a1,0x2000
    80001c1a:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c1c:	05b6                	sll	a1,a1,0xd
    80001c1e:	8526                	mv	a0,s1
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	63e080e7          	jalr	1598(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c28:	85ca                	mv	a1,s2
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	8fc080e7          	jalr	-1796(ra) # 80001528 <uvmfree>
}
    80001c34:	60e2                	ld	ra,24(sp)
    80001c36:	6442                	ld	s0,16(sp)
    80001c38:	64a2                	ld	s1,8(sp)
    80001c3a:	6902                	ld	s2,0(sp)
    80001c3c:	6105                	add	sp,sp,32
    80001c3e:	8082                	ret

0000000080001c40 <freeproc>:
{
    80001c40:	1101                	add	sp,sp,-32
    80001c42:	ec06                	sd	ra,24(sp)
    80001c44:	e822                	sd	s0,16(sp)
    80001c46:	e426                	sd	s1,8(sp)
    80001c48:	1000                	add	s0,sp,32
    80001c4a:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c4c:	6d28                	ld	a0,88(a0)
    80001c4e:	c509                	beqz	a0,80001c58 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	d94080e7          	jalr	-620(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c58:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c5c:	68a8                	ld	a0,80(s1)
    80001c5e:	c511                	beqz	a0,80001c6a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c60:	64ac                	ld	a1,72(s1)
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	f8c080e7          	jalr	-116(ra) # 80001bee <proc_freepagetable>
  p->pagetable = 0;
    80001c6a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c6e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c72:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c76:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c7a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c7e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c82:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c86:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c8a:	0004ac23          	sw	zero,24(s1)
}
    80001c8e:	60e2                	ld	ra,24(sp)
    80001c90:	6442                	ld	s0,16(sp)
    80001c92:	64a2                	ld	s1,8(sp)
    80001c94:	6105                	add	sp,sp,32
    80001c96:	8082                	ret

0000000080001c98 <allocproc>:
{
    80001c98:	1101                	add	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	e04a                	sd	s2,0(sp)
    80001ca2:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ca4:	00010497          	auipc	s1,0x10
    80001ca8:	36c48493          	add	s1,s1,876 # 80012010 <proc>
    80001cac:	00019917          	auipc	s2,0x19
    80001cb0:	f6490913          	add	s2,s2,-156 # 8001ac10 <tickslock>
    acquire(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	f1c080e7          	jalr	-228(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001cbe:	4c9c                	lw	a5,24(s1)
    80001cc0:	cf81                	beqz	a5,80001cd8 <allocproc+0x40>
      release(&p->lock); // Release lock if not UNUSED
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	fc2080e7          	jalr	-62(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ccc:	23048493          	add	s1,s1,560
    80001cd0:	ff2492e3          	bne	s1,s2,80001cb4 <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001cd4:	4481                	li	s1,0
    80001cd6:	a845                	j	80001d86 <allocproc+0xee>
  p->pid = allocpid(); // Assign PID
    80001cd8:	00000097          	auipc	ra,0x0
    80001cdc:	e34080e7          	jalr	-460(ra) # 80001b0c <allocpid>
    80001ce0:	d888                	sw	a0,48(s1)
  p->state = USED;     // Mark process as USED
    80001ce2:	4785                	li	a5,1
    80001ce4:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < 31; i++)
    80001ce6:	17448793          	add	a5,s1,372
    80001cea:	1f048713          	add	a4,s1,496
    p->syscall_count[i] = 0;
    80001cee:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < 31; i++)
    80001cf2:	0791                	add	a5,a5,4
    80001cf4:	fee79de3          	bne	a5,a4,80001cee <allocproc+0x56>
  p->tickets = 1; // since by default a process should have 1 ticket
    80001cf8:	4785                	li	a5,1
    80001cfa:	20f4a823          	sw	a5,528(s1)
  p->creation_time = ticks;
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	c9a7e783          	lwu	a5,-870(a5) # 80008998 <ticks>
    80001d06:	20f4bc23          	sd	a5,536(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	dd8080e7          	jalr	-552(ra) # 80000ae2 <kalloc>
    80001d12:	892a                	mv	s2,a0
    80001d14:	eca8                	sd	a0,88(s1)
    80001d16:	cd3d                	beqz	a0,80001d94 <allocproc+0xfc>
  p->pagetable = proc_pagetable(p);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	e38080e7          	jalr	-456(ra) # 80001b52 <proc_pagetable>
    80001d22:	892a                	mv	s2,a0
    80001d24:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d26:	c159                	beqz	a0,80001dac <allocproc+0x114>
  memset(&p->context, 0, sizeof(p->context));
    80001d28:	07000613          	li	a2,112
    80001d2c:	4581                	li	a1,0
    80001d2e:	06048513          	add	a0,s1,96
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f9c080e7          	jalr	-100(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001d3a:	00000797          	auipc	a5,0x0
    80001d3e:	d8c78793          	add	a5,a5,-628 # 80001ac6 <forkret>
    80001d42:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d44:	60bc                	ld	a5,64(s1)
    80001d46:	6705                	lui	a4,0x1
    80001d48:	97ba                	add	a5,a5,a4
    80001d4a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;     // Initialize runtime
    80001d4c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;     // Initialize exit time
    80001d50:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks; // Record creation time
    80001d54:	00007797          	auipc	a5,0x7
    80001d58:	c447a783          	lw	a5,-956(a5) # 80008998 <ticks>
    80001d5c:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001d60:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001d64:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001d68:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001d6c:	2004a223          	sw	zero,516(s1)
  p->priority = 0;              // Start in highest priority queue
    80001d70:	2204a023          	sw	zero,544(s1)
  p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    80001d74:	4785                	li	a5,1
    80001d76:	22f4a223          	sw	a5,548(s1)
  enqueue(0, p);                // Add to queue 0
    80001d7a:	85a6                	mv	a1,s1
    80001d7c:	4501                	li	a0,0
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	ae6080e7          	jalr	-1306(ra) # 80001864 <enqueue>
}
    80001d86:	8526                	mv	a0,s1
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6902                	ld	s2,0(sp)
    80001d90:	6105                	add	sp,sp,32
    80001d92:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001d94:	8526                	mv	a0,s1
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	eaa080e7          	jalr	-342(ra) # 80001c40 <freeproc>
    release(&p->lock); // Release lock
    80001d9e:	8526                	mv	a0,s1
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	ee6080e7          	jalr	-282(ra) # 80000c86 <release>
    return 0;
    80001da8:	84ca                	mv	s1,s2
    80001daa:	bff1                	j	80001d86 <allocproc+0xee>
    freeproc(p);       // Clean up if allocation fails
    80001dac:	8526                	mv	a0,s1
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	e92080e7          	jalr	-366(ra) # 80001c40 <freeproc>
    release(&p->lock); // Release lock
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	ece080e7          	jalr	-306(ra) # 80000c86 <release>
    return 0;
    80001dc0:	84ca                	mv	s1,s2
    80001dc2:	b7d1                	j	80001d86 <allocproc+0xee>

0000000080001dc4 <userinit>:
{
    80001dc4:	1101                	add	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	1000                	add	s0,sp,32
  p = allocproc();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	eca080e7          	jalr	-310(ra) # 80001c98 <allocproc>
    80001dd6:	84aa                	mv	s1,a0
  initproc = p;
    80001dd8:	00007797          	auipc	a5,0x7
    80001ddc:	baa7bc23          	sd	a0,-1096(a5) # 80008990 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001de0:	03400613          	li	a2,52
    80001de4:	00007597          	auipc	a1,0x7
    80001de8:	b1c58593          	add	a1,a1,-1252 # 80008900 <initcode>
    80001dec:	6928                	ld	a0,80(a0)
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	562080e7          	jalr	1378(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001df6:	6785                	lui	a5,0x1
    80001df8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dfa:	6cb8                	ld	a4,88(s1)
    80001dfc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e00:	6cb8                	ld	a4,88(s1)
    80001e02:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e04:	4641                	li	a2,16
    80001e06:	00006597          	auipc	a1,0x6
    80001e0a:	41258593          	add	a1,a1,1042 # 80008218 <digits+0x1d8>
    80001e0e:	15848513          	add	a0,s1,344
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	004080e7          	jalr	4(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001e1a:	00006517          	auipc	a0,0x6
    80001e1e:	40e50513          	add	a0,a0,1038 # 80008228 <digits+0x1e8>
    80001e22:	00003097          	auipc	ra,0x3
    80001e26:	aee080e7          	jalr	-1298(ra) # 80004910 <namei>
    80001e2a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e2e:	478d                	li	a5,3
    80001e30:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001e32:	4785                	li	a5,1
    80001e34:	20f4a823          	sw	a5,528(s1)
  release(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e4c080e7          	jalr	-436(ra) # 80000c86 <release>
}
    80001e42:	60e2                	ld	ra,24(sp)
    80001e44:	6442                	ld	s0,16(sp)
    80001e46:	64a2                	ld	s1,8(sp)
    80001e48:	6105                	add	sp,sp,32
    80001e4a:	8082                	ret

0000000080001e4c <growproc>:
{
    80001e4c:	1101                	add	sp,sp,-32
    80001e4e:	ec06                	sd	ra,24(sp)
    80001e50:	e822                	sd	s0,16(sp)
    80001e52:	e426                	sd	s1,8(sp)
    80001e54:	e04a                	sd	s2,0(sp)
    80001e56:	1000                	add	s0,sp,32
    80001e58:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	c34080e7          	jalr	-972(ra) # 80001a8e <myproc>
    80001e62:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e64:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e66:	01204c63          	bgtz	s2,80001e7e <growproc+0x32>
  else if (n < 0)
    80001e6a:	02094663          	bltz	s2,80001e96 <growproc+0x4a>
  p->sz = sz;
    80001e6e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e70:	4501                	li	a0,0
}
    80001e72:	60e2                	ld	ra,24(sp)
    80001e74:	6442                	ld	s0,16(sp)
    80001e76:	64a2                	ld	s1,8(sp)
    80001e78:	6902                	ld	s2,0(sp)
    80001e7a:	6105                	add	sp,sp,32
    80001e7c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e7e:	4691                	li	a3,4
    80001e80:	00b90633          	add	a2,s2,a1
    80001e84:	6928                	ld	a0,80(a0)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	584080e7          	jalr	1412(ra) # 8000140a <uvmalloc>
    80001e8e:	85aa                	mv	a1,a0
    80001e90:	fd79                	bnez	a0,80001e6e <growproc+0x22>
      return -1;
    80001e92:	557d                	li	a0,-1
    80001e94:	bff9                	j	80001e72 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e96:	00b90633          	add	a2,s2,a1
    80001e9a:	6928                	ld	a0,80(a0)
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	526080e7          	jalr	1318(ra) # 800013c2 <uvmdealloc>
    80001ea4:	85aa                	mv	a1,a0
    80001ea6:	b7e1                	j	80001e6e <growproc+0x22>

0000000080001ea8 <fork>:
{
    80001ea8:	7139                	add	sp,sp,-64
    80001eaa:	fc06                	sd	ra,56(sp)
    80001eac:	f822                	sd	s0,48(sp)
    80001eae:	f426                	sd	s1,40(sp)
    80001eb0:	f04a                	sd	s2,32(sp)
    80001eb2:	ec4e                	sd	s3,24(sp)
    80001eb4:	e852                	sd	s4,16(sp)
    80001eb6:	e456                	sd	s5,8(sp)
    80001eb8:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001eba:	00000097          	auipc	ra,0x0
    80001ebe:	bd4080e7          	jalr	-1068(ra) # 80001a8e <myproc>
    80001ec2:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80001c98 <allocproc>
    80001ecc:	12050663          	beqz	a0,80001ff8 <fork+0x150>
    80001ed0:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ed2:	048ab603          	ld	a2,72(s5)
    80001ed6:	692c                	ld	a1,80(a0)
    80001ed8:	050ab503          	ld	a0,80(s5)
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	686080e7          	jalr	1670(ra) # 80001562 <uvmcopy>
    80001ee4:	06054263          	bltz	a0,80001f48 <fork+0xa0>
  np->sz = p->sz;
    80001ee8:	048ab783          	ld	a5,72(s5)
    80001eec:	04f9b423          	sd	a5,72(s3)
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
    80001ef0:	210aa783          	lw	a5,528(s5)
    80001ef4:	20f9a823          	sw	a5,528(s3)
  np->creation_time = ticks; // record its creation time
    80001ef8:	00007797          	auipc	a5,0x7
    80001efc:	aa07e783          	lwu	a5,-1376(a5) # 80008998 <ticks>
    80001f00:	20f9bc23          	sd	a5,536(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f04:	058ab683          	ld	a3,88(s5)
    80001f08:	87b6                	mv	a5,a3
    80001f0a:	0589b703          	ld	a4,88(s3)
    80001f0e:	12068693          	add	a3,a3,288
    80001f12:	0007b803          	ld	a6,0(a5)
    80001f16:	6788                	ld	a0,8(a5)
    80001f18:	6b8c                	ld	a1,16(a5)
    80001f1a:	6f90                	ld	a2,24(a5)
    80001f1c:	01073023          	sd	a6,0(a4)
    80001f20:	e708                	sd	a0,8(a4)
    80001f22:	eb0c                	sd	a1,16(a4)
    80001f24:	ef10                	sd	a2,24(a4)
    80001f26:	02078793          	add	a5,a5,32
    80001f2a:	02070713          	add	a4,a4,32
    80001f2e:	fed792e3          	bne	a5,a3,80001f12 <fork+0x6a>
  np->trapframe->a0 = 0;
    80001f32:	0589b783          	ld	a5,88(s3)
    80001f36:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f3a:	0d0a8493          	add	s1,s5,208
    80001f3e:	0d098913          	add	s2,s3,208
    80001f42:	150a8a13          	add	s4,s5,336
    80001f46:	a00d                	j	80001f68 <fork+0xc0>
    freeproc(np);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	cf6080e7          	jalr	-778(ra) # 80001c40 <freeproc>
    release(&np->lock);
    80001f52:	854e                	mv	a0,s3
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d32080e7          	jalr	-718(ra) # 80000c86 <release>
    return -1;
    80001f5c:	597d                	li	s2,-1
    80001f5e:	a059                	j	80001fe4 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    80001f60:	04a1                	add	s1,s1,8
    80001f62:	0921                	add	s2,s2,8
    80001f64:	01448b63          	beq	s1,s4,80001f7a <fork+0xd2>
    if (p->ofile[i])
    80001f68:	6088                	ld	a0,0(s1)
    80001f6a:	d97d                	beqz	a0,80001f60 <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f6c:	00003097          	auipc	ra,0x3
    80001f70:	016080e7          	jalr	22(ra) # 80004f82 <filedup>
    80001f74:	00a93023          	sd	a0,0(s2)
    80001f78:	b7e5                	j	80001f60 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001f7a:	150ab503          	ld	a0,336(s5)
    80001f7e:	00002097          	auipc	ra,0x2
    80001f82:	1ae080e7          	jalr	430(ra) # 8000412c <idup>
    80001f86:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f8a:	4641                	li	a2,16
    80001f8c:	158a8593          	add	a1,s5,344
    80001f90:	15898513          	add	a0,s3,344
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	e82080e7          	jalr	-382(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f9c:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001fa0:	854e                	mv	a0,s3
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	ce4080e7          	jalr	-796(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001faa:	0000f497          	auipc	s1,0xf
    80001fae:	cae48493          	add	s1,s1,-850 # 80010c58 <wait_lock>
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	c1e080e7          	jalr	-994(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001fbc:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	cc4080e7          	jalr	-828(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001fca:	854e                	mv	a0,s3
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	c06080e7          	jalr	-1018(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001fd4:	478d                	li	a5,3
    80001fd6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fda:	854e                	mv	a0,s3
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	caa080e7          	jalr	-854(ra) # 80000c86 <release>
}
    80001fe4:	854a                	mv	a0,s2
    80001fe6:	70e2                	ld	ra,56(sp)
    80001fe8:	7442                	ld	s0,48(sp)
    80001fea:	74a2                	ld	s1,40(sp)
    80001fec:	7902                	ld	s2,32(sp)
    80001fee:	69e2                	ld	s3,24(sp)
    80001ff0:	6a42                	ld	s4,16(sp)
    80001ff2:	6aa2                	ld	s5,8(sp)
    80001ff4:	6121                	add	sp,sp,64
    80001ff6:	8082                	ret
    return -1;
    80001ff8:	597d                	li	s2,-1
    80001ffa:	b7ed                	j	80001fe4 <fork+0x13c>

0000000080001ffc <simple_atol>:
{
    80001ffc:	1141                	add	sp,sp,-16
    80001ffe:	e422                	sd	s0,8(sp)
    80002000:	0800                	add	s0,sp,16
  for (int i = 0; str[i] != '\0'; ++i)
    80002002:	00054683          	lbu	a3,0(a0)
    80002006:	c295                	beqz	a3,8000202a <simple_atol+0x2e>
    80002008:	00150713          	add	a4,a0,1
  long res = 0;
    8000200c:	4501                	li	a0,0
    res = res * 10 + str[i] - '0';
    8000200e:	00251793          	sll	a5,a0,0x2
    80002012:	97aa                	add	a5,a5,a0
    80002014:	0786                	sll	a5,a5,0x1
    80002016:	97b6                	add	a5,a5,a3
    80002018:	fd078513          	add	a0,a5,-48
  for (int i = 0; str[i] != '\0'; ++i)
    8000201c:	0705                	add	a4,a4,1
    8000201e:	fff74683          	lbu	a3,-1(a4)
    80002022:	f6f5                	bnez	a3,8000200e <simple_atol+0x12>
}
    80002024:	6422                	ld	s0,8(sp)
    80002026:	0141                	add	sp,sp,16
    80002028:	8082                	ret
  long res = 0;
    8000202a:	4501                	li	a0,0
  return res;
    8000202c:	bfe5                	j	80002024 <simple_atol+0x28>

000000008000202e <get_random_seed>:
{
    8000202e:	1141                	add	sp,sp,-16
    80002030:	e422                	sd	s0,8(sp)
    80002032:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80002034:	00007697          	auipc	a3,0x7
    80002038:	8b468693          	add	a3,a3,-1868 # 800088e8 <seed>
    8000203c:	629c                	ld	a5,0(a3)
    8000203e:	41c65737          	lui	a4,0x41c65
    80002042:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80002046:	02e787b3          	mul	a5,a5,a4
    8000204a:	670d                	lui	a4,0x3
    8000204c:	03970713          	add	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80002050:	97ba                	add	a5,a5,a4
    80002052:	1786                	sll	a5,a5,0x21
    80002054:	9385                	srl	a5,a5,0x21
    80002056:	e29c                	sd	a5,0(a3)
}
    80002058:	6509                	lui	a0,0x2
    8000205a:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    8000205e:	02a7f533          	remu	a0,a5,a0
    80002062:	6422                	ld	s0,8(sp)
    80002064:	0141                	add	sp,sp,16
    80002066:	8082                	ret

0000000080002068 <long_to_padded_string>:
{
    80002068:	1141                	add	sp,sp,-16
    8000206a:	e422                	sd	s0,8(sp)
    8000206c:	0800                	add	s0,sp,16
  long temp = num;
    8000206e:	87aa                	mv	a5,a0
  int len = 0;
    80002070:	4681                	li	a3,0
    temp /= 10;
    80002072:	4329                	li	t1,10
  } while (temp > 0);
    80002074:	48a5                	li	a7,9
    len++;
    80002076:	0016871b          	addw	a4,a3,1
    8000207a:	0007069b          	sext.w	a3,a4
    temp /= 10;
    8000207e:	883e                	mv	a6,a5
    80002080:	0267c7b3          	div	a5,a5,t1
  } while (temp > 0);
    80002084:	ff08c9e3          	blt	a7,a6,80002076 <long_to_padded_string+0xe>
  int padding = total_length - len;
    80002088:	40e5873b          	subw	a4,a1,a4
    8000208c:	0007089b          	sext.w	a7,a4
  for (int i = 0; i < padding; i++)
    80002090:	01105c63          	blez	a7,800020a8 <long_to_padded_string+0x40>
    80002094:	87b2                	mv	a5,a2
    80002096:	00c88833          	add	a6,a7,a2
    result[i] = '0';
    8000209a:	03000693          	li	a3,48
    8000209e:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < padding; i++)
    800020a2:	0785                	add	a5,a5,1
    800020a4:	ff079de3          	bne	a5,a6,8000209e <long_to_padded_string+0x36>
  for (int i = total_length - 1; i >= padding; i--)
    800020a8:	fff5879b          	addw	a5,a1,-1
    800020ac:	0317ca63          	blt	a5,a7,800020e0 <long_to_padded_string+0x78>
    800020b0:	97b2                	add	a5,a5,a2
    800020b2:	ffe60813          	add	a6,a2,-2 # ffe <_entry-0x7ffff002>
    800020b6:	982e                	add	a6,a6,a1
    800020b8:	fff5869b          	addw	a3,a1,-1
    800020bc:	40e6873b          	subw	a4,a3,a4
    800020c0:	1702                	sll	a4,a4,0x20
    800020c2:	9301                	srl	a4,a4,0x20
    800020c4:	40e80833          	sub	a6,a6,a4
    result[i] = (num % 10) + '0';
    800020c8:	46a9                	li	a3,10
    800020ca:	02d56733          	rem	a4,a0,a3
    800020ce:	0307071b          	addw	a4,a4,48
    800020d2:	00e78023          	sb	a4,0(a5)
    num /= 10;
    800020d6:	02d54533          	div	a0,a0,a3
  for (int i = total_length - 1; i >= padding; i--)
    800020da:	17fd                	add	a5,a5,-1
    800020dc:	ff0797e3          	bne	a5,a6,800020ca <long_to_padded_string+0x62>
  result[total_length] = '\0'; // Null-terminate the string
    800020e0:	962e                	add	a2,a2,a1
    800020e2:	00060023          	sb	zero,0(a2)
}
    800020e6:	6422                	ld	s0,8(sp)
    800020e8:	0141                	add	sp,sp,16
    800020ea:	8082                	ret

00000000800020ec <pseudo_rand_num_generator>:
{
    800020ec:	7119                	add	sp,sp,-128
    800020ee:	fc86                	sd	ra,120(sp)
    800020f0:	f8a2                	sd	s0,112(sp)
    800020f2:	f4a6                	sd	s1,104(sp)
    800020f4:	f0ca                	sd	s2,96(sp)
    800020f6:	ecce                	sd	s3,88(sp)
    800020f8:	e8d2                	sd	s4,80(sp)
    800020fa:	e4d6                	sd	s5,72(sp)
    800020fc:	e0da                	sd	s6,64(sp)
    800020fe:	fc5e                	sd	s7,56(sp)
    80002100:	f862                	sd	s8,48(sp)
    80002102:	f466                	sd	s9,40(sp)
    80002104:	0100                	add	s0,sp,128
    80002106:	84aa                	mv	s1,a0
    80002108:	8aae                	mv	s5,a1
  if (iterations == 0 && lst_index > 0)
    8000210a:	e1a1                	bnez	a1,8000214a <pseudo_rand_num_generator+0x5e>
    8000210c:	00007797          	auipc	a5,0x7
    80002110:	8807a783          	lw	a5,-1920(a5) # 8000898c <lst_index>
    80002114:	02f04263          	bgtz	a5,80002138 <pseudo_rand_num_generator+0x4c>
  int seed_size = strlen(initial_seed);
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	d30080e7          	jalr	-720(ra) # 80000e48 <strlen>
    80002120:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002122:	8526                	mv	a0,s1
    80002124:	00000097          	auipc	ra,0x0
    80002128:	ed8080e7          	jalr	-296(ra) # 80001ffc <simple_atol>
  if (seed_val == 0)
    8000212c:	e561                	bnez	a0,800021f4 <pseudo_rand_num_generator+0x108>
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	f00080e7          	jalr	-256(ra) # 8000202e <get_random_seed>
    80002136:	a02d                	j	80002160 <pseudo_rand_num_generator+0x74>
    return lst[lst_index - 1]; // Return the last generated number
    80002138:	37fd                	addw	a5,a5,-1
    8000213a:	078a                	sll	a5,a5,0x2
    8000213c:	0000f717          	auipc	a4,0xf
    80002140:	f3470713          	add	a4,a4,-204 # 80011070 <lst>
    80002144:	97ba                	add	a5,a5,a4
    80002146:	4388                	lw	a0,0(a5)
    80002148:	a0d1                	j	8000220c <pseudo_rand_num_generator+0x120>
  int seed_size = strlen(initial_seed);
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	cfe080e7          	jalr	-770(ra) # 80000e48 <strlen>
    80002152:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002154:	8526                	mv	a0,s1
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	ea6080e7          	jalr	-346(ra) # 80001ffc <simple_atol>
  if (seed_val == 0)
    8000215e:	d961                	beqz	a0,8000212e <pseudo_rand_num_generator+0x42>
  for (int i = 0; i < iterations; i++)
    80002160:	09505a63          	blez	s5,800021f4 <pseudo_rand_num_generator+0x108>
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    80002164:	00191c9b          	sllw	s9,s2,0x1
    int mid_start = seed_size / 2;
    80002168:	01f9579b          	srlw	a5,s2,0x1f
    8000216c:	012787bb          	addw	a5,a5,s2
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    80002170:	4017d79b          	sraw	a5,a5,0x1
    80002174:	f8040713          	add	a4,s0,-128
    80002178:	00f70bb3          	add	s7,a4,a5
    8000217c:	4481                	li	s1,0
    char new_seed[seed_size + 1];
    8000217e:	00190b1b          	addw	s6,s2,1
    80002182:	0b3d                	add	s6,s6,15
    80002184:	ff0b7b13          	and	s6,s6,-16
    lst[lst_index++] = simple_atol(new_seed);
    80002188:	00007997          	auipc	s3,0x7
    8000218c:	80498993          	add	s3,s3,-2044 # 8000898c <lst_index>
    80002190:	0000fc17          	auipc	s8,0xf
    80002194:	ee0c0c13          	add	s8,s8,-288 # 80011070 <lst>
  {
    80002198:	8a0a                	mv	s4,sp
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    8000219a:	f8040613          	add	a2,s0,-128
    8000219e:	85e6                	mv	a1,s9
    800021a0:	02a50533          	mul	a0,a0,a0
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	ec4080e7          	jalr	-316(ra) # 80002068 <long_to_padded_string>
    char new_seed[seed_size + 1];
    800021ac:	41610133          	sub	sp,sp,s6
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800021b0:	864a                	mv	a2,s2
    800021b2:	85de                	mv	a1,s7
    800021b4:	850a                	mv	a0,sp
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	c24080e7          	jalr	-988(ra) # 80000dda <strncpy>
    new_seed[seed_size] = '\0';                         // Null-terminate
    800021be:	012107b3          	add	a5,sp,s2
    800021c2:	00078023          	sb	zero,0(a5)
    lst[lst_index++] = simple_atol(new_seed);
    800021c6:	850a                	mv	a0,sp
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	e34080e7          	jalr	-460(ra) # 80001ffc <simple_atol>
    800021d0:	0009a783          	lw	a5,0(s3)
    800021d4:	0017871b          	addw	a4,a5,1
    800021d8:	00e9a023          	sw	a4,0(s3)
    800021dc:	078a                	sll	a5,a5,0x2
    800021de:	97e2                	add	a5,a5,s8
    800021e0:	c388                	sw	a0,0(a5)
    seed_val = simple_atol(new_seed);
    800021e2:	850a                	mv	a0,sp
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	e18080e7          	jalr	-488(ra) # 80001ffc <simple_atol>
    800021ec:	8152                	mv	sp,s4
  for (int i = 0; i < iterations; i++)
    800021ee:	2485                	addw	s1,s1,1
    800021f0:	fa9a94e3          	bne	s5,s1,80002198 <pseudo_rand_num_generator+0xac>
  return lst[lst_index - 1];
    800021f4:	00006797          	auipc	a5,0x6
    800021f8:	7987a783          	lw	a5,1944(a5) # 8000898c <lst_index>
    800021fc:	37fd                	addw	a5,a5,-1
    800021fe:	078a                	sll	a5,a5,0x2
    80002200:	0000f717          	auipc	a4,0xf
    80002204:	e7070713          	add	a4,a4,-400 # 80011070 <lst>
    80002208:	97ba                	add	a5,a5,a4
    8000220a:	4388                	lw	a0,0(a5)
}
    8000220c:	f8040113          	add	sp,s0,-128
    80002210:	70e6                	ld	ra,120(sp)
    80002212:	7446                	ld	s0,112(sp)
    80002214:	74a6                	ld	s1,104(sp)
    80002216:	7906                	ld	s2,96(sp)
    80002218:	69e6                	ld	s3,88(sp)
    8000221a:	6a46                	ld	s4,80(sp)
    8000221c:	6aa6                	ld	s5,72(sp)
    8000221e:	6b06                	ld	s6,64(sp)
    80002220:	7be2                	ld	s7,56(sp)
    80002222:	7c42                	ld	s8,48(sp)
    80002224:	7ca2                	ld	s9,40(sp)
    80002226:	6109                	add	sp,sp,128
    80002228:	8082                	ret

000000008000222a <int_to_string>:
{
    8000222a:	1141                	add	sp,sp,-16
    8000222c:	e422                	sd	s0,8(sp)
    8000222e:	0800                	add	s0,sp,16
  int temp = num;
    80002230:	872a                	mv	a4,a0
  int len = 0;
    80002232:	4781                	li	a5,0
    temp /= 10;
    80002234:	48a9                	li	a7,10
  } while (temp > 0);
    80002236:	4825                	li	a6,9
    len++;
    80002238:	863e                	mv	a2,a5
    8000223a:	2785                	addw	a5,a5,1
    temp /= 10;
    8000223c:	86ba                	mv	a3,a4
    8000223e:	0317473b          	divw	a4,a4,a7
  } while (temp > 0);
    80002242:	fed84be3          	blt	a6,a3,80002238 <int_to_string+0xe>
  result[len] = '\0'; // Null-terminate the string
    80002246:	97ae                	add	a5,a5,a1
    80002248:	00078023          	sb	zero,0(a5)
  for (int i = len - 1; i >= 0; i--)
    8000224c:	02064663          	bltz	a2,80002278 <int_to_string+0x4e>
    80002250:	00c587b3          	add	a5,a1,a2
    80002254:	fff58693          	add	a3,a1,-1
    80002258:	96b2                	add	a3,a3,a2
    8000225a:	1602                	sll	a2,a2,0x20
    8000225c:	9201                	srl	a2,a2,0x20
    8000225e:	8e91                	sub	a3,a3,a2
    result[i] = (num % 10) + '0';
    80002260:	4629                	li	a2,10
    80002262:	02c5673b          	remw	a4,a0,a2
    80002266:	0307071b          	addw	a4,a4,48
    8000226a:	00e78023          	sb	a4,0(a5)
    num /= 10;
    8000226e:	02c5453b          	divw	a0,a0,a2
  for (int i = len - 1; i >= 0; i--)
    80002272:	17fd                	add	a5,a5,-1
    80002274:	fed797e3          	bne	a5,a3,80002262 <int_to_string+0x38>
}
    80002278:	6422                	ld	s0,8(sp)
    8000227a:	0141                	add	sp,sp,16
    8000227c:	8082                	ret

000000008000227e <simple_rand>:
{
    8000227e:	1141                	add	sp,sp,-16
    80002280:	e422                	sd	s0,8(sp)
    80002282:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80002284:	00006697          	auipc	a3,0x6
    80002288:	66468693          	add	a3,a3,1636 # 800088e8 <seed>
    8000228c:	629c                	ld	a5,0(a3)
    8000228e:	41c65737          	lui	a4,0x41c65
    80002292:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80002296:	02e787b3          	mul	a5,a5,a4
    8000229a:	0012d737          	lui	a4,0x12d
    8000229e:	68770713          	add	a4,a4,1671 # 12d687 <_entry-0x7fed2979>
    800022a2:	97ba                	add	a5,a5,a4
    800022a4:	1786                	sll	a5,a5,0x21
    800022a6:	9385                	srl	a5,a5,0x21
    800022a8:	e29c                	sd	a5,0(a3)
}
    800022aa:	6509                	lui	a0,0x2
    800022ac:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    800022b0:	02a7f533          	remu	a0,a5,a0
    800022b4:	6422                	ld	s0,8(sp)
    800022b6:	0141                	add	sp,sp,16
    800022b8:	8082                	ret

00000000800022ba <random_at_most>:
{
    800022ba:	1101                	add	sp,sp,-32
    800022bc:	ec06                	sd	ra,24(sp)
    800022be:	e822                	sd	s0,16(sp)
    800022c0:	e426                	sd	s1,8(sp)
    800022c2:	1000                	add	s0,sp,32
    800022c4:	84aa                	mv	s1,a0
  int random_num = simple_rand(); // Use the LCG for random generation
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	fb8080e7          	jalr	-72(ra) # 8000227e <simple_rand>
  return 1 + (random_num % max);  // Return a number in the range [1, max]
    800022ce:	0295653b          	remw	a0,a0,s1
}
    800022d2:	2505                	addw	a0,a0,1
    800022d4:	60e2                	ld	ra,24(sp)
    800022d6:	6442                	ld	s0,16(sp)
    800022d8:	64a2                	ld	s1,8(sp)
    800022da:	6105                	add	sp,sp,32
    800022dc:	8082                	ret

00000000800022de <round_robin_scheduler>:
{
    800022de:	7139                	add	sp,sp,-64
    800022e0:	fc06                	sd	ra,56(sp)
    800022e2:	f822                	sd	s0,48(sp)
    800022e4:	f426                	sd	s1,40(sp)
    800022e6:	f04a                	sd	s2,32(sp)
    800022e8:	ec4e                	sd	s3,24(sp)
    800022ea:	e852                	sd	s4,16(sp)
    800022ec:	e456                	sd	s5,8(sp)
    800022ee:	e05a                	sd	s6,0(sp)
    800022f0:	0080                	add	s0,sp,64
    800022f2:	8792                	mv	a5,tp
  int id = r_tp();
    800022f4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022f6:	00779a93          	sll	s5,a5,0x7
    800022fa:	0000f717          	auipc	a4,0xf
    800022fe:	90670713          	add	a4,a4,-1786 # 80010c00 <mlfq_queues>
    80002302:	9756                	add	a4,a4,s5
    80002304:	06073823          	sd	zero,112(a4)
        swtch(&c->context, &p->context);
    80002308:	0000f717          	auipc	a4,0xf
    8000230c:	97070713          	add	a4,a4,-1680 # 80010c78 <cpus+0x8>
    80002310:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002312:	498d                	li	s3,3
        p->state = RUNNING;
    80002314:	4b11                	li	s6,4
        c->proc = p;
    80002316:	079e                	sll	a5,a5,0x7
    80002318:	0000fa17          	auipc	s4,0xf
    8000231c:	8e8a0a13          	add	s4,s4,-1816 # 80010c00 <mlfq_queues>
    80002320:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002322:	00019917          	auipc	s2,0x19
    80002326:	8ee90913          	add	s2,s2,-1810 # 8001ac10 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000232a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000232e:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002332:	10079073          	csrw	sstatus,a5
    80002336:	00010497          	auipc	s1,0x10
    8000233a:	cda48493          	add	s1,s1,-806 # 80012010 <proc>
    8000233e:	a811                	j	80002352 <round_robin_scheduler+0x74>
      release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	944080e7          	jalr	-1724(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000234a:	23048493          	add	s1,s1,560
    8000234e:	fd248ee3          	beq	s1,s2,8000232a <round_robin_scheduler+0x4c>
      acquire(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87e080e7          	jalr	-1922(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000235c:	4c9c                	lw	a5,24(s1)
    8000235e:	ff3791e3          	bne	a5,s3,80002340 <round_robin_scheduler+0x62>
        p->state = RUNNING;
    80002362:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002366:	069a3823          	sd	s1,112(s4)
        swtch(&c->context, &p->context);
    8000236a:	06048593          	add	a1,s1,96
    8000236e:	8556                	mv	a0,s5
    80002370:	00001097          	auipc	ra,0x1
    80002374:	b3c080e7          	jalr	-1220(ra) # 80002eac <swtch>
        c->proc = 0;
    80002378:	060a3823          	sd	zero,112(s4)
    8000237c:	b7d1                	j	80002340 <round_robin_scheduler+0x62>

000000008000237e <lottery_scheduler>:
{
    8000237e:	715d                	add	sp,sp,-80
    80002380:	e486                	sd	ra,72(sp)
    80002382:	e0a2                	sd	s0,64(sp)
    80002384:	fc26                	sd	s1,56(sp)
    80002386:	f84a                	sd	s2,48(sp)
    80002388:	f44e                	sd	s3,40(sp)
    8000238a:	f052                	sd	s4,32(sp)
    8000238c:	ec56                	sd	s5,24(sp)
    8000238e:	e85a                	sd	s6,16(sp)
    80002390:	e45e                	sd	s7,8(sp)
    80002392:	e062                	sd	s8,0(sp)
    80002394:	0880                	add	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002396:	8792                	mv	a5,tp
  int id = r_tp();
    80002398:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000239a:	00779693          	sll	a3,a5,0x7
    8000239e:	0000f717          	auipc	a4,0xf
    800023a2:	86270713          	add	a4,a4,-1950 # 80010c00 <mlfq_queues>
    800023a6:	9736                	add	a4,a4,a3
    800023a8:	06073823          	sd	zero,112(a4)
        swtch(&c->context, &winner->context);
    800023ac:	0000f717          	auipc	a4,0xf
    800023b0:	8cc70713          	add	a4,a4,-1844 # 80010c78 <cpus+0x8>
    800023b4:	00e68c33          	add	s8,a3,a4
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    800023b8:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800023ba:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023bc:	00019917          	auipc	s2,0x19
    800023c0:	85490913          	add	s2,s2,-1964 # 8001ac10 <tickslock>
        c->proc = winner;
    800023c4:	0000fb17          	auipc	s6,0xf
    800023c8:	83cb0b13          	add	s6,s6,-1988 # 80010c00 <mlfq_queues>
    800023cc:	9b36                	add	s6,s6,a3
    800023ce:	a80d                	j	80002400 <lottery_scheduler+0x82>
      release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b4080e7          	jalr	-1868(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023da:	23048493          	add	s1,s1,560
    800023de:	01248f63          	beq	s1,s2,800023fc <lottery_scheduler+0x7e>
      acquire(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	7ee080e7          	jalr	2030(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    800023ec:	4c9c                	lw	a5,24(s1)
    800023ee:	ff3791e3          	bne	a5,s3,800023d0 <lottery_scheduler+0x52>
        total_tickets += p->tickets; // Accumulate total tickets
    800023f2:	2104a783          	lw	a5,528(s1)
    800023f6:	01478a3b          	addw	s4,a5,s4
    800023fa:	bfd9                	j	800023d0 <lottery_scheduler+0x52>
    if (total_tickets == 0)
    800023fc:	000a1e63          	bnez	s4,80002418 <lottery_scheduler+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002400:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002404:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002408:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    8000240c:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    8000240e:	00010497          	auipc	s1,0x10
    80002412:	c0248493          	add	s1,s1,-1022 # 80012010 <proc>
    80002416:	b7f1                	j	800023e2 <lottery_scheduler+0x64>
    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    80002418:	8552                	mv	a0,s4
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	ea0080e7          	jalr	-352(ra) # 800022ba <random_at_most>
    80002422:	8baa                	mv	s7,a0
    int ticket_counter = 0;                             // Track ticket count while iterating over processes
    80002424:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002426:	00010497          	auipc	s1,0x10
    8000242a:	bea48493          	add	s1,s1,-1046 # 80012010 <proc>
    8000242e:	a811                	j	80002442 <lottery_scheduler+0xc4>
      release(&p->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	854080e7          	jalr	-1964(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000243a:	23048493          	add	s1,s1,560
    8000243e:	fd2481e3          	beq	s1,s2,80002400 <lottery_scheduler+0x82>
      if (p == 0)
    80002442:	dce5                	beqz	s1,8000243a <lottery_scheduler+0xbc>
      acquire(&p->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	78c080e7          	jalr	1932(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000244e:	4c9c                	lw	a5,24(s1)
    80002450:	ff3790e3          	bne	a5,s3,80002430 <lottery_scheduler+0xb2>
        ticket_counter += p->tickets; // Increment the ticket counter
    80002454:	2104a783          	lw	a5,528(s1)
    80002458:	01478a3b          	addw	s4,a5,s4
        if (ticket_counter >= winning_ticket)
    8000245c:	fd7a4ae3          	blt	s4,s7,80002430 <lottery_scheduler+0xb2>
            release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	824080e7          	jalr	-2012(ra) # 80000c86 <release>
      acquire(&winner->lock);
    8000246a:	8a26                	mv	s4,s1
    8000246c:	8526                	mv	a0,s1
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	764080e7          	jalr	1892(ra) # 80000bd2 <acquire>
      if (winner->state == RUNNABLE)
    80002476:	4c9c                	lw	a5,24(s1)
    80002478:	01378863          	beq	a5,s3,80002488 <lottery_scheduler+0x10a>
      release(&winner->lock);
    8000247c:	8552                	mv	a0,s4
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	808080e7          	jalr	-2040(ra) # 80000c86 <release>
    80002486:	bfad                	j	80002400 <lottery_scheduler+0x82>
        winner->state = RUNNING;
    80002488:	4791                	li	a5,4
    8000248a:	cc9c                	sw	a5,24(s1)
        c->proc = winner;
    8000248c:	069b3823          	sd	s1,112(s6)
        swtch(&c->context, &winner->context);
    80002490:	06048593          	add	a1,s1,96
    80002494:	8562                	mv	a0,s8
    80002496:	00001097          	auipc	ra,0x1
    8000249a:	a16080e7          	jalr	-1514(ra) # 80002eac <swtch>
        c->proc = 0;
    8000249e:	060b3823          	sd	zero,112(s6)
    800024a2:	bfe9                	j	8000247c <lottery_scheduler+0xfe>

00000000800024a4 <get_ticks_for_priority>:
{
    800024a4:	1141                	add	sp,sp,-16
    800024a6:	e422                	sd	s0,8(sp)
    800024a8:	0800                	add	s0,sp,16
  switch (priority)
    800024aa:	4709                	li	a4,2
    800024ac:	00e50f63          	beq	a0,a4,800024ca <get_ticks_for_priority+0x26>
    800024b0:	87aa                	mv	a5,a0
    800024b2:	470d                	li	a4,3
    return TICKS_3; // 16 ticks for priority 3
    800024b4:	4541                	li	a0,16
  switch (priority)
    800024b6:	00e78763          	beq	a5,a4,800024c4 <get_ticks_for_priority+0x20>
    800024ba:	4705                	li	a4,1
    800024bc:	4511                	li	a0,4
    800024be:	00e78363          	beq	a5,a4,800024c4 <get_ticks_for_priority+0x20>
    return TICKS_0; // 1 tick for priority 0
    800024c2:	4505                	li	a0,1
}
    800024c4:	6422                	ld	s0,8(sp)
    800024c6:	0141                	add	sp,sp,16
    800024c8:	8082                	ret
    return TICKS_2; // 8 ticks for priority 2
    800024ca:	4521                	li	a0,8
    800024cc:	bfe5                	j	800024c4 <get_ticks_for_priority+0x20>

00000000800024ce <boost_all_processes>:
{
    800024ce:	7179                	add	sp,sp,-48
    800024d0:	f406                	sd	ra,40(sp)
    800024d2:	f022                	sd	s0,32(sp)
    800024d4:	ec26                	sd	s1,24(sp)
    800024d6:	e84a                	sd	s2,16(sp)
    800024d8:	e44e                	sd	s3,8(sp)
    800024da:	1800                	add	s0,sp,48
  for (int i = 0; i < NPROC; i++)
    800024dc:	00010497          	auipc	s1,0x10
    800024e0:	b3448493          	add	s1,s1,-1228 # 80012010 <proc>
    800024e4:	00018917          	auipc	s2,0x18
    800024e8:	72c90913          	add	s2,s2,1836 # 8001ac10 <tickslock>
      p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    800024ec:	4985                	li	s3,1
    800024ee:	a029                	j	800024f8 <boost_all_processes+0x2a>
  for (int i = 0; i < NPROC; i++)
    800024f0:	23048493          	add	s1,s1,560
    800024f4:	01248f63          	beq	s1,s2,80002512 <boost_all_processes+0x44>
    if (p->state != UNUSED)
    800024f8:	4c9c                	lw	a5,24(s1)
    800024fa:	dbfd                	beqz	a5,800024f0 <boost_all_processes+0x22>
      p->priority = 0;              // Move all processes to priority 0
    800024fc:	2204a023          	sw	zero,544(s1)
      p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    80002500:	2334a223          	sw	s3,548(s1)
      enqueue(0, p);                // Enqueue into priority 0
    80002504:	85a6                	mv	a1,s1
    80002506:	4501                	li	a0,0
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	35c080e7          	jalr	860(ra) # 80001864 <enqueue>
    80002510:	b7c5                	j	800024f0 <boost_all_processes+0x22>
}
    80002512:	70a2                	ld	ra,40(sp)
    80002514:	7402                	ld	s0,32(sp)
    80002516:	64e2                	ld	s1,24(sp)
    80002518:	6942                	ld	s2,16(sp)
    8000251a:	69a2                	ld	s3,8(sp)
    8000251c:	6145                	add	sp,sp,48
    8000251e:	8082                	ret

0000000080002520 <mlfq_scheduler>:
{
    80002520:	711d                	add	sp,sp,-96
    80002522:	ec86                	sd	ra,88(sp)
    80002524:	e8a2                	sd	s0,80(sp)
    80002526:	e4a6                	sd	s1,72(sp)
    80002528:	e0ca                	sd	s2,64(sp)
    8000252a:	fc4e                	sd	s3,56(sp)
    8000252c:	f852                	sd	s4,48(sp)
    8000252e:	f456                	sd	s5,40(sp)
    80002530:	f05a                	sd	s6,32(sp)
    80002532:	ec5e                	sd	s7,24(sp)
    80002534:	e862                	sd	s8,16(sp)
    80002536:	e466                	sd	s9,8(sp)
    80002538:	1080                	add	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000253a:	8792                	mv	a5,tp
  int id = r_tp();
    8000253c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000253e:	00779b93          	sll	s7,a5,0x7
    80002542:	0000e717          	auipc	a4,0xe
    80002546:	6be70713          	add	a4,a4,1726 # 80010c00 <mlfq_queues>
    8000254a:	975e                	add	a4,a4,s7
    8000254c:	06073823          	sd	zero,112(a4)
      swtch(&c->context, &selected_proc->context);
    80002550:	0000e717          	auipc	a4,0xe
    80002554:	72870713          	add	a4,a4,1832 # 80010c78 <cpus+0x8>
    80002558:	9bba                	add	s7,s7,a4
    if (boost_ticks >= BOOST_INTERVAL)
    8000255a:	00006997          	auipc	s3,0x6
    8000255e:	42e98993          	add	s3,s3,1070 # 80008988 <boost_ticks>
    80002562:	02f00a13          	li	s4,47
    80002566:	0000ea97          	auipc	s5,0xe
    8000256a:	6daa8a93          	add	s5,s5,1754 # 80010c40 <pid_lock>
        if (p->state == RUNNABLE) // Check if the process is runnable
    8000256e:	490d                	li	s2,3
      c->proc = selected_proc;
    80002570:	079e                	sll	a5,a5,0x7
    80002572:	0000eb17          	auipc	s6,0xe
    80002576:	68eb0b13          	add	s6,s6,1678 # 80010c00 <mlfq_queues>
    8000257a:	9b3e                	add	s6,s6,a5
    8000257c:	a861                	j	80002614 <mlfq_scheduler+0xf4>
      boost_all_processes(); // Boost all processes back to the highest priority queue
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	f50080e7          	jalr	-176(ra) # 800024ce <boost_all_processes>
      boost_ticks = 0;       // Reset boost tick counter
    80002586:	0009a023          	sw	zero,0(s3)
    8000258a:	a879                	j	80002628 <mlfq_scheduler+0x108>
      selected_proc->state = RUNNING; // Change state to RUNNING
    8000258c:	4791                	li	a5,4
    8000258e:	cc9c                	sw	a5,24(s1)
      c->proc = selected_proc;
    80002590:	069b3823          	sd	s1,112(s6)
      swtch(&c->context, &selected_proc->context);
    80002594:	06048593          	add	a1,s1,96
    80002598:	855e                	mv	a0,s7
    8000259a:	00001097          	auipc	ra,0x1
    8000259e:	912080e7          	jalr	-1774(ra) # 80002eac <swtch>
      c->proc = 0;
    800025a2:	060b3823          	sd	zero,112(s6)
      selected_proc->remaining_ticks--;
    800025a6:	2244a783          	lw	a5,548(s1)
    800025aa:	37fd                	addw	a5,a5,-1
    800025ac:	0007871b          	sext.w	a4,a5
    800025b0:	22f4a223          	sw	a5,548(s1)
      if (selected_proc->remaining_ticks <= 0)
    800025b4:	02e04a63          	bgtz	a4,800025e8 <mlfq_scheduler+0xc8>
        if (selected_proc->priority < total_queue - 1)
    800025b8:	2204a783          	lw	a5,544(s1)
    800025bc:	4709                	li	a4,2
    800025be:	00f74563          	blt	a4,a5,800025c8 <mlfq_scheduler+0xa8>
          selected_proc->priority++; // Move to a lower-priority queue
    800025c2:	2785                	addw	a5,a5,1
    800025c4:	22f4a023          	sw	a5,544(s1)
        selected_proc->remaining_ticks = get_ticks_for_priority(selected_proc->priority);
    800025c8:	2204ac83          	lw	s9,544(s1)
    800025cc:	8566                	mv	a0,s9
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	ed6080e7          	jalr	-298(ra) # 800024a4 <get_ticks_for_priority>
    800025d6:	22a4a223          	sw	a0,548(s1)
        enqueue(selected_proc->priority, selected_proc); // Requeue the process
    800025da:	85a6                	mv	a1,s1
    800025dc:	8566                	mv	a0,s9
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	286080e7          	jalr	646(ra) # 80001864 <enqueue>
    800025e6:	a015                	j	8000260a <mlfq_scheduler+0xea>
        enqueue(selected_proc->priority, selected_proc);
    800025e8:	85a6                	mv	a1,s1
    800025ea:	2204a503          	lw	a0,544(s1)
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	276080e7          	jalr	630(ra) # 80001864 <enqueue>
    800025f6:	a811                	j	8000260a <mlfq_scheduler+0xea>
    acquire(&selected_proc->lock); // Lock the selected process
    800025f8:	8c26                	mv	s8,s1
    800025fa:	8526                	mv	a0,s1
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	5d6080e7          	jalr	1494(ra) # 80000bd2 <acquire>
    if (selected_proc->state == RUNNABLE)
    80002604:	4c9c                	lw	a5,24(s1)
    80002606:	f92783e3          	beq	a5,s2,8000258c <mlfq_scheduler+0x6c>
    release(&selected_proc->lock); // Release the lock for the selected process
    8000260a:	8562                	mv	a0,s8
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	67a080e7          	jalr	1658(ra) # 80000c86 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002614:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002618:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000261c:	10079073          	csrw	sstatus,a5
    if (boost_ticks >= BOOST_INTERVAL)
    80002620:	0009a783          	lw	a5,0(s3)
    80002624:	f4fa4de3          	blt	s4,a5,8000257e <mlfq_scheduler+0x5e>
    for (int i = 0; i < total_queue; i++)
    80002628:	0000e717          	auipc	a4,0xe
    8000262c:	5d870713          	add	a4,a4,1496 # 80010c00 <mlfq_queues>
      for (p = mlfq_queues[i].head; p != 0; p = p->next)
    80002630:	6304                	ld	s1,0(a4)
    80002632:	c499                	beqz	s1,80002640 <mlfq_scheduler+0x120>
        if (p->state == RUNNABLE) // Check if the process is runnable
    80002634:	4c9c                	lw	a5,24(s1)
    80002636:	fd2781e3          	beq	a5,s2,800025f8 <mlfq_scheduler+0xd8>
      for (p = mlfq_queues[i].head; p != 0; p = p->next)
    8000263a:	2284b483          	ld	s1,552(s1)
    8000263e:	f8fd                	bnez	s1,80002634 <mlfq_scheduler+0x114>
    for (int i = 0; i < total_queue; i++)
    80002640:	0741                	add	a4,a4,16
    80002642:	ff5717e3          	bne	a4,s5,80002630 <mlfq_scheduler+0x110>
    80002646:	b7f9                	j	80002614 <mlfq_scheduler+0xf4>

0000000080002648 <scheduler>:
{
    80002648:	1141                	add	sp,sp,-16
    8000264a:	e406                	sd	ra,8(sp)
    8000264c:	e022                	sd	s0,0(sp)
    8000264e:	0800                	add	s0,sp,16
    printf("mlfq will run");
    80002650:	00006517          	auipc	a0,0x6
    80002654:	be050513          	add	a0,a0,-1056 # 80008230 <digits+0x1f0>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	f2e080e7          	jalr	-210(ra) # 80000586 <printf>
    mlfq_scheduler();
    80002660:	00000097          	auipc	ra,0x0
    80002664:	ec0080e7          	jalr	-320(ra) # 80002520 <mlfq_scheduler>

0000000080002668 <sched>:
{
    80002668:	7179                	add	sp,sp,-48
    8000266a:	f406                	sd	ra,40(sp)
    8000266c:	f022                	sd	s0,32(sp)
    8000266e:	ec26                	sd	s1,24(sp)
    80002670:	e84a                	sd	s2,16(sp)
    80002672:	e44e                	sd	s3,8(sp)
    80002674:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	418080e7          	jalr	1048(ra) # 80001a8e <myproc>
    8000267e:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	4d8080e7          	jalr	1240(ra) # 80000b58 <holding>
    80002688:	c93d                	beqz	a0,800026fe <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000268a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000268c:	2781                	sext.w	a5,a5
    8000268e:	079e                	sll	a5,a5,0x7
    80002690:	0000e717          	auipc	a4,0xe
    80002694:	57070713          	add	a4,a4,1392 # 80010c00 <mlfq_queues>
    80002698:	97ba                	add	a5,a5,a4
    8000269a:	0e87a703          	lw	a4,232(a5)
    8000269e:	4785                	li	a5,1
    800026a0:	06f71763          	bne	a4,a5,8000270e <sched+0xa6>
  if (p->state == RUNNING)
    800026a4:	4c98                	lw	a4,24(s1)
    800026a6:	4791                	li	a5,4
    800026a8:	06f70b63          	beq	a4,a5,8000271e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026b0:	8b89                	and	a5,a5,2
  if (intr_get())
    800026b2:	efb5                	bnez	a5,8000272e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800026b6:	0000e917          	auipc	s2,0xe
    800026ba:	54a90913          	add	s2,s2,1354 # 80010c00 <mlfq_queues>
    800026be:	2781                	sext.w	a5,a5
    800026c0:	079e                	sll	a5,a5,0x7
    800026c2:	97ca                	add	a5,a5,s2
    800026c4:	0ec7a983          	lw	s3,236(a5)
    800026c8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800026ca:	2781                	sext.w	a5,a5
    800026cc:	079e                	sll	a5,a5,0x7
    800026ce:	0000e597          	auipc	a1,0xe
    800026d2:	5aa58593          	add	a1,a1,1450 # 80010c78 <cpus+0x8>
    800026d6:	95be                	add	a1,a1,a5
    800026d8:	06048513          	add	a0,s1,96
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	7d0080e7          	jalr	2000(ra) # 80002eac <swtch>
    800026e4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800026e6:	2781                	sext.w	a5,a5
    800026e8:	079e                	sll	a5,a5,0x7
    800026ea:	993e                	add	s2,s2,a5
    800026ec:	0f392623          	sw	s3,236(s2)
}
    800026f0:	70a2                	ld	ra,40(sp)
    800026f2:	7402                	ld	s0,32(sp)
    800026f4:	64e2                	ld	s1,24(sp)
    800026f6:	6942                	ld	s2,16(sp)
    800026f8:	69a2                	ld	s3,8(sp)
    800026fa:	6145                	add	sp,sp,48
    800026fc:	8082                	ret
    panic("sched p->lock");
    800026fe:	00006517          	auipc	a0,0x6
    80002702:	b4250513          	add	a0,a0,-1214 # 80008240 <digits+0x200>
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e36080e7          	jalr	-458(ra) # 8000053c <panic>
    panic("sched locks");
    8000270e:	00006517          	auipc	a0,0x6
    80002712:	b4250513          	add	a0,a0,-1214 # 80008250 <digits+0x210>
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	e26080e7          	jalr	-474(ra) # 8000053c <panic>
    panic("sched running");
    8000271e:	00006517          	auipc	a0,0x6
    80002722:	b4250513          	add	a0,a0,-1214 # 80008260 <digits+0x220>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	e16080e7          	jalr	-490(ra) # 8000053c <panic>
    panic("sched interruptible");
    8000272e:	00006517          	auipc	a0,0x6
    80002732:	b4250513          	add	a0,a0,-1214 # 80008270 <digits+0x230>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e06080e7          	jalr	-506(ra) # 8000053c <panic>

000000008000273e <yield>:
{
    8000273e:	1101                	add	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	346080e7          	jalr	838(ra) # 80001a8e <myproc>
    80002750:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	480080e7          	jalr	1152(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000275a:	478d                	li	a5,3
    8000275c:	cc9c                	sw	a5,24(s1)
  sched();
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	f0a080e7          	jalr	-246(ra) # 80002668 <sched>
  release(&p->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	51e080e7          	jalr	1310(ra) # 80000c86 <release>
}
    80002770:	60e2                	ld	ra,24(sp)
    80002772:	6442                	ld	s0,16(sp)
    80002774:	64a2                	ld	s1,8(sp)
    80002776:	6105                	add	sp,sp,32
    80002778:	8082                	ret

000000008000277a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000277a:	7179                	add	sp,sp,-48
    8000277c:	f406                	sd	ra,40(sp)
    8000277e:	f022                	sd	s0,32(sp)
    80002780:	ec26                	sd	s1,24(sp)
    80002782:	e84a                	sd	s2,16(sp)
    80002784:	e44e                	sd	s3,8(sp)
    80002786:	1800                	add	s0,sp,48
    80002788:	89aa                	mv	s3,a0
    8000278a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	302080e7          	jalr	770(ra) # 80001a8e <myproc>
    80002794:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	43c080e7          	jalr	1084(ra) # 80000bd2 <acquire>
  release(lk);
    8000279e:	854a                	mv	a0,s2
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4e6080e7          	jalr	1254(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800027a8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800027ac:	4789                	li	a5,2
    800027ae:	cc9c                	sw	a5,24(s1)

  sched();
    800027b0:	00000097          	auipc	ra,0x0
    800027b4:	eb8080e7          	jalr	-328(ra) # 80002668 <sched>

  // Tidy up.
  p->chan = 0;
    800027b8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4c8080e7          	jalr	1224(ra) # 80000c86 <release>
  acquire(lk);
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	40a080e7          	jalr	1034(ra) # 80000bd2 <acquire>
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6145                	add	sp,sp,48
    800027dc:	8082                	ret

00000000800027de <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800027de:	7139                	add	sp,sp,-64
    800027e0:	fc06                	sd	ra,56(sp)
    800027e2:	f822                	sd	s0,48(sp)
    800027e4:	f426                	sd	s1,40(sp)
    800027e6:	f04a                	sd	s2,32(sp)
    800027e8:	ec4e                	sd	s3,24(sp)
    800027ea:	e852                	sd	s4,16(sp)
    800027ec:	e456                	sd	s5,8(sp)
    800027ee:	0080                	add	s0,sp,64
    800027f0:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027f2:	00010497          	auipc	s1,0x10
    800027f6:	81e48493          	add	s1,s1,-2018 # 80012010 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800027fa:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800027fc:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800027fe:	00018917          	auipc	s2,0x18
    80002802:	41290913          	add	s2,s2,1042 # 8001ac10 <tickslock>
    80002806:	a811                	j	8000281a <wakeup+0x3c>
      }
      release(&p->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	47c080e7          	jalr	1148(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002812:	23048493          	add	s1,s1,560
    80002816:	03248663          	beq	s1,s2,80002842 <wakeup+0x64>
    if (p != myproc())
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	274080e7          	jalr	628(ra) # 80001a8e <myproc>
    80002822:	fea488e3          	beq	s1,a0,80002812 <wakeup+0x34>
      acquire(&p->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	3aa080e7          	jalr	938(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002830:	4c9c                	lw	a5,24(s1)
    80002832:	fd379be3          	bne	a5,s3,80002808 <wakeup+0x2a>
    80002836:	709c                	ld	a5,32(s1)
    80002838:	fd4798e3          	bne	a5,s4,80002808 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000283c:	0154ac23          	sw	s5,24(s1)
    80002840:	b7e1                	j	80002808 <wakeup+0x2a>
    }
  }
}
    80002842:	70e2                	ld	ra,56(sp)
    80002844:	7442                	ld	s0,48(sp)
    80002846:	74a2                	ld	s1,40(sp)
    80002848:	7902                	ld	s2,32(sp)
    8000284a:	69e2                	ld	s3,24(sp)
    8000284c:	6a42                	ld	s4,16(sp)
    8000284e:	6aa2                	ld	s5,8(sp)
    80002850:	6121                	add	sp,sp,64
    80002852:	8082                	ret

0000000080002854 <reparent>:
{
    80002854:	7179                	add	sp,sp,-48
    80002856:	f406                	sd	ra,40(sp)
    80002858:	f022                	sd	s0,32(sp)
    8000285a:	ec26                	sd	s1,24(sp)
    8000285c:	e84a                	sd	s2,16(sp)
    8000285e:	e44e                	sd	s3,8(sp)
    80002860:	e052                	sd	s4,0(sp)
    80002862:	1800                	add	s0,sp,48
    80002864:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002866:	0000f497          	auipc	s1,0xf
    8000286a:	7aa48493          	add	s1,s1,1962 # 80012010 <proc>
      pp->parent = initproc;
    8000286e:	00006a17          	auipc	s4,0x6
    80002872:	122a0a13          	add	s4,s4,290 # 80008990 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002876:	00018997          	auipc	s3,0x18
    8000287a:	39a98993          	add	s3,s3,922 # 8001ac10 <tickslock>
    8000287e:	a029                	j	80002888 <reparent+0x34>
    80002880:	23048493          	add	s1,s1,560
    80002884:	01348d63          	beq	s1,s3,8000289e <reparent+0x4a>
    if (pp->parent == p)
    80002888:	7c9c                	ld	a5,56(s1)
    8000288a:	ff279be3          	bne	a5,s2,80002880 <reparent+0x2c>
      pp->parent = initproc;
    8000288e:	000a3503          	ld	a0,0(s4)
    80002892:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002894:	00000097          	auipc	ra,0x0
    80002898:	f4a080e7          	jalr	-182(ra) # 800027de <wakeup>
    8000289c:	b7d5                	j	80002880 <reparent+0x2c>
}
    8000289e:	70a2                	ld	ra,40(sp)
    800028a0:	7402                	ld	s0,32(sp)
    800028a2:	64e2                	ld	s1,24(sp)
    800028a4:	6942                	ld	s2,16(sp)
    800028a6:	69a2                	ld	s3,8(sp)
    800028a8:	6a02                	ld	s4,0(sp)
    800028aa:	6145                	add	sp,sp,48
    800028ac:	8082                	ret

00000000800028ae <exit>:
{
    800028ae:	7179                	add	sp,sp,-48
    800028b0:	f406                	sd	ra,40(sp)
    800028b2:	f022                	sd	s0,32(sp)
    800028b4:	ec26                	sd	s1,24(sp)
    800028b6:	e84a                	sd	s2,16(sp)
    800028b8:	e44e                	sd	s3,8(sp)
    800028ba:	e052                	sd	s4,0(sp)
    800028bc:	1800                	add	s0,sp,48
    800028be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800028c0:	fffff097          	auipc	ra,0xfffff
    800028c4:	1ce080e7          	jalr	462(ra) # 80001a8e <myproc>
    800028c8:	89aa                	mv	s3,a0
  if (p == initproc)
    800028ca:	00006797          	auipc	a5,0x6
    800028ce:	0c67b783          	ld	a5,198(a5) # 80008990 <initproc>
    800028d2:	0d050493          	add	s1,a0,208
    800028d6:	15050913          	add	s2,a0,336
    800028da:	02a79363          	bne	a5,a0,80002900 <exit+0x52>
    panic("init exiting");
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	9aa50513          	add	a0,a0,-1622 # 80008288 <digits+0x248>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	c56080e7          	jalr	-938(ra) # 8000053c <panic>
      fileclose(f);
    800028ee:	00002097          	auipc	ra,0x2
    800028f2:	6e6080e7          	jalr	1766(ra) # 80004fd4 <fileclose>
      p->ofile[fd] = 0;
    800028f6:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800028fa:	04a1                	add	s1,s1,8
    800028fc:	01248563          	beq	s1,s2,80002906 <exit+0x58>
    if (p->ofile[fd])
    80002900:	6088                	ld	a0,0(s1)
    80002902:	f575                	bnez	a0,800028ee <exit+0x40>
    80002904:	bfdd                	j	800028fa <exit+0x4c>
  begin_op();
    80002906:	00002097          	auipc	ra,0x2
    8000290a:	20a080e7          	jalr	522(ra) # 80004b10 <begin_op>
  iput(p->cwd);
    8000290e:	1509b503          	ld	a0,336(s3)
    80002912:	00002097          	auipc	ra,0x2
    80002916:	a12080e7          	jalr	-1518(ra) # 80004324 <iput>
  end_op();
    8000291a:	00002097          	auipc	ra,0x2
    8000291e:	270080e7          	jalr	624(ra) # 80004b8a <end_op>
  p->cwd = 0;
    80002922:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002926:	0000e497          	auipc	s1,0xe
    8000292a:	33248493          	add	s1,s1,818 # 80010c58 <wait_lock>
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	2a2080e7          	jalr	674(ra) # 80000bd2 <acquire>
  reparent(p);
    80002938:	854e                	mv	a0,s3
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	f1a080e7          	jalr	-230(ra) # 80002854 <reparent>
  wakeup(p->parent);
    80002942:	0389b503          	ld	a0,56(s3)
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	e98080e7          	jalr	-360(ra) # 800027de <wakeup>
  acquire(&p->lock);
    8000294e:	854e                	mv	a0,s3
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	282080e7          	jalr	642(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002958:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000295c:	4795                	li	a5,5
    8000295e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002962:	00006797          	auipc	a5,0x6
    80002966:	0367a783          	lw	a5,54(a5) # 80008998 <ticks>
    8000296a:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000296e:	8526                	mv	a0,s1
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	316080e7          	jalr	790(ra) # 80000c86 <release>
  sched();
    80002978:	00000097          	auipc	ra,0x0
    8000297c:	cf0080e7          	jalr	-784(ra) # 80002668 <sched>
  panic("zombie exit");
    80002980:	00006517          	auipc	a0,0x6
    80002984:	91850513          	add	a0,a0,-1768 # 80008298 <digits+0x258>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	bb4080e7          	jalr	-1100(ra) # 8000053c <panic>

0000000080002990 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002990:	7179                	add	sp,sp,-48
    80002992:	f406                	sd	ra,40(sp)
    80002994:	f022                	sd	s0,32(sp)
    80002996:	ec26                	sd	s1,24(sp)
    80002998:	e84a                	sd	s2,16(sp)
    8000299a:	e44e                	sd	s3,8(sp)
    8000299c:	1800                	add	s0,sp,48
    8000299e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800029a0:	0000f497          	auipc	s1,0xf
    800029a4:	67048493          	add	s1,s1,1648 # 80012010 <proc>
    800029a8:	00018997          	auipc	s3,0x18
    800029ac:	26898993          	add	s3,s3,616 # 8001ac10 <tickslock>
  {
    acquire(&p->lock);
    800029b0:	8526                	mv	a0,s1
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	220080e7          	jalr	544(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    800029ba:	589c                	lw	a5,48(s1)
    800029bc:	01278d63          	beq	a5,s2,800029d6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800029c0:	8526                	mv	a0,s1
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	2c4080e7          	jalr	708(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029ca:	23048493          	add	s1,s1,560
    800029ce:	ff3491e3          	bne	s1,s3,800029b0 <kill+0x20>
  }
  return -1;
    800029d2:	557d                	li	a0,-1
    800029d4:	a829                	j	800029ee <kill+0x5e>
      p->killed = 1;
    800029d6:	4785                	li	a5,1
    800029d8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800029da:	4c98                	lw	a4,24(s1)
    800029dc:	4789                	li	a5,2
    800029de:	00f70f63          	beq	a4,a5,800029fc <kill+0x6c>
      release(&p->lock);
    800029e2:	8526                	mv	a0,s1
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2a2080e7          	jalr	674(ra) # 80000c86 <release>
      return 0;
    800029ec:	4501                	li	a0,0
}
    800029ee:	70a2                	ld	ra,40(sp)
    800029f0:	7402                	ld	s0,32(sp)
    800029f2:	64e2                	ld	s1,24(sp)
    800029f4:	6942                	ld	s2,16(sp)
    800029f6:	69a2                	ld	s3,8(sp)
    800029f8:	6145                	add	sp,sp,48
    800029fa:	8082                	ret
        p->state = RUNNABLE;
    800029fc:	478d                	li	a5,3
    800029fe:	cc9c                	sw	a5,24(s1)
    80002a00:	b7cd                	j	800029e2 <kill+0x52>

0000000080002a02 <setkilled>:

void setkilled(struct proc *p)
{
    80002a02:	1101                	add	sp,sp,-32
    80002a04:	ec06                	sd	ra,24(sp)
    80002a06:	e822                	sd	s0,16(sp)
    80002a08:	e426                	sd	s1,8(sp)
    80002a0a:	1000                	add	s0,sp,32
    80002a0c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	1c4080e7          	jalr	452(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002a16:	4785                	li	a5,1
    80002a18:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	26a080e7          	jalr	618(ra) # 80000c86 <release>
}
    80002a24:	60e2                	ld	ra,24(sp)
    80002a26:	6442                	ld	s0,16(sp)
    80002a28:	64a2                	ld	s1,8(sp)
    80002a2a:	6105                	add	sp,sp,32
    80002a2c:	8082                	ret

0000000080002a2e <killed>:

int killed(struct proc *p)
{
    80002a2e:	1101                	add	sp,sp,-32
    80002a30:	ec06                	sd	ra,24(sp)
    80002a32:	e822                	sd	s0,16(sp)
    80002a34:	e426                	sd	s1,8(sp)
    80002a36:	e04a                	sd	s2,0(sp)
    80002a38:	1000                	add	s0,sp,32
    80002a3a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	196080e7          	jalr	406(ra) # 80000bd2 <acquire>
  k = p->killed;
    80002a44:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	23c080e7          	jalr	572(ra) # 80000c86 <release>
  return k;
}
    80002a52:	854a                	mv	a0,s2
    80002a54:	60e2                	ld	ra,24(sp)
    80002a56:	6442                	ld	s0,16(sp)
    80002a58:	64a2                	ld	s1,8(sp)
    80002a5a:	6902                	ld	s2,0(sp)
    80002a5c:	6105                	add	sp,sp,32
    80002a5e:	8082                	ret

0000000080002a60 <wait>:
{
    80002a60:	715d                	add	sp,sp,-80
    80002a62:	e486                	sd	ra,72(sp)
    80002a64:	e0a2                	sd	s0,64(sp)
    80002a66:	fc26                	sd	s1,56(sp)
    80002a68:	f84a                	sd	s2,48(sp)
    80002a6a:	f44e                	sd	s3,40(sp)
    80002a6c:	f052                	sd	s4,32(sp)
    80002a6e:	ec56                	sd	s5,24(sp)
    80002a70:	e85a                	sd	s6,16(sp)
    80002a72:	e45e                	sd	s7,8(sp)
    80002a74:	e062                	sd	s8,0(sp)
    80002a76:	0880                	add	s0,sp,80
    80002a78:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	014080e7          	jalr	20(ra) # 80001a8e <myproc>
    80002a82:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002a84:	0000e517          	auipc	a0,0xe
    80002a88:	1d450513          	add	a0,a0,468 # 80010c58 <wait_lock>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	146080e7          	jalr	326(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002a94:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002a96:	4a95                	li	s5,5
        havekids = 1;
    80002a98:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a9a:	00018997          	auipc	s3,0x18
    80002a9e:	17698993          	add	s3,s3,374 # 8001ac10 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002aa2:	0000ec17          	auipc	s8,0xe
    80002aa6:	1b6c0c13          	add	s8,s8,438 # 80010c58 <wait_lock>
    80002aaa:	a8f1                	j	80002b86 <wait+0x126>
    80002aac:	17448793          	add	a5,s1,372
    80002ab0:	17490713          	add	a4,s2,372
    80002ab4:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    80002ab8:	4394                	lw	a3,0(a5)
    80002aba:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    80002abc:	0791                	add	a5,a5,4
    80002abe:	0711                	add	a4,a4,4
    80002ac0:	fec79ce3          	bne	a5,a2,80002ab8 <wait+0x58>
          pid = pp->pid;
    80002ac4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002ac8:	000a0e63          	beqz	s4,80002ae4 <wait+0x84>
    80002acc:	4691                	li	a3,4
    80002ace:	02c48613          	add	a2,s1,44
    80002ad2:	85d2                	mv	a1,s4
    80002ad4:	05093503          	ld	a0,80(s2)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	b8e080e7          	jalr	-1138(ra) # 80001666 <copyout>
    80002ae0:	04054163          	bltz	a0,80002b22 <wait+0xc2>
          freeproc(pp);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	15a080e7          	jalr	346(ra) # 80001c40 <freeproc>
          release(&pp->lock);
    80002aee:	8526                	mv	a0,s1
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	196080e7          	jalr	406(ra) # 80000c86 <release>
          release(&wait_lock);
    80002af8:	0000e517          	auipc	a0,0xe
    80002afc:	16050513          	add	a0,a0,352 # 80010c58 <wait_lock>
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	186080e7          	jalr	390(ra) # 80000c86 <release>
}
    80002b08:	854e                	mv	a0,s3
    80002b0a:	60a6                	ld	ra,72(sp)
    80002b0c:	6406                	ld	s0,64(sp)
    80002b0e:	74e2                	ld	s1,56(sp)
    80002b10:	7942                	ld	s2,48(sp)
    80002b12:	79a2                	ld	s3,40(sp)
    80002b14:	7a02                	ld	s4,32(sp)
    80002b16:	6ae2                	ld	s5,24(sp)
    80002b18:	6b42                	ld	s6,16(sp)
    80002b1a:	6ba2                	ld	s7,8(sp)
    80002b1c:	6c02                	ld	s8,0(sp)
    80002b1e:	6161                	add	sp,sp,80
    80002b20:	8082                	ret
            release(&pp->lock);
    80002b22:	8526                	mv	a0,s1
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	162080e7          	jalr	354(ra) # 80000c86 <release>
            release(&wait_lock);
    80002b2c:	0000e517          	auipc	a0,0xe
    80002b30:	12c50513          	add	a0,a0,300 # 80010c58 <wait_lock>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	152080e7          	jalr	338(ra) # 80000c86 <release>
            return -1;
    80002b3c:	59fd                	li	s3,-1
    80002b3e:	b7e9                	j	80002b08 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b40:	23048493          	add	s1,s1,560
    80002b44:	03348463          	beq	s1,s3,80002b6c <wait+0x10c>
      if (pp->parent == p)
    80002b48:	7c9c                	ld	a5,56(s1)
    80002b4a:	ff279be3          	bne	a5,s2,80002b40 <wait+0xe0>
        acquire(&pp->lock);
    80002b4e:	8526                	mv	a0,s1
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	082080e7          	jalr	130(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002b58:	4c9c                	lw	a5,24(s1)
    80002b5a:	f55789e3          	beq	a5,s5,80002aac <wait+0x4c>
        release(&pp->lock);
    80002b5e:	8526                	mv	a0,s1
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	126080e7          	jalr	294(ra) # 80000c86 <release>
        havekids = 1;
    80002b68:	875a                	mv	a4,s6
    80002b6a:	bfd9                	j	80002b40 <wait+0xe0>
    if (!havekids || killed(p))
    80002b6c:	c31d                	beqz	a4,80002b92 <wait+0x132>
    80002b6e:	854a                	mv	a0,s2
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	ebe080e7          	jalr	-322(ra) # 80002a2e <killed>
    80002b78:	ed09                	bnez	a0,80002b92 <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b7a:	85e2                	mv	a1,s8
    80002b7c:	854a                	mv	a0,s2
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	bfc080e7          	jalr	-1028(ra) # 8000277a <sleep>
    havekids = 0;
    80002b86:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b88:	0000f497          	auipc	s1,0xf
    80002b8c:	48848493          	add	s1,s1,1160 # 80012010 <proc>
    80002b90:	bf65                	j	80002b48 <wait+0xe8>
      release(&wait_lock);
    80002b92:	0000e517          	auipc	a0,0xe
    80002b96:	0c650513          	add	a0,a0,198 # 80010c58 <wait_lock>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	0ec080e7          	jalr	236(ra) # 80000c86 <release>
      return -1;
    80002ba2:	59fd                	li	s3,-1
    80002ba4:	b795                	j	80002b08 <wait+0xa8>

0000000080002ba6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002ba6:	7179                	add	sp,sp,-48
    80002ba8:	f406                	sd	ra,40(sp)
    80002baa:	f022                	sd	s0,32(sp)
    80002bac:	ec26                	sd	s1,24(sp)
    80002bae:	e84a                	sd	s2,16(sp)
    80002bb0:	e44e                	sd	s3,8(sp)
    80002bb2:	e052                	sd	s4,0(sp)
    80002bb4:	1800                	add	s0,sp,48
    80002bb6:	84aa                	mv	s1,a0
    80002bb8:	892e                	mv	s2,a1
    80002bba:	89b2                	mv	s3,a2
    80002bbc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	ed0080e7          	jalr	-304(ra) # 80001a8e <myproc>
  if (user_dst)
    80002bc6:	c08d                	beqz	s1,80002be8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002bc8:	86d2                	mv	a3,s4
    80002bca:	864e                	mv	a2,s3
    80002bcc:	85ca                	mv	a1,s2
    80002bce:	6928                	ld	a0,80(a0)
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	a96080e7          	jalr	-1386(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002bd8:	70a2                	ld	ra,40(sp)
    80002bda:	7402                	ld	s0,32(sp)
    80002bdc:	64e2                	ld	s1,24(sp)
    80002bde:	6942                	ld	s2,16(sp)
    80002be0:	69a2                	ld	s3,8(sp)
    80002be2:	6a02                	ld	s4,0(sp)
    80002be4:	6145                	add	sp,sp,48
    80002be6:	8082                	ret
    memmove((char *)dst, src, len);
    80002be8:	000a061b          	sext.w	a2,s4
    80002bec:	85ce                	mv	a1,s3
    80002bee:	854a                	mv	a0,s2
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	13a080e7          	jalr	314(ra) # 80000d2a <memmove>
    return 0;
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	bff9                	j	80002bd8 <either_copyout+0x32>

0000000080002bfc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002bfc:	7179                	add	sp,sp,-48
    80002bfe:	f406                	sd	ra,40(sp)
    80002c00:	f022                	sd	s0,32(sp)
    80002c02:	ec26                	sd	s1,24(sp)
    80002c04:	e84a                	sd	s2,16(sp)
    80002c06:	e44e                	sd	s3,8(sp)
    80002c08:	e052                	sd	s4,0(sp)
    80002c0a:	1800                	add	s0,sp,48
    80002c0c:	892a                	mv	s2,a0
    80002c0e:	84ae                	mv	s1,a1
    80002c10:	89b2                	mv	s3,a2
    80002c12:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	e7a080e7          	jalr	-390(ra) # 80001a8e <myproc>
  if (user_src)
    80002c1c:	c08d                	beqz	s1,80002c3e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002c1e:	86d2                	mv	a3,s4
    80002c20:	864e                	mv	a2,s3
    80002c22:	85ca                	mv	a1,s2
    80002c24:	6928                	ld	a0,80(a0)
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	acc080e7          	jalr	-1332(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002c2e:	70a2                	ld	ra,40(sp)
    80002c30:	7402                	ld	s0,32(sp)
    80002c32:	64e2                	ld	s1,24(sp)
    80002c34:	6942                	ld	s2,16(sp)
    80002c36:	69a2                	ld	s3,8(sp)
    80002c38:	6a02                	ld	s4,0(sp)
    80002c3a:	6145                	add	sp,sp,48
    80002c3c:	8082                	ret
    memmove(dst, (char *)src, len);
    80002c3e:	000a061b          	sext.w	a2,s4
    80002c42:	85ce                	mv	a1,s3
    80002c44:	854a                	mv	a0,s2
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	0e4080e7          	jalr	228(ra) # 80000d2a <memmove>
    return 0;
    80002c4e:	8526                	mv	a0,s1
    80002c50:	bff9                	j	80002c2e <either_copyin+0x32>

0000000080002c52 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002c52:	715d                	add	sp,sp,-80
    80002c54:	e486                	sd	ra,72(sp)
    80002c56:	e0a2                	sd	s0,64(sp)
    80002c58:	fc26                	sd	s1,56(sp)
    80002c5a:	f84a                	sd	s2,48(sp)
    80002c5c:	f44e                	sd	s3,40(sp)
    80002c5e:	f052                	sd	s4,32(sp)
    80002c60:	ec56                	sd	s5,24(sp)
    80002c62:	e85a                	sd	s6,16(sp)
    80002c64:	e45e                	sd	s7,8(sp)
    80002c66:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	46050513          	add	a0,a0,1120 # 800080c8 <digits+0x88>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	916080e7          	jalr	-1770(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002c78:	0000f497          	auipc	s1,0xf
    80002c7c:	4f048493          	add	s1,s1,1264 # 80012168 <proc+0x158>
    80002c80:	00018917          	auipc	s2,0x18
    80002c84:	0e890913          	add	s2,s2,232 # 8001ad68 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c88:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c8a:	00005997          	auipc	s3,0x5
    80002c8e:	61e98993          	add	s3,s3,1566 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002c92:	00005a97          	auipc	s5,0x5
    80002c96:	61ea8a93          	add	s5,s5,1566 # 800082b0 <digits+0x270>
    printf("\n");
    80002c9a:	00005a17          	auipc	s4,0x5
    80002c9e:	42ea0a13          	add	s4,s4,1070 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ca2:	00005b97          	auipc	s7,0x5
    80002ca6:	64eb8b93          	add	s7,s7,1614 # 800082f0 <states.0>
    80002caa:	a00d                	j	80002ccc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002cac:	ed86a583          	lw	a1,-296(a3)
    80002cb0:	8556                	mv	a0,s5
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8d4080e7          	jalr	-1836(ra) # 80000586 <printf>
    printf("\n");
    80002cba:	8552                	mv	a0,s4
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8ca080e7          	jalr	-1846(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002cc4:	23048493          	add	s1,s1,560
    80002cc8:	03248263          	beq	s1,s2,80002cec <procdump+0x9a>
    if (p->state == UNUSED)
    80002ccc:	86a6                	mv	a3,s1
    80002cce:	ec04a783          	lw	a5,-320(s1)
    80002cd2:	dbed                	beqz	a5,80002cc4 <procdump+0x72>
      state = "???";
    80002cd4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cd6:	fcfb6be3          	bltu	s6,a5,80002cac <procdump+0x5a>
    80002cda:	02079713          	sll	a4,a5,0x20
    80002cde:	01d75793          	srl	a5,a4,0x1d
    80002ce2:	97de                	add	a5,a5,s7
    80002ce4:	6390                	ld	a2,0(a5)
    80002ce6:	f279                	bnez	a2,80002cac <procdump+0x5a>
      state = "???";
    80002ce8:	864e                	mv	a2,s3
    80002cea:	b7c9                	j	80002cac <procdump+0x5a>
  }
}
    80002cec:	60a6                	ld	ra,72(sp)
    80002cee:	6406                	ld	s0,64(sp)
    80002cf0:	74e2                	ld	s1,56(sp)
    80002cf2:	7942                	ld	s2,48(sp)
    80002cf4:	79a2                	ld	s3,40(sp)
    80002cf6:	7a02                	ld	s4,32(sp)
    80002cf8:	6ae2                	ld	s5,24(sp)
    80002cfa:	6b42                	ld	s6,16(sp)
    80002cfc:	6ba2                	ld	s7,8(sp)
    80002cfe:	6161                	add	sp,sp,80
    80002d00:	8082                	ret

0000000080002d02 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002d02:	711d                	add	sp,sp,-96
    80002d04:	ec86                	sd	ra,88(sp)
    80002d06:	e8a2                	sd	s0,80(sp)
    80002d08:	e4a6                	sd	s1,72(sp)
    80002d0a:	e0ca                	sd	s2,64(sp)
    80002d0c:	fc4e                	sd	s3,56(sp)
    80002d0e:	f852                	sd	s4,48(sp)
    80002d10:	f456                	sd	s5,40(sp)
    80002d12:	f05a                	sd	s6,32(sp)
    80002d14:	ec5e                	sd	s7,24(sp)
    80002d16:	e862                	sd	s8,16(sp)
    80002d18:	e466                	sd	s9,8(sp)
    80002d1a:	e06a                	sd	s10,0(sp)
    80002d1c:	1080                	add	s0,sp,96
    80002d1e:	8b2a                	mv	s6,a0
    80002d20:	8bae                	mv	s7,a1
    80002d22:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	d6a080e7          	jalr	-662(ra) # 80001a8e <myproc>
    80002d2c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002d2e:	0000e517          	auipc	a0,0xe
    80002d32:	f2a50513          	add	a0,a0,-214 # 80010c58 <wait_lock>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	e9c080e7          	jalr	-356(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002d3e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002d40:	4a15                	li	s4,5
        havekids = 1;
    80002d42:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002d44:	00018997          	auipc	s3,0x18
    80002d48:	ecc98993          	add	s3,s3,-308 # 8001ac10 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d4c:	0000ed17          	auipc	s10,0xe
    80002d50:	f0cd0d13          	add	s10,s10,-244 # 80010c58 <wait_lock>
    80002d54:	a8e9                	j	80002e2e <waitx+0x12c>
          pid = np->pid;
    80002d56:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002d5a:	1684a783          	lw	a5,360(s1)
    80002d5e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002d62:	16c4a703          	lw	a4,364(s1)
    80002d66:	9f3d                	addw	a4,a4,a5
    80002d68:	1704a783          	lw	a5,368(s1)
    80002d6c:	9f99                	subw	a5,a5,a4
    80002d6e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d72:	000b0e63          	beqz	s6,80002d8e <waitx+0x8c>
    80002d76:	4691                	li	a3,4
    80002d78:	02c48613          	add	a2,s1,44
    80002d7c:	85da                	mv	a1,s6
    80002d7e:	05093503          	ld	a0,80(s2)
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	8e4080e7          	jalr	-1820(ra) # 80001666 <copyout>
    80002d8a:	04054363          	bltz	a0,80002dd0 <waitx+0xce>
          freeproc(np);
    80002d8e:	8526                	mv	a0,s1
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	eb0080e7          	jalr	-336(ra) # 80001c40 <freeproc>
          release(&np->lock);
    80002d98:	8526                	mv	a0,s1
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	eec080e7          	jalr	-276(ra) # 80000c86 <release>
          release(&wait_lock);
    80002da2:	0000e517          	auipc	a0,0xe
    80002da6:	eb650513          	add	a0,a0,-330 # 80010c58 <wait_lock>
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	edc080e7          	jalr	-292(ra) # 80000c86 <release>
  }
}
    80002db2:	854e                	mv	a0,s3
    80002db4:	60e6                	ld	ra,88(sp)
    80002db6:	6446                	ld	s0,80(sp)
    80002db8:	64a6                	ld	s1,72(sp)
    80002dba:	6906                	ld	s2,64(sp)
    80002dbc:	79e2                	ld	s3,56(sp)
    80002dbe:	7a42                	ld	s4,48(sp)
    80002dc0:	7aa2                	ld	s5,40(sp)
    80002dc2:	7b02                	ld	s6,32(sp)
    80002dc4:	6be2                	ld	s7,24(sp)
    80002dc6:	6c42                	ld	s8,16(sp)
    80002dc8:	6ca2                	ld	s9,8(sp)
    80002dca:	6d02                	ld	s10,0(sp)
    80002dcc:	6125                	add	sp,sp,96
    80002dce:	8082                	ret
            release(&np->lock);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	eb4080e7          	jalr	-332(ra) # 80000c86 <release>
            release(&wait_lock);
    80002dda:	0000e517          	auipc	a0,0xe
    80002dde:	e7e50513          	add	a0,a0,-386 # 80010c58 <wait_lock>
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	ea4080e7          	jalr	-348(ra) # 80000c86 <release>
            return -1;
    80002dea:	59fd                	li	s3,-1
    80002dec:	b7d9                	j	80002db2 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002dee:	23048493          	add	s1,s1,560
    80002df2:	03348463          	beq	s1,s3,80002e1a <waitx+0x118>
      if (np->parent == p)
    80002df6:	7c9c                	ld	a5,56(s1)
    80002df8:	ff279be3          	bne	a5,s2,80002dee <waitx+0xec>
        acquire(&np->lock);
    80002dfc:	8526                	mv	a0,s1
    80002dfe:	ffffe097          	auipc	ra,0xffffe
    80002e02:	dd4080e7          	jalr	-556(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002e06:	4c9c                	lw	a5,24(s1)
    80002e08:	f54787e3          	beq	a5,s4,80002d56 <waitx+0x54>
        release(&np->lock);
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e78080e7          	jalr	-392(ra) # 80000c86 <release>
        havekids = 1;
    80002e16:	8756                	mv	a4,s5
    80002e18:	bfd9                	j	80002dee <waitx+0xec>
    if (!havekids || p->killed)
    80002e1a:	c305                	beqz	a4,80002e3a <waitx+0x138>
    80002e1c:	02892783          	lw	a5,40(s2)
    80002e20:	ef89                	bnez	a5,80002e3a <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002e22:	85ea                	mv	a1,s10
    80002e24:	854a                	mv	a0,s2
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	954080e7          	jalr	-1708(ra) # 8000277a <sleep>
    havekids = 0;
    80002e2e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002e30:	0000f497          	auipc	s1,0xf
    80002e34:	1e048493          	add	s1,s1,480 # 80012010 <proc>
    80002e38:	bf7d                	j	80002df6 <waitx+0xf4>
      release(&wait_lock);
    80002e3a:	0000e517          	auipc	a0,0xe
    80002e3e:	e1e50513          	add	a0,a0,-482 # 80010c58 <wait_lock>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e44080e7          	jalr	-444(ra) # 80000c86 <release>
      return -1;
    80002e4a:	59fd                	li	s3,-1
    80002e4c:	b79d                	j	80002db2 <waitx+0xb0>

0000000080002e4e <update_time>:

void update_time()
{
    80002e4e:	7179                	add	sp,sp,-48
    80002e50:	f406                	sd	ra,40(sp)
    80002e52:	f022                	sd	s0,32(sp)
    80002e54:	ec26                	sd	s1,24(sp)
    80002e56:	e84a                	sd	s2,16(sp)
    80002e58:	e44e                	sd	s3,8(sp)
    80002e5a:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002e5c:	0000f497          	auipc	s1,0xf
    80002e60:	1b448493          	add	s1,s1,436 # 80012010 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002e64:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002e66:	00018917          	auipc	s2,0x18
    80002e6a:	daa90913          	add	s2,s2,-598 # 8001ac10 <tickslock>
    80002e6e:	a811                	j	80002e82 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002e70:	8526                	mv	a0,s1
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	e14080e7          	jalr	-492(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002e7a:	23048493          	add	s1,s1,560
    80002e7e:	03248063          	beq	s1,s2,80002e9e <update_time+0x50>
    acquire(&p->lock);
    80002e82:	8526                	mv	a0,s1
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	d4e080e7          	jalr	-690(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002e8c:	4c9c                	lw	a5,24(s1)
    80002e8e:	ff3791e3          	bne	a5,s3,80002e70 <update_time+0x22>
      p->rtime++;
    80002e92:	1684a783          	lw	a5,360(s1)
    80002e96:	2785                	addw	a5,a5,1
    80002e98:	16f4a423          	sw	a5,360(s1)
    80002e9c:	bfd1                	j	80002e70 <update_time+0x22>
  }
    80002e9e:	70a2                	ld	ra,40(sp)
    80002ea0:	7402                	ld	s0,32(sp)
    80002ea2:	64e2                	ld	s1,24(sp)
    80002ea4:	6942                	ld	s2,16(sp)
    80002ea6:	69a2                	ld	s3,8(sp)
    80002ea8:	6145                	add	sp,sp,48
    80002eaa:	8082                	ret

0000000080002eac <swtch>:
    80002eac:	00153023          	sd	ra,0(a0)
    80002eb0:	00253423          	sd	sp,8(a0)
    80002eb4:	e900                	sd	s0,16(a0)
    80002eb6:	ed04                	sd	s1,24(a0)
    80002eb8:	03253023          	sd	s2,32(a0)
    80002ebc:	03353423          	sd	s3,40(a0)
    80002ec0:	03453823          	sd	s4,48(a0)
    80002ec4:	03553c23          	sd	s5,56(a0)
    80002ec8:	05653023          	sd	s6,64(a0)
    80002ecc:	05753423          	sd	s7,72(a0)
    80002ed0:	05853823          	sd	s8,80(a0)
    80002ed4:	05953c23          	sd	s9,88(a0)
    80002ed8:	07a53023          	sd	s10,96(a0)
    80002edc:	07b53423          	sd	s11,104(a0)
    80002ee0:	0005b083          	ld	ra,0(a1)
    80002ee4:	0085b103          	ld	sp,8(a1)
    80002ee8:	6980                	ld	s0,16(a1)
    80002eea:	6d84                	ld	s1,24(a1)
    80002eec:	0205b903          	ld	s2,32(a1)
    80002ef0:	0285b983          	ld	s3,40(a1)
    80002ef4:	0305ba03          	ld	s4,48(a1)
    80002ef8:	0385ba83          	ld	s5,56(a1)
    80002efc:	0405bb03          	ld	s6,64(a1)
    80002f00:	0485bb83          	ld	s7,72(a1)
    80002f04:	0505bc03          	ld	s8,80(a1)
    80002f08:	0585bc83          	ld	s9,88(a1)
    80002f0c:	0605bd03          	ld	s10,96(a1)
    80002f10:	0685bd83          	ld	s11,104(a1)
    80002f14:	8082                	ret

0000000080002f16 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002f16:	1141                	add	sp,sp,-16
    80002f18:	e406                	sd	ra,8(sp)
    80002f1a:	e022                	sd	s0,0(sp)
    80002f1c:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002f1e:	00005597          	auipc	a1,0x5
    80002f22:	40258593          	add	a1,a1,1026 # 80008320 <states.0+0x30>
    80002f26:	00018517          	auipc	a0,0x18
    80002f2a:	cea50513          	add	a0,a0,-790 # 8001ac10 <tickslock>
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	c14080e7          	jalr	-1004(ra) # 80000b42 <initlock>
}
    80002f36:	60a2                	ld	ra,8(sp)
    80002f38:	6402                	ld	s0,0(sp)
    80002f3a:	0141                	add	sp,sp,16
    80002f3c:	8082                	ret

0000000080002f3e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002f3e:	1141                	add	sp,sp,-16
    80002f40:	e422                	sd	s0,8(sp)
    80002f42:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f44:	00003797          	auipc	a5,0x3
    80002f48:	6bc78793          	add	a5,a5,1724 # 80006600 <kernelvec>
    80002f4c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f50:	6422                	ld	s0,8(sp)
    80002f52:	0141                	add	sp,sp,16
    80002f54:	8082                	ret

0000000080002f56 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002f56:	1141                	add	sp,sp,-16
    80002f58:	e406                	sd	ra,8(sp)
    80002f5a:	e022                	sd	s0,0(sp)
    80002f5c:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	b30080e7          	jalr	-1232(ra) # 80001a8e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f6a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f6c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002f70:	00004697          	auipc	a3,0x4
    80002f74:	09068693          	add	a3,a3,144 # 80007000 <_trampoline>
    80002f78:	00004717          	auipc	a4,0x4
    80002f7c:	08870713          	add	a4,a4,136 # 80007000 <_trampoline>
    80002f80:	8f15                	sub	a4,a4,a3
    80002f82:	040007b7          	lui	a5,0x4000
    80002f86:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002f88:	07b2                	sll	a5,a5,0xc
    80002f8a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f8c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f90:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f92:	18002673          	csrr	a2,satp
    80002f96:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f98:	6d30                	ld	a2,88(a0)
    80002f9a:	6138                	ld	a4,64(a0)
    80002f9c:	6585                	lui	a1,0x1
    80002f9e:	972e                	add	a4,a4,a1
    80002fa0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fa2:	6d38                	ld	a4,88(a0)
    80002fa4:	00000617          	auipc	a2,0x0
    80002fa8:	14260613          	add	a2,a2,322 # 800030e6 <usertrap>
    80002fac:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002fae:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fb0:	8612                	mv	a2,tp
    80002fb2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fb4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002fb8:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002fbc:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002fc4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fc6:	6f18                	ld	a4,24(a4)
    80002fc8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002fcc:	6928                	ld	a0,80(a0)
    80002fce:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002fd0:	00004717          	auipc	a4,0x4
    80002fd4:	0cc70713          	add	a4,a4,204 # 8000709c <userret>
    80002fd8:	8f15                	sub	a4,a4,a3
    80002fda:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002fdc:	577d                	li	a4,-1
    80002fde:	177e                	sll	a4,a4,0x3f
    80002fe0:	8d59                	or	a0,a0,a4
    80002fe2:	9782                	jalr	a5
}
    80002fe4:	60a2                	ld	ra,8(sp)
    80002fe6:	6402                	ld	s0,0(sp)
    80002fe8:	0141                	add	sp,sp,16
    80002fea:	8082                	ret

0000000080002fec <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002fec:	1101                	add	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	e04a                	sd	s2,0(sp)
    80002ff6:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002ff8:	00018917          	auipc	s2,0x18
    80002ffc:	c1890913          	add	s2,s2,-1000 # 8001ac10 <tickslock>
    80003000:	854a                	mv	a0,s2
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	bd0080e7          	jalr	-1072(ra) # 80000bd2 <acquire>
  ticks++;
    8000300a:	00006497          	auipc	s1,0x6
    8000300e:	98e48493          	add	s1,s1,-1650 # 80008998 <ticks>
    80003012:	409c                	lw	a5,0(s1)
    80003014:	2785                	addw	a5,a5,1
    80003016:	c09c                	sw	a5,0(s1)
  update_time();
    80003018:	00000097          	auipc	ra,0x0
    8000301c:	e36080e7          	jalr	-458(ra) # 80002e4e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80003020:	8526                	mv	a0,s1
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	7bc080e7          	jalr	1980(ra) # 800027de <wakeup>
  release(&tickslock);
    8000302a:	854a                	mv	a0,s2
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c5a080e7          	jalr	-934(ra) # 80000c86 <release>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6902                	ld	s2,0(sp)
    8000303c:	6105                	add	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003040:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80003044:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80003046:	0807df63          	bgez	a5,800030e4 <devintr+0xa4>
{
    8000304a:	1101                	add	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	e426                	sd	s1,8(sp)
    80003052:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80003054:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80003058:	46a5                	li	a3,9
    8000305a:	00d70d63          	beq	a4,a3,80003074 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    8000305e:	577d                	li	a4,-1
    80003060:	177e                	sll	a4,a4,0x3f
    80003062:	0705                	add	a4,a4,1
    return 0;
    80003064:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80003066:	04e78e63          	beq	a5,a4,800030c2 <devintr+0x82>
  }
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	add	sp,sp,32
    80003072:	8082                	ret
    int irq = plic_claim();
    80003074:	00003097          	auipc	ra,0x3
    80003078:	694080e7          	jalr	1684(ra) # 80006708 <plic_claim>
    8000307c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000307e:	47a9                	li	a5,10
    80003080:	02f50763          	beq	a0,a5,800030ae <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80003084:	4785                	li	a5,1
    80003086:	02f50963          	beq	a0,a5,800030b8 <devintr+0x78>
    return 1;
    8000308a:	4505                	li	a0,1
    else if (irq)
    8000308c:	dcf9                	beqz	s1,8000306a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    8000308e:	85a6                	mv	a1,s1
    80003090:	00005517          	auipc	a0,0x5
    80003094:	29850513          	add	a0,a0,664 # 80008328 <states.0+0x38>
    80003098:	ffffd097          	auipc	ra,0xffffd
    8000309c:	4ee080e7          	jalr	1262(ra) # 80000586 <printf>
      plic_complete(irq);
    800030a0:	8526                	mv	a0,s1
    800030a2:	00003097          	auipc	ra,0x3
    800030a6:	68a080e7          	jalr	1674(ra) # 8000672c <plic_complete>
    return 1;
    800030aa:	4505                	li	a0,1
    800030ac:	bf7d                	j	8000306a <devintr+0x2a>
      uartintr();
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	8e6080e7          	jalr	-1818(ra) # 80000994 <uartintr>
    if (irq)
    800030b6:	b7ed                	j	800030a0 <devintr+0x60>
      virtio_disk_intr();
    800030b8:	00004097          	auipc	ra,0x4
    800030bc:	b3a080e7          	jalr	-1222(ra) # 80006bf2 <virtio_disk_intr>
    if (irq)
    800030c0:	b7c5                	j	800030a0 <devintr+0x60>
    if (cpuid() == 0)
    800030c2:	fffff097          	auipc	ra,0xfffff
    800030c6:	9a0080e7          	jalr	-1632(ra) # 80001a62 <cpuid>
    800030ca:	c901                	beqz	a0,800030da <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030cc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030d0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030d2:	14479073          	csrw	sip,a5
    return 2;
    800030d6:	4509                	li	a0,2
    800030d8:	bf49                	j	8000306a <devintr+0x2a>
      clockintr();
    800030da:	00000097          	auipc	ra,0x0
    800030de:	f12080e7          	jalr	-238(ra) # 80002fec <clockintr>
    800030e2:	b7ed                	j	800030cc <devintr+0x8c>
}
    800030e4:	8082                	ret

00000000800030e6 <usertrap>:
{
    800030e6:	1101                	add	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030f0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800030f4:	1007f793          	and	a5,a5,256
    800030f8:	e7b1                	bnez	a5,80003144 <usertrap+0x5e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030fa:	00003797          	auipc	a5,0x3
    800030fe:	50678793          	add	a5,a5,1286 # 80006600 <kernelvec>
    80003102:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	988080e7          	jalr	-1656(ra) # 80001a8e <myproc>
    8000310e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003110:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003112:	14102773          	csrr	a4,sepc
    80003116:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003118:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    8000311c:	47a1                	li	a5,8
    8000311e:	02f70b63          	beq	a4,a5,80003154 <usertrap+0x6e>
  else if ((which_dev = devintr()) != 0)
    80003122:	00000097          	auipc	ra,0x0
    80003126:	f1e080e7          	jalr	-226(ra) # 80003040 <devintr>
    8000312a:	cd61                	beqz	a0,80003202 <usertrap+0x11c>
    if (which_dev == 2)
    8000312c:	4789                	li	a5,2
    8000312e:	04f51663          	bne	a0,a5,8000317a <usertrap+0x94>
      if (p != 0 && p->state == RUNNING)
    80003132:	4c98                	lw	a4,24(s1)
    80003134:	4791                	li	a5,4
    80003136:	06f70763          	beq	a4,a5,800031a4 <usertrap+0xbe>
    yield();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	604080e7          	jalr	1540(ra) # 8000273e <yield>
    80003142:	a825                	j	8000317a <usertrap+0x94>
    panic("usertrap: not from user mode");
    80003144:	00005517          	auipc	a0,0x5
    80003148:	20450513          	add	a0,a0,516 # 80008348 <states.0+0x58>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	3f0080e7          	jalr	1008(ra) # 8000053c <panic>
    if (killed(p))
    80003154:	00000097          	auipc	ra,0x0
    80003158:	8da080e7          	jalr	-1830(ra) # 80002a2e <killed>
    8000315c:	ed15                	bnez	a0,80003198 <usertrap+0xb2>
    p->trapframe->epc += 4;
    8000315e:	6cb8                	ld	a4,88(s1)
    80003160:	6f1c                	ld	a5,24(a4)
    80003162:	0791                	add	a5,a5,4
    80003164:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003166:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000316a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000316e:	10079073          	csrw	sstatus,a5
    syscall();
    80003172:	00000097          	auipc	ra,0x0
    80003176:	320080e7          	jalr	800(ra) # 80003492 <syscall>
  if (killed(p))
    8000317a:	8526                	mv	a0,s1
    8000317c:	00000097          	auipc	ra,0x0
    80003180:	8b2080e7          	jalr	-1870(ra) # 80002a2e <killed>
    80003184:	ed45                	bnez	a0,8000323c <usertrap+0x156>
  usertrapret();
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	dd0080e7          	jalr	-560(ra) # 80002f56 <usertrapret>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	add	sp,sp,32
    80003196:	8082                	ret
      exit(-1);
    80003198:	557d                	li	a0,-1
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	714080e7          	jalr	1812(ra) # 800028ae <exit>
    800031a2:	bf75                	j	8000315e <usertrap+0x78>
        p->ticks_count++;
    800031a4:	2004a783          	lw	a5,512(s1)
    800031a8:	2785                	addw	a5,a5,1
    800031aa:	0007871b          	sext.w	a4,a5
    800031ae:	20f4a023          	sw	a5,512(s1)
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    800031b2:	1f04a783          	lw	a5,496(s1)
    800031b6:	f8f052e3          	blez	a5,8000313a <usertrap+0x54>
    800031ba:	f8f740e3          	blt	a4,a5,8000313a <usertrap+0x54>
    800031be:	2044a783          	lw	a5,516(s1)
    800031c2:	dfa5                	beqz	a5,8000313a <usertrap+0x54>
          p->alarm_on = 0; // Disable alarm while handler is running
    800031c4:	2004a223          	sw	zero,516(s1)
          p->alarm_tf = kalloc();
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	91a080e7          	jalr	-1766(ra) # 80000ae2 <kalloc>
    800031d0:	20a4b423          	sd	a0,520(s1)
          if (p->alarm_tf == 0)
    800031d4:	cd19                	beqz	a0,800031f2 <usertrap+0x10c>
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    800031d6:	12000613          	li	a2,288
    800031da:	6cac                	ld	a1,88(s1)
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	b4e080e7          	jalr	-1202(ra) # 80000d2a <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    800031e4:	6cbc                	ld	a5,88(s1)
    800031e6:	1f84b703          	ld	a4,504(s1)
    800031ea:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    800031ec:	2004a023          	sw	zero,512(s1)
    800031f0:	b7a9                	j	8000313a <usertrap+0x54>
            panic("Error !! usertrap: out of memory");
    800031f2:	00005517          	auipc	a0,0x5
    800031f6:	17650513          	add	a0,a0,374 # 80008368 <states.0+0x78>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	342080e7          	jalr	834(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003202:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003206:	5890                	lw	a2,48(s1)
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	18850513          	add	a0,a0,392 # 80008390 <states.0+0xa0>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	376080e7          	jalr	886(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003218:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000321c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003220:	00005517          	auipc	a0,0x5
    80003224:	1a050513          	add	a0,a0,416 # 800083c0 <states.0+0xd0>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	35e080e7          	jalr	862(ra) # 80000586 <printf>
    setkilled(p);
    80003230:	8526                	mv	a0,s1
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	7d0080e7          	jalr	2000(ra) # 80002a02 <setkilled>
  if (which_dev == 2)
    8000323a:	b781                	j	8000317a <usertrap+0x94>
    exit(-1);
    8000323c:	557d                	li	a0,-1
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	670080e7          	jalr	1648(ra) # 800028ae <exit>
    80003246:	b781                	j	80003186 <usertrap+0xa0>

0000000080003248 <kerneltrap>:
{
    80003248:	7179                	add	sp,sp,-48
    8000324a:	f406                	sd	ra,40(sp)
    8000324c:	f022                	sd	s0,32(sp)
    8000324e:	ec26                	sd	s1,24(sp)
    80003250:	e84a                	sd	s2,16(sp)
    80003252:	e44e                	sd	s3,8(sp)
    80003254:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003256:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000325a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000325e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80003262:	1004f793          	and	a5,s1,256
    80003266:	cb85                	beqz	a5,80003296 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003268:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000326c:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    8000326e:	ef85                	bnez	a5,800032a6 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80003270:	00000097          	auipc	ra,0x0
    80003274:	dd0080e7          	jalr	-560(ra) # 80003040 <devintr>
    80003278:	cd1d                	beqz	a0,800032b6 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000327a:	4789                	li	a5,2
    8000327c:	06f50a63          	beq	a0,a5,800032f0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003280:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003284:	10049073          	csrw	sstatus,s1
}
    80003288:	70a2                	ld	ra,40(sp)
    8000328a:	7402                	ld	s0,32(sp)
    8000328c:	64e2                	ld	s1,24(sp)
    8000328e:	6942                	ld	s2,16(sp)
    80003290:	69a2                	ld	s3,8(sp)
    80003292:	6145                	add	sp,sp,48
    80003294:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003296:	00005517          	auipc	a0,0x5
    8000329a:	14a50513          	add	a0,a0,330 # 800083e0 <states.0+0xf0>
    8000329e:	ffffd097          	auipc	ra,0xffffd
    800032a2:	29e080e7          	jalr	670(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800032a6:	00005517          	auipc	a0,0x5
    800032aa:	16250513          	add	a0,a0,354 # 80008408 <states.0+0x118>
    800032ae:	ffffd097          	auipc	ra,0xffffd
    800032b2:	28e080e7          	jalr	654(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800032b6:	85ce                	mv	a1,s3
    800032b8:	00005517          	auipc	a0,0x5
    800032bc:	17050513          	add	a0,a0,368 # 80008428 <states.0+0x138>
    800032c0:	ffffd097          	auipc	ra,0xffffd
    800032c4:	2c6080e7          	jalr	710(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032cc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032d0:	00005517          	auipc	a0,0x5
    800032d4:	16850513          	add	a0,a0,360 # 80008438 <states.0+0x148>
    800032d8:	ffffd097          	auipc	ra,0xffffd
    800032dc:	2ae080e7          	jalr	686(ra) # 80000586 <printf>
    panic("kerneltrap");
    800032e0:	00005517          	auipc	a0,0x5
    800032e4:	17050513          	add	a0,a0,368 # 80008450 <states.0+0x160>
    800032e8:	ffffd097          	auipc	ra,0xffffd
    800032ec:	254080e7          	jalr	596(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	79e080e7          	jalr	1950(ra) # 80001a8e <myproc>
    800032f8:	d541                	beqz	a0,80003280 <kerneltrap+0x38>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	794080e7          	jalr	1940(ra) # 80001a8e <myproc>
    80003302:	4d18                	lw	a4,24(a0)
    80003304:	4791                	li	a5,4
    80003306:	f6f71de3          	bne	a4,a5,80003280 <kerneltrap+0x38>
    yield();
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	434080e7          	jalr	1076(ra) # 8000273e <yield>
    80003312:	b7bd                	j	80003280 <kerneltrap+0x38>

0000000080003314 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003314:	1101                	add	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	1000                	add	s0,sp,32
    8000331e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	76e080e7          	jalr	1902(ra) # 80001a8e <myproc>
  switch (n)
    80003328:	4795                	li	a5,5
    8000332a:	0497e163          	bltu	a5,s1,8000336c <argraw+0x58>
    8000332e:	048a                	sll	s1,s1,0x2
    80003330:	00005717          	auipc	a4,0x5
    80003334:	15870713          	add	a4,a4,344 # 80008488 <states.0+0x198>
    80003338:	94ba                	add	s1,s1,a4
    8000333a:	409c                	lw	a5,0(s1)
    8000333c:	97ba                	add	a5,a5,a4
    8000333e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80003340:	6d3c                	ld	a5,88(a0)
    80003342:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003344:	60e2                	ld	ra,24(sp)
    80003346:	6442                	ld	s0,16(sp)
    80003348:	64a2                	ld	s1,8(sp)
    8000334a:	6105                	add	sp,sp,32
    8000334c:	8082                	ret
    return p->trapframe->a1;
    8000334e:	6d3c                	ld	a5,88(a0)
    80003350:	7fa8                	ld	a0,120(a5)
    80003352:	bfcd                	j	80003344 <argraw+0x30>
    return p->trapframe->a2;
    80003354:	6d3c                	ld	a5,88(a0)
    80003356:	63c8                	ld	a0,128(a5)
    80003358:	b7f5                	j	80003344 <argraw+0x30>
    return p->trapframe->a3;
    8000335a:	6d3c                	ld	a5,88(a0)
    8000335c:	67c8                	ld	a0,136(a5)
    8000335e:	b7dd                	j	80003344 <argraw+0x30>
    return p->trapframe->a4;
    80003360:	6d3c                	ld	a5,88(a0)
    80003362:	6bc8                	ld	a0,144(a5)
    80003364:	b7c5                	j	80003344 <argraw+0x30>
    return p->trapframe->a5;
    80003366:	6d3c                	ld	a5,88(a0)
    80003368:	6fc8                	ld	a0,152(a5)
    8000336a:	bfe9                	j	80003344 <argraw+0x30>
  panic("argraw");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	0f450513          	add	a0,a0,244 # 80008460 <states.0+0x170>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1c8080e7          	jalr	456(ra) # 8000053c <panic>

000000008000337c <fetchaddr>:
{
    8000337c:	1101                	add	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	e04a                	sd	s2,0(sp)
    80003386:	1000                	add	s0,sp,32
    80003388:	84aa                	mv	s1,a0
    8000338a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	702080e7          	jalr	1794(ra) # 80001a8e <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003394:	653c                	ld	a5,72(a0)
    80003396:	02f4f863          	bgeu	s1,a5,800033c6 <fetchaddr+0x4a>
    8000339a:	00848713          	add	a4,s1,8
    8000339e:	02e7e663          	bltu	a5,a4,800033ca <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033a2:	46a1                	li	a3,8
    800033a4:	8626                	mv	a2,s1
    800033a6:	85ca                	mv	a1,s2
    800033a8:	6928                	ld	a0,80(a0)
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	348080e7          	jalr	840(ra) # 800016f2 <copyin>
    800033b2:	00a03533          	snez	a0,a0
    800033b6:	40a00533          	neg	a0,a0
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	64a2                	ld	s1,8(sp)
    800033c0:	6902                	ld	s2,0(sp)
    800033c2:	6105                	add	sp,sp,32
    800033c4:	8082                	ret
    return -1;
    800033c6:	557d                	li	a0,-1
    800033c8:	bfcd                	j	800033ba <fetchaddr+0x3e>
    800033ca:	557d                	li	a0,-1
    800033cc:	b7fd                	j	800033ba <fetchaddr+0x3e>

00000000800033ce <fetchstr>:
{
    800033ce:	7179                	add	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	1800                	add	s0,sp,48
    800033dc:	892a                	mv	s2,a0
    800033de:	84ae                	mv	s1,a1
    800033e0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	6ac080e7          	jalr	1708(ra) # 80001a8e <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800033ea:	86ce                	mv	a3,s3
    800033ec:	864a                	mv	a2,s2
    800033ee:	85a6                	mv	a1,s1
    800033f0:	6928                	ld	a0,80(a0)
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	38e080e7          	jalr	910(ra) # 80001780 <copyinstr>
    800033fa:	00054e63          	bltz	a0,80003416 <fetchstr+0x48>
  return strlen(buf);
    800033fe:	8526                	mv	a0,s1
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	a48080e7          	jalr	-1464(ra) # 80000e48 <strlen>
}
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6145                	add	sp,sp,48
    80003414:	8082                	ret
    return -1;
    80003416:	557d                	li	a0,-1
    80003418:	bfc5                	j	80003408 <fetchstr+0x3a>

000000008000341a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000341a:	1101                	add	sp,sp,-32
    8000341c:	ec06                	sd	ra,24(sp)
    8000341e:	e822                	sd	s0,16(sp)
    80003420:	e426                	sd	s1,8(sp)
    80003422:	1000                	add	s0,sp,32
    80003424:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	eee080e7          	jalr	-274(ra) # 80003314 <argraw>
    8000342e:	c088                	sw	a0,0(s1)
}
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	64a2                	ld	s1,8(sp)
    80003436:	6105                	add	sp,sp,32
    80003438:	8082                	ret

000000008000343a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000343a:	1101                	add	sp,sp,-32
    8000343c:	ec06                	sd	ra,24(sp)
    8000343e:	e822                	sd	s0,16(sp)
    80003440:	e426                	sd	s1,8(sp)
    80003442:	1000                	add	s0,sp,32
    80003444:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	ece080e7          	jalr	-306(ra) # 80003314 <argraw>
    8000344e:	e088                	sd	a0,0(s1)
}
    80003450:	60e2                	ld	ra,24(sp)
    80003452:	6442                	ld	s0,16(sp)
    80003454:	64a2                	ld	s1,8(sp)
    80003456:	6105                	add	sp,sp,32
    80003458:	8082                	ret

000000008000345a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000345a:	7179                	add	sp,sp,-48
    8000345c:	f406                	sd	ra,40(sp)
    8000345e:	f022                	sd	s0,32(sp)
    80003460:	ec26                	sd	s1,24(sp)
    80003462:	e84a                	sd	s2,16(sp)
    80003464:	1800                	add	s0,sp,48
    80003466:	84ae                	mv	s1,a1
    80003468:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000346a:	fd840593          	add	a1,s0,-40
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	fcc080e7          	jalr	-52(ra) # 8000343a <argaddr>
  return fetchstr(addr, buf, max);
    80003476:	864a                	mv	a2,s2
    80003478:	85a6                	mv	a1,s1
    8000347a:	fd843503          	ld	a0,-40(s0)
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	f50080e7          	jalr	-176(ra) # 800033ce <fetchstr>
}
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	6145                	add	sp,sp,48
    80003490:	8082                	ret

0000000080003492 <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    80003492:	1101                	add	sp,sp,-32
    80003494:	ec06                	sd	ra,24(sp)
    80003496:	e822                	sd	s0,16(sp)
    80003498:	e426                	sd	s1,8(sp)
    8000349a:	e04a                	sd	s2,0(sp)
    8000349c:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000349e:	ffffe097          	auipc	ra,0xffffe
    800034a2:	5f0080e7          	jalr	1520(ra) # 80001a8e <myproc>
    800034a6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034a8:	05853903          	ld	s2,88(a0)
    800034ac:	0a893783          	ld	a5,168(s2)
    800034b0:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800034b4:	37fd                	addw	a5,a5,-1
    800034b6:	4765                	li	a4,25
    800034b8:	02f76763          	bltu	a4,a5,800034e6 <syscall+0x54>
    800034bc:	00369713          	sll	a4,a3,0x3
    800034c0:	00005797          	auipc	a5,0x5
    800034c4:	fe078793          	add	a5,a5,-32 # 800084a0 <syscalls>
    800034c8:	97ba                	add	a5,a5,a4
    800034ca:	6398                	ld	a4,0(a5)
    800034cc:	cf09                	beqz	a4,800034e6 <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    800034ce:	068a                	sll	a3,a3,0x2
    800034d0:	00d504b3          	add	s1,a0,a3
    800034d4:	1704a783          	lw	a5,368(s1)
    800034d8:	2785                	addw	a5,a5,1
    800034da:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    800034de:	9702                	jalr	a4
    800034e0:	06a93823          	sd	a0,112(s2)
    800034e4:	a839                	j	80003502 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800034e6:	15848613          	add	a2,s1,344
    800034ea:	588c                	lw	a1,48(s1)
    800034ec:	00005517          	auipc	a0,0x5
    800034f0:	f7c50513          	add	a0,a0,-132 # 80008468 <states.0+0x178>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	092080e7          	jalr	146(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800034fc:	6cbc                	ld	a5,88(s1)
    800034fe:	577d                	li	a4,-1
    80003500:	fbb8                	sd	a4,112(a5)
  }
}
    80003502:	60e2                	ld	ra,24(sp)
    80003504:	6442                	ld	s0,16(sp)
    80003506:	64a2                	ld	s1,8(sp)
    80003508:	6902                	ld	s2,0(sp)
    8000350a:	6105                	add	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    8000350e:	1101                	add	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003516:	fec40593          	add	a1,s0,-20
    8000351a:	4501                	li	a0,0
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	efe080e7          	jalr	-258(ra) # 8000341a <argint>
  exit(n);
    80003524:	fec42503          	lw	a0,-20(s0)
    80003528:	fffff097          	auipc	ra,0xfffff
    8000352c:	386080e7          	jalr	902(ra) # 800028ae <exit>
  return 0; // not reached
}
    80003530:	4501                	li	a0,0
    80003532:	60e2                	ld	ra,24(sp)
    80003534:	6442                	ld	s0,16(sp)
    80003536:	6105                	add	sp,sp,32
    80003538:	8082                	ret

000000008000353a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000353a:	1141                	add	sp,sp,-16
    8000353c:	e406                	sd	ra,8(sp)
    8000353e:	e022                	sd	s0,0(sp)
    80003540:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003542:	ffffe097          	auipc	ra,0xffffe
    80003546:	54c080e7          	jalr	1356(ra) # 80001a8e <myproc>
}
    8000354a:	5908                	lw	a0,48(a0)
    8000354c:	60a2                	ld	ra,8(sp)
    8000354e:	6402                	ld	s0,0(sp)
    80003550:	0141                	add	sp,sp,16
    80003552:	8082                	ret

0000000080003554 <sys_fork>:

uint64
sys_fork(void)
{
    80003554:	1141                	add	sp,sp,-16
    80003556:	e406                	sd	ra,8(sp)
    80003558:	e022                	sd	s0,0(sp)
    8000355a:	0800                	add	s0,sp,16
  return fork();
    8000355c:	fffff097          	auipc	ra,0xfffff
    80003560:	94c080e7          	jalr	-1716(ra) # 80001ea8 <fork>
}
    80003564:	60a2                	ld	ra,8(sp)
    80003566:	6402                	ld	s0,0(sp)
    80003568:	0141                	add	sp,sp,16
    8000356a:	8082                	ret

000000008000356c <sys_wait>:

uint64
sys_wait(void)
{
    8000356c:	1101                	add	sp,sp,-32
    8000356e:	ec06                	sd	ra,24(sp)
    80003570:	e822                	sd	s0,16(sp)
    80003572:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003574:	fe840593          	add	a1,s0,-24
    80003578:	4501                	li	a0,0
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	ec0080e7          	jalr	-320(ra) # 8000343a <argaddr>
  return wait(p);
    80003582:	fe843503          	ld	a0,-24(s0)
    80003586:	fffff097          	auipc	ra,0xfffff
    8000358a:	4da080e7          	jalr	1242(ra) # 80002a60 <wait>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	6105                	add	sp,sp,32
    80003594:	8082                	ret

0000000080003596 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003596:	7179                	add	sp,sp,-48
    80003598:	f406                	sd	ra,40(sp)
    8000359a:	f022                	sd	s0,32(sp)
    8000359c:	ec26                	sd	s1,24(sp)
    8000359e:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800035a0:	fdc40593          	add	a1,s0,-36
    800035a4:	4501                	li	a0,0
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e74080e7          	jalr	-396(ra) # 8000341a <argint>
  addr = myproc()->sz;
    800035ae:	ffffe097          	auipc	ra,0xffffe
    800035b2:	4e0080e7          	jalr	1248(ra) # 80001a8e <myproc>
    800035b6:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800035b8:	fdc42503          	lw	a0,-36(s0)
    800035bc:	fffff097          	auipc	ra,0xfffff
    800035c0:	890080e7          	jalr	-1904(ra) # 80001e4c <growproc>
    800035c4:	00054863          	bltz	a0,800035d4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800035c8:	8526                	mv	a0,s1
    800035ca:	70a2                	ld	ra,40(sp)
    800035cc:	7402                	ld	s0,32(sp)
    800035ce:	64e2                	ld	s1,24(sp)
    800035d0:	6145                	add	sp,sp,48
    800035d2:	8082                	ret
    return -1;
    800035d4:	54fd                	li	s1,-1
    800035d6:	bfcd                	j	800035c8 <sys_sbrk+0x32>

00000000800035d8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800035d8:	7139                	add	sp,sp,-64
    800035da:	fc06                	sd	ra,56(sp)
    800035dc:	f822                	sd	s0,48(sp)
    800035de:	f426                	sd	s1,40(sp)
    800035e0:	f04a                	sd	s2,32(sp)
    800035e2:	ec4e                	sd	s3,24(sp)
    800035e4:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800035e6:	fcc40593          	add	a1,s0,-52
    800035ea:	4501                	li	a0,0
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e2e080e7          	jalr	-466(ra) # 8000341a <argint>
  acquire(&tickslock);
    800035f4:	00017517          	auipc	a0,0x17
    800035f8:	61c50513          	add	a0,a0,1564 # 8001ac10 <tickslock>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	5d6080e7          	jalr	1494(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003604:	00005917          	auipc	s2,0x5
    80003608:	39492903          	lw	s2,916(s2) # 80008998 <ticks>
  while (ticks - ticks0 < n)
    8000360c:	fcc42783          	lw	a5,-52(s0)
    80003610:	cf9d                	beqz	a5,8000364e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003612:	00017997          	auipc	s3,0x17
    80003616:	5fe98993          	add	s3,s3,1534 # 8001ac10 <tickslock>
    8000361a:	00005497          	auipc	s1,0x5
    8000361e:	37e48493          	add	s1,s1,894 # 80008998 <ticks>
    if (killed(myproc()))
    80003622:	ffffe097          	auipc	ra,0xffffe
    80003626:	46c080e7          	jalr	1132(ra) # 80001a8e <myproc>
    8000362a:	fffff097          	auipc	ra,0xfffff
    8000362e:	404080e7          	jalr	1028(ra) # 80002a2e <killed>
    80003632:	ed15                	bnez	a0,8000366e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003634:	85ce                	mv	a1,s3
    80003636:	8526                	mv	a0,s1
    80003638:	fffff097          	auipc	ra,0xfffff
    8000363c:	142080e7          	jalr	322(ra) # 8000277a <sleep>
  while (ticks - ticks0 < n)
    80003640:	409c                	lw	a5,0(s1)
    80003642:	412787bb          	subw	a5,a5,s2
    80003646:	fcc42703          	lw	a4,-52(s0)
    8000364a:	fce7ece3          	bltu	a5,a4,80003622 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000364e:	00017517          	auipc	a0,0x17
    80003652:	5c250513          	add	a0,a0,1474 # 8001ac10 <tickslock>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	630080e7          	jalr	1584(ra) # 80000c86 <release>
  return 0;
    8000365e:	4501                	li	a0,0
}
    80003660:	70e2                	ld	ra,56(sp)
    80003662:	7442                	ld	s0,48(sp)
    80003664:	74a2                	ld	s1,40(sp)
    80003666:	7902                	ld	s2,32(sp)
    80003668:	69e2                	ld	s3,24(sp)
    8000366a:	6121                	add	sp,sp,64
    8000366c:	8082                	ret
      release(&tickslock);
    8000366e:	00017517          	auipc	a0,0x17
    80003672:	5a250513          	add	a0,a0,1442 # 8001ac10 <tickslock>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	610080e7          	jalr	1552(ra) # 80000c86 <release>
      return -1;
    8000367e:	557d                	li	a0,-1
    80003680:	b7c5                	j	80003660 <sys_sleep+0x88>

0000000080003682 <sys_kill>:

uint64
sys_kill(void)
{
    80003682:	1101                	add	sp,sp,-32
    80003684:	ec06                	sd	ra,24(sp)
    80003686:	e822                	sd	s0,16(sp)
    80003688:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    8000368a:	fec40593          	add	a1,s0,-20
    8000368e:	4501                	li	a0,0
    80003690:	00000097          	auipc	ra,0x0
    80003694:	d8a080e7          	jalr	-630(ra) # 8000341a <argint>
  return kill(pid);
    80003698:	fec42503          	lw	a0,-20(s0)
    8000369c:	fffff097          	auipc	ra,0xfffff
    800036a0:	2f4080e7          	jalr	756(ra) # 80002990 <kill>
}
    800036a4:	60e2                	ld	ra,24(sp)
    800036a6:	6442                	ld	s0,16(sp)
    800036a8:	6105                	add	sp,sp,32
    800036aa:	8082                	ret

00000000800036ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036ac:	1101                	add	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036b6:	00017517          	auipc	a0,0x17
    800036ba:	55a50513          	add	a0,a0,1370 # 8001ac10 <tickslock>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	514080e7          	jalr	1300(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800036c6:	00005497          	auipc	s1,0x5
    800036ca:	2d24a483          	lw	s1,722(s1) # 80008998 <ticks>
  release(&tickslock);
    800036ce:	00017517          	auipc	a0,0x17
    800036d2:	54250513          	add	a0,a0,1346 # 8001ac10 <tickslock>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	5b0080e7          	jalr	1456(ra) # 80000c86 <release>
  return xticks;
}
    800036de:	02049513          	sll	a0,s1,0x20
    800036e2:	9101                	srl	a0,a0,0x20
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6105                	add	sp,sp,32
    800036ec:	8082                	ret

00000000800036ee <sys_waitx>:

uint64
sys_waitx(void)
{
    800036ee:	7139                	add	sp,sp,-64
    800036f0:	fc06                	sd	ra,56(sp)
    800036f2:	f822                	sd	s0,48(sp)
    800036f4:	f426                	sd	s1,40(sp)
    800036f6:	f04a                	sd	s2,32(sp)
    800036f8:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800036fa:	fd840593          	add	a1,s0,-40
    800036fe:	4501                	li	a0,0
    80003700:	00000097          	auipc	ra,0x0
    80003704:	d3a080e7          	jalr	-710(ra) # 8000343a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003708:	fd040593          	add	a1,s0,-48
    8000370c:	4505                	li	a0,1
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	d2c080e7          	jalr	-724(ra) # 8000343a <argaddr>
  argaddr(2, &addr2);
    80003716:	fc840593          	add	a1,s0,-56
    8000371a:	4509                	li	a0,2
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	d1e080e7          	jalr	-738(ra) # 8000343a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003724:	fc040613          	add	a2,s0,-64
    80003728:	fc440593          	add	a1,s0,-60
    8000372c:	fd843503          	ld	a0,-40(s0)
    80003730:	fffff097          	auipc	ra,0xfffff
    80003734:	5d2080e7          	jalr	1490(ra) # 80002d02 <waitx>
    80003738:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000373a:	ffffe097          	auipc	ra,0xffffe
    8000373e:	354080e7          	jalr	852(ra) # 80001a8e <myproc>
    80003742:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003744:	4691                	li	a3,4
    80003746:	fc440613          	add	a2,s0,-60
    8000374a:	fd043583          	ld	a1,-48(s0)
    8000374e:	6928                	ld	a0,80(a0)
    80003750:	ffffe097          	auipc	ra,0xffffe
    80003754:	f16080e7          	jalr	-234(ra) # 80001666 <copyout>
    return -1;
    80003758:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000375a:	00054f63          	bltz	a0,80003778 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000375e:	4691                	li	a3,4
    80003760:	fc040613          	add	a2,s0,-64
    80003764:	fc843583          	ld	a1,-56(s0)
    80003768:	68a8                	ld	a0,80(s1)
    8000376a:	ffffe097          	auipc	ra,0xffffe
    8000376e:	efc080e7          	jalr	-260(ra) # 80001666 <copyout>
    80003772:	00054a63          	bltz	a0,80003786 <sys_waitx+0x98>
    return -1;
  return ret;
    80003776:	87ca                	mv	a5,s2
}
    80003778:	853e                	mv	a0,a5
    8000377a:	70e2                	ld	ra,56(sp)
    8000377c:	7442                	ld	s0,48(sp)
    8000377e:	74a2                	ld	s1,40(sp)
    80003780:	7902                	ld	s2,32(sp)
    80003782:	6121                	add	sp,sp,64
    80003784:	8082                	ret
    return -1;
    80003786:	57fd                	li	a5,-1
    80003788:	bfc5                	j	80003778 <sys_waitx+0x8a>

000000008000378a <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    8000378a:	7179                	add	sp,sp,-48
    8000378c:	f406                	sd	ra,40(sp)
    8000378e:	f022                	sd	s0,32(sp)
    80003790:	ec26                	sd	s1,24(sp)
    80003792:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    80003794:	ffffe097          	auipc	ra,0xffffe
    80003798:	2fa080e7          	jalr	762(ra) # 80001a8e <myproc>
    8000379c:	84aa                	mv	s1,a0
  // for (int i = 0; i < 31; i++)
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }

  argint(0, &mask);
    8000379e:	fdc40593          	add	a1,s0,-36
    800037a2:	4501                	li	a0,0
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	c76080e7          	jalr	-906(ra) # 8000341a <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    800037ac:	fdc42583          	lw	a1,-36(s0)
    800037b0:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    800037b4:	4781                	li	a5,0
  int count = 0;
    800037b6:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    800037b8:	467d                	li	a2,31
    800037ba:	a029                	j	800037c4 <sys_getSysCount+0x3a>
    800037bc:	2785                	addw	a5,a5,1
    800037be:	0691                	add	a3,a3,4
    800037c0:	00c78963          	beq	a5,a2,800037d2 <sys_getSysCount+0x48>
    if (mask & (1 << i))
    800037c4:	40f5d73b          	sraw	a4,a1,a5
    800037c8:	8b05                	and	a4,a4,1
    800037ca:	db6d                	beqz	a4,800037bc <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i - 1]; // Add up the syscall counts
    800037cc:	4298                	lw	a4,0(a3)
    800037ce:	9d39                	addw	a0,a0,a4
    800037d0:	b7f5                	j	800037bc <sys_getSysCount+0x32>
    }
  }

  return count;
}
    800037d2:	70a2                	ld	ra,40(sp)
    800037d4:	7402                	ld	s0,32(sp)
    800037d6:	64e2                	ld	s1,24(sp)
    800037d8:	6145                	add	sp,sp,48
    800037da:	8082                	ret

00000000800037dc <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    800037dc:	1101                	add	sp,sp,-32
    800037de:	ec06                	sd	ra,24(sp)
    800037e0:	e822                	sd	s0,16(sp)
    800037e2:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    800037e4:	fec40593          	add	a1,s0,-20
    800037e8:	4501                	li	a0,0
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	c30080e7          	jalr	-976(ra) # 8000341a <argint>

  argaddr(1, &handler);
    800037f2:	fe040593          	add	a1,s0,-32
    800037f6:	4505                	li	a0,1
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	c42080e7          	jalr	-958(ra) # 8000343a <argaddr>

  struct proc *p = myproc();
    80003800:	ffffe097          	auipc	ra,0xffffe
    80003804:	28e080e7          	jalr	654(ra) # 80001a8e <myproc>
  p->alarm_interval = interval;
    80003808:	fec42783          	lw	a5,-20(s0)
    8000380c:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void (*)())handler;
    80003810:	fe043703          	ld	a4,-32(s0)
    80003814:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    80003818:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    8000381c:	00f027b3          	sgtz	a5,a5
    80003820:	20f52223          	sw	a5,516(a0)

  return 0;
}
    80003824:	4501                	li	a0,0
    80003826:	60e2                	ld	ra,24(sp)
    80003828:	6442                	ld	s0,16(sp)
    8000382a:	6105                	add	sp,sp,32
    8000382c:	8082                	ret

000000008000382e <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    8000382e:	1101                	add	sp,sp,-32
    80003830:	ec06                	sd	ra,24(sp)
    80003832:	e822                	sd	s0,16(sp)
    80003834:	e426                	sd	s1,8(sp)
    80003836:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80003838:	ffffe097          	auipc	ra,0xffffe
    8000383c:	256080e7          	jalr	598(ra) # 80001a8e <myproc>

  if (p->alarm_tf)
    80003840:	20853583          	ld	a1,520(a0)
    80003844:	c585                	beqz	a1,8000386c <sys_sigreturn+0x3e>
    80003846:	84aa                	mv	s1,a0
  {
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    80003848:	12000613          	li	a2,288
    8000384c:	6d28                	ld	a0,88(a0)
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	4dc080e7          	jalr	1244(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    80003856:	2084b503          	ld	a0,520(s1)
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	18a080e7          	jalr	394(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    80003862:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1; // Re-enable the alarm
    80003866:	4785                	li	a5,1
    80003868:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret(); // function that returns the command back to the user space
    8000386c:	fffff097          	auipc	ra,0xfffff
    80003870:	6ea080e7          	jalr	1770(ra) # 80002f56 <usertrapret>
  return 0;
}
    80003874:	4501                	li	a0,0
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	64a2                	ld	s1,8(sp)
    8000387c:	6105                	add	sp,sp,32
    8000387e:	8082                	ret

0000000080003880 <sys_settickets>:

// settickets system call
uint64 sys_settickets(void)
{
    80003880:	1101                	add	sp,sp,-32
    80003882:	ec06                	sd	ra,24(sp)
    80003884:	e822                	sd	s0,16(sp)
    80003886:	1000                	add	s0,sp,32
  int n;

  // Get the number of tickets from the user
  argint(0, &n);
    80003888:	fec40593          	add	a1,s0,-20
    8000388c:	4501                	li	a0,0
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	b8c080e7          	jalr	-1140(ra) # 8000341a <argint>
  // Ensure the ticket number is valid (greater than 0)
  if (n < 1)
    80003896:	fec42783          	lw	a5,-20(s0)
    8000389a:	00f05f63          	blez	a5,800038b8 <sys_settickets+0x38>
    printf("entered ticket is invalid error");
    return -1; // Error: invalid ticket count
  }

  // Set the calling process's ticket count
  myproc()->tickets = n;
    8000389e:	ffffe097          	auipc	ra,0xffffe
    800038a2:	1f0080e7          	jalr	496(ra) # 80001a8e <myproc>
    800038a6:	fec42783          	lw	a5,-20(s0)
    800038aa:	20f52823          	sw	a5,528(a0)

  return 0; // Success
    800038ae:	4501                	li	a0,0
}
    800038b0:	60e2                	ld	ra,24(sp)
    800038b2:	6442                	ld	s0,16(sp)
    800038b4:	6105                	add	sp,sp,32
    800038b6:	8082                	ret
    printf("entered ticket is invalid error");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	cc050513          	add	a0,a0,-832 # 80008578 <syscalls+0xd8>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	cc6080e7          	jalr	-826(ra) # 80000586 <printf>
    return -1; // Error: invalid ticket count
    800038c8:	557d                	li	a0,-1
    800038ca:	b7dd                	j	800038b0 <sys_settickets+0x30>

00000000800038cc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800038cc:	7179                	add	sp,sp,-48
    800038ce:	f406                	sd	ra,40(sp)
    800038d0:	f022                	sd	s0,32(sp)
    800038d2:	ec26                	sd	s1,24(sp)
    800038d4:	e84a                	sd	s2,16(sp)
    800038d6:	e44e                	sd	s3,8(sp)
    800038d8:	e052                	sd	s4,0(sp)
    800038da:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800038dc:	00005597          	auipc	a1,0x5
    800038e0:	cbc58593          	add	a1,a1,-836 # 80008598 <syscalls+0xf8>
    800038e4:	00017517          	auipc	a0,0x17
    800038e8:	34450513          	add	a0,a0,836 # 8001ac28 <bcache>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	256080e7          	jalr	598(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800038f4:	0001f797          	auipc	a5,0x1f
    800038f8:	33478793          	add	a5,a5,820 # 80022c28 <bcache+0x8000>
    800038fc:	0001f717          	auipc	a4,0x1f
    80003900:	59470713          	add	a4,a4,1428 # 80022e90 <bcache+0x8268>
    80003904:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003908:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000390c:	00017497          	auipc	s1,0x17
    80003910:	33448493          	add	s1,s1,820 # 8001ac40 <bcache+0x18>
    b->next = bcache.head.next;
    80003914:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003916:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003918:	00005a17          	auipc	s4,0x5
    8000391c:	c88a0a13          	add	s4,s4,-888 # 800085a0 <syscalls+0x100>
    b->next = bcache.head.next;
    80003920:	2b893783          	ld	a5,696(s2)
    80003924:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003926:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000392a:	85d2                	mv	a1,s4
    8000392c:	01048513          	add	a0,s1,16
    80003930:	00001097          	auipc	ra,0x1
    80003934:	496080e7          	jalr	1174(ra) # 80004dc6 <initsleeplock>
    bcache.head.next->prev = b;
    80003938:	2b893783          	ld	a5,696(s2)
    8000393c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000393e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003942:	45848493          	add	s1,s1,1112
    80003946:	fd349de3          	bne	s1,s3,80003920 <binit+0x54>
  }
}
    8000394a:	70a2                	ld	ra,40(sp)
    8000394c:	7402                	ld	s0,32(sp)
    8000394e:	64e2                	ld	s1,24(sp)
    80003950:	6942                	ld	s2,16(sp)
    80003952:	69a2                	ld	s3,8(sp)
    80003954:	6a02                	ld	s4,0(sp)
    80003956:	6145                	add	sp,sp,48
    80003958:	8082                	ret

000000008000395a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000395a:	7179                	add	sp,sp,-48
    8000395c:	f406                	sd	ra,40(sp)
    8000395e:	f022                	sd	s0,32(sp)
    80003960:	ec26                	sd	s1,24(sp)
    80003962:	e84a                	sd	s2,16(sp)
    80003964:	e44e                	sd	s3,8(sp)
    80003966:	1800                	add	s0,sp,48
    80003968:	892a                	mv	s2,a0
    8000396a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000396c:	00017517          	auipc	a0,0x17
    80003970:	2bc50513          	add	a0,a0,700 # 8001ac28 <bcache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	25e080e7          	jalr	606(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000397c:	0001f497          	auipc	s1,0x1f
    80003980:	5644b483          	ld	s1,1380(s1) # 80022ee0 <bcache+0x82b8>
    80003984:	0001f797          	auipc	a5,0x1f
    80003988:	50c78793          	add	a5,a5,1292 # 80022e90 <bcache+0x8268>
    8000398c:	02f48f63          	beq	s1,a5,800039ca <bread+0x70>
    80003990:	873e                	mv	a4,a5
    80003992:	a021                	j	8000399a <bread+0x40>
    80003994:	68a4                	ld	s1,80(s1)
    80003996:	02e48a63          	beq	s1,a4,800039ca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000399a:	449c                	lw	a5,8(s1)
    8000399c:	ff279ce3          	bne	a5,s2,80003994 <bread+0x3a>
    800039a0:	44dc                	lw	a5,12(s1)
    800039a2:	ff3799e3          	bne	a5,s3,80003994 <bread+0x3a>
      b->refcnt++;
    800039a6:	40bc                	lw	a5,64(s1)
    800039a8:	2785                	addw	a5,a5,1
    800039aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039ac:	00017517          	auipc	a0,0x17
    800039b0:	27c50513          	add	a0,a0,636 # 8001ac28 <bcache>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2d2080e7          	jalr	722(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800039bc:	01048513          	add	a0,s1,16
    800039c0:	00001097          	auipc	ra,0x1
    800039c4:	440080e7          	jalr	1088(ra) # 80004e00 <acquiresleep>
      return b;
    800039c8:	a8b9                	j	80003a26 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039ca:	0001f497          	auipc	s1,0x1f
    800039ce:	50e4b483          	ld	s1,1294(s1) # 80022ed8 <bcache+0x82b0>
    800039d2:	0001f797          	auipc	a5,0x1f
    800039d6:	4be78793          	add	a5,a5,1214 # 80022e90 <bcache+0x8268>
    800039da:	00f48863          	beq	s1,a5,800039ea <bread+0x90>
    800039de:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800039e0:	40bc                	lw	a5,64(s1)
    800039e2:	cf81                	beqz	a5,800039fa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039e4:	64a4                	ld	s1,72(s1)
    800039e6:	fee49de3          	bne	s1,a4,800039e0 <bread+0x86>
  panic("bget: no buffers");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	bbe50513          	add	a0,a0,-1090 # 800085a8 <syscalls+0x108>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b4a080e7          	jalr	-1206(ra) # 8000053c <panic>
      b->dev = dev;
    800039fa:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800039fe:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003a02:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a06:	4785                	li	a5,1
    80003a08:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a0a:	00017517          	auipc	a0,0x17
    80003a0e:	21e50513          	add	a0,a0,542 # 8001ac28 <bcache>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	274080e7          	jalr	628(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003a1a:	01048513          	add	a0,s1,16
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	3e2080e7          	jalr	994(ra) # 80004e00 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a26:	409c                	lw	a5,0(s1)
    80003a28:	cb89                	beqz	a5,80003a3a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a2a:	8526                	mv	a0,s1
    80003a2c:	70a2                	ld	ra,40(sp)
    80003a2e:	7402                	ld	s0,32(sp)
    80003a30:	64e2                	ld	s1,24(sp)
    80003a32:	6942                	ld	s2,16(sp)
    80003a34:	69a2                	ld	s3,8(sp)
    80003a36:	6145                	add	sp,sp,48
    80003a38:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a3a:	4581                	li	a1,0
    80003a3c:	8526                	mv	a0,s1
    80003a3e:	00003097          	auipc	ra,0x3
    80003a42:	f84080e7          	jalr	-124(ra) # 800069c2 <virtio_disk_rw>
    b->valid = 1;
    80003a46:	4785                	li	a5,1
    80003a48:	c09c                	sw	a5,0(s1)
  return b;
    80003a4a:	b7c5                	j	80003a2a <bread+0xd0>

0000000080003a4c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003a4c:	1101                	add	sp,sp,-32
    80003a4e:	ec06                	sd	ra,24(sp)
    80003a50:	e822                	sd	s0,16(sp)
    80003a52:	e426                	sd	s1,8(sp)
    80003a54:	1000                	add	s0,sp,32
    80003a56:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a58:	0541                	add	a0,a0,16
    80003a5a:	00001097          	auipc	ra,0x1
    80003a5e:	440080e7          	jalr	1088(ra) # 80004e9a <holdingsleep>
    80003a62:	cd01                	beqz	a0,80003a7a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003a64:	4585                	li	a1,1
    80003a66:	8526                	mv	a0,s1
    80003a68:	00003097          	auipc	ra,0x3
    80003a6c:	f5a080e7          	jalr	-166(ra) # 800069c2 <virtio_disk_rw>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6105                	add	sp,sp,32
    80003a78:	8082                	ret
    panic("bwrite");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	b4650513          	add	a0,a0,-1210 # 800085c0 <syscalls+0x120>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	aba080e7          	jalr	-1350(ra) # 8000053c <panic>

0000000080003a8a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a8a:	1101                	add	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	add	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a98:	01050913          	add	s2,a0,16
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00001097          	auipc	ra,0x1
    80003aa2:	3fc080e7          	jalr	1020(ra) # 80004e9a <holdingsleep>
    80003aa6:	c925                	beqz	a0,80003b16 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	00001097          	auipc	ra,0x1
    80003aae:	3ac080e7          	jalr	940(ra) # 80004e56 <releasesleep>

  acquire(&bcache.lock);
    80003ab2:	00017517          	auipc	a0,0x17
    80003ab6:	17650513          	add	a0,a0,374 # 8001ac28 <bcache>
    80003aba:	ffffd097          	auipc	ra,0xffffd
    80003abe:	118080e7          	jalr	280(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003ac2:	40bc                	lw	a5,64(s1)
    80003ac4:	37fd                	addw	a5,a5,-1
    80003ac6:	0007871b          	sext.w	a4,a5
    80003aca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003acc:	e71d                	bnez	a4,80003afa <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ace:	68b8                	ld	a4,80(s1)
    80003ad0:	64bc                	ld	a5,72(s1)
    80003ad2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003ad4:	68b8                	ld	a4,80(s1)
    80003ad6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003ad8:	0001f797          	auipc	a5,0x1f
    80003adc:	15078793          	add	a5,a5,336 # 80022c28 <bcache+0x8000>
    80003ae0:	2b87b703          	ld	a4,696(a5)
    80003ae4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003ae6:	0001f717          	auipc	a4,0x1f
    80003aea:	3aa70713          	add	a4,a4,938 # 80022e90 <bcache+0x8268>
    80003aee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003af0:	2b87b703          	ld	a4,696(a5)
    80003af4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003af6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003afa:	00017517          	auipc	a0,0x17
    80003afe:	12e50513          	add	a0,a0,302 # 8001ac28 <bcache>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	184080e7          	jalr	388(ra) # 80000c86 <release>
}
    80003b0a:	60e2                	ld	ra,24(sp)
    80003b0c:	6442                	ld	s0,16(sp)
    80003b0e:	64a2                	ld	s1,8(sp)
    80003b10:	6902                	ld	s2,0(sp)
    80003b12:	6105                	add	sp,sp,32
    80003b14:	8082                	ret
    panic("brelse");
    80003b16:	00005517          	auipc	a0,0x5
    80003b1a:	ab250513          	add	a0,a0,-1358 # 800085c8 <syscalls+0x128>
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	a1e080e7          	jalr	-1506(ra) # 8000053c <panic>

0000000080003b26 <bpin>:

void
bpin(struct buf *b) {
    80003b26:	1101                	add	sp,sp,-32
    80003b28:	ec06                	sd	ra,24(sp)
    80003b2a:	e822                	sd	s0,16(sp)
    80003b2c:	e426                	sd	s1,8(sp)
    80003b2e:	1000                	add	s0,sp,32
    80003b30:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b32:	00017517          	auipc	a0,0x17
    80003b36:	0f650513          	add	a0,a0,246 # 8001ac28 <bcache>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	098080e7          	jalr	152(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003b42:	40bc                	lw	a5,64(s1)
    80003b44:	2785                	addw	a5,a5,1
    80003b46:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b48:	00017517          	auipc	a0,0x17
    80003b4c:	0e050513          	add	a0,a0,224 # 8001ac28 <bcache>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	136080e7          	jalr	310(ra) # 80000c86 <release>
}
    80003b58:	60e2                	ld	ra,24(sp)
    80003b5a:	6442                	ld	s0,16(sp)
    80003b5c:	64a2                	ld	s1,8(sp)
    80003b5e:	6105                	add	sp,sp,32
    80003b60:	8082                	ret

0000000080003b62 <bunpin>:

void
bunpin(struct buf *b) {
    80003b62:	1101                	add	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	1000                	add	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b6e:	00017517          	auipc	a0,0x17
    80003b72:	0ba50513          	add	a0,a0,186 # 8001ac28 <bcache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	05c080e7          	jalr	92(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003b7e:	40bc                	lw	a5,64(s1)
    80003b80:	37fd                	addw	a5,a5,-1
    80003b82:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b84:	00017517          	auipc	a0,0x17
    80003b88:	0a450513          	add	a0,a0,164 # 8001ac28 <bcache>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	0fa080e7          	jalr	250(ra) # 80000c86 <release>
}
    80003b94:	60e2                	ld	ra,24(sp)
    80003b96:	6442                	ld	s0,16(sp)
    80003b98:	64a2                	ld	s1,8(sp)
    80003b9a:	6105                	add	sp,sp,32
    80003b9c:	8082                	ret

0000000080003b9e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b9e:	1101                	add	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	e426                	sd	s1,8(sp)
    80003ba6:	e04a                	sd	s2,0(sp)
    80003ba8:	1000                	add	s0,sp,32
    80003baa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003bac:	00d5d59b          	srlw	a1,a1,0xd
    80003bb0:	0001f797          	auipc	a5,0x1f
    80003bb4:	7547a783          	lw	a5,1876(a5) # 80023304 <sb+0x1c>
    80003bb8:	9dbd                	addw	a1,a1,a5
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	da0080e7          	jalr	-608(ra) # 8000395a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003bc2:	0074f713          	and	a4,s1,7
    80003bc6:	4785                	li	a5,1
    80003bc8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003bcc:	14ce                	sll	s1,s1,0x33
    80003bce:	90d9                	srl	s1,s1,0x36
    80003bd0:	00950733          	add	a4,a0,s1
    80003bd4:	05874703          	lbu	a4,88(a4)
    80003bd8:	00e7f6b3          	and	a3,a5,a4
    80003bdc:	c69d                	beqz	a3,80003c0a <bfree+0x6c>
    80003bde:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003be0:	94aa                	add	s1,s1,a0
    80003be2:	fff7c793          	not	a5,a5
    80003be6:	8f7d                	and	a4,a4,a5
    80003be8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003bec:	00001097          	auipc	ra,0x1
    80003bf0:	0f6080e7          	jalr	246(ra) # 80004ce2 <log_write>
  brelse(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	e94080e7          	jalr	-364(ra) # 80003a8a <brelse>
}
    80003bfe:	60e2                	ld	ra,24(sp)
    80003c00:	6442                	ld	s0,16(sp)
    80003c02:	64a2                	ld	s1,8(sp)
    80003c04:	6902                	ld	s2,0(sp)
    80003c06:	6105                	add	sp,sp,32
    80003c08:	8082                	ret
    panic("freeing free block");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	9c650513          	add	a0,a0,-1594 # 800085d0 <syscalls+0x130>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	92a080e7          	jalr	-1750(ra) # 8000053c <panic>

0000000080003c1a <balloc>:
{
    80003c1a:	711d                	add	sp,sp,-96
    80003c1c:	ec86                	sd	ra,88(sp)
    80003c1e:	e8a2                	sd	s0,80(sp)
    80003c20:	e4a6                	sd	s1,72(sp)
    80003c22:	e0ca                	sd	s2,64(sp)
    80003c24:	fc4e                	sd	s3,56(sp)
    80003c26:	f852                	sd	s4,48(sp)
    80003c28:	f456                	sd	s5,40(sp)
    80003c2a:	f05a                	sd	s6,32(sp)
    80003c2c:	ec5e                	sd	s7,24(sp)
    80003c2e:	e862                	sd	s8,16(sp)
    80003c30:	e466                	sd	s9,8(sp)
    80003c32:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c34:	0001f797          	auipc	a5,0x1f
    80003c38:	6b87a783          	lw	a5,1720(a5) # 800232ec <sb+0x4>
    80003c3c:	cff5                	beqz	a5,80003d38 <balloc+0x11e>
    80003c3e:	8baa                	mv	s7,a0
    80003c40:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c42:	0001fb17          	auipc	s6,0x1f
    80003c46:	6a6b0b13          	add	s6,s6,1702 # 800232e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c4a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003c4c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c4e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003c50:	6c89                	lui	s9,0x2
    80003c52:	a061                	j	80003cda <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003c54:	97ca                	add	a5,a5,s2
    80003c56:	8e55                	or	a2,a2,a3
    80003c58:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	00001097          	auipc	ra,0x1
    80003c62:	084080e7          	jalr	132(ra) # 80004ce2 <log_write>
        brelse(bp);
    80003c66:	854a                	mv	a0,s2
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	e22080e7          	jalr	-478(ra) # 80003a8a <brelse>
  bp = bread(dev, bno);
    80003c70:	85a6                	mv	a1,s1
    80003c72:	855e                	mv	a0,s7
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	ce6080e7          	jalr	-794(ra) # 8000395a <bread>
    80003c7c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c7e:	40000613          	li	a2,1024
    80003c82:	4581                	li	a1,0
    80003c84:	05850513          	add	a0,a0,88
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	046080e7          	jalr	70(ra) # 80000cce <memset>
  log_write(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	050080e7          	jalr	80(ra) # 80004ce2 <log_write>
  brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	dee080e7          	jalr	-530(ra) # 80003a8a <brelse>
}
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	60e6                	ld	ra,88(sp)
    80003ca8:	6446                	ld	s0,80(sp)
    80003caa:	64a6                	ld	s1,72(sp)
    80003cac:	6906                	ld	s2,64(sp)
    80003cae:	79e2                	ld	s3,56(sp)
    80003cb0:	7a42                	ld	s4,48(sp)
    80003cb2:	7aa2                	ld	s5,40(sp)
    80003cb4:	7b02                	ld	s6,32(sp)
    80003cb6:	6be2                	ld	s7,24(sp)
    80003cb8:	6c42                	ld	s8,16(sp)
    80003cba:	6ca2                	ld	s9,8(sp)
    80003cbc:	6125                	add	sp,sp,96
    80003cbe:	8082                	ret
    brelse(bp);
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	dc8080e7          	jalr	-568(ra) # 80003a8a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003cca:	015c87bb          	addw	a5,s9,s5
    80003cce:	00078a9b          	sext.w	s5,a5
    80003cd2:	004b2703          	lw	a4,4(s6)
    80003cd6:	06eaf163          	bgeu	s5,a4,80003d38 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003cda:	41fad79b          	sraw	a5,s5,0x1f
    80003cde:	0137d79b          	srlw	a5,a5,0x13
    80003ce2:	015787bb          	addw	a5,a5,s5
    80003ce6:	40d7d79b          	sraw	a5,a5,0xd
    80003cea:	01cb2583          	lw	a1,28(s6)
    80003cee:	9dbd                	addw	a1,a1,a5
    80003cf0:	855e                	mv	a0,s7
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	c68080e7          	jalr	-920(ra) # 8000395a <bread>
    80003cfa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cfc:	004b2503          	lw	a0,4(s6)
    80003d00:	000a849b          	sext.w	s1,s5
    80003d04:	8762                	mv	a4,s8
    80003d06:	faa4fde3          	bgeu	s1,a0,80003cc0 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003d0a:	00777693          	and	a3,a4,7
    80003d0e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d12:	41f7579b          	sraw	a5,a4,0x1f
    80003d16:	01d7d79b          	srlw	a5,a5,0x1d
    80003d1a:	9fb9                	addw	a5,a5,a4
    80003d1c:	4037d79b          	sraw	a5,a5,0x3
    80003d20:	00f90633          	add	a2,s2,a5
    80003d24:	05864603          	lbu	a2,88(a2)
    80003d28:	00c6f5b3          	and	a1,a3,a2
    80003d2c:	d585                	beqz	a1,80003c54 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d2e:	2705                	addw	a4,a4,1
    80003d30:	2485                	addw	s1,s1,1
    80003d32:	fd471ae3          	bne	a4,s4,80003d06 <balloc+0xec>
    80003d36:	b769                	j	80003cc0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003d38:	00005517          	auipc	a0,0x5
    80003d3c:	8b050513          	add	a0,a0,-1872 # 800085e8 <syscalls+0x148>
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	846080e7          	jalr	-1978(ra) # 80000586 <printf>
  return 0;
    80003d48:	4481                	li	s1,0
    80003d4a:	bfa9                	j	80003ca4 <balloc+0x8a>

0000000080003d4c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003d4c:	7179                	add	sp,sp,-48
    80003d4e:	f406                	sd	ra,40(sp)
    80003d50:	f022                	sd	s0,32(sp)
    80003d52:	ec26                	sd	s1,24(sp)
    80003d54:	e84a                	sd	s2,16(sp)
    80003d56:	e44e                	sd	s3,8(sp)
    80003d58:	e052                	sd	s4,0(sp)
    80003d5a:	1800                	add	s0,sp,48
    80003d5c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003d5e:	47ad                	li	a5,11
    80003d60:	02b7e863          	bltu	a5,a1,80003d90 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003d64:	02059793          	sll	a5,a1,0x20
    80003d68:	01e7d593          	srl	a1,a5,0x1e
    80003d6c:	00b504b3          	add	s1,a0,a1
    80003d70:	0504a903          	lw	s2,80(s1)
    80003d74:	06091e63          	bnez	s2,80003df0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003d78:	4108                	lw	a0,0(a0)
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	ea0080e7          	jalr	-352(ra) # 80003c1a <balloc>
    80003d82:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d86:	06090563          	beqz	s2,80003df0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003d8a:	0524a823          	sw	s2,80(s1)
    80003d8e:	a08d                	j	80003df0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003d90:	ff45849b          	addw	s1,a1,-12
    80003d94:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d98:	0ff00793          	li	a5,255
    80003d9c:	08e7e563          	bltu	a5,a4,80003e26 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003da0:	08052903          	lw	s2,128(a0)
    80003da4:	00091d63          	bnez	s2,80003dbe <bmap+0x72>
      addr = balloc(ip->dev);
    80003da8:	4108                	lw	a0,0(a0)
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	e70080e7          	jalr	-400(ra) # 80003c1a <balloc>
    80003db2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003db6:	02090d63          	beqz	s2,80003df0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003dba:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003dbe:	85ca                	mv	a1,s2
    80003dc0:	0009a503          	lw	a0,0(s3)
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	b96080e7          	jalr	-1130(ra) # 8000395a <bread>
    80003dcc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003dce:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003dd2:	02049713          	sll	a4,s1,0x20
    80003dd6:	01e75593          	srl	a1,a4,0x1e
    80003dda:	00b784b3          	add	s1,a5,a1
    80003dde:	0004a903          	lw	s2,0(s1)
    80003de2:	02090063          	beqz	s2,80003e02 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003de6:	8552                	mv	a0,s4
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	ca2080e7          	jalr	-862(ra) # 80003a8a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003df0:	854a                	mv	a0,s2
    80003df2:	70a2                	ld	ra,40(sp)
    80003df4:	7402                	ld	s0,32(sp)
    80003df6:	64e2                	ld	s1,24(sp)
    80003df8:	6942                	ld	s2,16(sp)
    80003dfa:	69a2                	ld	s3,8(sp)
    80003dfc:	6a02                	ld	s4,0(sp)
    80003dfe:	6145                	add	sp,sp,48
    80003e00:	8082                	ret
      addr = balloc(ip->dev);
    80003e02:	0009a503          	lw	a0,0(s3)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	e14080e7          	jalr	-492(ra) # 80003c1a <balloc>
    80003e0e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003e12:	fc090ae3          	beqz	s2,80003de6 <bmap+0x9a>
        a[bn] = addr;
    80003e16:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003e1a:	8552                	mv	a0,s4
    80003e1c:	00001097          	auipc	ra,0x1
    80003e20:	ec6080e7          	jalr	-314(ra) # 80004ce2 <log_write>
    80003e24:	b7c9                	j	80003de6 <bmap+0x9a>
  panic("bmap: out of range");
    80003e26:	00004517          	auipc	a0,0x4
    80003e2a:	7da50513          	add	a0,a0,2010 # 80008600 <syscalls+0x160>
    80003e2e:	ffffc097          	auipc	ra,0xffffc
    80003e32:	70e080e7          	jalr	1806(ra) # 8000053c <panic>

0000000080003e36 <iget>:
{
    80003e36:	7179                	add	sp,sp,-48
    80003e38:	f406                	sd	ra,40(sp)
    80003e3a:	f022                	sd	s0,32(sp)
    80003e3c:	ec26                	sd	s1,24(sp)
    80003e3e:	e84a                	sd	s2,16(sp)
    80003e40:	e44e                	sd	s3,8(sp)
    80003e42:	e052                	sd	s4,0(sp)
    80003e44:	1800                	add	s0,sp,48
    80003e46:	89aa                	mv	s3,a0
    80003e48:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003e4a:	0001f517          	auipc	a0,0x1f
    80003e4e:	4be50513          	add	a0,a0,1214 # 80023308 <itable>
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	d80080e7          	jalr	-640(ra) # 80000bd2 <acquire>
  empty = 0;
    80003e5a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e5c:	0001f497          	auipc	s1,0x1f
    80003e60:	4c448493          	add	s1,s1,1220 # 80023320 <itable+0x18>
    80003e64:	00021697          	auipc	a3,0x21
    80003e68:	f4c68693          	add	a3,a3,-180 # 80024db0 <log>
    80003e6c:	a039                	j	80003e7a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e6e:	02090b63          	beqz	s2,80003ea4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e72:	08848493          	add	s1,s1,136
    80003e76:	02d48a63          	beq	s1,a3,80003eaa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e7a:	449c                	lw	a5,8(s1)
    80003e7c:	fef059e3          	blez	a5,80003e6e <iget+0x38>
    80003e80:	4098                	lw	a4,0(s1)
    80003e82:	ff3716e3          	bne	a4,s3,80003e6e <iget+0x38>
    80003e86:	40d8                	lw	a4,4(s1)
    80003e88:	ff4713e3          	bne	a4,s4,80003e6e <iget+0x38>
      ip->ref++;
    80003e8c:	2785                	addw	a5,a5,1
    80003e8e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e90:	0001f517          	auipc	a0,0x1f
    80003e94:	47850513          	add	a0,a0,1144 # 80023308 <itable>
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	dee080e7          	jalr	-530(ra) # 80000c86 <release>
      return ip;
    80003ea0:	8926                	mv	s2,s1
    80003ea2:	a03d                	j	80003ed0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ea4:	f7f9                	bnez	a5,80003e72 <iget+0x3c>
    80003ea6:	8926                	mv	s2,s1
    80003ea8:	b7e9                	j	80003e72 <iget+0x3c>
  if(empty == 0)
    80003eaa:	02090c63          	beqz	s2,80003ee2 <iget+0xac>
  ip->dev = dev;
    80003eae:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003eb2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003eb6:	4785                	li	a5,1
    80003eb8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ebc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ec0:	0001f517          	auipc	a0,0x1f
    80003ec4:	44850513          	add	a0,a0,1096 # 80023308 <itable>
    80003ec8:	ffffd097          	auipc	ra,0xffffd
    80003ecc:	dbe080e7          	jalr	-578(ra) # 80000c86 <release>
}
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	70a2                	ld	ra,40(sp)
    80003ed4:	7402                	ld	s0,32(sp)
    80003ed6:	64e2                	ld	s1,24(sp)
    80003ed8:	6942                	ld	s2,16(sp)
    80003eda:	69a2                	ld	s3,8(sp)
    80003edc:	6a02                	ld	s4,0(sp)
    80003ede:	6145                	add	sp,sp,48
    80003ee0:	8082                	ret
    panic("iget: no inodes");
    80003ee2:	00004517          	auipc	a0,0x4
    80003ee6:	73650513          	add	a0,a0,1846 # 80008618 <syscalls+0x178>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	652080e7          	jalr	1618(ra) # 8000053c <panic>

0000000080003ef2 <fsinit>:
fsinit(int dev) {
    80003ef2:	7179                	add	sp,sp,-48
    80003ef4:	f406                	sd	ra,40(sp)
    80003ef6:	f022                	sd	s0,32(sp)
    80003ef8:	ec26                	sd	s1,24(sp)
    80003efa:	e84a                	sd	s2,16(sp)
    80003efc:	e44e                	sd	s3,8(sp)
    80003efe:	1800                	add	s0,sp,48
    80003f00:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f02:	4585                	li	a1,1
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	a56080e7          	jalr	-1450(ra) # 8000395a <bread>
    80003f0c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f0e:	0001f997          	auipc	s3,0x1f
    80003f12:	3da98993          	add	s3,s3,986 # 800232e8 <sb>
    80003f16:	02000613          	li	a2,32
    80003f1a:	05850593          	add	a1,a0,88
    80003f1e:	854e                	mv	a0,s3
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	e0a080e7          	jalr	-502(ra) # 80000d2a <memmove>
  brelse(bp);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	b60080e7          	jalr	-1184(ra) # 80003a8a <brelse>
  if(sb.magic != FSMAGIC)
    80003f32:	0009a703          	lw	a4,0(s3)
    80003f36:	102037b7          	lui	a5,0x10203
    80003f3a:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f3e:	02f71263          	bne	a4,a5,80003f62 <fsinit+0x70>
  initlog(dev, &sb);
    80003f42:	0001f597          	auipc	a1,0x1f
    80003f46:	3a658593          	add	a1,a1,934 # 800232e8 <sb>
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00001097          	auipc	ra,0x1
    80003f50:	b2c080e7          	jalr	-1236(ra) # 80004a78 <initlog>
}
    80003f54:	70a2                	ld	ra,40(sp)
    80003f56:	7402                	ld	s0,32(sp)
    80003f58:	64e2                	ld	s1,24(sp)
    80003f5a:	6942                	ld	s2,16(sp)
    80003f5c:	69a2                	ld	s3,8(sp)
    80003f5e:	6145                	add	sp,sp,48
    80003f60:	8082                	ret
    panic("invalid file system");
    80003f62:	00004517          	auipc	a0,0x4
    80003f66:	6c650513          	add	a0,a0,1734 # 80008628 <syscalls+0x188>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5d2080e7          	jalr	1490(ra) # 8000053c <panic>

0000000080003f72 <iinit>:
{
    80003f72:	7179                	add	sp,sp,-48
    80003f74:	f406                	sd	ra,40(sp)
    80003f76:	f022                	sd	s0,32(sp)
    80003f78:	ec26                	sd	s1,24(sp)
    80003f7a:	e84a                	sd	s2,16(sp)
    80003f7c:	e44e                	sd	s3,8(sp)
    80003f7e:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f80:	00004597          	auipc	a1,0x4
    80003f84:	6c058593          	add	a1,a1,1728 # 80008640 <syscalls+0x1a0>
    80003f88:	0001f517          	auipc	a0,0x1f
    80003f8c:	38050513          	add	a0,a0,896 # 80023308 <itable>
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	bb2080e7          	jalr	-1102(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003f98:	0001f497          	auipc	s1,0x1f
    80003f9c:	39848493          	add	s1,s1,920 # 80023330 <itable+0x28>
    80003fa0:	00021997          	auipc	s3,0x21
    80003fa4:	e2098993          	add	s3,s3,-480 # 80024dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003fa8:	00004917          	auipc	s2,0x4
    80003fac:	6a090913          	add	s2,s2,1696 # 80008648 <syscalls+0x1a8>
    80003fb0:	85ca                	mv	a1,s2
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	00001097          	auipc	ra,0x1
    80003fb8:	e12080e7          	jalr	-494(ra) # 80004dc6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003fbc:	08848493          	add	s1,s1,136
    80003fc0:	ff3498e3          	bne	s1,s3,80003fb0 <iinit+0x3e>
}
    80003fc4:	70a2                	ld	ra,40(sp)
    80003fc6:	7402                	ld	s0,32(sp)
    80003fc8:	64e2                	ld	s1,24(sp)
    80003fca:	6942                	ld	s2,16(sp)
    80003fcc:	69a2                	ld	s3,8(sp)
    80003fce:	6145                	add	sp,sp,48
    80003fd0:	8082                	ret

0000000080003fd2 <ialloc>:
{
    80003fd2:	7139                	add	sp,sp,-64
    80003fd4:	fc06                	sd	ra,56(sp)
    80003fd6:	f822                	sd	s0,48(sp)
    80003fd8:	f426                	sd	s1,40(sp)
    80003fda:	f04a                	sd	s2,32(sp)
    80003fdc:	ec4e                	sd	s3,24(sp)
    80003fde:	e852                	sd	s4,16(sp)
    80003fe0:	e456                	sd	s5,8(sp)
    80003fe2:	e05a                	sd	s6,0(sp)
    80003fe4:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003fe6:	0001f717          	auipc	a4,0x1f
    80003fea:	30e72703          	lw	a4,782(a4) # 800232f4 <sb+0xc>
    80003fee:	4785                	li	a5,1
    80003ff0:	04e7f863          	bgeu	a5,a4,80004040 <ialloc+0x6e>
    80003ff4:	8aaa                	mv	s5,a0
    80003ff6:	8b2e                	mv	s6,a1
    80003ff8:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ffa:	0001fa17          	auipc	s4,0x1f
    80003ffe:	2eea0a13          	add	s4,s4,750 # 800232e8 <sb>
    80004002:	00495593          	srl	a1,s2,0x4
    80004006:	018a2783          	lw	a5,24(s4)
    8000400a:	9dbd                	addw	a1,a1,a5
    8000400c:	8556                	mv	a0,s5
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	94c080e7          	jalr	-1716(ra) # 8000395a <bread>
    80004016:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004018:	05850993          	add	s3,a0,88
    8000401c:	00f97793          	and	a5,s2,15
    80004020:	079a                	sll	a5,a5,0x6
    80004022:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004024:	00099783          	lh	a5,0(s3)
    80004028:	cf9d                	beqz	a5,80004066 <ialloc+0x94>
    brelse(bp);
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	a60080e7          	jalr	-1440(ra) # 80003a8a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004032:	0905                	add	s2,s2,1
    80004034:	00ca2703          	lw	a4,12(s4)
    80004038:	0009079b          	sext.w	a5,s2
    8000403c:	fce7e3e3          	bltu	a5,a4,80004002 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80004040:	00004517          	auipc	a0,0x4
    80004044:	61050513          	add	a0,a0,1552 # 80008650 <syscalls+0x1b0>
    80004048:	ffffc097          	auipc	ra,0xffffc
    8000404c:	53e080e7          	jalr	1342(ra) # 80000586 <printf>
  return 0;
    80004050:	4501                	li	a0,0
}
    80004052:	70e2                	ld	ra,56(sp)
    80004054:	7442                	ld	s0,48(sp)
    80004056:	74a2                	ld	s1,40(sp)
    80004058:	7902                	ld	s2,32(sp)
    8000405a:	69e2                	ld	s3,24(sp)
    8000405c:	6a42                	ld	s4,16(sp)
    8000405e:	6aa2                	ld	s5,8(sp)
    80004060:	6b02                	ld	s6,0(sp)
    80004062:	6121                	add	sp,sp,64
    80004064:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004066:	04000613          	li	a2,64
    8000406a:	4581                	li	a1,0
    8000406c:	854e                	mv	a0,s3
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	c60080e7          	jalr	-928(ra) # 80000cce <memset>
      dip->type = type;
    80004076:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000407a:	8526                	mv	a0,s1
    8000407c:	00001097          	auipc	ra,0x1
    80004080:	c66080e7          	jalr	-922(ra) # 80004ce2 <log_write>
      brelse(bp);
    80004084:	8526                	mv	a0,s1
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	a04080e7          	jalr	-1532(ra) # 80003a8a <brelse>
      return iget(dev, inum);
    8000408e:	0009059b          	sext.w	a1,s2
    80004092:	8556                	mv	a0,s5
    80004094:	00000097          	auipc	ra,0x0
    80004098:	da2080e7          	jalr	-606(ra) # 80003e36 <iget>
    8000409c:	bf5d                	j	80004052 <ialloc+0x80>

000000008000409e <iupdate>:
{
    8000409e:	1101                	add	sp,sp,-32
    800040a0:	ec06                	sd	ra,24(sp)
    800040a2:	e822                	sd	s0,16(sp)
    800040a4:	e426                	sd	s1,8(sp)
    800040a6:	e04a                	sd	s2,0(sp)
    800040a8:	1000                	add	s0,sp,32
    800040aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040ac:	415c                	lw	a5,4(a0)
    800040ae:	0047d79b          	srlw	a5,a5,0x4
    800040b2:	0001f597          	auipc	a1,0x1f
    800040b6:	24e5a583          	lw	a1,590(a1) # 80023300 <sb+0x18>
    800040ba:	9dbd                	addw	a1,a1,a5
    800040bc:	4108                	lw	a0,0(a0)
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	89c080e7          	jalr	-1892(ra) # 8000395a <bread>
    800040c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040c8:	05850793          	add	a5,a0,88
    800040cc:	40d8                	lw	a4,4(s1)
    800040ce:	8b3d                	and	a4,a4,15
    800040d0:	071a                	sll	a4,a4,0x6
    800040d2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800040d4:	04449703          	lh	a4,68(s1)
    800040d8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800040dc:	04649703          	lh	a4,70(s1)
    800040e0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800040e4:	04849703          	lh	a4,72(s1)
    800040e8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800040ec:	04a49703          	lh	a4,74(s1)
    800040f0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800040f4:	44f8                	lw	a4,76(s1)
    800040f6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800040f8:	03400613          	li	a2,52
    800040fc:	05048593          	add	a1,s1,80
    80004100:	00c78513          	add	a0,a5,12
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	c26080e7          	jalr	-986(ra) # 80000d2a <memmove>
  log_write(bp);
    8000410c:	854a                	mv	a0,s2
    8000410e:	00001097          	auipc	ra,0x1
    80004112:	bd4080e7          	jalr	-1068(ra) # 80004ce2 <log_write>
  brelse(bp);
    80004116:	854a                	mv	a0,s2
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	972080e7          	jalr	-1678(ra) # 80003a8a <brelse>
}
    80004120:	60e2                	ld	ra,24(sp)
    80004122:	6442                	ld	s0,16(sp)
    80004124:	64a2                	ld	s1,8(sp)
    80004126:	6902                	ld	s2,0(sp)
    80004128:	6105                	add	sp,sp,32
    8000412a:	8082                	ret

000000008000412c <idup>:
{
    8000412c:	1101                	add	sp,sp,-32
    8000412e:	ec06                	sd	ra,24(sp)
    80004130:	e822                	sd	s0,16(sp)
    80004132:	e426                	sd	s1,8(sp)
    80004134:	1000                	add	s0,sp,32
    80004136:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004138:	0001f517          	auipc	a0,0x1f
    8000413c:	1d050513          	add	a0,a0,464 # 80023308 <itable>
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	a92080e7          	jalr	-1390(ra) # 80000bd2 <acquire>
  ip->ref++;
    80004148:	449c                	lw	a5,8(s1)
    8000414a:	2785                	addw	a5,a5,1
    8000414c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000414e:	0001f517          	auipc	a0,0x1f
    80004152:	1ba50513          	add	a0,a0,442 # 80023308 <itable>
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	b30080e7          	jalr	-1232(ra) # 80000c86 <release>
}
    8000415e:	8526                	mv	a0,s1
    80004160:	60e2                	ld	ra,24(sp)
    80004162:	6442                	ld	s0,16(sp)
    80004164:	64a2                	ld	s1,8(sp)
    80004166:	6105                	add	sp,sp,32
    80004168:	8082                	ret

000000008000416a <ilock>:
{
    8000416a:	1101                	add	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004176:	c115                	beqz	a0,8000419a <ilock+0x30>
    80004178:	84aa                	mv	s1,a0
    8000417a:	451c                	lw	a5,8(a0)
    8000417c:	00f05f63          	blez	a5,8000419a <ilock+0x30>
  acquiresleep(&ip->lock);
    80004180:	0541                	add	a0,a0,16
    80004182:	00001097          	auipc	ra,0x1
    80004186:	c7e080e7          	jalr	-898(ra) # 80004e00 <acquiresleep>
  if(ip->valid == 0){
    8000418a:	40bc                	lw	a5,64(s1)
    8000418c:	cf99                	beqz	a5,800041aa <ilock+0x40>
}
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6902                	ld	s2,0(sp)
    80004196:	6105                	add	sp,sp,32
    80004198:	8082                	ret
    panic("ilock");
    8000419a:	00004517          	auipc	a0,0x4
    8000419e:	4ce50513          	add	a0,a0,1230 # 80008668 <syscalls+0x1c8>
    800041a2:	ffffc097          	auipc	ra,0xffffc
    800041a6:	39a080e7          	jalr	922(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041aa:	40dc                	lw	a5,4(s1)
    800041ac:	0047d79b          	srlw	a5,a5,0x4
    800041b0:	0001f597          	auipc	a1,0x1f
    800041b4:	1505a583          	lw	a1,336(a1) # 80023300 <sb+0x18>
    800041b8:	9dbd                	addw	a1,a1,a5
    800041ba:	4088                	lw	a0,0(s1)
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	79e080e7          	jalr	1950(ra) # 8000395a <bread>
    800041c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041c6:	05850593          	add	a1,a0,88
    800041ca:	40dc                	lw	a5,4(s1)
    800041cc:	8bbd                	and	a5,a5,15
    800041ce:	079a                	sll	a5,a5,0x6
    800041d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800041d2:	00059783          	lh	a5,0(a1)
    800041d6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800041da:	00259783          	lh	a5,2(a1)
    800041de:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800041e2:	00459783          	lh	a5,4(a1)
    800041e6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800041ea:	00659783          	lh	a5,6(a1)
    800041ee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800041f2:	459c                	lw	a5,8(a1)
    800041f4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800041f6:	03400613          	li	a2,52
    800041fa:	05b1                	add	a1,a1,12
    800041fc:	05048513          	add	a0,s1,80
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	b2a080e7          	jalr	-1238(ra) # 80000d2a <memmove>
    brelse(bp);
    80004208:	854a                	mv	a0,s2
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	880080e7          	jalr	-1920(ra) # 80003a8a <brelse>
    ip->valid = 1;
    80004212:	4785                	li	a5,1
    80004214:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004216:	04449783          	lh	a5,68(s1)
    8000421a:	fbb5                	bnez	a5,8000418e <ilock+0x24>
      panic("ilock: no type");
    8000421c:	00004517          	auipc	a0,0x4
    80004220:	45450513          	add	a0,a0,1108 # 80008670 <syscalls+0x1d0>
    80004224:	ffffc097          	auipc	ra,0xffffc
    80004228:	318080e7          	jalr	792(ra) # 8000053c <panic>

000000008000422c <iunlock>:
{
    8000422c:	1101                	add	sp,sp,-32
    8000422e:	ec06                	sd	ra,24(sp)
    80004230:	e822                	sd	s0,16(sp)
    80004232:	e426                	sd	s1,8(sp)
    80004234:	e04a                	sd	s2,0(sp)
    80004236:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004238:	c905                	beqz	a0,80004268 <iunlock+0x3c>
    8000423a:	84aa                	mv	s1,a0
    8000423c:	01050913          	add	s2,a0,16
    80004240:	854a                	mv	a0,s2
    80004242:	00001097          	auipc	ra,0x1
    80004246:	c58080e7          	jalr	-936(ra) # 80004e9a <holdingsleep>
    8000424a:	cd19                	beqz	a0,80004268 <iunlock+0x3c>
    8000424c:	449c                	lw	a5,8(s1)
    8000424e:	00f05d63          	blez	a5,80004268 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004252:	854a                	mv	a0,s2
    80004254:	00001097          	auipc	ra,0x1
    80004258:	c02080e7          	jalr	-1022(ra) # 80004e56 <releasesleep>
}
    8000425c:	60e2                	ld	ra,24(sp)
    8000425e:	6442                	ld	s0,16(sp)
    80004260:	64a2                	ld	s1,8(sp)
    80004262:	6902                	ld	s2,0(sp)
    80004264:	6105                	add	sp,sp,32
    80004266:	8082                	ret
    panic("iunlock");
    80004268:	00004517          	auipc	a0,0x4
    8000426c:	41850513          	add	a0,a0,1048 # 80008680 <syscalls+0x1e0>
    80004270:	ffffc097          	auipc	ra,0xffffc
    80004274:	2cc080e7          	jalr	716(ra) # 8000053c <panic>

0000000080004278 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004278:	7179                	add	sp,sp,-48
    8000427a:	f406                	sd	ra,40(sp)
    8000427c:	f022                	sd	s0,32(sp)
    8000427e:	ec26                	sd	s1,24(sp)
    80004280:	e84a                	sd	s2,16(sp)
    80004282:	e44e                	sd	s3,8(sp)
    80004284:	e052                	sd	s4,0(sp)
    80004286:	1800                	add	s0,sp,48
    80004288:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000428a:	05050493          	add	s1,a0,80
    8000428e:	08050913          	add	s2,a0,128
    80004292:	a021                	j	8000429a <itrunc+0x22>
    80004294:	0491                	add	s1,s1,4
    80004296:	01248d63          	beq	s1,s2,800042b0 <itrunc+0x38>
    if(ip->addrs[i]){
    8000429a:	408c                	lw	a1,0(s1)
    8000429c:	dde5                	beqz	a1,80004294 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000429e:	0009a503          	lw	a0,0(s3)
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	8fc080e7          	jalr	-1796(ra) # 80003b9e <bfree>
      ip->addrs[i] = 0;
    800042aa:	0004a023          	sw	zero,0(s1)
    800042ae:	b7dd                	j	80004294 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800042b0:	0809a583          	lw	a1,128(s3)
    800042b4:	e185                	bnez	a1,800042d4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800042b6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800042ba:	854e                	mv	a0,s3
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	de2080e7          	jalr	-542(ra) # 8000409e <iupdate>
}
    800042c4:	70a2                	ld	ra,40(sp)
    800042c6:	7402                	ld	s0,32(sp)
    800042c8:	64e2                	ld	s1,24(sp)
    800042ca:	6942                	ld	s2,16(sp)
    800042cc:	69a2                	ld	s3,8(sp)
    800042ce:	6a02                	ld	s4,0(sp)
    800042d0:	6145                	add	sp,sp,48
    800042d2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800042d4:	0009a503          	lw	a0,0(s3)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	682080e7          	jalr	1666(ra) # 8000395a <bread>
    800042e0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800042e2:	05850493          	add	s1,a0,88
    800042e6:	45850913          	add	s2,a0,1112
    800042ea:	a021                	j	800042f2 <itrunc+0x7a>
    800042ec:	0491                	add	s1,s1,4
    800042ee:	01248b63          	beq	s1,s2,80004304 <itrunc+0x8c>
      if(a[j])
    800042f2:	408c                	lw	a1,0(s1)
    800042f4:	dde5                	beqz	a1,800042ec <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800042f6:	0009a503          	lw	a0,0(s3)
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	8a4080e7          	jalr	-1884(ra) # 80003b9e <bfree>
    80004302:	b7ed                	j	800042ec <itrunc+0x74>
    brelse(bp);
    80004304:	8552                	mv	a0,s4
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	784080e7          	jalr	1924(ra) # 80003a8a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000430e:	0809a583          	lw	a1,128(s3)
    80004312:	0009a503          	lw	a0,0(s3)
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	888080e7          	jalr	-1912(ra) # 80003b9e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000431e:	0809a023          	sw	zero,128(s3)
    80004322:	bf51                	j	800042b6 <itrunc+0x3e>

0000000080004324 <iput>:
{
    80004324:	1101                	add	sp,sp,-32
    80004326:	ec06                	sd	ra,24(sp)
    80004328:	e822                	sd	s0,16(sp)
    8000432a:	e426                	sd	s1,8(sp)
    8000432c:	e04a                	sd	s2,0(sp)
    8000432e:	1000                	add	s0,sp,32
    80004330:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004332:	0001f517          	auipc	a0,0x1f
    80004336:	fd650513          	add	a0,a0,-42 # 80023308 <itable>
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	898080e7          	jalr	-1896(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004342:	4498                	lw	a4,8(s1)
    80004344:	4785                	li	a5,1
    80004346:	02f70363          	beq	a4,a5,8000436c <iput+0x48>
  ip->ref--;
    8000434a:	449c                	lw	a5,8(s1)
    8000434c:	37fd                	addw	a5,a5,-1
    8000434e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004350:	0001f517          	auipc	a0,0x1f
    80004354:	fb850513          	add	a0,a0,-72 # 80023308 <itable>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	92e080e7          	jalr	-1746(ra) # 80000c86 <release>
}
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	64a2                	ld	s1,8(sp)
    80004366:	6902                	ld	s2,0(sp)
    80004368:	6105                	add	sp,sp,32
    8000436a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000436c:	40bc                	lw	a5,64(s1)
    8000436e:	dff1                	beqz	a5,8000434a <iput+0x26>
    80004370:	04a49783          	lh	a5,74(s1)
    80004374:	fbf9                	bnez	a5,8000434a <iput+0x26>
    acquiresleep(&ip->lock);
    80004376:	01048913          	add	s2,s1,16
    8000437a:	854a                	mv	a0,s2
    8000437c:	00001097          	auipc	ra,0x1
    80004380:	a84080e7          	jalr	-1404(ra) # 80004e00 <acquiresleep>
    release(&itable.lock);
    80004384:	0001f517          	auipc	a0,0x1f
    80004388:	f8450513          	add	a0,a0,-124 # 80023308 <itable>
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	8fa080e7          	jalr	-1798(ra) # 80000c86 <release>
    itrunc(ip);
    80004394:	8526                	mv	a0,s1
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	ee2080e7          	jalr	-286(ra) # 80004278 <itrunc>
    ip->type = 0;
    8000439e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800043a2:	8526                	mv	a0,s1
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	cfa080e7          	jalr	-774(ra) # 8000409e <iupdate>
    ip->valid = 0;
    800043ac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800043b0:	854a                	mv	a0,s2
    800043b2:	00001097          	auipc	ra,0x1
    800043b6:	aa4080e7          	jalr	-1372(ra) # 80004e56 <releasesleep>
    acquire(&itable.lock);
    800043ba:	0001f517          	auipc	a0,0x1f
    800043be:	f4e50513          	add	a0,a0,-178 # 80023308 <itable>
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	810080e7          	jalr	-2032(ra) # 80000bd2 <acquire>
    800043ca:	b741                	j	8000434a <iput+0x26>

00000000800043cc <iunlockput>:
{
    800043cc:	1101                	add	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	1000                	add	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
  iunlock(ip);
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	e54080e7          	jalr	-428(ra) # 8000422c <iunlock>
  iput(ip);
    800043e0:	8526                	mv	a0,s1
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	f42080e7          	jalr	-190(ra) # 80004324 <iput>
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6105                	add	sp,sp,32
    800043f2:	8082                	ret

00000000800043f4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800043f4:	1141                	add	sp,sp,-16
    800043f6:	e422                	sd	s0,8(sp)
    800043f8:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800043fa:	411c                	lw	a5,0(a0)
    800043fc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800043fe:	415c                	lw	a5,4(a0)
    80004400:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004402:	04451783          	lh	a5,68(a0)
    80004406:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000440a:	04a51783          	lh	a5,74(a0)
    8000440e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004412:	04c56783          	lwu	a5,76(a0)
    80004416:	e99c                	sd	a5,16(a1)
}
    80004418:	6422                	ld	s0,8(sp)
    8000441a:	0141                	add	sp,sp,16
    8000441c:	8082                	ret

000000008000441e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000441e:	457c                	lw	a5,76(a0)
    80004420:	0ed7e963          	bltu	a5,a3,80004512 <readi+0xf4>
{
    80004424:	7159                	add	sp,sp,-112
    80004426:	f486                	sd	ra,104(sp)
    80004428:	f0a2                	sd	s0,96(sp)
    8000442a:	eca6                	sd	s1,88(sp)
    8000442c:	e8ca                	sd	s2,80(sp)
    8000442e:	e4ce                	sd	s3,72(sp)
    80004430:	e0d2                	sd	s4,64(sp)
    80004432:	fc56                	sd	s5,56(sp)
    80004434:	f85a                	sd	s6,48(sp)
    80004436:	f45e                	sd	s7,40(sp)
    80004438:	f062                	sd	s8,32(sp)
    8000443a:	ec66                	sd	s9,24(sp)
    8000443c:	e86a                	sd	s10,16(sp)
    8000443e:	e46e                	sd	s11,8(sp)
    80004440:	1880                	add	s0,sp,112
    80004442:	8b2a                	mv	s6,a0
    80004444:	8bae                	mv	s7,a1
    80004446:	8a32                	mv	s4,a2
    80004448:	84b6                	mv	s1,a3
    8000444a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000444c:	9f35                	addw	a4,a4,a3
    return 0;
    8000444e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004450:	0ad76063          	bltu	a4,a3,800044f0 <readi+0xd2>
  if(off + n > ip->size)
    80004454:	00e7f463          	bgeu	a5,a4,8000445c <readi+0x3e>
    n = ip->size - off;
    80004458:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000445c:	0a0a8963          	beqz	s5,8000450e <readi+0xf0>
    80004460:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004462:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004466:	5c7d                	li	s8,-1
    80004468:	a82d                	j	800044a2 <readi+0x84>
    8000446a:	020d1d93          	sll	s11,s10,0x20
    8000446e:	020ddd93          	srl	s11,s11,0x20
    80004472:	05890613          	add	a2,s2,88
    80004476:	86ee                	mv	a3,s11
    80004478:	963a                	add	a2,a2,a4
    8000447a:	85d2                	mv	a1,s4
    8000447c:	855e                	mv	a0,s7
    8000447e:	ffffe097          	auipc	ra,0xffffe
    80004482:	728080e7          	jalr	1832(ra) # 80002ba6 <either_copyout>
    80004486:	05850d63          	beq	a0,s8,800044e0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000448a:	854a                	mv	a0,s2
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	5fe080e7          	jalr	1534(ra) # 80003a8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004494:	013d09bb          	addw	s3,s10,s3
    80004498:	009d04bb          	addw	s1,s10,s1
    8000449c:	9a6e                	add	s4,s4,s11
    8000449e:	0559f763          	bgeu	s3,s5,800044ec <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800044a2:	00a4d59b          	srlw	a1,s1,0xa
    800044a6:	855a                	mv	a0,s6
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	8a4080e7          	jalr	-1884(ra) # 80003d4c <bmap>
    800044b0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800044b4:	cd85                	beqz	a1,800044ec <readi+0xce>
    bp = bread(ip->dev, addr);
    800044b6:	000b2503          	lw	a0,0(s6)
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	4a0080e7          	jalr	1184(ra) # 8000395a <bread>
    800044c2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044c4:	3ff4f713          	and	a4,s1,1023
    800044c8:	40ec87bb          	subw	a5,s9,a4
    800044cc:	413a86bb          	subw	a3,s5,s3
    800044d0:	8d3e                	mv	s10,a5
    800044d2:	2781                	sext.w	a5,a5
    800044d4:	0006861b          	sext.w	a2,a3
    800044d8:	f8f679e3          	bgeu	a2,a5,8000446a <readi+0x4c>
    800044dc:	8d36                	mv	s10,a3
    800044de:	b771                	j	8000446a <readi+0x4c>
      brelse(bp);
    800044e0:	854a                	mv	a0,s2
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	5a8080e7          	jalr	1448(ra) # 80003a8a <brelse>
      tot = -1;
    800044ea:	59fd                	li	s3,-1
  }
  return tot;
    800044ec:	0009851b          	sext.w	a0,s3
}
    800044f0:	70a6                	ld	ra,104(sp)
    800044f2:	7406                	ld	s0,96(sp)
    800044f4:	64e6                	ld	s1,88(sp)
    800044f6:	6946                	ld	s2,80(sp)
    800044f8:	69a6                	ld	s3,72(sp)
    800044fa:	6a06                	ld	s4,64(sp)
    800044fc:	7ae2                	ld	s5,56(sp)
    800044fe:	7b42                	ld	s6,48(sp)
    80004500:	7ba2                	ld	s7,40(sp)
    80004502:	7c02                	ld	s8,32(sp)
    80004504:	6ce2                	ld	s9,24(sp)
    80004506:	6d42                	ld	s10,16(sp)
    80004508:	6da2                	ld	s11,8(sp)
    8000450a:	6165                	add	sp,sp,112
    8000450c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000450e:	89d6                	mv	s3,s5
    80004510:	bff1                	j	800044ec <readi+0xce>
    return 0;
    80004512:	4501                	li	a0,0
}
    80004514:	8082                	ret

0000000080004516 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004516:	457c                	lw	a5,76(a0)
    80004518:	10d7e863          	bltu	a5,a3,80004628 <writei+0x112>
{
    8000451c:	7159                	add	sp,sp,-112
    8000451e:	f486                	sd	ra,104(sp)
    80004520:	f0a2                	sd	s0,96(sp)
    80004522:	eca6                	sd	s1,88(sp)
    80004524:	e8ca                	sd	s2,80(sp)
    80004526:	e4ce                	sd	s3,72(sp)
    80004528:	e0d2                	sd	s4,64(sp)
    8000452a:	fc56                	sd	s5,56(sp)
    8000452c:	f85a                	sd	s6,48(sp)
    8000452e:	f45e                	sd	s7,40(sp)
    80004530:	f062                	sd	s8,32(sp)
    80004532:	ec66                	sd	s9,24(sp)
    80004534:	e86a                	sd	s10,16(sp)
    80004536:	e46e                	sd	s11,8(sp)
    80004538:	1880                	add	s0,sp,112
    8000453a:	8aaa                	mv	s5,a0
    8000453c:	8bae                	mv	s7,a1
    8000453e:	8a32                	mv	s4,a2
    80004540:	8936                	mv	s2,a3
    80004542:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004544:	00e687bb          	addw	a5,a3,a4
    80004548:	0ed7e263          	bltu	a5,a3,8000462c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000454c:	00043737          	lui	a4,0x43
    80004550:	0ef76063          	bltu	a4,a5,80004630 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004554:	0c0b0863          	beqz	s6,80004624 <writei+0x10e>
    80004558:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000455a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000455e:	5c7d                	li	s8,-1
    80004560:	a091                	j	800045a4 <writei+0x8e>
    80004562:	020d1d93          	sll	s11,s10,0x20
    80004566:	020ddd93          	srl	s11,s11,0x20
    8000456a:	05848513          	add	a0,s1,88
    8000456e:	86ee                	mv	a3,s11
    80004570:	8652                	mv	a2,s4
    80004572:	85de                	mv	a1,s7
    80004574:	953a                	add	a0,a0,a4
    80004576:	ffffe097          	auipc	ra,0xffffe
    8000457a:	686080e7          	jalr	1670(ra) # 80002bfc <either_copyin>
    8000457e:	07850263          	beq	a0,s8,800045e2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004582:	8526                	mv	a0,s1
    80004584:	00000097          	auipc	ra,0x0
    80004588:	75e080e7          	jalr	1886(ra) # 80004ce2 <log_write>
    brelse(bp);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	4fc080e7          	jalr	1276(ra) # 80003a8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004596:	013d09bb          	addw	s3,s10,s3
    8000459a:	012d093b          	addw	s2,s10,s2
    8000459e:	9a6e                	add	s4,s4,s11
    800045a0:	0569f663          	bgeu	s3,s6,800045ec <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800045a4:	00a9559b          	srlw	a1,s2,0xa
    800045a8:	8556                	mv	a0,s5
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	7a2080e7          	jalr	1954(ra) # 80003d4c <bmap>
    800045b2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800045b6:	c99d                	beqz	a1,800045ec <writei+0xd6>
    bp = bread(ip->dev, addr);
    800045b8:	000aa503          	lw	a0,0(s5)
    800045bc:	fffff097          	auipc	ra,0xfffff
    800045c0:	39e080e7          	jalr	926(ra) # 8000395a <bread>
    800045c4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045c6:	3ff97713          	and	a4,s2,1023
    800045ca:	40ec87bb          	subw	a5,s9,a4
    800045ce:	413b06bb          	subw	a3,s6,s3
    800045d2:	8d3e                	mv	s10,a5
    800045d4:	2781                	sext.w	a5,a5
    800045d6:	0006861b          	sext.w	a2,a3
    800045da:	f8f674e3          	bgeu	a2,a5,80004562 <writei+0x4c>
    800045de:	8d36                	mv	s10,a3
    800045e0:	b749                	j	80004562 <writei+0x4c>
      brelse(bp);
    800045e2:	8526                	mv	a0,s1
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	4a6080e7          	jalr	1190(ra) # 80003a8a <brelse>
  }

  if(off > ip->size)
    800045ec:	04caa783          	lw	a5,76(s5)
    800045f0:	0127f463          	bgeu	a5,s2,800045f8 <writei+0xe2>
    ip->size = off;
    800045f4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800045f8:	8556                	mv	a0,s5
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	aa4080e7          	jalr	-1372(ra) # 8000409e <iupdate>

  return tot;
    80004602:	0009851b          	sext.w	a0,s3
}
    80004606:	70a6                	ld	ra,104(sp)
    80004608:	7406                	ld	s0,96(sp)
    8000460a:	64e6                	ld	s1,88(sp)
    8000460c:	6946                	ld	s2,80(sp)
    8000460e:	69a6                	ld	s3,72(sp)
    80004610:	6a06                	ld	s4,64(sp)
    80004612:	7ae2                	ld	s5,56(sp)
    80004614:	7b42                	ld	s6,48(sp)
    80004616:	7ba2                	ld	s7,40(sp)
    80004618:	7c02                	ld	s8,32(sp)
    8000461a:	6ce2                	ld	s9,24(sp)
    8000461c:	6d42                	ld	s10,16(sp)
    8000461e:	6da2                	ld	s11,8(sp)
    80004620:	6165                	add	sp,sp,112
    80004622:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004624:	89da                	mv	s3,s6
    80004626:	bfc9                	j	800045f8 <writei+0xe2>
    return -1;
    80004628:	557d                	li	a0,-1
}
    8000462a:	8082                	ret
    return -1;
    8000462c:	557d                	li	a0,-1
    8000462e:	bfe1                	j	80004606 <writei+0xf0>
    return -1;
    80004630:	557d                	li	a0,-1
    80004632:	bfd1                	j	80004606 <writei+0xf0>

0000000080004634 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004634:	1141                	add	sp,sp,-16
    80004636:	e406                	sd	ra,8(sp)
    80004638:	e022                	sd	s0,0(sp)
    8000463a:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000463c:	4639                	li	a2,14
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	760080e7          	jalr	1888(ra) # 80000d9e <strncmp>
}
    80004646:	60a2                	ld	ra,8(sp)
    80004648:	6402                	ld	s0,0(sp)
    8000464a:	0141                	add	sp,sp,16
    8000464c:	8082                	ret

000000008000464e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000464e:	7139                	add	sp,sp,-64
    80004650:	fc06                	sd	ra,56(sp)
    80004652:	f822                	sd	s0,48(sp)
    80004654:	f426                	sd	s1,40(sp)
    80004656:	f04a                	sd	s2,32(sp)
    80004658:	ec4e                	sd	s3,24(sp)
    8000465a:	e852                	sd	s4,16(sp)
    8000465c:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000465e:	04451703          	lh	a4,68(a0)
    80004662:	4785                	li	a5,1
    80004664:	00f71a63          	bne	a4,a5,80004678 <dirlookup+0x2a>
    80004668:	892a                	mv	s2,a0
    8000466a:	89ae                	mv	s3,a1
    8000466c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000466e:	457c                	lw	a5,76(a0)
    80004670:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004672:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004674:	e79d                	bnez	a5,800046a2 <dirlookup+0x54>
    80004676:	a8a5                	j	800046ee <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	01050513          	add	a0,a0,16 # 80008688 <syscalls+0x1e8>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ebc080e7          	jalr	-324(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004688:	00004517          	auipc	a0,0x4
    8000468c:	01850513          	add	a0,a0,24 # 800086a0 <syscalls+0x200>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	eac080e7          	jalr	-340(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004698:	24c1                	addw	s1,s1,16
    8000469a:	04c92783          	lw	a5,76(s2)
    8000469e:	04f4f763          	bgeu	s1,a5,800046ec <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046a2:	4741                	li	a4,16
    800046a4:	86a6                	mv	a3,s1
    800046a6:	fc040613          	add	a2,s0,-64
    800046aa:	4581                	li	a1,0
    800046ac:	854a                	mv	a0,s2
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	d70080e7          	jalr	-656(ra) # 8000441e <readi>
    800046b6:	47c1                	li	a5,16
    800046b8:	fcf518e3          	bne	a0,a5,80004688 <dirlookup+0x3a>
    if(de.inum == 0)
    800046bc:	fc045783          	lhu	a5,-64(s0)
    800046c0:	dfe1                	beqz	a5,80004698 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800046c2:	fc240593          	add	a1,s0,-62
    800046c6:	854e                	mv	a0,s3
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	f6c080e7          	jalr	-148(ra) # 80004634 <namecmp>
    800046d0:	f561                	bnez	a0,80004698 <dirlookup+0x4a>
      if(poff)
    800046d2:	000a0463          	beqz	s4,800046da <dirlookup+0x8c>
        *poff = off;
    800046d6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800046da:	fc045583          	lhu	a1,-64(s0)
    800046de:	00092503          	lw	a0,0(s2)
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	754080e7          	jalr	1876(ra) # 80003e36 <iget>
    800046ea:	a011                	j	800046ee <dirlookup+0xa0>
  return 0;
    800046ec:	4501                	li	a0,0
}
    800046ee:	70e2                	ld	ra,56(sp)
    800046f0:	7442                	ld	s0,48(sp)
    800046f2:	74a2                	ld	s1,40(sp)
    800046f4:	7902                	ld	s2,32(sp)
    800046f6:	69e2                	ld	s3,24(sp)
    800046f8:	6a42                	ld	s4,16(sp)
    800046fa:	6121                	add	sp,sp,64
    800046fc:	8082                	ret

00000000800046fe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800046fe:	711d                	add	sp,sp,-96
    80004700:	ec86                	sd	ra,88(sp)
    80004702:	e8a2                	sd	s0,80(sp)
    80004704:	e4a6                	sd	s1,72(sp)
    80004706:	e0ca                	sd	s2,64(sp)
    80004708:	fc4e                	sd	s3,56(sp)
    8000470a:	f852                	sd	s4,48(sp)
    8000470c:	f456                	sd	s5,40(sp)
    8000470e:	f05a                	sd	s6,32(sp)
    80004710:	ec5e                	sd	s7,24(sp)
    80004712:	e862                	sd	s8,16(sp)
    80004714:	e466                	sd	s9,8(sp)
    80004716:	1080                	add	s0,sp,96
    80004718:	84aa                	mv	s1,a0
    8000471a:	8b2e                	mv	s6,a1
    8000471c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000471e:	00054703          	lbu	a4,0(a0)
    80004722:	02f00793          	li	a5,47
    80004726:	02f70263          	beq	a4,a5,8000474a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000472a:	ffffd097          	auipc	ra,0xffffd
    8000472e:	364080e7          	jalr	868(ra) # 80001a8e <myproc>
    80004732:	15053503          	ld	a0,336(a0)
    80004736:	00000097          	auipc	ra,0x0
    8000473a:	9f6080e7          	jalr	-1546(ra) # 8000412c <idup>
    8000473e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004740:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004744:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004746:	4b85                	li	s7,1
    80004748:	a875                	j	80004804 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000474a:	4585                	li	a1,1
    8000474c:	4505                	li	a0,1
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	6e8080e7          	jalr	1768(ra) # 80003e36 <iget>
    80004756:	8a2a                	mv	s4,a0
    80004758:	b7e5                	j	80004740 <namex+0x42>
      iunlockput(ip);
    8000475a:	8552                	mv	a0,s4
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	c70080e7          	jalr	-912(ra) # 800043cc <iunlockput>
      return 0;
    80004764:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004766:	8552                	mv	a0,s4
    80004768:	60e6                	ld	ra,88(sp)
    8000476a:	6446                	ld	s0,80(sp)
    8000476c:	64a6                	ld	s1,72(sp)
    8000476e:	6906                	ld	s2,64(sp)
    80004770:	79e2                	ld	s3,56(sp)
    80004772:	7a42                	ld	s4,48(sp)
    80004774:	7aa2                	ld	s5,40(sp)
    80004776:	7b02                	ld	s6,32(sp)
    80004778:	6be2                	ld	s7,24(sp)
    8000477a:	6c42                	ld	s8,16(sp)
    8000477c:	6ca2                	ld	s9,8(sp)
    8000477e:	6125                	add	sp,sp,96
    80004780:	8082                	ret
      iunlock(ip);
    80004782:	8552                	mv	a0,s4
    80004784:	00000097          	auipc	ra,0x0
    80004788:	aa8080e7          	jalr	-1368(ra) # 8000422c <iunlock>
      return ip;
    8000478c:	bfe9                	j	80004766 <namex+0x68>
      iunlockput(ip);
    8000478e:	8552                	mv	a0,s4
    80004790:	00000097          	auipc	ra,0x0
    80004794:	c3c080e7          	jalr	-964(ra) # 800043cc <iunlockput>
      return 0;
    80004798:	8a4e                	mv	s4,s3
    8000479a:	b7f1                	j	80004766 <namex+0x68>
  len = path - s;
    8000479c:	40998633          	sub	a2,s3,s1
    800047a0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800047a4:	099c5863          	bge	s8,s9,80004834 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800047a8:	4639                	li	a2,14
    800047aa:	85a6                	mv	a1,s1
    800047ac:	8556                	mv	a0,s5
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	57c080e7          	jalr	1404(ra) # 80000d2a <memmove>
    800047b6:	84ce                	mv	s1,s3
  while(*path == '/')
    800047b8:	0004c783          	lbu	a5,0(s1)
    800047bc:	01279763          	bne	a5,s2,800047ca <namex+0xcc>
    path++;
    800047c0:	0485                	add	s1,s1,1
  while(*path == '/')
    800047c2:	0004c783          	lbu	a5,0(s1)
    800047c6:	ff278de3          	beq	a5,s2,800047c0 <namex+0xc2>
    ilock(ip);
    800047ca:	8552                	mv	a0,s4
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	99e080e7          	jalr	-1634(ra) # 8000416a <ilock>
    if(ip->type != T_DIR){
    800047d4:	044a1783          	lh	a5,68(s4)
    800047d8:	f97791e3          	bne	a5,s7,8000475a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800047dc:	000b0563          	beqz	s6,800047e6 <namex+0xe8>
    800047e0:	0004c783          	lbu	a5,0(s1)
    800047e4:	dfd9                	beqz	a5,80004782 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800047e6:	4601                	li	a2,0
    800047e8:	85d6                	mv	a1,s5
    800047ea:	8552                	mv	a0,s4
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	e62080e7          	jalr	-414(ra) # 8000464e <dirlookup>
    800047f4:	89aa                	mv	s3,a0
    800047f6:	dd41                	beqz	a0,8000478e <namex+0x90>
    iunlockput(ip);
    800047f8:	8552                	mv	a0,s4
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	bd2080e7          	jalr	-1070(ra) # 800043cc <iunlockput>
    ip = next;
    80004802:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004804:	0004c783          	lbu	a5,0(s1)
    80004808:	01279763          	bne	a5,s2,80004816 <namex+0x118>
    path++;
    8000480c:	0485                	add	s1,s1,1
  while(*path == '/')
    8000480e:	0004c783          	lbu	a5,0(s1)
    80004812:	ff278de3          	beq	a5,s2,8000480c <namex+0x10e>
  if(*path == 0)
    80004816:	cb9d                	beqz	a5,8000484c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004818:	0004c783          	lbu	a5,0(s1)
    8000481c:	89a6                	mv	s3,s1
  len = path - s;
    8000481e:	4c81                	li	s9,0
    80004820:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004822:	01278963          	beq	a5,s2,80004834 <namex+0x136>
    80004826:	dbbd                	beqz	a5,8000479c <namex+0x9e>
    path++;
    80004828:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000482a:	0009c783          	lbu	a5,0(s3)
    8000482e:	ff279ce3          	bne	a5,s2,80004826 <namex+0x128>
    80004832:	b7ad                	j	8000479c <namex+0x9e>
    memmove(name, s, len);
    80004834:	2601                	sext.w	a2,a2
    80004836:	85a6                	mv	a1,s1
    80004838:	8556                	mv	a0,s5
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	4f0080e7          	jalr	1264(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004842:	9cd6                	add	s9,s9,s5
    80004844:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004848:	84ce                	mv	s1,s3
    8000484a:	b7bd                	j	800047b8 <namex+0xba>
  if(nameiparent){
    8000484c:	f00b0de3          	beqz	s6,80004766 <namex+0x68>
    iput(ip);
    80004850:	8552                	mv	a0,s4
    80004852:	00000097          	auipc	ra,0x0
    80004856:	ad2080e7          	jalr	-1326(ra) # 80004324 <iput>
    return 0;
    8000485a:	4a01                	li	s4,0
    8000485c:	b729                	j	80004766 <namex+0x68>

000000008000485e <dirlink>:
{
    8000485e:	7139                	add	sp,sp,-64
    80004860:	fc06                	sd	ra,56(sp)
    80004862:	f822                	sd	s0,48(sp)
    80004864:	f426                	sd	s1,40(sp)
    80004866:	f04a                	sd	s2,32(sp)
    80004868:	ec4e                	sd	s3,24(sp)
    8000486a:	e852                	sd	s4,16(sp)
    8000486c:	0080                	add	s0,sp,64
    8000486e:	892a                	mv	s2,a0
    80004870:	8a2e                	mv	s4,a1
    80004872:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004874:	4601                	li	a2,0
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	dd8080e7          	jalr	-552(ra) # 8000464e <dirlookup>
    8000487e:	e93d                	bnez	a0,800048f4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004880:	04c92483          	lw	s1,76(s2)
    80004884:	c49d                	beqz	s1,800048b2 <dirlink+0x54>
    80004886:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004888:	4741                	li	a4,16
    8000488a:	86a6                	mv	a3,s1
    8000488c:	fc040613          	add	a2,s0,-64
    80004890:	4581                	li	a1,0
    80004892:	854a                	mv	a0,s2
    80004894:	00000097          	auipc	ra,0x0
    80004898:	b8a080e7          	jalr	-1142(ra) # 8000441e <readi>
    8000489c:	47c1                	li	a5,16
    8000489e:	06f51163          	bne	a0,a5,80004900 <dirlink+0xa2>
    if(de.inum == 0)
    800048a2:	fc045783          	lhu	a5,-64(s0)
    800048a6:	c791                	beqz	a5,800048b2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048a8:	24c1                	addw	s1,s1,16
    800048aa:	04c92783          	lw	a5,76(s2)
    800048ae:	fcf4ede3          	bltu	s1,a5,80004888 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800048b2:	4639                	li	a2,14
    800048b4:	85d2                	mv	a1,s4
    800048b6:	fc240513          	add	a0,s0,-62
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	520080e7          	jalr	1312(ra) # 80000dda <strncpy>
  de.inum = inum;
    800048c2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048c6:	4741                	li	a4,16
    800048c8:	86a6                	mv	a3,s1
    800048ca:	fc040613          	add	a2,s0,-64
    800048ce:	4581                	li	a1,0
    800048d0:	854a                	mv	a0,s2
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	c44080e7          	jalr	-956(ra) # 80004516 <writei>
    800048da:	1541                	add	a0,a0,-16
    800048dc:	00a03533          	snez	a0,a0
    800048e0:	40a00533          	neg	a0,a0
}
    800048e4:	70e2                	ld	ra,56(sp)
    800048e6:	7442                	ld	s0,48(sp)
    800048e8:	74a2                	ld	s1,40(sp)
    800048ea:	7902                	ld	s2,32(sp)
    800048ec:	69e2                	ld	s3,24(sp)
    800048ee:	6a42                	ld	s4,16(sp)
    800048f0:	6121                	add	sp,sp,64
    800048f2:	8082                	ret
    iput(ip);
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	a30080e7          	jalr	-1488(ra) # 80004324 <iput>
    return -1;
    800048fc:	557d                	li	a0,-1
    800048fe:	b7dd                	j	800048e4 <dirlink+0x86>
      panic("dirlink read");
    80004900:	00004517          	auipc	a0,0x4
    80004904:	db050513          	add	a0,a0,-592 # 800086b0 <syscalls+0x210>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	c34080e7          	jalr	-972(ra) # 8000053c <panic>

0000000080004910 <namei>:

struct inode*
namei(char *path)
{
    80004910:	1101                	add	sp,sp,-32
    80004912:	ec06                	sd	ra,24(sp)
    80004914:	e822                	sd	s0,16(sp)
    80004916:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004918:	fe040613          	add	a2,s0,-32
    8000491c:	4581                	li	a1,0
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	de0080e7          	jalr	-544(ra) # 800046fe <namex>
}
    80004926:	60e2                	ld	ra,24(sp)
    80004928:	6442                	ld	s0,16(sp)
    8000492a:	6105                	add	sp,sp,32
    8000492c:	8082                	ret

000000008000492e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000492e:	1141                	add	sp,sp,-16
    80004930:	e406                	sd	ra,8(sp)
    80004932:	e022                	sd	s0,0(sp)
    80004934:	0800                	add	s0,sp,16
    80004936:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004938:	4585                	li	a1,1
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	dc4080e7          	jalr	-572(ra) # 800046fe <namex>
}
    80004942:	60a2                	ld	ra,8(sp)
    80004944:	6402                	ld	s0,0(sp)
    80004946:	0141                	add	sp,sp,16
    80004948:	8082                	ret

000000008000494a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000494a:	1101                	add	sp,sp,-32
    8000494c:	ec06                	sd	ra,24(sp)
    8000494e:	e822                	sd	s0,16(sp)
    80004950:	e426                	sd	s1,8(sp)
    80004952:	e04a                	sd	s2,0(sp)
    80004954:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004956:	00020917          	auipc	s2,0x20
    8000495a:	45a90913          	add	s2,s2,1114 # 80024db0 <log>
    8000495e:	01892583          	lw	a1,24(s2)
    80004962:	02892503          	lw	a0,40(s2)
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	ff4080e7          	jalr	-12(ra) # 8000395a <bread>
    8000496e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004970:	02c92603          	lw	a2,44(s2)
    80004974:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004976:	00c05f63          	blez	a2,80004994 <write_head+0x4a>
    8000497a:	00020717          	auipc	a4,0x20
    8000497e:	46670713          	add	a4,a4,1126 # 80024de0 <log+0x30>
    80004982:	87aa                	mv	a5,a0
    80004984:	060a                	sll	a2,a2,0x2
    80004986:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004988:	4314                	lw	a3,0(a4)
    8000498a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000498c:	0711                	add	a4,a4,4
    8000498e:	0791                	add	a5,a5,4
    80004990:	fec79ce3          	bne	a5,a2,80004988 <write_head+0x3e>
  }
  bwrite(buf);
    80004994:	8526                	mv	a0,s1
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	0b6080e7          	jalr	182(ra) # 80003a4c <bwrite>
  brelse(buf);
    8000499e:	8526                	mv	a0,s1
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	0ea080e7          	jalr	234(ra) # 80003a8a <brelse>
}
    800049a8:	60e2                	ld	ra,24(sp)
    800049aa:	6442                	ld	s0,16(sp)
    800049ac:	64a2                	ld	s1,8(sp)
    800049ae:	6902                	ld	s2,0(sp)
    800049b0:	6105                	add	sp,sp,32
    800049b2:	8082                	ret

00000000800049b4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b4:	00020797          	auipc	a5,0x20
    800049b8:	4287a783          	lw	a5,1064(a5) # 80024ddc <log+0x2c>
    800049bc:	0af05d63          	blez	a5,80004a76 <install_trans+0xc2>
{
    800049c0:	7139                	add	sp,sp,-64
    800049c2:	fc06                	sd	ra,56(sp)
    800049c4:	f822                	sd	s0,48(sp)
    800049c6:	f426                	sd	s1,40(sp)
    800049c8:	f04a                	sd	s2,32(sp)
    800049ca:	ec4e                	sd	s3,24(sp)
    800049cc:	e852                	sd	s4,16(sp)
    800049ce:	e456                	sd	s5,8(sp)
    800049d0:	e05a                	sd	s6,0(sp)
    800049d2:	0080                	add	s0,sp,64
    800049d4:	8b2a                	mv	s6,a0
    800049d6:	00020a97          	auipc	s5,0x20
    800049da:	40aa8a93          	add	s5,s5,1034 # 80024de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049de:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049e0:	00020997          	auipc	s3,0x20
    800049e4:	3d098993          	add	s3,s3,976 # 80024db0 <log>
    800049e8:	a00d                	j	80004a0a <install_trans+0x56>
    brelse(lbuf);
    800049ea:	854a                	mv	a0,s2
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	09e080e7          	jalr	158(ra) # 80003a8a <brelse>
    brelse(dbuf);
    800049f4:	8526                	mv	a0,s1
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	094080e7          	jalr	148(ra) # 80003a8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fe:	2a05                	addw	s4,s4,1
    80004a00:	0a91                	add	s5,s5,4
    80004a02:	02c9a783          	lw	a5,44(s3)
    80004a06:	04fa5e63          	bge	s4,a5,80004a62 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a0a:	0189a583          	lw	a1,24(s3)
    80004a0e:	014585bb          	addw	a1,a1,s4
    80004a12:	2585                	addw	a1,a1,1
    80004a14:	0289a503          	lw	a0,40(s3)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	f42080e7          	jalr	-190(ra) # 8000395a <bread>
    80004a20:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a22:	000aa583          	lw	a1,0(s5)
    80004a26:	0289a503          	lw	a0,40(s3)
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	f30080e7          	jalr	-208(ra) # 8000395a <bread>
    80004a32:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a34:	40000613          	li	a2,1024
    80004a38:	05890593          	add	a1,s2,88
    80004a3c:	05850513          	add	a0,a0,88
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	2ea080e7          	jalr	746(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a48:	8526                	mv	a0,s1
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	002080e7          	jalr	2(ra) # 80003a4c <bwrite>
    if(recovering == 0)
    80004a52:	f80b1ce3          	bnez	s6,800049ea <install_trans+0x36>
      bunpin(dbuf);
    80004a56:	8526                	mv	a0,s1
    80004a58:	fffff097          	auipc	ra,0xfffff
    80004a5c:	10a080e7          	jalr	266(ra) # 80003b62 <bunpin>
    80004a60:	b769                	j	800049ea <install_trans+0x36>
}
    80004a62:	70e2                	ld	ra,56(sp)
    80004a64:	7442                	ld	s0,48(sp)
    80004a66:	74a2                	ld	s1,40(sp)
    80004a68:	7902                	ld	s2,32(sp)
    80004a6a:	69e2                	ld	s3,24(sp)
    80004a6c:	6a42                	ld	s4,16(sp)
    80004a6e:	6aa2                	ld	s5,8(sp)
    80004a70:	6b02                	ld	s6,0(sp)
    80004a72:	6121                	add	sp,sp,64
    80004a74:	8082                	ret
    80004a76:	8082                	ret

0000000080004a78 <initlog>:
{
    80004a78:	7179                	add	sp,sp,-48
    80004a7a:	f406                	sd	ra,40(sp)
    80004a7c:	f022                	sd	s0,32(sp)
    80004a7e:	ec26                	sd	s1,24(sp)
    80004a80:	e84a                	sd	s2,16(sp)
    80004a82:	e44e                	sd	s3,8(sp)
    80004a84:	1800                	add	s0,sp,48
    80004a86:	892a                	mv	s2,a0
    80004a88:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a8a:	00020497          	auipc	s1,0x20
    80004a8e:	32648493          	add	s1,s1,806 # 80024db0 <log>
    80004a92:	00004597          	auipc	a1,0x4
    80004a96:	c2e58593          	add	a1,a1,-978 # 800086c0 <syscalls+0x220>
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	0a6080e7          	jalr	166(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004aa4:	0149a583          	lw	a1,20(s3)
    80004aa8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004aaa:	0109a783          	lw	a5,16(s3)
    80004aae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004ab0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	ea4080e7          	jalr	-348(ra) # 8000395a <bread>
  log.lh.n = lh->n;
    80004abe:	4d30                	lw	a2,88(a0)
    80004ac0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004ac2:	00c05f63          	blez	a2,80004ae0 <initlog+0x68>
    80004ac6:	87aa                	mv	a5,a0
    80004ac8:	00020717          	auipc	a4,0x20
    80004acc:	31870713          	add	a4,a4,792 # 80024de0 <log+0x30>
    80004ad0:	060a                	sll	a2,a2,0x2
    80004ad2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004ad4:	4ff4                	lw	a3,92(a5)
    80004ad6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ad8:	0791                	add	a5,a5,4
    80004ada:	0711                	add	a4,a4,4
    80004adc:	fec79ce3          	bne	a5,a2,80004ad4 <initlog+0x5c>
  brelse(buf);
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	faa080e7          	jalr	-86(ra) # 80003a8a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004ae8:	4505                	li	a0,1
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	eca080e7          	jalr	-310(ra) # 800049b4 <install_trans>
  log.lh.n = 0;
    80004af2:	00020797          	auipc	a5,0x20
    80004af6:	2e07a523          	sw	zero,746(a5) # 80024ddc <log+0x2c>
  write_head(); // clear the log
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	e50080e7          	jalr	-432(ra) # 8000494a <write_head>
}
    80004b02:	70a2                	ld	ra,40(sp)
    80004b04:	7402                	ld	s0,32(sp)
    80004b06:	64e2                	ld	s1,24(sp)
    80004b08:	6942                	ld	s2,16(sp)
    80004b0a:	69a2                	ld	s3,8(sp)
    80004b0c:	6145                	add	sp,sp,48
    80004b0e:	8082                	ret

0000000080004b10 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b10:	1101                	add	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	e04a                	sd	s2,0(sp)
    80004b1a:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004b1c:	00020517          	auipc	a0,0x20
    80004b20:	29450513          	add	a0,a0,660 # 80024db0 <log>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	0ae080e7          	jalr	174(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004b2c:	00020497          	auipc	s1,0x20
    80004b30:	28448493          	add	s1,s1,644 # 80024db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b34:	4979                	li	s2,30
    80004b36:	a039                	j	80004b44 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b38:	85a6                	mv	a1,s1
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffe097          	auipc	ra,0xffffe
    80004b40:	c3e080e7          	jalr	-962(ra) # 8000277a <sleep>
    if(log.committing){
    80004b44:	50dc                	lw	a5,36(s1)
    80004b46:	fbed                	bnez	a5,80004b38 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b48:	5098                	lw	a4,32(s1)
    80004b4a:	2705                	addw	a4,a4,1
    80004b4c:	0027179b          	sllw	a5,a4,0x2
    80004b50:	9fb9                	addw	a5,a5,a4
    80004b52:	0017979b          	sllw	a5,a5,0x1
    80004b56:	54d4                	lw	a3,44(s1)
    80004b58:	9fb5                	addw	a5,a5,a3
    80004b5a:	00f95963          	bge	s2,a5,80004b6c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b5e:	85a6                	mv	a1,s1
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffe097          	auipc	ra,0xffffe
    80004b66:	c18080e7          	jalr	-1000(ra) # 8000277a <sleep>
    80004b6a:	bfe9                	j	80004b44 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b6c:	00020517          	auipc	a0,0x20
    80004b70:	24450513          	add	a0,a0,580 # 80024db0 <log>
    80004b74:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	110080e7          	jalr	272(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6902                	ld	s2,0(sp)
    80004b86:	6105                	add	sp,sp,32
    80004b88:	8082                	ret

0000000080004b8a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b8a:	7139                	add	sp,sp,-64
    80004b8c:	fc06                	sd	ra,56(sp)
    80004b8e:	f822                	sd	s0,48(sp)
    80004b90:	f426                	sd	s1,40(sp)
    80004b92:	f04a                	sd	s2,32(sp)
    80004b94:	ec4e                	sd	s3,24(sp)
    80004b96:	e852                	sd	s4,16(sp)
    80004b98:	e456                	sd	s5,8(sp)
    80004b9a:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b9c:	00020497          	auipc	s1,0x20
    80004ba0:	21448493          	add	s1,s1,532 # 80024db0 <log>
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	02c080e7          	jalr	44(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004bae:	509c                	lw	a5,32(s1)
    80004bb0:	37fd                	addw	a5,a5,-1
    80004bb2:	0007891b          	sext.w	s2,a5
    80004bb6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004bb8:	50dc                	lw	a5,36(s1)
    80004bba:	e7b9                	bnez	a5,80004c08 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004bbc:	04091e63          	bnez	s2,80004c18 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004bc0:	00020497          	auipc	s1,0x20
    80004bc4:	1f048493          	add	s1,s1,496 # 80024db0 <log>
    80004bc8:	4785                	li	a5,1
    80004bca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	0b8080e7          	jalr	184(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004bd6:	54dc                	lw	a5,44(s1)
    80004bd8:	06f04763          	bgtz	a5,80004c46 <end_op+0xbc>
    acquire(&log.lock);
    80004bdc:	00020497          	auipc	s1,0x20
    80004be0:	1d448493          	add	s1,s1,468 # 80024db0 <log>
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	fec080e7          	jalr	-20(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004bee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffe097          	auipc	ra,0xffffe
    80004bf8:	bea080e7          	jalr	-1046(ra) # 800027de <wakeup>
    release(&log.lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	088080e7          	jalr	136(ra) # 80000c86 <release>
}
    80004c06:	a03d                	j	80004c34 <end_op+0xaa>
    panic("log.committing");
    80004c08:	00004517          	auipc	a0,0x4
    80004c0c:	ac050513          	add	a0,a0,-1344 # 800086c8 <syscalls+0x228>
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	92c080e7          	jalr	-1748(ra) # 8000053c <panic>
    wakeup(&log);
    80004c18:	00020497          	auipc	s1,0x20
    80004c1c:	19848493          	add	s1,s1,408 # 80024db0 <log>
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffe097          	auipc	ra,0xffffe
    80004c26:	bbc080e7          	jalr	-1092(ra) # 800027de <wakeup>
  release(&log.lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	05a080e7          	jalr	90(ra) # 80000c86 <release>
}
    80004c34:	70e2                	ld	ra,56(sp)
    80004c36:	7442                	ld	s0,48(sp)
    80004c38:	74a2                	ld	s1,40(sp)
    80004c3a:	7902                	ld	s2,32(sp)
    80004c3c:	69e2                	ld	s3,24(sp)
    80004c3e:	6a42                	ld	s4,16(sp)
    80004c40:	6aa2                	ld	s5,8(sp)
    80004c42:	6121                	add	sp,sp,64
    80004c44:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c46:	00020a97          	auipc	s5,0x20
    80004c4a:	19aa8a93          	add	s5,s5,410 # 80024de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c4e:	00020a17          	auipc	s4,0x20
    80004c52:	162a0a13          	add	s4,s4,354 # 80024db0 <log>
    80004c56:	018a2583          	lw	a1,24(s4)
    80004c5a:	012585bb          	addw	a1,a1,s2
    80004c5e:	2585                	addw	a1,a1,1
    80004c60:	028a2503          	lw	a0,40(s4)
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	cf6080e7          	jalr	-778(ra) # 8000395a <bread>
    80004c6c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c6e:	000aa583          	lw	a1,0(s5)
    80004c72:	028a2503          	lw	a0,40(s4)
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	ce4080e7          	jalr	-796(ra) # 8000395a <bread>
    80004c7e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c80:	40000613          	li	a2,1024
    80004c84:	05850593          	add	a1,a0,88
    80004c88:	05848513          	add	a0,s1,88
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	09e080e7          	jalr	158(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004c94:	8526                	mv	a0,s1
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	db6080e7          	jalr	-586(ra) # 80003a4c <bwrite>
    brelse(from);
    80004c9e:	854e                	mv	a0,s3
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	dea080e7          	jalr	-534(ra) # 80003a8a <brelse>
    brelse(to);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	de0080e7          	jalr	-544(ra) # 80003a8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cb2:	2905                	addw	s2,s2,1
    80004cb4:	0a91                	add	s5,s5,4
    80004cb6:	02ca2783          	lw	a5,44(s4)
    80004cba:	f8f94ee3          	blt	s2,a5,80004c56 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004cbe:	00000097          	auipc	ra,0x0
    80004cc2:	c8c080e7          	jalr	-884(ra) # 8000494a <write_head>
    install_trans(0); // Now install writes to home locations
    80004cc6:	4501                	li	a0,0
    80004cc8:	00000097          	auipc	ra,0x0
    80004ccc:	cec080e7          	jalr	-788(ra) # 800049b4 <install_trans>
    log.lh.n = 0;
    80004cd0:	00020797          	auipc	a5,0x20
    80004cd4:	1007a623          	sw	zero,268(a5) # 80024ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004cd8:	00000097          	auipc	ra,0x0
    80004cdc:	c72080e7          	jalr	-910(ra) # 8000494a <write_head>
    80004ce0:	bdf5                	j	80004bdc <end_op+0x52>

0000000080004ce2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ce2:	1101                	add	sp,sp,-32
    80004ce4:	ec06                	sd	ra,24(sp)
    80004ce6:	e822                	sd	s0,16(sp)
    80004ce8:	e426                	sd	s1,8(sp)
    80004cea:	e04a                	sd	s2,0(sp)
    80004cec:	1000                	add	s0,sp,32
    80004cee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004cf0:	00020917          	auipc	s2,0x20
    80004cf4:	0c090913          	add	s2,s2,192 # 80024db0 <log>
    80004cf8:	854a                	mv	a0,s2
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	ed8080e7          	jalr	-296(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d02:	02c92603          	lw	a2,44(s2)
    80004d06:	47f5                	li	a5,29
    80004d08:	06c7c563          	blt	a5,a2,80004d72 <log_write+0x90>
    80004d0c:	00020797          	auipc	a5,0x20
    80004d10:	0c07a783          	lw	a5,192(a5) # 80024dcc <log+0x1c>
    80004d14:	37fd                	addw	a5,a5,-1
    80004d16:	04f65e63          	bge	a2,a5,80004d72 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d1a:	00020797          	auipc	a5,0x20
    80004d1e:	0b67a783          	lw	a5,182(a5) # 80024dd0 <log+0x20>
    80004d22:	06f05063          	blez	a5,80004d82 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d26:	4781                	li	a5,0
    80004d28:	06c05563          	blez	a2,80004d92 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d2c:	44cc                	lw	a1,12(s1)
    80004d2e:	00020717          	auipc	a4,0x20
    80004d32:	0b270713          	add	a4,a4,178 # 80024de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d36:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d38:	4314                	lw	a3,0(a4)
    80004d3a:	04b68c63          	beq	a3,a1,80004d92 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d3e:	2785                	addw	a5,a5,1
    80004d40:	0711                	add	a4,a4,4
    80004d42:	fef61be3          	bne	a2,a5,80004d38 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d46:	0621                	add	a2,a2,8
    80004d48:	060a                	sll	a2,a2,0x2
    80004d4a:	00020797          	auipc	a5,0x20
    80004d4e:	06678793          	add	a5,a5,102 # 80024db0 <log>
    80004d52:	97b2                	add	a5,a5,a2
    80004d54:	44d8                	lw	a4,12(s1)
    80004d56:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d58:	8526                	mv	a0,s1
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	dcc080e7          	jalr	-564(ra) # 80003b26 <bpin>
    log.lh.n++;
    80004d62:	00020717          	auipc	a4,0x20
    80004d66:	04e70713          	add	a4,a4,78 # 80024db0 <log>
    80004d6a:	575c                	lw	a5,44(a4)
    80004d6c:	2785                	addw	a5,a5,1
    80004d6e:	d75c                	sw	a5,44(a4)
    80004d70:	a82d                	j	80004daa <log_write+0xc8>
    panic("too big a transaction");
    80004d72:	00004517          	auipc	a0,0x4
    80004d76:	96650513          	add	a0,a0,-1690 # 800086d8 <syscalls+0x238>
    80004d7a:	ffffb097          	auipc	ra,0xffffb
    80004d7e:	7c2080e7          	jalr	1986(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004d82:	00004517          	auipc	a0,0x4
    80004d86:	96e50513          	add	a0,a0,-1682 # 800086f0 <syscalls+0x250>
    80004d8a:	ffffb097          	auipc	ra,0xffffb
    80004d8e:	7b2080e7          	jalr	1970(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004d92:	00878693          	add	a3,a5,8
    80004d96:	068a                	sll	a3,a3,0x2
    80004d98:	00020717          	auipc	a4,0x20
    80004d9c:	01870713          	add	a4,a4,24 # 80024db0 <log>
    80004da0:	9736                	add	a4,a4,a3
    80004da2:	44d4                	lw	a3,12(s1)
    80004da4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004da6:	faf609e3          	beq	a2,a5,80004d58 <log_write+0x76>
  }
  release(&log.lock);
    80004daa:	00020517          	auipc	a0,0x20
    80004dae:	00650513          	add	a0,a0,6 # 80024db0 <log>
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	ed4080e7          	jalr	-300(ra) # 80000c86 <release>
}
    80004dba:	60e2                	ld	ra,24(sp)
    80004dbc:	6442                	ld	s0,16(sp)
    80004dbe:	64a2                	ld	s1,8(sp)
    80004dc0:	6902                	ld	s2,0(sp)
    80004dc2:	6105                	add	sp,sp,32
    80004dc4:	8082                	ret

0000000080004dc6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004dc6:	1101                	add	sp,sp,-32
    80004dc8:	ec06                	sd	ra,24(sp)
    80004dca:	e822                	sd	s0,16(sp)
    80004dcc:	e426                	sd	s1,8(sp)
    80004dce:	e04a                	sd	s2,0(sp)
    80004dd0:	1000                	add	s0,sp,32
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004dd6:	00004597          	auipc	a1,0x4
    80004dda:	93a58593          	add	a1,a1,-1734 # 80008710 <syscalls+0x270>
    80004dde:	0521                	add	a0,a0,8
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	d62080e7          	jalr	-670(ra) # 80000b42 <initlock>
  lk->name = name;
    80004de8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004dec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004df0:	0204a423          	sw	zero,40(s1)
}
    80004df4:	60e2                	ld	ra,24(sp)
    80004df6:	6442                	ld	s0,16(sp)
    80004df8:	64a2                	ld	s1,8(sp)
    80004dfa:	6902                	ld	s2,0(sp)
    80004dfc:	6105                	add	sp,sp,32
    80004dfe:	8082                	ret

0000000080004e00 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e00:	1101                	add	sp,sp,-32
    80004e02:	ec06                	sd	ra,24(sp)
    80004e04:	e822                	sd	s0,16(sp)
    80004e06:	e426                	sd	s1,8(sp)
    80004e08:	e04a                	sd	s2,0(sp)
    80004e0a:	1000                	add	s0,sp,32
    80004e0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e0e:	00850913          	add	s2,a0,8
    80004e12:	854a                	mv	a0,s2
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	dbe080e7          	jalr	-578(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004e1c:	409c                	lw	a5,0(s1)
    80004e1e:	cb89                	beqz	a5,80004e30 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e20:	85ca                	mv	a1,s2
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffe097          	auipc	ra,0xffffe
    80004e28:	956080e7          	jalr	-1706(ra) # 8000277a <sleep>
  while (lk->locked) {
    80004e2c:	409c                	lw	a5,0(s1)
    80004e2e:	fbed                	bnez	a5,80004e20 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e30:	4785                	li	a5,1
    80004e32:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	c5a080e7          	jalr	-934(ra) # 80001a8e <myproc>
    80004e3c:	591c                	lw	a5,48(a0)
    80004e3e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e40:	854a                	mv	a0,s2
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	e44080e7          	jalr	-444(ra) # 80000c86 <release>
}
    80004e4a:	60e2                	ld	ra,24(sp)
    80004e4c:	6442                	ld	s0,16(sp)
    80004e4e:	64a2                	ld	s1,8(sp)
    80004e50:	6902                	ld	s2,0(sp)
    80004e52:	6105                	add	sp,sp,32
    80004e54:	8082                	ret

0000000080004e56 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e56:	1101                	add	sp,sp,-32
    80004e58:	ec06                	sd	ra,24(sp)
    80004e5a:	e822                	sd	s0,16(sp)
    80004e5c:	e426                	sd	s1,8(sp)
    80004e5e:	e04a                	sd	s2,0(sp)
    80004e60:	1000                	add	s0,sp,32
    80004e62:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e64:	00850913          	add	s2,a0,8
    80004e68:	854a                	mv	a0,s2
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	d68080e7          	jalr	-664(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004e72:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e76:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffe097          	auipc	ra,0xffffe
    80004e80:	962080e7          	jalr	-1694(ra) # 800027de <wakeup>
  release(&lk->lk);
    80004e84:	854a                	mv	a0,s2
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	e00080e7          	jalr	-512(ra) # 80000c86 <release>
}
    80004e8e:	60e2                	ld	ra,24(sp)
    80004e90:	6442                	ld	s0,16(sp)
    80004e92:	64a2                	ld	s1,8(sp)
    80004e94:	6902                	ld	s2,0(sp)
    80004e96:	6105                	add	sp,sp,32
    80004e98:	8082                	ret

0000000080004e9a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e9a:	7179                	add	sp,sp,-48
    80004e9c:	f406                	sd	ra,40(sp)
    80004e9e:	f022                	sd	s0,32(sp)
    80004ea0:	ec26                	sd	s1,24(sp)
    80004ea2:	e84a                	sd	s2,16(sp)
    80004ea4:	e44e                	sd	s3,8(sp)
    80004ea6:	1800                	add	s0,sp,48
    80004ea8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004eaa:	00850913          	add	s2,a0,8
    80004eae:	854a                	mv	a0,s2
    80004eb0:	ffffc097          	auipc	ra,0xffffc
    80004eb4:	d22080e7          	jalr	-734(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004eb8:	409c                	lw	a5,0(s1)
    80004eba:	ef99                	bnez	a5,80004ed8 <holdingsleep+0x3e>
    80004ebc:	4481                	li	s1,0
  release(&lk->lk);
    80004ebe:	854a                	mv	a0,s2
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	dc6080e7          	jalr	-570(ra) # 80000c86 <release>
  return r;
}
    80004ec8:	8526                	mv	a0,s1
    80004eca:	70a2                	ld	ra,40(sp)
    80004ecc:	7402                	ld	s0,32(sp)
    80004ece:	64e2                	ld	s1,24(sp)
    80004ed0:	6942                	ld	s2,16(sp)
    80004ed2:	69a2                	ld	s3,8(sp)
    80004ed4:	6145                	add	sp,sp,48
    80004ed6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ed8:	0284a983          	lw	s3,40(s1)
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	bb2080e7          	jalr	-1102(ra) # 80001a8e <myproc>
    80004ee4:	5904                	lw	s1,48(a0)
    80004ee6:	413484b3          	sub	s1,s1,s3
    80004eea:	0014b493          	seqz	s1,s1
    80004eee:	bfc1                	j	80004ebe <holdingsleep+0x24>

0000000080004ef0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ef0:	1141                	add	sp,sp,-16
    80004ef2:	e406                	sd	ra,8(sp)
    80004ef4:	e022                	sd	s0,0(sp)
    80004ef6:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ef8:	00004597          	auipc	a1,0x4
    80004efc:	82858593          	add	a1,a1,-2008 # 80008720 <syscalls+0x280>
    80004f00:	00020517          	auipc	a0,0x20
    80004f04:	ff850513          	add	a0,a0,-8 # 80024ef8 <ftable>
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	c3a080e7          	jalr	-966(ra) # 80000b42 <initlock>
}
    80004f10:	60a2                	ld	ra,8(sp)
    80004f12:	6402                	ld	s0,0(sp)
    80004f14:	0141                	add	sp,sp,16
    80004f16:	8082                	ret

0000000080004f18 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f18:	1101                	add	sp,sp,-32
    80004f1a:	ec06                	sd	ra,24(sp)
    80004f1c:	e822                	sd	s0,16(sp)
    80004f1e:	e426                	sd	s1,8(sp)
    80004f20:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f22:	00020517          	auipc	a0,0x20
    80004f26:	fd650513          	add	a0,a0,-42 # 80024ef8 <ftable>
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	ca8080e7          	jalr	-856(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f32:	00020497          	auipc	s1,0x20
    80004f36:	fde48493          	add	s1,s1,-34 # 80024f10 <ftable+0x18>
    80004f3a:	00021717          	auipc	a4,0x21
    80004f3e:	f7670713          	add	a4,a4,-138 # 80025eb0 <disk>
    if(f->ref == 0){
    80004f42:	40dc                	lw	a5,4(s1)
    80004f44:	cf99                	beqz	a5,80004f62 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f46:	02848493          	add	s1,s1,40
    80004f4a:	fee49ce3          	bne	s1,a4,80004f42 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f4e:	00020517          	auipc	a0,0x20
    80004f52:	faa50513          	add	a0,a0,-86 # 80024ef8 <ftable>
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	d30080e7          	jalr	-720(ra) # 80000c86 <release>
  return 0;
    80004f5e:	4481                	li	s1,0
    80004f60:	a819                	j	80004f76 <filealloc+0x5e>
      f->ref = 1;
    80004f62:	4785                	li	a5,1
    80004f64:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f66:	00020517          	auipc	a0,0x20
    80004f6a:	f9250513          	add	a0,a0,-110 # 80024ef8 <ftable>
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	d18080e7          	jalr	-744(ra) # 80000c86 <release>
}
    80004f76:	8526                	mv	a0,s1
    80004f78:	60e2                	ld	ra,24(sp)
    80004f7a:	6442                	ld	s0,16(sp)
    80004f7c:	64a2                	ld	s1,8(sp)
    80004f7e:	6105                	add	sp,sp,32
    80004f80:	8082                	ret

0000000080004f82 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f82:	1101                	add	sp,sp,-32
    80004f84:	ec06                	sd	ra,24(sp)
    80004f86:	e822                	sd	s0,16(sp)
    80004f88:	e426                	sd	s1,8(sp)
    80004f8a:	1000                	add	s0,sp,32
    80004f8c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f8e:	00020517          	auipc	a0,0x20
    80004f92:	f6a50513          	add	a0,a0,-150 # 80024ef8 <ftable>
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	c3c080e7          	jalr	-964(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004f9e:	40dc                	lw	a5,4(s1)
    80004fa0:	02f05263          	blez	a5,80004fc4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004fa4:	2785                	addw	a5,a5,1
    80004fa6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004fa8:	00020517          	auipc	a0,0x20
    80004fac:	f5050513          	add	a0,a0,-176 # 80024ef8 <ftable>
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	cd6080e7          	jalr	-810(ra) # 80000c86 <release>
  return f;
}
    80004fb8:	8526                	mv	a0,s1
    80004fba:	60e2                	ld	ra,24(sp)
    80004fbc:	6442                	ld	s0,16(sp)
    80004fbe:	64a2                	ld	s1,8(sp)
    80004fc0:	6105                	add	sp,sp,32
    80004fc2:	8082                	ret
    panic("filedup");
    80004fc4:	00003517          	auipc	a0,0x3
    80004fc8:	76450513          	add	a0,a0,1892 # 80008728 <syscalls+0x288>
    80004fcc:	ffffb097          	auipc	ra,0xffffb
    80004fd0:	570080e7          	jalr	1392(ra) # 8000053c <panic>

0000000080004fd4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004fd4:	7139                	add	sp,sp,-64
    80004fd6:	fc06                	sd	ra,56(sp)
    80004fd8:	f822                	sd	s0,48(sp)
    80004fda:	f426                	sd	s1,40(sp)
    80004fdc:	f04a                	sd	s2,32(sp)
    80004fde:	ec4e                	sd	s3,24(sp)
    80004fe0:	e852                	sd	s4,16(sp)
    80004fe2:	e456                	sd	s5,8(sp)
    80004fe4:	0080                	add	s0,sp,64
    80004fe6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004fe8:	00020517          	auipc	a0,0x20
    80004fec:	f1050513          	add	a0,a0,-240 # 80024ef8 <ftable>
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	be2080e7          	jalr	-1054(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004ff8:	40dc                	lw	a5,4(s1)
    80004ffa:	06f05163          	blez	a5,8000505c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ffe:	37fd                	addw	a5,a5,-1
    80005000:	0007871b          	sext.w	a4,a5
    80005004:	c0dc                	sw	a5,4(s1)
    80005006:	06e04363          	bgtz	a4,8000506c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000500a:	0004a903          	lw	s2,0(s1)
    8000500e:	0094ca83          	lbu	s5,9(s1)
    80005012:	0104ba03          	ld	s4,16(s1)
    80005016:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000501a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000501e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005022:	00020517          	auipc	a0,0x20
    80005026:	ed650513          	add	a0,a0,-298 # 80024ef8 <ftable>
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	c5c080e7          	jalr	-932(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80005032:	4785                	li	a5,1
    80005034:	04f90d63          	beq	s2,a5,8000508e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005038:	3979                	addw	s2,s2,-2
    8000503a:	4785                	li	a5,1
    8000503c:	0527e063          	bltu	a5,s2,8000507c <fileclose+0xa8>
    begin_op();
    80005040:	00000097          	auipc	ra,0x0
    80005044:	ad0080e7          	jalr	-1328(ra) # 80004b10 <begin_op>
    iput(ff.ip);
    80005048:	854e                	mv	a0,s3
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	2da080e7          	jalr	730(ra) # 80004324 <iput>
    end_op();
    80005052:	00000097          	auipc	ra,0x0
    80005056:	b38080e7          	jalr	-1224(ra) # 80004b8a <end_op>
    8000505a:	a00d                	j	8000507c <fileclose+0xa8>
    panic("fileclose");
    8000505c:	00003517          	auipc	a0,0x3
    80005060:	6d450513          	add	a0,a0,1748 # 80008730 <syscalls+0x290>
    80005064:	ffffb097          	auipc	ra,0xffffb
    80005068:	4d8080e7          	jalr	1240(ra) # 8000053c <panic>
    release(&ftable.lock);
    8000506c:	00020517          	auipc	a0,0x20
    80005070:	e8c50513          	add	a0,a0,-372 # 80024ef8 <ftable>
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	c12080e7          	jalr	-1006(ra) # 80000c86 <release>
  }
}
    8000507c:	70e2                	ld	ra,56(sp)
    8000507e:	7442                	ld	s0,48(sp)
    80005080:	74a2                	ld	s1,40(sp)
    80005082:	7902                	ld	s2,32(sp)
    80005084:	69e2                	ld	s3,24(sp)
    80005086:	6a42                	ld	s4,16(sp)
    80005088:	6aa2                	ld	s5,8(sp)
    8000508a:	6121                	add	sp,sp,64
    8000508c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000508e:	85d6                	mv	a1,s5
    80005090:	8552                	mv	a0,s4
    80005092:	00000097          	auipc	ra,0x0
    80005096:	348080e7          	jalr	840(ra) # 800053da <pipeclose>
    8000509a:	b7cd                	j	8000507c <fileclose+0xa8>

000000008000509c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000509c:	715d                	add	sp,sp,-80
    8000509e:	e486                	sd	ra,72(sp)
    800050a0:	e0a2                	sd	s0,64(sp)
    800050a2:	fc26                	sd	s1,56(sp)
    800050a4:	f84a                	sd	s2,48(sp)
    800050a6:	f44e                	sd	s3,40(sp)
    800050a8:	0880                	add	s0,sp,80
    800050aa:	84aa                	mv	s1,a0
    800050ac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	9e0080e7          	jalr	-1568(ra) # 80001a8e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800050b6:	409c                	lw	a5,0(s1)
    800050b8:	37f9                	addw	a5,a5,-2
    800050ba:	4705                	li	a4,1
    800050bc:	04f76763          	bltu	a4,a5,8000510a <filestat+0x6e>
    800050c0:	892a                	mv	s2,a0
    ilock(f->ip);
    800050c2:	6c88                	ld	a0,24(s1)
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	0a6080e7          	jalr	166(ra) # 8000416a <ilock>
    stati(f->ip, &st);
    800050cc:	fb840593          	add	a1,s0,-72
    800050d0:	6c88                	ld	a0,24(s1)
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	322080e7          	jalr	802(ra) # 800043f4 <stati>
    iunlock(f->ip);
    800050da:	6c88                	ld	a0,24(s1)
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	150080e7          	jalr	336(ra) # 8000422c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800050e4:	46e1                	li	a3,24
    800050e6:	fb840613          	add	a2,s0,-72
    800050ea:	85ce                	mv	a1,s3
    800050ec:	05093503          	ld	a0,80(s2)
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	576080e7          	jalr	1398(ra) # 80001666 <copyout>
    800050f8:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800050fc:	60a6                	ld	ra,72(sp)
    800050fe:	6406                	ld	s0,64(sp)
    80005100:	74e2                	ld	s1,56(sp)
    80005102:	7942                	ld	s2,48(sp)
    80005104:	79a2                	ld	s3,40(sp)
    80005106:	6161                	add	sp,sp,80
    80005108:	8082                	ret
  return -1;
    8000510a:	557d                	li	a0,-1
    8000510c:	bfc5                	j	800050fc <filestat+0x60>

000000008000510e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000510e:	7179                	add	sp,sp,-48
    80005110:	f406                	sd	ra,40(sp)
    80005112:	f022                	sd	s0,32(sp)
    80005114:	ec26                	sd	s1,24(sp)
    80005116:	e84a                	sd	s2,16(sp)
    80005118:	e44e                	sd	s3,8(sp)
    8000511a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000511c:	00854783          	lbu	a5,8(a0)
    80005120:	c3d5                	beqz	a5,800051c4 <fileread+0xb6>
    80005122:	84aa                	mv	s1,a0
    80005124:	89ae                	mv	s3,a1
    80005126:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005128:	411c                	lw	a5,0(a0)
    8000512a:	4705                	li	a4,1
    8000512c:	04e78963          	beq	a5,a4,8000517e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005130:	470d                	li	a4,3
    80005132:	04e78d63          	beq	a5,a4,8000518c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005136:	4709                	li	a4,2
    80005138:	06e79e63          	bne	a5,a4,800051b4 <fileread+0xa6>
    ilock(f->ip);
    8000513c:	6d08                	ld	a0,24(a0)
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	02c080e7          	jalr	44(ra) # 8000416a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005146:	874a                	mv	a4,s2
    80005148:	5094                	lw	a3,32(s1)
    8000514a:	864e                	mv	a2,s3
    8000514c:	4585                	li	a1,1
    8000514e:	6c88                	ld	a0,24(s1)
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	2ce080e7          	jalr	718(ra) # 8000441e <readi>
    80005158:	892a                	mv	s2,a0
    8000515a:	00a05563          	blez	a0,80005164 <fileread+0x56>
      f->off += r;
    8000515e:	509c                	lw	a5,32(s1)
    80005160:	9fa9                	addw	a5,a5,a0
    80005162:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005164:	6c88                	ld	a0,24(s1)
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	0c6080e7          	jalr	198(ra) # 8000422c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000516e:	854a                	mv	a0,s2
    80005170:	70a2                	ld	ra,40(sp)
    80005172:	7402                	ld	s0,32(sp)
    80005174:	64e2                	ld	s1,24(sp)
    80005176:	6942                	ld	s2,16(sp)
    80005178:	69a2                	ld	s3,8(sp)
    8000517a:	6145                	add	sp,sp,48
    8000517c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000517e:	6908                	ld	a0,16(a0)
    80005180:	00000097          	auipc	ra,0x0
    80005184:	3c2080e7          	jalr	962(ra) # 80005542 <piperead>
    80005188:	892a                	mv	s2,a0
    8000518a:	b7d5                	j	8000516e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000518c:	02451783          	lh	a5,36(a0)
    80005190:	03079693          	sll	a3,a5,0x30
    80005194:	92c1                	srl	a3,a3,0x30
    80005196:	4725                	li	a4,9
    80005198:	02d76863          	bltu	a4,a3,800051c8 <fileread+0xba>
    8000519c:	0792                	sll	a5,a5,0x4
    8000519e:	00020717          	auipc	a4,0x20
    800051a2:	cba70713          	add	a4,a4,-838 # 80024e58 <devsw>
    800051a6:	97ba                	add	a5,a5,a4
    800051a8:	639c                	ld	a5,0(a5)
    800051aa:	c38d                	beqz	a5,800051cc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051ac:	4505                	li	a0,1
    800051ae:	9782                	jalr	a5
    800051b0:	892a                	mv	s2,a0
    800051b2:	bf75                	j	8000516e <fileread+0x60>
    panic("fileread");
    800051b4:	00003517          	auipc	a0,0x3
    800051b8:	58c50513          	add	a0,a0,1420 # 80008740 <syscalls+0x2a0>
    800051bc:	ffffb097          	auipc	ra,0xffffb
    800051c0:	380080e7          	jalr	896(ra) # 8000053c <panic>
    return -1;
    800051c4:	597d                	li	s2,-1
    800051c6:	b765                	j	8000516e <fileread+0x60>
      return -1;
    800051c8:	597d                	li	s2,-1
    800051ca:	b755                	j	8000516e <fileread+0x60>
    800051cc:	597d                	li	s2,-1
    800051ce:	b745                	j	8000516e <fileread+0x60>

00000000800051d0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800051d0:	00954783          	lbu	a5,9(a0)
    800051d4:	10078e63          	beqz	a5,800052f0 <filewrite+0x120>
{
    800051d8:	715d                	add	sp,sp,-80
    800051da:	e486                	sd	ra,72(sp)
    800051dc:	e0a2                	sd	s0,64(sp)
    800051de:	fc26                	sd	s1,56(sp)
    800051e0:	f84a                	sd	s2,48(sp)
    800051e2:	f44e                	sd	s3,40(sp)
    800051e4:	f052                	sd	s4,32(sp)
    800051e6:	ec56                	sd	s5,24(sp)
    800051e8:	e85a                	sd	s6,16(sp)
    800051ea:	e45e                	sd	s7,8(sp)
    800051ec:	e062                	sd	s8,0(sp)
    800051ee:	0880                	add	s0,sp,80
    800051f0:	892a                	mv	s2,a0
    800051f2:	8b2e                	mv	s6,a1
    800051f4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800051f6:	411c                	lw	a5,0(a0)
    800051f8:	4705                	li	a4,1
    800051fa:	02e78263          	beq	a5,a4,8000521e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051fe:	470d                	li	a4,3
    80005200:	02e78563          	beq	a5,a4,8000522a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005204:	4709                	li	a4,2
    80005206:	0ce79d63          	bne	a5,a4,800052e0 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000520a:	0ac05b63          	blez	a2,800052c0 <filewrite+0xf0>
    int i = 0;
    8000520e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80005210:	6b85                	lui	s7,0x1
    80005212:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005216:	6c05                	lui	s8,0x1
    80005218:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000521c:	a851                	j	800052b0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000521e:	6908                	ld	a0,16(a0)
    80005220:	00000097          	auipc	ra,0x0
    80005224:	22a080e7          	jalr	554(ra) # 8000544a <pipewrite>
    80005228:	a045                	j	800052c8 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000522a:	02451783          	lh	a5,36(a0)
    8000522e:	03079693          	sll	a3,a5,0x30
    80005232:	92c1                	srl	a3,a3,0x30
    80005234:	4725                	li	a4,9
    80005236:	0ad76f63          	bltu	a4,a3,800052f4 <filewrite+0x124>
    8000523a:	0792                	sll	a5,a5,0x4
    8000523c:	00020717          	auipc	a4,0x20
    80005240:	c1c70713          	add	a4,a4,-996 # 80024e58 <devsw>
    80005244:	97ba                	add	a5,a5,a4
    80005246:	679c                	ld	a5,8(a5)
    80005248:	cbc5                	beqz	a5,800052f8 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    8000524a:	4505                	li	a0,1
    8000524c:	9782                	jalr	a5
    8000524e:	a8ad                	j	800052c8 <filewrite+0xf8>
      if(n1 > max)
    80005250:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80005254:	00000097          	auipc	ra,0x0
    80005258:	8bc080e7          	jalr	-1860(ra) # 80004b10 <begin_op>
      ilock(f->ip);
    8000525c:	01893503          	ld	a0,24(s2)
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	f0a080e7          	jalr	-246(ra) # 8000416a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005268:	8756                	mv	a4,s5
    8000526a:	02092683          	lw	a3,32(s2)
    8000526e:	01698633          	add	a2,s3,s6
    80005272:	4585                	li	a1,1
    80005274:	01893503          	ld	a0,24(s2)
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	29e080e7          	jalr	670(ra) # 80004516 <writei>
    80005280:	84aa                	mv	s1,a0
    80005282:	00a05763          	blez	a0,80005290 <filewrite+0xc0>
        f->off += r;
    80005286:	02092783          	lw	a5,32(s2)
    8000528a:	9fa9                	addw	a5,a5,a0
    8000528c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005290:	01893503          	ld	a0,24(s2)
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	f98080e7          	jalr	-104(ra) # 8000422c <iunlock>
      end_op();
    8000529c:	00000097          	auipc	ra,0x0
    800052a0:	8ee080e7          	jalr	-1810(ra) # 80004b8a <end_op>

      if(r != n1){
    800052a4:	009a9f63          	bne	s5,s1,800052c2 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800052a8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052ac:	0149db63          	bge	s3,s4,800052c2 <filewrite+0xf2>
      int n1 = n - i;
    800052b0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800052b4:	0004879b          	sext.w	a5,s1
    800052b8:	f8fbdce3          	bge	s7,a5,80005250 <filewrite+0x80>
    800052bc:	84e2                	mv	s1,s8
    800052be:	bf49                	j	80005250 <filewrite+0x80>
    int i = 0;
    800052c0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800052c2:	033a1d63          	bne	s4,s3,800052fc <filewrite+0x12c>
    800052c6:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800052c8:	60a6                	ld	ra,72(sp)
    800052ca:	6406                	ld	s0,64(sp)
    800052cc:	74e2                	ld	s1,56(sp)
    800052ce:	7942                	ld	s2,48(sp)
    800052d0:	79a2                	ld	s3,40(sp)
    800052d2:	7a02                	ld	s4,32(sp)
    800052d4:	6ae2                	ld	s5,24(sp)
    800052d6:	6b42                	ld	s6,16(sp)
    800052d8:	6ba2                	ld	s7,8(sp)
    800052da:	6c02                	ld	s8,0(sp)
    800052dc:	6161                	add	sp,sp,80
    800052de:	8082                	ret
    panic("filewrite");
    800052e0:	00003517          	auipc	a0,0x3
    800052e4:	47050513          	add	a0,a0,1136 # 80008750 <syscalls+0x2b0>
    800052e8:	ffffb097          	auipc	ra,0xffffb
    800052ec:	254080e7          	jalr	596(ra) # 8000053c <panic>
    return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	8082                	ret
      return -1;
    800052f4:	557d                	li	a0,-1
    800052f6:	bfc9                	j	800052c8 <filewrite+0xf8>
    800052f8:	557d                	li	a0,-1
    800052fa:	b7f9                	j	800052c8 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800052fc:	557d                	li	a0,-1
    800052fe:	b7e9                	j	800052c8 <filewrite+0xf8>

0000000080005300 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005300:	7179                	add	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	ec26                	sd	s1,24(sp)
    80005308:	e84a                	sd	s2,16(sp)
    8000530a:	e44e                	sd	s3,8(sp)
    8000530c:	e052                	sd	s4,0(sp)
    8000530e:	1800                	add	s0,sp,48
    80005310:	84aa                	mv	s1,a0
    80005312:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005314:	0005b023          	sd	zero,0(a1)
    80005318:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	bfc080e7          	jalr	-1028(ra) # 80004f18 <filealloc>
    80005324:	e088                	sd	a0,0(s1)
    80005326:	c551                	beqz	a0,800053b2 <pipealloc+0xb2>
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	bf0080e7          	jalr	-1040(ra) # 80004f18 <filealloc>
    80005330:	00aa3023          	sd	a0,0(s4)
    80005334:	c92d                	beqz	a0,800053a6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005336:	ffffb097          	auipc	ra,0xffffb
    8000533a:	7ac080e7          	jalr	1964(ra) # 80000ae2 <kalloc>
    8000533e:	892a                	mv	s2,a0
    80005340:	c125                	beqz	a0,800053a0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005342:	4985                	li	s3,1
    80005344:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005348:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000534c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005350:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005354:	00003597          	auipc	a1,0x3
    80005358:	40c58593          	add	a1,a1,1036 # 80008760 <syscalls+0x2c0>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	7e6080e7          	jalr	2022(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80005364:	609c                	ld	a5,0(s1)
    80005366:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000536a:	609c                	ld	a5,0(s1)
    8000536c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005370:	609c                	ld	a5,0(s1)
    80005372:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005376:	609c                	ld	a5,0(s1)
    80005378:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000537c:	000a3783          	ld	a5,0(s4)
    80005380:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005384:	000a3783          	ld	a5,0(s4)
    80005388:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000538c:	000a3783          	ld	a5,0(s4)
    80005390:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005394:	000a3783          	ld	a5,0(s4)
    80005398:	0127b823          	sd	s2,16(a5)
  return 0;
    8000539c:	4501                	li	a0,0
    8000539e:	a025                	j	800053c6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053a0:	6088                	ld	a0,0(s1)
    800053a2:	e501                	bnez	a0,800053aa <pipealloc+0xaa>
    800053a4:	a039                	j	800053b2 <pipealloc+0xb2>
    800053a6:	6088                	ld	a0,0(s1)
    800053a8:	c51d                	beqz	a0,800053d6 <pipealloc+0xd6>
    fileclose(*f0);
    800053aa:	00000097          	auipc	ra,0x0
    800053ae:	c2a080e7          	jalr	-982(ra) # 80004fd4 <fileclose>
  if(*f1)
    800053b2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053b6:	557d                	li	a0,-1
  if(*f1)
    800053b8:	c799                	beqz	a5,800053c6 <pipealloc+0xc6>
    fileclose(*f1);
    800053ba:	853e                	mv	a0,a5
    800053bc:	00000097          	auipc	ra,0x0
    800053c0:	c18080e7          	jalr	-1000(ra) # 80004fd4 <fileclose>
  return -1;
    800053c4:	557d                	li	a0,-1
}
    800053c6:	70a2                	ld	ra,40(sp)
    800053c8:	7402                	ld	s0,32(sp)
    800053ca:	64e2                	ld	s1,24(sp)
    800053cc:	6942                	ld	s2,16(sp)
    800053ce:	69a2                	ld	s3,8(sp)
    800053d0:	6a02                	ld	s4,0(sp)
    800053d2:	6145                	add	sp,sp,48
    800053d4:	8082                	ret
  return -1;
    800053d6:	557d                	li	a0,-1
    800053d8:	b7fd                	j	800053c6 <pipealloc+0xc6>

00000000800053da <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053da:	1101                	add	sp,sp,-32
    800053dc:	ec06                	sd	ra,24(sp)
    800053de:	e822                	sd	s0,16(sp)
    800053e0:	e426                	sd	s1,8(sp)
    800053e2:	e04a                	sd	s2,0(sp)
    800053e4:	1000                	add	s0,sp,32
    800053e6:	84aa                	mv	s1,a0
    800053e8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800053ea:	ffffb097          	auipc	ra,0xffffb
    800053ee:	7e8080e7          	jalr	2024(ra) # 80000bd2 <acquire>
  if(writable){
    800053f2:	02090d63          	beqz	s2,8000542c <pipeclose+0x52>
    pi->writeopen = 0;
    800053f6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800053fa:	21848513          	add	a0,s1,536
    800053fe:	ffffd097          	auipc	ra,0xffffd
    80005402:	3e0080e7          	jalr	992(ra) # 800027de <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005406:	2204b783          	ld	a5,544(s1)
    8000540a:	eb95                	bnez	a5,8000543e <pipeclose+0x64>
    release(&pi->lock);
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	878080e7          	jalr	-1928(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005416:	8526                	mv	a0,s1
    80005418:	ffffb097          	auipc	ra,0xffffb
    8000541c:	5cc080e7          	jalr	1484(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005420:	60e2                	ld	ra,24(sp)
    80005422:	6442                	ld	s0,16(sp)
    80005424:	64a2                	ld	s1,8(sp)
    80005426:	6902                	ld	s2,0(sp)
    80005428:	6105                	add	sp,sp,32
    8000542a:	8082                	ret
    pi->readopen = 0;
    8000542c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005430:	21c48513          	add	a0,s1,540
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	3aa080e7          	jalr	938(ra) # 800027de <wakeup>
    8000543c:	b7e9                	j	80005406 <pipeclose+0x2c>
    release(&pi->lock);
    8000543e:	8526                	mv	a0,s1
    80005440:	ffffc097          	auipc	ra,0xffffc
    80005444:	846080e7          	jalr	-1978(ra) # 80000c86 <release>
}
    80005448:	bfe1                	j	80005420 <pipeclose+0x46>

000000008000544a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000544a:	711d                	add	sp,sp,-96
    8000544c:	ec86                	sd	ra,88(sp)
    8000544e:	e8a2                	sd	s0,80(sp)
    80005450:	e4a6                	sd	s1,72(sp)
    80005452:	e0ca                	sd	s2,64(sp)
    80005454:	fc4e                	sd	s3,56(sp)
    80005456:	f852                	sd	s4,48(sp)
    80005458:	f456                	sd	s5,40(sp)
    8000545a:	f05a                	sd	s6,32(sp)
    8000545c:	ec5e                	sd	s7,24(sp)
    8000545e:	e862                	sd	s8,16(sp)
    80005460:	1080                	add	s0,sp,96
    80005462:	84aa                	mv	s1,a0
    80005464:	8aae                	mv	s5,a1
    80005466:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	626080e7          	jalr	1574(ra) # 80001a8e <myproc>
    80005470:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffb097          	auipc	ra,0xffffb
    80005478:	75e080e7          	jalr	1886(ra) # 80000bd2 <acquire>
  while(i < n){
    8000547c:	0b405663          	blez	s4,80005528 <pipewrite+0xde>
  int i = 0;
    80005480:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005482:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005484:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005488:	21c48b93          	add	s7,s1,540
    8000548c:	a089                	j	800054ce <pipewrite+0x84>
      release(&pi->lock);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffb097          	auipc	ra,0xffffb
    80005494:	7f6080e7          	jalr	2038(ra) # 80000c86 <release>
      return -1;
    80005498:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000549a:	854a                	mv	a0,s2
    8000549c:	60e6                	ld	ra,88(sp)
    8000549e:	6446                	ld	s0,80(sp)
    800054a0:	64a6                	ld	s1,72(sp)
    800054a2:	6906                	ld	s2,64(sp)
    800054a4:	79e2                	ld	s3,56(sp)
    800054a6:	7a42                	ld	s4,48(sp)
    800054a8:	7aa2                	ld	s5,40(sp)
    800054aa:	7b02                	ld	s6,32(sp)
    800054ac:	6be2                	ld	s7,24(sp)
    800054ae:	6c42                	ld	s8,16(sp)
    800054b0:	6125                	add	sp,sp,96
    800054b2:	8082                	ret
      wakeup(&pi->nread);
    800054b4:	8562                	mv	a0,s8
    800054b6:	ffffd097          	auipc	ra,0xffffd
    800054ba:	328080e7          	jalr	808(ra) # 800027de <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054be:	85a6                	mv	a1,s1
    800054c0:	855e                	mv	a0,s7
    800054c2:	ffffd097          	auipc	ra,0xffffd
    800054c6:	2b8080e7          	jalr	696(ra) # 8000277a <sleep>
  while(i < n){
    800054ca:	07495063          	bge	s2,s4,8000552a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800054ce:	2204a783          	lw	a5,544(s1)
    800054d2:	dfd5                	beqz	a5,8000548e <pipewrite+0x44>
    800054d4:	854e                	mv	a0,s3
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	558080e7          	jalr	1368(ra) # 80002a2e <killed>
    800054de:	f945                	bnez	a0,8000548e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800054e0:	2184a783          	lw	a5,536(s1)
    800054e4:	21c4a703          	lw	a4,540(s1)
    800054e8:	2007879b          	addw	a5,a5,512
    800054ec:	fcf704e3          	beq	a4,a5,800054b4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054f0:	4685                	li	a3,1
    800054f2:	01590633          	add	a2,s2,s5
    800054f6:	faf40593          	add	a1,s0,-81
    800054fa:	0509b503          	ld	a0,80(s3)
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	1f4080e7          	jalr	500(ra) # 800016f2 <copyin>
    80005506:	03650263          	beq	a0,s6,8000552a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000550a:	21c4a783          	lw	a5,540(s1)
    8000550e:	0017871b          	addw	a4,a5,1
    80005512:	20e4ae23          	sw	a4,540(s1)
    80005516:	1ff7f793          	and	a5,a5,511
    8000551a:	97a6                	add	a5,a5,s1
    8000551c:	faf44703          	lbu	a4,-81(s0)
    80005520:	00e78c23          	sb	a4,24(a5)
      i++;
    80005524:	2905                	addw	s2,s2,1
    80005526:	b755                	j	800054ca <pipewrite+0x80>
  int i = 0;
    80005528:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000552a:	21848513          	add	a0,s1,536
    8000552e:	ffffd097          	auipc	ra,0xffffd
    80005532:	2b0080e7          	jalr	688(ra) # 800027de <wakeup>
  release(&pi->lock);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffb097          	auipc	ra,0xffffb
    8000553c:	74e080e7          	jalr	1870(ra) # 80000c86 <release>
  return i;
    80005540:	bfa9                	j	8000549a <pipewrite+0x50>

0000000080005542 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005542:	715d                	add	sp,sp,-80
    80005544:	e486                	sd	ra,72(sp)
    80005546:	e0a2                	sd	s0,64(sp)
    80005548:	fc26                	sd	s1,56(sp)
    8000554a:	f84a                	sd	s2,48(sp)
    8000554c:	f44e                	sd	s3,40(sp)
    8000554e:	f052                	sd	s4,32(sp)
    80005550:	ec56                	sd	s5,24(sp)
    80005552:	e85a                	sd	s6,16(sp)
    80005554:	0880                	add	s0,sp,80
    80005556:	84aa                	mv	s1,a0
    80005558:	892e                	mv	s2,a1
    8000555a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	532080e7          	jalr	1330(ra) # 80001a8e <myproc>
    80005564:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	66a080e7          	jalr	1642(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005570:	2184a703          	lw	a4,536(s1)
    80005574:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005578:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000557c:	02f71763          	bne	a4,a5,800055aa <piperead+0x68>
    80005580:	2244a783          	lw	a5,548(s1)
    80005584:	c39d                	beqz	a5,800055aa <piperead+0x68>
    if(killed(pr)){
    80005586:	8552                	mv	a0,s4
    80005588:	ffffd097          	auipc	ra,0xffffd
    8000558c:	4a6080e7          	jalr	1190(ra) # 80002a2e <killed>
    80005590:	e949                	bnez	a0,80005622 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005592:	85a6                	mv	a1,s1
    80005594:	854e                	mv	a0,s3
    80005596:	ffffd097          	auipc	ra,0xffffd
    8000559a:	1e4080e7          	jalr	484(ra) # 8000277a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000559e:	2184a703          	lw	a4,536(s1)
    800055a2:	21c4a783          	lw	a5,540(s1)
    800055a6:	fcf70de3          	beq	a4,a5,80005580 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055aa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055ac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ae:	05505463          	blez	s5,800055f6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800055b2:	2184a783          	lw	a5,536(s1)
    800055b6:	21c4a703          	lw	a4,540(s1)
    800055ba:	02f70e63          	beq	a4,a5,800055f6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055be:	0017871b          	addw	a4,a5,1
    800055c2:	20e4ac23          	sw	a4,536(s1)
    800055c6:	1ff7f793          	and	a5,a5,511
    800055ca:	97a6                	add	a5,a5,s1
    800055cc:	0187c783          	lbu	a5,24(a5)
    800055d0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055d4:	4685                	li	a3,1
    800055d6:	fbf40613          	add	a2,s0,-65
    800055da:	85ca                	mv	a1,s2
    800055dc:	050a3503          	ld	a0,80(s4)
    800055e0:	ffffc097          	auipc	ra,0xffffc
    800055e4:	086080e7          	jalr	134(ra) # 80001666 <copyout>
    800055e8:	01650763          	beq	a0,s6,800055f6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ec:	2985                	addw	s3,s3,1
    800055ee:	0905                	add	s2,s2,1
    800055f0:	fd3a91e3          	bne	s5,s3,800055b2 <piperead+0x70>
    800055f4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800055f6:	21c48513          	add	a0,s1,540
    800055fa:	ffffd097          	auipc	ra,0xffffd
    800055fe:	1e4080e7          	jalr	484(ra) # 800027de <wakeup>
  release(&pi->lock);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	682080e7          	jalr	1666(ra) # 80000c86 <release>
  return i;
}
    8000560c:	854e                	mv	a0,s3
    8000560e:	60a6                	ld	ra,72(sp)
    80005610:	6406                	ld	s0,64(sp)
    80005612:	74e2                	ld	s1,56(sp)
    80005614:	7942                	ld	s2,48(sp)
    80005616:	79a2                	ld	s3,40(sp)
    80005618:	7a02                	ld	s4,32(sp)
    8000561a:	6ae2                	ld	s5,24(sp)
    8000561c:	6b42                	ld	s6,16(sp)
    8000561e:	6161                	add	sp,sp,80
    80005620:	8082                	ret
      release(&pi->lock);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffb097          	auipc	ra,0xffffb
    80005628:	662080e7          	jalr	1634(ra) # 80000c86 <release>
      return -1;
    8000562c:	59fd                	li	s3,-1
    8000562e:	bff9                	j	8000560c <piperead+0xca>

0000000080005630 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005630:	1141                	add	sp,sp,-16
    80005632:	e422                	sd	s0,8(sp)
    80005634:	0800                	add	s0,sp,16
    80005636:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005638:	8905                	and	a0,a0,1
    8000563a:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000563c:	8b89                	and	a5,a5,2
    8000563e:	c399                	beqz	a5,80005644 <flags2perm+0x14>
      perm |= PTE_W;
    80005640:	00456513          	or	a0,a0,4
    return perm;
}
    80005644:	6422                	ld	s0,8(sp)
    80005646:	0141                	add	sp,sp,16
    80005648:	8082                	ret

000000008000564a <exec>:

int
exec(char *path, char **argv)
{
    8000564a:	df010113          	add	sp,sp,-528
    8000564e:	20113423          	sd	ra,520(sp)
    80005652:	20813023          	sd	s0,512(sp)
    80005656:	ffa6                	sd	s1,504(sp)
    80005658:	fbca                	sd	s2,496(sp)
    8000565a:	f7ce                	sd	s3,488(sp)
    8000565c:	f3d2                	sd	s4,480(sp)
    8000565e:	efd6                	sd	s5,472(sp)
    80005660:	ebda                	sd	s6,464(sp)
    80005662:	e7de                	sd	s7,456(sp)
    80005664:	e3e2                	sd	s8,448(sp)
    80005666:	ff66                	sd	s9,440(sp)
    80005668:	fb6a                	sd	s10,432(sp)
    8000566a:	f76e                	sd	s11,424(sp)
    8000566c:	0c00                	add	s0,sp,528
    8000566e:	892a                	mv	s2,a0
    80005670:	dea43c23          	sd	a0,-520(s0)
    80005674:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005678:	ffffc097          	auipc	ra,0xffffc
    8000567c:	416080e7          	jalr	1046(ra) # 80001a8e <myproc>
    80005680:	84aa                	mv	s1,a0

  begin_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	48e080e7          	jalr	1166(ra) # 80004b10 <begin_op>

  if((ip = namei(path)) == 0){
    8000568a:	854a                	mv	a0,s2
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	284080e7          	jalr	644(ra) # 80004910 <namei>
    80005694:	c92d                	beqz	a0,80005706 <exec+0xbc>
    80005696:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	ad2080e7          	jalr	-1326(ra) # 8000416a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056a0:	04000713          	li	a4,64
    800056a4:	4681                	li	a3,0
    800056a6:	e5040613          	add	a2,s0,-432
    800056aa:	4581                	li	a1,0
    800056ac:	8552                	mv	a0,s4
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	d70080e7          	jalr	-656(ra) # 8000441e <readi>
    800056b6:	04000793          	li	a5,64
    800056ba:	00f51a63          	bne	a0,a5,800056ce <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800056be:	e5042703          	lw	a4,-432(s0)
    800056c2:	464c47b7          	lui	a5,0x464c4
    800056c6:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800056ca:	04f70463          	beq	a4,a5,80005712 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800056ce:	8552                	mv	a0,s4
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	cfc080e7          	jalr	-772(ra) # 800043cc <iunlockput>
    end_op();
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	4b2080e7          	jalr	1202(ra) # 80004b8a <end_op>
  }
  return -1;
    800056e0:	557d                	li	a0,-1
}
    800056e2:	20813083          	ld	ra,520(sp)
    800056e6:	20013403          	ld	s0,512(sp)
    800056ea:	74fe                	ld	s1,504(sp)
    800056ec:	795e                	ld	s2,496(sp)
    800056ee:	79be                	ld	s3,488(sp)
    800056f0:	7a1e                	ld	s4,480(sp)
    800056f2:	6afe                	ld	s5,472(sp)
    800056f4:	6b5e                	ld	s6,464(sp)
    800056f6:	6bbe                	ld	s7,456(sp)
    800056f8:	6c1e                	ld	s8,448(sp)
    800056fa:	7cfa                	ld	s9,440(sp)
    800056fc:	7d5a                	ld	s10,432(sp)
    800056fe:	7dba                	ld	s11,424(sp)
    80005700:	21010113          	add	sp,sp,528
    80005704:	8082                	ret
    end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	484080e7          	jalr	1156(ra) # 80004b8a <end_op>
    return -1;
    8000570e:	557d                	li	a0,-1
    80005710:	bfc9                	j	800056e2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005712:	8526                	mv	a0,s1
    80005714:	ffffc097          	auipc	ra,0xffffc
    80005718:	43e080e7          	jalr	1086(ra) # 80001b52 <proc_pagetable>
    8000571c:	8b2a                	mv	s6,a0
    8000571e:	d945                	beqz	a0,800056ce <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005720:	e7042d03          	lw	s10,-400(s0)
    80005724:	e8845783          	lhu	a5,-376(s0)
    80005728:	10078463          	beqz	a5,80005830 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000572c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000572e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005730:	6c85                	lui	s9,0x1
    80005732:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005736:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000573a:	6a85                	lui	s5,0x1
    8000573c:	a0b5                	j	800057a8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	02a50513          	add	a0,a0,42 # 80008768 <syscalls+0x2c8>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	df6080e7          	jalr	-522(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000574e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005750:	8726                	mv	a4,s1
    80005752:	012c06bb          	addw	a3,s8,s2
    80005756:	4581                	li	a1,0
    80005758:	8552                	mv	a0,s4
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	cc4080e7          	jalr	-828(ra) # 8000441e <readi>
    80005762:	2501                	sext.w	a0,a0
    80005764:	24a49863          	bne	s1,a0,800059b4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005768:	012a893b          	addw	s2,s5,s2
    8000576c:	03397563          	bgeu	s2,s3,80005796 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005770:	02091593          	sll	a1,s2,0x20
    80005774:	9181                	srl	a1,a1,0x20
    80005776:	95de                	add	a1,a1,s7
    80005778:	855a                	mv	a0,s6
    8000577a:	ffffc097          	auipc	ra,0xffffc
    8000577e:	8dc080e7          	jalr	-1828(ra) # 80001056 <walkaddr>
    80005782:	862a                	mv	a2,a0
    if(pa == 0)
    80005784:	dd4d                	beqz	a0,8000573e <exec+0xf4>
    if(sz - i < PGSIZE)
    80005786:	412984bb          	subw	s1,s3,s2
    8000578a:	0004879b          	sext.w	a5,s1
    8000578e:	fcfcf0e3          	bgeu	s9,a5,8000574e <exec+0x104>
    80005792:	84d6                	mv	s1,s5
    80005794:	bf6d                	j	8000574e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005796:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000579a:	2d85                	addw	s11,s11,1
    8000579c:	038d0d1b          	addw	s10,s10,56
    800057a0:	e8845783          	lhu	a5,-376(s0)
    800057a4:	08fdd763          	bge	s11,a5,80005832 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057a8:	2d01                	sext.w	s10,s10
    800057aa:	03800713          	li	a4,56
    800057ae:	86ea                	mv	a3,s10
    800057b0:	e1840613          	add	a2,s0,-488
    800057b4:	4581                	li	a1,0
    800057b6:	8552                	mv	a0,s4
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	c66080e7          	jalr	-922(ra) # 8000441e <readi>
    800057c0:	03800793          	li	a5,56
    800057c4:	1ef51663          	bne	a0,a5,800059b0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800057c8:	e1842783          	lw	a5,-488(s0)
    800057cc:	4705                	li	a4,1
    800057ce:	fce796e3          	bne	a5,a4,8000579a <exec+0x150>
    if(ph.memsz < ph.filesz)
    800057d2:	e4043483          	ld	s1,-448(s0)
    800057d6:	e3843783          	ld	a5,-456(s0)
    800057da:	1ef4e863          	bltu	s1,a5,800059ca <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800057de:	e2843783          	ld	a5,-472(s0)
    800057e2:	94be                	add	s1,s1,a5
    800057e4:	1ef4e663          	bltu	s1,a5,800059d0 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800057e8:	df043703          	ld	a4,-528(s0)
    800057ec:	8ff9                	and	a5,a5,a4
    800057ee:	1e079463          	bnez	a5,800059d6 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057f2:	e1c42503          	lw	a0,-484(s0)
    800057f6:	00000097          	auipc	ra,0x0
    800057fa:	e3a080e7          	jalr	-454(ra) # 80005630 <flags2perm>
    800057fe:	86aa                	mv	a3,a0
    80005800:	8626                	mv	a2,s1
    80005802:	85ca                	mv	a1,s2
    80005804:	855a                	mv	a0,s6
    80005806:	ffffc097          	auipc	ra,0xffffc
    8000580a:	c04080e7          	jalr	-1020(ra) # 8000140a <uvmalloc>
    8000580e:	e0a43423          	sd	a0,-504(s0)
    80005812:	1c050563          	beqz	a0,800059dc <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005816:	e2843b83          	ld	s7,-472(s0)
    8000581a:	e2042c03          	lw	s8,-480(s0)
    8000581e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005822:	00098463          	beqz	s3,8000582a <exec+0x1e0>
    80005826:	4901                	li	s2,0
    80005828:	b7a1                	j	80005770 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000582a:	e0843903          	ld	s2,-504(s0)
    8000582e:	b7b5                	j	8000579a <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005830:	4901                	li	s2,0
  iunlockput(ip);
    80005832:	8552                	mv	a0,s4
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	b98080e7          	jalr	-1128(ra) # 800043cc <iunlockput>
  end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	34e080e7          	jalr	846(ra) # 80004b8a <end_op>
  p = myproc();
    80005844:	ffffc097          	auipc	ra,0xffffc
    80005848:	24a080e7          	jalr	586(ra) # 80001a8e <myproc>
    8000584c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000584e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005852:	6985                	lui	s3,0x1
    80005854:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005856:	99ca                	add	s3,s3,s2
    80005858:	77fd                	lui	a5,0xfffff
    8000585a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000585e:	4691                	li	a3,4
    80005860:	6609                	lui	a2,0x2
    80005862:	964e                	add	a2,a2,s3
    80005864:	85ce                	mv	a1,s3
    80005866:	855a                	mv	a0,s6
    80005868:	ffffc097          	auipc	ra,0xffffc
    8000586c:	ba2080e7          	jalr	-1118(ra) # 8000140a <uvmalloc>
    80005870:	892a                	mv	s2,a0
    80005872:	e0a43423          	sd	a0,-504(s0)
    80005876:	e509                	bnez	a0,80005880 <exec+0x236>
  if(pagetable)
    80005878:	e1343423          	sd	s3,-504(s0)
    8000587c:	4a01                	li	s4,0
    8000587e:	aa1d                	j	800059b4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005880:	75f9                	lui	a1,0xffffe
    80005882:	95aa                	add	a1,a1,a0
    80005884:	855a                	mv	a0,s6
    80005886:	ffffc097          	auipc	ra,0xffffc
    8000588a:	dae080e7          	jalr	-594(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    8000588e:	7bfd                	lui	s7,0xfffff
    80005890:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005892:	e0043783          	ld	a5,-512(s0)
    80005896:	6388                	ld	a0,0(a5)
    80005898:	c52d                	beqz	a0,80005902 <exec+0x2b8>
    8000589a:	e9040993          	add	s3,s0,-368
    8000589e:	f9040c13          	add	s8,s0,-112
    800058a2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058a4:	ffffb097          	auipc	ra,0xffffb
    800058a8:	5a4080e7          	jalr	1444(ra) # 80000e48 <strlen>
    800058ac:	0015079b          	addw	a5,a0,1
    800058b0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058b4:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800058b8:	13796563          	bltu	s2,s7,800059e2 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058bc:	e0043d03          	ld	s10,-512(s0)
    800058c0:	000d3a03          	ld	s4,0(s10)
    800058c4:	8552                	mv	a0,s4
    800058c6:	ffffb097          	auipc	ra,0xffffb
    800058ca:	582080e7          	jalr	1410(ra) # 80000e48 <strlen>
    800058ce:	0015069b          	addw	a3,a0,1
    800058d2:	8652                	mv	a2,s4
    800058d4:	85ca                	mv	a1,s2
    800058d6:	855a                	mv	a0,s6
    800058d8:	ffffc097          	auipc	ra,0xffffc
    800058dc:	d8e080e7          	jalr	-626(ra) # 80001666 <copyout>
    800058e0:	10054363          	bltz	a0,800059e6 <exec+0x39c>
    ustack[argc] = sp;
    800058e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800058e8:	0485                	add	s1,s1,1
    800058ea:	008d0793          	add	a5,s10,8
    800058ee:	e0f43023          	sd	a5,-512(s0)
    800058f2:	008d3503          	ld	a0,8(s10)
    800058f6:	c909                	beqz	a0,80005908 <exec+0x2be>
    if(argc >= MAXARG)
    800058f8:	09a1                	add	s3,s3,8
    800058fa:	fb8995e3          	bne	s3,s8,800058a4 <exec+0x25a>
  ip = 0;
    800058fe:	4a01                	li	s4,0
    80005900:	a855                	j	800059b4 <exec+0x36a>
  sp = sz;
    80005902:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005906:	4481                	li	s1,0
  ustack[argc] = 0;
    80005908:	00349793          	sll	a5,s1,0x3
    8000590c:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8fa0>
    80005910:	97a2                	add	a5,a5,s0
    80005912:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005916:	00148693          	add	a3,s1,1
    8000591a:	068e                	sll	a3,a3,0x3
    8000591c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005920:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005924:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005928:	f57968e3          	bltu	s2,s7,80005878 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000592c:	e9040613          	add	a2,s0,-368
    80005930:	85ca                	mv	a1,s2
    80005932:	855a                	mv	a0,s6
    80005934:	ffffc097          	auipc	ra,0xffffc
    80005938:	d32080e7          	jalr	-718(ra) # 80001666 <copyout>
    8000593c:	0a054763          	bltz	a0,800059ea <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005940:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005944:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005948:	df843783          	ld	a5,-520(s0)
    8000594c:	0007c703          	lbu	a4,0(a5)
    80005950:	cf11                	beqz	a4,8000596c <exec+0x322>
    80005952:	0785                	add	a5,a5,1
    if(*s == '/')
    80005954:	02f00693          	li	a3,47
    80005958:	a039                	j	80005966 <exec+0x31c>
      last = s+1;
    8000595a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000595e:	0785                	add	a5,a5,1
    80005960:	fff7c703          	lbu	a4,-1(a5)
    80005964:	c701                	beqz	a4,8000596c <exec+0x322>
    if(*s == '/')
    80005966:	fed71ce3          	bne	a4,a3,8000595e <exec+0x314>
    8000596a:	bfc5                	j	8000595a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000596c:	4641                	li	a2,16
    8000596e:	df843583          	ld	a1,-520(s0)
    80005972:	158a8513          	add	a0,s5,344
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	4a0080e7          	jalr	1184(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    8000597e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005982:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005986:	e0843783          	ld	a5,-504(s0)
    8000598a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000598e:	058ab783          	ld	a5,88(s5)
    80005992:	e6843703          	ld	a4,-408(s0)
    80005996:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005998:	058ab783          	ld	a5,88(s5)
    8000599c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059a0:	85e6                	mv	a1,s9
    800059a2:	ffffc097          	auipc	ra,0xffffc
    800059a6:	24c080e7          	jalr	588(ra) # 80001bee <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059aa:	0004851b          	sext.w	a0,s1
    800059ae:	bb15                	j	800056e2 <exec+0x98>
    800059b0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800059b4:	e0843583          	ld	a1,-504(s0)
    800059b8:	855a                	mv	a0,s6
    800059ba:	ffffc097          	auipc	ra,0xffffc
    800059be:	234080e7          	jalr	564(ra) # 80001bee <proc_freepagetable>
  return -1;
    800059c2:	557d                	li	a0,-1
  if(ip){
    800059c4:	d00a0fe3          	beqz	s4,800056e2 <exec+0x98>
    800059c8:	b319                	j	800056ce <exec+0x84>
    800059ca:	e1243423          	sd	s2,-504(s0)
    800059ce:	b7dd                	j	800059b4 <exec+0x36a>
    800059d0:	e1243423          	sd	s2,-504(s0)
    800059d4:	b7c5                	j	800059b4 <exec+0x36a>
    800059d6:	e1243423          	sd	s2,-504(s0)
    800059da:	bfe9                	j	800059b4 <exec+0x36a>
    800059dc:	e1243423          	sd	s2,-504(s0)
    800059e0:	bfd1                	j	800059b4 <exec+0x36a>
  ip = 0;
    800059e2:	4a01                	li	s4,0
    800059e4:	bfc1                	j	800059b4 <exec+0x36a>
    800059e6:	4a01                	li	s4,0
  if(pagetable)
    800059e8:	b7f1                	j	800059b4 <exec+0x36a>
  sz = sz1;
    800059ea:	e0843983          	ld	s3,-504(s0)
    800059ee:	b569                	j	80005878 <exec+0x22e>

00000000800059f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800059f0:	7179                	add	sp,sp,-48
    800059f2:	f406                	sd	ra,40(sp)
    800059f4:	f022                	sd	s0,32(sp)
    800059f6:	ec26                	sd	s1,24(sp)
    800059f8:	e84a                	sd	s2,16(sp)
    800059fa:	1800                	add	s0,sp,48
    800059fc:	892e                	mv	s2,a1
    800059fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005a00:	fdc40593          	add	a1,s0,-36
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	a16080e7          	jalr	-1514(ra) # 8000341a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a0c:	fdc42703          	lw	a4,-36(s0)
    80005a10:	47bd                	li	a5,15
    80005a12:	02e7eb63          	bltu	a5,a4,80005a48 <argfd+0x58>
    80005a16:	ffffc097          	auipc	ra,0xffffc
    80005a1a:	078080e7          	jalr	120(ra) # 80001a8e <myproc>
    80005a1e:	fdc42703          	lw	a4,-36(s0)
    80005a22:	01a70793          	add	a5,a4,26
    80005a26:	078e                	sll	a5,a5,0x3
    80005a28:	953e                	add	a0,a0,a5
    80005a2a:	611c                	ld	a5,0(a0)
    80005a2c:	c385                	beqz	a5,80005a4c <argfd+0x5c>
    return -1;
  if(pfd)
    80005a2e:	00090463          	beqz	s2,80005a36 <argfd+0x46>
    *pfd = fd;
    80005a32:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a36:	4501                	li	a0,0
  if(pf)
    80005a38:	c091                	beqz	s1,80005a3c <argfd+0x4c>
    *pf = f;
    80005a3a:	e09c                	sd	a5,0(s1)
}
    80005a3c:	70a2                	ld	ra,40(sp)
    80005a3e:	7402                	ld	s0,32(sp)
    80005a40:	64e2                	ld	s1,24(sp)
    80005a42:	6942                	ld	s2,16(sp)
    80005a44:	6145                	add	sp,sp,48
    80005a46:	8082                	ret
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	bfcd                	j	80005a3c <argfd+0x4c>
    80005a4c:	557d                	li	a0,-1
    80005a4e:	b7fd                	j	80005a3c <argfd+0x4c>

0000000080005a50 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a50:	1101                	add	sp,sp,-32
    80005a52:	ec06                	sd	ra,24(sp)
    80005a54:	e822                	sd	s0,16(sp)
    80005a56:	e426                	sd	s1,8(sp)
    80005a58:	1000                	add	s0,sp,32
    80005a5a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a5c:	ffffc097          	auipc	ra,0xffffc
    80005a60:	032080e7          	jalr	50(ra) # 80001a8e <myproc>
    80005a64:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a66:	0d050793          	add	a5,a0,208
    80005a6a:	4501                	li	a0,0
    80005a6c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a6e:	6398                	ld	a4,0(a5)
    80005a70:	cb19                	beqz	a4,80005a86 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a72:	2505                	addw	a0,a0,1
    80005a74:	07a1                	add	a5,a5,8
    80005a76:	fed51ce3          	bne	a0,a3,80005a6e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a7a:	557d                	li	a0,-1
}
    80005a7c:	60e2                	ld	ra,24(sp)
    80005a7e:	6442                	ld	s0,16(sp)
    80005a80:	64a2                	ld	s1,8(sp)
    80005a82:	6105                	add	sp,sp,32
    80005a84:	8082                	ret
      p->ofile[fd] = f;
    80005a86:	01a50793          	add	a5,a0,26
    80005a8a:	078e                	sll	a5,a5,0x3
    80005a8c:	963e                	add	a2,a2,a5
    80005a8e:	e204                	sd	s1,0(a2)
      return fd;
    80005a90:	b7f5                	j	80005a7c <fdalloc+0x2c>

0000000080005a92 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005a92:	715d                	add	sp,sp,-80
    80005a94:	e486                	sd	ra,72(sp)
    80005a96:	e0a2                	sd	s0,64(sp)
    80005a98:	fc26                	sd	s1,56(sp)
    80005a9a:	f84a                	sd	s2,48(sp)
    80005a9c:	f44e                	sd	s3,40(sp)
    80005a9e:	f052                	sd	s4,32(sp)
    80005aa0:	ec56                	sd	s5,24(sp)
    80005aa2:	e85a                	sd	s6,16(sp)
    80005aa4:	0880                	add	s0,sp,80
    80005aa6:	8b2e                	mv	s6,a1
    80005aa8:	89b2                	mv	s3,a2
    80005aaa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005aac:	fb040593          	add	a1,s0,-80
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	e7e080e7          	jalr	-386(ra) # 8000492e <nameiparent>
    80005ab8:	84aa                	mv	s1,a0
    80005aba:	14050b63          	beqz	a0,80005c10 <create+0x17e>
    return 0;

  ilock(dp);
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	6ac080e7          	jalr	1708(ra) # 8000416a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005ac6:	4601                	li	a2,0
    80005ac8:	fb040593          	add	a1,s0,-80
    80005acc:	8526                	mv	a0,s1
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	b80080e7          	jalr	-1152(ra) # 8000464e <dirlookup>
    80005ad6:	8aaa                	mv	s5,a0
    80005ad8:	c921                	beqz	a0,80005b28 <create+0x96>
    iunlockput(dp);
    80005ada:	8526                	mv	a0,s1
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	8f0080e7          	jalr	-1808(ra) # 800043cc <iunlockput>
    ilock(ip);
    80005ae4:	8556                	mv	a0,s5
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	684080e7          	jalr	1668(ra) # 8000416a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005aee:	4789                	li	a5,2
    80005af0:	02fb1563          	bne	s6,a5,80005b1a <create+0x88>
    80005af4:	044ad783          	lhu	a5,68(s5)
    80005af8:	37f9                	addw	a5,a5,-2
    80005afa:	17c2                	sll	a5,a5,0x30
    80005afc:	93c1                	srl	a5,a5,0x30
    80005afe:	4705                	li	a4,1
    80005b00:	00f76d63          	bltu	a4,a5,80005b1a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005b04:	8556                	mv	a0,s5
    80005b06:	60a6                	ld	ra,72(sp)
    80005b08:	6406                	ld	s0,64(sp)
    80005b0a:	74e2                	ld	s1,56(sp)
    80005b0c:	7942                	ld	s2,48(sp)
    80005b0e:	79a2                	ld	s3,40(sp)
    80005b10:	7a02                	ld	s4,32(sp)
    80005b12:	6ae2                	ld	s5,24(sp)
    80005b14:	6b42                	ld	s6,16(sp)
    80005b16:	6161                	add	sp,sp,80
    80005b18:	8082                	ret
    iunlockput(ip);
    80005b1a:	8556                	mv	a0,s5
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	8b0080e7          	jalr	-1872(ra) # 800043cc <iunlockput>
    return 0;
    80005b24:	4a81                	li	s5,0
    80005b26:	bff9                	j	80005b04 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005b28:	85da                	mv	a1,s6
    80005b2a:	4088                	lw	a0,0(s1)
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	4a6080e7          	jalr	1190(ra) # 80003fd2 <ialloc>
    80005b34:	8a2a                	mv	s4,a0
    80005b36:	c529                	beqz	a0,80005b80 <create+0xee>
  ilock(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	632080e7          	jalr	1586(ra) # 8000416a <ilock>
  ip->major = major;
    80005b40:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005b44:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005b48:	4905                	li	s2,1
    80005b4a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005b4e:	8552                	mv	a0,s4
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	54e080e7          	jalr	1358(ra) # 8000409e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b58:	032b0b63          	beq	s6,s2,80005b8e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b5c:	004a2603          	lw	a2,4(s4)
    80005b60:	fb040593          	add	a1,s0,-80
    80005b64:	8526                	mv	a0,s1
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	cf8080e7          	jalr	-776(ra) # 8000485e <dirlink>
    80005b6e:	06054f63          	bltz	a0,80005bec <create+0x15a>
  iunlockput(dp);
    80005b72:	8526                	mv	a0,s1
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	858080e7          	jalr	-1960(ra) # 800043cc <iunlockput>
  return ip;
    80005b7c:	8ad2                	mv	s5,s4
    80005b7e:	b759                	j	80005b04 <create+0x72>
    iunlockput(dp);
    80005b80:	8526                	mv	a0,s1
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	84a080e7          	jalr	-1974(ra) # 800043cc <iunlockput>
    return 0;
    80005b8a:	8ad2                	mv	s5,s4
    80005b8c:	bfa5                	j	80005b04 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b8e:	004a2603          	lw	a2,4(s4)
    80005b92:	00003597          	auipc	a1,0x3
    80005b96:	bf658593          	add	a1,a1,-1034 # 80008788 <syscalls+0x2e8>
    80005b9a:	8552                	mv	a0,s4
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	cc2080e7          	jalr	-830(ra) # 8000485e <dirlink>
    80005ba4:	04054463          	bltz	a0,80005bec <create+0x15a>
    80005ba8:	40d0                	lw	a2,4(s1)
    80005baa:	00003597          	auipc	a1,0x3
    80005bae:	be658593          	add	a1,a1,-1050 # 80008790 <syscalls+0x2f0>
    80005bb2:	8552                	mv	a0,s4
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	caa080e7          	jalr	-854(ra) # 8000485e <dirlink>
    80005bbc:	02054863          	bltz	a0,80005bec <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005bc0:	004a2603          	lw	a2,4(s4)
    80005bc4:	fb040593          	add	a1,s0,-80
    80005bc8:	8526                	mv	a0,s1
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	c94080e7          	jalr	-876(ra) # 8000485e <dirlink>
    80005bd2:	00054d63          	bltz	a0,80005bec <create+0x15a>
    dp->nlink++;  // for ".."
    80005bd6:	04a4d783          	lhu	a5,74(s1)
    80005bda:	2785                	addw	a5,a5,1
    80005bdc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	4bc080e7          	jalr	1212(ra) # 8000409e <iupdate>
    80005bea:	b761                	j	80005b72 <create+0xe0>
  ip->nlink = 0;
    80005bec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005bf0:	8552                	mv	a0,s4
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	4ac080e7          	jalr	1196(ra) # 8000409e <iupdate>
  iunlockput(ip);
    80005bfa:	8552                	mv	a0,s4
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	7d0080e7          	jalr	2000(ra) # 800043cc <iunlockput>
  iunlockput(dp);
    80005c04:	8526                	mv	a0,s1
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	7c6080e7          	jalr	1990(ra) # 800043cc <iunlockput>
  return 0;
    80005c0e:	bddd                	j	80005b04 <create+0x72>
    return 0;
    80005c10:	8aaa                	mv	s5,a0
    80005c12:	bdcd                	j	80005b04 <create+0x72>

0000000080005c14 <sys_dup>:
{
    80005c14:	7179                	add	sp,sp,-48
    80005c16:	f406                	sd	ra,40(sp)
    80005c18:	f022                	sd	s0,32(sp)
    80005c1a:	ec26                	sd	s1,24(sp)
    80005c1c:	e84a                	sd	s2,16(sp)
    80005c1e:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c20:	fd840613          	add	a2,s0,-40
    80005c24:	4581                	li	a1,0
    80005c26:	4501                	li	a0,0
    80005c28:	00000097          	auipc	ra,0x0
    80005c2c:	dc8080e7          	jalr	-568(ra) # 800059f0 <argfd>
    return -1;
    80005c30:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c32:	02054363          	bltz	a0,80005c58 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005c36:	fd843903          	ld	s2,-40(s0)
    80005c3a:	854a                	mv	a0,s2
    80005c3c:	00000097          	auipc	ra,0x0
    80005c40:	e14080e7          	jalr	-492(ra) # 80005a50 <fdalloc>
    80005c44:	84aa                	mv	s1,a0
    return -1;
    80005c46:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c48:	00054863          	bltz	a0,80005c58 <sys_dup+0x44>
  filedup(f);
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	334080e7          	jalr	820(ra) # 80004f82 <filedup>
  return fd;
    80005c56:	87a6                	mv	a5,s1
}
    80005c58:	853e                	mv	a0,a5
    80005c5a:	70a2                	ld	ra,40(sp)
    80005c5c:	7402                	ld	s0,32(sp)
    80005c5e:	64e2                	ld	s1,24(sp)
    80005c60:	6942                	ld	s2,16(sp)
    80005c62:	6145                	add	sp,sp,48
    80005c64:	8082                	ret

0000000080005c66 <sys_read>:
{
    80005c66:	7179                	add	sp,sp,-48
    80005c68:	f406                	sd	ra,40(sp)
    80005c6a:	f022                	sd	s0,32(sp)
    80005c6c:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005c6e:	fd840593          	add	a1,s0,-40
    80005c72:	4505                	li	a0,1
    80005c74:	ffffd097          	auipc	ra,0xffffd
    80005c78:	7c6080e7          	jalr	1990(ra) # 8000343a <argaddr>
  argint(2, &n);
    80005c7c:	fe440593          	add	a1,s0,-28
    80005c80:	4509                	li	a0,2
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	798080e7          	jalr	1944(ra) # 8000341a <argint>
  if(argfd(0, 0, &f) < 0)
    80005c8a:	fe840613          	add	a2,s0,-24
    80005c8e:	4581                	li	a1,0
    80005c90:	4501                	li	a0,0
    80005c92:	00000097          	auipc	ra,0x0
    80005c96:	d5e080e7          	jalr	-674(ra) # 800059f0 <argfd>
    80005c9a:	87aa                	mv	a5,a0
    return -1;
    80005c9c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c9e:	0007cc63          	bltz	a5,80005cb6 <sys_read+0x50>
  return fileread(f, p, n);
    80005ca2:	fe442603          	lw	a2,-28(s0)
    80005ca6:	fd843583          	ld	a1,-40(s0)
    80005caa:	fe843503          	ld	a0,-24(s0)
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	460080e7          	jalr	1120(ra) # 8000510e <fileread>
}
    80005cb6:	70a2                	ld	ra,40(sp)
    80005cb8:	7402                	ld	s0,32(sp)
    80005cba:	6145                	add	sp,sp,48
    80005cbc:	8082                	ret

0000000080005cbe <sys_write>:
{
    80005cbe:	7179                	add	sp,sp,-48
    80005cc0:	f406                	sd	ra,40(sp)
    80005cc2:	f022                	sd	s0,32(sp)
    80005cc4:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005cc6:	fd840593          	add	a1,s0,-40
    80005cca:	4505                	li	a0,1
    80005ccc:	ffffd097          	auipc	ra,0xffffd
    80005cd0:	76e080e7          	jalr	1902(ra) # 8000343a <argaddr>
  argint(2, &n);
    80005cd4:	fe440593          	add	a1,s0,-28
    80005cd8:	4509                	li	a0,2
    80005cda:	ffffd097          	auipc	ra,0xffffd
    80005cde:	740080e7          	jalr	1856(ra) # 8000341a <argint>
  if(argfd(0, 0, &f) < 0)
    80005ce2:	fe840613          	add	a2,s0,-24
    80005ce6:	4581                	li	a1,0
    80005ce8:	4501                	li	a0,0
    80005cea:	00000097          	auipc	ra,0x0
    80005cee:	d06080e7          	jalr	-762(ra) # 800059f0 <argfd>
    80005cf2:	87aa                	mv	a5,a0
    return -1;
    80005cf4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cf6:	0007cc63          	bltz	a5,80005d0e <sys_write+0x50>
  return filewrite(f, p, n);
    80005cfa:	fe442603          	lw	a2,-28(s0)
    80005cfe:	fd843583          	ld	a1,-40(s0)
    80005d02:	fe843503          	ld	a0,-24(s0)
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	4ca080e7          	jalr	1226(ra) # 800051d0 <filewrite>
}
    80005d0e:	70a2                	ld	ra,40(sp)
    80005d10:	7402                	ld	s0,32(sp)
    80005d12:	6145                	add	sp,sp,48
    80005d14:	8082                	ret

0000000080005d16 <sys_close>:
{
    80005d16:	1101                	add	sp,sp,-32
    80005d18:	ec06                	sd	ra,24(sp)
    80005d1a:	e822                	sd	s0,16(sp)
    80005d1c:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d1e:	fe040613          	add	a2,s0,-32
    80005d22:	fec40593          	add	a1,s0,-20
    80005d26:	4501                	li	a0,0
    80005d28:	00000097          	auipc	ra,0x0
    80005d2c:	cc8080e7          	jalr	-824(ra) # 800059f0 <argfd>
    return -1;
    80005d30:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d32:	02054463          	bltz	a0,80005d5a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d36:	ffffc097          	auipc	ra,0xffffc
    80005d3a:	d58080e7          	jalr	-680(ra) # 80001a8e <myproc>
    80005d3e:	fec42783          	lw	a5,-20(s0)
    80005d42:	07e9                	add	a5,a5,26
    80005d44:	078e                	sll	a5,a5,0x3
    80005d46:	953e                	add	a0,a0,a5
    80005d48:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005d4c:	fe043503          	ld	a0,-32(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	284080e7          	jalr	644(ra) # 80004fd4 <fileclose>
  return 0;
    80005d58:	4781                	li	a5,0
}
    80005d5a:	853e                	mv	a0,a5
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	6105                	add	sp,sp,32
    80005d62:	8082                	ret

0000000080005d64 <sys_fstat>:
{
    80005d64:	1101                	add	sp,sp,-32
    80005d66:	ec06                	sd	ra,24(sp)
    80005d68:	e822                	sd	s0,16(sp)
    80005d6a:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005d6c:	fe040593          	add	a1,s0,-32
    80005d70:	4505                	li	a0,1
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	6c8080e7          	jalr	1736(ra) # 8000343a <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005d7a:	fe840613          	add	a2,s0,-24
    80005d7e:	4581                	li	a1,0
    80005d80:	4501                	li	a0,0
    80005d82:	00000097          	auipc	ra,0x0
    80005d86:	c6e080e7          	jalr	-914(ra) # 800059f0 <argfd>
    80005d8a:	87aa                	mv	a5,a0
    return -1;
    80005d8c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d8e:	0007ca63          	bltz	a5,80005da2 <sys_fstat+0x3e>
  return filestat(f, st);
    80005d92:	fe043583          	ld	a1,-32(s0)
    80005d96:	fe843503          	ld	a0,-24(s0)
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	302080e7          	jalr	770(ra) # 8000509c <filestat>
}
    80005da2:	60e2                	ld	ra,24(sp)
    80005da4:	6442                	ld	s0,16(sp)
    80005da6:	6105                	add	sp,sp,32
    80005da8:	8082                	ret

0000000080005daa <sys_link>:
{
    80005daa:	7169                	add	sp,sp,-304
    80005dac:	f606                	sd	ra,296(sp)
    80005dae:	f222                	sd	s0,288(sp)
    80005db0:	ee26                	sd	s1,280(sp)
    80005db2:	ea4a                	sd	s2,272(sp)
    80005db4:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005db6:	08000613          	li	a2,128
    80005dba:	ed040593          	add	a1,s0,-304
    80005dbe:	4501                	li	a0,0
    80005dc0:	ffffd097          	auipc	ra,0xffffd
    80005dc4:	69a080e7          	jalr	1690(ra) # 8000345a <argstr>
    return -1;
    80005dc8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005dca:	10054e63          	bltz	a0,80005ee6 <sys_link+0x13c>
    80005dce:	08000613          	li	a2,128
    80005dd2:	f5040593          	add	a1,s0,-176
    80005dd6:	4505                	li	a0,1
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	682080e7          	jalr	1666(ra) # 8000345a <argstr>
    return -1;
    80005de0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005de2:	10054263          	bltz	a0,80005ee6 <sys_link+0x13c>
  begin_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	d2a080e7          	jalr	-726(ra) # 80004b10 <begin_op>
  if((ip = namei(old)) == 0){
    80005dee:	ed040513          	add	a0,s0,-304
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	b1e080e7          	jalr	-1250(ra) # 80004910 <namei>
    80005dfa:	84aa                	mv	s1,a0
    80005dfc:	c551                	beqz	a0,80005e88 <sys_link+0xde>
  ilock(ip);
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	36c080e7          	jalr	876(ra) # 8000416a <ilock>
  if(ip->type == T_DIR){
    80005e06:	04449703          	lh	a4,68(s1)
    80005e0a:	4785                	li	a5,1
    80005e0c:	08f70463          	beq	a4,a5,80005e94 <sys_link+0xea>
  ip->nlink++;
    80005e10:	04a4d783          	lhu	a5,74(s1)
    80005e14:	2785                	addw	a5,a5,1
    80005e16:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e1a:	8526                	mv	a0,s1
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	282080e7          	jalr	642(ra) # 8000409e <iupdate>
  iunlock(ip);
    80005e24:	8526                	mv	a0,s1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	406080e7          	jalr	1030(ra) # 8000422c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e2e:	fd040593          	add	a1,s0,-48
    80005e32:	f5040513          	add	a0,s0,-176
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	af8080e7          	jalr	-1288(ra) # 8000492e <nameiparent>
    80005e3e:	892a                	mv	s2,a0
    80005e40:	c935                	beqz	a0,80005eb4 <sys_link+0x10a>
  ilock(dp);
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	328080e7          	jalr	808(ra) # 8000416a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e4a:	00092703          	lw	a4,0(s2)
    80005e4e:	409c                	lw	a5,0(s1)
    80005e50:	04f71d63          	bne	a4,a5,80005eaa <sys_link+0x100>
    80005e54:	40d0                	lw	a2,4(s1)
    80005e56:	fd040593          	add	a1,s0,-48
    80005e5a:	854a                	mv	a0,s2
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	a02080e7          	jalr	-1534(ra) # 8000485e <dirlink>
    80005e64:	04054363          	bltz	a0,80005eaa <sys_link+0x100>
  iunlockput(dp);
    80005e68:	854a                	mv	a0,s2
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	562080e7          	jalr	1378(ra) # 800043cc <iunlockput>
  iput(ip);
    80005e72:	8526                	mv	a0,s1
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	4b0080e7          	jalr	1200(ra) # 80004324 <iput>
  end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	d0e080e7          	jalr	-754(ra) # 80004b8a <end_op>
  return 0;
    80005e84:	4781                	li	a5,0
    80005e86:	a085                	j	80005ee6 <sys_link+0x13c>
    end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	d02080e7          	jalr	-766(ra) # 80004b8a <end_op>
    return -1;
    80005e90:	57fd                	li	a5,-1
    80005e92:	a891                	j	80005ee6 <sys_link+0x13c>
    iunlockput(ip);
    80005e94:	8526                	mv	a0,s1
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	536080e7          	jalr	1334(ra) # 800043cc <iunlockput>
    end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	cec080e7          	jalr	-788(ra) # 80004b8a <end_op>
    return -1;
    80005ea6:	57fd                	li	a5,-1
    80005ea8:	a83d                	j	80005ee6 <sys_link+0x13c>
    iunlockput(dp);
    80005eaa:	854a                	mv	a0,s2
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	520080e7          	jalr	1312(ra) # 800043cc <iunlockput>
  ilock(ip);
    80005eb4:	8526                	mv	a0,s1
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	2b4080e7          	jalr	692(ra) # 8000416a <ilock>
  ip->nlink--;
    80005ebe:	04a4d783          	lhu	a5,74(s1)
    80005ec2:	37fd                	addw	a5,a5,-1
    80005ec4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ec8:	8526                	mv	a0,s1
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	1d4080e7          	jalr	468(ra) # 8000409e <iupdate>
  iunlockput(ip);
    80005ed2:	8526                	mv	a0,s1
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	4f8080e7          	jalr	1272(ra) # 800043cc <iunlockput>
  end_op();
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	cae080e7          	jalr	-850(ra) # 80004b8a <end_op>
  return -1;
    80005ee4:	57fd                	li	a5,-1
}
    80005ee6:	853e                	mv	a0,a5
    80005ee8:	70b2                	ld	ra,296(sp)
    80005eea:	7412                	ld	s0,288(sp)
    80005eec:	64f2                	ld	s1,280(sp)
    80005eee:	6952                	ld	s2,272(sp)
    80005ef0:	6155                	add	sp,sp,304
    80005ef2:	8082                	ret

0000000080005ef4 <sys_unlink>:
{
    80005ef4:	7151                	add	sp,sp,-240
    80005ef6:	f586                	sd	ra,232(sp)
    80005ef8:	f1a2                	sd	s0,224(sp)
    80005efa:	eda6                	sd	s1,216(sp)
    80005efc:	e9ca                	sd	s2,208(sp)
    80005efe:	e5ce                	sd	s3,200(sp)
    80005f00:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005f02:	08000613          	li	a2,128
    80005f06:	f3040593          	add	a1,s0,-208
    80005f0a:	4501                	li	a0,0
    80005f0c:	ffffd097          	auipc	ra,0xffffd
    80005f10:	54e080e7          	jalr	1358(ra) # 8000345a <argstr>
    80005f14:	18054163          	bltz	a0,80006096 <sys_unlink+0x1a2>
  begin_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	bf8080e7          	jalr	-1032(ra) # 80004b10 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f20:	fb040593          	add	a1,s0,-80
    80005f24:	f3040513          	add	a0,s0,-208
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	a06080e7          	jalr	-1530(ra) # 8000492e <nameiparent>
    80005f30:	84aa                	mv	s1,a0
    80005f32:	c979                	beqz	a0,80006008 <sys_unlink+0x114>
  ilock(dp);
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	236080e7          	jalr	566(ra) # 8000416a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f3c:	00003597          	auipc	a1,0x3
    80005f40:	84c58593          	add	a1,a1,-1972 # 80008788 <syscalls+0x2e8>
    80005f44:	fb040513          	add	a0,s0,-80
    80005f48:	ffffe097          	auipc	ra,0xffffe
    80005f4c:	6ec080e7          	jalr	1772(ra) # 80004634 <namecmp>
    80005f50:	14050a63          	beqz	a0,800060a4 <sys_unlink+0x1b0>
    80005f54:	00003597          	auipc	a1,0x3
    80005f58:	83c58593          	add	a1,a1,-1988 # 80008790 <syscalls+0x2f0>
    80005f5c:	fb040513          	add	a0,s0,-80
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	6d4080e7          	jalr	1748(ra) # 80004634 <namecmp>
    80005f68:	12050e63          	beqz	a0,800060a4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f6c:	f2c40613          	add	a2,s0,-212
    80005f70:	fb040593          	add	a1,s0,-80
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	6d8080e7          	jalr	1752(ra) # 8000464e <dirlookup>
    80005f7e:	892a                	mv	s2,a0
    80005f80:	12050263          	beqz	a0,800060a4 <sys_unlink+0x1b0>
  ilock(ip);
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	1e6080e7          	jalr	486(ra) # 8000416a <ilock>
  if(ip->nlink < 1)
    80005f8c:	04a91783          	lh	a5,74(s2)
    80005f90:	08f05263          	blez	a5,80006014 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f94:	04491703          	lh	a4,68(s2)
    80005f98:	4785                	li	a5,1
    80005f9a:	08f70563          	beq	a4,a5,80006024 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f9e:	4641                	li	a2,16
    80005fa0:	4581                	li	a1,0
    80005fa2:	fc040513          	add	a0,s0,-64
    80005fa6:	ffffb097          	auipc	ra,0xffffb
    80005faa:	d28080e7          	jalr	-728(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fae:	4741                	li	a4,16
    80005fb0:	f2c42683          	lw	a3,-212(s0)
    80005fb4:	fc040613          	add	a2,s0,-64
    80005fb8:	4581                	li	a1,0
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	55a080e7          	jalr	1370(ra) # 80004516 <writei>
    80005fc4:	47c1                	li	a5,16
    80005fc6:	0af51563          	bne	a0,a5,80006070 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005fca:	04491703          	lh	a4,68(s2)
    80005fce:	4785                	li	a5,1
    80005fd0:	0af70863          	beq	a4,a5,80006080 <sys_unlink+0x18c>
  iunlockput(dp);
    80005fd4:	8526                	mv	a0,s1
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	3f6080e7          	jalr	1014(ra) # 800043cc <iunlockput>
  ip->nlink--;
    80005fde:	04a95783          	lhu	a5,74(s2)
    80005fe2:	37fd                	addw	a5,a5,-1
    80005fe4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fe8:	854a                	mv	a0,s2
    80005fea:	ffffe097          	auipc	ra,0xffffe
    80005fee:	0b4080e7          	jalr	180(ra) # 8000409e <iupdate>
  iunlockput(ip);
    80005ff2:	854a                	mv	a0,s2
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	3d8080e7          	jalr	984(ra) # 800043cc <iunlockput>
  end_op();
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	b8e080e7          	jalr	-1138(ra) # 80004b8a <end_op>
  return 0;
    80006004:	4501                	li	a0,0
    80006006:	a84d                	j	800060b8 <sys_unlink+0x1c4>
    end_op();
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	b82080e7          	jalr	-1150(ra) # 80004b8a <end_op>
    return -1;
    80006010:	557d                	li	a0,-1
    80006012:	a05d                	j	800060b8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006014:	00002517          	auipc	a0,0x2
    80006018:	78450513          	add	a0,a0,1924 # 80008798 <syscalls+0x2f8>
    8000601c:	ffffa097          	auipc	ra,0xffffa
    80006020:	520080e7          	jalr	1312(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006024:	04c92703          	lw	a4,76(s2)
    80006028:	02000793          	li	a5,32
    8000602c:	f6e7f9e3          	bgeu	a5,a4,80005f9e <sys_unlink+0xaa>
    80006030:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006034:	4741                	li	a4,16
    80006036:	86ce                	mv	a3,s3
    80006038:	f1840613          	add	a2,s0,-232
    8000603c:	4581                	li	a1,0
    8000603e:	854a                	mv	a0,s2
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	3de080e7          	jalr	990(ra) # 8000441e <readi>
    80006048:	47c1                	li	a5,16
    8000604a:	00f51b63          	bne	a0,a5,80006060 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000604e:	f1845783          	lhu	a5,-232(s0)
    80006052:	e7a1                	bnez	a5,8000609a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006054:	29c1                	addw	s3,s3,16
    80006056:	04c92783          	lw	a5,76(s2)
    8000605a:	fcf9ede3          	bltu	s3,a5,80006034 <sys_unlink+0x140>
    8000605e:	b781                	j	80005f9e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006060:	00002517          	auipc	a0,0x2
    80006064:	75050513          	add	a0,a0,1872 # 800087b0 <syscalls+0x310>
    80006068:	ffffa097          	auipc	ra,0xffffa
    8000606c:	4d4080e7          	jalr	1236(ra) # 8000053c <panic>
    panic("unlink: writei");
    80006070:	00002517          	auipc	a0,0x2
    80006074:	75850513          	add	a0,a0,1880 # 800087c8 <syscalls+0x328>
    80006078:	ffffa097          	auipc	ra,0xffffa
    8000607c:	4c4080e7          	jalr	1220(ra) # 8000053c <panic>
    dp->nlink--;
    80006080:	04a4d783          	lhu	a5,74(s1)
    80006084:	37fd                	addw	a5,a5,-1
    80006086:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000608a:	8526                	mv	a0,s1
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	012080e7          	jalr	18(ra) # 8000409e <iupdate>
    80006094:	b781                	j	80005fd4 <sys_unlink+0xe0>
    return -1;
    80006096:	557d                	li	a0,-1
    80006098:	a005                	j	800060b8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000609a:	854a                	mv	a0,s2
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	330080e7          	jalr	816(ra) # 800043cc <iunlockput>
  iunlockput(dp);
    800060a4:	8526                	mv	a0,s1
    800060a6:	ffffe097          	auipc	ra,0xffffe
    800060aa:	326080e7          	jalr	806(ra) # 800043cc <iunlockput>
  end_op();
    800060ae:	fffff097          	auipc	ra,0xfffff
    800060b2:	adc080e7          	jalr	-1316(ra) # 80004b8a <end_op>
  return -1;
    800060b6:	557d                	li	a0,-1
}
    800060b8:	70ae                	ld	ra,232(sp)
    800060ba:	740e                	ld	s0,224(sp)
    800060bc:	64ee                	ld	s1,216(sp)
    800060be:	694e                	ld	s2,208(sp)
    800060c0:	69ae                	ld	s3,200(sp)
    800060c2:	616d                	add	sp,sp,240
    800060c4:	8082                	ret

00000000800060c6 <sys_open>:

uint64
sys_open(void)
{
    800060c6:	7131                	add	sp,sp,-192
    800060c8:	fd06                	sd	ra,184(sp)
    800060ca:	f922                	sd	s0,176(sp)
    800060cc:	f526                	sd	s1,168(sp)
    800060ce:	f14a                	sd	s2,160(sp)
    800060d0:	ed4e                	sd	s3,152(sp)
    800060d2:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800060d4:	f4c40593          	add	a1,s0,-180
    800060d8:	4505                	li	a0,1
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	340080e7          	jalr	832(ra) # 8000341a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060e2:	08000613          	li	a2,128
    800060e6:	f5040593          	add	a1,s0,-176
    800060ea:	4501                	li	a0,0
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	36e080e7          	jalr	878(ra) # 8000345a <argstr>
    800060f4:	87aa                	mv	a5,a0
    return -1;
    800060f6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060f8:	0a07c863          	bltz	a5,800061a8 <sys_open+0xe2>

  begin_op();
    800060fc:	fffff097          	auipc	ra,0xfffff
    80006100:	a14080e7          	jalr	-1516(ra) # 80004b10 <begin_op>

  if(omode & O_CREATE){
    80006104:	f4c42783          	lw	a5,-180(s0)
    80006108:	2007f793          	and	a5,a5,512
    8000610c:	cbdd                	beqz	a5,800061c2 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000610e:	4681                	li	a3,0
    80006110:	4601                	li	a2,0
    80006112:	4589                	li	a1,2
    80006114:	f5040513          	add	a0,s0,-176
    80006118:	00000097          	auipc	ra,0x0
    8000611c:	97a080e7          	jalr	-1670(ra) # 80005a92 <create>
    80006120:	84aa                	mv	s1,a0
    if(ip == 0){
    80006122:	c951                	beqz	a0,800061b6 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006124:	04449703          	lh	a4,68(s1)
    80006128:	478d                	li	a5,3
    8000612a:	00f71763          	bne	a4,a5,80006138 <sys_open+0x72>
    8000612e:	0464d703          	lhu	a4,70(s1)
    80006132:	47a5                	li	a5,9
    80006134:	0ce7ec63          	bltu	a5,a4,8000620c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	de0080e7          	jalr	-544(ra) # 80004f18 <filealloc>
    80006140:	892a                	mv	s2,a0
    80006142:	c56d                	beqz	a0,8000622c <sys_open+0x166>
    80006144:	00000097          	auipc	ra,0x0
    80006148:	90c080e7          	jalr	-1780(ra) # 80005a50 <fdalloc>
    8000614c:	89aa                	mv	s3,a0
    8000614e:	0c054a63          	bltz	a0,80006222 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006152:	04449703          	lh	a4,68(s1)
    80006156:	478d                	li	a5,3
    80006158:	0ef70563          	beq	a4,a5,80006242 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000615c:	4789                	li	a5,2
    8000615e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80006162:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80006166:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000616a:	f4c42783          	lw	a5,-180(s0)
    8000616e:	0017c713          	xor	a4,a5,1
    80006172:	8b05                	and	a4,a4,1
    80006174:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006178:	0037f713          	and	a4,a5,3
    8000617c:	00e03733          	snez	a4,a4
    80006180:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006184:	4007f793          	and	a5,a5,1024
    80006188:	c791                	beqz	a5,80006194 <sys_open+0xce>
    8000618a:	04449703          	lh	a4,68(s1)
    8000618e:	4789                	li	a5,2
    80006190:	0cf70063          	beq	a4,a5,80006250 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80006194:	8526                	mv	a0,s1
    80006196:	ffffe097          	auipc	ra,0xffffe
    8000619a:	096080e7          	jalr	150(ra) # 8000422c <iunlock>
  end_op();
    8000619e:	fffff097          	auipc	ra,0xfffff
    800061a2:	9ec080e7          	jalr	-1556(ra) # 80004b8a <end_op>

  return fd;
    800061a6:	854e                	mv	a0,s3
}
    800061a8:	70ea                	ld	ra,184(sp)
    800061aa:	744a                	ld	s0,176(sp)
    800061ac:	74aa                	ld	s1,168(sp)
    800061ae:	790a                	ld	s2,160(sp)
    800061b0:	69ea                	ld	s3,152(sp)
    800061b2:	6129                	add	sp,sp,192
    800061b4:	8082                	ret
      end_op();
    800061b6:	fffff097          	auipc	ra,0xfffff
    800061ba:	9d4080e7          	jalr	-1580(ra) # 80004b8a <end_op>
      return -1;
    800061be:	557d                	li	a0,-1
    800061c0:	b7e5                	j	800061a8 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800061c2:	f5040513          	add	a0,s0,-176
    800061c6:	ffffe097          	auipc	ra,0xffffe
    800061ca:	74a080e7          	jalr	1866(ra) # 80004910 <namei>
    800061ce:	84aa                	mv	s1,a0
    800061d0:	c905                	beqz	a0,80006200 <sys_open+0x13a>
    ilock(ip);
    800061d2:	ffffe097          	auipc	ra,0xffffe
    800061d6:	f98080e7          	jalr	-104(ra) # 8000416a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800061da:	04449703          	lh	a4,68(s1)
    800061de:	4785                	li	a5,1
    800061e0:	f4f712e3          	bne	a4,a5,80006124 <sys_open+0x5e>
    800061e4:	f4c42783          	lw	a5,-180(s0)
    800061e8:	dba1                	beqz	a5,80006138 <sys_open+0x72>
      iunlockput(ip);
    800061ea:	8526                	mv	a0,s1
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	1e0080e7          	jalr	480(ra) # 800043cc <iunlockput>
      end_op();
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	996080e7          	jalr	-1642(ra) # 80004b8a <end_op>
      return -1;
    800061fc:	557d                	li	a0,-1
    800061fe:	b76d                	j	800061a8 <sys_open+0xe2>
      end_op();
    80006200:	fffff097          	auipc	ra,0xfffff
    80006204:	98a080e7          	jalr	-1654(ra) # 80004b8a <end_op>
      return -1;
    80006208:	557d                	li	a0,-1
    8000620a:	bf79                	j	800061a8 <sys_open+0xe2>
    iunlockput(ip);
    8000620c:	8526                	mv	a0,s1
    8000620e:	ffffe097          	auipc	ra,0xffffe
    80006212:	1be080e7          	jalr	446(ra) # 800043cc <iunlockput>
    end_op();
    80006216:	fffff097          	auipc	ra,0xfffff
    8000621a:	974080e7          	jalr	-1676(ra) # 80004b8a <end_op>
    return -1;
    8000621e:	557d                	li	a0,-1
    80006220:	b761                	j	800061a8 <sys_open+0xe2>
      fileclose(f);
    80006222:	854a                	mv	a0,s2
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	db0080e7          	jalr	-592(ra) # 80004fd4 <fileclose>
    iunlockput(ip);
    8000622c:	8526                	mv	a0,s1
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	19e080e7          	jalr	414(ra) # 800043cc <iunlockput>
    end_op();
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	954080e7          	jalr	-1708(ra) # 80004b8a <end_op>
    return -1;
    8000623e:	557d                	li	a0,-1
    80006240:	b7a5                	j	800061a8 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80006242:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80006246:	04649783          	lh	a5,70(s1)
    8000624a:	02f91223          	sh	a5,36(s2)
    8000624e:	bf21                	j	80006166 <sys_open+0xa0>
    itrunc(ip);
    80006250:	8526                	mv	a0,s1
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	026080e7          	jalr	38(ra) # 80004278 <itrunc>
    8000625a:	bf2d                	j	80006194 <sys_open+0xce>

000000008000625c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000625c:	7175                	add	sp,sp,-144
    8000625e:	e506                	sd	ra,136(sp)
    80006260:	e122                	sd	s0,128(sp)
    80006262:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	8ac080e7          	jalr	-1876(ra) # 80004b10 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000626c:	08000613          	li	a2,128
    80006270:	f7040593          	add	a1,s0,-144
    80006274:	4501                	li	a0,0
    80006276:	ffffd097          	auipc	ra,0xffffd
    8000627a:	1e4080e7          	jalr	484(ra) # 8000345a <argstr>
    8000627e:	02054963          	bltz	a0,800062b0 <sys_mkdir+0x54>
    80006282:	4681                	li	a3,0
    80006284:	4601                	li	a2,0
    80006286:	4585                	li	a1,1
    80006288:	f7040513          	add	a0,s0,-144
    8000628c:	00000097          	auipc	ra,0x0
    80006290:	806080e7          	jalr	-2042(ra) # 80005a92 <create>
    80006294:	cd11                	beqz	a0,800062b0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006296:	ffffe097          	auipc	ra,0xffffe
    8000629a:	136080e7          	jalr	310(ra) # 800043cc <iunlockput>
  end_op();
    8000629e:	fffff097          	auipc	ra,0xfffff
    800062a2:	8ec080e7          	jalr	-1812(ra) # 80004b8a <end_op>
  return 0;
    800062a6:	4501                	li	a0,0
}
    800062a8:	60aa                	ld	ra,136(sp)
    800062aa:	640a                	ld	s0,128(sp)
    800062ac:	6149                	add	sp,sp,144
    800062ae:	8082                	ret
    end_op();
    800062b0:	fffff097          	auipc	ra,0xfffff
    800062b4:	8da080e7          	jalr	-1830(ra) # 80004b8a <end_op>
    return -1;
    800062b8:	557d                	li	a0,-1
    800062ba:	b7fd                	j	800062a8 <sys_mkdir+0x4c>

00000000800062bc <sys_mknod>:

uint64
sys_mknod(void)
{
    800062bc:	7135                	add	sp,sp,-160
    800062be:	ed06                	sd	ra,152(sp)
    800062c0:	e922                	sd	s0,144(sp)
    800062c2:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800062c4:	fffff097          	auipc	ra,0xfffff
    800062c8:	84c080e7          	jalr	-1972(ra) # 80004b10 <begin_op>
  argint(1, &major);
    800062cc:	f6c40593          	add	a1,s0,-148
    800062d0:	4505                	li	a0,1
    800062d2:	ffffd097          	auipc	ra,0xffffd
    800062d6:	148080e7          	jalr	328(ra) # 8000341a <argint>
  argint(2, &minor);
    800062da:	f6840593          	add	a1,s0,-152
    800062de:	4509                	li	a0,2
    800062e0:	ffffd097          	auipc	ra,0xffffd
    800062e4:	13a080e7          	jalr	314(ra) # 8000341a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062e8:	08000613          	li	a2,128
    800062ec:	f7040593          	add	a1,s0,-144
    800062f0:	4501                	li	a0,0
    800062f2:	ffffd097          	auipc	ra,0xffffd
    800062f6:	168080e7          	jalr	360(ra) # 8000345a <argstr>
    800062fa:	02054b63          	bltz	a0,80006330 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062fe:	f6841683          	lh	a3,-152(s0)
    80006302:	f6c41603          	lh	a2,-148(s0)
    80006306:	458d                	li	a1,3
    80006308:	f7040513          	add	a0,s0,-144
    8000630c:	fffff097          	auipc	ra,0xfffff
    80006310:	786080e7          	jalr	1926(ra) # 80005a92 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006314:	cd11                	beqz	a0,80006330 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	0b6080e7          	jalr	182(ra) # 800043cc <iunlockput>
  end_op();
    8000631e:	fffff097          	auipc	ra,0xfffff
    80006322:	86c080e7          	jalr	-1940(ra) # 80004b8a <end_op>
  return 0;
    80006326:	4501                	li	a0,0
}
    80006328:	60ea                	ld	ra,152(sp)
    8000632a:	644a                	ld	s0,144(sp)
    8000632c:	610d                	add	sp,sp,160
    8000632e:	8082                	ret
    end_op();
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	85a080e7          	jalr	-1958(ra) # 80004b8a <end_op>
    return -1;
    80006338:	557d                	li	a0,-1
    8000633a:	b7fd                	j	80006328 <sys_mknod+0x6c>

000000008000633c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000633c:	7135                	add	sp,sp,-160
    8000633e:	ed06                	sd	ra,152(sp)
    80006340:	e922                	sd	s0,144(sp)
    80006342:	e526                	sd	s1,136(sp)
    80006344:	e14a                	sd	s2,128(sp)
    80006346:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	746080e7          	jalr	1862(ra) # 80001a8e <myproc>
    80006350:	892a                	mv	s2,a0
  
  begin_op();
    80006352:	ffffe097          	auipc	ra,0xffffe
    80006356:	7be080e7          	jalr	1982(ra) # 80004b10 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000635a:	08000613          	li	a2,128
    8000635e:	f6040593          	add	a1,s0,-160
    80006362:	4501                	li	a0,0
    80006364:	ffffd097          	auipc	ra,0xffffd
    80006368:	0f6080e7          	jalr	246(ra) # 8000345a <argstr>
    8000636c:	04054b63          	bltz	a0,800063c2 <sys_chdir+0x86>
    80006370:	f6040513          	add	a0,s0,-160
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	59c080e7          	jalr	1436(ra) # 80004910 <namei>
    8000637c:	84aa                	mv	s1,a0
    8000637e:	c131                	beqz	a0,800063c2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006380:	ffffe097          	auipc	ra,0xffffe
    80006384:	dea080e7          	jalr	-534(ra) # 8000416a <ilock>
  if(ip->type != T_DIR){
    80006388:	04449703          	lh	a4,68(s1)
    8000638c:	4785                	li	a5,1
    8000638e:	04f71063          	bne	a4,a5,800063ce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006392:	8526                	mv	a0,s1
    80006394:	ffffe097          	auipc	ra,0xffffe
    80006398:	e98080e7          	jalr	-360(ra) # 8000422c <iunlock>
  iput(p->cwd);
    8000639c:	15093503          	ld	a0,336(s2)
    800063a0:	ffffe097          	auipc	ra,0xffffe
    800063a4:	f84080e7          	jalr	-124(ra) # 80004324 <iput>
  end_op();
    800063a8:	ffffe097          	auipc	ra,0xffffe
    800063ac:	7e2080e7          	jalr	2018(ra) # 80004b8a <end_op>
  p->cwd = ip;
    800063b0:	14993823          	sd	s1,336(s2)
  return 0;
    800063b4:	4501                	li	a0,0
}
    800063b6:	60ea                	ld	ra,152(sp)
    800063b8:	644a                	ld	s0,144(sp)
    800063ba:	64aa                	ld	s1,136(sp)
    800063bc:	690a                	ld	s2,128(sp)
    800063be:	610d                	add	sp,sp,160
    800063c0:	8082                	ret
    end_op();
    800063c2:	ffffe097          	auipc	ra,0xffffe
    800063c6:	7c8080e7          	jalr	1992(ra) # 80004b8a <end_op>
    return -1;
    800063ca:	557d                	li	a0,-1
    800063cc:	b7ed                	j	800063b6 <sys_chdir+0x7a>
    iunlockput(ip);
    800063ce:	8526                	mv	a0,s1
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	ffc080e7          	jalr	-4(ra) # 800043cc <iunlockput>
    end_op();
    800063d8:	ffffe097          	auipc	ra,0xffffe
    800063dc:	7b2080e7          	jalr	1970(ra) # 80004b8a <end_op>
    return -1;
    800063e0:	557d                	li	a0,-1
    800063e2:	bfd1                	j	800063b6 <sys_chdir+0x7a>

00000000800063e4 <sys_exec>:

uint64
sys_exec(void)
{
    800063e4:	7121                	add	sp,sp,-448
    800063e6:	ff06                	sd	ra,440(sp)
    800063e8:	fb22                	sd	s0,432(sp)
    800063ea:	f726                	sd	s1,424(sp)
    800063ec:	f34a                	sd	s2,416(sp)
    800063ee:	ef4e                	sd	s3,408(sp)
    800063f0:	eb52                	sd	s4,400(sp)
    800063f2:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800063f4:	e4840593          	add	a1,s0,-440
    800063f8:	4505                	li	a0,1
    800063fa:	ffffd097          	auipc	ra,0xffffd
    800063fe:	040080e7          	jalr	64(ra) # 8000343a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006402:	08000613          	li	a2,128
    80006406:	f5040593          	add	a1,s0,-176
    8000640a:	4501                	li	a0,0
    8000640c:	ffffd097          	auipc	ra,0xffffd
    80006410:	04e080e7          	jalr	78(ra) # 8000345a <argstr>
    80006414:	87aa                	mv	a5,a0
    return -1;
    80006416:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006418:	0c07c263          	bltz	a5,800064dc <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    8000641c:	10000613          	li	a2,256
    80006420:	4581                	li	a1,0
    80006422:	e5040513          	add	a0,s0,-432
    80006426:	ffffb097          	auipc	ra,0xffffb
    8000642a:	8a8080e7          	jalr	-1880(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000642e:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006432:	89a6                	mv	s3,s1
    80006434:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006436:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000643a:	00391513          	sll	a0,s2,0x3
    8000643e:	e4040593          	add	a1,s0,-448
    80006442:	e4843783          	ld	a5,-440(s0)
    80006446:	953e                	add	a0,a0,a5
    80006448:	ffffd097          	auipc	ra,0xffffd
    8000644c:	f34080e7          	jalr	-204(ra) # 8000337c <fetchaddr>
    80006450:	02054a63          	bltz	a0,80006484 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006454:	e4043783          	ld	a5,-448(s0)
    80006458:	c3b9                	beqz	a5,8000649e <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	688080e7          	jalr	1672(ra) # 80000ae2 <kalloc>
    80006462:	85aa                	mv	a1,a0
    80006464:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006468:	cd11                	beqz	a0,80006484 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000646a:	6605                	lui	a2,0x1
    8000646c:	e4043503          	ld	a0,-448(s0)
    80006470:	ffffd097          	auipc	ra,0xffffd
    80006474:	f5e080e7          	jalr	-162(ra) # 800033ce <fetchstr>
    80006478:	00054663          	bltz	a0,80006484 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    8000647c:	0905                	add	s2,s2,1
    8000647e:	09a1                	add	s3,s3,8
    80006480:	fb491de3          	bne	s2,s4,8000643a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006484:	f5040913          	add	s2,s0,-176
    80006488:	6088                	ld	a0,0(s1)
    8000648a:	c921                	beqz	a0,800064da <sys_exec+0xf6>
    kfree(argv[i]);
    8000648c:	ffffa097          	auipc	ra,0xffffa
    80006490:	558080e7          	jalr	1368(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006494:	04a1                	add	s1,s1,8
    80006496:	ff2499e3          	bne	s1,s2,80006488 <sys_exec+0xa4>
  return -1;
    8000649a:	557d                	li	a0,-1
    8000649c:	a081                	j	800064dc <sys_exec+0xf8>
      argv[i] = 0;
    8000649e:	0009079b          	sext.w	a5,s2
    800064a2:	078e                	sll	a5,a5,0x3
    800064a4:	fd078793          	add	a5,a5,-48
    800064a8:	97a2                	add	a5,a5,s0
    800064aa:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800064ae:	e5040593          	add	a1,s0,-432
    800064b2:	f5040513          	add	a0,s0,-176
    800064b6:	fffff097          	auipc	ra,0xfffff
    800064ba:	194080e7          	jalr	404(ra) # 8000564a <exec>
    800064be:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064c0:	f5040993          	add	s3,s0,-176
    800064c4:	6088                	ld	a0,0(s1)
    800064c6:	c901                	beqz	a0,800064d6 <sys_exec+0xf2>
    kfree(argv[i]);
    800064c8:	ffffa097          	auipc	ra,0xffffa
    800064cc:	51c080e7          	jalr	1308(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064d0:	04a1                	add	s1,s1,8
    800064d2:	ff3499e3          	bne	s1,s3,800064c4 <sys_exec+0xe0>
  return ret;
    800064d6:	854a                	mv	a0,s2
    800064d8:	a011                	j	800064dc <sys_exec+0xf8>
  return -1;
    800064da:	557d                	li	a0,-1
}
    800064dc:	70fa                	ld	ra,440(sp)
    800064de:	745a                	ld	s0,432(sp)
    800064e0:	74ba                	ld	s1,424(sp)
    800064e2:	791a                	ld	s2,416(sp)
    800064e4:	69fa                	ld	s3,408(sp)
    800064e6:	6a5a                	ld	s4,400(sp)
    800064e8:	6139                	add	sp,sp,448
    800064ea:	8082                	ret

00000000800064ec <sys_pipe>:

uint64
sys_pipe(void)
{
    800064ec:	7139                	add	sp,sp,-64
    800064ee:	fc06                	sd	ra,56(sp)
    800064f0:	f822                	sd	s0,48(sp)
    800064f2:	f426                	sd	s1,40(sp)
    800064f4:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800064f6:	ffffb097          	auipc	ra,0xffffb
    800064fa:	598080e7          	jalr	1432(ra) # 80001a8e <myproc>
    800064fe:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006500:	fd840593          	add	a1,s0,-40
    80006504:	4501                	li	a0,0
    80006506:	ffffd097          	auipc	ra,0xffffd
    8000650a:	f34080e7          	jalr	-204(ra) # 8000343a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000650e:	fc840593          	add	a1,s0,-56
    80006512:	fd040513          	add	a0,s0,-48
    80006516:	fffff097          	auipc	ra,0xfffff
    8000651a:	dea080e7          	jalr	-534(ra) # 80005300 <pipealloc>
    return -1;
    8000651e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006520:	0c054463          	bltz	a0,800065e8 <sys_pipe+0xfc>
  fd0 = -1;
    80006524:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006528:	fd043503          	ld	a0,-48(s0)
    8000652c:	fffff097          	auipc	ra,0xfffff
    80006530:	524080e7          	jalr	1316(ra) # 80005a50 <fdalloc>
    80006534:	fca42223          	sw	a0,-60(s0)
    80006538:	08054b63          	bltz	a0,800065ce <sys_pipe+0xe2>
    8000653c:	fc843503          	ld	a0,-56(s0)
    80006540:	fffff097          	auipc	ra,0xfffff
    80006544:	510080e7          	jalr	1296(ra) # 80005a50 <fdalloc>
    80006548:	fca42023          	sw	a0,-64(s0)
    8000654c:	06054863          	bltz	a0,800065bc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006550:	4691                	li	a3,4
    80006552:	fc440613          	add	a2,s0,-60
    80006556:	fd843583          	ld	a1,-40(s0)
    8000655a:	68a8                	ld	a0,80(s1)
    8000655c:	ffffb097          	auipc	ra,0xffffb
    80006560:	10a080e7          	jalr	266(ra) # 80001666 <copyout>
    80006564:	02054063          	bltz	a0,80006584 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006568:	4691                	li	a3,4
    8000656a:	fc040613          	add	a2,s0,-64
    8000656e:	fd843583          	ld	a1,-40(s0)
    80006572:	0591                	add	a1,a1,4
    80006574:	68a8                	ld	a0,80(s1)
    80006576:	ffffb097          	auipc	ra,0xffffb
    8000657a:	0f0080e7          	jalr	240(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000657e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006580:	06055463          	bgez	a0,800065e8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006584:	fc442783          	lw	a5,-60(s0)
    80006588:	07e9                	add	a5,a5,26
    8000658a:	078e                	sll	a5,a5,0x3
    8000658c:	97a6                	add	a5,a5,s1
    8000658e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006592:	fc042783          	lw	a5,-64(s0)
    80006596:	07e9                	add	a5,a5,26
    80006598:	078e                	sll	a5,a5,0x3
    8000659a:	94be                	add	s1,s1,a5
    8000659c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800065a0:	fd043503          	ld	a0,-48(s0)
    800065a4:	fffff097          	auipc	ra,0xfffff
    800065a8:	a30080e7          	jalr	-1488(ra) # 80004fd4 <fileclose>
    fileclose(wf);
    800065ac:	fc843503          	ld	a0,-56(s0)
    800065b0:	fffff097          	auipc	ra,0xfffff
    800065b4:	a24080e7          	jalr	-1500(ra) # 80004fd4 <fileclose>
    return -1;
    800065b8:	57fd                	li	a5,-1
    800065ba:	a03d                	j	800065e8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800065bc:	fc442783          	lw	a5,-60(s0)
    800065c0:	0007c763          	bltz	a5,800065ce <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800065c4:	07e9                	add	a5,a5,26
    800065c6:	078e                	sll	a5,a5,0x3
    800065c8:	97a6                	add	a5,a5,s1
    800065ca:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800065ce:	fd043503          	ld	a0,-48(s0)
    800065d2:	fffff097          	auipc	ra,0xfffff
    800065d6:	a02080e7          	jalr	-1534(ra) # 80004fd4 <fileclose>
    fileclose(wf);
    800065da:	fc843503          	ld	a0,-56(s0)
    800065de:	fffff097          	auipc	ra,0xfffff
    800065e2:	9f6080e7          	jalr	-1546(ra) # 80004fd4 <fileclose>
    return -1;
    800065e6:	57fd                	li	a5,-1
}
    800065e8:	853e                	mv	a0,a5
    800065ea:	70e2                	ld	ra,56(sp)
    800065ec:	7442                	ld	s0,48(sp)
    800065ee:	74a2                	ld	s1,40(sp)
    800065f0:	6121                	add	sp,sp,64
    800065f2:	8082                	ret
	...

0000000080006600 <kernelvec>:
    80006600:	7111                	add	sp,sp,-256
    80006602:	e006                	sd	ra,0(sp)
    80006604:	e40a                	sd	sp,8(sp)
    80006606:	e80e                	sd	gp,16(sp)
    80006608:	ec12                	sd	tp,24(sp)
    8000660a:	f016                	sd	t0,32(sp)
    8000660c:	f41a                	sd	t1,40(sp)
    8000660e:	f81e                	sd	t2,48(sp)
    80006610:	fc22                	sd	s0,56(sp)
    80006612:	e0a6                	sd	s1,64(sp)
    80006614:	e4aa                	sd	a0,72(sp)
    80006616:	e8ae                	sd	a1,80(sp)
    80006618:	ecb2                	sd	a2,88(sp)
    8000661a:	f0b6                	sd	a3,96(sp)
    8000661c:	f4ba                	sd	a4,104(sp)
    8000661e:	f8be                	sd	a5,112(sp)
    80006620:	fcc2                	sd	a6,120(sp)
    80006622:	e146                	sd	a7,128(sp)
    80006624:	e54a                	sd	s2,136(sp)
    80006626:	e94e                	sd	s3,144(sp)
    80006628:	ed52                	sd	s4,152(sp)
    8000662a:	f156                	sd	s5,160(sp)
    8000662c:	f55a                	sd	s6,168(sp)
    8000662e:	f95e                	sd	s7,176(sp)
    80006630:	fd62                	sd	s8,184(sp)
    80006632:	e1e6                	sd	s9,192(sp)
    80006634:	e5ea                	sd	s10,200(sp)
    80006636:	e9ee                	sd	s11,208(sp)
    80006638:	edf2                	sd	t3,216(sp)
    8000663a:	f1f6                	sd	t4,224(sp)
    8000663c:	f5fa                	sd	t5,232(sp)
    8000663e:	f9fe                	sd	t6,240(sp)
    80006640:	c09fc0ef          	jal	80003248 <kerneltrap>
    80006644:	6082                	ld	ra,0(sp)
    80006646:	6122                	ld	sp,8(sp)
    80006648:	61c2                	ld	gp,16(sp)
    8000664a:	7282                	ld	t0,32(sp)
    8000664c:	7322                	ld	t1,40(sp)
    8000664e:	73c2                	ld	t2,48(sp)
    80006650:	7462                	ld	s0,56(sp)
    80006652:	6486                	ld	s1,64(sp)
    80006654:	6526                	ld	a0,72(sp)
    80006656:	65c6                	ld	a1,80(sp)
    80006658:	6666                	ld	a2,88(sp)
    8000665a:	7686                	ld	a3,96(sp)
    8000665c:	7726                	ld	a4,104(sp)
    8000665e:	77c6                	ld	a5,112(sp)
    80006660:	7866                	ld	a6,120(sp)
    80006662:	688a                	ld	a7,128(sp)
    80006664:	692a                	ld	s2,136(sp)
    80006666:	69ca                	ld	s3,144(sp)
    80006668:	6a6a                	ld	s4,152(sp)
    8000666a:	7a8a                	ld	s5,160(sp)
    8000666c:	7b2a                	ld	s6,168(sp)
    8000666e:	7bca                	ld	s7,176(sp)
    80006670:	7c6a                	ld	s8,184(sp)
    80006672:	6c8e                	ld	s9,192(sp)
    80006674:	6d2e                	ld	s10,200(sp)
    80006676:	6dce                	ld	s11,208(sp)
    80006678:	6e6e                	ld	t3,216(sp)
    8000667a:	7e8e                	ld	t4,224(sp)
    8000667c:	7f2e                	ld	t5,232(sp)
    8000667e:	7fce                	ld	t6,240(sp)
    80006680:	6111                	add	sp,sp,256
    80006682:	10200073          	sret
    80006686:	00000013          	nop
    8000668a:	00000013          	nop
    8000668e:	0001                	nop

0000000080006690 <timervec>:
    80006690:	34051573          	csrrw	a0,mscratch,a0
    80006694:	e10c                	sd	a1,0(a0)
    80006696:	e510                	sd	a2,8(a0)
    80006698:	e914                	sd	a3,16(a0)
    8000669a:	6d0c                	ld	a1,24(a0)
    8000669c:	7110                	ld	a2,32(a0)
    8000669e:	6194                	ld	a3,0(a1)
    800066a0:	96b2                	add	a3,a3,a2
    800066a2:	e194                	sd	a3,0(a1)
    800066a4:	4589                	li	a1,2
    800066a6:	14459073          	csrw	sip,a1
    800066aa:	6914                	ld	a3,16(a0)
    800066ac:	6510                	ld	a2,8(a0)
    800066ae:	610c                	ld	a1,0(a0)
    800066b0:	34051573          	csrrw	a0,mscratch,a0
    800066b4:	30200073          	mret
	...

00000000800066ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800066ba:	1141                	add	sp,sp,-16
    800066bc:	e422                	sd	s0,8(sp)
    800066be:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800066c0:	0c0007b7          	lui	a5,0xc000
    800066c4:	4705                	li	a4,1
    800066c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800066c8:	c3d8                	sw	a4,4(a5)
}
    800066ca:	6422                	ld	s0,8(sp)
    800066cc:	0141                	add	sp,sp,16
    800066ce:	8082                	ret

00000000800066d0 <plicinithart>:

void
plicinithart(void)
{
    800066d0:	1141                	add	sp,sp,-16
    800066d2:	e406                	sd	ra,8(sp)
    800066d4:	e022                	sd	s0,0(sp)
    800066d6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800066d8:	ffffb097          	auipc	ra,0xffffb
    800066dc:	38a080e7          	jalr	906(ra) # 80001a62 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800066e0:	0085171b          	sllw	a4,a0,0x8
    800066e4:	0c0027b7          	lui	a5,0xc002
    800066e8:	97ba                	add	a5,a5,a4
    800066ea:	40200713          	li	a4,1026
    800066ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066f2:	00d5151b          	sllw	a0,a0,0xd
    800066f6:	0c2017b7          	lui	a5,0xc201
    800066fa:	97aa                	add	a5,a5,a0
    800066fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006700:	60a2                	ld	ra,8(sp)
    80006702:	6402                	ld	s0,0(sp)
    80006704:	0141                	add	sp,sp,16
    80006706:	8082                	ret

0000000080006708 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006708:	1141                	add	sp,sp,-16
    8000670a:	e406                	sd	ra,8(sp)
    8000670c:	e022                	sd	s0,0(sp)
    8000670e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006710:	ffffb097          	auipc	ra,0xffffb
    80006714:	352080e7          	jalr	850(ra) # 80001a62 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006718:	00d5151b          	sllw	a0,a0,0xd
    8000671c:	0c2017b7          	lui	a5,0xc201
    80006720:	97aa                	add	a5,a5,a0
  return irq;
}
    80006722:	43c8                	lw	a0,4(a5)
    80006724:	60a2                	ld	ra,8(sp)
    80006726:	6402                	ld	s0,0(sp)
    80006728:	0141                	add	sp,sp,16
    8000672a:	8082                	ret

000000008000672c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000672c:	1101                	add	sp,sp,-32
    8000672e:	ec06                	sd	ra,24(sp)
    80006730:	e822                	sd	s0,16(sp)
    80006732:	e426                	sd	s1,8(sp)
    80006734:	1000                	add	s0,sp,32
    80006736:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006738:	ffffb097          	auipc	ra,0xffffb
    8000673c:	32a080e7          	jalr	810(ra) # 80001a62 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006740:	00d5151b          	sllw	a0,a0,0xd
    80006744:	0c2017b7          	lui	a5,0xc201
    80006748:	97aa                	add	a5,a5,a0
    8000674a:	c3c4                	sw	s1,4(a5)
}
    8000674c:	60e2                	ld	ra,24(sp)
    8000674e:	6442                	ld	s0,16(sp)
    80006750:	64a2                	ld	s1,8(sp)
    80006752:	6105                	add	sp,sp,32
    80006754:	8082                	ret

0000000080006756 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006756:	1141                	add	sp,sp,-16
    80006758:	e406                	sd	ra,8(sp)
    8000675a:	e022                	sd	s0,0(sp)
    8000675c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000675e:	479d                	li	a5,7
    80006760:	04a7cc63          	blt	a5,a0,800067b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006764:	0001f797          	auipc	a5,0x1f
    80006768:	74c78793          	add	a5,a5,1868 # 80025eb0 <disk>
    8000676c:	97aa                	add	a5,a5,a0
    8000676e:	0187c783          	lbu	a5,24(a5)
    80006772:	ebb9                	bnez	a5,800067c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006774:	00451693          	sll	a3,a0,0x4
    80006778:	0001f797          	auipc	a5,0x1f
    8000677c:	73878793          	add	a5,a5,1848 # 80025eb0 <disk>
    80006780:	6398                	ld	a4,0(a5)
    80006782:	9736                	add	a4,a4,a3
    80006784:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006788:	6398                	ld	a4,0(a5)
    8000678a:	9736                	add	a4,a4,a3
    8000678c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006790:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006794:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006798:	97aa                	add	a5,a5,a0
    8000679a:	4705                	li	a4,1
    8000679c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800067a0:	0001f517          	auipc	a0,0x1f
    800067a4:	72850513          	add	a0,a0,1832 # 80025ec8 <disk+0x18>
    800067a8:	ffffc097          	auipc	ra,0xffffc
    800067ac:	036080e7          	jalr	54(ra) # 800027de <wakeup>
}
    800067b0:	60a2                	ld	ra,8(sp)
    800067b2:	6402                	ld	s0,0(sp)
    800067b4:	0141                	add	sp,sp,16
    800067b6:	8082                	ret
    panic("free_desc 1");
    800067b8:	00002517          	auipc	a0,0x2
    800067bc:	02050513          	add	a0,a0,32 # 800087d8 <syscalls+0x338>
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	d7c080e7          	jalr	-644(ra) # 8000053c <panic>
    panic("free_desc 2");
    800067c8:	00002517          	auipc	a0,0x2
    800067cc:	02050513          	add	a0,a0,32 # 800087e8 <syscalls+0x348>
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	d6c080e7          	jalr	-660(ra) # 8000053c <panic>

00000000800067d8 <virtio_disk_init>:
{
    800067d8:	1101                	add	sp,sp,-32
    800067da:	ec06                	sd	ra,24(sp)
    800067dc:	e822                	sd	s0,16(sp)
    800067de:	e426                	sd	s1,8(sp)
    800067e0:	e04a                	sd	s2,0(sp)
    800067e2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067e4:	00002597          	auipc	a1,0x2
    800067e8:	01458593          	add	a1,a1,20 # 800087f8 <syscalls+0x358>
    800067ec:	0001f517          	auipc	a0,0x1f
    800067f0:	7ec50513          	add	a0,a0,2028 # 80025fd8 <disk+0x128>
    800067f4:	ffffa097          	auipc	ra,0xffffa
    800067f8:	34e080e7          	jalr	846(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067fc:	100017b7          	lui	a5,0x10001
    80006800:	4398                	lw	a4,0(a5)
    80006802:	2701                	sext.w	a4,a4
    80006804:	747277b7          	lui	a5,0x74727
    80006808:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000680c:	14f71b63          	bne	a4,a5,80006962 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006810:	100017b7          	lui	a5,0x10001
    80006814:	43dc                	lw	a5,4(a5)
    80006816:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006818:	4709                	li	a4,2
    8000681a:	14e79463          	bne	a5,a4,80006962 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000681e:	100017b7          	lui	a5,0x10001
    80006822:	479c                	lw	a5,8(a5)
    80006824:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006826:	12e79e63          	bne	a5,a4,80006962 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000682a:	100017b7          	lui	a5,0x10001
    8000682e:	47d8                	lw	a4,12(a5)
    80006830:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006832:	554d47b7          	lui	a5,0x554d4
    80006836:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000683a:	12f71463          	bne	a4,a5,80006962 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000683e:	100017b7          	lui	a5,0x10001
    80006842:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006846:	4705                	li	a4,1
    80006848:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000684a:	470d                	li	a4,3
    8000684c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000684e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006850:	c7ffe6b7          	lui	a3,0xc7ffe
    80006854:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd876f>
    80006858:	8f75                	and	a4,a4,a3
    8000685a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000685c:	472d                	li	a4,11
    8000685e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006860:	5bbc                	lw	a5,112(a5)
    80006862:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006866:	8ba1                	and	a5,a5,8
    80006868:	10078563          	beqz	a5,80006972 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000686c:	100017b7          	lui	a5,0x10001
    80006870:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006874:	43fc                	lw	a5,68(a5)
    80006876:	2781                	sext.w	a5,a5
    80006878:	10079563          	bnez	a5,80006982 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000687c:	100017b7          	lui	a5,0x10001
    80006880:	5bdc                	lw	a5,52(a5)
    80006882:	2781                	sext.w	a5,a5
  if(max == 0)
    80006884:	10078763          	beqz	a5,80006992 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006888:	471d                	li	a4,7
    8000688a:	10f77c63          	bgeu	a4,a5,800069a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000688e:	ffffa097          	auipc	ra,0xffffa
    80006892:	254080e7          	jalr	596(ra) # 80000ae2 <kalloc>
    80006896:	0001f497          	auipc	s1,0x1f
    8000689a:	61a48493          	add	s1,s1,1562 # 80025eb0 <disk>
    8000689e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800068a0:	ffffa097          	auipc	ra,0xffffa
    800068a4:	242080e7          	jalr	578(ra) # 80000ae2 <kalloc>
    800068a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800068aa:	ffffa097          	auipc	ra,0xffffa
    800068ae:	238080e7          	jalr	568(ra) # 80000ae2 <kalloc>
    800068b2:	87aa                	mv	a5,a0
    800068b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800068b6:	6088                	ld	a0,0(s1)
    800068b8:	cd6d                	beqz	a0,800069b2 <virtio_disk_init+0x1da>
    800068ba:	0001f717          	auipc	a4,0x1f
    800068be:	5fe73703          	ld	a4,1534(a4) # 80025eb8 <disk+0x8>
    800068c2:	cb65                	beqz	a4,800069b2 <virtio_disk_init+0x1da>
    800068c4:	c7fd                	beqz	a5,800069b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800068c6:	6605                	lui	a2,0x1
    800068c8:	4581                	li	a1,0
    800068ca:	ffffa097          	auipc	ra,0xffffa
    800068ce:	404080e7          	jalr	1028(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800068d2:	0001f497          	auipc	s1,0x1f
    800068d6:	5de48493          	add	s1,s1,1502 # 80025eb0 <disk>
    800068da:	6605                	lui	a2,0x1
    800068dc:	4581                	li	a1,0
    800068de:	6488                	ld	a0,8(s1)
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	3ee080e7          	jalr	1006(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800068e8:	6605                	lui	a2,0x1
    800068ea:	4581                	li	a1,0
    800068ec:	6888                	ld	a0,16(s1)
    800068ee:	ffffa097          	auipc	ra,0xffffa
    800068f2:	3e0080e7          	jalr	992(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068f6:	100017b7          	lui	a5,0x10001
    800068fa:	4721                	li	a4,8
    800068fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800068fe:	4098                	lw	a4,0(s1)
    80006900:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006904:	40d8                	lw	a4,4(s1)
    80006906:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000690a:	6498                	ld	a4,8(s1)
    8000690c:	0007069b          	sext.w	a3,a4
    80006910:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006914:	9701                	sra	a4,a4,0x20
    80006916:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000691a:	6898                	ld	a4,16(s1)
    8000691c:	0007069b          	sext.w	a3,a4
    80006920:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006924:	9701                	sra	a4,a4,0x20
    80006926:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000692a:	4705                	li	a4,1
    8000692c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000692e:	00e48c23          	sb	a4,24(s1)
    80006932:	00e48ca3          	sb	a4,25(s1)
    80006936:	00e48d23          	sb	a4,26(s1)
    8000693a:	00e48da3          	sb	a4,27(s1)
    8000693e:	00e48e23          	sb	a4,28(s1)
    80006942:	00e48ea3          	sb	a4,29(s1)
    80006946:	00e48f23          	sb	a4,30(s1)
    8000694a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000694e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006952:	0727a823          	sw	s2,112(a5)
}
    80006956:	60e2                	ld	ra,24(sp)
    80006958:	6442                	ld	s0,16(sp)
    8000695a:	64a2                	ld	s1,8(sp)
    8000695c:	6902                	ld	s2,0(sp)
    8000695e:	6105                	add	sp,sp,32
    80006960:	8082                	ret
    panic("could not find virtio disk");
    80006962:	00002517          	auipc	a0,0x2
    80006966:	ea650513          	add	a0,a0,-346 # 80008808 <syscalls+0x368>
    8000696a:	ffffa097          	auipc	ra,0xffffa
    8000696e:	bd2080e7          	jalr	-1070(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006972:	00002517          	auipc	a0,0x2
    80006976:	eb650513          	add	a0,a0,-330 # 80008828 <syscalls+0x388>
    8000697a:	ffffa097          	auipc	ra,0xffffa
    8000697e:	bc2080e7          	jalr	-1086(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006982:	00002517          	auipc	a0,0x2
    80006986:	ec650513          	add	a0,a0,-314 # 80008848 <syscalls+0x3a8>
    8000698a:	ffffa097          	auipc	ra,0xffffa
    8000698e:	bb2080e7          	jalr	-1102(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006992:	00002517          	auipc	a0,0x2
    80006996:	ed650513          	add	a0,a0,-298 # 80008868 <syscalls+0x3c8>
    8000699a:	ffffa097          	auipc	ra,0xffffa
    8000699e:	ba2080e7          	jalr	-1118(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800069a2:	00002517          	auipc	a0,0x2
    800069a6:	ee650513          	add	a0,a0,-282 # 80008888 <syscalls+0x3e8>
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	b92080e7          	jalr	-1134(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800069b2:	00002517          	auipc	a0,0x2
    800069b6:	ef650513          	add	a0,a0,-266 # 800088a8 <syscalls+0x408>
    800069ba:	ffffa097          	auipc	ra,0xffffa
    800069be:	b82080e7          	jalr	-1150(ra) # 8000053c <panic>

00000000800069c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800069c2:	7159                	add	sp,sp,-112
    800069c4:	f486                	sd	ra,104(sp)
    800069c6:	f0a2                	sd	s0,96(sp)
    800069c8:	eca6                	sd	s1,88(sp)
    800069ca:	e8ca                	sd	s2,80(sp)
    800069cc:	e4ce                	sd	s3,72(sp)
    800069ce:	e0d2                	sd	s4,64(sp)
    800069d0:	fc56                	sd	s5,56(sp)
    800069d2:	f85a                	sd	s6,48(sp)
    800069d4:	f45e                	sd	s7,40(sp)
    800069d6:	f062                	sd	s8,32(sp)
    800069d8:	ec66                	sd	s9,24(sp)
    800069da:	e86a                	sd	s10,16(sp)
    800069dc:	1880                	add	s0,sp,112
    800069de:	8a2a                	mv	s4,a0
    800069e0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800069e2:	00c52c83          	lw	s9,12(a0)
    800069e6:	001c9c9b          	sllw	s9,s9,0x1
    800069ea:	1c82                	sll	s9,s9,0x20
    800069ec:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800069f0:	0001f517          	auipc	a0,0x1f
    800069f4:	5e850513          	add	a0,a0,1512 # 80025fd8 <disk+0x128>
    800069f8:	ffffa097          	auipc	ra,0xffffa
    800069fc:	1da080e7          	jalr	474(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006a00:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006a02:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006a04:	0001fb17          	auipc	s6,0x1f
    80006a08:	4acb0b13          	add	s6,s6,1196 # 80025eb0 <disk>
  for(int i = 0; i < 3; i++){
    80006a0c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a0e:	0001fc17          	auipc	s8,0x1f
    80006a12:	5cac0c13          	add	s8,s8,1482 # 80025fd8 <disk+0x128>
    80006a16:	a095                	j	80006a7a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006a18:	00fb0733          	add	a4,s6,a5
    80006a1c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a20:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006a22:	0207c563          	bltz	a5,80006a4c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006a26:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006a28:	0591                	add	a1,a1,4
    80006a2a:	05560d63          	beq	a2,s5,80006a84 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006a2e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006a30:	0001f717          	auipc	a4,0x1f
    80006a34:	48070713          	add	a4,a4,1152 # 80025eb0 <disk>
    80006a38:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80006a3a:	01874683          	lbu	a3,24(a4)
    80006a3e:	fee9                	bnez	a3,80006a18 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006a40:	2785                	addw	a5,a5,1
    80006a42:	0705                	add	a4,a4,1
    80006a44:	fe979be3          	bne	a5,s1,80006a3a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006a48:	57fd                	li	a5,-1
    80006a4a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80006a4c:	00c05e63          	blez	a2,80006a68 <virtio_disk_rw+0xa6>
    80006a50:	060a                	sll	a2,a2,0x2
    80006a52:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006a56:	0009a503          	lw	a0,0(s3)
    80006a5a:	00000097          	auipc	ra,0x0
    80006a5e:	cfc080e7          	jalr	-772(ra) # 80006756 <free_desc>
      for(int j = 0; j < i; j++)
    80006a62:	0991                	add	s3,s3,4
    80006a64:	ffa999e3          	bne	s3,s10,80006a56 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a68:	85e2                	mv	a1,s8
    80006a6a:	0001f517          	auipc	a0,0x1f
    80006a6e:	45e50513          	add	a0,a0,1118 # 80025ec8 <disk+0x18>
    80006a72:	ffffc097          	auipc	ra,0xffffc
    80006a76:	d08080e7          	jalr	-760(ra) # 8000277a <sleep>
  for(int i = 0; i < 3; i++){
    80006a7a:	f9040993          	add	s3,s0,-112
{
    80006a7e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006a80:	864a                	mv	a2,s2
    80006a82:	b775                	j	80006a2e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a84:	f9042503          	lw	a0,-112(s0)
    80006a88:	00a50713          	add	a4,a0,10
    80006a8c:	0712                	sll	a4,a4,0x4

  if(write)
    80006a8e:	0001f797          	auipc	a5,0x1f
    80006a92:	42278793          	add	a5,a5,1058 # 80025eb0 <disk>
    80006a96:	00e786b3          	add	a3,a5,a4
    80006a9a:	01703633          	snez	a2,s7
    80006a9e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006aa0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006aa4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006aa8:	f6070613          	add	a2,a4,-160
    80006aac:	6394                	ld	a3,0(a5)
    80006aae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ab0:	00870593          	add	a1,a4,8
    80006ab4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006ab6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006ab8:	0007b803          	ld	a6,0(a5)
    80006abc:	9642                	add	a2,a2,a6
    80006abe:	46c1                	li	a3,16
    80006ac0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006ac2:	4585                	li	a1,1
    80006ac4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006ac8:	f9442683          	lw	a3,-108(s0)
    80006acc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ad0:	0692                	sll	a3,a3,0x4
    80006ad2:	9836                	add	a6,a6,a3
    80006ad4:	058a0613          	add	a2,s4,88
    80006ad8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006adc:	0007b803          	ld	a6,0(a5)
    80006ae0:	96c2                	add	a3,a3,a6
    80006ae2:	40000613          	li	a2,1024
    80006ae6:	c690                	sw	a2,8(a3)
  if(write)
    80006ae8:	001bb613          	seqz	a2,s7
    80006aec:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006af0:	00166613          	or	a2,a2,1
    80006af4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006af8:	f9842603          	lw	a2,-104(s0)
    80006afc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b00:	00250693          	add	a3,a0,2
    80006b04:	0692                	sll	a3,a3,0x4
    80006b06:	96be                	add	a3,a3,a5
    80006b08:	58fd                	li	a7,-1
    80006b0a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b0e:	0612                	sll	a2,a2,0x4
    80006b10:	9832                	add	a6,a6,a2
    80006b12:	f9070713          	add	a4,a4,-112
    80006b16:	973e                	add	a4,a4,a5
    80006b18:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006b1c:	6398                	ld	a4,0(a5)
    80006b1e:	9732                	add	a4,a4,a2
    80006b20:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b22:	4609                	li	a2,2
    80006b24:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006b28:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b2c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006b30:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b34:	6794                	ld	a3,8(a5)
    80006b36:	0026d703          	lhu	a4,2(a3)
    80006b3a:	8b1d                	and	a4,a4,7
    80006b3c:	0706                	sll	a4,a4,0x1
    80006b3e:	96ba                	add	a3,a3,a4
    80006b40:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006b44:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b48:	6798                	ld	a4,8(a5)
    80006b4a:	00275783          	lhu	a5,2(a4)
    80006b4e:	2785                	addw	a5,a5,1
    80006b50:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b54:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b58:	100017b7          	lui	a5,0x10001
    80006b5c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b60:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006b64:	0001f917          	auipc	s2,0x1f
    80006b68:	47490913          	add	s2,s2,1140 # 80025fd8 <disk+0x128>
  while(b->disk == 1) {
    80006b6c:	4485                	li	s1,1
    80006b6e:	00b79c63          	bne	a5,a1,80006b86 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006b72:	85ca                	mv	a1,s2
    80006b74:	8552                	mv	a0,s4
    80006b76:	ffffc097          	auipc	ra,0xffffc
    80006b7a:	c04080e7          	jalr	-1020(ra) # 8000277a <sleep>
  while(b->disk == 1) {
    80006b7e:	004a2783          	lw	a5,4(s4)
    80006b82:	fe9788e3          	beq	a5,s1,80006b72 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006b86:	f9042903          	lw	s2,-112(s0)
    80006b8a:	00290713          	add	a4,s2,2
    80006b8e:	0712                	sll	a4,a4,0x4
    80006b90:	0001f797          	auipc	a5,0x1f
    80006b94:	32078793          	add	a5,a5,800 # 80025eb0 <disk>
    80006b98:	97ba                	add	a5,a5,a4
    80006b9a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006b9e:	0001f997          	auipc	s3,0x1f
    80006ba2:	31298993          	add	s3,s3,786 # 80025eb0 <disk>
    80006ba6:	00491713          	sll	a4,s2,0x4
    80006baa:	0009b783          	ld	a5,0(s3)
    80006bae:	97ba                	add	a5,a5,a4
    80006bb0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006bb4:	854a                	mv	a0,s2
    80006bb6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006bba:	00000097          	auipc	ra,0x0
    80006bbe:	b9c080e7          	jalr	-1124(ra) # 80006756 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006bc2:	8885                	and	s1,s1,1
    80006bc4:	f0ed                	bnez	s1,80006ba6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006bc6:	0001f517          	auipc	a0,0x1f
    80006bca:	41250513          	add	a0,a0,1042 # 80025fd8 <disk+0x128>
    80006bce:	ffffa097          	auipc	ra,0xffffa
    80006bd2:	0b8080e7          	jalr	184(ra) # 80000c86 <release>
}
    80006bd6:	70a6                	ld	ra,104(sp)
    80006bd8:	7406                	ld	s0,96(sp)
    80006bda:	64e6                	ld	s1,88(sp)
    80006bdc:	6946                	ld	s2,80(sp)
    80006bde:	69a6                	ld	s3,72(sp)
    80006be0:	6a06                	ld	s4,64(sp)
    80006be2:	7ae2                	ld	s5,56(sp)
    80006be4:	7b42                	ld	s6,48(sp)
    80006be6:	7ba2                	ld	s7,40(sp)
    80006be8:	7c02                	ld	s8,32(sp)
    80006bea:	6ce2                	ld	s9,24(sp)
    80006bec:	6d42                	ld	s10,16(sp)
    80006bee:	6165                	add	sp,sp,112
    80006bf0:	8082                	ret

0000000080006bf2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006bf2:	1101                	add	sp,sp,-32
    80006bf4:	ec06                	sd	ra,24(sp)
    80006bf6:	e822                	sd	s0,16(sp)
    80006bf8:	e426                	sd	s1,8(sp)
    80006bfa:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006bfc:	0001f497          	auipc	s1,0x1f
    80006c00:	2b448493          	add	s1,s1,692 # 80025eb0 <disk>
    80006c04:	0001f517          	auipc	a0,0x1f
    80006c08:	3d450513          	add	a0,a0,980 # 80025fd8 <disk+0x128>
    80006c0c:	ffffa097          	auipc	ra,0xffffa
    80006c10:	fc6080e7          	jalr	-58(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006c14:	10001737          	lui	a4,0x10001
    80006c18:	533c                	lw	a5,96(a4)
    80006c1a:	8b8d                	and	a5,a5,3
    80006c1c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c1e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c22:	689c                	ld	a5,16(s1)
    80006c24:	0204d703          	lhu	a4,32(s1)
    80006c28:	0027d783          	lhu	a5,2(a5)
    80006c2c:	04f70863          	beq	a4,a5,80006c7c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006c30:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c34:	6898                	ld	a4,16(s1)
    80006c36:	0204d783          	lhu	a5,32(s1)
    80006c3a:	8b9d                	and	a5,a5,7
    80006c3c:	078e                	sll	a5,a5,0x3
    80006c3e:	97ba                	add	a5,a5,a4
    80006c40:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c42:	00278713          	add	a4,a5,2
    80006c46:	0712                	sll	a4,a4,0x4
    80006c48:	9726                	add	a4,a4,s1
    80006c4a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c4e:	e721                	bnez	a4,80006c96 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c50:	0789                	add	a5,a5,2
    80006c52:	0792                	sll	a5,a5,0x4
    80006c54:	97a6                	add	a5,a5,s1
    80006c56:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006c58:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c5c:	ffffc097          	auipc	ra,0xffffc
    80006c60:	b82080e7          	jalr	-1150(ra) # 800027de <wakeup>

    disk.used_idx += 1;
    80006c64:	0204d783          	lhu	a5,32(s1)
    80006c68:	2785                	addw	a5,a5,1
    80006c6a:	17c2                	sll	a5,a5,0x30
    80006c6c:	93c1                	srl	a5,a5,0x30
    80006c6e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c72:	6898                	ld	a4,16(s1)
    80006c74:	00275703          	lhu	a4,2(a4)
    80006c78:	faf71ce3          	bne	a4,a5,80006c30 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006c7c:	0001f517          	auipc	a0,0x1f
    80006c80:	35c50513          	add	a0,a0,860 # 80025fd8 <disk+0x128>
    80006c84:	ffffa097          	auipc	ra,0xffffa
    80006c88:	002080e7          	jalr	2(ra) # 80000c86 <release>
}
    80006c8c:	60e2                	ld	ra,24(sp)
    80006c8e:	6442                	ld	s0,16(sp)
    80006c90:	64a2                	ld	s1,8(sp)
    80006c92:	6105                	add	sp,sp,32
    80006c94:	8082                	ret
      panic("virtio_disk_intr status");
    80006c96:	00002517          	auipc	a0,0x2
    80006c9a:	c2a50513          	add	a0,a0,-982 # 800088c0 <syscalls+0x420>
    80006c9e:	ffffa097          	auipc	ra,0xffffa
    80006ca2:	89e080e7          	jalr	-1890(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
