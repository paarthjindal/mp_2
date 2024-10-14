
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	99013103          	ld	sp,-1648(sp) # 80008990 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	9b070713          	add	a4,a4,-1616 # 80008a00 <timer_scratch>
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
    80000066:	90e78793          	add	a5,a5,-1778 # 80006970 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ef>
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
    8000012e:	a9a080e7          	jalr	-1382(ra) # 80002bc4 <either_copyin>
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
    80000188:	9bc50513          	add	a0,a0,-1604 # 80010b40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	9ac48493          	add	s1,s1,-1620 # 80010b40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	a3c90913          	add	s2,s2,-1476 # 80010bd8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	802080e7          	jalr	-2046(ra) # 800019b6 <myproc>
    800001bc:	00003097          	auipc	ra,0x3
    800001c0:	83a080e7          	jalr	-1990(ra) # 800029f6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	578080e7          	jalr	1400(ra) # 80002742 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	96270713          	add	a4,a4,-1694 # 80010b40 <cons>
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
    80000214:	95e080e7          	jalr	-1698(ra) # 80002b6e <either_copyout>
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
    8000022c:	91850513          	add	a0,a0,-1768 # 80010b40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	90250513          	add	a0,a0,-1790 # 80010b40 <cons>
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
    80000272:	96f72523          	sw	a5,-1686(a4) # 80010bd8 <cons+0x98>
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
    800002cc:	87850513          	add	a0,a0,-1928 # 80010b40 <cons>
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
    800002f2:	92c080e7          	jalr	-1748(ra) # 80002c1a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	84a50513          	add	a0,a0,-1974 # 80010b40 <cons>
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
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	82670713          	add	a4,a4,-2010 # 80010b40 <cons>
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
    80000348:	7fc78793          	add	a5,a5,2044 # 80010b40 <cons>
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
    80000376:	8667a783          	lw	a5,-1946(a5) # 80010bd8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	7ba70713          	add	a4,a4,1978 # 80010b40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	7aa48493          	add	s1,s1,1962 # 80010b40 <cons>
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
    800003d6:	76e70713          	add	a4,a4,1902 # 80010b40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	7ef72c23          	sw	a5,2040(a4) # 80010be0 <cons+0xa0>
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
    80000412:	73278793          	add	a5,a5,1842 # 80010b40 <cons>
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
    80000436:	7ac7a523          	sw	a2,1962(a5) # 80010bdc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	79e50513          	add	a0,a0,1950 # 80010bd8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	364080e7          	jalr	868(ra) # 800027a6 <wakeup>
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
    80000460:	6e450513          	add	a0,a0,1764 # 80010b40 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00025797          	auipc	a5,0x25
    80000478:	a0478793          	add	a5,a5,-1532 # 80024e78 <devsw>
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
    8000054c:	6a07ac23          	sw	zero,1720(a5) # 80010c00 <pr+0x18>
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
    8000056e:	da650513          	add	a0,a0,-602 # 80008310 <digits+0x2d0>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	42f72a23          	sw	a5,1076(a4) # 800089b0 <panicked>
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
    800005bc:	648dad83          	lw	s11,1608(s11) # 80010c00 <pr+0x18>
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
    800005fa:	5f250513          	add	a0,a0,1522 # 80010be8 <pr>
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
    80000758:	49450513          	add	a0,a0,1172 # 80010be8 <pr>
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
    80000774:	47848493          	add	s1,s1,1144 # 80010be8 <pr>
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
    800007d4:	43850513          	add	a0,a0,1080 # 80010c08 <uart_tx_lock>
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
    80000800:	1b47a783          	lw	a5,436(a5) # 800089b0 <panicked>
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
    80000838:	1847b783          	ld	a5,388(a5) # 800089b8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	18473703          	ld	a4,388(a4) # 800089c0 <uart_tx_w>
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
    80000862:	3aaa0a13          	add	s4,s4,938 # 80010c08 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	15248493          	add	s1,s1,338 # 800089b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	15298993          	add	s3,s3,338 # 800089c0 <uart_tx_w>
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
    80000894:	f16080e7          	jalr	-234(ra) # 800027a6 <wakeup>
    
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
    800008d0:	33c50513          	add	a0,a0,828 # 80010c08 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0d47a783          	lw	a5,212(a5) # 800089b0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	0da73703          	ld	a4,218(a4) # 800089c0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	0ca7b783          	ld	a5,202(a5) # 800089b8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	30e98993          	add	s3,s3,782 # 80010c08 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	0b648493          	add	s1,s1,182 # 800089b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	0b690913          	add	s2,s2,182 # 800089c0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	e28080e7          	jalr	-472(ra) # 80002742 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	2d848493          	add	s1,s1,728 # 80010c08 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	06e7be23          	sd	a4,124(a5) # 800089c0 <uart_tx_w>
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
    800009ba:	25248493          	add	s1,s1,594 # 80010c08 <uart_tx_lock>
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
    800009fc:	61878793          	add	a5,a5,1560 # 80026010 <end>
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
    80000a1c:	22890913          	add	s2,s2,552 # 80010c40 <kmem>
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
    80000aba:	18a50513          	add	a0,a0,394 # 80010c40 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00025517          	auipc	a0,0x25
    80000ace:	54650513          	add	a0,a0,1350 # 80026010 <end>
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
    80000af0:	15448493          	add	s1,s1,340 # 80010c40 <kmem>
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
    80000b08:	13c50513          	add	a0,a0,316 # 80010c40 <kmem>
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
    80000b34:	11050513          	add	a0,a0,272 # 80010c40 <kmem>
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
    80000b70:	e2e080e7          	jalr	-466(ra) # 8000199a <mycpu>
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
    80000ba2:	dfc080e7          	jalr	-516(ra) # 8000199a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	df0080e7          	jalr	-528(ra) # 8000199a <mycpu>
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
    80000bc6:	dd8080e7          	jalr	-552(ra) # 8000199a <mycpu>
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
    80000c06:	d98080e7          	jalr	-616(ra) # 8000199a <mycpu>
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
    80000c32:	d6c080e7          	jalr	-660(ra) # 8000199a <mycpu>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd8ff1>
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
    80000e7e:	b10080e7          	jalr	-1264(ra) # 8000198a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	b4670713          	add	a4,a4,-1210 # 800089c8 <started>
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
    80000e9a:	af4080e7          	jalr	-1292(ra) # 8000198a <cpuid>
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
    80000ebc:	0a6080e7          	jalr	166(ra) # 80002f5e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00006097          	auipc	ra,0x6
    80000ec4:	af0080e7          	jalr	-1296(ra) # 800069b0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	748080e7          	jalr	1864(ra) # 80002610 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	43050513          	add	a0,a0,1072 # 80008310 <digits+0x2d0>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	add	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	41050513          	add	a0,a0,1040 # 80008310 <digits+0x2d0>
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
    80000f34:	006080e7          	jalr	6(ra) # 80002f36 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	026080e7          	jalr	38(ra) # 80002f5e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00006097          	auipc	ra,0x6
    80000f44:	a5a080e7          	jalr	-1446(ra) # 8000699a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00006097          	auipc	ra,0x6
    80000f4c:	a68080e7          	jalr	-1432(ra) # 800069b0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	c68080e7          	jalr	-920(ra) # 80003bb8 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	306080e7          	jalr	774(ra) # 8000425e <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	27c080e7          	jalr	636(ra) # 800051dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00006097          	auipc	ra,0x6
    80000f6c:	b50080e7          	jalr	-1200(ra) # 80006ab8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d72080e7          	jalr	-654(ra) # 80001ce2 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	a4f72523          	sw	a5,-1462(a4) # 800089c8 <started>
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
    80000f96:	a3e7b783          	ld	a5,-1474(a5) # 800089d0 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8fe7>
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
    80001252:	78a7b123          	sd	a0,1922(a5) # 800089d0 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8ff0>
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
    8000184a:	7ea48493          	add	s1,s1,2026 # 80012030 <proc>
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
    80001864:	3d0a0a13          	add	s4,s4,976 # 8001ac30 <tickslock>
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
int start_time;
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
  start_time = ticks;
    800018da:	00007797          	auipc	a5,0x7
    800018de:	1167a783          	lw	a5,278(a5) # 800089f0 <ticks>
    800018e2:	00007717          	auipc	a4,0x7
    800018e6:	0ef72f23          	sw	a5,254(a4) # 800089e0 <start_time>
  // printf("start time is %d",start_time);
  initlock(&pid_lock, "nextpid");
    800018ea:	00007597          	auipc	a1,0x7
    800018ee:	8f658593          	add	a1,a1,-1802 # 800081e0 <digits+0x1a0>
    800018f2:	0000f517          	auipc	a0,0xf
    800018f6:	36e50513          	add	a0,a0,878 # 80010c60 <pid_lock>
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	248080e7          	jalr	584(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8e658593          	add	a1,a1,-1818 # 800081e8 <digits+0x1a8>
    8000190a:	0000f517          	auipc	a0,0xf
    8000190e:	36e50513          	add	a0,a0,878 # 80010c78 <wait_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	230080e7          	jalr	560(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000191a:	00010497          	auipc	s1,0x10
    8000191e:	71648493          	add	s1,s1,1814 # 80012030 <proc>
  {
    initlock(&p->lock, "proc");
    80001922:	00007b17          	auipc	s6,0x7
    80001926:	8d6b0b13          	add	s6,s6,-1834 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000192a:	8aa6                	mv	s5,s1
    8000192c:	00006a17          	auipc	s4,0x6
    80001930:	6d4a0a13          	add	s4,s4,1748 # 80008000 <etext>
    80001934:	04000937          	lui	s2,0x4000
    80001938:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000193a:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193c:	00019997          	auipc	s3,0x19
    80001940:	2f498993          	add	s3,s3,756 # 8001ac30 <tickslock>
    initlock(&p->lock, "proc");
    80001944:	85da                	mv	a1,s6
    80001946:	8526                	mv	a0,s1
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	1fa080e7          	jalr	506(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001950:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001954:	415487b3          	sub	a5,s1,s5
    80001958:	8791                	sra	a5,a5,0x4
    8000195a:	000a3703          	ld	a4,0(s4)
    8000195e:	02e787b3          	mul	a5,a5,a4
    80001962:	2785                	addw	a5,a5,1
    80001964:	00d7979b          	sllw	a5,a5,0xd
    80001968:	40f907b3          	sub	a5,s2,a5
    8000196c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000196e:	23048493          	add	s1,s1,560
    80001972:	fd3499e3          	bne	s1,s3,80001944 <procinit+0x7e>
  }
}
    80001976:	70e2                	ld	ra,56(sp)
    80001978:	7442                	ld	s0,48(sp)
    8000197a:	74a2                	ld	s1,40(sp)
    8000197c:	7902                	ld	s2,32(sp)
    8000197e:	69e2                	ld	s3,24(sp)
    80001980:	6a42                	ld	s4,16(sp)
    80001982:	6aa2                	ld	s5,8(sp)
    80001984:	6b02                	ld	s6,0(sp)
    80001986:	6121                	add	sp,sp,64
    80001988:	8082                	ret

000000008000198a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000198a:	1141                	add	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001990:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001992:	2501                	sext.w	a0,a0
    80001994:	6422                	ld	s0,8(sp)
    80001996:	0141                	add	sp,sp,16
    80001998:	8082                	ret

000000008000199a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000199a:	1141                	add	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	add	s0,sp,16
    800019a0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a2:	2781                	sext.w	a5,a5
    800019a4:	079e                	sll	a5,a5,0x7
  return c;
}
    800019a6:	0000f517          	auipc	a0,0xf
    800019aa:	2ea50513          	add	a0,a0,746 # 80010c90 <cpus>
    800019ae:	953e                	add	a0,a0,a5
    800019b0:	6422                	ld	s0,8(sp)
    800019b2:	0141                	add	sp,sp,16
    800019b4:	8082                	ret

00000000800019b6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b6:	1101                	add	sp,sp,-32
    800019b8:	ec06                	sd	ra,24(sp)
    800019ba:	e822                	sd	s0,16(sp)
    800019bc:	e426                	sd	s1,8(sp)
    800019be:	1000                	add	s0,sp,32
  push_off();
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	1c6080e7          	jalr	454(ra) # 80000b86 <push_off>
    800019c8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	sll	a5,a5,0x7
    800019ce:	0000f717          	auipc	a4,0xf
    800019d2:	29270713          	add	a4,a4,658 # 80010c60 <pid_lock>
    800019d6:	97ba                	add	a5,a5,a4
    800019d8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	24c080e7          	jalr	588(ra) # 80000c26 <pop_off>
  return p;
}
    800019e2:	8526                	mv	a0,s1
    800019e4:	60e2                	ld	ra,24(sp)
    800019e6:	6442                	ld	s0,16(sp)
    800019e8:	64a2                	ld	s1,8(sp)
    800019ea:	6105                	add	sp,sp,32
    800019ec:	8082                	ret

00000000800019ee <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019ee:	1141                	add	sp,sp,-16
    800019f0:	e406                	sd	ra,8(sp)
    800019f2:	e022                	sd	s0,0(sp)
    800019f4:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	fc0080e7          	jalr	-64(ra) # 800019b6 <myproc>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	288080e7          	jalr	648(ra) # 80000c86 <release>

  if (first)
    80001a06:	00007797          	auipc	a5,0x7
    80001a0a:	f2a7a783          	lw	a5,-214(a5) # 80008930 <first.1>
    80001a0e:	eb89                	bnez	a5,80001a20 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a10:	00001097          	auipc	ra,0x1
    80001a14:	618080e7          	jalr	1560(ra) # 80003028 <usertrapret>
}
    80001a18:	60a2                	ld	ra,8(sp)
    80001a1a:	6402                	ld	s0,0(sp)
    80001a1c:	0141                	add	sp,sp,16
    80001a1e:	8082                	ret
    first = 0;
    80001a20:	00007797          	auipc	a5,0x7
    80001a24:	f007a823          	sw	zero,-240(a5) # 80008930 <first.1>
    fsinit(ROOTDEV);
    80001a28:	4505                	li	a0,1
    80001a2a:	00002097          	auipc	ra,0x2
    80001a2e:	7b4080e7          	jalr	1972(ra) # 800041de <fsinit>
    80001a32:	bff9                	j	80001a10 <forkret+0x22>

0000000080001a34 <allocpid>:
{
    80001a34:	1101                	add	sp,sp,-32
    80001a36:	ec06                	sd	ra,24(sp)
    80001a38:	e822                	sd	s0,16(sp)
    80001a3a:	e426                	sd	s1,8(sp)
    80001a3c:	e04a                	sd	s2,0(sp)
    80001a3e:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001a40:	0000f917          	auipc	s2,0xf
    80001a44:	22090913          	add	s2,s2,544 # 80010c60 <pid_lock>
    80001a48:	854a                	mv	a0,s2
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	188080e7          	jalr	392(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	eee78793          	add	a5,a5,-274 # 80008940 <nextpid>
    80001a5a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5c:	0014871b          	addw	a4,s1,1
    80001a60:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a62:	854a                	mv	a0,s2
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	222080e7          	jalr	546(ra) # 80000c86 <release>
}
    80001a6c:	8526                	mv	a0,s1
    80001a6e:	60e2                	ld	ra,24(sp)
    80001a70:	6442                	ld	s0,16(sp)
    80001a72:	64a2                	ld	s1,8(sp)
    80001a74:	6902                	ld	s2,0(sp)
    80001a76:	6105                	add	sp,sp,32
    80001a78:	8082                	ret

0000000080001a7a <proc_pagetable>:
{
    80001a7a:	1101                	add	sp,sp,-32
    80001a7c:	ec06                	sd	ra,24(sp)
    80001a7e:	e822                	sd	s0,16(sp)
    80001a80:	e426                	sd	s1,8(sp)
    80001a82:	e04a                	sd	s2,0(sp)
    80001a84:	1000                	add	s0,sp,32
    80001a86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a88:	00000097          	auipc	ra,0x0
    80001a8c:	89a080e7          	jalr	-1894(ra) # 80001322 <uvmcreate>
    80001a90:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a92:	c121                	beqz	a0,80001ad2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a94:	4729                	li	a4,10
    80001a96:	00005697          	auipc	a3,0x5
    80001a9a:	56a68693          	add	a3,a3,1386 # 80007000 <_trampoline>
    80001a9e:	6605                	lui	a2,0x1
    80001aa0:	040005b7          	lui	a1,0x4000
    80001aa4:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa6:	05b2                	sll	a1,a1,0xc
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	5f0080e7          	jalr	1520(ra) # 80001098 <mappages>
    80001ab0:	02054863          	bltz	a0,80001ae0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab4:	4719                	li	a4,6
    80001ab6:	05893683          	ld	a3,88(s2)
    80001aba:	6605                	lui	a2,0x1
    80001abc:	020005b7          	lui	a1,0x2000
    80001ac0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ac2:	05b6                	sll	a1,a1,0xd
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	5d2080e7          	jalr	1490(ra) # 80001098 <mappages>
    80001ace:	02054163          	bltz	a0,80001af0 <proc_pagetable+0x76>
}
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	60e2                	ld	ra,24(sp)
    80001ad6:	6442                	ld	s0,16(sp)
    80001ad8:	64a2                	ld	s1,8(sp)
    80001ada:	6902                	ld	s2,0(sp)
    80001adc:	6105                	add	sp,sp,32
    80001ade:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae0:	4581                	li	a1,0
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	a44080e7          	jalr	-1468(ra) # 80001528 <uvmfree>
    return 0;
    80001aec:	4481                	li	s1,0
    80001aee:	b7d5                	j	80001ad2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af0:	4681                	li	a3,0
    80001af2:	4605                	li	a2,1
    80001af4:	040005b7          	lui	a1,0x4000
    80001af8:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001afa:	05b2                	sll	a1,a1,0xc
    80001afc:	8526                	mv	a0,s1
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	760080e7          	jalr	1888(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b06:	4581                	li	a1,0
    80001b08:	8526                	mv	a0,s1
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	a1e080e7          	jalr	-1506(ra) # 80001528 <uvmfree>
    return 0;
    80001b12:	4481                	li	s1,0
    80001b14:	bf7d                	j	80001ad2 <proc_pagetable+0x58>

0000000080001b16 <proc_freepagetable>:
{
    80001b16:	1101                	add	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	e426                	sd	s1,8(sp)
    80001b1e:	e04a                	sd	s2,0(sp)
    80001b20:	1000                	add	s0,sp,32
    80001b22:	84aa                	mv	s1,a0
    80001b24:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b26:	4681                	li	a3,0
    80001b28:	4605                	li	a2,1
    80001b2a:	040005b7          	lui	a1,0x4000
    80001b2e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b30:	05b2                	sll	a1,a1,0xc
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	72c080e7          	jalr	1836(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3a:	4681                	li	a3,0
    80001b3c:	4605                	li	a2,1
    80001b3e:	020005b7          	lui	a1,0x2000
    80001b42:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b44:	05b6                	sll	a1,a1,0xd
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	716080e7          	jalr	1814(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b50:	85ca                	mv	a1,s2
    80001b52:	8526                	mv	a0,s1
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	9d4080e7          	jalr	-1580(ra) # 80001528 <uvmfree>
}
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6902                	ld	s2,0(sp)
    80001b64:	6105                	add	sp,sp,32
    80001b66:	8082                	ret

0000000080001b68 <freeproc>:
{
    80001b68:	1101                	add	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	1000                	add	s0,sp,32
    80001b72:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b74:	6d28                	ld	a0,88(a0)
    80001b76:	c509                	beqz	a0,80001b80 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	e6c080e7          	jalr	-404(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b80:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b84:	68a8                	ld	a0,80(s1)
    80001b86:	c511                	beqz	a0,80001b92 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b88:	64ac                	ld	a1,72(s1)
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	f8c080e7          	jalr	-116(ra) # 80001b16 <proc_freepagetable>
  p->pagetable = 0;
    80001b92:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b96:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001baa:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bae:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb2:	0004ac23          	sw	zero,24(s1)
}
    80001bb6:	60e2                	ld	ra,24(sp)
    80001bb8:	6442                	ld	s0,16(sp)
    80001bba:	64a2                	ld	s1,8(sp)
    80001bbc:	6105                	add	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <allocproc>:
{
    80001bc0:	1101                	add	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bcc:	00010497          	auipc	s1,0x10
    80001bd0:	46448493          	add	s1,s1,1124 # 80012030 <proc>
    80001bd4:	00019917          	auipc	s2,0x19
    80001bd8:	05c90913          	add	s2,s2,92 # 8001ac30 <tickslock>
    acquire(&p->lock);
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	ff4080e7          	jalr	-12(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001be6:	4c9c                	lw	a5,24(s1)
    80001be8:	cf81                	beqz	a5,80001c00 <allocproc+0x40>
      release(&p->lock); // Release lock if not UNUSED
    80001bea:	8526                	mv	a0,s1
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	09a080e7          	jalr	154(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bf4:	23048493          	add	s1,s1,560
    80001bf8:	ff2492e3          	bne	s1,s2,80001bdc <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001bfc:	4481                	li	s1,0
    80001bfe:	a05d                	j	80001ca4 <allocproc+0xe4>
  p->pid = allocpid(); // Assign PID
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	e34080e7          	jalr	-460(ra) # 80001a34 <allocpid>
    80001c08:	d888                	sw	a0,48(s1)
  p->state = USED;     // Mark process as USED
    80001c0a:	4785                	li	a5,1
    80001c0c:	cc9c                	sw	a5,24(s1)
  for (int i = 0; i < 31; i++)
    80001c0e:	17448793          	add	a5,s1,372
    80001c12:	1f048713          	add	a4,s1,496
    p->syscall_count[i] = 0;
    80001c16:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < 31; i++)
    80001c1a:	0791                	add	a5,a5,4
    80001c1c:	fee79de3          	bne	a5,a4,80001c16 <allocproc+0x56>
  p->tickets = 1; // since by default a process should have 1 ticket
    80001c20:	4785                	li	a5,1
    80001c22:	20f4a823          	sw	a5,528(s1)
  p->creation_time = ticks;
    80001c26:	00007797          	auipc	a5,0x7
    80001c2a:	dca7e783          	lwu	a5,-566(a5) # 800089f0 <ticks>
    80001c2e:	20f4bc23          	sd	a5,536(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	eb0080e7          	jalr	-336(ra) # 80000ae2 <kalloc>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	eca8                	sd	a0,88(s1)
    80001c3e:	c935                	beqz	a0,80001cb2 <allocproc+0xf2>
  p->pagetable = proc_pagetable(p);
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e38080e7          	jalr	-456(ra) # 80001a7a <proc_pagetable>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c4e:	cd35                	beqz	a0,80001cca <allocproc+0x10a>
  memset(&p->context, 0, sizeof(p->context));
    80001c50:	07000613          	li	a2,112
    80001c54:	4581                	li	a1,0
    80001c56:	06048513          	add	a0,s1,96
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	074080e7          	jalr	116(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c62:	00000797          	auipc	a5,0x0
    80001c66:	d8c78793          	add	a5,a5,-628 # 800019ee <forkret>
    80001c6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6c:	60bc                	ld	a5,64(s1)
    80001c6e:	6705                	lui	a4,0x1
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;     // Initialize runtime
    80001c74:	1604a423          	sw	zero,360(s1)
  p->etime = 0;     // Initialize exit time
    80001c78:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks; // Record creation time
    80001c7c:	00007797          	auipc	a5,0x7
    80001c80:	d747a783          	lw	a5,-652(a5) # 800089f0 <ticks>
    80001c84:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001c88:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001c8c:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001c90:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001c94:	2004a223          	sw	zero,516(s1)
  p->ticks = 0;
    80001c98:	2204a423          	sw	zero,552(s1)
  p->priority = 0;
    80001c9c:	2204a023          	sw	zero,544(s1)
  p->lastscheduledticks = 0;
    80001ca0:	2204a223          	sw	zero,548(s1)
}
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	60e2                	ld	ra,24(sp)
    80001ca8:	6442                	ld	s0,16(sp)
    80001caa:	64a2                	ld	s1,8(sp)
    80001cac:	6902                	ld	s2,0(sp)
    80001cae:	6105                	add	sp,sp,32
    80001cb0:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	eb4080e7          	jalr	-332(ra) # 80001b68 <freeproc>
    release(&p->lock); // Release lock
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	fc8080e7          	jalr	-56(ra) # 80000c86 <release>
    return 0;
    80001cc6:	84ca                	mv	s1,s2
    80001cc8:	bff1                	j	80001ca4 <allocproc+0xe4>
    freeproc(p);       // Clean up if allocation fails
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	e9c080e7          	jalr	-356(ra) # 80001b68 <freeproc>
    release(&p->lock); // Release lock
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	fb0080e7          	jalr	-80(ra) # 80000c86 <release>
    return 0;
    80001cde:	84ca                	mv	s1,s2
    80001ce0:	b7d1                	j	80001ca4 <allocproc+0xe4>

0000000080001ce2 <userinit>:
{
    80001ce2:	1101                	add	sp,sp,-32
    80001ce4:	ec06                	sd	ra,24(sp)
    80001ce6:	e822                	sd	s0,16(sp)
    80001ce8:	e426                	sd	s1,8(sp)
    80001cea:	1000                	add	s0,sp,32
  p = allocproc();
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	ed4080e7          	jalr	-300(ra) # 80001bc0 <allocproc>
    80001cf4:	84aa                	mv	s1,a0
  initproc = p;
    80001cf6:	00007797          	auipc	a5,0x7
    80001cfa:	cea7b923          	sd	a0,-782(a5) # 800089e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cfe:	03400613          	li	a2,52
    80001d02:	00007597          	auipc	a1,0x7
    80001d06:	c4e58593          	add	a1,a1,-946 # 80008950 <initcode>
    80001d0a:	6928                	ld	a0,80(a0)
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	644080e7          	jalr	1604(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001d14:	6785                	lui	a5,0x1
    80001d16:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d18:	6cb8                	ld	a4,88(s1)
    80001d1a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d1e:	6cb8                	ld	a4,88(s1)
    80001d20:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d22:	4641                	li	a2,16
    80001d24:	00006597          	auipc	a1,0x6
    80001d28:	4dc58593          	add	a1,a1,1244 # 80008200 <digits+0x1c0>
    80001d2c:	15848513          	add	a0,s1,344
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	0e6080e7          	jalr	230(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d38:	00006517          	auipc	a0,0x6
    80001d3c:	4d850513          	add	a0,a0,1240 # 80008210 <digits+0x1d0>
    80001d40:	00003097          	auipc	ra,0x3
    80001d44:	ebc080e7          	jalr	-324(ra) # 80004bfc <namei>
    80001d48:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d4c:	478d                	li	a5,3
    80001d4e:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001d50:	4785                	li	a5,1
    80001d52:	20f4a823          	sw	a5,528(s1)
  release(&p->lock);
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	f2e080e7          	jalr	-210(ra) # 80000c86 <release>
}
    80001d60:	60e2                	ld	ra,24(sp)
    80001d62:	6442                	ld	s0,16(sp)
    80001d64:	64a2                	ld	s1,8(sp)
    80001d66:	6105                	add	sp,sp,32
    80001d68:	8082                	ret

0000000080001d6a <growproc>:
{
    80001d6a:	1101                	add	sp,sp,-32
    80001d6c:	ec06                	sd	ra,24(sp)
    80001d6e:	e822                	sd	s0,16(sp)
    80001d70:	e426                	sd	s1,8(sp)
    80001d72:	e04a                	sd	s2,0(sp)
    80001d74:	1000                	add	s0,sp,32
    80001d76:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	c3e080e7          	jalr	-962(ra) # 800019b6 <myproc>
    80001d80:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d82:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d84:	01204c63          	bgtz	s2,80001d9c <growproc+0x32>
  else if (n < 0)
    80001d88:	02094663          	bltz	s2,80001db4 <growproc+0x4a>
  p->sz = sz;
    80001d8c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d8e:	4501                	li	a0,0
}
    80001d90:	60e2                	ld	ra,24(sp)
    80001d92:	6442                	ld	s0,16(sp)
    80001d94:	64a2                	ld	s1,8(sp)
    80001d96:	6902                	ld	s2,0(sp)
    80001d98:	6105                	add	sp,sp,32
    80001d9a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d9c:	4691                	li	a3,4
    80001d9e:	00b90633          	add	a2,s2,a1
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	666080e7          	jalr	1638(ra) # 8000140a <uvmalloc>
    80001dac:	85aa                	mv	a1,a0
    80001dae:	fd79                	bnez	a0,80001d8c <growproc+0x22>
      return -1;
    80001db0:	557d                	li	a0,-1
    80001db2:	bff9                	j	80001d90 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db4:	00b90633          	add	a2,s2,a1
    80001db8:	6928                	ld	a0,80(a0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	608080e7          	jalr	1544(ra) # 800013c2 <uvmdealloc>
    80001dc2:	85aa                	mv	a1,a0
    80001dc4:	b7e1                	j	80001d8c <growproc+0x22>

0000000080001dc6 <fork>:
{
    80001dc6:	7139                	add	sp,sp,-64
    80001dc8:	fc06                	sd	ra,56(sp)
    80001dca:	f822                	sd	s0,48(sp)
    80001dcc:	f426                	sd	s1,40(sp)
    80001dce:	f04a                	sd	s2,32(sp)
    80001dd0:	ec4e                	sd	s3,24(sp)
    80001dd2:	e852                	sd	s4,16(sp)
    80001dd4:	e456                	sd	s5,8(sp)
    80001dd6:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	bde080e7          	jalr	-1058(ra) # 800019b6 <myproc>
    80001de0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	dde080e7          	jalr	-546(ra) # 80001bc0 <allocproc>
    80001dea:	12050663          	beqz	a0,80001f16 <fork+0x150>
    80001dee:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001df0:	048ab603          	ld	a2,72(s5)
    80001df4:	692c                	ld	a1,80(a0)
    80001df6:	050ab503          	ld	a0,80(s5)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	768080e7          	jalr	1896(ra) # 80001562 <uvmcopy>
    80001e02:	06054263          	bltz	a0,80001e66 <fork+0xa0>
  np->sz = p->sz;
    80001e06:	048ab783          	ld	a5,72(s5)
    80001e0a:	04f9b423          	sd	a5,72(s3)
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
    80001e0e:	210aa783          	lw	a5,528(s5)
    80001e12:	20f9a823          	sw	a5,528(s3)
  np->creation_time = ticks; // record its creation time
    80001e16:	00007797          	auipc	a5,0x7
    80001e1a:	bda7e783          	lwu	a5,-1062(a5) # 800089f0 <ticks>
    80001e1e:	20f9bc23          	sd	a5,536(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e22:	058ab683          	ld	a3,88(s5)
    80001e26:	87b6                	mv	a5,a3
    80001e28:	0589b703          	ld	a4,88(s3)
    80001e2c:	12068693          	add	a3,a3,288
    80001e30:	0007b803          	ld	a6,0(a5)
    80001e34:	6788                	ld	a0,8(a5)
    80001e36:	6b8c                	ld	a1,16(a5)
    80001e38:	6f90                	ld	a2,24(a5)
    80001e3a:	01073023          	sd	a6,0(a4)
    80001e3e:	e708                	sd	a0,8(a4)
    80001e40:	eb0c                	sd	a1,16(a4)
    80001e42:	ef10                	sd	a2,24(a4)
    80001e44:	02078793          	add	a5,a5,32
    80001e48:	02070713          	add	a4,a4,32
    80001e4c:	fed792e3          	bne	a5,a3,80001e30 <fork+0x6a>
  np->trapframe->a0 = 0;
    80001e50:	0589b783          	ld	a5,88(s3)
    80001e54:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e58:	0d0a8493          	add	s1,s5,208
    80001e5c:	0d098913          	add	s2,s3,208
    80001e60:	150a8a13          	add	s4,s5,336
    80001e64:	a00d                	j	80001e86 <fork+0xc0>
    freeproc(np);
    80001e66:	854e                	mv	a0,s3
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	d00080e7          	jalr	-768(ra) # 80001b68 <freeproc>
    release(&np->lock);
    80001e70:	854e                	mv	a0,s3
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	e14080e7          	jalr	-492(ra) # 80000c86 <release>
    return -1;
    80001e7a:	597d                	li	s2,-1
    80001e7c:	a059                	j	80001f02 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    80001e7e:	04a1                	add	s1,s1,8
    80001e80:	0921                	add	s2,s2,8
    80001e82:	01448b63          	beq	s1,s4,80001e98 <fork+0xd2>
    if (p->ofile[i])
    80001e86:	6088                	ld	a0,0(s1)
    80001e88:	d97d                	beqz	a0,80001e7e <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e8a:	00003097          	auipc	ra,0x3
    80001e8e:	3e4080e7          	jalr	996(ra) # 8000526e <filedup>
    80001e92:	00a93023          	sd	a0,0(s2)
    80001e96:	b7e5                	j	80001e7e <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e98:	150ab503          	ld	a0,336(s5)
    80001e9c:	00002097          	auipc	ra,0x2
    80001ea0:	57c080e7          	jalr	1404(ra) # 80004418 <idup>
    80001ea4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea8:	4641                	li	a2,16
    80001eaa:	158a8593          	add	a1,s5,344
    80001eae:	15898513          	add	a0,s3,344
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	f64080e7          	jalr	-156(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001eba:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001ebe:	854e                	mv	a0,s3
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dc6080e7          	jalr	-570(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001ec8:	0000f497          	auipc	s1,0xf
    80001ecc:	db048493          	add	s1,s1,-592 # 80010c78 <wait_lock>
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	d00080e7          	jalr	-768(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001eda:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	da6080e7          	jalr	-602(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	ce8080e7          	jalr	-792(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001ef2:	478d                	li	a5,3
    80001ef4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ef8:	854e                	mv	a0,s3
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d8c080e7          	jalr	-628(ra) # 80000c86 <release>
}
    80001f02:	854a                	mv	a0,s2
    80001f04:	70e2                	ld	ra,56(sp)
    80001f06:	7442                	ld	s0,48(sp)
    80001f08:	74a2                	ld	s1,40(sp)
    80001f0a:	7902                	ld	s2,32(sp)
    80001f0c:	69e2                	ld	s3,24(sp)
    80001f0e:	6a42                	ld	s4,16(sp)
    80001f10:	6aa2                	ld	s5,8(sp)
    80001f12:	6121                	add	sp,sp,64
    80001f14:	8082                	ret
    return -1;
    80001f16:	597d                	li	s2,-1
    80001f18:	b7ed                	j	80001f02 <fork+0x13c>

0000000080001f1a <simple_atol>:
{
    80001f1a:	1141                	add	sp,sp,-16
    80001f1c:	e422                	sd	s0,8(sp)
    80001f1e:	0800                	add	s0,sp,16
  for (int i = 0; str[i] != '\0'; ++i)
    80001f20:	00054683          	lbu	a3,0(a0)
    80001f24:	c295                	beqz	a3,80001f48 <simple_atol+0x2e>
    80001f26:	00150713          	add	a4,a0,1
  long res = 0;
    80001f2a:	4501                	li	a0,0
    res = res * 10 + str[i] - '0';
    80001f2c:	00251793          	sll	a5,a0,0x2
    80001f30:	97aa                	add	a5,a5,a0
    80001f32:	0786                	sll	a5,a5,0x1
    80001f34:	97b6                	add	a5,a5,a3
    80001f36:	fd078513          	add	a0,a5,-48
  for (int i = 0; str[i] != '\0'; ++i)
    80001f3a:	0705                	add	a4,a4,1
    80001f3c:	fff74683          	lbu	a3,-1(a4)
    80001f40:	f6f5                	bnez	a3,80001f2c <simple_atol+0x12>
}
    80001f42:	6422                	ld	s0,8(sp)
    80001f44:	0141                	add	sp,sp,16
    80001f46:	8082                	ret
  long res = 0;
    80001f48:	4501                	li	a0,0
  return res;
    80001f4a:	bfe5                	j	80001f42 <simple_atol+0x28>

0000000080001f4c <get_random_seed>:
{
    80001f4c:	1141                	add	sp,sp,-16
    80001f4e:	e422                	sd	s0,8(sp)
    80001f50:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80001f52:	00007697          	auipc	a3,0x7
    80001f56:	9e668693          	add	a3,a3,-1562 # 80008938 <seed>
    80001f5a:	629c                	ld	a5,0(a3)
    80001f5c:	41c65737          	lui	a4,0x41c65
    80001f60:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80001f64:	02e787b3          	mul	a5,a5,a4
    80001f68:	670d                	lui	a4,0x3
    80001f6a:	03970713          	add	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80001f6e:	97ba                	add	a5,a5,a4
    80001f70:	1786                	sll	a5,a5,0x21
    80001f72:	9385                	srl	a5,a5,0x21
    80001f74:	e29c                	sd	a5,0(a3)
}
    80001f76:	6509                	lui	a0,0x2
    80001f78:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    80001f7c:	02a7f533          	remu	a0,a5,a0
    80001f80:	6422                	ld	s0,8(sp)
    80001f82:	0141                	add	sp,sp,16
    80001f84:	8082                	ret

0000000080001f86 <long_to_padded_string>:
{
    80001f86:	1141                	add	sp,sp,-16
    80001f88:	e422                	sd	s0,8(sp)
    80001f8a:	0800                	add	s0,sp,16
  long temp = num;
    80001f8c:	87aa                	mv	a5,a0
  int len = 0;
    80001f8e:	4681                	li	a3,0
    temp /= 10;
    80001f90:	4329                	li	t1,10
  } while (temp > 0);
    80001f92:	48a5                	li	a7,9
    len++;
    80001f94:	0016871b          	addw	a4,a3,1
    80001f98:	0007069b          	sext.w	a3,a4
    temp /= 10;
    80001f9c:	883e                	mv	a6,a5
    80001f9e:	0267c7b3          	div	a5,a5,t1
  } while (temp > 0);
    80001fa2:	ff08c9e3          	blt	a7,a6,80001f94 <long_to_padded_string+0xe>
  int padding = total_length - len;
    80001fa6:	40e5873b          	subw	a4,a1,a4
    80001faa:	0007089b          	sext.w	a7,a4
  for (int i = 0; i < padding; i++)
    80001fae:	01105c63          	blez	a7,80001fc6 <long_to_padded_string+0x40>
    80001fb2:	87b2                	mv	a5,a2
    80001fb4:	00c88833          	add	a6,a7,a2
    result[i] = '0';
    80001fb8:	03000693          	li	a3,48
    80001fbc:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < padding; i++)
    80001fc0:	0785                	add	a5,a5,1
    80001fc2:	ff079de3          	bne	a5,a6,80001fbc <long_to_padded_string+0x36>
  for (int i = total_length - 1; i >= padding; i--)
    80001fc6:	fff5879b          	addw	a5,a1,-1
    80001fca:	0317ca63          	blt	a5,a7,80001ffe <long_to_padded_string+0x78>
    80001fce:	97b2                	add	a5,a5,a2
    80001fd0:	ffe60813          	add	a6,a2,-2 # ffe <_entry-0x7ffff002>
    80001fd4:	982e                	add	a6,a6,a1
    80001fd6:	fff5869b          	addw	a3,a1,-1
    80001fda:	40e6873b          	subw	a4,a3,a4
    80001fde:	1702                	sll	a4,a4,0x20
    80001fe0:	9301                	srl	a4,a4,0x20
    80001fe2:	40e80833          	sub	a6,a6,a4
    result[i] = (num % 10) + '0';
    80001fe6:	46a9                	li	a3,10
    80001fe8:	02d56733          	rem	a4,a0,a3
    80001fec:	0307071b          	addw	a4,a4,48
    80001ff0:	00e78023          	sb	a4,0(a5)
    num /= 10;
    80001ff4:	02d54533          	div	a0,a0,a3
  for (int i = total_length - 1; i >= padding; i--)
    80001ff8:	17fd                	add	a5,a5,-1
    80001ffa:	ff0797e3          	bne	a5,a6,80001fe8 <long_to_padded_string+0x62>
  result[total_length] = '\0'; // Null-terminate the string
    80001ffe:	962e                	add	a2,a2,a1
    80002000:	00060023          	sb	zero,0(a2)
}
    80002004:	6422                	ld	s0,8(sp)
    80002006:	0141                	add	sp,sp,16
    80002008:	8082                	ret

000000008000200a <pseudo_rand_num_generator>:
{
    8000200a:	7119                	add	sp,sp,-128
    8000200c:	fc86                	sd	ra,120(sp)
    8000200e:	f8a2                	sd	s0,112(sp)
    80002010:	f4a6                	sd	s1,104(sp)
    80002012:	f0ca                	sd	s2,96(sp)
    80002014:	ecce                	sd	s3,88(sp)
    80002016:	e8d2                	sd	s4,80(sp)
    80002018:	e4d6                	sd	s5,72(sp)
    8000201a:	e0da                	sd	s6,64(sp)
    8000201c:	fc5e                	sd	s7,56(sp)
    8000201e:	f862                	sd	s8,48(sp)
    80002020:	f466                	sd	s9,40(sp)
    80002022:	0100                	add	s0,sp,128
    80002024:	84aa                	mv	s1,a0
    80002026:	8aae                	mv	s5,a1
  if (iterations == 0 && lst_index > 0)
    80002028:	e1a1                	bnez	a1,80002068 <pseudo_rand_num_generator+0x5e>
    8000202a:	00007797          	auipc	a5,0x7
    8000202e:	9b27a783          	lw	a5,-1614(a5) # 800089dc <lst_index>
    80002032:	02f04263          	bgtz	a5,80002056 <pseudo_rand_num_generator+0x4c>
  int seed_size = strlen(initial_seed);
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	e12080e7          	jalr	-494(ra) # 80000e48 <strlen>
    8000203e:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002040:	8526                	mv	a0,s1
    80002042:	00000097          	auipc	ra,0x0
    80002046:	ed8080e7          	jalr	-296(ra) # 80001f1a <simple_atol>
  if (seed_val == 0)
    8000204a:	e561                	bnez	a0,80002112 <pseudo_rand_num_generator+0x108>
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	f00080e7          	jalr	-256(ra) # 80001f4c <get_random_seed>
    80002054:	a02d                	j	8000207e <pseudo_rand_num_generator+0x74>
    return lst[lst_index - 1]; // Return the last generated number
    80002056:	37fd                	addw	a5,a5,-1
    80002058:	078a                	sll	a5,a5,0x2
    8000205a:	0000f717          	auipc	a4,0xf
    8000205e:	03670713          	add	a4,a4,54 # 80011090 <lst>
    80002062:	97ba                	add	a5,a5,a4
    80002064:	4388                	lw	a0,0(a5)
    80002066:	a0d1                	j	8000212a <pseudo_rand_num_generator+0x120>
  int seed_size = strlen(initial_seed);
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	de0080e7          	jalr	-544(ra) # 80000e48 <strlen>
    80002070:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002072:	8526                	mv	a0,s1
    80002074:	00000097          	auipc	ra,0x0
    80002078:	ea6080e7          	jalr	-346(ra) # 80001f1a <simple_atol>
  if (seed_val == 0)
    8000207c:	d961                	beqz	a0,8000204c <pseudo_rand_num_generator+0x42>
  for (int i = 0; i < iterations; i++)
    8000207e:	09505a63          	blez	s5,80002112 <pseudo_rand_num_generator+0x108>
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    80002082:	00191c9b          	sllw	s9,s2,0x1
    int mid_start = seed_size / 2;
    80002086:	01f9579b          	srlw	a5,s2,0x1f
    8000208a:	012787bb          	addw	a5,a5,s2
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    8000208e:	4017d79b          	sraw	a5,a5,0x1
    80002092:	f8040713          	add	a4,s0,-128
    80002096:	00f70bb3          	add	s7,a4,a5
    8000209a:	4481                	li	s1,0
    char new_seed[seed_size + 1];
    8000209c:	00190b1b          	addw	s6,s2,1
    800020a0:	0b3d                	add	s6,s6,15
    800020a2:	ff0b7b13          	and	s6,s6,-16
    lst[lst_index++] = simple_atol(new_seed);
    800020a6:	00007997          	auipc	s3,0x7
    800020aa:	93698993          	add	s3,s3,-1738 # 800089dc <lst_index>
    800020ae:	0000fc17          	auipc	s8,0xf
    800020b2:	fe2c0c13          	add	s8,s8,-30 # 80011090 <lst>
  {
    800020b6:	8a0a                	mv	s4,sp
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    800020b8:	f8040613          	add	a2,s0,-128
    800020bc:	85e6                	mv	a1,s9
    800020be:	02a50533          	mul	a0,a0,a0
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	ec4080e7          	jalr	-316(ra) # 80001f86 <long_to_padded_string>
    char new_seed[seed_size + 1];
    800020ca:	41610133          	sub	sp,sp,s6
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800020ce:	864a                	mv	a2,s2
    800020d0:	85de                	mv	a1,s7
    800020d2:	850a                	mv	a0,sp
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	d06080e7          	jalr	-762(ra) # 80000dda <strncpy>
    new_seed[seed_size] = '\0';                         // Null-terminate
    800020dc:	012107b3          	add	a5,sp,s2
    800020e0:	00078023          	sb	zero,0(a5)
    lst[lst_index++] = simple_atol(new_seed);
    800020e4:	850a                	mv	a0,sp
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	e34080e7          	jalr	-460(ra) # 80001f1a <simple_atol>
    800020ee:	0009a783          	lw	a5,0(s3)
    800020f2:	0017871b          	addw	a4,a5,1
    800020f6:	00e9a023          	sw	a4,0(s3)
    800020fa:	078a                	sll	a5,a5,0x2
    800020fc:	97e2                	add	a5,a5,s8
    800020fe:	c388                	sw	a0,0(a5)
    seed_val = simple_atol(new_seed);
    80002100:	850a                	mv	a0,sp
    80002102:	00000097          	auipc	ra,0x0
    80002106:	e18080e7          	jalr	-488(ra) # 80001f1a <simple_atol>
    8000210a:	8152                	mv	sp,s4
  for (int i = 0; i < iterations; i++)
    8000210c:	2485                	addw	s1,s1,1
    8000210e:	fa9a94e3          	bne	s5,s1,800020b6 <pseudo_rand_num_generator+0xac>
  return lst[lst_index - 1];
    80002112:	00007797          	auipc	a5,0x7
    80002116:	8ca7a783          	lw	a5,-1846(a5) # 800089dc <lst_index>
    8000211a:	37fd                	addw	a5,a5,-1
    8000211c:	078a                	sll	a5,a5,0x2
    8000211e:	0000f717          	auipc	a4,0xf
    80002122:	f7270713          	add	a4,a4,-142 # 80011090 <lst>
    80002126:	97ba                	add	a5,a5,a4
    80002128:	4388                	lw	a0,0(a5)
}
    8000212a:	f8040113          	add	sp,s0,-128
    8000212e:	70e6                	ld	ra,120(sp)
    80002130:	7446                	ld	s0,112(sp)
    80002132:	74a6                	ld	s1,104(sp)
    80002134:	7906                	ld	s2,96(sp)
    80002136:	69e6                	ld	s3,88(sp)
    80002138:	6a46                	ld	s4,80(sp)
    8000213a:	6aa6                	ld	s5,72(sp)
    8000213c:	6b06                	ld	s6,64(sp)
    8000213e:	7be2                	ld	s7,56(sp)
    80002140:	7c42                	ld	s8,48(sp)
    80002142:	7ca2                	ld	s9,40(sp)
    80002144:	6109                	add	sp,sp,128
    80002146:	8082                	ret

0000000080002148 <int_to_string>:
{
    80002148:	1141                	add	sp,sp,-16
    8000214a:	e422                	sd	s0,8(sp)
    8000214c:	0800                	add	s0,sp,16
  int temp = num;
    8000214e:	872a                	mv	a4,a0
  int len = 0;
    80002150:	4781                	li	a5,0
    temp /= 10;
    80002152:	48a9                	li	a7,10
  } while (temp > 0);
    80002154:	4825                	li	a6,9
    len++;
    80002156:	863e                	mv	a2,a5
    80002158:	2785                	addw	a5,a5,1
    temp /= 10;
    8000215a:	86ba                	mv	a3,a4
    8000215c:	0317473b          	divw	a4,a4,a7
  } while (temp > 0);
    80002160:	fed84be3          	blt	a6,a3,80002156 <int_to_string+0xe>
  result[len] = '\0'; // Null-terminate the string
    80002164:	97ae                	add	a5,a5,a1
    80002166:	00078023          	sb	zero,0(a5)
  for (int i = len - 1; i >= 0; i--)
    8000216a:	02064663          	bltz	a2,80002196 <int_to_string+0x4e>
    8000216e:	00c587b3          	add	a5,a1,a2
    80002172:	fff58693          	add	a3,a1,-1
    80002176:	96b2                	add	a3,a3,a2
    80002178:	1602                	sll	a2,a2,0x20
    8000217a:	9201                	srl	a2,a2,0x20
    8000217c:	8e91                	sub	a3,a3,a2
    result[i] = (num % 10) + '0';
    8000217e:	4629                	li	a2,10
    80002180:	02c5673b          	remw	a4,a0,a2
    80002184:	0307071b          	addw	a4,a4,48
    80002188:	00e78023          	sb	a4,0(a5)
    num /= 10;
    8000218c:	02c5453b          	divw	a0,a0,a2
  for (int i = len - 1; i >= 0; i--)
    80002190:	17fd                	add	a5,a5,-1
    80002192:	fed797e3          	bne	a5,a3,80002180 <int_to_string+0x38>
}
    80002196:	6422                	ld	s0,8(sp)
    80002198:	0141                	add	sp,sp,16
    8000219a:	8082                	ret

000000008000219c <simple_rand>:
{
    8000219c:	1141                	add	sp,sp,-16
    8000219e:	e422                	sd	s0,8(sp)
    800021a0:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    800021a2:	00006697          	auipc	a3,0x6
    800021a6:	79668693          	add	a3,a3,1942 # 80008938 <seed>
    800021aa:	629c                	ld	a5,0(a3)
    800021ac:	41c65737          	lui	a4,0x41c65
    800021b0:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    800021b4:	02e787b3          	mul	a5,a5,a4
    800021b8:	0012d737          	lui	a4,0x12d
    800021bc:	68770713          	add	a4,a4,1671 # 12d687 <_entry-0x7fed2979>
    800021c0:	97ba                	add	a5,a5,a4
    800021c2:	1786                	sll	a5,a5,0x21
    800021c4:	9385                	srl	a5,a5,0x21
    800021c6:	e29c                	sd	a5,0(a3)
}
    800021c8:	6509                	lui	a0,0x2
    800021ca:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    800021ce:	02a7f533          	remu	a0,a5,a0
    800021d2:	6422                	ld	s0,8(sp)
    800021d4:	0141                	add	sp,sp,16
    800021d6:	8082                	ret

00000000800021d8 <random_at_most>:
{
    800021d8:	1101                	add	sp,sp,-32
    800021da:	ec06                	sd	ra,24(sp)
    800021dc:	e822                	sd	s0,16(sp)
    800021de:	e426                	sd	s1,8(sp)
    800021e0:	1000                	add	s0,sp,32
    800021e2:	84aa                	mv	s1,a0
  int random_num = simple_rand(); // Use the LCG for random generation
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	fb8080e7          	jalr	-72(ra) # 8000219c <simple_rand>
  return 1 + (random_num % max);  // Return a number in the range [1, max]
    800021ec:	0295653b          	remw	a0,a0,s1
}
    800021f0:	2505                	addw	a0,a0,1
    800021f2:	60e2                	ld	ra,24(sp)
    800021f4:	6442                	ld	s0,16(sp)
    800021f6:	64a2                	ld	s1,8(sp)
    800021f8:	6105                	add	sp,sp,32
    800021fa:	8082                	ret

00000000800021fc <round_robin_scheduler>:
{
    800021fc:	7139                	add	sp,sp,-64
    800021fe:	fc06                	sd	ra,56(sp)
    80002200:	f822                	sd	s0,48(sp)
    80002202:	f426                	sd	s1,40(sp)
    80002204:	f04a                	sd	s2,32(sp)
    80002206:	ec4e                	sd	s3,24(sp)
    80002208:	e852                	sd	s4,16(sp)
    8000220a:	e456                	sd	s5,8(sp)
    8000220c:	e05a                	sd	s6,0(sp)
    8000220e:	0080                	add	s0,sp,64
    80002210:	8792                	mv	a5,tp
  int id = r_tp();
    80002212:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002214:	00779a93          	sll	s5,a5,0x7
    80002218:	0000f717          	auipc	a4,0xf
    8000221c:	a4870713          	add	a4,a4,-1464 # 80010c60 <pid_lock>
    80002220:	9756                	add	a4,a4,s5
    80002222:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002226:	0000f717          	auipc	a4,0xf
    8000222a:	a7270713          	add	a4,a4,-1422 # 80010c98 <cpus+0x8>
    8000222e:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002230:	498d                	li	s3,3
        p->state = RUNNING;
    80002232:	4b11                	li	s6,4
        c->proc = p;
    80002234:	079e                	sll	a5,a5,0x7
    80002236:	0000fa17          	auipc	s4,0xf
    8000223a:	a2aa0a13          	add	s4,s4,-1494 # 80010c60 <pid_lock>
    8000223e:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002240:	00019917          	auipc	s2,0x19
    80002244:	9f090913          	add	s2,s2,-1552 # 8001ac30 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002248:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000224c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002250:	10079073          	csrw	sstatus,a5
    80002254:	00010497          	auipc	s1,0x10
    80002258:	ddc48493          	add	s1,s1,-548 # 80012030 <proc>
    8000225c:	a811                	j	80002270 <round_robin_scheduler+0x74>
      release(&p->lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a26080e7          	jalr	-1498(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002268:	23048493          	add	s1,s1,560
    8000226c:	fd248ee3          	beq	s1,s2,80002248 <round_robin_scheduler+0x4c>
      acquire(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	960080e7          	jalr	-1696(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000227a:	4c9c                	lw	a5,24(s1)
    8000227c:	ff3791e3          	bne	a5,s3,8000225e <round_robin_scheduler+0x62>
        p->state = RUNNING;
    80002280:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002284:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002288:	06048593          	add	a1,s1,96
    8000228c:	8556                	mv	a0,s5
    8000228e:	00001097          	auipc	ra,0x1
    80002292:	c3e080e7          	jalr	-962(ra) # 80002ecc <swtch>
        c->proc = 0;
    80002296:	020a3823          	sd	zero,48(s4)
    8000229a:	b7d1                	j	8000225e <round_robin_scheduler+0x62>

000000008000229c <lottery_scheduler>:
{
    8000229c:	715d                	add	sp,sp,-80
    8000229e:	e486                	sd	ra,72(sp)
    800022a0:	e0a2                	sd	s0,64(sp)
    800022a2:	fc26                	sd	s1,56(sp)
    800022a4:	f84a                	sd	s2,48(sp)
    800022a6:	f44e                	sd	s3,40(sp)
    800022a8:	f052                	sd	s4,32(sp)
    800022aa:	ec56                	sd	s5,24(sp)
    800022ac:	e85a                	sd	s6,16(sp)
    800022ae:	e45e                	sd	s7,8(sp)
    800022b0:	e062                	sd	s8,0(sp)
    800022b2:	0880                	add	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800022b4:	8792                	mv	a5,tp
  int id = r_tp();
    800022b6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022b8:	00779693          	sll	a3,a5,0x7
    800022bc:	0000f717          	auipc	a4,0xf
    800022c0:	9a470713          	add	a4,a4,-1628 # 80010c60 <pid_lock>
    800022c4:	9736                	add	a4,a4,a3
    800022c6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &winner->context);
    800022ca:	0000f717          	auipc	a4,0xf
    800022ce:	9ce70713          	add	a4,a4,-1586 # 80010c98 <cpus+0x8>
    800022d2:	00e68c33          	add	s8,a3,a4
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    800022d6:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800022d8:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800022da:	00019917          	auipc	s2,0x19
    800022de:	95690913          	add	s2,s2,-1706 # 8001ac30 <tickslock>
        c->proc = winner;
    800022e2:	0000fb17          	auipc	s6,0xf
    800022e6:	97eb0b13          	add	s6,s6,-1666 # 80010c60 <pid_lock>
    800022ea:	9b36                	add	s6,s6,a3
    800022ec:	a80d                	j	8000231e <lottery_scheduler+0x82>
      release(&p->lock);
    800022ee:	8526                	mv	a0,s1
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	996080e7          	jalr	-1642(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022f8:	23048493          	add	s1,s1,560
    800022fc:	01248f63          	beq	s1,s2,8000231a <lottery_scheduler+0x7e>
      acquire(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	8d0080e7          	jalr	-1840(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000230a:	4c9c                	lw	a5,24(s1)
    8000230c:	ff3791e3          	bne	a5,s3,800022ee <lottery_scheduler+0x52>
        total_tickets += p->tickets; // Accumulate total tickets
    80002310:	2104a783          	lw	a5,528(s1)
    80002314:	01478a3b          	addw	s4,a5,s4
    80002318:	bfd9                	j	800022ee <lottery_scheduler+0x52>
    if (total_tickets == 0)
    8000231a:	000a1e63          	bnez	s4,80002336 <lottery_scheduler+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002322:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002326:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    8000232a:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    8000232c:	00010497          	auipc	s1,0x10
    80002330:	d0448493          	add	s1,s1,-764 # 80012030 <proc>
    80002334:	b7f1                	j	80002300 <lottery_scheduler+0x64>
    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    80002336:	8552                	mv	a0,s4
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	ea0080e7          	jalr	-352(ra) # 800021d8 <random_at_most>
    80002340:	8baa                	mv	s7,a0
    int ticket_counter = 0;                             // Track ticket count while iterating over processes
    80002342:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002344:	00010497          	auipc	s1,0x10
    80002348:	cec48493          	add	s1,s1,-788 # 80012030 <proc>
    8000234c:	a811                	j	80002360 <lottery_scheduler+0xc4>
      release(&p->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	936080e7          	jalr	-1738(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002358:	23048493          	add	s1,s1,560
    8000235c:	fd2481e3          	beq	s1,s2,8000231e <lottery_scheduler+0x82>
      if (p == 0)
    80002360:	dce5                	beqz	s1,80002358 <lottery_scheduler+0xbc>
      acquire(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	86e080e7          	jalr	-1938(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000236c:	4c9c                	lw	a5,24(s1)
    8000236e:	ff3790e3          	bne	a5,s3,8000234e <lottery_scheduler+0xb2>
        ticket_counter += p->tickets; // Increment the ticket counter
    80002372:	2104a783          	lw	a5,528(s1)
    80002376:	01478a3b          	addw	s4,a5,s4
        if (ticket_counter >= winning_ticket)
    8000237a:	fd7a4ae3          	blt	s4,s7,8000234e <lottery_scheduler+0xb2>
            release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	906080e7          	jalr	-1786(ra) # 80000c86 <release>
      acquire(&winner->lock);
    80002388:	8a26                	mv	s4,s1
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	846080e7          	jalr	-1978(ra) # 80000bd2 <acquire>
      if (winner->state == RUNNABLE)
    80002394:	4c9c                	lw	a5,24(s1)
    80002396:	01378863          	beq	a5,s3,800023a6 <lottery_scheduler+0x10a>
      release(&winner->lock);
    8000239a:	8552                	mv	a0,s4
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8ea080e7          	jalr	-1814(ra) # 80000c86 <release>
    800023a4:	bfad                	j	8000231e <lottery_scheduler+0x82>
        winner->state = RUNNING;
    800023a6:	4791                	li	a5,4
    800023a8:	cc9c                	sw	a5,24(s1)
        c->proc = winner;
    800023aa:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &winner->context);
    800023ae:	06048593          	add	a1,s1,96
    800023b2:	8562                	mv	a0,s8
    800023b4:	00001097          	auipc	ra,0x1
    800023b8:	b18080e7          	jalr	-1256(ra) # 80002ecc <swtch>
        c->proc = 0;
    800023bc:	020b3823          	sd	zero,48(s6)
    800023c0:	bfe9                	j	8000239a <lottery_scheduler+0xfe>

00000000800023c2 <get_ticks_for_priority>:
{
    800023c2:	1141                	add	sp,sp,-16
    800023c4:	e422                	sd	s0,8(sp)
    800023c6:	0800                	add	s0,sp,16
  switch (priority)
    800023c8:	4709                	li	a4,2
    800023ca:	00e50f63          	beq	a0,a4,800023e8 <get_ticks_for_priority+0x26>
    800023ce:	87aa                	mv	a5,a0
    800023d0:	470d                	li	a4,3
    return TICKS_3; // 16 ticks for priority 3
    800023d2:	4541                	li	a0,16
  switch (priority)
    800023d4:	00e78763          	beq	a5,a4,800023e2 <get_ticks_for_priority+0x20>
    800023d8:	4705                	li	a4,1
    800023da:	4511                	li	a0,4
    800023dc:	00e78363          	beq	a5,a4,800023e2 <get_ticks_for_priority+0x20>
    return TICKS_0; // 1 tick for priority 0
    800023e0:	4505                	li	a0,1
}
    800023e2:	6422                	ld	s0,8(sp)
    800023e4:	0141                	add	sp,sp,16
    800023e6:	8082                	ret
    return TICKS_2; // 8 ticks for priority 2
    800023e8:	4521                	li	a0,8
    800023ea:	bfe5                	j	800023e2 <get_ticks_for_priority+0x20>

00000000800023ec <priority_boost>:
{
    800023ec:	1141                	add	sp,sp,-16
    800023ee:	e422                	sd	s0,8(sp)
    800023f0:	0800                	add	s0,sp,16
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800023f2:	00010797          	auipc	a5,0x10
    800023f6:	c3e78793          	add	a5,a5,-962 # 80012030 <proc>
    if (p->state == RUNNABLE)
    800023fa:	460d                	li	a2,3
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800023fc:	00019697          	auipc	a3,0x19
    80002400:	83468693          	add	a3,a3,-1996 # 8001ac30 <tickslock>
    80002404:	a029                	j	8000240e <priority_boost+0x22>
    80002406:	23078793          	add	a5,a5,560
    8000240a:	00d78c63          	beq	a5,a3,80002422 <priority_boost+0x36>
    if (p->state == RUNNABLE)
    8000240e:	4f98                	lw	a4,24(a5)
    80002410:	fec71be3          	bne	a4,a2,80002406 <priority_boost+0x1a>
      p->priority = 0;           // Boost process to the highest priority
    80002414:	2207a023          	sw	zero,544(a5)
      p->ticks = 0;              // Reset process ticks
    80002418:	2207a423          	sw	zero,552(a5)
      p->lastscheduledticks = 0; // Reset last scheduled ticks
    8000241c:	2207a223          	sw	zero,548(a5)
    80002420:	b7dd                	j	80002406 <priority_boost+0x1a>
}
    80002422:	6422                	ld	s0,8(sp)
    80002424:	0141                	add	sp,sp,16
    80002426:	8082                	ret

0000000080002428 <mlfq_scheduler>:
{
    80002428:	711d                	add	sp,sp,-96
    8000242a:	ec86                	sd	ra,88(sp)
    8000242c:	e8a2                	sd	s0,80(sp)
    8000242e:	e4a6                	sd	s1,72(sp)
    80002430:	e0ca                	sd	s2,64(sp)
    80002432:	fc4e                	sd	s3,56(sp)
    80002434:	f852                	sd	s4,48(sp)
    80002436:	f456                	sd	s5,40(sp)
    80002438:	f05a                	sd	s6,32(sp)
    8000243a:	ec5e                	sd	s7,24(sp)
    8000243c:	e862                	sd	s8,16(sp)
    8000243e:	e466                	sd	s9,8(sp)
    80002440:	e06a                	sd	s10,0(sp)
    80002442:	1080                	add	s0,sp,96
  printf("hi");
    80002444:	00006517          	auipc	a0,0x6
    80002448:	dd450513          	add	a0,a0,-556 # 80008218 <digits+0x1d8>
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	13a080e7          	jalr	314(ra) # 80000586 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002454:	8c92                	mv	s9,tp
  int id = r_tp();
    80002456:	2c81                	sext.w	s9,s9
  c->proc = 0;
    80002458:	007c9713          	sll	a4,s9,0x7
    8000245c:	0000f797          	auipc	a5,0xf
    80002460:	80478793          	add	a5,a5,-2044 # 80010c60 <pid_lock>
    80002464:	97ba                	add	a5,a5,a4
    80002466:	0207b823          	sd	zero,48(a5)
    if (ticks - last_boost_ticks >= BOOST_INTERVAL)
    8000246a:	00006b17          	auipc	s6,0x6
    8000246e:	586b0b13          	add	s6,s6,1414 # 800089f0 <ticks>
    80002472:	00006a97          	auipc	s5,0x6
    80002476:	566a8a93          	add	s5,s5,1382 # 800089d8 <last_boost_ticks>
    8000247a:	02f00b93          	li	s7,47
      printf("Boosting priorities at ticks = %d\n", ticks);
    8000247e:	00006c17          	auipc	s8,0x6
    80002482:	da2c0c13          	add	s8,s8,-606 # 80008220 <digits+0x1e0>
      if (p->state == RUNNABLE)
    80002486:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002488:	00018497          	auipc	s1,0x18
    8000248c:	7a848493          	add	s1,s1,1960 # 8001ac30 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002490:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002494:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002498:	10079073          	csrw	sstatus,a5
    if (ticks - last_boost_ticks >= BOOST_INTERVAL)
    8000249c:	000b2583          	lw	a1,0(s6)
    800024a0:	000aa783          	lw	a5,0(s5)
    800024a4:	40f587bb          	subw	a5,a1,a5
    800024a8:	02fbef63          	bltu	s7,a5,800024e6 <mlfq_scheduler+0xbe>
    for (p = proc; p < &proc[NPROC]; p++)
    800024ac:	00010a17          	auipc	s4,0x10
    800024b0:	be4a0a13          	add	s4,s4,-1052 # 80012090 <proc+0x60>
{
    800024b4:	00010917          	auipc	s2,0x10
    800024b8:	b7c90913          	add	s2,s2,-1156 # 80012030 <proc>
      acquire(&p->lock);
    800024bc:	854a                	mv	a0,s2
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	714080e7          	jalr	1812(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    800024c6:	01892783          	lw	a5,24(s2)
    800024ca:	03378c63          	beq	a5,s3,80002502 <mlfq_scheduler+0xda>
      release(&p->lock);
    800024ce:	854a                	mv	a0,s2
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7b6080e7          	jalr	1974(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024d8:	23090913          	add	s2,s2,560
    800024dc:	230a0a13          	add	s4,s4,560
    800024e0:	fa9908e3          	beq	s2,s1,80002490 <mlfq_scheduler+0x68>
    800024e4:	bfe1                	j	800024bc <mlfq_scheduler+0x94>
      printf("Boosting priorities at ticks = %d\n", ticks);
    800024e6:	8562                	mv	a0,s8
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	09e080e7          	jalr	158(ra) # 80000586 <printf>
      priority_boost();
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	efc080e7          	jalr	-260(ra) # 800023ec <priority_boost>
      last_boost_ticks = ticks; // Update the last boost time
    800024f8:	000b2783          	lw	a5,0(s6)
    800024fc:	00faa023          	sw	a5,0(s5)
    80002500:	b775                	j	800024ac <mlfq_scheduler+0x84>
          if (i->priority < p->priority && i->state == RUNNABLE)
    80002502:	22092683          	lw	a3,544(s2)
        for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002506:	00010797          	auipc	a5,0x10
    8000250a:	b2a78793          	add	a5,a5,-1238 # 80012030 <proc>
    8000250e:	a029                	j	80002518 <mlfq_scheduler+0xf0>
    80002510:	23078793          	add	a5,a5,560
    80002514:	00978a63          	beq	a5,s1,80002528 <mlfq_scheduler+0x100>
          if (i->priority < p->priority && i->state == RUNNABLE)
    80002518:	2207a703          	lw	a4,544(a5)
    8000251c:	fed75ae3          	bge	a4,a3,80002510 <mlfq_scheduler+0xe8>
    80002520:	4f98                	lw	a4,24(a5)
    80002522:	ff3717e3          	bne	a4,s3,80002510 <mlfq_scheduler+0xe8>
    80002526:	b765                	j	800024ce <mlfq_scheduler+0xa6>
          for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002528:	00010797          	auipc	a5,0x10
    8000252c:	b0878793          	add	a5,a5,-1272 # 80012030 <proc>
    80002530:	a029                	j	8000253a <mlfq_scheduler+0x112>
    80002532:	23078793          	add	a5,a5,560
    80002536:	0a978c63          	beq	a5,s1,800025ee <mlfq_scheduler+0x1c6>
            if (i->priority == p->priority && i->lastscheduledticks > p->lastscheduledticks && i->state == RUNNABLE)
    8000253a:	2207a703          	lw	a4,544(a5)
    8000253e:	fed71ae3          	bne	a4,a3,80002532 <mlfq_scheduler+0x10a>
    80002542:	2247a603          	lw	a2,548(a5)
    80002546:	22492703          	lw	a4,548(s2)
    8000254a:	fec754e3          	bge	a4,a2,80002532 <mlfq_scheduler+0x10a>
    8000254e:	4f98                	lw	a4,24(a5)
    80002550:	ff3711e3          	bne	a4,s3,80002532 <mlfq_scheduler+0x10a>
              flag = 1;
    80002554:	4785                	li	a5,1
          if (p->priority == 3)
    80002556:	f7368ce3          	beq	a3,s3,800024ce <mlfq_scheduler+0xa6>
    8000255a:	a869                	j	800025f4 <mlfq_scheduler+0x1cc>
              p->state = RUNNING;
    8000255c:	4791                	li	a5,4
    8000255e:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    80002562:	007c9793          	sll	a5,s9,0x7
    80002566:	0000ed17          	auipc	s10,0xe
    8000256a:	6fad0d13          	add	s10,s10,1786 # 80010c60 <pid_lock>
    8000256e:	9d3e                	add	s10,s10,a5
    80002570:	032d3823          	sd	s2,48(s10)
              swtch(&c->context, &p->context);
    80002574:	85d2                	mv	a1,s4
    80002576:	0000e517          	auipc	a0,0xe
    8000257a:	72250513          	add	a0,a0,1826 # 80010c98 <cpus+0x8>
    8000257e:	953e                	add	a0,a0,a5
    80002580:	00001097          	auipc	ra,0x1
    80002584:	94c080e7          	jalr	-1716(ra) # 80002ecc <swtch>
              c->proc = 0;
    80002588:	020d3823          	sd	zero,48(s10)
              release(&p->lock);
    8000258c:	854a                	mv	a0,s2
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6f8080e7          	jalr	1784(ra) # 80000c86 <release>
              continue;
    80002596:	b789                	j	800024d8 <mlfq_scheduler+0xb0>
            for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002598:	23078793          	add	a5,a5,560
    8000259c:	02d78063          	beq	a5,a3,800025bc <mlfq_scheduler+0x194>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    800025a0:	2207b703          	ld	a4,544(a5)
    800025a4:	fec71ae3          	bne	a4,a2,80002598 <mlfq_scheduler+0x170>
    800025a8:	16c7a583          	lw	a1,364(a5)
    800025ac:	16c92703          	lw	a4,364(s2)
    800025b0:	fee5f4e3          	bgeu	a1,a4,80002598 <mlfq_scheduler+0x170>
    800025b4:	4f98                	lw	a4,24(a5)
    800025b6:	fea711e3          	bne	a4,a0,80002598 <mlfq_scheduler+0x170>
    800025ba:	bf11                	j	800024ce <mlfq_scheduler+0xa6>
              p->state = RUNNING;
    800025bc:	4791                	li	a5,4
    800025be:	00f92c23          	sw	a5,24(s2)
              c->proc = p;
    800025c2:	007c9793          	sll	a5,s9,0x7
    800025c6:	0000ed17          	auipc	s10,0xe
    800025ca:	69ad0d13          	add	s10,s10,1690 # 80010c60 <pid_lock>
    800025ce:	9d3e                	add	s10,s10,a5
    800025d0:	032d3823          	sd	s2,48(s10)
              swtch(&c->context, &p->context);
    800025d4:	85d2                	mv	a1,s4
    800025d6:	0000e517          	auipc	a0,0xe
    800025da:	6c250513          	add	a0,a0,1730 # 80010c98 <cpus+0x8>
    800025de:	953e                	add	a0,a0,a5
    800025e0:	00001097          	auipc	ra,0x1
    800025e4:	8ec080e7          	jalr	-1812(ra) # 80002ecc <swtch>
              c->proc = 0;
    800025e8:	020d3823          	sd	zero,48(s10)
    800025ec:	b5cd                	j	800024ce <mlfq_scheduler+0xa6>
          if (p->priority == 3)
    800025ee:	f73687e3          	beq	a3,s3,8000255c <mlfq_scheduler+0x134>
    800025f2:	4781                	li	a5,0
          if (flag == 0)
    800025f4:	ec079de3          	bnez	a5,800024ce <mlfq_scheduler+0xa6>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    800025f8:	22093603          	ld	a2,544(s2)
            for (struct proc *i = proc; i < &proc[NPROC]; i++)
    800025fc:	00010797          	auipc	a5,0x10
    80002600:	a3478793          	add	a5,a5,-1484 # 80012030 <proc>
              if (i->priority == p->priority && i->lastscheduledticks == p->lastscheduledticks && i->ctime < p->ctime && i->state == RUNNABLE)
    80002604:	450d                	li	a0,3
            for (struct proc *i = proc; i < &proc[NPROC]; i++)
    80002606:	00018697          	auipc	a3,0x18
    8000260a:	62a68693          	add	a3,a3,1578 # 8001ac30 <tickslock>
    8000260e:	bf49                	j	800025a0 <mlfq_scheduler+0x178>

0000000080002610 <scheduler>:
{
    80002610:	1141                	add	sp,sp,-16
    80002612:	e406                	sd	ra,8(sp)
    80002614:	e022                	sd	s0,0(sp)
    80002616:	0800                	add	s0,sp,16
    printf("mlfq will run");
    80002618:	00006517          	auipc	a0,0x6
    8000261c:	c3050513          	add	a0,a0,-976 # 80008248 <digits+0x208>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	f66080e7          	jalr	-154(ra) # 80000586 <printf>
    mlfq_scheduler();
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	e00080e7          	jalr	-512(ra) # 80002428 <mlfq_scheduler>

0000000080002630 <sched>:
{
    80002630:	7179                	add	sp,sp,-48
    80002632:	f406                	sd	ra,40(sp)
    80002634:	f022                	sd	s0,32(sp)
    80002636:	ec26                	sd	s1,24(sp)
    80002638:	e84a                	sd	s2,16(sp)
    8000263a:	e44e                	sd	s3,8(sp)
    8000263c:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	378080e7          	jalr	888(ra) # 800019b6 <myproc>
    80002646:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	510080e7          	jalr	1296(ra) # 80000b58 <holding>
    80002650:	c93d                	beqz	a0,800026c6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002652:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002654:	2781                	sext.w	a5,a5
    80002656:	079e                	sll	a5,a5,0x7
    80002658:	0000e717          	auipc	a4,0xe
    8000265c:	60870713          	add	a4,a4,1544 # 80010c60 <pid_lock>
    80002660:	97ba                	add	a5,a5,a4
    80002662:	0a87a703          	lw	a4,168(a5)
    80002666:	4785                	li	a5,1
    80002668:	06f71763          	bne	a4,a5,800026d6 <sched+0xa6>
  if (p->state == RUNNING)
    8000266c:	4c98                	lw	a4,24(s1)
    8000266e:	4791                	li	a5,4
    80002670:	06f70b63          	beq	a4,a5,800026e6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002674:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002678:	8b89                	and	a5,a5,2
  if (intr_get())
    8000267a:	efb5                	bnez	a5,800026f6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000267c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000267e:	0000e917          	auipc	s2,0xe
    80002682:	5e290913          	add	s2,s2,1506 # 80010c60 <pid_lock>
    80002686:	2781                	sext.w	a5,a5
    80002688:	079e                	sll	a5,a5,0x7
    8000268a:	97ca                	add	a5,a5,s2
    8000268c:	0ac7a983          	lw	s3,172(a5)
    80002690:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002692:	2781                	sext.w	a5,a5
    80002694:	079e                	sll	a5,a5,0x7
    80002696:	0000e597          	auipc	a1,0xe
    8000269a:	60258593          	add	a1,a1,1538 # 80010c98 <cpus+0x8>
    8000269e:	95be                	add	a1,a1,a5
    800026a0:	06048513          	add	a0,s1,96
    800026a4:	00001097          	auipc	ra,0x1
    800026a8:	828080e7          	jalr	-2008(ra) # 80002ecc <swtch>
    800026ac:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800026ae:	2781                	sext.w	a5,a5
    800026b0:	079e                	sll	a5,a5,0x7
    800026b2:	993e                	add	s2,s2,a5
    800026b4:	0b392623          	sw	s3,172(s2)
}
    800026b8:	70a2                	ld	ra,40(sp)
    800026ba:	7402                	ld	s0,32(sp)
    800026bc:	64e2                	ld	s1,24(sp)
    800026be:	6942                	ld	s2,16(sp)
    800026c0:	69a2                	ld	s3,8(sp)
    800026c2:	6145                	add	sp,sp,48
    800026c4:	8082                	ret
    panic("sched p->lock");
    800026c6:	00006517          	auipc	a0,0x6
    800026ca:	b9250513          	add	a0,a0,-1134 # 80008258 <digits+0x218>
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	e6e080e7          	jalr	-402(ra) # 8000053c <panic>
    panic("sched locks");
    800026d6:	00006517          	auipc	a0,0x6
    800026da:	b9250513          	add	a0,a0,-1134 # 80008268 <digits+0x228>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	e5e080e7          	jalr	-418(ra) # 8000053c <panic>
    panic("sched running");
    800026e6:	00006517          	auipc	a0,0x6
    800026ea:	b9250513          	add	a0,a0,-1134 # 80008278 <digits+0x238>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	e4e080e7          	jalr	-434(ra) # 8000053c <panic>
    panic("sched interruptible");
    800026f6:	00006517          	auipc	a0,0x6
    800026fa:	b9250513          	add	a0,a0,-1134 # 80008288 <digits+0x248>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	e3e080e7          	jalr	-450(ra) # 8000053c <panic>

0000000080002706 <yield>:
{
    80002706:	1101                	add	sp,sp,-32
    80002708:	ec06                	sd	ra,24(sp)
    8000270a:	e822                	sd	s0,16(sp)
    8000270c:	e426                	sd	s1,8(sp)
    8000270e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	2a6080e7          	jalr	678(ra) # 800019b6 <myproc>
    80002718:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	4b8080e7          	jalr	1208(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002722:	478d                	li	a5,3
    80002724:	cc9c                	sw	a5,24(s1)
  sched();
    80002726:	00000097          	auipc	ra,0x0
    8000272a:	f0a080e7          	jalr	-246(ra) # 80002630 <sched>
  release(&p->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	556080e7          	jalr	1366(ra) # 80000c86 <release>
}
    80002738:	60e2                	ld	ra,24(sp)
    8000273a:	6442                	ld	s0,16(sp)
    8000273c:	64a2                	ld	s1,8(sp)
    8000273e:	6105                	add	sp,sp,32
    80002740:	8082                	ret

0000000080002742 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002742:	7179                	add	sp,sp,-48
    80002744:	f406                	sd	ra,40(sp)
    80002746:	f022                	sd	s0,32(sp)
    80002748:	ec26                	sd	s1,24(sp)
    8000274a:	e84a                	sd	s2,16(sp)
    8000274c:	e44e                	sd	s3,8(sp)
    8000274e:	1800                	add	s0,sp,48
    80002750:	89aa                	mv	s3,a0
    80002752:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	262080e7          	jalr	610(ra) # 800019b6 <myproc>
    8000275c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	474080e7          	jalr	1140(ra) # 80000bd2 <acquire>
  release(lk);
    80002766:	854a                	mv	a0,s2
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	51e080e7          	jalr	1310(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002770:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002774:	4789                	li	a5,2
    80002776:	cc9c                	sw	a5,24(s1)

  sched();
    80002778:	00000097          	auipc	ra,0x0
    8000277c:	eb8080e7          	jalr	-328(ra) # 80002630 <sched>

  // Tidy up.
  p->chan = 0;
    80002780:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	500080e7          	jalr	1280(ra) # 80000c86 <release>
  acquire(lk);
    8000278e:	854a                	mv	a0,s2
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	442080e7          	jalr	1090(ra) # 80000bd2 <acquire>
}
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6145                	add	sp,sp,48
    800027a4:	8082                	ret

00000000800027a6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800027a6:	7139                	add	sp,sp,-64
    800027a8:	fc06                	sd	ra,56(sp)
    800027aa:	f822                	sd	s0,48(sp)
    800027ac:	f426                	sd	s1,40(sp)
    800027ae:	f04a                	sd	s2,32(sp)
    800027b0:	ec4e                	sd	s3,24(sp)
    800027b2:	e852                	sd	s4,16(sp)
    800027b4:	e456                	sd	s5,8(sp)
    800027b6:	0080                	add	s0,sp,64
    800027b8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027ba:	00010497          	auipc	s1,0x10
    800027be:	87648493          	add	s1,s1,-1930 # 80012030 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800027c2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800027c4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800027c6:	00018917          	auipc	s2,0x18
    800027ca:	46a90913          	add	s2,s2,1130 # 8001ac30 <tickslock>
    800027ce:	a811                	j	800027e2 <wakeup+0x3c>
      }
      release(&p->lock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4b4080e7          	jalr	1204(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027da:	23048493          	add	s1,s1,560
    800027de:	03248663          	beq	s1,s2,8000280a <wakeup+0x64>
    if (p != myproc())
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	1d4080e7          	jalr	468(ra) # 800019b6 <myproc>
    800027ea:	fea488e3          	beq	s1,a0,800027da <wakeup+0x34>
      acquire(&p->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	3e2080e7          	jalr	994(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800027f8:	4c9c                	lw	a5,24(s1)
    800027fa:	fd379be3          	bne	a5,s3,800027d0 <wakeup+0x2a>
    800027fe:	709c                	ld	a5,32(s1)
    80002800:	fd4798e3          	bne	a5,s4,800027d0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002804:	0154ac23          	sw	s5,24(s1)
    80002808:	b7e1                	j	800027d0 <wakeup+0x2a>
    }
  }
}
    8000280a:	70e2                	ld	ra,56(sp)
    8000280c:	7442                	ld	s0,48(sp)
    8000280e:	74a2                	ld	s1,40(sp)
    80002810:	7902                	ld	s2,32(sp)
    80002812:	69e2                	ld	s3,24(sp)
    80002814:	6a42                	ld	s4,16(sp)
    80002816:	6aa2                	ld	s5,8(sp)
    80002818:	6121                	add	sp,sp,64
    8000281a:	8082                	ret

000000008000281c <reparent>:
{
    8000281c:	7179                	add	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	add	s0,sp,48
    8000282c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000282e:	00010497          	auipc	s1,0x10
    80002832:	80248493          	add	s1,s1,-2046 # 80012030 <proc>
      pp->parent = initproc;
    80002836:	00006a17          	auipc	s4,0x6
    8000283a:	1b2a0a13          	add	s4,s4,434 # 800089e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000283e:	00018997          	auipc	s3,0x18
    80002842:	3f298993          	add	s3,s3,1010 # 8001ac30 <tickslock>
    80002846:	a029                	j	80002850 <reparent+0x34>
    80002848:	23048493          	add	s1,s1,560
    8000284c:	01348d63          	beq	s1,s3,80002866 <reparent+0x4a>
    if (pp->parent == p)
    80002850:	7c9c                	ld	a5,56(s1)
    80002852:	ff279be3          	bne	a5,s2,80002848 <reparent+0x2c>
      pp->parent = initproc;
    80002856:	000a3503          	ld	a0,0(s4)
    8000285a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	f4a080e7          	jalr	-182(ra) # 800027a6 <wakeup>
    80002864:	b7d5                	j	80002848 <reparent+0x2c>
}
    80002866:	70a2                	ld	ra,40(sp)
    80002868:	7402                	ld	s0,32(sp)
    8000286a:	64e2                	ld	s1,24(sp)
    8000286c:	6942                	ld	s2,16(sp)
    8000286e:	69a2                	ld	s3,8(sp)
    80002870:	6a02                	ld	s4,0(sp)
    80002872:	6145                	add	sp,sp,48
    80002874:	8082                	ret

0000000080002876 <exit>:
{
    80002876:	7179                	add	sp,sp,-48
    80002878:	f406                	sd	ra,40(sp)
    8000287a:	f022                	sd	s0,32(sp)
    8000287c:	ec26                	sd	s1,24(sp)
    8000287e:	e84a                	sd	s2,16(sp)
    80002880:	e44e                	sd	s3,8(sp)
    80002882:	e052                	sd	s4,0(sp)
    80002884:	1800                	add	s0,sp,48
    80002886:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	12e080e7          	jalr	302(ra) # 800019b6 <myproc>
    80002890:	89aa                	mv	s3,a0
  if (p == initproc)
    80002892:	00006797          	auipc	a5,0x6
    80002896:	1567b783          	ld	a5,342(a5) # 800089e8 <initproc>
    8000289a:	0d050493          	add	s1,a0,208
    8000289e:	15050913          	add	s2,a0,336
    800028a2:	02a79363          	bne	a5,a0,800028c8 <exit+0x52>
    panic("init exiting");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	9fa50513          	add	a0,a0,-1542 # 800082a0 <digits+0x260>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	c8e080e7          	jalr	-882(ra) # 8000053c <panic>
      fileclose(f);
    800028b6:	00003097          	auipc	ra,0x3
    800028ba:	a0a080e7          	jalr	-1526(ra) # 800052c0 <fileclose>
      p->ofile[fd] = 0;
    800028be:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800028c2:	04a1                	add	s1,s1,8
    800028c4:	01248563          	beq	s1,s2,800028ce <exit+0x58>
    if (p->ofile[fd])
    800028c8:	6088                	ld	a0,0(s1)
    800028ca:	f575                	bnez	a0,800028b6 <exit+0x40>
    800028cc:	bfdd                	j	800028c2 <exit+0x4c>
  begin_op();
    800028ce:	00002097          	auipc	ra,0x2
    800028d2:	52e080e7          	jalr	1326(ra) # 80004dfc <begin_op>
  iput(p->cwd);
    800028d6:	1509b503          	ld	a0,336(s3)
    800028da:	00002097          	auipc	ra,0x2
    800028de:	d36080e7          	jalr	-714(ra) # 80004610 <iput>
  end_op();
    800028e2:	00002097          	auipc	ra,0x2
    800028e6:	594080e7          	jalr	1428(ra) # 80004e76 <end_op>
  p->cwd = 0;
    800028ea:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800028ee:	0000e497          	auipc	s1,0xe
    800028f2:	38a48493          	add	s1,s1,906 # 80010c78 <wait_lock>
    800028f6:	8526                	mv	a0,s1
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	2da080e7          	jalr	730(ra) # 80000bd2 <acquire>
  reparent(p);
    80002900:	854e                	mv	a0,s3
    80002902:	00000097          	auipc	ra,0x0
    80002906:	f1a080e7          	jalr	-230(ra) # 8000281c <reparent>
  wakeup(p->parent);
    8000290a:	0389b503          	ld	a0,56(s3)
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	e98080e7          	jalr	-360(ra) # 800027a6 <wakeup>
  acquire(&p->lock);
    80002916:	854e                	mv	a0,s3
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	2ba080e7          	jalr	698(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002920:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002924:	4795                	li	a5,5
    80002926:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000292a:	00006797          	auipc	a5,0x6
    8000292e:	0c67a783          	lw	a5,198(a5) # 800089f0 <ticks>
    80002932:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002936:	8526                	mv	a0,s1
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	34e080e7          	jalr	846(ra) # 80000c86 <release>
  sched();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	cf0080e7          	jalr	-784(ra) # 80002630 <sched>
  panic("zombie exit");
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	96850513          	add	a0,a0,-1688 # 800082b0 <digits+0x270>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	bec080e7          	jalr	-1044(ra) # 8000053c <panic>

0000000080002958 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002958:	7179                	add	sp,sp,-48
    8000295a:	f406                	sd	ra,40(sp)
    8000295c:	f022                	sd	s0,32(sp)
    8000295e:	ec26                	sd	s1,24(sp)
    80002960:	e84a                	sd	s2,16(sp)
    80002962:	e44e                	sd	s3,8(sp)
    80002964:	1800                	add	s0,sp,48
    80002966:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002968:	0000f497          	auipc	s1,0xf
    8000296c:	6c848493          	add	s1,s1,1736 # 80012030 <proc>
    80002970:	00018997          	auipc	s3,0x18
    80002974:	2c098993          	add	s3,s3,704 # 8001ac30 <tickslock>
  {
    acquire(&p->lock);
    80002978:	8526                	mv	a0,s1
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	258080e7          	jalr	600(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002982:	589c                	lw	a5,48(s1)
    80002984:	01278d63          	beq	a5,s2,8000299e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002988:	8526                	mv	a0,s1
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	2fc080e7          	jalr	764(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002992:	23048493          	add	s1,s1,560
    80002996:	ff3491e3          	bne	s1,s3,80002978 <kill+0x20>
  }
  return -1;
    8000299a:	557d                	li	a0,-1
    8000299c:	a829                	j	800029b6 <kill+0x5e>
      p->killed = 1;
    8000299e:	4785                	li	a5,1
    800029a0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800029a2:	4c98                	lw	a4,24(s1)
    800029a4:	4789                	li	a5,2
    800029a6:	00f70f63          	beq	a4,a5,800029c4 <kill+0x6c>
      release(&p->lock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	2da080e7          	jalr	730(ra) # 80000c86 <release>
      return 0;
    800029b4:	4501                	li	a0,0
}
    800029b6:	70a2                	ld	ra,40(sp)
    800029b8:	7402                	ld	s0,32(sp)
    800029ba:	64e2                	ld	s1,24(sp)
    800029bc:	6942                	ld	s2,16(sp)
    800029be:	69a2                	ld	s3,8(sp)
    800029c0:	6145                	add	sp,sp,48
    800029c2:	8082                	ret
        p->state = RUNNABLE;
    800029c4:	478d                	li	a5,3
    800029c6:	cc9c                	sw	a5,24(s1)
    800029c8:	b7cd                	j	800029aa <kill+0x52>

00000000800029ca <setkilled>:

void setkilled(struct proc *p)
{
    800029ca:	1101                	add	sp,sp,-32
    800029cc:	ec06                	sd	ra,24(sp)
    800029ce:	e822                	sd	s0,16(sp)
    800029d0:	e426                	sd	s1,8(sp)
    800029d2:	1000                	add	s0,sp,32
    800029d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	1fc080e7          	jalr	508(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800029de:	4785                	li	a5,1
    800029e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800029e2:	8526                	mv	a0,s1
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2a2080e7          	jalr	674(ra) # 80000c86 <release>
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	64a2                	ld	s1,8(sp)
    800029f2:	6105                	add	sp,sp,32
    800029f4:	8082                	ret

00000000800029f6 <killed>:

int killed(struct proc *p)
{
    800029f6:	1101                	add	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	e04a                	sd	s2,0(sp)
    80002a00:	1000                	add	s0,sp,32
    80002a02:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	1ce080e7          	jalr	462(ra) # 80000bd2 <acquire>
  k = p->killed;
    80002a0c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002a10:	8526                	mv	a0,s1
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	274080e7          	jalr	628(ra) # 80000c86 <release>
  return k;
}
    80002a1a:	854a                	mv	a0,s2
    80002a1c:	60e2                	ld	ra,24(sp)
    80002a1e:	6442                	ld	s0,16(sp)
    80002a20:	64a2                	ld	s1,8(sp)
    80002a22:	6902                	ld	s2,0(sp)
    80002a24:	6105                	add	sp,sp,32
    80002a26:	8082                	ret

0000000080002a28 <wait>:
{
    80002a28:	715d                	add	sp,sp,-80
    80002a2a:	e486                	sd	ra,72(sp)
    80002a2c:	e0a2                	sd	s0,64(sp)
    80002a2e:	fc26                	sd	s1,56(sp)
    80002a30:	f84a                	sd	s2,48(sp)
    80002a32:	f44e                	sd	s3,40(sp)
    80002a34:	f052                	sd	s4,32(sp)
    80002a36:	ec56                	sd	s5,24(sp)
    80002a38:	e85a                	sd	s6,16(sp)
    80002a3a:	e45e                	sd	s7,8(sp)
    80002a3c:	e062                	sd	s8,0(sp)
    80002a3e:	0880                	add	s0,sp,80
    80002a40:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	f74080e7          	jalr	-140(ra) # 800019b6 <myproc>
    80002a4a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002a4c:	0000e517          	auipc	a0,0xe
    80002a50:	22c50513          	add	a0,a0,556 # 80010c78 <wait_lock>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	17e080e7          	jalr	382(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002a5c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002a5e:	4a95                	li	s5,5
        havekids = 1;
    80002a60:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a62:	00018997          	auipc	s3,0x18
    80002a66:	1ce98993          	add	s3,s3,462 # 8001ac30 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a6a:	0000ec17          	auipc	s8,0xe
    80002a6e:	20ec0c13          	add	s8,s8,526 # 80010c78 <wait_lock>
    80002a72:	a8f1                	j	80002b4e <wait+0x126>
    80002a74:	17448793          	add	a5,s1,372
    80002a78:	17490713          	add	a4,s2,372
    80002a7c:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    80002a80:	4394                	lw	a3,0(a5)
    80002a82:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    80002a84:	0791                	add	a5,a5,4
    80002a86:	0711                	add	a4,a4,4
    80002a88:	fec79ce3          	bne	a5,a2,80002a80 <wait+0x58>
          pid = pp->pid;
    80002a8c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002a90:	000a0e63          	beqz	s4,80002aac <wait+0x84>
    80002a94:	4691                	li	a3,4
    80002a96:	02c48613          	add	a2,s1,44
    80002a9a:	85d2                	mv	a1,s4
    80002a9c:	05093503          	ld	a0,80(s2)
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	bc6080e7          	jalr	-1082(ra) # 80001666 <copyout>
    80002aa8:	04054163          	bltz	a0,80002aea <wait+0xc2>
          freeproc(pp);
    80002aac:	8526                	mv	a0,s1
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	0ba080e7          	jalr	186(ra) # 80001b68 <freeproc>
          release(&pp->lock);
    80002ab6:	8526                	mv	a0,s1
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	1ce080e7          	jalr	462(ra) # 80000c86 <release>
          release(&wait_lock);
    80002ac0:	0000e517          	auipc	a0,0xe
    80002ac4:	1b850513          	add	a0,a0,440 # 80010c78 <wait_lock>
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	1be080e7          	jalr	446(ra) # 80000c86 <release>
}
    80002ad0:	854e                	mv	a0,s3
    80002ad2:	60a6                	ld	ra,72(sp)
    80002ad4:	6406                	ld	s0,64(sp)
    80002ad6:	74e2                	ld	s1,56(sp)
    80002ad8:	7942                	ld	s2,48(sp)
    80002ada:	79a2                	ld	s3,40(sp)
    80002adc:	7a02                	ld	s4,32(sp)
    80002ade:	6ae2                	ld	s5,24(sp)
    80002ae0:	6b42                	ld	s6,16(sp)
    80002ae2:	6ba2                	ld	s7,8(sp)
    80002ae4:	6c02                	ld	s8,0(sp)
    80002ae6:	6161                	add	sp,sp,80
    80002ae8:	8082                	ret
            release(&pp->lock);
    80002aea:	8526                	mv	a0,s1
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	19a080e7          	jalr	410(ra) # 80000c86 <release>
            release(&wait_lock);
    80002af4:	0000e517          	auipc	a0,0xe
    80002af8:	18450513          	add	a0,a0,388 # 80010c78 <wait_lock>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	18a080e7          	jalr	394(ra) # 80000c86 <release>
            return -1;
    80002b04:	59fd                	li	s3,-1
    80002b06:	b7e9                	j	80002ad0 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b08:	23048493          	add	s1,s1,560
    80002b0c:	03348463          	beq	s1,s3,80002b34 <wait+0x10c>
      if (pp->parent == p)
    80002b10:	7c9c                	ld	a5,56(s1)
    80002b12:	ff279be3          	bne	a5,s2,80002b08 <wait+0xe0>
        acquire(&pp->lock);
    80002b16:	8526                	mv	a0,s1
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	0ba080e7          	jalr	186(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002b20:	4c9c                	lw	a5,24(s1)
    80002b22:	f55789e3          	beq	a5,s5,80002a74 <wait+0x4c>
        release(&pp->lock);
    80002b26:	8526                	mv	a0,s1
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	15e080e7          	jalr	350(ra) # 80000c86 <release>
        havekids = 1;
    80002b30:	875a                	mv	a4,s6
    80002b32:	bfd9                	j	80002b08 <wait+0xe0>
    if (!havekids || killed(p))
    80002b34:	c31d                	beqz	a4,80002b5a <wait+0x132>
    80002b36:	854a                	mv	a0,s2
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	ebe080e7          	jalr	-322(ra) # 800029f6 <killed>
    80002b40:	ed09                	bnez	a0,80002b5a <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b42:	85e2                	mv	a1,s8
    80002b44:	854a                	mv	a0,s2
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	bfc080e7          	jalr	-1028(ra) # 80002742 <sleep>
    havekids = 0;
    80002b4e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002b50:	0000f497          	auipc	s1,0xf
    80002b54:	4e048493          	add	s1,s1,1248 # 80012030 <proc>
    80002b58:	bf65                	j	80002b10 <wait+0xe8>
      release(&wait_lock);
    80002b5a:	0000e517          	auipc	a0,0xe
    80002b5e:	11e50513          	add	a0,a0,286 # 80010c78 <wait_lock>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	124080e7          	jalr	292(ra) # 80000c86 <release>
      return -1;
    80002b6a:	59fd                	li	s3,-1
    80002b6c:	b795                	j	80002ad0 <wait+0xa8>

0000000080002b6e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002b6e:	7179                	add	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	e052                	sd	s4,0(sp)
    80002b7c:	1800                	add	s0,sp,48
    80002b7e:	84aa                	mv	s1,a0
    80002b80:	892e                	mv	s2,a1
    80002b82:	89b2                	mv	s3,a2
    80002b84:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	e30080e7          	jalr	-464(ra) # 800019b6 <myproc>
  if (user_dst)
    80002b8e:	c08d                	beqz	s1,80002bb0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002b90:	86d2                	mv	a3,s4
    80002b92:	864e                	mv	a2,s3
    80002b94:	85ca                	mv	a1,s2
    80002b96:	6928                	ld	a0,80(a0)
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	ace080e7          	jalr	-1330(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ba0:	70a2                	ld	ra,40(sp)
    80002ba2:	7402                	ld	s0,32(sp)
    80002ba4:	64e2                	ld	s1,24(sp)
    80002ba6:	6942                	ld	s2,16(sp)
    80002ba8:	69a2                	ld	s3,8(sp)
    80002baa:	6a02                	ld	s4,0(sp)
    80002bac:	6145                	add	sp,sp,48
    80002bae:	8082                	ret
    memmove((char *)dst, src, len);
    80002bb0:	000a061b          	sext.w	a2,s4
    80002bb4:	85ce                	mv	a1,s3
    80002bb6:	854a                	mv	a0,s2
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	172080e7          	jalr	370(ra) # 80000d2a <memmove>
    return 0;
    80002bc0:	8526                	mv	a0,s1
    80002bc2:	bff9                	j	80002ba0 <either_copyout+0x32>

0000000080002bc4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002bc4:	7179                	add	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	e84a                	sd	s2,16(sp)
    80002bce:	e44e                	sd	s3,8(sp)
    80002bd0:	e052                	sd	s4,0(sp)
    80002bd2:	1800                	add	s0,sp,48
    80002bd4:	892a                	mv	s2,a0
    80002bd6:	84ae                	mv	s1,a1
    80002bd8:	89b2                	mv	s3,a2
    80002bda:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	dda080e7          	jalr	-550(ra) # 800019b6 <myproc>
  if (user_src)
    80002be4:	c08d                	beqz	s1,80002c06 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002be6:	86d2                	mv	a3,s4
    80002be8:	864e                	mv	a2,s3
    80002bea:	85ca                	mv	a1,s2
    80002bec:	6928                	ld	a0,80(a0)
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	b04080e7          	jalr	-1276(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002bf6:	70a2                	ld	ra,40(sp)
    80002bf8:	7402                	ld	s0,32(sp)
    80002bfa:	64e2                	ld	s1,24(sp)
    80002bfc:	6942                	ld	s2,16(sp)
    80002bfe:	69a2                	ld	s3,8(sp)
    80002c00:	6a02                	ld	s4,0(sp)
    80002c02:	6145                	add	sp,sp,48
    80002c04:	8082                	ret
    memmove(dst, (char *)src, len);
    80002c06:	000a061b          	sext.w	a2,s4
    80002c0a:	85ce                	mv	a1,s3
    80002c0c:	854a                	mv	a0,s2
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	11c080e7          	jalr	284(ra) # 80000d2a <memmove>
    return 0;
    80002c16:	8526                	mv	a0,s1
    80002c18:	bff9                	j	80002bf6 <either_copyin+0x32>

0000000080002c1a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002c1a:	715d                	add	sp,sp,-80
    80002c1c:	e486                	sd	ra,72(sp)
    80002c1e:	e0a2                	sd	s0,64(sp)
    80002c20:	fc26                	sd	s1,56(sp)
    80002c22:	f84a                	sd	s2,48(sp)
    80002c24:	f44e                	sd	s3,40(sp)
    80002c26:	f052                	sd	s4,32(sp)
    80002c28:	ec56                	sd	s5,24(sp)
    80002c2a:	e85a                	sd	s6,16(sp)
    80002c2c:	e45e                	sd	s7,8(sp)
    80002c2e:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002c30:	00005517          	auipc	a0,0x5
    80002c34:	6e050513          	add	a0,a0,1760 # 80008310 <digits+0x2d0>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	94e080e7          	jalr	-1714(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002c40:	0000f497          	auipc	s1,0xf
    80002c44:	54848493          	add	s1,s1,1352 # 80012188 <proc+0x158>
    80002c48:	00018917          	auipc	s2,0x18
    80002c4c:	14090913          	add	s2,s2,320 # 8001ad88 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c50:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c52:	00005997          	auipc	s3,0x5
    80002c56:	66e98993          	add	s3,s3,1646 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002c5a:	00005a97          	auipc	s5,0x5
    80002c5e:	66ea8a93          	add	s5,s5,1646 # 800082c8 <digits+0x288>
    printf("\n");
    80002c62:	00005a17          	auipc	s4,0x5
    80002c66:	6aea0a13          	add	s4,s4,1710 # 80008310 <digits+0x2d0>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c6a:	00005b97          	auipc	s7,0x5
    80002c6e:	6deb8b93          	add	s7,s7,1758 # 80008348 <states.0>
    80002c72:	a00d                	j	80002c94 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002c74:	ed86a583          	lw	a1,-296(a3)
    80002c78:	8556                	mv	a0,s5
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	90c080e7          	jalr	-1780(ra) # 80000586 <printf>
    printf("\n");
    80002c82:	8552                	mv	a0,s4
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	902080e7          	jalr	-1790(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002c8c:	23048493          	add	s1,s1,560
    80002c90:	03248263          	beq	s1,s2,80002cb4 <procdump+0x9a>
    if (p->state == UNUSED)
    80002c94:	86a6                	mv	a3,s1
    80002c96:	ec04a783          	lw	a5,-320(s1)
    80002c9a:	dbed                	beqz	a5,80002c8c <procdump+0x72>
      state = "???";
    80002c9c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c9e:	fcfb6be3          	bltu	s6,a5,80002c74 <procdump+0x5a>
    80002ca2:	02079713          	sll	a4,a5,0x20
    80002ca6:	01d75793          	srl	a5,a4,0x1d
    80002caa:	97de                	add	a5,a5,s7
    80002cac:	6390                	ld	a2,0(a5)
    80002cae:	f279                	bnez	a2,80002c74 <procdump+0x5a>
      state = "???";
    80002cb0:	864e                	mv	a2,s3
    80002cb2:	b7c9                	j	80002c74 <procdump+0x5a>
  }
}
    80002cb4:	60a6                	ld	ra,72(sp)
    80002cb6:	6406                	ld	s0,64(sp)
    80002cb8:	74e2                	ld	s1,56(sp)
    80002cba:	7942                	ld	s2,48(sp)
    80002cbc:	79a2                	ld	s3,40(sp)
    80002cbe:	7a02                	ld	s4,32(sp)
    80002cc0:	6ae2                	ld	s5,24(sp)
    80002cc2:	6b42                	ld	s6,16(sp)
    80002cc4:	6ba2                	ld	s7,8(sp)
    80002cc6:	6161                	add	sp,sp,80
    80002cc8:	8082                	ret

0000000080002cca <waitx>:
//     }
// }

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002cca:	711d                	add	sp,sp,-96
    80002ccc:	ec86                	sd	ra,88(sp)
    80002cce:	e8a2                	sd	s0,80(sp)
    80002cd0:	e4a6                	sd	s1,72(sp)
    80002cd2:	e0ca                	sd	s2,64(sp)
    80002cd4:	fc4e                	sd	s3,56(sp)
    80002cd6:	f852                	sd	s4,48(sp)
    80002cd8:	f456                	sd	s5,40(sp)
    80002cda:	f05a                	sd	s6,32(sp)
    80002cdc:	ec5e                	sd	s7,24(sp)
    80002cde:	e862                	sd	s8,16(sp)
    80002ce0:	e466                	sd	s9,8(sp)
    80002ce2:	e06a                	sd	s10,0(sp)
    80002ce4:	1080                	add	s0,sp,96
    80002ce6:	8b2a                	mv	s6,a0
    80002ce8:	8bae                	mv	s7,a1
    80002cea:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	cca080e7          	jalr	-822(ra) # 800019b6 <myproc>
    80002cf4:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002cf6:	0000e517          	auipc	a0,0xe
    80002cfa:	f8250513          	add	a0,a0,-126 # 80010c78 <wait_lock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	ed4080e7          	jalr	-300(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002d06:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002d08:	4a15                	li	s4,5
        havekids = 1;
    80002d0a:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002d0c:	00018997          	auipc	s3,0x18
    80002d10:	f2498993          	add	s3,s3,-220 # 8001ac30 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d14:	0000ed17          	auipc	s10,0xe
    80002d18:	f64d0d13          	add	s10,s10,-156 # 80010c78 <wait_lock>
    80002d1c:	a0fd                	j	80002e0a <waitx+0x140>
          pid = np->pid;
    80002d1e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002d22:	1684a583          	lw	a1,360(s1)
    80002d26:	00bc2023          	sw	a1,0(s8)
          printf("%d \n", *rtime);
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	5ae50513          	add	a0,a0,1454 # 800082d8 <digits+0x298>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	854080e7          	jalr	-1964(ra) # 80000586 <printf>
          *wtime = np->etime - np->ctime - np->rtime;
    80002d3a:	16c4a783          	lw	a5,364(s1)
    80002d3e:	1684a703          	lw	a4,360(s1)
    80002d42:	9f3d                	addw	a4,a4,a5
    80002d44:	1704a783          	lw	a5,368(s1)
    80002d48:	9f99                	subw	a5,a5,a4
    80002d4a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d4e:	000b0e63          	beqz	s6,80002d6a <waitx+0xa0>
    80002d52:	4691                	li	a3,4
    80002d54:	02c48613          	add	a2,s1,44
    80002d58:	85da                	mv	a1,s6
    80002d5a:	05093503          	ld	a0,80(s2)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	908080e7          	jalr	-1784(ra) # 80001666 <copyout>
    80002d66:	04054363          	bltz	a0,80002dac <waitx+0xe2>
          freeproc(np);
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	dfc080e7          	jalr	-516(ra) # 80001b68 <freeproc>
          release(&np->lock);
    80002d74:	8526                	mv	a0,s1
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	f10080e7          	jalr	-240(ra) # 80000c86 <release>
          release(&wait_lock);
    80002d7e:	0000e517          	auipc	a0,0xe
    80002d82:	efa50513          	add	a0,a0,-262 # 80010c78 <wait_lock>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	f00080e7          	jalr	-256(ra) # 80000c86 <release>
  }
}
    80002d8e:	854e                	mv	a0,s3
    80002d90:	60e6                	ld	ra,88(sp)
    80002d92:	6446                	ld	s0,80(sp)
    80002d94:	64a6                	ld	s1,72(sp)
    80002d96:	6906                	ld	s2,64(sp)
    80002d98:	79e2                	ld	s3,56(sp)
    80002d9a:	7a42                	ld	s4,48(sp)
    80002d9c:	7aa2                	ld	s5,40(sp)
    80002d9e:	7b02                	ld	s6,32(sp)
    80002da0:	6be2                	ld	s7,24(sp)
    80002da2:	6c42                	ld	s8,16(sp)
    80002da4:	6ca2                	ld	s9,8(sp)
    80002da6:	6d02                	ld	s10,0(sp)
    80002da8:	6125                	add	sp,sp,96
    80002daa:	8082                	ret
            release(&np->lock);
    80002dac:	8526                	mv	a0,s1
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	ed8080e7          	jalr	-296(ra) # 80000c86 <release>
            release(&wait_lock);
    80002db6:	0000e517          	auipc	a0,0xe
    80002dba:	ec250513          	add	a0,a0,-318 # 80010c78 <wait_lock>
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	ec8080e7          	jalr	-312(ra) # 80000c86 <release>
            return -1;
    80002dc6:	59fd                	li	s3,-1
    80002dc8:	b7d9                	j	80002d8e <waitx+0xc4>
    for (np = proc; np < &proc[NPROC]; np++)
    80002dca:	23048493          	add	s1,s1,560
    80002dce:	03348463          	beq	s1,s3,80002df6 <waitx+0x12c>
      if (np->parent == p)
    80002dd2:	7c9c                	ld	a5,56(s1)
    80002dd4:	ff279be3          	bne	a5,s2,80002dca <waitx+0x100>
        acquire(&np->lock);
    80002dd8:	8526                	mv	a0,s1
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	df8080e7          	jalr	-520(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002de2:	4c9c                	lw	a5,24(s1)
    80002de4:	f3478de3          	beq	a5,s4,80002d1e <waitx+0x54>
        release(&np->lock);
    80002de8:	8526                	mv	a0,s1
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	e9c080e7          	jalr	-356(ra) # 80000c86 <release>
        havekids = 1;
    80002df2:	8756                	mv	a4,s5
    80002df4:	bfd9                	j	80002dca <waitx+0x100>
    if (!havekids || p->killed)
    80002df6:	c305                	beqz	a4,80002e16 <waitx+0x14c>
    80002df8:	02892783          	lw	a5,40(s2)
    80002dfc:	ef89                	bnez	a5,80002e16 <waitx+0x14c>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002dfe:	85ea                	mv	a1,s10
    80002e00:	854a                	mv	a0,s2
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	940080e7          	jalr	-1728(ra) # 80002742 <sleep>
    havekids = 0;
    80002e0a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002e0c:	0000f497          	auipc	s1,0xf
    80002e10:	22448493          	add	s1,s1,548 # 80012030 <proc>
    80002e14:	bf7d                	j	80002dd2 <waitx+0x108>
      release(&wait_lock);
    80002e16:	0000e517          	auipc	a0,0xe
    80002e1a:	e6250513          	add	a0,a0,-414 # 80010c78 <wait_lock>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	e68080e7          	jalr	-408(ra) # 80000c86 <release>
      return -1;
    80002e26:	59fd                	li	s3,-1
    80002e28:	b79d                	j	80002d8e <waitx+0xc4>

0000000080002e2a <update_time>:

void update_time()
{
    80002e2a:	7139                	add	sp,sp,-64
    80002e2c:	fc06                	sd	ra,56(sp)
    80002e2e:	f822                	sd	s0,48(sp)
    80002e30:	f426                	sd	s1,40(sp)
    80002e32:	f04a                	sd	s2,32(sp)
    80002e34:	ec4e                	sd	s3,24(sp)
    80002e36:	e852                	sd	s4,16(sp)
    80002e38:	e456                	sd	s5,8(sp)
    80002e3a:	e05a                	sd	s6,0(sp)
    80002e3c:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002e3e:	0000f497          	auipc	s1,0xf
    80002e42:	1f248493          	add	s1,s1,498 # 80012030 <proc>
  {
    if (p->pid >= 9 && p->pid <= 14)
    80002e46:	4a15                	li	s4,5
    {
      printf("p :%d p_ticks:%d p_priority %d ticks: %d p_lst%d\n", p->pid, p->ticks, p->priority, ticks, p->lastscheduledticks);
    80002e48:	00006b17          	auipc	s6,0x6
    80002e4c:	ba8b0b13          	add	s6,s6,-1112 # 800089f0 <ticks>
    80002e50:	00005a97          	auipc	s5,0x5
    80002e54:	490a8a93          	add	s5,s5,1168 # 800082e0 <digits+0x2a0>
    }
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002e58:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002e5a:	00018917          	auipc	s2,0x18
    80002e5e:	dd690913          	add	s2,s2,-554 # 8001ac30 <tickslock>
    80002e62:	a805                	j	80002e92 <update_time+0x68>
      printf("p :%d p_ticks:%d p_priority %d ticks: %d p_lst%d\n", p->pid, p->ticks, p->priority, ticks, p->lastscheduledticks);
    80002e64:	2244a783          	lw	a5,548(s1)
    80002e68:	000b2703          	lw	a4,0(s6)
    80002e6c:	2204a683          	lw	a3,544(s1)
    80002e70:	2284a603          	lw	a2,552(s1)
    80002e74:	8556                	mv	a0,s5
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	710080e7          	jalr	1808(ra) # 80000586 <printf>
    80002e7e:	a839                	j	80002e9c <update_time+0x72>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e04080e7          	jalr	-508(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002e8a:	23048493          	add	s1,s1,560
    80002e8e:	03248563          	beq	s1,s2,80002eb8 <update_time+0x8e>
    if (p->pid >= 9 && p->pid <= 14)
    80002e92:	588c                	lw	a1,48(s1)
    80002e94:	ff75879b          	addw	a5,a1,-9
    80002e98:	fcfa76e3          	bgeu	s4,a5,80002e64 <update_time+0x3a>
    acquire(&p->lock);
    80002e9c:	8526                	mv	a0,s1
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	d34080e7          	jalr	-716(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002ea6:	4c9c                	lw	a5,24(s1)
    80002ea8:	fd379ce3          	bne	a5,s3,80002e80 <update_time+0x56>
      p->rtime++;
    80002eac:	1684a783          	lw	a5,360(s1)
    80002eb0:	2785                	addw	a5,a5,1
    80002eb2:	16f4a423          	sw	a5,360(s1)
    80002eb6:	b7e9                	j	80002e80 <update_time+0x56>
  }
}
    80002eb8:	70e2                	ld	ra,56(sp)
    80002eba:	7442                	ld	s0,48(sp)
    80002ebc:	74a2                	ld	s1,40(sp)
    80002ebe:	7902                	ld	s2,32(sp)
    80002ec0:	69e2                	ld	s3,24(sp)
    80002ec2:	6a42                	ld	s4,16(sp)
    80002ec4:	6aa2                	ld	s5,8(sp)
    80002ec6:	6b02                	ld	s6,0(sp)
    80002ec8:	6121                	add	sp,sp,64
    80002eca:	8082                	ret

0000000080002ecc <swtch>:
    80002ecc:	00153023          	sd	ra,0(a0)
    80002ed0:	00253423          	sd	sp,8(a0)
    80002ed4:	e900                	sd	s0,16(a0)
    80002ed6:	ed04                	sd	s1,24(a0)
    80002ed8:	03253023          	sd	s2,32(a0)
    80002edc:	03353423          	sd	s3,40(a0)
    80002ee0:	03453823          	sd	s4,48(a0)
    80002ee4:	03553c23          	sd	s5,56(a0)
    80002ee8:	05653023          	sd	s6,64(a0)
    80002eec:	05753423          	sd	s7,72(a0)
    80002ef0:	05853823          	sd	s8,80(a0)
    80002ef4:	05953c23          	sd	s9,88(a0)
    80002ef8:	07a53023          	sd	s10,96(a0)
    80002efc:	07b53423          	sd	s11,104(a0)
    80002f00:	0005b083          	ld	ra,0(a1)
    80002f04:	0085b103          	ld	sp,8(a1)
    80002f08:	6980                	ld	s0,16(a1)
    80002f0a:	6d84                	ld	s1,24(a1)
    80002f0c:	0205b903          	ld	s2,32(a1)
    80002f10:	0285b983          	ld	s3,40(a1)
    80002f14:	0305ba03          	ld	s4,48(a1)
    80002f18:	0385ba83          	ld	s5,56(a1)
    80002f1c:	0405bb03          	ld	s6,64(a1)
    80002f20:	0485bb83          	ld	s7,72(a1)
    80002f24:	0505bc03          	ld	s8,80(a1)
    80002f28:	0585bc83          	ld	s9,88(a1)
    80002f2c:	0605bd03          	ld	s10,96(a1)
    80002f30:	0685bd83          	ld	s11,104(a1)
    80002f34:	8082                	ret

0000000080002f36 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002f36:	1141                	add	sp,sp,-16
    80002f38:	e406                	sd	ra,8(sp)
    80002f3a:	e022                	sd	s0,0(sp)
    80002f3c:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002f3e:	00005597          	auipc	a1,0x5
    80002f42:	43a58593          	add	a1,a1,1082 # 80008378 <states.0+0x30>
    80002f46:	00018517          	auipc	a0,0x18
    80002f4a:	cea50513          	add	a0,a0,-790 # 8001ac30 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	bf4080e7          	jalr	-1036(ra) # 80000b42 <initlock>
}
    80002f56:	60a2                	ld	ra,8(sp)
    80002f58:	6402                	ld	s0,0(sp)
    80002f5a:	0141                	add	sp,sp,16
    80002f5c:	8082                	ret

0000000080002f5e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002f5e:	1141                	add	sp,sp,-16
    80002f60:	e422                	sd	s0,8(sp)
    80002f62:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f64:	00004797          	auipc	a5,0x4
    80002f68:	97c78793          	add	a5,a5,-1668 # 800068e0 <kernelvec>
    80002f6c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f70:	6422                	ld	s0,8(sp)
    80002f72:	0141                	add	sp,sp,16
    80002f74:	8082                	ret

0000000080002f76 <get_time_slice>:
#define total_queue 4

int get_time_slice(int priority)
{
    80002f76:	1141                	add	sp,sp,-16
    80002f78:	e422                	sd	s0,8(sp)
    80002f7a:	0800                	add	s0,sp,16
  switch (priority)
    80002f7c:	4709                	li	a4,2
    80002f7e:	00e50f63          	beq	a0,a4,80002f9c <get_time_slice+0x26>
    80002f82:	87aa                	mv	a5,a0
    80002f84:	470d                	li	a4,3
  case 1:
    return 4;
  case 2:
    return 8;
  case 3:
    return 16;
    80002f86:	4541                	li	a0,16
  switch (priority)
    80002f88:	00e78763          	beq	a5,a4,80002f96 <get_time_slice+0x20>
    80002f8c:	4705                	li	a4,1
    80002f8e:	4511                	li	a0,4
    80002f90:	00e78363          	beq	a5,a4,80002f96 <get_time_slice+0x20>
    return 1;
    80002f94:	4505                	li	a0,1
  default:
    return 1;
  }
}
    80002f96:	6422                	ld	s0,8(sp)
    80002f98:	0141                	add	sp,sp,16
    80002f9a:	8082                	ret
    return 8;
    80002f9c:	4521                	li	a0,8
    80002f9e:	bfe5                	j	80002f96 <get_time_slice+0x20>

0000000080002fa0 <adjust_process_priority>:
//     }
//   }
// }

void adjust_process_priority(struct proc *p)
{
    80002fa0:	7179                	add	sp,sp,-48
    80002fa2:	f406                	sd	ra,40(sp)
    80002fa4:	f022                	sd	s0,32(sp)
    80002fa6:	ec26                	sd	s1,24(sp)
    80002fa8:	e84a                	sd	s2,16(sp)
    80002faa:	e44e                	sd	s3,8(sp)
    80002fac:	1800                	add	s0,sp,48
    80002fae:	84aa                	mv	s1,a0
  // Check if the process has exhausted its time slice
  if (p->ticks_count >= get_time_slice(p->priority))
    80002fb0:	20052983          	lw	s3,512(a0)
    80002fb4:	22052903          	lw	s2,544(a0)
    80002fb8:	854a                	mv	a0,s2
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	fbc080e7          	jalr	-68(ra) # 80002f76 <get_time_slice>
    80002fc2:	00a9c863          	blt	s3,a0,80002fd2 <adjust_process_priority+0x32>
  {
    // Move to the next lower priority queue if not already at the lowest level
    if (p->priority < total_queue - 1) // Assuming total_queue is the number of queues
    80002fc6:	4789                	li	a5,2
    80002fc8:	0127c563          	blt	a5,s2,80002fd2 <adjust_process_priority+0x32>
    {
      // Move the process to a lower priority
      p->priority++;
    80002fcc:	2905                	addw	s2,s2,1
    80002fce:	2324a023          	sw	s2,544(s1)
    // If the process has not exhausted its time slice, we can choose to keep it in the same queue.
    // Optional: You could implement logic here to possibly increase the priority based on behavior.
  }

  // Reset the tick count for the next time slice
  p->ticks_count = 0; // Reset ticks count for the next time slice
    80002fd2:	2004a023          	sw	zero,512(s1)
}
    80002fd6:	70a2                	ld	ra,40(sp)
    80002fd8:	7402                	ld	s0,32(sp)
    80002fda:	64e2                	ld	s1,24(sp)
    80002fdc:	6942                	ld	s2,16(sp)
    80002fde:	69a2                	ld	s3,8(sp)
    80002fe0:	6145                	add	sp,sp,48
    80002fe2:	8082                	ret

0000000080002fe4 <lastscheduled>:

void lastscheduled(void)
{
    80002fe4:	1141                	add	sp,sp,-16
    80002fe6:	e422                	sd	s0,8(sp)
    80002fe8:	0800                	add	s0,sp,16
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002fea:	0000f797          	auipc	a5,0xf
    80002fee:	04678793          	add	a5,a5,70 # 80012030 <proc>
  {
    if (p->state == RUNNING)
    80002ff2:	4611                	li	a2,4
    {
      p->lastscheduledticks = 0;
    }
    else if (p->state == RUNNABLE)
    80002ff4:	458d                	li	a1,3
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002ff6:	00018697          	auipc	a3,0x18
    80002ffa:	c3a68693          	add	a3,a3,-966 # 8001ac30 <tickslock>
    80002ffe:	a039                	j	8000300c <lastscheduled+0x28>
      p->lastscheduledticks = 0;
    80003000:	2207a223          	sw	zero,548(a5)
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80003004:	23078793          	add	a5,a5,560
    80003008:	00d78d63          	beq	a5,a3,80003022 <lastscheduled+0x3e>
    if (p->state == RUNNING)
    8000300c:	4f98                	lw	a4,24(a5)
    8000300e:	fec709e3          	beq	a4,a2,80003000 <lastscheduled+0x1c>
    else if (p->state == RUNNABLE)
    80003012:	feb719e3          	bne	a4,a1,80003004 <lastscheduled+0x20>
    {
      p->lastscheduledticks += 1;
    80003016:	2247a703          	lw	a4,548(a5)
    8000301a:	2705                	addw	a4,a4,1
    8000301c:	22e7a223          	sw	a4,548(a5)
    80003020:	b7d5                	j	80003004 <lastscheduled+0x20>
    }
  }
}
    80003022:	6422                	ld	s0,8(sp)
    80003024:	0141                	add	sp,sp,16
    80003026:	8082                	ret

0000000080003028 <usertrapret>:
}
//
// return to user space
//
void usertrapret(void)
{
    80003028:	1141                	add	sp,sp,-16
    8000302a:	e406                	sd	ra,8(sp)
    8000302c:	e022                	sd	s0,0(sp)
    8000302e:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	986080e7          	jalr	-1658(ra) # 800019b6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003038:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000303c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000303e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003042:	00004697          	auipc	a3,0x4
    80003046:	fbe68693          	add	a3,a3,-66 # 80007000 <_trampoline>
    8000304a:	00004717          	auipc	a4,0x4
    8000304e:	fb670713          	add	a4,a4,-74 # 80007000 <_trampoline>
    80003052:	8f15                	sub	a4,a4,a3
    80003054:	040007b7          	lui	a5,0x4000
    80003058:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000305a:	07b2                	sll	a5,a5,0xc
    8000305c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000305e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003062:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003064:	18002673          	csrr	a2,satp
    80003068:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000306a:	6d30                	ld	a2,88(a0)
    8000306c:	6138                	ld	a4,64(a0)
    8000306e:	6585                	lui	a1,0x1
    80003070:	972e                	add	a4,a4,a1
    80003072:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003074:	6d38                	ld	a4,88(a0)
    80003076:	00000617          	auipc	a2,0x0
    8000307a:	14260613          	add	a2,a2,322 # 800031b8 <usertrap>
    8000307e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80003080:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003082:	8612                	mv	a2,tp
    80003084:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003086:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000308a:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000308e:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003092:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003096:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003098:	6f18                	ld	a4,24(a4)
    8000309a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000309e:	6928                	ld	a0,80(a0)
    800030a0:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800030a2:	00004717          	auipc	a4,0x4
    800030a6:	ffa70713          	add	a4,a4,-6 # 8000709c <userret>
    800030aa:	8f15                	sub	a4,a4,a3
    800030ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800030ae:	577d                	li	a4,-1
    800030b0:	177e                	sll	a4,a4,0x3f
    800030b2:	8d59                	or	a0,a0,a4
    800030b4:	9782                	jalr	a5
}
    800030b6:	60a2                	ld	ra,8(sp)
    800030b8:	6402                	ld	s0,0(sp)
    800030ba:	0141                	add	sp,sp,16
    800030bc:	8082                	ret

00000000800030be <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800030be:	1101                	add	sp,sp,-32
    800030c0:	ec06                	sd	ra,24(sp)
    800030c2:	e822                	sd	s0,16(sp)
    800030c4:	e426                	sd	s1,8(sp)
    800030c6:	e04a                	sd	s2,0(sp)
    800030c8:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800030ca:	00018917          	auipc	s2,0x18
    800030ce:	b6690913          	add	s2,s2,-1178 # 8001ac30 <tickslock>
    800030d2:	854a                	mv	a0,s2
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	afe080e7          	jalr	-1282(ra) # 80000bd2 <acquire>
  ticks++;
    800030dc:	00006497          	auipc	s1,0x6
    800030e0:	91448493          	add	s1,s1,-1772 # 800089f0 <ticks>
    800030e4:	409c                	lw	a5,0(s1)
    800030e6:	2785                	addw	a5,a5,1
    800030e8:	c09c                	sw	a5,0(s1)
  update_time();
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	d40080e7          	jalr	-704(ra) # 80002e2a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800030f2:	8526                	mv	a0,s1
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	6b2080e7          	jalr	1714(ra) # 800027a6 <wakeup>
  release(&tickslock);
    800030fc:	854a                	mv	a0,s2
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b88080e7          	jalr	-1144(ra) # 80000c86 <release>
}
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	64a2                	ld	s1,8(sp)
    8000310c:	6902                	ld	s2,0(sp)
    8000310e:	6105                	add	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003112:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80003116:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80003118:	0807df63          	bgez	a5,800031b6 <devintr+0xa4>
{
    8000311c:	1101                	add	sp,sp,-32
    8000311e:	ec06                	sd	ra,24(sp)
    80003120:	e822                	sd	s0,16(sp)
    80003122:	e426                	sd	s1,8(sp)
    80003124:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80003126:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    8000312a:	46a5                	li	a3,9
    8000312c:	00d70d63          	beq	a4,a3,80003146 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80003130:	577d                	li	a4,-1
    80003132:	177e                	sll	a4,a4,0x3f
    80003134:	0705                	add	a4,a4,1
    return 0;
    80003136:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80003138:	04e78e63          	beq	a5,a4,80003194 <devintr+0x82>
  }
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6105                	add	sp,sp,32
    80003144:	8082                	ret
    int irq = plic_claim();
    80003146:	00004097          	auipc	ra,0x4
    8000314a:	8a2080e7          	jalr	-1886(ra) # 800069e8 <plic_claim>
    8000314e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80003150:	47a9                	li	a5,10
    80003152:	02f50763          	beq	a0,a5,80003180 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80003156:	4785                	li	a5,1
    80003158:	02f50963          	beq	a0,a5,8000318a <devintr+0x78>
    return 1;
    8000315c:	4505                	li	a0,1
    else if (irq)
    8000315e:	dcf9                	beqz	s1,8000313c <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80003160:	85a6                	mv	a1,s1
    80003162:	00005517          	auipc	a0,0x5
    80003166:	21e50513          	add	a0,a0,542 # 80008380 <states.0+0x38>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	41c080e7          	jalr	1052(ra) # 80000586 <printf>
      plic_complete(irq);
    80003172:	8526                	mv	a0,s1
    80003174:	00004097          	auipc	ra,0x4
    80003178:	898080e7          	jalr	-1896(ra) # 80006a0c <plic_complete>
    return 1;
    8000317c:	4505                	li	a0,1
    8000317e:	bf7d                	j	8000313c <devintr+0x2a>
      uartintr();
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	814080e7          	jalr	-2028(ra) # 80000994 <uartintr>
    if (irq)
    80003188:	b7ed                	j	80003172 <devintr+0x60>
      virtio_disk_intr();
    8000318a:	00004097          	auipc	ra,0x4
    8000318e:	d48080e7          	jalr	-696(ra) # 80006ed2 <virtio_disk_intr>
    if (irq)
    80003192:	b7c5                	j	80003172 <devintr+0x60>
    if (cpuid() == 0)
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	7f6080e7          	jalr	2038(ra) # 8000198a <cpuid>
    8000319c:	c901                	beqz	a0,800031ac <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000319e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800031a2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800031a4:	14479073          	csrw	sip,a5
    return 2;
    800031a8:	4509                	li	a0,2
    800031aa:	bf49                	j	8000313c <devintr+0x2a>
      clockintr();
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	f12080e7          	jalr	-238(ra) # 800030be <clockintr>
    800031b4:	b7ed                	j	8000319e <devintr+0x8c>
}
    800031b6:	8082                	ret

00000000800031b8 <usertrap>:
{
    800031b8:	1101                	add	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	e04a                	sd	s2,0(sp)
    800031c2:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031c4:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800031c8:	1007f793          	and	a5,a5,256
    800031cc:	eba1                	bnez	a5,8000321c <usertrap+0x64>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031ce:	00003797          	auipc	a5,0x3
    800031d2:	71278793          	add	a5,a5,1810 # 800068e0 <kernelvec>
    800031d6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	7dc080e7          	jalr	2012(ra) # 800019b6 <myproc>
    800031e2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031e4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031e6:	14102773          	csrr	a4,sepc
    800031ea:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ec:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800031f0:	47a1                	li	a5,8
    800031f2:	02f70d63          	beq	a4,a5,8000322c <usertrap+0x74>
  else if ((which_dev = devintr()) != 0)
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	f1c080e7          	jalr	-228(ra) # 80003112 <devintr>
    800031fe:	892a                	mv	s2,a0
    80003200:	c549                	beqz	a0,8000328a <usertrap+0xd2>
    myproc()->lastscheduledticks = 0;
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	7b4080e7          	jalr	1972(ra) # 800019b6 <myproc>
    8000320a:	22052223          	sw	zero,548(a0)
  if (killed(p))
    8000320e:	8526                	mv	a0,s1
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	7e6080e7          	jalr	2022(ra) # 800029f6 <killed>
    80003218:	cd45                	beqz	a0,800032d0 <usertrap+0x118>
    8000321a:	a075                	j	800032c6 <usertrap+0x10e>
    panic("usertrap: not from user mode");
    8000321c:	00005517          	auipc	a0,0x5
    80003220:	18450513          	add	a0,a0,388 # 800083a0 <states.0+0x58>
    80003224:	ffffd097          	auipc	ra,0xffffd
    80003228:	318080e7          	jalr	792(ra) # 8000053c <panic>
    if (killed(p))
    8000322c:	fffff097          	auipc	ra,0xfffff
    80003230:	7ca080e7          	jalr	1994(ra) # 800029f6 <killed>
    80003234:	e529                	bnez	a0,8000327e <usertrap+0xc6>
    myproc()->lastscheduledticks = 0;
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	780080e7          	jalr	1920(ra) # 800019b6 <myproc>
    8000323e:	22052223          	sw	zero,548(a0)
    p->trapframe->epc += 4;
    80003242:	6cb8                	ld	a4,88(s1)
    80003244:	6f1c                	ld	a5,24(a4)
    80003246:	0791                	add	a5,a5,4
    80003248:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000324a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000324e:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003252:	10079073          	csrw	sstatus,a5
    syscall();
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	528080e7          	jalr	1320(ra) # 8000377e <syscall>
  if (killed(p))
    8000325e:	8526                	mv	a0,s1
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	796080e7          	jalr	1942(ra) # 800029f6 <killed>
    80003268:	ed31                	bnez	a0,800032c4 <usertrap+0x10c>
  usertrapret();
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	dbe080e7          	jalr	-578(ra) # 80003028 <usertrapret>
}
    80003272:	60e2                	ld	ra,24(sp)
    80003274:	6442                	ld	s0,16(sp)
    80003276:	64a2                	ld	s1,8(sp)
    80003278:	6902                	ld	s2,0(sp)
    8000327a:	6105                	add	sp,sp,32
    8000327c:	8082                	ret
      exit(-1);
    8000327e:	557d                	li	a0,-1
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	5f6080e7          	jalr	1526(ra) # 80002876 <exit>
    80003288:	b77d                	j	80003236 <usertrap+0x7e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000328a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000328e:	5890                	lw	a2,48(s1)
    80003290:	00005517          	auipc	a0,0x5
    80003294:	13050513          	add	a0,a0,304 # 800083c0 <states.0+0x78>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2ee080e7          	jalr	750(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032a0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032a4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032a8:	00005517          	auipc	a0,0x5
    800032ac:	14850513          	add	a0,a0,328 # 800083f0 <states.0+0xa8>
    800032b0:	ffffd097          	auipc	ra,0xffffd
    800032b4:	2d6080e7          	jalr	726(ra) # 80000586 <printf>
    setkilled(p);
    800032b8:	8526                	mv	a0,s1
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	710080e7          	jalr	1808(ra) # 800029ca <setkilled>
    800032c2:	bf71                	j	8000325e <usertrap+0xa6>
  if (killed(p))
    800032c4:	4901                	li	s2,0
    exit(-1);
    800032c6:	557d                	li	a0,-1
    800032c8:	fffff097          	auipc	ra,0xfffff
    800032cc:	5ae080e7          	jalr	1454(ra) # 80002876 <exit>
  if (which_dev == 2)
    800032d0:	4789                	li	a5,2
    800032d2:	f8f91ce3          	bne	s2,a5,8000326a <usertrap+0xb2>
      lastscheduled();
    800032d6:	00000097          	auipc	ra,0x0
    800032da:	d0e080e7          	jalr	-754(ra) # 80002fe4 <lastscheduled>
      p->ticks += 1;
    800032de:	2284a783          	lw	a5,552(s1)
    800032e2:	2785                	addw	a5,a5,1
    800032e4:	22f4a423          	sw	a5,552(s1)
      for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800032e8:	0000f797          	auipc	a5,0xf
    800032ec:	d4878793          	add	a5,a5,-696 # 80012030 <proc>
        if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    800032f0:	02f00693          	li	a3,47
    800032f4:	458d                	li	a1,3
      for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800032f6:	00018617          	auipc	a2,0x18
    800032fa:	93a60613          	add	a2,a2,-1734 # 8001ac30 <tickslock>
    800032fe:	a029                	j	80003308 <usertrap+0x150>
    80003300:	23078793          	add	a5,a5,560
    80003304:	02c78863          	beq	a5,a2,80003334 <usertrap+0x17c>
        if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    80003308:	2247a703          	lw	a4,548(a5)
    8000330c:	fee6dae3          	bge	a3,a4,80003300 <usertrap+0x148>
    80003310:	2207a703          	lw	a4,544(a5)
    80003314:	d775                	beqz	a4,80003300 <usertrap+0x148>
    80003316:	4f98                	lw	a4,24(a5)
    80003318:	feb714e3          	bne	a4,a1,80003300 <usertrap+0x148>
          t->lastscheduledticks = 0;
    8000331c:	2207a223          	sw	zero,548(a5)
          t->priority = 0;
    80003320:	2207a023          	sw	zero,544(a5)
          if (p->priority > t->priority)
    80003324:	2204a703          	lw	a4,544(s1)
    80003328:	fce05ce3          	blez	a4,80003300 <usertrap+0x148>
      if (p->priority == 0 && p->ticks == 1)
    8000332c:	2204a703          	lw	a4,544(s1)
            flag = 1;
    80003330:	4785                	li	a5,1
    80003332:	a0e1                	j	800033fa <usertrap+0x242>
      if (p->priority == 0 && p->ticks == 1)
    80003334:	2204a783          	lw	a5,544(s1)
    80003338:	efdd                	bnez	a5,800033f6 <usertrap+0x23e>
    8000333a:	2284a683          	lw	a3,552(s1)
    8000333e:	4705                	li	a4,1
    80003340:	06e68263          	beq	a3,a4,800033a4 <usertrap+0x1ec>
      else if (flag == 1)
    80003344:	4705                	li	a4,1
    80003346:	1ce78a63          	beq	a5,a4,8000351a <usertrap+0x362>
    if (p != 0 && p->state == RUNNING)
    8000334a:	4c98                	lw	a4,24(s1)
    8000334c:	4791                	li	a5,4
    8000334e:	f0f71ee3          	bne	a4,a5,8000326a <usertrap+0xb2>
      p->ticks_count++;
    80003352:	2004a783          	lw	a5,512(s1)
    80003356:	2785                	addw	a5,a5,1
    80003358:	0007871b          	sext.w	a4,a5
    8000335c:	20f4a023          	sw	a5,512(s1)
      if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    80003360:	1f04a783          	lw	a5,496(s1)
    80003364:	f0f053e3          	blez	a5,8000326a <usertrap+0xb2>
    80003368:	f0f741e3          	blt	a4,a5,8000326a <usertrap+0xb2>
    8000336c:	2044a783          	lw	a5,516(s1)
    80003370:	ee078de3          	beqz	a5,8000326a <usertrap+0xb2>
        p->alarm_on = 0; // Disable alarm while handler is running
    80003374:	2004a223          	sw	zero,516(s1)
        p->alarm_tf = kalloc();
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	76a080e7          	jalr	1898(ra) # 80000ae2 <kalloc>
    80003380:	20a4b423          	sd	a0,520(s1)
        if (p->alarm_tf == 0)
    80003384:	1a050063          	beqz	a0,80003524 <usertrap+0x36c>
        memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    80003388:	12000613          	li	a2,288
    8000338c:	6cac                	ld	a1,88(s1)
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	99c080e7          	jalr	-1636(ra) # 80000d2a <memmove>
        p->trapframe->epc = (uint64)p->alarm_handler;
    80003396:	6cbc                	ld	a5,88(s1)
    80003398:	1f84b703          	ld	a4,504(s1)
    8000339c:	ef98                	sd	a4,24(a5)
        p->ticks_count = 0;
    8000339e:	2004a023          	sw	zero,512(s1)
    800033a2:	b5e1                	j	8000326a <usertrap+0xb2>
        p->priority = 1;
    800033a4:	4785                	li	a5,1
    800033a6:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    800033aa:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800033ae:	0000f797          	auipc	a5,0xf
    800033b2:	c8278793          	add	a5,a5,-894 # 80012030 <proc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    800033b6:	02f00613          	li	a2,47
    800033ba:	458d                	li	a1,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800033bc:	00018697          	auipc	a3,0x18
    800033c0:	87468693          	add	a3,a3,-1932 # 8001ac30 <tickslock>
    800033c4:	a029                	j	800033ce <usertrap+0x216>
    800033c6:	23078793          	add	a5,a5,560
    800033ca:	02d78163          	beq	a5,a3,800033ec <usertrap+0x234>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    800033ce:	2247a703          	lw	a4,548(a5)
    800033d2:	fee65ae3          	bge	a2,a4,800033c6 <usertrap+0x20e>
    800033d6:	2207a703          	lw	a4,544(a5)
    800033da:	d775                	beqz	a4,800033c6 <usertrap+0x20e>
    800033dc:	4f98                	lw	a4,24(a5)
    800033de:	feb714e3          	bne	a4,a1,800033c6 <usertrap+0x20e>
            t->lastscheduledticks = 0;
    800033e2:	2207a223          	sw	zero,548(a5)
            t->priority = 0;
    800033e6:	2207a023          	sw	zero,544(a5)
    800033ea:	bff1                	j	800033c6 <usertrap+0x20e>
        yield();
    800033ec:	fffff097          	auipc	ra,0xfffff
    800033f0:	31a080e7          	jalr	794(ra) # 80002706 <yield>
    800033f4:	bf99                	j	8000334a <usertrap+0x192>
      if (p->priority == 0 && p->ticks == 1)
    800033f6:	873e                	mv	a4,a5
      int flag = 0;
    800033f8:	4781                	li	a5,0
      else if (p->priority == 1 && p->ticks == 4)
    800033fa:	4685                	li	a3,1
    800033fc:	02d70b63          	beq	a4,a3,80003432 <usertrap+0x27a>
      else if (p->priority == 2 && p->ticks == 8)
    80003400:	4689                	li	a3,2
    80003402:	0ad71e63          	bne	a4,a3,800034be <usertrap+0x306>
    80003406:	2284a683          	lw	a3,552(s1)
    8000340a:	4721                	li	a4,8
    8000340c:	f2e69ce3          	bne	a3,a4,80003344 <usertrap+0x18c>
        p->priority = 3;
    80003410:	478d                	li	a5,3
    80003412:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    80003416:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    8000341a:	0000f797          	auipc	a5,0xf
    8000341e:	c1678793          	add	a5,a5,-1002 # 80012030 <proc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    80003422:	02f00613          	li	a2,47
    80003426:	458d                	li	a1,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003428:	00018697          	auipc	a3,0x18
    8000342c:	80868693          	add	a3,a3,-2040 # 8001ac30 <tickslock>
    80003430:	a09d                	j	80003496 <usertrap+0x2de>
      else if (p->priority == 1 && p->ticks == 4)
    80003432:	2284a683          	lw	a3,552(s1)
    80003436:	4711                	li	a4,4
    80003438:	f0e696e3          	bne	a3,a4,80003344 <usertrap+0x18c>
        p->priority = 2;
    8000343c:	4789                	li	a5,2
    8000343e:	22f4a023          	sw	a5,544(s1)
        p->ticks = 0;
    80003442:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003446:	0000f797          	auipc	a5,0xf
    8000344a:	bea78793          	add	a5,a5,-1046 # 80012030 <proc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    8000344e:	02f00613          	li	a2,47
    80003452:	458d                	li	a1,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    80003454:	00017697          	auipc	a3,0x17
    80003458:	7dc68693          	add	a3,a3,2012 # 8001ac30 <tickslock>
    8000345c:	a029                	j	80003466 <usertrap+0x2ae>
    8000345e:	23078793          	add	a5,a5,560
    80003462:	02d78163          	beq	a5,a3,80003484 <usertrap+0x2cc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    80003466:	2247a703          	lw	a4,548(a5)
    8000346a:	fee65ae3          	bge	a2,a4,8000345e <usertrap+0x2a6>
    8000346e:	2207a703          	lw	a4,544(a5)
    80003472:	d775                	beqz	a4,8000345e <usertrap+0x2a6>
    80003474:	4f98                	lw	a4,24(a5)
    80003476:	feb714e3          	bne	a4,a1,8000345e <usertrap+0x2a6>
            t->lastscheduledticks = 0;
    8000347a:	2207a223          	sw	zero,548(a5)
            t->priority = 0;
    8000347e:	2207a023          	sw	zero,544(a5)
    80003482:	bff1                	j	8000345e <usertrap+0x2a6>
        yield();
    80003484:	fffff097          	auipc	ra,0xfffff
    80003488:	282080e7          	jalr	642(ra) # 80002706 <yield>
    8000348c:	bd7d                	j	8000334a <usertrap+0x192>
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    8000348e:	23078793          	add	a5,a5,560
    80003492:	02d78163          	beq	a5,a3,800034b4 <usertrap+0x2fc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    80003496:	2247a703          	lw	a4,548(a5)
    8000349a:	fee65ae3          	bge	a2,a4,8000348e <usertrap+0x2d6>
    8000349e:	2207a703          	lw	a4,544(a5)
    800034a2:	d775                	beqz	a4,8000348e <usertrap+0x2d6>
    800034a4:	4f98                	lw	a4,24(a5)
    800034a6:	feb714e3          	bne	a4,a1,8000348e <usertrap+0x2d6>
            t->lastscheduledticks = 0;
    800034aa:	2207a223          	sw	zero,548(a5)
            t->priority = 0;
    800034ae:	2207a023          	sw	zero,544(a5)
    800034b2:	bff1                	j	8000348e <usertrap+0x2d6>
        yield();
    800034b4:	fffff097          	auipc	ra,0xfffff
    800034b8:	252080e7          	jalr	594(ra) # 80002706 <yield>
    800034bc:	b579                	j	8000334a <usertrap+0x192>
      else if (p->priority == 3 && p->ticks == 16)
    800034be:	468d                	li	a3,3
    800034c0:	e8d712e3          	bne	a4,a3,80003344 <usertrap+0x18c>
    800034c4:	2284a683          	lw	a3,552(s1)
    800034c8:	4741                	li	a4,16
    800034ca:	e6e69de3          	bne	a3,a4,80003344 <usertrap+0x18c>
        p->ticks = 0;
    800034ce:	2204a423          	sw	zero,552(s1)
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800034d2:	0000f797          	auipc	a5,0xf
    800034d6:	b5e78793          	add	a5,a5,-1186 # 80012030 <proc>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    800034da:	02f00613          	li	a2,47
    800034de:	458d                	li	a1,3
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
    800034e0:	00017697          	auipc	a3,0x17
    800034e4:	75068693          	add	a3,a3,1872 # 8001ac30 <tickslock>
    800034e8:	a029                	j	800034f2 <usertrap+0x33a>
    800034ea:	23078793          	add	a5,a5,560
    800034ee:	02d78163          	beq	a5,a3,80003510 <usertrap+0x358>
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
    800034f2:	2247a703          	lw	a4,548(a5)
    800034f6:	fee65ae3          	bge	a2,a4,800034ea <usertrap+0x332>
    800034fa:	2207a703          	lw	a4,544(a5)
    800034fe:	d775                	beqz	a4,800034ea <usertrap+0x332>
    80003500:	4f98                	lw	a4,24(a5)
    80003502:	feb714e3          	bne	a4,a1,800034ea <usertrap+0x332>
            t->lastscheduledticks = 0;
    80003506:	2207a223          	sw	zero,548(a5)
            t->priority = 0;
    8000350a:	2207a023          	sw	zero,544(a5)
    8000350e:	bff1                	j	800034ea <usertrap+0x332>
        yield();
    80003510:	fffff097          	auipc	ra,0xfffff
    80003514:	1f6080e7          	jalr	502(ra) # 80002706 <yield>
    80003518:	bd0d                	j	8000334a <usertrap+0x192>
        yield();
    8000351a:	fffff097          	auipc	ra,0xfffff
    8000351e:	1ec080e7          	jalr	492(ra) # 80002706 <yield>
    80003522:	b525                	j	8000334a <usertrap+0x192>
          panic("Error !! usertrap: out of memory");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	eec50513          	add	a0,a0,-276 # 80008410 <states.0+0xc8>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	010080e7          	jalr	16(ra) # 8000053c <panic>

0000000080003534 <kerneltrap>:
{
    80003534:	7179                	add	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003542:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003546:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000354a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    8000354e:	1004f793          	and	a5,s1,256
    80003552:	cb85                	beqz	a5,80003582 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003554:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003558:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    8000355a:	ef85                	bnez	a5,80003592 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	bb6080e7          	jalr	-1098(ra) # 80003112 <devintr>
    80003564:	cd1d                	beqz	a0,800035a2 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003566:	4789                	li	a5,2
    80003568:	06f50a63          	beq	a0,a5,800035dc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000356c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003570:	10049073          	csrw	sstatus,s1
}
    80003574:	70a2                	ld	ra,40(sp)
    80003576:	7402                	ld	s0,32(sp)
    80003578:	64e2                	ld	s1,24(sp)
    8000357a:	6942                	ld	s2,16(sp)
    8000357c:	69a2                	ld	s3,8(sp)
    8000357e:	6145                	add	sp,sp,48
    80003580:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	eb650513          	add	a0,a0,-330 # 80008438 <states.0+0xf0>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fb2080e7          	jalr	-78(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	ece50513          	add	a0,a0,-306 # 80008460 <states.0+0x118>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	fa2080e7          	jalr	-94(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800035a2:	85ce                	mv	a1,s3
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	edc50513          	add	a0,a0,-292 # 80008480 <states.0+0x138>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	fda080e7          	jalr	-38(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035b4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035b8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800035bc:	00005517          	auipc	a0,0x5
    800035c0:	ed450513          	add	a0,a0,-300 # 80008490 <states.0+0x148>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	fc2080e7          	jalr	-62(ra) # 80000586 <printf>
    panic("kerneltrap");
    800035cc:	00005517          	auipc	a0,0x5
    800035d0:	edc50513          	add	a0,a0,-292 # 800084a8 <states.0+0x160>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	f68080e7          	jalr	-152(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035dc:	ffffe097          	auipc	ra,0xffffe
    800035e0:	3da080e7          	jalr	986(ra) # 800019b6 <myproc>
    800035e4:	d541                	beqz	a0,8000356c <kerneltrap+0x38>
    800035e6:	ffffe097          	auipc	ra,0xffffe
    800035ea:	3d0080e7          	jalr	976(ra) # 800019b6 <myproc>
    800035ee:	4d18                	lw	a4,24(a0)
    800035f0:	4791                	li	a5,4
    800035f2:	f6f71de3          	bne	a4,a5,8000356c <kerneltrap+0x38>
    yield();
    800035f6:	fffff097          	auipc	ra,0xfffff
    800035fa:	110080e7          	jalr	272(ra) # 80002706 <yield>
    800035fe:	b7bd                	j	8000356c <kerneltrap+0x38>

0000000080003600 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003600:	1101                	add	sp,sp,-32
    80003602:	ec06                	sd	ra,24(sp)
    80003604:	e822                	sd	s0,16(sp)
    80003606:	e426                	sd	s1,8(sp)
    80003608:	1000                	add	s0,sp,32
    8000360a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000360c:	ffffe097          	auipc	ra,0xffffe
    80003610:	3aa080e7          	jalr	938(ra) # 800019b6 <myproc>
  switch (n)
    80003614:	4795                	li	a5,5
    80003616:	0497e163          	bltu	a5,s1,80003658 <argraw+0x58>
    8000361a:	048a                	sll	s1,s1,0x2
    8000361c:	00005717          	auipc	a4,0x5
    80003620:	ec470713          	add	a4,a4,-316 # 800084e0 <states.0+0x198>
    80003624:	94ba                	add	s1,s1,a4
    80003626:	409c                	lw	a5,0(s1)
    80003628:	97ba                	add	a5,a5,a4
    8000362a:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    8000362c:	6d3c                	ld	a5,88(a0)
    8000362e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6105                	add	sp,sp,32
    80003638:	8082                	ret
    return p->trapframe->a1;
    8000363a:	6d3c                	ld	a5,88(a0)
    8000363c:	7fa8                	ld	a0,120(a5)
    8000363e:	bfcd                	j	80003630 <argraw+0x30>
    return p->trapframe->a2;
    80003640:	6d3c                	ld	a5,88(a0)
    80003642:	63c8                	ld	a0,128(a5)
    80003644:	b7f5                	j	80003630 <argraw+0x30>
    return p->trapframe->a3;
    80003646:	6d3c                	ld	a5,88(a0)
    80003648:	67c8                	ld	a0,136(a5)
    8000364a:	b7dd                	j	80003630 <argraw+0x30>
    return p->trapframe->a4;
    8000364c:	6d3c                	ld	a5,88(a0)
    8000364e:	6bc8                	ld	a0,144(a5)
    80003650:	b7c5                	j	80003630 <argraw+0x30>
    return p->trapframe->a5;
    80003652:	6d3c                	ld	a5,88(a0)
    80003654:	6fc8                	ld	a0,152(a5)
    80003656:	bfe9                	j	80003630 <argraw+0x30>
  panic("argraw");
    80003658:	00005517          	auipc	a0,0x5
    8000365c:	e6050513          	add	a0,a0,-416 # 800084b8 <states.0+0x170>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	edc080e7          	jalr	-292(ra) # 8000053c <panic>

0000000080003668 <fetchaddr>:
{
    80003668:	1101                	add	sp,sp,-32
    8000366a:	ec06                	sd	ra,24(sp)
    8000366c:	e822                	sd	s0,16(sp)
    8000366e:	e426                	sd	s1,8(sp)
    80003670:	e04a                	sd	s2,0(sp)
    80003672:	1000                	add	s0,sp,32
    80003674:	84aa                	mv	s1,a0
    80003676:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003678:	ffffe097          	auipc	ra,0xffffe
    8000367c:	33e080e7          	jalr	830(ra) # 800019b6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003680:	653c                	ld	a5,72(a0)
    80003682:	02f4f863          	bgeu	s1,a5,800036b2 <fetchaddr+0x4a>
    80003686:	00848713          	add	a4,s1,8
    8000368a:	02e7e663          	bltu	a5,a4,800036b6 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000368e:	46a1                	li	a3,8
    80003690:	8626                	mv	a2,s1
    80003692:	85ca                	mv	a1,s2
    80003694:	6928                	ld	a0,80(a0)
    80003696:	ffffe097          	auipc	ra,0xffffe
    8000369a:	05c080e7          	jalr	92(ra) # 800016f2 <copyin>
    8000369e:	00a03533          	snez	a0,a0
    800036a2:	40a00533          	neg	a0,a0
}
    800036a6:	60e2                	ld	ra,24(sp)
    800036a8:	6442                	ld	s0,16(sp)
    800036aa:	64a2                	ld	s1,8(sp)
    800036ac:	6902                	ld	s2,0(sp)
    800036ae:	6105                	add	sp,sp,32
    800036b0:	8082                	ret
    return -1;
    800036b2:	557d                	li	a0,-1
    800036b4:	bfcd                	j	800036a6 <fetchaddr+0x3e>
    800036b6:	557d                	li	a0,-1
    800036b8:	b7fd                	j	800036a6 <fetchaddr+0x3e>

00000000800036ba <fetchstr>:
{
    800036ba:	7179                	add	sp,sp,-48
    800036bc:	f406                	sd	ra,40(sp)
    800036be:	f022                	sd	s0,32(sp)
    800036c0:	ec26                	sd	s1,24(sp)
    800036c2:	e84a                	sd	s2,16(sp)
    800036c4:	e44e                	sd	s3,8(sp)
    800036c6:	1800                	add	s0,sp,48
    800036c8:	892a                	mv	s2,a0
    800036ca:	84ae                	mv	s1,a1
    800036cc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800036ce:	ffffe097          	auipc	ra,0xffffe
    800036d2:	2e8080e7          	jalr	744(ra) # 800019b6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800036d6:	86ce                	mv	a3,s3
    800036d8:	864a                	mv	a2,s2
    800036da:	85a6                	mv	a1,s1
    800036dc:	6928                	ld	a0,80(a0)
    800036de:	ffffe097          	auipc	ra,0xffffe
    800036e2:	0a2080e7          	jalr	162(ra) # 80001780 <copyinstr>
    800036e6:	00054e63          	bltz	a0,80003702 <fetchstr+0x48>
  return strlen(buf);
    800036ea:	8526                	mv	a0,s1
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	75c080e7          	jalr	1884(ra) # 80000e48 <strlen>
}
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6145                	add	sp,sp,48
    80003700:	8082                	ret
    return -1;
    80003702:	557d                	li	a0,-1
    80003704:	bfc5                	j	800036f4 <fetchstr+0x3a>

0000000080003706 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003706:	1101                	add	sp,sp,-32
    80003708:	ec06                	sd	ra,24(sp)
    8000370a:	e822                	sd	s0,16(sp)
    8000370c:	e426                	sd	s1,8(sp)
    8000370e:	1000                	add	s0,sp,32
    80003710:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003712:	00000097          	auipc	ra,0x0
    80003716:	eee080e7          	jalr	-274(ra) # 80003600 <argraw>
    8000371a:	c088                	sw	a0,0(s1)
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6105                	add	sp,sp,32
    80003724:	8082                	ret

0000000080003726 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003726:	1101                	add	sp,sp,-32
    80003728:	ec06                	sd	ra,24(sp)
    8000372a:	e822                	sd	s0,16(sp)
    8000372c:	e426                	sd	s1,8(sp)
    8000372e:	1000                	add	s0,sp,32
    80003730:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003732:	00000097          	auipc	ra,0x0
    80003736:	ece080e7          	jalr	-306(ra) # 80003600 <argraw>
    8000373a:	e088                	sd	a0,0(s1)
}
    8000373c:	60e2                	ld	ra,24(sp)
    8000373e:	6442                	ld	s0,16(sp)
    80003740:	64a2                	ld	s1,8(sp)
    80003742:	6105                	add	sp,sp,32
    80003744:	8082                	ret

0000000080003746 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003746:	7179                	add	sp,sp,-48
    80003748:	f406                	sd	ra,40(sp)
    8000374a:	f022                	sd	s0,32(sp)
    8000374c:	ec26                	sd	s1,24(sp)
    8000374e:	e84a                	sd	s2,16(sp)
    80003750:	1800                	add	s0,sp,48
    80003752:	84ae                	mv	s1,a1
    80003754:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003756:	fd840593          	add	a1,s0,-40
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	fcc080e7          	jalr	-52(ra) # 80003726 <argaddr>
  return fetchstr(addr, buf, max);
    80003762:	864a                	mv	a2,s2
    80003764:	85a6                	mv	a1,s1
    80003766:	fd843503          	ld	a0,-40(s0)
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	f50080e7          	jalr	-176(ra) # 800036ba <fetchstr>
}
    80003772:	70a2                	ld	ra,40(sp)
    80003774:	7402                	ld	s0,32(sp)
    80003776:	64e2                	ld	s1,24(sp)
    80003778:	6942                	ld	s2,16(sp)
    8000377a:	6145                	add	sp,sp,48
    8000377c:	8082                	ret

000000008000377e <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    8000377e:	1101                	add	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	e04a                	sd	s2,0(sp)
    80003788:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000378a:	ffffe097          	auipc	ra,0xffffe
    8000378e:	22c080e7          	jalr	556(ra) # 800019b6 <myproc>
    80003792:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003794:	05853903          	ld	s2,88(a0)
    80003798:	0a893783          	ld	a5,168(s2)
    8000379c:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800037a0:	37fd                	addw	a5,a5,-1
    800037a2:	4765                	li	a4,25
    800037a4:	02f76763          	bltu	a4,a5,800037d2 <syscall+0x54>
    800037a8:	00369713          	sll	a4,a3,0x3
    800037ac:	00005797          	auipc	a5,0x5
    800037b0:	d4c78793          	add	a5,a5,-692 # 800084f8 <syscalls>
    800037b4:	97ba                	add	a5,a5,a4
    800037b6:	6398                	ld	a4,0(a5)
    800037b8:	cf09                	beqz	a4,800037d2 <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    800037ba:	068a                	sll	a3,a3,0x2
    800037bc:	00d504b3          	add	s1,a0,a3
    800037c0:	1704a783          	lw	a5,368(s1)
    800037c4:	2785                	addw	a5,a5,1
    800037c6:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    800037ca:	9702                	jalr	a4
    800037cc:	06a93823          	sd	a0,112(s2)
    800037d0:	a839                	j	800037ee <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800037d2:	15848613          	add	a2,s1,344
    800037d6:	588c                	lw	a1,48(s1)
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	ce850513          	add	a0,a0,-792 # 800084c0 <states.0+0x178>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	da6080e7          	jalr	-602(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800037e8:	6cbc                	ld	a5,88(s1)
    800037ea:	577d                	li	a4,-1
    800037ec:	fbb8                	sd	a4,112(a5)
  }
}
    800037ee:	60e2                	ld	ra,24(sp)
    800037f0:	6442                	ld	s0,16(sp)
    800037f2:	64a2                	ld	s1,8(sp)
    800037f4:	6902                	ld	s2,0(sp)
    800037f6:	6105                	add	sp,sp,32
    800037f8:	8082                	ret

00000000800037fa <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    800037fa:	1101                	add	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003802:	fec40593          	add	a1,s0,-20
    80003806:	4501                	li	a0,0
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	efe080e7          	jalr	-258(ra) # 80003706 <argint>
  exit(n);
    80003810:	fec42503          	lw	a0,-20(s0)
    80003814:	fffff097          	auipc	ra,0xfffff
    80003818:	062080e7          	jalr	98(ra) # 80002876 <exit>
  return 0; // not reached
}
    8000381c:	4501                	li	a0,0
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	6105                	add	sp,sp,32
    80003824:	8082                	ret

0000000080003826 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003826:	1141                	add	sp,sp,-16
    80003828:	e406                	sd	ra,8(sp)
    8000382a:	e022                	sd	s0,0(sp)
    8000382c:	0800                	add	s0,sp,16
  return myproc()->pid;
    8000382e:	ffffe097          	auipc	ra,0xffffe
    80003832:	188080e7          	jalr	392(ra) # 800019b6 <myproc>
}
    80003836:	5908                	lw	a0,48(a0)
    80003838:	60a2                	ld	ra,8(sp)
    8000383a:	6402                	ld	s0,0(sp)
    8000383c:	0141                	add	sp,sp,16
    8000383e:	8082                	ret

0000000080003840 <sys_fork>:

uint64
sys_fork(void)
{
    80003840:	1141                	add	sp,sp,-16
    80003842:	e406                	sd	ra,8(sp)
    80003844:	e022                	sd	s0,0(sp)
    80003846:	0800                	add	s0,sp,16
  return fork();
    80003848:	ffffe097          	auipc	ra,0xffffe
    8000384c:	57e080e7          	jalr	1406(ra) # 80001dc6 <fork>
}
    80003850:	60a2                	ld	ra,8(sp)
    80003852:	6402                	ld	s0,0(sp)
    80003854:	0141                	add	sp,sp,16
    80003856:	8082                	ret

0000000080003858 <sys_wait>:

uint64
sys_wait(void)
{
    80003858:	1101                	add	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003860:	fe840593          	add	a1,s0,-24
    80003864:	4501                	li	a0,0
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	ec0080e7          	jalr	-320(ra) # 80003726 <argaddr>
  return wait(p);
    8000386e:	fe843503          	ld	a0,-24(s0)
    80003872:	fffff097          	auipc	ra,0xfffff
    80003876:	1b6080e7          	jalr	438(ra) # 80002a28 <wait>
}
    8000387a:	60e2                	ld	ra,24(sp)
    8000387c:	6442                	ld	s0,16(sp)
    8000387e:	6105                	add	sp,sp,32
    80003880:	8082                	ret

0000000080003882 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003882:	7179                	add	sp,sp,-48
    80003884:	f406                	sd	ra,40(sp)
    80003886:	f022                	sd	s0,32(sp)
    80003888:	ec26                	sd	s1,24(sp)
    8000388a:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000388c:	fdc40593          	add	a1,s0,-36
    80003890:	4501                	li	a0,0
    80003892:	00000097          	auipc	ra,0x0
    80003896:	e74080e7          	jalr	-396(ra) # 80003706 <argint>
  addr = myproc()->sz;
    8000389a:	ffffe097          	auipc	ra,0xffffe
    8000389e:	11c080e7          	jalr	284(ra) # 800019b6 <myproc>
    800038a2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800038a4:	fdc42503          	lw	a0,-36(s0)
    800038a8:	ffffe097          	auipc	ra,0xffffe
    800038ac:	4c2080e7          	jalr	1218(ra) # 80001d6a <growproc>
    800038b0:	00054863          	bltz	a0,800038c0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800038b4:	8526                	mv	a0,s1
    800038b6:	70a2                	ld	ra,40(sp)
    800038b8:	7402                	ld	s0,32(sp)
    800038ba:	64e2                	ld	s1,24(sp)
    800038bc:	6145                	add	sp,sp,48
    800038be:	8082                	ret
    return -1;
    800038c0:	54fd                	li	s1,-1
    800038c2:	bfcd                	j	800038b4 <sys_sbrk+0x32>

00000000800038c4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800038c4:	7139                	add	sp,sp,-64
    800038c6:	fc06                	sd	ra,56(sp)
    800038c8:	f822                	sd	s0,48(sp)
    800038ca:	f426                	sd	s1,40(sp)
    800038cc:	f04a                	sd	s2,32(sp)
    800038ce:	ec4e                	sd	s3,24(sp)
    800038d0:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800038d2:	fcc40593          	add	a1,s0,-52
    800038d6:	4501                	li	a0,0
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	e2e080e7          	jalr	-466(ra) # 80003706 <argint>
  acquire(&tickslock);
    800038e0:	00017517          	auipc	a0,0x17
    800038e4:	35050513          	add	a0,a0,848 # 8001ac30 <tickslock>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	2ea080e7          	jalr	746(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    800038f0:	00005917          	auipc	s2,0x5
    800038f4:	10092903          	lw	s2,256(s2) # 800089f0 <ticks>
  while (ticks - ticks0 < n)
    800038f8:	fcc42783          	lw	a5,-52(s0)
    800038fc:	cf9d                	beqz	a5,8000393a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800038fe:	00017997          	auipc	s3,0x17
    80003902:	33298993          	add	s3,s3,818 # 8001ac30 <tickslock>
    80003906:	00005497          	auipc	s1,0x5
    8000390a:	0ea48493          	add	s1,s1,234 # 800089f0 <ticks>
    if (killed(myproc()))
    8000390e:	ffffe097          	auipc	ra,0xffffe
    80003912:	0a8080e7          	jalr	168(ra) # 800019b6 <myproc>
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	0e0080e7          	jalr	224(ra) # 800029f6 <killed>
    8000391e:	ed15                	bnez	a0,8000395a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003920:	85ce                	mv	a1,s3
    80003922:	8526                	mv	a0,s1
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	e1e080e7          	jalr	-482(ra) # 80002742 <sleep>
  while (ticks - ticks0 < n)
    8000392c:	409c                	lw	a5,0(s1)
    8000392e:	412787bb          	subw	a5,a5,s2
    80003932:	fcc42703          	lw	a4,-52(s0)
    80003936:	fce7ece3          	bltu	a5,a4,8000390e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000393a:	00017517          	auipc	a0,0x17
    8000393e:	2f650513          	add	a0,a0,758 # 8001ac30 <tickslock>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	344080e7          	jalr	836(ra) # 80000c86 <release>
  return 0;
    8000394a:	4501                	li	a0,0
}
    8000394c:	70e2                	ld	ra,56(sp)
    8000394e:	7442                	ld	s0,48(sp)
    80003950:	74a2                	ld	s1,40(sp)
    80003952:	7902                	ld	s2,32(sp)
    80003954:	69e2                	ld	s3,24(sp)
    80003956:	6121                	add	sp,sp,64
    80003958:	8082                	ret
      release(&tickslock);
    8000395a:	00017517          	auipc	a0,0x17
    8000395e:	2d650513          	add	a0,a0,726 # 8001ac30 <tickslock>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	324080e7          	jalr	804(ra) # 80000c86 <release>
      return -1;
    8000396a:	557d                	li	a0,-1
    8000396c:	b7c5                	j	8000394c <sys_sleep+0x88>

000000008000396e <sys_kill>:

uint64
sys_kill(void)
{
    8000396e:	1101                	add	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80003976:	fec40593          	add	a1,s0,-20
    8000397a:	4501                	li	a0,0
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	d8a080e7          	jalr	-630(ra) # 80003706 <argint>
  return kill(pid);
    80003984:	fec42503          	lw	a0,-20(s0)
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	fd0080e7          	jalr	-48(ra) # 80002958 <kill>
}
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	6105                	add	sp,sp,32
    80003996:	8082                	ret

0000000080003998 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003998:	1101                	add	sp,sp,-32
    8000399a:	ec06                	sd	ra,24(sp)
    8000399c:	e822                	sd	s0,16(sp)
    8000399e:	e426                	sd	s1,8(sp)
    800039a0:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039a2:	00017517          	auipc	a0,0x17
    800039a6:	28e50513          	add	a0,a0,654 # 8001ac30 <tickslock>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	228080e7          	jalr	552(ra) # 80000bd2 <acquire>
  xticks = ticks;
    800039b2:	00005497          	auipc	s1,0x5
    800039b6:	03e4a483          	lw	s1,62(s1) # 800089f0 <ticks>
  release(&tickslock);
    800039ba:	00017517          	auipc	a0,0x17
    800039be:	27650513          	add	a0,a0,630 # 8001ac30 <tickslock>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	2c4080e7          	jalr	708(ra) # 80000c86 <release>
  return xticks;
}
    800039ca:	02049513          	sll	a0,s1,0x20
    800039ce:	9101                	srl	a0,a0,0x20
    800039d0:	60e2                	ld	ra,24(sp)
    800039d2:	6442                	ld	s0,16(sp)
    800039d4:	64a2                	ld	s1,8(sp)
    800039d6:	6105                	add	sp,sp,32
    800039d8:	8082                	ret

00000000800039da <sys_waitx>:

uint64
sys_waitx(void)
{
    800039da:	7139                	add	sp,sp,-64
    800039dc:	fc06                	sd	ra,56(sp)
    800039de:	f822                	sd	s0,48(sp)
    800039e0:	f426                	sd	s1,40(sp)
    800039e2:	f04a                	sd	s2,32(sp)
    800039e4:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800039e6:	fd840593          	add	a1,s0,-40
    800039ea:	4501                	li	a0,0
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	d3a080e7          	jalr	-710(ra) # 80003726 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800039f4:	fd040593          	add	a1,s0,-48
    800039f8:	4505                	li	a0,1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	d2c080e7          	jalr	-724(ra) # 80003726 <argaddr>
  argaddr(2, &addr2);
    80003a02:	fc840593          	add	a1,s0,-56
    80003a06:	4509                	li	a0,2
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	d1e080e7          	jalr	-738(ra) # 80003726 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003a10:	fc040613          	add	a2,s0,-64
    80003a14:	fc440593          	add	a1,s0,-60
    80003a18:	fd843503          	ld	a0,-40(s0)
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	2ae080e7          	jalr	686(ra) # 80002cca <waitx>
    80003a24:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003a26:	ffffe097          	auipc	ra,0xffffe
    80003a2a:	f90080e7          	jalr	-112(ra) # 800019b6 <myproc>
    80003a2e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003a30:	4691                	li	a3,4
    80003a32:	fc440613          	add	a2,s0,-60
    80003a36:	fd043583          	ld	a1,-48(s0)
    80003a3a:	6928                	ld	a0,80(a0)
    80003a3c:	ffffe097          	auipc	ra,0xffffe
    80003a40:	c2a080e7          	jalr	-982(ra) # 80001666 <copyout>
    return -1;
    80003a44:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003a46:	00054f63          	bltz	a0,80003a64 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003a4a:	4691                	li	a3,4
    80003a4c:	fc040613          	add	a2,s0,-64
    80003a50:	fc843583          	ld	a1,-56(s0)
    80003a54:	68a8                	ld	a0,80(s1)
    80003a56:	ffffe097          	auipc	ra,0xffffe
    80003a5a:	c10080e7          	jalr	-1008(ra) # 80001666 <copyout>
    80003a5e:	00054a63          	bltz	a0,80003a72 <sys_waitx+0x98>
    return -1;
  return ret;
    80003a62:	87ca                	mv	a5,s2
}
    80003a64:	853e                	mv	a0,a5
    80003a66:	70e2                	ld	ra,56(sp)
    80003a68:	7442                	ld	s0,48(sp)
    80003a6a:	74a2                	ld	s1,40(sp)
    80003a6c:	7902                	ld	s2,32(sp)
    80003a6e:	6121                	add	sp,sp,64
    80003a70:	8082                	ret
    return -1;
    80003a72:	57fd                	li	a5,-1
    80003a74:	bfc5                	j	80003a64 <sys_waitx+0x8a>

0000000080003a76 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    80003a76:	7179                	add	sp,sp,-48
    80003a78:	f406                	sd	ra,40(sp)
    80003a7a:	f022                	sd	s0,32(sp)
    80003a7c:	ec26                	sd	s1,24(sp)
    80003a7e:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    80003a80:	ffffe097          	auipc	ra,0xffffe
    80003a84:	f36080e7          	jalr	-202(ra) # 800019b6 <myproc>
    80003a88:	84aa                	mv	s1,a0
  // for (int i = 0; i < 31; i++)
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }

  argint(0, &mask);
    80003a8a:	fdc40593          	add	a1,s0,-36
    80003a8e:	4501                	li	a0,0
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	c76080e7          	jalr	-906(ra) # 80003706 <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    80003a98:	fdc42583          	lw	a1,-36(s0)
    80003a9c:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    80003aa0:	4781                	li	a5,0
  int count = 0;
    80003aa2:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    80003aa4:	467d                	li	a2,31
    80003aa6:	a029                	j	80003ab0 <sys_getSysCount+0x3a>
    80003aa8:	2785                	addw	a5,a5,1
    80003aaa:	0691                	add	a3,a3,4
    80003aac:	00c78963          	beq	a5,a2,80003abe <sys_getSysCount+0x48>
    if (mask & (1 << i))
    80003ab0:	40f5d73b          	sraw	a4,a1,a5
    80003ab4:	8b05                	and	a4,a4,1
    80003ab6:	db6d                	beqz	a4,80003aa8 <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i - 1]; // Add up the syscall counts
    80003ab8:	4298                	lw	a4,0(a3)
    80003aba:	9d39                	addw	a0,a0,a4
    80003abc:	b7f5                	j	80003aa8 <sys_getSysCount+0x32>
    }
  }

  return count;
}
    80003abe:	70a2                	ld	ra,40(sp)
    80003ac0:	7402                	ld	s0,32(sp)
    80003ac2:	64e2                	ld	s1,24(sp)
    80003ac4:	6145                	add	sp,sp,48
    80003ac6:	8082                	ret

0000000080003ac8 <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    80003ac8:	1101                	add	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    80003ad0:	fec40593          	add	a1,s0,-20
    80003ad4:	4501                	li	a0,0
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	c30080e7          	jalr	-976(ra) # 80003706 <argint>

  argaddr(1, &handler);
    80003ade:	fe040593          	add	a1,s0,-32
    80003ae2:	4505                	li	a0,1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	c42080e7          	jalr	-958(ra) # 80003726 <argaddr>

  struct proc *p = myproc();
    80003aec:	ffffe097          	auipc	ra,0xffffe
    80003af0:	eca080e7          	jalr	-310(ra) # 800019b6 <myproc>
  p->alarm_interval = interval;
    80003af4:	fec42783          	lw	a5,-20(s0)
    80003af8:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void (*)())handler;
    80003afc:	fe043703          	ld	a4,-32(s0)
    80003b00:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    80003b04:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    80003b08:	00f027b3          	sgtz	a5,a5
    80003b0c:	20f52223          	sw	a5,516(a0)

  return 0;
}
    80003b10:	4501                	li	a0,0
    80003b12:	60e2                	ld	ra,24(sp)
    80003b14:	6442                	ld	s0,16(sp)
    80003b16:	6105                	add	sp,sp,32
    80003b18:	8082                	ret

0000000080003b1a <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    80003b1a:	1101                	add	sp,sp,-32
    80003b1c:	ec06                	sd	ra,24(sp)
    80003b1e:	e822                	sd	s0,16(sp)
    80003b20:	e426                	sd	s1,8(sp)
    80003b22:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80003b24:	ffffe097          	auipc	ra,0xffffe
    80003b28:	e92080e7          	jalr	-366(ra) # 800019b6 <myproc>

  if (p->alarm_tf)
    80003b2c:	20853583          	ld	a1,520(a0)
    80003b30:	c585                	beqz	a1,80003b58 <sys_sigreturn+0x3e>
    80003b32:	84aa                	mv	s1,a0
  {
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    80003b34:	12000613          	li	a2,288
    80003b38:	6d28                	ld	a0,88(a0)
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	1f0080e7          	jalr	496(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    80003b42:	2084b503          	ld	a0,520(s1)
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	e9e080e7          	jalr	-354(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    80003b4e:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1; // Re-enable the alarm
    80003b52:	4785                	li	a5,1
    80003b54:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret(); // function that returns the command back to the user space
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	4d0080e7          	jalr	1232(ra) # 80003028 <usertrapret>
  return 0;
}
    80003b60:	4501                	li	a0,0
    80003b62:	60e2                	ld	ra,24(sp)
    80003b64:	6442                	ld	s0,16(sp)
    80003b66:	64a2                	ld	s1,8(sp)
    80003b68:	6105                	add	sp,sp,32
    80003b6a:	8082                	ret

0000000080003b6c <sys_settickets>:

// settickets system call
uint64 sys_settickets(void)
{
    80003b6c:	1101                	add	sp,sp,-32
    80003b6e:	ec06                	sd	ra,24(sp)
    80003b70:	e822                	sd	s0,16(sp)
    80003b72:	1000                	add	s0,sp,32
  int n;

  // Get the number of tickets from the user
  argint(0, &n);
    80003b74:	fec40593          	add	a1,s0,-20
    80003b78:	4501                	li	a0,0
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	b8c080e7          	jalr	-1140(ra) # 80003706 <argint>
  // Ensure the ticket number is valid (greater than 0)
  if (n < 1)
    80003b82:	fec42783          	lw	a5,-20(s0)
    80003b86:	00f05f63          	blez	a5,80003ba4 <sys_settickets+0x38>
    printf("entered ticket is invalid error");
    return -1; // Error: invalid ticket count
  }

  // Set the calling process's ticket count
  myproc()->tickets = n;
    80003b8a:	ffffe097          	auipc	ra,0xffffe
    80003b8e:	e2c080e7          	jalr	-468(ra) # 800019b6 <myproc>
    80003b92:	fec42783          	lw	a5,-20(s0)
    80003b96:	20f52823          	sw	a5,528(a0)

  return 0; // Success
    80003b9a:	4501                	li	a0,0
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	6105                	add	sp,sp,32
    80003ba2:	8082                	ret
    printf("entered ticket is invalid error");
    80003ba4:	00005517          	auipc	a0,0x5
    80003ba8:	a2c50513          	add	a0,a0,-1492 # 800085d0 <syscalls+0xd8>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	9da080e7          	jalr	-1574(ra) # 80000586 <printf>
    return -1; // Error: invalid ticket count
    80003bb4:	557d                	li	a0,-1
    80003bb6:	b7dd                	j	80003b9c <sys_settickets+0x30>

0000000080003bb8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003bb8:	7179                	add	sp,sp,-48
    80003bba:	f406                	sd	ra,40(sp)
    80003bbc:	f022                	sd	s0,32(sp)
    80003bbe:	ec26                	sd	s1,24(sp)
    80003bc0:	e84a                	sd	s2,16(sp)
    80003bc2:	e44e                	sd	s3,8(sp)
    80003bc4:	e052                	sd	s4,0(sp)
    80003bc6:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003bc8:	00005597          	auipc	a1,0x5
    80003bcc:	a2858593          	add	a1,a1,-1496 # 800085f0 <syscalls+0xf8>
    80003bd0:	00017517          	auipc	a0,0x17
    80003bd4:	07850513          	add	a0,a0,120 # 8001ac48 <bcache>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	f6a080e7          	jalr	-150(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003be0:	0001f797          	auipc	a5,0x1f
    80003be4:	06878793          	add	a5,a5,104 # 80022c48 <bcache+0x8000>
    80003be8:	0001f717          	auipc	a4,0x1f
    80003bec:	2c870713          	add	a4,a4,712 # 80022eb0 <bcache+0x8268>
    80003bf0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003bf4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003bf8:	00017497          	auipc	s1,0x17
    80003bfc:	06848493          	add	s1,s1,104 # 8001ac60 <bcache+0x18>
    b->next = bcache.head.next;
    80003c00:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003c02:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003c04:	00005a17          	auipc	s4,0x5
    80003c08:	9f4a0a13          	add	s4,s4,-1548 # 800085f8 <syscalls+0x100>
    b->next = bcache.head.next;
    80003c0c:	2b893783          	ld	a5,696(s2)
    80003c10:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003c12:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003c16:	85d2                	mv	a1,s4
    80003c18:	01048513          	add	a0,s1,16
    80003c1c:	00001097          	auipc	ra,0x1
    80003c20:	496080e7          	jalr	1174(ra) # 800050b2 <initsleeplock>
    bcache.head.next->prev = b;
    80003c24:	2b893783          	ld	a5,696(s2)
    80003c28:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003c2a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003c2e:	45848493          	add	s1,s1,1112
    80003c32:	fd349de3          	bne	s1,s3,80003c0c <binit+0x54>
  }
}
    80003c36:	70a2                	ld	ra,40(sp)
    80003c38:	7402                	ld	s0,32(sp)
    80003c3a:	64e2                	ld	s1,24(sp)
    80003c3c:	6942                	ld	s2,16(sp)
    80003c3e:	69a2                	ld	s3,8(sp)
    80003c40:	6a02                	ld	s4,0(sp)
    80003c42:	6145                	add	sp,sp,48
    80003c44:	8082                	ret

0000000080003c46 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003c46:	7179                	add	sp,sp,-48
    80003c48:	f406                	sd	ra,40(sp)
    80003c4a:	f022                	sd	s0,32(sp)
    80003c4c:	ec26                	sd	s1,24(sp)
    80003c4e:	e84a                	sd	s2,16(sp)
    80003c50:	e44e                	sd	s3,8(sp)
    80003c52:	1800                	add	s0,sp,48
    80003c54:	892a                	mv	s2,a0
    80003c56:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003c58:	00017517          	auipc	a0,0x17
    80003c5c:	ff050513          	add	a0,a0,-16 # 8001ac48 <bcache>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	f72080e7          	jalr	-142(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003c68:	0001f497          	auipc	s1,0x1f
    80003c6c:	2984b483          	ld	s1,664(s1) # 80022f00 <bcache+0x82b8>
    80003c70:	0001f797          	auipc	a5,0x1f
    80003c74:	24078793          	add	a5,a5,576 # 80022eb0 <bcache+0x8268>
    80003c78:	02f48f63          	beq	s1,a5,80003cb6 <bread+0x70>
    80003c7c:	873e                	mv	a4,a5
    80003c7e:	a021                	j	80003c86 <bread+0x40>
    80003c80:	68a4                	ld	s1,80(s1)
    80003c82:	02e48a63          	beq	s1,a4,80003cb6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003c86:	449c                	lw	a5,8(s1)
    80003c88:	ff279ce3          	bne	a5,s2,80003c80 <bread+0x3a>
    80003c8c:	44dc                	lw	a5,12(s1)
    80003c8e:	ff3799e3          	bne	a5,s3,80003c80 <bread+0x3a>
      b->refcnt++;
    80003c92:	40bc                	lw	a5,64(s1)
    80003c94:	2785                	addw	a5,a5,1
    80003c96:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c98:	00017517          	auipc	a0,0x17
    80003c9c:	fb050513          	add	a0,a0,-80 # 8001ac48 <bcache>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	fe6080e7          	jalr	-26(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003ca8:	01048513          	add	a0,s1,16
    80003cac:	00001097          	auipc	ra,0x1
    80003cb0:	440080e7          	jalr	1088(ra) # 800050ec <acquiresleep>
      return b;
    80003cb4:	a8b9                	j	80003d12 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003cb6:	0001f497          	auipc	s1,0x1f
    80003cba:	2424b483          	ld	s1,578(s1) # 80022ef8 <bcache+0x82b0>
    80003cbe:	0001f797          	auipc	a5,0x1f
    80003cc2:	1f278793          	add	a5,a5,498 # 80022eb0 <bcache+0x8268>
    80003cc6:	00f48863          	beq	s1,a5,80003cd6 <bread+0x90>
    80003cca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003ccc:	40bc                	lw	a5,64(s1)
    80003cce:	cf81                	beqz	a5,80003ce6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003cd0:	64a4                	ld	s1,72(s1)
    80003cd2:	fee49de3          	bne	s1,a4,80003ccc <bread+0x86>
  panic("bget: no buffers");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	92a50513          	add	a0,a0,-1750 # 80008600 <syscalls+0x108>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	85e080e7          	jalr	-1954(ra) # 8000053c <panic>
      b->dev = dev;
    80003ce6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003cea:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003cee:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003cf2:	4785                	li	a5,1
    80003cf4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003cf6:	00017517          	auipc	a0,0x17
    80003cfa:	f5250513          	add	a0,a0,-174 # 8001ac48 <bcache>
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	f88080e7          	jalr	-120(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003d06:	01048513          	add	a0,s1,16
    80003d0a:	00001097          	auipc	ra,0x1
    80003d0e:	3e2080e7          	jalr	994(ra) # 800050ec <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003d12:	409c                	lw	a5,0(s1)
    80003d14:	cb89                	beqz	a5,80003d26 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003d16:	8526                	mv	a0,s1
    80003d18:	70a2                	ld	ra,40(sp)
    80003d1a:	7402                	ld	s0,32(sp)
    80003d1c:	64e2                	ld	s1,24(sp)
    80003d1e:	6942                	ld	s2,16(sp)
    80003d20:	69a2                	ld	s3,8(sp)
    80003d22:	6145                	add	sp,sp,48
    80003d24:	8082                	ret
    virtio_disk_rw(b, 0);
    80003d26:	4581                	li	a1,0
    80003d28:	8526                	mv	a0,s1
    80003d2a:	00003097          	auipc	ra,0x3
    80003d2e:	f78080e7          	jalr	-136(ra) # 80006ca2 <virtio_disk_rw>
    b->valid = 1;
    80003d32:	4785                	li	a5,1
    80003d34:	c09c                	sw	a5,0(s1)
  return b;
    80003d36:	b7c5                	j	80003d16 <bread+0xd0>

0000000080003d38 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003d38:	1101                	add	sp,sp,-32
    80003d3a:	ec06                	sd	ra,24(sp)
    80003d3c:	e822                	sd	s0,16(sp)
    80003d3e:	e426                	sd	s1,8(sp)
    80003d40:	1000                	add	s0,sp,32
    80003d42:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003d44:	0541                	add	a0,a0,16
    80003d46:	00001097          	auipc	ra,0x1
    80003d4a:	440080e7          	jalr	1088(ra) # 80005186 <holdingsleep>
    80003d4e:	cd01                	beqz	a0,80003d66 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003d50:	4585                	li	a1,1
    80003d52:	8526                	mv	a0,s1
    80003d54:	00003097          	auipc	ra,0x3
    80003d58:	f4e080e7          	jalr	-178(ra) # 80006ca2 <virtio_disk_rw>
}
    80003d5c:	60e2                	ld	ra,24(sp)
    80003d5e:	6442                	ld	s0,16(sp)
    80003d60:	64a2                	ld	s1,8(sp)
    80003d62:	6105                	add	sp,sp,32
    80003d64:	8082                	ret
    panic("bwrite");
    80003d66:	00005517          	auipc	a0,0x5
    80003d6a:	8b250513          	add	a0,a0,-1870 # 80008618 <syscalls+0x120>
    80003d6e:	ffffc097          	auipc	ra,0xffffc
    80003d72:	7ce080e7          	jalr	1998(ra) # 8000053c <panic>

0000000080003d76 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003d76:	1101                	add	sp,sp,-32
    80003d78:	ec06                	sd	ra,24(sp)
    80003d7a:	e822                	sd	s0,16(sp)
    80003d7c:	e426                	sd	s1,8(sp)
    80003d7e:	e04a                	sd	s2,0(sp)
    80003d80:	1000                	add	s0,sp,32
    80003d82:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003d84:	01050913          	add	s2,a0,16
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00001097          	auipc	ra,0x1
    80003d8e:	3fc080e7          	jalr	1020(ra) # 80005186 <holdingsleep>
    80003d92:	c925                	beqz	a0,80003e02 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003d94:	854a                	mv	a0,s2
    80003d96:	00001097          	auipc	ra,0x1
    80003d9a:	3ac080e7          	jalr	940(ra) # 80005142 <releasesleep>

  acquire(&bcache.lock);
    80003d9e:	00017517          	auipc	a0,0x17
    80003da2:	eaa50513          	add	a0,a0,-342 # 8001ac48 <bcache>
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	e2c080e7          	jalr	-468(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003dae:	40bc                	lw	a5,64(s1)
    80003db0:	37fd                	addw	a5,a5,-1
    80003db2:	0007871b          	sext.w	a4,a5
    80003db6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003db8:	e71d                	bnez	a4,80003de6 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003dba:	68b8                	ld	a4,80(s1)
    80003dbc:	64bc                	ld	a5,72(s1)
    80003dbe:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003dc0:	68b8                	ld	a4,80(s1)
    80003dc2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003dc4:	0001f797          	auipc	a5,0x1f
    80003dc8:	e8478793          	add	a5,a5,-380 # 80022c48 <bcache+0x8000>
    80003dcc:	2b87b703          	ld	a4,696(a5)
    80003dd0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003dd2:	0001f717          	auipc	a4,0x1f
    80003dd6:	0de70713          	add	a4,a4,222 # 80022eb0 <bcache+0x8268>
    80003dda:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003ddc:	2b87b703          	ld	a4,696(a5)
    80003de0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003de2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003de6:	00017517          	auipc	a0,0x17
    80003dea:	e6250513          	add	a0,a0,-414 # 8001ac48 <bcache>
    80003dee:	ffffd097          	auipc	ra,0xffffd
    80003df2:	e98080e7          	jalr	-360(ra) # 80000c86 <release>
}
    80003df6:	60e2                	ld	ra,24(sp)
    80003df8:	6442                	ld	s0,16(sp)
    80003dfa:	64a2                	ld	s1,8(sp)
    80003dfc:	6902                	ld	s2,0(sp)
    80003dfe:	6105                	add	sp,sp,32
    80003e00:	8082                	ret
    panic("brelse");
    80003e02:	00005517          	auipc	a0,0x5
    80003e06:	81e50513          	add	a0,a0,-2018 # 80008620 <syscalls+0x128>
    80003e0a:	ffffc097          	auipc	ra,0xffffc
    80003e0e:	732080e7          	jalr	1842(ra) # 8000053c <panic>

0000000080003e12 <bpin>:

void
bpin(struct buf *b) {
    80003e12:	1101                	add	sp,sp,-32
    80003e14:	ec06                	sd	ra,24(sp)
    80003e16:	e822                	sd	s0,16(sp)
    80003e18:	e426                	sd	s1,8(sp)
    80003e1a:	1000                	add	s0,sp,32
    80003e1c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003e1e:	00017517          	auipc	a0,0x17
    80003e22:	e2a50513          	add	a0,a0,-470 # 8001ac48 <bcache>
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	dac080e7          	jalr	-596(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003e2e:	40bc                	lw	a5,64(s1)
    80003e30:	2785                	addw	a5,a5,1
    80003e32:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003e34:	00017517          	auipc	a0,0x17
    80003e38:	e1450513          	add	a0,a0,-492 # 8001ac48 <bcache>
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	e4a080e7          	jalr	-438(ra) # 80000c86 <release>
}
    80003e44:	60e2                	ld	ra,24(sp)
    80003e46:	6442                	ld	s0,16(sp)
    80003e48:	64a2                	ld	s1,8(sp)
    80003e4a:	6105                	add	sp,sp,32
    80003e4c:	8082                	ret

0000000080003e4e <bunpin>:

void
bunpin(struct buf *b) {
    80003e4e:	1101                	add	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	1000                	add	s0,sp,32
    80003e58:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003e5a:	00017517          	auipc	a0,0x17
    80003e5e:	dee50513          	add	a0,a0,-530 # 8001ac48 <bcache>
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	d70080e7          	jalr	-656(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003e6a:	40bc                	lw	a5,64(s1)
    80003e6c:	37fd                	addw	a5,a5,-1
    80003e6e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003e70:	00017517          	auipc	a0,0x17
    80003e74:	dd850513          	add	a0,a0,-552 # 8001ac48 <bcache>
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	e0e080e7          	jalr	-498(ra) # 80000c86 <release>
}
    80003e80:	60e2                	ld	ra,24(sp)
    80003e82:	6442                	ld	s0,16(sp)
    80003e84:	64a2                	ld	s1,8(sp)
    80003e86:	6105                	add	sp,sp,32
    80003e88:	8082                	ret

0000000080003e8a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003e8a:	1101                	add	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	e426                	sd	s1,8(sp)
    80003e92:	e04a                	sd	s2,0(sp)
    80003e94:	1000                	add	s0,sp,32
    80003e96:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003e98:	00d5d59b          	srlw	a1,a1,0xd
    80003e9c:	0001f797          	auipc	a5,0x1f
    80003ea0:	4887a783          	lw	a5,1160(a5) # 80023324 <sb+0x1c>
    80003ea4:	9dbd                	addw	a1,a1,a5
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	da0080e7          	jalr	-608(ra) # 80003c46 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003eae:	0074f713          	and	a4,s1,7
    80003eb2:	4785                	li	a5,1
    80003eb4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003eb8:	14ce                	sll	s1,s1,0x33
    80003eba:	90d9                	srl	s1,s1,0x36
    80003ebc:	00950733          	add	a4,a0,s1
    80003ec0:	05874703          	lbu	a4,88(a4)
    80003ec4:	00e7f6b3          	and	a3,a5,a4
    80003ec8:	c69d                	beqz	a3,80003ef6 <bfree+0x6c>
    80003eca:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003ecc:	94aa                	add	s1,s1,a0
    80003ece:	fff7c793          	not	a5,a5
    80003ed2:	8f7d                	and	a4,a4,a5
    80003ed4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003ed8:	00001097          	auipc	ra,0x1
    80003edc:	0f6080e7          	jalr	246(ra) # 80004fce <log_write>
  brelse(bp);
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	e94080e7          	jalr	-364(ra) # 80003d76 <brelse>
}
    80003eea:	60e2                	ld	ra,24(sp)
    80003eec:	6442                	ld	s0,16(sp)
    80003eee:	64a2                	ld	s1,8(sp)
    80003ef0:	6902                	ld	s2,0(sp)
    80003ef2:	6105                	add	sp,sp,32
    80003ef4:	8082                	ret
    panic("freeing free block");
    80003ef6:	00004517          	auipc	a0,0x4
    80003efa:	73250513          	add	a0,a0,1842 # 80008628 <syscalls+0x130>
    80003efe:	ffffc097          	auipc	ra,0xffffc
    80003f02:	63e080e7          	jalr	1598(ra) # 8000053c <panic>

0000000080003f06 <balloc>:
{
    80003f06:	711d                	add	sp,sp,-96
    80003f08:	ec86                	sd	ra,88(sp)
    80003f0a:	e8a2                	sd	s0,80(sp)
    80003f0c:	e4a6                	sd	s1,72(sp)
    80003f0e:	e0ca                	sd	s2,64(sp)
    80003f10:	fc4e                	sd	s3,56(sp)
    80003f12:	f852                	sd	s4,48(sp)
    80003f14:	f456                	sd	s5,40(sp)
    80003f16:	f05a                	sd	s6,32(sp)
    80003f18:	ec5e                	sd	s7,24(sp)
    80003f1a:	e862                	sd	s8,16(sp)
    80003f1c:	e466                	sd	s9,8(sp)
    80003f1e:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003f20:	0001f797          	auipc	a5,0x1f
    80003f24:	3ec7a783          	lw	a5,1004(a5) # 8002330c <sb+0x4>
    80003f28:	cff5                	beqz	a5,80004024 <balloc+0x11e>
    80003f2a:	8baa                	mv	s7,a0
    80003f2c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003f2e:	0001fb17          	auipc	s6,0x1f
    80003f32:	3dab0b13          	add	s6,s6,986 # 80023308 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f36:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003f38:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f3a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003f3c:	6c89                	lui	s9,0x2
    80003f3e:	a061                	j	80003fc6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003f40:	97ca                	add	a5,a5,s2
    80003f42:	8e55                	or	a2,a2,a3
    80003f44:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003f48:	854a                	mv	a0,s2
    80003f4a:	00001097          	auipc	ra,0x1
    80003f4e:	084080e7          	jalr	132(ra) # 80004fce <log_write>
        brelse(bp);
    80003f52:	854a                	mv	a0,s2
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	e22080e7          	jalr	-478(ra) # 80003d76 <brelse>
  bp = bread(dev, bno);
    80003f5c:	85a6                	mv	a1,s1
    80003f5e:	855e                	mv	a0,s7
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	ce6080e7          	jalr	-794(ra) # 80003c46 <bread>
    80003f68:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003f6a:	40000613          	li	a2,1024
    80003f6e:	4581                	li	a1,0
    80003f70:	05850513          	add	a0,a0,88
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	d5a080e7          	jalr	-678(ra) # 80000cce <memset>
  log_write(bp);
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00001097          	auipc	ra,0x1
    80003f82:	050080e7          	jalr	80(ra) # 80004fce <log_write>
  brelse(bp);
    80003f86:	854a                	mv	a0,s2
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	dee080e7          	jalr	-530(ra) # 80003d76 <brelse>
}
    80003f90:	8526                	mv	a0,s1
    80003f92:	60e6                	ld	ra,88(sp)
    80003f94:	6446                	ld	s0,80(sp)
    80003f96:	64a6                	ld	s1,72(sp)
    80003f98:	6906                	ld	s2,64(sp)
    80003f9a:	79e2                	ld	s3,56(sp)
    80003f9c:	7a42                	ld	s4,48(sp)
    80003f9e:	7aa2                	ld	s5,40(sp)
    80003fa0:	7b02                	ld	s6,32(sp)
    80003fa2:	6be2                	ld	s7,24(sp)
    80003fa4:	6c42                	ld	s8,16(sp)
    80003fa6:	6ca2                	ld	s9,8(sp)
    80003fa8:	6125                	add	sp,sp,96
    80003faa:	8082                	ret
    brelse(bp);
    80003fac:	854a                	mv	a0,s2
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	dc8080e7          	jalr	-568(ra) # 80003d76 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003fb6:	015c87bb          	addw	a5,s9,s5
    80003fba:	00078a9b          	sext.w	s5,a5
    80003fbe:	004b2703          	lw	a4,4(s6)
    80003fc2:	06eaf163          	bgeu	s5,a4,80004024 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003fc6:	41fad79b          	sraw	a5,s5,0x1f
    80003fca:	0137d79b          	srlw	a5,a5,0x13
    80003fce:	015787bb          	addw	a5,a5,s5
    80003fd2:	40d7d79b          	sraw	a5,a5,0xd
    80003fd6:	01cb2583          	lw	a1,28(s6)
    80003fda:	9dbd                	addw	a1,a1,a5
    80003fdc:	855e                	mv	a0,s7
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	c68080e7          	jalr	-920(ra) # 80003c46 <bread>
    80003fe6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fe8:	004b2503          	lw	a0,4(s6)
    80003fec:	000a849b          	sext.w	s1,s5
    80003ff0:	8762                	mv	a4,s8
    80003ff2:	faa4fde3          	bgeu	s1,a0,80003fac <balloc+0xa6>
      m = 1 << (bi % 8);
    80003ff6:	00777693          	and	a3,a4,7
    80003ffa:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ffe:	41f7579b          	sraw	a5,a4,0x1f
    80004002:	01d7d79b          	srlw	a5,a5,0x1d
    80004006:	9fb9                	addw	a5,a5,a4
    80004008:	4037d79b          	sraw	a5,a5,0x3
    8000400c:	00f90633          	add	a2,s2,a5
    80004010:	05864603          	lbu	a2,88(a2)
    80004014:	00c6f5b3          	and	a1,a3,a2
    80004018:	d585                	beqz	a1,80003f40 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000401a:	2705                	addw	a4,a4,1
    8000401c:	2485                	addw	s1,s1,1
    8000401e:	fd471ae3          	bne	a4,s4,80003ff2 <balloc+0xec>
    80004022:	b769                	j	80003fac <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80004024:	00004517          	auipc	a0,0x4
    80004028:	61c50513          	add	a0,a0,1564 # 80008640 <syscalls+0x148>
    8000402c:	ffffc097          	auipc	ra,0xffffc
    80004030:	55a080e7          	jalr	1370(ra) # 80000586 <printf>
  return 0;
    80004034:	4481                	li	s1,0
    80004036:	bfa9                	j	80003f90 <balloc+0x8a>

0000000080004038 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80004038:	7179                	add	sp,sp,-48
    8000403a:	f406                	sd	ra,40(sp)
    8000403c:	f022                	sd	s0,32(sp)
    8000403e:	ec26                	sd	s1,24(sp)
    80004040:	e84a                	sd	s2,16(sp)
    80004042:	e44e                	sd	s3,8(sp)
    80004044:	e052                	sd	s4,0(sp)
    80004046:	1800                	add	s0,sp,48
    80004048:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000404a:	47ad                	li	a5,11
    8000404c:	02b7e863          	bltu	a5,a1,8000407c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80004050:	02059793          	sll	a5,a1,0x20
    80004054:	01e7d593          	srl	a1,a5,0x1e
    80004058:	00b504b3          	add	s1,a0,a1
    8000405c:	0504a903          	lw	s2,80(s1)
    80004060:	06091e63          	bnez	s2,800040dc <bmap+0xa4>
      addr = balloc(ip->dev);
    80004064:	4108                	lw	a0,0(a0)
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	ea0080e7          	jalr	-352(ra) # 80003f06 <balloc>
    8000406e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80004072:	06090563          	beqz	s2,800040dc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80004076:	0524a823          	sw	s2,80(s1)
    8000407a:	a08d                	j	800040dc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000407c:	ff45849b          	addw	s1,a1,-12
    80004080:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80004084:	0ff00793          	li	a5,255
    80004088:	08e7e563          	bltu	a5,a4,80004112 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000408c:	08052903          	lw	s2,128(a0)
    80004090:	00091d63          	bnez	s2,800040aa <bmap+0x72>
      addr = balloc(ip->dev);
    80004094:	4108                	lw	a0,0(a0)
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	e70080e7          	jalr	-400(ra) # 80003f06 <balloc>
    8000409e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800040a2:	02090d63          	beqz	s2,800040dc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800040a6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800040aa:	85ca                	mv	a1,s2
    800040ac:	0009a503          	lw	a0,0(s3)
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	b96080e7          	jalr	-1130(ra) # 80003c46 <bread>
    800040b8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800040ba:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800040be:	02049713          	sll	a4,s1,0x20
    800040c2:	01e75593          	srl	a1,a4,0x1e
    800040c6:	00b784b3          	add	s1,a5,a1
    800040ca:	0004a903          	lw	s2,0(s1)
    800040ce:	02090063          	beqz	s2,800040ee <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800040d2:	8552                	mv	a0,s4
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	ca2080e7          	jalr	-862(ra) # 80003d76 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800040dc:	854a                	mv	a0,s2
    800040de:	70a2                	ld	ra,40(sp)
    800040e0:	7402                	ld	s0,32(sp)
    800040e2:	64e2                	ld	s1,24(sp)
    800040e4:	6942                	ld	s2,16(sp)
    800040e6:	69a2                	ld	s3,8(sp)
    800040e8:	6a02                	ld	s4,0(sp)
    800040ea:	6145                	add	sp,sp,48
    800040ec:	8082                	ret
      addr = balloc(ip->dev);
    800040ee:	0009a503          	lw	a0,0(s3)
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	e14080e7          	jalr	-492(ra) # 80003f06 <balloc>
    800040fa:	0005091b          	sext.w	s2,a0
      if(addr){
    800040fe:	fc090ae3          	beqz	s2,800040d2 <bmap+0x9a>
        a[bn] = addr;
    80004102:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004106:	8552                	mv	a0,s4
    80004108:	00001097          	auipc	ra,0x1
    8000410c:	ec6080e7          	jalr	-314(ra) # 80004fce <log_write>
    80004110:	b7c9                	j	800040d2 <bmap+0x9a>
  panic("bmap: out of range");
    80004112:	00004517          	auipc	a0,0x4
    80004116:	54650513          	add	a0,a0,1350 # 80008658 <syscalls+0x160>
    8000411a:	ffffc097          	auipc	ra,0xffffc
    8000411e:	422080e7          	jalr	1058(ra) # 8000053c <panic>

0000000080004122 <iget>:
{
    80004122:	7179                	add	sp,sp,-48
    80004124:	f406                	sd	ra,40(sp)
    80004126:	f022                	sd	s0,32(sp)
    80004128:	ec26                	sd	s1,24(sp)
    8000412a:	e84a                	sd	s2,16(sp)
    8000412c:	e44e                	sd	s3,8(sp)
    8000412e:	e052                	sd	s4,0(sp)
    80004130:	1800                	add	s0,sp,48
    80004132:	89aa                	mv	s3,a0
    80004134:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004136:	0001f517          	auipc	a0,0x1f
    8000413a:	1f250513          	add	a0,a0,498 # 80023328 <itable>
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	a94080e7          	jalr	-1388(ra) # 80000bd2 <acquire>
  empty = 0;
    80004146:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004148:	0001f497          	auipc	s1,0x1f
    8000414c:	1f848493          	add	s1,s1,504 # 80023340 <itable+0x18>
    80004150:	00021697          	auipc	a3,0x21
    80004154:	c8068693          	add	a3,a3,-896 # 80024dd0 <log>
    80004158:	a039                	j	80004166 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000415a:	02090b63          	beqz	s2,80004190 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000415e:	08848493          	add	s1,s1,136
    80004162:	02d48a63          	beq	s1,a3,80004196 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004166:	449c                	lw	a5,8(s1)
    80004168:	fef059e3          	blez	a5,8000415a <iget+0x38>
    8000416c:	4098                	lw	a4,0(s1)
    8000416e:	ff3716e3          	bne	a4,s3,8000415a <iget+0x38>
    80004172:	40d8                	lw	a4,4(s1)
    80004174:	ff4713e3          	bne	a4,s4,8000415a <iget+0x38>
      ip->ref++;
    80004178:	2785                	addw	a5,a5,1
    8000417a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000417c:	0001f517          	auipc	a0,0x1f
    80004180:	1ac50513          	add	a0,a0,428 # 80023328 <itable>
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	b02080e7          	jalr	-1278(ra) # 80000c86 <release>
      return ip;
    8000418c:	8926                	mv	s2,s1
    8000418e:	a03d                	j	800041bc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004190:	f7f9                	bnez	a5,8000415e <iget+0x3c>
    80004192:	8926                	mv	s2,s1
    80004194:	b7e9                	j	8000415e <iget+0x3c>
  if(empty == 0)
    80004196:	02090c63          	beqz	s2,800041ce <iget+0xac>
  ip->dev = dev;
    8000419a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000419e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800041a2:	4785                	li	a5,1
    800041a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800041a8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800041ac:	0001f517          	auipc	a0,0x1f
    800041b0:	17c50513          	add	a0,a0,380 # 80023328 <itable>
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	ad2080e7          	jalr	-1326(ra) # 80000c86 <release>
}
    800041bc:	854a                	mv	a0,s2
    800041be:	70a2                	ld	ra,40(sp)
    800041c0:	7402                	ld	s0,32(sp)
    800041c2:	64e2                	ld	s1,24(sp)
    800041c4:	6942                	ld	s2,16(sp)
    800041c6:	69a2                	ld	s3,8(sp)
    800041c8:	6a02                	ld	s4,0(sp)
    800041ca:	6145                	add	sp,sp,48
    800041cc:	8082                	ret
    panic("iget: no inodes");
    800041ce:	00004517          	auipc	a0,0x4
    800041d2:	4a250513          	add	a0,a0,1186 # 80008670 <syscalls+0x178>
    800041d6:	ffffc097          	auipc	ra,0xffffc
    800041da:	366080e7          	jalr	870(ra) # 8000053c <panic>

00000000800041de <fsinit>:
fsinit(int dev) {
    800041de:	7179                	add	sp,sp,-48
    800041e0:	f406                	sd	ra,40(sp)
    800041e2:	f022                	sd	s0,32(sp)
    800041e4:	ec26                	sd	s1,24(sp)
    800041e6:	e84a                	sd	s2,16(sp)
    800041e8:	e44e                	sd	s3,8(sp)
    800041ea:	1800                	add	s0,sp,48
    800041ec:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800041ee:	4585                	li	a1,1
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	a56080e7          	jalr	-1450(ra) # 80003c46 <bread>
    800041f8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800041fa:	0001f997          	auipc	s3,0x1f
    800041fe:	10e98993          	add	s3,s3,270 # 80023308 <sb>
    80004202:	02000613          	li	a2,32
    80004206:	05850593          	add	a1,a0,88
    8000420a:	854e                	mv	a0,s3
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	b1e080e7          	jalr	-1250(ra) # 80000d2a <memmove>
  brelse(bp);
    80004214:	8526                	mv	a0,s1
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	b60080e7          	jalr	-1184(ra) # 80003d76 <brelse>
  if(sb.magic != FSMAGIC)
    8000421e:	0009a703          	lw	a4,0(s3)
    80004222:	102037b7          	lui	a5,0x10203
    80004226:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000422a:	02f71263          	bne	a4,a5,8000424e <fsinit+0x70>
  initlog(dev, &sb);
    8000422e:	0001f597          	auipc	a1,0x1f
    80004232:	0da58593          	add	a1,a1,218 # 80023308 <sb>
    80004236:	854a                	mv	a0,s2
    80004238:	00001097          	auipc	ra,0x1
    8000423c:	b2c080e7          	jalr	-1236(ra) # 80004d64 <initlog>
}
    80004240:	70a2                	ld	ra,40(sp)
    80004242:	7402                	ld	s0,32(sp)
    80004244:	64e2                	ld	s1,24(sp)
    80004246:	6942                	ld	s2,16(sp)
    80004248:	69a2                	ld	s3,8(sp)
    8000424a:	6145                	add	sp,sp,48
    8000424c:	8082                	ret
    panic("invalid file system");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	43250513          	add	a0,a0,1074 # 80008680 <syscalls+0x188>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	2e6080e7          	jalr	742(ra) # 8000053c <panic>

000000008000425e <iinit>:
{
    8000425e:	7179                	add	sp,sp,-48
    80004260:	f406                	sd	ra,40(sp)
    80004262:	f022                	sd	s0,32(sp)
    80004264:	ec26                	sd	s1,24(sp)
    80004266:	e84a                	sd	s2,16(sp)
    80004268:	e44e                	sd	s3,8(sp)
    8000426a:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    8000426c:	00004597          	auipc	a1,0x4
    80004270:	42c58593          	add	a1,a1,1068 # 80008698 <syscalls+0x1a0>
    80004274:	0001f517          	auipc	a0,0x1f
    80004278:	0b450513          	add	a0,a0,180 # 80023328 <itable>
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	8c6080e7          	jalr	-1850(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004284:	0001f497          	auipc	s1,0x1f
    80004288:	0cc48493          	add	s1,s1,204 # 80023350 <itable+0x28>
    8000428c:	00021997          	auipc	s3,0x21
    80004290:	b5498993          	add	s3,s3,-1196 # 80024de0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004294:	00004917          	auipc	s2,0x4
    80004298:	40c90913          	add	s2,s2,1036 # 800086a0 <syscalls+0x1a8>
    8000429c:	85ca                	mv	a1,s2
    8000429e:	8526                	mv	a0,s1
    800042a0:	00001097          	auipc	ra,0x1
    800042a4:	e12080e7          	jalr	-494(ra) # 800050b2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800042a8:	08848493          	add	s1,s1,136
    800042ac:	ff3498e3          	bne	s1,s3,8000429c <iinit+0x3e>
}
    800042b0:	70a2                	ld	ra,40(sp)
    800042b2:	7402                	ld	s0,32(sp)
    800042b4:	64e2                	ld	s1,24(sp)
    800042b6:	6942                	ld	s2,16(sp)
    800042b8:	69a2                	ld	s3,8(sp)
    800042ba:	6145                	add	sp,sp,48
    800042bc:	8082                	ret

00000000800042be <ialloc>:
{
    800042be:	7139                	add	sp,sp,-64
    800042c0:	fc06                	sd	ra,56(sp)
    800042c2:	f822                	sd	s0,48(sp)
    800042c4:	f426                	sd	s1,40(sp)
    800042c6:	f04a                	sd	s2,32(sp)
    800042c8:	ec4e                	sd	s3,24(sp)
    800042ca:	e852                	sd	s4,16(sp)
    800042cc:	e456                	sd	s5,8(sp)
    800042ce:	e05a                	sd	s6,0(sp)
    800042d0:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800042d2:	0001f717          	auipc	a4,0x1f
    800042d6:	04272703          	lw	a4,66(a4) # 80023314 <sb+0xc>
    800042da:	4785                	li	a5,1
    800042dc:	04e7f863          	bgeu	a5,a4,8000432c <ialloc+0x6e>
    800042e0:	8aaa                	mv	s5,a0
    800042e2:	8b2e                	mv	s6,a1
    800042e4:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800042e6:	0001fa17          	auipc	s4,0x1f
    800042ea:	022a0a13          	add	s4,s4,34 # 80023308 <sb>
    800042ee:	00495593          	srl	a1,s2,0x4
    800042f2:	018a2783          	lw	a5,24(s4)
    800042f6:	9dbd                	addw	a1,a1,a5
    800042f8:	8556                	mv	a0,s5
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	94c080e7          	jalr	-1716(ra) # 80003c46 <bread>
    80004302:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004304:	05850993          	add	s3,a0,88
    80004308:	00f97793          	and	a5,s2,15
    8000430c:	079a                	sll	a5,a5,0x6
    8000430e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004310:	00099783          	lh	a5,0(s3)
    80004314:	cf9d                	beqz	a5,80004352 <ialloc+0x94>
    brelse(bp);
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	a60080e7          	jalr	-1440(ra) # 80003d76 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000431e:	0905                	add	s2,s2,1
    80004320:	00ca2703          	lw	a4,12(s4)
    80004324:	0009079b          	sext.w	a5,s2
    80004328:	fce7e3e3          	bltu	a5,a4,800042ee <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000432c:	00004517          	auipc	a0,0x4
    80004330:	37c50513          	add	a0,a0,892 # 800086a8 <syscalls+0x1b0>
    80004334:	ffffc097          	auipc	ra,0xffffc
    80004338:	252080e7          	jalr	594(ra) # 80000586 <printf>
  return 0;
    8000433c:	4501                	li	a0,0
}
    8000433e:	70e2                	ld	ra,56(sp)
    80004340:	7442                	ld	s0,48(sp)
    80004342:	74a2                	ld	s1,40(sp)
    80004344:	7902                	ld	s2,32(sp)
    80004346:	69e2                	ld	s3,24(sp)
    80004348:	6a42                	ld	s4,16(sp)
    8000434a:	6aa2                	ld	s5,8(sp)
    8000434c:	6b02                	ld	s6,0(sp)
    8000434e:	6121                	add	sp,sp,64
    80004350:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004352:	04000613          	li	a2,64
    80004356:	4581                	li	a1,0
    80004358:	854e                	mv	a0,s3
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	974080e7          	jalr	-1676(ra) # 80000cce <memset>
      dip->type = type;
    80004362:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004366:	8526                	mv	a0,s1
    80004368:	00001097          	auipc	ra,0x1
    8000436c:	c66080e7          	jalr	-922(ra) # 80004fce <log_write>
      brelse(bp);
    80004370:	8526                	mv	a0,s1
    80004372:	00000097          	auipc	ra,0x0
    80004376:	a04080e7          	jalr	-1532(ra) # 80003d76 <brelse>
      return iget(dev, inum);
    8000437a:	0009059b          	sext.w	a1,s2
    8000437e:	8556                	mv	a0,s5
    80004380:	00000097          	auipc	ra,0x0
    80004384:	da2080e7          	jalr	-606(ra) # 80004122 <iget>
    80004388:	bf5d                	j	8000433e <ialloc+0x80>

000000008000438a <iupdate>:
{
    8000438a:	1101                	add	sp,sp,-32
    8000438c:	ec06                	sd	ra,24(sp)
    8000438e:	e822                	sd	s0,16(sp)
    80004390:	e426                	sd	s1,8(sp)
    80004392:	e04a                	sd	s2,0(sp)
    80004394:	1000                	add	s0,sp,32
    80004396:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004398:	415c                	lw	a5,4(a0)
    8000439a:	0047d79b          	srlw	a5,a5,0x4
    8000439e:	0001f597          	auipc	a1,0x1f
    800043a2:	f825a583          	lw	a1,-126(a1) # 80023320 <sb+0x18>
    800043a6:	9dbd                	addw	a1,a1,a5
    800043a8:	4108                	lw	a0,0(a0)
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	89c080e7          	jalr	-1892(ra) # 80003c46 <bread>
    800043b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800043b4:	05850793          	add	a5,a0,88
    800043b8:	40d8                	lw	a4,4(s1)
    800043ba:	8b3d                	and	a4,a4,15
    800043bc:	071a                	sll	a4,a4,0x6
    800043be:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800043c0:	04449703          	lh	a4,68(s1)
    800043c4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800043c8:	04649703          	lh	a4,70(s1)
    800043cc:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800043d0:	04849703          	lh	a4,72(s1)
    800043d4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800043d8:	04a49703          	lh	a4,74(s1)
    800043dc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800043e0:	44f8                	lw	a4,76(s1)
    800043e2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800043e4:	03400613          	li	a2,52
    800043e8:	05048593          	add	a1,s1,80
    800043ec:	00c78513          	add	a0,a5,12
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	93a080e7          	jalr	-1734(ra) # 80000d2a <memmove>
  log_write(bp);
    800043f8:	854a                	mv	a0,s2
    800043fa:	00001097          	auipc	ra,0x1
    800043fe:	bd4080e7          	jalr	-1068(ra) # 80004fce <log_write>
  brelse(bp);
    80004402:	854a                	mv	a0,s2
    80004404:	00000097          	auipc	ra,0x0
    80004408:	972080e7          	jalr	-1678(ra) # 80003d76 <brelse>
}
    8000440c:	60e2                	ld	ra,24(sp)
    8000440e:	6442                	ld	s0,16(sp)
    80004410:	64a2                	ld	s1,8(sp)
    80004412:	6902                	ld	s2,0(sp)
    80004414:	6105                	add	sp,sp,32
    80004416:	8082                	ret

0000000080004418 <idup>:
{
    80004418:	1101                	add	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	1000                	add	s0,sp,32
    80004422:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004424:	0001f517          	auipc	a0,0x1f
    80004428:	f0450513          	add	a0,a0,-252 # 80023328 <itable>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	7a6080e7          	jalr	1958(ra) # 80000bd2 <acquire>
  ip->ref++;
    80004434:	449c                	lw	a5,8(s1)
    80004436:	2785                	addw	a5,a5,1
    80004438:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000443a:	0001f517          	auipc	a0,0x1f
    8000443e:	eee50513          	add	a0,a0,-274 # 80023328 <itable>
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	844080e7          	jalr	-1980(ra) # 80000c86 <release>
}
    8000444a:	8526                	mv	a0,s1
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6105                	add	sp,sp,32
    80004454:	8082                	ret

0000000080004456 <ilock>:
{
    80004456:	1101                	add	sp,sp,-32
    80004458:	ec06                	sd	ra,24(sp)
    8000445a:	e822                	sd	s0,16(sp)
    8000445c:	e426                	sd	s1,8(sp)
    8000445e:	e04a                	sd	s2,0(sp)
    80004460:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004462:	c115                	beqz	a0,80004486 <ilock+0x30>
    80004464:	84aa                	mv	s1,a0
    80004466:	451c                	lw	a5,8(a0)
    80004468:	00f05f63          	blez	a5,80004486 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000446c:	0541                	add	a0,a0,16
    8000446e:	00001097          	auipc	ra,0x1
    80004472:	c7e080e7          	jalr	-898(ra) # 800050ec <acquiresleep>
  if(ip->valid == 0){
    80004476:	40bc                	lw	a5,64(s1)
    80004478:	cf99                	beqz	a5,80004496 <ilock+0x40>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	add	sp,sp,32
    80004484:	8082                	ret
    panic("ilock");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	23a50513          	add	a0,a0,570 # 800086c0 <syscalls+0x1c8>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0ae080e7          	jalr	174(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004496:	40dc                	lw	a5,4(s1)
    80004498:	0047d79b          	srlw	a5,a5,0x4
    8000449c:	0001f597          	auipc	a1,0x1f
    800044a0:	e845a583          	lw	a1,-380(a1) # 80023320 <sb+0x18>
    800044a4:	9dbd                	addw	a1,a1,a5
    800044a6:	4088                	lw	a0,0(s1)
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	79e080e7          	jalr	1950(ra) # 80003c46 <bread>
    800044b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800044b2:	05850593          	add	a1,a0,88
    800044b6:	40dc                	lw	a5,4(s1)
    800044b8:	8bbd                	and	a5,a5,15
    800044ba:	079a                	sll	a5,a5,0x6
    800044bc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800044be:	00059783          	lh	a5,0(a1)
    800044c2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800044c6:	00259783          	lh	a5,2(a1)
    800044ca:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800044ce:	00459783          	lh	a5,4(a1)
    800044d2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800044d6:	00659783          	lh	a5,6(a1)
    800044da:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800044de:	459c                	lw	a5,8(a1)
    800044e0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800044e2:	03400613          	li	a2,52
    800044e6:	05b1                	add	a1,a1,12
    800044e8:	05048513          	add	a0,s1,80
    800044ec:	ffffd097          	auipc	ra,0xffffd
    800044f0:	83e080e7          	jalr	-1986(ra) # 80000d2a <memmove>
    brelse(bp);
    800044f4:	854a                	mv	a0,s2
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	880080e7          	jalr	-1920(ra) # 80003d76 <brelse>
    ip->valid = 1;
    800044fe:	4785                	li	a5,1
    80004500:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004502:	04449783          	lh	a5,68(s1)
    80004506:	fbb5                	bnez	a5,8000447a <ilock+0x24>
      panic("ilock: no type");
    80004508:	00004517          	auipc	a0,0x4
    8000450c:	1c050513          	add	a0,a0,448 # 800086c8 <syscalls+0x1d0>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	02c080e7          	jalr	44(ra) # 8000053c <panic>

0000000080004518 <iunlock>:
{
    80004518:	1101                	add	sp,sp,-32
    8000451a:	ec06                	sd	ra,24(sp)
    8000451c:	e822                	sd	s0,16(sp)
    8000451e:	e426                	sd	s1,8(sp)
    80004520:	e04a                	sd	s2,0(sp)
    80004522:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004524:	c905                	beqz	a0,80004554 <iunlock+0x3c>
    80004526:	84aa                	mv	s1,a0
    80004528:	01050913          	add	s2,a0,16
    8000452c:	854a                	mv	a0,s2
    8000452e:	00001097          	auipc	ra,0x1
    80004532:	c58080e7          	jalr	-936(ra) # 80005186 <holdingsleep>
    80004536:	cd19                	beqz	a0,80004554 <iunlock+0x3c>
    80004538:	449c                	lw	a5,8(s1)
    8000453a:	00f05d63          	blez	a5,80004554 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000453e:	854a                	mv	a0,s2
    80004540:	00001097          	auipc	ra,0x1
    80004544:	c02080e7          	jalr	-1022(ra) # 80005142 <releasesleep>
}
    80004548:	60e2                	ld	ra,24(sp)
    8000454a:	6442                	ld	s0,16(sp)
    8000454c:	64a2                	ld	s1,8(sp)
    8000454e:	6902                	ld	s2,0(sp)
    80004550:	6105                	add	sp,sp,32
    80004552:	8082                	ret
    panic("iunlock");
    80004554:	00004517          	auipc	a0,0x4
    80004558:	18450513          	add	a0,a0,388 # 800086d8 <syscalls+0x1e0>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	fe0080e7          	jalr	-32(ra) # 8000053c <panic>

0000000080004564 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004564:	7179                	add	sp,sp,-48
    80004566:	f406                	sd	ra,40(sp)
    80004568:	f022                	sd	s0,32(sp)
    8000456a:	ec26                	sd	s1,24(sp)
    8000456c:	e84a                	sd	s2,16(sp)
    8000456e:	e44e                	sd	s3,8(sp)
    80004570:	e052                	sd	s4,0(sp)
    80004572:	1800                	add	s0,sp,48
    80004574:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004576:	05050493          	add	s1,a0,80
    8000457a:	08050913          	add	s2,a0,128
    8000457e:	a021                	j	80004586 <itrunc+0x22>
    80004580:	0491                	add	s1,s1,4
    80004582:	01248d63          	beq	s1,s2,8000459c <itrunc+0x38>
    if(ip->addrs[i]){
    80004586:	408c                	lw	a1,0(s1)
    80004588:	dde5                	beqz	a1,80004580 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000458a:	0009a503          	lw	a0,0(s3)
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	8fc080e7          	jalr	-1796(ra) # 80003e8a <bfree>
      ip->addrs[i] = 0;
    80004596:	0004a023          	sw	zero,0(s1)
    8000459a:	b7dd                	j	80004580 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000459c:	0809a583          	lw	a1,128(s3)
    800045a0:	e185                	bnez	a1,800045c0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800045a2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800045a6:	854e                	mv	a0,s3
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	de2080e7          	jalr	-542(ra) # 8000438a <iupdate>
}
    800045b0:	70a2                	ld	ra,40(sp)
    800045b2:	7402                	ld	s0,32(sp)
    800045b4:	64e2                	ld	s1,24(sp)
    800045b6:	6942                	ld	s2,16(sp)
    800045b8:	69a2                	ld	s3,8(sp)
    800045ba:	6a02                	ld	s4,0(sp)
    800045bc:	6145                	add	sp,sp,48
    800045be:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800045c0:	0009a503          	lw	a0,0(s3)
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	682080e7          	jalr	1666(ra) # 80003c46 <bread>
    800045cc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800045ce:	05850493          	add	s1,a0,88
    800045d2:	45850913          	add	s2,a0,1112
    800045d6:	a021                	j	800045de <itrunc+0x7a>
    800045d8:	0491                	add	s1,s1,4
    800045da:	01248b63          	beq	s1,s2,800045f0 <itrunc+0x8c>
      if(a[j])
    800045de:	408c                	lw	a1,0(s1)
    800045e0:	dde5                	beqz	a1,800045d8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800045e2:	0009a503          	lw	a0,0(s3)
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	8a4080e7          	jalr	-1884(ra) # 80003e8a <bfree>
    800045ee:	b7ed                	j	800045d8 <itrunc+0x74>
    brelse(bp);
    800045f0:	8552                	mv	a0,s4
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	784080e7          	jalr	1924(ra) # 80003d76 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800045fa:	0809a583          	lw	a1,128(s3)
    800045fe:	0009a503          	lw	a0,0(s3)
    80004602:	00000097          	auipc	ra,0x0
    80004606:	888080e7          	jalr	-1912(ra) # 80003e8a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000460a:	0809a023          	sw	zero,128(s3)
    8000460e:	bf51                	j	800045a2 <itrunc+0x3e>

0000000080004610 <iput>:
{
    80004610:	1101                	add	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	add	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000461e:	0001f517          	auipc	a0,0x1f
    80004622:	d0a50513          	add	a0,a0,-758 # 80023328 <itable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	5ac080e7          	jalr	1452(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000462e:	4498                	lw	a4,8(s1)
    80004630:	4785                	li	a5,1
    80004632:	02f70363          	beq	a4,a5,80004658 <iput+0x48>
  ip->ref--;
    80004636:	449c                	lw	a5,8(s1)
    80004638:	37fd                	addw	a5,a5,-1
    8000463a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000463c:	0001f517          	auipc	a0,0x1f
    80004640:	cec50513          	add	a0,a0,-788 # 80023328 <itable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	642080e7          	jalr	1602(ra) # 80000c86 <release>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	add	sp,sp,32
    80004656:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004658:	40bc                	lw	a5,64(s1)
    8000465a:	dff1                	beqz	a5,80004636 <iput+0x26>
    8000465c:	04a49783          	lh	a5,74(s1)
    80004660:	fbf9                	bnez	a5,80004636 <iput+0x26>
    acquiresleep(&ip->lock);
    80004662:	01048913          	add	s2,s1,16
    80004666:	854a                	mv	a0,s2
    80004668:	00001097          	auipc	ra,0x1
    8000466c:	a84080e7          	jalr	-1404(ra) # 800050ec <acquiresleep>
    release(&itable.lock);
    80004670:	0001f517          	auipc	a0,0x1f
    80004674:	cb850513          	add	a0,a0,-840 # 80023328 <itable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	60e080e7          	jalr	1550(ra) # 80000c86 <release>
    itrunc(ip);
    80004680:	8526                	mv	a0,s1
    80004682:	00000097          	auipc	ra,0x0
    80004686:	ee2080e7          	jalr	-286(ra) # 80004564 <itrunc>
    ip->type = 0;
    8000468a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000468e:	8526                	mv	a0,s1
    80004690:	00000097          	auipc	ra,0x0
    80004694:	cfa080e7          	jalr	-774(ra) # 8000438a <iupdate>
    ip->valid = 0;
    80004698:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000469c:	854a                	mv	a0,s2
    8000469e:	00001097          	auipc	ra,0x1
    800046a2:	aa4080e7          	jalr	-1372(ra) # 80005142 <releasesleep>
    acquire(&itable.lock);
    800046a6:	0001f517          	auipc	a0,0x1f
    800046aa:	c8250513          	add	a0,a0,-894 # 80023328 <itable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	524080e7          	jalr	1316(ra) # 80000bd2 <acquire>
    800046b6:	b741                	j	80004636 <iput+0x26>

00000000800046b8 <iunlockput>:
{
    800046b8:	1101                	add	sp,sp,-32
    800046ba:	ec06                	sd	ra,24(sp)
    800046bc:	e822                	sd	s0,16(sp)
    800046be:	e426                	sd	s1,8(sp)
    800046c0:	1000                	add	s0,sp,32
    800046c2:	84aa                	mv	s1,a0
  iunlock(ip);
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	e54080e7          	jalr	-428(ra) # 80004518 <iunlock>
  iput(ip);
    800046cc:	8526                	mv	a0,s1
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	f42080e7          	jalr	-190(ra) # 80004610 <iput>
}
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	64a2                	ld	s1,8(sp)
    800046dc:	6105                	add	sp,sp,32
    800046de:	8082                	ret

00000000800046e0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800046e0:	1141                	add	sp,sp,-16
    800046e2:	e422                	sd	s0,8(sp)
    800046e4:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    800046e6:	411c                	lw	a5,0(a0)
    800046e8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800046ea:	415c                	lw	a5,4(a0)
    800046ec:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800046ee:	04451783          	lh	a5,68(a0)
    800046f2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800046f6:	04a51783          	lh	a5,74(a0)
    800046fa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800046fe:	04c56783          	lwu	a5,76(a0)
    80004702:	e99c                	sd	a5,16(a1)
}
    80004704:	6422                	ld	s0,8(sp)
    80004706:	0141                	add	sp,sp,16
    80004708:	8082                	ret

000000008000470a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000470a:	457c                	lw	a5,76(a0)
    8000470c:	0ed7e963          	bltu	a5,a3,800047fe <readi+0xf4>
{
    80004710:	7159                	add	sp,sp,-112
    80004712:	f486                	sd	ra,104(sp)
    80004714:	f0a2                	sd	s0,96(sp)
    80004716:	eca6                	sd	s1,88(sp)
    80004718:	e8ca                	sd	s2,80(sp)
    8000471a:	e4ce                	sd	s3,72(sp)
    8000471c:	e0d2                	sd	s4,64(sp)
    8000471e:	fc56                	sd	s5,56(sp)
    80004720:	f85a                	sd	s6,48(sp)
    80004722:	f45e                	sd	s7,40(sp)
    80004724:	f062                	sd	s8,32(sp)
    80004726:	ec66                	sd	s9,24(sp)
    80004728:	e86a                	sd	s10,16(sp)
    8000472a:	e46e                	sd	s11,8(sp)
    8000472c:	1880                	add	s0,sp,112
    8000472e:	8b2a                	mv	s6,a0
    80004730:	8bae                	mv	s7,a1
    80004732:	8a32                	mv	s4,a2
    80004734:	84b6                	mv	s1,a3
    80004736:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004738:	9f35                	addw	a4,a4,a3
    return 0;
    8000473a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000473c:	0ad76063          	bltu	a4,a3,800047dc <readi+0xd2>
  if(off + n > ip->size)
    80004740:	00e7f463          	bgeu	a5,a4,80004748 <readi+0x3e>
    n = ip->size - off;
    80004744:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004748:	0a0a8963          	beqz	s5,800047fa <readi+0xf0>
    8000474c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000474e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004752:	5c7d                	li	s8,-1
    80004754:	a82d                	j	8000478e <readi+0x84>
    80004756:	020d1d93          	sll	s11,s10,0x20
    8000475a:	020ddd93          	srl	s11,s11,0x20
    8000475e:	05890613          	add	a2,s2,88
    80004762:	86ee                	mv	a3,s11
    80004764:	963a                	add	a2,a2,a4
    80004766:	85d2                	mv	a1,s4
    80004768:	855e                	mv	a0,s7
    8000476a:	ffffe097          	auipc	ra,0xffffe
    8000476e:	404080e7          	jalr	1028(ra) # 80002b6e <either_copyout>
    80004772:	05850d63          	beq	a0,s8,800047cc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004776:	854a                	mv	a0,s2
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	5fe080e7          	jalr	1534(ra) # 80003d76 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004780:	013d09bb          	addw	s3,s10,s3
    80004784:	009d04bb          	addw	s1,s10,s1
    80004788:	9a6e                	add	s4,s4,s11
    8000478a:	0559f763          	bgeu	s3,s5,800047d8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000478e:	00a4d59b          	srlw	a1,s1,0xa
    80004792:	855a                	mv	a0,s6
    80004794:	00000097          	auipc	ra,0x0
    80004798:	8a4080e7          	jalr	-1884(ra) # 80004038 <bmap>
    8000479c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800047a0:	cd85                	beqz	a1,800047d8 <readi+0xce>
    bp = bread(ip->dev, addr);
    800047a2:	000b2503          	lw	a0,0(s6)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	4a0080e7          	jalr	1184(ra) # 80003c46 <bread>
    800047ae:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800047b0:	3ff4f713          	and	a4,s1,1023
    800047b4:	40ec87bb          	subw	a5,s9,a4
    800047b8:	413a86bb          	subw	a3,s5,s3
    800047bc:	8d3e                	mv	s10,a5
    800047be:	2781                	sext.w	a5,a5
    800047c0:	0006861b          	sext.w	a2,a3
    800047c4:	f8f679e3          	bgeu	a2,a5,80004756 <readi+0x4c>
    800047c8:	8d36                	mv	s10,a3
    800047ca:	b771                	j	80004756 <readi+0x4c>
      brelse(bp);
    800047cc:	854a                	mv	a0,s2
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	5a8080e7          	jalr	1448(ra) # 80003d76 <brelse>
      tot = -1;
    800047d6:	59fd                	li	s3,-1
  }
  return tot;
    800047d8:	0009851b          	sext.w	a0,s3
}
    800047dc:	70a6                	ld	ra,104(sp)
    800047de:	7406                	ld	s0,96(sp)
    800047e0:	64e6                	ld	s1,88(sp)
    800047e2:	6946                	ld	s2,80(sp)
    800047e4:	69a6                	ld	s3,72(sp)
    800047e6:	6a06                	ld	s4,64(sp)
    800047e8:	7ae2                	ld	s5,56(sp)
    800047ea:	7b42                	ld	s6,48(sp)
    800047ec:	7ba2                	ld	s7,40(sp)
    800047ee:	7c02                	ld	s8,32(sp)
    800047f0:	6ce2                	ld	s9,24(sp)
    800047f2:	6d42                	ld	s10,16(sp)
    800047f4:	6da2                	ld	s11,8(sp)
    800047f6:	6165                	add	sp,sp,112
    800047f8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800047fa:	89d6                	mv	s3,s5
    800047fc:	bff1                	j	800047d8 <readi+0xce>
    return 0;
    800047fe:	4501                	li	a0,0
}
    80004800:	8082                	ret

0000000080004802 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004802:	457c                	lw	a5,76(a0)
    80004804:	10d7e863          	bltu	a5,a3,80004914 <writei+0x112>
{
    80004808:	7159                	add	sp,sp,-112
    8000480a:	f486                	sd	ra,104(sp)
    8000480c:	f0a2                	sd	s0,96(sp)
    8000480e:	eca6                	sd	s1,88(sp)
    80004810:	e8ca                	sd	s2,80(sp)
    80004812:	e4ce                	sd	s3,72(sp)
    80004814:	e0d2                	sd	s4,64(sp)
    80004816:	fc56                	sd	s5,56(sp)
    80004818:	f85a                	sd	s6,48(sp)
    8000481a:	f45e                	sd	s7,40(sp)
    8000481c:	f062                	sd	s8,32(sp)
    8000481e:	ec66                	sd	s9,24(sp)
    80004820:	e86a                	sd	s10,16(sp)
    80004822:	e46e                	sd	s11,8(sp)
    80004824:	1880                	add	s0,sp,112
    80004826:	8aaa                	mv	s5,a0
    80004828:	8bae                	mv	s7,a1
    8000482a:	8a32                	mv	s4,a2
    8000482c:	8936                	mv	s2,a3
    8000482e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004830:	00e687bb          	addw	a5,a3,a4
    80004834:	0ed7e263          	bltu	a5,a3,80004918 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004838:	00043737          	lui	a4,0x43
    8000483c:	0ef76063          	bltu	a4,a5,8000491c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004840:	0c0b0863          	beqz	s6,80004910 <writei+0x10e>
    80004844:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004846:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000484a:	5c7d                	li	s8,-1
    8000484c:	a091                	j	80004890 <writei+0x8e>
    8000484e:	020d1d93          	sll	s11,s10,0x20
    80004852:	020ddd93          	srl	s11,s11,0x20
    80004856:	05848513          	add	a0,s1,88
    8000485a:	86ee                	mv	a3,s11
    8000485c:	8652                	mv	a2,s4
    8000485e:	85de                	mv	a1,s7
    80004860:	953a                	add	a0,a0,a4
    80004862:	ffffe097          	auipc	ra,0xffffe
    80004866:	362080e7          	jalr	866(ra) # 80002bc4 <either_copyin>
    8000486a:	07850263          	beq	a0,s8,800048ce <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000486e:	8526                	mv	a0,s1
    80004870:	00000097          	auipc	ra,0x0
    80004874:	75e080e7          	jalr	1886(ra) # 80004fce <log_write>
    brelse(bp);
    80004878:	8526                	mv	a0,s1
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	4fc080e7          	jalr	1276(ra) # 80003d76 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004882:	013d09bb          	addw	s3,s10,s3
    80004886:	012d093b          	addw	s2,s10,s2
    8000488a:	9a6e                	add	s4,s4,s11
    8000488c:	0569f663          	bgeu	s3,s6,800048d8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004890:	00a9559b          	srlw	a1,s2,0xa
    80004894:	8556                	mv	a0,s5
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	7a2080e7          	jalr	1954(ra) # 80004038 <bmap>
    8000489e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800048a2:	c99d                	beqz	a1,800048d8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800048a4:	000aa503          	lw	a0,0(s5)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	39e080e7          	jalr	926(ra) # 80003c46 <bread>
    800048b0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800048b2:	3ff97713          	and	a4,s2,1023
    800048b6:	40ec87bb          	subw	a5,s9,a4
    800048ba:	413b06bb          	subw	a3,s6,s3
    800048be:	8d3e                	mv	s10,a5
    800048c0:	2781                	sext.w	a5,a5
    800048c2:	0006861b          	sext.w	a2,a3
    800048c6:	f8f674e3          	bgeu	a2,a5,8000484e <writei+0x4c>
    800048ca:	8d36                	mv	s10,a3
    800048cc:	b749                	j	8000484e <writei+0x4c>
      brelse(bp);
    800048ce:	8526                	mv	a0,s1
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	4a6080e7          	jalr	1190(ra) # 80003d76 <brelse>
  }

  if(off > ip->size)
    800048d8:	04caa783          	lw	a5,76(s5)
    800048dc:	0127f463          	bgeu	a5,s2,800048e4 <writei+0xe2>
    ip->size = off;
    800048e0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800048e4:	8556                	mv	a0,s5
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	aa4080e7          	jalr	-1372(ra) # 8000438a <iupdate>

  return tot;
    800048ee:	0009851b          	sext.w	a0,s3
}
    800048f2:	70a6                	ld	ra,104(sp)
    800048f4:	7406                	ld	s0,96(sp)
    800048f6:	64e6                	ld	s1,88(sp)
    800048f8:	6946                	ld	s2,80(sp)
    800048fa:	69a6                	ld	s3,72(sp)
    800048fc:	6a06                	ld	s4,64(sp)
    800048fe:	7ae2                	ld	s5,56(sp)
    80004900:	7b42                	ld	s6,48(sp)
    80004902:	7ba2                	ld	s7,40(sp)
    80004904:	7c02                	ld	s8,32(sp)
    80004906:	6ce2                	ld	s9,24(sp)
    80004908:	6d42                	ld	s10,16(sp)
    8000490a:	6da2                	ld	s11,8(sp)
    8000490c:	6165                	add	sp,sp,112
    8000490e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004910:	89da                	mv	s3,s6
    80004912:	bfc9                	j	800048e4 <writei+0xe2>
    return -1;
    80004914:	557d                	li	a0,-1
}
    80004916:	8082                	ret
    return -1;
    80004918:	557d                	li	a0,-1
    8000491a:	bfe1                	j	800048f2 <writei+0xf0>
    return -1;
    8000491c:	557d                	li	a0,-1
    8000491e:	bfd1                	j	800048f2 <writei+0xf0>

0000000080004920 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004920:	1141                	add	sp,sp,-16
    80004922:	e406                	sd	ra,8(sp)
    80004924:	e022                	sd	s0,0(sp)
    80004926:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004928:	4639                	li	a2,14
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	474080e7          	jalr	1140(ra) # 80000d9e <strncmp>
}
    80004932:	60a2                	ld	ra,8(sp)
    80004934:	6402                	ld	s0,0(sp)
    80004936:	0141                	add	sp,sp,16
    80004938:	8082                	ret

000000008000493a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000493a:	7139                	add	sp,sp,-64
    8000493c:	fc06                	sd	ra,56(sp)
    8000493e:	f822                	sd	s0,48(sp)
    80004940:	f426                	sd	s1,40(sp)
    80004942:	f04a                	sd	s2,32(sp)
    80004944:	ec4e                	sd	s3,24(sp)
    80004946:	e852                	sd	s4,16(sp)
    80004948:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000494a:	04451703          	lh	a4,68(a0)
    8000494e:	4785                	li	a5,1
    80004950:	00f71a63          	bne	a4,a5,80004964 <dirlookup+0x2a>
    80004954:	892a                	mv	s2,a0
    80004956:	89ae                	mv	s3,a1
    80004958:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000495a:	457c                	lw	a5,76(a0)
    8000495c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000495e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004960:	e79d                	bnez	a5,8000498e <dirlookup+0x54>
    80004962:	a8a5                	j	800049da <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004964:	00004517          	auipc	a0,0x4
    80004968:	d7c50513          	add	a0,a0,-644 # 800086e0 <syscalls+0x1e8>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	bd0080e7          	jalr	-1072(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004974:	00004517          	auipc	a0,0x4
    80004978:	d8450513          	add	a0,a0,-636 # 800086f8 <syscalls+0x200>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	bc0080e7          	jalr	-1088(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004984:	24c1                	addw	s1,s1,16
    80004986:	04c92783          	lw	a5,76(s2)
    8000498a:	04f4f763          	bgeu	s1,a5,800049d8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000498e:	4741                	li	a4,16
    80004990:	86a6                	mv	a3,s1
    80004992:	fc040613          	add	a2,s0,-64
    80004996:	4581                	li	a1,0
    80004998:	854a                	mv	a0,s2
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	d70080e7          	jalr	-656(ra) # 8000470a <readi>
    800049a2:	47c1                	li	a5,16
    800049a4:	fcf518e3          	bne	a0,a5,80004974 <dirlookup+0x3a>
    if(de.inum == 0)
    800049a8:	fc045783          	lhu	a5,-64(s0)
    800049ac:	dfe1                	beqz	a5,80004984 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800049ae:	fc240593          	add	a1,s0,-62
    800049b2:	854e                	mv	a0,s3
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	f6c080e7          	jalr	-148(ra) # 80004920 <namecmp>
    800049bc:	f561                	bnez	a0,80004984 <dirlookup+0x4a>
      if(poff)
    800049be:	000a0463          	beqz	s4,800049c6 <dirlookup+0x8c>
        *poff = off;
    800049c2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800049c6:	fc045583          	lhu	a1,-64(s0)
    800049ca:	00092503          	lw	a0,0(s2)
    800049ce:	fffff097          	auipc	ra,0xfffff
    800049d2:	754080e7          	jalr	1876(ra) # 80004122 <iget>
    800049d6:	a011                	j	800049da <dirlookup+0xa0>
  return 0;
    800049d8:	4501                	li	a0,0
}
    800049da:	70e2                	ld	ra,56(sp)
    800049dc:	7442                	ld	s0,48(sp)
    800049de:	74a2                	ld	s1,40(sp)
    800049e0:	7902                	ld	s2,32(sp)
    800049e2:	69e2                	ld	s3,24(sp)
    800049e4:	6a42                	ld	s4,16(sp)
    800049e6:	6121                	add	sp,sp,64
    800049e8:	8082                	ret

00000000800049ea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800049ea:	711d                	add	sp,sp,-96
    800049ec:	ec86                	sd	ra,88(sp)
    800049ee:	e8a2                	sd	s0,80(sp)
    800049f0:	e4a6                	sd	s1,72(sp)
    800049f2:	e0ca                	sd	s2,64(sp)
    800049f4:	fc4e                	sd	s3,56(sp)
    800049f6:	f852                	sd	s4,48(sp)
    800049f8:	f456                	sd	s5,40(sp)
    800049fa:	f05a                	sd	s6,32(sp)
    800049fc:	ec5e                	sd	s7,24(sp)
    800049fe:	e862                	sd	s8,16(sp)
    80004a00:	e466                	sd	s9,8(sp)
    80004a02:	1080                	add	s0,sp,96
    80004a04:	84aa                	mv	s1,a0
    80004a06:	8b2e                	mv	s6,a1
    80004a08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004a0a:	00054703          	lbu	a4,0(a0)
    80004a0e:	02f00793          	li	a5,47
    80004a12:	02f70263          	beq	a4,a5,80004a36 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004a16:	ffffd097          	auipc	ra,0xffffd
    80004a1a:	fa0080e7          	jalr	-96(ra) # 800019b6 <myproc>
    80004a1e:	15053503          	ld	a0,336(a0)
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	9f6080e7          	jalr	-1546(ra) # 80004418 <idup>
    80004a2a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004a2c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004a30:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004a32:	4b85                	li	s7,1
    80004a34:	a875                	j	80004af0 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004a36:	4585                	li	a1,1
    80004a38:	4505                	li	a0,1
    80004a3a:	fffff097          	auipc	ra,0xfffff
    80004a3e:	6e8080e7          	jalr	1768(ra) # 80004122 <iget>
    80004a42:	8a2a                	mv	s4,a0
    80004a44:	b7e5                	j	80004a2c <namex+0x42>
      iunlockput(ip);
    80004a46:	8552                	mv	a0,s4
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	c70080e7          	jalr	-912(ra) # 800046b8 <iunlockput>
      return 0;
    80004a50:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004a52:	8552                	mv	a0,s4
    80004a54:	60e6                	ld	ra,88(sp)
    80004a56:	6446                	ld	s0,80(sp)
    80004a58:	64a6                	ld	s1,72(sp)
    80004a5a:	6906                	ld	s2,64(sp)
    80004a5c:	79e2                	ld	s3,56(sp)
    80004a5e:	7a42                	ld	s4,48(sp)
    80004a60:	7aa2                	ld	s5,40(sp)
    80004a62:	7b02                	ld	s6,32(sp)
    80004a64:	6be2                	ld	s7,24(sp)
    80004a66:	6c42                	ld	s8,16(sp)
    80004a68:	6ca2                	ld	s9,8(sp)
    80004a6a:	6125                	add	sp,sp,96
    80004a6c:	8082                	ret
      iunlock(ip);
    80004a6e:	8552                	mv	a0,s4
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	aa8080e7          	jalr	-1368(ra) # 80004518 <iunlock>
      return ip;
    80004a78:	bfe9                	j	80004a52 <namex+0x68>
      iunlockput(ip);
    80004a7a:	8552                	mv	a0,s4
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	c3c080e7          	jalr	-964(ra) # 800046b8 <iunlockput>
      return 0;
    80004a84:	8a4e                	mv	s4,s3
    80004a86:	b7f1                	j	80004a52 <namex+0x68>
  len = path - s;
    80004a88:	40998633          	sub	a2,s3,s1
    80004a8c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004a90:	099c5863          	bge	s8,s9,80004b20 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004a94:	4639                	li	a2,14
    80004a96:	85a6                	mv	a1,s1
    80004a98:	8556                	mv	a0,s5
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	290080e7          	jalr	656(ra) # 80000d2a <memmove>
    80004aa2:	84ce                	mv	s1,s3
  while(*path == '/')
    80004aa4:	0004c783          	lbu	a5,0(s1)
    80004aa8:	01279763          	bne	a5,s2,80004ab6 <namex+0xcc>
    path++;
    80004aac:	0485                	add	s1,s1,1
  while(*path == '/')
    80004aae:	0004c783          	lbu	a5,0(s1)
    80004ab2:	ff278de3          	beq	a5,s2,80004aac <namex+0xc2>
    ilock(ip);
    80004ab6:	8552                	mv	a0,s4
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	99e080e7          	jalr	-1634(ra) # 80004456 <ilock>
    if(ip->type != T_DIR){
    80004ac0:	044a1783          	lh	a5,68(s4)
    80004ac4:	f97791e3          	bne	a5,s7,80004a46 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004ac8:	000b0563          	beqz	s6,80004ad2 <namex+0xe8>
    80004acc:	0004c783          	lbu	a5,0(s1)
    80004ad0:	dfd9                	beqz	a5,80004a6e <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004ad2:	4601                	li	a2,0
    80004ad4:	85d6                	mv	a1,s5
    80004ad6:	8552                	mv	a0,s4
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	e62080e7          	jalr	-414(ra) # 8000493a <dirlookup>
    80004ae0:	89aa                	mv	s3,a0
    80004ae2:	dd41                	beqz	a0,80004a7a <namex+0x90>
    iunlockput(ip);
    80004ae4:	8552                	mv	a0,s4
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	bd2080e7          	jalr	-1070(ra) # 800046b8 <iunlockput>
    ip = next;
    80004aee:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004af0:	0004c783          	lbu	a5,0(s1)
    80004af4:	01279763          	bne	a5,s2,80004b02 <namex+0x118>
    path++;
    80004af8:	0485                	add	s1,s1,1
  while(*path == '/')
    80004afa:	0004c783          	lbu	a5,0(s1)
    80004afe:	ff278de3          	beq	a5,s2,80004af8 <namex+0x10e>
  if(*path == 0)
    80004b02:	cb9d                	beqz	a5,80004b38 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004b04:	0004c783          	lbu	a5,0(s1)
    80004b08:	89a6                	mv	s3,s1
  len = path - s;
    80004b0a:	4c81                	li	s9,0
    80004b0c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004b0e:	01278963          	beq	a5,s2,80004b20 <namex+0x136>
    80004b12:	dbbd                	beqz	a5,80004a88 <namex+0x9e>
    path++;
    80004b14:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004b16:	0009c783          	lbu	a5,0(s3)
    80004b1a:	ff279ce3          	bne	a5,s2,80004b12 <namex+0x128>
    80004b1e:	b7ad                	j	80004a88 <namex+0x9e>
    memmove(name, s, len);
    80004b20:	2601                	sext.w	a2,a2
    80004b22:	85a6                	mv	a1,s1
    80004b24:	8556                	mv	a0,s5
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	204080e7          	jalr	516(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004b2e:	9cd6                	add	s9,s9,s5
    80004b30:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004b34:	84ce                	mv	s1,s3
    80004b36:	b7bd                	j	80004aa4 <namex+0xba>
  if(nameiparent){
    80004b38:	f00b0de3          	beqz	s6,80004a52 <namex+0x68>
    iput(ip);
    80004b3c:	8552                	mv	a0,s4
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	ad2080e7          	jalr	-1326(ra) # 80004610 <iput>
    return 0;
    80004b46:	4a01                	li	s4,0
    80004b48:	b729                	j	80004a52 <namex+0x68>

0000000080004b4a <dirlink>:
{
    80004b4a:	7139                	add	sp,sp,-64
    80004b4c:	fc06                	sd	ra,56(sp)
    80004b4e:	f822                	sd	s0,48(sp)
    80004b50:	f426                	sd	s1,40(sp)
    80004b52:	f04a                	sd	s2,32(sp)
    80004b54:	ec4e                	sd	s3,24(sp)
    80004b56:	e852                	sd	s4,16(sp)
    80004b58:	0080                	add	s0,sp,64
    80004b5a:	892a                	mv	s2,a0
    80004b5c:	8a2e                	mv	s4,a1
    80004b5e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004b60:	4601                	li	a2,0
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	dd8080e7          	jalr	-552(ra) # 8000493a <dirlookup>
    80004b6a:	e93d                	bnez	a0,80004be0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b6c:	04c92483          	lw	s1,76(s2)
    80004b70:	c49d                	beqz	s1,80004b9e <dirlink+0x54>
    80004b72:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b74:	4741                	li	a4,16
    80004b76:	86a6                	mv	a3,s1
    80004b78:	fc040613          	add	a2,s0,-64
    80004b7c:	4581                	li	a1,0
    80004b7e:	854a                	mv	a0,s2
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	b8a080e7          	jalr	-1142(ra) # 8000470a <readi>
    80004b88:	47c1                	li	a5,16
    80004b8a:	06f51163          	bne	a0,a5,80004bec <dirlink+0xa2>
    if(de.inum == 0)
    80004b8e:	fc045783          	lhu	a5,-64(s0)
    80004b92:	c791                	beqz	a5,80004b9e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b94:	24c1                	addw	s1,s1,16
    80004b96:	04c92783          	lw	a5,76(s2)
    80004b9a:	fcf4ede3          	bltu	s1,a5,80004b74 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004b9e:	4639                	li	a2,14
    80004ba0:	85d2                	mv	a1,s4
    80004ba2:	fc240513          	add	a0,s0,-62
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	234080e7          	jalr	564(ra) # 80000dda <strncpy>
  de.inum = inum;
    80004bae:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004bb2:	4741                	li	a4,16
    80004bb4:	86a6                	mv	a3,s1
    80004bb6:	fc040613          	add	a2,s0,-64
    80004bba:	4581                	li	a1,0
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	c44080e7          	jalr	-956(ra) # 80004802 <writei>
    80004bc6:	1541                	add	a0,a0,-16
    80004bc8:	00a03533          	snez	a0,a0
    80004bcc:	40a00533          	neg	a0,a0
}
    80004bd0:	70e2                	ld	ra,56(sp)
    80004bd2:	7442                	ld	s0,48(sp)
    80004bd4:	74a2                	ld	s1,40(sp)
    80004bd6:	7902                	ld	s2,32(sp)
    80004bd8:	69e2                	ld	s3,24(sp)
    80004bda:	6a42                	ld	s4,16(sp)
    80004bdc:	6121                	add	sp,sp,64
    80004bde:	8082                	ret
    iput(ip);
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	a30080e7          	jalr	-1488(ra) # 80004610 <iput>
    return -1;
    80004be8:	557d                	li	a0,-1
    80004bea:	b7dd                	j	80004bd0 <dirlink+0x86>
      panic("dirlink read");
    80004bec:	00004517          	auipc	a0,0x4
    80004bf0:	b1c50513          	add	a0,a0,-1252 # 80008708 <syscalls+0x210>
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	948080e7          	jalr	-1720(ra) # 8000053c <panic>

0000000080004bfc <namei>:

struct inode*
namei(char *path)
{
    80004bfc:	1101                	add	sp,sp,-32
    80004bfe:	ec06                	sd	ra,24(sp)
    80004c00:	e822                	sd	s0,16(sp)
    80004c02:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004c04:	fe040613          	add	a2,s0,-32
    80004c08:	4581                	li	a1,0
    80004c0a:	00000097          	auipc	ra,0x0
    80004c0e:	de0080e7          	jalr	-544(ra) # 800049ea <namex>
}
    80004c12:	60e2                	ld	ra,24(sp)
    80004c14:	6442                	ld	s0,16(sp)
    80004c16:	6105                	add	sp,sp,32
    80004c18:	8082                	ret

0000000080004c1a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004c1a:	1141                	add	sp,sp,-16
    80004c1c:	e406                	sd	ra,8(sp)
    80004c1e:	e022                	sd	s0,0(sp)
    80004c20:	0800                	add	s0,sp,16
    80004c22:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004c24:	4585                	li	a1,1
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	dc4080e7          	jalr	-572(ra) # 800049ea <namex>
}
    80004c2e:	60a2                	ld	ra,8(sp)
    80004c30:	6402                	ld	s0,0(sp)
    80004c32:	0141                	add	sp,sp,16
    80004c34:	8082                	ret

0000000080004c36 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004c36:	1101                	add	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	e04a                	sd	s2,0(sp)
    80004c40:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004c42:	00020917          	auipc	s2,0x20
    80004c46:	18e90913          	add	s2,s2,398 # 80024dd0 <log>
    80004c4a:	01892583          	lw	a1,24(s2)
    80004c4e:	02892503          	lw	a0,40(s2)
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	ff4080e7          	jalr	-12(ra) # 80003c46 <bread>
    80004c5a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004c5c:	02c92603          	lw	a2,44(s2)
    80004c60:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004c62:	00c05f63          	blez	a2,80004c80 <write_head+0x4a>
    80004c66:	00020717          	auipc	a4,0x20
    80004c6a:	19a70713          	add	a4,a4,410 # 80024e00 <log+0x30>
    80004c6e:	87aa                	mv	a5,a0
    80004c70:	060a                	sll	a2,a2,0x2
    80004c72:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004c74:	4314                	lw	a3,0(a4)
    80004c76:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004c78:	0711                	add	a4,a4,4
    80004c7a:	0791                	add	a5,a5,4
    80004c7c:	fec79ce3          	bne	a5,a2,80004c74 <write_head+0x3e>
  }
  bwrite(buf);
    80004c80:	8526                	mv	a0,s1
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	0b6080e7          	jalr	182(ra) # 80003d38 <bwrite>
  brelse(buf);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	0ea080e7          	jalr	234(ra) # 80003d76 <brelse>
}
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6902                	ld	s2,0(sp)
    80004c9c:	6105                	add	sp,sp,32
    80004c9e:	8082                	ret

0000000080004ca0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ca0:	00020797          	auipc	a5,0x20
    80004ca4:	15c7a783          	lw	a5,348(a5) # 80024dfc <log+0x2c>
    80004ca8:	0af05d63          	blez	a5,80004d62 <install_trans+0xc2>
{
    80004cac:	7139                	add	sp,sp,-64
    80004cae:	fc06                	sd	ra,56(sp)
    80004cb0:	f822                	sd	s0,48(sp)
    80004cb2:	f426                	sd	s1,40(sp)
    80004cb4:	f04a                	sd	s2,32(sp)
    80004cb6:	ec4e                	sd	s3,24(sp)
    80004cb8:	e852                	sd	s4,16(sp)
    80004cba:	e456                	sd	s5,8(sp)
    80004cbc:	e05a                	sd	s6,0(sp)
    80004cbe:	0080                	add	s0,sp,64
    80004cc0:	8b2a                	mv	s6,a0
    80004cc2:	00020a97          	auipc	s5,0x20
    80004cc6:	13ea8a93          	add	s5,s5,318 # 80024e00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cca:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ccc:	00020997          	auipc	s3,0x20
    80004cd0:	10498993          	add	s3,s3,260 # 80024dd0 <log>
    80004cd4:	a00d                	j	80004cf6 <install_trans+0x56>
    brelse(lbuf);
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	09e080e7          	jalr	158(ra) # 80003d76 <brelse>
    brelse(dbuf);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	094080e7          	jalr	148(ra) # 80003d76 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cea:	2a05                	addw	s4,s4,1
    80004cec:	0a91                	add	s5,s5,4
    80004cee:	02c9a783          	lw	a5,44(s3)
    80004cf2:	04fa5e63          	bge	s4,a5,80004d4e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004cf6:	0189a583          	lw	a1,24(s3)
    80004cfa:	014585bb          	addw	a1,a1,s4
    80004cfe:	2585                	addw	a1,a1,1
    80004d00:	0289a503          	lw	a0,40(s3)
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	f42080e7          	jalr	-190(ra) # 80003c46 <bread>
    80004d0c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004d0e:	000aa583          	lw	a1,0(s5)
    80004d12:	0289a503          	lw	a0,40(s3)
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	f30080e7          	jalr	-208(ra) # 80003c46 <bread>
    80004d1e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004d20:	40000613          	li	a2,1024
    80004d24:	05890593          	add	a1,s2,88
    80004d28:	05850513          	add	a0,a0,88
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	ffe080e7          	jalr	-2(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004d34:	8526                	mv	a0,s1
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	002080e7          	jalr	2(ra) # 80003d38 <bwrite>
    if(recovering == 0)
    80004d3e:	f80b1ce3          	bnez	s6,80004cd6 <install_trans+0x36>
      bunpin(dbuf);
    80004d42:	8526                	mv	a0,s1
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	10a080e7          	jalr	266(ra) # 80003e4e <bunpin>
    80004d4c:	b769                	j	80004cd6 <install_trans+0x36>
}
    80004d4e:	70e2                	ld	ra,56(sp)
    80004d50:	7442                	ld	s0,48(sp)
    80004d52:	74a2                	ld	s1,40(sp)
    80004d54:	7902                	ld	s2,32(sp)
    80004d56:	69e2                	ld	s3,24(sp)
    80004d58:	6a42                	ld	s4,16(sp)
    80004d5a:	6aa2                	ld	s5,8(sp)
    80004d5c:	6b02                	ld	s6,0(sp)
    80004d5e:	6121                	add	sp,sp,64
    80004d60:	8082                	ret
    80004d62:	8082                	ret

0000000080004d64 <initlog>:
{
    80004d64:	7179                	add	sp,sp,-48
    80004d66:	f406                	sd	ra,40(sp)
    80004d68:	f022                	sd	s0,32(sp)
    80004d6a:	ec26                	sd	s1,24(sp)
    80004d6c:	e84a                	sd	s2,16(sp)
    80004d6e:	e44e                	sd	s3,8(sp)
    80004d70:	1800                	add	s0,sp,48
    80004d72:	892a                	mv	s2,a0
    80004d74:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004d76:	00020497          	auipc	s1,0x20
    80004d7a:	05a48493          	add	s1,s1,90 # 80024dd0 <log>
    80004d7e:	00004597          	auipc	a1,0x4
    80004d82:	99a58593          	add	a1,a1,-1638 # 80008718 <syscalls+0x220>
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	dba080e7          	jalr	-582(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004d90:	0149a583          	lw	a1,20(s3)
    80004d94:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004d96:	0109a783          	lw	a5,16(s3)
    80004d9a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004d9c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004da0:	854a                	mv	a0,s2
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	ea4080e7          	jalr	-348(ra) # 80003c46 <bread>
  log.lh.n = lh->n;
    80004daa:	4d30                	lw	a2,88(a0)
    80004dac:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004dae:	00c05f63          	blez	a2,80004dcc <initlog+0x68>
    80004db2:	87aa                	mv	a5,a0
    80004db4:	00020717          	auipc	a4,0x20
    80004db8:	04c70713          	add	a4,a4,76 # 80024e00 <log+0x30>
    80004dbc:	060a                	sll	a2,a2,0x2
    80004dbe:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004dc0:	4ff4                	lw	a3,92(a5)
    80004dc2:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004dc4:	0791                	add	a5,a5,4
    80004dc6:	0711                	add	a4,a4,4
    80004dc8:	fec79ce3          	bne	a5,a2,80004dc0 <initlog+0x5c>
  brelse(buf);
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	faa080e7          	jalr	-86(ra) # 80003d76 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004dd4:	4505                	li	a0,1
    80004dd6:	00000097          	auipc	ra,0x0
    80004dda:	eca080e7          	jalr	-310(ra) # 80004ca0 <install_trans>
  log.lh.n = 0;
    80004dde:	00020797          	auipc	a5,0x20
    80004de2:	0007af23          	sw	zero,30(a5) # 80024dfc <log+0x2c>
  write_head(); // clear the log
    80004de6:	00000097          	auipc	ra,0x0
    80004dea:	e50080e7          	jalr	-432(ra) # 80004c36 <write_head>
}
    80004dee:	70a2                	ld	ra,40(sp)
    80004df0:	7402                	ld	s0,32(sp)
    80004df2:	64e2                	ld	s1,24(sp)
    80004df4:	6942                	ld	s2,16(sp)
    80004df6:	69a2                	ld	s3,8(sp)
    80004df8:	6145                	add	sp,sp,48
    80004dfa:	8082                	ret

0000000080004dfc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004dfc:	1101                	add	sp,sp,-32
    80004dfe:	ec06                	sd	ra,24(sp)
    80004e00:	e822                	sd	s0,16(sp)
    80004e02:	e426                	sd	s1,8(sp)
    80004e04:	e04a                	sd	s2,0(sp)
    80004e06:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004e08:	00020517          	auipc	a0,0x20
    80004e0c:	fc850513          	add	a0,a0,-56 # 80024dd0 <log>
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	dc2080e7          	jalr	-574(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004e18:	00020497          	auipc	s1,0x20
    80004e1c:	fb848493          	add	s1,s1,-72 # 80024dd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004e20:	4979                	li	s2,30
    80004e22:	a039                	j	80004e30 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004e24:	85a6                	mv	a1,s1
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffe097          	auipc	ra,0xffffe
    80004e2c:	91a080e7          	jalr	-1766(ra) # 80002742 <sleep>
    if(log.committing){
    80004e30:	50dc                	lw	a5,36(s1)
    80004e32:	fbed                	bnez	a5,80004e24 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004e34:	5098                	lw	a4,32(s1)
    80004e36:	2705                	addw	a4,a4,1
    80004e38:	0027179b          	sllw	a5,a4,0x2
    80004e3c:	9fb9                	addw	a5,a5,a4
    80004e3e:	0017979b          	sllw	a5,a5,0x1
    80004e42:	54d4                	lw	a3,44(s1)
    80004e44:	9fb5                	addw	a5,a5,a3
    80004e46:	00f95963          	bge	s2,a5,80004e58 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004e4a:	85a6                	mv	a1,s1
    80004e4c:	8526                	mv	a0,s1
    80004e4e:	ffffe097          	auipc	ra,0xffffe
    80004e52:	8f4080e7          	jalr	-1804(ra) # 80002742 <sleep>
    80004e56:	bfe9                	j	80004e30 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004e58:	00020517          	auipc	a0,0x20
    80004e5c:	f7850513          	add	a0,a0,-136 # 80024dd0 <log>
    80004e60:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004e6a:	60e2                	ld	ra,24(sp)
    80004e6c:	6442                	ld	s0,16(sp)
    80004e6e:	64a2                	ld	s1,8(sp)
    80004e70:	6902                	ld	s2,0(sp)
    80004e72:	6105                	add	sp,sp,32
    80004e74:	8082                	ret

0000000080004e76 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004e76:	7139                	add	sp,sp,-64
    80004e78:	fc06                	sd	ra,56(sp)
    80004e7a:	f822                	sd	s0,48(sp)
    80004e7c:	f426                	sd	s1,40(sp)
    80004e7e:	f04a                	sd	s2,32(sp)
    80004e80:	ec4e                	sd	s3,24(sp)
    80004e82:	e852                	sd	s4,16(sp)
    80004e84:	e456                	sd	s5,8(sp)
    80004e86:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004e88:	00020497          	auipc	s1,0x20
    80004e8c:	f4848493          	add	s1,s1,-184 # 80024dd0 <log>
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	d40080e7          	jalr	-704(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004e9a:	509c                	lw	a5,32(s1)
    80004e9c:	37fd                	addw	a5,a5,-1
    80004e9e:	0007891b          	sext.w	s2,a5
    80004ea2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ea4:	50dc                	lw	a5,36(s1)
    80004ea6:	e7b9                	bnez	a5,80004ef4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ea8:	04091e63          	bnez	s2,80004f04 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004eac:	00020497          	auipc	s1,0x20
    80004eb0:	f2448493          	add	s1,s1,-220 # 80024dd0 <log>
    80004eb4:	4785                	li	a5,1
    80004eb6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004eb8:	8526                	mv	a0,s1
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	dcc080e7          	jalr	-564(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ec2:	54dc                	lw	a5,44(s1)
    80004ec4:	06f04763          	bgtz	a5,80004f32 <end_op+0xbc>
    acquire(&log.lock);
    80004ec8:	00020497          	auipc	s1,0x20
    80004ecc:	f0848493          	add	s1,s1,-248 # 80024dd0 <log>
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	d00080e7          	jalr	-768(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004eda:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004ede:	8526                	mv	a0,s1
    80004ee0:	ffffe097          	auipc	ra,0xffffe
    80004ee4:	8c6080e7          	jalr	-1850(ra) # 800027a6 <wakeup>
    release(&log.lock);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	d9c080e7          	jalr	-612(ra) # 80000c86 <release>
}
    80004ef2:	a03d                	j	80004f20 <end_op+0xaa>
    panic("log.committing");
    80004ef4:	00004517          	auipc	a0,0x4
    80004ef8:	82c50513          	add	a0,a0,-2004 # 80008720 <syscalls+0x228>
    80004efc:	ffffb097          	auipc	ra,0xffffb
    80004f00:	640080e7          	jalr	1600(ra) # 8000053c <panic>
    wakeup(&log);
    80004f04:	00020497          	auipc	s1,0x20
    80004f08:	ecc48493          	add	s1,s1,-308 # 80024dd0 <log>
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffe097          	auipc	ra,0xffffe
    80004f12:	898080e7          	jalr	-1896(ra) # 800027a6 <wakeup>
  release(&log.lock);
    80004f16:	8526                	mv	a0,s1
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	d6e080e7          	jalr	-658(ra) # 80000c86 <release>
}
    80004f20:	70e2                	ld	ra,56(sp)
    80004f22:	7442                	ld	s0,48(sp)
    80004f24:	74a2                	ld	s1,40(sp)
    80004f26:	7902                	ld	s2,32(sp)
    80004f28:	69e2                	ld	s3,24(sp)
    80004f2a:	6a42                	ld	s4,16(sp)
    80004f2c:	6aa2                	ld	s5,8(sp)
    80004f2e:	6121                	add	sp,sp,64
    80004f30:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f32:	00020a97          	auipc	s5,0x20
    80004f36:	ecea8a93          	add	s5,s5,-306 # 80024e00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004f3a:	00020a17          	auipc	s4,0x20
    80004f3e:	e96a0a13          	add	s4,s4,-362 # 80024dd0 <log>
    80004f42:	018a2583          	lw	a1,24(s4)
    80004f46:	012585bb          	addw	a1,a1,s2
    80004f4a:	2585                	addw	a1,a1,1
    80004f4c:	028a2503          	lw	a0,40(s4)
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	cf6080e7          	jalr	-778(ra) # 80003c46 <bread>
    80004f58:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004f5a:	000aa583          	lw	a1,0(s5)
    80004f5e:	028a2503          	lw	a0,40(s4)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	ce4080e7          	jalr	-796(ra) # 80003c46 <bread>
    80004f6a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004f6c:	40000613          	li	a2,1024
    80004f70:	05850593          	add	a1,a0,88
    80004f74:	05848513          	add	a0,s1,88
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	db2080e7          	jalr	-590(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004f80:	8526                	mv	a0,s1
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	db6080e7          	jalr	-586(ra) # 80003d38 <bwrite>
    brelse(from);
    80004f8a:	854e                	mv	a0,s3
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	dea080e7          	jalr	-534(ra) # 80003d76 <brelse>
    brelse(to);
    80004f94:	8526                	mv	a0,s1
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	de0080e7          	jalr	-544(ra) # 80003d76 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f9e:	2905                	addw	s2,s2,1
    80004fa0:	0a91                	add	s5,s5,4
    80004fa2:	02ca2783          	lw	a5,44(s4)
    80004fa6:	f8f94ee3          	blt	s2,a5,80004f42 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004faa:	00000097          	auipc	ra,0x0
    80004fae:	c8c080e7          	jalr	-884(ra) # 80004c36 <write_head>
    install_trans(0); // Now install writes to home locations
    80004fb2:	4501                	li	a0,0
    80004fb4:	00000097          	auipc	ra,0x0
    80004fb8:	cec080e7          	jalr	-788(ra) # 80004ca0 <install_trans>
    log.lh.n = 0;
    80004fbc:	00020797          	auipc	a5,0x20
    80004fc0:	e407a023          	sw	zero,-448(a5) # 80024dfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004fc4:	00000097          	auipc	ra,0x0
    80004fc8:	c72080e7          	jalr	-910(ra) # 80004c36 <write_head>
    80004fcc:	bdf5                	j	80004ec8 <end_op+0x52>

0000000080004fce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004fce:	1101                	add	sp,sp,-32
    80004fd0:	ec06                	sd	ra,24(sp)
    80004fd2:	e822                	sd	s0,16(sp)
    80004fd4:	e426                	sd	s1,8(sp)
    80004fd6:	e04a                	sd	s2,0(sp)
    80004fd8:	1000                	add	s0,sp,32
    80004fda:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004fdc:	00020917          	auipc	s2,0x20
    80004fe0:	df490913          	add	s2,s2,-524 # 80024dd0 <log>
    80004fe4:	854a                	mv	a0,s2
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	bec080e7          	jalr	-1044(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004fee:	02c92603          	lw	a2,44(s2)
    80004ff2:	47f5                	li	a5,29
    80004ff4:	06c7c563          	blt	a5,a2,8000505e <log_write+0x90>
    80004ff8:	00020797          	auipc	a5,0x20
    80004ffc:	df47a783          	lw	a5,-524(a5) # 80024dec <log+0x1c>
    80005000:	37fd                	addw	a5,a5,-1
    80005002:	04f65e63          	bge	a2,a5,8000505e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005006:	00020797          	auipc	a5,0x20
    8000500a:	dea7a783          	lw	a5,-534(a5) # 80024df0 <log+0x20>
    8000500e:	06f05063          	blez	a5,8000506e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005012:	4781                	li	a5,0
    80005014:	06c05563          	blez	a2,8000507e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005018:	44cc                	lw	a1,12(s1)
    8000501a:	00020717          	auipc	a4,0x20
    8000501e:	de670713          	add	a4,a4,-538 # 80024e00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005022:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005024:	4314                	lw	a3,0(a4)
    80005026:	04b68c63          	beq	a3,a1,8000507e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000502a:	2785                	addw	a5,a5,1
    8000502c:	0711                	add	a4,a4,4
    8000502e:	fef61be3          	bne	a2,a5,80005024 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005032:	0621                	add	a2,a2,8
    80005034:	060a                	sll	a2,a2,0x2
    80005036:	00020797          	auipc	a5,0x20
    8000503a:	d9a78793          	add	a5,a5,-614 # 80024dd0 <log>
    8000503e:	97b2                	add	a5,a5,a2
    80005040:	44d8                	lw	a4,12(s1)
    80005042:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005044:	8526                	mv	a0,s1
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	dcc080e7          	jalr	-564(ra) # 80003e12 <bpin>
    log.lh.n++;
    8000504e:	00020717          	auipc	a4,0x20
    80005052:	d8270713          	add	a4,a4,-638 # 80024dd0 <log>
    80005056:	575c                	lw	a5,44(a4)
    80005058:	2785                	addw	a5,a5,1
    8000505a:	d75c                	sw	a5,44(a4)
    8000505c:	a82d                	j	80005096 <log_write+0xc8>
    panic("too big a transaction");
    8000505e:	00003517          	auipc	a0,0x3
    80005062:	6d250513          	add	a0,a0,1746 # 80008730 <syscalls+0x238>
    80005066:	ffffb097          	auipc	ra,0xffffb
    8000506a:	4d6080e7          	jalr	1238(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000506e:	00003517          	auipc	a0,0x3
    80005072:	6da50513          	add	a0,a0,1754 # 80008748 <syscalls+0x250>
    80005076:	ffffb097          	auipc	ra,0xffffb
    8000507a:	4c6080e7          	jalr	1222(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000507e:	00878693          	add	a3,a5,8
    80005082:	068a                	sll	a3,a3,0x2
    80005084:	00020717          	auipc	a4,0x20
    80005088:	d4c70713          	add	a4,a4,-692 # 80024dd0 <log>
    8000508c:	9736                	add	a4,a4,a3
    8000508e:	44d4                	lw	a3,12(s1)
    80005090:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005092:	faf609e3          	beq	a2,a5,80005044 <log_write+0x76>
  }
  release(&log.lock);
    80005096:	00020517          	auipc	a0,0x20
    8000509a:	d3a50513          	add	a0,a0,-710 # 80024dd0 <log>
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	be8080e7          	jalr	-1048(ra) # 80000c86 <release>
}
    800050a6:	60e2                	ld	ra,24(sp)
    800050a8:	6442                	ld	s0,16(sp)
    800050aa:	64a2                	ld	s1,8(sp)
    800050ac:	6902                	ld	s2,0(sp)
    800050ae:	6105                	add	sp,sp,32
    800050b0:	8082                	ret

00000000800050b2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800050b2:	1101                	add	sp,sp,-32
    800050b4:	ec06                	sd	ra,24(sp)
    800050b6:	e822                	sd	s0,16(sp)
    800050b8:	e426                	sd	s1,8(sp)
    800050ba:	e04a                	sd	s2,0(sp)
    800050bc:	1000                	add	s0,sp,32
    800050be:	84aa                	mv	s1,a0
    800050c0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800050c2:	00003597          	auipc	a1,0x3
    800050c6:	6a658593          	add	a1,a1,1702 # 80008768 <syscalls+0x270>
    800050ca:	0521                	add	a0,a0,8
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	a76080e7          	jalr	-1418(ra) # 80000b42 <initlock>
  lk->name = name;
    800050d4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800050d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800050dc:	0204a423          	sw	zero,40(s1)
}
    800050e0:	60e2                	ld	ra,24(sp)
    800050e2:	6442                	ld	s0,16(sp)
    800050e4:	64a2                	ld	s1,8(sp)
    800050e6:	6902                	ld	s2,0(sp)
    800050e8:	6105                	add	sp,sp,32
    800050ea:	8082                	ret

00000000800050ec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800050ec:	1101                	add	sp,sp,-32
    800050ee:	ec06                	sd	ra,24(sp)
    800050f0:	e822                	sd	s0,16(sp)
    800050f2:	e426                	sd	s1,8(sp)
    800050f4:	e04a                	sd	s2,0(sp)
    800050f6:	1000                	add	s0,sp,32
    800050f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050fa:	00850913          	add	s2,a0,8
    800050fe:	854a                	mv	a0,s2
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	ad2080e7          	jalr	-1326(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80005108:	409c                	lw	a5,0(s1)
    8000510a:	cb89                	beqz	a5,8000511c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000510c:	85ca                	mv	a1,s2
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffd097          	auipc	ra,0xffffd
    80005114:	632080e7          	jalr	1586(ra) # 80002742 <sleep>
  while (lk->locked) {
    80005118:	409c                	lw	a5,0(s1)
    8000511a:	fbed                	bnez	a5,8000510c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000511c:	4785                	li	a5,1
    8000511e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	896080e7          	jalr	-1898(ra) # 800019b6 <myproc>
    80005128:	591c                	lw	a5,48(a0)
    8000512a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000512c:	854a                	mv	a0,s2
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	b58080e7          	jalr	-1192(ra) # 80000c86 <release>
}
    80005136:	60e2                	ld	ra,24(sp)
    80005138:	6442                	ld	s0,16(sp)
    8000513a:	64a2                	ld	s1,8(sp)
    8000513c:	6902                	ld	s2,0(sp)
    8000513e:	6105                	add	sp,sp,32
    80005140:	8082                	ret

0000000080005142 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005142:	1101                	add	sp,sp,-32
    80005144:	ec06                	sd	ra,24(sp)
    80005146:	e822                	sd	s0,16(sp)
    80005148:	e426                	sd	s1,8(sp)
    8000514a:	e04a                	sd	s2,0(sp)
    8000514c:	1000                	add	s0,sp,32
    8000514e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005150:	00850913          	add	s2,a0,8
    80005154:	854a                	mv	a0,s2
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	a7c080e7          	jalr	-1412(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    8000515e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005162:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	63e080e7          	jalr	1598(ra) # 800027a6 <wakeup>
  release(&lk->lk);
    80005170:	854a                	mv	a0,s2
    80005172:	ffffc097          	auipc	ra,0xffffc
    80005176:	b14080e7          	jalr	-1260(ra) # 80000c86 <release>
}
    8000517a:	60e2                	ld	ra,24(sp)
    8000517c:	6442                	ld	s0,16(sp)
    8000517e:	64a2                	ld	s1,8(sp)
    80005180:	6902                	ld	s2,0(sp)
    80005182:	6105                	add	sp,sp,32
    80005184:	8082                	ret

0000000080005186 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005186:	7179                	add	sp,sp,-48
    80005188:	f406                	sd	ra,40(sp)
    8000518a:	f022                	sd	s0,32(sp)
    8000518c:	ec26                	sd	s1,24(sp)
    8000518e:	e84a                	sd	s2,16(sp)
    80005190:	e44e                	sd	s3,8(sp)
    80005192:	1800                	add	s0,sp,48
    80005194:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005196:	00850913          	add	s2,a0,8
    8000519a:	854a                	mv	a0,s2
    8000519c:	ffffc097          	auipc	ra,0xffffc
    800051a0:	a36080e7          	jalr	-1482(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800051a4:	409c                	lw	a5,0(s1)
    800051a6:	ef99                	bnez	a5,800051c4 <holdingsleep+0x3e>
    800051a8:	4481                	li	s1,0
  release(&lk->lk);
    800051aa:	854a                	mv	a0,s2
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	ada080e7          	jalr	-1318(ra) # 80000c86 <release>
  return r;
}
    800051b4:	8526                	mv	a0,s1
    800051b6:	70a2                	ld	ra,40(sp)
    800051b8:	7402                	ld	s0,32(sp)
    800051ba:	64e2                	ld	s1,24(sp)
    800051bc:	6942                	ld	s2,16(sp)
    800051be:	69a2                	ld	s3,8(sp)
    800051c0:	6145                	add	sp,sp,48
    800051c2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800051c4:	0284a983          	lw	s3,40(s1)
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	7ee080e7          	jalr	2030(ra) # 800019b6 <myproc>
    800051d0:	5904                	lw	s1,48(a0)
    800051d2:	413484b3          	sub	s1,s1,s3
    800051d6:	0014b493          	seqz	s1,s1
    800051da:	bfc1                	j	800051aa <holdingsleep+0x24>

00000000800051dc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800051dc:	1141                	add	sp,sp,-16
    800051de:	e406                	sd	ra,8(sp)
    800051e0:	e022                	sd	s0,0(sp)
    800051e2:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800051e4:	00003597          	auipc	a1,0x3
    800051e8:	59458593          	add	a1,a1,1428 # 80008778 <syscalls+0x280>
    800051ec:	00020517          	auipc	a0,0x20
    800051f0:	d2c50513          	add	a0,a0,-724 # 80024f18 <ftable>
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	94e080e7          	jalr	-1714(ra) # 80000b42 <initlock>
}
    800051fc:	60a2                	ld	ra,8(sp)
    800051fe:	6402                	ld	s0,0(sp)
    80005200:	0141                	add	sp,sp,16
    80005202:	8082                	ret

0000000080005204 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005204:	1101                	add	sp,sp,-32
    80005206:	ec06                	sd	ra,24(sp)
    80005208:	e822                	sd	s0,16(sp)
    8000520a:	e426                	sd	s1,8(sp)
    8000520c:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000520e:	00020517          	auipc	a0,0x20
    80005212:	d0a50513          	add	a0,a0,-758 # 80024f18 <ftable>
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	9bc080e7          	jalr	-1604(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000521e:	00020497          	auipc	s1,0x20
    80005222:	d1248493          	add	s1,s1,-750 # 80024f30 <ftable+0x18>
    80005226:	00021717          	auipc	a4,0x21
    8000522a:	caa70713          	add	a4,a4,-854 # 80025ed0 <disk>
    if(f->ref == 0){
    8000522e:	40dc                	lw	a5,4(s1)
    80005230:	cf99                	beqz	a5,8000524e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005232:	02848493          	add	s1,s1,40
    80005236:	fee49ce3          	bne	s1,a4,8000522e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000523a:	00020517          	auipc	a0,0x20
    8000523e:	cde50513          	add	a0,a0,-802 # 80024f18 <ftable>
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	a44080e7          	jalr	-1468(ra) # 80000c86 <release>
  return 0;
    8000524a:	4481                	li	s1,0
    8000524c:	a819                	j	80005262 <filealloc+0x5e>
      f->ref = 1;
    8000524e:	4785                	li	a5,1
    80005250:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005252:	00020517          	auipc	a0,0x20
    80005256:	cc650513          	add	a0,a0,-826 # 80024f18 <ftable>
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	a2c080e7          	jalr	-1492(ra) # 80000c86 <release>
}
    80005262:	8526                	mv	a0,s1
    80005264:	60e2                	ld	ra,24(sp)
    80005266:	6442                	ld	s0,16(sp)
    80005268:	64a2                	ld	s1,8(sp)
    8000526a:	6105                	add	sp,sp,32
    8000526c:	8082                	ret

000000008000526e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000526e:	1101                	add	sp,sp,-32
    80005270:	ec06                	sd	ra,24(sp)
    80005272:	e822                	sd	s0,16(sp)
    80005274:	e426                	sd	s1,8(sp)
    80005276:	1000                	add	s0,sp,32
    80005278:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000527a:	00020517          	auipc	a0,0x20
    8000527e:	c9e50513          	add	a0,a0,-866 # 80024f18 <ftable>
    80005282:	ffffc097          	auipc	ra,0xffffc
    80005286:	950080e7          	jalr	-1712(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000528a:	40dc                	lw	a5,4(s1)
    8000528c:	02f05263          	blez	a5,800052b0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005290:	2785                	addw	a5,a5,1
    80005292:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005294:	00020517          	auipc	a0,0x20
    80005298:	c8450513          	add	a0,a0,-892 # 80024f18 <ftable>
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	9ea080e7          	jalr	-1558(ra) # 80000c86 <release>
  return f;
}
    800052a4:	8526                	mv	a0,s1
    800052a6:	60e2                	ld	ra,24(sp)
    800052a8:	6442                	ld	s0,16(sp)
    800052aa:	64a2                	ld	s1,8(sp)
    800052ac:	6105                	add	sp,sp,32
    800052ae:	8082                	ret
    panic("filedup");
    800052b0:	00003517          	auipc	a0,0x3
    800052b4:	4d050513          	add	a0,a0,1232 # 80008780 <syscalls+0x288>
    800052b8:	ffffb097          	auipc	ra,0xffffb
    800052bc:	284080e7          	jalr	644(ra) # 8000053c <panic>

00000000800052c0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800052c0:	7139                	add	sp,sp,-64
    800052c2:	fc06                	sd	ra,56(sp)
    800052c4:	f822                	sd	s0,48(sp)
    800052c6:	f426                	sd	s1,40(sp)
    800052c8:	f04a                	sd	s2,32(sp)
    800052ca:	ec4e                	sd	s3,24(sp)
    800052cc:	e852                	sd	s4,16(sp)
    800052ce:	e456                	sd	s5,8(sp)
    800052d0:	0080                	add	s0,sp,64
    800052d2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800052d4:	00020517          	auipc	a0,0x20
    800052d8:	c4450513          	add	a0,a0,-956 # 80024f18 <ftable>
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	8f6080e7          	jalr	-1802(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800052e4:	40dc                	lw	a5,4(s1)
    800052e6:	06f05163          	blez	a5,80005348 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800052ea:	37fd                	addw	a5,a5,-1
    800052ec:	0007871b          	sext.w	a4,a5
    800052f0:	c0dc                	sw	a5,4(s1)
    800052f2:	06e04363          	bgtz	a4,80005358 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800052f6:	0004a903          	lw	s2,0(s1)
    800052fa:	0094ca83          	lbu	s5,9(s1)
    800052fe:	0104ba03          	ld	s4,16(s1)
    80005302:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005306:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000530a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000530e:	00020517          	auipc	a0,0x20
    80005312:	c0a50513          	add	a0,a0,-1014 # 80024f18 <ftable>
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	970080e7          	jalr	-1680(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000531e:	4785                	li	a5,1
    80005320:	04f90d63          	beq	s2,a5,8000537a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005324:	3979                	addw	s2,s2,-2
    80005326:	4785                	li	a5,1
    80005328:	0527e063          	bltu	a5,s2,80005368 <fileclose+0xa8>
    begin_op();
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	ad0080e7          	jalr	-1328(ra) # 80004dfc <begin_op>
    iput(ff.ip);
    80005334:	854e                	mv	a0,s3
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	2da080e7          	jalr	730(ra) # 80004610 <iput>
    end_op();
    8000533e:	00000097          	auipc	ra,0x0
    80005342:	b38080e7          	jalr	-1224(ra) # 80004e76 <end_op>
    80005346:	a00d                	j	80005368 <fileclose+0xa8>
    panic("fileclose");
    80005348:	00003517          	auipc	a0,0x3
    8000534c:	44050513          	add	a0,a0,1088 # 80008788 <syscalls+0x290>
    80005350:	ffffb097          	auipc	ra,0xffffb
    80005354:	1ec080e7          	jalr	492(ra) # 8000053c <panic>
    release(&ftable.lock);
    80005358:	00020517          	auipc	a0,0x20
    8000535c:	bc050513          	add	a0,a0,-1088 # 80024f18 <ftable>
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	926080e7          	jalr	-1754(ra) # 80000c86 <release>
  }
}
    80005368:	70e2                	ld	ra,56(sp)
    8000536a:	7442                	ld	s0,48(sp)
    8000536c:	74a2                	ld	s1,40(sp)
    8000536e:	7902                	ld	s2,32(sp)
    80005370:	69e2                	ld	s3,24(sp)
    80005372:	6a42                	ld	s4,16(sp)
    80005374:	6aa2                	ld	s5,8(sp)
    80005376:	6121                	add	sp,sp,64
    80005378:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000537a:	85d6                	mv	a1,s5
    8000537c:	8552                	mv	a0,s4
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	348080e7          	jalr	840(ra) # 800056c6 <pipeclose>
    80005386:	b7cd                	j	80005368 <fileclose+0xa8>

0000000080005388 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005388:	715d                	add	sp,sp,-80
    8000538a:	e486                	sd	ra,72(sp)
    8000538c:	e0a2                	sd	s0,64(sp)
    8000538e:	fc26                	sd	s1,56(sp)
    80005390:	f84a                	sd	s2,48(sp)
    80005392:	f44e                	sd	s3,40(sp)
    80005394:	0880                	add	s0,sp,80
    80005396:	84aa                	mv	s1,a0
    80005398:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000539a:	ffffc097          	auipc	ra,0xffffc
    8000539e:	61c080e7          	jalr	1564(ra) # 800019b6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800053a2:	409c                	lw	a5,0(s1)
    800053a4:	37f9                	addw	a5,a5,-2
    800053a6:	4705                	li	a4,1
    800053a8:	04f76763          	bltu	a4,a5,800053f6 <filestat+0x6e>
    800053ac:	892a                	mv	s2,a0
    ilock(f->ip);
    800053ae:	6c88                	ld	a0,24(s1)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	0a6080e7          	jalr	166(ra) # 80004456 <ilock>
    stati(f->ip, &st);
    800053b8:	fb840593          	add	a1,s0,-72
    800053bc:	6c88                	ld	a0,24(s1)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	322080e7          	jalr	802(ra) # 800046e0 <stati>
    iunlock(f->ip);
    800053c6:	6c88                	ld	a0,24(s1)
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	150080e7          	jalr	336(ra) # 80004518 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800053d0:	46e1                	li	a3,24
    800053d2:	fb840613          	add	a2,s0,-72
    800053d6:	85ce                	mv	a1,s3
    800053d8:	05093503          	ld	a0,80(s2)
    800053dc:	ffffc097          	auipc	ra,0xffffc
    800053e0:	28a080e7          	jalr	650(ra) # 80001666 <copyout>
    800053e4:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800053e8:	60a6                	ld	ra,72(sp)
    800053ea:	6406                	ld	s0,64(sp)
    800053ec:	74e2                	ld	s1,56(sp)
    800053ee:	7942                	ld	s2,48(sp)
    800053f0:	79a2                	ld	s3,40(sp)
    800053f2:	6161                	add	sp,sp,80
    800053f4:	8082                	ret
  return -1;
    800053f6:	557d                	li	a0,-1
    800053f8:	bfc5                	j	800053e8 <filestat+0x60>

00000000800053fa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800053fa:	7179                	add	sp,sp,-48
    800053fc:	f406                	sd	ra,40(sp)
    800053fe:	f022                	sd	s0,32(sp)
    80005400:	ec26                	sd	s1,24(sp)
    80005402:	e84a                	sd	s2,16(sp)
    80005404:	e44e                	sd	s3,8(sp)
    80005406:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005408:	00854783          	lbu	a5,8(a0)
    8000540c:	c3d5                	beqz	a5,800054b0 <fileread+0xb6>
    8000540e:	84aa                	mv	s1,a0
    80005410:	89ae                	mv	s3,a1
    80005412:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005414:	411c                	lw	a5,0(a0)
    80005416:	4705                	li	a4,1
    80005418:	04e78963          	beq	a5,a4,8000546a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000541c:	470d                	li	a4,3
    8000541e:	04e78d63          	beq	a5,a4,80005478 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005422:	4709                	li	a4,2
    80005424:	06e79e63          	bne	a5,a4,800054a0 <fileread+0xa6>
    ilock(f->ip);
    80005428:	6d08                	ld	a0,24(a0)
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	02c080e7          	jalr	44(ra) # 80004456 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005432:	874a                	mv	a4,s2
    80005434:	5094                	lw	a3,32(s1)
    80005436:	864e                	mv	a2,s3
    80005438:	4585                	li	a1,1
    8000543a:	6c88                	ld	a0,24(s1)
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	2ce080e7          	jalr	718(ra) # 8000470a <readi>
    80005444:	892a                	mv	s2,a0
    80005446:	00a05563          	blez	a0,80005450 <fileread+0x56>
      f->off += r;
    8000544a:	509c                	lw	a5,32(s1)
    8000544c:	9fa9                	addw	a5,a5,a0
    8000544e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005450:	6c88                	ld	a0,24(s1)
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	0c6080e7          	jalr	198(ra) # 80004518 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000545a:	854a                	mv	a0,s2
    8000545c:	70a2                	ld	ra,40(sp)
    8000545e:	7402                	ld	s0,32(sp)
    80005460:	64e2                	ld	s1,24(sp)
    80005462:	6942                	ld	s2,16(sp)
    80005464:	69a2                	ld	s3,8(sp)
    80005466:	6145                	add	sp,sp,48
    80005468:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000546a:	6908                	ld	a0,16(a0)
    8000546c:	00000097          	auipc	ra,0x0
    80005470:	3c2080e7          	jalr	962(ra) # 8000582e <piperead>
    80005474:	892a                	mv	s2,a0
    80005476:	b7d5                	j	8000545a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005478:	02451783          	lh	a5,36(a0)
    8000547c:	03079693          	sll	a3,a5,0x30
    80005480:	92c1                	srl	a3,a3,0x30
    80005482:	4725                	li	a4,9
    80005484:	02d76863          	bltu	a4,a3,800054b4 <fileread+0xba>
    80005488:	0792                	sll	a5,a5,0x4
    8000548a:	00020717          	auipc	a4,0x20
    8000548e:	9ee70713          	add	a4,a4,-1554 # 80024e78 <devsw>
    80005492:	97ba                	add	a5,a5,a4
    80005494:	639c                	ld	a5,0(a5)
    80005496:	c38d                	beqz	a5,800054b8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005498:	4505                	li	a0,1
    8000549a:	9782                	jalr	a5
    8000549c:	892a                	mv	s2,a0
    8000549e:	bf75                	j	8000545a <fileread+0x60>
    panic("fileread");
    800054a0:	00003517          	auipc	a0,0x3
    800054a4:	2f850513          	add	a0,a0,760 # 80008798 <syscalls+0x2a0>
    800054a8:	ffffb097          	auipc	ra,0xffffb
    800054ac:	094080e7          	jalr	148(ra) # 8000053c <panic>
    return -1;
    800054b0:	597d                	li	s2,-1
    800054b2:	b765                	j	8000545a <fileread+0x60>
      return -1;
    800054b4:	597d                	li	s2,-1
    800054b6:	b755                	j	8000545a <fileread+0x60>
    800054b8:	597d                	li	s2,-1
    800054ba:	b745                	j	8000545a <fileread+0x60>

00000000800054bc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800054bc:	00954783          	lbu	a5,9(a0)
    800054c0:	10078e63          	beqz	a5,800055dc <filewrite+0x120>
{
    800054c4:	715d                	add	sp,sp,-80
    800054c6:	e486                	sd	ra,72(sp)
    800054c8:	e0a2                	sd	s0,64(sp)
    800054ca:	fc26                	sd	s1,56(sp)
    800054cc:	f84a                	sd	s2,48(sp)
    800054ce:	f44e                	sd	s3,40(sp)
    800054d0:	f052                	sd	s4,32(sp)
    800054d2:	ec56                	sd	s5,24(sp)
    800054d4:	e85a                	sd	s6,16(sp)
    800054d6:	e45e                	sd	s7,8(sp)
    800054d8:	e062                	sd	s8,0(sp)
    800054da:	0880                	add	s0,sp,80
    800054dc:	892a                	mv	s2,a0
    800054de:	8b2e                	mv	s6,a1
    800054e0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800054e2:	411c                	lw	a5,0(a0)
    800054e4:	4705                	li	a4,1
    800054e6:	02e78263          	beq	a5,a4,8000550a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054ea:	470d                	li	a4,3
    800054ec:	02e78563          	beq	a5,a4,80005516 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800054f0:	4709                	li	a4,2
    800054f2:	0ce79d63          	bne	a5,a4,800055cc <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800054f6:	0ac05b63          	blez	a2,800055ac <filewrite+0xf0>
    int i = 0;
    800054fa:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800054fc:	6b85                	lui	s7,0x1
    800054fe:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005502:	6c05                	lui	s8,0x1
    80005504:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005508:	a851                	j	8000559c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000550a:	6908                	ld	a0,16(a0)
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	22a080e7          	jalr	554(ra) # 80005736 <pipewrite>
    80005514:	a045                	j	800055b4 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005516:	02451783          	lh	a5,36(a0)
    8000551a:	03079693          	sll	a3,a5,0x30
    8000551e:	92c1                	srl	a3,a3,0x30
    80005520:	4725                	li	a4,9
    80005522:	0ad76f63          	bltu	a4,a3,800055e0 <filewrite+0x124>
    80005526:	0792                	sll	a5,a5,0x4
    80005528:	00020717          	auipc	a4,0x20
    8000552c:	95070713          	add	a4,a4,-1712 # 80024e78 <devsw>
    80005530:	97ba                	add	a5,a5,a4
    80005532:	679c                	ld	a5,8(a5)
    80005534:	cbc5                	beqz	a5,800055e4 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80005536:	4505                	li	a0,1
    80005538:	9782                	jalr	a5
    8000553a:	a8ad                	j	800055b4 <filewrite+0xf8>
      if(n1 > max)
    8000553c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80005540:	00000097          	auipc	ra,0x0
    80005544:	8bc080e7          	jalr	-1860(ra) # 80004dfc <begin_op>
      ilock(f->ip);
    80005548:	01893503          	ld	a0,24(s2)
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	f0a080e7          	jalr	-246(ra) # 80004456 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005554:	8756                	mv	a4,s5
    80005556:	02092683          	lw	a3,32(s2)
    8000555a:	01698633          	add	a2,s3,s6
    8000555e:	4585                	li	a1,1
    80005560:	01893503          	ld	a0,24(s2)
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	29e080e7          	jalr	670(ra) # 80004802 <writei>
    8000556c:	84aa                	mv	s1,a0
    8000556e:	00a05763          	blez	a0,8000557c <filewrite+0xc0>
        f->off += r;
    80005572:	02092783          	lw	a5,32(s2)
    80005576:	9fa9                	addw	a5,a5,a0
    80005578:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000557c:	01893503          	ld	a0,24(s2)
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	f98080e7          	jalr	-104(ra) # 80004518 <iunlock>
      end_op();
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	8ee080e7          	jalr	-1810(ra) # 80004e76 <end_op>

      if(r != n1){
    80005590:	009a9f63          	bne	s5,s1,800055ae <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80005594:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005598:	0149db63          	bge	s3,s4,800055ae <filewrite+0xf2>
      int n1 = n - i;
    8000559c:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800055a0:	0004879b          	sext.w	a5,s1
    800055a4:	f8fbdce3          	bge	s7,a5,8000553c <filewrite+0x80>
    800055a8:	84e2                	mv	s1,s8
    800055aa:	bf49                	j	8000553c <filewrite+0x80>
    int i = 0;
    800055ac:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800055ae:	033a1d63          	bne	s4,s3,800055e8 <filewrite+0x12c>
    800055b2:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800055b4:	60a6                	ld	ra,72(sp)
    800055b6:	6406                	ld	s0,64(sp)
    800055b8:	74e2                	ld	s1,56(sp)
    800055ba:	7942                	ld	s2,48(sp)
    800055bc:	79a2                	ld	s3,40(sp)
    800055be:	7a02                	ld	s4,32(sp)
    800055c0:	6ae2                	ld	s5,24(sp)
    800055c2:	6b42                	ld	s6,16(sp)
    800055c4:	6ba2                	ld	s7,8(sp)
    800055c6:	6c02                	ld	s8,0(sp)
    800055c8:	6161                	add	sp,sp,80
    800055ca:	8082                	ret
    panic("filewrite");
    800055cc:	00003517          	auipc	a0,0x3
    800055d0:	1dc50513          	add	a0,a0,476 # 800087a8 <syscalls+0x2b0>
    800055d4:	ffffb097          	auipc	ra,0xffffb
    800055d8:	f68080e7          	jalr	-152(ra) # 8000053c <panic>
    return -1;
    800055dc:	557d                	li	a0,-1
}
    800055de:	8082                	ret
      return -1;
    800055e0:	557d                	li	a0,-1
    800055e2:	bfc9                	j	800055b4 <filewrite+0xf8>
    800055e4:	557d                	li	a0,-1
    800055e6:	b7f9                	j	800055b4 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800055e8:	557d                	li	a0,-1
    800055ea:	b7e9                	j	800055b4 <filewrite+0xf8>

00000000800055ec <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800055ec:	7179                	add	sp,sp,-48
    800055ee:	f406                	sd	ra,40(sp)
    800055f0:	f022                	sd	s0,32(sp)
    800055f2:	ec26                	sd	s1,24(sp)
    800055f4:	e84a                	sd	s2,16(sp)
    800055f6:	e44e                	sd	s3,8(sp)
    800055f8:	e052                	sd	s4,0(sp)
    800055fa:	1800                	add	s0,sp,48
    800055fc:	84aa                	mv	s1,a0
    800055fe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005600:	0005b023          	sd	zero,0(a1)
    80005604:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	bfc080e7          	jalr	-1028(ra) # 80005204 <filealloc>
    80005610:	e088                	sd	a0,0(s1)
    80005612:	c551                	beqz	a0,8000569e <pipealloc+0xb2>
    80005614:	00000097          	auipc	ra,0x0
    80005618:	bf0080e7          	jalr	-1040(ra) # 80005204 <filealloc>
    8000561c:	00aa3023          	sd	a0,0(s4)
    80005620:	c92d                	beqz	a0,80005692 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	4c0080e7          	jalr	1216(ra) # 80000ae2 <kalloc>
    8000562a:	892a                	mv	s2,a0
    8000562c:	c125                	beqz	a0,8000568c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000562e:	4985                	li	s3,1
    80005630:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005634:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005638:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000563c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005640:	00003597          	auipc	a1,0x3
    80005644:	17858593          	add	a1,a1,376 # 800087b8 <syscalls+0x2c0>
    80005648:	ffffb097          	auipc	ra,0xffffb
    8000564c:	4fa080e7          	jalr	1274(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80005650:	609c                	ld	a5,0(s1)
    80005652:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005656:	609c                	ld	a5,0(s1)
    80005658:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000565c:	609c                	ld	a5,0(s1)
    8000565e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005662:	609c                	ld	a5,0(s1)
    80005664:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005668:	000a3783          	ld	a5,0(s4)
    8000566c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005670:	000a3783          	ld	a5,0(s4)
    80005674:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005678:	000a3783          	ld	a5,0(s4)
    8000567c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005680:	000a3783          	ld	a5,0(s4)
    80005684:	0127b823          	sd	s2,16(a5)
  return 0;
    80005688:	4501                	li	a0,0
    8000568a:	a025                	j	800056b2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000568c:	6088                	ld	a0,0(s1)
    8000568e:	e501                	bnez	a0,80005696 <pipealloc+0xaa>
    80005690:	a039                	j	8000569e <pipealloc+0xb2>
    80005692:	6088                	ld	a0,0(s1)
    80005694:	c51d                	beqz	a0,800056c2 <pipealloc+0xd6>
    fileclose(*f0);
    80005696:	00000097          	auipc	ra,0x0
    8000569a:	c2a080e7          	jalr	-982(ra) # 800052c0 <fileclose>
  if(*f1)
    8000569e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800056a2:	557d                	li	a0,-1
  if(*f1)
    800056a4:	c799                	beqz	a5,800056b2 <pipealloc+0xc6>
    fileclose(*f1);
    800056a6:	853e                	mv	a0,a5
    800056a8:	00000097          	auipc	ra,0x0
    800056ac:	c18080e7          	jalr	-1000(ra) # 800052c0 <fileclose>
  return -1;
    800056b0:	557d                	li	a0,-1
}
    800056b2:	70a2                	ld	ra,40(sp)
    800056b4:	7402                	ld	s0,32(sp)
    800056b6:	64e2                	ld	s1,24(sp)
    800056b8:	6942                	ld	s2,16(sp)
    800056ba:	69a2                	ld	s3,8(sp)
    800056bc:	6a02                	ld	s4,0(sp)
    800056be:	6145                	add	sp,sp,48
    800056c0:	8082                	ret
  return -1;
    800056c2:	557d                	li	a0,-1
    800056c4:	b7fd                	j	800056b2 <pipealloc+0xc6>

00000000800056c6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800056c6:	1101                	add	sp,sp,-32
    800056c8:	ec06                	sd	ra,24(sp)
    800056ca:	e822                	sd	s0,16(sp)
    800056cc:	e426                	sd	s1,8(sp)
    800056ce:	e04a                	sd	s2,0(sp)
    800056d0:	1000                	add	s0,sp,32
    800056d2:	84aa                	mv	s1,a0
    800056d4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800056d6:	ffffb097          	auipc	ra,0xffffb
    800056da:	4fc080e7          	jalr	1276(ra) # 80000bd2 <acquire>
  if(writable){
    800056de:	02090d63          	beqz	s2,80005718 <pipeclose+0x52>
    pi->writeopen = 0;
    800056e2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800056e6:	21848513          	add	a0,s1,536
    800056ea:	ffffd097          	auipc	ra,0xffffd
    800056ee:	0bc080e7          	jalr	188(ra) # 800027a6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800056f2:	2204b783          	ld	a5,544(s1)
    800056f6:	eb95                	bnez	a5,8000572a <pipeclose+0x64>
    release(&pi->lock);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	58c080e7          	jalr	1420(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	2e0080e7          	jalr	736(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    8000570c:	60e2                	ld	ra,24(sp)
    8000570e:	6442                	ld	s0,16(sp)
    80005710:	64a2                	ld	s1,8(sp)
    80005712:	6902                	ld	s2,0(sp)
    80005714:	6105                	add	sp,sp,32
    80005716:	8082                	ret
    pi->readopen = 0;
    80005718:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000571c:	21c48513          	add	a0,s1,540
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	086080e7          	jalr	134(ra) # 800027a6 <wakeup>
    80005728:	b7e9                	j	800056f2 <pipeclose+0x2c>
    release(&pi->lock);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	55a080e7          	jalr	1370(ra) # 80000c86 <release>
}
    80005734:	bfe1                	j	8000570c <pipeclose+0x46>

0000000080005736 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005736:	711d                	add	sp,sp,-96
    80005738:	ec86                	sd	ra,88(sp)
    8000573a:	e8a2                	sd	s0,80(sp)
    8000573c:	e4a6                	sd	s1,72(sp)
    8000573e:	e0ca                	sd	s2,64(sp)
    80005740:	fc4e                	sd	s3,56(sp)
    80005742:	f852                	sd	s4,48(sp)
    80005744:	f456                	sd	s5,40(sp)
    80005746:	f05a                	sd	s6,32(sp)
    80005748:	ec5e                	sd	s7,24(sp)
    8000574a:	e862                	sd	s8,16(sp)
    8000574c:	1080                	add	s0,sp,96
    8000574e:	84aa                	mv	s1,a0
    80005750:	8aae                	mv	s5,a1
    80005752:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005754:	ffffc097          	auipc	ra,0xffffc
    80005758:	262080e7          	jalr	610(ra) # 800019b6 <myproc>
    8000575c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffb097          	auipc	ra,0xffffb
    80005764:	472080e7          	jalr	1138(ra) # 80000bd2 <acquire>
  while(i < n){
    80005768:	0b405663          	blez	s4,80005814 <pipewrite+0xde>
  int i = 0;
    8000576c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000576e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005770:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005774:	21c48b93          	add	s7,s1,540
    80005778:	a089                	j	800057ba <pipewrite+0x84>
      release(&pi->lock);
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	50a080e7          	jalr	1290(ra) # 80000c86 <release>
      return -1;
    80005784:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005786:	854a                	mv	a0,s2
    80005788:	60e6                	ld	ra,88(sp)
    8000578a:	6446                	ld	s0,80(sp)
    8000578c:	64a6                	ld	s1,72(sp)
    8000578e:	6906                	ld	s2,64(sp)
    80005790:	79e2                	ld	s3,56(sp)
    80005792:	7a42                	ld	s4,48(sp)
    80005794:	7aa2                	ld	s5,40(sp)
    80005796:	7b02                	ld	s6,32(sp)
    80005798:	6be2                	ld	s7,24(sp)
    8000579a:	6c42                	ld	s8,16(sp)
    8000579c:	6125                	add	sp,sp,96
    8000579e:	8082                	ret
      wakeup(&pi->nread);
    800057a0:	8562                	mv	a0,s8
    800057a2:	ffffd097          	auipc	ra,0xffffd
    800057a6:	004080e7          	jalr	4(ra) # 800027a6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800057aa:	85a6                	mv	a1,s1
    800057ac:	855e                	mv	a0,s7
    800057ae:	ffffd097          	auipc	ra,0xffffd
    800057b2:	f94080e7          	jalr	-108(ra) # 80002742 <sleep>
  while(i < n){
    800057b6:	07495063          	bge	s2,s4,80005816 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800057ba:	2204a783          	lw	a5,544(s1)
    800057be:	dfd5                	beqz	a5,8000577a <pipewrite+0x44>
    800057c0:	854e                	mv	a0,s3
    800057c2:	ffffd097          	auipc	ra,0xffffd
    800057c6:	234080e7          	jalr	564(ra) # 800029f6 <killed>
    800057ca:	f945                	bnez	a0,8000577a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800057cc:	2184a783          	lw	a5,536(s1)
    800057d0:	21c4a703          	lw	a4,540(s1)
    800057d4:	2007879b          	addw	a5,a5,512
    800057d8:	fcf704e3          	beq	a4,a5,800057a0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057dc:	4685                	li	a3,1
    800057de:	01590633          	add	a2,s2,s5
    800057e2:	faf40593          	add	a1,s0,-81
    800057e6:	0509b503          	ld	a0,80(s3)
    800057ea:	ffffc097          	auipc	ra,0xffffc
    800057ee:	f08080e7          	jalr	-248(ra) # 800016f2 <copyin>
    800057f2:	03650263          	beq	a0,s6,80005816 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800057f6:	21c4a783          	lw	a5,540(s1)
    800057fa:	0017871b          	addw	a4,a5,1
    800057fe:	20e4ae23          	sw	a4,540(s1)
    80005802:	1ff7f793          	and	a5,a5,511
    80005806:	97a6                	add	a5,a5,s1
    80005808:	faf44703          	lbu	a4,-81(s0)
    8000580c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005810:	2905                	addw	s2,s2,1
    80005812:	b755                	j	800057b6 <pipewrite+0x80>
  int i = 0;
    80005814:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005816:	21848513          	add	a0,s1,536
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	f8c080e7          	jalr	-116(ra) # 800027a6 <wakeup>
  release(&pi->lock);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffb097          	auipc	ra,0xffffb
    80005828:	462080e7          	jalr	1122(ra) # 80000c86 <release>
  return i;
    8000582c:	bfa9                	j	80005786 <pipewrite+0x50>

000000008000582e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000582e:	715d                	add	sp,sp,-80
    80005830:	e486                	sd	ra,72(sp)
    80005832:	e0a2                	sd	s0,64(sp)
    80005834:	fc26                	sd	s1,56(sp)
    80005836:	f84a                	sd	s2,48(sp)
    80005838:	f44e                	sd	s3,40(sp)
    8000583a:	f052                	sd	s4,32(sp)
    8000583c:	ec56                	sd	s5,24(sp)
    8000583e:	e85a                	sd	s6,16(sp)
    80005840:	0880                	add	s0,sp,80
    80005842:	84aa                	mv	s1,a0
    80005844:	892e                	mv	s2,a1
    80005846:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005848:	ffffc097          	auipc	ra,0xffffc
    8000584c:	16e080e7          	jalr	366(ra) # 800019b6 <myproc>
    80005850:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffb097          	auipc	ra,0xffffb
    80005858:	37e080e7          	jalr	894(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000585c:	2184a703          	lw	a4,536(s1)
    80005860:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005864:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005868:	02f71763          	bne	a4,a5,80005896 <piperead+0x68>
    8000586c:	2244a783          	lw	a5,548(s1)
    80005870:	c39d                	beqz	a5,80005896 <piperead+0x68>
    if(killed(pr)){
    80005872:	8552                	mv	a0,s4
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	182080e7          	jalr	386(ra) # 800029f6 <killed>
    8000587c:	e949                	bnez	a0,8000590e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000587e:	85a6                	mv	a1,s1
    80005880:	854e                	mv	a0,s3
    80005882:	ffffd097          	auipc	ra,0xffffd
    80005886:	ec0080e7          	jalr	-320(ra) # 80002742 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000588a:	2184a703          	lw	a4,536(s1)
    8000588e:	21c4a783          	lw	a5,540(s1)
    80005892:	fcf70de3          	beq	a4,a5,8000586c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005896:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005898:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000589a:	05505463          	blez	s5,800058e2 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000589e:	2184a783          	lw	a5,536(s1)
    800058a2:	21c4a703          	lw	a4,540(s1)
    800058a6:	02f70e63          	beq	a4,a5,800058e2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800058aa:	0017871b          	addw	a4,a5,1
    800058ae:	20e4ac23          	sw	a4,536(s1)
    800058b2:	1ff7f793          	and	a5,a5,511
    800058b6:	97a6                	add	a5,a5,s1
    800058b8:	0187c783          	lbu	a5,24(a5)
    800058bc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800058c0:	4685                	li	a3,1
    800058c2:	fbf40613          	add	a2,s0,-65
    800058c6:	85ca                	mv	a1,s2
    800058c8:	050a3503          	ld	a0,80(s4)
    800058cc:	ffffc097          	auipc	ra,0xffffc
    800058d0:	d9a080e7          	jalr	-614(ra) # 80001666 <copyout>
    800058d4:	01650763          	beq	a0,s6,800058e2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058d8:	2985                	addw	s3,s3,1
    800058da:	0905                	add	s2,s2,1
    800058dc:	fd3a91e3          	bne	s5,s3,8000589e <piperead+0x70>
    800058e0:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800058e2:	21c48513          	add	a0,s1,540
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	ec0080e7          	jalr	-320(ra) # 800027a6 <wakeup>
  release(&pi->lock);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	396080e7          	jalr	918(ra) # 80000c86 <release>
  return i;
}
    800058f8:	854e                	mv	a0,s3
    800058fa:	60a6                	ld	ra,72(sp)
    800058fc:	6406                	ld	s0,64(sp)
    800058fe:	74e2                	ld	s1,56(sp)
    80005900:	7942                	ld	s2,48(sp)
    80005902:	79a2                	ld	s3,40(sp)
    80005904:	7a02                	ld	s4,32(sp)
    80005906:	6ae2                	ld	s5,24(sp)
    80005908:	6b42                	ld	s6,16(sp)
    8000590a:	6161                	add	sp,sp,80
    8000590c:	8082                	ret
      release(&pi->lock);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffb097          	auipc	ra,0xffffb
    80005914:	376080e7          	jalr	886(ra) # 80000c86 <release>
      return -1;
    80005918:	59fd                	li	s3,-1
    8000591a:	bff9                	j	800058f8 <piperead+0xca>

000000008000591c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000591c:	1141                	add	sp,sp,-16
    8000591e:	e422                	sd	s0,8(sp)
    80005920:	0800                	add	s0,sp,16
    80005922:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005924:	8905                	and	a0,a0,1
    80005926:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005928:	8b89                	and	a5,a5,2
    8000592a:	c399                	beqz	a5,80005930 <flags2perm+0x14>
      perm |= PTE_W;
    8000592c:	00456513          	or	a0,a0,4
    return perm;
}
    80005930:	6422                	ld	s0,8(sp)
    80005932:	0141                	add	sp,sp,16
    80005934:	8082                	ret

0000000080005936 <exec>:

int
exec(char *path, char **argv)
{
    80005936:	df010113          	add	sp,sp,-528
    8000593a:	20113423          	sd	ra,520(sp)
    8000593e:	20813023          	sd	s0,512(sp)
    80005942:	ffa6                	sd	s1,504(sp)
    80005944:	fbca                	sd	s2,496(sp)
    80005946:	f7ce                	sd	s3,488(sp)
    80005948:	f3d2                	sd	s4,480(sp)
    8000594a:	efd6                	sd	s5,472(sp)
    8000594c:	ebda                	sd	s6,464(sp)
    8000594e:	e7de                	sd	s7,456(sp)
    80005950:	e3e2                	sd	s8,448(sp)
    80005952:	ff66                	sd	s9,440(sp)
    80005954:	fb6a                	sd	s10,432(sp)
    80005956:	f76e                	sd	s11,424(sp)
    80005958:	0c00                	add	s0,sp,528
    8000595a:	892a                	mv	s2,a0
    8000595c:	dea43c23          	sd	a0,-520(s0)
    80005960:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005964:	ffffc097          	auipc	ra,0xffffc
    80005968:	052080e7          	jalr	82(ra) # 800019b6 <myproc>
    8000596c:	84aa                	mv	s1,a0

  begin_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	48e080e7          	jalr	1166(ra) # 80004dfc <begin_op>

  if((ip = namei(path)) == 0){
    80005976:	854a                	mv	a0,s2
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	284080e7          	jalr	644(ra) # 80004bfc <namei>
    80005980:	c92d                	beqz	a0,800059f2 <exec+0xbc>
    80005982:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	ad2080e7          	jalr	-1326(ra) # 80004456 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000598c:	04000713          	li	a4,64
    80005990:	4681                	li	a3,0
    80005992:	e5040613          	add	a2,s0,-432
    80005996:	4581                	li	a1,0
    80005998:	8552                	mv	a0,s4
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	d70080e7          	jalr	-656(ra) # 8000470a <readi>
    800059a2:	04000793          	li	a5,64
    800059a6:	00f51a63          	bne	a0,a5,800059ba <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800059aa:	e5042703          	lw	a4,-432(s0)
    800059ae:	464c47b7          	lui	a5,0x464c4
    800059b2:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800059b6:	04f70463          	beq	a4,a5,800059fe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800059ba:	8552                	mv	a0,s4
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	cfc080e7          	jalr	-772(ra) # 800046b8 <iunlockput>
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	4b2080e7          	jalr	1202(ra) # 80004e76 <end_op>
  }
  return -1;
    800059cc:	557d                	li	a0,-1
}
    800059ce:	20813083          	ld	ra,520(sp)
    800059d2:	20013403          	ld	s0,512(sp)
    800059d6:	74fe                	ld	s1,504(sp)
    800059d8:	795e                	ld	s2,496(sp)
    800059da:	79be                	ld	s3,488(sp)
    800059dc:	7a1e                	ld	s4,480(sp)
    800059de:	6afe                	ld	s5,472(sp)
    800059e0:	6b5e                	ld	s6,464(sp)
    800059e2:	6bbe                	ld	s7,456(sp)
    800059e4:	6c1e                	ld	s8,448(sp)
    800059e6:	7cfa                	ld	s9,440(sp)
    800059e8:	7d5a                	ld	s10,432(sp)
    800059ea:	7dba                	ld	s11,424(sp)
    800059ec:	21010113          	add	sp,sp,528
    800059f0:	8082                	ret
    end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	484080e7          	jalr	1156(ra) # 80004e76 <end_op>
    return -1;
    800059fa:	557d                	li	a0,-1
    800059fc:	bfc9                	j	800059ce <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffc097          	auipc	ra,0xffffc
    80005a04:	07a080e7          	jalr	122(ra) # 80001a7a <proc_pagetable>
    80005a08:	8b2a                	mv	s6,a0
    80005a0a:	d945                	beqz	a0,800059ba <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a0c:	e7042d03          	lw	s10,-400(s0)
    80005a10:	e8845783          	lhu	a5,-376(s0)
    80005a14:	10078463          	beqz	a5,80005b1c <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005a18:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a1a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005a1c:	6c85                	lui	s9,0x1
    80005a1e:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005a22:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005a26:	6a85                	lui	s5,0x1
    80005a28:	a0b5                	j	80005a94 <exec+0x15e>
      panic("loadseg: address should exist");
    80005a2a:	00003517          	auipc	a0,0x3
    80005a2e:	d9650513          	add	a0,a0,-618 # 800087c0 <syscalls+0x2c8>
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	b0a080e7          	jalr	-1270(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005a3a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005a3c:	8726                	mv	a4,s1
    80005a3e:	012c06bb          	addw	a3,s8,s2
    80005a42:	4581                	li	a1,0
    80005a44:	8552                	mv	a0,s4
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	cc4080e7          	jalr	-828(ra) # 8000470a <readi>
    80005a4e:	2501                	sext.w	a0,a0
    80005a50:	24a49863          	bne	s1,a0,80005ca0 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005a54:	012a893b          	addw	s2,s5,s2
    80005a58:	03397563          	bgeu	s2,s3,80005a82 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005a5c:	02091593          	sll	a1,s2,0x20
    80005a60:	9181                	srl	a1,a1,0x20
    80005a62:	95de                	add	a1,a1,s7
    80005a64:	855a                	mv	a0,s6
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	5f0080e7          	jalr	1520(ra) # 80001056 <walkaddr>
    80005a6e:	862a                	mv	a2,a0
    if(pa == 0)
    80005a70:	dd4d                	beqz	a0,80005a2a <exec+0xf4>
    if(sz - i < PGSIZE)
    80005a72:	412984bb          	subw	s1,s3,s2
    80005a76:	0004879b          	sext.w	a5,s1
    80005a7a:	fcfcf0e3          	bgeu	s9,a5,80005a3a <exec+0x104>
    80005a7e:	84d6                	mv	s1,s5
    80005a80:	bf6d                	j	80005a3a <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005a82:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a86:	2d85                	addw	s11,s11,1
    80005a88:	038d0d1b          	addw	s10,s10,56
    80005a8c:	e8845783          	lhu	a5,-376(s0)
    80005a90:	08fdd763          	bge	s11,a5,80005b1e <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a94:	2d01                	sext.w	s10,s10
    80005a96:	03800713          	li	a4,56
    80005a9a:	86ea                	mv	a3,s10
    80005a9c:	e1840613          	add	a2,s0,-488
    80005aa0:	4581                	li	a1,0
    80005aa2:	8552                	mv	a0,s4
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	c66080e7          	jalr	-922(ra) # 8000470a <readi>
    80005aac:	03800793          	li	a5,56
    80005ab0:	1ef51663          	bne	a0,a5,80005c9c <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005ab4:	e1842783          	lw	a5,-488(s0)
    80005ab8:	4705                	li	a4,1
    80005aba:	fce796e3          	bne	a5,a4,80005a86 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005abe:	e4043483          	ld	s1,-448(s0)
    80005ac2:	e3843783          	ld	a5,-456(s0)
    80005ac6:	1ef4e863          	bltu	s1,a5,80005cb6 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005aca:	e2843783          	ld	a5,-472(s0)
    80005ace:	94be                	add	s1,s1,a5
    80005ad0:	1ef4e663          	bltu	s1,a5,80005cbc <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005ad4:	df043703          	ld	a4,-528(s0)
    80005ad8:	8ff9                	and	a5,a5,a4
    80005ada:	1e079463          	bnez	a5,80005cc2 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005ade:	e1c42503          	lw	a0,-484(s0)
    80005ae2:	00000097          	auipc	ra,0x0
    80005ae6:	e3a080e7          	jalr	-454(ra) # 8000591c <flags2perm>
    80005aea:	86aa                	mv	a3,a0
    80005aec:	8626                	mv	a2,s1
    80005aee:	85ca                	mv	a1,s2
    80005af0:	855a                	mv	a0,s6
    80005af2:	ffffc097          	auipc	ra,0xffffc
    80005af6:	918080e7          	jalr	-1768(ra) # 8000140a <uvmalloc>
    80005afa:	e0a43423          	sd	a0,-504(s0)
    80005afe:	1c050563          	beqz	a0,80005cc8 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b02:	e2843b83          	ld	s7,-472(s0)
    80005b06:	e2042c03          	lw	s8,-480(s0)
    80005b0a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b0e:	00098463          	beqz	s3,80005b16 <exec+0x1e0>
    80005b12:	4901                	li	s2,0
    80005b14:	b7a1                	j	80005a5c <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b16:	e0843903          	ld	s2,-504(s0)
    80005b1a:	b7b5                	j	80005a86 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005b1c:	4901                	li	s2,0
  iunlockput(ip);
    80005b1e:	8552                	mv	a0,s4
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	b98080e7          	jalr	-1128(ra) # 800046b8 <iunlockput>
  end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	34e080e7          	jalr	846(ra) # 80004e76 <end_op>
  p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	e86080e7          	jalr	-378(ra) # 800019b6 <myproc>
    80005b38:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005b3a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b3e:	6985                	lui	s3,0x1
    80005b40:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005b42:	99ca                	add	s3,s3,s2
    80005b44:	77fd                	lui	a5,0xfffff
    80005b46:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005b4a:	4691                	li	a3,4
    80005b4c:	6609                	lui	a2,0x2
    80005b4e:	964e                	add	a2,a2,s3
    80005b50:	85ce                	mv	a1,s3
    80005b52:	855a                	mv	a0,s6
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	8b6080e7          	jalr	-1866(ra) # 8000140a <uvmalloc>
    80005b5c:	892a                	mv	s2,a0
    80005b5e:	e0a43423          	sd	a0,-504(s0)
    80005b62:	e509                	bnez	a0,80005b6c <exec+0x236>
  if(pagetable)
    80005b64:	e1343423          	sd	s3,-504(s0)
    80005b68:	4a01                	li	s4,0
    80005b6a:	aa1d                	j	80005ca0 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b6c:	75f9                	lui	a1,0xffffe
    80005b6e:	95aa                	add	a1,a1,a0
    80005b70:	855a                	mv	a0,s6
    80005b72:	ffffc097          	auipc	ra,0xffffc
    80005b76:	ac2080e7          	jalr	-1342(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005b7a:	7bfd                	lui	s7,0xfffff
    80005b7c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005b7e:	e0043783          	ld	a5,-512(s0)
    80005b82:	6388                	ld	a0,0(a5)
    80005b84:	c52d                	beqz	a0,80005bee <exec+0x2b8>
    80005b86:	e9040993          	add	s3,s0,-368
    80005b8a:	f9040c13          	add	s8,s0,-112
    80005b8e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b90:	ffffb097          	auipc	ra,0xffffb
    80005b94:	2b8080e7          	jalr	696(ra) # 80000e48 <strlen>
    80005b98:	0015079b          	addw	a5,a0,1
    80005b9c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005ba0:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005ba4:	13796563          	bltu	s2,s7,80005cce <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005ba8:	e0043d03          	ld	s10,-512(s0)
    80005bac:	000d3a03          	ld	s4,0(s10)
    80005bb0:	8552                	mv	a0,s4
    80005bb2:	ffffb097          	auipc	ra,0xffffb
    80005bb6:	296080e7          	jalr	662(ra) # 80000e48 <strlen>
    80005bba:	0015069b          	addw	a3,a0,1
    80005bbe:	8652                	mv	a2,s4
    80005bc0:	85ca                	mv	a1,s2
    80005bc2:	855a                	mv	a0,s6
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	aa2080e7          	jalr	-1374(ra) # 80001666 <copyout>
    80005bcc:	10054363          	bltz	a0,80005cd2 <exec+0x39c>
    ustack[argc] = sp;
    80005bd0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005bd4:	0485                	add	s1,s1,1
    80005bd6:	008d0793          	add	a5,s10,8
    80005bda:	e0f43023          	sd	a5,-512(s0)
    80005bde:	008d3503          	ld	a0,8(s10)
    80005be2:	c909                	beqz	a0,80005bf4 <exec+0x2be>
    if(argc >= MAXARG)
    80005be4:	09a1                	add	s3,s3,8
    80005be6:	fb8995e3          	bne	s3,s8,80005b90 <exec+0x25a>
  ip = 0;
    80005bea:	4a01                	li	s4,0
    80005bec:	a855                	j	80005ca0 <exec+0x36a>
  sp = sz;
    80005bee:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005bf2:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bf4:	00349793          	sll	a5,s1,0x3
    80005bf8:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd8f80>
    80005bfc:	97a2                	add	a5,a5,s0
    80005bfe:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005c02:	00148693          	add	a3,s1,1
    80005c06:	068e                	sll	a3,a3,0x3
    80005c08:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c0c:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005c10:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005c14:	f57968e3          	bltu	s2,s7,80005b64 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c18:	e9040613          	add	a2,s0,-368
    80005c1c:	85ca                	mv	a1,s2
    80005c1e:	855a                	mv	a0,s6
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	a46080e7          	jalr	-1466(ra) # 80001666 <copyout>
    80005c28:	0a054763          	bltz	a0,80005cd6 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005c2c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005c30:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c34:	df843783          	ld	a5,-520(s0)
    80005c38:	0007c703          	lbu	a4,0(a5)
    80005c3c:	cf11                	beqz	a4,80005c58 <exec+0x322>
    80005c3e:	0785                	add	a5,a5,1
    if(*s == '/')
    80005c40:	02f00693          	li	a3,47
    80005c44:	a039                	j	80005c52 <exec+0x31c>
      last = s+1;
    80005c46:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005c4a:	0785                	add	a5,a5,1
    80005c4c:	fff7c703          	lbu	a4,-1(a5)
    80005c50:	c701                	beqz	a4,80005c58 <exec+0x322>
    if(*s == '/')
    80005c52:	fed71ce3          	bne	a4,a3,80005c4a <exec+0x314>
    80005c56:	bfc5                	j	80005c46 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c58:	4641                	li	a2,16
    80005c5a:	df843583          	ld	a1,-520(s0)
    80005c5e:	158a8513          	add	a0,s5,344
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	1b4080e7          	jalr	436(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c6a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005c6e:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005c72:	e0843783          	ld	a5,-504(s0)
    80005c76:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c7a:	058ab783          	ld	a5,88(s5)
    80005c7e:	e6843703          	ld	a4,-408(s0)
    80005c82:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c84:	058ab783          	ld	a5,88(s5)
    80005c88:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c8c:	85e6                	mv	a1,s9
    80005c8e:	ffffc097          	auipc	ra,0xffffc
    80005c92:	e88080e7          	jalr	-376(ra) # 80001b16 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c96:	0004851b          	sext.w	a0,s1
    80005c9a:	bb15                	j	800059ce <exec+0x98>
    80005c9c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005ca0:	e0843583          	ld	a1,-504(s0)
    80005ca4:	855a                	mv	a0,s6
    80005ca6:	ffffc097          	auipc	ra,0xffffc
    80005caa:	e70080e7          	jalr	-400(ra) # 80001b16 <proc_freepagetable>
  return -1;
    80005cae:	557d                	li	a0,-1
  if(ip){
    80005cb0:	d00a0fe3          	beqz	s4,800059ce <exec+0x98>
    80005cb4:	b319                	j	800059ba <exec+0x84>
    80005cb6:	e1243423          	sd	s2,-504(s0)
    80005cba:	b7dd                	j	80005ca0 <exec+0x36a>
    80005cbc:	e1243423          	sd	s2,-504(s0)
    80005cc0:	b7c5                	j	80005ca0 <exec+0x36a>
    80005cc2:	e1243423          	sd	s2,-504(s0)
    80005cc6:	bfe9                	j	80005ca0 <exec+0x36a>
    80005cc8:	e1243423          	sd	s2,-504(s0)
    80005ccc:	bfd1                	j	80005ca0 <exec+0x36a>
  ip = 0;
    80005cce:	4a01                	li	s4,0
    80005cd0:	bfc1                	j	80005ca0 <exec+0x36a>
    80005cd2:	4a01                	li	s4,0
  if(pagetable)
    80005cd4:	b7f1                	j	80005ca0 <exec+0x36a>
  sz = sz1;
    80005cd6:	e0843983          	ld	s3,-504(s0)
    80005cda:	b569                	j	80005b64 <exec+0x22e>

0000000080005cdc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005cdc:	7179                	add	sp,sp,-48
    80005cde:	f406                	sd	ra,40(sp)
    80005ce0:	f022                	sd	s0,32(sp)
    80005ce2:	ec26                	sd	s1,24(sp)
    80005ce4:	e84a                	sd	s2,16(sp)
    80005ce6:	1800                	add	s0,sp,48
    80005ce8:	892e                	mv	s2,a1
    80005cea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005cec:	fdc40593          	add	a1,s0,-36
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	a16080e7          	jalr	-1514(ra) # 80003706 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005cf8:	fdc42703          	lw	a4,-36(s0)
    80005cfc:	47bd                	li	a5,15
    80005cfe:	02e7eb63          	bltu	a5,a4,80005d34 <argfd+0x58>
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	cb4080e7          	jalr	-844(ra) # 800019b6 <myproc>
    80005d0a:	fdc42703          	lw	a4,-36(s0)
    80005d0e:	01a70793          	add	a5,a4,26
    80005d12:	078e                	sll	a5,a5,0x3
    80005d14:	953e                	add	a0,a0,a5
    80005d16:	611c                	ld	a5,0(a0)
    80005d18:	c385                	beqz	a5,80005d38 <argfd+0x5c>
    return -1;
  if(pfd)
    80005d1a:	00090463          	beqz	s2,80005d22 <argfd+0x46>
    *pfd = fd;
    80005d1e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005d22:	4501                	li	a0,0
  if(pf)
    80005d24:	c091                	beqz	s1,80005d28 <argfd+0x4c>
    *pf = f;
    80005d26:	e09c                	sd	a5,0(s1)
}
    80005d28:	70a2                	ld	ra,40(sp)
    80005d2a:	7402                	ld	s0,32(sp)
    80005d2c:	64e2                	ld	s1,24(sp)
    80005d2e:	6942                	ld	s2,16(sp)
    80005d30:	6145                	add	sp,sp,48
    80005d32:	8082                	ret
    return -1;
    80005d34:	557d                	li	a0,-1
    80005d36:	bfcd                	j	80005d28 <argfd+0x4c>
    80005d38:	557d                	li	a0,-1
    80005d3a:	b7fd                	j	80005d28 <argfd+0x4c>

0000000080005d3c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005d3c:	1101                	add	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	add	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c6e080e7          	jalr	-914(ra) # 800019b6 <myproc>
    80005d50:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005d52:	0d050793          	add	a5,a0,208
    80005d56:	4501                	li	a0,0
    80005d58:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005d5a:	6398                	ld	a4,0(a5)
    80005d5c:	cb19                	beqz	a4,80005d72 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005d5e:	2505                	addw	a0,a0,1
    80005d60:	07a1                	add	a5,a5,8
    80005d62:	fed51ce3          	bne	a0,a3,80005d5a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005d66:	557d                	li	a0,-1
}
    80005d68:	60e2                	ld	ra,24(sp)
    80005d6a:	6442                	ld	s0,16(sp)
    80005d6c:	64a2                	ld	s1,8(sp)
    80005d6e:	6105                	add	sp,sp,32
    80005d70:	8082                	ret
      p->ofile[fd] = f;
    80005d72:	01a50793          	add	a5,a0,26
    80005d76:	078e                	sll	a5,a5,0x3
    80005d78:	963e                	add	a2,a2,a5
    80005d7a:	e204                	sd	s1,0(a2)
      return fd;
    80005d7c:	b7f5                	j	80005d68 <fdalloc+0x2c>

0000000080005d7e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005d7e:	715d                	add	sp,sp,-80
    80005d80:	e486                	sd	ra,72(sp)
    80005d82:	e0a2                	sd	s0,64(sp)
    80005d84:	fc26                	sd	s1,56(sp)
    80005d86:	f84a                	sd	s2,48(sp)
    80005d88:	f44e                	sd	s3,40(sp)
    80005d8a:	f052                	sd	s4,32(sp)
    80005d8c:	ec56                	sd	s5,24(sp)
    80005d8e:	e85a                	sd	s6,16(sp)
    80005d90:	0880                	add	s0,sp,80
    80005d92:	8b2e                	mv	s6,a1
    80005d94:	89b2                	mv	s3,a2
    80005d96:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d98:	fb040593          	add	a1,s0,-80
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	e7e080e7          	jalr	-386(ra) # 80004c1a <nameiparent>
    80005da4:	84aa                	mv	s1,a0
    80005da6:	14050b63          	beqz	a0,80005efc <create+0x17e>
    return 0;

  ilock(dp);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	6ac080e7          	jalr	1708(ra) # 80004456 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005db2:	4601                	li	a2,0
    80005db4:	fb040593          	add	a1,s0,-80
    80005db8:	8526                	mv	a0,s1
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	b80080e7          	jalr	-1152(ra) # 8000493a <dirlookup>
    80005dc2:	8aaa                	mv	s5,a0
    80005dc4:	c921                	beqz	a0,80005e14 <create+0x96>
    iunlockput(dp);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	8f0080e7          	jalr	-1808(ra) # 800046b8 <iunlockput>
    ilock(ip);
    80005dd0:	8556                	mv	a0,s5
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	684080e7          	jalr	1668(ra) # 80004456 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005dda:	4789                	li	a5,2
    80005ddc:	02fb1563          	bne	s6,a5,80005e06 <create+0x88>
    80005de0:	044ad783          	lhu	a5,68(s5)
    80005de4:	37f9                	addw	a5,a5,-2
    80005de6:	17c2                	sll	a5,a5,0x30
    80005de8:	93c1                	srl	a5,a5,0x30
    80005dea:	4705                	li	a4,1
    80005dec:	00f76d63          	bltu	a4,a5,80005e06 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005df0:	8556                	mv	a0,s5
    80005df2:	60a6                	ld	ra,72(sp)
    80005df4:	6406                	ld	s0,64(sp)
    80005df6:	74e2                	ld	s1,56(sp)
    80005df8:	7942                	ld	s2,48(sp)
    80005dfa:	79a2                	ld	s3,40(sp)
    80005dfc:	7a02                	ld	s4,32(sp)
    80005dfe:	6ae2                	ld	s5,24(sp)
    80005e00:	6b42                	ld	s6,16(sp)
    80005e02:	6161                	add	sp,sp,80
    80005e04:	8082                	ret
    iunlockput(ip);
    80005e06:	8556                	mv	a0,s5
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	8b0080e7          	jalr	-1872(ra) # 800046b8 <iunlockput>
    return 0;
    80005e10:	4a81                	li	s5,0
    80005e12:	bff9                	j	80005df0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005e14:	85da                	mv	a1,s6
    80005e16:	4088                	lw	a0,0(s1)
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	4a6080e7          	jalr	1190(ra) # 800042be <ialloc>
    80005e20:	8a2a                	mv	s4,a0
    80005e22:	c529                	beqz	a0,80005e6c <create+0xee>
  ilock(ip);
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	632080e7          	jalr	1586(ra) # 80004456 <ilock>
  ip->major = major;
    80005e2c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005e30:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005e34:	4905                	li	s2,1
    80005e36:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005e3a:	8552                	mv	a0,s4
    80005e3c:	ffffe097          	auipc	ra,0xffffe
    80005e40:	54e080e7          	jalr	1358(ra) # 8000438a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005e44:	032b0b63          	beq	s6,s2,80005e7a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005e48:	004a2603          	lw	a2,4(s4)
    80005e4c:	fb040593          	add	a1,s0,-80
    80005e50:	8526                	mv	a0,s1
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	cf8080e7          	jalr	-776(ra) # 80004b4a <dirlink>
    80005e5a:	06054f63          	bltz	a0,80005ed8 <create+0x15a>
  iunlockput(dp);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	858080e7          	jalr	-1960(ra) # 800046b8 <iunlockput>
  return ip;
    80005e68:	8ad2                	mv	s5,s4
    80005e6a:	b759                	j	80005df0 <create+0x72>
    iunlockput(dp);
    80005e6c:	8526                	mv	a0,s1
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	84a080e7          	jalr	-1974(ra) # 800046b8 <iunlockput>
    return 0;
    80005e76:	8ad2                	mv	s5,s4
    80005e78:	bfa5                	j	80005df0 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e7a:	004a2603          	lw	a2,4(s4)
    80005e7e:	00003597          	auipc	a1,0x3
    80005e82:	96258593          	add	a1,a1,-1694 # 800087e0 <syscalls+0x2e8>
    80005e86:	8552                	mv	a0,s4
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	cc2080e7          	jalr	-830(ra) # 80004b4a <dirlink>
    80005e90:	04054463          	bltz	a0,80005ed8 <create+0x15a>
    80005e94:	40d0                	lw	a2,4(s1)
    80005e96:	00003597          	auipc	a1,0x3
    80005e9a:	95258593          	add	a1,a1,-1710 # 800087e8 <syscalls+0x2f0>
    80005e9e:	8552                	mv	a0,s4
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	caa080e7          	jalr	-854(ra) # 80004b4a <dirlink>
    80005ea8:	02054863          	bltz	a0,80005ed8 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005eac:	004a2603          	lw	a2,4(s4)
    80005eb0:	fb040593          	add	a1,s0,-80
    80005eb4:	8526                	mv	a0,s1
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	c94080e7          	jalr	-876(ra) # 80004b4a <dirlink>
    80005ebe:	00054d63          	bltz	a0,80005ed8 <create+0x15a>
    dp->nlink++;  // for ".."
    80005ec2:	04a4d783          	lhu	a5,74(s1)
    80005ec6:	2785                	addw	a5,a5,1
    80005ec8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ecc:	8526                	mv	a0,s1
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	4bc080e7          	jalr	1212(ra) # 8000438a <iupdate>
    80005ed6:	b761                	j	80005e5e <create+0xe0>
  ip->nlink = 0;
    80005ed8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005edc:	8552                	mv	a0,s4
    80005ede:	ffffe097          	auipc	ra,0xffffe
    80005ee2:	4ac080e7          	jalr	1196(ra) # 8000438a <iupdate>
  iunlockput(ip);
    80005ee6:	8552                	mv	a0,s4
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	7d0080e7          	jalr	2000(ra) # 800046b8 <iunlockput>
  iunlockput(dp);
    80005ef0:	8526                	mv	a0,s1
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	7c6080e7          	jalr	1990(ra) # 800046b8 <iunlockput>
  return 0;
    80005efa:	bddd                	j	80005df0 <create+0x72>
    return 0;
    80005efc:	8aaa                	mv	s5,a0
    80005efe:	bdcd                	j	80005df0 <create+0x72>

0000000080005f00 <sys_dup>:
{
    80005f00:	7179                	add	sp,sp,-48
    80005f02:	f406                	sd	ra,40(sp)
    80005f04:	f022                	sd	s0,32(sp)
    80005f06:	ec26                	sd	s1,24(sp)
    80005f08:	e84a                	sd	s2,16(sp)
    80005f0a:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005f0c:	fd840613          	add	a2,s0,-40
    80005f10:	4581                	li	a1,0
    80005f12:	4501                	li	a0,0
    80005f14:	00000097          	auipc	ra,0x0
    80005f18:	dc8080e7          	jalr	-568(ra) # 80005cdc <argfd>
    return -1;
    80005f1c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005f1e:	02054363          	bltz	a0,80005f44 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005f22:	fd843903          	ld	s2,-40(s0)
    80005f26:	854a                	mv	a0,s2
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	e14080e7          	jalr	-492(ra) # 80005d3c <fdalloc>
    80005f30:	84aa                	mv	s1,a0
    return -1;
    80005f32:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005f34:	00054863          	bltz	a0,80005f44 <sys_dup+0x44>
  filedup(f);
    80005f38:	854a                	mv	a0,s2
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	334080e7          	jalr	820(ra) # 8000526e <filedup>
  return fd;
    80005f42:	87a6                	mv	a5,s1
}
    80005f44:	853e                	mv	a0,a5
    80005f46:	70a2                	ld	ra,40(sp)
    80005f48:	7402                	ld	s0,32(sp)
    80005f4a:	64e2                	ld	s1,24(sp)
    80005f4c:	6942                	ld	s2,16(sp)
    80005f4e:	6145                	add	sp,sp,48
    80005f50:	8082                	ret

0000000080005f52 <sys_read>:
{
    80005f52:	7179                	add	sp,sp,-48
    80005f54:	f406                	sd	ra,40(sp)
    80005f56:	f022                	sd	s0,32(sp)
    80005f58:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005f5a:	fd840593          	add	a1,s0,-40
    80005f5e:	4505                	li	a0,1
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	7c6080e7          	jalr	1990(ra) # 80003726 <argaddr>
  argint(2, &n);
    80005f68:	fe440593          	add	a1,s0,-28
    80005f6c:	4509                	li	a0,2
    80005f6e:	ffffd097          	auipc	ra,0xffffd
    80005f72:	798080e7          	jalr	1944(ra) # 80003706 <argint>
  if(argfd(0, 0, &f) < 0)
    80005f76:	fe840613          	add	a2,s0,-24
    80005f7a:	4581                	li	a1,0
    80005f7c:	4501                	li	a0,0
    80005f7e:	00000097          	auipc	ra,0x0
    80005f82:	d5e080e7          	jalr	-674(ra) # 80005cdc <argfd>
    80005f86:	87aa                	mv	a5,a0
    return -1;
    80005f88:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f8a:	0007cc63          	bltz	a5,80005fa2 <sys_read+0x50>
  return fileread(f, p, n);
    80005f8e:	fe442603          	lw	a2,-28(s0)
    80005f92:	fd843583          	ld	a1,-40(s0)
    80005f96:	fe843503          	ld	a0,-24(s0)
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	460080e7          	jalr	1120(ra) # 800053fa <fileread>
}
    80005fa2:	70a2                	ld	ra,40(sp)
    80005fa4:	7402                	ld	s0,32(sp)
    80005fa6:	6145                	add	sp,sp,48
    80005fa8:	8082                	ret

0000000080005faa <sys_write>:
{
    80005faa:	7179                	add	sp,sp,-48
    80005fac:	f406                	sd	ra,40(sp)
    80005fae:	f022                	sd	s0,32(sp)
    80005fb0:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005fb2:	fd840593          	add	a1,s0,-40
    80005fb6:	4505                	li	a0,1
    80005fb8:	ffffd097          	auipc	ra,0xffffd
    80005fbc:	76e080e7          	jalr	1902(ra) # 80003726 <argaddr>
  argint(2, &n);
    80005fc0:	fe440593          	add	a1,s0,-28
    80005fc4:	4509                	li	a0,2
    80005fc6:	ffffd097          	auipc	ra,0xffffd
    80005fca:	740080e7          	jalr	1856(ra) # 80003706 <argint>
  if(argfd(0, 0, &f) < 0)
    80005fce:	fe840613          	add	a2,s0,-24
    80005fd2:	4581                	li	a1,0
    80005fd4:	4501                	li	a0,0
    80005fd6:	00000097          	auipc	ra,0x0
    80005fda:	d06080e7          	jalr	-762(ra) # 80005cdc <argfd>
    80005fde:	87aa                	mv	a5,a0
    return -1;
    80005fe0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005fe2:	0007cc63          	bltz	a5,80005ffa <sys_write+0x50>
  return filewrite(f, p, n);
    80005fe6:	fe442603          	lw	a2,-28(s0)
    80005fea:	fd843583          	ld	a1,-40(s0)
    80005fee:	fe843503          	ld	a0,-24(s0)
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	4ca080e7          	jalr	1226(ra) # 800054bc <filewrite>
}
    80005ffa:	70a2                	ld	ra,40(sp)
    80005ffc:	7402                	ld	s0,32(sp)
    80005ffe:	6145                	add	sp,sp,48
    80006000:	8082                	ret

0000000080006002 <sys_close>:
{
    80006002:	1101                	add	sp,sp,-32
    80006004:	ec06                	sd	ra,24(sp)
    80006006:	e822                	sd	s0,16(sp)
    80006008:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000600a:	fe040613          	add	a2,s0,-32
    8000600e:	fec40593          	add	a1,s0,-20
    80006012:	4501                	li	a0,0
    80006014:	00000097          	auipc	ra,0x0
    80006018:	cc8080e7          	jalr	-824(ra) # 80005cdc <argfd>
    return -1;
    8000601c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000601e:	02054463          	bltz	a0,80006046 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80006022:	ffffc097          	auipc	ra,0xffffc
    80006026:	994080e7          	jalr	-1644(ra) # 800019b6 <myproc>
    8000602a:	fec42783          	lw	a5,-20(s0)
    8000602e:	07e9                	add	a5,a5,26
    80006030:	078e                	sll	a5,a5,0x3
    80006032:	953e                	add	a0,a0,a5
    80006034:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80006038:	fe043503          	ld	a0,-32(s0)
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	284080e7          	jalr	644(ra) # 800052c0 <fileclose>
  return 0;
    80006044:	4781                	li	a5,0
}
    80006046:	853e                	mv	a0,a5
    80006048:	60e2                	ld	ra,24(sp)
    8000604a:	6442                	ld	s0,16(sp)
    8000604c:	6105                	add	sp,sp,32
    8000604e:	8082                	ret

0000000080006050 <sys_fstat>:
{
    80006050:	1101                	add	sp,sp,-32
    80006052:	ec06                	sd	ra,24(sp)
    80006054:	e822                	sd	s0,16(sp)
    80006056:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80006058:	fe040593          	add	a1,s0,-32
    8000605c:	4505                	li	a0,1
    8000605e:	ffffd097          	auipc	ra,0xffffd
    80006062:	6c8080e7          	jalr	1736(ra) # 80003726 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80006066:	fe840613          	add	a2,s0,-24
    8000606a:	4581                	li	a1,0
    8000606c:	4501                	li	a0,0
    8000606e:	00000097          	auipc	ra,0x0
    80006072:	c6e080e7          	jalr	-914(ra) # 80005cdc <argfd>
    80006076:	87aa                	mv	a5,a0
    return -1;
    80006078:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000607a:	0007ca63          	bltz	a5,8000608e <sys_fstat+0x3e>
  return filestat(f, st);
    8000607e:	fe043583          	ld	a1,-32(s0)
    80006082:	fe843503          	ld	a0,-24(s0)
    80006086:	fffff097          	auipc	ra,0xfffff
    8000608a:	302080e7          	jalr	770(ra) # 80005388 <filestat>
}
    8000608e:	60e2                	ld	ra,24(sp)
    80006090:	6442                	ld	s0,16(sp)
    80006092:	6105                	add	sp,sp,32
    80006094:	8082                	ret

0000000080006096 <sys_link>:
{
    80006096:	7169                	add	sp,sp,-304
    80006098:	f606                	sd	ra,296(sp)
    8000609a:	f222                	sd	s0,288(sp)
    8000609c:	ee26                	sd	s1,280(sp)
    8000609e:	ea4a                	sd	s2,272(sp)
    800060a0:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060a2:	08000613          	li	a2,128
    800060a6:	ed040593          	add	a1,s0,-304
    800060aa:	4501                	li	a0,0
    800060ac:	ffffd097          	auipc	ra,0xffffd
    800060b0:	69a080e7          	jalr	1690(ra) # 80003746 <argstr>
    return -1;
    800060b4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060b6:	10054e63          	bltz	a0,800061d2 <sys_link+0x13c>
    800060ba:	08000613          	li	a2,128
    800060be:	f5040593          	add	a1,s0,-176
    800060c2:	4505                	li	a0,1
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	682080e7          	jalr	1666(ra) # 80003746 <argstr>
    return -1;
    800060cc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060ce:	10054263          	bltz	a0,800061d2 <sys_link+0x13c>
  begin_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	d2a080e7          	jalr	-726(ra) # 80004dfc <begin_op>
  if((ip = namei(old)) == 0){
    800060da:	ed040513          	add	a0,s0,-304
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	b1e080e7          	jalr	-1250(ra) # 80004bfc <namei>
    800060e6:	84aa                	mv	s1,a0
    800060e8:	c551                	beqz	a0,80006174 <sys_link+0xde>
  ilock(ip);
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	36c080e7          	jalr	876(ra) # 80004456 <ilock>
  if(ip->type == T_DIR){
    800060f2:	04449703          	lh	a4,68(s1)
    800060f6:	4785                	li	a5,1
    800060f8:	08f70463          	beq	a4,a5,80006180 <sys_link+0xea>
  ip->nlink++;
    800060fc:	04a4d783          	lhu	a5,74(s1)
    80006100:	2785                	addw	a5,a5,1
    80006102:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	282080e7          	jalr	642(ra) # 8000438a <iupdate>
  iunlock(ip);
    80006110:	8526                	mv	a0,s1
    80006112:	ffffe097          	auipc	ra,0xffffe
    80006116:	406080e7          	jalr	1030(ra) # 80004518 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000611a:	fd040593          	add	a1,s0,-48
    8000611e:	f5040513          	add	a0,s0,-176
    80006122:	fffff097          	auipc	ra,0xfffff
    80006126:	af8080e7          	jalr	-1288(ra) # 80004c1a <nameiparent>
    8000612a:	892a                	mv	s2,a0
    8000612c:	c935                	beqz	a0,800061a0 <sys_link+0x10a>
  ilock(dp);
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	328080e7          	jalr	808(ra) # 80004456 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006136:	00092703          	lw	a4,0(s2)
    8000613a:	409c                	lw	a5,0(s1)
    8000613c:	04f71d63          	bne	a4,a5,80006196 <sys_link+0x100>
    80006140:	40d0                	lw	a2,4(s1)
    80006142:	fd040593          	add	a1,s0,-48
    80006146:	854a                	mv	a0,s2
    80006148:	fffff097          	auipc	ra,0xfffff
    8000614c:	a02080e7          	jalr	-1534(ra) # 80004b4a <dirlink>
    80006150:	04054363          	bltz	a0,80006196 <sys_link+0x100>
  iunlockput(dp);
    80006154:	854a                	mv	a0,s2
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	562080e7          	jalr	1378(ra) # 800046b8 <iunlockput>
  iput(ip);
    8000615e:	8526                	mv	a0,s1
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	4b0080e7          	jalr	1200(ra) # 80004610 <iput>
  end_op();
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	d0e080e7          	jalr	-754(ra) # 80004e76 <end_op>
  return 0;
    80006170:	4781                	li	a5,0
    80006172:	a085                	j	800061d2 <sys_link+0x13c>
    end_op();
    80006174:	fffff097          	auipc	ra,0xfffff
    80006178:	d02080e7          	jalr	-766(ra) # 80004e76 <end_op>
    return -1;
    8000617c:	57fd                	li	a5,-1
    8000617e:	a891                	j	800061d2 <sys_link+0x13c>
    iunlockput(ip);
    80006180:	8526                	mv	a0,s1
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	536080e7          	jalr	1334(ra) # 800046b8 <iunlockput>
    end_op();
    8000618a:	fffff097          	auipc	ra,0xfffff
    8000618e:	cec080e7          	jalr	-788(ra) # 80004e76 <end_op>
    return -1;
    80006192:	57fd                	li	a5,-1
    80006194:	a83d                	j	800061d2 <sys_link+0x13c>
    iunlockput(dp);
    80006196:	854a                	mv	a0,s2
    80006198:	ffffe097          	auipc	ra,0xffffe
    8000619c:	520080e7          	jalr	1312(ra) # 800046b8 <iunlockput>
  ilock(ip);
    800061a0:	8526                	mv	a0,s1
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	2b4080e7          	jalr	692(ra) # 80004456 <ilock>
  ip->nlink--;
    800061aa:	04a4d783          	lhu	a5,74(s1)
    800061ae:	37fd                	addw	a5,a5,-1
    800061b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800061b4:	8526                	mv	a0,s1
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	1d4080e7          	jalr	468(ra) # 8000438a <iupdate>
  iunlockput(ip);
    800061be:	8526                	mv	a0,s1
    800061c0:	ffffe097          	auipc	ra,0xffffe
    800061c4:	4f8080e7          	jalr	1272(ra) # 800046b8 <iunlockput>
  end_op();
    800061c8:	fffff097          	auipc	ra,0xfffff
    800061cc:	cae080e7          	jalr	-850(ra) # 80004e76 <end_op>
  return -1;
    800061d0:	57fd                	li	a5,-1
}
    800061d2:	853e                	mv	a0,a5
    800061d4:	70b2                	ld	ra,296(sp)
    800061d6:	7412                	ld	s0,288(sp)
    800061d8:	64f2                	ld	s1,280(sp)
    800061da:	6952                	ld	s2,272(sp)
    800061dc:	6155                	add	sp,sp,304
    800061de:	8082                	ret

00000000800061e0 <sys_unlink>:
{
    800061e0:	7151                	add	sp,sp,-240
    800061e2:	f586                	sd	ra,232(sp)
    800061e4:	f1a2                	sd	s0,224(sp)
    800061e6:	eda6                	sd	s1,216(sp)
    800061e8:	e9ca                	sd	s2,208(sp)
    800061ea:	e5ce                	sd	s3,200(sp)
    800061ec:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800061ee:	08000613          	li	a2,128
    800061f2:	f3040593          	add	a1,s0,-208
    800061f6:	4501                	li	a0,0
    800061f8:	ffffd097          	auipc	ra,0xffffd
    800061fc:	54e080e7          	jalr	1358(ra) # 80003746 <argstr>
    80006200:	18054163          	bltz	a0,80006382 <sys_unlink+0x1a2>
  begin_op();
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	bf8080e7          	jalr	-1032(ra) # 80004dfc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000620c:	fb040593          	add	a1,s0,-80
    80006210:	f3040513          	add	a0,s0,-208
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	a06080e7          	jalr	-1530(ra) # 80004c1a <nameiparent>
    8000621c:	84aa                	mv	s1,a0
    8000621e:	c979                	beqz	a0,800062f4 <sys_unlink+0x114>
  ilock(dp);
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	236080e7          	jalr	566(ra) # 80004456 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006228:	00002597          	auipc	a1,0x2
    8000622c:	5b858593          	add	a1,a1,1464 # 800087e0 <syscalls+0x2e8>
    80006230:	fb040513          	add	a0,s0,-80
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	6ec080e7          	jalr	1772(ra) # 80004920 <namecmp>
    8000623c:	14050a63          	beqz	a0,80006390 <sys_unlink+0x1b0>
    80006240:	00002597          	auipc	a1,0x2
    80006244:	5a858593          	add	a1,a1,1448 # 800087e8 <syscalls+0x2f0>
    80006248:	fb040513          	add	a0,s0,-80
    8000624c:	ffffe097          	auipc	ra,0xffffe
    80006250:	6d4080e7          	jalr	1748(ra) # 80004920 <namecmp>
    80006254:	12050e63          	beqz	a0,80006390 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006258:	f2c40613          	add	a2,s0,-212
    8000625c:	fb040593          	add	a1,s0,-80
    80006260:	8526                	mv	a0,s1
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	6d8080e7          	jalr	1752(ra) # 8000493a <dirlookup>
    8000626a:	892a                	mv	s2,a0
    8000626c:	12050263          	beqz	a0,80006390 <sys_unlink+0x1b0>
  ilock(ip);
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	1e6080e7          	jalr	486(ra) # 80004456 <ilock>
  if(ip->nlink < 1)
    80006278:	04a91783          	lh	a5,74(s2)
    8000627c:	08f05263          	blez	a5,80006300 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006280:	04491703          	lh	a4,68(s2)
    80006284:	4785                	li	a5,1
    80006286:	08f70563          	beq	a4,a5,80006310 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000628a:	4641                	li	a2,16
    8000628c:	4581                	li	a1,0
    8000628e:	fc040513          	add	a0,s0,-64
    80006292:	ffffb097          	auipc	ra,0xffffb
    80006296:	a3c080e7          	jalr	-1476(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000629a:	4741                	li	a4,16
    8000629c:	f2c42683          	lw	a3,-212(s0)
    800062a0:	fc040613          	add	a2,s0,-64
    800062a4:	4581                	li	a1,0
    800062a6:	8526                	mv	a0,s1
    800062a8:	ffffe097          	auipc	ra,0xffffe
    800062ac:	55a080e7          	jalr	1370(ra) # 80004802 <writei>
    800062b0:	47c1                	li	a5,16
    800062b2:	0af51563          	bne	a0,a5,8000635c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800062b6:	04491703          	lh	a4,68(s2)
    800062ba:	4785                	li	a5,1
    800062bc:	0af70863          	beq	a4,a5,8000636c <sys_unlink+0x18c>
  iunlockput(dp);
    800062c0:	8526                	mv	a0,s1
    800062c2:	ffffe097          	auipc	ra,0xffffe
    800062c6:	3f6080e7          	jalr	1014(ra) # 800046b8 <iunlockput>
  ip->nlink--;
    800062ca:	04a95783          	lhu	a5,74(s2)
    800062ce:	37fd                	addw	a5,a5,-1
    800062d0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800062d4:	854a                	mv	a0,s2
    800062d6:	ffffe097          	auipc	ra,0xffffe
    800062da:	0b4080e7          	jalr	180(ra) # 8000438a <iupdate>
  iunlockput(ip);
    800062de:	854a                	mv	a0,s2
    800062e0:	ffffe097          	auipc	ra,0xffffe
    800062e4:	3d8080e7          	jalr	984(ra) # 800046b8 <iunlockput>
  end_op();
    800062e8:	fffff097          	auipc	ra,0xfffff
    800062ec:	b8e080e7          	jalr	-1138(ra) # 80004e76 <end_op>
  return 0;
    800062f0:	4501                	li	a0,0
    800062f2:	a84d                	j	800063a4 <sys_unlink+0x1c4>
    end_op();
    800062f4:	fffff097          	auipc	ra,0xfffff
    800062f8:	b82080e7          	jalr	-1150(ra) # 80004e76 <end_op>
    return -1;
    800062fc:	557d                	li	a0,-1
    800062fe:	a05d                	j	800063a4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006300:	00002517          	auipc	a0,0x2
    80006304:	4f050513          	add	a0,a0,1264 # 800087f0 <syscalls+0x2f8>
    80006308:	ffffa097          	auipc	ra,0xffffa
    8000630c:	234080e7          	jalr	564(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006310:	04c92703          	lw	a4,76(s2)
    80006314:	02000793          	li	a5,32
    80006318:	f6e7f9e3          	bgeu	a5,a4,8000628a <sys_unlink+0xaa>
    8000631c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006320:	4741                	li	a4,16
    80006322:	86ce                	mv	a3,s3
    80006324:	f1840613          	add	a2,s0,-232
    80006328:	4581                	li	a1,0
    8000632a:	854a                	mv	a0,s2
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	3de080e7          	jalr	990(ra) # 8000470a <readi>
    80006334:	47c1                	li	a5,16
    80006336:	00f51b63          	bne	a0,a5,8000634c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000633a:	f1845783          	lhu	a5,-232(s0)
    8000633e:	e7a1                	bnez	a5,80006386 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006340:	29c1                	addw	s3,s3,16
    80006342:	04c92783          	lw	a5,76(s2)
    80006346:	fcf9ede3          	bltu	s3,a5,80006320 <sys_unlink+0x140>
    8000634a:	b781                	j	8000628a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000634c:	00002517          	auipc	a0,0x2
    80006350:	4bc50513          	add	a0,a0,1212 # 80008808 <syscalls+0x310>
    80006354:	ffffa097          	auipc	ra,0xffffa
    80006358:	1e8080e7          	jalr	488(ra) # 8000053c <panic>
    panic("unlink: writei");
    8000635c:	00002517          	auipc	a0,0x2
    80006360:	4c450513          	add	a0,a0,1220 # 80008820 <syscalls+0x328>
    80006364:	ffffa097          	auipc	ra,0xffffa
    80006368:	1d8080e7          	jalr	472(ra) # 8000053c <panic>
    dp->nlink--;
    8000636c:	04a4d783          	lhu	a5,74(s1)
    80006370:	37fd                	addw	a5,a5,-1
    80006372:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006376:	8526                	mv	a0,s1
    80006378:	ffffe097          	auipc	ra,0xffffe
    8000637c:	012080e7          	jalr	18(ra) # 8000438a <iupdate>
    80006380:	b781                	j	800062c0 <sys_unlink+0xe0>
    return -1;
    80006382:	557d                	li	a0,-1
    80006384:	a005                	j	800063a4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006386:	854a                	mv	a0,s2
    80006388:	ffffe097          	auipc	ra,0xffffe
    8000638c:	330080e7          	jalr	816(ra) # 800046b8 <iunlockput>
  iunlockput(dp);
    80006390:	8526                	mv	a0,s1
    80006392:	ffffe097          	auipc	ra,0xffffe
    80006396:	326080e7          	jalr	806(ra) # 800046b8 <iunlockput>
  end_op();
    8000639a:	fffff097          	auipc	ra,0xfffff
    8000639e:	adc080e7          	jalr	-1316(ra) # 80004e76 <end_op>
  return -1;
    800063a2:	557d                	li	a0,-1
}
    800063a4:	70ae                	ld	ra,232(sp)
    800063a6:	740e                	ld	s0,224(sp)
    800063a8:	64ee                	ld	s1,216(sp)
    800063aa:	694e                	ld	s2,208(sp)
    800063ac:	69ae                	ld	s3,200(sp)
    800063ae:	616d                	add	sp,sp,240
    800063b0:	8082                	ret

00000000800063b2 <sys_open>:

uint64
sys_open(void)
{
    800063b2:	7131                	add	sp,sp,-192
    800063b4:	fd06                	sd	ra,184(sp)
    800063b6:	f922                	sd	s0,176(sp)
    800063b8:	f526                	sd	s1,168(sp)
    800063ba:	f14a                	sd	s2,160(sp)
    800063bc:	ed4e                	sd	s3,152(sp)
    800063be:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800063c0:	f4c40593          	add	a1,s0,-180
    800063c4:	4505                	li	a0,1
    800063c6:	ffffd097          	auipc	ra,0xffffd
    800063ca:	340080e7          	jalr	832(ra) # 80003706 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800063ce:	08000613          	li	a2,128
    800063d2:	f5040593          	add	a1,s0,-176
    800063d6:	4501                	li	a0,0
    800063d8:	ffffd097          	auipc	ra,0xffffd
    800063dc:	36e080e7          	jalr	878(ra) # 80003746 <argstr>
    800063e0:	87aa                	mv	a5,a0
    return -1;
    800063e2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800063e4:	0a07c863          	bltz	a5,80006494 <sys_open+0xe2>

  begin_op();
    800063e8:	fffff097          	auipc	ra,0xfffff
    800063ec:	a14080e7          	jalr	-1516(ra) # 80004dfc <begin_op>

  if(omode & O_CREATE){
    800063f0:	f4c42783          	lw	a5,-180(s0)
    800063f4:	2007f793          	and	a5,a5,512
    800063f8:	cbdd                	beqz	a5,800064ae <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800063fa:	4681                	li	a3,0
    800063fc:	4601                	li	a2,0
    800063fe:	4589                	li	a1,2
    80006400:	f5040513          	add	a0,s0,-176
    80006404:	00000097          	auipc	ra,0x0
    80006408:	97a080e7          	jalr	-1670(ra) # 80005d7e <create>
    8000640c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000640e:	c951                	beqz	a0,800064a2 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006410:	04449703          	lh	a4,68(s1)
    80006414:	478d                	li	a5,3
    80006416:	00f71763          	bne	a4,a5,80006424 <sys_open+0x72>
    8000641a:	0464d703          	lhu	a4,70(s1)
    8000641e:	47a5                	li	a5,9
    80006420:	0ce7ec63          	bltu	a5,a4,800064f8 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006424:	fffff097          	auipc	ra,0xfffff
    80006428:	de0080e7          	jalr	-544(ra) # 80005204 <filealloc>
    8000642c:	892a                	mv	s2,a0
    8000642e:	c56d                	beqz	a0,80006518 <sys_open+0x166>
    80006430:	00000097          	auipc	ra,0x0
    80006434:	90c080e7          	jalr	-1780(ra) # 80005d3c <fdalloc>
    80006438:	89aa                	mv	s3,a0
    8000643a:	0c054a63          	bltz	a0,8000650e <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000643e:	04449703          	lh	a4,68(s1)
    80006442:	478d                	li	a5,3
    80006444:	0ef70563          	beq	a4,a5,8000652e <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006448:	4789                	li	a5,2
    8000644a:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000644e:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80006452:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80006456:	f4c42783          	lw	a5,-180(s0)
    8000645a:	0017c713          	xor	a4,a5,1
    8000645e:	8b05                	and	a4,a4,1
    80006460:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006464:	0037f713          	and	a4,a5,3
    80006468:	00e03733          	snez	a4,a4
    8000646c:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006470:	4007f793          	and	a5,a5,1024
    80006474:	c791                	beqz	a5,80006480 <sys_open+0xce>
    80006476:	04449703          	lh	a4,68(s1)
    8000647a:	4789                	li	a5,2
    8000647c:	0cf70063          	beq	a4,a5,8000653c <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80006480:	8526                	mv	a0,s1
    80006482:	ffffe097          	auipc	ra,0xffffe
    80006486:	096080e7          	jalr	150(ra) # 80004518 <iunlock>
  end_op();
    8000648a:	fffff097          	auipc	ra,0xfffff
    8000648e:	9ec080e7          	jalr	-1556(ra) # 80004e76 <end_op>

  return fd;
    80006492:	854e                	mv	a0,s3
}
    80006494:	70ea                	ld	ra,184(sp)
    80006496:	744a                	ld	s0,176(sp)
    80006498:	74aa                	ld	s1,168(sp)
    8000649a:	790a                	ld	s2,160(sp)
    8000649c:	69ea                	ld	s3,152(sp)
    8000649e:	6129                	add	sp,sp,192
    800064a0:	8082                	ret
      end_op();
    800064a2:	fffff097          	auipc	ra,0xfffff
    800064a6:	9d4080e7          	jalr	-1580(ra) # 80004e76 <end_op>
      return -1;
    800064aa:	557d                	li	a0,-1
    800064ac:	b7e5                	j	80006494 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800064ae:	f5040513          	add	a0,s0,-176
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	74a080e7          	jalr	1866(ra) # 80004bfc <namei>
    800064ba:	84aa                	mv	s1,a0
    800064bc:	c905                	beqz	a0,800064ec <sys_open+0x13a>
    ilock(ip);
    800064be:	ffffe097          	auipc	ra,0xffffe
    800064c2:	f98080e7          	jalr	-104(ra) # 80004456 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800064c6:	04449703          	lh	a4,68(s1)
    800064ca:	4785                	li	a5,1
    800064cc:	f4f712e3          	bne	a4,a5,80006410 <sys_open+0x5e>
    800064d0:	f4c42783          	lw	a5,-180(s0)
    800064d4:	dba1                	beqz	a5,80006424 <sys_open+0x72>
      iunlockput(ip);
    800064d6:	8526                	mv	a0,s1
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	1e0080e7          	jalr	480(ra) # 800046b8 <iunlockput>
      end_op();
    800064e0:	fffff097          	auipc	ra,0xfffff
    800064e4:	996080e7          	jalr	-1642(ra) # 80004e76 <end_op>
      return -1;
    800064e8:	557d                	li	a0,-1
    800064ea:	b76d                	j	80006494 <sys_open+0xe2>
      end_op();
    800064ec:	fffff097          	auipc	ra,0xfffff
    800064f0:	98a080e7          	jalr	-1654(ra) # 80004e76 <end_op>
      return -1;
    800064f4:	557d                	li	a0,-1
    800064f6:	bf79                	j	80006494 <sys_open+0xe2>
    iunlockput(ip);
    800064f8:	8526                	mv	a0,s1
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	1be080e7          	jalr	446(ra) # 800046b8 <iunlockput>
    end_op();
    80006502:	fffff097          	auipc	ra,0xfffff
    80006506:	974080e7          	jalr	-1676(ra) # 80004e76 <end_op>
    return -1;
    8000650a:	557d                	li	a0,-1
    8000650c:	b761                	j	80006494 <sys_open+0xe2>
      fileclose(f);
    8000650e:	854a                	mv	a0,s2
    80006510:	fffff097          	auipc	ra,0xfffff
    80006514:	db0080e7          	jalr	-592(ra) # 800052c0 <fileclose>
    iunlockput(ip);
    80006518:	8526                	mv	a0,s1
    8000651a:	ffffe097          	auipc	ra,0xffffe
    8000651e:	19e080e7          	jalr	414(ra) # 800046b8 <iunlockput>
    end_op();
    80006522:	fffff097          	auipc	ra,0xfffff
    80006526:	954080e7          	jalr	-1708(ra) # 80004e76 <end_op>
    return -1;
    8000652a:	557d                	li	a0,-1
    8000652c:	b7a5                	j	80006494 <sys_open+0xe2>
    f->type = FD_DEVICE;
    8000652e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80006532:	04649783          	lh	a5,70(s1)
    80006536:	02f91223          	sh	a5,36(s2)
    8000653a:	bf21                	j	80006452 <sys_open+0xa0>
    itrunc(ip);
    8000653c:	8526                	mv	a0,s1
    8000653e:	ffffe097          	auipc	ra,0xffffe
    80006542:	026080e7          	jalr	38(ra) # 80004564 <itrunc>
    80006546:	bf2d                	j	80006480 <sys_open+0xce>

0000000080006548 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006548:	7175                	add	sp,sp,-144
    8000654a:	e506                	sd	ra,136(sp)
    8000654c:	e122                	sd	s0,128(sp)
    8000654e:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006550:	fffff097          	auipc	ra,0xfffff
    80006554:	8ac080e7          	jalr	-1876(ra) # 80004dfc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006558:	08000613          	li	a2,128
    8000655c:	f7040593          	add	a1,s0,-144
    80006560:	4501                	li	a0,0
    80006562:	ffffd097          	auipc	ra,0xffffd
    80006566:	1e4080e7          	jalr	484(ra) # 80003746 <argstr>
    8000656a:	02054963          	bltz	a0,8000659c <sys_mkdir+0x54>
    8000656e:	4681                	li	a3,0
    80006570:	4601                	li	a2,0
    80006572:	4585                	li	a1,1
    80006574:	f7040513          	add	a0,s0,-144
    80006578:	00000097          	auipc	ra,0x0
    8000657c:	806080e7          	jalr	-2042(ra) # 80005d7e <create>
    80006580:	cd11                	beqz	a0,8000659c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006582:	ffffe097          	auipc	ra,0xffffe
    80006586:	136080e7          	jalr	310(ra) # 800046b8 <iunlockput>
  end_op();
    8000658a:	fffff097          	auipc	ra,0xfffff
    8000658e:	8ec080e7          	jalr	-1812(ra) # 80004e76 <end_op>
  return 0;
    80006592:	4501                	li	a0,0
}
    80006594:	60aa                	ld	ra,136(sp)
    80006596:	640a                	ld	s0,128(sp)
    80006598:	6149                	add	sp,sp,144
    8000659a:	8082                	ret
    end_op();
    8000659c:	fffff097          	auipc	ra,0xfffff
    800065a0:	8da080e7          	jalr	-1830(ra) # 80004e76 <end_op>
    return -1;
    800065a4:	557d                	li	a0,-1
    800065a6:	b7fd                	j	80006594 <sys_mkdir+0x4c>

00000000800065a8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800065a8:	7135                	add	sp,sp,-160
    800065aa:	ed06                	sd	ra,152(sp)
    800065ac:	e922                	sd	s0,144(sp)
    800065ae:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800065b0:	fffff097          	auipc	ra,0xfffff
    800065b4:	84c080e7          	jalr	-1972(ra) # 80004dfc <begin_op>
  argint(1, &major);
    800065b8:	f6c40593          	add	a1,s0,-148
    800065bc:	4505                	li	a0,1
    800065be:	ffffd097          	auipc	ra,0xffffd
    800065c2:	148080e7          	jalr	328(ra) # 80003706 <argint>
  argint(2, &minor);
    800065c6:	f6840593          	add	a1,s0,-152
    800065ca:	4509                	li	a0,2
    800065cc:	ffffd097          	auipc	ra,0xffffd
    800065d0:	13a080e7          	jalr	314(ra) # 80003706 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800065d4:	08000613          	li	a2,128
    800065d8:	f7040593          	add	a1,s0,-144
    800065dc:	4501                	li	a0,0
    800065de:	ffffd097          	auipc	ra,0xffffd
    800065e2:	168080e7          	jalr	360(ra) # 80003746 <argstr>
    800065e6:	02054b63          	bltz	a0,8000661c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800065ea:	f6841683          	lh	a3,-152(s0)
    800065ee:	f6c41603          	lh	a2,-148(s0)
    800065f2:	458d                	li	a1,3
    800065f4:	f7040513          	add	a0,s0,-144
    800065f8:	fffff097          	auipc	ra,0xfffff
    800065fc:	786080e7          	jalr	1926(ra) # 80005d7e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006600:	cd11                	beqz	a0,8000661c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006602:	ffffe097          	auipc	ra,0xffffe
    80006606:	0b6080e7          	jalr	182(ra) # 800046b8 <iunlockput>
  end_op();
    8000660a:	fffff097          	auipc	ra,0xfffff
    8000660e:	86c080e7          	jalr	-1940(ra) # 80004e76 <end_op>
  return 0;
    80006612:	4501                	li	a0,0
}
    80006614:	60ea                	ld	ra,152(sp)
    80006616:	644a                	ld	s0,144(sp)
    80006618:	610d                	add	sp,sp,160
    8000661a:	8082                	ret
    end_op();
    8000661c:	fffff097          	auipc	ra,0xfffff
    80006620:	85a080e7          	jalr	-1958(ra) # 80004e76 <end_op>
    return -1;
    80006624:	557d                	li	a0,-1
    80006626:	b7fd                	j	80006614 <sys_mknod+0x6c>

0000000080006628 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006628:	7135                	add	sp,sp,-160
    8000662a:	ed06                	sd	ra,152(sp)
    8000662c:	e922                	sd	s0,144(sp)
    8000662e:	e526                	sd	s1,136(sp)
    80006630:	e14a                	sd	s2,128(sp)
    80006632:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006634:	ffffb097          	auipc	ra,0xffffb
    80006638:	382080e7          	jalr	898(ra) # 800019b6 <myproc>
    8000663c:	892a                	mv	s2,a0
  
  begin_op();
    8000663e:	ffffe097          	auipc	ra,0xffffe
    80006642:	7be080e7          	jalr	1982(ra) # 80004dfc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006646:	08000613          	li	a2,128
    8000664a:	f6040593          	add	a1,s0,-160
    8000664e:	4501                	li	a0,0
    80006650:	ffffd097          	auipc	ra,0xffffd
    80006654:	0f6080e7          	jalr	246(ra) # 80003746 <argstr>
    80006658:	04054b63          	bltz	a0,800066ae <sys_chdir+0x86>
    8000665c:	f6040513          	add	a0,s0,-160
    80006660:	ffffe097          	auipc	ra,0xffffe
    80006664:	59c080e7          	jalr	1436(ra) # 80004bfc <namei>
    80006668:	84aa                	mv	s1,a0
    8000666a:	c131                	beqz	a0,800066ae <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000666c:	ffffe097          	auipc	ra,0xffffe
    80006670:	dea080e7          	jalr	-534(ra) # 80004456 <ilock>
  if(ip->type != T_DIR){
    80006674:	04449703          	lh	a4,68(s1)
    80006678:	4785                	li	a5,1
    8000667a:	04f71063          	bne	a4,a5,800066ba <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000667e:	8526                	mv	a0,s1
    80006680:	ffffe097          	auipc	ra,0xffffe
    80006684:	e98080e7          	jalr	-360(ra) # 80004518 <iunlock>
  iput(p->cwd);
    80006688:	15093503          	ld	a0,336(s2)
    8000668c:	ffffe097          	auipc	ra,0xffffe
    80006690:	f84080e7          	jalr	-124(ra) # 80004610 <iput>
  end_op();
    80006694:	ffffe097          	auipc	ra,0xffffe
    80006698:	7e2080e7          	jalr	2018(ra) # 80004e76 <end_op>
  p->cwd = ip;
    8000669c:	14993823          	sd	s1,336(s2)
  return 0;
    800066a0:	4501                	li	a0,0
}
    800066a2:	60ea                	ld	ra,152(sp)
    800066a4:	644a                	ld	s0,144(sp)
    800066a6:	64aa                	ld	s1,136(sp)
    800066a8:	690a                	ld	s2,128(sp)
    800066aa:	610d                	add	sp,sp,160
    800066ac:	8082                	ret
    end_op();
    800066ae:	ffffe097          	auipc	ra,0xffffe
    800066b2:	7c8080e7          	jalr	1992(ra) # 80004e76 <end_op>
    return -1;
    800066b6:	557d                	li	a0,-1
    800066b8:	b7ed                	j	800066a2 <sys_chdir+0x7a>
    iunlockput(ip);
    800066ba:	8526                	mv	a0,s1
    800066bc:	ffffe097          	auipc	ra,0xffffe
    800066c0:	ffc080e7          	jalr	-4(ra) # 800046b8 <iunlockput>
    end_op();
    800066c4:	ffffe097          	auipc	ra,0xffffe
    800066c8:	7b2080e7          	jalr	1970(ra) # 80004e76 <end_op>
    return -1;
    800066cc:	557d                	li	a0,-1
    800066ce:	bfd1                	j	800066a2 <sys_chdir+0x7a>

00000000800066d0 <sys_exec>:

uint64
sys_exec(void)
{
    800066d0:	7121                	add	sp,sp,-448
    800066d2:	ff06                	sd	ra,440(sp)
    800066d4:	fb22                	sd	s0,432(sp)
    800066d6:	f726                	sd	s1,424(sp)
    800066d8:	f34a                	sd	s2,416(sp)
    800066da:	ef4e                	sd	s3,408(sp)
    800066dc:	eb52                	sd	s4,400(sp)
    800066de:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800066e0:	e4840593          	add	a1,s0,-440
    800066e4:	4505                	li	a0,1
    800066e6:	ffffd097          	auipc	ra,0xffffd
    800066ea:	040080e7          	jalr	64(ra) # 80003726 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800066ee:	08000613          	li	a2,128
    800066f2:	f5040593          	add	a1,s0,-176
    800066f6:	4501                	li	a0,0
    800066f8:	ffffd097          	auipc	ra,0xffffd
    800066fc:	04e080e7          	jalr	78(ra) # 80003746 <argstr>
    80006700:	87aa                	mv	a5,a0
    return -1;
    80006702:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006704:	0c07c263          	bltz	a5,800067c8 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80006708:	10000613          	li	a2,256
    8000670c:	4581                	li	a1,0
    8000670e:	e5040513          	add	a0,s0,-432
    80006712:	ffffa097          	auipc	ra,0xffffa
    80006716:	5bc080e7          	jalr	1468(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000671a:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000671e:	89a6                	mv	s3,s1
    80006720:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006722:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006726:	00391513          	sll	a0,s2,0x3
    8000672a:	e4040593          	add	a1,s0,-448
    8000672e:	e4843783          	ld	a5,-440(s0)
    80006732:	953e                	add	a0,a0,a5
    80006734:	ffffd097          	auipc	ra,0xffffd
    80006738:	f34080e7          	jalr	-204(ra) # 80003668 <fetchaddr>
    8000673c:	02054a63          	bltz	a0,80006770 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006740:	e4043783          	ld	a5,-448(s0)
    80006744:	c3b9                	beqz	a5,8000678a <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006746:	ffffa097          	auipc	ra,0xffffa
    8000674a:	39c080e7          	jalr	924(ra) # 80000ae2 <kalloc>
    8000674e:	85aa                	mv	a1,a0
    80006750:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006754:	cd11                	beqz	a0,80006770 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006756:	6605                	lui	a2,0x1
    80006758:	e4043503          	ld	a0,-448(s0)
    8000675c:	ffffd097          	auipc	ra,0xffffd
    80006760:	f5e080e7          	jalr	-162(ra) # 800036ba <fetchstr>
    80006764:	00054663          	bltz	a0,80006770 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006768:	0905                	add	s2,s2,1
    8000676a:	09a1                	add	s3,s3,8
    8000676c:	fb491de3          	bne	s2,s4,80006726 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006770:	f5040913          	add	s2,s0,-176
    80006774:	6088                	ld	a0,0(s1)
    80006776:	c921                	beqz	a0,800067c6 <sys_exec+0xf6>
    kfree(argv[i]);
    80006778:	ffffa097          	auipc	ra,0xffffa
    8000677c:	26c080e7          	jalr	620(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006780:	04a1                	add	s1,s1,8
    80006782:	ff2499e3          	bne	s1,s2,80006774 <sys_exec+0xa4>
  return -1;
    80006786:	557d                	li	a0,-1
    80006788:	a081                	j	800067c8 <sys_exec+0xf8>
      argv[i] = 0;
    8000678a:	0009079b          	sext.w	a5,s2
    8000678e:	078e                	sll	a5,a5,0x3
    80006790:	fd078793          	add	a5,a5,-48
    80006794:	97a2                	add	a5,a5,s0
    80006796:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    8000679a:	e5040593          	add	a1,s0,-432
    8000679e:	f5040513          	add	a0,s0,-176
    800067a2:	fffff097          	auipc	ra,0xfffff
    800067a6:	194080e7          	jalr	404(ra) # 80005936 <exec>
    800067aa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067ac:	f5040993          	add	s3,s0,-176
    800067b0:	6088                	ld	a0,0(s1)
    800067b2:	c901                	beqz	a0,800067c2 <sys_exec+0xf2>
    kfree(argv[i]);
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	230080e7          	jalr	560(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067bc:	04a1                	add	s1,s1,8
    800067be:	ff3499e3          	bne	s1,s3,800067b0 <sys_exec+0xe0>
  return ret;
    800067c2:	854a                	mv	a0,s2
    800067c4:	a011                	j	800067c8 <sys_exec+0xf8>
  return -1;
    800067c6:	557d                	li	a0,-1
}
    800067c8:	70fa                	ld	ra,440(sp)
    800067ca:	745a                	ld	s0,432(sp)
    800067cc:	74ba                	ld	s1,424(sp)
    800067ce:	791a                	ld	s2,416(sp)
    800067d0:	69fa                	ld	s3,408(sp)
    800067d2:	6a5a                	ld	s4,400(sp)
    800067d4:	6139                	add	sp,sp,448
    800067d6:	8082                	ret

00000000800067d8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800067d8:	7139                	add	sp,sp,-64
    800067da:	fc06                	sd	ra,56(sp)
    800067dc:	f822                	sd	s0,48(sp)
    800067de:	f426                	sd	s1,40(sp)
    800067e0:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800067e2:	ffffb097          	auipc	ra,0xffffb
    800067e6:	1d4080e7          	jalr	468(ra) # 800019b6 <myproc>
    800067ea:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800067ec:	fd840593          	add	a1,s0,-40
    800067f0:	4501                	li	a0,0
    800067f2:	ffffd097          	auipc	ra,0xffffd
    800067f6:	f34080e7          	jalr	-204(ra) # 80003726 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800067fa:	fc840593          	add	a1,s0,-56
    800067fe:	fd040513          	add	a0,s0,-48
    80006802:	fffff097          	auipc	ra,0xfffff
    80006806:	dea080e7          	jalr	-534(ra) # 800055ec <pipealloc>
    return -1;
    8000680a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000680c:	0c054463          	bltz	a0,800068d4 <sys_pipe+0xfc>
  fd0 = -1;
    80006810:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006814:	fd043503          	ld	a0,-48(s0)
    80006818:	fffff097          	auipc	ra,0xfffff
    8000681c:	524080e7          	jalr	1316(ra) # 80005d3c <fdalloc>
    80006820:	fca42223          	sw	a0,-60(s0)
    80006824:	08054b63          	bltz	a0,800068ba <sys_pipe+0xe2>
    80006828:	fc843503          	ld	a0,-56(s0)
    8000682c:	fffff097          	auipc	ra,0xfffff
    80006830:	510080e7          	jalr	1296(ra) # 80005d3c <fdalloc>
    80006834:	fca42023          	sw	a0,-64(s0)
    80006838:	06054863          	bltz	a0,800068a8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000683c:	4691                	li	a3,4
    8000683e:	fc440613          	add	a2,s0,-60
    80006842:	fd843583          	ld	a1,-40(s0)
    80006846:	68a8                	ld	a0,80(s1)
    80006848:	ffffb097          	auipc	ra,0xffffb
    8000684c:	e1e080e7          	jalr	-482(ra) # 80001666 <copyout>
    80006850:	02054063          	bltz	a0,80006870 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006854:	4691                	li	a3,4
    80006856:	fc040613          	add	a2,s0,-64
    8000685a:	fd843583          	ld	a1,-40(s0)
    8000685e:	0591                	add	a1,a1,4
    80006860:	68a8                	ld	a0,80(s1)
    80006862:	ffffb097          	auipc	ra,0xffffb
    80006866:	e04080e7          	jalr	-508(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000686a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000686c:	06055463          	bgez	a0,800068d4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006870:	fc442783          	lw	a5,-60(s0)
    80006874:	07e9                	add	a5,a5,26
    80006876:	078e                	sll	a5,a5,0x3
    80006878:	97a6                	add	a5,a5,s1
    8000687a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000687e:	fc042783          	lw	a5,-64(s0)
    80006882:	07e9                	add	a5,a5,26
    80006884:	078e                	sll	a5,a5,0x3
    80006886:	94be                	add	s1,s1,a5
    80006888:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000688c:	fd043503          	ld	a0,-48(s0)
    80006890:	fffff097          	auipc	ra,0xfffff
    80006894:	a30080e7          	jalr	-1488(ra) # 800052c0 <fileclose>
    fileclose(wf);
    80006898:	fc843503          	ld	a0,-56(s0)
    8000689c:	fffff097          	auipc	ra,0xfffff
    800068a0:	a24080e7          	jalr	-1500(ra) # 800052c0 <fileclose>
    return -1;
    800068a4:	57fd                	li	a5,-1
    800068a6:	a03d                	j	800068d4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800068a8:	fc442783          	lw	a5,-60(s0)
    800068ac:	0007c763          	bltz	a5,800068ba <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800068b0:	07e9                	add	a5,a5,26
    800068b2:	078e                	sll	a5,a5,0x3
    800068b4:	97a6                	add	a5,a5,s1
    800068b6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800068ba:	fd043503          	ld	a0,-48(s0)
    800068be:	fffff097          	auipc	ra,0xfffff
    800068c2:	a02080e7          	jalr	-1534(ra) # 800052c0 <fileclose>
    fileclose(wf);
    800068c6:	fc843503          	ld	a0,-56(s0)
    800068ca:	fffff097          	auipc	ra,0xfffff
    800068ce:	9f6080e7          	jalr	-1546(ra) # 800052c0 <fileclose>
    return -1;
    800068d2:	57fd                	li	a5,-1
}
    800068d4:	853e                	mv	a0,a5
    800068d6:	70e2                	ld	ra,56(sp)
    800068d8:	7442                	ld	s0,48(sp)
    800068da:	74a2                	ld	s1,40(sp)
    800068dc:	6121                	add	sp,sp,64
    800068de:	8082                	ret

00000000800068e0 <kernelvec>:
    800068e0:	7111                	add	sp,sp,-256
    800068e2:	e006                	sd	ra,0(sp)
    800068e4:	e40a                	sd	sp,8(sp)
    800068e6:	e80e                	sd	gp,16(sp)
    800068e8:	ec12                	sd	tp,24(sp)
    800068ea:	f016                	sd	t0,32(sp)
    800068ec:	f41a                	sd	t1,40(sp)
    800068ee:	f81e                	sd	t2,48(sp)
    800068f0:	fc22                	sd	s0,56(sp)
    800068f2:	e0a6                	sd	s1,64(sp)
    800068f4:	e4aa                	sd	a0,72(sp)
    800068f6:	e8ae                	sd	a1,80(sp)
    800068f8:	ecb2                	sd	a2,88(sp)
    800068fa:	f0b6                	sd	a3,96(sp)
    800068fc:	f4ba                	sd	a4,104(sp)
    800068fe:	f8be                	sd	a5,112(sp)
    80006900:	fcc2                	sd	a6,120(sp)
    80006902:	e146                	sd	a7,128(sp)
    80006904:	e54a                	sd	s2,136(sp)
    80006906:	e94e                	sd	s3,144(sp)
    80006908:	ed52                	sd	s4,152(sp)
    8000690a:	f156                	sd	s5,160(sp)
    8000690c:	f55a                	sd	s6,168(sp)
    8000690e:	f95e                	sd	s7,176(sp)
    80006910:	fd62                	sd	s8,184(sp)
    80006912:	e1e6                	sd	s9,192(sp)
    80006914:	e5ea                	sd	s10,200(sp)
    80006916:	e9ee                	sd	s11,208(sp)
    80006918:	edf2                	sd	t3,216(sp)
    8000691a:	f1f6                	sd	t4,224(sp)
    8000691c:	f5fa                	sd	t5,232(sp)
    8000691e:	f9fe                	sd	t6,240(sp)
    80006920:	c15fc0ef          	jal	80003534 <kerneltrap>
    80006924:	6082                	ld	ra,0(sp)
    80006926:	6122                	ld	sp,8(sp)
    80006928:	61c2                	ld	gp,16(sp)
    8000692a:	7282                	ld	t0,32(sp)
    8000692c:	7322                	ld	t1,40(sp)
    8000692e:	73c2                	ld	t2,48(sp)
    80006930:	7462                	ld	s0,56(sp)
    80006932:	6486                	ld	s1,64(sp)
    80006934:	6526                	ld	a0,72(sp)
    80006936:	65c6                	ld	a1,80(sp)
    80006938:	6666                	ld	a2,88(sp)
    8000693a:	7686                	ld	a3,96(sp)
    8000693c:	7726                	ld	a4,104(sp)
    8000693e:	77c6                	ld	a5,112(sp)
    80006940:	7866                	ld	a6,120(sp)
    80006942:	688a                	ld	a7,128(sp)
    80006944:	692a                	ld	s2,136(sp)
    80006946:	69ca                	ld	s3,144(sp)
    80006948:	6a6a                	ld	s4,152(sp)
    8000694a:	7a8a                	ld	s5,160(sp)
    8000694c:	7b2a                	ld	s6,168(sp)
    8000694e:	7bca                	ld	s7,176(sp)
    80006950:	7c6a                	ld	s8,184(sp)
    80006952:	6c8e                	ld	s9,192(sp)
    80006954:	6d2e                	ld	s10,200(sp)
    80006956:	6dce                	ld	s11,208(sp)
    80006958:	6e6e                	ld	t3,216(sp)
    8000695a:	7e8e                	ld	t4,224(sp)
    8000695c:	7f2e                	ld	t5,232(sp)
    8000695e:	7fce                	ld	t6,240(sp)
    80006960:	6111                	add	sp,sp,256
    80006962:	10200073          	sret
    80006966:	00000013          	nop
    8000696a:	00000013          	nop
    8000696e:	0001                	nop

0000000080006970 <timervec>:
    80006970:	34051573          	csrrw	a0,mscratch,a0
    80006974:	e10c                	sd	a1,0(a0)
    80006976:	e510                	sd	a2,8(a0)
    80006978:	e914                	sd	a3,16(a0)
    8000697a:	6d0c                	ld	a1,24(a0)
    8000697c:	7110                	ld	a2,32(a0)
    8000697e:	6194                	ld	a3,0(a1)
    80006980:	96b2                	add	a3,a3,a2
    80006982:	e194                	sd	a3,0(a1)
    80006984:	4589                	li	a1,2
    80006986:	14459073          	csrw	sip,a1
    8000698a:	6914                	ld	a3,16(a0)
    8000698c:	6510                	ld	a2,8(a0)
    8000698e:	610c                	ld	a1,0(a0)
    80006990:	34051573          	csrrw	a0,mscratch,a0
    80006994:	30200073          	mret
	...

000000008000699a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000699a:	1141                	add	sp,sp,-16
    8000699c:	e422                	sd	s0,8(sp)
    8000699e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800069a0:	0c0007b7          	lui	a5,0xc000
    800069a4:	4705                	li	a4,1
    800069a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800069a8:	c3d8                	sw	a4,4(a5)
}
    800069aa:	6422                	ld	s0,8(sp)
    800069ac:	0141                	add	sp,sp,16
    800069ae:	8082                	ret

00000000800069b0 <plicinithart>:

void
plicinithart(void)
{
    800069b0:	1141                	add	sp,sp,-16
    800069b2:	e406                	sd	ra,8(sp)
    800069b4:	e022                	sd	s0,0(sp)
    800069b6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800069b8:	ffffb097          	auipc	ra,0xffffb
    800069bc:	fd2080e7          	jalr	-46(ra) # 8000198a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800069c0:	0085171b          	sllw	a4,a0,0x8
    800069c4:	0c0027b7          	lui	a5,0xc002
    800069c8:	97ba                	add	a5,a5,a4
    800069ca:	40200713          	li	a4,1026
    800069ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800069d2:	00d5151b          	sllw	a0,a0,0xd
    800069d6:	0c2017b7          	lui	a5,0xc201
    800069da:	97aa                	add	a5,a5,a0
    800069dc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800069e0:	60a2                	ld	ra,8(sp)
    800069e2:	6402                	ld	s0,0(sp)
    800069e4:	0141                	add	sp,sp,16
    800069e6:	8082                	ret

00000000800069e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800069e8:	1141                	add	sp,sp,-16
    800069ea:	e406                	sd	ra,8(sp)
    800069ec:	e022                	sd	s0,0(sp)
    800069ee:	0800                	add	s0,sp,16
  int hart = cpuid();
    800069f0:	ffffb097          	auipc	ra,0xffffb
    800069f4:	f9a080e7          	jalr	-102(ra) # 8000198a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800069f8:	00d5151b          	sllw	a0,a0,0xd
    800069fc:	0c2017b7          	lui	a5,0xc201
    80006a00:	97aa                	add	a5,a5,a0
  return irq;
}
    80006a02:	43c8                	lw	a0,4(a5)
    80006a04:	60a2                	ld	ra,8(sp)
    80006a06:	6402                	ld	s0,0(sp)
    80006a08:	0141                	add	sp,sp,16
    80006a0a:	8082                	ret

0000000080006a0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006a0c:	1101                	add	sp,sp,-32
    80006a0e:	ec06                	sd	ra,24(sp)
    80006a10:	e822                	sd	s0,16(sp)
    80006a12:	e426                	sd	s1,8(sp)
    80006a14:	1000                	add	s0,sp,32
    80006a16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006a18:	ffffb097          	auipc	ra,0xffffb
    80006a1c:	f72080e7          	jalr	-142(ra) # 8000198a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006a20:	00d5151b          	sllw	a0,a0,0xd
    80006a24:	0c2017b7          	lui	a5,0xc201
    80006a28:	97aa                	add	a5,a5,a0
    80006a2a:	c3c4                	sw	s1,4(a5)
}
    80006a2c:	60e2                	ld	ra,24(sp)
    80006a2e:	6442                	ld	s0,16(sp)
    80006a30:	64a2                	ld	s1,8(sp)
    80006a32:	6105                	add	sp,sp,32
    80006a34:	8082                	ret

0000000080006a36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006a36:	1141                	add	sp,sp,-16
    80006a38:	e406                	sd	ra,8(sp)
    80006a3a:	e022                	sd	s0,0(sp)
    80006a3c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80006a3e:	479d                	li	a5,7
    80006a40:	04a7cc63          	blt	a5,a0,80006a98 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006a44:	0001f797          	auipc	a5,0x1f
    80006a48:	48c78793          	add	a5,a5,1164 # 80025ed0 <disk>
    80006a4c:	97aa                	add	a5,a5,a0
    80006a4e:	0187c783          	lbu	a5,24(a5)
    80006a52:	ebb9                	bnez	a5,80006aa8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006a54:	00451693          	sll	a3,a0,0x4
    80006a58:	0001f797          	auipc	a5,0x1f
    80006a5c:	47878793          	add	a5,a5,1144 # 80025ed0 <disk>
    80006a60:	6398                	ld	a4,0(a5)
    80006a62:	9736                	add	a4,a4,a3
    80006a64:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006a68:	6398                	ld	a4,0(a5)
    80006a6a:	9736                	add	a4,a4,a3
    80006a6c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006a70:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006a74:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006a78:	97aa                	add	a5,a5,a0
    80006a7a:	4705                	li	a4,1
    80006a7c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006a80:	0001f517          	auipc	a0,0x1f
    80006a84:	46850513          	add	a0,a0,1128 # 80025ee8 <disk+0x18>
    80006a88:	ffffc097          	auipc	ra,0xffffc
    80006a8c:	d1e080e7          	jalr	-738(ra) # 800027a6 <wakeup>
}
    80006a90:	60a2                	ld	ra,8(sp)
    80006a92:	6402                	ld	s0,0(sp)
    80006a94:	0141                	add	sp,sp,16
    80006a96:	8082                	ret
    panic("free_desc 1");
    80006a98:	00002517          	auipc	a0,0x2
    80006a9c:	d9850513          	add	a0,a0,-616 # 80008830 <syscalls+0x338>
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	a9c080e7          	jalr	-1380(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006aa8:	00002517          	auipc	a0,0x2
    80006aac:	d9850513          	add	a0,a0,-616 # 80008840 <syscalls+0x348>
    80006ab0:	ffffa097          	auipc	ra,0xffffa
    80006ab4:	a8c080e7          	jalr	-1396(ra) # 8000053c <panic>

0000000080006ab8 <virtio_disk_init>:
{
    80006ab8:	1101                	add	sp,sp,-32
    80006aba:	ec06                	sd	ra,24(sp)
    80006abc:	e822                	sd	s0,16(sp)
    80006abe:	e426                	sd	s1,8(sp)
    80006ac0:	e04a                	sd	s2,0(sp)
    80006ac2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006ac4:	00002597          	auipc	a1,0x2
    80006ac8:	d8c58593          	add	a1,a1,-628 # 80008850 <syscalls+0x358>
    80006acc:	0001f517          	auipc	a0,0x1f
    80006ad0:	52c50513          	add	a0,a0,1324 # 80025ff8 <disk+0x128>
    80006ad4:	ffffa097          	auipc	ra,0xffffa
    80006ad8:	06e080e7          	jalr	110(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006adc:	100017b7          	lui	a5,0x10001
    80006ae0:	4398                	lw	a4,0(a5)
    80006ae2:	2701                	sext.w	a4,a4
    80006ae4:	747277b7          	lui	a5,0x74727
    80006ae8:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006aec:	14f71b63          	bne	a4,a5,80006c42 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006af0:	100017b7          	lui	a5,0x10001
    80006af4:	43dc                	lw	a5,4(a5)
    80006af6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006af8:	4709                	li	a4,2
    80006afa:	14e79463          	bne	a5,a4,80006c42 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006afe:	100017b7          	lui	a5,0x10001
    80006b02:	479c                	lw	a5,8(a5)
    80006b04:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006b06:	12e79e63          	bne	a5,a4,80006c42 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006b0a:	100017b7          	lui	a5,0x10001
    80006b0e:	47d8                	lw	a4,12(a5)
    80006b10:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b12:	554d47b7          	lui	a5,0x554d4
    80006b16:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006b1a:	12f71463          	bne	a4,a5,80006c42 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b1e:	100017b7          	lui	a5,0x10001
    80006b22:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b26:	4705                	li	a4,1
    80006b28:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b2a:	470d                	li	a4,3
    80006b2c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006b2e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006b30:	c7ffe6b7          	lui	a3,0xc7ffe
    80006b34:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd874f>
    80006b38:	8f75                	and	a4,a4,a3
    80006b3a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b3c:	472d                	li	a4,11
    80006b3e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006b40:	5bbc                	lw	a5,112(a5)
    80006b42:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006b46:	8ba1                	and	a5,a5,8
    80006b48:	10078563          	beqz	a5,80006c52 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006b4c:	100017b7          	lui	a5,0x10001
    80006b50:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006b54:	43fc                	lw	a5,68(a5)
    80006b56:	2781                	sext.w	a5,a5
    80006b58:	10079563          	bnez	a5,80006c62 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b5c:	100017b7          	lui	a5,0x10001
    80006b60:	5bdc                	lw	a5,52(a5)
    80006b62:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b64:	10078763          	beqz	a5,80006c72 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006b68:	471d                	li	a4,7
    80006b6a:	10f77c63          	bgeu	a4,a5,80006c82 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80006b6e:	ffffa097          	auipc	ra,0xffffa
    80006b72:	f74080e7          	jalr	-140(ra) # 80000ae2 <kalloc>
    80006b76:	0001f497          	auipc	s1,0x1f
    80006b7a:	35a48493          	add	s1,s1,858 # 80025ed0 <disk>
    80006b7e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006b80:	ffffa097          	auipc	ra,0xffffa
    80006b84:	f62080e7          	jalr	-158(ra) # 80000ae2 <kalloc>
    80006b88:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006b8a:	ffffa097          	auipc	ra,0xffffa
    80006b8e:	f58080e7          	jalr	-168(ra) # 80000ae2 <kalloc>
    80006b92:	87aa                	mv	a5,a0
    80006b94:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006b96:	6088                	ld	a0,0(s1)
    80006b98:	cd6d                	beqz	a0,80006c92 <virtio_disk_init+0x1da>
    80006b9a:	0001f717          	auipc	a4,0x1f
    80006b9e:	33e73703          	ld	a4,830(a4) # 80025ed8 <disk+0x8>
    80006ba2:	cb65                	beqz	a4,80006c92 <virtio_disk_init+0x1da>
    80006ba4:	c7fd                	beqz	a5,80006c92 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006ba6:	6605                	lui	a2,0x1
    80006ba8:	4581                	li	a1,0
    80006baa:	ffffa097          	auipc	ra,0xffffa
    80006bae:	124080e7          	jalr	292(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006bb2:	0001f497          	auipc	s1,0x1f
    80006bb6:	31e48493          	add	s1,s1,798 # 80025ed0 <disk>
    80006bba:	6605                	lui	a2,0x1
    80006bbc:	4581                	li	a1,0
    80006bbe:	6488                	ld	a0,8(s1)
    80006bc0:	ffffa097          	auipc	ra,0xffffa
    80006bc4:	10e080e7          	jalr	270(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006bc8:	6605                	lui	a2,0x1
    80006bca:	4581                	li	a1,0
    80006bcc:	6888                	ld	a0,16(s1)
    80006bce:	ffffa097          	auipc	ra,0xffffa
    80006bd2:	100080e7          	jalr	256(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006bd6:	100017b7          	lui	a5,0x10001
    80006bda:	4721                	li	a4,8
    80006bdc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006bde:	4098                	lw	a4,0(s1)
    80006be0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006be4:	40d8                	lw	a4,4(s1)
    80006be6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006bea:	6498                	ld	a4,8(s1)
    80006bec:	0007069b          	sext.w	a3,a4
    80006bf0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006bf4:	9701                	sra	a4,a4,0x20
    80006bf6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006bfa:	6898                	ld	a4,16(s1)
    80006bfc:	0007069b          	sext.w	a3,a4
    80006c00:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006c04:	9701                	sra	a4,a4,0x20
    80006c06:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006c0a:	4705                	li	a4,1
    80006c0c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006c0e:	00e48c23          	sb	a4,24(s1)
    80006c12:	00e48ca3          	sb	a4,25(s1)
    80006c16:	00e48d23          	sb	a4,26(s1)
    80006c1a:	00e48da3          	sb	a4,27(s1)
    80006c1e:	00e48e23          	sb	a4,28(s1)
    80006c22:	00e48ea3          	sb	a4,29(s1)
    80006c26:	00e48f23          	sb	a4,30(s1)
    80006c2a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006c2e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c32:	0727a823          	sw	s2,112(a5)
}
    80006c36:	60e2                	ld	ra,24(sp)
    80006c38:	6442                	ld	s0,16(sp)
    80006c3a:	64a2                	ld	s1,8(sp)
    80006c3c:	6902                	ld	s2,0(sp)
    80006c3e:	6105                	add	sp,sp,32
    80006c40:	8082                	ret
    panic("could not find virtio disk");
    80006c42:	00002517          	auipc	a0,0x2
    80006c46:	c1e50513          	add	a0,a0,-994 # 80008860 <syscalls+0x368>
    80006c4a:	ffffa097          	auipc	ra,0xffffa
    80006c4e:	8f2080e7          	jalr	-1806(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006c52:	00002517          	auipc	a0,0x2
    80006c56:	c2e50513          	add	a0,a0,-978 # 80008880 <syscalls+0x388>
    80006c5a:	ffffa097          	auipc	ra,0xffffa
    80006c5e:	8e2080e7          	jalr	-1822(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006c62:	00002517          	auipc	a0,0x2
    80006c66:	c3e50513          	add	a0,a0,-962 # 800088a0 <syscalls+0x3a8>
    80006c6a:	ffffa097          	auipc	ra,0xffffa
    80006c6e:	8d2080e7          	jalr	-1838(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006c72:	00002517          	auipc	a0,0x2
    80006c76:	c4e50513          	add	a0,a0,-946 # 800088c0 <syscalls+0x3c8>
    80006c7a:	ffffa097          	auipc	ra,0xffffa
    80006c7e:	8c2080e7          	jalr	-1854(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006c82:	00002517          	auipc	a0,0x2
    80006c86:	c5e50513          	add	a0,a0,-930 # 800088e0 <syscalls+0x3e8>
    80006c8a:	ffffa097          	auipc	ra,0xffffa
    80006c8e:	8b2080e7          	jalr	-1870(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006c92:	00002517          	auipc	a0,0x2
    80006c96:	c6e50513          	add	a0,a0,-914 # 80008900 <syscalls+0x408>
    80006c9a:	ffffa097          	auipc	ra,0xffffa
    80006c9e:	8a2080e7          	jalr	-1886(ra) # 8000053c <panic>

0000000080006ca2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006ca2:	7159                	add	sp,sp,-112
    80006ca4:	f486                	sd	ra,104(sp)
    80006ca6:	f0a2                	sd	s0,96(sp)
    80006ca8:	eca6                	sd	s1,88(sp)
    80006caa:	e8ca                	sd	s2,80(sp)
    80006cac:	e4ce                	sd	s3,72(sp)
    80006cae:	e0d2                	sd	s4,64(sp)
    80006cb0:	fc56                	sd	s5,56(sp)
    80006cb2:	f85a                	sd	s6,48(sp)
    80006cb4:	f45e                	sd	s7,40(sp)
    80006cb6:	f062                	sd	s8,32(sp)
    80006cb8:	ec66                	sd	s9,24(sp)
    80006cba:	e86a                	sd	s10,16(sp)
    80006cbc:	1880                	add	s0,sp,112
    80006cbe:	8a2a                	mv	s4,a0
    80006cc0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006cc2:	00c52c83          	lw	s9,12(a0)
    80006cc6:	001c9c9b          	sllw	s9,s9,0x1
    80006cca:	1c82                	sll	s9,s9,0x20
    80006ccc:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006cd0:	0001f517          	auipc	a0,0x1f
    80006cd4:	32850513          	add	a0,a0,808 # 80025ff8 <disk+0x128>
    80006cd8:	ffffa097          	auipc	ra,0xffffa
    80006cdc:	efa080e7          	jalr	-262(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006ce0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006ce2:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006ce4:	0001fb17          	auipc	s6,0x1f
    80006ce8:	1ecb0b13          	add	s6,s6,492 # 80025ed0 <disk>
  for(int i = 0; i < 3; i++){
    80006cec:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006cee:	0001fc17          	auipc	s8,0x1f
    80006cf2:	30ac0c13          	add	s8,s8,778 # 80025ff8 <disk+0x128>
    80006cf6:	a095                	j	80006d5a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006cf8:	00fb0733          	add	a4,s6,a5
    80006cfc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006d00:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006d02:	0207c563          	bltz	a5,80006d2c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006d06:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006d08:	0591                	add	a1,a1,4
    80006d0a:	05560d63          	beq	a2,s5,80006d64 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006d0e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006d10:	0001f717          	auipc	a4,0x1f
    80006d14:	1c070713          	add	a4,a4,448 # 80025ed0 <disk>
    80006d18:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80006d1a:	01874683          	lbu	a3,24(a4)
    80006d1e:	fee9                	bnez	a3,80006cf8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006d20:	2785                	addw	a5,a5,1
    80006d22:	0705                	add	a4,a4,1
    80006d24:	fe979be3          	bne	a5,s1,80006d1a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006d28:	57fd                	li	a5,-1
    80006d2a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80006d2c:	00c05e63          	blez	a2,80006d48 <virtio_disk_rw+0xa6>
    80006d30:	060a                	sll	a2,a2,0x2
    80006d32:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006d36:	0009a503          	lw	a0,0(s3)
    80006d3a:	00000097          	auipc	ra,0x0
    80006d3e:	cfc080e7          	jalr	-772(ra) # 80006a36 <free_desc>
      for(int j = 0; j < i; j++)
    80006d42:	0991                	add	s3,s3,4
    80006d44:	ffa999e3          	bne	s3,s10,80006d36 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d48:	85e2                	mv	a1,s8
    80006d4a:	0001f517          	auipc	a0,0x1f
    80006d4e:	19e50513          	add	a0,a0,414 # 80025ee8 <disk+0x18>
    80006d52:	ffffc097          	auipc	ra,0xffffc
    80006d56:	9f0080e7          	jalr	-1552(ra) # 80002742 <sleep>
  for(int i = 0; i < 3; i++){
    80006d5a:	f9040993          	add	s3,s0,-112
{
    80006d5e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006d60:	864a                	mv	a2,s2
    80006d62:	b775                	j	80006d0e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d64:	f9042503          	lw	a0,-112(s0)
    80006d68:	00a50713          	add	a4,a0,10
    80006d6c:	0712                	sll	a4,a4,0x4

  if(write)
    80006d6e:	0001f797          	auipc	a5,0x1f
    80006d72:	16278793          	add	a5,a5,354 # 80025ed0 <disk>
    80006d76:	00e786b3          	add	a3,a5,a4
    80006d7a:	01703633          	snez	a2,s7
    80006d7e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006d80:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006d84:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d88:	f6070613          	add	a2,a4,-160
    80006d8c:	6394                	ld	a3,0(a5)
    80006d8e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d90:	00870593          	add	a1,a4,8
    80006d94:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d96:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006d98:	0007b803          	ld	a6,0(a5)
    80006d9c:	9642                	add	a2,a2,a6
    80006d9e:	46c1                	li	a3,16
    80006da0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006da2:	4585                	li	a1,1
    80006da4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006da8:	f9442683          	lw	a3,-108(s0)
    80006dac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006db0:	0692                	sll	a3,a3,0x4
    80006db2:	9836                	add	a6,a6,a3
    80006db4:	058a0613          	add	a2,s4,88
    80006db8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006dbc:	0007b803          	ld	a6,0(a5)
    80006dc0:	96c2                	add	a3,a3,a6
    80006dc2:	40000613          	li	a2,1024
    80006dc6:	c690                	sw	a2,8(a3)
  if(write)
    80006dc8:	001bb613          	seqz	a2,s7
    80006dcc:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006dd0:	00166613          	or	a2,a2,1
    80006dd4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006dd8:	f9842603          	lw	a2,-104(s0)
    80006ddc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006de0:	00250693          	add	a3,a0,2
    80006de4:	0692                	sll	a3,a3,0x4
    80006de6:	96be                	add	a3,a3,a5
    80006de8:	58fd                	li	a7,-1
    80006dea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006dee:	0612                	sll	a2,a2,0x4
    80006df0:	9832                	add	a6,a6,a2
    80006df2:	f9070713          	add	a4,a4,-112
    80006df6:	973e                	add	a4,a4,a5
    80006df8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006dfc:	6398                	ld	a4,0(a5)
    80006dfe:	9732                	add	a4,a4,a2
    80006e00:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e02:	4609                	li	a2,2
    80006e04:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006e08:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e0c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006e10:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006e14:	6794                	ld	a3,8(a5)
    80006e16:	0026d703          	lhu	a4,2(a3)
    80006e1a:	8b1d                	and	a4,a4,7
    80006e1c:	0706                	sll	a4,a4,0x1
    80006e1e:	96ba                	add	a3,a3,a4
    80006e20:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006e24:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006e28:	6798                	ld	a4,8(a5)
    80006e2a:	00275783          	lhu	a5,2(a4)
    80006e2e:	2785                	addw	a5,a5,1
    80006e30:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006e34:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006e38:	100017b7          	lui	a5,0x10001
    80006e3c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006e40:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006e44:	0001f917          	auipc	s2,0x1f
    80006e48:	1b490913          	add	s2,s2,436 # 80025ff8 <disk+0x128>
  while(b->disk == 1) {
    80006e4c:	4485                	li	s1,1
    80006e4e:	00b79c63          	bne	a5,a1,80006e66 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006e52:	85ca                	mv	a1,s2
    80006e54:	8552                	mv	a0,s4
    80006e56:	ffffc097          	auipc	ra,0xffffc
    80006e5a:	8ec080e7          	jalr	-1812(ra) # 80002742 <sleep>
  while(b->disk == 1) {
    80006e5e:	004a2783          	lw	a5,4(s4)
    80006e62:	fe9788e3          	beq	a5,s1,80006e52 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006e66:	f9042903          	lw	s2,-112(s0)
    80006e6a:	00290713          	add	a4,s2,2
    80006e6e:	0712                	sll	a4,a4,0x4
    80006e70:	0001f797          	auipc	a5,0x1f
    80006e74:	06078793          	add	a5,a5,96 # 80025ed0 <disk>
    80006e78:	97ba                	add	a5,a5,a4
    80006e7a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006e7e:	0001f997          	auipc	s3,0x1f
    80006e82:	05298993          	add	s3,s3,82 # 80025ed0 <disk>
    80006e86:	00491713          	sll	a4,s2,0x4
    80006e8a:	0009b783          	ld	a5,0(s3)
    80006e8e:	97ba                	add	a5,a5,a4
    80006e90:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e94:	854a                	mv	a0,s2
    80006e96:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e9a:	00000097          	auipc	ra,0x0
    80006e9e:	b9c080e7          	jalr	-1124(ra) # 80006a36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ea2:	8885                	and	s1,s1,1
    80006ea4:	f0ed                	bnez	s1,80006e86 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006ea6:	0001f517          	auipc	a0,0x1f
    80006eaa:	15250513          	add	a0,a0,338 # 80025ff8 <disk+0x128>
    80006eae:	ffffa097          	auipc	ra,0xffffa
    80006eb2:	dd8080e7          	jalr	-552(ra) # 80000c86 <release>
}
    80006eb6:	70a6                	ld	ra,104(sp)
    80006eb8:	7406                	ld	s0,96(sp)
    80006eba:	64e6                	ld	s1,88(sp)
    80006ebc:	6946                	ld	s2,80(sp)
    80006ebe:	69a6                	ld	s3,72(sp)
    80006ec0:	6a06                	ld	s4,64(sp)
    80006ec2:	7ae2                	ld	s5,56(sp)
    80006ec4:	7b42                	ld	s6,48(sp)
    80006ec6:	7ba2                	ld	s7,40(sp)
    80006ec8:	7c02                	ld	s8,32(sp)
    80006eca:	6ce2                	ld	s9,24(sp)
    80006ecc:	6d42                	ld	s10,16(sp)
    80006ece:	6165                	add	sp,sp,112
    80006ed0:	8082                	ret

0000000080006ed2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ed2:	1101                	add	sp,sp,-32
    80006ed4:	ec06                	sd	ra,24(sp)
    80006ed6:	e822                	sd	s0,16(sp)
    80006ed8:	e426                	sd	s1,8(sp)
    80006eda:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006edc:	0001f497          	auipc	s1,0x1f
    80006ee0:	ff448493          	add	s1,s1,-12 # 80025ed0 <disk>
    80006ee4:	0001f517          	auipc	a0,0x1f
    80006ee8:	11450513          	add	a0,a0,276 # 80025ff8 <disk+0x128>
    80006eec:	ffffa097          	auipc	ra,0xffffa
    80006ef0:	ce6080e7          	jalr	-794(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ef4:	10001737          	lui	a4,0x10001
    80006ef8:	533c                	lw	a5,96(a4)
    80006efa:	8b8d                	and	a5,a5,3
    80006efc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006efe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006f02:	689c                	ld	a5,16(s1)
    80006f04:	0204d703          	lhu	a4,32(s1)
    80006f08:	0027d783          	lhu	a5,2(a5)
    80006f0c:	04f70863          	beq	a4,a5,80006f5c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006f10:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006f14:	6898                	ld	a4,16(s1)
    80006f16:	0204d783          	lhu	a5,32(s1)
    80006f1a:	8b9d                	and	a5,a5,7
    80006f1c:	078e                	sll	a5,a5,0x3
    80006f1e:	97ba                	add	a5,a5,a4
    80006f20:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006f22:	00278713          	add	a4,a5,2
    80006f26:	0712                	sll	a4,a4,0x4
    80006f28:	9726                	add	a4,a4,s1
    80006f2a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006f2e:	e721                	bnez	a4,80006f76 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006f30:	0789                	add	a5,a5,2
    80006f32:	0792                	sll	a5,a5,0x4
    80006f34:	97a6                	add	a5,a5,s1
    80006f36:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006f38:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006f3c:	ffffc097          	auipc	ra,0xffffc
    80006f40:	86a080e7          	jalr	-1942(ra) # 800027a6 <wakeup>

    disk.used_idx += 1;
    80006f44:	0204d783          	lhu	a5,32(s1)
    80006f48:	2785                	addw	a5,a5,1
    80006f4a:	17c2                	sll	a5,a5,0x30
    80006f4c:	93c1                	srl	a5,a5,0x30
    80006f4e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f52:	6898                	ld	a4,16(s1)
    80006f54:	00275703          	lhu	a4,2(a4)
    80006f58:	faf71ce3          	bne	a4,a5,80006f10 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006f5c:	0001f517          	auipc	a0,0x1f
    80006f60:	09c50513          	add	a0,a0,156 # 80025ff8 <disk+0x128>
    80006f64:	ffffa097          	auipc	ra,0xffffa
    80006f68:	d22080e7          	jalr	-734(ra) # 80000c86 <release>
}
    80006f6c:	60e2                	ld	ra,24(sp)
    80006f6e:	6442                	ld	s0,16(sp)
    80006f70:	64a2                	ld	s1,8(sp)
    80006f72:	6105                	add	sp,sp,32
    80006f74:	8082                	ret
      panic("virtio_disk_intr status");
    80006f76:	00002517          	auipc	a0,0x2
    80006f7a:	9a250513          	add	a0,a0,-1630 # 80008918 <syscalls+0x420>
    80006f7e:	ffff9097          	auipc	ra,0xffff9
    80006f82:	5be080e7          	jalr	1470(ra) # 8000053c <panic>
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
