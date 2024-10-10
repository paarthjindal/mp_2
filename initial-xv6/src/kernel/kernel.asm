
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8f070713          	add	a4,a4,-1808 # 80008940 <timer_scratch>
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
    80000066:	f0e78793          	add	a5,a5,-242 # 80005f70 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda04f>
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
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3dc080e7          	jalr	988(ra) # 80002506 <either_copyin>
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
    80000188:	8fc50513          	add	a0,a0,-1796 # 80010a80 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8ec48493          	add	s1,s1,-1812 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	97c90913          	add	s2,s2,-1668 # 80010b18 <cons+0x98>
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
    800001c0:	17c080e7          	jalr	380(ra) # 80002338 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	eba080e7          	jalr	-326(ra) # 80002084 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	8a270713          	add	a4,a4,-1886 # 80010a80 <cons>
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
    80000214:	2a0080e7          	jalr	672(ra) # 800024b0 <either_copyout>
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
    8000022c:	85850513          	add	a0,a0,-1960 # 80010a80 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	84250513          	add	a0,a0,-1982 # 80010a80 <cons>
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
    80000272:	8af72523          	sw	a5,-1878(a4) # 80010b18 <cons+0x98>
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
    800002cc:	7b850513          	add	a0,a0,1976 # 80010a80 <cons>
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
    800002f2:	26e080e7          	jalr	622(ra) # 8000255c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	78a50513          	add	a0,a0,1930 # 80010a80 <cons>
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
    8000031e:	76670713          	add	a4,a4,1894 # 80010a80 <cons>
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
    80000348:	73c78793          	add	a5,a5,1852 # 80010a80 <cons>
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
    80000376:	7a67a783          	lw	a5,1958(a5) # 80010b18 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6fa70713          	add	a4,a4,1786 # 80010a80 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6ea48493          	add	s1,s1,1770 # 80010a80 <cons>
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
    800003d6:	6ae70713          	add	a4,a4,1710 # 80010a80 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	72f72c23          	sw	a5,1848(a4) # 80010b20 <cons+0xa0>
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
    80000412:	67278793          	add	a5,a5,1650 # 80010a80 <cons>
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
    80000436:	6ec7a523          	sw	a2,1770(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	6de50513          	add	a0,a0,1758 # 80010b18 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	ca6080e7          	jalr	-858(ra) # 800020e8 <wakeup>
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
    80000460:	62450513          	add	a0,a0,1572 # 80010a80 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00023797          	auipc	a5,0x23
    80000478:	1a478793          	add	a5,a5,420 # 80023618 <devsw>
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
    8000054c:	5e07ac23          	sw	zero,1528(a5) # 80010b40 <pr+0x18>
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
    80000580:	38f72223          	sw	a5,900(a4) # 80008900 <panicked>
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
    800005bc:	588dad83          	lw	s11,1416(s11) # 80010b40 <pr+0x18>
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
    800005fa:	53250513          	add	a0,a0,1330 # 80010b28 <pr>
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
    80000758:	3d450513          	add	a0,a0,980 # 80010b28 <pr>
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
    80000774:	3b848493          	add	s1,s1,952 # 80010b28 <pr>
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
    800007d4:	37850513          	add	a0,a0,888 # 80010b48 <uart_tx_lock>
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
    80000800:	1047a783          	lw	a5,260(a5) # 80008900 <panicked>
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
    80000838:	0d47b783          	ld	a5,212(a5) # 80008908 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	0d473703          	ld	a4,212(a4) # 80008910 <uart_tx_w>
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
    80000862:	2eaa0a13          	add	s4,s4,746 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	0a248493          	add	s1,s1,162 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	0a298993          	add	s3,s3,162 # 80008910 <uart_tx_w>
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
    80000894:	858080e7          	jalr	-1960(ra) # 800020e8 <wakeup>
    
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
    800008d0:	27c50513          	add	a0,a0,636 # 80010b48 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0247a783          	lw	a5,36(a5) # 80008900 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	02a73703          	ld	a4,42(a4) # 80008910 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	01a7b783          	ld	a5,26(a5) # 80008908 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	24e98993          	add	s3,s3,590 # 80010b48 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	00648493          	add	s1,s1,6 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	00690913          	add	s2,s2,6 # 80008910 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	76a080e7          	jalr	1898(ra) # 80002084 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	21848493          	add	s1,s1,536 # 80010b48 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	fce7b623          	sd	a4,-52(a5) # 80008910 <uart_tx_w>
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
    800009ba:	19248493          	add	s1,s1,402 # 80010b48 <uart_tx_lock>
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
    800009f8:	00024797          	auipc	a5,0x24
    800009fc:	db878793          	add	a5,a5,-584 # 800247b0 <end>
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
    80000a1c:	16890913          	add	s2,s2,360 # 80010b80 <kmem>
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
    80000aba:	0ca50513          	add	a0,a0,202 # 80010b80 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00024517          	auipc	a0,0x24
    80000ace:	ce650513          	add	a0,a0,-794 # 800247b0 <end>
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
    80000af0:	09448493          	add	s1,s1,148 # 80010b80 <kmem>
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
    80000b08:	07c50513          	add	a0,a0,124 # 80010b80 <kmem>
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
    80000b34:	05050513          	add	a0,a0,80 # 80010b80 <kmem>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda851>
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
    80000e86:	a9670713          	add	a4,a4,-1386 # 80008918 <started>
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
    80000ebc:	990080e7          	jalr	-1648(ra) # 80002848 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	0f0080e7          	jalr	240(ra) # 80005fb0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	00a080e7          	jalr	10(ra) # 80001ed2 <scheduler>
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
    80000f34:	8f0080e7          	jalr	-1808(ra) # 80002820 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	910080e7          	jalr	-1776(ra) # 80002848 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	05a080e7          	jalr	90(ra) # 80005f9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	068080e7          	jalr	104(ra) # 80005fb0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	260080e7          	jalr	608(ra) # 800031b0 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	8fe080e7          	jalr	-1794(ra) # 80003856 <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	874080e7          	jalr	-1932(ra) # 800047d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	150080e7          	jalr	336(ra) # 800060b8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d44080e7          	jalr	-700(ra) # 80001cb4 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	98f72d23          	sw	a5,-1638(a4) # 80008918 <started>
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
    80000f96:	98e7b783          	ld	a5,-1650(a5) # 80008920 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda847>
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
    80001252:	6ca7b923          	sd	a0,1746(a5) # 80008920 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda850>
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
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	78a48493          	add	s1,s1,1930 # 80010fd0 <proc>
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
    80001860:	00018a17          	auipc	s4,0x18
    80001864:	b70a0a13          	add	s4,s4,-1168 # 800193d0 <tickslock>
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
    8000189a:	21048493          	add	s1,s1,528
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
    800018e6:	2be50513          	add	a0,a0,702 # 80010ba0 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	2be50513          	add	a0,a0,702 # 80010bb8 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	6c648493          	add	s1,s1,1734 # 80010fd0 <proc>
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
    8000192c:	00018997          	auipc	s3,0x18
    80001930:	aa498993          	add	s3,s3,-1372 # 800193d0 <tickslock>
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
    8000195e:	21048493          	add	s1,s1,528
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
    8000199a:	23a50513          	add	a0,a0,570 # 80010bd0 <cpus>
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
    800019c2:	1e270713          	add	a4,a4,482 # 80010ba0 <pid_lock>
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
    800019fa:	e9a7a783          	lw	a5,-358(a5) # 80008890 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	e60080e7          	jalr	-416(ra) # 80002860 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e807a023          	sw	zero,-384(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	dbc080e7          	jalr	-580(ra) # 800037d6 <fsinit>
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
    80001a34:	17090913          	add	s2,s2,368 # 80010ba0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e5278793          	add	a5,a5,-430 # 80008894 <nextpid>
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
    80001bbc:	0000f497          	auipc	s1,0xf
    80001bc0:	41448493          	add	s1,s1,1044 # 80010fd0 <proc>
    80001bc4:	00018917          	auipc	s2,0x18
    80001bc8:	80c90913          	add	s2,s2,-2036 # 800193d0 <tickslock>
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
    80001be4:	21048493          	add	s1,s1,528
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0; // No UNUSED process found, return 0
    80001bec:	4481                	li	s1,0
    80001bee:	a061                	j	80001c76 <allocproc+0xc6>
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
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	ed2080e7          	jalr	-302(ra) # 80000ae2 <kalloc>
    80001c18:	892a                	mv	s2,a0
    80001c1a:	eca8                	sd	a0,88(s1)
    80001c1c:	c525                	beqz	a0,80001c84 <allocproc+0xd4>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e4a080e7          	jalr	-438(ra) # 80001a6a <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c2c:	c925                	beqz	a0,80001c9c <allocproc+0xec>
  memset(&p->context, 0, sizeof(p->context));
    80001c2e:	07000613          	li	a2,112
    80001c32:	4581                	li	a1,0
    80001c34:	06048513          	add	a0,s1,96
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	096080e7          	jalr	150(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c40:	00000797          	auipc	a5,0x0
    80001c44:	d9e78793          	add	a5,a5,-610 # 800019de <forkret>
    80001c48:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4a:	60bc                	ld	a5,64(s1)
    80001c4c:	6705                	lui	a4,0x1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;     // Initialize runtime
    80001c52:	1604a423          	sw	zero,360(s1)
  p->etime = 0;     // Initialize exit time
    80001c56:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks; // Record creation time
    80001c5a:	00007797          	auipc	a5,0x7
    80001c5e:	cd67a783          	lw	a5,-810(a5) # 80008930 <ticks>
    80001c62:	16f4a623          	sw	a5,364(s1)
  p->alarm_interval = 0;
    80001c66:	1e04a823          	sw	zero,496(s1)
  p->alarm_handler = 0;
    80001c6a:	1e04bc23          	sd	zero,504(s1)
  p->ticks_count = 0;
    80001c6e:	2004a023          	sw	zero,512(s1)
  p->alarm_on = 0;
    80001c72:	2004a223          	sw	zero,516(s1)
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	add	sp,sp,32
    80001c82:	8082                	ret
    freeproc(p);       // Clean up if allocation fails
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ed2080e7          	jalr	-302(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	ff6080e7          	jalr	-10(ra) # 80000c86 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	bff1                	j	80001c76 <allocproc+0xc6>
    freeproc(p);       // Clean up if allocation fails
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	eba080e7          	jalr	-326(ra) # 80001b58 <freeproc>
    release(&p->lock); // Release lock
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	fde080e7          	jalr	-34(ra) # 80000c86 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7d1                	j	80001c76 <allocproc+0xc6>

0000000080001cb4 <userinit>:
{
    80001cb4:	1101                	add	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	add	s0,sp,32
  p = allocproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	ef2080e7          	jalr	-270(ra) # 80001bb0 <allocproc>
    80001cc6:	84aa                	mv	s1,a0
  initproc = p;
    80001cc8:	00007797          	auipc	a5,0x7
    80001ccc:	c6a7b023          	sd	a0,-928(a5) # 80008928 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd0:	03400613          	li	a2,52
    80001cd4:	00007597          	auipc	a1,0x7
    80001cd8:	bcc58593          	add	a1,a1,-1076 # 800088a0 <initcode>
    80001cdc:	6928                	ld	a0,80(a0)
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	672080e7          	jalr	1650(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001ce6:	6785                	lui	a5,0x1
    80001ce8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cea:	6cb8                	ld	a4,88(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf0:	6cb8                	ld	a4,88(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	add	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	15848513          	add	a0,s1,344
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	114080e7          	jalr	276(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	add	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	4e2080e7          	jalr	1250(ra) # 800041f4 <namei>
    80001d1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	f62080e7          	jalr	-158(ra) # 80000c86 <release>
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	add	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <growproc>:
{
    80001d36:	1101                	add	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	e04a                	sd	s2,0(sp)
    80001d40:	1000                	add	s0,sp,32
    80001d42:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	c62080e7          	jalr	-926(ra) # 800019a6 <myproc>
    80001d4c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d4e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d50:	01204c63          	bgtz	s2,80001d68 <growproc+0x32>
  else if (n < 0)
    80001d54:	02094663          	bltz	s2,80001d80 <growproc+0x4a>
  p->sz = sz;
    80001d58:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	60e2                	ld	ra,24(sp)
    80001d5e:	6442                	ld	s0,16(sp)
    80001d60:	64a2                	ld	s1,8(sp)
    80001d62:	6902                	ld	s2,0(sp)
    80001d64:	6105                	add	sp,sp,32
    80001d66:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d68:	4691                	li	a3,4
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	69a080e7          	jalr	1690(ra) # 8000140a <uvmalloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	fd79                	bnez	a0,80001d58 <growproc+0x22>
      return -1;
    80001d7c:	557d                	li	a0,-1
    80001d7e:	bff9                	j	80001d5c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d80:	00b90633          	add	a2,s2,a1
    80001d84:	6928                	ld	a0,80(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	63c080e7          	jalr	1596(ra) # 800013c2 <uvmdealloc>
    80001d8e:	85aa                	mv	a1,a0
    80001d90:	b7e1                	j	80001d58 <growproc+0x22>

0000000080001d92 <fork>:
{
    80001d92:	7139                	add	sp,sp,-64
    80001d94:	fc06                	sd	ra,56(sp)
    80001d96:	f822                	sd	s0,48(sp)
    80001d98:	f426                	sd	s1,40(sp)
    80001d9a:	f04a                	sd	s2,32(sp)
    80001d9c:	ec4e                	sd	s3,24(sp)
    80001d9e:	e852                	sd	s4,16(sp)
    80001da0:	e456                	sd	s5,8(sp)
    80001da2:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c02080e7          	jalr	-1022(ra) # 800019a6 <myproc>
    80001dac:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	e02080e7          	jalr	-510(ra) # 80001bb0 <allocproc>
    80001db6:	10050c63          	beqz	a0,80001ece <fork+0x13c>
    80001dba:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dbc:	048ab603          	ld	a2,72(s5)
    80001dc0:	692c                	ld	a1,80(a0)
    80001dc2:	050ab503          	ld	a0,80(s5)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	79c080e7          	jalr	1948(ra) # 80001562 <uvmcopy>
    80001dce:	04054863          	bltz	a0,80001e1e <fork+0x8c>
  np->sz = p->sz;
    80001dd2:	048ab783          	ld	a5,72(s5)
    80001dd6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dda:	058ab683          	ld	a3,88(s5)
    80001dde:	87b6                	mv	a5,a3
    80001de0:	058a3703          	ld	a4,88(s4)
    80001de4:	12068693          	add	a3,a3,288
    80001de8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dec:	6788                	ld	a0,8(a5)
    80001dee:	6b8c                	ld	a1,16(a5)
    80001df0:	6f90                	ld	a2,24(a5)
    80001df2:	01073023          	sd	a6,0(a4)
    80001df6:	e708                	sd	a0,8(a4)
    80001df8:	eb0c                	sd	a1,16(a4)
    80001dfa:	ef10                	sd	a2,24(a4)
    80001dfc:	02078793          	add	a5,a5,32
    80001e00:	02070713          	add	a4,a4,32
    80001e04:	fed792e3          	bne	a5,a3,80001de8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e08:	058a3783          	ld	a5,88(s4)
    80001e0c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e10:	0d0a8493          	add	s1,s5,208
    80001e14:	0d0a0913          	add	s2,s4,208
    80001e18:	150a8993          	add	s3,s5,336
    80001e1c:	a00d                	j	80001e3e <fork+0xac>
    freeproc(np);
    80001e1e:	8552                	mv	a0,s4
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	d38080e7          	jalr	-712(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e28:	8552                	mv	a0,s4
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e5c080e7          	jalr	-420(ra) # 80000c86 <release>
    return -1;
    80001e32:	597d                	li	s2,-1
    80001e34:	a059                	j	80001eba <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e36:	04a1                	add	s1,s1,8
    80001e38:	0921                	add	s2,s2,8
    80001e3a:	01348b63          	beq	s1,s3,80001e50 <fork+0xbe>
    if (p->ofile[i])
    80001e3e:	6088                	ld	a0,0(s1)
    80001e40:	d97d                	beqz	a0,80001e36 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e42:	00003097          	auipc	ra,0x3
    80001e46:	a24080e7          	jalr	-1500(ra) # 80004866 <filedup>
    80001e4a:	00a93023          	sd	a0,0(s2)
    80001e4e:	b7e5                	j	80001e36 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e50:	150ab503          	ld	a0,336(s5)
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	bbc080e7          	jalr	-1092(ra) # 80003a10 <idup>
    80001e5c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e60:	4641                	li	a2,16
    80001e62:	158a8593          	add	a1,s5,344
    80001e66:	158a0513          	add	a0,s4,344
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	fac080e7          	jalr	-84(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e72:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	e0e080e7          	jalr	-498(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e80:	0000f497          	auipc	s1,0xf
    80001e84:	d3848493          	add	s1,s1,-712 # 80010bb8 <wait_lock>
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d48080e7          	jalr	-696(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e92:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dee080e7          	jalr	-530(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d30080e7          	jalr	-720(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001eaa:	478d                	li	a5,3
    80001eac:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dd4080e7          	jalr	-556(ra) # 80000c86 <release>
}
    80001eba:	854a                	mv	a0,s2
    80001ebc:	70e2                	ld	ra,56(sp)
    80001ebe:	7442                	ld	s0,48(sp)
    80001ec0:	74a2                	ld	s1,40(sp)
    80001ec2:	7902                	ld	s2,32(sp)
    80001ec4:	69e2                	ld	s3,24(sp)
    80001ec6:	6a42                	ld	s4,16(sp)
    80001ec8:	6aa2                	ld	s5,8(sp)
    80001eca:	6121                	add	sp,sp,64
    80001ecc:	8082                	ret
    return -1;
    80001ece:	597d                	li	s2,-1
    80001ed0:	b7ed                	j	80001eba <fork+0x128>

0000000080001ed2 <scheduler>:
{
    80001ed2:	7139                	add	sp,sp,-64
    80001ed4:	fc06                	sd	ra,56(sp)
    80001ed6:	f822                	sd	s0,48(sp)
    80001ed8:	f426                	sd	s1,40(sp)
    80001eda:	f04a                	sd	s2,32(sp)
    80001edc:	ec4e                	sd	s3,24(sp)
    80001ede:	e852                	sd	s4,16(sp)
    80001ee0:	e456                	sd	s5,8(sp)
    80001ee2:	e05a                	sd	s6,0(sp)
    80001ee4:	0080                	add	s0,sp,64
    80001ee6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eea:	00779a93          	sll	s5,a5,0x7
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	cb270713          	add	a4,a4,-846 # 80010ba0 <pid_lock>
    80001ef6:	9756                	add	a4,a4,s5
    80001ef8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001efc:	0000f717          	auipc	a4,0xf
    80001f00:	cdc70713          	add	a4,a4,-804 # 80010bd8 <cpus+0x8>
    80001f04:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f06:	498d                	li	s3,3
        p->state = RUNNING;
    80001f08:	4b11                	li	s6,4
        c->proc = p;
    80001f0a:	079e                	sll	a5,a5,0x7
    80001f0c:	0000fa17          	auipc	s4,0xf
    80001f10:	c94a0a13          	add	s4,s4,-876 # 80010ba0 <pid_lock>
    80001f14:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f16:	00017917          	auipc	s2,0x17
    80001f1a:	4ba90913          	add	s2,s2,1210 # 800193d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f22:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f26:	10079073          	csrw	sstatus,a5
    80001f2a:	0000f497          	auipc	s1,0xf
    80001f2e:	0a648493          	add	s1,s1,166 # 80010fd0 <proc>
    80001f32:	a811                	j	80001f46 <scheduler+0x74>
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d50080e7          	jalr	-688(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f3e:	21048493          	add	s1,s1,528
    80001f42:	fd248ee3          	beq	s1,s2,80001f1e <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	c8a080e7          	jalr	-886(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x62>
        p->state = RUNNING;
    80001f56:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f5a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5e:	06048593          	add	a1,s1,96
    80001f62:	8556                	mv	a0,s5
    80001f64:	00001097          	auipc	ra,0x1
    80001f68:	852080e7          	jalr	-1966(ra) # 800027b6 <swtch>
        c->proc = 0;
    80001f6c:	020a3823          	sd	zero,48(s4)
    80001f70:	b7d1                	j	80001f34 <scheduler+0x62>

0000000080001f72 <sched>:
{
    80001f72:	7179                	add	sp,sp,-48
    80001f74:	f406                	sd	ra,40(sp)
    80001f76:	f022                	sd	s0,32(sp)
    80001f78:	ec26                	sd	s1,24(sp)
    80001f7a:	e84a                	sd	s2,16(sp)
    80001f7c:	e44e                	sd	s3,8(sp)
    80001f7e:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	a26080e7          	jalr	-1498(ra) # 800019a6 <myproc>
    80001f88:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	bce080e7          	jalr	-1074(ra) # 80000b58 <holding>
    80001f92:	c93d                	beqz	a0,80002008 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	sll	a5,a5,0x7
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	c0670713          	add	a4,a4,-1018 # 80010ba0 <pid_lock>
    80001fa2:	97ba                	add	a5,a5,a4
    80001fa4:	0a87a703          	lw	a4,168(a5)
    80001fa8:	4785                	li	a5,1
    80001faa:	06f71763          	bne	a4,a5,80002018 <sched+0xa6>
  if (p->state == RUNNING)
    80001fae:	4c98                	lw	a4,24(s1)
    80001fb0:	4791                	li	a5,4
    80001fb2:	06f70b63          	beq	a4,a5,80002028 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fba:	8b89                	and	a5,a5,2
  if (intr_get())
    80001fbc:	efb5                	bnez	a5,80002038 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fc0:	0000f917          	auipc	s2,0xf
    80001fc4:	be090913          	add	s2,s2,-1056 # 80010ba0 <pid_lock>
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	sll	a5,a5,0x7
    80001fcc:	97ca                	add	a5,a5,s2
    80001fce:	0ac7a983          	lw	s3,172(a5)
    80001fd2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	sll	a5,a5,0x7
    80001fd8:	0000f597          	auipc	a1,0xf
    80001fdc:	c0058593          	add	a1,a1,-1024 # 80010bd8 <cpus+0x8>
    80001fe0:	95be                	add	a1,a1,a5
    80001fe2:	06048513          	add	a0,s1,96
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	7d0080e7          	jalr	2000(ra) # 800027b6 <swtch>
    80001fee:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	sll	a5,a5,0x7
    80001ff4:	993e                	add	s2,s2,a5
    80001ff6:	0b392623          	sw	s3,172(s2)
}
    80001ffa:	70a2                	ld	ra,40(sp)
    80001ffc:	7402                	ld	s0,32(sp)
    80001ffe:	64e2                	ld	s1,24(sp)
    80002000:	6942                	ld	s2,16(sp)
    80002002:	69a2                	ld	s3,8(sp)
    80002004:	6145                	add	sp,sp,48
    80002006:	8082                	ret
    panic("sched p->lock");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	21050513          	add	a0,a0,528 # 80008218 <digits+0x1d8>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52c080e7          	jalr	1324(ra) # 8000053c <panic>
    panic("sched locks");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	21050513          	add	a0,a0,528 # 80008228 <digits+0x1e8>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51c080e7          	jalr	1308(ra) # 8000053c <panic>
    panic("sched running");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	21050513          	add	a0,a0,528 # 80008238 <digits+0x1f8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50c080e7          	jalr	1292(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	21050513          	add	a0,a0,528 # 80008248 <digits+0x208>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fc080e7          	jalr	1276(ra) # 8000053c <panic>

0000000080002048 <yield>:
{
    80002048:	1101                	add	sp,sp,-32
    8000204a:	ec06                	sd	ra,24(sp)
    8000204c:	e822                	sd	s0,16(sp)
    8000204e:	e426                	sd	s1,8(sp)
    80002050:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	954080e7          	jalr	-1708(ra) # 800019a6 <myproc>
    8000205a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b76080e7          	jalr	-1162(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002064:	478d                	li	a5,3
    80002066:	cc9c                	sw	a5,24(s1)
  sched();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	f0a080e7          	jalr	-246(ra) # 80001f72 <sched>
  release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c14080e7          	jalr	-1004(ra) # 80000c86 <release>
}
    8000207a:	60e2                	ld	ra,24(sp)
    8000207c:	6442                	ld	s0,16(sp)
    8000207e:	64a2                	ld	s1,8(sp)
    80002080:	6105                	add	sp,sp,32
    80002082:	8082                	ret

0000000080002084 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002084:	7179                	add	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	add	s0,sp,48
    80002092:	89aa                	mv	s3,a0
    80002094:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	910080e7          	jalr	-1776(ra) # 800019a6 <myproc>
    8000209e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b32080e7          	jalr	-1230(ra) # 80000bd2 <acquire>
  release(lk);
    800020a8:	854a                	mv	a0,s2
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bdc080e7          	jalr	-1060(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800020b2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b6:	4789                	li	a5,2
    800020b8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	eb8080e7          	jalr	-328(ra) # 80001f72 <sched>

  // Tidy up.
  p->chan = 0;
    800020c2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bbe080e7          	jalr	-1090(ra) # 80000c86 <release>
  acquire(lk);
    800020d0:	854a                	mv	a0,s2
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b00080e7          	jalr	-1280(ra) # 80000bd2 <acquire>
}
    800020da:	70a2                	ld	ra,40(sp)
    800020dc:	7402                	ld	s0,32(sp)
    800020de:	64e2                	ld	s1,24(sp)
    800020e0:	6942                	ld	s2,16(sp)
    800020e2:	69a2                	ld	s3,8(sp)
    800020e4:	6145                	add	sp,sp,48
    800020e6:	8082                	ret

00000000800020e8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020e8:	7139                	add	sp,sp,-64
    800020ea:	fc06                	sd	ra,56(sp)
    800020ec:	f822                	sd	s0,48(sp)
    800020ee:	f426                	sd	s1,40(sp)
    800020f0:	f04a                	sd	s2,32(sp)
    800020f2:	ec4e                	sd	s3,24(sp)
    800020f4:	e852                	sd	s4,16(sp)
    800020f6:	e456                	sd	s5,8(sp)
    800020f8:	0080                	add	s0,sp,64
    800020fa:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020fc:	0000f497          	auipc	s1,0xf
    80002100:	ed448493          	add	s1,s1,-300 # 80010fd0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002104:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002106:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002108:	00017917          	auipc	s2,0x17
    8000210c:	2c890913          	add	s2,s2,712 # 800193d0 <tickslock>
    80002110:	a811                	j	80002124 <wakeup+0x3c>
      }
      release(&p->lock);
    80002112:	8526                	mv	a0,s1
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	b72080e7          	jalr	-1166(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000211c:	21048493          	add	s1,s1,528
    80002120:	03248663          	beq	s1,s2,8000214c <wakeup+0x64>
    if (p != myproc())
    80002124:	00000097          	auipc	ra,0x0
    80002128:	882080e7          	jalr	-1918(ra) # 800019a6 <myproc>
    8000212c:	fea488e3          	beq	s1,a0,8000211c <wakeup+0x34>
      acquire(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	aa0080e7          	jalr	-1376(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000213a:	4c9c                	lw	a5,24(s1)
    8000213c:	fd379be3          	bne	a5,s3,80002112 <wakeup+0x2a>
    80002140:	709c                	ld	a5,32(s1)
    80002142:	fd4798e3          	bne	a5,s4,80002112 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002146:	0154ac23          	sw	s5,24(s1)
    8000214a:	b7e1                	j	80002112 <wakeup+0x2a>
    }
  }
}
    8000214c:	70e2                	ld	ra,56(sp)
    8000214e:	7442                	ld	s0,48(sp)
    80002150:	74a2                	ld	s1,40(sp)
    80002152:	7902                	ld	s2,32(sp)
    80002154:	69e2                	ld	s3,24(sp)
    80002156:	6a42                	ld	s4,16(sp)
    80002158:	6aa2                	ld	s5,8(sp)
    8000215a:	6121                	add	sp,sp,64
    8000215c:	8082                	ret

000000008000215e <reparent>:
{
    8000215e:	7179                	add	sp,sp,-48
    80002160:	f406                	sd	ra,40(sp)
    80002162:	f022                	sd	s0,32(sp)
    80002164:	ec26                	sd	s1,24(sp)
    80002166:	e84a                	sd	s2,16(sp)
    80002168:	e44e                	sd	s3,8(sp)
    8000216a:	e052                	sd	s4,0(sp)
    8000216c:	1800                	add	s0,sp,48
    8000216e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002170:	0000f497          	auipc	s1,0xf
    80002174:	e6048493          	add	s1,s1,-416 # 80010fd0 <proc>
      pp->parent = initproc;
    80002178:	00006a17          	auipc	s4,0x6
    8000217c:	7b0a0a13          	add	s4,s4,1968 # 80008928 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002180:	00017997          	auipc	s3,0x17
    80002184:	25098993          	add	s3,s3,592 # 800193d0 <tickslock>
    80002188:	a029                	j	80002192 <reparent+0x34>
    8000218a:	21048493          	add	s1,s1,528
    8000218e:	01348d63          	beq	s1,s3,800021a8 <reparent+0x4a>
    if (pp->parent == p)
    80002192:	7c9c                	ld	a5,56(s1)
    80002194:	ff279be3          	bne	a5,s2,8000218a <reparent+0x2c>
      pp->parent = initproc;
    80002198:	000a3503          	ld	a0,0(s4)
    8000219c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	f4a080e7          	jalr	-182(ra) # 800020e8 <wakeup>
    800021a6:	b7d5                	j	8000218a <reparent+0x2c>
}
    800021a8:	70a2                	ld	ra,40(sp)
    800021aa:	7402                	ld	s0,32(sp)
    800021ac:	64e2                	ld	s1,24(sp)
    800021ae:	6942                	ld	s2,16(sp)
    800021b0:	69a2                	ld	s3,8(sp)
    800021b2:	6a02                	ld	s4,0(sp)
    800021b4:	6145                	add	sp,sp,48
    800021b6:	8082                	ret

00000000800021b8 <exit>:
{
    800021b8:	7179                	add	sp,sp,-48
    800021ba:	f406                	sd	ra,40(sp)
    800021bc:	f022                	sd	s0,32(sp)
    800021be:	ec26                	sd	s1,24(sp)
    800021c0:	e84a                	sd	s2,16(sp)
    800021c2:	e44e                	sd	s3,8(sp)
    800021c4:	e052                	sd	s4,0(sp)
    800021c6:	1800                	add	s0,sp,48
    800021c8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	7dc080e7          	jalr	2012(ra) # 800019a6 <myproc>
    800021d2:	89aa                	mv	s3,a0
  if (p == initproc)
    800021d4:	00006797          	auipc	a5,0x6
    800021d8:	7547b783          	ld	a5,1876(a5) # 80008928 <initproc>
    800021dc:	0d050493          	add	s1,a0,208
    800021e0:	15050913          	add	s2,a0,336
    800021e4:	02a79363          	bne	a5,a0,8000220a <exit+0x52>
    panic("init exiting");
    800021e8:	00006517          	auipc	a0,0x6
    800021ec:	07850513          	add	a0,a0,120 # 80008260 <digits+0x220>
    800021f0:	ffffe097          	auipc	ra,0xffffe
    800021f4:	34c080e7          	jalr	844(ra) # 8000053c <panic>
      fileclose(f);
    800021f8:	00002097          	auipc	ra,0x2
    800021fc:	6c0080e7          	jalr	1728(ra) # 800048b8 <fileclose>
      p->ofile[fd] = 0;
    80002200:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002204:	04a1                	add	s1,s1,8
    80002206:	01248563          	beq	s1,s2,80002210 <exit+0x58>
    if (p->ofile[fd])
    8000220a:	6088                	ld	a0,0(s1)
    8000220c:	f575                	bnez	a0,800021f8 <exit+0x40>
    8000220e:	bfdd                	j	80002204 <exit+0x4c>
  begin_op();
    80002210:	00002097          	auipc	ra,0x2
    80002214:	1e4080e7          	jalr	484(ra) # 800043f4 <begin_op>
  iput(p->cwd);
    80002218:	1509b503          	ld	a0,336(s3)
    8000221c:	00002097          	auipc	ra,0x2
    80002220:	9ec080e7          	jalr	-1556(ra) # 80003c08 <iput>
  end_op();
    80002224:	00002097          	auipc	ra,0x2
    80002228:	24a080e7          	jalr	586(ra) # 8000446e <end_op>
  p->cwd = 0;
    8000222c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002230:	0000f497          	auipc	s1,0xf
    80002234:	98848493          	add	s1,s1,-1656 # 80010bb8 <wait_lock>
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	998080e7          	jalr	-1640(ra) # 80000bd2 <acquire>
  reparent(p);
    80002242:	854e                	mv	a0,s3
    80002244:	00000097          	auipc	ra,0x0
    80002248:	f1a080e7          	jalr	-230(ra) # 8000215e <reparent>
  wakeup(p->parent);
    8000224c:	0389b503          	ld	a0,56(s3)
    80002250:	00000097          	auipc	ra,0x0
    80002254:	e98080e7          	jalr	-360(ra) # 800020e8 <wakeup>
  acquire(&p->lock);
    80002258:	854e                	mv	a0,s3
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	978080e7          	jalr	-1672(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002262:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002266:	4795                	li	a5,5
    80002268:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000226c:	00006797          	auipc	a5,0x6
    80002270:	6c47a783          	lw	a5,1732(a5) # 80008930 <ticks>
    80002274:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a0c080e7          	jalr	-1524(ra) # 80000c86 <release>
  sched();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	cf0080e7          	jalr	-784(ra) # 80001f72 <sched>
  panic("zombie exit");
    8000228a:	00006517          	auipc	a0,0x6
    8000228e:	fe650513          	add	a0,a0,-26 # 80008270 <digits+0x230>
    80002292:	ffffe097          	auipc	ra,0xffffe
    80002296:	2aa080e7          	jalr	682(ra) # 8000053c <panic>

000000008000229a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000229a:	7179                	add	sp,sp,-48
    8000229c:	f406                	sd	ra,40(sp)
    8000229e:	f022                	sd	s0,32(sp)
    800022a0:	ec26                	sd	s1,24(sp)
    800022a2:	e84a                	sd	s2,16(sp)
    800022a4:	e44e                	sd	s3,8(sp)
    800022a6:	1800                	add	s0,sp,48
    800022a8:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022aa:	0000f497          	auipc	s1,0xf
    800022ae:	d2648493          	add	s1,s1,-730 # 80010fd0 <proc>
    800022b2:	00017997          	auipc	s3,0x17
    800022b6:	11e98993          	add	s3,s3,286 # 800193d0 <tickslock>
  {
    acquire(&p->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	916080e7          	jalr	-1770(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    800022c4:	589c                	lw	a5,48(s1)
    800022c6:	01278d63          	beq	a5,s2,800022e0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9ba080e7          	jalr	-1606(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022d4:	21048493          	add	s1,s1,528
    800022d8:	ff3491e3          	bne	s1,s3,800022ba <kill+0x20>
  }
  return -1;
    800022dc:	557d                	li	a0,-1
    800022de:	a829                	j	800022f8 <kill+0x5e>
      p->killed = 1;
    800022e0:	4785                	li	a5,1
    800022e2:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022e4:	4c98                	lw	a4,24(s1)
    800022e6:	4789                	li	a5,2
    800022e8:	00f70f63          	beq	a4,a5,80002306 <kill+0x6c>
      release(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	998080e7          	jalr	-1640(ra) # 80000c86 <release>
      return 0;
    800022f6:	4501                	li	a0,0
}
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6145                	add	sp,sp,48
    80002304:	8082                	ret
        p->state = RUNNABLE;
    80002306:	478d                	li	a5,3
    80002308:	cc9c                	sw	a5,24(s1)
    8000230a:	b7cd                	j	800022ec <kill+0x52>

000000008000230c <setkilled>:

void setkilled(struct proc *p)
{
    8000230c:	1101                	add	sp,sp,-32
    8000230e:	ec06                	sd	ra,24(sp)
    80002310:	e822                	sd	s0,16(sp)
    80002312:	e426                	sd	s1,8(sp)
    80002314:	1000                	add	s0,sp,32
    80002316:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8ba080e7          	jalr	-1862(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002320:	4785                	li	a5,1
    80002322:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	960080e7          	jalr	-1696(ra) # 80000c86 <release>
}
    8000232e:	60e2                	ld	ra,24(sp)
    80002330:	6442                	ld	s0,16(sp)
    80002332:	64a2                	ld	s1,8(sp)
    80002334:	6105                	add	sp,sp,32
    80002336:	8082                	ret

0000000080002338 <killed>:

int killed(struct proc *p)
{
    80002338:	1101                	add	sp,sp,-32
    8000233a:	ec06                	sd	ra,24(sp)
    8000233c:	e822                	sd	s0,16(sp)
    8000233e:	e426                	sd	s1,8(sp)
    80002340:	e04a                	sd	s2,0(sp)
    80002342:	1000                	add	s0,sp,32
    80002344:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	88c080e7          	jalr	-1908(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000234e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	932080e7          	jalr	-1742(ra) # 80000c86 <release>
  return k;
}
    8000235c:	854a                	mv	a0,s2
    8000235e:	60e2                	ld	ra,24(sp)
    80002360:	6442                	ld	s0,16(sp)
    80002362:	64a2                	ld	s1,8(sp)
    80002364:	6902                	ld	s2,0(sp)
    80002366:	6105                	add	sp,sp,32
    80002368:	8082                	ret

000000008000236a <wait>:
{
    8000236a:	715d                	add	sp,sp,-80
    8000236c:	e486                	sd	ra,72(sp)
    8000236e:	e0a2                	sd	s0,64(sp)
    80002370:	fc26                	sd	s1,56(sp)
    80002372:	f84a                	sd	s2,48(sp)
    80002374:	f44e                	sd	s3,40(sp)
    80002376:	f052                	sd	s4,32(sp)
    80002378:	ec56                	sd	s5,24(sp)
    8000237a:	e85a                	sd	s6,16(sp)
    8000237c:	e45e                	sd	s7,8(sp)
    8000237e:	e062                	sd	s8,0(sp)
    80002380:	0880                	add	s0,sp,80
    80002382:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	622080e7          	jalr	1570(ra) # 800019a6 <myproc>
    8000238c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000238e:	0000f517          	auipc	a0,0xf
    80002392:	82a50513          	add	a0,a0,-2006 # 80010bb8 <wait_lock>
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	83c080e7          	jalr	-1988(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000239e:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023a0:	4a95                	li	s5,5
        havekids = 1;
    800023a2:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023a4:	00017997          	auipc	s3,0x17
    800023a8:	02c98993          	add	s3,s3,44 # 800193d0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023ac:	0000fc17          	auipc	s8,0xf
    800023b0:	80cc0c13          	add	s8,s8,-2036 # 80010bb8 <wait_lock>
    800023b4:	a8f1                	j	80002490 <wait+0x126>
    800023b6:	17448793          	add	a5,s1,372
    800023ba:	17490713          	add	a4,s2,372
    800023be:	1f048613          	add	a2,s1,496
            p->syscall_count[i] = pp->syscall_count[i];
    800023c2:	4394                	lw	a3,0(a5)
    800023c4:	c314                	sw	a3,0(a4)
          for (int i = 0; i < 31; i++)
    800023c6:	0791                	add	a5,a5,4
    800023c8:	0711                	add	a4,a4,4
    800023ca:	fec79ce3          	bne	a5,a2,800023c2 <wait+0x58>
          pid = pp->pid;
    800023ce:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023d2:	000a0e63          	beqz	s4,800023ee <wait+0x84>
    800023d6:	4691                	li	a3,4
    800023d8:	02c48613          	add	a2,s1,44
    800023dc:	85d2                	mv	a1,s4
    800023de:	05093503          	ld	a0,80(s2)
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	284080e7          	jalr	644(ra) # 80001666 <copyout>
    800023ea:	04054163          	bltz	a0,8000242c <wait+0xc2>
          freeproc(pp);
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	768080e7          	jalr	1896(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	88c080e7          	jalr	-1908(ra) # 80000c86 <release>
          release(&wait_lock);
    80002402:	0000e517          	auipc	a0,0xe
    80002406:	7b650513          	add	a0,a0,1974 # 80010bb8 <wait_lock>
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	87c080e7          	jalr	-1924(ra) # 80000c86 <release>
}
    80002412:	854e                	mv	a0,s3
    80002414:	60a6                	ld	ra,72(sp)
    80002416:	6406                	ld	s0,64(sp)
    80002418:	74e2                	ld	s1,56(sp)
    8000241a:	7942                	ld	s2,48(sp)
    8000241c:	79a2                	ld	s3,40(sp)
    8000241e:	7a02                	ld	s4,32(sp)
    80002420:	6ae2                	ld	s5,24(sp)
    80002422:	6b42                	ld	s6,16(sp)
    80002424:	6ba2                	ld	s7,8(sp)
    80002426:	6c02                	ld	s8,0(sp)
    80002428:	6161                	add	sp,sp,80
    8000242a:	8082                	ret
            release(&pp->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	858080e7          	jalr	-1960(ra) # 80000c86 <release>
            release(&wait_lock);
    80002436:	0000e517          	auipc	a0,0xe
    8000243a:	78250513          	add	a0,a0,1922 # 80010bb8 <wait_lock>
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	848080e7          	jalr	-1976(ra) # 80000c86 <release>
            return -1;
    80002446:	59fd                	li	s3,-1
    80002448:	b7e9                	j	80002412 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000244a:	21048493          	add	s1,s1,528
    8000244e:	03348463          	beq	s1,s3,80002476 <wait+0x10c>
      if (pp->parent == p)
    80002452:	7c9c                	ld	a5,56(s1)
    80002454:	ff279be3          	bne	a5,s2,8000244a <wait+0xe0>
        acquire(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	778080e7          	jalr	1912(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002462:	4c9c                	lw	a5,24(s1)
    80002464:	f55789e3          	beq	a5,s5,800023b6 <wait+0x4c>
        release(&pp->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	81c080e7          	jalr	-2020(ra) # 80000c86 <release>
        havekids = 1;
    80002472:	875a                	mv	a4,s6
    80002474:	bfd9                	j	8000244a <wait+0xe0>
    if (!havekids || killed(p))
    80002476:	c31d                	beqz	a4,8000249c <wait+0x132>
    80002478:	854a                	mv	a0,s2
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	ebe080e7          	jalr	-322(ra) # 80002338 <killed>
    80002482:	ed09                	bnez	a0,8000249c <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002484:	85e2                	mv	a1,s8
    80002486:	854a                	mv	a0,s2
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	bfc080e7          	jalr	-1028(ra) # 80002084 <sleep>
    havekids = 0;
    80002490:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	b3e48493          	add	s1,s1,-1218 # 80010fd0 <proc>
    8000249a:	bf65                	j	80002452 <wait+0xe8>
      release(&wait_lock);
    8000249c:	0000e517          	auipc	a0,0xe
    800024a0:	71c50513          	add	a0,a0,1820 # 80010bb8 <wait_lock>
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7e2080e7          	jalr	2018(ra) # 80000c86 <release>
      return -1;
    800024ac:	59fd                	li	s3,-1
    800024ae:	b795                	j	80002412 <wait+0xa8>

00000000800024b0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024b0:	7179                	add	sp,sp,-48
    800024b2:	f406                	sd	ra,40(sp)
    800024b4:	f022                	sd	s0,32(sp)
    800024b6:	ec26                	sd	s1,24(sp)
    800024b8:	e84a                	sd	s2,16(sp)
    800024ba:	e44e                	sd	s3,8(sp)
    800024bc:	e052                	sd	s4,0(sp)
    800024be:	1800                	add	s0,sp,48
    800024c0:	84aa                	mv	s1,a0
    800024c2:	892e                	mv	s2,a1
    800024c4:	89b2                	mv	s3,a2
    800024c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	4de080e7          	jalr	1246(ra) # 800019a6 <myproc>
  if (user_dst)
    800024d0:	c08d                	beqz	s1,800024f2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024d2:	86d2                	mv	a3,s4
    800024d4:	864e                	mv	a2,s3
    800024d6:	85ca                	mv	a1,s2
    800024d8:	6928                	ld	a0,80(a0)
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	18c080e7          	jalr	396(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e2:	70a2                	ld	ra,40(sp)
    800024e4:	7402                	ld	s0,32(sp)
    800024e6:	64e2                	ld	s1,24(sp)
    800024e8:	6942                	ld	s2,16(sp)
    800024ea:	69a2                	ld	s3,8(sp)
    800024ec:	6a02                	ld	s4,0(sp)
    800024ee:	6145                	add	sp,sp,48
    800024f0:	8082                	ret
    memmove((char *)dst, src, len);
    800024f2:	000a061b          	sext.w	a2,s4
    800024f6:	85ce                	mv	a1,s3
    800024f8:	854a                	mv	a0,s2
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	830080e7          	jalr	-2000(ra) # 80000d2a <memmove>
    return 0;
    80002502:	8526                	mv	a0,s1
    80002504:	bff9                	j	800024e2 <either_copyout+0x32>

0000000080002506 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002506:	7179                	add	sp,sp,-48
    80002508:	f406                	sd	ra,40(sp)
    8000250a:	f022                	sd	s0,32(sp)
    8000250c:	ec26                	sd	s1,24(sp)
    8000250e:	e84a                	sd	s2,16(sp)
    80002510:	e44e                	sd	s3,8(sp)
    80002512:	e052                	sd	s4,0(sp)
    80002514:	1800                	add	s0,sp,48
    80002516:	892a                	mv	s2,a0
    80002518:	84ae                	mv	s1,a1
    8000251a:	89b2                	mv	s3,a2
    8000251c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	488080e7          	jalr	1160(ra) # 800019a6 <myproc>
  if (user_src)
    80002526:	c08d                	beqz	s1,80002548 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002528:	86d2                	mv	a3,s4
    8000252a:	864e                	mv	a2,s3
    8000252c:	85ca                	mv	a1,s2
    8000252e:	6928                	ld	a0,80(a0)
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	1c2080e7          	jalr	450(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6a02                	ld	s4,0(sp)
    80002544:	6145                	add	sp,sp,48
    80002546:	8082                	ret
    memmove(dst, (char *)src, len);
    80002548:	000a061b          	sext.w	a2,s4
    8000254c:	85ce                	mv	a1,s3
    8000254e:	854a                	mv	a0,s2
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	7da080e7          	jalr	2010(ra) # 80000d2a <memmove>
    return 0;
    80002558:	8526                	mv	a0,s1
    8000255a:	bff9                	j	80002538 <either_copyin+0x32>

000000008000255c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000255c:	715d                	add	sp,sp,-80
    8000255e:	e486                	sd	ra,72(sp)
    80002560:	e0a2                	sd	s0,64(sp)
    80002562:	fc26                	sd	s1,56(sp)
    80002564:	f84a                	sd	s2,48(sp)
    80002566:	f44e                	sd	s3,40(sp)
    80002568:	f052                	sd	s4,32(sp)
    8000256a:	ec56                	sd	s5,24(sp)
    8000256c:	e85a                	sd	s6,16(sp)
    8000256e:	e45e                	sd	s7,8(sp)
    80002570:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002572:	00006517          	auipc	a0,0x6
    80002576:	b5650513          	add	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	00c080e7          	jalr	12(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002582:	0000f497          	auipc	s1,0xf
    80002586:	ba648493          	add	s1,s1,-1114 # 80011128 <proc+0x158>
    8000258a:	00017917          	auipc	s2,0x17
    8000258e:	f9e90913          	add	s2,s2,-98 # 80019528 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002592:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002594:	00006997          	auipc	s3,0x6
    80002598:	cec98993          	add	s3,s3,-788 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000259c:	00006a97          	auipc	s5,0x6
    800025a0:	ceca8a93          	add	s5,s5,-788 # 80008288 <digits+0x248>
    printf("\n");
    800025a4:	00006a17          	auipc	s4,0x6
    800025a8:	b24a0a13          	add	s4,s4,-1244 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	00006b97          	auipc	s7,0x6
    800025b0:	d1cb8b93          	add	s7,s7,-740 # 800082c8 <states.0>
    800025b4:	a00d                	j	800025d6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b6:	ed86a583          	lw	a1,-296(a3)
    800025ba:	8556                	mv	a0,s5
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	fca080e7          	jalr	-54(ra) # 80000586 <printf>
    printf("\n");
    800025c4:	8552                	mv	a0,s4
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	fc0080e7          	jalr	-64(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ce:	21048493          	add	s1,s1,528
    800025d2:	03248263          	beq	s1,s2,800025f6 <procdump+0x9a>
    if (p->state == UNUSED)
    800025d6:	86a6                	mv	a3,s1
    800025d8:	ec04a783          	lw	a5,-320(s1)
    800025dc:	dbed                	beqz	a5,800025ce <procdump+0x72>
      state = "???";
    800025de:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e0:	fcfb6be3          	bltu	s6,a5,800025b6 <procdump+0x5a>
    800025e4:	02079713          	sll	a4,a5,0x20
    800025e8:	01d75793          	srl	a5,a4,0x1d
    800025ec:	97de                	add	a5,a5,s7
    800025ee:	6390                	ld	a2,0(a5)
    800025f0:	f279                	bnez	a2,800025b6 <procdump+0x5a>
      state = "???";
    800025f2:	864e                	mv	a2,s3
    800025f4:	b7c9                	j	800025b6 <procdump+0x5a>
  }
}
    800025f6:	60a6                	ld	ra,72(sp)
    800025f8:	6406                	ld	s0,64(sp)
    800025fa:	74e2                	ld	s1,56(sp)
    800025fc:	7942                	ld	s2,48(sp)
    800025fe:	79a2                	ld	s3,40(sp)
    80002600:	7a02                	ld	s4,32(sp)
    80002602:	6ae2                	ld	s5,24(sp)
    80002604:	6b42                	ld	s6,16(sp)
    80002606:	6ba2                	ld	s7,8(sp)
    80002608:	6161                	add	sp,sp,80
    8000260a:	8082                	ret

000000008000260c <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000260c:	711d                	add	sp,sp,-96
    8000260e:	ec86                	sd	ra,88(sp)
    80002610:	e8a2                	sd	s0,80(sp)
    80002612:	e4a6                	sd	s1,72(sp)
    80002614:	e0ca                	sd	s2,64(sp)
    80002616:	fc4e                	sd	s3,56(sp)
    80002618:	f852                	sd	s4,48(sp)
    8000261a:	f456                	sd	s5,40(sp)
    8000261c:	f05a                	sd	s6,32(sp)
    8000261e:	ec5e                	sd	s7,24(sp)
    80002620:	e862                	sd	s8,16(sp)
    80002622:	e466                	sd	s9,8(sp)
    80002624:	e06a                	sd	s10,0(sp)
    80002626:	1080                	add	s0,sp,96
    80002628:	8b2a                	mv	s6,a0
    8000262a:	8bae                	mv	s7,a1
    8000262c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	378080e7          	jalr	888(ra) # 800019a6 <myproc>
    80002636:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002638:	0000e517          	auipc	a0,0xe
    8000263c:	58050513          	add	a0,a0,1408 # 80010bb8 <wait_lock>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	592080e7          	jalr	1426(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002648:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000264a:	4a15                	li	s4,5
        havekids = 1;
    8000264c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000264e:	00017997          	auipc	s3,0x17
    80002652:	d8298993          	add	s3,s3,-638 # 800193d0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002656:	0000ed17          	auipc	s10,0xe
    8000265a:	562d0d13          	add	s10,s10,1378 # 80010bb8 <wait_lock>
    8000265e:	a8e9                	j	80002738 <waitx+0x12c>
          pid = np->pid;
    80002660:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002664:	1684a783          	lw	a5,360(s1)
    80002668:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000266c:	16c4a703          	lw	a4,364(s1)
    80002670:	9f3d                	addw	a4,a4,a5
    80002672:	1704a783          	lw	a5,368(s1)
    80002676:	9f99                	subw	a5,a5,a4
    80002678:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000267c:	000b0e63          	beqz	s6,80002698 <waitx+0x8c>
    80002680:	4691                	li	a3,4
    80002682:	02c48613          	add	a2,s1,44
    80002686:	85da                	mv	a1,s6
    80002688:	05093503          	ld	a0,80(s2)
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	fda080e7          	jalr	-38(ra) # 80001666 <copyout>
    80002694:	04054363          	bltz	a0,800026da <waitx+0xce>
          freeproc(np);
    80002698:	8526                	mv	a0,s1
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	4be080e7          	jalr	1214(ra) # 80001b58 <freeproc>
          release(&np->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e2080e7          	jalr	1506(ra) # 80000c86 <release>
          release(&wait_lock);
    800026ac:	0000e517          	auipc	a0,0xe
    800026b0:	50c50513          	add	a0,a0,1292 # 80010bb8 <wait_lock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5d2080e7          	jalr	1490(ra) # 80000c86 <release>
  }
}
    800026bc:	854e                	mv	a0,s3
    800026be:	60e6                	ld	ra,88(sp)
    800026c0:	6446                	ld	s0,80(sp)
    800026c2:	64a6                	ld	s1,72(sp)
    800026c4:	6906                	ld	s2,64(sp)
    800026c6:	79e2                	ld	s3,56(sp)
    800026c8:	7a42                	ld	s4,48(sp)
    800026ca:	7aa2                	ld	s5,40(sp)
    800026cc:	7b02                	ld	s6,32(sp)
    800026ce:	6be2                	ld	s7,24(sp)
    800026d0:	6c42                	ld	s8,16(sp)
    800026d2:	6ca2                	ld	s9,8(sp)
    800026d4:	6d02                	ld	s10,0(sp)
    800026d6:	6125                	add	sp,sp,96
    800026d8:	8082                	ret
            release(&np->lock);
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	5aa080e7          	jalr	1450(ra) # 80000c86 <release>
            release(&wait_lock);
    800026e4:	0000e517          	auipc	a0,0xe
    800026e8:	4d450513          	add	a0,a0,1236 # 80010bb8 <wait_lock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	59a080e7          	jalr	1434(ra) # 80000c86 <release>
            return -1;
    800026f4:	59fd                	li	s3,-1
    800026f6:	b7d9                	j	800026bc <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    800026f8:	21048493          	add	s1,s1,528
    800026fc:	03348463          	beq	s1,s3,80002724 <waitx+0x118>
      if (np->parent == p)
    80002700:	7c9c                	ld	a5,56(s1)
    80002702:	ff279be3          	bne	a5,s2,800026f8 <waitx+0xec>
        acquire(&np->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4ca080e7          	jalr	1226(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002710:	4c9c                	lw	a5,24(s1)
    80002712:	f54787e3          	beq	a5,s4,80002660 <waitx+0x54>
        release(&np->lock);
    80002716:	8526                	mv	a0,s1
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	56e080e7          	jalr	1390(ra) # 80000c86 <release>
        havekids = 1;
    80002720:	8756                	mv	a4,s5
    80002722:	bfd9                	j	800026f8 <waitx+0xec>
    if (!havekids || p->killed)
    80002724:	c305                	beqz	a4,80002744 <waitx+0x138>
    80002726:	02892783          	lw	a5,40(s2)
    8000272a:	ef89                	bnez	a5,80002744 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000272c:	85ea                	mv	a1,s10
    8000272e:	854a                	mv	a0,s2
    80002730:	00000097          	auipc	ra,0x0
    80002734:	954080e7          	jalr	-1708(ra) # 80002084 <sleep>
    havekids = 0;
    80002738:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000273a:	0000f497          	auipc	s1,0xf
    8000273e:	89648493          	add	s1,s1,-1898 # 80010fd0 <proc>
    80002742:	bf7d                	j	80002700 <waitx+0xf4>
      release(&wait_lock);
    80002744:	0000e517          	auipc	a0,0xe
    80002748:	47450513          	add	a0,a0,1140 # 80010bb8 <wait_lock>
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	53a080e7          	jalr	1338(ra) # 80000c86 <release>
      return -1;
    80002754:	59fd                	li	s3,-1
    80002756:	b79d                	j	800026bc <waitx+0xb0>

0000000080002758 <update_time>:

void update_time()
{
    80002758:	7179                	add	sp,sp,-48
    8000275a:	f406                	sd	ra,40(sp)
    8000275c:	f022                	sd	s0,32(sp)
    8000275e:	ec26                	sd	s1,24(sp)
    80002760:	e84a                	sd	s2,16(sp)
    80002762:	e44e                	sd	s3,8(sp)
    80002764:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002766:	0000f497          	auipc	s1,0xf
    8000276a:	86a48493          	add	s1,s1,-1942 # 80010fd0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000276e:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002770:	00017917          	auipc	s2,0x17
    80002774:	c6090913          	add	s2,s2,-928 # 800193d0 <tickslock>
    80002778:	a811                	j	8000278c <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	50a080e7          	jalr	1290(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002784:	21048493          	add	s1,s1,528
    80002788:	03248063          	beq	s1,s2,800027a8 <update_time+0x50>
    acquire(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	444080e7          	jalr	1092(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002796:	4c9c                	lw	a5,24(s1)
    80002798:	ff3791e3          	bne	a5,s3,8000277a <update_time+0x22>
      p->rtime++;
    8000279c:	1684a783          	lw	a5,360(s1)
    800027a0:	2785                	addw	a5,a5,1
    800027a2:	16f4a423          	sw	a5,360(s1)
    800027a6:	bfd1                	j	8000277a <update_time+0x22>
  }
    800027a8:	70a2                	ld	ra,40(sp)
    800027aa:	7402                	ld	s0,32(sp)
    800027ac:	64e2                	ld	s1,24(sp)
    800027ae:	6942                	ld	s2,16(sp)
    800027b0:	69a2                	ld	s3,8(sp)
    800027b2:	6145                	add	sp,sp,48
    800027b4:	8082                	ret

00000000800027b6 <swtch>:
    800027b6:	00153023          	sd	ra,0(a0)
    800027ba:	00253423          	sd	sp,8(a0)
    800027be:	e900                	sd	s0,16(a0)
    800027c0:	ed04                	sd	s1,24(a0)
    800027c2:	03253023          	sd	s2,32(a0)
    800027c6:	03353423          	sd	s3,40(a0)
    800027ca:	03453823          	sd	s4,48(a0)
    800027ce:	03553c23          	sd	s5,56(a0)
    800027d2:	05653023          	sd	s6,64(a0)
    800027d6:	05753423          	sd	s7,72(a0)
    800027da:	05853823          	sd	s8,80(a0)
    800027de:	05953c23          	sd	s9,88(a0)
    800027e2:	07a53023          	sd	s10,96(a0)
    800027e6:	07b53423          	sd	s11,104(a0)
    800027ea:	0005b083          	ld	ra,0(a1)
    800027ee:	0085b103          	ld	sp,8(a1)
    800027f2:	6980                	ld	s0,16(a1)
    800027f4:	6d84                	ld	s1,24(a1)
    800027f6:	0205b903          	ld	s2,32(a1)
    800027fa:	0285b983          	ld	s3,40(a1)
    800027fe:	0305ba03          	ld	s4,48(a1)
    80002802:	0385ba83          	ld	s5,56(a1)
    80002806:	0405bb03          	ld	s6,64(a1)
    8000280a:	0485bb83          	ld	s7,72(a1)
    8000280e:	0505bc03          	ld	s8,80(a1)
    80002812:	0585bc83          	ld	s9,88(a1)
    80002816:	0605bd03          	ld	s10,96(a1)
    8000281a:	0685bd83          	ld	s11,104(a1)
    8000281e:	8082                	ret

0000000080002820 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002820:	1141                	add	sp,sp,-16
    80002822:	e406                	sd	ra,8(sp)
    80002824:	e022                	sd	s0,0(sp)
    80002826:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002828:	00006597          	auipc	a1,0x6
    8000282c:	ad058593          	add	a1,a1,-1328 # 800082f8 <states.0+0x30>
    80002830:	00017517          	auipc	a0,0x17
    80002834:	ba050513          	add	a0,a0,-1120 # 800193d0 <tickslock>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	30a080e7          	jalr	778(ra) # 80000b42 <initlock>
}
    80002840:	60a2                	ld	ra,8(sp)
    80002842:	6402                	ld	s0,0(sp)
    80002844:	0141                	add	sp,sp,16
    80002846:	8082                	ret

0000000080002848 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002848:	1141                	add	sp,sp,-16
    8000284a:	e422                	sd	s0,8(sp)
    8000284c:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284e:	00003797          	auipc	a5,0x3
    80002852:	69278793          	add	a5,a5,1682 # 80005ee0 <kernelvec>
    80002856:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000285a:	6422                	ld	s0,8(sp)
    8000285c:	0141                	add	sp,sp,16
    8000285e:	8082                	ret

0000000080002860 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002860:	1141                	add	sp,sp,-16
    80002862:	e406                	sd	ra,8(sp)
    80002864:	e022                	sd	s0,0(sp)
    80002866:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	13e080e7          	jalr	318(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002870:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002874:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002876:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000287a:	00004697          	auipc	a3,0x4
    8000287e:	78668693          	add	a3,a3,1926 # 80007000 <_trampoline>
    80002882:	00004717          	auipc	a4,0x4
    80002886:	77e70713          	add	a4,a4,1918 # 80007000 <_trampoline>
    8000288a:	8f15                	sub	a4,a4,a3
    8000288c:	040007b7          	lui	a5,0x4000
    80002890:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002892:	07b2                	sll	a5,a5,0xc
    80002894:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002896:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000289a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000289c:	18002673          	csrr	a2,satp
    800028a0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028a2:	6d30                	ld	a2,88(a0)
    800028a4:	6138                	ld	a4,64(a0)
    800028a6:	6585                	lui	a1,0x1
    800028a8:	972e                	add	a4,a4,a1
    800028aa:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028ac:	6d38                	ld	a4,88(a0)
    800028ae:	00000617          	auipc	a2,0x0
    800028b2:	14260613          	add	a2,a2,322 # 800029f0 <usertrap>
    800028b6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028b8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ba:	8612                	mv	a2,tp
    800028bc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028be:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028c2:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c6:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ca:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ce:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028d0:	6f18                	ld	a4,24(a4)
    800028d2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d6:	6928                	ld	a0,80(a0)
    800028d8:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028da:	00004717          	auipc	a4,0x4
    800028de:	7c270713          	add	a4,a4,1986 # 8000709c <userret>
    800028e2:	8f15                	sub	a4,a4,a3
    800028e4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028e6:	577d                	li	a4,-1
    800028e8:	177e                	sll	a4,a4,0x3f
    800028ea:	8d59                	or	a0,a0,a4
    800028ec:	9782                	jalr	a5
}
    800028ee:	60a2                	ld	ra,8(sp)
    800028f0:	6402                	ld	s0,0(sp)
    800028f2:	0141                	add	sp,sp,16
    800028f4:	8082                	ret

00000000800028f6 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028f6:	1101                	add	sp,sp,-32
    800028f8:	ec06                	sd	ra,24(sp)
    800028fa:	e822                	sd	s0,16(sp)
    800028fc:	e426                	sd	s1,8(sp)
    800028fe:	e04a                	sd	s2,0(sp)
    80002900:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002902:	00017917          	auipc	s2,0x17
    80002906:	ace90913          	add	s2,s2,-1330 # 800193d0 <tickslock>
    8000290a:	854a                	mv	a0,s2
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	2c6080e7          	jalr	710(ra) # 80000bd2 <acquire>
  ticks++;
    80002914:	00006497          	auipc	s1,0x6
    80002918:	01c48493          	add	s1,s1,28 # 80008930 <ticks>
    8000291c:	409c                	lw	a5,0(s1)
    8000291e:	2785                	addw	a5,a5,1
    80002920:	c09c                	sw	a5,0(s1)
  update_time();
    80002922:	00000097          	auipc	ra,0x0
    80002926:	e36080e7          	jalr	-458(ra) # 80002758 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000292a:	8526                	mv	a0,s1
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	7bc080e7          	jalr	1980(ra) # 800020e8 <wakeup>
  release(&tickslock);
    80002934:	854a                	mv	a0,s2
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	350080e7          	jalr	848(ra) # 80000c86 <release>
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6902                	ld	s2,0(sp)
    80002946:	6105                	add	sp,sp,32
    80002948:	8082                	ret

000000008000294a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294a:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    8000294e:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002950:	0807df63          	bgez	a5,800029ee <devintr+0xa4>
{
    80002954:	1101                	add	sp,sp,-32
    80002956:	ec06                	sd	ra,24(sp)
    80002958:	e822                	sd	s0,16(sp)
    8000295a:	e426                	sd	s1,8(sp)
    8000295c:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    8000295e:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002962:	46a5                	li	a3,9
    80002964:	00d70d63          	beq	a4,a3,8000297e <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002968:	577d                	li	a4,-1
    8000296a:	177e                	sll	a4,a4,0x3f
    8000296c:	0705                	add	a4,a4,1
    return 0;
    8000296e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002970:	04e78e63          	beq	a5,a4,800029cc <devintr+0x82>
  }
}
    80002974:	60e2                	ld	ra,24(sp)
    80002976:	6442                	ld	s0,16(sp)
    80002978:	64a2                	ld	s1,8(sp)
    8000297a:	6105                	add	sp,sp,32
    8000297c:	8082                	ret
    int irq = plic_claim();
    8000297e:	00003097          	auipc	ra,0x3
    80002982:	66a080e7          	jalr	1642(ra) # 80005fe8 <plic_claim>
    80002986:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002988:	47a9                	li	a5,10
    8000298a:	02f50763          	beq	a0,a5,800029b8 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    8000298e:	4785                	li	a5,1
    80002990:	02f50963          	beq	a0,a5,800029c2 <devintr+0x78>
    return 1;
    80002994:	4505                	li	a0,1
    else if (irq)
    80002996:	dcf9                	beqz	s1,80002974 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002998:	85a6                	mv	a1,s1
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	96650513          	add	a0,a0,-1690 # 80008300 <states.0+0x38>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be4080e7          	jalr	-1052(ra) # 80000586 <printf>
      plic_complete(irq);
    800029aa:	8526                	mv	a0,s1
    800029ac:	00003097          	auipc	ra,0x3
    800029b0:	660080e7          	jalr	1632(ra) # 8000600c <plic_complete>
    return 1;
    800029b4:	4505                	li	a0,1
    800029b6:	bf7d                	j	80002974 <devintr+0x2a>
      uartintr();
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	fdc080e7          	jalr	-36(ra) # 80000994 <uartintr>
    if (irq)
    800029c0:	b7ed                	j	800029aa <devintr+0x60>
      virtio_disk_intr();
    800029c2:	00004097          	auipc	ra,0x4
    800029c6:	b10080e7          	jalr	-1264(ra) # 800064d2 <virtio_disk_intr>
    if (irq)
    800029ca:	b7c5                	j	800029aa <devintr+0x60>
    if (cpuid() == 0)
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	fae080e7          	jalr	-82(ra) # 8000197a <cpuid>
    800029d4:	c901                	beqz	a0,800029e4 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029d6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029da:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029dc:	14479073          	csrw	sip,a5
    return 2;
    800029e0:	4509                	li	a0,2
    800029e2:	bf49                	j	80002974 <devintr+0x2a>
      clockintr();
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	f12080e7          	jalr	-238(ra) # 800028f6 <clockintr>
    800029ec:	b7ed                	j	800029d6 <devintr+0x8c>
}
    800029ee:	8082                	ret

00000000800029f0 <usertrap>:
{
    800029f0:	1101                	add	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a00:	1007f793          	and	a5,a5,256
    80002a04:	efb9                	bnez	a5,80002a62 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a06:	00003797          	auipc	a5,0x3
    80002a0a:	4da78793          	add	a5,a5,1242 # 80005ee0 <kernelvec>
    80002a0e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	f94080e7          	jalr	-108(ra) # 800019a6 <myproc>
    80002a1a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a1c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	14102773          	csrr	a4,sepc
    80002a22:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a28:	47a1                	li	a5,8
    80002a2a:	04f70463          	beq	a4,a5,80002a72 <usertrap+0x82>
  else if ((which_dev = devintr()) != 0)
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	f1c080e7          	jalr	-228(ra) # 8000294a <devintr>
    80002a36:	892a                	mv	s2,a0
    80002a38:	c575                	beqz	a0,80002b24 <usertrap+0x134>
    if (which_dev == 2)
    80002a3a:	4789                	li	a5,2
    80002a3c:	04f51f63          	bne	a0,a5,80002a9a <usertrap+0xaa>
      if (p != 0 && p->state == RUNNING)
    80002a40:	4c98                	lw	a4,24(s1)
    80002a42:	4791                	li	a5,4
    80002a44:	08f70163          	beq	a4,a5,80002ac6 <usertrap+0xd6>
  if (killed(p))
    80002a48:	8526                	mv	a0,s1
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	8ee080e7          	jalr	-1810(ra) # 80002338 <killed>
    80002a52:	10050e63          	beqz	a0,80002b6e <usertrap+0x17e>
    exit(-1);
    80002a56:	557d                	li	a0,-1
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	760080e7          	jalr	1888(ra) # 800021b8 <exit>
  if (which_dev == 2)
    80002a60:	a239                	j	80002b6e <usertrap+0x17e>
    panic("usertrap: not from user mode");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8be50513          	add	a0,a0,-1858 # 80008320 <states.0+0x58>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ad2080e7          	jalr	-1326(ra) # 8000053c <panic>
    if (killed(p))
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	8c6080e7          	jalr	-1850(ra) # 80002338 <killed>
    80002a7a:	e121                	bnez	a0,80002aba <usertrap+0xca>
    p->trapframe->epc += 4;
    80002a7c:	6cb8                	ld	a4,88(s1)
    80002a7e:	6f1c                	ld	a5,24(a4)
    80002a80:	0791                	add	a5,a5,4
    80002a82:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a88:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	332080e7          	jalr	818(ra) # 80002dc2 <syscall>
  int which_dev = 0;
    80002a98:	4901                	li	s2,0
  if (killed(p))
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	89c080e7          	jalr	-1892(ra) # 80002338 <killed>
    80002aa4:	ed4d                	bnez	a0,80002b5e <usertrap+0x16e>
  usertrapret();
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	dba080e7          	jalr	-582(ra) # 80002860 <usertrapret>
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6902                	ld	s2,0(sp)
    80002ab6:	6105                	add	sp,sp,32
    80002ab8:	8082                	ret
      exit(-1);
    80002aba:	557d                	li	a0,-1
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	6fc080e7          	jalr	1788(ra) # 800021b8 <exit>
    80002ac4:	bf65                	j	80002a7c <usertrap+0x8c>
        p->ticks_count++;
    80002ac6:	2004a783          	lw	a5,512(s1)
    80002aca:	2785                	addw	a5,a5,1
    80002acc:	0007871b          	sext.w	a4,a5
    80002ad0:	20f4a023          	sw	a5,512(s1)
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
    80002ad4:	1f04a783          	lw	a5,496(s1)
    80002ad8:	f6f058e3          	blez	a5,80002a48 <usertrap+0x58>
    80002adc:	f6f746e3          	blt	a4,a5,80002a48 <usertrap+0x58>
    80002ae0:	2044a783          	lw	a5,516(s1)
    80002ae4:	d3b5                	beqz	a5,80002a48 <usertrap+0x58>
          p->alarm_on = 0; // Disable alarm while handler is running
    80002ae6:	2004a223          	sw	zero,516(s1)
          p->alarm_tf = kalloc();
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	ff8080e7          	jalr	-8(ra) # 80000ae2 <kalloc>
    80002af2:	20a4b423          	sd	a0,520(s1)
          if (p->alarm_tf == 0)
    80002af6:	cd19                	beqz	a0,80002b14 <usertrap+0x124>
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    80002af8:	12000613          	li	a2,288
    80002afc:	6cac                	ld	a1,88(s1)
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	22c080e7          	jalr	556(ra) # 80000d2a <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    80002b06:	6cbc                	ld	a5,88(s1)
    80002b08:	1f84b703          	ld	a4,504(s1)
    80002b0c:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    80002b0e:	2004a023          	sw	zero,512(s1)
    80002b12:	bf1d                	j	80002a48 <usertrap+0x58>
            panic("Error !! usertrap: out of memory");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	82c50513          	add	a0,a0,-2004 # 80008340 <states.0+0x78>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a20080e7          	jalr	-1504(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b24:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b28:	5890                	lw	a2,48(s1)
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	83e50513          	add	a0,a0,-1986 # 80008368 <states.0+0xa0>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a54080e7          	jalr	-1452(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b3e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	85650513          	add	a0,a0,-1962 # 80008398 <states.0+0xd0>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	a3c080e7          	jalr	-1476(ra) # 80000586 <printf>
    setkilled(p);
    80002b52:	8526                	mv	a0,s1
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	7b8080e7          	jalr	1976(ra) # 8000230c <setkilled>
    80002b5c:	bf3d                	j	80002a9a <usertrap+0xaa>
    exit(-1);
    80002b5e:	557d                	li	a0,-1
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	658080e7          	jalr	1624(ra) # 800021b8 <exit>
  if (which_dev == 2)
    80002b68:	4789                	li	a5,2
    80002b6a:	f2f91ee3          	bne	s2,a5,80002aa6 <usertrap+0xb6>
    yield();
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	4da080e7          	jalr	1242(ra) # 80002048 <yield>
    80002b76:	bf05                	j	80002aa6 <usertrap+0xb6>

0000000080002b78 <kerneltrap>:
{
    80002b78:	7179                	add	sp,sp,-48
    80002b7a:	f406                	sd	ra,40(sp)
    80002b7c:	f022                	sd	s0,32(sp)
    80002b7e:	ec26                	sd	s1,24(sp)
    80002b80:	e84a                	sd	s2,16(sp)
    80002b82:	e44e                	sd	s3,8(sp)
    80002b84:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b86:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b92:	1004f793          	and	a5,s1,256
    80002b96:	cb85                	beqz	a5,80002bc6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b9c:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002b9e:	ef85                	bnez	a5,80002bd6 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	daa080e7          	jalr	-598(ra) # 8000294a <devintr>
    80002ba8:	cd1d                	beqz	a0,80002be6 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002baa:	4789                	li	a5,2
    80002bac:	06f50a63          	beq	a0,a5,80002c20 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bb0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb4:	10049073          	csrw	sstatus,s1
}
    80002bb8:	70a2                	ld	ra,40(sp)
    80002bba:	7402                	ld	s0,32(sp)
    80002bbc:	64e2                	ld	s1,24(sp)
    80002bbe:	6942                	ld	s2,16(sp)
    80002bc0:	69a2                	ld	s3,8(sp)
    80002bc2:	6145                	add	sp,sp,48
    80002bc4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bc6:	00005517          	auipc	a0,0x5
    80002bca:	7f250513          	add	a0,a0,2034 # 800083b8 <states.0+0xf0>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	96e080e7          	jalr	-1682(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	80a50513          	add	a0,a0,-2038 # 800083e0 <states.0+0x118>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	95e080e7          	jalr	-1698(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002be6:	85ce                	mv	a1,s3
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	81850513          	add	a0,a0,-2024 # 80008400 <states.0+0x138>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	996080e7          	jalr	-1642(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bfc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	81050513          	add	a0,a0,-2032 # 80008410 <states.0+0x148>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	97e080e7          	jalr	-1666(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002c10:	00006517          	auipc	a0,0x6
    80002c14:	81850513          	add	a0,a0,-2024 # 80008428 <states.0+0x160>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	924080e7          	jalr	-1756(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	d86080e7          	jalr	-634(ra) # 800019a6 <myproc>
    80002c28:	d541                	beqz	a0,80002bb0 <kerneltrap+0x38>
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	d7c080e7          	jalr	-644(ra) # 800019a6 <myproc>
    80002c32:	4d18                	lw	a4,24(a0)
    80002c34:	4791                	li	a5,4
    80002c36:	f6f71de3          	bne	a4,a5,80002bb0 <kerneltrap+0x38>
    yield();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	40e080e7          	jalr	1038(ra) # 80002048 <yield>
    80002c42:	b7bd                	j	80002bb0 <kerneltrap+0x38>

0000000080002c44 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c44:	1101                	add	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	1000                	add	s0,sp,32
    80002c4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d56080e7          	jalr	-682(ra) # 800019a6 <myproc>
  switch (n)
    80002c58:	4795                	li	a5,5
    80002c5a:	0497e163          	bltu	a5,s1,80002c9c <argraw+0x58>
    80002c5e:	048a                	sll	s1,s1,0x2
    80002c60:	00006717          	auipc	a4,0x6
    80002c64:	80070713          	add	a4,a4,-2048 # 80008460 <states.0+0x198>
    80002c68:	94ba                	add	s1,s1,a4
    80002c6a:	409c                	lw	a5,0(s1)
    80002c6c:	97ba                	add	a5,a5,a4
    80002c6e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c70:	6d3c                	ld	a5,88(a0)
    80002c72:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	64a2                	ld	s1,8(sp)
    80002c7a:	6105                	add	sp,sp,32
    80002c7c:	8082                	ret
    return p->trapframe->a1;
    80002c7e:	6d3c                	ld	a5,88(a0)
    80002c80:	7fa8                	ld	a0,120(a5)
    80002c82:	bfcd                	j	80002c74 <argraw+0x30>
    return p->trapframe->a2;
    80002c84:	6d3c                	ld	a5,88(a0)
    80002c86:	63c8                	ld	a0,128(a5)
    80002c88:	b7f5                	j	80002c74 <argraw+0x30>
    return p->trapframe->a3;
    80002c8a:	6d3c                	ld	a5,88(a0)
    80002c8c:	67c8                	ld	a0,136(a5)
    80002c8e:	b7dd                	j	80002c74 <argraw+0x30>
    return p->trapframe->a4;
    80002c90:	6d3c                	ld	a5,88(a0)
    80002c92:	6bc8                	ld	a0,144(a5)
    80002c94:	b7c5                	j	80002c74 <argraw+0x30>
    return p->trapframe->a5;
    80002c96:	6d3c                	ld	a5,88(a0)
    80002c98:	6fc8                	ld	a0,152(a5)
    80002c9a:	bfe9                	j	80002c74 <argraw+0x30>
  panic("argraw");
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	79c50513          	add	a0,a0,1948 # 80008438 <states.0+0x170>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	898080e7          	jalr	-1896(ra) # 8000053c <panic>

0000000080002cac <fetchaddr>:
{
    80002cac:	1101                	add	sp,sp,-32
    80002cae:	ec06                	sd	ra,24(sp)
    80002cb0:	e822                	sd	s0,16(sp)
    80002cb2:	e426                	sd	s1,8(sp)
    80002cb4:	e04a                	sd	s2,0(sp)
    80002cb6:	1000                	add	s0,sp,32
    80002cb8:	84aa                	mv	s1,a0
    80002cba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	cea080e7          	jalr	-790(ra) # 800019a6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002cc4:	653c                	ld	a5,72(a0)
    80002cc6:	02f4f863          	bgeu	s1,a5,80002cf6 <fetchaddr+0x4a>
    80002cca:	00848713          	add	a4,s1,8
    80002cce:	02e7e663          	bltu	a5,a4,80002cfa <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cd2:	46a1                	li	a3,8
    80002cd4:	8626                	mv	a2,s1
    80002cd6:	85ca                	mv	a1,s2
    80002cd8:	6928                	ld	a0,80(a0)
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	a18080e7          	jalr	-1512(ra) # 800016f2 <copyin>
    80002ce2:	00a03533          	snez	a0,a0
    80002ce6:	40a00533          	neg	a0,a0
}
    80002cea:	60e2                	ld	ra,24(sp)
    80002cec:	6442                	ld	s0,16(sp)
    80002cee:	64a2                	ld	s1,8(sp)
    80002cf0:	6902                	ld	s2,0(sp)
    80002cf2:	6105                	add	sp,sp,32
    80002cf4:	8082                	ret
    return -1;
    80002cf6:	557d                	li	a0,-1
    80002cf8:	bfcd                	j	80002cea <fetchaddr+0x3e>
    80002cfa:	557d                	li	a0,-1
    80002cfc:	b7fd                	j	80002cea <fetchaddr+0x3e>

0000000080002cfe <fetchstr>:
{
    80002cfe:	7179                	add	sp,sp,-48
    80002d00:	f406                	sd	ra,40(sp)
    80002d02:	f022                	sd	s0,32(sp)
    80002d04:	ec26                	sd	s1,24(sp)
    80002d06:	e84a                	sd	s2,16(sp)
    80002d08:	e44e                	sd	s3,8(sp)
    80002d0a:	1800                	add	s0,sp,48
    80002d0c:	892a                	mv	s2,a0
    80002d0e:	84ae                	mv	s1,a1
    80002d10:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d12:	fffff097          	auipc	ra,0xfffff
    80002d16:	c94080e7          	jalr	-876(ra) # 800019a6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d1a:	86ce                	mv	a3,s3
    80002d1c:	864a                	mv	a2,s2
    80002d1e:	85a6                	mv	a1,s1
    80002d20:	6928                	ld	a0,80(a0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	a5e080e7          	jalr	-1442(ra) # 80001780 <copyinstr>
    80002d2a:	00054e63          	bltz	a0,80002d46 <fetchstr+0x48>
  return strlen(buf);
    80002d2e:	8526                	mv	a0,s1
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	118080e7          	jalr	280(ra) # 80000e48 <strlen>
}
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6942                	ld	s2,16(sp)
    80002d40:	69a2                	ld	s3,8(sp)
    80002d42:	6145                	add	sp,sp,48
    80002d44:	8082                	ret
    return -1;
    80002d46:	557d                	li	a0,-1
    80002d48:	bfc5                	j	80002d38 <fetchstr+0x3a>

0000000080002d4a <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002d4a:	1101                	add	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	1000                	add	s0,sp,32
    80002d54:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	eee080e7          	jalr	-274(ra) # 80002c44 <argraw>
    80002d5e:	c088                	sw	a0,0(s1)
}
    80002d60:	60e2                	ld	ra,24(sp)
    80002d62:	6442                	ld	s0,16(sp)
    80002d64:	64a2                	ld	s1,8(sp)
    80002d66:	6105                	add	sp,sp,32
    80002d68:	8082                	ret

0000000080002d6a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002d6a:	1101                	add	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	1000                	add	s0,sp,32
    80002d74:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	ece080e7          	jalr	-306(ra) # 80002c44 <argraw>
    80002d7e:	e088                	sd	a0,0(s1)
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	add	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d8a:	7179                	add	sp,sp,-48
    80002d8c:	f406                	sd	ra,40(sp)
    80002d8e:	f022                	sd	s0,32(sp)
    80002d90:	ec26                	sd	s1,24(sp)
    80002d92:	e84a                	sd	s2,16(sp)
    80002d94:	1800                	add	s0,sp,48
    80002d96:	84ae                	mv	s1,a1
    80002d98:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d9a:	fd840593          	add	a1,s0,-40
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	fcc080e7          	jalr	-52(ra) # 80002d6a <argaddr>
  return fetchstr(addr, buf, max);
    80002da6:	864a                	mv	a2,s2
    80002da8:	85a6                	mv	a1,s1
    80002daa:	fd843503          	ld	a0,-40(s0)
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	f50080e7          	jalr	-176(ra) # 80002cfe <fetchstr>
}
    80002db6:	70a2                	ld	ra,40(sp)
    80002db8:	7402                	ld	s0,32(sp)
    80002dba:	64e2                	ld	s1,24(sp)
    80002dbc:	6942                	ld	s2,16(sp)
    80002dbe:	6145                	add	sp,sp,48
    80002dc0:	8082                	ret

0000000080002dc2 <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    80002dc2:	1101                	add	sp,sp,-32
    80002dc4:	ec06                	sd	ra,24(sp)
    80002dc6:	e822                	sd	s0,16(sp)
    80002dc8:	e426                	sd	s1,8(sp)
    80002dca:	e04a                	sd	s2,0(sp)
    80002dcc:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	bd8080e7          	jalr	-1064(ra) # 800019a6 <myproc>
    80002dd6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dd8:	05853903          	ld	s2,88(a0)
    80002ddc:	0a893783          	ld	a5,168(s2)
    80002de0:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002de4:	37fd                	addw	a5,a5,-1
    80002de6:	4761                	li	a4,24
    80002de8:	02f76763          	bltu	a4,a5,80002e16 <syscall+0x54>
    80002dec:	00369713          	sll	a4,a3,0x3
    80002df0:	00005797          	auipc	a5,0x5
    80002df4:	68878793          	add	a5,a5,1672 # 80008478 <syscalls>
    80002df8:	97ba                	add	a5,a5,a4
    80002dfa:	6398                	ld	a4,0(a5)
    80002dfc:	cf09                	beqz	a4,80002e16 <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    80002dfe:	068a                	sll	a3,a3,0x2
    80002e00:	00d504b3          	add	s1,a0,a3
    80002e04:	1704a783          	lw	a5,368(s1)
    80002e08:	2785                	addw	a5,a5,1
    80002e0a:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    80002e0e:	9702                	jalr	a4
    80002e10:	06a93823          	sd	a0,112(s2)
    80002e14:	a839                	j	80002e32 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e16:	15848613          	add	a2,s1,344
    80002e1a:	588c                	lw	a1,48(s1)
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	62450513          	add	a0,a0,1572 # 80008440 <states.0+0x178>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	762080e7          	jalr	1890(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e2c:	6cbc                	ld	a5,88(s1)
    80002e2e:	577d                	li	a4,-1
    80002e30:	fbb8                	sd	a4,112(a5)
  }
}
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6902                	ld	s2,0(sp)
    80002e3a:	6105                	add	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    80002e3e:	1101                	add	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002e46:	fec40593          	add	a1,s0,-20
    80002e4a:	4501                	li	a0,0
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	efe080e7          	jalr	-258(ra) # 80002d4a <argint>
  exit(n);
    80002e54:	fec42503          	lw	a0,-20(s0)
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	360080e7          	jalr	864(ra) # 800021b8 <exit>
  return 0; // not reached
}
    80002e60:	4501                	li	a0,0
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	6105                	add	sp,sp,32
    80002e68:	8082                	ret

0000000080002e6a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e6a:	1141                	add	sp,sp,-16
    80002e6c:	e406                	sd	ra,8(sp)
    80002e6e:	e022                	sd	s0,0(sp)
    80002e70:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	b34080e7          	jalr	-1228(ra) # 800019a6 <myproc>
}
    80002e7a:	5908                	lw	a0,48(a0)
    80002e7c:	60a2                	ld	ra,8(sp)
    80002e7e:	6402                	ld	s0,0(sp)
    80002e80:	0141                	add	sp,sp,16
    80002e82:	8082                	ret

0000000080002e84 <sys_fork>:

uint64
sys_fork(void)
{
    80002e84:	1141                	add	sp,sp,-16
    80002e86:	e406                	sd	ra,8(sp)
    80002e88:	e022                	sd	s0,0(sp)
    80002e8a:	0800                	add	s0,sp,16
  return fork();
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	f06080e7          	jalr	-250(ra) # 80001d92 <fork>
}
    80002e94:	60a2                	ld	ra,8(sp)
    80002e96:	6402                	ld	s0,0(sp)
    80002e98:	0141                	add	sp,sp,16
    80002e9a:	8082                	ret

0000000080002e9c <sys_wait>:

uint64
sys_wait(void)
{
    80002e9c:	1101                	add	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ea4:	fe840593          	add	a1,s0,-24
    80002ea8:	4501                	li	a0,0
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	ec0080e7          	jalr	-320(ra) # 80002d6a <argaddr>
  return wait(p);
    80002eb2:	fe843503          	ld	a0,-24(s0)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	4b4080e7          	jalr	1204(ra) # 8000236a <wait>
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	6105                	add	sp,sp,32
    80002ec4:	8082                	ret

0000000080002ec6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ec6:	7179                	add	sp,sp,-48
    80002ec8:	f406                	sd	ra,40(sp)
    80002eca:	f022                	sd	s0,32(sp)
    80002ecc:	ec26                	sd	s1,24(sp)
    80002ece:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ed0:	fdc40593          	add	a1,s0,-36
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	e74080e7          	jalr	-396(ra) # 80002d4a <argint>
  addr = myproc()->sz;
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	ac8080e7          	jalr	-1336(ra) # 800019a6 <myproc>
    80002ee6:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002ee8:	fdc42503          	lw	a0,-36(s0)
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	e4a080e7          	jalr	-438(ra) # 80001d36 <growproc>
    80002ef4:	00054863          	bltz	a0,80002f04 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ef8:	8526                	mv	a0,s1
    80002efa:	70a2                	ld	ra,40(sp)
    80002efc:	7402                	ld	s0,32(sp)
    80002efe:	64e2                	ld	s1,24(sp)
    80002f00:	6145                	add	sp,sp,48
    80002f02:	8082                	ret
    return -1;
    80002f04:	54fd                	li	s1,-1
    80002f06:	bfcd                	j	80002ef8 <sys_sbrk+0x32>

0000000080002f08 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f08:	7139                	add	sp,sp,-64
    80002f0a:	fc06                	sd	ra,56(sp)
    80002f0c:	f822                	sd	s0,48(sp)
    80002f0e:	f426                	sd	s1,40(sp)
    80002f10:	f04a                	sd	s2,32(sp)
    80002f12:	ec4e                	sd	s3,24(sp)
    80002f14:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002f16:	fcc40593          	add	a1,s0,-52
    80002f1a:	4501                	li	a0,0
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	e2e080e7          	jalr	-466(ra) # 80002d4a <argint>
  acquire(&tickslock);
    80002f24:	00016517          	auipc	a0,0x16
    80002f28:	4ac50513          	add	a0,a0,1196 # 800193d0 <tickslock>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	ca6080e7          	jalr	-858(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002f34:	00006917          	auipc	s2,0x6
    80002f38:	9fc92903          	lw	s2,-1540(s2) # 80008930 <ticks>
  while (ticks - ticks0 < n)
    80002f3c:	fcc42783          	lw	a5,-52(s0)
    80002f40:	cf9d                	beqz	a5,80002f7e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f42:	00016997          	auipc	s3,0x16
    80002f46:	48e98993          	add	s3,s3,1166 # 800193d0 <tickslock>
    80002f4a:	00006497          	auipc	s1,0x6
    80002f4e:	9e648493          	add	s1,s1,-1562 # 80008930 <ticks>
    if (killed(myproc()))
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	a54080e7          	jalr	-1452(ra) # 800019a6 <myproc>
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	3de080e7          	jalr	990(ra) # 80002338 <killed>
    80002f62:	ed15                	bnez	a0,80002f9e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f64:	85ce                	mv	a1,s3
    80002f66:	8526                	mv	a0,s1
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	11c080e7          	jalr	284(ra) # 80002084 <sleep>
  while (ticks - ticks0 < n)
    80002f70:	409c                	lw	a5,0(s1)
    80002f72:	412787bb          	subw	a5,a5,s2
    80002f76:	fcc42703          	lw	a4,-52(s0)
    80002f7a:	fce7ece3          	bltu	a5,a4,80002f52 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f7e:	00016517          	auipc	a0,0x16
    80002f82:	45250513          	add	a0,a0,1106 # 800193d0 <tickslock>
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	d00080e7          	jalr	-768(ra) # 80000c86 <release>
  return 0;
    80002f8e:	4501                	li	a0,0
}
    80002f90:	70e2                	ld	ra,56(sp)
    80002f92:	7442                	ld	s0,48(sp)
    80002f94:	74a2                	ld	s1,40(sp)
    80002f96:	7902                	ld	s2,32(sp)
    80002f98:	69e2                	ld	s3,24(sp)
    80002f9a:	6121                	add	sp,sp,64
    80002f9c:	8082                	ret
      release(&tickslock);
    80002f9e:	00016517          	auipc	a0,0x16
    80002fa2:	43250513          	add	a0,a0,1074 # 800193d0 <tickslock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	ce0080e7          	jalr	-800(ra) # 80000c86 <release>
      return -1;
    80002fae:	557d                	li	a0,-1
    80002fb0:	b7c5                	j	80002f90 <sys_sleep+0x88>

0000000080002fb2 <sys_kill>:

uint64
sys_kill(void)
{
    80002fb2:	1101                	add	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002fba:	fec40593          	add	a1,s0,-20
    80002fbe:	4501                	li	a0,0
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	d8a080e7          	jalr	-630(ra) # 80002d4a <argint>
  return kill(pid);
    80002fc8:	fec42503          	lw	a0,-20(s0)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	2ce080e7          	jalr	718(ra) # 8000229a <kill>
}
    80002fd4:	60e2                	ld	ra,24(sp)
    80002fd6:	6442                	ld	s0,16(sp)
    80002fd8:	6105                	add	sp,sp,32
    80002fda:	8082                	ret

0000000080002fdc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fdc:	1101                	add	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fe6:	00016517          	auipc	a0,0x16
    80002fea:	3ea50513          	add	a0,a0,1002 # 800193d0 <tickslock>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	be4080e7          	jalr	-1052(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002ff6:	00006497          	auipc	s1,0x6
    80002ffa:	93a4a483          	lw	s1,-1734(s1) # 80008930 <ticks>
  release(&tickslock);
    80002ffe:	00016517          	auipc	a0,0x16
    80003002:	3d250513          	add	a0,a0,978 # 800193d0 <tickslock>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	c80080e7          	jalr	-896(ra) # 80000c86 <release>
  return xticks;
}
    8000300e:	02049513          	sll	a0,s1,0x20
    80003012:	9101                	srl	a0,a0,0x20
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6105                	add	sp,sp,32
    8000301c:	8082                	ret

000000008000301e <sys_waitx>:

uint64
sys_waitx(void)
{
    8000301e:	7139                	add	sp,sp,-64
    80003020:	fc06                	sd	ra,56(sp)
    80003022:	f822                	sd	s0,48(sp)
    80003024:	f426                	sd	s1,40(sp)
    80003026:	f04a                	sd	s2,32(sp)
    80003028:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000302a:	fd840593          	add	a1,s0,-40
    8000302e:	4501                	li	a0,0
    80003030:	00000097          	auipc	ra,0x0
    80003034:	d3a080e7          	jalr	-710(ra) # 80002d6a <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003038:	fd040593          	add	a1,s0,-48
    8000303c:	4505                	li	a0,1
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	d2c080e7          	jalr	-724(ra) # 80002d6a <argaddr>
  argaddr(2, &addr2);
    80003046:	fc840593          	add	a1,s0,-56
    8000304a:	4509                	li	a0,2
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	d1e080e7          	jalr	-738(ra) # 80002d6a <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003054:	fc040613          	add	a2,s0,-64
    80003058:	fc440593          	add	a1,s0,-60
    8000305c:	fd843503          	ld	a0,-40(s0)
    80003060:	fffff097          	auipc	ra,0xfffff
    80003064:	5ac080e7          	jalr	1452(ra) # 8000260c <waitx>
    80003068:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	93c080e7          	jalr	-1732(ra) # 800019a6 <myproc>
    80003072:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003074:	4691                	li	a3,4
    80003076:	fc440613          	add	a2,s0,-60
    8000307a:	fd043583          	ld	a1,-48(s0)
    8000307e:	6928                	ld	a0,80(a0)
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	5e6080e7          	jalr	1510(ra) # 80001666 <copyout>
    return -1;
    80003088:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000308a:	00054f63          	bltz	a0,800030a8 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000308e:	4691                	li	a3,4
    80003090:	fc040613          	add	a2,s0,-64
    80003094:	fc843583          	ld	a1,-56(s0)
    80003098:	68a8                	ld	a0,80(s1)
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	5cc080e7          	jalr	1484(ra) # 80001666 <copyout>
    800030a2:	00054a63          	bltz	a0,800030b6 <sys_waitx+0x98>
    return -1;
  return ret;
    800030a6:	87ca                	mv	a5,s2
}
    800030a8:	853e                	mv	a0,a5
    800030aa:	70e2                	ld	ra,56(sp)
    800030ac:	7442                	ld	s0,48(sp)
    800030ae:	74a2                	ld	s1,40(sp)
    800030b0:	7902                	ld	s2,32(sp)
    800030b2:	6121                	add	sp,sp,64
    800030b4:	8082                	ret
    return -1;
    800030b6:	57fd                	li	a5,-1
    800030b8:	bfc5                	j	800030a8 <sys_waitx+0x8a>

00000000800030ba <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    800030ba:	7179                	add	sp,sp,-48
    800030bc:	f406                	sd	ra,40(sp)
    800030be:	f022                	sd	s0,32(sp)
    800030c0:	ec26                	sd	s1,24(sp)
    800030c2:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	8e2080e7          	jalr	-1822(ra) # 800019a6 <myproc>
    800030cc:	84aa                	mv	s1,a0
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }
  

  argint(0, &mask);
    800030ce:	fdc40593          	add	a1,s0,-36
    800030d2:	4501                	li	a0,0
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	c76080e7          	jalr	-906(ra) # 80002d4a <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    800030dc:	fdc42583          	lw	a1,-36(s0)
    800030e0:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    800030e4:	4781                	li	a5,0
  int count = 0;
    800030e6:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    800030e8:	467d                	li	a2,31
    800030ea:	a029                	j	800030f4 <sys_getSysCount+0x3a>
    800030ec:	2785                	addw	a5,a5,1
    800030ee:	0691                	add	a3,a3,4
    800030f0:	00c78963          	beq	a5,a2,80003102 <sys_getSysCount+0x48>
    if (mask & (1 << i))
    800030f4:	40f5d73b          	sraw	a4,a1,a5
    800030f8:	8b05                	and	a4,a4,1
    800030fa:	db6d                	beqz	a4,800030ec <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i-1]; // Add up the syscall counts
    800030fc:	4298                	lw	a4,0(a3)
    800030fe:	9d39                	addw	a0,a0,a4
    80003100:	b7f5                	j	800030ec <sys_getSysCount+0x32>
    }
  }

  return count;
}
    80003102:	70a2                	ld	ra,40(sp)
    80003104:	7402                	ld	s0,32(sp)
    80003106:	64e2                	ld	s1,24(sp)
    80003108:	6145                	add	sp,sp,48
    8000310a:	8082                	ret

000000008000310c <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    8000310c:	1101                	add	sp,sp,-32
    8000310e:	ec06                	sd	ra,24(sp)
    80003110:	e822                	sd	s0,16(sp)
    80003112:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    80003114:	fec40593          	add	a1,s0,-20
    80003118:	4501                	li	a0,0
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	c30080e7          	jalr	-976(ra) # 80002d4a <argint>
    
  argaddr(1, &handler);
    80003122:	fe040593          	add	a1,s0,-32
    80003126:	4505                	li	a0,1
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	c42080e7          	jalr	-958(ra) # 80002d6a <argaddr>
    

  struct proc *p = myproc();
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	876080e7          	jalr	-1930(ra) # 800019a6 <myproc>
  p->alarm_interval = interval;
    80003138:	fec42783          	lw	a5,-20(s0)
    8000313c:	1ef52823          	sw	a5,496(a0)
  p->alarm_handler = (void(*)())handler;
    80003140:	fe043703          	ld	a4,-32(s0)
    80003144:	1ee53c23          	sd	a4,504(a0)
  p->ticks_count = 0;
    80003148:	20052023          	sw	zero,512(a0)
  p->alarm_on = (interval > 0);
    8000314c:	00f027b3          	sgtz	a5,a5
    80003150:	20f52223          	sw	a5,516(a0)

  return 0;
}
    80003154:	4501                	li	a0,0
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	6105                	add	sp,sp,32
    8000315c:	8082                	ret

000000008000315e <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    8000315e:	1101                	add	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	e426                	sd	s1,8(sp)
    80003166:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	83e080e7          	jalr	-1986(ra) # 800019a6 <myproc>

  if(p->alarm_tf) {
    80003170:	20853583          	ld	a1,520(a0)
    80003174:	c585                	beqz	a1,8000319c <sys_sigreturn+0x3e>
    80003176:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_tf, sizeof(struct trapframe));
    80003178:	12000613          	li	a2,288
    8000317c:	6d28                	ld	a0,88(a0)
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	bac080e7          	jalr	-1108(ra) # 80000d2a <memmove>
    kfree(p->alarm_tf);
    80003186:	2084b503          	ld	a0,520(s1)
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	85a080e7          	jalr	-1958(ra) # 800009e4 <kfree>
    p->alarm_tf = 0;
    80003192:	2004b423          	sd	zero,520(s1)
    p->alarm_on = 1;  // Re-enable the alarm
    80003196:	4785                	li	a5,1
    80003198:	20f4a223          	sw	a5,516(s1)
  }
  usertrapret();  // function that returns the command back to the user space
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	6c4080e7          	jalr	1732(ra) # 80002860 <usertrapret>
  return 0;
}
    800031a4:	4501                	li	a0,0
    800031a6:	60e2                	ld	ra,24(sp)
    800031a8:	6442                	ld	s0,16(sp)
    800031aa:	64a2                	ld	s1,8(sp)
    800031ac:	6105                	add	sp,sp,32
    800031ae:	8082                	ret

00000000800031b0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031b0:	7179                	add	sp,sp,-48
    800031b2:	f406                	sd	ra,40(sp)
    800031b4:	f022                	sd	s0,32(sp)
    800031b6:	ec26                	sd	s1,24(sp)
    800031b8:	e84a                	sd	s2,16(sp)
    800031ba:	e44e                	sd	s3,8(sp)
    800031bc:	e052                	sd	s4,0(sp)
    800031be:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031c0:	00005597          	auipc	a1,0x5
    800031c4:	38858593          	add	a1,a1,904 # 80008548 <syscalls+0xd0>
    800031c8:	00016517          	auipc	a0,0x16
    800031cc:	22050513          	add	a0,a0,544 # 800193e8 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	972080e7          	jalr	-1678(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031d8:	0001e797          	auipc	a5,0x1e
    800031dc:	21078793          	add	a5,a5,528 # 800213e8 <bcache+0x8000>
    800031e0:	0001e717          	auipc	a4,0x1e
    800031e4:	47070713          	add	a4,a4,1136 # 80021650 <bcache+0x8268>
    800031e8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031ec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031f0:	00016497          	auipc	s1,0x16
    800031f4:	21048493          	add	s1,s1,528 # 80019400 <bcache+0x18>
    b->next = bcache.head.next;
    800031f8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031fa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031fc:	00005a17          	auipc	s4,0x5
    80003200:	354a0a13          	add	s4,s4,852 # 80008550 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003204:	2b893783          	ld	a5,696(s2)
    80003208:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000320a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000320e:	85d2                	mv	a1,s4
    80003210:	01048513          	add	a0,s1,16
    80003214:	00001097          	auipc	ra,0x1
    80003218:	496080e7          	jalr	1174(ra) # 800046aa <initsleeplock>
    bcache.head.next->prev = b;
    8000321c:	2b893783          	ld	a5,696(s2)
    80003220:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003222:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003226:	45848493          	add	s1,s1,1112
    8000322a:	fd349de3          	bne	s1,s3,80003204 <binit+0x54>
  }
}
    8000322e:	70a2                	ld	ra,40(sp)
    80003230:	7402                	ld	s0,32(sp)
    80003232:	64e2                	ld	s1,24(sp)
    80003234:	6942                	ld	s2,16(sp)
    80003236:	69a2                	ld	s3,8(sp)
    80003238:	6a02                	ld	s4,0(sp)
    8000323a:	6145                	add	sp,sp,48
    8000323c:	8082                	ret

000000008000323e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000323e:	7179                	add	sp,sp,-48
    80003240:	f406                	sd	ra,40(sp)
    80003242:	f022                	sd	s0,32(sp)
    80003244:	ec26                	sd	s1,24(sp)
    80003246:	e84a                	sd	s2,16(sp)
    80003248:	e44e                	sd	s3,8(sp)
    8000324a:	1800                	add	s0,sp,48
    8000324c:	892a                	mv	s2,a0
    8000324e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003250:	00016517          	auipc	a0,0x16
    80003254:	19850513          	add	a0,a0,408 # 800193e8 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	97a080e7          	jalr	-1670(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003260:	0001e497          	auipc	s1,0x1e
    80003264:	4404b483          	ld	s1,1088(s1) # 800216a0 <bcache+0x82b8>
    80003268:	0001e797          	auipc	a5,0x1e
    8000326c:	3e878793          	add	a5,a5,1000 # 80021650 <bcache+0x8268>
    80003270:	02f48f63          	beq	s1,a5,800032ae <bread+0x70>
    80003274:	873e                	mv	a4,a5
    80003276:	a021                	j	8000327e <bread+0x40>
    80003278:	68a4                	ld	s1,80(s1)
    8000327a:	02e48a63          	beq	s1,a4,800032ae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000327e:	449c                	lw	a5,8(s1)
    80003280:	ff279ce3          	bne	a5,s2,80003278 <bread+0x3a>
    80003284:	44dc                	lw	a5,12(s1)
    80003286:	ff3799e3          	bne	a5,s3,80003278 <bread+0x3a>
      b->refcnt++;
    8000328a:	40bc                	lw	a5,64(s1)
    8000328c:	2785                	addw	a5,a5,1
    8000328e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003290:	00016517          	auipc	a0,0x16
    80003294:	15850513          	add	a0,a0,344 # 800193e8 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	9ee080e7          	jalr	-1554(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032a0:	01048513          	add	a0,s1,16
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	440080e7          	jalr	1088(ra) # 800046e4 <acquiresleep>
      return b;
    800032ac:	a8b9                	j	8000330a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ae:	0001e497          	auipc	s1,0x1e
    800032b2:	3ea4b483          	ld	s1,1002(s1) # 80021698 <bcache+0x82b0>
    800032b6:	0001e797          	auipc	a5,0x1e
    800032ba:	39a78793          	add	a5,a5,922 # 80021650 <bcache+0x8268>
    800032be:	00f48863          	beq	s1,a5,800032ce <bread+0x90>
    800032c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032c4:	40bc                	lw	a5,64(s1)
    800032c6:	cf81                	beqz	a5,800032de <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c8:	64a4                	ld	s1,72(s1)
    800032ca:	fee49de3          	bne	s1,a4,800032c4 <bread+0x86>
  panic("bget: no buffers");
    800032ce:	00005517          	auipc	a0,0x5
    800032d2:	28a50513          	add	a0,a0,650 # 80008558 <syscalls+0xe0>
    800032d6:	ffffd097          	auipc	ra,0xffffd
    800032da:	266080e7          	jalr	614(ra) # 8000053c <panic>
      b->dev = dev;
    800032de:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032e2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032e6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032ea:	4785                	li	a5,1
    800032ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032ee:	00016517          	auipc	a0,0x16
    800032f2:	0fa50513          	add	a0,a0,250 # 800193e8 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	990080e7          	jalr	-1648(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800032fe:	01048513          	add	a0,s1,16
    80003302:	00001097          	auipc	ra,0x1
    80003306:	3e2080e7          	jalr	994(ra) # 800046e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000330a:	409c                	lw	a5,0(s1)
    8000330c:	cb89                	beqz	a5,8000331e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000330e:	8526                	mv	a0,s1
    80003310:	70a2                	ld	ra,40(sp)
    80003312:	7402                	ld	s0,32(sp)
    80003314:	64e2                	ld	s1,24(sp)
    80003316:	6942                	ld	s2,16(sp)
    80003318:	69a2                	ld	s3,8(sp)
    8000331a:	6145                	add	sp,sp,48
    8000331c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000331e:	4581                	li	a1,0
    80003320:	8526                	mv	a0,s1
    80003322:	00003097          	auipc	ra,0x3
    80003326:	f80080e7          	jalr	-128(ra) # 800062a2 <virtio_disk_rw>
    b->valid = 1;
    8000332a:	4785                	li	a5,1
    8000332c:	c09c                	sw	a5,0(s1)
  return b;
    8000332e:	b7c5                	j	8000330e <bread+0xd0>

0000000080003330 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003330:	1101                	add	sp,sp,-32
    80003332:	ec06                	sd	ra,24(sp)
    80003334:	e822                	sd	s0,16(sp)
    80003336:	e426                	sd	s1,8(sp)
    80003338:	1000                	add	s0,sp,32
    8000333a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000333c:	0541                	add	a0,a0,16
    8000333e:	00001097          	auipc	ra,0x1
    80003342:	440080e7          	jalr	1088(ra) # 8000477e <holdingsleep>
    80003346:	cd01                	beqz	a0,8000335e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003348:	4585                	li	a1,1
    8000334a:	8526                	mv	a0,s1
    8000334c:	00003097          	auipc	ra,0x3
    80003350:	f56080e7          	jalr	-170(ra) # 800062a2 <virtio_disk_rw>
}
    80003354:	60e2                	ld	ra,24(sp)
    80003356:	6442                	ld	s0,16(sp)
    80003358:	64a2                	ld	s1,8(sp)
    8000335a:	6105                	add	sp,sp,32
    8000335c:	8082                	ret
    panic("bwrite");
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	21250513          	add	a0,a0,530 # 80008570 <syscalls+0xf8>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	1d6080e7          	jalr	470(ra) # 8000053c <panic>

000000008000336e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000336e:	1101                	add	sp,sp,-32
    80003370:	ec06                	sd	ra,24(sp)
    80003372:	e822                	sd	s0,16(sp)
    80003374:	e426                	sd	s1,8(sp)
    80003376:	e04a                	sd	s2,0(sp)
    80003378:	1000                	add	s0,sp,32
    8000337a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000337c:	01050913          	add	s2,a0,16
    80003380:	854a                	mv	a0,s2
    80003382:	00001097          	auipc	ra,0x1
    80003386:	3fc080e7          	jalr	1020(ra) # 8000477e <holdingsleep>
    8000338a:	c925                	beqz	a0,800033fa <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000338c:	854a                	mv	a0,s2
    8000338e:	00001097          	auipc	ra,0x1
    80003392:	3ac080e7          	jalr	940(ra) # 8000473a <releasesleep>

  acquire(&bcache.lock);
    80003396:	00016517          	auipc	a0,0x16
    8000339a:	05250513          	add	a0,a0,82 # 800193e8 <bcache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	834080e7          	jalr	-1996(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033a6:	40bc                	lw	a5,64(s1)
    800033a8:	37fd                	addw	a5,a5,-1
    800033aa:	0007871b          	sext.w	a4,a5
    800033ae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033b0:	e71d                	bnez	a4,800033de <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033b2:	68b8                	ld	a4,80(s1)
    800033b4:	64bc                	ld	a5,72(s1)
    800033b6:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800033b8:	68b8                	ld	a4,80(s1)
    800033ba:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033bc:	0001e797          	auipc	a5,0x1e
    800033c0:	02c78793          	add	a5,a5,44 # 800213e8 <bcache+0x8000>
    800033c4:	2b87b703          	ld	a4,696(a5)
    800033c8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ca:	0001e717          	auipc	a4,0x1e
    800033ce:	28670713          	add	a4,a4,646 # 80021650 <bcache+0x8268>
    800033d2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033d4:	2b87b703          	ld	a4,696(a5)
    800033d8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033da:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033de:	00016517          	auipc	a0,0x16
    800033e2:	00a50513          	add	a0,a0,10 # 800193e8 <bcache>
    800033e6:	ffffe097          	auipc	ra,0xffffe
    800033ea:	8a0080e7          	jalr	-1888(ra) # 80000c86 <release>
}
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	64a2                	ld	s1,8(sp)
    800033f4:	6902                	ld	s2,0(sp)
    800033f6:	6105                	add	sp,sp,32
    800033f8:	8082                	ret
    panic("brelse");
    800033fa:	00005517          	auipc	a0,0x5
    800033fe:	17e50513          	add	a0,a0,382 # 80008578 <syscalls+0x100>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	13a080e7          	jalr	314(ra) # 8000053c <panic>

000000008000340a <bpin>:

void
bpin(struct buf *b) {
    8000340a:	1101                	add	sp,sp,-32
    8000340c:	ec06                	sd	ra,24(sp)
    8000340e:	e822                	sd	s0,16(sp)
    80003410:	e426                	sd	s1,8(sp)
    80003412:	1000                	add	s0,sp,32
    80003414:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003416:	00016517          	auipc	a0,0x16
    8000341a:	fd250513          	add	a0,a0,-46 # 800193e8 <bcache>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	7b4080e7          	jalr	1972(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003426:	40bc                	lw	a5,64(s1)
    80003428:	2785                	addw	a5,a5,1
    8000342a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000342c:	00016517          	auipc	a0,0x16
    80003430:	fbc50513          	add	a0,a0,-68 # 800193e8 <bcache>
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	852080e7          	jalr	-1966(ra) # 80000c86 <release>
}
    8000343c:	60e2                	ld	ra,24(sp)
    8000343e:	6442                	ld	s0,16(sp)
    80003440:	64a2                	ld	s1,8(sp)
    80003442:	6105                	add	sp,sp,32
    80003444:	8082                	ret

0000000080003446 <bunpin>:

void
bunpin(struct buf *b) {
    80003446:	1101                	add	sp,sp,-32
    80003448:	ec06                	sd	ra,24(sp)
    8000344a:	e822                	sd	s0,16(sp)
    8000344c:	e426                	sd	s1,8(sp)
    8000344e:	1000                	add	s0,sp,32
    80003450:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003452:	00016517          	auipc	a0,0x16
    80003456:	f9650513          	add	a0,a0,-106 # 800193e8 <bcache>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	778080e7          	jalr	1912(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003462:	40bc                	lw	a5,64(s1)
    80003464:	37fd                	addw	a5,a5,-1
    80003466:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003468:	00016517          	auipc	a0,0x16
    8000346c:	f8050513          	add	a0,a0,-128 # 800193e8 <bcache>
    80003470:	ffffe097          	auipc	ra,0xffffe
    80003474:	816080e7          	jalr	-2026(ra) # 80000c86 <release>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6105                	add	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003482:	1101                	add	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	e426                	sd	s1,8(sp)
    8000348a:	e04a                	sd	s2,0(sp)
    8000348c:	1000                	add	s0,sp,32
    8000348e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003490:	00d5d59b          	srlw	a1,a1,0xd
    80003494:	0001e797          	auipc	a5,0x1e
    80003498:	6307a783          	lw	a5,1584(a5) # 80021ac4 <sb+0x1c>
    8000349c:	9dbd                	addw	a1,a1,a5
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	da0080e7          	jalr	-608(ra) # 8000323e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034a6:	0074f713          	and	a4,s1,7
    800034aa:	4785                	li	a5,1
    800034ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034b0:	14ce                	sll	s1,s1,0x33
    800034b2:	90d9                	srl	s1,s1,0x36
    800034b4:	00950733          	add	a4,a0,s1
    800034b8:	05874703          	lbu	a4,88(a4)
    800034bc:	00e7f6b3          	and	a3,a5,a4
    800034c0:	c69d                	beqz	a3,800034ee <bfree+0x6c>
    800034c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034c4:	94aa                	add	s1,s1,a0
    800034c6:	fff7c793          	not	a5,a5
    800034ca:	8f7d                	and	a4,a4,a5
    800034cc:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	0f6080e7          	jalr	246(ra) # 800045c6 <log_write>
  brelse(bp);
    800034d8:	854a                	mv	a0,s2
    800034da:	00000097          	auipc	ra,0x0
    800034de:	e94080e7          	jalr	-364(ra) # 8000336e <brelse>
}
    800034e2:	60e2                	ld	ra,24(sp)
    800034e4:	6442                	ld	s0,16(sp)
    800034e6:	64a2                	ld	s1,8(sp)
    800034e8:	6902                	ld	s2,0(sp)
    800034ea:	6105                	add	sp,sp,32
    800034ec:	8082                	ret
    panic("freeing free block");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	09250513          	add	a0,a0,146 # 80008580 <syscalls+0x108>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	046080e7          	jalr	70(ra) # 8000053c <panic>

00000000800034fe <balloc>:
{
    800034fe:	711d                	add	sp,sp,-96
    80003500:	ec86                	sd	ra,88(sp)
    80003502:	e8a2                	sd	s0,80(sp)
    80003504:	e4a6                	sd	s1,72(sp)
    80003506:	e0ca                	sd	s2,64(sp)
    80003508:	fc4e                	sd	s3,56(sp)
    8000350a:	f852                	sd	s4,48(sp)
    8000350c:	f456                	sd	s5,40(sp)
    8000350e:	f05a                	sd	s6,32(sp)
    80003510:	ec5e                	sd	s7,24(sp)
    80003512:	e862                	sd	s8,16(sp)
    80003514:	e466                	sd	s9,8(sp)
    80003516:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003518:	0001e797          	auipc	a5,0x1e
    8000351c:	5947a783          	lw	a5,1428(a5) # 80021aac <sb+0x4>
    80003520:	cff5                	beqz	a5,8000361c <balloc+0x11e>
    80003522:	8baa                	mv	s7,a0
    80003524:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003526:	0001eb17          	auipc	s6,0x1e
    8000352a:	582b0b13          	add	s6,s6,1410 # 80021aa8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003530:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003532:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003534:	6c89                	lui	s9,0x2
    80003536:	a061                	j	800035be <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003538:	97ca                	add	a5,a5,s2
    8000353a:	8e55                	or	a2,a2,a3
    8000353c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	084080e7          	jalr	132(ra) # 800045c6 <log_write>
        brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	e22080e7          	jalr	-478(ra) # 8000336e <brelse>
  bp = bread(dev, bno);
    80003554:	85a6                	mv	a1,s1
    80003556:	855e                	mv	a0,s7
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	ce6080e7          	jalr	-794(ra) # 8000323e <bread>
    80003560:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003562:	40000613          	li	a2,1024
    80003566:	4581                	li	a1,0
    80003568:	05850513          	add	a0,a0,88
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	762080e7          	jalr	1890(ra) # 80000cce <memset>
  log_write(bp);
    80003574:	854a                	mv	a0,s2
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	050080e7          	jalr	80(ra) # 800045c6 <log_write>
  brelse(bp);
    8000357e:	854a                	mv	a0,s2
    80003580:	00000097          	auipc	ra,0x0
    80003584:	dee080e7          	jalr	-530(ra) # 8000336e <brelse>
}
    80003588:	8526                	mv	a0,s1
    8000358a:	60e6                	ld	ra,88(sp)
    8000358c:	6446                	ld	s0,80(sp)
    8000358e:	64a6                	ld	s1,72(sp)
    80003590:	6906                	ld	s2,64(sp)
    80003592:	79e2                	ld	s3,56(sp)
    80003594:	7a42                	ld	s4,48(sp)
    80003596:	7aa2                	ld	s5,40(sp)
    80003598:	7b02                	ld	s6,32(sp)
    8000359a:	6be2                	ld	s7,24(sp)
    8000359c:	6c42                	ld	s8,16(sp)
    8000359e:	6ca2                	ld	s9,8(sp)
    800035a0:	6125                	add	sp,sp,96
    800035a2:	8082                	ret
    brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	dc8080e7          	jalr	-568(ra) # 8000336e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035ae:	015c87bb          	addw	a5,s9,s5
    800035b2:	00078a9b          	sext.w	s5,a5
    800035b6:	004b2703          	lw	a4,4(s6)
    800035ba:	06eaf163          	bgeu	s5,a4,8000361c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035be:	41fad79b          	sraw	a5,s5,0x1f
    800035c2:	0137d79b          	srlw	a5,a5,0x13
    800035c6:	015787bb          	addw	a5,a5,s5
    800035ca:	40d7d79b          	sraw	a5,a5,0xd
    800035ce:	01cb2583          	lw	a1,28(s6)
    800035d2:	9dbd                	addw	a1,a1,a5
    800035d4:	855e                	mv	a0,s7
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	c68080e7          	jalr	-920(ra) # 8000323e <bread>
    800035de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e0:	004b2503          	lw	a0,4(s6)
    800035e4:	000a849b          	sext.w	s1,s5
    800035e8:	8762                	mv	a4,s8
    800035ea:	faa4fde3          	bgeu	s1,a0,800035a4 <balloc+0xa6>
      m = 1 << (bi % 8);
    800035ee:	00777693          	and	a3,a4,7
    800035f2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035f6:	41f7579b          	sraw	a5,a4,0x1f
    800035fa:	01d7d79b          	srlw	a5,a5,0x1d
    800035fe:	9fb9                	addw	a5,a5,a4
    80003600:	4037d79b          	sraw	a5,a5,0x3
    80003604:	00f90633          	add	a2,s2,a5
    80003608:	05864603          	lbu	a2,88(a2)
    8000360c:	00c6f5b3          	and	a1,a3,a2
    80003610:	d585                	beqz	a1,80003538 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003612:	2705                	addw	a4,a4,1
    80003614:	2485                	addw	s1,s1,1
    80003616:	fd471ae3          	bne	a4,s4,800035ea <balloc+0xec>
    8000361a:	b769                	j	800035a4 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	f7c50513          	add	a0,a0,-132 # 80008598 <syscalls+0x120>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f62080e7          	jalr	-158(ra) # 80000586 <printf>
  return 0;
    8000362c:	4481                	li	s1,0
    8000362e:	bfa9                	j	80003588 <balloc+0x8a>

0000000080003630 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003630:	7179                	add	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	e052                	sd	s4,0(sp)
    8000363e:	1800                	add	s0,sp,48
    80003640:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003642:	47ad                	li	a5,11
    80003644:	02b7e863          	bltu	a5,a1,80003674 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003648:	02059793          	sll	a5,a1,0x20
    8000364c:	01e7d593          	srl	a1,a5,0x1e
    80003650:	00b504b3          	add	s1,a0,a1
    80003654:	0504a903          	lw	s2,80(s1)
    80003658:	06091e63          	bnez	s2,800036d4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000365c:	4108                	lw	a0,0(a0)
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	ea0080e7          	jalr	-352(ra) # 800034fe <balloc>
    80003666:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000366a:	06090563          	beqz	s2,800036d4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000366e:	0524a823          	sw	s2,80(s1)
    80003672:	a08d                	j	800036d4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003674:	ff45849b          	addw	s1,a1,-12
    80003678:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000367c:	0ff00793          	li	a5,255
    80003680:	08e7e563          	bltu	a5,a4,8000370a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003684:	08052903          	lw	s2,128(a0)
    80003688:	00091d63          	bnez	s2,800036a2 <bmap+0x72>
      addr = balloc(ip->dev);
    8000368c:	4108                	lw	a0,0(a0)
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	e70080e7          	jalr	-400(ra) # 800034fe <balloc>
    80003696:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000369a:	02090d63          	beqz	s2,800036d4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000369e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036a2:	85ca                	mv	a1,s2
    800036a4:	0009a503          	lw	a0,0(s3)
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	b96080e7          	jalr	-1130(ra) # 8000323e <bread>
    800036b0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036b2:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800036b6:	02049713          	sll	a4,s1,0x20
    800036ba:	01e75593          	srl	a1,a4,0x1e
    800036be:	00b784b3          	add	s1,a5,a1
    800036c2:	0004a903          	lw	s2,0(s1)
    800036c6:	02090063          	beqz	s2,800036e6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036ca:	8552                	mv	a0,s4
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	ca2080e7          	jalr	-862(ra) # 8000336e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036d4:	854a                	mv	a0,s2
    800036d6:	70a2                	ld	ra,40(sp)
    800036d8:	7402                	ld	s0,32(sp)
    800036da:	64e2                	ld	s1,24(sp)
    800036dc:	6942                	ld	s2,16(sp)
    800036de:	69a2                	ld	s3,8(sp)
    800036e0:	6a02                	ld	s4,0(sp)
    800036e2:	6145                	add	sp,sp,48
    800036e4:	8082                	ret
      addr = balloc(ip->dev);
    800036e6:	0009a503          	lw	a0,0(s3)
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	e14080e7          	jalr	-492(ra) # 800034fe <balloc>
    800036f2:	0005091b          	sext.w	s2,a0
      if(addr){
    800036f6:	fc090ae3          	beqz	s2,800036ca <bmap+0x9a>
        a[bn] = addr;
    800036fa:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036fe:	8552                	mv	a0,s4
    80003700:	00001097          	auipc	ra,0x1
    80003704:	ec6080e7          	jalr	-314(ra) # 800045c6 <log_write>
    80003708:	b7c9                	j	800036ca <bmap+0x9a>
  panic("bmap: out of range");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	ea650513          	add	a0,a0,-346 # 800085b0 <syscalls+0x138>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e2a080e7          	jalr	-470(ra) # 8000053c <panic>

000000008000371a <iget>:
{
    8000371a:	7179                	add	sp,sp,-48
    8000371c:	f406                	sd	ra,40(sp)
    8000371e:	f022                	sd	s0,32(sp)
    80003720:	ec26                	sd	s1,24(sp)
    80003722:	e84a                	sd	s2,16(sp)
    80003724:	e44e                	sd	s3,8(sp)
    80003726:	e052                	sd	s4,0(sp)
    80003728:	1800                	add	s0,sp,48
    8000372a:	89aa                	mv	s3,a0
    8000372c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000372e:	0001e517          	auipc	a0,0x1e
    80003732:	39a50513          	add	a0,a0,922 # 80021ac8 <itable>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	49c080e7          	jalr	1180(ra) # 80000bd2 <acquire>
  empty = 0;
    8000373e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003740:	0001e497          	auipc	s1,0x1e
    80003744:	3a048493          	add	s1,s1,928 # 80021ae0 <itable+0x18>
    80003748:	00020697          	auipc	a3,0x20
    8000374c:	e2868693          	add	a3,a3,-472 # 80023570 <log>
    80003750:	a039                	j	8000375e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003752:	02090b63          	beqz	s2,80003788 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003756:	08848493          	add	s1,s1,136
    8000375a:	02d48a63          	beq	s1,a3,8000378e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000375e:	449c                	lw	a5,8(s1)
    80003760:	fef059e3          	blez	a5,80003752 <iget+0x38>
    80003764:	4098                	lw	a4,0(s1)
    80003766:	ff3716e3          	bne	a4,s3,80003752 <iget+0x38>
    8000376a:	40d8                	lw	a4,4(s1)
    8000376c:	ff4713e3          	bne	a4,s4,80003752 <iget+0x38>
      ip->ref++;
    80003770:	2785                	addw	a5,a5,1
    80003772:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003774:	0001e517          	auipc	a0,0x1e
    80003778:	35450513          	add	a0,a0,852 # 80021ac8 <itable>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	50a080e7          	jalr	1290(ra) # 80000c86 <release>
      return ip;
    80003784:	8926                	mv	s2,s1
    80003786:	a03d                	j	800037b4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003788:	f7f9                	bnez	a5,80003756 <iget+0x3c>
    8000378a:	8926                	mv	s2,s1
    8000378c:	b7e9                	j	80003756 <iget+0x3c>
  if(empty == 0)
    8000378e:	02090c63          	beqz	s2,800037c6 <iget+0xac>
  ip->dev = dev;
    80003792:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003796:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000379a:	4785                	li	a5,1
    8000379c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037a0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037a4:	0001e517          	auipc	a0,0x1e
    800037a8:	32450513          	add	a0,a0,804 # 80021ac8 <itable>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	4da080e7          	jalr	1242(ra) # 80000c86 <release>
}
    800037b4:	854a                	mv	a0,s2
    800037b6:	70a2                	ld	ra,40(sp)
    800037b8:	7402                	ld	s0,32(sp)
    800037ba:	64e2                	ld	s1,24(sp)
    800037bc:	6942                	ld	s2,16(sp)
    800037be:	69a2                	ld	s3,8(sp)
    800037c0:	6a02                	ld	s4,0(sp)
    800037c2:	6145                	add	sp,sp,48
    800037c4:	8082                	ret
    panic("iget: no inodes");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	e0250513          	add	a0,a0,-510 # 800085c8 <syscalls+0x150>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d6e080e7          	jalr	-658(ra) # 8000053c <panic>

00000000800037d6 <fsinit>:
fsinit(int dev) {
    800037d6:	7179                	add	sp,sp,-48
    800037d8:	f406                	sd	ra,40(sp)
    800037da:	f022                	sd	s0,32(sp)
    800037dc:	ec26                	sd	s1,24(sp)
    800037de:	e84a                	sd	s2,16(sp)
    800037e0:	e44e                	sd	s3,8(sp)
    800037e2:	1800                	add	s0,sp,48
    800037e4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037e6:	4585                	li	a1,1
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	a56080e7          	jalr	-1450(ra) # 8000323e <bread>
    800037f0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f2:	0001e997          	auipc	s3,0x1e
    800037f6:	2b698993          	add	s3,s3,694 # 80021aa8 <sb>
    800037fa:	02000613          	li	a2,32
    800037fe:	05850593          	add	a1,a0,88
    80003802:	854e                	mv	a0,s3
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	526080e7          	jalr	1318(ra) # 80000d2a <memmove>
  brelse(bp);
    8000380c:	8526                	mv	a0,s1
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	b60080e7          	jalr	-1184(ra) # 8000336e <brelse>
  if(sb.magic != FSMAGIC)
    80003816:	0009a703          	lw	a4,0(s3)
    8000381a:	102037b7          	lui	a5,0x10203
    8000381e:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003822:	02f71263          	bne	a4,a5,80003846 <fsinit+0x70>
  initlog(dev, &sb);
    80003826:	0001e597          	auipc	a1,0x1e
    8000382a:	28258593          	add	a1,a1,642 # 80021aa8 <sb>
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	b2c080e7          	jalr	-1236(ra) # 8000435c <initlog>
}
    80003838:	70a2                	ld	ra,40(sp)
    8000383a:	7402                	ld	s0,32(sp)
    8000383c:	64e2                	ld	s1,24(sp)
    8000383e:	6942                	ld	s2,16(sp)
    80003840:	69a2                	ld	s3,8(sp)
    80003842:	6145                	add	sp,sp,48
    80003844:	8082                	ret
    panic("invalid file system");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	d9250513          	add	a0,a0,-622 # 800085d8 <syscalls+0x160>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cee080e7          	jalr	-786(ra) # 8000053c <panic>

0000000080003856 <iinit>:
{
    80003856:	7179                	add	sp,sp,-48
    80003858:	f406                	sd	ra,40(sp)
    8000385a:	f022                	sd	s0,32(sp)
    8000385c:	ec26                	sd	s1,24(sp)
    8000385e:	e84a                	sd	s2,16(sp)
    80003860:	e44e                	sd	s3,8(sp)
    80003862:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003864:	00005597          	auipc	a1,0x5
    80003868:	d8c58593          	add	a1,a1,-628 # 800085f0 <syscalls+0x178>
    8000386c:	0001e517          	auipc	a0,0x1e
    80003870:	25c50513          	add	a0,a0,604 # 80021ac8 <itable>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	2ce080e7          	jalr	718(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000387c:	0001e497          	auipc	s1,0x1e
    80003880:	27448493          	add	s1,s1,628 # 80021af0 <itable+0x28>
    80003884:	00020997          	auipc	s3,0x20
    80003888:	cfc98993          	add	s3,s3,-772 # 80023580 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000388c:	00005917          	auipc	s2,0x5
    80003890:	d6c90913          	add	s2,s2,-660 # 800085f8 <syscalls+0x180>
    80003894:	85ca                	mv	a1,s2
    80003896:	8526                	mv	a0,s1
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	e12080e7          	jalr	-494(ra) # 800046aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038a0:	08848493          	add	s1,s1,136
    800038a4:	ff3498e3          	bne	s1,s3,80003894 <iinit+0x3e>
}
    800038a8:	70a2                	ld	ra,40(sp)
    800038aa:	7402                	ld	s0,32(sp)
    800038ac:	64e2                	ld	s1,24(sp)
    800038ae:	6942                	ld	s2,16(sp)
    800038b0:	69a2                	ld	s3,8(sp)
    800038b2:	6145                	add	sp,sp,48
    800038b4:	8082                	ret

00000000800038b6 <ialloc>:
{
    800038b6:	7139                	add	sp,sp,-64
    800038b8:	fc06                	sd	ra,56(sp)
    800038ba:	f822                	sd	s0,48(sp)
    800038bc:	f426                	sd	s1,40(sp)
    800038be:	f04a                	sd	s2,32(sp)
    800038c0:	ec4e                	sd	s3,24(sp)
    800038c2:	e852                	sd	s4,16(sp)
    800038c4:	e456                	sd	s5,8(sp)
    800038c6:	e05a                	sd	s6,0(sp)
    800038c8:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ca:	0001e717          	auipc	a4,0x1e
    800038ce:	1ea72703          	lw	a4,490(a4) # 80021ab4 <sb+0xc>
    800038d2:	4785                	li	a5,1
    800038d4:	04e7f863          	bgeu	a5,a4,80003924 <ialloc+0x6e>
    800038d8:	8aaa                	mv	s5,a0
    800038da:	8b2e                	mv	s6,a1
    800038dc:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038de:	0001ea17          	auipc	s4,0x1e
    800038e2:	1caa0a13          	add	s4,s4,458 # 80021aa8 <sb>
    800038e6:	00495593          	srl	a1,s2,0x4
    800038ea:	018a2783          	lw	a5,24(s4)
    800038ee:	9dbd                	addw	a1,a1,a5
    800038f0:	8556                	mv	a0,s5
    800038f2:	00000097          	auipc	ra,0x0
    800038f6:	94c080e7          	jalr	-1716(ra) # 8000323e <bread>
    800038fa:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038fc:	05850993          	add	s3,a0,88
    80003900:	00f97793          	and	a5,s2,15
    80003904:	079a                	sll	a5,a5,0x6
    80003906:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003908:	00099783          	lh	a5,0(s3)
    8000390c:	cf9d                	beqz	a5,8000394a <ialloc+0x94>
    brelse(bp);
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	a60080e7          	jalr	-1440(ra) # 8000336e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003916:	0905                	add	s2,s2,1
    80003918:	00ca2703          	lw	a4,12(s4)
    8000391c:	0009079b          	sext.w	a5,s2
    80003920:	fce7e3e3          	bltu	a5,a4,800038e6 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003924:	00005517          	auipc	a0,0x5
    80003928:	cdc50513          	add	a0,a0,-804 # 80008600 <syscalls+0x188>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	c5a080e7          	jalr	-934(ra) # 80000586 <printf>
  return 0;
    80003934:	4501                	li	a0,0
}
    80003936:	70e2                	ld	ra,56(sp)
    80003938:	7442                	ld	s0,48(sp)
    8000393a:	74a2                	ld	s1,40(sp)
    8000393c:	7902                	ld	s2,32(sp)
    8000393e:	69e2                	ld	s3,24(sp)
    80003940:	6a42                	ld	s4,16(sp)
    80003942:	6aa2                	ld	s5,8(sp)
    80003944:	6b02                	ld	s6,0(sp)
    80003946:	6121                	add	sp,sp,64
    80003948:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000394a:	04000613          	li	a2,64
    8000394e:	4581                	li	a1,0
    80003950:	854e                	mv	a0,s3
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	37c080e7          	jalr	892(ra) # 80000cce <memset>
      dip->type = type;
    8000395a:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000395e:	8526                	mv	a0,s1
    80003960:	00001097          	auipc	ra,0x1
    80003964:	c66080e7          	jalr	-922(ra) # 800045c6 <log_write>
      brelse(bp);
    80003968:	8526                	mv	a0,s1
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	a04080e7          	jalr	-1532(ra) # 8000336e <brelse>
      return iget(dev, inum);
    80003972:	0009059b          	sext.w	a1,s2
    80003976:	8556                	mv	a0,s5
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	da2080e7          	jalr	-606(ra) # 8000371a <iget>
    80003980:	bf5d                	j	80003936 <ialloc+0x80>

0000000080003982 <iupdate>:
{
    80003982:	1101                	add	sp,sp,-32
    80003984:	ec06                	sd	ra,24(sp)
    80003986:	e822                	sd	s0,16(sp)
    80003988:	e426                	sd	s1,8(sp)
    8000398a:	e04a                	sd	s2,0(sp)
    8000398c:	1000                	add	s0,sp,32
    8000398e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003990:	415c                	lw	a5,4(a0)
    80003992:	0047d79b          	srlw	a5,a5,0x4
    80003996:	0001e597          	auipc	a1,0x1e
    8000399a:	12a5a583          	lw	a1,298(a1) # 80021ac0 <sb+0x18>
    8000399e:	9dbd                	addw	a1,a1,a5
    800039a0:	4108                	lw	a0,0(a0)
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	89c080e7          	jalr	-1892(ra) # 8000323e <bread>
    800039aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ac:	05850793          	add	a5,a0,88
    800039b0:	40d8                	lw	a4,4(s1)
    800039b2:	8b3d                	and	a4,a4,15
    800039b4:	071a                	sll	a4,a4,0x6
    800039b6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039b8:	04449703          	lh	a4,68(s1)
    800039bc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039c0:	04649703          	lh	a4,70(s1)
    800039c4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039c8:	04849703          	lh	a4,72(s1)
    800039cc:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039d0:	04a49703          	lh	a4,74(s1)
    800039d4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039d8:	44f8                	lw	a4,76(s1)
    800039da:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039dc:	03400613          	li	a2,52
    800039e0:	05048593          	add	a1,s1,80
    800039e4:	00c78513          	add	a0,a5,12
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	342080e7          	jalr	834(ra) # 80000d2a <memmove>
  log_write(bp);
    800039f0:	854a                	mv	a0,s2
    800039f2:	00001097          	auipc	ra,0x1
    800039f6:	bd4080e7          	jalr	-1068(ra) # 800045c6 <log_write>
  brelse(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	972080e7          	jalr	-1678(ra) # 8000336e <brelse>
}
    80003a04:	60e2                	ld	ra,24(sp)
    80003a06:	6442                	ld	s0,16(sp)
    80003a08:	64a2                	ld	s1,8(sp)
    80003a0a:	6902                	ld	s2,0(sp)
    80003a0c:	6105                	add	sp,sp,32
    80003a0e:	8082                	ret

0000000080003a10 <idup>:
{
    80003a10:	1101                	add	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	e426                	sd	s1,8(sp)
    80003a18:	1000                	add	s0,sp,32
    80003a1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a1c:	0001e517          	auipc	a0,0x1e
    80003a20:	0ac50513          	add	a0,a0,172 # 80021ac8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	1ae080e7          	jalr	430(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003a2c:	449c                	lw	a5,8(s1)
    80003a2e:	2785                	addw	a5,a5,1
    80003a30:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a32:	0001e517          	auipc	a0,0x1e
    80003a36:	09650513          	add	a0,a0,150 # 80021ac8 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	24c080e7          	jalr	588(ra) # 80000c86 <release>
}
    80003a42:	8526                	mv	a0,s1
    80003a44:	60e2                	ld	ra,24(sp)
    80003a46:	6442                	ld	s0,16(sp)
    80003a48:	64a2                	ld	s1,8(sp)
    80003a4a:	6105                	add	sp,sp,32
    80003a4c:	8082                	ret

0000000080003a4e <ilock>:
{
    80003a4e:	1101                	add	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	e04a                	sd	s2,0(sp)
    80003a58:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a5a:	c115                	beqz	a0,80003a7e <ilock+0x30>
    80003a5c:	84aa                	mv	s1,a0
    80003a5e:	451c                	lw	a5,8(a0)
    80003a60:	00f05f63          	blez	a5,80003a7e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a64:	0541                	add	a0,a0,16
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	c7e080e7          	jalr	-898(ra) # 800046e4 <acquiresleep>
  if(ip->valid == 0){
    80003a6e:	40bc                	lw	a5,64(s1)
    80003a70:	cf99                	beqz	a5,80003a8e <ilock+0x40>
}
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	64a2                	ld	s1,8(sp)
    80003a78:	6902                	ld	s2,0(sp)
    80003a7a:	6105                	add	sp,sp,32
    80003a7c:	8082                	ret
    panic("ilock");
    80003a7e:	00005517          	auipc	a0,0x5
    80003a82:	b9a50513          	add	a0,a0,-1126 # 80008618 <syscalls+0x1a0>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	ab6080e7          	jalr	-1354(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a8e:	40dc                	lw	a5,4(s1)
    80003a90:	0047d79b          	srlw	a5,a5,0x4
    80003a94:	0001e597          	auipc	a1,0x1e
    80003a98:	02c5a583          	lw	a1,44(a1) # 80021ac0 <sb+0x18>
    80003a9c:	9dbd                	addw	a1,a1,a5
    80003a9e:	4088                	lw	a0,0(s1)
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	79e080e7          	jalr	1950(ra) # 8000323e <bread>
    80003aa8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aaa:	05850593          	add	a1,a0,88
    80003aae:	40dc                	lw	a5,4(s1)
    80003ab0:	8bbd                	and	a5,a5,15
    80003ab2:	079a                	sll	a5,a5,0x6
    80003ab4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ab6:	00059783          	lh	a5,0(a1)
    80003aba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003abe:	00259783          	lh	a5,2(a1)
    80003ac2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ac6:	00459783          	lh	a5,4(a1)
    80003aca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ace:	00659783          	lh	a5,6(a1)
    80003ad2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ad6:	459c                	lw	a5,8(a1)
    80003ad8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ada:	03400613          	li	a2,52
    80003ade:	05b1                	add	a1,a1,12
    80003ae0:	05048513          	add	a0,s1,80
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	246080e7          	jalr	582(ra) # 80000d2a <memmove>
    brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	880080e7          	jalr	-1920(ra) # 8000336e <brelse>
    ip->valid = 1;
    80003af6:	4785                	li	a5,1
    80003af8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003afa:	04449783          	lh	a5,68(s1)
    80003afe:	fbb5                	bnez	a5,80003a72 <ilock+0x24>
      panic("ilock: no type");
    80003b00:	00005517          	auipc	a0,0x5
    80003b04:	b2050513          	add	a0,a0,-1248 # 80008620 <syscalls+0x1a8>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	a34080e7          	jalr	-1484(ra) # 8000053c <panic>

0000000080003b10 <iunlock>:
{
    80003b10:	1101                	add	sp,sp,-32
    80003b12:	ec06                	sd	ra,24(sp)
    80003b14:	e822                	sd	s0,16(sp)
    80003b16:	e426                	sd	s1,8(sp)
    80003b18:	e04a                	sd	s2,0(sp)
    80003b1a:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b1c:	c905                	beqz	a0,80003b4c <iunlock+0x3c>
    80003b1e:	84aa                	mv	s1,a0
    80003b20:	01050913          	add	s2,a0,16
    80003b24:	854a                	mv	a0,s2
    80003b26:	00001097          	auipc	ra,0x1
    80003b2a:	c58080e7          	jalr	-936(ra) # 8000477e <holdingsleep>
    80003b2e:	cd19                	beqz	a0,80003b4c <iunlock+0x3c>
    80003b30:	449c                	lw	a5,8(s1)
    80003b32:	00f05d63          	blez	a5,80003b4c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b36:	854a                	mv	a0,s2
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	c02080e7          	jalr	-1022(ra) # 8000473a <releasesleep>
}
    80003b40:	60e2                	ld	ra,24(sp)
    80003b42:	6442                	ld	s0,16(sp)
    80003b44:	64a2                	ld	s1,8(sp)
    80003b46:	6902                	ld	s2,0(sp)
    80003b48:	6105                	add	sp,sp,32
    80003b4a:	8082                	ret
    panic("iunlock");
    80003b4c:	00005517          	auipc	a0,0x5
    80003b50:	ae450513          	add	a0,a0,-1308 # 80008630 <syscalls+0x1b8>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	9e8080e7          	jalr	-1560(ra) # 8000053c <panic>

0000000080003b5c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b5c:	7179                	add	sp,sp,-48
    80003b5e:	f406                	sd	ra,40(sp)
    80003b60:	f022                	sd	s0,32(sp)
    80003b62:	ec26                	sd	s1,24(sp)
    80003b64:	e84a                	sd	s2,16(sp)
    80003b66:	e44e                	sd	s3,8(sp)
    80003b68:	e052                	sd	s4,0(sp)
    80003b6a:	1800                	add	s0,sp,48
    80003b6c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b6e:	05050493          	add	s1,a0,80
    80003b72:	08050913          	add	s2,a0,128
    80003b76:	a021                	j	80003b7e <itrunc+0x22>
    80003b78:	0491                	add	s1,s1,4
    80003b7a:	01248d63          	beq	s1,s2,80003b94 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b7e:	408c                	lw	a1,0(s1)
    80003b80:	dde5                	beqz	a1,80003b78 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b82:	0009a503          	lw	a0,0(s3)
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	8fc080e7          	jalr	-1796(ra) # 80003482 <bfree>
      ip->addrs[i] = 0;
    80003b8e:	0004a023          	sw	zero,0(s1)
    80003b92:	b7dd                	j	80003b78 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b94:	0809a583          	lw	a1,128(s3)
    80003b98:	e185                	bnez	a1,80003bb8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b9a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	de2080e7          	jalr	-542(ra) # 80003982 <iupdate>
}
    80003ba8:	70a2                	ld	ra,40(sp)
    80003baa:	7402                	ld	s0,32(sp)
    80003bac:	64e2                	ld	s1,24(sp)
    80003bae:	6942                	ld	s2,16(sp)
    80003bb0:	69a2                	ld	s3,8(sp)
    80003bb2:	6a02                	ld	s4,0(sp)
    80003bb4:	6145                	add	sp,sp,48
    80003bb6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bb8:	0009a503          	lw	a0,0(s3)
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	682080e7          	jalr	1666(ra) # 8000323e <bread>
    80003bc4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bc6:	05850493          	add	s1,a0,88
    80003bca:	45850913          	add	s2,a0,1112
    80003bce:	a021                	j	80003bd6 <itrunc+0x7a>
    80003bd0:	0491                	add	s1,s1,4
    80003bd2:	01248b63          	beq	s1,s2,80003be8 <itrunc+0x8c>
      if(a[j])
    80003bd6:	408c                	lw	a1,0(s1)
    80003bd8:	dde5                	beqz	a1,80003bd0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bda:	0009a503          	lw	a0,0(s3)
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	8a4080e7          	jalr	-1884(ra) # 80003482 <bfree>
    80003be6:	b7ed                	j	80003bd0 <itrunc+0x74>
    brelse(bp);
    80003be8:	8552                	mv	a0,s4
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	784080e7          	jalr	1924(ra) # 8000336e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf2:	0809a583          	lw	a1,128(s3)
    80003bf6:	0009a503          	lw	a0,0(s3)
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	888080e7          	jalr	-1912(ra) # 80003482 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c02:	0809a023          	sw	zero,128(s3)
    80003c06:	bf51                	j	80003b9a <itrunc+0x3e>

0000000080003c08 <iput>:
{
    80003c08:	1101                	add	sp,sp,-32
    80003c0a:	ec06                	sd	ra,24(sp)
    80003c0c:	e822                	sd	s0,16(sp)
    80003c0e:	e426                	sd	s1,8(sp)
    80003c10:	e04a                	sd	s2,0(sp)
    80003c12:	1000                	add	s0,sp,32
    80003c14:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c16:	0001e517          	auipc	a0,0x1e
    80003c1a:	eb250513          	add	a0,a0,-334 # 80021ac8 <itable>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	fb4080e7          	jalr	-76(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c26:	4498                	lw	a4,8(s1)
    80003c28:	4785                	li	a5,1
    80003c2a:	02f70363          	beq	a4,a5,80003c50 <iput+0x48>
  ip->ref--;
    80003c2e:	449c                	lw	a5,8(s1)
    80003c30:	37fd                	addw	a5,a5,-1
    80003c32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c34:	0001e517          	auipc	a0,0x1e
    80003c38:	e9450513          	add	a0,a0,-364 # 80021ac8 <itable>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	04a080e7          	jalr	74(ra) # 80000c86 <release>
}
    80003c44:	60e2                	ld	ra,24(sp)
    80003c46:	6442                	ld	s0,16(sp)
    80003c48:	64a2                	ld	s1,8(sp)
    80003c4a:	6902                	ld	s2,0(sp)
    80003c4c:	6105                	add	sp,sp,32
    80003c4e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c50:	40bc                	lw	a5,64(s1)
    80003c52:	dff1                	beqz	a5,80003c2e <iput+0x26>
    80003c54:	04a49783          	lh	a5,74(s1)
    80003c58:	fbf9                	bnez	a5,80003c2e <iput+0x26>
    acquiresleep(&ip->lock);
    80003c5a:	01048913          	add	s2,s1,16
    80003c5e:	854a                	mv	a0,s2
    80003c60:	00001097          	auipc	ra,0x1
    80003c64:	a84080e7          	jalr	-1404(ra) # 800046e4 <acquiresleep>
    release(&itable.lock);
    80003c68:	0001e517          	auipc	a0,0x1e
    80003c6c:	e6050513          	add	a0,a0,-416 # 80021ac8 <itable>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	016080e7          	jalr	22(ra) # 80000c86 <release>
    itrunc(ip);
    80003c78:	8526                	mv	a0,s1
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	ee2080e7          	jalr	-286(ra) # 80003b5c <itrunc>
    ip->type = 0;
    80003c82:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c86:	8526                	mv	a0,s1
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	cfa080e7          	jalr	-774(ra) # 80003982 <iupdate>
    ip->valid = 0;
    80003c90:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c94:	854a                	mv	a0,s2
    80003c96:	00001097          	auipc	ra,0x1
    80003c9a:	aa4080e7          	jalr	-1372(ra) # 8000473a <releasesleep>
    acquire(&itable.lock);
    80003c9e:	0001e517          	auipc	a0,0x1e
    80003ca2:	e2a50513          	add	a0,a0,-470 # 80021ac8 <itable>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	f2c080e7          	jalr	-212(ra) # 80000bd2 <acquire>
    80003cae:	b741                	j	80003c2e <iput+0x26>

0000000080003cb0 <iunlockput>:
{
    80003cb0:	1101                	add	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	1000                	add	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	e54080e7          	jalr	-428(ra) # 80003b10 <iunlock>
  iput(ip);
    80003cc4:	8526                	mv	a0,s1
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	f42080e7          	jalr	-190(ra) # 80003c08 <iput>
}
    80003cce:	60e2                	ld	ra,24(sp)
    80003cd0:	6442                	ld	s0,16(sp)
    80003cd2:	64a2                	ld	s1,8(sp)
    80003cd4:	6105                	add	sp,sp,32
    80003cd6:	8082                	ret

0000000080003cd8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cd8:	1141                	add	sp,sp,-16
    80003cda:	e422                	sd	s0,8(sp)
    80003cdc:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003cde:	411c                	lw	a5,0(a0)
    80003ce0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce2:	415c                	lw	a5,4(a0)
    80003ce4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ce6:	04451783          	lh	a5,68(a0)
    80003cea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cee:	04a51783          	lh	a5,74(a0)
    80003cf2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cf6:	04c56783          	lwu	a5,76(a0)
    80003cfa:	e99c                	sd	a5,16(a1)
}
    80003cfc:	6422                	ld	s0,8(sp)
    80003cfe:	0141                	add	sp,sp,16
    80003d00:	8082                	ret

0000000080003d02 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d02:	457c                	lw	a5,76(a0)
    80003d04:	0ed7e963          	bltu	a5,a3,80003df6 <readi+0xf4>
{
    80003d08:	7159                	add	sp,sp,-112
    80003d0a:	f486                	sd	ra,104(sp)
    80003d0c:	f0a2                	sd	s0,96(sp)
    80003d0e:	eca6                	sd	s1,88(sp)
    80003d10:	e8ca                	sd	s2,80(sp)
    80003d12:	e4ce                	sd	s3,72(sp)
    80003d14:	e0d2                	sd	s4,64(sp)
    80003d16:	fc56                	sd	s5,56(sp)
    80003d18:	f85a                	sd	s6,48(sp)
    80003d1a:	f45e                	sd	s7,40(sp)
    80003d1c:	f062                	sd	s8,32(sp)
    80003d1e:	ec66                	sd	s9,24(sp)
    80003d20:	e86a                	sd	s10,16(sp)
    80003d22:	e46e                	sd	s11,8(sp)
    80003d24:	1880                	add	s0,sp,112
    80003d26:	8b2a                	mv	s6,a0
    80003d28:	8bae                	mv	s7,a1
    80003d2a:	8a32                	mv	s4,a2
    80003d2c:	84b6                	mv	s1,a3
    80003d2e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d30:	9f35                	addw	a4,a4,a3
    return 0;
    80003d32:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d34:	0ad76063          	bltu	a4,a3,80003dd4 <readi+0xd2>
  if(off + n > ip->size)
    80003d38:	00e7f463          	bgeu	a5,a4,80003d40 <readi+0x3e>
    n = ip->size - off;
    80003d3c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d40:	0a0a8963          	beqz	s5,80003df2 <readi+0xf0>
    80003d44:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d46:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d4a:	5c7d                	li	s8,-1
    80003d4c:	a82d                	j	80003d86 <readi+0x84>
    80003d4e:	020d1d93          	sll	s11,s10,0x20
    80003d52:	020ddd93          	srl	s11,s11,0x20
    80003d56:	05890613          	add	a2,s2,88
    80003d5a:	86ee                	mv	a3,s11
    80003d5c:	963a                	add	a2,a2,a4
    80003d5e:	85d2                	mv	a1,s4
    80003d60:	855e                	mv	a0,s7
    80003d62:	ffffe097          	auipc	ra,0xffffe
    80003d66:	74e080e7          	jalr	1870(ra) # 800024b0 <either_copyout>
    80003d6a:	05850d63          	beq	a0,s8,80003dc4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d6e:	854a                	mv	a0,s2
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	5fe080e7          	jalr	1534(ra) # 8000336e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d78:	013d09bb          	addw	s3,s10,s3
    80003d7c:	009d04bb          	addw	s1,s10,s1
    80003d80:	9a6e                	add	s4,s4,s11
    80003d82:	0559f763          	bgeu	s3,s5,80003dd0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d86:	00a4d59b          	srlw	a1,s1,0xa
    80003d8a:	855a                	mv	a0,s6
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	8a4080e7          	jalr	-1884(ra) # 80003630 <bmap>
    80003d94:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d98:	cd85                	beqz	a1,80003dd0 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d9a:	000b2503          	lw	a0,0(s6)
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	4a0080e7          	jalr	1184(ra) # 8000323e <bread>
    80003da6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da8:	3ff4f713          	and	a4,s1,1023
    80003dac:	40ec87bb          	subw	a5,s9,a4
    80003db0:	413a86bb          	subw	a3,s5,s3
    80003db4:	8d3e                	mv	s10,a5
    80003db6:	2781                	sext.w	a5,a5
    80003db8:	0006861b          	sext.w	a2,a3
    80003dbc:	f8f679e3          	bgeu	a2,a5,80003d4e <readi+0x4c>
    80003dc0:	8d36                	mv	s10,a3
    80003dc2:	b771                	j	80003d4e <readi+0x4c>
      brelse(bp);
    80003dc4:	854a                	mv	a0,s2
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	5a8080e7          	jalr	1448(ra) # 8000336e <brelse>
      tot = -1;
    80003dce:	59fd                	li	s3,-1
  }
  return tot;
    80003dd0:	0009851b          	sext.w	a0,s3
}
    80003dd4:	70a6                	ld	ra,104(sp)
    80003dd6:	7406                	ld	s0,96(sp)
    80003dd8:	64e6                	ld	s1,88(sp)
    80003dda:	6946                	ld	s2,80(sp)
    80003ddc:	69a6                	ld	s3,72(sp)
    80003dde:	6a06                	ld	s4,64(sp)
    80003de0:	7ae2                	ld	s5,56(sp)
    80003de2:	7b42                	ld	s6,48(sp)
    80003de4:	7ba2                	ld	s7,40(sp)
    80003de6:	7c02                	ld	s8,32(sp)
    80003de8:	6ce2                	ld	s9,24(sp)
    80003dea:	6d42                	ld	s10,16(sp)
    80003dec:	6da2                	ld	s11,8(sp)
    80003dee:	6165                	add	sp,sp,112
    80003df0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df2:	89d6                	mv	s3,s5
    80003df4:	bff1                	j	80003dd0 <readi+0xce>
    return 0;
    80003df6:	4501                	li	a0,0
}
    80003df8:	8082                	ret

0000000080003dfa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dfa:	457c                	lw	a5,76(a0)
    80003dfc:	10d7e863          	bltu	a5,a3,80003f0c <writei+0x112>
{
    80003e00:	7159                	add	sp,sp,-112
    80003e02:	f486                	sd	ra,104(sp)
    80003e04:	f0a2                	sd	s0,96(sp)
    80003e06:	eca6                	sd	s1,88(sp)
    80003e08:	e8ca                	sd	s2,80(sp)
    80003e0a:	e4ce                	sd	s3,72(sp)
    80003e0c:	e0d2                	sd	s4,64(sp)
    80003e0e:	fc56                	sd	s5,56(sp)
    80003e10:	f85a                	sd	s6,48(sp)
    80003e12:	f45e                	sd	s7,40(sp)
    80003e14:	f062                	sd	s8,32(sp)
    80003e16:	ec66                	sd	s9,24(sp)
    80003e18:	e86a                	sd	s10,16(sp)
    80003e1a:	e46e                	sd	s11,8(sp)
    80003e1c:	1880                	add	s0,sp,112
    80003e1e:	8aaa                	mv	s5,a0
    80003e20:	8bae                	mv	s7,a1
    80003e22:	8a32                	mv	s4,a2
    80003e24:	8936                	mv	s2,a3
    80003e26:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e28:	00e687bb          	addw	a5,a3,a4
    80003e2c:	0ed7e263          	bltu	a5,a3,80003f10 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e30:	00043737          	lui	a4,0x43
    80003e34:	0ef76063          	bltu	a4,a5,80003f14 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e38:	0c0b0863          	beqz	s6,80003f08 <writei+0x10e>
    80003e3c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e3e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e42:	5c7d                	li	s8,-1
    80003e44:	a091                	j	80003e88 <writei+0x8e>
    80003e46:	020d1d93          	sll	s11,s10,0x20
    80003e4a:	020ddd93          	srl	s11,s11,0x20
    80003e4e:	05848513          	add	a0,s1,88
    80003e52:	86ee                	mv	a3,s11
    80003e54:	8652                	mv	a2,s4
    80003e56:	85de                	mv	a1,s7
    80003e58:	953a                	add	a0,a0,a4
    80003e5a:	ffffe097          	auipc	ra,0xffffe
    80003e5e:	6ac080e7          	jalr	1708(ra) # 80002506 <either_copyin>
    80003e62:	07850263          	beq	a0,s8,80003ec6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e66:	8526                	mv	a0,s1
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	75e080e7          	jalr	1886(ra) # 800045c6 <log_write>
    brelse(bp);
    80003e70:	8526                	mv	a0,s1
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	4fc080e7          	jalr	1276(ra) # 8000336e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e7a:	013d09bb          	addw	s3,s10,s3
    80003e7e:	012d093b          	addw	s2,s10,s2
    80003e82:	9a6e                	add	s4,s4,s11
    80003e84:	0569f663          	bgeu	s3,s6,80003ed0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e88:	00a9559b          	srlw	a1,s2,0xa
    80003e8c:	8556                	mv	a0,s5
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	7a2080e7          	jalr	1954(ra) # 80003630 <bmap>
    80003e96:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e9a:	c99d                	beqz	a1,80003ed0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e9c:	000aa503          	lw	a0,0(s5)
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	39e080e7          	jalr	926(ra) # 8000323e <bread>
    80003ea8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eaa:	3ff97713          	and	a4,s2,1023
    80003eae:	40ec87bb          	subw	a5,s9,a4
    80003eb2:	413b06bb          	subw	a3,s6,s3
    80003eb6:	8d3e                	mv	s10,a5
    80003eb8:	2781                	sext.w	a5,a5
    80003eba:	0006861b          	sext.w	a2,a3
    80003ebe:	f8f674e3          	bgeu	a2,a5,80003e46 <writei+0x4c>
    80003ec2:	8d36                	mv	s10,a3
    80003ec4:	b749                	j	80003e46 <writei+0x4c>
      brelse(bp);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	4a6080e7          	jalr	1190(ra) # 8000336e <brelse>
  }

  if(off > ip->size)
    80003ed0:	04caa783          	lw	a5,76(s5)
    80003ed4:	0127f463          	bgeu	a5,s2,80003edc <writei+0xe2>
    ip->size = off;
    80003ed8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003edc:	8556                	mv	a0,s5
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	aa4080e7          	jalr	-1372(ra) # 80003982 <iupdate>

  return tot;
    80003ee6:	0009851b          	sext.w	a0,s3
}
    80003eea:	70a6                	ld	ra,104(sp)
    80003eec:	7406                	ld	s0,96(sp)
    80003eee:	64e6                	ld	s1,88(sp)
    80003ef0:	6946                	ld	s2,80(sp)
    80003ef2:	69a6                	ld	s3,72(sp)
    80003ef4:	6a06                	ld	s4,64(sp)
    80003ef6:	7ae2                	ld	s5,56(sp)
    80003ef8:	7b42                	ld	s6,48(sp)
    80003efa:	7ba2                	ld	s7,40(sp)
    80003efc:	7c02                	ld	s8,32(sp)
    80003efe:	6ce2                	ld	s9,24(sp)
    80003f00:	6d42                	ld	s10,16(sp)
    80003f02:	6da2                	ld	s11,8(sp)
    80003f04:	6165                	add	sp,sp,112
    80003f06:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f08:	89da                	mv	s3,s6
    80003f0a:	bfc9                	j	80003edc <writei+0xe2>
    return -1;
    80003f0c:	557d                	li	a0,-1
}
    80003f0e:	8082                	ret
    return -1;
    80003f10:	557d                	li	a0,-1
    80003f12:	bfe1                	j	80003eea <writei+0xf0>
    return -1;
    80003f14:	557d                	li	a0,-1
    80003f16:	bfd1                	j	80003eea <writei+0xf0>

0000000080003f18 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f18:	1141                	add	sp,sp,-16
    80003f1a:	e406                	sd	ra,8(sp)
    80003f1c:	e022                	sd	s0,0(sp)
    80003f1e:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f20:	4639                	li	a2,14
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	e7c080e7          	jalr	-388(ra) # 80000d9e <strncmp>
}
    80003f2a:	60a2                	ld	ra,8(sp)
    80003f2c:	6402                	ld	s0,0(sp)
    80003f2e:	0141                	add	sp,sp,16
    80003f30:	8082                	ret

0000000080003f32 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f32:	7139                	add	sp,sp,-64
    80003f34:	fc06                	sd	ra,56(sp)
    80003f36:	f822                	sd	s0,48(sp)
    80003f38:	f426                	sd	s1,40(sp)
    80003f3a:	f04a                	sd	s2,32(sp)
    80003f3c:	ec4e                	sd	s3,24(sp)
    80003f3e:	e852                	sd	s4,16(sp)
    80003f40:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f42:	04451703          	lh	a4,68(a0)
    80003f46:	4785                	li	a5,1
    80003f48:	00f71a63          	bne	a4,a5,80003f5c <dirlookup+0x2a>
    80003f4c:	892a                	mv	s2,a0
    80003f4e:	89ae                	mv	s3,a1
    80003f50:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f52:	457c                	lw	a5,76(a0)
    80003f54:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f56:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f58:	e79d                	bnez	a5,80003f86 <dirlookup+0x54>
    80003f5a:	a8a5                	j	80003fd2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f5c:	00004517          	auipc	a0,0x4
    80003f60:	6dc50513          	add	a0,a0,1756 # 80008638 <syscalls+0x1c0>
    80003f64:	ffffc097          	auipc	ra,0xffffc
    80003f68:	5d8080e7          	jalr	1496(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003f6c:	00004517          	auipc	a0,0x4
    80003f70:	6e450513          	add	a0,a0,1764 # 80008650 <syscalls+0x1d8>
    80003f74:	ffffc097          	auipc	ra,0xffffc
    80003f78:	5c8080e7          	jalr	1480(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7c:	24c1                	addw	s1,s1,16
    80003f7e:	04c92783          	lw	a5,76(s2)
    80003f82:	04f4f763          	bgeu	s1,a5,80003fd0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f86:	4741                	li	a4,16
    80003f88:	86a6                	mv	a3,s1
    80003f8a:	fc040613          	add	a2,s0,-64
    80003f8e:	4581                	li	a1,0
    80003f90:	854a                	mv	a0,s2
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	d70080e7          	jalr	-656(ra) # 80003d02 <readi>
    80003f9a:	47c1                	li	a5,16
    80003f9c:	fcf518e3          	bne	a0,a5,80003f6c <dirlookup+0x3a>
    if(de.inum == 0)
    80003fa0:	fc045783          	lhu	a5,-64(s0)
    80003fa4:	dfe1                	beqz	a5,80003f7c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fa6:	fc240593          	add	a1,s0,-62
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	f6c080e7          	jalr	-148(ra) # 80003f18 <namecmp>
    80003fb4:	f561                	bnez	a0,80003f7c <dirlookup+0x4a>
      if(poff)
    80003fb6:	000a0463          	beqz	s4,80003fbe <dirlookup+0x8c>
        *poff = off;
    80003fba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fbe:	fc045583          	lhu	a1,-64(s0)
    80003fc2:	00092503          	lw	a0,0(s2)
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	754080e7          	jalr	1876(ra) # 8000371a <iget>
    80003fce:	a011                	j	80003fd2 <dirlookup+0xa0>
  return 0;
    80003fd0:	4501                	li	a0,0
}
    80003fd2:	70e2                	ld	ra,56(sp)
    80003fd4:	7442                	ld	s0,48(sp)
    80003fd6:	74a2                	ld	s1,40(sp)
    80003fd8:	7902                	ld	s2,32(sp)
    80003fda:	69e2                	ld	s3,24(sp)
    80003fdc:	6a42                	ld	s4,16(sp)
    80003fde:	6121                	add	sp,sp,64
    80003fe0:	8082                	ret

0000000080003fe2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fe2:	711d                	add	sp,sp,-96
    80003fe4:	ec86                	sd	ra,88(sp)
    80003fe6:	e8a2                	sd	s0,80(sp)
    80003fe8:	e4a6                	sd	s1,72(sp)
    80003fea:	e0ca                	sd	s2,64(sp)
    80003fec:	fc4e                	sd	s3,56(sp)
    80003fee:	f852                	sd	s4,48(sp)
    80003ff0:	f456                	sd	s5,40(sp)
    80003ff2:	f05a                	sd	s6,32(sp)
    80003ff4:	ec5e                	sd	s7,24(sp)
    80003ff6:	e862                	sd	s8,16(sp)
    80003ff8:	e466                	sd	s9,8(sp)
    80003ffa:	1080                	add	s0,sp,96
    80003ffc:	84aa                	mv	s1,a0
    80003ffe:	8b2e                	mv	s6,a1
    80004000:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004002:	00054703          	lbu	a4,0(a0)
    80004006:	02f00793          	li	a5,47
    8000400a:	02f70263          	beq	a4,a5,8000402e <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000400e:	ffffe097          	auipc	ra,0xffffe
    80004012:	998080e7          	jalr	-1640(ra) # 800019a6 <myproc>
    80004016:	15053503          	ld	a0,336(a0)
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	9f6080e7          	jalr	-1546(ra) # 80003a10 <idup>
    80004022:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004024:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004028:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000402a:	4b85                	li	s7,1
    8000402c:	a875                	j	800040e8 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000402e:	4585                	li	a1,1
    80004030:	4505                	li	a0,1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	6e8080e7          	jalr	1768(ra) # 8000371a <iget>
    8000403a:	8a2a                	mv	s4,a0
    8000403c:	b7e5                	j	80004024 <namex+0x42>
      iunlockput(ip);
    8000403e:	8552                	mv	a0,s4
    80004040:	00000097          	auipc	ra,0x0
    80004044:	c70080e7          	jalr	-912(ra) # 80003cb0 <iunlockput>
      return 0;
    80004048:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000404a:	8552                	mv	a0,s4
    8000404c:	60e6                	ld	ra,88(sp)
    8000404e:	6446                	ld	s0,80(sp)
    80004050:	64a6                	ld	s1,72(sp)
    80004052:	6906                	ld	s2,64(sp)
    80004054:	79e2                	ld	s3,56(sp)
    80004056:	7a42                	ld	s4,48(sp)
    80004058:	7aa2                	ld	s5,40(sp)
    8000405a:	7b02                	ld	s6,32(sp)
    8000405c:	6be2                	ld	s7,24(sp)
    8000405e:	6c42                	ld	s8,16(sp)
    80004060:	6ca2                	ld	s9,8(sp)
    80004062:	6125                	add	sp,sp,96
    80004064:	8082                	ret
      iunlock(ip);
    80004066:	8552                	mv	a0,s4
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	aa8080e7          	jalr	-1368(ra) # 80003b10 <iunlock>
      return ip;
    80004070:	bfe9                	j	8000404a <namex+0x68>
      iunlockput(ip);
    80004072:	8552                	mv	a0,s4
    80004074:	00000097          	auipc	ra,0x0
    80004078:	c3c080e7          	jalr	-964(ra) # 80003cb0 <iunlockput>
      return 0;
    8000407c:	8a4e                	mv	s4,s3
    8000407e:	b7f1                	j	8000404a <namex+0x68>
  len = path - s;
    80004080:	40998633          	sub	a2,s3,s1
    80004084:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004088:	099c5863          	bge	s8,s9,80004118 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000408c:	4639                	li	a2,14
    8000408e:	85a6                	mv	a1,s1
    80004090:	8556                	mv	a0,s5
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	c98080e7          	jalr	-872(ra) # 80000d2a <memmove>
    8000409a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000409c:	0004c783          	lbu	a5,0(s1)
    800040a0:	01279763          	bne	a5,s2,800040ae <namex+0xcc>
    path++;
    800040a4:	0485                	add	s1,s1,1
  while(*path == '/')
    800040a6:	0004c783          	lbu	a5,0(s1)
    800040aa:	ff278de3          	beq	a5,s2,800040a4 <namex+0xc2>
    ilock(ip);
    800040ae:	8552                	mv	a0,s4
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	99e080e7          	jalr	-1634(ra) # 80003a4e <ilock>
    if(ip->type != T_DIR){
    800040b8:	044a1783          	lh	a5,68(s4)
    800040bc:	f97791e3          	bne	a5,s7,8000403e <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800040c0:	000b0563          	beqz	s6,800040ca <namex+0xe8>
    800040c4:	0004c783          	lbu	a5,0(s1)
    800040c8:	dfd9                	beqz	a5,80004066 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040ca:	4601                	li	a2,0
    800040cc:	85d6                	mv	a1,s5
    800040ce:	8552                	mv	a0,s4
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	e62080e7          	jalr	-414(ra) # 80003f32 <dirlookup>
    800040d8:	89aa                	mv	s3,a0
    800040da:	dd41                	beqz	a0,80004072 <namex+0x90>
    iunlockput(ip);
    800040dc:	8552                	mv	a0,s4
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	bd2080e7          	jalr	-1070(ra) # 80003cb0 <iunlockput>
    ip = next;
    800040e6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040e8:	0004c783          	lbu	a5,0(s1)
    800040ec:	01279763          	bne	a5,s2,800040fa <namex+0x118>
    path++;
    800040f0:	0485                	add	s1,s1,1
  while(*path == '/')
    800040f2:	0004c783          	lbu	a5,0(s1)
    800040f6:	ff278de3          	beq	a5,s2,800040f0 <namex+0x10e>
  if(*path == 0)
    800040fa:	cb9d                	beqz	a5,80004130 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800040fc:	0004c783          	lbu	a5,0(s1)
    80004100:	89a6                	mv	s3,s1
  len = path - s;
    80004102:	4c81                	li	s9,0
    80004104:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004106:	01278963          	beq	a5,s2,80004118 <namex+0x136>
    8000410a:	dbbd                	beqz	a5,80004080 <namex+0x9e>
    path++;
    8000410c:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000410e:	0009c783          	lbu	a5,0(s3)
    80004112:	ff279ce3          	bne	a5,s2,8000410a <namex+0x128>
    80004116:	b7ad                	j	80004080 <namex+0x9e>
    memmove(name, s, len);
    80004118:	2601                	sext.w	a2,a2
    8000411a:	85a6                	mv	a1,s1
    8000411c:	8556                	mv	a0,s5
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	c0c080e7          	jalr	-1012(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004126:	9cd6                	add	s9,s9,s5
    80004128:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000412c:	84ce                	mv	s1,s3
    8000412e:	b7bd                	j	8000409c <namex+0xba>
  if(nameiparent){
    80004130:	f00b0de3          	beqz	s6,8000404a <namex+0x68>
    iput(ip);
    80004134:	8552                	mv	a0,s4
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	ad2080e7          	jalr	-1326(ra) # 80003c08 <iput>
    return 0;
    8000413e:	4a01                	li	s4,0
    80004140:	b729                	j	8000404a <namex+0x68>

0000000080004142 <dirlink>:
{
    80004142:	7139                	add	sp,sp,-64
    80004144:	fc06                	sd	ra,56(sp)
    80004146:	f822                	sd	s0,48(sp)
    80004148:	f426                	sd	s1,40(sp)
    8000414a:	f04a                	sd	s2,32(sp)
    8000414c:	ec4e                	sd	s3,24(sp)
    8000414e:	e852                	sd	s4,16(sp)
    80004150:	0080                	add	s0,sp,64
    80004152:	892a                	mv	s2,a0
    80004154:	8a2e                	mv	s4,a1
    80004156:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004158:	4601                	li	a2,0
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	dd8080e7          	jalr	-552(ra) # 80003f32 <dirlookup>
    80004162:	e93d                	bnez	a0,800041d8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004164:	04c92483          	lw	s1,76(s2)
    80004168:	c49d                	beqz	s1,80004196 <dirlink+0x54>
    8000416a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000416c:	4741                	li	a4,16
    8000416e:	86a6                	mv	a3,s1
    80004170:	fc040613          	add	a2,s0,-64
    80004174:	4581                	li	a1,0
    80004176:	854a                	mv	a0,s2
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	b8a080e7          	jalr	-1142(ra) # 80003d02 <readi>
    80004180:	47c1                	li	a5,16
    80004182:	06f51163          	bne	a0,a5,800041e4 <dirlink+0xa2>
    if(de.inum == 0)
    80004186:	fc045783          	lhu	a5,-64(s0)
    8000418a:	c791                	beqz	a5,80004196 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418c:	24c1                	addw	s1,s1,16
    8000418e:	04c92783          	lw	a5,76(s2)
    80004192:	fcf4ede3          	bltu	s1,a5,8000416c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004196:	4639                	li	a2,14
    80004198:	85d2                	mv	a1,s4
    8000419a:	fc240513          	add	a0,s0,-62
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	c3c080e7          	jalr	-964(ra) # 80000dda <strncpy>
  de.inum = inum;
    800041a6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041aa:	4741                	li	a4,16
    800041ac:	86a6                	mv	a3,s1
    800041ae:	fc040613          	add	a2,s0,-64
    800041b2:	4581                	li	a1,0
    800041b4:	854a                	mv	a0,s2
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	c44080e7          	jalr	-956(ra) # 80003dfa <writei>
    800041be:	1541                	add	a0,a0,-16
    800041c0:	00a03533          	snez	a0,a0
    800041c4:	40a00533          	neg	a0,a0
}
    800041c8:	70e2                	ld	ra,56(sp)
    800041ca:	7442                	ld	s0,48(sp)
    800041cc:	74a2                	ld	s1,40(sp)
    800041ce:	7902                	ld	s2,32(sp)
    800041d0:	69e2                	ld	s3,24(sp)
    800041d2:	6a42                	ld	s4,16(sp)
    800041d4:	6121                	add	sp,sp,64
    800041d6:	8082                	ret
    iput(ip);
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	a30080e7          	jalr	-1488(ra) # 80003c08 <iput>
    return -1;
    800041e0:	557d                	li	a0,-1
    800041e2:	b7dd                	j	800041c8 <dirlink+0x86>
      panic("dirlink read");
    800041e4:	00004517          	auipc	a0,0x4
    800041e8:	47c50513          	add	a0,a0,1148 # 80008660 <syscalls+0x1e8>
    800041ec:	ffffc097          	auipc	ra,0xffffc
    800041f0:	350080e7          	jalr	848(ra) # 8000053c <panic>

00000000800041f4 <namei>:

struct inode*
namei(char *path)
{
    800041f4:	1101                	add	sp,sp,-32
    800041f6:	ec06                	sd	ra,24(sp)
    800041f8:	e822                	sd	s0,16(sp)
    800041fa:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041fc:	fe040613          	add	a2,s0,-32
    80004200:	4581                	li	a1,0
    80004202:	00000097          	auipc	ra,0x0
    80004206:	de0080e7          	jalr	-544(ra) # 80003fe2 <namex>
}
    8000420a:	60e2                	ld	ra,24(sp)
    8000420c:	6442                	ld	s0,16(sp)
    8000420e:	6105                	add	sp,sp,32
    80004210:	8082                	ret

0000000080004212 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004212:	1141                	add	sp,sp,-16
    80004214:	e406                	sd	ra,8(sp)
    80004216:	e022                	sd	s0,0(sp)
    80004218:	0800                	add	s0,sp,16
    8000421a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000421c:	4585                	li	a1,1
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	dc4080e7          	jalr	-572(ra) # 80003fe2 <namex>
}
    80004226:	60a2                	ld	ra,8(sp)
    80004228:	6402                	ld	s0,0(sp)
    8000422a:	0141                	add	sp,sp,16
    8000422c:	8082                	ret

000000008000422e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000422e:	1101                	add	sp,sp,-32
    80004230:	ec06                	sd	ra,24(sp)
    80004232:	e822                	sd	s0,16(sp)
    80004234:	e426                	sd	s1,8(sp)
    80004236:	e04a                	sd	s2,0(sp)
    80004238:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000423a:	0001f917          	auipc	s2,0x1f
    8000423e:	33690913          	add	s2,s2,822 # 80023570 <log>
    80004242:	01892583          	lw	a1,24(s2)
    80004246:	02892503          	lw	a0,40(s2)
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	ff4080e7          	jalr	-12(ra) # 8000323e <bread>
    80004252:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004254:	02c92603          	lw	a2,44(s2)
    80004258:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000425a:	00c05f63          	blez	a2,80004278 <write_head+0x4a>
    8000425e:	0001f717          	auipc	a4,0x1f
    80004262:	34270713          	add	a4,a4,834 # 800235a0 <log+0x30>
    80004266:	87aa                	mv	a5,a0
    80004268:	060a                	sll	a2,a2,0x2
    8000426a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000426c:	4314                	lw	a3,0(a4)
    8000426e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004270:	0711                	add	a4,a4,4
    80004272:	0791                	add	a5,a5,4
    80004274:	fec79ce3          	bne	a5,a2,8000426c <write_head+0x3e>
  }
  bwrite(buf);
    80004278:	8526                	mv	a0,s1
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	0b6080e7          	jalr	182(ra) # 80003330 <bwrite>
  brelse(buf);
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	0ea080e7          	jalr	234(ra) # 8000336e <brelse>
}
    8000428c:	60e2                	ld	ra,24(sp)
    8000428e:	6442                	ld	s0,16(sp)
    80004290:	64a2                	ld	s1,8(sp)
    80004292:	6902                	ld	s2,0(sp)
    80004294:	6105                	add	sp,sp,32
    80004296:	8082                	ret

0000000080004298 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004298:	0001f797          	auipc	a5,0x1f
    8000429c:	3047a783          	lw	a5,772(a5) # 8002359c <log+0x2c>
    800042a0:	0af05d63          	blez	a5,8000435a <install_trans+0xc2>
{
    800042a4:	7139                	add	sp,sp,-64
    800042a6:	fc06                	sd	ra,56(sp)
    800042a8:	f822                	sd	s0,48(sp)
    800042aa:	f426                	sd	s1,40(sp)
    800042ac:	f04a                	sd	s2,32(sp)
    800042ae:	ec4e                	sd	s3,24(sp)
    800042b0:	e852                	sd	s4,16(sp)
    800042b2:	e456                	sd	s5,8(sp)
    800042b4:	e05a                	sd	s6,0(sp)
    800042b6:	0080                	add	s0,sp,64
    800042b8:	8b2a                	mv	s6,a0
    800042ba:	0001fa97          	auipc	s5,0x1f
    800042be:	2e6a8a93          	add	s5,s5,742 # 800235a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042c4:	0001f997          	auipc	s3,0x1f
    800042c8:	2ac98993          	add	s3,s3,684 # 80023570 <log>
    800042cc:	a00d                	j	800042ee <install_trans+0x56>
    brelse(lbuf);
    800042ce:	854a                	mv	a0,s2
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	09e080e7          	jalr	158(ra) # 8000336e <brelse>
    brelse(dbuf);
    800042d8:	8526                	mv	a0,s1
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	094080e7          	jalr	148(ra) # 8000336e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e2:	2a05                	addw	s4,s4,1
    800042e4:	0a91                	add	s5,s5,4
    800042e6:	02c9a783          	lw	a5,44(s3)
    800042ea:	04fa5e63          	bge	s4,a5,80004346 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042ee:	0189a583          	lw	a1,24(s3)
    800042f2:	014585bb          	addw	a1,a1,s4
    800042f6:	2585                	addw	a1,a1,1
    800042f8:	0289a503          	lw	a0,40(s3)
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	f42080e7          	jalr	-190(ra) # 8000323e <bread>
    80004304:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004306:	000aa583          	lw	a1,0(s5)
    8000430a:	0289a503          	lw	a0,40(s3)
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	f30080e7          	jalr	-208(ra) # 8000323e <bread>
    80004316:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004318:	40000613          	li	a2,1024
    8000431c:	05890593          	add	a1,s2,88
    80004320:	05850513          	add	a0,a0,88
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	a06080e7          	jalr	-1530(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000432c:	8526                	mv	a0,s1
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	002080e7          	jalr	2(ra) # 80003330 <bwrite>
    if(recovering == 0)
    80004336:	f80b1ce3          	bnez	s6,800042ce <install_trans+0x36>
      bunpin(dbuf);
    8000433a:	8526                	mv	a0,s1
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	10a080e7          	jalr	266(ra) # 80003446 <bunpin>
    80004344:	b769                	j	800042ce <install_trans+0x36>
}
    80004346:	70e2                	ld	ra,56(sp)
    80004348:	7442                	ld	s0,48(sp)
    8000434a:	74a2                	ld	s1,40(sp)
    8000434c:	7902                	ld	s2,32(sp)
    8000434e:	69e2                	ld	s3,24(sp)
    80004350:	6a42                	ld	s4,16(sp)
    80004352:	6aa2                	ld	s5,8(sp)
    80004354:	6b02                	ld	s6,0(sp)
    80004356:	6121                	add	sp,sp,64
    80004358:	8082                	ret
    8000435a:	8082                	ret

000000008000435c <initlog>:
{
    8000435c:	7179                	add	sp,sp,-48
    8000435e:	f406                	sd	ra,40(sp)
    80004360:	f022                	sd	s0,32(sp)
    80004362:	ec26                	sd	s1,24(sp)
    80004364:	e84a                	sd	s2,16(sp)
    80004366:	e44e                	sd	s3,8(sp)
    80004368:	1800                	add	s0,sp,48
    8000436a:	892a                	mv	s2,a0
    8000436c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000436e:	0001f497          	auipc	s1,0x1f
    80004372:	20248493          	add	s1,s1,514 # 80023570 <log>
    80004376:	00004597          	auipc	a1,0x4
    8000437a:	2fa58593          	add	a1,a1,762 # 80008670 <syscalls+0x1f8>
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffc097          	auipc	ra,0xffffc
    80004384:	7c2080e7          	jalr	1986(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004388:	0149a583          	lw	a1,20(s3)
    8000438c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000438e:	0109a783          	lw	a5,16(s3)
    80004392:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004394:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004398:	854a                	mv	a0,s2
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	ea4080e7          	jalr	-348(ra) # 8000323e <bread>
  log.lh.n = lh->n;
    800043a2:	4d30                	lw	a2,88(a0)
    800043a4:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043a6:	00c05f63          	blez	a2,800043c4 <initlog+0x68>
    800043aa:	87aa                	mv	a5,a0
    800043ac:	0001f717          	auipc	a4,0x1f
    800043b0:	1f470713          	add	a4,a4,500 # 800235a0 <log+0x30>
    800043b4:	060a                	sll	a2,a2,0x2
    800043b6:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800043b8:	4ff4                	lw	a3,92(a5)
    800043ba:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	0791                	add	a5,a5,4
    800043be:	0711                	add	a4,a4,4
    800043c0:	fec79ce3          	bne	a5,a2,800043b8 <initlog+0x5c>
  brelse(buf);
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	faa080e7          	jalr	-86(ra) # 8000336e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043cc:	4505                	li	a0,1
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	eca080e7          	jalr	-310(ra) # 80004298 <install_trans>
  log.lh.n = 0;
    800043d6:	0001f797          	auipc	a5,0x1f
    800043da:	1c07a323          	sw	zero,454(a5) # 8002359c <log+0x2c>
  write_head(); // clear the log
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	e50080e7          	jalr	-432(ra) # 8000422e <write_head>
}
    800043e6:	70a2                	ld	ra,40(sp)
    800043e8:	7402                	ld	s0,32(sp)
    800043ea:	64e2                	ld	s1,24(sp)
    800043ec:	6942                	ld	s2,16(sp)
    800043ee:	69a2                	ld	s3,8(sp)
    800043f0:	6145                	add	sp,sp,48
    800043f2:	8082                	ret

00000000800043f4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043f4:	1101                	add	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	e426                	sd	s1,8(sp)
    800043fc:	e04a                	sd	s2,0(sp)
    800043fe:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004400:	0001f517          	auipc	a0,0x1f
    80004404:	17050513          	add	a0,a0,368 # 80023570 <log>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	7ca080e7          	jalr	1994(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004410:	0001f497          	auipc	s1,0x1f
    80004414:	16048493          	add	s1,s1,352 # 80023570 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004418:	4979                	li	s2,30
    8000441a:	a039                	j	80004428 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000441c:	85a6                	mv	a1,s1
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffe097          	auipc	ra,0xffffe
    80004424:	c64080e7          	jalr	-924(ra) # 80002084 <sleep>
    if(log.committing){
    80004428:	50dc                	lw	a5,36(s1)
    8000442a:	fbed                	bnez	a5,8000441c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000442c:	5098                	lw	a4,32(s1)
    8000442e:	2705                	addw	a4,a4,1
    80004430:	0027179b          	sllw	a5,a4,0x2
    80004434:	9fb9                	addw	a5,a5,a4
    80004436:	0017979b          	sllw	a5,a5,0x1
    8000443a:	54d4                	lw	a3,44(s1)
    8000443c:	9fb5                	addw	a5,a5,a3
    8000443e:	00f95963          	bge	s2,a5,80004450 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004442:	85a6                	mv	a1,s1
    80004444:	8526                	mv	a0,s1
    80004446:	ffffe097          	auipc	ra,0xffffe
    8000444a:	c3e080e7          	jalr	-962(ra) # 80002084 <sleep>
    8000444e:	bfe9                	j	80004428 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004450:	0001f517          	auipc	a0,0x1f
    80004454:	12050513          	add	a0,a0,288 # 80023570 <log>
    80004458:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	82c080e7          	jalr	-2004(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6902                	ld	s2,0(sp)
    8000446a:	6105                	add	sp,sp,32
    8000446c:	8082                	ret

000000008000446e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000446e:	7139                	add	sp,sp,-64
    80004470:	fc06                	sd	ra,56(sp)
    80004472:	f822                	sd	s0,48(sp)
    80004474:	f426                	sd	s1,40(sp)
    80004476:	f04a                	sd	s2,32(sp)
    80004478:	ec4e                	sd	s3,24(sp)
    8000447a:	e852                	sd	s4,16(sp)
    8000447c:	e456                	sd	s5,8(sp)
    8000447e:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004480:	0001f497          	auipc	s1,0x1f
    80004484:	0f048493          	add	s1,s1,240 # 80023570 <log>
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	748080e7          	jalr	1864(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004492:	509c                	lw	a5,32(s1)
    80004494:	37fd                	addw	a5,a5,-1
    80004496:	0007891b          	sext.w	s2,a5
    8000449a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000449c:	50dc                	lw	a5,36(s1)
    8000449e:	e7b9                	bnez	a5,800044ec <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044a0:	04091e63          	bnez	s2,800044fc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044a4:	0001f497          	auipc	s1,0x1f
    800044a8:	0cc48493          	add	s1,s1,204 # 80023570 <log>
    800044ac:	4785                	li	a5,1
    800044ae:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	7d4080e7          	jalr	2004(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044ba:	54dc                	lw	a5,44(s1)
    800044bc:	06f04763          	bgtz	a5,8000452a <end_op+0xbc>
    acquire(&log.lock);
    800044c0:	0001f497          	auipc	s1,0x1f
    800044c4:	0b048493          	add	s1,s1,176 # 80023570 <log>
    800044c8:	8526                	mv	a0,s1
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	708080e7          	jalr	1800(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800044d2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044d6:	8526                	mv	a0,s1
    800044d8:	ffffe097          	auipc	ra,0xffffe
    800044dc:	c10080e7          	jalr	-1008(ra) # 800020e8 <wakeup>
    release(&log.lock);
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7a4080e7          	jalr	1956(ra) # 80000c86 <release>
}
    800044ea:	a03d                	j	80004518 <end_op+0xaa>
    panic("log.committing");
    800044ec:	00004517          	auipc	a0,0x4
    800044f0:	18c50513          	add	a0,a0,396 # 80008678 <syscalls+0x200>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	048080e7          	jalr	72(ra) # 8000053c <panic>
    wakeup(&log);
    800044fc:	0001f497          	auipc	s1,0x1f
    80004500:	07448493          	add	s1,s1,116 # 80023570 <log>
    80004504:	8526                	mv	a0,s1
    80004506:	ffffe097          	auipc	ra,0xffffe
    8000450a:	be2080e7          	jalr	-1054(ra) # 800020e8 <wakeup>
  release(&log.lock);
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	776080e7          	jalr	1910(ra) # 80000c86 <release>
}
    80004518:	70e2                	ld	ra,56(sp)
    8000451a:	7442                	ld	s0,48(sp)
    8000451c:	74a2                	ld	s1,40(sp)
    8000451e:	7902                	ld	s2,32(sp)
    80004520:	69e2                	ld	s3,24(sp)
    80004522:	6a42                	ld	s4,16(sp)
    80004524:	6aa2                	ld	s5,8(sp)
    80004526:	6121                	add	sp,sp,64
    80004528:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000452a:	0001fa97          	auipc	s5,0x1f
    8000452e:	076a8a93          	add	s5,s5,118 # 800235a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004532:	0001fa17          	auipc	s4,0x1f
    80004536:	03ea0a13          	add	s4,s4,62 # 80023570 <log>
    8000453a:	018a2583          	lw	a1,24(s4)
    8000453e:	012585bb          	addw	a1,a1,s2
    80004542:	2585                	addw	a1,a1,1
    80004544:	028a2503          	lw	a0,40(s4)
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	cf6080e7          	jalr	-778(ra) # 8000323e <bread>
    80004550:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004552:	000aa583          	lw	a1,0(s5)
    80004556:	028a2503          	lw	a0,40(s4)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	ce4080e7          	jalr	-796(ra) # 8000323e <bread>
    80004562:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004564:	40000613          	li	a2,1024
    80004568:	05850593          	add	a1,a0,88
    8000456c:	05848513          	add	a0,s1,88
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	7ba080e7          	jalr	1978(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	db6080e7          	jalr	-586(ra) # 80003330 <bwrite>
    brelse(from);
    80004582:	854e                	mv	a0,s3
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	dea080e7          	jalr	-534(ra) # 8000336e <brelse>
    brelse(to);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	de0080e7          	jalr	-544(ra) # 8000336e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004596:	2905                	addw	s2,s2,1
    80004598:	0a91                	add	s5,s5,4
    8000459a:	02ca2783          	lw	a5,44(s4)
    8000459e:	f8f94ee3          	blt	s2,a5,8000453a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	c8c080e7          	jalr	-884(ra) # 8000422e <write_head>
    install_trans(0); // Now install writes to home locations
    800045aa:	4501                	li	a0,0
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	cec080e7          	jalr	-788(ra) # 80004298 <install_trans>
    log.lh.n = 0;
    800045b4:	0001f797          	auipc	a5,0x1f
    800045b8:	fe07a423          	sw	zero,-24(a5) # 8002359c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	c72080e7          	jalr	-910(ra) # 8000422e <write_head>
    800045c4:	bdf5                	j	800044c0 <end_op+0x52>

00000000800045c6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045c6:	1101                	add	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	e04a                	sd	s2,0(sp)
    800045d0:	1000                	add	s0,sp,32
    800045d2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045d4:	0001f917          	auipc	s2,0x1f
    800045d8:	f9c90913          	add	s2,s2,-100 # 80023570 <log>
    800045dc:	854a                	mv	a0,s2
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	5f4080e7          	jalr	1524(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045e6:	02c92603          	lw	a2,44(s2)
    800045ea:	47f5                	li	a5,29
    800045ec:	06c7c563          	blt	a5,a2,80004656 <log_write+0x90>
    800045f0:	0001f797          	auipc	a5,0x1f
    800045f4:	f9c7a783          	lw	a5,-100(a5) # 8002358c <log+0x1c>
    800045f8:	37fd                	addw	a5,a5,-1
    800045fa:	04f65e63          	bge	a2,a5,80004656 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045fe:	0001f797          	auipc	a5,0x1f
    80004602:	f927a783          	lw	a5,-110(a5) # 80023590 <log+0x20>
    80004606:	06f05063          	blez	a5,80004666 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000460a:	4781                	li	a5,0
    8000460c:	06c05563          	blez	a2,80004676 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004610:	44cc                	lw	a1,12(s1)
    80004612:	0001f717          	auipc	a4,0x1f
    80004616:	f8e70713          	add	a4,a4,-114 # 800235a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000461a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000461c:	4314                	lw	a3,0(a4)
    8000461e:	04b68c63          	beq	a3,a1,80004676 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004622:	2785                	addw	a5,a5,1
    80004624:	0711                	add	a4,a4,4
    80004626:	fef61be3          	bne	a2,a5,8000461c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000462a:	0621                	add	a2,a2,8
    8000462c:	060a                	sll	a2,a2,0x2
    8000462e:	0001f797          	auipc	a5,0x1f
    80004632:	f4278793          	add	a5,a5,-190 # 80023570 <log>
    80004636:	97b2                	add	a5,a5,a2
    80004638:	44d8                	lw	a4,12(s1)
    8000463a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	dcc080e7          	jalr	-564(ra) # 8000340a <bpin>
    log.lh.n++;
    80004646:	0001f717          	auipc	a4,0x1f
    8000464a:	f2a70713          	add	a4,a4,-214 # 80023570 <log>
    8000464e:	575c                	lw	a5,44(a4)
    80004650:	2785                	addw	a5,a5,1
    80004652:	d75c                	sw	a5,44(a4)
    80004654:	a82d                	j	8000468e <log_write+0xc8>
    panic("too big a transaction");
    80004656:	00004517          	auipc	a0,0x4
    8000465a:	03250513          	add	a0,a0,50 # 80008688 <syscalls+0x210>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004666:	00004517          	auipc	a0,0x4
    8000466a:	03a50513          	add	a0,a0,58 # 800086a0 <syscalls+0x228>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	ece080e7          	jalr	-306(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004676:	00878693          	add	a3,a5,8
    8000467a:	068a                	sll	a3,a3,0x2
    8000467c:	0001f717          	auipc	a4,0x1f
    80004680:	ef470713          	add	a4,a4,-268 # 80023570 <log>
    80004684:	9736                	add	a4,a4,a3
    80004686:	44d4                	lw	a3,12(s1)
    80004688:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000468a:	faf609e3          	beq	a2,a5,8000463c <log_write+0x76>
  }
  release(&log.lock);
    8000468e:	0001f517          	auipc	a0,0x1f
    80004692:	ee250513          	add	a0,a0,-286 # 80023570 <log>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	5f0080e7          	jalr	1520(ra) # 80000c86 <release>
}
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6902                	ld	s2,0(sp)
    800046a6:	6105                	add	sp,sp,32
    800046a8:	8082                	ret

00000000800046aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046aa:	1101                	add	sp,sp,-32
    800046ac:	ec06                	sd	ra,24(sp)
    800046ae:	e822                	sd	s0,16(sp)
    800046b0:	e426                	sd	s1,8(sp)
    800046b2:	e04a                	sd	s2,0(sp)
    800046b4:	1000                	add	s0,sp,32
    800046b6:	84aa                	mv	s1,a0
    800046b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046ba:	00004597          	auipc	a1,0x4
    800046be:	00658593          	add	a1,a1,6 # 800086c0 <syscalls+0x248>
    800046c2:	0521                	add	a0,a0,8
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	47e080e7          	jalr	1150(ra) # 80000b42 <initlock>
  lk->name = name;
    800046cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046d4:	0204a423          	sw	zero,40(s1)
}
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6902                	ld	s2,0(sp)
    800046e0:	6105                	add	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046e4:	1101                	add	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	e04a                	sd	s2,0(sp)
    800046ee:	1000                	add	s0,sp,32
    800046f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f2:	00850913          	add	s2,a0,8
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4da080e7          	jalr	1242(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004700:	409c                	lw	a5,0(s1)
    80004702:	cb89                	beqz	a5,80004714 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004704:	85ca                	mv	a1,s2
    80004706:	8526                	mv	a0,s1
    80004708:	ffffe097          	auipc	ra,0xffffe
    8000470c:	97c080e7          	jalr	-1668(ra) # 80002084 <sleep>
  while (lk->locked) {
    80004710:	409c                	lw	a5,0(s1)
    80004712:	fbed                	bnez	a5,80004704 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004714:	4785                	li	a5,1
    80004716:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004718:	ffffd097          	auipc	ra,0xffffd
    8000471c:	28e080e7          	jalr	654(ra) # 800019a6 <myproc>
    80004720:	591c                	lw	a5,48(a0)
    80004722:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004724:	854a                	mv	a0,s2
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	560080e7          	jalr	1376(ra) # 80000c86 <release>
}
    8000472e:	60e2                	ld	ra,24(sp)
    80004730:	6442                	ld	s0,16(sp)
    80004732:	64a2                	ld	s1,8(sp)
    80004734:	6902                	ld	s2,0(sp)
    80004736:	6105                	add	sp,sp,32
    80004738:	8082                	ret

000000008000473a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000473a:	1101                	add	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	e04a                	sd	s2,0(sp)
    80004744:	1000                	add	s0,sp,32
    80004746:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004748:	00850913          	add	s2,a0,8
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	484080e7          	jalr	1156(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004756:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000475a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000475e:	8526                	mv	a0,s1
    80004760:	ffffe097          	auipc	ra,0xffffe
    80004764:	988080e7          	jalr	-1656(ra) # 800020e8 <wakeup>
  release(&lk->lk);
    80004768:	854a                	mv	a0,s2
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	51c080e7          	jalr	1308(ra) # 80000c86 <release>
}
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6902                	ld	s2,0(sp)
    8000477a:	6105                	add	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000477e:	7179                	add	sp,sp,-48
    80004780:	f406                	sd	ra,40(sp)
    80004782:	f022                	sd	s0,32(sp)
    80004784:	ec26                	sd	s1,24(sp)
    80004786:	e84a                	sd	s2,16(sp)
    80004788:	e44e                	sd	s3,8(sp)
    8000478a:	1800                	add	s0,sp,48
    8000478c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000478e:	00850913          	add	s2,a0,8
    80004792:	854a                	mv	a0,s2
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	43e080e7          	jalr	1086(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000479c:	409c                	lw	a5,0(s1)
    8000479e:	ef99                	bnez	a5,800047bc <holdingsleep+0x3e>
    800047a0:	4481                	li	s1,0
  release(&lk->lk);
    800047a2:	854a                	mv	a0,s2
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	4e2080e7          	jalr	1250(ra) # 80000c86 <release>
  return r;
}
    800047ac:	8526                	mv	a0,s1
    800047ae:	70a2                	ld	ra,40(sp)
    800047b0:	7402                	ld	s0,32(sp)
    800047b2:	64e2                	ld	s1,24(sp)
    800047b4:	6942                	ld	s2,16(sp)
    800047b6:	69a2                	ld	s3,8(sp)
    800047b8:	6145                	add	sp,sp,48
    800047ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047bc:	0284a983          	lw	s3,40(s1)
    800047c0:	ffffd097          	auipc	ra,0xffffd
    800047c4:	1e6080e7          	jalr	486(ra) # 800019a6 <myproc>
    800047c8:	5904                	lw	s1,48(a0)
    800047ca:	413484b3          	sub	s1,s1,s3
    800047ce:	0014b493          	seqz	s1,s1
    800047d2:	bfc1                	j	800047a2 <holdingsleep+0x24>

00000000800047d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047d4:	1141                	add	sp,sp,-16
    800047d6:	e406                	sd	ra,8(sp)
    800047d8:	e022                	sd	s0,0(sp)
    800047da:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047dc:	00004597          	auipc	a1,0x4
    800047e0:	ef458593          	add	a1,a1,-268 # 800086d0 <syscalls+0x258>
    800047e4:	0001f517          	auipc	a0,0x1f
    800047e8:	ed450513          	add	a0,a0,-300 # 800236b8 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	356080e7          	jalr	854(ra) # 80000b42 <initlock>
}
    800047f4:	60a2                	ld	ra,8(sp)
    800047f6:	6402                	ld	s0,0(sp)
    800047f8:	0141                	add	sp,sp,16
    800047fa:	8082                	ret

00000000800047fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047fc:	1101                	add	sp,sp,-32
    800047fe:	ec06                	sd	ra,24(sp)
    80004800:	e822                	sd	s0,16(sp)
    80004802:	e426                	sd	s1,8(sp)
    80004804:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004806:	0001f517          	auipc	a0,0x1f
    8000480a:	eb250513          	add	a0,a0,-334 # 800236b8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	3c4080e7          	jalr	964(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004816:	0001f497          	auipc	s1,0x1f
    8000481a:	eba48493          	add	s1,s1,-326 # 800236d0 <ftable+0x18>
    8000481e:	00020717          	auipc	a4,0x20
    80004822:	e5270713          	add	a4,a4,-430 # 80024670 <disk>
    if(f->ref == 0){
    80004826:	40dc                	lw	a5,4(s1)
    80004828:	cf99                	beqz	a5,80004846 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000482a:	02848493          	add	s1,s1,40
    8000482e:	fee49ce3          	bne	s1,a4,80004826 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004832:	0001f517          	auipc	a0,0x1f
    80004836:	e8650513          	add	a0,a0,-378 # 800236b8 <ftable>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	44c080e7          	jalr	1100(ra) # 80000c86 <release>
  return 0;
    80004842:	4481                	li	s1,0
    80004844:	a819                	j	8000485a <filealloc+0x5e>
      f->ref = 1;
    80004846:	4785                	li	a5,1
    80004848:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000484a:	0001f517          	auipc	a0,0x1f
    8000484e:	e6e50513          	add	a0,a0,-402 # 800236b8 <ftable>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	434080e7          	jalr	1076(ra) # 80000c86 <release>
}
    8000485a:	8526                	mv	a0,s1
    8000485c:	60e2                	ld	ra,24(sp)
    8000485e:	6442                	ld	s0,16(sp)
    80004860:	64a2                	ld	s1,8(sp)
    80004862:	6105                	add	sp,sp,32
    80004864:	8082                	ret

0000000080004866 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004866:	1101                	add	sp,sp,-32
    80004868:	ec06                	sd	ra,24(sp)
    8000486a:	e822                	sd	s0,16(sp)
    8000486c:	e426                	sd	s1,8(sp)
    8000486e:	1000                	add	s0,sp,32
    80004870:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004872:	0001f517          	auipc	a0,0x1f
    80004876:	e4650513          	add	a0,a0,-442 # 800236b8 <ftable>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	358080e7          	jalr	856(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004882:	40dc                	lw	a5,4(s1)
    80004884:	02f05263          	blez	a5,800048a8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004888:	2785                	addw	a5,a5,1
    8000488a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000488c:	0001f517          	auipc	a0,0x1f
    80004890:	e2c50513          	add	a0,a0,-468 # 800236b8 <ftable>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	3f2080e7          	jalr	1010(ra) # 80000c86 <release>
  return f;
}
    8000489c:	8526                	mv	a0,s1
    8000489e:	60e2                	ld	ra,24(sp)
    800048a0:	6442                	ld	s0,16(sp)
    800048a2:	64a2                	ld	s1,8(sp)
    800048a4:	6105                	add	sp,sp,32
    800048a6:	8082                	ret
    panic("filedup");
    800048a8:	00004517          	auipc	a0,0x4
    800048ac:	e3050513          	add	a0,a0,-464 # 800086d8 <syscalls+0x260>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	c8c080e7          	jalr	-884(ra) # 8000053c <panic>

00000000800048b8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048b8:	7139                	add	sp,sp,-64
    800048ba:	fc06                	sd	ra,56(sp)
    800048bc:	f822                	sd	s0,48(sp)
    800048be:	f426                	sd	s1,40(sp)
    800048c0:	f04a                	sd	s2,32(sp)
    800048c2:	ec4e                	sd	s3,24(sp)
    800048c4:	e852                	sd	s4,16(sp)
    800048c6:	e456                	sd	s5,8(sp)
    800048c8:	0080                	add	s0,sp,64
    800048ca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048cc:	0001f517          	auipc	a0,0x1f
    800048d0:	dec50513          	add	a0,a0,-532 # 800236b8 <ftable>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800048dc:	40dc                	lw	a5,4(s1)
    800048de:	06f05163          	blez	a5,80004940 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048e2:	37fd                	addw	a5,a5,-1
    800048e4:	0007871b          	sext.w	a4,a5
    800048e8:	c0dc                	sw	a5,4(s1)
    800048ea:	06e04363          	bgtz	a4,80004950 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048ee:	0004a903          	lw	s2,0(s1)
    800048f2:	0094ca83          	lbu	s5,9(s1)
    800048f6:	0104ba03          	ld	s4,16(s1)
    800048fa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048fe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004902:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004906:	0001f517          	auipc	a0,0x1f
    8000490a:	db250513          	add	a0,a0,-590 # 800236b8 <ftable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	378080e7          	jalr	888(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004916:	4785                	li	a5,1
    80004918:	04f90d63          	beq	s2,a5,80004972 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000491c:	3979                	addw	s2,s2,-2
    8000491e:	4785                	li	a5,1
    80004920:	0527e063          	bltu	a5,s2,80004960 <fileclose+0xa8>
    begin_op();
    80004924:	00000097          	auipc	ra,0x0
    80004928:	ad0080e7          	jalr	-1328(ra) # 800043f4 <begin_op>
    iput(ff.ip);
    8000492c:	854e                	mv	a0,s3
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	2da080e7          	jalr	730(ra) # 80003c08 <iput>
    end_op();
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	b38080e7          	jalr	-1224(ra) # 8000446e <end_op>
    8000493e:	a00d                	j	80004960 <fileclose+0xa8>
    panic("fileclose");
    80004940:	00004517          	auipc	a0,0x4
    80004944:	da050513          	add	a0,a0,-608 # 800086e0 <syscalls+0x268>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	bf4080e7          	jalr	-1036(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004950:	0001f517          	auipc	a0,0x1f
    80004954:	d6850513          	add	a0,a0,-664 # 800236b8 <ftable>
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	32e080e7          	jalr	814(ra) # 80000c86 <release>
  }
}
    80004960:	70e2                	ld	ra,56(sp)
    80004962:	7442                	ld	s0,48(sp)
    80004964:	74a2                	ld	s1,40(sp)
    80004966:	7902                	ld	s2,32(sp)
    80004968:	69e2                	ld	s3,24(sp)
    8000496a:	6a42                	ld	s4,16(sp)
    8000496c:	6aa2                	ld	s5,8(sp)
    8000496e:	6121                	add	sp,sp,64
    80004970:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004972:	85d6                	mv	a1,s5
    80004974:	8552                	mv	a0,s4
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	348080e7          	jalr	840(ra) # 80004cbe <pipeclose>
    8000497e:	b7cd                	j	80004960 <fileclose+0xa8>

0000000080004980 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004980:	715d                	add	sp,sp,-80
    80004982:	e486                	sd	ra,72(sp)
    80004984:	e0a2                	sd	s0,64(sp)
    80004986:	fc26                	sd	s1,56(sp)
    80004988:	f84a                	sd	s2,48(sp)
    8000498a:	f44e                	sd	s3,40(sp)
    8000498c:	0880                	add	s0,sp,80
    8000498e:	84aa                	mv	s1,a0
    80004990:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004992:	ffffd097          	auipc	ra,0xffffd
    80004996:	014080e7          	jalr	20(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000499a:	409c                	lw	a5,0(s1)
    8000499c:	37f9                	addw	a5,a5,-2
    8000499e:	4705                	li	a4,1
    800049a0:	04f76763          	bltu	a4,a5,800049ee <filestat+0x6e>
    800049a4:	892a                	mv	s2,a0
    ilock(f->ip);
    800049a6:	6c88                	ld	a0,24(s1)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	0a6080e7          	jalr	166(ra) # 80003a4e <ilock>
    stati(f->ip, &st);
    800049b0:	fb840593          	add	a1,s0,-72
    800049b4:	6c88                	ld	a0,24(s1)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	322080e7          	jalr	802(ra) # 80003cd8 <stati>
    iunlock(f->ip);
    800049be:	6c88                	ld	a0,24(s1)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	150080e7          	jalr	336(ra) # 80003b10 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049c8:	46e1                	li	a3,24
    800049ca:	fb840613          	add	a2,s0,-72
    800049ce:	85ce                	mv	a1,s3
    800049d0:	05093503          	ld	a0,80(s2)
    800049d4:	ffffd097          	auipc	ra,0xffffd
    800049d8:	c92080e7          	jalr	-878(ra) # 80001666 <copyout>
    800049dc:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049e0:	60a6                	ld	ra,72(sp)
    800049e2:	6406                	ld	s0,64(sp)
    800049e4:	74e2                	ld	s1,56(sp)
    800049e6:	7942                	ld	s2,48(sp)
    800049e8:	79a2                	ld	s3,40(sp)
    800049ea:	6161                	add	sp,sp,80
    800049ec:	8082                	ret
  return -1;
    800049ee:	557d                	li	a0,-1
    800049f0:	bfc5                	j	800049e0 <filestat+0x60>

00000000800049f2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049f2:	7179                	add	sp,sp,-48
    800049f4:	f406                	sd	ra,40(sp)
    800049f6:	f022                	sd	s0,32(sp)
    800049f8:	ec26                	sd	s1,24(sp)
    800049fa:	e84a                	sd	s2,16(sp)
    800049fc:	e44e                	sd	s3,8(sp)
    800049fe:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a00:	00854783          	lbu	a5,8(a0)
    80004a04:	c3d5                	beqz	a5,80004aa8 <fileread+0xb6>
    80004a06:	84aa                	mv	s1,a0
    80004a08:	89ae                	mv	s3,a1
    80004a0a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a0c:	411c                	lw	a5,0(a0)
    80004a0e:	4705                	li	a4,1
    80004a10:	04e78963          	beq	a5,a4,80004a62 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a14:	470d                	li	a4,3
    80004a16:	04e78d63          	beq	a5,a4,80004a70 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a1a:	4709                	li	a4,2
    80004a1c:	06e79e63          	bne	a5,a4,80004a98 <fileread+0xa6>
    ilock(f->ip);
    80004a20:	6d08                	ld	a0,24(a0)
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	02c080e7          	jalr	44(ra) # 80003a4e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a2a:	874a                	mv	a4,s2
    80004a2c:	5094                	lw	a3,32(s1)
    80004a2e:	864e                	mv	a2,s3
    80004a30:	4585                	li	a1,1
    80004a32:	6c88                	ld	a0,24(s1)
    80004a34:	fffff097          	auipc	ra,0xfffff
    80004a38:	2ce080e7          	jalr	718(ra) # 80003d02 <readi>
    80004a3c:	892a                	mv	s2,a0
    80004a3e:	00a05563          	blez	a0,80004a48 <fileread+0x56>
      f->off += r;
    80004a42:	509c                	lw	a5,32(s1)
    80004a44:	9fa9                	addw	a5,a5,a0
    80004a46:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a48:	6c88                	ld	a0,24(s1)
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	0c6080e7          	jalr	198(ra) # 80003b10 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a52:	854a                	mv	a0,s2
    80004a54:	70a2                	ld	ra,40(sp)
    80004a56:	7402                	ld	s0,32(sp)
    80004a58:	64e2                	ld	s1,24(sp)
    80004a5a:	6942                	ld	s2,16(sp)
    80004a5c:	69a2                	ld	s3,8(sp)
    80004a5e:	6145                	add	sp,sp,48
    80004a60:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a62:	6908                	ld	a0,16(a0)
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	3c2080e7          	jalr	962(ra) # 80004e26 <piperead>
    80004a6c:	892a                	mv	s2,a0
    80004a6e:	b7d5                	j	80004a52 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a70:	02451783          	lh	a5,36(a0)
    80004a74:	03079693          	sll	a3,a5,0x30
    80004a78:	92c1                	srl	a3,a3,0x30
    80004a7a:	4725                	li	a4,9
    80004a7c:	02d76863          	bltu	a4,a3,80004aac <fileread+0xba>
    80004a80:	0792                	sll	a5,a5,0x4
    80004a82:	0001f717          	auipc	a4,0x1f
    80004a86:	b9670713          	add	a4,a4,-1130 # 80023618 <devsw>
    80004a8a:	97ba                	add	a5,a5,a4
    80004a8c:	639c                	ld	a5,0(a5)
    80004a8e:	c38d                	beqz	a5,80004ab0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a90:	4505                	li	a0,1
    80004a92:	9782                	jalr	a5
    80004a94:	892a                	mv	s2,a0
    80004a96:	bf75                	j	80004a52 <fileread+0x60>
    panic("fileread");
    80004a98:	00004517          	auipc	a0,0x4
    80004a9c:	c5850513          	add	a0,a0,-936 # 800086f0 <syscalls+0x278>
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	a9c080e7          	jalr	-1380(ra) # 8000053c <panic>
    return -1;
    80004aa8:	597d                	li	s2,-1
    80004aaa:	b765                	j	80004a52 <fileread+0x60>
      return -1;
    80004aac:	597d                	li	s2,-1
    80004aae:	b755                	j	80004a52 <fileread+0x60>
    80004ab0:	597d                	li	s2,-1
    80004ab2:	b745                	j	80004a52 <fileread+0x60>

0000000080004ab4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ab4:	00954783          	lbu	a5,9(a0)
    80004ab8:	10078e63          	beqz	a5,80004bd4 <filewrite+0x120>
{
    80004abc:	715d                	add	sp,sp,-80
    80004abe:	e486                	sd	ra,72(sp)
    80004ac0:	e0a2                	sd	s0,64(sp)
    80004ac2:	fc26                	sd	s1,56(sp)
    80004ac4:	f84a                	sd	s2,48(sp)
    80004ac6:	f44e                	sd	s3,40(sp)
    80004ac8:	f052                	sd	s4,32(sp)
    80004aca:	ec56                	sd	s5,24(sp)
    80004acc:	e85a                	sd	s6,16(sp)
    80004ace:	e45e                	sd	s7,8(sp)
    80004ad0:	e062                	sd	s8,0(sp)
    80004ad2:	0880                	add	s0,sp,80
    80004ad4:	892a                	mv	s2,a0
    80004ad6:	8b2e                	mv	s6,a1
    80004ad8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ada:	411c                	lw	a5,0(a0)
    80004adc:	4705                	li	a4,1
    80004ade:	02e78263          	beq	a5,a4,80004b02 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ae2:	470d                	li	a4,3
    80004ae4:	02e78563          	beq	a5,a4,80004b0e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ae8:	4709                	li	a4,2
    80004aea:	0ce79d63          	bne	a5,a4,80004bc4 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aee:	0ac05b63          	blez	a2,80004ba4 <filewrite+0xf0>
    int i = 0;
    80004af2:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004af4:	6b85                	lui	s7,0x1
    80004af6:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004afa:	6c05                	lui	s8,0x1
    80004afc:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b00:	a851                	j	80004b94 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b02:	6908                	ld	a0,16(a0)
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	22a080e7          	jalr	554(ra) # 80004d2e <pipewrite>
    80004b0c:	a045                	j	80004bac <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b0e:	02451783          	lh	a5,36(a0)
    80004b12:	03079693          	sll	a3,a5,0x30
    80004b16:	92c1                	srl	a3,a3,0x30
    80004b18:	4725                	li	a4,9
    80004b1a:	0ad76f63          	bltu	a4,a3,80004bd8 <filewrite+0x124>
    80004b1e:	0792                	sll	a5,a5,0x4
    80004b20:	0001f717          	auipc	a4,0x1f
    80004b24:	af870713          	add	a4,a4,-1288 # 80023618 <devsw>
    80004b28:	97ba                	add	a5,a5,a4
    80004b2a:	679c                	ld	a5,8(a5)
    80004b2c:	cbc5                	beqz	a5,80004bdc <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004b2e:	4505                	li	a0,1
    80004b30:	9782                	jalr	a5
    80004b32:	a8ad                	j	80004bac <filewrite+0xf8>
      if(n1 > max)
    80004b34:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	8bc080e7          	jalr	-1860(ra) # 800043f4 <begin_op>
      ilock(f->ip);
    80004b40:	01893503          	ld	a0,24(s2)
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	f0a080e7          	jalr	-246(ra) # 80003a4e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b4c:	8756                	mv	a4,s5
    80004b4e:	02092683          	lw	a3,32(s2)
    80004b52:	01698633          	add	a2,s3,s6
    80004b56:	4585                	li	a1,1
    80004b58:	01893503          	ld	a0,24(s2)
    80004b5c:	fffff097          	auipc	ra,0xfffff
    80004b60:	29e080e7          	jalr	670(ra) # 80003dfa <writei>
    80004b64:	84aa                	mv	s1,a0
    80004b66:	00a05763          	blez	a0,80004b74 <filewrite+0xc0>
        f->off += r;
    80004b6a:	02092783          	lw	a5,32(s2)
    80004b6e:	9fa9                	addw	a5,a5,a0
    80004b70:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b74:	01893503          	ld	a0,24(s2)
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	f98080e7          	jalr	-104(ra) # 80003b10 <iunlock>
      end_op();
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	8ee080e7          	jalr	-1810(ra) # 8000446e <end_op>

      if(r != n1){
    80004b88:	009a9f63          	bne	s5,s1,80004ba6 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004b8c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b90:	0149db63          	bge	s3,s4,80004ba6 <filewrite+0xf2>
      int n1 = n - i;
    80004b94:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004b98:	0004879b          	sext.w	a5,s1
    80004b9c:	f8fbdce3          	bge	s7,a5,80004b34 <filewrite+0x80>
    80004ba0:	84e2                	mv	s1,s8
    80004ba2:	bf49                	j	80004b34 <filewrite+0x80>
    int i = 0;
    80004ba4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ba6:	033a1d63          	bne	s4,s3,80004be0 <filewrite+0x12c>
    80004baa:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bac:	60a6                	ld	ra,72(sp)
    80004bae:	6406                	ld	s0,64(sp)
    80004bb0:	74e2                	ld	s1,56(sp)
    80004bb2:	7942                	ld	s2,48(sp)
    80004bb4:	79a2                	ld	s3,40(sp)
    80004bb6:	7a02                	ld	s4,32(sp)
    80004bb8:	6ae2                	ld	s5,24(sp)
    80004bba:	6b42                	ld	s6,16(sp)
    80004bbc:	6ba2                	ld	s7,8(sp)
    80004bbe:	6c02                	ld	s8,0(sp)
    80004bc0:	6161                	add	sp,sp,80
    80004bc2:	8082                	ret
    panic("filewrite");
    80004bc4:	00004517          	auipc	a0,0x4
    80004bc8:	b3c50513          	add	a0,a0,-1220 # 80008700 <syscalls+0x288>
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	970080e7          	jalr	-1680(ra) # 8000053c <panic>
    return -1;
    80004bd4:	557d                	li	a0,-1
}
    80004bd6:	8082                	ret
      return -1;
    80004bd8:	557d                	li	a0,-1
    80004bda:	bfc9                	j	80004bac <filewrite+0xf8>
    80004bdc:	557d                	li	a0,-1
    80004bde:	b7f9                	j	80004bac <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004be0:	557d                	li	a0,-1
    80004be2:	b7e9                	j	80004bac <filewrite+0xf8>

0000000080004be4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004be4:	7179                	add	sp,sp,-48
    80004be6:	f406                	sd	ra,40(sp)
    80004be8:	f022                	sd	s0,32(sp)
    80004bea:	ec26                	sd	s1,24(sp)
    80004bec:	e84a                	sd	s2,16(sp)
    80004bee:	e44e                	sd	s3,8(sp)
    80004bf0:	e052                	sd	s4,0(sp)
    80004bf2:	1800                	add	s0,sp,48
    80004bf4:	84aa                	mv	s1,a0
    80004bf6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bf8:	0005b023          	sd	zero,0(a1)
    80004bfc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c00:	00000097          	auipc	ra,0x0
    80004c04:	bfc080e7          	jalr	-1028(ra) # 800047fc <filealloc>
    80004c08:	e088                	sd	a0,0(s1)
    80004c0a:	c551                	beqz	a0,80004c96 <pipealloc+0xb2>
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	bf0080e7          	jalr	-1040(ra) # 800047fc <filealloc>
    80004c14:	00aa3023          	sd	a0,0(s4)
    80004c18:	c92d                	beqz	a0,80004c8a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	ec8080e7          	jalr	-312(ra) # 80000ae2 <kalloc>
    80004c22:	892a                	mv	s2,a0
    80004c24:	c125                	beqz	a0,80004c84 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c26:	4985                	li	s3,1
    80004c28:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c2c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c30:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c34:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c38:	00004597          	auipc	a1,0x4
    80004c3c:	ad858593          	add	a1,a1,-1320 # 80008710 <syscalls+0x298>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	f02080e7          	jalr	-254(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004c48:	609c                	ld	a5,0(s1)
    80004c4a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c4e:	609c                	ld	a5,0(s1)
    80004c50:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c54:	609c                	ld	a5,0(s1)
    80004c56:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c5a:	609c                	ld	a5,0(s1)
    80004c5c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c60:	000a3783          	ld	a5,0(s4)
    80004c64:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c68:	000a3783          	ld	a5,0(s4)
    80004c6c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c70:	000a3783          	ld	a5,0(s4)
    80004c74:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c78:	000a3783          	ld	a5,0(s4)
    80004c7c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c80:	4501                	li	a0,0
    80004c82:	a025                	j	80004caa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c84:	6088                	ld	a0,0(s1)
    80004c86:	e501                	bnez	a0,80004c8e <pipealloc+0xaa>
    80004c88:	a039                	j	80004c96 <pipealloc+0xb2>
    80004c8a:	6088                	ld	a0,0(s1)
    80004c8c:	c51d                	beqz	a0,80004cba <pipealloc+0xd6>
    fileclose(*f0);
    80004c8e:	00000097          	auipc	ra,0x0
    80004c92:	c2a080e7          	jalr	-982(ra) # 800048b8 <fileclose>
  if(*f1)
    80004c96:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c9a:	557d                	li	a0,-1
  if(*f1)
    80004c9c:	c799                	beqz	a5,80004caa <pipealloc+0xc6>
    fileclose(*f1);
    80004c9e:	853e                	mv	a0,a5
    80004ca0:	00000097          	auipc	ra,0x0
    80004ca4:	c18080e7          	jalr	-1000(ra) # 800048b8 <fileclose>
  return -1;
    80004ca8:	557d                	li	a0,-1
}
    80004caa:	70a2                	ld	ra,40(sp)
    80004cac:	7402                	ld	s0,32(sp)
    80004cae:	64e2                	ld	s1,24(sp)
    80004cb0:	6942                	ld	s2,16(sp)
    80004cb2:	69a2                	ld	s3,8(sp)
    80004cb4:	6a02                	ld	s4,0(sp)
    80004cb6:	6145                	add	sp,sp,48
    80004cb8:	8082                	ret
  return -1;
    80004cba:	557d                	li	a0,-1
    80004cbc:	b7fd                	j	80004caa <pipealloc+0xc6>

0000000080004cbe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cbe:	1101                	add	sp,sp,-32
    80004cc0:	ec06                	sd	ra,24(sp)
    80004cc2:	e822                	sd	s0,16(sp)
    80004cc4:	e426                	sd	s1,8(sp)
    80004cc6:	e04a                	sd	s2,0(sp)
    80004cc8:	1000                	add	s0,sp,32
    80004cca:	84aa                	mv	s1,a0
    80004ccc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	f04080e7          	jalr	-252(ra) # 80000bd2 <acquire>
  if(writable){
    80004cd6:	02090d63          	beqz	s2,80004d10 <pipeclose+0x52>
    pi->writeopen = 0;
    80004cda:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cde:	21848513          	add	a0,s1,536
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	406080e7          	jalr	1030(ra) # 800020e8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cea:	2204b783          	ld	a5,544(s1)
    80004cee:	eb95                	bnez	a5,80004d22 <pipeclose+0x64>
    release(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f94080e7          	jalr	-108(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	ce8080e7          	jalr	-792(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004d04:	60e2                	ld	ra,24(sp)
    80004d06:	6442                	ld	s0,16(sp)
    80004d08:	64a2                	ld	s1,8(sp)
    80004d0a:	6902                	ld	s2,0(sp)
    80004d0c:	6105                	add	sp,sp,32
    80004d0e:	8082                	ret
    pi->readopen = 0;
    80004d10:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d14:	21c48513          	add	a0,s1,540
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	3d0080e7          	jalr	976(ra) # 800020e8 <wakeup>
    80004d20:	b7e9                	j	80004cea <pipeclose+0x2c>
    release(&pi->lock);
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f62080e7          	jalr	-158(ra) # 80000c86 <release>
}
    80004d2c:	bfe1                	j	80004d04 <pipeclose+0x46>

0000000080004d2e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d2e:	711d                	add	sp,sp,-96
    80004d30:	ec86                	sd	ra,88(sp)
    80004d32:	e8a2                	sd	s0,80(sp)
    80004d34:	e4a6                	sd	s1,72(sp)
    80004d36:	e0ca                	sd	s2,64(sp)
    80004d38:	fc4e                	sd	s3,56(sp)
    80004d3a:	f852                	sd	s4,48(sp)
    80004d3c:	f456                	sd	s5,40(sp)
    80004d3e:	f05a                	sd	s6,32(sp)
    80004d40:	ec5e                	sd	s7,24(sp)
    80004d42:	e862                	sd	s8,16(sp)
    80004d44:	1080                	add	s0,sp,96
    80004d46:	84aa                	mv	s1,a0
    80004d48:	8aae                	mv	s5,a1
    80004d4a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	c5a080e7          	jalr	-934(ra) # 800019a6 <myproc>
    80004d54:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	e7a080e7          	jalr	-390(ra) # 80000bd2 <acquire>
  while(i < n){
    80004d60:	0b405663          	blez	s4,80004e0c <pipewrite+0xde>
  int i = 0;
    80004d64:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d66:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d68:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d6c:	21c48b93          	add	s7,s1,540
    80004d70:	a089                	j	80004db2 <pipewrite+0x84>
      release(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f12080e7          	jalr	-238(ra) # 80000c86 <release>
      return -1;
    80004d7c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d7e:	854a                	mv	a0,s2
    80004d80:	60e6                	ld	ra,88(sp)
    80004d82:	6446                	ld	s0,80(sp)
    80004d84:	64a6                	ld	s1,72(sp)
    80004d86:	6906                	ld	s2,64(sp)
    80004d88:	79e2                	ld	s3,56(sp)
    80004d8a:	7a42                	ld	s4,48(sp)
    80004d8c:	7aa2                	ld	s5,40(sp)
    80004d8e:	7b02                	ld	s6,32(sp)
    80004d90:	6be2                	ld	s7,24(sp)
    80004d92:	6c42                	ld	s8,16(sp)
    80004d94:	6125                	add	sp,sp,96
    80004d96:	8082                	ret
      wakeup(&pi->nread);
    80004d98:	8562                	mv	a0,s8
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	34e080e7          	jalr	846(ra) # 800020e8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004da2:	85a6                	mv	a1,s1
    80004da4:	855e                	mv	a0,s7
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	2de080e7          	jalr	734(ra) # 80002084 <sleep>
  while(i < n){
    80004dae:	07495063          	bge	s2,s4,80004e0e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004db2:	2204a783          	lw	a5,544(s1)
    80004db6:	dfd5                	beqz	a5,80004d72 <pipewrite+0x44>
    80004db8:	854e                	mv	a0,s3
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	57e080e7          	jalr	1406(ra) # 80002338 <killed>
    80004dc2:	f945                	bnez	a0,80004d72 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dc4:	2184a783          	lw	a5,536(s1)
    80004dc8:	21c4a703          	lw	a4,540(s1)
    80004dcc:	2007879b          	addw	a5,a5,512
    80004dd0:	fcf704e3          	beq	a4,a5,80004d98 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dd4:	4685                	li	a3,1
    80004dd6:	01590633          	add	a2,s2,s5
    80004dda:	faf40593          	add	a1,s0,-81
    80004dde:	0509b503          	ld	a0,80(s3)
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	910080e7          	jalr	-1776(ra) # 800016f2 <copyin>
    80004dea:	03650263          	beq	a0,s6,80004e0e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dee:	21c4a783          	lw	a5,540(s1)
    80004df2:	0017871b          	addw	a4,a5,1
    80004df6:	20e4ae23          	sw	a4,540(s1)
    80004dfa:	1ff7f793          	and	a5,a5,511
    80004dfe:	97a6                	add	a5,a5,s1
    80004e00:	faf44703          	lbu	a4,-81(s0)
    80004e04:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e08:	2905                	addw	s2,s2,1
    80004e0a:	b755                	j	80004dae <pipewrite+0x80>
  int i = 0;
    80004e0c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e0e:	21848513          	add	a0,s1,536
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	2d6080e7          	jalr	726(ra) # 800020e8 <wakeup>
  release(&pi->lock);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	e6a080e7          	jalr	-406(ra) # 80000c86 <release>
  return i;
    80004e24:	bfa9                	j	80004d7e <pipewrite+0x50>

0000000080004e26 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e26:	715d                	add	sp,sp,-80
    80004e28:	e486                	sd	ra,72(sp)
    80004e2a:	e0a2                	sd	s0,64(sp)
    80004e2c:	fc26                	sd	s1,56(sp)
    80004e2e:	f84a                	sd	s2,48(sp)
    80004e30:	f44e                	sd	s3,40(sp)
    80004e32:	f052                	sd	s4,32(sp)
    80004e34:	ec56                	sd	s5,24(sp)
    80004e36:	e85a                	sd	s6,16(sp)
    80004e38:	0880                	add	s0,sp,80
    80004e3a:	84aa                	mv	s1,a0
    80004e3c:	892e                	mv	s2,a1
    80004e3e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	b66080e7          	jalr	-1178(ra) # 800019a6 <myproc>
    80004e48:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	d86080e7          	jalr	-634(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e54:	2184a703          	lw	a4,536(s1)
    80004e58:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e5c:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e60:	02f71763          	bne	a4,a5,80004e8e <piperead+0x68>
    80004e64:	2244a783          	lw	a5,548(s1)
    80004e68:	c39d                	beqz	a5,80004e8e <piperead+0x68>
    if(killed(pr)){
    80004e6a:	8552                	mv	a0,s4
    80004e6c:	ffffd097          	auipc	ra,0xffffd
    80004e70:	4cc080e7          	jalr	1228(ra) # 80002338 <killed>
    80004e74:	e949                	bnez	a0,80004f06 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e76:	85a6                	mv	a1,s1
    80004e78:	854e                	mv	a0,s3
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	20a080e7          	jalr	522(ra) # 80002084 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e82:	2184a703          	lw	a4,536(s1)
    80004e86:	21c4a783          	lw	a5,540(s1)
    80004e8a:	fcf70de3          	beq	a4,a5,80004e64 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e8e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e90:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e92:	05505463          	blez	s5,80004eda <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e96:	2184a783          	lw	a5,536(s1)
    80004e9a:	21c4a703          	lw	a4,540(s1)
    80004e9e:	02f70e63          	beq	a4,a5,80004eda <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ea2:	0017871b          	addw	a4,a5,1
    80004ea6:	20e4ac23          	sw	a4,536(s1)
    80004eaa:	1ff7f793          	and	a5,a5,511
    80004eae:	97a6                	add	a5,a5,s1
    80004eb0:	0187c783          	lbu	a5,24(a5)
    80004eb4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eb8:	4685                	li	a3,1
    80004eba:	fbf40613          	add	a2,s0,-65
    80004ebe:	85ca                	mv	a1,s2
    80004ec0:	050a3503          	ld	a0,80(s4)
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	7a2080e7          	jalr	1954(ra) # 80001666 <copyout>
    80004ecc:	01650763          	beq	a0,s6,80004eda <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ed0:	2985                	addw	s3,s3,1
    80004ed2:	0905                	add	s2,s2,1
    80004ed4:	fd3a91e3          	bne	s5,s3,80004e96 <piperead+0x70>
    80004ed8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eda:	21c48513          	add	a0,s1,540
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	20a080e7          	jalr	522(ra) # 800020e8 <wakeup>
  release(&pi->lock);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	d9e080e7          	jalr	-610(ra) # 80000c86 <release>
  return i;
}
    80004ef0:	854e                	mv	a0,s3
    80004ef2:	60a6                	ld	ra,72(sp)
    80004ef4:	6406                	ld	s0,64(sp)
    80004ef6:	74e2                	ld	s1,56(sp)
    80004ef8:	7942                	ld	s2,48(sp)
    80004efa:	79a2                	ld	s3,40(sp)
    80004efc:	7a02                	ld	s4,32(sp)
    80004efe:	6ae2                	ld	s5,24(sp)
    80004f00:	6b42                	ld	s6,16(sp)
    80004f02:	6161                	add	sp,sp,80
    80004f04:	8082                	ret
      release(&pi->lock);
    80004f06:	8526                	mv	a0,s1
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	d7e080e7          	jalr	-642(ra) # 80000c86 <release>
      return -1;
    80004f10:	59fd                	li	s3,-1
    80004f12:	bff9                	j	80004ef0 <piperead+0xca>

0000000080004f14 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f14:	1141                	add	sp,sp,-16
    80004f16:	e422                	sd	s0,8(sp)
    80004f18:	0800                	add	s0,sp,16
    80004f1a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f1c:	8905                	and	a0,a0,1
    80004f1e:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f20:	8b89                	and	a5,a5,2
    80004f22:	c399                	beqz	a5,80004f28 <flags2perm+0x14>
      perm |= PTE_W;
    80004f24:	00456513          	or	a0,a0,4
    return perm;
}
    80004f28:	6422                	ld	s0,8(sp)
    80004f2a:	0141                	add	sp,sp,16
    80004f2c:	8082                	ret

0000000080004f2e <exec>:

int
exec(char *path, char **argv)
{
    80004f2e:	df010113          	add	sp,sp,-528
    80004f32:	20113423          	sd	ra,520(sp)
    80004f36:	20813023          	sd	s0,512(sp)
    80004f3a:	ffa6                	sd	s1,504(sp)
    80004f3c:	fbca                	sd	s2,496(sp)
    80004f3e:	f7ce                	sd	s3,488(sp)
    80004f40:	f3d2                	sd	s4,480(sp)
    80004f42:	efd6                	sd	s5,472(sp)
    80004f44:	ebda                	sd	s6,464(sp)
    80004f46:	e7de                	sd	s7,456(sp)
    80004f48:	e3e2                	sd	s8,448(sp)
    80004f4a:	ff66                	sd	s9,440(sp)
    80004f4c:	fb6a                	sd	s10,432(sp)
    80004f4e:	f76e                	sd	s11,424(sp)
    80004f50:	0c00                	add	s0,sp,528
    80004f52:	892a                	mv	s2,a0
    80004f54:	dea43c23          	sd	a0,-520(s0)
    80004f58:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	a4a080e7          	jalr	-1462(ra) # 800019a6 <myproc>
    80004f64:	84aa                	mv	s1,a0

  begin_op();
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	48e080e7          	jalr	1166(ra) # 800043f4 <begin_op>

  if((ip = namei(path)) == 0){
    80004f6e:	854a                	mv	a0,s2
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	284080e7          	jalr	644(ra) # 800041f4 <namei>
    80004f78:	c92d                	beqz	a0,80004fea <exec+0xbc>
    80004f7a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	ad2080e7          	jalr	-1326(ra) # 80003a4e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f84:	04000713          	li	a4,64
    80004f88:	4681                	li	a3,0
    80004f8a:	e5040613          	add	a2,s0,-432
    80004f8e:	4581                	li	a1,0
    80004f90:	8552                	mv	a0,s4
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	d70080e7          	jalr	-656(ra) # 80003d02 <readi>
    80004f9a:	04000793          	li	a5,64
    80004f9e:	00f51a63          	bne	a0,a5,80004fb2 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fa2:	e5042703          	lw	a4,-432(s0)
    80004fa6:	464c47b7          	lui	a5,0x464c4
    80004faa:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fae:	04f70463          	beq	a4,a5,80004ff6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fb2:	8552                	mv	a0,s4
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	cfc080e7          	jalr	-772(ra) # 80003cb0 <iunlockput>
    end_op();
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	4b2080e7          	jalr	1202(ra) # 8000446e <end_op>
  }
  return -1;
    80004fc4:	557d                	li	a0,-1
}
    80004fc6:	20813083          	ld	ra,520(sp)
    80004fca:	20013403          	ld	s0,512(sp)
    80004fce:	74fe                	ld	s1,504(sp)
    80004fd0:	795e                	ld	s2,496(sp)
    80004fd2:	79be                	ld	s3,488(sp)
    80004fd4:	7a1e                	ld	s4,480(sp)
    80004fd6:	6afe                	ld	s5,472(sp)
    80004fd8:	6b5e                	ld	s6,464(sp)
    80004fda:	6bbe                	ld	s7,456(sp)
    80004fdc:	6c1e                	ld	s8,448(sp)
    80004fde:	7cfa                	ld	s9,440(sp)
    80004fe0:	7d5a                	ld	s10,432(sp)
    80004fe2:	7dba                	ld	s11,424(sp)
    80004fe4:	21010113          	add	sp,sp,528
    80004fe8:	8082                	ret
    end_op();
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	484080e7          	jalr	1156(ra) # 8000446e <end_op>
    return -1;
    80004ff2:	557d                	li	a0,-1
    80004ff4:	bfc9                	j	80004fc6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	a72080e7          	jalr	-1422(ra) # 80001a6a <proc_pagetable>
    80005000:	8b2a                	mv	s6,a0
    80005002:	d945                	beqz	a0,80004fb2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005004:	e7042d03          	lw	s10,-400(s0)
    80005008:	e8845783          	lhu	a5,-376(s0)
    8000500c:	10078463          	beqz	a5,80005114 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005010:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005012:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005014:	6c85                	lui	s9,0x1
    80005016:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000501a:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000501e:	6a85                	lui	s5,0x1
    80005020:	a0b5                	j	8000508c <exec+0x15e>
      panic("loadseg: address should exist");
    80005022:	00003517          	auipc	a0,0x3
    80005026:	6f650513          	add	a0,a0,1782 # 80008718 <syscalls+0x2a0>
    8000502a:	ffffb097          	auipc	ra,0xffffb
    8000502e:	512080e7          	jalr	1298(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005032:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005034:	8726                	mv	a4,s1
    80005036:	012c06bb          	addw	a3,s8,s2
    8000503a:	4581                	li	a1,0
    8000503c:	8552                	mv	a0,s4
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	cc4080e7          	jalr	-828(ra) # 80003d02 <readi>
    80005046:	2501                	sext.w	a0,a0
    80005048:	24a49863          	bne	s1,a0,80005298 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    8000504c:	012a893b          	addw	s2,s5,s2
    80005050:	03397563          	bgeu	s2,s3,8000507a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005054:	02091593          	sll	a1,s2,0x20
    80005058:	9181                	srl	a1,a1,0x20
    8000505a:	95de                	add	a1,a1,s7
    8000505c:	855a                	mv	a0,s6
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	ff8080e7          	jalr	-8(ra) # 80001056 <walkaddr>
    80005066:	862a                	mv	a2,a0
    if(pa == 0)
    80005068:	dd4d                	beqz	a0,80005022 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000506a:	412984bb          	subw	s1,s3,s2
    8000506e:	0004879b          	sext.w	a5,s1
    80005072:	fcfcf0e3          	bgeu	s9,a5,80005032 <exec+0x104>
    80005076:	84d6                	mv	s1,s5
    80005078:	bf6d                	j	80005032 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000507a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000507e:	2d85                	addw	s11,s11,1
    80005080:	038d0d1b          	addw	s10,s10,56
    80005084:	e8845783          	lhu	a5,-376(s0)
    80005088:	08fdd763          	bge	s11,a5,80005116 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000508c:	2d01                	sext.w	s10,s10
    8000508e:	03800713          	li	a4,56
    80005092:	86ea                	mv	a3,s10
    80005094:	e1840613          	add	a2,s0,-488
    80005098:	4581                	li	a1,0
    8000509a:	8552                	mv	a0,s4
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	c66080e7          	jalr	-922(ra) # 80003d02 <readi>
    800050a4:	03800793          	li	a5,56
    800050a8:	1ef51663          	bne	a0,a5,80005294 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800050ac:	e1842783          	lw	a5,-488(s0)
    800050b0:	4705                	li	a4,1
    800050b2:	fce796e3          	bne	a5,a4,8000507e <exec+0x150>
    if(ph.memsz < ph.filesz)
    800050b6:	e4043483          	ld	s1,-448(s0)
    800050ba:	e3843783          	ld	a5,-456(s0)
    800050be:	1ef4e863          	bltu	s1,a5,800052ae <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050c2:	e2843783          	ld	a5,-472(s0)
    800050c6:	94be                	add	s1,s1,a5
    800050c8:	1ef4e663          	bltu	s1,a5,800052b4 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800050cc:	df043703          	ld	a4,-528(s0)
    800050d0:	8ff9                	and	a5,a5,a4
    800050d2:	1e079463          	bnez	a5,800052ba <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050d6:	e1c42503          	lw	a0,-484(s0)
    800050da:	00000097          	auipc	ra,0x0
    800050de:	e3a080e7          	jalr	-454(ra) # 80004f14 <flags2perm>
    800050e2:	86aa                	mv	a3,a0
    800050e4:	8626                	mv	a2,s1
    800050e6:	85ca                	mv	a1,s2
    800050e8:	855a                	mv	a0,s6
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	320080e7          	jalr	800(ra) # 8000140a <uvmalloc>
    800050f2:	e0a43423          	sd	a0,-504(s0)
    800050f6:	1c050563          	beqz	a0,800052c0 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050fa:	e2843b83          	ld	s7,-472(s0)
    800050fe:	e2042c03          	lw	s8,-480(s0)
    80005102:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005106:	00098463          	beqz	s3,8000510e <exec+0x1e0>
    8000510a:	4901                	li	s2,0
    8000510c:	b7a1                	j	80005054 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000510e:	e0843903          	ld	s2,-504(s0)
    80005112:	b7b5                	j	8000507e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005114:	4901                	li	s2,0
  iunlockput(ip);
    80005116:	8552                	mv	a0,s4
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	b98080e7          	jalr	-1128(ra) # 80003cb0 <iunlockput>
  end_op();
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	34e080e7          	jalr	846(ra) # 8000446e <end_op>
  p = myproc();
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	87e080e7          	jalr	-1922(ra) # 800019a6 <myproc>
    80005130:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005132:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005136:	6985                	lui	s3,0x1
    80005138:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000513a:	99ca                	add	s3,s3,s2
    8000513c:	77fd                	lui	a5,0xfffff
    8000513e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005142:	4691                	li	a3,4
    80005144:	6609                	lui	a2,0x2
    80005146:	964e                	add	a2,a2,s3
    80005148:	85ce                	mv	a1,s3
    8000514a:	855a                	mv	a0,s6
    8000514c:	ffffc097          	auipc	ra,0xffffc
    80005150:	2be080e7          	jalr	702(ra) # 8000140a <uvmalloc>
    80005154:	892a                	mv	s2,a0
    80005156:	e0a43423          	sd	a0,-504(s0)
    8000515a:	e509                	bnez	a0,80005164 <exec+0x236>
  if(pagetable)
    8000515c:	e1343423          	sd	s3,-504(s0)
    80005160:	4a01                	li	s4,0
    80005162:	aa1d                	j	80005298 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005164:	75f9                	lui	a1,0xffffe
    80005166:	95aa                	add	a1,a1,a0
    80005168:	855a                	mv	a0,s6
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	4ca080e7          	jalr	1226(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005172:	7bfd                	lui	s7,0xfffff
    80005174:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005176:	e0043783          	ld	a5,-512(s0)
    8000517a:	6388                	ld	a0,0(a5)
    8000517c:	c52d                	beqz	a0,800051e6 <exec+0x2b8>
    8000517e:	e9040993          	add	s3,s0,-368
    80005182:	f9040c13          	add	s8,s0,-112
    80005186:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	cc0080e7          	jalr	-832(ra) # 80000e48 <strlen>
    80005190:	0015079b          	addw	a5,a0,1
    80005194:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005198:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    8000519c:	13796563          	bltu	s2,s7,800052c6 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a0:	e0043d03          	ld	s10,-512(s0)
    800051a4:	000d3a03          	ld	s4,0(s10)
    800051a8:	8552                	mv	a0,s4
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	c9e080e7          	jalr	-866(ra) # 80000e48 <strlen>
    800051b2:	0015069b          	addw	a3,a0,1
    800051b6:	8652                	mv	a2,s4
    800051b8:	85ca                	mv	a1,s2
    800051ba:	855a                	mv	a0,s6
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	4aa080e7          	jalr	1194(ra) # 80001666 <copyout>
    800051c4:	10054363          	bltz	a0,800052ca <exec+0x39c>
    ustack[argc] = sp;
    800051c8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051cc:	0485                	add	s1,s1,1
    800051ce:	008d0793          	add	a5,s10,8
    800051d2:	e0f43023          	sd	a5,-512(s0)
    800051d6:	008d3503          	ld	a0,8(s10)
    800051da:	c909                	beqz	a0,800051ec <exec+0x2be>
    if(argc >= MAXARG)
    800051dc:	09a1                	add	s3,s3,8
    800051de:	fb8995e3          	bne	s3,s8,80005188 <exec+0x25a>
  ip = 0;
    800051e2:	4a01                	li	s4,0
    800051e4:	a855                	j	80005298 <exec+0x36a>
  sp = sz;
    800051e6:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800051ea:	4481                	li	s1,0
  ustack[argc] = 0;
    800051ec:	00349793          	sll	a5,s1,0x3
    800051f0:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffda7e0>
    800051f4:	97a2                	add	a5,a5,s0
    800051f6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051fa:	00148693          	add	a3,s1,1
    800051fe:	068e                	sll	a3,a3,0x3
    80005200:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005204:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005208:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000520c:	f57968e3          	bltu	s2,s7,8000515c <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005210:	e9040613          	add	a2,s0,-368
    80005214:	85ca                	mv	a1,s2
    80005216:	855a                	mv	a0,s6
    80005218:	ffffc097          	auipc	ra,0xffffc
    8000521c:	44e080e7          	jalr	1102(ra) # 80001666 <copyout>
    80005220:	0a054763          	bltz	a0,800052ce <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005224:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005228:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000522c:	df843783          	ld	a5,-520(s0)
    80005230:	0007c703          	lbu	a4,0(a5)
    80005234:	cf11                	beqz	a4,80005250 <exec+0x322>
    80005236:	0785                	add	a5,a5,1
    if(*s == '/')
    80005238:	02f00693          	li	a3,47
    8000523c:	a039                	j	8000524a <exec+0x31c>
      last = s+1;
    8000523e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005242:	0785                	add	a5,a5,1
    80005244:	fff7c703          	lbu	a4,-1(a5)
    80005248:	c701                	beqz	a4,80005250 <exec+0x322>
    if(*s == '/')
    8000524a:	fed71ce3          	bne	a4,a3,80005242 <exec+0x314>
    8000524e:	bfc5                	j	8000523e <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80005250:	4641                	li	a2,16
    80005252:	df843583          	ld	a1,-520(s0)
    80005256:	158a8513          	add	a0,s5,344
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	bbc080e7          	jalr	-1092(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005262:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005266:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000526a:	e0843783          	ld	a5,-504(s0)
    8000526e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005272:	058ab783          	ld	a5,88(s5)
    80005276:	e6843703          	ld	a4,-408(s0)
    8000527a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000527c:	058ab783          	ld	a5,88(s5)
    80005280:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005284:	85e6                	mv	a1,s9
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	880080e7          	jalr	-1920(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000528e:	0004851b          	sext.w	a0,s1
    80005292:	bb15                	j	80004fc6 <exec+0x98>
    80005294:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005298:	e0843583          	ld	a1,-504(s0)
    8000529c:	855a                	mv	a0,s6
    8000529e:	ffffd097          	auipc	ra,0xffffd
    800052a2:	868080e7          	jalr	-1944(ra) # 80001b06 <proc_freepagetable>
  return -1;
    800052a6:	557d                	li	a0,-1
  if(ip){
    800052a8:	d00a0fe3          	beqz	s4,80004fc6 <exec+0x98>
    800052ac:	b319                	j	80004fb2 <exec+0x84>
    800052ae:	e1243423          	sd	s2,-504(s0)
    800052b2:	b7dd                	j	80005298 <exec+0x36a>
    800052b4:	e1243423          	sd	s2,-504(s0)
    800052b8:	b7c5                	j	80005298 <exec+0x36a>
    800052ba:	e1243423          	sd	s2,-504(s0)
    800052be:	bfe9                	j	80005298 <exec+0x36a>
    800052c0:	e1243423          	sd	s2,-504(s0)
    800052c4:	bfd1                	j	80005298 <exec+0x36a>
  ip = 0;
    800052c6:	4a01                	li	s4,0
    800052c8:	bfc1                	j	80005298 <exec+0x36a>
    800052ca:	4a01                	li	s4,0
  if(pagetable)
    800052cc:	b7f1                	j	80005298 <exec+0x36a>
  sz = sz1;
    800052ce:	e0843983          	ld	s3,-504(s0)
    800052d2:	b569                	j	8000515c <exec+0x22e>

00000000800052d4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052d4:	7179                	add	sp,sp,-48
    800052d6:	f406                	sd	ra,40(sp)
    800052d8:	f022                	sd	s0,32(sp)
    800052da:	ec26                	sd	s1,24(sp)
    800052dc:	e84a                	sd	s2,16(sp)
    800052de:	1800                	add	s0,sp,48
    800052e0:	892e                	mv	s2,a1
    800052e2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052e4:	fdc40593          	add	a1,s0,-36
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	a62080e7          	jalr	-1438(ra) # 80002d4a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052f0:	fdc42703          	lw	a4,-36(s0)
    800052f4:	47bd                	li	a5,15
    800052f6:	02e7eb63          	bltu	a5,a4,8000532c <argfd+0x58>
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	6ac080e7          	jalr	1708(ra) # 800019a6 <myproc>
    80005302:	fdc42703          	lw	a4,-36(s0)
    80005306:	01a70793          	add	a5,a4,26
    8000530a:	078e                	sll	a5,a5,0x3
    8000530c:	953e                	add	a0,a0,a5
    8000530e:	611c                	ld	a5,0(a0)
    80005310:	c385                	beqz	a5,80005330 <argfd+0x5c>
    return -1;
  if(pfd)
    80005312:	00090463          	beqz	s2,8000531a <argfd+0x46>
    *pfd = fd;
    80005316:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000531a:	4501                	li	a0,0
  if(pf)
    8000531c:	c091                	beqz	s1,80005320 <argfd+0x4c>
    *pf = f;
    8000531e:	e09c                	sd	a5,0(s1)
}
    80005320:	70a2                	ld	ra,40(sp)
    80005322:	7402                	ld	s0,32(sp)
    80005324:	64e2                	ld	s1,24(sp)
    80005326:	6942                	ld	s2,16(sp)
    80005328:	6145                	add	sp,sp,48
    8000532a:	8082                	ret
    return -1;
    8000532c:	557d                	li	a0,-1
    8000532e:	bfcd                	j	80005320 <argfd+0x4c>
    80005330:	557d                	li	a0,-1
    80005332:	b7fd                	j	80005320 <argfd+0x4c>

0000000080005334 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005334:	1101                	add	sp,sp,-32
    80005336:	ec06                	sd	ra,24(sp)
    80005338:	e822                	sd	s0,16(sp)
    8000533a:	e426                	sd	s1,8(sp)
    8000533c:	1000                	add	s0,sp,32
    8000533e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	666080e7          	jalr	1638(ra) # 800019a6 <myproc>
    80005348:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000534a:	0d050793          	add	a5,a0,208
    8000534e:	4501                	li	a0,0
    80005350:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005352:	6398                	ld	a4,0(a5)
    80005354:	cb19                	beqz	a4,8000536a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005356:	2505                	addw	a0,a0,1
    80005358:	07a1                	add	a5,a5,8
    8000535a:	fed51ce3          	bne	a0,a3,80005352 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000535e:	557d                	li	a0,-1
}
    80005360:	60e2                	ld	ra,24(sp)
    80005362:	6442                	ld	s0,16(sp)
    80005364:	64a2                	ld	s1,8(sp)
    80005366:	6105                	add	sp,sp,32
    80005368:	8082                	ret
      p->ofile[fd] = f;
    8000536a:	01a50793          	add	a5,a0,26
    8000536e:	078e                	sll	a5,a5,0x3
    80005370:	963e                	add	a2,a2,a5
    80005372:	e204                	sd	s1,0(a2)
      return fd;
    80005374:	b7f5                	j	80005360 <fdalloc+0x2c>

0000000080005376 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005376:	715d                	add	sp,sp,-80
    80005378:	e486                	sd	ra,72(sp)
    8000537a:	e0a2                	sd	s0,64(sp)
    8000537c:	fc26                	sd	s1,56(sp)
    8000537e:	f84a                	sd	s2,48(sp)
    80005380:	f44e                	sd	s3,40(sp)
    80005382:	f052                	sd	s4,32(sp)
    80005384:	ec56                	sd	s5,24(sp)
    80005386:	e85a                	sd	s6,16(sp)
    80005388:	0880                	add	s0,sp,80
    8000538a:	8b2e                	mv	s6,a1
    8000538c:	89b2                	mv	s3,a2
    8000538e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005390:	fb040593          	add	a1,s0,-80
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	e7e080e7          	jalr	-386(ra) # 80004212 <nameiparent>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	14050b63          	beqz	a0,800054f4 <create+0x17e>
    return 0;

  ilock(dp);
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	6ac080e7          	jalr	1708(ra) # 80003a4e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053aa:	4601                	li	a2,0
    800053ac:	fb040593          	add	a1,s0,-80
    800053b0:	8526                	mv	a0,s1
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	b80080e7          	jalr	-1152(ra) # 80003f32 <dirlookup>
    800053ba:	8aaa                	mv	s5,a0
    800053bc:	c921                	beqz	a0,8000540c <create+0x96>
    iunlockput(dp);
    800053be:	8526                	mv	a0,s1
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	8f0080e7          	jalr	-1808(ra) # 80003cb0 <iunlockput>
    ilock(ip);
    800053c8:	8556                	mv	a0,s5
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	684080e7          	jalr	1668(ra) # 80003a4e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053d2:	4789                	li	a5,2
    800053d4:	02fb1563          	bne	s6,a5,800053fe <create+0x88>
    800053d8:	044ad783          	lhu	a5,68(s5)
    800053dc:	37f9                	addw	a5,a5,-2
    800053de:	17c2                	sll	a5,a5,0x30
    800053e0:	93c1                	srl	a5,a5,0x30
    800053e2:	4705                	li	a4,1
    800053e4:	00f76d63          	bltu	a4,a5,800053fe <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053e8:	8556                	mv	a0,s5
    800053ea:	60a6                	ld	ra,72(sp)
    800053ec:	6406                	ld	s0,64(sp)
    800053ee:	74e2                	ld	s1,56(sp)
    800053f0:	7942                	ld	s2,48(sp)
    800053f2:	79a2                	ld	s3,40(sp)
    800053f4:	7a02                	ld	s4,32(sp)
    800053f6:	6ae2                	ld	s5,24(sp)
    800053f8:	6b42                	ld	s6,16(sp)
    800053fa:	6161                	add	sp,sp,80
    800053fc:	8082                	ret
    iunlockput(ip);
    800053fe:	8556                	mv	a0,s5
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	8b0080e7          	jalr	-1872(ra) # 80003cb0 <iunlockput>
    return 0;
    80005408:	4a81                	li	s5,0
    8000540a:	bff9                	j	800053e8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000540c:	85da                	mv	a1,s6
    8000540e:	4088                	lw	a0,0(s1)
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	4a6080e7          	jalr	1190(ra) # 800038b6 <ialloc>
    80005418:	8a2a                	mv	s4,a0
    8000541a:	c529                	beqz	a0,80005464 <create+0xee>
  ilock(ip);
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	632080e7          	jalr	1586(ra) # 80003a4e <ilock>
  ip->major = major;
    80005424:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005428:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000542c:	4905                	li	s2,1
    8000542e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005432:	8552                	mv	a0,s4
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	54e080e7          	jalr	1358(ra) # 80003982 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000543c:	032b0b63          	beq	s6,s2,80005472 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005440:	004a2603          	lw	a2,4(s4)
    80005444:	fb040593          	add	a1,s0,-80
    80005448:	8526                	mv	a0,s1
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	cf8080e7          	jalr	-776(ra) # 80004142 <dirlink>
    80005452:	06054f63          	bltz	a0,800054d0 <create+0x15a>
  iunlockput(dp);
    80005456:	8526                	mv	a0,s1
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	858080e7          	jalr	-1960(ra) # 80003cb0 <iunlockput>
  return ip;
    80005460:	8ad2                	mv	s5,s4
    80005462:	b759                	j	800053e8 <create+0x72>
    iunlockput(dp);
    80005464:	8526                	mv	a0,s1
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	84a080e7          	jalr	-1974(ra) # 80003cb0 <iunlockput>
    return 0;
    8000546e:	8ad2                	mv	s5,s4
    80005470:	bfa5                	j	800053e8 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005472:	004a2603          	lw	a2,4(s4)
    80005476:	00003597          	auipc	a1,0x3
    8000547a:	2c258593          	add	a1,a1,706 # 80008738 <syscalls+0x2c0>
    8000547e:	8552                	mv	a0,s4
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	cc2080e7          	jalr	-830(ra) # 80004142 <dirlink>
    80005488:	04054463          	bltz	a0,800054d0 <create+0x15a>
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	00003597          	auipc	a1,0x3
    80005492:	2b258593          	add	a1,a1,690 # 80008740 <syscalls+0x2c8>
    80005496:	8552                	mv	a0,s4
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	caa080e7          	jalr	-854(ra) # 80004142 <dirlink>
    800054a0:	02054863          	bltz	a0,800054d0 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800054a4:	004a2603          	lw	a2,4(s4)
    800054a8:	fb040593          	add	a1,s0,-80
    800054ac:	8526                	mv	a0,s1
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c94080e7          	jalr	-876(ra) # 80004142 <dirlink>
    800054b6:	00054d63          	bltz	a0,800054d0 <create+0x15a>
    dp->nlink++;  // for ".."
    800054ba:	04a4d783          	lhu	a5,74(s1)
    800054be:	2785                	addw	a5,a5,1
    800054c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	4bc080e7          	jalr	1212(ra) # 80003982 <iupdate>
    800054ce:	b761                	j	80005456 <create+0xe0>
  ip->nlink = 0;
    800054d0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054d4:	8552                	mv	a0,s4
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	4ac080e7          	jalr	1196(ra) # 80003982 <iupdate>
  iunlockput(ip);
    800054de:	8552                	mv	a0,s4
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	7d0080e7          	jalr	2000(ra) # 80003cb0 <iunlockput>
  iunlockput(dp);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	7c6080e7          	jalr	1990(ra) # 80003cb0 <iunlockput>
  return 0;
    800054f2:	bddd                	j	800053e8 <create+0x72>
    return 0;
    800054f4:	8aaa                	mv	s5,a0
    800054f6:	bdcd                	j	800053e8 <create+0x72>

00000000800054f8 <sys_dup>:
{
    800054f8:	7179                	add	sp,sp,-48
    800054fa:	f406                	sd	ra,40(sp)
    800054fc:	f022                	sd	s0,32(sp)
    800054fe:	ec26                	sd	s1,24(sp)
    80005500:	e84a                	sd	s2,16(sp)
    80005502:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005504:	fd840613          	add	a2,s0,-40
    80005508:	4581                	li	a1,0
    8000550a:	4501                	li	a0,0
    8000550c:	00000097          	auipc	ra,0x0
    80005510:	dc8080e7          	jalr	-568(ra) # 800052d4 <argfd>
    return -1;
    80005514:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005516:	02054363          	bltz	a0,8000553c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000551a:	fd843903          	ld	s2,-40(s0)
    8000551e:	854a                	mv	a0,s2
    80005520:	00000097          	auipc	ra,0x0
    80005524:	e14080e7          	jalr	-492(ra) # 80005334 <fdalloc>
    80005528:	84aa                	mv	s1,a0
    return -1;
    8000552a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000552c:	00054863          	bltz	a0,8000553c <sys_dup+0x44>
  filedup(f);
    80005530:	854a                	mv	a0,s2
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	334080e7          	jalr	820(ra) # 80004866 <filedup>
  return fd;
    8000553a:	87a6                	mv	a5,s1
}
    8000553c:	853e                	mv	a0,a5
    8000553e:	70a2                	ld	ra,40(sp)
    80005540:	7402                	ld	s0,32(sp)
    80005542:	64e2                	ld	s1,24(sp)
    80005544:	6942                	ld	s2,16(sp)
    80005546:	6145                	add	sp,sp,48
    80005548:	8082                	ret

000000008000554a <sys_read>:
{
    8000554a:	7179                	add	sp,sp,-48
    8000554c:	f406                	sd	ra,40(sp)
    8000554e:	f022                	sd	s0,32(sp)
    80005550:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005552:	fd840593          	add	a1,s0,-40
    80005556:	4505                	li	a0,1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	812080e7          	jalr	-2030(ra) # 80002d6a <argaddr>
  argint(2, &n);
    80005560:	fe440593          	add	a1,s0,-28
    80005564:	4509                	li	a0,2
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	7e4080e7          	jalr	2020(ra) # 80002d4a <argint>
  if(argfd(0, 0, &f) < 0)
    8000556e:	fe840613          	add	a2,s0,-24
    80005572:	4581                	li	a1,0
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	d5e080e7          	jalr	-674(ra) # 800052d4 <argfd>
    8000557e:	87aa                	mv	a5,a0
    return -1;
    80005580:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005582:	0007cc63          	bltz	a5,8000559a <sys_read+0x50>
  return fileread(f, p, n);
    80005586:	fe442603          	lw	a2,-28(s0)
    8000558a:	fd843583          	ld	a1,-40(s0)
    8000558e:	fe843503          	ld	a0,-24(s0)
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	460080e7          	jalr	1120(ra) # 800049f2 <fileread>
}
    8000559a:	70a2                	ld	ra,40(sp)
    8000559c:	7402                	ld	s0,32(sp)
    8000559e:	6145                	add	sp,sp,48
    800055a0:	8082                	ret

00000000800055a2 <sys_write>:
{
    800055a2:	7179                	add	sp,sp,-48
    800055a4:	f406                	sd	ra,40(sp)
    800055a6:	f022                	sd	s0,32(sp)
    800055a8:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800055aa:	fd840593          	add	a1,s0,-40
    800055ae:	4505                	li	a0,1
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	7ba080e7          	jalr	1978(ra) # 80002d6a <argaddr>
  argint(2, &n);
    800055b8:	fe440593          	add	a1,s0,-28
    800055bc:	4509                	li	a0,2
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	78c080e7          	jalr	1932(ra) # 80002d4a <argint>
  if(argfd(0, 0, &f) < 0)
    800055c6:	fe840613          	add	a2,s0,-24
    800055ca:	4581                	li	a1,0
    800055cc:	4501                	li	a0,0
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	d06080e7          	jalr	-762(ra) # 800052d4 <argfd>
    800055d6:	87aa                	mv	a5,a0
    return -1;
    800055d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055da:	0007cc63          	bltz	a5,800055f2 <sys_write+0x50>
  return filewrite(f, p, n);
    800055de:	fe442603          	lw	a2,-28(s0)
    800055e2:	fd843583          	ld	a1,-40(s0)
    800055e6:	fe843503          	ld	a0,-24(s0)
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	4ca080e7          	jalr	1226(ra) # 80004ab4 <filewrite>
}
    800055f2:	70a2                	ld	ra,40(sp)
    800055f4:	7402                	ld	s0,32(sp)
    800055f6:	6145                	add	sp,sp,48
    800055f8:	8082                	ret

00000000800055fa <sys_close>:
{
    800055fa:	1101                	add	sp,sp,-32
    800055fc:	ec06                	sd	ra,24(sp)
    800055fe:	e822                	sd	s0,16(sp)
    80005600:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005602:	fe040613          	add	a2,s0,-32
    80005606:	fec40593          	add	a1,s0,-20
    8000560a:	4501                	li	a0,0
    8000560c:	00000097          	auipc	ra,0x0
    80005610:	cc8080e7          	jalr	-824(ra) # 800052d4 <argfd>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005616:	02054463          	bltz	a0,8000563e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000561a:	ffffc097          	auipc	ra,0xffffc
    8000561e:	38c080e7          	jalr	908(ra) # 800019a6 <myproc>
    80005622:	fec42783          	lw	a5,-20(s0)
    80005626:	07e9                	add	a5,a5,26
    80005628:	078e                	sll	a5,a5,0x3
    8000562a:	953e                	add	a0,a0,a5
    8000562c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005630:	fe043503          	ld	a0,-32(s0)
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	284080e7          	jalr	644(ra) # 800048b8 <fileclose>
  return 0;
    8000563c:	4781                	li	a5,0
}
    8000563e:	853e                	mv	a0,a5
    80005640:	60e2                	ld	ra,24(sp)
    80005642:	6442                	ld	s0,16(sp)
    80005644:	6105                	add	sp,sp,32
    80005646:	8082                	ret

0000000080005648 <sys_fstat>:
{
    80005648:	1101                	add	sp,sp,-32
    8000564a:	ec06                	sd	ra,24(sp)
    8000564c:	e822                	sd	s0,16(sp)
    8000564e:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005650:	fe040593          	add	a1,s0,-32
    80005654:	4505                	li	a0,1
    80005656:	ffffd097          	auipc	ra,0xffffd
    8000565a:	714080e7          	jalr	1812(ra) # 80002d6a <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000565e:	fe840613          	add	a2,s0,-24
    80005662:	4581                	li	a1,0
    80005664:	4501                	li	a0,0
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	c6e080e7          	jalr	-914(ra) # 800052d4 <argfd>
    8000566e:	87aa                	mv	a5,a0
    return -1;
    80005670:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005672:	0007ca63          	bltz	a5,80005686 <sys_fstat+0x3e>
  return filestat(f, st);
    80005676:	fe043583          	ld	a1,-32(s0)
    8000567a:	fe843503          	ld	a0,-24(s0)
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	302080e7          	jalr	770(ra) # 80004980 <filestat>
}
    80005686:	60e2                	ld	ra,24(sp)
    80005688:	6442                	ld	s0,16(sp)
    8000568a:	6105                	add	sp,sp,32
    8000568c:	8082                	ret

000000008000568e <sys_link>:
{
    8000568e:	7169                	add	sp,sp,-304
    80005690:	f606                	sd	ra,296(sp)
    80005692:	f222                	sd	s0,288(sp)
    80005694:	ee26                	sd	s1,280(sp)
    80005696:	ea4a                	sd	s2,272(sp)
    80005698:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569a:	08000613          	li	a2,128
    8000569e:	ed040593          	add	a1,s0,-304
    800056a2:	4501                	li	a0,0
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	6e6080e7          	jalr	1766(ra) # 80002d8a <argstr>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ae:	10054e63          	bltz	a0,800057ca <sys_link+0x13c>
    800056b2:	08000613          	li	a2,128
    800056b6:	f5040593          	add	a1,s0,-176
    800056ba:	4505                	li	a0,1
    800056bc:	ffffd097          	auipc	ra,0xffffd
    800056c0:	6ce080e7          	jalr	1742(ra) # 80002d8a <argstr>
    return -1;
    800056c4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c6:	10054263          	bltz	a0,800057ca <sys_link+0x13c>
  begin_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	d2a080e7          	jalr	-726(ra) # 800043f4 <begin_op>
  if((ip = namei(old)) == 0){
    800056d2:	ed040513          	add	a0,s0,-304
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	b1e080e7          	jalr	-1250(ra) # 800041f4 <namei>
    800056de:	84aa                	mv	s1,a0
    800056e0:	c551                	beqz	a0,8000576c <sys_link+0xde>
  ilock(ip);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	36c080e7          	jalr	876(ra) # 80003a4e <ilock>
  if(ip->type == T_DIR){
    800056ea:	04449703          	lh	a4,68(s1)
    800056ee:	4785                	li	a5,1
    800056f0:	08f70463          	beq	a4,a5,80005778 <sys_link+0xea>
  ip->nlink++;
    800056f4:	04a4d783          	lhu	a5,74(s1)
    800056f8:	2785                	addw	a5,a5,1
    800056fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	282080e7          	jalr	642(ra) # 80003982 <iupdate>
  iunlock(ip);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	406080e7          	jalr	1030(ra) # 80003b10 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005712:	fd040593          	add	a1,s0,-48
    80005716:	f5040513          	add	a0,s0,-176
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	af8080e7          	jalr	-1288(ra) # 80004212 <nameiparent>
    80005722:	892a                	mv	s2,a0
    80005724:	c935                	beqz	a0,80005798 <sys_link+0x10a>
  ilock(dp);
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	328080e7          	jalr	808(ra) # 80003a4e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000572e:	00092703          	lw	a4,0(s2)
    80005732:	409c                	lw	a5,0(s1)
    80005734:	04f71d63          	bne	a4,a5,8000578e <sys_link+0x100>
    80005738:	40d0                	lw	a2,4(s1)
    8000573a:	fd040593          	add	a1,s0,-48
    8000573e:	854a                	mv	a0,s2
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	a02080e7          	jalr	-1534(ra) # 80004142 <dirlink>
    80005748:	04054363          	bltz	a0,8000578e <sys_link+0x100>
  iunlockput(dp);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	562080e7          	jalr	1378(ra) # 80003cb0 <iunlockput>
  iput(ip);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	4b0080e7          	jalr	1200(ra) # 80003c08 <iput>
  end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	d0e080e7          	jalr	-754(ra) # 8000446e <end_op>
  return 0;
    80005768:	4781                	li	a5,0
    8000576a:	a085                	j	800057ca <sys_link+0x13c>
    end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	d02080e7          	jalr	-766(ra) # 8000446e <end_op>
    return -1;
    80005774:	57fd                	li	a5,-1
    80005776:	a891                	j	800057ca <sys_link+0x13c>
    iunlockput(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	536080e7          	jalr	1334(ra) # 80003cb0 <iunlockput>
    end_op();
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	cec080e7          	jalr	-788(ra) # 8000446e <end_op>
    return -1;
    8000578a:	57fd                	li	a5,-1
    8000578c:	a83d                	j	800057ca <sys_link+0x13c>
    iunlockput(dp);
    8000578e:	854a                	mv	a0,s2
    80005790:	ffffe097          	auipc	ra,0xffffe
    80005794:	520080e7          	jalr	1312(ra) # 80003cb0 <iunlockput>
  ilock(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	2b4080e7          	jalr	692(ra) # 80003a4e <ilock>
  ip->nlink--;
    800057a2:	04a4d783          	lhu	a5,74(s1)
    800057a6:	37fd                	addw	a5,a5,-1
    800057a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	1d4080e7          	jalr	468(ra) # 80003982 <iupdate>
  iunlockput(ip);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	4f8080e7          	jalr	1272(ra) # 80003cb0 <iunlockput>
  end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	cae080e7          	jalr	-850(ra) # 8000446e <end_op>
  return -1;
    800057c8:	57fd                	li	a5,-1
}
    800057ca:	853e                	mv	a0,a5
    800057cc:	70b2                	ld	ra,296(sp)
    800057ce:	7412                	ld	s0,288(sp)
    800057d0:	64f2                	ld	s1,280(sp)
    800057d2:	6952                	ld	s2,272(sp)
    800057d4:	6155                	add	sp,sp,304
    800057d6:	8082                	ret

00000000800057d8 <sys_unlink>:
{
    800057d8:	7151                	add	sp,sp,-240
    800057da:	f586                	sd	ra,232(sp)
    800057dc:	f1a2                	sd	s0,224(sp)
    800057de:	eda6                	sd	s1,216(sp)
    800057e0:	e9ca                	sd	s2,208(sp)
    800057e2:	e5ce                	sd	s3,200(sp)
    800057e4:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057e6:	08000613          	li	a2,128
    800057ea:	f3040593          	add	a1,s0,-208
    800057ee:	4501                	li	a0,0
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	59a080e7          	jalr	1434(ra) # 80002d8a <argstr>
    800057f8:	18054163          	bltz	a0,8000597a <sys_unlink+0x1a2>
  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	bf8080e7          	jalr	-1032(ra) # 800043f4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005804:	fb040593          	add	a1,s0,-80
    80005808:	f3040513          	add	a0,s0,-208
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	a06080e7          	jalr	-1530(ra) # 80004212 <nameiparent>
    80005814:	84aa                	mv	s1,a0
    80005816:	c979                	beqz	a0,800058ec <sys_unlink+0x114>
  ilock(dp);
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	236080e7          	jalr	566(ra) # 80003a4e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005820:	00003597          	auipc	a1,0x3
    80005824:	f1858593          	add	a1,a1,-232 # 80008738 <syscalls+0x2c0>
    80005828:	fb040513          	add	a0,s0,-80
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	6ec080e7          	jalr	1772(ra) # 80003f18 <namecmp>
    80005834:	14050a63          	beqz	a0,80005988 <sys_unlink+0x1b0>
    80005838:	00003597          	auipc	a1,0x3
    8000583c:	f0858593          	add	a1,a1,-248 # 80008740 <syscalls+0x2c8>
    80005840:	fb040513          	add	a0,s0,-80
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	6d4080e7          	jalr	1748(ra) # 80003f18 <namecmp>
    8000584c:	12050e63          	beqz	a0,80005988 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005850:	f2c40613          	add	a2,s0,-212
    80005854:	fb040593          	add	a1,s0,-80
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	6d8080e7          	jalr	1752(ra) # 80003f32 <dirlookup>
    80005862:	892a                	mv	s2,a0
    80005864:	12050263          	beqz	a0,80005988 <sys_unlink+0x1b0>
  ilock(ip);
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	1e6080e7          	jalr	486(ra) # 80003a4e <ilock>
  if(ip->nlink < 1)
    80005870:	04a91783          	lh	a5,74(s2)
    80005874:	08f05263          	blez	a5,800058f8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005878:	04491703          	lh	a4,68(s2)
    8000587c:	4785                	li	a5,1
    8000587e:	08f70563          	beq	a4,a5,80005908 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005882:	4641                	li	a2,16
    80005884:	4581                	li	a1,0
    80005886:	fc040513          	add	a0,s0,-64
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	444080e7          	jalr	1092(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005892:	4741                	li	a4,16
    80005894:	f2c42683          	lw	a3,-212(s0)
    80005898:	fc040613          	add	a2,s0,-64
    8000589c:	4581                	li	a1,0
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	55a080e7          	jalr	1370(ra) # 80003dfa <writei>
    800058a8:	47c1                	li	a5,16
    800058aa:	0af51563          	bne	a0,a5,80005954 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058ae:	04491703          	lh	a4,68(s2)
    800058b2:	4785                	li	a5,1
    800058b4:	0af70863          	beq	a4,a5,80005964 <sys_unlink+0x18c>
  iunlockput(dp);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	3f6080e7          	jalr	1014(ra) # 80003cb0 <iunlockput>
  ip->nlink--;
    800058c2:	04a95783          	lhu	a5,74(s2)
    800058c6:	37fd                	addw	a5,a5,-1
    800058c8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	0b4080e7          	jalr	180(ra) # 80003982 <iupdate>
  iunlockput(ip);
    800058d6:	854a                	mv	a0,s2
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	3d8080e7          	jalr	984(ra) # 80003cb0 <iunlockput>
  end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	b8e080e7          	jalr	-1138(ra) # 8000446e <end_op>
  return 0;
    800058e8:	4501                	li	a0,0
    800058ea:	a84d                	j	8000599c <sys_unlink+0x1c4>
    end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	b82080e7          	jalr	-1150(ra) # 8000446e <end_op>
    return -1;
    800058f4:	557d                	li	a0,-1
    800058f6:	a05d                	j	8000599c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058f8:	00003517          	auipc	a0,0x3
    800058fc:	e5050513          	add	a0,a0,-432 # 80008748 <syscalls+0x2d0>
    80005900:	ffffb097          	auipc	ra,0xffffb
    80005904:	c3c080e7          	jalr	-964(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005908:	04c92703          	lw	a4,76(s2)
    8000590c:	02000793          	li	a5,32
    80005910:	f6e7f9e3          	bgeu	a5,a4,80005882 <sys_unlink+0xaa>
    80005914:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005918:	4741                	li	a4,16
    8000591a:	86ce                	mv	a3,s3
    8000591c:	f1840613          	add	a2,s0,-232
    80005920:	4581                	li	a1,0
    80005922:	854a                	mv	a0,s2
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	3de080e7          	jalr	990(ra) # 80003d02 <readi>
    8000592c:	47c1                	li	a5,16
    8000592e:	00f51b63          	bne	a0,a5,80005944 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005932:	f1845783          	lhu	a5,-232(s0)
    80005936:	e7a1                	bnez	a5,8000597e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005938:	29c1                	addw	s3,s3,16
    8000593a:	04c92783          	lw	a5,76(s2)
    8000593e:	fcf9ede3          	bltu	s3,a5,80005918 <sys_unlink+0x140>
    80005942:	b781                	j	80005882 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005944:	00003517          	auipc	a0,0x3
    80005948:	e1c50513          	add	a0,a0,-484 # 80008760 <syscalls+0x2e8>
    8000594c:	ffffb097          	auipc	ra,0xffffb
    80005950:	bf0080e7          	jalr	-1040(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005954:	00003517          	auipc	a0,0x3
    80005958:	e2450513          	add	a0,a0,-476 # 80008778 <syscalls+0x300>
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	be0080e7          	jalr	-1056(ra) # 8000053c <panic>
    dp->nlink--;
    80005964:	04a4d783          	lhu	a5,74(s1)
    80005968:	37fd                	addw	a5,a5,-1
    8000596a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	012080e7          	jalr	18(ra) # 80003982 <iupdate>
    80005978:	b781                	j	800058b8 <sys_unlink+0xe0>
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	a005                	j	8000599c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000597e:	854a                	mv	a0,s2
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	330080e7          	jalr	816(ra) # 80003cb0 <iunlockput>
  iunlockput(dp);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	326080e7          	jalr	806(ra) # 80003cb0 <iunlockput>
  end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	adc080e7          	jalr	-1316(ra) # 8000446e <end_op>
  return -1;
    8000599a:	557d                	li	a0,-1
}
    8000599c:	70ae                	ld	ra,232(sp)
    8000599e:	740e                	ld	s0,224(sp)
    800059a0:	64ee                	ld	s1,216(sp)
    800059a2:	694e                	ld	s2,208(sp)
    800059a4:	69ae                	ld	s3,200(sp)
    800059a6:	616d                	add	sp,sp,240
    800059a8:	8082                	ret

00000000800059aa <sys_open>:

uint64
sys_open(void)
{
    800059aa:	7131                	add	sp,sp,-192
    800059ac:	fd06                	sd	ra,184(sp)
    800059ae:	f922                	sd	s0,176(sp)
    800059b0:	f526                	sd	s1,168(sp)
    800059b2:	f14a                	sd	s2,160(sp)
    800059b4:	ed4e                	sd	s3,152(sp)
    800059b6:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059b8:	f4c40593          	add	a1,s0,-180
    800059bc:	4505                	li	a0,1
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	38c080e7          	jalr	908(ra) # 80002d4a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059c6:	08000613          	li	a2,128
    800059ca:	f5040593          	add	a1,s0,-176
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	3ba080e7          	jalr	954(ra) # 80002d8a <argstr>
    800059d8:	87aa                	mv	a5,a0
    return -1;
    800059da:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059dc:	0a07c863          	bltz	a5,80005a8c <sys_open+0xe2>

  begin_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	a14080e7          	jalr	-1516(ra) # 800043f4 <begin_op>

  if(omode & O_CREATE){
    800059e8:	f4c42783          	lw	a5,-180(s0)
    800059ec:	2007f793          	and	a5,a5,512
    800059f0:	cbdd                	beqz	a5,80005aa6 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800059f2:	4681                	li	a3,0
    800059f4:	4601                	li	a2,0
    800059f6:	4589                	li	a1,2
    800059f8:	f5040513          	add	a0,s0,-176
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	97a080e7          	jalr	-1670(ra) # 80005376 <create>
    80005a04:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a06:	c951                	beqz	a0,80005a9a <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	478d                	li	a5,3
    80005a0e:	00f71763          	bne	a4,a5,80005a1c <sys_open+0x72>
    80005a12:	0464d703          	lhu	a4,70(s1)
    80005a16:	47a5                	li	a5,9
    80005a18:	0ce7ec63          	bltu	a5,a4,80005af0 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	de0080e7          	jalr	-544(ra) # 800047fc <filealloc>
    80005a24:	892a                	mv	s2,a0
    80005a26:	c56d                	beqz	a0,80005b10 <sys_open+0x166>
    80005a28:	00000097          	auipc	ra,0x0
    80005a2c:	90c080e7          	jalr	-1780(ra) # 80005334 <fdalloc>
    80005a30:	89aa                	mv	s3,a0
    80005a32:	0c054a63          	bltz	a0,80005b06 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a36:	04449703          	lh	a4,68(s1)
    80005a3a:	478d                	li	a5,3
    80005a3c:	0ef70563          	beq	a4,a5,80005b26 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a40:	4789                	li	a5,2
    80005a42:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005a46:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005a4a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005a4e:	f4c42783          	lw	a5,-180(s0)
    80005a52:	0017c713          	xor	a4,a5,1
    80005a56:	8b05                	and	a4,a4,1
    80005a58:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a5c:	0037f713          	and	a4,a5,3
    80005a60:	00e03733          	snez	a4,a4
    80005a64:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a68:	4007f793          	and	a5,a5,1024
    80005a6c:	c791                	beqz	a5,80005a78 <sys_open+0xce>
    80005a6e:	04449703          	lh	a4,68(s1)
    80005a72:	4789                	li	a5,2
    80005a74:	0cf70063          	beq	a4,a5,80005b34 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	096080e7          	jalr	150(ra) # 80003b10 <iunlock>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	9ec080e7          	jalr	-1556(ra) # 8000446e <end_op>

  return fd;
    80005a8a:	854e                	mv	a0,s3
}
    80005a8c:	70ea                	ld	ra,184(sp)
    80005a8e:	744a                	ld	s0,176(sp)
    80005a90:	74aa                	ld	s1,168(sp)
    80005a92:	790a                	ld	s2,160(sp)
    80005a94:	69ea                	ld	s3,152(sp)
    80005a96:	6129                	add	sp,sp,192
    80005a98:	8082                	ret
      end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	9d4080e7          	jalr	-1580(ra) # 8000446e <end_op>
      return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	b7e5                	j	80005a8c <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005aa6:	f5040513          	add	a0,s0,-176
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	74a080e7          	jalr	1866(ra) # 800041f4 <namei>
    80005ab2:	84aa                	mv	s1,a0
    80005ab4:	c905                	beqz	a0,80005ae4 <sys_open+0x13a>
    ilock(ip);
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	f98080e7          	jalr	-104(ra) # 80003a4e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005abe:	04449703          	lh	a4,68(s1)
    80005ac2:	4785                	li	a5,1
    80005ac4:	f4f712e3          	bne	a4,a5,80005a08 <sys_open+0x5e>
    80005ac8:	f4c42783          	lw	a5,-180(s0)
    80005acc:	dba1                	beqz	a5,80005a1c <sys_open+0x72>
      iunlockput(ip);
    80005ace:	8526                	mv	a0,s1
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	1e0080e7          	jalr	480(ra) # 80003cb0 <iunlockput>
      end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	996080e7          	jalr	-1642(ra) # 8000446e <end_op>
      return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	b76d                	j	80005a8c <sys_open+0xe2>
      end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	98a080e7          	jalr	-1654(ra) # 8000446e <end_op>
      return -1;
    80005aec:	557d                	li	a0,-1
    80005aee:	bf79                	j	80005a8c <sys_open+0xe2>
    iunlockput(ip);
    80005af0:	8526                	mv	a0,s1
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	1be080e7          	jalr	446(ra) # 80003cb0 <iunlockput>
    end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	974080e7          	jalr	-1676(ra) # 8000446e <end_op>
    return -1;
    80005b02:	557d                	li	a0,-1
    80005b04:	b761                	j	80005a8c <sys_open+0xe2>
      fileclose(f);
    80005b06:	854a                	mv	a0,s2
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	db0080e7          	jalr	-592(ra) # 800048b8 <fileclose>
    iunlockput(ip);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	19e080e7          	jalr	414(ra) # 80003cb0 <iunlockput>
    end_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	954080e7          	jalr	-1708(ra) # 8000446e <end_op>
    return -1;
    80005b22:	557d                	li	a0,-1
    80005b24:	b7a5                	j	80005a8c <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005b26:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005b2a:	04649783          	lh	a5,70(s1)
    80005b2e:	02f91223          	sh	a5,36(s2)
    80005b32:	bf21                	j	80005a4a <sys_open+0xa0>
    itrunc(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	026080e7          	jalr	38(ra) # 80003b5c <itrunc>
    80005b3e:	bf2d                	j	80005a78 <sys_open+0xce>

0000000080005b40 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b40:	7175                	add	sp,sp,-144
    80005b42:	e506                	sd	ra,136(sp)
    80005b44:	e122                	sd	s0,128(sp)
    80005b46:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	8ac080e7          	jalr	-1876(ra) # 800043f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b50:	08000613          	li	a2,128
    80005b54:	f7040593          	add	a1,s0,-144
    80005b58:	4501                	li	a0,0
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	230080e7          	jalr	560(ra) # 80002d8a <argstr>
    80005b62:	02054963          	bltz	a0,80005b94 <sys_mkdir+0x54>
    80005b66:	4681                	li	a3,0
    80005b68:	4601                	li	a2,0
    80005b6a:	4585                	li	a1,1
    80005b6c:	f7040513          	add	a0,s0,-144
    80005b70:	00000097          	auipc	ra,0x0
    80005b74:	806080e7          	jalr	-2042(ra) # 80005376 <create>
    80005b78:	cd11                	beqz	a0,80005b94 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	136080e7          	jalr	310(ra) # 80003cb0 <iunlockput>
  end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	8ec080e7          	jalr	-1812(ra) # 8000446e <end_op>
  return 0;
    80005b8a:	4501                	li	a0,0
}
    80005b8c:	60aa                	ld	ra,136(sp)
    80005b8e:	640a                	ld	s0,128(sp)
    80005b90:	6149                	add	sp,sp,144
    80005b92:	8082                	ret
    end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	8da080e7          	jalr	-1830(ra) # 8000446e <end_op>
    return -1;
    80005b9c:	557d                	li	a0,-1
    80005b9e:	b7fd                	j	80005b8c <sys_mkdir+0x4c>

0000000080005ba0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ba0:	7135                	add	sp,sp,-160
    80005ba2:	ed06                	sd	ra,152(sp)
    80005ba4:	e922                	sd	s0,144(sp)
    80005ba6:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	84c080e7          	jalr	-1972(ra) # 800043f4 <begin_op>
  argint(1, &major);
    80005bb0:	f6c40593          	add	a1,s0,-148
    80005bb4:	4505                	li	a0,1
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	194080e7          	jalr	404(ra) # 80002d4a <argint>
  argint(2, &minor);
    80005bbe:	f6840593          	add	a1,s0,-152
    80005bc2:	4509                	li	a0,2
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	186080e7          	jalr	390(ra) # 80002d4a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bcc:	08000613          	li	a2,128
    80005bd0:	f7040593          	add	a1,s0,-144
    80005bd4:	4501                	li	a0,0
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	1b4080e7          	jalr	436(ra) # 80002d8a <argstr>
    80005bde:	02054b63          	bltz	a0,80005c14 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005be2:	f6841683          	lh	a3,-152(s0)
    80005be6:	f6c41603          	lh	a2,-148(s0)
    80005bea:	458d                	li	a1,3
    80005bec:	f7040513          	add	a0,s0,-144
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	786080e7          	jalr	1926(ra) # 80005376 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bf8:	cd11                	beqz	a0,80005c14 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	0b6080e7          	jalr	182(ra) # 80003cb0 <iunlockput>
  end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	86c080e7          	jalr	-1940(ra) # 8000446e <end_op>
  return 0;
    80005c0a:	4501                	li	a0,0
}
    80005c0c:	60ea                	ld	ra,152(sp)
    80005c0e:	644a                	ld	s0,144(sp)
    80005c10:	610d                	add	sp,sp,160
    80005c12:	8082                	ret
    end_op();
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	85a080e7          	jalr	-1958(ra) # 8000446e <end_op>
    return -1;
    80005c1c:	557d                	li	a0,-1
    80005c1e:	b7fd                	j	80005c0c <sys_mknod+0x6c>

0000000080005c20 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c20:	7135                	add	sp,sp,-160
    80005c22:	ed06                	sd	ra,152(sp)
    80005c24:	e922                	sd	s0,144(sp)
    80005c26:	e526                	sd	s1,136(sp)
    80005c28:	e14a                	sd	s2,128(sp)
    80005c2a:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c2c:	ffffc097          	auipc	ra,0xffffc
    80005c30:	d7a080e7          	jalr	-646(ra) # 800019a6 <myproc>
    80005c34:	892a                	mv	s2,a0
  
  begin_op();
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	7be080e7          	jalr	1982(ra) # 800043f4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c3e:	08000613          	li	a2,128
    80005c42:	f6040593          	add	a1,s0,-160
    80005c46:	4501                	li	a0,0
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	142080e7          	jalr	322(ra) # 80002d8a <argstr>
    80005c50:	04054b63          	bltz	a0,80005ca6 <sys_chdir+0x86>
    80005c54:	f6040513          	add	a0,s0,-160
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	59c080e7          	jalr	1436(ra) # 800041f4 <namei>
    80005c60:	84aa                	mv	s1,a0
    80005c62:	c131                	beqz	a0,80005ca6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	dea080e7          	jalr	-534(ra) # 80003a4e <ilock>
  if(ip->type != T_DIR){
    80005c6c:	04449703          	lh	a4,68(s1)
    80005c70:	4785                	li	a5,1
    80005c72:	04f71063          	bne	a4,a5,80005cb2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	e98080e7          	jalr	-360(ra) # 80003b10 <iunlock>
  iput(p->cwd);
    80005c80:	15093503          	ld	a0,336(s2)
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	f84080e7          	jalr	-124(ra) # 80003c08 <iput>
  end_op();
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	7e2080e7          	jalr	2018(ra) # 8000446e <end_op>
  p->cwd = ip;
    80005c94:	14993823          	sd	s1,336(s2)
  return 0;
    80005c98:	4501                	li	a0,0
}
    80005c9a:	60ea                	ld	ra,152(sp)
    80005c9c:	644a                	ld	s0,144(sp)
    80005c9e:	64aa                	ld	s1,136(sp)
    80005ca0:	690a                	ld	s2,128(sp)
    80005ca2:	610d                	add	sp,sp,160
    80005ca4:	8082                	ret
    end_op();
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	7c8080e7          	jalr	1992(ra) # 8000446e <end_op>
    return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	b7ed                	j	80005c9a <sys_chdir+0x7a>
    iunlockput(ip);
    80005cb2:	8526                	mv	a0,s1
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	ffc080e7          	jalr	-4(ra) # 80003cb0 <iunlockput>
    end_op();
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	7b2080e7          	jalr	1970(ra) # 8000446e <end_op>
    return -1;
    80005cc4:	557d                	li	a0,-1
    80005cc6:	bfd1                	j	80005c9a <sys_chdir+0x7a>

0000000080005cc8 <sys_exec>:

uint64
sys_exec(void)
{
    80005cc8:	7121                	add	sp,sp,-448
    80005cca:	ff06                	sd	ra,440(sp)
    80005ccc:	fb22                	sd	s0,432(sp)
    80005cce:	f726                	sd	s1,424(sp)
    80005cd0:	f34a                	sd	s2,416(sp)
    80005cd2:	ef4e                	sd	s3,408(sp)
    80005cd4:	eb52                	sd	s4,400(sp)
    80005cd6:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cd8:	e4840593          	add	a1,s0,-440
    80005cdc:	4505                	li	a0,1
    80005cde:	ffffd097          	auipc	ra,0xffffd
    80005ce2:	08c080e7          	jalr	140(ra) # 80002d6a <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ce6:	08000613          	li	a2,128
    80005cea:	f5040593          	add	a1,s0,-176
    80005cee:	4501                	li	a0,0
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	09a080e7          	jalr	154(ra) # 80002d8a <argstr>
    80005cf8:	87aa                	mv	a5,a0
    return -1;
    80005cfa:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cfc:	0c07c263          	bltz	a5,80005dc0 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005d00:	10000613          	li	a2,256
    80005d04:	4581                	li	a1,0
    80005d06:	e5040513          	add	a0,s0,-432
    80005d0a:	ffffb097          	auipc	ra,0xffffb
    80005d0e:	fc4080e7          	jalr	-60(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d12:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005d16:	89a6                	mv	s3,s1
    80005d18:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d1a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d1e:	00391513          	sll	a0,s2,0x3
    80005d22:	e4040593          	add	a1,s0,-448
    80005d26:	e4843783          	ld	a5,-440(s0)
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	f80080e7          	jalr	-128(ra) # 80002cac <fetchaddr>
    80005d34:	02054a63          	bltz	a0,80005d68 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005d38:	e4043783          	ld	a5,-448(s0)
    80005d3c:	c3b9                	beqz	a5,80005d82 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d3e:	ffffb097          	auipc	ra,0xffffb
    80005d42:	da4080e7          	jalr	-604(ra) # 80000ae2 <kalloc>
    80005d46:	85aa                	mv	a1,a0
    80005d48:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d4c:	cd11                	beqz	a0,80005d68 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d4e:	6605                	lui	a2,0x1
    80005d50:	e4043503          	ld	a0,-448(s0)
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	faa080e7          	jalr	-86(ra) # 80002cfe <fetchstr>
    80005d5c:	00054663          	bltz	a0,80005d68 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005d60:	0905                	add	s2,s2,1
    80005d62:	09a1                	add	s3,s3,8
    80005d64:	fb491de3          	bne	s2,s4,80005d1e <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d68:	f5040913          	add	s2,s0,-176
    80005d6c:	6088                	ld	a0,0(s1)
    80005d6e:	c921                	beqz	a0,80005dbe <sys_exec+0xf6>
    kfree(argv[i]);
    80005d70:	ffffb097          	auipc	ra,0xffffb
    80005d74:	c74080e7          	jalr	-908(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d78:	04a1                	add	s1,s1,8
    80005d7a:	ff2499e3          	bne	s1,s2,80005d6c <sys_exec+0xa4>
  return -1;
    80005d7e:	557d                	li	a0,-1
    80005d80:	a081                	j	80005dc0 <sys_exec+0xf8>
      argv[i] = 0;
    80005d82:	0009079b          	sext.w	a5,s2
    80005d86:	078e                	sll	a5,a5,0x3
    80005d88:	fd078793          	add	a5,a5,-48
    80005d8c:	97a2                	add	a5,a5,s0
    80005d8e:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005d92:	e5040593          	add	a1,s0,-432
    80005d96:	f5040513          	add	a0,s0,-176
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	194080e7          	jalr	404(ra) # 80004f2e <exec>
    80005da2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da4:	f5040993          	add	s3,s0,-176
    80005da8:	6088                	ld	a0,0(s1)
    80005daa:	c901                	beqz	a0,80005dba <sys_exec+0xf2>
    kfree(argv[i]);
    80005dac:	ffffb097          	auipc	ra,0xffffb
    80005db0:	c38080e7          	jalr	-968(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db4:	04a1                	add	s1,s1,8
    80005db6:	ff3499e3          	bne	s1,s3,80005da8 <sys_exec+0xe0>
  return ret;
    80005dba:	854a                	mv	a0,s2
    80005dbc:	a011                	j	80005dc0 <sys_exec+0xf8>
  return -1;
    80005dbe:	557d                	li	a0,-1
}
    80005dc0:	70fa                	ld	ra,440(sp)
    80005dc2:	745a                	ld	s0,432(sp)
    80005dc4:	74ba                	ld	s1,424(sp)
    80005dc6:	791a                	ld	s2,416(sp)
    80005dc8:	69fa                	ld	s3,408(sp)
    80005dca:	6a5a                	ld	s4,400(sp)
    80005dcc:	6139                	add	sp,sp,448
    80005dce:	8082                	ret

0000000080005dd0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dd0:	7139                	add	sp,sp,-64
    80005dd2:	fc06                	sd	ra,56(sp)
    80005dd4:	f822                	sd	s0,48(sp)
    80005dd6:	f426                	sd	s1,40(sp)
    80005dd8:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dda:	ffffc097          	auipc	ra,0xffffc
    80005dde:	bcc080e7          	jalr	-1076(ra) # 800019a6 <myproc>
    80005de2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005de4:	fd840593          	add	a1,s0,-40
    80005de8:	4501                	li	a0,0
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	f80080e7          	jalr	-128(ra) # 80002d6a <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005df2:	fc840593          	add	a1,s0,-56
    80005df6:	fd040513          	add	a0,s0,-48
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	dea080e7          	jalr	-534(ra) # 80004be4 <pipealloc>
    return -1;
    80005e02:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e04:	0c054463          	bltz	a0,80005ecc <sys_pipe+0xfc>
  fd0 = -1;
    80005e08:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e0c:	fd043503          	ld	a0,-48(s0)
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	524080e7          	jalr	1316(ra) # 80005334 <fdalloc>
    80005e18:	fca42223          	sw	a0,-60(s0)
    80005e1c:	08054b63          	bltz	a0,80005eb2 <sys_pipe+0xe2>
    80005e20:	fc843503          	ld	a0,-56(s0)
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	510080e7          	jalr	1296(ra) # 80005334 <fdalloc>
    80005e2c:	fca42023          	sw	a0,-64(s0)
    80005e30:	06054863          	bltz	a0,80005ea0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e34:	4691                	li	a3,4
    80005e36:	fc440613          	add	a2,s0,-60
    80005e3a:	fd843583          	ld	a1,-40(s0)
    80005e3e:	68a8                	ld	a0,80(s1)
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	826080e7          	jalr	-2010(ra) # 80001666 <copyout>
    80005e48:	02054063          	bltz	a0,80005e68 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e4c:	4691                	li	a3,4
    80005e4e:	fc040613          	add	a2,s0,-64
    80005e52:	fd843583          	ld	a1,-40(s0)
    80005e56:	0591                	add	a1,a1,4
    80005e58:	68a8                	ld	a0,80(s1)
    80005e5a:	ffffc097          	auipc	ra,0xffffc
    80005e5e:	80c080e7          	jalr	-2036(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e62:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e64:	06055463          	bgez	a0,80005ecc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e68:	fc442783          	lw	a5,-60(s0)
    80005e6c:	07e9                	add	a5,a5,26
    80005e6e:	078e                	sll	a5,a5,0x3
    80005e70:	97a6                	add	a5,a5,s1
    80005e72:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e76:	fc042783          	lw	a5,-64(s0)
    80005e7a:	07e9                	add	a5,a5,26
    80005e7c:	078e                	sll	a5,a5,0x3
    80005e7e:	94be                	add	s1,s1,a5
    80005e80:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e84:	fd043503          	ld	a0,-48(s0)
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	a30080e7          	jalr	-1488(ra) # 800048b8 <fileclose>
    fileclose(wf);
    80005e90:	fc843503          	ld	a0,-56(s0)
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	a24080e7          	jalr	-1500(ra) # 800048b8 <fileclose>
    return -1;
    80005e9c:	57fd                	li	a5,-1
    80005e9e:	a03d                	j	80005ecc <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ea0:	fc442783          	lw	a5,-60(s0)
    80005ea4:	0007c763          	bltz	a5,80005eb2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ea8:	07e9                	add	a5,a5,26
    80005eaa:	078e                	sll	a5,a5,0x3
    80005eac:	97a6                	add	a5,a5,s1
    80005eae:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005eb2:	fd043503          	ld	a0,-48(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	a02080e7          	jalr	-1534(ra) # 800048b8 <fileclose>
    fileclose(wf);
    80005ebe:	fc843503          	ld	a0,-56(s0)
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	9f6080e7          	jalr	-1546(ra) # 800048b8 <fileclose>
    return -1;
    80005eca:	57fd                	li	a5,-1
}
    80005ecc:	853e                	mv	a0,a5
    80005ece:	70e2                	ld	ra,56(sp)
    80005ed0:	7442                	ld	s0,48(sp)
    80005ed2:	74a2                	ld	s1,40(sp)
    80005ed4:	6121                	add	sp,sp,64
    80005ed6:	8082                	ret
	...

0000000080005ee0 <kernelvec>:
    80005ee0:	7111                	add	sp,sp,-256
    80005ee2:	e006                	sd	ra,0(sp)
    80005ee4:	e40a                	sd	sp,8(sp)
    80005ee6:	e80e                	sd	gp,16(sp)
    80005ee8:	ec12                	sd	tp,24(sp)
    80005eea:	f016                	sd	t0,32(sp)
    80005eec:	f41a                	sd	t1,40(sp)
    80005eee:	f81e                	sd	t2,48(sp)
    80005ef0:	fc22                	sd	s0,56(sp)
    80005ef2:	e0a6                	sd	s1,64(sp)
    80005ef4:	e4aa                	sd	a0,72(sp)
    80005ef6:	e8ae                	sd	a1,80(sp)
    80005ef8:	ecb2                	sd	a2,88(sp)
    80005efa:	f0b6                	sd	a3,96(sp)
    80005efc:	f4ba                	sd	a4,104(sp)
    80005efe:	f8be                	sd	a5,112(sp)
    80005f00:	fcc2                	sd	a6,120(sp)
    80005f02:	e146                	sd	a7,128(sp)
    80005f04:	e54a                	sd	s2,136(sp)
    80005f06:	e94e                	sd	s3,144(sp)
    80005f08:	ed52                	sd	s4,152(sp)
    80005f0a:	f156                	sd	s5,160(sp)
    80005f0c:	f55a                	sd	s6,168(sp)
    80005f0e:	f95e                	sd	s7,176(sp)
    80005f10:	fd62                	sd	s8,184(sp)
    80005f12:	e1e6                	sd	s9,192(sp)
    80005f14:	e5ea                	sd	s10,200(sp)
    80005f16:	e9ee                	sd	s11,208(sp)
    80005f18:	edf2                	sd	t3,216(sp)
    80005f1a:	f1f6                	sd	t4,224(sp)
    80005f1c:	f5fa                	sd	t5,232(sp)
    80005f1e:	f9fe                	sd	t6,240(sp)
    80005f20:	c59fc0ef          	jal	80002b78 <kerneltrap>
    80005f24:	6082                	ld	ra,0(sp)
    80005f26:	6122                	ld	sp,8(sp)
    80005f28:	61c2                	ld	gp,16(sp)
    80005f2a:	7282                	ld	t0,32(sp)
    80005f2c:	7322                	ld	t1,40(sp)
    80005f2e:	73c2                	ld	t2,48(sp)
    80005f30:	7462                	ld	s0,56(sp)
    80005f32:	6486                	ld	s1,64(sp)
    80005f34:	6526                	ld	a0,72(sp)
    80005f36:	65c6                	ld	a1,80(sp)
    80005f38:	6666                	ld	a2,88(sp)
    80005f3a:	7686                	ld	a3,96(sp)
    80005f3c:	7726                	ld	a4,104(sp)
    80005f3e:	77c6                	ld	a5,112(sp)
    80005f40:	7866                	ld	a6,120(sp)
    80005f42:	688a                	ld	a7,128(sp)
    80005f44:	692a                	ld	s2,136(sp)
    80005f46:	69ca                	ld	s3,144(sp)
    80005f48:	6a6a                	ld	s4,152(sp)
    80005f4a:	7a8a                	ld	s5,160(sp)
    80005f4c:	7b2a                	ld	s6,168(sp)
    80005f4e:	7bca                	ld	s7,176(sp)
    80005f50:	7c6a                	ld	s8,184(sp)
    80005f52:	6c8e                	ld	s9,192(sp)
    80005f54:	6d2e                	ld	s10,200(sp)
    80005f56:	6dce                	ld	s11,208(sp)
    80005f58:	6e6e                	ld	t3,216(sp)
    80005f5a:	7e8e                	ld	t4,224(sp)
    80005f5c:	7f2e                	ld	t5,232(sp)
    80005f5e:	7fce                	ld	t6,240(sp)
    80005f60:	6111                	add	sp,sp,256
    80005f62:	10200073          	sret
    80005f66:	00000013          	nop
    80005f6a:	00000013          	nop
    80005f6e:	0001                	nop

0000000080005f70 <timervec>:
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	e10c                	sd	a1,0(a0)
    80005f76:	e510                	sd	a2,8(a0)
    80005f78:	e914                	sd	a3,16(a0)
    80005f7a:	6d0c                	ld	a1,24(a0)
    80005f7c:	7110                	ld	a2,32(a0)
    80005f7e:	6194                	ld	a3,0(a1)
    80005f80:	96b2                	add	a3,a3,a2
    80005f82:	e194                	sd	a3,0(a1)
    80005f84:	4589                	li	a1,2
    80005f86:	14459073          	csrw	sip,a1
    80005f8a:	6914                	ld	a3,16(a0)
    80005f8c:	6510                	ld	a2,8(a0)
    80005f8e:	610c                	ld	a1,0(a0)
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	30200073          	mret
	...

0000000080005f9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f9a:	1141                	add	sp,sp,-16
    80005f9c:	e422                	sd	s0,8(sp)
    80005f9e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fa0:	0c0007b7          	lui	a5,0xc000
    80005fa4:	4705                	li	a4,1
    80005fa6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fa8:	c3d8                	sw	a4,4(a5)
}
    80005faa:	6422                	ld	s0,8(sp)
    80005fac:	0141                	add	sp,sp,16
    80005fae:	8082                	ret

0000000080005fb0 <plicinithart>:

void
plicinithart(void)
{
    80005fb0:	1141                	add	sp,sp,-16
    80005fb2:	e406                	sd	ra,8(sp)
    80005fb4:	e022                	sd	s0,0(sp)
    80005fb6:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	9c2080e7          	jalr	-1598(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fc0:	0085171b          	sllw	a4,a0,0x8
    80005fc4:	0c0027b7          	lui	a5,0xc002
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	40200713          	li	a4,1026
    80005fce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fd2:	00d5151b          	sllw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	97aa                	add	a5,a5,a0
    80005fdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fe0:	60a2                	ld	ra,8(sp)
    80005fe2:	6402                	ld	s0,0(sp)
    80005fe4:	0141                	add	sp,sp,16
    80005fe6:	8082                	ret

0000000080005fe8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fe8:	1141                	add	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005ff0:	ffffc097          	auipc	ra,0xffffc
    80005ff4:	98a080e7          	jalr	-1654(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ff8:	00d5151b          	sllw	a0,a0,0xd
    80005ffc:	0c2017b7          	lui	a5,0xc201
    80006000:	97aa                	add	a5,a5,a0
  return irq;
}
    80006002:	43c8                	lw	a0,4(a5)
    80006004:	60a2                	ld	ra,8(sp)
    80006006:	6402                	ld	s0,0(sp)
    80006008:	0141                	add	sp,sp,16
    8000600a:	8082                	ret

000000008000600c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000600c:	1101                	add	sp,sp,-32
    8000600e:	ec06                	sd	ra,24(sp)
    80006010:	e822                	sd	s0,16(sp)
    80006012:	e426                	sd	s1,8(sp)
    80006014:	1000                	add	s0,sp,32
    80006016:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	962080e7          	jalr	-1694(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006020:	00d5151b          	sllw	a0,a0,0xd
    80006024:	0c2017b7          	lui	a5,0xc201
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	c3c4                	sw	s1,4(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	add	sp,sp,32
    80006034:	8082                	ret

0000000080006036 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006036:	1141                	add	sp,sp,-16
    80006038:	e406                	sd	ra,8(sp)
    8000603a:	e022                	sd	s0,0(sp)
    8000603c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000603e:	479d                	li	a5,7
    80006040:	04a7cc63          	blt	a5,a0,80006098 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006044:	0001e797          	auipc	a5,0x1e
    80006048:	62c78793          	add	a5,a5,1580 # 80024670 <disk>
    8000604c:	97aa                	add	a5,a5,a0
    8000604e:	0187c783          	lbu	a5,24(a5)
    80006052:	ebb9                	bnez	a5,800060a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006054:	00451693          	sll	a3,a0,0x4
    80006058:	0001e797          	auipc	a5,0x1e
    8000605c:	61878793          	add	a5,a5,1560 # 80024670 <disk>
    80006060:	6398                	ld	a4,0(a5)
    80006062:	9736                	add	a4,a4,a3
    80006064:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006068:	6398                	ld	a4,0(a5)
    8000606a:	9736                	add	a4,a4,a3
    8000606c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006070:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006074:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006078:	97aa                	add	a5,a5,a0
    8000607a:	4705                	li	a4,1
    8000607c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006080:	0001e517          	auipc	a0,0x1e
    80006084:	60850513          	add	a0,a0,1544 # 80024688 <disk+0x18>
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	060080e7          	jalr	96(ra) # 800020e8 <wakeup>
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	add	sp,sp,16
    80006096:	8082                	ret
    panic("free_desc 1");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6f050513          	add	a0,a0,1776 # 80008788 <syscalls+0x310>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	49c080e7          	jalr	1180(ra) # 8000053c <panic>
    panic("free_desc 2");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6f050513          	add	a0,a0,1776 # 80008798 <syscalls+0x320>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	48c080e7          	jalr	1164(ra) # 8000053c <panic>

00000000800060b8 <virtio_disk_init>:
{
    800060b8:	1101                	add	sp,sp,-32
    800060ba:	ec06                	sd	ra,24(sp)
    800060bc:	e822                	sd	s0,16(sp)
    800060be:	e426                	sd	s1,8(sp)
    800060c0:	e04a                	sd	s2,0(sp)
    800060c2:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060c4:	00002597          	auipc	a1,0x2
    800060c8:	6e458593          	add	a1,a1,1764 # 800087a8 <syscalls+0x330>
    800060cc:	0001e517          	auipc	a0,0x1e
    800060d0:	6cc50513          	add	a0,a0,1740 # 80024798 <disk+0x128>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	a6e080e7          	jalr	-1426(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	4398                	lw	a4,0(a5)
    800060e2:	2701                	sext.w	a4,a4
    800060e4:	747277b7          	lui	a5,0x74727
    800060e8:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ec:	14f71b63          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f0:	100017b7          	lui	a5,0x10001
    800060f4:	43dc                	lw	a5,4(a5)
    800060f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f8:	4709                	li	a4,2
    800060fa:	14e79463          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	479c                	lw	a5,8(a5)
    80006104:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006106:	12e79e63          	bne	a5,a4,80006242 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000610a:	100017b7          	lui	a5,0x10001
    8000610e:	47d8                	lw	a4,12(a5)
    80006110:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006112:	554d47b7          	lui	a5,0x554d4
    80006116:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000611a:	12f71463          	bne	a4,a5,80006242 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006126:	4705                	li	a4,1
    80006128:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612a:	470d                	li	a4,3
    8000612c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000612e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006130:	c7ffe6b7          	lui	a3,0xc7ffe
    80006134:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9faf>
    80006138:	8f75                	and	a4,a4,a3
    8000613a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613c:	472d                	li	a4,11
    8000613e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006140:	5bbc                	lw	a5,112(a5)
    80006142:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006146:	8ba1                	and	a5,a5,8
    80006148:	10078563          	beqz	a5,80006252 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006154:	43fc                	lw	a5,68(a5)
    80006156:	2781                	sext.w	a5,a5
    80006158:	10079563          	bnez	a5,80006262 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000615c:	100017b7          	lui	a5,0x10001
    80006160:	5bdc                	lw	a5,52(a5)
    80006162:	2781                	sext.w	a5,a5
  if(max == 0)
    80006164:	10078763          	beqz	a5,80006272 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006168:	471d                	li	a4,7
    8000616a:	10f77c63          	bgeu	a4,a5,80006282 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	974080e7          	jalr	-1676(ra) # 80000ae2 <kalloc>
    80006176:	0001e497          	auipc	s1,0x1e
    8000617a:	4fa48493          	add	s1,s1,1274 # 80024670 <disk>
    8000617e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	962080e7          	jalr	-1694(ra) # 80000ae2 <kalloc>
    80006188:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	958080e7          	jalr	-1704(ra) # 80000ae2 <kalloc>
    80006192:	87aa                	mv	a5,a0
    80006194:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006196:	6088                	ld	a0,0(s1)
    80006198:	cd6d                	beqz	a0,80006292 <virtio_disk_init+0x1da>
    8000619a:	0001e717          	auipc	a4,0x1e
    8000619e:	4de73703          	ld	a4,1246(a4) # 80024678 <disk+0x8>
    800061a2:	cb65                	beqz	a4,80006292 <virtio_disk_init+0x1da>
    800061a4:	c7fd                	beqz	a5,80006292 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800061a6:	6605                	lui	a2,0x1
    800061a8:	4581                	li	a1,0
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	b24080e7          	jalr	-1244(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    800061b2:	0001e497          	auipc	s1,0x1e
    800061b6:	4be48493          	add	s1,s1,1214 # 80024670 <disk>
    800061ba:	6605                	lui	a2,0x1
    800061bc:	4581                	li	a1,0
    800061be:	6488                	ld	a0,8(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b0e080e7          	jalr	-1266(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    800061c8:	6605                	lui	a2,0x1
    800061ca:	4581                	li	a1,0
    800061cc:	6888                	ld	a0,16(s1)
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	b00080e7          	jalr	-1280(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061d6:	100017b7          	lui	a5,0x10001
    800061da:	4721                	li	a4,8
    800061dc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061de:	4098                	lw	a4,0(s1)
    800061e0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061e4:	40d8                	lw	a4,4(s1)
    800061e6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ea:	6498                	ld	a4,8(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061f4:	9701                	sra	a4,a4,0x20
    800061f6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061fa:	6898                	ld	a4,16(s1)
    800061fc:	0007069b          	sext.w	a3,a4
    80006200:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006204:	9701                	sra	a4,a4,0x20
    80006206:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000620a:	4705                	li	a4,1
    8000620c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000620e:	00e48c23          	sb	a4,24(s1)
    80006212:	00e48ca3          	sb	a4,25(s1)
    80006216:	00e48d23          	sb	a4,26(s1)
    8000621a:	00e48da3          	sb	a4,27(s1)
    8000621e:	00e48e23          	sb	a4,28(s1)
    80006222:	00e48ea3          	sb	a4,29(s1)
    80006226:	00e48f23          	sb	a4,30(s1)
    8000622a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000622e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006232:	0727a823          	sw	s2,112(a5)
}
    80006236:	60e2                	ld	ra,24(sp)
    80006238:	6442                	ld	s0,16(sp)
    8000623a:	64a2                	ld	s1,8(sp)
    8000623c:	6902                	ld	s2,0(sp)
    8000623e:	6105                	add	sp,sp,32
    80006240:	8082                	ret
    panic("could not find virtio disk");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	57650513          	add	a0,a0,1398 # 800087b8 <syscalls+0x340>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f2080e7          	jalr	754(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	58650513          	add	a0,a0,1414 # 800087d8 <syscalls+0x360>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e2080e7          	jalr	738(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	59650513          	add	a0,a0,1430 # 800087f8 <syscalls+0x380>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d2080e7          	jalr	722(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	5a650513          	add	a0,a0,1446 # 80008818 <syscalls+0x3a0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c2080e7          	jalr	706(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	5b650513          	add	a0,a0,1462 # 80008838 <syscalls+0x3c0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b2080e7          	jalr	690(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	5c650513          	add	a0,a0,1478 # 80008858 <syscalls+0x3e0>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a2080e7          	jalr	674(ra) # 8000053c <panic>

00000000800062a2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062a2:	7159                	add	sp,sp,-112
    800062a4:	f486                	sd	ra,104(sp)
    800062a6:	f0a2                	sd	s0,96(sp)
    800062a8:	eca6                	sd	s1,88(sp)
    800062aa:	e8ca                	sd	s2,80(sp)
    800062ac:	e4ce                	sd	s3,72(sp)
    800062ae:	e0d2                	sd	s4,64(sp)
    800062b0:	fc56                	sd	s5,56(sp)
    800062b2:	f85a                	sd	s6,48(sp)
    800062b4:	f45e                	sd	s7,40(sp)
    800062b6:	f062                	sd	s8,32(sp)
    800062b8:	ec66                	sd	s9,24(sp)
    800062ba:	e86a                	sd	s10,16(sp)
    800062bc:	1880                	add	s0,sp,112
    800062be:	8a2a                	mv	s4,a0
    800062c0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062c2:	00c52c83          	lw	s9,12(a0)
    800062c6:	001c9c9b          	sllw	s9,s9,0x1
    800062ca:	1c82                	sll	s9,s9,0x20
    800062cc:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062d0:	0001e517          	auipc	a0,0x1e
    800062d4:	4c850513          	add	a0,a0,1224 # 80024798 <disk+0x128>
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	8fa080e7          	jalr	-1798(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    800062e0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800062e2:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062e4:	0001eb17          	auipc	s6,0x1e
    800062e8:	38cb0b13          	add	s6,s6,908 # 80024670 <disk>
  for(int i = 0; i < 3; i++){
    800062ec:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062ee:	0001ec17          	auipc	s8,0x1e
    800062f2:	4aac0c13          	add	s8,s8,1194 # 80024798 <disk+0x128>
    800062f6:	a095                	j	8000635a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062f8:	00fb0733          	add	a4,s6,a5
    800062fc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006300:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006302:	0207c563          	bltz	a5,8000632c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006306:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006308:	0591                	add	a1,a1,4
    8000630a:	05560d63          	beq	a2,s5,80006364 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000630e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006310:	0001e717          	auipc	a4,0x1e
    80006314:	36070713          	add	a4,a4,864 # 80024670 <disk>
    80006318:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000631a:	01874683          	lbu	a3,24(a4)
    8000631e:	fee9                	bnez	a3,800062f8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006320:	2785                	addw	a5,a5,1
    80006322:	0705                	add	a4,a4,1
    80006324:	fe979be3          	bne	a5,s1,8000631a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006328:	57fd                	li	a5,-1
    8000632a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000632c:	00c05e63          	blez	a2,80006348 <virtio_disk_rw+0xa6>
    80006330:	060a                	sll	a2,a2,0x2
    80006332:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006336:	0009a503          	lw	a0,0(s3)
    8000633a:	00000097          	auipc	ra,0x0
    8000633e:	cfc080e7          	jalr	-772(ra) # 80006036 <free_desc>
      for(int j = 0; j < i; j++)
    80006342:	0991                	add	s3,s3,4
    80006344:	ffa999e3          	bne	s3,s10,80006336 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006348:	85e2                	mv	a1,s8
    8000634a:	0001e517          	auipc	a0,0x1e
    8000634e:	33e50513          	add	a0,a0,830 # 80024688 <disk+0x18>
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	d32080e7          	jalr	-718(ra) # 80002084 <sleep>
  for(int i = 0; i < 3; i++){
    8000635a:	f9040993          	add	s3,s0,-112
{
    8000635e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006360:	864a                	mv	a2,s2
    80006362:	b775                	j	8000630e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006364:	f9042503          	lw	a0,-112(s0)
    80006368:	00a50713          	add	a4,a0,10
    8000636c:	0712                	sll	a4,a4,0x4

  if(write)
    8000636e:	0001e797          	auipc	a5,0x1e
    80006372:	30278793          	add	a5,a5,770 # 80024670 <disk>
    80006376:	00e786b3          	add	a3,a5,a4
    8000637a:	01703633          	snez	a2,s7
    8000637e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006380:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006384:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006388:	f6070613          	add	a2,a4,-160
    8000638c:	6394                	ld	a3,0(a5)
    8000638e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006390:	00870593          	add	a1,a4,8
    80006394:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006396:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006398:	0007b803          	ld	a6,0(a5)
    8000639c:	9642                	add	a2,a2,a6
    8000639e:	46c1                	li	a3,16
    800063a0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063a2:	4585                	li	a1,1
    800063a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800063a8:	f9442683          	lw	a3,-108(s0)
    800063ac:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0692                	sll	a3,a3,0x4
    800063b2:	9836                	add	a6,a6,a3
    800063b4:	058a0613          	add	a2,s4,88
    800063b8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063bc:	0007b803          	ld	a6,0(a5)
    800063c0:	96c2                	add	a3,a3,a6
    800063c2:	40000613          	li	a2,1024
    800063c6:	c690                	sw	a2,8(a3)
  if(write)
    800063c8:	001bb613          	seqz	a2,s7
    800063cc:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063d0:	00166613          	or	a2,a2,1
    800063d4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063d8:	f9842603          	lw	a2,-104(s0)
    800063dc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063e0:	00250693          	add	a3,a0,2
    800063e4:	0692                	sll	a3,a3,0x4
    800063e6:	96be                	add	a3,a3,a5
    800063e8:	58fd                	li	a7,-1
    800063ea:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ee:	0612                	sll	a2,a2,0x4
    800063f0:	9832                	add	a6,a6,a2
    800063f2:	f9070713          	add	a4,a4,-112
    800063f6:	973e                	add	a4,a4,a5
    800063f8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063fc:	6398                	ld	a4,0(a5)
    800063fe:	9732                	add	a4,a4,a2
    80006400:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006402:	4609                	li	a2,2
    80006404:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006408:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000640c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006410:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006414:	6794                	ld	a3,8(a5)
    80006416:	0026d703          	lhu	a4,2(a3)
    8000641a:	8b1d                	and	a4,a4,7
    8000641c:	0706                	sll	a4,a4,0x1
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006428:	6798                	ld	a4,8(a5)
    8000642a:	00275783          	lhu	a5,2(a4)
    8000642e:	2785                	addw	a5,a5,1
    80006430:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006434:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006440:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006444:	0001e917          	auipc	s2,0x1e
    80006448:	35490913          	add	s2,s2,852 # 80024798 <disk+0x128>
  while(b->disk == 1) {
    8000644c:	4485                	li	s1,1
    8000644e:	00b79c63          	bne	a5,a1,80006466 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006452:	85ca                	mv	a1,s2
    80006454:	8552                	mv	a0,s4
    80006456:	ffffc097          	auipc	ra,0xffffc
    8000645a:	c2e080e7          	jalr	-978(ra) # 80002084 <sleep>
  while(b->disk == 1) {
    8000645e:	004a2783          	lw	a5,4(s4)
    80006462:	fe9788e3          	beq	a5,s1,80006452 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006466:	f9042903          	lw	s2,-112(s0)
    8000646a:	00290713          	add	a4,s2,2
    8000646e:	0712                	sll	a4,a4,0x4
    80006470:	0001e797          	auipc	a5,0x1e
    80006474:	20078793          	add	a5,a5,512 # 80024670 <disk>
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000647e:	0001e997          	auipc	s3,0x1e
    80006482:	1f298993          	add	s3,s3,498 # 80024670 <disk>
    80006486:	00491713          	sll	a4,s2,0x4
    8000648a:	0009b783          	ld	a5,0(s3)
    8000648e:	97ba                	add	a5,a5,a4
    80006490:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006494:	854a                	mv	a0,s2
    80006496:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	b9c080e7          	jalr	-1124(ra) # 80006036 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064a2:	8885                	and	s1,s1,1
    800064a4:	f0ed                	bnez	s1,80006486 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064a6:	0001e517          	auipc	a0,0x1e
    800064aa:	2f250513          	add	a0,a0,754 # 80024798 <disk+0x128>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	7d8080e7          	jalr	2008(ra) # 80000c86 <release>
}
    800064b6:	70a6                	ld	ra,104(sp)
    800064b8:	7406                	ld	s0,96(sp)
    800064ba:	64e6                	ld	s1,88(sp)
    800064bc:	6946                	ld	s2,80(sp)
    800064be:	69a6                	ld	s3,72(sp)
    800064c0:	6a06                	ld	s4,64(sp)
    800064c2:	7ae2                	ld	s5,56(sp)
    800064c4:	7b42                	ld	s6,48(sp)
    800064c6:	7ba2                	ld	s7,40(sp)
    800064c8:	7c02                	ld	s8,32(sp)
    800064ca:	6ce2                	ld	s9,24(sp)
    800064cc:	6d42                	ld	s10,16(sp)
    800064ce:	6165                	add	sp,sp,112
    800064d0:	8082                	ret

00000000800064d2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064d2:	1101                	add	sp,sp,-32
    800064d4:	ec06                	sd	ra,24(sp)
    800064d6:	e822                	sd	s0,16(sp)
    800064d8:	e426                	sd	s1,8(sp)
    800064da:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064dc:	0001e497          	auipc	s1,0x1e
    800064e0:	19448493          	add	s1,s1,404 # 80024670 <disk>
    800064e4:	0001e517          	auipc	a0,0x1e
    800064e8:	2b450513          	add	a0,a0,692 # 80024798 <disk+0x128>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	6e6080e7          	jalr	1766(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064f4:	10001737          	lui	a4,0x10001
    800064f8:	533c                	lw	a5,96(a4)
    800064fa:	8b8d                	and	a5,a5,3
    800064fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006502:	689c                	ld	a5,16(s1)
    80006504:	0204d703          	lhu	a4,32(s1)
    80006508:	0027d783          	lhu	a5,2(a5)
    8000650c:	04f70863          	beq	a4,a5,8000655c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006510:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006514:	6898                	ld	a4,16(s1)
    80006516:	0204d783          	lhu	a5,32(s1)
    8000651a:	8b9d                	and	a5,a5,7
    8000651c:	078e                	sll	a5,a5,0x3
    8000651e:	97ba                	add	a5,a5,a4
    80006520:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006522:	00278713          	add	a4,a5,2
    80006526:	0712                	sll	a4,a4,0x4
    80006528:	9726                	add	a4,a4,s1
    8000652a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000652e:	e721                	bnez	a4,80006576 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006530:	0789                	add	a5,a5,2
    80006532:	0792                	sll	a5,a5,0x4
    80006534:	97a6                	add	a5,a5,s1
    80006536:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006538:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000653c:	ffffc097          	auipc	ra,0xffffc
    80006540:	bac080e7          	jalr	-1108(ra) # 800020e8 <wakeup>

    disk.used_idx += 1;
    80006544:	0204d783          	lhu	a5,32(s1)
    80006548:	2785                	addw	a5,a5,1
    8000654a:	17c2                	sll	a5,a5,0x30
    8000654c:	93c1                	srl	a5,a5,0x30
    8000654e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006552:	6898                	ld	a4,16(s1)
    80006554:	00275703          	lhu	a4,2(a4)
    80006558:	faf71ce3          	bne	a4,a5,80006510 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000655c:	0001e517          	auipc	a0,0x1e
    80006560:	23c50513          	add	a0,a0,572 # 80024798 <disk+0x128>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	722080e7          	jalr	1826(ra) # 80000c86 <release>
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6105                	add	sp,sp,32
    80006574:	8082                	ret
      panic("virtio_disk_intr status");
    80006576:	00002517          	auipc	a0,0x2
    8000657a:	2fa50513          	add	a0,a0,762 # 80008870 <syscalls+0x3f8>
    8000657e:	ffffa097          	auipc	ra,0xffffa
    80006582:	fbe080e7          	jalr	-66(ra) # 8000053c <panic>
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
