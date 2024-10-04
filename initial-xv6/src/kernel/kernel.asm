
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8b070713          	add	a4,a4,-1872 # 80008900 <timer_scratch>
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
    80000066:	e6e78793          	add	a5,a5,-402 # 80005ed0 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda08f>
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
    8000012e:	3cc080e7          	jalr	972(ra) # 800024f6 <either_copyin>
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
    80000188:	8bc50513          	add	a0,a0,-1860 # 80010a40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8ac48493          	add	s1,s1,-1876 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	93c90913          	add	s2,s2,-1732 # 80010ad8 <cons+0x98>
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
    800001c0:	16c080e7          	jalr	364(ra) # 80002328 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	eaa080e7          	jalr	-342(ra) # 80002074 <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	86270713          	add	a4,a4,-1950 # 80010a40 <cons>
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
    80000214:	290080e7          	jalr	656(ra) # 800024a0 <either_copyout>
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
    8000022c:	81850513          	add	a0,a0,-2024 # 80010a40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	80250513          	add	a0,a0,-2046 # 80010a40 <cons>
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
    80000272:	86f72523          	sw	a5,-1942(a4) # 80010ad8 <cons+0x98>
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
    800002cc:	77850513          	add	a0,a0,1912 # 80010a40 <cons>
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
    800002f2:	25e080e7          	jalr	606(ra) # 8000254c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	74a50513          	add	a0,a0,1866 # 80010a40 <cons>
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
    8000031e:	72670713          	add	a4,a4,1830 # 80010a40 <cons>
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
    80000348:	6fc78793          	add	a5,a5,1788 # 80010a40 <cons>
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
    80000376:	7667a783          	lw	a5,1894(a5) # 80010ad8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ba70713          	add	a4,a4,1722 # 80010a40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6aa48493          	add	s1,s1,1706 # 80010a40 <cons>
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
    800003d6:	66e70713          	add	a4,a4,1646 # 80010a40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72c23          	sw	a5,1784(a4) # 80010ae0 <cons+0xa0>
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
    80000412:	63278793          	add	a5,a5,1586 # 80010a40 <cons>
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
    80000436:	6ac7a523          	sw	a2,1706(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	69e50513          	add	a0,a0,1694 # 80010ad8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	c96080e7          	jalr	-874(ra) # 800020d8 <wakeup>
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
    80000460:	5e450513          	add	a0,a0,1508 # 80010a40 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00023797          	auipc	a5,0x23
    80000478:	16478793          	add	a5,a5,356 # 800235d8 <devsw>
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
    8000054c:	5a07ac23          	sw	zero,1464(a5) # 80010b00 <pr+0x18>
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
    80000580:	34f72223          	sw	a5,836(a4) # 800088c0 <panicked>
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
    800005bc:	548dad83          	lw	s11,1352(s11) # 80010b00 <pr+0x18>
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
    800005fa:	4f250513          	add	a0,a0,1266 # 80010ae8 <pr>
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
    80000758:	39450513          	add	a0,a0,916 # 80010ae8 <pr>
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
    80000774:	37848493          	add	s1,s1,888 # 80010ae8 <pr>
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
    800007d4:	33850513          	add	a0,a0,824 # 80010b08 <uart_tx_lock>
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
    80000800:	0c47a783          	lw	a5,196(a5) # 800088c0 <panicked>
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
    80000838:	0947b783          	ld	a5,148(a5) # 800088c8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	09473703          	ld	a4,148(a4) # 800088d0 <uart_tx_w>
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
    80000862:	2aaa0a13          	add	s4,s4,682 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	06248493          	add	s1,s1,98 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	06298993          	add	s3,s3,98 # 800088d0 <uart_tx_w>
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
    80000894:	848080e7          	jalr	-1976(ra) # 800020d8 <wakeup>
    
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
    800008d0:	23c50513          	add	a0,a0,572 # 80010b08 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fe47a783          	lw	a5,-28(a5) # 800088c0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fea73703          	ld	a4,-22(a4) # 800088d0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fda7b783          	ld	a5,-38(a5) # 800088c8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	20e98993          	add	s3,s3,526 # 80010b08 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fc648493          	add	s1,s1,-58 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fc690913          	add	s2,s2,-58 # 800088d0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	75a080e7          	jalr	1882(ra) # 80002074 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1d848493          	add	s1,s1,472 # 80010b08 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7b623          	sd	a4,-116(a5) # 800088d0 <uart_tx_w>
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
    800009ba:	15248493          	add	s1,s1,338 # 80010b08 <uart_tx_lock>
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
    800009fc:	d7878793          	add	a5,a5,-648 # 80024770 <end>
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
    80000a1c:	12890913          	add	s2,s2,296 # 80010b40 <kmem>
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
    80000aba:	08a50513          	add	a0,a0,138 # 80010b40 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	sll	a1,a1,0x1b
    80000aca:	00024517          	auipc	a0,0x24
    80000ace:	ca650513          	add	a0,a0,-858 # 80024770 <end>
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
    80000af0:	05448493          	add	s1,s1,84 # 80010b40 <kmem>
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
    80000b08:	03c50513          	add	a0,a0,60 # 80010b40 <kmem>
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
    80000b34:	01050513          	add	a0,a0,16 # 80010b40 <kmem>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda891>
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
    80000e86:	a5670713          	add	a4,a4,-1450 # 800088d8 <started>
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
    80000ebc:	980080e7          	jalr	-1664(ra) # 80002838 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	050080e7          	jalr	80(ra) # 80005f10 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	ffa080e7          	jalr	-6(ra) # 80001ec2 <scheduler>
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
    80000f34:	8e0080e7          	jalr	-1824(ra) # 80002810 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	900080e7          	jalr	-1792(ra) # 80002838 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	fba080e7          	jalr	-70(ra) # 80005efa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	fc8080e7          	jalr	-56(ra) # 80005f10 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	1c8080e7          	jalr	456(ra) # 80003118 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	866080e7          	jalr	-1946(ra) # 800037be <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	7dc080e7          	jalr	2012(ra) # 8000473c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	0b0080e7          	jalr	176(ra) # 80006018 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d34080e7          	jalr	-716(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	94f72d23          	sw	a5,-1702(a4) # 800088d8 <started>
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
    80000f96:	94e7b783          	ld	a5,-1714(a5) # 800088e0 <kernel_pagetable>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda887>
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
    80001252:	68a7b923          	sd	a0,1682(a5) # 800088e0 <kernel_pagetable>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda890>
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
    8000184a:	74a48493          	add	s1,s1,1866 # 80010f90 <proc>
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
    80001864:	b30a0a13          	add	s4,s4,-1232 # 80019390 <tickslock>
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
    800018e6:	27e50513          	add	a0,a0,638 # 80010b60 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	add	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	27e50513          	add	a0,a0,638 # 80010b78 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	68648493          	add	s1,s1,1670 # 80010f90 <proc>
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
    80001930:	a6498993          	add	s3,s3,-1436 # 80019390 <tickslock>
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
    8000199a:	1fa50513          	add	a0,a0,506 # 80010b90 <cpus>
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
    800019c2:	1a270713          	add	a4,a4,418 # 80010b60 <pid_lock>
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
    800019fa:	e5a7a783          	lw	a5,-422(a5) # 80008850 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	e50080e7          	jalr	-432(ra) # 80002850 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	add	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	e407a023          	sw	zero,-448(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	d24080e7          	jalr	-732(ra) # 8000373e <fsinit>
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
    80001a34:	13090913          	add	s2,s2,304 # 80010b60 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e1278793          	add	a5,a5,-494 # 80008854 <nextpid>
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
    80001bc0:	3d448493          	add	s1,s1,980 # 80010f90 <proc>
    80001bc4:	00017917          	auipc	s2,0x17
    80001bc8:	7cc90913          	add	s2,s2,1996 # 80019390 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);  // Release lock if not UNUSED
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be4:	21048493          	add	s1,s1,528
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;  // No UNUSED process found, return 0
    80001bec:	4481                	li	s1,0
    80001bee:	a8a5                	j	80001c66 <allocproc+0xb6>
  p->pid = allocpid();  // Assign PID
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;      // Mark process as USED
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
    80001c1c:	cd21                	beqz	a0,80001c74 <allocproc+0xc4>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e4a080e7          	jalr	-438(ra) # 80001a6a <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c2c:	c125                	beqz	a0,80001c8c <allocproc+0xdc>
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
  p->rtime = 0;       // Initialize runtime
    80001c52:	1604a423          	sw	zero,360(s1)
  p->etime = 0;       // Initialize exit time
    80001c56:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;   // Record creation time
    80001c5a:	00007797          	auipc	a5,0x7
    80001c5e:	c967a783          	lw	a5,-874(a5) # 800088f0 <ticks>
    80001c62:	16f4a623          	sw	a5,364(s1)
}
    80001c66:	8526                	mv	a0,s1
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	add	sp,sp,32
    80001c72:	8082                	ret
    freeproc(p);      // Clean up if allocation fails
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	ee2080e7          	jalr	-286(ra) # 80001b58 <freeproc>
    release(&p->lock);  // Release lock
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	006080e7          	jalr	6(ra) # 80000c86 <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	bff1                	j	80001c66 <allocproc+0xb6>
    freeproc(p);      // Clean up if allocation fails
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	eca080e7          	jalr	-310(ra) # 80001b58 <freeproc>
    release(&p->lock);  // Release lock
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fee080e7          	jalr	-18(ra) # 80000c86 <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	b7d1                	j	80001c66 <allocproc+0xb6>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	add	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	1000                	add	s0,sp,32
  p = allocproc();
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f02080e7          	jalr	-254(ra) # 80001bb0 <allocproc>
    80001cb6:	84aa                	mv	s1,a0
  initproc = p;
    80001cb8:	00007797          	auipc	a5,0x7
    80001cbc:	c2a7b823          	sd	a0,-976(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc0:	03400613          	li	a2,52
    80001cc4:	00007597          	auipc	a1,0x7
    80001cc8:	b9c58593          	add	a1,a1,-1124 # 80008860 <initcode>
    80001ccc:	6928                	ld	a0,80(a0)
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	682080e7          	jalr	1666(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cd6:	6785                	lui	a5,0x1
    80001cd8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce4:	4641                	li	a2,16
    80001ce6:	00006597          	auipc	a1,0x6
    80001cea:	51a58593          	add	a1,a1,1306 # 80008200 <digits+0x1c0>
    80001cee:	15848513          	add	a0,s1,344
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	124080e7          	jalr	292(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cfa:	00006517          	auipc	a0,0x6
    80001cfe:	51650513          	add	a0,a0,1302 # 80008210 <digits+0x1d0>
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	45a080e7          	jalr	1114(ra) # 8000415c <namei>
    80001d0a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0e:	478d                	li	a5,3
    80001d10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f72080e7          	jalr	-142(ra) # 80000c86 <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	add	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	add	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	add	s0,sp,32
    80001d32:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c72080e7          	jalr	-910(ra) # 800019a6 <myproc>
    80001d3c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d3e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d40:	01204c63          	bgtz	s2,80001d58 <growproc+0x32>
  else if (n < 0)
    80001d44:	02094663          	bltz	s2,80001d70 <growproc+0x4a>
  p->sz = sz;
    80001d48:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4a:	4501                	li	a0,0
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	add	sp,sp,32
    80001d56:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d58:	4691                	li	a3,4
    80001d5a:	00b90633          	add	a2,s2,a1
    80001d5e:	6928                	ld	a0,80(a0)
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	6aa080e7          	jalr	1706(ra) # 8000140a <uvmalloc>
    80001d68:	85aa                	mv	a1,a0
    80001d6a:	fd79                	bnez	a0,80001d48 <growproc+0x22>
      return -1;
    80001d6c:	557d                	li	a0,-1
    80001d6e:	bff9                	j	80001d4c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d70:	00b90633          	add	a2,s2,a1
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	64c080e7          	jalr	1612(ra) # 800013c2 <uvmdealloc>
    80001d7e:	85aa                	mv	a1,a0
    80001d80:	b7e1                	j	80001d48 <growproc+0x22>

0000000080001d82 <fork>:
{
    80001d82:	7139                	add	sp,sp,-64
    80001d84:	fc06                	sd	ra,56(sp)
    80001d86:	f822                	sd	s0,48(sp)
    80001d88:	f426                	sd	s1,40(sp)
    80001d8a:	f04a                	sd	s2,32(sp)
    80001d8c:	ec4e                	sd	s3,24(sp)
    80001d8e:	e852                	sd	s4,16(sp)
    80001d90:	e456                	sd	s5,8(sp)
    80001d92:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c12080e7          	jalr	-1006(ra) # 800019a6 <myproc>
    80001d9c:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	e12080e7          	jalr	-494(ra) # 80001bb0 <allocproc>
    80001da6:	10050c63          	beqz	a0,80001ebe <fork+0x13c>
    80001daa:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dac:	048ab603          	ld	a2,72(s5)
    80001db0:	692c                	ld	a1,80(a0)
    80001db2:	050ab503          	ld	a0,80(s5)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	7ac080e7          	jalr	1964(ra) # 80001562 <uvmcopy>
    80001dbe:	04054863          	bltz	a0,80001e0e <fork+0x8c>
  np->sz = p->sz;
    80001dc2:	048ab783          	ld	a5,72(s5)
    80001dc6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dca:	058ab683          	ld	a3,88(s5)
    80001dce:	87b6                	mv	a5,a3
    80001dd0:	058a3703          	ld	a4,88(s4)
    80001dd4:	12068693          	add	a3,a3,288
    80001dd8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ddc:	6788                	ld	a0,8(a5)
    80001dde:	6b8c                	ld	a1,16(a5)
    80001de0:	6f90                	ld	a2,24(a5)
    80001de2:	01073023          	sd	a6,0(a4)
    80001de6:	e708                	sd	a0,8(a4)
    80001de8:	eb0c                	sd	a1,16(a4)
    80001dea:	ef10                	sd	a2,24(a4)
    80001dec:	02078793          	add	a5,a5,32
    80001df0:	02070713          	add	a4,a4,32
    80001df4:	fed792e3          	bne	a5,a3,80001dd8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001df8:	058a3783          	ld	a5,88(s4)
    80001dfc:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e00:	0d0a8493          	add	s1,s5,208
    80001e04:	0d0a0913          	add	s2,s4,208
    80001e08:	150a8993          	add	s3,s5,336
    80001e0c:	a00d                	j	80001e2e <fork+0xac>
    freeproc(np);
    80001e0e:	8552                	mv	a0,s4
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	d48080e7          	jalr	-696(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e18:	8552                	mv	a0,s4
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	e6c080e7          	jalr	-404(ra) # 80000c86 <release>
    return -1;
    80001e22:	597d                	li	s2,-1
    80001e24:	a059                	j	80001eaa <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e26:	04a1                	add	s1,s1,8
    80001e28:	0921                	add	s2,s2,8
    80001e2a:	01348b63          	beq	s1,s3,80001e40 <fork+0xbe>
    if (p->ofile[i])
    80001e2e:	6088                	ld	a0,0(s1)
    80001e30:	d97d                	beqz	a0,80001e26 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e32:	00003097          	auipc	ra,0x3
    80001e36:	99c080e7          	jalr	-1636(ra) # 800047ce <filedup>
    80001e3a:	00a93023          	sd	a0,0(s2)
    80001e3e:	b7e5                	j	80001e26 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e40:	150ab503          	ld	a0,336(s5)
    80001e44:	00002097          	auipc	ra,0x2
    80001e48:	b34080e7          	jalr	-1228(ra) # 80003978 <idup>
    80001e4c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e50:	4641                	li	a2,16
    80001e52:	158a8593          	add	a1,s5,344
    80001e56:	158a0513          	add	a0,s4,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fbc080e7          	jalr	-68(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e62:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e66:	8552                	mv	a0,s4
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e1e080e7          	jalr	-482(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e70:	0000f497          	auipc	s1,0xf
    80001e74:	d0848493          	add	s1,s1,-760 # 80010b78 <wait_lock>
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d58080e7          	jalr	-680(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e82:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfe080e7          	jalr	-514(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e90:	8552                	mv	a0,s4
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d40080e7          	jalr	-704(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e9a:	478d                	li	a5,3
    80001e9c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	de4080e7          	jalr	-540(ra) # 80000c86 <release>
}
    80001eaa:	854a                	mv	a0,s2
    80001eac:	70e2                	ld	ra,56(sp)
    80001eae:	7442                	ld	s0,48(sp)
    80001eb0:	74a2                	ld	s1,40(sp)
    80001eb2:	7902                	ld	s2,32(sp)
    80001eb4:	69e2                	ld	s3,24(sp)
    80001eb6:	6a42                	ld	s4,16(sp)
    80001eb8:	6aa2                	ld	s5,8(sp)
    80001eba:	6121                	add	sp,sp,64
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	597d                	li	s2,-1
    80001ec0:	b7ed                	j	80001eaa <fork+0x128>

0000000080001ec2 <scheduler>:
{
    80001ec2:	7139                	add	sp,sp,-64
    80001ec4:	fc06                	sd	ra,56(sp)
    80001ec6:	f822                	sd	s0,48(sp)
    80001ec8:	f426                	sd	s1,40(sp)
    80001eca:	f04a                	sd	s2,32(sp)
    80001ecc:	ec4e                	sd	s3,24(sp)
    80001ece:	e852                	sd	s4,16(sp)
    80001ed0:	e456                	sd	s5,8(sp)
    80001ed2:	e05a                	sd	s6,0(sp)
    80001ed4:	0080                	add	s0,sp,64
    80001ed6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eda:	00779a93          	sll	s5,a5,0x7
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	c8270713          	add	a4,a4,-894 # 80010b60 <pid_lock>
    80001ee6:	9756                	add	a4,a4,s5
    80001ee8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	cac70713          	add	a4,a4,-852 # 80010b98 <cpus+0x8>
    80001ef4:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ef6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef8:	4b11                	li	s6,4
        c->proc = p;
    80001efa:	079e                	sll	a5,a5,0x7
    80001efc:	0000fa17          	auipc	s4,0xf
    80001f00:	c64a0a13          	add	s4,s4,-924 # 80010b60 <pid_lock>
    80001f04:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f06:	00017917          	auipc	s2,0x17
    80001f0a:	48a90913          	add	s2,s2,1162 # 80019390 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f12:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f16:	10079073          	csrw	sstatus,a5
    80001f1a:	0000f497          	auipc	s1,0xf
    80001f1e:	07648493          	add	s1,s1,118 # 80010f90 <proc>
    80001f22:	a811                	j	80001f36 <scheduler+0x74>
      release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d60080e7          	jalr	-672(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f2e:	21048493          	add	s1,s1,528
    80001f32:	fd248ee3          	beq	s1,s2,80001f0e <scheduler+0x4c>
      acquire(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	c9a080e7          	jalr	-870(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001f40:	4c9c                	lw	a5,24(s1)
    80001f42:	ff3791e3          	bne	a5,s3,80001f24 <scheduler+0x62>
        p->state = RUNNING;
    80001f46:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f4a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f4e:	06048593          	add	a1,s1,96
    80001f52:	8556                	mv	a0,s5
    80001f54:	00001097          	auipc	ra,0x1
    80001f58:	852080e7          	jalr	-1966(ra) # 800027a6 <swtch>
        c->proc = 0;
    80001f5c:	020a3823          	sd	zero,48(s4)
    80001f60:	b7d1                	j	80001f24 <scheduler+0x62>

0000000080001f62 <sched>:
{
    80001f62:	7179                	add	sp,sp,-48
    80001f64:	f406                	sd	ra,40(sp)
    80001f66:	f022                	sd	s0,32(sp)
    80001f68:	ec26                	sd	s1,24(sp)
    80001f6a:	e84a                	sd	s2,16(sp)
    80001f6c:	e44e                	sd	s3,8(sp)
    80001f6e:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	a36080e7          	jalr	-1482(ra) # 800019a6 <myproc>
    80001f78:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	bde080e7          	jalr	-1058(ra) # 80000b58 <holding>
    80001f82:	c93d                	beqz	a0,80001ff8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f86:	2781                	sext.w	a5,a5
    80001f88:	079e                	sll	a5,a5,0x7
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	bd670713          	add	a4,a4,-1066 # 80010b60 <pid_lock>
    80001f92:	97ba                	add	a5,a5,a4
    80001f94:	0a87a703          	lw	a4,168(a5)
    80001f98:	4785                	li	a5,1
    80001f9a:	06f71763          	bne	a4,a5,80002008 <sched+0xa6>
  if (p->state == RUNNING)
    80001f9e:	4c98                	lw	a4,24(s1)
    80001fa0:	4791                	li	a5,4
    80001fa2:	06f70b63          	beq	a4,a5,80002018 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001faa:	8b89                	and	a5,a5,2
  if (intr_get())
    80001fac:	efb5                	bnez	a5,80002028 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb0:	0000f917          	auipc	s2,0xf
    80001fb4:	bb090913          	add	s2,s2,-1104 # 80010b60 <pid_lock>
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	sll	a5,a5,0x7
    80001fbc:	97ca                	add	a5,a5,s2
    80001fbe:	0ac7a983          	lw	s3,172(a5)
    80001fc2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc4:	2781                	sext.w	a5,a5
    80001fc6:	079e                	sll	a5,a5,0x7
    80001fc8:	0000f597          	auipc	a1,0xf
    80001fcc:	bd058593          	add	a1,a1,-1072 # 80010b98 <cpus+0x8>
    80001fd0:	95be                	add	a1,a1,a5
    80001fd2:	06048513          	add	a0,s1,96
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	7d0080e7          	jalr	2000(ra) # 800027a6 <swtch>
    80001fde:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	079e                	sll	a5,a5,0x7
    80001fe4:	993e                	add	s2,s2,a5
    80001fe6:	0b392623          	sw	s3,172(s2)
}
    80001fea:	70a2                	ld	ra,40(sp)
    80001fec:	7402                	ld	s0,32(sp)
    80001fee:	64e2                	ld	s1,24(sp)
    80001ff0:	6942                	ld	s2,16(sp)
    80001ff2:	69a2                	ld	s3,8(sp)
    80001ff4:	6145                	add	sp,sp,48
    80001ff6:	8082                	ret
    panic("sched p->lock");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	22050513          	add	a0,a0,544 # 80008218 <digits+0x1d8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53c080e7          	jalr	1340(ra) # 8000053c <panic>
    panic("sched locks");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	22050513          	add	a0,a0,544 # 80008228 <digits+0x1e8>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52c080e7          	jalr	1324(ra) # 8000053c <panic>
    panic("sched running");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	22050513          	add	a0,a0,544 # 80008238 <digits+0x1f8>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	51c080e7          	jalr	1308(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	22050513          	add	a0,a0,544 # 80008248 <digits+0x208>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	50c080e7          	jalr	1292(ra) # 8000053c <panic>

0000000080002038 <yield>:
{
    80002038:	1101                	add	sp,sp,-32
    8000203a:	ec06                	sd	ra,24(sp)
    8000203c:	e822                	sd	s0,16(sp)
    8000203e:	e426                	sd	s1,8(sp)
    80002040:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	964080e7          	jalr	-1692(ra) # 800019a6 <myproc>
    8000204a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b86080e7          	jalr	-1146(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002054:	478d                	li	a5,3
    80002056:	cc9c                	sw	a5,24(s1)
  sched();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	f0a080e7          	jalr	-246(ra) # 80001f62 <sched>
  release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c24080e7          	jalr	-988(ra) # 80000c86 <release>
}
    8000206a:	60e2                	ld	ra,24(sp)
    8000206c:	6442                	ld	s0,16(sp)
    8000206e:	64a2                	ld	s1,8(sp)
    80002070:	6105                	add	sp,sp,32
    80002072:	8082                	ret

0000000080002074 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002074:	7179                	add	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	1800                	add	s0,sp,48
    80002082:	89aa                	mv	s3,a0
    80002084:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	920080e7          	jalr	-1760(ra) # 800019a6 <myproc>
    8000208e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b42080e7          	jalr	-1214(ra) # 80000bd2 <acquire>
  release(lk);
    80002098:	854a                	mv	a0,s2
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bec080e7          	jalr	-1044(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800020a2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a6:	4789                	li	a5,2
    800020a8:	cc9c                	sw	a5,24(s1)

  sched();
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	eb8080e7          	jalr	-328(ra) # 80001f62 <sched>

  // Tidy up.
  p->chan = 0;
    800020b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bce080e7          	jalr	-1074(ra) # 80000c86 <release>
  acquire(lk);
    800020c0:	854a                	mv	a0,s2
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	b10080e7          	jalr	-1264(ra) # 80000bd2 <acquire>
}
    800020ca:	70a2                	ld	ra,40(sp)
    800020cc:	7402                	ld	s0,32(sp)
    800020ce:	64e2                	ld	s1,24(sp)
    800020d0:	6942                	ld	s2,16(sp)
    800020d2:	69a2                	ld	s3,8(sp)
    800020d4:	6145                	add	sp,sp,48
    800020d6:	8082                	ret

00000000800020d8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020d8:	7139                	add	sp,sp,-64
    800020da:	fc06                	sd	ra,56(sp)
    800020dc:	f822                	sd	s0,48(sp)
    800020de:	f426                	sd	s1,40(sp)
    800020e0:	f04a                	sd	s2,32(sp)
    800020e2:	ec4e                	sd	s3,24(sp)
    800020e4:	e852                	sd	s4,16(sp)
    800020e6:	e456                	sd	s5,8(sp)
    800020e8:	0080                	add	s0,sp,64
    800020ea:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	0000f497          	auipc	s1,0xf
    800020f0:	ea448493          	add	s1,s1,-348 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020f4:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020f6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020f8:	00017917          	auipc	s2,0x17
    800020fc:	29890913          	add	s2,s2,664 # 80019390 <tickslock>
    80002100:	a811                	j	80002114 <wakeup+0x3c>
      }
      release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b82080e7          	jalr	-1150(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000210c:	21048493          	add	s1,s1,528
    80002110:	03248663          	beq	s1,s2,8000213c <wakeup+0x64>
    if (p != myproc())
    80002114:	00000097          	auipc	ra,0x0
    80002118:	892080e7          	jalr	-1902(ra) # 800019a6 <myproc>
    8000211c:	fea488e3          	beq	s1,a0,8000210c <wakeup+0x34>
      acquire(&p->lock);
    80002120:	8526                	mv	a0,s1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ab0080e7          	jalr	-1360(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000212a:	4c9c                	lw	a5,24(s1)
    8000212c:	fd379be3          	bne	a5,s3,80002102 <wakeup+0x2a>
    80002130:	709c                	ld	a5,32(s1)
    80002132:	fd4798e3          	bne	a5,s4,80002102 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002136:	0154ac23          	sw	s5,24(s1)
    8000213a:	b7e1                	j	80002102 <wakeup+0x2a>
    }
  }
}
    8000213c:	70e2                	ld	ra,56(sp)
    8000213e:	7442                	ld	s0,48(sp)
    80002140:	74a2                	ld	s1,40(sp)
    80002142:	7902                	ld	s2,32(sp)
    80002144:	69e2                	ld	s3,24(sp)
    80002146:	6a42                	ld	s4,16(sp)
    80002148:	6aa2                	ld	s5,8(sp)
    8000214a:	6121                	add	sp,sp,64
    8000214c:	8082                	ret

000000008000214e <reparent>:
{
    8000214e:	7179                	add	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	e052                	sd	s4,0(sp)
    8000215c:	1800                	add	s0,sp,48
    8000215e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002160:	0000f497          	auipc	s1,0xf
    80002164:	e3048493          	add	s1,s1,-464 # 80010f90 <proc>
      pp->parent = initproc;
    80002168:	00006a17          	auipc	s4,0x6
    8000216c:	780a0a13          	add	s4,s4,1920 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002170:	00017997          	auipc	s3,0x17
    80002174:	22098993          	add	s3,s3,544 # 80019390 <tickslock>
    80002178:	a029                	j	80002182 <reparent+0x34>
    8000217a:	21048493          	add	s1,s1,528
    8000217e:	01348d63          	beq	s1,s3,80002198 <reparent+0x4a>
    if (pp->parent == p)
    80002182:	7c9c                	ld	a5,56(s1)
    80002184:	ff279be3          	bne	a5,s2,8000217a <reparent+0x2c>
      pp->parent = initproc;
    80002188:	000a3503          	ld	a0,0(s4)
    8000218c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	f4a080e7          	jalr	-182(ra) # 800020d8 <wakeup>
    80002196:	b7d5                	j	8000217a <reparent+0x2c>
}
    80002198:	70a2                	ld	ra,40(sp)
    8000219a:	7402                	ld	s0,32(sp)
    8000219c:	64e2                	ld	s1,24(sp)
    8000219e:	6942                	ld	s2,16(sp)
    800021a0:	69a2                	ld	s3,8(sp)
    800021a2:	6a02                	ld	s4,0(sp)
    800021a4:	6145                	add	sp,sp,48
    800021a6:	8082                	ret

00000000800021a8 <exit>:
{
    800021a8:	7179                	add	sp,sp,-48
    800021aa:	f406                	sd	ra,40(sp)
    800021ac:	f022                	sd	s0,32(sp)
    800021ae:	ec26                	sd	s1,24(sp)
    800021b0:	e84a                	sd	s2,16(sp)
    800021b2:	e44e                	sd	s3,8(sp)
    800021b4:	e052                	sd	s4,0(sp)
    800021b6:	1800                	add	s0,sp,48
    800021b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	7ec080e7          	jalr	2028(ra) # 800019a6 <myproc>
    800021c2:	89aa                	mv	s3,a0
  if (p == initproc)
    800021c4:	00006797          	auipc	a5,0x6
    800021c8:	7247b783          	ld	a5,1828(a5) # 800088e8 <initproc>
    800021cc:	0d050493          	add	s1,a0,208
    800021d0:	15050913          	add	s2,a0,336
    800021d4:	02a79363          	bne	a5,a0,800021fa <exit+0x52>
    panic("init exiting");
    800021d8:	00006517          	auipc	a0,0x6
    800021dc:	08850513          	add	a0,a0,136 # 80008260 <digits+0x220>
    800021e0:	ffffe097          	auipc	ra,0xffffe
    800021e4:	35c080e7          	jalr	860(ra) # 8000053c <panic>
      fileclose(f);
    800021e8:	00002097          	auipc	ra,0x2
    800021ec:	638080e7          	jalr	1592(ra) # 80004820 <fileclose>
      p->ofile[fd] = 0;
    800021f0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021f4:	04a1                	add	s1,s1,8
    800021f6:	01248563          	beq	s1,s2,80002200 <exit+0x58>
    if (p->ofile[fd])
    800021fa:	6088                	ld	a0,0(s1)
    800021fc:	f575                	bnez	a0,800021e8 <exit+0x40>
    800021fe:	bfdd                	j	800021f4 <exit+0x4c>
  begin_op();
    80002200:	00002097          	auipc	ra,0x2
    80002204:	15c080e7          	jalr	348(ra) # 8000435c <begin_op>
  iput(p->cwd);
    80002208:	1509b503          	ld	a0,336(s3)
    8000220c:	00002097          	auipc	ra,0x2
    80002210:	964080e7          	jalr	-1692(ra) # 80003b70 <iput>
  end_op();
    80002214:	00002097          	auipc	ra,0x2
    80002218:	1c2080e7          	jalr	450(ra) # 800043d6 <end_op>
  p->cwd = 0;
    8000221c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	95848493          	add	s1,s1,-1704 # 80010b78 <wait_lock>
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9a8080e7          	jalr	-1624(ra) # 80000bd2 <acquire>
  reparent(p);
    80002232:	854e                	mv	a0,s3
    80002234:	00000097          	auipc	ra,0x0
    80002238:	f1a080e7          	jalr	-230(ra) # 8000214e <reparent>
  wakeup(p->parent);
    8000223c:	0389b503          	ld	a0,56(s3)
    80002240:	00000097          	auipc	ra,0x0
    80002244:	e98080e7          	jalr	-360(ra) # 800020d8 <wakeup>
  acquire(&p->lock);
    80002248:	854e                	mv	a0,s3
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	988080e7          	jalr	-1656(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002252:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002256:	4795                	li	a5,5
    80002258:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000225c:	00006797          	auipc	a5,0x6
    80002260:	6947a783          	lw	a5,1684(a5) # 800088f0 <ticks>
    80002264:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a1c080e7          	jalr	-1508(ra) # 80000c86 <release>
  sched();
    80002272:	00000097          	auipc	ra,0x0
    80002276:	cf0080e7          	jalr	-784(ra) # 80001f62 <sched>
  panic("zombie exit");
    8000227a:	00006517          	auipc	a0,0x6
    8000227e:	ff650513          	add	a0,a0,-10 # 80008270 <digits+0x230>
    80002282:	ffffe097          	auipc	ra,0xffffe
    80002286:	2ba080e7          	jalr	698(ra) # 8000053c <panic>

000000008000228a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000228a:	7179                	add	sp,sp,-48
    8000228c:	f406                	sd	ra,40(sp)
    8000228e:	f022                	sd	s0,32(sp)
    80002290:	ec26                	sd	s1,24(sp)
    80002292:	e84a                	sd	s2,16(sp)
    80002294:	e44e                	sd	s3,8(sp)
    80002296:	1800                	add	s0,sp,48
    80002298:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000229a:	0000f497          	auipc	s1,0xf
    8000229e:	cf648493          	add	s1,s1,-778 # 80010f90 <proc>
    800022a2:	00017997          	auipc	s3,0x17
    800022a6:	0ee98993          	add	s3,s3,238 # 80019390 <tickslock>
  {
    acquire(&p->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	926080e7          	jalr	-1754(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    800022b4:	589c                	lw	a5,48(s1)
    800022b6:	01278d63          	beq	a5,s2,800022d0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	9ca080e7          	jalr	-1590(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022c4:	21048493          	add	s1,s1,528
    800022c8:	ff3491e3          	bne	s1,s3,800022aa <kill+0x20>
  }
  return -1;
    800022cc:	557d                	li	a0,-1
    800022ce:	a829                	j	800022e8 <kill+0x5e>
      p->killed = 1;
    800022d0:	4785                	li	a5,1
    800022d2:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022d4:	4c98                	lw	a4,24(s1)
    800022d6:	4789                	li	a5,2
    800022d8:	00f70f63          	beq	a4,a5,800022f6 <kill+0x6c>
      release(&p->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9a8080e7          	jalr	-1624(ra) # 80000c86 <release>
      return 0;
    800022e6:	4501                	li	a0,0
}
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6145                	add	sp,sp,48
    800022f4:	8082                	ret
        p->state = RUNNABLE;
    800022f6:	478d                	li	a5,3
    800022f8:	cc9c                	sw	a5,24(s1)
    800022fa:	b7cd                	j	800022dc <kill+0x52>

00000000800022fc <setkilled>:

void setkilled(struct proc *p)
{
    800022fc:	1101                	add	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	1000                	add	s0,sp,32
    80002306:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	8ca080e7          	jalr	-1846(ra) # 80000bd2 <acquire>
  p->killed = 1;
    80002310:	4785                	li	a5,1
    80002312:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	970080e7          	jalr	-1680(ra) # 80000c86 <release>
}
    8000231e:	60e2                	ld	ra,24(sp)
    80002320:	6442                	ld	s0,16(sp)
    80002322:	64a2                	ld	s1,8(sp)
    80002324:	6105                	add	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <killed>:

int killed(struct proc *p)
{
    80002328:	1101                	add	sp,sp,-32
    8000232a:	ec06                	sd	ra,24(sp)
    8000232c:	e822                	sd	s0,16(sp)
    8000232e:	e426                	sd	s1,8(sp)
    80002330:	e04a                	sd	s2,0(sp)
    80002332:	1000                	add	s0,sp,32
    80002334:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	89c080e7          	jalr	-1892(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000233e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	942080e7          	jalr	-1726(ra) # 80000c86 <release>
  return k;
}
    8000234c:	854a                	mv	a0,s2
    8000234e:	60e2                	ld	ra,24(sp)
    80002350:	6442                	ld	s0,16(sp)
    80002352:	64a2                	ld	s1,8(sp)
    80002354:	6902                	ld	s2,0(sp)
    80002356:	6105                	add	sp,sp,32
    80002358:	8082                	ret

000000008000235a <wait>:
{
    8000235a:	715d                	add	sp,sp,-80
    8000235c:	e486                	sd	ra,72(sp)
    8000235e:	e0a2                	sd	s0,64(sp)
    80002360:	fc26                	sd	s1,56(sp)
    80002362:	f84a                	sd	s2,48(sp)
    80002364:	f44e                	sd	s3,40(sp)
    80002366:	f052                	sd	s4,32(sp)
    80002368:	ec56                	sd	s5,24(sp)
    8000236a:	e85a                	sd	s6,16(sp)
    8000236c:	e45e                	sd	s7,8(sp)
    8000236e:	e062                	sd	s8,0(sp)
    80002370:	0880                	add	s0,sp,80
    80002372:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	632080e7          	jalr	1586(ra) # 800019a6 <myproc>
    8000237c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000237e:	0000e517          	auipc	a0,0xe
    80002382:	7fa50513          	add	a0,a0,2042 # 80010b78 <wait_lock>
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	84c080e7          	jalr	-1972(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000238e:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002390:	4a95                	li	s5,5
        havekids = 1;
    80002392:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002394:	00017997          	auipc	s3,0x17
    80002398:	ffc98993          	add	s3,s3,-4 # 80019390 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000239c:	0000ec17          	auipc	s8,0xe
    800023a0:	7dcc0c13          	add	s8,s8,2012 # 80010b78 <wait_lock>
    800023a4:	a8f1                	j	80002480 <wait+0x126>
    800023a6:	17448793          	add	a5,s1,372
    800023aa:	17490713          	add	a4,s2,372
    800023ae:	1f048613          	add	a2,s1,496
            p->syscall_count[i]=pp->syscall_count[i];
    800023b2:	4394                	lw	a3,0(a5)
    800023b4:	c314                	sw	a3,0(a4)
          for(int i=0;i<31;i++){
    800023b6:	0791                	add	a5,a5,4
    800023b8:	0711                	add	a4,a4,4
    800023ba:	fec79ce3          	bne	a5,a2,800023b2 <wait+0x58>
          pid = pp->pid;
    800023be:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023c2:	000a0e63          	beqz	s4,800023de <wait+0x84>
    800023c6:	4691                	li	a3,4
    800023c8:	02c48613          	add	a2,s1,44
    800023cc:	85d2                	mv	a1,s4
    800023ce:	05093503          	ld	a0,80(s2)
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	294080e7          	jalr	660(ra) # 80001666 <copyout>
    800023da:	04054163          	bltz	a0,8000241c <wait+0xc2>
          freeproc(pp);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	778080e7          	jalr	1912(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	89c080e7          	jalr	-1892(ra) # 80000c86 <release>
          release(&wait_lock);
    800023f2:	0000e517          	auipc	a0,0xe
    800023f6:	78650513          	add	a0,a0,1926 # 80010b78 <wait_lock>
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	88c080e7          	jalr	-1908(ra) # 80000c86 <release>
}
    80002402:	854e                	mv	a0,s3
    80002404:	60a6                	ld	ra,72(sp)
    80002406:	6406                	ld	s0,64(sp)
    80002408:	74e2                	ld	s1,56(sp)
    8000240a:	7942                	ld	s2,48(sp)
    8000240c:	79a2                	ld	s3,40(sp)
    8000240e:	7a02                	ld	s4,32(sp)
    80002410:	6ae2                	ld	s5,24(sp)
    80002412:	6b42                	ld	s6,16(sp)
    80002414:	6ba2                	ld	s7,8(sp)
    80002416:	6c02                	ld	s8,0(sp)
    80002418:	6161                	add	sp,sp,80
    8000241a:	8082                	ret
            release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	868080e7          	jalr	-1944(ra) # 80000c86 <release>
            release(&wait_lock);
    80002426:	0000e517          	auipc	a0,0xe
    8000242a:	75250513          	add	a0,a0,1874 # 80010b78 <wait_lock>
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	858080e7          	jalr	-1960(ra) # 80000c86 <release>
            return -1;
    80002436:	59fd                	li	s3,-1
    80002438:	b7e9                	j	80002402 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000243a:	21048493          	add	s1,s1,528
    8000243e:	03348463          	beq	s1,s3,80002466 <wait+0x10c>
      if (pp->parent == p)
    80002442:	7c9c                	ld	a5,56(s1)
    80002444:	ff279be3          	bne	a5,s2,8000243a <wait+0xe0>
        acquire(&pp->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	788080e7          	jalr	1928(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002452:	4c9c                	lw	a5,24(s1)
    80002454:	f55789e3          	beq	a5,s5,800023a6 <wait+0x4c>
        release(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	82c080e7          	jalr	-2004(ra) # 80000c86 <release>
        havekids = 1;
    80002462:	875a                	mv	a4,s6
    80002464:	bfd9                	j	8000243a <wait+0xe0>
    if (!havekids || killed(p))
    80002466:	c31d                	beqz	a4,8000248c <wait+0x132>
    80002468:	854a                	mv	a0,s2
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	ebe080e7          	jalr	-322(ra) # 80002328 <killed>
    80002472:	ed09                	bnez	a0,8000248c <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002474:	85e2                	mv	a1,s8
    80002476:	854a                	mv	a0,s2
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	bfc080e7          	jalr	-1028(ra) # 80002074 <sleep>
    havekids = 0;
    80002480:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002482:	0000f497          	auipc	s1,0xf
    80002486:	b0e48493          	add	s1,s1,-1266 # 80010f90 <proc>
    8000248a:	bf65                	j	80002442 <wait+0xe8>
      release(&wait_lock);
    8000248c:	0000e517          	auipc	a0,0xe
    80002490:	6ec50513          	add	a0,a0,1772 # 80010b78 <wait_lock>
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	7f2080e7          	jalr	2034(ra) # 80000c86 <release>
      return -1;
    8000249c:	59fd                	li	s3,-1
    8000249e:	b795                	j	80002402 <wait+0xa8>

00000000800024a0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a0:	7179                	add	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	e052                	sd	s4,0(sp)
    800024ae:	1800                	add	s0,sp,48
    800024b0:	84aa                	mv	s1,a0
    800024b2:	892e                	mv	s2,a1
    800024b4:	89b2                	mv	s3,a2
    800024b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	4ee080e7          	jalr	1262(ra) # 800019a6 <myproc>
  if (user_dst)
    800024c0:	c08d                	beqz	s1,800024e2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024c2:	86d2                	mv	a3,s4
    800024c4:	864e                	mv	a2,s3
    800024c6:	85ca                	mv	a1,s2
    800024c8:	6928                	ld	a0,80(a0)
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	19c080e7          	jalr	412(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d2:	70a2                	ld	ra,40(sp)
    800024d4:	7402                	ld	s0,32(sp)
    800024d6:	64e2                	ld	s1,24(sp)
    800024d8:	6942                	ld	s2,16(sp)
    800024da:	69a2                	ld	s3,8(sp)
    800024dc:	6a02                	ld	s4,0(sp)
    800024de:	6145                	add	sp,sp,48
    800024e0:	8082                	ret
    memmove((char *)dst, src, len);
    800024e2:	000a061b          	sext.w	a2,s4
    800024e6:	85ce                	mv	a1,s3
    800024e8:	854a                	mv	a0,s2
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	840080e7          	jalr	-1984(ra) # 80000d2a <memmove>
    return 0;
    800024f2:	8526                	mv	a0,s1
    800024f4:	bff9                	j	800024d2 <either_copyout+0x32>

00000000800024f6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f6:	7179                	add	sp,sp,-48
    800024f8:	f406                	sd	ra,40(sp)
    800024fa:	f022                	sd	s0,32(sp)
    800024fc:	ec26                	sd	s1,24(sp)
    800024fe:	e84a                	sd	s2,16(sp)
    80002500:	e44e                	sd	s3,8(sp)
    80002502:	e052                	sd	s4,0(sp)
    80002504:	1800                	add	s0,sp,48
    80002506:	892a                	mv	s2,a0
    80002508:	84ae                	mv	s1,a1
    8000250a:	89b2                	mv	s3,a2
    8000250c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	498080e7          	jalr	1176(ra) # 800019a6 <myproc>
  if (user_src)
    80002516:	c08d                	beqz	s1,80002538 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002518:	86d2                	mv	a3,s4
    8000251a:	864e                	mv	a2,s3
    8000251c:	85ca                	mv	a1,s2
    8000251e:	6928                	ld	a0,80(a0)
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	1d2080e7          	jalr	466(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002528:	70a2                	ld	ra,40(sp)
    8000252a:	7402                	ld	s0,32(sp)
    8000252c:	64e2                	ld	s1,24(sp)
    8000252e:	6942                	ld	s2,16(sp)
    80002530:	69a2                	ld	s3,8(sp)
    80002532:	6a02                	ld	s4,0(sp)
    80002534:	6145                	add	sp,sp,48
    80002536:	8082                	ret
    memmove(dst, (char *)src, len);
    80002538:	000a061b          	sext.w	a2,s4
    8000253c:	85ce                	mv	a1,s3
    8000253e:	854a                	mv	a0,s2
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	7ea080e7          	jalr	2026(ra) # 80000d2a <memmove>
    return 0;
    80002548:	8526                	mv	a0,s1
    8000254a:	bff9                	j	80002528 <either_copyin+0x32>

000000008000254c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000254c:	715d                	add	sp,sp,-80
    8000254e:	e486                	sd	ra,72(sp)
    80002550:	e0a2                	sd	s0,64(sp)
    80002552:	fc26                	sd	s1,56(sp)
    80002554:	f84a                	sd	s2,48(sp)
    80002556:	f44e                	sd	s3,40(sp)
    80002558:	f052                	sd	s4,32(sp)
    8000255a:	ec56                	sd	s5,24(sp)
    8000255c:	e85a                	sd	s6,16(sp)
    8000255e:	e45e                	sd	s7,8(sp)
    80002560:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002562:	00006517          	auipc	a0,0x6
    80002566:	b6650513          	add	a0,a0,-1178 # 800080c8 <digits+0x88>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	01c080e7          	jalr	28(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002572:	0000f497          	auipc	s1,0xf
    80002576:	b7648493          	add	s1,s1,-1162 # 800110e8 <proc+0x158>
    8000257a:	00017917          	auipc	s2,0x17
    8000257e:	f6e90913          	add	s2,s2,-146 # 800194e8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002582:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002584:	00006997          	auipc	s3,0x6
    80002588:	cfc98993          	add	s3,s3,-772 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000258c:	00006a97          	auipc	s5,0x6
    80002590:	cfca8a93          	add	s5,s5,-772 # 80008288 <digits+0x248>
    printf("\n");
    80002594:	00006a17          	auipc	s4,0x6
    80002598:	b34a0a13          	add	s4,s4,-1228 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259c:	00006b97          	auipc	s7,0x6
    800025a0:	d2cb8b93          	add	s7,s7,-724 # 800082c8 <states.0>
    800025a4:	a00d                	j	800025c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a6:	ed86a583          	lw	a1,-296(a3)
    800025aa:	8556                	mv	a0,s5
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	fda080e7          	jalr	-38(ra) # 80000586 <printf>
    printf("\n");
    800025b4:	8552                	mv	a0,s4
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	fd0080e7          	jalr	-48(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025be:	21048493          	add	s1,s1,528
    800025c2:	03248263          	beq	s1,s2,800025e6 <procdump+0x9a>
    if (p->state == UNUSED)
    800025c6:	86a6                	mv	a3,s1
    800025c8:	ec04a783          	lw	a5,-320(s1)
    800025cc:	dbed                	beqz	a5,800025be <procdump+0x72>
      state = "???";
    800025ce:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d0:	fcfb6be3          	bltu	s6,a5,800025a6 <procdump+0x5a>
    800025d4:	02079713          	sll	a4,a5,0x20
    800025d8:	01d75793          	srl	a5,a4,0x1d
    800025dc:	97de                	add	a5,a5,s7
    800025de:	6390                	ld	a2,0(a5)
    800025e0:	f279                	bnez	a2,800025a6 <procdump+0x5a>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    800025e4:	b7c9                	j	800025a6 <procdump+0x5a>
  }
}
    800025e6:	60a6                	ld	ra,72(sp)
    800025e8:	6406                	ld	s0,64(sp)
    800025ea:	74e2                	ld	s1,56(sp)
    800025ec:	7942                	ld	s2,48(sp)
    800025ee:	79a2                	ld	s3,40(sp)
    800025f0:	7a02                	ld	s4,32(sp)
    800025f2:	6ae2                	ld	s5,24(sp)
    800025f4:	6b42                	ld	s6,16(sp)
    800025f6:	6ba2                	ld	s7,8(sp)
    800025f8:	6161                	add	sp,sp,80
    800025fa:	8082                	ret

00000000800025fc <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025fc:	711d                	add	sp,sp,-96
    800025fe:	ec86                	sd	ra,88(sp)
    80002600:	e8a2                	sd	s0,80(sp)
    80002602:	e4a6                	sd	s1,72(sp)
    80002604:	e0ca                	sd	s2,64(sp)
    80002606:	fc4e                	sd	s3,56(sp)
    80002608:	f852                	sd	s4,48(sp)
    8000260a:	f456                	sd	s5,40(sp)
    8000260c:	f05a                	sd	s6,32(sp)
    8000260e:	ec5e                	sd	s7,24(sp)
    80002610:	e862                	sd	s8,16(sp)
    80002612:	e466                	sd	s9,8(sp)
    80002614:	e06a                	sd	s10,0(sp)
    80002616:	1080                	add	s0,sp,96
    80002618:	8b2a                	mv	s6,a0
    8000261a:	8bae                	mv	s7,a1
    8000261c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	388080e7          	jalr	904(ra) # 800019a6 <myproc>
    80002626:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002628:	0000e517          	auipc	a0,0xe
    8000262c:	55050513          	add	a0,a0,1360 # 80010b78 <wait_lock>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	5a2080e7          	jalr	1442(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002638:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000263a:	4a15                	li	s4,5
        havekids = 1;
    8000263c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000263e:	00017997          	auipc	s3,0x17
    80002642:	d5298993          	add	s3,s3,-686 # 80019390 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002646:	0000ed17          	auipc	s10,0xe
    8000264a:	532d0d13          	add	s10,s10,1330 # 80010b78 <wait_lock>
    8000264e:	a8e9                	j	80002728 <waitx+0x12c>
          pid = np->pid;
    80002650:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002654:	1684a783          	lw	a5,360(s1)
    80002658:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000265c:	16c4a703          	lw	a4,364(s1)
    80002660:	9f3d                	addw	a4,a4,a5
    80002662:	1704a783          	lw	a5,368(s1)
    80002666:	9f99                	subw	a5,a5,a4
    80002668:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000266c:	000b0e63          	beqz	s6,80002688 <waitx+0x8c>
    80002670:	4691                	li	a3,4
    80002672:	02c48613          	add	a2,s1,44
    80002676:	85da                	mv	a1,s6
    80002678:	05093503          	ld	a0,80(s2)
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	fea080e7          	jalr	-22(ra) # 80001666 <copyout>
    80002684:	04054363          	bltz	a0,800026ca <waitx+0xce>
          freeproc(np);
    80002688:	8526                	mv	a0,s1
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	4ce080e7          	jalr	1230(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5f2080e7          	jalr	1522(ra) # 80000c86 <release>
          release(&wait_lock);
    8000269c:	0000e517          	auipc	a0,0xe
    800026a0:	4dc50513          	add	a0,a0,1244 # 80010b78 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e2080e7          	jalr	1506(ra) # 80000c86 <release>
  }
}
    800026ac:	854e                	mv	a0,s3
    800026ae:	60e6                	ld	ra,88(sp)
    800026b0:	6446                	ld	s0,80(sp)
    800026b2:	64a6                	ld	s1,72(sp)
    800026b4:	6906                	ld	s2,64(sp)
    800026b6:	79e2                	ld	s3,56(sp)
    800026b8:	7a42                	ld	s4,48(sp)
    800026ba:	7aa2                	ld	s5,40(sp)
    800026bc:	7b02                	ld	s6,32(sp)
    800026be:	6be2                	ld	s7,24(sp)
    800026c0:	6c42                	ld	s8,16(sp)
    800026c2:	6ca2                	ld	s9,8(sp)
    800026c4:	6d02                	ld	s10,0(sp)
    800026c6:	6125                	add	sp,sp,96
    800026c8:	8082                	ret
            release(&np->lock);
    800026ca:	8526                	mv	a0,s1
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	5ba080e7          	jalr	1466(ra) # 80000c86 <release>
            release(&wait_lock);
    800026d4:	0000e517          	auipc	a0,0xe
    800026d8:	4a450513          	add	a0,a0,1188 # 80010b78 <wait_lock>
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	5aa080e7          	jalr	1450(ra) # 80000c86 <release>
            return -1;
    800026e4:	59fd                	li	s3,-1
    800026e6:	b7d9                	j	800026ac <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    800026e8:	21048493          	add	s1,s1,528
    800026ec:	03348463          	beq	s1,s3,80002714 <waitx+0x118>
      if (np->parent == p)
    800026f0:	7c9c                	ld	a5,56(s1)
    800026f2:	ff279be3          	bne	a5,s2,800026e8 <waitx+0xec>
        acquire(&np->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	4da080e7          	jalr	1242(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    80002700:	4c9c                	lw	a5,24(s1)
    80002702:	f54787e3          	beq	a5,s4,80002650 <waitx+0x54>
        release(&np->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	57e080e7          	jalr	1406(ra) # 80000c86 <release>
        havekids = 1;
    80002710:	8756                	mv	a4,s5
    80002712:	bfd9                	j	800026e8 <waitx+0xec>
    if (!havekids || p->killed)
    80002714:	c305                	beqz	a4,80002734 <waitx+0x138>
    80002716:	02892783          	lw	a5,40(s2)
    8000271a:	ef89                	bnez	a5,80002734 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000271c:	85ea                	mv	a1,s10
    8000271e:	854a                	mv	a0,s2
    80002720:	00000097          	auipc	ra,0x0
    80002724:	954080e7          	jalr	-1708(ra) # 80002074 <sleep>
    havekids = 0;
    80002728:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000272a:	0000f497          	auipc	s1,0xf
    8000272e:	86648493          	add	s1,s1,-1946 # 80010f90 <proc>
    80002732:	bf7d                	j	800026f0 <waitx+0xf4>
      release(&wait_lock);
    80002734:	0000e517          	auipc	a0,0xe
    80002738:	44450513          	add	a0,a0,1092 # 80010b78 <wait_lock>
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	54a080e7          	jalr	1354(ra) # 80000c86 <release>
      return -1;
    80002744:	59fd                	li	s3,-1
    80002746:	b79d                	j	800026ac <waitx+0xb0>

0000000080002748 <update_time>:

void update_time()
{
    80002748:	7179                	add	sp,sp,-48
    8000274a:	f406                	sd	ra,40(sp)
    8000274c:	f022                	sd	s0,32(sp)
    8000274e:	ec26                	sd	s1,24(sp)
    80002750:	e84a                	sd	s2,16(sp)
    80002752:	e44e                	sd	s3,8(sp)
    80002754:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002756:	0000f497          	auipc	s1,0xf
    8000275a:	83a48493          	add	s1,s1,-1990 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000275e:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002760:	00017917          	auipc	s2,0x17
    80002764:	c3090913          	add	s2,s2,-976 # 80019390 <tickslock>
    80002768:	a811                	j	8000277c <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	51a080e7          	jalr	1306(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002774:	21048493          	add	s1,s1,528
    80002778:	03248063          	beq	s1,s2,80002798 <update_time+0x50>
    acquire(&p->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	454080e7          	jalr	1108(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    80002786:	4c9c                	lw	a5,24(s1)
    80002788:	ff3791e3          	bne	a5,s3,8000276a <update_time+0x22>
      p->rtime++;
    8000278c:	1684a783          	lw	a5,360(s1)
    80002790:	2785                	addw	a5,a5,1
    80002792:	16f4a423          	sw	a5,360(s1)
    80002796:	bfd1                	j	8000276a <update_time+0x22>
  }
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6145                	add	sp,sp,48
    800027a4:	8082                	ret

00000000800027a6 <swtch>:
    800027a6:	00153023          	sd	ra,0(a0)
    800027aa:	00253423          	sd	sp,8(a0)
    800027ae:	e900                	sd	s0,16(a0)
    800027b0:	ed04                	sd	s1,24(a0)
    800027b2:	03253023          	sd	s2,32(a0)
    800027b6:	03353423          	sd	s3,40(a0)
    800027ba:	03453823          	sd	s4,48(a0)
    800027be:	03553c23          	sd	s5,56(a0)
    800027c2:	05653023          	sd	s6,64(a0)
    800027c6:	05753423          	sd	s7,72(a0)
    800027ca:	05853823          	sd	s8,80(a0)
    800027ce:	05953c23          	sd	s9,88(a0)
    800027d2:	07a53023          	sd	s10,96(a0)
    800027d6:	07b53423          	sd	s11,104(a0)
    800027da:	0005b083          	ld	ra,0(a1)
    800027de:	0085b103          	ld	sp,8(a1)
    800027e2:	6980                	ld	s0,16(a1)
    800027e4:	6d84                	ld	s1,24(a1)
    800027e6:	0205b903          	ld	s2,32(a1)
    800027ea:	0285b983          	ld	s3,40(a1)
    800027ee:	0305ba03          	ld	s4,48(a1)
    800027f2:	0385ba83          	ld	s5,56(a1)
    800027f6:	0405bb03          	ld	s6,64(a1)
    800027fa:	0485bb83          	ld	s7,72(a1)
    800027fe:	0505bc03          	ld	s8,80(a1)
    80002802:	0585bc83          	ld	s9,88(a1)
    80002806:	0605bd03          	ld	s10,96(a1)
    8000280a:	0685bd83          	ld	s11,104(a1)
    8000280e:	8082                	ret

0000000080002810 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002810:	1141                	add	sp,sp,-16
    80002812:	e406                	sd	ra,8(sp)
    80002814:	e022                	sd	s0,0(sp)
    80002816:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002818:	00006597          	auipc	a1,0x6
    8000281c:	ae058593          	add	a1,a1,-1312 # 800082f8 <states.0+0x30>
    80002820:	00017517          	auipc	a0,0x17
    80002824:	b7050513          	add	a0,a0,-1168 # 80019390 <tickslock>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	31a080e7          	jalr	794(ra) # 80000b42 <initlock>
}
    80002830:	60a2                	ld	ra,8(sp)
    80002832:	6402                	ld	s0,0(sp)
    80002834:	0141                	add	sp,sp,16
    80002836:	8082                	ret

0000000080002838 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002838:	1141                	add	sp,sp,-16
    8000283a:	e422                	sd	s0,8(sp)
    8000283c:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283e:	00003797          	auipc	a5,0x3
    80002842:	60278793          	add	a5,a5,1538 # 80005e40 <kernelvec>
    80002846:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000284a:	6422                	ld	s0,8(sp)
    8000284c:	0141                	add	sp,sp,16
    8000284e:	8082                	ret

0000000080002850 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002850:	1141                	add	sp,sp,-16
    80002852:	e406                	sd	ra,8(sp)
    80002854:	e022                	sd	s0,0(sp)
    80002856:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	14e080e7          	jalr	334(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002860:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002864:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002866:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000286a:	00004697          	auipc	a3,0x4
    8000286e:	79668693          	add	a3,a3,1942 # 80007000 <_trampoline>
    80002872:	00004717          	auipc	a4,0x4
    80002876:	78e70713          	add	a4,a4,1934 # 80007000 <_trampoline>
    8000287a:	8f15                	sub	a4,a4,a3
    8000287c:	040007b7          	lui	a5,0x4000
    80002880:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002882:	07b2                	sll	a5,a5,0xc
    80002884:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002886:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000288a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000288c:	18002673          	csrr	a2,satp
    80002890:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002892:	6d30                	ld	a2,88(a0)
    80002894:	6138                	ld	a4,64(a0)
    80002896:	6585                	lui	a1,0x1
    80002898:	972e                	add	a4,a4,a1
    8000289a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000289c:	6d38                	ld	a4,88(a0)
    8000289e:	00000617          	auipc	a2,0x0
    800028a2:	14260613          	add	a2,a2,322 # 800029e0 <usertrap>
    800028a6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028a8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028aa:	8612                	mv	a2,tp
    800028ac:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ae:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028b2:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028b6:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028be:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c0:	6f18                	ld	a4,24(a4)
    800028c2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028c6:	6928                	ld	a0,80(a0)
    800028c8:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028ca:	00004717          	auipc	a4,0x4
    800028ce:	7d270713          	add	a4,a4,2002 # 8000709c <userret>
    800028d2:	8f15                	sub	a4,a4,a3
    800028d4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028d6:	577d                	li	a4,-1
    800028d8:	177e                	sll	a4,a4,0x3f
    800028da:	8d59                	or	a0,a0,a4
    800028dc:	9782                	jalr	a5
}
    800028de:	60a2                	ld	ra,8(sp)
    800028e0:	6402                	ld	s0,0(sp)
    800028e2:	0141                	add	sp,sp,16
    800028e4:	8082                	ret

00000000800028e6 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028e6:	1101                	add	sp,sp,-32
    800028e8:	ec06                	sd	ra,24(sp)
    800028ea:	e822                	sd	s0,16(sp)
    800028ec:	e426                	sd	s1,8(sp)
    800028ee:	e04a                	sd	s2,0(sp)
    800028f0:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800028f2:	00017917          	auipc	s2,0x17
    800028f6:	a9e90913          	add	s2,s2,-1378 # 80019390 <tickslock>
    800028fa:	854a                	mv	a0,s2
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	2d6080e7          	jalr	726(ra) # 80000bd2 <acquire>
  ticks++;
    80002904:	00006497          	auipc	s1,0x6
    80002908:	fec48493          	add	s1,s1,-20 # 800088f0 <ticks>
    8000290c:	409c                	lw	a5,0(s1)
    8000290e:	2785                	addw	a5,a5,1
    80002910:	c09c                	sw	a5,0(s1)
  update_time();
    80002912:	00000097          	auipc	ra,0x0
    80002916:	e36080e7          	jalr	-458(ra) # 80002748 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000291a:	8526                	mv	a0,s1
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	7bc080e7          	jalr	1980(ra) # 800020d8 <wakeup>
  release(&tickslock);
    80002924:	854a                	mv	a0,s2
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	360080e7          	jalr	864(ra) # 80000c86 <release>
}
    8000292e:	60e2                	ld	ra,24(sp)
    80002930:	6442                	ld	s0,16(sp)
    80002932:	64a2                	ld	s1,8(sp)
    80002934:	6902                	ld	s2,0(sp)
    80002936:	6105                	add	sp,sp,32
    80002938:	8082                	ret

000000008000293a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293a:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    8000293e:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002940:	0807df63          	bgez	a5,800029de <devintr+0xa4>
{
    80002944:	1101                	add	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	e426                	sd	s1,8(sp)
    8000294c:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    8000294e:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002952:	46a5                	li	a3,9
    80002954:	00d70d63          	beq	a4,a3,8000296e <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    80002958:	577d                	li	a4,-1
    8000295a:	177e                	sll	a4,a4,0x3f
    8000295c:	0705                	add	a4,a4,1
    return 0;
    8000295e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002960:	04e78e63          	beq	a5,a4,800029bc <devintr+0x82>
  }
}
    80002964:	60e2                	ld	ra,24(sp)
    80002966:	6442                	ld	s0,16(sp)
    80002968:	64a2                	ld	s1,8(sp)
    8000296a:	6105                	add	sp,sp,32
    8000296c:	8082                	ret
    int irq = plic_claim();
    8000296e:	00003097          	auipc	ra,0x3
    80002972:	5da080e7          	jalr	1498(ra) # 80005f48 <plic_claim>
    80002976:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002978:	47a9                	li	a5,10
    8000297a:	02f50763          	beq	a0,a5,800029a8 <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    8000297e:	4785                	li	a5,1
    80002980:	02f50963          	beq	a0,a5,800029b2 <devintr+0x78>
    return 1;
    80002984:	4505                	li	a0,1
    else if (irq)
    80002986:	dcf9                	beqz	s1,80002964 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002988:	85a6                	mv	a1,s1
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	97650513          	add	a0,a0,-1674 # 80008300 <states.0+0x38>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf4080e7          	jalr	-1036(ra) # 80000586 <printf>
      plic_complete(irq);
    8000299a:	8526                	mv	a0,s1
    8000299c:	00003097          	auipc	ra,0x3
    800029a0:	5d0080e7          	jalr	1488(ra) # 80005f6c <plic_complete>
    return 1;
    800029a4:	4505                	li	a0,1
    800029a6:	bf7d                	j	80002964 <devintr+0x2a>
      uartintr();
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	fec080e7          	jalr	-20(ra) # 80000994 <uartintr>
    if (irq)
    800029b0:	b7ed                	j	8000299a <devintr+0x60>
      virtio_disk_intr();
    800029b2:	00004097          	auipc	ra,0x4
    800029b6:	a80080e7          	jalr	-1408(ra) # 80006432 <virtio_disk_intr>
    if (irq)
    800029ba:	b7c5                	j	8000299a <devintr+0x60>
    if (cpuid() == 0)
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	fbe080e7          	jalr	-66(ra) # 8000197a <cpuid>
    800029c4:	c901                	beqz	a0,800029d4 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ca:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029cc:	14479073          	csrw	sip,a5
    return 2;
    800029d0:	4509                	li	a0,2
    800029d2:	bf49                	j	80002964 <devintr+0x2a>
      clockintr();
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	f12080e7          	jalr	-238(ra) # 800028e6 <clockintr>
    800029dc:	b7ed                	j	800029c6 <devintr+0x8c>
}
    800029de:	8082                	ret

00000000800029e0 <usertrap>:
{
    800029e0:	1101                	add	sp,sp,-32
    800029e2:	ec06                	sd	ra,24(sp)
    800029e4:	e822                	sd	s0,16(sp)
    800029e6:	e426                	sd	s1,8(sp)
    800029e8:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	fbc080e7          	jalr	-68(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029f6:	1007f793          	and	a5,a5,256
    800029fa:	eba9                	bnez	a5,80002a4c <usertrap+0x6c>
    800029fc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029fe:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	14102773          	csrr	a4,sepc
    80002a04:	ef98                	sd	a4,24(a5)
  if ((which_dev = devintr()) == 0)
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	f34080e7          	jalr	-204(ra) # 8000293a <devintr>
    80002a0e:	c539                	beqz	a0,80002a5c <usertrap+0x7c>
  if (which_dev == 2)
    80002a10:	4789                	li	a5,2
    80002a12:	02f51263          	bne	a0,a5,80002a36 <usertrap+0x56>
    p->tickcount++; // Increment tick count
    80002a16:	1f44a783          	lw	a5,500(s1)
    80002a1a:	2785                	addw	a5,a5,1
    80002a1c:	0007871b          	sext.w	a4,a5
    80002a20:	1ef4aa23          	sw	a5,500(s1)
    if (p->alarmticks > 0 && p->tickcount >= p->alarmticks && !p->in_handler)
    80002a24:	1f04a783          	lw	a5,496(s1)
    80002a28:	00f05763          	blez	a5,80002a36 <usertrap+0x56>
    80002a2c:	00f74563          	blt	a4,a5,80002a36 <usertrap+0x56>
    80002a30:	2004a783          	lw	a5,512(s1)
    80002a34:	c3b5                	beqz	a5,80002a98 <usertrap+0xb8>
  if (p->killed)
    80002a36:	549c                	lw	a5,40(s1)
    80002a38:	ebb1                	bnez	a5,80002a8c <usertrap+0xac>
  usertrapret();
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	e16080e7          	jalr	-490(ra) # 80002850 <usertrapret>
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6105                	add	sp,sp,32
    80002a4a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	8d450513          	add	a0,a0,-1836 # 80008320 <states.0+0x58>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	ae8080e7          	jalr	-1304(ra) # 8000053c <panic>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a5c:	142025f3          	csrr	a1,scause
    printf("unexpected scause %p\n", r_scause());
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	8e050513          	add	a0,a0,-1824 # 80008340 <states.0+0x78>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b1e080e7          	jalr	-1250(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a74:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	8e050513          	add	a0,a0,-1824 # 80008358 <states.0+0x90>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b06080e7          	jalr	-1274(ra) # 80000586 <printf>
    p->killed = 1;
    80002a88:	4785                	li	a5,1
    80002a8a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a8c:	557d                	li	a0,-1
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	71a080e7          	jalr	1818(ra) # 800021a8 <exit>
    80002a96:	b755                	j	80002a3a <usertrap+0x5a>
      p->alarm_trapframe = kalloc(); // Allocate space for saving trapframe
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	04a080e7          	jalr	74(ra) # 80000ae2 <kalloc>
    80002aa0:	20a4b423          	sd	a0,520(s1)
      if (p->alarm_trapframe != 0)
    80002aa4:	d949                	beqz	a0,80002a36 <usertrap+0x56>
        *p->alarm_trapframe = *p->trapframe; // Save trapframe
    80002aa6:	6cbc                	ld	a5,88(s1)
    80002aa8:	12078813          	add	a6,a5,288
    80002aac:	638c                	ld	a1,0(a5)
    80002aae:	6790                	ld	a2,8(a5)
    80002ab0:	6b94                	ld	a3,16(a5)
    80002ab2:	6f98                	ld	a4,24(a5)
    80002ab4:	e10c                	sd	a1,0(a0)
    80002ab6:	e510                	sd	a2,8(a0)
    80002ab8:	e914                	sd	a3,16(a0)
    80002aba:	ed18                	sd	a4,24(a0)
    80002abc:	02078793          	add	a5,a5,32
    80002ac0:	02050513          	add	a0,a0,32
    80002ac4:	ff0794e3          	bne	a5,a6,80002aac <usertrap+0xcc>
        p->trapframe->epc = p->handler; // Set the handler address in epc
    80002ac8:	6cbc                	ld	a5,88(s1)
    80002aca:	1f84b703          	ld	a4,504(s1)
    80002ace:	ef98                	sd	a4,24(a5)
        p->in_handler = 1;              // Mark that we are in the handler
    80002ad0:	4785                	li	a5,1
    80002ad2:	20f4a023          	sw	a5,512(s1)
        p->tickcount = 0;               // Reset the tick counter
    80002ad6:	1e04aa23          	sw	zero,500(s1)
    80002ada:	bfb1                	j	80002a36 <usertrap+0x56>

0000000080002adc <kerneltrap>:
{
    80002adc:	7179                	add	sp,sp,-48
    80002ade:	f406                	sd	ra,40(sp)
    80002ae0:	f022                	sd	s0,32(sp)
    80002ae2:	ec26                	sd	s1,24(sp)
    80002ae4:	e84a                	sd	s2,16(sp)
    80002ae6:	e44e                	sd	s3,8(sp)
    80002ae8:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aea:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aee:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af2:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002af6:	1004f793          	and	a5,s1,256
    80002afa:	cb85                	beqz	a5,80002b2a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b00:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002b02:	ef85                	bnez	a5,80002b3a <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	e36080e7          	jalr	-458(ra) # 8000293a <devintr>
    80002b0c:	cd1d                	beqz	a0,80002b4a <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b0e:	4789                	li	a5,2
    80002b10:	06f50a63          	beq	a0,a5,80002b84 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b14:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b18:	10049073          	csrw	sstatus,s1
}
    80002b1c:	70a2                	ld	ra,40(sp)
    80002b1e:	7402                	ld	s0,32(sp)
    80002b20:	64e2                	ld	s1,24(sp)
    80002b22:	6942                	ld	s2,16(sp)
    80002b24:	69a2                	ld	s3,8(sp)
    80002b26:	6145                	add	sp,sp,48
    80002b28:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b2a:	00006517          	auipc	a0,0x6
    80002b2e:	84e50513          	add	a0,a0,-1970 # 80008378 <states.0+0xb0>
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	a0a080e7          	jalr	-1526(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	86650513          	add	a0,a0,-1946 # 800083a0 <states.0+0xd8>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	9fa080e7          	jalr	-1542(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002b4a:	85ce                	mv	a1,s3
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	87450513          	add	a0,a0,-1932 # 800083c0 <states.0+0xf8>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	a32080e7          	jalr	-1486(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b60:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	86c50513          	add	a0,a0,-1940 # 800083d0 <states.0+0x108>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a1a080e7          	jalr	-1510(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	87450513          	add	a0,a0,-1932 # 800083e8 <states.0+0x120>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	9c0080e7          	jalr	-1600(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	e22080e7          	jalr	-478(ra) # 800019a6 <myproc>
    80002b8c:	d541                	beqz	a0,80002b14 <kerneltrap+0x38>
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	e18080e7          	jalr	-488(ra) # 800019a6 <myproc>
    80002b96:	4d18                	lw	a4,24(a0)
    80002b98:	4791                	li	a5,4
    80002b9a:	f6f71de3          	bne	a4,a5,80002b14 <kerneltrap+0x38>
    yield();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	49a080e7          	jalr	1178(ra) # 80002038 <yield>
    80002ba6:	b7bd                	j	80002b14 <kerneltrap+0x38>

0000000080002ba8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ba8:	1101                	add	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	e426                	sd	s1,8(sp)
    80002bb0:	1000                	add	s0,sp,32
    80002bb2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	df2080e7          	jalr	-526(ra) # 800019a6 <myproc>
  switch (n)
    80002bbc:	4795                	li	a5,5
    80002bbe:	0497e163          	bltu	a5,s1,80002c00 <argraw+0x58>
    80002bc2:	048a                	sll	s1,s1,0x2
    80002bc4:	00006717          	auipc	a4,0x6
    80002bc8:	85c70713          	add	a4,a4,-1956 # 80008420 <states.0+0x158>
    80002bcc:	94ba                	add	s1,s1,a4
    80002bce:	409c                	lw	a5,0(s1)
    80002bd0:	97ba                	add	a5,a5,a4
    80002bd2:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002bd4:	6d3c                	ld	a5,88(a0)
    80002bd6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	add	sp,sp,32
    80002be0:	8082                	ret
    return p->trapframe->a1;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	7fa8                	ld	a0,120(a5)
    80002be6:	bfcd                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a2;
    80002be8:	6d3c                	ld	a5,88(a0)
    80002bea:	63c8                	ld	a0,128(a5)
    80002bec:	b7f5                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a3;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	67c8                	ld	a0,136(a5)
    80002bf2:	b7dd                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a4;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	6bc8                	ld	a0,144(a5)
    80002bf8:	b7c5                	j	80002bd8 <argraw+0x30>
    return p->trapframe->a5;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	6fc8                	ld	a0,152(a5)
    80002bfe:	bfe9                	j	80002bd8 <argraw+0x30>
  panic("argraw");
    80002c00:	00005517          	auipc	a0,0x5
    80002c04:	7f850513          	add	a0,a0,2040 # 800083f8 <states.0+0x130>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	934080e7          	jalr	-1740(ra) # 8000053c <panic>

0000000080002c10 <fetchaddr>:
{
    80002c10:	1101                	add	sp,sp,-32
    80002c12:	ec06                	sd	ra,24(sp)
    80002c14:	e822                	sd	s0,16(sp)
    80002c16:	e426                	sd	s1,8(sp)
    80002c18:	e04a                	sd	s2,0(sp)
    80002c1a:	1000                	add	s0,sp,32
    80002c1c:	84aa                	mv	s1,a0
    80002c1e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	d86080e7          	jalr	-634(ra) # 800019a6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c28:	653c                	ld	a5,72(a0)
    80002c2a:	02f4f863          	bgeu	s1,a5,80002c5a <fetchaddr+0x4a>
    80002c2e:	00848713          	add	a4,s1,8
    80002c32:	02e7e663          	bltu	a5,a4,80002c5e <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c36:	46a1                	li	a3,8
    80002c38:	8626                	mv	a2,s1
    80002c3a:	85ca                	mv	a1,s2
    80002c3c:	6928                	ld	a0,80(a0)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	ab4080e7          	jalr	-1356(ra) # 800016f2 <copyin>
    80002c46:	00a03533          	snez	a0,a0
    80002c4a:	40a00533          	neg	a0,a0
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	add	sp,sp,32
    80002c58:	8082                	ret
    return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bfcd                	j	80002c4e <fetchaddr+0x3e>
    80002c5e:	557d                	li	a0,-1
    80002c60:	b7fd                	j	80002c4e <fetchaddr+0x3e>

0000000080002c62 <fetchstr>:
{
    80002c62:	7179                	add	sp,sp,-48
    80002c64:	f406                	sd	ra,40(sp)
    80002c66:	f022                	sd	s0,32(sp)
    80002c68:	ec26                	sd	s1,24(sp)
    80002c6a:	e84a                	sd	s2,16(sp)
    80002c6c:	e44e                	sd	s3,8(sp)
    80002c6e:	1800                	add	s0,sp,48
    80002c70:	892a                	mv	s2,a0
    80002c72:	84ae                	mv	s1,a1
    80002c74:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	d30080e7          	jalr	-720(ra) # 800019a6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c7e:	86ce                	mv	a3,s3
    80002c80:	864a                	mv	a2,s2
    80002c82:	85a6                	mv	a1,s1
    80002c84:	6928                	ld	a0,80(a0)
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	afa080e7          	jalr	-1286(ra) # 80001780 <copyinstr>
    80002c8e:	00054e63          	bltz	a0,80002caa <fetchstr+0x48>
  return strlen(buf);
    80002c92:	8526                	mv	a0,s1
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	1b4080e7          	jalr	436(ra) # 80000e48 <strlen>
}
    80002c9c:	70a2                	ld	ra,40(sp)
    80002c9e:	7402                	ld	s0,32(sp)
    80002ca0:	64e2                	ld	s1,24(sp)
    80002ca2:	6942                	ld	s2,16(sp)
    80002ca4:	69a2                	ld	s3,8(sp)
    80002ca6:	6145                	add	sp,sp,48
    80002ca8:	8082                	ret
    return -1;
    80002caa:	557d                	li	a0,-1
    80002cac:	bfc5                	j	80002c9c <fetchstr+0x3a>

0000000080002cae <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002cae:	1101                	add	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	1000                	add	s0,sp,32
    80002cb8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	eee080e7          	jalr	-274(ra) # 80002ba8 <argraw>
    80002cc2:	c088                	sw	a0,0(s1)
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6105                	add	sp,sp,32
    80002ccc:	8082                	ret

0000000080002cce <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002cce:	1101                	add	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	e426                	sd	s1,8(sp)
    80002cd6:	1000                	add	s0,sp,32
    80002cd8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	ece080e7          	jalr	-306(ra) # 80002ba8 <argraw>
    80002ce2:	e088                	sd	a0,0(s1)
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	64a2                	ld	s1,8(sp)
    80002cea:	6105                	add	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002cee:	7179                	add	sp,sp,-48
    80002cf0:	f406                	sd	ra,40(sp)
    80002cf2:	f022                	sd	s0,32(sp)
    80002cf4:	ec26                	sd	s1,24(sp)
    80002cf6:	e84a                	sd	s2,16(sp)
    80002cf8:	1800                	add	s0,sp,48
    80002cfa:	84ae                	mv	s1,a1
    80002cfc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cfe:	fd840593          	add	a1,s0,-40
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	fcc080e7          	jalr	-52(ra) # 80002cce <argaddr>
  return fetchstr(addr, buf, max);
    80002d0a:	864a                	mv	a2,s2
    80002d0c:	85a6                	mv	a1,s1
    80002d0e:	fd843503          	ld	a0,-40(s0)
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f50080e7          	jalr	-176(ra) # 80002c62 <fetchstr>
}
    80002d1a:	70a2                	ld	ra,40(sp)
    80002d1c:	7402                	ld	s0,32(sp)
    80002d1e:	64e2                	ld	s1,24(sp)
    80002d20:	6942                	ld	s2,16(sp)
    80002d22:	6145                	add	sp,sp,48
    80002d24:	8082                	ret

0000000080002d26 <syscall>:
//     );
//     return result;
// }

void syscall(void)
{
    80002d26:	1101                	add	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c74080e7          	jalr	-908(ra) # 800019a6 <myproc>
    80002d3a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d3c:	05853903          	ld	s2,88(a0)
    80002d40:	0a893783          	ld	a5,168(s2)
    80002d44:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002d48:	37fd                	addw	a5,a5,-1
    80002d4a:	4761                	li	a4,24
    80002d4c:	02f76763          	bltu	a4,a5,80002d7a <syscall+0x54>
    80002d50:	00369713          	sll	a4,a3,0x3
    80002d54:	00005797          	auipc	a5,0x5
    80002d58:	6e478793          	add	a5,a5,1764 # 80008438 <syscalls>
    80002d5c:	97ba                	add	a5,a5,a4
    80002d5e:	6398                	ld	a4,0(a5)
    80002d60:	cf09                	beqz	a4,80002d7a <syscall+0x54>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num - 1]++;
    80002d62:	068a                	sll	a3,a3,0x2
    80002d64:	00d504b3          	add	s1,a0,a3
    80002d68:	1704a783          	lw	a5,368(s1)
    80002d6c:	2785                	addw	a5,a5,1
    80002d6e:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    80002d72:	9702                	jalr	a4
    80002d74:	06a93823          	sd	a0,112(s2)
    80002d78:	a839                	j	80002d96 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002d7a:	15848613          	add	a2,s1,344
    80002d7e:	588c                	lw	a1,48(s1)
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	68050513          	add	a0,a0,1664 # 80008400 <states.0+0x138>
    80002d88:	ffffd097          	auipc	ra,0xffffd
    80002d8c:	7fe080e7          	jalr	2046(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d90:	6cbc                	ld	a5,88(s1)
    80002d92:	577d                	li	a4,-1
    80002d94:	fbb8                	sd	a4,112(a5)
  }
}
    80002d96:	60e2                	ld	ra,24(sp)
    80002d98:	6442                	ld	s0,16(sp)
    80002d9a:	64a2                	ld	s1,8(sp)
    80002d9c:	6902                	ld	s2,0(sp)
    80002d9e:	6105                	add	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    80002da2:	1101                	add	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002daa:	fec40593          	add	a1,s0,-20
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	efe080e7          	jalr	-258(ra) # 80002cae <argint>
  exit(n);
    80002db8:	fec42503          	lw	a0,-20(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	3ec080e7          	jalr	1004(ra) # 800021a8 <exit>
  return 0; // not reached
}
    80002dc4:	4501                	li	a0,0
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	6105                	add	sp,sp,32
    80002dcc:	8082                	ret

0000000080002dce <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dce:	1141                	add	sp,sp,-16
    80002dd0:	e406                	sd	ra,8(sp)
    80002dd2:	e022                	sd	s0,0(sp)
    80002dd4:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	bd0080e7          	jalr	-1072(ra) # 800019a6 <myproc>
}
    80002dde:	5908                	lw	a0,48(a0)
    80002de0:	60a2                	ld	ra,8(sp)
    80002de2:	6402                	ld	s0,0(sp)
    80002de4:	0141                	add	sp,sp,16
    80002de6:	8082                	ret

0000000080002de8 <sys_fork>:

uint64
sys_fork(void)
{
    80002de8:	1141                	add	sp,sp,-16
    80002dea:	e406                	sd	ra,8(sp)
    80002dec:	e022                	sd	s0,0(sp)
    80002dee:	0800                	add	s0,sp,16
  return fork();
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	f92080e7          	jalr	-110(ra) # 80001d82 <fork>
}
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	add	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <sys_wait>:

uint64
sys_wait(void)
{
    80002e00:	1101                	add	sp,sp,-32
    80002e02:	ec06                	sd	ra,24(sp)
    80002e04:	e822                	sd	s0,16(sp)
    80002e06:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e08:	fe840593          	add	a1,s0,-24
    80002e0c:	4501                	li	a0,0
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	ec0080e7          	jalr	-320(ra) # 80002cce <argaddr>
  return wait(p);
    80002e16:	fe843503          	ld	a0,-24(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	540080e7          	jalr	1344(ra) # 8000235a <wait>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	add	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2a:	7179                	add	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e34:	fdc40593          	add	a1,s0,-36
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	e74080e7          	jalr	-396(ra) # 80002cae <argint>
  addr = myproc()->sz;
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	b64080e7          	jalr	-1180(ra) # 800019a6 <myproc>
    80002e4a:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e4c:	fdc42503          	lw	a0,-36(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	ed6080e7          	jalr	-298(ra) # 80001d26 <growproc>
    80002e58:	00054863          	bltz	a0,80002e68 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	70a2                	ld	ra,40(sp)
    80002e60:	7402                	ld	s0,32(sp)
    80002e62:	64e2                	ld	s1,24(sp)
    80002e64:	6145                	add	sp,sp,48
    80002e66:	8082                	ret
    return -1;
    80002e68:	54fd                	li	s1,-1
    80002e6a:	bfcd                	j	80002e5c <sys_sbrk+0x32>

0000000080002e6c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e6c:	7139                	add	sp,sp,-64
    80002e6e:	fc06                	sd	ra,56(sp)
    80002e70:	f822                	sd	s0,48(sp)
    80002e72:	f426                	sd	s1,40(sp)
    80002e74:	f04a                	sd	s2,32(sp)
    80002e76:	ec4e                	sd	s3,24(sp)
    80002e78:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e7a:	fcc40593          	add	a1,s0,-52
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	e2e080e7          	jalr	-466(ra) # 80002cae <argint>
  acquire(&tickslock);
    80002e88:	00016517          	auipc	a0,0x16
    80002e8c:	50850513          	add	a0,a0,1288 # 80019390 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	d42080e7          	jalr	-702(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002e98:	00006917          	auipc	s2,0x6
    80002e9c:	a5892903          	lw	s2,-1448(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80002ea0:	fcc42783          	lw	a5,-52(s0)
    80002ea4:	cf9d                	beqz	a5,80002ee2 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea6:	00016997          	auipc	s3,0x16
    80002eaa:	4ea98993          	add	s3,s3,1258 # 80019390 <tickslock>
    80002eae:	00006497          	auipc	s1,0x6
    80002eb2:	a4248493          	add	s1,s1,-1470 # 800088f0 <ticks>
    if (killed(myproc()))
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	af0080e7          	jalr	-1296(ra) # 800019a6 <myproc>
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	46a080e7          	jalr	1130(ra) # 80002328 <killed>
    80002ec6:	ed15                	bnez	a0,80002f02 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec8:	85ce                	mv	a1,s3
    80002eca:	8526                	mv	a0,s1
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	1a8080e7          	jalr	424(ra) # 80002074 <sleep>
  while (ticks - ticks0 < n)
    80002ed4:	409c                	lw	a5,0(s1)
    80002ed6:	412787bb          	subw	a5,a5,s2
    80002eda:	fcc42703          	lw	a4,-52(s0)
    80002ede:	fce7ece3          	bltu	a5,a4,80002eb6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ee2:	00016517          	auipc	a0,0x16
    80002ee6:	4ae50513          	add	a0,a0,1198 # 80019390 <tickslock>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	d9c080e7          	jalr	-612(ra) # 80000c86 <release>
  return 0;
    80002ef2:	4501                	li	a0,0
}
    80002ef4:	70e2                	ld	ra,56(sp)
    80002ef6:	7442                	ld	s0,48(sp)
    80002ef8:	74a2                	ld	s1,40(sp)
    80002efa:	7902                	ld	s2,32(sp)
    80002efc:	69e2                	ld	s3,24(sp)
    80002efe:	6121                	add	sp,sp,64
    80002f00:	8082                	ret
      release(&tickslock);
    80002f02:	00016517          	auipc	a0,0x16
    80002f06:	48e50513          	add	a0,a0,1166 # 80019390 <tickslock>
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	d7c080e7          	jalr	-644(ra) # 80000c86 <release>
      return -1;
    80002f12:	557d                	li	a0,-1
    80002f14:	b7c5                	j	80002ef4 <sys_sleep+0x88>

0000000080002f16 <sys_kill>:

uint64
sys_kill(void)
{
    80002f16:	1101                	add	sp,sp,-32
    80002f18:	ec06                	sd	ra,24(sp)
    80002f1a:	e822                	sd	s0,16(sp)
    80002f1c:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f1e:	fec40593          	add	a1,s0,-20
    80002f22:	4501                	li	a0,0
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	d8a080e7          	jalr	-630(ra) # 80002cae <argint>
  return kill(pid);
    80002f2c:	fec42503          	lw	a0,-20(s0)
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	35a080e7          	jalr	858(ra) # 8000228a <kill>
}
    80002f38:	60e2                	ld	ra,24(sp)
    80002f3a:	6442                	ld	s0,16(sp)
    80002f3c:	6105                	add	sp,sp,32
    80002f3e:	8082                	ret

0000000080002f40 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f40:	1101                	add	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f4a:	00016517          	auipc	a0,0x16
    80002f4e:	44650513          	add	a0,a0,1094 # 80019390 <tickslock>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	c80080e7          	jalr	-896(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002f5a:	00006497          	auipc	s1,0x6
    80002f5e:	9964a483          	lw	s1,-1642(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002f62:	00016517          	auipc	a0,0x16
    80002f66:	42e50513          	add	a0,a0,1070 # 80019390 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	d1c080e7          	jalr	-740(ra) # 80000c86 <release>
  return xticks;
}
    80002f72:	02049513          	sll	a0,s1,0x20
    80002f76:	9101                	srl	a0,a0,0x20
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	64a2                	ld	s1,8(sp)
    80002f7e:	6105                	add	sp,sp,32
    80002f80:	8082                	ret

0000000080002f82 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002f82:	7139                	add	sp,sp,-64
    80002f84:	fc06                	sd	ra,56(sp)
    80002f86:	f822                	sd	s0,48(sp)
    80002f88:	f426                	sd	s1,40(sp)
    80002f8a:	f04a                	sd	s2,32(sp)
    80002f8c:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002f8e:	fd840593          	add	a1,s0,-40
    80002f92:	4501                	li	a0,0
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	d3a080e7          	jalr	-710(ra) # 80002cce <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002f9c:	fd040593          	add	a1,s0,-48
    80002fa0:	4505                	li	a0,1
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	d2c080e7          	jalr	-724(ra) # 80002cce <argaddr>
  argaddr(2, &addr2);
    80002faa:	fc840593          	add	a1,s0,-56
    80002fae:	4509                	li	a0,2
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	d1e080e7          	jalr	-738(ra) # 80002cce <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80002fb8:	fc040613          	add	a2,s0,-64
    80002fbc:	fc440593          	add	a1,s0,-60
    80002fc0:	fd843503          	ld	a0,-40(s0)
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	638080e7          	jalr	1592(ra) # 800025fc <waitx>
    80002fcc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	9d8080e7          	jalr	-1576(ra) # 800019a6 <myproc>
    80002fd6:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fd8:	4691                	li	a3,4
    80002fda:	fc440613          	add	a2,s0,-60
    80002fde:	fd043583          	ld	a1,-48(s0)
    80002fe2:	6928                	ld	a0,80(a0)
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	682080e7          	jalr	1666(ra) # 80001666 <copyout>
    return -1;
    80002fec:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fee:	00054f63          	bltz	a0,8000300c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80002ff2:	4691                	li	a3,4
    80002ff4:	fc040613          	add	a2,s0,-64
    80002ff8:	fc843583          	ld	a1,-56(s0)
    80002ffc:	68a8                	ld	a0,80(s1)
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	668080e7          	jalr	1640(ra) # 80001666 <copyout>
    80003006:	00054a63          	bltz	a0,8000301a <sys_waitx+0x98>
    return -1;
  return ret;
    8000300a:	87ca                	mv	a5,s2
}
    8000300c:	853e                	mv	a0,a5
    8000300e:	70e2                	ld	ra,56(sp)
    80003010:	7442                	ld	s0,48(sp)
    80003012:	74a2                	ld	s1,40(sp)
    80003014:	7902                	ld	s2,32(sp)
    80003016:	6121                	add	sp,sp,64
    80003018:	8082                	ret
    return -1;
    8000301a:	57fd                	li	a5,-1
    8000301c:	bfc5                	j	8000300c <sys_waitx+0x8a>

000000008000301e <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    8000301e:	7179                	add	sp,sp,-48
    80003020:	f406                	sd	ra,40(sp)
    80003022:	f022                	sd	s0,32(sp)
    80003024:	ec26                	sd	s1,24(sp)
    80003026:	1800                	add	s0,sp,48
  int mask;
  struct proc *p = myproc(); // Get the current process
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	97e080e7          	jalr	-1666(ra) # 800019a6 <myproc>
    80003030:	84aa                	mv	s1,a0
  // {
  //   printf("%d %d\n",i, p->syscall_count[i]);
  // }
  

  argint(0, &mask);
    80003032:	fdc40593          	add	a1,s0,-36
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	c76080e7          	jalr	-906(ra) # 80002cae <argint>
  int count = 0;

  // Check the mask to determine which syscall to count
  for (int i = 0; i < 31; i++)
  {
    if (mask & (1 << i))
    80003040:	fdc42583          	lw	a1,-36(s0)
    80003044:	17048693          	add	a3,s1,368
  for (int i = 0; i < 31; i++)
    80003048:	4781                	li	a5,0
  int count = 0;
    8000304a:	4501                	li	a0,0
  for (int i = 0; i < 31; i++)
    8000304c:	467d                	li	a2,31
    8000304e:	a029                	j	80003058 <sys_getSysCount+0x3a>
    80003050:	2785                	addw	a5,a5,1
    80003052:	0691                	add	a3,a3,4
    80003054:	00c78963          	beq	a5,a2,80003066 <sys_getSysCount+0x48>
    if (mask & (1 << i))
    80003058:	40f5d73b          	sraw	a4,a1,a5
    8000305c:	8b05                	and	a4,a4,1
    8000305e:	db6d                	beqz	a4,80003050 <sys_getSysCount+0x32>
    {
      count += p->syscall_count[i-1]; // Add up the syscall counts
    80003060:	4298                	lw	a4,0(a3)
    80003062:	9d39                	addw	a0,a0,a4
    80003064:	b7f5                	j	80003050 <sys_getSysCount+0x32>
    }
  }

  return count;
}
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6145                	add	sp,sp,48
    8000306e:	8082                	ret

0000000080003070 <sys_sigalarm>:

// sysproc.c
uint64
sys_sigalarm(void)
{
    80003070:	1101                	add	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	1000                	add	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    80003078:	fec40593          	add	a1,s0,-20
    8000307c:	4501                	li	a0,0
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	c30080e7          	jalr	-976(ra) # 80002cae <argint>
    
  argaddr(1, &handler);
    80003086:	fe040593          	add	a1,s0,-32
    8000308a:	4505                	li	a0,1
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	c42080e7          	jalr	-958(ra) # 80002cce <argaddr>
    

  struct proc *p = myproc();
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	912080e7          	jalr	-1774(ra) # 800019a6 <myproc>
  p->alarmticks = interval;
    8000309c:	fec42783          	lw	a5,-20(s0)
    800030a0:	1ef52823          	sw	a5,496(a0)
  p->handler = handler;
    800030a4:	fe043783          	ld	a5,-32(s0)
    800030a8:	1ef53c23          	sd	a5,504(a0)
  // p->tickcount = 0;
  // p->in_handler = 0;

  return 0;
}
    800030ac:	4501                	li	a0,0
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	6105                	add	sp,sp,32
    800030b4:	8082                	ret

00000000800030b6 <sys_sigreturn>:

// sysproc.c
uint64
sys_sigreturn(void)
{
    800030b6:	1101                	add	sp,sp,-32
    800030b8:	ec06                	sd	ra,24(sp)
    800030ba:	e822                	sd	s0,16(sp)
    800030bc:	e426                	sd	s1,8(sp)
    800030be:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	8e6080e7          	jalr	-1818(ra) # 800019a6 <myproc>

  if (p->alarm_trapframe != 0) {
    800030c8:	20853683          	ld	a3,520(a0)
    800030cc:	c2a1                	beqz	a3,8000310c <sys_sigreturn+0x56>
    800030ce:	84aa                	mv	s1,a0
    *p->trapframe = *p->alarm_trapframe;  // Restore the saved trapframe
    800030d0:	87b6                	mv	a5,a3
    800030d2:	6d38                	ld	a4,88(a0)
    800030d4:	12068693          	add	a3,a3,288
    800030d8:	0007b803          	ld	a6,0(a5)
    800030dc:	6788                	ld	a0,8(a5)
    800030de:	6b8c                	ld	a1,16(a5)
    800030e0:	6f90                	ld	a2,24(a5)
    800030e2:	01073023          	sd	a6,0(a4)
    800030e6:	e708                	sd	a0,8(a4)
    800030e8:	eb0c                	sd	a1,16(a4)
    800030ea:	ef10                	sd	a2,24(a4)
    800030ec:	02078793          	add	a5,a5,32
    800030f0:	02070713          	add	a4,a4,32
    800030f4:	fed792e3          	bne	a5,a3,800030d8 <sys_sigreturn+0x22>
    kfree(p->alarm_trapframe);            // Free the allocated memory
    800030f8:	2084b503          	ld	a0,520(s1)
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	8e8080e7          	jalr	-1816(ra) # 800009e4 <kfree>
    p->alarm_trapframe = 0;               // Clear the saved trapframe pointer
    80003104:	2004b423          	sd	zero,520(s1)
    p->in_handler = 0;                    // Mark that we are out of the handler
    80003108:	2004a023          	sw	zero,512(s1)
  }

  return 0;
}
    8000310c:	4501                	li	a0,0
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6105                	add	sp,sp,32
    80003116:	8082                	ret

0000000080003118 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003118:	7179                	add	sp,sp,-48
    8000311a:	f406                	sd	ra,40(sp)
    8000311c:	f022                	sd	s0,32(sp)
    8000311e:	ec26                	sd	s1,24(sp)
    80003120:	e84a                	sd	s2,16(sp)
    80003122:	e44e                	sd	s3,8(sp)
    80003124:	e052                	sd	s4,0(sp)
    80003126:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003128:	00005597          	auipc	a1,0x5
    8000312c:	3e058593          	add	a1,a1,992 # 80008508 <syscalls+0xd0>
    80003130:	00016517          	auipc	a0,0x16
    80003134:	27850513          	add	a0,a0,632 # 800193a8 <bcache>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	a0a080e7          	jalr	-1526(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003140:	0001e797          	auipc	a5,0x1e
    80003144:	26878793          	add	a5,a5,616 # 800213a8 <bcache+0x8000>
    80003148:	0001e717          	auipc	a4,0x1e
    8000314c:	4c870713          	add	a4,a4,1224 # 80021610 <bcache+0x8268>
    80003150:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003154:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003158:	00016497          	auipc	s1,0x16
    8000315c:	26848493          	add	s1,s1,616 # 800193c0 <bcache+0x18>
    b->next = bcache.head.next;
    80003160:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003162:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003164:	00005a17          	auipc	s4,0x5
    80003168:	3aca0a13          	add	s4,s4,940 # 80008510 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000316c:	2b893783          	ld	a5,696(s2)
    80003170:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003172:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003176:	85d2                	mv	a1,s4
    80003178:	01048513          	add	a0,s1,16
    8000317c:	00001097          	auipc	ra,0x1
    80003180:	496080e7          	jalr	1174(ra) # 80004612 <initsleeplock>
    bcache.head.next->prev = b;
    80003184:	2b893783          	ld	a5,696(s2)
    80003188:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000318a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000318e:	45848493          	add	s1,s1,1112
    80003192:	fd349de3          	bne	s1,s3,8000316c <binit+0x54>
  }
}
    80003196:	70a2                	ld	ra,40(sp)
    80003198:	7402                	ld	s0,32(sp)
    8000319a:	64e2                	ld	s1,24(sp)
    8000319c:	6942                	ld	s2,16(sp)
    8000319e:	69a2                	ld	s3,8(sp)
    800031a0:	6a02                	ld	s4,0(sp)
    800031a2:	6145                	add	sp,sp,48
    800031a4:	8082                	ret

00000000800031a6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031a6:	7179                	add	sp,sp,-48
    800031a8:	f406                	sd	ra,40(sp)
    800031aa:	f022                	sd	s0,32(sp)
    800031ac:	ec26                	sd	s1,24(sp)
    800031ae:	e84a                	sd	s2,16(sp)
    800031b0:	e44e                	sd	s3,8(sp)
    800031b2:	1800                	add	s0,sp,48
    800031b4:	892a                	mv	s2,a0
    800031b6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031b8:	00016517          	auipc	a0,0x16
    800031bc:	1f050513          	add	a0,a0,496 # 800193a8 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	a12080e7          	jalr	-1518(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031c8:	0001e497          	auipc	s1,0x1e
    800031cc:	4984b483          	ld	s1,1176(s1) # 80021660 <bcache+0x82b8>
    800031d0:	0001e797          	auipc	a5,0x1e
    800031d4:	44078793          	add	a5,a5,1088 # 80021610 <bcache+0x8268>
    800031d8:	02f48f63          	beq	s1,a5,80003216 <bread+0x70>
    800031dc:	873e                	mv	a4,a5
    800031de:	a021                	j	800031e6 <bread+0x40>
    800031e0:	68a4                	ld	s1,80(s1)
    800031e2:	02e48a63          	beq	s1,a4,80003216 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031e6:	449c                	lw	a5,8(s1)
    800031e8:	ff279ce3          	bne	a5,s2,800031e0 <bread+0x3a>
    800031ec:	44dc                	lw	a5,12(s1)
    800031ee:	ff3799e3          	bne	a5,s3,800031e0 <bread+0x3a>
      b->refcnt++;
    800031f2:	40bc                	lw	a5,64(s1)
    800031f4:	2785                	addw	a5,a5,1
    800031f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031f8:	00016517          	auipc	a0,0x16
    800031fc:	1b050513          	add	a0,a0,432 # 800193a8 <bcache>
    80003200:	ffffe097          	auipc	ra,0xffffe
    80003204:	a86080e7          	jalr	-1402(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003208:	01048513          	add	a0,s1,16
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	440080e7          	jalr	1088(ra) # 8000464c <acquiresleep>
      return b;
    80003214:	a8b9                	j	80003272 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003216:	0001e497          	auipc	s1,0x1e
    8000321a:	4424b483          	ld	s1,1090(s1) # 80021658 <bcache+0x82b0>
    8000321e:	0001e797          	auipc	a5,0x1e
    80003222:	3f278793          	add	a5,a5,1010 # 80021610 <bcache+0x8268>
    80003226:	00f48863          	beq	s1,a5,80003236 <bread+0x90>
    8000322a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000322c:	40bc                	lw	a5,64(s1)
    8000322e:	cf81                	beqz	a5,80003246 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003230:	64a4                	ld	s1,72(s1)
    80003232:	fee49de3          	bne	s1,a4,8000322c <bread+0x86>
  panic("bget: no buffers");
    80003236:	00005517          	auipc	a0,0x5
    8000323a:	2e250513          	add	a0,a0,738 # 80008518 <syscalls+0xe0>
    8000323e:	ffffd097          	auipc	ra,0xffffd
    80003242:	2fe080e7          	jalr	766(ra) # 8000053c <panic>
      b->dev = dev;
    80003246:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000324a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000324e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003252:	4785                	li	a5,1
    80003254:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003256:	00016517          	auipc	a0,0x16
    8000325a:	15250513          	add	a0,a0,338 # 800193a8 <bcache>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	a28080e7          	jalr	-1496(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003266:	01048513          	add	a0,s1,16
    8000326a:	00001097          	auipc	ra,0x1
    8000326e:	3e2080e7          	jalr	994(ra) # 8000464c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003272:	409c                	lw	a5,0(s1)
    80003274:	cb89                	beqz	a5,80003286 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003276:	8526                	mv	a0,s1
    80003278:	70a2                	ld	ra,40(sp)
    8000327a:	7402                	ld	s0,32(sp)
    8000327c:	64e2                	ld	s1,24(sp)
    8000327e:	6942                	ld	s2,16(sp)
    80003280:	69a2                	ld	s3,8(sp)
    80003282:	6145                	add	sp,sp,48
    80003284:	8082                	ret
    virtio_disk_rw(b, 0);
    80003286:	4581                	li	a1,0
    80003288:	8526                	mv	a0,s1
    8000328a:	00003097          	auipc	ra,0x3
    8000328e:	f78080e7          	jalr	-136(ra) # 80006202 <virtio_disk_rw>
    b->valid = 1;
    80003292:	4785                	li	a5,1
    80003294:	c09c                	sw	a5,0(s1)
  return b;
    80003296:	b7c5                	j	80003276 <bread+0xd0>

0000000080003298 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003298:	1101                	add	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	1000                	add	s0,sp,32
    800032a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a4:	0541                	add	a0,a0,16
    800032a6:	00001097          	auipc	ra,0x1
    800032aa:	440080e7          	jalr	1088(ra) # 800046e6 <holdingsleep>
    800032ae:	cd01                	beqz	a0,800032c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032b0:	4585                	li	a1,1
    800032b2:	8526                	mv	a0,s1
    800032b4:	00003097          	auipc	ra,0x3
    800032b8:	f4e080e7          	jalr	-178(ra) # 80006202 <virtio_disk_rw>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6105                	add	sp,sp,32
    800032c4:	8082                	ret
    panic("bwrite");
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	26a50513          	add	a0,a0,618 # 80008530 <syscalls+0xf8>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	26e080e7          	jalr	622(ra) # 8000053c <panic>

00000000800032d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032d6:	1101                	add	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	e04a                	sd	s2,0(sp)
    800032e0:	1000                	add	s0,sp,32
    800032e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032e4:	01050913          	add	s2,a0,16
    800032e8:	854a                	mv	a0,s2
    800032ea:	00001097          	auipc	ra,0x1
    800032ee:	3fc080e7          	jalr	1020(ra) # 800046e6 <holdingsleep>
    800032f2:	c925                	beqz	a0,80003362 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800032f4:	854a                	mv	a0,s2
    800032f6:	00001097          	auipc	ra,0x1
    800032fa:	3ac080e7          	jalr	940(ra) # 800046a2 <releasesleep>

  acquire(&bcache.lock);
    800032fe:	00016517          	auipc	a0,0x16
    80003302:	0aa50513          	add	a0,a0,170 # 800193a8 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	8cc080e7          	jalr	-1844(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000330e:	40bc                	lw	a5,64(s1)
    80003310:	37fd                	addw	a5,a5,-1
    80003312:	0007871b          	sext.w	a4,a5
    80003316:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003318:	e71d                	bnez	a4,80003346 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000331a:	68b8                	ld	a4,80(s1)
    8000331c:	64bc                	ld	a5,72(s1)
    8000331e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003320:	68b8                	ld	a4,80(s1)
    80003322:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003324:	0001e797          	auipc	a5,0x1e
    80003328:	08478793          	add	a5,a5,132 # 800213a8 <bcache+0x8000>
    8000332c:	2b87b703          	ld	a4,696(a5)
    80003330:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003332:	0001e717          	auipc	a4,0x1e
    80003336:	2de70713          	add	a4,a4,734 # 80021610 <bcache+0x8268>
    8000333a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000333c:	2b87b703          	ld	a4,696(a5)
    80003340:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003342:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003346:	00016517          	auipc	a0,0x16
    8000334a:	06250513          	add	a0,a0,98 # 800193a8 <bcache>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	938080e7          	jalr	-1736(ra) # 80000c86 <release>
}
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	64a2                	ld	s1,8(sp)
    8000335c:	6902                	ld	s2,0(sp)
    8000335e:	6105                	add	sp,sp,32
    80003360:	8082                	ret
    panic("brelse");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	1d650513          	add	a0,a0,470 # 80008538 <syscalls+0x100>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d2080e7          	jalr	466(ra) # 8000053c <panic>

0000000080003372 <bpin>:

void
bpin(struct buf *b) {
    80003372:	1101                	add	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	add	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	00016517          	auipc	a0,0x16
    80003382:	02a50513          	add	a0,a0,42 # 800193a8 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	84c080e7          	jalr	-1972(ra) # 80000bd2 <acquire>
  b->refcnt++;
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	2785                	addw	a5,a5,1
    80003392:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003394:	00016517          	auipc	a0,0x16
    80003398:	01450513          	add	a0,a0,20 # 800193a8 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	8ea080e7          	jalr	-1814(ra) # 80000c86 <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	add	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bunpin>:

void
bunpin(struct buf *b) {
    800033ae:	1101                	add	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	1000                	add	s0,sp,32
    800033b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ba:	00016517          	auipc	a0,0x16
    800033be:	fee50513          	add	a0,a0,-18 # 800193a8 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	810080e7          	jalr	-2032(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	37fd                	addw	a5,a5,-1
    800033ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d0:	00016517          	auipc	a0,0x16
    800033d4:	fd850513          	add	a0,a0,-40 # 800193a8 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8ae080e7          	jalr	-1874(ra) # 80000c86 <release>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6105                	add	sp,sp,32
    800033e8:	8082                	ret

00000000800033ea <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ea:	1101                	add	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	e426                	sd	s1,8(sp)
    800033f2:	e04a                	sd	s2,0(sp)
    800033f4:	1000                	add	s0,sp,32
    800033f6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033f8:	00d5d59b          	srlw	a1,a1,0xd
    800033fc:	0001e797          	auipc	a5,0x1e
    80003400:	6887a783          	lw	a5,1672(a5) # 80021a84 <sb+0x1c>
    80003404:	9dbd                	addw	a1,a1,a5
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	da0080e7          	jalr	-608(ra) # 800031a6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000340e:	0074f713          	and	a4,s1,7
    80003412:	4785                	li	a5,1
    80003414:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003418:	14ce                	sll	s1,s1,0x33
    8000341a:	90d9                	srl	s1,s1,0x36
    8000341c:	00950733          	add	a4,a0,s1
    80003420:	05874703          	lbu	a4,88(a4)
    80003424:	00e7f6b3          	and	a3,a5,a4
    80003428:	c69d                	beqz	a3,80003456 <bfree+0x6c>
    8000342a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000342c:	94aa                	add	s1,s1,a0
    8000342e:	fff7c793          	not	a5,a5
    80003432:	8f7d                	and	a4,a4,a5
    80003434:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	0f6080e7          	jalr	246(ra) # 8000452e <log_write>
  brelse(bp);
    80003440:	854a                	mv	a0,s2
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e94080e7          	jalr	-364(ra) # 800032d6 <brelse>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6902                	ld	s2,0(sp)
    80003452:	6105                	add	sp,sp,32
    80003454:	8082                	ret
    panic("freeing free block");
    80003456:	00005517          	auipc	a0,0x5
    8000345a:	0ea50513          	add	a0,a0,234 # 80008540 <syscalls+0x108>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	0de080e7          	jalr	222(ra) # 8000053c <panic>

0000000080003466 <balloc>:
{
    80003466:	711d                	add	sp,sp,-96
    80003468:	ec86                	sd	ra,88(sp)
    8000346a:	e8a2                	sd	s0,80(sp)
    8000346c:	e4a6                	sd	s1,72(sp)
    8000346e:	e0ca                	sd	s2,64(sp)
    80003470:	fc4e                	sd	s3,56(sp)
    80003472:	f852                	sd	s4,48(sp)
    80003474:	f456                	sd	s5,40(sp)
    80003476:	f05a                	sd	s6,32(sp)
    80003478:	ec5e                	sd	s7,24(sp)
    8000347a:	e862                	sd	s8,16(sp)
    8000347c:	e466                	sd	s9,8(sp)
    8000347e:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003480:	0001e797          	auipc	a5,0x1e
    80003484:	5ec7a783          	lw	a5,1516(a5) # 80021a6c <sb+0x4>
    80003488:	cff5                	beqz	a5,80003584 <balloc+0x11e>
    8000348a:	8baa                	mv	s7,a0
    8000348c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000348e:	0001eb17          	auipc	s6,0x1e
    80003492:	5dab0b13          	add	s6,s6,1498 # 80021a68 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003496:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003498:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000349c:	6c89                	lui	s9,0x2
    8000349e:	a061                	j	80003526 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034a0:	97ca                	add	a5,a5,s2
    800034a2:	8e55                	or	a2,a2,a3
    800034a4:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034a8:	854a                	mv	a0,s2
    800034aa:	00001097          	auipc	ra,0x1
    800034ae:	084080e7          	jalr	132(ra) # 8000452e <log_write>
        brelse(bp);
    800034b2:	854a                	mv	a0,s2
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	e22080e7          	jalr	-478(ra) # 800032d6 <brelse>
  bp = bread(dev, bno);
    800034bc:	85a6                	mv	a1,s1
    800034be:	855e                	mv	a0,s7
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	ce6080e7          	jalr	-794(ra) # 800031a6 <bread>
    800034c8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034ca:	40000613          	li	a2,1024
    800034ce:	4581                	li	a1,0
    800034d0:	05850513          	add	a0,a0,88
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	7fa080e7          	jalr	2042(ra) # 80000cce <memset>
  log_write(bp);
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	050080e7          	jalr	80(ra) # 8000452e <log_write>
  brelse(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	dee080e7          	jalr	-530(ra) # 800032d6 <brelse>
}
    800034f0:	8526                	mv	a0,s1
    800034f2:	60e6                	ld	ra,88(sp)
    800034f4:	6446                	ld	s0,80(sp)
    800034f6:	64a6                	ld	s1,72(sp)
    800034f8:	6906                	ld	s2,64(sp)
    800034fa:	79e2                	ld	s3,56(sp)
    800034fc:	7a42                	ld	s4,48(sp)
    800034fe:	7aa2                	ld	s5,40(sp)
    80003500:	7b02                	ld	s6,32(sp)
    80003502:	6be2                	ld	s7,24(sp)
    80003504:	6c42                	ld	s8,16(sp)
    80003506:	6ca2                	ld	s9,8(sp)
    80003508:	6125                	add	sp,sp,96
    8000350a:	8082                	ret
    brelse(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	dc8080e7          	jalr	-568(ra) # 800032d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003516:	015c87bb          	addw	a5,s9,s5
    8000351a:	00078a9b          	sext.w	s5,a5
    8000351e:	004b2703          	lw	a4,4(s6)
    80003522:	06eaf163          	bgeu	s5,a4,80003584 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003526:	41fad79b          	sraw	a5,s5,0x1f
    8000352a:	0137d79b          	srlw	a5,a5,0x13
    8000352e:	015787bb          	addw	a5,a5,s5
    80003532:	40d7d79b          	sraw	a5,a5,0xd
    80003536:	01cb2583          	lw	a1,28(s6)
    8000353a:	9dbd                	addw	a1,a1,a5
    8000353c:	855e                	mv	a0,s7
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	c68080e7          	jalr	-920(ra) # 800031a6 <bread>
    80003546:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003548:	004b2503          	lw	a0,4(s6)
    8000354c:	000a849b          	sext.w	s1,s5
    80003550:	8762                	mv	a4,s8
    80003552:	faa4fde3          	bgeu	s1,a0,8000350c <balloc+0xa6>
      m = 1 << (bi % 8);
    80003556:	00777693          	and	a3,a4,7
    8000355a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000355e:	41f7579b          	sraw	a5,a4,0x1f
    80003562:	01d7d79b          	srlw	a5,a5,0x1d
    80003566:	9fb9                	addw	a5,a5,a4
    80003568:	4037d79b          	sraw	a5,a5,0x3
    8000356c:	00f90633          	add	a2,s2,a5
    80003570:	05864603          	lbu	a2,88(a2)
    80003574:	00c6f5b3          	and	a1,a3,a2
    80003578:	d585                	beqz	a1,800034a0 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000357a:	2705                	addw	a4,a4,1
    8000357c:	2485                	addw	s1,s1,1
    8000357e:	fd471ae3          	bne	a4,s4,80003552 <balloc+0xec>
    80003582:	b769                	j	8000350c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003584:	00005517          	auipc	a0,0x5
    80003588:	fd450513          	add	a0,a0,-44 # 80008558 <syscalls+0x120>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	ffa080e7          	jalr	-6(ra) # 80000586 <printf>
  return 0;
    80003594:	4481                	li	s1,0
    80003596:	bfa9                	j	800034f0 <balloc+0x8a>

0000000080003598 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003598:	7179                	add	sp,sp,-48
    8000359a:	f406                	sd	ra,40(sp)
    8000359c:	f022                	sd	s0,32(sp)
    8000359e:	ec26                	sd	s1,24(sp)
    800035a0:	e84a                	sd	s2,16(sp)
    800035a2:	e44e                	sd	s3,8(sp)
    800035a4:	e052                	sd	s4,0(sp)
    800035a6:	1800                	add	s0,sp,48
    800035a8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035aa:	47ad                	li	a5,11
    800035ac:	02b7e863          	bltu	a5,a1,800035dc <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035b0:	02059793          	sll	a5,a1,0x20
    800035b4:	01e7d593          	srl	a1,a5,0x1e
    800035b8:	00b504b3          	add	s1,a0,a1
    800035bc:	0504a903          	lw	s2,80(s1)
    800035c0:	06091e63          	bnez	s2,8000363c <bmap+0xa4>
      addr = balloc(ip->dev);
    800035c4:	4108                	lw	a0,0(a0)
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	ea0080e7          	jalr	-352(ra) # 80003466 <balloc>
    800035ce:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035d2:	06090563          	beqz	s2,8000363c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800035d6:	0524a823          	sw	s2,80(s1)
    800035da:	a08d                	j	8000363c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035dc:	ff45849b          	addw	s1,a1,-12
    800035e0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035e4:	0ff00793          	li	a5,255
    800035e8:	08e7e563          	bltu	a5,a4,80003672 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035ec:	08052903          	lw	s2,128(a0)
    800035f0:	00091d63          	bnez	s2,8000360a <bmap+0x72>
      addr = balloc(ip->dev);
    800035f4:	4108                	lw	a0,0(a0)
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	e70080e7          	jalr	-400(ra) # 80003466 <balloc>
    800035fe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003602:	02090d63          	beqz	s2,8000363c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003606:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000360a:	85ca                	mv	a1,s2
    8000360c:	0009a503          	lw	a0,0(s3)
    80003610:	00000097          	auipc	ra,0x0
    80003614:	b96080e7          	jalr	-1130(ra) # 800031a6 <bread>
    80003618:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000361a:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    8000361e:	02049713          	sll	a4,s1,0x20
    80003622:	01e75593          	srl	a1,a4,0x1e
    80003626:	00b784b3          	add	s1,a5,a1
    8000362a:	0004a903          	lw	s2,0(s1)
    8000362e:	02090063          	beqz	s2,8000364e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003632:	8552                	mv	a0,s4
    80003634:	00000097          	auipc	ra,0x0
    80003638:	ca2080e7          	jalr	-862(ra) # 800032d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000363c:	854a                	mv	a0,s2
    8000363e:	70a2                	ld	ra,40(sp)
    80003640:	7402                	ld	s0,32(sp)
    80003642:	64e2                	ld	s1,24(sp)
    80003644:	6942                	ld	s2,16(sp)
    80003646:	69a2                	ld	s3,8(sp)
    80003648:	6a02                	ld	s4,0(sp)
    8000364a:	6145                	add	sp,sp,48
    8000364c:	8082                	ret
      addr = balloc(ip->dev);
    8000364e:	0009a503          	lw	a0,0(s3)
    80003652:	00000097          	auipc	ra,0x0
    80003656:	e14080e7          	jalr	-492(ra) # 80003466 <balloc>
    8000365a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000365e:	fc090ae3          	beqz	s2,80003632 <bmap+0x9a>
        a[bn] = addr;
    80003662:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003666:	8552                	mv	a0,s4
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	ec6080e7          	jalr	-314(ra) # 8000452e <log_write>
    80003670:	b7c9                	j	80003632 <bmap+0x9a>
  panic("bmap: out of range");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	efe50513          	add	a0,a0,-258 # 80008570 <syscalls+0x138>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec2080e7          	jalr	-318(ra) # 8000053c <panic>

0000000080003682 <iget>:
{
    80003682:	7179                	add	sp,sp,-48
    80003684:	f406                	sd	ra,40(sp)
    80003686:	f022                	sd	s0,32(sp)
    80003688:	ec26                	sd	s1,24(sp)
    8000368a:	e84a                	sd	s2,16(sp)
    8000368c:	e44e                	sd	s3,8(sp)
    8000368e:	e052                	sd	s4,0(sp)
    80003690:	1800                	add	s0,sp,48
    80003692:	89aa                	mv	s3,a0
    80003694:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003696:	0001e517          	auipc	a0,0x1e
    8000369a:	3f250513          	add	a0,a0,1010 # 80021a88 <itable>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	534080e7          	jalr	1332(ra) # 80000bd2 <acquire>
  empty = 0;
    800036a6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036a8:	0001e497          	auipc	s1,0x1e
    800036ac:	3f848493          	add	s1,s1,1016 # 80021aa0 <itable+0x18>
    800036b0:	00020697          	auipc	a3,0x20
    800036b4:	e8068693          	add	a3,a3,-384 # 80023530 <log>
    800036b8:	a039                	j	800036c6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ba:	02090b63          	beqz	s2,800036f0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036be:	08848493          	add	s1,s1,136
    800036c2:	02d48a63          	beq	s1,a3,800036f6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036c6:	449c                	lw	a5,8(s1)
    800036c8:	fef059e3          	blez	a5,800036ba <iget+0x38>
    800036cc:	4098                	lw	a4,0(s1)
    800036ce:	ff3716e3          	bne	a4,s3,800036ba <iget+0x38>
    800036d2:	40d8                	lw	a4,4(s1)
    800036d4:	ff4713e3          	bne	a4,s4,800036ba <iget+0x38>
      ip->ref++;
    800036d8:	2785                	addw	a5,a5,1
    800036da:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036dc:	0001e517          	auipc	a0,0x1e
    800036e0:	3ac50513          	add	a0,a0,940 # 80021a88 <itable>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	5a2080e7          	jalr	1442(ra) # 80000c86 <release>
      return ip;
    800036ec:	8926                	mv	s2,s1
    800036ee:	a03d                	j	8000371c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036f0:	f7f9                	bnez	a5,800036be <iget+0x3c>
    800036f2:	8926                	mv	s2,s1
    800036f4:	b7e9                	j	800036be <iget+0x3c>
  if(empty == 0)
    800036f6:	02090c63          	beqz	s2,8000372e <iget+0xac>
  ip->dev = dev;
    800036fa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036fe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003702:	4785                	li	a5,1
    80003704:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003708:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000370c:	0001e517          	auipc	a0,0x1e
    80003710:	37c50513          	add	a0,a0,892 # 80021a88 <itable>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	572080e7          	jalr	1394(ra) # 80000c86 <release>
}
    8000371c:	854a                	mv	a0,s2
    8000371e:	70a2                	ld	ra,40(sp)
    80003720:	7402                	ld	s0,32(sp)
    80003722:	64e2                	ld	s1,24(sp)
    80003724:	6942                	ld	s2,16(sp)
    80003726:	69a2                	ld	s3,8(sp)
    80003728:	6a02                	ld	s4,0(sp)
    8000372a:	6145                	add	sp,sp,48
    8000372c:	8082                	ret
    panic("iget: no inodes");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	e5a50513          	add	a0,a0,-422 # 80008588 <syscalls+0x150>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e06080e7          	jalr	-506(ra) # 8000053c <panic>

000000008000373e <fsinit>:
fsinit(int dev) {
    8000373e:	7179                	add	sp,sp,-48
    80003740:	f406                	sd	ra,40(sp)
    80003742:	f022                	sd	s0,32(sp)
    80003744:	ec26                	sd	s1,24(sp)
    80003746:	e84a                	sd	s2,16(sp)
    80003748:	e44e                	sd	s3,8(sp)
    8000374a:	1800                	add	s0,sp,48
    8000374c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000374e:	4585                	li	a1,1
    80003750:	00000097          	auipc	ra,0x0
    80003754:	a56080e7          	jalr	-1450(ra) # 800031a6 <bread>
    80003758:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000375a:	0001e997          	auipc	s3,0x1e
    8000375e:	30e98993          	add	s3,s3,782 # 80021a68 <sb>
    80003762:	02000613          	li	a2,32
    80003766:	05850593          	add	a1,a0,88
    8000376a:	854e                	mv	a0,s3
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	5be080e7          	jalr	1470(ra) # 80000d2a <memmove>
  brelse(bp);
    80003774:	8526                	mv	a0,s1
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	b60080e7          	jalr	-1184(ra) # 800032d6 <brelse>
  if(sb.magic != FSMAGIC)
    8000377e:	0009a703          	lw	a4,0(s3)
    80003782:	102037b7          	lui	a5,0x10203
    80003786:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000378a:	02f71263          	bne	a4,a5,800037ae <fsinit+0x70>
  initlog(dev, &sb);
    8000378e:	0001e597          	auipc	a1,0x1e
    80003792:	2da58593          	add	a1,a1,730 # 80021a68 <sb>
    80003796:	854a                	mv	a0,s2
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	b2c080e7          	jalr	-1236(ra) # 800042c4 <initlog>
}
    800037a0:	70a2                	ld	ra,40(sp)
    800037a2:	7402                	ld	s0,32(sp)
    800037a4:	64e2                	ld	s1,24(sp)
    800037a6:	6942                	ld	s2,16(sp)
    800037a8:	69a2                	ld	s3,8(sp)
    800037aa:	6145                	add	sp,sp,48
    800037ac:	8082                	ret
    panic("invalid file system");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	dea50513          	add	a0,a0,-534 # 80008598 <syscalls+0x160>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d86080e7          	jalr	-634(ra) # 8000053c <panic>

00000000800037be <iinit>:
{
    800037be:	7179                	add	sp,sp,-48
    800037c0:	f406                	sd	ra,40(sp)
    800037c2:	f022                	sd	s0,32(sp)
    800037c4:	ec26                	sd	s1,24(sp)
    800037c6:	e84a                	sd	s2,16(sp)
    800037c8:	e44e                	sd	s3,8(sp)
    800037ca:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800037cc:	00005597          	auipc	a1,0x5
    800037d0:	de458593          	add	a1,a1,-540 # 800085b0 <syscalls+0x178>
    800037d4:	0001e517          	auipc	a0,0x1e
    800037d8:	2b450513          	add	a0,a0,692 # 80021a88 <itable>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	366080e7          	jalr	870(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037e4:	0001e497          	auipc	s1,0x1e
    800037e8:	2cc48493          	add	s1,s1,716 # 80021ab0 <itable+0x28>
    800037ec:	00020997          	auipc	s3,0x20
    800037f0:	d5498993          	add	s3,s3,-684 # 80023540 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037f4:	00005917          	auipc	s2,0x5
    800037f8:	dc490913          	add	s2,s2,-572 # 800085b8 <syscalls+0x180>
    800037fc:	85ca                	mv	a1,s2
    800037fe:	8526                	mv	a0,s1
    80003800:	00001097          	auipc	ra,0x1
    80003804:	e12080e7          	jalr	-494(ra) # 80004612 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003808:	08848493          	add	s1,s1,136
    8000380c:	ff3498e3          	bne	s1,s3,800037fc <iinit+0x3e>
}
    80003810:	70a2                	ld	ra,40(sp)
    80003812:	7402                	ld	s0,32(sp)
    80003814:	64e2                	ld	s1,24(sp)
    80003816:	6942                	ld	s2,16(sp)
    80003818:	69a2                	ld	s3,8(sp)
    8000381a:	6145                	add	sp,sp,48
    8000381c:	8082                	ret

000000008000381e <ialloc>:
{
    8000381e:	7139                	add	sp,sp,-64
    80003820:	fc06                	sd	ra,56(sp)
    80003822:	f822                	sd	s0,48(sp)
    80003824:	f426                	sd	s1,40(sp)
    80003826:	f04a                	sd	s2,32(sp)
    80003828:	ec4e                	sd	s3,24(sp)
    8000382a:	e852                	sd	s4,16(sp)
    8000382c:	e456                	sd	s5,8(sp)
    8000382e:	e05a                	sd	s6,0(sp)
    80003830:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003832:	0001e717          	auipc	a4,0x1e
    80003836:	24272703          	lw	a4,578(a4) # 80021a74 <sb+0xc>
    8000383a:	4785                	li	a5,1
    8000383c:	04e7f863          	bgeu	a5,a4,8000388c <ialloc+0x6e>
    80003840:	8aaa                	mv	s5,a0
    80003842:	8b2e                	mv	s6,a1
    80003844:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003846:	0001ea17          	auipc	s4,0x1e
    8000384a:	222a0a13          	add	s4,s4,546 # 80021a68 <sb>
    8000384e:	00495593          	srl	a1,s2,0x4
    80003852:	018a2783          	lw	a5,24(s4)
    80003856:	9dbd                	addw	a1,a1,a5
    80003858:	8556                	mv	a0,s5
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	94c080e7          	jalr	-1716(ra) # 800031a6 <bread>
    80003862:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003864:	05850993          	add	s3,a0,88
    80003868:	00f97793          	and	a5,s2,15
    8000386c:	079a                	sll	a5,a5,0x6
    8000386e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003870:	00099783          	lh	a5,0(s3)
    80003874:	cf9d                	beqz	a5,800038b2 <ialloc+0x94>
    brelse(bp);
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	a60080e7          	jalr	-1440(ra) # 800032d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000387e:	0905                	add	s2,s2,1
    80003880:	00ca2703          	lw	a4,12(s4)
    80003884:	0009079b          	sext.w	a5,s2
    80003888:	fce7e3e3          	bltu	a5,a4,8000384e <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000388c:	00005517          	auipc	a0,0x5
    80003890:	d3450513          	add	a0,a0,-716 # 800085c0 <syscalls+0x188>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	cf2080e7          	jalr	-782(ra) # 80000586 <printf>
  return 0;
    8000389c:	4501                	li	a0,0
}
    8000389e:	70e2                	ld	ra,56(sp)
    800038a0:	7442                	ld	s0,48(sp)
    800038a2:	74a2                	ld	s1,40(sp)
    800038a4:	7902                	ld	s2,32(sp)
    800038a6:	69e2                	ld	s3,24(sp)
    800038a8:	6a42                	ld	s4,16(sp)
    800038aa:	6aa2                	ld	s5,8(sp)
    800038ac:	6b02                	ld	s6,0(sp)
    800038ae:	6121                	add	sp,sp,64
    800038b0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038b2:	04000613          	li	a2,64
    800038b6:	4581                	li	a1,0
    800038b8:	854e                	mv	a0,s3
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	414080e7          	jalr	1044(ra) # 80000cce <memset>
      dip->type = type;
    800038c2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038c6:	8526                	mv	a0,s1
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	c66080e7          	jalr	-922(ra) # 8000452e <log_write>
      brelse(bp);
    800038d0:	8526                	mv	a0,s1
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	a04080e7          	jalr	-1532(ra) # 800032d6 <brelse>
      return iget(dev, inum);
    800038da:	0009059b          	sext.w	a1,s2
    800038de:	8556                	mv	a0,s5
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	da2080e7          	jalr	-606(ra) # 80003682 <iget>
    800038e8:	bf5d                	j	8000389e <ialloc+0x80>

00000000800038ea <iupdate>:
{
    800038ea:	1101                	add	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	e04a                	sd	s2,0(sp)
    800038f4:	1000                	add	s0,sp,32
    800038f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f8:	415c                	lw	a5,4(a0)
    800038fa:	0047d79b          	srlw	a5,a5,0x4
    800038fe:	0001e597          	auipc	a1,0x1e
    80003902:	1825a583          	lw	a1,386(a1) # 80021a80 <sb+0x18>
    80003906:	9dbd                	addw	a1,a1,a5
    80003908:	4108                	lw	a0,0(a0)
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	89c080e7          	jalr	-1892(ra) # 800031a6 <bread>
    80003912:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003914:	05850793          	add	a5,a0,88
    80003918:	40d8                	lw	a4,4(s1)
    8000391a:	8b3d                	and	a4,a4,15
    8000391c:	071a                	sll	a4,a4,0x6
    8000391e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003920:	04449703          	lh	a4,68(s1)
    80003924:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003928:	04649703          	lh	a4,70(s1)
    8000392c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003930:	04849703          	lh	a4,72(s1)
    80003934:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003938:	04a49703          	lh	a4,74(s1)
    8000393c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003940:	44f8                	lw	a4,76(s1)
    80003942:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003944:	03400613          	li	a2,52
    80003948:	05048593          	add	a1,s1,80
    8000394c:	00c78513          	add	a0,a5,12
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	3da080e7          	jalr	986(ra) # 80000d2a <memmove>
  log_write(bp);
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	bd4080e7          	jalr	-1068(ra) # 8000452e <log_write>
  brelse(bp);
    80003962:	854a                	mv	a0,s2
    80003964:	00000097          	auipc	ra,0x0
    80003968:	972080e7          	jalr	-1678(ra) # 800032d6 <brelse>
}
    8000396c:	60e2                	ld	ra,24(sp)
    8000396e:	6442                	ld	s0,16(sp)
    80003970:	64a2                	ld	s1,8(sp)
    80003972:	6902                	ld	s2,0(sp)
    80003974:	6105                	add	sp,sp,32
    80003976:	8082                	ret

0000000080003978 <idup>:
{
    80003978:	1101                	add	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	1000                	add	s0,sp,32
    80003982:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003984:	0001e517          	auipc	a0,0x1e
    80003988:	10450513          	add	a0,a0,260 # 80021a88 <itable>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	246080e7          	jalr	582(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003994:	449c                	lw	a5,8(s1)
    80003996:	2785                	addw	a5,a5,1
    80003998:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000399a:	0001e517          	auipc	a0,0x1e
    8000399e:	0ee50513          	add	a0,a0,238 # 80021a88 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	2e4080e7          	jalr	740(ra) # 80000c86 <release>
}
    800039aa:	8526                	mv	a0,s1
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6105                	add	sp,sp,32
    800039b4:	8082                	ret

00000000800039b6 <ilock>:
{
    800039b6:	1101                	add	sp,sp,-32
    800039b8:	ec06                	sd	ra,24(sp)
    800039ba:	e822                	sd	s0,16(sp)
    800039bc:	e426                	sd	s1,8(sp)
    800039be:	e04a                	sd	s2,0(sp)
    800039c0:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039c2:	c115                	beqz	a0,800039e6 <ilock+0x30>
    800039c4:	84aa                	mv	s1,a0
    800039c6:	451c                	lw	a5,8(a0)
    800039c8:	00f05f63          	blez	a5,800039e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039cc:	0541                	add	a0,a0,16
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	c7e080e7          	jalr	-898(ra) # 8000464c <acquiresleep>
  if(ip->valid == 0){
    800039d6:	40bc                	lw	a5,64(s1)
    800039d8:	cf99                	beqz	a5,800039f6 <ilock+0x40>
}
    800039da:	60e2                	ld	ra,24(sp)
    800039dc:	6442                	ld	s0,16(sp)
    800039de:	64a2                	ld	s1,8(sp)
    800039e0:	6902                	ld	s2,0(sp)
    800039e2:	6105                	add	sp,sp,32
    800039e4:	8082                	ret
    panic("ilock");
    800039e6:	00005517          	auipc	a0,0x5
    800039ea:	bf250513          	add	a0,a0,-1038 # 800085d8 <syscalls+0x1a0>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	b4e080e7          	jalr	-1202(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039f6:	40dc                	lw	a5,4(s1)
    800039f8:	0047d79b          	srlw	a5,a5,0x4
    800039fc:	0001e597          	auipc	a1,0x1e
    80003a00:	0845a583          	lw	a1,132(a1) # 80021a80 <sb+0x18>
    80003a04:	9dbd                	addw	a1,a1,a5
    80003a06:	4088                	lw	a0,0(s1)
    80003a08:	fffff097          	auipc	ra,0xfffff
    80003a0c:	79e080e7          	jalr	1950(ra) # 800031a6 <bread>
    80003a10:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a12:	05850593          	add	a1,a0,88
    80003a16:	40dc                	lw	a5,4(s1)
    80003a18:	8bbd                	and	a5,a5,15
    80003a1a:	079a                	sll	a5,a5,0x6
    80003a1c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a1e:	00059783          	lh	a5,0(a1)
    80003a22:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a26:	00259783          	lh	a5,2(a1)
    80003a2a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a2e:	00459783          	lh	a5,4(a1)
    80003a32:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a36:	00659783          	lh	a5,6(a1)
    80003a3a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a3e:	459c                	lw	a5,8(a1)
    80003a40:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a42:	03400613          	li	a2,52
    80003a46:	05b1                	add	a1,a1,12
    80003a48:	05048513          	add	a0,s1,80
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	2de080e7          	jalr	734(ra) # 80000d2a <memmove>
    brelse(bp);
    80003a54:	854a                	mv	a0,s2
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	880080e7          	jalr	-1920(ra) # 800032d6 <brelse>
    ip->valid = 1;
    80003a5e:	4785                	li	a5,1
    80003a60:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a62:	04449783          	lh	a5,68(s1)
    80003a66:	fbb5                	bnez	a5,800039da <ilock+0x24>
      panic("ilock: no type");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	b7850513          	add	a0,a0,-1160 # 800085e0 <syscalls+0x1a8>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	acc080e7          	jalr	-1332(ra) # 8000053c <panic>

0000000080003a78 <iunlock>:
{
    80003a78:	1101                	add	sp,sp,-32
    80003a7a:	ec06                	sd	ra,24(sp)
    80003a7c:	e822                	sd	s0,16(sp)
    80003a7e:	e426                	sd	s1,8(sp)
    80003a80:	e04a                	sd	s2,0(sp)
    80003a82:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a84:	c905                	beqz	a0,80003ab4 <iunlock+0x3c>
    80003a86:	84aa                	mv	s1,a0
    80003a88:	01050913          	add	s2,a0,16
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	c58080e7          	jalr	-936(ra) # 800046e6 <holdingsleep>
    80003a96:	cd19                	beqz	a0,80003ab4 <iunlock+0x3c>
    80003a98:	449c                	lw	a5,8(s1)
    80003a9a:	00f05d63          	blez	a5,80003ab4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	00001097          	auipc	ra,0x1
    80003aa4:	c02080e7          	jalr	-1022(ra) # 800046a2 <releasesleep>
}
    80003aa8:	60e2                	ld	ra,24(sp)
    80003aaa:	6442                	ld	s0,16(sp)
    80003aac:	64a2                	ld	s1,8(sp)
    80003aae:	6902                	ld	s2,0(sp)
    80003ab0:	6105                	add	sp,sp,32
    80003ab2:	8082                	ret
    panic("iunlock");
    80003ab4:	00005517          	auipc	a0,0x5
    80003ab8:	b3c50513          	add	a0,a0,-1220 # 800085f0 <syscalls+0x1b8>
    80003abc:	ffffd097          	auipc	ra,0xffffd
    80003ac0:	a80080e7          	jalr	-1408(ra) # 8000053c <panic>

0000000080003ac4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ac4:	7179                	add	sp,sp,-48
    80003ac6:	f406                	sd	ra,40(sp)
    80003ac8:	f022                	sd	s0,32(sp)
    80003aca:	ec26                	sd	s1,24(sp)
    80003acc:	e84a                	sd	s2,16(sp)
    80003ace:	e44e                	sd	s3,8(sp)
    80003ad0:	e052                	sd	s4,0(sp)
    80003ad2:	1800                	add	s0,sp,48
    80003ad4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ad6:	05050493          	add	s1,a0,80
    80003ada:	08050913          	add	s2,a0,128
    80003ade:	a021                	j	80003ae6 <itrunc+0x22>
    80003ae0:	0491                	add	s1,s1,4
    80003ae2:	01248d63          	beq	s1,s2,80003afc <itrunc+0x38>
    if(ip->addrs[i]){
    80003ae6:	408c                	lw	a1,0(s1)
    80003ae8:	dde5                	beqz	a1,80003ae0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aea:	0009a503          	lw	a0,0(s3)
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	8fc080e7          	jalr	-1796(ra) # 800033ea <bfree>
      ip->addrs[i] = 0;
    80003af6:	0004a023          	sw	zero,0(s1)
    80003afa:	b7dd                	j	80003ae0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003afc:	0809a583          	lw	a1,128(s3)
    80003b00:	e185                	bnez	a1,80003b20 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b02:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b06:	854e                	mv	a0,s3
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	de2080e7          	jalr	-542(ra) # 800038ea <iupdate>
}
    80003b10:	70a2                	ld	ra,40(sp)
    80003b12:	7402                	ld	s0,32(sp)
    80003b14:	64e2                	ld	s1,24(sp)
    80003b16:	6942                	ld	s2,16(sp)
    80003b18:	69a2                	ld	s3,8(sp)
    80003b1a:	6a02                	ld	s4,0(sp)
    80003b1c:	6145                	add	sp,sp,48
    80003b1e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b20:	0009a503          	lw	a0,0(s3)
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	682080e7          	jalr	1666(ra) # 800031a6 <bread>
    80003b2c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b2e:	05850493          	add	s1,a0,88
    80003b32:	45850913          	add	s2,a0,1112
    80003b36:	a021                	j	80003b3e <itrunc+0x7a>
    80003b38:	0491                	add	s1,s1,4
    80003b3a:	01248b63          	beq	s1,s2,80003b50 <itrunc+0x8c>
      if(a[j])
    80003b3e:	408c                	lw	a1,0(s1)
    80003b40:	dde5                	beqz	a1,80003b38 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b42:	0009a503          	lw	a0,0(s3)
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	8a4080e7          	jalr	-1884(ra) # 800033ea <bfree>
    80003b4e:	b7ed                	j	80003b38 <itrunc+0x74>
    brelse(bp);
    80003b50:	8552                	mv	a0,s4
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	784080e7          	jalr	1924(ra) # 800032d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b5a:	0809a583          	lw	a1,128(s3)
    80003b5e:	0009a503          	lw	a0,0(s3)
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	888080e7          	jalr	-1912(ra) # 800033ea <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b6a:	0809a023          	sw	zero,128(s3)
    80003b6e:	bf51                	j	80003b02 <itrunc+0x3e>

0000000080003b70 <iput>:
{
    80003b70:	1101                	add	sp,sp,-32
    80003b72:	ec06                	sd	ra,24(sp)
    80003b74:	e822                	sd	s0,16(sp)
    80003b76:	e426                	sd	s1,8(sp)
    80003b78:	e04a                	sd	s2,0(sp)
    80003b7a:	1000                	add	s0,sp,32
    80003b7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b7e:	0001e517          	auipc	a0,0x1e
    80003b82:	f0a50513          	add	a0,a0,-246 # 80021a88 <itable>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	04c080e7          	jalr	76(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b8e:	4498                	lw	a4,8(s1)
    80003b90:	4785                	li	a5,1
    80003b92:	02f70363          	beq	a4,a5,80003bb8 <iput+0x48>
  ip->ref--;
    80003b96:	449c                	lw	a5,8(s1)
    80003b98:	37fd                	addw	a5,a5,-1
    80003b9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b9c:	0001e517          	auipc	a0,0x1e
    80003ba0:	eec50513          	add	a0,a0,-276 # 80021a88 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	0e2080e7          	jalr	226(ra) # 80000c86 <release>
}
    80003bac:	60e2                	ld	ra,24(sp)
    80003bae:	6442                	ld	s0,16(sp)
    80003bb0:	64a2                	ld	s1,8(sp)
    80003bb2:	6902                	ld	s2,0(sp)
    80003bb4:	6105                	add	sp,sp,32
    80003bb6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bb8:	40bc                	lw	a5,64(s1)
    80003bba:	dff1                	beqz	a5,80003b96 <iput+0x26>
    80003bbc:	04a49783          	lh	a5,74(s1)
    80003bc0:	fbf9                	bnez	a5,80003b96 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bc2:	01048913          	add	s2,s1,16
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	a84080e7          	jalr	-1404(ra) # 8000464c <acquiresleep>
    release(&itable.lock);
    80003bd0:	0001e517          	auipc	a0,0x1e
    80003bd4:	eb850513          	add	a0,a0,-328 # 80021a88 <itable>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	0ae080e7          	jalr	174(ra) # 80000c86 <release>
    itrunc(ip);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	ee2080e7          	jalr	-286(ra) # 80003ac4 <itrunc>
    ip->type = 0;
    80003bea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	cfa080e7          	jalr	-774(ra) # 800038ea <iupdate>
    ip->valid = 0;
    80003bf8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	aa4080e7          	jalr	-1372(ra) # 800046a2 <releasesleep>
    acquire(&itable.lock);
    80003c06:	0001e517          	auipc	a0,0x1e
    80003c0a:	e8250513          	add	a0,a0,-382 # 80021a88 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	fc4080e7          	jalr	-60(ra) # 80000bd2 <acquire>
    80003c16:	b741                	j	80003b96 <iput+0x26>

0000000080003c18 <iunlockput>:
{
    80003c18:	1101                	add	sp,sp,-32
    80003c1a:	ec06                	sd	ra,24(sp)
    80003c1c:	e822                	sd	s0,16(sp)
    80003c1e:	e426                	sd	s1,8(sp)
    80003c20:	1000                	add	s0,sp,32
    80003c22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	e54080e7          	jalr	-428(ra) # 80003a78 <iunlock>
  iput(ip);
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	00000097          	auipc	ra,0x0
    80003c32:	f42080e7          	jalr	-190(ra) # 80003b70 <iput>
}
    80003c36:	60e2                	ld	ra,24(sp)
    80003c38:	6442                	ld	s0,16(sp)
    80003c3a:	64a2                	ld	s1,8(sp)
    80003c3c:	6105                	add	sp,sp,32
    80003c3e:	8082                	ret

0000000080003c40 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c40:	1141                	add	sp,sp,-16
    80003c42:	e422                	sd	s0,8(sp)
    80003c44:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003c46:	411c                	lw	a5,0(a0)
    80003c48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c4a:	415c                	lw	a5,4(a0)
    80003c4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c4e:	04451783          	lh	a5,68(a0)
    80003c52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c56:	04a51783          	lh	a5,74(a0)
    80003c5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c5e:	04c56783          	lwu	a5,76(a0)
    80003c62:	e99c                	sd	a5,16(a1)
}
    80003c64:	6422                	ld	s0,8(sp)
    80003c66:	0141                	add	sp,sp,16
    80003c68:	8082                	ret

0000000080003c6a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6a:	457c                	lw	a5,76(a0)
    80003c6c:	0ed7e963          	bltu	a5,a3,80003d5e <readi+0xf4>
{
    80003c70:	7159                	add	sp,sp,-112
    80003c72:	f486                	sd	ra,104(sp)
    80003c74:	f0a2                	sd	s0,96(sp)
    80003c76:	eca6                	sd	s1,88(sp)
    80003c78:	e8ca                	sd	s2,80(sp)
    80003c7a:	e4ce                	sd	s3,72(sp)
    80003c7c:	e0d2                	sd	s4,64(sp)
    80003c7e:	fc56                	sd	s5,56(sp)
    80003c80:	f85a                	sd	s6,48(sp)
    80003c82:	f45e                	sd	s7,40(sp)
    80003c84:	f062                	sd	s8,32(sp)
    80003c86:	ec66                	sd	s9,24(sp)
    80003c88:	e86a                	sd	s10,16(sp)
    80003c8a:	e46e                	sd	s11,8(sp)
    80003c8c:	1880                	add	s0,sp,112
    80003c8e:	8b2a                	mv	s6,a0
    80003c90:	8bae                	mv	s7,a1
    80003c92:	8a32                	mv	s4,a2
    80003c94:	84b6                	mv	s1,a3
    80003c96:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c98:	9f35                	addw	a4,a4,a3
    return 0;
    80003c9a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c9c:	0ad76063          	bltu	a4,a3,80003d3c <readi+0xd2>
  if(off + n > ip->size)
    80003ca0:	00e7f463          	bgeu	a5,a4,80003ca8 <readi+0x3e>
    n = ip->size - off;
    80003ca4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca8:	0a0a8963          	beqz	s5,80003d5a <readi+0xf0>
    80003cac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cae:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cb2:	5c7d                	li	s8,-1
    80003cb4:	a82d                	j	80003cee <readi+0x84>
    80003cb6:	020d1d93          	sll	s11,s10,0x20
    80003cba:	020ddd93          	srl	s11,s11,0x20
    80003cbe:	05890613          	add	a2,s2,88
    80003cc2:	86ee                	mv	a3,s11
    80003cc4:	963a                	add	a2,a2,a4
    80003cc6:	85d2                	mv	a1,s4
    80003cc8:	855e                	mv	a0,s7
    80003cca:	ffffe097          	auipc	ra,0xffffe
    80003cce:	7d6080e7          	jalr	2006(ra) # 800024a0 <either_copyout>
    80003cd2:	05850d63          	beq	a0,s8,80003d2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	5fe080e7          	jalr	1534(ra) # 800032d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce0:	013d09bb          	addw	s3,s10,s3
    80003ce4:	009d04bb          	addw	s1,s10,s1
    80003ce8:	9a6e                	add	s4,s4,s11
    80003cea:	0559f763          	bgeu	s3,s5,80003d38 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cee:	00a4d59b          	srlw	a1,s1,0xa
    80003cf2:	855a                	mv	a0,s6
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	8a4080e7          	jalr	-1884(ra) # 80003598 <bmap>
    80003cfc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d00:	cd85                	beqz	a1,80003d38 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d02:	000b2503          	lw	a0,0(s6)
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	4a0080e7          	jalr	1184(ra) # 800031a6 <bread>
    80003d0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d10:	3ff4f713          	and	a4,s1,1023
    80003d14:	40ec87bb          	subw	a5,s9,a4
    80003d18:	413a86bb          	subw	a3,s5,s3
    80003d1c:	8d3e                	mv	s10,a5
    80003d1e:	2781                	sext.w	a5,a5
    80003d20:	0006861b          	sext.w	a2,a3
    80003d24:	f8f679e3          	bgeu	a2,a5,80003cb6 <readi+0x4c>
    80003d28:	8d36                	mv	s10,a3
    80003d2a:	b771                	j	80003cb6 <readi+0x4c>
      brelse(bp);
    80003d2c:	854a                	mv	a0,s2
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	5a8080e7          	jalr	1448(ra) # 800032d6 <brelse>
      tot = -1;
    80003d36:	59fd                	li	s3,-1
  }
  return tot;
    80003d38:	0009851b          	sext.w	a0,s3
}
    80003d3c:	70a6                	ld	ra,104(sp)
    80003d3e:	7406                	ld	s0,96(sp)
    80003d40:	64e6                	ld	s1,88(sp)
    80003d42:	6946                	ld	s2,80(sp)
    80003d44:	69a6                	ld	s3,72(sp)
    80003d46:	6a06                	ld	s4,64(sp)
    80003d48:	7ae2                	ld	s5,56(sp)
    80003d4a:	7b42                	ld	s6,48(sp)
    80003d4c:	7ba2                	ld	s7,40(sp)
    80003d4e:	7c02                	ld	s8,32(sp)
    80003d50:	6ce2                	ld	s9,24(sp)
    80003d52:	6d42                	ld	s10,16(sp)
    80003d54:	6da2                	ld	s11,8(sp)
    80003d56:	6165                	add	sp,sp,112
    80003d58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d5a:	89d6                	mv	s3,s5
    80003d5c:	bff1                	j	80003d38 <readi+0xce>
    return 0;
    80003d5e:	4501                	li	a0,0
}
    80003d60:	8082                	ret

0000000080003d62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d62:	457c                	lw	a5,76(a0)
    80003d64:	10d7e863          	bltu	a5,a3,80003e74 <writei+0x112>
{
    80003d68:	7159                	add	sp,sp,-112
    80003d6a:	f486                	sd	ra,104(sp)
    80003d6c:	f0a2                	sd	s0,96(sp)
    80003d6e:	eca6                	sd	s1,88(sp)
    80003d70:	e8ca                	sd	s2,80(sp)
    80003d72:	e4ce                	sd	s3,72(sp)
    80003d74:	e0d2                	sd	s4,64(sp)
    80003d76:	fc56                	sd	s5,56(sp)
    80003d78:	f85a                	sd	s6,48(sp)
    80003d7a:	f45e                	sd	s7,40(sp)
    80003d7c:	f062                	sd	s8,32(sp)
    80003d7e:	ec66                	sd	s9,24(sp)
    80003d80:	e86a                	sd	s10,16(sp)
    80003d82:	e46e                	sd	s11,8(sp)
    80003d84:	1880                	add	s0,sp,112
    80003d86:	8aaa                	mv	s5,a0
    80003d88:	8bae                	mv	s7,a1
    80003d8a:	8a32                	mv	s4,a2
    80003d8c:	8936                	mv	s2,a3
    80003d8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d90:	00e687bb          	addw	a5,a3,a4
    80003d94:	0ed7e263          	bltu	a5,a3,80003e78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d98:	00043737          	lui	a4,0x43
    80003d9c:	0ef76063          	bltu	a4,a5,80003e7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da0:	0c0b0863          	beqz	s6,80003e70 <writei+0x10e>
    80003da4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003daa:	5c7d                	li	s8,-1
    80003dac:	a091                	j	80003df0 <writei+0x8e>
    80003dae:	020d1d93          	sll	s11,s10,0x20
    80003db2:	020ddd93          	srl	s11,s11,0x20
    80003db6:	05848513          	add	a0,s1,88
    80003dba:	86ee                	mv	a3,s11
    80003dbc:	8652                	mv	a2,s4
    80003dbe:	85de                	mv	a1,s7
    80003dc0:	953a                	add	a0,a0,a4
    80003dc2:	ffffe097          	auipc	ra,0xffffe
    80003dc6:	734080e7          	jalr	1844(ra) # 800024f6 <either_copyin>
    80003dca:	07850263          	beq	a0,s8,80003e2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dce:	8526                	mv	a0,s1
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	75e080e7          	jalr	1886(ra) # 8000452e <log_write>
    brelse(bp);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	4fc080e7          	jalr	1276(ra) # 800032d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de2:	013d09bb          	addw	s3,s10,s3
    80003de6:	012d093b          	addw	s2,s10,s2
    80003dea:	9a6e                	add	s4,s4,s11
    80003dec:	0569f663          	bgeu	s3,s6,80003e38 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003df0:	00a9559b          	srlw	a1,s2,0xa
    80003df4:	8556                	mv	a0,s5
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	7a2080e7          	jalr	1954(ra) # 80003598 <bmap>
    80003dfe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e02:	c99d                	beqz	a1,80003e38 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e04:	000aa503          	lw	a0,0(s5)
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	39e080e7          	jalr	926(ra) # 800031a6 <bread>
    80003e10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e12:	3ff97713          	and	a4,s2,1023
    80003e16:	40ec87bb          	subw	a5,s9,a4
    80003e1a:	413b06bb          	subw	a3,s6,s3
    80003e1e:	8d3e                	mv	s10,a5
    80003e20:	2781                	sext.w	a5,a5
    80003e22:	0006861b          	sext.w	a2,a3
    80003e26:	f8f674e3          	bgeu	a2,a5,80003dae <writei+0x4c>
    80003e2a:	8d36                	mv	s10,a3
    80003e2c:	b749                	j	80003dae <writei+0x4c>
      brelse(bp);
    80003e2e:	8526                	mv	a0,s1
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	4a6080e7          	jalr	1190(ra) # 800032d6 <brelse>
  }

  if(off > ip->size)
    80003e38:	04caa783          	lw	a5,76(s5)
    80003e3c:	0127f463          	bgeu	a5,s2,80003e44 <writei+0xe2>
    ip->size = off;
    80003e40:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e44:	8556                	mv	a0,s5
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	aa4080e7          	jalr	-1372(ra) # 800038ea <iupdate>

  return tot;
    80003e4e:	0009851b          	sext.w	a0,s3
}
    80003e52:	70a6                	ld	ra,104(sp)
    80003e54:	7406                	ld	s0,96(sp)
    80003e56:	64e6                	ld	s1,88(sp)
    80003e58:	6946                	ld	s2,80(sp)
    80003e5a:	69a6                	ld	s3,72(sp)
    80003e5c:	6a06                	ld	s4,64(sp)
    80003e5e:	7ae2                	ld	s5,56(sp)
    80003e60:	7b42                	ld	s6,48(sp)
    80003e62:	7ba2                	ld	s7,40(sp)
    80003e64:	7c02                	ld	s8,32(sp)
    80003e66:	6ce2                	ld	s9,24(sp)
    80003e68:	6d42                	ld	s10,16(sp)
    80003e6a:	6da2                	ld	s11,8(sp)
    80003e6c:	6165                	add	sp,sp,112
    80003e6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e70:	89da                	mv	s3,s6
    80003e72:	bfc9                	j	80003e44 <writei+0xe2>
    return -1;
    80003e74:	557d                	li	a0,-1
}
    80003e76:	8082                	ret
    return -1;
    80003e78:	557d                	li	a0,-1
    80003e7a:	bfe1                	j	80003e52 <writei+0xf0>
    return -1;
    80003e7c:	557d                	li	a0,-1
    80003e7e:	bfd1                	j	80003e52 <writei+0xf0>

0000000080003e80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e80:	1141                	add	sp,sp,-16
    80003e82:	e406                	sd	ra,8(sp)
    80003e84:	e022                	sd	s0,0(sp)
    80003e86:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e88:	4639                	li	a2,14
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	f14080e7          	jalr	-236(ra) # 80000d9e <strncmp>
}
    80003e92:	60a2                	ld	ra,8(sp)
    80003e94:	6402                	ld	s0,0(sp)
    80003e96:	0141                	add	sp,sp,16
    80003e98:	8082                	ret

0000000080003e9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e9a:	7139                	add	sp,sp,-64
    80003e9c:	fc06                	sd	ra,56(sp)
    80003e9e:	f822                	sd	s0,48(sp)
    80003ea0:	f426                	sd	s1,40(sp)
    80003ea2:	f04a                	sd	s2,32(sp)
    80003ea4:	ec4e                	sd	s3,24(sp)
    80003ea6:	e852                	sd	s4,16(sp)
    80003ea8:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eaa:	04451703          	lh	a4,68(a0)
    80003eae:	4785                	li	a5,1
    80003eb0:	00f71a63          	bne	a4,a5,80003ec4 <dirlookup+0x2a>
    80003eb4:	892a                	mv	s2,a0
    80003eb6:	89ae                	mv	s3,a1
    80003eb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eba:	457c                	lw	a5,76(a0)
    80003ebc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ebe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec0:	e79d                	bnez	a5,80003eee <dirlookup+0x54>
    80003ec2:	a8a5                	j	80003f3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ec4:	00004517          	auipc	a0,0x4
    80003ec8:	73450513          	add	a0,a0,1844 # 800085f8 <syscalls+0x1c0>
    80003ecc:	ffffc097          	auipc	ra,0xffffc
    80003ed0:	670080e7          	jalr	1648(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003ed4:	00004517          	auipc	a0,0x4
    80003ed8:	73c50513          	add	a0,a0,1852 # 80008610 <syscalls+0x1d8>
    80003edc:	ffffc097          	auipc	ra,0xffffc
    80003ee0:	660080e7          	jalr	1632(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee4:	24c1                	addw	s1,s1,16
    80003ee6:	04c92783          	lw	a5,76(s2)
    80003eea:	04f4f763          	bgeu	s1,a5,80003f38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eee:	4741                	li	a4,16
    80003ef0:	86a6                	mv	a3,s1
    80003ef2:	fc040613          	add	a2,s0,-64
    80003ef6:	4581                	li	a1,0
    80003ef8:	854a                	mv	a0,s2
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	d70080e7          	jalr	-656(ra) # 80003c6a <readi>
    80003f02:	47c1                	li	a5,16
    80003f04:	fcf518e3          	bne	a0,a5,80003ed4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f08:	fc045783          	lhu	a5,-64(s0)
    80003f0c:	dfe1                	beqz	a5,80003ee4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f0e:	fc240593          	add	a1,s0,-62
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	f6c080e7          	jalr	-148(ra) # 80003e80 <namecmp>
    80003f1c:	f561                	bnez	a0,80003ee4 <dirlookup+0x4a>
      if(poff)
    80003f1e:	000a0463          	beqz	s4,80003f26 <dirlookup+0x8c>
        *poff = off;
    80003f22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f26:	fc045583          	lhu	a1,-64(s0)
    80003f2a:	00092503          	lw	a0,0(s2)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	754080e7          	jalr	1876(ra) # 80003682 <iget>
    80003f36:	a011                	j	80003f3a <dirlookup+0xa0>
  return 0;
    80003f38:	4501                	li	a0,0
}
    80003f3a:	70e2                	ld	ra,56(sp)
    80003f3c:	7442                	ld	s0,48(sp)
    80003f3e:	74a2                	ld	s1,40(sp)
    80003f40:	7902                	ld	s2,32(sp)
    80003f42:	69e2                	ld	s3,24(sp)
    80003f44:	6a42                	ld	s4,16(sp)
    80003f46:	6121                	add	sp,sp,64
    80003f48:	8082                	ret

0000000080003f4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f4a:	711d                	add	sp,sp,-96
    80003f4c:	ec86                	sd	ra,88(sp)
    80003f4e:	e8a2                	sd	s0,80(sp)
    80003f50:	e4a6                	sd	s1,72(sp)
    80003f52:	e0ca                	sd	s2,64(sp)
    80003f54:	fc4e                	sd	s3,56(sp)
    80003f56:	f852                	sd	s4,48(sp)
    80003f58:	f456                	sd	s5,40(sp)
    80003f5a:	f05a                	sd	s6,32(sp)
    80003f5c:	ec5e                	sd	s7,24(sp)
    80003f5e:	e862                	sd	s8,16(sp)
    80003f60:	e466                	sd	s9,8(sp)
    80003f62:	1080                	add	s0,sp,96
    80003f64:	84aa                	mv	s1,a0
    80003f66:	8b2e                	mv	s6,a1
    80003f68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f6a:	00054703          	lbu	a4,0(a0)
    80003f6e:	02f00793          	li	a5,47
    80003f72:	02f70263          	beq	a4,a5,80003f96 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f76:	ffffe097          	auipc	ra,0xffffe
    80003f7a:	a30080e7          	jalr	-1488(ra) # 800019a6 <myproc>
    80003f7e:	15053503          	ld	a0,336(a0)
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	9f6080e7          	jalr	-1546(ra) # 80003978 <idup>
    80003f8a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f8c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f90:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f92:	4b85                	li	s7,1
    80003f94:	a875                	j	80004050 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003f96:	4585                	li	a1,1
    80003f98:	4505                	li	a0,1
    80003f9a:	fffff097          	auipc	ra,0xfffff
    80003f9e:	6e8080e7          	jalr	1768(ra) # 80003682 <iget>
    80003fa2:	8a2a                	mv	s4,a0
    80003fa4:	b7e5                	j	80003f8c <namex+0x42>
      iunlockput(ip);
    80003fa6:	8552                	mv	a0,s4
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	c70080e7          	jalr	-912(ra) # 80003c18 <iunlockput>
      return 0;
    80003fb0:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fb2:	8552                	mv	a0,s4
    80003fb4:	60e6                	ld	ra,88(sp)
    80003fb6:	6446                	ld	s0,80(sp)
    80003fb8:	64a6                	ld	s1,72(sp)
    80003fba:	6906                	ld	s2,64(sp)
    80003fbc:	79e2                	ld	s3,56(sp)
    80003fbe:	7a42                	ld	s4,48(sp)
    80003fc0:	7aa2                	ld	s5,40(sp)
    80003fc2:	7b02                	ld	s6,32(sp)
    80003fc4:	6be2                	ld	s7,24(sp)
    80003fc6:	6c42                	ld	s8,16(sp)
    80003fc8:	6ca2                	ld	s9,8(sp)
    80003fca:	6125                	add	sp,sp,96
    80003fcc:	8082                	ret
      iunlock(ip);
    80003fce:	8552                	mv	a0,s4
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	aa8080e7          	jalr	-1368(ra) # 80003a78 <iunlock>
      return ip;
    80003fd8:	bfe9                	j	80003fb2 <namex+0x68>
      iunlockput(ip);
    80003fda:	8552                	mv	a0,s4
    80003fdc:	00000097          	auipc	ra,0x0
    80003fe0:	c3c080e7          	jalr	-964(ra) # 80003c18 <iunlockput>
      return 0;
    80003fe4:	8a4e                	mv	s4,s3
    80003fe6:	b7f1                	j	80003fb2 <namex+0x68>
  len = path - s;
    80003fe8:	40998633          	sub	a2,s3,s1
    80003fec:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ff0:	099c5863          	bge	s8,s9,80004080 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003ff4:	4639                	li	a2,14
    80003ff6:	85a6                	mv	a1,s1
    80003ff8:	8556                	mv	a0,s5
    80003ffa:	ffffd097          	auipc	ra,0xffffd
    80003ffe:	d30080e7          	jalr	-720(ra) # 80000d2a <memmove>
    80004002:	84ce                	mv	s1,s3
  while(*path == '/')
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	01279763          	bne	a5,s2,80004016 <namex+0xcc>
    path++;
    8000400c:	0485                	add	s1,s1,1
  while(*path == '/')
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	ff278de3          	beq	a5,s2,8000400c <namex+0xc2>
    ilock(ip);
    80004016:	8552                	mv	a0,s4
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	99e080e7          	jalr	-1634(ra) # 800039b6 <ilock>
    if(ip->type != T_DIR){
    80004020:	044a1783          	lh	a5,68(s4)
    80004024:	f97791e3          	bne	a5,s7,80003fa6 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004028:	000b0563          	beqz	s6,80004032 <namex+0xe8>
    8000402c:	0004c783          	lbu	a5,0(s1)
    80004030:	dfd9                	beqz	a5,80003fce <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004032:	4601                	li	a2,0
    80004034:	85d6                	mv	a1,s5
    80004036:	8552                	mv	a0,s4
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	e62080e7          	jalr	-414(ra) # 80003e9a <dirlookup>
    80004040:	89aa                	mv	s3,a0
    80004042:	dd41                	beqz	a0,80003fda <namex+0x90>
    iunlockput(ip);
    80004044:	8552                	mv	a0,s4
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	bd2080e7          	jalr	-1070(ra) # 80003c18 <iunlockput>
    ip = next;
    8000404e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	01279763          	bne	a5,s2,80004062 <namex+0x118>
    path++;
    80004058:	0485                	add	s1,s1,1
  while(*path == '/')
    8000405a:	0004c783          	lbu	a5,0(s1)
    8000405e:	ff278de3          	beq	a5,s2,80004058 <namex+0x10e>
  if(*path == 0)
    80004062:	cb9d                	beqz	a5,80004098 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004064:	0004c783          	lbu	a5,0(s1)
    80004068:	89a6                	mv	s3,s1
  len = path - s;
    8000406a:	4c81                	li	s9,0
    8000406c:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    8000406e:	01278963          	beq	a5,s2,80004080 <namex+0x136>
    80004072:	dbbd                	beqz	a5,80003fe8 <namex+0x9e>
    path++;
    80004074:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004076:	0009c783          	lbu	a5,0(s3)
    8000407a:	ff279ce3          	bne	a5,s2,80004072 <namex+0x128>
    8000407e:	b7ad                	j	80003fe8 <namex+0x9e>
    memmove(name, s, len);
    80004080:	2601                	sext.w	a2,a2
    80004082:	85a6                	mv	a1,s1
    80004084:	8556                	mv	a0,s5
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	ca4080e7          	jalr	-860(ra) # 80000d2a <memmove>
    name[len] = 0;
    8000408e:	9cd6                	add	s9,s9,s5
    80004090:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004094:	84ce                	mv	s1,s3
    80004096:	b7bd                	j	80004004 <namex+0xba>
  if(nameiparent){
    80004098:	f00b0de3          	beqz	s6,80003fb2 <namex+0x68>
    iput(ip);
    8000409c:	8552                	mv	a0,s4
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	ad2080e7          	jalr	-1326(ra) # 80003b70 <iput>
    return 0;
    800040a6:	4a01                	li	s4,0
    800040a8:	b729                	j	80003fb2 <namex+0x68>

00000000800040aa <dirlink>:
{
    800040aa:	7139                	add	sp,sp,-64
    800040ac:	fc06                	sd	ra,56(sp)
    800040ae:	f822                	sd	s0,48(sp)
    800040b0:	f426                	sd	s1,40(sp)
    800040b2:	f04a                	sd	s2,32(sp)
    800040b4:	ec4e                	sd	s3,24(sp)
    800040b6:	e852                	sd	s4,16(sp)
    800040b8:	0080                	add	s0,sp,64
    800040ba:	892a                	mv	s2,a0
    800040bc:	8a2e                	mv	s4,a1
    800040be:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040c0:	4601                	li	a2,0
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	dd8080e7          	jalr	-552(ra) # 80003e9a <dirlookup>
    800040ca:	e93d                	bnez	a0,80004140 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040cc:	04c92483          	lw	s1,76(s2)
    800040d0:	c49d                	beqz	s1,800040fe <dirlink+0x54>
    800040d2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d4:	4741                	li	a4,16
    800040d6:	86a6                	mv	a3,s1
    800040d8:	fc040613          	add	a2,s0,-64
    800040dc:	4581                	li	a1,0
    800040de:	854a                	mv	a0,s2
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	b8a080e7          	jalr	-1142(ra) # 80003c6a <readi>
    800040e8:	47c1                	li	a5,16
    800040ea:	06f51163          	bne	a0,a5,8000414c <dirlink+0xa2>
    if(de.inum == 0)
    800040ee:	fc045783          	lhu	a5,-64(s0)
    800040f2:	c791                	beqz	a5,800040fe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f4:	24c1                	addw	s1,s1,16
    800040f6:	04c92783          	lw	a5,76(s2)
    800040fa:	fcf4ede3          	bltu	s1,a5,800040d4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040fe:	4639                	li	a2,14
    80004100:	85d2                	mv	a1,s4
    80004102:	fc240513          	add	a0,s0,-62
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	cd4080e7          	jalr	-812(ra) # 80000dda <strncpy>
  de.inum = inum;
    8000410e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004112:	4741                	li	a4,16
    80004114:	86a6                	mv	a3,s1
    80004116:	fc040613          	add	a2,s0,-64
    8000411a:	4581                	li	a1,0
    8000411c:	854a                	mv	a0,s2
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	c44080e7          	jalr	-956(ra) # 80003d62 <writei>
    80004126:	1541                	add	a0,a0,-16
    80004128:	00a03533          	snez	a0,a0
    8000412c:	40a00533          	neg	a0,a0
}
    80004130:	70e2                	ld	ra,56(sp)
    80004132:	7442                	ld	s0,48(sp)
    80004134:	74a2                	ld	s1,40(sp)
    80004136:	7902                	ld	s2,32(sp)
    80004138:	69e2                	ld	s3,24(sp)
    8000413a:	6a42                	ld	s4,16(sp)
    8000413c:	6121                	add	sp,sp,64
    8000413e:	8082                	ret
    iput(ip);
    80004140:	00000097          	auipc	ra,0x0
    80004144:	a30080e7          	jalr	-1488(ra) # 80003b70 <iput>
    return -1;
    80004148:	557d                	li	a0,-1
    8000414a:	b7dd                	j	80004130 <dirlink+0x86>
      panic("dirlink read");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	4d450513          	add	a0,a0,1236 # 80008620 <syscalls+0x1e8>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	3e8080e7          	jalr	1000(ra) # 8000053c <panic>

000000008000415c <namei>:

struct inode*
namei(char *path)
{
    8000415c:	1101                	add	sp,sp,-32
    8000415e:	ec06                	sd	ra,24(sp)
    80004160:	e822                	sd	s0,16(sp)
    80004162:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004164:	fe040613          	add	a2,s0,-32
    80004168:	4581                	li	a1,0
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	de0080e7          	jalr	-544(ra) # 80003f4a <namex>
}
    80004172:	60e2                	ld	ra,24(sp)
    80004174:	6442                	ld	s0,16(sp)
    80004176:	6105                	add	sp,sp,32
    80004178:	8082                	ret

000000008000417a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000417a:	1141                	add	sp,sp,-16
    8000417c:	e406                	sd	ra,8(sp)
    8000417e:	e022                	sd	s0,0(sp)
    80004180:	0800                	add	s0,sp,16
    80004182:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004184:	4585                	li	a1,1
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	dc4080e7          	jalr	-572(ra) # 80003f4a <namex>
}
    8000418e:	60a2                	ld	ra,8(sp)
    80004190:	6402                	ld	s0,0(sp)
    80004192:	0141                	add	sp,sp,16
    80004194:	8082                	ret

0000000080004196 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004196:	1101                	add	sp,sp,-32
    80004198:	ec06                	sd	ra,24(sp)
    8000419a:	e822                	sd	s0,16(sp)
    8000419c:	e426                	sd	s1,8(sp)
    8000419e:	e04a                	sd	s2,0(sp)
    800041a0:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041a2:	0001f917          	auipc	s2,0x1f
    800041a6:	38e90913          	add	s2,s2,910 # 80023530 <log>
    800041aa:	01892583          	lw	a1,24(s2)
    800041ae:	02892503          	lw	a0,40(s2)
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	ff4080e7          	jalr	-12(ra) # 800031a6 <bread>
    800041ba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041bc:	02c92603          	lw	a2,44(s2)
    800041c0:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	00c05f63          	blez	a2,800041e0 <write_head+0x4a>
    800041c6:	0001f717          	auipc	a4,0x1f
    800041ca:	39a70713          	add	a4,a4,922 # 80023560 <log+0x30>
    800041ce:	87aa                	mv	a5,a0
    800041d0:	060a                	sll	a2,a2,0x2
    800041d2:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800041d4:	4314                	lw	a3,0(a4)
    800041d6:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800041d8:	0711                	add	a4,a4,4
    800041da:	0791                	add	a5,a5,4
    800041dc:	fec79ce3          	bne	a5,a2,800041d4 <write_head+0x3e>
  }
  bwrite(buf);
    800041e0:	8526                	mv	a0,s1
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	0b6080e7          	jalr	182(ra) # 80003298 <bwrite>
  brelse(buf);
    800041ea:	8526                	mv	a0,s1
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	0ea080e7          	jalr	234(ra) # 800032d6 <brelse>
}
    800041f4:	60e2                	ld	ra,24(sp)
    800041f6:	6442                	ld	s0,16(sp)
    800041f8:	64a2                	ld	s1,8(sp)
    800041fa:	6902                	ld	s2,0(sp)
    800041fc:	6105                	add	sp,sp,32
    800041fe:	8082                	ret

0000000080004200 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004200:	0001f797          	auipc	a5,0x1f
    80004204:	35c7a783          	lw	a5,860(a5) # 8002355c <log+0x2c>
    80004208:	0af05d63          	blez	a5,800042c2 <install_trans+0xc2>
{
    8000420c:	7139                	add	sp,sp,-64
    8000420e:	fc06                	sd	ra,56(sp)
    80004210:	f822                	sd	s0,48(sp)
    80004212:	f426                	sd	s1,40(sp)
    80004214:	f04a                	sd	s2,32(sp)
    80004216:	ec4e                	sd	s3,24(sp)
    80004218:	e852                	sd	s4,16(sp)
    8000421a:	e456                	sd	s5,8(sp)
    8000421c:	e05a                	sd	s6,0(sp)
    8000421e:	0080                	add	s0,sp,64
    80004220:	8b2a                	mv	s6,a0
    80004222:	0001fa97          	auipc	s5,0x1f
    80004226:	33ea8a93          	add	s5,s5,830 # 80023560 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000422c:	0001f997          	auipc	s3,0x1f
    80004230:	30498993          	add	s3,s3,772 # 80023530 <log>
    80004234:	a00d                	j	80004256 <install_trans+0x56>
    brelse(lbuf);
    80004236:	854a                	mv	a0,s2
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	09e080e7          	jalr	158(ra) # 800032d6 <brelse>
    brelse(dbuf);
    80004240:	8526                	mv	a0,s1
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	094080e7          	jalr	148(ra) # 800032d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424a:	2a05                	addw	s4,s4,1
    8000424c:	0a91                	add	s5,s5,4
    8000424e:	02c9a783          	lw	a5,44(s3)
    80004252:	04fa5e63          	bge	s4,a5,800042ae <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004256:	0189a583          	lw	a1,24(s3)
    8000425a:	014585bb          	addw	a1,a1,s4
    8000425e:	2585                	addw	a1,a1,1
    80004260:	0289a503          	lw	a0,40(s3)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	f42080e7          	jalr	-190(ra) # 800031a6 <bread>
    8000426c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000426e:	000aa583          	lw	a1,0(s5)
    80004272:	0289a503          	lw	a0,40(s3)
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	f30080e7          	jalr	-208(ra) # 800031a6 <bread>
    8000427e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004280:	40000613          	li	a2,1024
    80004284:	05890593          	add	a1,s2,88
    80004288:	05850513          	add	a0,a0,88
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	a9e080e7          	jalr	-1378(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	002080e7          	jalr	2(ra) # 80003298 <bwrite>
    if(recovering == 0)
    8000429e:	f80b1ce3          	bnez	s6,80004236 <install_trans+0x36>
      bunpin(dbuf);
    800042a2:	8526                	mv	a0,s1
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	10a080e7          	jalr	266(ra) # 800033ae <bunpin>
    800042ac:	b769                	j	80004236 <install_trans+0x36>
}
    800042ae:	70e2                	ld	ra,56(sp)
    800042b0:	7442                	ld	s0,48(sp)
    800042b2:	74a2                	ld	s1,40(sp)
    800042b4:	7902                	ld	s2,32(sp)
    800042b6:	69e2                	ld	s3,24(sp)
    800042b8:	6a42                	ld	s4,16(sp)
    800042ba:	6aa2                	ld	s5,8(sp)
    800042bc:	6b02                	ld	s6,0(sp)
    800042be:	6121                	add	sp,sp,64
    800042c0:	8082                	ret
    800042c2:	8082                	ret

00000000800042c4 <initlog>:
{
    800042c4:	7179                	add	sp,sp,-48
    800042c6:	f406                	sd	ra,40(sp)
    800042c8:	f022                	sd	s0,32(sp)
    800042ca:	ec26                	sd	s1,24(sp)
    800042cc:	e84a                	sd	s2,16(sp)
    800042ce:	e44e                	sd	s3,8(sp)
    800042d0:	1800                	add	s0,sp,48
    800042d2:	892a                	mv	s2,a0
    800042d4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042d6:	0001f497          	auipc	s1,0x1f
    800042da:	25a48493          	add	s1,s1,602 # 80023530 <log>
    800042de:	00004597          	auipc	a1,0x4
    800042e2:	35258593          	add	a1,a1,850 # 80008630 <syscalls+0x1f8>
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	85a080e7          	jalr	-1958(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800042f0:	0149a583          	lw	a1,20(s3)
    800042f4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042f6:	0109a783          	lw	a5,16(s3)
    800042fa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042fc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004300:	854a                	mv	a0,s2
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	ea4080e7          	jalr	-348(ra) # 800031a6 <bread>
  log.lh.n = lh->n;
    8000430a:	4d30                	lw	a2,88(a0)
    8000430c:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	00c05f63          	blez	a2,8000432c <initlog+0x68>
    80004312:	87aa                	mv	a5,a0
    80004314:	0001f717          	auipc	a4,0x1f
    80004318:	24c70713          	add	a4,a4,588 # 80023560 <log+0x30>
    8000431c:	060a                	sll	a2,a2,0x2
    8000431e:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004320:	4ff4                	lw	a3,92(a5)
    80004322:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004324:	0791                	add	a5,a5,4
    80004326:	0711                	add	a4,a4,4
    80004328:	fec79ce3          	bne	a5,a2,80004320 <initlog+0x5c>
  brelse(buf);
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	faa080e7          	jalr	-86(ra) # 800032d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004334:	4505                	li	a0,1
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	eca080e7          	jalr	-310(ra) # 80004200 <install_trans>
  log.lh.n = 0;
    8000433e:	0001f797          	auipc	a5,0x1f
    80004342:	2007af23          	sw	zero,542(a5) # 8002355c <log+0x2c>
  write_head(); // clear the log
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	e50080e7          	jalr	-432(ra) # 80004196 <write_head>
}
    8000434e:	70a2                	ld	ra,40(sp)
    80004350:	7402                	ld	s0,32(sp)
    80004352:	64e2                	ld	s1,24(sp)
    80004354:	6942                	ld	s2,16(sp)
    80004356:	69a2                	ld	s3,8(sp)
    80004358:	6145                	add	sp,sp,48
    8000435a:	8082                	ret

000000008000435c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000435c:	1101                	add	sp,sp,-32
    8000435e:	ec06                	sd	ra,24(sp)
    80004360:	e822                	sd	s0,16(sp)
    80004362:	e426                	sd	s1,8(sp)
    80004364:	e04a                	sd	s2,0(sp)
    80004366:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004368:	0001f517          	auipc	a0,0x1f
    8000436c:	1c850513          	add	a0,a0,456 # 80023530 <log>
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	862080e7          	jalr	-1950(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004378:	0001f497          	auipc	s1,0x1f
    8000437c:	1b848493          	add	s1,s1,440 # 80023530 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004380:	4979                	li	s2,30
    80004382:	a039                	j	80004390 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004384:	85a6                	mv	a1,s1
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	cec080e7          	jalr	-788(ra) # 80002074 <sleep>
    if(log.committing){
    80004390:	50dc                	lw	a5,36(s1)
    80004392:	fbed                	bnez	a5,80004384 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004394:	5098                	lw	a4,32(s1)
    80004396:	2705                	addw	a4,a4,1
    80004398:	0027179b          	sllw	a5,a4,0x2
    8000439c:	9fb9                	addw	a5,a5,a4
    8000439e:	0017979b          	sllw	a5,a5,0x1
    800043a2:	54d4                	lw	a3,44(s1)
    800043a4:	9fb5                	addw	a5,a5,a3
    800043a6:	00f95963          	bge	s2,a5,800043b8 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043aa:	85a6                	mv	a1,s1
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffe097          	auipc	ra,0xffffe
    800043b2:	cc6080e7          	jalr	-826(ra) # 80002074 <sleep>
    800043b6:	bfe9                	j	80004390 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043b8:	0001f517          	auipc	a0,0x1f
    800043bc:	17850513          	add	a0,a0,376 # 80023530 <log>
    800043c0:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	8c4080e7          	jalr	-1852(ra) # 80000c86 <release>
      break;
    }
  }
}
    800043ca:	60e2                	ld	ra,24(sp)
    800043cc:	6442                	ld	s0,16(sp)
    800043ce:	64a2                	ld	s1,8(sp)
    800043d0:	6902                	ld	s2,0(sp)
    800043d2:	6105                	add	sp,sp,32
    800043d4:	8082                	ret

00000000800043d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043d6:	7139                	add	sp,sp,-64
    800043d8:	fc06                	sd	ra,56(sp)
    800043da:	f822                	sd	s0,48(sp)
    800043dc:	f426                	sd	s1,40(sp)
    800043de:	f04a                	sd	s2,32(sp)
    800043e0:	ec4e                	sd	s3,24(sp)
    800043e2:	e852                	sd	s4,16(sp)
    800043e4:	e456                	sd	s5,8(sp)
    800043e6:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043e8:	0001f497          	auipc	s1,0x1f
    800043ec:	14848493          	add	s1,s1,328 # 80023530 <log>
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	7e0080e7          	jalr	2016(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800043fa:	509c                	lw	a5,32(s1)
    800043fc:	37fd                	addw	a5,a5,-1
    800043fe:	0007891b          	sext.w	s2,a5
    80004402:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004404:	50dc                	lw	a5,36(s1)
    80004406:	e7b9                	bnez	a5,80004454 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004408:	04091e63          	bnez	s2,80004464 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000440c:	0001f497          	auipc	s1,0x1f
    80004410:	12448493          	add	s1,s1,292 # 80023530 <log>
    80004414:	4785                	li	a5,1
    80004416:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	86c080e7          	jalr	-1940(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004422:	54dc                	lw	a5,44(s1)
    80004424:	06f04763          	bgtz	a5,80004492 <end_op+0xbc>
    acquire(&log.lock);
    80004428:	0001f497          	auipc	s1,0x1f
    8000442c:	10848493          	add	s1,s1,264 # 80023530 <log>
    80004430:	8526                	mv	a0,s1
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7a0080e7          	jalr	1952(ra) # 80000bd2 <acquire>
    log.committing = 0;
    8000443a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	c98080e7          	jalr	-872(ra) # 800020d8 <wakeup>
    release(&log.lock);
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	83c080e7          	jalr	-1988(ra) # 80000c86 <release>
}
    80004452:	a03d                	j	80004480 <end_op+0xaa>
    panic("log.committing");
    80004454:	00004517          	auipc	a0,0x4
    80004458:	1e450513          	add	a0,a0,484 # 80008638 <syscalls+0x200>
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	0e0080e7          	jalr	224(ra) # 8000053c <panic>
    wakeup(&log);
    80004464:	0001f497          	auipc	s1,0x1f
    80004468:	0cc48493          	add	s1,s1,204 # 80023530 <log>
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffe097          	auipc	ra,0xffffe
    80004472:	c6a080e7          	jalr	-918(ra) # 800020d8 <wakeup>
  release(&log.lock);
    80004476:	8526                	mv	a0,s1
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	80e080e7          	jalr	-2034(ra) # 80000c86 <release>
}
    80004480:	70e2                	ld	ra,56(sp)
    80004482:	7442                	ld	s0,48(sp)
    80004484:	74a2                	ld	s1,40(sp)
    80004486:	7902                	ld	s2,32(sp)
    80004488:	69e2                	ld	s3,24(sp)
    8000448a:	6a42                	ld	s4,16(sp)
    8000448c:	6aa2                	ld	s5,8(sp)
    8000448e:	6121                	add	sp,sp,64
    80004490:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004492:	0001fa97          	auipc	s5,0x1f
    80004496:	0cea8a93          	add	s5,s5,206 # 80023560 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000449a:	0001fa17          	auipc	s4,0x1f
    8000449e:	096a0a13          	add	s4,s4,150 # 80023530 <log>
    800044a2:	018a2583          	lw	a1,24(s4)
    800044a6:	012585bb          	addw	a1,a1,s2
    800044aa:	2585                	addw	a1,a1,1
    800044ac:	028a2503          	lw	a0,40(s4)
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	cf6080e7          	jalr	-778(ra) # 800031a6 <bread>
    800044b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044ba:	000aa583          	lw	a1,0(s5)
    800044be:	028a2503          	lw	a0,40(s4)
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	ce4080e7          	jalr	-796(ra) # 800031a6 <bread>
    800044ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044cc:	40000613          	li	a2,1024
    800044d0:	05850593          	add	a1,a0,88
    800044d4:	05848513          	add	a0,s1,88
    800044d8:	ffffd097          	auipc	ra,0xffffd
    800044dc:	852080e7          	jalr	-1966(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800044e0:	8526                	mv	a0,s1
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	db6080e7          	jalr	-586(ra) # 80003298 <bwrite>
    brelse(from);
    800044ea:	854e                	mv	a0,s3
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	dea080e7          	jalr	-534(ra) # 800032d6 <brelse>
    brelse(to);
    800044f4:	8526                	mv	a0,s1
    800044f6:	fffff097          	auipc	ra,0xfffff
    800044fa:	de0080e7          	jalr	-544(ra) # 800032d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fe:	2905                	addw	s2,s2,1
    80004500:	0a91                	add	s5,s5,4
    80004502:	02ca2783          	lw	a5,44(s4)
    80004506:	f8f94ee3          	blt	s2,a5,800044a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	c8c080e7          	jalr	-884(ra) # 80004196 <write_head>
    install_trans(0); // Now install writes to home locations
    80004512:	4501                	li	a0,0
    80004514:	00000097          	auipc	ra,0x0
    80004518:	cec080e7          	jalr	-788(ra) # 80004200 <install_trans>
    log.lh.n = 0;
    8000451c:	0001f797          	auipc	a5,0x1f
    80004520:	0407a023          	sw	zero,64(a5) # 8002355c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004524:	00000097          	auipc	ra,0x0
    80004528:	c72080e7          	jalr	-910(ra) # 80004196 <write_head>
    8000452c:	bdf5                	j	80004428 <end_op+0x52>

000000008000452e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000452e:	1101                	add	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	e04a                	sd	s2,0(sp)
    80004538:	1000                	add	s0,sp,32
    8000453a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000453c:	0001f917          	auipc	s2,0x1f
    80004540:	ff490913          	add	s2,s2,-12 # 80023530 <log>
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	68c080e7          	jalr	1676(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000454e:	02c92603          	lw	a2,44(s2)
    80004552:	47f5                	li	a5,29
    80004554:	06c7c563          	blt	a5,a2,800045be <log_write+0x90>
    80004558:	0001f797          	auipc	a5,0x1f
    8000455c:	ff47a783          	lw	a5,-12(a5) # 8002354c <log+0x1c>
    80004560:	37fd                	addw	a5,a5,-1
    80004562:	04f65e63          	bge	a2,a5,800045be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004566:	0001f797          	auipc	a5,0x1f
    8000456a:	fea7a783          	lw	a5,-22(a5) # 80023550 <log+0x20>
    8000456e:	06f05063          	blez	a5,800045ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004572:	4781                	li	a5,0
    80004574:	06c05563          	blez	a2,800045de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004578:	44cc                	lw	a1,12(s1)
    8000457a:	0001f717          	auipc	a4,0x1f
    8000457e:	fe670713          	add	a4,a4,-26 # 80023560 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004582:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004584:	4314                	lw	a3,0(a4)
    80004586:	04b68c63          	beq	a3,a1,800045de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000458a:	2785                	addw	a5,a5,1
    8000458c:	0711                	add	a4,a4,4
    8000458e:	fef61be3          	bne	a2,a5,80004584 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004592:	0621                	add	a2,a2,8
    80004594:	060a                	sll	a2,a2,0x2
    80004596:	0001f797          	auipc	a5,0x1f
    8000459a:	f9a78793          	add	a5,a5,-102 # 80023530 <log>
    8000459e:	97b2                	add	a5,a5,a2
    800045a0:	44d8                	lw	a4,12(s1)
    800045a2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045a4:	8526                	mv	a0,s1
    800045a6:	fffff097          	auipc	ra,0xfffff
    800045aa:	dcc080e7          	jalr	-564(ra) # 80003372 <bpin>
    log.lh.n++;
    800045ae:	0001f717          	auipc	a4,0x1f
    800045b2:	f8270713          	add	a4,a4,-126 # 80023530 <log>
    800045b6:	575c                	lw	a5,44(a4)
    800045b8:	2785                	addw	a5,a5,1
    800045ba:	d75c                	sw	a5,44(a4)
    800045bc:	a82d                	j	800045f6 <log_write+0xc8>
    panic("too big a transaction");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	08a50513          	add	a0,a0,138 # 80008648 <syscalls+0x210>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f76080e7          	jalr	-138(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800045ce:	00004517          	auipc	a0,0x4
    800045d2:	09250513          	add	a0,a0,146 # 80008660 <syscalls+0x228>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	f66080e7          	jalr	-154(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800045de:	00878693          	add	a3,a5,8
    800045e2:	068a                	sll	a3,a3,0x2
    800045e4:	0001f717          	auipc	a4,0x1f
    800045e8:	f4c70713          	add	a4,a4,-180 # 80023530 <log>
    800045ec:	9736                	add	a4,a4,a3
    800045ee:	44d4                	lw	a3,12(s1)
    800045f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045f2:	faf609e3          	beq	a2,a5,800045a4 <log_write+0x76>
  }
  release(&log.lock);
    800045f6:	0001f517          	auipc	a0,0x1f
    800045fa:	f3a50513          	add	a0,a0,-198 # 80023530 <log>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	688080e7          	jalr	1672(ra) # 80000c86 <release>
}
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	64a2                	ld	s1,8(sp)
    8000460c:	6902                	ld	s2,0(sp)
    8000460e:	6105                	add	sp,sp,32
    80004610:	8082                	ret

0000000080004612 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004612:	1101                	add	sp,sp,-32
    80004614:	ec06                	sd	ra,24(sp)
    80004616:	e822                	sd	s0,16(sp)
    80004618:	e426                	sd	s1,8(sp)
    8000461a:	e04a                	sd	s2,0(sp)
    8000461c:	1000                	add	s0,sp,32
    8000461e:	84aa                	mv	s1,a0
    80004620:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004622:	00004597          	auipc	a1,0x4
    80004626:	05e58593          	add	a1,a1,94 # 80008680 <syscalls+0x248>
    8000462a:	0521                	add	a0,a0,8
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	516080e7          	jalr	1302(ra) # 80000b42 <initlock>
  lk->name = name;
    80004634:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004638:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463c:	0204a423          	sw	zero,40(s1)
}
    80004640:	60e2                	ld	ra,24(sp)
    80004642:	6442                	ld	s0,16(sp)
    80004644:	64a2                	ld	s1,8(sp)
    80004646:	6902                	ld	s2,0(sp)
    80004648:	6105                	add	sp,sp,32
    8000464a:	8082                	ret

000000008000464c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000464c:	1101                	add	sp,sp,-32
    8000464e:	ec06                	sd	ra,24(sp)
    80004650:	e822                	sd	s0,16(sp)
    80004652:	e426                	sd	s1,8(sp)
    80004654:	e04a                	sd	s2,0(sp)
    80004656:	1000                	add	s0,sp,32
    80004658:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000465a:	00850913          	add	s2,a0,8
    8000465e:	854a                	mv	a0,s2
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	572080e7          	jalr	1394(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004668:	409c                	lw	a5,0(s1)
    8000466a:	cb89                	beqz	a5,8000467c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000466c:	85ca                	mv	a1,s2
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffe097          	auipc	ra,0xffffe
    80004674:	a04080e7          	jalr	-1532(ra) # 80002074 <sleep>
  while (lk->locked) {
    80004678:	409c                	lw	a5,0(s1)
    8000467a:	fbed                	bnez	a5,8000466c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000467c:	4785                	li	a5,1
    8000467e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004680:	ffffd097          	auipc	ra,0xffffd
    80004684:	326080e7          	jalr	806(ra) # 800019a6 <myproc>
    80004688:	591c                	lw	a5,48(a0)
    8000468a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	5f8080e7          	jalr	1528(ra) # 80000c86 <release>
}
    80004696:	60e2                	ld	ra,24(sp)
    80004698:	6442                	ld	s0,16(sp)
    8000469a:	64a2                	ld	s1,8(sp)
    8000469c:	6902                	ld	s2,0(sp)
    8000469e:	6105                	add	sp,sp,32
    800046a0:	8082                	ret

00000000800046a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046a2:	1101                	add	sp,sp,-32
    800046a4:	ec06                	sd	ra,24(sp)
    800046a6:	e822                	sd	s0,16(sp)
    800046a8:	e426                	sd	s1,8(sp)
    800046aa:	e04a                	sd	s2,0(sp)
    800046ac:	1000                	add	s0,sp,32
    800046ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b0:	00850913          	add	s2,a0,8
    800046b4:	854a                	mv	a0,s2
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	51c080e7          	jalr	1308(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800046be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046c6:	8526                	mv	a0,s1
    800046c8:	ffffe097          	auipc	ra,0xffffe
    800046cc:	a10080e7          	jalr	-1520(ra) # 800020d8 <wakeup>
  release(&lk->lk);
    800046d0:	854a                	mv	a0,s2
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	5b4080e7          	jalr	1460(ra) # 80000c86 <release>
}
    800046da:	60e2                	ld	ra,24(sp)
    800046dc:	6442                	ld	s0,16(sp)
    800046de:	64a2                	ld	s1,8(sp)
    800046e0:	6902                	ld	s2,0(sp)
    800046e2:	6105                	add	sp,sp,32
    800046e4:	8082                	ret

00000000800046e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e6:	7179                	add	sp,sp,-48
    800046e8:	f406                	sd	ra,40(sp)
    800046ea:	f022                	sd	s0,32(sp)
    800046ec:	ec26                	sd	s1,24(sp)
    800046ee:	e84a                	sd	s2,16(sp)
    800046f0:	e44e                	sd	s3,8(sp)
    800046f2:	1800                	add	s0,sp,48
    800046f4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f6:	00850913          	add	s2,a0,8
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	4d6080e7          	jalr	1238(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004704:	409c                	lw	a5,0(s1)
    80004706:	ef99                	bnez	a5,80004724 <holdingsleep+0x3e>
    80004708:	4481                	li	s1,0
  release(&lk->lk);
    8000470a:	854a                	mv	a0,s2
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	57a080e7          	jalr	1402(ra) # 80000c86 <release>
  return r;
}
    80004714:	8526                	mv	a0,s1
    80004716:	70a2                	ld	ra,40(sp)
    80004718:	7402                	ld	s0,32(sp)
    8000471a:	64e2                	ld	s1,24(sp)
    8000471c:	6942                	ld	s2,16(sp)
    8000471e:	69a2                	ld	s3,8(sp)
    80004720:	6145                	add	sp,sp,48
    80004722:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004724:	0284a983          	lw	s3,40(s1)
    80004728:	ffffd097          	auipc	ra,0xffffd
    8000472c:	27e080e7          	jalr	638(ra) # 800019a6 <myproc>
    80004730:	5904                	lw	s1,48(a0)
    80004732:	413484b3          	sub	s1,s1,s3
    80004736:	0014b493          	seqz	s1,s1
    8000473a:	bfc1                	j	8000470a <holdingsleep+0x24>

000000008000473c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000473c:	1141                	add	sp,sp,-16
    8000473e:	e406                	sd	ra,8(sp)
    80004740:	e022                	sd	s0,0(sp)
    80004742:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004744:	00004597          	auipc	a1,0x4
    80004748:	f4c58593          	add	a1,a1,-180 # 80008690 <syscalls+0x258>
    8000474c:	0001f517          	auipc	a0,0x1f
    80004750:	f2c50513          	add	a0,a0,-212 # 80023678 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	3ee080e7          	jalr	1006(ra) # 80000b42 <initlock>
}
    8000475c:	60a2                	ld	ra,8(sp)
    8000475e:	6402                	ld	s0,0(sp)
    80004760:	0141                	add	sp,sp,16
    80004762:	8082                	ret

0000000080004764 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004764:	1101                	add	sp,sp,-32
    80004766:	ec06                	sd	ra,24(sp)
    80004768:	e822                	sd	s0,16(sp)
    8000476a:	e426                	sd	s1,8(sp)
    8000476c:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000476e:	0001f517          	auipc	a0,0x1f
    80004772:	f0a50513          	add	a0,a0,-246 # 80023678 <ftable>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	45c080e7          	jalr	1116(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477e:	0001f497          	auipc	s1,0x1f
    80004782:	f1248493          	add	s1,s1,-238 # 80023690 <ftable+0x18>
    80004786:	00020717          	auipc	a4,0x20
    8000478a:	eaa70713          	add	a4,a4,-342 # 80024630 <disk>
    if(f->ref == 0){
    8000478e:	40dc                	lw	a5,4(s1)
    80004790:	cf99                	beqz	a5,800047ae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004792:	02848493          	add	s1,s1,40
    80004796:	fee49ce3          	bne	s1,a4,8000478e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000479a:	0001f517          	auipc	a0,0x1f
    8000479e:	ede50513          	add	a0,a0,-290 # 80023678 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4e4080e7          	jalr	1252(ra) # 80000c86 <release>
  return 0;
    800047aa:	4481                	li	s1,0
    800047ac:	a819                	j	800047c2 <filealloc+0x5e>
      f->ref = 1;
    800047ae:	4785                	li	a5,1
    800047b0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047b2:	0001f517          	auipc	a0,0x1f
    800047b6:	ec650513          	add	a0,a0,-314 # 80023678 <ftable>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	4cc080e7          	jalr	1228(ra) # 80000c86 <release>
}
    800047c2:	8526                	mv	a0,s1
    800047c4:	60e2                	ld	ra,24(sp)
    800047c6:	6442                	ld	s0,16(sp)
    800047c8:	64a2                	ld	s1,8(sp)
    800047ca:	6105                	add	sp,sp,32
    800047cc:	8082                	ret

00000000800047ce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047ce:	1101                	add	sp,sp,-32
    800047d0:	ec06                	sd	ra,24(sp)
    800047d2:	e822                	sd	s0,16(sp)
    800047d4:	e426                	sd	s1,8(sp)
    800047d6:	1000                	add	s0,sp,32
    800047d8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047da:	0001f517          	auipc	a0,0x1f
    800047de:	e9e50513          	add	a0,a0,-354 # 80023678 <ftable>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	3f0080e7          	jalr	1008(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800047ea:	40dc                	lw	a5,4(s1)
    800047ec:	02f05263          	blez	a5,80004810 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047f0:	2785                	addw	a5,a5,1
    800047f2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047f4:	0001f517          	auipc	a0,0x1f
    800047f8:	e8450513          	add	a0,a0,-380 # 80023678 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	48a080e7          	jalr	1162(ra) # 80000c86 <release>
  return f;
}
    80004804:	8526                	mv	a0,s1
    80004806:	60e2                	ld	ra,24(sp)
    80004808:	6442                	ld	s0,16(sp)
    8000480a:	64a2                	ld	s1,8(sp)
    8000480c:	6105                	add	sp,sp,32
    8000480e:	8082                	ret
    panic("filedup");
    80004810:	00004517          	auipc	a0,0x4
    80004814:	e8850513          	add	a0,a0,-376 # 80008698 <syscalls+0x260>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	d24080e7          	jalr	-732(ra) # 8000053c <panic>

0000000080004820 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004820:	7139                	add	sp,sp,-64
    80004822:	fc06                	sd	ra,56(sp)
    80004824:	f822                	sd	s0,48(sp)
    80004826:	f426                	sd	s1,40(sp)
    80004828:	f04a                	sd	s2,32(sp)
    8000482a:	ec4e                	sd	s3,24(sp)
    8000482c:	e852                	sd	s4,16(sp)
    8000482e:	e456                	sd	s5,8(sp)
    80004830:	0080                	add	s0,sp,64
    80004832:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004834:	0001f517          	auipc	a0,0x1f
    80004838:	e4450513          	add	a0,a0,-444 # 80023678 <ftable>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	396080e7          	jalr	918(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004844:	40dc                	lw	a5,4(s1)
    80004846:	06f05163          	blez	a5,800048a8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000484a:	37fd                	addw	a5,a5,-1
    8000484c:	0007871b          	sext.w	a4,a5
    80004850:	c0dc                	sw	a5,4(s1)
    80004852:	06e04363          	bgtz	a4,800048b8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004856:	0004a903          	lw	s2,0(s1)
    8000485a:	0094ca83          	lbu	s5,9(s1)
    8000485e:	0104ba03          	ld	s4,16(s1)
    80004862:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004866:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000486a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000486e:	0001f517          	auipc	a0,0x1f
    80004872:	e0a50513          	add	a0,a0,-502 # 80023678 <ftable>
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	410080e7          	jalr	1040(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000487e:	4785                	li	a5,1
    80004880:	04f90d63          	beq	s2,a5,800048da <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004884:	3979                	addw	s2,s2,-2
    80004886:	4785                	li	a5,1
    80004888:	0527e063          	bltu	a5,s2,800048c8 <fileclose+0xa8>
    begin_op();
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	ad0080e7          	jalr	-1328(ra) # 8000435c <begin_op>
    iput(ff.ip);
    80004894:	854e                	mv	a0,s3
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	2da080e7          	jalr	730(ra) # 80003b70 <iput>
    end_op();
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	b38080e7          	jalr	-1224(ra) # 800043d6 <end_op>
    800048a6:	a00d                	j	800048c8 <fileclose+0xa8>
    panic("fileclose");
    800048a8:	00004517          	auipc	a0,0x4
    800048ac:	df850513          	add	a0,a0,-520 # 800086a0 <syscalls+0x268>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	c8c080e7          	jalr	-884(ra) # 8000053c <panic>
    release(&ftable.lock);
    800048b8:	0001f517          	auipc	a0,0x1f
    800048bc:	dc050513          	add	a0,a0,-576 # 80023678 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	3c6080e7          	jalr	966(ra) # 80000c86 <release>
  }
}
    800048c8:	70e2                	ld	ra,56(sp)
    800048ca:	7442                	ld	s0,48(sp)
    800048cc:	74a2                	ld	s1,40(sp)
    800048ce:	7902                	ld	s2,32(sp)
    800048d0:	69e2                	ld	s3,24(sp)
    800048d2:	6a42                	ld	s4,16(sp)
    800048d4:	6aa2                	ld	s5,8(sp)
    800048d6:	6121                	add	sp,sp,64
    800048d8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048da:	85d6                	mv	a1,s5
    800048dc:	8552                	mv	a0,s4
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	348080e7          	jalr	840(ra) # 80004c26 <pipeclose>
    800048e6:	b7cd                	j	800048c8 <fileclose+0xa8>

00000000800048e8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e8:	715d                	add	sp,sp,-80
    800048ea:	e486                	sd	ra,72(sp)
    800048ec:	e0a2                	sd	s0,64(sp)
    800048ee:	fc26                	sd	s1,56(sp)
    800048f0:	f84a                	sd	s2,48(sp)
    800048f2:	f44e                	sd	s3,40(sp)
    800048f4:	0880                	add	s0,sp,80
    800048f6:	84aa                	mv	s1,a0
    800048f8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048fa:	ffffd097          	auipc	ra,0xffffd
    800048fe:	0ac080e7          	jalr	172(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004902:	409c                	lw	a5,0(s1)
    80004904:	37f9                	addw	a5,a5,-2
    80004906:	4705                	li	a4,1
    80004908:	04f76763          	bltu	a4,a5,80004956 <filestat+0x6e>
    8000490c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	0a6080e7          	jalr	166(ra) # 800039b6 <ilock>
    stati(f->ip, &st);
    80004918:	fb840593          	add	a1,s0,-72
    8000491c:	6c88                	ld	a0,24(s1)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	322080e7          	jalr	802(ra) # 80003c40 <stati>
    iunlock(f->ip);
    80004926:	6c88                	ld	a0,24(s1)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	150080e7          	jalr	336(ra) # 80003a78 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004930:	46e1                	li	a3,24
    80004932:	fb840613          	add	a2,s0,-72
    80004936:	85ce                	mv	a1,s3
    80004938:	05093503          	ld	a0,80(s2)
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	d2a080e7          	jalr	-726(ra) # 80001666 <copyout>
    80004944:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004948:	60a6                	ld	ra,72(sp)
    8000494a:	6406                	ld	s0,64(sp)
    8000494c:	74e2                	ld	s1,56(sp)
    8000494e:	7942                	ld	s2,48(sp)
    80004950:	79a2                	ld	s3,40(sp)
    80004952:	6161                	add	sp,sp,80
    80004954:	8082                	ret
  return -1;
    80004956:	557d                	li	a0,-1
    80004958:	bfc5                	j	80004948 <filestat+0x60>

000000008000495a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000495a:	7179                	add	sp,sp,-48
    8000495c:	f406                	sd	ra,40(sp)
    8000495e:	f022                	sd	s0,32(sp)
    80004960:	ec26                	sd	s1,24(sp)
    80004962:	e84a                	sd	s2,16(sp)
    80004964:	e44e                	sd	s3,8(sp)
    80004966:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004968:	00854783          	lbu	a5,8(a0)
    8000496c:	c3d5                	beqz	a5,80004a10 <fileread+0xb6>
    8000496e:	84aa                	mv	s1,a0
    80004970:	89ae                	mv	s3,a1
    80004972:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004974:	411c                	lw	a5,0(a0)
    80004976:	4705                	li	a4,1
    80004978:	04e78963          	beq	a5,a4,800049ca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497c:	470d                	li	a4,3
    8000497e:	04e78d63          	beq	a5,a4,800049d8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004982:	4709                	li	a4,2
    80004984:	06e79e63          	bne	a5,a4,80004a00 <fileread+0xa6>
    ilock(f->ip);
    80004988:	6d08                	ld	a0,24(a0)
    8000498a:	fffff097          	auipc	ra,0xfffff
    8000498e:	02c080e7          	jalr	44(ra) # 800039b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004992:	874a                	mv	a4,s2
    80004994:	5094                	lw	a3,32(s1)
    80004996:	864e                	mv	a2,s3
    80004998:	4585                	li	a1,1
    8000499a:	6c88                	ld	a0,24(s1)
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	2ce080e7          	jalr	718(ra) # 80003c6a <readi>
    800049a4:	892a                	mv	s2,a0
    800049a6:	00a05563          	blez	a0,800049b0 <fileread+0x56>
      f->off += r;
    800049aa:	509c                	lw	a5,32(s1)
    800049ac:	9fa9                	addw	a5,a5,a0
    800049ae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049b0:	6c88                	ld	a0,24(s1)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	0c6080e7          	jalr	198(ra) # 80003a78 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049ba:	854a                	mv	a0,s2
    800049bc:	70a2                	ld	ra,40(sp)
    800049be:	7402                	ld	s0,32(sp)
    800049c0:	64e2                	ld	s1,24(sp)
    800049c2:	6942                	ld	s2,16(sp)
    800049c4:	69a2                	ld	s3,8(sp)
    800049c6:	6145                	add	sp,sp,48
    800049c8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049ca:	6908                	ld	a0,16(a0)
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	3c2080e7          	jalr	962(ra) # 80004d8e <piperead>
    800049d4:	892a                	mv	s2,a0
    800049d6:	b7d5                	j	800049ba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d8:	02451783          	lh	a5,36(a0)
    800049dc:	03079693          	sll	a3,a5,0x30
    800049e0:	92c1                	srl	a3,a3,0x30
    800049e2:	4725                	li	a4,9
    800049e4:	02d76863          	bltu	a4,a3,80004a14 <fileread+0xba>
    800049e8:	0792                	sll	a5,a5,0x4
    800049ea:	0001f717          	auipc	a4,0x1f
    800049ee:	bee70713          	add	a4,a4,-1042 # 800235d8 <devsw>
    800049f2:	97ba                	add	a5,a5,a4
    800049f4:	639c                	ld	a5,0(a5)
    800049f6:	c38d                	beqz	a5,80004a18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f8:	4505                	li	a0,1
    800049fa:	9782                	jalr	a5
    800049fc:	892a                	mv	s2,a0
    800049fe:	bf75                	j	800049ba <fileread+0x60>
    panic("fileread");
    80004a00:	00004517          	auipc	a0,0x4
    80004a04:	cb050513          	add	a0,a0,-848 # 800086b0 <syscalls+0x278>
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	b34080e7          	jalr	-1228(ra) # 8000053c <panic>
    return -1;
    80004a10:	597d                	li	s2,-1
    80004a12:	b765                	j	800049ba <fileread+0x60>
      return -1;
    80004a14:	597d                	li	s2,-1
    80004a16:	b755                	j	800049ba <fileread+0x60>
    80004a18:	597d                	li	s2,-1
    80004a1a:	b745                	j	800049ba <fileread+0x60>

0000000080004a1c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a1c:	00954783          	lbu	a5,9(a0)
    80004a20:	10078e63          	beqz	a5,80004b3c <filewrite+0x120>
{
    80004a24:	715d                	add	sp,sp,-80
    80004a26:	e486                	sd	ra,72(sp)
    80004a28:	e0a2                	sd	s0,64(sp)
    80004a2a:	fc26                	sd	s1,56(sp)
    80004a2c:	f84a                	sd	s2,48(sp)
    80004a2e:	f44e                	sd	s3,40(sp)
    80004a30:	f052                	sd	s4,32(sp)
    80004a32:	ec56                	sd	s5,24(sp)
    80004a34:	e85a                	sd	s6,16(sp)
    80004a36:	e45e                	sd	s7,8(sp)
    80004a38:	e062                	sd	s8,0(sp)
    80004a3a:	0880                	add	s0,sp,80
    80004a3c:	892a                	mv	s2,a0
    80004a3e:	8b2e                	mv	s6,a1
    80004a40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a42:	411c                	lw	a5,0(a0)
    80004a44:	4705                	li	a4,1
    80004a46:	02e78263          	beq	a5,a4,80004a6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a4a:	470d                	li	a4,3
    80004a4c:	02e78563          	beq	a5,a4,80004a76 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a50:	4709                	li	a4,2
    80004a52:	0ce79d63          	bne	a5,a4,80004b2c <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a56:	0ac05b63          	blez	a2,80004b0c <filewrite+0xf0>
    int i = 0;
    80004a5a:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004a5c:	6b85                	lui	s7,0x1
    80004a5e:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a62:	6c05                	lui	s8,0x1
    80004a64:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a68:	a851                	j	80004afc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a6a:	6908                	ld	a0,16(a0)
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	22a080e7          	jalr	554(ra) # 80004c96 <pipewrite>
    80004a74:	a045                	j	80004b14 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a76:	02451783          	lh	a5,36(a0)
    80004a7a:	03079693          	sll	a3,a5,0x30
    80004a7e:	92c1                	srl	a3,a3,0x30
    80004a80:	4725                	li	a4,9
    80004a82:	0ad76f63          	bltu	a4,a3,80004b40 <filewrite+0x124>
    80004a86:	0792                	sll	a5,a5,0x4
    80004a88:	0001f717          	auipc	a4,0x1f
    80004a8c:	b5070713          	add	a4,a4,-1200 # 800235d8 <devsw>
    80004a90:	97ba                	add	a5,a5,a4
    80004a92:	679c                	ld	a5,8(a5)
    80004a94:	cbc5                	beqz	a5,80004b44 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004a96:	4505                	li	a0,1
    80004a98:	9782                	jalr	a5
    80004a9a:	a8ad                	j	80004b14 <filewrite+0xf8>
      if(n1 > max)
    80004a9c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	8bc080e7          	jalr	-1860(ra) # 8000435c <begin_op>
      ilock(f->ip);
    80004aa8:	01893503          	ld	a0,24(s2)
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	f0a080e7          	jalr	-246(ra) # 800039b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab4:	8756                	mv	a4,s5
    80004ab6:	02092683          	lw	a3,32(s2)
    80004aba:	01698633          	add	a2,s3,s6
    80004abe:	4585                	li	a1,1
    80004ac0:	01893503          	ld	a0,24(s2)
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	29e080e7          	jalr	670(ra) # 80003d62 <writei>
    80004acc:	84aa                	mv	s1,a0
    80004ace:	00a05763          	blez	a0,80004adc <filewrite+0xc0>
        f->off += r;
    80004ad2:	02092783          	lw	a5,32(s2)
    80004ad6:	9fa9                	addw	a5,a5,a0
    80004ad8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004adc:	01893503          	ld	a0,24(s2)
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	f98080e7          	jalr	-104(ra) # 80003a78 <iunlock>
      end_op();
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	8ee080e7          	jalr	-1810(ra) # 800043d6 <end_op>

      if(r != n1){
    80004af0:	009a9f63          	bne	s5,s1,80004b0e <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004af4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af8:	0149db63          	bge	s3,s4,80004b0e <filewrite+0xf2>
      int n1 = n - i;
    80004afc:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004b00:	0004879b          	sext.w	a5,s1
    80004b04:	f8fbdce3          	bge	s7,a5,80004a9c <filewrite+0x80>
    80004b08:	84e2                	mv	s1,s8
    80004b0a:	bf49                	j	80004a9c <filewrite+0x80>
    int i = 0;
    80004b0c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b0e:	033a1d63          	bne	s4,s3,80004b48 <filewrite+0x12c>
    80004b12:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b14:	60a6                	ld	ra,72(sp)
    80004b16:	6406                	ld	s0,64(sp)
    80004b18:	74e2                	ld	s1,56(sp)
    80004b1a:	7942                	ld	s2,48(sp)
    80004b1c:	79a2                	ld	s3,40(sp)
    80004b1e:	7a02                	ld	s4,32(sp)
    80004b20:	6ae2                	ld	s5,24(sp)
    80004b22:	6b42                	ld	s6,16(sp)
    80004b24:	6ba2                	ld	s7,8(sp)
    80004b26:	6c02                	ld	s8,0(sp)
    80004b28:	6161                	add	sp,sp,80
    80004b2a:	8082                	ret
    panic("filewrite");
    80004b2c:	00004517          	auipc	a0,0x4
    80004b30:	b9450513          	add	a0,a0,-1132 # 800086c0 <syscalls+0x288>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	a08080e7          	jalr	-1528(ra) # 8000053c <panic>
    return -1;
    80004b3c:	557d                	li	a0,-1
}
    80004b3e:	8082                	ret
      return -1;
    80004b40:	557d                	li	a0,-1
    80004b42:	bfc9                	j	80004b14 <filewrite+0xf8>
    80004b44:	557d                	li	a0,-1
    80004b46:	b7f9                	j	80004b14 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004b48:	557d                	li	a0,-1
    80004b4a:	b7e9                	j	80004b14 <filewrite+0xf8>

0000000080004b4c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b4c:	7179                	add	sp,sp,-48
    80004b4e:	f406                	sd	ra,40(sp)
    80004b50:	f022                	sd	s0,32(sp)
    80004b52:	ec26                	sd	s1,24(sp)
    80004b54:	e84a                	sd	s2,16(sp)
    80004b56:	e44e                	sd	s3,8(sp)
    80004b58:	e052                	sd	s4,0(sp)
    80004b5a:	1800                	add	s0,sp,48
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b60:	0005b023          	sd	zero,0(a1)
    80004b64:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	bfc080e7          	jalr	-1028(ra) # 80004764 <filealloc>
    80004b70:	e088                	sd	a0,0(s1)
    80004b72:	c551                	beqz	a0,80004bfe <pipealloc+0xb2>
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	bf0080e7          	jalr	-1040(ra) # 80004764 <filealloc>
    80004b7c:	00aa3023          	sd	a0,0(s4)
    80004b80:	c92d                	beqz	a0,80004bf2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	f60080e7          	jalr	-160(ra) # 80000ae2 <kalloc>
    80004b8a:	892a                	mv	s2,a0
    80004b8c:	c125                	beqz	a0,80004bec <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b8e:	4985                	li	s3,1
    80004b90:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b94:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b98:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b9c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ba0:	00004597          	auipc	a1,0x4
    80004ba4:	b3058593          	add	a1,a1,-1232 # 800086d0 <syscalls+0x298>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	f9a080e7          	jalr	-102(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004bb0:	609c                	ld	a5,0(s1)
    80004bb2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bb6:	609c                	ld	a5,0(s1)
    80004bb8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bbc:	609c                	ld	a5,0(s1)
    80004bbe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bc2:	609c                	ld	a5,0(s1)
    80004bc4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bc8:	000a3783          	ld	a5,0(s4)
    80004bcc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bd0:	000a3783          	ld	a5,0(s4)
    80004bd4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bd8:	000a3783          	ld	a5,0(s4)
    80004bdc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004be0:	000a3783          	ld	a5,0(s4)
    80004be4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004be8:	4501                	li	a0,0
    80004bea:	a025                	j	80004c12 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bec:	6088                	ld	a0,0(s1)
    80004bee:	e501                	bnez	a0,80004bf6 <pipealloc+0xaa>
    80004bf0:	a039                	j	80004bfe <pipealloc+0xb2>
    80004bf2:	6088                	ld	a0,0(s1)
    80004bf4:	c51d                	beqz	a0,80004c22 <pipealloc+0xd6>
    fileclose(*f0);
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	c2a080e7          	jalr	-982(ra) # 80004820 <fileclose>
  if(*f1)
    80004bfe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c02:	557d                	li	a0,-1
  if(*f1)
    80004c04:	c799                	beqz	a5,80004c12 <pipealloc+0xc6>
    fileclose(*f1);
    80004c06:	853e                	mv	a0,a5
    80004c08:	00000097          	auipc	ra,0x0
    80004c0c:	c18080e7          	jalr	-1000(ra) # 80004820 <fileclose>
  return -1;
    80004c10:	557d                	li	a0,-1
}
    80004c12:	70a2                	ld	ra,40(sp)
    80004c14:	7402                	ld	s0,32(sp)
    80004c16:	64e2                	ld	s1,24(sp)
    80004c18:	6942                	ld	s2,16(sp)
    80004c1a:	69a2                	ld	s3,8(sp)
    80004c1c:	6a02                	ld	s4,0(sp)
    80004c1e:	6145                	add	sp,sp,48
    80004c20:	8082                	ret
  return -1;
    80004c22:	557d                	li	a0,-1
    80004c24:	b7fd                	j	80004c12 <pipealloc+0xc6>

0000000080004c26 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c26:	1101                	add	sp,sp,-32
    80004c28:	ec06                	sd	ra,24(sp)
    80004c2a:	e822                	sd	s0,16(sp)
    80004c2c:	e426                	sd	s1,8(sp)
    80004c2e:	e04a                	sd	s2,0(sp)
    80004c30:	1000                	add	s0,sp,32
    80004c32:	84aa                	mv	s1,a0
    80004c34:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	f9c080e7          	jalr	-100(ra) # 80000bd2 <acquire>
  if(writable){
    80004c3e:	02090d63          	beqz	s2,80004c78 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c42:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c46:	21848513          	add	a0,s1,536
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	48e080e7          	jalr	1166(ra) # 800020d8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c52:	2204b783          	ld	a5,544(s1)
    80004c56:	eb95                	bnez	a5,80004c8a <pipeclose+0x64>
    release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	02c080e7          	jalr	44(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	d80080e7          	jalr	-640(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004c6c:	60e2                	ld	ra,24(sp)
    80004c6e:	6442                	ld	s0,16(sp)
    80004c70:	64a2                	ld	s1,8(sp)
    80004c72:	6902                	ld	s2,0(sp)
    80004c74:	6105                	add	sp,sp,32
    80004c76:	8082                	ret
    pi->readopen = 0;
    80004c78:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c7c:	21c48513          	add	a0,s1,540
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	458080e7          	jalr	1112(ra) # 800020d8 <wakeup>
    80004c88:	b7e9                	j	80004c52 <pipeclose+0x2c>
    release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	ffa080e7          	jalr	-6(ra) # 80000c86 <release>
}
    80004c94:	bfe1                	j	80004c6c <pipeclose+0x46>

0000000080004c96 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c96:	711d                	add	sp,sp,-96
    80004c98:	ec86                	sd	ra,88(sp)
    80004c9a:	e8a2                	sd	s0,80(sp)
    80004c9c:	e4a6                	sd	s1,72(sp)
    80004c9e:	e0ca                	sd	s2,64(sp)
    80004ca0:	fc4e                	sd	s3,56(sp)
    80004ca2:	f852                	sd	s4,48(sp)
    80004ca4:	f456                	sd	s5,40(sp)
    80004ca6:	f05a                	sd	s6,32(sp)
    80004ca8:	ec5e                	sd	s7,24(sp)
    80004caa:	e862                	sd	s8,16(sp)
    80004cac:	1080                	add	s0,sp,96
    80004cae:	84aa                	mv	s1,a0
    80004cb0:	8aae                	mv	s5,a1
    80004cb2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	cf2080e7          	jalr	-782(ra) # 800019a6 <myproc>
    80004cbc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	f12080e7          	jalr	-238(ra) # 80000bd2 <acquire>
  while(i < n){
    80004cc8:	0b405663          	blez	s4,80004d74 <pipewrite+0xde>
  int i = 0;
    80004ccc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cce:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cd0:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cd4:	21c48b93          	add	s7,s1,540
    80004cd8:	a089                	j	80004d1a <pipewrite+0x84>
      release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	faa080e7          	jalr	-86(ra) # 80000c86 <release>
      return -1;
    80004ce4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ce6:	854a                	mv	a0,s2
    80004ce8:	60e6                	ld	ra,88(sp)
    80004cea:	6446                	ld	s0,80(sp)
    80004cec:	64a6                	ld	s1,72(sp)
    80004cee:	6906                	ld	s2,64(sp)
    80004cf0:	79e2                	ld	s3,56(sp)
    80004cf2:	7a42                	ld	s4,48(sp)
    80004cf4:	7aa2                	ld	s5,40(sp)
    80004cf6:	7b02                	ld	s6,32(sp)
    80004cf8:	6be2                	ld	s7,24(sp)
    80004cfa:	6c42                	ld	s8,16(sp)
    80004cfc:	6125                	add	sp,sp,96
    80004cfe:	8082                	ret
      wakeup(&pi->nread);
    80004d00:	8562                	mv	a0,s8
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	3d6080e7          	jalr	982(ra) # 800020d8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d0a:	85a6                	mv	a1,s1
    80004d0c:	855e                	mv	a0,s7
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	366080e7          	jalr	870(ra) # 80002074 <sleep>
  while(i < n){
    80004d16:	07495063          	bge	s2,s4,80004d76 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d1a:	2204a783          	lw	a5,544(s1)
    80004d1e:	dfd5                	beqz	a5,80004cda <pipewrite+0x44>
    80004d20:	854e                	mv	a0,s3
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	606080e7          	jalr	1542(ra) # 80002328 <killed>
    80004d2a:	f945                	bnez	a0,80004cda <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d2c:	2184a783          	lw	a5,536(s1)
    80004d30:	21c4a703          	lw	a4,540(s1)
    80004d34:	2007879b          	addw	a5,a5,512
    80004d38:	fcf704e3          	beq	a4,a5,80004d00 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3c:	4685                	li	a3,1
    80004d3e:	01590633          	add	a2,s2,s5
    80004d42:	faf40593          	add	a1,s0,-81
    80004d46:	0509b503          	ld	a0,80(s3)
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	9a8080e7          	jalr	-1624(ra) # 800016f2 <copyin>
    80004d52:	03650263          	beq	a0,s6,80004d76 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d56:	21c4a783          	lw	a5,540(s1)
    80004d5a:	0017871b          	addw	a4,a5,1
    80004d5e:	20e4ae23          	sw	a4,540(s1)
    80004d62:	1ff7f793          	and	a5,a5,511
    80004d66:	97a6                	add	a5,a5,s1
    80004d68:	faf44703          	lbu	a4,-81(s0)
    80004d6c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d70:	2905                	addw	s2,s2,1
    80004d72:	b755                	j	80004d16 <pipewrite+0x80>
  int i = 0;
    80004d74:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004d76:	21848513          	add	a0,s1,536
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	35e080e7          	jalr	862(ra) # 800020d8 <wakeup>
  release(&pi->lock);
    80004d82:	8526                	mv	a0,s1
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	f02080e7          	jalr	-254(ra) # 80000c86 <release>
  return i;
    80004d8c:	bfa9                	j	80004ce6 <pipewrite+0x50>

0000000080004d8e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d8e:	715d                	add	sp,sp,-80
    80004d90:	e486                	sd	ra,72(sp)
    80004d92:	e0a2                	sd	s0,64(sp)
    80004d94:	fc26                	sd	s1,56(sp)
    80004d96:	f84a                	sd	s2,48(sp)
    80004d98:	f44e                	sd	s3,40(sp)
    80004d9a:	f052                	sd	s4,32(sp)
    80004d9c:	ec56                	sd	s5,24(sp)
    80004d9e:	e85a                	sd	s6,16(sp)
    80004da0:	0880                	add	s0,sp,80
    80004da2:	84aa                	mv	s1,a0
    80004da4:	892e                	mv	s2,a1
    80004da6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004da8:	ffffd097          	auipc	ra,0xffffd
    80004dac:	bfe080e7          	jalr	-1026(ra) # 800019a6 <myproc>
    80004db0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	e1e080e7          	jalr	-482(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbc:	2184a703          	lw	a4,536(s1)
    80004dc0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc4:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc8:	02f71763          	bne	a4,a5,80004df6 <piperead+0x68>
    80004dcc:	2244a783          	lw	a5,548(s1)
    80004dd0:	c39d                	beqz	a5,80004df6 <piperead+0x68>
    if(killed(pr)){
    80004dd2:	8552                	mv	a0,s4
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	554080e7          	jalr	1364(ra) # 80002328 <killed>
    80004ddc:	e949                	bnez	a0,80004e6e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dde:	85a6                	mv	a1,s1
    80004de0:	854e                	mv	a0,s3
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	292080e7          	jalr	658(ra) # 80002074 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dea:	2184a703          	lw	a4,536(s1)
    80004dee:	21c4a783          	lw	a5,540(s1)
    80004df2:	fcf70de3          	beq	a4,a5,80004dcc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df8:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dfa:	05505463          	blez	s5,80004e42 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004dfe:	2184a783          	lw	a5,536(s1)
    80004e02:	21c4a703          	lw	a4,540(s1)
    80004e06:	02f70e63          	beq	a4,a5,80004e42 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e0a:	0017871b          	addw	a4,a5,1
    80004e0e:	20e4ac23          	sw	a4,536(s1)
    80004e12:	1ff7f793          	and	a5,a5,511
    80004e16:	97a6                	add	a5,a5,s1
    80004e18:	0187c783          	lbu	a5,24(a5)
    80004e1c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e20:	4685                	li	a3,1
    80004e22:	fbf40613          	add	a2,s0,-65
    80004e26:	85ca                	mv	a1,s2
    80004e28:	050a3503          	ld	a0,80(s4)
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	83a080e7          	jalr	-1990(ra) # 80001666 <copyout>
    80004e34:	01650763          	beq	a0,s6,80004e42 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e38:	2985                	addw	s3,s3,1
    80004e3a:	0905                	add	s2,s2,1
    80004e3c:	fd3a91e3          	bne	s5,s3,80004dfe <piperead+0x70>
    80004e40:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e42:	21c48513          	add	a0,s1,540
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	292080e7          	jalr	658(ra) # 800020d8 <wakeup>
  release(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	e36080e7          	jalr	-458(ra) # 80000c86 <release>
  return i;
}
    80004e58:	854e                	mv	a0,s3
    80004e5a:	60a6                	ld	ra,72(sp)
    80004e5c:	6406                	ld	s0,64(sp)
    80004e5e:	74e2                	ld	s1,56(sp)
    80004e60:	7942                	ld	s2,48(sp)
    80004e62:	79a2                	ld	s3,40(sp)
    80004e64:	7a02                	ld	s4,32(sp)
    80004e66:	6ae2                	ld	s5,24(sp)
    80004e68:	6b42                	ld	s6,16(sp)
    80004e6a:	6161                	add	sp,sp,80
    80004e6c:	8082                	ret
      release(&pi->lock);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	e16080e7          	jalr	-490(ra) # 80000c86 <release>
      return -1;
    80004e78:	59fd                	li	s3,-1
    80004e7a:	bff9                	j	80004e58 <piperead+0xca>

0000000080004e7c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e7c:	1141                	add	sp,sp,-16
    80004e7e:	e422                	sd	s0,8(sp)
    80004e80:	0800                	add	s0,sp,16
    80004e82:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e84:	8905                	and	a0,a0,1
    80004e86:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004e88:	8b89                	and	a5,a5,2
    80004e8a:	c399                	beqz	a5,80004e90 <flags2perm+0x14>
      perm |= PTE_W;
    80004e8c:	00456513          	or	a0,a0,4
    return perm;
}
    80004e90:	6422                	ld	s0,8(sp)
    80004e92:	0141                	add	sp,sp,16
    80004e94:	8082                	ret

0000000080004e96 <exec>:

int
exec(char *path, char **argv)
{
    80004e96:	df010113          	add	sp,sp,-528
    80004e9a:	20113423          	sd	ra,520(sp)
    80004e9e:	20813023          	sd	s0,512(sp)
    80004ea2:	ffa6                	sd	s1,504(sp)
    80004ea4:	fbca                	sd	s2,496(sp)
    80004ea6:	f7ce                	sd	s3,488(sp)
    80004ea8:	f3d2                	sd	s4,480(sp)
    80004eaa:	efd6                	sd	s5,472(sp)
    80004eac:	ebda                	sd	s6,464(sp)
    80004eae:	e7de                	sd	s7,456(sp)
    80004eb0:	e3e2                	sd	s8,448(sp)
    80004eb2:	ff66                	sd	s9,440(sp)
    80004eb4:	fb6a                	sd	s10,432(sp)
    80004eb6:	f76e                	sd	s11,424(sp)
    80004eb8:	0c00                	add	s0,sp,528
    80004eba:	892a                	mv	s2,a0
    80004ebc:	dea43c23          	sd	a0,-520(s0)
    80004ec0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	ae2080e7          	jalr	-1310(ra) # 800019a6 <myproc>
    80004ecc:	84aa                	mv	s1,a0

  begin_op();
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	48e080e7          	jalr	1166(ra) # 8000435c <begin_op>

  if((ip = namei(path)) == 0){
    80004ed6:	854a                	mv	a0,s2
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	284080e7          	jalr	644(ra) # 8000415c <namei>
    80004ee0:	c92d                	beqz	a0,80004f52 <exec+0xbc>
    80004ee2:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	ad2080e7          	jalr	-1326(ra) # 800039b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eec:	04000713          	li	a4,64
    80004ef0:	4681                	li	a3,0
    80004ef2:	e5040613          	add	a2,s0,-432
    80004ef6:	4581                	li	a1,0
    80004ef8:	8552                	mv	a0,s4
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	d70080e7          	jalr	-656(ra) # 80003c6a <readi>
    80004f02:	04000793          	li	a5,64
    80004f06:	00f51a63          	bne	a0,a5,80004f1a <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f0a:	e5042703          	lw	a4,-432(s0)
    80004f0e:	464c47b7          	lui	a5,0x464c4
    80004f12:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f16:	04f70463          	beq	a4,a5,80004f5e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f1a:	8552                	mv	a0,s4
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	cfc080e7          	jalr	-772(ra) # 80003c18 <iunlockput>
    end_op();
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	4b2080e7          	jalr	1202(ra) # 800043d6 <end_op>
  }
  return -1;
    80004f2c:	557d                	li	a0,-1
}
    80004f2e:	20813083          	ld	ra,520(sp)
    80004f32:	20013403          	ld	s0,512(sp)
    80004f36:	74fe                	ld	s1,504(sp)
    80004f38:	795e                	ld	s2,496(sp)
    80004f3a:	79be                	ld	s3,488(sp)
    80004f3c:	7a1e                	ld	s4,480(sp)
    80004f3e:	6afe                	ld	s5,472(sp)
    80004f40:	6b5e                	ld	s6,464(sp)
    80004f42:	6bbe                	ld	s7,456(sp)
    80004f44:	6c1e                	ld	s8,448(sp)
    80004f46:	7cfa                	ld	s9,440(sp)
    80004f48:	7d5a                	ld	s10,432(sp)
    80004f4a:	7dba                	ld	s11,424(sp)
    80004f4c:	21010113          	add	sp,sp,528
    80004f50:	8082                	ret
    end_op();
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	484080e7          	jalr	1156(ra) # 800043d6 <end_op>
    return -1;
    80004f5a:	557d                	li	a0,-1
    80004f5c:	bfc9                	j	80004f2e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f5e:	8526                	mv	a0,s1
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	b0a080e7          	jalr	-1270(ra) # 80001a6a <proc_pagetable>
    80004f68:	8b2a                	mv	s6,a0
    80004f6a:	d945                	beqz	a0,80004f1a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6c:	e7042d03          	lw	s10,-400(s0)
    80004f70:	e8845783          	lhu	a5,-376(s0)
    80004f74:	10078463          	beqz	a5,8000507c <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f78:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004f7c:	6c85                	lui	s9,0x1
    80004f7e:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f82:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004f86:	6a85                	lui	s5,0x1
    80004f88:	a0b5                	j	80004ff4 <exec+0x15e>
      panic("loadseg: address should exist");
    80004f8a:	00003517          	auipc	a0,0x3
    80004f8e:	74e50513          	add	a0,a0,1870 # 800086d8 <syscalls+0x2a0>
    80004f92:	ffffb097          	auipc	ra,0xffffb
    80004f96:	5aa080e7          	jalr	1450(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004f9a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f9c:	8726                	mv	a4,s1
    80004f9e:	012c06bb          	addw	a3,s8,s2
    80004fa2:	4581                	li	a1,0
    80004fa4:	8552                	mv	a0,s4
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	cc4080e7          	jalr	-828(ra) # 80003c6a <readi>
    80004fae:	2501                	sext.w	a0,a0
    80004fb0:	24a49863          	bne	s1,a0,80005200 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004fb4:	012a893b          	addw	s2,s5,s2
    80004fb8:	03397563          	bgeu	s2,s3,80004fe2 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004fbc:	02091593          	sll	a1,s2,0x20
    80004fc0:	9181                	srl	a1,a1,0x20
    80004fc2:	95de                	add	a1,a1,s7
    80004fc4:	855a                	mv	a0,s6
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	090080e7          	jalr	144(ra) # 80001056 <walkaddr>
    80004fce:	862a                	mv	a2,a0
    if(pa == 0)
    80004fd0:	dd4d                	beqz	a0,80004f8a <exec+0xf4>
    if(sz - i < PGSIZE)
    80004fd2:	412984bb          	subw	s1,s3,s2
    80004fd6:	0004879b          	sext.w	a5,s1
    80004fda:	fcfcf0e3          	bgeu	s9,a5,80004f9a <exec+0x104>
    80004fde:	84d6                	mv	s1,s5
    80004fe0:	bf6d                	j	80004f9a <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fe2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe6:	2d85                	addw	s11,s11,1
    80004fe8:	038d0d1b          	addw	s10,s10,56
    80004fec:	e8845783          	lhu	a5,-376(s0)
    80004ff0:	08fdd763          	bge	s11,a5,8000507e <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ff4:	2d01                	sext.w	s10,s10
    80004ff6:	03800713          	li	a4,56
    80004ffa:	86ea                	mv	a3,s10
    80004ffc:	e1840613          	add	a2,s0,-488
    80005000:	4581                	li	a1,0
    80005002:	8552                	mv	a0,s4
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	c66080e7          	jalr	-922(ra) # 80003c6a <readi>
    8000500c:	03800793          	li	a5,56
    80005010:	1ef51663          	bne	a0,a5,800051fc <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005014:	e1842783          	lw	a5,-488(s0)
    80005018:	4705                	li	a4,1
    8000501a:	fce796e3          	bne	a5,a4,80004fe6 <exec+0x150>
    if(ph.memsz < ph.filesz)
    8000501e:	e4043483          	ld	s1,-448(s0)
    80005022:	e3843783          	ld	a5,-456(s0)
    80005026:	1ef4e863          	bltu	s1,a5,80005216 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000502a:	e2843783          	ld	a5,-472(s0)
    8000502e:	94be                	add	s1,s1,a5
    80005030:	1ef4e663          	bltu	s1,a5,8000521c <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005034:	df043703          	ld	a4,-528(s0)
    80005038:	8ff9                	and	a5,a5,a4
    8000503a:	1e079463          	bnez	a5,80005222 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000503e:	e1c42503          	lw	a0,-484(s0)
    80005042:	00000097          	auipc	ra,0x0
    80005046:	e3a080e7          	jalr	-454(ra) # 80004e7c <flags2perm>
    8000504a:	86aa                	mv	a3,a0
    8000504c:	8626                	mv	a2,s1
    8000504e:	85ca                	mv	a1,s2
    80005050:	855a                	mv	a0,s6
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	3b8080e7          	jalr	952(ra) # 8000140a <uvmalloc>
    8000505a:	e0a43423          	sd	a0,-504(s0)
    8000505e:	1c050563          	beqz	a0,80005228 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005062:	e2843b83          	ld	s7,-472(s0)
    80005066:	e2042c03          	lw	s8,-480(s0)
    8000506a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000506e:	00098463          	beqz	s3,80005076 <exec+0x1e0>
    80005072:	4901                	li	s2,0
    80005074:	b7a1                	j	80004fbc <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005076:	e0843903          	ld	s2,-504(s0)
    8000507a:	b7b5                	j	80004fe6 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000507c:	4901                	li	s2,0
  iunlockput(ip);
    8000507e:	8552                	mv	a0,s4
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	b98080e7          	jalr	-1128(ra) # 80003c18 <iunlockput>
  end_op();
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	34e080e7          	jalr	846(ra) # 800043d6 <end_op>
  p = myproc();
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	916080e7          	jalr	-1770(ra) # 800019a6 <myproc>
    80005098:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000509a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000509e:	6985                	lui	s3,0x1
    800050a0:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    800050a2:	99ca                	add	s3,s3,s2
    800050a4:	77fd                	lui	a5,0xfffff
    800050a6:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050aa:	4691                	li	a3,4
    800050ac:	6609                	lui	a2,0x2
    800050ae:	964e                	add	a2,a2,s3
    800050b0:	85ce                	mv	a1,s3
    800050b2:	855a                	mv	a0,s6
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	356080e7          	jalr	854(ra) # 8000140a <uvmalloc>
    800050bc:	892a                	mv	s2,a0
    800050be:	e0a43423          	sd	a0,-504(s0)
    800050c2:	e509                	bnez	a0,800050cc <exec+0x236>
  if(pagetable)
    800050c4:	e1343423          	sd	s3,-504(s0)
    800050c8:	4a01                	li	s4,0
    800050ca:	aa1d                	j	80005200 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050cc:	75f9                	lui	a1,0xffffe
    800050ce:	95aa                	add	a1,a1,a0
    800050d0:	855a                	mv	a0,s6
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	562080e7          	jalr	1378(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    800050da:	7bfd                	lui	s7,0xfffff
    800050dc:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800050de:	e0043783          	ld	a5,-512(s0)
    800050e2:	6388                	ld	a0,0(a5)
    800050e4:	c52d                	beqz	a0,8000514e <exec+0x2b8>
    800050e6:	e9040993          	add	s3,s0,-368
    800050ea:	f9040c13          	add	s8,s0,-112
    800050ee:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	d58080e7          	jalr	-680(ra) # 80000e48 <strlen>
    800050f8:	0015079b          	addw	a5,a0,1
    800050fc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005100:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005104:	13796563          	bltu	s2,s7,8000522e <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005108:	e0043d03          	ld	s10,-512(s0)
    8000510c:	000d3a03          	ld	s4,0(s10)
    80005110:	8552                	mv	a0,s4
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	d36080e7          	jalr	-714(ra) # 80000e48 <strlen>
    8000511a:	0015069b          	addw	a3,a0,1
    8000511e:	8652                	mv	a2,s4
    80005120:	85ca                	mv	a1,s2
    80005122:	855a                	mv	a0,s6
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	542080e7          	jalr	1346(ra) # 80001666 <copyout>
    8000512c:	10054363          	bltz	a0,80005232 <exec+0x39c>
    ustack[argc] = sp;
    80005130:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005134:	0485                	add	s1,s1,1
    80005136:	008d0793          	add	a5,s10,8
    8000513a:	e0f43023          	sd	a5,-512(s0)
    8000513e:	008d3503          	ld	a0,8(s10)
    80005142:	c909                	beqz	a0,80005154 <exec+0x2be>
    if(argc >= MAXARG)
    80005144:	09a1                	add	s3,s3,8
    80005146:	fb8995e3          	bne	s3,s8,800050f0 <exec+0x25a>
  ip = 0;
    8000514a:	4a01                	li	s4,0
    8000514c:	a855                	j	80005200 <exec+0x36a>
  sp = sz;
    8000514e:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005152:	4481                	li	s1,0
  ustack[argc] = 0;
    80005154:	00349793          	sll	a5,s1,0x3
    80005158:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffda820>
    8000515c:	97a2                	add	a5,a5,s0
    8000515e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005162:	00148693          	add	a3,s1,1
    80005166:	068e                	sll	a3,a3,0x3
    80005168:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000516c:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005170:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005174:	f57968e3          	bltu	s2,s7,800050c4 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005178:	e9040613          	add	a2,s0,-368
    8000517c:	85ca                	mv	a1,s2
    8000517e:	855a                	mv	a0,s6
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	4e6080e7          	jalr	1254(ra) # 80001666 <copyout>
    80005188:	0a054763          	bltz	a0,80005236 <exec+0x3a0>
  p->trapframe->a1 = sp;
    8000518c:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005190:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005194:	df843783          	ld	a5,-520(s0)
    80005198:	0007c703          	lbu	a4,0(a5)
    8000519c:	cf11                	beqz	a4,800051b8 <exec+0x322>
    8000519e:	0785                	add	a5,a5,1
    if(*s == '/')
    800051a0:	02f00693          	li	a3,47
    800051a4:	a039                	j	800051b2 <exec+0x31c>
      last = s+1;
    800051a6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800051aa:	0785                	add	a5,a5,1
    800051ac:	fff7c703          	lbu	a4,-1(a5)
    800051b0:	c701                	beqz	a4,800051b8 <exec+0x322>
    if(*s == '/')
    800051b2:	fed71ce3          	bne	a4,a3,800051aa <exec+0x314>
    800051b6:	bfc5                	j	800051a6 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800051b8:	4641                	li	a2,16
    800051ba:	df843583          	ld	a1,-520(s0)
    800051be:	158a8513          	add	a0,s5,344
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	c54080e7          	jalr	-940(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    800051ca:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051ce:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800051d2:	e0843783          	ld	a5,-504(s0)
    800051d6:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051da:	058ab783          	ld	a5,88(s5)
    800051de:	e6843703          	ld	a4,-408(s0)
    800051e2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051e4:	058ab783          	ld	a5,88(s5)
    800051e8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ec:	85e6                	mv	a1,s9
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	918080e7          	jalr	-1768(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051f6:	0004851b          	sext.w	a0,s1
    800051fa:	bb15                	j	80004f2e <exec+0x98>
    800051fc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005200:	e0843583          	ld	a1,-504(s0)
    80005204:	855a                	mv	a0,s6
    80005206:	ffffd097          	auipc	ra,0xffffd
    8000520a:	900080e7          	jalr	-1792(ra) # 80001b06 <proc_freepagetable>
  return -1;
    8000520e:	557d                	li	a0,-1
  if(ip){
    80005210:	d00a0fe3          	beqz	s4,80004f2e <exec+0x98>
    80005214:	b319                	j	80004f1a <exec+0x84>
    80005216:	e1243423          	sd	s2,-504(s0)
    8000521a:	b7dd                	j	80005200 <exec+0x36a>
    8000521c:	e1243423          	sd	s2,-504(s0)
    80005220:	b7c5                	j	80005200 <exec+0x36a>
    80005222:	e1243423          	sd	s2,-504(s0)
    80005226:	bfe9                	j	80005200 <exec+0x36a>
    80005228:	e1243423          	sd	s2,-504(s0)
    8000522c:	bfd1                	j	80005200 <exec+0x36a>
  ip = 0;
    8000522e:	4a01                	li	s4,0
    80005230:	bfc1                	j	80005200 <exec+0x36a>
    80005232:	4a01                	li	s4,0
  if(pagetable)
    80005234:	b7f1                	j	80005200 <exec+0x36a>
  sz = sz1;
    80005236:	e0843983          	ld	s3,-504(s0)
    8000523a:	b569                	j	800050c4 <exec+0x22e>

000000008000523c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000523c:	7179                	add	sp,sp,-48
    8000523e:	f406                	sd	ra,40(sp)
    80005240:	f022                	sd	s0,32(sp)
    80005242:	ec26                	sd	s1,24(sp)
    80005244:	e84a                	sd	s2,16(sp)
    80005246:	1800                	add	s0,sp,48
    80005248:	892e                	mv	s2,a1
    8000524a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000524c:	fdc40593          	add	a1,s0,-36
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	a5e080e7          	jalr	-1442(ra) # 80002cae <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005258:	fdc42703          	lw	a4,-36(s0)
    8000525c:	47bd                	li	a5,15
    8000525e:	02e7eb63          	bltu	a5,a4,80005294 <argfd+0x58>
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	744080e7          	jalr	1860(ra) # 800019a6 <myproc>
    8000526a:	fdc42703          	lw	a4,-36(s0)
    8000526e:	01a70793          	add	a5,a4,26
    80005272:	078e                	sll	a5,a5,0x3
    80005274:	953e                	add	a0,a0,a5
    80005276:	611c                	ld	a5,0(a0)
    80005278:	c385                	beqz	a5,80005298 <argfd+0x5c>
    return -1;
  if(pfd)
    8000527a:	00090463          	beqz	s2,80005282 <argfd+0x46>
    *pfd = fd;
    8000527e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005282:	4501                	li	a0,0
  if(pf)
    80005284:	c091                	beqz	s1,80005288 <argfd+0x4c>
    *pf = f;
    80005286:	e09c                	sd	a5,0(s1)
}
    80005288:	70a2                	ld	ra,40(sp)
    8000528a:	7402                	ld	s0,32(sp)
    8000528c:	64e2                	ld	s1,24(sp)
    8000528e:	6942                	ld	s2,16(sp)
    80005290:	6145                	add	sp,sp,48
    80005292:	8082                	ret
    return -1;
    80005294:	557d                	li	a0,-1
    80005296:	bfcd                	j	80005288 <argfd+0x4c>
    80005298:	557d                	li	a0,-1
    8000529a:	b7fd                	j	80005288 <argfd+0x4c>

000000008000529c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000529c:	1101                	add	sp,sp,-32
    8000529e:	ec06                	sd	ra,24(sp)
    800052a0:	e822                	sd	s0,16(sp)
    800052a2:	e426                	sd	s1,8(sp)
    800052a4:	1000                	add	s0,sp,32
    800052a6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	6fe080e7          	jalr	1790(ra) # 800019a6 <myproc>
    800052b0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052b2:	0d050793          	add	a5,a0,208
    800052b6:	4501                	li	a0,0
    800052b8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ba:	6398                	ld	a4,0(a5)
    800052bc:	cb19                	beqz	a4,800052d2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052be:	2505                	addw	a0,a0,1
    800052c0:	07a1                	add	a5,a5,8
    800052c2:	fed51ce3          	bne	a0,a3,800052ba <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052c6:	557d                	li	a0,-1
}
    800052c8:	60e2                	ld	ra,24(sp)
    800052ca:	6442                	ld	s0,16(sp)
    800052cc:	64a2                	ld	s1,8(sp)
    800052ce:	6105                	add	sp,sp,32
    800052d0:	8082                	ret
      p->ofile[fd] = f;
    800052d2:	01a50793          	add	a5,a0,26
    800052d6:	078e                	sll	a5,a5,0x3
    800052d8:	963e                	add	a2,a2,a5
    800052da:	e204                	sd	s1,0(a2)
      return fd;
    800052dc:	b7f5                	j	800052c8 <fdalloc+0x2c>

00000000800052de <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052de:	715d                	add	sp,sp,-80
    800052e0:	e486                	sd	ra,72(sp)
    800052e2:	e0a2                	sd	s0,64(sp)
    800052e4:	fc26                	sd	s1,56(sp)
    800052e6:	f84a                	sd	s2,48(sp)
    800052e8:	f44e                	sd	s3,40(sp)
    800052ea:	f052                	sd	s4,32(sp)
    800052ec:	ec56                	sd	s5,24(sp)
    800052ee:	e85a                	sd	s6,16(sp)
    800052f0:	0880                	add	s0,sp,80
    800052f2:	8b2e                	mv	s6,a1
    800052f4:	89b2                	mv	s3,a2
    800052f6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052f8:	fb040593          	add	a1,s0,-80
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	e7e080e7          	jalr	-386(ra) # 8000417a <nameiparent>
    80005304:	84aa                	mv	s1,a0
    80005306:	14050b63          	beqz	a0,8000545c <create+0x17e>
    return 0;

  ilock(dp);
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	6ac080e7          	jalr	1708(ra) # 800039b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005312:	4601                	li	a2,0
    80005314:	fb040593          	add	a1,s0,-80
    80005318:	8526                	mv	a0,s1
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	b80080e7          	jalr	-1152(ra) # 80003e9a <dirlookup>
    80005322:	8aaa                	mv	s5,a0
    80005324:	c921                	beqz	a0,80005374 <create+0x96>
    iunlockput(dp);
    80005326:	8526                	mv	a0,s1
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	8f0080e7          	jalr	-1808(ra) # 80003c18 <iunlockput>
    ilock(ip);
    80005330:	8556                	mv	a0,s5
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	684080e7          	jalr	1668(ra) # 800039b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000533a:	4789                	li	a5,2
    8000533c:	02fb1563          	bne	s6,a5,80005366 <create+0x88>
    80005340:	044ad783          	lhu	a5,68(s5)
    80005344:	37f9                	addw	a5,a5,-2
    80005346:	17c2                	sll	a5,a5,0x30
    80005348:	93c1                	srl	a5,a5,0x30
    8000534a:	4705                	li	a4,1
    8000534c:	00f76d63          	bltu	a4,a5,80005366 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005350:	8556                	mv	a0,s5
    80005352:	60a6                	ld	ra,72(sp)
    80005354:	6406                	ld	s0,64(sp)
    80005356:	74e2                	ld	s1,56(sp)
    80005358:	7942                	ld	s2,48(sp)
    8000535a:	79a2                	ld	s3,40(sp)
    8000535c:	7a02                	ld	s4,32(sp)
    8000535e:	6ae2                	ld	s5,24(sp)
    80005360:	6b42                	ld	s6,16(sp)
    80005362:	6161                	add	sp,sp,80
    80005364:	8082                	ret
    iunlockput(ip);
    80005366:	8556                	mv	a0,s5
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	8b0080e7          	jalr	-1872(ra) # 80003c18 <iunlockput>
    return 0;
    80005370:	4a81                	li	s5,0
    80005372:	bff9                	j	80005350 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005374:	85da                	mv	a1,s6
    80005376:	4088                	lw	a0,0(s1)
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	4a6080e7          	jalr	1190(ra) # 8000381e <ialloc>
    80005380:	8a2a                	mv	s4,a0
    80005382:	c529                	beqz	a0,800053cc <create+0xee>
  ilock(ip);
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	632080e7          	jalr	1586(ra) # 800039b6 <ilock>
  ip->major = major;
    8000538c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005390:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005394:	4905                	li	s2,1
    80005396:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000539a:	8552                	mv	a0,s4
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	54e080e7          	jalr	1358(ra) # 800038ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053a4:	032b0b63          	beq	s6,s2,800053da <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053a8:	004a2603          	lw	a2,4(s4)
    800053ac:	fb040593          	add	a1,s0,-80
    800053b0:	8526                	mv	a0,s1
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	cf8080e7          	jalr	-776(ra) # 800040aa <dirlink>
    800053ba:	06054f63          	bltz	a0,80005438 <create+0x15a>
  iunlockput(dp);
    800053be:	8526                	mv	a0,s1
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	858080e7          	jalr	-1960(ra) # 80003c18 <iunlockput>
  return ip;
    800053c8:	8ad2                	mv	s5,s4
    800053ca:	b759                	j	80005350 <create+0x72>
    iunlockput(dp);
    800053cc:	8526                	mv	a0,s1
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	84a080e7          	jalr	-1974(ra) # 80003c18 <iunlockput>
    return 0;
    800053d6:	8ad2                	mv	s5,s4
    800053d8:	bfa5                	j	80005350 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053da:	004a2603          	lw	a2,4(s4)
    800053de:	00003597          	auipc	a1,0x3
    800053e2:	31a58593          	add	a1,a1,794 # 800086f8 <syscalls+0x2c0>
    800053e6:	8552                	mv	a0,s4
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	cc2080e7          	jalr	-830(ra) # 800040aa <dirlink>
    800053f0:	04054463          	bltz	a0,80005438 <create+0x15a>
    800053f4:	40d0                	lw	a2,4(s1)
    800053f6:	00003597          	auipc	a1,0x3
    800053fa:	30a58593          	add	a1,a1,778 # 80008700 <syscalls+0x2c8>
    800053fe:	8552                	mv	a0,s4
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	caa080e7          	jalr	-854(ra) # 800040aa <dirlink>
    80005408:	02054863          	bltz	a0,80005438 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    8000540c:	004a2603          	lw	a2,4(s4)
    80005410:	fb040593          	add	a1,s0,-80
    80005414:	8526                	mv	a0,s1
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	c94080e7          	jalr	-876(ra) # 800040aa <dirlink>
    8000541e:	00054d63          	bltz	a0,80005438 <create+0x15a>
    dp->nlink++;  // for ".."
    80005422:	04a4d783          	lhu	a5,74(s1)
    80005426:	2785                	addw	a5,a5,1
    80005428:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	4bc080e7          	jalr	1212(ra) # 800038ea <iupdate>
    80005436:	b761                	j	800053be <create+0xe0>
  ip->nlink = 0;
    80005438:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000543c:	8552                	mv	a0,s4
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	4ac080e7          	jalr	1196(ra) # 800038ea <iupdate>
  iunlockput(ip);
    80005446:	8552                	mv	a0,s4
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	7d0080e7          	jalr	2000(ra) # 80003c18 <iunlockput>
  iunlockput(dp);
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	7c6080e7          	jalr	1990(ra) # 80003c18 <iunlockput>
  return 0;
    8000545a:	bddd                	j	80005350 <create+0x72>
    return 0;
    8000545c:	8aaa                	mv	s5,a0
    8000545e:	bdcd                	j	80005350 <create+0x72>

0000000080005460 <sys_dup>:
{
    80005460:	7179                	add	sp,sp,-48
    80005462:	f406                	sd	ra,40(sp)
    80005464:	f022                	sd	s0,32(sp)
    80005466:	ec26                	sd	s1,24(sp)
    80005468:	e84a                	sd	s2,16(sp)
    8000546a:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000546c:	fd840613          	add	a2,s0,-40
    80005470:	4581                	li	a1,0
    80005472:	4501                	li	a0,0
    80005474:	00000097          	auipc	ra,0x0
    80005478:	dc8080e7          	jalr	-568(ra) # 8000523c <argfd>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000547e:	02054363          	bltz	a0,800054a4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005482:	fd843903          	ld	s2,-40(s0)
    80005486:	854a                	mv	a0,s2
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	e14080e7          	jalr	-492(ra) # 8000529c <fdalloc>
    80005490:	84aa                	mv	s1,a0
    return -1;
    80005492:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005494:	00054863          	bltz	a0,800054a4 <sys_dup+0x44>
  filedup(f);
    80005498:	854a                	mv	a0,s2
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	334080e7          	jalr	820(ra) # 800047ce <filedup>
  return fd;
    800054a2:	87a6                	mv	a5,s1
}
    800054a4:	853e                	mv	a0,a5
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	64e2                	ld	s1,24(sp)
    800054ac:	6942                	ld	s2,16(sp)
    800054ae:	6145                	add	sp,sp,48
    800054b0:	8082                	ret

00000000800054b2 <sys_read>:
{
    800054b2:	7179                	add	sp,sp,-48
    800054b4:	f406                	sd	ra,40(sp)
    800054b6:	f022                	sd	s0,32(sp)
    800054b8:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800054ba:	fd840593          	add	a1,s0,-40
    800054be:	4505                	li	a0,1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	80e080e7          	jalr	-2034(ra) # 80002cce <argaddr>
  argint(2, &n);
    800054c8:	fe440593          	add	a1,s0,-28
    800054cc:	4509                	li	a0,2
    800054ce:	ffffd097          	auipc	ra,0xffffd
    800054d2:	7e0080e7          	jalr	2016(ra) # 80002cae <argint>
  if(argfd(0, 0, &f) < 0)
    800054d6:	fe840613          	add	a2,s0,-24
    800054da:	4581                	li	a1,0
    800054dc:	4501                	li	a0,0
    800054de:	00000097          	auipc	ra,0x0
    800054e2:	d5e080e7          	jalr	-674(ra) # 8000523c <argfd>
    800054e6:	87aa                	mv	a5,a0
    return -1;
    800054e8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054ea:	0007cc63          	bltz	a5,80005502 <sys_read+0x50>
  return fileread(f, p, n);
    800054ee:	fe442603          	lw	a2,-28(s0)
    800054f2:	fd843583          	ld	a1,-40(s0)
    800054f6:	fe843503          	ld	a0,-24(s0)
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	460080e7          	jalr	1120(ra) # 8000495a <fileread>
}
    80005502:	70a2                	ld	ra,40(sp)
    80005504:	7402                	ld	s0,32(sp)
    80005506:	6145                	add	sp,sp,48
    80005508:	8082                	ret

000000008000550a <sys_write>:
{
    8000550a:	7179                	add	sp,sp,-48
    8000550c:	f406                	sd	ra,40(sp)
    8000550e:	f022                	sd	s0,32(sp)
    80005510:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005512:	fd840593          	add	a1,s0,-40
    80005516:	4505                	li	a0,1
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	7b6080e7          	jalr	1974(ra) # 80002cce <argaddr>
  argint(2, &n);
    80005520:	fe440593          	add	a1,s0,-28
    80005524:	4509                	li	a0,2
    80005526:	ffffd097          	auipc	ra,0xffffd
    8000552a:	788080e7          	jalr	1928(ra) # 80002cae <argint>
  if(argfd(0, 0, &f) < 0)
    8000552e:	fe840613          	add	a2,s0,-24
    80005532:	4581                	li	a1,0
    80005534:	4501                	li	a0,0
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	d06080e7          	jalr	-762(ra) # 8000523c <argfd>
    8000553e:	87aa                	mv	a5,a0
    return -1;
    80005540:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005542:	0007cc63          	bltz	a5,8000555a <sys_write+0x50>
  return filewrite(f, p, n);
    80005546:	fe442603          	lw	a2,-28(s0)
    8000554a:	fd843583          	ld	a1,-40(s0)
    8000554e:	fe843503          	ld	a0,-24(s0)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	4ca080e7          	jalr	1226(ra) # 80004a1c <filewrite>
}
    8000555a:	70a2                	ld	ra,40(sp)
    8000555c:	7402                	ld	s0,32(sp)
    8000555e:	6145                	add	sp,sp,48
    80005560:	8082                	ret

0000000080005562 <sys_close>:
{
    80005562:	1101                	add	sp,sp,-32
    80005564:	ec06                	sd	ra,24(sp)
    80005566:	e822                	sd	s0,16(sp)
    80005568:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000556a:	fe040613          	add	a2,s0,-32
    8000556e:	fec40593          	add	a1,s0,-20
    80005572:	4501                	li	a0,0
    80005574:	00000097          	auipc	ra,0x0
    80005578:	cc8080e7          	jalr	-824(ra) # 8000523c <argfd>
    return -1;
    8000557c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000557e:	02054463          	bltz	a0,800055a6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	424080e7          	jalr	1060(ra) # 800019a6 <myproc>
    8000558a:	fec42783          	lw	a5,-20(s0)
    8000558e:	07e9                	add	a5,a5,26
    80005590:	078e                	sll	a5,a5,0x3
    80005592:	953e                	add	a0,a0,a5
    80005594:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005598:	fe043503          	ld	a0,-32(s0)
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	284080e7          	jalr	644(ra) # 80004820 <fileclose>
  return 0;
    800055a4:	4781                	li	a5,0
}
    800055a6:	853e                	mv	a0,a5
    800055a8:	60e2                	ld	ra,24(sp)
    800055aa:	6442                	ld	s0,16(sp)
    800055ac:	6105                	add	sp,sp,32
    800055ae:	8082                	ret

00000000800055b0 <sys_fstat>:
{
    800055b0:	1101                	add	sp,sp,-32
    800055b2:	ec06                	sd	ra,24(sp)
    800055b4:	e822                	sd	s0,16(sp)
    800055b6:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800055b8:	fe040593          	add	a1,s0,-32
    800055bc:	4505                	li	a0,1
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	710080e7          	jalr	1808(ra) # 80002cce <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055c6:	fe840613          	add	a2,s0,-24
    800055ca:	4581                	li	a1,0
    800055cc:	4501                	li	a0,0
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	c6e080e7          	jalr	-914(ra) # 8000523c <argfd>
    800055d6:	87aa                	mv	a5,a0
    return -1;
    800055d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055da:	0007ca63          	bltz	a5,800055ee <sys_fstat+0x3e>
  return filestat(f, st);
    800055de:	fe043583          	ld	a1,-32(s0)
    800055e2:	fe843503          	ld	a0,-24(s0)
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	302080e7          	jalr	770(ra) # 800048e8 <filestat>
}
    800055ee:	60e2                	ld	ra,24(sp)
    800055f0:	6442                	ld	s0,16(sp)
    800055f2:	6105                	add	sp,sp,32
    800055f4:	8082                	ret

00000000800055f6 <sys_link>:
{
    800055f6:	7169                	add	sp,sp,-304
    800055f8:	f606                	sd	ra,296(sp)
    800055fa:	f222                	sd	s0,288(sp)
    800055fc:	ee26                	sd	s1,280(sp)
    800055fe:	ea4a                	sd	s2,272(sp)
    80005600:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005602:	08000613          	li	a2,128
    80005606:	ed040593          	add	a1,s0,-304
    8000560a:	4501                	li	a0,0
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	6e2080e7          	jalr	1762(ra) # 80002cee <argstr>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005616:	10054e63          	bltz	a0,80005732 <sys_link+0x13c>
    8000561a:	08000613          	li	a2,128
    8000561e:	f5040593          	add	a1,s0,-176
    80005622:	4505                	li	a0,1
    80005624:	ffffd097          	auipc	ra,0xffffd
    80005628:	6ca080e7          	jalr	1738(ra) # 80002cee <argstr>
    return -1;
    8000562c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562e:	10054263          	bltz	a0,80005732 <sys_link+0x13c>
  begin_op();
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	d2a080e7          	jalr	-726(ra) # 8000435c <begin_op>
  if((ip = namei(old)) == 0){
    8000563a:	ed040513          	add	a0,s0,-304
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	b1e080e7          	jalr	-1250(ra) # 8000415c <namei>
    80005646:	84aa                	mv	s1,a0
    80005648:	c551                	beqz	a0,800056d4 <sys_link+0xde>
  ilock(ip);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	36c080e7          	jalr	876(ra) # 800039b6 <ilock>
  if(ip->type == T_DIR){
    80005652:	04449703          	lh	a4,68(s1)
    80005656:	4785                	li	a5,1
    80005658:	08f70463          	beq	a4,a5,800056e0 <sys_link+0xea>
  ip->nlink++;
    8000565c:	04a4d783          	lhu	a5,74(s1)
    80005660:	2785                	addw	a5,a5,1
    80005662:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	282080e7          	jalr	642(ra) # 800038ea <iupdate>
  iunlock(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	406080e7          	jalr	1030(ra) # 80003a78 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000567a:	fd040593          	add	a1,s0,-48
    8000567e:	f5040513          	add	a0,s0,-176
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	af8080e7          	jalr	-1288(ra) # 8000417a <nameiparent>
    8000568a:	892a                	mv	s2,a0
    8000568c:	c935                	beqz	a0,80005700 <sys_link+0x10a>
  ilock(dp);
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	328080e7          	jalr	808(ra) # 800039b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005696:	00092703          	lw	a4,0(s2)
    8000569a:	409c                	lw	a5,0(s1)
    8000569c:	04f71d63          	bne	a4,a5,800056f6 <sys_link+0x100>
    800056a0:	40d0                	lw	a2,4(s1)
    800056a2:	fd040593          	add	a1,s0,-48
    800056a6:	854a                	mv	a0,s2
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	a02080e7          	jalr	-1534(ra) # 800040aa <dirlink>
    800056b0:	04054363          	bltz	a0,800056f6 <sys_link+0x100>
  iunlockput(dp);
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	562080e7          	jalr	1378(ra) # 80003c18 <iunlockput>
  iput(ip);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	4b0080e7          	jalr	1200(ra) # 80003b70 <iput>
  end_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	d0e080e7          	jalr	-754(ra) # 800043d6 <end_op>
  return 0;
    800056d0:	4781                	li	a5,0
    800056d2:	a085                	j	80005732 <sys_link+0x13c>
    end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	d02080e7          	jalr	-766(ra) # 800043d6 <end_op>
    return -1;
    800056dc:	57fd                	li	a5,-1
    800056de:	a891                	j	80005732 <sys_link+0x13c>
    iunlockput(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	536080e7          	jalr	1334(ra) # 80003c18 <iunlockput>
    end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	cec080e7          	jalr	-788(ra) # 800043d6 <end_op>
    return -1;
    800056f2:	57fd                	li	a5,-1
    800056f4:	a83d                	j	80005732 <sys_link+0x13c>
    iunlockput(dp);
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	520080e7          	jalr	1312(ra) # 80003c18 <iunlockput>
  ilock(ip);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	2b4080e7          	jalr	692(ra) # 800039b6 <ilock>
  ip->nlink--;
    8000570a:	04a4d783          	lhu	a5,74(s1)
    8000570e:	37fd                	addw	a5,a5,-1
    80005710:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	1d4080e7          	jalr	468(ra) # 800038ea <iupdate>
  iunlockput(ip);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	4f8080e7          	jalr	1272(ra) # 80003c18 <iunlockput>
  end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	cae080e7          	jalr	-850(ra) # 800043d6 <end_op>
  return -1;
    80005730:	57fd                	li	a5,-1
}
    80005732:	853e                	mv	a0,a5
    80005734:	70b2                	ld	ra,296(sp)
    80005736:	7412                	ld	s0,288(sp)
    80005738:	64f2                	ld	s1,280(sp)
    8000573a:	6952                	ld	s2,272(sp)
    8000573c:	6155                	add	sp,sp,304
    8000573e:	8082                	ret

0000000080005740 <sys_unlink>:
{
    80005740:	7151                	add	sp,sp,-240
    80005742:	f586                	sd	ra,232(sp)
    80005744:	f1a2                	sd	s0,224(sp)
    80005746:	eda6                	sd	s1,216(sp)
    80005748:	e9ca                	sd	s2,208(sp)
    8000574a:	e5ce                	sd	s3,200(sp)
    8000574c:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000574e:	08000613          	li	a2,128
    80005752:	f3040593          	add	a1,s0,-208
    80005756:	4501                	li	a0,0
    80005758:	ffffd097          	auipc	ra,0xffffd
    8000575c:	596080e7          	jalr	1430(ra) # 80002cee <argstr>
    80005760:	18054163          	bltz	a0,800058e2 <sys_unlink+0x1a2>
  begin_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	bf8080e7          	jalr	-1032(ra) # 8000435c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000576c:	fb040593          	add	a1,s0,-80
    80005770:	f3040513          	add	a0,s0,-208
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	a06080e7          	jalr	-1530(ra) # 8000417a <nameiparent>
    8000577c:	84aa                	mv	s1,a0
    8000577e:	c979                	beqz	a0,80005854 <sys_unlink+0x114>
  ilock(dp);
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	236080e7          	jalr	566(ra) # 800039b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005788:	00003597          	auipc	a1,0x3
    8000578c:	f7058593          	add	a1,a1,-144 # 800086f8 <syscalls+0x2c0>
    80005790:	fb040513          	add	a0,s0,-80
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	6ec080e7          	jalr	1772(ra) # 80003e80 <namecmp>
    8000579c:	14050a63          	beqz	a0,800058f0 <sys_unlink+0x1b0>
    800057a0:	00003597          	auipc	a1,0x3
    800057a4:	f6058593          	add	a1,a1,-160 # 80008700 <syscalls+0x2c8>
    800057a8:	fb040513          	add	a0,s0,-80
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	6d4080e7          	jalr	1748(ra) # 80003e80 <namecmp>
    800057b4:	12050e63          	beqz	a0,800058f0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057b8:	f2c40613          	add	a2,s0,-212
    800057bc:	fb040593          	add	a1,s0,-80
    800057c0:	8526                	mv	a0,s1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	6d8080e7          	jalr	1752(ra) # 80003e9a <dirlookup>
    800057ca:	892a                	mv	s2,a0
    800057cc:	12050263          	beqz	a0,800058f0 <sys_unlink+0x1b0>
  ilock(ip);
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	1e6080e7          	jalr	486(ra) # 800039b6 <ilock>
  if(ip->nlink < 1)
    800057d8:	04a91783          	lh	a5,74(s2)
    800057dc:	08f05263          	blez	a5,80005860 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057e0:	04491703          	lh	a4,68(s2)
    800057e4:	4785                	li	a5,1
    800057e6:	08f70563          	beq	a4,a5,80005870 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ea:	4641                	li	a2,16
    800057ec:	4581                	li	a1,0
    800057ee:	fc040513          	add	a0,s0,-64
    800057f2:	ffffb097          	auipc	ra,0xffffb
    800057f6:	4dc080e7          	jalr	1244(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057fa:	4741                	li	a4,16
    800057fc:	f2c42683          	lw	a3,-212(s0)
    80005800:	fc040613          	add	a2,s0,-64
    80005804:	4581                	li	a1,0
    80005806:	8526                	mv	a0,s1
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	55a080e7          	jalr	1370(ra) # 80003d62 <writei>
    80005810:	47c1                	li	a5,16
    80005812:	0af51563          	bne	a0,a5,800058bc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005816:	04491703          	lh	a4,68(s2)
    8000581a:	4785                	li	a5,1
    8000581c:	0af70863          	beq	a4,a5,800058cc <sys_unlink+0x18c>
  iunlockput(dp);
    80005820:	8526                	mv	a0,s1
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	3f6080e7          	jalr	1014(ra) # 80003c18 <iunlockput>
  ip->nlink--;
    8000582a:	04a95783          	lhu	a5,74(s2)
    8000582e:	37fd                	addw	a5,a5,-1
    80005830:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005834:	854a                	mv	a0,s2
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	0b4080e7          	jalr	180(ra) # 800038ea <iupdate>
  iunlockput(ip);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	3d8080e7          	jalr	984(ra) # 80003c18 <iunlockput>
  end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	b8e080e7          	jalr	-1138(ra) # 800043d6 <end_op>
  return 0;
    80005850:	4501                	li	a0,0
    80005852:	a84d                	j	80005904 <sys_unlink+0x1c4>
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	b82080e7          	jalr	-1150(ra) # 800043d6 <end_op>
    return -1;
    8000585c:	557d                	li	a0,-1
    8000585e:	a05d                	j	80005904 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005860:	00003517          	auipc	a0,0x3
    80005864:	ea850513          	add	a0,a0,-344 # 80008708 <syscalls+0x2d0>
    80005868:	ffffb097          	auipc	ra,0xffffb
    8000586c:	cd4080e7          	jalr	-812(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005870:	04c92703          	lw	a4,76(s2)
    80005874:	02000793          	li	a5,32
    80005878:	f6e7f9e3          	bgeu	a5,a4,800057ea <sys_unlink+0xaa>
    8000587c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005880:	4741                	li	a4,16
    80005882:	86ce                	mv	a3,s3
    80005884:	f1840613          	add	a2,s0,-232
    80005888:	4581                	li	a1,0
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	3de080e7          	jalr	990(ra) # 80003c6a <readi>
    80005894:	47c1                	li	a5,16
    80005896:	00f51b63          	bne	a0,a5,800058ac <sys_unlink+0x16c>
    if(de.inum != 0)
    8000589a:	f1845783          	lhu	a5,-232(s0)
    8000589e:	e7a1                	bnez	a5,800058e6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058a0:	29c1                	addw	s3,s3,16
    800058a2:	04c92783          	lw	a5,76(s2)
    800058a6:	fcf9ede3          	bltu	s3,a5,80005880 <sys_unlink+0x140>
    800058aa:	b781                	j	800057ea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ac:	00003517          	auipc	a0,0x3
    800058b0:	e7450513          	add	a0,a0,-396 # 80008720 <syscalls+0x2e8>
    800058b4:	ffffb097          	auipc	ra,0xffffb
    800058b8:	c88080e7          	jalr	-888(ra) # 8000053c <panic>
    panic("unlink: writei");
    800058bc:	00003517          	auipc	a0,0x3
    800058c0:	e7c50513          	add	a0,a0,-388 # 80008738 <syscalls+0x300>
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	c78080e7          	jalr	-904(ra) # 8000053c <panic>
    dp->nlink--;
    800058cc:	04a4d783          	lhu	a5,74(s1)
    800058d0:	37fd                	addw	a5,a5,-1
    800058d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	012080e7          	jalr	18(ra) # 800038ea <iupdate>
    800058e0:	b781                	j	80005820 <sys_unlink+0xe0>
    return -1;
    800058e2:	557d                	li	a0,-1
    800058e4:	a005                	j	80005904 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058e6:	854a                	mv	a0,s2
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	330080e7          	jalr	816(ra) # 80003c18 <iunlockput>
  iunlockput(dp);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	326080e7          	jalr	806(ra) # 80003c18 <iunlockput>
  end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	adc080e7          	jalr	-1316(ra) # 800043d6 <end_op>
  return -1;
    80005902:	557d                	li	a0,-1
}
    80005904:	70ae                	ld	ra,232(sp)
    80005906:	740e                	ld	s0,224(sp)
    80005908:	64ee                	ld	s1,216(sp)
    8000590a:	694e                	ld	s2,208(sp)
    8000590c:	69ae                	ld	s3,200(sp)
    8000590e:	616d                	add	sp,sp,240
    80005910:	8082                	ret

0000000080005912 <sys_open>:

uint64
sys_open(void)
{
    80005912:	7131                	add	sp,sp,-192
    80005914:	fd06                	sd	ra,184(sp)
    80005916:	f922                	sd	s0,176(sp)
    80005918:	f526                	sd	s1,168(sp)
    8000591a:	f14a                	sd	s2,160(sp)
    8000591c:	ed4e                	sd	s3,152(sp)
    8000591e:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005920:	f4c40593          	add	a1,s0,-180
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	388080e7          	jalr	904(ra) # 80002cae <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000592e:	08000613          	li	a2,128
    80005932:	f5040593          	add	a1,s0,-176
    80005936:	4501                	li	a0,0
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	3b6080e7          	jalr	950(ra) # 80002cee <argstr>
    80005940:	87aa                	mv	a5,a0
    return -1;
    80005942:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005944:	0a07c863          	bltz	a5,800059f4 <sys_open+0xe2>

  begin_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	a14080e7          	jalr	-1516(ra) # 8000435c <begin_op>

  if(omode & O_CREATE){
    80005950:	f4c42783          	lw	a5,-180(s0)
    80005954:	2007f793          	and	a5,a5,512
    80005958:	cbdd                	beqz	a5,80005a0e <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000595a:	4681                	li	a3,0
    8000595c:	4601                	li	a2,0
    8000595e:	4589                	li	a1,2
    80005960:	f5040513          	add	a0,s0,-176
    80005964:	00000097          	auipc	ra,0x0
    80005968:	97a080e7          	jalr	-1670(ra) # 800052de <create>
    8000596c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000596e:	c951                	beqz	a0,80005a02 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005970:	04449703          	lh	a4,68(s1)
    80005974:	478d                	li	a5,3
    80005976:	00f71763          	bne	a4,a5,80005984 <sys_open+0x72>
    8000597a:	0464d703          	lhu	a4,70(s1)
    8000597e:	47a5                	li	a5,9
    80005980:	0ce7ec63          	bltu	a5,a4,80005a58 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	de0080e7          	jalr	-544(ra) # 80004764 <filealloc>
    8000598c:	892a                	mv	s2,a0
    8000598e:	c56d                	beqz	a0,80005a78 <sys_open+0x166>
    80005990:	00000097          	auipc	ra,0x0
    80005994:	90c080e7          	jalr	-1780(ra) # 8000529c <fdalloc>
    80005998:	89aa                	mv	s3,a0
    8000599a:	0c054a63          	bltz	a0,80005a6e <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000599e:	04449703          	lh	a4,68(s1)
    800059a2:	478d                	li	a5,3
    800059a4:	0ef70563          	beq	a4,a5,80005a8e <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059a8:	4789                	li	a5,2
    800059aa:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800059ae:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800059b2:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800059b6:	f4c42783          	lw	a5,-180(s0)
    800059ba:	0017c713          	xor	a4,a5,1
    800059be:	8b05                	and	a4,a4,1
    800059c0:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059c4:	0037f713          	and	a4,a5,3
    800059c8:	00e03733          	snez	a4,a4
    800059cc:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059d0:	4007f793          	and	a5,a5,1024
    800059d4:	c791                	beqz	a5,800059e0 <sys_open+0xce>
    800059d6:	04449703          	lh	a4,68(s1)
    800059da:	4789                	li	a5,2
    800059dc:	0cf70063          	beq	a4,a5,80005a9c <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	096080e7          	jalr	150(ra) # 80003a78 <iunlock>
  end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	9ec080e7          	jalr	-1556(ra) # 800043d6 <end_op>

  return fd;
    800059f2:	854e                	mv	a0,s3
}
    800059f4:	70ea                	ld	ra,184(sp)
    800059f6:	744a                	ld	s0,176(sp)
    800059f8:	74aa                	ld	s1,168(sp)
    800059fa:	790a                	ld	s2,160(sp)
    800059fc:	69ea                	ld	s3,152(sp)
    800059fe:	6129                	add	sp,sp,192
    80005a00:	8082                	ret
      end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	9d4080e7          	jalr	-1580(ra) # 800043d6 <end_op>
      return -1;
    80005a0a:	557d                	li	a0,-1
    80005a0c:	b7e5                	j	800059f4 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005a0e:	f5040513          	add	a0,s0,-176
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	74a080e7          	jalr	1866(ra) # 8000415c <namei>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c905                	beqz	a0,80005a4c <sys_open+0x13a>
    ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	f98080e7          	jalr	-104(ra) # 800039b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a26:	04449703          	lh	a4,68(s1)
    80005a2a:	4785                	li	a5,1
    80005a2c:	f4f712e3          	bne	a4,a5,80005970 <sys_open+0x5e>
    80005a30:	f4c42783          	lw	a5,-180(s0)
    80005a34:	dba1                	beqz	a5,80005984 <sys_open+0x72>
      iunlockput(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	1e0080e7          	jalr	480(ra) # 80003c18 <iunlockput>
      end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	996080e7          	jalr	-1642(ra) # 800043d6 <end_op>
      return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	b76d                	j	800059f4 <sys_open+0xe2>
      end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	98a080e7          	jalr	-1654(ra) # 800043d6 <end_op>
      return -1;
    80005a54:	557d                	li	a0,-1
    80005a56:	bf79                	j	800059f4 <sys_open+0xe2>
    iunlockput(ip);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	1be080e7          	jalr	446(ra) # 80003c18 <iunlockput>
    end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	974080e7          	jalr	-1676(ra) # 800043d6 <end_op>
    return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	b761                	j	800059f4 <sys_open+0xe2>
      fileclose(f);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	db0080e7          	jalr	-592(ra) # 80004820 <fileclose>
    iunlockput(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	19e080e7          	jalr	414(ra) # 80003c18 <iunlockput>
    end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	954080e7          	jalr	-1708(ra) # 800043d6 <end_op>
    return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	b7a5                	j	800059f4 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005a8e:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005a92:	04649783          	lh	a5,70(s1)
    80005a96:	02f91223          	sh	a5,36(s2)
    80005a9a:	bf21                	j	800059b2 <sys_open+0xa0>
    itrunc(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	026080e7          	jalr	38(ra) # 80003ac4 <itrunc>
    80005aa6:	bf2d                	j	800059e0 <sys_open+0xce>

0000000080005aa8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aa8:	7175                	add	sp,sp,-144
    80005aaa:	e506                	sd	ra,136(sp)
    80005aac:	e122                	sd	s0,128(sp)
    80005aae:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	8ac080e7          	jalr	-1876(ra) # 8000435c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ab8:	08000613          	li	a2,128
    80005abc:	f7040593          	add	a1,s0,-144
    80005ac0:	4501                	li	a0,0
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	22c080e7          	jalr	556(ra) # 80002cee <argstr>
    80005aca:	02054963          	bltz	a0,80005afc <sys_mkdir+0x54>
    80005ace:	4681                	li	a3,0
    80005ad0:	4601                	li	a2,0
    80005ad2:	4585                	li	a1,1
    80005ad4:	f7040513          	add	a0,s0,-144
    80005ad8:	00000097          	auipc	ra,0x0
    80005adc:	806080e7          	jalr	-2042(ra) # 800052de <create>
    80005ae0:	cd11                	beqz	a0,80005afc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	136080e7          	jalr	310(ra) # 80003c18 <iunlockput>
  end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	8ec080e7          	jalr	-1812(ra) # 800043d6 <end_op>
  return 0;
    80005af2:	4501                	li	a0,0
}
    80005af4:	60aa                	ld	ra,136(sp)
    80005af6:	640a                	ld	s0,128(sp)
    80005af8:	6149                	add	sp,sp,144
    80005afa:	8082                	ret
    end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	8da080e7          	jalr	-1830(ra) # 800043d6 <end_op>
    return -1;
    80005b04:	557d                	li	a0,-1
    80005b06:	b7fd                	j	80005af4 <sys_mkdir+0x4c>

0000000080005b08 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b08:	7135                	add	sp,sp,-160
    80005b0a:	ed06                	sd	ra,152(sp)
    80005b0c:	e922                	sd	s0,144(sp)
    80005b0e:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	84c080e7          	jalr	-1972(ra) # 8000435c <begin_op>
  argint(1, &major);
    80005b18:	f6c40593          	add	a1,s0,-148
    80005b1c:	4505                	li	a0,1
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	190080e7          	jalr	400(ra) # 80002cae <argint>
  argint(2, &minor);
    80005b26:	f6840593          	add	a1,s0,-152
    80005b2a:	4509                	li	a0,2
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	182080e7          	jalr	386(ra) # 80002cae <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b34:	08000613          	li	a2,128
    80005b38:	f7040593          	add	a1,s0,-144
    80005b3c:	4501                	li	a0,0
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	1b0080e7          	jalr	432(ra) # 80002cee <argstr>
    80005b46:	02054b63          	bltz	a0,80005b7c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b4a:	f6841683          	lh	a3,-152(s0)
    80005b4e:	f6c41603          	lh	a2,-148(s0)
    80005b52:	458d                	li	a1,3
    80005b54:	f7040513          	add	a0,s0,-144
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	786080e7          	jalr	1926(ra) # 800052de <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b60:	cd11                	beqz	a0,80005b7c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	0b6080e7          	jalr	182(ra) # 80003c18 <iunlockput>
  end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	86c080e7          	jalr	-1940(ra) # 800043d6 <end_op>
  return 0;
    80005b72:	4501                	li	a0,0
}
    80005b74:	60ea                	ld	ra,152(sp)
    80005b76:	644a                	ld	s0,144(sp)
    80005b78:	610d                	add	sp,sp,160
    80005b7a:	8082                	ret
    end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	85a080e7          	jalr	-1958(ra) # 800043d6 <end_op>
    return -1;
    80005b84:	557d                	li	a0,-1
    80005b86:	b7fd                	j	80005b74 <sys_mknod+0x6c>

0000000080005b88 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b88:	7135                	add	sp,sp,-160
    80005b8a:	ed06                	sd	ra,152(sp)
    80005b8c:	e922                	sd	s0,144(sp)
    80005b8e:	e526                	sd	s1,136(sp)
    80005b90:	e14a                	sd	s2,128(sp)
    80005b92:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	e12080e7          	jalr	-494(ra) # 800019a6 <myproc>
    80005b9c:	892a                	mv	s2,a0
  
  begin_op();
    80005b9e:	ffffe097          	auipc	ra,0xffffe
    80005ba2:	7be080e7          	jalr	1982(ra) # 8000435c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ba6:	08000613          	li	a2,128
    80005baa:	f6040593          	add	a1,s0,-160
    80005bae:	4501                	li	a0,0
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	13e080e7          	jalr	318(ra) # 80002cee <argstr>
    80005bb8:	04054b63          	bltz	a0,80005c0e <sys_chdir+0x86>
    80005bbc:	f6040513          	add	a0,s0,-160
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	59c080e7          	jalr	1436(ra) # 8000415c <namei>
    80005bc8:	84aa                	mv	s1,a0
    80005bca:	c131                	beqz	a0,80005c0e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	dea080e7          	jalr	-534(ra) # 800039b6 <ilock>
  if(ip->type != T_DIR){
    80005bd4:	04449703          	lh	a4,68(s1)
    80005bd8:	4785                	li	a5,1
    80005bda:	04f71063          	bne	a4,a5,80005c1a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bde:	8526                	mv	a0,s1
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	e98080e7          	jalr	-360(ra) # 80003a78 <iunlock>
  iput(p->cwd);
    80005be8:	15093503          	ld	a0,336(s2)
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	f84080e7          	jalr	-124(ra) # 80003b70 <iput>
  end_op();
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	7e2080e7          	jalr	2018(ra) # 800043d6 <end_op>
  p->cwd = ip;
    80005bfc:	14993823          	sd	s1,336(s2)
  return 0;
    80005c00:	4501                	li	a0,0
}
    80005c02:	60ea                	ld	ra,152(sp)
    80005c04:	644a                	ld	s0,144(sp)
    80005c06:	64aa                	ld	s1,136(sp)
    80005c08:	690a                	ld	s2,128(sp)
    80005c0a:	610d                	add	sp,sp,160
    80005c0c:	8082                	ret
    end_op();
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	7c8080e7          	jalr	1992(ra) # 800043d6 <end_op>
    return -1;
    80005c16:	557d                	li	a0,-1
    80005c18:	b7ed                	j	80005c02 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	ffc080e7          	jalr	-4(ra) # 80003c18 <iunlockput>
    end_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	7b2080e7          	jalr	1970(ra) # 800043d6 <end_op>
    return -1;
    80005c2c:	557d                	li	a0,-1
    80005c2e:	bfd1                	j	80005c02 <sys_chdir+0x7a>

0000000080005c30 <sys_exec>:

uint64
sys_exec(void)
{
    80005c30:	7121                	add	sp,sp,-448
    80005c32:	ff06                	sd	ra,440(sp)
    80005c34:	fb22                	sd	s0,432(sp)
    80005c36:	f726                	sd	s1,424(sp)
    80005c38:	f34a                	sd	s2,416(sp)
    80005c3a:	ef4e                	sd	s3,408(sp)
    80005c3c:	eb52                	sd	s4,400(sp)
    80005c3e:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c40:	e4840593          	add	a1,s0,-440
    80005c44:	4505                	li	a0,1
    80005c46:	ffffd097          	auipc	ra,0xffffd
    80005c4a:	088080e7          	jalr	136(ra) # 80002cce <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c4e:	08000613          	li	a2,128
    80005c52:	f5040593          	add	a1,s0,-176
    80005c56:	4501                	li	a0,0
    80005c58:	ffffd097          	auipc	ra,0xffffd
    80005c5c:	096080e7          	jalr	150(ra) # 80002cee <argstr>
    80005c60:	87aa                	mv	a5,a0
    return -1;
    80005c62:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c64:	0c07c263          	bltz	a5,80005d28 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005c68:	10000613          	li	a2,256
    80005c6c:	4581                	li	a1,0
    80005c6e:	e5040513          	add	a0,s0,-432
    80005c72:	ffffb097          	auipc	ra,0xffffb
    80005c76:	05c080e7          	jalr	92(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c7a:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005c7e:	89a6                	mv	s3,s1
    80005c80:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c82:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c86:	00391513          	sll	a0,s2,0x3
    80005c8a:	e4040593          	add	a1,s0,-448
    80005c8e:	e4843783          	ld	a5,-440(s0)
    80005c92:	953e                	add	a0,a0,a5
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	f7c080e7          	jalr	-132(ra) # 80002c10 <fetchaddr>
    80005c9c:	02054a63          	bltz	a0,80005cd0 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005ca0:	e4043783          	ld	a5,-448(s0)
    80005ca4:	c3b9                	beqz	a5,80005cea <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	e3c080e7          	jalr	-452(ra) # 80000ae2 <kalloc>
    80005cae:	85aa                	mv	a1,a0
    80005cb0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cb4:	cd11                	beqz	a0,80005cd0 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb6:	6605                	lui	a2,0x1
    80005cb8:	e4043503          	ld	a0,-448(s0)
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	fa6080e7          	jalr	-90(ra) # 80002c62 <fetchstr>
    80005cc4:	00054663          	bltz	a0,80005cd0 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005cc8:	0905                	add	s2,s2,1
    80005cca:	09a1                	add	s3,s3,8
    80005ccc:	fb491de3          	bne	s2,s4,80005c86 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd0:	f5040913          	add	s2,s0,-176
    80005cd4:	6088                	ld	a0,0(s1)
    80005cd6:	c921                	beqz	a0,80005d26 <sys_exec+0xf6>
    kfree(argv[i]);
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	d0c080e7          	jalr	-756(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce0:	04a1                	add	s1,s1,8
    80005ce2:	ff2499e3          	bne	s1,s2,80005cd4 <sys_exec+0xa4>
  return -1;
    80005ce6:	557d                	li	a0,-1
    80005ce8:	a081                	j	80005d28 <sys_exec+0xf8>
      argv[i] = 0;
    80005cea:	0009079b          	sext.w	a5,s2
    80005cee:	078e                	sll	a5,a5,0x3
    80005cf0:	fd078793          	add	a5,a5,-48
    80005cf4:	97a2                	add	a5,a5,s0
    80005cf6:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005cfa:	e5040593          	add	a1,s0,-432
    80005cfe:	f5040513          	add	a0,s0,-176
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	194080e7          	jalr	404(ra) # 80004e96 <exec>
    80005d0a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0c:	f5040993          	add	s3,s0,-176
    80005d10:	6088                	ld	a0,0(s1)
    80005d12:	c901                	beqz	a0,80005d22 <sys_exec+0xf2>
    kfree(argv[i]);
    80005d14:	ffffb097          	auipc	ra,0xffffb
    80005d18:	cd0080e7          	jalr	-816(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1c:	04a1                	add	s1,s1,8
    80005d1e:	ff3499e3          	bne	s1,s3,80005d10 <sys_exec+0xe0>
  return ret;
    80005d22:	854a                	mv	a0,s2
    80005d24:	a011                	j	80005d28 <sys_exec+0xf8>
  return -1;
    80005d26:	557d                	li	a0,-1
}
    80005d28:	70fa                	ld	ra,440(sp)
    80005d2a:	745a                	ld	s0,432(sp)
    80005d2c:	74ba                	ld	s1,424(sp)
    80005d2e:	791a                	ld	s2,416(sp)
    80005d30:	69fa                	ld	s3,408(sp)
    80005d32:	6a5a                	ld	s4,400(sp)
    80005d34:	6139                	add	sp,sp,448
    80005d36:	8082                	ret

0000000080005d38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d38:	7139                	add	sp,sp,-64
    80005d3a:	fc06                	sd	ra,56(sp)
    80005d3c:	f822                	sd	s0,48(sp)
    80005d3e:	f426                	sd	s1,40(sp)
    80005d40:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d42:	ffffc097          	auipc	ra,0xffffc
    80005d46:	c64080e7          	jalr	-924(ra) # 800019a6 <myproc>
    80005d4a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d4c:	fd840593          	add	a1,s0,-40
    80005d50:	4501                	li	a0,0
    80005d52:	ffffd097          	auipc	ra,0xffffd
    80005d56:	f7c080e7          	jalr	-132(ra) # 80002cce <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d5a:	fc840593          	add	a1,s0,-56
    80005d5e:	fd040513          	add	a0,s0,-48
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	dea080e7          	jalr	-534(ra) # 80004b4c <pipealloc>
    return -1;
    80005d6a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d6c:	0c054463          	bltz	a0,80005e34 <sys_pipe+0xfc>
  fd0 = -1;
    80005d70:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d74:	fd043503          	ld	a0,-48(s0)
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	524080e7          	jalr	1316(ra) # 8000529c <fdalloc>
    80005d80:	fca42223          	sw	a0,-60(s0)
    80005d84:	08054b63          	bltz	a0,80005e1a <sys_pipe+0xe2>
    80005d88:	fc843503          	ld	a0,-56(s0)
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	510080e7          	jalr	1296(ra) # 8000529c <fdalloc>
    80005d94:	fca42023          	sw	a0,-64(s0)
    80005d98:	06054863          	bltz	a0,80005e08 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9c:	4691                	li	a3,4
    80005d9e:	fc440613          	add	a2,s0,-60
    80005da2:	fd843583          	ld	a1,-40(s0)
    80005da6:	68a8                	ld	a0,80(s1)
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	8be080e7          	jalr	-1858(ra) # 80001666 <copyout>
    80005db0:	02054063          	bltz	a0,80005dd0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db4:	4691                	li	a3,4
    80005db6:	fc040613          	add	a2,s0,-64
    80005dba:	fd843583          	ld	a1,-40(s0)
    80005dbe:	0591                	add	a1,a1,4
    80005dc0:	68a8                	ld	a0,80(s1)
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	8a4080e7          	jalr	-1884(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dcc:	06055463          	bgez	a0,80005e34 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dd0:	fc442783          	lw	a5,-60(s0)
    80005dd4:	07e9                	add	a5,a5,26
    80005dd6:	078e                	sll	a5,a5,0x3
    80005dd8:	97a6                	add	a5,a5,s1
    80005dda:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dde:	fc042783          	lw	a5,-64(s0)
    80005de2:	07e9                	add	a5,a5,26
    80005de4:	078e                	sll	a5,a5,0x3
    80005de6:	94be                	add	s1,s1,a5
    80005de8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dec:	fd043503          	ld	a0,-48(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	a30080e7          	jalr	-1488(ra) # 80004820 <fileclose>
    fileclose(wf);
    80005df8:	fc843503          	ld	a0,-56(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	a24080e7          	jalr	-1500(ra) # 80004820 <fileclose>
    return -1;
    80005e04:	57fd                	li	a5,-1
    80005e06:	a03d                	j	80005e34 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e08:	fc442783          	lw	a5,-60(s0)
    80005e0c:	0007c763          	bltz	a5,80005e1a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e10:	07e9                	add	a5,a5,26
    80005e12:	078e                	sll	a5,a5,0x3
    80005e14:	97a6                	add	a5,a5,s1
    80005e16:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005e1a:	fd043503          	ld	a0,-48(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	a02080e7          	jalr	-1534(ra) # 80004820 <fileclose>
    fileclose(wf);
    80005e26:	fc843503          	ld	a0,-56(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	9f6080e7          	jalr	-1546(ra) # 80004820 <fileclose>
    return -1;
    80005e32:	57fd                	li	a5,-1
}
    80005e34:	853e                	mv	a0,a5
    80005e36:	70e2                	ld	ra,56(sp)
    80005e38:	7442                	ld	s0,48(sp)
    80005e3a:	74a2                	ld	s1,40(sp)
    80005e3c:	6121                	add	sp,sp,64
    80005e3e:	8082                	ret

0000000080005e40 <kernelvec>:
    80005e40:	7111                	add	sp,sp,-256
    80005e42:	e006                	sd	ra,0(sp)
    80005e44:	e40a                	sd	sp,8(sp)
    80005e46:	e80e                	sd	gp,16(sp)
    80005e48:	ec12                	sd	tp,24(sp)
    80005e4a:	f016                	sd	t0,32(sp)
    80005e4c:	f41a                	sd	t1,40(sp)
    80005e4e:	f81e                	sd	t2,48(sp)
    80005e50:	fc22                	sd	s0,56(sp)
    80005e52:	e0a6                	sd	s1,64(sp)
    80005e54:	e4aa                	sd	a0,72(sp)
    80005e56:	e8ae                	sd	a1,80(sp)
    80005e58:	ecb2                	sd	a2,88(sp)
    80005e5a:	f0b6                	sd	a3,96(sp)
    80005e5c:	f4ba                	sd	a4,104(sp)
    80005e5e:	f8be                	sd	a5,112(sp)
    80005e60:	fcc2                	sd	a6,120(sp)
    80005e62:	e146                	sd	a7,128(sp)
    80005e64:	e54a                	sd	s2,136(sp)
    80005e66:	e94e                	sd	s3,144(sp)
    80005e68:	ed52                	sd	s4,152(sp)
    80005e6a:	f156                	sd	s5,160(sp)
    80005e6c:	f55a                	sd	s6,168(sp)
    80005e6e:	f95e                	sd	s7,176(sp)
    80005e70:	fd62                	sd	s8,184(sp)
    80005e72:	e1e6                	sd	s9,192(sp)
    80005e74:	e5ea                	sd	s10,200(sp)
    80005e76:	e9ee                	sd	s11,208(sp)
    80005e78:	edf2                	sd	t3,216(sp)
    80005e7a:	f1f6                	sd	t4,224(sp)
    80005e7c:	f5fa                	sd	t5,232(sp)
    80005e7e:	f9fe                	sd	t6,240(sp)
    80005e80:	c5dfc0ef          	jal	80002adc <kerneltrap>
    80005e84:	6082                	ld	ra,0(sp)
    80005e86:	6122                	ld	sp,8(sp)
    80005e88:	61c2                	ld	gp,16(sp)
    80005e8a:	7282                	ld	t0,32(sp)
    80005e8c:	7322                	ld	t1,40(sp)
    80005e8e:	73c2                	ld	t2,48(sp)
    80005e90:	7462                	ld	s0,56(sp)
    80005e92:	6486                	ld	s1,64(sp)
    80005e94:	6526                	ld	a0,72(sp)
    80005e96:	65c6                	ld	a1,80(sp)
    80005e98:	6666                	ld	a2,88(sp)
    80005e9a:	7686                	ld	a3,96(sp)
    80005e9c:	7726                	ld	a4,104(sp)
    80005e9e:	77c6                	ld	a5,112(sp)
    80005ea0:	7866                	ld	a6,120(sp)
    80005ea2:	688a                	ld	a7,128(sp)
    80005ea4:	692a                	ld	s2,136(sp)
    80005ea6:	69ca                	ld	s3,144(sp)
    80005ea8:	6a6a                	ld	s4,152(sp)
    80005eaa:	7a8a                	ld	s5,160(sp)
    80005eac:	7b2a                	ld	s6,168(sp)
    80005eae:	7bca                	ld	s7,176(sp)
    80005eb0:	7c6a                	ld	s8,184(sp)
    80005eb2:	6c8e                	ld	s9,192(sp)
    80005eb4:	6d2e                	ld	s10,200(sp)
    80005eb6:	6dce                	ld	s11,208(sp)
    80005eb8:	6e6e                	ld	t3,216(sp)
    80005eba:	7e8e                	ld	t4,224(sp)
    80005ebc:	7f2e                	ld	t5,232(sp)
    80005ebe:	7fce                	ld	t6,240(sp)
    80005ec0:	6111                	add	sp,sp,256
    80005ec2:	10200073          	sret
    80005ec6:	00000013          	nop
    80005eca:	00000013          	nop
    80005ece:	0001                	nop

0000000080005ed0 <timervec>:
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	e10c                	sd	a1,0(a0)
    80005ed6:	e510                	sd	a2,8(a0)
    80005ed8:	e914                	sd	a3,16(a0)
    80005eda:	6d0c                	ld	a1,24(a0)
    80005edc:	7110                	ld	a2,32(a0)
    80005ede:	6194                	ld	a3,0(a1)
    80005ee0:	96b2                	add	a3,a3,a2
    80005ee2:	e194                	sd	a3,0(a1)
    80005ee4:	4589                	li	a1,2
    80005ee6:	14459073          	csrw	sip,a1
    80005eea:	6914                	ld	a3,16(a0)
    80005eec:	6510                	ld	a2,8(a0)
    80005eee:	610c                	ld	a1,0(a0)
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	30200073          	mret
	...

0000000080005efa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005efa:	1141                	add	sp,sp,-16
    80005efc:	e422                	sd	s0,8(sp)
    80005efe:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f00:	0c0007b7          	lui	a5,0xc000
    80005f04:	4705                	li	a4,1
    80005f06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f08:	c3d8                	sw	a4,4(a5)
}
    80005f0a:	6422                	ld	s0,8(sp)
    80005f0c:	0141                	add	sp,sp,16
    80005f0e:	8082                	ret

0000000080005f10 <plicinithart>:

void
plicinithart(void)
{
    80005f10:	1141                	add	sp,sp,-16
    80005f12:	e406                	sd	ra,8(sp)
    80005f14:	e022                	sd	s0,0(sp)
    80005f16:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a62080e7          	jalr	-1438(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f20:	0085171b          	sllw	a4,a0,0x8
    80005f24:	0c0027b7          	lui	a5,0xc002
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	40200713          	li	a4,1026
    80005f2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f32:	00d5151b          	sllw	a0,a0,0xd
    80005f36:	0c2017b7          	lui	a5,0xc201
    80005f3a:	97aa                	add	a5,a5,a0
    80005f3c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	add	sp,sp,16
    80005f46:	8082                	ret

0000000080005f48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f48:	1141                	add	sp,sp,-16
    80005f4a:	e406                	sd	ra,8(sp)
    80005f4c:	e022                	sd	s0,0(sp)
    80005f4e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	a2a080e7          	jalr	-1494(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f58:	00d5151b          	sllw	a0,a0,0xd
    80005f5c:	0c2017b7          	lui	a5,0xc201
    80005f60:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f62:	43c8                	lw	a0,4(a5)
    80005f64:	60a2                	ld	ra,8(sp)
    80005f66:	6402                	ld	s0,0(sp)
    80005f68:	0141                	add	sp,sp,16
    80005f6a:	8082                	ret

0000000080005f6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f6c:	1101                	add	sp,sp,-32
    80005f6e:	ec06                	sd	ra,24(sp)
    80005f70:	e822                	sd	s0,16(sp)
    80005f72:	e426                	sd	s1,8(sp)
    80005f74:	1000                	add	s0,sp,32
    80005f76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a02080e7          	jalr	-1534(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f80:	00d5151b          	sllw	a0,a0,0xd
    80005f84:	0c2017b7          	lui	a5,0xc201
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	c3c4                	sw	s1,4(a5)
}
    80005f8c:	60e2                	ld	ra,24(sp)
    80005f8e:	6442                	ld	s0,16(sp)
    80005f90:	64a2                	ld	s1,8(sp)
    80005f92:	6105                	add	sp,sp,32
    80005f94:	8082                	ret

0000000080005f96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f96:	1141                	add	sp,sp,-16
    80005f98:	e406                	sd	ra,8(sp)
    80005f9a:	e022                	sd	s0,0(sp)
    80005f9c:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005f9e:	479d                	li	a5,7
    80005fa0:	04a7cc63          	blt	a5,a0,80005ff8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005fa4:	0001e797          	auipc	a5,0x1e
    80005fa8:	68c78793          	add	a5,a5,1676 # 80024630 <disk>
    80005fac:	97aa                	add	a5,a5,a0
    80005fae:	0187c783          	lbu	a5,24(a5)
    80005fb2:	ebb9                	bnez	a5,80006008 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fb4:	00451693          	sll	a3,a0,0x4
    80005fb8:	0001e797          	auipc	a5,0x1e
    80005fbc:	67878793          	add	a5,a5,1656 # 80024630 <disk>
    80005fc0:	6398                	ld	a4,0(a5)
    80005fc2:	9736                	add	a4,a4,a3
    80005fc4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005fc8:	6398                	ld	a4,0(a5)
    80005fca:	9736                	add	a4,a4,a3
    80005fcc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005fe0:	0001e517          	auipc	a0,0x1e
    80005fe4:	66850513          	add	a0,a0,1640 # 80024648 <disk+0x18>
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	0f0080e7          	jalr	240(ra) # 800020d8 <wakeup>
}
    80005ff0:	60a2                	ld	ra,8(sp)
    80005ff2:	6402                	ld	s0,0(sp)
    80005ff4:	0141                	add	sp,sp,16
    80005ff6:	8082                	ret
    panic("free_desc 1");
    80005ff8:	00002517          	auipc	a0,0x2
    80005ffc:	75050513          	add	a0,a0,1872 # 80008748 <syscalls+0x310>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	53c080e7          	jalr	1340(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	75050513          	add	a0,a0,1872 # 80008758 <syscalls+0x320>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	52c080e7          	jalr	1324(ra) # 8000053c <panic>

0000000080006018 <virtio_disk_init>:
{
    80006018:	1101                	add	sp,sp,-32
    8000601a:	ec06                	sd	ra,24(sp)
    8000601c:	e822                	sd	s0,16(sp)
    8000601e:	e426                	sd	s1,8(sp)
    80006020:	e04a                	sd	s2,0(sp)
    80006022:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006024:	00002597          	auipc	a1,0x2
    80006028:	74458593          	add	a1,a1,1860 # 80008768 <syscalls+0x330>
    8000602c:	0001e517          	auipc	a0,0x1e
    80006030:	72c50513          	add	a0,a0,1836 # 80024758 <disk+0x128>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	b0e080e7          	jalr	-1266(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	4398                	lw	a4,0(a5)
    80006042:	2701                	sext.w	a4,a4
    80006044:	747277b7          	lui	a5,0x74727
    80006048:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000604c:	14f71b63          	bne	a4,a5,800061a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006050:	100017b7          	lui	a5,0x10001
    80006054:	43dc                	lw	a5,4(a5)
    80006056:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006058:	4709                	li	a4,2
    8000605a:	14e79463          	bne	a5,a4,800061a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	479c                	lw	a5,8(a5)
    80006064:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006066:	12e79e63          	bne	a5,a4,800061a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	47d8                	lw	a4,12(a5)
    80006070:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006072:	554d47b7          	lui	a5,0x554d4
    80006076:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000607a:	12f71463          	bne	a4,a5,800061a2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006086:	4705                	li	a4,1
    80006088:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000608a:	470d                	li	a4,3
    8000608c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000608e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006090:	c7ffe6b7          	lui	a3,0xc7ffe
    80006094:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9fef>
    80006098:	8f75                	and	a4,a4,a3
    8000609a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000609c:	472d                	li	a4,11
    8000609e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060a0:	5bbc                	lw	a5,112(a5)
    800060a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060a6:	8ba1                	and	a5,a5,8
    800060a8:	10078563          	beqz	a5,800061b2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060ac:	100017b7          	lui	a5,0x10001
    800060b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060b4:	43fc                	lw	a5,68(a5)
    800060b6:	2781                	sext.w	a5,a5
    800060b8:	10079563          	bnez	a5,800061c2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060bc:	100017b7          	lui	a5,0x10001
    800060c0:	5bdc                	lw	a5,52(a5)
    800060c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c4:	10078763          	beqz	a5,800061d2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800060c8:	471d                	li	a4,7
    800060ca:	10f77c63          	bgeu	a4,a5,800061e2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800060ce:	ffffb097          	auipc	ra,0xffffb
    800060d2:	a14080e7          	jalr	-1516(ra) # 80000ae2 <kalloc>
    800060d6:	0001e497          	auipc	s1,0x1e
    800060da:	55a48493          	add	s1,s1,1370 # 80024630 <disk>
    800060de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	a02080e7          	jalr	-1534(ra) # 80000ae2 <kalloc>
    800060e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	9f8080e7          	jalr	-1544(ra) # 80000ae2 <kalloc>
    800060f2:	87aa                	mv	a5,a0
    800060f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060f6:	6088                	ld	a0,0(s1)
    800060f8:	cd6d                	beqz	a0,800061f2 <virtio_disk_init+0x1da>
    800060fa:	0001e717          	auipc	a4,0x1e
    800060fe:	53e73703          	ld	a4,1342(a4) # 80024638 <disk+0x8>
    80006102:	cb65                	beqz	a4,800061f2 <virtio_disk_init+0x1da>
    80006104:	c7fd                	beqz	a5,800061f2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006106:	6605                	lui	a2,0x1
    80006108:	4581                	li	a1,0
    8000610a:	ffffb097          	auipc	ra,0xffffb
    8000610e:	bc4080e7          	jalr	-1084(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006112:	0001e497          	auipc	s1,0x1e
    80006116:	51e48493          	add	s1,s1,1310 # 80024630 <disk>
    8000611a:	6605                	lui	a2,0x1
    8000611c:	4581                	li	a1,0
    8000611e:	6488                	ld	a0,8(s1)
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	bae080e7          	jalr	-1106(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006128:	6605                	lui	a2,0x1
    8000612a:	4581                	li	a1,0
    8000612c:	6888                	ld	a0,16(s1)
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	ba0080e7          	jalr	-1120(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006136:	100017b7          	lui	a5,0x10001
    8000613a:	4721                	li	a4,8
    8000613c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000613e:	4098                	lw	a4,0(s1)
    80006140:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006144:	40d8                	lw	a4,4(s1)
    80006146:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000614a:	6498                	ld	a4,8(s1)
    8000614c:	0007069b          	sext.w	a3,a4
    80006150:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006154:	9701                	sra	a4,a4,0x20
    80006156:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000615a:	6898                	ld	a4,16(s1)
    8000615c:	0007069b          	sext.w	a3,a4
    80006160:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006164:	9701                	sra	a4,a4,0x20
    80006166:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000616a:	4705                	li	a4,1
    8000616c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000616e:	00e48c23          	sb	a4,24(s1)
    80006172:	00e48ca3          	sb	a4,25(s1)
    80006176:	00e48d23          	sb	a4,26(s1)
    8000617a:	00e48da3          	sb	a4,27(s1)
    8000617e:	00e48e23          	sb	a4,28(s1)
    80006182:	00e48ea3          	sb	a4,29(s1)
    80006186:	00e48f23          	sb	a4,30(s1)
    8000618a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000618e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006192:	0727a823          	sw	s2,112(a5)
}
    80006196:	60e2                	ld	ra,24(sp)
    80006198:	6442                	ld	s0,16(sp)
    8000619a:	64a2                	ld	s1,8(sp)
    8000619c:	6902                	ld	s2,0(sp)
    8000619e:	6105                	add	sp,sp,32
    800061a0:	8082                	ret
    panic("could not find virtio disk");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	5d650513          	add	a0,a0,1494 # 80008778 <syscalls+0x340>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	392080e7          	jalr	914(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	5e650513          	add	a0,a0,1510 # 80008798 <syscalls+0x360>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	382080e7          	jalr	898(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	5f650513          	add	a0,a0,1526 # 800087b8 <syscalls+0x380>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	372080e7          	jalr	882(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800061d2:	00002517          	auipc	a0,0x2
    800061d6:	60650513          	add	a0,a0,1542 # 800087d8 <syscalls+0x3a0>
    800061da:	ffffa097          	auipc	ra,0xffffa
    800061de:	362080e7          	jalr	866(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800061e2:	00002517          	auipc	a0,0x2
    800061e6:	61650513          	add	a0,a0,1558 # 800087f8 <syscalls+0x3c0>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	352080e7          	jalr	850(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	62650513          	add	a0,a0,1574 # 80008818 <syscalls+0x3e0>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	342080e7          	jalr	834(ra) # 8000053c <panic>

0000000080006202 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006202:	7159                	add	sp,sp,-112
    80006204:	f486                	sd	ra,104(sp)
    80006206:	f0a2                	sd	s0,96(sp)
    80006208:	eca6                	sd	s1,88(sp)
    8000620a:	e8ca                	sd	s2,80(sp)
    8000620c:	e4ce                	sd	s3,72(sp)
    8000620e:	e0d2                	sd	s4,64(sp)
    80006210:	fc56                	sd	s5,56(sp)
    80006212:	f85a                	sd	s6,48(sp)
    80006214:	f45e                	sd	s7,40(sp)
    80006216:	f062                	sd	s8,32(sp)
    80006218:	ec66                	sd	s9,24(sp)
    8000621a:	e86a                	sd	s10,16(sp)
    8000621c:	1880                	add	s0,sp,112
    8000621e:	8a2a                	mv	s4,a0
    80006220:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006222:	00c52c83          	lw	s9,12(a0)
    80006226:	001c9c9b          	sllw	s9,s9,0x1
    8000622a:	1c82                	sll	s9,s9,0x20
    8000622c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006230:	0001e517          	auipc	a0,0x1e
    80006234:	52850513          	add	a0,a0,1320 # 80024758 <disk+0x128>
    80006238:	ffffb097          	auipc	ra,0xffffb
    8000623c:	99a080e7          	jalr	-1638(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006240:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006242:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006244:	0001eb17          	auipc	s6,0x1e
    80006248:	3ecb0b13          	add	s6,s6,1004 # 80024630 <disk>
  for(int i = 0; i < 3; i++){
    8000624c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000624e:	0001ec17          	auipc	s8,0x1e
    80006252:	50ac0c13          	add	s8,s8,1290 # 80024758 <disk+0x128>
    80006256:	a095                	j	800062ba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006258:	00fb0733          	add	a4,s6,a5
    8000625c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006260:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006262:	0207c563          	bltz	a5,8000628c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006266:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006268:	0591                	add	a1,a1,4
    8000626a:	05560d63          	beq	a2,s5,800062c4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000626e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006270:	0001e717          	auipc	a4,0x1e
    80006274:	3c070713          	add	a4,a4,960 # 80024630 <disk>
    80006278:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000627a:	01874683          	lbu	a3,24(a4)
    8000627e:	fee9                	bnez	a3,80006258 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006280:	2785                	addw	a5,a5,1
    80006282:	0705                	add	a4,a4,1
    80006284:	fe979be3          	bne	a5,s1,8000627a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006288:	57fd                	li	a5,-1
    8000628a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000628c:	00c05e63          	blez	a2,800062a8 <virtio_disk_rw+0xa6>
    80006290:	060a                	sll	a2,a2,0x2
    80006292:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006296:	0009a503          	lw	a0,0(s3)
    8000629a:	00000097          	auipc	ra,0x0
    8000629e:	cfc080e7          	jalr	-772(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    800062a2:	0991                	add	s3,s3,4
    800062a4:	ffa999e3          	bne	s3,s10,80006296 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	85e2                	mv	a1,s8
    800062aa:	0001e517          	auipc	a0,0x1e
    800062ae:	39e50513          	add	a0,a0,926 # 80024648 <disk+0x18>
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	dc2080e7          	jalr	-574(ra) # 80002074 <sleep>
  for(int i = 0; i < 3; i++){
    800062ba:	f9040993          	add	s3,s0,-112
{
    800062be:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800062c0:	864a                	mv	a2,s2
    800062c2:	b775                	j	8000626e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c4:	f9042503          	lw	a0,-112(s0)
    800062c8:	00a50713          	add	a4,a0,10
    800062cc:	0712                	sll	a4,a4,0x4

  if(write)
    800062ce:	0001e797          	auipc	a5,0x1e
    800062d2:	36278793          	add	a5,a5,866 # 80024630 <disk>
    800062d6:	00e786b3          	add	a3,a5,a4
    800062da:	01703633          	snez	a2,s7
    800062de:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062e0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800062e4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062e8:	f6070613          	add	a2,a4,-160
    800062ec:	6394                	ld	a3,0(a5)
    800062ee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062f0:	00870593          	add	a1,a4,8
    800062f4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062f6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062f8:	0007b803          	ld	a6,0(a5)
    800062fc:	9642                	add	a2,a2,a6
    800062fe:	46c1                	li	a3,16
    80006300:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006302:	4585                	li	a1,1
    80006304:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006308:	f9442683          	lw	a3,-108(s0)
    8000630c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006310:	0692                	sll	a3,a3,0x4
    80006312:	9836                	add	a6,a6,a3
    80006314:	058a0613          	add	a2,s4,88
    80006318:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000631c:	0007b803          	ld	a6,0(a5)
    80006320:	96c2                	add	a3,a3,a6
    80006322:	40000613          	li	a2,1024
    80006326:	c690                	sw	a2,8(a3)
  if(write)
    80006328:	001bb613          	seqz	a2,s7
    8000632c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006330:	00166613          	or	a2,a2,1
    80006334:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006338:	f9842603          	lw	a2,-104(s0)
    8000633c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006340:	00250693          	add	a3,a0,2
    80006344:	0692                	sll	a3,a3,0x4
    80006346:	96be                	add	a3,a3,a5
    80006348:	58fd                	li	a7,-1
    8000634a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000634e:	0612                	sll	a2,a2,0x4
    80006350:	9832                	add	a6,a6,a2
    80006352:	f9070713          	add	a4,a4,-112
    80006356:	973e                	add	a4,a4,a5
    80006358:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000635c:	6398                	ld	a4,0(a5)
    8000635e:	9732                	add	a4,a4,a2
    80006360:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006362:	4609                	li	a2,2
    80006364:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006368:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000636c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006370:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006374:	6794                	ld	a3,8(a5)
    80006376:	0026d703          	lhu	a4,2(a3)
    8000637a:	8b1d                	and	a4,a4,7
    8000637c:	0706                	sll	a4,a4,0x1
    8000637e:	96ba                	add	a3,a3,a4
    80006380:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006384:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006388:	6798                	ld	a4,8(a5)
    8000638a:	00275783          	lhu	a5,2(a4)
    8000638e:	2785                	addw	a5,a5,1
    80006390:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006394:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800063a4:	0001e917          	auipc	s2,0x1e
    800063a8:	3b490913          	add	s2,s2,948 # 80024758 <disk+0x128>
  while(b->disk == 1) {
    800063ac:	4485                	li	s1,1
    800063ae:	00b79c63          	bne	a5,a1,800063c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063b2:	85ca                	mv	a1,s2
    800063b4:	8552                	mv	a0,s4
    800063b6:	ffffc097          	auipc	ra,0xffffc
    800063ba:	cbe080e7          	jalr	-834(ra) # 80002074 <sleep>
  while(b->disk == 1) {
    800063be:	004a2783          	lw	a5,4(s4)
    800063c2:	fe9788e3          	beq	a5,s1,800063b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800063c6:	f9042903          	lw	s2,-112(s0)
    800063ca:	00290713          	add	a4,s2,2
    800063ce:	0712                	sll	a4,a4,0x4
    800063d0:	0001e797          	auipc	a5,0x1e
    800063d4:	26078793          	add	a5,a5,608 # 80024630 <disk>
    800063d8:	97ba                	add	a5,a5,a4
    800063da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063de:	0001e997          	auipc	s3,0x1e
    800063e2:	25298993          	add	s3,s3,594 # 80024630 <disk>
    800063e6:	00491713          	sll	a4,s2,0x4
    800063ea:	0009b783          	ld	a5,0(s3)
    800063ee:	97ba                	add	a5,a5,a4
    800063f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063f4:	854a                	mv	a0,s2
    800063f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063fa:	00000097          	auipc	ra,0x0
    800063fe:	b9c080e7          	jalr	-1124(ra) # 80005f96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006402:	8885                	and	s1,s1,1
    80006404:	f0ed                	bnez	s1,800063e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006406:	0001e517          	auipc	a0,0x1e
    8000640a:	35250513          	add	a0,a0,850 # 80024758 <disk+0x128>
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	878080e7          	jalr	-1928(ra) # 80000c86 <release>
}
    80006416:	70a6                	ld	ra,104(sp)
    80006418:	7406                	ld	s0,96(sp)
    8000641a:	64e6                	ld	s1,88(sp)
    8000641c:	6946                	ld	s2,80(sp)
    8000641e:	69a6                	ld	s3,72(sp)
    80006420:	6a06                	ld	s4,64(sp)
    80006422:	7ae2                	ld	s5,56(sp)
    80006424:	7b42                	ld	s6,48(sp)
    80006426:	7ba2                	ld	s7,40(sp)
    80006428:	7c02                	ld	s8,32(sp)
    8000642a:	6ce2                	ld	s9,24(sp)
    8000642c:	6d42                	ld	s10,16(sp)
    8000642e:	6165                	add	sp,sp,112
    80006430:	8082                	ret

0000000080006432 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006432:	1101                	add	sp,sp,-32
    80006434:	ec06                	sd	ra,24(sp)
    80006436:	e822                	sd	s0,16(sp)
    80006438:	e426                	sd	s1,8(sp)
    8000643a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000643c:	0001e497          	auipc	s1,0x1e
    80006440:	1f448493          	add	s1,s1,500 # 80024630 <disk>
    80006444:	0001e517          	auipc	a0,0x1e
    80006448:	31450513          	add	a0,a0,788 # 80024758 <disk+0x128>
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	786080e7          	jalr	1926(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006454:	10001737          	lui	a4,0x10001
    80006458:	533c                	lw	a5,96(a4)
    8000645a:	8b8d                	and	a5,a5,3
    8000645c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000645e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006462:	689c                	ld	a5,16(s1)
    80006464:	0204d703          	lhu	a4,32(s1)
    80006468:	0027d783          	lhu	a5,2(a5)
    8000646c:	04f70863          	beq	a4,a5,800064bc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006470:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006474:	6898                	ld	a4,16(s1)
    80006476:	0204d783          	lhu	a5,32(s1)
    8000647a:	8b9d                	and	a5,a5,7
    8000647c:	078e                	sll	a5,a5,0x3
    8000647e:	97ba                	add	a5,a5,a4
    80006480:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006482:	00278713          	add	a4,a5,2
    80006486:	0712                	sll	a4,a4,0x4
    80006488:	9726                	add	a4,a4,s1
    8000648a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000648e:	e721                	bnez	a4,800064d6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006490:	0789                	add	a5,a5,2
    80006492:	0792                	sll	a5,a5,0x4
    80006494:	97a6                	add	a5,a5,s1
    80006496:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006498:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000649c:	ffffc097          	auipc	ra,0xffffc
    800064a0:	c3c080e7          	jalr	-964(ra) # 800020d8 <wakeup>

    disk.used_idx += 1;
    800064a4:	0204d783          	lhu	a5,32(s1)
    800064a8:	2785                	addw	a5,a5,1
    800064aa:	17c2                	sll	a5,a5,0x30
    800064ac:	93c1                	srl	a5,a5,0x30
    800064ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b2:	6898                	ld	a4,16(s1)
    800064b4:	00275703          	lhu	a4,2(a4)
    800064b8:	faf71ce3          	bne	a4,a5,80006470 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064bc:	0001e517          	auipc	a0,0x1e
    800064c0:	29c50513          	add	a0,a0,668 # 80024758 <disk+0x128>
    800064c4:	ffffa097          	auipc	ra,0xffffa
    800064c8:	7c2080e7          	jalr	1986(ra) # 80000c86 <release>
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	add	sp,sp,32
    800064d4:	8082                	ret
      panic("virtio_disk_intr status");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	35a50513          	add	a0,a0,858 # 80008830 <syscalls+0x3f8>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	05e080e7          	jalr	94(ra) # 8000053c <panic>
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
