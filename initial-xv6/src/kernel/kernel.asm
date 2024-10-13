
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
    80000062:	00007797          	auipc	a5,0x7
    80000066:	82e78793          	add	a5,a5,-2002 # 80006890 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd884f>
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
    8000012e:	9da080e7          	jalr	-1574(ra) # 80002b04 <either_copyin>
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
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7f2080e7          	jalr	2034(ra) # 800019a6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	77a080e7          	jalr	1914(ra) # 80002936 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	4b8080e7          	jalr	1208(ra) # 80002682 <sleep>
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
    80000214:	89e080e7          	jalr	-1890(ra) # 80002aae <either_copyout>
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
    800002f2:	86c080e7          	jalr	-1940(ra) # 80002b5a <procdump>
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
    80000446:	2a4080e7          	jalr	676(ra) # 800026e6 <wakeup>
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
    80000478:	9a478793          	add	a5,a5,-1628 # 80024e18 <devsw>
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
    8000056e:	d4e50513          	add	a0,a0,-690 # 800082b8 <digits+0x278>
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
    80000894:	e56080e7          	jalr	-426(ra) # 800026e6 <wakeup>
    
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
    8000091e:	d68080e7          	jalr	-664(ra) # 80002682 <sleep>
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
    800009fc:	5b878793          	add	a5,a5,1464 # 80025fb0 <end>
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
    80000ace:	4e650513          	add	a0,a0,1254 # 80025fb0 <end>
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
    80000b70:	e1e080e7          	jalr	-482(ra) # 8000198a <mycpu>
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
    80000ba2:	dec080e7          	jalr	-532(ra) # 8000198a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	de0080e7          	jalr	-544(ra) # 8000198a <mycpu>
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
    80000bc6:	dc8080e7          	jalr	-568(ra) # 8000198a <mycpu>
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
    80000c06:	d88080e7          	jalr	-632(ra) # 8000198a <mycpu>
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
    80000c32:	d5c080e7          	jalr	-676(ra) # 8000198a <mycpu>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9051>
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
    80000e7e:	b00080e7          	jalr	-1280(ra) # 8000197a <cpuid>
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
    80000e9a:	ae4080e7          	jalr	-1308(ra) # 8000197a <cpuid>
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
    80000ebc:	fde080e7          	jalr	-34(ra) # 80002e96 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00006097          	auipc	ra,0x6
    80000ec4:	a10080e7          	jalr	-1520(ra) # 800068d0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	688080e7          	jalr	1672(ra) # 80002550 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	3d850513          	add	a0,a0,984 # 800082b8 <digits+0x278>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	3b850513          	add	a0,a0,952 # 800082b8 <digits+0x278>
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
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	f3e080e7          	jalr	-194(ra) # 80002e6e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	f5e080e7          	jalr	-162(ra) # 80002e96 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00006097          	auipc	ra,0x6
    80000f44:	97a080e7          	jalr	-1670(ra) # 800068ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00006097          	auipc	ra,0x6
    80000f4c:	988080e7          	jalr	-1656(ra) # 800068d0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	b7c080e7          	jalr	-1156(ra) # 80003acc <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	21a080e7          	jalr	538(ra) # 80004172 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	190080e7          	jalr	400(ra) # 800050f0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00006097          	auipc	ra,0x6
    80000f6c:	a70080e7          	jalr	-1424(ra) # 800069d8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d62080e7          	jalr	-670(ra) # 80001cd2 <userinit>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd9047>
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
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9050>
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

0000000080001830 <proc_mapstacks>:
//     current = current->next;
//   }
// }

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001830:	7139                	add	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	add	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001846:	00010497          	auipc	s1,0x10
    8000184a:	78a48493          	add	s1,s1,1930 # 80011fd0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	add	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001860:	00019a17          	auipc	s4,0x19
    80001864:	370a0a13          	add	s4,s4,880 # 8001abd0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	8591                	sra	a1,a1,0x4
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addw	a1,a1,1
    80001884:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000189a:	23048493          	add	s1,s1,560
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	add	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	add	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018c6:	7139                	add	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	add	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	31e50513          	add	a0,a0,798 # 80010c00 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	31e50513          	add	a0,a0,798 # 80010c18 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	00010497          	auipc	s1,0x10
    8000190e:	6c648493          	add	s1,s1,1734 # 80011fd0 <proc>
  {
    initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	add	s6,s6,-1818 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	add	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000192c:	00019997          	auipc	s3,0x19
    80001930:	2a498993          	add	s3,s3,676 # 8001abd0 <tickslock>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	8791                	sra	a5,a5,0x4
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addw	a5,a5,1
    80001954:	00d7979b          	sllw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	23048493          	add	s1,s1,560
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	add	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000197a:	1141                	add	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	add	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000198a:	1141                	add	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	add	s0,sp,16
    80001990:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	sll	a5,a5,0x7
  return c;
}
    80001996:	0000f517          	auipc	a0,0xf
    8000199a:	29a50513          	add	a0,a0,666 # 80010c30 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	add	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019a6:	1101                	add	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	add	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d6080e7          	jalr	470(ra) # 80000b86 <push_off>
    800019b8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	sll	a5,a5,0x7
    800019be:	0000f717          	auipc	a4,0xf
    800019c2:	24270713          	add	a4,a4,578 # 80010c00 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	25c080e7          	jalr	604(ra) # 80000c26 <pop_off>
  return p;
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	add	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019de:	1141                	add	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	298080e7          	jalr	664(ra) # 80000c86 <release>

  if (first)
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	eea7a783          	lw	a5,-278(a5) # 800088e0 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	560080e7          	jalr	1376(ra) # 80002f60 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	ec07a823          	sw	zero,-304(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	6d8080e7          	jalr	1752(ra) # 800040f2 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
{
    80001a24:	1101                	add	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a30:	0000f917          	auipc	s2,0xf
    80001a34:	1d090913          	add	s2,s2,464 # 80010c00 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	eae78793          	add	a5,a5,-338 # 800088f0 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	232080e7          	jalr	562(ra) # 80000c86 <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	add	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	add	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	add	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	8aa080e7          	jalr	-1878(ra) # 80001322 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	add	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a96:	05b2                	sll	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	600080e7          	jalr	1536(ra) # 80001098 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab2:	05b6                	sll	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5e2080e7          	jalr	1506(ra) # 80001098 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	add	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a54080e7          	jalr	-1452(ra) # 80001528 <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aea:	05b2                	sll	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	770080e7          	jalr	1904(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a2e080e7          	jalr	-1490(ra) # 80001528 <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	add	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	add	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b20:	05b2                	sll	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	73c080e7          	jalr	1852(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b34:	05b6                	sll	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	726080e7          	jalr	1830(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9e4080e7          	jalr	-1564(ra) # 80001528 <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	add	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	add	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	add	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e7c080e7          	jalr	-388(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b9a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	add	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	add	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bbc:	00010497          	auipc	s1,0x10
    80001bc0:	41448493          	add	s1,s1,1044 # 80011fd0 <proc>
    80001bc4:	00019917          	auipc	s2,0x19
    80001bc8:	00c90913          	add	s2,s2,12 # 8001abd0 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock); // Release lock if not UNUSED
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be4:	23048493          	add	s1,s1,560
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001bec:	4481                	li	s1,0
    80001bee:	a05d                	j	80001c94 <allocproc+0xe4>
  p->pid = allocpid(); // Assign PID
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;     // Mark process as USED
    80001bfa:	4785                	li	a5,1
    80001bfc:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < 31; i++)
    80001bfe:	17448793          	add	a5,s1,372
    80001c02:	1f048713          	add	a4,s1,496
    p->syscall_count[i] = 0;
    80001c06:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < 31; i++)
    80001c0a:	0791                	add	a5,a5,4
    80001c0c:	fee79de3          	bne	a5,a4,80001c06 <allocproc+0x56>
  p->tickets = 1; // since by default a process should have 1 ticket
    80001c10:	4785                	li	a5,1
    80001c12:	20f4a823          	sw	a5,528(s1)
  p->creation_time = ticks;
    80001c16:	00007797          	auipc	a5,0x7
    80001c1a:	d827e783          	lwu	a5,-638(a5) # 80008998 <ticks>
    80001c1e:	20f4bc23          	sd	a5,536(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	ec0080e7          	jalr	-320(ra) # 80000ae2 <kalloc>
    80001c2a:	892a                	mv	s2,a0
    80001c2c:	eca8                	sd	a0,88(s1)
    80001c2e:	c935                	beqz	a0,80001ca2 <allocproc+0xf2>
  p->pagetable = proc_pagetable(p);
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	e38080e7          	jalr	-456(ra) # 80001a6a <proc_pagetable>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c3e:	cd35                	beqz	a0,80001cba <allocproc+0x10a>
  memset(&p->context, 0, sizeof(p->context));
    80001c40:	07000613          	li	a2,112
    80001c44:	4581                	li	a1,0
    80001c46:	06048513          	add	a0,s1,96
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	084080e7          	jalr	132(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c52:	00000797          	auipc	a5,0x0
    80001c56:	d8c78793          	add	a5,a5,-628 # 800019de <forkret>
    80001c5a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5c:	60bc                	ld	a5,64(s1)
    80001c5e:	6705                	lui	a4,0x1
    80001c60:	97ba                	add	a5,a5,a4
    80001c62:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;     // Initialize runtime
    80001c64:	1604a423          	sw	zero,360(s1)
  p->etime = 0;     // Initialize exit time
    80001c68:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks; // Record creation time
    80001c6c:	00007797          	auipc	a5,0x7
    80001c70:	d2c7a783          	lw	a5,-724(a5) # 80008998 <ticks>
    80001c74:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001c78:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001c7c:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001c80:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001c84:	2004a223          	sw	zero,516(s1)
  p->ticks = 0;
    80001c88:	2204a423          	sw	zero,552(s1)
  p->priority = 0;
    80001c8c:	2204a023          	sw	zero,544(s1)
  p->lastscheduledticks = 0;
    80001c90:	2204a223          	sw	zero,548(s1)
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	add	sp,sp,32
    80001ca0:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	eb4080e7          	jalr	-332(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fd8080e7          	jalr	-40(ra) # 80000c86 <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	bff1                	j	80001c94 <allocproc+0xe4>
    freeproc(p);       // Clean up if allocation fails
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	e9c080e7          	jalr	-356(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fc0080e7          	jalr	-64(ra) # 80000c86 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	b7d1                	j	80001c94 <allocproc+0xe4>

0000000080001cd2 <userinit>:
{
    80001cd2:	1101                	add	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	add	s0,sp,32
  p = allocproc();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	ed4080e7          	jalr	-300(ra) # 80001bb0 <allocproc>
    80001ce4:	84aa                	mv	s1,a0
  initproc = p;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	caa7b523          	sd	a0,-854(a5) # 80008990 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cee:	03400613          	li	a2,52
    80001cf2:	00007597          	auipc	a1,0x7
    80001cf6:	c0e58593          	add	a1,a1,-1010 # 80008900 <initcode>
    80001cfa:	6928                	ld	a0,80(a0)
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	654080e7          	jalr	1620(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d04:	6785                	lui	a5,0x1
    80001d06:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d12:	4641                	li	a2,16
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	4ec58593          	add	a1,a1,1260 # 80008200 <digits+0x1c0>
    80001d1c:	15848513          	add	a0,s1,344
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	0f6080e7          	jalr	246(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	4e850513          	add	a0,a0,1256 # 80008210 <digits+0x1d0>
    80001d30:	00003097          	auipc	ra,0x3
    80001d34:	de0080e7          	jalr	-544(ra) # 80004b10 <namei>
    80001d38:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3c:	478d                	li	a5,3
    80001d3e:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001d40:	4785                	li	a5,1
    80001d42:	20f4a823          	sw	a5,528(s1)
  release(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	f3e080e7          	jalr	-194(ra) # 80000c86 <release>
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6105                	add	sp,sp,32
    80001d58:	8082                	ret

0000000080001d5a <growproc>:
{
    80001d5a:	1101                	add	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	e04a                	sd	s2,0(sp)
    80001d64:	1000                	add	s0,sp,32
    80001d66:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	c3e080e7          	jalr	-962(ra) # 800019a6 <myproc>
    80001d70:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d72:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d74:	01204c63          	bgtz	s2,80001d8c <growproc+0x32>
  else if (n < 0)
    80001d78:	02094663          	bltz	s2,80001da4 <growproc+0x4a>
  p->sz = sz;
    80001d7c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d7e:	4501                	li	a0,0
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6902                	ld	s2,0(sp)
    80001d88:	6105                	add	sp,sp,32
    80001d8a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d8c:	4691                	li	a3,4
    80001d8e:	00b90633          	add	a2,s2,a1
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	676080e7          	jalr	1654(ra) # 8000140a <uvmalloc>
    80001d9c:	85aa                	mv	a1,a0
    80001d9e:	fd79                	bnez	a0,80001d7c <growproc+0x22>
      return -1;
    80001da0:	557d                	li	a0,-1
    80001da2:	bff9                	j	80001d80 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da4:	00b90633          	add	a2,s2,a1
    80001da8:	6928                	ld	a0,80(a0)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	618080e7          	jalr	1560(ra) # 800013c2 <uvmdealloc>
    80001db2:	85aa                	mv	a1,a0
    80001db4:	b7e1                	j	80001d7c <growproc+0x22>

0000000080001db6 <fork>:
{
    80001db6:	7139                	add	sp,sp,-64
    80001db8:	fc06                	sd	ra,56(sp)
    80001dba:	f822                	sd	s0,48(sp)
    80001dbc:	f426                	sd	s1,40(sp)
    80001dbe:	f04a                	sd	s2,32(sp)
    80001dc0:	ec4e                	sd	s3,24(sp)
    80001dc2:	e852                	sd	s4,16(sp)
    80001dc4:	e456                	sd	s5,8(sp)
    80001dc6:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	bde080e7          	jalr	-1058(ra) # 800019a6 <myproc>
    80001dd0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	dde080e7          	jalr	-546(ra) # 80001bb0 <allocproc>
    80001dda:	12050663          	beqz	a0,80001f06 <fork+0x150>
    80001dde:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001de0:	048ab603          	ld	a2,72(s5)
    80001de4:	692c                	ld	a1,80(a0)
    80001de6:	050ab503          	ld	a0,80(s5)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	778080e7          	jalr	1912(ra) # 80001562 <uvmcopy>
    80001df2:	06054263          	bltz	a0,80001e56 <fork+0xa0>
  np->sz = p->sz;
    80001df6:	048ab783          	ld	a5,72(s5)
    80001dfa:	04f9b423          	sd	a5,72(s3)
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
    80001dfe:	210aa783          	lw	a5,528(s5)
    80001e02:	20f9a823          	sw	a5,528(s3)
  np->creation_time = ticks; // record its creation time
    80001e06:	00007797          	auipc	a5,0x7
    80001e0a:	b927e783          	lwu	a5,-1134(a5) # 80008998 <ticks>
    80001e0e:	20f9bc23          	sd	a5,536(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	058ab683          	ld	a3,88(s5)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	0589b703          	ld	a4,88(s3)
    80001e1c:	12068693          	add	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5)
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	add	a5,a5,32
    80001e38:	02070713          	add	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x6a>
  np->trapframe->a0 = 0;
    80001e40:	0589b783          	ld	a5,88(s3)
    80001e44:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e48:	0d0a8493          	add	s1,s5,208
    80001e4c:	0d098913          	add	s2,s3,208
    80001e50:	150a8a13          	add	s4,s5,336
    80001e54:	a00d                	j	80001e76 <fork+0xc0>
    freeproc(np);
    80001e56:	854e                	mv	a0,s3
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	d00080e7          	jalr	-768(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
    return -1;
    80001e6a:	597d                	li	s2,-1
    80001e6c:	a059                	j	80001ef2 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    80001e6e:	04a1                	add	s1,s1,8
    80001e70:	0921                	add	s2,s2,8
    80001e72:	01448b63          	beq	s1,s4,80001e88 <fork+0xd2>
    if (p->ofile[i])
    80001e76:	6088                	ld	a0,0(s1)
    80001e78:	d97d                	beqz	a0,80001e6e <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e7a:	00003097          	auipc	ra,0x3
    80001e7e:	308080e7          	jalr	776(ra) # 80005182 <filedup>
    80001e82:	00a93023          	sd	a0,0(s2)
    80001e86:	b7e5                	j	80001e6e <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e88:	150ab503          	ld	a0,336(s5)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	4a0080e7          	jalr	1184(ra) # 8000432c <idup>
    80001e94:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	158a8593          	add	a1,s5,344
    80001e9e:	15898513          	add	a0,s3,344
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	f74080e7          	jalr	-140(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001eaa:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	dd6080e7          	jalr	-554(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001eb8:	0000f497          	auipc	s1,0xf
    80001ebc:	d6048493          	add	s1,s1,-672 # 80010c18 <wait_lock>
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d10080e7          	jalr	-752(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001eca:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	db6080e7          	jalr	-586(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ed8:	854e                	mv	a0,s3
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	cf8080e7          	jalr	-776(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001ee2:	478d                	li	a5,3
    80001ee4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	d9c080e7          	jalr	-612(ra) # 80000c86 <release>
}
    80001ef2:	854a                	mv	a0,s2
    80001ef4:	70e2                	ld	ra,56(sp)
    80001ef6:	7442                	ld	s0,48(sp)
    80001ef8:	74a2                	ld	s1,40(sp)
    80001efa:	7902                	ld	s2,32(sp)
    80001efc:	69e2                	ld	s3,24(sp)
    80001efe:	6a42                	ld	s4,16(sp)
    80001f00:	6aa2                	ld	s5,8(sp)
    80001f02:	6121                	add	sp,sp,64
    80001f04:	8082                	ret
    return -1;
    80001f06:	597d                	li	s2,-1
    80001f08:	b7ed                	j	80001ef2 <fork+0x13c>

0000000080001f0a <simple_atol>:
{
    80001f0a:	1141                	add	sp,sp,-16
    80001f0c:	e422                	sd	s0,8(sp)
    80001f0e:	0800                	add	s0,sp,16
  for (int i = 0; str[i] != '\0'; ++i)
    80001f10:	00054683          	lbu	a3,0(a0)
    80001f14:	c295                	beqz	a3,80001f38 <simple_atol+0x2e>
    80001f16:	00150713          	add	a4,a0,1
  long res = 0;
    80001f1a:	4501                	li	a0,0
    res = res * 10 + str[i] - '0';
    80001f1c:	00251793          	sll	a5,a0,0x2
    80001f20:	97aa                	add	a5,a5,a0
    80001f22:	0786                	sll	a5,a5,0x1
    80001f24:	97b6                	add	a5,a5,a3
    80001f26:	fd078513          	add	a0,a5,-48
  for (int i = 0; str[i] != '\0'; ++i)
    80001f2a:	0705                	add	a4,a4,1
    80001f2c:	fff74683          	lbu	a3,-1(a4)
    80001f30:	f6f5                	bnez	a3,80001f1c <simple_atol+0x12>
}
    80001f32:	6422                	ld	s0,8(sp)
    80001f34:	0141                	add	sp,sp,16
    80001f36:	8082                	ret
  long res = 0;
    80001f38:	4501                	li	a0,0
  return res;
    80001f3a:	bfe5                	j	80001f32 <simple_atol+0x28>

0000000080001f3c <get_random_seed>:
{
    80001f3c:	1141                	add	sp,sp,-16
    80001f3e:	e422                	sd	s0,8(sp)
    80001f40:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80001f42:	00007697          	auipc	a3,0x7
    80001f46:	9a668693          	add	a3,a3,-1626 # 800088e8 <seed>
    80001f4a:	629c                	ld	a5,0(a3)
    80001f4c:	41c65737          	lui	a4,0x41c65
    80001f50:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80001f54:	02e787b3          	mul	a5,a5,a4
    80001f58:	670d                	lui	a4,0x3
    80001f5a:	03970713          	add	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80001f5e:	97ba                	add	a5,a5,a4
    80001f60:	1786                	sll	a5,a5,0x21
    80001f62:	9385                	srl	a5,a5,0x21
    80001f64:	e29c                	sd	a5,0(a3)
}
    80001f66:	6509                	lui	a0,0x2
    80001f68:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    80001f6c:	02a7f533          	remu	a0,a5,a0
    80001f70:	6422                	ld	s0,8(sp)
    80001f72:	0141                	add	sp,sp,16
    80001f74:	8082                	ret

0000000080001f76 <long_to_padded_string>:
{
    80001f76:	1141                	add	sp,sp,-16
    80001f78:	e422                	sd	s0,8(sp)
    80001f7a:	0800                	add	s0,sp,16
  long temp = num;
    80001f7c:	87aa                	mv	a5,a0
  int len = 0;
    80001f7e:	4681                	li	a3,0
    temp /= 10;
    80001f80:	4329                	li	t1,10
  } while (temp > 0);
    80001f82:	48a5                	li	a7,9
    len++;
    80001f84:	0016871b          	addw	a4,a3,1
    80001f88:	0007069b          	sext.w	a3,a4
    temp /= 10;
    80001f8c:	883e                	mv	a6,a5
    80001f8e:	0267c7b3          	div	a5,a5,t1
  } while (temp > 0);
    80001f92:	ff08c9e3          	blt	a7,a6,80001f84 <long_to_padded_string+0xe>
  int padding = total_length - len;
    80001f96:	40e5873b          	subw	a4,a1,a4
    80001f9a:	0007089b          	sext.w	a7,a4
  for (int i = 0; i < padding; i++)
    80001f9e:	01105c63          	blez	a7,80001fb6 <long_to_padded_string+0x40>
    80001fa2:	87b2                	mv	a5,a2
    80001fa4:	00c88833          	add	a6,a7,a2
    result[i] = '0';
    80001fa8:	03000693          	li	a3,48
    80001fac:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < padding; i++)
    80001fb0:	0785                	add	a5,a5,1
    80001fb2:	ff079de3          	bne	a5,a6,80001fac <long_to_padded_string+0x36>
  for (int i = total_length - 1; i >= padding; i--)
    80001fb6:	fff5879b          	addw	a5,a1,-1
    80001fba:	0317ca63          	blt	a5,a7,80001fee <long_to_padded_string+0x78>
    80001fbe:	97b2                	add	a5,a5,a2
    80001fc0:	ffe60813          	add	a6,a2,-2 # ffe <_entry-0x7ffff002>
    80001fc4:	982e                	add	a6,a6,a1
    80001fc6:	fff5869b          	addw	a3,a1,-1
    80001fca:	40e6873b          	subw	a4,a3,a4
    80001fce:	1702                	sll	a4,a4,0x20
    80001fd0:	9301                	srl	a4,a4,0x20
    80001fd2:	40e80833          	sub	a6,a6,a4
    result[i] = (num % 10) + '0';
    80001fd6:	46a9                	li	a3,10
    80001fd8:	02d56733          	rem	a4,a0,a3
    80001fdc:	0307071b          	addw	a4,a4,48
    80001fe0:	00e78023          	sb	a4,0(a5)
    num /= 10;
    80001fe4:	02d54533          	div	a0,a0,a3
  for (int i = total_length - 1; i >= padding; i--)
    80001fe8:	17fd                	add	a5,a5,-1
    80001fea:	ff0797e3          	bne	a5,a6,80001fd8 <long_to_padded_string+0x62>
  result[total_length] = '\0'; // Null-terminate the string
    80001fee:	962e                	add	a2,a2,a1
    80001ff0:	00060023          	sb	zero,0(a2)
}
    80001ff4:	6422                	ld	s0,8(sp)
    80001ff6:	0141                	add	sp,sp,16
    80001ff8:	8082                	ret

0000000080001ffa <pseudo_rand_num_generator>:
{
    80001ffa:	7119                	add	sp,sp,-128
    80001ffc:	fc86                	sd	ra,120(sp)
    80001ffe:	f8a2                	sd	s0,112(sp)
    80002000:	f4a6                	sd	s1,104(sp)
    80002002:	f0ca                	sd	s2,96(sp)
    80002004:	ecce                	sd	s3,88(sp)
    80002006:	e8d2                	sd	s4,80(sp)
    80002008:	e4d6                	sd	s5,72(sp)
    8000200a:	e0da                	sd	s6,64(sp)
    8000200c:	fc5e                	sd	s7,56(sp)
    8000200e:	f862                	sd	s8,48(sp)
    80002010:	f466                	sd	s9,40(sp)
    80002012:	0100                	add	s0,sp,128
    80002014:	84aa                	mv	s1,a0
    80002016:	8aae                	mv	s5,a1
  if (iterations == 0 && lst_index > 0)
    80002018:	e1a1                	bnez	a1,80002058 <pseudo_rand_num_generator+0x5e>
    8000201a:	00007797          	auipc	a5,0x7
    8000201e:	96e7a783          	lw	a5,-1682(a5) # 80008988 <lst_index>
    80002022:	02f04263          	bgtz	a5,80002046 <pseudo_rand_num_generator+0x4c>
  int seed_size = strlen(initial_seed);
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	e22080e7          	jalr	-478(ra) # 80000e48 <strlen>
    8000202e:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002030:	8526                	mv	a0,s1
    80002032:	00000097          	auipc	ra,0x0
    80002036:	ed8080e7          	jalr	-296(ra) # 80001f0a <simple_atol>
  if (seed_val == 0)
    8000203a:	e561                	bnez	a0,80002102 <pseudo_rand_num_generator+0x108>
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	f00080e7          	jalr	-256(ra) # 80001f3c <get_random_seed>
    80002044:	a02d                	j	8000206e <pseudo_rand_num_generator+0x74>
    return lst[lst_index - 1]; // Return the last generated number
    80002046:	37fd                	addw	a5,a5,-1
    80002048:	078a                	sll	a5,a5,0x2
    8000204a:	0000f717          	auipc	a4,0xf
    8000204e:	fe670713          	add	a4,a4,-26 # 80011030 <lst>
    80002052:	97ba                	add	a5,a5,a4
    80002054:	4388                	lw	a0,0(a5)
    80002056:	a0d1                	j	8000211a <pseudo_rand_num_generator+0x120>
  int seed_size = strlen(initial_seed);
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	df0080e7          	jalr	-528(ra) # 80000e48 <strlen>
    80002060:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002062:	8526                	mv	a0,s1
    80002064:	00000097          	auipc	ra,0x0
    80002068:	ea6080e7          	jalr	-346(ra) # 80001f0a <simple_atol>
  if (seed_val == 0)
    8000206c:	d961                	beqz	a0,8000203c <pseudo_rand_num_generator+0x42>
  for (int i = 0; i < iterations; i++)
    8000206e:	09505a63          	blez	s5,80002102 <pseudo_rand_num_generator+0x108>
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    80002072:	00191c9b          	sllw	s9,s2,0x1
    int mid_start = seed_size / 2;
    80002076:	01f9579b          	srlw	a5,s2,0x1f
    8000207a:	012787bb          	addw	a5,a5,s2
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    8000207e:	4017d79b          	sraw	a5,a5,0x1
    80002082:	f8040713          	add	a4,s0,-128
    80002086:	00f70bb3          	add	s7,a4,a5
    8000208a:	4481                	li	s1,0
    char new_seed[seed_size + 1];
    8000208c:	00190b1b          	addw	s6,s2,1
    80002090:	0b3d                	add	s6,s6,15
    80002092:	ff0b7b13          	and	s6,s6,-16
    lst[lst_index++] = simple_atol(new_seed);
    80002096:	00007997          	auipc	s3,0x7
    8000209a:	8f298993          	add	s3,s3,-1806 # 80008988 <lst_index>
    8000209e:	0000fc17          	auipc	s8,0xf
    800020a2:	f92c0c13          	add	s8,s8,-110 # 80011030 <lst>
  {
    800020a6:	8a0a                	mv	s4,sp
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    800020a8:	f8040613          	add	a2,s0,-128
    800020ac:	85e6                	mv	a1,s9
    800020ae:	02a50533          	mul	a0,a0,a0
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	ec4080e7          	jalr	-316(ra) # 80001f76 <long_to_padded_string>
    char new_seed[seed_size + 1];
    800020ba:	41610133          	sub	sp,sp,s6
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800020be:	864a                	mv	a2,s2
    800020c0:	85de                	mv	a1,s7
    800020c2:	850a                	mv	a0,sp
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	d16080e7          	jalr	-746(ra) # 80000dda <strncpy>
    new_seed[seed_size] = '\0';                         // Null-terminate
    800020cc:	012107b3          	add	a5,sp,s2
    800020d0:	00078023          	sb	zero,0(a5)
    lst[lst_index++] = simple_atol(new_seed);
    800020d4:	850a                	mv	a0,sp
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	e34080e7          	jalr	-460(ra) # 80001f0a <simple_atol>
    800020de:	0009a783          	lw	a5,0(s3)
    800020e2:	0017871b          	addw	a4,a5,1
    800020e6:	00e9a023          	sw	a4,0(s3)
    800020ea:	078a                	sll	a5,a5,0x2
    800020ec:	97e2                	add	a5,a5,s8
    800020ee:	c388                	sw	a0,0(a5)
    seed_val = simple_atol(new_seed);
    800020f0:	850a                	mv	a0,sp
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	e18080e7          	jalr	-488(ra) # 80001f0a <simple_atol>
    800020fa:	8152                	mv	sp,s4
  for (int i = 0; i < iterations; i++)
    800020fc:	2485                	addw	s1,s1,1
    800020fe:	fa9a94e3          	bne	s5,s1,800020a6 <pseudo_rand_num_generator+0xac>
  return lst[lst_index - 1];
    80002102:	00007797          	auipc	a5,0x7
    80002106:	8867a783          	lw	a5,-1914(a5) # 80008988 <lst_index>
    8000210a:	37fd                	addw	a5,a5,-1
    8000210c:	078a                	sll	a5,a5,0x2
    8000210e:	0000f717          	auipc	a4,0xf
    80002112:	f2270713          	add	a4,a4,-222 # 80011030 <lst>
    80002116:	97ba                	add	a5,a5,a4
    80002118:	4388                	lw	a0,0(a5)
}
    8000211a:	f8040113          	add	sp,s0,-128
    8000211e:	70e6                	ld	ra,120(sp)
    80002120:	7446                	ld	s0,112(sp)
    80002122:	74a6                	ld	s1,104(sp)
    80002124:	7906                	ld	s2,96(sp)
    80002126:	69e6                	ld	s3,88(sp)
    80002128:	6a46                	ld	s4,80(sp)
    8000212a:	6aa6                	ld	s5,72(sp)
    8000212c:	6b06                	ld	s6,64(sp)
    8000212e:	7be2                	ld	s7,56(sp)
    80002130:	7c42                	ld	s8,48(sp)
    80002132:	7ca2                	ld	s9,40(sp)
    80002134:	6109                	add	sp,sp,128
    80002136:	8082                	ret

0000000080002138 <int_to_string>:
{
    80002138:	1141                	add	sp,sp,-16
    8000213a:	e422                	sd	s0,8(sp)
    8000213c:	0800                	add	s0,sp,16
  int temp = num;
    8000213e:	872a                	mv	a4,a0
  int len = 0;
    80002140:	4781                	li	a5,0
    temp /= 10;
    80002142:	48a9                	li	a7,10
  } while (temp > 0);
    80002144:	4825                	li	a6,9
    len++;
    80002146:	863e                	mv	a2,a5
    80002148:	2785                	addw	a5,a5,1
    temp /= 10;
    8000214a:	86ba                	mv	a3,a4
    8000214c:	0317473b          	divw	a4,a4,a7
  } while (temp > 0);
    80002150:	fed84be3          	blt	a6,a3,80002146 <int_to_string+0xe>
  result[len] = '\0'; // Null-terminate the string
    80002154:	97ae                	add	a5,a5,a1
    80002156:	00078023          	sb	zero,0(a5)
  for (int i = len - 1; i >= 0; i--)
    8000215a:	02064663          	bltz	a2,80002186 <int_to_string+0x4e>
    8000215e:	00c587b3          	add	a5,a1,a2
    80002162:	fff58693          	add	a3,a1,-1
    80002166:	96b2                	add	a3,a3,a2
    80002168:	1602                	sll	a2,a2,0x20
    8000216a:	9201                	srl	a2,a2,0x20
    8000216c:	8e91                	sub	a3,a3,a2
    result[i] = (num % 10) + '0';
    8000216e:	4629                	li	a2,10
    80002170:	02c5673b          	remw	a4,a0,a2
    80002174:	0307071b          	addw	a4,a4,48
    80002178:	00e78023          	sb	a4,0(a5)
    num /= 10;
    8000217c:	02c5453b          	divw	a0,a0,a2
  for (int i = len - 1; i >= 0; i--)
    80002180:	17fd                	add	a5,a5,-1
    80002182:	fed797e3          	bne	a5,a3,80002170 <int_to_string+0x38>
}
    80002186:	6422                	ld	s0,8(sp)
    80002188:	0141                	add	sp,sp,16
    8000218a:	8082                	ret

000000008000218c <simple_rand>:
{
    8000218c:	1141                	add	sp,sp,-16
    8000218e:	e422                	sd	s0,8(sp)
    80002190:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80002192:	00006697          	auipc	a3,0x6
    80002196:	75668693          	add	a3,a3,1878 # 800088e8 <seed>
    8000219a:	629c                	ld	a5,0(a3)
    8000219c:	41c65737          	lui	a4,0x41c65
    800021a0:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    800021a4:	02e787b3          	mul	a5,a5,a4
    800021a8:	0012d737          	lui	a4,0x12d
    800021ac:	68770713          	add	a4,a4,1671 # 12d687 <_entry-0x7fed2979>
    800021b0:	97ba                	add	a5,a5,a4
    800021b2:	1786                	sll	a5,a5,0x21
    800021b4:	9385                	srl	a5,a5,0x21
    800021b6:	e29c                	sd	a5,0(a3)
}
    800021b8:	6509                	lui	a0,0x2
    800021ba:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    800021be:	02a7f533          	remu	a0,a5,a0
    800021c2:	6422                	ld	s0,8(sp)
    800021c4:	0141                	add	sp,sp,16
    800021c6:	8082                	ret

00000000800021c8 <random_at_most>:
{
    800021c8:	1101                	add	sp,sp,-32
    800021ca:	ec06                	sd	ra,24(sp)
    800021cc:	e822                	sd	s0,16(sp)
    800021ce:	e426                	sd	s1,8(sp)
    800021d0:	1000                	add	s0,sp,32
    800021d2:	84aa                	mv	s1,a0
  int random_num = simple_rand(); // Use the LCG for random generation
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	fb8080e7          	jalr	-72(ra) # 8000218c <simple_rand>
  return 1 + (random_num % max);  // Return a number in the range [1, max]
    800021dc:	0295653b          	remw	a0,a0,s1
}
    800021e0:	2505                	addw	a0,a0,1
    800021e2:	60e2                	ld	ra,24(sp)
    800021e4:	6442                	ld	s0,16(sp)
    800021e6:	64a2                	ld	s1,8(sp)
    800021e8:	6105                	add	sp,sp,32
    800021ea:	8082                	ret

00000000800021ec <round_robin_scheduler>:
{
    800021ec:	7139                	add	sp,sp,-64
    800021ee:	fc06                	sd	ra,56(sp)
    800021f0:	f822                	sd	s0,48(sp)
    800021f2:	f426                	sd	s1,40(sp)
    800021f4:	f04a                	sd	s2,32(sp)
    800021f6:	ec4e                	sd	s3,24(sp)
    800021f8:	e852                	sd	s4,16(sp)
    800021fa:	e456                	sd	s5,8(sp)
    800021fc:	e05a                	sd	s6,0(sp)
    800021fe:	0080                	add	s0,sp,64
    80002200:	8792                	mv	a5,tp
  int id = r_tp();
    80002202:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002204:	00779a93          	sll	s5,a5,0x7
    80002208:	0000f717          	auipc	a4,0xf
    8000220c:	9f870713          	add	a4,a4,-1544 # 80010c00 <pid_lock>
    80002210:	9756                	add	a4,a4,s5
    80002212:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002216:	0000f717          	auipc	a4,0xf
    8000221a:	a2270713          	add	a4,a4,-1502 # 80010c38 <cpus+0x8>
    8000221e:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002220:	498d                	li	s3,3
        p->state = RUNNING;
    80002222:	4b11                	li	s6,4
        c->proc = p;
    80002224:	079e                	sll	a5,a5,0x7
    80002226:	0000fa17          	auipc	s4,0xf
    8000222a:	9daa0a13          	add	s4,s4,-1574 # 80010c00 <pid_lock>
    8000222e:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002230:	00019917          	auipc	s2,0x19
    80002234:	9a090913          	add	s2,s2,-1632 # 8001abd0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002238:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000223c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002240:	10079073          	csrw	sstatus,a5
    80002244:	00010497          	auipc	s1,0x10
    80002248:	d8c48493          	add	s1,s1,-628 # 80011fd0 <proc>
    8000224c:	a811                	j	80002260 <round_robin_scheduler+0x74>
      release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a36080e7          	jalr	-1482(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002258:	23048493          	add	s1,s1,560
    8000225c:	fd248ee3          	beq	s1,s2,80002238 <round_robin_scheduler+0x4c>
      acquire(&p->lock);
    80002260:	8526                	mv	a0,s1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	970080e7          	jalr	-1680(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000226a:	4c9c                	lw	a5,24(s1)
    8000226c:	ff3791e3          	bne	a5,s3,8000224e <round_robin_scheduler+0x62>
        p->state = RUNNING;
    80002270:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002274:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002278:	06048593          	add	a1,s1,96
    8000227c:	8556                	mv	a0,s5
    8000227e:	00001097          	auipc	ra,0x1
    80002282:	b86080e7          	jalr	-1146(ra) # 80002e04 <swtch>
        c->proc = 0;
    80002286:	020a3823          	sd	zero,48(s4)
    8000228a:	b7d1                	j	8000224e <round_robin_scheduler+0x62>

000000008000228c <lottery_scheduler>:
{
    8000228c:	715d                	add	sp,sp,-80
    8000228e:	e486                	sd	ra,72(sp)
    80002290:	e0a2                	sd	s0,64(sp)
    80002292:	fc26                	sd	s1,56(sp)
    80002294:	f84a                	sd	s2,48(sp)
    80002296:	f44e                	sd	s3,40(sp)
    80002298:	f052                	sd	s4,32(sp)
    8000229a:	ec56                	sd	s5,24(sp)
    8000229c:	e85a                	sd	s6,16(sp)
    8000229e:	e45e                	sd	s7,8(sp)
    800022a0:	e062                	sd	s8,0(sp)
    800022a2:	0880                	add	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a4:	8792                	mv	a5,tp
  int id = r_tp();
    800022a6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022a8:	00779693          	sll	a3,a5,0x7
    800022ac:	0000f717          	auipc	a4,0xf
    800022b0:	95470713          	add	a4,a4,-1708 # 80010c00 <pid_lock>
    800022b4:	9736                	add	a4,a4,a3
    800022b6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &winner->context);
    800022ba:	0000f717          	auipc	a4,0xf
    800022be:	97e70713          	add	a4,a4,-1666 # 80010c38 <cpus+0x8>
    800022c2:	00e68c33          	add	s8,a3,a4
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    800022c6:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800022c8:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800022ca:	00019917          	auipc	s2,0x19
    800022ce:	90690913          	add	s2,s2,-1786 # 8001abd0 <tickslock>
        c->proc = winner;
    800022d2:	0000fb17          	auipc	s6,0xf
    800022d6:	92eb0b13          	add	s6,s6,-1746 # 80010c00 <pid_lock>
    800022da:	9b36                	add	s6,s6,a3
    800022dc:	a80d                	j	8000230e <lottery_scheduler+0x82>
      release(&p->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9a6080e7          	jalr	-1626(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022e8:	23048493          	add	s1,s1,560
    800022ec:	01248f63          	beq	s1,s2,8000230a <lottery_scheduler+0x7e>
      acquire(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8e0080e7          	jalr	-1824(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    800022fa:	4c9c                	lw	a5,24(s1)
    800022fc:	ff3791e3          	bne	a5,s3,800022de <lottery_scheduler+0x52>
        total_tickets += p->tickets; // Accumulate total tickets
    80002300:	2104a783          	lw	a5,528(s1)
    80002304:	01478a3b          	addw	s4,a5,s4
    80002308:	bfd9                	j	800022de <lottery_scheduler+0x52>
    if (total_tickets == 0)
    8000230a:	000a1e63          	bnez	s4,80002326 <lottery_scheduler+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002312:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002316:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    8000231a:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    8000231c:	00010497          	auipc	s1,0x10
    80002320:	cb448493          	add	s1,s1,-844 # 80011fd0 <proc>
    80002324:	b7f1                	j	800022f0 <lottery_scheduler+0x64>
    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    80002326:	8552                	mv	a0,s4
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	ea0080e7          	jalr	-352(ra) # 800021c8 <random_at_most>
    80002330:	8baa                	mv	s7,a0
    int ticket_counter = 0;                             // Track ticket count while iterating over processes
    80002332:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002334:	00010497          	auipc	s1,0x10
    80002338:	c9c48493          	add	s1,s1,-868 # 80011fd0 <proc>
    8000233c:	a811                	j	80002350 <lottery_scheduler+0xc4>
      release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	946080e7          	jalr	-1722(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002348:	23048493          	add	s1,s1,560
    8000234c:	fd2481e3          	beq	s1,s2,8000230e <lottery_scheduler+0x82>
      if (p == 0)
    80002350:	dce5                	beqz	s1,80002348 <lottery_scheduler+0xbc>
      acquire(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87e080e7          	jalr	-1922(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000235c:	4c9c                	lw	a5,24(s1)
    8000235e:	ff3790e3          	bne	a5,s3,8000233e <lottery_scheduler+0xb2>
        ticket_counter += p->tickets; // Increment the ticket counter
    80002362:	2104a783          	lw	a5,528(s1)
    80002366:	01478a3b          	addw	s4,a5,s4
        if (ticket_counter >= winning_ticket)
    8000236a:	fd7a4ae3          	blt	s4,s7,8000233e <lottery_scheduler+0xb2>
            release(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	916080e7          	jalr	-1770(ra) # 80000c86 <release>
      acquire(&winner->lock);
    80002378:	8a26                	mv	s4,s1
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	856080e7          	jalr	-1962(ra) # 80000bd2 <acquire>
      if (winner->state == RUNNABLE)
    80002384:	4c9c                	lw	a5,24(s1)
    80002386:	01378863          	beq	a5,s3,80002396 <lottery_scheduler+0x10a>
      release(&winner->lock);
    8000238a:	8552                	mv	a0,s4
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8fa080e7          	jalr	-1798(ra) # 80000c86 <release>
    80002394:	bfad                	j	8000230e <lottery_scheduler+0x82>
        winner->state = RUNNING;
    80002396:	4791                	li	a5,4
    80002398:	cc9c                	sw	a5,24(s1)
        c->proc = winner;
    8000239a:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &winner->context);
    8000239e:	06048593          	add	a1,s1,96
    800023a2:	8562                	mv	a0,s8
    800023a4:	00001097          	auipc	ra,0x1
    800023a8:	a60080e7          	jalr	-1440(ra) # 80002e04 <swtch>
        c->proc = 0;
    800023ac:	020b3823          	sd	zero,48(s6)
    800023b0:	bfe9                	j	8000238a <lottery_scheduler+0xfe>

00000000800023b2 <get_ticks_for_priority>:
{
    800023b2:	1141                	add	sp,sp,-16
    800023b4:	e422                	sd	s0,8(sp)
    800023b6:	0800                	add	s0,sp,16
  switch (priority)
    800023b8:	4709                	li	a4,2
    800023ba:	00e50f63          	beq	a0,a4,800023d8 <get_ticks_for_priority+0x26>
    800023be:	87aa                	mv	a5,a0
    800023c0:	470d                	li	a4,3
    return TICKS_3; // 16 ticks for priority 3
    800023c2:	4541                	li	a0,16
  switch (priority)
    800023c4:	00e78763          	beq	a5,a4,800023d2 <get_ticks_for_priority+0x20>
    800023c8:	4705                	li	a4,1
    800023ca:	4511                	li	a0,4
    800023cc:	00e78363          	beq	a5,a4,800023d2 <get_ticks_for_priority+0x20>
    return TICKS_0; // 1 tick for priority 0
    800023d0:	4505                	li	a0,1
}
    800023d2:	6422                	ld	s0,8(sp)
    800023d4:	0141                	add	sp,sp,16
    800023d6:	8082                	ret
    return TICKS_2; // 8 ticks for priority 2
    800023d8:	4521                	li	a0,8
    800023da:	bfe5                	j	800023d2 <get_ticks_for_priority+0x20>

00000000800023dc <mlfq_scheduler>:
{
    800023dc:	711d                	add	sp,sp,-96
    800023de:	ec86                	sd	ra,88(sp)
    800023e0:	e8a2                	sd	s0,80(sp)
    800023e2:	e4a6                	sd	s1,72(sp)
    800023e4:	e0ca                	sd	s2,64(sp)
    800023e6:	fc4e                	sd	s3,56(sp)
    800023e8:	f852                	sd	s4,48(sp)
    800023ea:	f456                	sd	s5,40(sp)
    800023ec:	f05a                	sd	s6,32(sp)
    800023ee:	ec5e                	sd	s7,24(sp)
    800023f0:	e862                	sd	s8,16(sp)
    800023f2:	e466                	sd	s9,8(sp)
    800023f4:	1080                	add	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f6:	8a92                	mv	s5,tp
  int id = r_tp();
    800023f8:	2a81                	sext.w	s5,s5
  c->proc = 0;
    800023fa:	007a9713          	sll	a4,s5,0x7
    800023fe:	0000f797          	auipc	a5,0xf
    80002402:	80278793          	add	a5,a5,-2046 # 80010c00 <pid_lock>
    80002406:	97ba                	add	a5,a5,a4
    80002408:	0207b823          	sd	zero,48(a5)
        for (struct proc *i = proc; i < &proc[NPROC]; i++)
    8000240c:	00018497          	auipc	s1,0x18
    80002410:	7c448493          	add	s1,s1,1988 # 8001abd0 <tickslock>
              c->proc = p;
    80002414:	0000eb97          	auipc	s7,0xe
    80002418:	7ecb8b93          	add	s7,s7,2028 # 80010c00 <pid_lock>
    8000241c:	8aba                	mv	s5,a4
              swtch(&c->context, &p->context);
    8000241e:	0000fb17          	auipc	s6,0xf
    80002422:	81ab0b13          	add	s6,s6,-2022 # 80010c38 <cpus+0x8>
    80002426:	9b3a                	add	s6,s6,a4
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002428:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000242c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002430:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002434:	00010a17          	auipc	s4,0x10
    80002438:	bfca0a13          	add	s4,s4,-1028 # 80012030 <proc+0x60>
    8000243c:	00010917          	auipc	s2,0x10
    80002440:	b9490913          	add	s2,s2,-1132 # 80011fd0 <proc>
      if (p->state == RUNNABLE)
    80002444:	498d                	li	s3,3
          if (p->priority == 3)
    80002446:	4c81                	li	s9,0
    80002448:	a03d                	j	80002476 <mlfq_scheduler+0x9a>
        for (struct proc *i = proc; i < &proc[NPROC]; i++)
    8000244a:	23078793          	add	a5,a5,560
    8000244e:	04978463          	beq	a5,s1,80002496 <mlfq_scheduler+0xba>
          if (i->priority < p->priority && i->state == RUNNABLE)
    80002452:	2207a703          	lw	a4,544(a5)
    80002456:	fed75ae3          	bge	a4,a3,8000244a <mlfq_scheduler+0x6e>
    8000245a:	4f98                	lw	a4,24(a5)
    8000245c:	ff3717e3          	bne	a4,s3,8000244a <mlfq_scheduler+0x6e>
      release(&p->lock);
    80002460:	854a                	mv	a0,s2
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	824080e7          	jalr	-2012(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000246a:	23090913          	add	s2,s2,560
    8000246e:	230a0a13          	add	s4,s4,560
    80002472:	fa990be3          	beq	s2,s1,80002428 <mlfq_scheduler+0x4c>
      acquire(&p->lock);
    80002476:	854a                	mv	a0,s2
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	75a080e7          	jalr	1882(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80002480:	01892783          	lw	a5,24(s2)
    80002484:	fd379ee3          	bne	a5,s3,80002460 <mlfq_scheduler+0x84>
          if (i->priority < p->priority && i->state == RUNNABLE)
    80002488:	22092683          	lw	a3,544(s2)
        for (struct proc *i = proc; i < &proc[NPROC]; i++)
    8000248c:	00010797          	auipc	a5,0x10
    80002490:	b4478793          	add	a5,a5,-1212 # 80011fd0 <proc>
    80002494:	bf7d                	j	80002452 <mlfq_scheduler+0x76>
          for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002496:	00010797          	auipc	a5,0x10
    8000249a:	b3a78793          	add	a5,a5,-1222 # 80011fd0 <proc>
    8000249e:	a029                	j	800024a8 <mlfq_scheduler+0xcc>
    800024a0:	23078793          	add	a5,a5,560
    800024a4:	08978a63          	beq	a5,s1,80002538 <mlfq_scheduler+0x15c>
            if (i->priority == p->priority && i->lastscheduledticks > p->lastscheduledticks && i->state == RUNNABLE)
    800024a8:	2207a703          	lw	a4,544(a5)
    800024ac:	fed71ae3          	bne	a4,a3,800024a0 <mlfq_scheduler+0xc4>
    800024b0:	2247a603          	lw	a2,548(a5)
    800024b4:	22492703          	lw	a4,548(s2)
    800024b8:	fec754e3          	bge	a4,a2,800024a0 <mlfq_scheduler+0xc4>
    800024bc:	4f98                	lw	a4,24(a5)
    800024be:	ff3711e3          	bne	a4,s3,800024a0 <mlfq_scheduler+0xc4>
              flag = 1;
    800024c2:	4785                	li	a5,1
          if (p->priority == 3)
    800024c4:	f9368ee3          	beq	a3,s3,80002460 <mlfq_scheduler+0x84>
    800024c8:	a89d                	j	8000253e <mlfq_scheduler+0x162>
              p->state = RUNNING;
    800024ca:	4791                	li	a5,4
    800024cc:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    800024d0:	015b8c33          	add	s8,s7,s5
    800024d4:	032c3823          	sd	s2,48(s8)
              swtch(&c->context, &p->context);
    800024d8:	85d2                	mv	a1,s4
    800024da:	855a                	mv	a0,s6
    800024dc:	00001097          	auipc	ra,0x1
    800024e0:	928080e7          	jalr	-1752(ra) # 80002e04 <swtch>
              c->proc = 0;
    800024e4:	020c3823          	sd	zero,48(s8)
              release(&p->lock);
    800024e8:	854a                	mv	a0,s2
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	79c080e7          	jalr	1948(ra) # 80000c86 <release>
              continue;
    800024f2:	bfa5                	j	8000246a <mlfq_scheduler+0x8e>
            for (struct proc *i = proc; i < &proc[NPROC]; i++)
    800024f4:	23078793          	add	a5,a5,560
    800024f8:	02978063          	beq	a5,s1,80002518 <mlfq_scheduler+0x13c>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    800024fc:	2207b703          	ld	a4,544(a5)
    80002500:	fed71ae3          	bne	a4,a3,800024f4 <mlfq_scheduler+0x118>
    80002504:	16c7a603          	lw	a2,364(a5)
    80002508:	16c92703          	lw	a4,364(s2)
    8000250c:	fee674e3          	bgeu	a2,a4,800024f4 <mlfq_scheduler+0x118>
    80002510:	4f98                	lw	a4,24(a5)
    80002512:	feb711e3          	bne	a4,a1,800024f4 <mlfq_scheduler+0x118>
    80002516:	b7a9                	j	80002460 <mlfq_scheduler+0x84>
              p->state = RUNNING;
    80002518:	4791                	li	a5,4
    8000251a:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    8000251e:	015b8c33          	add	s8,s7,s5
    80002522:	032c3823          	sd	s2,48(s8)
              swtch(&c->context, &p->context);
    80002526:	85d2                	mv	a1,s4
    80002528:	855a                	mv	a0,s6
    8000252a:	00001097          	auipc	ra,0x1
    8000252e:	8da080e7          	jalr	-1830(ra) # 80002e04 <swtch>
              c->proc = 0;
    80002532:	020c3823          	sd	zero,48(s8)
    80002536:	b72d                	j	80002460 <mlfq_scheduler+0x84>
          if (p->priority == 3)
    80002538:	f93689e3          	beq	a3,s3,800024ca <mlfq_scheduler+0xee>
    8000253c:	87e6                	mv	a5,s9
          if (flag == 0)
    8000253e:	f38d                	bnez	a5,80002460 <mlfq_scheduler+0x84>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    80002540:	22093683          	ld	a3,544(s2)
            for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002544:	00010797          	auipc	a5,0x10
    80002548:	a8c78793          	add	a5,a5,-1396 # 80011fd0 <proc>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    8000254c:	458d                	li	a1,3
    8000254e:	b77d                	j	800024fc <mlfq_scheduler+0x120>

0000000080002550 <scheduler>:
{
    80002550:	1141                	add	sp,sp,-16
    80002552:	e406                	sd	ra,8(sp)
    80002554:	e022                	sd	s0,0(sp)
    80002556:	0800                	add	s0,sp,16
    printf("mlfq will run");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	cc050513          	add	a0,a0,-832 # 80008218 <digits+0x1d8>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	026080e7          	jalr	38(ra) # 80000586 <printf>
    mlfq_scheduler();
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	e74080e7          	jalr	-396(ra) # 800023dc <mlfq_scheduler>

0000000080002570 <sched>:
{
    80002570:	7179                	add	sp,sp,-48
    80002572:	f406                	sd	ra,40(sp)
    80002574:	f022                	sd	s0,32(sp)
    80002576:	ec26                	sd	s1,24(sp)
    80002578:	e84a                	sd	s2,16(sp)
    8000257a:	e44e                	sd	s3,8(sp)
    8000257c:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	428080e7          	jalr	1064(ra) # 800019a6 <myproc>
    80002586:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	5d0080e7          	jalr	1488(ra) # 80000b58 <holding>
    80002590:	c93d                	beqz	a0,80002606 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002592:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002594:	2781                	sext.w	a5,a5
    80002596:	079e                	sll	a5,a5,0x7
    80002598:	0000e717          	auipc	a4,0xe
    8000259c:	66870713          	add	a4,a4,1640 # 80010c00 <pid_lock>
    800025a0:	97ba                	add	a5,a5,a4
    800025a2:	0a87a703          	lw	a4,168(a5)
    800025a6:	4785                	li	a5,1
    800025a8:	06f71763          	bne	a4,a5,80002616 <sched+0xa6>
  if (p->state == RUNNING)
    800025ac:	4c98                	lw	a4,24(s1)
    800025ae:	4791                	li	a5,4
    800025b0:	06f70b63          	beq	a4,a5,80002626 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025b8:	8b89                	and	a5,a5,2
  if (intr_get())
    800025ba:	efb5                	bnez	a5,80002636 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025bc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025be:	0000e917          	auipc	s2,0xe
    800025c2:	64290913          	add	s2,s2,1602 # 80010c00 <pid_lock>
    800025c6:	2781                	sext.w	a5,a5
    800025c8:	079e                	sll	a5,a5,0x7
    800025ca:	97ca                	add	a5,a5,s2
    800025cc:	0ac7a983          	lw	s3,172(a5)
    800025d0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025d2:	2781                	sext.w	a5,a5
    800025d4:	079e                	sll	a5,a5,0x7
    800025d6:	0000e597          	auipc	a1,0xe
    800025da:	66258593          	add	a1,a1,1634 # 80010c38 <cpus+0x8>
    800025de:	95be                	add	a1,a1,a5
    800025e0:	06048513          	add	a0,s1,96
    800025e4:	00001097          	auipc	ra,0x1
    800025e8:	820080e7          	jalr	-2016(ra) # 80002e04 <swtch>
    800025ec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025ee:	2781                	sext.w	a5,a5
    800025f0:	079e                	sll	a5,a5,0x7
    800025f2:	993e                	add	s2,s2,a5
    800025f4:	0b392623          	sw	s3,172(s2)
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6145                	add	sp,sp,48
    80002604:	8082                	ret
    panic("sched p->lock");
    80002606:	00006517          	auipc	a0,0x6
    8000260a:	c2250513          	add	a0,a0,-990 # 80008228 <digits+0x1e8>
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f2e080e7          	jalr	-210(ra) # 8000053c <panic>
    panic("sched locks");
    80002616:	00006517          	auipc	a0,0x6
    8000261a:	c2250513          	add	a0,a0,-990 # 80008238 <digits+0x1f8>
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f1e080e7          	jalr	-226(ra) # 8000053c <panic>
    panic("sched running");
    80002626:	00006517          	auipc	a0,0x6
    8000262a:	c2250513          	add	a0,a0,-990 # 80008248 <digits+0x208>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f0e080e7          	jalr	-242(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002636:	00006517          	auipc	a0,0x6
    8000263a:	c2250513          	add	a0,a0,-990 # 80008258 <digits+0x218>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	efe080e7          	jalr	-258(ra) # 8000053c <panic>

0000000080002646 <yield>:
{
    80002646:	1101                	add	sp,sp,-32
    80002648:	ec06                	sd	ra,24(sp)
    8000264a:	e822                	sd	s0,16(sp)
    8000264c:	e426                	sd	s1,8(sp)
    8000264e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	356080e7          	jalr	854(ra) # 800019a6 <myproc>
    80002658:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	578080e7          	jalr	1400(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002662:	478d                	li	a5,3
    80002664:	cc9c                	sw	a5,24(s1)
  sched();
    80002666:	00000097          	auipc	ra,0x0
    8000266a:	f0a080e7          	jalr	-246(ra) # 80002570 <sched>
  release(&p->lock);
    8000266e:	8526                	mv	a0,s1
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	616080e7          	jalr	1558(ra) # 80000c86 <release>
}
    80002678:	60e2                	ld	ra,24(sp)
    8000267a:	6442                	ld	s0,16(sp)
    8000267c:	64a2                	ld	s1,8(sp)
    8000267e:	6105                	add	sp,sp,32
    80002680:	8082                	ret

0000000080002682 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002682:	7179                	add	sp,sp,-48
    80002684:	f406                	sd	ra,40(sp)
    80002686:	f022                	sd	s0,32(sp)
    80002688:	ec26                	sd	s1,24(sp)
    8000268a:	e84a                	sd	s2,16(sp)
    8000268c:	e44e                	sd	s3,8(sp)
    8000268e:	1800                	add	s0,sp,48
    80002690:	89aa                	mv	s3,a0
    80002692:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	312080e7          	jalr	786(ra) # 800019a6 <myproc>
    8000269c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	534080e7          	jalr	1332(ra) # 80000bd2 <acquire>
  release(lk);
    800026a6:	854a                	mv	a0,s2
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5de080e7          	jalr	1502(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800026b0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800026b4:	4789                	li	a5,2
    800026b6:	cc9c                	sw	a5,24(s1)

  sched();
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	eb8080e7          	jalr	-328(ra) # 80002570 <sched>

  // Tidy up.
  p->chan = 0;
    800026c0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5c0080e7          	jalr	1472(ra) # 80000c86 <release>
  acquire(lk);
    800026ce:	854a                	mv	a0,s2
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	502080e7          	jalr	1282(ra) # 80000bd2 <acquire>
}
    800026d8:	70a2                	ld	ra,40(sp)
    800026da:	7402                	ld	s0,32(sp)
    800026dc:	64e2                	ld	s1,24(sp)
    800026de:	6942                	ld	s2,16(sp)
    800026e0:	69a2                	ld	s3,8(sp)
    800026e2:	6145                	add	sp,sp,48
    800026e4:	8082                	ret

00000000800026e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800026e6:	7139                	add	sp,sp,-64
    800026e8:	fc06                	sd	ra,56(sp)
    800026ea:	f822                	sd	s0,48(sp)
    800026ec:	f426                	sd	s1,40(sp)
    800026ee:	f04a                	sd	s2,32(sp)
    800026f0:	ec4e                	sd	s3,24(sp)
    800026f2:	e852                	sd	s4,16(sp)
    800026f4:	e456                	sd	s5,8(sp)
    800026f6:	0080                	add	s0,sp,64
    800026f8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026fa:	00010497          	auipc	s1,0x10
    800026fe:	8d648493          	add	s1,s1,-1834 # 80011fd0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002702:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002704:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002706:	00018917          	auipc	s2,0x18
    8000270a:	4ca90913          	add	s2,s2,1226 # 8001abd0 <tickslock>
    8000270e:	a811                	j	80002722 <wakeup+0x3c>
      }
      release(&p->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	574080e7          	jalr	1396(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000271a:	23048493          	add	s1,s1,560
    8000271e:	03248663          	beq	s1,s2,8000274a <wakeup+0x64>
    if (p != myproc())
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	284080e7          	jalr	644(ra) # 800019a6 <myproc>
    8000272a:	fea488e3          	beq	s1,a0,8000271a <wakeup+0x34>
      acquire(&p->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	4a2080e7          	jalr	1186(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002738:	4c9c                	lw	a5,24(s1)
    8000273a:	fd379be3          	bne	a5,s3,80002710 <wakeup+0x2a>
    8000273e:	709c                	ld	a5,32(s1)
    80002740:	fd4798e3          	bne	a5,s4,80002710 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002744:	0154ac23          	sw	s5,24(s1)
    80002748:	b7e1                	j	80002710 <wakeup+0x2a>
    }
  }
}
    8000274a:	70e2                	ld	ra,56(sp)
    8000274c:	7442                	ld	s0,48(sp)
    8000274e:	74a2                	ld	s1,40(sp)
    80002750:	7902                	ld	s2,32(sp)
    80002752:	69e2                	ld	s3,24(sp)
    80002754:	6a42                	ld	s4,16(sp)
    80002756:	6aa2                	ld	s5,8(sp)
    80002758:	6121                	add	sp,sp,64
    8000275a:	8082                	ret

000000008000275c <reparent>:
{
    8000275c:	7179                	add	sp,sp,-48
    8000275e:	f406                	sd	ra,40(sp)
    80002760:	f022                	sd	s0,32(sp)
    80002762:	ec26                	sd	s1,24(sp)
    80002764:	e84a                	sd	s2,16(sp)
    80002766:	e44e                	sd	s3,8(sp)
    80002768:	e052                	sd	s4,0(sp)
    8000276a:	1800                	add	s0,sp,48
    8000276c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000276e:	00010497          	auipc	s1,0x10
    80002772:	86248493          	add	s1,s1,-1950 # 80011fd0 <proc>
      pp->parent = initproc;
    80002776:	00006a17          	auipc	s4,0x6
    8000277a:	21aa0a13          	add	s4,s4,538 # 80008990 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000277e:	00018997          	auipc	s3,0x18
    80002782:	45298993          	add	s3,s3,1106 # 8001abd0 <tickslock>
    80002786:	a029                	j	80002790 <reparent+0x34>
    80002788:	23048493          	add	s1,s1,560
    8000278c:	01348d63          	beq	s1,s3,800027a6 <reparent+0x4a>
    if (pp->parent == p)
    80002790:	7c9c                	ld	a5,56(s1)
    80002792:	ff279be3          	bne	a5,s2,80002788 <reparent+0x2c>
      pp->parent = initproc;
    80002796:	000a3503          	ld	a0,0(s4)
    8000279a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	f4a080e7          	jalr	-182(ra) # 800026e6 <wakeup>
    800027a4:	b7d5                	j	80002788 <reparent+0x2c>
}
    800027a6:	70a2                	ld	ra,40(sp)
    800027a8:	7402                	ld	s0,32(sp)
    800027aa:	64e2                	ld	s1,24(sp)
    800027ac:	6942                	ld	s2,16(sp)
    800027ae:	69a2                	ld	s3,8(sp)
    800027b0:	6a02                	ld	s4,0(sp)
    800027b2:	6145                	add	sp,sp,48
    800027b4:	8082                	ret

00000000800027b6 <exit>:
{
    800027b6:	7179                	add	sp,sp,-48
    800027b8:	f406                	sd	ra,40(sp)
    800027ba:	f022                	sd	s0,32(sp)
    800027bc:	ec26                	sd	s1,24(sp)
    800027be:	e84a                	sd	s2,16(sp)
    800027c0:	e44e                	sd	s3,8(sp)
    800027c2:	e052                	sd	s4,0(sp)
    800027c4:	1800                	add	s0,sp,48
    800027c6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	1de080e7          	jalr	478(ra) # 800019a6 <myproc>
    800027d0:	89aa                	mv	s3,a0
  if (p == initproc)
    800027d2:	00006797          	auipc	a5,0x6
    800027d6:	1be7b783          	ld	a5,446(a5) # 80008990 <initproc>
    800027da:	0d050493          	add	s1,a0,208
    800027de:	15050913          	add	s2,a0,336
    800027e2:	02a79363          	bne	a5,a0,80002808 <exit+0x52>
    panic("init exiting");
    800027e6:	00006517          	auipc	a0,0x6
    800027ea:	a8a50513          	add	a0,a0,-1398 # 80008270 <digits+0x230>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	d4e080e7          	jalr	-690(ra) # 8000053c <panic>
      fileclose(f);
    800027f6:	00003097          	auipc	ra,0x3
    800027fa:	9de080e7          	jalr	-1570(ra) # 800051d4 <fileclose>
      p->ofile[fd] = 0;
    800027fe:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002802:	04a1                	add	s1,s1,8
    80002804:	01248563          	beq	s1,s2,8000280e <exit+0x58>
    if (p->ofile[fd])
    80002808:	6088                	ld	a0,0(s1)
    8000280a:	f575                	bnez	a0,800027f6 <exit+0x40>
    8000280c:	bfdd                	j	80002802 <exit+0x4c>
  begin_op();
    8000280e:	00002097          	auipc	ra,0x2
    80002812:	502080e7          	jalr	1282(ra) # 80004d10 <begin_op>
  iput(p->cwd);
    80002816:	1509b503          	ld	a0,336(s3)
    8000281a:	00002097          	auipc	ra,0x2
    8000281e:	d0a080e7          	jalr	-758(ra) # 80004524 <iput>
  end_op();
    80002822:	00002097          	auipc	ra,0x2
    80002826:	568080e7          	jalr	1384(ra) # 80004d8a <end_op>
  p->cwd = 0;
    8000282a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000282e:	0000e497          	auipc	s1,0xe
    80002832:	3ea48493          	add	s1,s1,1002 # 80010c18 <wait_lock>
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	39a080e7          	jalr	922(ra) # 80000bd2 <acquire>
  reparent(p);
    80002840:	854e                	mv	a0,s3
    80002842:	00000097          	auipc	ra,0x0
    80002846:	f1a080e7          	jalr	-230(ra) # 8000275c <reparent>
  wakeup(p->parent);
    8000284a:	0389b503          	ld	a0,56(s3)
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	e98080e7          	jalr	-360(ra) # 800026e6 <wakeup>
  acquire(&p->lock);
    80002856:	854e                	mv	a0,s3
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	37a080e7          	jalr	890(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002860:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002864:	4795                	li	a5,5
    80002866:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000286a:	00006797          	auipc	a5,0x6
    8000286e:	12e7a783          	lw	a5,302(a5) # 80008998 <ticks>
    80002872:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	40e080e7          	jalr	1038(ra) # 80000c86 <release>
  sched();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	cf0080e7          	jalr	-784(ra) # 80002570 <sched>
  panic("zombie exit");
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	9f850513          	add	a0,a0,-1544 # 80008280 <digits+0x240>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cac080e7          	jalr	-852(ra) # 8000053c <panic>

0000000080002898 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002898:	7179                	add	sp,sp,-48
    8000289a:	f406                	sd	ra,40(sp)
    8000289c:	f022                	sd	s0,32(sp)
    8000289e:	ec26                	sd	s1,24(sp)
    800028a0:	e84a                	sd	s2,16(sp)
    800028a2:	e44e                	sd	s3,8(sp)
    800028a4:	1800                	add	s0,sp,48
    800028a6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800028a8:	0000f497          	auipc	s1,0xf
    800028ac:	72848493          	add	s1,s1,1832 # 80011fd0 <proc>
    800028b0:	00018997          	auipc	s3,0x18
    800028b4:	32098993          	add	s3,s3,800 # 8001abd0 <tickslock>
  {
    acquire(&p->lock);
    800028b8:	8526                	mv	a0,s1
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	318080e7          	jalr	792(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    800028c2:	589c                	lw	a5,48(s1)
    800028c4:	01278d63          	beq	a5,s2,800028de <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028c8:	8526                	mv	a0,s1
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	3bc080e7          	jalr	956(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028d2:	23048493          	add	s1,s1,560
    800028d6:	ff3491e3          	bne	s1,s3,800028b8 <kill+0x20>
  }
  return -1;
    800028da:	557d                	li	a0,-1
    800028dc:	a829                	j	800028f6 <kill+0x5e>
      p->killed = 1;
    800028de:	4785                	li	a5,1
    800028e0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800028e2:	4c98                	lw	a4,24(s1)
    800028e4:	4789                	li	a5,2
    800028e6:	00f70f63          	beq	a4,a5,80002904 <kill+0x6c>
      release(&p->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	39a080e7          	jalr	922(ra) # 80000c86 <release>
      return 0;
    800028f4:	4501                	li	a0,0
}
    800028f6:	70a2                	ld	ra,40(sp)
    800028f8:	7402                	ld	s0,32(sp)
    800028fa:	64e2                	ld	s1,24(sp)
    800028fc:	6942                	ld	s2,16(sp)
    800028fe:	69a2                	ld	s3,8(sp)
    80002900:	6145                	add	sp,sp,48
    80002902:	8082                	ret
        p->state = RUNNABLE;
    80002904:	478d                	li	a5,3
    80002906:	cc9c                	sw	a5,24(s1)
    80002908:	b7cd                	j	800028ea <kill+0x52>

000000008000290a <setkilled>:

void setkilled(struct proc *p)
{
    8000290a:	1101                	add	sp,sp,-32
    8000290c:	ec06                	sd	ra,24(sp)
    8000290e:	e822                	sd	s0,16(sp)
    80002910:	e426                	sd	s1,8(sp)
    80002912:	1000                	add	s0,sp,32
    80002914:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	2bc080e7          	jalr	700(ra) # 80000bd2 <acquire>
  p->killed = 1;
    8000291e:	4785                	li	a5,1
    80002920:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	362080e7          	jalr	866(ra) # 80000c86 <release>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6105                	add	sp,sp,32
    80002934:	8082                	ret

0000000080002936 <killed>:

int killed(struct proc *p)
{
    80002936:	1101                	add	sp,sp,-32
    80002938:	ec06                	sd	ra,24(sp)
    8000293a:	e822                	sd	s0,16(sp)
    8000293c:	e426                	sd	s1,8(sp)
    8000293e:	e04a                	sd	s2,0(sp)
    80002940:	1000                	add	s0,sp,32
    80002942:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	28e080e7          	jalr	654(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000294c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	334080e7          	jalr	820(ra) # 80000c86 <release>
  return k;
}
    8000295a:	854a                	mv	a0,s2
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6902                	ld	s2,0(sp)
    80002964:	6105                	add	sp,sp,32
    80002966:	8082                	ret

0000000080002968 <wait>:
{
    80002968:	715d                	add	sp,sp,-80
    8000296a:	e486                	sd	ra,72(sp)
    8000296c:	e0a2                	sd	s0,64(sp)
    8000296e:	fc26                	sd	s1,56(sp)
    80002970:	f84a                	sd	s2,48(sp)
    80002972:	f44e                	sd	s3,40(sp)
    80002974:	f052                	sd	s4,32(sp)
    80002976:	ec56                	sd	s5,24(sp)
    80002978:	e85a                	sd	s6,16(sp)
    8000297a:	e45e                	sd	s7,8(sp)
    8000297c:	e062                	sd	s8,0(sp)
    8000297e:	0880                	add	s0,sp,80
    80002980:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002982:	fffff097          	auipc	ra,0xfffff
    80002986:	024080e7          	jalr	36(ra) # 800019a6 <myproc>
    8000298a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000298c:	0000e517          	auipc	a0,0xe
    80002990:	28c50513          	add	a0,a0,652 # 80010c18 <wait_lock>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	23e080e7          	jalr	574(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000299c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000299e:	4a95                	li	s5,5
        havekids = 1;
    800029a0:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800029a2:	00018997          	auipc	s3,0x18
    800029a6:	22e98993          	add	s3,s3,558 # 8001abd0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029aa:	0000ec17          	auipc	s8,0xe
    800029ae:	26ec0c13          	add	s8,s8,622 # 80010c18 <wait_lock>
    800029b2:	a8f1                	j	80002a8e <wait+0x126>
    800029b4:	17448793          	add	a5,s1,372
    800029b8:	17490713          	add	a4,s2,372
    800029bc:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    800029c0:	4394                	lw	a3,0(a5)
    800029c2:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    800029c4:	0791                	add	a5,a5,4
    800029c6:	0711                	add	a4,a4,4
    800029c8:	fec79ce3          	bne	a5,a2,800029c0 <wait+0x58>
          pid = pp->pid;
    800029cc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800029d0:	000a0e63          	beqz	s4,800029ec <wait+0x84>
    800029d4:	4691                	li	a3,4
    800029d6:	02c48613          	add	a2,s1,44
    800029da:	85d2                	mv	a1,s4
    800029dc:	05093503          	ld	a0,80(s2)
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	c86080e7          	jalr	-890(ra) # 80001666 <copyout>
    800029e8:	04054163          	bltz	a0,80002a2a <wait+0xc2>
          freeproc(pp);
    800029ec:	8526                	mv	a0,s1
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	16a080e7          	jalr	362(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    800029f6:	8526                	mv	a0,s1
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	28e080e7          	jalr	654(ra) # 80000c86 <release>
          release(&wait_lock);
    80002a00:	0000e517          	auipc	a0,0xe
    80002a04:	21850513          	add	a0,a0,536 # 80010c18 <wait_lock>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	27e080e7          	jalr	638(ra) # 80000c86 <release>
}
    80002a10:	854e                	mv	a0,s3
    80002a12:	60a6                	ld	ra,72(sp)
    80002a14:	6406                	ld	s0,64(sp)
    80002a16:	74e2                	ld	s1,56(sp)
    80002a18:	7942                	ld	s2,48(sp)
    80002a1a:	79a2                	ld	s3,40(sp)
    80002a1c:	7a02                	ld	s4,32(sp)
    80002a1e:	6ae2                	ld	s5,24(sp)
    80002a20:	6b42                	ld	s6,16(sp)
    80002a22:	6ba2                	ld	s7,8(sp)
    80002a24:	6c02                	ld	s8,0(sp)
    80002a26:	6161                	add	sp,sp,80
    80002a28:	8082                	ret
            release(&pp->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	25a080e7          	jalr	602(ra) # 80000c86 <release>
            release(&wait_lock);
    80002a34:	0000e517          	auipc	a0,0xe
    80002a38:	1e450513          	add	a0,a0,484 # 80010c18 <wait_lock>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	24a080e7          	jalr	586(ra) # 80000c86 <release>
            return -1;
    80002a44:	59fd                	li	s3,-1
    80002a46:	b7e9                	j	80002a10 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a48:	23048493          	add	s1,s1,560
    80002a4c:	03348463          	beq	s1,s3,80002a74 <wait+0x10c>
      if (pp->parent == p)
    80002a50:	7c9c                	ld	a5,56(s1)
    80002a52:	ff279be3          	bne	a5,s2,80002a48 <wait+0xe0>
        acquire(&pp->lock);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	17a080e7          	jalr	378(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002a60:	4c9c                	lw	a5,24(s1)
    80002a62:	f55789e3          	beq	a5,s5,800029b4 <wait+0x4c>
        release(&pp->lock);
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	21e080e7          	jalr	542(ra) # 80000c86 <release>
        havekids = 1;
    80002a70:	875a                	mv	a4,s6
    80002a72:	bfd9                	j	80002a48 <wait+0xe0>
    if (!havekids || killed(p))
    80002a74:	c31d                	beqz	a4,80002a9a <wait+0x132>
    80002a76:	854a                	mv	a0,s2
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	ebe080e7          	jalr	-322(ra) # 80002936 <killed>
    80002a80:	ed09                	bnez	a0,80002a9a <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a82:	85e2                	mv	a1,s8
    80002a84:	854a                	mv	a0,s2
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	bfc080e7          	jalr	-1028(ra) # 80002682 <sleep>
    havekids = 0;
    80002a8e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a90:	0000f497          	auipc	s1,0xf
    80002a94:	54048493          	add	s1,s1,1344 # 80011fd0 <proc>
    80002a98:	bf65                	j	80002a50 <wait+0xe8>
      release(&wait_lock);
    80002a9a:	0000e517          	auipc	a0,0xe
    80002a9e:	17e50513          	add	a0,a0,382 # 80010c18 <wait_lock>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	1e4080e7          	jalr	484(ra) # 80000c86 <release>
      return -1;
    80002aaa:	59fd                	li	s3,-1
    80002aac:	b795                	j	80002a10 <wait+0xa8>

0000000080002aae <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002aae:	7179                	add	sp,sp,-48
    80002ab0:	f406                	sd	ra,40(sp)
    80002ab2:	f022                	sd	s0,32(sp)
    80002ab4:	ec26                	sd	s1,24(sp)
    80002ab6:	e84a                	sd	s2,16(sp)
    80002ab8:	e44e                	sd	s3,8(sp)
    80002aba:	e052                	sd	s4,0(sp)
    80002abc:	1800                	add	s0,sp,48
    80002abe:	84aa                	mv	s1,a0
    80002ac0:	892e                	mv	s2,a1
    80002ac2:	89b2                	mv	s3,a2
    80002ac4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	ee0080e7          	jalr	-288(ra) # 800019a6 <myproc>
  if (user_dst)
    80002ace:	c08d                	beqz	s1,80002af0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002ad0:	86d2                	mv	a3,s4
    80002ad2:	864e                	mv	a2,s3
    80002ad4:	85ca                	mv	a1,s2
    80002ad6:	6928                	ld	a0,80(a0)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	b8e080e7          	jalr	-1138(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ae0:	70a2                	ld	ra,40(sp)
    80002ae2:	7402                	ld	s0,32(sp)
    80002ae4:	64e2                	ld	s1,24(sp)
    80002ae6:	6942                	ld	s2,16(sp)
    80002ae8:	69a2                	ld	s3,8(sp)
    80002aea:	6a02                	ld	s4,0(sp)
    80002aec:	6145                	add	sp,sp,48
    80002aee:	8082                	ret
    memmove((char *)dst, src, len);
    80002af0:	000a061b          	sext.w	a2,s4
    80002af4:	85ce                	mv	a1,s3
    80002af6:	854a                	mv	a0,s2
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	232080e7          	jalr	562(ra) # 80000d2a <memmove>
    return 0;
    80002b00:	8526                	mv	a0,s1
    80002b02:	bff9                	j	80002ae0 <either_copyout+0x32>

0000000080002b04 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b04:	7179                	add	sp,sp,-48
    80002b06:	f406                	sd	ra,40(sp)
    80002b08:	f022                	sd	s0,32(sp)
    80002b0a:	ec26                	sd	s1,24(sp)
    80002b0c:	e84a                	sd	s2,16(sp)
    80002b0e:	e44e                	sd	s3,8(sp)
    80002b10:	e052                	sd	s4,0(sp)
    80002b12:	1800                	add	s0,sp,48
    80002b14:	892a                	mv	s2,a0
    80002b16:	84ae                	mv	s1,a1
    80002b18:	89b2                	mv	s3,a2
    80002b1a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	e8a080e7          	jalr	-374(ra) # 800019a6 <myproc>
  if (user_src)
    80002b24:	c08d                	beqz	s1,80002b46 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002b26:	86d2                	mv	a3,s4
    80002b28:	864e                	mv	a2,s3
    80002b2a:	85ca                	mv	a1,s2
    80002b2c:	6928                	ld	a0,80(a0)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	bc4080e7          	jalr	-1084(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002b36:	70a2                	ld	ra,40(sp)
    80002b38:	7402                	ld	s0,32(sp)
    80002b3a:	64e2                	ld	s1,24(sp)
    80002b3c:	6942                	ld	s2,16(sp)
    80002b3e:	69a2                	ld	s3,8(sp)
    80002b40:	6a02                	ld	s4,0(sp)
    80002b42:	6145                	add	sp,sp,48
    80002b44:	8082                	ret
    memmove(dst, (char *)src, len);
    80002b46:	000a061b          	sext.w	a2,s4
    80002b4a:	85ce                	mv	a1,s3
    80002b4c:	854a                	mv	a0,s2
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	1dc080e7          	jalr	476(ra) # 80000d2a <memmove>
    return 0;
    80002b56:	8526                	mv	a0,s1
    80002b58:	bff9                	j	80002b36 <either_copyin+0x32>

0000000080002b5a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002b5a:	715d                	add	sp,sp,-80
    80002b5c:	e486                	sd	ra,72(sp)
    80002b5e:	e0a2                	sd	s0,64(sp)
    80002b60:	fc26                	sd	s1,56(sp)
    80002b62:	f84a                	sd	s2,48(sp)
    80002b64:	f44e                	sd	s3,40(sp)
    80002b66:	f052                	sd	s4,32(sp)
    80002b68:	ec56                	sd	s5,24(sp)
    80002b6a:	e85a                	sd	s6,16(sp)
    80002b6c:	e45e                	sd	s7,8(sp)
    80002b6e:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002b70:	00005517          	auipc	a0,0x5
    80002b74:	74850513          	add	a0,a0,1864 # 800082b8 <digits+0x278>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a0e080e7          	jalr	-1522(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b80:	0000f497          	auipc	s1,0xf
    80002b84:	5a848493          	add	s1,s1,1448 # 80012128 <proc+0x158>
    80002b88:	00018917          	auipc	s2,0x18
    80002b8c:	1a090913          	add	s2,s2,416 # 8001ad28 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b90:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002b92:	00005997          	auipc	s3,0x5
    80002b96:	6fe98993          	add	s3,s3,1790 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002b9a:	00005a97          	auipc	s5,0x5
    80002b9e:	6fea8a93          	add	s5,s5,1790 # 80008298 <digits+0x258>
    printf("\n");
    80002ba2:	00005a17          	auipc	s4,0x5
    80002ba6:	716a0a13          	add	s4,s4,1814 # 800082b8 <digits+0x278>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002baa:	00005b97          	auipc	s7,0x5
    80002bae:	746b8b93          	add	s7,s7,1862 # 800082f0 <states.0>
    80002bb2:	a00d                	j	80002bd4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bb4:	ed86a583          	lw	a1,-296(a3)
    80002bb8:	8556                	mv	a0,s5
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	9cc080e7          	jalr	-1588(ra) # 80000586 <printf>
    printf("\n");
    80002bc2:	8552                	mv	a0,s4
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	9c2080e7          	jalr	-1598(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bcc:	23048493          	add	s1,s1,560
    80002bd0:	03248263          	beq	s1,s2,80002bf4 <procdump+0x9a>
    if (p->state == UNUSED)
    80002bd4:	86a6                	mv	a3,s1
    80002bd6:	ec04a783          	lw	a5,-320(s1)
    80002bda:	dbed                	beqz	a5,80002bcc <procdump+0x72>
      state = "???";
    80002bdc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bde:	fcfb6be3          	bltu	s6,a5,80002bb4 <procdump+0x5a>
    80002be2:	02079713          	sll	a4,a5,0x20
    80002be6:	01d75793          	srl	a5,a4,0x1d
    80002bea:	97de                	add	a5,a5,s7
    80002bec:	6390                	ld	a2,0(a5)
    80002bee:	f279                	bnez	a2,80002bb4 <procdump+0x5a>
      state = "???";
    80002bf0:	864e                	mv	a2,s3
    80002bf2:	b7c9                	j	80002bb4 <procdump+0x5a>
  }
}
    80002bf4:	60a6                	ld	ra,72(sp)
    80002bf6:	6406                	ld	s0,64(sp)
    80002bf8:	74e2                	ld	s1,56(sp)
    80002bfa:	7942                	ld	s2,48(sp)
    80002bfc:	79a2                	ld	s3,40(sp)
    80002bfe:	7a02                	ld	s4,32(sp)
    80002c00:	6ae2                	ld	s5,24(sp)
    80002c02:	6b42                	ld	s6,16(sp)
    80002c04:	6ba2                	ld	s7,8(sp)
    80002c06:	6161                	add	sp,sp,80
    80002c08:	8082                	ret

0000000080002c0a <waitx>:
//     }
// }

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002c0a:	711d                	add	sp,sp,-96
    80002c0c:	ec86                	sd	ra,88(sp)
    80002c0e:	e8a2                	sd	s0,80(sp)
    80002c10:	e4a6                	sd	s1,72(sp)
    80002c12:	e0ca                	sd	s2,64(sp)
    80002c14:	fc4e                	sd	s3,56(sp)
    80002c16:	f852                	sd	s4,48(sp)
    80002c18:	f456                	sd	s5,40(sp)
    80002c1a:	f05a                	sd	s6,32(sp)
    80002c1c:	ec5e                	sd	s7,24(sp)
    80002c1e:	e862                	sd	s8,16(sp)
    80002c20:	e466                	sd	s9,8(sp)
    80002c22:	e06a                	sd	s10,0(sp)
    80002c24:	1080                	add	s0,sp,96
    80002c26:	8b2a                	mv	s6,a0
    80002c28:	8bae                	mv	s7,a1
    80002c2a:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	d7a080e7          	jalr	-646(ra) # 800019a6 <myproc>
    80002c34:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002c36:	0000e517          	auipc	a0,0xe
    80002c3a:	fe250513          	add	a0,a0,-30 # 80010c18 <wait_lock>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	f94080e7          	jalr	-108(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002c46:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002c48:	4a15                	li	s4,5
        havekids = 1;
    80002c4a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002c4c:	00018997          	auipc	s3,0x18
    80002c50:	f8498993          	add	s3,s3,-124 # 8001abd0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c54:	0000ed17          	auipc	s10,0xe
    80002c58:	fc4d0d13          	add	s10,s10,-60 # 80010c18 <wait_lock>
    80002c5c:	a0fd                	j	80002d4a <waitx+0x140>
          pid = np->pid;
    80002c5e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002c62:	1684a583          	lw	a1,360(s1)
    80002c66:	00bc2023          	sw	a1,0(s8)
          printf("%d \n",*rtime);
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	63e50513          	add	a0,a0,1598 # 800082a8 <digits+0x268>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	914080e7          	jalr	-1772(ra) # 80000586 <printf>
          *wtime = np->etime - np->ctime - np->rtime;
    80002c7a:	16c4a783          	lw	a5,364(s1)
    80002c7e:	1684a703          	lw	a4,360(s1)
    80002c82:	9f3d                	addw	a4,a4,a5
    80002c84:	1704a783          	lw	a5,368(s1)
    80002c88:	9f99                	subw	a5,a5,a4
    80002c8a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c8e:	000b0e63          	beqz	s6,80002caa <waitx+0xa0>
    80002c92:	4691                	li	a3,4
    80002c94:	02c48613          	add	a2,s1,44
    80002c98:	85da                	mv	a1,s6
    80002c9a:	05093503          	ld	a0,80(s2)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	9c8080e7          	jalr	-1592(ra) # 80001666 <copyout>
    80002ca6:	04054363          	bltz	a0,80002cec <waitx+0xe2>
          freeproc(np);
    80002caa:	8526                	mv	a0,s1
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	eac080e7          	jalr	-340(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002cb4:	8526                	mv	a0,s1
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	fd0080e7          	jalr	-48(ra) # 80000c86 <release>
          release(&wait_lock);
    80002cbe:	0000e517          	auipc	a0,0xe
    80002cc2:	f5a50513          	add	a0,a0,-166 # 80010c18 <wait_lock>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	fc0080e7          	jalr	-64(ra) # 80000c86 <release>
  }
}
    80002cce:	854e                	mv	a0,s3
    80002cd0:	60e6                	ld	ra,88(sp)
    80002cd2:	6446                	ld	s0,80(sp)
    80002cd4:	64a6                	ld	s1,72(sp)
    80002cd6:	6906                	ld	s2,64(sp)
    80002cd8:	79e2                	ld	s3,56(sp)
    80002cda:	7a42                	ld	s4,48(sp)
    80002cdc:	7aa2                	ld	s5,40(sp)
    80002cde:	7b02                	ld	s6,32(sp)
    80002ce0:	6be2                	ld	s7,24(sp)
    80002ce2:	6c42                	ld	s8,16(sp)
    80002ce4:	6ca2                	ld	s9,8(sp)
    80002ce6:	6d02                	ld	s10,0(sp)
    80002ce8:	6125                	add	sp,sp,96
    80002cea:	8082                	ret
            release(&np->lock);
    80002cec:	8526                	mv	a0,s1
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	f98080e7          	jalr	-104(ra) # 80000c86 <release>
            release(&wait_lock);
    80002cf6:	0000e517          	auipc	a0,0xe
    80002cfa:	f2250513          	add	a0,a0,-222 # 80010c18 <wait_lock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	f88080e7          	jalr	-120(ra) # 80000c86 <release>
            return -1;
    80002d06:	59fd                	li	s3,-1
    80002d08:	b7d9                	j	80002cce <waitx+0xc4>
    for (np = proc; np < &proc[NPROC]; np++)
    80002d0a:	23048493          	add	s1,s1,560
    80002d0e:	03348463          	beq	s1,s3,80002d36 <waitx+0x12c>
      if (np->parent == p)
    80002d12:	7c9c                	ld	a5,56(s1)
    80002d14:	ff279be3          	bne	a5,s2,80002d0a <waitx+0x100>
        acquire(&np->lock);
    80002d18:	8526                	mv	a0,s1
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	eb8080e7          	jalr	-328(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002d22:	4c9c                	lw	a5,24(s1)
    80002d24:	f3478de3          	beq	a5,s4,80002c5e <waitx+0x54>
        release(&np->lock);
    80002d28:	8526                	mv	a0,s1
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	f5c080e7          	jalr	-164(ra) # 80000c86 <release>
        havekids = 1;
    80002d32:	8756                	mv	a4,s5
    80002d34:	bfd9                	j	80002d0a <waitx+0x100>
    if (!havekids || p->killed)
    80002d36:	c305                	beqz	a4,80002d56 <waitx+0x14c>
    80002d38:	02892783          	lw	a5,40(s2)
    80002d3c:	ef89                	bnez	a5,80002d56 <waitx+0x14c>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d3e:	85ea                	mv	a1,s10
    80002d40:	854a                	mv	a0,s2
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	940080e7          	jalr	-1728(ra) # 80002682 <sleep>
    havekids = 0;
    80002d4a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002d4c:	0000f497          	auipc	s1,0xf
    80002d50:	28448493          	add	s1,s1,644 # 80011fd0 <proc>
    80002d54:	bf7d                	j	80002d12 <waitx+0x108>
      release(&wait_lock);
    80002d56:	0000e517          	auipc	a0,0xe
    80002d5a:	ec250513          	add	a0,a0,-318 # 80010c18 <wait_lock>
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	f28080e7          	jalr	-216(ra) # 80000c86 <release>
      return -1;
    80002d66:	59fd                	li	s3,-1
    80002d68:	b79d                	j	80002cce <waitx+0xc4>

0000000080002d6a <update_time>:

void update_time()
{
    80002d6a:	7139                	add	sp,sp,-64
    80002d6c:	fc06                	sd	ra,56(sp)
    80002d6e:	f822                	sd	s0,48(sp)
    80002d70:	f426                	sd	s1,40(sp)
    80002d72:	f04a                	sd	s2,32(sp)
    80002d74:	ec4e                	sd	s3,24(sp)
    80002d76:	e852                	sd	s4,16(sp)
    80002d78:	e456                	sd	s5,8(sp)
    80002d7a:	e05a                	sd	s6,0(sp)
    80002d7c:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002d7e:	0000f497          	auipc	s1,0xf
    80002d82:	25248493          	add	s1,s1,594 # 80011fd0 <proc>
  {
    if (p->pid >= 9 && p->pid <= 14)
    80002d86:	4a15                	li	s4,5
    {
      printf("%d %d %d\n", p->pid, p->priority, ticks);
    80002d88:	00006b17          	auipc	s6,0x6
    80002d8c:	c10b0b13          	add	s6,s6,-1008 # 80008998 <ticks>
    80002d90:	00005a97          	auipc	s5,0x5
    80002d94:	520a8a93          	add	s5,s5,1312 # 800082b0 <digits+0x270>
    }
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002d98:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002d9a:	00018917          	auipc	s2,0x18
    80002d9e:	e3690913          	add	s2,s2,-458 # 8001abd0 <tickslock>
    80002da2:	a025                	j	80002dca <update_time+0x60>
      printf("%d %d %d\n", p->pid, p->priority, ticks);
    80002da4:	000b2683          	lw	a3,0(s6)
    80002da8:	2204a603          	lw	a2,544(s1)
    80002dac:	8556                	mv	a0,s5
    80002dae:	ffffd097          	auipc	ra,0xffffd
    80002db2:	7d8080e7          	jalr	2008(ra) # 80000586 <printf>
    80002db6:	a839                	j	80002dd4 <update_time+0x6a>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002db8:	8526                	mv	a0,s1
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	ecc080e7          	jalr	-308(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002dc2:	23048493          	add	s1,s1,560
    80002dc6:	03248563          	beq	s1,s2,80002df0 <update_time+0x86>
    if (p->pid >= 9 && p->pid <= 14)
    80002dca:	588c                	lw	a1,48(s1)
    80002dcc:	ff75879b          	addw	a5,a1,-9
    80002dd0:	fcfa7ae3          	bgeu	s4,a5,80002da4 <update_time+0x3a>
    acquire(&p->lock);
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	dfc080e7          	jalr	-516(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002dde:	4c9c                	lw	a5,24(s1)
    80002de0:	fd379ce3          	bne	a5,s3,80002db8 <update_time+0x4e>
      p->rtime++;
    80002de4:	1684a783          	lw	a5,360(s1)
    80002de8:	2785                	addw	a5,a5,1
    80002dea:	16f4a423          	sw	a5,360(s1)
    80002dee:	b7e9                	j	80002db8 <update_time+0x4e>
  }
}
    80002df0:	70e2                	ld	ra,56(sp)
    80002df2:	7442                	ld	s0,48(sp)
    80002df4:	74a2                	ld	s1,40(sp)
    80002df6:	7902                	ld	s2,32(sp)
    80002df8:	69e2                	ld	s3,24(sp)
    80002dfa:	6a42                	ld	s4,16(sp)
    80002dfc:	6aa2                	ld	s5,8(sp)
    80002dfe:	6b02                	ld	s6,0(sp)
    80002e00:	6121                	add	sp,sp,64
    80002e02:	8082                	ret

0000000080002e04 <swtch>:
    80002e04:	00153023          	sd	ra,0(a0)
    80002e08:	00253423          	sd	sp,8(a0)
    80002e0c:	e900                	sd	s0,16(a0)
    80002e0e:	ed04                	sd	s1,24(a0)
    80002e10:	03253023          	sd	s2,32(a0)
    80002e14:	03353423          	sd	s3,40(a0)
    80002e18:	03453823          	sd	s4,48(a0)
    80002e1c:	03553c23          	sd	s5,56(a0)
    80002e20:	05653023          	sd	s6,64(a0)
    80002e24:	05753423          	sd	s7,72(a0)
    80002e28:	05853823          	sd	s8,80(a0)
    80002e2c:	05953c23          	sd	s9,88(a0)
    80002e30:	07a53023          	sd	s10,96(a0)
    80002e34:	07b53423          	sd	s11,104(a0)
    80002e38:	0005b083          	ld	ra,0(a1)
    80002e3c:	0085b103          	ld	sp,8(a1)
    80002e40:	6980                	ld	s0,16(a1)
    80002e42:	6d84                	ld	s1,24(a1)
    80002e44:	0205b903          	ld	s2,32(a1)
    80002e48:	0285b983          	ld	s3,40(a1)
    80002e4c:	0305ba03          	ld	s4,48(a1)
    80002e50:	0385ba83          	ld	s5,56(a1)
    80002e54:	0405bb03          	ld	s6,64(a1)
    80002e58:	0485bb83          	ld	s7,72(a1)
    80002e5c:	0505bc03          	ld	s8,80(a1)
    80002e60:	0585bc83          	ld	s9,88(a1)
    80002e64:	0605bd03          	ld	s10,96(a1)
    80002e68:	0685bd83          	ld	s11,104(a1)
    80002e6c:	8082                	ret

0000000080002e6e <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002e6e:	1141                	add	sp,sp,-16
    80002e70:	e406                	sd	ra,8(sp)
    80002e72:	e022                	sd	s0,0(sp)
    80002e74:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002e76:	00005597          	auipc	a1,0x5
    80002e7a:	4aa58593          	add	a1,a1,1194 # 80008320 <states.0+0x30>
    80002e7e:	00018517          	auipc	a0,0x18
    80002e82:	d5250513          	add	a0,a0,-686 # 8001abd0 <tickslock>
    80002e86:	ffffe097          	auipc	ra,0xffffe
    80002e8a:	cbc080e7          	jalr	-836(ra) # 80000b42 <initlock>
}
    80002e8e:	60a2                	ld	ra,8(sp)
    80002e90:	6402                	ld	s0,0(sp)
    80002e92:	0141                	add	sp,sp,16
    80002e94:	8082                	ret

0000000080002e96 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002e96:	1141                	add	sp,sp,-16
    80002e98:	e422                	sd	s0,8(sp)
    80002e9a:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e9c:	00004797          	auipc	a5,0x4
    80002ea0:	96478793          	add	a5,a5,-1692 # 80006800 <kernelvec>
    80002ea4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ea8:	6422                	ld	s0,8(sp)
    80002eaa:	0141                	add	sp,sp,16
    80002eac:	8082                	ret

0000000080002eae <get_time_slice>:
#define total_queue 4

int get_time_slice(int priority)
{
    80002eae:	1141                	add	sp,sp,-16
    80002eb0:	e422                	sd	s0,8(sp)
    80002eb2:	0800                	add	s0,sp,16
  switch (priority)
    80002eb4:	4709                	li	a4,2
    80002eb6:	00e50f63          	beq	a0,a4,80002ed4 <get_time_slice+0x26>
    80002eba:	87aa                	mv	a5,a0
    80002ebc:	470d                	li	a4,3
  case 1:
    return 4;
  case 2:
    return 8;
  case 3:
    return 16;
    80002ebe:	4541                	li	a0,16
  switch (priority)
    80002ec0:	00e78763          	beq	a5,a4,80002ece <get_time_slice+0x20>
    80002ec4:	4705                	li	a4,1
    80002ec6:	4511                	li	a0,4
    80002ec8:	00e78363          	beq	a5,a4,80002ece <get_time_slice+0x20>
    return 1;
    80002ecc:	4505                	li	a0,1
  default:
    return 1;
  }
}
    80002ece:	6422                	ld	s0,8(sp)
    80002ed0:	0141                	add	sp,sp,16
    80002ed2:	8082                	ret
    return 8;
    80002ed4:	4521                	li	a0,8
    80002ed6:	bfe5                	j	80002ece <get_time_slice+0x20>

0000000080002ed8 <adjust_process_priority>:
//     }
//   }
// }

void adjust_process_priority(struct proc *p)
{
    80002ed8:	7179                	add	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	e84a                	sd	s2,16(sp)
    80002ee2:	e44e                	sd	s3,8(sp)
    80002ee4:	1800                	add	s0,sp,48
    80002ee6:	84aa                	mv	s1,a0
  // Check if the process has exhausted its time slice
  if (p->ticks_count >= get_time_slice(p->priority))
    80002ee8:	20052983          	lw	s3,512(a0)
    80002eec:	22052903          	lw	s2,544(a0)
    80002ef0:	854a                	mv	a0,s2
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	fbc080e7          	jalr	-68(ra) # 80002eae <get_time_slice>
    80002efa:	00a9c863          	blt	s3,a0,80002f0a <adjust_process_priority+0x32>
  {
    // Move to the next lower priority queue if not already at the lowest level
    if (p->priority < total_queue - 1) // Assuming total_queue is the number of queues
    80002efe:	4789                	li	a5,2
    80002f00:	0127c563          	blt	a5,s2,80002f0a <adjust_process_priority+0x32>
    {
      // Move the process to a lower priority
      p->priority++;
    80002f04:	2905                	addw	s2,s2,1
    80002f06:	2324a023          	sw	s2,544(s1)
    // If the process has not exhausted its time slice, we can choose to keep it in the same queue.
    // Optional: You could implement logic here to possibly increase the priority based on behavior.
  }

  // Reset the tick count for the next time slice
  p->ticks_count = 0; // Reset ticks count for the next time slice
    80002f0a:	2004a023          	sw	zero,512(s1)
}
    80002f0e:	70a2                	ld	ra,40(sp)
    80002f10:	7402                	ld	s0,32(sp)
    80002f12:	64e2                	ld	s1,24(sp)
    80002f14:	6942                	ld	s2,16(sp)
    80002f16:	69a2                	ld	s3,8(sp)
    80002f18:	6145                	add	sp,sp,48
    80002f1a:	8082                	ret

0000000080002f1c <lastscheduled>:

void lastscheduled(void)
{
    80002f1c:	1141                	add	sp,sp,-16
    80002f1e:	e422                	sd	s0,8(sp)
    80002f20:	0800                	add	s0,sp,16
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002f22:	0000f797          	auipc	a5,0xf
    80002f26:	0ae78793          	add	a5,a5,174 # 80011fd0 <proc>
  {
    if (p->state == RUNNING)
    80002f2a:	4611                	li	a2,4
    {
      p->lastscheduledticks = 0;
    }
    else if (p->state == RUNNABLE)
    80002f2c:	458d                	li	a1,3
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002f2e:	00018697          	auipc	a3,0x18
    80002f32:	ca268693          	add	a3,a3,-862 # 8001abd0 <tickslock>
    80002f36:	a039                	j	80002f44 <lastscheduled+0x28>
      p->lastscheduledticks = 0;
    80002f38:	2207a223          	sw	zero,548(a5)
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002f3c:	23078793          	add	a5,a5,560
    80002f40:	00d78d63          	beq	a5,a3,80002f5a <lastscheduled+0x3e>
    if (p->state == RUNNING)
    80002f44:	4f98                	lw	a4,24(a5)
    80002f46:	fec709e3          	beq	a4,a2,80002f38 <lastscheduled+0x1c>
    else if (p->state == RUNNABLE)
    80002f4a:	feb719e3          	bne	a4,a1,80002f3c <lastscheduled+0x20>
    {
      p->lastscheduledticks += 1;
    80002f4e:	2247a703          	lw	a4,548(a5)
    80002f52:	2705                	addw	a4,a4,1
    80002f54:	22e7a223          	sw	a4,548(a5)
    80002f58:	b7d5                	j	80002f3c <lastscheduled+0x20>
    }
  }
}
    80002f5a:	6422                	ld	s0,8(sp)
    80002f5c:	0141                	add	sp,sp,16
    80002f5e:	8082                	ret

0000000080002f60 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002f60:	1141                	add	sp,sp,-16
    80002f62:	e406                	sd	ra,8(sp)
    80002f64:	e022                	sd	s0,0(sp)
    80002f66:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	a3e080e7          	jalr	-1474(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f74:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f76:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002f7a:	00004697          	auipc	a3,0x4
    80002f7e:	08668693          	add	a3,a3,134 # 80007000 <_trampoline>
    80002f82:	00004717          	auipc	a4,0x4
    80002f86:	07e70713          	add	a4,a4,126 # 80007000 <_trampoline>
    80002f8a:	8f15                	sub	a4,a4,a3
    80002f8c:	040007b7          	lui	a5,0x4000
    80002f90:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002f92:	07b2                	sll	a5,a5,0xc
    80002f94:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f96:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f9a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f9c:	18002673          	csrr	a2,satp
    80002fa0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fa2:	6d30                	ld	a2,88(a0)
    80002fa4:	6138                	ld	a4,64(a0)
    80002fa6:	6585                	lui	a1,0x1
    80002fa8:	972e                	add	a4,a4,a1
    80002faa:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fac:	6d38                	ld	a4,88(a0)
    80002fae:	00000617          	auipc	a2,0x0
    80002fb2:	14260613          	add	a2,a2,322 # 800030f0 <usertrap>
    80002fb6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002fb8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fba:	8612                	mv	a2,tp
    80002fbc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbe:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002fc2:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002fc6:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fca:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002fce:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fd0:	6f18                	ld	a4,24(a4)
    80002fd2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002fd6:	6928                	ld	a0,80(a0)
    80002fd8:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002fda:	00004717          	auipc	a4,0x4
    80002fde:	0c270713          	add	a4,a4,194 # 8000709c <userret>
    80002fe2:	8f15                	sub	a4,a4,a3
    80002fe4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002fe6:	577d                	li	a4,-1
    80002fe8:	177e                	sll	a4,a4,0x3f
    80002fea:	8d59                	or	a0,a0,a4
    80002fec:	9782                	jalr	a5
}
    80002fee:	60a2                	ld	ra,8(sp)
    80002ff0:	6402                	ld	s0,0(sp)
    80002ff2:	0141                	add	sp,sp,16
    80002ff4:	8082                	ret

0000000080002ff6 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002ff6:	1101                	add	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	e426                	sd	s1,8(sp)
    80002ffe:	e04a                	sd	s2,0(sp)
    80003000:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80003002:	00018917          	auipc	s2,0x18
    80003006:	bce90913          	add	s2,s2,-1074 # 8001abd0 <tickslock>
    8000300a:	854a                	mv	a0,s2
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bc6080e7          	jalr	-1082(ra) # 80000bd2 <acquire>
  ticks++;
    80003014:	00006497          	auipc	s1,0x6
    80003018:	98448493          	add	s1,s1,-1660 # 80008998 <ticks>
    8000301c:	409c                	lw	a5,0(s1)
    8000301e:	2785                	addw	a5,a5,1
    80003020:	c09c                	sw	a5,0(s1)
  update_time();
    80003022:	00000097          	auipc	ra,0x0
    80003026:	d48080e7          	jalr	-696(ra) # 80002d6a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000302a:	8526                	mv	a0,s1
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	6ba080e7          	jalr	1722(ra) # 800026e6 <wakeup>
  release(&tickslock);
    80003034:	854a                	mv	a0,s2
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c50080e7          	jalr	-944(ra) # 80000c86 <release>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6902                	ld	s2,0(sp)
    80003046:	6105                	add	sp,sp,32
    80003048:	8082                	ret

000000008000304a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000304a:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    8000304e:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80003050:	0807df63          	bgez	a5,800030ee <devintr+0xa4>
{
    80003054:	1101                	add	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    8000305e:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80003062:	46a5                	li	a3,9
    80003064:	00d70d63          	beq	a4,a3,8000307e <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80003068:	577d                	li	a4,-1
    8000306a:	177e                	sll	a4,a4,0x3f
    8000306c:	0705                	add	a4,a4,1
    return 0;
    8000306e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80003070:	04e78e63          	beq	a5,a4,800030cc <devintr+0x82>
  }
}
    80003074:	60e2                	ld	ra,24(sp)
    80003076:	6442                	ld	s0,16(sp)
    80003078:	64a2                	ld	s1,8(sp)
    8000307a:	6105                	add	sp,sp,32
    8000307c:	8082                	ret
    int irq = plic_claim();
    8000307e:	00004097          	auipc	ra,0x4
    80003082:	88a080e7          	jalr	-1910(ra) # 80006908 <plic_claim>
    80003086:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80003088:	47a9                	li	a5,10
    8000308a:	02f50763          	beq	a0,a5,800030b8 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    8000308e:	4785                	li	a5,1
    80003090:	02f50963          	beq	a0,a5,800030c2 <devintr+0x78>
    return 1;
    80003094:	4505                	li	a0,1
    else if (irq)
    80003096:	dcf9                	beqz	s1,80003074 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80003098:	85a6                	mv	a1,s1
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	28e50513          	add	a0,a0,654 # 80008328 <states.0+0x38>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	4e4080e7          	jalr	1252(ra) # 80000586 <printf>
      plic_complete(irq);
    800030aa:	8526                	mv	a0,s1
    800030ac:	00004097          	auipc	ra,0x4
    800030b0:	880080e7          	jalr	-1920(ra) # 8000692c <plic_complete>
    return 1;
    800030b4:	4505                	li	a0,1
    800030b6:	bf7d                	j	80003074 <devintr+0x2a>
      uartintr();
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	8dc080e7          	jalr	-1828(ra) # 80000994 <uartintr>
    if (irq)
    800030c0:	b7ed                	j	800030aa <devintr+0x60>
      virtio_disk_intr();
    800030c2:	00004097          	auipc	ra,0x4
    800030c6:	d30080e7          	jalr	-720(ra) # 80006df2 <virtio_disk_intr>
    if (irq)
    800030ca:	b7c5                	j	800030aa <devintr+0x60>
    if (cpuid() == 0)
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	8ae080e7          	jalr	-1874(ra) # 8000197a <cpuid>
    800030d4:	c901                	beqz	a0,800030e4 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030d6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030da:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030dc:	14479073          	csrw	sip,a5
    return 2;
    800030e0:	4509                	li	a0,2
    800030e2:	bf49                	j	80003074 <devintr+0x2a>
      clockintr();
    800030e4:	00000097          	auipc	ra,0x0
    800030e8:	f12080e7          	jalr	-238(ra) # 80002ff6 <clockintr>
    800030ec:	b7ed                	j	800030d6 <devintr+0x8c>
}
    800030ee:	8082                	ret

00000000800030f0 <usertrap>:
{
    800030f0:	1101                	add	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	e04a                	sd	s2,0(sp)
    800030fa:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030fc:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80003100:	1007f793          	and	a5,a5,256
    80003104:	efb9                	bnez	a5,80003162 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003106:	00003797          	auipc	a5,0x3
    8000310a:	6fa78793          	add	a5,a5,1786 # 80006800 <kernelvec>
    8000310e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003112:	fffff097          	auipc	ra,0xfffff
    80003116:	894080e7          	jalr	-1900(ra) # 800019a6 <myproc>
    8000311a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000311c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000311e:	14102773          	csrr	a4,sepc
    80003122:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003124:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003128:	47a1                	li	a5,8
    8000312a:	04f70463          	beq	a4,a5,80003172 <usertrap+0x82>
  else if ((which_dev = devintr()) != 0)
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	f1c080e7          	jalr	-228(ra) # 8000304a <devintr>
    80003136:	2c050663          	beqz	a0,80003402 <usertrap+0x312>
    if (which_dev == 2 && SCHEDULER == 2)
    8000313a:	4789                	li	a5,2
    8000313c:	06f50563          	beq	a0,a5,800031a6 <usertrap+0xb6>
  if (killed(p))
    80003140:	8526                	mv	a0,s1
    80003142:	fffff097          	auipc	ra,0xfffff
    80003146:	7f4080e7          	jalr	2036(ra) # 80002936 <killed>
    8000314a:	2e051963          	bnez	a0,8000343c <usertrap+0x34c>
  usertrapret();
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	e12080e7          	jalr	-494(ra) # 80002f60 <usertrapret>
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6902                	ld	s2,0(sp)
    8000315e:	6105                	add	sp,sp,32
    80003160:	8082                	ret
    panic("usertrap: not from user mode");
    80003162:	00005517          	auipc	a0,0x5
    80003166:	1e650513          	add	a0,a0,486 # 80008348 <states.0+0x58>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	3d2080e7          	jalr	978(ra) # 8000053c <panic>
    if (killed(p))
    80003172:	fffff097          	auipc	ra,0xfffff
    80003176:	7c4080e7          	jalr	1988(ra) # 80002936 <killed>
    8000317a:	e105                	bnez	a0,8000319a <usertrap+0xaa>
    p->trapframe->epc += 4;
    8000317c:	6cb8                	ld	a4,88(s1)
    8000317e:	6f1c                	ld	a5,24(a4)
    80003180:	0791                	add	a5,a5,4
    80003182:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003184:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003188:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000318c:	10079073          	csrw	sstatus,a5
    syscall();
    80003190:	00000097          	auipc	ra,0x0
    80003194:	502080e7          	jalr	1282(ra) # 80003692 <syscall>
  if (which_dev == 2)
    80003198:	b765                	j	80003140 <usertrap+0x50>
      exit(-1);
    8000319a:	557d                	li	a0,-1
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	61a080e7          	jalr	1562(ra) # 800027b6 <exit>
    800031a4:	bfe1                	j	8000317c <usertrap+0x8c>
      lastscheduled();
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	d76080e7          	jalr	-650(ra) # 80002f1c <lastscheduled>
      p->ticks += 1;
    800031ae:	2284a783          	lw	a5,552(s1)
    800031b2:	2785                	addw	a5,a5,1
    800031b4:	22f4a423          	sw	a5,552(s1)
      for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800031b8:	0000f797          	auipc	a5,0xf
    800031bc:	e1878793          	add	a5,a5,-488 # 80011fd0 <proc>
        if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    800031c0:	46f5                	li	a3,29
    800031c2:	450d                	li	a0,3
      for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800031c4:	00018617          	auipc	a2,0x18
    800031c8:	a0c60613          	add	a2,a2,-1524 # 8001abd0 <tickslock>
    800031cc:	a029                	j	800031d6 <usertrap+0xe6>
    800031ce:	23078793          	add	a5,a5,560
    800031d2:	02c78963          	beq	a5,a2,80003204 <usertrap+0x114>
        if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    800031d6:	2247a703          	lw	a4,548(a5)
    800031da:	fee6dae3          	bge	a3,a4,800031ce <usertrap+0xde>
    800031de:	2207a703          	lw	a4,544(a5)
    800031e2:	d775                	beqz	a4,800031ce <usertrap+0xde>
    800031e4:	4f8c                	lw	a1,24(a5)
    800031e6:	fea594e3          	bne	a1,a0,800031ce <usertrap+0xde>
          t->lastscheduledticks = 0;
    800031ea:	2207a223          	sw	zero,548(a5)
          t->priority -= 1;
    800031ee:	377d                	addw	a4,a4,-1
    800031f0:	0007059b          	sext.w	a1,a4
    800031f4:	22e7a023          	sw	a4,544(a5)
          if (p->priority > t->priority)
    800031f8:	2204a703          	lw	a4,544(s1)
    800031fc:	fce5d9e3          	bge	a1,a4,800031ce <usertrap+0xde>
            flag = 1;
    80003200:	4905                	li	s2,1
    80003202:	a011                	j	80003206 <usertrap+0x116>
      int flag = 0;
    80003204:	4901                	li	s2,0
       if (p != 0 && p->state == RUNNING)
    80003206:	4c98                	lw	a4,24(s1)
    80003208:	4791                	li	a5,4
    8000320a:	02f70163          	beq	a4,a5,8000322c <usertrap+0x13c>
      if (p->priority == 0 && p->ticks == 1)
    8000320e:	2204a783          	lw	a5,544(s1)
    80003212:	e7e1                	bnez	a5,800032da <usertrap+0x1ea>
    80003214:	2284a703          	lw	a4,552(s1)
    80003218:	4785                	li	a5,1
    8000321a:	06f70863          	beq	a4,a5,8000328a <usertrap+0x19a>
      else if (flag == 1)
    8000321e:	1c091d63          	bnez	s2,800033f8 <usertrap+0x308>
    yield();
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	424080e7          	jalr	1060(ra) # 80002646 <yield>
    8000322a:	bf19                	j	80003140 <usertrap+0x50>
        p->ticks_count++;
    8000322c:	2004a783          	lw	a5,512(s1)
    80003230:	2785                	addw	a5,a5,1
    80003232:	0007871b          	sext.w	a4,a5
    80003236:	20f4a023          	sw	a5,512(s1)
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    8000323a:	1f04a783          	lw	a5,496(s1)
    8000323e:	fcf058e3          	blez	a5,8000320e <usertrap+0x11e>
    80003242:	fcf746e3          	blt	a4,a5,8000320e <usertrap+0x11e>
    80003246:	2044a783          	lw	a5,516(s1)
    8000324a:	d3f1                	beqz	a5,8000320e <usertrap+0x11e>
          p->alarm_on = 0; // Disable alarm while handler is running
    8000324c:	2004a223          	sw	zero,516(s1)
          p->alarm_tf = kalloc();
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	892080e7          	jalr	-1902(ra) # 80000ae2 <kalloc>
    80003258:	20a4b423          	sd	a0,520(s1)
          if (p->alarm_tf == 0)
    8000325c:	cd19                	beqz	a0,8000327a <usertrap+0x18a>
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    8000325e:	12000613          	li	a2,288
    80003262:	6cac                	ld	a1,88(s1)
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	ac6080e7          	jalr	-1338(ra) # 80000d2a <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    8000326c:	6cbc                	ld	a5,88(s1)
    8000326e:	1f84b703          	ld	a4,504(s1)
    80003272:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    80003274:	2004a023          	sw	zero,512(s1)
    80003278:	bf59                	j	8000320e <usertrap+0x11e>
            panic("Error !! usertrap: out of memory");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	0ee50513          	add	a0,a0,238 # 80008368 <states.0+0x78>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2ba080e7          	jalr	698(ra) # 8000053c <panic>
        p->priority += 1;
    8000328a:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    8000328e:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003292:	0000f797          	auipc	a5,0xf
    80003296:	d3e78793          	add	a5,a5,-706 # 80011fd0 <proc>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    8000329a:	4675                	li	a2,29
    8000329c:	450d                	li	a0,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    8000329e:	00018697          	auipc	a3,0x18
    800032a2:	93268693          	add	a3,a3,-1742 # 8001abd0 <tickslock>
    800032a6:	a029                	j	800032b0 <usertrap+0x1c0>
    800032a8:	23078793          	add	a5,a5,560
    800032ac:	02d78263          	beq	a5,a3,800032d0 <usertrap+0x1e0>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    800032b0:	2247a703          	lw	a4,548(a5)
    800032b4:	fee65ae3          	bge	a2,a4,800032a8 <usertrap+0x1b8>
    800032b8:	2207a703          	lw	a4,544(a5)
    800032bc:	d775                	beqz	a4,800032a8 <usertrap+0x1b8>
    800032be:	4f8c                	lw	a1,24(a5)
    800032c0:	fea594e3          	bne	a1,a0,800032a8 <usertrap+0x1b8>
            t->lastscheduledticks = 0;
    800032c4:	2207a223          	sw	zero,548(a5)
            t->priority -= 1;
    800032c8:	377d                	addw	a4,a4,-1
    800032ca:	22e7a023          	sw	a4,544(a5)
    800032ce:	bfe9                	j	800032a8 <usertrap+0x1b8>
        yield();
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	376080e7          	jalr	886(ra) # 80002646 <yield>
    800032d8:	b7a9                	j	80003222 <usertrap+0x132>
      else if (p->priority == 1 && p->ticks == 2)
    800032da:	4705                	li	a4,1
    800032dc:	02e78a63          	beq	a5,a4,80003310 <usertrap+0x220>
      else if (p->priority == 2 && p->ticks == 8)
    800032e0:	4709                	li	a4,2
    800032e2:	0ae79d63          	bne	a5,a4,8000339c <usertrap+0x2ac>
    800032e6:	2284a703          	lw	a4,552(s1)
    800032ea:	47a1                	li	a5,8
    800032ec:	f2f719e3          	bne	a4,a5,8000321e <usertrap+0x12e>
        p->priority += 1;
    800032f0:	478d                	li	a5,3
    800032f2:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    800032f6:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800032fa:	0000f797          	auipc	a5,0xf
    800032fe:	cd678793          	add	a5,a5,-810 # 80011fd0 <proc>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    80003302:	4675                	li	a2,29
    80003304:	450d                	li	a0,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003306:	00018697          	auipc	a3,0x18
    8000330a:	8ca68693          	add	a3,a3,-1846 # 8001abd0 <tickslock>
    8000330e:	a095                	j	80003372 <usertrap+0x282>
      else if (p->priority == 1 && p->ticks == 2)
    80003310:	2284a703          	lw	a4,552(s1)
    80003314:	4789                	li	a5,2
    80003316:	f0f714e3          	bne	a4,a5,8000321e <usertrap+0x12e>
        p->priority += 1;
    8000331a:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    8000331e:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003322:	0000f797          	auipc	a5,0xf
    80003326:	cae78793          	add	a5,a5,-850 # 80011fd0 <proc>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    8000332a:	4675                	li	a2,29
    8000332c:	450d                	li	a0,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    8000332e:	00018697          	auipc	a3,0x18
    80003332:	8a268693          	add	a3,a3,-1886 # 8001abd0 <tickslock>
    80003336:	a029                	j	80003340 <usertrap+0x250>
    80003338:	23078793          	add	a5,a5,560
    8000333c:	02d78263          	beq	a5,a3,80003360 <usertrap+0x270>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    80003340:	2247a703          	lw	a4,548(a5)
    80003344:	fee65ae3          	bge	a2,a4,80003338 <usertrap+0x248>
    80003348:	2207a703          	lw	a4,544(a5)
    8000334c:	d775                	beqz	a4,80003338 <usertrap+0x248>
    8000334e:	4f8c                	lw	a1,24(a5)
    80003350:	fea594e3          	bne	a1,a0,80003338 <usertrap+0x248>
            t->lastscheduledticks = 0;
    80003354:	2207a223          	sw	zero,548(a5)
            t->priority -= 1;
    80003358:	377d                	addw	a4,a4,-1
    8000335a:	22e7a023          	sw	a4,544(a5)
    8000335e:	bfe9                	j	80003338 <usertrap+0x248>
        yield();
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	2e6080e7          	jalr	742(ra) # 80002646 <yield>
    80003368:	bd6d                	j	80003222 <usertrap+0x132>
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    8000336a:	23078793          	add	a5,a5,560
    8000336e:	02d78263          	beq	a5,a3,80003392 <usertrap+0x2a2>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    80003372:	2247a703          	lw	a4,548(a5)
    80003376:	fee65ae3          	bge	a2,a4,8000336a <usertrap+0x27a>
    8000337a:	2207a703          	lw	a4,544(a5)
    8000337e:	d775                	beqz	a4,8000336a <usertrap+0x27a>
    80003380:	4f8c                	lw	a1,24(a5)
    80003382:	fea594e3          	bne	a1,a0,8000336a <usertrap+0x27a>
            t->lastscheduledticks = 0;
    80003386:	2207a223          	sw	zero,548(a5)
            t->priority -= 1;
    8000338a:	377d                	addw	a4,a4,-1
    8000338c:	22e7a023          	sw	a4,544(a5)
    80003390:	bfe9                	j	8000336a <usertrap+0x27a>
        yield();
    80003392:	fffff097          	auipc	ra,0xfffff
    80003396:	2b4080e7          	jalr	692(ra) # 80002646 <yield>
    8000339a:	b561                	j	80003222 <usertrap+0x132>
      else if (p->priority == 3 && p->ticks == 10)
    8000339c:	470d                	li	a4,3
    8000339e:	e8e790e3          	bne	a5,a4,8000321e <usertrap+0x12e>
    800033a2:	2284a703          	lw	a4,552(s1)
    800033a6:	47a9                	li	a5,10
    800033a8:	e6f71be3          	bne	a4,a5,8000321e <usertrap+0x12e>
        p->ticks = 0;
    800033ac:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800033b0:	0000f797          	auipc	a5,0xf
    800033b4:	c2078793          	add	a5,a5,-992 # 80011fd0 <proc>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    800033b8:	4675                	li	a2,29
    800033ba:	450d                	li	a0,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800033bc:	00018697          	auipc	a3,0x18
    800033c0:	81468693          	add	a3,a3,-2028 # 8001abd0 <tickslock>
    800033c4:	a029                	j	800033ce <usertrap+0x2de>
    800033c6:	23078793          	add	a5,a5,560
    800033ca:	02d78263          	beq	a5,a3,800033ee <usertrap+0x2fe>
          if (t->lastscheduledticks >= 30 && t->priority != 0 && t->state == RUNNABLE)
    800033ce:	2247a703          	lw	a4,548(a5)
    800033d2:	fee65ae3          	bge	a2,a4,800033c6 <usertrap+0x2d6>
    800033d6:	2207a703          	lw	a4,544(a5)
    800033da:	d775                	beqz	a4,800033c6 <usertrap+0x2d6>
    800033dc:	4f8c                	lw	a1,24(a5)
    800033de:	fea594e3          	bne	a1,a0,800033c6 <usertrap+0x2d6>
            t->lastscheduledticks = 0;
    800033e2:	2207a223          	sw	zero,548(a5)
            t->priority -= 1;
    800033e6:	377d                	addw	a4,a4,-1
    800033e8:	22e7a023          	sw	a4,544(a5)
    800033ec:	bfe9                	j	800033c6 <usertrap+0x2d6>
        yield();
    800033ee:	fffff097          	auipc	ra,0xfffff
    800033f2:	258080e7          	jalr	600(ra) # 80002646 <yield>
    800033f6:	b535                	j	80003222 <usertrap+0x132>
        yield();
    800033f8:	fffff097          	auipc	ra,0xfffff
    800033fc:	24e080e7          	jalr	590(ra) # 80002646 <yield>
    80003400:	b50d                	j	80003222 <usertrap+0x132>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003402:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003406:	5890                	lw	a2,48(s1)
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	f8850513          	add	a0,a0,-120 # 80008390 <states.0+0xa0>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	176080e7          	jalr	374(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003418:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000341c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003420:	00005517          	auipc	a0,0x5
    80003424:	fa050513          	add	a0,a0,-96 # 800083c0 <states.0+0xd0>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	15e080e7          	jalr	350(ra) # 80000586 <printf>
    setkilled(p);
    80003430:	8526                	mv	a0,s1
    80003432:	fffff097          	auipc	ra,0xfffff
    80003436:	4d8080e7          	jalr	1240(ra) # 8000290a <setkilled>
  if (which_dev == 2)
    8000343a:	b319                	j	80003140 <usertrap+0x50>
    exit(-1);
    8000343c:	557d                	li	a0,-1
    8000343e:	fffff097          	auipc	ra,0xfffff
    80003442:	378080e7          	jalr	888(ra) # 800027b6 <exit>
    80003446:	b321                	j	8000314e <usertrap+0x5e>

0000000080003448 <kerneltrap>:
{
    80003448:	7179                	add	sp,sp,-48
    8000344a:	f406                	sd	ra,40(sp)
    8000344c:	f022                	sd	s0,32(sp)
    8000344e:	ec26                	sd	s1,24(sp)
    80003450:	e84a                	sd	s2,16(sp)
    80003452:	e44e                	sd	s3,8(sp)
    80003454:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003456:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000345a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000345e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80003462:	1004f793          	and	a5,s1,256
    80003466:	cb85                	beqz	a5,80003496 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003468:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000346c:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    8000346e:	ef85                	bnez	a5,800034a6 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80003470:	00000097          	auipc	ra,0x0
    80003474:	bda080e7          	jalr	-1062(ra) # 8000304a <devintr>
    80003478:	cd1d                	beqz	a0,800034b6 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000347a:	4789                	li	a5,2
    8000347c:	06f50a63          	beq	a0,a5,800034f0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003480:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003484:	10049073          	csrw	sstatus,s1
}
    80003488:	70a2                	ld	ra,40(sp)
    8000348a:	7402                	ld	s0,32(sp)
    8000348c:	64e2                	ld	s1,24(sp)
    8000348e:	6942                	ld	s2,16(sp)
    80003490:	69a2                	ld	s3,8(sp)
    80003492:	6145                	add	sp,sp,48
    80003494:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003496:	00005517          	auipc	a0,0x5
    8000349a:	f4a50513          	add	a0,a0,-182 # 800083e0 <states.0+0xf0>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	09e080e7          	jalr	158(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	f6250513          	add	a0,a0,-158 # 80008408 <states.0+0x118>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	08e080e7          	jalr	142(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800034b6:	85ce                	mv	a1,s3
    800034b8:	00005517          	auipc	a0,0x5
    800034bc:	f7050513          	add	a0,a0,-144 # 80008428 <states.0+0x138>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	0c6080e7          	jalr	198(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034cc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034d0:	00005517          	auipc	a0,0x5
    800034d4:	f6850513          	add	a0,a0,-152 # 80008438 <states.0+0x148>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	0ae080e7          	jalr	174(ra) # 80000586 <printf>
    panic("kerneltrap");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	f7050513          	add	a0,a0,-144 # 80008450 <states.0+0x160>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	054080e7          	jalr	84(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	4b6080e7          	jalr	1206(ra) # 800019a6 <myproc>
    800034f8:	d541                	beqz	a0,80003480 <kerneltrap+0x38>
    800034fa:	ffffe097          	auipc	ra,0xffffe
    800034fe:	4ac080e7          	jalr	1196(ra) # 800019a6 <myproc>
    80003502:	4d18                	lw	a4,24(a0)
    80003504:	4791                	li	a5,4
    80003506:	f6f71de3          	bne	a4,a5,80003480 <kerneltrap+0x38>
    yield();
    8000350a:	fffff097          	auipc	ra,0xfffff
    8000350e:	13c080e7          	jalr	316(ra) # 80002646 <yield>
    80003512:	b7bd                	j	80003480 <kerneltrap+0x38>

0000000080003514 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003514:	1101                	add	sp,sp,-32
    80003516:	ec06                	sd	ra,24(sp)
    80003518:	e822                	sd	s0,16(sp)
    8000351a:	e426                	sd	s1,8(sp)
    8000351c:	1000                	add	s0,sp,32
    8000351e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	486080e7          	jalr	1158(ra) # 800019a6 <myproc>
  switch (n)
    80003528:	4795                	li	a5,5
    8000352a:	0497e163          	bltu	a5,s1,8000356c <argraw+0x58>
    8000352e:	048a                	sll	s1,s1,0x2
    80003530:	00005717          	auipc	a4,0x5
    80003534:	f5870713          	add	a4,a4,-168 # 80008488 <states.0+0x198>
    80003538:	94ba                	add	s1,s1,a4
    8000353a:	409c                	lw	a5,0(s1)
    8000353c:	97ba                	add	a5,a5,a4
    8000353e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80003540:	6d3c                	ld	a5,88(a0)
    80003542:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	64a2                	ld	s1,8(sp)
    8000354a:	6105                	add	sp,sp,32
    8000354c:	8082                	ret
    return p->trapframe->a1;
    8000354e:	6d3c                	ld	a5,88(a0)
    80003550:	7fa8                	ld	a0,120(a5)
    80003552:	bfcd                	j	80003544 <argraw+0x30>
    return p->trapframe->a2;
    80003554:	6d3c                	ld	a5,88(a0)
    80003556:	63c8                	ld	a0,128(a5)
    80003558:	b7f5                	j	80003544 <argraw+0x30>
    return p->trapframe->a3;
    8000355a:	6d3c                	ld	a5,88(a0)
    8000355c:	67c8                	ld	a0,136(a5)
    8000355e:	b7dd                	j	80003544 <argraw+0x30>
    return p->trapframe->a4;
    80003560:	6d3c                	ld	a5,88(a0)
    80003562:	6bc8                	ld	a0,144(a5)
    80003564:	b7c5                	j	80003544 <argraw+0x30>
    return p->trapframe->a5;
    80003566:	6d3c                	ld	a5,88(a0)
    80003568:	6fc8                	ld	a0,152(a5)
    8000356a:	bfe9                	j	80003544 <argraw+0x30>
  panic("argraw");
    8000356c:	00005517          	auipc	a0,0x5
    80003570:	ef450513          	add	a0,a0,-268 # 80008460 <states.0+0x170>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	fc8080e7          	jalr	-56(ra) # 8000053c <panic>

000000008000357c <fetchaddr>:
{
    8000357c:	1101                	add	sp,sp,-32
    8000357e:	ec06                	sd	ra,24(sp)
    80003580:	e822                	sd	s0,16(sp)
    80003582:	e426                	sd	s1,8(sp)
    80003584:	e04a                	sd	s2,0(sp)
    80003586:	1000                	add	s0,sp,32
    80003588:	84aa                	mv	s1,a0
    8000358a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000358c:	ffffe097          	auipc	ra,0xffffe
    80003590:	41a080e7          	jalr	1050(ra) # 800019a6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003594:	653c                	ld	a5,72(a0)
    80003596:	02f4f863          	bgeu	s1,a5,800035c6 <fetchaddr+0x4a>
    8000359a:	00848713          	add	a4,s1,8
    8000359e:	02e7e663          	bltu	a5,a4,800035ca <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800035a2:	46a1                	li	a3,8
    800035a4:	8626                	mv	a2,s1
    800035a6:	85ca                	mv	a1,s2
    800035a8:	6928                	ld	a0,80(a0)
    800035aa:	ffffe097          	auipc	ra,0xffffe
    800035ae:	148080e7          	jalr	328(ra) # 800016f2 <copyin>
    800035b2:	00a03533          	snez	a0,a0
    800035b6:	40a00533          	neg	a0,a0
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6902                	ld	s2,0(sp)
    800035c2:	6105                	add	sp,sp,32
    800035c4:	8082                	ret
    return -1;
    800035c6:	557d                	li	a0,-1
    800035c8:	bfcd                	j	800035ba <fetchaddr+0x3e>
    800035ca:	557d                	li	a0,-1
    800035cc:	b7fd                	j	800035ba <fetchaddr+0x3e>

00000000800035ce <fetchstr>:
{
    800035ce:	7179                	add	sp,sp,-48
    800035d0:	f406                	sd	ra,40(sp)
    800035d2:	f022                	sd	s0,32(sp)
    800035d4:	ec26                	sd	s1,24(sp)
    800035d6:	e84a                	sd	s2,16(sp)
    800035d8:	e44e                	sd	s3,8(sp)
    800035da:	1800                	add	s0,sp,48
    800035dc:	892a                	mv	s2,a0
    800035de:	84ae                	mv	s1,a1
    800035e0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800035e2:	ffffe097          	auipc	ra,0xffffe
    800035e6:	3c4080e7          	jalr	964(ra) # 800019a6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800035ea:	86ce                	mv	a3,s3
    800035ec:	864a                	mv	a2,s2
    800035ee:	85a6                	mv	a1,s1
    800035f0:	6928                	ld	a0,80(a0)
    800035f2:	ffffe097          	auipc	ra,0xffffe
    800035f6:	18e080e7          	jalr	398(ra) # 80001780 <copyinstr>
    800035fa:	00054e63          	bltz	a0,80003616 <fetchstr+0x48>
  return strlen(buf);
    800035fe:	8526                	mv	a0,s1
    80003600:	ffffe097          	auipc	ra,0xffffe
    80003604:	848080e7          	jalr	-1976(ra) # 80000e48 <strlen>
}
    80003608:	70a2                	ld	ra,40(sp)
    8000360a:	7402                	ld	s0,32(sp)
    8000360c:	64e2                	ld	s1,24(sp)
    8000360e:	6942                	ld	s2,16(sp)
    80003610:	69a2                	ld	s3,8(sp)
    80003612:	6145                	add	sp,sp,48
    80003614:	8082                	ret
    return -1;
    80003616:	557d                	li	a0,-1
    80003618:	bfc5                	j	80003608 <fetchstr+0x3a>

000000008000361a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000361a:	1101                	add	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	1000                	add	s0,sp,32
    80003624:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	eee080e7          	jalr	-274(ra) # 80003514 <argraw>
    8000362e:	c088                	sw	a0,0(s1)
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6105                	add	sp,sp,32
    80003638:	8082                	ret

000000008000363a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000363a:	1101                	add	sp,sp,-32
    8000363c:	ec06                	sd	ra,24(sp)
    8000363e:	e822                	sd	s0,16(sp)
    80003640:	e426                	sd	s1,8(sp)
    80003642:	1000                	add	s0,sp,32
    80003644:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	ece080e7          	jalr	-306(ra) # 80003514 <argraw>
    8000364e:	e088                	sd	a0,0(s1)
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6105                	add	sp,sp,32
    80003658:	8082                	ret

000000008000365a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000365a:	7179                	add	sp,sp,-48
    8000365c:	f406                	sd	ra,40(sp)
    8000365e:	f022                	sd	s0,32(sp)
    80003660:	ec26                	sd	s1,24(sp)
    80003662:	e84a                	sd	s2,16(sp)
    80003664:	1800                	add	s0,sp,48
    80003666:	84ae                	mv	s1,a1
    80003668:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000366a:	fd840593          	add	a1,s0,-40
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	fcc080e7          	jalr	-52(ra) # 8000363a <argaddr>
  return fetchstr(addr, buf, max);
    80003676:	864a                	mv	a2,s2
    80003678:	85a6                	mv	a1,s1
    8000367a:	fd843503          	ld	a0,-40(s0)
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	f50080e7          	jalr	-176(ra) # 800035ce <fetchstr>
}
    80003686:	70a2                	ld	ra,40(sp)
    80003688:	7402                	ld	s0,32(sp)
    8000368a:	64e2                	ld	s1,24(sp)
    8000368c:	6942                	ld	s2,16(sp)
    8000368e:	6145                	add	sp,sp,48
    80003690:	8082                	ret

0000000080003692 <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    80003692:	1101                	add	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	e04a                	sd	s2,0(sp)
    8000369c:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000369e:	ffffe097          	auipc	ra,0xffffe
    800036a2:	308080e7          	jalr	776(ra) # 800019a6 <myproc>
    800036a6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800036a8:	05853903          	ld	s2,88(a0)
    800036ac:	0a893783          	ld	a5,168(s2)
    800036b0:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800036b4:	37fd                	addw	a5,a5,-1
    800036b6:	4765                	li	a4,25
    800036b8:	02f76763          	bltu	a4,a5,800036e6 <syscall+0x54>
    800036bc:	00369713          	sll	a4,a3,0x3
    800036c0:	00005797          	auipc	a5,0x5
    800036c4:	de078793          	add	a5,a5,-544 # 800084a0 <syscalls>
    800036c8:	97ba                	add	a5,a5,a4
    800036ca:	6398                	ld	a4,0(a5)
    800036cc:	cf09                	beqz	a4,800036e6 <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    800036ce:	068a                	sll	a3,a3,0x2
    800036d0:	00d504b3          	add	s1,a0,a3
    800036d4:	1704a783          	lw	a5,368(s1)
    800036d8:	2785                	addw	a5,a5,1
    800036da:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    800036de:	9702                	jalr	a4
    800036e0:	06a93823          	sd	a0,112(s2)
    800036e4:	a839                	j	80003702 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800036e6:	15848613          	add	a2,s1,344
    800036ea:	588c                	lw	a1,48(s1)
    800036ec:	00005517          	auipc	a0,0x5
    800036f0:	d7c50513          	add	a0,a0,-644 # 80008468 <states.0+0x178>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	e92080e7          	jalr	-366(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800036fc:	6cbc                	ld	a5,88(s1)
    800036fe:	577d                	li	a4,-1
    80003700:	fbb8                	sd	a4,112(a5)
  }
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6902                	ld	s2,0(sp)
    8000370a:	6105                	add	sp,sp,32
    8000370c:	8082                	ret

000000008000370e <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    8000370e:	1101                	add	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003716:	fec40593          	add	a1,s0,-20
    8000371a:	4501                	li	a0,0
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	efe080e7          	jalr	-258(ra) # 8000361a <argint>
  exit(n);
    80003724:	fec42503          	lw	a0,-20(s0)
    80003728:	fffff097          	auipc	ra,0xfffff
    8000372c:	08e080e7          	jalr	142(ra) # 800027b6 <exit>
  return 0; // not reached
}
    80003730:	4501                	li	a0,0
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	6105                	add	sp,sp,32
    80003738:	8082                	ret

000000008000373a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000373a:	1141                	add	sp,sp,-16
    8000373c:	e406                	sd	ra,8(sp)
    8000373e:	e022                	sd	s0,0(sp)
    80003740:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003742:	ffffe097          	auipc	ra,0xffffe
    80003746:	264080e7          	jalr	612(ra) # 800019a6 <myproc>
}
    8000374a:	5908                	lw	a0,48(a0)
    8000374c:	60a2                	ld	ra,8(sp)
    8000374e:	6402                	ld	s0,0(sp)
    80003750:	0141                	add	sp,sp,16
    80003752:	8082                	ret

0000000080003754 <sys_fork>:

uint64
sys_fork(void)
{
    80003754:	1141                	add	sp,sp,-16
    80003756:	e406                	sd	ra,8(sp)
    80003758:	e022                	sd	s0,0(sp)
    8000375a:	0800                	add	s0,sp,16
  return fork();
    8000375c:	ffffe097          	auipc	ra,0xffffe
    80003760:	65a080e7          	jalr	1626(ra) # 80001db6 <fork>
}
    80003764:	60a2                	ld	ra,8(sp)
    80003766:	6402                	ld	s0,0(sp)
    80003768:	0141                	add	sp,sp,16
    8000376a:	8082                	ret

000000008000376c <sys_wait>:

uint64
sys_wait(void)
{
    8000376c:	1101                	add	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003774:	fe840593          	add	a1,s0,-24
    80003778:	4501                	li	a0,0
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	ec0080e7          	jalr	-320(ra) # 8000363a <argaddr>
  return wait(p);
    80003782:	fe843503          	ld	a0,-24(s0)
    80003786:	fffff097          	auipc	ra,0xfffff
    8000378a:	1e2080e7          	jalr	482(ra) # 80002968 <wait>
}
    8000378e:	60e2                	ld	ra,24(sp)
    80003790:	6442                	ld	s0,16(sp)
    80003792:	6105                	add	sp,sp,32
    80003794:	8082                	ret

0000000080003796 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003796:	7179                	add	sp,sp,-48
    80003798:	f406                	sd	ra,40(sp)
    8000379a:	f022                	sd	s0,32(sp)
    8000379c:	ec26                	sd	s1,24(sp)
    8000379e:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800037a0:	fdc40593          	add	a1,s0,-36
    800037a4:	4501                	li	a0,0
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	e74080e7          	jalr	-396(ra) # 8000361a <argint>
  addr = myproc()->sz;
    800037ae:	ffffe097          	auipc	ra,0xffffe
    800037b2:	1f8080e7          	jalr	504(ra) # 800019a6 <myproc>
    800037b6:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800037b8:	fdc42503          	lw	a0,-36(s0)
    800037bc:	ffffe097          	auipc	ra,0xffffe
    800037c0:	59e080e7          	jalr	1438(ra) # 80001d5a <growproc>
    800037c4:	00054863          	bltz	a0,800037d4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800037c8:	8526                	mv	a0,s1
    800037ca:	70a2                	ld	ra,40(sp)
    800037cc:	7402                	ld	s0,32(sp)
    800037ce:	64e2                	ld	s1,24(sp)
    800037d0:	6145                	add	sp,sp,48
    800037d2:	8082                	ret
    return -1;
    800037d4:	54fd                	li	s1,-1
    800037d6:	bfcd                	j	800037c8 <sys_sbrk+0x32>

00000000800037d8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800037d8:	7139                	add	sp,sp,-64
    800037da:	fc06                	sd	ra,56(sp)
    800037dc:	f822                	sd	s0,48(sp)
    800037de:	f426                	sd	s1,40(sp)
    800037e0:	f04a                	sd	s2,32(sp)
    800037e2:	ec4e                	sd	s3,24(sp)
    800037e4:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800037e6:	fcc40593          	add	a1,s0,-52
    800037ea:	4501                	li	a0,0
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	e2e080e7          	jalr	-466(ra) # 8000361a <argint>
  acquire(&tickslock);
    800037f4:	00017517          	auipc	a0,0x17
    800037f8:	3dc50513          	add	a0,a0,988 # 8001abd0 <tickslock>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3d6080e7          	jalr	982(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003804:	00005917          	auipc	s2,0x5
    80003808:	19492903          	lw	s2,404(s2) # 80008998 <ticks>
  while (ticks - ticks0 < n)
    8000380c:	fcc42783          	lw	a5,-52(s0)
    80003810:	cf9d                	beqz	a5,8000384e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003812:	00017997          	auipc	s3,0x17
    80003816:	3be98993          	add	s3,s3,958 # 8001abd0 <tickslock>
    8000381a:	00005497          	auipc	s1,0x5
    8000381e:	17e48493          	add	s1,s1,382 # 80008998 <ticks>
    if (killed(myproc()))
    80003822:	ffffe097          	auipc	ra,0xffffe
    80003826:	184080e7          	jalr	388(ra) # 800019a6 <myproc>
    8000382a:	fffff097          	auipc	ra,0xfffff
    8000382e:	10c080e7          	jalr	268(ra) # 80002936 <killed>
    80003832:	ed15                	bnez	a0,8000386e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003834:	85ce                	mv	a1,s3
    80003836:	8526                	mv	a0,s1
    80003838:	fffff097          	auipc	ra,0xfffff
    8000383c:	e4a080e7          	jalr	-438(ra) # 80002682 <sleep>
  while (ticks - ticks0 < n)
    80003840:	409c                	lw	a5,0(s1)
    80003842:	412787bb          	subw	a5,a5,s2
    80003846:	fcc42703          	lw	a4,-52(s0)
    8000384a:	fce7ece3          	bltu	a5,a4,80003822 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000384e:	00017517          	auipc	a0,0x17
    80003852:	38250513          	add	a0,a0,898 # 8001abd0 <tickslock>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	430080e7          	jalr	1072(ra) # 80000c86 <release>
  return 0;
    8000385e:	4501                	li	a0,0
}
    80003860:	70e2                	ld	ra,56(sp)
    80003862:	7442                	ld	s0,48(sp)
    80003864:	74a2                	ld	s1,40(sp)
    80003866:	7902                	ld	s2,32(sp)
    80003868:	69e2                	ld	s3,24(sp)
    8000386a:	6121                	add	sp,sp,64
    8000386c:	8082                	ret
      release(&tickslock);
    8000386e:	00017517          	auipc	a0,0x17
    80003872:	36250513          	add	a0,a0,866 # 8001abd0 <tickslock>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	410080e7          	jalr	1040(ra) # 80000c86 <release>
      return -1;
    8000387e:	557d                	li	a0,-1
    80003880:	b7c5                	j	80003860 <sys_sleep+0x88>

0000000080003882 <sys_kill>:

uint64
sys_kill(void)
{
    80003882:	1101                	add	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    8000388a:	fec40593          	add	a1,s0,-20
    8000388e:	4501                	li	a0,0
    80003890:	00000097          	auipc	ra,0x0
    80003894:	d8a080e7          	jalr	-630(ra) # 8000361a <argint>
  return kill(pid);
    80003898:	fec42503          	lw	a0,-20(s0)
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	ffc080e7          	jalr	-4(ra) # 80002898 <kill>
}
    800038a4:	60e2                	ld	ra,24(sp)
    800038a6:	6442                	ld	s0,16(sp)
    800038a8:	6105                	add	sp,sp,32
    800038aa:	8082                	ret

00000000800038ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038ac:	1101                	add	sp,sp,-32
    800038ae:	ec06                	sd	ra,24(sp)
    800038b0:	e822                	sd	s0,16(sp)
    800038b2:	e426                	sd	s1,8(sp)
    800038b4:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038b6:	00017517          	auipc	a0,0x17
    800038ba:	31a50513          	add	a0,a0,794 # 8001abd0 <tickslock>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	314080e7          	jalr	788(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800038c6:	00005497          	auipc	s1,0x5
    800038ca:	0d24a483          	lw	s1,210(s1) # 80008998 <ticks>
  release(&tickslock);
    800038ce:	00017517          	auipc	a0,0x17
    800038d2:	30250513          	add	a0,a0,770 # 8001abd0 <tickslock>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	3b0080e7          	jalr	944(ra) # 80000c86 <release>
  return xticks;
}
    800038de:	02049513          	sll	a0,s1,0x20
    800038e2:	9101                	srl	a0,a0,0x20
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6105                	add	sp,sp,32
    800038ec:	8082                	ret

00000000800038ee <sys_waitx>:

uint64
sys_waitx(void)
{
    800038ee:	7139                	add	sp,sp,-64
    800038f0:	fc06                	sd	ra,56(sp)
    800038f2:	f822                	sd	s0,48(sp)
    800038f4:	f426                	sd	s1,40(sp)
    800038f6:	f04a                	sd	s2,32(sp)
    800038f8:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800038fa:	fd840593          	add	a1,s0,-40
    800038fe:	4501                	li	a0,0
    80003900:	00000097          	auipc	ra,0x0
    80003904:	d3a080e7          	jalr	-710(ra) # 8000363a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003908:	fd040593          	add	a1,s0,-48
    8000390c:	4505                	li	a0,1
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	d2c080e7          	jalr	-724(ra) # 8000363a <argaddr>
  argaddr(2, &addr2);
    80003916:	fc840593          	add	a1,s0,-56
    8000391a:	4509                	li	a0,2
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	d1e080e7          	jalr	-738(ra) # 8000363a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003924:	fc040613          	add	a2,s0,-64
    80003928:	fc440593          	add	a1,s0,-60
    8000392c:	fd843503          	ld	a0,-40(s0)
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	2da080e7          	jalr	730(ra) # 80002c0a <waitx>
    80003938:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000393a:	ffffe097          	auipc	ra,0xffffe
    8000393e:	06c080e7          	jalr	108(ra) # 800019a6 <myproc>
    80003942:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003944:	4691                	li	a3,4
    80003946:	fc440613          	add	a2,s0,-60
    8000394a:	fd043583          	ld	a1,-48(s0)
    8000394e:	6928                	ld	a0,80(a0)
    80003950:	ffffe097          	auipc	ra,0xffffe
    80003954:	d16080e7          	jalr	-746(ra) # 80001666 <copyout>
    return -1;
    80003958:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000395a:	00054f63          	bltz	a0,80003978 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000395e:	4691                	li	a3,4
    80003960:	fc040613          	add	a2,s0,-64
    80003964:	fc843583          	ld	a1,-56(s0)
    80003968:	68a8                	ld	a0,80(s1)
    8000396a:	ffffe097          	auipc	ra,0xffffe
    8000396e:	cfc080e7          	jalr	-772(ra) # 80001666 <copyout>
    80003972:	00054a63          	bltz	a0,80003986 <sys_waitx+0x98>
    return -1;
  return ret;
    80003976:	87ca                	mv	a5,s2
}
    80003978:	853e                	mv	a0,a5
    8000397a:	70e2                	ld	ra,56(sp)
    8000397c:	7442                	ld	s0,48(sp)
    8000397e:	74a2                	ld	s1,40(sp)
    80003980:	7902                	ld	s2,32(sp)
    80003982:	6121                	add	sp,sp,64
    80003984:	8082                	ret
    return -1;
    80003986:	57fd                	li	a5,-1
    80003988:	bfc5                	j	80003978 <sys_waitx+0x8a>

000000008000398a <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    8000398a:	7179                	add	sp,sp,-48
    8000398c:	f406                	sd	ra,40(sp)
    8000398e:	f022                	sd	s0,32(sp)
    80003990:	ec26                	sd	s1,24(sp)
    80003992:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    80003994:	ffffe097          	auipc	ra,0xffffe
    80003998:	012080e7          	jalr	18(ra) # 800019a6 <myproc>
    8000399c:	84aa                	mv	s1,a0
  // for (int i = 0; i < 31; i++)
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }

  argint(0, &mask);
    8000399e:	fdc40593          	add	a1,s0,-36
    800039a2:	4501                	li	a0,0
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	c76080e7          	jalr	-906(ra) # 8000361a <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    800039ac:	fdc42583          	lw	a1,-36(s0)
    800039b0:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    800039b4:	4781                	li	a5,0
  int count = 0;
    800039b6:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    800039b8:	467d                	li	a2,31
    800039ba:	a029                	j	800039c4 <sys_getSysCount+0x3a>
    800039bc:	2785                	addw	a5,a5,1
    800039be:	0691                	add	a3,a3,4
    800039c0:	00c78963          	beq	a5,a2,800039d2 <sys_getSysCount+0x48>
    if (mask & (1 << i))
    800039c4:	40f5d73b          	sraw	a4,a1,a5
    800039c8:	8b05                	and	a4,a4,1
    800039ca:	db6d                	beqz	a4,800039bc <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i - 1]; // Add up the syscall counts
    800039cc:	4298                	lw	a4,0(a3)
    800039ce:	9d39                	addw	a0,a0,a4
    800039d0:	b7f5                	j	800039bc <sys_getSysCount+0x32>
    }
  }

  return count;
}
    800039d2:	70a2                	ld	ra,40(sp)
    800039d4:	7402                	ld	s0,32(sp)
    800039d6:	64e2                	ld	s1,24(sp)
    800039d8:	6145                	add	sp,sp,48
    800039da:	8082                	ret

00000000800039dc <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    800039dc:	1101                	add	sp,sp,-32
    800039de:	ec06                	sd	ra,24(sp)
    800039e0:	e822                	sd	s0,16(sp)
    800039e2:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    800039e4:	fec40593          	add	a1,s0,-20
    800039e8:	4501                	li	a0,0
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	c30080e7          	jalr	-976(ra) # 8000361a <argint>

  argaddr(1, &handler);
    800039f2:	fe040593          	add	a1,s0,-32
    800039f6:	4505                	li	a0,1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	c42080e7          	jalr	-958(ra) # 8000363a <argaddr>

  struct proc *p = myproc();
    80003a00:	ffffe097          	auipc	ra,0xffffe
    80003a04:	fa6080e7          	jalr	-90(ra) # 800019a6 <myproc>
  p->alarm_interval = interval;
    80003a08:	fec42783          	lw	a5,-20(s0)
    80003a0c:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void (*)())handler;
    80003a10:	fe043703          	ld	a4,-32(s0)
    80003a14:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    80003a18:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    80003a1c:	00f027b3          	sgtz	a5,a5
    80003a20:	20f52223          	sw	a5,516(a0)

  return 0;
}
    80003a24:	4501                	li	a0,0
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	6105                	add	sp,sp,32
    80003a2c:	8082                	ret

0000000080003a2e <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    80003a2e:	1101                	add	sp,sp,-32
    80003a30:	ec06                	sd	ra,24(sp)
    80003a32:	e822                	sd	s0,16(sp)
    80003a34:	e426                	sd	s1,8(sp)
    80003a36:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80003a38:	ffffe097          	auipc	ra,0xffffe
    80003a3c:	f6e080e7          	jalr	-146(ra) # 800019a6 <myproc>

  if (p->alarm_tf)
    80003a40:	20853583          	ld	a1,520(a0)
    80003a44:	c585                	beqz	a1,80003a6c <sys_sigreturn+0x3e>
    80003a46:	84aa                	mv	s1,a0
  {
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    80003a48:	12000613          	li	a2,288
    80003a4c:	6d28                	ld	a0,88(a0)
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	2dc080e7          	jalr	732(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    80003a56:	2084b503          	ld	a0,520(s1)
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	f8a080e7          	jalr	-118(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    80003a62:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1; // Re-enable the alarm
    80003a66:	4785                	li	a5,1
    80003a68:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret(); // function that returns the command back to the user space
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	4f4080e7          	jalr	1268(ra) # 80002f60 <usertrapret>
  return 0;
}
    80003a74:	4501                	li	a0,0
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6105                	add	sp,sp,32
    80003a7e:	8082                	ret

0000000080003a80 <sys_settickets>:

// settickets system call
uint64 sys_settickets(void)
{
    80003a80:	1101                	add	sp,sp,-32
    80003a82:	ec06                	sd	ra,24(sp)
    80003a84:	e822                	sd	s0,16(sp)
    80003a86:	1000                	add	s0,sp,32
  int n;

  // Get the number of tickets from the user
  argint(0, &n);
    80003a88:	fec40593          	add	a1,s0,-20
    80003a8c:	4501                	li	a0,0
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	b8c080e7          	jalr	-1140(ra) # 8000361a <argint>
  // Ensure the ticket number is valid (greater than 0)
  if (n < 1)
    80003a96:	fec42783          	lw	a5,-20(s0)
    80003a9a:	00f05f63          	blez	a5,80003ab8 <sys_settickets+0x38>
    printf("entered ticket is invalid error");
    return -1; // Error: invalid ticket count
  }

  // Set the calling process's ticket count
  myproc()->tickets = n;
    80003a9e:	ffffe097          	auipc	ra,0xffffe
    80003aa2:	f08080e7          	jalr	-248(ra) # 800019a6 <myproc>
    80003aa6:	fec42783          	lw	a5,-20(s0)
    80003aaa:	20f52823          	sw	a5,528(a0)

  return 0; // Success
    80003aae:	4501                	li	a0,0
}
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	6105                	add	sp,sp,32
    80003ab6:	8082                	ret
    printf("entered ticket is invalid error");
    80003ab8:	00005517          	auipc	a0,0x5
    80003abc:	ac050513          	add	a0,a0,-1344 # 80008578 <syscalls+0xd8>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	ac6080e7          	jalr	-1338(ra) # 80000586 <printf>
    return -1; // Error: invalid ticket count
    80003ac8:	557d                	li	a0,-1
    80003aca:	b7dd                	j	80003ab0 <sys_settickets+0x30>

0000000080003acc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003acc:	7179                	add	sp,sp,-48
    80003ace:	f406                	sd	ra,40(sp)
    80003ad0:	f022                	sd	s0,32(sp)
    80003ad2:	ec26                	sd	s1,24(sp)
    80003ad4:	e84a                	sd	s2,16(sp)
    80003ad6:	e44e                	sd	s3,8(sp)
    80003ad8:	e052                	sd	s4,0(sp)
    80003ada:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003adc:	00005597          	auipc	a1,0x5
    80003ae0:	abc58593          	add	a1,a1,-1348 # 80008598 <syscalls+0xf8>
    80003ae4:	00017517          	auipc	a0,0x17
    80003ae8:	10450513          	add	a0,a0,260 # 8001abe8 <bcache>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	056080e7          	jalr	86(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003af4:	0001f797          	auipc	a5,0x1f
    80003af8:	0f478793          	add	a5,a5,244 # 80022be8 <bcache+0x8000>
    80003afc:	0001f717          	auipc	a4,0x1f
    80003b00:	35470713          	add	a4,a4,852 # 80022e50 <bcache+0x8268>
    80003b04:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003b08:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b0c:	00017497          	auipc	s1,0x17
    80003b10:	0f448493          	add	s1,s1,244 # 8001ac00 <bcache+0x18>
    b->next = bcache.head.next;
    80003b14:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b16:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b18:	00005a17          	auipc	s4,0x5
    80003b1c:	a88a0a13          	add	s4,s4,-1400 # 800085a0 <syscalls+0x100>
    b->next = bcache.head.next;
    80003b20:	2b893783          	ld	a5,696(s2)
    80003b24:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003b26:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b2a:	85d2                	mv	a1,s4
    80003b2c:	01048513          	add	a0,s1,16
    80003b30:	00001097          	auipc	ra,0x1
    80003b34:	496080e7          	jalr	1174(ra) # 80004fc6 <initsleeplock>
    bcache.head.next->prev = b;
    80003b38:	2b893783          	ld	a5,696(s2)
    80003b3c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b3e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b42:	45848493          	add	s1,s1,1112
    80003b46:	fd349de3          	bne	s1,s3,80003b20 <binit+0x54>
  }
}
    80003b4a:	70a2                	ld	ra,40(sp)
    80003b4c:	7402                	ld	s0,32(sp)
    80003b4e:	64e2                	ld	s1,24(sp)
    80003b50:	6942                	ld	s2,16(sp)
    80003b52:	69a2                	ld	s3,8(sp)
    80003b54:	6a02                	ld	s4,0(sp)
    80003b56:	6145                	add	sp,sp,48
    80003b58:	8082                	ret

0000000080003b5a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b5a:	7179                	add	sp,sp,-48
    80003b5c:	f406                	sd	ra,40(sp)
    80003b5e:	f022                	sd	s0,32(sp)
    80003b60:	ec26                	sd	s1,24(sp)
    80003b62:	e84a                	sd	s2,16(sp)
    80003b64:	e44e                	sd	s3,8(sp)
    80003b66:	1800                	add	s0,sp,48
    80003b68:	892a                	mv	s2,a0
    80003b6a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003b6c:	00017517          	auipc	a0,0x17
    80003b70:	07c50513          	add	a0,a0,124 # 8001abe8 <bcache>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	05e080e7          	jalr	94(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b7c:	0001f497          	auipc	s1,0x1f
    80003b80:	3244b483          	ld	s1,804(s1) # 80022ea0 <bcache+0x82b8>
    80003b84:	0001f797          	auipc	a5,0x1f
    80003b88:	2cc78793          	add	a5,a5,716 # 80022e50 <bcache+0x8268>
    80003b8c:	02f48f63          	beq	s1,a5,80003bca <bread+0x70>
    80003b90:	873e                	mv	a4,a5
    80003b92:	a021                	j	80003b9a <bread+0x40>
    80003b94:	68a4                	ld	s1,80(s1)
    80003b96:	02e48a63          	beq	s1,a4,80003bca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b9a:	449c                	lw	a5,8(s1)
    80003b9c:	ff279ce3          	bne	a5,s2,80003b94 <bread+0x3a>
    80003ba0:	44dc                	lw	a5,12(s1)
    80003ba2:	ff3799e3          	bne	a5,s3,80003b94 <bread+0x3a>
      b->refcnt++;
    80003ba6:	40bc                	lw	a5,64(s1)
    80003ba8:	2785                	addw	a5,a5,1
    80003baa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bac:	00017517          	auipc	a0,0x17
    80003bb0:	03c50513          	add	a0,a0,60 # 8001abe8 <bcache>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	0d2080e7          	jalr	210(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003bbc:	01048513          	add	a0,s1,16
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	440080e7          	jalr	1088(ra) # 80005000 <acquiresleep>
      return b;
    80003bc8:	a8b9                	j	80003c26 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bca:	0001f497          	auipc	s1,0x1f
    80003bce:	2ce4b483          	ld	s1,718(s1) # 80022e98 <bcache+0x82b0>
    80003bd2:	0001f797          	auipc	a5,0x1f
    80003bd6:	27e78793          	add	a5,a5,638 # 80022e50 <bcache+0x8268>
    80003bda:	00f48863          	beq	s1,a5,80003bea <bread+0x90>
    80003bde:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003be0:	40bc                	lw	a5,64(s1)
    80003be2:	cf81                	beqz	a5,80003bfa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003be4:	64a4                	ld	s1,72(s1)
    80003be6:	fee49de3          	bne	s1,a4,80003be0 <bread+0x86>
  panic("bget: no buffers");
    80003bea:	00005517          	auipc	a0,0x5
    80003bee:	9be50513          	add	a0,a0,-1602 # 800085a8 <syscalls+0x108>
    80003bf2:	ffffd097          	auipc	ra,0xffffd
    80003bf6:	94a080e7          	jalr	-1718(ra) # 8000053c <panic>
      b->dev = dev;
    80003bfa:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003bfe:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003c02:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003c06:	4785                	li	a5,1
    80003c08:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c0a:	00017517          	auipc	a0,0x17
    80003c0e:	fde50513          	add	a0,a0,-34 # 8001abe8 <bcache>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	074080e7          	jalr	116(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003c1a:	01048513          	add	a0,s1,16
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	3e2080e7          	jalr	994(ra) # 80005000 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003c26:	409c                	lw	a5,0(s1)
    80003c28:	cb89                	beqz	a5,80003c3a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c2a:	8526                	mv	a0,s1
    80003c2c:	70a2                	ld	ra,40(sp)
    80003c2e:	7402                	ld	s0,32(sp)
    80003c30:	64e2                	ld	s1,24(sp)
    80003c32:	6942                	ld	s2,16(sp)
    80003c34:	69a2                	ld	s3,8(sp)
    80003c36:	6145                	add	sp,sp,48
    80003c38:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c3a:	4581                	li	a1,0
    80003c3c:	8526                	mv	a0,s1
    80003c3e:	00003097          	auipc	ra,0x3
    80003c42:	f84080e7          	jalr	-124(ra) # 80006bc2 <virtio_disk_rw>
    b->valid = 1;
    80003c46:	4785                	li	a5,1
    80003c48:	c09c                	sw	a5,0(s1)
  return b;
    80003c4a:	b7c5                	j	80003c2a <bread+0xd0>

0000000080003c4c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c4c:	1101                	add	sp,sp,-32
    80003c4e:	ec06                	sd	ra,24(sp)
    80003c50:	e822                	sd	s0,16(sp)
    80003c52:	e426                	sd	s1,8(sp)
    80003c54:	1000                	add	s0,sp,32
    80003c56:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c58:	0541                	add	a0,a0,16
    80003c5a:	00001097          	auipc	ra,0x1
    80003c5e:	440080e7          	jalr	1088(ra) # 8000509a <holdingsleep>
    80003c62:	cd01                	beqz	a0,80003c7a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c64:	4585                	li	a1,1
    80003c66:	8526                	mv	a0,s1
    80003c68:	00003097          	auipc	ra,0x3
    80003c6c:	f5a080e7          	jalr	-166(ra) # 80006bc2 <virtio_disk_rw>
}
    80003c70:	60e2                	ld	ra,24(sp)
    80003c72:	6442                	ld	s0,16(sp)
    80003c74:	64a2                	ld	s1,8(sp)
    80003c76:	6105                	add	sp,sp,32
    80003c78:	8082                	ret
    panic("bwrite");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	94650513          	add	a0,a0,-1722 # 800085c0 <syscalls+0x120>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8ba080e7          	jalr	-1862(ra) # 8000053c <panic>

0000000080003c8a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c8a:	1101                	add	sp,sp,-32
    80003c8c:	ec06                	sd	ra,24(sp)
    80003c8e:	e822                	sd	s0,16(sp)
    80003c90:	e426                	sd	s1,8(sp)
    80003c92:	e04a                	sd	s2,0(sp)
    80003c94:	1000                	add	s0,sp,32
    80003c96:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c98:	01050913          	add	s2,a0,16
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	00001097          	auipc	ra,0x1
    80003ca2:	3fc080e7          	jalr	1020(ra) # 8000509a <holdingsleep>
    80003ca6:	c925                	beqz	a0,80003d16 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	00001097          	auipc	ra,0x1
    80003cae:	3ac080e7          	jalr	940(ra) # 80005056 <releasesleep>

  acquire(&bcache.lock);
    80003cb2:	00017517          	auipc	a0,0x17
    80003cb6:	f3650513          	add	a0,a0,-202 # 8001abe8 <bcache>
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	f18080e7          	jalr	-232(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003cc2:	40bc                	lw	a5,64(s1)
    80003cc4:	37fd                	addw	a5,a5,-1
    80003cc6:	0007871b          	sext.w	a4,a5
    80003cca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ccc:	e71d                	bnez	a4,80003cfa <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003cce:	68b8                	ld	a4,80(s1)
    80003cd0:	64bc                	ld	a5,72(s1)
    80003cd2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003cd4:	68b8                	ld	a4,80(s1)
    80003cd6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003cd8:	0001f797          	auipc	a5,0x1f
    80003cdc:	f1078793          	add	a5,a5,-240 # 80022be8 <bcache+0x8000>
    80003ce0:	2b87b703          	ld	a4,696(a5)
    80003ce4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003ce6:	0001f717          	auipc	a4,0x1f
    80003cea:	16a70713          	add	a4,a4,362 # 80022e50 <bcache+0x8268>
    80003cee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003cf0:	2b87b703          	ld	a4,696(a5)
    80003cf4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cf6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cfa:	00017517          	auipc	a0,0x17
    80003cfe:	eee50513          	add	a0,a0,-274 # 8001abe8 <bcache>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	f84080e7          	jalr	-124(ra) # 80000c86 <release>
}
    80003d0a:	60e2                	ld	ra,24(sp)
    80003d0c:	6442                	ld	s0,16(sp)
    80003d0e:	64a2                	ld	s1,8(sp)
    80003d10:	6902                	ld	s2,0(sp)
    80003d12:	6105                	add	sp,sp,32
    80003d14:	8082                	ret
    panic("brelse");
    80003d16:	00005517          	auipc	a0,0x5
    80003d1a:	8b250513          	add	a0,a0,-1870 # 800085c8 <syscalls+0x128>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	81e080e7          	jalr	-2018(ra) # 8000053c <panic>

0000000080003d26 <bpin>:

void
bpin(struct buf *b) {
    80003d26:	1101                	add	sp,sp,-32
    80003d28:	ec06                	sd	ra,24(sp)
    80003d2a:	e822                	sd	s0,16(sp)
    80003d2c:	e426                	sd	s1,8(sp)
    80003d2e:	1000                	add	s0,sp,32
    80003d30:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d32:	00017517          	auipc	a0,0x17
    80003d36:	eb650513          	add	a0,a0,-330 # 8001abe8 <bcache>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	e98080e7          	jalr	-360(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003d42:	40bc                	lw	a5,64(s1)
    80003d44:	2785                	addw	a5,a5,1
    80003d46:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d48:	00017517          	auipc	a0,0x17
    80003d4c:	ea050513          	add	a0,a0,-352 # 8001abe8 <bcache>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	f36080e7          	jalr	-202(ra) # 80000c86 <release>
}
    80003d58:	60e2                	ld	ra,24(sp)
    80003d5a:	6442                	ld	s0,16(sp)
    80003d5c:	64a2                	ld	s1,8(sp)
    80003d5e:	6105                	add	sp,sp,32
    80003d60:	8082                	ret

0000000080003d62 <bunpin>:

void
bunpin(struct buf *b) {
    80003d62:	1101                	add	sp,sp,-32
    80003d64:	ec06                	sd	ra,24(sp)
    80003d66:	e822                	sd	s0,16(sp)
    80003d68:	e426                	sd	s1,8(sp)
    80003d6a:	1000                	add	s0,sp,32
    80003d6c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d6e:	00017517          	auipc	a0,0x17
    80003d72:	e7a50513          	add	a0,a0,-390 # 8001abe8 <bcache>
    80003d76:	ffffd097          	auipc	ra,0xffffd
    80003d7a:	e5c080e7          	jalr	-420(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003d7e:	40bc                	lw	a5,64(s1)
    80003d80:	37fd                	addw	a5,a5,-1
    80003d82:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d84:	00017517          	auipc	a0,0x17
    80003d88:	e6450513          	add	a0,a0,-412 # 8001abe8 <bcache>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	efa080e7          	jalr	-262(ra) # 80000c86 <release>
}
    80003d94:	60e2                	ld	ra,24(sp)
    80003d96:	6442                	ld	s0,16(sp)
    80003d98:	64a2                	ld	s1,8(sp)
    80003d9a:	6105                	add	sp,sp,32
    80003d9c:	8082                	ret

0000000080003d9e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d9e:	1101                	add	sp,sp,-32
    80003da0:	ec06                	sd	ra,24(sp)
    80003da2:	e822                	sd	s0,16(sp)
    80003da4:	e426                	sd	s1,8(sp)
    80003da6:	e04a                	sd	s2,0(sp)
    80003da8:	1000                	add	s0,sp,32
    80003daa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003dac:	00d5d59b          	srlw	a1,a1,0xd
    80003db0:	0001f797          	auipc	a5,0x1f
    80003db4:	5147a783          	lw	a5,1300(a5) # 800232c4 <sb+0x1c>
    80003db8:	9dbd                	addw	a1,a1,a5
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	da0080e7          	jalr	-608(ra) # 80003b5a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003dc2:	0074f713          	and	a4,s1,7
    80003dc6:	4785                	li	a5,1
    80003dc8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003dcc:	14ce                	sll	s1,s1,0x33
    80003dce:	90d9                	srl	s1,s1,0x36
    80003dd0:	00950733          	add	a4,a0,s1
    80003dd4:	05874703          	lbu	a4,88(a4)
    80003dd8:	00e7f6b3          	and	a3,a5,a4
    80003ddc:	c69d                	beqz	a3,80003e0a <bfree+0x6c>
    80003dde:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003de0:	94aa                	add	s1,s1,a0
    80003de2:	fff7c793          	not	a5,a5
    80003de6:	8f7d                	and	a4,a4,a5
    80003de8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	0f6080e7          	jalr	246(ra) # 80004ee2 <log_write>
  brelse(bp);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	e94080e7          	jalr	-364(ra) # 80003c8a <brelse>
}
    80003dfe:	60e2                	ld	ra,24(sp)
    80003e00:	6442                	ld	s0,16(sp)
    80003e02:	64a2                	ld	s1,8(sp)
    80003e04:	6902                	ld	s2,0(sp)
    80003e06:	6105                	add	sp,sp,32
    80003e08:	8082                	ret
    panic("freeing free block");
    80003e0a:	00004517          	auipc	a0,0x4
    80003e0e:	7c650513          	add	a0,a0,1990 # 800085d0 <syscalls+0x130>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	72a080e7          	jalr	1834(ra) # 8000053c <panic>

0000000080003e1a <balloc>:
{
    80003e1a:	711d                	add	sp,sp,-96
    80003e1c:	ec86                	sd	ra,88(sp)
    80003e1e:	e8a2                	sd	s0,80(sp)
    80003e20:	e4a6                	sd	s1,72(sp)
    80003e22:	e0ca                	sd	s2,64(sp)
    80003e24:	fc4e                	sd	s3,56(sp)
    80003e26:	f852                	sd	s4,48(sp)
    80003e28:	f456                	sd	s5,40(sp)
    80003e2a:	f05a                	sd	s6,32(sp)
    80003e2c:	ec5e                	sd	s7,24(sp)
    80003e2e:	e862                	sd	s8,16(sp)
    80003e30:	e466                	sd	s9,8(sp)
    80003e32:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e34:	0001f797          	auipc	a5,0x1f
    80003e38:	4787a783          	lw	a5,1144(a5) # 800232ac <sb+0x4>
    80003e3c:	cff5                	beqz	a5,80003f38 <balloc+0x11e>
    80003e3e:	8baa                	mv	s7,a0
    80003e40:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e42:	0001fb17          	auipc	s6,0x1f
    80003e46:	466b0b13          	add	s6,s6,1126 # 800232a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e4a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e4c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e4e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e50:	6c89                	lui	s9,0x2
    80003e52:	a061                	j	80003eda <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e54:	97ca                	add	a5,a5,s2
    80003e56:	8e55                	or	a2,a2,a3
    80003e58:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00001097          	auipc	ra,0x1
    80003e62:	084080e7          	jalr	132(ra) # 80004ee2 <log_write>
        brelse(bp);
    80003e66:	854a                	mv	a0,s2
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	e22080e7          	jalr	-478(ra) # 80003c8a <brelse>
  bp = bread(dev, bno);
    80003e70:	85a6                	mv	a1,s1
    80003e72:	855e                	mv	a0,s7
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	ce6080e7          	jalr	-794(ra) # 80003b5a <bread>
    80003e7c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e7e:	40000613          	li	a2,1024
    80003e82:	4581                	li	a1,0
    80003e84:	05850513          	add	a0,a0,88
    80003e88:	ffffd097          	auipc	ra,0xffffd
    80003e8c:	e46080e7          	jalr	-442(ra) # 80000cce <memset>
  log_write(bp);
    80003e90:	854a                	mv	a0,s2
    80003e92:	00001097          	auipc	ra,0x1
    80003e96:	050080e7          	jalr	80(ra) # 80004ee2 <log_write>
  brelse(bp);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	dee080e7          	jalr	-530(ra) # 80003c8a <brelse>
}
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	60e6                	ld	ra,88(sp)
    80003ea8:	6446                	ld	s0,80(sp)
    80003eaa:	64a6                	ld	s1,72(sp)
    80003eac:	6906                	ld	s2,64(sp)
    80003eae:	79e2                	ld	s3,56(sp)
    80003eb0:	7a42                	ld	s4,48(sp)
    80003eb2:	7aa2                	ld	s5,40(sp)
    80003eb4:	7b02                	ld	s6,32(sp)
    80003eb6:	6be2                	ld	s7,24(sp)
    80003eb8:	6c42                	ld	s8,16(sp)
    80003eba:	6ca2                	ld	s9,8(sp)
    80003ebc:	6125                	add	sp,sp,96
    80003ebe:	8082                	ret
    brelse(bp);
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	dc8080e7          	jalr	-568(ra) # 80003c8a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003eca:	015c87bb          	addw	a5,s9,s5
    80003ece:	00078a9b          	sext.w	s5,a5
    80003ed2:	004b2703          	lw	a4,4(s6)
    80003ed6:	06eaf163          	bgeu	s5,a4,80003f38 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003eda:	41fad79b          	sraw	a5,s5,0x1f
    80003ede:	0137d79b          	srlw	a5,a5,0x13
    80003ee2:	015787bb          	addw	a5,a5,s5
    80003ee6:	40d7d79b          	sraw	a5,a5,0xd
    80003eea:	01cb2583          	lw	a1,28(s6)
    80003eee:	9dbd                	addw	a1,a1,a5
    80003ef0:	855e                	mv	a0,s7
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	c68080e7          	jalr	-920(ra) # 80003b5a <bread>
    80003efa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003efc:	004b2503          	lw	a0,4(s6)
    80003f00:	000a849b          	sext.w	s1,s5
    80003f04:	8762                	mv	a4,s8
    80003f06:	faa4fde3          	bgeu	s1,a0,80003ec0 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003f0a:	00777693          	and	a3,a4,7
    80003f0e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003f12:	41f7579b          	sraw	a5,a4,0x1f
    80003f16:	01d7d79b          	srlw	a5,a5,0x1d
    80003f1a:	9fb9                	addw	a5,a5,a4
    80003f1c:	4037d79b          	sraw	a5,a5,0x3
    80003f20:	00f90633          	add	a2,s2,a5
    80003f24:	05864603          	lbu	a2,88(a2)
    80003f28:	00c6f5b3          	and	a1,a3,a2
    80003f2c:	d585                	beqz	a1,80003e54 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f2e:	2705                	addw	a4,a4,1
    80003f30:	2485                	addw	s1,s1,1
    80003f32:	fd471ae3          	bne	a4,s4,80003f06 <balloc+0xec>
    80003f36:	b769                	j	80003ec0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003f38:	00004517          	auipc	a0,0x4
    80003f3c:	6b050513          	add	a0,a0,1712 # 800085e8 <syscalls+0x148>
    80003f40:	ffffc097          	auipc	ra,0xffffc
    80003f44:	646080e7          	jalr	1606(ra) # 80000586 <printf>
  return 0;
    80003f48:	4481                	li	s1,0
    80003f4a:	bfa9                	j	80003ea4 <balloc+0x8a>

0000000080003f4c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f4c:	7179                	add	sp,sp,-48
    80003f4e:	f406                	sd	ra,40(sp)
    80003f50:	f022                	sd	s0,32(sp)
    80003f52:	ec26                	sd	s1,24(sp)
    80003f54:	e84a                	sd	s2,16(sp)
    80003f56:	e44e                	sd	s3,8(sp)
    80003f58:	e052                	sd	s4,0(sp)
    80003f5a:	1800                	add	s0,sp,48
    80003f5c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f5e:	47ad                	li	a5,11
    80003f60:	02b7e863          	bltu	a5,a1,80003f90 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003f64:	02059793          	sll	a5,a1,0x20
    80003f68:	01e7d593          	srl	a1,a5,0x1e
    80003f6c:	00b504b3          	add	s1,a0,a1
    80003f70:	0504a903          	lw	s2,80(s1)
    80003f74:	06091e63          	bnez	s2,80003ff0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003f78:	4108                	lw	a0,0(a0)
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	ea0080e7          	jalr	-352(ra) # 80003e1a <balloc>
    80003f82:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f86:	06090563          	beqz	s2,80003ff0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003f8a:	0524a823          	sw	s2,80(s1)
    80003f8e:	a08d                	j	80003ff0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003f90:	ff45849b          	addw	s1,a1,-12
    80003f94:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f98:	0ff00793          	li	a5,255
    80003f9c:	08e7e563          	bltu	a5,a4,80004026 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003fa0:	08052903          	lw	s2,128(a0)
    80003fa4:	00091d63          	bnez	s2,80003fbe <bmap+0x72>
      addr = balloc(ip->dev);
    80003fa8:	4108                	lw	a0,0(a0)
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	e70080e7          	jalr	-400(ra) # 80003e1a <balloc>
    80003fb2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003fb6:	02090d63          	beqz	s2,80003ff0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003fba:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003fbe:	85ca                	mv	a1,s2
    80003fc0:	0009a503          	lw	a0,0(s3)
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	b96080e7          	jalr	-1130(ra) # 80003b5a <bread>
    80003fcc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003fce:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003fd2:	02049713          	sll	a4,s1,0x20
    80003fd6:	01e75593          	srl	a1,a4,0x1e
    80003fda:	00b784b3          	add	s1,a5,a1
    80003fde:	0004a903          	lw	s2,0(s1)
    80003fe2:	02090063          	beqz	s2,80004002 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003fe6:	8552                	mv	a0,s4
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	ca2080e7          	jalr	-862(ra) # 80003c8a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	70a2                	ld	ra,40(sp)
    80003ff4:	7402                	ld	s0,32(sp)
    80003ff6:	64e2                	ld	s1,24(sp)
    80003ff8:	6942                	ld	s2,16(sp)
    80003ffa:	69a2                	ld	s3,8(sp)
    80003ffc:	6a02                	ld	s4,0(sp)
    80003ffe:	6145                	add	sp,sp,48
    80004000:	8082                	ret
      addr = balloc(ip->dev);
    80004002:	0009a503          	lw	a0,0(s3)
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	e14080e7          	jalr	-492(ra) # 80003e1a <balloc>
    8000400e:	0005091b          	sext.w	s2,a0
      if(addr){
    80004012:	fc090ae3          	beqz	s2,80003fe6 <bmap+0x9a>
        a[bn] = addr;
    80004016:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000401a:	8552                	mv	a0,s4
    8000401c:	00001097          	auipc	ra,0x1
    80004020:	ec6080e7          	jalr	-314(ra) # 80004ee2 <log_write>
    80004024:	b7c9                	j	80003fe6 <bmap+0x9a>
  panic("bmap: out of range");
    80004026:	00004517          	auipc	a0,0x4
    8000402a:	5da50513          	add	a0,a0,1498 # 80008600 <syscalls+0x160>
    8000402e:	ffffc097          	auipc	ra,0xffffc
    80004032:	50e080e7          	jalr	1294(ra) # 8000053c <panic>

0000000080004036 <iget>:
{
    80004036:	7179                	add	sp,sp,-48
    80004038:	f406                	sd	ra,40(sp)
    8000403a:	f022                	sd	s0,32(sp)
    8000403c:	ec26                	sd	s1,24(sp)
    8000403e:	e84a                	sd	s2,16(sp)
    80004040:	e44e                	sd	s3,8(sp)
    80004042:	e052                	sd	s4,0(sp)
    80004044:	1800                	add	s0,sp,48
    80004046:	89aa                	mv	s3,a0
    80004048:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000404a:	0001f517          	auipc	a0,0x1f
    8000404e:	27e50513          	add	a0,a0,638 # 800232c8 <itable>
    80004052:	ffffd097          	auipc	ra,0xffffd
    80004056:	b80080e7          	jalr	-1152(ra) # 80000bd2 <acquire>
  empty = 0;
    8000405a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000405c:	0001f497          	auipc	s1,0x1f
    80004060:	28448493          	add	s1,s1,644 # 800232e0 <itable+0x18>
    80004064:	00021697          	auipc	a3,0x21
    80004068:	d0c68693          	add	a3,a3,-756 # 80024d70 <log>
    8000406c:	a039                	j	8000407a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000406e:	02090b63          	beqz	s2,800040a4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004072:	08848493          	add	s1,s1,136
    80004076:	02d48a63          	beq	s1,a3,800040aa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000407a:	449c                	lw	a5,8(s1)
    8000407c:	fef059e3          	blez	a5,8000406e <iget+0x38>
    80004080:	4098                	lw	a4,0(s1)
    80004082:	ff3716e3          	bne	a4,s3,8000406e <iget+0x38>
    80004086:	40d8                	lw	a4,4(s1)
    80004088:	ff4713e3          	bne	a4,s4,8000406e <iget+0x38>
      ip->ref++;
    8000408c:	2785                	addw	a5,a5,1
    8000408e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004090:	0001f517          	auipc	a0,0x1f
    80004094:	23850513          	add	a0,a0,568 # 800232c8 <itable>
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	bee080e7          	jalr	-1042(ra) # 80000c86 <release>
      return ip;
    800040a0:	8926                	mv	s2,s1
    800040a2:	a03d                	j	800040d0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040a4:	f7f9                	bnez	a5,80004072 <iget+0x3c>
    800040a6:	8926                	mv	s2,s1
    800040a8:	b7e9                	j	80004072 <iget+0x3c>
  if(empty == 0)
    800040aa:	02090c63          	beqz	s2,800040e2 <iget+0xac>
  ip->dev = dev;
    800040ae:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800040b2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800040b6:	4785                	li	a5,1
    800040b8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800040bc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800040c0:	0001f517          	auipc	a0,0x1f
    800040c4:	20850513          	add	a0,a0,520 # 800232c8 <itable>
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	bbe080e7          	jalr	-1090(ra) # 80000c86 <release>
}
    800040d0:	854a                	mv	a0,s2
    800040d2:	70a2                	ld	ra,40(sp)
    800040d4:	7402                	ld	s0,32(sp)
    800040d6:	64e2                	ld	s1,24(sp)
    800040d8:	6942                	ld	s2,16(sp)
    800040da:	69a2                	ld	s3,8(sp)
    800040dc:	6a02                	ld	s4,0(sp)
    800040de:	6145                	add	sp,sp,48
    800040e0:	8082                	ret
    panic("iget: no inodes");
    800040e2:	00004517          	auipc	a0,0x4
    800040e6:	53650513          	add	a0,a0,1334 # 80008618 <syscalls+0x178>
    800040ea:	ffffc097          	auipc	ra,0xffffc
    800040ee:	452080e7          	jalr	1106(ra) # 8000053c <panic>

00000000800040f2 <fsinit>:
fsinit(int dev) {
    800040f2:	7179                	add	sp,sp,-48
    800040f4:	f406                	sd	ra,40(sp)
    800040f6:	f022                	sd	s0,32(sp)
    800040f8:	ec26                	sd	s1,24(sp)
    800040fa:	e84a                	sd	s2,16(sp)
    800040fc:	e44e                	sd	s3,8(sp)
    800040fe:	1800                	add	s0,sp,48
    80004100:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004102:	4585                	li	a1,1
    80004104:	00000097          	auipc	ra,0x0
    80004108:	a56080e7          	jalr	-1450(ra) # 80003b5a <bread>
    8000410c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000410e:	0001f997          	auipc	s3,0x1f
    80004112:	19a98993          	add	s3,s3,410 # 800232a8 <sb>
    80004116:	02000613          	li	a2,32
    8000411a:	05850593          	add	a1,a0,88
    8000411e:	854e                	mv	a0,s3
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	c0a080e7          	jalr	-1014(ra) # 80000d2a <memmove>
  brelse(bp);
    80004128:	8526                	mv	a0,s1
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	b60080e7          	jalr	-1184(ra) # 80003c8a <brelse>
  if(sb.magic != FSMAGIC)
    80004132:	0009a703          	lw	a4,0(s3)
    80004136:	102037b7          	lui	a5,0x10203
    8000413a:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000413e:	02f71263          	bne	a4,a5,80004162 <fsinit+0x70>
  initlog(dev, &sb);
    80004142:	0001f597          	auipc	a1,0x1f
    80004146:	16658593          	add	a1,a1,358 # 800232a8 <sb>
    8000414a:	854a                	mv	a0,s2
    8000414c:	00001097          	auipc	ra,0x1
    80004150:	b2c080e7          	jalr	-1236(ra) # 80004c78 <initlog>
}
    80004154:	70a2                	ld	ra,40(sp)
    80004156:	7402                	ld	s0,32(sp)
    80004158:	64e2                	ld	s1,24(sp)
    8000415a:	6942                	ld	s2,16(sp)
    8000415c:	69a2                	ld	s3,8(sp)
    8000415e:	6145                	add	sp,sp,48
    80004160:	8082                	ret
    panic("invalid file system");
    80004162:	00004517          	auipc	a0,0x4
    80004166:	4c650513          	add	a0,a0,1222 # 80008628 <syscalls+0x188>
    8000416a:	ffffc097          	auipc	ra,0xffffc
    8000416e:	3d2080e7          	jalr	978(ra) # 8000053c <panic>

0000000080004172 <iinit>:
{
    80004172:	7179                	add	sp,sp,-48
    80004174:	f406                	sd	ra,40(sp)
    80004176:	f022                	sd	s0,32(sp)
    80004178:	ec26                	sd	s1,24(sp)
    8000417a:	e84a                	sd	s2,16(sp)
    8000417c:	e44e                	sd	s3,8(sp)
    8000417e:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80004180:	00004597          	auipc	a1,0x4
    80004184:	4c058593          	add	a1,a1,1216 # 80008640 <syscalls+0x1a0>
    80004188:	0001f517          	auipc	a0,0x1f
    8000418c:	14050513          	add	a0,a0,320 # 800232c8 <itable>
    80004190:	ffffd097          	auipc	ra,0xffffd
    80004194:	9b2080e7          	jalr	-1614(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004198:	0001f497          	auipc	s1,0x1f
    8000419c:	15848493          	add	s1,s1,344 # 800232f0 <itable+0x28>
    800041a0:	00021997          	auipc	s3,0x21
    800041a4:	be098993          	add	s3,s3,-1056 # 80024d80 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800041a8:	00004917          	auipc	s2,0x4
    800041ac:	4a090913          	add	s2,s2,1184 # 80008648 <syscalls+0x1a8>
    800041b0:	85ca                	mv	a1,s2
    800041b2:	8526                	mv	a0,s1
    800041b4:	00001097          	auipc	ra,0x1
    800041b8:	e12080e7          	jalr	-494(ra) # 80004fc6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800041bc:	08848493          	add	s1,s1,136
    800041c0:	ff3498e3          	bne	s1,s3,800041b0 <iinit+0x3e>
}
    800041c4:	70a2                	ld	ra,40(sp)
    800041c6:	7402                	ld	s0,32(sp)
    800041c8:	64e2                	ld	s1,24(sp)
    800041ca:	6942                	ld	s2,16(sp)
    800041cc:	69a2                	ld	s3,8(sp)
    800041ce:	6145                	add	sp,sp,48
    800041d0:	8082                	ret

00000000800041d2 <ialloc>:
{
    800041d2:	7139                	add	sp,sp,-64
    800041d4:	fc06                	sd	ra,56(sp)
    800041d6:	f822                	sd	s0,48(sp)
    800041d8:	f426                	sd	s1,40(sp)
    800041da:	f04a                	sd	s2,32(sp)
    800041dc:	ec4e                	sd	s3,24(sp)
    800041de:	e852                	sd	s4,16(sp)
    800041e0:	e456                	sd	s5,8(sp)
    800041e2:	e05a                	sd	s6,0(sp)
    800041e4:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800041e6:	0001f717          	auipc	a4,0x1f
    800041ea:	0ce72703          	lw	a4,206(a4) # 800232b4 <sb+0xc>
    800041ee:	4785                	li	a5,1
    800041f0:	04e7f863          	bgeu	a5,a4,80004240 <ialloc+0x6e>
    800041f4:	8aaa                	mv	s5,a0
    800041f6:	8b2e                	mv	s6,a1
    800041f8:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041fa:	0001fa17          	auipc	s4,0x1f
    800041fe:	0aea0a13          	add	s4,s4,174 # 800232a8 <sb>
    80004202:	00495593          	srl	a1,s2,0x4
    80004206:	018a2783          	lw	a5,24(s4)
    8000420a:	9dbd                	addw	a1,a1,a5
    8000420c:	8556                	mv	a0,s5
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	94c080e7          	jalr	-1716(ra) # 80003b5a <bread>
    80004216:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004218:	05850993          	add	s3,a0,88
    8000421c:	00f97793          	and	a5,s2,15
    80004220:	079a                	sll	a5,a5,0x6
    80004222:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004224:	00099783          	lh	a5,0(s3)
    80004228:	cf9d                	beqz	a5,80004266 <ialloc+0x94>
    brelse(bp);
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	a60080e7          	jalr	-1440(ra) # 80003c8a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004232:	0905                	add	s2,s2,1
    80004234:	00ca2703          	lw	a4,12(s4)
    80004238:	0009079b          	sext.w	a5,s2
    8000423c:	fce7e3e3          	bltu	a5,a4,80004202 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80004240:	00004517          	auipc	a0,0x4
    80004244:	41050513          	add	a0,a0,1040 # 80008650 <syscalls+0x1b0>
    80004248:	ffffc097          	auipc	ra,0xffffc
    8000424c:	33e080e7          	jalr	830(ra) # 80000586 <printf>
  return 0;
    80004250:	4501                	li	a0,0
}
    80004252:	70e2                	ld	ra,56(sp)
    80004254:	7442                	ld	s0,48(sp)
    80004256:	74a2                	ld	s1,40(sp)
    80004258:	7902                	ld	s2,32(sp)
    8000425a:	69e2                	ld	s3,24(sp)
    8000425c:	6a42                	ld	s4,16(sp)
    8000425e:	6aa2                	ld	s5,8(sp)
    80004260:	6b02                	ld	s6,0(sp)
    80004262:	6121                	add	sp,sp,64
    80004264:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004266:	04000613          	li	a2,64
    8000426a:	4581                	li	a1,0
    8000426c:	854e                	mv	a0,s3
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	a60080e7          	jalr	-1440(ra) # 80000cce <memset>
      dip->type = type;
    80004276:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000427a:	8526                	mv	a0,s1
    8000427c:	00001097          	auipc	ra,0x1
    80004280:	c66080e7          	jalr	-922(ra) # 80004ee2 <log_write>
      brelse(bp);
    80004284:	8526                	mv	a0,s1
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	a04080e7          	jalr	-1532(ra) # 80003c8a <brelse>
      return iget(dev, inum);
    8000428e:	0009059b          	sext.w	a1,s2
    80004292:	8556                	mv	a0,s5
    80004294:	00000097          	auipc	ra,0x0
    80004298:	da2080e7          	jalr	-606(ra) # 80004036 <iget>
    8000429c:	bf5d                	j	80004252 <ialloc+0x80>

000000008000429e <iupdate>:
{
    8000429e:	1101                	add	sp,sp,-32
    800042a0:	ec06                	sd	ra,24(sp)
    800042a2:	e822                	sd	s0,16(sp)
    800042a4:	e426                	sd	s1,8(sp)
    800042a6:	e04a                	sd	s2,0(sp)
    800042a8:	1000                	add	s0,sp,32
    800042aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042ac:	415c                	lw	a5,4(a0)
    800042ae:	0047d79b          	srlw	a5,a5,0x4
    800042b2:	0001f597          	auipc	a1,0x1f
    800042b6:	00e5a583          	lw	a1,14(a1) # 800232c0 <sb+0x18>
    800042ba:	9dbd                	addw	a1,a1,a5
    800042bc:	4108                	lw	a0,0(a0)
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	89c080e7          	jalr	-1892(ra) # 80003b5a <bread>
    800042c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042c8:	05850793          	add	a5,a0,88
    800042cc:	40d8                	lw	a4,4(s1)
    800042ce:	8b3d                	and	a4,a4,15
    800042d0:	071a                	sll	a4,a4,0x6
    800042d2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800042d4:	04449703          	lh	a4,68(s1)
    800042d8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800042dc:	04649703          	lh	a4,70(s1)
    800042e0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800042e4:	04849703          	lh	a4,72(s1)
    800042e8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800042ec:	04a49703          	lh	a4,74(s1)
    800042f0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800042f4:	44f8                	lw	a4,76(s1)
    800042f6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042f8:	03400613          	li	a2,52
    800042fc:	05048593          	add	a1,s1,80
    80004300:	00c78513          	add	a0,a5,12
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	a26080e7          	jalr	-1498(ra) # 80000d2a <memmove>
  log_write(bp);
    8000430c:	854a                	mv	a0,s2
    8000430e:	00001097          	auipc	ra,0x1
    80004312:	bd4080e7          	jalr	-1068(ra) # 80004ee2 <log_write>
  brelse(bp);
    80004316:	854a                	mv	a0,s2
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	972080e7          	jalr	-1678(ra) # 80003c8a <brelse>
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	add	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <idup>:
{
    8000432c:	1101                	add	sp,sp,-32
    8000432e:	ec06                	sd	ra,24(sp)
    80004330:	e822                	sd	s0,16(sp)
    80004332:	e426                	sd	s1,8(sp)
    80004334:	1000                	add	s0,sp,32
    80004336:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004338:	0001f517          	auipc	a0,0x1f
    8000433c:	f9050513          	add	a0,a0,-112 # 800232c8 <itable>
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	892080e7          	jalr	-1902(ra) # 80000bd2 <acquire>
  ip->ref++;
    80004348:	449c                	lw	a5,8(s1)
    8000434a:	2785                	addw	a5,a5,1
    8000434c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000434e:	0001f517          	auipc	a0,0x1f
    80004352:	f7a50513          	add	a0,a0,-134 # 800232c8 <itable>
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	930080e7          	jalr	-1744(ra) # 80000c86 <release>
}
    8000435e:	8526                	mv	a0,s1
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	64a2                	ld	s1,8(sp)
    80004366:	6105                	add	sp,sp,32
    80004368:	8082                	ret

000000008000436a <ilock>:
{
    8000436a:	1101                	add	sp,sp,-32
    8000436c:	ec06                	sd	ra,24(sp)
    8000436e:	e822                	sd	s0,16(sp)
    80004370:	e426                	sd	s1,8(sp)
    80004372:	e04a                	sd	s2,0(sp)
    80004374:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004376:	c115                	beqz	a0,8000439a <ilock+0x30>
    80004378:	84aa                	mv	s1,a0
    8000437a:	451c                	lw	a5,8(a0)
    8000437c:	00f05f63          	blez	a5,8000439a <ilock+0x30>
  acquiresleep(&ip->lock);
    80004380:	0541                	add	a0,a0,16
    80004382:	00001097          	auipc	ra,0x1
    80004386:	c7e080e7          	jalr	-898(ra) # 80005000 <acquiresleep>
  if(ip->valid == 0){
    8000438a:	40bc                	lw	a5,64(s1)
    8000438c:	cf99                	beqz	a5,800043aa <ilock+0x40>
}
    8000438e:	60e2                	ld	ra,24(sp)
    80004390:	6442                	ld	s0,16(sp)
    80004392:	64a2                	ld	s1,8(sp)
    80004394:	6902                	ld	s2,0(sp)
    80004396:	6105                	add	sp,sp,32
    80004398:	8082                	ret
    panic("ilock");
    8000439a:	00004517          	auipc	a0,0x4
    8000439e:	2ce50513          	add	a0,a0,718 # 80008668 <syscalls+0x1c8>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	19a080e7          	jalr	410(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800043aa:	40dc                	lw	a5,4(s1)
    800043ac:	0047d79b          	srlw	a5,a5,0x4
    800043b0:	0001f597          	auipc	a1,0x1f
    800043b4:	f105a583          	lw	a1,-240(a1) # 800232c0 <sb+0x18>
    800043b8:	9dbd                	addw	a1,a1,a5
    800043ba:	4088                	lw	a0,0(s1)
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	79e080e7          	jalr	1950(ra) # 80003b5a <bread>
    800043c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800043c6:	05850593          	add	a1,a0,88
    800043ca:	40dc                	lw	a5,4(s1)
    800043cc:	8bbd                	and	a5,a5,15
    800043ce:	079a                	sll	a5,a5,0x6
    800043d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800043d2:	00059783          	lh	a5,0(a1)
    800043d6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800043da:	00259783          	lh	a5,2(a1)
    800043de:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043e2:	00459783          	lh	a5,4(a1)
    800043e6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043ea:	00659783          	lh	a5,6(a1)
    800043ee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043f2:	459c                	lw	a5,8(a1)
    800043f4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043f6:	03400613          	li	a2,52
    800043fa:	05b1                	add	a1,a1,12
    800043fc:	05048513          	add	a0,s1,80
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	92a080e7          	jalr	-1750(ra) # 80000d2a <memmove>
    brelse(bp);
    80004408:	854a                	mv	a0,s2
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	880080e7          	jalr	-1920(ra) # 80003c8a <brelse>
    ip->valid = 1;
    80004412:	4785                	li	a5,1
    80004414:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004416:	04449783          	lh	a5,68(s1)
    8000441a:	fbb5                	bnez	a5,8000438e <ilock+0x24>
      panic("ilock: no type");
    8000441c:	00004517          	auipc	a0,0x4
    80004420:	25450513          	add	a0,a0,596 # 80008670 <syscalls+0x1d0>
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	118080e7          	jalr	280(ra) # 8000053c <panic>

000000008000442c <iunlock>:
{
    8000442c:	1101                	add	sp,sp,-32
    8000442e:	ec06                	sd	ra,24(sp)
    80004430:	e822                	sd	s0,16(sp)
    80004432:	e426                	sd	s1,8(sp)
    80004434:	e04a                	sd	s2,0(sp)
    80004436:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004438:	c905                	beqz	a0,80004468 <iunlock+0x3c>
    8000443a:	84aa                	mv	s1,a0
    8000443c:	01050913          	add	s2,a0,16
    80004440:	854a                	mv	a0,s2
    80004442:	00001097          	auipc	ra,0x1
    80004446:	c58080e7          	jalr	-936(ra) # 8000509a <holdingsleep>
    8000444a:	cd19                	beqz	a0,80004468 <iunlock+0x3c>
    8000444c:	449c                	lw	a5,8(s1)
    8000444e:	00f05d63          	blez	a5,80004468 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004452:	854a                	mv	a0,s2
    80004454:	00001097          	auipc	ra,0x1
    80004458:	c02080e7          	jalr	-1022(ra) # 80005056 <releasesleep>
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	add	sp,sp,32
    80004466:	8082                	ret
    panic("iunlock");
    80004468:	00004517          	auipc	a0,0x4
    8000446c:	21850513          	add	a0,a0,536 # 80008680 <syscalls+0x1e0>
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	0cc080e7          	jalr	204(ra) # 8000053c <panic>

0000000080004478 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004478:	7179                	add	sp,sp,-48
    8000447a:	f406                	sd	ra,40(sp)
    8000447c:	f022                	sd	s0,32(sp)
    8000447e:	ec26                	sd	s1,24(sp)
    80004480:	e84a                	sd	s2,16(sp)
    80004482:	e44e                	sd	s3,8(sp)
    80004484:	e052                	sd	s4,0(sp)
    80004486:	1800                	add	s0,sp,48
    80004488:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000448a:	05050493          	add	s1,a0,80
    8000448e:	08050913          	add	s2,a0,128
    80004492:	a021                	j	8000449a <itrunc+0x22>
    80004494:	0491                	add	s1,s1,4
    80004496:	01248d63          	beq	s1,s2,800044b0 <itrunc+0x38>
    if(ip->addrs[i]){
    8000449a:	408c                	lw	a1,0(s1)
    8000449c:	dde5                	beqz	a1,80004494 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000449e:	0009a503          	lw	a0,0(s3)
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	8fc080e7          	jalr	-1796(ra) # 80003d9e <bfree>
      ip->addrs[i] = 0;
    800044aa:	0004a023          	sw	zero,0(s1)
    800044ae:	b7dd                	j	80004494 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800044b0:	0809a583          	lw	a1,128(s3)
    800044b4:	e185                	bnez	a1,800044d4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800044b6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800044ba:	854e                	mv	a0,s3
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	de2080e7          	jalr	-542(ra) # 8000429e <iupdate>
}
    800044c4:	70a2                	ld	ra,40(sp)
    800044c6:	7402                	ld	s0,32(sp)
    800044c8:	64e2                	ld	s1,24(sp)
    800044ca:	6942                	ld	s2,16(sp)
    800044cc:	69a2                	ld	s3,8(sp)
    800044ce:	6a02                	ld	s4,0(sp)
    800044d0:	6145                	add	sp,sp,48
    800044d2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800044d4:	0009a503          	lw	a0,0(s3)
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	682080e7          	jalr	1666(ra) # 80003b5a <bread>
    800044e0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044e2:	05850493          	add	s1,a0,88
    800044e6:	45850913          	add	s2,a0,1112
    800044ea:	a021                	j	800044f2 <itrunc+0x7a>
    800044ec:	0491                	add	s1,s1,4
    800044ee:	01248b63          	beq	s1,s2,80004504 <itrunc+0x8c>
      if(a[j])
    800044f2:	408c                	lw	a1,0(s1)
    800044f4:	dde5                	beqz	a1,800044ec <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800044f6:	0009a503          	lw	a0,0(s3)
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	8a4080e7          	jalr	-1884(ra) # 80003d9e <bfree>
    80004502:	b7ed                	j	800044ec <itrunc+0x74>
    brelse(bp);
    80004504:	8552                	mv	a0,s4
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	784080e7          	jalr	1924(ra) # 80003c8a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000450e:	0809a583          	lw	a1,128(s3)
    80004512:	0009a503          	lw	a0,0(s3)
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	888080e7          	jalr	-1912(ra) # 80003d9e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000451e:	0809a023          	sw	zero,128(s3)
    80004522:	bf51                	j	800044b6 <itrunc+0x3e>

0000000080004524 <iput>:
{
    80004524:	1101                	add	sp,sp,-32
    80004526:	ec06                	sd	ra,24(sp)
    80004528:	e822                	sd	s0,16(sp)
    8000452a:	e426                	sd	s1,8(sp)
    8000452c:	e04a                	sd	s2,0(sp)
    8000452e:	1000                	add	s0,sp,32
    80004530:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004532:	0001f517          	auipc	a0,0x1f
    80004536:	d9650513          	add	a0,a0,-618 # 800232c8 <itable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	698080e7          	jalr	1688(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004542:	4498                	lw	a4,8(s1)
    80004544:	4785                	li	a5,1
    80004546:	02f70363          	beq	a4,a5,8000456c <iput+0x48>
  ip->ref--;
    8000454a:	449c                	lw	a5,8(s1)
    8000454c:	37fd                	addw	a5,a5,-1
    8000454e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004550:	0001f517          	auipc	a0,0x1f
    80004554:	d7850513          	add	a0,a0,-648 # 800232c8 <itable>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	72e080e7          	jalr	1838(ra) # 80000c86 <release>
}
    80004560:	60e2                	ld	ra,24(sp)
    80004562:	6442                	ld	s0,16(sp)
    80004564:	64a2                	ld	s1,8(sp)
    80004566:	6902                	ld	s2,0(sp)
    80004568:	6105                	add	sp,sp,32
    8000456a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000456c:	40bc                	lw	a5,64(s1)
    8000456e:	dff1                	beqz	a5,8000454a <iput+0x26>
    80004570:	04a49783          	lh	a5,74(s1)
    80004574:	fbf9                	bnez	a5,8000454a <iput+0x26>
    acquiresleep(&ip->lock);
    80004576:	01048913          	add	s2,s1,16
    8000457a:	854a                	mv	a0,s2
    8000457c:	00001097          	auipc	ra,0x1
    80004580:	a84080e7          	jalr	-1404(ra) # 80005000 <acquiresleep>
    release(&itable.lock);
    80004584:	0001f517          	auipc	a0,0x1f
    80004588:	d4450513          	add	a0,a0,-700 # 800232c8 <itable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	6fa080e7          	jalr	1786(ra) # 80000c86 <release>
    itrunc(ip);
    80004594:	8526                	mv	a0,s1
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	ee2080e7          	jalr	-286(ra) # 80004478 <itrunc>
    ip->type = 0;
    8000459e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800045a2:	8526                	mv	a0,s1
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	cfa080e7          	jalr	-774(ra) # 8000429e <iupdate>
    ip->valid = 0;
    800045ac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800045b0:	854a                	mv	a0,s2
    800045b2:	00001097          	auipc	ra,0x1
    800045b6:	aa4080e7          	jalr	-1372(ra) # 80005056 <releasesleep>
    acquire(&itable.lock);
    800045ba:	0001f517          	auipc	a0,0x1f
    800045be:	d0e50513          	add	a0,a0,-754 # 800232c8 <itable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	610080e7          	jalr	1552(ra) # 80000bd2 <acquire>
    800045ca:	b741                	j	8000454a <iput+0x26>

00000000800045cc <iunlockput>:
{
    800045cc:	1101                	add	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	1000                	add	s0,sp,32
    800045d6:	84aa                	mv	s1,a0
  iunlock(ip);
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	e54080e7          	jalr	-428(ra) # 8000442c <iunlock>
  iput(ip);
    800045e0:	8526                	mv	a0,s1
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	f42080e7          	jalr	-190(ra) # 80004524 <iput>
}
    800045ea:	60e2                	ld	ra,24(sp)
    800045ec:	6442                	ld	s0,16(sp)
    800045ee:	64a2                	ld	s1,8(sp)
    800045f0:	6105                	add	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045f4:	1141                	add	sp,sp,-16
    800045f6:	e422                	sd	s0,8(sp)
    800045f8:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800045fa:	411c                	lw	a5,0(a0)
    800045fc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045fe:	415c                	lw	a5,4(a0)
    80004600:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004602:	04451783          	lh	a5,68(a0)
    80004606:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000460a:	04a51783          	lh	a5,74(a0)
    8000460e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004612:	04c56783          	lwu	a5,76(a0)
    80004616:	e99c                	sd	a5,16(a1)
}
    80004618:	6422                	ld	s0,8(sp)
    8000461a:	0141                	add	sp,sp,16
    8000461c:	8082                	ret

000000008000461e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000461e:	457c                	lw	a5,76(a0)
    80004620:	0ed7e963          	bltu	a5,a3,80004712 <readi+0xf4>
{
    80004624:	7159                	add	sp,sp,-112
    80004626:	f486                	sd	ra,104(sp)
    80004628:	f0a2                	sd	s0,96(sp)
    8000462a:	eca6                	sd	s1,88(sp)
    8000462c:	e8ca                	sd	s2,80(sp)
    8000462e:	e4ce                	sd	s3,72(sp)
    80004630:	e0d2                	sd	s4,64(sp)
    80004632:	fc56                	sd	s5,56(sp)
    80004634:	f85a                	sd	s6,48(sp)
    80004636:	f45e                	sd	s7,40(sp)
    80004638:	f062                	sd	s8,32(sp)
    8000463a:	ec66                	sd	s9,24(sp)
    8000463c:	e86a                	sd	s10,16(sp)
    8000463e:	e46e                	sd	s11,8(sp)
    80004640:	1880                	add	s0,sp,112
    80004642:	8b2a                	mv	s6,a0
    80004644:	8bae                	mv	s7,a1
    80004646:	8a32                	mv	s4,a2
    80004648:	84b6                	mv	s1,a3
    8000464a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000464c:	9f35                	addw	a4,a4,a3
    return 0;
    8000464e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004650:	0ad76063          	bltu	a4,a3,800046f0 <readi+0xd2>
  if(off + n > ip->size)
    80004654:	00e7f463          	bgeu	a5,a4,8000465c <readi+0x3e>
    n = ip->size - off;
    80004658:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000465c:	0a0a8963          	beqz	s5,8000470e <readi+0xf0>
    80004660:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004662:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004666:	5c7d                	li	s8,-1
    80004668:	a82d                	j	800046a2 <readi+0x84>
    8000466a:	020d1d93          	sll	s11,s10,0x20
    8000466e:	020ddd93          	srl	s11,s11,0x20
    80004672:	05890613          	add	a2,s2,88
    80004676:	86ee                	mv	a3,s11
    80004678:	963a                	add	a2,a2,a4
    8000467a:	85d2                	mv	a1,s4
    8000467c:	855e                	mv	a0,s7
    8000467e:	ffffe097          	auipc	ra,0xffffe
    80004682:	430080e7          	jalr	1072(ra) # 80002aae <either_copyout>
    80004686:	05850d63          	beq	a0,s8,800046e0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000468a:	854a                	mv	a0,s2
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	5fe080e7          	jalr	1534(ra) # 80003c8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004694:	013d09bb          	addw	s3,s10,s3
    80004698:	009d04bb          	addw	s1,s10,s1
    8000469c:	9a6e                	add	s4,s4,s11
    8000469e:	0559f763          	bgeu	s3,s5,800046ec <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800046a2:	00a4d59b          	srlw	a1,s1,0xa
    800046a6:	855a                	mv	a0,s6
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	8a4080e7          	jalr	-1884(ra) # 80003f4c <bmap>
    800046b0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800046b4:	cd85                	beqz	a1,800046ec <readi+0xce>
    bp = bread(ip->dev, addr);
    800046b6:	000b2503          	lw	a0,0(s6)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	4a0080e7          	jalr	1184(ra) # 80003b5a <bread>
    800046c2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046c4:	3ff4f713          	and	a4,s1,1023
    800046c8:	40ec87bb          	subw	a5,s9,a4
    800046cc:	413a86bb          	subw	a3,s5,s3
    800046d0:	8d3e                	mv	s10,a5
    800046d2:	2781                	sext.w	a5,a5
    800046d4:	0006861b          	sext.w	a2,a3
    800046d8:	f8f679e3          	bgeu	a2,a5,8000466a <readi+0x4c>
    800046dc:	8d36                	mv	s10,a3
    800046de:	b771                	j	8000466a <readi+0x4c>
      brelse(bp);
    800046e0:	854a                	mv	a0,s2
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	5a8080e7          	jalr	1448(ra) # 80003c8a <brelse>
      tot = -1;
    800046ea:	59fd                	li	s3,-1
  }
  return tot;
    800046ec:	0009851b          	sext.w	a0,s3
}
    800046f0:	70a6                	ld	ra,104(sp)
    800046f2:	7406                	ld	s0,96(sp)
    800046f4:	64e6                	ld	s1,88(sp)
    800046f6:	6946                	ld	s2,80(sp)
    800046f8:	69a6                	ld	s3,72(sp)
    800046fa:	6a06                	ld	s4,64(sp)
    800046fc:	7ae2                	ld	s5,56(sp)
    800046fe:	7b42                	ld	s6,48(sp)
    80004700:	7ba2                	ld	s7,40(sp)
    80004702:	7c02                	ld	s8,32(sp)
    80004704:	6ce2                	ld	s9,24(sp)
    80004706:	6d42                	ld	s10,16(sp)
    80004708:	6da2                	ld	s11,8(sp)
    8000470a:	6165                	add	sp,sp,112
    8000470c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000470e:	89d6                	mv	s3,s5
    80004710:	bff1                	j	800046ec <readi+0xce>
    return 0;
    80004712:	4501                	li	a0,0
}
    80004714:	8082                	ret

0000000080004716 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004716:	457c                	lw	a5,76(a0)
    80004718:	10d7e863          	bltu	a5,a3,80004828 <writei+0x112>
{
    8000471c:	7159                	add	sp,sp,-112
    8000471e:	f486                	sd	ra,104(sp)
    80004720:	f0a2                	sd	s0,96(sp)
    80004722:	eca6                	sd	s1,88(sp)
    80004724:	e8ca                	sd	s2,80(sp)
    80004726:	e4ce                	sd	s3,72(sp)
    80004728:	e0d2                	sd	s4,64(sp)
    8000472a:	fc56                	sd	s5,56(sp)
    8000472c:	f85a                	sd	s6,48(sp)
    8000472e:	f45e                	sd	s7,40(sp)
    80004730:	f062                	sd	s8,32(sp)
    80004732:	ec66                	sd	s9,24(sp)
    80004734:	e86a                	sd	s10,16(sp)
    80004736:	e46e                	sd	s11,8(sp)
    80004738:	1880                	add	s0,sp,112
    8000473a:	8aaa                	mv	s5,a0
    8000473c:	8bae                	mv	s7,a1
    8000473e:	8a32                	mv	s4,a2
    80004740:	8936                	mv	s2,a3
    80004742:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004744:	00e687bb          	addw	a5,a3,a4
    80004748:	0ed7e263          	bltu	a5,a3,8000482c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000474c:	00043737          	lui	a4,0x43
    80004750:	0ef76063          	bltu	a4,a5,80004830 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004754:	0c0b0863          	beqz	s6,80004824 <writei+0x10e>
    80004758:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000475a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000475e:	5c7d                	li	s8,-1
    80004760:	a091                	j	800047a4 <writei+0x8e>
    80004762:	020d1d93          	sll	s11,s10,0x20
    80004766:	020ddd93          	srl	s11,s11,0x20
    8000476a:	05848513          	add	a0,s1,88
    8000476e:	86ee                	mv	a3,s11
    80004770:	8652                	mv	a2,s4
    80004772:	85de                	mv	a1,s7
    80004774:	953a                	add	a0,a0,a4
    80004776:	ffffe097          	auipc	ra,0xffffe
    8000477a:	38e080e7          	jalr	910(ra) # 80002b04 <either_copyin>
    8000477e:	07850263          	beq	a0,s8,800047e2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004782:	8526                	mv	a0,s1
    80004784:	00000097          	auipc	ra,0x0
    80004788:	75e080e7          	jalr	1886(ra) # 80004ee2 <log_write>
    brelse(bp);
    8000478c:	8526                	mv	a0,s1
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	4fc080e7          	jalr	1276(ra) # 80003c8a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004796:	013d09bb          	addw	s3,s10,s3
    8000479a:	012d093b          	addw	s2,s10,s2
    8000479e:	9a6e                	add	s4,s4,s11
    800047a0:	0569f663          	bgeu	s3,s6,800047ec <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800047a4:	00a9559b          	srlw	a1,s2,0xa
    800047a8:	8556                	mv	a0,s5
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	7a2080e7          	jalr	1954(ra) # 80003f4c <bmap>
    800047b2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800047b6:	c99d                	beqz	a1,800047ec <writei+0xd6>
    bp = bread(ip->dev, addr);
    800047b8:	000aa503          	lw	a0,0(s5)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	39e080e7          	jalr	926(ra) # 80003b5a <bread>
    800047c4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800047c6:	3ff97713          	and	a4,s2,1023
    800047ca:	40ec87bb          	subw	a5,s9,a4
    800047ce:	413b06bb          	subw	a3,s6,s3
    800047d2:	8d3e                	mv	s10,a5
    800047d4:	2781                	sext.w	a5,a5
    800047d6:	0006861b          	sext.w	a2,a3
    800047da:	f8f674e3          	bgeu	a2,a5,80004762 <writei+0x4c>
    800047de:	8d36                	mv	s10,a3
    800047e0:	b749                	j	80004762 <writei+0x4c>
      brelse(bp);
    800047e2:	8526                	mv	a0,s1
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	4a6080e7          	jalr	1190(ra) # 80003c8a <brelse>
  }

  if(off > ip->size)
    800047ec:	04caa783          	lw	a5,76(s5)
    800047f0:	0127f463          	bgeu	a5,s2,800047f8 <writei+0xe2>
    ip->size = off;
    800047f4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047f8:	8556                	mv	a0,s5
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	aa4080e7          	jalr	-1372(ra) # 8000429e <iupdate>

  return tot;
    80004802:	0009851b          	sext.w	a0,s3
}
    80004806:	70a6                	ld	ra,104(sp)
    80004808:	7406                	ld	s0,96(sp)
    8000480a:	64e6                	ld	s1,88(sp)
    8000480c:	6946                	ld	s2,80(sp)
    8000480e:	69a6                	ld	s3,72(sp)
    80004810:	6a06                	ld	s4,64(sp)
    80004812:	7ae2                	ld	s5,56(sp)
    80004814:	7b42                	ld	s6,48(sp)
    80004816:	7ba2                	ld	s7,40(sp)
    80004818:	7c02                	ld	s8,32(sp)
    8000481a:	6ce2                	ld	s9,24(sp)
    8000481c:	6d42                	ld	s10,16(sp)
    8000481e:	6da2                	ld	s11,8(sp)
    80004820:	6165                	add	sp,sp,112
    80004822:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004824:	89da                	mv	s3,s6
    80004826:	bfc9                	j	800047f8 <writei+0xe2>
    return -1;
    80004828:	557d                	li	a0,-1
}
    8000482a:	8082                	ret
    return -1;
    8000482c:	557d                	li	a0,-1
    8000482e:	bfe1                	j	80004806 <writei+0xf0>
    return -1;
    80004830:	557d                	li	a0,-1
    80004832:	bfd1                	j	80004806 <writei+0xf0>

0000000080004834 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004834:	1141                	add	sp,sp,-16
    80004836:	e406                	sd	ra,8(sp)
    80004838:	e022                	sd	s0,0(sp)
    8000483a:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000483c:	4639                	li	a2,14
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	560080e7          	jalr	1376(ra) # 80000d9e <strncmp>
}
    80004846:	60a2                	ld	ra,8(sp)
    80004848:	6402                	ld	s0,0(sp)
    8000484a:	0141                	add	sp,sp,16
    8000484c:	8082                	ret

000000008000484e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000484e:	7139                	add	sp,sp,-64
    80004850:	fc06                	sd	ra,56(sp)
    80004852:	f822                	sd	s0,48(sp)
    80004854:	f426                	sd	s1,40(sp)
    80004856:	f04a                	sd	s2,32(sp)
    80004858:	ec4e                	sd	s3,24(sp)
    8000485a:	e852                	sd	s4,16(sp)
    8000485c:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000485e:	04451703          	lh	a4,68(a0)
    80004862:	4785                	li	a5,1
    80004864:	00f71a63          	bne	a4,a5,80004878 <dirlookup+0x2a>
    80004868:	892a                	mv	s2,a0
    8000486a:	89ae                	mv	s3,a1
    8000486c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000486e:	457c                	lw	a5,76(a0)
    80004870:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004872:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004874:	e79d                	bnez	a5,800048a2 <dirlookup+0x54>
    80004876:	a8a5                	j	800048ee <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	e1050513          	add	a0,a0,-496 # 80008688 <syscalls+0x1e8>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cbc080e7          	jalr	-836(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004888:	00004517          	auipc	a0,0x4
    8000488c:	e1850513          	add	a0,a0,-488 # 800086a0 <syscalls+0x200>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	cac080e7          	jalr	-852(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004898:	24c1                	addw	s1,s1,16
    8000489a:	04c92783          	lw	a5,76(s2)
    8000489e:	04f4f763          	bgeu	s1,a5,800048ec <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048a2:	4741                	li	a4,16
    800048a4:	86a6                	mv	a3,s1
    800048a6:	fc040613          	add	a2,s0,-64
    800048aa:	4581                	li	a1,0
    800048ac:	854a                	mv	a0,s2
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	d70080e7          	jalr	-656(ra) # 8000461e <readi>
    800048b6:	47c1                	li	a5,16
    800048b8:	fcf518e3          	bne	a0,a5,80004888 <dirlookup+0x3a>
    if(de.inum == 0)
    800048bc:	fc045783          	lhu	a5,-64(s0)
    800048c0:	dfe1                	beqz	a5,80004898 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800048c2:	fc240593          	add	a1,s0,-62
    800048c6:	854e                	mv	a0,s3
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	f6c080e7          	jalr	-148(ra) # 80004834 <namecmp>
    800048d0:	f561                	bnez	a0,80004898 <dirlookup+0x4a>
      if(poff)
    800048d2:	000a0463          	beqz	s4,800048da <dirlookup+0x8c>
        *poff = off;
    800048d6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800048da:	fc045583          	lhu	a1,-64(s0)
    800048de:	00092503          	lw	a0,0(s2)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	754080e7          	jalr	1876(ra) # 80004036 <iget>
    800048ea:	a011                	j	800048ee <dirlookup+0xa0>
  return 0;
    800048ec:	4501                	li	a0,0
}
    800048ee:	70e2                	ld	ra,56(sp)
    800048f0:	7442                	ld	s0,48(sp)
    800048f2:	74a2                	ld	s1,40(sp)
    800048f4:	7902                	ld	s2,32(sp)
    800048f6:	69e2                	ld	s3,24(sp)
    800048f8:	6a42                	ld	s4,16(sp)
    800048fa:	6121                	add	sp,sp,64
    800048fc:	8082                	ret

00000000800048fe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048fe:	711d                	add	sp,sp,-96
    80004900:	ec86                	sd	ra,88(sp)
    80004902:	e8a2                	sd	s0,80(sp)
    80004904:	e4a6                	sd	s1,72(sp)
    80004906:	e0ca                	sd	s2,64(sp)
    80004908:	fc4e                	sd	s3,56(sp)
    8000490a:	f852                	sd	s4,48(sp)
    8000490c:	f456                	sd	s5,40(sp)
    8000490e:	f05a                	sd	s6,32(sp)
    80004910:	ec5e                	sd	s7,24(sp)
    80004912:	e862                	sd	s8,16(sp)
    80004914:	e466                	sd	s9,8(sp)
    80004916:	1080                	add	s0,sp,96
    80004918:	84aa                	mv	s1,a0
    8000491a:	8b2e                	mv	s6,a1
    8000491c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000491e:	00054703          	lbu	a4,0(a0)
    80004922:	02f00793          	li	a5,47
    80004926:	02f70263          	beq	a4,a5,8000494a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000492a:	ffffd097          	auipc	ra,0xffffd
    8000492e:	07c080e7          	jalr	124(ra) # 800019a6 <myproc>
    80004932:	15053503          	ld	a0,336(a0)
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	9f6080e7          	jalr	-1546(ra) # 8000432c <idup>
    8000493e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004940:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004944:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004946:	4b85                	li	s7,1
    80004948:	a875                	j	80004a04 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000494a:	4585                	li	a1,1
    8000494c:	4505                	li	a0,1
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	6e8080e7          	jalr	1768(ra) # 80004036 <iget>
    80004956:	8a2a                	mv	s4,a0
    80004958:	b7e5                	j	80004940 <namex+0x42>
      iunlockput(ip);
    8000495a:	8552                	mv	a0,s4
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	c70080e7          	jalr	-912(ra) # 800045cc <iunlockput>
      return 0;
    80004964:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004966:	8552                	mv	a0,s4
    80004968:	60e6                	ld	ra,88(sp)
    8000496a:	6446                	ld	s0,80(sp)
    8000496c:	64a6                	ld	s1,72(sp)
    8000496e:	6906                	ld	s2,64(sp)
    80004970:	79e2                	ld	s3,56(sp)
    80004972:	7a42                	ld	s4,48(sp)
    80004974:	7aa2                	ld	s5,40(sp)
    80004976:	7b02                	ld	s6,32(sp)
    80004978:	6be2                	ld	s7,24(sp)
    8000497a:	6c42                	ld	s8,16(sp)
    8000497c:	6ca2                	ld	s9,8(sp)
    8000497e:	6125                	add	sp,sp,96
    80004980:	8082                	ret
      iunlock(ip);
    80004982:	8552                	mv	a0,s4
    80004984:	00000097          	auipc	ra,0x0
    80004988:	aa8080e7          	jalr	-1368(ra) # 8000442c <iunlock>
      return ip;
    8000498c:	bfe9                	j	80004966 <namex+0x68>
      iunlockput(ip);
    8000498e:	8552                	mv	a0,s4
    80004990:	00000097          	auipc	ra,0x0
    80004994:	c3c080e7          	jalr	-964(ra) # 800045cc <iunlockput>
      return 0;
    80004998:	8a4e                	mv	s4,s3
    8000499a:	b7f1                	j	80004966 <namex+0x68>
  len = path - s;
    8000499c:	40998633          	sub	a2,s3,s1
    800049a0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800049a4:	099c5863          	bge	s8,s9,80004a34 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800049a8:	4639                	li	a2,14
    800049aa:	85a6                	mv	a1,s1
    800049ac:	8556                	mv	a0,s5
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	37c080e7          	jalr	892(ra) # 80000d2a <memmove>
    800049b6:	84ce                	mv	s1,s3
  while(*path == '/')
    800049b8:	0004c783          	lbu	a5,0(s1)
    800049bc:	01279763          	bne	a5,s2,800049ca <namex+0xcc>
    path++;
    800049c0:	0485                	add	s1,s1,1
  while(*path == '/')
    800049c2:	0004c783          	lbu	a5,0(s1)
    800049c6:	ff278de3          	beq	a5,s2,800049c0 <namex+0xc2>
    ilock(ip);
    800049ca:	8552                	mv	a0,s4
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	99e080e7          	jalr	-1634(ra) # 8000436a <ilock>
    if(ip->type != T_DIR){
    800049d4:	044a1783          	lh	a5,68(s4)
    800049d8:	f97791e3          	bne	a5,s7,8000495a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800049dc:	000b0563          	beqz	s6,800049e6 <namex+0xe8>
    800049e0:	0004c783          	lbu	a5,0(s1)
    800049e4:	dfd9                	beqz	a5,80004982 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049e6:	4601                	li	a2,0
    800049e8:	85d6                	mv	a1,s5
    800049ea:	8552                	mv	a0,s4
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	e62080e7          	jalr	-414(ra) # 8000484e <dirlookup>
    800049f4:	89aa                	mv	s3,a0
    800049f6:	dd41                	beqz	a0,8000498e <namex+0x90>
    iunlockput(ip);
    800049f8:	8552                	mv	a0,s4
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	bd2080e7          	jalr	-1070(ra) # 800045cc <iunlockput>
    ip = next;
    80004a02:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004a04:	0004c783          	lbu	a5,0(s1)
    80004a08:	01279763          	bne	a5,s2,80004a16 <namex+0x118>
    path++;
    80004a0c:	0485                	add	s1,s1,1
  while(*path == '/')
    80004a0e:	0004c783          	lbu	a5,0(s1)
    80004a12:	ff278de3          	beq	a5,s2,80004a0c <namex+0x10e>
  if(*path == 0)
    80004a16:	cb9d                	beqz	a5,80004a4c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004a18:	0004c783          	lbu	a5,0(s1)
    80004a1c:	89a6                	mv	s3,s1
  len = path - s;
    80004a1e:	4c81                	li	s9,0
    80004a20:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004a22:	01278963          	beq	a5,s2,80004a34 <namex+0x136>
    80004a26:	dbbd                	beqz	a5,8000499c <namex+0x9e>
    path++;
    80004a28:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004a2a:	0009c783          	lbu	a5,0(s3)
    80004a2e:	ff279ce3          	bne	a5,s2,80004a26 <namex+0x128>
    80004a32:	b7ad                	j	8000499c <namex+0x9e>
    memmove(name, s, len);
    80004a34:	2601                	sext.w	a2,a2
    80004a36:	85a6                	mv	a1,s1
    80004a38:	8556                	mv	a0,s5
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	2f0080e7          	jalr	752(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004a42:	9cd6                	add	s9,s9,s5
    80004a44:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004a48:	84ce                	mv	s1,s3
    80004a4a:	b7bd                	j	800049b8 <namex+0xba>
  if(nameiparent){
    80004a4c:	f00b0de3          	beqz	s6,80004966 <namex+0x68>
    iput(ip);
    80004a50:	8552                	mv	a0,s4
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	ad2080e7          	jalr	-1326(ra) # 80004524 <iput>
    return 0;
    80004a5a:	4a01                	li	s4,0
    80004a5c:	b729                	j	80004966 <namex+0x68>

0000000080004a5e <dirlink>:
{
    80004a5e:	7139                	add	sp,sp,-64
    80004a60:	fc06                	sd	ra,56(sp)
    80004a62:	f822                	sd	s0,48(sp)
    80004a64:	f426                	sd	s1,40(sp)
    80004a66:	f04a                	sd	s2,32(sp)
    80004a68:	ec4e                	sd	s3,24(sp)
    80004a6a:	e852                	sd	s4,16(sp)
    80004a6c:	0080                	add	s0,sp,64
    80004a6e:	892a                	mv	s2,a0
    80004a70:	8a2e                	mv	s4,a1
    80004a72:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a74:	4601                	li	a2,0
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	dd8080e7          	jalr	-552(ra) # 8000484e <dirlookup>
    80004a7e:	e93d                	bnez	a0,80004af4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a80:	04c92483          	lw	s1,76(s2)
    80004a84:	c49d                	beqz	s1,80004ab2 <dirlink+0x54>
    80004a86:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a88:	4741                	li	a4,16
    80004a8a:	86a6                	mv	a3,s1
    80004a8c:	fc040613          	add	a2,s0,-64
    80004a90:	4581                	li	a1,0
    80004a92:	854a                	mv	a0,s2
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	b8a080e7          	jalr	-1142(ra) # 8000461e <readi>
    80004a9c:	47c1                	li	a5,16
    80004a9e:	06f51163          	bne	a0,a5,80004b00 <dirlink+0xa2>
    if(de.inum == 0)
    80004aa2:	fc045783          	lhu	a5,-64(s0)
    80004aa6:	c791                	beqz	a5,80004ab2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004aa8:	24c1                	addw	s1,s1,16
    80004aaa:	04c92783          	lw	a5,76(s2)
    80004aae:	fcf4ede3          	bltu	s1,a5,80004a88 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004ab2:	4639                	li	a2,14
    80004ab4:	85d2                	mv	a1,s4
    80004ab6:	fc240513          	add	a0,s0,-62
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	320080e7          	jalr	800(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004ac2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ac6:	4741                	li	a4,16
    80004ac8:	86a6                	mv	a3,s1
    80004aca:	fc040613          	add	a2,s0,-64
    80004ace:	4581                	li	a1,0
    80004ad0:	854a                	mv	a0,s2
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	c44080e7          	jalr	-956(ra) # 80004716 <writei>
    80004ada:	1541                	add	a0,a0,-16
    80004adc:	00a03533          	snez	a0,a0
    80004ae0:	40a00533          	neg	a0,a0
}
    80004ae4:	70e2                	ld	ra,56(sp)
    80004ae6:	7442                	ld	s0,48(sp)
    80004ae8:	74a2                	ld	s1,40(sp)
    80004aea:	7902                	ld	s2,32(sp)
    80004aec:	69e2                	ld	s3,24(sp)
    80004aee:	6a42                	ld	s4,16(sp)
    80004af0:	6121                	add	sp,sp,64
    80004af2:	8082                	ret
    iput(ip);
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	a30080e7          	jalr	-1488(ra) # 80004524 <iput>
    return -1;
    80004afc:	557d                	li	a0,-1
    80004afe:	b7dd                	j	80004ae4 <dirlink+0x86>
      panic("dirlink read");
    80004b00:	00004517          	auipc	a0,0x4
    80004b04:	bb050513          	add	a0,a0,-1104 # 800086b0 <syscalls+0x210>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	a34080e7          	jalr	-1484(ra) # 8000053c <panic>

0000000080004b10 <namei>:

struct inode*
namei(char *path)
{
    80004b10:	1101                	add	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b18:	fe040613          	add	a2,s0,-32
    80004b1c:	4581                	li	a1,0
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	de0080e7          	jalr	-544(ra) # 800048fe <namex>
}
    80004b26:	60e2                	ld	ra,24(sp)
    80004b28:	6442                	ld	s0,16(sp)
    80004b2a:	6105                	add	sp,sp,32
    80004b2c:	8082                	ret

0000000080004b2e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b2e:	1141                	add	sp,sp,-16
    80004b30:	e406                	sd	ra,8(sp)
    80004b32:	e022                	sd	s0,0(sp)
    80004b34:	0800                	add	s0,sp,16
    80004b36:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b38:	4585                	li	a1,1
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	dc4080e7          	jalr	-572(ra) # 800048fe <namex>
}
    80004b42:	60a2                	ld	ra,8(sp)
    80004b44:	6402                	ld	s0,0(sp)
    80004b46:	0141                	add	sp,sp,16
    80004b48:	8082                	ret

0000000080004b4a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b4a:	1101                	add	sp,sp,-32
    80004b4c:	ec06                	sd	ra,24(sp)
    80004b4e:	e822                	sd	s0,16(sp)
    80004b50:	e426                	sd	s1,8(sp)
    80004b52:	e04a                	sd	s2,0(sp)
    80004b54:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b56:	00020917          	auipc	s2,0x20
    80004b5a:	21a90913          	add	s2,s2,538 # 80024d70 <log>
    80004b5e:	01892583          	lw	a1,24(s2)
    80004b62:	02892503          	lw	a0,40(s2)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	ff4080e7          	jalr	-12(ra) # 80003b5a <bread>
    80004b6e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b70:	02c92603          	lw	a2,44(s2)
    80004b74:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b76:	00c05f63          	blez	a2,80004b94 <write_head+0x4a>
    80004b7a:	00020717          	auipc	a4,0x20
    80004b7e:	22670713          	add	a4,a4,550 # 80024da0 <log+0x30>
    80004b82:	87aa                	mv	a5,a0
    80004b84:	060a                	sll	a2,a2,0x2
    80004b86:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004b88:	4314                	lw	a3,0(a4)
    80004b8a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004b8c:	0711                	add	a4,a4,4
    80004b8e:	0791                	add	a5,a5,4
    80004b90:	fec79ce3          	bne	a5,a2,80004b88 <write_head+0x3e>
  }
  bwrite(buf);
    80004b94:	8526                	mv	a0,s1
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	0b6080e7          	jalr	182(ra) # 80003c4c <bwrite>
  brelse(buf);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	0ea080e7          	jalr	234(ra) # 80003c8a <brelse>
}
    80004ba8:	60e2                	ld	ra,24(sp)
    80004baa:	6442                	ld	s0,16(sp)
    80004bac:	64a2                	ld	s1,8(sp)
    80004bae:	6902                	ld	s2,0(sp)
    80004bb0:	6105                	add	sp,sp,32
    80004bb2:	8082                	ret

0000000080004bb4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bb4:	00020797          	auipc	a5,0x20
    80004bb8:	1e87a783          	lw	a5,488(a5) # 80024d9c <log+0x2c>
    80004bbc:	0af05d63          	blez	a5,80004c76 <install_trans+0xc2>
{
    80004bc0:	7139                	add	sp,sp,-64
    80004bc2:	fc06                	sd	ra,56(sp)
    80004bc4:	f822                	sd	s0,48(sp)
    80004bc6:	f426                	sd	s1,40(sp)
    80004bc8:	f04a                	sd	s2,32(sp)
    80004bca:	ec4e                	sd	s3,24(sp)
    80004bcc:	e852                	sd	s4,16(sp)
    80004bce:	e456                	sd	s5,8(sp)
    80004bd0:	e05a                	sd	s6,0(sp)
    80004bd2:	0080                	add	s0,sp,64
    80004bd4:	8b2a                	mv	s6,a0
    80004bd6:	00020a97          	auipc	s5,0x20
    80004bda:	1caa8a93          	add	s5,s5,458 # 80024da0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bde:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004be0:	00020997          	auipc	s3,0x20
    80004be4:	19098993          	add	s3,s3,400 # 80024d70 <log>
    80004be8:	a00d                	j	80004c0a <install_trans+0x56>
    brelse(lbuf);
    80004bea:	854a                	mv	a0,s2
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	09e080e7          	jalr	158(ra) # 80003c8a <brelse>
    brelse(dbuf);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	fffff097          	auipc	ra,0xfffff
    80004bfa:	094080e7          	jalr	148(ra) # 80003c8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bfe:	2a05                	addw	s4,s4,1
    80004c00:	0a91                	add	s5,s5,4
    80004c02:	02c9a783          	lw	a5,44(s3)
    80004c06:	04fa5e63          	bge	s4,a5,80004c62 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c0a:	0189a583          	lw	a1,24(s3)
    80004c0e:	014585bb          	addw	a1,a1,s4
    80004c12:	2585                	addw	a1,a1,1
    80004c14:	0289a503          	lw	a0,40(s3)
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	f42080e7          	jalr	-190(ra) # 80003b5a <bread>
    80004c20:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c22:	000aa583          	lw	a1,0(s5)
    80004c26:	0289a503          	lw	a0,40(s3)
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	f30080e7          	jalr	-208(ra) # 80003b5a <bread>
    80004c32:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c34:	40000613          	li	a2,1024
    80004c38:	05890593          	add	a1,s2,88
    80004c3c:	05850513          	add	a0,a0,88
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	0ea080e7          	jalr	234(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c48:	8526                	mv	a0,s1
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	002080e7          	jalr	2(ra) # 80003c4c <bwrite>
    if(recovering == 0)
    80004c52:	f80b1ce3          	bnez	s6,80004bea <install_trans+0x36>
      bunpin(dbuf);
    80004c56:	8526                	mv	a0,s1
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	10a080e7          	jalr	266(ra) # 80003d62 <bunpin>
    80004c60:	b769                	j	80004bea <install_trans+0x36>
}
    80004c62:	70e2                	ld	ra,56(sp)
    80004c64:	7442                	ld	s0,48(sp)
    80004c66:	74a2                	ld	s1,40(sp)
    80004c68:	7902                	ld	s2,32(sp)
    80004c6a:	69e2                	ld	s3,24(sp)
    80004c6c:	6a42                	ld	s4,16(sp)
    80004c6e:	6aa2                	ld	s5,8(sp)
    80004c70:	6b02                	ld	s6,0(sp)
    80004c72:	6121                	add	sp,sp,64
    80004c74:	8082                	ret
    80004c76:	8082                	ret

0000000080004c78 <initlog>:
{
    80004c78:	7179                	add	sp,sp,-48
    80004c7a:	f406                	sd	ra,40(sp)
    80004c7c:	f022                	sd	s0,32(sp)
    80004c7e:	ec26                	sd	s1,24(sp)
    80004c80:	e84a                	sd	s2,16(sp)
    80004c82:	e44e                	sd	s3,8(sp)
    80004c84:	1800                	add	s0,sp,48
    80004c86:	892a                	mv	s2,a0
    80004c88:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c8a:	00020497          	auipc	s1,0x20
    80004c8e:	0e648493          	add	s1,s1,230 # 80024d70 <log>
    80004c92:	00004597          	auipc	a1,0x4
    80004c96:	a2e58593          	add	a1,a1,-1490 # 800086c0 <syscalls+0x220>
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	ea6080e7          	jalr	-346(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004ca4:	0149a583          	lw	a1,20(s3)
    80004ca8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004caa:	0109a783          	lw	a5,16(s3)
    80004cae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004cb0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004cb4:	854a                	mv	a0,s2
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	ea4080e7          	jalr	-348(ra) # 80003b5a <bread>
  log.lh.n = lh->n;
    80004cbe:	4d30                	lw	a2,88(a0)
    80004cc0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004cc2:	00c05f63          	blez	a2,80004ce0 <initlog+0x68>
    80004cc6:	87aa                	mv	a5,a0
    80004cc8:	00020717          	auipc	a4,0x20
    80004ccc:	0d870713          	add	a4,a4,216 # 80024da0 <log+0x30>
    80004cd0:	060a                	sll	a2,a2,0x2
    80004cd2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004cd4:	4ff4                	lw	a3,92(a5)
    80004cd6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004cd8:	0791                	add	a5,a5,4
    80004cda:	0711                	add	a4,a4,4
    80004cdc:	fec79ce3          	bne	a5,a2,80004cd4 <initlog+0x5c>
  brelse(buf);
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	faa080e7          	jalr	-86(ra) # 80003c8a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004ce8:	4505                	li	a0,1
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	eca080e7          	jalr	-310(ra) # 80004bb4 <install_trans>
  log.lh.n = 0;
    80004cf2:	00020797          	auipc	a5,0x20
    80004cf6:	0a07a523          	sw	zero,170(a5) # 80024d9c <log+0x2c>
  write_head(); // clear the log
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	e50080e7          	jalr	-432(ra) # 80004b4a <write_head>
}
    80004d02:	70a2                	ld	ra,40(sp)
    80004d04:	7402                	ld	s0,32(sp)
    80004d06:	64e2                	ld	s1,24(sp)
    80004d08:	6942                	ld	s2,16(sp)
    80004d0a:	69a2                	ld	s3,8(sp)
    80004d0c:	6145                	add	sp,sp,48
    80004d0e:	8082                	ret

0000000080004d10 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d10:	1101                	add	sp,sp,-32
    80004d12:	ec06                	sd	ra,24(sp)
    80004d14:	e822                	sd	s0,16(sp)
    80004d16:	e426                	sd	s1,8(sp)
    80004d18:	e04a                	sd	s2,0(sp)
    80004d1a:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004d1c:	00020517          	auipc	a0,0x20
    80004d20:	05450513          	add	a0,a0,84 # 80024d70 <log>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	eae080e7          	jalr	-338(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004d2c:	00020497          	auipc	s1,0x20
    80004d30:	04448493          	add	s1,s1,68 # 80024d70 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d34:	4979                	li	s2,30
    80004d36:	a039                	j	80004d44 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d38:	85a6                	mv	a1,s1
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffe097          	auipc	ra,0xffffe
    80004d40:	946080e7          	jalr	-1722(ra) # 80002682 <sleep>
    if(log.committing){
    80004d44:	50dc                	lw	a5,36(s1)
    80004d46:	fbed                	bnez	a5,80004d38 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d48:	5098                	lw	a4,32(s1)
    80004d4a:	2705                	addw	a4,a4,1
    80004d4c:	0027179b          	sllw	a5,a4,0x2
    80004d50:	9fb9                	addw	a5,a5,a4
    80004d52:	0017979b          	sllw	a5,a5,0x1
    80004d56:	54d4                	lw	a3,44(s1)
    80004d58:	9fb5                	addw	a5,a5,a3
    80004d5a:	00f95963          	bge	s2,a5,80004d6c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d5e:	85a6                	mv	a1,s1
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffe097          	auipc	ra,0xffffe
    80004d66:	920080e7          	jalr	-1760(ra) # 80002682 <sleep>
    80004d6a:	bfe9                	j	80004d44 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d6c:	00020517          	auipc	a0,0x20
    80004d70:	00450513          	add	a0,a0,4 # 80024d70 <log>
    80004d74:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	f10080e7          	jalr	-240(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004d7e:	60e2                	ld	ra,24(sp)
    80004d80:	6442                	ld	s0,16(sp)
    80004d82:	64a2                	ld	s1,8(sp)
    80004d84:	6902                	ld	s2,0(sp)
    80004d86:	6105                	add	sp,sp,32
    80004d88:	8082                	ret

0000000080004d8a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d8a:	7139                	add	sp,sp,-64
    80004d8c:	fc06                	sd	ra,56(sp)
    80004d8e:	f822                	sd	s0,48(sp)
    80004d90:	f426                	sd	s1,40(sp)
    80004d92:	f04a                	sd	s2,32(sp)
    80004d94:	ec4e                	sd	s3,24(sp)
    80004d96:	e852                	sd	s4,16(sp)
    80004d98:	e456                	sd	s5,8(sp)
    80004d9a:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d9c:	00020497          	auipc	s1,0x20
    80004da0:	fd448493          	add	s1,s1,-44 # 80024d70 <log>
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	e2c080e7          	jalr	-468(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004dae:	509c                	lw	a5,32(s1)
    80004db0:	37fd                	addw	a5,a5,-1
    80004db2:	0007891b          	sext.w	s2,a5
    80004db6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004db8:	50dc                	lw	a5,36(s1)
    80004dba:	e7b9                	bnez	a5,80004e08 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004dbc:	04091e63          	bnez	s2,80004e18 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004dc0:	00020497          	auipc	s1,0x20
    80004dc4:	fb048493          	add	s1,s1,-80 # 80024d70 <log>
    80004dc8:	4785                	li	a5,1
    80004dca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	eb8080e7          	jalr	-328(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004dd6:	54dc                	lw	a5,44(s1)
    80004dd8:	06f04763          	bgtz	a5,80004e46 <end_op+0xbc>
    acquire(&log.lock);
    80004ddc:	00020497          	auipc	s1,0x20
    80004de0:	f9448493          	add	s1,s1,-108 # 80024d70 <log>
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	dec080e7          	jalr	-532(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004dee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004df2:	8526                	mv	a0,s1
    80004df4:	ffffe097          	auipc	ra,0xffffe
    80004df8:	8f2080e7          	jalr	-1806(ra) # 800026e6 <wakeup>
    release(&log.lock);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	e88080e7          	jalr	-376(ra) # 80000c86 <release>
}
    80004e06:	a03d                	j	80004e34 <end_op+0xaa>
    panic("log.committing");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	8c050513          	add	a0,a0,-1856 # 800086c8 <syscalls+0x228>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	72c080e7          	jalr	1836(ra) # 8000053c <panic>
    wakeup(&log);
    80004e18:	00020497          	auipc	s1,0x20
    80004e1c:	f5848493          	add	s1,s1,-168 # 80024d70 <log>
    80004e20:	8526                	mv	a0,s1
    80004e22:	ffffe097          	auipc	ra,0xffffe
    80004e26:	8c4080e7          	jalr	-1852(ra) # 800026e6 <wakeup>
  release(&log.lock);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	e5a080e7          	jalr	-422(ra) # 80000c86 <release>
}
    80004e34:	70e2                	ld	ra,56(sp)
    80004e36:	7442                	ld	s0,48(sp)
    80004e38:	74a2                	ld	s1,40(sp)
    80004e3a:	7902                	ld	s2,32(sp)
    80004e3c:	69e2                	ld	s3,24(sp)
    80004e3e:	6a42                	ld	s4,16(sp)
    80004e40:	6aa2                	ld	s5,8(sp)
    80004e42:	6121                	add	sp,sp,64
    80004e44:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e46:	00020a97          	auipc	s5,0x20
    80004e4a:	f5aa8a93          	add	s5,s5,-166 # 80024da0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e4e:	00020a17          	auipc	s4,0x20
    80004e52:	f22a0a13          	add	s4,s4,-222 # 80024d70 <log>
    80004e56:	018a2583          	lw	a1,24(s4)
    80004e5a:	012585bb          	addw	a1,a1,s2
    80004e5e:	2585                	addw	a1,a1,1
    80004e60:	028a2503          	lw	a0,40(s4)
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	cf6080e7          	jalr	-778(ra) # 80003b5a <bread>
    80004e6c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e6e:	000aa583          	lw	a1,0(s5)
    80004e72:	028a2503          	lw	a0,40(s4)
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	ce4080e7          	jalr	-796(ra) # 80003b5a <bread>
    80004e7e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e80:	40000613          	li	a2,1024
    80004e84:	05850593          	add	a1,a0,88
    80004e88:	05848513          	add	a0,s1,88
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	e9e080e7          	jalr	-354(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004e94:	8526                	mv	a0,s1
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	db6080e7          	jalr	-586(ra) # 80003c4c <bwrite>
    brelse(from);
    80004e9e:	854e                	mv	a0,s3
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	dea080e7          	jalr	-534(ra) # 80003c8a <brelse>
    brelse(to);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	de0080e7          	jalr	-544(ra) # 80003c8a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004eb2:	2905                	addw	s2,s2,1
    80004eb4:	0a91                	add	s5,s5,4
    80004eb6:	02ca2783          	lw	a5,44(s4)
    80004eba:	f8f94ee3          	blt	s2,a5,80004e56 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ebe:	00000097          	auipc	ra,0x0
    80004ec2:	c8c080e7          	jalr	-884(ra) # 80004b4a <write_head>
    install_trans(0); // Now install writes to home locations
    80004ec6:	4501                	li	a0,0
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	cec080e7          	jalr	-788(ra) # 80004bb4 <install_trans>
    log.lh.n = 0;
    80004ed0:	00020797          	auipc	a5,0x20
    80004ed4:	ec07a623          	sw	zero,-308(a5) # 80024d9c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ed8:	00000097          	auipc	ra,0x0
    80004edc:	c72080e7          	jalr	-910(ra) # 80004b4a <write_head>
    80004ee0:	bdf5                	j	80004ddc <end_op+0x52>

0000000080004ee2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ee2:	1101                	add	sp,sp,-32
    80004ee4:	ec06                	sd	ra,24(sp)
    80004ee6:	e822                	sd	s0,16(sp)
    80004ee8:	e426                	sd	s1,8(sp)
    80004eea:	e04a                	sd	s2,0(sp)
    80004eec:	1000                	add	s0,sp,32
    80004eee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ef0:	00020917          	auipc	s2,0x20
    80004ef4:	e8090913          	add	s2,s2,-384 # 80024d70 <log>
    80004ef8:	854a                	mv	a0,s2
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	cd8080e7          	jalr	-808(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f02:	02c92603          	lw	a2,44(s2)
    80004f06:	47f5                	li	a5,29
    80004f08:	06c7c563          	blt	a5,a2,80004f72 <log_write+0x90>
    80004f0c:	00020797          	auipc	a5,0x20
    80004f10:	e807a783          	lw	a5,-384(a5) # 80024d8c <log+0x1c>
    80004f14:	37fd                	addw	a5,a5,-1
    80004f16:	04f65e63          	bge	a2,a5,80004f72 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f1a:	00020797          	auipc	a5,0x20
    80004f1e:	e767a783          	lw	a5,-394(a5) # 80024d90 <log+0x20>
    80004f22:	06f05063          	blez	a5,80004f82 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f26:	4781                	li	a5,0
    80004f28:	06c05563          	blez	a2,80004f92 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f2c:	44cc                	lw	a1,12(s1)
    80004f2e:	00020717          	auipc	a4,0x20
    80004f32:	e7270713          	add	a4,a4,-398 # 80024da0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f36:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f38:	4314                	lw	a3,0(a4)
    80004f3a:	04b68c63          	beq	a3,a1,80004f92 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f3e:	2785                	addw	a5,a5,1
    80004f40:	0711                	add	a4,a4,4
    80004f42:	fef61be3          	bne	a2,a5,80004f38 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f46:	0621                	add	a2,a2,8
    80004f48:	060a                	sll	a2,a2,0x2
    80004f4a:	00020797          	auipc	a5,0x20
    80004f4e:	e2678793          	add	a5,a5,-474 # 80024d70 <log>
    80004f52:	97b2                	add	a5,a5,a2
    80004f54:	44d8                	lw	a4,12(s1)
    80004f56:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	dcc080e7          	jalr	-564(ra) # 80003d26 <bpin>
    log.lh.n++;
    80004f62:	00020717          	auipc	a4,0x20
    80004f66:	e0e70713          	add	a4,a4,-498 # 80024d70 <log>
    80004f6a:	575c                	lw	a5,44(a4)
    80004f6c:	2785                	addw	a5,a5,1
    80004f6e:	d75c                	sw	a5,44(a4)
    80004f70:	a82d                	j	80004faa <log_write+0xc8>
    panic("too big a transaction");
    80004f72:	00003517          	auipc	a0,0x3
    80004f76:	76650513          	add	a0,a0,1894 # 800086d8 <syscalls+0x238>
    80004f7a:	ffffb097          	auipc	ra,0xffffb
    80004f7e:	5c2080e7          	jalr	1474(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004f82:	00003517          	auipc	a0,0x3
    80004f86:	76e50513          	add	a0,a0,1902 # 800086f0 <syscalls+0x250>
    80004f8a:	ffffb097          	auipc	ra,0xffffb
    80004f8e:	5b2080e7          	jalr	1458(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004f92:	00878693          	add	a3,a5,8
    80004f96:	068a                	sll	a3,a3,0x2
    80004f98:	00020717          	auipc	a4,0x20
    80004f9c:	dd870713          	add	a4,a4,-552 # 80024d70 <log>
    80004fa0:	9736                	add	a4,a4,a3
    80004fa2:	44d4                	lw	a3,12(s1)
    80004fa4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004fa6:	faf609e3          	beq	a2,a5,80004f58 <log_write+0x76>
  }
  release(&log.lock);
    80004faa:	00020517          	auipc	a0,0x20
    80004fae:	dc650513          	add	a0,a0,-570 # 80024d70 <log>
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	cd4080e7          	jalr	-812(ra) # 80000c86 <release>
}
    80004fba:	60e2                	ld	ra,24(sp)
    80004fbc:	6442                	ld	s0,16(sp)
    80004fbe:	64a2                	ld	s1,8(sp)
    80004fc0:	6902                	ld	s2,0(sp)
    80004fc2:	6105                	add	sp,sp,32
    80004fc4:	8082                	ret

0000000080004fc6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fc6:	1101                	add	sp,sp,-32
    80004fc8:	ec06                	sd	ra,24(sp)
    80004fca:	e822                	sd	s0,16(sp)
    80004fcc:	e426                	sd	s1,8(sp)
    80004fce:	e04a                	sd	s2,0(sp)
    80004fd0:	1000                	add	s0,sp,32
    80004fd2:	84aa                	mv	s1,a0
    80004fd4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fd6:	00003597          	auipc	a1,0x3
    80004fda:	73a58593          	add	a1,a1,1850 # 80008710 <syscalls+0x270>
    80004fde:	0521                	add	a0,a0,8
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	b62080e7          	jalr	-1182(ra) # 80000b42 <initlock>
  lk->name = name;
    80004fe8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004fec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ff0:	0204a423          	sw	zero,40(s1)
}
    80004ff4:	60e2                	ld	ra,24(sp)
    80004ff6:	6442                	ld	s0,16(sp)
    80004ff8:	64a2                	ld	s1,8(sp)
    80004ffa:	6902                	ld	s2,0(sp)
    80004ffc:	6105                	add	sp,sp,32
    80004ffe:	8082                	ret

0000000080005000 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005000:	1101                	add	sp,sp,-32
    80005002:	ec06                	sd	ra,24(sp)
    80005004:	e822                	sd	s0,16(sp)
    80005006:	e426                	sd	s1,8(sp)
    80005008:	e04a                	sd	s2,0(sp)
    8000500a:	1000                	add	s0,sp,32
    8000500c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000500e:	00850913          	add	s2,a0,8
    80005012:	854a                	mv	a0,s2
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	bbe080e7          	jalr	-1090(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    8000501c:	409c                	lw	a5,0(s1)
    8000501e:	cb89                	beqz	a5,80005030 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005020:	85ca                	mv	a1,s2
    80005022:	8526                	mv	a0,s1
    80005024:	ffffd097          	auipc	ra,0xffffd
    80005028:	65e080e7          	jalr	1630(ra) # 80002682 <sleep>
  while (lk->locked) {
    8000502c:	409c                	lw	a5,0(s1)
    8000502e:	fbed                	bnez	a5,80005020 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005030:	4785                	li	a5,1
    80005032:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	972080e7          	jalr	-1678(ra) # 800019a6 <myproc>
    8000503c:	591c                	lw	a5,48(a0)
    8000503e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005040:	854a                	mv	a0,s2
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	c44080e7          	jalr	-956(ra) # 80000c86 <release>
}
    8000504a:	60e2                	ld	ra,24(sp)
    8000504c:	6442                	ld	s0,16(sp)
    8000504e:	64a2                	ld	s1,8(sp)
    80005050:	6902                	ld	s2,0(sp)
    80005052:	6105                	add	sp,sp,32
    80005054:	8082                	ret

0000000080005056 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005056:	1101                	add	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	e04a                	sd	s2,0(sp)
    80005060:	1000                	add	s0,sp,32
    80005062:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005064:	00850913          	add	s2,a0,8
    80005068:	854a                	mv	a0,s2
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	b68080e7          	jalr	-1176(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80005072:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005076:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000507a:	8526                	mv	a0,s1
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	66a080e7          	jalr	1642(ra) # 800026e6 <wakeup>
  release(&lk->lk);
    80005084:	854a                	mv	a0,s2
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c00080e7          	jalr	-1024(ra) # 80000c86 <release>
}
    8000508e:	60e2                	ld	ra,24(sp)
    80005090:	6442                	ld	s0,16(sp)
    80005092:	64a2                	ld	s1,8(sp)
    80005094:	6902                	ld	s2,0(sp)
    80005096:	6105                	add	sp,sp,32
    80005098:	8082                	ret

000000008000509a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000509a:	7179                	add	sp,sp,-48
    8000509c:	f406                	sd	ra,40(sp)
    8000509e:	f022                	sd	s0,32(sp)
    800050a0:	ec26                	sd	s1,24(sp)
    800050a2:	e84a                	sd	s2,16(sp)
    800050a4:	e44e                	sd	s3,8(sp)
    800050a6:	1800                	add	s0,sp,48
    800050a8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800050aa:	00850913          	add	s2,a0,8
    800050ae:	854a                	mv	a0,s2
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	b22080e7          	jalr	-1246(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050b8:	409c                	lw	a5,0(s1)
    800050ba:	ef99                	bnez	a5,800050d8 <holdingsleep+0x3e>
    800050bc:	4481                	li	s1,0
  release(&lk->lk);
    800050be:	854a                	mv	a0,s2
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	bc6080e7          	jalr	-1082(ra) # 80000c86 <release>
  return r;
}
    800050c8:	8526                	mv	a0,s1
    800050ca:	70a2                	ld	ra,40(sp)
    800050cc:	7402                	ld	s0,32(sp)
    800050ce:	64e2                	ld	s1,24(sp)
    800050d0:	6942                	ld	s2,16(sp)
    800050d2:	69a2                	ld	s3,8(sp)
    800050d4:	6145                	add	sp,sp,48
    800050d6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050d8:	0284a983          	lw	s3,40(s1)
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	8ca080e7          	jalr	-1846(ra) # 800019a6 <myproc>
    800050e4:	5904                	lw	s1,48(a0)
    800050e6:	413484b3          	sub	s1,s1,s3
    800050ea:	0014b493          	seqz	s1,s1
    800050ee:	bfc1                	j	800050be <holdingsleep+0x24>

00000000800050f0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050f0:	1141                	add	sp,sp,-16
    800050f2:	e406                	sd	ra,8(sp)
    800050f4:	e022                	sd	s0,0(sp)
    800050f6:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050f8:	00003597          	auipc	a1,0x3
    800050fc:	62858593          	add	a1,a1,1576 # 80008720 <syscalls+0x280>
    80005100:	00020517          	auipc	a0,0x20
    80005104:	db850513          	add	a0,a0,-584 # 80024eb8 <ftable>
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	a3a080e7          	jalr	-1478(ra) # 80000b42 <initlock>
}
    80005110:	60a2                	ld	ra,8(sp)
    80005112:	6402                	ld	s0,0(sp)
    80005114:	0141                	add	sp,sp,16
    80005116:	8082                	ret

0000000080005118 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005118:	1101                	add	sp,sp,-32
    8000511a:	ec06                	sd	ra,24(sp)
    8000511c:	e822                	sd	s0,16(sp)
    8000511e:	e426                	sd	s1,8(sp)
    80005120:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005122:	00020517          	auipc	a0,0x20
    80005126:	d9650513          	add	a0,a0,-618 # 80024eb8 <ftable>
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	aa8080e7          	jalr	-1368(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005132:	00020497          	auipc	s1,0x20
    80005136:	d9e48493          	add	s1,s1,-610 # 80024ed0 <ftable+0x18>
    8000513a:	00021717          	auipc	a4,0x21
    8000513e:	d3670713          	add	a4,a4,-714 # 80025e70 <disk>
    if(f->ref == 0){
    80005142:	40dc                	lw	a5,4(s1)
    80005144:	cf99                	beqz	a5,80005162 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005146:	02848493          	add	s1,s1,40
    8000514a:	fee49ce3          	bne	s1,a4,80005142 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000514e:	00020517          	auipc	a0,0x20
    80005152:	d6a50513          	add	a0,a0,-662 # 80024eb8 <ftable>
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	b30080e7          	jalr	-1232(ra) # 80000c86 <release>
  return 0;
    8000515e:	4481                	li	s1,0
    80005160:	a819                	j	80005176 <filealloc+0x5e>
      f->ref = 1;
    80005162:	4785                	li	a5,1
    80005164:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005166:	00020517          	auipc	a0,0x20
    8000516a:	d5250513          	add	a0,a0,-686 # 80024eb8 <ftable>
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	b18080e7          	jalr	-1256(ra) # 80000c86 <release>
}
    80005176:	8526                	mv	a0,s1
    80005178:	60e2                	ld	ra,24(sp)
    8000517a:	6442                	ld	s0,16(sp)
    8000517c:	64a2                	ld	s1,8(sp)
    8000517e:	6105                	add	sp,sp,32
    80005180:	8082                	ret

0000000080005182 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005182:	1101                	add	sp,sp,-32
    80005184:	ec06                	sd	ra,24(sp)
    80005186:	e822                	sd	s0,16(sp)
    80005188:	e426                	sd	s1,8(sp)
    8000518a:	1000                	add	s0,sp,32
    8000518c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000518e:	00020517          	auipc	a0,0x20
    80005192:	d2a50513          	add	a0,a0,-726 # 80024eb8 <ftable>
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	a3c080e7          	jalr	-1476(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000519e:	40dc                	lw	a5,4(s1)
    800051a0:	02f05263          	blez	a5,800051c4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800051a4:	2785                	addw	a5,a5,1
    800051a6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800051a8:	00020517          	auipc	a0,0x20
    800051ac:	d1050513          	add	a0,a0,-752 # 80024eb8 <ftable>
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	ad6080e7          	jalr	-1322(ra) # 80000c86 <release>
  return f;
}
    800051b8:	8526                	mv	a0,s1
    800051ba:	60e2                	ld	ra,24(sp)
    800051bc:	6442                	ld	s0,16(sp)
    800051be:	64a2                	ld	s1,8(sp)
    800051c0:	6105                	add	sp,sp,32
    800051c2:	8082                	ret
    panic("filedup");
    800051c4:	00003517          	auipc	a0,0x3
    800051c8:	56450513          	add	a0,a0,1380 # 80008728 <syscalls+0x288>
    800051cc:	ffffb097          	auipc	ra,0xffffb
    800051d0:	370080e7          	jalr	880(ra) # 8000053c <panic>

00000000800051d4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051d4:	7139                	add	sp,sp,-64
    800051d6:	fc06                	sd	ra,56(sp)
    800051d8:	f822                	sd	s0,48(sp)
    800051da:	f426                	sd	s1,40(sp)
    800051dc:	f04a                	sd	s2,32(sp)
    800051de:	ec4e                	sd	s3,24(sp)
    800051e0:	e852                	sd	s4,16(sp)
    800051e2:	e456                	sd	s5,8(sp)
    800051e4:	0080                	add	s0,sp,64
    800051e6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051e8:	00020517          	auipc	a0,0x20
    800051ec:	cd050513          	add	a0,a0,-816 # 80024eb8 <ftable>
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	9e2080e7          	jalr	-1566(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800051f8:	40dc                	lw	a5,4(s1)
    800051fa:	06f05163          	blez	a5,8000525c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051fe:	37fd                	addw	a5,a5,-1
    80005200:	0007871b          	sext.w	a4,a5
    80005204:	c0dc                	sw	a5,4(s1)
    80005206:	06e04363          	bgtz	a4,8000526c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000520a:	0004a903          	lw	s2,0(s1)
    8000520e:	0094ca83          	lbu	s5,9(s1)
    80005212:	0104ba03          	ld	s4,16(s1)
    80005216:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000521a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000521e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005222:	00020517          	auipc	a0,0x20
    80005226:	c9650513          	add	a0,a0,-874 # 80024eb8 <ftable>
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	a5c080e7          	jalr	-1444(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80005232:	4785                	li	a5,1
    80005234:	04f90d63          	beq	s2,a5,8000528e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005238:	3979                	addw	s2,s2,-2
    8000523a:	4785                	li	a5,1
    8000523c:	0527e063          	bltu	a5,s2,8000527c <fileclose+0xa8>
    begin_op();
    80005240:	00000097          	auipc	ra,0x0
    80005244:	ad0080e7          	jalr	-1328(ra) # 80004d10 <begin_op>
    iput(ff.ip);
    80005248:	854e                	mv	a0,s3
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	2da080e7          	jalr	730(ra) # 80004524 <iput>
    end_op();
    80005252:	00000097          	auipc	ra,0x0
    80005256:	b38080e7          	jalr	-1224(ra) # 80004d8a <end_op>
    8000525a:	a00d                	j	8000527c <fileclose+0xa8>
    panic("fileclose");
    8000525c:	00003517          	auipc	a0,0x3
    80005260:	4d450513          	add	a0,a0,1236 # 80008730 <syscalls+0x290>
    80005264:	ffffb097          	auipc	ra,0xffffb
    80005268:	2d8080e7          	jalr	728(ra) # 8000053c <panic>
    release(&ftable.lock);
    8000526c:	00020517          	auipc	a0,0x20
    80005270:	c4c50513          	add	a0,a0,-948 # 80024eb8 <ftable>
    80005274:	ffffc097          	auipc	ra,0xffffc
    80005278:	a12080e7          	jalr	-1518(ra) # 80000c86 <release>
  }
}
    8000527c:	70e2                	ld	ra,56(sp)
    8000527e:	7442                	ld	s0,48(sp)
    80005280:	74a2                	ld	s1,40(sp)
    80005282:	7902                	ld	s2,32(sp)
    80005284:	69e2                	ld	s3,24(sp)
    80005286:	6a42                	ld	s4,16(sp)
    80005288:	6aa2                	ld	s5,8(sp)
    8000528a:	6121                	add	sp,sp,64
    8000528c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000528e:	85d6                	mv	a1,s5
    80005290:	8552                	mv	a0,s4
    80005292:	00000097          	auipc	ra,0x0
    80005296:	348080e7          	jalr	840(ra) # 800055da <pipeclose>
    8000529a:	b7cd                	j	8000527c <fileclose+0xa8>

000000008000529c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000529c:	715d                	add	sp,sp,-80
    8000529e:	e486                	sd	ra,72(sp)
    800052a0:	e0a2                	sd	s0,64(sp)
    800052a2:	fc26                	sd	s1,56(sp)
    800052a4:	f84a                	sd	s2,48(sp)
    800052a6:	f44e                	sd	s3,40(sp)
    800052a8:	0880                	add	s0,sp,80
    800052aa:	84aa                	mv	s1,a0
    800052ac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	6f8080e7          	jalr	1784(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052b6:	409c                	lw	a5,0(s1)
    800052b8:	37f9                	addw	a5,a5,-2
    800052ba:	4705                	li	a4,1
    800052bc:	04f76763          	bltu	a4,a5,8000530a <filestat+0x6e>
    800052c0:	892a                	mv	s2,a0
    ilock(f->ip);
    800052c2:	6c88                	ld	a0,24(s1)
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	0a6080e7          	jalr	166(ra) # 8000436a <ilock>
    stati(f->ip, &st);
    800052cc:	fb840593          	add	a1,s0,-72
    800052d0:	6c88                	ld	a0,24(s1)
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	322080e7          	jalr	802(ra) # 800045f4 <stati>
    iunlock(f->ip);
    800052da:	6c88                	ld	a0,24(s1)
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	150080e7          	jalr	336(ra) # 8000442c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052e4:	46e1                	li	a3,24
    800052e6:	fb840613          	add	a2,s0,-72
    800052ea:	85ce                	mv	a1,s3
    800052ec:	05093503          	ld	a0,80(s2)
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	376080e7          	jalr	886(ra) # 80001666 <copyout>
    800052f8:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052fc:	60a6                	ld	ra,72(sp)
    800052fe:	6406                	ld	s0,64(sp)
    80005300:	74e2                	ld	s1,56(sp)
    80005302:	7942                	ld	s2,48(sp)
    80005304:	79a2                	ld	s3,40(sp)
    80005306:	6161                	add	sp,sp,80
    80005308:	8082                	ret
  return -1;
    8000530a:	557d                	li	a0,-1
    8000530c:	bfc5                	j	800052fc <filestat+0x60>

000000008000530e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000530e:	7179                	add	sp,sp,-48
    80005310:	f406                	sd	ra,40(sp)
    80005312:	f022                	sd	s0,32(sp)
    80005314:	ec26                	sd	s1,24(sp)
    80005316:	e84a                	sd	s2,16(sp)
    80005318:	e44e                	sd	s3,8(sp)
    8000531a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000531c:	00854783          	lbu	a5,8(a0)
    80005320:	c3d5                	beqz	a5,800053c4 <fileread+0xb6>
    80005322:	84aa                	mv	s1,a0
    80005324:	89ae                	mv	s3,a1
    80005326:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005328:	411c                	lw	a5,0(a0)
    8000532a:	4705                	li	a4,1
    8000532c:	04e78963          	beq	a5,a4,8000537e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005330:	470d                	li	a4,3
    80005332:	04e78d63          	beq	a5,a4,8000538c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005336:	4709                	li	a4,2
    80005338:	06e79e63          	bne	a5,a4,800053b4 <fileread+0xa6>
    ilock(f->ip);
    8000533c:	6d08                	ld	a0,24(a0)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	02c080e7          	jalr	44(ra) # 8000436a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005346:	874a                	mv	a4,s2
    80005348:	5094                	lw	a3,32(s1)
    8000534a:	864e                	mv	a2,s3
    8000534c:	4585                	li	a1,1
    8000534e:	6c88                	ld	a0,24(s1)
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	2ce080e7          	jalr	718(ra) # 8000461e <readi>
    80005358:	892a                	mv	s2,a0
    8000535a:	00a05563          	blez	a0,80005364 <fileread+0x56>
      f->off += r;
    8000535e:	509c                	lw	a5,32(s1)
    80005360:	9fa9                	addw	a5,a5,a0
    80005362:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005364:	6c88                	ld	a0,24(s1)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	0c6080e7          	jalr	198(ra) # 8000442c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000536e:	854a                	mv	a0,s2
    80005370:	70a2                	ld	ra,40(sp)
    80005372:	7402                	ld	s0,32(sp)
    80005374:	64e2                	ld	s1,24(sp)
    80005376:	6942                	ld	s2,16(sp)
    80005378:	69a2                	ld	s3,8(sp)
    8000537a:	6145                	add	sp,sp,48
    8000537c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000537e:	6908                	ld	a0,16(a0)
    80005380:	00000097          	auipc	ra,0x0
    80005384:	3c2080e7          	jalr	962(ra) # 80005742 <piperead>
    80005388:	892a                	mv	s2,a0
    8000538a:	b7d5                	j	8000536e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000538c:	02451783          	lh	a5,36(a0)
    80005390:	03079693          	sll	a3,a5,0x30
    80005394:	92c1                	srl	a3,a3,0x30
    80005396:	4725                	li	a4,9
    80005398:	02d76863          	bltu	a4,a3,800053c8 <fileread+0xba>
    8000539c:	0792                	sll	a5,a5,0x4
    8000539e:	00020717          	auipc	a4,0x20
    800053a2:	a7a70713          	add	a4,a4,-1414 # 80024e18 <devsw>
    800053a6:	97ba                	add	a5,a5,a4
    800053a8:	639c                	ld	a5,0(a5)
    800053aa:	c38d                	beqz	a5,800053cc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800053ac:	4505                	li	a0,1
    800053ae:	9782                	jalr	a5
    800053b0:	892a                	mv	s2,a0
    800053b2:	bf75                	j	8000536e <fileread+0x60>
    panic("fileread");
    800053b4:	00003517          	auipc	a0,0x3
    800053b8:	38c50513          	add	a0,a0,908 # 80008740 <syscalls+0x2a0>
    800053bc:	ffffb097          	auipc	ra,0xffffb
    800053c0:	180080e7          	jalr	384(ra) # 8000053c <panic>
    return -1;
    800053c4:	597d                	li	s2,-1
    800053c6:	b765                	j	8000536e <fileread+0x60>
      return -1;
    800053c8:	597d                	li	s2,-1
    800053ca:	b755                	j	8000536e <fileread+0x60>
    800053cc:	597d                	li	s2,-1
    800053ce:	b745                	j	8000536e <fileread+0x60>

00000000800053d0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800053d0:	00954783          	lbu	a5,9(a0)
    800053d4:	10078e63          	beqz	a5,800054f0 <filewrite+0x120>
{
    800053d8:	715d                	add	sp,sp,-80
    800053da:	e486                	sd	ra,72(sp)
    800053dc:	e0a2                	sd	s0,64(sp)
    800053de:	fc26                	sd	s1,56(sp)
    800053e0:	f84a                	sd	s2,48(sp)
    800053e2:	f44e                	sd	s3,40(sp)
    800053e4:	f052                	sd	s4,32(sp)
    800053e6:	ec56                	sd	s5,24(sp)
    800053e8:	e85a                	sd	s6,16(sp)
    800053ea:	e45e                	sd	s7,8(sp)
    800053ec:	e062                	sd	s8,0(sp)
    800053ee:	0880                	add	s0,sp,80
    800053f0:	892a                	mv	s2,a0
    800053f2:	8b2e                	mv	s6,a1
    800053f4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053f6:	411c                	lw	a5,0(a0)
    800053f8:	4705                	li	a4,1
    800053fa:	02e78263          	beq	a5,a4,8000541e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053fe:	470d                	li	a4,3
    80005400:	02e78563          	beq	a5,a4,8000542a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005404:	4709                	li	a4,2
    80005406:	0ce79d63          	bne	a5,a4,800054e0 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000540a:	0ac05b63          	blez	a2,800054c0 <filewrite+0xf0>
    int i = 0;
    8000540e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80005410:	6b85                	lui	s7,0x1
    80005412:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005416:	6c05                	lui	s8,0x1
    80005418:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000541c:	a851                	j	800054b0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000541e:	6908                	ld	a0,16(a0)
    80005420:	00000097          	auipc	ra,0x0
    80005424:	22a080e7          	jalr	554(ra) # 8000564a <pipewrite>
    80005428:	a045                	j	800054c8 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000542a:	02451783          	lh	a5,36(a0)
    8000542e:	03079693          	sll	a3,a5,0x30
    80005432:	92c1                	srl	a3,a3,0x30
    80005434:	4725                	li	a4,9
    80005436:	0ad76f63          	bltu	a4,a3,800054f4 <filewrite+0x124>
    8000543a:	0792                	sll	a5,a5,0x4
    8000543c:	00020717          	auipc	a4,0x20
    80005440:	9dc70713          	add	a4,a4,-1572 # 80024e18 <devsw>
    80005444:	97ba                	add	a5,a5,a4
    80005446:	679c                	ld	a5,8(a5)
    80005448:	cbc5                	beqz	a5,800054f8 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    8000544a:	4505                	li	a0,1
    8000544c:	9782                	jalr	a5
    8000544e:	a8ad                	j	800054c8 <filewrite+0xf8>
      if(n1 > max)
    80005450:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80005454:	00000097          	auipc	ra,0x0
    80005458:	8bc080e7          	jalr	-1860(ra) # 80004d10 <begin_op>
      ilock(f->ip);
    8000545c:	01893503          	ld	a0,24(s2)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	f0a080e7          	jalr	-246(ra) # 8000436a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005468:	8756                	mv	a4,s5
    8000546a:	02092683          	lw	a3,32(s2)
    8000546e:	01698633          	add	a2,s3,s6
    80005472:	4585                	li	a1,1
    80005474:	01893503          	ld	a0,24(s2)
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	29e080e7          	jalr	670(ra) # 80004716 <writei>
    80005480:	84aa                	mv	s1,a0
    80005482:	00a05763          	blez	a0,80005490 <filewrite+0xc0>
        f->off += r;
    80005486:	02092783          	lw	a5,32(s2)
    8000548a:	9fa9                	addw	a5,a5,a0
    8000548c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005490:	01893503          	ld	a0,24(s2)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	f98080e7          	jalr	-104(ra) # 8000442c <iunlock>
      end_op();
    8000549c:	00000097          	auipc	ra,0x0
    800054a0:	8ee080e7          	jalr	-1810(ra) # 80004d8a <end_op>

      if(r != n1){
    800054a4:	009a9f63          	bne	s5,s1,800054c2 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800054a8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800054ac:	0149db63          	bge	s3,s4,800054c2 <filewrite+0xf2>
      int n1 = n - i;
    800054b0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800054b4:	0004879b          	sext.w	a5,s1
    800054b8:	f8fbdce3          	bge	s7,a5,80005450 <filewrite+0x80>
    800054bc:	84e2                	mv	s1,s8
    800054be:	bf49                	j	80005450 <filewrite+0x80>
    int i = 0;
    800054c0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054c2:	033a1d63          	bne	s4,s3,800054fc <filewrite+0x12c>
    800054c6:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054c8:	60a6                	ld	ra,72(sp)
    800054ca:	6406                	ld	s0,64(sp)
    800054cc:	74e2                	ld	s1,56(sp)
    800054ce:	7942                	ld	s2,48(sp)
    800054d0:	79a2                	ld	s3,40(sp)
    800054d2:	7a02                	ld	s4,32(sp)
    800054d4:	6ae2                	ld	s5,24(sp)
    800054d6:	6b42                	ld	s6,16(sp)
    800054d8:	6ba2                	ld	s7,8(sp)
    800054da:	6c02                	ld	s8,0(sp)
    800054dc:	6161                	add	sp,sp,80
    800054de:	8082                	ret
    panic("filewrite");
    800054e0:	00003517          	auipc	a0,0x3
    800054e4:	27050513          	add	a0,a0,624 # 80008750 <syscalls+0x2b0>
    800054e8:	ffffb097          	auipc	ra,0xffffb
    800054ec:	054080e7          	jalr	84(ra) # 8000053c <panic>
    return -1;
    800054f0:	557d                	li	a0,-1
}
    800054f2:	8082                	ret
      return -1;
    800054f4:	557d                	li	a0,-1
    800054f6:	bfc9                	j	800054c8 <filewrite+0xf8>
    800054f8:	557d                	li	a0,-1
    800054fa:	b7f9                	j	800054c8 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800054fc:	557d                	li	a0,-1
    800054fe:	b7e9                	j	800054c8 <filewrite+0xf8>

0000000080005500 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005500:	7179                	add	sp,sp,-48
    80005502:	f406                	sd	ra,40(sp)
    80005504:	f022                	sd	s0,32(sp)
    80005506:	ec26                	sd	s1,24(sp)
    80005508:	e84a                	sd	s2,16(sp)
    8000550a:	e44e                	sd	s3,8(sp)
    8000550c:	e052                	sd	s4,0(sp)
    8000550e:	1800                	add	s0,sp,48
    80005510:	84aa                	mv	s1,a0
    80005512:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005514:	0005b023          	sd	zero,0(a1)
    80005518:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000551c:	00000097          	auipc	ra,0x0
    80005520:	bfc080e7          	jalr	-1028(ra) # 80005118 <filealloc>
    80005524:	e088                	sd	a0,0(s1)
    80005526:	c551                	beqz	a0,800055b2 <pipealloc+0xb2>
    80005528:	00000097          	auipc	ra,0x0
    8000552c:	bf0080e7          	jalr	-1040(ra) # 80005118 <filealloc>
    80005530:	00aa3023          	sd	a0,0(s4)
    80005534:	c92d                	beqz	a0,800055a6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005536:	ffffb097          	auipc	ra,0xffffb
    8000553a:	5ac080e7          	jalr	1452(ra) # 80000ae2 <kalloc>
    8000553e:	892a                	mv	s2,a0
    80005540:	c125                	beqz	a0,800055a0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005542:	4985                	li	s3,1
    80005544:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005548:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000554c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005550:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005554:	00003597          	auipc	a1,0x3
    80005558:	20c58593          	add	a1,a1,524 # 80008760 <syscalls+0x2c0>
    8000555c:	ffffb097          	auipc	ra,0xffffb
    80005560:	5e6080e7          	jalr	1510(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80005564:	609c                	ld	a5,0(s1)
    80005566:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000556a:	609c                	ld	a5,0(s1)
    8000556c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005570:	609c                	ld	a5,0(s1)
    80005572:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005576:	609c                	ld	a5,0(s1)
    80005578:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000557c:	000a3783          	ld	a5,0(s4)
    80005580:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005584:	000a3783          	ld	a5,0(s4)
    80005588:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000558c:	000a3783          	ld	a5,0(s4)
    80005590:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005594:	000a3783          	ld	a5,0(s4)
    80005598:	0127b823          	sd	s2,16(a5)
  return 0;
    8000559c:	4501                	li	a0,0
    8000559e:	a025                	j	800055c6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800055a0:	6088                	ld	a0,0(s1)
    800055a2:	e501                	bnez	a0,800055aa <pipealloc+0xaa>
    800055a4:	a039                	j	800055b2 <pipealloc+0xb2>
    800055a6:	6088                	ld	a0,0(s1)
    800055a8:	c51d                	beqz	a0,800055d6 <pipealloc+0xd6>
    fileclose(*f0);
    800055aa:	00000097          	auipc	ra,0x0
    800055ae:	c2a080e7          	jalr	-982(ra) # 800051d4 <fileclose>
  if(*f1)
    800055b2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055b6:	557d                	li	a0,-1
  if(*f1)
    800055b8:	c799                	beqz	a5,800055c6 <pipealloc+0xc6>
    fileclose(*f1);
    800055ba:	853e                	mv	a0,a5
    800055bc:	00000097          	auipc	ra,0x0
    800055c0:	c18080e7          	jalr	-1000(ra) # 800051d4 <fileclose>
  return -1;
    800055c4:	557d                	li	a0,-1
}
    800055c6:	70a2                	ld	ra,40(sp)
    800055c8:	7402                	ld	s0,32(sp)
    800055ca:	64e2                	ld	s1,24(sp)
    800055cc:	6942                	ld	s2,16(sp)
    800055ce:	69a2                	ld	s3,8(sp)
    800055d0:	6a02                	ld	s4,0(sp)
    800055d2:	6145                	add	sp,sp,48
    800055d4:	8082                	ret
  return -1;
    800055d6:	557d                	li	a0,-1
    800055d8:	b7fd                	j	800055c6 <pipealloc+0xc6>

00000000800055da <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055da:	1101                	add	sp,sp,-32
    800055dc:	ec06                	sd	ra,24(sp)
    800055de:	e822                	sd	s0,16(sp)
    800055e0:	e426                	sd	s1,8(sp)
    800055e2:	e04a                	sd	s2,0(sp)
    800055e4:	1000                	add	s0,sp,32
    800055e6:	84aa                	mv	s1,a0
    800055e8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	5e8080e7          	jalr	1512(ra) # 80000bd2 <acquire>
  if(writable){
    800055f2:	02090d63          	beqz	s2,8000562c <pipeclose+0x52>
    pi->writeopen = 0;
    800055f6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055fa:	21848513          	add	a0,s1,536
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	0e8080e7          	jalr	232(ra) # 800026e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005606:	2204b783          	ld	a5,544(s1)
    8000560a:	eb95                	bnez	a5,8000563e <pipeclose+0x64>
    release(&pi->lock);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	678080e7          	jalr	1656(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffb097          	auipc	ra,0xffffb
    8000561c:	3cc080e7          	jalr	972(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80005620:	60e2                	ld	ra,24(sp)
    80005622:	6442                	ld	s0,16(sp)
    80005624:	64a2                	ld	s1,8(sp)
    80005626:	6902                	ld	s2,0(sp)
    80005628:	6105                	add	sp,sp,32
    8000562a:	8082                	ret
    pi->readopen = 0;
    8000562c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005630:	21c48513          	add	a0,s1,540
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	0b2080e7          	jalr	178(ra) # 800026e6 <wakeup>
    8000563c:	b7e9                	j	80005606 <pipeclose+0x2c>
    release(&pi->lock);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	646080e7          	jalr	1606(ra) # 80000c86 <release>
}
    80005648:	bfe1                	j	80005620 <pipeclose+0x46>

000000008000564a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000564a:	711d                	add	sp,sp,-96
    8000564c:	ec86                	sd	ra,88(sp)
    8000564e:	e8a2                	sd	s0,80(sp)
    80005650:	e4a6                	sd	s1,72(sp)
    80005652:	e0ca                	sd	s2,64(sp)
    80005654:	fc4e                	sd	s3,56(sp)
    80005656:	f852                	sd	s4,48(sp)
    80005658:	f456                	sd	s5,40(sp)
    8000565a:	f05a                	sd	s6,32(sp)
    8000565c:	ec5e                	sd	s7,24(sp)
    8000565e:	e862                	sd	s8,16(sp)
    80005660:	1080                	add	s0,sp,96
    80005662:	84aa                	mv	s1,a0
    80005664:	8aae                	mv	s5,a1
    80005666:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005668:	ffffc097          	auipc	ra,0xffffc
    8000566c:	33e080e7          	jalr	830(ra) # 800019a6 <myproc>
    80005670:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	55e080e7          	jalr	1374(ra) # 80000bd2 <acquire>
  while(i < n){
    8000567c:	0b405663          	blez	s4,80005728 <pipewrite+0xde>
  int i = 0;
    80005680:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005682:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005684:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005688:	21c48b93          	add	s7,s1,540
    8000568c:	a089                	j	800056ce <pipewrite+0x84>
      release(&pi->lock);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffb097          	auipc	ra,0xffffb
    80005694:	5f6080e7          	jalr	1526(ra) # 80000c86 <release>
      return -1;
    80005698:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000569a:	854a                	mv	a0,s2
    8000569c:	60e6                	ld	ra,88(sp)
    8000569e:	6446                	ld	s0,80(sp)
    800056a0:	64a6                	ld	s1,72(sp)
    800056a2:	6906                	ld	s2,64(sp)
    800056a4:	79e2                	ld	s3,56(sp)
    800056a6:	7a42                	ld	s4,48(sp)
    800056a8:	7aa2                	ld	s5,40(sp)
    800056aa:	7b02                	ld	s6,32(sp)
    800056ac:	6be2                	ld	s7,24(sp)
    800056ae:	6c42                	ld	s8,16(sp)
    800056b0:	6125                	add	sp,sp,96
    800056b2:	8082                	ret
      wakeup(&pi->nread);
    800056b4:	8562                	mv	a0,s8
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	030080e7          	jalr	48(ra) # 800026e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056be:	85a6                	mv	a1,s1
    800056c0:	855e                	mv	a0,s7
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	fc0080e7          	jalr	-64(ra) # 80002682 <sleep>
  while(i < n){
    800056ca:	07495063          	bge	s2,s4,8000572a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800056ce:	2204a783          	lw	a5,544(s1)
    800056d2:	dfd5                	beqz	a5,8000568e <pipewrite+0x44>
    800056d4:	854e                	mv	a0,s3
    800056d6:	ffffd097          	auipc	ra,0xffffd
    800056da:	260080e7          	jalr	608(ra) # 80002936 <killed>
    800056de:	f945                	bnez	a0,8000568e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056e0:	2184a783          	lw	a5,536(s1)
    800056e4:	21c4a703          	lw	a4,540(s1)
    800056e8:	2007879b          	addw	a5,a5,512
    800056ec:	fcf704e3          	beq	a4,a5,800056b4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056f0:	4685                	li	a3,1
    800056f2:	01590633          	add	a2,s2,s5
    800056f6:	faf40593          	add	a1,s0,-81
    800056fa:	0509b503          	ld	a0,80(s3)
    800056fe:	ffffc097          	auipc	ra,0xffffc
    80005702:	ff4080e7          	jalr	-12(ra) # 800016f2 <copyin>
    80005706:	03650263          	beq	a0,s6,8000572a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000570a:	21c4a783          	lw	a5,540(s1)
    8000570e:	0017871b          	addw	a4,a5,1
    80005712:	20e4ae23          	sw	a4,540(s1)
    80005716:	1ff7f793          	and	a5,a5,511
    8000571a:	97a6                	add	a5,a5,s1
    8000571c:	faf44703          	lbu	a4,-81(s0)
    80005720:	00e78c23          	sb	a4,24(a5)
      i++;
    80005724:	2905                	addw	s2,s2,1
    80005726:	b755                	j	800056ca <pipewrite+0x80>
  int i = 0;
    80005728:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000572a:	21848513          	add	a0,s1,536
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	fb8080e7          	jalr	-72(ra) # 800026e6 <wakeup>
  release(&pi->lock);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	54e080e7          	jalr	1358(ra) # 80000c86 <release>
  return i;
    80005740:	bfa9                	j	8000569a <pipewrite+0x50>

0000000080005742 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005742:	715d                	add	sp,sp,-80
    80005744:	e486                	sd	ra,72(sp)
    80005746:	e0a2                	sd	s0,64(sp)
    80005748:	fc26                	sd	s1,56(sp)
    8000574a:	f84a                	sd	s2,48(sp)
    8000574c:	f44e                	sd	s3,40(sp)
    8000574e:	f052                	sd	s4,32(sp)
    80005750:	ec56                	sd	s5,24(sp)
    80005752:	e85a                	sd	s6,16(sp)
    80005754:	0880                	add	s0,sp,80
    80005756:	84aa                	mv	s1,a0
    80005758:	892e                	mv	s2,a1
    8000575a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000575c:	ffffc097          	auipc	ra,0xffffc
    80005760:	24a080e7          	jalr	586(ra) # 800019a6 <myproc>
    80005764:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005766:	8526                	mv	a0,s1
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	46a080e7          	jalr	1130(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005770:	2184a703          	lw	a4,536(s1)
    80005774:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005778:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000577c:	02f71763          	bne	a4,a5,800057aa <piperead+0x68>
    80005780:	2244a783          	lw	a5,548(s1)
    80005784:	c39d                	beqz	a5,800057aa <piperead+0x68>
    if(killed(pr)){
    80005786:	8552                	mv	a0,s4
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	1ae080e7          	jalr	430(ra) # 80002936 <killed>
    80005790:	e949                	bnez	a0,80005822 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005792:	85a6                	mv	a1,s1
    80005794:	854e                	mv	a0,s3
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	eec080e7          	jalr	-276(ra) # 80002682 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000579e:	2184a703          	lw	a4,536(s1)
    800057a2:	21c4a783          	lw	a5,540(s1)
    800057a6:	fcf70de3          	beq	a4,a5,80005780 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057aa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057ac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057ae:	05505463          	blez	s5,800057f6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800057b2:	2184a783          	lw	a5,536(s1)
    800057b6:	21c4a703          	lw	a4,540(s1)
    800057ba:	02f70e63          	beq	a4,a5,800057f6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057be:	0017871b          	addw	a4,a5,1
    800057c2:	20e4ac23          	sw	a4,536(s1)
    800057c6:	1ff7f793          	and	a5,a5,511
    800057ca:	97a6                	add	a5,a5,s1
    800057cc:	0187c783          	lbu	a5,24(a5)
    800057d0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057d4:	4685                	li	a3,1
    800057d6:	fbf40613          	add	a2,s0,-65
    800057da:	85ca                	mv	a1,s2
    800057dc:	050a3503          	ld	a0,80(s4)
    800057e0:	ffffc097          	auipc	ra,0xffffc
    800057e4:	e86080e7          	jalr	-378(ra) # 80001666 <copyout>
    800057e8:	01650763          	beq	a0,s6,800057f6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057ec:	2985                	addw	s3,s3,1
    800057ee:	0905                	add	s2,s2,1
    800057f0:	fd3a91e3          	bne	s5,s3,800057b2 <piperead+0x70>
    800057f4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057f6:	21c48513          	add	a0,s1,540
    800057fa:	ffffd097          	auipc	ra,0xffffd
    800057fe:	eec080e7          	jalr	-276(ra) # 800026e6 <wakeup>
  release(&pi->lock);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffb097          	auipc	ra,0xffffb
    80005808:	482080e7          	jalr	1154(ra) # 80000c86 <release>
  return i;
}
    8000580c:	854e                	mv	a0,s3
    8000580e:	60a6                	ld	ra,72(sp)
    80005810:	6406                	ld	s0,64(sp)
    80005812:	74e2                	ld	s1,56(sp)
    80005814:	7942                	ld	s2,48(sp)
    80005816:	79a2                	ld	s3,40(sp)
    80005818:	7a02                	ld	s4,32(sp)
    8000581a:	6ae2                	ld	s5,24(sp)
    8000581c:	6b42                	ld	s6,16(sp)
    8000581e:	6161                	add	sp,sp,80
    80005820:	8082                	ret
      release(&pi->lock);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffb097          	auipc	ra,0xffffb
    80005828:	462080e7          	jalr	1122(ra) # 80000c86 <release>
      return -1;
    8000582c:	59fd                	li	s3,-1
    8000582e:	bff9                	j	8000580c <piperead+0xca>

0000000080005830 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005830:	1141                	add	sp,sp,-16
    80005832:	e422                	sd	s0,8(sp)
    80005834:	0800                	add	s0,sp,16
    80005836:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005838:	8905                	and	a0,a0,1
    8000583a:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000583c:	8b89                	and	a5,a5,2
    8000583e:	c399                	beqz	a5,80005844 <flags2perm+0x14>
      perm |= PTE_W;
    80005840:	00456513          	or	a0,a0,4
    return perm;
}
    80005844:	6422                	ld	s0,8(sp)
    80005846:	0141                	add	sp,sp,16
    80005848:	8082                	ret

000000008000584a <exec>:

int
exec(char *path, char **argv)
{
    8000584a:	df010113          	add	sp,sp,-528
    8000584e:	20113423          	sd	ra,520(sp)
    80005852:	20813023          	sd	s0,512(sp)
    80005856:	ffa6                	sd	s1,504(sp)
    80005858:	fbca                	sd	s2,496(sp)
    8000585a:	f7ce                	sd	s3,488(sp)
    8000585c:	f3d2                	sd	s4,480(sp)
    8000585e:	efd6                	sd	s5,472(sp)
    80005860:	ebda                	sd	s6,464(sp)
    80005862:	e7de                	sd	s7,456(sp)
    80005864:	e3e2                	sd	s8,448(sp)
    80005866:	ff66                	sd	s9,440(sp)
    80005868:	fb6a                	sd	s10,432(sp)
    8000586a:	f76e                	sd	s11,424(sp)
    8000586c:	0c00                	add	s0,sp,528
    8000586e:	892a                	mv	s2,a0
    80005870:	dea43c23          	sd	a0,-520(s0)
    80005874:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005878:	ffffc097          	auipc	ra,0xffffc
    8000587c:	12e080e7          	jalr	302(ra) # 800019a6 <myproc>
    80005880:	84aa                	mv	s1,a0

  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	48e080e7          	jalr	1166(ra) # 80004d10 <begin_op>

  if((ip = namei(path)) == 0){
    8000588a:	854a                	mv	a0,s2
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	284080e7          	jalr	644(ra) # 80004b10 <namei>
    80005894:	c92d                	beqz	a0,80005906 <exec+0xbc>
    80005896:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	ad2080e7          	jalr	-1326(ra) # 8000436a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800058a0:	04000713          	li	a4,64
    800058a4:	4681                	li	a3,0
    800058a6:	e5040613          	add	a2,s0,-432
    800058aa:	4581                	li	a1,0
    800058ac:	8552                	mv	a0,s4
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	d70080e7          	jalr	-656(ra) # 8000461e <readi>
    800058b6:	04000793          	li	a5,64
    800058ba:	00f51a63          	bne	a0,a5,800058ce <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800058be:	e5042703          	lw	a4,-432(s0)
    800058c2:	464c47b7          	lui	a5,0x464c4
    800058c6:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058ca:	04f70463          	beq	a4,a5,80005912 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058ce:	8552                	mv	a0,s4
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	cfc080e7          	jalr	-772(ra) # 800045cc <iunlockput>
    end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	4b2080e7          	jalr	1202(ra) # 80004d8a <end_op>
  }
  return -1;
    800058e0:	557d                	li	a0,-1
}
    800058e2:	20813083          	ld	ra,520(sp)
    800058e6:	20013403          	ld	s0,512(sp)
    800058ea:	74fe                	ld	s1,504(sp)
    800058ec:	795e                	ld	s2,496(sp)
    800058ee:	79be                	ld	s3,488(sp)
    800058f0:	7a1e                	ld	s4,480(sp)
    800058f2:	6afe                	ld	s5,472(sp)
    800058f4:	6b5e                	ld	s6,464(sp)
    800058f6:	6bbe                	ld	s7,456(sp)
    800058f8:	6c1e                	ld	s8,448(sp)
    800058fa:	7cfa                	ld	s9,440(sp)
    800058fc:	7d5a                	ld	s10,432(sp)
    800058fe:	7dba                	ld	s11,424(sp)
    80005900:	21010113          	add	sp,sp,528
    80005904:	8082                	ret
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	484080e7          	jalr	1156(ra) # 80004d8a <end_op>
    return -1;
    8000590e:	557d                	li	a0,-1
    80005910:	bfc9                	j	800058e2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005912:	8526                	mv	a0,s1
    80005914:	ffffc097          	auipc	ra,0xffffc
    80005918:	156080e7          	jalr	342(ra) # 80001a6a <proc_pagetable>
    8000591c:	8b2a                	mv	s6,a0
    8000591e:	d945                	beqz	a0,800058ce <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005920:	e7042d03          	lw	s10,-400(s0)
    80005924:	e8845783          	lhu	a5,-376(s0)
    80005928:	10078463          	beqz	a5,80005a30 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000592c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000592e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005930:	6c85                	lui	s9,0x1
    80005932:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005936:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000593a:	6a85                	lui	s5,0x1
    8000593c:	a0b5                	j	800059a8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000593e:	00003517          	auipc	a0,0x3
    80005942:	e2a50513          	add	a0,a0,-470 # 80008768 <syscalls+0x2c8>
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	bf6080e7          	jalr	-1034(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000594e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005950:	8726                	mv	a4,s1
    80005952:	012c06bb          	addw	a3,s8,s2
    80005956:	4581                	li	a1,0
    80005958:	8552                	mv	a0,s4
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	cc4080e7          	jalr	-828(ra) # 8000461e <readi>
    80005962:	2501                	sext.w	a0,a0
    80005964:	24a49863          	bne	s1,a0,80005bb4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005968:	012a893b          	addw	s2,s5,s2
    8000596c:	03397563          	bgeu	s2,s3,80005996 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005970:	02091593          	sll	a1,s2,0x20
    80005974:	9181                	srl	a1,a1,0x20
    80005976:	95de                	add	a1,a1,s7
    80005978:	855a                	mv	a0,s6
    8000597a:	ffffb097          	auipc	ra,0xffffb
    8000597e:	6dc080e7          	jalr	1756(ra) # 80001056 <walkaddr>
    80005982:	862a                	mv	a2,a0
    if(pa == 0)
    80005984:	dd4d                	beqz	a0,8000593e <exec+0xf4>
    if(sz - i < PGSIZE)
    80005986:	412984bb          	subw	s1,s3,s2
    8000598a:	0004879b          	sext.w	a5,s1
    8000598e:	fcfcf0e3          	bgeu	s9,a5,8000594e <exec+0x104>
    80005992:	84d6                	mv	s1,s5
    80005994:	bf6d                	j	8000594e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005996:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000599a:	2d85                	addw	s11,s11,1
    8000599c:	038d0d1b          	addw	s10,s10,56
    800059a0:	e8845783          	lhu	a5,-376(s0)
    800059a4:	08fdd763          	bge	s11,a5,80005a32 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800059a8:	2d01                	sext.w	s10,s10
    800059aa:	03800713          	li	a4,56
    800059ae:	86ea                	mv	a3,s10
    800059b0:	e1840613          	add	a2,s0,-488
    800059b4:	4581                	li	a1,0
    800059b6:	8552                	mv	a0,s4
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	c66080e7          	jalr	-922(ra) # 8000461e <readi>
    800059c0:	03800793          	li	a5,56
    800059c4:	1ef51663          	bne	a0,a5,80005bb0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800059c8:	e1842783          	lw	a5,-488(s0)
    800059cc:	4705                	li	a4,1
    800059ce:	fce796e3          	bne	a5,a4,8000599a <exec+0x150>
    if(ph.memsz < ph.filesz)
    800059d2:	e4043483          	ld	s1,-448(s0)
    800059d6:	e3843783          	ld	a5,-456(s0)
    800059da:	1ef4e863          	bltu	s1,a5,80005bca <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800059de:	e2843783          	ld	a5,-472(s0)
    800059e2:	94be                	add	s1,s1,a5
    800059e4:	1ef4e663          	bltu	s1,a5,80005bd0 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800059e8:	df043703          	ld	a4,-528(s0)
    800059ec:	8ff9                	and	a5,a5,a4
    800059ee:	1e079463          	bnez	a5,80005bd6 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800059f2:	e1c42503          	lw	a0,-484(s0)
    800059f6:	00000097          	auipc	ra,0x0
    800059fa:	e3a080e7          	jalr	-454(ra) # 80005830 <flags2perm>
    800059fe:	86aa                	mv	a3,a0
    80005a00:	8626                	mv	a2,s1
    80005a02:	85ca                	mv	a1,s2
    80005a04:	855a                	mv	a0,s6
    80005a06:	ffffc097          	auipc	ra,0xffffc
    80005a0a:	a04080e7          	jalr	-1532(ra) # 8000140a <uvmalloc>
    80005a0e:	e0a43423          	sd	a0,-504(s0)
    80005a12:	1c050563          	beqz	a0,80005bdc <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a16:	e2843b83          	ld	s7,-472(s0)
    80005a1a:	e2042c03          	lw	s8,-480(s0)
    80005a1e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005a22:	00098463          	beqz	s3,80005a2a <exec+0x1e0>
    80005a26:	4901                	li	s2,0
    80005a28:	b7a1                	j	80005970 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a2a:	e0843903          	ld	s2,-504(s0)
    80005a2e:	b7b5                	j	8000599a <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005a30:	4901                	li	s2,0
  iunlockput(ip);
    80005a32:	8552                	mv	a0,s4
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	b98080e7          	jalr	-1128(ra) # 800045cc <iunlockput>
  end_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	34e080e7          	jalr	846(ra) # 80004d8a <end_op>
  p = myproc();
    80005a44:	ffffc097          	auipc	ra,0xffffc
    80005a48:	f62080e7          	jalr	-158(ra) # 800019a6 <myproc>
    80005a4c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005a4e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005a52:	6985                	lui	s3,0x1
    80005a54:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005a56:	99ca                	add	s3,s3,s2
    80005a58:	77fd                	lui	a5,0xfffff
    80005a5a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005a5e:	4691                	li	a3,4
    80005a60:	6609                	lui	a2,0x2
    80005a62:	964e                	add	a2,a2,s3
    80005a64:	85ce                	mv	a1,s3
    80005a66:	855a                	mv	a0,s6
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	9a2080e7          	jalr	-1630(ra) # 8000140a <uvmalloc>
    80005a70:	892a                	mv	s2,a0
    80005a72:	e0a43423          	sd	a0,-504(s0)
    80005a76:	e509                	bnez	a0,80005a80 <exec+0x236>
  if(pagetable)
    80005a78:	e1343423          	sd	s3,-504(s0)
    80005a7c:	4a01                	li	s4,0
    80005a7e:	aa1d                	j	80005bb4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a80:	75f9                	lui	a1,0xffffe
    80005a82:	95aa                	add	a1,a1,a0
    80005a84:	855a                	mv	a0,s6
    80005a86:	ffffc097          	auipc	ra,0xffffc
    80005a8a:	bae080e7          	jalr	-1106(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a8e:	7bfd                	lui	s7,0xfffff
    80005a90:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005a92:	e0043783          	ld	a5,-512(s0)
    80005a96:	6388                	ld	a0,0(a5)
    80005a98:	c52d                	beqz	a0,80005b02 <exec+0x2b8>
    80005a9a:	e9040993          	add	s3,s0,-368
    80005a9e:	f9040c13          	add	s8,s0,-112
    80005aa2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	3a4080e7          	jalr	932(ra) # 80000e48 <strlen>
    80005aac:	0015079b          	addw	a5,a0,1
    80005ab0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005ab4:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005ab8:	13796563          	bltu	s2,s7,80005be2 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005abc:	e0043d03          	ld	s10,-512(s0)
    80005ac0:	000d3a03          	ld	s4,0(s10)
    80005ac4:	8552                	mv	a0,s4
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	382080e7          	jalr	898(ra) # 80000e48 <strlen>
    80005ace:	0015069b          	addw	a3,a0,1
    80005ad2:	8652                	mv	a2,s4
    80005ad4:	85ca                	mv	a1,s2
    80005ad6:	855a                	mv	a0,s6
    80005ad8:	ffffc097          	auipc	ra,0xffffc
    80005adc:	b8e080e7          	jalr	-1138(ra) # 80001666 <copyout>
    80005ae0:	10054363          	bltz	a0,80005be6 <exec+0x39c>
    ustack[argc] = sp;
    80005ae4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005ae8:	0485                	add	s1,s1,1
    80005aea:	008d0793          	add	a5,s10,8
    80005aee:	e0f43023          	sd	a5,-512(s0)
    80005af2:	008d3503          	ld	a0,8(s10)
    80005af6:	c909                	beqz	a0,80005b08 <exec+0x2be>
    if(argc >= MAXARG)
    80005af8:	09a1                	add	s3,s3,8
    80005afa:	fb8995e3          	bne	s3,s8,80005aa4 <exec+0x25a>
  ip = 0;
    80005afe:	4a01                	li	s4,0
    80005b00:	a855                	j	80005bb4 <exec+0x36a>
  sp = sz;
    80005b02:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005b06:	4481                	li	s1,0
  ustack[argc] = 0;
    80005b08:	00349793          	sll	a5,s1,0x3
    80005b0c:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8fe0>
    80005b10:	97a2                	add	a5,a5,s0
    80005b12:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005b16:	00148693          	add	a3,s1,1
    80005b1a:	068e                	sll	a3,a3,0x3
    80005b1c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005b20:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005b24:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005b28:	f57968e3          	bltu	s2,s7,80005a78 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b2c:	e9040613          	add	a2,s0,-368
    80005b30:	85ca                	mv	a1,s2
    80005b32:	855a                	mv	a0,s6
    80005b34:	ffffc097          	auipc	ra,0xffffc
    80005b38:	b32080e7          	jalr	-1230(ra) # 80001666 <copyout>
    80005b3c:	0a054763          	bltz	a0,80005bea <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005b40:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005b44:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b48:	df843783          	ld	a5,-520(s0)
    80005b4c:	0007c703          	lbu	a4,0(a5)
    80005b50:	cf11                	beqz	a4,80005b6c <exec+0x322>
    80005b52:	0785                	add	a5,a5,1
    if(*s == '/')
    80005b54:	02f00693          	li	a3,47
    80005b58:	a039                	j	80005b66 <exec+0x31c>
      last = s+1;
    80005b5a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005b5e:	0785                	add	a5,a5,1
    80005b60:	fff7c703          	lbu	a4,-1(a5)
    80005b64:	c701                	beqz	a4,80005b6c <exec+0x322>
    if(*s == '/')
    80005b66:	fed71ce3          	bne	a4,a3,80005b5e <exec+0x314>
    80005b6a:	bfc5                	j	80005b5a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b6c:	4641                	li	a2,16
    80005b6e:	df843583          	ld	a1,-520(s0)
    80005b72:	158a8513          	add	a0,s5,344
    80005b76:	ffffb097          	auipc	ra,0xffffb
    80005b7a:	2a0080e7          	jalr	672(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b7e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005b82:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005b86:	e0843783          	ld	a5,-504(s0)
    80005b8a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b8e:	058ab783          	ld	a5,88(s5)
    80005b92:	e6843703          	ld	a4,-408(s0)
    80005b96:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b98:	058ab783          	ld	a5,88(s5)
    80005b9c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ba0:	85e6                	mv	a1,s9
    80005ba2:	ffffc097          	auipc	ra,0xffffc
    80005ba6:	f64080e7          	jalr	-156(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005baa:	0004851b          	sext.w	a0,s1
    80005bae:	bb15                	j	800058e2 <exec+0x98>
    80005bb0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005bb4:	e0843583          	ld	a1,-504(s0)
    80005bb8:	855a                	mv	a0,s6
    80005bba:	ffffc097          	auipc	ra,0xffffc
    80005bbe:	f4c080e7          	jalr	-180(ra) # 80001b06 <proc_freepagetable>
  return -1;
    80005bc2:	557d                	li	a0,-1
  if(ip){
    80005bc4:	d00a0fe3          	beqz	s4,800058e2 <exec+0x98>
    80005bc8:	b319                	j	800058ce <exec+0x84>
    80005bca:	e1243423          	sd	s2,-504(s0)
    80005bce:	b7dd                	j	80005bb4 <exec+0x36a>
    80005bd0:	e1243423          	sd	s2,-504(s0)
    80005bd4:	b7c5                	j	80005bb4 <exec+0x36a>
    80005bd6:	e1243423          	sd	s2,-504(s0)
    80005bda:	bfe9                	j	80005bb4 <exec+0x36a>
    80005bdc:	e1243423          	sd	s2,-504(s0)
    80005be0:	bfd1                	j	80005bb4 <exec+0x36a>
  ip = 0;
    80005be2:	4a01                	li	s4,0
    80005be4:	bfc1                	j	80005bb4 <exec+0x36a>
    80005be6:	4a01                	li	s4,0
  if(pagetable)
    80005be8:	b7f1                	j	80005bb4 <exec+0x36a>
  sz = sz1;
    80005bea:	e0843983          	ld	s3,-504(s0)
    80005bee:	b569                	j	80005a78 <exec+0x22e>

0000000080005bf0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005bf0:	7179                	add	sp,sp,-48
    80005bf2:	f406                	sd	ra,40(sp)
    80005bf4:	f022                	sd	s0,32(sp)
    80005bf6:	ec26                	sd	s1,24(sp)
    80005bf8:	e84a                	sd	s2,16(sp)
    80005bfa:	1800                	add	s0,sp,48
    80005bfc:	892e                	mv	s2,a1
    80005bfe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005c00:	fdc40593          	add	a1,s0,-36
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	a16080e7          	jalr	-1514(ra) # 8000361a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c0c:	fdc42703          	lw	a4,-36(s0)
    80005c10:	47bd                	li	a5,15
    80005c12:	02e7eb63          	bltu	a5,a4,80005c48 <argfd+0x58>
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	d90080e7          	jalr	-624(ra) # 800019a6 <myproc>
    80005c1e:	fdc42703          	lw	a4,-36(s0)
    80005c22:	01a70793          	add	a5,a4,26
    80005c26:	078e                	sll	a5,a5,0x3
    80005c28:	953e                	add	a0,a0,a5
    80005c2a:	611c                	ld	a5,0(a0)
    80005c2c:	c385                	beqz	a5,80005c4c <argfd+0x5c>
    return -1;
  if(pfd)
    80005c2e:	00090463          	beqz	s2,80005c36 <argfd+0x46>
    *pfd = fd;
    80005c32:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c36:	4501                	li	a0,0
  if(pf)
    80005c38:	c091                	beqz	s1,80005c3c <argfd+0x4c>
    *pf = f;
    80005c3a:	e09c                	sd	a5,0(s1)
}
    80005c3c:	70a2                	ld	ra,40(sp)
    80005c3e:	7402                	ld	s0,32(sp)
    80005c40:	64e2                	ld	s1,24(sp)
    80005c42:	6942                	ld	s2,16(sp)
    80005c44:	6145                	add	sp,sp,48
    80005c46:	8082                	ret
    return -1;
    80005c48:	557d                	li	a0,-1
    80005c4a:	bfcd                	j	80005c3c <argfd+0x4c>
    80005c4c:	557d                	li	a0,-1
    80005c4e:	b7fd                	j	80005c3c <argfd+0x4c>

0000000080005c50 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c50:	1101                	add	sp,sp,-32
    80005c52:	ec06                	sd	ra,24(sp)
    80005c54:	e822                	sd	s0,16(sp)
    80005c56:	e426                	sd	s1,8(sp)
    80005c58:	1000                	add	s0,sp,32
    80005c5a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c5c:	ffffc097          	auipc	ra,0xffffc
    80005c60:	d4a080e7          	jalr	-694(ra) # 800019a6 <myproc>
    80005c64:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c66:	0d050793          	add	a5,a0,208
    80005c6a:	4501                	li	a0,0
    80005c6c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c6e:	6398                	ld	a4,0(a5)
    80005c70:	cb19                	beqz	a4,80005c86 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c72:	2505                	addw	a0,a0,1
    80005c74:	07a1                	add	a5,a5,8
    80005c76:	fed51ce3          	bne	a0,a3,80005c6e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c7a:	557d                	li	a0,-1
}
    80005c7c:	60e2                	ld	ra,24(sp)
    80005c7e:	6442                	ld	s0,16(sp)
    80005c80:	64a2                	ld	s1,8(sp)
    80005c82:	6105                	add	sp,sp,32
    80005c84:	8082                	ret
      p->ofile[fd] = f;
    80005c86:	01a50793          	add	a5,a0,26
    80005c8a:	078e                	sll	a5,a5,0x3
    80005c8c:	963e                	add	a2,a2,a5
    80005c8e:	e204                	sd	s1,0(a2)
      return fd;
    80005c90:	b7f5                	j	80005c7c <fdalloc+0x2c>

0000000080005c92 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c92:	715d                	add	sp,sp,-80
    80005c94:	e486                	sd	ra,72(sp)
    80005c96:	e0a2                	sd	s0,64(sp)
    80005c98:	fc26                	sd	s1,56(sp)
    80005c9a:	f84a                	sd	s2,48(sp)
    80005c9c:	f44e                	sd	s3,40(sp)
    80005c9e:	f052                	sd	s4,32(sp)
    80005ca0:	ec56                	sd	s5,24(sp)
    80005ca2:	e85a                	sd	s6,16(sp)
    80005ca4:	0880                	add	s0,sp,80
    80005ca6:	8b2e                	mv	s6,a1
    80005ca8:	89b2                	mv	s3,a2
    80005caa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005cac:	fb040593          	add	a1,s0,-80
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	e7e080e7          	jalr	-386(ra) # 80004b2e <nameiparent>
    80005cb8:	84aa                	mv	s1,a0
    80005cba:	14050b63          	beqz	a0,80005e10 <create+0x17e>
    return 0;

  ilock(dp);
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	6ac080e7          	jalr	1708(ra) # 8000436a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005cc6:	4601                	li	a2,0
    80005cc8:	fb040593          	add	a1,s0,-80
    80005ccc:	8526                	mv	a0,s1
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	b80080e7          	jalr	-1152(ra) # 8000484e <dirlookup>
    80005cd6:	8aaa                	mv	s5,a0
    80005cd8:	c921                	beqz	a0,80005d28 <create+0x96>
    iunlockput(dp);
    80005cda:	8526                	mv	a0,s1
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	8f0080e7          	jalr	-1808(ra) # 800045cc <iunlockput>
    ilock(ip);
    80005ce4:	8556                	mv	a0,s5
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	684080e7          	jalr	1668(ra) # 8000436a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005cee:	4789                	li	a5,2
    80005cf0:	02fb1563          	bne	s6,a5,80005d1a <create+0x88>
    80005cf4:	044ad783          	lhu	a5,68(s5)
    80005cf8:	37f9                	addw	a5,a5,-2
    80005cfa:	17c2                	sll	a5,a5,0x30
    80005cfc:	93c1                	srl	a5,a5,0x30
    80005cfe:	4705                	li	a4,1
    80005d00:	00f76d63          	bltu	a4,a5,80005d1a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005d04:	8556                	mv	a0,s5
    80005d06:	60a6                	ld	ra,72(sp)
    80005d08:	6406                	ld	s0,64(sp)
    80005d0a:	74e2                	ld	s1,56(sp)
    80005d0c:	7942                	ld	s2,48(sp)
    80005d0e:	79a2                	ld	s3,40(sp)
    80005d10:	7a02                	ld	s4,32(sp)
    80005d12:	6ae2                	ld	s5,24(sp)
    80005d14:	6b42                	ld	s6,16(sp)
    80005d16:	6161                	add	sp,sp,80
    80005d18:	8082                	ret
    iunlockput(ip);
    80005d1a:	8556                	mv	a0,s5
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	8b0080e7          	jalr	-1872(ra) # 800045cc <iunlockput>
    return 0;
    80005d24:	4a81                	li	s5,0
    80005d26:	bff9                	j	80005d04 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005d28:	85da                	mv	a1,s6
    80005d2a:	4088                	lw	a0,0(s1)
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	4a6080e7          	jalr	1190(ra) # 800041d2 <ialloc>
    80005d34:	8a2a                	mv	s4,a0
    80005d36:	c529                	beqz	a0,80005d80 <create+0xee>
  ilock(ip);
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	632080e7          	jalr	1586(ra) # 8000436a <ilock>
  ip->major = major;
    80005d40:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005d44:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005d48:	4905                	li	s2,1
    80005d4a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005d4e:	8552                	mv	a0,s4
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	54e080e7          	jalr	1358(ra) # 8000429e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d58:	032b0b63          	beq	s6,s2,80005d8e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d5c:	004a2603          	lw	a2,4(s4)
    80005d60:	fb040593          	add	a1,s0,-80
    80005d64:	8526                	mv	a0,s1
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	cf8080e7          	jalr	-776(ra) # 80004a5e <dirlink>
    80005d6e:	06054f63          	bltz	a0,80005dec <create+0x15a>
  iunlockput(dp);
    80005d72:	8526                	mv	a0,s1
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	858080e7          	jalr	-1960(ra) # 800045cc <iunlockput>
  return ip;
    80005d7c:	8ad2                	mv	s5,s4
    80005d7e:	b759                	j	80005d04 <create+0x72>
    iunlockput(dp);
    80005d80:	8526                	mv	a0,s1
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	84a080e7          	jalr	-1974(ra) # 800045cc <iunlockput>
    return 0;
    80005d8a:	8ad2                	mv	s5,s4
    80005d8c:	bfa5                	j	80005d04 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d8e:	004a2603          	lw	a2,4(s4)
    80005d92:	00003597          	auipc	a1,0x3
    80005d96:	9f658593          	add	a1,a1,-1546 # 80008788 <syscalls+0x2e8>
    80005d9a:	8552                	mv	a0,s4
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	cc2080e7          	jalr	-830(ra) # 80004a5e <dirlink>
    80005da4:	04054463          	bltz	a0,80005dec <create+0x15a>
    80005da8:	40d0                	lw	a2,4(s1)
    80005daa:	00003597          	auipc	a1,0x3
    80005dae:	9e658593          	add	a1,a1,-1562 # 80008790 <syscalls+0x2f0>
    80005db2:	8552                	mv	a0,s4
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	caa080e7          	jalr	-854(ra) # 80004a5e <dirlink>
    80005dbc:	02054863          	bltz	a0,80005dec <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dc0:	004a2603          	lw	a2,4(s4)
    80005dc4:	fb040593          	add	a1,s0,-80
    80005dc8:	8526                	mv	a0,s1
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	c94080e7          	jalr	-876(ra) # 80004a5e <dirlink>
    80005dd2:	00054d63          	bltz	a0,80005dec <create+0x15a>
    dp->nlink++;  // for ".."
    80005dd6:	04a4d783          	lhu	a5,74(s1)
    80005dda:	2785                	addw	a5,a5,1
    80005ddc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	4bc080e7          	jalr	1212(ra) # 8000429e <iupdate>
    80005dea:	b761                	j	80005d72 <create+0xe0>
  ip->nlink = 0;
    80005dec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005df0:	8552                	mv	a0,s4
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	4ac080e7          	jalr	1196(ra) # 8000429e <iupdate>
  iunlockput(ip);
    80005dfa:	8552                	mv	a0,s4
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	7d0080e7          	jalr	2000(ra) # 800045cc <iunlockput>
  iunlockput(dp);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	7c6080e7          	jalr	1990(ra) # 800045cc <iunlockput>
  return 0;
    80005e0e:	bddd                	j	80005d04 <create+0x72>
    return 0;
    80005e10:	8aaa                	mv	s5,a0
    80005e12:	bdcd                	j	80005d04 <create+0x72>

0000000080005e14 <sys_dup>:
{
    80005e14:	7179                	add	sp,sp,-48
    80005e16:	f406                	sd	ra,40(sp)
    80005e18:	f022                	sd	s0,32(sp)
    80005e1a:	ec26                	sd	s1,24(sp)
    80005e1c:	e84a                	sd	s2,16(sp)
    80005e1e:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e20:	fd840613          	add	a2,s0,-40
    80005e24:	4581                	li	a1,0
    80005e26:	4501                	li	a0,0
    80005e28:	00000097          	auipc	ra,0x0
    80005e2c:	dc8080e7          	jalr	-568(ra) # 80005bf0 <argfd>
    return -1;
    80005e30:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e32:	02054363          	bltz	a0,80005e58 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005e36:	fd843903          	ld	s2,-40(s0)
    80005e3a:	854a                	mv	a0,s2
    80005e3c:	00000097          	auipc	ra,0x0
    80005e40:	e14080e7          	jalr	-492(ra) # 80005c50 <fdalloc>
    80005e44:	84aa                	mv	s1,a0
    return -1;
    80005e46:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e48:	00054863          	bltz	a0,80005e58 <sys_dup+0x44>
  filedup(f);
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	334080e7          	jalr	820(ra) # 80005182 <filedup>
  return fd;
    80005e56:	87a6                	mv	a5,s1
}
    80005e58:	853e                	mv	a0,a5
    80005e5a:	70a2                	ld	ra,40(sp)
    80005e5c:	7402                	ld	s0,32(sp)
    80005e5e:	64e2                	ld	s1,24(sp)
    80005e60:	6942                	ld	s2,16(sp)
    80005e62:	6145                	add	sp,sp,48
    80005e64:	8082                	ret

0000000080005e66 <sys_read>:
{
    80005e66:	7179                	add	sp,sp,-48
    80005e68:	f406                	sd	ra,40(sp)
    80005e6a:	f022                	sd	s0,32(sp)
    80005e6c:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005e6e:	fd840593          	add	a1,s0,-40
    80005e72:	4505                	li	a0,1
    80005e74:	ffffd097          	auipc	ra,0xffffd
    80005e78:	7c6080e7          	jalr	1990(ra) # 8000363a <argaddr>
  argint(2, &n);
    80005e7c:	fe440593          	add	a1,s0,-28
    80005e80:	4509                	li	a0,2
    80005e82:	ffffd097          	auipc	ra,0xffffd
    80005e86:	798080e7          	jalr	1944(ra) # 8000361a <argint>
  if(argfd(0, 0, &f) < 0)
    80005e8a:	fe840613          	add	a2,s0,-24
    80005e8e:	4581                	li	a1,0
    80005e90:	4501                	li	a0,0
    80005e92:	00000097          	auipc	ra,0x0
    80005e96:	d5e080e7          	jalr	-674(ra) # 80005bf0 <argfd>
    80005e9a:	87aa                	mv	a5,a0
    return -1;
    80005e9c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e9e:	0007cc63          	bltz	a5,80005eb6 <sys_read+0x50>
  return fileread(f, p, n);
    80005ea2:	fe442603          	lw	a2,-28(s0)
    80005ea6:	fd843583          	ld	a1,-40(s0)
    80005eaa:	fe843503          	ld	a0,-24(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	460080e7          	jalr	1120(ra) # 8000530e <fileread>
}
    80005eb6:	70a2                	ld	ra,40(sp)
    80005eb8:	7402                	ld	s0,32(sp)
    80005eba:	6145                	add	sp,sp,48
    80005ebc:	8082                	ret

0000000080005ebe <sys_write>:
{
    80005ebe:	7179                	add	sp,sp,-48
    80005ec0:	f406                	sd	ra,40(sp)
    80005ec2:	f022                	sd	s0,32(sp)
    80005ec4:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005ec6:	fd840593          	add	a1,s0,-40
    80005eca:	4505                	li	a0,1
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	76e080e7          	jalr	1902(ra) # 8000363a <argaddr>
  argint(2, &n);
    80005ed4:	fe440593          	add	a1,s0,-28
    80005ed8:	4509                	li	a0,2
    80005eda:	ffffd097          	auipc	ra,0xffffd
    80005ede:	740080e7          	jalr	1856(ra) # 8000361a <argint>
  if(argfd(0, 0, &f) < 0)
    80005ee2:	fe840613          	add	a2,s0,-24
    80005ee6:	4581                	li	a1,0
    80005ee8:	4501                	li	a0,0
    80005eea:	00000097          	auipc	ra,0x0
    80005eee:	d06080e7          	jalr	-762(ra) # 80005bf0 <argfd>
    80005ef2:	87aa                	mv	a5,a0
    return -1;
    80005ef4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ef6:	0007cc63          	bltz	a5,80005f0e <sys_write+0x50>
  return filewrite(f, p, n);
    80005efa:	fe442603          	lw	a2,-28(s0)
    80005efe:	fd843583          	ld	a1,-40(s0)
    80005f02:	fe843503          	ld	a0,-24(s0)
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	4ca080e7          	jalr	1226(ra) # 800053d0 <filewrite>
}
    80005f0e:	70a2                	ld	ra,40(sp)
    80005f10:	7402                	ld	s0,32(sp)
    80005f12:	6145                	add	sp,sp,48
    80005f14:	8082                	ret

0000000080005f16 <sys_close>:
{
    80005f16:	1101                	add	sp,sp,-32
    80005f18:	ec06                	sd	ra,24(sp)
    80005f1a:	e822                	sd	s0,16(sp)
    80005f1c:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f1e:	fe040613          	add	a2,s0,-32
    80005f22:	fec40593          	add	a1,s0,-20
    80005f26:	4501                	li	a0,0
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	cc8080e7          	jalr	-824(ra) # 80005bf0 <argfd>
    return -1;
    80005f30:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f32:	02054463          	bltz	a0,80005f5a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f36:	ffffc097          	auipc	ra,0xffffc
    80005f3a:	a70080e7          	jalr	-1424(ra) # 800019a6 <myproc>
    80005f3e:	fec42783          	lw	a5,-20(s0)
    80005f42:	07e9                	add	a5,a5,26
    80005f44:	078e                	sll	a5,a5,0x3
    80005f46:	953e                	add	a0,a0,a5
    80005f48:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005f4c:	fe043503          	ld	a0,-32(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	284080e7          	jalr	644(ra) # 800051d4 <fileclose>
  return 0;
    80005f58:	4781                	li	a5,0
}
    80005f5a:	853e                	mv	a0,a5
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	6105                	add	sp,sp,32
    80005f62:	8082                	ret

0000000080005f64 <sys_fstat>:
{
    80005f64:	1101                	add	sp,sp,-32
    80005f66:	ec06                	sd	ra,24(sp)
    80005f68:	e822                	sd	s0,16(sp)
    80005f6a:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005f6c:	fe040593          	add	a1,s0,-32
    80005f70:	4505                	li	a0,1
    80005f72:	ffffd097          	auipc	ra,0xffffd
    80005f76:	6c8080e7          	jalr	1736(ra) # 8000363a <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005f7a:	fe840613          	add	a2,s0,-24
    80005f7e:	4581                	li	a1,0
    80005f80:	4501                	li	a0,0
    80005f82:	00000097          	auipc	ra,0x0
    80005f86:	c6e080e7          	jalr	-914(ra) # 80005bf0 <argfd>
    80005f8a:	87aa                	mv	a5,a0
    return -1;
    80005f8c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f8e:	0007ca63          	bltz	a5,80005fa2 <sys_fstat+0x3e>
  return filestat(f, st);
    80005f92:	fe043583          	ld	a1,-32(s0)
    80005f96:	fe843503          	ld	a0,-24(s0)
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	302080e7          	jalr	770(ra) # 8000529c <filestat>
}
    80005fa2:	60e2                	ld	ra,24(sp)
    80005fa4:	6442                	ld	s0,16(sp)
    80005fa6:	6105                	add	sp,sp,32
    80005fa8:	8082                	ret

0000000080005faa <sys_link>:
{
    80005faa:	7169                	add	sp,sp,-304
    80005fac:	f606                	sd	ra,296(sp)
    80005fae:	f222                	sd	s0,288(sp)
    80005fb0:	ee26                	sd	s1,280(sp)
    80005fb2:	ea4a                	sd	s2,272(sp)
    80005fb4:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fb6:	08000613          	li	a2,128
    80005fba:	ed040593          	add	a1,s0,-304
    80005fbe:	4501                	li	a0,0
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	69a080e7          	jalr	1690(ra) # 8000365a <argstr>
    return -1;
    80005fc8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fca:	10054e63          	bltz	a0,800060e6 <sys_link+0x13c>
    80005fce:	08000613          	li	a2,128
    80005fd2:	f5040593          	add	a1,s0,-176
    80005fd6:	4505                	li	a0,1
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	682080e7          	jalr	1666(ra) # 8000365a <argstr>
    return -1;
    80005fe0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fe2:	10054263          	bltz	a0,800060e6 <sys_link+0x13c>
  begin_op();
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	d2a080e7          	jalr	-726(ra) # 80004d10 <begin_op>
  if((ip = namei(old)) == 0){
    80005fee:	ed040513          	add	a0,s0,-304
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	b1e080e7          	jalr	-1250(ra) # 80004b10 <namei>
    80005ffa:	84aa                	mv	s1,a0
    80005ffc:	c551                	beqz	a0,80006088 <sys_link+0xde>
  ilock(ip);
    80005ffe:	ffffe097          	auipc	ra,0xffffe
    80006002:	36c080e7          	jalr	876(ra) # 8000436a <ilock>
  if(ip->type == T_DIR){
    80006006:	04449703          	lh	a4,68(s1)
    8000600a:	4785                	li	a5,1
    8000600c:	08f70463          	beq	a4,a5,80006094 <sys_link+0xea>
  ip->nlink++;
    80006010:	04a4d783          	lhu	a5,74(s1)
    80006014:	2785                	addw	a5,a5,1
    80006016:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000601a:	8526                	mv	a0,s1
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	282080e7          	jalr	642(ra) # 8000429e <iupdate>
  iunlock(ip);
    80006024:	8526                	mv	a0,s1
    80006026:	ffffe097          	auipc	ra,0xffffe
    8000602a:	406080e7          	jalr	1030(ra) # 8000442c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000602e:	fd040593          	add	a1,s0,-48
    80006032:	f5040513          	add	a0,s0,-176
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	af8080e7          	jalr	-1288(ra) # 80004b2e <nameiparent>
    8000603e:	892a                	mv	s2,a0
    80006040:	c935                	beqz	a0,800060b4 <sys_link+0x10a>
  ilock(dp);
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	328080e7          	jalr	808(ra) # 8000436a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000604a:	00092703          	lw	a4,0(s2)
    8000604e:	409c                	lw	a5,0(s1)
    80006050:	04f71d63          	bne	a4,a5,800060aa <sys_link+0x100>
    80006054:	40d0                	lw	a2,4(s1)
    80006056:	fd040593          	add	a1,s0,-48
    8000605a:	854a                	mv	a0,s2
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	a02080e7          	jalr	-1534(ra) # 80004a5e <dirlink>
    80006064:	04054363          	bltz	a0,800060aa <sys_link+0x100>
  iunlockput(dp);
    80006068:	854a                	mv	a0,s2
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	562080e7          	jalr	1378(ra) # 800045cc <iunlockput>
  iput(ip);
    80006072:	8526                	mv	a0,s1
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	4b0080e7          	jalr	1200(ra) # 80004524 <iput>
  end_op();
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	d0e080e7          	jalr	-754(ra) # 80004d8a <end_op>
  return 0;
    80006084:	4781                	li	a5,0
    80006086:	a085                	j	800060e6 <sys_link+0x13c>
    end_op();
    80006088:	fffff097          	auipc	ra,0xfffff
    8000608c:	d02080e7          	jalr	-766(ra) # 80004d8a <end_op>
    return -1;
    80006090:	57fd                	li	a5,-1
    80006092:	a891                	j	800060e6 <sys_link+0x13c>
    iunlockput(ip);
    80006094:	8526                	mv	a0,s1
    80006096:	ffffe097          	auipc	ra,0xffffe
    8000609a:	536080e7          	jalr	1334(ra) # 800045cc <iunlockput>
    end_op();
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	cec080e7          	jalr	-788(ra) # 80004d8a <end_op>
    return -1;
    800060a6:	57fd                	li	a5,-1
    800060a8:	a83d                	j	800060e6 <sys_link+0x13c>
    iunlockput(dp);
    800060aa:	854a                	mv	a0,s2
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	520080e7          	jalr	1312(ra) # 800045cc <iunlockput>
  ilock(ip);
    800060b4:	8526                	mv	a0,s1
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	2b4080e7          	jalr	692(ra) # 8000436a <ilock>
  ip->nlink--;
    800060be:	04a4d783          	lhu	a5,74(s1)
    800060c2:	37fd                	addw	a5,a5,-1
    800060c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060c8:	8526                	mv	a0,s1
    800060ca:	ffffe097          	auipc	ra,0xffffe
    800060ce:	1d4080e7          	jalr	468(ra) # 8000429e <iupdate>
  iunlockput(ip);
    800060d2:	8526                	mv	a0,s1
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	4f8080e7          	jalr	1272(ra) # 800045cc <iunlockput>
  end_op();
    800060dc:	fffff097          	auipc	ra,0xfffff
    800060e0:	cae080e7          	jalr	-850(ra) # 80004d8a <end_op>
  return -1;
    800060e4:	57fd                	li	a5,-1
}
    800060e6:	853e                	mv	a0,a5
    800060e8:	70b2                	ld	ra,296(sp)
    800060ea:	7412                	ld	s0,288(sp)
    800060ec:	64f2                	ld	s1,280(sp)
    800060ee:	6952                	ld	s2,272(sp)
    800060f0:	6155                	add	sp,sp,304
    800060f2:	8082                	ret

00000000800060f4 <sys_unlink>:
{
    800060f4:	7151                	add	sp,sp,-240
    800060f6:	f586                	sd	ra,232(sp)
    800060f8:	f1a2                	sd	s0,224(sp)
    800060fa:	eda6                	sd	s1,216(sp)
    800060fc:	e9ca                	sd	s2,208(sp)
    800060fe:	e5ce                	sd	s3,200(sp)
    80006100:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006102:	08000613          	li	a2,128
    80006106:	f3040593          	add	a1,s0,-208
    8000610a:	4501                	li	a0,0
    8000610c:	ffffd097          	auipc	ra,0xffffd
    80006110:	54e080e7          	jalr	1358(ra) # 8000365a <argstr>
    80006114:	18054163          	bltz	a0,80006296 <sys_unlink+0x1a2>
  begin_op();
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	bf8080e7          	jalr	-1032(ra) # 80004d10 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006120:	fb040593          	add	a1,s0,-80
    80006124:	f3040513          	add	a0,s0,-208
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	a06080e7          	jalr	-1530(ra) # 80004b2e <nameiparent>
    80006130:	84aa                	mv	s1,a0
    80006132:	c979                	beqz	a0,80006208 <sys_unlink+0x114>
  ilock(dp);
    80006134:	ffffe097          	auipc	ra,0xffffe
    80006138:	236080e7          	jalr	566(ra) # 8000436a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000613c:	00002597          	auipc	a1,0x2
    80006140:	64c58593          	add	a1,a1,1612 # 80008788 <syscalls+0x2e8>
    80006144:	fb040513          	add	a0,s0,-80
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	6ec080e7          	jalr	1772(ra) # 80004834 <namecmp>
    80006150:	14050a63          	beqz	a0,800062a4 <sys_unlink+0x1b0>
    80006154:	00002597          	auipc	a1,0x2
    80006158:	63c58593          	add	a1,a1,1596 # 80008790 <syscalls+0x2f0>
    8000615c:	fb040513          	add	a0,s0,-80
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	6d4080e7          	jalr	1748(ra) # 80004834 <namecmp>
    80006168:	12050e63          	beqz	a0,800062a4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000616c:	f2c40613          	add	a2,s0,-212
    80006170:	fb040593          	add	a1,s0,-80
    80006174:	8526                	mv	a0,s1
    80006176:	ffffe097          	auipc	ra,0xffffe
    8000617a:	6d8080e7          	jalr	1752(ra) # 8000484e <dirlookup>
    8000617e:	892a                	mv	s2,a0
    80006180:	12050263          	beqz	a0,800062a4 <sys_unlink+0x1b0>
  ilock(ip);
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	1e6080e7          	jalr	486(ra) # 8000436a <ilock>
  if(ip->nlink < 1)
    8000618c:	04a91783          	lh	a5,74(s2)
    80006190:	08f05263          	blez	a5,80006214 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006194:	04491703          	lh	a4,68(s2)
    80006198:	4785                	li	a5,1
    8000619a:	08f70563          	beq	a4,a5,80006224 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000619e:	4641                	li	a2,16
    800061a0:	4581                	li	a1,0
    800061a2:	fc040513          	add	a0,s0,-64
    800061a6:	ffffb097          	auipc	ra,0xffffb
    800061aa:	b28080e7          	jalr	-1240(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061ae:	4741                	li	a4,16
    800061b0:	f2c42683          	lw	a3,-212(s0)
    800061b4:	fc040613          	add	a2,s0,-64
    800061b8:	4581                	li	a1,0
    800061ba:	8526                	mv	a0,s1
    800061bc:	ffffe097          	auipc	ra,0xffffe
    800061c0:	55a080e7          	jalr	1370(ra) # 80004716 <writei>
    800061c4:	47c1                	li	a5,16
    800061c6:	0af51563          	bne	a0,a5,80006270 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800061ca:	04491703          	lh	a4,68(s2)
    800061ce:	4785                	li	a5,1
    800061d0:	0af70863          	beq	a4,a5,80006280 <sys_unlink+0x18c>
  iunlockput(dp);
    800061d4:	8526                	mv	a0,s1
    800061d6:	ffffe097          	auipc	ra,0xffffe
    800061da:	3f6080e7          	jalr	1014(ra) # 800045cc <iunlockput>
  ip->nlink--;
    800061de:	04a95783          	lhu	a5,74(s2)
    800061e2:	37fd                	addw	a5,a5,-1
    800061e4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800061e8:	854a                	mv	a0,s2
    800061ea:	ffffe097          	auipc	ra,0xffffe
    800061ee:	0b4080e7          	jalr	180(ra) # 8000429e <iupdate>
  iunlockput(ip);
    800061f2:	854a                	mv	a0,s2
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	3d8080e7          	jalr	984(ra) # 800045cc <iunlockput>
  end_op();
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	b8e080e7          	jalr	-1138(ra) # 80004d8a <end_op>
  return 0;
    80006204:	4501                	li	a0,0
    80006206:	a84d                	j	800062b8 <sys_unlink+0x1c4>
    end_op();
    80006208:	fffff097          	auipc	ra,0xfffff
    8000620c:	b82080e7          	jalr	-1150(ra) # 80004d8a <end_op>
    return -1;
    80006210:	557d                	li	a0,-1
    80006212:	a05d                	j	800062b8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006214:	00002517          	auipc	a0,0x2
    80006218:	58450513          	add	a0,a0,1412 # 80008798 <syscalls+0x2f8>
    8000621c:	ffffa097          	auipc	ra,0xffffa
    80006220:	320080e7          	jalr	800(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006224:	04c92703          	lw	a4,76(s2)
    80006228:	02000793          	li	a5,32
    8000622c:	f6e7f9e3          	bgeu	a5,a4,8000619e <sys_unlink+0xaa>
    80006230:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006234:	4741                	li	a4,16
    80006236:	86ce                	mv	a3,s3
    80006238:	f1840613          	add	a2,s0,-232
    8000623c:	4581                	li	a1,0
    8000623e:	854a                	mv	a0,s2
    80006240:	ffffe097          	auipc	ra,0xffffe
    80006244:	3de080e7          	jalr	990(ra) # 8000461e <readi>
    80006248:	47c1                	li	a5,16
    8000624a:	00f51b63          	bne	a0,a5,80006260 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000624e:	f1845783          	lhu	a5,-232(s0)
    80006252:	e7a1                	bnez	a5,8000629a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006254:	29c1                	addw	s3,s3,16
    80006256:	04c92783          	lw	a5,76(s2)
    8000625a:	fcf9ede3          	bltu	s3,a5,80006234 <sys_unlink+0x140>
    8000625e:	b781                	j	8000619e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006260:	00002517          	auipc	a0,0x2
    80006264:	55050513          	add	a0,a0,1360 # 800087b0 <syscalls+0x310>
    80006268:	ffffa097          	auipc	ra,0xffffa
    8000626c:	2d4080e7          	jalr	724(ra) # 8000053c <panic>
    panic("unlink: writei");
    80006270:	00002517          	auipc	a0,0x2
    80006274:	55850513          	add	a0,a0,1368 # 800087c8 <syscalls+0x328>
    80006278:	ffffa097          	auipc	ra,0xffffa
    8000627c:	2c4080e7          	jalr	708(ra) # 8000053c <panic>
    dp->nlink--;
    80006280:	04a4d783          	lhu	a5,74(s1)
    80006284:	37fd                	addw	a5,a5,-1
    80006286:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000628a:	8526                	mv	a0,s1
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	012080e7          	jalr	18(ra) # 8000429e <iupdate>
    80006294:	b781                	j	800061d4 <sys_unlink+0xe0>
    return -1;
    80006296:	557d                	li	a0,-1
    80006298:	a005                	j	800062b8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000629a:	854a                	mv	a0,s2
    8000629c:	ffffe097          	auipc	ra,0xffffe
    800062a0:	330080e7          	jalr	816(ra) # 800045cc <iunlockput>
  iunlockput(dp);
    800062a4:	8526                	mv	a0,s1
    800062a6:	ffffe097          	auipc	ra,0xffffe
    800062aa:	326080e7          	jalr	806(ra) # 800045cc <iunlockput>
  end_op();
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	adc080e7          	jalr	-1316(ra) # 80004d8a <end_op>
  return -1;
    800062b6:	557d                	li	a0,-1
}
    800062b8:	70ae                	ld	ra,232(sp)
    800062ba:	740e                	ld	s0,224(sp)
    800062bc:	64ee                	ld	s1,216(sp)
    800062be:	694e                	ld	s2,208(sp)
    800062c0:	69ae                	ld	s3,200(sp)
    800062c2:	616d                	add	sp,sp,240
    800062c4:	8082                	ret

00000000800062c6 <sys_open>:

uint64
sys_open(void)
{
    800062c6:	7131                	add	sp,sp,-192
    800062c8:	fd06                	sd	ra,184(sp)
    800062ca:	f922                	sd	s0,176(sp)
    800062cc:	f526                	sd	s1,168(sp)
    800062ce:	f14a                	sd	s2,160(sp)
    800062d0:	ed4e                	sd	s3,152(sp)
    800062d2:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800062d4:	f4c40593          	add	a1,s0,-180
    800062d8:	4505                	li	a0,1
    800062da:	ffffd097          	auipc	ra,0xffffd
    800062de:	340080e7          	jalr	832(ra) # 8000361a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800062e2:	08000613          	li	a2,128
    800062e6:	f5040593          	add	a1,s0,-176
    800062ea:	4501                	li	a0,0
    800062ec:	ffffd097          	auipc	ra,0xffffd
    800062f0:	36e080e7          	jalr	878(ra) # 8000365a <argstr>
    800062f4:	87aa                	mv	a5,a0
    return -1;
    800062f6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800062f8:	0a07c863          	bltz	a5,800063a8 <sys_open+0xe2>

  begin_op();
    800062fc:	fffff097          	auipc	ra,0xfffff
    80006300:	a14080e7          	jalr	-1516(ra) # 80004d10 <begin_op>

  if(omode & O_CREATE){
    80006304:	f4c42783          	lw	a5,-180(s0)
    80006308:	2007f793          	and	a5,a5,512
    8000630c:	cbdd                	beqz	a5,800063c2 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000630e:	4681                	li	a3,0
    80006310:	4601                	li	a2,0
    80006312:	4589                	li	a1,2
    80006314:	f5040513          	add	a0,s0,-176
    80006318:	00000097          	auipc	ra,0x0
    8000631c:	97a080e7          	jalr	-1670(ra) # 80005c92 <create>
    80006320:	84aa                	mv	s1,a0
    if(ip == 0){
    80006322:	c951                	beqz	a0,800063b6 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006324:	04449703          	lh	a4,68(s1)
    80006328:	478d                	li	a5,3
    8000632a:	00f71763          	bne	a4,a5,80006338 <sys_open+0x72>
    8000632e:	0464d703          	lhu	a4,70(s1)
    80006332:	47a5                	li	a5,9
    80006334:	0ce7ec63          	bltu	a5,a4,8000640c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006338:	fffff097          	auipc	ra,0xfffff
    8000633c:	de0080e7          	jalr	-544(ra) # 80005118 <filealloc>
    80006340:	892a                	mv	s2,a0
    80006342:	c56d                	beqz	a0,8000642c <sys_open+0x166>
    80006344:	00000097          	auipc	ra,0x0
    80006348:	90c080e7          	jalr	-1780(ra) # 80005c50 <fdalloc>
    8000634c:	89aa                	mv	s3,a0
    8000634e:	0c054a63          	bltz	a0,80006422 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006352:	04449703          	lh	a4,68(s1)
    80006356:	478d                	li	a5,3
    80006358:	0ef70563          	beq	a4,a5,80006442 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000635c:	4789                	li	a5,2
    8000635e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80006362:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80006366:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000636a:	f4c42783          	lw	a5,-180(s0)
    8000636e:	0017c713          	xor	a4,a5,1
    80006372:	8b05                	and	a4,a4,1
    80006374:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006378:	0037f713          	and	a4,a5,3
    8000637c:	00e03733          	snez	a4,a4
    80006380:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006384:	4007f793          	and	a5,a5,1024
    80006388:	c791                	beqz	a5,80006394 <sys_open+0xce>
    8000638a:	04449703          	lh	a4,68(s1)
    8000638e:	4789                	li	a5,2
    80006390:	0cf70063          	beq	a4,a5,80006450 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80006394:	8526                	mv	a0,s1
    80006396:	ffffe097          	auipc	ra,0xffffe
    8000639a:	096080e7          	jalr	150(ra) # 8000442c <iunlock>
  end_op();
    8000639e:	fffff097          	auipc	ra,0xfffff
    800063a2:	9ec080e7          	jalr	-1556(ra) # 80004d8a <end_op>

  return fd;
    800063a6:	854e                	mv	a0,s3
}
    800063a8:	70ea                	ld	ra,184(sp)
    800063aa:	744a                	ld	s0,176(sp)
    800063ac:	74aa                	ld	s1,168(sp)
    800063ae:	790a                	ld	s2,160(sp)
    800063b0:	69ea                	ld	s3,152(sp)
    800063b2:	6129                	add	sp,sp,192
    800063b4:	8082                	ret
      end_op();
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	9d4080e7          	jalr	-1580(ra) # 80004d8a <end_op>
      return -1;
    800063be:	557d                	li	a0,-1
    800063c0:	b7e5                	j	800063a8 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800063c2:	f5040513          	add	a0,s0,-176
    800063c6:	ffffe097          	auipc	ra,0xffffe
    800063ca:	74a080e7          	jalr	1866(ra) # 80004b10 <namei>
    800063ce:	84aa                	mv	s1,a0
    800063d0:	c905                	beqz	a0,80006400 <sys_open+0x13a>
    ilock(ip);
    800063d2:	ffffe097          	auipc	ra,0xffffe
    800063d6:	f98080e7          	jalr	-104(ra) # 8000436a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800063da:	04449703          	lh	a4,68(s1)
    800063de:	4785                	li	a5,1
    800063e0:	f4f712e3          	bne	a4,a5,80006324 <sys_open+0x5e>
    800063e4:	f4c42783          	lw	a5,-180(s0)
    800063e8:	dba1                	beqz	a5,80006338 <sys_open+0x72>
      iunlockput(ip);
    800063ea:	8526                	mv	a0,s1
    800063ec:	ffffe097          	auipc	ra,0xffffe
    800063f0:	1e0080e7          	jalr	480(ra) # 800045cc <iunlockput>
      end_op();
    800063f4:	fffff097          	auipc	ra,0xfffff
    800063f8:	996080e7          	jalr	-1642(ra) # 80004d8a <end_op>
      return -1;
    800063fc:	557d                	li	a0,-1
    800063fe:	b76d                	j	800063a8 <sys_open+0xe2>
      end_op();
    80006400:	fffff097          	auipc	ra,0xfffff
    80006404:	98a080e7          	jalr	-1654(ra) # 80004d8a <end_op>
      return -1;
    80006408:	557d                	li	a0,-1
    8000640a:	bf79                	j	800063a8 <sys_open+0xe2>
    iunlockput(ip);
    8000640c:	8526                	mv	a0,s1
    8000640e:	ffffe097          	auipc	ra,0xffffe
    80006412:	1be080e7          	jalr	446(ra) # 800045cc <iunlockput>
    end_op();
    80006416:	fffff097          	auipc	ra,0xfffff
    8000641a:	974080e7          	jalr	-1676(ra) # 80004d8a <end_op>
    return -1;
    8000641e:	557d                	li	a0,-1
    80006420:	b761                	j	800063a8 <sys_open+0xe2>
      fileclose(f);
    80006422:	854a                	mv	a0,s2
    80006424:	fffff097          	auipc	ra,0xfffff
    80006428:	db0080e7          	jalr	-592(ra) # 800051d4 <fileclose>
    iunlockput(ip);
    8000642c:	8526                	mv	a0,s1
    8000642e:	ffffe097          	auipc	ra,0xffffe
    80006432:	19e080e7          	jalr	414(ra) # 800045cc <iunlockput>
    end_op();
    80006436:	fffff097          	auipc	ra,0xfffff
    8000643a:	954080e7          	jalr	-1708(ra) # 80004d8a <end_op>
    return -1;
    8000643e:	557d                	li	a0,-1
    80006440:	b7a5                	j	800063a8 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80006442:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80006446:	04649783          	lh	a5,70(s1)
    8000644a:	02f91223          	sh	a5,36(s2)
    8000644e:	bf21                	j	80006366 <sys_open+0xa0>
    itrunc(ip);
    80006450:	8526                	mv	a0,s1
    80006452:	ffffe097          	auipc	ra,0xffffe
    80006456:	026080e7          	jalr	38(ra) # 80004478 <itrunc>
    8000645a:	bf2d                	j	80006394 <sys_open+0xce>

000000008000645c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000645c:	7175                	add	sp,sp,-144
    8000645e:	e506                	sd	ra,136(sp)
    80006460:	e122                	sd	s0,128(sp)
    80006462:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006464:	fffff097          	auipc	ra,0xfffff
    80006468:	8ac080e7          	jalr	-1876(ra) # 80004d10 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000646c:	08000613          	li	a2,128
    80006470:	f7040593          	add	a1,s0,-144
    80006474:	4501                	li	a0,0
    80006476:	ffffd097          	auipc	ra,0xffffd
    8000647a:	1e4080e7          	jalr	484(ra) # 8000365a <argstr>
    8000647e:	02054963          	bltz	a0,800064b0 <sys_mkdir+0x54>
    80006482:	4681                	li	a3,0
    80006484:	4601                	li	a2,0
    80006486:	4585                	li	a1,1
    80006488:	f7040513          	add	a0,s0,-144
    8000648c:	00000097          	auipc	ra,0x0
    80006490:	806080e7          	jalr	-2042(ra) # 80005c92 <create>
    80006494:	cd11                	beqz	a0,800064b0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006496:	ffffe097          	auipc	ra,0xffffe
    8000649a:	136080e7          	jalr	310(ra) # 800045cc <iunlockput>
  end_op();
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	8ec080e7          	jalr	-1812(ra) # 80004d8a <end_op>
  return 0;
    800064a6:	4501                	li	a0,0
}
    800064a8:	60aa                	ld	ra,136(sp)
    800064aa:	640a                	ld	s0,128(sp)
    800064ac:	6149                	add	sp,sp,144
    800064ae:	8082                	ret
    end_op();
    800064b0:	fffff097          	auipc	ra,0xfffff
    800064b4:	8da080e7          	jalr	-1830(ra) # 80004d8a <end_op>
    return -1;
    800064b8:	557d                	li	a0,-1
    800064ba:	b7fd                	j	800064a8 <sys_mkdir+0x4c>

00000000800064bc <sys_mknod>:

uint64
sys_mknod(void)
{
    800064bc:	7135                	add	sp,sp,-160
    800064be:	ed06                	sd	ra,152(sp)
    800064c0:	e922                	sd	s0,144(sp)
    800064c2:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064c4:	fffff097          	auipc	ra,0xfffff
    800064c8:	84c080e7          	jalr	-1972(ra) # 80004d10 <begin_op>
  argint(1, &major);
    800064cc:	f6c40593          	add	a1,s0,-148
    800064d0:	4505                	li	a0,1
    800064d2:	ffffd097          	auipc	ra,0xffffd
    800064d6:	148080e7          	jalr	328(ra) # 8000361a <argint>
  argint(2, &minor);
    800064da:	f6840593          	add	a1,s0,-152
    800064de:	4509                	li	a0,2
    800064e0:	ffffd097          	auipc	ra,0xffffd
    800064e4:	13a080e7          	jalr	314(ra) # 8000361a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064e8:	08000613          	li	a2,128
    800064ec:	f7040593          	add	a1,s0,-144
    800064f0:	4501                	li	a0,0
    800064f2:	ffffd097          	auipc	ra,0xffffd
    800064f6:	168080e7          	jalr	360(ra) # 8000365a <argstr>
    800064fa:	02054b63          	bltz	a0,80006530 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800064fe:	f6841683          	lh	a3,-152(s0)
    80006502:	f6c41603          	lh	a2,-148(s0)
    80006506:	458d                	li	a1,3
    80006508:	f7040513          	add	a0,s0,-144
    8000650c:	fffff097          	auipc	ra,0xfffff
    80006510:	786080e7          	jalr	1926(ra) # 80005c92 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006514:	cd11                	beqz	a0,80006530 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006516:	ffffe097          	auipc	ra,0xffffe
    8000651a:	0b6080e7          	jalr	182(ra) # 800045cc <iunlockput>
  end_op();
    8000651e:	fffff097          	auipc	ra,0xfffff
    80006522:	86c080e7          	jalr	-1940(ra) # 80004d8a <end_op>
  return 0;
    80006526:	4501                	li	a0,0
}
    80006528:	60ea                	ld	ra,152(sp)
    8000652a:	644a                	ld	s0,144(sp)
    8000652c:	610d                	add	sp,sp,160
    8000652e:	8082                	ret
    end_op();
    80006530:	fffff097          	auipc	ra,0xfffff
    80006534:	85a080e7          	jalr	-1958(ra) # 80004d8a <end_op>
    return -1;
    80006538:	557d                	li	a0,-1
    8000653a:	b7fd                	j	80006528 <sys_mknod+0x6c>

000000008000653c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000653c:	7135                	add	sp,sp,-160
    8000653e:	ed06                	sd	ra,152(sp)
    80006540:	e922                	sd	s0,144(sp)
    80006542:	e526                	sd	s1,136(sp)
    80006544:	e14a                	sd	s2,128(sp)
    80006546:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006548:	ffffb097          	auipc	ra,0xffffb
    8000654c:	45e080e7          	jalr	1118(ra) # 800019a6 <myproc>
    80006550:	892a                	mv	s2,a0
  
  begin_op();
    80006552:	ffffe097          	auipc	ra,0xffffe
    80006556:	7be080e7          	jalr	1982(ra) # 80004d10 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000655a:	08000613          	li	a2,128
    8000655e:	f6040593          	add	a1,s0,-160
    80006562:	4501                	li	a0,0
    80006564:	ffffd097          	auipc	ra,0xffffd
    80006568:	0f6080e7          	jalr	246(ra) # 8000365a <argstr>
    8000656c:	04054b63          	bltz	a0,800065c2 <sys_chdir+0x86>
    80006570:	f6040513          	add	a0,s0,-160
    80006574:	ffffe097          	auipc	ra,0xffffe
    80006578:	59c080e7          	jalr	1436(ra) # 80004b10 <namei>
    8000657c:	84aa                	mv	s1,a0
    8000657e:	c131                	beqz	a0,800065c2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006580:	ffffe097          	auipc	ra,0xffffe
    80006584:	dea080e7          	jalr	-534(ra) # 8000436a <ilock>
  if(ip->type != T_DIR){
    80006588:	04449703          	lh	a4,68(s1)
    8000658c:	4785                	li	a5,1
    8000658e:	04f71063          	bne	a4,a5,800065ce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006592:	8526                	mv	a0,s1
    80006594:	ffffe097          	auipc	ra,0xffffe
    80006598:	e98080e7          	jalr	-360(ra) # 8000442c <iunlock>
  iput(p->cwd);
    8000659c:	15093503          	ld	a0,336(s2)
    800065a0:	ffffe097          	auipc	ra,0xffffe
    800065a4:	f84080e7          	jalr	-124(ra) # 80004524 <iput>
  end_op();
    800065a8:	ffffe097          	auipc	ra,0xffffe
    800065ac:	7e2080e7          	jalr	2018(ra) # 80004d8a <end_op>
  p->cwd = ip;
    800065b0:	14993823          	sd	s1,336(s2)
  return 0;
    800065b4:	4501                	li	a0,0
}
    800065b6:	60ea                	ld	ra,152(sp)
    800065b8:	644a                	ld	s0,144(sp)
    800065ba:	64aa                	ld	s1,136(sp)
    800065bc:	690a                	ld	s2,128(sp)
    800065be:	610d                	add	sp,sp,160
    800065c0:	8082                	ret
    end_op();
    800065c2:	ffffe097          	auipc	ra,0xffffe
    800065c6:	7c8080e7          	jalr	1992(ra) # 80004d8a <end_op>
    return -1;
    800065ca:	557d                	li	a0,-1
    800065cc:	b7ed                	j	800065b6 <sys_chdir+0x7a>
    iunlockput(ip);
    800065ce:	8526                	mv	a0,s1
    800065d0:	ffffe097          	auipc	ra,0xffffe
    800065d4:	ffc080e7          	jalr	-4(ra) # 800045cc <iunlockput>
    end_op();
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	7b2080e7          	jalr	1970(ra) # 80004d8a <end_op>
    return -1;
    800065e0:	557d                	li	a0,-1
    800065e2:	bfd1                	j	800065b6 <sys_chdir+0x7a>

00000000800065e4 <sys_exec>:

uint64
sys_exec(void)
{
    800065e4:	7121                	add	sp,sp,-448
    800065e6:	ff06                	sd	ra,440(sp)
    800065e8:	fb22                	sd	s0,432(sp)
    800065ea:	f726                	sd	s1,424(sp)
    800065ec:	f34a                	sd	s2,416(sp)
    800065ee:	ef4e                	sd	s3,408(sp)
    800065f0:	eb52                	sd	s4,400(sp)
    800065f2:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800065f4:	e4840593          	add	a1,s0,-440
    800065f8:	4505                	li	a0,1
    800065fa:	ffffd097          	auipc	ra,0xffffd
    800065fe:	040080e7          	jalr	64(ra) # 8000363a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006602:	08000613          	li	a2,128
    80006606:	f5040593          	add	a1,s0,-176
    8000660a:	4501                	li	a0,0
    8000660c:	ffffd097          	auipc	ra,0xffffd
    80006610:	04e080e7          	jalr	78(ra) # 8000365a <argstr>
    80006614:	87aa                	mv	a5,a0
    return -1;
    80006616:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006618:	0c07c263          	bltz	a5,800066dc <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    8000661c:	10000613          	li	a2,256
    80006620:	4581                	li	a1,0
    80006622:	e5040513          	add	a0,s0,-432
    80006626:	ffffa097          	auipc	ra,0xffffa
    8000662a:	6a8080e7          	jalr	1704(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000662e:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006632:	89a6                	mv	s3,s1
    80006634:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006636:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000663a:	00391513          	sll	a0,s2,0x3
    8000663e:	e4040593          	add	a1,s0,-448
    80006642:	e4843783          	ld	a5,-440(s0)
    80006646:	953e                	add	a0,a0,a5
    80006648:	ffffd097          	auipc	ra,0xffffd
    8000664c:	f34080e7          	jalr	-204(ra) # 8000357c <fetchaddr>
    80006650:	02054a63          	bltz	a0,80006684 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006654:	e4043783          	ld	a5,-448(s0)
    80006658:	c3b9                	beqz	a5,8000669e <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	488080e7          	jalr	1160(ra) # 80000ae2 <kalloc>
    80006662:	85aa                	mv	a1,a0
    80006664:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006668:	cd11                	beqz	a0,80006684 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000666a:	6605                	lui	a2,0x1
    8000666c:	e4043503          	ld	a0,-448(s0)
    80006670:	ffffd097          	auipc	ra,0xffffd
    80006674:	f5e080e7          	jalr	-162(ra) # 800035ce <fetchstr>
    80006678:	00054663          	bltz	a0,80006684 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    8000667c:	0905                	add	s2,s2,1
    8000667e:	09a1                	add	s3,s3,8
    80006680:	fb491de3          	bne	s2,s4,8000663a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006684:	f5040913          	add	s2,s0,-176
    80006688:	6088                	ld	a0,0(s1)
    8000668a:	c921                	beqz	a0,800066da <sys_exec+0xf6>
    kfree(argv[i]);
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	358080e7          	jalr	856(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006694:	04a1                	add	s1,s1,8
    80006696:	ff2499e3          	bne	s1,s2,80006688 <sys_exec+0xa4>
  return -1;
    8000669a:	557d                	li	a0,-1
    8000669c:	a081                	j	800066dc <sys_exec+0xf8>
      argv[i] = 0;
    8000669e:	0009079b          	sext.w	a5,s2
    800066a2:	078e                	sll	a5,a5,0x3
    800066a4:	fd078793          	add	a5,a5,-48
    800066a8:	97a2                	add	a5,a5,s0
    800066aa:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800066ae:	e5040593          	add	a1,s0,-432
    800066b2:	f5040513          	add	a0,s0,-176
    800066b6:	fffff097          	auipc	ra,0xfffff
    800066ba:	194080e7          	jalr	404(ra) # 8000584a <exec>
    800066be:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066c0:	f5040993          	add	s3,s0,-176
    800066c4:	6088                	ld	a0,0(s1)
    800066c6:	c901                	beqz	a0,800066d6 <sys_exec+0xf2>
    kfree(argv[i]);
    800066c8:	ffffa097          	auipc	ra,0xffffa
    800066cc:	31c080e7          	jalr	796(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066d0:	04a1                	add	s1,s1,8
    800066d2:	ff3499e3          	bne	s1,s3,800066c4 <sys_exec+0xe0>
  return ret;
    800066d6:	854a                	mv	a0,s2
    800066d8:	a011                	j	800066dc <sys_exec+0xf8>
  return -1;
    800066da:	557d                	li	a0,-1
}
    800066dc:	70fa                	ld	ra,440(sp)
    800066de:	745a                	ld	s0,432(sp)
    800066e0:	74ba                	ld	s1,424(sp)
    800066e2:	791a                	ld	s2,416(sp)
    800066e4:	69fa                	ld	s3,408(sp)
    800066e6:	6a5a                	ld	s4,400(sp)
    800066e8:	6139                	add	sp,sp,448
    800066ea:	8082                	ret

00000000800066ec <sys_pipe>:

uint64
sys_pipe(void)
{
    800066ec:	7139                	add	sp,sp,-64
    800066ee:	fc06                	sd	ra,56(sp)
    800066f0:	f822                	sd	s0,48(sp)
    800066f2:	f426                	sd	s1,40(sp)
    800066f4:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800066f6:	ffffb097          	auipc	ra,0xffffb
    800066fa:	2b0080e7          	jalr	688(ra) # 800019a6 <myproc>
    800066fe:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006700:	fd840593          	add	a1,s0,-40
    80006704:	4501                	li	a0,0
    80006706:	ffffd097          	auipc	ra,0xffffd
    8000670a:	f34080e7          	jalr	-204(ra) # 8000363a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000670e:	fc840593          	add	a1,s0,-56
    80006712:	fd040513          	add	a0,s0,-48
    80006716:	fffff097          	auipc	ra,0xfffff
    8000671a:	dea080e7          	jalr	-534(ra) # 80005500 <pipealloc>
    return -1;
    8000671e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006720:	0c054463          	bltz	a0,800067e8 <sys_pipe+0xfc>
  fd0 = -1;
    80006724:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006728:	fd043503          	ld	a0,-48(s0)
    8000672c:	fffff097          	auipc	ra,0xfffff
    80006730:	524080e7          	jalr	1316(ra) # 80005c50 <fdalloc>
    80006734:	fca42223          	sw	a0,-60(s0)
    80006738:	08054b63          	bltz	a0,800067ce <sys_pipe+0xe2>
    8000673c:	fc843503          	ld	a0,-56(s0)
    80006740:	fffff097          	auipc	ra,0xfffff
    80006744:	510080e7          	jalr	1296(ra) # 80005c50 <fdalloc>
    80006748:	fca42023          	sw	a0,-64(s0)
    8000674c:	06054863          	bltz	a0,800067bc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006750:	4691                	li	a3,4
    80006752:	fc440613          	add	a2,s0,-60
    80006756:	fd843583          	ld	a1,-40(s0)
    8000675a:	68a8                	ld	a0,80(s1)
    8000675c:	ffffb097          	auipc	ra,0xffffb
    80006760:	f0a080e7          	jalr	-246(ra) # 80001666 <copyout>
    80006764:	02054063          	bltz	a0,80006784 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006768:	4691                	li	a3,4
    8000676a:	fc040613          	add	a2,s0,-64
    8000676e:	fd843583          	ld	a1,-40(s0)
    80006772:	0591                	add	a1,a1,4
    80006774:	68a8                	ld	a0,80(s1)
    80006776:	ffffb097          	auipc	ra,0xffffb
    8000677a:	ef0080e7          	jalr	-272(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000677e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006780:	06055463          	bgez	a0,800067e8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006784:	fc442783          	lw	a5,-60(s0)
    80006788:	07e9                	add	a5,a5,26
    8000678a:	078e                	sll	a5,a5,0x3
    8000678c:	97a6                	add	a5,a5,s1
    8000678e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006792:	fc042783          	lw	a5,-64(s0)
    80006796:	07e9                	add	a5,a5,26
    80006798:	078e                	sll	a5,a5,0x3
    8000679a:	94be                	add	s1,s1,a5
    8000679c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800067a0:	fd043503          	ld	a0,-48(s0)
    800067a4:	fffff097          	auipc	ra,0xfffff
    800067a8:	a30080e7          	jalr	-1488(ra) # 800051d4 <fileclose>
    fileclose(wf);
    800067ac:	fc843503          	ld	a0,-56(s0)
    800067b0:	fffff097          	auipc	ra,0xfffff
    800067b4:	a24080e7          	jalr	-1500(ra) # 800051d4 <fileclose>
    return -1;
    800067b8:	57fd                	li	a5,-1
    800067ba:	a03d                	j	800067e8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800067bc:	fc442783          	lw	a5,-60(s0)
    800067c0:	0007c763          	bltz	a5,800067ce <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800067c4:	07e9                	add	a5,a5,26
    800067c6:	078e                	sll	a5,a5,0x3
    800067c8:	97a6                	add	a5,a5,s1
    800067ca:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800067ce:	fd043503          	ld	a0,-48(s0)
    800067d2:	fffff097          	auipc	ra,0xfffff
    800067d6:	a02080e7          	jalr	-1534(ra) # 800051d4 <fileclose>
    fileclose(wf);
    800067da:	fc843503          	ld	a0,-56(s0)
    800067de:	fffff097          	auipc	ra,0xfffff
    800067e2:	9f6080e7          	jalr	-1546(ra) # 800051d4 <fileclose>
    return -1;
    800067e6:	57fd                	li	a5,-1
}
    800067e8:	853e                	mv	a0,a5
    800067ea:	70e2                	ld	ra,56(sp)
    800067ec:	7442                	ld	s0,48(sp)
    800067ee:	74a2                	ld	s1,40(sp)
    800067f0:	6121                	add	sp,sp,64
    800067f2:	8082                	ret
	...

0000000080006800 <kernelvec>:
    80006800:	7111                	add	sp,sp,-256
    80006802:	e006                	sd	ra,0(sp)
    80006804:	e40a                	sd	sp,8(sp)
    80006806:	e80e                	sd	gp,16(sp)
    80006808:	ec12                	sd	tp,24(sp)
    8000680a:	f016                	sd	t0,32(sp)
    8000680c:	f41a                	sd	t1,40(sp)
    8000680e:	f81e                	sd	t2,48(sp)
    80006810:	fc22                	sd	s0,56(sp)
    80006812:	e0a6                	sd	s1,64(sp)
    80006814:	e4aa                	sd	a0,72(sp)
    80006816:	e8ae                	sd	a1,80(sp)
    80006818:	ecb2                	sd	a2,88(sp)
    8000681a:	f0b6                	sd	a3,96(sp)
    8000681c:	f4ba                	sd	a4,104(sp)
    8000681e:	f8be                	sd	a5,112(sp)
    80006820:	fcc2                	sd	a6,120(sp)
    80006822:	e146                	sd	a7,128(sp)
    80006824:	e54a                	sd	s2,136(sp)
    80006826:	e94e                	sd	s3,144(sp)
    80006828:	ed52                	sd	s4,152(sp)
    8000682a:	f156                	sd	s5,160(sp)
    8000682c:	f55a                	sd	s6,168(sp)
    8000682e:	f95e                	sd	s7,176(sp)
    80006830:	fd62                	sd	s8,184(sp)
    80006832:	e1e6                	sd	s9,192(sp)
    80006834:	e5ea                	sd	s10,200(sp)
    80006836:	e9ee                	sd	s11,208(sp)
    80006838:	edf2                	sd	t3,216(sp)
    8000683a:	f1f6                	sd	t4,224(sp)
    8000683c:	f5fa                	sd	t5,232(sp)
    8000683e:	f9fe                	sd	t6,240(sp)
    80006840:	c09fc0ef          	jal	80003448 <kerneltrap>
    80006844:	6082                	ld	ra,0(sp)
    80006846:	6122                	ld	sp,8(sp)
    80006848:	61c2                	ld	gp,16(sp)
    8000684a:	7282                	ld	t0,32(sp)
    8000684c:	7322                	ld	t1,40(sp)
    8000684e:	73c2                	ld	t2,48(sp)
    80006850:	7462                	ld	s0,56(sp)
    80006852:	6486                	ld	s1,64(sp)
    80006854:	6526                	ld	a0,72(sp)
    80006856:	65c6                	ld	a1,80(sp)
    80006858:	6666                	ld	a2,88(sp)
    8000685a:	7686                	ld	a3,96(sp)
    8000685c:	7726                	ld	a4,104(sp)
    8000685e:	77c6                	ld	a5,112(sp)
    80006860:	7866                	ld	a6,120(sp)
    80006862:	688a                	ld	a7,128(sp)
    80006864:	692a                	ld	s2,136(sp)
    80006866:	69ca                	ld	s3,144(sp)
    80006868:	6a6a                	ld	s4,152(sp)
    8000686a:	7a8a                	ld	s5,160(sp)
    8000686c:	7b2a                	ld	s6,168(sp)
    8000686e:	7bca                	ld	s7,176(sp)
    80006870:	7c6a                	ld	s8,184(sp)
    80006872:	6c8e                	ld	s9,192(sp)
    80006874:	6d2e                	ld	s10,200(sp)
    80006876:	6dce                	ld	s11,208(sp)
    80006878:	6e6e                	ld	t3,216(sp)
    8000687a:	7e8e                	ld	t4,224(sp)
    8000687c:	7f2e                	ld	t5,232(sp)
    8000687e:	7fce                	ld	t6,240(sp)
    80006880:	6111                	add	sp,sp,256
    80006882:	10200073          	sret
    80006886:	00000013          	nop
    8000688a:	00000013          	nop
    8000688e:	0001                	nop

0000000080006890 <timervec>:
    80006890:	34051573          	csrrw	a0,mscratch,a0
    80006894:	e10c                	sd	a1,0(a0)
    80006896:	e510                	sd	a2,8(a0)
    80006898:	e914                	sd	a3,16(a0)
    8000689a:	6d0c                	ld	a1,24(a0)
    8000689c:	7110                	ld	a2,32(a0)
    8000689e:	6194                	ld	a3,0(a1)
    800068a0:	96b2                	add	a3,a3,a2
    800068a2:	e194                	sd	a3,0(a1)
    800068a4:	4589                	li	a1,2
    800068a6:	14459073          	csrw	sip,a1
    800068aa:	6914                	ld	a3,16(a0)
    800068ac:	6510                	ld	a2,8(a0)
    800068ae:	610c                	ld	a1,0(a0)
    800068b0:	34051573          	csrrw	a0,mscratch,a0
    800068b4:	30200073          	mret
	...

00000000800068ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068ba:	1141                	add	sp,sp,-16
    800068bc:	e422                	sd	s0,8(sp)
    800068be:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068c0:	0c0007b7          	lui	a5,0xc000
    800068c4:	4705                	li	a4,1
    800068c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068c8:	c3d8                	sw	a4,4(a5)
}
    800068ca:	6422                	ld	s0,8(sp)
    800068cc:	0141                	add	sp,sp,16
    800068ce:	8082                	ret

00000000800068d0 <plicinithart>:

void
plicinithart(void)
{
    800068d0:	1141                	add	sp,sp,-16
    800068d2:	e406                	sd	ra,8(sp)
    800068d4:	e022                	sd	s0,0(sp)
    800068d6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800068d8:	ffffb097          	auipc	ra,0xffffb
    800068dc:	0a2080e7          	jalr	162(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800068e0:	0085171b          	sllw	a4,a0,0x8
    800068e4:	0c0027b7          	lui	a5,0xc002
    800068e8:	97ba                	add	a5,a5,a4
    800068ea:	40200713          	li	a4,1026
    800068ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800068f2:	00d5151b          	sllw	a0,a0,0xd
    800068f6:	0c2017b7          	lui	a5,0xc201
    800068fa:	97aa                	add	a5,a5,a0
    800068fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006900:	60a2                	ld	ra,8(sp)
    80006902:	6402                	ld	s0,0(sp)
    80006904:	0141                	add	sp,sp,16
    80006906:	8082                	ret

0000000080006908 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006908:	1141                	add	sp,sp,-16
    8000690a:	e406                	sd	ra,8(sp)
    8000690c:	e022                	sd	s0,0(sp)
    8000690e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006910:	ffffb097          	auipc	ra,0xffffb
    80006914:	06a080e7          	jalr	106(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006918:	00d5151b          	sllw	a0,a0,0xd
    8000691c:	0c2017b7          	lui	a5,0xc201
    80006920:	97aa                	add	a5,a5,a0
  return irq;
}
    80006922:	43c8                	lw	a0,4(a5)
    80006924:	60a2                	ld	ra,8(sp)
    80006926:	6402                	ld	s0,0(sp)
    80006928:	0141                	add	sp,sp,16
    8000692a:	8082                	ret

000000008000692c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000692c:	1101                	add	sp,sp,-32
    8000692e:	ec06                	sd	ra,24(sp)
    80006930:	e822                	sd	s0,16(sp)
    80006932:	e426                	sd	s1,8(sp)
    80006934:	1000                	add	s0,sp,32
    80006936:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006938:	ffffb097          	auipc	ra,0xffffb
    8000693c:	042080e7          	jalr	66(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006940:	00d5151b          	sllw	a0,a0,0xd
    80006944:	0c2017b7          	lui	a5,0xc201
    80006948:	97aa                	add	a5,a5,a0
    8000694a:	c3c4                	sw	s1,4(a5)
}
    8000694c:	60e2                	ld	ra,24(sp)
    8000694e:	6442                	ld	s0,16(sp)
    80006950:	64a2                	ld	s1,8(sp)
    80006952:	6105                	add	sp,sp,32
    80006954:	8082                	ret

0000000080006956 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006956:	1141                	add	sp,sp,-16
    80006958:	e406                	sd	ra,8(sp)
    8000695a:	e022                	sd	s0,0(sp)
    8000695c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000695e:	479d                	li	a5,7
    80006960:	04a7cc63          	blt	a5,a0,800069b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006964:	0001f797          	auipc	a5,0x1f
    80006968:	50c78793          	add	a5,a5,1292 # 80025e70 <disk>
    8000696c:	97aa                	add	a5,a5,a0
    8000696e:	0187c783          	lbu	a5,24(a5)
    80006972:	ebb9                	bnez	a5,800069c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006974:	00451693          	sll	a3,a0,0x4
    80006978:	0001f797          	auipc	a5,0x1f
    8000697c:	4f878793          	add	a5,a5,1272 # 80025e70 <disk>
    80006980:	6398                	ld	a4,0(a5)
    80006982:	9736                	add	a4,a4,a3
    80006984:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006988:	6398                	ld	a4,0(a5)
    8000698a:	9736                	add	a4,a4,a3
    8000698c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006990:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006994:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006998:	97aa                	add	a5,a5,a0
    8000699a:	4705                	li	a4,1
    8000699c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800069a0:	0001f517          	auipc	a0,0x1f
    800069a4:	4e850513          	add	a0,a0,1256 # 80025e88 <disk+0x18>
    800069a8:	ffffc097          	auipc	ra,0xffffc
    800069ac:	d3e080e7          	jalr	-706(ra) # 800026e6 <wakeup>
}
    800069b0:	60a2                	ld	ra,8(sp)
    800069b2:	6402                	ld	s0,0(sp)
    800069b4:	0141                	add	sp,sp,16
    800069b6:	8082                	ret
    panic("free_desc 1");
    800069b8:	00002517          	auipc	a0,0x2
    800069bc:	e2050513          	add	a0,a0,-480 # 800087d8 <syscalls+0x338>
    800069c0:	ffffa097          	auipc	ra,0xffffa
    800069c4:	b7c080e7          	jalr	-1156(ra) # 8000053c <panic>
    panic("free_desc 2");
    800069c8:	00002517          	auipc	a0,0x2
    800069cc:	e2050513          	add	a0,a0,-480 # 800087e8 <syscalls+0x348>
    800069d0:	ffffa097          	auipc	ra,0xffffa
    800069d4:	b6c080e7          	jalr	-1172(ra) # 8000053c <panic>

00000000800069d8 <virtio_disk_init>:
{
    800069d8:	1101                	add	sp,sp,-32
    800069da:	ec06                	sd	ra,24(sp)
    800069dc:	e822                	sd	s0,16(sp)
    800069de:	e426                	sd	s1,8(sp)
    800069e0:	e04a                	sd	s2,0(sp)
    800069e2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800069e4:	00002597          	auipc	a1,0x2
    800069e8:	e1458593          	add	a1,a1,-492 # 800087f8 <syscalls+0x358>
    800069ec:	0001f517          	auipc	a0,0x1f
    800069f0:	5ac50513          	add	a0,a0,1452 # 80025f98 <disk+0x128>
    800069f4:	ffffa097          	auipc	ra,0xffffa
    800069f8:	14e080e7          	jalr	334(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069fc:	100017b7          	lui	a5,0x10001
    80006a00:	4398                	lw	a4,0(a5)
    80006a02:	2701                	sext.w	a4,a4
    80006a04:	747277b7          	lui	a5,0x74727
    80006a08:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a0c:	14f71b63          	bne	a4,a5,80006b62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a10:	100017b7          	lui	a5,0x10001
    80006a14:	43dc                	lw	a5,4(a5)
    80006a16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a18:	4709                	li	a4,2
    80006a1a:	14e79463          	bne	a5,a4,80006b62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a1e:	100017b7          	lui	a5,0x10001
    80006a22:	479c                	lw	a5,8(a5)
    80006a24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a26:	12e79e63          	bne	a5,a4,80006b62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a2a:	100017b7          	lui	a5,0x10001
    80006a2e:	47d8                	lw	a4,12(a5)
    80006a30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a32:	554d47b7          	lui	a5,0x554d4
    80006a36:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a3a:	12f71463          	bne	a4,a5,80006b62 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a3e:	100017b7          	lui	a5,0x10001
    80006a42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a46:	4705                	li	a4,1
    80006a48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a4a:	470d                	li	a4,3
    80006a4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a4e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a50:	c7ffe6b7          	lui	a3,0xc7ffe
    80006a54:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd87af>
    80006a58:	8f75                	and	a4,a4,a3
    80006a5a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a5c:	472d                	li	a4,11
    80006a5e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006a60:	5bbc                	lw	a5,112(a5)
    80006a62:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006a66:	8ba1                	and	a5,a5,8
    80006a68:	10078563          	beqz	a5,80006b72 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a6c:	100017b7          	lui	a5,0x10001
    80006a70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006a74:	43fc                	lw	a5,68(a5)
    80006a76:	2781                	sext.w	a5,a5
    80006a78:	10079563          	bnez	a5,80006b82 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a7c:	100017b7          	lui	a5,0x10001
    80006a80:	5bdc                	lw	a5,52(a5)
    80006a82:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a84:	10078763          	beqz	a5,80006b92 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006a88:	471d                	li	a4,7
    80006a8a:	10f77c63          	bgeu	a4,a5,80006ba2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80006a8e:	ffffa097          	auipc	ra,0xffffa
    80006a92:	054080e7          	jalr	84(ra) # 80000ae2 <kalloc>
    80006a96:	0001f497          	auipc	s1,0x1f
    80006a9a:	3da48493          	add	s1,s1,986 # 80025e70 <disk>
    80006a9e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	042080e7          	jalr	66(ra) # 80000ae2 <kalloc>
    80006aa8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006aaa:	ffffa097          	auipc	ra,0xffffa
    80006aae:	038080e7          	jalr	56(ra) # 80000ae2 <kalloc>
    80006ab2:	87aa                	mv	a5,a0
    80006ab4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006ab6:	6088                	ld	a0,0(s1)
    80006ab8:	cd6d                	beqz	a0,80006bb2 <virtio_disk_init+0x1da>
    80006aba:	0001f717          	auipc	a4,0x1f
    80006abe:	3be73703          	ld	a4,958(a4) # 80025e78 <disk+0x8>
    80006ac2:	cb65                	beqz	a4,80006bb2 <virtio_disk_init+0x1da>
    80006ac4:	c7fd                	beqz	a5,80006bb2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006ac6:	6605                	lui	a2,0x1
    80006ac8:	4581                	li	a1,0
    80006aca:	ffffa097          	auipc	ra,0xffffa
    80006ace:	204080e7          	jalr	516(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006ad2:	0001f497          	auipc	s1,0x1f
    80006ad6:	39e48493          	add	s1,s1,926 # 80025e70 <disk>
    80006ada:	6605                	lui	a2,0x1
    80006adc:	4581                	li	a1,0
    80006ade:	6488                	ld	a0,8(s1)
    80006ae0:	ffffa097          	auipc	ra,0xffffa
    80006ae4:	1ee080e7          	jalr	494(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006ae8:	6605                	lui	a2,0x1
    80006aea:	4581                	li	a1,0
    80006aec:	6888                	ld	a0,16(s1)
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	1e0080e7          	jalr	480(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006af6:	100017b7          	lui	a5,0x10001
    80006afa:	4721                	li	a4,8
    80006afc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006afe:	4098                	lw	a4,0(s1)
    80006b00:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b04:	40d8                	lw	a4,4(s1)
    80006b06:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b0a:	6498                	ld	a4,8(s1)
    80006b0c:	0007069b          	sext.w	a3,a4
    80006b10:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b14:	9701                	sra	a4,a4,0x20
    80006b16:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b1a:	6898                	ld	a4,16(s1)
    80006b1c:	0007069b          	sext.w	a3,a4
    80006b20:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006b24:	9701                	sra	a4,a4,0x20
    80006b26:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006b2a:	4705                	li	a4,1
    80006b2c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006b2e:	00e48c23          	sb	a4,24(s1)
    80006b32:	00e48ca3          	sb	a4,25(s1)
    80006b36:	00e48d23          	sb	a4,26(s1)
    80006b3a:	00e48da3          	sb	a4,27(s1)
    80006b3e:	00e48e23          	sb	a4,28(s1)
    80006b42:	00e48ea3          	sb	a4,29(s1)
    80006b46:	00e48f23          	sb	a4,30(s1)
    80006b4a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006b4e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b52:	0727a823          	sw	s2,112(a5)
}
    80006b56:	60e2                	ld	ra,24(sp)
    80006b58:	6442                	ld	s0,16(sp)
    80006b5a:	64a2                	ld	s1,8(sp)
    80006b5c:	6902                	ld	s2,0(sp)
    80006b5e:	6105                	add	sp,sp,32
    80006b60:	8082                	ret
    panic("could not find virtio disk");
    80006b62:	00002517          	auipc	a0,0x2
    80006b66:	ca650513          	add	a0,a0,-858 # 80008808 <syscalls+0x368>
    80006b6a:	ffffa097          	auipc	ra,0xffffa
    80006b6e:	9d2080e7          	jalr	-1582(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006b72:	00002517          	auipc	a0,0x2
    80006b76:	cb650513          	add	a0,a0,-842 # 80008828 <syscalls+0x388>
    80006b7a:	ffffa097          	auipc	ra,0xffffa
    80006b7e:	9c2080e7          	jalr	-1598(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006b82:	00002517          	auipc	a0,0x2
    80006b86:	cc650513          	add	a0,a0,-826 # 80008848 <syscalls+0x3a8>
    80006b8a:	ffffa097          	auipc	ra,0xffffa
    80006b8e:	9b2080e7          	jalr	-1614(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006b92:	00002517          	auipc	a0,0x2
    80006b96:	cd650513          	add	a0,a0,-810 # 80008868 <syscalls+0x3c8>
    80006b9a:	ffffa097          	auipc	ra,0xffffa
    80006b9e:	9a2080e7          	jalr	-1630(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006ba2:	00002517          	auipc	a0,0x2
    80006ba6:	ce650513          	add	a0,a0,-794 # 80008888 <syscalls+0x3e8>
    80006baa:	ffffa097          	auipc	ra,0xffffa
    80006bae:	992080e7          	jalr	-1646(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006bb2:	00002517          	auipc	a0,0x2
    80006bb6:	cf650513          	add	a0,a0,-778 # 800088a8 <syscalls+0x408>
    80006bba:	ffffa097          	auipc	ra,0xffffa
    80006bbe:	982080e7          	jalr	-1662(ra) # 8000053c <panic>

0000000080006bc2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bc2:	7159                	add	sp,sp,-112
    80006bc4:	f486                	sd	ra,104(sp)
    80006bc6:	f0a2                	sd	s0,96(sp)
    80006bc8:	eca6                	sd	s1,88(sp)
    80006bca:	e8ca                	sd	s2,80(sp)
    80006bcc:	e4ce                	sd	s3,72(sp)
    80006bce:	e0d2                	sd	s4,64(sp)
    80006bd0:	fc56                	sd	s5,56(sp)
    80006bd2:	f85a                	sd	s6,48(sp)
    80006bd4:	f45e                	sd	s7,40(sp)
    80006bd6:	f062                	sd	s8,32(sp)
    80006bd8:	ec66                	sd	s9,24(sp)
    80006bda:	e86a                	sd	s10,16(sp)
    80006bdc:	1880                	add	s0,sp,112
    80006bde:	8a2a                	mv	s4,a0
    80006be0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006be2:	00c52c83          	lw	s9,12(a0)
    80006be6:	001c9c9b          	sllw	s9,s9,0x1
    80006bea:	1c82                	sll	s9,s9,0x20
    80006bec:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006bf0:	0001f517          	auipc	a0,0x1f
    80006bf4:	3a850513          	add	a0,a0,936 # 80025f98 <disk+0x128>
    80006bf8:	ffffa097          	auipc	ra,0xffffa
    80006bfc:	fda080e7          	jalr	-38(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006c00:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006c02:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006c04:	0001fb17          	auipc	s6,0x1f
    80006c08:	26cb0b13          	add	s6,s6,620 # 80025e70 <disk>
  for(int i = 0; i < 3; i++){
    80006c0c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c0e:	0001fc17          	auipc	s8,0x1f
    80006c12:	38ac0c13          	add	s8,s8,906 # 80025f98 <disk+0x128>
    80006c16:	a095                	j	80006c7a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006c18:	00fb0733          	add	a4,s6,a5
    80006c1c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006c20:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006c22:	0207c563          	bltz	a5,80006c4c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006c26:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006c28:	0591                	add	a1,a1,4
    80006c2a:	05560d63          	beq	a2,s5,80006c84 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006c2e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006c30:	0001f717          	auipc	a4,0x1f
    80006c34:	24070713          	add	a4,a4,576 # 80025e70 <disk>
    80006c38:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80006c3a:	01874683          	lbu	a3,24(a4)
    80006c3e:	fee9                	bnez	a3,80006c18 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006c40:	2785                	addw	a5,a5,1
    80006c42:	0705                	add	a4,a4,1
    80006c44:	fe979be3          	bne	a5,s1,80006c3a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006c48:	57fd                	li	a5,-1
    80006c4a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80006c4c:	00c05e63          	blez	a2,80006c68 <virtio_disk_rw+0xa6>
    80006c50:	060a                	sll	a2,a2,0x2
    80006c52:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006c56:	0009a503          	lw	a0,0(s3)
    80006c5a:	00000097          	auipc	ra,0x0
    80006c5e:	cfc080e7          	jalr	-772(ra) # 80006956 <free_desc>
      for(int j = 0; j < i; j++)
    80006c62:	0991                	add	s3,s3,4
    80006c64:	ffa999e3          	bne	s3,s10,80006c56 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c68:	85e2                	mv	a1,s8
    80006c6a:	0001f517          	auipc	a0,0x1f
    80006c6e:	21e50513          	add	a0,a0,542 # 80025e88 <disk+0x18>
    80006c72:	ffffc097          	auipc	ra,0xffffc
    80006c76:	a10080e7          	jalr	-1520(ra) # 80002682 <sleep>
  for(int i = 0; i < 3; i++){
    80006c7a:	f9040993          	add	s3,s0,-112
{
    80006c7e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006c80:	864a                	mv	a2,s2
    80006c82:	b775                	j	80006c2e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c84:	f9042503          	lw	a0,-112(s0)
    80006c88:	00a50713          	add	a4,a0,10
    80006c8c:	0712                	sll	a4,a4,0x4

  if(write)
    80006c8e:	0001f797          	auipc	a5,0x1f
    80006c92:	1e278793          	add	a5,a5,482 # 80025e70 <disk>
    80006c96:	00e786b3          	add	a3,a5,a4
    80006c9a:	01703633          	snez	a2,s7
    80006c9e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006ca0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006ca4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006ca8:	f6070613          	add	a2,a4,-160
    80006cac:	6394                	ld	a3,0(a5)
    80006cae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006cb0:	00870593          	add	a1,a4,8
    80006cb4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cb6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006cb8:	0007b803          	ld	a6,0(a5)
    80006cbc:	9642                	add	a2,a2,a6
    80006cbe:	46c1                	li	a3,16
    80006cc0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006cc2:	4585                	li	a1,1
    80006cc4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006cc8:	f9442683          	lw	a3,-108(s0)
    80006ccc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006cd0:	0692                	sll	a3,a3,0x4
    80006cd2:	9836                	add	a6,a6,a3
    80006cd4:	058a0613          	add	a2,s4,88
    80006cd8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006cdc:	0007b803          	ld	a6,0(a5)
    80006ce0:	96c2                	add	a3,a3,a6
    80006ce2:	40000613          	li	a2,1024
    80006ce6:	c690                	sw	a2,8(a3)
  if(write)
    80006ce8:	001bb613          	seqz	a2,s7
    80006cec:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006cf0:	00166613          	or	a2,a2,1
    80006cf4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006cf8:	f9842603          	lw	a2,-104(s0)
    80006cfc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d00:	00250693          	add	a3,a0,2
    80006d04:	0692                	sll	a3,a3,0x4
    80006d06:	96be                	add	a3,a3,a5
    80006d08:	58fd                	li	a7,-1
    80006d0a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d0e:	0612                	sll	a2,a2,0x4
    80006d10:	9832                	add	a6,a6,a2
    80006d12:	f9070713          	add	a4,a4,-112
    80006d16:	973e                	add	a4,a4,a5
    80006d18:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006d1c:	6398                	ld	a4,0(a5)
    80006d1e:	9732                	add	a4,a4,a2
    80006d20:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d22:	4609                	li	a2,2
    80006d24:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006d28:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d2c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006d30:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d34:	6794                	ld	a3,8(a5)
    80006d36:	0026d703          	lhu	a4,2(a3)
    80006d3a:	8b1d                	and	a4,a4,7
    80006d3c:	0706                	sll	a4,a4,0x1
    80006d3e:	96ba                	add	a3,a3,a4
    80006d40:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006d44:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d48:	6798                	ld	a4,8(a5)
    80006d4a:	00275783          	lhu	a5,2(a4)
    80006d4e:	2785                	addw	a5,a5,1
    80006d50:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d54:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d58:	100017b7          	lui	a5,0x10001
    80006d5c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d60:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006d64:	0001f917          	auipc	s2,0x1f
    80006d68:	23490913          	add	s2,s2,564 # 80025f98 <disk+0x128>
  while(b->disk == 1) {
    80006d6c:	4485                	li	s1,1
    80006d6e:	00b79c63          	bne	a5,a1,80006d86 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006d72:	85ca                	mv	a1,s2
    80006d74:	8552                	mv	a0,s4
    80006d76:	ffffc097          	auipc	ra,0xffffc
    80006d7a:	90c080e7          	jalr	-1780(ra) # 80002682 <sleep>
  while(b->disk == 1) {
    80006d7e:	004a2783          	lw	a5,4(s4)
    80006d82:	fe9788e3          	beq	a5,s1,80006d72 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006d86:	f9042903          	lw	s2,-112(s0)
    80006d8a:	00290713          	add	a4,s2,2
    80006d8e:	0712                	sll	a4,a4,0x4
    80006d90:	0001f797          	auipc	a5,0x1f
    80006d94:	0e078793          	add	a5,a5,224 # 80025e70 <disk>
    80006d98:	97ba                	add	a5,a5,a4
    80006d9a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006d9e:	0001f997          	auipc	s3,0x1f
    80006da2:	0d298993          	add	s3,s3,210 # 80025e70 <disk>
    80006da6:	00491713          	sll	a4,s2,0x4
    80006daa:	0009b783          	ld	a5,0(s3)
    80006dae:	97ba                	add	a5,a5,a4
    80006db0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006db4:	854a                	mv	a0,s2
    80006db6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006dba:	00000097          	auipc	ra,0x0
    80006dbe:	b9c080e7          	jalr	-1124(ra) # 80006956 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006dc2:	8885                	and	s1,s1,1
    80006dc4:	f0ed                	bnez	s1,80006da6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006dc6:	0001f517          	auipc	a0,0x1f
    80006dca:	1d250513          	add	a0,a0,466 # 80025f98 <disk+0x128>
    80006dce:	ffffa097          	auipc	ra,0xffffa
    80006dd2:	eb8080e7          	jalr	-328(ra) # 80000c86 <release>
}
    80006dd6:	70a6                	ld	ra,104(sp)
    80006dd8:	7406                	ld	s0,96(sp)
    80006dda:	64e6                	ld	s1,88(sp)
    80006ddc:	6946                	ld	s2,80(sp)
    80006dde:	69a6                	ld	s3,72(sp)
    80006de0:	6a06                	ld	s4,64(sp)
    80006de2:	7ae2                	ld	s5,56(sp)
    80006de4:	7b42                	ld	s6,48(sp)
    80006de6:	7ba2                	ld	s7,40(sp)
    80006de8:	7c02                	ld	s8,32(sp)
    80006dea:	6ce2                	ld	s9,24(sp)
    80006dec:	6d42                	ld	s10,16(sp)
    80006dee:	6165                	add	sp,sp,112
    80006df0:	8082                	ret

0000000080006df2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006df2:	1101                	add	sp,sp,-32
    80006df4:	ec06                	sd	ra,24(sp)
    80006df6:	e822                	sd	s0,16(sp)
    80006df8:	e426                	sd	s1,8(sp)
    80006dfa:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006dfc:	0001f497          	auipc	s1,0x1f
    80006e00:	07448493          	add	s1,s1,116 # 80025e70 <disk>
    80006e04:	0001f517          	auipc	a0,0x1f
    80006e08:	19450513          	add	a0,a0,404 # 80025f98 <disk+0x128>
    80006e0c:	ffffa097          	auipc	ra,0xffffa
    80006e10:	dc6080e7          	jalr	-570(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e14:	10001737          	lui	a4,0x10001
    80006e18:	533c                	lw	a5,96(a4)
    80006e1a:	8b8d                	and	a5,a5,3
    80006e1c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e1e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e22:	689c                	ld	a5,16(s1)
    80006e24:	0204d703          	lhu	a4,32(s1)
    80006e28:	0027d783          	lhu	a5,2(a5)
    80006e2c:	04f70863          	beq	a4,a5,80006e7c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006e30:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e34:	6898                	ld	a4,16(s1)
    80006e36:	0204d783          	lhu	a5,32(s1)
    80006e3a:	8b9d                	and	a5,a5,7
    80006e3c:	078e                	sll	a5,a5,0x3
    80006e3e:	97ba                	add	a5,a5,a4
    80006e40:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e42:	00278713          	add	a4,a5,2
    80006e46:	0712                	sll	a4,a4,0x4
    80006e48:	9726                	add	a4,a4,s1
    80006e4a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006e4e:	e721                	bnez	a4,80006e96 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e50:	0789                	add	a5,a5,2
    80006e52:	0792                	sll	a5,a5,0x4
    80006e54:	97a6                	add	a5,a5,s1
    80006e56:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006e58:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e5c:	ffffc097          	auipc	ra,0xffffc
    80006e60:	88a080e7          	jalr	-1910(ra) # 800026e6 <wakeup>

    disk.used_idx += 1;
    80006e64:	0204d783          	lhu	a5,32(s1)
    80006e68:	2785                	addw	a5,a5,1
    80006e6a:	17c2                	sll	a5,a5,0x30
    80006e6c:	93c1                	srl	a5,a5,0x30
    80006e6e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e72:	6898                	ld	a4,16(s1)
    80006e74:	00275703          	lhu	a4,2(a4)
    80006e78:	faf71ce3          	bne	a4,a5,80006e30 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006e7c:	0001f517          	auipc	a0,0x1f
    80006e80:	11c50513          	add	a0,a0,284 # 80025f98 <disk+0x128>
    80006e84:	ffffa097          	auipc	ra,0xffffa
    80006e88:	e02080e7          	jalr	-510(ra) # 80000c86 <release>
}
    80006e8c:	60e2                	ld	ra,24(sp)
    80006e8e:	6442                	ld	s0,16(sp)
    80006e90:	64a2                	ld	s1,8(sp)
    80006e92:	6105                	add	sp,sp,32
    80006e94:	8082                	ret
      panic("virtio_disk_intr status");
    80006e96:	00002517          	auipc	a0,0x2
    80006e9a:	a2a50513          	add	a0,a0,-1494 # 800088c0 <syscalls+0x420>
    80006e9e:	ffff9097          	auipc	ra,0xffff9
    80006ea2:	69e080e7          	jalr	1694(ra) # 8000053c <panic>
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
