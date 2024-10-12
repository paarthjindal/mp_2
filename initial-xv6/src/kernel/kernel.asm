
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
    80000066:	67e78793          	add	a5,a5,1662 # 800066e0 <timervec>
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
    8000012e:	b28080e7          	jalr	-1240(ra) # 80002c52 <either_copyin>
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
    800001b8:	90a080e7          	jalr	-1782(ra) # 80001abe <myproc>
    800001bc:	00003097          	auipc	ra,0x3
    800001c0:	8c8080e7          	jalr	-1848(ra) # 80002a84 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	606080e7          	jalr	1542(ra) # 800027d0 <sleep>
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
    80000214:	9ec080e7          	jalr	-1556(ra) # 80002bfc <either_copyout>
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
    800002f2:	9ba080e7          	jalr	-1606(ra) # 80002ca8 <procdump>
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
    80000446:	3f2080e7          	jalr	1010(ra) # 80002834 <wakeup>
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
    80000894:	fa4080e7          	jalr	-92(ra) # 80002834 <wakeup>
    
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
    8000091e:	eb6080e7          	jalr	-330(ra) # 800027d0 <sleep>
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
    80000b70:	f36080e7          	jalr	-202(ra) # 80001aa2 <mycpu>
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
    80000ba2:	f04080e7          	jalr	-252(ra) # 80001aa2 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	ef8080e7          	jalr	-264(ra) # 80001aa2 <mycpu>
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
    80000bc6:	ee0080e7          	jalr	-288(ra) # 80001aa2 <mycpu>
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
    80000c06:	ea0080e7          	jalr	-352(ra) # 80001aa2 <mycpu>
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
    80000c32:	e74080e7          	jalr	-396(ra) # 80001aa2 <mycpu>
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
    80000e7e:	c18080e7          	jalr	-1000(ra) # 80001a92 <cpuid>
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
    80000e9a:	bfc080e7          	jalr	-1028(ra) # 80001a92 <cpuid>
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
    80000ebc:	0dc080e7          	jalr	220(ra) # 80002f94 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00006097          	auipc	ra,0x6
    80000ec4:	860080e7          	jalr	-1952(ra) # 80006720 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	7c8080e7          	jalr	1992(ra) # 80002690 <scheduler>
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
    80000f2c:	ab6080e7          	jalr	-1354(ra) # 800019de <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	03c080e7          	jalr	60(ra) # 80002f6c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	05c080e7          	jalr	92(ra) # 80002f94 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	7ca080e7          	jalr	1994(ra) # 8000670a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	7d8080e7          	jalr	2008(ra) # 80006720 <plicinithart>
    binit();         // buffer cache
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	9d2080e7          	jalr	-1582(ra) # 80003922 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	070080e7          	jalr	112(ra) # 80003fc8 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	fe6080e7          	jalr	-26(ra) # 80004f46 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00006097          	auipc	ra,0x6
    80000f6c:	8c0080e7          	jalr	-1856(ra) # 80006828 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	e84080e7          	jalr	-380(ra) # 80001df4 <userinit>
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
    8000122c:	720080e7          	jalr	1824(ra) # 80001948 <proc_mapstacks>
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

void dequeue(int priority, struct proc *p)
{
    800018c8:	1141                	add	sp,sp,-16
    800018ca:	e422                	sd	s0,8(sp)
    800018cc:	0800                	add	s0,sp,16
  if (priority < 0 || priority >= total_queue)
    800018ce:	478d                	li	a5,3
    800018d0:	04a7e463          	bltu	a5,a0,80001918 <dequeue+0x50>
    800018d4:	86aa                	mv	a3,a0
  {
    return;
  }
  struct proc *prev = 0, *current = mlfq_queues[priority].head;
    800018d6:	00451713          	sll	a4,a0,0x4
    800018da:	0000f797          	auipc	a5,0xf
    800018de:	32678793          	add	a5,a5,806 # 80010c00 <mlfq_queues>
    800018e2:	97ba                	add	a5,a5,a4
    800018e4:	639c                	ld	a5,0(a5)

  // Traverse the queue and find the process to remove
  while (current != 0)
    800018e6:	cb8d                	beqz	a5,80001918 <dequeue+0x50>
  {
    if (current == p)
    800018e8:	02b78b63          	beq	a5,a1,8000191e <dequeue+0x56>
      }
      current->next = 0; // Disconnect the process
      return;
    }
    prev = current;
    current = current->next;
    800018ec:	873e                	mv	a4,a5
    800018ee:	2287b783          	ld	a5,552(a5)
  while (current != 0)
    800018f2:	c39d                	beqz	a5,80001918 <dequeue+0x50>
    if (current == p)
    800018f4:	fef59ce3          	bne	a1,a5,800018ec <dequeue+0x24>
        prev->next = current->next;
    800018f8:	2287b603          	ld	a2,552(a5)
    800018fc:	22c73423          	sd	a2,552(a4)
      if (current == mlfq_queues[priority].tail)
    80001900:	00469593          	sll	a1,a3,0x4
    80001904:	0000f617          	auipc	a2,0xf
    80001908:	2fc60613          	add	a2,a2,764 # 80010c00 <mlfq_queues>
    8000190c:	962e                	add	a2,a2,a1
    8000190e:	6610                	ld	a2,8(a2)
    80001910:	02f60463          	beq	a2,a5,80001938 <dequeue+0x70>
      current->next = 0; // Disconnect the process
    80001914:	2207b423          	sd	zero,552(a5)
  }
}
    80001918:	6422                	ld	s0,8(sp)
    8000191a:	0141                	add	sp,sp,16
    8000191c:	8082                	ret
        mlfq_queues[priority].head = current->next;
    8000191e:	00451713          	sll	a4,a0,0x4
    80001922:	0000f797          	auipc	a5,0xf
    80001926:	2de78793          	add	a5,a5,734 # 80010c00 <mlfq_queues>
    8000192a:	97ba                	add	a5,a5,a4
    8000192c:	2285b703          	ld	a4,552(a1)
    80001930:	e398                	sd	a4,0(a5)
    80001932:	87ae                	mv	a5,a1
    80001934:	4701                	li	a4,0
    80001936:	b7e9                	j	80001900 <dequeue+0x38>
        mlfq_queues[priority].tail = prev;
    80001938:	0000f617          	auipc	a2,0xf
    8000193c:	2c860613          	add	a2,a2,712 # 80010c00 <mlfq_queues>
    80001940:	00b606b3          	add	a3,a2,a1
    80001944:	e698                	sd	a4,8(a3)
    80001946:	b7f9                	j	80001914 <dequeue+0x4c>

0000000080001948 <proc_mapstacks>:

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001948:	7139                	add	sp,sp,-64
    8000194a:	fc06                	sd	ra,56(sp)
    8000194c:	f822                	sd	s0,48(sp)
    8000194e:	f426                	sd	s1,40(sp)
    80001950:	f04a                	sd	s2,32(sp)
    80001952:	ec4e                	sd	s3,24(sp)
    80001954:	e852                	sd	s4,16(sp)
    80001956:	e456                	sd	s5,8(sp)
    80001958:	e05a                	sd	s6,0(sp)
    8000195a:	0080                	add	s0,sp,64
    8000195c:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	00010497          	auipc	s1,0x10
    80001962:	6b248493          	add	s1,s1,1714 # 80012010 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001966:	8b26                	mv	s6,s1
    80001968:	00006a97          	auipc	s5,0x6
    8000196c:	698a8a93          	add	s5,s5,1688 # 80008000 <etext>
    80001970:	04000937          	lui	s2,0x4000
    80001974:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001976:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001978:	00019a17          	auipc	s4,0x19
    8000197c:	298a0a13          	add	s4,s4,664 # 8001ac10 <tickslock>
    char *pa = kalloc();
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	162080e7          	jalr	354(ra) # 80000ae2 <kalloc>
    80001988:	862a                	mv	a2,a0
    if (pa == 0)
    8000198a:	c131                	beqz	a0,800019ce <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000198c:	416485b3          	sub	a1,s1,s6
    80001990:	8591                	sra	a1,a1,0x4
    80001992:	000ab783          	ld	a5,0(s5)
    80001996:	02f585b3          	mul	a1,a1,a5
    8000199a:	2585                	addw	a1,a1,1
    8000199c:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019a0:	4719                	li	a4,6
    800019a2:	6685                	lui	a3,0x1
    800019a4:	40b905b3          	sub	a1,s2,a1
    800019a8:	854e                	mv	a0,s3
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	78e080e7          	jalr	1934(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019b2:	23048493          	add	s1,s1,560
    800019b6:	fd4495e3          	bne	s1,s4,80001980 <proc_mapstacks+0x38>
  }
}
    800019ba:	70e2                	ld	ra,56(sp)
    800019bc:	7442                	ld	s0,48(sp)
    800019be:	74a2                	ld	s1,40(sp)
    800019c0:	7902                	ld	s2,32(sp)
    800019c2:	69e2                	ld	s3,24(sp)
    800019c4:	6a42                	ld	s4,16(sp)
    800019c6:	6aa2                	ld	s5,8(sp)
    800019c8:	6b02                	ld	s6,0(sp)
    800019ca:	6121                	add	sp,sp,64
    800019cc:	8082                	ret
      panic("kalloc");
    800019ce:	00007517          	auipc	a0,0x7
    800019d2:	82250513          	add	a0,a0,-2014 # 800081f0 <digits+0x1b0>
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	b66080e7          	jalr	-1178(ra) # 8000053c <panic>

00000000800019de <procinit>:

// initialize the proc table.
void procinit(void)
{
    800019de:	7139                	add	sp,sp,-64
    800019e0:	fc06                	sd	ra,56(sp)
    800019e2:	f822                	sd	s0,48(sp)
    800019e4:	f426                	sd	s1,40(sp)
    800019e6:	f04a                	sd	s2,32(sp)
    800019e8:	ec4e                	sd	s3,24(sp)
    800019ea:	e852                	sd	s4,16(sp)
    800019ec:	e456                	sd	s5,8(sp)
    800019ee:	e05a                	sd	s6,0(sp)
    800019f0:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800019f2:	00007597          	auipc	a1,0x7
    800019f6:	80658593          	add	a1,a1,-2042 # 800081f8 <digits+0x1b8>
    800019fa:	0000f517          	auipc	a0,0xf
    800019fe:	24650513          	add	a0,a0,582 # 80010c40 <pid_lock>
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	140080e7          	jalr	320(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a0a:	00006597          	auipc	a1,0x6
    80001a0e:	7f658593          	add	a1,a1,2038 # 80008200 <digits+0x1c0>
    80001a12:	0000f517          	auipc	a0,0xf
    80001a16:	24650513          	add	a0,a0,582 # 80010c58 <wait_lock>
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	128080e7          	jalr	296(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a22:	00010497          	auipc	s1,0x10
    80001a26:	5ee48493          	add	s1,s1,1518 # 80012010 <proc>
  {
    initlock(&p->lock, "proc");
    80001a2a:	00006b17          	auipc	s6,0x6
    80001a2e:	7e6b0b13          	add	s6,s6,2022 # 80008210 <digits+0x1d0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a32:	8aa6                	mv	s5,s1
    80001a34:	00006a17          	auipc	s4,0x6
    80001a38:	5cca0a13          	add	s4,s4,1484 # 80008000 <etext>
    80001a3c:	04000937          	lui	s2,0x4000
    80001a40:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a42:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a44:	00019997          	auipc	s3,0x19
    80001a48:	1cc98993          	add	s3,s3,460 # 8001ac10 <tickslock>
    initlock(&p->lock, "proc");
    80001a4c:	85da                	mv	a1,s6
    80001a4e:	8526                	mv	a0,s1
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	0f2080e7          	jalr	242(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001a58:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a5c:	415487b3          	sub	a5,s1,s5
    80001a60:	8791                	sra	a5,a5,0x4
    80001a62:	000a3703          	ld	a4,0(s4)
    80001a66:	02e787b3          	mul	a5,a5,a4
    80001a6a:	2785                	addw	a5,a5,1
    80001a6c:	00d7979b          	sllw	a5,a5,0xd
    80001a70:	40f907b3          	sub	a5,s2,a5
    80001a74:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a76:	23048493          	add	s1,s1,560
    80001a7a:	fd3499e3          	bne	s1,s3,80001a4c <procinit+0x6e>
  }
}
    80001a7e:	70e2                	ld	ra,56(sp)
    80001a80:	7442                	ld	s0,48(sp)
    80001a82:	74a2                	ld	s1,40(sp)
    80001a84:	7902                	ld	s2,32(sp)
    80001a86:	69e2                	ld	s3,24(sp)
    80001a88:	6a42                	ld	s4,16(sp)
    80001a8a:	6aa2                	ld	s5,8(sp)
    80001a8c:	6b02                	ld	s6,0(sp)
    80001a8e:	6121                	add	sp,sp,64
    80001a90:	8082                	ret

0000000080001a92 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a92:	1141                	add	sp,sp,-16
    80001a94:	e422                	sd	s0,8(sp)
    80001a96:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a98:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a9a:	2501                	sext.w	a0,a0
    80001a9c:	6422                	ld	s0,8(sp)
    80001a9e:	0141                	add	sp,sp,16
    80001aa0:	8082                	ret

0000000080001aa2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001aa2:	1141                	add	sp,sp,-16
    80001aa4:	e422                	sd	s0,8(sp)
    80001aa6:	0800                	add	s0,sp,16
    80001aa8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aaa:	2781                	sext.w	a5,a5
    80001aac:	079e                	sll	a5,a5,0x7
  return c;
}
    80001aae:	0000f517          	auipc	a0,0xf
    80001ab2:	1c250513          	add	a0,a0,450 # 80010c70 <cpus>
    80001ab6:	953e                	add	a0,a0,a5
    80001ab8:	6422                	ld	s0,8(sp)
    80001aba:	0141                	add	sp,sp,16
    80001abc:	8082                	ret

0000000080001abe <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001abe:	1101                	add	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	1000                	add	s0,sp,32
  push_off();
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	0be080e7          	jalr	190(ra) # 80000b86 <push_off>
    80001ad0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ad2:	2781                	sext.w	a5,a5
    80001ad4:	079e                	sll	a5,a5,0x7
    80001ad6:	0000f717          	auipc	a4,0xf
    80001ada:	12a70713          	add	a4,a4,298 # 80010c00 <mlfq_queues>
    80001ade:	97ba                	add	a5,a5,a4
    80001ae0:	7ba4                	ld	s1,112(a5)
  pop_off();
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	144080e7          	jalr	324(ra) # 80000c26 <pop_off>
  return p;
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6105                	add	sp,sp,32
    80001af4:	8082                	ret

0000000080001af6 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001af6:	1141                	add	sp,sp,-16
    80001af8:	e406                	sd	ra,8(sp)
    80001afa:	e022                	sd	s0,0(sp)
    80001afc:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	fc0080e7          	jalr	-64(ra) # 80001abe <myproc>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	180080e7          	jalr	384(ra) # 80000c86 <release>

  if (first)
    80001b0e:	00007797          	auipc	a5,0x7
    80001b12:	dd27a783          	lw	a5,-558(a5) # 800088e0 <first.1>
    80001b16:	eb89                	bnez	a5,80001b28 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b18:	00001097          	auipc	ra,0x1
    80001b1c:	494080e7          	jalr	1172(ra) # 80002fac <usertrapret>
}
    80001b20:	60a2                	ld	ra,8(sp)
    80001b22:	6402                	ld	s0,0(sp)
    80001b24:	0141                	add	sp,sp,16
    80001b26:	8082                	ret
    first = 0;
    80001b28:	00007797          	auipc	a5,0x7
    80001b2c:	da07ac23          	sw	zero,-584(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001b30:	4505                	li	a0,1
    80001b32:	00002097          	auipc	ra,0x2
    80001b36:	416080e7          	jalr	1046(ra) # 80003f48 <fsinit>
    80001b3a:	bff9                	j	80001b18 <forkret+0x22>

0000000080001b3c <allocpid>:
{
    80001b3c:	1101                	add	sp,sp,-32
    80001b3e:	ec06                	sd	ra,24(sp)
    80001b40:	e822                	sd	s0,16(sp)
    80001b42:	e426                	sd	s1,8(sp)
    80001b44:	e04a                	sd	s2,0(sp)
    80001b46:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b48:	0000f917          	auipc	s2,0xf
    80001b4c:	0f890913          	add	s2,s2,248 # 80010c40 <pid_lock>
    80001b50:	854a                	mv	a0,s2
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	080080e7          	jalr	128(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	d9678793          	add	a5,a5,-618 # 800088f0 <nextpid>
    80001b62:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b64:	0014871b          	addw	a4,s1,1
    80001b68:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	11a080e7          	jalr	282(ra) # 80000c86 <release>
}
    80001b74:	8526                	mv	a0,s1
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	add	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <proc_pagetable>:
{
    80001b82:	1101                	add	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	e04a                	sd	s2,0(sp)
    80001b8c:	1000                	add	s0,sp,32
    80001b8e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	792080e7          	jalr	1938(ra) # 80001322 <uvmcreate>
    80001b98:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b9a:	c121                	beqz	a0,80001bda <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b9c:	4729                	li	a4,10
    80001b9e:	00005697          	auipc	a3,0x5
    80001ba2:	46268693          	add	a3,a3,1122 # 80007000 <_trampoline>
    80001ba6:	6605                	lui	a2,0x1
    80001ba8:	040005b7          	lui	a1,0x4000
    80001bac:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bae:	05b2                	sll	a1,a1,0xc
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	4e8080e7          	jalr	1256(ra) # 80001098 <mappages>
    80001bb8:	02054863          	bltz	a0,80001be8 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bbc:	4719                	li	a4,6
    80001bbe:	05893683          	ld	a3,88(s2)
    80001bc2:	6605                	lui	a2,0x1
    80001bc4:	020005b7          	lui	a1,0x2000
    80001bc8:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bca:	05b6                	sll	a1,a1,0xd
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	4ca080e7          	jalr	1226(ra) # 80001098 <mappages>
    80001bd6:	02054163          	bltz	a0,80001bf8 <proc_pagetable+0x76>
}
    80001bda:	8526                	mv	a0,s1
    80001bdc:	60e2                	ld	ra,24(sp)
    80001bde:	6442                	ld	s0,16(sp)
    80001be0:	64a2                	ld	s1,8(sp)
    80001be2:	6902                	ld	s2,0(sp)
    80001be4:	6105                	add	sp,sp,32
    80001be6:	8082                	ret
    uvmfree(pagetable, 0);
    80001be8:	4581                	li	a1,0
    80001bea:	8526                	mv	a0,s1
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	93c080e7          	jalr	-1732(ra) # 80001528 <uvmfree>
    return 0;
    80001bf4:	4481                	li	s1,0
    80001bf6:	b7d5                	j	80001bda <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf8:	4681                	li	a3,0
    80001bfa:	4605                	li	a2,1
    80001bfc:	040005b7          	lui	a1,0x4000
    80001c00:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c02:	05b2                	sll	a1,a1,0xc
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	658080e7          	jalr	1624(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001c0e:	4581                	li	a1,0
    80001c10:	8526                	mv	a0,s1
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	916080e7          	jalr	-1770(ra) # 80001528 <uvmfree>
    return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	bf7d                	j	80001bda <proc_pagetable+0x58>

0000000080001c1e <proc_freepagetable>:
{
    80001c1e:	1101                	add	sp,sp,-32
    80001c20:	ec06                	sd	ra,24(sp)
    80001c22:	e822                	sd	s0,16(sp)
    80001c24:	e426                	sd	s1,8(sp)
    80001c26:	e04a                	sd	s2,0(sp)
    80001c28:	1000                	add	s0,sp,32
    80001c2a:	84aa                	mv	s1,a0
    80001c2c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2e:	4681                	li	a3,0
    80001c30:	4605                	li	a2,1
    80001c32:	040005b7          	lui	a1,0x4000
    80001c36:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c38:	05b2                	sll	a1,a1,0xc
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	624080e7          	jalr	1572(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c42:	4681                	li	a3,0
    80001c44:	4605                	li	a2,1
    80001c46:	020005b7          	lui	a1,0x2000
    80001c4a:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c4c:	05b6                	sll	a1,a1,0xd
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	60e080e7          	jalr	1550(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c58:	85ca                	mv	a1,s2
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	8cc080e7          	jalr	-1844(ra) # 80001528 <uvmfree>
}
    80001c64:	60e2                	ld	ra,24(sp)
    80001c66:	6442                	ld	s0,16(sp)
    80001c68:	64a2                	ld	s1,8(sp)
    80001c6a:	6902                	ld	s2,0(sp)
    80001c6c:	6105                	add	sp,sp,32
    80001c6e:	8082                	ret

0000000080001c70 <freeproc>:
{
    80001c70:	1101                	add	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	add	s0,sp,32
    80001c7a:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c7c:	6d28                	ld	a0,88(a0)
    80001c7e:	c509                	beqz	a0,80001c88 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	d64080e7          	jalr	-668(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001c88:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c8c:	68a8                	ld	a0,80(s1)
    80001c8e:	c511                	beqz	a0,80001c9a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c90:	64ac                	ld	a1,72(s1)
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f8c080e7          	jalr	-116(ra) # 80001c1e <proc_freepagetable>
  p->pagetable = 0;
    80001c9a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c9e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ca6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001caa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cae:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cb2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cb6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cba:	0004ac23          	sw	zero,24(s1)
}
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6105                	add	sp,sp,32
    80001cc6:	8082                	ret

0000000080001cc8 <allocproc>:
{
    80001cc8:	1101                	add	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001cd4:	00010497          	auipc	s1,0x10
    80001cd8:	33c48493          	add	s1,s1,828 # 80012010 <proc>
    80001cdc:	00019917          	auipc	s2,0x19
    80001ce0:	f3490913          	add	s2,s2,-204 # 8001ac10 <tickslock>
    acquire(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	eec080e7          	jalr	-276(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001cee:	4c9c                	lw	a5,24(s1)
    80001cf0:	cf81                	beqz	a5,80001d08 <allocproc+0x40>
      release(&p->lock); // Release lock if not UNUSED
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f92080e7          	jalr	-110(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cfc:	23048493          	add	s1,s1,560
    80001d00:	ff2492e3          	bne	s1,s2,80001ce4 <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001d04:	4481                	li	s1,0
    80001d06:	a845                	j	80001db6 <allocproc+0xee>
  p->pid = allocpid(); // Assign PID
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	e34080e7          	jalr	-460(ra) # 80001b3c <allocpid>
    80001d10:	d888                	sw	a0,48(s1)
  p->state = USED;     // Mark process as USED
    80001d12:	4785                	li	a5,1
    80001d14:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < 31; i++)
    80001d16:	17448793          	add	a5,s1,372
    80001d1a:	1f048713          	add	a4,s1,496
    p->syscall_count[i] = 0;
    80001d1e:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < 31; i++)
    80001d22:	0791                	add	a5,a5,4
    80001d24:	fee79de3          	bne	a5,a4,80001d1e <allocproc+0x56>
  p->tickets = 1; // since by default a process should have 1 ticket
    80001d28:	4785                	li	a5,1
    80001d2a:	20f4a823          	sw	a5,528(s1)
  p->creation_time = ticks;
    80001d2e:	00007797          	auipc	a5,0x7
    80001d32:	c6a7e783          	lwu	a5,-918(a5) # 80008998 <ticks>
    80001d36:	20f4bc23          	sd	a5,536(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	da8080e7          	jalr	-600(ra) # 80000ae2 <kalloc>
    80001d42:	892a                	mv	s2,a0
    80001d44:	eca8                	sd	a0,88(s1)
    80001d46:	cd3d                	beqz	a0,80001dc4 <allocproc+0xfc>
  p->pagetable = proc_pagetable(p);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	e38080e7          	jalr	-456(ra) # 80001b82 <proc_pagetable>
    80001d52:	892a                	mv	s2,a0
    80001d54:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d56:	c159                	beqz	a0,80001ddc <allocproc+0x114>
  memset(&p->context, 0, sizeof(p->context));
    80001d58:	07000613          	li	a2,112
    80001d5c:	4581                	li	a1,0
    80001d5e:	06048513          	add	a0,s1,96
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f6c080e7          	jalr	-148(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001d6a:	00000797          	auipc	a5,0x0
    80001d6e:	d8c78793          	add	a5,a5,-628 # 80001af6 <forkret>
    80001d72:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d74:	60bc                	ld	a5,64(s1)
    80001d76:	6705                	lui	a4,0x1
    80001d78:	97ba                	add	a5,a5,a4
    80001d7a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;     // Initialize runtime
    80001d7c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;     // Initialize exit time
    80001d80:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks; // Record creation time
    80001d84:	00007797          	auipc	a5,0x7
    80001d88:	c147a783          	lw	a5,-1004(a5) # 80008998 <ticks>
    80001d8c:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001d90:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001d94:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001d98:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001d9c:	2004a223          	sw	zero,516(s1)
  p->priority = 0;              // Start in highest priority queue
    80001da0:	2204a023          	sw	zero,544(s1)
  p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    80001da4:	4785                	li	a5,1
    80001da6:	22f4a223          	sw	a5,548(s1)
  enqueue(0, p);                // Add to queue 0
    80001daa:	85a6                	mv	a1,s1
    80001dac:	4501                	li	a0,0
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	ab6080e7          	jalr	-1354(ra) # 80001864 <enqueue>
}
    80001db6:	8526                	mv	a0,s1
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6902                	ld	s2,0(sp)
    80001dc0:	6105                	add	sp,sp,32
    80001dc2:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001dc4:	8526                	mv	a0,s1
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	eaa080e7          	jalr	-342(ra) # 80001c70 <freeproc>
    release(&p->lock); // Release lock
    80001dce:	8526                	mv	a0,s1
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	eb6080e7          	jalr	-330(ra) # 80000c86 <release>
    return 0;
    80001dd8:	84ca                	mv	s1,s2
    80001dda:	bff1                	j	80001db6 <allocproc+0xee>
    freeproc(p);       // Clean up if allocation fails
    80001ddc:	8526                	mv	a0,s1
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	e92080e7          	jalr	-366(ra) # 80001c70 <freeproc>
    release(&p->lock); // Release lock
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	e9e080e7          	jalr	-354(ra) # 80000c86 <release>
    return 0;
    80001df0:	84ca                	mv	s1,s2
    80001df2:	b7d1                	j	80001db6 <allocproc+0xee>

0000000080001df4 <userinit>:
{
    80001df4:	1101                	add	sp,sp,-32
    80001df6:	ec06                	sd	ra,24(sp)
    80001df8:	e822                	sd	s0,16(sp)
    80001dfa:	e426                	sd	s1,8(sp)
    80001dfc:	1000                	add	s0,sp,32
  p = allocproc();
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	eca080e7          	jalr	-310(ra) # 80001cc8 <allocproc>
    80001e06:	84aa                	mv	s1,a0
  initproc = p;
    80001e08:	00007797          	auipc	a5,0x7
    80001e0c:	b8a7b423          	sd	a0,-1144(a5) # 80008990 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e10:	03400613          	li	a2,52
    80001e14:	00007597          	auipc	a1,0x7
    80001e18:	aec58593          	add	a1,a1,-1300 # 80008900 <initcode>
    80001e1c:	6928                	ld	a0,80(a0)
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	532080e7          	jalr	1330(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001e26:	6785                	lui	a5,0x1
    80001e28:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e2a:	6cb8                	ld	a4,88(s1)
    80001e2c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e30:	6cb8                	ld	a4,88(s1)
    80001e32:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e34:	4641                	li	a2,16
    80001e36:	00006597          	auipc	a1,0x6
    80001e3a:	3e258593          	add	a1,a1,994 # 80008218 <digits+0x1d8>
    80001e3e:	15848513          	add	a0,s1,344
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	fd4080e7          	jalr	-44(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001e4a:	00006517          	auipc	a0,0x6
    80001e4e:	3de50513          	add	a0,a0,990 # 80008228 <digits+0x1e8>
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	b14080e7          	jalr	-1260(ra) # 80004966 <namei>
    80001e5a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e5e:	478d                	li	a5,3
    80001e60:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001e62:	4785                	li	a5,1
    80001e64:	20f4a823          	sw	a5,528(s1)
  release(&p->lock);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1c080e7          	jalr	-484(ra) # 80000c86 <release>
}
    80001e72:	60e2                	ld	ra,24(sp)
    80001e74:	6442                	ld	s0,16(sp)
    80001e76:	64a2                	ld	s1,8(sp)
    80001e78:	6105                	add	sp,sp,32
    80001e7a:	8082                	ret

0000000080001e7c <growproc>:
{
    80001e7c:	1101                	add	sp,sp,-32
    80001e7e:	ec06                	sd	ra,24(sp)
    80001e80:	e822                	sd	s0,16(sp)
    80001e82:	e426                	sd	s1,8(sp)
    80001e84:	e04a                	sd	s2,0(sp)
    80001e86:	1000                	add	s0,sp,32
    80001e88:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e8a:	00000097          	auipc	ra,0x0
    80001e8e:	c34080e7          	jalr	-972(ra) # 80001abe <myproc>
    80001e92:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e94:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e96:	01204c63          	bgtz	s2,80001eae <growproc+0x32>
  else if (n < 0)
    80001e9a:	02094663          	bltz	s2,80001ec6 <growproc+0x4a>
  p->sz = sz;
    80001e9e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ea0:	4501                	li	a0,0
}
    80001ea2:	60e2                	ld	ra,24(sp)
    80001ea4:	6442                	ld	s0,16(sp)
    80001ea6:	64a2                	ld	s1,8(sp)
    80001ea8:	6902                	ld	s2,0(sp)
    80001eaa:	6105                	add	sp,sp,32
    80001eac:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001eae:	4691                	li	a3,4
    80001eb0:	00b90633          	add	a2,s2,a1
    80001eb4:	6928                	ld	a0,80(a0)
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	554080e7          	jalr	1364(ra) # 8000140a <uvmalloc>
    80001ebe:	85aa                	mv	a1,a0
    80001ec0:	fd79                	bnez	a0,80001e9e <growproc+0x22>
      return -1;
    80001ec2:	557d                	li	a0,-1
    80001ec4:	bff9                	j	80001ea2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ec6:	00b90633          	add	a2,s2,a1
    80001eca:	6928                	ld	a0,80(a0)
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	4f6080e7          	jalr	1270(ra) # 800013c2 <uvmdealloc>
    80001ed4:	85aa                	mv	a1,a0
    80001ed6:	b7e1                	j	80001e9e <growproc+0x22>

0000000080001ed8 <fork>:
{
    80001ed8:	7139                	add	sp,sp,-64
    80001eda:	fc06                	sd	ra,56(sp)
    80001edc:	f822                	sd	s0,48(sp)
    80001ede:	f426                	sd	s1,40(sp)
    80001ee0:	f04a                	sd	s2,32(sp)
    80001ee2:	ec4e                	sd	s3,24(sp)
    80001ee4:	e852                	sd	s4,16(sp)
    80001ee6:	e456                	sd	s5,8(sp)
    80001ee8:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	bd4080e7          	jalr	-1068(ra) # 80001abe <myproc>
    80001ef2:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ef4:	00000097          	auipc	ra,0x0
    80001ef8:	dd4080e7          	jalr	-556(ra) # 80001cc8 <allocproc>
    80001efc:	12050663          	beqz	a0,80002028 <fork+0x150>
    80001f00:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f02:	048ab603          	ld	a2,72(s5)
    80001f06:	692c                	ld	a1,80(a0)
    80001f08:	050ab503          	ld	a0,80(s5)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	656080e7          	jalr	1622(ra) # 80001562 <uvmcopy>
    80001f14:	06054263          	bltz	a0,80001f78 <fork+0xa0>
  np->sz = p->sz;
    80001f18:	048ab783          	ld	a5,72(s5)
    80001f1c:	04f9b423          	sd	a5,72(s3)
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
    80001f20:	210aa783          	lw	a5,528(s5)
    80001f24:	20f9a823          	sw	a5,528(s3)
  np->creation_time = ticks; // record its creation time
    80001f28:	00007797          	auipc	a5,0x7
    80001f2c:	a707e783          	lwu	a5,-1424(a5) # 80008998 <ticks>
    80001f30:	20f9bc23          	sd	a5,536(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f34:	058ab683          	ld	a3,88(s5)
    80001f38:	87b6                	mv	a5,a3
    80001f3a:	0589b703          	ld	a4,88(s3)
    80001f3e:	12068693          	add	a3,a3,288
    80001f42:	0007b803          	ld	a6,0(a5)
    80001f46:	6788                	ld	a0,8(a5)
    80001f48:	6b8c                	ld	a1,16(a5)
    80001f4a:	6f90                	ld	a2,24(a5)
    80001f4c:	01073023          	sd	a6,0(a4)
    80001f50:	e708                	sd	a0,8(a4)
    80001f52:	eb0c                	sd	a1,16(a4)
    80001f54:	ef10                	sd	a2,24(a4)
    80001f56:	02078793          	add	a5,a5,32
    80001f5a:	02070713          	add	a4,a4,32
    80001f5e:	fed792e3          	bne	a5,a3,80001f42 <fork+0x6a>
  np->trapframe->a0 = 0;
    80001f62:	0589b783          	ld	a5,88(s3)
    80001f66:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f6a:	0d0a8493          	add	s1,s5,208
    80001f6e:	0d098913          	add	s2,s3,208
    80001f72:	150a8a13          	add	s4,s5,336
    80001f76:	a00d                	j	80001f98 <fork+0xc0>
    freeproc(np);
    80001f78:	854e                	mv	a0,s3
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	cf6080e7          	jalr	-778(ra) # 80001c70 <freeproc>
    release(&np->lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d02080e7          	jalr	-766(ra) # 80000c86 <release>
    return -1;
    80001f8c:	597d                	li	s2,-1
    80001f8e:	a059                	j	80002014 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    80001f90:	04a1                	add	s1,s1,8
    80001f92:	0921                	add	s2,s2,8
    80001f94:	01448b63          	beq	s1,s4,80001faa <fork+0xd2>
    if (p->ofile[i])
    80001f98:	6088                	ld	a0,0(s1)
    80001f9a:	d97d                	beqz	a0,80001f90 <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f9c:	00003097          	auipc	ra,0x3
    80001fa0:	03c080e7          	jalr	60(ra) # 80004fd8 <filedup>
    80001fa4:	00a93023          	sd	a0,0(s2)
    80001fa8:	b7e5                	j	80001f90 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001faa:	150ab503          	ld	a0,336(s5)
    80001fae:	00002097          	auipc	ra,0x2
    80001fb2:	1d4080e7          	jalr	468(ra) # 80004182 <idup>
    80001fb6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fba:	4641                	li	a2,16
    80001fbc:	158a8593          	add	a1,s5,344
    80001fc0:	15898513          	add	a0,s3,344
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	e52080e7          	jalr	-430(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001fcc:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001fd0:	854e                	mv	a0,s3
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	cb4080e7          	jalr	-844(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001fda:	0000f497          	auipc	s1,0xf
    80001fde:	c7e48493          	add	s1,s1,-898 # 80010c58 <wait_lock>
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	bee080e7          	jalr	-1042(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001fec:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	c94080e7          	jalr	-876(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ffa:	854e                	mv	a0,s3
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	bd6080e7          	jalr	-1066(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80002004:	478d                	li	a5,3
    80002006:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000200a:	854e                	mv	a0,s3
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c7a080e7          	jalr	-902(ra) # 80000c86 <release>
}
    80002014:	854a                	mv	a0,s2
    80002016:	70e2                	ld	ra,56(sp)
    80002018:	7442                	ld	s0,48(sp)
    8000201a:	74a2                	ld	s1,40(sp)
    8000201c:	7902                	ld	s2,32(sp)
    8000201e:	69e2                	ld	s3,24(sp)
    80002020:	6a42                	ld	s4,16(sp)
    80002022:	6aa2                	ld	s5,8(sp)
    80002024:	6121                	add	sp,sp,64
    80002026:	8082                	ret
    return -1;
    80002028:	597d                	li	s2,-1
    8000202a:	b7ed                	j	80002014 <fork+0x13c>

000000008000202c <simple_atol>:
{
    8000202c:	1141                	add	sp,sp,-16
    8000202e:	e422                	sd	s0,8(sp)
    80002030:	0800                	add	s0,sp,16
  for (int i = 0; str[i] != '\0'; ++i)
    80002032:	00054683          	lbu	a3,0(a0)
    80002036:	c295                	beqz	a3,8000205a <simple_atol+0x2e>
    80002038:	00150713          	add	a4,a0,1
  long res = 0;
    8000203c:	4501                	li	a0,0
    res = res * 10 + str[i] - '0';
    8000203e:	00251793          	sll	a5,a0,0x2
    80002042:	97aa                	add	a5,a5,a0
    80002044:	0786                	sll	a5,a5,0x1
    80002046:	97b6                	add	a5,a5,a3
    80002048:	fd078513          	add	a0,a5,-48
  for (int i = 0; str[i] != '\0'; ++i)
    8000204c:	0705                	add	a4,a4,1
    8000204e:	fff74683          	lbu	a3,-1(a4)
    80002052:	f6f5                	bnez	a3,8000203e <simple_atol+0x12>
}
    80002054:	6422                	ld	s0,8(sp)
    80002056:	0141                	add	sp,sp,16
    80002058:	8082                	ret
  long res = 0;
    8000205a:	4501                	li	a0,0
  return res;
    8000205c:	bfe5                	j	80002054 <simple_atol+0x28>

000000008000205e <get_random_seed>:
{
    8000205e:	1141                	add	sp,sp,-16
    80002060:	e422                	sd	s0,8(sp)
    80002062:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80002064:	00007697          	auipc	a3,0x7
    80002068:	88468693          	add	a3,a3,-1916 # 800088e8 <seed>
    8000206c:	629c                	ld	a5,0(a3)
    8000206e:	41c65737          	lui	a4,0x41c65
    80002072:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80002076:	02e787b3          	mul	a5,a5,a4
    8000207a:	670d                	lui	a4,0x3
    8000207c:	03970713          	add	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80002080:	97ba                	add	a5,a5,a4
    80002082:	1786                	sll	a5,a5,0x21
    80002084:	9385                	srl	a5,a5,0x21
    80002086:	e29c                	sd	a5,0(a3)
}
    80002088:	6509                	lui	a0,0x2
    8000208a:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    8000208e:	02a7f533          	remu	a0,a5,a0
    80002092:	6422                	ld	s0,8(sp)
    80002094:	0141                	add	sp,sp,16
    80002096:	8082                	ret

0000000080002098 <long_to_padded_string>:
{
    80002098:	1141                	add	sp,sp,-16
    8000209a:	e422                	sd	s0,8(sp)
    8000209c:	0800                	add	s0,sp,16
  long temp = num;
    8000209e:	87aa                	mv	a5,a0
  int len = 0;
    800020a0:	4681                	li	a3,0
    temp /= 10;
    800020a2:	4329                	li	t1,10
  } while (temp > 0);
    800020a4:	48a5                	li	a7,9
    len++;
    800020a6:	0016871b          	addw	a4,a3,1
    800020aa:	0007069b          	sext.w	a3,a4
    temp /= 10;
    800020ae:	883e                	mv	a6,a5
    800020b0:	0267c7b3          	div	a5,a5,t1
  } while (temp > 0);
    800020b4:	ff08c9e3          	blt	a7,a6,800020a6 <long_to_padded_string+0xe>
  int padding = total_length - len;
    800020b8:	40e5873b          	subw	a4,a1,a4
    800020bc:	0007089b          	sext.w	a7,a4
  for (int i = 0; i < padding; i++)
    800020c0:	01105c63          	blez	a7,800020d8 <long_to_padded_string+0x40>
    800020c4:	87b2                	mv	a5,a2
    800020c6:	00c88833          	add	a6,a7,a2
    result[i] = '0';
    800020ca:	03000693          	li	a3,48
    800020ce:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < padding; i++)
    800020d2:	0785                	add	a5,a5,1
    800020d4:	ff079de3          	bne	a5,a6,800020ce <long_to_padded_string+0x36>
  for (int i = total_length - 1; i >= padding; i--)
    800020d8:	fff5879b          	addw	a5,a1,-1
    800020dc:	0317ca63          	blt	a5,a7,80002110 <long_to_padded_string+0x78>
    800020e0:	97b2                	add	a5,a5,a2
    800020e2:	ffe60813          	add	a6,a2,-2 # ffe <_entry-0x7ffff002>
    800020e6:	982e                	add	a6,a6,a1
    800020e8:	fff5869b          	addw	a3,a1,-1
    800020ec:	40e6873b          	subw	a4,a3,a4
    800020f0:	1702                	sll	a4,a4,0x20
    800020f2:	9301                	srl	a4,a4,0x20
    800020f4:	40e80833          	sub	a6,a6,a4
    result[i] = (num % 10) + '0';
    800020f8:	46a9                	li	a3,10
    800020fa:	02d56733          	rem	a4,a0,a3
    800020fe:	0307071b          	addw	a4,a4,48
    80002102:	00e78023          	sb	a4,0(a5)
    num /= 10;
    80002106:	02d54533          	div	a0,a0,a3
  for (int i = total_length - 1; i >= padding; i--)
    8000210a:	17fd                	add	a5,a5,-1
    8000210c:	ff0797e3          	bne	a5,a6,800020fa <long_to_padded_string+0x62>
  result[total_length] = '\0'; // Null-terminate the string
    80002110:	962e                	add	a2,a2,a1
    80002112:	00060023          	sb	zero,0(a2)
}
    80002116:	6422                	ld	s0,8(sp)
    80002118:	0141                	add	sp,sp,16
    8000211a:	8082                	ret

000000008000211c <pseudo_rand_num_generator>:
{
    8000211c:	7119                	add	sp,sp,-128
    8000211e:	fc86                	sd	ra,120(sp)
    80002120:	f8a2                	sd	s0,112(sp)
    80002122:	f4a6                	sd	s1,104(sp)
    80002124:	f0ca                	sd	s2,96(sp)
    80002126:	ecce                	sd	s3,88(sp)
    80002128:	e8d2                	sd	s4,80(sp)
    8000212a:	e4d6                	sd	s5,72(sp)
    8000212c:	e0da                	sd	s6,64(sp)
    8000212e:	fc5e                	sd	s7,56(sp)
    80002130:	f862                	sd	s8,48(sp)
    80002132:	f466                	sd	s9,40(sp)
    80002134:	0100                	add	s0,sp,128
    80002136:	84aa                	mv	s1,a0
    80002138:	8aae                	mv	s5,a1
  if (iterations == 0 && lst_index > 0)
    8000213a:	e1a1                	bnez	a1,8000217a <pseudo_rand_num_generator+0x5e>
    8000213c:	00007797          	auipc	a5,0x7
    80002140:	8507a783          	lw	a5,-1968(a5) # 8000898c <lst_index>
    80002144:	02f04263          	bgtz	a5,80002168 <pseudo_rand_num_generator+0x4c>
  int seed_size = strlen(initial_seed);
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	d00080e7          	jalr	-768(ra) # 80000e48 <strlen>
    80002150:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002152:	8526                	mv	a0,s1
    80002154:	00000097          	auipc	ra,0x0
    80002158:	ed8080e7          	jalr	-296(ra) # 8000202c <simple_atol>
  if (seed_val == 0)
    8000215c:	e561                	bnez	a0,80002224 <pseudo_rand_num_generator+0x108>
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	f00080e7          	jalr	-256(ra) # 8000205e <get_random_seed>
    80002166:	a02d                	j	80002190 <pseudo_rand_num_generator+0x74>
    return lst[lst_index - 1]; // Return the last generated number
    80002168:	37fd                	addw	a5,a5,-1
    8000216a:	078a                	sll	a5,a5,0x2
    8000216c:	0000f717          	auipc	a4,0xf
    80002170:	f0470713          	add	a4,a4,-252 # 80011070 <lst>
    80002174:	97ba                	add	a5,a5,a4
    80002176:	4388                	lw	a0,0(a5)
    80002178:	a0d1                	j	8000223c <pseudo_rand_num_generator+0x120>
  int seed_size = strlen(initial_seed);
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	cce080e7          	jalr	-818(ra) # 80000e48 <strlen>
    80002182:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002184:	8526                	mv	a0,s1
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	ea6080e7          	jalr	-346(ra) # 8000202c <simple_atol>
  if (seed_val == 0)
    8000218e:	d961                	beqz	a0,8000215e <pseudo_rand_num_generator+0x42>
  for (int i = 0; i < iterations; i++)
    80002190:	09505a63          	blez	s5,80002224 <pseudo_rand_num_generator+0x108>
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    80002194:	00191c9b          	sllw	s9,s2,0x1
    int mid_start = seed_size / 2;
    80002198:	01f9579b          	srlw	a5,s2,0x1f
    8000219c:	012787bb          	addw	a5,a5,s2
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800021a0:	4017d79b          	sraw	a5,a5,0x1
    800021a4:	f8040713          	add	a4,s0,-128
    800021a8:	00f70bb3          	add	s7,a4,a5
    800021ac:	4481                	li	s1,0
    char new_seed[seed_size + 1];
    800021ae:	00190b1b          	addw	s6,s2,1
    800021b2:	0b3d                	add	s6,s6,15
    800021b4:	ff0b7b13          	and	s6,s6,-16
    lst[lst_index++] = simple_atol(new_seed);
    800021b8:	00006997          	auipc	s3,0x6
    800021bc:	7d498993          	add	s3,s3,2004 # 8000898c <lst_index>
    800021c0:	0000fc17          	auipc	s8,0xf
    800021c4:	eb0c0c13          	add	s8,s8,-336 # 80011070 <lst>
  {
    800021c8:	8a0a                	mv	s4,sp
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    800021ca:	f8040613          	add	a2,s0,-128
    800021ce:	85e6                	mv	a1,s9
    800021d0:	02a50533          	mul	a0,a0,a0
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	ec4080e7          	jalr	-316(ra) # 80002098 <long_to_padded_string>
    char new_seed[seed_size + 1];
    800021dc:	41610133          	sub	sp,sp,s6
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800021e0:	864a                	mv	a2,s2
    800021e2:	85de                	mv	a1,s7
    800021e4:	850a                	mv	a0,sp
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	bf4080e7          	jalr	-1036(ra) # 80000dda <strncpy>
    new_seed[seed_size] = '\0';                         // Null-terminate
    800021ee:	012107b3          	add	a5,sp,s2
    800021f2:	00078023          	sb	zero,0(a5)
    lst[lst_index++] = simple_atol(new_seed);
    800021f6:	850a                	mv	a0,sp
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	e34080e7          	jalr	-460(ra) # 8000202c <simple_atol>
    80002200:	0009a783          	lw	a5,0(s3)
    80002204:	0017871b          	addw	a4,a5,1
    80002208:	00e9a023          	sw	a4,0(s3)
    8000220c:	078a                	sll	a5,a5,0x2
    8000220e:	97e2                	add	a5,a5,s8
    80002210:	c388                	sw	a0,0(a5)
    seed_val = simple_atol(new_seed);
    80002212:	850a                	mv	a0,sp
    80002214:	00000097          	auipc	ra,0x0
    80002218:	e18080e7          	jalr	-488(ra) # 8000202c <simple_atol>
    8000221c:	8152                	mv	sp,s4
  for (int i = 0; i < iterations; i++)
    8000221e:	2485                	addw	s1,s1,1
    80002220:	fa9a94e3          	bne	s5,s1,800021c8 <pseudo_rand_num_generator+0xac>
  return lst[lst_index - 1];
    80002224:	00006797          	auipc	a5,0x6
    80002228:	7687a783          	lw	a5,1896(a5) # 8000898c <lst_index>
    8000222c:	37fd                	addw	a5,a5,-1
    8000222e:	078a                	sll	a5,a5,0x2
    80002230:	0000f717          	auipc	a4,0xf
    80002234:	e4070713          	add	a4,a4,-448 # 80011070 <lst>
    80002238:	97ba                	add	a5,a5,a4
    8000223a:	4388                	lw	a0,0(a5)
}
    8000223c:	f8040113          	add	sp,s0,-128
    80002240:	70e6                	ld	ra,120(sp)
    80002242:	7446                	ld	s0,112(sp)
    80002244:	74a6                	ld	s1,104(sp)
    80002246:	7906                	ld	s2,96(sp)
    80002248:	69e6                	ld	s3,88(sp)
    8000224a:	6a46                	ld	s4,80(sp)
    8000224c:	6aa6                	ld	s5,72(sp)
    8000224e:	6b06                	ld	s6,64(sp)
    80002250:	7be2                	ld	s7,56(sp)
    80002252:	7c42                	ld	s8,48(sp)
    80002254:	7ca2                	ld	s9,40(sp)
    80002256:	6109                	add	sp,sp,128
    80002258:	8082                	ret

000000008000225a <int_to_string>:
{
    8000225a:	1141                	add	sp,sp,-16
    8000225c:	e422                	sd	s0,8(sp)
    8000225e:	0800                	add	s0,sp,16
  int temp = num;
    80002260:	872a                	mv	a4,a0
  int len = 0;
    80002262:	4781                	li	a5,0
    temp /= 10;
    80002264:	48a9                	li	a7,10
  } while (temp > 0);
    80002266:	4825                	li	a6,9
    len++;
    80002268:	863e                	mv	a2,a5
    8000226a:	2785                	addw	a5,a5,1
    temp /= 10;
    8000226c:	86ba                	mv	a3,a4
    8000226e:	0317473b          	divw	a4,a4,a7
  } while (temp > 0);
    80002272:	fed84be3          	blt	a6,a3,80002268 <int_to_string+0xe>
  result[len] = '\0'; // Null-terminate the string
    80002276:	97ae                	add	a5,a5,a1
    80002278:	00078023          	sb	zero,0(a5)
  for (int i = len - 1; i >= 0; i--)
    8000227c:	02064663          	bltz	a2,800022a8 <int_to_string+0x4e>
    80002280:	00c587b3          	add	a5,a1,a2
    80002284:	fff58693          	add	a3,a1,-1
    80002288:	96b2                	add	a3,a3,a2
    8000228a:	1602                	sll	a2,a2,0x20
    8000228c:	9201                	srl	a2,a2,0x20
    8000228e:	8e91                	sub	a3,a3,a2
    result[i] = (num % 10) + '0';
    80002290:	4629                	li	a2,10
    80002292:	02c5673b          	remw	a4,a0,a2
    80002296:	0307071b          	addw	a4,a4,48
    8000229a:	00e78023          	sb	a4,0(a5)
    num /= 10;
    8000229e:	02c5453b          	divw	a0,a0,a2
  for (int i = len - 1; i >= 0; i--)
    800022a2:	17fd                	add	a5,a5,-1
    800022a4:	fed797e3          	bne	a5,a3,80002292 <int_to_string+0x38>
}
    800022a8:	6422                	ld	s0,8(sp)
    800022aa:	0141                	add	sp,sp,16
    800022ac:	8082                	ret

00000000800022ae <simple_rand>:
{
    800022ae:	1141                	add	sp,sp,-16
    800022b0:	e422                	sd	s0,8(sp)
    800022b2:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    800022b4:	00006697          	auipc	a3,0x6
    800022b8:	63468693          	add	a3,a3,1588 # 800088e8 <seed>
    800022bc:	629c                	ld	a5,0(a3)
    800022be:	41c65737          	lui	a4,0x41c65
    800022c2:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    800022c6:	02e787b3          	mul	a5,a5,a4
    800022ca:	0012d737          	lui	a4,0x12d
    800022ce:	68770713          	add	a4,a4,1671 # 12d687 <_entry-0x7fed2979>
    800022d2:	97ba                	add	a5,a5,a4
    800022d4:	1786                	sll	a5,a5,0x21
    800022d6:	9385                	srl	a5,a5,0x21
    800022d8:	e29c                	sd	a5,0(a3)
}
    800022da:	6509                	lui	a0,0x2
    800022dc:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    800022e0:	02a7f533          	remu	a0,a5,a0
    800022e4:	6422                	ld	s0,8(sp)
    800022e6:	0141                	add	sp,sp,16
    800022e8:	8082                	ret

00000000800022ea <random_at_most>:
{
    800022ea:	1101                	add	sp,sp,-32
    800022ec:	ec06                	sd	ra,24(sp)
    800022ee:	e822                	sd	s0,16(sp)
    800022f0:	e426                	sd	s1,8(sp)
    800022f2:	1000                	add	s0,sp,32
    800022f4:	84aa                	mv	s1,a0
  int random_num = simple_rand(); // Use the LCG for random generation
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	fb8080e7          	jalr	-72(ra) # 800022ae <simple_rand>
  return 1 + (random_num % max);  // Return a number in the range [1, max]
    800022fe:	0295653b          	remw	a0,a0,s1
}
    80002302:	2505                	addw	a0,a0,1
    80002304:	60e2                	ld	ra,24(sp)
    80002306:	6442                	ld	s0,16(sp)
    80002308:	64a2                	ld	s1,8(sp)
    8000230a:	6105                	add	sp,sp,32
    8000230c:	8082                	ret

000000008000230e <round_robin_scheduler>:
{
    8000230e:	7139                	add	sp,sp,-64
    80002310:	fc06                	sd	ra,56(sp)
    80002312:	f822                	sd	s0,48(sp)
    80002314:	f426                	sd	s1,40(sp)
    80002316:	f04a                	sd	s2,32(sp)
    80002318:	ec4e                	sd	s3,24(sp)
    8000231a:	e852                	sd	s4,16(sp)
    8000231c:	e456                	sd	s5,8(sp)
    8000231e:	e05a                	sd	s6,0(sp)
    80002320:	0080                	add	s0,sp,64
    80002322:	8792                	mv	a5,tp
  int id = r_tp();
    80002324:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002326:	00779a93          	sll	s5,a5,0x7
    8000232a:	0000f717          	auipc	a4,0xf
    8000232e:	8d670713          	add	a4,a4,-1834 # 80010c00 <mlfq_queues>
    80002332:	9756                	add	a4,a4,s5
    80002334:	06073823          	sd	zero,112(a4)
        swtch(&c->context, &p->context);
    80002338:	0000f717          	auipc	a4,0xf
    8000233c:	94070713          	add	a4,a4,-1728 # 80010c78 <cpus+0x8>
    80002340:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002342:	498d                	li	s3,3
        p->state = RUNNING;
    80002344:	4b11                	li	s6,4
        c->proc = p;
    80002346:	079e                	sll	a5,a5,0x7
    80002348:	0000fa17          	auipc	s4,0xf
    8000234c:	8b8a0a13          	add	s4,s4,-1864 # 80010c00 <mlfq_queues>
    80002350:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002352:	00019917          	auipc	s2,0x19
    80002356:	8be90913          	add	s2,s2,-1858 # 8001ac10 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000235a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000235e:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002362:	10079073          	csrw	sstatus,a5
    80002366:	00010497          	auipc	s1,0x10
    8000236a:	caa48493          	add	s1,s1,-854 # 80012010 <proc>
    8000236e:	a811                	j	80002382 <round_robin_scheduler+0x74>
      release(&p->lock);
    80002370:	8526                	mv	a0,s1
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	914080e7          	jalr	-1772(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000237a:	23048493          	add	s1,s1,560
    8000237e:	fd248ee3          	beq	s1,s2,8000235a <round_robin_scheduler+0x4c>
      acquire(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	84e080e7          	jalr	-1970(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000238c:	4c9c                	lw	a5,24(s1)
    8000238e:	ff3791e3          	bne	a5,s3,80002370 <round_robin_scheduler+0x62>
        p->state = RUNNING;
    80002392:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002396:	069a3823          	sd	s1,112(s4)
        swtch(&c->context, &p->context);
    8000239a:	06048593          	add	a1,s1,96
    8000239e:	8556                	mv	a0,s5
    800023a0:	00001097          	auipc	ra,0x1
    800023a4:	b62080e7          	jalr	-1182(ra) # 80002f02 <swtch>
        c->proc = 0;
    800023a8:	060a3823          	sd	zero,112(s4)
    800023ac:	b7d1                	j	80002370 <round_robin_scheduler+0x62>

00000000800023ae <lottery_scheduler>:
{
    800023ae:	715d                	add	sp,sp,-80
    800023b0:	e486                	sd	ra,72(sp)
    800023b2:	e0a2                	sd	s0,64(sp)
    800023b4:	fc26                	sd	s1,56(sp)
    800023b6:	f84a                	sd	s2,48(sp)
    800023b8:	f44e                	sd	s3,40(sp)
    800023ba:	f052                	sd	s4,32(sp)
    800023bc:	ec56                	sd	s5,24(sp)
    800023be:	e85a                	sd	s6,16(sp)
    800023c0:	e45e                	sd	s7,8(sp)
    800023c2:	e062                	sd	s8,0(sp)
    800023c4:	0880                	add	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800023c6:	8792                	mv	a5,tp
  int id = r_tp();
    800023c8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800023ca:	00779693          	sll	a3,a5,0x7
    800023ce:	0000f717          	auipc	a4,0xf
    800023d2:	83270713          	add	a4,a4,-1998 # 80010c00 <mlfq_queues>
    800023d6:	9736                	add	a4,a4,a3
    800023d8:	06073823          	sd	zero,112(a4)
        swtch(&c->context, &winner->context);
    800023dc:	0000f717          	auipc	a4,0xf
    800023e0:	89c70713          	add	a4,a4,-1892 # 80010c78 <cpus+0x8>
    800023e4:	00e68c33          	add	s8,a3,a4
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    800023e8:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800023ea:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023ec:	00019917          	auipc	s2,0x19
    800023f0:	82490913          	add	s2,s2,-2012 # 8001ac10 <tickslock>
        c->proc = winner;
    800023f4:	0000fb17          	auipc	s6,0xf
    800023f8:	80cb0b13          	add	s6,s6,-2036 # 80010c00 <mlfq_queues>
    800023fc:	9b36                	add	s6,s6,a3
    800023fe:	a80d                	j	80002430 <lottery_scheduler+0x82>
      release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	884080e7          	jalr	-1916(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000240a:	23048493          	add	s1,s1,560
    8000240e:	01248f63          	beq	s1,s2,8000242c <lottery_scheduler+0x7e>
      acquire(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7be080e7          	jalr	1982(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000241c:	4c9c                	lw	a5,24(s1)
    8000241e:	ff3791e3          	bne	a5,s3,80002400 <lottery_scheduler+0x52>
        total_tickets += p->tickets; // Accumulate total tickets
    80002422:	2104a783          	lw	a5,528(s1)
    80002426:	01478a3b          	addw	s4,a5,s4
    8000242a:	bfd9                	j	80002400 <lottery_scheduler+0x52>
    if (total_tickets == 0)
    8000242c:	000a1e63          	bnez	s4,80002448 <lottery_scheduler+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002430:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002434:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002438:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    8000243c:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    8000243e:	00010497          	auipc	s1,0x10
    80002442:	bd248493          	add	s1,s1,-1070 # 80012010 <proc>
    80002446:	b7f1                	j	80002412 <lottery_scheduler+0x64>
    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    80002448:	8552                	mv	a0,s4
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	ea0080e7          	jalr	-352(ra) # 800022ea <random_at_most>
    80002452:	8baa                	mv	s7,a0
    int ticket_counter = 0;                             // Track ticket count while iterating over processes
    80002454:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002456:	00010497          	auipc	s1,0x10
    8000245a:	bba48493          	add	s1,s1,-1094 # 80012010 <proc>
    8000245e:	a811                	j	80002472 <lottery_scheduler+0xc4>
      release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	824080e7          	jalr	-2012(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000246a:	23048493          	add	s1,s1,560
    8000246e:	fd2481e3          	beq	s1,s2,80002430 <lottery_scheduler+0x82>
      if (p == 0)
    80002472:	dce5                	beqz	s1,8000246a <lottery_scheduler+0xbc>
      acquire(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	75c080e7          	jalr	1884(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000247e:	4c9c                	lw	a5,24(s1)
    80002480:	ff3790e3          	bne	a5,s3,80002460 <lottery_scheduler+0xb2>
        ticket_counter += p->tickets; // Increment the ticket counter
    80002484:	2104a783          	lw	a5,528(s1)
    80002488:	01478a3b          	addw	s4,a5,s4
        if (ticket_counter >= winning_ticket)
    8000248c:	fd7a4ae3          	blt	s4,s7,80002460 <lottery_scheduler+0xb2>
            release(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	7f4080e7          	jalr	2036(ra) # 80000c86 <release>
      acquire(&winner->lock);
    8000249a:	8a26                	mv	s4,s1
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	734080e7          	jalr	1844(ra) # 80000bd2 <acquire>
      if (winner->state == RUNNABLE)
    800024a6:	4c9c                	lw	a5,24(s1)
    800024a8:	01378863          	beq	a5,s3,800024b8 <lottery_scheduler+0x10a>
      release(&winner->lock);
    800024ac:	8552                	mv	a0,s4
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7d8080e7          	jalr	2008(ra) # 80000c86 <release>
    800024b6:	bfad                	j	80002430 <lottery_scheduler+0x82>
        winner->state = RUNNING;
    800024b8:	4791                	li	a5,4
    800024ba:	cc9c                	sw	a5,24(s1)
        c->proc = winner;
    800024bc:	069b3823          	sd	s1,112(s6)
        swtch(&c->context, &winner->context);
    800024c0:	06048593          	add	a1,s1,96
    800024c4:	8562                	mv	a0,s8
    800024c6:	00001097          	auipc	ra,0x1
    800024ca:	a3c080e7          	jalr	-1476(ra) # 80002f02 <swtch>
        c->proc = 0;
    800024ce:	060b3823          	sd	zero,112(s6)
    800024d2:	bfe9                	j	800024ac <lottery_scheduler+0xfe>

00000000800024d4 <get_ticks_for_priority>:
{
    800024d4:	1141                	add	sp,sp,-16
    800024d6:	e422                	sd	s0,8(sp)
    800024d8:	0800                	add	s0,sp,16
  switch (priority)
    800024da:	4709                	li	a4,2
    800024dc:	00e50f63          	beq	a0,a4,800024fa <get_ticks_for_priority+0x26>
    800024e0:	87aa                	mv	a5,a0
    800024e2:	470d                	li	a4,3
    return TICKS_3; // 16 ticks for priority 3
    800024e4:	4541                	li	a0,16
  switch (priority)
    800024e6:	00e78763          	beq	a5,a4,800024f4 <get_ticks_for_priority+0x20>
    800024ea:	4705                	li	a4,1
    800024ec:	4511                	li	a0,4
    800024ee:	00e78363          	beq	a5,a4,800024f4 <get_ticks_for_priority+0x20>
    return TICKS_0; // 1 tick for priority 0
    800024f2:	4505                	li	a0,1
}
    800024f4:	6422                	ld	s0,8(sp)
    800024f6:	0141                	add	sp,sp,16
    800024f8:	8082                	ret
    return TICKS_2; // 8 ticks for priority 2
    800024fa:	4521                	li	a0,8
    800024fc:	bfe5                	j	800024f4 <get_ticks_for_priority+0x20>

00000000800024fe <boost_all_processes>:
{
    800024fe:	7179                	add	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	1800                	add	s0,sp,48
  for (int i = 0; i < NPROC; i++)
    8000250c:	00010497          	auipc	s1,0x10
    80002510:	b0448493          	add	s1,s1,-1276 # 80012010 <proc>
    80002514:	00018917          	auipc	s2,0x18
    80002518:	6fc90913          	add	s2,s2,1788 # 8001ac10 <tickslock>
      p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    8000251c:	4985                	li	s3,1
    8000251e:	a029                	j	80002528 <boost_all_processes+0x2a>
  for (int i = 0; i < NPROC; i++)
    80002520:	23048493          	add	s1,s1,560
    80002524:	01248f63          	beq	s1,s2,80002542 <boost_all_processes+0x44>
    if (p->state != UNUSED)
    80002528:	4c9c                	lw	a5,24(s1)
    8000252a:	dbfd                	beqz	a5,80002520 <boost_all_processes+0x22>
      p->priority = 0;              // Move all processes to priority 0
    8000252c:	2204a023          	sw	zero,544(s1)
      p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
    80002530:	2334a223          	sw	s3,548(s1)
      enqueue(0, p);                // Enqueue into priority 0
    80002534:	85a6                	mv	a1,s1
    80002536:	4501                	li	a0,0
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	32c080e7          	jalr	812(ra) # 80001864 <enqueue>
    80002540:	b7c5                	j	80002520 <boost_all_processes+0x22>
}
    80002542:	70a2                	ld	ra,40(sp)
    80002544:	7402                	ld	s0,32(sp)
    80002546:	64e2                	ld	s1,24(sp)
    80002548:	6942                	ld	s2,16(sp)
    8000254a:	69a2                	ld	s3,8(sp)
    8000254c:	6145                	add	sp,sp,48
    8000254e:	8082                	ret

0000000080002550 <mlfq_scheduler>:
{
    80002550:	711d                	add	sp,sp,-96
    80002552:	ec86                	sd	ra,88(sp)
    80002554:	e8a2                	sd	s0,80(sp)
    80002556:	e4a6                	sd	s1,72(sp)
    80002558:	e0ca                	sd	s2,64(sp)
    8000255a:	fc4e                	sd	s3,56(sp)
    8000255c:	f852                	sd	s4,48(sp)
    8000255e:	f456                	sd	s5,40(sp)
    80002560:	f05a                	sd	s6,32(sp)
    80002562:	ec5e                	sd	s7,24(sp)
    80002564:	e862                	sd	s8,16(sp)
    80002566:	e466                	sd	s9,8(sp)
    80002568:	1080                	add	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000256a:	8792                	mv	a5,tp
  int id = r_tp();
    8000256c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000256e:	00779b93          	sll	s7,a5,0x7
    80002572:	0000e717          	auipc	a4,0xe
    80002576:	68e70713          	add	a4,a4,1678 # 80010c00 <mlfq_queues>
    8000257a:	975e                	add	a4,a4,s7
    8000257c:	06073823          	sd	zero,112(a4)
      swtch(&c->context, &selected_proc->context);
    80002580:	0000e717          	auipc	a4,0xe
    80002584:	6f870713          	add	a4,a4,1784 # 80010c78 <cpus+0x8>
    80002588:	9bba                	add	s7,s7,a4
    boost_ticks++;
    8000258a:	00006997          	auipc	s3,0x6
    8000258e:	3fe98993          	add	s3,s3,1022 # 80008988 <boost_ticks>
    if (boost_ticks >= BOOST_INTERVAL)
    80002592:	02f00a13          	li	s4,47
    80002596:	0000ea97          	auipc	s5,0xe
    8000259a:	6aaa8a93          	add	s5,s5,1706 # 80010c40 <pid_lock>
        if (p->state == RUNNABLE) // Check if the process is runnable
    8000259e:	490d                	li	s2,3
      c->proc = selected_proc;
    800025a0:	079e                	sll	a5,a5,0x7
    800025a2:	0000eb17          	auipc	s6,0xe
    800025a6:	65eb0b13          	add	s6,s6,1630 # 80010c00 <mlfq_queues>
    800025aa:	9b3e                	add	s6,s6,a5
    800025ac:	a05d                	j	80002652 <mlfq_scheduler+0x102>
      boost_all_processes(); // Boost all processes back to the highest priority queue
    800025ae:	00000097          	auipc	ra,0x0
    800025b2:	f50080e7          	jalr	-176(ra) # 800024fe <boost_all_processes>
      boost_ticks = 0;       // Reset boost tick counter
    800025b6:	0009a023          	sw	zero,0(s3)
    800025ba:	a85d                	j	80002670 <mlfq_scheduler+0x120>
      selected_proc->state = RUNNING; // Change state to RUNNING
    800025bc:	4791                	li	a5,4
    800025be:	cc9c                	sw	a5,24(s1)
      c->proc = selected_proc;
    800025c0:	069b3823          	sd	s1,112(s6)
      dequeue(selected_proc->priority, selected_proc);
    800025c4:	85a6                	mv	a1,s1
    800025c6:	2204a503          	lw	a0,544(s1)
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	2fe080e7          	jalr	766(ra) # 800018c8 <dequeue>
      swtch(&c->context, &selected_proc->context);
    800025d2:	06048593          	add	a1,s1,96
    800025d6:	855e                	mv	a0,s7
    800025d8:	00001097          	auipc	ra,0x1
    800025dc:	92a080e7          	jalr	-1750(ra) # 80002f02 <swtch>
      c->proc = 0;
    800025e0:	060b3823          	sd	zero,112(s6)
      selected_proc->remaining_ticks--;
    800025e4:	2244a783          	lw	a5,548(s1)
    800025e8:	37fd                	addw	a5,a5,-1
    800025ea:	0007871b          	sext.w	a4,a5
    800025ee:	22f4a223          	sw	a5,548(s1)
      if (selected_proc->remaining_ticks <= 0)
    800025f2:	02e04a63          	bgtz	a4,80002626 <mlfq_scheduler+0xd6>
        if (selected_proc->priority < total_queue - 1)
    800025f6:	2204a783          	lw	a5,544(s1)
    800025fa:	4709                	li	a4,2
    800025fc:	00f74563          	blt	a4,a5,80002606 <mlfq_scheduler+0xb6>
          selected_proc->priority++; // Move to a lower-priority queue
    80002600:	2785                	addw	a5,a5,1
    80002602:	22f4a023          	sw	a5,544(s1)
        selected_proc->remaining_ticks = get_ticks_for_priority(selected_proc->priority);
    80002606:	2204ac83          	lw	s9,544(s1)
    8000260a:	8566                	mv	a0,s9
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	ec8080e7          	jalr	-312(ra) # 800024d4 <get_ticks_for_priority>
    80002614:	22a4a223          	sw	a0,548(s1)
        enqueue(selected_proc->priority, selected_proc); // Requeue the process
    80002618:	85a6                	mv	a1,s1
    8000261a:	8566                	mv	a0,s9
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	248080e7          	jalr	584(ra) # 80001864 <enqueue>
    80002624:	a015                	j	80002648 <mlfq_scheduler+0xf8>
        enqueue(selected_proc->priority, selected_proc);
    80002626:	85a6                	mv	a1,s1
    80002628:	2204a503          	lw	a0,544(s1)
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	238080e7          	jalr	568(ra) # 80001864 <enqueue>
    80002634:	a811                	j	80002648 <mlfq_scheduler+0xf8>
    acquire(&selected_proc->lock); // Lock the selected process
    80002636:	8c26                	mv	s8,s1
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	598080e7          	jalr	1432(ra) # 80000bd2 <acquire>
    if (selected_proc->state == RUNNABLE)
    80002642:	4c9c                	lw	a5,24(s1)
    80002644:	f7278ce3          	beq	a5,s2,800025bc <mlfq_scheduler+0x6c>
    release(&selected_proc->lock); // Release the lock for the selected process
    80002648:	8562                	mv	a0,s8
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	63c080e7          	jalr	1596(ra) # 80000c86 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002652:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002656:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000265a:	10079073          	csrw	sstatus,a5
    boost_ticks++;
    8000265e:	0009a783          	lw	a5,0(s3)
    80002662:	2785                	addw	a5,a5,1
    80002664:	0007871b          	sext.w	a4,a5
    80002668:	00f9a023          	sw	a5,0(s3)
    if (boost_ticks >= BOOST_INTERVAL)
    8000266c:	f4ea41e3          	blt	s4,a4,800025ae <mlfq_scheduler+0x5e>
    for (int i = 0; i < total_queue; i++)
    80002670:	0000e717          	auipc	a4,0xe
    80002674:	59070713          	add	a4,a4,1424 # 80010c00 <mlfq_queues>
      for (p = mlfq_queues[i].head; p != 0; p = p->next)
    80002678:	6304                	ld	s1,0(a4)
    8000267a:	c499                	beqz	s1,80002688 <mlfq_scheduler+0x138>
        if (p->state == RUNNABLE) // Check if the process is runnable
    8000267c:	4c9c                	lw	a5,24(s1)
    8000267e:	fb278ce3          	beq	a5,s2,80002636 <mlfq_scheduler+0xe6>
      for (p = mlfq_queues[i].head; p != 0; p = p->next)
    80002682:	2284b483          	ld	s1,552(s1)
    80002686:	f8fd                	bnez	s1,8000267c <mlfq_scheduler+0x12c>
    for (int i = 0; i < total_queue; i++)
    80002688:	0741                	add	a4,a4,16
    8000268a:	ff5717e3          	bne	a4,s5,80002678 <mlfq_scheduler+0x128>
    8000268e:	b7d1                	j	80002652 <mlfq_scheduler+0x102>

0000000080002690 <scheduler>:
{
    80002690:	1141                	add	sp,sp,-16
    80002692:	e406                	sd	ra,8(sp)
    80002694:	e022                	sd	s0,0(sp)
    80002696:	0800                	add	s0,sp,16
    printf("mlfq will run");
    80002698:	00006517          	auipc	a0,0x6
    8000269c:	b9850513          	add	a0,a0,-1128 # 80008230 <digits+0x1f0>
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	ee6080e7          	jalr	-282(ra) # 80000586 <printf>
    mlfq_scheduler();
    800026a8:	00000097          	auipc	ra,0x0
    800026ac:	ea8080e7          	jalr	-344(ra) # 80002550 <mlfq_scheduler>

00000000800026b0 <sched>:
{
    800026b0:	7179                	add	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800026be:	fffff097          	auipc	ra,0xfffff
    800026c2:	400080e7          	jalr	1024(ra) # 80001abe <myproc>
    800026c6:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	490080e7          	jalr	1168(ra) # 80000b58 <holding>
    800026d0:	c93d                	beqz	a0,80002746 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026d2:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800026d4:	2781                	sext.w	a5,a5
    800026d6:	079e                	sll	a5,a5,0x7
    800026d8:	0000e717          	auipc	a4,0xe
    800026dc:	52870713          	add	a4,a4,1320 # 80010c00 <mlfq_queues>
    800026e0:	97ba                	add	a5,a5,a4
    800026e2:	0e87a703          	lw	a4,232(a5)
    800026e6:	4785                	li	a5,1
    800026e8:	06f71763          	bne	a4,a5,80002756 <sched+0xa6>
  if (p->state == RUNNING)
    800026ec:	4c98                	lw	a4,24(s1)
    800026ee:	4791                	li	a5,4
    800026f0:	06f70b63          	beq	a4,a5,80002766 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026f8:	8b89                	and	a5,a5,2
  if (intr_get())
    800026fa:	efb5                	bnez	a5,80002776 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026fc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800026fe:	0000e917          	auipc	s2,0xe
    80002702:	50290913          	add	s2,s2,1282 # 80010c00 <mlfq_queues>
    80002706:	2781                	sext.w	a5,a5
    80002708:	079e                	sll	a5,a5,0x7
    8000270a:	97ca                	add	a5,a5,s2
    8000270c:	0ec7a983          	lw	s3,236(a5)
    80002710:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002712:	2781                	sext.w	a5,a5
    80002714:	079e                	sll	a5,a5,0x7
    80002716:	0000e597          	auipc	a1,0xe
    8000271a:	56258593          	add	a1,a1,1378 # 80010c78 <cpus+0x8>
    8000271e:	95be                	add	a1,a1,a5
    80002720:	06048513          	add	a0,s1,96
    80002724:	00000097          	auipc	ra,0x0
    80002728:	7de080e7          	jalr	2014(ra) # 80002f02 <swtch>
    8000272c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000272e:	2781                	sext.w	a5,a5
    80002730:	079e                	sll	a5,a5,0x7
    80002732:	993e                	add	s2,s2,a5
    80002734:	0f392623          	sw	s3,236(s2)
}
    80002738:	70a2                	ld	ra,40(sp)
    8000273a:	7402                	ld	s0,32(sp)
    8000273c:	64e2                	ld	s1,24(sp)
    8000273e:	6942                	ld	s2,16(sp)
    80002740:	69a2                	ld	s3,8(sp)
    80002742:	6145                	add	sp,sp,48
    80002744:	8082                	ret
    panic("sched p->lock");
    80002746:	00006517          	auipc	a0,0x6
    8000274a:	afa50513          	add	a0,a0,-1286 # 80008240 <digits+0x200>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	dee080e7          	jalr	-530(ra) # 8000053c <panic>
    panic("sched locks");
    80002756:	00006517          	auipc	a0,0x6
    8000275a:	afa50513          	add	a0,a0,-1286 # 80008250 <digits+0x210>
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	dde080e7          	jalr	-546(ra) # 8000053c <panic>
    panic("sched running");
    80002766:	00006517          	auipc	a0,0x6
    8000276a:	afa50513          	add	a0,a0,-1286 # 80008260 <digits+0x220>
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	dce080e7          	jalr	-562(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002776:	00006517          	auipc	a0,0x6
    8000277a:	afa50513          	add	a0,a0,-1286 # 80008270 <digits+0x230>
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	dbe080e7          	jalr	-578(ra) # 8000053c <panic>

0000000080002786 <yield>:
{
    80002786:	1101                	add	sp,sp,-32
    80002788:	ec06                	sd	ra,24(sp)
    8000278a:	e822                	sd	s0,16(sp)
    8000278c:	e426                	sd	s1,8(sp)
    8000278e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	32e080e7          	jalr	814(ra) # 80001abe <myproc>
    80002798:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	438080e7          	jalr	1080(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800027a2:	478d                	li	a5,3
    800027a4:	cc9c                	sw	a5,24(s1)
  enqueue(p->priority, p); // here is the change  i did
    800027a6:	85a6                	mv	a1,s1
    800027a8:	2204a503          	lw	a0,544(s1)
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	0b8080e7          	jalr	184(ra) # 80001864 <enqueue>
  sched();
    800027b4:	00000097          	auipc	ra,0x0
    800027b8:	efc080e7          	jalr	-260(ra) # 800026b0 <sched>
  release(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4c8080e7          	jalr	1224(ra) # 80000c86 <release>
}
    800027c6:	60e2                	ld	ra,24(sp)
    800027c8:	6442                	ld	s0,16(sp)
    800027ca:	64a2                	ld	s1,8(sp)
    800027cc:	6105                	add	sp,sp,32
    800027ce:	8082                	ret

00000000800027d0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800027d0:	7179                	add	sp,sp,-48
    800027d2:	f406                	sd	ra,40(sp)
    800027d4:	f022                	sd	s0,32(sp)
    800027d6:	ec26                	sd	s1,24(sp)
    800027d8:	e84a                	sd	s2,16(sp)
    800027da:	e44e                	sd	s3,8(sp)
    800027dc:	1800                	add	s0,sp,48
    800027de:	89aa                	mv	s3,a0
    800027e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	2dc080e7          	jalr	732(ra) # 80001abe <myproc>
    800027ea:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	3e6080e7          	jalr	998(ra) # 80000bd2 <acquire>
  release(lk);
    800027f4:	854a                	mv	a0,s2
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	490080e7          	jalr	1168(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800027fe:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002802:	4789                	li	a5,2
    80002804:	cc9c                	sw	a5,24(s1)

  sched();
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	eaa080e7          	jalr	-342(ra) # 800026b0 <sched>

  // Tidy up.
  p->chan = 0;
    8000280e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	472080e7          	jalr	1138(ra) # 80000c86 <release>
  acquire(lk);
    8000281c:	854a                	mv	a0,s2
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	3b4080e7          	jalr	948(ra) # 80000bd2 <acquire>
}
    80002826:	70a2                	ld	ra,40(sp)
    80002828:	7402                	ld	s0,32(sp)
    8000282a:	64e2                	ld	s1,24(sp)
    8000282c:	6942                	ld	s2,16(sp)
    8000282e:	69a2                	ld	s3,8(sp)
    80002830:	6145                	add	sp,sp,48
    80002832:	8082                	ret

0000000080002834 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002834:	7139                	add	sp,sp,-64
    80002836:	fc06                	sd	ra,56(sp)
    80002838:	f822                	sd	s0,48(sp)
    8000283a:	f426                	sd	s1,40(sp)
    8000283c:	f04a                	sd	s2,32(sp)
    8000283e:	ec4e                	sd	s3,24(sp)
    80002840:	e852                	sd	s4,16(sp)
    80002842:	e456                	sd	s5,8(sp)
    80002844:	0080                	add	s0,sp,64
    80002846:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002848:	0000f497          	auipc	s1,0xf
    8000284c:	7c848493          	add	s1,s1,1992 # 80012010 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002850:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002852:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002854:	00018917          	auipc	s2,0x18
    80002858:	3bc90913          	add	s2,s2,956 # 8001ac10 <tickslock>
    8000285c:	a811                	j	80002870 <wakeup+0x3c>
      }
      release(&p->lock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	426080e7          	jalr	1062(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002868:	23048493          	add	s1,s1,560
    8000286c:	03248663          	beq	s1,s2,80002898 <wakeup+0x64>
    if (p != myproc())
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	24e080e7          	jalr	590(ra) # 80001abe <myproc>
    80002878:	fea488e3          	beq	s1,a0,80002868 <wakeup+0x34>
      acquire(&p->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	354080e7          	jalr	852(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002886:	4c9c                	lw	a5,24(s1)
    80002888:	fd379be3          	bne	a5,s3,8000285e <wakeup+0x2a>
    8000288c:	709c                	ld	a5,32(s1)
    8000288e:	fd4798e3          	bne	a5,s4,8000285e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002892:	0154ac23          	sw	s5,24(s1)
    80002896:	b7e1                	j	8000285e <wakeup+0x2a>
    }
  }
}
    80002898:	70e2                	ld	ra,56(sp)
    8000289a:	7442                	ld	s0,48(sp)
    8000289c:	74a2                	ld	s1,40(sp)
    8000289e:	7902                	ld	s2,32(sp)
    800028a0:	69e2                	ld	s3,24(sp)
    800028a2:	6a42                	ld	s4,16(sp)
    800028a4:	6aa2                	ld	s5,8(sp)
    800028a6:	6121                	add	sp,sp,64
    800028a8:	8082                	ret

00000000800028aa <reparent>:
{
    800028aa:	7179                	add	sp,sp,-48
    800028ac:	f406                	sd	ra,40(sp)
    800028ae:	f022                	sd	s0,32(sp)
    800028b0:	ec26                	sd	s1,24(sp)
    800028b2:	e84a                	sd	s2,16(sp)
    800028b4:	e44e                	sd	s3,8(sp)
    800028b6:	e052                	sd	s4,0(sp)
    800028b8:	1800                	add	s0,sp,48
    800028ba:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800028bc:	0000f497          	auipc	s1,0xf
    800028c0:	75448493          	add	s1,s1,1876 # 80012010 <proc>
      pp->parent = initproc;
    800028c4:	00006a17          	auipc	s4,0x6
    800028c8:	0cca0a13          	add	s4,s4,204 # 80008990 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800028cc:	00018997          	auipc	s3,0x18
    800028d0:	34498993          	add	s3,s3,836 # 8001ac10 <tickslock>
    800028d4:	a029                	j	800028de <reparent+0x34>
    800028d6:	23048493          	add	s1,s1,560
    800028da:	01348d63          	beq	s1,s3,800028f4 <reparent+0x4a>
    if (pp->parent == p)
    800028de:	7c9c                	ld	a5,56(s1)
    800028e0:	ff279be3          	bne	a5,s2,800028d6 <reparent+0x2c>
      pp->parent = initproc;
    800028e4:	000a3503          	ld	a0,0(s4)
    800028e8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	f4a080e7          	jalr	-182(ra) # 80002834 <wakeup>
    800028f2:	b7d5                	j	800028d6 <reparent+0x2c>
}
    800028f4:	70a2                	ld	ra,40(sp)
    800028f6:	7402                	ld	s0,32(sp)
    800028f8:	64e2                	ld	s1,24(sp)
    800028fa:	6942                	ld	s2,16(sp)
    800028fc:	69a2                	ld	s3,8(sp)
    800028fe:	6a02                	ld	s4,0(sp)
    80002900:	6145                	add	sp,sp,48
    80002902:	8082                	ret

0000000080002904 <exit>:
{
    80002904:	7179                	add	sp,sp,-48
    80002906:	f406                	sd	ra,40(sp)
    80002908:	f022                	sd	s0,32(sp)
    8000290a:	ec26                	sd	s1,24(sp)
    8000290c:	e84a                	sd	s2,16(sp)
    8000290e:	e44e                	sd	s3,8(sp)
    80002910:	e052                	sd	s4,0(sp)
    80002912:	1800                	add	s0,sp,48
    80002914:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	1a8080e7          	jalr	424(ra) # 80001abe <myproc>
    8000291e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002920:	00006797          	auipc	a5,0x6
    80002924:	0707b783          	ld	a5,112(a5) # 80008990 <initproc>
    80002928:	0d050493          	add	s1,a0,208
    8000292c:	15050913          	add	s2,a0,336
    80002930:	02a79363          	bne	a5,a0,80002956 <exit+0x52>
    panic("init exiting");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	95450513          	add	a0,a0,-1708 # 80008288 <digits+0x248>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c00080e7          	jalr	-1024(ra) # 8000053c <panic>
      fileclose(f);
    80002944:	00002097          	auipc	ra,0x2
    80002948:	6e6080e7          	jalr	1766(ra) # 8000502a <fileclose>
      p->ofile[fd] = 0;
    8000294c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002950:	04a1                	add	s1,s1,8
    80002952:	01248563          	beq	s1,s2,8000295c <exit+0x58>
    if (p->ofile[fd])
    80002956:	6088                	ld	a0,0(s1)
    80002958:	f575                	bnez	a0,80002944 <exit+0x40>
    8000295a:	bfdd                	j	80002950 <exit+0x4c>
  begin_op();
    8000295c:	00002097          	auipc	ra,0x2
    80002960:	20a080e7          	jalr	522(ra) # 80004b66 <begin_op>
  iput(p->cwd);
    80002964:	1509b503          	ld	a0,336(s3)
    80002968:	00002097          	auipc	ra,0x2
    8000296c:	a12080e7          	jalr	-1518(ra) # 8000437a <iput>
  end_op();
    80002970:	00002097          	auipc	ra,0x2
    80002974:	270080e7          	jalr	624(ra) # 80004be0 <end_op>
  p->cwd = 0;
    80002978:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000297c:	0000e497          	auipc	s1,0xe
    80002980:	2dc48493          	add	s1,s1,732 # 80010c58 <wait_lock>
    80002984:	8526                	mv	a0,s1
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	24c080e7          	jalr	588(ra) # 80000bd2 <acquire>
  reparent(p);
    8000298e:	854e                	mv	a0,s3
    80002990:	00000097          	auipc	ra,0x0
    80002994:	f1a080e7          	jalr	-230(ra) # 800028aa <reparent>
  wakeup(p->parent);
    80002998:	0389b503          	ld	a0,56(s3)
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	e98080e7          	jalr	-360(ra) # 80002834 <wakeup>
  acquire(&p->lock);
    800029a4:	854e                	mv	a0,s3
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	22c080e7          	jalr	556(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800029ae:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800029b2:	4795                	li	a5,5
    800029b4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800029b8:	00006797          	auipc	a5,0x6
    800029bc:	fe07a783          	lw	a5,-32(a5) # 80008998 <ticks>
    800029c0:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	2c0080e7          	jalr	704(ra) # 80000c86 <release>
  sched();
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	ce2080e7          	jalr	-798(ra) # 800026b0 <sched>
  panic("zombie exit");
    800029d6:	00006517          	auipc	a0,0x6
    800029da:	8c250513          	add	a0,a0,-1854 # 80008298 <digits+0x258>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	b5e080e7          	jalr	-1186(ra) # 8000053c <panic>

00000000800029e6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800029e6:	7179                	add	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	1800                	add	s0,sp,48
    800029f4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800029f6:	0000f497          	auipc	s1,0xf
    800029fa:	61a48493          	add	s1,s1,1562 # 80012010 <proc>
    800029fe:	00018997          	auipc	s3,0x18
    80002a02:	21298993          	add	s3,s3,530 # 8001ac10 <tickslock>
  {
    acquire(&p->lock);
    80002a06:	8526                	mv	a0,s1
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	1ca080e7          	jalr	458(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002a10:	589c                	lw	a5,48(s1)
    80002a12:	01278d63          	beq	a5,s2,80002a2c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	26e080e7          	jalr	622(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a20:	23048493          	add	s1,s1,560
    80002a24:	ff3491e3          	bne	s1,s3,80002a06 <kill+0x20>
  }
  return -1;
    80002a28:	557d                	li	a0,-1
    80002a2a:	a829                	j	80002a44 <kill+0x5e>
      p->killed = 1;
    80002a2c:	4785                	li	a5,1
    80002a2e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002a30:	4c98                	lw	a4,24(s1)
    80002a32:	4789                	li	a5,2
    80002a34:	00f70f63          	beq	a4,a5,80002a52 <kill+0x6c>
      release(&p->lock);
    80002a38:	8526                	mv	a0,s1
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	24c080e7          	jalr	588(ra) # 80000c86 <release>
      return 0;
    80002a42:	4501                	li	a0,0
}
    80002a44:	70a2                	ld	ra,40(sp)
    80002a46:	7402                	ld	s0,32(sp)
    80002a48:	64e2                	ld	s1,24(sp)
    80002a4a:	6942                	ld	s2,16(sp)
    80002a4c:	69a2                	ld	s3,8(sp)
    80002a4e:	6145                	add	sp,sp,48
    80002a50:	8082                	ret
        p->state = RUNNABLE;
    80002a52:	478d                	li	a5,3
    80002a54:	cc9c                	sw	a5,24(s1)
    80002a56:	b7cd                	j	80002a38 <kill+0x52>

0000000080002a58 <setkilled>:

void setkilled(struct proc *p)
{
    80002a58:	1101                	add	sp,sp,-32
    80002a5a:	ec06                	sd	ra,24(sp)
    80002a5c:	e822                	sd	s0,16(sp)
    80002a5e:	e426                	sd	s1,8(sp)
    80002a60:	1000                	add	s0,sp,32
    80002a62:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002a6c:	4785                	li	a5,1
    80002a6e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002a70:	8526                	mv	a0,s1
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	214080e7          	jalr	532(ra) # 80000c86 <release>
}
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	add	sp,sp,32
    80002a82:	8082                	ret

0000000080002a84 <killed>:

int killed(struct proc *p)
{
    80002a84:	1101                	add	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	e04a                	sd	s2,0(sp)
    80002a8e:	1000                	add	s0,sp,32
    80002a90:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	140080e7          	jalr	320(ra) # 80000bd2 <acquire>
  k = p->killed;
    80002a9a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	1e6080e7          	jalr	486(ra) # 80000c86 <release>
  return k;
}
    80002aa8:	854a                	mv	a0,s2
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6902                	ld	s2,0(sp)
    80002ab2:	6105                	add	sp,sp,32
    80002ab4:	8082                	ret

0000000080002ab6 <wait>:
{
    80002ab6:	715d                	add	sp,sp,-80
    80002ab8:	e486                	sd	ra,72(sp)
    80002aba:	e0a2                	sd	s0,64(sp)
    80002abc:	fc26                	sd	s1,56(sp)
    80002abe:	f84a                	sd	s2,48(sp)
    80002ac0:	f44e                	sd	s3,40(sp)
    80002ac2:	f052                	sd	s4,32(sp)
    80002ac4:	ec56                	sd	s5,24(sp)
    80002ac6:	e85a                	sd	s6,16(sp)
    80002ac8:	e45e                	sd	s7,8(sp)
    80002aca:	e062                	sd	s8,0(sp)
    80002acc:	0880                	add	s0,sp,80
    80002ace:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	fee080e7          	jalr	-18(ra) # 80001abe <myproc>
    80002ad8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002ada:	0000e517          	auipc	a0,0xe
    80002ade:	17e50513          	add	a0,a0,382 # 80010c58 <wait_lock>
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	0f0080e7          	jalr	240(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002aea:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002aec:	4a95                	li	s5,5
        havekids = 1;
    80002aee:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002af0:	00018997          	auipc	s3,0x18
    80002af4:	12098993          	add	s3,s3,288 # 8001ac10 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002af8:	0000ec17          	auipc	s8,0xe
    80002afc:	160c0c13          	add	s8,s8,352 # 80010c58 <wait_lock>
    80002b00:	a8f1                	j	80002bdc <wait+0x126>
    80002b02:	17448793          	add	a5,s1,372
    80002b06:	17490713          	add	a4,s2,372
    80002b0a:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    80002b0e:	4394                	lw	a3,0(a5)
    80002b10:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    80002b12:	0791                	add	a5,a5,4
    80002b14:	0711                	add	a4,a4,4
    80002b16:	fec79ce3          	bne	a5,a2,80002b0e <wait+0x58>
          pid = pp->pid;
    80002b1a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002b1e:	000a0e63          	beqz	s4,80002b3a <wait+0x84>
    80002b22:	4691                	li	a3,4
    80002b24:	02c48613          	add	a2,s1,44
    80002b28:	85d2                	mv	a1,s4
    80002b2a:	05093503          	ld	a0,80(s2)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	b38080e7          	jalr	-1224(ra) # 80001666 <copyout>
    80002b36:	04054163          	bltz	a0,80002b78 <wait+0xc2>
          freeproc(pp);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	134080e7          	jalr	308(ra) # 80001c70 <freeproc>
          release(&pp->lock);
    80002b44:	8526                	mv	a0,s1
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	140080e7          	jalr	320(ra) # 80000c86 <release>
          release(&wait_lock);
    80002b4e:	0000e517          	auipc	a0,0xe
    80002b52:	10a50513          	add	a0,a0,266 # 80010c58 <wait_lock>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	130080e7          	jalr	304(ra) # 80000c86 <release>
}
    80002b5e:	854e                	mv	a0,s3
    80002b60:	60a6                	ld	ra,72(sp)
    80002b62:	6406                	ld	s0,64(sp)
    80002b64:	74e2                	ld	s1,56(sp)
    80002b66:	7942                	ld	s2,48(sp)
    80002b68:	79a2                	ld	s3,40(sp)
    80002b6a:	7a02                	ld	s4,32(sp)
    80002b6c:	6ae2                	ld	s5,24(sp)
    80002b6e:	6b42                	ld	s6,16(sp)
    80002b70:	6ba2                	ld	s7,8(sp)
    80002b72:	6c02                	ld	s8,0(sp)
    80002b74:	6161                	add	sp,sp,80
    80002b76:	8082                	ret
            release(&pp->lock);
    80002b78:	8526                	mv	a0,s1
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	10c080e7          	jalr	268(ra) # 80000c86 <release>
            release(&wait_lock);
    80002b82:	0000e517          	auipc	a0,0xe
    80002b86:	0d650513          	add	a0,a0,214 # 80010c58 <wait_lock>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	0fc080e7          	jalr	252(ra) # 80000c86 <release>
            return -1;
    80002b92:	59fd                	li	s3,-1
    80002b94:	b7e9                	j	80002b5e <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b96:	23048493          	add	s1,s1,560
    80002b9a:	03348463          	beq	s1,s3,80002bc2 <wait+0x10c>
      if (pp->parent == p)
    80002b9e:	7c9c                	ld	a5,56(s1)
    80002ba0:	ff279be3          	bne	a5,s2,80002b96 <wait+0xe0>
        acquire(&pp->lock);
    80002ba4:	8526                	mv	a0,s1
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	02c080e7          	jalr	44(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002bae:	4c9c                	lw	a5,24(s1)
    80002bb0:	f55789e3          	beq	a5,s5,80002b02 <wait+0x4c>
        release(&pp->lock);
    80002bb4:	8526                	mv	a0,s1
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	0d0080e7          	jalr	208(ra) # 80000c86 <release>
        havekids = 1;
    80002bbe:	875a                	mv	a4,s6
    80002bc0:	bfd9                	j	80002b96 <wait+0xe0>
    if (!havekids || killed(p))
    80002bc2:	c31d                	beqz	a4,80002be8 <wait+0x132>
    80002bc4:	854a                	mv	a0,s2
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	ebe080e7          	jalr	-322(ra) # 80002a84 <killed>
    80002bce:	ed09                	bnez	a0,80002be8 <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002bd0:	85e2                	mv	a1,s8
    80002bd2:	854a                	mv	a0,s2
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	bfc080e7          	jalr	-1028(ra) # 800027d0 <sleep>
    havekids = 0;
    80002bdc:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002bde:	0000f497          	auipc	s1,0xf
    80002be2:	43248493          	add	s1,s1,1074 # 80012010 <proc>
    80002be6:	bf65                	j	80002b9e <wait+0xe8>
      release(&wait_lock);
    80002be8:	0000e517          	auipc	a0,0xe
    80002bec:	07050513          	add	a0,a0,112 # 80010c58 <wait_lock>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	096080e7          	jalr	150(ra) # 80000c86 <release>
      return -1;
    80002bf8:	59fd                	li	s3,-1
    80002bfa:	b795                	j	80002b5e <wait+0xa8>

0000000080002bfc <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002bfc:	7179                	add	sp,sp,-48
    80002bfe:	f406                	sd	ra,40(sp)
    80002c00:	f022                	sd	s0,32(sp)
    80002c02:	ec26                	sd	s1,24(sp)
    80002c04:	e84a                	sd	s2,16(sp)
    80002c06:	e44e                	sd	s3,8(sp)
    80002c08:	e052                	sd	s4,0(sp)
    80002c0a:	1800                	add	s0,sp,48
    80002c0c:	84aa                	mv	s1,a0
    80002c0e:	892e                	mv	s2,a1
    80002c10:	89b2                	mv	s3,a2
    80002c12:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	eaa080e7          	jalr	-342(ra) # 80001abe <myproc>
  if (user_dst)
    80002c1c:	c08d                	beqz	s1,80002c3e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002c1e:	86d2                	mv	a3,s4
    80002c20:	864e                	mv	a2,s3
    80002c22:	85ca                	mv	a1,s2
    80002c24:	6928                	ld	a0,80(a0)
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	a40080e7          	jalr	-1472(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
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
    memmove((char *)dst, src, len);
    80002c3e:	000a061b          	sext.w	a2,s4
    80002c42:	85ce                	mv	a1,s3
    80002c44:	854a                	mv	a0,s2
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	0e4080e7          	jalr	228(ra) # 80000d2a <memmove>
    return 0;
    80002c4e:	8526                	mv	a0,s1
    80002c50:	bff9                	j	80002c2e <either_copyout+0x32>

0000000080002c52 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c52:	7179                	add	sp,sp,-48
    80002c54:	f406                	sd	ra,40(sp)
    80002c56:	f022                	sd	s0,32(sp)
    80002c58:	ec26                	sd	s1,24(sp)
    80002c5a:	e84a                	sd	s2,16(sp)
    80002c5c:	e44e                	sd	s3,8(sp)
    80002c5e:	e052                	sd	s4,0(sp)
    80002c60:	1800                	add	s0,sp,48
    80002c62:	892a                	mv	s2,a0
    80002c64:	84ae                	mv	s1,a1
    80002c66:	89b2                	mv	s3,a2
    80002c68:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	e54080e7          	jalr	-428(ra) # 80001abe <myproc>
  if (user_src)
    80002c72:	c08d                	beqz	s1,80002c94 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002c74:	86d2                	mv	a3,s4
    80002c76:	864e                	mv	a2,s3
    80002c78:	85ca                	mv	a1,s2
    80002c7a:	6928                	ld	a0,80(a0)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	a76080e7          	jalr	-1418(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6a02                	ld	s4,0(sp)
    80002c90:	6145                	add	sp,sp,48
    80002c92:	8082                	ret
    memmove(dst, (char *)src, len);
    80002c94:	000a061b          	sext.w	a2,s4
    80002c98:	85ce                	mv	a1,s3
    80002c9a:	854a                	mv	a0,s2
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	08e080e7          	jalr	142(ra) # 80000d2a <memmove>
    return 0;
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	bff9                	j	80002c84 <either_copyin+0x32>

0000000080002ca8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002ca8:	715d                	add	sp,sp,-80
    80002caa:	e486                	sd	ra,72(sp)
    80002cac:	e0a2                	sd	s0,64(sp)
    80002cae:	fc26                	sd	s1,56(sp)
    80002cb0:	f84a                	sd	s2,48(sp)
    80002cb2:	f44e                	sd	s3,40(sp)
    80002cb4:	f052                	sd	s4,32(sp)
    80002cb6:	ec56                	sd	s5,24(sp)
    80002cb8:	e85a                	sd	s6,16(sp)
    80002cba:	e45e                	sd	s7,8(sp)
    80002cbc:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	40a50513          	add	a0,a0,1034 # 800080c8 <digits+0x88>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c0080e7          	jalr	-1856(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002cce:	0000f497          	auipc	s1,0xf
    80002cd2:	49a48493          	add	s1,s1,1178 # 80012168 <proc+0x158>
    80002cd6:	00018917          	auipc	s2,0x18
    80002cda:	09290913          	add	s2,s2,146 # 8001ad68 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cde:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002ce0:	00005997          	auipc	s3,0x5
    80002ce4:	5c898993          	add	s3,s3,1480 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002ce8:	00005a97          	auipc	s5,0x5
    80002cec:	5c8a8a93          	add	s5,s5,1480 # 800082b0 <digits+0x270>
    printf("\n");
    80002cf0:	00005a17          	auipc	s4,0x5
    80002cf4:	3d8a0a13          	add	s4,s4,984 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cf8:	00005b97          	auipc	s7,0x5
    80002cfc:	5f8b8b93          	add	s7,s7,1528 # 800082f0 <states.0>
    80002d00:	a00d                	j	80002d22 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d02:	ed86a583          	lw	a1,-296(a3)
    80002d06:	8556                	mv	a0,s5
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	87e080e7          	jalr	-1922(ra) # 80000586 <printf>
    printf("\n");
    80002d10:	8552                	mv	a0,s4
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	874080e7          	jalr	-1932(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d1a:	23048493          	add	s1,s1,560
    80002d1e:	03248263          	beq	s1,s2,80002d42 <procdump+0x9a>
    if (p->state == UNUSED)
    80002d22:	86a6                	mv	a3,s1
    80002d24:	ec04a783          	lw	a5,-320(s1)
    80002d28:	dbed                	beqz	a5,80002d1a <procdump+0x72>
      state = "???";
    80002d2a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d2c:	fcfb6be3          	bltu	s6,a5,80002d02 <procdump+0x5a>
    80002d30:	02079713          	sll	a4,a5,0x20
    80002d34:	01d75793          	srl	a5,a4,0x1d
    80002d38:	97de                	add	a5,a5,s7
    80002d3a:	6390                	ld	a2,0(a5)
    80002d3c:	f279                	bnez	a2,80002d02 <procdump+0x5a>
      state = "???";
    80002d3e:	864e                	mv	a2,s3
    80002d40:	b7c9                	j	80002d02 <procdump+0x5a>
  }
}
    80002d42:	60a6                	ld	ra,72(sp)
    80002d44:	6406                	ld	s0,64(sp)
    80002d46:	74e2                	ld	s1,56(sp)
    80002d48:	7942                	ld	s2,48(sp)
    80002d4a:	79a2                	ld	s3,40(sp)
    80002d4c:	7a02                	ld	s4,32(sp)
    80002d4e:	6ae2                	ld	s5,24(sp)
    80002d50:	6b42                	ld	s6,16(sp)
    80002d52:	6ba2                	ld	s7,8(sp)
    80002d54:	6161                	add	sp,sp,80
    80002d56:	8082                	ret

0000000080002d58 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002d58:	711d                	add	sp,sp,-96
    80002d5a:	ec86                	sd	ra,88(sp)
    80002d5c:	e8a2                	sd	s0,80(sp)
    80002d5e:	e4a6                	sd	s1,72(sp)
    80002d60:	e0ca                	sd	s2,64(sp)
    80002d62:	fc4e                	sd	s3,56(sp)
    80002d64:	f852                	sd	s4,48(sp)
    80002d66:	f456                	sd	s5,40(sp)
    80002d68:	f05a                	sd	s6,32(sp)
    80002d6a:	ec5e                	sd	s7,24(sp)
    80002d6c:	e862                	sd	s8,16(sp)
    80002d6e:	e466                	sd	s9,8(sp)
    80002d70:	e06a                	sd	s10,0(sp)
    80002d72:	1080                	add	s0,sp,96
    80002d74:	8b2a                	mv	s6,a0
    80002d76:	8bae                	mv	s7,a1
    80002d78:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d44080e7          	jalr	-700(ra) # 80001abe <myproc>
    80002d82:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002d84:	0000e517          	auipc	a0,0xe
    80002d88:	ed450513          	add	a0,a0,-300 # 80010c58 <wait_lock>
    80002d8c:	ffffe097          	auipc	ra,0xffffe
    80002d90:	e46080e7          	jalr	-442(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002d94:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002d96:	4a15                	li	s4,5
        havekids = 1;
    80002d98:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002d9a:	00018997          	auipc	s3,0x18
    80002d9e:	e7698993          	add	s3,s3,-394 # 8001ac10 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002da2:	0000ed17          	auipc	s10,0xe
    80002da6:	eb6d0d13          	add	s10,s10,-330 # 80010c58 <wait_lock>
    80002daa:	a8e9                	j	80002e84 <waitx+0x12c>
          pid = np->pid;
    80002dac:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002db0:	1684a783          	lw	a5,360(s1)
    80002db4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002db8:	16c4a703          	lw	a4,364(s1)
    80002dbc:	9f3d                	addw	a4,a4,a5
    80002dbe:	1704a783          	lw	a5,368(s1)
    80002dc2:	9f99                	subw	a5,a5,a4
    80002dc4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002dc8:	000b0e63          	beqz	s6,80002de4 <waitx+0x8c>
    80002dcc:	4691                	li	a3,4
    80002dce:	02c48613          	add	a2,s1,44
    80002dd2:	85da                	mv	a1,s6
    80002dd4:	05093503          	ld	a0,80(s2)
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	88e080e7          	jalr	-1906(ra) # 80001666 <copyout>
    80002de0:	04054363          	bltz	a0,80002e26 <waitx+0xce>
          freeproc(np);
    80002de4:	8526                	mv	a0,s1
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	e8a080e7          	jalr	-374(ra) # 80001c70 <freeproc>
          release(&np->lock);
    80002dee:	8526                	mv	a0,s1
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	e96080e7          	jalr	-362(ra) # 80000c86 <release>
          release(&wait_lock);
    80002df8:	0000e517          	auipc	a0,0xe
    80002dfc:	e6050513          	add	a0,a0,-416 # 80010c58 <wait_lock>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	e86080e7          	jalr	-378(ra) # 80000c86 <release>
  }
}
    80002e08:	854e                	mv	a0,s3
    80002e0a:	60e6                	ld	ra,88(sp)
    80002e0c:	6446                	ld	s0,80(sp)
    80002e0e:	64a6                	ld	s1,72(sp)
    80002e10:	6906                	ld	s2,64(sp)
    80002e12:	79e2                	ld	s3,56(sp)
    80002e14:	7a42                	ld	s4,48(sp)
    80002e16:	7aa2                	ld	s5,40(sp)
    80002e18:	7b02                	ld	s6,32(sp)
    80002e1a:	6be2                	ld	s7,24(sp)
    80002e1c:	6c42                	ld	s8,16(sp)
    80002e1e:	6ca2                	ld	s9,8(sp)
    80002e20:	6d02                	ld	s10,0(sp)
    80002e22:	6125                	add	sp,sp,96
    80002e24:	8082                	ret
            release(&np->lock);
    80002e26:	8526                	mv	a0,s1
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e5e080e7          	jalr	-418(ra) # 80000c86 <release>
            release(&wait_lock);
    80002e30:	0000e517          	auipc	a0,0xe
    80002e34:	e2850513          	add	a0,a0,-472 # 80010c58 <wait_lock>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	e4e080e7          	jalr	-434(ra) # 80000c86 <release>
            return -1;
    80002e40:	59fd                	li	s3,-1
    80002e42:	b7d9                	j	80002e08 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002e44:	23048493          	add	s1,s1,560
    80002e48:	03348463          	beq	s1,s3,80002e70 <waitx+0x118>
      if (np->parent == p)
    80002e4c:	7c9c                	ld	a5,56(s1)
    80002e4e:	ff279be3          	bne	a5,s2,80002e44 <waitx+0xec>
        acquire(&np->lock);
    80002e52:	8526                	mv	a0,s1
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002e5c:	4c9c                	lw	a5,24(s1)
    80002e5e:	f54787e3          	beq	a5,s4,80002dac <waitx+0x54>
        release(&np->lock);
    80002e62:	8526                	mv	a0,s1
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	e22080e7          	jalr	-478(ra) # 80000c86 <release>
        havekids = 1;
    80002e6c:	8756                	mv	a4,s5
    80002e6e:	bfd9                	j	80002e44 <waitx+0xec>
    if (!havekids || p->killed)
    80002e70:	c305                	beqz	a4,80002e90 <waitx+0x138>
    80002e72:	02892783          	lw	a5,40(s2)
    80002e76:	ef89                	bnez	a5,80002e90 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002e78:	85ea                	mv	a1,s10
    80002e7a:	854a                	mv	a0,s2
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	954080e7          	jalr	-1708(ra) # 800027d0 <sleep>
    havekids = 0;
    80002e84:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002e86:	0000f497          	auipc	s1,0xf
    80002e8a:	18a48493          	add	s1,s1,394 # 80012010 <proc>
    80002e8e:	bf7d                	j	80002e4c <waitx+0xf4>
      release(&wait_lock);
    80002e90:	0000e517          	auipc	a0,0xe
    80002e94:	dc850513          	add	a0,a0,-568 # 80010c58 <wait_lock>
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	dee080e7          	jalr	-530(ra) # 80000c86 <release>
      return -1;
    80002ea0:	59fd                	li	s3,-1
    80002ea2:	b79d                	j	80002e08 <waitx+0xb0>

0000000080002ea4 <update_time>:

void update_time()
{
    80002ea4:	7179                	add	sp,sp,-48
    80002ea6:	f406                	sd	ra,40(sp)
    80002ea8:	f022                	sd	s0,32(sp)
    80002eaa:	ec26                	sd	s1,24(sp)
    80002eac:	e84a                	sd	s2,16(sp)
    80002eae:	e44e                	sd	s3,8(sp)
    80002eb0:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002eb2:	0000f497          	auipc	s1,0xf
    80002eb6:	15e48493          	add	s1,s1,350 # 80012010 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002eba:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002ebc:	00018917          	auipc	s2,0x18
    80002ec0:	d5490913          	add	s2,s2,-684 # 8001ac10 <tickslock>
    80002ec4:	a811                	j	80002ed8 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002ec6:	8526                	mv	a0,s1
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dbe080e7          	jalr	-578(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ed0:	23048493          	add	s1,s1,560
    80002ed4:	03248063          	beq	s1,s2,80002ef4 <update_time+0x50>
    acquire(&p->lock);
    80002ed8:	8526                	mv	a0,s1
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	cf8080e7          	jalr	-776(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002ee2:	4c9c                	lw	a5,24(s1)
    80002ee4:	ff3791e3          	bne	a5,s3,80002ec6 <update_time+0x22>
      p->rtime++;
    80002ee8:	1684a783          	lw	a5,360(s1)
    80002eec:	2785                	addw	a5,a5,1
    80002eee:	16f4a423          	sw	a5,360(s1)
    80002ef2:	bfd1                	j	80002ec6 <update_time+0x22>
  }
    80002ef4:	70a2                	ld	ra,40(sp)
    80002ef6:	7402                	ld	s0,32(sp)
    80002ef8:	64e2                	ld	s1,24(sp)
    80002efa:	6942                	ld	s2,16(sp)
    80002efc:	69a2                	ld	s3,8(sp)
    80002efe:	6145                	add	sp,sp,48
    80002f00:	8082                	ret

0000000080002f02 <swtch>:
    80002f02:	00153023          	sd	ra,0(a0)
    80002f06:	00253423          	sd	sp,8(a0)
    80002f0a:	e900                	sd	s0,16(a0)
    80002f0c:	ed04                	sd	s1,24(a0)
    80002f0e:	03253023          	sd	s2,32(a0)
    80002f12:	03353423          	sd	s3,40(a0)
    80002f16:	03453823          	sd	s4,48(a0)
    80002f1a:	03553c23          	sd	s5,56(a0)
    80002f1e:	05653023          	sd	s6,64(a0)
    80002f22:	05753423          	sd	s7,72(a0)
    80002f26:	05853823          	sd	s8,80(a0)
    80002f2a:	05953c23          	sd	s9,88(a0)
    80002f2e:	07a53023          	sd	s10,96(a0)
    80002f32:	07b53423          	sd	s11,104(a0)
    80002f36:	0005b083          	ld	ra,0(a1)
    80002f3a:	0085b103          	ld	sp,8(a1)
    80002f3e:	6980                	ld	s0,16(a1)
    80002f40:	6d84                	ld	s1,24(a1)
    80002f42:	0205b903          	ld	s2,32(a1)
    80002f46:	0285b983          	ld	s3,40(a1)
    80002f4a:	0305ba03          	ld	s4,48(a1)
    80002f4e:	0385ba83          	ld	s5,56(a1)
    80002f52:	0405bb03          	ld	s6,64(a1)
    80002f56:	0485bb83          	ld	s7,72(a1)
    80002f5a:	0505bc03          	ld	s8,80(a1)
    80002f5e:	0585bc83          	ld	s9,88(a1)
    80002f62:	0605bd03          	ld	s10,96(a1)
    80002f66:	0685bd83          	ld	s11,104(a1)
    80002f6a:	8082                	ret

0000000080002f6c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002f6c:	1141                	add	sp,sp,-16
    80002f6e:	e406                	sd	ra,8(sp)
    80002f70:	e022                	sd	s0,0(sp)
    80002f72:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002f74:	00005597          	auipc	a1,0x5
    80002f78:	3ac58593          	add	a1,a1,940 # 80008320 <states.0+0x30>
    80002f7c:	00018517          	auipc	a0,0x18
    80002f80:	c9450513          	add	a0,a0,-876 # 8001ac10 <tickslock>
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	bbe080e7          	jalr	-1090(ra) # 80000b42 <initlock>
}
    80002f8c:	60a2                	ld	ra,8(sp)
    80002f8e:	6402                	ld	s0,0(sp)
    80002f90:	0141                	add	sp,sp,16
    80002f92:	8082                	ret

0000000080002f94 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002f94:	1141                	add	sp,sp,-16
    80002f96:	e422                	sd	s0,8(sp)
    80002f98:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f9a:	00003797          	auipc	a5,0x3
    80002f9e:	6b678793          	add	a5,a5,1718 # 80006650 <kernelvec>
    80002fa2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002fa6:	6422                	ld	s0,8(sp)
    80002fa8:	0141                	add	sp,sp,16
    80002faa:	8082                	ret

0000000080002fac <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002fac:	1141                	add	sp,sp,-16
    80002fae:	e406                	sd	ra,8(sp)
    80002fb0:	e022                	sd	s0,0(sp)
    80002fb2:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	b0a080e7          	jalr	-1270(ra) # 80001abe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fc0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002fc6:	00004697          	auipc	a3,0x4
    80002fca:	03a68693          	add	a3,a3,58 # 80007000 <_trampoline>
    80002fce:	00004717          	auipc	a4,0x4
    80002fd2:	03270713          	add	a4,a4,50 # 80007000 <_trampoline>
    80002fd6:	8f15                	sub	a4,a4,a3
    80002fd8:	040007b7          	lui	a5,0x4000
    80002fdc:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002fde:	07b2                	sll	a5,a5,0xc
    80002fe0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fe2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fe6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fe8:	18002673          	csrr	a2,satp
    80002fec:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fee:	6d30                	ld	a2,88(a0)
    80002ff0:	6138                	ld	a4,64(a0)
    80002ff2:	6585                	lui	a1,0x1
    80002ff4:	972e                	add	a4,a4,a1
    80002ff6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ff8:	6d38                	ld	a4,88(a0)
    80002ffa:	00000617          	auipc	a2,0x0
    80002ffe:	14260613          	add	a2,a2,322 # 8000313c <usertrap>
    80003002:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80003004:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003006:	8612                	mv	a2,tp
    80003008:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000300a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000300e:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003012:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003016:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000301a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000301c:	6f18                	ld	a4,24(a4)
    8000301e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003022:	6928                	ld	a0,80(a0)
    80003024:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80003026:	00004717          	auipc	a4,0x4
    8000302a:	07670713          	add	a4,a4,118 # 8000709c <userret>
    8000302e:	8f15                	sub	a4,a4,a3
    80003030:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80003032:	577d                	li	a4,-1
    80003034:	177e                	sll	a4,a4,0x3f
    80003036:	8d59                	or	a0,a0,a4
    80003038:	9782                	jalr	a5
}
    8000303a:	60a2                	ld	ra,8(sp)
    8000303c:	6402                	ld	s0,0(sp)
    8000303e:	0141                	add	sp,sp,16
    80003040:	8082                	ret

0000000080003042 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80003042:	1101                	add	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	e426                	sd	s1,8(sp)
    8000304a:	e04a                	sd	s2,0(sp)
    8000304c:	1000                	add	s0,sp,32
  acquire(&tickslock);
    8000304e:	00018917          	auipc	s2,0x18
    80003052:	bc290913          	add	s2,s2,-1086 # 8001ac10 <tickslock>
    80003056:	854a                	mv	a0,s2
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	b7a080e7          	jalr	-1158(ra) # 80000bd2 <acquire>
  ticks++;
    80003060:	00006497          	auipc	s1,0x6
    80003064:	93848493          	add	s1,s1,-1736 # 80008998 <ticks>
    80003068:	409c                	lw	a5,0(s1)
    8000306a:	2785                	addw	a5,a5,1
    8000306c:	c09c                	sw	a5,0(s1)
  update_time();
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	e36080e7          	jalr	-458(ra) # 80002ea4 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80003076:	8526                	mv	a0,s1
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	7bc080e7          	jalr	1980(ra) # 80002834 <wakeup>
  release(&tickslock);
    80003080:	854a                	mv	a0,s2
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	c04080e7          	jalr	-1020(ra) # 80000c86 <release>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	64a2                	ld	s1,8(sp)
    80003090:	6902                	ld	s2,0(sp)
    80003092:	6105                	add	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003096:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    8000309a:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    8000309c:	0807df63          	bgez	a5,8000313a <devintr+0xa4>
{
    800030a0:	1101                	add	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    800030aa:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    800030ae:	46a5                	li	a3,9
    800030b0:	00d70d63          	beq	a4,a3,800030ca <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    800030b4:	577d                	li	a4,-1
    800030b6:	177e                	sll	a4,a4,0x3f
    800030b8:	0705                	add	a4,a4,1
    return 0;
    800030ba:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800030bc:	04e78e63          	beq	a5,a4,80003118 <devintr+0x82>
  }
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	add	sp,sp,32
    800030c8:	8082                	ret
    int irq = plic_claim();
    800030ca:	00003097          	auipc	ra,0x3
    800030ce:	68e080e7          	jalr	1678(ra) # 80006758 <plic_claim>
    800030d2:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800030d4:	47a9                	li	a5,10
    800030d6:	02f50763          	beq	a0,a5,80003104 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    800030da:	4785                	li	a5,1
    800030dc:	02f50963          	beq	a0,a5,8000310e <devintr+0x78>
    return 1;
    800030e0:	4505                	li	a0,1
    else if (irq)
    800030e2:	dcf9                	beqz	s1,800030c0 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800030e4:	85a6                	mv	a1,s1
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	24250513          	add	a0,a0,578 # 80008328 <states.0+0x38>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	498080e7          	jalr	1176(ra) # 80000586 <printf>
      plic_complete(irq);
    800030f6:	8526                	mv	a0,s1
    800030f8:	00003097          	auipc	ra,0x3
    800030fc:	684080e7          	jalr	1668(ra) # 8000677c <plic_complete>
    return 1;
    80003100:	4505                	li	a0,1
    80003102:	bf7d                	j	800030c0 <devintr+0x2a>
      uartintr();
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	890080e7          	jalr	-1904(ra) # 80000994 <uartintr>
    if (irq)
    8000310c:	b7ed                	j	800030f6 <devintr+0x60>
      virtio_disk_intr();
    8000310e:	00004097          	auipc	ra,0x4
    80003112:	b34080e7          	jalr	-1228(ra) # 80006c42 <virtio_disk_intr>
    if (irq)
    80003116:	b7c5                	j	800030f6 <devintr+0x60>
    if (cpuid() == 0)
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	97a080e7          	jalr	-1670(ra) # 80001a92 <cpuid>
    80003120:	c901                	beqz	a0,80003130 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003122:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003126:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003128:	14479073          	csrw	sip,a5
    return 2;
    8000312c:	4509                	li	a0,2
    8000312e:	bf49                	j	800030c0 <devintr+0x2a>
      clockintr();
    80003130:	00000097          	auipc	ra,0x0
    80003134:	f12080e7          	jalr	-238(ra) # 80003042 <clockintr>
    80003138:	b7ed                	j	80003122 <devintr+0x8c>
}
    8000313a:	8082                	ret

000000008000313c <usertrap>:
{
    8000313c:	1101                	add	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003146:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    8000314a:	1007f793          	and	a5,a5,256
    8000314e:	e7b1                	bnez	a5,8000319a <usertrap+0x5e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003150:	00003797          	auipc	a5,0x3
    80003154:	50078793          	add	a5,a5,1280 # 80006650 <kernelvec>
    80003158:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	962080e7          	jalr	-1694(ra) # 80001abe <myproc>
    80003164:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003166:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003168:	14102773          	csrr	a4,sepc
    8000316c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000316e:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003172:	47a1                	li	a5,8
    80003174:	02f70b63          	beq	a4,a5,800031aa <usertrap+0x6e>
  else if ((which_dev = devintr()) != 0)
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	f1e080e7          	jalr	-226(ra) # 80003096 <devintr>
    80003180:	cd61                	beqz	a0,80003258 <usertrap+0x11c>
    if (which_dev == 2)
    80003182:	4789                	li	a5,2
    80003184:	04f51663          	bne	a0,a5,800031d0 <usertrap+0x94>
      if (p != 0 && p->state == RUNNING)
    80003188:	4c98                	lw	a4,24(s1)
    8000318a:	4791                	li	a5,4
    8000318c:	06f70763          	beq	a4,a5,800031fa <usertrap+0xbe>
    yield();
    80003190:	fffff097          	auipc	ra,0xfffff
    80003194:	5f6080e7          	jalr	1526(ra) # 80002786 <yield>
    80003198:	a825                	j	800031d0 <usertrap+0x94>
    panic("usertrap: not from user mode");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	1ae50513          	add	a0,a0,430 # 80008348 <states.0+0x58>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	39a080e7          	jalr	922(ra) # 8000053c <panic>
    if (killed(p))
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	8da080e7          	jalr	-1830(ra) # 80002a84 <killed>
    800031b2:	ed15                	bnez	a0,800031ee <usertrap+0xb2>
    p->trapframe->epc += 4;
    800031b4:	6cb8                	ld	a4,88(s1)
    800031b6:	6f1c                	ld	a5,24(a4)
    800031b8:	0791                	add	a5,a5,4
    800031ba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031c0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031c4:	10079073          	csrw	sstatus,a5
    syscall();
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	320080e7          	jalr	800(ra) # 800034e8 <syscall>
  if (killed(p))
    800031d0:	8526                	mv	a0,s1
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	8b2080e7          	jalr	-1870(ra) # 80002a84 <killed>
    800031da:	ed45                	bnez	a0,80003292 <usertrap+0x156>
  usertrapret();
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	dd0080e7          	jalr	-560(ra) # 80002fac <usertrapret>
}
    800031e4:	60e2                	ld	ra,24(sp)
    800031e6:	6442                	ld	s0,16(sp)
    800031e8:	64a2                	ld	s1,8(sp)
    800031ea:	6105                	add	sp,sp,32
    800031ec:	8082                	ret
      exit(-1);
    800031ee:	557d                	li	a0,-1
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	714080e7          	jalr	1812(ra) # 80002904 <exit>
    800031f8:	bf75                	j	800031b4 <usertrap+0x78>
        p->ticks_count++;
    800031fa:	2004a783          	lw	a5,512(s1)
    800031fe:	2785                	addw	a5,a5,1
    80003200:	0007871b          	sext.w	a4,a5
    80003204:	20f4a023          	sw	a5,512(s1)
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    80003208:	1f04a783          	lw	a5,496(s1)
    8000320c:	f8f052e3          	blez	a5,80003190 <usertrap+0x54>
    80003210:	f8f740e3          	blt	a4,a5,80003190 <usertrap+0x54>
    80003214:	2044a783          	lw	a5,516(s1)
    80003218:	dfa5                	beqz	a5,80003190 <usertrap+0x54>
          p->alarm_on = 0; // Disable alarm while handler is running
    8000321a:	2004a223          	sw	zero,516(s1)
          p->alarm_tf = kalloc();
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	8c4080e7          	jalr	-1852(ra) # 80000ae2 <kalloc>
    80003226:	20a4b423          	sd	a0,520(s1)
          if (p->alarm_tf == 0)
    8000322a:	cd19                	beqz	a0,80003248 <usertrap+0x10c>
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    8000322c:	12000613          	li	a2,288
    80003230:	6cac                	ld	a1,88(s1)
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	af8080e7          	jalr	-1288(ra) # 80000d2a <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    8000323a:	6cbc                	ld	a5,88(s1)
    8000323c:	1f84b703          	ld	a4,504(s1)
    80003240:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    80003242:	2004a023          	sw	zero,512(s1)
    80003246:	b7a9                	j	80003190 <usertrap+0x54>
            panic("Error !! usertrap: out of memory");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	12050513          	add	a0,a0,288 # 80008368 <states.0+0x78>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003258:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000325c:	5890                	lw	a2,48(s1)
    8000325e:	00005517          	auipc	a0,0x5
    80003262:	13250513          	add	a0,a0,306 # 80008390 <states.0+0xa0>
    80003266:	ffffd097          	auipc	ra,0xffffd
    8000326a:	320080e7          	jalr	800(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000326e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003272:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	14a50513          	add	a0,a0,330 # 800083c0 <states.0+0xd0>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	308080e7          	jalr	776(ra) # 80000586 <printf>
    setkilled(p);
    80003286:	8526                	mv	a0,s1
    80003288:	fffff097          	auipc	ra,0xfffff
    8000328c:	7d0080e7          	jalr	2000(ra) # 80002a58 <setkilled>
  if (which_dev == 2)
    80003290:	b781                	j	800031d0 <usertrap+0x94>
    exit(-1);
    80003292:	557d                	li	a0,-1
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	670080e7          	jalr	1648(ra) # 80002904 <exit>
    8000329c:	b781                	j	800031dc <usertrap+0xa0>

000000008000329e <kerneltrap>:
{
    8000329e:	7179                	add	sp,sp,-48
    800032a0:	f406                	sd	ra,40(sp)
    800032a2:	f022                	sd	s0,32(sp)
    800032a4:	ec26                	sd	s1,24(sp)
    800032a6:	e84a                	sd	s2,16(sp)
    800032a8:	e44e                	sd	s3,8(sp)
    800032aa:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032ac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032b0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032b4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800032b8:	1004f793          	and	a5,s1,256
    800032bc:	cb85                	beqz	a5,800032ec <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032c2:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    800032c4:	ef85                	bnez	a5,800032fc <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	dd0080e7          	jalr	-560(ra) # 80003096 <devintr>
    800032ce:	cd1d                	beqz	a0,8000330c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032d0:	4789                	li	a5,2
    800032d2:	06f50a63          	beq	a0,a5,80003346 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032d6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032da:	10049073          	csrw	sstatus,s1
}
    800032de:	70a2                	ld	ra,40(sp)
    800032e0:	7402                	ld	s0,32(sp)
    800032e2:	64e2                	ld	s1,24(sp)
    800032e4:	6942                	ld	s2,16(sp)
    800032e6:	69a2                	ld	s3,8(sp)
    800032e8:	6145                	add	sp,sp,48
    800032ea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	0f450513          	add	a0,a0,244 # 800083e0 <states.0+0xf0>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	248080e7          	jalr	584(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800032fc:	00005517          	auipc	a0,0x5
    80003300:	10c50513          	add	a0,a0,268 # 80008408 <states.0+0x118>
    80003304:	ffffd097          	auipc	ra,0xffffd
    80003308:	238080e7          	jalr	568(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    8000330c:	85ce                	mv	a1,s3
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	11a50513          	add	a0,a0,282 # 80008428 <states.0+0x138>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	270080e7          	jalr	624(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000331e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003322:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	11250513          	add	a0,a0,274 # 80008438 <states.0+0x148>
    8000332e:	ffffd097          	auipc	ra,0xffffd
    80003332:	258080e7          	jalr	600(ra) # 80000586 <printf>
    panic("kerneltrap");
    80003336:	00005517          	auipc	a0,0x5
    8000333a:	11a50513          	add	a0,a0,282 # 80008450 <states.0+0x160>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	1fe080e7          	jalr	510(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	778080e7          	jalr	1912(ra) # 80001abe <myproc>
    8000334e:	d541                	beqz	a0,800032d6 <kerneltrap+0x38>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	76e080e7          	jalr	1902(ra) # 80001abe <myproc>
    80003358:	4d18                	lw	a4,24(a0)
    8000335a:	4791                	li	a5,4
    8000335c:	f6f71de3          	bne	a4,a5,800032d6 <kerneltrap+0x38>
    yield();
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	426080e7          	jalr	1062(ra) # 80002786 <yield>
    80003368:	b7bd                	j	800032d6 <kerneltrap+0x38>

000000008000336a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000336a:	1101                	add	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	1000                	add	s0,sp,32
    80003374:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	748080e7          	jalr	1864(ra) # 80001abe <myproc>
  switch (n)
    8000337e:	4795                	li	a5,5
    80003380:	0497e163          	bltu	a5,s1,800033c2 <argraw+0x58>
    80003384:	048a                	sll	s1,s1,0x2
    80003386:	00005717          	auipc	a4,0x5
    8000338a:	10270713          	add	a4,a4,258 # 80008488 <states.0+0x198>
    8000338e:	94ba                	add	s1,s1,a4
    80003390:	409c                	lw	a5,0(s1)
    80003392:	97ba                	add	a5,a5,a4
    80003394:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80003396:	6d3c                	ld	a5,88(a0)
    80003398:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6105                	add	sp,sp,32
    800033a2:	8082                	ret
    return p->trapframe->a1;
    800033a4:	6d3c                	ld	a5,88(a0)
    800033a6:	7fa8                	ld	a0,120(a5)
    800033a8:	bfcd                	j	8000339a <argraw+0x30>
    return p->trapframe->a2;
    800033aa:	6d3c                	ld	a5,88(a0)
    800033ac:	63c8                	ld	a0,128(a5)
    800033ae:	b7f5                	j	8000339a <argraw+0x30>
    return p->trapframe->a3;
    800033b0:	6d3c                	ld	a5,88(a0)
    800033b2:	67c8                	ld	a0,136(a5)
    800033b4:	b7dd                	j	8000339a <argraw+0x30>
    return p->trapframe->a4;
    800033b6:	6d3c                	ld	a5,88(a0)
    800033b8:	6bc8                	ld	a0,144(a5)
    800033ba:	b7c5                	j	8000339a <argraw+0x30>
    return p->trapframe->a5;
    800033bc:	6d3c                	ld	a5,88(a0)
    800033be:	6fc8                	ld	a0,152(a5)
    800033c0:	bfe9                	j	8000339a <argraw+0x30>
  panic("argraw");
    800033c2:	00005517          	auipc	a0,0x5
    800033c6:	09e50513          	add	a0,a0,158 # 80008460 <states.0+0x170>
    800033ca:	ffffd097          	auipc	ra,0xffffd
    800033ce:	172080e7          	jalr	370(ra) # 8000053c <panic>

00000000800033d2 <fetchaddr>:
{
    800033d2:	1101                	add	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	e04a                	sd	s2,0(sp)
    800033dc:	1000                	add	s0,sp,32
    800033de:	84aa                	mv	s1,a0
    800033e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	6dc080e7          	jalr	1756(ra) # 80001abe <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800033ea:	653c                	ld	a5,72(a0)
    800033ec:	02f4f863          	bgeu	s1,a5,8000341c <fetchaddr+0x4a>
    800033f0:	00848713          	add	a4,s1,8
    800033f4:	02e7e663          	bltu	a5,a4,80003420 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033f8:	46a1                	li	a3,8
    800033fa:	8626                	mv	a2,s1
    800033fc:	85ca                	mv	a1,s2
    800033fe:	6928                	ld	a0,80(a0)
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	2f2080e7          	jalr	754(ra) # 800016f2 <copyin>
    80003408:	00a03533          	snez	a0,a0
    8000340c:	40a00533          	neg	a0,a0
}
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	64a2                	ld	s1,8(sp)
    80003416:	6902                	ld	s2,0(sp)
    80003418:	6105                	add	sp,sp,32
    8000341a:	8082                	ret
    return -1;
    8000341c:	557d                	li	a0,-1
    8000341e:	bfcd                	j	80003410 <fetchaddr+0x3e>
    80003420:	557d                	li	a0,-1
    80003422:	b7fd                	j	80003410 <fetchaddr+0x3e>

0000000080003424 <fetchstr>:
{
    80003424:	7179                	add	sp,sp,-48
    80003426:	f406                	sd	ra,40(sp)
    80003428:	f022                	sd	s0,32(sp)
    8000342a:	ec26                	sd	s1,24(sp)
    8000342c:	e84a                	sd	s2,16(sp)
    8000342e:	e44e                	sd	s3,8(sp)
    80003430:	1800                	add	s0,sp,48
    80003432:	892a                	mv	s2,a0
    80003434:	84ae                	mv	s1,a1
    80003436:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	686080e7          	jalr	1670(ra) # 80001abe <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003440:	86ce                	mv	a3,s3
    80003442:	864a                	mv	a2,s2
    80003444:	85a6                	mv	a1,s1
    80003446:	6928                	ld	a0,80(a0)
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	338080e7          	jalr	824(ra) # 80001780 <copyinstr>
    80003450:	00054e63          	bltz	a0,8000346c <fetchstr+0x48>
  return strlen(buf);
    80003454:	8526                	mv	a0,s1
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	9f2080e7          	jalr	-1550(ra) # 80000e48 <strlen>
}
    8000345e:	70a2                	ld	ra,40(sp)
    80003460:	7402                	ld	s0,32(sp)
    80003462:	64e2                	ld	s1,24(sp)
    80003464:	6942                	ld	s2,16(sp)
    80003466:	69a2                	ld	s3,8(sp)
    80003468:	6145                	add	sp,sp,48
    8000346a:	8082                	ret
    return -1;
    8000346c:	557d                	li	a0,-1
    8000346e:	bfc5                	j	8000345e <fetchstr+0x3a>

0000000080003470 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003470:	1101                	add	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	1000                	add	s0,sp,32
    8000347a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	eee080e7          	jalr	-274(ra) # 8000336a <argraw>
    80003484:	c088                	sw	a0,0(s1)
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6105                	add	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003490:	1101                	add	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	1000                	add	s0,sp,32
    8000349a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	ece080e7          	jalr	-306(ra) # 8000336a <argraw>
    800034a4:	e088                	sd	a0,0(s1)
}
    800034a6:	60e2                	ld	ra,24(sp)
    800034a8:	6442                	ld	s0,16(sp)
    800034aa:	64a2                	ld	s1,8(sp)
    800034ac:	6105                	add	sp,sp,32
    800034ae:	8082                	ret

00000000800034b0 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800034b0:	7179                	add	sp,sp,-48
    800034b2:	f406                	sd	ra,40(sp)
    800034b4:	f022                	sd	s0,32(sp)
    800034b6:	ec26                	sd	s1,24(sp)
    800034b8:	e84a                	sd	s2,16(sp)
    800034ba:	1800                	add	s0,sp,48
    800034bc:	84ae                	mv	s1,a1
    800034be:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800034c0:	fd840593          	add	a1,s0,-40
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	fcc080e7          	jalr	-52(ra) # 80003490 <argaddr>
  return fetchstr(addr, buf, max);
    800034cc:	864a                	mv	a2,s2
    800034ce:	85a6                	mv	a1,s1
    800034d0:	fd843503          	ld	a0,-40(s0)
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	f50080e7          	jalr	-176(ra) # 80003424 <fetchstr>
}
    800034dc:	70a2                	ld	ra,40(sp)
    800034de:	7402                	ld	s0,32(sp)
    800034e0:	64e2                	ld	s1,24(sp)
    800034e2:	6942                	ld	s2,16(sp)
    800034e4:	6145                	add	sp,sp,48
    800034e6:	8082                	ret

00000000800034e8 <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    800034e8:	1101                	add	sp,sp,-32
    800034ea:	ec06                	sd	ra,24(sp)
    800034ec:	e822                	sd	s0,16(sp)
    800034ee:	e426                	sd	s1,8(sp)
    800034f0:	e04a                	sd	s2,0(sp)
    800034f2:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	5ca080e7          	jalr	1482(ra) # 80001abe <myproc>
    800034fc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034fe:	05853903          	ld	s2,88(a0)
    80003502:	0a893783          	ld	a5,168(s2)
    80003506:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000350a:	37fd                	addw	a5,a5,-1
    8000350c:	4765                	li	a4,25
    8000350e:	02f76763          	bltu	a4,a5,8000353c <syscall+0x54>
    80003512:	00369713          	sll	a4,a3,0x3
    80003516:	00005797          	auipc	a5,0x5
    8000351a:	f8a78793          	add	a5,a5,-118 # 800084a0 <syscalls>
    8000351e:	97ba                	add	a5,a5,a4
    80003520:	6398                	ld	a4,0(a5)
    80003522:	cf09                	beqz	a4,8000353c <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    80003524:	068a                	sll	a3,a3,0x2
    80003526:	00d504b3          	add	s1,a0,a3
    8000352a:	1704a783          	lw	a5,368(s1)
    8000352e:	2785                	addw	a5,a5,1
    80003530:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    80003534:	9702                	jalr	a4
    80003536:	06a93823          	sd	a0,112(s2)
    8000353a:	a839                	j	80003558 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    8000353c:	15848613          	add	a2,s1,344
    80003540:	588c                	lw	a1,48(s1)
    80003542:	00005517          	auipc	a0,0x5
    80003546:	f2650513          	add	a0,a0,-218 # 80008468 <states.0+0x178>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	03c080e7          	jalr	60(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003552:	6cbc                	ld	a5,88(s1)
    80003554:	577d                	li	a4,-1
    80003556:	fbb8                	sd	a4,112(a5)
  }
}
    80003558:	60e2                	ld	ra,24(sp)
    8000355a:	6442                	ld	s0,16(sp)
    8000355c:	64a2                	ld	s1,8(sp)
    8000355e:	6902                	ld	s2,0(sp)
    80003560:	6105                	add	sp,sp,32
    80003562:	8082                	ret

0000000080003564 <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    80003564:	1101                	add	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    8000356c:	fec40593          	add	a1,s0,-20
    80003570:	4501                	li	a0,0
    80003572:	00000097          	auipc	ra,0x0
    80003576:	efe080e7          	jalr	-258(ra) # 80003470 <argint>
  exit(n);
    8000357a:	fec42503          	lw	a0,-20(s0)
    8000357e:	fffff097          	auipc	ra,0xfffff
    80003582:	386080e7          	jalr	902(ra) # 80002904 <exit>
  return 0; // not reached
}
    80003586:	4501                	li	a0,0
    80003588:	60e2                	ld	ra,24(sp)
    8000358a:	6442                	ld	s0,16(sp)
    8000358c:	6105                	add	sp,sp,32
    8000358e:	8082                	ret

0000000080003590 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003590:	1141                	add	sp,sp,-16
    80003592:	e406                	sd	ra,8(sp)
    80003594:	e022                	sd	s0,0(sp)
    80003596:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003598:	ffffe097          	auipc	ra,0xffffe
    8000359c:	526080e7          	jalr	1318(ra) # 80001abe <myproc>
}
    800035a0:	5908                	lw	a0,48(a0)
    800035a2:	60a2                	ld	ra,8(sp)
    800035a4:	6402                	ld	s0,0(sp)
    800035a6:	0141                	add	sp,sp,16
    800035a8:	8082                	ret

00000000800035aa <sys_fork>:

uint64
sys_fork(void)
{
    800035aa:	1141                	add	sp,sp,-16
    800035ac:	e406                	sd	ra,8(sp)
    800035ae:	e022                	sd	s0,0(sp)
    800035b0:	0800                	add	s0,sp,16
  return fork();
    800035b2:	fffff097          	auipc	ra,0xfffff
    800035b6:	926080e7          	jalr	-1754(ra) # 80001ed8 <fork>
}
    800035ba:	60a2                	ld	ra,8(sp)
    800035bc:	6402                	ld	s0,0(sp)
    800035be:	0141                	add	sp,sp,16
    800035c0:	8082                	ret

00000000800035c2 <sys_wait>:

uint64
sys_wait(void)
{
    800035c2:	1101                	add	sp,sp,-32
    800035c4:	ec06                	sd	ra,24(sp)
    800035c6:	e822                	sd	s0,16(sp)
    800035c8:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800035ca:	fe840593          	add	a1,s0,-24
    800035ce:	4501                	li	a0,0
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	ec0080e7          	jalr	-320(ra) # 80003490 <argaddr>
  return wait(p);
    800035d8:	fe843503          	ld	a0,-24(s0)
    800035dc:	fffff097          	auipc	ra,0xfffff
    800035e0:	4da080e7          	jalr	1242(ra) # 80002ab6 <wait>
}
    800035e4:	60e2                	ld	ra,24(sp)
    800035e6:	6442                	ld	s0,16(sp)
    800035e8:	6105                	add	sp,sp,32
    800035ea:	8082                	ret

00000000800035ec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035ec:	7179                	add	sp,sp,-48
    800035ee:	f406                	sd	ra,40(sp)
    800035f0:	f022                	sd	s0,32(sp)
    800035f2:	ec26                	sd	s1,24(sp)
    800035f4:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800035f6:	fdc40593          	add	a1,s0,-36
    800035fa:	4501                	li	a0,0
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e74080e7          	jalr	-396(ra) # 80003470 <argint>
  addr = myproc()->sz;
    80003604:	ffffe097          	auipc	ra,0xffffe
    80003608:	4ba080e7          	jalr	1210(ra) # 80001abe <myproc>
    8000360c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000360e:	fdc42503          	lw	a0,-36(s0)
    80003612:	fffff097          	auipc	ra,0xfffff
    80003616:	86a080e7          	jalr	-1942(ra) # 80001e7c <growproc>
    8000361a:	00054863          	bltz	a0,8000362a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000361e:	8526                	mv	a0,s1
    80003620:	70a2                	ld	ra,40(sp)
    80003622:	7402                	ld	s0,32(sp)
    80003624:	64e2                	ld	s1,24(sp)
    80003626:	6145                	add	sp,sp,48
    80003628:	8082                	ret
    return -1;
    8000362a:	54fd                	li	s1,-1
    8000362c:	bfcd                	j	8000361e <sys_sbrk+0x32>

000000008000362e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000362e:	7139                	add	sp,sp,-64
    80003630:	fc06                	sd	ra,56(sp)
    80003632:	f822                	sd	s0,48(sp)
    80003634:	f426                	sd	s1,40(sp)
    80003636:	f04a                	sd	s2,32(sp)
    80003638:	ec4e                	sd	s3,24(sp)
    8000363a:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000363c:	fcc40593          	add	a1,s0,-52
    80003640:	4501                	li	a0,0
    80003642:	00000097          	auipc	ra,0x0
    80003646:	e2e080e7          	jalr	-466(ra) # 80003470 <argint>
  acquire(&tickslock);
    8000364a:	00017517          	auipc	a0,0x17
    8000364e:	5c650513          	add	a0,a0,1478 # 8001ac10 <tickslock>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	580080e7          	jalr	1408(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000365a:	00005917          	auipc	s2,0x5
    8000365e:	33e92903          	lw	s2,830(s2) # 80008998 <ticks>
  while (ticks - ticks0 < n)
    80003662:	fcc42783          	lw	a5,-52(s0)
    80003666:	cf9d                	beqz	a5,800036a4 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003668:	00017997          	auipc	s3,0x17
    8000366c:	5a898993          	add	s3,s3,1448 # 8001ac10 <tickslock>
    80003670:	00005497          	auipc	s1,0x5
    80003674:	32848493          	add	s1,s1,808 # 80008998 <ticks>
    if (killed(myproc()))
    80003678:	ffffe097          	auipc	ra,0xffffe
    8000367c:	446080e7          	jalr	1094(ra) # 80001abe <myproc>
    80003680:	fffff097          	auipc	ra,0xfffff
    80003684:	404080e7          	jalr	1028(ra) # 80002a84 <killed>
    80003688:	ed15                	bnez	a0,800036c4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000368a:	85ce                	mv	a1,s3
    8000368c:	8526                	mv	a0,s1
    8000368e:	fffff097          	auipc	ra,0xfffff
    80003692:	142080e7          	jalr	322(ra) # 800027d0 <sleep>
  while (ticks - ticks0 < n)
    80003696:	409c                	lw	a5,0(s1)
    80003698:	412787bb          	subw	a5,a5,s2
    8000369c:	fcc42703          	lw	a4,-52(s0)
    800036a0:	fce7ece3          	bltu	a5,a4,80003678 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800036a4:	00017517          	auipc	a0,0x17
    800036a8:	56c50513          	add	a0,a0,1388 # 8001ac10 <tickslock>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	5da080e7          	jalr	1498(ra) # 80000c86 <release>
  return 0;
    800036b4:	4501                	li	a0,0
}
    800036b6:	70e2                	ld	ra,56(sp)
    800036b8:	7442                	ld	s0,48(sp)
    800036ba:	74a2                	ld	s1,40(sp)
    800036bc:	7902                	ld	s2,32(sp)
    800036be:	69e2                	ld	s3,24(sp)
    800036c0:	6121                	add	sp,sp,64
    800036c2:	8082                	ret
      release(&tickslock);
    800036c4:	00017517          	auipc	a0,0x17
    800036c8:	54c50513          	add	a0,a0,1356 # 8001ac10 <tickslock>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	5ba080e7          	jalr	1466(ra) # 80000c86 <release>
      return -1;
    800036d4:	557d                	li	a0,-1
    800036d6:	b7c5                	j	800036b6 <sys_sleep+0x88>

00000000800036d8 <sys_kill>:

uint64
sys_kill(void)
{
    800036d8:	1101                	add	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800036e0:	fec40593          	add	a1,s0,-20
    800036e4:	4501                	li	a0,0
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	d8a080e7          	jalr	-630(ra) # 80003470 <argint>
  return kill(pid);
    800036ee:	fec42503          	lw	a0,-20(s0)
    800036f2:	fffff097          	auipc	ra,0xfffff
    800036f6:	2f4080e7          	jalr	756(ra) # 800029e6 <kill>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	6105                	add	sp,sp,32
    80003700:	8082                	ret

0000000080003702 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003702:	1101                	add	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000370c:	00017517          	auipc	a0,0x17
    80003710:	50450513          	add	a0,a0,1284 # 8001ac10 <tickslock>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	4be080e7          	jalr	1214(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000371c:	00005497          	auipc	s1,0x5
    80003720:	27c4a483          	lw	s1,636(s1) # 80008998 <ticks>
  release(&tickslock);
    80003724:	00017517          	auipc	a0,0x17
    80003728:	4ec50513          	add	a0,a0,1260 # 8001ac10 <tickslock>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	55a080e7          	jalr	1370(ra) # 80000c86 <release>
  return xticks;
}
    80003734:	02049513          	sll	a0,s1,0x20
    80003738:	9101                	srl	a0,a0,0x20
    8000373a:	60e2                	ld	ra,24(sp)
    8000373c:	6442                	ld	s0,16(sp)
    8000373e:	64a2                	ld	s1,8(sp)
    80003740:	6105                	add	sp,sp,32
    80003742:	8082                	ret

0000000080003744 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003744:	7139                	add	sp,sp,-64
    80003746:	fc06                	sd	ra,56(sp)
    80003748:	f822                	sd	s0,48(sp)
    8000374a:	f426                	sd	s1,40(sp)
    8000374c:	f04a                	sd	s2,32(sp)
    8000374e:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003750:	fd840593          	add	a1,s0,-40
    80003754:	4501                	li	a0,0
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	d3a080e7          	jalr	-710(ra) # 80003490 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000375e:	fd040593          	add	a1,s0,-48
    80003762:	4505                	li	a0,1
    80003764:	00000097          	auipc	ra,0x0
    80003768:	d2c080e7          	jalr	-724(ra) # 80003490 <argaddr>
  argaddr(2, &addr2);
    8000376c:	fc840593          	add	a1,s0,-56
    80003770:	4509                	li	a0,2
    80003772:	00000097          	auipc	ra,0x0
    80003776:	d1e080e7          	jalr	-738(ra) # 80003490 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000377a:	fc040613          	add	a2,s0,-64
    8000377e:	fc440593          	add	a1,s0,-60
    80003782:	fd843503          	ld	a0,-40(s0)
    80003786:	fffff097          	auipc	ra,0xfffff
    8000378a:	5d2080e7          	jalr	1490(ra) # 80002d58 <waitx>
    8000378e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003790:	ffffe097          	auipc	ra,0xffffe
    80003794:	32e080e7          	jalr	814(ra) # 80001abe <myproc>
    80003798:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000379a:	4691                	li	a3,4
    8000379c:	fc440613          	add	a2,s0,-60
    800037a0:	fd043583          	ld	a1,-48(s0)
    800037a4:	6928                	ld	a0,80(a0)
    800037a6:	ffffe097          	auipc	ra,0xffffe
    800037aa:	ec0080e7          	jalr	-320(ra) # 80001666 <copyout>
    return -1;
    800037ae:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800037b0:	00054f63          	bltz	a0,800037ce <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800037b4:	4691                	li	a3,4
    800037b6:	fc040613          	add	a2,s0,-64
    800037ba:	fc843583          	ld	a1,-56(s0)
    800037be:	68a8                	ld	a0,80(s1)
    800037c0:	ffffe097          	auipc	ra,0xffffe
    800037c4:	ea6080e7          	jalr	-346(ra) # 80001666 <copyout>
    800037c8:	00054a63          	bltz	a0,800037dc <sys_waitx+0x98>
    return -1;
  return ret;
    800037cc:	87ca                	mv	a5,s2
}
    800037ce:	853e                	mv	a0,a5
    800037d0:	70e2                	ld	ra,56(sp)
    800037d2:	7442                	ld	s0,48(sp)
    800037d4:	74a2                	ld	s1,40(sp)
    800037d6:	7902                	ld	s2,32(sp)
    800037d8:	6121                	add	sp,sp,64
    800037da:	8082                	ret
    return -1;
    800037dc:	57fd                	li	a5,-1
    800037de:	bfc5                	j	800037ce <sys_waitx+0x8a>

00000000800037e0 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    800037e0:	7179                	add	sp,sp,-48
    800037e2:	f406                	sd	ra,40(sp)
    800037e4:	f022                	sd	s0,32(sp)
    800037e6:	ec26                	sd	s1,24(sp)
    800037e8:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    800037ea:	ffffe097          	auipc	ra,0xffffe
    800037ee:	2d4080e7          	jalr	724(ra) # 80001abe <myproc>
    800037f2:	84aa                	mv	s1,a0
  // for (int i = 0; i < 31; i++)
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }

  argint(0, &mask);
    800037f4:	fdc40593          	add	a1,s0,-36
    800037f8:	4501                	li	a0,0
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	c76080e7          	jalr	-906(ra) # 80003470 <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    80003802:	fdc42583          	lw	a1,-36(s0)
    80003806:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    8000380a:	4781                	li	a5,0
  int count = 0;
    8000380c:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    8000380e:	467d                	li	a2,31
    80003810:	a029                	j	8000381a <sys_getSysCount+0x3a>
    80003812:	2785                	addw	a5,a5,1
    80003814:	0691                	add	a3,a3,4
    80003816:	00c78963          	beq	a5,a2,80003828 <sys_getSysCount+0x48>
    if (mask & (1 << i))
    8000381a:	40f5d73b          	sraw	a4,a1,a5
    8000381e:	8b05                	and	a4,a4,1
    80003820:	db6d                	beqz	a4,80003812 <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i - 1]; // Add up the syscall counts
    80003822:	4298                	lw	a4,0(a3)
    80003824:	9d39                	addw	a0,a0,a4
    80003826:	b7f5                	j	80003812 <sys_getSysCount+0x32>
    }
  }

  return count;
}
    80003828:	70a2                	ld	ra,40(sp)
    8000382a:	7402                	ld	s0,32(sp)
    8000382c:	64e2                	ld	s1,24(sp)
    8000382e:	6145                	add	sp,sp,48
    80003830:	8082                	ret

0000000080003832 <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    80003832:	1101                	add	sp,sp,-32
    80003834:	ec06                	sd	ra,24(sp)
    80003836:	e822                	sd	s0,16(sp)
    80003838:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    8000383a:	fec40593          	add	a1,s0,-20
    8000383e:	4501                	li	a0,0
    80003840:	00000097          	auipc	ra,0x0
    80003844:	c30080e7          	jalr	-976(ra) # 80003470 <argint>

  argaddr(1, &handler);
    80003848:	fe040593          	add	a1,s0,-32
    8000384c:	4505                	li	a0,1
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	c42080e7          	jalr	-958(ra) # 80003490 <argaddr>

  struct proc *p = myproc();
    80003856:	ffffe097          	auipc	ra,0xffffe
    8000385a:	268080e7          	jalr	616(ra) # 80001abe <myproc>
  p->alarm_interval = interval;
    8000385e:	fec42783          	lw	a5,-20(s0)
    80003862:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void (*)())handler;
    80003866:	fe043703          	ld	a4,-32(s0)
    8000386a:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    8000386e:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    80003872:	00f027b3          	sgtz	a5,a5
    80003876:	20f52223          	sw	a5,516(a0)

  return 0;
}
    8000387a:	4501                	li	a0,0
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	6105                	add	sp,sp,32
    80003882:	8082                	ret

0000000080003884 <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    80003884:	1101                	add	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000388e:	ffffe097          	auipc	ra,0xffffe
    80003892:	230080e7          	jalr	560(ra) # 80001abe <myproc>

  if (p->alarm_tf)
    80003896:	20853583          	ld	a1,520(a0)
    8000389a:	c585                	beqz	a1,800038c2 <sys_sigreturn+0x3e>
    8000389c:	84aa                	mv	s1,a0
  {
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    8000389e:	12000613          	li	a2,288
    800038a2:	6d28                	ld	a0,88(a0)
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	486080e7          	jalr	1158(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    800038ac:	2084b503          	ld	a0,520(s1)
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	134080e7          	jalr	308(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    800038b8:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1; // Re-enable the alarm
    800038bc:	4785                	li	a5,1
    800038be:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret(); // function that returns the command back to the user space
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	6ea080e7          	jalr	1770(ra) # 80002fac <usertrapret>
  return 0;
}
    800038ca:	4501                	li	a0,0
    800038cc:	60e2                	ld	ra,24(sp)
    800038ce:	6442                	ld	s0,16(sp)
    800038d0:	64a2                	ld	s1,8(sp)
    800038d2:	6105                	add	sp,sp,32
    800038d4:	8082                	ret

00000000800038d6 <sys_settickets>:

// settickets system call
uint64 sys_settickets(void)
{
    800038d6:	1101                	add	sp,sp,-32
    800038d8:	ec06                	sd	ra,24(sp)
    800038da:	e822                	sd	s0,16(sp)
    800038dc:	1000                	add	s0,sp,32
  int n;

  // Get the number of tickets from the user
  argint(0, &n);
    800038de:	fec40593          	add	a1,s0,-20
    800038e2:	4501                	li	a0,0
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	b8c080e7          	jalr	-1140(ra) # 80003470 <argint>
  // Ensure the ticket number is valid (greater than 0)
  if (n < 1)
    800038ec:	fec42783          	lw	a5,-20(s0)
    800038f0:	00f05f63          	blez	a5,8000390e <sys_settickets+0x38>
    printf("entered ticket is invalid error");
    return -1; // Error: invalid ticket count
  }

  // Set the calling process's ticket count
  myproc()->tickets = n;
    800038f4:	ffffe097          	auipc	ra,0xffffe
    800038f8:	1ca080e7          	jalr	458(ra) # 80001abe <myproc>
    800038fc:	fec42783          	lw	a5,-20(s0)
    80003900:	20f52823          	sw	a5,528(a0)

  return 0; // Success
    80003904:	4501                	li	a0,0
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	6105                	add	sp,sp,32
    8000390c:	8082                	ret
    printf("entered ticket is invalid error");
    8000390e:	00005517          	auipc	a0,0x5
    80003912:	c6a50513          	add	a0,a0,-918 # 80008578 <syscalls+0xd8>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	c70080e7          	jalr	-912(ra) # 80000586 <printf>
    return -1; // Error: invalid ticket count
    8000391e:	557d                	li	a0,-1
    80003920:	b7dd                	j	80003906 <sys_settickets+0x30>

0000000080003922 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003922:	7179                	add	sp,sp,-48
    80003924:	f406                	sd	ra,40(sp)
    80003926:	f022                	sd	s0,32(sp)
    80003928:	ec26                	sd	s1,24(sp)
    8000392a:	e84a                	sd	s2,16(sp)
    8000392c:	e44e                	sd	s3,8(sp)
    8000392e:	e052                	sd	s4,0(sp)
    80003930:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003932:	00005597          	auipc	a1,0x5
    80003936:	c6658593          	add	a1,a1,-922 # 80008598 <syscalls+0xf8>
    8000393a:	00017517          	auipc	a0,0x17
    8000393e:	2ee50513          	add	a0,a0,750 # 8001ac28 <bcache>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	200080e7          	jalr	512(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000394a:	0001f797          	auipc	a5,0x1f
    8000394e:	2de78793          	add	a5,a5,734 # 80022c28 <bcache+0x8000>
    80003952:	0001f717          	auipc	a4,0x1f
    80003956:	53e70713          	add	a4,a4,1342 # 80022e90 <bcache+0x8268>
    8000395a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000395e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003962:	00017497          	auipc	s1,0x17
    80003966:	2de48493          	add	s1,s1,734 # 8001ac40 <bcache+0x18>
    b->next = bcache.head.next;
    8000396a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000396c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000396e:	00005a17          	auipc	s4,0x5
    80003972:	c32a0a13          	add	s4,s4,-974 # 800085a0 <syscalls+0x100>
    b->next = bcache.head.next;
    80003976:	2b893783          	ld	a5,696(s2)
    8000397a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000397c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003980:	85d2                	mv	a1,s4
    80003982:	01048513          	add	a0,s1,16
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	496080e7          	jalr	1174(ra) # 80004e1c <initsleeplock>
    bcache.head.next->prev = b;
    8000398e:	2b893783          	ld	a5,696(s2)
    80003992:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003994:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003998:	45848493          	add	s1,s1,1112
    8000399c:	fd349de3          	bne	s1,s3,80003976 <binit+0x54>
  }
}
    800039a0:	70a2                	ld	ra,40(sp)
    800039a2:	7402                	ld	s0,32(sp)
    800039a4:	64e2                	ld	s1,24(sp)
    800039a6:	6942                	ld	s2,16(sp)
    800039a8:	69a2                	ld	s3,8(sp)
    800039aa:	6a02                	ld	s4,0(sp)
    800039ac:	6145                	add	sp,sp,48
    800039ae:	8082                	ret

00000000800039b0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800039b0:	7179                	add	sp,sp,-48
    800039b2:	f406                	sd	ra,40(sp)
    800039b4:	f022                	sd	s0,32(sp)
    800039b6:	ec26                	sd	s1,24(sp)
    800039b8:	e84a                	sd	s2,16(sp)
    800039ba:	e44e                	sd	s3,8(sp)
    800039bc:	1800                	add	s0,sp,48
    800039be:	892a                	mv	s2,a0
    800039c0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800039c2:	00017517          	auipc	a0,0x17
    800039c6:	26650513          	add	a0,a0,614 # 8001ac28 <bcache>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	208080e7          	jalr	520(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800039d2:	0001f497          	auipc	s1,0x1f
    800039d6:	50e4b483          	ld	s1,1294(s1) # 80022ee0 <bcache+0x82b8>
    800039da:	0001f797          	auipc	a5,0x1f
    800039de:	4b678793          	add	a5,a5,1206 # 80022e90 <bcache+0x8268>
    800039e2:	02f48f63          	beq	s1,a5,80003a20 <bread+0x70>
    800039e6:	873e                	mv	a4,a5
    800039e8:	a021                	j	800039f0 <bread+0x40>
    800039ea:	68a4                	ld	s1,80(s1)
    800039ec:	02e48a63          	beq	s1,a4,80003a20 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800039f0:	449c                	lw	a5,8(s1)
    800039f2:	ff279ce3          	bne	a5,s2,800039ea <bread+0x3a>
    800039f6:	44dc                	lw	a5,12(s1)
    800039f8:	ff3799e3          	bne	a5,s3,800039ea <bread+0x3a>
      b->refcnt++;
    800039fc:	40bc                	lw	a5,64(s1)
    800039fe:	2785                	addw	a5,a5,1
    80003a00:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a02:	00017517          	auipc	a0,0x17
    80003a06:	22650513          	add	a0,a0,550 # 8001ac28 <bcache>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	27c080e7          	jalr	636(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003a12:	01048513          	add	a0,s1,16
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	440080e7          	jalr	1088(ra) # 80004e56 <acquiresleep>
      return b;
    80003a1e:	a8b9                	j	80003a7c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a20:	0001f497          	auipc	s1,0x1f
    80003a24:	4b84b483          	ld	s1,1208(s1) # 80022ed8 <bcache+0x82b0>
    80003a28:	0001f797          	auipc	a5,0x1f
    80003a2c:	46878793          	add	a5,a5,1128 # 80022e90 <bcache+0x8268>
    80003a30:	00f48863          	beq	s1,a5,80003a40 <bread+0x90>
    80003a34:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003a36:	40bc                	lw	a5,64(s1)
    80003a38:	cf81                	beqz	a5,80003a50 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a3a:	64a4                	ld	s1,72(s1)
    80003a3c:	fee49de3          	bne	s1,a4,80003a36 <bread+0x86>
  panic("bget: no buffers");
    80003a40:	00005517          	auipc	a0,0x5
    80003a44:	b6850513          	add	a0,a0,-1176 # 800085a8 <syscalls+0x108>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	af4080e7          	jalr	-1292(ra) # 8000053c <panic>
      b->dev = dev;
    80003a50:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003a54:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003a58:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a5c:	4785                	li	a5,1
    80003a5e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a60:	00017517          	auipc	a0,0x17
    80003a64:	1c850513          	add	a0,a0,456 # 8001ac28 <bcache>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	21e080e7          	jalr	542(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003a70:	01048513          	add	a0,s1,16
    80003a74:	00001097          	auipc	ra,0x1
    80003a78:	3e2080e7          	jalr	994(ra) # 80004e56 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a7c:	409c                	lw	a5,0(s1)
    80003a7e:	cb89                	beqz	a5,80003a90 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a80:	8526                	mv	a0,s1
    80003a82:	70a2                	ld	ra,40(sp)
    80003a84:	7402                	ld	s0,32(sp)
    80003a86:	64e2                	ld	s1,24(sp)
    80003a88:	6942                	ld	s2,16(sp)
    80003a8a:	69a2                	ld	s3,8(sp)
    80003a8c:	6145                	add	sp,sp,48
    80003a8e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a90:	4581                	li	a1,0
    80003a92:	8526                	mv	a0,s1
    80003a94:	00003097          	auipc	ra,0x3
    80003a98:	f7e080e7          	jalr	-130(ra) # 80006a12 <virtio_disk_rw>
    b->valid = 1;
    80003a9c:	4785                	li	a5,1
    80003a9e:	c09c                	sw	a5,0(s1)
  return b;
    80003aa0:	b7c5                	j	80003a80 <bread+0xd0>

0000000080003aa2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003aa2:	1101                	add	sp,sp,-32
    80003aa4:	ec06                	sd	ra,24(sp)
    80003aa6:	e822                	sd	s0,16(sp)
    80003aa8:	e426                	sd	s1,8(sp)
    80003aaa:	1000                	add	s0,sp,32
    80003aac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003aae:	0541                	add	a0,a0,16
    80003ab0:	00001097          	auipc	ra,0x1
    80003ab4:	440080e7          	jalr	1088(ra) # 80004ef0 <holdingsleep>
    80003ab8:	cd01                	beqz	a0,80003ad0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003aba:	4585                	li	a1,1
    80003abc:	8526                	mv	a0,s1
    80003abe:	00003097          	auipc	ra,0x3
    80003ac2:	f54080e7          	jalr	-172(ra) # 80006a12 <virtio_disk_rw>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6105                	add	sp,sp,32
    80003ace:	8082                	ret
    panic("bwrite");
    80003ad0:	00005517          	auipc	a0,0x5
    80003ad4:	af050513          	add	a0,a0,-1296 # 800085c0 <syscalls+0x120>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	a64080e7          	jalr	-1436(ra) # 8000053c <panic>

0000000080003ae0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003ae0:	1101                	add	sp,sp,-32
    80003ae2:	ec06                	sd	ra,24(sp)
    80003ae4:	e822                	sd	s0,16(sp)
    80003ae6:	e426                	sd	s1,8(sp)
    80003ae8:	e04a                	sd	s2,0(sp)
    80003aea:	1000                	add	s0,sp,32
    80003aec:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003aee:	01050913          	add	s2,a0,16
    80003af2:	854a                	mv	a0,s2
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	3fc080e7          	jalr	1020(ra) # 80004ef0 <holdingsleep>
    80003afc:	c925                	beqz	a0,80003b6c <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	3ac080e7          	jalr	940(ra) # 80004eac <releasesleep>

  acquire(&bcache.lock);
    80003b08:	00017517          	auipc	a0,0x17
    80003b0c:	12050513          	add	a0,a0,288 # 8001ac28 <bcache>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	0c2080e7          	jalr	194(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003b18:	40bc                	lw	a5,64(s1)
    80003b1a:	37fd                	addw	a5,a5,-1
    80003b1c:	0007871b          	sext.w	a4,a5
    80003b20:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003b22:	e71d                	bnez	a4,80003b50 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003b24:	68b8                	ld	a4,80(s1)
    80003b26:	64bc                	ld	a5,72(s1)
    80003b28:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003b2a:	68b8                	ld	a4,80(s1)
    80003b2c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003b2e:	0001f797          	auipc	a5,0x1f
    80003b32:	0fa78793          	add	a5,a5,250 # 80022c28 <bcache+0x8000>
    80003b36:	2b87b703          	ld	a4,696(a5)
    80003b3a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003b3c:	0001f717          	auipc	a4,0x1f
    80003b40:	35470713          	add	a4,a4,852 # 80022e90 <bcache+0x8268>
    80003b44:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003b46:	2b87b703          	ld	a4,696(a5)
    80003b4a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003b4c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003b50:	00017517          	auipc	a0,0x17
    80003b54:	0d850513          	add	a0,a0,216 # 8001ac28 <bcache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	12e080e7          	jalr	302(ra) # 80000c86 <release>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6902                	ld	s2,0(sp)
    80003b68:	6105                	add	sp,sp,32
    80003b6a:	8082                	ret
    panic("brelse");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	a5c50513          	add	a0,a0,-1444 # 800085c8 <syscalls+0x128>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9c8080e7          	jalr	-1592(ra) # 8000053c <panic>

0000000080003b7c <bpin>:

void
bpin(struct buf *b) {
    80003b7c:	1101                	add	sp,sp,-32
    80003b7e:	ec06                	sd	ra,24(sp)
    80003b80:	e822                	sd	s0,16(sp)
    80003b82:	e426                	sd	s1,8(sp)
    80003b84:	1000                	add	s0,sp,32
    80003b86:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b88:	00017517          	auipc	a0,0x17
    80003b8c:	0a050513          	add	a0,a0,160 # 8001ac28 <bcache>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	042080e7          	jalr	66(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003b98:	40bc                	lw	a5,64(s1)
    80003b9a:	2785                	addw	a5,a5,1
    80003b9c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b9e:	00017517          	auipc	a0,0x17
    80003ba2:	08a50513          	add	a0,a0,138 # 8001ac28 <bcache>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	0e0080e7          	jalr	224(ra) # 80000c86 <release>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6105                	add	sp,sp,32
    80003bb6:	8082                	ret

0000000080003bb8 <bunpin>:

void
bunpin(struct buf *b) {
    80003bb8:	1101                	add	sp,sp,-32
    80003bba:	ec06                	sd	ra,24(sp)
    80003bbc:	e822                	sd	s0,16(sp)
    80003bbe:	e426                	sd	s1,8(sp)
    80003bc0:	1000                	add	s0,sp,32
    80003bc2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003bc4:	00017517          	auipc	a0,0x17
    80003bc8:	06450513          	add	a0,a0,100 # 8001ac28 <bcache>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	006080e7          	jalr	6(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003bd4:	40bc                	lw	a5,64(s1)
    80003bd6:	37fd                	addw	a5,a5,-1
    80003bd8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003bda:	00017517          	auipc	a0,0x17
    80003bde:	04e50513          	add	a0,a0,78 # 8001ac28 <bcache>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	0a4080e7          	jalr	164(ra) # 80000c86 <release>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6105                	add	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003bf4:	1101                	add	sp,sp,-32
    80003bf6:	ec06                	sd	ra,24(sp)
    80003bf8:	e822                	sd	s0,16(sp)
    80003bfa:	e426                	sd	s1,8(sp)
    80003bfc:	e04a                	sd	s2,0(sp)
    80003bfe:	1000                	add	s0,sp,32
    80003c00:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003c02:	00d5d59b          	srlw	a1,a1,0xd
    80003c06:	0001f797          	auipc	a5,0x1f
    80003c0a:	6fe7a783          	lw	a5,1790(a5) # 80023304 <sb+0x1c>
    80003c0e:	9dbd                	addw	a1,a1,a5
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	da0080e7          	jalr	-608(ra) # 800039b0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003c18:	0074f713          	and	a4,s1,7
    80003c1c:	4785                	li	a5,1
    80003c1e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003c22:	14ce                	sll	s1,s1,0x33
    80003c24:	90d9                	srl	s1,s1,0x36
    80003c26:	00950733          	add	a4,a0,s1
    80003c2a:	05874703          	lbu	a4,88(a4)
    80003c2e:	00e7f6b3          	and	a3,a5,a4
    80003c32:	c69d                	beqz	a3,80003c60 <bfree+0x6c>
    80003c34:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003c36:	94aa                	add	s1,s1,a0
    80003c38:	fff7c793          	not	a5,a5
    80003c3c:	8f7d                	and	a4,a4,a5
    80003c3e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	0f6080e7          	jalr	246(ra) # 80004d38 <log_write>
  brelse(bp);
    80003c4a:	854a                	mv	a0,s2
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	e94080e7          	jalr	-364(ra) # 80003ae0 <brelse>
}
    80003c54:	60e2                	ld	ra,24(sp)
    80003c56:	6442                	ld	s0,16(sp)
    80003c58:	64a2                	ld	s1,8(sp)
    80003c5a:	6902                	ld	s2,0(sp)
    80003c5c:	6105                	add	sp,sp,32
    80003c5e:	8082                	ret
    panic("freeing free block");
    80003c60:	00005517          	auipc	a0,0x5
    80003c64:	97050513          	add	a0,a0,-1680 # 800085d0 <syscalls+0x130>
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	8d4080e7          	jalr	-1836(ra) # 8000053c <panic>

0000000080003c70 <balloc>:
{
    80003c70:	711d                	add	sp,sp,-96
    80003c72:	ec86                	sd	ra,88(sp)
    80003c74:	e8a2                	sd	s0,80(sp)
    80003c76:	e4a6                	sd	s1,72(sp)
    80003c78:	e0ca                	sd	s2,64(sp)
    80003c7a:	fc4e                	sd	s3,56(sp)
    80003c7c:	f852                	sd	s4,48(sp)
    80003c7e:	f456                	sd	s5,40(sp)
    80003c80:	f05a                	sd	s6,32(sp)
    80003c82:	ec5e                	sd	s7,24(sp)
    80003c84:	e862                	sd	s8,16(sp)
    80003c86:	e466                	sd	s9,8(sp)
    80003c88:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c8a:	0001f797          	auipc	a5,0x1f
    80003c8e:	6627a783          	lw	a5,1634(a5) # 800232ec <sb+0x4>
    80003c92:	cff5                	beqz	a5,80003d8e <balloc+0x11e>
    80003c94:	8baa                	mv	s7,a0
    80003c96:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c98:	0001fb17          	auipc	s6,0x1f
    80003c9c:	650b0b13          	add	s6,s6,1616 # 800232e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ca0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ca2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ca4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003ca6:	6c89                	lui	s9,0x2
    80003ca8:	a061                	j	80003d30 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003caa:	97ca                	add	a5,a5,s2
    80003cac:	8e55                	or	a2,a2,a3
    80003cae:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00001097          	auipc	ra,0x1
    80003cb8:	084080e7          	jalr	132(ra) # 80004d38 <log_write>
        brelse(bp);
    80003cbc:	854a                	mv	a0,s2
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	e22080e7          	jalr	-478(ra) # 80003ae0 <brelse>
  bp = bread(dev, bno);
    80003cc6:	85a6                	mv	a1,s1
    80003cc8:	855e                	mv	a0,s7
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	ce6080e7          	jalr	-794(ra) # 800039b0 <bread>
    80003cd2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003cd4:	40000613          	li	a2,1024
    80003cd8:	4581                	li	a1,0
    80003cda:	05850513          	add	a0,a0,88
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	ff0080e7          	jalr	-16(ra) # 80000cce <memset>
  log_write(bp);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	050080e7          	jalr	80(ra) # 80004d38 <log_write>
  brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	dee080e7          	jalr	-530(ra) # 80003ae0 <brelse>
}
    80003cfa:	8526                	mv	a0,s1
    80003cfc:	60e6                	ld	ra,88(sp)
    80003cfe:	6446                	ld	s0,80(sp)
    80003d00:	64a6                	ld	s1,72(sp)
    80003d02:	6906                	ld	s2,64(sp)
    80003d04:	79e2                	ld	s3,56(sp)
    80003d06:	7a42                	ld	s4,48(sp)
    80003d08:	7aa2                	ld	s5,40(sp)
    80003d0a:	7b02                	ld	s6,32(sp)
    80003d0c:	6be2                	ld	s7,24(sp)
    80003d0e:	6c42                	ld	s8,16(sp)
    80003d10:	6ca2                	ld	s9,8(sp)
    80003d12:	6125                	add	sp,sp,96
    80003d14:	8082                	ret
    brelse(bp);
    80003d16:	854a                	mv	a0,s2
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	dc8080e7          	jalr	-568(ra) # 80003ae0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003d20:	015c87bb          	addw	a5,s9,s5
    80003d24:	00078a9b          	sext.w	s5,a5
    80003d28:	004b2703          	lw	a4,4(s6)
    80003d2c:	06eaf163          	bgeu	s5,a4,80003d8e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003d30:	41fad79b          	sraw	a5,s5,0x1f
    80003d34:	0137d79b          	srlw	a5,a5,0x13
    80003d38:	015787bb          	addw	a5,a5,s5
    80003d3c:	40d7d79b          	sraw	a5,a5,0xd
    80003d40:	01cb2583          	lw	a1,28(s6)
    80003d44:	9dbd                	addw	a1,a1,a5
    80003d46:	855e                	mv	a0,s7
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	c68080e7          	jalr	-920(ra) # 800039b0 <bread>
    80003d50:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d52:	004b2503          	lw	a0,4(s6)
    80003d56:	000a849b          	sext.w	s1,s5
    80003d5a:	8762                	mv	a4,s8
    80003d5c:	faa4fde3          	bgeu	s1,a0,80003d16 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003d60:	00777693          	and	a3,a4,7
    80003d64:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d68:	41f7579b          	sraw	a5,a4,0x1f
    80003d6c:	01d7d79b          	srlw	a5,a5,0x1d
    80003d70:	9fb9                	addw	a5,a5,a4
    80003d72:	4037d79b          	sraw	a5,a5,0x3
    80003d76:	00f90633          	add	a2,s2,a5
    80003d7a:	05864603          	lbu	a2,88(a2)
    80003d7e:	00c6f5b3          	and	a1,a3,a2
    80003d82:	d585                	beqz	a1,80003caa <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d84:	2705                	addw	a4,a4,1
    80003d86:	2485                	addw	s1,s1,1
    80003d88:	fd471ae3          	bne	a4,s4,80003d5c <balloc+0xec>
    80003d8c:	b769                	j	80003d16 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003d8e:	00005517          	auipc	a0,0x5
    80003d92:	85a50513          	add	a0,a0,-1958 # 800085e8 <syscalls+0x148>
    80003d96:	ffffc097          	auipc	ra,0xffffc
    80003d9a:	7f0080e7          	jalr	2032(ra) # 80000586 <printf>
  return 0;
    80003d9e:	4481                	li	s1,0
    80003da0:	bfa9                	j	80003cfa <balloc+0x8a>

0000000080003da2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003da2:	7179                	add	sp,sp,-48
    80003da4:	f406                	sd	ra,40(sp)
    80003da6:	f022                	sd	s0,32(sp)
    80003da8:	ec26                	sd	s1,24(sp)
    80003daa:	e84a                	sd	s2,16(sp)
    80003dac:	e44e                	sd	s3,8(sp)
    80003dae:	e052                	sd	s4,0(sp)
    80003db0:	1800                	add	s0,sp,48
    80003db2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003db4:	47ad                	li	a5,11
    80003db6:	02b7e863          	bltu	a5,a1,80003de6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003dba:	02059793          	sll	a5,a1,0x20
    80003dbe:	01e7d593          	srl	a1,a5,0x1e
    80003dc2:	00b504b3          	add	s1,a0,a1
    80003dc6:	0504a903          	lw	s2,80(s1)
    80003dca:	06091e63          	bnez	s2,80003e46 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003dce:	4108                	lw	a0,0(a0)
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	ea0080e7          	jalr	-352(ra) # 80003c70 <balloc>
    80003dd8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ddc:	06090563          	beqz	s2,80003e46 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003de0:	0524a823          	sw	s2,80(s1)
    80003de4:	a08d                	j	80003e46 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003de6:	ff45849b          	addw	s1,a1,-12
    80003dea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003dee:	0ff00793          	li	a5,255
    80003df2:	08e7e563          	bltu	a5,a4,80003e7c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003df6:	08052903          	lw	s2,128(a0)
    80003dfa:	00091d63          	bnez	s2,80003e14 <bmap+0x72>
      addr = balloc(ip->dev);
    80003dfe:	4108                	lw	a0,0(a0)
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	e70080e7          	jalr	-400(ra) # 80003c70 <balloc>
    80003e08:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003e0c:	02090d63          	beqz	s2,80003e46 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003e10:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003e14:	85ca                	mv	a1,s2
    80003e16:	0009a503          	lw	a0,0(s3)
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	b96080e7          	jalr	-1130(ra) # 800039b0 <bread>
    80003e22:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003e24:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003e28:	02049713          	sll	a4,s1,0x20
    80003e2c:	01e75593          	srl	a1,a4,0x1e
    80003e30:	00b784b3          	add	s1,a5,a1
    80003e34:	0004a903          	lw	s2,0(s1)
    80003e38:	02090063          	beqz	s2,80003e58 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003e3c:	8552                	mv	a0,s4
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	ca2080e7          	jalr	-862(ra) # 80003ae0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003e46:	854a                	mv	a0,s2
    80003e48:	70a2                	ld	ra,40(sp)
    80003e4a:	7402                	ld	s0,32(sp)
    80003e4c:	64e2                	ld	s1,24(sp)
    80003e4e:	6942                	ld	s2,16(sp)
    80003e50:	69a2                	ld	s3,8(sp)
    80003e52:	6a02                	ld	s4,0(sp)
    80003e54:	6145                	add	sp,sp,48
    80003e56:	8082                	ret
      addr = balloc(ip->dev);
    80003e58:	0009a503          	lw	a0,0(s3)
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	e14080e7          	jalr	-492(ra) # 80003c70 <balloc>
    80003e64:	0005091b          	sext.w	s2,a0
      if(addr){
    80003e68:	fc090ae3          	beqz	s2,80003e3c <bmap+0x9a>
        a[bn] = addr;
    80003e6c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003e70:	8552                	mv	a0,s4
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	ec6080e7          	jalr	-314(ra) # 80004d38 <log_write>
    80003e7a:	b7c9                	j	80003e3c <bmap+0x9a>
  panic("bmap: out of range");
    80003e7c:	00004517          	auipc	a0,0x4
    80003e80:	78450513          	add	a0,a0,1924 # 80008600 <syscalls+0x160>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6b8080e7          	jalr	1720(ra) # 8000053c <panic>

0000000080003e8c <iget>:
{
    80003e8c:	7179                	add	sp,sp,-48
    80003e8e:	f406                	sd	ra,40(sp)
    80003e90:	f022                	sd	s0,32(sp)
    80003e92:	ec26                	sd	s1,24(sp)
    80003e94:	e84a                	sd	s2,16(sp)
    80003e96:	e44e                	sd	s3,8(sp)
    80003e98:	e052                	sd	s4,0(sp)
    80003e9a:	1800                	add	s0,sp,48
    80003e9c:	89aa                	mv	s3,a0
    80003e9e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ea0:	0001f517          	auipc	a0,0x1f
    80003ea4:	46850513          	add	a0,a0,1128 # 80023308 <itable>
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	d2a080e7          	jalr	-726(ra) # 80000bd2 <acquire>
  empty = 0;
    80003eb0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003eb2:	0001f497          	auipc	s1,0x1f
    80003eb6:	46e48493          	add	s1,s1,1134 # 80023320 <itable+0x18>
    80003eba:	00021697          	auipc	a3,0x21
    80003ebe:	ef668693          	add	a3,a3,-266 # 80024db0 <log>
    80003ec2:	a039                	j	80003ed0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ec4:	02090b63          	beqz	s2,80003efa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ec8:	08848493          	add	s1,s1,136
    80003ecc:	02d48a63          	beq	s1,a3,80003f00 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ed0:	449c                	lw	a5,8(s1)
    80003ed2:	fef059e3          	blez	a5,80003ec4 <iget+0x38>
    80003ed6:	4098                	lw	a4,0(s1)
    80003ed8:	ff3716e3          	bne	a4,s3,80003ec4 <iget+0x38>
    80003edc:	40d8                	lw	a4,4(s1)
    80003ede:	ff4713e3          	bne	a4,s4,80003ec4 <iget+0x38>
      ip->ref++;
    80003ee2:	2785                	addw	a5,a5,1
    80003ee4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ee6:	0001f517          	auipc	a0,0x1f
    80003eea:	42250513          	add	a0,a0,1058 # 80023308 <itable>
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	d98080e7          	jalr	-616(ra) # 80000c86 <release>
      return ip;
    80003ef6:	8926                	mv	s2,s1
    80003ef8:	a03d                	j	80003f26 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003efa:	f7f9                	bnez	a5,80003ec8 <iget+0x3c>
    80003efc:	8926                	mv	s2,s1
    80003efe:	b7e9                	j	80003ec8 <iget+0x3c>
  if(empty == 0)
    80003f00:	02090c63          	beqz	s2,80003f38 <iget+0xac>
  ip->dev = dev;
    80003f04:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003f08:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003f0c:	4785                	li	a5,1
    80003f0e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003f12:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003f16:	0001f517          	auipc	a0,0x1f
    80003f1a:	3f250513          	add	a0,a0,1010 # 80023308 <itable>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	d68080e7          	jalr	-664(ra) # 80000c86 <release>
}
    80003f26:	854a                	mv	a0,s2
    80003f28:	70a2                	ld	ra,40(sp)
    80003f2a:	7402                	ld	s0,32(sp)
    80003f2c:	64e2                	ld	s1,24(sp)
    80003f2e:	6942                	ld	s2,16(sp)
    80003f30:	69a2                	ld	s3,8(sp)
    80003f32:	6a02                	ld	s4,0(sp)
    80003f34:	6145                	add	sp,sp,48
    80003f36:	8082                	ret
    panic("iget: no inodes");
    80003f38:	00004517          	auipc	a0,0x4
    80003f3c:	6e050513          	add	a0,a0,1760 # 80008618 <syscalls+0x178>
    80003f40:	ffffc097          	auipc	ra,0xffffc
    80003f44:	5fc080e7          	jalr	1532(ra) # 8000053c <panic>

0000000080003f48 <fsinit>:
fsinit(int dev) {
    80003f48:	7179                	add	sp,sp,-48
    80003f4a:	f406                	sd	ra,40(sp)
    80003f4c:	f022                	sd	s0,32(sp)
    80003f4e:	ec26                	sd	s1,24(sp)
    80003f50:	e84a                	sd	s2,16(sp)
    80003f52:	e44e                	sd	s3,8(sp)
    80003f54:	1800                	add	s0,sp,48
    80003f56:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f58:	4585                	li	a1,1
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	a56080e7          	jalr	-1450(ra) # 800039b0 <bread>
    80003f62:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f64:	0001f997          	auipc	s3,0x1f
    80003f68:	38498993          	add	s3,s3,900 # 800232e8 <sb>
    80003f6c:	02000613          	li	a2,32
    80003f70:	05850593          	add	a1,a0,88
    80003f74:	854e                	mv	a0,s3
    80003f76:	ffffd097          	auipc	ra,0xffffd
    80003f7a:	db4080e7          	jalr	-588(ra) # 80000d2a <memmove>
  brelse(bp);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	b60080e7          	jalr	-1184(ra) # 80003ae0 <brelse>
  if(sb.magic != FSMAGIC)
    80003f88:	0009a703          	lw	a4,0(s3)
    80003f8c:	102037b7          	lui	a5,0x10203
    80003f90:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f94:	02f71263          	bne	a4,a5,80003fb8 <fsinit+0x70>
  initlog(dev, &sb);
    80003f98:	0001f597          	auipc	a1,0x1f
    80003f9c:	35058593          	add	a1,a1,848 # 800232e8 <sb>
    80003fa0:	854a                	mv	a0,s2
    80003fa2:	00001097          	auipc	ra,0x1
    80003fa6:	b2c080e7          	jalr	-1236(ra) # 80004ace <initlog>
}
    80003faa:	70a2                	ld	ra,40(sp)
    80003fac:	7402                	ld	s0,32(sp)
    80003fae:	64e2                	ld	s1,24(sp)
    80003fb0:	6942                	ld	s2,16(sp)
    80003fb2:	69a2                	ld	s3,8(sp)
    80003fb4:	6145                	add	sp,sp,48
    80003fb6:	8082                	ret
    panic("invalid file system");
    80003fb8:	00004517          	auipc	a0,0x4
    80003fbc:	67050513          	add	a0,a0,1648 # 80008628 <syscalls+0x188>
    80003fc0:	ffffc097          	auipc	ra,0xffffc
    80003fc4:	57c080e7          	jalr	1404(ra) # 8000053c <panic>

0000000080003fc8 <iinit>:
{
    80003fc8:	7179                	add	sp,sp,-48
    80003fca:	f406                	sd	ra,40(sp)
    80003fcc:	f022                	sd	s0,32(sp)
    80003fce:	ec26                	sd	s1,24(sp)
    80003fd0:	e84a                	sd	s2,16(sp)
    80003fd2:	e44e                	sd	s3,8(sp)
    80003fd4:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003fd6:	00004597          	auipc	a1,0x4
    80003fda:	66a58593          	add	a1,a1,1642 # 80008640 <syscalls+0x1a0>
    80003fde:	0001f517          	auipc	a0,0x1f
    80003fe2:	32a50513          	add	a0,a0,810 # 80023308 <itable>
    80003fe6:	ffffd097          	auipc	ra,0xffffd
    80003fea:	b5c080e7          	jalr	-1188(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003fee:	0001f497          	auipc	s1,0x1f
    80003ff2:	34248493          	add	s1,s1,834 # 80023330 <itable+0x28>
    80003ff6:	00021997          	auipc	s3,0x21
    80003ffa:	dca98993          	add	s3,s3,-566 # 80024dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ffe:	00004917          	auipc	s2,0x4
    80004002:	64a90913          	add	s2,s2,1610 # 80008648 <syscalls+0x1a8>
    80004006:	85ca                	mv	a1,s2
    80004008:	8526                	mv	a0,s1
    8000400a:	00001097          	auipc	ra,0x1
    8000400e:	e12080e7          	jalr	-494(ra) # 80004e1c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004012:	08848493          	add	s1,s1,136
    80004016:	ff3498e3          	bne	s1,s3,80004006 <iinit+0x3e>
}
    8000401a:	70a2                	ld	ra,40(sp)
    8000401c:	7402                	ld	s0,32(sp)
    8000401e:	64e2                	ld	s1,24(sp)
    80004020:	6942                	ld	s2,16(sp)
    80004022:	69a2                	ld	s3,8(sp)
    80004024:	6145                	add	sp,sp,48
    80004026:	8082                	ret

0000000080004028 <ialloc>:
{
    80004028:	7139                	add	sp,sp,-64
    8000402a:	fc06                	sd	ra,56(sp)
    8000402c:	f822                	sd	s0,48(sp)
    8000402e:	f426                	sd	s1,40(sp)
    80004030:	f04a                	sd	s2,32(sp)
    80004032:	ec4e                	sd	s3,24(sp)
    80004034:	e852                	sd	s4,16(sp)
    80004036:	e456                	sd	s5,8(sp)
    80004038:	e05a                	sd	s6,0(sp)
    8000403a:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000403c:	0001f717          	auipc	a4,0x1f
    80004040:	2b872703          	lw	a4,696(a4) # 800232f4 <sb+0xc>
    80004044:	4785                	li	a5,1
    80004046:	04e7f863          	bgeu	a5,a4,80004096 <ialloc+0x6e>
    8000404a:	8aaa                	mv	s5,a0
    8000404c:	8b2e                	mv	s6,a1
    8000404e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004050:	0001fa17          	auipc	s4,0x1f
    80004054:	298a0a13          	add	s4,s4,664 # 800232e8 <sb>
    80004058:	00495593          	srl	a1,s2,0x4
    8000405c:	018a2783          	lw	a5,24(s4)
    80004060:	9dbd                	addw	a1,a1,a5
    80004062:	8556                	mv	a0,s5
    80004064:	00000097          	auipc	ra,0x0
    80004068:	94c080e7          	jalr	-1716(ra) # 800039b0 <bread>
    8000406c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000406e:	05850993          	add	s3,a0,88
    80004072:	00f97793          	and	a5,s2,15
    80004076:	079a                	sll	a5,a5,0x6
    80004078:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000407a:	00099783          	lh	a5,0(s3)
    8000407e:	cf9d                	beqz	a5,800040bc <ialloc+0x94>
    brelse(bp);
    80004080:	00000097          	auipc	ra,0x0
    80004084:	a60080e7          	jalr	-1440(ra) # 80003ae0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004088:	0905                	add	s2,s2,1
    8000408a:	00ca2703          	lw	a4,12(s4)
    8000408e:	0009079b          	sext.w	a5,s2
    80004092:	fce7e3e3          	bltu	a5,a4,80004058 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80004096:	00004517          	auipc	a0,0x4
    8000409a:	5ba50513          	add	a0,a0,1466 # 80008650 <syscalls+0x1b0>
    8000409e:	ffffc097          	auipc	ra,0xffffc
    800040a2:	4e8080e7          	jalr	1256(ra) # 80000586 <printf>
  return 0;
    800040a6:	4501                	li	a0,0
}
    800040a8:	70e2                	ld	ra,56(sp)
    800040aa:	7442                	ld	s0,48(sp)
    800040ac:	74a2                	ld	s1,40(sp)
    800040ae:	7902                	ld	s2,32(sp)
    800040b0:	69e2                	ld	s3,24(sp)
    800040b2:	6a42                	ld	s4,16(sp)
    800040b4:	6aa2                	ld	s5,8(sp)
    800040b6:	6b02                	ld	s6,0(sp)
    800040b8:	6121                	add	sp,sp,64
    800040ba:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800040bc:	04000613          	li	a2,64
    800040c0:	4581                	li	a1,0
    800040c2:	854e                	mv	a0,s3
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	c0a080e7          	jalr	-1014(ra) # 80000cce <memset>
      dip->type = type;
    800040cc:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800040d0:	8526                	mv	a0,s1
    800040d2:	00001097          	auipc	ra,0x1
    800040d6:	c66080e7          	jalr	-922(ra) # 80004d38 <log_write>
      brelse(bp);
    800040da:	8526                	mv	a0,s1
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	a04080e7          	jalr	-1532(ra) # 80003ae0 <brelse>
      return iget(dev, inum);
    800040e4:	0009059b          	sext.w	a1,s2
    800040e8:	8556                	mv	a0,s5
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	da2080e7          	jalr	-606(ra) # 80003e8c <iget>
    800040f2:	bf5d                	j	800040a8 <ialloc+0x80>

00000000800040f4 <iupdate>:
{
    800040f4:	1101                	add	sp,sp,-32
    800040f6:	ec06                	sd	ra,24(sp)
    800040f8:	e822                	sd	s0,16(sp)
    800040fa:	e426                	sd	s1,8(sp)
    800040fc:	e04a                	sd	s2,0(sp)
    800040fe:	1000                	add	s0,sp,32
    80004100:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004102:	415c                	lw	a5,4(a0)
    80004104:	0047d79b          	srlw	a5,a5,0x4
    80004108:	0001f597          	auipc	a1,0x1f
    8000410c:	1f85a583          	lw	a1,504(a1) # 80023300 <sb+0x18>
    80004110:	9dbd                	addw	a1,a1,a5
    80004112:	4108                	lw	a0,0(a0)
    80004114:	00000097          	auipc	ra,0x0
    80004118:	89c080e7          	jalr	-1892(ra) # 800039b0 <bread>
    8000411c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000411e:	05850793          	add	a5,a0,88
    80004122:	40d8                	lw	a4,4(s1)
    80004124:	8b3d                	and	a4,a4,15
    80004126:	071a                	sll	a4,a4,0x6
    80004128:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000412a:	04449703          	lh	a4,68(s1)
    8000412e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80004132:	04649703          	lh	a4,70(s1)
    80004136:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000413a:	04849703          	lh	a4,72(s1)
    8000413e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80004142:	04a49703          	lh	a4,74(s1)
    80004146:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000414a:	44f8                	lw	a4,76(s1)
    8000414c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000414e:	03400613          	li	a2,52
    80004152:	05048593          	add	a1,s1,80
    80004156:	00c78513          	add	a0,a5,12
    8000415a:	ffffd097          	auipc	ra,0xffffd
    8000415e:	bd0080e7          	jalr	-1072(ra) # 80000d2a <memmove>
  log_write(bp);
    80004162:	854a                	mv	a0,s2
    80004164:	00001097          	auipc	ra,0x1
    80004168:	bd4080e7          	jalr	-1068(ra) # 80004d38 <log_write>
  brelse(bp);
    8000416c:	854a                	mv	a0,s2
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	972080e7          	jalr	-1678(ra) # 80003ae0 <brelse>
}
    80004176:	60e2                	ld	ra,24(sp)
    80004178:	6442                	ld	s0,16(sp)
    8000417a:	64a2                	ld	s1,8(sp)
    8000417c:	6902                	ld	s2,0(sp)
    8000417e:	6105                	add	sp,sp,32
    80004180:	8082                	ret

0000000080004182 <idup>:
{
    80004182:	1101                	add	sp,sp,-32
    80004184:	ec06                	sd	ra,24(sp)
    80004186:	e822                	sd	s0,16(sp)
    80004188:	e426                	sd	s1,8(sp)
    8000418a:	1000                	add	s0,sp,32
    8000418c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000418e:	0001f517          	auipc	a0,0x1f
    80004192:	17a50513          	add	a0,a0,378 # 80023308 <itable>
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a3c080e7          	jalr	-1476(ra) # 80000bd2 <acquire>
  ip->ref++;
    8000419e:	449c                	lw	a5,8(s1)
    800041a0:	2785                	addw	a5,a5,1
    800041a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041a4:	0001f517          	auipc	a0,0x1f
    800041a8:	16450513          	add	a0,a0,356 # 80023308 <itable>
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	ada080e7          	jalr	-1318(ra) # 80000c86 <release>
}
    800041b4:	8526                	mv	a0,s1
    800041b6:	60e2                	ld	ra,24(sp)
    800041b8:	6442                	ld	s0,16(sp)
    800041ba:	64a2                	ld	s1,8(sp)
    800041bc:	6105                	add	sp,sp,32
    800041be:	8082                	ret

00000000800041c0 <ilock>:
{
    800041c0:	1101                	add	sp,sp,-32
    800041c2:	ec06                	sd	ra,24(sp)
    800041c4:	e822                	sd	s0,16(sp)
    800041c6:	e426                	sd	s1,8(sp)
    800041c8:	e04a                	sd	s2,0(sp)
    800041ca:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800041cc:	c115                	beqz	a0,800041f0 <ilock+0x30>
    800041ce:	84aa                	mv	s1,a0
    800041d0:	451c                	lw	a5,8(a0)
    800041d2:	00f05f63          	blez	a5,800041f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800041d6:	0541                	add	a0,a0,16
    800041d8:	00001097          	auipc	ra,0x1
    800041dc:	c7e080e7          	jalr	-898(ra) # 80004e56 <acquiresleep>
  if(ip->valid == 0){
    800041e0:	40bc                	lw	a5,64(s1)
    800041e2:	cf99                	beqz	a5,80004200 <ilock+0x40>
}
    800041e4:	60e2                	ld	ra,24(sp)
    800041e6:	6442                	ld	s0,16(sp)
    800041e8:	64a2                	ld	s1,8(sp)
    800041ea:	6902                	ld	s2,0(sp)
    800041ec:	6105                	add	sp,sp,32
    800041ee:	8082                	ret
    panic("ilock");
    800041f0:	00004517          	auipc	a0,0x4
    800041f4:	47850513          	add	a0,a0,1144 # 80008668 <syscalls+0x1c8>
    800041f8:	ffffc097          	auipc	ra,0xffffc
    800041fc:	344080e7          	jalr	836(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004200:	40dc                	lw	a5,4(s1)
    80004202:	0047d79b          	srlw	a5,a5,0x4
    80004206:	0001f597          	auipc	a1,0x1f
    8000420a:	0fa5a583          	lw	a1,250(a1) # 80023300 <sb+0x18>
    8000420e:	9dbd                	addw	a1,a1,a5
    80004210:	4088                	lw	a0,0(s1)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	79e080e7          	jalr	1950(ra) # 800039b0 <bread>
    8000421a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000421c:	05850593          	add	a1,a0,88
    80004220:	40dc                	lw	a5,4(s1)
    80004222:	8bbd                	and	a5,a5,15
    80004224:	079a                	sll	a5,a5,0x6
    80004226:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004228:	00059783          	lh	a5,0(a1)
    8000422c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004230:	00259783          	lh	a5,2(a1)
    80004234:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004238:	00459783          	lh	a5,4(a1)
    8000423c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004240:	00659783          	lh	a5,6(a1)
    80004244:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004248:	459c                	lw	a5,8(a1)
    8000424a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000424c:	03400613          	li	a2,52
    80004250:	05b1                	add	a1,a1,12
    80004252:	05048513          	add	a0,s1,80
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	ad4080e7          	jalr	-1324(ra) # 80000d2a <memmove>
    brelse(bp);
    8000425e:	854a                	mv	a0,s2
    80004260:	00000097          	auipc	ra,0x0
    80004264:	880080e7          	jalr	-1920(ra) # 80003ae0 <brelse>
    ip->valid = 1;
    80004268:	4785                	li	a5,1
    8000426a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000426c:	04449783          	lh	a5,68(s1)
    80004270:	fbb5                	bnez	a5,800041e4 <ilock+0x24>
      panic("ilock: no type");
    80004272:	00004517          	auipc	a0,0x4
    80004276:	3fe50513          	add	a0,a0,1022 # 80008670 <syscalls+0x1d0>
    8000427a:	ffffc097          	auipc	ra,0xffffc
    8000427e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>

0000000080004282 <iunlock>:
{
    80004282:	1101                	add	sp,sp,-32
    80004284:	ec06                	sd	ra,24(sp)
    80004286:	e822                	sd	s0,16(sp)
    80004288:	e426                	sd	s1,8(sp)
    8000428a:	e04a                	sd	s2,0(sp)
    8000428c:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000428e:	c905                	beqz	a0,800042be <iunlock+0x3c>
    80004290:	84aa                	mv	s1,a0
    80004292:	01050913          	add	s2,a0,16
    80004296:	854a                	mv	a0,s2
    80004298:	00001097          	auipc	ra,0x1
    8000429c:	c58080e7          	jalr	-936(ra) # 80004ef0 <holdingsleep>
    800042a0:	cd19                	beqz	a0,800042be <iunlock+0x3c>
    800042a2:	449c                	lw	a5,8(s1)
    800042a4:	00f05d63          	blez	a5,800042be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800042a8:	854a                	mv	a0,s2
    800042aa:	00001097          	auipc	ra,0x1
    800042ae:	c02080e7          	jalr	-1022(ra) # 80004eac <releasesleep>
}
    800042b2:	60e2                	ld	ra,24(sp)
    800042b4:	6442                	ld	s0,16(sp)
    800042b6:	64a2                	ld	s1,8(sp)
    800042b8:	6902                	ld	s2,0(sp)
    800042ba:	6105                	add	sp,sp,32
    800042bc:	8082                	ret
    panic("iunlock");
    800042be:	00004517          	auipc	a0,0x4
    800042c2:	3c250513          	add	a0,a0,962 # 80008680 <syscalls+0x1e0>
    800042c6:	ffffc097          	auipc	ra,0xffffc
    800042ca:	276080e7          	jalr	630(ra) # 8000053c <panic>

00000000800042ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800042ce:	7179                	add	sp,sp,-48
    800042d0:	f406                	sd	ra,40(sp)
    800042d2:	f022                	sd	s0,32(sp)
    800042d4:	ec26                	sd	s1,24(sp)
    800042d6:	e84a                	sd	s2,16(sp)
    800042d8:	e44e                	sd	s3,8(sp)
    800042da:	e052                	sd	s4,0(sp)
    800042dc:	1800                	add	s0,sp,48
    800042de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800042e0:	05050493          	add	s1,a0,80
    800042e4:	08050913          	add	s2,a0,128
    800042e8:	a021                	j	800042f0 <itrunc+0x22>
    800042ea:	0491                	add	s1,s1,4
    800042ec:	01248d63          	beq	s1,s2,80004306 <itrunc+0x38>
    if(ip->addrs[i]){
    800042f0:	408c                	lw	a1,0(s1)
    800042f2:	dde5                	beqz	a1,800042ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800042f4:	0009a503          	lw	a0,0(s3)
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	8fc080e7          	jalr	-1796(ra) # 80003bf4 <bfree>
      ip->addrs[i] = 0;
    80004300:	0004a023          	sw	zero,0(s1)
    80004304:	b7dd                	j	800042ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004306:	0809a583          	lw	a1,128(s3)
    8000430a:	e185                	bnez	a1,8000432a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000430c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004310:	854e                	mv	a0,s3
    80004312:	00000097          	auipc	ra,0x0
    80004316:	de2080e7          	jalr	-542(ra) # 800040f4 <iupdate>
}
    8000431a:	70a2                	ld	ra,40(sp)
    8000431c:	7402                	ld	s0,32(sp)
    8000431e:	64e2                	ld	s1,24(sp)
    80004320:	6942                	ld	s2,16(sp)
    80004322:	69a2                	ld	s3,8(sp)
    80004324:	6a02                	ld	s4,0(sp)
    80004326:	6145                	add	sp,sp,48
    80004328:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000432a:	0009a503          	lw	a0,0(s3)
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	682080e7          	jalr	1666(ra) # 800039b0 <bread>
    80004336:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004338:	05850493          	add	s1,a0,88
    8000433c:	45850913          	add	s2,a0,1112
    80004340:	a021                	j	80004348 <itrunc+0x7a>
    80004342:	0491                	add	s1,s1,4
    80004344:	01248b63          	beq	s1,s2,8000435a <itrunc+0x8c>
      if(a[j])
    80004348:	408c                	lw	a1,0(s1)
    8000434a:	dde5                	beqz	a1,80004342 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000434c:	0009a503          	lw	a0,0(s3)
    80004350:	00000097          	auipc	ra,0x0
    80004354:	8a4080e7          	jalr	-1884(ra) # 80003bf4 <bfree>
    80004358:	b7ed                	j	80004342 <itrunc+0x74>
    brelse(bp);
    8000435a:	8552                	mv	a0,s4
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	784080e7          	jalr	1924(ra) # 80003ae0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004364:	0809a583          	lw	a1,128(s3)
    80004368:	0009a503          	lw	a0,0(s3)
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	888080e7          	jalr	-1912(ra) # 80003bf4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004374:	0809a023          	sw	zero,128(s3)
    80004378:	bf51                	j	8000430c <itrunc+0x3e>

000000008000437a <iput>:
{
    8000437a:	1101                	add	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	e426                	sd	s1,8(sp)
    80004382:	e04a                	sd	s2,0(sp)
    80004384:	1000                	add	s0,sp,32
    80004386:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004388:	0001f517          	auipc	a0,0x1f
    8000438c:	f8050513          	add	a0,a0,-128 # 80023308 <itable>
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	842080e7          	jalr	-1982(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004398:	4498                	lw	a4,8(s1)
    8000439a:	4785                	li	a5,1
    8000439c:	02f70363          	beq	a4,a5,800043c2 <iput+0x48>
  ip->ref--;
    800043a0:	449c                	lw	a5,8(s1)
    800043a2:	37fd                	addw	a5,a5,-1
    800043a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800043a6:	0001f517          	auipc	a0,0x1f
    800043aa:	f6250513          	add	a0,a0,-158 # 80023308 <itable>
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	8d8080e7          	jalr	-1832(ra) # 80000c86 <release>
}
    800043b6:	60e2                	ld	ra,24(sp)
    800043b8:	6442                	ld	s0,16(sp)
    800043ba:	64a2                	ld	s1,8(sp)
    800043bc:	6902                	ld	s2,0(sp)
    800043be:	6105                	add	sp,sp,32
    800043c0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800043c2:	40bc                	lw	a5,64(s1)
    800043c4:	dff1                	beqz	a5,800043a0 <iput+0x26>
    800043c6:	04a49783          	lh	a5,74(s1)
    800043ca:	fbf9                	bnez	a5,800043a0 <iput+0x26>
    acquiresleep(&ip->lock);
    800043cc:	01048913          	add	s2,s1,16
    800043d0:	854a                	mv	a0,s2
    800043d2:	00001097          	auipc	ra,0x1
    800043d6:	a84080e7          	jalr	-1404(ra) # 80004e56 <acquiresleep>
    release(&itable.lock);
    800043da:	0001f517          	auipc	a0,0x1f
    800043de:	f2e50513          	add	a0,a0,-210 # 80023308 <itable>
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8a4080e7          	jalr	-1884(ra) # 80000c86 <release>
    itrunc(ip);
    800043ea:	8526                	mv	a0,s1
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	ee2080e7          	jalr	-286(ra) # 800042ce <itrunc>
    ip->type = 0;
    800043f4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800043f8:	8526                	mv	a0,s1
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	cfa080e7          	jalr	-774(ra) # 800040f4 <iupdate>
    ip->valid = 0;
    80004402:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004406:	854a                	mv	a0,s2
    80004408:	00001097          	auipc	ra,0x1
    8000440c:	aa4080e7          	jalr	-1372(ra) # 80004eac <releasesleep>
    acquire(&itable.lock);
    80004410:	0001f517          	auipc	a0,0x1f
    80004414:	ef850513          	add	a0,a0,-264 # 80023308 <itable>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7ba080e7          	jalr	1978(ra) # 80000bd2 <acquire>
    80004420:	b741                	j	800043a0 <iput+0x26>

0000000080004422 <iunlockput>:
{
    80004422:	1101                	add	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	1000                	add	s0,sp,32
    8000442c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	e54080e7          	jalr	-428(ra) # 80004282 <iunlock>
  iput(ip);
    80004436:	8526                	mv	a0,s1
    80004438:	00000097          	auipc	ra,0x0
    8000443c:	f42080e7          	jalr	-190(ra) # 8000437a <iput>
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6105                	add	sp,sp,32
    80004448:	8082                	ret

000000008000444a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000444a:	1141                	add	sp,sp,-16
    8000444c:	e422                	sd	s0,8(sp)
    8000444e:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80004450:	411c                	lw	a5,0(a0)
    80004452:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004454:	415c                	lw	a5,4(a0)
    80004456:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004458:	04451783          	lh	a5,68(a0)
    8000445c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004460:	04a51783          	lh	a5,74(a0)
    80004464:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004468:	04c56783          	lwu	a5,76(a0)
    8000446c:	e99c                	sd	a5,16(a1)
}
    8000446e:	6422                	ld	s0,8(sp)
    80004470:	0141                	add	sp,sp,16
    80004472:	8082                	ret

0000000080004474 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004474:	457c                	lw	a5,76(a0)
    80004476:	0ed7e963          	bltu	a5,a3,80004568 <readi+0xf4>
{
    8000447a:	7159                	add	sp,sp,-112
    8000447c:	f486                	sd	ra,104(sp)
    8000447e:	f0a2                	sd	s0,96(sp)
    80004480:	eca6                	sd	s1,88(sp)
    80004482:	e8ca                	sd	s2,80(sp)
    80004484:	e4ce                	sd	s3,72(sp)
    80004486:	e0d2                	sd	s4,64(sp)
    80004488:	fc56                	sd	s5,56(sp)
    8000448a:	f85a                	sd	s6,48(sp)
    8000448c:	f45e                	sd	s7,40(sp)
    8000448e:	f062                	sd	s8,32(sp)
    80004490:	ec66                	sd	s9,24(sp)
    80004492:	e86a                	sd	s10,16(sp)
    80004494:	e46e                	sd	s11,8(sp)
    80004496:	1880                	add	s0,sp,112
    80004498:	8b2a                	mv	s6,a0
    8000449a:	8bae                	mv	s7,a1
    8000449c:	8a32                	mv	s4,a2
    8000449e:	84b6                	mv	s1,a3
    800044a0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800044a2:	9f35                	addw	a4,a4,a3
    return 0;
    800044a4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800044a6:	0ad76063          	bltu	a4,a3,80004546 <readi+0xd2>
  if(off + n > ip->size)
    800044aa:	00e7f463          	bgeu	a5,a4,800044b2 <readi+0x3e>
    n = ip->size - off;
    800044ae:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044b2:	0a0a8963          	beqz	s5,80004564 <readi+0xf0>
    800044b6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800044b8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800044bc:	5c7d                	li	s8,-1
    800044be:	a82d                	j	800044f8 <readi+0x84>
    800044c0:	020d1d93          	sll	s11,s10,0x20
    800044c4:	020ddd93          	srl	s11,s11,0x20
    800044c8:	05890613          	add	a2,s2,88
    800044cc:	86ee                	mv	a3,s11
    800044ce:	963a                	add	a2,a2,a4
    800044d0:	85d2                	mv	a1,s4
    800044d2:	855e                	mv	a0,s7
    800044d4:	ffffe097          	auipc	ra,0xffffe
    800044d8:	728080e7          	jalr	1832(ra) # 80002bfc <either_copyout>
    800044dc:	05850d63          	beq	a0,s8,80004536 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800044e0:	854a                	mv	a0,s2
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	5fe080e7          	jalr	1534(ra) # 80003ae0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044ea:	013d09bb          	addw	s3,s10,s3
    800044ee:	009d04bb          	addw	s1,s10,s1
    800044f2:	9a6e                	add	s4,s4,s11
    800044f4:	0559f763          	bgeu	s3,s5,80004542 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800044f8:	00a4d59b          	srlw	a1,s1,0xa
    800044fc:	855a                	mv	a0,s6
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	8a4080e7          	jalr	-1884(ra) # 80003da2 <bmap>
    80004506:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000450a:	cd85                	beqz	a1,80004542 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000450c:	000b2503          	lw	a0,0(s6)
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	4a0080e7          	jalr	1184(ra) # 800039b0 <bread>
    80004518:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000451a:	3ff4f713          	and	a4,s1,1023
    8000451e:	40ec87bb          	subw	a5,s9,a4
    80004522:	413a86bb          	subw	a3,s5,s3
    80004526:	8d3e                	mv	s10,a5
    80004528:	2781                	sext.w	a5,a5
    8000452a:	0006861b          	sext.w	a2,a3
    8000452e:	f8f679e3          	bgeu	a2,a5,800044c0 <readi+0x4c>
    80004532:	8d36                	mv	s10,a3
    80004534:	b771                	j	800044c0 <readi+0x4c>
      brelse(bp);
    80004536:	854a                	mv	a0,s2
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	5a8080e7          	jalr	1448(ra) # 80003ae0 <brelse>
      tot = -1;
    80004540:	59fd                	li	s3,-1
  }
  return tot;
    80004542:	0009851b          	sext.w	a0,s3
}
    80004546:	70a6                	ld	ra,104(sp)
    80004548:	7406                	ld	s0,96(sp)
    8000454a:	64e6                	ld	s1,88(sp)
    8000454c:	6946                	ld	s2,80(sp)
    8000454e:	69a6                	ld	s3,72(sp)
    80004550:	6a06                	ld	s4,64(sp)
    80004552:	7ae2                	ld	s5,56(sp)
    80004554:	7b42                	ld	s6,48(sp)
    80004556:	7ba2                	ld	s7,40(sp)
    80004558:	7c02                	ld	s8,32(sp)
    8000455a:	6ce2                	ld	s9,24(sp)
    8000455c:	6d42                	ld	s10,16(sp)
    8000455e:	6da2                	ld	s11,8(sp)
    80004560:	6165                	add	sp,sp,112
    80004562:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004564:	89d6                	mv	s3,s5
    80004566:	bff1                	j	80004542 <readi+0xce>
    return 0;
    80004568:	4501                	li	a0,0
}
    8000456a:	8082                	ret

000000008000456c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000456c:	457c                	lw	a5,76(a0)
    8000456e:	10d7e863          	bltu	a5,a3,8000467e <writei+0x112>
{
    80004572:	7159                	add	sp,sp,-112
    80004574:	f486                	sd	ra,104(sp)
    80004576:	f0a2                	sd	s0,96(sp)
    80004578:	eca6                	sd	s1,88(sp)
    8000457a:	e8ca                	sd	s2,80(sp)
    8000457c:	e4ce                	sd	s3,72(sp)
    8000457e:	e0d2                	sd	s4,64(sp)
    80004580:	fc56                	sd	s5,56(sp)
    80004582:	f85a                	sd	s6,48(sp)
    80004584:	f45e                	sd	s7,40(sp)
    80004586:	f062                	sd	s8,32(sp)
    80004588:	ec66                	sd	s9,24(sp)
    8000458a:	e86a                	sd	s10,16(sp)
    8000458c:	e46e                	sd	s11,8(sp)
    8000458e:	1880                	add	s0,sp,112
    80004590:	8aaa                	mv	s5,a0
    80004592:	8bae                	mv	s7,a1
    80004594:	8a32                	mv	s4,a2
    80004596:	8936                	mv	s2,a3
    80004598:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000459a:	00e687bb          	addw	a5,a3,a4
    8000459e:	0ed7e263          	bltu	a5,a3,80004682 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800045a2:	00043737          	lui	a4,0x43
    800045a6:	0ef76063          	bltu	a4,a5,80004686 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045aa:	0c0b0863          	beqz	s6,8000467a <writei+0x10e>
    800045ae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800045b0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800045b4:	5c7d                	li	s8,-1
    800045b6:	a091                	j	800045fa <writei+0x8e>
    800045b8:	020d1d93          	sll	s11,s10,0x20
    800045bc:	020ddd93          	srl	s11,s11,0x20
    800045c0:	05848513          	add	a0,s1,88
    800045c4:	86ee                	mv	a3,s11
    800045c6:	8652                	mv	a2,s4
    800045c8:	85de                	mv	a1,s7
    800045ca:	953a                	add	a0,a0,a4
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	686080e7          	jalr	1670(ra) # 80002c52 <either_copyin>
    800045d4:	07850263          	beq	a0,s8,80004638 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800045d8:	8526                	mv	a0,s1
    800045da:	00000097          	auipc	ra,0x0
    800045de:	75e080e7          	jalr	1886(ra) # 80004d38 <log_write>
    brelse(bp);
    800045e2:	8526                	mv	a0,s1
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	4fc080e7          	jalr	1276(ra) # 80003ae0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045ec:	013d09bb          	addw	s3,s10,s3
    800045f0:	012d093b          	addw	s2,s10,s2
    800045f4:	9a6e                	add	s4,s4,s11
    800045f6:	0569f663          	bgeu	s3,s6,80004642 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800045fa:	00a9559b          	srlw	a1,s2,0xa
    800045fe:	8556                	mv	a0,s5
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	7a2080e7          	jalr	1954(ra) # 80003da2 <bmap>
    80004608:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000460c:	c99d                	beqz	a1,80004642 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000460e:	000aa503          	lw	a0,0(s5)
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	39e080e7          	jalr	926(ra) # 800039b0 <bread>
    8000461a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000461c:	3ff97713          	and	a4,s2,1023
    80004620:	40ec87bb          	subw	a5,s9,a4
    80004624:	413b06bb          	subw	a3,s6,s3
    80004628:	8d3e                	mv	s10,a5
    8000462a:	2781                	sext.w	a5,a5
    8000462c:	0006861b          	sext.w	a2,a3
    80004630:	f8f674e3          	bgeu	a2,a5,800045b8 <writei+0x4c>
    80004634:	8d36                	mv	s10,a3
    80004636:	b749                	j	800045b8 <writei+0x4c>
      brelse(bp);
    80004638:	8526                	mv	a0,s1
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	4a6080e7          	jalr	1190(ra) # 80003ae0 <brelse>
  }

  if(off > ip->size)
    80004642:	04caa783          	lw	a5,76(s5)
    80004646:	0127f463          	bgeu	a5,s2,8000464e <writei+0xe2>
    ip->size = off;
    8000464a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000464e:	8556                	mv	a0,s5
    80004650:	00000097          	auipc	ra,0x0
    80004654:	aa4080e7          	jalr	-1372(ra) # 800040f4 <iupdate>

  return tot;
    80004658:	0009851b          	sext.w	a0,s3
}
    8000465c:	70a6                	ld	ra,104(sp)
    8000465e:	7406                	ld	s0,96(sp)
    80004660:	64e6                	ld	s1,88(sp)
    80004662:	6946                	ld	s2,80(sp)
    80004664:	69a6                	ld	s3,72(sp)
    80004666:	6a06                	ld	s4,64(sp)
    80004668:	7ae2                	ld	s5,56(sp)
    8000466a:	7b42                	ld	s6,48(sp)
    8000466c:	7ba2                	ld	s7,40(sp)
    8000466e:	7c02                	ld	s8,32(sp)
    80004670:	6ce2                	ld	s9,24(sp)
    80004672:	6d42                	ld	s10,16(sp)
    80004674:	6da2                	ld	s11,8(sp)
    80004676:	6165                	add	sp,sp,112
    80004678:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000467a:	89da                	mv	s3,s6
    8000467c:	bfc9                	j	8000464e <writei+0xe2>
    return -1;
    8000467e:	557d                	li	a0,-1
}
    80004680:	8082                	ret
    return -1;
    80004682:	557d                	li	a0,-1
    80004684:	bfe1                	j	8000465c <writei+0xf0>
    return -1;
    80004686:	557d                	li	a0,-1
    80004688:	bfd1                	j	8000465c <writei+0xf0>

000000008000468a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000468a:	1141                	add	sp,sp,-16
    8000468c:	e406                	sd	ra,8(sp)
    8000468e:	e022                	sd	s0,0(sp)
    80004690:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004692:	4639                	li	a2,14
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	70a080e7          	jalr	1802(ra) # 80000d9e <strncmp>
}
    8000469c:	60a2                	ld	ra,8(sp)
    8000469e:	6402                	ld	s0,0(sp)
    800046a0:	0141                	add	sp,sp,16
    800046a2:	8082                	ret

00000000800046a4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800046a4:	7139                	add	sp,sp,-64
    800046a6:	fc06                	sd	ra,56(sp)
    800046a8:	f822                	sd	s0,48(sp)
    800046aa:	f426                	sd	s1,40(sp)
    800046ac:	f04a                	sd	s2,32(sp)
    800046ae:	ec4e                	sd	s3,24(sp)
    800046b0:	e852                	sd	s4,16(sp)
    800046b2:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800046b4:	04451703          	lh	a4,68(a0)
    800046b8:	4785                	li	a5,1
    800046ba:	00f71a63          	bne	a4,a5,800046ce <dirlookup+0x2a>
    800046be:	892a                	mv	s2,a0
    800046c0:	89ae                	mv	s3,a1
    800046c2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800046c4:	457c                	lw	a5,76(a0)
    800046c6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800046c8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ca:	e79d                	bnez	a5,800046f8 <dirlookup+0x54>
    800046cc:	a8a5                	j	80004744 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800046ce:	00004517          	auipc	a0,0x4
    800046d2:	fba50513          	add	a0,a0,-70 # 80008688 <syscalls+0x1e8>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	e66080e7          	jalr	-410(ra) # 8000053c <panic>
      panic("dirlookup read");
    800046de:	00004517          	auipc	a0,0x4
    800046e2:	fc250513          	add	a0,a0,-62 # 800086a0 <syscalls+0x200>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	e56080e7          	jalr	-426(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ee:	24c1                	addw	s1,s1,16
    800046f0:	04c92783          	lw	a5,76(s2)
    800046f4:	04f4f763          	bgeu	s1,a5,80004742 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046f8:	4741                	li	a4,16
    800046fa:	86a6                	mv	a3,s1
    800046fc:	fc040613          	add	a2,s0,-64
    80004700:	4581                	li	a1,0
    80004702:	854a                	mv	a0,s2
    80004704:	00000097          	auipc	ra,0x0
    80004708:	d70080e7          	jalr	-656(ra) # 80004474 <readi>
    8000470c:	47c1                	li	a5,16
    8000470e:	fcf518e3          	bne	a0,a5,800046de <dirlookup+0x3a>
    if(de.inum == 0)
    80004712:	fc045783          	lhu	a5,-64(s0)
    80004716:	dfe1                	beqz	a5,800046ee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004718:	fc240593          	add	a1,s0,-62
    8000471c:	854e                	mv	a0,s3
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	f6c080e7          	jalr	-148(ra) # 8000468a <namecmp>
    80004726:	f561                	bnez	a0,800046ee <dirlookup+0x4a>
      if(poff)
    80004728:	000a0463          	beqz	s4,80004730 <dirlookup+0x8c>
        *poff = off;
    8000472c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004730:	fc045583          	lhu	a1,-64(s0)
    80004734:	00092503          	lw	a0,0(s2)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	754080e7          	jalr	1876(ra) # 80003e8c <iget>
    80004740:	a011                	j	80004744 <dirlookup+0xa0>
  return 0;
    80004742:	4501                	li	a0,0
}
    80004744:	70e2                	ld	ra,56(sp)
    80004746:	7442                	ld	s0,48(sp)
    80004748:	74a2                	ld	s1,40(sp)
    8000474a:	7902                	ld	s2,32(sp)
    8000474c:	69e2                	ld	s3,24(sp)
    8000474e:	6a42                	ld	s4,16(sp)
    80004750:	6121                	add	sp,sp,64
    80004752:	8082                	ret

0000000080004754 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004754:	711d                	add	sp,sp,-96
    80004756:	ec86                	sd	ra,88(sp)
    80004758:	e8a2                	sd	s0,80(sp)
    8000475a:	e4a6                	sd	s1,72(sp)
    8000475c:	e0ca                	sd	s2,64(sp)
    8000475e:	fc4e                	sd	s3,56(sp)
    80004760:	f852                	sd	s4,48(sp)
    80004762:	f456                	sd	s5,40(sp)
    80004764:	f05a                	sd	s6,32(sp)
    80004766:	ec5e                	sd	s7,24(sp)
    80004768:	e862                	sd	s8,16(sp)
    8000476a:	e466                	sd	s9,8(sp)
    8000476c:	1080                	add	s0,sp,96
    8000476e:	84aa                	mv	s1,a0
    80004770:	8b2e                	mv	s6,a1
    80004772:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004774:	00054703          	lbu	a4,0(a0)
    80004778:	02f00793          	li	a5,47
    8000477c:	02f70263          	beq	a4,a5,800047a0 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004780:	ffffd097          	auipc	ra,0xffffd
    80004784:	33e080e7          	jalr	830(ra) # 80001abe <myproc>
    80004788:	15053503          	ld	a0,336(a0)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	9f6080e7          	jalr	-1546(ra) # 80004182 <idup>
    80004794:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004796:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000479a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000479c:	4b85                	li	s7,1
    8000479e:	a875                	j	8000485a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800047a0:	4585                	li	a1,1
    800047a2:	4505                	li	a0,1
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	6e8080e7          	jalr	1768(ra) # 80003e8c <iget>
    800047ac:	8a2a                	mv	s4,a0
    800047ae:	b7e5                	j	80004796 <namex+0x42>
      iunlockput(ip);
    800047b0:	8552                	mv	a0,s4
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	c70080e7          	jalr	-912(ra) # 80004422 <iunlockput>
      return 0;
    800047ba:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800047bc:	8552                	mv	a0,s4
    800047be:	60e6                	ld	ra,88(sp)
    800047c0:	6446                	ld	s0,80(sp)
    800047c2:	64a6                	ld	s1,72(sp)
    800047c4:	6906                	ld	s2,64(sp)
    800047c6:	79e2                	ld	s3,56(sp)
    800047c8:	7a42                	ld	s4,48(sp)
    800047ca:	7aa2                	ld	s5,40(sp)
    800047cc:	7b02                	ld	s6,32(sp)
    800047ce:	6be2                	ld	s7,24(sp)
    800047d0:	6c42                	ld	s8,16(sp)
    800047d2:	6ca2                	ld	s9,8(sp)
    800047d4:	6125                	add	sp,sp,96
    800047d6:	8082                	ret
      iunlock(ip);
    800047d8:	8552                	mv	a0,s4
    800047da:	00000097          	auipc	ra,0x0
    800047de:	aa8080e7          	jalr	-1368(ra) # 80004282 <iunlock>
      return ip;
    800047e2:	bfe9                	j	800047bc <namex+0x68>
      iunlockput(ip);
    800047e4:	8552                	mv	a0,s4
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	c3c080e7          	jalr	-964(ra) # 80004422 <iunlockput>
      return 0;
    800047ee:	8a4e                	mv	s4,s3
    800047f0:	b7f1                	j	800047bc <namex+0x68>
  len = path - s;
    800047f2:	40998633          	sub	a2,s3,s1
    800047f6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800047fa:	099c5863          	bge	s8,s9,8000488a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800047fe:	4639                	li	a2,14
    80004800:	85a6                	mv	a1,s1
    80004802:	8556                	mv	a0,s5
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	526080e7          	jalr	1318(ra) # 80000d2a <memmove>
    8000480c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000480e:	0004c783          	lbu	a5,0(s1)
    80004812:	01279763          	bne	a5,s2,80004820 <namex+0xcc>
    path++;
    80004816:	0485                	add	s1,s1,1
  while(*path == '/')
    80004818:	0004c783          	lbu	a5,0(s1)
    8000481c:	ff278de3          	beq	a5,s2,80004816 <namex+0xc2>
    ilock(ip);
    80004820:	8552                	mv	a0,s4
    80004822:	00000097          	auipc	ra,0x0
    80004826:	99e080e7          	jalr	-1634(ra) # 800041c0 <ilock>
    if(ip->type != T_DIR){
    8000482a:	044a1783          	lh	a5,68(s4)
    8000482e:	f97791e3          	bne	a5,s7,800047b0 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004832:	000b0563          	beqz	s6,8000483c <namex+0xe8>
    80004836:	0004c783          	lbu	a5,0(s1)
    8000483a:	dfd9                	beqz	a5,800047d8 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000483c:	4601                	li	a2,0
    8000483e:	85d6                	mv	a1,s5
    80004840:	8552                	mv	a0,s4
    80004842:	00000097          	auipc	ra,0x0
    80004846:	e62080e7          	jalr	-414(ra) # 800046a4 <dirlookup>
    8000484a:	89aa                	mv	s3,a0
    8000484c:	dd41                	beqz	a0,800047e4 <namex+0x90>
    iunlockput(ip);
    8000484e:	8552                	mv	a0,s4
    80004850:	00000097          	auipc	ra,0x0
    80004854:	bd2080e7          	jalr	-1070(ra) # 80004422 <iunlockput>
    ip = next;
    80004858:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000485a:	0004c783          	lbu	a5,0(s1)
    8000485e:	01279763          	bne	a5,s2,8000486c <namex+0x118>
    path++;
    80004862:	0485                	add	s1,s1,1
  while(*path == '/')
    80004864:	0004c783          	lbu	a5,0(s1)
    80004868:	ff278de3          	beq	a5,s2,80004862 <namex+0x10e>
  if(*path == 0)
    8000486c:	cb9d                	beqz	a5,800048a2 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000486e:	0004c783          	lbu	a5,0(s1)
    80004872:	89a6                	mv	s3,s1
  len = path - s;
    80004874:	4c81                	li	s9,0
    80004876:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004878:	01278963          	beq	a5,s2,8000488a <namex+0x136>
    8000487c:	dbbd                	beqz	a5,800047f2 <namex+0x9e>
    path++;
    8000487e:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004880:	0009c783          	lbu	a5,0(s3)
    80004884:	ff279ce3          	bne	a5,s2,8000487c <namex+0x128>
    80004888:	b7ad                	j	800047f2 <namex+0x9e>
    memmove(name, s, len);
    8000488a:	2601                	sext.w	a2,a2
    8000488c:	85a6                	mv	a1,s1
    8000488e:	8556                	mv	a0,s5
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	49a080e7          	jalr	1178(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004898:	9cd6                	add	s9,s9,s5
    8000489a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000489e:	84ce                	mv	s1,s3
    800048a0:	b7bd                	j	8000480e <namex+0xba>
  if(nameiparent){
    800048a2:	f00b0de3          	beqz	s6,800047bc <namex+0x68>
    iput(ip);
    800048a6:	8552                	mv	a0,s4
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	ad2080e7          	jalr	-1326(ra) # 8000437a <iput>
    return 0;
    800048b0:	4a01                	li	s4,0
    800048b2:	b729                	j	800047bc <namex+0x68>

00000000800048b4 <dirlink>:
{
    800048b4:	7139                	add	sp,sp,-64
    800048b6:	fc06                	sd	ra,56(sp)
    800048b8:	f822                	sd	s0,48(sp)
    800048ba:	f426                	sd	s1,40(sp)
    800048bc:	f04a                	sd	s2,32(sp)
    800048be:	ec4e                	sd	s3,24(sp)
    800048c0:	e852                	sd	s4,16(sp)
    800048c2:	0080                	add	s0,sp,64
    800048c4:	892a                	mv	s2,a0
    800048c6:	8a2e                	mv	s4,a1
    800048c8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800048ca:	4601                	li	a2,0
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	dd8080e7          	jalr	-552(ra) # 800046a4 <dirlookup>
    800048d4:	e93d                	bnez	a0,8000494a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048d6:	04c92483          	lw	s1,76(s2)
    800048da:	c49d                	beqz	s1,80004908 <dirlink+0x54>
    800048dc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048de:	4741                	li	a4,16
    800048e0:	86a6                	mv	a3,s1
    800048e2:	fc040613          	add	a2,s0,-64
    800048e6:	4581                	li	a1,0
    800048e8:	854a                	mv	a0,s2
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	b8a080e7          	jalr	-1142(ra) # 80004474 <readi>
    800048f2:	47c1                	li	a5,16
    800048f4:	06f51163          	bne	a0,a5,80004956 <dirlink+0xa2>
    if(de.inum == 0)
    800048f8:	fc045783          	lhu	a5,-64(s0)
    800048fc:	c791                	beqz	a5,80004908 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048fe:	24c1                	addw	s1,s1,16
    80004900:	04c92783          	lw	a5,76(s2)
    80004904:	fcf4ede3          	bltu	s1,a5,800048de <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004908:	4639                	li	a2,14
    8000490a:	85d2                	mv	a1,s4
    8000490c:	fc240513          	add	a0,s0,-62
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	4ca080e7          	jalr	1226(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004918:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000491c:	4741                	li	a4,16
    8000491e:	86a6                	mv	a3,s1
    80004920:	fc040613          	add	a2,s0,-64
    80004924:	4581                	li	a1,0
    80004926:	854a                	mv	a0,s2
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	c44080e7          	jalr	-956(ra) # 8000456c <writei>
    80004930:	1541                	add	a0,a0,-16
    80004932:	00a03533          	snez	a0,a0
    80004936:	40a00533          	neg	a0,a0
}
    8000493a:	70e2                	ld	ra,56(sp)
    8000493c:	7442                	ld	s0,48(sp)
    8000493e:	74a2                	ld	s1,40(sp)
    80004940:	7902                	ld	s2,32(sp)
    80004942:	69e2                	ld	s3,24(sp)
    80004944:	6a42                	ld	s4,16(sp)
    80004946:	6121                	add	sp,sp,64
    80004948:	8082                	ret
    iput(ip);
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	a30080e7          	jalr	-1488(ra) # 8000437a <iput>
    return -1;
    80004952:	557d                	li	a0,-1
    80004954:	b7dd                	j	8000493a <dirlink+0x86>
      panic("dirlink read");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	d5a50513          	add	a0,a0,-678 # 800086b0 <syscalls+0x210>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	bde080e7          	jalr	-1058(ra) # 8000053c <panic>

0000000080004966 <namei>:

struct inode*
namei(char *path)
{
    80004966:	1101                	add	sp,sp,-32
    80004968:	ec06                	sd	ra,24(sp)
    8000496a:	e822                	sd	s0,16(sp)
    8000496c:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000496e:	fe040613          	add	a2,s0,-32
    80004972:	4581                	li	a1,0
    80004974:	00000097          	auipc	ra,0x0
    80004978:	de0080e7          	jalr	-544(ra) # 80004754 <namex>
}
    8000497c:	60e2                	ld	ra,24(sp)
    8000497e:	6442                	ld	s0,16(sp)
    80004980:	6105                	add	sp,sp,32
    80004982:	8082                	ret

0000000080004984 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004984:	1141                	add	sp,sp,-16
    80004986:	e406                	sd	ra,8(sp)
    80004988:	e022                	sd	s0,0(sp)
    8000498a:	0800                	add	s0,sp,16
    8000498c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000498e:	4585                	li	a1,1
    80004990:	00000097          	auipc	ra,0x0
    80004994:	dc4080e7          	jalr	-572(ra) # 80004754 <namex>
}
    80004998:	60a2                	ld	ra,8(sp)
    8000499a:	6402                	ld	s0,0(sp)
    8000499c:	0141                	add	sp,sp,16
    8000499e:	8082                	ret

00000000800049a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049a0:	1101                	add	sp,sp,-32
    800049a2:	ec06                	sd	ra,24(sp)
    800049a4:	e822                	sd	s0,16(sp)
    800049a6:	e426                	sd	s1,8(sp)
    800049a8:	e04a                	sd	s2,0(sp)
    800049aa:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800049ac:	00020917          	auipc	s2,0x20
    800049b0:	40490913          	add	s2,s2,1028 # 80024db0 <log>
    800049b4:	01892583          	lw	a1,24(s2)
    800049b8:	02892503          	lw	a0,40(s2)
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	ff4080e7          	jalr	-12(ra) # 800039b0 <bread>
    800049c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800049c6:	02c92603          	lw	a2,44(s2)
    800049ca:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800049cc:	00c05f63          	blez	a2,800049ea <write_head+0x4a>
    800049d0:	00020717          	auipc	a4,0x20
    800049d4:	41070713          	add	a4,a4,1040 # 80024de0 <log+0x30>
    800049d8:	87aa                	mv	a5,a0
    800049da:	060a                	sll	a2,a2,0x2
    800049dc:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800049de:	4314                	lw	a3,0(a4)
    800049e0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800049e2:	0711                	add	a4,a4,4
    800049e4:	0791                	add	a5,a5,4
    800049e6:	fec79ce3          	bne	a5,a2,800049de <write_head+0x3e>
  }
  bwrite(buf);
    800049ea:	8526                	mv	a0,s1
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	0b6080e7          	jalr	182(ra) # 80003aa2 <bwrite>
  brelse(buf);
    800049f4:	8526                	mv	a0,s1
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	0ea080e7          	jalr	234(ra) # 80003ae0 <brelse>
}
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6902                	ld	s2,0(sp)
    80004a06:	6105                	add	sp,sp,32
    80004a08:	8082                	ret

0000000080004a0a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a0a:	00020797          	auipc	a5,0x20
    80004a0e:	3d27a783          	lw	a5,978(a5) # 80024ddc <log+0x2c>
    80004a12:	0af05d63          	blez	a5,80004acc <install_trans+0xc2>
{
    80004a16:	7139                	add	sp,sp,-64
    80004a18:	fc06                	sd	ra,56(sp)
    80004a1a:	f822                	sd	s0,48(sp)
    80004a1c:	f426                	sd	s1,40(sp)
    80004a1e:	f04a                	sd	s2,32(sp)
    80004a20:	ec4e                	sd	s3,24(sp)
    80004a22:	e852                	sd	s4,16(sp)
    80004a24:	e456                	sd	s5,8(sp)
    80004a26:	e05a                	sd	s6,0(sp)
    80004a28:	0080                	add	s0,sp,64
    80004a2a:	8b2a                	mv	s6,a0
    80004a2c:	00020a97          	auipc	s5,0x20
    80004a30:	3b4a8a93          	add	s5,s5,948 # 80024de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a34:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a36:	00020997          	auipc	s3,0x20
    80004a3a:	37a98993          	add	s3,s3,890 # 80024db0 <log>
    80004a3e:	a00d                	j	80004a60 <install_trans+0x56>
    brelse(lbuf);
    80004a40:	854a                	mv	a0,s2
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	09e080e7          	jalr	158(ra) # 80003ae0 <brelse>
    brelse(dbuf);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	094080e7          	jalr	148(ra) # 80003ae0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a54:	2a05                	addw	s4,s4,1
    80004a56:	0a91                	add	s5,s5,4
    80004a58:	02c9a783          	lw	a5,44(s3)
    80004a5c:	04fa5e63          	bge	s4,a5,80004ab8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a60:	0189a583          	lw	a1,24(s3)
    80004a64:	014585bb          	addw	a1,a1,s4
    80004a68:	2585                	addw	a1,a1,1
    80004a6a:	0289a503          	lw	a0,40(s3)
    80004a6e:	fffff097          	auipc	ra,0xfffff
    80004a72:	f42080e7          	jalr	-190(ra) # 800039b0 <bread>
    80004a76:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a78:	000aa583          	lw	a1,0(s5)
    80004a7c:	0289a503          	lw	a0,40(s3)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	f30080e7          	jalr	-208(ra) # 800039b0 <bread>
    80004a88:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a8a:	40000613          	li	a2,1024
    80004a8e:	05890593          	add	a1,s2,88
    80004a92:	05850513          	add	a0,a0,88
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	294080e7          	jalr	660(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	002080e7          	jalr	2(ra) # 80003aa2 <bwrite>
    if(recovering == 0)
    80004aa8:	f80b1ce3          	bnez	s6,80004a40 <install_trans+0x36>
      bunpin(dbuf);
    80004aac:	8526                	mv	a0,s1
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	10a080e7          	jalr	266(ra) # 80003bb8 <bunpin>
    80004ab6:	b769                	j	80004a40 <install_trans+0x36>
}
    80004ab8:	70e2                	ld	ra,56(sp)
    80004aba:	7442                	ld	s0,48(sp)
    80004abc:	74a2                	ld	s1,40(sp)
    80004abe:	7902                	ld	s2,32(sp)
    80004ac0:	69e2                	ld	s3,24(sp)
    80004ac2:	6a42                	ld	s4,16(sp)
    80004ac4:	6aa2                	ld	s5,8(sp)
    80004ac6:	6b02                	ld	s6,0(sp)
    80004ac8:	6121                	add	sp,sp,64
    80004aca:	8082                	ret
    80004acc:	8082                	ret

0000000080004ace <initlog>:
{
    80004ace:	7179                	add	sp,sp,-48
    80004ad0:	f406                	sd	ra,40(sp)
    80004ad2:	f022                	sd	s0,32(sp)
    80004ad4:	ec26                	sd	s1,24(sp)
    80004ad6:	e84a                	sd	s2,16(sp)
    80004ad8:	e44e                	sd	s3,8(sp)
    80004ada:	1800                	add	s0,sp,48
    80004adc:	892a                	mv	s2,a0
    80004ade:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004ae0:	00020497          	auipc	s1,0x20
    80004ae4:	2d048493          	add	s1,s1,720 # 80024db0 <log>
    80004ae8:	00004597          	auipc	a1,0x4
    80004aec:	bd858593          	add	a1,a1,-1064 # 800086c0 <syscalls+0x220>
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	050080e7          	jalr	80(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004afa:	0149a583          	lw	a1,20(s3)
    80004afe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b00:	0109a783          	lw	a5,16(s3)
    80004b04:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b06:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b0a:	854a                	mv	a0,s2
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	ea4080e7          	jalr	-348(ra) # 800039b0 <bread>
  log.lh.n = lh->n;
    80004b14:	4d30                	lw	a2,88(a0)
    80004b16:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b18:	00c05f63          	blez	a2,80004b36 <initlog+0x68>
    80004b1c:	87aa                	mv	a5,a0
    80004b1e:	00020717          	auipc	a4,0x20
    80004b22:	2c270713          	add	a4,a4,706 # 80024de0 <log+0x30>
    80004b26:	060a                	sll	a2,a2,0x2
    80004b28:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004b2a:	4ff4                	lw	a3,92(a5)
    80004b2c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b2e:	0791                	add	a5,a5,4
    80004b30:	0711                	add	a4,a4,4
    80004b32:	fec79ce3          	bne	a5,a2,80004b2a <initlog+0x5c>
  brelse(buf);
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	faa080e7          	jalr	-86(ra) # 80003ae0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b3e:	4505                	li	a0,1
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	eca080e7          	jalr	-310(ra) # 80004a0a <install_trans>
  log.lh.n = 0;
    80004b48:	00020797          	auipc	a5,0x20
    80004b4c:	2807aa23          	sw	zero,660(a5) # 80024ddc <log+0x2c>
  write_head(); // clear the log
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	e50080e7          	jalr	-432(ra) # 800049a0 <write_head>
}
    80004b58:	70a2                	ld	ra,40(sp)
    80004b5a:	7402                	ld	s0,32(sp)
    80004b5c:	64e2                	ld	s1,24(sp)
    80004b5e:	6942                	ld	s2,16(sp)
    80004b60:	69a2                	ld	s3,8(sp)
    80004b62:	6145                	add	sp,sp,48
    80004b64:	8082                	ret

0000000080004b66 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b66:	1101                	add	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	e04a                	sd	s2,0(sp)
    80004b70:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004b72:	00020517          	auipc	a0,0x20
    80004b76:	23e50513          	add	a0,a0,574 # 80024db0 <log>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	058080e7          	jalr	88(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004b82:	00020497          	auipc	s1,0x20
    80004b86:	22e48493          	add	s1,s1,558 # 80024db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b8a:	4979                	li	s2,30
    80004b8c:	a039                	j	80004b9a <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b8e:	85a6                	mv	a1,s1
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffe097          	auipc	ra,0xffffe
    80004b96:	c3e080e7          	jalr	-962(ra) # 800027d0 <sleep>
    if(log.committing){
    80004b9a:	50dc                	lw	a5,36(s1)
    80004b9c:	fbed                	bnez	a5,80004b8e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b9e:	5098                	lw	a4,32(s1)
    80004ba0:	2705                	addw	a4,a4,1
    80004ba2:	0027179b          	sllw	a5,a4,0x2
    80004ba6:	9fb9                	addw	a5,a5,a4
    80004ba8:	0017979b          	sllw	a5,a5,0x1
    80004bac:	54d4                	lw	a3,44(s1)
    80004bae:	9fb5                	addw	a5,a5,a3
    80004bb0:	00f95963          	bge	s2,a5,80004bc2 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004bb4:	85a6                	mv	a1,s1
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffe097          	auipc	ra,0xffffe
    80004bbc:	c18080e7          	jalr	-1000(ra) # 800027d0 <sleep>
    80004bc0:	bfe9                	j	80004b9a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004bc2:	00020517          	auipc	a0,0x20
    80004bc6:	1ee50513          	add	a0,a0,494 # 80024db0 <log>
    80004bca:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	0ba080e7          	jalr	186(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004bd4:	60e2                	ld	ra,24(sp)
    80004bd6:	6442                	ld	s0,16(sp)
    80004bd8:	64a2                	ld	s1,8(sp)
    80004bda:	6902                	ld	s2,0(sp)
    80004bdc:	6105                	add	sp,sp,32
    80004bde:	8082                	ret

0000000080004be0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004be0:	7139                	add	sp,sp,-64
    80004be2:	fc06                	sd	ra,56(sp)
    80004be4:	f822                	sd	s0,48(sp)
    80004be6:	f426                	sd	s1,40(sp)
    80004be8:	f04a                	sd	s2,32(sp)
    80004bea:	ec4e                	sd	s3,24(sp)
    80004bec:	e852                	sd	s4,16(sp)
    80004bee:	e456                	sd	s5,8(sp)
    80004bf0:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004bf2:	00020497          	auipc	s1,0x20
    80004bf6:	1be48493          	add	s1,s1,446 # 80024db0 <log>
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fd6080e7          	jalr	-42(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004c04:	509c                	lw	a5,32(s1)
    80004c06:	37fd                	addw	a5,a5,-1
    80004c08:	0007891b          	sext.w	s2,a5
    80004c0c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c0e:	50dc                	lw	a5,36(s1)
    80004c10:	e7b9                	bnez	a5,80004c5e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c12:	04091e63          	bnez	s2,80004c6e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c16:	00020497          	auipc	s1,0x20
    80004c1a:	19a48493          	add	s1,s1,410 # 80024db0 <log>
    80004c1e:	4785                	li	a5,1
    80004c20:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	062080e7          	jalr	98(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c2c:	54dc                	lw	a5,44(s1)
    80004c2e:	06f04763          	bgtz	a5,80004c9c <end_op+0xbc>
    acquire(&log.lock);
    80004c32:	00020497          	auipc	s1,0x20
    80004c36:	17e48493          	add	s1,s1,382 # 80024db0 <log>
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	f96080e7          	jalr	-106(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004c44:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffe097          	auipc	ra,0xffffe
    80004c4e:	bea080e7          	jalr	-1046(ra) # 80002834 <wakeup>
    release(&log.lock);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	032080e7          	jalr	50(ra) # 80000c86 <release>
}
    80004c5c:	a03d                	j	80004c8a <end_op+0xaa>
    panic("log.committing");
    80004c5e:	00004517          	auipc	a0,0x4
    80004c62:	a6a50513          	add	a0,a0,-1430 # 800086c8 <syscalls+0x228>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8d6080e7          	jalr	-1834(ra) # 8000053c <panic>
    wakeup(&log);
    80004c6e:	00020497          	auipc	s1,0x20
    80004c72:	14248493          	add	s1,s1,322 # 80024db0 <log>
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffe097          	auipc	ra,0xffffe
    80004c7c:	bbc080e7          	jalr	-1092(ra) # 80002834 <wakeup>
  release(&log.lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	004080e7          	jalr	4(ra) # 80000c86 <release>
}
    80004c8a:	70e2                	ld	ra,56(sp)
    80004c8c:	7442                	ld	s0,48(sp)
    80004c8e:	74a2                	ld	s1,40(sp)
    80004c90:	7902                	ld	s2,32(sp)
    80004c92:	69e2                	ld	s3,24(sp)
    80004c94:	6a42                	ld	s4,16(sp)
    80004c96:	6aa2                	ld	s5,8(sp)
    80004c98:	6121                	add	sp,sp,64
    80004c9a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c9c:	00020a97          	auipc	s5,0x20
    80004ca0:	144a8a93          	add	s5,s5,324 # 80024de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ca4:	00020a17          	auipc	s4,0x20
    80004ca8:	10ca0a13          	add	s4,s4,268 # 80024db0 <log>
    80004cac:	018a2583          	lw	a1,24(s4)
    80004cb0:	012585bb          	addw	a1,a1,s2
    80004cb4:	2585                	addw	a1,a1,1
    80004cb6:	028a2503          	lw	a0,40(s4)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	cf6080e7          	jalr	-778(ra) # 800039b0 <bread>
    80004cc2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004cc4:	000aa583          	lw	a1,0(s5)
    80004cc8:	028a2503          	lw	a0,40(s4)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	ce4080e7          	jalr	-796(ra) # 800039b0 <bread>
    80004cd4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004cd6:	40000613          	li	a2,1024
    80004cda:	05850593          	add	a1,a0,88
    80004cde:	05848513          	add	a0,s1,88
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	048080e7          	jalr	72(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004cea:	8526                	mv	a0,s1
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	db6080e7          	jalr	-586(ra) # 80003aa2 <bwrite>
    brelse(from);
    80004cf4:	854e                	mv	a0,s3
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	dea080e7          	jalr	-534(ra) # 80003ae0 <brelse>
    brelse(to);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	de0080e7          	jalr	-544(ra) # 80003ae0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d08:	2905                	addw	s2,s2,1
    80004d0a:	0a91                	add	s5,s5,4
    80004d0c:	02ca2783          	lw	a5,44(s4)
    80004d10:	f8f94ee3          	blt	s2,a5,80004cac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	c8c080e7          	jalr	-884(ra) # 800049a0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004d1c:	4501                	li	a0,0
    80004d1e:	00000097          	auipc	ra,0x0
    80004d22:	cec080e7          	jalr	-788(ra) # 80004a0a <install_trans>
    log.lh.n = 0;
    80004d26:	00020797          	auipc	a5,0x20
    80004d2a:	0a07ab23          	sw	zero,182(a5) # 80024ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	c72080e7          	jalr	-910(ra) # 800049a0 <write_head>
    80004d36:	bdf5                	j	80004c32 <end_op+0x52>

0000000080004d38 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d38:	1101                	add	sp,sp,-32
    80004d3a:	ec06                	sd	ra,24(sp)
    80004d3c:	e822                	sd	s0,16(sp)
    80004d3e:	e426                	sd	s1,8(sp)
    80004d40:	e04a                	sd	s2,0(sp)
    80004d42:	1000                	add	s0,sp,32
    80004d44:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d46:	00020917          	auipc	s2,0x20
    80004d4a:	06a90913          	add	s2,s2,106 # 80024db0 <log>
    80004d4e:	854a                	mv	a0,s2
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	e82080e7          	jalr	-382(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d58:	02c92603          	lw	a2,44(s2)
    80004d5c:	47f5                	li	a5,29
    80004d5e:	06c7c563          	blt	a5,a2,80004dc8 <log_write+0x90>
    80004d62:	00020797          	auipc	a5,0x20
    80004d66:	06a7a783          	lw	a5,106(a5) # 80024dcc <log+0x1c>
    80004d6a:	37fd                	addw	a5,a5,-1
    80004d6c:	04f65e63          	bge	a2,a5,80004dc8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d70:	00020797          	auipc	a5,0x20
    80004d74:	0607a783          	lw	a5,96(a5) # 80024dd0 <log+0x20>
    80004d78:	06f05063          	blez	a5,80004dd8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d7c:	4781                	li	a5,0
    80004d7e:	06c05563          	blez	a2,80004de8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d82:	44cc                	lw	a1,12(s1)
    80004d84:	00020717          	auipc	a4,0x20
    80004d88:	05c70713          	add	a4,a4,92 # 80024de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d8c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d8e:	4314                	lw	a3,0(a4)
    80004d90:	04b68c63          	beq	a3,a1,80004de8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d94:	2785                	addw	a5,a5,1
    80004d96:	0711                	add	a4,a4,4
    80004d98:	fef61be3          	bne	a2,a5,80004d8e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d9c:	0621                	add	a2,a2,8
    80004d9e:	060a                	sll	a2,a2,0x2
    80004da0:	00020797          	auipc	a5,0x20
    80004da4:	01078793          	add	a5,a5,16 # 80024db0 <log>
    80004da8:	97b2                	add	a5,a5,a2
    80004daa:	44d8                	lw	a4,12(s1)
    80004dac:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	dcc080e7          	jalr	-564(ra) # 80003b7c <bpin>
    log.lh.n++;
    80004db8:	00020717          	auipc	a4,0x20
    80004dbc:	ff870713          	add	a4,a4,-8 # 80024db0 <log>
    80004dc0:	575c                	lw	a5,44(a4)
    80004dc2:	2785                	addw	a5,a5,1
    80004dc4:	d75c                	sw	a5,44(a4)
    80004dc6:	a82d                	j	80004e00 <log_write+0xc8>
    panic("too big a transaction");
    80004dc8:	00004517          	auipc	a0,0x4
    80004dcc:	91050513          	add	a0,a0,-1776 # 800086d8 <syscalls+0x238>
    80004dd0:	ffffb097          	auipc	ra,0xffffb
    80004dd4:	76c080e7          	jalr	1900(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004dd8:	00004517          	auipc	a0,0x4
    80004ddc:	91850513          	add	a0,a0,-1768 # 800086f0 <syscalls+0x250>
    80004de0:	ffffb097          	auipc	ra,0xffffb
    80004de4:	75c080e7          	jalr	1884(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004de8:	00878693          	add	a3,a5,8
    80004dec:	068a                	sll	a3,a3,0x2
    80004dee:	00020717          	auipc	a4,0x20
    80004df2:	fc270713          	add	a4,a4,-62 # 80024db0 <log>
    80004df6:	9736                	add	a4,a4,a3
    80004df8:	44d4                	lw	a3,12(s1)
    80004dfa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004dfc:	faf609e3          	beq	a2,a5,80004dae <log_write+0x76>
  }
  release(&log.lock);
    80004e00:	00020517          	auipc	a0,0x20
    80004e04:	fb050513          	add	a0,a0,-80 # 80024db0 <log>
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	e7e080e7          	jalr	-386(ra) # 80000c86 <release>
}
    80004e10:	60e2                	ld	ra,24(sp)
    80004e12:	6442                	ld	s0,16(sp)
    80004e14:	64a2                	ld	s1,8(sp)
    80004e16:	6902                	ld	s2,0(sp)
    80004e18:	6105                	add	sp,sp,32
    80004e1a:	8082                	ret

0000000080004e1c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e1c:	1101                	add	sp,sp,-32
    80004e1e:	ec06                	sd	ra,24(sp)
    80004e20:	e822                	sd	s0,16(sp)
    80004e22:	e426                	sd	s1,8(sp)
    80004e24:	e04a                	sd	s2,0(sp)
    80004e26:	1000                	add	s0,sp,32
    80004e28:	84aa                	mv	s1,a0
    80004e2a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e2c:	00004597          	auipc	a1,0x4
    80004e30:	8e458593          	add	a1,a1,-1820 # 80008710 <syscalls+0x270>
    80004e34:	0521                	add	a0,a0,8
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	d0c080e7          	jalr	-756(ra) # 80000b42 <initlock>
  lk->name = name;
    80004e3e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e42:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e46:	0204a423          	sw	zero,40(s1)
}
    80004e4a:	60e2                	ld	ra,24(sp)
    80004e4c:	6442                	ld	s0,16(sp)
    80004e4e:	64a2                	ld	s1,8(sp)
    80004e50:	6902                	ld	s2,0(sp)
    80004e52:	6105                	add	sp,sp,32
    80004e54:	8082                	ret

0000000080004e56 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
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
  while (lk->locked) {
    80004e72:	409c                	lw	a5,0(s1)
    80004e74:	cb89                	beqz	a5,80004e86 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e76:	85ca                	mv	a1,s2
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffe097          	auipc	ra,0xffffe
    80004e7e:	956080e7          	jalr	-1706(ra) # 800027d0 <sleep>
  while (lk->locked) {
    80004e82:	409c                	lw	a5,0(s1)
    80004e84:	fbed                	bnez	a5,80004e76 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e86:	4785                	li	a5,1
    80004e88:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	c34080e7          	jalr	-972(ra) # 80001abe <myproc>
    80004e92:	591c                	lw	a5,48(a0)
    80004e94:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e96:	854a                	mv	a0,s2
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	dee080e7          	jalr	-530(ra) # 80000c86 <release>
}
    80004ea0:	60e2                	ld	ra,24(sp)
    80004ea2:	6442                	ld	s0,16(sp)
    80004ea4:	64a2                	ld	s1,8(sp)
    80004ea6:	6902                	ld	s2,0(sp)
    80004ea8:	6105                	add	sp,sp,32
    80004eaa:	8082                	ret

0000000080004eac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004eac:	1101                	add	sp,sp,-32
    80004eae:	ec06                	sd	ra,24(sp)
    80004eb0:	e822                	sd	s0,16(sp)
    80004eb2:	e426                	sd	s1,8(sp)
    80004eb4:	e04a                	sd	s2,0(sp)
    80004eb6:	1000                	add	s0,sp,32
    80004eb8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004eba:	00850913          	add	s2,a0,8
    80004ebe:	854a                	mv	a0,s2
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	d12080e7          	jalr	-750(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004ec8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ecc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffe097          	auipc	ra,0xffffe
    80004ed6:	962080e7          	jalr	-1694(ra) # 80002834 <wakeup>
  release(&lk->lk);
    80004eda:	854a                	mv	a0,s2
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	daa080e7          	jalr	-598(ra) # 80000c86 <release>
}
    80004ee4:	60e2                	ld	ra,24(sp)
    80004ee6:	6442                	ld	s0,16(sp)
    80004ee8:	64a2                	ld	s1,8(sp)
    80004eea:	6902                	ld	s2,0(sp)
    80004eec:	6105                	add	sp,sp,32
    80004eee:	8082                	ret

0000000080004ef0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ef0:	7179                	add	sp,sp,-48
    80004ef2:	f406                	sd	ra,40(sp)
    80004ef4:	f022                	sd	s0,32(sp)
    80004ef6:	ec26                	sd	s1,24(sp)
    80004ef8:	e84a                	sd	s2,16(sp)
    80004efa:	e44e                	sd	s3,8(sp)
    80004efc:	1800                	add	s0,sp,48
    80004efe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f00:	00850913          	add	s2,a0,8
    80004f04:	854a                	mv	a0,s2
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	ccc080e7          	jalr	-820(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f0e:	409c                	lw	a5,0(s1)
    80004f10:	ef99                	bnez	a5,80004f2e <holdingsleep+0x3e>
    80004f12:	4481                	li	s1,0
  release(&lk->lk);
    80004f14:	854a                	mv	a0,s2
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	d70080e7          	jalr	-656(ra) # 80000c86 <release>
  return r;
}
    80004f1e:	8526                	mv	a0,s1
    80004f20:	70a2                	ld	ra,40(sp)
    80004f22:	7402                	ld	s0,32(sp)
    80004f24:	64e2                	ld	s1,24(sp)
    80004f26:	6942                	ld	s2,16(sp)
    80004f28:	69a2                	ld	s3,8(sp)
    80004f2a:	6145                	add	sp,sp,48
    80004f2c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f2e:	0284a983          	lw	s3,40(s1)
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	b8c080e7          	jalr	-1140(ra) # 80001abe <myproc>
    80004f3a:	5904                	lw	s1,48(a0)
    80004f3c:	413484b3          	sub	s1,s1,s3
    80004f40:	0014b493          	seqz	s1,s1
    80004f44:	bfc1                	j	80004f14 <holdingsleep+0x24>

0000000080004f46 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f46:	1141                	add	sp,sp,-16
    80004f48:	e406                	sd	ra,8(sp)
    80004f4a:	e022                	sd	s0,0(sp)
    80004f4c:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f4e:	00003597          	auipc	a1,0x3
    80004f52:	7d258593          	add	a1,a1,2002 # 80008720 <syscalls+0x280>
    80004f56:	00020517          	auipc	a0,0x20
    80004f5a:	fa250513          	add	a0,a0,-94 # 80024ef8 <ftable>
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	be4080e7          	jalr	-1052(ra) # 80000b42 <initlock>
}
    80004f66:	60a2                	ld	ra,8(sp)
    80004f68:	6402                	ld	s0,0(sp)
    80004f6a:	0141                	add	sp,sp,16
    80004f6c:	8082                	ret

0000000080004f6e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f6e:	1101                	add	sp,sp,-32
    80004f70:	ec06                	sd	ra,24(sp)
    80004f72:	e822                	sd	s0,16(sp)
    80004f74:	e426                	sd	s1,8(sp)
    80004f76:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f78:	00020517          	auipc	a0,0x20
    80004f7c:	f8050513          	add	a0,a0,-128 # 80024ef8 <ftable>
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	c52080e7          	jalr	-942(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f88:	00020497          	auipc	s1,0x20
    80004f8c:	f8848493          	add	s1,s1,-120 # 80024f10 <ftable+0x18>
    80004f90:	00021717          	auipc	a4,0x21
    80004f94:	f2070713          	add	a4,a4,-224 # 80025eb0 <disk>
    if(f->ref == 0){
    80004f98:	40dc                	lw	a5,4(s1)
    80004f9a:	cf99                	beqz	a5,80004fb8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f9c:	02848493          	add	s1,s1,40
    80004fa0:	fee49ce3          	bne	s1,a4,80004f98 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004fa4:	00020517          	auipc	a0,0x20
    80004fa8:	f5450513          	add	a0,a0,-172 # 80024ef8 <ftable>
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	cda080e7          	jalr	-806(ra) # 80000c86 <release>
  return 0;
    80004fb4:	4481                	li	s1,0
    80004fb6:	a819                	j	80004fcc <filealloc+0x5e>
      f->ref = 1;
    80004fb8:	4785                	li	a5,1
    80004fba:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004fbc:	00020517          	auipc	a0,0x20
    80004fc0:	f3c50513          	add	a0,a0,-196 # 80024ef8 <ftable>
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	cc2080e7          	jalr	-830(ra) # 80000c86 <release>
}
    80004fcc:	8526                	mv	a0,s1
    80004fce:	60e2                	ld	ra,24(sp)
    80004fd0:	6442                	ld	s0,16(sp)
    80004fd2:	64a2                	ld	s1,8(sp)
    80004fd4:	6105                	add	sp,sp,32
    80004fd6:	8082                	ret

0000000080004fd8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004fd8:	1101                	add	sp,sp,-32
    80004fda:	ec06                	sd	ra,24(sp)
    80004fdc:	e822                	sd	s0,16(sp)
    80004fde:	e426                	sd	s1,8(sp)
    80004fe0:	1000                	add	s0,sp,32
    80004fe2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004fe4:	00020517          	auipc	a0,0x20
    80004fe8:	f1450513          	add	a0,a0,-236 # 80024ef8 <ftable>
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	be6080e7          	jalr	-1050(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004ff4:	40dc                	lw	a5,4(s1)
    80004ff6:	02f05263          	blez	a5,8000501a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ffa:	2785                	addw	a5,a5,1
    80004ffc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ffe:	00020517          	auipc	a0,0x20
    80005002:	efa50513          	add	a0,a0,-262 # 80024ef8 <ftable>
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	c80080e7          	jalr	-896(ra) # 80000c86 <release>
  return f;
}
    8000500e:	8526                	mv	a0,s1
    80005010:	60e2                	ld	ra,24(sp)
    80005012:	6442                	ld	s0,16(sp)
    80005014:	64a2                	ld	s1,8(sp)
    80005016:	6105                	add	sp,sp,32
    80005018:	8082                	ret
    panic("filedup");
    8000501a:	00003517          	auipc	a0,0x3
    8000501e:	70e50513          	add	a0,a0,1806 # 80008728 <syscalls+0x288>
    80005022:	ffffb097          	auipc	ra,0xffffb
    80005026:	51a080e7          	jalr	1306(ra) # 8000053c <panic>

000000008000502a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000502a:	7139                	add	sp,sp,-64
    8000502c:	fc06                	sd	ra,56(sp)
    8000502e:	f822                	sd	s0,48(sp)
    80005030:	f426                	sd	s1,40(sp)
    80005032:	f04a                	sd	s2,32(sp)
    80005034:	ec4e                	sd	s3,24(sp)
    80005036:	e852                	sd	s4,16(sp)
    80005038:	e456                	sd	s5,8(sp)
    8000503a:	0080                	add	s0,sp,64
    8000503c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000503e:	00020517          	auipc	a0,0x20
    80005042:	eba50513          	add	a0,a0,-326 # 80024ef8 <ftable>
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	b8c080e7          	jalr	-1140(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000504e:	40dc                	lw	a5,4(s1)
    80005050:	06f05163          	blez	a5,800050b2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005054:	37fd                	addw	a5,a5,-1
    80005056:	0007871b          	sext.w	a4,a5
    8000505a:	c0dc                	sw	a5,4(s1)
    8000505c:	06e04363          	bgtz	a4,800050c2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005060:	0004a903          	lw	s2,0(s1)
    80005064:	0094ca83          	lbu	s5,9(s1)
    80005068:	0104ba03          	ld	s4,16(s1)
    8000506c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005070:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005074:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005078:	00020517          	auipc	a0,0x20
    8000507c:	e8050513          	add	a0,a0,-384 # 80024ef8 <ftable>
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	c06080e7          	jalr	-1018(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80005088:	4785                	li	a5,1
    8000508a:	04f90d63          	beq	s2,a5,800050e4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000508e:	3979                	addw	s2,s2,-2
    80005090:	4785                	li	a5,1
    80005092:	0527e063          	bltu	a5,s2,800050d2 <fileclose+0xa8>
    begin_op();
    80005096:	00000097          	auipc	ra,0x0
    8000509a:	ad0080e7          	jalr	-1328(ra) # 80004b66 <begin_op>
    iput(ff.ip);
    8000509e:	854e                	mv	a0,s3
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	2da080e7          	jalr	730(ra) # 8000437a <iput>
    end_op();
    800050a8:	00000097          	auipc	ra,0x0
    800050ac:	b38080e7          	jalr	-1224(ra) # 80004be0 <end_op>
    800050b0:	a00d                	j	800050d2 <fileclose+0xa8>
    panic("fileclose");
    800050b2:	00003517          	auipc	a0,0x3
    800050b6:	67e50513          	add	a0,a0,1662 # 80008730 <syscalls+0x290>
    800050ba:	ffffb097          	auipc	ra,0xffffb
    800050be:	482080e7          	jalr	1154(ra) # 8000053c <panic>
    release(&ftable.lock);
    800050c2:	00020517          	auipc	a0,0x20
    800050c6:	e3650513          	add	a0,a0,-458 # 80024ef8 <ftable>
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	bbc080e7          	jalr	-1092(ra) # 80000c86 <release>
  }
}
    800050d2:	70e2                	ld	ra,56(sp)
    800050d4:	7442                	ld	s0,48(sp)
    800050d6:	74a2                	ld	s1,40(sp)
    800050d8:	7902                	ld	s2,32(sp)
    800050da:	69e2                	ld	s3,24(sp)
    800050dc:	6a42                	ld	s4,16(sp)
    800050de:	6aa2                	ld	s5,8(sp)
    800050e0:	6121                	add	sp,sp,64
    800050e2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800050e4:	85d6                	mv	a1,s5
    800050e6:	8552                	mv	a0,s4
    800050e8:	00000097          	auipc	ra,0x0
    800050ec:	348080e7          	jalr	840(ra) # 80005430 <pipeclose>
    800050f0:	b7cd                	j	800050d2 <fileclose+0xa8>

00000000800050f2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800050f2:	715d                	add	sp,sp,-80
    800050f4:	e486                	sd	ra,72(sp)
    800050f6:	e0a2                	sd	s0,64(sp)
    800050f8:	fc26                	sd	s1,56(sp)
    800050fa:	f84a                	sd	s2,48(sp)
    800050fc:	f44e                	sd	s3,40(sp)
    800050fe:	0880                	add	s0,sp,80
    80005100:	84aa                	mv	s1,a0
    80005102:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	9ba080e7          	jalr	-1606(ra) # 80001abe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000510c:	409c                	lw	a5,0(s1)
    8000510e:	37f9                	addw	a5,a5,-2
    80005110:	4705                	li	a4,1
    80005112:	04f76763          	bltu	a4,a5,80005160 <filestat+0x6e>
    80005116:	892a                	mv	s2,a0
    ilock(f->ip);
    80005118:	6c88                	ld	a0,24(s1)
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	0a6080e7          	jalr	166(ra) # 800041c0 <ilock>
    stati(f->ip, &st);
    80005122:	fb840593          	add	a1,s0,-72
    80005126:	6c88                	ld	a0,24(s1)
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	322080e7          	jalr	802(ra) # 8000444a <stati>
    iunlock(f->ip);
    80005130:	6c88                	ld	a0,24(s1)
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	150080e7          	jalr	336(ra) # 80004282 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000513a:	46e1                	li	a3,24
    8000513c:	fb840613          	add	a2,s0,-72
    80005140:	85ce                	mv	a1,s3
    80005142:	05093503          	ld	a0,80(s2)
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	520080e7          	jalr	1312(ra) # 80001666 <copyout>
    8000514e:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005152:	60a6                	ld	ra,72(sp)
    80005154:	6406                	ld	s0,64(sp)
    80005156:	74e2                	ld	s1,56(sp)
    80005158:	7942                	ld	s2,48(sp)
    8000515a:	79a2                	ld	s3,40(sp)
    8000515c:	6161                	add	sp,sp,80
    8000515e:	8082                	ret
  return -1;
    80005160:	557d                	li	a0,-1
    80005162:	bfc5                	j	80005152 <filestat+0x60>

0000000080005164 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005164:	7179                	add	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	ec26                	sd	s1,24(sp)
    8000516c:	e84a                	sd	s2,16(sp)
    8000516e:	e44e                	sd	s3,8(sp)
    80005170:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005172:	00854783          	lbu	a5,8(a0)
    80005176:	c3d5                	beqz	a5,8000521a <fileread+0xb6>
    80005178:	84aa                	mv	s1,a0
    8000517a:	89ae                	mv	s3,a1
    8000517c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000517e:	411c                	lw	a5,0(a0)
    80005180:	4705                	li	a4,1
    80005182:	04e78963          	beq	a5,a4,800051d4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005186:	470d                	li	a4,3
    80005188:	04e78d63          	beq	a5,a4,800051e2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000518c:	4709                	li	a4,2
    8000518e:	06e79e63          	bne	a5,a4,8000520a <fileread+0xa6>
    ilock(f->ip);
    80005192:	6d08                	ld	a0,24(a0)
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	02c080e7          	jalr	44(ra) # 800041c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000519c:	874a                	mv	a4,s2
    8000519e:	5094                	lw	a3,32(s1)
    800051a0:	864e                	mv	a2,s3
    800051a2:	4585                	li	a1,1
    800051a4:	6c88                	ld	a0,24(s1)
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	2ce080e7          	jalr	718(ra) # 80004474 <readi>
    800051ae:	892a                	mv	s2,a0
    800051b0:	00a05563          	blez	a0,800051ba <fileread+0x56>
      f->off += r;
    800051b4:	509c                	lw	a5,32(s1)
    800051b6:	9fa9                	addw	a5,a5,a0
    800051b8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051ba:	6c88                	ld	a0,24(s1)
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	0c6080e7          	jalr	198(ra) # 80004282 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051c4:	854a                	mv	a0,s2
    800051c6:	70a2                	ld	ra,40(sp)
    800051c8:	7402                	ld	s0,32(sp)
    800051ca:	64e2                	ld	s1,24(sp)
    800051cc:	6942                	ld	s2,16(sp)
    800051ce:	69a2                	ld	s3,8(sp)
    800051d0:	6145                	add	sp,sp,48
    800051d2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800051d4:	6908                	ld	a0,16(a0)
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	3c2080e7          	jalr	962(ra) # 80005598 <piperead>
    800051de:	892a                	mv	s2,a0
    800051e0:	b7d5                	j	800051c4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800051e2:	02451783          	lh	a5,36(a0)
    800051e6:	03079693          	sll	a3,a5,0x30
    800051ea:	92c1                	srl	a3,a3,0x30
    800051ec:	4725                	li	a4,9
    800051ee:	02d76863          	bltu	a4,a3,8000521e <fileread+0xba>
    800051f2:	0792                	sll	a5,a5,0x4
    800051f4:	00020717          	auipc	a4,0x20
    800051f8:	c6470713          	add	a4,a4,-924 # 80024e58 <devsw>
    800051fc:	97ba                	add	a5,a5,a4
    800051fe:	639c                	ld	a5,0(a5)
    80005200:	c38d                	beqz	a5,80005222 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005202:	4505                	li	a0,1
    80005204:	9782                	jalr	a5
    80005206:	892a                	mv	s2,a0
    80005208:	bf75                	j	800051c4 <fileread+0x60>
    panic("fileread");
    8000520a:	00003517          	auipc	a0,0x3
    8000520e:	53650513          	add	a0,a0,1334 # 80008740 <syscalls+0x2a0>
    80005212:	ffffb097          	auipc	ra,0xffffb
    80005216:	32a080e7          	jalr	810(ra) # 8000053c <panic>
    return -1;
    8000521a:	597d                	li	s2,-1
    8000521c:	b765                	j	800051c4 <fileread+0x60>
      return -1;
    8000521e:	597d                	li	s2,-1
    80005220:	b755                	j	800051c4 <fileread+0x60>
    80005222:	597d                	li	s2,-1
    80005224:	b745                	j	800051c4 <fileread+0x60>

0000000080005226 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80005226:	00954783          	lbu	a5,9(a0)
    8000522a:	10078e63          	beqz	a5,80005346 <filewrite+0x120>
{
    8000522e:	715d                	add	sp,sp,-80
    80005230:	e486                	sd	ra,72(sp)
    80005232:	e0a2                	sd	s0,64(sp)
    80005234:	fc26                	sd	s1,56(sp)
    80005236:	f84a                	sd	s2,48(sp)
    80005238:	f44e                	sd	s3,40(sp)
    8000523a:	f052                	sd	s4,32(sp)
    8000523c:	ec56                	sd	s5,24(sp)
    8000523e:	e85a                	sd	s6,16(sp)
    80005240:	e45e                	sd	s7,8(sp)
    80005242:	e062                	sd	s8,0(sp)
    80005244:	0880                	add	s0,sp,80
    80005246:	892a                	mv	s2,a0
    80005248:	8b2e                	mv	s6,a1
    8000524a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000524c:	411c                	lw	a5,0(a0)
    8000524e:	4705                	li	a4,1
    80005250:	02e78263          	beq	a5,a4,80005274 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005254:	470d                	li	a4,3
    80005256:	02e78563          	beq	a5,a4,80005280 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000525a:	4709                	li	a4,2
    8000525c:	0ce79d63          	bne	a5,a4,80005336 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005260:	0ac05b63          	blez	a2,80005316 <filewrite+0xf0>
    int i = 0;
    80005264:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80005266:	6b85                	lui	s7,0x1
    80005268:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000526c:	6c05                	lui	s8,0x1
    8000526e:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005272:	a851                	j	80005306 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80005274:	6908                	ld	a0,16(a0)
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	22a080e7          	jalr	554(ra) # 800054a0 <pipewrite>
    8000527e:	a045                	j	8000531e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005280:	02451783          	lh	a5,36(a0)
    80005284:	03079693          	sll	a3,a5,0x30
    80005288:	92c1                	srl	a3,a3,0x30
    8000528a:	4725                	li	a4,9
    8000528c:	0ad76f63          	bltu	a4,a3,8000534a <filewrite+0x124>
    80005290:	0792                	sll	a5,a5,0x4
    80005292:	00020717          	auipc	a4,0x20
    80005296:	bc670713          	add	a4,a4,-1082 # 80024e58 <devsw>
    8000529a:	97ba                	add	a5,a5,a4
    8000529c:	679c                	ld	a5,8(a5)
    8000529e:	cbc5                	beqz	a5,8000534e <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800052a0:	4505                	li	a0,1
    800052a2:	9782                	jalr	a5
    800052a4:	a8ad                	j	8000531e <filewrite+0xf8>
      if(n1 > max)
    800052a6:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	8bc080e7          	jalr	-1860(ra) # 80004b66 <begin_op>
      ilock(f->ip);
    800052b2:	01893503          	ld	a0,24(s2)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	f0a080e7          	jalr	-246(ra) # 800041c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800052be:	8756                	mv	a4,s5
    800052c0:	02092683          	lw	a3,32(s2)
    800052c4:	01698633          	add	a2,s3,s6
    800052c8:	4585                	li	a1,1
    800052ca:	01893503          	ld	a0,24(s2)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	29e080e7          	jalr	670(ra) # 8000456c <writei>
    800052d6:	84aa                	mv	s1,a0
    800052d8:	00a05763          	blez	a0,800052e6 <filewrite+0xc0>
        f->off += r;
    800052dc:	02092783          	lw	a5,32(s2)
    800052e0:	9fa9                	addw	a5,a5,a0
    800052e2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800052e6:	01893503          	ld	a0,24(s2)
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	f98080e7          	jalr	-104(ra) # 80004282 <iunlock>
      end_op();
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	8ee080e7          	jalr	-1810(ra) # 80004be0 <end_op>

      if(r != n1){
    800052fa:	009a9f63          	bne	s5,s1,80005318 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800052fe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005302:	0149db63          	bge	s3,s4,80005318 <filewrite+0xf2>
      int n1 = n - i;
    80005306:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000530a:	0004879b          	sext.w	a5,s1
    8000530e:	f8fbdce3          	bge	s7,a5,800052a6 <filewrite+0x80>
    80005312:	84e2                	mv	s1,s8
    80005314:	bf49                	j	800052a6 <filewrite+0x80>
    int i = 0;
    80005316:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005318:	033a1d63          	bne	s4,s3,80005352 <filewrite+0x12c>
    8000531c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000531e:	60a6                	ld	ra,72(sp)
    80005320:	6406                	ld	s0,64(sp)
    80005322:	74e2                	ld	s1,56(sp)
    80005324:	7942                	ld	s2,48(sp)
    80005326:	79a2                	ld	s3,40(sp)
    80005328:	7a02                	ld	s4,32(sp)
    8000532a:	6ae2                	ld	s5,24(sp)
    8000532c:	6b42                	ld	s6,16(sp)
    8000532e:	6ba2                	ld	s7,8(sp)
    80005330:	6c02                	ld	s8,0(sp)
    80005332:	6161                	add	sp,sp,80
    80005334:	8082                	ret
    panic("filewrite");
    80005336:	00003517          	auipc	a0,0x3
    8000533a:	41a50513          	add	a0,a0,1050 # 80008750 <syscalls+0x2b0>
    8000533e:	ffffb097          	auipc	ra,0xffffb
    80005342:	1fe080e7          	jalr	510(ra) # 8000053c <panic>
    return -1;
    80005346:	557d                	li	a0,-1
}
    80005348:	8082                	ret
      return -1;
    8000534a:	557d                	li	a0,-1
    8000534c:	bfc9                	j	8000531e <filewrite+0xf8>
    8000534e:	557d                	li	a0,-1
    80005350:	b7f9                	j	8000531e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80005352:	557d                	li	a0,-1
    80005354:	b7e9                	j	8000531e <filewrite+0xf8>

0000000080005356 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005356:	7179                	add	sp,sp,-48
    80005358:	f406                	sd	ra,40(sp)
    8000535a:	f022                	sd	s0,32(sp)
    8000535c:	ec26                	sd	s1,24(sp)
    8000535e:	e84a                	sd	s2,16(sp)
    80005360:	e44e                	sd	s3,8(sp)
    80005362:	e052                	sd	s4,0(sp)
    80005364:	1800                	add	s0,sp,48
    80005366:	84aa                	mv	s1,a0
    80005368:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000536a:	0005b023          	sd	zero,0(a1)
    8000536e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005372:	00000097          	auipc	ra,0x0
    80005376:	bfc080e7          	jalr	-1028(ra) # 80004f6e <filealloc>
    8000537a:	e088                	sd	a0,0(s1)
    8000537c:	c551                	beqz	a0,80005408 <pipealloc+0xb2>
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	bf0080e7          	jalr	-1040(ra) # 80004f6e <filealloc>
    80005386:	00aa3023          	sd	a0,0(s4)
    8000538a:	c92d                	beqz	a0,800053fc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000538c:	ffffb097          	auipc	ra,0xffffb
    80005390:	756080e7          	jalr	1878(ra) # 80000ae2 <kalloc>
    80005394:	892a                	mv	s2,a0
    80005396:	c125                	beqz	a0,800053f6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005398:	4985                	li	s3,1
    8000539a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000539e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800053a2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800053a6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053aa:	00003597          	auipc	a1,0x3
    800053ae:	3b658593          	add	a1,a1,950 # 80008760 <syscalls+0x2c0>
    800053b2:	ffffb097          	auipc	ra,0xffffb
    800053b6:	790080e7          	jalr	1936(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    800053ba:	609c                	ld	a5,0(s1)
    800053bc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800053c0:	609c                	ld	a5,0(s1)
    800053c2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800053c6:	609c                	ld	a5,0(s1)
    800053c8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800053cc:	609c                	ld	a5,0(s1)
    800053ce:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800053d2:	000a3783          	ld	a5,0(s4)
    800053d6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800053da:	000a3783          	ld	a5,0(s4)
    800053de:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800053e2:	000a3783          	ld	a5,0(s4)
    800053e6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053ea:	000a3783          	ld	a5,0(s4)
    800053ee:	0127b823          	sd	s2,16(a5)
  return 0;
    800053f2:	4501                	li	a0,0
    800053f4:	a025                	j	8000541c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053f6:	6088                	ld	a0,0(s1)
    800053f8:	e501                	bnez	a0,80005400 <pipealloc+0xaa>
    800053fa:	a039                	j	80005408 <pipealloc+0xb2>
    800053fc:	6088                	ld	a0,0(s1)
    800053fe:	c51d                	beqz	a0,8000542c <pipealloc+0xd6>
    fileclose(*f0);
    80005400:	00000097          	auipc	ra,0x0
    80005404:	c2a080e7          	jalr	-982(ra) # 8000502a <fileclose>
  if(*f1)
    80005408:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000540c:	557d                	li	a0,-1
  if(*f1)
    8000540e:	c799                	beqz	a5,8000541c <pipealloc+0xc6>
    fileclose(*f1);
    80005410:	853e                	mv	a0,a5
    80005412:	00000097          	auipc	ra,0x0
    80005416:	c18080e7          	jalr	-1000(ra) # 8000502a <fileclose>
  return -1;
    8000541a:	557d                	li	a0,-1
}
    8000541c:	70a2                	ld	ra,40(sp)
    8000541e:	7402                	ld	s0,32(sp)
    80005420:	64e2                	ld	s1,24(sp)
    80005422:	6942                	ld	s2,16(sp)
    80005424:	69a2                	ld	s3,8(sp)
    80005426:	6a02                	ld	s4,0(sp)
    80005428:	6145                	add	sp,sp,48
    8000542a:	8082                	ret
  return -1;
    8000542c:	557d                	li	a0,-1
    8000542e:	b7fd                	j	8000541c <pipealloc+0xc6>

0000000080005430 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005430:	1101                	add	sp,sp,-32
    80005432:	ec06                	sd	ra,24(sp)
    80005434:	e822                	sd	s0,16(sp)
    80005436:	e426                	sd	s1,8(sp)
    80005438:	e04a                	sd	s2,0(sp)
    8000543a:	1000                	add	s0,sp,32
    8000543c:	84aa                	mv	s1,a0
    8000543e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005440:	ffffb097          	auipc	ra,0xffffb
    80005444:	792080e7          	jalr	1938(ra) # 80000bd2 <acquire>
  if(writable){
    80005448:	02090d63          	beqz	s2,80005482 <pipeclose+0x52>
    pi->writeopen = 0;
    8000544c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005450:	21848513          	add	a0,s1,536
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	3e0080e7          	jalr	992(ra) # 80002834 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000545c:	2204b783          	ld	a5,544(s1)
    80005460:	eb95                	bnez	a5,80005494 <pipeclose+0x64>
    release(&pi->lock);
    80005462:	8526                	mv	a0,s1
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	822080e7          	jalr	-2014(ra) # 80000c86 <release>
    kfree((char*)pi);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffb097          	auipc	ra,0xffffb
    80005472:	576080e7          	jalr	1398(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005476:	60e2                	ld	ra,24(sp)
    80005478:	6442                	ld	s0,16(sp)
    8000547a:	64a2                	ld	s1,8(sp)
    8000547c:	6902                	ld	s2,0(sp)
    8000547e:	6105                	add	sp,sp,32
    80005480:	8082                	ret
    pi->readopen = 0;
    80005482:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005486:	21c48513          	add	a0,s1,540
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	3aa080e7          	jalr	938(ra) # 80002834 <wakeup>
    80005492:	b7e9                	j	8000545c <pipeclose+0x2c>
    release(&pi->lock);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffb097          	auipc	ra,0xffffb
    8000549a:	7f0080e7          	jalr	2032(ra) # 80000c86 <release>
}
    8000549e:	bfe1                	j	80005476 <pipeclose+0x46>

00000000800054a0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800054a0:	711d                	add	sp,sp,-96
    800054a2:	ec86                	sd	ra,88(sp)
    800054a4:	e8a2                	sd	s0,80(sp)
    800054a6:	e4a6                	sd	s1,72(sp)
    800054a8:	e0ca                	sd	s2,64(sp)
    800054aa:	fc4e                	sd	s3,56(sp)
    800054ac:	f852                	sd	s4,48(sp)
    800054ae:	f456                	sd	s5,40(sp)
    800054b0:	f05a                	sd	s6,32(sp)
    800054b2:	ec5e                	sd	s7,24(sp)
    800054b4:	e862                	sd	s8,16(sp)
    800054b6:	1080                	add	s0,sp,96
    800054b8:	84aa                	mv	s1,a0
    800054ba:	8aae                	mv	s5,a1
    800054bc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	600080e7          	jalr	1536(ra) # 80001abe <myproc>
    800054c6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffb097          	auipc	ra,0xffffb
    800054ce:	708080e7          	jalr	1800(ra) # 80000bd2 <acquire>
  while(i < n){
    800054d2:	0b405663          	blez	s4,8000557e <pipewrite+0xde>
  int i = 0;
    800054d6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054d8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800054da:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800054de:	21c48b93          	add	s7,s1,540
    800054e2:	a089                	j	80005524 <pipewrite+0x84>
      release(&pi->lock);
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffb097          	auipc	ra,0xffffb
    800054ea:	7a0080e7          	jalr	1952(ra) # 80000c86 <release>
      return -1;
    800054ee:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054f0:	854a                	mv	a0,s2
    800054f2:	60e6                	ld	ra,88(sp)
    800054f4:	6446                	ld	s0,80(sp)
    800054f6:	64a6                	ld	s1,72(sp)
    800054f8:	6906                	ld	s2,64(sp)
    800054fa:	79e2                	ld	s3,56(sp)
    800054fc:	7a42                	ld	s4,48(sp)
    800054fe:	7aa2                	ld	s5,40(sp)
    80005500:	7b02                	ld	s6,32(sp)
    80005502:	6be2                	ld	s7,24(sp)
    80005504:	6c42                	ld	s8,16(sp)
    80005506:	6125                	add	sp,sp,96
    80005508:	8082                	ret
      wakeup(&pi->nread);
    8000550a:	8562                	mv	a0,s8
    8000550c:	ffffd097          	auipc	ra,0xffffd
    80005510:	328080e7          	jalr	808(ra) # 80002834 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005514:	85a6                	mv	a1,s1
    80005516:	855e                	mv	a0,s7
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	2b8080e7          	jalr	696(ra) # 800027d0 <sleep>
  while(i < n){
    80005520:	07495063          	bge	s2,s4,80005580 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005524:	2204a783          	lw	a5,544(s1)
    80005528:	dfd5                	beqz	a5,800054e4 <pipewrite+0x44>
    8000552a:	854e                	mv	a0,s3
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	558080e7          	jalr	1368(ra) # 80002a84 <killed>
    80005534:	f945                	bnez	a0,800054e4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005536:	2184a783          	lw	a5,536(s1)
    8000553a:	21c4a703          	lw	a4,540(s1)
    8000553e:	2007879b          	addw	a5,a5,512
    80005542:	fcf704e3          	beq	a4,a5,8000550a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005546:	4685                	li	a3,1
    80005548:	01590633          	add	a2,s2,s5
    8000554c:	faf40593          	add	a1,s0,-81
    80005550:	0509b503          	ld	a0,80(s3)
    80005554:	ffffc097          	auipc	ra,0xffffc
    80005558:	19e080e7          	jalr	414(ra) # 800016f2 <copyin>
    8000555c:	03650263          	beq	a0,s6,80005580 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005560:	21c4a783          	lw	a5,540(s1)
    80005564:	0017871b          	addw	a4,a5,1
    80005568:	20e4ae23          	sw	a4,540(s1)
    8000556c:	1ff7f793          	and	a5,a5,511
    80005570:	97a6                	add	a5,a5,s1
    80005572:	faf44703          	lbu	a4,-81(s0)
    80005576:	00e78c23          	sb	a4,24(a5)
      i++;
    8000557a:	2905                	addw	s2,s2,1
    8000557c:	b755                	j	80005520 <pipewrite+0x80>
  int i = 0;
    8000557e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005580:	21848513          	add	a0,s1,536
    80005584:	ffffd097          	auipc	ra,0xffffd
    80005588:	2b0080e7          	jalr	688(ra) # 80002834 <wakeup>
  release(&pi->lock);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffb097          	auipc	ra,0xffffb
    80005592:	6f8080e7          	jalr	1784(ra) # 80000c86 <release>
  return i;
    80005596:	bfa9                	j	800054f0 <pipewrite+0x50>

0000000080005598 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005598:	715d                	add	sp,sp,-80
    8000559a:	e486                	sd	ra,72(sp)
    8000559c:	e0a2                	sd	s0,64(sp)
    8000559e:	fc26                	sd	s1,56(sp)
    800055a0:	f84a                	sd	s2,48(sp)
    800055a2:	f44e                	sd	s3,40(sp)
    800055a4:	f052                	sd	s4,32(sp)
    800055a6:	ec56                	sd	s5,24(sp)
    800055a8:	e85a                	sd	s6,16(sp)
    800055aa:	0880                	add	s0,sp,80
    800055ac:	84aa                	mv	s1,a0
    800055ae:	892e                	mv	s2,a1
    800055b0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800055b2:	ffffc097          	auipc	ra,0xffffc
    800055b6:	50c080e7          	jalr	1292(ra) # 80001abe <myproc>
    800055ba:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055bc:	8526                	mv	a0,s1
    800055be:	ffffb097          	auipc	ra,0xffffb
    800055c2:	614080e7          	jalr	1556(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055c6:	2184a703          	lw	a4,536(s1)
    800055ca:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055ce:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055d2:	02f71763          	bne	a4,a5,80005600 <piperead+0x68>
    800055d6:	2244a783          	lw	a5,548(s1)
    800055da:	c39d                	beqz	a5,80005600 <piperead+0x68>
    if(killed(pr)){
    800055dc:	8552                	mv	a0,s4
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	4a6080e7          	jalr	1190(ra) # 80002a84 <killed>
    800055e6:	e949                	bnez	a0,80005678 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055e8:	85a6                	mv	a1,s1
    800055ea:	854e                	mv	a0,s3
    800055ec:	ffffd097          	auipc	ra,0xffffd
    800055f0:	1e4080e7          	jalr	484(ra) # 800027d0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055f4:	2184a703          	lw	a4,536(s1)
    800055f8:	21c4a783          	lw	a5,540(s1)
    800055fc:	fcf70de3          	beq	a4,a5,800055d6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005600:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005602:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005604:	05505463          	blez	s5,8000564c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005608:	2184a783          	lw	a5,536(s1)
    8000560c:	21c4a703          	lw	a4,540(s1)
    80005610:	02f70e63          	beq	a4,a5,8000564c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005614:	0017871b          	addw	a4,a5,1
    80005618:	20e4ac23          	sw	a4,536(s1)
    8000561c:	1ff7f793          	and	a5,a5,511
    80005620:	97a6                	add	a5,a5,s1
    80005622:	0187c783          	lbu	a5,24(a5)
    80005626:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000562a:	4685                	li	a3,1
    8000562c:	fbf40613          	add	a2,s0,-65
    80005630:	85ca                	mv	a1,s2
    80005632:	050a3503          	ld	a0,80(s4)
    80005636:	ffffc097          	auipc	ra,0xffffc
    8000563a:	030080e7          	jalr	48(ra) # 80001666 <copyout>
    8000563e:	01650763          	beq	a0,s6,8000564c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005642:	2985                	addw	s3,s3,1
    80005644:	0905                	add	s2,s2,1
    80005646:	fd3a91e3          	bne	s5,s3,80005608 <piperead+0x70>
    8000564a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000564c:	21c48513          	add	a0,s1,540
    80005650:	ffffd097          	auipc	ra,0xffffd
    80005654:	1e4080e7          	jalr	484(ra) # 80002834 <wakeup>
  release(&pi->lock);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffb097          	auipc	ra,0xffffb
    8000565e:	62c080e7          	jalr	1580(ra) # 80000c86 <release>
  return i;
}
    80005662:	854e                	mv	a0,s3
    80005664:	60a6                	ld	ra,72(sp)
    80005666:	6406                	ld	s0,64(sp)
    80005668:	74e2                	ld	s1,56(sp)
    8000566a:	7942                	ld	s2,48(sp)
    8000566c:	79a2                	ld	s3,40(sp)
    8000566e:	7a02                	ld	s4,32(sp)
    80005670:	6ae2                	ld	s5,24(sp)
    80005672:	6b42                	ld	s6,16(sp)
    80005674:	6161                	add	sp,sp,80
    80005676:	8082                	ret
      release(&pi->lock);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	60c080e7          	jalr	1548(ra) # 80000c86 <release>
      return -1;
    80005682:	59fd                	li	s3,-1
    80005684:	bff9                	j	80005662 <piperead+0xca>

0000000080005686 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005686:	1141                	add	sp,sp,-16
    80005688:	e422                	sd	s0,8(sp)
    8000568a:	0800                	add	s0,sp,16
    8000568c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000568e:	8905                	and	a0,a0,1
    80005690:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005692:	8b89                	and	a5,a5,2
    80005694:	c399                	beqz	a5,8000569a <flags2perm+0x14>
      perm |= PTE_W;
    80005696:	00456513          	or	a0,a0,4
    return perm;
}
    8000569a:	6422                	ld	s0,8(sp)
    8000569c:	0141                	add	sp,sp,16
    8000569e:	8082                	ret

00000000800056a0 <exec>:

int
exec(char *path, char **argv)
{
    800056a0:	df010113          	add	sp,sp,-528
    800056a4:	20113423          	sd	ra,520(sp)
    800056a8:	20813023          	sd	s0,512(sp)
    800056ac:	ffa6                	sd	s1,504(sp)
    800056ae:	fbca                	sd	s2,496(sp)
    800056b0:	f7ce                	sd	s3,488(sp)
    800056b2:	f3d2                	sd	s4,480(sp)
    800056b4:	efd6                	sd	s5,472(sp)
    800056b6:	ebda                	sd	s6,464(sp)
    800056b8:	e7de                	sd	s7,456(sp)
    800056ba:	e3e2                	sd	s8,448(sp)
    800056bc:	ff66                	sd	s9,440(sp)
    800056be:	fb6a                	sd	s10,432(sp)
    800056c0:	f76e                	sd	s11,424(sp)
    800056c2:	0c00                	add	s0,sp,528
    800056c4:	892a                	mv	s2,a0
    800056c6:	dea43c23          	sd	a0,-520(s0)
    800056ca:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800056ce:	ffffc097          	auipc	ra,0xffffc
    800056d2:	3f0080e7          	jalr	1008(ra) # 80001abe <myproc>
    800056d6:	84aa                	mv	s1,a0

  begin_op();
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	48e080e7          	jalr	1166(ra) # 80004b66 <begin_op>

  if((ip = namei(path)) == 0){
    800056e0:	854a                	mv	a0,s2
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	284080e7          	jalr	644(ra) # 80004966 <namei>
    800056ea:	c92d                	beqz	a0,8000575c <exec+0xbc>
    800056ec:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	ad2080e7          	jalr	-1326(ra) # 800041c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056f6:	04000713          	li	a4,64
    800056fa:	4681                	li	a3,0
    800056fc:	e5040613          	add	a2,s0,-432
    80005700:	4581                	li	a1,0
    80005702:	8552                	mv	a0,s4
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	d70080e7          	jalr	-656(ra) # 80004474 <readi>
    8000570c:	04000793          	li	a5,64
    80005710:	00f51a63          	bne	a0,a5,80005724 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005714:	e5042703          	lw	a4,-432(s0)
    80005718:	464c47b7          	lui	a5,0x464c4
    8000571c:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005720:	04f70463          	beq	a4,a5,80005768 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005724:	8552                	mv	a0,s4
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	cfc080e7          	jalr	-772(ra) # 80004422 <iunlockput>
    end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	4b2080e7          	jalr	1202(ra) # 80004be0 <end_op>
  }
  return -1;
    80005736:	557d                	li	a0,-1
}
    80005738:	20813083          	ld	ra,520(sp)
    8000573c:	20013403          	ld	s0,512(sp)
    80005740:	74fe                	ld	s1,504(sp)
    80005742:	795e                	ld	s2,496(sp)
    80005744:	79be                	ld	s3,488(sp)
    80005746:	7a1e                	ld	s4,480(sp)
    80005748:	6afe                	ld	s5,472(sp)
    8000574a:	6b5e                	ld	s6,464(sp)
    8000574c:	6bbe                	ld	s7,456(sp)
    8000574e:	6c1e                	ld	s8,448(sp)
    80005750:	7cfa                	ld	s9,440(sp)
    80005752:	7d5a                	ld	s10,432(sp)
    80005754:	7dba                	ld	s11,424(sp)
    80005756:	21010113          	add	sp,sp,528
    8000575a:	8082                	ret
    end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	484080e7          	jalr	1156(ra) # 80004be0 <end_op>
    return -1;
    80005764:	557d                	li	a0,-1
    80005766:	bfc9                	j	80005738 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffc097          	auipc	ra,0xffffc
    8000576e:	418080e7          	jalr	1048(ra) # 80001b82 <proc_pagetable>
    80005772:	8b2a                	mv	s6,a0
    80005774:	d945                	beqz	a0,80005724 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005776:	e7042d03          	lw	s10,-400(s0)
    8000577a:	e8845783          	lhu	a5,-376(s0)
    8000577e:	10078463          	beqz	a5,80005886 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005782:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005784:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005786:	6c85                	lui	s9,0x1
    80005788:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000578c:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005790:	6a85                	lui	s5,0x1
    80005792:	a0b5                	j	800057fe <exec+0x15e>
      panic("loadseg: address should exist");
    80005794:	00003517          	auipc	a0,0x3
    80005798:	fd450513          	add	a0,a0,-44 # 80008768 <syscalls+0x2c8>
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	da0080e7          	jalr	-608(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800057a4:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800057a6:	8726                	mv	a4,s1
    800057a8:	012c06bb          	addw	a3,s8,s2
    800057ac:	4581                	li	a1,0
    800057ae:	8552                	mv	a0,s4
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	cc4080e7          	jalr	-828(ra) # 80004474 <readi>
    800057b8:	2501                	sext.w	a0,a0
    800057ba:	24a49863          	bne	s1,a0,80005a0a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800057be:	012a893b          	addw	s2,s5,s2
    800057c2:	03397563          	bgeu	s2,s3,800057ec <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800057c6:	02091593          	sll	a1,s2,0x20
    800057ca:	9181                	srl	a1,a1,0x20
    800057cc:	95de                	add	a1,a1,s7
    800057ce:	855a                	mv	a0,s6
    800057d0:	ffffc097          	auipc	ra,0xffffc
    800057d4:	886080e7          	jalr	-1914(ra) # 80001056 <walkaddr>
    800057d8:	862a                	mv	a2,a0
    if(pa == 0)
    800057da:	dd4d                	beqz	a0,80005794 <exec+0xf4>
    if(sz - i < PGSIZE)
    800057dc:	412984bb          	subw	s1,s3,s2
    800057e0:	0004879b          	sext.w	a5,s1
    800057e4:	fcfcf0e3          	bgeu	s9,a5,800057a4 <exec+0x104>
    800057e8:	84d6                	mv	s1,s5
    800057ea:	bf6d                	j	800057a4 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057ec:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057f0:	2d85                	addw	s11,s11,1
    800057f2:	038d0d1b          	addw	s10,s10,56
    800057f6:	e8845783          	lhu	a5,-376(s0)
    800057fa:	08fdd763          	bge	s11,a5,80005888 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057fe:	2d01                	sext.w	s10,s10
    80005800:	03800713          	li	a4,56
    80005804:	86ea                	mv	a3,s10
    80005806:	e1840613          	add	a2,s0,-488
    8000580a:	4581                	li	a1,0
    8000580c:	8552                	mv	a0,s4
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	c66080e7          	jalr	-922(ra) # 80004474 <readi>
    80005816:	03800793          	li	a5,56
    8000581a:	1ef51663          	bne	a0,a5,80005a06 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000581e:	e1842783          	lw	a5,-488(s0)
    80005822:	4705                	li	a4,1
    80005824:	fce796e3          	bne	a5,a4,800057f0 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005828:	e4043483          	ld	s1,-448(s0)
    8000582c:	e3843783          	ld	a5,-456(s0)
    80005830:	1ef4e863          	bltu	s1,a5,80005a20 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005834:	e2843783          	ld	a5,-472(s0)
    80005838:	94be                	add	s1,s1,a5
    8000583a:	1ef4e663          	bltu	s1,a5,80005a26 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000583e:	df043703          	ld	a4,-528(s0)
    80005842:	8ff9                	and	a5,a5,a4
    80005844:	1e079463          	bnez	a5,80005a2c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005848:	e1c42503          	lw	a0,-484(s0)
    8000584c:	00000097          	auipc	ra,0x0
    80005850:	e3a080e7          	jalr	-454(ra) # 80005686 <flags2perm>
    80005854:	86aa                	mv	a3,a0
    80005856:	8626                	mv	a2,s1
    80005858:	85ca                	mv	a1,s2
    8000585a:	855a                	mv	a0,s6
    8000585c:	ffffc097          	auipc	ra,0xffffc
    80005860:	bae080e7          	jalr	-1106(ra) # 8000140a <uvmalloc>
    80005864:	e0a43423          	sd	a0,-504(s0)
    80005868:	1c050563          	beqz	a0,80005a32 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000586c:	e2843b83          	ld	s7,-472(s0)
    80005870:	e2042c03          	lw	s8,-480(s0)
    80005874:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005878:	00098463          	beqz	s3,80005880 <exec+0x1e0>
    8000587c:	4901                	li	s2,0
    8000587e:	b7a1                	j	800057c6 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005880:	e0843903          	ld	s2,-504(s0)
    80005884:	b7b5                	j	800057f0 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005886:	4901                	li	s2,0
  iunlockput(ip);
    80005888:	8552                	mv	a0,s4
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	b98080e7          	jalr	-1128(ra) # 80004422 <iunlockput>
  end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	34e080e7          	jalr	846(ra) # 80004be0 <end_op>
  p = myproc();
    8000589a:	ffffc097          	auipc	ra,0xffffc
    8000589e:	224080e7          	jalr	548(ra) # 80001abe <myproc>
    800058a2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800058a4:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800058a8:	6985                	lui	s3,0x1
    800058aa:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    800058ac:	99ca                	add	s3,s3,s2
    800058ae:	77fd                	lui	a5,0xfffff
    800058b0:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800058b4:	4691                	li	a3,4
    800058b6:	6609                	lui	a2,0x2
    800058b8:	964e                	add	a2,a2,s3
    800058ba:	85ce                	mv	a1,s3
    800058bc:	855a                	mv	a0,s6
    800058be:	ffffc097          	auipc	ra,0xffffc
    800058c2:	b4c080e7          	jalr	-1204(ra) # 8000140a <uvmalloc>
    800058c6:	892a                	mv	s2,a0
    800058c8:	e0a43423          	sd	a0,-504(s0)
    800058cc:	e509                	bnez	a0,800058d6 <exec+0x236>
  if(pagetable)
    800058ce:	e1343423          	sd	s3,-504(s0)
    800058d2:	4a01                	li	s4,0
    800058d4:	aa1d                	j	80005a0a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800058d6:	75f9                	lui	a1,0xffffe
    800058d8:	95aa                	add	a1,a1,a0
    800058da:	855a                	mv	a0,s6
    800058dc:	ffffc097          	auipc	ra,0xffffc
    800058e0:	d58080e7          	jalr	-680(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800058e4:	7bfd                	lui	s7,0xfffff
    800058e6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800058e8:	e0043783          	ld	a5,-512(s0)
    800058ec:	6388                	ld	a0,0(a5)
    800058ee:	c52d                	beqz	a0,80005958 <exec+0x2b8>
    800058f0:	e9040993          	add	s3,s0,-368
    800058f4:	f9040c13          	add	s8,s0,-112
    800058f8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	54e080e7          	jalr	1358(ra) # 80000e48 <strlen>
    80005902:	0015079b          	addw	a5,a0,1
    80005906:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000590a:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    8000590e:	13796563          	bltu	s2,s7,80005a38 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005912:	e0043d03          	ld	s10,-512(s0)
    80005916:	000d3a03          	ld	s4,0(s10)
    8000591a:	8552                	mv	a0,s4
    8000591c:	ffffb097          	auipc	ra,0xffffb
    80005920:	52c080e7          	jalr	1324(ra) # 80000e48 <strlen>
    80005924:	0015069b          	addw	a3,a0,1
    80005928:	8652                	mv	a2,s4
    8000592a:	85ca                	mv	a1,s2
    8000592c:	855a                	mv	a0,s6
    8000592e:	ffffc097          	auipc	ra,0xffffc
    80005932:	d38080e7          	jalr	-712(ra) # 80001666 <copyout>
    80005936:	10054363          	bltz	a0,80005a3c <exec+0x39c>
    ustack[argc] = sp;
    8000593a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000593e:	0485                	add	s1,s1,1
    80005940:	008d0793          	add	a5,s10,8
    80005944:	e0f43023          	sd	a5,-512(s0)
    80005948:	008d3503          	ld	a0,8(s10)
    8000594c:	c909                	beqz	a0,8000595e <exec+0x2be>
    if(argc >= MAXARG)
    8000594e:	09a1                	add	s3,s3,8
    80005950:	fb8995e3          	bne	s3,s8,800058fa <exec+0x25a>
  ip = 0;
    80005954:	4a01                	li	s4,0
    80005956:	a855                	j	80005a0a <exec+0x36a>
  sp = sz;
    80005958:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000595c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000595e:	00349793          	sll	a5,s1,0x3
    80005962:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8fa0>
    80005966:	97a2                	add	a5,a5,s0
    80005968:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000596c:	00148693          	add	a3,s1,1
    80005970:	068e                	sll	a3,a3,0x3
    80005972:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005976:	ff097913          	and	s2,s2,-16
  sz = sz1;
    8000597a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000597e:	f57968e3          	bltu	s2,s7,800058ce <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005982:	e9040613          	add	a2,s0,-368
    80005986:	85ca                	mv	a1,s2
    80005988:	855a                	mv	a0,s6
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	cdc080e7          	jalr	-804(ra) # 80001666 <copyout>
    80005992:	0a054763          	bltz	a0,80005a40 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005996:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000599a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000599e:	df843783          	ld	a5,-520(s0)
    800059a2:	0007c703          	lbu	a4,0(a5)
    800059a6:	cf11                	beqz	a4,800059c2 <exec+0x322>
    800059a8:	0785                	add	a5,a5,1
    if(*s == '/')
    800059aa:	02f00693          	li	a3,47
    800059ae:	a039                	j	800059bc <exec+0x31c>
      last = s+1;
    800059b0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800059b4:	0785                	add	a5,a5,1
    800059b6:	fff7c703          	lbu	a4,-1(a5)
    800059ba:	c701                	beqz	a4,800059c2 <exec+0x322>
    if(*s == '/')
    800059bc:	fed71ce3          	bne	a4,a3,800059b4 <exec+0x314>
    800059c0:	bfc5                	j	800059b0 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800059c2:	4641                	li	a2,16
    800059c4:	df843583          	ld	a1,-520(s0)
    800059c8:	158a8513          	add	a0,s5,344
    800059cc:	ffffb097          	auipc	ra,0xffffb
    800059d0:	44a080e7          	jalr	1098(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800059d4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800059d8:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800059dc:	e0843783          	ld	a5,-504(s0)
    800059e0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800059e4:	058ab783          	ld	a5,88(s5)
    800059e8:	e6843703          	ld	a4,-408(s0)
    800059ec:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800059ee:	058ab783          	ld	a5,88(s5)
    800059f2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059f6:	85e6                	mv	a1,s9
    800059f8:	ffffc097          	auipc	ra,0xffffc
    800059fc:	226080e7          	jalr	550(ra) # 80001c1e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a00:	0004851b          	sext.w	a0,s1
    80005a04:	bb15                	j	80005738 <exec+0x98>
    80005a06:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a0a:	e0843583          	ld	a1,-504(s0)
    80005a0e:	855a                	mv	a0,s6
    80005a10:	ffffc097          	auipc	ra,0xffffc
    80005a14:	20e080e7          	jalr	526(ra) # 80001c1e <proc_freepagetable>
  return -1;
    80005a18:	557d                	li	a0,-1
  if(ip){
    80005a1a:	d00a0fe3          	beqz	s4,80005738 <exec+0x98>
    80005a1e:	b319                	j	80005724 <exec+0x84>
    80005a20:	e1243423          	sd	s2,-504(s0)
    80005a24:	b7dd                	j	80005a0a <exec+0x36a>
    80005a26:	e1243423          	sd	s2,-504(s0)
    80005a2a:	b7c5                	j	80005a0a <exec+0x36a>
    80005a2c:	e1243423          	sd	s2,-504(s0)
    80005a30:	bfe9                	j	80005a0a <exec+0x36a>
    80005a32:	e1243423          	sd	s2,-504(s0)
    80005a36:	bfd1                	j	80005a0a <exec+0x36a>
  ip = 0;
    80005a38:	4a01                	li	s4,0
    80005a3a:	bfc1                	j	80005a0a <exec+0x36a>
    80005a3c:	4a01                	li	s4,0
  if(pagetable)
    80005a3e:	b7f1                	j	80005a0a <exec+0x36a>
  sz = sz1;
    80005a40:	e0843983          	ld	s3,-504(s0)
    80005a44:	b569                	j	800058ce <exec+0x22e>

0000000080005a46 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a46:	7179                	add	sp,sp,-48
    80005a48:	f406                	sd	ra,40(sp)
    80005a4a:	f022                	sd	s0,32(sp)
    80005a4c:	ec26                	sd	s1,24(sp)
    80005a4e:	e84a                	sd	s2,16(sp)
    80005a50:	1800                	add	s0,sp,48
    80005a52:	892e                	mv	s2,a1
    80005a54:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005a56:	fdc40593          	add	a1,s0,-36
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	a16080e7          	jalr	-1514(ra) # 80003470 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a62:	fdc42703          	lw	a4,-36(s0)
    80005a66:	47bd                	li	a5,15
    80005a68:	02e7eb63          	bltu	a5,a4,80005a9e <argfd+0x58>
    80005a6c:	ffffc097          	auipc	ra,0xffffc
    80005a70:	052080e7          	jalr	82(ra) # 80001abe <myproc>
    80005a74:	fdc42703          	lw	a4,-36(s0)
    80005a78:	01a70793          	add	a5,a4,26
    80005a7c:	078e                	sll	a5,a5,0x3
    80005a7e:	953e                	add	a0,a0,a5
    80005a80:	611c                	ld	a5,0(a0)
    80005a82:	c385                	beqz	a5,80005aa2 <argfd+0x5c>
    return -1;
  if(pfd)
    80005a84:	00090463          	beqz	s2,80005a8c <argfd+0x46>
    *pfd = fd;
    80005a88:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a8c:	4501                	li	a0,0
  if(pf)
    80005a8e:	c091                	beqz	s1,80005a92 <argfd+0x4c>
    *pf = f;
    80005a90:	e09c                	sd	a5,0(s1)
}
    80005a92:	70a2                	ld	ra,40(sp)
    80005a94:	7402                	ld	s0,32(sp)
    80005a96:	64e2                	ld	s1,24(sp)
    80005a98:	6942                	ld	s2,16(sp)
    80005a9a:	6145                	add	sp,sp,48
    80005a9c:	8082                	ret
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	bfcd                	j	80005a92 <argfd+0x4c>
    80005aa2:	557d                	li	a0,-1
    80005aa4:	b7fd                	j	80005a92 <argfd+0x4c>

0000000080005aa6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005aa6:	1101                	add	sp,sp,-32
    80005aa8:	ec06                	sd	ra,24(sp)
    80005aaa:	e822                	sd	s0,16(sp)
    80005aac:	e426                	sd	s1,8(sp)
    80005aae:	1000                	add	s0,sp,32
    80005ab0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ab2:	ffffc097          	auipc	ra,0xffffc
    80005ab6:	00c080e7          	jalr	12(ra) # 80001abe <myproc>
    80005aba:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005abc:	0d050793          	add	a5,a0,208
    80005ac0:	4501                	li	a0,0
    80005ac2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ac4:	6398                	ld	a4,0(a5)
    80005ac6:	cb19                	beqz	a4,80005adc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ac8:	2505                	addw	a0,a0,1
    80005aca:	07a1                	add	a5,a5,8
    80005acc:	fed51ce3          	bne	a0,a3,80005ac4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ad0:	557d                	li	a0,-1
}
    80005ad2:	60e2                	ld	ra,24(sp)
    80005ad4:	6442                	ld	s0,16(sp)
    80005ad6:	64a2                	ld	s1,8(sp)
    80005ad8:	6105                	add	sp,sp,32
    80005ada:	8082                	ret
      p->ofile[fd] = f;
    80005adc:	01a50793          	add	a5,a0,26
    80005ae0:	078e                	sll	a5,a5,0x3
    80005ae2:	963e                	add	a2,a2,a5
    80005ae4:	e204                	sd	s1,0(a2)
      return fd;
    80005ae6:	b7f5                	j	80005ad2 <fdalloc+0x2c>

0000000080005ae8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ae8:	715d                	add	sp,sp,-80
    80005aea:	e486                	sd	ra,72(sp)
    80005aec:	e0a2                	sd	s0,64(sp)
    80005aee:	fc26                	sd	s1,56(sp)
    80005af0:	f84a                	sd	s2,48(sp)
    80005af2:	f44e                	sd	s3,40(sp)
    80005af4:	f052                	sd	s4,32(sp)
    80005af6:	ec56                	sd	s5,24(sp)
    80005af8:	e85a                	sd	s6,16(sp)
    80005afa:	0880                	add	s0,sp,80
    80005afc:	8b2e                	mv	s6,a1
    80005afe:	89b2                	mv	s3,a2
    80005b00:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005b02:	fb040593          	add	a1,s0,-80
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	e7e080e7          	jalr	-386(ra) # 80004984 <nameiparent>
    80005b0e:	84aa                	mv	s1,a0
    80005b10:	14050b63          	beqz	a0,80005c66 <create+0x17e>
    return 0;

  ilock(dp);
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	6ac080e7          	jalr	1708(ra) # 800041c0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005b1c:	4601                	li	a2,0
    80005b1e:	fb040593          	add	a1,s0,-80
    80005b22:	8526                	mv	a0,s1
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	b80080e7          	jalr	-1152(ra) # 800046a4 <dirlookup>
    80005b2c:	8aaa                	mv	s5,a0
    80005b2e:	c921                	beqz	a0,80005b7e <create+0x96>
    iunlockput(dp);
    80005b30:	8526                	mv	a0,s1
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	8f0080e7          	jalr	-1808(ra) # 80004422 <iunlockput>
    ilock(ip);
    80005b3a:	8556                	mv	a0,s5
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	684080e7          	jalr	1668(ra) # 800041c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005b44:	4789                	li	a5,2
    80005b46:	02fb1563          	bne	s6,a5,80005b70 <create+0x88>
    80005b4a:	044ad783          	lhu	a5,68(s5)
    80005b4e:	37f9                	addw	a5,a5,-2
    80005b50:	17c2                	sll	a5,a5,0x30
    80005b52:	93c1                	srl	a5,a5,0x30
    80005b54:	4705                	li	a4,1
    80005b56:	00f76d63          	bltu	a4,a5,80005b70 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005b5a:	8556                	mv	a0,s5
    80005b5c:	60a6                	ld	ra,72(sp)
    80005b5e:	6406                	ld	s0,64(sp)
    80005b60:	74e2                	ld	s1,56(sp)
    80005b62:	7942                	ld	s2,48(sp)
    80005b64:	79a2                	ld	s3,40(sp)
    80005b66:	7a02                	ld	s4,32(sp)
    80005b68:	6ae2                	ld	s5,24(sp)
    80005b6a:	6b42                	ld	s6,16(sp)
    80005b6c:	6161                	add	sp,sp,80
    80005b6e:	8082                	ret
    iunlockput(ip);
    80005b70:	8556                	mv	a0,s5
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	8b0080e7          	jalr	-1872(ra) # 80004422 <iunlockput>
    return 0;
    80005b7a:	4a81                	li	s5,0
    80005b7c:	bff9                	j	80005b5a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005b7e:	85da                	mv	a1,s6
    80005b80:	4088                	lw	a0,0(s1)
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	4a6080e7          	jalr	1190(ra) # 80004028 <ialloc>
    80005b8a:	8a2a                	mv	s4,a0
    80005b8c:	c529                	beqz	a0,80005bd6 <create+0xee>
  ilock(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	632080e7          	jalr	1586(ra) # 800041c0 <ilock>
  ip->major = major;
    80005b96:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005b9a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005b9e:	4905                	li	s2,1
    80005ba0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005ba4:	8552                	mv	a0,s4
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	54e080e7          	jalr	1358(ra) # 800040f4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005bae:	032b0b63          	beq	s6,s2,80005be4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005bb2:	004a2603          	lw	a2,4(s4)
    80005bb6:	fb040593          	add	a1,s0,-80
    80005bba:	8526                	mv	a0,s1
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	cf8080e7          	jalr	-776(ra) # 800048b4 <dirlink>
    80005bc4:	06054f63          	bltz	a0,80005c42 <create+0x15a>
  iunlockput(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	858080e7          	jalr	-1960(ra) # 80004422 <iunlockput>
  return ip;
    80005bd2:	8ad2                	mv	s5,s4
    80005bd4:	b759                	j	80005b5a <create+0x72>
    iunlockput(dp);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	84a080e7          	jalr	-1974(ra) # 80004422 <iunlockput>
    return 0;
    80005be0:	8ad2                	mv	s5,s4
    80005be2:	bfa5                	j	80005b5a <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005be4:	004a2603          	lw	a2,4(s4)
    80005be8:	00003597          	auipc	a1,0x3
    80005bec:	ba058593          	add	a1,a1,-1120 # 80008788 <syscalls+0x2e8>
    80005bf0:	8552                	mv	a0,s4
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	cc2080e7          	jalr	-830(ra) # 800048b4 <dirlink>
    80005bfa:	04054463          	bltz	a0,80005c42 <create+0x15a>
    80005bfe:	40d0                	lw	a2,4(s1)
    80005c00:	00003597          	auipc	a1,0x3
    80005c04:	b9058593          	add	a1,a1,-1136 # 80008790 <syscalls+0x2f0>
    80005c08:	8552                	mv	a0,s4
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	caa080e7          	jalr	-854(ra) # 800048b4 <dirlink>
    80005c12:	02054863          	bltz	a0,80005c42 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c16:	004a2603          	lw	a2,4(s4)
    80005c1a:	fb040593          	add	a1,s0,-80
    80005c1e:	8526                	mv	a0,s1
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	c94080e7          	jalr	-876(ra) # 800048b4 <dirlink>
    80005c28:	00054d63          	bltz	a0,80005c42 <create+0x15a>
    dp->nlink++;  // for ".."
    80005c2c:	04a4d783          	lhu	a5,74(s1)
    80005c30:	2785                	addw	a5,a5,1
    80005c32:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c36:	8526                	mv	a0,s1
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	4bc080e7          	jalr	1212(ra) # 800040f4 <iupdate>
    80005c40:	b761                	j	80005bc8 <create+0xe0>
  ip->nlink = 0;
    80005c42:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005c46:	8552                	mv	a0,s4
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	4ac080e7          	jalr	1196(ra) # 800040f4 <iupdate>
  iunlockput(ip);
    80005c50:	8552                	mv	a0,s4
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	7d0080e7          	jalr	2000(ra) # 80004422 <iunlockput>
  iunlockput(dp);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	7c6080e7          	jalr	1990(ra) # 80004422 <iunlockput>
  return 0;
    80005c64:	bddd                	j	80005b5a <create+0x72>
    return 0;
    80005c66:	8aaa                	mv	s5,a0
    80005c68:	bdcd                	j	80005b5a <create+0x72>

0000000080005c6a <sys_dup>:
{
    80005c6a:	7179                	add	sp,sp,-48
    80005c6c:	f406                	sd	ra,40(sp)
    80005c6e:	f022                	sd	s0,32(sp)
    80005c70:	ec26                	sd	s1,24(sp)
    80005c72:	e84a                	sd	s2,16(sp)
    80005c74:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c76:	fd840613          	add	a2,s0,-40
    80005c7a:	4581                	li	a1,0
    80005c7c:	4501                	li	a0,0
    80005c7e:	00000097          	auipc	ra,0x0
    80005c82:	dc8080e7          	jalr	-568(ra) # 80005a46 <argfd>
    return -1;
    80005c86:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c88:	02054363          	bltz	a0,80005cae <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005c8c:	fd843903          	ld	s2,-40(s0)
    80005c90:	854a                	mv	a0,s2
    80005c92:	00000097          	auipc	ra,0x0
    80005c96:	e14080e7          	jalr	-492(ra) # 80005aa6 <fdalloc>
    80005c9a:	84aa                	mv	s1,a0
    return -1;
    80005c9c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c9e:	00054863          	bltz	a0,80005cae <sys_dup+0x44>
  filedup(f);
    80005ca2:	854a                	mv	a0,s2
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	334080e7          	jalr	820(ra) # 80004fd8 <filedup>
  return fd;
    80005cac:	87a6                	mv	a5,s1
}
    80005cae:	853e                	mv	a0,a5
    80005cb0:	70a2                	ld	ra,40(sp)
    80005cb2:	7402                	ld	s0,32(sp)
    80005cb4:	64e2                	ld	s1,24(sp)
    80005cb6:	6942                	ld	s2,16(sp)
    80005cb8:	6145                	add	sp,sp,48
    80005cba:	8082                	ret

0000000080005cbc <sys_read>:
{
    80005cbc:	7179                	add	sp,sp,-48
    80005cbe:	f406                	sd	ra,40(sp)
    80005cc0:	f022                	sd	s0,32(sp)
    80005cc2:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005cc4:	fd840593          	add	a1,s0,-40
    80005cc8:	4505                	li	a0,1
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	7c6080e7          	jalr	1990(ra) # 80003490 <argaddr>
  argint(2, &n);
    80005cd2:	fe440593          	add	a1,s0,-28
    80005cd6:	4509                	li	a0,2
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	798080e7          	jalr	1944(ra) # 80003470 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ce0:	fe840613          	add	a2,s0,-24
    80005ce4:	4581                	li	a1,0
    80005ce6:	4501                	li	a0,0
    80005ce8:	00000097          	auipc	ra,0x0
    80005cec:	d5e080e7          	jalr	-674(ra) # 80005a46 <argfd>
    80005cf0:	87aa                	mv	a5,a0
    return -1;
    80005cf2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cf4:	0007cc63          	bltz	a5,80005d0c <sys_read+0x50>
  return fileread(f, p, n);
    80005cf8:	fe442603          	lw	a2,-28(s0)
    80005cfc:	fd843583          	ld	a1,-40(s0)
    80005d00:	fe843503          	ld	a0,-24(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	460080e7          	jalr	1120(ra) # 80005164 <fileread>
}
    80005d0c:	70a2                	ld	ra,40(sp)
    80005d0e:	7402                	ld	s0,32(sp)
    80005d10:	6145                	add	sp,sp,48
    80005d12:	8082                	ret

0000000080005d14 <sys_write>:
{
    80005d14:	7179                	add	sp,sp,-48
    80005d16:	f406                	sd	ra,40(sp)
    80005d18:	f022                	sd	s0,32(sp)
    80005d1a:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005d1c:	fd840593          	add	a1,s0,-40
    80005d20:	4505                	li	a0,1
    80005d22:	ffffd097          	auipc	ra,0xffffd
    80005d26:	76e080e7          	jalr	1902(ra) # 80003490 <argaddr>
  argint(2, &n);
    80005d2a:	fe440593          	add	a1,s0,-28
    80005d2e:	4509                	li	a0,2
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	740080e7          	jalr	1856(ra) # 80003470 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d38:	fe840613          	add	a2,s0,-24
    80005d3c:	4581                	li	a1,0
    80005d3e:	4501                	li	a0,0
    80005d40:	00000097          	auipc	ra,0x0
    80005d44:	d06080e7          	jalr	-762(ra) # 80005a46 <argfd>
    80005d48:	87aa                	mv	a5,a0
    return -1;
    80005d4a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d4c:	0007cc63          	bltz	a5,80005d64 <sys_write+0x50>
  return filewrite(f, p, n);
    80005d50:	fe442603          	lw	a2,-28(s0)
    80005d54:	fd843583          	ld	a1,-40(s0)
    80005d58:	fe843503          	ld	a0,-24(s0)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	4ca080e7          	jalr	1226(ra) # 80005226 <filewrite>
}
    80005d64:	70a2                	ld	ra,40(sp)
    80005d66:	7402                	ld	s0,32(sp)
    80005d68:	6145                	add	sp,sp,48
    80005d6a:	8082                	ret

0000000080005d6c <sys_close>:
{
    80005d6c:	1101                	add	sp,sp,-32
    80005d6e:	ec06                	sd	ra,24(sp)
    80005d70:	e822                	sd	s0,16(sp)
    80005d72:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d74:	fe040613          	add	a2,s0,-32
    80005d78:	fec40593          	add	a1,s0,-20
    80005d7c:	4501                	li	a0,0
    80005d7e:	00000097          	auipc	ra,0x0
    80005d82:	cc8080e7          	jalr	-824(ra) # 80005a46 <argfd>
    return -1;
    80005d86:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d88:	02054463          	bltz	a0,80005db0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d8c:	ffffc097          	auipc	ra,0xffffc
    80005d90:	d32080e7          	jalr	-718(ra) # 80001abe <myproc>
    80005d94:	fec42783          	lw	a5,-20(s0)
    80005d98:	07e9                	add	a5,a5,26
    80005d9a:	078e                	sll	a5,a5,0x3
    80005d9c:	953e                	add	a0,a0,a5
    80005d9e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005da2:	fe043503          	ld	a0,-32(s0)
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	284080e7          	jalr	644(ra) # 8000502a <fileclose>
  return 0;
    80005dae:	4781                	li	a5,0
}
    80005db0:	853e                	mv	a0,a5
    80005db2:	60e2                	ld	ra,24(sp)
    80005db4:	6442                	ld	s0,16(sp)
    80005db6:	6105                	add	sp,sp,32
    80005db8:	8082                	ret

0000000080005dba <sys_fstat>:
{
    80005dba:	1101                	add	sp,sp,-32
    80005dbc:	ec06                	sd	ra,24(sp)
    80005dbe:	e822                	sd	s0,16(sp)
    80005dc0:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005dc2:	fe040593          	add	a1,s0,-32
    80005dc6:	4505                	li	a0,1
    80005dc8:	ffffd097          	auipc	ra,0xffffd
    80005dcc:	6c8080e7          	jalr	1736(ra) # 80003490 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005dd0:	fe840613          	add	a2,s0,-24
    80005dd4:	4581                	li	a1,0
    80005dd6:	4501                	li	a0,0
    80005dd8:	00000097          	auipc	ra,0x0
    80005ddc:	c6e080e7          	jalr	-914(ra) # 80005a46 <argfd>
    80005de0:	87aa                	mv	a5,a0
    return -1;
    80005de2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005de4:	0007ca63          	bltz	a5,80005df8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005de8:	fe043583          	ld	a1,-32(s0)
    80005dec:	fe843503          	ld	a0,-24(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	302080e7          	jalr	770(ra) # 800050f2 <filestat>
}
    80005df8:	60e2                	ld	ra,24(sp)
    80005dfa:	6442                	ld	s0,16(sp)
    80005dfc:	6105                	add	sp,sp,32
    80005dfe:	8082                	ret

0000000080005e00 <sys_link>:
{
    80005e00:	7169                	add	sp,sp,-304
    80005e02:	f606                	sd	ra,296(sp)
    80005e04:	f222                	sd	s0,288(sp)
    80005e06:	ee26                	sd	s1,280(sp)
    80005e08:	ea4a                	sd	s2,272(sp)
    80005e0a:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e0c:	08000613          	li	a2,128
    80005e10:	ed040593          	add	a1,s0,-304
    80005e14:	4501                	li	a0,0
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	69a080e7          	jalr	1690(ra) # 800034b0 <argstr>
    return -1;
    80005e1e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e20:	10054e63          	bltz	a0,80005f3c <sys_link+0x13c>
    80005e24:	08000613          	li	a2,128
    80005e28:	f5040593          	add	a1,s0,-176
    80005e2c:	4505                	li	a0,1
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	682080e7          	jalr	1666(ra) # 800034b0 <argstr>
    return -1;
    80005e36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e38:	10054263          	bltz	a0,80005f3c <sys_link+0x13c>
  begin_op();
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	d2a080e7          	jalr	-726(ra) # 80004b66 <begin_op>
  if((ip = namei(old)) == 0){
    80005e44:	ed040513          	add	a0,s0,-304
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	b1e080e7          	jalr	-1250(ra) # 80004966 <namei>
    80005e50:	84aa                	mv	s1,a0
    80005e52:	c551                	beqz	a0,80005ede <sys_link+0xde>
  ilock(ip);
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	36c080e7          	jalr	876(ra) # 800041c0 <ilock>
  if(ip->type == T_DIR){
    80005e5c:	04449703          	lh	a4,68(s1)
    80005e60:	4785                	li	a5,1
    80005e62:	08f70463          	beq	a4,a5,80005eea <sys_link+0xea>
  ip->nlink++;
    80005e66:	04a4d783          	lhu	a5,74(s1)
    80005e6a:	2785                	addw	a5,a5,1
    80005e6c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e70:	8526                	mv	a0,s1
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	282080e7          	jalr	642(ra) # 800040f4 <iupdate>
  iunlock(ip);
    80005e7a:	8526                	mv	a0,s1
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	406080e7          	jalr	1030(ra) # 80004282 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e84:	fd040593          	add	a1,s0,-48
    80005e88:	f5040513          	add	a0,s0,-176
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	af8080e7          	jalr	-1288(ra) # 80004984 <nameiparent>
    80005e94:	892a                	mv	s2,a0
    80005e96:	c935                	beqz	a0,80005f0a <sys_link+0x10a>
  ilock(dp);
    80005e98:	ffffe097          	auipc	ra,0xffffe
    80005e9c:	328080e7          	jalr	808(ra) # 800041c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ea0:	00092703          	lw	a4,0(s2)
    80005ea4:	409c                	lw	a5,0(s1)
    80005ea6:	04f71d63          	bne	a4,a5,80005f00 <sys_link+0x100>
    80005eaa:	40d0                	lw	a2,4(s1)
    80005eac:	fd040593          	add	a1,s0,-48
    80005eb0:	854a                	mv	a0,s2
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	a02080e7          	jalr	-1534(ra) # 800048b4 <dirlink>
    80005eba:	04054363          	bltz	a0,80005f00 <sys_link+0x100>
  iunlockput(dp);
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	562080e7          	jalr	1378(ra) # 80004422 <iunlockput>
  iput(ip);
    80005ec8:	8526                	mv	a0,s1
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	4b0080e7          	jalr	1200(ra) # 8000437a <iput>
  end_op();
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	d0e080e7          	jalr	-754(ra) # 80004be0 <end_op>
  return 0;
    80005eda:	4781                	li	a5,0
    80005edc:	a085                	j	80005f3c <sys_link+0x13c>
    end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	d02080e7          	jalr	-766(ra) # 80004be0 <end_op>
    return -1;
    80005ee6:	57fd                	li	a5,-1
    80005ee8:	a891                	j	80005f3c <sys_link+0x13c>
    iunlockput(ip);
    80005eea:	8526                	mv	a0,s1
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	536080e7          	jalr	1334(ra) # 80004422 <iunlockput>
    end_op();
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	cec080e7          	jalr	-788(ra) # 80004be0 <end_op>
    return -1;
    80005efc:	57fd                	li	a5,-1
    80005efe:	a83d                	j	80005f3c <sys_link+0x13c>
    iunlockput(dp);
    80005f00:	854a                	mv	a0,s2
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	520080e7          	jalr	1312(ra) # 80004422 <iunlockput>
  ilock(ip);
    80005f0a:	8526                	mv	a0,s1
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	2b4080e7          	jalr	692(ra) # 800041c0 <ilock>
  ip->nlink--;
    80005f14:	04a4d783          	lhu	a5,74(s1)
    80005f18:	37fd                	addw	a5,a5,-1
    80005f1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f1e:	8526                	mv	a0,s1
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	1d4080e7          	jalr	468(ra) # 800040f4 <iupdate>
  iunlockput(ip);
    80005f28:	8526                	mv	a0,s1
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	4f8080e7          	jalr	1272(ra) # 80004422 <iunlockput>
  end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	cae080e7          	jalr	-850(ra) # 80004be0 <end_op>
  return -1;
    80005f3a:	57fd                	li	a5,-1
}
    80005f3c:	853e                	mv	a0,a5
    80005f3e:	70b2                	ld	ra,296(sp)
    80005f40:	7412                	ld	s0,288(sp)
    80005f42:	64f2                	ld	s1,280(sp)
    80005f44:	6952                	ld	s2,272(sp)
    80005f46:	6155                	add	sp,sp,304
    80005f48:	8082                	ret

0000000080005f4a <sys_unlink>:
{
    80005f4a:	7151                	add	sp,sp,-240
    80005f4c:	f586                	sd	ra,232(sp)
    80005f4e:	f1a2                	sd	s0,224(sp)
    80005f50:	eda6                	sd	s1,216(sp)
    80005f52:	e9ca                	sd	s2,208(sp)
    80005f54:	e5ce                	sd	s3,200(sp)
    80005f56:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005f58:	08000613          	li	a2,128
    80005f5c:	f3040593          	add	a1,s0,-208
    80005f60:	4501                	li	a0,0
    80005f62:	ffffd097          	auipc	ra,0xffffd
    80005f66:	54e080e7          	jalr	1358(ra) # 800034b0 <argstr>
    80005f6a:	18054163          	bltz	a0,800060ec <sys_unlink+0x1a2>
  begin_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	bf8080e7          	jalr	-1032(ra) # 80004b66 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f76:	fb040593          	add	a1,s0,-80
    80005f7a:	f3040513          	add	a0,s0,-208
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	a06080e7          	jalr	-1530(ra) # 80004984 <nameiparent>
    80005f86:	84aa                	mv	s1,a0
    80005f88:	c979                	beqz	a0,8000605e <sys_unlink+0x114>
  ilock(dp);
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	236080e7          	jalr	566(ra) # 800041c0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f92:	00002597          	auipc	a1,0x2
    80005f96:	7f658593          	add	a1,a1,2038 # 80008788 <syscalls+0x2e8>
    80005f9a:	fb040513          	add	a0,s0,-80
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	6ec080e7          	jalr	1772(ra) # 8000468a <namecmp>
    80005fa6:	14050a63          	beqz	a0,800060fa <sys_unlink+0x1b0>
    80005faa:	00002597          	auipc	a1,0x2
    80005fae:	7e658593          	add	a1,a1,2022 # 80008790 <syscalls+0x2f0>
    80005fb2:	fb040513          	add	a0,s0,-80
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	6d4080e7          	jalr	1748(ra) # 8000468a <namecmp>
    80005fbe:	12050e63          	beqz	a0,800060fa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005fc2:	f2c40613          	add	a2,s0,-212
    80005fc6:	fb040593          	add	a1,s0,-80
    80005fca:	8526                	mv	a0,s1
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	6d8080e7          	jalr	1752(ra) # 800046a4 <dirlookup>
    80005fd4:	892a                	mv	s2,a0
    80005fd6:	12050263          	beqz	a0,800060fa <sys_unlink+0x1b0>
  ilock(ip);
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	1e6080e7          	jalr	486(ra) # 800041c0 <ilock>
  if(ip->nlink < 1)
    80005fe2:	04a91783          	lh	a5,74(s2)
    80005fe6:	08f05263          	blez	a5,8000606a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005fea:	04491703          	lh	a4,68(s2)
    80005fee:	4785                	li	a5,1
    80005ff0:	08f70563          	beq	a4,a5,8000607a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ff4:	4641                	li	a2,16
    80005ff6:	4581                	li	a1,0
    80005ff8:	fc040513          	add	a0,s0,-64
    80005ffc:	ffffb097          	auipc	ra,0xffffb
    80006000:	cd2080e7          	jalr	-814(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006004:	4741                	li	a4,16
    80006006:	f2c42683          	lw	a3,-212(s0)
    8000600a:	fc040613          	add	a2,s0,-64
    8000600e:	4581                	li	a1,0
    80006010:	8526                	mv	a0,s1
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	55a080e7          	jalr	1370(ra) # 8000456c <writei>
    8000601a:	47c1                	li	a5,16
    8000601c:	0af51563          	bne	a0,a5,800060c6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006020:	04491703          	lh	a4,68(s2)
    80006024:	4785                	li	a5,1
    80006026:	0af70863          	beq	a4,a5,800060d6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	3f6080e7          	jalr	1014(ra) # 80004422 <iunlockput>
  ip->nlink--;
    80006034:	04a95783          	lhu	a5,74(s2)
    80006038:	37fd                	addw	a5,a5,-1
    8000603a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000603e:	854a                	mv	a0,s2
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	0b4080e7          	jalr	180(ra) # 800040f4 <iupdate>
  iunlockput(ip);
    80006048:	854a                	mv	a0,s2
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	3d8080e7          	jalr	984(ra) # 80004422 <iunlockput>
  end_op();
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	b8e080e7          	jalr	-1138(ra) # 80004be0 <end_op>
  return 0;
    8000605a:	4501                	li	a0,0
    8000605c:	a84d                	j	8000610e <sys_unlink+0x1c4>
    end_op();
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	b82080e7          	jalr	-1150(ra) # 80004be0 <end_op>
    return -1;
    80006066:	557d                	li	a0,-1
    80006068:	a05d                	j	8000610e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000606a:	00002517          	auipc	a0,0x2
    8000606e:	72e50513          	add	a0,a0,1838 # 80008798 <syscalls+0x2f8>
    80006072:	ffffa097          	auipc	ra,0xffffa
    80006076:	4ca080e7          	jalr	1226(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000607a:	04c92703          	lw	a4,76(s2)
    8000607e:	02000793          	li	a5,32
    80006082:	f6e7f9e3          	bgeu	a5,a4,80005ff4 <sys_unlink+0xaa>
    80006086:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000608a:	4741                	li	a4,16
    8000608c:	86ce                	mv	a3,s3
    8000608e:	f1840613          	add	a2,s0,-232
    80006092:	4581                	li	a1,0
    80006094:	854a                	mv	a0,s2
    80006096:	ffffe097          	auipc	ra,0xffffe
    8000609a:	3de080e7          	jalr	990(ra) # 80004474 <readi>
    8000609e:	47c1                	li	a5,16
    800060a0:	00f51b63          	bne	a0,a5,800060b6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800060a4:	f1845783          	lhu	a5,-232(s0)
    800060a8:	e7a1                	bnez	a5,800060f0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060aa:	29c1                	addw	s3,s3,16
    800060ac:	04c92783          	lw	a5,76(s2)
    800060b0:	fcf9ede3          	bltu	s3,a5,8000608a <sys_unlink+0x140>
    800060b4:	b781                	j	80005ff4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	6fa50513          	add	a0,a0,1786 # 800087b0 <syscalls+0x310>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	47e080e7          	jalr	1150(ra) # 8000053c <panic>
    panic("unlink: writei");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	70250513          	add	a0,a0,1794 # 800087c8 <syscalls+0x328>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	46e080e7          	jalr	1134(ra) # 8000053c <panic>
    dp->nlink--;
    800060d6:	04a4d783          	lhu	a5,74(s1)
    800060da:	37fd                	addw	a5,a5,-1
    800060dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800060e0:	8526                	mv	a0,s1
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	012080e7          	jalr	18(ra) # 800040f4 <iupdate>
    800060ea:	b781                	j	8000602a <sys_unlink+0xe0>
    return -1;
    800060ec:	557d                	li	a0,-1
    800060ee:	a005                	j	8000610e <sys_unlink+0x1c4>
    iunlockput(ip);
    800060f0:	854a                	mv	a0,s2
    800060f2:	ffffe097          	auipc	ra,0xffffe
    800060f6:	330080e7          	jalr	816(ra) # 80004422 <iunlockput>
  iunlockput(dp);
    800060fa:	8526                	mv	a0,s1
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	326080e7          	jalr	806(ra) # 80004422 <iunlockput>
  end_op();
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	adc080e7          	jalr	-1316(ra) # 80004be0 <end_op>
  return -1;
    8000610c:	557d                	li	a0,-1
}
    8000610e:	70ae                	ld	ra,232(sp)
    80006110:	740e                	ld	s0,224(sp)
    80006112:	64ee                	ld	s1,216(sp)
    80006114:	694e                	ld	s2,208(sp)
    80006116:	69ae                	ld	s3,200(sp)
    80006118:	616d                	add	sp,sp,240
    8000611a:	8082                	ret

000000008000611c <sys_open>:

uint64
sys_open(void)
{
    8000611c:	7131                	add	sp,sp,-192
    8000611e:	fd06                	sd	ra,184(sp)
    80006120:	f922                	sd	s0,176(sp)
    80006122:	f526                	sd	s1,168(sp)
    80006124:	f14a                	sd	s2,160(sp)
    80006126:	ed4e                	sd	s3,152(sp)
    80006128:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000612a:	f4c40593          	add	a1,s0,-180
    8000612e:	4505                	li	a0,1
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	340080e7          	jalr	832(ra) # 80003470 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006138:	08000613          	li	a2,128
    8000613c:	f5040593          	add	a1,s0,-176
    80006140:	4501                	li	a0,0
    80006142:	ffffd097          	auipc	ra,0xffffd
    80006146:	36e080e7          	jalr	878(ra) # 800034b0 <argstr>
    8000614a:	87aa                	mv	a5,a0
    return -1;
    8000614c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000614e:	0a07c863          	bltz	a5,800061fe <sys_open+0xe2>

  begin_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	a14080e7          	jalr	-1516(ra) # 80004b66 <begin_op>

  if(omode & O_CREATE){
    8000615a:	f4c42783          	lw	a5,-180(s0)
    8000615e:	2007f793          	and	a5,a5,512
    80006162:	cbdd                	beqz	a5,80006218 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80006164:	4681                	li	a3,0
    80006166:	4601                	li	a2,0
    80006168:	4589                	li	a1,2
    8000616a:	f5040513          	add	a0,s0,-176
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	97a080e7          	jalr	-1670(ra) # 80005ae8 <create>
    80006176:	84aa                	mv	s1,a0
    if(ip == 0){
    80006178:	c951                	beqz	a0,8000620c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000617a:	04449703          	lh	a4,68(s1)
    8000617e:	478d                	li	a5,3
    80006180:	00f71763          	bne	a4,a5,8000618e <sys_open+0x72>
    80006184:	0464d703          	lhu	a4,70(s1)
    80006188:	47a5                	li	a5,9
    8000618a:	0ce7ec63          	bltu	a5,a4,80006262 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	de0080e7          	jalr	-544(ra) # 80004f6e <filealloc>
    80006196:	892a                	mv	s2,a0
    80006198:	c56d                	beqz	a0,80006282 <sys_open+0x166>
    8000619a:	00000097          	auipc	ra,0x0
    8000619e:	90c080e7          	jalr	-1780(ra) # 80005aa6 <fdalloc>
    800061a2:	89aa                	mv	s3,a0
    800061a4:	0c054a63          	bltz	a0,80006278 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800061a8:	04449703          	lh	a4,68(s1)
    800061ac:	478d                	li	a5,3
    800061ae:	0ef70563          	beq	a4,a5,80006298 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800061b2:	4789                	li	a5,2
    800061b4:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800061b8:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800061bc:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800061c0:	f4c42783          	lw	a5,-180(s0)
    800061c4:	0017c713          	xor	a4,a5,1
    800061c8:	8b05                	and	a4,a4,1
    800061ca:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800061ce:	0037f713          	and	a4,a5,3
    800061d2:	00e03733          	snez	a4,a4
    800061d6:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800061da:	4007f793          	and	a5,a5,1024
    800061de:	c791                	beqz	a5,800061ea <sys_open+0xce>
    800061e0:	04449703          	lh	a4,68(s1)
    800061e4:	4789                	li	a5,2
    800061e6:	0cf70063          	beq	a4,a5,800062a6 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800061ea:	8526                	mv	a0,s1
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	096080e7          	jalr	150(ra) # 80004282 <iunlock>
  end_op();
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	9ec080e7          	jalr	-1556(ra) # 80004be0 <end_op>

  return fd;
    800061fc:	854e                	mv	a0,s3
}
    800061fe:	70ea                	ld	ra,184(sp)
    80006200:	744a                	ld	s0,176(sp)
    80006202:	74aa                	ld	s1,168(sp)
    80006204:	790a                	ld	s2,160(sp)
    80006206:	69ea                	ld	s3,152(sp)
    80006208:	6129                	add	sp,sp,192
    8000620a:	8082                	ret
      end_op();
    8000620c:	fffff097          	auipc	ra,0xfffff
    80006210:	9d4080e7          	jalr	-1580(ra) # 80004be0 <end_op>
      return -1;
    80006214:	557d                	li	a0,-1
    80006216:	b7e5                	j	800061fe <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80006218:	f5040513          	add	a0,s0,-176
    8000621c:	ffffe097          	auipc	ra,0xffffe
    80006220:	74a080e7          	jalr	1866(ra) # 80004966 <namei>
    80006224:	84aa                	mv	s1,a0
    80006226:	c905                	beqz	a0,80006256 <sys_open+0x13a>
    ilock(ip);
    80006228:	ffffe097          	auipc	ra,0xffffe
    8000622c:	f98080e7          	jalr	-104(ra) # 800041c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006230:	04449703          	lh	a4,68(s1)
    80006234:	4785                	li	a5,1
    80006236:	f4f712e3          	bne	a4,a5,8000617a <sys_open+0x5e>
    8000623a:	f4c42783          	lw	a5,-180(s0)
    8000623e:	dba1                	beqz	a5,8000618e <sys_open+0x72>
      iunlockput(ip);
    80006240:	8526                	mv	a0,s1
    80006242:	ffffe097          	auipc	ra,0xffffe
    80006246:	1e0080e7          	jalr	480(ra) # 80004422 <iunlockput>
      end_op();
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	996080e7          	jalr	-1642(ra) # 80004be0 <end_op>
      return -1;
    80006252:	557d                	li	a0,-1
    80006254:	b76d                	j	800061fe <sys_open+0xe2>
      end_op();
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	98a080e7          	jalr	-1654(ra) # 80004be0 <end_op>
      return -1;
    8000625e:	557d                	li	a0,-1
    80006260:	bf79                	j	800061fe <sys_open+0xe2>
    iunlockput(ip);
    80006262:	8526                	mv	a0,s1
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	1be080e7          	jalr	446(ra) # 80004422 <iunlockput>
    end_op();
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	974080e7          	jalr	-1676(ra) # 80004be0 <end_op>
    return -1;
    80006274:	557d                	li	a0,-1
    80006276:	b761                	j	800061fe <sys_open+0xe2>
      fileclose(f);
    80006278:	854a                	mv	a0,s2
    8000627a:	fffff097          	auipc	ra,0xfffff
    8000627e:	db0080e7          	jalr	-592(ra) # 8000502a <fileclose>
    iunlockput(ip);
    80006282:	8526                	mv	a0,s1
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	19e080e7          	jalr	414(ra) # 80004422 <iunlockput>
    end_op();
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	954080e7          	jalr	-1708(ra) # 80004be0 <end_op>
    return -1;
    80006294:	557d                	li	a0,-1
    80006296:	b7a5                	j	800061fe <sys_open+0xe2>
    f->type = FD_DEVICE;
    80006298:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000629c:	04649783          	lh	a5,70(s1)
    800062a0:	02f91223          	sh	a5,36(s2)
    800062a4:	bf21                	j	800061bc <sys_open+0xa0>
    itrunc(ip);
    800062a6:	8526                	mv	a0,s1
    800062a8:	ffffe097          	auipc	ra,0xffffe
    800062ac:	026080e7          	jalr	38(ra) # 800042ce <itrunc>
    800062b0:	bf2d                	j	800061ea <sys_open+0xce>

00000000800062b2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800062b2:	7175                	add	sp,sp,-144
    800062b4:	e506                	sd	ra,136(sp)
    800062b6:	e122                	sd	s0,128(sp)
    800062b8:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	8ac080e7          	jalr	-1876(ra) # 80004b66 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800062c2:	08000613          	li	a2,128
    800062c6:	f7040593          	add	a1,s0,-144
    800062ca:	4501                	li	a0,0
    800062cc:	ffffd097          	auipc	ra,0xffffd
    800062d0:	1e4080e7          	jalr	484(ra) # 800034b0 <argstr>
    800062d4:	02054963          	bltz	a0,80006306 <sys_mkdir+0x54>
    800062d8:	4681                	li	a3,0
    800062da:	4601                	li	a2,0
    800062dc:	4585                	li	a1,1
    800062de:	f7040513          	add	a0,s0,-144
    800062e2:	00000097          	auipc	ra,0x0
    800062e6:	806080e7          	jalr	-2042(ra) # 80005ae8 <create>
    800062ea:	cd11                	beqz	a0,80006306 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	136080e7          	jalr	310(ra) # 80004422 <iunlockput>
  end_op();
    800062f4:	fffff097          	auipc	ra,0xfffff
    800062f8:	8ec080e7          	jalr	-1812(ra) # 80004be0 <end_op>
  return 0;
    800062fc:	4501                	li	a0,0
}
    800062fe:	60aa                	ld	ra,136(sp)
    80006300:	640a                	ld	s0,128(sp)
    80006302:	6149                	add	sp,sp,144
    80006304:	8082                	ret
    end_op();
    80006306:	fffff097          	auipc	ra,0xfffff
    8000630a:	8da080e7          	jalr	-1830(ra) # 80004be0 <end_op>
    return -1;
    8000630e:	557d                	li	a0,-1
    80006310:	b7fd                	j	800062fe <sys_mkdir+0x4c>

0000000080006312 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006312:	7135                	add	sp,sp,-160
    80006314:	ed06                	sd	ra,152(sp)
    80006316:	e922                	sd	s0,144(sp)
    80006318:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	84c080e7          	jalr	-1972(ra) # 80004b66 <begin_op>
  argint(1, &major);
    80006322:	f6c40593          	add	a1,s0,-148
    80006326:	4505                	li	a0,1
    80006328:	ffffd097          	auipc	ra,0xffffd
    8000632c:	148080e7          	jalr	328(ra) # 80003470 <argint>
  argint(2, &minor);
    80006330:	f6840593          	add	a1,s0,-152
    80006334:	4509                	li	a0,2
    80006336:	ffffd097          	auipc	ra,0xffffd
    8000633a:	13a080e7          	jalr	314(ra) # 80003470 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000633e:	08000613          	li	a2,128
    80006342:	f7040593          	add	a1,s0,-144
    80006346:	4501                	li	a0,0
    80006348:	ffffd097          	auipc	ra,0xffffd
    8000634c:	168080e7          	jalr	360(ra) # 800034b0 <argstr>
    80006350:	02054b63          	bltz	a0,80006386 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006354:	f6841683          	lh	a3,-152(s0)
    80006358:	f6c41603          	lh	a2,-148(s0)
    8000635c:	458d                	li	a1,3
    8000635e:	f7040513          	add	a0,s0,-144
    80006362:	fffff097          	auipc	ra,0xfffff
    80006366:	786080e7          	jalr	1926(ra) # 80005ae8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000636a:	cd11                	beqz	a0,80006386 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000636c:	ffffe097          	auipc	ra,0xffffe
    80006370:	0b6080e7          	jalr	182(ra) # 80004422 <iunlockput>
  end_op();
    80006374:	fffff097          	auipc	ra,0xfffff
    80006378:	86c080e7          	jalr	-1940(ra) # 80004be0 <end_op>
  return 0;
    8000637c:	4501                	li	a0,0
}
    8000637e:	60ea                	ld	ra,152(sp)
    80006380:	644a                	ld	s0,144(sp)
    80006382:	610d                	add	sp,sp,160
    80006384:	8082                	ret
    end_op();
    80006386:	fffff097          	auipc	ra,0xfffff
    8000638a:	85a080e7          	jalr	-1958(ra) # 80004be0 <end_op>
    return -1;
    8000638e:	557d                	li	a0,-1
    80006390:	b7fd                	j	8000637e <sys_mknod+0x6c>

0000000080006392 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006392:	7135                	add	sp,sp,-160
    80006394:	ed06                	sd	ra,152(sp)
    80006396:	e922                	sd	s0,144(sp)
    80006398:	e526                	sd	s1,136(sp)
    8000639a:	e14a                	sd	s2,128(sp)
    8000639c:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000639e:	ffffb097          	auipc	ra,0xffffb
    800063a2:	720080e7          	jalr	1824(ra) # 80001abe <myproc>
    800063a6:	892a                	mv	s2,a0
  
  begin_op();
    800063a8:	ffffe097          	auipc	ra,0xffffe
    800063ac:	7be080e7          	jalr	1982(ra) # 80004b66 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800063b0:	08000613          	li	a2,128
    800063b4:	f6040593          	add	a1,s0,-160
    800063b8:	4501                	li	a0,0
    800063ba:	ffffd097          	auipc	ra,0xffffd
    800063be:	0f6080e7          	jalr	246(ra) # 800034b0 <argstr>
    800063c2:	04054b63          	bltz	a0,80006418 <sys_chdir+0x86>
    800063c6:	f6040513          	add	a0,s0,-160
    800063ca:	ffffe097          	auipc	ra,0xffffe
    800063ce:	59c080e7          	jalr	1436(ra) # 80004966 <namei>
    800063d2:	84aa                	mv	s1,a0
    800063d4:	c131                	beqz	a0,80006418 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800063d6:	ffffe097          	auipc	ra,0xffffe
    800063da:	dea080e7          	jalr	-534(ra) # 800041c0 <ilock>
  if(ip->type != T_DIR){
    800063de:	04449703          	lh	a4,68(s1)
    800063e2:	4785                	li	a5,1
    800063e4:	04f71063          	bne	a4,a5,80006424 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800063e8:	8526                	mv	a0,s1
    800063ea:	ffffe097          	auipc	ra,0xffffe
    800063ee:	e98080e7          	jalr	-360(ra) # 80004282 <iunlock>
  iput(p->cwd);
    800063f2:	15093503          	ld	a0,336(s2)
    800063f6:	ffffe097          	auipc	ra,0xffffe
    800063fa:	f84080e7          	jalr	-124(ra) # 8000437a <iput>
  end_op();
    800063fe:	ffffe097          	auipc	ra,0xffffe
    80006402:	7e2080e7          	jalr	2018(ra) # 80004be0 <end_op>
  p->cwd = ip;
    80006406:	14993823          	sd	s1,336(s2)
  return 0;
    8000640a:	4501                	li	a0,0
}
    8000640c:	60ea                	ld	ra,152(sp)
    8000640e:	644a                	ld	s0,144(sp)
    80006410:	64aa                	ld	s1,136(sp)
    80006412:	690a                	ld	s2,128(sp)
    80006414:	610d                	add	sp,sp,160
    80006416:	8082                	ret
    end_op();
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	7c8080e7          	jalr	1992(ra) # 80004be0 <end_op>
    return -1;
    80006420:	557d                	li	a0,-1
    80006422:	b7ed                	j	8000640c <sys_chdir+0x7a>
    iunlockput(ip);
    80006424:	8526                	mv	a0,s1
    80006426:	ffffe097          	auipc	ra,0xffffe
    8000642a:	ffc080e7          	jalr	-4(ra) # 80004422 <iunlockput>
    end_op();
    8000642e:	ffffe097          	auipc	ra,0xffffe
    80006432:	7b2080e7          	jalr	1970(ra) # 80004be0 <end_op>
    return -1;
    80006436:	557d                	li	a0,-1
    80006438:	bfd1                	j	8000640c <sys_chdir+0x7a>

000000008000643a <sys_exec>:

uint64
sys_exec(void)
{
    8000643a:	7121                	add	sp,sp,-448
    8000643c:	ff06                	sd	ra,440(sp)
    8000643e:	fb22                	sd	s0,432(sp)
    80006440:	f726                	sd	s1,424(sp)
    80006442:	f34a                	sd	s2,416(sp)
    80006444:	ef4e                	sd	s3,408(sp)
    80006446:	eb52                	sd	s4,400(sp)
    80006448:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000644a:	e4840593          	add	a1,s0,-440
    8000644e:	4505                	li	a0,1
    80006450:	ffffd097          	auipc	ra,0xffffd
    80006454:	040080e7          	jalr	64(ra) # 80003490 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006458:	08000613          	li	a2,128
    8000645c:	f5040593          	add	a1,s0,-176
    80006460:	4501                	li	a0,0
    80006462:	ffffd097          	auipc	ra,0xffffd
    80006466:	04e080e7          	jalr	78(ra) # 800034b0 <argstr>
    8000646a:	87aa                	mv	a5,a0
    return -1;
    8000646c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000646e:	0c07c263          	bltz	a5,80006532 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80006472:	10000613          	li	a2,256
    80006476:	4581                	li	a1,0
    80006478:	e5040513          	add	a0,s0,-432
    8000647c:	ffffb097          	auipc	ra,0xffffb
    80006480:	852080e7          	jalr	-1966(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006484:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006488:	89a6                	mv	s3,s1
    8000648a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000648c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006490:	00391513          	sll	a0,s2,0x3
    80006494:	e4040593          	add	a1,s0,-448
    80006498:	e4843783          	ld	a5,-440(s0)
    8000649c:	953e                	add	a0,a0,a5
    8000649e:	ffffd097          	auipc	ra,0xffffd
    800064a2:	f34080e7          	jalr	-204(ra) # 800033d2 <fetchaddr>
    800064a6:	02054a63          	bltz	a0,800064da <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800064aa:	e4043783          	ld	a5,-448(s0)
    800064ae:	c3b9                	beqz	a5,800064f4 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	632080e7          	jalr	1586(ra) # 80000ae2 <kalloc>
    800064b8:	85aa                	mv	a1,a0
    800064ba:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800064be:	cd11                	beqz	a0,800064da <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800064c0:	6605                	lui	a2,0x1
    800064c2:	e4043503          	ld	a0,-448(s0)
    800064c6:	ffffd097          	auipc	ra,0xffffd
    800064ca:	f5e080e7          	jalr	-162(ra) # 80003424 <fetchstr>
    800064ce:	00054663          	bltz	a0,800064da <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800064d2:	0905                	add	s2,s2,1
    800064d4:	09a1                	add	s3,s3,8
    800064d6:	fb491de3          	bne	s2,s4,80006490 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064da:	f5040913          	add	s2,s0,-176
    800064de:	6088                	ld	a0,0(s1)
    800064e0:	c921                	beqz	a0,80006530 <sys_exec+0xf6>
    kfree(argv[i]);
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	502080e7          	jalr	1282(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064ea:	04a1                	add	s1,s1,8
    800064ec:	ff2499e3          	bne	s1,s2,800064de <sys_exec+0xa4>
  return -1;
    800064f0:	557d                	li	a0,-1
    800064f2:	a081                	j	80006532 <sys_exec+0xf8>
      argv[i] = 0;
    800064f4:	0009079b          	sext.w	a5,s2
    800064f8:	078e                	sll	a5,a5,0x3
    800064fa:	fd078793          	add	a5,a5,-48
    800064fe:	97a2                	add	a5,a5,s0
    80006500:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006504:	e5040593          	add	a1,s0,-432
    80006508:	f5040513          	add	a0,s0,-176
    8000650c:	fffff097          	auipc	ra,0xfffff
    80006510:	194080e7          	jalr	404(ra) # 800056a0 <exec>
    80006514:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006516:	f5040993          	add	s3,s0,-176
    8000651a:	6088                	ld	a0,0(s1)
    8000651c:	c901                	beqz	a0,8000652c <sys_exec+0xf2>
    kfree(argv[i]);
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	4c6080e7          	jalr	1222(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006526:	04a1                	add	s1,s1,8
    80006528:	ff3499e3          	bne	s1,s3,8000651a <sys_exec+0xe0>
  return ret;
    8000652c:	854a                	mv	a0,s2
    8000652e:	a011                	j	80006532 <sys_exec+0xf8>
  return -1;
    80006530:	557d                	li	a0,-1
}
    80006532:	70fa                	ld	ra,440(sp)
    80006534:	745a                	ld	s0,432(sp)
    80006536:	74ba                	ld	s1,424(sp)
    80006538:	791a                	ld	s2,416(sp)
    8000653a:	69fa                	ld	s3,408(sp)
    8000653c:	6a5a                	ld	s4,400(sp)
    8000653e:	6139                	add	sp,sp,448
    80006540:	8082                	ret

0000000080006542 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006542:	7139                	add	sp,sp,-64
    80006544:	fc06                	sd	ra,56(sp)
    80006546:	f822                	sd	s0,48(sp)
    80006548:	f426                	sd	s1,40(sp)
    8000654a:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000654c:	ffffb097          	auipc	ra,0xffffb
    80006550:	572080e7          	jalr	1394(ra) # 80001abe <myproc>
    80006554:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006556:	fd840593          	add	a1,s0,-40
    8000655a:	4501                	li	a0,0
    8000655c:	ffffd097          	auipc	ra,0xffffd
    80006560:	f34080e7          	jalr	-204(ra) # 80003490 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006564:	fc840593          	add	a1,s0,-56
    80006568:	fd040513          	add	a0,s0,-48
    8000656c:	fffff097          	auipc	ra,0xfffff
    80006570:	dea080e7          	jalr	-534(ra) # 80005356 <pipealloc>
    return -1;
    80006574:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006576:	0c054463          	bltz	a0,8000663e <sys_pipe+0xfc>
  fd0 = -1;
    8000657a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000657e:	fd043503          	ld	a0,-48(s0)
    80006582:	fffff097          	auipc	ra,0xfffff
    80006586:	524080e7          	jalr	1316(ra) # 80005aa6 <fdalloc>
    8000658a:	fca42223          	sw	a0,-60(s0)
    8000658e:	08054b63          	bltz	a0,80006624 <sys_pipe+0xe2>
    80006592:	fc843503          	ld	a0,-56(s0)
    80006596:	fffff097          	auipc	ra,0xfffff
    8000659a:	510080e7          	jalr	1296(ra) # 80005aa6 <fdalloc>
    8000659e:	fca42023          	sw	a0,-64(s0)
    800065a2:	06054863          	bltz	a0,80006612 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065a6:	4691                	li	a3,4
    800065a8:	fc440613          	add	a2,s0,-60
    800065ac:	fd843583          	ld	a1,-40(s0)
    800065b0:	68a8                	ld	a0,80(s1)
    800065b2:	ffffb097          	auipc	ra,0xffffb
    800065b6:	0b4080e7          	jalr	180(ra) # 80001666 <copyout>
    800065ba:	02054063          	bltz	a0,800065da <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800065be:	4691                	li	a3,4
    800065c0:	fc040613          	add	a2,s0,-64
    800065c4:	fd843583          	ld	a1,-40(s0)
    800065c8:	0591                	add	a1,a1,4
    800065ca:	68a8                	ld	a0,80(s1)
    800065cc:	ffffb097          	auipc	ra,0xffffb
    800065d0:	09a080e7          	jalr	154(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800065d4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065d6:	06055463          	bgez	a0,8000663e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800065da:	fc442783          	lw	a5,-60(s0)
    800065de:	07e9                	add	a5,a5,26
    800065e0:	078e                	sll	a5,a5,0x3
    800065e2:	97a6                	add	a5,a5,s1
    800065e4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800065e8:	fc042783          	lw	a5,-64(s0)
    800065ec:	07e9                	add	a5,a5,26
    800065ee:	078e                	sll	a5,a5,0x3
    800065f0:	94be                	add	s1,s1,a5
    800065f2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800065f6:	fd043503          	ld	a0,-48(s0)
    800065fa:	fffff097          	auipc	ra,0xfffff
    800065fe:	a30080e7          	jalr	-1488(ra) # 8000502a <fileclose>
    fileclose(wf);
    80006602:	fc843503          	ld	a0,-56(s0)
    80006606:	fffff097          	auipc	ra,0xfffff
    8000660a:	a24080e7          	jalr	-1500(ra) # 8000502a <fileclose>
    return -1;
    8000660e:	57fd                	li	a5,-1
    80006610:	a03d                	j	8000663e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006612:	fc442783          	lw	a5,-60(s0)
    80006616:	0007c763          	bltz	a5,80006624 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000661a:	07e9                	add	a5,a5,26
    8000661c:	078e                	sll	a5,a5,0x3
    8000661e:	97a6                	add	a5,a5,s1
    80006620:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006624:	fd043503          	ld	a0,-48(s0)
    80006628:	fffff097          	auipc	ra,0xfffff
    8000662c:	a02080e7          	jalr	-1534(ra) # 8000502a <fileclose>
    fileclose(wf);
    80006630:	fc843503          	ld	a0,-56(s0)
    80006634:	fffff097          	auipc	ra,0xfffff
    80006638:	9f6080e7          	jalr	-1546(ra) # 8000502a <fileclose>
    return -1;
    8000663c:	57fd                	li	a5,-1
}
    8000663e:	853e                	mv	a0,a5
    80006640:	70e2                	ld	ra,56(sp)
    80006642:	7442                	ld	s0,48(sp)
    80006644:	74a2                	ld	s1,40(sp)
    80006646:	6121                	add	sp,sp,64
    80006648:	8082                	ret
    8000664a:	0000                	unimp
    8000664c:	0000                	unimp
	...

0000000080006650 <kernelvec>:
    80006650:	7111                	add	sp,sp,-256
    80006652:	e006                	sd	ra,0(sp)
    80006654:	e40a                	sd	sp,8(sp)
    80006656:	e80e                	sd	gp,16(sp)
    80006658:	ec12                	sd	tp,24(sp)
    8000665a:	f016                	sd	t0,32(sp)
    8000665c:	f41a                	sd	t1,40(sp)
    8000665e:	f81e                	sd	t2,48(sp)
    80006660:	fc22                	sd	s0,56(sp)
    80006662:	e0a6                	sd	s1,64(sp)
    80006664:	e4aa                	sd	a0,72(sp)
    80006666:	e8ae                	sd	a1,80(sp)
    80006668:	ecb2                	sd	a2,88(sp)
    8000666a:	f0b6                	sd	a3,96(sp)
    8000666c:	f4ba                	sd	a4,104(sp)
    8000666e:	f8be                	sd	a5,112(sp)
    80006670:	fcc2                	sd	a6,120(sp)
    80006672:	e146                	sd	a7,128(sp)
    80006674:	e54a                	sd	s2,136(sp)
    80006676:	e94e                	sd	s3,144(sp)
    80006678:	ed52                	sd	s4,152(sp)
    8000667a:	f156                	sd	s5,160(sp)
    8000667c:	f55a                	sd	s6,168(sp)
    8000667e:	f95e                	sd	s7,176(sp)
    80006680:	fd62                	sd	s8,184(sp)
    80006682:	e1e6                	sd	s9,192(sp)
    80006684:	e5ea                	sd	s10,200(sp)
    80006686:	e9ee                	sd	s11,208(sp)
    80006688:	edf2                	sd	t3,216(sp)
    8000668a:	f1f6                	sd	t4,224(sp)
    8000668c:	f5fa                	sd	t5,232(sp)
    8000668e:	f9fe                	sd	t6,240(sp)
    80006690:	c0ffc0ef          	jal	8000329e <kerneltrap>
    80006694:	6082                	ld	ra,0(sp)
    80006696:	6122                	ld	sp,8(sp)
    80006698:	61c2                	ld	gp,16(sp)
    8000669a:	7282                	ld	t0,32(sp)
    8000669c:	7322                	ld	t1,40(sp)
    8000669e:	73c2                	ld	t2,48(sp)
    800066a0:	7462                	ld	s0,56(sp)
    800066a2:	6486                	ld	s1,64(sp)
    800066a4:	6526                	ld	a0,72(sp)
    800066a6:	65c6                	ld	a1,80(sp)
    800066a8:	6666                	ld	a2,88(sp)
    800066aa:	7686                	ld	a3,96(sp)
    800066ac:	7726                	ld	a4,104(sp)
    800066ae:	77c6                	ld	a5,112(sp)
    800066b0:	7866                	ld	a6,120(sp)
    800066b2:	688a                	ld	a7,128(sp)
    800066b4:	692a                	ld	s2,136(sp)
    800066b6:	69ca                	ld	s3,144(sp)
    800066b8:	6a6a                	ld	s4,152(sp)
    800066ba:	7a8a                	ld	s5,160(sp)
    800066bc:	7b2a                	ld	s6,168(sp)
    800066be:	7bca                	ld	s7,176(sp)
    800066c0:	7c6a                	ld	s8,184(sp)
    800066c2:	6c8e                	ld	s9,192(sp)
    800066c4:	6d2e                	ld	s10,200(sp)
    800066c6:	6dce                	ld	s11,208(sp)
    800066c8:	6e6e                	ld	t3,216(sp)
    800066ca:	7e8e                	ld	t4,224(sp)
    800066cc:	7f2e                	ld	t5,232(sp)
    800066ce:	7fce                	ld	t6,240(sp)
    800066d0:	6111                	add	sp,sp,256
    800066d2:	10200073          	sret
    800066d6:	00000013          	nop
    800066da:	00000013          	nop
    800066de:	0001                	nop

00000000800066e0 <timervec>:
    800066e0:	34051573          	csrrw	a0,mscratch,a0
    800066e4:	e10c                	sd	a1,0(a0)
    800066e6:	e510                	sd	a2,8(a0)
    800066e8:	e914                	sd	a3,16(a0)
    800066ea:	6d0c                	ld	a1,24(a0)
    800066ec:	7110                	ld	a2,32(a0)
    800066ee:	6194                	ld	a3,0(a1)
    800066f0:	96b2                	add	a3,a3,a2
    800066f2:	e194                	sd	a3,0(a1)
    800066f4:	4589                	li	a1,2
    800066f6:	14459073          	csrw	sip,a1
    800066fa:	6914                	ld	a3,16(a0)
    800066fc:	6510                	ld	a2,8(a0)
    800066fe:	610c                	ld	a1,0(a0)
    80006700:	34051573          	csrrw	a0,mscratch,a0
    80006704:	30200073          	mret
	...

000000008000670a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000670a:	1141                	add	sp,sp,-16
    8000670c:	e422                	sd	s0,8(sp)
    8000670e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006710:	0c0007b7          	lui	a5,0xc000
    80006714:	4705                	li	a4,1
    80006716:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006718:	c3d8                	sw	a4,4(a5)
}
    8000671a:	6422                	ld	s0,8(sp)
    8000671c:	0141                	add	sp,sp,16
    8000671e:	8082                	ret

0000000080006720 <plicinithart>:

void
plicinithart(void)
{
    80006720:	1141                	add	sp,sp,-16
    80006722:	e406                	sd	ra,8(sp)
    80006724:	e022                	sd	s0,0(sp)
    80006726:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006728:	ffffb097          	auipc	ra,0xffffb
    8000672c:	36a080e7          	jalr	874(ra) # 80001a92 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006730:	0085171b          	sllw	a4,a0,0x8
    80006734:	0c0027b7          	lui	a5,0xc002
    80006738:	97ba                	add	a5,a5,a4
    8000673a:	40200713          	li	a4,1026
    8000673e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006742:	00d5151b          	sllw	a0,a0,0xd
    80006746:	0c2017b7          	lui	a5,0xc201
    8000674a:	97aa                	add	a5,a5,a0
    8000674c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006750:	60a2                	ld	ra,8(sp)
    80006752:	6402                	ld	s0,0(sp)
    80006754:	0141                	add	sp,sp,16
    80006756:	8082                	ret

0000000080006758 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006758:	1141                	add	sp,sp,-16
    8000675a:	e406                	sd	ra,8(sp)
    8000675c:	e022                	sd	s0,0(sp)
    8000675e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006760:	ffffb097          	auipc	ra,0xffffb
    80006764:	332080e7          	jalr	818(ra) # 80001a92 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006768:	00d5151b          	sllw	a0,a0,0xd
    8000676c:	0c2017b7          	lui	a5,0xc201
    80006770:	97aa                	add	a5,a5,a0
  return irq;
}
    80006772:	43c8                	lw	a0,4(a5)
    80006774:	60a2                	ld	ra,8(sp)
    80006776:	6402                	ld	s0,0(sp)
    80006778:	0141                	add	sp,sp,16
    8000677a:	8082                	ret

000000008000677c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000677c:	1101                	add	sp,sp,-32
    8000677e:	ec06                	sd	ra,24(sp)
    80006780:	e822                	sd	s0,16(sp)
    80006782:	e426                	sd	s1,8(sp)
    80006784:	1000                	add	s0,sp,32
    80006786:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006788:	ffffb097          	auipc	ra,0xffffb
    8000678c:	30a080e7          	jalr	778(ra) # 80001a92 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006790:	00d5151b          	sllw	a0,a0,0xd
    80006794:	0c2017b7          	lui	a5,0xc201
    80006798:	97aa                	add	a5,a5,a0
    8000679a:	c3c4                	sw	s1,4(a5)
}
    8000679c:	60e2                	ld	ra,24(sp)
    8000679e:	6442                	ld	s0,16(sp)
    800067a0:	64a2                	ld	s1,8(sp)
    800067a2:	6105                	add	sp,sp,32
    800067a4:	8082                	ret

00000000800067a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800067a6:	1141                	add	sp,sp,-16
    800067a8:	e406                	sd	ra,8(sp)
    800067aa:	e022                	sd	s0,0(sp)
    800067ac:	0800                	add	s0,sp,16
  if(i >= NUM)
    800067ae:	479d                	li	a5,7
    800067b0:	04a7cc63          	blt	a5,a0,80006808 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800067b4:	0001f797          	auipc	a5,0x1f
    800067b8:	6fc78793          	add	a5,a5,1788 # 80025eb0 <disk>
    800067bc:	97aa                	add	a5,a5,a0
    800067be:	0187c783          	lbu	a5,24(a5)
    800067c2:	ebb9                	bnez	a5,80006818 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800067c4:	00451693          	sll	a3,a0,0x4
    800067c8:	0001f797          	auipc	a5,0x1f
    800067cc:	6e878793          	add	a5,a5,1768 # 80025eb0 <disk>
    800067d0:	6398                	ld	a4,0(a5)
    800067d2:	9736                	add	a4,a4,a3
    800067d4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800067d8:	6398                	ld	a4,0(a5)
    800067da:	9736                	add	a4,a4,a3
    800067dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800067e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800067e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800067e8:	97aa                	add	a5,a5,a0
    800067ea:	4705                	li	a4,1
    800067ec:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800067f0:	0001f517          	auipc	a0,0x1f
    800067f4:	6d850513          	add	a0,a0,1752 # 80025ec8 <disk+0x18>
    800067f8:	ffffc097          	auipc	ra,0xffffc
    800067fc:	03c080e7          	jalr	60(ra) # 80002834 <wakeup>
}
    80006800:	60a2                	ld	ra,8(sp)
    80006802:	6402                	ld	s0,0(sp)
    80006804:	0141                	add	sp,sp,16
    80006806:	8082                	ret
    panic("free_desc 1");
    80006808:	00002517          	auipc	a0,0x2
    8000680c:	fd050513          	add	a0,a0,-48 # 800087d8 <syscalls+0x338>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	d2c080e7          	jalr	-724(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006818:	00002517          	auipc	a0,0x2
    8000681c:	fd050513          	add	a0,a0,-48 # 800087e8 <syscalls+0x348>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	d1c080e7          	jalr	-740(ra) # 8000053c <panic>

0000000080006828 <virtio_disk_init>:
{
    80006828:	1101                	add	sp,sp,-32
    8000682a:	ec06                	sd	ra,24(sp)
    8000682c:	e822                	sd	s0,16(sp)
    8000682e:	e426                	sd	s1,8(sp)
    80006830:	e04a                	sd	s2,0(sp)
    80006832:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006834:	00002597          	auipc	a1,0x2
    80006838:	fc458593          	add	a1,a1,-60 # 800087f8 <syscalls+0x358>
    8000683c:	0001f517          	auipc	a0,0x1f
    80006840:	79c50513          	add	a0,a0,1948 # 80025fd8 <disk+0x128>
    80006844:	ffffa097          	auipc	ra,0xffffa
    80006848:	2fe080e7          	jalr	766(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000684c:	100017b7          	lui	a5,0x10001
    80006850:	4398                	lw	a4,0(a5)
    80006852:	2701                	sext.w	a4,a4
    80006854:	747277b7          	lui	a5,0x74727
    80006858:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000685c:	14f71b63          	bne	a4,a5,800069b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006860:	100017b7          	lui	a5,0x10001
    80006864:	43dc                	lw	a5,4(a5)
    80006866:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006868:	4709                	li	a4,2
    8000686a:	14e79463          	bne	a5,a4,800069b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000686e:	100017b7          	lui	a5,0x10001
    80006872:	479c                	lw	a5,8(a5)
    80006874:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006876:	12e79e63          	bne	a5,a4,800069b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000687a:	100017b7          	lui	a5,0x10001
    8000687e:	47d8                	lw	a4,12(a5)
    80006880:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006882:	554d47b7          	lui	a5,0x554d4
    80006886:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000688a:	12f71463          	bne	a4,a5,800069b2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000688e:	100017b7          	lui	a5,0x10001
    80006892:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006896:	4705                	li	a4,1
    80006898:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000689a:	470d                	li	a4,3
    8000689c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000689e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800068a0:	c7ffe6b7          	lui	a3,0xc7ffe
    800068a4:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd876f>
    800068a8:	8f75                	and	a4,a4,a3
    800068aa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068ac:	472d                	li	a4,11
    800068ae:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800068b0:	5bbc                	lw	a5,112(a5)
    800068b2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800068b6:	8ba1                	and	a5,a5,8
    800068b8:	10078563          	beqz	a5,800069c2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800068bc:	100017b7          	lui	a5,0x10001
    800068c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800068c4:	43fc                	lw	a5,68(a5)
    800068c6:	2781                	sext.w	a5,a5
    800068c8:	10079563          	bnez	a5,800069d2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800068cc:	100017b7          	lui	a5,0x10001
    800068d0:	5bdc                	lw	a5,52(a5)
    800068d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800068d4:	10078763          	beqz	a5,800069e2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800068d8:	471d                	li	a4,7
    800068da:	10f77c63          	bgeu	a4,a5,800069f2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800068de:	ffffa097          	auipc	ra,0xffffa
    800068e2:	204080e7          	jalr	516(ra) # 80000ae2 <kalloc>
    800068e6:	0001f497          	auipc	s1,0x1f
    800068ea:	5ca48493          	add	s1,s1,1482 # 80025eb0 <disk>
    800068ee:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	1f2080e7          	jalr	498(ra) # 80000ae2 <kalloc>
    800068f8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800068fa:	ffffa097          	auipc	ra,0xffffa
    800068fe:	1e8080e7          	jalr	488(ra) # 80000ae2 <kalloc>
    80006902:	87aa                	mv	a5,a0
    80006904:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006906:	6088                	ld	a0,0(s1)
    80006908:	cd6d                	beqz	a0,80006a02 <virtio_disk_init+0x1da>
    8000690a:	0001f717          	auipc	a4,0x1f
    8000690e:	5ae73703          	ld	a4,1454(a4) # 80025eb8 <disk+0x8>
    80006912:	cb65                	beqz	a4,80006a02 <virtio_disk_init+0x1da>
    80006914:	c7fd                	beqz	a5,80006a02 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006916:	6605                	lui	a2,0x1
    80006918:	4581                	li	a1,0
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	3b4080e7          	jalr	948(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006922:	0001f497          	auipc	s1,0x1f
    80006926:	58e48493          	add	s1,s1,1422 # 80025eb0 <disk>
    8000692a:	6605                	lui	a2,0x1
    8000692c:	4581                	li	a1,0
    8000692e:	6488                	ld	a0,8(s1)
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	39e080e7          	jalr	926(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006938:	6605                	lui	a2,0x1
    8000693a:	4581                	li	a1,0
    8000693c:	6888                	ld	a0,16(s1)
    8000693e:	ffffa097          	auipc	ra,0xffffa
    80006942:	390080e7          	jalr	912(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006946:	100017b7          	lui	a5,0x10001
    8000694a:	4721                	li	a4,8
    8000694c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000694e:	4098                	lw	a4,0(s1)
    80006950:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006954:	40d8                	lw	a4,4(s1)
    80006956:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000695a:	6498                	ld	a4,8(s1)
    8000695c:	0007069b          	sext.w	a3,a4
    80006960:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006964:	9701                	sra	a4,a4,0x20
    80006966:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000696a:	6898                	ld	a4,16(s1)
    8000696c:	0007069b          	sext.w	a3,a4
    80006970:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006974:	9701                	sra	a4,a4,0x20
    80006976:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000697a:	4705                	li	a4,1
    8000697c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000697e:	00e48c23          	sb	a4,24(s1)
    80006982:	00e48ca3          	sb	a4,25(s1)
    80006986:	00e48d23          	sb	a4,26(s1)
    8000698a:	00e48da3          	sb	a4,27(s1)
    8000698e:	00e48e23          	sb	a4,28(s1)
    80006992:	00e48ea3          	sb	a4,29(s1)
    80006996:	00e48f23          	sb	a4,30(s1)
    8000699a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000699e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800069a2:	0727a823          	sw	s2,112(a5)
}
    800069a6:	60e2                	ld	ra,24(sp)
    800069a8:	6442                	ld	s0,16(sp)
    800069aa:	64a2                	ld	s1,8(sp)
    800069ac:	6902                	ld	s2,0(sp)
    800069ae:	6105                	add	sp,sp,32
    800069b0:	8082                	ret
    panic("could not find virtio disk");
    800069b2:	00002517          	auipc	a0,0x2
    800069b6:	e5650513          	add	a0,a0,-426 # 80008808 <syscalls+0x368>
    800069ba:	ffffa097          	auipc	ra,0xffffa
    800069be:	b82080e7          	jalr	-1150(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800069c2:	00002517          	auipc	a0,0x2
    800069c6:	e6650513          	add	a0,a0,-410 # 80008828 <syscalls+0x388>
    800069ca:	ffffa097          	auipc	ra,0xffffa
    800069ce:	b72080e7          	jalr	-1166(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800069d2:	00002517          	auipc	a0,0x2
    800069d6:	e7650513          	add	a0,a0,-394 # 80008848 <syscalls+0x3a8>
    800069da:	ffffa097          	auipc	ra,0xffffa
    800069de:	b62080e7          	jalr	-1182(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800069e2:	00002517          	auipc	a0,0x2
    800069e6:	e8650513          	add	a0,a0,-378 # 80008868 <syscalls+0x3c8>
    800069ea:	ffffa097          	auipc	ra,0xffffa
    800069ee:	b52080e7          	jalr	-1198(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800069f2:	00002517          	auipc	a0,0x2
    800069f6:	e9650513          	add	a0,a0,-362 # 80008888 <syscalls+0x3e8>
    800069fa:	ffffa097          	auipc	ra,0xffffa
    800069fe:	b42080e7          	jalr	-1214(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006a02:	00002517          	auipc	a0,0x2
    80006a06:	ea650513          	add	a0,a0,-346 # 800088a8 <syscalls+0x408>
    80006a0a:	ffffa097          	auipc	ra,0xffffa
    80006a0e:	b32080e7          	jalr	-1230(ra) # 8000053c <panic>

0000000080006a12 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a12:	7159                	add	sp,sp,-112
    80006a14:	f486                	sd	ra,104(sp)
    80006a16:	f0a2                	sd	s0,96(sp)
    80006a18:	eca6                	sd	s1,88(sp)
    80006a1a:	e8ca                	sd	s2,80(sp)
    80006a1c:	e4ce                	sd	s3,72(sp)
    80006a1e:	e0d2                	sd	s4,64(sp)
    80006a20:	fc56                	sd	s5,56(sp)
    80006a22:	f85a                	sd	s6,48(sp)
    80006a24:	f45e                	sd	s7,40(sp)
    80006a26:	f062                	sd	s8,32(sp)
    80006a28:	ec66                	sd	s9,24(sp)
    80006a2a:	e86a                	sd	s10,16(sp)
    80006a2c:	1880                	add	s0,sp,112
    80006a2e:	8a2a                	mv	s4,a0
    80006a30:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006a32:	00c52c83          	lw	s9,12(a0)
    80006a36:	001c9c9b          	sllw	s9,s9,0x1
    80006a3a:	1c82                	sll	s9,s9,0x20
    80006a3c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006a40:	0001f517          	auipc	a0,0x1f
    80006a44:	59850513          	add	a0,a0,1432 # 80025fd8 <disk+0x128>
    80006a48:	ffffa097          	auipc	ra,0xffffa
    80006a4c:	18a080e7          	jalr	394(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006a50:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006a52:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006a54:	0001fb17          	auipc	s6,0x1f
    80006a58:	45cb0b13          	add	s6,s6,1116 # 80025eb0 <disk>
  for(int i = 0; i < 3; i++){
    80006a5c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a5e:	0001fc17          	auipc	s8,0x1f
    80006a62:	57ac0c13          	add	s8,s8,1402 # 80025fd8 <disk+0x128>
    80006a66:	a095                	j	80006aca <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006a68:	00fb0733          	add	a4,s6,a5
    80006a6c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a70:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006a72:	0207c563          	bltz	a5,80006a9c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006a76:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006a78:	0591                	add	a1,a1,4
    80006a7a:	05560d63          	beq	a2,s5,80006ad4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006a7e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006a80:	0001f717          	auipc	a4,0x1f
    80006a84:	43070713          	add	a4,a4,1072 # 80025eb0 <disk>
    80006a88:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80006a8a:	01874683          	lbu	a3,24(a4)
    80006a8e:	fee9                	bnez	a3,80006a68 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006a90:	2785                	addw	a5,a5,1
    80006a92:	0705                	add	a4,a4,1
    80006a94:	fe979be3          	bne	a5,s1,80006a8a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006a98:	57fd                	li	a5,-1
    80006a9a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80006a9c:	00c05e63          	blez	a2,80006ab8 <virtio_disk_rw+0xa6>
    80006aa0:	060a                	sll	a2,a2,0x2
    80006aa2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006aa6:	0009a503          	lw	a0,0(s3)
    80006aaa:	00000097          	auipc	ra,0x0
    80006aae:	cfc080e7          	jalr	-772(ra) # 800067a6 <free_desc>
      for(int j = 0; j < i; j++)
    80006ab2:	0991                	add	s3,s3,4
    80006ab4:	ffa999e3          	bne	s3,s10,80006aa6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ab8:	85e2                	mv	a1,s8
    80006aba:	0001f517          	auipc	a0,0x1f
    80006abe:	40e50513          	add	a0,a0,1038 # 80025ec8 <disk+0x18>
    80006ac2:	ffffc097          	auipc	ra,0xffffc
    80006ac6:	d0e080e7          	jalr	-754(ra) # 800027d0 <sleep>
  for(int i = 0; i < 3; i++){
    80006aca:	f9040993          	add	s3,s0,-112
{
    80006ace:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006ad0:	864a                	mv	a2,s2
    80006ad2:	b775                	j	80006a7e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ad4:	f9042503          	lw	a0,-112(s0)
    80006ad8:	00a50713          	add	a4,a0,10
    80006adc:	0712                	sll	a4,a4,0x4

  if(write)
    80006ade:	0001f797          	auipc	a5,0x1f
    80006ae2:	3d278793          	add	a5,a5,978 # 80025eb0 <disk>
    80006ae6:	00e786b3          	add	a3,a5,a4
    80006aea:	01703633          	snez	a2,s7
    80006aee:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006af0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006af4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006af8:	f6070613          	add	a2,a4,-160
    80006afc:	6394                	ld	a3,0(a5)
    80006afe:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b00:	00870593          	add	a1,a4,8
    80006b04:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b06:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b08:	0007b803          	ld	a6,0(a5)
    80006b0c:	9642                	add	a2,a2,a6
    80006b0e:	46c1                	li	a3,16
    80006b10:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b12:	4585                	li	a1,1
    80006b14:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006b18:	f9442683          	lw	a3,-108(s0)
    80006b1c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006b20:	0692                	sll	a3,a3,0x4
    80006b22:	9836                	add	a6,a6,a3
    80006b24:	058a0613          	add	a2,s4,88
    80006b28:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006b2c:	0007b803          	ld	a6,0(a5)
    80006b30:	96c2                	add	a3,a3,a6
    80006b32:	40000613          	li	a2,1024
    80006b36:	c690                	sw	a2,8(a3)
  if(write)
    80006b38:	001bb613          	seqz	a2,s7
    80006b3c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006b40:	00166613          	or	a2,a2,1
    80006b44:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006b48:	f9842603          	lw	a2,-104(s0)
    80006b4c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b50:	00250693          	add	a3,a0,2
    80006b54:	0692                	sll	a3,a3,0x4
    80006b56:	96be                	add	a3,a3,a5
    80006b58:	58fd                	li	a7,-1
    80006b5a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b5e:	0612                	sll	a2,a2,0x4
    80006b60:	9832                	add	a6,a6,a2
    80006b62:	f9070713          	add	a4,a4,-112
    80006b66:	973e                	add	a4,a4,a5
    80006b68:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006b6c:	6398                	ld	a4,0(a5)
    80006b6e:	9732                	add	a4,a4,a2
    80006b70:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b72:	4609                	li	a2,2
    80006b74:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006b78:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b7c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006b80:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b84:	6794                	ld	a3,8(a5)
    80006b86:	0026d703          	lhu	a4,2(a3)
    80006b8a:	8b1d                	and	a4,a4,7
    80006b8c:	0706                	sll	a4,a4,0x1
    80006b8e:	96ba                	add	a3,a3,a4
    80006b90:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006b94:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b98:	6798                	ld	a4,8(a5)
    80006b9a:	00275783          	lhu	a5,2(a4)
    80006b9e:	2785                	addw	a5,a5,1
    80006ba0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ba4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ba8:	100017b7          	lui	a5,0x10001
    80006bac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006bb0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006bb4:	0001f917          	auipc	s2,0x1f
    80006bb8:	42490913          	add	s2,s2,1060 # 80025fd8 <disk+0x128>
  while(b->disk == 1) {
    80006bbc:	4485                	li	s1,1
    80006bbe:	00b79c63          	bne	a5,a1,80006bd6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006bc2:	85ca                	mv	a1,s2
    80006bc4:	8552                	mv	a0,s4
    80006bc6:	ffffc097          	auipc	ra,0xffffc
    80006bca:	c0a080e7          	jalr	-1014(ra) # 800027d0 <sleep>
  while(b->disk == 1) {
    80006bce:	004a2783          	lw	a5,4(s4)
    80006bd2:	fe9788e3          	beq	a5,s1,80006bc2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006bd6:	f9042903          	lw	s2,-112(s0)
    80006bda:	00290713          	add	a4,s2,2
    80006bde:	0712                	sll	a4,a4,0x4
    80006be0:	0001f797          	auipc	a5,0x1f
    80006be4:	2d078793          	add	a5,a5,720 # 80025eb0 <disk>
    80006be8:	97ba                	add	a5,a5,a4
    80006bea:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006bee:	0001f997          	auipc	s3,0x1f
    80006bf2:	2c298993          	add	s3,s3,706 # 80025eb0 <disk>
    80006bf6:	00491713          	sll	a4,s2,0x4
    80006bfa:	0009b783          	ld	a5,0(s3)
    80006bfe:	97ba                	add	a5,a5,a4
    80006c00:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c04:	854a                	mv	a0,s2
    80006c06:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c0a:	00000097          	auipc	ra,0x0
    80006c0e:	b9c080e7          	jalr	-1124(ra) # 800067a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c12:	8885                	and	s1,s1,1
    80006c14:	f0ed                	bnez	s1,80006bf6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c16:	0001f517          	auipc	a0,0x1f
    80006c1a:	3c250513          	add	a0,a0,962 # 80025fd8 <disk+0x128>
    80006c1e:	ffffa097          	auipc	ra,0xffffa
    80006c22:	068080e7          	jalr	104(ra) # 80000c86 <release>
}
    80006c26:	70a6                	ld	ra,104(sp)
    80006c28:	7406                	ld	s0,96(sp)
    80006c2a:	64e6                	ld	s1,88(sp)
    80006c2c:	6946                	ld	s2,80(sp)
    80006c2e:	69a6                	ld	s3,72(sp)
    80006c30:	6a06                	ld	s4,64(sp)
    80006c32:	7ae2                	ld	s5,56(sp)
    80006c34:	7b42                	ld	s6,48(sp)
    80006c36:	7ba2                	ld	s7,40(sp)
    80006c38:	7c02                	ld	s8,32(sp)
    80006c3a:	6ce2                	ld	s9,24(sp)
    80006c3c:	6d42                	ld	s10,16(sp)
    80006c3e:	6165                	add	sp,sp,112
    80006c40:	8082                	ret

0000000080006c42 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006c42:	1101                	add	sp,sp,-32
    80006c44:	ec06                	sd	ra,24(sp)
    80006c46:	e822                	sd	s0,16(sp)
    80006c48:	e426                	sd	s1,8(sp)
    80006c4a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006c4c:	0001f497          	auipc	s1,0x1f
    80006c50:	26448493          	add	s1,s1,612 # 80025eb0 <disk>
    80006c54:	0001f517          	auipc	a0,0x1f
    80006c58:	38450513          	add	a0,a0,900 # 80025fd8 <disk+0x128>
    80006c5c:	ffffa097          	auipc	ra,0xffffa
    80006c60:	f76080e7          	jalr	-138(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006c64:	10001737          	lui	a4,0x10001
    80006c68:	533c                	lw	a5,96(a4)
    80006c6a:	8b8d                	and	a5,a5,3
    80006c6c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c6e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c72:	689c                	ld	a5,16(s1)
    80006c74:	0204d703          	lhu	a4,32(s1)
    80006c78:	0027d783          	lhu	a5,2(a5)
    80006c7c:	04f70863          	beq	a4,a5,80006ccc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006c80:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c84:	6898                	ld	a4,16(s1)
    80006c86:	0204d783          	lhu	a5,32(s1)
    80006c8a:	8b9d                	and	a5,a5,7
    80006c8c:	078e                	sll	a5,a5,0x3
    80006c8e:	97ba                	add	a5,a5,a4
    80006c90:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c92:	00278713          	add	a4,a5,2
    80006c96:	0712                	sll	a4,a4,0x4
    80006c98:	9726                	add	a4,a4,s1
    80006c9a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c9e:	e721                	bnez	a4,80006ce6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006ca0:	0789                	add	a5,a5,2
    80006ca2:	0792                	sll	a5,a5,0x4
    80006ca4:	97a6                	add	a5,a5,s1
    80006ca6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006ca8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006cac:	ffffc097          	auipc	ra,0xffffc
    80006cb0:	b88080e7          	jalr	-1144(ra) # 80002834 <wakeup>

    disk.used_idx += 1;
    80006cb4:	0204d783          	lhu	a5,32(s1)
    80006cb8:	2785                	addw	a5,a5,1
    80006cba:	17c2                	sll	a5,a5,0x30
    80006cbc:	93c1                	srl	a5,a5,0x30
    80006cbe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006cc2:	6898                	ld	a4,16(s1)
    80006cc4:	00275703          	lhu	a4,2(a4)
    80006cc8:	faf71ce3          	bne	a4,a5,80006c80 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006ccc:	0001f517          	auipc	a0,0x1f
    80006cd0:	30c50513          	add	a0,a0,780 # 80025fd8 <disk+0x128>
    80006cd4:	ffffa097          	auipc	ra,0xffffa
    80006cd8:	fb2080e7          	jalr	-78(ra) # 80000c86 <release>
}
    80006cdc:	60e2                	ld	ra,24(sp)
    80006cde:	6442                	ld	s0,16(sp)
    80006ce0:	64a2                	ld	s1,8(sp)
    80006ce2:	6105                	add	sp,sp,32
    80006ce4:	8082                	ret
      panic("virtio_disk_intr status");
    80006ce6:	00002517          	auipc	a0,0x2
    80006cea:	bda50513          	add	a0,a0,-1062 # 800088c0 <syscalls+0x420>
    80006cee:	ffffa097          	auipc	ra,0xffffa
    80006cf2:	84e080e7          	jalr	-1970(ra) # 8000053c <panic>
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
