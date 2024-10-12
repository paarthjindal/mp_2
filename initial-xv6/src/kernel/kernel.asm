
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	93070713          	add	a4,a4,-1744 # 80008980 <timer_scratch>
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
    80000066:	38e78793          	add	a5,a5,910 # 800063f0 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd8c6f>
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
    8000012e:	83c080e7          	jalr	-1988(ra) # 80002966 <either_copyin>
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
    80000188:	93c50513          	add	a0,a0,-1732 # 80010ac0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	92c48493          	add	s1,s1,-1748 # 80010ac0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	9bc90913          	add	s2,s2,-1604 # 80010b58 <cons+0x98>
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
    800001c0:	5dc080e7          	jalr	1500(ra) # 80002798 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	31a080e7          	jalr	794(ra) # 800024e4 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8e270713          	add	a4,a4,-1822 # 80010ac0 <cons>
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
    80000210:	00002097          	auipc	ra,0x2
    80000214:	700080e7          	jalr	1792(ra) # 80002910 <either_copyout>
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
    8000022c:	89850513          	add	a0,a0,-1896 # 80010ac0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	88250513          	add	a0,a0,-1918 # 80010ac0 <cons>
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
    80000272:	8ef72523          	sw	a5,-1814(a4) # 80010b58 <cons+0x98>
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
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	7f850513          	add	a0,a0,2040 # 80010ac0 <cons>
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
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	6ce080e7          	jalr	1742(ra) # 800029bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7ca50513          	add	a0,a0,1994 # 80010ac0 <cons>
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
    8000031e:	7a670713          	add	a4,a4,1958 # 80010ac0 <cons>
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
    80000348:	77c78793          	add	a5,a5,1916 # 80010ac0 <cons>
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
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7e67a783          	lw	a5,2022(a5) # 80010b58 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	73a70713          	add	a4,a4,1850 # 80010ac0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	72a48493          	add	s1,s1,1834 # 80010ac0 <cons>
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
    800003d6:	6ee70713          	add	a4,a4,1774 # 80010ac0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	76f72c23          	sw	a5,1912(a4) # 80010b60 <cons+0xa0>
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
    80000412:	6b278793          	add	a5,a5,1714 # 80010ac0 <cons>
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
    80000436:	72c7a523          	sw	a2,1834(a5) # 80010b5c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	71e50513          	add	a0,a0,1822 # 80010b58 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	106080e7          	jalr	262(ra) # 80002548 <wakeup>
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
    80000460:	66450513          	add	a0,a0,1636 # 80010ac0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00024797          	auipc	a5,0x24
    80000478:	58478793          	add	a5,a5,1412 # 800249f8 <devsw>
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
    8000054c:	6207ac23          	sw	zero,1592(a5) # 80010b80 <pr+0x18>
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
    80000580:	3cf72223          	sw	a5,964(a4) # 80008940 <panicked>
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
    800005bc:	5c8dad83          	lw	s11,1480(s11) # 80010b80 <pr+0x18>
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
    800005fa:	57250513          	add	a0,a0,1394 # 80010b68 <pr>
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
    80000758:	41450513          	add	a0,a0,1044 # 80010b68 <pr>
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
    80000774:	3f848493          	add	s1,s1,1016 # 80010b68 <pr>
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
    800007d4:	3b850513          	add	a0,a0,952 # 80010b88 <uart_tx_lock>
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
    80000800:	1447a783          	lw	a5,324(a5) # 80008940 <panicked>
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
    80000838:	1147b783          	ld	a5,276(a5) # 80008948 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	11473703          	ld	a4,276(a4) # 80008950 <uart_tx_w>
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
    80000862:	32aa0a13          	add	s4,s4,810 # 80010b88 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0e248493          	add	s1,s1,226 # 80008948 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0e298993          	add	s3,s3,226 # 80008950 <uart_tx_w>
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
    80000894:	cb8080e7          	jalr	-840(ra) # 80002548 <wakeup>
    
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
    800008d0:	2bc50513          	add	a0,a0,700 # 80010b88 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0647a783          	lw	a5,100(a5) # 80008940 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	06a73703          	ld	a4,106(a4) # 80008950 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	05a7b783          	ld	a5,90(a5) # 80008948 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	28e98993          	add	s3,s3,654 # 80010b88 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	04648493          	add	s1,s1,70 # 80008948 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	04690913          	add	s2,s2,70 # 80008950 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	bca080e7          	jalr	-1078(ra) # 800024e4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	25848493          	add	s1,s1,600 # 80010b88 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	00e7b623          	sd	a4,12(a5) # 80008950 <uart_tx_w>
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
    800009ba:	1d248493          	add	s1,s1,466 # 80010b88 <uart_tx_lock>
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
    800009fc:	19878793          	add	a5,a5,408 # 80025b90 <end>
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
    80000a1c:	1a890913          	add	s2,s2,424 # 80010bc0 <kmem>
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
    80000aba:	10a50513          	add	a0,a0,266 # 80010bc0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00025517          	auipc	a0,0x25
    80000ace:	0c650513          	add	a0,a0,198 # 80025b90 <end>
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
    80000af0:	0d448493          	add	s1,s1,212 # 80010bc0 <kmem>
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
    80000b08:	0bc50513          	add	a0,a0,188 # 80010bc0 <kmem>
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
    80000b34:	09050513          	add	a0,a0,144 # 80010bc0 <kmem>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9471>
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
    80000e86:	ad670713          	add	a4,a4,-1322 # 80008958 <started>
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
    80000ebc:	df0080e7          	jalr	-528(ra) # 80002ca8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	570080e7          	jalr	1392(ra) # 80006430 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	4ea080e7          	jalr	1258(ra) # 800023b2 <scheduler>
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
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	d50080e7          	jalr	-688(ra) # 80002c80 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	d70080e7          	jalr	-656(ra) # 80002ca8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	4da080e7          	jalr	1242(ra) # 8000641a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	4e8080e7          	jalr	1256(ra) # 80006430 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	6e6080e7          	jalr	1766(ra) # 80003636 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	d84080e7          	jalr	-636(ra) # 80003cdc <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	cfa080e7          	jalr	-774(ra) # 80004c5a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	5d0080e7          	jalr	1488(ra) # 80006538 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d56080e7          	jalr	-682(ra) # 80001cc6 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9cf72d23          	sw	a5,-1574(a4) # 80008958 <started>
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
    80000f96:	9ce7b783          	ld	a5,-1586(a5) # 80008960 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd9467>
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
    80001252:	70a7b923          	sd	a0,1810(a5) # 80008960 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9470>
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

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
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
    8000184a:	76a48493          	add	s1,s1,1898 # 80011fb0 <proc>
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
    80001864:	f50a0a13          	add	s4,s4,-176 # 8001a7b0 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	8595                	sra	a1,a1,0x5
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
    8000189a:	22048493          	add	s1,s1,544
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
    800018e6:	2fe50513          	add	a0,a0,766 # 80010be0 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	2fe50513          	add	a0,a0,766 # 80010bf8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	00010497          	auipc	s1,0x10
    8000190e:	6a648493          	add	s1,s1,1702 # 80011fb0 <proc>
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
    80001930:	e8498993          	add	s3,s3,-380 # 8001a7b0 <tickslock>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	8795                	sra	a5,a5,0x5
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addw	a5,a5,1
    80001954:	00d7979b          	sllw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	22048493          	add	s1,s1,544
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
    8000199a:	27a50513          	add	a0,a0,634 # 80010c10 <cpus>
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
    800019c2:	22270713          	add	a4,a4,546 # 80010be0 <pid_lock>
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
    800019fa:	eca7a783          	lw	a5,-310(a5) # 800088c0 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	2c0080e7          	jalr	704(ra) # 80002cc0 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	ea07a823          	sw	zero,-336(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	242080e7          	jalr	578(ra) # 80003c5c <fsinit>
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
    80001a34:	1b090913          	add	s2,s2,432 # 80010be0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e8e78793          	add	a5,a5,-370 # 800088d0 <nextpid>
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
    80001bc0:	3f448493          	add	s1,s1,1012 # 80011fb0 <proc>
    80001bc4:	00019917          	auipc	s2,0x19
    80001bc8:	bec90913          	add	s2,s2,-1044 # 8001a7b0 <tickslock>
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
    80001be4:	22048493          	add	s1,s1,544
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001bec:	4481                	li	s1,0
    80001bee:	a869                	j	80001c88 <allocproc+0xd8>
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
    80001c1a:	d627e783          	lwu	a5,-670(a5) # 80008978 <ticks>
    80001c1e:	20f4bc23          	sd	a5,536(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	ec0080e7          	jalr	-320(ra) # 80000ae2 <kalloc>
    80001c2a:	892a                	mv	s2,a0
    80001c2c:	eca8                	sd	a0,88(s1)
    80001c2e:	c525                	beqz	a0,80001c96 <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	e38080e7          	jalr	-456(ra) # 80001a6a <proc_pagetable>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c3e:	c925                	beqz	a0,80001cae <allocproc+0xfe>
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
    80001c70:	d0c7a783          	lw	a5,-756(a5) # 80008978 <ticks>
    80001c74:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001c78:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001c7c:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001c80:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001c84:	2004a223          	sw	zero,516(s1)
}
    80001c88:	8526                	mv	a0,s1
    80001c8a:	60e2                	ld	ra,24(sp)
    80001c8c:	6442                	ld	s0,16(sp)
    80001c8e:	64a2                	ld	s1,8(sp)
    80001c90:	6902                	ld	s2,0(sp)
    80001c92:	6105                	add	sp,sp,32
    80001c94:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001c96:	8526                	mv	a0,s1
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	ec0080e7          	jalr	-320(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	fe4080e7          	jalr	-28(ra) # 80000c86 <release>
    return 0;
    80001caa:	84ca                	mv	s1,s2
    80001cac:	bff1                	j	80001c88 <allocproc+0xd8>
    freeproc(p);       // Clean up if allocation fails
    80001cae:	8526                	mv	a0,s1
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	ea8080e7          	jalr	-344(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	fcc080e7          	jalr	-52(ra) # 80000c86 <release>
    return 0;
    80001cc2:	84ca                	mv	s1,s2
    80001cc4:	b7d1                	j	80001c88 <allocproc+0xd8>

0000000080001cc6 <userinit>:
{
    80001cc6:	1101                	add	sp,sp,-32
    80001cc8:	ec06                	sd	ra,24(sp)
    80001cca:	e822                	sd	s0,16(sp)
    80001ccc:	e426                	sd	s1,8(sp)
    80001cce:	1000                	add	s0,sp,32
  p = allocproc();
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	ee0080e7          	jalr	-288(ra) # 80001bb0 <allocproc>
    80001cd8:	84aa                	mv	s1,a0
  initproc = p;
    80001cda:	00007797          	auipc	a5,0x7
    80001cde:	c8a7bb23          	sd	a0,-874(a5) # 80008970 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ce2:	03400613          	li	a2,52
    80001ce6:	00007597          	auipc	a1,0x7
    80001cea:	bfa58593          	add	a1,a1,-1030 # 800088e0 <initcode>
    80001cee:	6928                	ld	a0,80(a0)
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	660080e7          	jalr	1632(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cf8:	6785                	lui	a5,0x1
    80001cfa:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cfc:	6cb8                	ld	a4,88(s1)
    80001cfe:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d02:	6cb8                	ld	a4,88(s1)
    80001d04:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d06:	4641                	li	a2,16
    80001d08:	00006597          	auipc	a1,0x6
    80001d0c:	4f858593          	add	a1,a1,1272 # 80008200 <digits+0x1c0>
    80001d10:	15848513          	add	a0,s1,344
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	102080e7          	jalr	258(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d1c:	00006517          	auipc	a0,0x6
    80001d20:	4f450513          	add	a0,a0,1268 # 80008210 <digits+0x1d0>
    80001d24:	00003097          	auipc	ra,0x3
    80001d28:	956080e7          	jalr	-1706(ra) # 8000467a <namei>
    80001d2c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d30:	478d                	li	a5,3
    80001d32:	cc9c                	sw	a5,24(s1)
  p->tickets = 1;
    80001d34:	4785                	li	a5,1
    80001d36:	20f4a823          	sw	a5,528(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f4a080e7          	jalr	-182(ra) # 80000c86 <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	add	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	add	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	add	s0,sp,32
    80001d5a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	c4a080e7          	jalr	-950(ra) # 800019a6 <myproc>
    80001d64:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d66:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d68:	01204c63          	bgtz	s2,80001d80 <growproc+0x32>
  else if (n < 0)
    80001d6c:	02094663          	bltz	s2,80001d98 <growproc+0x4a>
  p->sz = sz;
    80001d70:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d72:	4501                	li	a0,0
}
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6902                	ld	s2,0(sp)
    80001d7c:	6105                	add	sp,sp,32
    80001d7e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d80:	4691                	li	a3,4
    80001d82:	00b90633          	add	a2,s2,a1
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	682080e7          	jalr	1666(ra) # 8000140a <uvmalloc>
    80001d90:	85aa                	mv	a1,a0
    80001d92:	fd79                	bnez	a0,80001d70 <growproc+0x22>
      return -1;
    80001d94:	557d                	li	a0,-1
    80001d96:	bff9                	j	80001d74 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d98:	00b90633          	add	a2,s2,a1
    80001d9c:	6928                	ld	a0,80(a0)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	624080e7          	jalr	1572(ra) # 800013c2 <uvmdealloc>
    80001da6:	85aa                	mv	a1,a0
    80001da8:	b7e1                	j	80001d70 <growproc+0x22>

0000000080001daa <fork>:
{
    80001daa:	7139                	add	sp,sp,-64
    80001dac:	fc06                	sd	ra,56(sp)
    80001dae:	f822                	sd	s0,48(sp)
    80001db0:	f426                	sd	s1,40(sp)
    80001db2:	f04a                	sd	s2,32(sp)
    80001db4:	ec4e                	sd	s3,24(sp)
    80001db6:	e852                	sd	s4,16(sp)
    80001db8:	e456                	sd	s5,8(sp)
    80001dba:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	bea080e7          	jalr	-1046(ra) # 800019a6 <myproc>
    80001dc4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	dea080e7          	jalr	-534(ra) # 80001bb0 <allocproc>
    80001dce:	12050663          	beqz	a0,80001efa <fork+0x150>
    80001dd2:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd4:	048ab603          	ld	a2,72(s5)
    80001dd8:	692c                	ld	a1,80(a0)
    80001dda:	050ab503          	ld	a0,80(s5)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	784080e7          	jalr	1924(ra) # 80001562 <uvmcopy>
    80001de6:	06054263          	bltz	a0,80001e4a <fork+0xa0>
  np->sz = p->sz;
    80001dea:	048ab783          	ld	a5,72(s5)
    80001dee:	04f9b423          	sd	a5,72(s3)
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
    80001df2:	210aa783          	lw	a5,528(s5)
    80001df6:	20f9a823          	sw	a5,528(s3)
  np->creation_time = ticks; // record its creation time
    80001dfa:	00007797          	auipc	a5,0x7
    80001dfe:	b7e7e783          	lwu	a5,-1154(a5) # 80008978 <ticks>
    80001e02:	20f9bc23          	sd	a5,536(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e06:	058ab683          	ld	a3,88(s5)
    80001e0a:	87b6                	mv	a5,a3
    80001e0c:	0589b703          	ld	a4,88(s3)
    80001e10:	12068693          	add	a3,a3,288
    80001e14:	0007b803          	ld	a6,0(a5)
    80001e18:	6788                	ld	a0,8(a5)
    80001e1a:	6b8c                	ld	a1,16(a5)
    80001e1c:	6f90                	ld	a2,24(a5)
    80001e1e:	01073023          	sd	a6,0(a4)
    80001e22:	e708                	sd	a0,8(a4)
    80001e24:	eb0c                	sd	a1,16(a4)
    80001e26:	ef10                	sd	a2,24(a4)
    80001e28:	02078793          	add	a5,a5,32
    80001e2c:	02070713          	add	a4,a4,32
    80001e30:	fed792e3          	bne	a5,a3,80001e14 <fork+0x6a>
  np->trapframe->a0 = 0;
    80001e34:	0589b783          	ld	a5,88(s3)
    80001e38:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e3c:	0d0a8493          	add	s1,s5,208
    80001e40:	0d098913          	add	s2,s3,208
    80001e44:	150a8a13          	add	s4,s5,336
    80001e48:	a00d                	j	80001e6a <fork+0xc0>
    freeproc(np);
    80001e4a:	854e                	mv	a0,s3
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	d0c080e7          	jalr	-756(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e30080e7          	jalr	-464(ra) # 80000c86 <release>
    return -1;
    80001e5e:	597d                	li	s2,-1
    80001e60:	a059                	j	80001ee6 <fork+0x13c>
  for (i = 0; i < NOFILE; i++)
    80001e62:	04a1                	add	s1,s1,8
    80001e64:	0921                	add	s2,s2,8
    80001e66:	01448b63          	beq	s1,s4,80001e7c <fork+0xd2>
    if (p->ofile[i])
    80001e6a:	6088                	ld	a0,0(s1)
    80001e6c:	d97d                	beqz	a0,80001e62 <fork+0xb8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e6e:	00003097          	auipc	ra,0x3
    80001e72:	e7e080e7          	jalr	-386(ra) # 80004cec <filedup>
    80001e76:	00a93023          	sd	a0,0(s2)
    80001e7a:	b7e5                	j	80001e62 <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e7c:	150ab503          	ld	a0,336(s5)
    80001e80:	00002097          	auipc	ra,0x2
    80001e84:	016080e7          	jalr	22(ra) # 80003e96 <idup>
    80001e88:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8c:	4641                	li	a2,16
    80001e8e:	158a8593          	add	a1,s5,344
    80001e92:	15898513          	add	a0,s3,344
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f80080e7          	jalr	-128(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e9e:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	de2080e7          	jalr	-542(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001eac:	0000f497          	auipc	s1,0xf
    80001eb0:	d4c48493          	add	s1,s1,-692 # 80010bf8 <wait_lock>
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d1c080e7          	jalr	-740(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001ebe:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dc2080e7          	jalr	-574(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ecc:	854e                	mv	a0,s3
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	d04080e7          	jalr	-764(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001ed6:	478d                	li	a5,3
    80001ed8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	da8080e7          	jalr	-600(ra) # 80000c86 <release>
}
    80001ee6:	854a                	mv	a0,s2
    80001ee8:	70e2                	ld	ra,56(sp)
    80001eea:	7442                	ld	s0,48(sp)
    80001eec:	74a2                	ld	s1,40(sp)
    80001eee:	7902                	ld	s2,32(sp)
    80001ef0:	69e2                	ld	s3,24(sp)
    80001ef2:	6a42                	ld	s4,16(sp)
    80001ef4:	6aa2                	ld	s5,8(sp)
    80001ef6:	6121                	add	sp,sp,64
    80001ef8:	8082                	ret
    return -1;
    80001efa:	597d                	li	s2,-1
    80001efc:	b7ed                	j	80001ee6 <fork+0x13c>

0000000080001efe <simple_atol>:
{
    80001efe:	1141                	add	sp,sp,-16
    80001f00:	e422                	sd	s0,8(sp)
    80001f02:	0800                	add	s0,sp,16
  for (int i = 0; str[i] != '\0'; ++i)
    80001f04:	00054683          	lbu	a3,0(a0)
    80001f08:	c295                	beqz	a3,80001f2c <simple_atol+0x2e>
    80001f0a:	00150713          	add	a4,a0,1
  long res = 0;
    80001f0e:	4501                	li	a0,0
    res = res * 10 + str[i] - '0';
    80001f10:	00251793          	sll	a5,a0,0x2
    80001f14:	97aa                	add	a5,a5,a0
    80001f16:	0786                	sll	a5,a5,0x1
    80001f18:	97b6                	add	a5,a5,a3
    80001f1a:	fd078513          	add	a0,a5,-48
  for (int i = 0; str[i] != '\0'; ++i)
    80001f1e:	0705                	add	a4,a4,1
    80001f20:	fff74683          	lbu	a3,-1(a4)
    80001f24:	f6f5                	bnez	a3,80001f10 <simple_atol+0x12>
}
    80001f26:	6422                	ld	s0,8(sp)
    80001f28:	0141                	add	sp,sp,16
    80001f2a:	8082                	ret
  long res = 0;
    80001f2c:	4501                	li	a0,0
  return res;
    80001f2e:	bfe5                	j	80001f26 <simple_atol+0x28>

0000000080001f30 <get_random_seed>:
{
    80001f30:	1141                	add	sp,sp,-16
    80001f32:	e422                	sd	s0,8(sp)
    80001f34:	0800                	add	s0,sp,16
  seed = (a * seed + c) % m;
    80001f36:	00007697          	auipc	a3,0x7
    80001f3a:	99268693          	add	a3,a3,-1646 # 800088c8 <seed>
    80001f3e:	629c                	ld	a5,0(a3)
    80001f40:	41c65737          	lui	a4,0x41c65
    80001f44:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80001f48:	02e787b3          	mul	a5,a5,a4
    80001f4c:	670d                	lui	a4,0x3
    80001f4e:	03970713          	add	a4,a4,57 # 3039 <_entry-0x7fffcfc7>
    80001f52:	97ba                	add	a5,a5,a4
    80001f54:	1786                	sll	a5,a5,0x21
    80001f56:	9385                	srl	a5,a5,0x21
    80001f58:	e29c                	sd	a5,0(a3)
}
    80001f5a:	6509                	lui	a0,0x2
    80001f5c:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    80001f60:	02a7f533          	remu	a0,a5,a0
    80001f64:	6422                	ld	s0,8(sp)
    80001f66:	0141                	add	sp,sp,16
    80001f68:	8082                	ret

0000000080001f6a <long_to_padded_string>:
{
    80001f6a:	1141                	add	sp,sp,-16
    80001f6c:	e422                	sd	s0,8(sp)
    80001f6e:	0800                	add	s0,sp,16
  long temp = num;
    80001f70:	87aa                	mv	a5,a0
  int len = 0;
    80001f72:	4681                	li	a3,0
    temp /= 10;
    80001f74:	4329                	li	t1,10
  } while (temp > 0);
    80001f76:	48a5                	li	a7,9
    len++;
    80001f78:	0016871b          	addw	a4,a3,1
    80001f7c:	0007069b          	sext.w	a3,a4
    temp /= 10;
    80001f80:	883e                	mv	a6,a5
    80001f82:	0267c7b3          	div	a5,a5,t1
  } while (temp > 0);
    80001f86:	ff08c9e3          	blt	a7,a6,80001f78 <long_to_padded_string+0xe>
  int padding = total_length - len;
    80001f8a:	40e5873b          	subw	a4,a1,a4
    80001f8e:	0007089b          	sext.w	a7,a4
  for (int i = 0; i < padding; i++)
    80001f92:	01105c63          	blez	a7,80001faa <long_to_padded_string+0x40>
    80001f96:	87b2                	mv	a5,a2
    80001f98:	00c88833          	add	a6,a7,a2
    result[i] = '0';
    80001f9c:	03000693          	li	a3,48
    80001fa0:	00d78023          	sb	a3,0(a5)
  for (int i = 0; i < padding; i++)
    80001fa4:	0785                	add	a5,a5,1
    80001fa6:	ff079de3          	bne	a5,a6,80001fa0 <long_to_padded_string+0x36>
  for (int i = total_length - 1; i >= padding; i--)
    80001faa:	fff5879b          	addw	a5,a1,-1
    80001fae:	0317ca63          	blt	a5,a7,80001fe2 <long_to_padded_string+0x78>
    80001fb2:	97b2                	add	a5,a5,a2
    80001fb4:	ffe60813          	add	a6,a2,-2 # ffe <_entry-0x7ffff002>
    80001fb8:	982e                	add	a6,a6,a1
    80001fba:	fff5869b          	addw	a3,a1,-1
    80001fbe:	40e6873b          	subw	a4,a3,a4
    80001fc2:	1702                	sll	a4,a4,0x20
    80001fc4:	9301                	srl	a4,a4,0x20
    80001fc6:	40e80833          	sub	a6,a6,a4
    result[i] = (num % 10) + '0';
    80001fca:	46a9                	li	a3,10
    80001fcc:	02d56733          	rem	a4,a0,a3
    80001fd0:	0307071b          	addw	a4,a4,48
    80001fd4:	00e78023          	sb	a4,0(a5)
    num /= 10;
    80001fd8:	02d54533          	div	a0,a0,a3
  for (int i = total_length - 1; i >= padding; i--)
    80001fdc:	17fd                	add	a5,a5,-1
    80001fde:	ff0797e3          	bne	a5,a6,80001fcc <long_to_padded_string+0x62>
  result[total_length] = '\0'; // Null-terminate the string
    80001fe2:	962e                	add	a2,a2,a1
    80001fe4:	00060023          	sb	zero,0(a2)
}
    80001fe8:	6422                	ld	s0,8(sp)
    80001fea:	0141                	add	sp,sp,16
    80001fec:	8082                	ret

0000000080001fee <pseudo_rand_num_generator>:
{
    80001fee:	7119                	add	sp,sp,-128
    80001ff0:	fc86                	sd	ra,120(sp)
    80001ff2:	f8a2                	sd	s0,112(sp)
    80001ff4:	f4a6                	sd	s1,104(sp)
    80001ff6:	f0ca                	sd	s2,96(sp)
    80001ff8:	ecce                	sd	s3,88(sp)
    80001ffa:	e8d2                	sd	s4,80(sp)
    80001ffc:	e4d6                	sd	s5,72(sp)
    80001ffe:	e0da                	sd	s6,64(sp)
    80002000:	fc5e                	sd	s7,56(sp)
    80002002:	f862                	sd	s8,48(sp)
    80002004:	f466                	sd	s9,40(sp)
    80002006:	0100                	add	s0,sp,128
    80002008:	84aa                	mv	s1,a0
    8000200a:	8aae                	mv	s5,a1
  if (iterations == 0 && lst_index > 0)
    8000200c:	e1a1                	bnez	a1,8000204c <pseudo_rand_num_generator+0x5e>
    8000200e:	00007797          	auipc	a5,0x7
    80002012:	95a7a783          	lw	a5,-1702(a5) # 80008968 <lst_index>
    80002016:	02f04263          	bgtz	a5,8000203a <pseudo_rand_num_generator+0x4c>
  int seed_size = strlen(initial_seed);
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	e2e080e7          	jalr	-466(ra) # 80000e48 <strlen>
    80002022:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002024:	8526                	mv	a0,s1
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	ed8080e7          	jalr	-296(ra) # 80001efe <simple_atol>
  if (seed_val == 0)
    8000202e:	e561                	bnez	a0,800020f6 <pseudo_rand_num_generator+0x108>
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
    80002030:	00000097          	auipc	ra,0x0
    80002034:	f00080e7          	jalr	-256(ra) # 80001f30 <get_random_seed>
    80002038:	a02d                	j	80002062 <pseudo_rand_num_generator+0x74>
    return lst[lst_index - 1]; // Return the last generated number
    8000203a:	37fd                	addw	a5,a5,-1
    8000203c:	078a                	sll	a5,a5,0x2
    8000203e:	0000f717          	auipc	a4,0xf
    80002042:	fd270713          	add	a4,a4,-46 # 80011010 <lst>
    80002046:	97ba                	add	a5,a5,a4
    80002048:	4388                	lw	a0,0(a5)
    8000204a:	a0d1                	j	8000210e <pseudo_rand_num_generator+0x120>
  int seed_size = strlen(initial_seed);
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	dfc080e7          	jalr	-516(ra) # 80000e48 <strlen>
    80002054:	892a                	mv	s2,a0
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
    80002056:	8526                	mv	a0,s1
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	ea6080e7          	jalr	-346(ra) # 80001efe <simple_atol>
  if (seed_val == 0)
    80002060:	d961                	beqz	a0,80002030 <pseudo_rand_num_generator+0x42>
  for (int i = 0; i < iterations; i++)
    80002062:	09505a63          	blez	s5,800020f6 <pseudo_rand_num_generator+0x108>
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    80002066:	00191c9b          	sllw	s9,s2,0x1
    int mid_start = seed_size / 2;
    8000206a:	01f9579b          	srlw	a5,s2,0x1f
    8000206e:	012787bb          	addw	a5,a5,s2
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    80002072:	4017d79b          	sraw	a5,a5,0x1
    80002076:	f8040713          	add	a4,s0,-128
    8000207a:	00f70bb3          	add	s7,a4,a5
    8000207e:	4481                	li	s1,0
    char new_seed[seed_size + 1];
    80002080:	00190b1b          	addw	s6,s2,1
    80002084:	0b3d                	add	s6,s6,15
    80002086:	ff0b7b13          	and	s6,s6,-16
    lst[lst_index++] = simple_atol(new_seed);
    8000208a:	00007997          	auipc	s3,0x7
    8000208e:	8de98993          	add	s3,s3,-1826 # 80008968 <lst_index>
    80002092:	0000fc17          	auipc	s8,0xf
    80002096:	f7ec0c13          	add	s8,s8,-130 # 80011010 <lst>
  {
    8000209a:	8a0a                	mv	s4,sp
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);
    8000209c:	f8040613          	add	a2,s0,-128
    800020a0:	85e6                	mv	a1,s9
    800020a2:	02a50533          	mul	a0,a0,a0
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	ec4080e7          	jalr	-316(ra) # 80001f6a <long_to_padded_string>
    char new_seed[seed_size + 1];
    800020ae:	41610133          	sub	sp,sp,s6
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    800020b2:	864a                	mv	a2,s2
    800020b4:	85de                	mv	a1,s7
    800020b6:	850a                	mv	a0,sp
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	d22080e7          	jalr	-734(ra) # 80000dda <strncpy>
    new_seed[seed_size] = '\0';                         // Null-terminate
    800020c0:	012107b3          	add	a5,sp,s2
    800020c4:	00078023          	sb	zero,0(a5)
    lst[lst_index++] = simple_atol(new_seed);
    800020c8:	850a                	mv	a0,sp
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	e34080e7          	jalr	-460(ra) # 80001efe <simple_atol>
    800020d2:	0009a783          	lw	a5,0(s3)
    800020d6:	0017871b          	addw	a4,a5,1
    800020da:	00e9a023          	sw	a4,0(s3)
    800020de:	078a                	sll	a5,a5,0x2
    800020e0:	97e2                	add	a5,a5,s8
    800020e2:	c388                	sw	a0,0(a5)
    seed_val = simple_atol(new_seed);
    800020e4:	850a                	mv	a0,sp
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	e18080e7          	jalr	-488(ra) # 80001efe <simple_atol>
    800020ee:	8152                	mv	sp,s4
  for (int i = 0; i < iterations; i++)
    800020f0:	2485                	addw	s1,s1,1
    800020f2:	fa9a94e3          	bne	s5,s1,8000209a <pseudo_rand_num_generator+0xac>
  return lst[lst_index - 1];
    800020f6:	00007797          	auipc	a5,0x7
    800020fa:	8727a783          	lw	a5,-1934(a5) # 80008968 <lst_index>
    800020fe:	37fd                	addw	a5,a5,-1
    80002100:	078a                	sll	a5,a5,0x2
    80002102:	0000f717          	auipc	a4,0xf
    80002106:	f0e70713          	add	a4,a4,-242 # 80011010 <lst>
    8000210a:	97ba                	add	a5,a5,a4
    8000210c:	4388                	lw	a0,0(a5)
}
    8000210e:	f8040113          	add	sp,s0,-128
    80002112:	70e6                	ld	ra,120(sp)
    80002114:	7446                	ld	s0,112(sp)
    80002116:	74a6                	ld	s1,104(sp)
    80002118:	7906                	ld	s2,96(sp)
    8000211a:	69e6                	ld	s3,88(sp)
    8000211c:	6a46                	ld	s4,80(sp)
    8000211e:	6aa6                	ld	s5,72(sp)
    80002120:	6b06                	ld	s6,64(sp)
    80002122:	7be2                	ld	s7,56(sp)
    80002124:	7c42                	ld	s8,48(sp)
    80002126:	7ca2                	ld	s9,40(sp)
    80002128:	6109                	add	sp,sp,128
    8000212a:	8082                	ret

000000008000212c <int_to_string>:
{
    8000212c:	1141                	add	sp,sp,-16
    8000212e:	e422                	sd	s0,8(sp)
    80002130:	0800                	add	s0,sp,16
  int temp = num;
    80002132:	872a                	mv	a4,a0
  int len = 0;
    80002134:	4781                	li	a5,0
    temp /= 10;
    80002136:	48a9                	li	a7,10
  } while (temp > 0);
    80002138:	4825                	li	a6,9
    len++;
    8000213a:	863e                	mv	a2,a5
    8000213c:	2785                	addw	a5,a5,1
    temp /= 10;
    8000213e:	86ba                	mv	a3,a4
    80002140:	0317473b          	divw	a4,a4,a7
  } while (temp > 0);
    80002144:	fed84be3          	blt	a6,a3,8000213a <int_to_string+0xe>
  result[len] = '\0'; // Null-terminate the string
    80002148:	97ae                	add	a5,a5,a1
    8000214a:	00078023          	sb	zero,0(a5)
  for (int i = len - 1; i >= 0; i--)
    8000214e:	02064663          	bltz	a2,8000217a <int_to_string+0x4e>
    80002152:	00c587b3          	add	a5,a1,a2
    80002156:	fff58693          	add	a3,a1,-1
    8000215a:	96b2                	add	a3,a3,a2
    8000215c:	1602                	sll	a2,a2,0x20
    8000215e:	9201                	srl	a2,a2,0x20
    80002160:	8e91                	sub	a3,a3,a2
    result[i] = (num % 10) + '0';
    80002162:	4629                	li	a2,10
    80002164:	02c5673b          	remw	a4,a0,a2
    80002168:	0307071b          	addw	a4,a4,48
    8000216c:	00e78023          	sb	a4,0(a5)
    num /= 10;
    80002170:	02c5453b          	divw	a0,a0,a2
  for (int i = len - 1; i >= 0; i--)
    80002174:	17fd                	add	a5,a5,-1
    80002176:	fed797e3          	bne	a5,a3,80002164 <int_to_string+0x38>
}
    8000217a:	6422                	ld	s0,8(sp)
    8000217c:	0141                	add	sp,sp,16
    8000217e:	8082                	ret

0000000080002180 <simple_rand>:
int simple_rand() {
    80002180:	1141                	add	sp,sp,-16
    80002182:	e422                	sd	s0,8(sp)
    80002184:	0800                	add	s0,sp,16
    seed = (a * seed + c) % m;
    80002186:	00006697          	auipc	a3,0x6
    8000218a:	74268693          	add	a3,a3,1858 # 800088c8 <seed>
    8000218e:	629c                	ld	a5,0(a3)
    80002190:	41c65737          	lui	a4,0x41c65
    80002194:	e6d70713          	add	a4,a4,-403 # 41c64e6d <_entry-0x3e39b193>
    80002198:	02e787b3          	mul	a5,a5,a4
    8000219c:	0012d737          	lui	a4,0x12d
    800021a0:	68770713          	add	a4,a4,1671 # 12d687 <_entry-0x7fed2979>
    800021a4:	97ba                	add	a5,a5,a4
    800021a6:	1786                	sll	a5,a5,0x21
    800021a8:	9385                	srl	a5,a5,0x21
    800021aa:	e29c                	sd	a5,0(a3)
}
    800021ac:	6509                	lui	a0,0x2
    800021ae:	71050513          	add	a0,a0,1808 # 2710 <_entry-0x7fffd8f0>
    800021b2:	02a7f533          	remu	a0,a5,a0
    800021b6:	6422                	ld	s0,8(sp)
    800021b8:	0141                	add	sp,sp,16
    800021ba:	8082                	ret

00000000800021bc <random_at_most>:
int random_at_most(int max) {
    800021bc:	1101                	add	sp,sp,-32
    800021be:	ec06                	sd	ra,24(sp)
    800021c0:	e822                	sd	s0,16(sp)
    800021c2:	e426                	sd	s1,8(sp)
    800021c4:	1000                	add	s0,sp,32
    800021c6:	84aa                	mv	s1,a0
    int random_num = simple_rand(); // Use the LCG for random generation
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	fb8080e7          	jalr	-72(ra) # 80002180 <simple_rand>
    return 1 + (random_num % max);  // Return a number in the range [1, max]
    800021d0:	0295653b          	remw	a0,a0,s1
}
    800021d4:	2505                	addw	a0,a0,1
    800021d6:	60e2                	ld	ra,24(sp)
    800021d8:	6442                	ld	s0,16(sp)
    800021da:	64a2                	ld	s1,8(sp)
    800021dc:	6105                	add	sp,sp,32
    800021de:	8082                	ret

00000000800021e0 <round_robin_scheduler>:
{
    800021e0:	7139                	add	sp,sp,-64
    800021e2:	fc06                	sd	ra,56(sp)
    800021e4:	f822                	sd	s0,48(sp)
    800021e6:	f426                	sd	s1,40(sp)
    800021e8:	f04a                	sd	s2,32(sp)
    800021ea:	ec4e                	sd	s3,24(sp)
    800021ec:	e852                	sd	s4,16(sp)
    800021ee:	e456                	sd	s5,8(sp)
    800021f0:	e05a                	sd	s6,0(sp)
    800021f2:	0080                	add	s0,sp,64
    800021f4:	8792                	mv	a5,tp
  int id = r_tp();
    800021f6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021f8:	00779a93          	sll	s5,a5,0x7
    800021fc:	0000f717          	auipc	a4,0xf
    80002200:	9e470713          	add	a4,a4,-1564 # 80010be0 <pid_lock>
    80002204:	9756                	add	a4,a4,s5
    80002206:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000220a:	0000f717          	auipc	a4,0xf
    8000220e:	a0e70713          	add	a4,a4,-1522 # 80010c18 <cpus+0x8>
    80002212:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80002214:	498d                	li	s3,3
        p->state = RUNNING;
    80002216:	4b11                	li	s6,4
        c->proc = p;
    80002218:	079e                	sll	a5,a5,0x7
    8000221a:	0000fa17          	auipc	s4,0xf
    8000221e:	9c6a0a13          	add	s4,s4,-1594 # 80010be0 <pid_lock>
    80002222:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002224:	00018917          	auipc	s2,0x18
    80002228:	58c90913          	add	s2,s2,1420 # 8001a7b0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000222c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002230:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002234:	10079073          	csrw	sstatus,a5
    80002238:	00010497          	auipc	s1,0x10
    8000223c:	d7848493          	add	s1,s1,-648 # 80011fb0 <proc>
    80002240:	a811                	j	80002254 <round_robin_scheduler+0x74>
      release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a42080e7          	jalr	-1470(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000224c:	22048493          	add	s1,s1,544
    80002250:	fd248ee3          	beq	s1,s2,8000222c <round_robin_scheduler+0x4c>
      acquire(&p->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	97c080e7          	jalr	-1668(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    8000225e:	4c9c                	lw	a5,24(s1)
    80002260:	ff3791e3          	bne	a5,s3,80002242 <round_robin_scheduler+0x62>
        p->state = RUNNING;
    80002264:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002268:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000226c:	06048593          	add	a1,s1,96
    80002270:	8556                	mv	a0,s5
    80002272:	00001097          	auipc	ra,0x1
    80002276:	9a4080e7          	jalr	-1628(ra) # 80002c16 <swtch>
        c->proc = 0;
    8000227a:	020a3823          	sd	zero,48(s4)
    8000227e:	b7d1                	j	80002242 <round_robin_scheduler+0x62>

0000000080002280 <lottery_scheduler>:
{
    80002280:	715d                	add	sp,sp,-80
    80002282:	e486                	sd	ra,72(sp)
    80002284:	e0a2                	sd	s0,64(sp)
    80002286:	fc26                	sd	s1,56(sp)
    80002288:	f84a                	sd	s2,48(sp)
    8000228a:	f44e                	sd	s3,40(sp)
    8000228c:	f052                	sd	s4,32(sp)
    8000228e:	ec56                	sd	s5,24(sp)
    80002290:	e85a                	sd	s6,16(sp)
    80002292:	e45e                	sd	s7,8(sp)
    80002294:	e062                	sd	s8,0(sp)
    80002296:	0880                	add	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002298:	8792                	mv	a5,tp
  int id = r_tp();
    8000229a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000229c:	00779693          	sll	a3,a5,0x7
    800022a0:	0000f717          	auipc	a4,0xf
    800022a4:	94070713          	add	a4,a4,-1728 # 80010be0 <pid_lock>
    800022a8:	9736                	add	a4,a4,a3
    800022aa:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &winner->context);
    800022ae:	0000f717          	auipc	a4,0xf
    800022b2:	96a70713          	add	a4,a4,-1686 # 80010c18 <cpus+0x8>
    800022b6:	00e68c33          	add	s8,a3,a4
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    800022ba:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    800022bc:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800022be:	00018917          	auipc	s2,0x18
    800022c2:	4f290913          	add	s2,s2,1266 # 8001a7b0 <tickslock>
        c->proc = winner;
    800022c6:	0000fb17          	auipc	s6,0xf
    800022ca:	91ab0b13          	add	s6,s6,-1766 # 80010be0 <pid_lock>
    800022ce:	9b36                	add	s6,s6,a3
    800022d0:	a80d                	j	80002302 <lottery_scheduler+0x82>
      release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9b2080e7          	jalr	-1614(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022dc:	22048493          	add	s1,s1,544
    800022e0:	01248f63          	beq	s1,s2,800022fe <lottery_scheduler+0x7e>
      acquire(&p->lock);
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	8ec080e7          	jalr	-1812(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    800022ee:	4c9c                	lw	a5,24(s1)
    800022f0:	ff3791e3          	bne	a5,s3,800022d2 <lottery_scheduler+0x52>
        total_tickets += p->tickets; // Accumulate total tickets
    800022f4:	2104a783          	lw	a5,528(s1)
    800022f8:	01478a3b          	addw	s4,a5,s4
    800022fc:	bfd9                	j	800022d2 <lottery_scheduler+0x52>
    if (total_tickets == 0)
    800022fe:	000a1e63          	bnez	s4,8000231a <lottery_scheduler+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002302:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002306:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000230a:	10079073          	csrw	sstatus,a5
    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    8000230e:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002310:	00010497          	auipc	s1,0x10
    80002314:	ca048493          	add	s1,s1,-864 # 80011fb0 <proc>
    80002318:	b7f1                	j	800022e4 <lottery_scheduler+0x64>
    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    8000231a:	8552                	mv	a0,s4
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	ea0080e7          	jalr	-352(ra) # 800021bc <random_at_most>
    80002324:	8baa                	mv	s7,a0
    int ticket_counter = 0; // Track ticket count while iterating over processes
    80002326:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80002328:	00010497          	auipc	s1,0x10
    8000232c:	c8848493          	add	s1,s1,-888 # 80011fb0 <proc>
    80002330:	a811                	j	80002344 <lottery_scheduler+0xc4>
      release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	952080e7          	jalr	-1710(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000233c:	22048493          	add	s1,s1,544
    80002340:	fd2481e3          	beq	s1,s2,80002302 <lottery_scheduler+0x82>
      if (p == 0)
    80002344:	dce5                	beqz	s1,8000233c <lottery_scheduler+0xbc>
      acquire(&p->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	88a080e7          	jalr	-1910(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80002350:	4c9c                	lw	a5,24(s1)
    80002352:	ff3790e3          	bne	a5,s3,80002332 <lottery_scheduler+0xb2>
        ticket_counter += p->tickets; // Increment the ticket counter
    80002356:	2104a783          	lw	a5,528(s1)
    8000235a:	01478a3b          	addw	s4,a5,s4
        if (ticket_counter >= winning_ticket)
    8000235e:	fd7a4ae3          	blt	s4,s7,80002332 <lottery_scheduler+0xb2>
            release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	922080e7          	jalr	-1758(ra) # 80000c86 <release>
      acquire(&winner->lock);
    8000236c:	8a26                	mv	s4,s1
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	862080e7          	jalr	-1950(ra) # 80000bd2 <acquire>
      if (winner->state == RUNNABLE)
    80002378:	4c9c                	lw	a5,24(s1)
    8000237a:	01378863          	beq	a5,s3,8000238a <lottery_scheduler+0x10a>
      release(&winner->lock);
    8000237e:	8552                	mv	a0,s4
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	906080e7          	jalr	-1786(ra) # 80000c86 <release>
    80002388:	bfad                	j	80002302 <lottery_scheduler+0x82>
        winner->state = RUNNING;
    8000238a:	4791                	li	a5,4
    8000238c:	cc9c                	sw	a5,24(s1)
        c->proc = winner;
    8000238e:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &winner->context);
    80002392:	06048593          	add	a1,s1,96
    80002396:	8562                	mv	a0,s8
    80002398:	00001097          	auipc	ra,0x1
    8000239c:	87e080e7          	jalr	-1922(ra) # 80002c16 <swtch>
        c->proc = 0;
    800023a0:	020b3823          	sd	zero,48(s6)
    800023a4:	bfe9                	j	8000237e <lottery_scheduler+0xfe>

00000000800023a6 <mlfq_scheduler>:
{
    800023a6:	1141                	add	sp,sp,-16
    800023a8:	e422                	sd	s0,8(sp)
    800023aa:	0800                	add	s0,sp,16
}
    800023ac:	6422                	ld	s0,8(sp)
    800023ae:	0141                	add	sp,sp,16
    800023b0:	8082                	ret

00000000800023b2 <scheduler>:
{
    800023b2:	1141                	add	sp,sp,-16
    800023b4:	e406                	sd	ra,8(sp)
    800023b6:	e022                	sd	s0,0(sp)
    800023b8:	0800                	add	s0,sp,16
    printf("LBS will run\n");
    800023ba:	00006517          	auipc	a0,0x6
    800023be:	e5e50513          	add	a0,a0,-418 # 80008218 <digits+0x1d8>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	1c4080e7          	jalr	452(ra) # 80000586 <printf>
    lottery_scheduler();
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	eb6080e7          	jalr	-330(ra) # 80002280 <lottery_scheduler>

00000000800023d2 <sched>:
{
    800023d2:	7179                	add	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	5c6080e7          	jalr	1478(ra) # 800019a6 <myproc>
    800023e8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	76e080e7          	jalr	1902(ra) # 80000b58 <holding>
    800023f2:	c93d                	beqz	a0,80002468 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800023f6:	2781                	sext.w	a5,a5
    800023f8:	079e                	sll	a5,a5,0x7
    800023fa:	0000e717          	auipc	a4,0xe
    800023fe:	7e670713          	add	a4,a4,2022 # 80010be0 <pid_lock>
    80002402:	97ba                	add	a5,a5,a4
    80002404:	0a87a703          	lw	a4,168(a5)
    80002408:	4785                	li	a5,1
    8000240a:	06f71763          	bne	a4,a5,80002478 <sched+0xa6>
  if (p->state == RUNNING)
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4791                	li	a5,4
    80002412:	06f70b63          	beq	a4,a5,80002488 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002416:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000241a:	8b89                	and	a5,a5,2
  if (intr_get())
    8000241c:	efb5                	bnez	a5,80002498 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002420:	0000e917          	auipc	s2,0xe
    80002424:	7c090913          	add	s2,s2,1984 # 80010be0 <pid_lock>
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	sll	a5,a5,0x7
    8000242c:	97ca                	add	a5,a5,s2
    8000242e:	0ac7a983          	lw	s3,172(a5)
    80002432:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002434:	2781                	sext.w	a5,a5
    80002436:	079e                	sll	a5,a5,0x7
    80002438:	0000e597          	auipc	a1,0xe
    8000243c:	7e058593          	add	a1,a1,2016 # 80010c18 <cpus+0x8>
    80002440:	95be                	add	a1,a1,a5
    80002442:	06048513          	add	a0,s1,96
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	7d0080e7          	jalr	2000(ra) # 80002c16 <swtch>
    8000244e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002450:	2781                	sext.w	a5,a5
    80002452:	079e                	sll	a5,a5,0x7
    80002454:	993e                	add	s2,s2,a5
    80002456:	0b392623          	sw	s3,172(s2)
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6145                	add	sp,sp,48
    80002466:	8082                	ret
    panic("sched p->lock");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	dc050513          	add	a0,a0,-576 # 80008228 <digits+0x1e8>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0cc080e7          	jalr	204(ra) # 8000053c <panic>
    panic("sched locks");
    80002478:	00006517          	auipc	a0,0x6
    8000247c:	dc050513          	add	a0,a0,-576 # 80008238 <digits+0x1f8>
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	0bc080e7          	jalr	188(ra) # 8000053c <panic>
    panic("sched running");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	dc050513          	add	a0,a0,-576 # 80008248 <digits+0x208>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0ac080e7          	jalr	172(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	dc050513          	add	a0,a0,-576 # 80008258 <digits+0x218>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	09c080e7          	jalr	156(ra) # 8000053c <panic>

00000000800024a8 <yield>:
{
    800024a8:	1101                	add	sp,sp,-32
    800024aa:	ec06                	sd	ra,24(sp)
    800024ac:	e822                	sd	s0,16(sp)
    800024ae:	e426                	sd	s1,8(sp)
    800024b0:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	4f4080e7          	jalr	1268(ra) # 800019a6 <myproc>
    800024ba:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	716080e7          	jalr	1814(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    800024c4:	478d                	li	a5,3
    800024c6:	cc9c                	sw	a5,24(s1)
  sched();
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	f0a080e7          	jalr	-246(ra) # 800023d2 <sched>
  release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7b4080e7          	jalr	1972(ra) # 80000c86 <release>
}
    800024da:	60e2                	ld	ra,24(sp)
    800024dc:	6442                	ld	s0,16(sp)
    800024de:	64a2                	ld	s1,8(sp)
    800024e0:	6105                	add	sp,sp,32
    800024e2:	8082                	ret

00000000800024e4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024e4:	7179                	add	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	1800                	add	s0,sp,48
    800024f2:	89aa                	mv	s3,a0
    800024f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	4b0080e7          	jalr	1200(ra) # 800019a6 <myproc>
    800024fe:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	6d2080e7          	jalr	1746(ra) # 80000bd2 <acquire>
  release(lk);
    80002508:	854a                	mv	a0,s2
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	77c080e7          	jalr	1916(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002512:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002516:	4789                	li	a5,2
    80002518:	cc9c                	sw	a5,24(s1)

  sched();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	eb8080e7          	jalr	-328(ra) # 800023d2 <sched>

  // Tidy up.
  p->chan = 0;
    80002522:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	75e080e7          	jalr	1886(ra) # 80000c86 <release>
  acquire(lk);
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	6a0080e7          	jalr	1696(ra) # 80000bd2 <acquire>
}
    8000253a:	70a2                	ld	ra,40(sp)
    8000253c:	7402                	ld	s0,32(sp)
    8000253e:	64e2                	ld	s1,24(sp)
    80002540:	6942                	ld	s2,16(sp)
    80002542:	69a2                	ld	s3,8(sp)
    80002544:	6145                	add	sp,sp,48
    80002546:	8082                	ret

0000000080002548 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002548:	7139                	add	sp,sp,-64
    8000254a:	fc06                	sd	ra,56(sp)
    8000254c:	f822                	sd	s0,48(sp)
    8000254e:	f426                	sd	s1,40(sp)
    80002550:	f04a                	sd	s2,32(sp)
    80002552:	ec4e                	sd	s3,24(sp)
    80002554:	e852                	sd	s4,16(sp)
    80002556:	e456                	sd	s5,8(sp)
    80002558:	0080                	add	s0,sp,64
    8000255a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000255c:	00010497          	auipc	s1,0x10
    80002560:	a5448493          	add	s1,s1,-1452 # 80011fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002564:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002566:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002568:	00018917          	auipc	s2,0x18
    8000256c:	24890913          	add	s2,s2,584 # 8001a7b0 <tickslock>
    80002570:	a811                	j	80002584 <wakeup+0x3c>
      }
      release(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	712080e7          	jalr	1810(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000257c:	22048493          	add	s1,s1,544
    80002580:	03248663          	beq	s1,s2,800025ac <wakeup+0x64>
    if (p != myproc())
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	422080e7          	jalr	1058(ra) # 800019a6 <myproc>
    8000258c:	fea488e3          	beq	s1,a0,8000257c <wakeup+0x34>
      acquire(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	640080e7          	jalr	1600(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000259a:	4c9c                	lw	a5,24(s1)
    8000259c:	fd379be3          	bne	a5,s3,80002572 <wakeup+0x2a>
    800025a0:	709c                	ld	a5,32(s1)
    800025a2:	fd4798e3          	bne	a5,s4,80002572 <wakeup+0x2a>
        p->state = RUNNABLE;
    800025a6:	0154ac23          	sw	s5,24(s1)
    800025aa:	b7e1                	j	80002572 <wakeup+0x2a>
    }
  }
}
    800025ac:	70e2                	ld	ra,56(sp)
    800025ae:	7442                	ld	s0,48(sp)
    800025b0:	74a2                	ld	s1,40(sp)
    800025b2:	7902                	ld	s2,32(sp)
    800025b4:	69e2                	ld	s3,24(sp)
    800025b6:	6a42                	ld	s4,16(sp)
    800025b8:	6aa2                	ld	s5,8(sp)
    800025ba:	6121                	add	sp,sp,64
    800025bc:	8082                	ret

00000000800025be <reparent>:
{
    800025be:	7179                	add	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	add	s0,sp,48
    800025ce:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025d0:	00010497          	auipc	s1,0x10
    800025d4:	9e048493          	add	s1,s1,-1568 # 80011fb0 <proc>
      pp->parent = initproc;
    800025d8:	00006a17          	auipc	s4,0x6
    800025dc:	398a0a13          	add	s4,s4,920 # 80008970 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e0:	00018997          	auipc	s3,0x18
    800025e4:	1d098993          	add	s3,s3,464 # 8001a7b0 <tickslock>
    800025e8:	a029                	j	800025f2 <reparent+0x34>
    800025ea:	22048493          	add	s1,s1,544
    800025ee:	01348d63          	beq	s1,s3,80002608 <reparent+0x4a>
    if (pp->parent == p)
    800025f2:	7c9c                	ld	a5,56(s1)
    800025f4:	ff279be3          	bne	a5,s2,800025ea <reparent+0x2c>
      pp->parent = initproc;
    800025f8:	000a3503          	ld	a0,0(s4)
    800025fc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	f4a080e7          	jalr	-182(ra) # 80002548 <wakeup>
    80002606:	b7d5                	j	800025ea <reparent+0x2c>
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	add	sp,sp,48
    80002616:	8082                	ret

0000000080002618 <exit>:
{
    80002618:	7179                	add	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	e052                	sd	s4,0(sp)
    80002626:	1800                	add	s0,sp,48
    80002628:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	37c080e7          	jalr	892(ra) # 800019a6 <myproc>
    80002632:	89aa                	mv	s3,a0
  if (p == initproc)
    80002634:	00006797          	auipc	a5,0x6
    80002638:	33c7b783          	ld	a5,828(a5) # 80008970 <initproc>
    8000263c:	0d050493          	add	s1,a0,208
    80002640:	15050913          	add	s2,a0,336
    80002644:	02a79363          	bne	a5,a0,8000266a <exit+0x52>
    panic("init exiting");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	c2850513          	add	a0,a0,-984 # 80008270 <digits+0x230>
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	eec080e7          	jalr	-276(ra) # 8000053c <panic>
      fileclose(f);
    80002658:	00002097          	auipc	ra,0x2
    8000265c:	6e6080e7          	jalr	1766(ra) # 80004d3e <fileclose>
      p->ofile[fd] = 0;
    80002660:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002664:	04a1                	add	s1,s1,8
    80002666:	01248563          	beq	s1,s2,80002670 <exit+0x58>
    if (p->ofile[fd])
    8000266a:	6088                	ld	a0,0(s1)
    8000266c:	f575                	bnez	a0,80002658 <exit+0x40>
    8000266e:	bfdd                	j	80002664 <exit+0x4c>
  begin_op();
    80002670:	00002097          	auipc	ra,0x2
    80002674:	20a080e7          	jalr	522(ra) # 8000487a <begin_op>
  iput(p->cwd);
    80002678:	1509b503          	ld	a0,336(s3)
    8000267c:	00002097          	auipc	ra,0x2
    80002680:	a12080e7          	jalr	-1518(ra) # 8000408e <iput>
  end_op();
    80002684:	00002097          	auipc	ra,0x2
    80002688:	270080e7          	jalr	624(ra) # 800048f4 <end_op>
  p->cwd = 0;
    8000268c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002690:	0000e497          	auipc	s1,0xe
    80002694:	56848493          	add	s1,s1,1384 # 80010bf8 <wait_lock>
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	538080e7          	jalr	1336(ra) # 80000bd2 <acquire>
  reparent(p);
    800026a2:	854e                	mv	a0,s3
    800026a4:	00000097          	auipc	ra,0x0
    800026a8:	f1a080e7          	jalr	-230(ra) # 800025be <reparent>
  wakeup(p->parent);
    800026ac:	0389b503          	ld	a0,56(s3)
    800026b0:	00000097          	auipc	ra,0x0
    800026b4:	e98080e7          	jalr	-360(ra) # 80002548 <wakeup>
  acquire(&p->lock);
    800026b8:	854e                	mv	a0,s3
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	518080e7          	jalr	1304(ra) # 80000bd2 <acquire>
  p->xstate = status;
    800026c2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026c6:	4795                	li	a5,5
    800026c8:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026cc:	00006797          	auipc	a5,0x6
    800026d0:	2ac7a783          	lw	a5,684(a5) # 80008978 <ticks>
    800026d4:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	5ac080e7          	jalr	1452(ra) # 80000c86 <release>
  sched();
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	cf0080e7          	jalr	-784(ra) # 800023d2 <sched>
  panic("zombie exit");
    800026ea:	00006517          	auipc	a0,0x6
    800026ee:	b9650513          	add	a0,a0,-1130 # 80008280 <digits+0x240>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	e4a080e7          	jalr	-438(ra) # 8000053c <panic>

00000000800026fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026fa:	7179                	add	sp,sp,-48
    800026fc:	f406                	sd	ra,40(sp)
    800026fe:	f022                	sd	s0,32(sp)
    80002700:	ec26                	sd	s1,24(sp)
    80002702:	e84a                	sd	s2,16(sp)
    80002704:	e44e                	sd	s3,8(sp)
    80002706:	1800                	add	s0,sp,48
    80002708:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000270a:	00010497          	auipc	s1,0x10
    8000270e:	8a648493          	add	s1,s1,-1882 # 80011fb0 <proc>
    80002712:	00018997          	auipc	s3,0x18
    80002716:	09e98993          	add	s3,s3,158 # 8001a7b0 <tickslock>
  {
    acquire(&p->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	4b6080e7          	jalr	1206(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002724:	589c                	lw	a5,48(s1)
    80002726:	01278d63          	beq	a5,s2,80002740 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	55a080e7          	jalr	1370(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002734:	22048493          	add	s1,s1,544
    80002738:	ff3491e3          	bne	s1,s3,8000271a <kill+0x20>
  }
  return -1;
    8000273c:	557d                	li	a0,-1
    8000273e:	a829                	j	80002758 <kill+0x5e>
      p->killed = 1;
    80002740:	4785                	li	a5,1
    80002742:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002744:	4c98                	lw	a4,24(s1)
    80002746:	4789                	li	a5,2
    80002748:	00f70f63          	beq	a4,a5,80002766 <kill+0x6c>
      release(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	538080e7          	jalr	1336(ra) # 80000c86 <release>
      return 0;
    80002756:	4501                	li	a0,0
}
    80002758:	70a2                	ld	ra,40(sp)
    8000275a:	7402                	ld	s0,32(sp)
    8000275c:	64e2                	ld	s1,24(sp)
    8000275e:	6942                	ld	s2,16(sp)
    80002760:	69a2                	ld	s3,8(sp)
    80002762:	6145                	add	sp,sp,48
    80002764:	8082                	ret
        p->state = RUNNABLE;
    80002766:	478d                	li	a5,3
    80002768:	cc9c                	sw	a5,24(s1)
    8000276a:	b7cd                	j	8000274c <kill+0x52>

000000008000276c <setkilled>:

void setkilled(struct proc *p)
{
    8000276c:	1101                	add	sp,sp,-32
    8000276e:	ec06                	sd	ra,24(sp)
    80002770:	e822                	sd	s0,16(sp)
    80002772:	e426                	sd	s1,8(sp)
    80002774:	1000                	add	s0,sp,32
    80002776:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	45a080e7          	jalr	1114(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002780:	4785                	li	a5,1
    80002782:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	500080e7          	jalr	1280(ra) # 80000c86 <release>
}
    8000278e:	60e2                	ld	ra,24(sp)
    80002790:	6442                	ld	s0,16(sp)
    80002792:	64a2                	ld	s1,8(sp)
    80002794:	6105                	add	sp,sp,32
    80002796:	8082                	ret

0000000080002798 <killed>:

int killed(struct proc *p)
{
    80002798:	1101                	add	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	e04a                	sd	s2,0(sp)
    800027a2:	1000                	add	s0,sp,32
    800027a4:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	42c080e7          	jalr	1068(ra) # 80000bd2 <acquire>
  k = p->killed;
    800027ae:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	4d2080e7          	jalr	1234(ra) # 80000c86 <release>
  return k;
}
    800027bc:	854a                	mv	a0,s2
    800027be:	60e2                	ld	ra,24(sp)
    800027c0:	6442                	ld	s0,16(sp)
    800027c2:	64a2                	ld	s1,8(sp)
    800027c4:	6902                	ld	s2,0(sp)
    800027c6:	6105                	add	sp,sp,32
    800027c8:	8082                	ret

00000000800027ca <wait>:
{
    800027ca:	715d                	add	sp,sp,-80
    800027cc:	e486                	sd	ra,72(sp)
    800027ce:	e0a2                	sd	s0,64(sp)
    800027d0:	fc26                	sd	s1,56(sp)
    800027d2:	f84a                	sd	s2,48(sp)
    800027d4:	f44e                	sd	s3,40(sp)
    800027d6:	f052                	sd	s4,32(sp)
    800027d8:	ec56                	sd	s5,24(sp)
    800027da:	e85a                	sd	s6,16(sp)
    800027dc:	e45e                	sd	s7,8(sp)
    800027de:	e062                	sd	s8,0(sp)
    800027e0:	0880                	add	s0,sp,80
    800027e2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	1c2080e7          	jalr	450(ra) # 800019a6 <myproc>
    800027ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027ee:	0000e517          	auipc	a0,0xe
    800027f2:	40a50513          	add	a0,a0,1034 # 80010bf8 <wait_lock>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	3dc080e7          	jalr	988(ra) # 80000bd2 <acquire>
    havekids = 0;
    800027fe:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002800:	4a95                	li	s5,5
        havekids = 1;
    80002802:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002804:	00018997          	auipc	s3,0x18
    80002808:	fac98993          	add	s3,s3,-84 # 8001a7b0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000280c:	0000ec17          	auipc	s8,0xe
    80002810:	3ecc0c13          	add	s8,s8,1004 # 80010bf8 <wait_lock>
    80002814:	a8f1                	j	800028f0 <wait+0x126>
    80002816:	17448793          	add	a5,s1,372
    8000281a:	17490713          	add	a4,s2,372
    8000281e:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    80002822:	4394                	lw	a3,0(a5)
    80002824:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    80002826:	0791                	add	a5,a5,4
    80002828:	0711                	add	a4,a4,4
    8000282a:	fec79ce3          	bne	a5,a2,80002822 <wait+0x58>
          pid = pp->pid;
    8000282e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002832:	000a0e63          	beqz	s4,8000284e <wait+0x84>
    80002836:	4691                	li	a3,4
    80002838:	02c48613          	add	a2,s1,44
    8000283c:	85d2                	mv	a1,s4
    8000283e:	05093503          	ld	a0,80(s2)
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	e24080e7          	jalr	-476(ra) # 80001666 <copyout>
    8000284a:	04054163          	bltz	a0,8000288c <wait+0xc2>
          freeproc(pp);
    8000284e:	8526                	mv	a0,s1
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	308080e7          	jalr	776(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	42c080e7          	jalr	1068(ra) # 80000c86 <release>
          release(&wait_lock);
    80002862:	0000e517          	auipc	a0,0xe
    80002866:	39650513          	add	a0,a0,918 # 80010bf8 <wait_lock>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	41c080e7          	jalr	1052(ra) # 80000c86 <release>
}
    80002872:	854e                	mv	a0,s3
    80002874:	60a6                	ld	ra,72(sp)
    80002876:	6406                	ld	s0,64(sp)
    80002878:	74e2                	ld	s1,56(sp)
    8000287a:	7942                	ld	s2,48(sp)
    8000287c:	79a2                	ld	s3,40(sp)
    8000287e:	7a02                	ld	s4,32(sp)
    80002880:	6ae2                	ld	s5,24(sp)
    80002882:	6b42                	ld	s6,16(sp)
    80002884:	6ba2                	ld	s7,8(sp)
    80002886:	6c02                	ld	s8,0(sp)
    80002888:	6161                	add	sp,sp,80
    8000288a:	8082                	ret
            release(&pp->lock);
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	3f8080e7          	jalr	1016(ra) # 80000c86 <release>
            release(&wait_lock);
    80002896:	0000e517          	auipc	a0,0xe
    8000289a:	36250513          	add	a0,a0,866 # 80010bf8 <wait_lock>
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	3e8080e7          	jalr	1000(ra) # 80000c86 <release>
            return -1;
    800028a6:	59fd                	li	s3,-1
    800028a8:	b7e9                	j	80002872 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028aa:	22048493          	add	s1,s1,544
    800028ae:	03348463          	beq	s1,s3,800028d6 <wait+0x10c>
      if (pp->parent == p)
    800028b2:	7c9c                	ld	a5,56(s1)
    800028b4:	ff279be3          	bne	a5,s2,800028aa <wait+0xe0>
        acquire(&pp->lock);
    800028b8:	8526                	mv	a0,s1
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	318080e7          	jalr	792(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    800028c2:	4c9c                	lw	a5,24(s1)
    800028c4:	f55789e3          	beq	a5,s5,80002816 <wait+0x4c>
        release(&pp->lock);
    800028c8:	8526                	mv	a0,s1
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	3bc080e7          	jalr	956(ra) # 80000c86 <release>
        havekids = 1;
    800028d2:	875a                	mv	a4,s6
    800028d4:	bfd9                	j	800028aa <wait+0xe0>
    if (!havekids || killed(p))
    800028d6:	c31d                	beqz	a4,800028fc <wait+0x132>
    800028d8:	854a                	mv	a0,s2
    800028da:	00000097          	auipc	ra,0x0
    800028de:	ebe080e7          	jalr	-322(ra) # 80002798 <killed>
    800028e2:	ed09                	bnez	a0,800028fc <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028e4:	85e2                	mv	a1,s8
    800028e6:	854a                	mv	a0,s2
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	bfc080e7          	jalr	-1028(ra) # 800024e4 <sleep>
    havekids = 0;
    800028f0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028f2:	0000f497          	auipc	s1,0xf
    800028f6:	6be48493          	add	s1,s1,1726 # 80011fb0 <proc>
    800028fa:	bf65                	j	800028b2 <wait+0xe8>
      release(&wait_lock);
    800028fc:	0000e517          	auipc	a0,0xe
    80002900:	2fc50513          	add	a0,a0,764 # 80010bf8 <wait_lock>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	382080e7          	jalr	898(ra) # 80000c86 <release>
      return -1;
    8000290c:	59fd                	li	s3,-1
    8000290e:	b795                	j	80002872 <wait+0xa8>

0000000080002910 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002910:	7179                	add	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	e052                	sd	s4,0(sp)
    8000291e:	1800                	add	s0,sp,48
    80002920:	84aa                	mv	s1,a0
    80002922:	892e                	mv	s2,a1
    80002924:	89b2                	mv	s3,a2
    80002926:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	07e080e7          	jalr	126(ra) # 800019a6 <myproc>
  if (user_dst)
    80002930:	c08d                	beqz	s1,80002952 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002932:	86d2                	mv	a3,s4
    80002934:	864e                	mv	a2,s3
    80002936:	85ca                	mv	a1,s2
    80002938:	6928                	ld	a0,80(a0)
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	d2c080e7          	jalr	-724(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002942:	70a2                	ld	ra,40(sp)
    80002944:	7402                	ld	s0,32(sp)
    80002946:	64e2                	ld	s1,24(sp)
    80002948:	6942                	ld	s2,16(sp)
    8000294a:	69a2                	ld	s3,8(sp)
    8000294c:	6a02                	ld	s4,0(sp)
    8000294e:	6145                	add	sp,sp,48
    80002950:	8082                	ret
    memmove((char *)dst, src, len);
    80002952:	000a061b          	sext.w	a2,s4
    80002956:	85ce                	mv	a1,s3
    80002958:	854a                	mv	a0,s2
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	3d0080e7          	jalr	976(ra) # 80000d2a <memmove>
    return 0;
    80002962:	8526                	mv	a0,s1
    80002964:	bff9                	j	80002942 <either_copyout+0x32>

0000000080002966 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002966:	7179                	add	sp,sp,-48
    80002968:	f406                	sd	ra,40(sp)
    8000296a:	f022                	sd	s0,32(sp)
    8000296c:	ec26                	sd	s1,24(sp)
    8000296e:	e84a                	sd	s2,16(sp)
    80002970:	e44e                	sd	s3,8(sp)
    80002972:	e052                	sd	s4,0(sp)
    80002974:	1800                	add	s0,sp,48
    80002976:	892a                	mv	s2,a0
    80002978:	84ae                	mv	s1,a1
    8000297a:	89b2                	mv	s3,a2
    8000297c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	028080e7          	jalr	40(ra) # 800019a6 <myproc>
  if (user_src)
    80002986:	c08d                	beqz	s1,800029a8 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002988:	86d2                	mv	a3,s4
    8000298a:	864e                	mv	a2,s3
    8000298c:	85ca                	mv	a1,s2
    8000298e:	6928                	ld	a0,80(a0)
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	d62080e7          	jalr	-670(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002998:	70a2                	ld	ra,40(sp)
    8000299a:	7402                	ld	s0,32(sp)
    8000299c:	64e2                	ld	s1,24(sp)
    8000299e:	6942                	ld	s2,16(sp)
    800029a0:	69a2                	ld	s3,8(sp)
    800029a2:	6a02                	ld	s4,0(sp)
    800029a4:	6145                	add	sp,sp,48
    800029a6:	8082                	ret
    memmove(dst, (char *)src, len);
    800029a8:	000a061b          	sext.w	a2,s4
    800029ac:	85ce                	mv	a1,s3
    800029ae:	854a                	mv	a0,s2
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	37a080e7          	jalr	890(ra) # 80000d2a <memmove>
    return 0;
    800029b8:	8526                	mv	a0,s1
    800029ba:	bff9                	j	80002998 <either_copyin+0x32>

00000000800029bc <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800029bc:	715d                	add	sp,sp,-80
    800029be:	e486                	sd	ra,72(sp)
    800029c0:	e0a2                	sd	s0,64(sp)
    800029c2:	fc26                	sd	s1,56(sp)
    800029c4:	f84a                	sd	s2,48(sp)
    800029c6:	f44e                	sd	s3,40(sp)
    800029c8:	f052                	sd	s4,32(sp)
    800029ca:	ec56                	sd	s5,24(sp)
    800029cc:	e85a                	sd	s6,16(sp)
    800029ce:	e45e                	sd	s7,8(sp)
    800029d0:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800029d2:	00005517          	auipc	a0,0x5
    800029d6:	6f650513          	add	a0,a0,1782 # 800080c8 <digits+0x88>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	bac080e7          	jalr	-1108(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029e2:	0000f497          	auipc	s1,0xf
    800029e6:	72648493          	add	s1,s1,1830 # 80012108 <proc+0x158>
    800029ea:	00018917          	auipc	s2,0x18
    800029ee:	f1e90913          	add	s2,s2,-226 # 8001a908 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029f2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800029f4:	00006997          	auipc	s3,0x6
    800029f8:	89c98993          	add	s3,s3,-1892 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800029fc:	00006a97          	auipc	s5,0x6
    80002a00:	89ca8a93          	add	s5,s5,-1892 # 80008298 <digits+0x258>
    printf("\n");
    80002a04:	00005a17          	auipc	s4,0x5
    80002a08:	6c4a0a13          	add	s4,s4,1732 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0c:	00006b97          	auipc	s7,0x6
    80002a10:	8ccb8b93          	add	s7,s7,-1844 # 800082d8 <states.0>
    80002a14:	a00d                	j	80002a36 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a16:	ed86a583          	lw	a1,-296(a3)
    80002a1a:	8556                	mv	a0,s5
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b6a080e7          	jalr	-1174(ra) # 80000586 <printf>
    printf("\n");
    80002a24:	8552                	mv	a0,s4
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b60080e7          	jalr	-1184(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a2e:	22048493          	add	s1,s1,544
    80002a32:	03248263          	beq	s1,s2,80002a56 <procdump+0x9a>
    if (p->state == UNUSED)
    80002a36:	86a6                	mv	a3,s1
    80002a38:	ec04a783          	lw	a5,-320(s1)
    80002a3c:	dbed                	beqz	a5,80002a2e <procdump+0x72>
      state = "???";
    80002a3e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a40:	fcfb6be3          	bltu	s6,a5,80002a16 <procdump+0x5a>
    80002a44:	02079713          	sll	a4,a5,0x20
    80002a48:	01d75793          	srl	a5,a4,0x1d
    80002a4c:	97de                	add	a5,a5,s7
    80002a4e:	6390                	ld	a2,0(a5)
    80002a50:	f279                	bnez	a2,80002a16 <procdump+0x5a>
      state = "???";
    80002a52:	864e                	mv	a2,s3
    80002a54:	b7c9                	j	80002a16 <procdump+0x5a>
  }
}
    80002a56:	60a6                	ld	ra,72(sp)
    80002a58:	6406                	ld	s0,64(sp)
    80002a5a:	74e2                	ld	s1,56(sp)
    80002a5c:	7942                	ld	s2,48(sp)
    80002a5e:	79a2                	ld	s3,40(sp)
    80002a60:	7a02                	ld	s4,32(sp)
    80002a62:	6ae2                	ld	s5,24(sp)
    80002a64:	6b42                	ld	s6,16(sp)
    80002a66:	6ba2                	ld	s7,8(sp)
    80002a68:	6161                	add	sp,sp,80
    80002a6a:	8082                	ret

0000000080002a6c <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002a6c:	711d                	add	sp,sp,-96
    80002a6e:	ec86                	sd	ra,88(sp)
    80002a70:	e8a2                	sd	s0,80(sp)
    80002a72:	e4a6                	sd	s1,72(sp)
    80002a74:	e0ca                	sd	s2,64(sp)
    80002a76:	fc4e                	sd	s3,56(sp)
    80002a78:	f852                	sd	s4,48(sp)
    80002a7a:	f456                	sd	s5,40(sp)
    80002a7c:	f05a                	sd	s6,32(sp)
    80002a7e:	ec5e                	sd	s7,24(sp)
    80002a80:	e862                	sd	s8,16(sp)
    80002a82:	e466                	sd	s9,8(sp)
    80002a84:	e06a                	sd	s10,0(sp)
    80002a86:	1080                	add	s0,sp,96
    80002a88:	8b2a                	mv	s6,a0
    80002a8a:	8bae                	mv	s7,a1
    80002a8c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	f18080e7          	jalr	-232(ra) # 800019a6 <myproc>
    80002a96:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a98:	0000e517          	auipc	a0,0xe
    80002a9c:	16050513          	add	a0,a0,352 # 80010bf8 <wait_lock>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	132080e7          	jalr	306(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002aa8:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002aaa:	4a15                	li	s4,5
        havekids = 1;
    80002aac:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002aae:	00018997          	auipc	s3,0x18
    80002ab2:	d0298993          	add	s3,s3,-766 # 8001a7b0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002ab6:	0000ed17          	auipc	s10,0xe
    80002aba:	142d0d13          	add	s10,s10,322 # 80010bf8 <wait_lock>
    80002abe:	a8e9                	j	80002b98 <waitx+0x12c>
          pid = np->pid;
    80002ac0:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002ac4:	1684a783          	lw	a5,360(s1)
    80002ac8:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002acc:	16c4a703          	lw	a4,364(s1)
    80002ad0:	9f3d                	addw	a4,a4,a5
    80002ad2:	1704a783          	lw	a5,368(s1)
    80002ad6:	9f99                	subw	a5,a5,a4
    80002ad8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002adc:	000b0e63          	beqz	s6,80002af8 <waitx+0x8c>
    80002ae0:	4691                	li	a3,4
    80002ae2:	02c48613          	add	a2,s1,44
    80002ae6:	85da                	mv	a1,s6
    80002ae8:	05093503          	ld	a0,80(s2)
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	b7a080e7          	jalr	-1158(ra) # 80001666 <copyout>
    80002af4:	04054363          	bltz	a0,80002b3a <waitx+0xce>
          freeproc(np);
    80002af8:	8526                	mv	a0,s1
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	05e080e7          	jalr	94(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002b02:	8526                	mv	a0,s1
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	182080e7          	jalr	386(ra) # 80000c86 <release>
          release(&wait_lock);
    80002b0c:	0000e517          	auipc	a0,0xe
    80002b10:	0ec50513          	add	a0,a0,236 # 80010bf8 <wait_lock>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	172080e7          	jalr	370(ra) # 80000c86 <release>
  }
}
    80002b1c:	854e                	mv	a0,s3
    80002b1e:	60e6                	ld	ra,88(sp)
    80002b20:	6446                	ld	s0,80(sp)
    80002b22:	64a6                	ld	s1,72(sp)
    80002b24:	6906                	ld	s2,64(sp)
    80002b26:	79e2                	ld	s3,56(sp)
    80002b28:	7a42                	ld	s4,48(sp)
    80002b2a:	7aa2                	ld	s5,40(sp)
    80002b2c:	7b02                	ld	s6,32(sp)
    80002b2e:	6be2                	ld	s7,24(sp)
    80002b30:	6c42                	ld	s8,16(sp)
    80002b32:	6ca2                	ld	s9,8(sp)
    80002b34:	6d02                	ld	s10,0(sp)
    80002b36:	6125                	add	sp,sp,96
    80002b38:	8082                	ret
            release(&np->lock);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	14a080e7          	jalr	330(ra) # 80000c86 <release>
            release(&wait_lock);
    80002b44:	0000e517          	auipc	a0,0xe
    80002b48:	0b450513          	add	a0,a0,180 # 80010bf8 <wait_lock>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	13a080e7          	jalr	314(ra) # 80000c86 <release>
            return -1;
    80002b54:	59fd                	li	s3,-1
    80002b56:	b7d9                	j	80002b1c <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002b58:	22048493          	add	s1,s1,544
    80002b5c:	03348463          	beq	s1,s3,80002b84 <waitx+0x118>
      if (np->parent == p)
    80002b60:	7c9c                	ld	a5,56(s1)
    80002b62:	ff279be3          	bne	a5,s2,80002b58 <waitx+0xec>
        acquire(&np->lock);
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	06a080e7          	jalr	106(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002b70:	4c9c                	lw	a5,24(s1)
    80002b72:	f54787e3          	beq	a5,s4,80002ac0 <waitx+0x54>
        release(&np->lock);
    80002b76:	8526                	mv	a0,s1
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	10e080e7          	jalr	270(ra) # 80000c86 <release>
        havekids = 1;
    80002b80:	8756                	mv	a4,s5
    80002b82:	bfd9                	j	80002b58 <waitx+0xec>
    if (!havekids || p->killed)
    80002b84:	c305                	beqz	a4,80002ba4 <waitx+0x138>
    80002b86:	02892783          	lw	a5,40(s2)
    80002b8a:	ef89                	bnez	a5,80002ba4 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b8c:	85ea                	mv	a1,s10
    80002b8e:	854a                	mv	a0,s2
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	954080e7          	jalr	-1708(ra) # 800024e4 <sleep>
    havekids = 0;
    80002b98:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002b9a:	0000f497          	auipc	s1,0xf
    80002b9e:	41648493          	add	s1,s1,1046 # 80011fb0 <proc>
    80002ba2:	bf7d                	j	80002b60 <waitx+0xf4>
      release(&wait_lock);
    80002ba4:	0000e517          	auipc	a0,0xe
    80002ba8:	05450513          	add	a0,a0,84 # 80010bf8 <wait_lock>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	0da080e7          	jalr	218(ra) # 80000c86 <release>
      return -1;
    80002bb4:	59fd                	li	s3,-1
    80002bb6:	b79d                	j	80002b1c <waitx+0xb0>

0000000080002bb8 <update_time>:

void update_time()
{
    80002bb8:	7179                	add	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	ec26                	sd	s1,24(sp)
    80002bc0:	e84a                	sd	s2,16(sp)
    80002bc2:	e44e                	sd	s3,8(sp)
    80002bc4:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002bc6:	0000f497          	auipc	s1,0xf
    80002bca:	3ea48493          	add	s1,s1,1002 # 80011fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002bce:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002bd0:	00018917          	auipc	s2,0x18
    80002bd4:	be090913          	add	s2,s2,-1056 # 8001a7b0 <tickslock>
    80002bd8:	a811                	j	80002bec <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002bda:	8526                	mv	a0,s1
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002be4:	22048493          	add	s1,s1,544
    80002be8:	03248063          	beq	s1,s2,80002c08 <update_time+0x50>
    acquire(&p->lock);
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	fe4080e7          	jalr	-28(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002bf6:	4c9c                	lw	a5,24(s1)
    80002bf8:	ff3791e3          	bne	a5,s3,80002bda <update_time+0x22>
      p->rtime++;
    80002bfc:	1684a783          	lw	a5,360(s1)
    80002c00:	2785                	addw	a5,a5,1
    80002c02:	16f4a423          	sw	a5,360(s1)
    80002c06:	bfd1                	j	80002bda <update_time+0x22>
  }
    80002c08:	70a2                	ld	ra,40(sp)
    80002c0a:	7402                	ld	s0,32(sp)
    80002c0c:	64e2                	ld	s1,24(sp)
    80002c0e:	6942                	ld	s2,16(sp)
    80002c10:	69a2                	ld	s3,8(sp)
    80002c12:	6145                	add	sp,sp,48
    80002c14:	8082                	ret

0000000080002c16 <swtch>:
    80002c16:	00153023          	sd	ra,0(a0)
    80002c1a:	00253423          	sd	sp,8(a0)
    80002c1e:	e900                	sd	s0,16(a0)
    80002c20:	ed04                	sd	s1,24(a0)
    80002c22:	03253023          	sd	s2,32(a0)
    80002c26:	03353423          	sd	s3,40(a0)
    80002c2a:	03453823          	sd	s4,48(a0)
    80002c2e:	03553c23          	sd	s5,56(a0)
    80002c32:	05653023          	sd	s6,64(a0)
    80002c36:	05753423          	sd	s7,72(a0)
    80002c3a:	05853823          	sd	s8,80(a0)
    80002c3e:	05953c23          	sd	s9,88(a0)
    80002c42:	07a53023          	sd	s10,96(a0)
    80002c46:	07b53423          	sd	s11,104(a0)
    80002c4a:	0005b083          	ld	ra,0(a1)
    80002c4e:	0085b103          	ld	sp,8(a1)
    80002c52:	6980                	ld	s0,16(a1)
    80002c54:	6d84                	ld	s1,24(a1)
    80002c56:	0205b903          	ld	s2,32(a1)
    80002c5a:	0285b983          	ld	s3,40(a1)
    80002c5e:	0305ba03          	ld	s4,48(a1)
    80002c62:	0385ba83          	ld	s5,56(a1)
    80002c66:	0405bb03          	ld	s6,64(a1)
    80002c6a:	0485bb83          	ld	s7,72(a1)
    80002c6e:	0505bc03          	ld	s8,80(a1)
    80002c72:	0585bc83          	ld	s9,88(a1)
    80002c76:	0605bd03          	ld	s10,96(a1)
    80002c7a:	0685bd83          	ld	s11,104(a1)
    80002c7e:	8082                	ret

0000000080002c80 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002c80:	1141                	add	sp,sp,-16
    80002c82:	e406                	sd	ra,8(sp)
    80002c84:	e022                	sd	s0,0(sp)
    80002c86:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002c88:	00005597          	auipc	a1,0x5
    80002c8c:	68058593          	add	a1,a1,1664 # 80008308 <states.0+0x30>
    80002c90:	00018517          	auipc	a0,0x18
    80002c94:	b2050513          	add	a0,a0,-1248 # 8001a7b0 <tickslock>
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	eaa080e7          	jalr	-342(ra) # 80000b42 <initlock>
}
    80002ca0:	60a2                	ld	ra,8(sp)
    80002ca2:	6402                	ld	s0,0(sp)
    80002ca4:	0141                	add	sp,sp,16
    80002ca6:	8082                	ret

0000000080002ca8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ca8:	1141                	add	sp,sp,-16
    80002caa:	e422                	sd	s0,8(sp)
    80002cac:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cae:	00003797          	auipc	a5,0x3
    80002cb2:	6b278793          	add	a5,a5,1714 # 80006360 <kernelvec>
    80002cb6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cba:	6422                	ld	s0,8(sp)
    80002cbc:	0141                	add	sp,sp,16
    80002cbe:	8082                	ret

0000000080002cc0 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002cc0:	1141                	add	sp,sp,-16
    80002cc2:	e406                	sd	ra,8(sp)
    80002cc4:	e022                	sd	s0,0(sp)
    80002cc6:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	cde080e7          	jalr	-802(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cd4:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002cda:	00004697          	auipc	a3,0x4
    80002cde:	32668693          	add	a3,a3,806 # 80007000 <_trampoline>
    80002ce2:	00004717          	auipc	a4,0x4
    80002ce6:	31e70713          	add	a4,a4,798 # 80007000 <_trampoline>
    80002cea:	8f15                	sub	a4,a4,a3
    80002cec:	040007b7          	lui	a5,0x4000
    80002cf0:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002cf2:	07b2                	sll	a5,a5,0xc
    80002cf4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cfa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cfc:	18002673          	csrr	a2,satp
    80002d00:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d02:	6d30                	ld	a2,88(a0)
    80002d04:	6138                	ld	a4,64(a0)
    80002d06:	6585                	lui	a1,0x1
    80002d08:	972e                	add	a4,a4,a1
    80002d0a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d0c:	6d38                	ld	a4,88(a0)
    80002d0e:	00000617          	auipc	a2,0x0
    80002d12:	14260613          	add	a2,a2,322 # 80002e50 <usertrap>
    80002d16:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d18:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d1a:	8612                	mv	a2,tp
    80002d1c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d22:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d26:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d2e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d30:	6f18                	ld	a4,24(a4)
    80002d32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d36:	6928                	ld	a0,80(a0)
    80002d38:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d3a:	00004717          	auipc	a4,0x4
    80002d3e:	36270713          	add	a4,a4,866 # 8000709c <userret>
    80002d42:	8f15                	sub	a4,a4,a3
    80002d44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d46:	577d                	li	a4,-1
    80002d48:	177e                	sll	a4,a4,0x3f
    80002d4a:	8d59                	or	a0,a0,a4
    80002d4c:	9782                	jalr	a5
}
    80002d4e:	60a2                	ld	ra,8(sp)
    80002d50:	6402                	ld	s0,0(sp)
    80002d52:	0141                	add	sp,sp,16
    80002d54:	8082                	ret

0000000080002d56 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d56:	1101                	add	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	e04a                	sd	s2,0(sp)
    80002d60:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002d62:	00018917          	auipc	s2,0x18
    80002d66:	a4e90913          	add	s2,s2,-1458 # 8001a7b0 <tickslock>
    80002d6a:	854a                	mv	a0,s2
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	e66080e7          	jalr	-410(ra) # 80000bd2 <acquire>
  ticks++;
    80002d74:	00006497          	auipc	s1,0x6
    80002d78:	c0448493          	add	s1,s1,-1020 # 80008978 <ticks>
    80002d7c:	409c                	lw	a5,0(s1)
    80002d7e:	2785                	addw	a5,a5,1
    80002d80:	c09c                	sw	a5,0(s1)
  update_time();
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	e36080e7          	jalr	-458(ra) # 80002bb8 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002d8a:	8526                	mv	a0,s1
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	7bc080e7          	jalr	1980(ra) # 80002548 <wakeup>
  release(&tickslock);
    80002d94:	854a                	mv	a0,s2
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	ef0080e7          	jalr	-272(ra) # 80000c86 <release>
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	add	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002daa:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002dae:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002db0:	0807df63          	bgez	a5,80002e4e <devintr+0xa4>
{
    80002db4:	1101                	add	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	e426                	sd	s1,8(sp)
    80002dbc:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002dbe:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002dc2:	46a5                	li	a3,9
    80002dc4:	00d70d63          	beq	a4,a3,80002dde <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002dc8:	577d                	li	a4,-1
    80002dca:	177e                	sll	a4,a4,0x3f
    80002dcc:	0705                	add	a4,a4,1
    return 0;
    80002dce:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002dd0:	04e78e63          	beq	a5,a4,80002e2c <devintr+0x82>
  }
}
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	64a2                	ld	s1,8(sp)
    80002dda:	6105                	add	sp,sp,32
    80002ddc:	8082                	ret
    int irq = plic_claim();
    80002dde:	00003097          	auipc	ra,0x3
    80002de2:	68a080e7          	jalr	1674(ra) # 80006468 <plic_claim>
    80002de6:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002de8:	47a9                	li	a5,10
    80002dea:	02f50763          	beq	a0,a5,80002e18 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002dee:	4785                	li	a5,1
    80002df0:	02f50963          	beq	a0,a5,80002e22 <devintr+0x78>
    return 1;
    80002df4:	4505                	li	a0,1
    else if (irq)
    80002df6:	dcf9                	beqz	s1,80002dd4 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002df8:	85a6                	mv	a1,s1
    80002dfa:	00005517          	auipc	a0,0x5
    80002dfe:	51650513          	add	a0,a0,1302 # 80008310 <states.0+0x38>
    80002e02:	ffffd097          	auipc	ra,0xffffd
    80002e06:	784080e7          	jalr	1924(ra) # 80000586 <printf>
      plic_complete(irq);
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	00003097          	auipc	ra,0x3
    80002e10:	680080e7          	jalr	1664(ra) # 8000648c <plic_complete>
    return 1;
    80002e14:	4505                	li	a0,1
    80002e16:	bf7d                	j	80002dd4 <devintr+0x2a>
      uartintr();
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	b7c080e7          	jalr	-1156(ra) # 80000994 <uartintr>
    if (irq)
    80002e20:	b7ed                	j	80002e0a <devintr+0x60>
      virtio_disk_intr();
    80002e22:	00004097          	auipc	ra,0x4
    80002e26:	b30080e7          	jalr	-1232(ra) # 80006952 <virtio_disk_intr>
    if (irq)
    80002e2a:	b7c5                	j	80002e0a <devintr+0x60>
    if (cpuid() == 0)
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	b4e080e7          	jalr	-1202(ra) # 8000197a <cpuid>
    80002e34:	c901                	beqz	a0,80002e44 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e36:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e3a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e3c:	14479073          	csrw	sip,a5
    return 2;
    80002e40:	4509                	li	a0,2
    80002e42:	bf49                	j	80002dd4 <devintr+0x2a>
      clockintr();
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	f12080e7          	jalr	-238(ra) # 80002d56 <clockintr>
    80002e4c:	b7ed                	j	80002e36 <devintr+0x8c>
}
    80002e4e:	8082                	ret

0000000080002e50 <usertrap>:
{
    80002e50:	1101                	add	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	e426                	sd	s1,8(sp)
    80002e58:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e5e:	1007f793          	and	a5,a5,256
    80002e62:	e7b1                	bnez	a5,80002eae <usertrap+0x5e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e64:	00003797          	auipc	a5,0x3
    80002e68:	4fc78793          	add	a5,a5,1276 # 80006360 <kernelvec>
    80002e6c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	b36080e7          	jalr	-1226(ra) # 800019a6 <myproc>
    80002e78:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e7a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e7c:	14102773          	csrr	a4,sepc
    80002e80:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e82:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e86:	47a1                	li	a5,8
    80002e88:	02f70b63          	beq	a4,a5,80002ebe <usertrap+0x6e>
  else if ((which_dev = devintr()) != 0)
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	f1e080e7          	jalr	-226(ra) # 80002daa <devintr>
    80002e94:	cd61                	beqz	a0,80002f6c <usertrap+0x11c>
    if (which_dev == 2)
    80002e96:	4789                	li	a5,2
    80002e98:	04f51663          	bne	a0,a5,80002ee4 <usertrap+0x94>
      if (p != 0 && p->state == RUNNING)
    80002e9c:	4c98                	lw	a4,24(s1)
    80002e9e:	4791                	li	a5,4
    80002ea0:	06f70763          	beq	a4,a5,80002f0e <usertrap+0xbe>
    yield();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	604080e7          	jalr	1540(ra) # 800024a8 <yield>
    80002eac:	a825                	j	80002ee4 <usertrap+0x94>
    panic("usertrap: not from user mode");
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	48250513          	add	a0,a0,1154 # 80008330 <states.0+0x58>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	686080e7          	jalr	1670(ra) # 8000053c <panic>
    if (killed(p))
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	8da080e7          	jalr	-1830(ra) # 80002798 <killed>
    80002ec6:	ed15                	bnez	a0,80002f02 <usertrap+0xb2>
    p->trapframe->epc += 4;
    80002ec8:	6cb8                	ld	a4,88(s1)
    80002eca:	6f1c                	ld	a5,24(a4)
    80002ecc:	0791                	add	a5,a5,4
    80002ece:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ed4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed8:	10079073          	csrw	sstatus,a5
    syscall();
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	320080e7          	jalr	800(ra) # 800031fc <syscall>
  if (killed(p))
    80002ee4:	8526                	mv	a0,s1
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	8b2080e7          	jalr	-1870(ra) # 80002798 <killed>
    80002eee:	ed45                	bnez	a0,80002fa6 <usertrap+0x156>
  usertrapret();
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	dd0080e7          	jalr	-560(ra) # 80002cc0 <usertrapret>
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	64a2                	ld	s1,8(sp)
    80002efe:	6105                	add	sp,sp,32
    80002f00:	8082                	ret
      exit(-1);
    80002f02:	557d                	li	a0,-1
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	714080e7          	jalr	1812(ra) # 80002618 <exit>
    80002f0c:	bf75                	j	80002ec8 <usertrap+0x78>
        p->ticks_count++;
    80002f0e:	2004a783          	lw	a5,512(s1)
    80002f12:	2785                	addw	a5,a5,1
    80002f14:	0007871b          	sext.w	a4,a5
    80002f18:	20f4a023          	sw	a5,512(s1)
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    80002f1c:	1f04a783          	lw	a5,496(s1)
    80002f20:	f8f052e3          	blez	a5,80002ea4 <usertrap+0x54>
    80002f24:	f8f740e3          	blt	a4,a5,80002ea4 <usertrap+0x54>
    80002f28:	2044a783          	lw	a5,516(s1)
    80002f2c:	dfa5                	beqz	a5,80002ea4 <usertrap+0x54>
          p->alarm_on = 0; // Disable alarm while handler is running
    80002f2e:	2004a223          	sw	zero,516(s1)
          p->alarm_tf = kalloc();
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	bb0080e7          	jalr	-1104(ra) # 80000ae2 <kalloc>
    80002f3a:	20a4b423          	sd	a0,520(s1)
          if (p->alarm_tf == 0)
    80002f3e:	cd19                	beqz	a0,80002f5c <usertrap+0x10c>
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    80002f40:	12000613          	li	a2,288
    80002f44:	6cac                	ld	a1,88(s1)
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	de4080e7          	jalr	-540(ra) # 80000d2a <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    80002f4e:	6cbc                	ld	a5,88(s1)
    80002f50:	1f84b703          	ld	a4,504(s1)
    80002f54:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    80002f56:	2004a023          	sw	zero,512(s1)
    80002f5a:	b7a9                	j	80002ea4 <usertrap+0x54>
            panic("Error !! usertrap: out of memory");
    80002f5c:	00005517          	auipc	a0,0x5
    80002f60:	3f450513          	add	a0,a0,1012 # 80008350 <states.0+0x78>
    80002f64:	ffffd097          	auipc	ra,0xffffd
    80002f68:	5d8080e7          	jalr	1496(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f6c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f70:	5890                	lw	a2,48(s1)
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	40650513          	add	a0,a0,1030 # 80008378 <states.0+0xa0>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	60c080e7          	jalr	1548(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f86:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	41e50513          	add	a0,a0,1054 # 800083a8 <states.0+0xd0>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5f4080e7          	jalr	1524(ra) # 80000586 <printf>
    setkilled(p);
    80002f9a:	8526                	mv	a0,s1
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	7d0080e7          	jalr	2000(ra) # 8000276c <setkilled>
  if (which_dev == 2)
    80002fa4:	b781                	j	80002ee4 <usertrap+0x94>
    exit(-1);
    80002fa6:	557d                	li	a0,-1
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	670080e7          	jalr	1648(ra) # 80002618 <exit>
    80002fb0:	b781                	j	80002ef0 <usertrap+0xa0>

0000000080002fb2 <kerneltrap>:
{
    80002fb2:	7179                	add	sp,sp,-48
    80002fb4:	f406                	sd	ra,40(sp)
    80002fb6:	f022                	sd	s0,32(sp)
    80002fb8:	ec26                	sd	s1,24(sp)
    80002fba:	e84a                	sd	s2,16(sp)
    80002fbc:	e44e                	sd	s3,8(sp)
    80002fbe:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fc0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fc8:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002fcc:	1004f793          	and	a5,s1,256
    80002fd0:	cb85                	beqz	a5,80003000 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fd6:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002fd8:	ef85                	bnez	a5,80003010 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	dd0080e7          	jalr	-560(ra) # 80002daa <devintr>
    80002fe2:	cd1d                	beqz	a0,80003020 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fe4:	4789                	li	a5,2
    80002fe6:	06f50a63          	beq	a0,a5,8000305a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fea:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fee:	10049073          	csrw	sstatus,s1
}
    80002ff2:	70a2                	ld	ra,40(sp)
    80002ff4:	7402                	ld	s0,32(sp)
    80002ff6:	64e2                	ld	s1,24(sp)
    80002ff8:	6942                	ld	s2,16(sp)
    80002ffa:	69a2                	ld	s3,8(sp)
    80002ffc:	6145                	add	sp,sp,48
    80002ffe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003000:	00005517          	auipc	a0,0x5
    80003004:	3c850513          	add	a0,a0,968 # 800083c8 <states.0+0xf0>
    80003008:	ffffd097          	auipc	ra,0xffffd
    8000300c:	534080e7          	jalr	1332(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80003010:	00005517          	auipc	a0,0x5
    80003014:	3e050513          	add	a0,a0,992 # 800083f0 <states.0+0x118>
    80003018:	ffffd097          	auipc	ra,0xffffd
    8000301c:	524080e7          	jalr	1316(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80003020:	85ce                	mv	a1,s3
    80003022:	00005517          	auipc	a0,0x5
    80003026:	3ee50513          	add	a0,a0,1006 # 80008410 <states.0+0x138>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	55c080e7          	jalr	1372(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003032:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003036:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000303a:	00005517          	auipc	a0,0x5
    8000303e:	3e650513          	add	a0,a0,998 # 80008420 <states.0+0x148>
    80003042:	ffffd097          	auipc	ra,0xffffd
    80003046:	544080e7          	jalr	1348(ra) # 80000586 <printf>
    panic("kerneltrap");
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	3ee50513          	add	a0,a0,1006 # 80008438 <states.0+0x160>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	4ea080e7          	jalr	1258(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	94c080e7          	jalr	-1716(ra) # 800019a6 <myproc>
    80003062:	d541                	beqz	a0,80002fea <kerneltrap+0x38>
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	942080e7          	jalr	-1726(ra) # 800019a6 <myproc>
    8000306c:	4d18                	lw	a4,24(a0)
    8000306e:	4791                	li	a5,4
    80003070:	f6f71de3          	bne	a4,a5,80002fea <kerneltrap+0x38>
    yield();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	434080e7          	jalr	1076(ra) # 800024a8 <yield>
    8000307c:	b7bd                	j	80002fea <kerneltrap+0x38>

000000008000307e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000307e:	1101                	add	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	e426                	sd	s1,8(sp)
    80003086:	1000                	add	s0,sp,32
    80003088:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	91c080e7          	jalr	-1764(ra) # 800019a6 <myproc>
  switch (n)
    80003092:	4795                	li	a5,5
    80003094:	0497e163          	bltu	a5,s1,800030d6 <argraw+0x58>
    80003098:	048a                	sll	s1,s1,0x2
    8000309a:	00005717          	auipc	a4,0x5
    8000309e:	3d670713          	add	a4,a4,982 # 80008470 <states.0+0x198>
    800030a2:	94ba                	add	s1,s1,a4
    800030a4:	409c                	lw	a5,0(s1)
    800030a6:	97ba                	add	a5,a5,a4
    800030a8:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800030aa:	6d3c                	ld	a5,88(a0)
    800030ac:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6105                	add	sp,sp,32
    800030b6:	8082                	ret
    return p->trapframe->a1;
    800030b8:	6d3c                	ld	a5,88(a0)
    800030ba:	7fa8                	ld	a0,120(a5)
    800030bc:	bfcd                	j	800030ae <argraw+0x30>
    return p->trapframe->a2;
    800030be:	6d3c                	ld	a5,88(a0)
    800030c0:	63c8                	ld	a0,128(a5)
    800030c2:	b7f5                	j	800030ae <argraw+0x30>
    return p->trapframe->a3;
    800030c4:	6d3c                	ld	a5,88(a0)
    800030c6:	67c8                	ld	a0,136(a5)
    800030c8:	b7dd                	j	800030ae <argraw+0x30>
    return p->trapframe->a4;
    800030ca:	6d3c                	ld	a5,88(a0)
    800030cc:	6bc8                	ld	a0,144(a5)
    800030ce:	b7c5                	j	800030ae <argraw+0x30>
    return p->trapframe->a5;
    800030d0:	6d3c                	ld	a5,88(a0)
    800030d2:	6fc8                	ld	a0,152(a5)
    800030d4:	bfe9                	j	800030ae <argraw+0x30>
  panic("argraw");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	37250513          	add	a0,a0,882 # 80008448 <states.0+0x170>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	45e080e7          	jalr	1118(ra) # 8000053c <panic>

00000000800030e6 <fetchaddr>:
{
    800030e6:	1101                	add	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	e04a                	sd	s2,0(sp)
    800030f0:	1000                	add	s0,sp,32
    800030f2:	84aa                	mv	s1,a0
    800030f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	8b0080e7          	jalr	-1872(ra) # 800019a6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800030fe:	653c                	ld	a5,72(a0)
    80003100:	02f4f863          	bgeu	s1,a5,80003130 <fetchaddr+0x4a>
    80003104:	00848713          	add	a4,s1,8
    80003108:	02e7e663          	bltu	a5,a4,80003134 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000310c:	46a1                	li	a3,8
    8000310e:	8626                	mv	a2,s1
    80003110:	85ca                	mv	a1,s2
    80003112:	6928                	ld	a0,80(a0)
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	5de080e7          	jalr	1502(ra) # 800016f2 <copyin>
    8000311c:	00a03533          	snez	a0,a0
    80003120:	40a00533          	neg	a0,a0
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6902                	ld	s2,0(sp)
    8000312c:	6105                	add	sp,sp,32
    8000312e:	8082                	ret
    return -1;
    80003130:	557d                	li	a0,-1
    80003132:	bfcd                	j	80003124 <fetchaddr+0x3e>
    80003134:	557d                	li	a0,-1
    80003136:	b7fd                	j	80003124 <fetchaddr+0x3e>

0000000080003138 <fetchstr>:
{
    80003138:	7179                	add	sp,sp,-48
    8000313a:	f406                	sd	ra,40(sp)
    8000313c:	f022                	sd	s0,32(sp)
    8000313e:	ec26                	sd	s1,24(sp)
    80003140:	e84a                	sd	s2,16(sp)
    80003142:	e44e                	sd	s3,8(sp)
    80003144:	1800                	add	s0,sp,48
    80003146:	892a                	mv	s2,a0
    80003148:	84ae                	mv	s1,a1
    8000314a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000314c:	fffff097          	auipc	ra,0xfffff
    80003150:	85a080e7          	jalr	-1958(ra) # 800019a6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003154:	86ce                	mv	a3,s3
    80003156:	864a                	mv	a2,s2
    80003158:	85a6                	mv	a1,s1
    8000315a:	6928                	ld	a0,80(a0)
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	624080e7          	jalr	1572(ra) # 80001780 <copyinstr>
    80003164:	00054e63          	bltz	a0,80003180 <fetchstr+0x48>
  return strlen(buf);
    80003168:	8526                	mv	a0,s1
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	cde080e7          	jalr	-802(ra) # 80000e48 <strlen>
}
    80003172:	70a2                	ld	ra,40(sp)
    80003174:	7402                	ld	s0,32(sp)
    80003176:	64e2                	ld	s1,24(sp)
    80003178:	6942                	ld	s2,16(sp)
    8000317a:	69a2                	ld	s3,8(sp)
    8000317c:	6145                	add	sp,sp,48
    8000317e:	8082                	ret
    return -1;
    80003180:	557d                	li	a0,-1
    80003182:	bfc5                	j	80003172 <fetchstr+0x3a>

0000000080003184 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003184:	1101                	add	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	add	s0,sp,32
    8000318e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003190:	00000097          	auipc	ra,0x0
    80003194:	eee080e7          	jalr	-274(ra) # 8000307e <argraw>
    80003198:	c088                	sw	a0,0(s1)
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	64a2                	ld	s1,8(sp)
    800031a0:	6105                	add	sp,sp,32
    800031a2:	8082                	ret

00000000800031a4 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    800031a4:	1101                	add	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	e426                	sd	s1,8(sp)
    800031ac:	1000                	add	s0,sp,32
    800031ae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031b0:	00000097          	auipc	ra,0x0
    800031b4:	ece080e7          	jalr	-306(ra) # 8000307e <argraw>
    800031b8:	e088                	sd	a0,0(s1)
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6105                	add	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800031c4:	7179                	add	sp,sp,-48
    800031c6:	f406                	sd	ra,40(sp)
    800031c8:	f022                	sd	s0,32(sp)
    800031ca:	ec26                	sd	s1,24(sp)
    800031cc:	e84a                	sd	s2,16(sp)
    800031ce:	1800                	add	s0,sp,48
    800031d0:	84ae                	mv	s1,a1
    800031d2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031d4:	fd840593          	add	a1,s0,-40
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	fcc080e7          	jalr	-52(ra) # 800031a4 <argaddr>
  return fetchstr(addr, buf, max);
    800031e0:	864a                	mv	a2,s2
    800031e2:	85a6                	mv	a1,s1
    800031e4:	fd843503          	ld	a0,-40(s0)
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	f50080e7          	jalr	-176(ra) # 80003138 <fetchstr>
}
    800031f0:	70a2                	ld	ra,40(sp)
    800031f2:	7402                	ld	s0,32(sp)
    800031f4:	64e2                	ld	s1,24(sp)
    800031f6:	6942                	ld	s2,16(sp)
    800031f8:	6145                	add	sp,sp,48
    800031fa:	8082                	ret

00000000800031fc <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    800031fc:	1101                	add	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	e04a                	sd	s2,0(sp)
    80003206:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	79e080e7          	jalr	1950(ra) # 800019a6 <myproc>
    80003210:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003212:	05853903          	ld	s2,88(a0)
    80003216:	0a893783          	ld	a5,168(s2)
    8000321a:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000321e:	37fd                	addw	a5,a5,-1
    80003220:	4765                	li	a4,25
    80003222:	02f76763          	bltu	a4,a5,80003250 <syscall+0x54>
    80003226:	00369713          	sll	a4,a3,0x3
    8000322a:	00005797          	auipc	a5,0x5
    8000322e:	25e78793          	add	a5,a5,606 # 80008488 <syscalls>
    80003232:	97ba                	add	a5,a5,a4
    80003234:	6398                	ld	a4,0(a5)
    80003236:	cf09                	beqz	a4,80003250 <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    80003238:	068a                	sll	a3,a3,0x2
    8000323a:	00d504b3          	add	s1,a0,a3
    8000323e:	1704a783          	lw	a5,368(s1)
    80003242:	2785                	addw	a5,a5,1
    80003244:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    80003248:	9702                	jalr	a4
    8000324a:	06a93823          	sd	a0,112(s2)
    8000324e:	a839                	j	8000326c <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003250:	15848613          	add	a2,s1,344
    80003254:	588c                	lw	a1,48(s1)
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	1fa50513          	add	a0,a0,506 # 80008450 <states.0+0x178>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	328080e7          	jalr	808(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003266:	6cbc                	ld	a5,88(s1)
    80003268:	577d                	li	a4,-1
    8000326a:	fbb8                	sd	a4,112(a5)
  }
}
    8000326c:	60e2                	ld	ra,24(sp)
    8000326e:	6442                	ld	s0,16(sp)
    80003270:	64a2                	ld	s1,8(sp)
    80003272:	6902                	ld	s2,0(sp)
    80003274:	6105                	add	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    80003278:	1101                	add	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003280:	fec40593          	add	a1,s0,-20
    80003284:	4501                	li	a0,0
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	efe080e7          	jalr	-258(ra) # 80003184 <argint>
  exit(n);
    8000328e:	fec42503          	lw	a0,-20(s0)
    80003292:	fffff097          	auipc	ra,0xfffff
    80003296:	386080e7          	jalr	902(ra) # 80002618 <exit>
  return 0; // not reached
}
    8000329a:	4501                	li	a0,0
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	6105                	add	sp,sp,32
    800032a2:	8082                	ret

00000000800032a4 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032a4:	1141                	add	sp,sp,-16
    800032a6:	e406                	sd	ra,8(sp)
    800032a8:	e022                	sd	s0,0(sp)
    800032aa:	0800                	add	s0,sp,16
  return myproc()->pid;
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	6fa080e7          	jalr	1786(ra) # 800019a6 <myproc>
}
    800032b4:	5908                	lw	a0,48(a0)
    800032b6:	60a2                	ld	ra,8(sp)
    800032b8:	6402                	ld	s0,0(sp)
    800032ba:	0141                	add	sp,sp,16
    800032bc:	8082                	ret

00000000800032be <sys_fork>:

uint64
sys_fork(void)
{
    800032be:	1141                	add	sp,sp,-16
    800032c0:	e406                	sd	ra,8(sp)
    800032c2:	e022                	sd	s0,0(sp)
    800032c4:	0800                	add	s0,sp,16
  return fork();
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	ae4080e7          	jalr	-1308(ra) # 80001daa <fork>
}
    800032ce:	60a2                	ld	ra,8(sp)
    800032d0:	6402                	ld	s0,0(sp)
    800032d2:	0141                	add	sp,sp,16
    800032d4:	8082                	ret

00000000800032d6 <sys_wait>:

uint64
sys_wait(void)
{
    800032d6:	1101                	add	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800032de:	fe840593          	add	a1,s0,-24
    800032e2:	4501                	li	a0,0
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	ec0080e7          	jalr	-320(ra) # 800031a4 <argaddr>
  return wait(p);
    800032ec:	fe843503          	ld	a0,-24(s0)
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	4da080e7          	jalr	1242(ra) # 800027ca <wait>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	6105                	add	sp,sp,32
    800032fe:	8082                	ret

0000000080003300 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003300:	7179                	add	sp,sp,-48
    80003302:	f406                	sd	ra,40(sp)
    80003304:	f022                	sd	s0,32(sp)
    80003306:	ec26                	sd	s1,24(sp)
    80003308:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000330a:	fdc40593          	add	a1,s0,-36
    8000330e:	4501                	li	a0,0
    80003310:	00000097          	auipc	ra,0x0
    80003314:	e74080e7          	jalr	-396(ra) # 80003184 <argint>
  addr = myproc()->sz;
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	68e080e7          	jalr	1678(ra) # 800019a6 <myproc>
    80003320:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003322:	fdc42503          	lw	a0,-36(s0)
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	a28080e7          	jalr	-1496(ra) # 80001d4e <growproc>
    8000332e:	00054863          	bltz	a0,8000333e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003332:	8526                	mv	a0,s1
    80003334:	70a2                	ld	ra,40(sp)
    80003336:	7402                	ld	s0,32(sp)
    80003338:	64e2                	ld	s1,24(sp)
    8000333a:	6145                	add	sp,sp,48
    8000333c:	8082                	ret
    return -1;
    8000333e:	54fd                	li	s1,-1
    80003340:	bfcd                	j	80003332 <sys_sbrk+0x32>

0000000080003342 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003342:	7139                	add	sp,sp,-64
    80003344:	fc06                	sd	ra,56(sp)
    80003346:	f822                	sd	s0,48(sp)
    80003348:	f426                	sd	s1,40(sp)
    8000334a:	f04a                	sd	s2,32(sp)
    8000334c:	ec4e                	sd	s3,24(sp)
    8000334e:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003350:	fcc40593          	add	a1,s0,-52
    80003354:	4501                	li	a0,0
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	e2e080e7          	jalr	-466(ra) # 80003184 <argint>
  acquire(&tickslock);
    8000335e:	00017517          	auipc	a0,0x17
    80003362:	45250513          	add	a0,a0,1106 # 8001a7b0 <tickslock>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	86c080e7          	jalr	-1940(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000336e:	00005917          	auipc	s2,0x5
    80003372:	60a92903          	lw	s2,1546(s2) # 80008978 <ticks>
  while (ticks - ticks0 < n)
    80003376:	fcc42783          	lw	a5,-52(s0)
    8000337a:	cf9d                	beqz	a5,800033b8 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000337c:	00017997          	auipc	s3,0x17
    80003380:	43498993          	add	s3,s3,1076 # 8001a7b0 <tickslock>
    80003384:	00005497          	auipc	s1,0x5
    80003388:	5f448493          	add	s1,s1,1524 # 80008978 <ticks>
    if (killed(myproc()))
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	61a080e7          	jalr	1562(ra) # 800019a6 <myproc>
    80003394:	fffff097          	auipc	ra,0xfffff
    80003398:	404080e7          	jalr	1028(ra) # 80002798 <killed>
    8000339c:	ed15                	bnez	a0,800033d8 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000339e:	85ce                	mv	a1,s3
    800033a0:	8526                	mv	a0,s1
    800033a2:	fffff097          	auipc	ra,0xfffff
    800033a6:	142080e7          	jalr	322(ra) # 800024e4 <sleep>
  while (ticks - ticks0 < n)
    800033aa:	409c                	lw	a5,0(s1)
    800033ac:	412787bb          	subw	a5,a5,s2
    800033b0:	fcc42703          	lw	a4,-52(s0)
    800033b4:	fce7ece3          	bltu	a5,a4,8000338c <sys_sleep+0x4a>
  }
  release(&tickslock);
    800033b8:	00017517          	auipc	a0,0x17
    800033bc:	3f850513          	add	a0,a0,1016 # 8001a7b0 <tickslock>
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	8c6080e7          	jalr	-1850(ra) # 80000c86 <release>
  return 0;
    800033c8:	4501                	li	a0,0
}
    800033ca:	70e2                	ld	ra,56(sp)
    800033cc:	7442                	ld	s0,48(sp)
    800033ce:	74a2                	ld	s1,40(sp)
    800033d0:	7902                	ld	s2,32(sp)
    800033d2:	69e2                	ld	s3,24(sp)
    800033d4:	6121                	add	sp,sp,64
    800033d6:	8082                	ret
      release(&tickslock);
    800033d8:	00017517          	auipc	a0,0x17
    800033dc:	3d850513          	add	a0,a0,984 # 8001a7b0 <tickslock>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8a6080e7          	jalr	-1882(ra) # 80000c86 <release>
      return -1;
    800033e8:	557d                	li	a0,-1
    800033ea:	b7c5                	j	800033ca <sys_sleep+0x88>

00000000800033ec <sys_kill>:

uint64
sys_kill(void)
{
    800033ec:	1101                	add	sp,sp,-32
    800033ee:	ec06                	sd	ra,24(sp)
    800033f0:	e822                	sd	s0,16(sp)
    800033f2:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800033f4:	fec40593          	add	a1,s0,-20
    800033f8:	4501                	li	a0,0
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	d8a080e7          	jalr	-630(ra) # 80003184 <argint>
  return kill(pid);
    80003402:	fec42503          	lw	a0,-20(s0)
    80003406:	fffff097          	auipc	ra,0xfffff
    8000340a:	2f4080e7          	jalr	756(ra) # 800026fa <kill>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	6105                	add	sp,sp,32
    80003414:	8082                	ret

0000000080003416 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003416:	1101                	add	sp,sp,-32
    80003418:	ec06                	sd	ra,24(sp)
    8000341a:	e822                	sd	s0,16(sp)
    8000341c:	e426                	sd	s1,8(sp)
    8000341e:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003420:	00017517          	auipc	a0,0x17
    80003424:	39050513          	add	a0,a0,912 # 8001a7b0 <tickslock>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	7aa080e7          	jalr	1962(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003430:	00005497          	auipc	s1,0x5
    80003434:	5484a483          	lw	s1,1352(s1) # 80008978 <ticks>
  release(&tickslock);
    80003438:	00017517          	auipc	a0,0x17
    8000343c:	37850513          	add	a0,a0,888 # 8001a7b0 <tickslock>
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	846080e7          	jalr	-1978(ra) # 80000c86 <release>
  return xticks;
}
    80003448:	02049513          	sll	a0,s1,0x20
    8000344c:	9101                	srl	a0,a0,0x20
    8000344e:	60e2                	ld	ra,24(sp)
    80003450:	6442                	ld	s0,16(sp)
    80003452:	64a2                	ld	s1,8(sp)
    80003454:	6105                	add	sp,sp,32
    80003456:	8082                	ret

0000000080003458 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003458:	7139                	add	sp,sp,-64
    8000345a:	fc06                	sd	ra,56(sp)
    8000345c:	f822                	sd	s0,48(sp)
    8000345e:	f426                	sd	s1,40(sp)
    80003460:	f04a                	sd	s2,32(sp)
    80003462:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003464:	fd840593          	add	a1,s0,-40
    80003468:	4501                	li	a0,0
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	d3a080e7          	jalr	-710(ra) # 800031a4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003472:	fd040593          	add	a1,s0,-48
    80003476:	4505                	li	a0,1
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	d2c080e7          	jalr	-724(ra) # 800031a4 <argaddr>
  argaddr(2, &addr2);
    80003480:	fc840593          	add	a1,s0,-56
    80003484:	4509                	li	a0,2
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	d1e080e7          	jalr	-738(ra) # 800031a4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000348e:	fc040613          	add	a2,s0,-64
    80003492:	fc440593          	add	a1,s0,-60
    80003496:	fd843503          	ld	a0,-40(s0)
    8000349a:	fffff097          	auipc	ra,0xfffff
    8000349e:	5d2080e7          	jalr	1490(ra) # 80002a6c <waitx>
    800034a2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	502080e7          	jalr	1282(ra) # 800019a6 <myproc>
    800034ac:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034ae:	4691                	li	a3,4
    800034b0:	fc440613          	add	a2,s0,-60
    800034b4:	fd043583          	ld	a1,-48(s0)
    800034b8:	6928                	ld	a0,80(a0)
    800034ba:	ffffe097          	auipc	ra,0xffffe
    800034be:	1ac080e7          	jalr	428(ra) # 80001666 <copyout>
    return -1;
    800034c2:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034c4:	00054f63          	bltz	a0,800034e2 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800034c8:	4691                	li	a3,4
    800034ca:	fc040613          	add	a2,s0,-64
    800034ce:	fc843583          	ld	a1,-56(s0)
    800034d2:	68a8                	ld	a0,80(s1)
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	192080e7          	jalr	402(ra) # 80001666 <copyout>
    800034dc:	00054a63          	bltz	a0,800034f0 <sys_waitx+0x98>
    return -1;
  return ret;
    800034e0:	87ca                	mv	a5,s2
}
    800034e2:	853e                	mv	a0,a5
    800034e4:	70e2                	ld	ra,56(sp)
    800034e6:	7442                	ld	s0,48(sp)
    800034e8:	74a2                	ld	s1,40(sp)
    800034ea:	7902                	ld	s2,32(sp)
    800034ec:	6121                	add	sp,sp,64
    800034ee:	8082                	ret
    return -1;
    800034f0:	57fd                	li	a5,-1
    800034f2:	bfc5                	j	800034e2 <sys_waitx+0x8a>

00000000800034f4 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    800034f4:	7179                	add	sp,sp,-48
    800034f6:	f406                	sd	ra,40(sp)
    800034f8:	f022                	sd	s0,32(sp)
    800034fa:	ec26                	sd	s1,24(sp)
    800034fc:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    800034fe:	ffffe097          	auipc	ra,0xffffe
    80003502:	4a8080e7          	jalr	1192(ra) # 800019a6 <myproc>
    80003506:	84aa                	mv	s1,a0
  // for (int i = 0; i < 31; i++)
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }

  argint(0, &mask);
    80003508:	fdc40593          	add	a1,s0,-36
    8000350c:	4501                	li	a0,0
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	c76080e7          	jalr	-906(ra) # 80003184 <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    80003516:	fdc42583          	lw	a1,-36(s0)
    8000351a:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    8000351e:	4781                	li	a5,0
  int count = 0;
    80003520:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    80003522:	467d                	li	a2,31
    80003524:	a029                	j	8000352e <sys_getSysCount+0x3a>
    80003526:	2785                	addw	a5,a5,1
    80003528:	0691                	add	a3,a3,4
    8000352a:	00c78963          	beq	a5,a2,8000353c <sys_getSysCount+0x48>
    if (mask & (1 << i))
    8000352e:	40f5d73b          	sraw	a4,a1,a5
    80003532:	8b05                	and	a4,a4,1
    80003534:	db6d                	beqz	a4,80003526 <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i - 1]; // Add up the syscall counts
    80003536:	4298                	lw	a4,0(a3)
    80003538:	9d39                	addw	a0,a0,a4
    8000353a:	b7f5                	j	80003526 <sys_getSysCount+0x32>
    }
  }

  return count;
}
    8000353c:	70a2                	ld	ra,40(sp)
    8000353e:	7402                	ld	s0,32(sp)
    80003540:	64e2                	ld	s1,24(sp)
    80003542:	6145                	add	sp,sp,48
    80003544:	8082                	ret

0000000080003546 <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    80003546:	1101                	add	sp,sp,-32
    80003548:	ec06                	sd	ra,24(sp)
    8000354a:	e822                	sd	s0,16(sp)
    8000354c:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    8000354e:	fec40593          	add	a1,s0,-20
    80003552:	4501                	li	a0,0
    80003554:	00000097          	auipc	ra,0x0
    80003558:	c30080e7          	jalr	-976(ra) # 80003184 <argint>

  argaddr(1, &handler);
    8000355c:	fe040593          	add	a1,s0,-32
    80003560:	4505                	li	a0,1
    80003562:	00000097          	auipc	ra,0x0
    80003566:	c42080e7          	jalr	-958(ra) # 800031a4 <argaddr>

  struct proc *p = myproc();
    8000356a:	ffffe097          	auipc	ra,0xffffe
    8000356e:	43c080e7          	jalr	1084(ra) # 800019a6 <myproc>
  p->alarm_interval = interval;
    80003572:	fec42783          	lw	a5,-20(s0)
    80003576:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void (*)())handler;
    8000357a:	fe043703          	ld	a4,-32(s0)
    8000357e:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    80003582:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    80003586:	00f027b3          	sgtz	a5,a5
    8000358a:	20f52223          	sw	a5,516(a0)

  return 0;
}
    8000358e:	4501                	li	a0,0
    80003590:	60e2                	ld	ra,24(sp)
    80003592:	6442                	ld	s0,16(sp)
    80003594:	6105                	add	sp,sp,32
    80003596:	8082                	ret

0000000080003598 <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    80003598:	1101                	add	sp,sp,-32
    8000359a:	ec06                	sd	ra,24(sp)
    8000359c:	e822                	sd	s0,16(sp)
    8000359e:	e426                	sd	s1,8(sp)
    800035a0:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800035a2:	ffffe097          	auipc	ra,0xffffe
    800035a6:	404080e7          	jalr	1028(ra) # 800019a6 <myproc>

  if (p->alarm_tf)
    800035aa:	20853583          	ld	a1,520(a0)
    800035ae:	c585                	beqz	a1,800035d6 <sys_sigreturn+0x3e>
    800035b0:	84aa                	mv	s1,a0
  {
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    800035b2:	12000613          	li	a2,288
    800035b6:	6d28                	ld	a0,88(a0)
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	772080e7          	jalr	1906(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    800035c0:	2084b503          	ld	a0,520(s1)
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	420080e7          	jalr	1056(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    800035cc:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1; // Re-enable the alarm
    800035d0:	4785                	li	a5,1
    800035d2:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret(); // function that returns the command back to the user space
    800035d6:	fffff097          	auipc	ra,0xfffff
    800035da:	6ea080e7          	jalr	1770(ra) # 80002cc0 <usertrapret>
  return 0;
}
    800035de:	4501                	li	a0,0
    800035e0:	60e2                	ld	ra,24(sp)
    800035e2:	6442                	ld	s0,16(sp)
    800035e4:	64a2                	ld	s1,8(sp)
    800035e6:	6105                	add	sp,sp,32
    800035e8:	8082                	ret

00000000800035ea <sys_settickets>:

// settickets system call
uint64 sys_settickets(void)
{
    800035ea:	1101                	add	sp,sp,-32
    800035ec:	ec06                	sd	ra,24(sp)
    800035ee:	e822                	sd	s0,16(sp)
    800035f0:	1000                	add	s0,sp,32
  int n;

  // Get the number of tickets from the user
  argint(0, &n);
    800035f2:	fec40593          	add	a1,s0,-20
    800035f6:	4501                	li	a0,0
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	b8c080e7          	jalr	-1140(ra) # 80003184 <argint>
  // Ensure the ticket number is valid (greater than 0)
  if (n < 1)
    80003600:	fec42783          	lw	a5,-20(s0)
    80003604:	00f05f63          	blez	a5,80003622 <sys_settickets+0x38>
    printf("entered ticket is invalid error");
    return -1; // Error: invalid ticket count
  }

  // Set the calling process's ticket count
  myproc()->tickets = n;
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	39e080e7          	jalr	926(ra) # 800019a6 <myproc>
    80003610:	fec42783          	lw	a5,-20(s0)
    80003614:	20f52823          	sw	a5,528(a0)

  return 0; // Success
    80003618:	4501                	li	a0,0
}
    8000361a:	60e2                	ld	ra,24(sp)
    8000361c:	6442                	ld	s0,16(sp)
    8000361e:	6105                	add	sp,sp,32
    80003620:	8082                	ret
    printf("entered ticket is invalid error");
    80003622:	00005517          	auipc	a0,0x5
    80003626:	f3e50513          	add	a0,a0,-194 # 80008560 <syscalls+0xd8>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f5c080e7          	jalr	-164(ra) # 80000586 <printf>
    return -1; // Error: invalid ticket count
    80003632:	557d                	li	a0,-1
    80003634:	b7dd                	j	8000361a <sys_settickets+0x30>

0000000080003636 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003636:	7179                	add	sp,sp,-48
    80003638:	f406                	sd	ra,40(sp)
    8000363a:	f022                	sd	s0,32(sp)
    8000363c:	ec26                	sd	s1,24(sp)
    8000363e:	e84a                	sd	s2,16(sp)
    80003640:	e44e                	sd	s3,8(sp)
    80003642:	e052                	sd	s4,0(sp)
    80003644:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003646:	00005597          	auipc	a1,0x5
    8000364a:	f3a58593          	add	a1,a1,-198 # 80008580 <syscalls+0xf8>
    8000364e:	00017517          	auipc	a0,0x17
    80003652:	17a50513          	add	a0,a0,378 # 8001a7c8 <bcache>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	4ec080e7          	jalr	1260(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000365e:	0001f797          	auipc	a5,0x1f
    80003662:	16a78793          	add	a5,a5,362 # 800227c8 <bcache+0x8000>
    80003666:	0001f717          	auipc	a4,0x1f
    8000366a:	3ca70713          	add	a4,a4,970 # 80022a30 <bcache+0x8268>
    8000366e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003672:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003676:	00017497          	auipc	s1,0x17
    8000367a:	16a48493          	add	s1,s1,362 # 8001a7e0 <bcache+0x18>
    b->next = bcache.head.next;
    8000367e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003680:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003682:	00005a17          	auipc	s4,0x5
    80003686:	f06a0a13          	add	s4,s4,-250 # 80008588 <syscalls+0x100>
    b->next = bcache.head.next;
    8000368a:	2b893783          	ld	a5,696(s2)
    8000368e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003690:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003694:	85d2                	mv	a1,s4
    80003696:	01048513          	add	a0,s1,16
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	496080e7          	jalr	1174(ra) # 80004b30 <initsleeplock>
    bcache.head.next->prev = b;
    800036a2:	2b893783          	ld	a5,696(s2)
    800036a6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036a8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036ac:	45848493          	add	s1,s1,1112
    800036b0:	fd349de3          	bne	s1,s3,8000368a <binit+0x54>
  }
}
    800036b4:	70a2                	ld	ra,40(sp)
    800036b6:	7402                	ld	s0,32(sp)
    800036b8:	64e2                	ld	s1,24(sp)
    800036ba:	6942                	ld	s2,16(sp)
    800036bc:	69a2                	ld	s3,8(sp)
    800036be:	6a02                	ld	s4,0(sp)
    800036c0:	6145                	add	sp,sp,48
    800036c2:	8082                	ret

00000000800036c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036c4:	7179                	add	sp,sp,-48
    800036c6:	f406                	sd	ra,40(sp)
    800036c8:	f022                	sd	s0,32(sp)
    800036ca:	ec26                	sd	s1,24(sp)
    800036cc:	e84a                	sd	s2,16(sp)
    800036ce:	e44e                	sd	s3,8(sp)
    800036d0:	1800                	add	s0,sp,48
    800036d2:	892a                	mv	s2,a0
    800036d4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036d6:	00017517          	auipc	a0,0x17
    800036da:	0f250513          	add	a0,a0,242 # 8001a7c8 <bcache>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	4f4080e7          	jalr	1268(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036e6:	0001f497          	auipc	s1,0x1f
    800036ea:	39a4b483          	ld	s1,922(s1) # 80022a80 <bcache+0x82b8>
    800036ee:	0001f797          	auipc	a5,0x1f
    800036f2:	34278793          	add	a5,a5,834 # 80022a30 <bcache+0x8268>
    800036f6:	02f48f63          	beq	s1,a5,80003734 <bread+0x70>
    800036fa:	873e                	mv	a4,a5
    800036fc:	a021                	j	80003704 <bread+0x40>
    800036fe:	68a4                	ld	s1,80(s1)
    80003700:	02e48a63          	beq	s1,a4,80003734 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003704:	449c                	lw	a5,8(s1)
    80003706:	ff279ce3          	bne	a5,s2,800036fe <bread+0x3a>
    8000370a:	44dc                	lw	a5,12(s1)
    8000370c:	ff3799e3          	bne	a5,s3,800036fe <bread+0x3a>
      b->refcnt++;
    80003710:	40bc                	lw	a5,64(s1)
    80003712:	2785                	addw	a5,a5,1
    80003714:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003716:	00017517          	auipc	a0,0x17
    8000371a:	0b250513          	add	a0,a0,178 # 8001a7c8 <bcache>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	568080e7          	jalr	1384(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003726:	01048513          	add	a0,s1,16
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	440080e7          	jalr	1088(ra) # 80004b6a <acquiresleep>
      return b;
    80003732:	a8b9                	j	80003790 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003734:	0001f497          	auipc	s1,0x1f
    80003738:	3444b483          	ld	s1,836(s1) # 80022a78 <bcache+0x82b0>
    8000373c:	0001f797          	auipc	a5,0x1f
    80003740:	2f478793          	add	a5,a5,756 # 80022a30 <bcache+0x8268>
    80003744:	00f48863          	beq	s1,a5,80003754 <bread+0x90>
    80003748:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000374a:	40bc                	lw	a5,64(s1)
    8000374c:	cf81                	beqz	a5,80003764 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000374e:	64a4                	ld	s1,72(s1)
    80003750:	fee49de3          	bne	s1,a4,8000374a <bread+0x86>
  panic("bget: no buffers");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	e3c50513          	add	a0,a0,-452 # 80008590 <syscalls+0x108>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	de0080e7          	jalr	-544(ra) # 8000053c <panic>
      b->dev = dev;
    80003764:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003768:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000376c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003770:	4785                	li	a5,1
    80003772:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003774:	00017517          	auipc	a0,0x17
    80003778:	05450513          	add	a0,a0,84 # 8001a7c8 <bcache>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	50a080e7          	jalr	1290(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003784:	01048513          	add	a0,s1,16
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	3e2080e7          	jalr	994(ra) # 80004b6a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003790:	409c                	lw	a5,0(s1)
    80003792:	cb89                	beqz	a5,800037a4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003794:	8526                	mv	a0,s1
    80003796:	70a2                	ld	ra,40(sp)
    80003798:	7402                	ld	s0,32(sp)
    8000379a:	64e2                	ld	s1,24(sp)
    8000379c:	6942                	ld	s2,16(sp)
    8000379e:	69a2                	ld	s3,8(sp)
    800037a0:	6145                	add	sp,sp,48
    800037a2:	8082                	ret
    virtio_disk_rw(b, 0);
    800037a4:	4581                	li	a1,0
    800037a6:	8526                	mv	a0,s1
    800037a8:	00003097          	auipc	ra,0x3
    800037ac:	f7a080e7          	jalr	-134(ra) # 80006722 <virtio_disk_rw>
    b->valid = 1;
    800037b0:	4785                	li	a5,1
    800037b2:	c09c                	sw	a5,0(s1)
  return b;
    800037b4:	b7c5                	j	80003794 <bread+0xd0>

00000000800037b6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037b6:	1101                	add	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	1000                	add	s0,sp,32
    800037c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037c2:	0541                	add	a0,a0,16
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	440080e7          	jalr	1088(ra) # 80004c04 <holdingsleep>
    800037cc:	cd01                	beqz	a0,800037e4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037ce:	4585                	li	a1,1
    800037d0:	8526                	mv	a0,s1
    800037d2:	00003097          	auipc	ra,0x3
    800037d6:	f50080e7          	jalr	-176(ra) # 80006722 <virtio_disk_rw>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6105                	add	sp,sp,32
    800037e2:	8082                	ret
    panic("bwrite");
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	dc450513          	add	a0,a0,-572 # 800085a8 <syscalls+0x120>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	d50080e7          	jalr	-688(ra) # 8000053c <panic>

00000000800037f4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037f4:	1101                	add	sp,sp,-32
    800037f6:	ec06                	sd	ra,24(sp)
    800037f8:	e822                	sd	s0,16(sp)
    800037fa:	e426                	sd	s1,8(sp)
    800037fc:	e04a                	sd	s2,0(sp)
    800037fe:	1000                	add	s0,sp,32
    80003800:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003802:	01050913          	add	s2,a0,16
    80003806:	854a                	mv	a0,s2
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	3fc080e7          	jalr	1020(ra) # 80004c04 <holdingsleep>
    80003810:	c925                	beqz	a0,80003880 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003812:	854a                	mv	a0,s2
    80003814:	00001097          	auipc	ra,0x1
    80003818:	3ac080e7          	jalr	940(ra) # 80004bc0 <releasesleep>

  acquire(&bcache.lock);
    8000381c:	00017517          	auipc	a0,0x17
    80003820:	fac50513          	add	a0,a0,-84 # 8001a7c8 <bcache>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	3ae080e7          	jalr	942(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000382c:	40bc                	lw	a5,64(s1)
    8000382e:	37fd                	addw	a5,a5,-1
    80003830:	0007871b          	sext.w	a4,a5
    80003834:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003836:	e71d                	bnez	a4,80003864 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003838:	68b8                	ld	a4,80(s1)
    8000383a:	64bc                	ld	a5,72(s1)
    8000383c:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000383e:	68b8                	ld	a4,80(s1)
    80003840:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003842:	0001f797          	auipc	a5,0x1f
    80003846:	f8678793          	add	a5,a5,-122 # 800227c8 <bcache+0x8000>
    8000384a:	2b87b703          	ld	a4,696(a5)
    8000384e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003850:	0001f717          	auipc	a4,0x1f
    80003854:	1e070713          	add	a4,a4,480 # 80022a30 <bcache+0x8268>
    80003858:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000385a:	2b87b703          	ld	a4,696(a5)
    8000385e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003860:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003864:	00017517          	auipc	a0,0x17
    80003868:	f6450513          	add	a0,a0,-156 # 8001a7c8 <bcache>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	41a080e7          	jalr	1050(ra) # 80000c86 <release>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6902                	ld	s2,0(sp)
    8000387c:	6105                	add	sp,sp,32
    8000387e:	8082                	ret
    panic("brelse");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	d3050513          	add	a0,a0,-720 # 800085b0 <syscalls+0x128>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cb4080e7          	jalr	-844(ra) # 8000053c <panic>

0000000080003890 <bpin>:

void
bpin(struct buf *b) {
    80003890:	1101                	add	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	1000                	add	s0,sp,32
    8000389a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000389c:	00017517          	auipc	a0,0x17
    800038a0:	f2c50513          	add	a0,a0,-212 # 8001a7c8 <bcache>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	32e080e7          	jalr	814(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800038ac:	40bc                	lw	a5,64(s1)
    800038ae:	2785                	addw	a5,a5,1
    800038b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038b2:	00017517          	auipc	a0,0x17
    800038b6:	f1650513          	add	a0,a0,-234 # 8001a7c8 <bcache>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	3cc080e7          	jalr	972(ra) # 80000c86 <release>
}
    800038c2:	60e2                	ld	ra,24(sp)
    800038c4:	6442                	ld	s0,16(sp)
    800038c6:	64a2                	ld	s1,8(sp)
    800038c8:	6105                	add	sp,sp,32
    800038ca:	8082                	ret

00000000800038cc <bunpin>:

void
bunpin(struct buf *b) {
    800038cc:	1101                	add	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	e426                	sd	s1,8(sp)
    800038d4:	1000                	add	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d8:	00017517          	auipc	a0,0x17
    800038dc:	ef050513          	add	a0,a0,-272 # 8001a7c8 <bcache>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	2f2080e7          	jalr	754(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800038e8:	40bc                	lw	a5,64(s1)
    800038ea:	37fd                	addw	a5,a5,-1
    800038ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ee:	00017517          	auipc	a0,0x17
    800038f2:	eda50513          	add	a0,a0,-294 # 8001a7c8 <bcache>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	390080e7          	jalr	912(ra) # 80000c86 <release>
}
    800038fe:	60e2                	ld	ra,24(sp)
    80003900:	6442                	ld	s0,16(sp)
    80003902:	64a2                	ld	s1,8(sp)
    80003904:	6105                	add	sp,sp,32
    80003906:	8082                	ret

0000000080003908 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003908:	1101                	add	sp,sp,-32
    8000390a:	ec06                	sd	ra,24(sp)
    8000390c:	e822                	sd	s0,16(sp)
    8000390e:	e426                	sd	s1,8(sp)
    80003910:	e04a                	sd	s2,0(sp)
    80003912:	1000                	add	s0,sp,32
    80003914:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003916:	00d5d59b          	srlw	a1,a1,0xd
    8000391a:	0001f797          	auipc	a5,0x1f
    8000391e:	58a7a783          	lw	a5,1418(a5) # 80022ea4 <sb+0x1c>
    80003922:	9dbd                	addw	a1,a1,a5
    80003924:	00000097          	auipc	ra,0x0
    80003928:	da0080e7          	jalr	-608(ra) # 800036c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000392c:	0074f713          	and	a4,s1,7
    80003930:	4785                	li	a5,1
    80003932:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003936:	14ce                	sll	s1,s1,0x33
    80003938:	90d9                	srl	s1,s1,0x36
    8000393a:	00950733          	add	a4,a0,s1
    8000393e:	05874703          	lbu	a4,88(a4)
    80003942:	00e7f6b3          	and	a3,a5,a4
    80003946:	c69d                	beqz	a3,80003974 <bfree+0x6c>
    80003948:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000394a:	94aa                	add	s1,s1,a0
    8000394c:	fff7c793          	not	a5,a5
    80003950:	8f7d                	and	a4,a4,a5
    80003952:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003956:	00001097          	auipc	ra,0x1
    8000395a:	0f6080e7          	jalr	246(ra) # 80004a4c <log_write>
  brelse(bp);
    8000395e:	854a                	mv	a0,s2
    80003960:	00000097          	auipc	ra,0x0
    80003964:	e94080e7          	jalr	-364(ra) # 800037f4 <brelse>
}
    80003968:	60e2                	ld	ra,24(sp)
    8000396a:	6442                	ld	s0,16(sp)
    8000396c:	64a2                	ld	s1,8(sp)
    8000396e:	6902                	ld	s2,0(sp)
    80003970:	6105                	add	sp,sp,32
    80003972:	8082                	ret
    panic("freeing free block");
    80003974:	00005517          	auipc	a0,0x5
    80003978:	c4450513          	add	a0,a0,-956 # 800085b8 <syscalls+0x130>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	bc0080e7          	jalr	-1088(ra) # 8000053c <panic>

0000000080003984 <balloc>:
{
    80003984:	711d                	add	sp,sp,-96
    80003986:	ec86                	sd	ra,88(sp)
    80003988:	e8a2                	sd	s0,80(sp)
    8000398a:	e4a6                	sd	s1,72(sp)
    8000398c:	e0ca                	sd	s2,64(sp)
    8000398e:	fc4e                	sd	s3,56(sp)
    80003990:	f852                	sd	s4,48(sp)
    80003992:	f456                	sd	s5,40(sp)
    80003994:	f05a                	sd	s6,32(sp)
    80003996:	ec5e                	sd	s7,24(sp)
    80003998:	e862                	sd	s8,16(sp)
    8000399a:	e466                	sd	s9,8(sp)
    8000399c:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000399e:	0001f797          	auipc	a5,0x1f
    800039a2:	4ee7a783          	lw	a5,1262(a5) # 80022e8c <sb+0x4>
    800039a6:	cff5                	beqz	a5,80003aa2 <balloc+0x11e>
    800039a8:	8baa                	mv	s7,a0
    800039aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039ac:	0001fb17          	auipc	s6,0x1f
    800039b0:	4dcb0b13          	add	s6,s6,1244 # 80022e88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039ba:	6c89                	lui	s9,0x2
    800039bc:	a061                	j	80003a44 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039be:	97ca                	add	a5,a5,s2
    800039c0:	8e55                	or	a2,a2,a3
    800039c2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	084080e7          	jalr	132(ra) # 80004a4c <log_write>
        brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	e22080e7          	jalr	-478(ra) # 800037f4 <brelse>
  bp = bread(dev, bno);
    800039da:	85a6                	mv	a1,s1
    800039dc:	855e                	mv	a0,s7
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	ce6080e7          	jalr	-794(ra) # 800036c4 <bread>
    800039e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e8:	40000613          	li	a2,1024
    800039ec:	4581                	li	a1,0
    800039ee:	05850513          	add	a0,a0,88
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	2dc080e7          	jalr	732(ra) # 80000cce <memset>
  log_write(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	050080e7          	jalr	80(ra) # 80004a4c <log_write>
  brelse(bp);
    80003a04:	854a                	mv	a0,s2
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	dee080e7          	jalr	-530(ra) # 800037f4 <brelse>
}
    80003a0e:	8526                	mv	a0,s1
    80003a10:	60e6                	ld	ra,88(sp)
    80003a12:	6446                	ld	s0,80(sp)
    80003a14:	64a6                	ld	s1,72(sp)
    80003a16:	6906                	ld	s2,64(sp)
    80003a18:	79e2                	ld	s3,56(sp)
    80003a1a:	7a42                	ld	s4,48(sp)
    80003a1c:	7aa2                	ld	s5,40(sp)
    80003a1e:	7b02                	ld	s6,32(sp)
    80003a20:	6be2                	ld	s7,24(sp)
    80003a22:	6c42                	ld	s8,16(sp)
    80003a24:	6ca2                	ld	s9,8(sp)
    80003a26:	6125                	add	sp,sp,96
    80003a28:	8082                	ret
    brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	dc8080e7          	jalr	-568(ra) # 800037f4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a34:	015c87bb          	addw	a5,s9,s5
    80003a38:	00078a9b          	sext.w	s5,a5
    80003a3c:	004b2703          	lw	a4,4(s6)
    80003a40:	06eaf163          	bgeu	s5,a4,80003aa2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003a44:	41fad79b          	sraw	a5,s5,0x1f
    80003a48:	0137d79b          	srlw	a5,a5,0x13
    80003a4c:	015787bb          	addw	a5,a5,s5
    80003a50:	40d7d79b          	sraw	a5,a5,0xd
    80003a54:	01cb2583          	lw	a1,28(s6)
    80003a58:	9dbd                	addw	a1,a1,a5
    80003a5a:	855e                	mv	a0,s7
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	c68080e7          	jalr	-920(ra) # 800036c4 <bread>
    80003a64:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a66:	004b2503          	lw	a0,4(s6)
    80003a6a:	000a849b          	sext.w	s1,s5
    80003a6e:	8762                	mv	a4,s8
    80003a70:	faa4fde3          	bgeu	s1,a0,80003a2a <balloc+0xa6>
      m = 1 << (bi % 8);
    80003a74:	00777693          	and	a3,a4,7
    80003a78:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a7c:	41f7579b          	sraw	a5,a4,0x1f
    80003a80:	01d7d79b          	srlw	a5,a5,0x1d
    80003a84:	9fb9                	addw	a5,a5,a4
    80003a86:	4037d79b          	sraw	a5,a5,0x3
    80003a8a:	00f90633          	add	a2,s2,a5
    80003a8e:	05864603          	lbu	a2,88(a2)
    80003a92:	00c6f5b3          	and	a1,a3,a2
    80003a96:	d585                	beqz	a1,800039be <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a98:	2705                	addw	a4,a4,1
    80003a9a:	2485                	addw	s1,s1,1
    80003a9c:	fd471ae3          	bne	a4,s4,80003a70 <balloc+0xec>
    80003aa0:	b769                	j	80003a2a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	b2e50513          	add	a0,a0,-1234 # 800085d0 <syscalls+0x148>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	adc080e7          	jalr	-1316(ra) # 80000586 <printf>
  return 0;
    80003ab2:	4481                	li	s1,0
    80003ab4:	bfa9                	j	80003a0e <balloc+0x8a>

0000000080003ab6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ab6:	7179                	add	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	e052                	sd	s4,0(sp)
    80003ac4:	1800                	add	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ac8:	47ad                	li	a5,11
    80003aca:	02b7e863          	bltu	a5,a1,80003afa <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003ace:	02059793          	sll	a5,a1,0x20
    80003ad2:	01e7d593          	srl	a1,a5,0x1e
    80003ad6:	00b504b3          	add	s1,a0,a1
    80003ada:	0504a903          	lw	s2,80(s1)
    80003ade:	06091e63          	bnez	s2,80003b5a <bmap+0xa4>
      addr = balloc(ip->dev);
    80003ae2:	4108                	lw	a0,0(a0)
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	ea0080e7          	jalr	-352(ra) # 80003984 <balloc>
    80003aec:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003af0:	06090563          	beqz	s2,80003b5a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003af4:	0524a823          	sw	s2,80(s1)
    80003af8:	a08d                	j	80003b5a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003afa:	ff45849b          	addw	s1,a1,-12
    80003afe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b02:	0ff00793          	li	a5,255
    80003b06:	08e7e563          	bltu	a5,a4,80003b90 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b0a:	08052903          	lw	s2,128(a0)
    80003b0e:	00091d63          	bnez	s2,80003b28 <bmap+0x72>
      addr = balloc(ip->dev);
    80003b12:	4108                	lw	a0,0(a0)
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	e70080e7          	jalr	-400(ra) # 80003984 <balloc>
    80003b1c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b20:	02090d63          	beqz	s2,80003b5a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b24:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b28:	85ca                	mv	a1,s2
    80003b2a:	0009a503          	lw	a0,0(s3)
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	b96080e7          	jalr	-1130(ra) # 800036c4 <bread>
    80003b36:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b38:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b3c:	02049713          	sll	a4,s1,0x20
    80003b40:	01e75593          	srl	a1,a4,0x1e
    80003b44:	00b784b3          	add	s1,a5,a1
    80003b48:	0004a903          	lw	s2,0(s1)
    80003b4c:	02090063          	beqz	s2,80003b6c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b50:	8552                	mv	a0,s4
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	ca2080e7          	jalr	-862(ra) # 800037f4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	70a2                	ld	ra,40(sp)
    80003b5e:	7402                	ld	s0,32(sp)
    80003b60:	64e2                	ld	s1,24(sp)
    80003b62:	6942                	ld	s2,16(sp)
    80003b64:	69a2                	ld	s3,8(sp)
    80003b66:	6a02                	ld	s4,0(sp)
    80003b68:	6145                	add	sp,sp,48
    80003b6a:	8082                	ret
      addr = balloc(ip->dev);
    80003b6c:	0009a503          	lw	a0,0(s3)
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	e14080e7          	jalr	-492(ra) # 80003984 <balloc>
    80003b78:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b7c:	fc090ae3          	beqz	s2,80003b50 <bmap+0x9a>
        a[bn] = addr;
    80003b80:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b84:	8552                	mv	a0,s4
    80003b86:	00001097          	auipc	ra,0x1
    80003b8a:	ec6080e7          	jalr	-314(ra) # 80004a4c <log_write>
    80003b8e:	b7c9                	j	80003b50 <bmap+0x9a>
  panic("bmap: out of range");
    80003b90:	00005517          	auipc	a0,0x5
    80003b94:	a5850513          	add	a0,a0,-1448 # 800085e8 <syscalls+0x160>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	9a4080e7          	jalr	-1628(ra) # 8000053c <panic>

0000000080003ba0 <iget>:
{
    80003ba0:	7179                	add	sp,sp,-48
    80003ba2:	f406                	sd	ra,40(sp)
    80003ba4:	f022                	sd	s0,32(sp)
    80003ba6:	ec26                	sd	s1,24(sp)
    80003ba8:	e84a                	sd	s2,16(sp)
    80003baa:	e44e                	sd	s3,8(sp)
    80003bac:	e052                	sd	s4,0(sp)
    80003bae:	1800                	add	s0,sp,48
    80003bb0:	89aa                	mv	s3,a0
    80003bb2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bb4:	0001f517          	auipc	a0,0x1f
    80003bb8:	2f450513          	add	a0,a0,756 # 80022ea8 <itable>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	016080e7          	jalr	22(ra) # 80000bd2 <acquire>
  empty = 0;
    80003bc4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bc6:	0001f497          	auipc	s1,0x1f
    80003bca:	2fa48493          	add	s1,s1,762 # 80022ec0 <itable+0x18>
    80003bce:	00021697          	auipc	a3,0x21
    80003bd2:	d8268693          	add	a3,a3,-638 # 80024950 <log>
    80003bd6:	a039                	j	80003be4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bd8:	02090b63          	beqz	s2,80003c0e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bdc:	08848493          	add	s1,s1,136
    80003be0:	02d48a63          	beq	s1,a3,80003c14 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003be4:	449c                	lw	a5,8(s1)
    80003be6:	fef059e3          	blez	a5,80003bd8 <iget+0x38>
    80003bea:	4098                	lw	a4,0(s1)
    80003bec:	ff3716e3          	bne	a4,s3,80003bd8 <iget+0x38>
    80003bf0:	40d8                	lw	a4,4(s1)
    80003bf2:	ff4713e3          	bne	a4,s4,80003bd8 <iget+0x38>
      ip->ref++;
    80003bf6:	2785                	addw	a5,a5,1
    80003bf8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bfa:	0001f517          	auipc	a0,0x1f
    80003bfe:	2ae50513          	add	a0,a0,686 # 80022ea8 <itable>
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	084080e7          	jalr	132(ra) # 80000c86 <release>
      return ip;
    80003c0a:	8926                	mv	s2,s1
    80003c0c:	a03d                	j	80003c3a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c0e:	f7f9                	bnez	a5,80003bdc <iget+0x3c>
    80003c10:	8926                	mv	s2,s1
    80003c12:	b7e9                	j	80003bdc <iget+0x3c>
  if(empty == 0)
    80003c14:	02090c63          	beqz	s2,80003c4c <iget+0xac>
  ip->dev = dev;
    80003c18:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c1c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c20:	4785                	li	a5,1
    80003c22:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c26:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c2a:	0001f517          	auipc	a0,0x1f
    80003c2e:	27e50513          	add	a0,a0,638 # 80022ea8 <itable>
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	054080e7          	jalr	84(ra) # 80000c86 <release>
}
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	70a2                	ld	ra,40(sp)
    80003c3e:	7402                	ld	s0,32(sp)
    80003c40:	64e2                	ld	s1,24(sp)
    80003c42:	6942                	ld	s2,16(sp)
    80003c44:	69a2                	ld	s3,8(sp)
    80003c46:	6a02                	ld	s4,0(sp)
    80003c48:	6145                	add	sp,sp,48
    80003c4a:	8082                	ret
    panic("iget: no inodes");
    80003c4c:	00005517          	auipc	a0,0x5
    80003c50:	9b450513          	add	a0,a0,-1612 # 80008600 <syscalls+0x178>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	8e8080e7          	jalr	-1816(ra) # 8000053c <panic>

0000000080003c5c <fsinit>:
fsinit(int dev) {
    80003c5c:	7179                	add	sp,sp,-48
    80003c5e:	f406                	sd	ra,40(sp)
    80003c60:	f022                	sd	s0,32(sp)
    80003c62:	ec26                	sd	s1,24(sp)
    80003c64:	e84a                	sd	s2,16(sp)
    80003c66:	e44e                	sd	s3,8(sp)
    80003c68:	1800                	add	s0,sp,48
    80003c6a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c6c:	4585                	li	a1,1
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	a56080e7          	jalr	-1450(ra) # 800036c4 <bread>
    80003c76:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c78:	0001f997          	auipc	s3,0x1f
    80003c7c:	21098993          	add	s3,s3,528 # 80022e88 <sb>
    80003c80:	02000613          	li	a2,32
    80003c84:	05850593          	add	a1,a0,88
    80003c88:	854e                	mv	a0,s3
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	0a0080e7          	jalr	160(ra) # 80000d2a <memmove>
  brelse(bp);
    80003c92:	8526                	mv	a0,s1
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	b60080e7          	jalr	-1184(ra) # 800037f4 <brelse>
  if(sb.magic != FSMAGIC)
    80003c9c:	0009a703          	lw	a4,0(s3)
    80003ca0:	102037b7          	lui	a5,0x10203
    80003ca4:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ca8:	02f71263          	bne	a4,a5,80003ccc <fsinit+0x70>
  initlog(dev, &sb);
    80003cac:	0001f597          	auipc	a1,0x1f
    80003cb0:	1dc58593          	add	a1,a1,476 # 80022e88 <sb>
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00001097          	auipc	ra,0x1
    80003cba:	b2c080e7          	jalr	-1236(ra) # 800047e2 <initlog>
}
    80003cbe:	70a2                	ld	ra,40(sp)
    80003cc0:	7402                	ld	s0,32(sp)
    80003cc2:	64e2                	ld	s1,24(sp)
    80003cc4:	6942                	ld	s2,16(sp)
    80003cc6:	69a2                	ld	s3,8(sp)
    80003cc8:	6145                	add	sp,sp,48
    80003cca:	8082                	ret
    panic("invalid file system");
    80003ccc:	00005517          	auipc	a0,0x5
    80003cd0:	94450513          	add	a0,a0,-1724 # 80008610 <syscalls+0x188>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	868080e7          	jalr	-1944(ra) # 8000053c <panic>

0000000080003cdc <iinit>:
{
    80003cdc:	7179                	add	sp,sp,-48
    80003cde:	f406                	sd	ra,40(sp)
    80003ce0:	f022                	sd	s0,32(sp)
    80003ce2:	ec26                	sd	s1,24(sp)
    80003ce4:	e84a                	sd	s2,16(sp)
    80003ce6:	e44e                	sd	s3,8(sp)
    80003ce8:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cea:	00005597          	auipc	a1,0x5
    80003cee:	93e58593          	add	a1,a1,-1730 # 80008628 <syscalls+0x1a0>
    80003cf2:	0001f517          	auipc	a0,0x1f
    80003cf6:	1b650513          	add	a0,a0,438 # 80022ea8 <itable>
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	e48080e7          	jalr	-440(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d02:	0001f497          	auipc	s1,0x1f
    80003d06:	1ce48493          	add	s1,s1,462 # 80022ed0 <itable+0x28>
    80003d0a:	00021997          	auipc	s3,0x21
    80003d0e:	c5698993          	add	s3,s3,-938 # 80024960 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d12:	00005917          	auipc	s2,0x5
    80003d16:	91e90913          	add	s2,s2,-1762 # 80008630 <syscalls+0x1a8>
    80003d1a:	85ca                	mv	a1,s2
    80003d1c:	8526                	mv	a0,s1
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	e12080e7          	jalr	-494(ra) # 80004b30 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d26:	08848493          	add	s1,s1,136
    80003d2a:	ff3498e3          	bne	s1,s3,80003d1a <iinit+0x3e>
}
    80003d2e:	70a2                	ld	ra,40(sp)
    80003d30:	7402                	ld	s0,32(sp)
    80003d32:	64e2                	ld	s1,24(sp)
    80003d34:	6942                	ld	s2,16(sp)
    80003d36:	69a2                	ld	s3,8(sp)
    80003d38:	6145                	add	sp,sp,48
    80003d3a:	8082                	ret

0000000080003d3c <ialloc>:
{
    80003d3c:	7139                	add	sp,sp,-64
    80003d3e:	fc06                	sd	ra,56(sp)
    80003d40:	f822                	sd	s0,48(sp)
    80003d42:	f426                	sd	s1,40(sp)
    80003d44:	f04a                	sd	s2,32(sp)
    80003d46:	ec4e                	sd	s3,24(sp)
    80003d48:	e852                	sd	s4,16(sp)
    80003d4a:	e456                	sd	s5,8(sp)
    80003d4c:	e05a                	sd	s6,0(sp)
    80003d4e:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d50:	0001f717          	auipc	a4,0x1f
    80003d54:	14472703          	lw	a4,324(a4) # 80022e94 <sb+0xc>
    80003d58:	4785                	li	a5,1
    80003d5a:	04e7f863          	bgeu	a5,a4,80003daa <ialloc+0x6e>
    80003d5e:	8aaa                	mv	s5,a0
    80003d60:	8b2e                	mv	s6,a1
    80003d62:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d64:	0001fa17          	auipc	s4,0x1f
    80003d68:	124a0a13          	add	s4,s4,292 # 80022e88 <sb>
    80003d6c:	00495593          	srl	a1,s2,0x4
    80003d70:	018a2783          	lw	a5,24(s4)
    80003d74:	9dbd                	addw	a1,a1,a5
    80003d76:	8556                	mv	a0,s5
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	94c080e7          	jalr	-1716(ra) # 800036c4 <bread>
    80003d80:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d82:	05850993          	add	s3,a0,88
    80003d86:	00f97793          	and	a5,s2,15
    80003d8a:	079a                	sll	a5,a5,0x6
    80003d8c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d8e:	00099783          	lh	a5,0(s3)
    80003d92:	cf9d                	beqz	a5,80003dd0 <ialloc+0x94>
    brelse(bp);
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	a60080e7          	jalr	-1440(ra) # 800037f4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d9c:	0905                	add	s2,s2,1
    80003d9e:	00ca2703          	lw	a4,12(s4)
    80003da2:	0009079b          	sext.w	a5,s2
    80003da6:	fce7e3e3          	bltu	a5,a4,80003d6c <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003daa:	00005517          	auipc	a0,0x5
    80003dae:	88e50513          	add	a0,a0,-1906 # 80008638 <syscalls+0x1b0>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	7d4080e7          	jalr	2004(ra) # 80000586 <printf>
  return 0;
    80003dba:	4501                	li	a0,0
}
    80003dbc:	70e2                	ld	ra,56(sp)
    80003dbe:	7442                	ld	s0,48(sp)
    80003dc0:	74a2                	ld	s1,40(sp)
    80003dc2:	7902                	ld	s2,32(sp)
    80003dc4:	69e2                	ld	s3,24(sp)
    80003dc6:	6a42                	ld	s4,16(sp)
    80003dc8:	6aa2                	ld	s5,8(sp)
    80003dca:	6b02                	ld	s6,0(sp)
    80003dcc:	6121                	add	sp,sp,64
    80003dce:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003dd0:	04000613          	li	a2,64
    80003dd4:	4581                	li	a1,0
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	ef6080e7          	jalr	-266(ra) # 80000cce <memset>
      dip->type = type;
    80003de0:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003de4:	8526                	mv	a0,s1
    80003de6:	00001097          	auipc	ra,0x1
    80003dea:	c66080e7          	jalr	-922(ra) # 80004a4c <log_write>
      brelse(bp);
    80003dee:	8526                	mv	a0,s1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	a04080e7          	jalr	-1532(ra) # 800037f4 <brelse>
      return iget(dev, inum);
    80003df8:	0009059b          	sext.w	a1,s2
    80003dfc:	8556                	mv	a0,s5
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	da2080e7          	jalr	-606(ra) # 80003ba0 <iget>
    80003e06:	bf5d                	j	80003dbc <ialloc+0x80>

0000000080003e08 <iupdate>:
{
    80003e08:	1101                	add	sp,sp,-32
    80003e0a:	ec06                	sd	ra,24(sp)
    80003e0c:	e822                	sd	s0,16(sp)
    80003e0e:	e426                	sd	s1,8(sp)
    80003e10:	e04a                	sd	s2,0(sp)
    80003e12:	1000                	add	s0,sp,32
    80003e14:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e16:	415c                	lw	a5,4(a0)
    80003e18:	0047d79b          	srlw	a5,a5,0x4
    80003e1c:	0001f597          	auipc	a1,0x1f
    80003e20:	0845a583          	lw	a1,132(a1) # 80022ea0 <sb+0x18>
    80003e24:	9dbd                	addw	a1,a1,a5
    80003e26:	4108                	lw	a0,0(a0)
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	89c080e7          	jalr	-1892(ra) # 800036c4 <bread>
    80003e30:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e32:	05850793          	add	a5,a0,88
    80003e36:	40d8                	lw	a4,4(s1)
    80003e38:	8b3d                	and	a4,a4,15
    80003e3a:	071a                	sll	a4,a4,0x6
    80003e3c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003e3e:	04449703          	lh	a4,68(s1)
    80003e42:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003e46:	04649703          	lh	a4,70(s1)
    80003e4a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003e4e:	04849703          	lh	a4,72(s1)
    80003e52:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003e56:	04a49703          	lh	a4,74(s1)
    80003e5a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003e5e:	44f8                	lw	a4,76(s1)
    80003e60:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e62:	03400613          	li	a2,52
    80003e66:	05048593          	add	a1,s1,80
    80003e6a:	00c78513          	add	a0,a5,12
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	ebc080e7          	jalr	-324(ra) # 80000d2a <memmove>
  log_write(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	00001097          	auipc	ra,0x1
    80003e7c:	bd4080e7          	jalr	-1068(ra) # 80004a4c <log_write>
  brelse(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	972080e7          	jalr	-1678(ra) # 800037f4 <brelse>
}
    80003e8a:	60e2                	ld	ra,24(sp)
    80003e8c:	6442                	ld	s0,16(sp)
    80003e8e:	64a2                	ld	s1,8(sp)
    80003e90:	6902                	ld	s2,0(sp)
    80003e92:	6105                	add	sp,sp,32
    80003e94:	8082                	ret

0000000080003e96 <idup>:
{
    80003e96:	1101                	add	sp,sp,-32
    80003e98:	ec06                	sd	ra,24(sp)
    80003e9a:	e822                	sd	s0,16(sp)
    80003e9c:	e426                	sd	s1,8(sp)
    80003e9e:	1000                	add	s0,sp,32
    80003ea0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ea2:	0001f517          	auipc	a0,0x1f
    80003ea6:	00650513          	add	a0,a0,6 # 80022ea8 <itable>
    80003eaa:	ffffd097          	auipc	ra,0xffffd
    80003eae:	d28080e7          	jalr	-728(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003eb2:	449c                	lw	a5,8(s1)
    80003eb4:	2785                	addw	a5,a5,1
    80003eb6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eb8:	0001f517          	auipc	a0,0x1f
    80003ebc:	ff050513          	add	a0,a0,-16 # 80022ea8 <itable>
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	dc6080e7          	jalr	-570(ra) # 80000c86 <release>
}
    80003ec8:	8526                	mv	a0,s1
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	64a2                	ld	s1,8(sp)
    80003ed0:	6105                	add	sp,sp,32
    80003ed2:	8082                	ret

0000000080003ed4 <ilock>:
{
    80003ed4:	1101                	add	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	e426                	sd	s1,8(sp)
    80003edc:	e04a                	sd	s2,0(sp)
    80003ede:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ee0:	c115                	beqz	a0,80003f04 <ilock+0x30>
    80003ee2:	84aa                	mv	s1,a0
    80003ee4:	451c                	lw	a5,8(a0)
    80003ee6:	00f05f63          	blez	a5,80003f04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003eea:	0541                	add	a0,a0,16
    80003eec:	00001097          	auipc	ra,0x1
    80003ef0:	c7e080e7          	jalr	-898(ra) # 80004b6a <acquiresleep>
  if(ip->valid == 0){
    80003ef4:	40bc                	lw	a5,64(s1)
    80003ef6:	cf99                	beqz	a5,80003f14 <ilock+0x40>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6902                	ld	s2,0(sp)
    80003f00:	6105                	add	sp,sp,32
    80003f02:	8082                	ret
    panic("ilock");
    80003f04:	00004517          	auipc	a0,0x4
    80003f08:	74c50513          	add	a0,a0,1868 # 80008650 <syscalls+0x1c8>
    80003f0c:	ffffc097          	auipc	ra,0xffffc
    80003f10:	630080e7          	jalr	1584(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f14:	40dc                	lw	a5,4(s1)
    80003f16:	0047d79b          	srlw	a5,a5,0x4
    80003f1a:	0001f597          	auipc	a1,0x1f
    80003f1e:	f865a583          	lw	a1,-122(a1) # 80022ea0 <sb+0x18>
    80003f22:	9dbd                	addw	a1,a1,a5
    80003f24:	4088                	lw	a0,0(s1)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	79e080e7          	jalr	1950(ra) # 800036c4 <bread>
    80003f2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f30:	05850593          	add	a1,a0,88
    80003f34:	40dc                	lw	a5,4(s1)
    80003f36:	8bbd                	and	a5,a5,15
    80003f38:	079a                	sll	a5,a5,0x6
    80003f3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f3c:	00059783          	lh	a5,0(a1)
    80003f40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f44:	00259783          	lh	a5,2(a1)
    80003f48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f4c:	00459783          	lh	a5,4(a1)
    80003f50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f54:	00659783          	lh	a5,6(a1)
    80003f58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f5c:	459c                	lw	a5,8(a1)
    80003f5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f60:	03400613          	li	a2,52
    80003f64:	05b1                	add	a1,a1,12
    80003f66:	05048513          	add	a0,s1,80
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	dc0080e7          	jalr	-576(ra) # 80000d2a <memmove>
    brelse(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	880080e7          	jalr	-1920(ra) # 800037f4 <brelse>
    ip->valid = 1;
    80003f7c:	4785                	li	a5,1
    80003f7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f80:	04449783          	lh	a5,68(s1)
    80003f84:	fbb5                	bnez	a5,80003ef8 <ilock+0x24>
      panic("ilock: no type");
    80003f86:	00004517          	auipc	a0,0x4
    80003f8a:	6d250513          	add	a0,a0,1746 # 80008658 <syscalls+0x1d0>
    80003f8e:	ffffc097          	auipc	ra,0xffffc
    80003f92:	5ae080e7          	jalr	1454(ra) # 8000053c <panic>

0000000080003f96 <iunlock>:
{
    80003f96:	1101                	add	sp,sp,-32
    80003f98:	ec06                	sd	ra,24(sp)
    80003f9a:	e822                	sd	s0,16(sp)
    80003f9c:	e426                	sd	s1,8(sp)
    80003f9e:	e04a                	sd	s2,0(sp)
    80003fa0:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fa2:	c905                	beqz	a0,80003fd2 <iunlock+0x3c>
    80003fa4:	84aa                	mv	s1,a0
    80003fa6:	01050913          	add	s2,a0,16
    80003faa:	854a                	mv	a0,s2
    80003fac:	00001097          	auipc	ra,0x1
    80003fb0:	c58080e7          	jalr	-936(ra) # 80004c04 <holdingsleep>
    80003fb4:	cd19                	beqz	a0,80003fd2 <iunlock+0x3c>
    80003fb6:	449c                	lw	a5,8(s1)
    80003fb8:	00f05d63          	blez	a5,80003fd2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	00001097          	auipc	ra,0x1
    80003fc2:	c02080e7          	jalr	-1022(ra) # 80004bc0 <releasesleep>
}
    80003fc6:	60e2                	ld	ra,24(sp)
    80003fc8:	6442                	ld	s0,16(sp)
    80003fca:	64a2                	ld	s1,8(sp)
    80003fcc:	6902                	ld	s2,0(sp)
    80003fce:	6105                	add	sp,sp,32
    80003fd0:	8082                	ret
    panic("iunlock");
    80003fd2:	00004517          	auipc	a0,0x4
    80003fd6:	69650513          	add	a0,a0,1686 # 80008668 <syscalls+0x1e0>
    80003fda:	ffffc097          	auipc	ra,0xffffc
    80003fde:	562080e7          	jalr	1378(ra) # 8000053c <panic>

0000000080003fe2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fe2:	7179                	add	sp,sp,-48
    80003fe4:	f406                	sd	ra,40(sp)
    80003fe6:	f022                	sd	s0,32(sp)
    80003fe8:	ec26                	sd	s1,24(sp)
    80003fea:	e84a                	sd	s2,16(sp)
    80003fec:	e44e                	sd	s3,8(sp)
    80003fee:	e052                	sd	s4,0(sp)
    80003ff0:	1800                	add	s0,sp,48
    80003ff2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ff4:	05050493          	add	s1,a0,80
    80003ff8:	08050913          	add	s2,a0,128
    80003ffc:	a021                	j	80004004 <itrunc+0x22>
    80003ffe:	0491                	add	s1,s1,4
    80004000:	01248d63          	beq	s1,s2,8000401a <itrunc+0x38>
    if(ip->addrs[i]){
    80004004:	408c                	lw	a1,0(s1)
    80004006:	dde5                	beqz	a1,80003ffe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004008:	0009a503          	lw	a0,0(s3)
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	8fc080e7          	jalr	-1796(ra) # 80003908 <bfree>
      ip->addrs[i] = 0;
    80004014:	0004a023          	sw	zero,0(s1)
    80004018:	b7dd                	j	80003ffe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000401a:	0809a583          	lw	a1,128(s3)
    8000401e:	e185                	bnez	a1,8000403e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004020:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004024:	854e                	mv	a0,s3
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	de2080e7          	jalr	-542(ra) # 80003e08 <iupdate>
}
    8000402e:	70a2                	ld	ra,40(sp)
    80004030:	7402                	ld	s0,32(sp)
    80004032:	64e2                	ld	s1,24(sp)
    80004034:	6942                	ld	s2,16(sp)
    80004036:	69a2                	ld	s3,8(sp)
    80004038:	6a02                	ld	s4,0(sp)
    8000403a:	6145                	add	sp,sp,48
    8000403c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000403e:	0009a503          	lw	a0,0(s3)
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	682080e7          	jalr	1666(ra) # 800036c4 <bread>
    8000404a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000404c:	05850493          	add	s1,a0,88
    80004050:	45850913          	add	s2,a0,1112
    80004054:	a021                	j	8000405c <itrunc+0x7a>
    80004056:	0491                	add	s1,s1,4
    80004058:	01248b63          	beq	s1,s2,8000406e <itrunc+0x8c>
      if(a[j])
    8000405c:	408c                	lw	a1,0(s1)
    8000405e:	dde5                	beqz	a1,80004056 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004060:	0009a503          	lw	a0,0(s3)
    80004064:	00000097          	auipc	ra,0x0
    80004068:	8a4080e7          	jalr	-1884(ra) # 80003908 <bfree>
    8000406c:	b7ed                	j	80004056 <itrunc+0x74>
    brelse(bp);
    8000406e:	8552                	mv	a0,s4
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	784080e7          	jalr	1924(ra) # 800037f4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004078:	0809a583          	lw	a1,128(s3)
    8000407c:	0009a503          	lw	a0,0(s3)
    80004080:	00000097          	auipc	ra,0x0
    80004084:	888080e7          	jalr	-1912(ra) # 80003908 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004088:	0809a023          	sw	zero,128(s3)
    8000408c:	bf51                	j	80004020 <itrunc+0x3e>

000000008000408e <iput>:
{
    8000408e:	1101                	add	sp,sp,-32
    80004090:	ec06                	sd	ra,24(sp)
    80004092:	e822                	sd	s0,16(sp)
    80004094:	e426                	sd	s1,8(sp)
    80004096:	e04a                	sd	s2,0(sp)
    80004098:	1000                	add	s0,sp,32
    8000409a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000409c:	0001f517          	auipc	a0,0x1f
    800040a0:	e0c50513          	add	a0,a0,-500 # 80022ea8 <itable>
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	b2e080e7          	jalr	-1234(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ac:	4498                	lw	a4,8(s1)
    800040ae:	4785                	li	a5,1
    800040b0:	02f70363          	beq	a4,a5,800040d6 <iput+0x48>
  ip->ref--;
    800040b4:	449c                	lw	a5,8(s1)
    800040b6:	37fd                	addw	a5,a5,-1
    800040b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040ba:	0001f517          	auipc	a0,0x1f
    800040be:	dee50513          	add	a0,a0,-530 # 80022ea8 <itable>
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	bc4080e7          	jalr	-1084(ra) # 80000c86 <release>
}
    800040ca:	60e2                	ld	ra,24(sp)
    800040cc:	6442                	ld	s0,16(sp)
    800040ce:	64a2                	ld	s1,8(sp)
    800040d0:	6902                	ld	s2,0(sp)
    800040d2:	6105                	add	sp,sp,32
    800040d4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d6:	40bc                	lw	a5,64(s1)
    800040d8:	dff1                	beqz	a5,800040b4 <iput+0x26>
    800040da:	04a49783          	lh	a5,74(s1)
    800040de:	fbf9                	bnez	a5,800040b4 <iput+0x26>
    acquiresleep(&ip->lock);
    800040e0:	01048913          	add	s2,s1,16
    800040e4:	854a                	mv	a0,s2
    800040e6:	00001097          	auipc	ra,0x1
    800040ea:	a84080e7          	jalr	-1404(ra) # 80004b6a <acquiresleep>
    release(&itable.lock);
    800040ee:	0001f517          	auipc	a0,0x1f
    800040f2:	dba50513          	add	a0,a0,-582 # 80022ea8 <itable>
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	b90080e7          	jalr	-1136(ra) # 80000c86 <release>
    itrunc(ip);
    800040fe:	8526                	mv	a0,s1
    80004100:	00000097          	auipc	ra,0x0
    80004104:	ee2080e7          	jalr	-286(ra) # 80003fe2 <itrunc>
    ip->type = 0;
    80004108:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000410c:	8526                	mv	a0,s1
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	cfa080e7          	jalr	-774(ra) # 80003e08 <iupdate>
    ip->valid = 0;
    80004116:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000411a:	854a                	mv	a0,s2
    8000411c:	00001097          	auipc	ra,0x1
    80004120:	aa4080e7          	jalr	-1372(ra) # 80004bc0 <releasesleep>
    acquire(&itable.lock);
    80004124:	0001f517          	auipc	a0,0x1f
    80004128:	d8450513          	add	a0,a0,-636 # 80022ea8 <itable>
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	aa6080e7          	jalr	-1370(ra) # 80000bd2 <acquire>
    80004134:	b741                	j	800040b4 <iput+0x26>

0000000080004136 <iunlockput>:
{
    80004136:	1101                	add	sp,sp,-32
    80004138:	ec06                	sd	ra,24(sp)
    8000413a:	e822                	sd	s0,16(sp)
    8000413c:	e426                	sd	s1,8(sp)
    8000413e:	1000                	add	s0,sp,32
    80004140:	84aa                	mv	s1,a0
  iunlock(ip);
    80004142:	00000097          	auipc	ra,0x0
    80004146:	e54080e7          	jalr	-428(ra) # 80003f96 <iunlock>
  iput(ip);
    8000414a:	8526                	mv	a0,s1
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	f42080e7          	jalr	-190(ra) # 8000408e <iput>
}
    80004154:	60e2                	ld	ra,24(sp)
    80004156:	6442                	ld	s0,16(sp)
    80004158:	64a2                	ld	s1,8(sp)
    8000415a:	6105                	add	sp,sp,32
    8000415c:	8082                	ret

000000008000415e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000415e:	1141                	add	sp,sp,-16
    80004160:	e422                	sd	s0,8(sp)
    80004162:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80004164:	411c                	lw	a5,0(a0)
    80004166:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004168:	415c                	lw	a5,4(a0)
    8000416a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000416c:	04451783          	lh	a5,68(a0)
    80004170:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004174:	04a51783          	lh	a5,74(a0)
    80004178:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000417c:	04c56783          	lwu	a5,76(a0)
    80004180:	e99c                	sd	a5,16(a1)
}
    80004182:	6422                	ld	s0,8(sp)
    80004184:	0141                	add	sp,sp,16
    80004186:	8082                	ret

0000000080004188 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004188:	457c                	lw	a5,76(a0)
    8000418a:	0ed7e963          	bltu	a5,a3,8000427c <readi+0xf4>
{
    8000418e:	7159                	add	sp,sp,-112
    80004190:	f486                	sd	ra,104(sp)
    80004192:	f0a2                	sd	s0,96(sp)
    80004194:	eca6                	sd	s1,88(sp)
    80004196:	e8ca                	sd	s2,80(sp)
    80004198:	e4ce                	sd	s3,72(sp)
    8000419a:	e0d2                	sd	s4,64(sp)
    8000419c:	fc56                	sd	s5,56(sp)
    8000419e:	f85a                	sd	s6,48(sp)
    800041a0:	f45e                	sd	s7,40(sp)
    800041a2:	f062                	sd	s8,32(sp)
    800041a4:	ec66                	sd	s9,24(sp)
    800041a6:	e86a                	sd	s10,16(sp)
    800041a8:	e46e                	sd	s11,8(sp)
    800041aa:	1880                	add	s0,sp,112
    800041ac:	8b2a                	mv	s6,a0
    800041ae:	8bae                	mv	s7,a1
    800041b0:	8a32                	mv	s4,a2
    800041b2:	84b6                	mv	s1,a3
    800041b4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041b6:	9f35                	addw	a4,a4,a3
    return 0;
    800041b8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041ba:	0ad76063          	bltu	a4,a3,8000425a <readi+0xd2>
  if(off + n > ip->size)
    800041be:	00e7f463          	bgeu	a5,a4,800041c6 <readi+0x3e>
    n = ip->size - off;
    800041c2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041c6:	0a0a8963          	beqz	s5,80004278 <readi+0xf0>
    800041ca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041cc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041d0:	5c7d                	li	s8,-1
    800041d2:	a82d                	j	8000420c <readi+0x84>
    800041d4:	020d1d93          	sll	s11,s10,0x20
    800041d8:	020ddd93          	srl	s11,s11,0x20
    800041dc:	05890613          	add	a2,s2,88
    800041e0:	86ee                	mv	a3,s11
    800041e2:	963a                	add	a2,a2,a4
    800041e4:	85d2                	mv	a1,s4
    800041e6:	855e                	mv	a0,s7
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	728080e7          	jalr	1832(ra) # 80002910 <either_copyout>
    800041f0:	05850d63          	beq	a0,s8,8000424a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041f4:	854a                	mv	a0,s2
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	5fe080e7          	jalr	1534(ra) # 800037f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041fe:	013d09bb          	addw	s3,s10,s3
    80004202:	009d04bb          	addw	s1,s10,s1
    80004206:	9a6e                	add	s4,s4,s11
    80004208:	0559f763          	bgeu	s3,s5,80004256 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000420c:	00a4d59b          	srlw	a1,s1,0xa
    80004210:	855a                	mv	a0,s6
    80004212:	00000097          	auipc	ra,0x0
    80004216:	8a4080e7          	jalr	-1884(ra) # 80003ab6 <bmap>
    8000421a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000421e:	cd85                	beqz	a1,80004256 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004220:	000b2503          	lw	a0,0(s6)
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	4a0080e7          	jalr	1184(ra) # 800036c4 <bread>
    8000422c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000422e:	3ff4f713          	and	a4,s1,1023
    80004232:	40ec87bb          	subw	a5,s9,a4
    80004236:	413a86bb          	subw	a3,s5,s3
    8000423a:	8d3e                	mv	s10,a5
    8000423c:	2781                	sext.w	a5,a5
    8000423e:	0006861b          	sext.w	a2,a3
    80004242:	f8f679e3          	bgeu	a2,a5,800041d4 <readi+0x4c>
    80004246:	8d36                	mv	s10,a3
    80004248:	b771                	j	800041d4 <readi+0x4c>
      brelse(bp);
    8000424a:	854a                	mv	a0,s2
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	5a8080e7          	jalr	1448(ra) # 800037f4 <brelse>
      tot = -1;
    80004254:	59fd                	li	s3,-1
  }
  return tot;
    80004256:	0009851b          	sext.w	a0,s3
}
    8000425a:	70a6                	ld	ra,104(sp)
    8000425c:	7406                	ld	s0,96(sp)
    8000425e:	64e6                	ld	s1,88(sp)
    80004260:	6946                	ld	s2,80(sp)
    80004262:	69a6                	ld	s3,72(sp)
    80004264:	6a06                	ld	s4,64(sp)
    80004266:	7ae2                	ld	s5,56(sp)
    80004268:	7b42                	ld	s6,48(sp)
    8000426a:	7ba2                	ld	s7,40(sp)
    8000426c:	7c02                	ld	s8,32(sp)
    8000426e:	6ce2                	ld	s9,24(sp)
    80004270:	6d42                	ld	s10,16(sp)
    80004272:	6da2                	ld	s11,8(sp)
    80004274:	6165                	add	sp,sp,112
    80004276:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004278:	89d6                	mv	s3,s5
    8000427a:	bff1                	j	80004256 <readi+0xce>
    return 0;
    8000427c:	4501                	li	a0,0
}
    8000427e:	8082                	ret

0000000080004280 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004280:	457c                	lw	a5,76(a0)
    80004282:	10d7e863          	bltu	a5,a3,80004392 <writei+0x112>
{
    80004286:	7159                	add	sp,sp,-112
    80004288:	f486                	sd	ra,104(sp)
    8000428a:	f0a2                	sd	s0,96(sp)
    8000428c:	eca6                	sd	s1,88(sp)
    8000428e:	e8ca                	sd	s2,80(sp)
    80004290:	e4ce                	sd	s3,72(sp)
    80004292:	e0d2                	sd	s4,64(sp)
    80004294:	fc56                	sd	s5,56(sp)
    80004296:	f85a                	sd	s6,48(sp)
    80004298:	f45e                	sd	s7,40(sp)
    8000429a:	f062                	sd	s8,32(sp)
    8000429c:	ec66                	sd	s9,24(sp)
    8000429e:	e86a                	sd	s10,16(sp)
    800042a0:	e46e                	sd	s11,8(sp)
    800042a2:	1880                	add	s0,sp,112
    800042a4:	8aaa                	mv	s5,a0
    800042a6:	8bae                	mv	s7,a1
    800042a8:	8a32                	mv	s4,a2
    800042aa:	8936                	mv	s2,a3
    800042ac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042ae:	00e687bb          	addw	a5,a3,a4
    800042b2:	0ed7e263          	bltu	a5,a3,80004396 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042b6:	00043737          	lui	a4,0x43
    800042ba:	0ef76063          	bltu	a4,a5,8000439a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042be:	0c0b0863          	beqz	s6,8000438e <writei+0x10e>
    800042c2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042c4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042c8:	5c7d                	li	s8,-1
    800042ca:	a091                	j	8000430e <writei+0x8e>
    800042cc:	020d1d93          	sll	s11,s10,0x20
    800042d0:	020ddd93          	srl	s11,s11,0x20
    800042d4:	05848513          	add	a0,s1,88
    800042d8:	86ee                	mv	a3,s11
    800042da:	8652                	mv	a2,s4
    800042dc:	85de                	mv	a1,s7
    800042de:	953a                	add	a0,a0,a4
    800042e0:	ffffe097          	auipc	ra,0xffffe
    800042e4:	686080e7          	jalr	1670(ra) # 80002966 <either_copyin>
    800042e8:	07850263          	beq	a0,s8,8000434c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042ec:	8526                	mv	a0,s1
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	75e080e7          	jalr	1886(ra) # 80004a4c <log_write>
    brelse(bp);
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	4fc080e7          	jalr	1276(ra) # 800037f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004300:	013d09bb          	addw	s3,s10,s3
    80004304:	012d093b          	addw	s2,s10,s2
    80004308:	9a6e                	add	s4,s4,s11
    8000430a:	0569f663          	bgeu	s3,s6,80004356 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000430e:	00a9559b          	srlw	a1,s2,0xa
    80004312:	8556                	mv	a0,s5
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	7a2080e7          	jalr	1954(ra) # 80003ab6 <bmap>
    8000431c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004320:	c99d                	beqz	a1,80004356 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004322:	000aa503          	lw	a0,0(s5)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	39e080e7          	jalr	926(ra) # 800036c4 <bread>
    8000432e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004330:	3ff97713          	and	a4,s2,1023
    80004334:	40ec87bb          	subw	a5,s9,a4
    80004338:	413b06bb          	subw	a3,s6,s3
    8000433c:	8d3e                	mv	s10,a5
    8000433e:	2781                	sext.w	a5,a5
    80004340:	0006861b          	sext.w	a2,a3
    80004344:	f8f674e3          	bgeu	a2,a5,800042cc <writei+0x4c>
    80004348:	8d36                	mv	s10,a3
    8000434a:	b749                	j	800042cc <writei+0x4c>
      brelse(bp);
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	4a6080e7          	jalr	1190(ra) # 800037f4 <brelse>
  }

  if(off > ip->size)
    80004356:	04caa783          	lw	a5,76(s5)
    8000435a:	0127f463          	bgeu	a5,s2,80004362 <writei+0xe2>
    ip->size = off;
    8000435e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004362:	8556                	mv	a0,s5
    80004364:	00000097          	auipc	ra,0x0
    80004368:	aa4080e7          	jalr	-1372(ra) # 80003e08 <iupdate>

  return tot;
    8000436c:	0009851b          	sext.w	a0,s3
}
    80004370:	70a6                	ld	ra,104(sp)
    80004372:	7406                	ld	s0,96(sp)
    80004374:	64e6                	ld	s1,88(sp)
    80004376:	6946                	ld	s2,80(sp)
    80004378:	69a6                	ld	s3,72(sp)
    8000437a:	6a06                	ld	s4,64(sp)
    8000437c:	7ae2                	ld	s5,56(sp)
    8000437e:	7b42                	ld	s6,48(sp)
    80004380:	7ba2                	ld	s7,40(sp)
    80004382:	7c02                	ld	s8,32(sp)
    80004384:	6ce2                	ld	s9,24(sp)
    80004386:	6d42                	ld	s10,16(sp)
    80004388:	6da2                	ld	s11,8(sp)
    8000438a:	6165                	add	sp,sp,112
    8000438c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000438e:	89da                	mv	s3,s6
    80004390:	bfc9                	j	80004362 <writei+0xe2>
    return -1;
    80004392:	557d                	li	a0,-1
}
    80004394:	8082                	ret
    return -1;
    80004396:	557d                	li	a0,-1
    80004398:	bfe1                	j	80004370 <writei+0xf0>
    return -1;
    8000439a:	557d                	li	a0,-1
    8000439c:	bfd1                	j	80004370 <writei+0xf0>

000000008000439e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000439e:	1141                	add	sp,sp,-16
    800043a0:	e406                	sd	ra,8(sp)
    800043a2:	e022                	sd	s0,0(sp)
    800043a4:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043a6:	4639                	li	a2,14
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	9f6080e7          	jalr	-1546(ra) # 80000d9e <strncmp>
}
    800043b0:	60a2                	ld	ra,8(sp)
    800043b2:	6402                	ld	s0,0(sp)
    800043b4:	0141                	add	sp,sp,16
    800043b6:	8082                	ret

00000000800043b8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043b8:	7139                	add	sp,sp,-64
    800043ba:	fc06                	sd	ra,56(sp)
    800043bc:	f822                	sd	s0,48(sp)
    800043be:	f426                	sd	s1,40(sp)
    800043c0:	f04a                	sd	s2,32(sp)
    800043c2:	ec4e                	sd	s3,24(sp)
    800043c4:	e852                	sd	s4,16(sp)
    800043c6:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043c8:	04451703          	lh	a4,68(a0)
    800043cc:	4785                	li	a5,1
    800043ce:	00f71a63          	bne	a4,a5,800043e2 <dirlookup+0x2a>
    800043d2:	892a                	mv	s2,a0
    800043d4:	89ae                	mv	s3,a1
    800043d6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d8:	457c                	lw	a5,76(a0)
    800043da:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043dc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043de:	e79d                	bnez	a5,8000440c <dirlookup+0x54>
    800043e0:	a8a5                	j	80004458 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043e2:	00004517          	auipc	a0,0x4
    800043e6:	28e50513          	add	a0,a0,654 # 80008670 <syscalls+0x1e8>
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	152080e7          	jalr	338(ra) # 8000053c <panic>
      panic("dirlookup read");
    800043f2:	00004517          	auipc	a0,0x4
    800043f6:	29650513          	add	a0,a0,662 # 80008688 <syscalls+0x200>
    800043fa:	ffffc097          	auipc	ra,0xffffc
    800043fe:	142080e7          	jalr	322(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004402:	24c1                	addw	s1,s1,16
    80004404:	04c92783          	lw	a5,76(s2)
    80004408:	04f4f763          	bgeu	s1,a5,80004456 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440c:	4741                	li	a4,16
    8000440e:	86a6                	mv	a3,s1
    80004410:	fc040613          	add	a2,s0,-64
    80004414:	4581                	li	a1,0
    80004416:	854a                	mv	a0,s2
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	d70080e7          	jalr	-656(ra) # 80004188 <readi>
    80004420:	47c1                	li	a5,16
    80004422:	fcf518e3          	bne	a0,a5,800043f2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004426:	fc045783          	lhu	a5,-64(s0)
    8000442a:	dfe1                	beqz	a5,80004402 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000442c:	fc240593          	add	a1,s0,-62
    80004430:	854e                	mv	a0,s3
    80004432:	00000097          	auipc	ra,0x0
    80004436:	f6c080e7          	jalr	-148(ra) # 8000439e <namecmp>
    8000443a:	f561                	bnez	a0,80004402 <dirlookup+0x4a>
      if(poff)
    8000443c:	000a0463          	beqz	s4,80004444 <dirlookup+0x8c>
        *poff = off;
    80004440:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004444:	fc045583          	lhu	a1,-64(s0)
    80004448:	00092503          	lw	a0,0(s2)
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	754080e7          	jalr	1876(ra) # 80003ba0 <iget>
    80004454:	a011                	j	80004458 <dirlookup+0xa0>
  return 0;
    80004456:	4501                	li	a0,0
}
    80004458:	70e2                	ld	ra,56(sp)
    8000445a:	7442                	ld	s0,48(sp)
    8000445c:	74a2                	ld	s1,40(sp)
    8000445e:	7902                	ld	s2,32(sp)
    80004460:	69e2                	ld	s3,24(sp)
    80004462:	6a42                	ld	s4,16(sp)
    80004464:	6121                	add	sp,sp,64
    80004466:	8082                	ret

0000000080004468 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004468:	711d                	add	sp,sp,-96
    8000446a:	ec86                	sd	ra,88(sp)
    8000446c:	e8a2                	sd	s0,80(sp)
    8000446e:	e4a6                	sd	s1,72(sp)
    80004470:	e0ca                	sd	s2,64(sp)
    80004472:	fc4e                	sd	s3,56(sp)
    80004474:	f852                	sd	s4,48(sp)
    80004476:	f456                	sd	s5,40(sp)
    80004478:	f05a                	sd	s6,32(sp)
    8000447a:	ec5e                	sd	s7,24(sp)
    8000447c:	e862                	sd	s8,16(sp)
    8000447e:	e466                	sd	s9,8(sp)
    80004480:	1080                	add	s0,sp,96
    80004482:	84aa                	mv	s1,a0
    80004484:	8b2e                	mv	s6,a1
    80004486:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004488:	00054703          	lbu	a4,0(a0)
    8000448c:	02f00793          	li	a5,47
    80004490:	02f70263          	beq	a4,a5,800044b4 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	512080e7          	jalr	1298(ra) # 800019a6 <myproc>
    8000449c:	15053503          	ld	a0,336(a0)
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	9f6080e7          	jalr	-1546(ra) # 80003e96 <idup>
    800044a8:	8a2a                	mv	s4,a0
  while(*path == '/')
    800044aa:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800044ae:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044b0:	4b85                	li	s7,1
    800044b2:	a875                	j	8000456e <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800044b4:	4585                	li	a1,1
    800044b6:	4505                	li	a0,1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	6e8080e7          	jalr	1768(ra) # 80003ba0 <iget>
    800044c0:	8a2a                	mv	s4,a0
    800044c2:	b7e5                	j	800044aa <namex+0x42>
      iunlockput(ip);
    800044c4:	8552                	mv	a0,s4
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	c70080e7          	jalr	-912(ra) # 80004136 <iunlockput>
      return 0;
    800044ce:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044d0:	8552                	mv	a0,s4
    800044d2:	60e6                	ld	ra,88(sp)
    800044d4:	6446                	ld	s0,80(sp)
    800044d6:	64a6                	ld	s1,72(sp)
    800044d8:	6906                	ld	s2,64(sp)
    800044da:	79e2                	ld	s3,56(sp)
    800044dc:	7a42                	ld	s4,48(sp)
    800044de:	7aa2                	ld	s5,40(sp)
    800044e0:	7b02                	ld	s6,32(sp)
    800044e2:	6be2                	ld	s7,24(sp)
    800044e4:	6c42                	ld	s8,16(sp)
    800044e6:	6ca2                	ld	s9,8(sp)
    800044e8:	6125                	add	sp,sp,96
    800044ea:	8082                	ret
      iunlock(ip);
    800044ec:	8552                	mv	a0,s4
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	aa8080e7          	jalr	-1368(ra) # 80003f96 <iunlock>
      return ip;
    800044f6:	bfe9                	j	800044d0 <namex+0x68>
      iunlockput(ip);
    800044f8:	8552                	mv	a0,s4
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c3c080e7          	jalr	-964(ra) # 80004136 <iunlockput>
      return 0;
    80004502:	8a4e                	mv	s4,s3
    80004504:	b7f1                	j	800044d0 <namex+0x68>
  len = path - s;
    80004506:	40998633          	sub	a2,s3,s1
    8000450a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000450e:	099c5863          	bge	s8,s9,8000459e <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004512:	4639                	li	a2,14
    80004514:	85a6                	mv	a1,s1
    80004516:	8556                	mv	a0,s5
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	812080e7          	jalr	-2030(ra) # 80000d2a <memmove>
    80004520:	84ce                	mv	s1,s3
  while(*path == '/')
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	01279763          	bne	a5,s2,80004534 <namex+0xcc>
    path++;
    8000452a:	0485                	add	s1,s1,1
  while(*path == '/')
    8000452c:	0004c783          	lbu	a5,0(s1)
    80004530:	ff278de3          	beq	a5,s2,8000452a <namex+0xc2>
    ilock(ip);
    80004534:	8552                	mv	a0,s4
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	99e080e7          	jalr	-1634(ra) # 80003ed4 <ilock>
    if(ip->type != T_DIR){
    8000453e:	044a1783          	lh	a5,68(s4)
    80004542:	f97791e3          	bne	a5,s7,800044c4 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004546:	000b0563          	beqz	s6,80004550 <namex+0xe8>
    8000454a:	0004c783          	lbu	a5,0(s1)
    8000454e:	dfd9                	beqz	a5,800044ec <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004550:	4601                	li	a2,0
    80004552:	85d6                	mv	a1,s5
    80004554:	8552                	mv	a0,s4
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	e62080e7          	jalr	-414(ra) # 800043b8 <dirlookup>
    8000455e:	89aa                	mv	s3,a0
    80004560:	dd41                	beqz	a0,800044f8 <namex+0x90>
    iunlockput(ip);
    80004562:	8552                	mv	a0,s4
    80004564:	00000097          	auipc	ra,0x0
    80004568:	bd2080e7          	jalr	-1070(ra) # 80004136 <iunlockput>
    ip = next;
    8000456c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000456e:	0004c783          	lbu	a5,0(s1)
    80004572:	01279763          	bne	a5,s2,80004580 <namex+0x118>
    path++;
    80004576:	0485                	add	s1,s1,1
  while(*path == '/')
    80004578:	0004c783          	lbu	a5,0(s1)
    8000457c:	ff278de3          	beq	a5,s2,80004576 <namex+0x10e>
  if(*path == 0)
    80004580:	cb9d                	beqz	a5,800045b6 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004582:	0004c783          	lbu	a5,0(s1)
    80004586:	89a6                	mv	s3,s1
  len = path - s;
    80004588:	4c81                	li	s9,0
    8000458a:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000458c:	01278963          	beq	a5,s2,8000459e <namex+0x136>
    80004590:	dbbd                	beqz	a5,80004506 <namex+0x9e>
    path++;
    80004592:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004594:	0009c783          	lbu	a5,0(s3)
    80004598:	ff279ce3          	bne	a5,s2,80004590 <namex+0x128>
    8000459c:	b7ad                	j	80004506 <namex+0x9e>
    memmove(name, s, len);
    8000459e:	2601                	sext.w	a2,a2
    800045a0:	85a6                	mv	a1,s1
    800045a2:	8556                	mv	a0,s5
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	786080e7          	jalr	1926(ra) # 80000d2a <memmove>
    name[len] = 0;
    800045ac:	9cd6                	add	s9,s9,s5
    800045ae:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045b2:	84ce                	mv	s1,s3
    800045b4:	b7bd                	j	80004522 <namex+0xba>
  if(nameiparent){
    800045b6:	f00b0de3          	beqz	s6,800044d0 <namex+0x68>
    iput(ip);
    800045ba:	8552                	mv	a0,s4
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	ad2080e7          	jalr	-1326(ra) # 8000408e <iput>
    return 0;
    800045c4:	4a01                	li	s4,0
    800045c6:	b729                	j	800044d0 <namex+0x68>

00000000800045c8 <dirlink>:
{
    800045c8:	7139                	add	sp,sp,-64
    800045ca:	fc06                	sd	ra,56(sp)
    800045cc:	f822                	sd	s0,48(sp)
    800045ce:	f426                	sd	s1,40(sp)
    800045d0:	f04a                	sd	s2,32(sp)
    800045d2:	ec4e                	sd	s3,24(sp)
    800045d4:	e852                	sd	s4,16(sp)
    800045d6:	0080                	add	s0,sp,64
    800045d8:	892a                	mv	s2,a0
    800045da:	8a2e                	mv	s4,a1
    800045dc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045de:	4601                	li	a2,0
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	dd8080e7          	jalr	-552(ra) # 800043b8 <dirlookup>
    800045e8:	e93d                	bnez	a0,8000465e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ea:	04c92483          	lw	s1,76(s2)
    800045ee:	c49d                	beqz	s1,8000461c <dirlink+0x54>
    800045f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045f2:	4741                	li	a4,16
    800045f4:	86a6                	mv	a3,s1
    800045f6:	fc040613          	add	a2,s0,-64
    800045fa:	4581                	li	a1,0
    800045fc:	854a                	mv	a0,s2
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	b8a080e7          	jalr	-1142(ra) # 80004188 <readi>
    80004606:	47c1                	li	a5,16
    80004608:	06f51163          	bne	a0,a5,8000466a <dirlink+0xa2>
    if(de.inum == 0)
    8000460c:	fc045783          	lhu	a5,-64(s0)
    80004610:	c791                	beqz	a5,8000461c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004612:	24c1                	addw	s1,s1,16
    80004614:	04c92783          	lw	a5,76(s2)
    80004618:	fcf4ede3          	bltu	s1,a5,800045f2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000461c:	4639                	li	a2,14
    8000461e:	85d2                	mv	a1,s4
    80004620:	fc240513          	add	a0,s0,-62
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	7b6080e7          	jalr	1974(ra) # 80000dda <strncpy>
  de.inum = inum;
    8000462c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004630:	4741                	li	a4,16
    80004632:	86a6                	mv	a3,s1
    80004634:	fc040613          	add	a2,s0,-64
    80004638:	4581                	li	a1,0
    8000463a:	854a                	mv	a0,s2
    8000463c:	00000097          	auipc	ra,0x0
    80004640:	c44080e7          	jalr	-956(ra) # 80004280 <writei>
    80004644:	1541                	add	a0,a0,-16
    80004646:	00a03533          	snez	a0,a0
    8000464a:	40a00533          	neg	a0,a0
}
    8000464e:	70e2                	ld	ra,56(sp)
    80004650:	7442                	ld	s0,48(sp)
    80004652:	74a2                	ld	s1,40(sp)
    80004654:	7902                	ld	s2,32(sp)
    80004656:	69e2                	ld	s3,24(sp)
    80004658:	6a42                	ld	s4,16(sp)
    8000465a:	6121                	add	sp,sp,64
    8000465c:	8082                	ret
    iput(ip);
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	a30080e7          	jalr	-1488(ra) # 8000408e <iput>
    return -1;
    80004666:	557d                	li	a0,-1
    80004668:	b7dd                	j	8000464e <dirlink+0x86>
      panic("dirlink read");
    8000466a:	00004517          	auipc	a0,0x4
    8000466e:	02e50513          	add	a0,a0,46 # 80008698 <syscalls+0x210>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	eca080e7          	jalr	-310(ra) # 8000053c <panic>

000000008000467a <namei>:

struct inode*
namei(char *path)
{
    8000467a:	1101                	add	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004682:	fe040613          	add	a2,s0,-32
    80004686:	4581                	li	a1,0
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	de0080e7          	jalr	-544(ra) # 80004468 <namex>
}
    80004690:	60e2                	ld	ra,24(sp)
    80004692:	6442                	ld	s0,16(sp)
    80004694:	6105                	add	sp,sp,32
    80004696:	8082                	ret

0000000080004698 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004698:	1141                	add	sp,sp,-16
    8000469a:	e406                	sd	ra,8(sp)
    8000469c:	e022                	sd	s0,0(sp)
    8000469e:	0800                	add	s0,sp,16
    800046a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046a2:	4585                	li	a1,1
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	dc4080e7          	jalr	-572(ra) # 80004468 <namex>
}
    800046ac:	60a2                	ld	ra,8(sp)
    800046ae:	6402                	ld	s0,0(sp)
    800046b0:	0141                	add	sp,sp,16
    800046b2:	8082                	ret

00000000800046b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046b4:	1101                	add	sp,sp,-32
    800046b6:	ec06                	sd	ra,24(sp)
    800046b8:	e822                	sd	s0,16(sp)
    800046ba:	e426                	sd	s1,8(sp)
    800046bc:	e04a                	sd	s2,0(sp)
    800046be:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046c0:	00020917          	auipc	s2,0x20
    800046c4:	29090913          	add	s2,s2,656 # 80024950 <log>
    800046c8:	01892583          	lw	a1,24(s2)
    800046cc:	02892503          	lw	a0,40(s2)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	ff4080e7          	jalr	-12(ra) # 800036c4 <bread>
    800046d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046da:	02c92603          	lw	a2,44(s2)
    800046de:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046e0:	00c05f63          	blez	a2,800046fe <write_head+0x4a>
    800046e4:	00020717          	auipc	a4,0x20
    800046e8:	29c70713          	add	a4,a4,668 # 80024980 <log+0x30>
    800046ec:	87aa                	mv	a5,a0
    800046ee:	060a                	sll	a2,a2,0x2
    800046f0:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800046f2:	4314                	lw	a3,0(a4)
    800046f4:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800046f6:	0711                	add	a4,a4,4
    800046f8:	0791                	add	a5,a5,4
    800046fa:	fec79ce3          	bne	a5,a2,800046f2 <write_head+0x3e>
  }
  bwrite(buf);
    800046fe:	8526                	mv	a0,s1
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	0b6080e7          	jalr	182(ra) # 800037b6 <bwrite>
  brelse(buf);
    80004708:	8526                	mv	a0,s1
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	0ea080e7          	jalr	234(ra) # 800037f4 <brelse>
}
    80004712:	60e2                	ld	ra,24(sp)
    80004714:	6442                	ld	s0,16(sp)
    80004716:	64a2                	ld	s1,8(sp)
    80004718:	6902                	ld	s2,0(sp)
    8000471a:	6105                	add	sp,sp,32
    8000471c:	8082                	ret

000000008000471e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000471e:	00020797          	auipc	a5,0x20
    80004722:	25e7a783          	lw	a5,606(a5) # 8002497c <log+0x2c>
    80004726:	0af05d63          	blez	a5,800047e0 <install_trans+0xc2>
{
    8000472a:	7139                	add	sp,sp,-64
    8000472c:	fc06                	sd	ra,56(sp)
    8000472e:	f822                	sd	s0,48(sp)
    80004730:	f426                	sd	s1,40(sp)
    80004732:	f04a                	sd	s2,32(sp)
    80004734:	ec4e                	sd	s3,24(sp)
    80004736:	e852                	sd	s4,16(sp)
    80004738:	e456                	sd	s5,8(sp)
    8000473a:	e05a                	sd	s6,0(sp)
    8000473c:	0080                	add	s0,sp,64
    8000473e:	8b2a                	mv	s6,a0
    80004740:	00020a97          	auipc	s5,0x20
    80004744:	240a8a93          	add	s5,s5,576 # 80024980 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004748:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000474a:	00020997          	auipc	s3,0x20
    8000474e:	20698993          	add	s3,s3,518 # 80024950 <log>
    80004752:	a00d                	j	80004774 <install_trans+0x56>
    brelse(lbuf);
    80004754:	854a                	mv	a0,s2
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	09e080e7          	jalr	158(ra) # 800037f4 <brelse>
    brelse(dbuf);
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	094080e7          	jalr	148(ra) # 800037f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004768:	2a05                	addw	s4,s4,1
    8000476a:	0a91                	add	s5,s5,4
    8000476c:	02c9a783          	lw	a5,44(s3)
    80004770:	04fa5e63          	bge	s4,a5,800047cc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004774:	0189a583          	lw	a1,24(s3)
    80004778:	014585bb          	addw	a1,a1,s4
    8000477c:	2585                	addw	a1,a1,1
    8000477e:	0289a503          	lw	a0,40(s3)
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	f42080e7          	jalr	-190(ra) # 800036c4 <bread>
    8000478a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000478c:	000aa583          	lw	a1,0(s5)
    80004790:	0289a503          	lw	a0,40(s3)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	f30080e7          	jalr	-208(ra) # 800036c4 <bread>
    8000479c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000479e:	40000613          	li	a2,1024
    800047a2:	05890593          	add	a1,s2,88
    800047a6:	05850513          	add	a0,a0,88
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	580080e7          	jalr	1408(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800047b2:	8526                	mv	a0,s1
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	002080e7          	jalr	2(ra) # 800037b6 <bwrite>
    if(recovering == 0)
    800047bc:	f80b1ce3          	bnez	s6,80004754 <install_trans+0x36>
      bunpin(dbuf);
    800047c0:	8526                	mv	a0,s1
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	10a080e7          	jalr	266(ra) # 800038cc <bunpin>
    800047ca:	b769                	j	80004754 <install_trans+0x36>
}
    800047cc:	70e2                	ld	ra,56(sp)
    800047ce:	7442                	ld	s0,48(sp)
    800047d0:	74a2                	ld	s1,40(sp)
    800047d2:	7902                	ld	s2,32(sp)
    800047d4:	69e2                	ld	s3,24(sp)
    800047d6:	6a42                	ld	s4,16(sp)
    800047d8:	6aa2                	ld	s5,8(sp)
    800047da:	6b02                	ld	s6,0(sp)
    800047dc:	6121                	add	sp,sp,64
    800047de:	8082                	ret
    800047e0:	8082                	ret

00000000800047e2 <initlog>:
{
    800047e2:	7179                	add	sp,sp,-48
    800047e4:	f406                	sd	ra,40(sp)
    800047e6:	f022                	sd	s0,32(sp)
    800047e8:	ec26                	sd	s1,24(sp)
    800047ea:	e84a                	sd	s2,16(sp)
    800047ec:	e44e                	sd	s3,8(sp)
    800047ee:	1800                	add	s0,sp,48
    800047f0:	892a                	mv	s2,a0
    800047f2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047f4:	00020497          	auipc	s1,0x20
    800047f8:	15c48493          	add	s1,s1,348 # 80024950 <log>
    800047fc:	00004597          	auipc	a1,0x4
    80004800:	eac58593          	add	a1,a1,-340 # 800086a8 <syscalls+0x220>
    80004804:	8526                	mv	a0,s1
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	33c080e7          	jalr	828(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    8000480e:	0149a583          	lw	a1,20(s3)
    80004812:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004814:	0109a783          	lw	a5,16(s3)
    80004818:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000481a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000481e:	854a                	mv	a0,s2
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	ea4080e7          	jalr	-348(ra) # 800036c4 <bread>
  log.lh.n = lh->n;
    80004828:	4d30                	lw	a2,88(a0)
    8000482a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000482c:	00c05f63          	blez	a2,8000484a <initlog+0x68>
    80004830:	87aa                	mv	a5,a0
    80004832:	00020717          	auipc	a4,0x20
    80004836:	14e70713          	add	a4,a4,334 # 80024980 <log+0x30>
    8000483a:	060a                	sll	a2,a2,0x2
    8000483c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000483e:	4ff4                	lw	a3,92(a5)
    80004840:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004842:	0791                	add	a5,a5,4
    80004844:	0711                	add	a4,a4,4
    80004846:	fec79ce3          	bne	a5,a2,8000483e <initlog+0x5c>
  brelse(buf);
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	faa080e7          	jalr	-86(ra) # 800037f4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004852:	4505                	li	a0,1
    80004854:	00000097          	auipc	ra,0x0
    80004858:	eca080e7          	jalr	-310(ra) # 8000471e <install_trans>
  log.lh.n = 0;
    8000485c:	00020797          	auipc	a5,0x20
    80004860:	1207a023          	sw	zero,288(a5) # 8002497c <log+0x2c>
  write_head(); // clear the log
    80004864:	00000097          	auipc	ra,0x0
    80004868:	e50080e7          	jalr	-432(ra) # 800046b4 <write_head>
}
    8000486c:	70a2                	ld	ra,40(sp)
    8000486e:	7402                	ld	s0,32(sp)
    80004870:	64e2                	ld	s1,24(sp)
    80004872:	6942                	ld	s2,16(sp)
    80004874:	69a2                	ld	s3,8(sp)
    80004876:	6145                	add	sp,sp,48
    80004878:	8082                	ret

000000008000487a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000487a:	1101                	add	sp,sp,-32
    8000487c:	ec06                	sd	ra,24(sp)
    8000487e:	e822                	sd	s0,16(sp)
    80004880:	e426                	sd	s1,8(sp)
    80004882:	e04a                	sd	s2,0(sp)
    80004884:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004886:	00020517          	auipc	a0,0x20
    8000488a:	0ca50513          	add	a0,a0,202 # 80024950 <log>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	344080e7          	jalr	836(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004896:	00020497          	auipc	s1,0x20
    8000489a:	0ba48493          	add	s1,s1,186 # 80024950 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000489e:	4979                	li	s2,30
    800048a0:	a039                	j	800048ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800048a2:	85a6                	mv	a1,s1
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffe097          	auipc	ra,0xffffe
    800048aa:	c3e080e7          	jalr	-962(ra) # 800024e4 <sleep>
    if(log.committing){
    800048ae:	50dc                	lw	a5,36(s1)
    800048b0:	fbed                	bnez	a5,800048a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048b2:	5098                	lw	a4,32(s1)
    800048b4:	2705                	addw	a4,a4,1
    800048b6:	0027179b          	sllw	a5,a4,0x2
    800048ba:	9fb9                	addw	a5,a5,a4
    800048bc:	0017979b          	sllw	a5,a5,0x1
    800048c0:	54d4                	lw	a3,44(s1)
    800048c2:	9fb5                	addw	a5,a5,a3
    800048c4:	00f95963          	bge	s2,a5,800048d6 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048c8:	85a6                	mv	a1,s1
    800048ca:	8526                	mv	a0,s1
    800048cc:	ffffe097          	auipc	ra,0xffffe
    800048d0:	c18080e7          	jalr	-1000(ra) # 800024e4 <sleep>
    800048d4:	bfe9                	j	800048ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048d6:	00020517          	auipc	a0,0x20
    800048da:	07a50513          	add	a0,a0,122 # 80024950 <log>
    800048de:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	3a6080e7          	jalr	934(ra) # 80000c86 <release>
      break;
    }
  }
}
    800048e8:	60e2                	ld	ra,24(sp)
    800048ea:	6442                	ld	s0,16(sp)
    800048ec:	64a2                	ld	s1,8(sp)
    800048ee:	6902                	ld	s2,0(sp)
    800048f0:	6105                	add	sp,sp,32
    800048f2:	8082                	ret

00000000800048f4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048f4:	7139                	add	sp,sp,-64
    800048f6:	fc06                	sd	ra,56(sp)
    800048f8:	f822                	sd	s0,48(sp)
    800048fa:	f426                	sd	s1,40(sp)
    800048fc:	f04a                	sd	s2,32(sp)
    800048fe:	ec4e                	sd	s3,24(sp)
    80004900:	e852                	sd	s4,16(sp)
    80004902:	e456                	sd	s5,8(sp)
    80004904:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004906:	00020497          	auipc	s1,0x20
    8000490a:	04a48493          	add	s1,s1,74 # 80024950 <log>
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	2c2080e7          	jalr	706(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004918:	509c                	lw	a5,32(s1)
    8000491a:	37fd                	addw	a5,a5,-1
    8000491c:	0007891b          	sext.w	s2,a5
    80004920:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004922:	50dc                	lw	a5,36(s1)
    80004924:	e7b9                	bnez	a5,80004972 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004926:	04091e63          	bnez	s2,80004982 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000492a:	00020497          	auipc	s1,0x20
    8000492e:	02648493          	add	s1,s1,38 # 80024950 <log>
    80004932:	4785                	li	a5,1
    80004934:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	34e080e7          	jalr	846(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004940:	54dc                	lw	a5,44(s1)
    80004942:	06f04763          	bgtz	a5,800049b0 <end_op+0xbc>
    acquire(&log.lock);
    80004946:	00020497          	auipc	s1,0x20
    8000494a:	00a48493          	add	s1,s1,10 # 80024950 <log>
    8000494e:	8526                	mv	a0,s1
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	282080e7          	jalr	642(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004958:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000495c:	8526                	mv	a0,s1
    8000495e:	ffffe097          	auipc	ra,0xffffe
    80004962:	bea080e7          	jalr	-1046(ra) # 80002548 <wakeup>
    release(&log.lock);
    80004966:	8526                	mv	a0,s1
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	31e080e7          	jalr	798(ra) # 80000c86 <release>
}
    80004970:	a03d                	j	8000499e <end_op+0xaa>
    panic("log.committing");
    80004972:	00004517          	auipc	a0,0x4
    80004976:	d3e50513          	add	a0,a0,-706 # 800086b0 <syscalls+0x228>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	bc2080e7          	jalr	-1086(ra) # 8000053c <panic>
    wakeup(&log);
    80004982:	00020497          	auipc	s1,0x20
    80004986:	fce48493          	add	s1,s1,-50 # 80024950 <log>
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffe097          	auipc	ra,0xffffe
    80004990:	bbc080e7          	jalr	-1092(ra) # 80002548 <wakeup>
  release(&log.lock);
    80004994:	8526                	mv	a0,s1
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	2f0080e7          	jalr	752(ra) # 80000c86 <release>
}
    8000499e:	70e2                	ld	ra,56(sp)
    800049a0:	7442                	ld	s0,48(sp)
    800049a2:	74a2                	ld	s1,40(sp)
    800049a4:	7902                	ld	s2,32(sp)
    800049a6:	69e2                	ld	s3,24(sp)
    800049a8:	6a42                	ld	s4,16(sp)
    800049aa:	6aa2                	ld	s5,8(sp)
    800049ac:	6121                	add	sp,sp,64
    800049ae:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b0:	00020a97          	auipc	s5,0x20
    800049b4:	fd0a8a93          	add	s5,s5,-48 # 80024980 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049b8:	00020a17          	auipc	s4,0x20
    800049bc:	f98a0a13          	add	s4,s4,-104 # 80024950 <log>
    800049c0:	018a2583          	lw	a1,24(s4)
    800049c4:	012585bb          	addw	a1,a1,s2
    800049c8:	2585                	addw	a1,a1,1
    800049ca:	028a2503          	lw	a0,40(s4)
    800049ce:	fffff097          	auipc	ra,0xfffff
    800049d2:	cf6080e7          	jalr	-778(ra) # 800036c4 <bread>
    800049d6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049d8:	000aa583          	lw	a1,0(s5)
    800049dc:	028a2503          	lw	a0,40(s4)
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	ce4080e7          	jalr	-796(ra) # 800036c4 <bread>
    800049e8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049ea:	40000613          	li	a2,1024
    800049ee:	05850593          	add	a1,a0,88
    800049f2:	05848513          	add	a0,s1,88
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	334080e7          	jalr	820(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800049fe:	8526                	mv	a0,s1
    80004a00:	fffff097          	auipc	ra,0xfffff
    80004a04:	db6080e7          	jalr	-586(ra) # 800037b6 <bwrite>
    brelse(from);
    80004a08:	854e                	mv	a0,s3
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	dea080e7          	jalr	-534(ra) # 800037f4 <brelse>
    brelse(to);
    80004a12:	8526                	mv	a0,s1
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	de0080e7          	jalr	-544(ra) # 800037f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a1c:	2905                	addw	s2,s2,1
    80004a1e:	0a91                	add	s5,s5,4
    80004a20:	02ca2783          	lw	a5,44(s4)
    80004a24:	f8f94ee3          	blt	s2,a5,800049c0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c8c080e7          	jalr	-884(ra) # 800046b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a30:	4501                	li	a0,0
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	cec080e7          	jalr	-788(ra) # 8000471e <install_trans>
    log.lh.n = 0;
    80004a3a:	00020797          	auipc	a5,0x20
    80004a3e:	f407a123          	sw	zero,-190(a5) # 8002497c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	c72080e7          	jalr	-910(ra) # 800046b4 <write_head>
    80004a4a:	bdf5                	j	80004946 <end_op+0x52>

0000000080004a4c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a4c:	1101                	add	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	e04a                	sd	s2,0(sp)
    80004a56:	1000                	add	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a5a:	00020917          	auipc	s2,0x20
    80004a5e:	ef690913          	add	s2,s2,-266 # 80024950 <log>
    80004a62:	854a                	mv	a0,s2
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a6c:	02c92603          	lw	a2,44(s2)
    80004a70:	47f5                	li	a5,29
    80004a72:	06c7c563          	blt	a5,a2,80004adc <log_write+0x90>
    80004a76:	00020797          	auipc	a5,0x20
    80004a7a:	ef67a783          	lw	a5,-266(a5) # 8002496c <log+0x1c>
    80004a7e:	37fd                	addw	a5,a5,-1
    80004a80:	04f65e63          	bge	a2,a5,80004adc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a84:	00020797          	auipc	a5,0x20
    80004a88:	eec7a783          	lw	a5,-276(a5) # 80024970 <log+0x20>
    80004a8c:	06f05063          	blez	a5,80004aec <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a90:	4781                	li	a5,0
    80004a92:	06c05563          	blez	a2,80004afc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a96:	44cc                	lw	a1,12(s1)
    80004a98:	00020717          	auipc	a4,0x20
    80004a9c:	ee870713          	add	a4,a4,-280 # 80024980 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004aa0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aa2:	4314                	lw	a3,0(a4)
    80004aa4:	04b68c63          	beq	a3,a1,80004afc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004aa8:	2785                	addw	a5,a5,1
    80004aaa:	0711                	add	a4,a4,4
    80004aac:	fef61be3          	bne	a2,a5,80004aa2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ab0:	0621                	add	a2,a2,8
    80004ab2:	060a                	sll	a2,a2,0x2
    80004ab4:	00020797          	auipc	a5,0x20
    80004ab8:	e9c78793          	add	a5,a5,-356 # 80024950 <log>
    80004abc:	97b2                	add	a5,a5,a2
    80004abe:	44d8                	lw	a4,12(s1)
    80004ac0:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	dcc080e7          	jalr	-564(ra) # 80003890 <bpin>
    log.lh.n++;
    80004acc:	00020717          	auipc	a4,0x20
    80004ad0:	e8470713          	add	a4,a4,-380 # 80024950 <log>
    80004ad4:	575c                	lw	a5,44(a4)
    80004ad6:	2785                	addw	a5,a5,1
    80004ad8:	d75c                	sw	a5,44(a4)
    80004ada:	a82d                	j	80004b14 <log_write+0xc8>
    panic("too big a transaction");
    80004adc:	00004517          	auipc	a0,0x4
    80004ae0:	be450513          	add	a0,a0,-1052 # 800086c0 <syscalls+0x238>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	a58080e7          	jalr	-1448(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004aec:	00004517          	auipc	a0,0x4
    80004af0:	bec50513          	add	a0,a0,-1044 # 800086d8 <syscalls+0x250>
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	a48080e7          	jalr	-1464(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004afc:	00878693          	add	a3,a5,8
    80004b00:	068a                	sll	a3,a3,0x2
    80004b02:	00020717          	auipc	a4,0x20
    80004b06:	e4e70713          	add	a4,a4,-434 # 80024950 <log>
    80004b0a:	9736                	add	a4,a4,a3
    80004b0c:	44d4                	lw	a3,12(s1)
    80004b0e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b10:	faf609e3          	beq	a2,a5,80004ac2 <log_write+0x76>
  }
  release(&log.lock);
    80004b14:	00020517          	auipc	a0,0x20
    80004b18:	e3c50513          	add	a0,a0,-452 # 80024950 <log>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	16a080e7          	jalr	362(ra) # 80000c86 <release>
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6902                	ld	s2,0(sp)
    80004b2c:	6105                	add	sp,sp,32
    80004b2e:	8082                	ret

0000000080004b30 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b30:	1101                	add	sp,sp,-32
    80004b32:	ec06                	sd	ra,24(sp)
    80004b34:	e822                	sd	s0,16(sp)
    80004b36:	e426                	sd	s1,8(sp)
    80004b38:	e04a                	sd	s2,0(sp)
    80004b3a:	1000                	add	s0,sp,32
    80004b3c:	84aa                	mv	s1,a0
    80004b3e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b40:	00004597          	auipc	a1,0x4
    80004b44:	bb858593          	add	a1,a1,-1096 # 800086f8 <syscalls+0x270>
    80004b48:	0521                	add	a0,a0,8
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	ff8080e7          	jalr	-8(ra) # 80000b42 <initlock>
  lk->name = name;
    80004b52:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b56:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b5a:	0204a423          	sw	zero,40(s1)
}
    80004b5e:	60e2                	ld	ra,24(sp)
    80004b60:	6442                	ld	s0,16(sp)
    80004b62:	64a2                	ld	s1,8(sp)
    80004b64:	6902                	ld	s2,0(sp)
    80004b66:	6105                	add	sp,sp,32
    80004b68:	8082                	ret

0000000080004b6a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b6a:	1101                	add	sp,sp,-32
    80004b6c:	ec06                	sd	ra,24(sp)
    80004b6e:	e822                	sd	s0,16(sp)
    80004b70:	e426                	sd	s1,8(sp)
    80004b72:	e04a                	sd	s2,0(sp)
    80004b74:	1000                	add	s0,sp,32
    80004b76:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b78:	00850913          	add	s2,a0,8
    80004b7c:	854a                	mv	a0,s2
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	054080e7          	jalr	84(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004b86:	409c                	lw	a5,0(s1)
    80004b88:	cb89                	beqz	a5,80004b9a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b8a:	85ca                	mv	a1,s2
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffe097          	auipc	ra,0xffffe
    80004b92:	956080e7          	jalr	-1706(ra) # 800024e4 <sleep>
  while (lk->locked) {
    80004b96:	409c                	lw	a5,0(s1)
    80004b98:	fbed                	bnez	a5,80004b8a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b9a:	4785                	li	a5,1
    80004b9c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	e08080e7          	jalr	-504(ra) # 800019a6 <myproc>
    80004ba6:	591c                	lw	a5,48(a0)
    80004ba8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004baa:	854a                	mv	a0,s2
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	0da080e7          	jalr	218(ra) # 80000c86 <release>
}
    80004bb4:	60e2                	ld	ra,24(sp)
    80004bb6:	6442                	ld	s0,16(sp)
    80004bb8:	64a2                	ld	s1,8(sp)
    80004bba:	6902                	ld	s2,0(sp)
    80004bbc:	6105                	add	sp,sp,32
    80004bbe:	8082                	ret

0000000080004bc0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bc0:	1101                	add	sp,sp,-32
    80004bc2:	ec06                	sd	ra,24(sp)
    80004bc4:	e822                	sd	s0,16(sp)
    80004bc6:	e426                	sd	s1,8(sp)
    80004bc8:	e04a                	sd	s2,0(sp)
    80004bca:	1000                	add	s0,sp,32
    80004bcc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bce:	00850913          	add	s2,a0,8
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	ffe080e7          	jalr	-2(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004bdc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004be0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffe097          	auipc	ra,0xffffe
    80004bea:	962080e7          	jalr	-1694(ra) # 80002548 <wakeup>
  release(&lk->lk);
    80004bee:	854a                	mv	a0,s2
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	096080e7          	jalr	150(ra) # 80000c86 <release>
}
    80004bf8:	60e2                	ld	ra,24(sp)
    80004bfa:	6442                	ld	s0,16(sp)
    80004bfc:	64a2                	ld	s1,8(sp)
    80004bfe:	6902                	ld	s2,0(sp)
    80004c00:	6105                	add	sp,sp,32
    80004c02:	8082                	ret

0000000080004c04 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c04:	7179                	add	sp,sp,-48
    80004c06:	f406                	sd	ra,40(sp)
    80004c08:	f022                	sd	s0,32(sp)
    80004c0a:	ec26                	sd	s1,24(sp)
    80004c0c:	e84a                	sd	s2,16(sp)
    80004c0e:	e44e                	sd	s3,8(sp)
    80004c10:	1800                	add	s0,sp,48
    80004c12:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c14:	00850913          	add	s2,a0,8
    80004c18:	854a                	mv	a0,s2
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	fb8080e7          	jalr	-72(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c22:	409c                	lw	a5,0(s1)
    80004c24:	ef99                	bnez	a5,80004c42 <holdingsleep+0x3e>
    80004c26:	4481                	li	s1,0
  release(&lk->lk);
    80004c28:	854a                	mv	a0,s2
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	05c080e7          	jalr	92(ra) # 80000c86 <release>
  return r;
}
    80004c32:	8526                	mv	a0,s1
    80004c34:	70a2                	ld	ra,40(sp)
    80004c36:	7402                	ld	s0,32(sp)
    80004c38:	64e2                	ld	s1,24(sp)
    80004c3a:	6942                	ld	s2,16(sp)
    80004c3c:	69a2                	ld	s3,8(sp)
    80004c3e:	6145                	add	sp,sp,48
    80004c40:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c42:	0284a983          	lw	s3,40(s1)
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	d60080e7          	jalr	-672(ra) # 800019a6 <myproc>
    80004c4e:	5904                	lw	s1,48(a0)
    80004c50:	413484b3          	sub	s1,s1,s3
    80004c54:	0014b493          	seqz	s1,s1
    80004c58:	bfc1                	j	80004c28 <holdingsleep+0x24>

0000000080004c5a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c5a:	1141                	add	sp,sp,-16
    80004c5c:	e406                	sd	ra,8(sp)
    80004c5e:	e022                	sd	s0,0(sp)
    80004c60:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c62:	00004597          	auipc	a1,0x4
    80004c66:	aa658593          	add	a1,a1,-1370 # 80008708 <syscalls+0x280>
    80004c6a:	00020517          	auipc	a0,0x20
    80004c6e:	e2e50513          	add	a0,a0,-466 # 80024a98 <ftable>
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	ed0080e7          	jalr	-304(ra) # 80000b42 <initlock>
}
    80004c7a:	60a2                	ld	ra,8(sp)
    80004c7c:	6402                	ld	s0,0(sp)
    80004c7e:	0141                	add	sp,sp,16
    80004c80:	8082                	ret

0000000080004c82 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c82:	1101                	add	sp,sp,-32
    80004c84:	ec06                	sd	ra,24(sp)
    80004c86:	e822                	sd	s0,16(sp)
    80004c88:	e426                	sd	s1,8(sp)
    80004c8a:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c8c:	00020517          	auipc	a0,0x20
    80004c90:	e0c50513          	add	a0,a0,-500 # 80024a98 <ftable>
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	f3e080e7          	jalr	-194(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c9c:	00020497          	auipc	s1,0x20
    80004ca0:	e1448493          	add	s1,s1,-492 # 80024ab0 <ftable+0x18>
    80004ca4:	00021717          	auipc	a4,0x21
    80004ca8:	dac70713          	add	a4,a4,-596 # 80025a50 <disk>
    if(f->ref == 0){
    80004cac:	40dc                	lw	a5,4(s1)
    80004cae:	cf99                	beqz	a5,80004ccc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cb0:	02848493          	add	s1,s1,40
    80004cb4:	fee49ce3          	bne	s1,a4,80004cac <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cb8:	00020517          	auipc	a0,0x20
    80004cbc:	de050513          	add	a0,a0,-544 # 80024a98 <ftable>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	fc6080e7          	jalr	-58(ra) # 80000c86 <release>
  return 0;
    80004cc8:	4481                	li	s1,0
    80004cca:	a819                	j	80004ce0 <filealloc+0x5e>
      f->ref = 1;
    80004ccc:	4785                	li	a5,1
    80004cce:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cd0:	00020517          	auipc	a0,0x20
    80004cd4:	dc850513          	add	a0,a0,-568 # 80024a98 <ftable>
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	fae080e7          	jalr	-82(ra) # 80000c86 <release>
}
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	60e2                	ld	ra,24(sp)
    80004ce4:	6442                	ld	s0,16(sp)
    80004ce6:	64a2                	ld	s1,8(sp)
    80004ce8:	6105                	add	sp,sp,32
    80004cea:	8082                	ret

0000000080004cec <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004cec:	1101                	add	sp,sp,-32
    80004cee:	ec06                	sd	ra,24(sp)
    80004cf0:	e822                	sd	s0,16(sp)
    80004cf2:	e426                	sd	s1,8(sp)
    80004cf4:	1000                	add	s0,sp,32
    80004cf6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cf8:	00020517          	auipc	a0,0x20
    80004cfc:	da050513          	add	a0,a0,-608 # 80024a98 <ftable>
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	ed2080e7          	jalr	-302(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004d08:	40dc                	lw	a5,4(s1)
    80004d0a:	02f05263          	blez	a5,80004d2e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d0e:	2785                	addw	a5,a5,1
    80004d10:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d12:	00020517          	auipc	a0,0x20
    80004d16:	d8650513          	add	a0,a0,-634 # 80024a98 <ftable>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	f6c080e7          	jalr	-148(ra) # 80000c86 <release>
  return f;
}
    80004d22:	8526                	mv	a0,s1
    80004d24:	60e2                	ld	ra,24(sp)
    80004d26:	6442                	ld	s0,16(sp)
    80004d28:	64a2                	ld	s1,8(sp)
    80004d2a:	6105                	add	sp,sp,32
    80004d2c:	8082                	ret
    panic("filedup");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	9e250513          	add	a0,a0,-1566 # 80008710 <syscalls+0x288>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	806080e7          	jalr	-2042(ra) # 8000053c <panic>

0000000080004d3e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d3e:	7139                	add	sp,sp,-64
    80004d40:	fc06                	sd	ra,56(sp)
    80004d42:	f822                	sd	s0,48(sp)
    80004d44:	f426                	sd	s1,40(sp)
    80004d46:	f04a                	sd	s2,32(sp)
    80004d48:	ec4e                	sd	s3,24(sp)
    80004d4a:	e852                	sd	s4,16(sp)
    80004d4c:	e456                	sd	s5,8(sp)
    80004d4e:	0080                	add	s0,sp,64
    80004d50:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d52:	00020517          	auipc	a0,0x20
    80004d56:	d4650513          	add	a0,a0,-698 # 80024a98 <ftable>
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	e78080e7          	jalr	-392(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004d62:	40dc                	lw	a5,4(s1)
    80004d64:	06f05163          	blez	a5,80004dc6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d68:	37fd                	addw	a5,a5,-1
    80004d6a:	0007871b          	sext.w	a4,a5
    80004d6e:	c0dc                	sw	a5,4(s1)
    80004d70:	06e04363          	bgtz	a4,80004dd6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d74:	0004a903          	lw	s2,0(s1)
    80004d78:	0094ca83          	lbu	s5,9(s1)
    80004d7c:	0104ba03          	ld	s4,16(s1)
    80004d80:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d84:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d88:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d8c:	00020517          	auipc	a0,0x20
    80004d90:	d0c50513          	add	a0,a0,-756 # 80024a98 <ftable>
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	ef2080e7          	jalr	-270(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004d9c:	4785                	li	a5,1
    80004d9e:	04f90d63          	beq	s2,a5,80004df8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004da2:	3979                	addw	s2,s2,-2
    80004da4:	4785                	li	a5,1
    80004da6:	0527e063          	bltu	a5,s2,80004de6 <fileclose+0xa8>
    begin_op();
    80004daa:	00000097          	auipc	ra,0x0
    80004dae:	ad0080e7          	jalr	-1328(ra) # 8000487a <begin_op>
    iput(ff.ip);
    80004db2:	854e                	mv	a0,s3
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	2da080e7          	jalr	730(ra) # 8000408e <iput>
    end_op();
    80004dbc:	00000097          	auipc	ra,0x0
    80004dc0:	b38080e7          	jalr	-1224(ra) # 800048f4 <end_op>
    80004dc4:	a00d                	j	80004de6 <fileclose+0xa8>
    panic("fileclose");
    80004dc6:	00004517          	auipc	a0,0x4
    80004dca:	95250513          	add	a0,a0,-1710 # 80008718 <syscalls+0x290>
    80004dce:	ffffb097          	auipc	ra,0xffffb
    80004dd2:	76e080e7          	jalr	1902(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004dd6:	00020517          	auipc	a0,0x20
    80004dda:	cc250513          	add	a0,a0,-830 # 80024a98 <ftable>
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	ea8080e7          	jalr	-344(ra) # 80000c86 <release>
  }
}
    80004de6:	70e2                	ld	ra,56(sp)
    80004de8:	7442                	ld	s0,48(sp)
    80004dea:	74a2                	ld	s1,40(sp)
    80004dec:	7902                	ld	s2,32(sp)
    80004dee:	69e2                	ld	s3,24(sp)
    80004df0:	6a42                	ld	s4,16(sp)
    80004df2:	6aa2                	ld	s5,8(sp)
    80004df4:	6121                	add	sp,sp,64
    80004df6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004df8:	85d6                	mv	a1,s5
    80004dfa:	8552                	mv	a0,s4
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	348080e7          	jalr	840(ra) # 80005144 <pipeclose>
    80004e04:	b7cd                	j	80004de6 <fileclose+0xa8>

0000000080004e06 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e06:	715d                	add	sp,sp,-80
    80004e08:	e486                	sd	ra,72(sp)
    80004e0a:	e0a2                	sd	s0,64(sp)
    80004e0c:	fc26                	sd	s1,56(sp)
    80004e0e:	f84a                	sd	s2,48(sp)
    80004e10:	f44e                	sd	s3,40(sp)
    80004e12:	0880                	add	s0,sp,80
    80004e14:	84aa                	mv	s1,a0
    80004e16:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	b8e080e7          	jalr	-1138(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e20:	409c                	lw	a5,0(s1)
    80004e22:	37f9                	addw	a5,a5,-2
    80004e24:	4705                	li	a4,1
    80004e26:	04f76763          	bltu	a4,a5,80004e74 <filestat+0x6e>
    80004e2a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e2c:	6c88                	ld	a0,24(s1)
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	0a6080e7          	jalr	166(ra) # 80003ed4 <ilock>
    stati(f->ip, &st);
    80004e36:	fb840593          	add	a1,s0,-72
    80004e3a:	6c88                	ld	a0,24(s1)
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	322080e7          	jalr	802(ra) # 8000415e <stati>
    iunlock(f->ip);
    80004e44:	6c88                	ld	a0,24(s1)
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	150080e7          	jalr	336(ra) # 80003f96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e4e:	46e1                	li	a3,24
    80004e50:	fb840613          	add	a2,s0,-72
    80004e54:	85ce                	mv	a1,s3
    80004e56:	05093503          	ld	a0,80(s2)
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	80c080e7          	jalr	-2036(ra) # 80001666 <copyout>
    80004e62:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e66:	60a6                	ld	ra,72(sp)
    80004e68:	6406                	ld	s0,64(sp)
    80004e6a:	74e2                	ld	s1,56(sp)
    80004e6c:	7942                	ld	s2,48(sp)
    80004e6e:	79a2                	ld	s3,40(sp)
    80004e70:	6161                	add	sp,sp,80
    80004e72:	8082                	ret
  return -1;
    80004e74:	557d                	li	a0,-1
    80004e76:	bfc5                	j	80004e66 <filestat+0x60>

0000000080004e78 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e78:	7179                	add	sp,sp,-48
    80004e7a:	f406                	sd	ra,40(sp)
    80004e7c:	f022                	sd	s0,32(sp)
    80004e7e:	ec26                	sd	s1,24(sp)
    80004e80:	e84a                	sd	s2,16(sp)
    80004e82:	e44e                	sd	s3,8(sp)
    80004e84:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e86:	00854783          	lbu	a5,8(a0)
    80004e8a:	c3d5                	beqz	a5,80004f2e <fileread+0xb6>
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	89ae                	mv	s3,a1
    80004e90:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e92:	411c                	lw	a5,0(a0)
    80004e94:	4705                	li	a4,1
    80004e96:	04e78963          	beq	a5,a4,80004ee8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e9a:	470d                	li	a4,3
    80004e9c:	04e78d63          	beq	a5,a4,80004ef6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ea0:	4709                	li	a4,2
    80004ea2:	06e79e63          	bne	a5,a4,80004f1e <fileread+0xa6>
    ilock(f->ip);
    80004ea6:	6d08                	ld	a0,24(a0)
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	02c080e7          	jalr	44(ra) # 80003ed4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004eb0:	874a                	mv	a4,s2
    80004eb2:	5094                	lw	a3,32(s1)
    80004eb4:	864e                	mv	a2,s3
    80004eb6:	4585                	li	a1,1
    80004eb8:	6c88                	ld	a0,24(s1)
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	2ce080e7          	jalr	718(ra) # 80004188 <readi>
    80004ec2:	892a                	mv	s2,a0
    80004ec4:	00a05563          	blez	a0,80004ece <fileread+0x56>
      f->off += r;
    80004ec8:	509c                	lw	a5,32(s1)
    80004eca:	9fa9                	addw	a5,a5,a0
    80004ecc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ece:	6c88                	ld	a0,24(s1)
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	0c6080e7          	jalr	198(ra) # 80003f96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ed8:	854a                	mv	a0,s2
    80004eda:	70a2                	ld	ra,40(sp)
    80004edc:	7402                	ld	s0,32(sp)
    80004ede:	64e2                	ld	s1,24(sp)
    80004ee0:	6942                	ld	s2,16(sp)
    80004ee2:	69a2                	ld	s3,8(sp)
    80004ee4:	6145                	add	sp,sp,48
    80004ee6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ee8:	6908                	ld	a0,16(a0)
    80004eea:	00000097          	auipc	ra,0x0
    80004eee:	3c2080e7          	jalr	962(ra) # 800052ac <piperead>
    80004ef2:	892a                	mv	s2,a0
    80004ef4:	b7d5                	j	80004ed8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ef6:	02451783          	lh	a5,36(a0)
    80004efa:	03079693          	sll	a3,a5,0x30
    80004efe:	92c1                	srl	a3,a3,0x30
    80004f00:	4725                	li	a4,9
    80004f02:	02d76863          	bltu	a4,a3,80004f32 <fileread+0xba>
    80004f06:	0792                	sll	a5,a5,0x4
    80004f08:	00020717          	auipc	a4,0x20
    80004f0c:	af070713          	add	a4,a4,-1296 # 800249f8 <devsw>
    80004f10:	97ba                	add	a5,a5,a4
    80004f12:	639c                	ld	a5,0(a5)
    80004f14:	c38d                	beqz	a5,80004f36 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f16:	4505                	li	a0,1
    80004f18:	9782                	jalr	a5
    80004f1a:	892a                	mv	s2,a0
    80004f1c:	bf75                	j	80004ed8 <fileread+0x60>
    panic("fileread");
    80004f1e:	00004517          	auipc	a0,0x4
    80004f22:	80a50513          	add	a0,a0,-2038 # 80008728 <syscalls+0x2a0>
    80004f26:	ffffb097          	auipc	ra,0xffffb
    80004f2a:	616080e7          	jalr	1558(ra) # 8000053c <panic>
    return -1;
    80004f2e:	597d                	li	s2,-1
    80004f30:	b765                	j	80004ed8 <fileread+0x60>
      return -1;
    80004f32:	597d                	li	s2,-1
    80004f34:	b755                	j	80004ed8 <fileread+0x60>
    80004f36:	597d                	li	s2,-1
    80004f38:	b745                	j	80004ed8 <fileread+0x60>

0000000080004f3a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004f3a:	00954783          	lbu	a5,9(a0)
    80004f3e:	10078e63          	beqz	a5,8000505a <filewrite+0x120>
{
    80004f42:	715d                	add	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	f052                	sd	s4,32(sp)
    80004f50:	ec56                	sd	s5,24(sp)
    80004f52:	e85a                	sd	s6,16(sp)
    80004f54:	e45e                	sd	s7,8(sp)
    80004f56:	e062                	sd	s8,0(sp)
    80004f58:	0880                	add	s0,sp,80
    80004f5a:	892a                	mv	s2,a0
    80004f5c:	8b2e                	mv	s6,a1
    80004f5e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f60:	411c                	lw	a5,0(a0)
    80004f62:	4705                	li	a4,1
    80004f64:	02e78263          	beq	a5,a4,80004f88 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f68:	470d                	li	a4,3
    80004f6a:	02e78563          	beq	a5,a4,80004f94 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f6e:	4709                	li	a4,2
    80004f70:	0ce79d63          	bne	a5,a4,8000504a <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f74:	0ac05b63          	blez	a2,8000502a <filewrite+0xf0>
    int i = 0;
    80004f78:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004f7a:	6b85                	lui	s7,0x1
    80004f7c:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004f80:	6c05                	lui	s8,0x1
    80004f82:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004f86:	a851                	j	8000501a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004f88:	6908                	ld	a0,16(a0)
    80004f8a:	00000097          	auipc	ra,0x0
    80004f8e:	22a080e7          	jalr	554(ra) # 800051b4 <pipewrite>
    80004f92:	a045                	j	80005032 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f94:	02451783          	lh	a5,36(a0)
    80004f98:	03079693          	sll	a3,a5,0x30
    80004f9c:	92c1                	srl	a3,a3,0x30
    80004f9e:	4725                	li	a4,9
    80004fa0:	0ad76f63          	bltu	a4,a3,8000505e <filewrite+0x124>
    80004fa4:	0792                	sll	a5,a5,0x4
    80004fa6:	00020717          	auipc	a4,0x20
    80004faa:	a5270713          	add	a4,a4,-1454 # 800249f8 <devsw>
    80004fae:	97ba                	add	a5,a5,a4
    80004fb0:	679c                	ld	a5,8(a5)
    80004fb2:	cbc5                	beqz	a5,80005062 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004fb4:	4505                	li	a0,1
    80004fb6:	9782                	jalr	a5
    80004fb8:	a8ad                	j	80005032 <filewrite+0xf8>
      if(n1 > max)
    80004fba:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004fbe:	00000097          	auipc	ra,0x0
    80004fc2:	8bc080e7          	jalr	-1860(ra) # 8000487a <begin_op>
      ilock(f->ip);
    80004fc6:	01893503          	ld	a0,24(s2)
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	f0a080e7          	jalr	-246(ra) # 80003ed4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fd2:	8756                	mv	a4,s5
    80004fd4:	02092683          	lw	a3,32(s2)
    80004fd8:	01698633          	add	a2,s3,s6
    80004fdc:	4585                	li	a1,1
    80004fde:	01893503          	ld	a0,24(s2)
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	29e080e7          	jalr	670(ra) # 80004280 <writei>
    80004fea:	84aa                	mv	s1,a0
    80004fec:	00a05763          	blez	a0,80004ffa <filewrite+0xc0>
        f->off += r;
    80004ff0:	02092783          	lw	a5,32(s2)
    80004ff4:	9fa9                	addw	a5,a5,a0
    80004ff6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ffa:	01893503          	ld	a0,24(s2)
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	f98080e7          	jalr	-104(ra) # 80003f96 <iunlock>
      end_op();
    80005006:	00000097          	auipc	ra,0x0
    8000500a:	8ee080e7          	jalr	-1810(ra) # 800048f4 <end_op>

      if(r != n1){
    8000500e:	009a9f63          	bne	s5,s1,8000502c <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80005012:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005016:	0149db63          	bge	s3,s4,8000502c <filewrite+0xf2>
      int n1 = n - i;
    8000501a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000501e:	0004879b          	sext.w	a5,s1
    80005022:	f8fbdce3          	bge	s7,a5,80004fba <filewrite+0x80>
    80005026:	84e2                	mv	s1,s8
    80005028:	bf49                	j	80004fba <filewrite+0x80>
    int i = 0;
    8000502a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000502c:	033a1d63          	bne	s4,s3,80005066 <filewrite+0x12c>
    80005030:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005032:	60a6                	ld	ra,72(sp)
    80005034:	6406                	ld	s0,64(sp)
    80005036:	74e2                	ld	s1,56(sp)
    80005038:	7942                	ld	s2,48(sp)
    8000503a:	79a2                	ld	s3,40(sp)
    8000503c:	7a02                	ld	s4,32(sp)
    8000503e:	6ae2                	ld	s5,24(sp)
    80005040:	6b42                	ld	s6,16(sp)
    80005042:	6ba2                	ld	s7,8(sp)
    80005044:	6c02                	ld	s8,0(sp)
    80005046:	6161                	add	sp,sp,80
    80005048:	8082                	ret
    panic("filewrite");
    8000504a:	00003517          	auipc	a0,0x3
    8000504e:	6ee50513          	add	a0,a0,1774 # 80008738 <syscalls+0x2b0>
    80005052:	ffffb097          	auipc	ra,0xffffb
    80005056:	4ea080e7          	jalr	1258(ra) # 8000053c <panic>
    return -1;
    8000505a:	557d                	li	a0,-1
}
    8000505c:	8082                	ret
      return -1;
    8000505e:	557d                	li	a0,-1
    80005060:	bfc9                	j	80005032 <filewrite+0xf8>
    80005062:	557d                	li	a0,-1
    80005064:	b7f9                	j	80005032 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80005066:	557d                	li	a0,-1
    80005068:	b7e9                	j	80005032 <filewrite+0xf8>

000000008000506a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000506a:	7179                	add	sp,sp,-48
    8000506c:	f406                	sd	ra,40(sp)
    8000506e:	f022                	sd	s0,32(sp)
    80005070:	ec26                	sd	s1,24(sp)
    80005072:	e84a                	sd	s2,16(sp)
    80005074:	e44e                	sd	s3,8(sp)
    80005076:	e052                	sd	s4,0(sp)
    80005078:	1800                	add	s0,sp,48
    8000507a:	84aa                	mv	s1,a0
    8000507c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000507e:	0005b023          	sd	zero,0(a1)
    80005082:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005086:	00000097          	auipc	ra,0x0
    8000508a:	bfc080e7          	jalr	-1028(ra) # 80004c82 <filealloc>
    8000508e:	e088                	sd	a0,0(s1)
    80005090:	c551                	beqz	a0,8000511c <pipealloc+0xb2>
    80005092:	00000097          	auipc	ra,0x0
    80005096:	bf0080e7          	jalr	-1040(ra) # 80004c82 <filealloc>
    8000509a:	00aa3023          	sd	a0,0(s4)
    8000509e:	c92d                	beqz	a0,80005110 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	a42080e7          	jalr	-1470(ra) # 80000ae2 <kalloc>
    800050a8:	892a                	mv	s2,a0
    800050aa:	c125                	beqz	a0,8000510a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050ac:	4985                	li	s3,1
    800050ae:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050b2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050b6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050ba:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050be:	00003597          	auipc	a1,0x3
    800050c2:	68a58593          	add	a1,a1,1674 # 80008748 <syscalls+0x2c0>
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	a7c080e7          	jalr	-1412(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    800050ce:	609c                	ld	a5,0(s1)
    800050d0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050d4:	609c                	ld	a5,0(s1)
    800050d6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050da:	609c                	ld	a5,0(s1)
    800050dc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050e0:	609c                	ld	a5,0(s1)
    800050e2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050e6:	000a3783          	ld	a5,0(s4)
    800050ea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050ee:	000a3783          	ld	a5,0(s4)
    800050f2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050f6:	000a3783          	ld	a5,0(s4)
    800050fa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050fe:	000a3783          	ld	a5,0(s4)
    80005102:	0127b823          	sd	s2,16(a5)
  return 0;
    80005106:	4501                	li	a0,0
    80005108:	a025                	j	80005130 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000510a:	6088                	ld	a0,0(s1)
    8000510c:	e501                	bnez	a0,80005114 <pipealloc+0xaa>
    8000510e:	a039                	j	8000511c <pipealloc+0xb2>
    80005110:	6088                	ld	a0,0(s1)
    80005112:	c51d                	beqz	a0,80005140 <pipealloc+0xd6>
    fileclose(*f0);
    80005114:	00000097          	auipc	ra,0x0
    80005118:	c2a080e7          	jalr	-982(ra) # 80004d3e <fileclose>
  if(*f1)
    8000511c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005120:	557d                	li	a0,-1
  if(*f1)
    80005122:	c799                	beqz	a5,80005130 <pipealloc+0xc6>
    fileclose(*f1);
    80005124:	853e                	mv	a0,a5
    80005126:	00000097          	auipc	ra,0x0
    8000512a:	c18080e7          	jalr	-1000(ra) # 80004d3e <fileclose>
  return -1;
    8000512e:	557d                	li	a0,-1
}
    80005130:	70a2                	ld	ra,40(sp)
    80005132:	7402                	ld	s0,32(sp)
    80005134:	64e2                	ld	s1,24(sp)
    80005136:	6942                	ld	s2,16(sp)
    80005138:	69a2                	ld	s3,8(sp)
    8000513a:	6a02                	ld	s4,0(sp)
    8000513c:	6145                	add	sp,sp,48
    8000513e:	8082                	ret
  return -1;
    80005140:	557d                	li	a0,-1
    80005142:	b7fd                	j	80005130 <pipealloc+0xc6>

0000000080005144 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005144:	1101                	add	sp,sp,-32
    80005146:	ec06                	sd	ra,24(sp)
    80005148:	e822                	sd	s0,16(sp)
    8000514a:	e426                	sd	s1,8(sp)
    8000514c:	e04a                	sd	s2,0(sp)
    8000514e:	1000                	add	s0,sp,32
    80005150:	84aa                	mv	s1,a0
    80005152:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	a7e080e7          	jalr	-1410(ra) # 80000bd2 <acquire>
  if(writable){
    8000515c:	02090d63          	beqz	s2,80005196 <pipeclose+0x52>
    pi->writeopen = 0;
    80005160:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005164:	21848513          	add	a0,s1,536
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	3e0080e7          	jalr	992(ra) # 80002548 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005170:	2204b783          	ld	a5,544(s1)
    80005174:	eb95                	bnez	a5,800051a8 <pipeclose+0x64>
    release(&pi->lock);
    80005176:	8526                	mv	a0,s1
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	b0e080e7          	jalr	-1266(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	862080e7          	jalr	-1950(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    8000518a:	60e2                	ld	ra,24(sp)
    8000518c:	6442                	ld	s0,16(sp)
    8000518e:	64a2                	ld	s1,8(sp)
    80005190:	6902                	ld	s2,0(sp)
    80005192:	6105                	add	sp,sp,32
    80005194:	8082                	ret
    pi->readopen = 0;
    80005196:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000519a:	21c48513          	add	a0,s1,540
    8000519e:	ffffd097          	auipc	ra,0xffffd
    800051a2:	3aa080e7          	jalr	938(ra) # 80002548 <wakeup>
    800051a6:	b7e9                	j	80005170 <pipeclose+0x2c>
    release(&pi->lock);
    800051a8:	8526                	mv	a0,s1
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	adc080e7          	jalr	-1316(ra) # 80000c86 <release>
}
    800051b2:	bfe1                	j	8000518a <pipeclose+0x46>

00000000800051b4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051b4:	711d                	add	sp,sp,-96
    800051b6:	ec86                	sd	ra,88(sp)
    800051b8:	e8a2                	sd	s0,80(sp)
    800051ba:	e4a6                	sd	s1,72(sp)
    800051bc:	e0ca                	sd	s2,64(sp)
    800051be:	fc4e                	sd	s3,56(sp)
    800051c0:	f852                	sd	s4,48(sp)
    800051c2:	f456                	sd	s5,40(sp)
    800051c4:	f05a                	sd	s6,32(sp)
    800051c6:	ec5e                	sd	s7,24(sp)
    800051c8:	e862                	sd	s8,16(sp)
    800051ca:	1080                	add	s0,sp,96
    800051cc:	84aa                	mv	s1,a0
    800051ce:	8aae                	mv	s5,a1
    800051d0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	7d4080e7          	jalr	2004(ra) # 800019a6 <myproc>
    800051da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051dc:	8526                	mv	a0,s1
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	9f4080e7          	jalr	-1548(ra) # 80000bd2 <acquire>
  while(i < n){
    800051e6:	0b405663          	blez	s4,80005292 <pipewrite+0xde>
  int i = 0;
    800051ea:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ec:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051ee:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051f2:	21c48b93          	add	s7,s1,540
    800051f6:	a089                	j	80005238 <pipewrite+0x84>
      release(&pi->lock);
    800051f8:	8526                	mv	a0,s1
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	a8c080e7          	jalr	-1396(ra) # 80000c86 <release>
      return -1;
    80005202:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005204:	854a                	mv	a0,s2
    80005206:	60e6                	ld	ra,88(sp)
    80005208:	6446                	ld	s0,80(sp)
    8000520a:	64a6                	ld	s1,72(sp)
    8000520c:	6906                	ld	s2,64(sp)
    8000520e:	79e2                	ld	s3,56(sp)
    80005210:	7a42                	ld	s4,48(sp)
    80005212:	7aa2                	ld	s5,40(sp)
    80005214:	7b02                	ld	s6,32(sp)
    80005216:	6be2                	ld	s7,24(sp)
    80005218:	6c42                	ld	s8,16(sp)
    8000521a:	6125                	add	sp,sp,96
    8000521c:	8082                	ret
      wakeup(&pi->nread);
    8000521e:	8562                	mv	a0,s8
    80005220:	ffffd097          	auipc	ra,0xffffd
    80005224:	328080e7          	jalr	808(ra) # 80002548 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005228:	85a6                	mv	a1,s1
    8000522a:	855e                	mv	a0,s7
    8000522c:	ffffd097          	auipc	ra,0xffffd
    80005230:	2b8080e7          	jalr	696(ra) # 800024e4 <sleep>
  while(i < n){
    80005234:	07495063          	bge	s2,s4,80005294 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005238:	2204a783          	lw	a5,544(s1)
    8000523c:	dfd5                	beqz	a5,800051f8 <pipewrite+0x44>
    8000523e:	854e                	mv	a0,s3
    80005240:	ffffd097          	auipc	ra,0xffffd
    80005244:	558080e7          	jalr	1368(ra) # 80002798 <killed>
    80005248:	f945                	bnez	a0,800051f8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000524a:	2184a783          	lw	a5,536(s1)
    8000524e:	21c4a703          	lw	a4,540(s1)
    80005252:	2007879b          	addw	a5,a5,512
    80005256:	fcf704e3          	beq	a4,a5,8000521e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000525a:	4685                	li	a3,1
    8000525c:	01590633          	add	a2,s2,s5
    80005260:	faf40593          	add	a1,s0,-81
    80005264:	0509b503          	ld	a0,80(s3)
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	48a080e7          	jalr	1162(ra) # 800016f2 <copyin>
    80005270:	03650263          	beq	a0,s6,80005294 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005274:	21c4a783          	lw	a5,540(s1)
    80005278:	0017871b          	addw	a4,a5,1
    8000527c:	20e4ae23          	sw	a4,540(s1)
    80005280:	1ff7f793          	and	a5,a5,511
    80005284:	97a6                	add	a5,a5,s1
    80005286:	faf44703          	lbu	a4,-81(s0)
    8000528a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000528e:	2905                	addw	s2,s2,1
    80005290:	b755                	j	80005234 <pipewrite+0x80>
  int i = 0;
    80005292:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005294:	21848513          	add	a0,s1,536
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	2b0080e7          	jalr	688(ra) # 80002548 <wakeup>
  release(&pi->lock);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	9e4080e7          	jalr	-1564(ra) # 80000c86 <release>
  return i;
    800052aa:	bfa9                	j	80005204 <pipewrite+0x50>

00000000800052ac <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052ac:	715d                	add	sp,sp,-80
    800052ae:	e486                	sd	ra,72(sp)
    800052b0:	e0a2                	sd	s0,64(sp)
    800052b2:	fc26                	sd	s1,56(sp)
    800052b4:	f84a                	sd	s2,48(sp)
    800052b6:	f44e                	sd	s3,40(sp)
    800052b8:	f052                	sd	s4,32(sp)
    800052ba:	ec56                	sd	s5,24(sp)
    800052bc:	e85a                	sd	s6,16(sp)
    800052be:	0880                	add	s0,sp,80
    800052c0:	84aa                	mv	s1,a0
    800052c2:	892e                	mv	s2,a1
    800052c4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	6e0080e7          	jalr	1760(ra) # 800019a6 <myproc>
    800052ce:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	900080e7          	jalr	-1792(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052da:	2184a703          	lw	a4,536(s1)
    800052de:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052e2:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052e6:	02f71763          	bne	a4,a5,80005314 <piperead+0x68>
    800052ea:	2244a783          	lw	a5,548(s1)
    800052ee:	c39d                	beqz	a5,80005314 <piperead+0x68>
    if(killed(pr)){
    800052f0:	8552                	mv	a0,s4
    800052f2:	ffffd097          	auipc	ra,0xffffd
    800052f6:	4a6080e7          	jalr	1190(ra) # 80002798 <killed>
    800052fa:	e949                	bnez	a0,8000538c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052fc:	85a6                	mv	a1,s1
    800052fe:	854e                	mv	a0,s3
    80005300:	ffffd097          	auipc	ra,0xffffd
    80005304:	1e4080e7          	jalr	484(ra) # 800024e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005308:	2184a703          	lw	a4,536(s1)
    8000530c:	21c4a783          	lw	a5,540(s1)
    80005310:	fcf70de3          	beq	a4,a5,800052ea <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005314:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005316:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005318:	05505463          	blez	s5,80005360 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000531c:	2184a783          	lw	a5,536(s1)
    80005320:	21c4a703          	lw	a4,540(s1)
    80005324:	02f70e63          	beq	a4,a5,80005360 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005328:	0017871b          	addw	a4,a5,1
    8000532c:	20e4ac23          	sw	a4,536(s1)
    80005330:	1ff7f793          	and	a5,a5,511
    80005334:	97a6                	add	a5,a5,s1
    80005336:	0187c783          	lbu	a5,24(a5)
    8000533a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000533e:	4685                	li	a3,1
    80005340:	fbf40613          	add	a2,s0,-65
    80005344:	85ca                	mv	a1,s2
    80005346:	050a3503          	ld	a0,80(s4)
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	31c080e7          	jalr	796(ra) # 80001666 <copyout>
    80005352:	01650763          	beq	a0,s6,80005360 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005356:	2985                	addw	s3,s3,1
    80005358:	0905                	add	s2,s2,1
    8000535a:	fd3a91e3          	bne	s5,s3,8000531c <piperead+0x70>
    8000535e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005360:	21c48513          	add	a0,s1,540
    80005364:	ffffd097          	auipc	ra,0xffffd
    80005368:	1e4080e7          	jalr	484(ra) # 80002548 <wakeup>
  release(&pi->lock);
    8000536c:	8526                	mv	a0,s1
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	918080e7          	jalr	-1768(ra) # 80000c86 <release>
  return i;
}
    80005376:	854e                	mv	a0,s3
    80005378:	60a6                	ld	ra,72(sp)
    8000537a:	6406                	ld	s0,64(sp)
    8000537c:	74e2                	ld	s1,56(sp)
    8000537e:	7942                	ld	s2,48(sp)
    80005380:	79a2                	ld	s3,40(sp)
    80005382:	7a02                	ld	s4,32(sp)
    80005384:	6ae2                	ld	s5,24(sp)
    80005386:	6b42                	ld	s6,16(sp)
    80005388:	6161                	add	sp,sp,80
    8000538a:	8082                	ret
      release(&pi->lock);
    8000538c:	8526                	mv	a0,s1
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	8f8080e7          	jalr	-1800(ra) # 80000c86 <release>
      return -1;
    80005396:	59fd                	li	s3,-1
    80005398:	bff9                	j	80005376 <piperead+0xca>

000000008000539a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000539a:	1141                	add	sp,sp,-16
    8000539c:	e422                	sd	s0,8(sp)
    8000539e:	0800                	add	s0,sp,16
    800053a0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800053a2:	8905                	and	a0,a0,1
    800053a4:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800053a6:	8b89                	and	a5,a5,2
    800053a8:	c399                	beqz	a5,800053ae <flags2perm+0x14>
      perm |= PTE_W;
    800053aa:	00456513          	or	a0,a0,4
    return perm;
}
    800053ae:	6422                	ld	s0,8(sp)
    800053b0:	0141                	add	sp,sp,16
    800053b2:	8082                	ret

00000000800053b4 <exec>:

int
exec(char *path, char **argv)
{
    800053b4:	df010113          	add	sp,sp,-528
    800053b8:	20113423          	sd	ra,520(sp)
    800053bc:	20813023          	sd	s0,512(sp)
    800053c0:	ffa6                	sd	s1,504(sp)
    800053c2:	fbca                	sd	s2,496(sp)
    800053c4:	f7ce                	sd	s3,488(sp)
    800053c6:	f3d2                	sd	s4,480(sp)
    800053c8:	efd6                	sd	s5,472(sp)
    800053ca:	ebda                	sd	s6,464(sp)
    800053cc:	e7de                	sd	s7,456(sp)
    800053ce:	e3e2                	sd	s8,448(sp)
    800053d0:	ff66                	sd	s9,440(sp)
    800053d2:	fb6a                	sd	s10,432(sp)
    800053d4:	f76e                	sd	s11,424(sp)
    800053d6:	0c00                	add	s0,sp,528
    800053d8:	892a                	mv	s2,a0
    800053da:	dea43c23          	sd	a0,-520(s0)
    800053de:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	5c4080e7          	jalr	1476(ra) # 800019a6 <myproc>
    800053ea:	84aa                	mv	s1,a0

  begin_op();
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	48e080e7          	jalr	1166(ra) # 8000487a <begin_op>

  if((ip = namei(path)) == 0){
    800053f4:	854a                	mv	a0,s2
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	284080e7          	jalr	644(ra) # 8000467a <namei>
    800053fe:	c92d                	beqz	a0,80005470 <exec+0xbc>
    80005400:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	ad2080e7          	jalr	-1326(ra) # 80003ed4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000540a:	04000713          	li	a4,64
    8000540e:	4681                	li	a3,0
    80005410:	e5040613          	add	a2,s0,-432
    80005414:	4581                	li	a1,0
    80005416:	8552                	mv	a0,s4
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	d70080e7          	jalr	-656(ra) # 80004188 <readi>
    80005420:	04000793          	li	a5,64
    80005424:	00f51a63          	bne	a0,a5,80005438 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005428:	e5042703          	lw	a4,-432(s0)
    8000542c:	464c47b7          	lui	a5,0x464c4
    80005430:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005434:	04f70463          	beq	a4,a5,8000547c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005438:	8552                	mv	a0,s4
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	cfc080e7          	jalr	-772(ra) # 80004136 <iunlockput>
    end_op();
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	4b2080e7          	jalr	1202(ra) # 800048f4 <end_op>
  }
  return -1;
    8000544a:	557d                	li	a0,-1
}
    8000544c:	20813083          	ld	ra,520(sp)
    80005450:	20013403          	ld	s0,512(sp)
    80005454:	74fe                	ld	s1,504(sp)
    80005456:	795e                	ld	s2,496(sp)
    80005458:	79be                	ld	s3,488(sp)
    8000545a:	7a1e                	ld	s4,480(sp)
    8000545c:	6afe                	ld	s5,472(sp)
    8000545e:	6b5e                	ld	s6,464(sp)
    80005460:	6bbe                	ld	s7,456(sp)
    80005462:	6c1e                	ld	s8,448(sp)
    80005464:	7cfa                	ld	s9,440(sp)
    80005466:	7d5a                	ld	s10,432(sp)
    80005468:	7dba                	ld	s11,424(sp)
    8000546a:	21010113          	add	sp,sp,528
    8000546e:	8082                	ret
    end_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	484080e7          	jalr	1156(ra) # 800048f4 <end_op>
    return -1;
    80005478:	557d                	li	a0,-1
    8000547a:	bfc9                	j	8000544c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	5ec080e7          	jalr	1516(ra) # 80001a6a <proc_pagetable>
    80005486:	8b2a                	mv	s6,a0
    80005488:	d945                	beqz	a0,80005438 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000548a:	e7042d03          	lw	s10,-400(s0)
    8000548e:	e8845783          	lhu	a5,-376(s0)
    80005492:	10078463          	beqz	a5,8000559a <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005496:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005498:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000549a:	6c85                	lui	s9,0x1
    8000549c:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    800054a0:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800054a4:	6a85                	lui	s5,0x1
    800054a6:	a0b5                	j	80005512 <exec+0x15e>
      panic("loadseg: address should exist");
    800054a8:	00003517          	auipc	a0,0x3
    800054ac:	2a850513          	add	a0,a0,680 # 80008750 <syscalls+0x2c8>
    800054b0:	ffffb097          	auipc	ra,0xffffb
    800054b4:	08c080e7          	jalr	140(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800054b8:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054ba:	8726                	mv	a4,s1
    800054bc:	012c06bb          	addw	a3,s8,s2
    800054c0:	4581                	li	a1,0
    800054c2:	8552                	mv	a0,s4
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	cc4080e7          	jalr	-828(ra) # 80004188 <readi>
    800054cc:	2501                	sext.w	a0,a0
    800054ce:	24a49863          	bne	s1,a0,8000571e <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800054d2:	012a893b          	addw	s2,s5,s2
    800054d6:	03397563          	bgeu	s2,s3,80005500 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800054da:	02091593          	sll	a1,s2,0x20
    800054de:	9181                	srl	a1,a1,0x20
    800054e0:	95de                	add	a1,a1,s7
    800054e2:	855a                	mv	a0,s6
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	b72080e7          	jalr	-1166(ra) # 80001056 <walkaddr>
    800054ec:	862a                	mv	a2,a0
    if(pa == 0)
    800054ee:	dd4d                	beqz	a0,800054a8 <exec+0xf4>
    if(sz - i < PGSIZE)
    800054f0:	412984bb          	subw	s1,s3,s2
    800054f4:	0004879b          	sext.w	a5,s1
    800054f8:	fcfcf0e3          	bgeu	s9,a5,800054b8 <exec+0x104>
    800054fc:	84d6                	mv	s1,s5
    800054fe:	bf6d                	j	800054b8 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005500:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005504:	2d85                	addw	s11,s11,1
    80005506:	038d0d1b          	addw	s10,s10,56
    8000550a:	e8845783          	lhu	a5,-376(s0)
    8000550e:	08fdd763          	bge	s11,a5,8000559c <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005512:	2d01                	sext.w	s10,s10
    80005514:	03800713          	li	a4,56
    80005518:	86ea                	mv	a3,s10
    8000551a:	e1840613          	add	a2,s0,-488
    8000551e:	4581                	li	a1,0
    80005520:	8552                	mv	a0,s4
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	c66080e7          	jalr	-922(ra) # 80004188 <readi>
    8000552a:	03800793          	li	a5,56
    8000552e:	1ef51663          	bne	a0,a5,8000571a <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005532:	e1842783          	lw	a5,-488(s0)
    80005536:	4705                	li	a4,1
    80005538:	fce796e3          	bne	a5,a4,80005504 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000553c:	e4043483          	ld	s1,-448(s0)
    80005540:	e3843783          	ld	a5,-456(s0)
    80005544:	1ef4e863          	bltu	s1,a5,80005734 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005548:	e2843783          	ld	a5,-472(s0)
    8000554c:	94be                	add	s1,s1,a5
    8000554e:	1ef4e663          	bltu	s1,a5,8000573a <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005552:	df043703          	ld	a4,-528(s0)
    80005556:	8ff9                	and	a5,a5,a4
    80005558:	1e079463          	bnez	a5,80005740 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000555c:	e1c42503          	lw	a0,-484(s0)
    80005560:	00000097          	auipc	ra,0x0
    80005564:	e3a080e7          	jalr	-454(ra) # 8000539a <flags2perm>
    80005568:	86aa                	mv	a3,a0
    8000556a:	8626                	mv	a2,s1
    8000556c:	85ca                	mv	a1,s2
    8000556e:	855a                	mv	a0,s6
    80005570:	ffffc097          	auipc	ra,0xffffc
    80005574:	e9a080e7          	jalr	-358(ra) # 8000140a <uvmalloc>
    80005578:	e0a43423          	sd	a0,-504(s0)
    8000557c:	1c050563          	beqz	a0,80005746 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005580:	e2843b83          	ld	s7,-472(s0)
    80005584:	e2042c03          	lw	s8,-480(s0)
    80005588:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000558c:	00098463          	beqz	s3,80005594 <exec+0x1e0>
    80005590:	4901                	li	s2,0
    80005592:	b7a1                	j	800054da <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005594:	e0843903          	ld	s2,-504(s0)
    80005598:	b7b5                	j	80005504 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000559a:	4901                	li	s2,0
  iunlockput(ip);
    8000559c:	8552                	mv	a0,s4
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	b98080e7          	jalr	-1128(ra) # 80004136 <iunlockput>
  end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	34e080e7          	jalr	846(ra) # 800048f4 <end_op>
  p = myproc();
    800055ae:	ffffc097          	auipc	ra,0xffffc
    800055b2:	3f8080e7          	jalr	1016(ra) # 800019a6 <myproc>
    800055b6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800055b8:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800055bc:	6985                	lui	s3,0x1
    800055be:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    800055c0:	99ca                	add	s3,s3,s2
    800055c2:	77fd                	lui	a5,0xfffff
    800055c4:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800055c8:	4691                	li	a3,4
    800055ca:	6609                	lui	a2,0x2
    800055cc:	964e                	add	a2,a2,s3
    800055ce:	85ce                	mv	a1,s3
    800055d0:	855a                	mv	a0,s6
    800055d2:	ffffc097          	auipc	ra,0xffffc
    800055d6:	e38080e7          	jalr	-456(ra) # 8000140a <uvmalloc>
    800055da:	892a                	mv	s2,a0
    800055dc:	e0a43423          	sd	a0,-504(s0)
    800055e0:	e509                	bnez	a0,800055ea <exec+0x236>
  if(pagetable)
    800055e2:	e1343423          	sd	s3,-504(s0)
    800055e6:	4a01                	li	s4,0
    800055e8:	aa1d                	j	8000571e <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055ea:	75f9                	lui	a1,0xffffe
    800055ec:	95aa                	add	a1,a1,a0
    800055ee:	855a                	mv	a0,s6
    800055f0:	ffffc097          	auipc	ra,0xffffc
    800055f4:	044080e7          	jalr	68(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800055f8:	7bfd                	lui	s7,0xfffff
    800055fa:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800055fc:	e0043783          	ld	a5,-512(s0)
    80005600:	6388                	ld	a0,0(a5)
    80005602:	c52d                	beqz	a0,8000566c <exec+0x2b8>
    80005604:	e9040993          	add	s3,s0,-368
    80005608:	f9040c13          	add	s8,s0,-112
    8000560c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	83a080e7          	jalr	-1990(ra) # 80000e48 <strlen>
    80005616:	0015079b          	addw	a5,a0,1
    8000561a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000561e:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005622:	13796563          	bltu	s2,s7,8000574c <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005626:	e0043d03          	ld	s10,-512(s0)
    8000562a:	000d3a03          	ld	s4,0(s10)
    8000562e:	8552                	mv	a0,s4
    80005630:	ffffc097          	auipc	ra,0xffffc
    80005634:	818080e7          	jalr	-2024(ra) # 80000e48 <strlen>
    80005638:	0015069b          	addw	a3,a0,1
    8000563c:	8652                	mv	a2,s4
    8000563e:	85ca                	mv	a1,s2
    80005640:	855a                	mv	a0,s6
    80005642:	ffffc097          	auipc	ra,0xffffc
    80005646:	024080e7          	jalr	36(ra) # 80001666 <copyout>
    8000564a:	10054363          	bltz	a0,80005750 <exec+0x39c>
    ustack[argc] = sp;
    8000564e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005652:	0485                	add	s1,s1,1
    80005654:	008d0793          	add	a5,s10,8
    80005658:	e0f43023          	sd	a5,-512(s0)
    8000565c:	008d3503          	ld	a0,8(s10)
    80005660:	c909                	beqz	a0,80005672 <exec+0x2be>
    if(argc >= MAXARG)
    80005662:	09a1                	add	s3,s3,8
    80005664:	fb8995e3          	bne	s3,s8,8000560e <exec+0x25a>
  ip = 0;
    80005668:	4a01                	li	s4,0
    8000566a:	a855                	j	8000571e <exec+0x36a>
  sp = sz;
    8000566c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005670:	4481                	li	s1,0
  ustack[argc] = 0;
    80005672:	00349793          	sll	a5,s1,0x3
    80005676:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd9400>
    8000567a:	97a2                	add	a5,a5,s0
    8000567c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005680:	00148693          	add	a3,s1,1
    80005684:	068e                	sll	a3,a3,0x3
    80005686:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000568a:	ff097913          	and	s2,s2,-16
  sz = sz1;
    8000568e:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005692:	f57968e3          	bltu	s2,s7,800055e2 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005696:	e9040613          	add	a2,s0,-368
    8000569a:	85ca                	mv	a1,s2
    8000569c:	855a                	mv	a0,s6
    8000569e:	ffffc097          	auipc	ra,0xffffc
    800056a2:	fc8080e7          	jalr	-56(ra) # 80001666 <copyout>
    800056a6:	0a054763          	bltz	a0,80005754 <exec+0x3a0>
  p->trapframe->a1 = sp;
    800056aa:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800056ae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800056b2:	df843783          	ld	a5,-520(s0)
    800056b6:	0007c703          	lbu	a4,0(a5)
    800056ba:	cf11                	beqz	a4,800056d6 <exec+0x322>
    800056bc:	0785                	add	a5,a5,1
    if(*s == '/')
    800056be:	02f00693          	li	a3,47
    800056c2:	a039                	j	800056d0 <exec+0x31c>
      last = s+1;
    800056c4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800056c8:	0785                	add	a5,a5,1
    800056ca:	fff7c703          	lbu	a4,-1(a5)
    800056ce:	c701                	beqz	a4,800056d6 <exec+0x322>
    if(*s == '/')
    800056d0:	fed71ce3          	bne	a4,a3,800056c8 <exec+0x314>
    800056d4:	bfc5                	j	800056c4 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800056d6:	4641                	li	a2,16
    800056d8:	df843583          	ld	a1,-520(s0)
    800056dc:	158a8513          	add	a0,s5,344
    800056e0:	ffffb097          	auipc	ra,0xffffb
    800056e4:	736080e7          	jalr	1846(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800056e8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800056ec:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800056f0:	e0843783          	ld	a5,-504(s0)
    800056f4:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056f8:	058ab783          	ld	a5,88(s5)
    800056fc:	e6843703          	ld	a4,-408(s0)
    80005700:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005702:	058ab783          	ld	a5,88(s5)
    80005706:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000570a:	85e6                	mv	a1,s9
    8000570c:	ffffc097          	auipc	ra,0xffffc
    80005710:	3fa080e7          	jalr	1018(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005714:	0004851b          	sext.w	a0,s1
    80005718:	bb15                	j	8000544c <exec+0x98>
    8000571a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000571e:	e0843583          	ld	a1,-504(s0)
    80005722:	855a                	mv	a0,s6
    80005724:	ffffc097          	auipc	ra,0xffffc
    80005728:	3e2080e7          	jalr	994(ra) # 80001b06 <proc_freepagetable>
  return -1;
    8000572c:	557d                	li	a0,-1
  if(ip){
    8000572e:	d00a0fe3          	beqz	s4,8000544c <exec+0x98>
    80005732:	b319                	j	80005438 <exec+0x84>
    80005734:	e1243423          	sd	s2,-504(s0)
    80005738:	b7dd                	j	8000571e <exec+0x36a>
    8000573a:	e1243423          	sd	s2,-504(s0)
    8000573e:	b7c5                	j	8000571e <exec+0x36a>
    80005740:	e1243423          	sd	s2,-504(s0)
    80005744:	bfe9                	j	8000571e <exec+0x36a>
    80005746:	e1243423          	sd	s2,-504(s0)
    8000574a:	bfd1                	j	8000571e <exec+0x36a>
  ip = 0;
    8000574c:	4a01                	li	s4,0
    8000574e:	bfc1                	j	8000571e <exec+0x36a>
    80005750:	4a01                	li	s4,0
  if(pagetable)
    80005752:	b7f1                	j	8000571e <exec+0x36a>
  sz = sz1;
    80005754:	e0843983          	ld	s3,-504(s0)
    80005758:	b569                	j	800055e2 <exec+0x22e>

000000008000575a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000575a:	7179                	add	sp,sp,-48
    8000575c:	f406                	sd	ra,40(sp)
    8000575e:	f022                	sd	s0,32(sp)
    80005760:	ec26                	sd	s1,24(sp)
    80005762:	e84a                	sd	s2,16(sp)
    80005764:	1800                	add	s0,sp,48
    80005766:	892e                	mv	s2,a1
    80005768:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000576a:	fdc40593          	add	a1,s0,-36
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	a16080e7          	jalr	-1514(ra) # 80003184 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005776:	fdc42703          	lw	a4,-36(s0)
    8000577a:	47bd                	li	a5,15
    8000577c:	02e7eb63          	bltu	a5,a4,800057b2 <argfd+0x58>
    80005780:	ffffc097          	auipc	ra,0xffffc
    80005784:	226080e7          	jalr	550(ra) # 800019a6 <myproc>
    80005788:	fdc42703          	lw	a4,-36(s0)
    8000578c:	01a70793          	add	a5,a4,26
    80005790:	078e                	sll	a5,a5,0x3
    80005792:	953e                	add	a0,a0,a5
    80005794:	611c                	ld	a5,0(a0)
    80005796:	c385                	beqz	a5,800057b6 <argfd+0x5c>
    return -1;
  if(pfd)
    80005798:	00090463          	beqz	s2,800057a0 <argfd+0x46>
    *pfd = fd;
    8000579c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057a0:	4501                	li	a0,0
  if(pf)
    800057a2:	c091                	beqz	s1,800057a6 <argfd+0x4c>
    *pf = f;
    800057a4:	e09c                	sd	a5,0(s1)
}
    800057a6:	70a2                	ld	ra,40(sp)
    800057a8:	7402                	ld	s0,32(sp)
    800057aa:	64e2                	ld	s1,24(sp)
    800057ac:	6942                	ld	s2,16(sp)
    800057ae:	6145                	add	sp,sp,48
    800057b0:	8082                	ret
    return -1;
    800057b2:	557d                	li	a0,-1
    800057b4:	bfcd                	j	800057a6 <argfd+0x4c>
    800057b6:	557d                	li	a0,-1
    800057b8:	b7fd                	j	800057a6 <argfd+0x4c>

00000000800057ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057ba:	1101                	add	sp,sp,-32
    800057bc:	ec06                	sd	ra,24(sp)
    800057be:	e822                	sd	s0,16(sp)
    800057c0:	e426                	sd	s1,8(sp)
    800057c2:	1000                	add	s0,sp,32
    800057c4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057c6:	ffffc097          	auipc	ra,0xffffc
    800057ca:	1e0080e7          	jalr	480(ra) # 800019a6 <myproc>
    800057ce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057d0:	0d050793          	add	a5,a0,208
    800057d4:	4501                	li	a0,0
    800057d6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057d8:	6398                	ld	a4,0(a5)
    800057da:	cb19                	beqz	a4,800057f0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057dc:	2505                	addw	a0,a0,1
    800057de:	07a1                	add	a5,a5,8
    800057e0:	fed51ce3          	bne	a0,a3,800057d8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057e4:	557d                	li	a0,-1
}
    800057e6:	60e2                	ld	ra,24(sp)
    800057e8:	6442                	ld	s0,16(sp)
    800057ea:	64a2                	ld	s1,8(sp)
    800057ec:	6105                	add	sp,sp,32
    800057ee:	8082                	ret
      p->ofile[fd] = f;
    800057f0:	01a50793          	add	a5,a0,26
    800057f4:	078e                	sll	a5,a5,0x3
    800057f6:	963e                	add	a2,a2,a5
    800057f8:	e204                	sd	s1,0(a2)
      return fd;
    800057fa:	b7f5                	j	800057e6 <fdalloc+0x2c>

00000000800057fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057fc:	715d                	add	sp,sp,-80
    800057fe:	e486                	sd	ra,72(sp)
    80005800:	e0a2                	sd	s0,64(sp)
    80005802:	fc26                	sd	s1,56(sp)
    80005804:	f84a                	sd	s2,48(sp)
    80005806:	f44e                	sd	s3,40(sp)
    80005808:	f052                	sd	s4,32(sp)
    8000580a:	ec56                	sd	s5,24(sp)
    8000580c:	e85a                	sd	s6,16(sp)
    8000580e:	0880                	add	s0,sp,80
    80005810:	8b2e                	mv	s6,a1
    80005812:	89b2                	mv	s3,a2
    80005814:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005816:	fb040593          	add	a1,s0,-80
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	e7e080e7          	jalr	-386(ra) # 80004698 <nameiparent>
    80005822:	84aa                	mv	s1,a0
    80005824:	14050b63          	beqz	a0,8000597a <create+0x17e>
    return 0;

  ilock(dp);
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	6ac080e7          	jalr	1708(ra) # 80003ed4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005830:	4601                	li	a2,0
    80005832:	fb040593          	add	a1,s0,-80
    80005836:	8526                	mv	a0,s1
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	b80080e7          	jalr	-1152(ra) # 800043b8 <dirlookup>
    80005840:	8aaa                	mv	s5,a0
    80005842:	c921                	beqz	a0,80005892 <create+0x96>
    iunlockput(dp);
    80005844:	8526                	mv	a0,s1
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	8f0080e7          	jalr	-1808(ra) # 80004136 <iunlockput>
    ilock(ip);
    8000584e:	8556                	mv	a0,s5
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	684080e7          	jalr	1668(ra) # 80003ed4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005858:	4789                	li	a5,2
    8000585a:	02fb1563          	bne	s6,a5,80005884 <create+0x88>
    8000585e:	044ad783          	lhu	a5,68(s5)
    80005862:	37f9                	addw	a5,a5,-2
    80005864:	17c2                	sll	a5,a5,0x30
    80005866:	93c1                	srl	a5,a5,0x30
    80005868:	4705                	li	a4,1
    8000586a:	00f76d63          	bltu	a4,a5,80005884 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000586e:	8556                	mv	a0,s5
    80005870:	60a6                	ld	ra,72(sp)
    80005872:	6406                	ld	s0,64(sp)
    80005874:	74e2                	ld	s1,56(sp)
    80005876:	7942                	ld	s2,48(sp)
    80005878:	79a2                	ld	s3,40(sp)
    8000587a:	7a02                	ld	s4,32(sp)
    8000587c:	6ae2                	ld	s5,24(sp)
    8000587e:	6b42                	ld	s6,16(sp)
    80005880:	6161                	add	sp,sp,80
    80005882:	8082                	ret
    iunlockput(ip);
    80005884:	8556                	mv	a0,s5
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	8b0080e7          	jalr	-1872(ra) # 80004136 <iunlockput>
    return 0;
    8000588e:	4a81                	li	s5,0
    80005890:	bff9                	j	8000586e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005892:	85da                	mv	a1,s6
    80005894:	4088                	lw	a0,0(s1)
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	4a6080e7          	jalr	1190(ra) # 80003d3c <ialloc>
    8000589e:	8a2a                	mv	s4,a0
    800058a0:	c529                	beqz	a0,800058ea <create+0xee>
  ilock(ip);
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	632080e7          	jalr	1586(ra) # 80003ed4 <ilock>
  ip->major = major;
    800058aa:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800058ae:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800058b2:	4905                	li	s2,1
    800058b4:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800058b8:	8552                	mv	a0,s4
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	54e080e7          	jalr	1358(ra) # 80003e08 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058c2:	032b0b63          	beq	s6,s2,800058f8 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800058c6:	004a2603          	lw	a2,4(s4)
    800058ca:	fb040593          	add	a1,s0,-80
    800058ce:	8526                	mv	a0,s1
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	cf8080e7          	jalr	-776(ra) # 800045c8 <dirlink>
    800058d8:	06054f63          	bltz	a0,80005956 <create+0x15a>
  iunlockput(dp);
    800058dc:	8526                	mv	a0,s1
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	858080e7          	jalr	-1960(ra) # 80004136 <iunlockput>
  return ip;
    800058e6:	8ad2                	mv	s5,s4
    800058e8:	b759                	j	8000586e <create+0x72>
    iunlockput(dp);
    800058ea:	8526                	mv	a0,s1
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	84a080e7          	jalr	-1974(ra) # 80004136 <iunlockput>
    return 0;
    800058f4:	8ad2                	mv	s5,s4
    800058f6:	bfa5                	j	8000586e <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058f8:	004a2603          	lw	a2,4(s4)
    800058fc:	00003597          	auipc	a1,0x3
    80005900:	e7458593          	add	a1,a1,-396 # 80008770 <syscalls+0x2e8>
    80005904:	8552                	mv	a0,s4
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	cc2080e7          	jalr	-830(ra) # 800045c8 <dirlink>
    8000590e:	04054463          	bltz	a0,80005956 <create+0x15a>
    80005912:	40d0                	lw	a2,4(s1)
    80005914:	00003597          	auipc	a1,0x3
    80005918:	e6458593          	add	a1,a1,-412 # 80008778 <syscalls+0x2f0>
    8000591c:	8552                	mv	a0,s4
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	caa080e7          	jalr	-854(ra) # 800045c8 <dirlink>
    80005926:	02054863          	bltz	a0,80005956 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000592a:	004a2603          	lw	a2,4(s4)
    8000592e:	fb040593          	add	a1,s0,-80
    80005932:	8526                	mv	a0,s1
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	c94080e7          	jalr	-876(ra) # 800045c8 <dirlink>
    8000593c:	00054d63          	bltz	a0,80005956 <create+0x15a>
    dp->nlink++;  // for ".."
    80005940:	04a4d783          	lhu	a5,74(s1)
    80005944:	2785                	addw	a5,a5,1
    80005946:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	4bc080e7          	jalr	1212(ra) # 80003e08 <iupdate>
    80005954:	b761                	j	800058dc <create+0xe0>
  ip->nlink = 0;
    80005956:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000595a:	8552                	mv	a0,s4
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	4ac080e7          	jalr	1196(ra) # 80003e08 <iupdate>
  iunlockput(ip);
    80005964:	8552                	mv	a0,s4
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	7d0080e7          	jalr	2000(ra) # 80004136 <iunlockput>
  iunlockput(dp);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	7c6080e7          	jalr	1990(ra) # 80004136 <iunlockput>
  return 0;
    80005978:	bddd                	j	8000586e <create+0x72>
    return 0;
    8000597a:	8aaa                	mv	s5,a0
    8000597c:	bdcd                	j	8000586e <create+0x72>

000000008000597e <sys_dup>:
{
    8000597e:	7179                	add	sp,sp,-48
    80005980:	f406                	sd	ra,40(sp)
    80005982:	f022                	sd	s0,32(sp)
    80005984:	ec26                	sd	s1,24(sp)
    80005986:	e84a                	sd	s2,16(sp)
    80005988:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000598a:	fd840613          	add	a2,s0,-40
    8000598e:	4581                	li	a1,0
    80005990:	4501                	li	a0,0
    80005992:	00000097          	auipc	ra,0x0
    80005996:	dc8080e7          	jalr	-568(ra) # 8000575a <argfd>
    return -1;
    8000599a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000599c:	02054363          	bltz	a0,800059c2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800059a0:	fd843903          	ld	s2,-40(s0)
    800059a4:	854a                	mv	a0,s2
    800059a6:	00000097          	auipc	ra,0x0
    800059aa:	e14080e7          	jalr	-492(ra) # 800057ba <fdalloc>
    800059ae:	84aa                	mv	s1,a0
    return -1;
    800059b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059b2:	00054863          	bltz	a0,800059c2 <sys_dup+0x44>
  filedup(f);
    800059b6:	854a                	mv	a0,s2
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	334080e7          	jalr	820(ra) # 80004cec <filedup>
  return fd;
    800059c0:	87a6                	mv	a5,s1
}
    800059c2:	853e                	mv	a0,a5
    800059c4:	70a2                	ld	ra,40(sp)
    800059c6:	7402                	ld	s0,32(sp)
    800059c8:	64e2                	ld	s1,24(sp)
    800059ca:	6942                	ld	s2,16(sp)
    800059cc:	6145                	add	sp,sp,48
    800059ce:	8082                	ret

00000000800059d0 <sys_read>:
{
    800059d0:	7179                	add	sp,sp,-48
    800059d2:	f406                	sd	ra,40(sp)
    800059d4:	f022                	sd	s0,32(sp)
    800059d6:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800059d8:	fd840593          	add	a1,s0,-40
    800059dc:	4505                	li	a0,1
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	7c6080e7          	jalr	1990(ra) # 800031a4 <argaddr>
  argint(2, &n);
    800059e6:	fe440593          	add	a1,s0,-28
    800059ea:	4509                	li	a0,2
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	798080e7          	jalr	1944(ra) # 80003184 <argint>
  if(argfd(0, 0, &f) < 0)
    800059f4:	fe840613          	add	a2,s0,-24
    800059f8:	4581                	li	a1,0
    800059fa:	4501                	li	a0,0
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	d5e080e7          	jalr	-674(ra) # 8000575a <argfd>
    80005a04:	87aa                	mv	a5,a0
    return -1;
    80005a06:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a08:	0007cc63          	bltz	a5,80005a20 <sys_read+0x50>
  return fileread(f, p, n);
    80005a0c:	fe442603          	lw	a2,-28(s0)
    80005a10:	fd843583          	ld	a1,-40(s0)
    80005a14:	fe843503          	ld	a0,-24(s0)
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	460080e7          	jalr	1120(ra) # 80004e78 <fileread>
}
    80005a20:	70a2                	ld	ra,40(sp)
    80005a22:	7402                	ld	s0,32(sp)
    80005a24:	6145                	add	sp,sp,48
    80005a26:	8082                	ret

0000000080005a28 <sys_write>:
{
    80005a28:	7179                	add	sp,sp,-48
    80005a2a:	f406                	sd	ra,40(sp)
    80005a2c:	f022                	sd	s0,32(sp)
    80005a2e:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005a30:	fd840593          	add	a1,s0,-40
    80005a34:	4505                	li	a0,1
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	76e080e7          	jalr	1902(ra) # 800031a4 <argaddr>
  argint(2, &n);
    80005a3e:	fe440593          	add	a1,s0,-28
    80005a42:	4509                	li	a0,2
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	740080e7          	jalr	1856(ra) # 80003184 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a4c:	fe840613          	add	a2,s0,-24
    80005a50:	4581                	li	a1,0
    80005a52:	4501                	li	a0,0
    80005a54:	00000097          	auipc	ra,0x0
    80005a58:	d06080e7          	jalr	-762(ra) # 8000575a <argfd>
    80005a5c:	87aa                	mv	a5,a0
    return -1;
    80005a5e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a60:	0007cc63          	bltz	a5,80005a78 <sys_write+0x50>
  return filewrite(f, p, n);
    80005a64:	fe442603          	lw	a2,-28(s0)
    80005a68:	fd843583          	ld	a1,-40(s0)
    80005a6c:	fe843503          	ld	a0,-24(s0)
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	4ca080e7          	jalr	1226(ra) # 80004f3a <filewrite>
}
    80005a78:	70a2                	ld	ra,40(sp)
    80005a7a:	7402                	ld	s0,32(sp)
    80005a7c:	6145                	add	sp,sp,48
    80005a7e:	8082                	ret

0000000080005a80 <sys_close>:
{
    80005a80:	1101                	add	sp,sp,-32
    80005a82:	ec06                	sd	ra,24(sp)
    80005a84:	e822                	sd	s0,16(sp)
    80005a86:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a88:	fe040613          	add	a2,s0,-32
    80005a8c:	fec40593          	add	a1,s0,-20
    80005a90:	4501                	li	a0,0
    80005a92:	00000097          	auipc	ra,0x0
    80005a96:	cc8080e7          	jalr	-824(ra) # 8000575a <argfd>
    return -1;
    80005a9a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a9c:	02054463          	bltz	a0,80005ac4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005aa0:	ffffc097          	auipc	ra,0xffffc
    80005aa4:	f06080e7          	jalr	-250(ra) # 800019a6 <myproc>
    80005aa8:	fec42783          	lw	a5,-20(s0)
    80005aac:	07e9                	add	a5,a5,26
    80005aae:	078e                	sll	a5,a5,0x3
    80005ab0:	953e                	add	a0,a0,a5
    80005ab2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005ab6:	fe043503          	ld	a0,-32(s0)
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	284080e7          	jalr	644(ra) # 80004d3e <fileclose>
  return 0;
    80005ac2:	4781                	li	a5,0
}
    80005ac4:	853e                	mv	a0,a5
    80005ac6:	60e2                	ld	ra,24(sp)
    80005ac8:	6442                	ld	s0,16(sp)
    80005aca:	6105                	add	sp,sp,32
    80005acc:	8082                	ret

0000000080005ace <sys_fstat>:
{
    80005ace:	1101                	add	sp,sp,-32
    80005ad0:	ec06                	sd	ra,24(sp)
    80005ad2:	e822                	sd	s0,16(sp)
    80005ad4:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005ad6:	fe040593          	add	a1,s0,-32
    80005ada:	4505                	li	a0,1
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	6c8080e7          	jalr	1736(ra) # 800031a4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005ae4:	fe840613          	add	a2,s0,-24
    80005ae8:	4581                	li	a1,0
    80005aea:	4501                	li	a0,0
    80005aec:	00000097          	auipc	ra,0x0
    80005af0:	c6e080e7          	jalr	-914(ra) # 8000575a <argfd>
    80005af4:	87aa                	mv	a5,a0
    return -1;
    80005af6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005af8:	0007ca63          	bltz	a5,80005b0c <sys_fstat+0x3e>
  return filestat(f, st);
    80005afc:	fe043583          	ld	a1,-32(s0)
    80005b00:	fe843503          	ld	a0,-24(s0)
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	302080e7          	jalr	770(ra) # 80004e06 <filestat>
}
    80005b0c:	60e2                	ld	ra,24(sp)
    80005b0e:	6442                	ld	s0,16(sp)
    80005b10:	6105                	add	sp,sp,32
    80005b12:	8082                	ret

0000000080005b14 <sys_link>:
{
    80005b14:	7169                	add	sp,sp,-304
    80005b16:	f606                	sd	ra,296(sp)
    80005b18:	f222                	sd	s0,288(sp)
    80005b1a:	ee26                	sd	s1,280(sp)
    80005b1c:	ea4a                	sd	s2,272(sp)
    80005b1e:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b20:	08000613          	li	a2,128
    80005b24:	ed040593          	add	a1,s0,-304
    80005b28:	4501                	li	a0,0
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	69a080e7          	jalr	1690(ra) # 800031c4 <argstr>
    return -1;
    80005b32:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b34:	10054e63          	bltz	a0,80005c50 <sys_link+0x13c>
    80005b38:	08000613          	li	a2,128
    80005b3c:	f5040593          	add	a1,s0,-176
    80005b40:	4505                	li	a0,1
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	682080e7          	jalr	1666(ra) # 800031c4 <argstr>
    return -1;
    80005b4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b4c:	10054263          	bltz	a0,80005c50 <sys_link+0x13c>
  begin_op();
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	d2a080e7          	jalr	-726(ra) # 8000487a <begin_op>
  if((ip = namei(old)) == 0){
    80005b58:	ed040513          	add	a0,s0,-304
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	b1e080e7          	jalr	-1250(ra) # 8000467a <namei>
    80005b64:	84aa                	mv	s1,a0
    80005b66:	c551                	beqz	a0,80005bf2 <sys_link+0xde>
  ilock(ip);
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	36c080e7          	jalr	876(ra) # 80003ed4 <ilock>
  if(ip->type == T_DIR){
    80005b70:	04449703          	lh	a4,68(s1)
    80005b74:	4785                	li	a5,1
    80005b76:	08f70463          	beq	a4,a5,80005bfe <sys_link+0xea>
  ip->nlink++;
    80005b7a:	04a4d783          	lhu	a5,74(s1)
    80005b7e:	2785                	addw	a5,a5,1
    80005b80:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	282080e7          	jalr	642(ra) # 80003e08 <iupdate>
  iunlock(ip);
    80005b8e:	8526                	mv	a0,s1
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	406080e7          	jalr	1030(ra) # 80003f96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b98:	fd040593          	add	a1,s0,-48
    80005b9c:	f5040513          	add	a0,s0,-176
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	af8080e7          	jalr	-1288(ra) # 80004698 <nameiparent>
    80005ba8:	892a                	mv	s2,a0
    80005baa:	c935                	beqz	a0,80005c1e <sys_link+0x10a>
  ilock(dp);
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	328080e7          	jalr	808(ra) # 80003ed4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bb4:	00092703          	lw	a4,0(s2)
    80005bb8:	409c                	lw	a5,0(s1)
    80005bba:	04f71d63          	bne	a4,a5,80005c14 <sys_link+0x100>
    80005bbe:	40d0                	lw	a2,4(s1)
    80005bc0:	fd040593          	add	a1,s0,-48
    80005bc4:	854a                	mv	a0,s2
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	a02080e7          	jalr	-1534(ra) # 800045c8 <dirlink>
    80005bce:	04054363          	bltz	a0,80005c14 <sys_link+0x100>
  iunlockput(dp);
    80005bd2:	854a                	mv	a0,s2
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	562080e7          	jalr	1378(ra) # 80004136 <iunlockput>
  iput(ip);
    80005bdc:	8526                	mv	a0,s1
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	4b0080e7          	jalr	1200(ra) # 8000408e <iput>
  end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	d0e080e7          	jalr	-754(ra) # 800048f4 <end_op>
  return 0;
    80005bee:	4781                	li	a5,0
    80005bf0:	a085                	j	80005c50 <sys_link+0x13c>
    end_op();
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	d02080e7          	jalr	-766(ra) # 800048f4 <end_op>
    return -1;
    80005bfa:	57fd                	li	a5,-1
    80005bfc:	a891                	j	80005c50 <sys_link+0x13c>
    iunlockput(ip);
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	536080e7          	jalr	1334(ra) # 80004136 <iunlockput>
    end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	cec080e7          	jalr	-788(ra) # 800048f4 <end_op>
    return -1;
    80005c10:	57fd                	li	a5,-1
    80005c12:	a83d                	j	80005c50 <sys_link+0x13c>
    iunlockput(dp);
    80005c14:	854a                	mv	a0,s2
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	520080e7          	jalr	1312(ra) # 80004136 <iunlockput>
  ilock(ip);
    80005c1e:	8526                	mv	a0,s1
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	2b4080e7          	jalr	692(ra) # 80003ed4 <ilock>
  ip->nlink--;
    80005c28:	04a4d783          	lhu	a5,74(s1)
    80005c2c:	37fd                	addw	a5,a5,-1
    80005c2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c32:	8526                	mv	a0,s1
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	1d4080e7          	jalr	468(ra) # 80003e08 <iupdate>
  iunlockput(ip);
    80005c3c:	8526                	mv	a0,s1
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	4f8080e7          	jalr	1272(ra) # 80004136 <iunlockput>
  end_op();
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	cae080e7          	jalr	-850(ra) # 800048f4 <end_op>
  return -1;
    80005c4e:	57fd                	li	a5,-1
}
    80005c50:	853e                	mv	a0,a5
    80005c52:	70b2                	ld	ra,296(sp)
    80005c54:	7412                	ld	s0,288(sp)
    80005c56:	64f2                	ld	s1,280(sp)
    80005c58:	6952                	ld	s2,272(sp)
    80005c5a:	6155                	add	sp,sp,304
    80005c5c:	8082                	ret

0000000080005c5e <sys_unlink>:
{
    80005c5e:	7151                	add	sp,sp,-240
    80005c60:	f586                	sd	ra,232(sp)
    80005c62:	f1a2                	sd	s0,224(sp)
    80005c64:	eda6                	sd	s1,216(sp)
    80005c66:	e9ca                	sd	s2,208(sp)
    80005c68:	e5ce                	sd	s3,200(sp)
    80005c6a:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c6c:	08000613          	li	a2,128
    80005c70:	f3040593          	add	a1,s0,-208
    80005c74:	4501                	li	a0,0
    80005c76:	ffffd097          	auipc	ra,0xffffd
    80005c7a:	54e080e7          	jalr	1358(ra) # 800031c4 <argstr>
    80005c7e:	18054163          	bltz	a0,80005e00 <sys_unlink+0x1a2>
  begin_op();
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	bf8080e7          	jalr	-1032(ra) # 8000487a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c8a:	fb040593          	add	a1,s0,-80
    80005c8e:	f3040513          	add	a0,s0,-208
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	a06080e7          	jalr	-1530(ra) # 80004698 <nameiparent>
    80005c9a:	84aa                	mv	s1,a0
    80005c9c:	c979                	beqz	a0,80005d72 <sys_unlink+0x114>
  ilock(dp);
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	236080e7          	jalr	566(ra) # 80003ed4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ca6:	00003597          	auipc	a1,0x3
    80005caa:	aca58593          	add	a1,a1,-1334 # 80008770 <syscalls+0x2e8>
    80005cae:	fb040513          	add	a0,s0,-80
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	6ec080e7          	jalr	1772(ra) # 8000439e <namecmp>
    80005cba:	14050a63          	beqz	a0,80005e0e <sys_unlink+0x1b0>
    80005cbe:	00003597          	auipc	a1,0x3
    80005cc2:	aba58593          	add	a1,a1,-1350 # 80008778 <syscalls+0x2f0>
    80005cc6:	fb040513          	add	a0,s0,-80
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	6d4080e7          	jalr	1748(ra) # 8000439e <namecmp>
    80005cd2:	12050e63          	beqz	a0,80005e0e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cd6:	f2c40613          	add	a2,s0,-212
    80005cda:	fb040593          	add	a1,s0,-80
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	6d8080e7          	jalr	1752(ra) # 800043b8 <dirlookup>
    80005ce8:	892a                	mv	s2,a0
    80005cea:	12050263          	beqz	a0,80005e0e <sys_unlink+0x1b0>
  ilock(ip);
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	1e6080e7          	jalr	486(ra) # 80003ed4 <ilock>
  if(ip->nlink < 1)
    80005cf6:	04a91783          	lh	a5,74(s2)
    80005cfa:	08f05263          	blez	a5,80005d7e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cfe:	04491703          	lh	a4,68(s2)
    80005d02:	4785                	li	a5,1
    80005d04:	08f70563          	beq	a4,a5,80005d8e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d08:	4641                	li	a2,16
    80005d0a:	4581                	li	a1,0
    80005d0c:	fc040513          	add	a0,s0,-64
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	fbe080e7          	jalr	-66(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d18:	4741                	li	a4,16
    80005d1a:	f2c42683          	lw	a3,-212(s0)
    80005d1e:	fc040613          	add	a2,s0,-64
    80005d22:	4581                	li	a1,0
    80005d24:	8526                	mv	a0,s1
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	55a080e7          	jalr	1370(ra) # 80004280 <writei>
    80005d2e:	47c1                	li	a5,16
    80005d30:	0af51563          	bne	a0,a5,80005dda <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d34:	04491703          	lh	a4,68(s2)
    80005d38:	4785                	li	a5,1
    80005d3a:	0af70863          	beq	a4,a5,80005dea <sys_unlink+0x18c>
  iunlockput(dp);
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	3f6080e7          	jalr	1014(ra) # 80004136 <iunlockput>
  ip->nlink--;
    80005d48:	04a95783          	lhu	a5,74(s2)
    80005d4c:	37fd                	addw	a5,a5,-1
    80005d4e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d52:	854a                	mv	a0,s2
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	0b4080e7          	jalr	180(ra) # 80003e08 <iupdate>
  iunlockput(ip);
    80005d5c:	854a                	mv	a0,s2
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	3d8080e7          	jalr	984(ra) # 80004136 <iunlockput>
  end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	b8e080e7          	jalr	-1138(ra) # 800048f4 <end_op>
  return 0;
    80005d6e:	4501                	li	a0,0
    80005d70:	a84d                	j	80005e22 <sys_unlink+0x1c4>
    end_op();
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	b82080e7          	jalr	-1150(ra) # 800048f4 <end_op>
    return -1;
    80005d7a:	557d                	li	a0,-1
    80005d7c:	a05d                	j	80005e22 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d7e:	00003517          	auipc	a0,0x3
    80005d82:	a0250513          	add	a0,a0,-1534 # 80008780 <syscalls+0x2f8>
    80005d86:	ffffa097          	auipc	ra,0xffffa
    80005d8a:	7b6080e7          	jalr	1974(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d8e:	04c92703          	lw	a4,76(s2)
    80005d92:	02000793          	li	a5,32
    80005d96:	f6e7f9e3          	bgeu	a5,a4,80005d08 <sys_unlink+0xaa>
    80005d9a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d9e:	4741                	li	a4,16
    80005da0:	86ce                	mv	a3,s3
    80005da2:	f1840613          	add	a2,s0,-232
    80005da6:	4581                	li	a1,0
    80005da8:	854a                	mv	a0,s2
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	3de080e7          	jalr	990(ra) # 80004188 <readi>
    80005db2:	47c1                	li	a5,16
    80005db4:	00f51b63          	bne	a0,a5,80005dca <sys_unlink+0x16c>
    if(de.inum != 0)
    80005db8:	f1845783          	lhu	a5,-232(s0)
    80005dbc:	e7a1                	bnez	a5,80005e04 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dbe:	29c1                	addw	s3,s3,16
    80005dc0:	04c92783          	lw	a5,76(s2)
    80005dc4:	fcf9ede3          	bltu	s3,a5,80005d9e <sys_unlink+0x140>
    80005dc8:	b781                	j	80005d08 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005dca:	00003517          	auipc	a0,0x3
    80005dce:	9ce50513          	add	a0,a0,-1586 # 80008798 <syscalls+0x310>
    80005dd2:	ffffa097          	auipc	ra,0xffffa
    80005dd6:	76a080e7          	jalr	1898(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005dda:	00003517          	auipc	a0,0x3
    80005dde:	9d650513          	add	a0,a0,-1578 # 800087b0 <syscalls+0x328>
    80005de2:	ffffa097          	auipc	ra,0xffffa
    80005de6:	75a080e7          	jalr	1882(ra) # 8000053c <panic>
    dp->nlink--;
    80005dea:	04a4d783          	lhu	a5,74(s1)
    80005dee:	37fd                	addw	a5,a5,-1
    80005df0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005df4:	8526                	mv	a0,s1
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	012080e7          	jalr	18(ra) # 80003e08 <iupdate>
    80005dfe:	b781                	j	80005d3e <sys_unlink+0xe0>
    return -1;
    80005e00:	557d                	li	a0,-1
    80005e02:	a005                	j	80005e22 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e04:	854a                	mv	a0,s2
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	330080e7          	jalr	816(ra) # 80004136 <iunlockput>
  iunlockput(dp);
    80005e0e:	8526                	mv	a0,s1
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	326080e7          	jalr	806(ra) # 80004136 <iunlockput>
  end_op();
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	adc080e7          	jalr	-1316(ra) # 800048f4 <end_op>
  return -1;
    80005e20:	557d                	li	a0,-1
}
    80005e22:	70ae                	ld	ra,232(sp)
    80005e24:	740e                	ld	s0,224(sp)
    80005e26:	64ee                	ld	s1,216(sp)
    80005e28:	694e                	ld	s2,208(sp)
    80005e2a:	69ae                	ld	s3,200(sp)
    80005e2c:	616d                	add	sp,sp,240
    80005e2e:	8082                	ret

0000000080005e30 <sys_open>:

uint64
sys_open(void)
{
    80005e30:	7131                	add	sp,sp,-192
    80005e32:	fd06                	sd	ra,184(sp)
    80005e34:	f922                	sd	s0,176(sp)
    80005e36:	f526                	sd	s1,168(sp)
    80005e38:	f14a                	sd	s2,160(sp)
    80005e3a:	ed4e                	sd	s3,152(sp)
    80005e3c:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e3e:	f4c40593          	add	a1,s0,-180
    80005e42:	4505                	li	a0,1
    80005e44:	ffffd097          	auipc	ra,0xffffd
    80005e48:	340080e7          	jalr	832(ra) # 80003184 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e4c:	08000613          	li	a2,128
    80005e50:	f5040593          	add	a1,s0,-176
    80005e54:	4501                	li	a0,0
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	36e080e7          	jalr	878(ra) # 800031c4 <argstr>
    80005e5e:	87aa                	mv	a5,a0
    return -1;
    80005e60:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e62:	0a07c863          	bltz	a5,80005f12 <sys_open+0xe2>

  begin_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	a14080e7          	jalr	-1516(ra) # 8000487a <begin_op>

  if(omode & O_CREATE){
    80005e6e:	f4c42783          	lw	a5,-180(s0)
    80005e72:	2007f793          	and	a5,a5,512
    80005e76:	cbdd                	beqz	a5,80005f2c <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005e78:	4681                	li	a3,0
    80005e7a:	4601                	li	a2,0
    80005e7c:	4589                	li	a1,2
    80005e7e:	f5040513          	add	a0,s0,-176
    80005e82:	00000097          	auipc	ra,0x0
    80005e86:	97a080e7          	jalr	-1670(ra) # 800057fc <create>
    80005e8a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e8c:	c951                	beqz	a0,80005f20 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e8e:	04449703          	lh	a4,68(s1)
    80005e92:	478d                	li	a5,3
    80005e94:	00f71763          	bne	a4,a5,80005ea2 <sys_open+0x72>
    80005e98:	0464d703          	lhu	a4,70(s1)
    80005e9c:	47a5                	li	a5,9
    80005e9e:	0ce7ec63          	bltu	a5,a4,80005f76 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	de0080e7          	jalr	-544(ra) # 80004c82 <filealloc>
    80005eaa:	892a                	mv	s2,a0
    80005eac:	c56d                	beqz	a0,80005f96 <sys_open+0x166>
    80005eae:	00000097          	auipc	ra,0x0
    80005eb2:	90c080e7          	jalr	-1780(ra) # 800057ba <fdalloc>
    80005eb6:	89aa                	mv	s3,a0
    80005eb8:	0c054a63          	bltz	a0,80005f8c <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ebc:	04449703          	lh	a4,68(s1)
    80005ec0:	478d                	li	a5,3
    80005ec2:	0ef70563          	beq	a4,a5,80005fac <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ec6:	4789                	li	a5,2
    80005ec8:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005ecc:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005ed0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005ed4:	f4c42783          	lw	a5,-180(s0)
    80005ed8:	0017c713          	xor	a4,a5,1
    80005edc:	8b05                	and	a4,a4,1
    80005ede:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ee2:	0037f713          	and	a4,a5,3
    80005ee6:	00e03733          	snez	a4,a4
    80005eea:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005eee:	4007f793          	and	a5,a5,1024
    80005ef2:	c791                	beqz	a5,80005efe <sys_open+0xce>
    80005ef4:	04449703          	lh	a4,68(s1)
    80005ef8:	4789                	li	a5,2
    80005efa:	0cf70063          	beq	a4,a5,80005fba <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005efe:	8526                	mv	a0,s1
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	096080e7          	jalr	150(ra) # 80003f96 <iunlock>
  end_op();
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	9ec080e7          	jalr	-1556(ra) # 800048f4 <end_op>

  return fd;
    80005f10:	854e                	mv	a0,s3
}
    80005f12:	70ea                	ld	ra,184(sp)
    80005f14:	744a                	ld	s0,176(sp)
    80005f16:	74aa                	ld	s1,168(sp)
    80005f18:	790a                	ld	s2,160(sp)
    80005f1a:	69ea                	ld	s3,152(sp)
    80005f1c:	6129                	add	sp,sp,192
    80005f1e:	8082                	ret
      end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	9d4080e7          	jalr	-1580(ra) # 800048f4 <end_op>
      return -1;
    80005f28:	557d                	li	a0,-1
    80005f2a:	b7e5                	j	80005f12 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005f2c:	f5040513          	add	a0,s0,-176
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	74a080e7          	jalr	1866(ra) # 8000467a <namei>
    80005f38:	84aa                	mv	s1,a0
    80005f3a:	c905                	beqz	a0,80005f6a <sys_open+0x13a>
    ilock(ip);
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	f98080e7          	jalr	-104(ra) # 80003ed4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f44:	04449703          	lh	a4,68(s1)
    80005f48:	4785                	li	a5,1
    80005f4a:	f4f712e3          	bne	a4,a5,80005e8e <sys_open+0x5e>
    80005f4e:	f4c42783          	lw	a5,-180(s0)
    80005f52:	dba1                	beqz	a5,80005ea2 <sys_open+0x72>
      iunlockput(ip);
    80005f54:	8526                	mv	a0,s1
    80005f56:	ffffe097          	auipc	ra,0xffffe
    80005f5a:	1e0080e7          	jalr	480(ra) # 80004136 <iunlockput>
      end_op();
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	996080e7          	jalr	-1642(ra) # 800048f4 <end_op>
      return -1;
    80005f66:	557d                	li	a0,-1
    80005f68:	b76d                	j	80005f12 <sys_open+0xe2>
      end_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	98a080e7          	jalr	-1654(ra) # 800048f4 <end_op>
      return -1;
    80005f72:	557d                	li	a0,-1
    80005f74:	bf79                	j	80005f12 <sys_open+0xe2>
    iunlockput(ip);
    80005f76:	8526                	mv	a0,s1
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	1be080e7          	jalr	446(ra) # 80004136 <iunlockput>
    end_op();
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	974080e7          	jalr	-1676(ra) # 800048f4 <end_op>
    return -1;
    80005f88:	557d                	li	a0,-1
    80005f8a:	b761                	j	80005f12 <sys_open+0xe2>
      fileclose(f);
    80005f8c:	854a                	mv	a0,s2
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	db0080e7          	jalr	-592(ra) # 80004d3e <fileclose>
    iunlockput(ip);
    80005f96:	8526                	mv	a0,s1
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	19e080e7          	jalr	414(ra) # 80004136 <iunlockput>
    end_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	954080e7          	jalr	-1708(ra) # 800048f4 <end_op>
    return -1;
    80005fa8:	557d                	li	a0,-1
    80005faa:	b7a5                	j	80005f12 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005fac:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005fb0:	04649783          	lh	a5,70(s1)
    80005fb4:	02f91223          	sh	a5,36(s2)
    80005fb8:	bf21                	j	80005ed0 <sys_open+0xa0>
    itrunc(ip);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	026080e7          	jalr	38(ra) # 80003fe2 <itrunc>
    80005fc4:	bf2d                	j	80005efe <sys_open+0xce>

0000000080005fc6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fc6:	7175                	add	sp,sp,-144
    80005fc8:	e506                	sd	ra,136(sp)
    80005fca:	e122                	sd	s0,128(sp)
    80005fcc:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	8ac080e7          	jalr	-1876(ra) # 8000487a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005fd6:	08000613          	li	a2,128
    80005fda:	f7040593          	add	a1,s0,-144
    80005fde:	4501                	li	a0,0
    80005fe0:	ffffd097          	auipc	ra,0xffffd
    80005fe4:	1e4080e7          	jalr	484(ra) # 800031c4 <argstr>
    80005fe8:	02054963          	bltz	a0,8000601a <sys_mkdir+0x54>
    80005fec:	4681                	li	a3,0
    80005fee:	4601                	li	a2,0
    80005ff0:	4585                	li	a1,1
    80005ff2:	f7040513          	add	a0,s0,-144
    80005ff6:	00000097          	auipc	ra,0x0
    80005ffa:	806080e7          	jalr	-2042(ra) # 800057fc <create>
    80005ffe:	cd11                	beqz	a0,8000601a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	136080e7          	jalr	310(ra) # 80004136 <iunlockput>
  end_op();
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	8ec080e7          	jalr	-1812(ra) # 800048f4 <end_op>
  return 0;
    80006010:	4501                	li	a0,0
}
    80006012:	60aa                	ld	ra,136(sp)
    80006014:	640a                	ld	s0,128(sp)
    80006016:	6149                	add	sp,sp,144
    80006018:	8082                	ret
    end_op();
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	8da080e7          	jalr	-1830(ra) # 800048f4 <end_op>
    return -1;
    80006022:	557d                	li	a0,-1
    80006024:	b7fd                	j	80006012 <sys_mkdir+0x4c>

0000000080006026 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006026:	7135                	add	sp,sp,-160
    80006028:	ed06                	sd	ra,152(sp)
    8000602a:	e922                	sd	s0,144(sp)
    8000602c:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	84c080e7          	jalr	-1972(ra) # 8000487a <begin_op>
  argint(1, &major);
    80006036:	f6c40593          	add	a1,s0,-148
    8000603a:	4505                	li	a0,1
    8000603c:	ffffd097          	auipc	ra,0xffffd
    80006040:	148080e7          	jalr	328(ra) # 80003184 <argint>
  argint(2, &minor);
    80006044:	f6840593          	add	a1,s0,-152
    80006048:	4509                	li	a0,2
    8000604a:	ffffd097          	auipc	ra,0xffffd
    8000604e:	13a080e7          	jalr	314(ra) # 80003184 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006052:	08000613          	li	a2,128
    80006056:	f7040593          	add	a1,s0,-144
    8000605a:	4501                	li	a0,0
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	168080e7          	jalr	360(ra) # 800031c4 <argstr>
    80006064:	02054b63          	bltz	a0,8000609a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006068:	f6841683          	lh	a3,-152(s0)
    8000606c:	f6c41603          	lh	a2,-148(s0)
    80006070:	458d                	li	a1,3
    80006072:	f7040513          	add	a0,s0,-144
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	786080e7          	jalr	1926(ra) # 800057fc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000607e:	cd11                	beqz	a0,8000609a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	0b6080e7          	jalr	182(ra) # 80004136 <iunlockput>
  end_op();
    80006088:	fffff097          	auipc	ra,0xfffff
    8000608c:	86c080e7          	jalr	-1940(ra) # 800048f4 <end_op>
  return 0;
    80006090:	4501                	li	a0,0
}
    80006092:	60ea                	ld	ra,152(sp)
    80006094:	644a                	ld	s0,144(sp)
    80006096:	610d                	add	sp,sp,160
    80006098:	8082                	ret
    end_op();
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	85a080e7          	jalr	-1958(ra) # 800048f4 <end_op>
    return -1;
    800060a2:	557d                	li	a0,-1
    800060a4:	b7fd                	j	80006092 <sys_mknod+0x6c>

00000000800060a6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060a6:	7135                	add	sp,sp,-160
    800060a8:	ed06                	sd	ra,152(sp)
    800060aa:	e922                	sd	s0,144(sp)
    800060ac:	e526                	sd	s1,136(sp)
    800060ae:	e14a                	sd	s2,128(sp)
    800060b0:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060b2:	ffffc097          	auipc	ra,0xffffc
    800060b6:	8f4080e7          	jalr	-1804(ra) # 800019a6 <myproc>
    800060ba:	892a                	mv	s2,a0
  
  begin_op();
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	7be080e7          	jalr	1982(ra) # 8000487a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060c4:	08000613          	li	a2,128
    800060c8:	f6040593          	add	a1,s0,-160
    800060cc:	4501                	li	a0,0
    800060ce:	ffffd097          	auipc	ra,0xffffd
    800060d2:	0f6080e7          	jalr	246(ra) # 800031c4 <argstr>
    800060d6:	04054b63          	bltz	a0,8000612c <sys_chdir+0x86>
    800060da:	f6040513          	add	a0,s0,-160
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	59c080e7          	jalr	1436(ra) # 8000467a <namei>
    800060e6:	84aa                	mv	s1,a0
    800060e8:	c131                	beqz	a0,8000612c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	dea080e7          	jalr	-534(ra) # 80003ed4 <ilock>
  if(ip->type != T_DIR){
    800060f2:	04449703          	lh	a4,68(s1)
    800060f6:	4785                	li	a5,1
    800060f8:	04f71063          	bne	a4,a5,80006138 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060fc:	8526                	mv	a0,s1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	e98080e7          	jalr	-360(ra) # 80003f96 <iunlock>
  iput(p->cwd);
    80006106:	15093503          	ld	a0,336(s2)
    8000610a:	ffffe097          	auipc	ra,0xffffe
    8000610e:	f84080e7          	jalr	-124(ra) # 8000408e <iput>
  end_op();
    80006112:	ffffe097          	auipc	ra,0xffffe
    80006116:	7e2080e7          	jalr	2018(ra) # 800048f4 <end_op>
  p->cwd = ip;
    8000611a:	14993823          	sd	s1,336(s2)
  return 0;
    8000611e:	4501                	li	a0,0
}
    80006120:	60ea                	ld	ra,152(sp)
    80006122:	644a                	ld	s0,144(sp)
    80006124:	64aa                	ld	s1,136(sp)
    80006126:	690a                	ld	s2,128(sp)
    80006128:	610d                	add	sp,sp,160
    8000612a:	8082                	ret
    end_op();
    8000612c:	ffffe097          	auipc	ra,0xffffe
    80006130:	7c8080e7          	jalr	1992(ra) # 800048f4 <end_op>
    return -1;
    80006134:	557d                	li	a0,-1
    80006136:	b7ed                	j	80006120 <sys_chdir+0x7a>
    iunlockput(ip);
    80006138:	8526                	mv	a0,s1
    8000613a:	ffffe097          	auipc	ra,0xffffe
    8000613e:	ffc080e7          	jalr	-4(ra) # 80004136 <iunlockput>
    end_op();
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	7b2080e7          	jalr	1970(ra) # 800048f4 <end_op>
    return -1;
    8000614a:	557d                	li	a0,-1
    8000614c:	bfd1                	j	80006120 <sys_chdir+0x7a>

000000008000614e <sys_exec>:

uint64
sys_exec(void)
{
    8000614e:	7121                	add	sp,sp,-448
    80006150:	ff06                	sd	ra,440(sp)
    80006152:	fb22                	sd	s0,432(sp)
    80006154:	f726                	sd	s1,424(sp)
    80006156:	f34a                	sd	s2,416(sp)
    80006158:	ef4e                	sd	s3,408(sp)
    8000615a:	eb52                	sd	s4,400(sp)
    8000615c:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000615e:	e4840593          	add	a1,s0,-440
    80006162:	4505                	li	a0,1
    80006164:	ffffd097          	auipc	ra,0xffffd
    80006168:	040080e7          	jalr	64(ra) # 800031a4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000616c:	08000613          	li	a2,128
    80006170:	f5040593          	add	a1,s0,-176
    80006174:	4501                	li	a0,0
    80006176:	ffffd097          	auipc	ra,0xffffd
    8000617a:	04e080e7          	jalr	78(ra) # 800031c4 <argstr>
    8000617e:	87aa                	mv	a5,a0
    return -1;
    80006180:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006182:	0c07c263          	bltz	a5,80006246 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80006186:	10000613          	li	a2,256
    8000618a:	4581                	li	a1,0
    8000618c:	e5040513          	add	a0,s0,-432
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	b3e080e7          	jalr	-1218(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006198:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000619c:	89a6                	mv	s3,s1
    8000619e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061a0:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061a4:	00391513          	sll	a0,s2,0x3
    800061a8:	e4040593          	add	a1,s0,-448
    800061ac:	e4843783          	ld	a5,-440(s0)
    800061b0:	953e                	add	a0,a0,a5
    800061b2:	ffffd097          	auipc	ra,0xffffd
    800061b6:	f34080e7          	jalr	-204(ra) # 800030e6 <fetchaddr>
    800061ba:	02054a63          	bltz	a0,800061ee <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800061be:	e4043783          	ld	a5,-448(s0)
    800061c2:	c3b9                	beqz	a5,80006208 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	91e080e7          	jalr	-1762(ra) # 80000ae2 <kalloc>
    800061cc:	85aa                	mv	a1,a0
    800061ce:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061d2:	cd11                	beqz	a0,800061ee <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061d4:	6605                	lui	a2,0x1
    800061d6:	e4043503          	ld	a0,-448(s0)
    800061da:	ffffd097          	auipc	ra,0xffffd
    800061de:	f5e080e7          	jalr	-162(ra) # 80003138 <fetchstr>
    800061e2:	00054663          	bltz	a0,800061ee <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800061e6:	0905                	add	s2,s2,1
    800061e8:	09a1                	add	s3,s3,8
    800061ea:	fb491de3          	bne	s2,s4,800061a4 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ee:	f5040913          	add	s2,s0,-176
    800061f2:	6088                	ld	a0,0(s1)
    800061f4:	c921                	beqz	a0,80006244 <sys_exec+0xf6>
    kfree(argv[i]);
    800061f6:	ffffa097          	auipc	ra,0xffffa
    800061fa:	7ee080e7          	jalr	2030(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061fe:	04a1                	add	s1,s1,8
    80006200:	ff2499e3          	bne	s1,s2,800061f2 <sys_exec+0xa4>
  return -1;
    80006204:	557d                	li	a0,-1
    80006206:	a081                	j	80006246 <sys_exec+0xf8>
      argv[i] = 0;
    80006208:	0009079b          	sext.w	a5,s2
    8000620c:	078e                	sll	a5,a5,0x3
    8000620e:	fd078793          	add	a5,a5,-48
    80006212:	97a2                	add	a5,a5,s0
    80006214:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006218:	e5040593          	add	a1,s0,-432
    8000621c:	f5040513          	add	a0,s0,-176
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	194080e7          	jalr	404(ra) # 800053b4 <exec>
    80006228:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000622a:	f5040993          	add	s3,s0,-176
    8000622e:	6088                	ld	a0,0(s1)
    80006230:	c901                	beqz	a0,80006240 <sys_exec+0xf2>
    kfree(argv[i]);
    80006232:	ffffa097          	auipc	ra,0xffffa
    80006236:	7b2080e7          	jalr	1970(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000623a:	04a1                	add	s1,s1,8
    8000623c:	ff3499e3          	bne	s1,s3,8000622e <sys_exec+0xe0>
  return ret;
    80006240:	854a                	mv	a0,s2
    80006242:	a011                	j	80006246 <sys_exec+0xf8>
  return -1;
    80006244:	557d                	li	a0,-1
}
    80006246:	70fa                	ld	ra,440(sp)
    80006248:	745a                	ld	s0,432(sp)
    8000624a:	74ba                	ld	s1,424(sp)
    8000624c:	791a                	ld	s2,416(sp)
    8000624e:	69fa                	ld	s3,408(sp)
    80006250:	6a5a                	ld	s4,400(sp)
    80006252:	6139                	add	sp,sp,448
    80006254:	8082                	ret

0000000080006256 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006256:	7139                	add	sp,sp,-64
    80006258:	fc06                	sd	ra,56(sp)
    8000625a:	f822                	sd	s0,48(sp)
    8000625c:	f426                	sd	s1,40(sp)
    8000625e:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	746080e7          	jalr	1862(ra) # 800019a6 <myproc>
    80006268:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000626a:	fd840593          	add	a1,s0,-40
    8000626e:	4501                	li	a0,0
    80006270:	ffffd097          	auipc	ra,0xffffd
    80006274:	f34080e7          	jalr	-204(ra) # 800031a4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006278:	fc840593          	add	a1,s0,-56
    8000627c:	fd040513          	add	a0,s0,-48
    80006280:	fffff097          	auipc	ra,0xfffff
    80006284:	dea080e7          	jalr	-534(ra) # 8000506a <pipealloc>
    return -1;
    80006288:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000628a:	0c054463          	bltz	a0,80006352 <sys_pipe+0xfc>
  fd0 = -1;
    8000628e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006292:	fd043503          	ld	a0,-48(s0)
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	524080e7          	jalr	1316(ra) # 800057ba <fdalloc>
    8000629e:	fca42223          	sw	a0,-60(s0)
    800062a2:	08054b63          	bltz	a0,80006338 <sys_pipe+0xe2>
    800062a6:	fc843503          	ld	a0,-56(s0)
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	510080e7          	jalr	1296(ra) # 800057ba <fdalloc>
    800062b2:	fca42023          	sw	a0,-64(s0)
    800062b6:	06054863          	bltz	a0,80006326 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062ba:	4691                	li	a3,4
    800062bc:	fc440613          	add	a2,s0,-60
    800062c0:	fd843583          	ld	a1,-40(s0)
    800062c4:	68a8                	ld	a0,80(s1)
    800062c6:	ffffb097          	auipc	ra,0xffffb
    800062ca:	3a0080e7          	jalr	928(ra) # 80001666 <copyout>
    800062ce:	02054063          	bltz	a0,800062ee <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062d2:	4691                	li	a3,4
    800062d4:	fc040613          	add	a2,s0,-64
    800062d8:	fd843583          	ld	a1,-40(s0)
    800062dc:	0591                	add	a1,a1,4
    800062de:	68a8                	ld	a0,80(s1)
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	386080e7          	jalr	902(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062e8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062ea:	06055463          	bgez	a0,80006352 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800062ee:	fc442783          	lw	a5,-60(s0)
    800062f2:	07e9                	add	a5,a5,26
    800062f4:	078e                	sll	a5,a5,0x3
    800062f6:	97a6                	add	a5,a5,s1
    800062f8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062fc:	fc042783          	lw	a5,-64(s0)
    80006300:	07e9                	add	a5,a5,26
    80006302:	078e                	sll	a5,a5,0x3
    80006304:	94be                	add	s1,s1,a5
    80006306:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000630a:	fd043503          	ld	a0,-48(s0)
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	a30080e7          	jalr	-1488(ra) # 80004d3e <fileclose>
    fileclose(wf);
    80006316:	fc843503          	ld	a0,-56(s0)
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	a24080e7          	jalr	-1500(ra) # 80004d3e <fileclose>
    return -1;
    80006322:	57fd                	li	a5,-1
    80006324:	a03d                	j	80006352 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006326:	fc442783          	lw	a5,-60(s0)
    8000632a:	0007c763          	bltz	a5,80006338 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000632e:	07e9                	add	a5,a5,26
    80006330:	078e                	sll	a5,a5,0x3
    80006332:	97a6                	add	a5,a5,s1
    80006334:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006338:	fd043503          	ld	a0,-48(s0)
    8000633c:	fffff097          	auipc	ra,0xfffff
    80006340:	a02080e7          	jalr	-1534(ra) # 80004d3e <fileclose>
    fileclose(wf);
    80006344:	fc843503          	ld	a0,-56(s0)
    80006348:	fffff097          	auipc	ra,0xfffff
    8000634c:	9f6080e7          	jalr	-1546(ra) # 80004d3e <fileclose>
    return -1;
    80006350:	57fd                	li	a5,-1
}
    80006352:	853e                	mv	a0,a5
    80006354:	70e2                	ld	ra,56(sp)
    80006356:	7442                	ld	s0,48(sp)
    80006358:	74a2                	ld	s1,40(sp)
    8000635a:	6121                	add	sp,sp,64
    8000635c:	8082                	ret
	...

0000000080006360 <kernelvec>:
    80006360:	7111                	add	sp,sp,-256
    80006362:	e006                	sd	ra,0(sp)
    80006364:	e40a                	sd	sp,8(sp)
    80006366:	e80e                	sd	gp,16(sp)
    80006368:	ec12                	sd	tp,24(sp)
    8000636a:	f016                	sd	t0,32(sp)
    8000636c:	f41a                	sd	t1,40(sp)
    8000636e:	f81e                	sd	t2,48(sp)
    80006370:	fc22                	sd	s0,56(sp)
    80006372:	e0a6                	sd	s1,64(sp)
    80006374:	e4aa                	sd	a0,72(sp)
    80006376:	e8ae                	sd	a1,80(sp)
    80006378:	ecb2                	sd	a2,88(sp)
    8000637a:	f0b6                	sd	a3,96(sp)
    8000637c:	f4ba                	sd	a4,104(sp)
    8000637e:	f8be                	sd	a5,112(sp)
    80006380:	fcc2                	sd	a6,120(sp)
    80006382:	e146                	sd	a7,128(sp)
    80006384:	e54a                	sd	s2,136(sp)
    80006386:	e94e                	sd	s3,144(sp)
    80006388:	ed52                	sd	s4,152(sp)
    8000638a:	f156                	sd	s5,160(sp)
    8000638c:	f55a                	sd	s6,168(sp)
    8000638e:	f95e                	sd	s7,176(sp)
    80006390:	fd62                	sd	s8,184(sp)
    80006392:	e1e6                	sd	s9,192(sp)
    80006394:	e5ea                	sd	s10,200(sp)
    80006396:	e9ee                	sd	s11,208(sp)
    80006398:	edf2                	sd	t3,216(sp)
    8000639a:	f1f6                	sd	t4,224(sp)
    8000639c:	f5fa                	sd	t5,232(sp)
    8000639e:	f9fe                	sd	t6,240(sp)
    800063a0:	c13fc0ef          	jal	80002fb2 <kerneltrap>
    800063a4:	6082                	ld	ra,0(sp)
    800063a6:	6122                	ld	sp,8(sp)
    800063a8:	61c2                	ld	gp,16(sp)
    800063aa:	7282                	ld	t0,32(sp)
    800063ac:	7322                	ld	t1,40(sp)
    800063ae:	73c2                	ld	t2,48(sp)
    800063b0:	7462                	ld	s0,56(sp)
    800063b2:	6486                	ld	s1,64(sp)
    800063b4:	6526                	ld	a0,72(sp)
    800063b6:	65c6                	ld	a1,80(sp)
    800063b8:	6666                	ld	a2,88(sp)
    800063ba:	7686                	ld	a3,96(sp)
    800063bc:	7726                	ld	a4,104(sp)
    800063be:	77c6                	ld	a5,112(sp)
    800063c0:	7866                	ld	a6,120(sp)
    800063c2:	688a                	ld	a7,128(sp)
    800063c4:	692a                	ld	s2,136(sp)
    800063c6:	69ca                	ld	s3,144(sp)
    800063c8:	6a6a                	ld	s4,152(sp)
    800063ca:	7a8a                	ld	s5,160(sp)
    800063cc:	7b2a                	ld	s6,168(sp)
    800063ce:	7bca                	ld	s7,176(sp)
    800063d0:	7c6a                	ld	s8,184(sp)
    800063d2:	6c8e                	ld	s9,192(sp)
    800063d4:	6d2e                	ld	s10,200(sp)
    800063d6:	6dce                	ld	s11,208(sp)
    800063d8:	6e6e                	ld	t3,216(sp)
    800063da:	7e8e                	ld	t4,224(sp)
    800063dc:	7f2e                	ld	t5,232(sp)
    800063de:	7fce                	ld	t6,240(sp)
    800063e0:	6111                	add	sp,sp,256
    800063e2:	10200073          	sret
    800063e6:	00000013          	nop
    800063ea:	00000013          	nop
    800063ee:	0001                	nop

00000000800063f0 <timervec>:
    800063f0:	34051573          	csrrw	a0,mscratch,a0
    800063f4:	e10c                	sd	a1,0(a0)
    800063f6:	e510                	sd	a2,8(a0)
    800063f8:	e914                	sd	a3,16(a0)
    800063fa:	6d0c                	ld	a1,24(a0)
    800063fc:	7110                	ld	a2,32(a0)
    800063fe:	6194                	ld	a3,0(a1)
    80006400:	96b2                	add	a3,a3,a2
    80006402:	e194                	sd	a3,0(a1)
    80006404:	4589                	li	a1,2
    80006406:	14459073          	csrw	sip,a1
    8000640a:	6914                	ld	a3,16(a0)
    8000640c:	6510                	ld	a2,8(a0)
    8000640e:	610c                	ld	a1,0(a0)
    80006410:	34051573          	csrrw	a0,mscratch,a0
    80006414:	30200073          	mret
	...

000000008000641a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000641a:	1141                	add	sp,sp,-16
    8000641c:	e422                	sd	s0,8(sp)
    8000641e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006420:	0c0007b7          	lui	a5,0xc000
    80006424:	4705                	li	a4,1
    80006426:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006428:	c3d8                	sw	a4,4(a5)
}
    8000642a:	6422                	ld	s0,8(sp)
    8000642c:	0141                	add	sp,sp,16
    8000642e:	8082                	ret

0000000080006430 <plicinithart>:

void
plicinithart(void)
{
    80006430:	1141                	add	sp,sp,-16
    80006432:	e406                	sd	ra,8(sp)
    80006434:	e022                	sd	s0,0(sp)
    80006436:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	542080e7          	jalr	1346(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006440:	0085171b          	sllw	a4,a0,0x8
    80006444:	0c0027b7          	lui	a5,0xc002
    80006448:	97ba                	add	a5,a5,a4
    8000644a:	40200713          	li	a4,1026
    8000644e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006452:	00d5151b          	sllw	a0,a0,0xd
    80006456:	0c2017b7          	lui	a5,0xc201
    8000645a:	97aa                	add	a5,a5,a0
    8000645c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006460:	60a2                	ld	ra,8(sp)
    80006462:	6402                	ld	s0,0(sp)
    80006464:	0141                	add	sp,sp,16
    80006466:	8082                	ret

0000000080006468 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006468:	1141                	add	sp,sp,-16
    8000646a:	e406                	sd	ra,8(sp)
    8000646c:	e022                	sd	s0,0(sp)
    8000646e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006470:	ffffb097          	auipc	ra,0xffffb
    80006474:	50a080e7          	jalr	1290(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006478:	00d5151b          	sllw	a0,a0,0xd
    8000647c:	0c2017b7          	lui	a5,0xc201
    80006480:	97aa                	add	a5,a5,a0
  return irq;
}
    80006482:	43c8                	lw	a0,4(a5)
    80006484:	60a2                	ld	ra,8(sp)
    80006486:	6402                	ld	s0,0(sp)
    80006488:	0141                	add	sp,sp,16
    8000648a:	8082                	ret

000000008000648c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000648c:	1101                	add	sp,sp,-32
    8000648e:	ec06                	sd	ra,24(sp)
    80006490:	e822                	sd	s0,16(sp)
    80006492:	e426                	sd	s1,8(sp)
    80006494:	1000                	add	s0,sp,32
    80006496:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006498:	ffffb097          	auipc	ra,0xffffb
    8000649c:	4e2080e7          	jalr	1250(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064a0:	00d5151b          	sllw	a0,a0,0xd
    800064a4:	0c2017b7          	lui	a5,0xc201
    800064a8:	97aa                	add	a5,a5,a0
    800064aa:	c3c4                	sw	s1,4(a5)
}
    800064ac:	60e2                	ld	ra,24(sp)
    800064ae:	6442                	ld	s0,16(sp)
    800064b0:	64a2                	ld	s1,8(sp)
    800064b2:	6105                	add	sp,sp,32
    800064b4:	8082                	ret

00000000800064b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064b6:	1141                	add	sp,sp,-16
    800064b8:	e406                	sd	ra,8(sp)
    800064ba:	e022                	sd	s0,0(sp)
    800064bc:	0800                	add	s0,sp,16
  if(i >= NUM)
    800064be:	479d                	li	a5,7
    800064c0:	04a7cc63          	blt	a5,a0,80006518 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800064c4:	0001f797          	auipc	a5,0x1f
    800064c8:	58c78793          	add	a5,a5,1420 # 80025a50 <disk>
    800064cc:	97aa                	add	a5,a5,a0
    800064ce:	0187c783          	lbu	a5,24(a5)
    800064d2:	ebb9                	bnez	a5,80006528 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064d4:	00451693          	sll	a3,a0,0x4
    800064d8:	0001f797          	auipc	a5,0x1f
    800064dc:	57878793          	add	a5,a5,1400 # 80025a50 <disk>
    800064e0:	6398                	ld	a4,0(a5)
    800064e2:	9736                	add	a4,a4,a3
    800064e4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800064e8:	6398                	ld	a4,0(a5)
    800064ea:	9736                	add	a4,a4,a3
    800064ec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800064f0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800064f4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800064f8:	97aa                	add	a5,a5,a0
    800064fa:	4705                	li	a4,1
    800064fc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006500:	0001f517          	auipc	a0,0x1f
    80006504:	56850513          	add	a0,a0,1384 # 80025a68 <disk+0x18>
    80006508:	ffffc097          	auipc	ra,0xffffc
    8000650c:	040080e7          	jalr	64(ra) # 80002548 <wakeup>
}
    80006510:	60a2                	ld	ra,8(sp)
    80006512:	6402                	ld	s0,0(sp)
    80006514:	0141                	add	sp,sp,16
    80006516:	8082                	ret
    panic("free_desc 1");
    80006518:	00002517          	auipc	a0,0x2
    8000651c:	2a850513          	add	a0,a0,680 # 800087c0 <syscalls+0x338>
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	01c080e7          	jalr	28(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006528:	00002517          	auipc	a0,0x2
    8000652c:	2a850513          	add	a0,a0,680 # 800087d0 <syscalls+0x348>
    80006530:	ffffa097          	auipc	ra,0xffffa
    80006534:	00c080e7          	jalr	12(ra) # 8000053c <panic>

0000000080006538 <virtio_disk_init>:
{
    80006538:	1101                	add	sp,sp,-32
    8000653a:	ec06                	sd	ra,24(sp)
    8000653c:	e822                	sd	s0,16(sp)
    8000653e:	e426                	sd	s1,8(sp)
    80006540:	e04a                	sd	s2,0(sp)
    80006542:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006544:	00002597          	auipc	a1,0x2
    80006548:	29c58593          	add	a1,a1,668 # 800087e0 <syscalls+0x358>
    8000654c:	0001f517          	auipc	a0,0x1f
    80006550:	62c50513          	add	a0,a0,1580 # 80025b78 <disk+0x128>
    80006554:	ffffa097          	auipc	ra,0xffffa
    80006558:	5ee080e7          	jalr	1518(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000655c:	100017b7          	lui	a5,0x10001
    80006560:	4398                	lw	a4,0(a5)
    80006562:	2701                	sext.w	a4,a4
    80006564:	747277b7          	lui	a5,0x74727
    80006568:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000656c:	14f71b63          	bne	a4,a5,800066c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006570:	100017b7          	lui	a5,0x10001
    80006574:	43dc                	lw	a5,4(a5)
    80006576:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006578:	4709                	li	a4,2
    8000657a:	14e79463          	bne	a5,a4,800066c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000657e:	100017b7          	lui	a5,0x10001
    80006582:	479c                	lw	a5,8(a5)
    80006584:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006586:	12e79e63          	bne	a5,a4,800066c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000658a:	100017b7          	lui	a5,0x10001
    8000658e:	47d8                	lw	a4,12(a5)
    80006590:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006592:	554d47b7          	lui	a5,0x554d4
    80006596:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000659a:	12f71463          	bne	a4,a5,800066c2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000659e:	100017b7          	lui	a5,0x10001
    800065a2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065a6:	4705                	li	a4,1
    800065a8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065aa:	470d                	li	a4,3
    800065ac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065ae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065b0:	c7ffe6b7          	lui	a3,0xc7ffe
    800065b4:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8bcf>
    800065b8:	8f75                	and	a4,a4,a3
    800065ba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065bc:	472d                	li	a4,11
    800065be:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800065c0:	5bbc                	lw	a5,112(a5)
    800065c2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800065c6:	8ba1                	and	a5,a5,8
    800065c8:	10078563          	beqz	a5,800066d2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065cc:	100017b7          	lui	a5,0x10001
    800065d0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800065d4:	43fc                	lw	a5,68(a5)
    800065d6:	2781                	sext.w	a5,a5
    800065d8:	10079563          	bnez	a5,800066e2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065dc:	100017b7          	lui	a5,0x10001
    800065e0:	5bdc                	lw	a5,52(a5)
    800065e2:	2781                	sext.w	a5,a5
  if(max == 0)
    800065e4:	10078763          	beqz	a5,800066f2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800065e8:	471d                	li	a4,7
    800065ea:	10f77c63          	bgeu	a4,a5,80006702 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	4f4080e7          	jalr	1268(ra) # 80000ae2 <kalloc>
    800065f6:	0001f497          	auipc	s1,0x1f
    800065fa:	45a48493          	add	s1,s1,1114 # 80025a50 <disk>
    800065fe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	4e2080e7          	jalr	1250(ra) # 80000ae2 <kalloc>
    80006608:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	4d8080e7          	jalr	1240(ra) # 80000ae2 <kalloc>
    80006612:	87aa                	mv	a5,a0
    80006614:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006616:	6088                	ld	a0,0(s1)
    80006618:	cd6d                	beqz	a0,80006712 <virtio_disk_init+0x1da>
    8000661a:	0001f717          	auipc	a4,0x1f
    8000661e:	43e73703          	ld	a4,1086(a4) # 80025a58 <disk+0x8>
    80006622:	cb65                	beqz	a4,80006712 <virtio_disk_init+0x1da>
    80006624:	c7fd                	beqz	a5,80006712 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006626:	6605                	lui	a2,0x1
    80006628:	4581                	li	a1,0
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	6a4080e7          	jalr	1700(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006632:	0001f497          	auipc	s1,0x1f
    80006636:	41e48493          	add	s1,s1,1054 # 80025a50 <disk>
    8000663a:	6605                	lui	a2,0x1
    8000663c:	4581                	li	a1,0
    8000663e:	6488                	ld	a0,8(s1)
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	68e080e7          	jalr	1678(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006648:	6605                	lui	a2,0x1
    8000664a:	4581                	li	a1,0
    8000664c:	6888                	ld	a0,16(s1)
    8000664e:	ffffa097          	auipc	ra,0xffffa
    80006652:	680080e7          	jalr	1664(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006656:	100017b7          	lui	a5,0x10001
    8000665a:	4721                	li	a4,8
    8000665c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000665e:	4098                	lw	a4,0(s1)
    80006660:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006664:	40d8                	lw	a4,4(s1)
    80006666:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000666a:	6498                	ld	a4,8(s1)
    8000666c:	0007069b          	sext.w	a3,a4
    80006670:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006674:	9701                	sra	a4,a4,0x20
    80006676:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000667a:	6898                	ld	a4,16(s1)
    8000667c:	0007069b          	sext.w	a3,a4
    80006680:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006684:	9701                	sra	a4,a4,0x20
    80006686:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000668a:	4705                	li	a4,1
    8000668c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000668e:	00e48c23          	sb	a4,24(s1)
    80006692:	00e48ca3          	sb	a4,25(s1)
    80006696:	00e48d23          	sb	a4,26(s1)
    8000669a:	00e48da3          	sb	a4,27(s1)
    8000669e:	00e48e23          	sb	a4,28(s1)
    800066a2:	00e48ea3          	sb	a4,29(s1)
    800066a6:	00e48f23          	sb	a4,30(s1)
    800066aa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800066ae:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800066b2:	0727a823          	sw	s2,112(a5)
}
    800066b6:	60e2                	ld	ra,24(sp)
    800066b8:	6442                	ld	s0,16(sp)
    800066ba:	64a2                	ld	s1,8(sp)
    800066bc:	6902                	ld	s2,0(sp)
    800066be:	6105                	add	sp,sp,32
    800066c0:	8082                	ret
    panic("could not find virtio disk");
    800066c2:	00002517          	auipc	a0,0x2
    800066c6:	12e50513          	add	a0,a0,302 # 800087f0 <syscalls+0x368>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	e72080e7          	jalr	-398(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800066d2:	00002517          	auipc	a0,0x2
    800066d6:	13e50513          	add	a0,a0,318 # 80008810 <syscalls+0x388>
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	e62080e7          	jalr	-414(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800066e2:	00002517          	auipc	a0,0x2
    800066e6:	14e50513          	add	a0,a0,334 # 80008830 <syscalls+0x3a8>
    800066ea:	ffffa097          	auipc	ra,0xffffa
    800066ee:	e52080e7          	jalr	-430(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800066f2:	00002517          	auipc	a0,0x2
    800066f6:	15e50513          	add	a0,a0,350 # 80008850 <syscalls+0x3c8>
    800066fa:	ffffa097          	auipc	ra,0xffffa
    800066fe:	e42080e7          	jalr	-446(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006702:	00002517          	auipc	a0,0x2
    80006706:	16e50513          	add	a0,a0,366 # 80008870 <syscalls+0x3e8>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	e32080e7          	jalr	-462(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006712:	00002517          	auipc	a0,0x2
    80006716:	17e50513          	add	a0,a0,382 # 80008890 <syscalls+0x408>
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	e22080e7          	jalr	-478(ra) # 8000053c <panic>

0000000080006722 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006722:	7159                	add	sp,sp,-112
    80006724:	f486                	sd	ra,104(sp)
    80006726:	f0a2                	sd	s0,96(sp)
    80006728:	eca6                	sd	s1,88(sp)
    8000672a:	e8ca                	sd	s2,80(sp)
    8000672c:	e4ce                	sd	s3,72(sp)
    8000672e:	e0d2                	sd	s4,64(sp)
    80006730:	fc56                	sd	s5,56(sp)
    80006732:	f85a                	sd	s6,48(sp)
    80006734:	f45e                	sd	s7,40(sp)
    80006736:	f062                	sd	s8,32(sp)
    80006738:	ec66                	sd	s9,24(sp)
    8000673a:	e86a                	sd	s10,16(sp)
    8000673c:	1880                	add	s0,sp,112
    8000673e:	8a2a                	mv	s4,a0
    80006740:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006742:	00c52c83          	lw	s9,12(a0)
    80006746:	001c9c9b          	sllw	s9,s9,0x1
    8000674a:	1c82                	sll	s9,s9,0x20
    8000674c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006750:	0001f517          	auipc	a0,0x1f
    80006754:	42850513          	add	a0,a0,1064 # 80025b78 <disk+0x128>
    80006758:	ffffa097          	auipc	ra,0xffffa
    8000675c:	47a080e7          	jalr	1146(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006760:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006762:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006764:	0001fb17          	auipc	s6,0x1f
    80006768:	2ecb0b13          	add	s6,s6,748 # 80025a50 <disk>
  for(int i = 0; i < 3; i++){
    8000676c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000676e:	0001fc17          	auipc	s8,0x1f
    80006772:	40ac0c13          	add	s8,s8,1034 # 80025b78 <disk+0x128>
    80006776:	a095                	j	800067da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006778:	00fb0733          	add	a4,s6,a5
    8000677c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006780:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006782:	0207c563          	bltz	a5,800067ac <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006786:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006788:	0591                	add	a1,a1,4
    8000678a:	05560d63          	beq	a2,s5,800067e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000678e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006790:	0001f717          	auipc	a4,0x1f
    80006794:	2c070713          	add	a4,a4,704 # 80025a50 <disk>
    80006798:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000679a:	01874683          	lbu	a3,24(a4)
    8000679e:	fee9                	bnez	a3,80006778 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800067a0:	2785                	addw	a5,a5,1
    800067a2:	0705                	add	a4,a4,1
    800067a4:	fe979be3          	bne	a5,s1,8000679a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800067a8:	57fd                	li	a5,-1
    800067aa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800067ac:	00c05e63          	blez	a2,800067c8 <virtio_disk_rw+0xa6>
    800067b0:	060a                	sll	a2,a2,0x2
    800067b2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800067b6:	0009a503          	lw	a0,0(s3)
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	cfc080e7          	jalr	-772(ra) # 800064b6 <free_desc>
      for(int j = 0; j < i; j++)
    800067c2:	0991                	add	s3,s3,4
    800067c4:	ffa999e3          	bne	s3,s10,800067b6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067c8:	85e2                	mv	a1,s8
    800067ca:	0001f517          	auipc	a0,0x1f
    800067ce:	29e50513          	add	a0,a0,670 # 80025a68 <disk+0x18>
    800067d2:	ffffc097          	auipc	ra,0xffffc
    800067d6:	d12080e7          	jalr	-750(ra) # 800024e4 <sleep>
  for(int i = 0; i < 3; i++){
    800067da:	f9040993          	add	s3,s0,-112
{
    800067de:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800067e0:	864a                	mv	a2,s2
    800067e2:	b775                	j	8000678e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067e4:	f9042503          	lw	a0,-112(s0)
    800067e8:	00a50713          	add	a4,a0,10
    800067ec:	0712                	sll	a4,a4,0x4

  if(write)
    800067ee:	0001f797          	auipc	a5,0x1f
    800067f2:	26278793          	add	a5,a5,610 # 80025a50 <disk>
    800067f6:	00e786b3          	add	a3,a5,a4
    800067fa:	01703633          	snez	a2,s7
    800067fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006800:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006804:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006808:	f6070613          	add	a2,a4,-160
    8000680c:	6394                	ld	a3,0(a5)
    8000680e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006810:	00870593          	add	a1,a4,8
    80006814:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006816:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006818:	0007b803          	ld	a6,0(a5)
    8000681c:	9642                	add	a2,a2,a6
    8000681e:	46c1                	li	a3,16
    80006820:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006822:	4585                	li	a1,1
    80006824:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006828:	f9442683          	lw	a3,-108(s0)
    8000682c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006830:	0692                	sll	a3,a3,0x4
    80006832:	9836                	add	a6,a6,a3
    80006834:	058a0613          	add	a2,s4,88
    80006838:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000683c:	0007b803          	ld	a6,0(a5)
    80006840:	96c2                	add	a3,a3,a6
    80006842:	40000613          	li	a2,1024
    80006846:	c690                	sw	a2,8(a3)
  if(write)
    80006848:	001bb613          	seqz	a2,s7
    8000684c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006850:	00166613          	or	a2,a2,1
    80006854:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006858:	f9842603          	lw	a2,-104(s0)
    8000685c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006860:	00250693          	add	a3,a0,2
    80006864:	0692                	sll	a3,a3,0x4
    80006866:	96be                	add	a3,a3,a5
    80006868:	58fd                	li	a7,-1
    8000686a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000686e:	0612                	sll	a2,a2,0x4
    80006870:	9832                	add	a6,a6,a2
    80006872:	f9070713          	add	a4,a4,-112
    80006876:	973e                	add	a4,a4,a5
    80006878:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000687c:	6398                	ld	a4,0(a5)
    8000687e:	9732                	add	a4,a4,a2
    80006880:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006882:	4609                	li	a2,2
    80006884:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006888:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000688c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006890:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006894:	6794                	ld	a3,8(a5)
    80006896:	0026d703          	lhu	a4,2(a3)
    8000689a:	8b1d                	and	a4,a4,7
    8000689c:	0706                	sll	a4,a4,0x1
    8000689e:	96ba                	add	a3,a3,a4
    800068a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800068a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068a8:	6798                	ld	a4,8(a5)
    800068aa:	00275783          	lhu	a5,2(a4)
    800068ae:	2785                	addw	a5,a5,1
    800068b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068b8:	100017b7          	lui	a5,0x10001
    800068bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068c0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800068c4:	0001f917          	auipc	s2,0x1f
    800068c8:	2b490913          	add	s2,s2,692 # 80025b78 <disk+0x128>
  while(b->disk == 1) {
    800068cc:	4485                	li	s1,1
    800068ce:	00b79c63          	bne	a5,a1,800068e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800068d2:	85ca                	mv	a1,s2
    800068d4:	8552                	mv	a0,s4
    800068d6:	ffffc097          	auipc	ra,0xffffc
    800068da:	c0e080e7          	jalr	-1010(ra) # 800024e4 <sleep>
  while(b->disk == 1) {
    800068de:	004a2783          	lw	a5,4(s4)
    800068e2:	fe9788e3          	beq	a5,s1,800068d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800068e6:	f9042903          	lw	s2,-112(s0)
    800068ea:	00290713          	add	a4,s2,2
    800068ee:	0712                	sll	a4,a4,0x4
    800068f0:	0001f797          	auipc	a5,0x1f
    800068f4:	16078793          	add	a5,a5,352 # 80025a50 <disk>
    800068f8:	97ba                	add	a5,a5,a4
    800068fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800068fe:	0001f997          	auipc	s3,0x1f
    80006902:	15298993          	add	s3,s3,338 # 80025a50 <disk>
    80006906:	00491713          	sll	a4,s2,0x4
    8000690a:	0009b783          	ld	a5,0(s3)
    8000690e:	97ba                	add	a5,a5,a4
    80006910:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006914:	854a                	mv	a0,s2
    80006916:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000691a:	00000097          	auipc	ra,0x0
    8000691e:	b9c080e7          	jalr	-1124(ra) # 800064b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006922:	8885                	and	s1,s1,1
    80006924:	f0ed                	bnez	s1,80006906 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006926:	0001f517          	auipc	a0,0x1f
    8000692a:	25250513          	add	a0,a0,594 # 80025b78 <disk+0x128>
    8000692e:	ffffa097          	auipc	ra,0xffffa
    80006932:	358080e7          	jalr	856(ra) # 80000c86 <release>
}
    80006936:	70a6                	ld	ra,104(sp)
    80006938:	7406                	ld	s0,96(sp)
    8000693a:	64e6                	ld	s1,88(sp)
    8000693c:	6946                	ld	s2,80(sp)
    8000693e:	69a6                	ld	s3,72(sp)
    80006940:	6a06                	ld	s4,64(sp)
    80006942:	7ae2                	ld	s5,56(sp)
    80006944:	7b42                	ld	s6,48(sp)
    80006946:	7ba2                	ld	s7,40(sp)
    80006948:	7c02                	ld	s8,32(sp)
    8000694a:	6ce2                	ld	s9,24(sp)
    8000694c:	6d42                	ld	s10,16(sp)
    8000694e:	6165                	add	sp,sp,112
    80006950:	8082                	ret

0000000080006952 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006952:	1101                	add	sp,sp,-32
    80006954:	ec06                	sd	ra,24(sp)
    80006956:	e822                	sd	s0,16(sp)
    80006958:	e426                	sd	s1,8(sp)
    8000695a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000695c:	0001f497          	auipc	s1,0x1f
    80006960:	0f448493          	add	s1,s1,244 # 80025a50 <disk>
    80006964:	0001f517          	auipc	a0,0x1f
    80006968:	21450513          	add	a0,a0,532 # 80025b78 <disk+0x128>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	266080e7          	jalr	614(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006974:	10001737          	lui	a4,0x10001
    80006978:	533c                	lw	a5,96(a4)
    8000697a:	8b8d                	and	a5,a5,3
    8000697c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000697e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006982:	689c                	ld	a5,16(s1)
    80006984:	0204d703          	lhu	a4,32(s1)
    80006988:	0027d783          	lhu	a5,2(a5)
    8000698c:	04f70863          	beq	a4,a5,800069dc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006990:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006994:	6898                	ld	a4,16(s1)
    80006996:	0204d783          	lhu	a5,32(s1)
    8000699a:	8b9d                	and	a5,a5,7
    8000699c:	078e                	sll	a5,a5,0x3
    8000699e:	97ba                	add	a5,a5,a4
    800069a0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069a2:	00278713          	add	a4,a5,2
    800069a6:	0712                	sll	a4,a4,0x4
    800069a8:	9726                	add	a4,a4,s1
    800069aa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800069ae:	e721                	bnez	a4,800069f6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069b0:	0789                	add	a5,a5,2
    800069b2:	0792                	sll	a5,a5,0x4
    800069b4:	97a6                	add	a5,a5,s1
    800069b6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800069b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069bc:	ffffc097          	auipc	ra,0xffffc
    800069c0:	b8c080e7          	jalr	-1140(ra) # 80002548 <wakeup>

    disk.used_idx += 1;
    800069c4:	0204d783          	lhu	a5,32(s1)
    800069c8:	2785                	addw	a5,a5,1
    800069ca:	17c2                	sll	a5,a5,0x30
    800069cc:	93c1                	srl	a5,a5,0x30
    800069ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069d2:	6898                	ld	a4,16(s1)
    800069d4:	00275703          	lhu	a4,2(a4)
    800069d8:	faf71ce3          	bne	a4,a5,80006990 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800069dc:	0001f517          	auipc	a0,0x1f
    800069e0:	19c50513          	add	a0,a0,412 # 80025b78 <disk+0x128>
    800069e4:	ffffa097          	auipc	ra,0xffffa
    800069e8:	2a2080e7          	jalr	674(ra) # 80000c86 <release>
}
    800069ec:	60e2                	ld	ra,24(sp)
    800069ee:	6442                	ld	s0,16(sp)
    800069f0:	64a2                	ld	s1,8(sp)
    800069f2:	6105                	add	sp,sp,32
    800069f4:	8082                	ret
      panic("virtio_disk_intr status");
    800069f6:	00002517          	auipc	a0,0x2
    800069fa:	eb250513          	add	a0,a0,-334 # 800088a8 <syscalls+0x420>
    800069fe:	ffffa097          	auipc	ra,0xffffa
    80006a02:	b3e080e7          	jalr	-1218(ra) # 8000053c <panic>
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
