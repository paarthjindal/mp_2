
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
    80000066:	dae78793          	add	a5,a5,-594 # 80005e10 <timervec>
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
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc60f>
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
    8000012e:	3a2080e7          	jalr	930(ra) # 800024cc <either_copyin>
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
    800001c0:	15a080e7          	jalr	346(ra) # 80002316 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	e98080e7          	jalr	-360(ra) # 80002062 <sleep>
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
    80000214:	266080e7          	jalr	614(ra) # 80002476 <either_copyout>
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
    800002f2:	234080e7          	jalr	564(ra) # 80002522 <procdump>
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
    80000446:	c84080e7          	jalr	-892(ra) # 800020c6 <wakeup>
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
    80000474:	00021797          	auipc	a5,0x21
    80000478:	be478793          	add	a5,a5,-1052 # 80021058 <devsw>
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
    80000894:	836080e7          	jalr	-1994(ra) # 800020c6 <wakeup>
    
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
    8000091e:	748080e7          	jalr	1864(ra) # 80002062 <sleep>
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
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	7f878793          	add	a5,a5,2040 # 800221f0 <end>
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
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	72650513          	add	a0,a0,1830 # 800221f0 <end>
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
    80000d42:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdce11>
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
    80000ebc:	956080e7          	jalr	-1706(ra) # 8000280e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	f90080e7          	jalr	-112(ra) # 80005e50 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fe8080e7          	jalr	-24(ra) # 80001eb0 <scheduler>
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
    80000f34:	8b6080e7          	jalr	-1866(ra) # 800027e6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	8d6080e7          	jalr	-1834(ra) # 8000280e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	efa080e7          	jalr	-262(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	f08080e7          	jalr	-248(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	104080e7          	jalr	260(ra) # 80003054 <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	7a2080e7          	jalr	1954(ra) # 800036fa <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	718080e7          	jalr	1816(ra) # 80004678 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	ff0080e7          	jalr	-16(ra) # 80005f58 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d22080e7          	jalr	-734(ra) # 80001c92 <userinit>
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
    80001010:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdce07>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdce10>
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
    80001860:	00015a17          	auipc	s4,0x15
    80001864:	530a0a13          	add	s4,s4,1328 # 80016d90 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	858d                	sra	a1,a1,0x3
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
    8000189a:	17848493          	add	s1,s1,376
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
    8000192c:	00015997          	auipc	s3,0x15
    80001930:	46498993          	add	s3,s3,1124 # 80016d90 <tickslock>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	sra	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addw	a5,a5,1
    80001954:	00d7979b          	sllw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	17848493          	add	s1,s1,376
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
    80001a04:	e26080e7          	jalr	-474(ra) # 80002826 <usertrapret>
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
    80001a1e:	c60080e7          	jalr	-928(ra) # 8000367a <fsinit>
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
    80001bc4:	00015917          	auipc	s2,0x15
    80001bc8:	1cc90913          	add	s2,s2,460 # 80016d90 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be4:	17848493          	add	s1,s1,376
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a09d                	j	80001c54 <allocproc+0xa4>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bfa:	4785                	li	a5,1
    80001bfc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	ee4080e7          	jalr	-284(ra) # 80000ae2 <kalloc>
    80001c06:	892a                	mv	s2,a0
    80001c08:	eca8                	sd	a0,88(s1)
    80001c0a:	cd21                	beqz	a0,80001c62 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	e5c080e7          	jalr	-420(ra) # 80001a6a <proc_pagetable>
    80001c16:	892a                	mv	s2,a0
    80001c18:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c1a:	c125                	beqz	a0,80001c7a <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c1c:	07000613          	li	a2,112
    80001c20:	4581                	li	a1,0
    80001c22:	06048513          	add	a0,s1,96
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	0a8080e7          	jalr	168(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c2e:	00000797          	auipc	a5,0x0
    80001c32:	db078793          	add	a5,a5,-592 # 800019de <forkret>
    80001c36:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c38:	60bc                	ld	a5,64(s1)
    80001c3a:	6705                	lui	a4,0x1
    80001c3c:	97ba                	add	a5,a5,a4
    80001c3e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c40:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c44:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c48:	00007797          	auipc	a5,0x7
    80001c4c:	ca87a783          	lw	a5,-856(a5) # 800088f0 <ticks>
    80001c50:	16f4a623          	sw	a5,364(s1)
}
    80001c54:	8526                	mv	a0,s1
    80001c56:	60e2                	ld	ra,24(sp)
    80001c58:	6442                	ld	s0,16(sp)
    80001c5a:	64a2                	ld	s1,8(sp)
    80001c5c:	6902                	ld	s2,0(sp)
    80001c5e:	6105                	add	sp,sp,32
    80001c60:	8082                	ret
    freeproc(p);
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	ef4080e7          	jalr	-268(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	018080e7          	jalr	24(ra) # 80000c86 <release>
    return 0;
    80001c76:	84ca                	mv	s1,s2
    80001c78:	bff1                	j	80001c54 <allocproc+0xa4>
    freeproc(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	edc080e7          	jalr	-292(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	000080e7          	jalr	ra # 80000c86 <release>
    return 0;
    80001c8e:	84ca                	mv	s1,s2
    80001c90:	b7d1                	j	80001c54 <allocproc+0xa4>

0000000080001c92 <userinit>:
{
    80001c92:	1101                	add	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	1000                	add	s0,sp,32
  p = allocproc();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	f14080e7          	jalr	-236(ra) # 80001bb0 <allocproc>
    80001ca4:	84aa                	mv	s1,a0
  initproc = p;
    80001ca6:	00007797          	auipc	a5,0x7
    80001caa:	c4a7b123          	sd	a0,-958(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cae:	03400613          	li	a2,52
    80001cb2:	00007597          	auipc	a1,0x7
    80001cb6:	bae58593          	add	a1,a1,-1106 # 80008860 <initcode>
    80001cba:	6928                	ld	a0,80(a0)
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	694080e7          	jalr	1684(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cc4:	6785                	lui	a5,0x1
    80001cc6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cc8:	6cb8                	ld	a4,88(s1)
    80001cca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd2:	4641                	li	a2,16
    80001cd4:	00006597          	auipc	a1,0x6
    80001cd8:	52c58593          	add	a1,a1,1324 # 80008200 <digits+0x1c0>
    80001cdc:	15848513          	add	a0,s1,344
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	136080e7          	jalr	310(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001ce8:	00006517          	auipc	a0,0x6
    80001cec:	52850513          	add	a0,a0,1320 # 80008210 <digits+0x1d0>
    80001cf0:	00002097          	auipc	ra,0x2
    80001cf4:	3a8080e7          	jalr	936(ra) # 80004098 <namei>
    80001cf8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfc:	478d                	li	a5,3
    80001cfe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	f84080e7          	jalr	-124(ra) # 80000c86 <release>
}
    80001d0a:	60e2                	ld	ra,24(sp)
    80001d0c:	6442                	ld	s0,16(sp)
    80001d0e:	64a2                	ld	s1,8(sp)
    80001d10:	6105                	add	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <growproc>:
{
    80001d14:	1101                	add	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	add	s0,sp,32
    80001d20:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	c84080e7          	jalr	-892(ra) # 800019a6 <myproc>
    80001d2a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d2c:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d2e:	01204c63          	bgtz	s2,80001d46 <growproc+0x32>
  else if (n < 0)
    80001d32:	02094663          	bltz	s2,80001d5e <growproc+0x4a>
  p->sz = sz;
    80001d36:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	add	sp,sp,32
    80001d44:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d46:	4691                	li	a3,4
    80001d48:	00b90633          	add	a2,s2,a1
    80001d4c:	6928                	ld	a0,80(a0)
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	6bc080e7          	jalr	1724(ra) # 8000140a <uvmalloc>
    80001d56:	85aa                	mv	a1,a0
    80001d58:	fd79                	bnez	a0,80001d36 <growproc+0x22>
      return -1;
    80001d5a:	557d                	li	a0,-1
    80001d5c:	bff9                	j	80001d3a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d5e:	00b90633          	add	a2,s2,a1
    80001d62:	6928                	ld	a0,80(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	65e080e7          	jalr	1630(ra) # 800013c2 <uvmdealloc>
    80001d6c:	85aa                	mv	a1,a0
    80001d6e:	b7e1                	j	80001d36 <growproc+0x22>

0000000080001d70 <fork>:
{
    80001d70:	7139                	add	sp,sp,-64
    80001d72:	fc06                	sd	ra,56(sp)
    80001d74:	f822                	sd	s0,48(sp)
    80001d76:	f426                	sd	s1,40(sp)
    80001d78:	f04a                	sd	s2,32(sp)
    80001d7a:	ec4e                	sd	s3,24(sp)
    80001d7c:	e852                	sd	s4,16(sp)
    80001d7e:	e456                	sd	s5,8(sp)
    80001d80:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	c24080e7          	jalr	-988(ra) # 800019a6 <myproc>
    80001d8a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	e24080e7          	jalr	-476(ra) # 80001bb0 <allocproc>
    80001d94:	10050c63          	beqz	a0,80001eac <fork+0x13c>
    80001d98:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d9a:	048ab603          	ld	a2,72(s5)
    80001d9e:	692c                	ld	a1,80(a0)
    80001da0:	050ab503          	ld	a0,80(s5)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	7be080e7          	jalr	1982(ra) # 80001562 <uvmcopy>
    80001dac:	04054863          	bltz	a0,80001dfc <fork+0x8c>
  np->sz = p->sz;
    80001db0:	048ab783          	ld	a5,72(s5)
    80001db4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db8:	058ab683          	ld	a3,88(s5)
    80001dbc:	87b6                	mv	a5,a3
    80001dbe:	058a3703          	ld	a4,88(s4)
    80001dc2:	12068693          	add	a3,a3,288
    80001dc6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dca:	6788                	ld	a0,8(a5)
    80001dcc:	6b8c                	ld	a1,16(a5)
    80001dce:	6f90                	ld	a2,24(a5)
    80001dd0:	01073023          	sd	a6,0(a4)
    80001dd4:	e708                	sd	a0,8(a4)
    80001dd6:	eb0c                	sd	a1,16(a4)
    80001dd8:	ef10                	sd	a2,24(a4)
    80001dda:	02078793          	add	a5,a5,32
    80001dde:	02070713          	add	a4,a4,32
    80001de2:	fed792e3          	bne	a5,a3,80001dc6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001de6:	058a3783          	ld	a5,88(s4)
    80001dea:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001dee:	0d0a8493          	add	s1,s5,208
    80001df2:	0d0a0913          	add	s2,s4,208
    80001df6:	150a8993          	add	s3,s5,336
    80001dfa:	a00d                	j	80001e1c <fork+0xac>
    freeproc(np);
    80001dfc:	8552                	mv	a0,s4
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	d5a080e7          	jalr	-678(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e06:	8552                	mv	a0,s4
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e7e080e7          	jalr	-386(ra) # 80000c86 <release>
    return -1;
    80001e10:	597d                	li	s2,-1
    80001e12:	a059                	j	80001e98 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e14:	04a1                	add	s1,s1,8
    80001e16:	0921                	add	s2,s2,8
    80001e18:	01348b63          	beq	s1,s3,80001e2e <fork+0xbe>
    if (p->ofile[i])
    80001e1c:	6088                	ld	a0,0(s1)
    80001e1e:	d97d                	beqz	a0,80001e14 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e20:	00003097          	auipc	ra,0x3
    80001e24:	8ea080e7          	jalr	-1814(ra) # 8000470a <filedup>
    80001e28:	00a93023          	sd	a0,0(s2)
    80001e2c:	b7e5                	j	80001e14 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e2e:	150ab503          	ld	a0,336(s5)
    80001e32:	00002097          	auipc	ra,0x2
    80001e36:	a82080e7          	jalr	-1406(ra) # 800038b4 <idup>
    80001e3a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3e:	4641                	li	a2,16
    80001e40:	158a8593          	add	a1,s5,344
    80001e44:	158a0513          	add	a0,s4,344
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	fce080e7          	jalr	-50(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e50:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e54:	8552                	mv	a0,s4
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e30080e7          	jalr	-464(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e5e:	0000f497          	auipc	s1,0xf
    80001e62:	d1a48493          	add	s1,s1,-742 # 80010b78 <wait_lock>
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	d6a080e7          	jalr	-662(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e70:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e10080e7          	jalr	-496(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e7e:	8552                	mv	a0,s4
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	d52080e7          	jalr	-686(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e88:	478d                	li	a5,3
    80001e8a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e8e:	8552                	mv	a0,s4
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	df6080e7          	jalr	-522(ra) # 80000c86 <release>
}
    80001e98:	854a                	mv	a0,s2
    80001e9a:	70e2                	ld	ra,56(sp)
    80001e9c:	7442                	ld	s0,48(sp)
    80001e9e:	74a2                	ld	s1,40(sp)
    80001ea0:	7902                	ld	s2,32(sp)
    80001ea2:	69e2                	ld	s3,24(sp)
    80001ea4:	6a42                	ld	s4,16(sp)
    80001ea6:	6aa2                	ld	s5,8(sp)
    80001ea8:	6121                	add	sp,sp,64
    80001eaa:	8082                	ret
    return -1;
    80001eac:	597d                	li	s2,-1
    80001eae:	b7ed                	j	80001e98 <fork+0x128>

0000000080001eb0 <scheduler>:
{
    80001eb0:	7139                	add	sp,sp,-64
    80001eb2:	fc06                	sd	ra,56(sp)
    80001eb4:	f822                	sd	s0,48(sp)
    80001eb6:	f426                	sd	s1,40(sp)
    80001eb8:	f04a                	sd	s2,32(sp)
    80001eba:	ec4e                	sd	s3,24(sp)
    80001ebc:	e852                	sd	s4,16(sp)
    80001ebe:	e456                	sd	s5,8(sp)
    80001ec0:	e05a                	sd	s6,0(sp)
    80001ec2:	0080                	add	s0,sp,64
    80001ec4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec8:	00779a93          	sll	s5,a5,0x7
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	c9470713          	add	a4,a4,-876 # 80010b60 <pid_lock>
    80001ed4:	9756                	add	a4,a4,s5
    80001ed6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eda:	0000f717          	auipc	a4,0xf
    80001ede:	cbe70713          	add	a4,a4,-834 # 80010b98 <cpus+0x8>
    80001ee2:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ee4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee6:	4b11                	li	s6,4
        c->proc = p;
    80001ee8:	079e                	sll	a5,a5,0x7
    80001eea:	0000fa17          	auipc	s4,0xf
    80001eee:	c76a0a13          	add	s4,s4,-906 # 80010b60 <pid_lock>
    80001ef2:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ef4:	00015917          	auipc	s2,0x15
    80001ef8:	e9c90913          	add	s2,s2,-356 # 80016d90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001efc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f00:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f04:	10079073          	csrw	sstatus,a5
    80001f08:	0000f497          	auipc	s1,0xf
    80001f0c:	08848493          	add	s1,s1,136 # 80010f90 <proc>
    80001f10:	a811                	j	80001f24 <scheduler+0x74>
      release(&p->lock);
    80001f12:	8526                	mv	a0,s1
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	d72080e7          	jalr	-654(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f1c:	17848493          	add	s1,s1,376
    80001f20:	fd248ee3          	beq	s1,s2,80001efc <scheduler+0x4c>
      acquire(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	cac080e7          	jalr	-852(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001f2e:	4c9c                	lw	a5,24(s1)
    80001f30:	ff3791e3          	bne	a5,s3,80001f12 <scheduler+0x62>
        p->state = RUNNING;
    80001f34:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f38:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f3c:	06048593          	add	a1,s1,96
    80001f40:	8556                	mv	a0,s5
    80001f42:	00001097          	auipc	ra,0x1
    80001f46:	83a080e7          	jalr	-1990(ra) # 8000277c <swtch>
        c->proc = 0;
    80001f4a:	020a3823          	sd	zero,48(s4)
    80001f4e:	b7d1                	j	80001f12 <scheduler+0x62>

0000000080001f50 <sched>:
{
    80001f50:	7179                	add	sp,sp,-48
    80001f52:	f406                	sd	ra,40(sp)
    80001f54:	f022                	sd	s0,32(sp)
    80001f56:	ec26                	sd	s1,24(sp)
    80001f58:	e84a                	sd	s2,16(sp)
    80001f5a:	e44e                	sd	s3,8(sp)
    80001f5c:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	a48080e7          	jalr	-1464(ra) # 800019a6 <myproc>
    80001f66:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	bf0080e7          	jalr	-1040(ra) # 80000b58 <holding>
    80001f70:	c93d                	beqz	a0,80001fe6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f72:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f74:	2781                	sext.w	a5,a5
    80001f76:	079e                	sll	a5,a5,0x7
    80001f78:	0000f717          	auipc	a4,0xf
    80001f7c:	be870713          	add	a4,a4,-1048 # 80010b60 <pid_lock>
    80001f80:	97ba                	add	a5,a5,a4
    80001f82:	0a87a703          	lw	a4,168(a5)
    80001f86:	4785                	li	a5,1
    80001f88:	06f71763          	bne	a4,a5,80001ff6 <sched+0xa6>
  if (p->state == RUNNING)
    80001f8c:	4c98                	lw	a4,24(s1)
    80001f8e:	4791                	li	a5,4
    80001f90:	06f70b63          	beq	a4,a5,80002006 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f98:	8b89                	and	a5,a5,2
  if (intr_get())
    80001f9a:	efb5                	bnez	a5,80002016 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9e:	0000f917          	auipc	s2,0xf
    80001fa2:	bc290913          	add	s2,s2,-1086 # 80010b60 <pid_lock>
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	sll	a5,a5,0x7
    80001faa:	97ca                	add	a5,a5,s2
    80001fac:	0ac7a983          	lw	s3,172(a5)
    80001fb0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	sll	a5,a5,0x7
    80001fb6:	0000f597          	auipc	a1,0xf
    80001fba:	be258593          	add	a1,a1,-1054 # 80010b98 <cpus+0x8>
    80001fbe:	95be                	add	a1,a1,a5
    80001fc0:	06048513          	add	a0,s1,96
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	7b8080e7          	jalr	1976(ra) # 8000277c <swtch>
    80001fcc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	sll	a5,a5,0x7
    80001fd2:	993e                	add	s2,s2,a5
    80001fd4:	0b392623          	sw	s3,172(s2)
}
    80001fd8:	70a2                	ld	ra,40(sp)
    80001fda:	7402                	ld	s0,32(sp)
    80001fdc:	64e2                	ld	s1,24(sp)
    80001fde:	6942                	ld	s2,16(sp)
    80001fe0:	69a2                	ld	s3,8(sp)
    80001fe2:	6145                	add	sp,sp,48
    80001fe4:	8082                	ret
    panic("sched p->lock");
    80001fe6:	00006517          	auipc	a0,0x6
    80001fea:	23250513          	add	a0,a0,562 # 80008218 <digits+0x1d8>
    80001fee:	ffffe097          	auipc	ra,0xffffe
    80001ff2:	54e080e7          	jalr	1358(ra) # 8000053c <panic>
    panic("sched locks");
    80001ff6:	00006517          	auipc	a0,0x6
    80001ffa:	23250513          	add	a0,a0,562 # 80008228 <digits+0x1e8>
    80001ffe:	ffffe097          	auipc	ra,0xffffe
    80002002:	53e080e7          	jalr	1342(ra) # 8000053c <panic>
    panic("sched running");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	23250513          	add	a0,a0,562 # 80008238 <digits+0x1f8>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	52e080e7          	jalr	1326(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	23250513          	add	a0,a0,562 # 80008248 <digits+0x208>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	51e080e7          	jalr	1310(ra) # 8000053c <panic>

0000000080002026 <yield>:
{
    80002026:	1101                	add	sp,sp,-32
    80002028:	ec06                	sd	ra,24(sp)
    8000202a:	e822                	sd	s0,16(sp)
    8000202c:	e426                	sd	s1,8(sp)
    8000202e:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002030:	00000097          	auipc	ra,0x0
    80002034:	976080e7          	jalr	-1674(ra) # 800019a6 <myproc>
    80002038:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	b98080e7          	jalr	-1128(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002042:	478d                	li	a5,3
    80002044:	cc9c                	sw	a5,24(s1)
  sched();
    80002046:	00000097          	auipc	ra,0x0
    8000204a:	f0a080e7          	jalr	-246(ra) # 80001f50 <sched>
  release(&p->lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	c36080e7          	jalr	-970(ra) # 80000c86 <release>
}
    80002058:	60e2                	ld	ra,24(sp)
    8000205a:	6442                	ld	s0,16(sp)
    8000205c:	64a2                	ld	s1,8(sp)
    8000205e:	6105                	add	sp,sp,32
    80002060:	8082                	ret

0000000080002062 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002062:	7179                	add	sp,sp,-48
    80002064:	f406                	sd	ra,40(sp)
    80002066:	f022                	sd	s0,32(sp)
    80002068:	ec26                	sd	s1,24(sp)
    8000206a:	e84a                	sd	s2,16(sp)
    8000206c:	e44e                	sd	s3,8(sp)
    8000206e:	1800                	add	s0,sp,48
    80002070:	89aa                	mv	s3,a0
    80002072:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	932080e7          	jalr	-1742(ra) # 800019a6 <myproc>
    8000207c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	b54080e7          	jalr	-1196(ra) # 80000bd2 <acquire>
  release(lk);
    80002086:	854a                	mv	a0,s2
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	bfe080e7          	jalr	-1026(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002090:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002094:	4789                	li	a5,2
    80002096:	cc9c                	sw	a5,24(s1)

  sched();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	eb8080e7          	jalr	-328(ra) # 80001f50 <sched>

  // Tidy up.
  p->chan = 0;
    800020a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a4:	8526                	mv	a0,s1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	be0080e7          	jalr	-1056(ra) # 80000c86 <release>
  acquire(lk);
    800020ae:	854a                	mv	a0,s2
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	b22080e7          	jalr	-1246(ra) # 80000bd2 <acquire>
}
    800020b8:	70a2                	ld	ra,40(sp)
    800020ba:	7402                	ld	s0,32(sp)
    800020bc:	64e2                	ld	s1,24(sp)
    800020be:	6942                	ld	s2,16(sp)
    800020c0:	69a2                	ld	s3,8(sp)
    800020c2:	6145                	add	sp,sp,48
    800020c4:	8082                	ret

00000000800020c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020c6:	7139                	add	sp,sp,-64
    800020c8:	fc06                	sd	ra,56(sp)
    800020ca:	f822                	sd	s0,48(sp)
    800020cc:	f426                	sd	s1,40(sp)
    800020ce:	f04a                	sd	s2,32(sp)
    800020d0:	ec4e                	sd	s3,24(sp)
    800020d2:	e852                	sd	s4,16(sp)
    800020d4:	e456                	sd	s5,8(sp)
    800020d6:	0080                	add	s0,sp,64
    800020d8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020da:	0000f497          	auipc	s1,0xf
    800020de:	eb648493          	add	s1,s1,-330 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020e2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020e4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020e6:	00015917          	auipc	s2,0x15
    800020ea:	caa90913          	add	s2,s2,-854 # 80016d90 <tickslock>
    800020ee:	a811                	j	80002102 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b94080e7          	jalr	-1132(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020fa:	17848493          	add	s1,s1,376
    800020fe:	03248663          	beq	s1,s2,8000212a <wakeup+0x64>
    if (p != myproc())
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8a4080e7          	jalr	-1884(ra) # 800019a6 <myproc>
    8000210a:	fea488e3          	beq	s1,a0,800020fa <wakeup+0x34>
      acquire(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ac2080e7          	jalr	-1342(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002118:	4c9c                	lw	a5,24(s1)
    8000211a:	fd379be3          	bne	a5,s3,800020f0 <wakeup+0x2a>
    8000211e:	709c                	ld	a5,32(s1)
    80002120:	fd4798e3          	bne	a5,s4,800020f0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002124:	0154ac23          	sw	s5,24(s1)
    80002128:	b7e1                	j	800020f0 <wakeup+0x2a>
    }
  }
}
    8000212a:	70e2                	ld	ra,56(sp)
    8000212c:	7442                	ld	s0,48(sp)
    8000212e:	74a2                	ld	s1,40(sp)
    80002130:	7902                	ld	s2,32(sp)
    80002132:	69e2                	ld	s3,24(sp)
    80002134:	6a42                	ld	s4,16(sp)
    80002136:	6aa2                	ld	s5,8(sp)
    80002138:	6121                	add	sp,sp,64
    8000213a:	8082                	ret

000000008000213c <reparent>:
{
    8000213c:	7179                	add	sp,sp,-48
    8000213e:	f406                	sd	ra,40(sp)
    80002140:	f022                	sd	s0,32(sp)
    80002142:	ec26                	sd	s1,24(sp)
    80002144:	e84a                	sd	s2,16(sp)
    80002146:	e44e                	sd	s3,8(sp)
    80002148:	e052                	sd	s4,0(sp)
    8000214a:	1800                	add	s0,sp,48
    8000214c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000214e:	0000f497          	auipc	s1,0xf
    80002152:	e4248493          	add	s1,s1,-446 # 80010f90 <proc>
      pp->parent = initproc;
    80002156:	00006a17          	auipc	s4,0x6
    8000215a:	792a0a13          	add	s4,s4,1938 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000215e:	00015997          	auipc	s3,0x15
    80002162:	c3298993          	add	s3,s3,-974 # 80016d90 <tickslock>
    80002166:	a029                	j	80002170 <reparent+0x34>
    80002168:	17848493          	add	s1,s1,376
    8000216c:	01348d63          	beq	s1,s3,80002186 <reparent+0x4a>
    if (pp->parent == p)
    80002170:	7c9c                	ld	a5,56(s1)
    80002172:	ff279be3          	bne	a5,s2,80002168 <reparent+0x2c>
      pp->parent = initproc;
    80002176:	000a3503          	ld	a0,0(s4)
    8000217a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	f4a080e7          	jalr	-182(ra) # 800020c6 <wakeup>
    80002184:	b7d5                	j	80002168 <reparent+0x2c>
}
    80002186:	70a2                	ld	ra,40(sp)
    80002188:	7402                	ld	s0,32(sp)
    8000218a:	64e2                	ld	s1,24(sp)
    8000218c:	6942                	ld	s2,16(sp)
    8000218e:	69a2                	ld	s3,8(sp)
    80002190:	6a02                	ld	s4,0(sp)
    80002192:	6145                	add	sp,sp,48
    80002194:	8082                	ret

0000000080002196 <exit>:
{
    80002196:	7179                	add	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	e052                	sd	s4,0(sp)
    800021a4:	1800                	add	s0,sp,48
    800021a6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	7fe080e7          	jalr	2046(ra) # 800019a6 <myproc>
    800021b0:	89aa                	mv	s3,a0
  if (p == initproc)
    800021b2:	00006797          	auipc	a5,0x6
    800021b6:	7367b783          	ld	a5,1846(a5) # 800088e8 <initproc>
    800021ba:	0d050493          	add	s1,a0,208
    800021be:	15050913          	add	s2,a0,336
    800021c2:	02a79363          	bne	a5,a0,800021e8 <exit+0x52>
    panic("init exiting");
    800021c6:	00006517          	auipc	a0,0x6
    800021ca:	09a50513          	add	a0,a0,154 # 80008260 <digits+0x220>
    800021ce:	ffffe097          	auipc	ra,0xffffe
    800021d2:	36e080e7          	jalr	878(ra) # 8000053c <panic>
      fileclose(f);
    800021d6:	00002097          	auipc	ra,0x2
    800021da:	586080e7          	jalr	1414(ra) # 8000475c <fileclose>
      p->ofile[fd] = 0;
    800021de:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021e2:	04a1                	add	s1,s1,8
    800021e4:	01248563          	beq	s1,s2,800021ee <exit+0x58>
    if (p->ofile[fd])
    800021e8:	6088                	ld	a0,0(s1)
    800021ea:	f575                	bnez	a0,800021d6 <exit+0x40>
    800021ec:	bfdd                	j	800021e2 <exit+0x4c>
  begin_op();
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	0aa080e7          	jalr	170(ra) # 80004298 <begin_op>
  iput(p->cwd);
    800021f6:	1509b503          	ld	a0,336(s3)
    800021fa:	00002097          	auipc	ra,0x2
    800021fe:	8b2080e7          	jalr	-1870(ra) # 80003aac <iput>
  end_op();
    80002202:	00002097          	auipc	ra,0x2
    80002206:	110080e7          	jalr	272(ra) # 80004312 <end_op>
  p->cwd = 0;
    8000220a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000220e:	0000f497          	auipc	s1,0xf
    80002212:	96a48493          	add	s1,s1,-1686 # 80010b78 <wait_lock>
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9ba080e7          	jalr	-1606(ra) # 80000bd2 <acquire>
  reparent(p);
    80002220:	854e                	mv	a0,s3
    80002222:	00000097          	auipc	ra,0x0
    80002226:	f1a080e7          	jalr	-230(ra) # 8000213c <reparent>
  wakeup(p->parent);
    8000222a:	0389b503          	ld	a0,56(s3)
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	e98080e7          	jalr	-360(ra) # 800020c6 <wakeup>
  acquire(&p->lock);
    80002236:	854e                	mv	a0,s3
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	99a080e7          	jalr	-1638(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002240:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002244:	4795                	li	a5,5
    80002246:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000224a:	00006797          	auipc	a5,0x6
    8000224e:	6a67a783          	lw	a5,1702(a5) # 800088f0 <ticks>
    80002252:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a2e080e7          	jalr	-1490(ra) # 80000c86 <release>
  sched();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	cf0080e7          	jalr	-784(ra) # 80001f50 <sched>
  panic("zombie exit");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	00850513          	add	a0,a0,8 # 80008270 <digits+0x230>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2cc080e7          	jalr	716(ra) # 8000053c <panic>

0000000080002278 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002278:	7179                	add	sp,sp,-48
    8000227a:	f406                	sd	ra,40(sp)
    8000227c:	f022                	sd	s0,32(sp)
    8000227e:	ec26                	sd	s1,24(sp)
    80002280:	e84a                	sd	s2,16(sp)
    80002282:	e44e                	sd	s3,8(sp)
    80002284:	1800                	add	s0,sp,48
    80002286:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002288:	0000f497          	auipc	s1,0xf
    8000228c:	d0848493          	add	s1,s1,-760 # 80010f90 <proc>
    80002290:	00015997          	auipc	s3,0x15
    80002294:	b0098993          	add	s3,s3,-1280 # 80016d90 <tickslock>
  {
    acquire(&p->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	938080e7          	jalr	-1736(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    800022a2:	589c                	lw	a5,48(s1)
    800022a4:	01278d63          	beq	a5,s2,800022be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9dc080e7          	jalr	-1572(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022b2:	17848493          	add	s1,s1,376
    800022b6:	ff3491e3          	bne	s1,s3,80002298 <kill+0x20>
  }
  return -1;
    800022ba:	557d                	li	a0,-1
    800022bc:	a829                	j	800022d6 <kill+0x5e>
      p->killed = 1;
    800022be:	4785                	li	a5,1
    800022c0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022c2:	4c98                	lw	a4,24(s1)
    800022c4:	4789                	li	a5,2
    800022c6:	00f70f63          	beq	a4,a5,800022e4 <kill+0x6c>
      release(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9ba080e7          	jalr	-1606(ra) # 80000c86 <release>
      return 0;
    800022d4:	4501                	li	a0,0
}
    800022d6:	70a2                	ld	ra,40(sp)
    800022d8:	7402                	ld	s0,32(sp)
    800022da:	64e2                	ld	s1,24(sp)
    800022dc:	6942                	ld	s2,16(sp)
    800022de:	69a2                	ld	s3,8(sp)
    800022e0:	6145                	add	sp,sp,48
    800022e2:	8082                	ret
        p->state = RUNNABLE;
    800022e4:	478d                	li	a5,3
    800022e6:	cc9c                	sw	a5,24(s1)
    800022e8:	b7cd                	j	800022ca <kill+0x52>

00000000800022ea <setkilled>:

void setkilled(struct proc *p)
{
    800022ea:	1101                	add	sp,sp,-32
    800022ec:	ec06                	sd	ra,24(sp)
    800022ee:	e822                	sd	s0,16(sp)
    800022f0:	e426                	sd	s1,8(sp)
    800022f2:	1000                	add	s0,sp,32
    800022f4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	8dc080e7          	jalr	-1828(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800022fe:	4785                	li	a5,1
    80002300:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	982080e7          	jalr	-1662(ra) # 80000c86 <release>
}
    8000230c:	60e2                	ld	ra,24(sp)
    8000230e:	6442                	ld	s0,16(sp)
    80002310:	64a2                	ld	s1,8(sp)
    80002312:	6105                	add	sp,sp,32
    80002314:	8082                	ret

0000000080002316 <killed>:

int killed(struct proc *p)
{
    80002316:	1101                	add	sp,sp,-32
    80002318:	ec06                	sd	ra,24(sp)
    8000231a:	e822                	sd	s0,16(sp)
    8000231c:	e426                	sd	s1,8(sp)
    8000231e:	e04a                	sd	s2,0(sp)
    80002320:	1000                	add	s0,sp,32
    80002322:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ae080e7          	jalr	-1874(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000232c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	954080e7          	jalr	-1708(ra) # 80000c86 <release>
  return k;
}
    8000233a:	854a                	mv	a0,s2
    8000233c:	60e2                	ld	ra,24(sp)
    8000233e:	6442                	ld	s0,16(sp)
    80002340:	64a2                	ld	s1,8(sp)
    80002342:	6902                	ld	s2,0(sp)
    80002344:	6105                	add	sp,sp,32
    80002346:	8082                	ret

0000000080002348 <wait>:
{
    80002348:	715d                	add	sp,sp,-80
    8000234a:	e486                	sd	ra,72(sp)
    8000234c:	e0a2                	sd	s0,64(sp)
    8000234e:	fc26                	sd	s1,56(sp)
    80002350:	f84a                	sd	s2,48(sp)
    80002352:	f44e                	sd	s3,40(sp)
    80002354:	f052                	sd	s4,32(sp)
    80002356:	ec56                	sd	s5,24(sp)
    80002358:	e85a                	sd	s6,16(sp)
    8000235a:	e45e                	sd	s7,8(sp)
    8000235c:	e062                	sd	s8,0(sp)
    8000235e:	0880                	add	s0,sp,80
    80002360:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	644080e7          	jalr	1604(ra) # 800019a6 <myproc>
    8000236a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000236c:	0000f517          	auipc	a0,0xf
    80002370:	80c50513          	add	a0,a0,-2036 # 80010b78 <wait_lock>
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	85e080e7          	jalr	-1954(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000237c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000237e:	4a15                	li	s4,5
        havekids = 1;
    80002380:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002382:	00015997          	auipc	s3,0x15
    80002386:	a0e98993          	add	s3,s3,-1522 # 80016d90 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000238a:	0000ec17          	auipc	s8,0xe
    8000238e:	7eec0c13          	add	s8,s8,2030 # 80010b78 <wait_lock>
    80002392:	a0d1                	j	80002456 <wait+0x10e>
          pid = pp->pid;
    80002394:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002398:	000b0e63          	beqz	s6,800023b4 <wait+0x6c>
    8000239c:	4691                	li	a3,4
    8000239e:	02c48613          	add	a2,s1,44
    800023a2:	85da                	mv	a1,s6
    800023a4:	05093503          	ld	a0,80(s2)
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	2be080e7          	jalr	702(ra) # 80001666 <copyout>
    800023b0:	04054163          	bltz	a0,800023f2 <wait+0xaa>
          freeproc(pp);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	7a2080e7          	jalr	1954(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8c6080e7          	jalr	-1850(ra) # 80000c86 <release>
          release(&wait_lock);
    800023c8:	0000e517          	auipc	a0,0xe
    800023cc:	7b050513          	add	a0,a0,1968 # 80010b78 <wait_lock>
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8b6080e7          	jalr	-1866(ra) # 80000c86 <release>
}
    800023d8:	854e                	mv	a0,s3
    800023da:	60a6                	ld	ra,72(sp)
    800023dc:	6406                	ld	s0,64(sp)
    800023de:	74e2                	ld	s1,56(sp)
    800023e0:	7942                	ld	s2,48(sp)
    800023e2:	79a2                	ld	s3,40(sp)
    800023e4:	7a02                	ld	s4,32(sp)
    800023e6:	6ae2                	ld	s5,24(sp)
    800023e8:	6b42                	ld	s6,16(sp)
    800023ea:	6ba2                	ld	s7,8(sp)
    800023ec:	6c02                	ld	s8,0(sp)
    800023ee:	6161                	add	sp,sp,80
    800023f0:	8082                	ret
            release(&pp->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	892080e7          	jalr	-1902(ra) # 80000c86 <release>
            release(&wait_lock);
    800023fc:	0000e517          	auipc	a0,0xe
    80002400:	77c50513          	add	a0,a0,1916 # 80010b78 <wait_lock>
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	882080e7          	jalr	-1918(ra) # 80000c86 <release>
            return -1;
    8000240c:	59fd                	li	s3,-1
    8000240e:	b7e9                	j	800023d8 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002410:	17848493          	add	s1,s1,376
    80002414:	03348463          	beq	s1,s3,8000243c <wait+0xf4>
      if (pp->parent == p)
    80002418:	7c9c                	ld	a5,56(s1)
    8000241a:	ff279be3          	bne	a5,s2,80002410 <wait+0xc8>
        acquire(&pp->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7b2080e7          	jalr	1970(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002428:	4c9c                	lw	a5,24(s1)
    8000242a:	f74785e3          	beq	a5,s4,80002394 <wait+0x4c>
        release(&pp->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	856080e7          	jalr	-1962(ra) # 80000c86 <release>
        havekids = 1;
    80002438:	8756                	mv	a4,s5
    8000243a:	bfd9                	j	80002410 <wait+0xc8>
    if (!havekids || killed(p))
    8000243c:	c31d                	beqz	a4,80002462 <wait+0x11a>
    8000243e:	854a                	mv	a0,s2
    80002440:	00000097          	auipc	ra,0x0
    80002444:	ed6080e7          	jalr	-298(ra) # 80002316 <killed>
    80002448:	ed09                	bnez	a0,80002462 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000244a:	85e2                	mv	a1,s8
    8000244c:	854a                	mv	a0,s2
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	c14080e7          	jalr	-1004(ra) # 80002062 <sleep>
    havekids = 0;
    80002456:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002458:	0000f497          	auipc	s1,0xf
    8000245c:	b3848493          	add	s1,s1,-1224 # 80010f90 <proc>
    80002460:	bf65                	j	80002418 <wait+0xd0>
      release(&wait_lock);
    80002462:	0000e517          	auipc	a0,0xe
    80002466:	71650513          	add	a0,a0,1814 # 80010b78 <wait_lock>
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	81c080e7          	jalr	-2020(ra) # 80000c86 <release>
      return -1;
    80002472:	59fd                	li	s3,-1
    80002474:	b795                	j	800023d8 <wait+0x90>

0000000080002476 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002476:	7179                	add	sp,sp,-48
    80002478:	f406                	sd	ra,40(sp)
    8000247a:	f022                	sd	s0,32(sp)
    8000247c:	ec26                	sd	s1,24(sp)
    8000247e:	e84a                	sd	s2,16(sp)
    80002480:	e44e                	sd	s3,8(sp)
    80002482:	e052                	sd	s4,0(sp)
    80002484:	1800                	add	s0,sp,48
    80002486:	84aa                	mv	s1,a0
    80002488:	892e                	mv	s2,a1
    8000248a:	89b2                	mv	s3,a2
    8000248c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	518080e7          	jalr	1304(ra) # 800019a6 <myproc>
  if (user_dst)
    80002496:	c08d                	beqz	s1,800024b8 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002498:	86d2                	mv	a3,s4
    8000249a:	864e                	mv	a2,s3
    8000249c:	85ca                	mv	a1,s2
    8000249e:	6928                	ld	a0,80(a0)
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	1c6080e7          	jalr	454(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6a02                	ld	s4,0(sp)
    800024b4:	6145                	add	sp,sp,48
    800024b6:	8082                	ret
    memmove((char *)dst, src, len);
    800024b8:	000a061b          	sext.w	a2,s4
    800024bc:	85ce                	mv	a1,s3
    800024be:	854a                	mv	a0,s2
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	86a080e7          	jalr	-1942(ra) # 80000d2a <memmove>
    return 0;
    800024c8:	8526                	mv	a0,s1
    800024ca:	bff9                	j	800024a8 <either_copyout+0x32>

00000000800024cc <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024cc:	7179                	add	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	e052                	sd	s4,0(sp)
    800024da:	1800                	add	s0,sp,48
    800024dc:	892a                	mv	s2,a0
    800024de:	84ae                	mv	s1,a1
    800024e0:	89b2                	mv	s3,a2
    800024e2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	4c2080e7          	jalr	1218(ra) # 800019a6 <myproc>
  if (user_src)
    800024ec:	c08d                	beqz	s1,8000250e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024ee:	86d2                	mv	a3,s4
    800024f0:	864e                	mv	a2,s3
    800024f2:	85ca                	mv	a1,s2
    800024f4:	6928                	ld	a0,80(a0)
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	1fc080e7          	jalr	508(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6a02                	ld	s4,0(sp)
    8000250a:	6145                	add	sp,sp,48
    8000250c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000250e:	000a061b          	sext.w	a2,s4
    80002512:	85ce                	mv	a1,s3
    80002514:	854a                	mv	a0,s2
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	814080e7          	jalr	-2028(ra) # 80000d2a <memmove>
    return 0;
    8000251e:	8526                	mv	a0,s1
    80002520:	bff9                	j	800024fe <either_copyin+0x32>

0000000080002522 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002522:	715d                	add	sp,sp,-80
    80002524:	e486                	sd	ra,72(sp)
    80002526:	e0a2                	sd	s0,64(sp)
    80002528:	fc26                	sd	s1,56(sp)
    8000252a:	f84a                	sd	s2,48(sp)
    8000252c:	f44e                	sd	s3,40(sp)
    8000252e:	f052                	sd	s4,32(sp)
    80002530:	ec56                	sd	s5,24(sp)
    80002532:	e85a                	sd	s6,16(sp)
    80002534:	e45e                	sd	s7,8(sp)
    80002536:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	b9050513          	add	a0,a0,-1136 # 800080c8 <digits+0x88>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	046080e7          	jalr	70(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002548:	0000f497          	auipc	s1,0xf
    8000254c:	ba048493          	add	s1,s1,-1120 # 800110e8 <proc+0x158>
    80002550:	00015917          	auipc	s2,0x15
    80002554:	99890913          	add	s2,s2,-1640 # 80016ee8 <bcache+0xc0>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000255a:	00006997          	auipc	s3,0x6
    8000255e:	d2698993          	add	s3,s3,-730 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	00006a97          	auipc	s5,0x6
    80002566:	d26a8a93          	add	s5,s5,-730 # 80008288 <digits+0x248>
    printf("\n");
    8000256a:	00006a17          	auipc	s4,0x6
    8000256e:	b5ea0a13          	add	s4,s4,-1186 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002572:	00006b97          	auipc	s7,0x6
    80002576:	d56b8b93          	add	s7,s7,-682 # 800082c8 <states.0>
    8000257a:	a00d                	j	8000259c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000257c:	ed86a583          	lw	a1,-296(a3)
    80002580:	8556                	mv	a0,s5
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	004080e7          	jalr	4(ra) # 80000586 <printf>
    printf("\n");
    8000258a:	8552                	mv	a0,s4
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	ffa080e7          	jalr	-6(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002594:	17848493          	add	s1,s1,376
    80002598:	03248263          	beq	s1,s2,800025bc <procdump+0x9a>
    if (p->state == UNUSED)
    8000259c:	86a6                	mv	a3,s1
    8000259e:	ec04a783          	lw	a5,-320(s1)
    800025a2:	dbed                	beqz	a5,80002594 <procdump+0x72>
      state = "???";
    800025a4:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	fcfb6be3          	bltu	s6,a5,8000257c <procdump+0x5a>
    800025aa:	02079713          	sll	a4,a5,0x20
    800025ae:	01d75793          	srl	a5,a4,0x1d
    800025b2:	97de                	add	a5,a5,s7
    800025b4:	6390                	ld	a2,0(a5)
    800025b6:	f279                	bnez	a2,8000257c <procdump+0x5a>
      state = "???";
    800025b8:	864e                	mv	a2,s3
    800025ba:	b7c9                	j	8000257c <procdump+0x5a>
  }
}
    800025bc:	60a6                	ld	ra,72(sp)
    800025be:	6406                	ld	s0,64(sp)
    800025c0:	74e2                	ld	s1,56(sp)
    800025c2:	7942                	ld	s2,48(sp)
    800025c4:	79a2                	ld	s3,40(sp)
    800025c6:	7a02                	ld	s4,32(sp)
    800025c8:	6ae2                	ld	s5,24(sp)
    800025ca:	6b42                	ld	s6,16(sp)
    800025cc:	6ba2                	ld	s7,8(sp)
    800025ce:	6161                	add	sp,sp,80
    800025d0:	8082                	ret

00000000800025d2 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025d2:	711d                	add	sp,sp,-96
    800025d4:	ec86                	sd	ra,88(sp)
    800025d6:	e8a2                	sd	s0,80(sp)
    800025d8:	e4a6                	sd	s1,72(sp)
    800025da:	e0ca                	sd	s2,64(sp)
    800025dc:	fc4e                	sd	s3,56(sp)
    800025de:	f852                	sd	s4,48(sp)
    800025e0:	f456                	sd	s5,40(sp)
    800025e2:	f05a                	sd	s6,32(sp)
    800025e4:	ec5e                	sd	s7,24(sp)
    800025e6:	e862                	sd	s8,16(sp)
    800025e8:	e466                	sd	s9,8(sp)
    800025ea:	e06a                	sd	s10,0(sp)
    800025ec:	1080                	add	s0,sp,96
    800025ee:	8b2a                	mv	s6,a0
    800025f0:	8bae                	mv	s7,a1
    800025f2:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	3b2080e7          	jalr	946(ra) # 800019a6 <myproc>
    800025fc:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800025fe:	0000e517          	auipc	a0,0xe
    80002602:	57a50513          	add	a0,a0,1402 # 80010b78 <wait_lock>
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	5cc080e7          	jalr	1484(ra) # 80000bd2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000260e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002610:	4a15                	li	s4,5
        havekids = 1;
    80002612:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002614:	00014997          	auipc	s3,0x14
    80002618:	77c98993          	add	s3,s3,1916 # 80016d90 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000261c:	0000ed17          	auipc	s10,0xe
    80002620:	55cd0d13          	add	s10,s10,1372 # 80010b78 <wait_lock>
    80002624:	a8e9                	j	800026fe <waitx+0x12c>
          pid = np->pid;
    80002626:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000262a:	1684a783          	lw	a5,360(s1)
    8000262e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002632:	16c4a703          	lw	a4,364(s1)
    80002636:	9f3d                	addw	a4,a4,a5
    80002638:	1704a783          	lw	a5,368(s1)
    8000263c:	9f99                	subw	a5,a5,a4
    8000263e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002642:	000b0e63          	beqz	s6,8000265e <waitx+0x8c>
    80002646:	4691                	li	a3,4
    80002648:	02c48613          	add	a2,s1,44
    8000264c:	85da                	mv	a1,s6
    8000264e:	05093503          	ld	a0,80(s2)
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	014080e7          	jalr	20(ra) # 80001666 <copyout>
    8000265a:	04054363          	bltz	a0,800026a0 <waitx+0xce>
          freeproc(np);
    8000265e:	8526                	mv	a0,s1
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	4f8080e7          	jalr	1272(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	61c080e7          	jalr	1564(ra) # 80000c86 <release>
          release(&wait_lock);
    80002672:	0000e517          	auipc	a0,0xe
    80002676:	50650513          	add	a0,a0,1286 # 80010b78 <wait_lock>
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	60c080e7          	jalr	1548(ra) # 80000c86 <release>
  }
}
    80002682:	854e                	mv	a0,s3
    80002684:	60e6                	ld	ra,88(sp)
    80002686:	6446                	ld	s0,80(sp)
    80002688:	64a6                	ld	s1,72(sp)
    8000268a:	6906                	ld	s2,64(sp)
    8000268c:	79e2                	ld	s3,56(sp)
    8000268e:	7a42                	ld	s4,48(sp)
    80002690:	7aa2                	ld	s5,40(sp)
    80002692:	7b02                	ld	s6,32(sp)
    80002694:	6be2                	ld	s7,24(sp)
    80002696:	6c42                	ld	s8,16(sp)
    80002698:	6ca2                	ld	s9,8(sp)
    8000269a:	6d02                	ld	s10,0(sp)
    8000269c:	6125                	add	sp,sp,96
    8000269e:	8082                	ret
            release(&np->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	5e4080e7          	jalr	1508(ra) # 80000c86 <release>
            release(&wait_lock);
    800026aa:	0000e517          	auipc	a0,0xe
    800026ae:	4ce50513          	add	a0,a0,1230 # 80010b78 <wait_lock>
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	5d4080e7          	jalr	1492(ra) # 80000c86 <release>
            return -1;
    800026ba:	59fd                	li	s3,-1
    800026bc:	b7d9                	j	80002682 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    800026be:	17848493          	add	s1,s1,376
    800026c2:	03348463          	beq	s1,s3,800026ea <waitx+0x118>
      if (np->parent == p)
    800026c6:	7c9c                	ld	a5,56(s1)
    800026c8:	ff279be3          	bne	a5,s2,800026be <waitx+0xec>
        acquire(&np->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	504080e7          	jalr	1284(ra) # 80000bd2 <acquire>
        if (np->state == ZOMBIE)
    800026d6:	4c9c                	lw	a5,24(s1)
    800026d8:	f54787e3          	beq	a5,s4,80002626 <waitx+0x54>
        release(&np->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5a8080e7          	jalr	1448(ra) # 80000c86 <release>
        havekids = 1;
    800026e6:	8756                	mv	a4,s5
    800026e8:	bfd9                	j	800026be <waitx+0xec>
    if (!havekids || p->killed)
    800026ea:	c305                	beqz	a4,8000270a <waitx+0x138>
    800026ec:	02892783          	lw	a5,40(s2)
    800026f0:	ef89                	bnez	a5,8000270a <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026f2:	85ea                	mv	a1,s10
    800026f4:	854a                	mv	a0,s2
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	96c080e7          	jalr	-1684(ra) # 80002062 <sleep>
    havekids = 0;
    800026fe:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002700:	0000f497          	auipc	s1,0xf
    80002704:	89048493          	add	s1,s1,-1904 # 80010f90 <proc>
    80002708:	bf7d                	j	800026c6 <waitx+0xf4>
      release(&wait_lock);
    8000270a:	0000e517          	auipc	a0,0xe
    8000270e:	46e50513          	add	a0,a0,1134 # 80010b78 <wait_lock>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	574080e7          	jalr	1396(ra) # 80000c86 <release>
      return -1;
    8000271a:	59fd                	li	s3,-1
    8000271c:	b79d                	j	80002682 <waitx+0xb0>

000000008000271e <update_time>:

void update_time()
{
    8000271e:	7179                	add	sp,sp,-48
    80002720:	f406                	sd	ra,40(sp)
    80002722:	f022                	sd	s0,32(sp)
    80002724:	ec26                	sd	s1,24(sp)
    80002726:	e84a                	sd	s2,16(sp)
    80002728:	e44e                	sd	s3,8(sp)
    8000272a:	1800                	add	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000272c:	0000f497          	auipc	s1,0xf
    80002730:	86448493          	add	s1,s1,-1948 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002734:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002736:	00014917          	auipc	s2,0x14
    8000273a:	65a90913          	add	s2,s2,1626 # 80016d90 <tickslock>
    8000273e:	a811                	j	80002752 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	544080e7          	jalr	1348(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000274a:	17848493          	add	s1,s1,376
    8000274e:	03248063          	beq	s1,s2,8000276e <update_time+0x50>
    acquire(&p->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	47e080e7          	jalr	1150(ra) # 80000bd2 <acquire>
    if (p->state == RUNNING)
    8000275c:	4c9c                	lw	a5,24(s1)
    8000275e:	ff3791e3          	bne	a5,s3,80002740 <update_time+0x22>
      p->rtime++;
    80002762:	1684a783          	lw	a5,360(s1)
    80002766:	2785                	addw	a5,a5,1
    80002768:	16f4a423          	sw	a5,360(s1)
    8000276c:	bfd1                	j	80002740 <update_time+0x22>
  }
    8000276e:	70a2                	ld	ra,40(sp)
    80002770:	7402                	ld	s0,32(sp)
    80002772:	64e2                	ld	s1,24(sp)
    80002774:	6942                	ld	s2,16(sp)
    80002776:	69a2                	ld	s3,8(sp)
    80002778:	6145                	add	sp,sp,48
    8000277a:	8082                	ret

000000008000277c <swtch>:
    8000277c:	00153023          	sd	ra,0(a0)
    80002780:	00253423          	sd	sp,8(a0)
    80002784:	e900                	sd	s0,16(a0)
    80002786:	ed04                	sd	s1,24(a0)
    80002788:	03253023          	sd	s2,32(a0)
    8000278c:	03353423          	sd	s3,40(a0)
    80002790:	03453823          	sd	s4,48(a0)
    80002794:	03553c23          	sd	s5,56(a0)
    80002798:	05653023          	sd	s6,64(a0)
    8000279c:	05753423          	sd	s7,72(a0)
    800027a0:	05853823          	sd	s8,80(a0)
    800027a4:	05953c23          	sd	s9,88(a0)
    800027a8:	07a53023          	sd	s10,96(a0)
    800027ac:	07b53423          	sd	s11,104(a0)
    800027b0:	0005b083          	ld	ra,0(a1)
    800027b4:	0085b103          	ld	sp,8(a1)
    800027b8:	6980                	ld	s0,16(a1)
    800027ba:	6d84                	ld	s1,24(a1)
    800027bc:	0205b903          	ld	s2,32(a1)
    800027c0:	0285b983          	ld	s3,40(a1)
    800027c4:	0305ba03          	ld	s4,48(a1)
    800027c8:	0385ba83          	ld	s5,56(a1)
    800027cc:	0405bb03          	ld	s6,64(a1)
    800027d0:	0485bb83          	ld	s7,72(a1)
    800027d4:	0505bc03          	ld	s8,80(a1)
    800027d8:	0585bc83          	ld	s9,88(a1)
    800027dc:	0605bd03          	ld	s10,96(a1)
    800027e0:	0685bd83          	ld	s11,104(a1)
    800027e4:	8082                	ret

00000000800027e6 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800027e6:	1141                	add	sp,sp,-16
    800027e8:	e406                	sd	ra,8(sp)
    800027ea:	e022                	sd	s0,0(sp)
    800027ec:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    800027ee:	00006597          	auipc	a1,0x6
    800027f2:	b0a58593          	add	a1,a1,-1270 # 800082f8 <states.0+0x30>
    800027f6:	00014517          	auipc	a0,0x14
    800027fa:	59a50513          	add	a0,a0,1434 # 80016d90 <tickslock>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	344080e7          	jalr	836(ra) # 80000b42 <initlock>
}
    80002806:	60a2                	ld	ra,8(sp)
    80002808:	6402                	ld	s0,0(sp)
    8000280a:	0141                	add	sp,sp,16
    8000280c:	8082                	ret

000000008000280e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000280e:	1141                	add	sp,sp,-16
    80002810:	e422                	sd	s0,8(sp)
    80002812:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002814:	00003797          	auipc	a5,0x3
    80002818:	56c78793          	add	a5,a5,1388 # 80005d80 <kernelvec>
    8000281c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002820:	6422                	ld	s0,8(sp)
    80002822:	0141                	add	sp,sp,16
    80002824:	8082                	ret

0000000080002826 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002826:	1141                	add	sp,sp,-16
    80002828:	e406                	sd	ra,8(sp)
    8000282a:	e022                	sd	s0,0(sp)
    8000282c:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	178080e7          	jalr	376(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002836:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000283a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000283c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002840:	00004697          	auipc	a3,0x4
    80002844:	7c068693          	add	a3,a3,1984 # 80007000 <_trampoline>
    80002848:	00004717          	auipc	a4,0x4
    8000284c:	7b870713          	add	a4,a4,1976 # 80007000 <_trampoline>
    80002850:	8f15                	sub	a4,a4,a3
    80002852:	040007b7          	lui	a5,0x4000
    80002856:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002858:	07b2                	sll	a5,a5,0xc
    8000285a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000285c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002860:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002862:	18002673          	csrr	a2,satp
    80002866:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002868:	6d30                	ld	a2,88(a0)
    8000286a:	6138                	ld	a4,64(a0)
    8000286c:	6585                	lui	a1,0x1
    8000286e:	972e                	add	a4,a4,a1
    80002870:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002872:	6d38                	ld	a4,88(a0)
    80002874:	00000617          	auipc	a2,0x0
    80002878:	14260613          	add	a2,a2,322 # 800029b6 <usertrap>
    8000287c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000287e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002880:	8612                	mv	a2,tp
    80002882:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002884:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002888:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000288c:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002896:	6f18                	ld	a4,24(a4)
    80002898:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000289c:	6928                	ld	a0,80(a0)
    8000289e:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028a0:	00004717          	auipc	a4,0x4
    800028a4:	7fc70713          	add	a4,a4,2044 # 8000709c <userret>
    800028a8:	8f15                	sub	a4,a4,a3
    800028aa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028ac:	577d                	li	a4,-1
    800028ae:	177e                	sll	a4,a4,0x3f
    800028b0:	8d59                	or	a0,a0,a4
    800028b2:	9782                	jalr	a5
}
    800028b4:	60a2                	ld	ra,8(sp)
    800028b6:	6402                	ld	s0,0(sp)
    800028b8:	0141                	add	sp,sp,16
    800028ba:	8082                	ret

00000000800028bc <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028bc:	1101                	add	sp,sp,-32
    800028be:	ec06                	sd	ra,24(sp)
    800028c0:	e822                	sd	s0,16(sp)
    800028c2:	e426                	sd	s1,8(sp)
    800028c4:	e04a                	sd	s2,0(sp)
    800028c6:	1000                	add	s0,sp,32
  acquire(&tickslock);
    800028c8:	00014917          	auipc	s2,0x14
    800028cc:	4c890913          	add	s2,s2,1224 # 80016d90 <tickslock>
    800028d0:	854a                	mv	a0,s2
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	300080e7          	jalr	768(ra) # 80000bd2 <acquire>
  ticks++;
    800028da:	00006497          	auipc	s1,0x6
    800028de:	01648493          	add	s1,s1,22 # 800088f0 <ticks>
    800028e2:	409c                	lw	a5,0(s1)
    800028e4:	2785                	addw	a5,a5,1
    800028e6:	c09c                	sw	a5,0(s1)
  update_time();
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	e36080e7          	jalr	-458(ra) # 8000271e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800028f0:	8526                	mv	a0,s1
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	7d4080e7          	jalr	2004(ra) # 800020c6 <wakeup>
  release(&tickslock);
    800028fa:	854a                	mv	a0,s2
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	38a080e7          	jalr	906(ra) # 80000c86 <release>
}
    80002904:	60e2                	ld	ra,24(sp)
    80002906:	6442                	ld	s0,16(sp)
    80002908:	64a2                	ld	s1,8(sp)
    8000290a:	6902                	ld	s2,0(sp)
    8000290c:	6105                	add	sp,sp,32
    8000290e:	8082                	ret

0000000080002910 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002910:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002914:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002916:	0807df63          	bgez	a5,800029b4 <devintr+0xa4>
{
    8000291a:	1101                	add	sp,sp,-32
    8000291c:	ec06                	sd	ra,24(sp)
    8000291e:	e822                	sd	s0,16(sp)
    80002920:	e426                	sd	s1,8(sp)
    80002922:	1000                	add	s0,sp,32
      (scause & 0xff) == 9)
    80002924:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002928:	46a5                	li	a3,9
    8000292a:	00d70d63          	beq	a4,a3,80002944 <devintr+0x34>
  else if (scause == 0x8000000000000001L)
    8000292e:	577d                	li	a4,-1
    80002930:	177e                	sll	a4,a4,0x3f
    80002932:	0705                	add	a4,a4,1
    return 0;
    80002934:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002936:	04e78e63          	beq	a5,a4,80002992 <devintr+0x82>
  }
}
    8000293a:	60e2                	ld	ra,24(sp)
    8000293c:	6442                	ld	s0,16(sp)
    8000293e:	64a2                	ld	s1,8(sp)
    80002940:	6105                	add	sp,sp,32
    80002942:	8082                	ret
    int irq = plic_claim();
    80002944:	00003097          	auipc	ra,0x3
    80002948:	544080e7          	jalr	1348(ra) # 80005e88 <plic_claim>
    8000294c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000294e:	47a9                	li	a5,10
    80002950:	02f50763          	beq	a0,a5,8000297e <devintr+0x6e>
    else if (irq == VIRTIO0_IRQ)
    80002954:	4785                	li	a5,1
    80002956:	02f50963          	beq	a0,a5,80002988 <devintr+0x78>
    return 1;
    8000295a:	4505                	li	a0,1
    else if (irq)
    8000295c:	dcf9                	beqz	s1,8000293a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    8000295e:	85a6                	mv	a1,s1
    80002960:	00006517          	auipc	a0,0x6
    80002964:	9a050513          	add	a0,a0,-1632 # 80008300 <states.0+0x38>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c1e080e7          	jalr	-994(ra) # 80000586 <printf>
      plic_complete(irq);
    80002970:	8526                	mv	a0,s1
    80002972:	00003097          	auipc	ra,0x3
    80002976:	53a080e7          	jalr	1338(ra) # 80005eac <plic_complete>
    return 1;
    8000297a:	4505                	li	a0,1
    8000297c:	bf7d                	j	8000293a <devintr+0x2a>
      uartintr();
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	016080e7          	jalr	22(ra) # 80000994 <uartintr>
    if (irq)
    80002986:	b7ed                	j	80002970 <devintr+0x60>
      virtio_disk_intr();
    80002988:	00004097          	auipc	ra,0x4
    8000298c:	9ea080e7          	jalr	-1558(ra) # 80006372 <virtio_disk_intr>
    if (irq)
    80002990:	b7c5                	j	80002970 <devintr+0x60>
    if (cpuid() == 0)
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	fe8080e7          	jalr	-24(ra) # 8000197a <cpuid>
    8000299a:	c901                	beqz	a0,800029aa <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000299c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a2:	14479073          	csrw	sip,a5
    return 2;
    800029a6:	4509                	li	a0,2
    800029a8:	bf49                	j	8000293a <devintr+0x2a>
      clockintr();
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	f12080e7          	jalr	-238(ra) # 800028bc <clockintr>
    800029b2:	b7ed                	j	8000299c <devintr+0x8c>
}
    800029b4:	8082                	ret

00000000800029b6 <usertrap>:
{
    800029b6:	1101                	add	sp,sp,-32
    800029b8:	ec06                	sd	ra,24(sp)
    800029ba:	e822                	sd	s0,16(sp)
    800029bc:	e426                	sd	s1,8(sp)
    800029be:	e04a                	sd	s2,0(sp)
    800029c0:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029c6:	1007f793          	and	a5,a5,256
    800029ca:	e3b1                	bnez	a5,80002a0e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029cc:	00003797          	auipc	a5,0x3
    800029d0:	3b478793          	add	a5,a5,948 # 80005d80 <kernelvec>
    800029d4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	fce080e7          	jalr	-50(ra) # 800019a6 <myproc>
    800029e0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	14102773          	csrr	a4,sepc
    800029e8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ea:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800029ee:	47a1                	li	a5,8
    800029f0:	02f70763          	beq	a4,a5,80002a1e <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	f1c080e7          	jalr	-228(ra) # 80002910 <devintr>
    800029fc:	892a                	mv	s2,a0
    800029fe:	c151                	beqz	a0,80002a82 <usertrap+0xcc>
  if (killed(p))
    80002a00:	8526                	mv	a0,s1
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	914080e7          	jalr	-1772(ra) # 80002316 <killed>
    80002a0a:	c929                	beqz	a0,80002a5c <usertrap+0xa6>
    80002a0c:	a099                	j	80002a52 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	91250513          	add	a0,a0,-1774 # 80008320 <states.0+0x58>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b26080e7          	jalr	-1242(ra) # 8000053c <panic>
    if (killed(p))
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	8f8080e7          	jalr	-1800(ra) # 80002316 <killed>
    80002a26:	e921                	bnez	a0,80002a76 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a28:	6cb8                	ld	a4,88(s1)
    80002a2a:	6f1c                	ld	a5,24(a4)
    80002a2c:	0791                	add	a5,a5,4
    80002a2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a34:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a38:	10079073          	csrw	sstatus,a5
    syscall();
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	2d4080e7          	jalr	724(ra) # 80002d10 <syscall>
  if (killed(p))
    80002a44:	8526                	mv	a0,s1
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	8d0080e7          	jalr	-1840(ra) # 80002316 <killed>
    80002a4e:	c911                	beqz	a0,80002a62 <usertrap+0xac>
    80002a50:	4901                	li	s2,0
    exit(-1);
    80002a52:	557d                	li	a0,-1
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	742080e7          	jalr	1858(ra) # 80002196 <exit>
  if (which_dev == 2)
    80002a5c:	4789                	li	a5,2
    80002a5e:	04f90f63          	beq	s2,a5,80002abc <usertrap+0x106>
  usertrapret();
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	dc4080e7          	jalr	-572(ra) # 80002826 <usertrapret>
}
    80002a6a:	60e2                	ld	ra,24(sp)
    80002a6c:	6442                	ld	s0,16(sp)
    80002a6e:	64a2                	ld	s1,8(sp)
    80002a70:	6902                	ld	s2,0(sp)
    80002a72:	6105                	add	sp,sp,32
    80002a74:	8082                	ret
      exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	71e080e7          	jalr	1822(ra) # 80002196 <exit>
    80002a80:	b765                	j	80002a28 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a86:	5890                	lw	a2,48(s1)
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	8b850513          	add	a0,a0,-1864 # 80008340 <states.0+0x78>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	af6080e7          	jalr	-1290(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	8d050513          	add	a0,a0,-1840 # 80008370 <states.0+0xa8>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	ade080e7          	jalr	-1314(ra) # 80000586 <printf>
    setkilled(p);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	838080e7          	jalr	-1992(ra) # 800022ea <setkilled>
    80002aba:	b769                	j	80002a44 <usertrap+0x8e>
    yield();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	56a080e7          	jalr	1386(ra) # 80002026 <yield>
    80002ac4:	bf79                	j	80002a62 <usertrap+0xac>

0000000080002ac6 <kerneltrap>:
{
    80002ac6:	7179                	add	sp,sp,-48
    80002ac8:	f406                	sd	ra,40(sp)
    80002aca:	f022                	sd	s0,32(sp)
    80002acc:	ec26                	sd	s1,24(sp)
    80002ace:	e84a                	sd	s2,16(sp)
    80002ad0:	e44e                	sd	s3,8(sp)
    80002ad2:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002adc:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ae0:	1004f793          	and	a5,s1,256
    80002ae4:	cb85                	beqz	a5,80002b14 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aea:	8b89                	and	a5,a5,2
  if (intr_get() != 0)
    80002aec:	ef85                	bnez	a5,80002b24 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	e22080e7          	jalr	-478(ra) # 80002910 <devintr>
    80002af6:	cd1d                	beqz	a0,80002b34 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002af8:	4789                	li	a5,2
    80002afa:	06f50a63          	beq	a0,a5,80002b6e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002afe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b02:	10049073          	csrw	sstatus,s1
}
    80002b06:	70a2                	ld	ra,40(sp)
    80002b08:	7402                	ld	s0,32(sp)
    80002b0a:	64e2                	ld	s1,24(sp)
    80002b0c:	6942                	ld	s2,16(sp)
    80002b0e:	69a2                	ld	s3,8(sp)
    80002b10:	6145                	add	sp,sp,48
    80002b12:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	87c50513          	add	a0,a0,-1924 # 80008390 <states.0+0xc8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a20080e7          	jalr	-1504(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	89450513          	add	a0,a0,-1900 # 800083b8 <states.0+0xf0>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a10080e7          	jalr	-1520(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002b34:	85ce                	mv	a1,s3
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	8a250513          	add	a0,a0,-1886 # 800083d8 <states.0+0x110>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a48080e7          	jalr	-1464(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b4a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b4e:	00006517          	auipc	a0,0x6
    80002b52:	89a50513          	add	a0,a0,-1894 # 800083e8 <states.0+0x120>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	a30080e7          	jalr	-1488(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	8a250513          	add	a0,a0,-1886 # 80008400 <states.0+0x138>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9d6080e7          	jalr	-1578(ra) # 8000053c <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	e38080e7          	jalr	-456(ra) # 800019a6 <myproc>
    80002b76:	d541                	beqz	a0,80002afe <kerneltrap+0x38>
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e2e080e7          	jalr	-466(ra) # 800019a6 <myproc>
    80002b80:	4d18                	lw	a4,24(a0)
    80002b82:	4791                	li	a5,4
    80002b84:	f6f71de3          	bne	a4,a5,80002afe <kerneltrap+0x38>
    yield();
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	49e080e7          	jalr	1182(ra) # 80002026 <yield>
    80002b90:	b7bd                	j	80002afe <kerneltrap+0x38>

0000000080002b92 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b92:	1101                	add	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	1000                	add	s0,sp,32
    80002b9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e08080e7          	jalr	-504(ra) # 800019a6 <myproc>
  switch (n) {
    80002ba6:	4795                	li	a5,5
    80002ba8:	0497e163          	bltu	a5,s1,80002bea <argraw+0x58>
    80002bac:	048a                	sll	s1,s1,0x2
    80002bae:	00006717          	auipc	a4,0x6
    80002bb2:	88a70713          	add	a4,a4,-1910 # 80008438 <states.0+0x170>
    80002bb6:	94ba                	add	s1,s1,a4
    80002bb8:	409c                	lw	a5,0(s1)
    80002bba:	97ba                	add	a5,a5,a4
    80002bbc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bbe:	6d3c                	ld	a5,88(a0)
    80002bc0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6105                	add	sp,sp,32
    80002bca:	8082                	ret
    return p->trapframe->a1;
    80002bcc:	6d3c                	ld	a5,88(a0)
    80002bce:	7fa8                	ld	a0,120(a5)
    80002bd0:	bfcd                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a2;
    80002bd2:	6d3c                	ld	a5,88(a0)
    80002bd4:	63c8                	ld	a0,128(a5)
    80002bd6:	b7f5                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a3;
    80002bd8:	6d3c                	ld	a5,88(a0)
    80002bda:	67c8                	ld	a0,136(a5)
    80002bdc:	b7dd                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a4;
    80002bde:	6d3c                	ld	a5,88(a0)
    80002be0:	6bc8                	ld	a0,144(a5)
    80002be2:	b7c5                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a5;
    80002be4:	6d3c                	ld	a5,88(a0)
    80002be6:	6fc8                	ld	a0,152(a5)
    80002be8:	bfe9                	j	80002bc2 <argraw+0x30>
  panic("argraw");
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	82650513          	add	a0,a0,-2010 # 80008410 <states.0+0x148>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	94a080e7          	jalr	-1718(ra) # 8000053c <panic>

0000000080002bfa <fetchaddr>:
{
    80002bfa:	1101                	add	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	add	s0,sp,32
    80002c06:	84aa                	mv	s1,a0
    80002c08:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	d9c080e7          	jalr	-612(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c12:	653c                	ld	a5,72(a0)
    80002c14:	02f4f863          	bgeu	s1,a5,80002c44 <fetchaddr+0x4a>
    80002c18:	00848713          	add	a4,s1,8
    80002c1c:	02e7e663          	bltu	a5,a4,80002c48 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c20:	46a1                	li	a3,8
    80002c22:	8626                	mv	a2,s1
    80002c24:	85ca                	mv	a1,s2
    80002c26:	6928                	ld	a0,80(a0)
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	aca080e7          	jalr	-1334(ra) # 800016f2 <copyin>
    80002c30:	00a03533          	snez	a0,a0
    80002c34:	40a00533          	neg	a0,a0
}
    80002c38:	60e2                	ld	ra,24(sp)
    80002c3a:	6442                	ld	s0,16(sp)
    80002c3c:	64a2                	ld	s1,8(sp)
    80002c3e:	6902                	ld	s2,0(sp)
    80002c40:	6105                	add	sp,sp,32
    80002c42:	8082                	ret
    return -1;
    80002c44:	557d                	li	a0,-1
    80002c46:	bfcd                	j	80002c38 <fetchaddr+0x3e>
    80002c48:	557d                	li	a0,-1
    80002c4a:	b7fd                	j	80002c38 <fetchaddr+0x3e>

0000000080002c4c <fetchstr>:
{
    80002c4c:	7179                	add	sp,sp,-48
    80002c4e:	f406                	sd	ra,40(sp)
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	ec26                	sd	s1,24(sp)
    80002c54:	e84a                	sd	s2,16(sp)
    80002c56:	e44e                	sd	s3,8(sp)
    80002c58:	1800                	add	s0,sp,48
    80002c5a:	892a                	mv	s2,a0
    80002c5c:	84ae                	mv	s1,a1
    80002c5e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d46080e7          	jalr	-698(ra) # 800019a6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c68:	86ce                	mv	a3,s3
    80002c6a:	864a                	mv	a2,s2
    80002c6c:	85a6                	mv	a1,s1
    80002c6e:	6928                	ld	a0,80(a0)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	b10080e7          	jalr	-1264(ra) # 80001780 <copyinstr>
    80002c78:	00054e63          	bltz	a0,80002c94 <fetchstr+0x48>
  return strlen(buf);
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	1ca080e7          	jalr	458(ra) # 80000e48 <strlen>
}
    80002c86:	70a2                	ld	ra,40(sp)
    80002c88:	7402                	ld	s0,32(sp)
    80002c8a:	64e2                	ld	s1,24(sp)
    80002c8c:	6942                	ld	s2,16(sp)
    80002c8e:	69a2                	ld	s3,8(sp)
    80002c90:	6145                	add	sp,sp,48
    80002c92:	8082                	ret
    return -1;
    80002c94:	557d                	li	a0,-1
    80002c96:	bfc5                	j	80002c86 <fetchstr+0x3a>

0000000080002c98 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c98:	1101                	add	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	1000                	add	s0,sp,32
    80002ca2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	eee080e7          	jalr	-274(ra) # 80002b92 <argraw>
    80002cac:	c088                	sw	a0,0(s1)
}
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	64a2                	ld	s1,8(sp)
    80002cb4:	6105                	add	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cb8:	1101                	add	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	add	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ece080e7          	jalr	-306(ra) # 80002b92 <argraw>
    80002ccc:	e088                	sd	a0,0(s1)
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6105                	add	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cd8:	7179                	add	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	e84a                	sd	s2,16(sp)
    80002ce2:	1800                	add	s0,sp,48
    80002ce4:	84ae                	mv	s1,a1
    80002ce6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ce8:	fd840593          	add	a1,s0,-40
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	fcc080e7          	jalr	-52(ra) # 80002cb8 <argaddr>
  return fetchstr(addr, buf, max);
    80002cf4:	864a                	mv	a2,s2
    80002cf6:	85a6                	mv	a1,s1
    80002cf8:	fd843503          	ld	a0,-40(s0)
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	f50080e7          	jalr	-176(ra) # 80002c4c <fetchstr>
}
    80002d04:	70a2                	ld	ra,40(sp)
    80002d06:	7402                	ld	s0,32(sp)
    80002d08:	64e2                	ld	s1,24(sp)
    80002d0a:	6942                	ld	s2,16(sp)
    80002d0c:	6145                	add	sp,sp,48
    80002d0e:	8082                	ret

0000000080002d10 <syscall>:
[SYS_getSysCount]  sys_getSysCount,  // Map getSysCount in syscalls array
};

void
syscall(void)
{
    80002d10:	1101                	add	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	c8c080e7          	jalr	-884(ra) # 800019a6 <myproc>
    80002d22:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d24:	6d3c                	ld	a5,88(a0)
    80002d26:	77dc                	ld	a5,168(a5)
    80002d28:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d2c:	37fd                	addw	a5,a5,-1
    80002d2e:	4759                	li	a4,22
    80002d30:	02f76863          	bltu	a4,a5,80002d60 <syscall+0x50>
    80002d34:	00369713          	sll	a4,a3,0x3
    80002d38:	00005797          	auipc	a5,0x5
    80002d3c:	71878793          	add	a5,a5,1816 # 80008450 <syscalls>
    80002d40:	97ba                	add	a5,a5,a4
    80002d42:	6390                	ld	a2,0(a5)
    80002d44:	ce11                	beqz	a2,80002d60 <syscall+0x50>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    syscall_count[num]++;
    80002d46:	068a                	sll	a3,a3,0x2
    80002d48:	00014797          	auipc	a5,0x14
    80002d4c:	06078793          	add	a5,a5,96 # 80016da8 <syscall_count>
    80002d50:	97b6                	add	a5,a5,a3
    80002d52:	4398                	lw	a4,0(a5)
    80002d54:	2705                	addw	a4,a4,1
    80002d56:	c398                	sw	a4,0(a5)
    p->trapframe->a0 = syscalls[num]();
    80002d58:	6d24                	ld	s1,88(a0)
    80002d5a:	9602                	jalr	a2
    80002d5c:	f8a8                	sd	a0,112(s1)
    80002d5e:	a839                	j	80002d7c <syscall+0x6c>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d60:	15848613          	add	a2,s1,344
    80002d64:	588c                	lw	a1,48(s1)
    80002d66:	00005517          	auipc	a0,0x5
    80002d6a:	6b250513          	add	a0,a0,1714 # 80008418 <states.0+0x150>
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	818080e7          	jalr	-2024(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d76:	6cbc                	ld	a5,88(s1)
    80002d78:	577d                	li	a4,-1
    80002d7a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6105                	add	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <sys_exit>:
#include "syscall.h"

extern int syscall_count[];
uint64
sys_exit(void)
{
    80002d86:	1101                	add	sp,sp,-32
    80002d88:	ec06                	sd	ra,24(sp)
    80002d8a:	e822                	sd	s0,16(sp)
    80002d8c:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002d8e:	fec40593          	add	a1,s0,-20
    80002d92:	4501                	li	a0,0
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	f04080e7          	jalr	-252(ra) # 80002c98 <argint>
  exit(n);
    80002d9c:	fec42503          	lw	a0,-20(s0)
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	3f6080e7          	jalr	1014(ra) # 80002196 <exit>
  return 0; // not reached
}
    80002da8:	4501                	li	a0,0
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	add	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002db2:	1141                	add	sp,sp,-16
    80002db4:	e406                	sd	ra,8(sp)
    80002db6:	e022                	sd	s0,0(sp)
    80002db8:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	bec080e7          	jalr	-1044(ra) # 800019a6 <myproc>
}
    80002dc2:	5908                	lw	a0,48(a0)
    80002dc4:	60a2                	ld	ra,8(sp)
    80002dc6:	6402                	ld	s0,0(sp)
    80002dc8:	0141                	add	sp,sp,16
    80002dca:	8082                	ret

0000000080002dcc <sys_fork>:

uint64
sys_fork(void)
{
    80002dcc:	1141                	add	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	add	s0,sp,16
  return fork();
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	f9c080e7          	jalr	-100(ra) # 80001d70 <fork>
}
    80002ddc:	60a2                	ld	ra,8(sp)
    80002dde:	6402                	ld	s0,0(sp)
    80002de0:	0141                	add	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <sys_wait>:

uint64
sys_wait(void)
{
    80002de4:	1101                	add	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002dec:	fe840593          	add	a1,s0,-24
    80002df0:	4501                	li	a0,0
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	ec6080e7          	jalr	-314(ra) # 80002cb8 <argaddr>
  return wait(p);
    80002dfa:	fe843503          	ld	a0,-24(s0)
    80002dfe:	fffff097          	auipc	ra,0xfffff
    80002e02:	54a080e7          	jalr	1354(ra) # 80002348 <wait>
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	6105                	add	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e0e:	7179                	add	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e18:	fdc40593          	add	a1,s0,-36
    80002e1c:	4501                	li	a0,0
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	e7a080e7          	jalr	-390(ra) # 80002c98 <argint>
  addr = myproc()->sz;
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	b80080e7          	jalr	-1152(ra) # 800019a6 <myproc>
    80002e2e:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e30:	fdc42503          	lw	a0,-36(s0)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	ee0080e7          	jalr	-288(ra) # 80001d14 <growproc>
    80002e3c:	00054863          	bltz	a0,80002e4c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e40:	8526                	mv	a0,s1
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6145                	add	sp,sp,48
    80002e4a:	8082                	ret
    return -1;
    80002e4c:	54fd                	li	s1,-1
    80002e4e:	bfcd                	j	80002e40 <sys_sbrk+0x32>

0000000080002e50 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e50:	7139                	add	sp,sp,-64
    80002e52:	fc06                	sd	ra,56(sp)
    80002e54:	f822                	sd	s0,48(sp)
    80002e56:	f426                	sd	s1,40(sp)
    80002e58:	f04a                	sd	s2,32(sp)
    80002e5a:	ec4e                	sd	s3,24(sp)
    80002e5c:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e5e:	fcc40593          	add	a1,s0,-52
    80002e62:	4501                	li	a0,0
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	e34080e7          	jalr	-460(ra) # 80002c98 <argint>
  acquire(&tickslock);
    80002e6c:	00014517          	auipc	a0,0x14
    80002e70:	f2450513          	add	a0,a0,-220 # 80016d90 <tickslock>
    80002e74:	ffffe097          	auipc	ra,0xffffe
    80002e78:	d5e080e7          	jalr	-674(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002e7c:	00006917          	auipc	s2,0x6
    80002e80:	a7492903          	lw	s2,-1420(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    80002e84:	fcc42783          	lw	a5,-52(s0)
    80002e88:	cf9d                	beqz	a5,80002ec6 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e8a:	00014997          	auipc	s3,0x14
    80002e8e:	f0698993          	add	s3,s3,-250 # 80016d90 <tickslock>
    80002e92:	00006497          	auipc	s1,0x6
    80002e96:	a5e48493          	add	s1,s1,-1442 # 800088f0 <ticks>
    if (killed(myproc()))
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	b0c080e7          	jalr	-1268(ra) # 800019a6 <myproc>
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	474080e7          	jalr	1140(ra) # 80002316 <killed>
    80002eaa:	ed15                	bnez	a0,80002ee6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002eac:	85ce                	mv	a1,s3
    80002eae:	8526                	mv	a0,s1
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	1b2080e7          	jalr	434(ra) # 80002062 <sleep>
  while (ticks - ticks0 < n)
    80002eb8:	409c                	lw	a5,0(s1)
    80002eba:	412787bb          	subw	a5,a5,s2
    80002ebe:	fcc42703          	lw	a4,-52(s0)
    80002ec2:	fce7ece3          	bltu	a5,a4,80002e9a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ec6:	00014517          	auipc	a0,0x14
    80002eca:	eca50513          	add	a0,a0,-310 # 80016d90 <tickslock>
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	db8080e7          	jalr	-584(ra) # 80000c86 <release>
  return 0;
    80002ed6:	4501                	li	a0,0
}
    80002ed8:	70e2                	ld	ra,56(sp)
    80002eda:	7442                	ld	s0,48(sp)
    80002edc:	74a2                	ld	s1,40(sp)
    80002ede:	7902                	ld	s2,32(sp)
    80002ee0:	69e2                	ld	s3,24(sp)
    80002ee2:	6121                	add	sp,sp,64
    80002ee4:	8082                	ret
      release(&tickslock);
    80002ee6:	00014517          	auipc	a0,0x14
    80002eea:	eaa50513          	add	a0,a0,-342 # 80016d90 <tickslock>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	d98080e7          	jalr	-616(ra) # 80000c86 <release>
      return -1;
    80002ef6:	557d                	li	a0,-1
    80002ef8:	b7c5                	j	80002ed8 <sys_sleep+0x88>

0000000080002efa <sys_kill>:

uint64
sys_kill(void)
{
    80002efa:	1101                	add	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f02:	fec40593          	add	a1,s0,-20
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	d90080e7          	jalr	-624(ra) # 80002c98 <argint>
  return kill(pid);
    80002f10:	fec42503          	lw	a0,-20(s0)
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	364080e7          	jalr	868(ra) # 80002278 <kill>
}
    80002f1c:	60e2                	ld	ra,24(sp)
    80002f1e:	6442                	ld	s0,16(sp)
    80002f20:	6105                	add	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f24:	1101                	add	sp,sp,-32
    80002f26:	ec06                	sd	ra,24(sp)
    80002f28:	e822                	sd	s0,16(sp)
    80002f2a:	e426                	sd	s1,8(sp)
    80002f2c:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f2e:	00014517          	auipc	a0,0x14
    80002f32:	e6250513          	add	a0,a0,-414 # 80016d90 <tickslock>
    80002f36:	ffffe097          	auipc	ra,0xffffe
    80002f3a:	c9c080e7          	jalr	-868(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002f3e:	00006497          	auipc	s1,0x6
    80002f42:	9b24a483          	lw	s1,-1614(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	e4a50513          	add	a0,a0,-438 # 80016d90 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	d38080e7          	jalr	-712(ra) # 80000c86 <release>
  return xticks;
}
    80002f56:	02049513          	sll	a0,s1,0x20
    80002f5a:	9101                	srl	a0,a0,0x20
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	add	sp,sp,32
    80002f64:	8082                	ret

0000000080002f66 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002f66:	7139                	add	sp,sp,-64
    80002f68:	fc06                	sd	ra,56(sp)
    80002f6a:	f822                	sd	s0,48(sp)
    80002f6c:	f426                	sd	s1,40(sp)
    80002f6e:	f04a                	sd	s2,32(sp)
    80002f70:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002f72:	fd840593          	add	a1,s0,-40
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	d40080e7          	jalr	-704(ra) # 80002cb8 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002f80:	fd040593          	add	a1,s0,-48
    80002f84:	4505                	li	a0,1
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	d32080e7          	jalr	-718(ra) # 80002cb8 <argaddr>
  argaddr(2, &addr2);
    80002f8e:	fc840593          	add	a1,s0,-56
    80002f92:	4509                	li	a0,2
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	d24080e7          	jalr	-732(ra) # 80002cb8 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80002f9c:	fc040613          	add	a2,s0,-64
    80002fa0:	fc440593          	add	a1,s0,-60
    80002fa4:	fd843503          	ld	a0,-40(s0)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	62a080e7          	jalr	1578(ra) # 800025d2 <waitx>
    80002fb0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	9f4080e7          	jalr	-1548(ra) # 800019a6 <myproc>
    80002fba:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fbc:	4691                	li	a3,4
    80002fbe:	fc440613          	add	a2,s0,-60
    80002fc2:	fd043583          	ld	a1,-48(s0)
    80002fc6:	6928                	ld	a0,80(a0)
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	69e080e7          	jalr	1694(ra) # 80001666 <copyout>
    return -1;
    80002fd0:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fd2:	00054f63          	bltz	a0,80002ff0 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80002fd6:	4691                	li	a3,4
    80002fd8:	fc040613          	add	a2,s0,-64
    80002fdc:	fc843583          	ld	a1,-56(s0)
    80002fe0:	68a8                	ld	a0,80(s1)
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	684080e7          	jalr	1668(ra) # 80001666 <copyout>
    80002fea:	00054a63          	bltz	a0,80002ffe <sys_waitx+0x98>
    return -1;
  return ret;
    80002fee:	87ca                	mv	a5,s2
}
    80002ff0:	853e                	mv	a0,a5
    80002ff2:	70e2                	ld	ra,56(sp)
    80002ff4:	7442                	ld	s0,48(sp)
    80002ff6:	74a2                	ld	s1,40(sp)
    80002ff8:	7902                	ld	s2,32(sp)
    80002ffa:	6121                	add	sp,sp,64
    80002ffc:	8082                	ret
    return -1;
    80002ffe:	57fd                	li	a5,-1
    80003000:	bfc5                	j	80002ff0 <sys_waitx+0x8a>

0000000080003002 <sys_getSysCount>:

uint64
sys_getSysCount(void) {
    80003002:	1101                	add	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	1000                	add	s0,sp,32
    int mask;
    argint(0, &mask);  // Correct usage of argint
    8000300a:	fec40593          	add	a1,s0,-20
    8000300e:	4501                	li	a0,0
    80003010:	00000097          	auipc	ra,0x0
    80003014:	c88080e7          	jalr	-888(ra) # 80002c98 <argint>
    
    int syscall_number = -1;

    // Identify the syscall based on the mask (1 << i format)
    for (int i = 0; i < 31; i++) {
        if (mask == (1 << i)) {
    80003018:	fec42603          	lw	a2,-20(s0)
    for (int i = 0; i < 31; i++) {
    8000301c:	4781                	li	a5,0
        if (mask == (1 << i)) {
    8000301e:	4685                	li	a3,1
    for (int i = 0; i < 31; i++) {
    80003020:	45fd                	li	a1,31
        if (mask == (1 << i)) {
    80003022:	00f6973b          	sllw	a4,a3,a5
    80003026:	00c70763          	beq	a4,a2,80003034 <sys_getSysCount+0x32>
    for (int i = 0; i < 31; i++) {
    8000302a:	2785                	addw	a5,a5,1
    8000302c:	feb79be3          	bne	a5,a1,80003022 <sys_getSysCount+0x20>
            syscall_number = i;
            break;
        }
    }
    if (syscall_number == -1)
        return -1;
    80003030:	557d                	li	a0,-1
    80003032:	a819                	j	80003048 <sys_getSysCount+0x46>
    if (syscall_number == -1)
    80003034:	577d                	li	a4,-1
    80003036:	00e78d63          	beq	a5,a4,80003050 <sys_getSysCount+0x4e>

    // Count the number of times this syscall has been invoked
    int count = syscall_count[syscall_number];
    8000303a:	078a                	sll	a5,a5,0x2
    8000303c:	00014717          	auipc	a4,0x14
    80003040:	d6c70713          	add	a4,a4,-660 # 80016da8 <syscall_count>
    80003044:	97ba                	add	a5,a5,a4
    return count;
    80003046:	4388                	lw	a0,0(a5)
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	6105                	add	sp,sp,32
    8000304e:	8082                	ret
        return -1;
    80003050:	557d                	li	a0,-1
    80003052:	bfdd                	j	80003048 <sys_getSysCount+0x46>

0000000080003054 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003054:	7179                	add	sp,sp,-48
    80003056:	f406                	sd	ra,40(sp)
    80003058:	f022                	sd	s0,32(sp)
    8000305a:	ec26                	sd	s1,24(sp)
    8000305c:	e84a                	sd	s2,16(sp)
    8000305e:	e44e                	sd	s3,8(sp)
    80003060:	e052                	sd	s4,0(sp)
    80003062:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003064:	00005597          	auipc	a1,0x5
    80003068:	4ac58593          	add	a1,a1,1196 # 80008510 <syscalls+0xc0>
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	dbc50513          	add	a0,a0,-580 # 80016e28 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	ace080e7          	jalr	-1330(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000307c:	0001c797          	auipc	a5,0x1c
    80003080:	dac78793          	add	a5,a5,-596 # 8001ee28 <bcache+0x8000>
    80003084:	0001c717          	auipc	a4,0x1c
    80003088:	00c70713          	add	a4,a4,12 # 8001f090 <bcache+0x8268>
    8000308c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003090:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003094:	00014497          	auipc	s1,0x14
    80003098:	dac48493          	add	s1,s1,-596 # 80016e40 <bcache+0x18>
    b->next = bcache.head.next;
    8000309c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000309e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030a0:	00005a17          	auipc	s4,0x5
    800030a4:	478a0a13          	add	s4,s4,1144 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    800030a8:	2b893783          	ld	a5,696(s2)
    800030ac:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030ae:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030b2:	85d2                	mv	a1,s4
    800030b4:	01048513          	add	a0,s1,16
    800030b8:	00001097          	auipc	ra,0x1
    800030bc:	496080e7          	jalr	1174(ra) # 8000454e <initsleeplock>
    bcache.head.next->prev = b;
    800030c0:	2b893783          	ld	a5,696(s2)
    800030c4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030c6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ca:	45848493          	add	s1,s1,1112
    800030ce:	fd349de3          	bne	s1,s3,800030a8 <binit+0x54>
  }
}
    800030d2:	70a2                	ld	ra,40(sp)
    800030d4:	7402                	ld	s0,32(sp)
    800030d6:	64e2                	ld	s1,24(sp)
    800030d8:	6942                	ld	s2,16(sp)
    800030da:	69a2                	ld	s3,8(sp)
    800030dc:	6a02                	ld	s4,0(sp)
    800030de:	6145                	add	sp,sp,48
    800030e0:	8082                	ret

00000000800030e2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030e2:	7179                	add	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	1800                	add	s0,sp,48
    800030f0:	892a                	mv	s2,a0
    800030f2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030f4:	00014517          	auipc	a0,0x14
    800030f8:	d3450513          	add	a0,a0,-716 # 80016e28 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	ad6080e7          	jalr	-1322(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003104:	0001c497          	auipc	s1,0x1c
    80003108:	fdc4b483          	ld	s1,-36(s1) # 8001f0e0 <bcache+0x82b8>
    8000310c:	0001c797          	auipc	a5,0x1c
    80003110:	f8478793          	add	a5,a5,-124 # 8001f090 <bcache+0x8268>
    80003114:	02f48f63          	beq	s1,a5,80003152 <bread+0x70>
    80003118:	873e                	mv	a4,a5
    8000311a:	a021                	j	80003122 <bread+0x40>
    8000311c:	68a4                	ld	s1,80(s1)
    8000311e:	02e48a63          	beq	s1,a4,80003152 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003122:	449c                	lw	a5,8(s1)
    80003124:	ff279ce3          	bne	a5,s2,8000311c <bread+0x3a>
    80003128:	44dc                	lw	a5,12(s1)
    8000312a:	ff3799e3          	bne	a5,s3,8000311c <bread+0x3a>
      b->refcnt++;
    8000312e:	40bc                	lw	a5,64(s1)
    80003130:	2785                	addw	a5,a5,1
    80003132:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	cf450513          	add	a0,a0,-780 # 80016e28 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b4a080e7          	jalr	-1206(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003144:	01048513          	add	a0,s1,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	440080e7          	jalr	1088(ra) # 80004588 <acquiresleep>
      return b;
    80003150:	a8b9                	j	800031ae <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003152:	0001c497          	auipc	s1,0x1c
    80003156:	f864b483          	ld	s1,-122(s1) # 8001f0d8 <bcache+0x82b0>
    8000315a:	0001c797          	auipc	a5,0x1c
    8000315e:	f3678793          	add	a5,a5,-202 # 8001f090 <bcache+0x8268>
    80003162:	00f48863          	beq	s1,a5,80003172 <bread+0x90>
    80003166:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003168:	40bc                	lw	a5,64(s1)
    8000316a:	cf81                	beqz	a5,80003182 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000316c:	64a4                	ld	s1,72(s1)
    8000316e:	fee49de3          	bne	s1,a4,80003168 <bread+0x86>
  panic("bget: no buffers");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	3ae50513          	add	a0,a0,942 # 80008520 <syscalls+0xd0>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3c2080e7          	jalr	962(ra) # 8000053c <panic>
      b->dev = dev;
    80003182:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003186:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000318a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000318e:	4785                	li	a5,1
    80003190:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003192:	00014517          	auipc	a0,0x14
    80003196:	c9650513          	add	a0,a0,-874 # 80016e28 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	aec080e7          	jalr	-1300(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800031a2:	01048513          	add	a0,s1,16
    800031a6:	00001097          	auipc	ra,0x1
    800031aa:	3e2080e7          	jalr	994(ra) # 80004588 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031ae:	409c                	lw	a5,0(s1)
    800031b0:	cb89                	beqz	a5,800031c2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031b2:	8526                	mv	a0,s1
    800031b4:	70a2                	ld	ra,40(sp)
    800031b6:	7402                	ld	s0,32(sp)
    800031b8:	64e2                	ld	s1,24(sp)
    800031ba:	6942                	ld	s2,16(sp)
    800031bc:	69a2                	ld	s3,8(sp)
    800031be:	6145                	add	sp,sp,48
    800031c0:	8082                	ret
    virtio_disk_rw(b, 0);
    800031c2:	4581                	li	a1,0
    800031c4:	8526                	mv	a0,s1
    800031c6:	00003097          	auipc	ra,0x3
    800031ca:	f7c080e7          	jalr	-132(ra) # 80006142 <virtio_disk_rw>
    b->valid = 1;
    800031ce:	4785                	li	a5,1
    800031d0:	c09c                	sw	a5,0(s1)
  return b;
    800031d2:	b7c5                	j	800031b2 <bread+0xd0>

00000000800031d4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031d4:	1101                	add	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	1000                	add	s0,sp,32
    800031de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e0:	0541                	add	a0,a0,16
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	440080e7          	jalr	1088(ra) # 80004622 <holdingsleep>
    800031ea:	cd01                	beqz	a0,80003202 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031ec:	4585                	li	a1,1
    800031ee:	8526                	mv	a0,s1
    800031f0:	00003097          	auipc	ra,0x3
    800031f4:	f52080e7          	jalr	-174(ra) # 80006142 <virtio_disk_rw>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	add	sp,sp,32
    80003200:	8082                	ret
    panic("bwrite");
    80003202:	00005517          	auipc	a0,0x5
    80003206:	33650513          	add	a0,a0,822 # 80008538 <syscalls+0xe8>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	332080e7          	jalr	818(ra) # 8000053c <panic>

0000000080003212 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003212:	1101                	add	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	e426                	sd	s1,8(sp)
    8000321a:	e04a                	sd	s2,0(sp)
    8000321c:	1000                	add	s0,sp,32
    8000321e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003220:	01050913          	add	s2,a0,16
    80003224:	854a                	mv	a0,s2
    80003226:	00001097          	auipc	ra,0x1
    8000322a:	3fc080e7          	jalr	1020(ra) # 80004622 <holdingsleep>
    8000322e:	c925                	beqz	a0,8000329e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003230:	854a                	mv	a0,s2
    80003232:	00001097          	auipc	ra,0x1
    80003236:	3ac080e7          	jalr	940(ra) # 800045de <releasesleep>

  acquire(&bcache.lock);
    8000323a:	00014517          	auipc	a0,0x14
    8000323e:	bee50513          	add	a0,a0,-1042 # 80016e28 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	990080e7          	jalr	-1648(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000324a:	40bc                	lw	a5,64(s1)
    8000324c:	37fd                	addw	a5,a5,-1
    8000324e:	0007871b          	sext.w	a4,a5
    80003252:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003254:	e71d                	bnez	a4,80003282 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003256:	68b8                	ld	a4,80(s1)
    80003258:	64bc                	ld	a5,72(s1)
    8000325a:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000325c:	68b8                	ld	a4,80(s1)
    8000325e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003260:	0001c797          	auipc	a5,0x1c
    80003264:	bc878793          	add	a5,a5,-1080 # 8001ee28 <bcache+0x8000>
    80003268:	2b87b703          	ld	a4,696(a5)
    8000326c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000326e:	0001c717          	auipc	a4,0x1c
    80003272:	e2270713          	add	a4,a4,-478 # 8001f090 <bcache+0x8268>
    80003276:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003278:	2b87b703          	ld	a4,696(a5)
    8000327c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000327e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	ba650513          	add	a0,a0,-1114 # 80016e28 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6902                	ld	s2,0(sp)
    8000329a:	6105                	add	sp,sp,32
    8000329c:	8082                	ret
    panic("brelse");
    8000329e:	00005517          	auipc	a0,0x5
    800032a2:	2a250513          	add	a0,a0,674 # 80008540 <syscalls+0xf0>
    800032a6:	ffffd097          	auipc	ra,0xffffd
    800032aa:	296080e7          	jalr	662(ra) # 8000053c <panic>

00000000800032ae <bpin>:

void
bpin(struct buf *b) {
    800032ae:	1101                	add	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	e426                	sd	s1,8(sp)
    800032b6:	1000                	add	s0,sp,32
    800032b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ba:	00014517          	auipc	a0,0x14
    800032be:	b6e50513          	add	a0,a0,-1170 # 80016e28 <bcache>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	910080e7          	jalr	-1776(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800032ca:	40bc                	lw	a5,64(s1)
    800032cc:	2785                	addw	a5,a5,1
    800032ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d0:	00014517          	auipc	a0,0x14
    800032d4:	b5850513          	add	a0,a0,-1192 # 80016e28 <bcache>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	9ae080e7          	jalr	-1618(ra) # 80000c86 <release>
}
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6105                	add	sp,sp,32
    800032e8:	8082                	ret

00000000800032ea <bunpin>:

void
bunpin(struct buf *b) {
    800032ea:	1101                	add	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	1000                	add	s0,sp,32
    800032f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f6:	00014517          	auipc	a0,0x14
    800032fa:	b3250513          	add	a0,a0,-1230 # 80016e28 <bcache>
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	8d4080e7          	jalr	-1836(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003306:	40bc                	lw	a5,64(s1)
    80003308:	37fd                	addw	a5,a5,-1
    8000330a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000330c:	00014517          	auipc	a0,0x14
    80003310:	b1c50513          	add	a0,a0,-1252 # 80016e28 <bcache>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	972080e7          	jalr	-1678(ra) # 80000c86 <release>
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6105                	add	sp,sp,32
    80003324:	8082                	ret

0000000080003326 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003326:	1101                	add	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	e426                	sd	s1,8(sp)
    8000332e:	e04a                	sd	s2,0(sp)
    80003330:	1000                	add	s0,sp,32
    80003332:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003334:	00d5d59b          	srlw	a1,a1,0xd
    80003338:	0001c797          	auipc	a5,0x1c
    8000333c:	1cc7a783          	lw	a5,460(a5) # 8001f504 <sb+0x1c>
    80003340:	9dbd                	addw	a1,a1,a5
    80003342:	00000097          	auipc	ra,0x0
    80003346:	da0080e7          	jalr	-608(ra) # 800030e2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000334a:	0074f713          	and	a4,s1,7
    8000334e:	4785                	li	a5,1
    80003350:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003354:	14ce                	sll	s1,s1,0x33
    80003356:	90d9                	srl	s1,s1,0x36
    80003358:	00950733          	add	a4,a0,s1
    8000335c:	05874703          	lbu	a4,88(a4)
    80003360:	00e7f6b3          	and	a3,a5,a4
    80003364:	c69d                	beqz	a3,80003392 <bfree+0x6c>
    80003366:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003368:	94aa                	add	s1,s1,a0
    8000336a:	fff7c793          	not	a5,a5
    8000336e:	8f7d                	and	a4,a4,a5
    80003370:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003374:	00001097          	auipc	ra,0x1
    80003378:	0f6080e7          	jalr	246(ra) # 8000446a <log_write>
  brelse(bp);
    8000337c:	854a                	mv	a0,s2
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	e94080e7          	jalr	-364(ra) # 80003212 <brelse>
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6902                	ld	s2,0(sp)
    8000338e:	6105                	add	sp,sp,32
    80003390:	8082                	ret
    panic("freeing free block");
    80003392:	00005517          	auipc	a0,0x5
    80003396:	1b650513          	add	a0,a0,438 # 80008548 <syscalls+0xf8>
    8000339a:	ffffd097          	auipc	ra,0xffffd
    8000339e:	1a2080e7          	jalr	418(ra) # 8000053c <panic>

00000000800033a2 <balloc>:
{
    800033a2:	711d                	add	sp,sp,-96
    800033a4:	ec86                	sd	ra,88(sp)
    800033a6:	e8a2                	sd	s0,80(sp)
    800033a8:	e4a6                	sd	s1,72(sp)
    800033aa:	e0ca                	sd	s2,64(sp)
    800033ac:	fc4e                	sd	s3,56(sp)
    800033ae:	f852                	sd	s4,48(sp)
    800033b0:	f456                	sd	s5,40(sp)
    800033b2:	f05a                	sd	s6,32(sp)
    800033b4:	ec5e                	sd	s7,24(sp)
    800033b6:	e862                	sd	s8,16(sp)
    800033b8:	e466                	sd	s9,8(sp)
    800033ba:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033bc:	0001c797          	auipc	a5,0x1c
    800033c0:	1307a783          	lw	a5,304(a5) # 8001f4ec <sb+0x4>
    800033c4:	cff5                	beqz	a5,800034c0 <balloc+0x11e>
    800033c6:	8baa                	mv	s7,a0
    800033c8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033ca:	0001cb17          	auipc	s6,0x1c
    800033ce:	11eb0b13          	add	s6,s6,286 # 8001f4e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033d4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033d8:	6c89                	lui	s9,0x2
    800033da:	a061                	j	80003462 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033dc:	97ca                	add	a5,a5,s2
    800033de:	8e55                	or	a2,a2,a3
    800033e0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033e4:	854a                	mv	a0,s2
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	084080e7          	jalr	132(ra) # 8000446a <log_write>
        brelse(bp);
    800033ee:	854a                	mv	a0,s2
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e22080e7          	jalr	-478(ra) # 80003212 <brelse>
  bp = bread(dev, bno);
    800033f8:	85a6                	mv	a1,s1
    800033fa:	855e                	mv	a0,s7
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	ce6080e7          	jalr	-794(ra) # 800030e2 <bread>
    80003404:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003406:	40000613          	li	a2,1024
    8000340a:	4581                	li	a1,0
    8000340c:	05850513          	add	a0,a0,88
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	8be080e7          	jalr	-1858(ra) # 80000cce <memset>
  log_write(bp);
    80003418:	854a                	mv	a0,s2
    8000341a:	00001097          	auipc	ra,0x1
    8000341e:	050080e7          	jalr	80(ra) # 8000446a <log_write>
  brelse(bp);
    80003422:	854a                	mv	a0,s2
    80003424:	00000097          	auipc	ra,0x0
    80003428:	dee080e7          	jalr	-530(ra) # 80003212 <brelse>
}
    8000342c:	8526                	mv	a0,s1
    8000342e:	60e6                	ld	ra,88(sp)
    80003430:	6446                	ld	s0,80(sp)
    80003432:	64a6                	ld	s1,72(sp)
    80003434:	6906                	ld	s2,64(sp)
    80003436:	79e2                	ld	s3,56(sp)
    80003438:	7a42                	ld	s4,48(sp)
    8000343a:	7aa2                	ld	s5,40(sp)
    8000343c:	7b02                	ld	s6,32(sp)
    8000343e:	6be2                	ld	s7,24(sp)
    80003440:	6c42                	ld	s8,16(sp)
    80003442:	6ca2                	ld	s9,8(sp)
    80003444:	6125                	add	sp,sp,96
    80003446:	8082                	ret
    brelse(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	dc8080e7          	jalr	-568(ra) # 80003212 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003452:	015c87bb          	addw	a5,s9,s5
    80003456:	00078a9b          	sext.w	s5,a5
    8000345a:	004b2703          	lw	a4,4(s6)
    8000345e:	06eaf163          	bgeu	s5,a4,800034c0 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003462:	41fad79b          	sraw	a5,s5,0x1f
    80003466:	0137d79b          	srlw	a5,a5,0x13
    8000346a:	015787bb          	addw	a5,a5,s5
    8000346e:	40d7d79b          	sraw	a5,a5,0xd
    80003472:	01cb2583          	lw	a1,28(s6)
    80003476:	9dbd                	addw	a1,a1,a5
    80003478:	855e                	mv	a0,s7
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	c68080e7          	jalr	-920(ra) # 800030e2 <bread>
    80003482:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003484:	004b2503          	lw	a0,4(s6)
    80003488:	000a849b          	sext.w	s1,s5
    8000348c:	8762                	mv	a4,s8
    8000348e:	faa4fde3          	bgeu	s1,a0,80003448 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003492:	00777693          	and	a3,a4,7
    80003496:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000349a:	41f7579b          	sraw	a5,a4,0x1f
    8000349e:	01d7d79b          	srlw	a5,a5,0x1d
    800034a2:	9fb9                	addw	a5,a5,a4
    800034a4:	4037d79b          	sraw	a5,a5,0x3
    800034a8:	00f90633          	add	a2,s2,a5
    800034ac:	05864603          	lbu	a2,88(a2)
    800034b0:	00c6f5b3          	and	a1,a3,a2
    800034b4:	d585                	beqz	a1,800033dc <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b6:	2705                	addw	a4,a4,1
    800034b8:	2485                	addw	s1,s1,1
    800034ba:	fd471ae3          	bne	a4,s4,8000348e <balloc+0xec>
    800034be:	b769                	j	80003448 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800034c0:	00005517          	auipc	a0,0x5
    800034c4:	0a050513          	add	a0,a0,160 # 80008560 <syscalls+0x110>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	0be080e7          	jalr	190(ra) # 80000586 <printf>
  return 0;
    800034d0:	4481                	li	s1,0
    800034d2:	bfa9                	j	8000342c <balloc+0x8a>

00000000800034d4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d4:	7179                	add	sp,sp,-48
    800034d6:	f406                	sd	ra,40(sp)
    800034d8:	f022                	sd	s0,32(sp)
    800034da:	ec26                	sd	s1,24(sp)
    800034dc:	e84a                	sd	s2,16(sp)
    800034de:	e44e                	sd	s3,8(sp)
    800034e0:	e052                	sd	s4,0(sp)
    800034e2:	1800                	add	s0,sp,48
    800034e4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e6:	47ad                	li	a5,11
    800034e8:	02b7e863          	bltu	a5,a1,80003518 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800034ec:	02059793          	sll	a5,a1,0x20
    800034f0:	01e7d593          	srl	a1,a5,0x1e
    800034f4:	00b504b3          	add	s1,a0,a1
    800034f8:	0504a903          	lw	s2,80(s1)
    800034fc:	06091e63          	bnez	s2,80003578 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003500:	4108                	lw	a0,0(a0)
    80003502:	00000097          	auipc	ra,0x0
    80003506:	ea0080e7          	jalr	-352(ra) # 800033a2 <balloc>
    8000350a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000350e:	06090563          	beqz	s2,80003578 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003512:	0524a823          	sw	s2,80(s1)
    80003516:	a08d                	j	80003578 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003518:	ff45849b          	addw	s1,a1,-12
    8000351c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003520:	0ff00793          	li	a5,255
    80003524:	08e7e563          	bltu	a5,a4,800035ae <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003528:	08052903          	lw	s2,128(a0)
    8000352c:	00091d63          	bnez	s2,80003546 <bmap+0x72>
      addr = balloc(ip->dev);
    80003530:	4108                	lw	a0,0(a0)
    80003532:	00000097          	auipc	ra,0x0
    80003536:	e70080e7          	jalr	-400(ra) # 800033a2 <balloc>
    8000353a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000353e:	02090d63          	beqz	s2,80003578 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003542:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003546:	85ca                	mv	a1,s2
    80003548:	0009a503          	lw	a0,0(s3)
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	b96080e7          	jalr	-1130(ra) # 800030e2 <bread>
    80003554:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003556:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    8000355a:	02049713          	sll	a4,s1,0x20
    8000355e:	01e75593          	srl	a1,a4,0x1e
    80003562:	00b784b3          	add	s1,a5,a1
    80003566:	0004a903          	lw	s2,0(s1)
    8000356a:	02090063          	beqz	s2,8000358a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000356e:	8552                	mv	a0,s4
    80003570:	00000097          	auipc	ra,0x0
    80003574:	ca2080e7          	jalr	-862(ra) # 80003212 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003578:	854a                	mv	a0,s2
    8000357a:	70a2                	ld	ra,40(sp)
    8000357c:	7402                	ld	s0,32(sp)
    8000357e:	64e2                	ld	s1,24(sp)
    80003580:	6942                	ld	s2,16(sp)
    80003582:	69a2                	ld	s3,8(sp)
    80003584:	6a02                	ld	s4,0(sp)
    80003586:	6145                	add	sp,sp,48
    80003588:	8082                	ret
      addr = balloc(ip->dev);
    8000358a:	0009a503          	lw	a0,0(s3)
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	e14080e7          	jalr	-492(ra) # 800033a2 <balloc>
    80003596:	0005091b          	sext.w	s2,a0
      if(addr){
    8000359a:	fc090ae3          	beqz	s2,8000356e <bmap+0x9a>
        a[bn] = addr;
    8000359e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035a2:	8552                	mv	a0,s4
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	ec6080e7          	jalr	-314(ra) # 8000446a <log_write>
    800035ac:	b7c9                	j	8000356e <bmap+0x9a>
  panic("bmap: out of range");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	fca50513          	add	a0,a0,-54 # 80008578 <syscalls+0x128>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f86080e7          	jalr	-122(ra) # 8000053c <panic>

00000000800035be <iget>:
{
    800035be:	7179                	add	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	e052                	sd	s4,0(sp)
    800035cc:	1800                	add	s0,sp,48
    800035ce:	89aa                	mv	s3,a0
    800035d0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035d2:	0001c517          	auipc	a0,0x1c
    800035d6:	f3650513          	add	a0,a0,-202 # 8001f508 <itable>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	5f8080e7          	jalr	1528(ra) # 80000bd2 <acquire>
  empty = 0;
    800035e2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e4:	0001c497          	auipc	s1,0x1c
    800035e8:	f3c48493          	add	s1,s1,-196 # 8001f520 <itable+0x18>
    800035ec:	0001e697          	auipc	a3,0x1e
    800035f0:	9c468693          	add	a3,a3,-1596 # 80020fb0 <log>
    800035f4:	a039                	j	80003602 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035f6:	02090b63          	beqz	s2,8000362c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035fa:	08848493          	add	s1,s1,136
    800035fe:	02d48a63          	beq	s1,a3,80003632 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003602:	449c                	lw	a5,8(s1)
    80003604:	fef059e3          	blez	a5,800035f6 <iget+0x38>
    80003608:	4098                	lw	a4,0(s1)
    8000360a:	ff3716e3          	bne	a4,s3,800035f6 <iget+0x38>
    8000360e:	40d8                	lw	a4,4(s1)
    80003610:	ff4713e3          	bne	a4,s4,800035f6 <iget+0x38>
      ip->ref++;
    80003614:	2785                	addw	a5,a5,1
    80003616:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003618:	0001c517          	auipc	a0,0x1c
    8000361c:	ef050513          	add	a0,a0,-272 # 8001f508 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	666080e7          	jalr	1638(ra) # 80000c86 <release>
      return ip;
    80003628:	8926                	mv	s2,s1
    8000362a:	a03d                	j	80003658 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000362c:	f7f9                	bnez	a5,800035fa <iget+0x3c>
    8000362e:	8926                	mv	s2,s1
    80003630:	b7e9                	j	800035fa <iget+0x3c>
  if(empty == 0)
    80003632:	02090c63          	beqz	s2,8000366a <iget+0xac>
  ip->dev = dev;
    80003636:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000363a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000363e:	4785                	li	a5,1
    80003640:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003644:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003648:	0001c517          	auipc	a0,0x1c
    8000364c:	ec050513          	add	a0,a0,-320 # 8001f508 <itable>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	636080e7          	jalr	1590(ra) # 80000c86 <release>
}
    80003658:	854a                	mv	a0,s2
    8000365a:	70a2                	ld	ra,40(sp)
    8000365c:	7402                	ld	s0,32(sp)
    8000365e:	64e2                	ld	s1,24(sp)
    80003660:	6942                	ld	s2,16(sp)
    80003662:	69a2                	ld	s3,8(sp)
    80003664:	6a02                	ld	s4,0(sp)
    80003666:	6145                	add	sp,sp,48
    80003668:	8082                	ret
    panic("iget: no inodes");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	f2650513          	add	a0,a0,-218 # 80008590 <syscalls+0x140>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	eca080e7          	jalr	-310(ra) # 8000053c <panic>

000000008000367a <fsinit>:
fsinit(int dev) {
    8000367a:	7179                	add	sp,sp,-48
    8000367c:	f406                	sd	ra,40(sp)
    8000367e:	f022                	sd	s0,32(sp)
    80003680:	ec26                	sd	s1,24(sp)
    80003682:	e84a                	sd	s2,16(sp)
    80003684:	e44e                	sd	s3,8(sp)
    80003686:	1800                	add	s0,sp,48
    80003688:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000368a:	4585                	li	a1,1
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	a56080e7          	jalr	-1450(ra) # 800030e2 <bread>
    80003694:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003696:	0001c997          	auipc	s3,0x1c
    8000369a:	e5298993          	add	s3,s3,-430 # 8001f4e8 <sb>
    8000369e:	02000613          	li	a2,32
    800036a2:	05850593          	add	a1,a0,88
    800036a6:	854e                	mv	a0,s3
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	682080e7          	jalr	1666(ra) # 80000d2a <memmove>
  brelse(bp);
    800036b0:	8526                	mv	a0,s1
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	b60080e7          	jalr	-1184(ra) # 80003212 <brelse>
  if(sb.magic != FSMAGIC)
    800036ba:	0009a703          	lw	a4,0(s3)
    800036be:	102037b7          	lui	a5,0x10203
    800036c2:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036c6:	02f71263          	bne	a4,a5,800036ea <fsinit+0x70>
  initlog(dev, &sb);
    800036ca:	0001c597          	auipc	a1,0x1c
    800036ce:	e1e58593          	add	a1,a1,-482 # 8001f4e8 <sb>
    800036d2:	854a                	mv	a0,s2
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	b2c080e7          	jalr	-1236(ra) # 80004200 <initlog>
}
    800036dc:	70a2                	ld	ra,40(sp)
    800036de:	7402                	ld	s0,32(sp)
    800036e0:	64e2                	ld	s1,24(sp)
    800036e2:	6942                	ld	s2,16(sp)
    800036e4:	69a2                	ld	s3,8(sp)
    800036e6:	6145                	add	sp,sp,48
    800036e8:	8082                	ret
    panic("invalid file system");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	eb650513          	add	a0,a0,-330 # 800085a0 <syscalls+0x150>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4a080e7          	jalr	-438(ra) # 8000053c <panic>

00000000800036fa <iinit>:
{
    800036fa:	7179                	add	sp,sp,-48
    800036fc:	f406                	sd	ra,40(sp)
    800036fe:	f022                	sd	s0,32(sp)
    80003700:	ec26                	sd	s1,24(sp)
    80003702:	e84a                	sd	s2,16(sp)
    80003704:	e44e                	sd	s3,8(sp)
    80003706:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003708:	00005597          	auipc	a1,0x5
    8000370c:	eb058593          	add	a1,a1,-336 # 800085b8 <syscalls+0x168>
    80003710:	0001c517          	auipc	a0,0x1c
    80003714:	df850513          	add	a0,a0,-520 # 8001f508 <itable>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	42a080e7          	jalr	1066(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003720:	0001c497          	auipc	s1,0x1c
    80003724:	e1048493          	add	s1,s1,-496 # 8001f530 <itable+0x28>
    80003728:	0001e997          	auipc	s3,0x1e
    8000372c:	89898993          	add	s3,s3,-1896 # 80020fc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003730:	00005917          	auipc	s2,0x5
    80003734:	e9090913          	add	s2,s2,-368 # 800085c0 <syscalls+0x170>
    80003738:	85ca                	mv	a1,s2
    8000373a:	8526                	mv	a0,s1
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	e12080e7          	jalr	-494(ra) # 8000454e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003744:	08848493          	add	s1,s1,136
    80003748:	ff3498e3          	bne	s1,s3,80003738 <iinit+0x3e>
}
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6145                	add	sp,sp,48
    80003758:	8082                	ret

000000008000375a <ialloc>:
{
    8000375a:	7139                	add	sp,sp,-64
    8000375c:	fc06                	sd	ra,56(sp)
    8000375e:	f822                	sd	s0,48(sp)
    80003760:	f426                	sd	s1,40(sp)
    80003762:	f04a                	sd	s2,32(sp)
    80003764:	ec4e                	sd	s3,24(sp)
    80003766:	e852                	sd	s4,16(sp)
    80003768:	e456                	sd	s5,8(sp)
    8000376a:	e05a                	sd	s6,0(sp)
    8000376c:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000376e:	0001c717          	auipc	a4,0x1c
    80003772:	d8672703          	lw	a4,-634(a4) # 8001f4f4 <sb+0xc>
    80003776:	4785                	li	a5,1
    80003778:	04e7f863          	bgeu	a5,a4,800037c8 <ialloc+0x6e>
    8000377c:	8aaa                	mv	s5,a0
    8000377e:	8b2e                	mv	s6,a1
    80003780:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003782:	0001ca17          	auipc	s4,0x1c
    80003786:	d66a0a13          	add	s4,s4,-666 # 8001f4e8 <sb>
    8000378a:	00495593          	srl	a1,s2,0x4
    8000378e:	018a2783          	lw	a5,24(s4)
    80003792:	9dbd                	addw	a1,a1,a5
    80003794:	8556                	mv	a0,s5
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	94c080e7          	jalr	-1716(ra) # 800030e2 <bread>
    8000379e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037a0:	05850993          	add	s3,a0,88
    800037a4:	00f97793          	and	a5,s2,15
    800037a8:	079a                	sll	a5,a5,0x6
    800037aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ac:	00099783          	lh	a5,0(s3)
    800037b0:	cf9d                	beqz	a5,800037ee <ialloc+0x94>
    brelse(bp);
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	a60080e7          	jalr	-1440(ra) # 80003212 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ba:	0905                	add	s2,s2,1
    800037bc:	00ca2703          	lw	a4,12(s4)
    800037c0:	0009079b          	sext.w	a5,s2
    800037c4:	fce7e3e3          	bltu	a5,a4,8000378a <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800037c8:	00005517          	auipc	a0,0x5
    800037cc:	e0050513          	add	a0,a0,-512 # 800085c8 <syscalls+0x178>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	db6080e7          	jalr	-586(ra) # 80000586 <printf>
  return 0;
    800037d8:	4501                	li	a0,0
}
    800037da:	70e2                	ld	ra,56(sp)
    800037dc:	7442                	ld	s0,48(sp)
    800037de:	74a2                	ld	s1,40(sp)
    800037e0:	7902                	ld	s2,32(sp)
    800037e2:	69e2                	ld	s3,24(sp)
    800037e4:	6a42                	ld	s4,16(sp)
    800037e6:	6aa2                	ld	s5,8(sp)
    800037e8:	6b02                	ld	s6,0(sp)
    800037ea:	6121                	add	sp,sp,64
    800037ec:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037ee:	04000613          	li	a2,64
    800037f2:	4581                	li	a1,0
    800037f4:	854e                	mv	a0,s3
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	4d8080e7          	jalr	1240(ra) # 80000cce <memset>
      dip->type = type;
    800037fe:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003802:	8526                	mv	a0,s1
    80003804:	00001097          	auipc	ra,0x1
    80003808:	c66080e7          	jalr	-922(ra) # 8000446a <log_write>
      brelse(bp);
    8000380c:	8526                	mv	a0,s1
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	a04080e7          	jalr	-1532(ra) # 80003212 <brelse>
      return iget(dev, inum);
    80003816:	0009059b          	sext.w	a1,s2
    8000381a:	8556                	mv	a0,s5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	da2080e7          	jalr	-606(ra) # 800035be <iget>
    80003824:	bf5d                	j	800037da <ialloc+0x80>

0000000080003826 <iupdate>:
{
    80003826:	1101                	add	sp,sp,-32
    80003828:	ec06                	sd	ra,24(sp)
    8000382a:	e822                	sd	s0,16(sp)
    8000382c:	e426                	sd	s1,8(sp)
    8000382e:	e04a                	sd	s2,0(sp)
    80003830:	1000                	add	s0,sp,32
    80003832:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003834:	415c                	lw	a5,4(a0)
    80003836:	0047d79b          	srlw	a5,a5,0x4
    8000383a:	0001c597          	auipc	a1,0x1c
    8000383e:	cc65a583          	lw	a1,-826(a1) # 8001f500 <sb+0x18>
    80003842:	9dbd                	addw	a1,a1,a5
    80003844:	4108                	lw	a0,0(a0)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	89c080e7          	jalr	-1892(ra) # 800030e2 <bread>
    8000384e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003850:	05850793          	add	a5,a0,88
    80003854:	40d8                	lw	a4,4(s1)
    80003856:	8b3d                	and	a4,a4,15
    80003858:	071a                	sll	a4,a4,0x6
    8000385a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000385c:	04449703          	lh	a4,68(s1)
    80003860:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003864:	04649703          	lh	a4,70(s1)
    80003868:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000386c:	04849703          	lh	a4,72(s1)
    80003870:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003874:	04a49703          	lh	a4,74(s1)
    80003878:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000387c:	44f8                	lw	a4,76(s1)
    8000387e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003880:	03400613          	li	a2,52
    80003884:	05048593          	add	a1,s1,80
    80003888:	00c78513          	add	a0,a5,12
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	49e080e7          	jalr	1182(ra) # 80000d2a <memmove>
  log_write(bp);
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	bd4080e7          	jalr	-1068(ra) # 8000446a <log_write>
  brelse(bp);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	972080e7          	jalr	-1678(ra) # 80003212 <brelse>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	add	sp,sp,32
    800038b2:	8082                	ret

00000000800038b4 <idup>:
{
    800038b4:	1101                	add	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	1000                	add	s0,sp,32
    800038be:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038c0:	0001c517          	auipc	a0,0x1c
    800038c4:	c4850513          	add	a0,a0,-952 # 8001f508 <itable>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	30a080e7          	jalr	778(ra) # 80000bd2 <acquire>
  ip->ref++;
    800038d0:	449c                	lw	a5,8(s1)
    800038d2:	2785                	addw	a5,a5,1
    800038d4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038d6:	0001c517          	auipc	a0,0x1c
    800038da:	c3250513          	add	a0,a0,-974 # 8001f508 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3a8080e7          	jalr	936(ra) # 80000c86 <release>
}
    800038e6:	8526                	mv	a0,s1
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	64a2                	ld	s1,8(sp)
    800038ee:	6105                	add	sp,sp,32
    800038f0:	8082                	ret

00000000800038f2 <ilock>:
{
    800038f2:	1101                	add	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038fe:	c115                	beqz	a0,80003922 <ilock+0x30>
    80003900:	84aa                	mv	s1,a0
    80003902:	451c                	lw	a5,8(a0)
    80003904:	00f05f63          	blez	a5,80003922 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003908:	0541                	add	a0,a0,16
    8000390a:	00001097          	auipc	ra,0x1
    8000390e:	c7e080e7          	jalr	-898(ra) # 80004588 <acquiresleep>
  if(ip->valid == 0){
    80003912:	40bc                	lw	a5,64(s1)
    80003914:	cf99                	beqz	a5,80003932 <ilock+0x40>
}
    80003916:	60e2                	ld	ra,24(sp)
    80003918:	6442                	ld	s0,16(sp)
    8000391a:	64a2                	ld	s1,8(sp)
    8000391c:	6902                	ld	s2,0(sp)
    8000391e:	6105                	add	sp,sp,32
    80003920:	8082                	ret
    panic("ilock");
    80003922:	00005517          	auipc	a0,0x5
    80003926:	cbe50513          	add	a0,a0,-834 # 800085e0 <syscalls+0x190>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	c12080e7          	jalr	-1006(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003932:	40dc                	lw	a5,4(s1)
    80003934:	0047d79b          	srlw	a5,a5,0x4
    80003938:	0001c597          	auipc	a1,0x1c
    8000393c:	bc85a583          	lw	a1,-1080(a1) # 8001f500 <sb+0x18>
    80003940:	9dbd                	addw	a1,a1,a5
    80003942:	4088                	lw	a0,0(s1)
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	79e080e7          	jalr	1950(ra) # 800030e2 <bread>
    8000394c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000394e:	05850593          	add	a1,a0,88
    80003952:	40dc                	lw	a5,4(s1)
    80003954:	8bbd                	and	a5,a5,15
    80003956:	079a                	sll	a5,a5,0x6
    80003958:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000395a:	00059783          	lh	a5,0(a1)
    8000395e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003962:	00259783          	lh	a5,2(a1)
    80003966:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000396a:	00459783          	lh	a5,4(a1)
    8000396e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003972:	00659783          	lh	a5,6(a1)
    80003976:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000397a:	459c                	lw	a5,8(a1)
    8000397c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000397e:	03400613          	li	a2,52
    80003982:	05b1                	add	a1,a1,12
    80003984:	05048513          	add	a0,s1,80
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	3a2080e7          	jalr	930(ra) # 80000d2a <memmove>
    brelse(bp);
    80003990:	854a                	mv	a0,s2
    80003992:	00000097          	auipc	ra,0x0
    80003996:	880080e7          	jalr	-1920(ra) # 80003212 <brelse>
    ip->valid = 1;
    8000399a:	4785                	li	a5,1
    8000399c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000399e:	04449783          	lh	a5,68(s1)
    800039a2:	fbb5                	bnez	a5,80003916 <ilock+0x24>
      panic("ilock: no type");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	c4450513          	add	a0,a0,-956 # 800085e8 <syscalls+0x198>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	b90080e7          	jalr	-1136(ra) # 8000053c <panic>

00000000800039b4 <iunlock>:
{
    800039b4:	1101                	add	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	e04a                	sd	s2,0(sp)
    800039be:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039c0:	c905                	beqz	a0,800039f0 <iunlock+0x3c>
    800039c2:	84aa                	mv	s1,a0
    800039c4:	01050913          	add	s2,a0,16
    800039c8:	854a                	mv	a0,s2
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	c58080e7          	jalr	-936(ra) # 80004622 <holdingsleep>
    800039d2:	cd19                	beqz	a0,800039f0 <iunlock+0x3c>
    800039d4:	449c                	lw	a5,8(s1)
    800039d6:	00f05d63          	blez	a5,800039f0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	c02080e7          	jalr	-1022(ra) # 800045de <releasesleep>
}
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	64a2                	ld	s1,8(sp)
    800039ea:	6902                	ld	s2,0(sp)
    800039ec:	6105                	add	sp,sp,32
    800039ee:	8082                	ret
    panic("iunlock");
    800039f0:	00005517          	auipc	a0,0x5
    800039f4:	c0850513          	add	a0,a0,-1016 # 800085f8 <syscalls+0x1a8>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	b44080e7          	jalr	-1212(ra) # 8000053c <panic>

0000000080003a00 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a00:	7179                	add	sp,sp,-48
    80003a02:	f406                	sd	ra,40(sp)
    80003a04:	f022                	sd	s0,32(sp)
    80003a06:	ec26                	sd	s1,24(sp)
    80003a08:	e84a                	sd	s2,16(sp)
    80003a0a:	e44e                	sd	s3,8(sp)
    80003a0c:	e052                	sd	s4,0(sp)
    80003a0e:	1800                	add	s0,sp,48
    80003a10:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a12:	05050493          	add	s1,a0,80
    80003a16:	08050913          	add	s2,a0,128
    80003a1a:	a021                	j	80003a22 <itrunc+0x22>
    80003a1c:	0491                	add	s1,s1,4
    80003a1e:	01248d63          	beq	s1,s2,80003a38 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a22:	408c                	lw	a1,0(s1)
    80003a24:	dde5                	beqz	a1,80003a1c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	8fc080e7          	jalr	-1796(ra) # 80003326 <bfree>
      ip->addrs[i] = 0;
    80003a32:	0004a023          	sw	zero,0(s1)
    80003a36:	b7dd                	j	80003a1c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a38:	0809a583          	lw	a1,128(s3)
    80003a3c:	e185                	bnez	a1,80003a5c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a3e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a42:	854e                	mv	a0,s3
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	de2080e7          	jalr	-542(ra) # 80003826 <iupdate>
}
    80003a4c:	70a2                	ld	ra,40(sp)
    80003a4e:	7402                	ld	s0,32(sp)
    80003a50:	64e2                	ld	s1,24(sp)
    80003a52:	6942                	ld	s2,16(sp)
    80003a54:	69a2                	ld	s3,8(sp)
    80003a56:	6a02                	ld	s4,0(sp)
    80003a58:	6145                	add	sp,sp,48
    80003a5a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a5c:	0009a503          	lw	a0,0(s3)
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	682080e7          	jalr	1666(ra) # 800030e2 <bread>
    80003a68:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a6a:	05850493          	add	s1,a0,88
    80003a6e:	45850913          	add	s2,a0,1112
    80003a72:	a021                	j	80003a7a <itrunc+0x7a>
    80003a74:	0491                	add	s1,s1,4
    80003a76:	01248b63          	beq	s1,s2,80003a8c <itrunc+0x8c>
      if(a[j])
    80003a7a:	408c                	lw	a1,0(s1)
    80003a7c:	dde5                	beqz	a1,80003a74 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a7e:	0009a503          	lw	a0,0(s3)
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	8a4080e7          	jalr	-1884(ra) # 80003326 <bfree>
    80003a8a:	b7ed                	j	80003a74 <itrunc+0x74>
    brelse(bp);
    80003a8c:	8552                	mv	a0,s4
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	784080e7          	jalr	1924(ra) # 80003212 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a96:	0809a583          	lw	a1,128(s3)
    80003a9a:	0009a503          	lw	a0,0(s3)
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	888080e7          	jalr	-1912(ra) # 80003326 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003aa6:	0809a023          	sw	zero,128(s3)
    80003aaa:	bf51                	j	80003a3e <itrunc+0x3e>

0000000080003aac <iput>:
{
    80003aac:	1101                	add	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	e426                	sd	s1,8(sp)
    80003ab4:	e04a                	sd	s2,0(sp)
    80003ab6:	1000                	add	s0,sp,32
    80003ab8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	a4e50513          	add	a0,a0,-1458 # 8001f508 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	110080e7          	jalr	272(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aca:	4498                	lw	a4,8(s1)
    80003acc:	4785                	li	a5,1
    80003ace:	02f70363          	beq	a4,a5,80003af4 <iput+0x48>
  ip->ref--;
    80003ad2:	449c                	lw	a5,8(s1)
    80003ad4:	37fd                	addw	a5,a5,-1
    80003ad6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad8:	0001c517          	auipc	a0,0x1c
    80003adc:	a3050513          	add	a0,a0,-1488 # 8001f508 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	1a6080e7          	jalr	422(ra) # 80000c86 <release>
}
    80003ae8:	60e2                	ld	ra,24(sp)
    80003aea:	6442                	ld	s0,16(sp)
    80003aec:	64a2                	ld	s1,8(sp)
    80003aee:	6902                	ld	s2,0(sp)
    80003af0:	6105                	add	sp,sp,32
    80003af2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003af4:	40bc                	lw	a5,64(s1)
    80003af6:	dff1                	beqz	a5,80003ad2 <iput+0x26>
    80003af8:	04a49783          	lh	a5,74(s1)
    80003afc:	fbf9                	bnez	a5,80003ad2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003afe:	01048913          	add	s2,s1,16
    80003b02:	854a                	mv	a0,s2
    80003b04:	00001097          	auipc	ra,0x1
    80003b08:	a84080e7          	jalr	-1404(ra) # 80004588 <acquiresleep>
    release(&itable.lock);
    80003b0c:	0001c517          	auipc	a0,0x1c
    80003b10:	9fc50513          	add	a0,a0,-1540 # 8001f508 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	172080e7          	jalr	370(ra) # 80000c86 <release>
    itrunc(ip);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	ee2080e7          	jalr	-286(ra) # 80003a00 <itrunc>
    ip->type = 0;
    80003b26:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	cfa080e7          	jalr	-774(ra) # 80003826 <iupdate>
    ip->valid = 0;
    80003b34:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	00001097          	auipc	ra,0x1
    80003b3e:	aa4080e7          	jalr	-1372(ra) # 800045de <releasesleep>
    acquire(&itable.lock);
    80003b42:	0001c517          	auipc	a0,0x1c
    80003b46:	9c650513          	add	a0,a0,-1594 # 8001f508 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	088080e7          	jalr	136(ra) # 80000bd2 <acquire>
    80003b52:	b741                	j	80003ad2 <iput+0x26>

0000000080003b54 <iunlockput>:
{
    80003b54:	1101                	add	sp,sp,-32
    80003b56:	ec06                	sd	ra,24(sp)
    80003b58:	e822                	sd	s0,16(sp)
    80003b5a:	e426                	sd	s1,8(sp)
    80003b5c:	1000                	add	s0,sp,32
    80003b5e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	e54080e7          	jalr	-428(ra) # 800039b4 <iunlock>
  iput(ip);
    80003b68:	8526                	mv	a0,s1
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	f42080e7          	jalr	-190(ra) # 80003aac <iput>
}
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	64a2                	ld	s1,8(sp)
    80003b78:	6105                	add	sp,sp,32
    80003b7a:	8082                	ret

0000000080003b7c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b7c:	1141                	add	sp,sp,-16
    80003b7e:	e422                	sd	s0,8(sp)
    80003b80:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003b82:	411c                	lw	a5,0(a0)
    80003b84:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b86:	415c                	lw	a5,4(a0)
    80003b88:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b8a:	04451783          	lh	a5,68(a0)
    80003b8e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b92:	04a51783          	lh	a5,74(a0)
    80003b96:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b9a:	04c56783          	lwu	a5,76(a0)
    80003b9e:	e99c                	sd	a5,16(a1)
}
    80003ba0:	6422                	ld	s0,8(sp)
    80003ba2:	0141                	add	sp,sp,16
    80003ba4:	8082                	ret

0000000080003ba6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba6:	457c                	lw	a5,76(a0)
    80003ba8:	0ed7e963          	bltu	a5,a3,80003c9a <readi+0xf4>
{
    80003bac:	7159                	add	sp,sp,-112
    80003bae:	f486                	sd	ra,104(sp)
    80003bb0:	f0a2                	sd	s0,96(sp)
    80003bb2:	eca6                	sd	s1,88(sp)
    80003bb4:	e8ca                	sd	s2,80(sp)
    80003bb6:	e4ce                	sd	s3,72(sp)
    80003bb8:	e0d2                	sd	s4,64(sp)
    80003bba:	fc56                	sd	s5,56(sp)
    80003bbc:	f85a                	sd	s6,48(sp)
    80003bbe:	f45e                	sd	s7,40(sp)
    80003bc0:	f062                	sd	s8,32(sp)
    80003bc2:	ec66                	sd	s9,24(sp)
    80003bc4:	e86a                	sd	s10,16(sp)
    80003bc6:	e46e                	sd	s11,8(sp)
    80003bc8:	1880                	add	s0,sp,112
    80003bca:	8b2a                	mv	s6,a0
    80003bcc:	8bae                	mv	s7,a1
    80003bce:	8a32                	mv	s4,a2
    80003bd0:	84b6                	mv	s1,a3
    80003bd2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bd4:	9f35                	addw	a4,a4,a3
    return 0;
    80003bd6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bd8:	0ad76063          	bltu	a4,a3,80003c78 <readi+0xd2>
  if(off + n > ip->size)
    80003bdc:	00e7f463          	bgeu	a5,a4,80003be4 <readi+0x3e>
    n = ip->size - off;
    80003be0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be4:	0a0a8963          	beqz	s5,80003c96 <readi+0xf0>
    80003be8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bee:	5c7d                	li	s8,-1
    80003bf0:	a82d                	j	80003c2a <readi+0x84>
    80003bf2:	020d1d93          	sll	s11,s10,0x20
    80003bf6:	020ddd93          	srl	s11,s11,0x20
    80003bfa:	05890613          	add	a2,s2,88
    80003bfe:	86ee                	mv	a3,s11
    80003c00:	963a                	add	a2,a2,a4
    80003c02:	85d2                	mv	a1,s4
    80003c04:	855e                	mv	a0,s7
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	870080e7          	jalr	-1936(ra) # 80002476 <either_copyout>
    80003c0e:	05850d63          	beq	a0,s8,80003c68 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c12:	854a                	mv	a0,s2
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	5fe080e7          	jalr	1534(ra) # 80003212 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c1c:	013d09bb          	addw	s3,s10,s3
    80003c20:	009d04bb          	addw	s1,s10,s1
    80003c24:	9a6e                	add	s4,s4,s11
    80003c26:	0559f763          	bgeu	s3,s5,80003c74 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c2a:	00a4d59b          	srlw	a1,s1,0xa
    80003c2e:	855a                	mv	a0,s6
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	8a4080e7          	jalr	-1884(ra) # 800034d4 <bmap>
    80003c38:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c3c:	cd85                	beqz	a1,80003c74 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c3e:	000b2503          	lw	a0,0(s6)
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	4a0080e7          	jalr	1184(ra) # 800030e2 <bread>
    80003c4a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c4c:	3ff4f713          	and	a4,s1,1023
    80003c50:	40ec87bb          	subw	a5,s9,a4
    80003c54:	413a86bb          	subw	a3,s5,s3
    80003c58:	8d3e                	mv	s10,a5
    80003c5a:	2781                	sext.w	a5,a5
    80003c5c:	0006861b          	sext.w	a2,a3
    80003c60:	f8f679e3          	bgeu	a2,a5,80003bf2 <readi+0x4c>
    80003c64:	8d36                	mv	s10,a3
    80003c66:	b771                	j	80003bf2 <readi+0x4c>
      brelse(bp);
    80003c68:	854a                	mv	a0,s2
    80003c6a:	fffff097          	auipc	ra,0xfffff
    80003c6e:	5a8080e7          	jalr	1448(ra) # 80003212 <brelse>
      tot = -1;
    80003c72:	59fd                	li	s3,-1
  }
  return tot;
    80003c74:	0009851b          	sext.w	a0,s3
}
    80003c78:	70a6                	ld	ra,104(sp)
    80003c7a:	7406                	ld	s0,96(sp)
    80003c7c:	64e6                	ld	s1,88(sp)
    80003c7e:	6946                	ld	s2,80(sp)
    80003c80:	69a6                	ld	s3,72(sp)
    80003c82:	6a06                	ld	s4,64(sp)
    80003c84:	7ae2                	ld	s5,56(sp)
    80003c86:	7b42                	ld	s6,48(sp)
    80003c88:	7ba2                	ld	s7,40(sp)
    80003c8a:	7c02                	ld	s8,32(sp)
    80003c8c:	6ce2                	ld	s9,24(sp)
    80003c8e:	6d42                	ld	s10,16(sp)
    80003c90:	6da2                	ld	s11,8(sp)
    80003c92:	6165                	add	sp,sp,112
    80003c94:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c96:	89d6                	mv	s3,s5
    80003c98:	bff1                	j	80003c74 <readi+0xce>
    return 0;
    80003c9a:	4501                	li	a0,0
}
    80003c9c:	8082                	ret

0000000080003c9e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	10d7e863          	bltu	a5,a3,80003db0 <writei+0x112>
{
    80003ca4:	7159                	add	sp,sp,-112
    80003ca6:	f486                	sd	ra,104(sp)
    80003ca8:	f0a2                	sd	s0,96(sp)
    80003caa:	eca6                	sd	s1,88(sp)
    80003cac:	e8ca                	sd	s2,80(sp)
    80003cae:	e4ce                	sd	s3,72(sp)
    80003cb0:	e0d2                	sd	s4,64(sp)
    80003cb2:	fc56                	sd	s5,56(sp)
    80003cb4:	f85a                	sd	s6,48(sp)
    80003cb6:	f45e                	sd	s7,40(sp)
    80003cb8:	f062                	sd	s8,32(sp)
    80003cba:	ec66                	sd	s9,24(sp)
    80003cbc:	e86a                	sd	s10,16(sp)
    80003cbe:	e46e                	sd	s11,8(sp)
    80003cc0:	1880                	add	s0,sp,112
    80003cc2:	8aaa                	mv	s5,a0
    80003cc4:	8bae                	mv	s7,a1
    80003cc6:	8a32                	mv	s4,a2
    80003cc8:	8936                	mv	s2,a3
    80003cca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ccc:	00e687bb          	addw	a5,a3,a4
    80003cd0:	0ed7e263          	bltu	a5,a3,80003db4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cd4:	00043737          	lui	a4,0x43
    80003cd8:	0ef76063          	bltu	a4,a5,80003db8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cdc:	0c0b0863          	beqz	s6,80003dac <writei+0x10e>
    80003ce0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ce6:	5c7d                	li	s8,-1
    80003ce8:	a091                	j	80003d2c <writei+0x8e>
    80003cea:	020d1d93          	sll	s11,s10,0x20
    80003cee:	020ddd93          	srl	s11,s11,0x20
    80003cf2:	05848513          	add	a0,s1,88
    80003cf6:	86ee                	mv	a3,s11
    80003cf8:	8652                	mv	a2,s4
    80003cfa:	85de                	mv	a1,s7
    80003cfc:	953a                	add	a0,a0,a4
    80003cfe:	ffffe097          	auipc	ra,0xffffe
    80003d02:	7ce080e7          	jalr	1998(ra) # 800024cc <either_copyin>
    80003d06:	07850263          	beq	a0,s8,80003d6a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d0a:	8526                	mv	a0,s1
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	75e080e7          	jalr	1886(ra) # 8000446a <log_write>
    brelse(bp);
    80003d14:	8526                	mv	a0,s1
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	4fc080e7          	jalr	1276(ra) # 80003212 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d1e:	013d09bb          	addw	s3,s10,s3
    80003d22:	012d093b          	addw	s2,s10,s2
    80003d26:	9a6e                	add	s4,s4,s11
    80003d28:	0569f663          	bgeu	s3,s6,80003d74 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d2c:	00a9559b          	srlw	a1,s2,0xa
    80003d30:	8556                	mv	a0,s5
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	7a2080e7          	jalr	1954(ra) # 800034d4 <bmap>
    80003d3a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d3e:	c99d                	beqz	a1,80003d74 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d40:	000aa503          	lw	a0,0(s5)
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	39e080e7          	jalr	926(ra) # 800030e2 <bread>
    80003d4c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4e:	3ff97713          	and	a4,s2,1023
    80003d52:	40ec87bb          	subw	a5,s9,a4
    80003d56:	413b06bb          	subw	a3,s6,s3
    80003d5a:	8d3e                	mv	s10,a5
    80003d5c:	2781                	sext.w	a5,a5
    80003d5e:	0006861b          	sext.w	a2,a3
    80003d62:	f8f674e3          	bgeu	a2,a5,80003cea <writei+0x4c>
    80003d66:	8d36                	mv	s10,a3
    80003d68:	b749                	j	80003cea <writei+0x4c>
      brelse(bp);
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	4a6080e7          	jalr	1190(ra) # 80003212 <brelse>
  }

  if(off > ip->size)
    80003d74:	04caa783          	lw	a5,76(s5)
    80003d78:	0127f463          	bgeu	a5,s2,80003d80 <writei+0xe2>
    ip->size = off;
    80003d7c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d80:	8556                	mv	a0,s5
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	aa4080e7          	jalr	-1372(ra) # 80003826 <iupdate>

  return tot;
    80003d8a:	0009851b          	sext.w	a0,s3
}
    80003d8e:	70a6                	ld	ra,104(sp)
    80003d90:	7406                	ld	s0,96(sp)
    80003d92:	64e6                	ld	s1,88(sp)
    80003d94:	6946                	ld	s2,80(sp)
    80003d96:	69a6                	ld	s3,72(sp)
    80003d98:	6a06                	ld	s4,64(sp)
    80003d9a:	7ae2                	ld	s5,56(sp)
    80003d9c:	7b42                	ld	s6,48(sp)
    80003d9e:	7ba2                	ld	s7,40(sp)
    80003da0:	7c02                	ld	s8,32(sp)
    80003da2:	6ce2                	ld	s9,24(sp)
    80003da4:	6d42                	ld	s10,16(sp)
    80003da6:	6da2                	ld	s11,8(sp)
    80003da8:	6165                	add	sp,sp,112
    80003daa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dac:	89da                	mv	s3,s6
    80003dae:	bfc9                	j	80003d80 <writei+0xe2>
    return -1;
    80003db0:	557d                	li	a0,-1
}
    80003db2:	8082                	ret
    return -1;
    80003db4:	557d                	li	a0,-1
    80003db6:	bfe1                	j	80003d8e <writei+0xf0>
    return -1;
    80003db8:	557d                	li	a0,-1
    80003dba:	bfd1                	j	80003d8e <writei+0xf0>

0000000080003dbc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dbc:	1141                	add	sp,sp,-16
    80003dbe:	e406                	sd	ra,8(sp)
    80003dc0:	e022                	sd	s0,0(sp)
    80003dc2:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dc4:	4639                	li	a2,14
    80003dc6:	ffffd097          	auipc	ra,0xffffd
    80003dca:	fd8080e7          	jalr	-40(ra) # 80000d9e <strncmp>
}
    80003dce:	60a2                	ld	ra,8(sp)
    80003dd0:	6402                	ld	s0,0(sp)
    80003dd2:	0141                	add	sp,sp,16
    80003dd4:	8082                	ret

0000000080003dd6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dd6:	7139                	add	sp,sp,-64
    80003dd8:	fc06                	sd	ra,56(sp)
    80003dda:	f822                	sd	s0,48(sp)
    80003ddc:	f426                	sd	s1,40(sp)
    80003dde:	f04a                	sd	s2,32(sp)
    80003de0:	ec4e                	sd	s3,24(sp)
    80003de2:	e852                	sd	s4,16(sp)
    80003de4:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003de6:	04451703          	lh	a4,68(a0)
    80003dea:	4785                	li	a5,1
    80003dec:	00f71a63          	bne	a4,a5,80003e00 <dirlookup+0x2a>
    80003df0:	892a                	mv	s2,a0
    80003df2:	89ae                	mv	s3,a1
    80003df4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df6:	457c                	lw	a5,76(a0)
    80003df8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dfa:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	e79d                	bnez	a5,80003e2a <dirlookup+0x54>
    80003dfe:	a8a5                	j	80003e76 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	80050513          	add	a0,a0,-2048 # 80008600 <syscalls+0x1b0>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	734080e7          	jalr	1844(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003e10:	00005517          	auipc	a0,0x5
    80003e14:	80850513          	add	a0,a0,-2040 # 80008618 <syscalls+0x1c8>
    80003e18:	ffffc097          	auipc	ra,0xffffc
    80003e1c:	724080e7          	jalr	1828(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e20:	24c1                	addw	s1,s1,16
    80003e22:	04c92783          	lw	a5,76(s2)
    80003e26:	04f4f763          	bgeu	s1,a5,80003e74 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2a:	4741                	li	a4,16
    80003e2c:	86a6                	mv	a3,s1
    80003e2e:	fc040613          	add	a2,s0,-64
    80003e32:	4581                	li	a1,0
    80003e34:	854a                	mv	a0,s2
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	d70080e7          	jalr	-656(ra) # 80003ba6 <readi>
    80003e3e:	47c1                	li	a5,16
    80003e40:	fcf518e3          	bne	a0,a5,80003e10 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e44:	fc045783          	lhu	a5,-64(s0)
    80003e48:	dfe1                	beqz	a5,80003e20 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e4a:	fc240593          	add	a1,s0,-62
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	f6c080e7          	jalr	-148(ra) # 80003dbc <namecmp>
    80003e58:	f561                	bnez	a0,80003e20 <dirlookup+0x4a>
      if(poff)
    80003e5a:	000a0463          	beqz	s4,80003e62 <dirlookup+0x8c>
        *poff = off;
    80003e5e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e62:	fc045583          	lhu	a1,-64(s0)
    80003e66:	00092503          	lw	a0,0(s2)
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	754080e7          	jalr	1876(ra) # 800035be <iget>
    80003e72:	a011                	j	80003e76 <dirlookup+0xa0>
  return 0;
    80003e74:	4501                	li	a0,0
}
    80003e76:	70e2                	ld	ra,56(sp)
    80003e78:	7442                	ld	s0,48(sp)
    80003e7a:	74a2                	ld	s1,40(sp)
    80003e7c:	7902                	ld	s2,32(sp)
    80003e7e:	69e2                	ld	s3,24(sp)
    80003e80:	6a42                	ld	s4,16(sp)
    80003e82:	6121                	add	sp,sp,64
    80003e84:	8082                	ret

0000000080003e86 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e86:	711d                	add	sp,sp,-96
    80003e88:	ec86                	sd	ra,88(sp)
    80003e8a:	e8a2                	sd	s0,80(sp)
    80003e8c:	e4a6                	sd	s1,72(sp)
    80003e8e:	e0ca                	sd	s2,64(sp)
    80003e90:	fc4e                	sd	s3,56(sp)
    80003e92:	f852                	sd	s4,48(sp)
    80003e94:	f456                	sd	s5,40(sp)
    80003e96:	f05a                	sd	s6,32(sp)
    80003e98:	ec5e                	sd	s7,24(sp)
    80003e9a:	e862                	sd	s8,16(sp)
    80003e9c:	e466                	sd	s9,8(sp)
    80003e9e:	1080                	add	s0,sp,96
    80003ea0:	84aa                	mv	s1,a0
    80003ea2:	8b2e                	mv	s6,a1
    80003ea4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ea6:	00054703          	lbu	a4,0(a0)
    80003eaa:	02f00793          	li	a5,47
    80003eae:	02f70263          	beq	a4,a5,80003ed2 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eb2:	ffffe097          	auipc	ra,0xffffe
    80003eb6:	af4080e7          	jalr	-1292(ra) # 800019a6 <myproc>
    80003eba:	15053503          	ld	a0,336(a0)
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	9f6080e7          	jalr	-1546(ra) # 800038b4 <idup>
    80003ec6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ec8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003ecc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ece:	4b85                	li	s7,1
    80003ed0:	a875                	j	80003f8c <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003ed2:	4585                	li	a1,1
    80003ed4:	4505                	li	a0,1
    80003ed6:	fffff097          	auipc	ra,0xfffff
    80003eda:	6e8080e7          	jalr	1768(ra) # 800035be <iget>
    80003ede:	8a2a                	mv	s4,a0
    80003ee0:	b7e5                	j	80003ec8 <namex+0x42>
      iunlockput(ip);
    80003ee2:	8552                	mv	a0,s4
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	c70080e7          	jalr	-912(ra) # 80003b54 <iunlockput>
      return 0;
    80003eec:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eee:	8552                	mv	a0,s4
    80003ef0:	60e6                	ld	ra,88(sp)
    80003ef2:	6446                	ld	s0,80(sp)
    80003ef4:	64a6                	ld	s1,72(sp)
    80003ef6:	6906                	ld	s2,64(sp)
    80003ef8:	79e2                	ld	s3,56(sp)
    80003efa:	7a42                	ld	s4,48(sp)
    80003efc:	7aa2                	ld	s5,40(sp)
    80003efe:	7b02                	ld	s6,32(sp)
    80003f00:	6be2                	ld	s7,24(sp)
    80003f02:	6c42                	ld	s8,16(sp)
    80003f04:	6ca2                	ld	s9,8(sp)
    80003f06:	6125                	add	sp,sp,96
    80003f08:	8082                	ret
      iunlock(ip);
    80003f0a:	8552                	mv	a0,s4
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	aa8080e7          	jalr	-1368(ra) # 800039b4 <iunlock>
      return ip;
    80003f14:	bfe9                	j	80003eee <namex+0x68>
      iunlockput(ip);
    80003f16:	8552                	mv	a0,s4
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	c3c080e7          	jalr	-964(ra) # 80003b54 <iunlockput>
      return 0;
    80003f20:	8a4e                	mv	s4,s3
    80003f22:	b7f1                	j	80003eee <namex+0x68>
  len = path - s;
    80003f24:	40998633          	sub	a2,s3,s1
    80003f28:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f2c:	099c5863          	bge	s8,s9,80003fbc <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003f30:	4639                	li	a2,14
    80003f32:	85a6                	mv	a1,s1
    80003f34:	8556                	mv	a0,s5
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	df4080e7          	jalr	-524(ra) # 80000d2a <memmove>
    80003f3e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	01279763          	bne	a5,s2,80003f52 <namex+0xcc>
    path++;
    80003f48:	0485                	add	s1,s1,1
  while(*path == '/')
    80003f4a:	0004c783          	lbu	a5,0(s1)
    80003f4e:	ff278de3          	beq	a5,s2,80003f48 <namex+0xc2>
    ilock(ip);
    80003f52:	8552                	mv	a0,s4
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	99e080e7          	jalr	-1634(ra) # 800038f2 <ilock>
    if(ip->type != T_DIR){
    80003f5c:	044a1783          	lh	a5,68(s4)
    80003f60:	f97791e3          	bne	a5,s7,80003ee2 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003f64:	000b0563          	beqz	s6,80003f6e <namex+0xe8>
    80003f68:	0004c783          	lbu	a5,0(s1)
    80003f6c:	dfd9                	beqz	a5,80003f0a <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f6e:	4601                	li	a2,0
    80003f70:	85d6                	mv	a1,s5
    80003f72:	8552                	mv	a0,s4
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	e62080e7          	jalr	-414(ra) # 80003dd6 <dirlookup>
    80003f7c:	89aa                	mv	s3,a0
    80003f7e:	dd41                	beqz	a0,80003f16 <namex+0x90>
    iunlockput(ip);
    80003f80:	8552                	mv	a0,s4
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	bd2080e7          	jalr	-1070(ra) # 80003b54 <iunlockput>
    ip = next;
    80003f8a:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f8c:	0004c783          	lbu	a5,0(s1)
    80003f90:	01279763          	bne	a5,s2,80003f9e <namex+0x118>
    path++;
    80003f94:	0485                	add	s1,s1,1
  while(*path == '/')
    80003f96:	0004c783          	lbu	a5,0(s1)
    80003f9a:	ff278de3          	beq	a5,s2,80003f94 <namex+0x10e>
  if(*path == 0)
    80003f9e:	cb9d                	beqz	a5,80003fd4 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	89a6                	mv	s3,s1
  len = path - s;
    80003fa6:	4c81                	li	s9,0
    80003fa8:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003faa:	01278963          	beq	a5,s2,80003fbc <namex+0x136>
    80003fae:	dbbd                	beqz	a5,80003f24 <namex+0x9e>
    path++;
    80003fb0:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80003fb2:	0009c783          	lbu	a5,0(s3)
    80003fb6:	ff279ce3          	bne	a5,s2,80003fae <namex+0x128>
    80003fba:	b7ad                	j	80003f24 <namex+0x9e>
    memmove(name, s, len);
    80003fbc:	2601                	sext.w	a2,a2
    80003fbe:	85a6                	mv	a1,s1
    80003fc0:	8556                	mv	a0,s5
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	d68080e7          	jalr	-664(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003fca:	9cd6                	add	s9,s9,s5
    80003fcc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fd0:	84ce                	mv	s1,s3
    80003fd2:	b7bd                	j	80003f40 <namex+0xba>
  if(nameiparent){
    80003fd4:	f00b0de3          	beqz	s6,80003eee <namex+0x68>
    iput(ip);
    80003fd8:	8552                	mv	a0,s4
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	ad2080e7          	jalr	-1326(ra) # 80003aac <iput>
    return 0;
    80003fe2:	4a01                	li	s4,0
    80003fe4:	b729                	j	80003eee <namex+0x68>

0000000080003fe6 <dirlink>:
{
    80003fe6:	7139                	add	sp,sp,-64
    80003fe8:	fc06                	sd	ra,56(sp)
    80003fea:	f822                	sd	s0,48(sp)
    80003fec:	f426                	sd	s1,40(sp)
    80003fee:	f04a                	sd	s2,32(sp)
    80003ff0:	ec4e                	sd	s3,24(sp)
    80003ff2:	e852                	sd	s4,16(sp)
    80003ff4:	0080                	add	s0,sp,64
    80003ff6:	892a                	mv	s2,a0
    80003ff8:	8a2e                	mv	s4,a1
    80003ffa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ffc:	4601                	li	a2,0
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	dd8080e7          	jalr	-552(ra) # 80003dd6 <dirlookup>
    80004006:	e93d                	bnez	a0,8000407c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004008:	04c92483          	lw	s1,76(s2)
    8000400c:	c49d                	beqz	s1,8000403a <dirlink+0x54>
    8000400e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004010:	4741                	li	a4,16
    80004012:	86a6                	mv	a3,s1
    80004014:	fc040613          	add	a2,s0,-64
    80004018:	4581                	li	a1,0
    8000401a:	854a                	mv	a0,s2
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	b8a080e7          	jalr	-1142(ra) # 80003ba6 <readi>
    80004024:	47c1                	li	a5,16
    80004026:	06f51163          	bne	a0,a5,80004088 <dirlink+0xa2>
    if(de.inum == 0)
    8000402a:	fc045783          	lhu	a5,-64(s0)
    8000402e:	c791                	beqz	a5,8000403a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004030:	24c1                	addw	s1,s1,16
    80004032:	04c92783          	lw	a5,76(s2)
    80004036:	fcf4ede3          	bltu	s1,a5,80004010 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000403a:	4639                	li	a2,14
    8000403c:	85d2                	mv	a1,s4
    8000403e:	fc240513          	add	a0,s0,-62
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d98080e7          	jalr	-616(ra) # 80000dda <strncpy>
  de.inum = inum;
    8000404a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404e:	4741                	li	a4,16
    80004050:	86a6                	mv	a3,s1
    80004052:	fc040613          	add	a2,s0,-64
    80004056:	4581                	li	a1,0
    80004058:	854a                	mv	a0,s2
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	c44080e7          	jalr	-956(ra) # 80003c9e <writei>
    80004062:	1541                	add	a0,a0,-16
    80004064:	00a03533          	snez	a0,a0
    80004068:	40a00533          	neg	a0,a0
}
    8000406c:	70e2                	ld	ra,56(sp)
    8000406e:	7442                	ld	s0,48(sp)
    80004070:	74a2                	ld	s1,40(sp)
    80004072:	7902                	ld	s2,32(sp)
    80004074:	69e2                	ld	s3,24(sp)
    80004076:	6a42                	ld	s4,16(sp)
    80004078:	6121                	add	sp,sp,64
    8000407a:	8082                	ret
    iput(ip);
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	a30080e7          	jalr	-1488(ra) # 80003aac <iput>
    return -1;
    80004084:	557d                	li	a0,-1
    80004086:	b7dd                	j	8000406c <dirlink+0x86>
      panic("dirlink read");
    80004088:	00004517          	auipc	a0,0x4
    8000408c:	5a050513          	add	a0,a0,1440 # 80008628 <syscalls+0x1d8>
    80004090:	ffffc097          	auipc	ra,0xffffc
    80004094:	4ac080e7          	jalr	1196(ra) # 8000053c <panic>

0000000080004098 <namei>:

struct inode*
namei(char *path)
{
    80004098:	1101                	add	sp,sp,-32
    8000409a:	ec06                	sd	ra,24(sp)
    8000409c:	e822                	sd	s0,16(sp)
    8000409e:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040a0:	fe040613          	add	a2,s0,-32
    800040a4:	4581                	li	a1,0
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	de0080e7          	jalr	-544(ra) # 80003e86 <namex>
}
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	6105                	add	sp,sp,32
    800040b4:	8082                	ret

00000000800040b6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040b6:	1141                	add	sp,sp,-16
    800040b8:	e406                	sd	ra,8(sp)
    800040ba:	e022                	sd	s0,0(sp)
    800040bc:	0800                	add	s0,sp,16
    800040be:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040c0:	4585                	li	a1,1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	dc4080e7          	jalr	-572(ra) # 80003e86 <namex>
}
    800040ca:	60a2                	ld	ra,8(sp)
    800040cc:	6402                	ld	s0,0(sp)
    800040ce:	0141                	add	sp,sp,16
    800040d0:	8082                	ret

00000000800040d2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040d2:	1101                	add	sp,sp,-32
    800040d4:	ec06                	sd	ra,24(sp)
    800040d6:	e822                	sd	s0,16(sp)
    800040d8:	e426                	sd	s1,8(sp)
    800040da:	e04a                	sd	s2,0(sp)
    800040dc:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040de:	0001d917          	auipc	s2,0x1d
    800040e2:	ed290913          	add	s2,s2,-302 # 80020fb0 <log>
    800040e6:	01892583          	lw	a1,24(s2)
    800040ea:	02892503          	lw	a0,40(s2)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	ff4080e7          	jalr	-12(ra) # 800030e2 <bread>
    800040f6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f8:	02c92603          	lw	a2,44(s2)
    800040fc:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040fe:	00c05f63          	blez	a2,8000411c <write_head+0x4a>
    80004102:	0001d717          	auipc	a4,0x1d
    80004106:	ede70713          	add	a4,a4,-290 # 80020fe0 <log+0x30>
    8000410a:	87aa                	mv	a5,a0
    8000410c:	060a                	sll	a2,a2,0x2
    8000410e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004110:	4314                	lw	a3,0(a4)
    80004112:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004114:	0711                	add	a4,a4,4
    80004116:	0791                	add	a5,a5,4
    80004118:	fec79ce3          	bne	a5,a2,80004110 <write_head+0x3e>
  }
  bwrite(buf);
    8000411c:	8526                	mv	a0,s1
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	0b6080e7          	jalr	182(ra) # 800031d4 <bwrite>
  brelse(buf);
    80004126:	8526                	mv	a0,s1
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	0ea080e7          	jalr	234(ra) # 80003212 <brelse>
}
    80004130:	60e2                	ld	ra,24(sp)
    80004132:	6442                	ld	s0,16(sp)
    80004134:	64a2                	ld	s1,8(sp)
    80004136:	6902                	ld	s2,0(sp)
    80004138:	6105                	add	sp,sp,32
    8000413a:	8082                	ret

000000008000413c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413c:	0001d797          	auipc	a5,0x1d
    80004140:	ea07a783          	lw	a5,-352(a5) # 80020fdc <log+0x2c>
    80004144:	0af05d63          	blez	a5,800041fe <install_trans+0xc2>
{
    80004148:	7139                	add	sp,sp,-64
    8000414a:	fc06                	sd	ra,56(sp)
    8000414c:	f822                	sd	s0,48(sp)
    8000414e:	f426                	sd	s1,40(sp)
    80004150:	f04a                	sd	s2,32(sp)
    80004152:	ec4e                	sd	s3,24(sp)
    80004154:	e852                	sd	s4,16(sp)
    80004156:	e456                	sd	s5,8(sp)
    80004158:	e05a                	sd	s6,0(sp)
    8000415a:	0080                	add	s0,sp,64
    8000415c:	8b2a                	mv	s6,a0
    8000415e:	0001da97          	auipc	s5,0x1d
    80004162:	e82a8a93          	add	s5,s5,-382 # 80020fe0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004166:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004168:	0001d997          	auipc	s3,0x1d
    8000416c:	e4898993          	add	s3,s3,-440 # 80020fb0 <log>
    80004170:	a00d                	j	80004192 <install_trans+0x56>
    brelse(lbuf);
    80004172:	854a                	mv	a0,s2
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	09e080e7          	jalr	158(ra) # 80003212 <brelse>
    brelse(dbuf);
    8000417c:	8526                	mv	a0,s1
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	094080e7          	jalr	148(ra) # 80003212 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004186:	2a05                	addw	s4,s4,1
    80004188:	0a91                	add	s5,s5,4
    8000418a:	02c9a783          	lw	a5,44(s3)
    8000418e:	04fa5e63          	bge	s4,a5,800041ea <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004192:	0189a583          	lw	a1,24(s3)
    80004196:	014585bb          	addw	a1,a1,s4
    8000419a:	2585                	addw	a1,a1,1
    8000419c:	0289a503          	lw	a0,40(s3)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	f42080e7          	jalr	-190(ra) # 800030e2 <bread>
    800041a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041aa:	000aa583          	lw	a1,0(s5)
    800041ae:	0289a503          	lw	a0,40(s3)
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	f30080e7          	jalr	-208(ra) # 800030e2 <bread>
    800041ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041bc:	40000613          	li	a2,1024
    800041c0:	05890593          	add	a1,s2,88
    800041c4:	05850513          	add	a0,a0,88
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	b62080e7          	jalr	-1182(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	002080e7          	jalr	2(ra) # 800031d4 <bwrite>
    if(recovering == 0)
    800041da:	f80b1ce3          	bnez	s6,80004172 <install_trans+0x36>
      bunpin(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	10a080e7          	jalr	266(ra) # 800032ea <bunpin>
    800041e8:	b769                	j	80004172 <install_trans+0x36>
}
    800041ea:	70e2                	ld	ra,56(sp)
    800041ec:	7442                	ld	s0,48(sp)
    800041ee:	74a2                	ld	s1,40(sp)
    800041f0:	7902                	ld	s2,32(sp)
    800041f2:	69e2                	ld	s3,24(sp)
    800041f4:	6a42                	ld	s4,16(sp)
    800041f6:	6aa2                	ld	s5,8(sp)
    800041f8:	6b02                	ld	s6,0(sp)
    800041fa:	6121                	add	sp,sp,64
    800041fc:	8082                	ret
    800041fe:	8082                	ret

0000000080004200 <initlog>:
{
    80004200:	7179                	add	sp,sp,-48
    80004202:	f406                	sd	ra,40(sp)
    80004204:	f022                	sd	s0,32(sp)
    80004206:	ec26                	sd	s1,24(sp)
    80004208:	e84a                	sd	s2,16(sp)
    8000420a:	e44e                	sd	s3,8(sp)
    8000420c:	1800                	add	s0,sp,48
    8000420e:	892a                	mv	s2,a0
    80004210:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004212:	0001d497          	auipc	s1,0x1d
    80004216:	d9e48493          	add	s1,s1,-610 # 80020fb0 <log>
    8000421a:	00004597          	auipc	a1,0x4
    8000421e:	41e58593          	add	a1,a1,1054 # 80008638 <syscalls+0x1e8>
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	91e080e7          	jalr	-1762(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    8000422c:	0149a583          	lw	a1,20(s3)
    80004230:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004232:	0109a783          	lw	a5,16(s3)
    80004236:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004238:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000423c:	854a                	mv	a0,s2
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	ea4080e7          	jalr	-348(ra) # 800030e2 <bread>
  log.lh.n = lh->n;
    80004246:	4d30                	lw	a2,88(a0)
    80004248:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000424a:	00c05f63          	blez	a2,80004268 <initlog+0x68>
    8000424e:	87aa                	mv	a5,a0
    80004250:	0001d717          	auipc	a4,0x1d
    80004254:	d9070713          	add	a4,a4,-624 # 80020fe0 <log+0x30>
    80004258:	060a                	sll	a2,a2,0x2
    8000425a:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000425c:	4ff4                	lw	a3,92(a5)
    8000425e:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004260:	0791                	add	a5,a5,4
    80004262:	0711                	add	a4,a4,4
    80004264:	fec79ce3          	bne	a5,a2,8000425c <initlog+0x5c>
  brelse(buf);
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	faa080e7          	jalr	-86(ra) # 80003212 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004270:	4505                	li	a0,1
    80004272:	00000097          	auipc	ra,0x0
    80004276:	eca080e7          	jalr	-310(ra) # 8000413c <install_trans>
  log.lh.n = 0;
    8000427a:	0001d797          	auipc	a5,0x1d
    8000427e:	d607a123          	sw	zero,-670(a5) # 80020fdc <log+0x2c>
  write_head(); // clear the log
    80004282:	00000097          	auipc	ra,0x0
    80004286:	e50080e7          	jalr	-432(ra) # 800040d2 <write_head>
}
    8000428a:	70a2                	ld	ra,40(sp)
    8000428c:	7402                	ld	s0,32(sp)
    8000428e:	64e2                	ld	s1,24(sp)
    80004290:	6942                	ld	s2,16(sp)
    80004292:	69a2                	ld	s3,8(sp)
    80004294:	6145                	add	sp,sp,48
    80004296:	8082                	ret

0000000080004298 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004298:	1101                	add	sp,sp,-32
    8000429a:	ec06                	sd	ra,24(sp)
    8000429c:	e822                	sd	s0,16(sp)
    8000429e:	e426                	sd	s1,8(sp)
    800042a0:	e04a                	sd	s2,0(sp)
    800042a2:	1000                	add	s0,sp,32
  acquire(&log.lock);
    800042a4:	0001d517          	auipc	a0,0x1d
    800042a8:	d0c50513          	add	a0,a0,-756 # 80020fb0 <log>
    800042ac:	ffffd097          	auipc	ra,0xffffd
    800042b0:	926080e7          	jalr	-1754(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    800042b4:	0001d497          	auipc	s1,0x1d
    800042b8:	cfc48493          	add	s1,s1,-772 # 80020fb0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042bc:	4979                	li	s2,30
    800042be:	a039                	j	800042cc <begin_op+0x34>
      sleep(&log, &log.lock);
    800042c0:	85a6                	mv	a1,s1
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffe097          	auipc	ra,0xffffe
    800042c8:	d9e080e7          	jalr	-610(ra) # 80002062 <sleep>
    if(log.committing){
    800042cc:	50dc                	lw	a5,36(s1)
    800042ce:	fbed                	bnez	a5,800042c0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d0:	5098                	lw	a4,32(s1)
    800042d2:	2705                	addw	a4,a4,1
    800042d4:	0027179b          	sllw	a5,a4,0x2
    800042d8:	9fb9                	addw	a5,a5,a4
    800042da:	0017979b          	sllw	a5,a5,0x1
    800042de:	54d4                	lw	a3,44(s1)
    800042e0:	9fb5                	addw	a5,a5,a3
    800042e2:	00f95963          	bge	s2,a5,800042f4 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042e6:	85a6                	mv	a1,s1
    800042e8:	8526                	mv	a0,s1
    800042ea:	ffffe097          	auipc	ra,0xffffe
    800042ee:	d78080e7          	jalr	-648(ra) # 80002062 <sleep>
    800042f2:	bfe9                	j	800042cc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042f4:	0001d517          	auipc	a0,0x1d
    800042f8:	cbc50513          	add	a0,a0,-836 # 80020fb0 <log>
    800042fc:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004306:	60e2                	ld	ra,24(sp)
    80004308:	6442                	ld	s0,16(sp)
    8000430a:	64a2                	ld	s1,8(sp)
    8000430c:	6902                	ld	s2,0(sp)
    8000430e:	6105                	add	sp,sp,32
    80004310:	8082                	ret

0000000080004312 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004312:	7139                	add	sp,sp,-64
    80004314:	fc06                	sd	ra,56(sp)
    80004316:	f822                	sd	s0,48(sp)
    80004318:	f426                	sd	s1,40(sp)
    8000431a:	f04a                	sd	s2,32(sp)
    8000431c:	ec4e                	sd	s3,24(sp)
    8000431e:	e852                	sd	s4,16(sp)
    80004320:	e456                	sd	s5,8(sp)
    80004322:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004324:	0001d497          	auipc	s1,0x1d
    80004328:	c8c48493          	add	s1,s1,-884 # 80020fb0 <log>
    8000432c:	8526                	mv	a0,s1
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	8a4080e7          	jalr	-1884(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004336:	509c                	lw	a5,32(s1)
    80004338:	37fd                	addw	a5,a5,-1
    8000433a:	0007891b          	sext.w	s2,a5
    8000433e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004340:	50dc                	lw	a5,36(s1)
    80004342:	e7b9                	bnez	a5,80004390 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004344:	04091e63          	bnez	s2,800043a0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004348:	0001d497          	auipc	s1,0x1d
    8000434c:	c6848493          	add	s1,s1,-920 # 80020fb0 <log>
    80004350:	4785                	li	a5,1
    80004352:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004354:	8526                	mv	a0,s1
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	930080e7          	jalr	-1744(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000435e:	54dc                	lw	a5,44(s1)
    80004360:	06f04763          	bgtz	a5,800043ce <end_op+0xbc>
    acquire(&log.lock);
    80004364:	0001d497          	auipc	s1,0x1d
    80004368:	c4c48493          	add	s1,s1,-948 # 80020fb0 <log>
    8000436c:	8526                	mv	a0,s1
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	864080e7          	jalr	-1948(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004376:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffe097          	auipc	ra,0xffffe
    80004380:	d4a080e7          	jalr	-694(ra) # 800020c6 <wakeup>
    release(&log.lock);
    80004384:	8526                	mv	a0,s1
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	900080e7          	jalr	-1792(ra) # 80000c86 <release>
}
    8000438e:	a03d                	j	800043bc <end_op+0xaa>
    panic("log.committing");
    80004390:	00004517          	auipc	a0,0x4
    80004394:	2b050513          	add	a0,a0,688 # 80008640 <syscalls+0x1f0>
    80004398:	ffffc097          	auipc	ra,0xffffc
    8000439c:	1a4080e7          	jalr	420(ra) # 8000053c <panic>
    wakeup(&log);
    800043a0:	0001d497          	auipc	s1,0x1d
    800043a4:	c1048493          	add	s1,s1,-1008 # 80020fb0 <log>
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	d1c080e7          	jalr	-740(ra) # 800020c6 <wakeup>
  release(&log.lock);
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8d2080e7          	jalr	-1838(ra) # 80000c86 <release>
}
    800043bc:	70e2                	ld	ra,56(sp)
    800043be:	7442                	ld	s0,48(sp)
    800043c0:	74a2                	ld	s1,40(sp)
    800043c2:	7902                	ld	s2,32(sp)
    800043c4:	69e2                	ld	s3,24(sp)
    800043c6:	6a42                	ld	s4,16(sp)
    800043c8:	6aa2                	ld	s5,8(sp)
    800043ca:	6121                	add	sp,sp,64
    800043cc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ce:	0001da97          	auipc	s5,0x1d
    800043d2:	c12a8a93          	add	s5,s5,-1006 # 80020fe0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043d6:	0001da17          	auipc	s4,0x1d
    800043da:	bdaa0a13          	add	s4,s4,-1062 # 80020fb0 <log>
    800043de:	018a2583          	lw	a1,24(s4)
    800043e2:	012585bb          	addw	a1,a1,s2
    800043e6:	2585                	addw	a1,a1,1
    800043e8:	028a2503          	lw	a0,40(s4)
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	cf6080e7          	jalr	-778(ra) # 800030e2 <bread>
    800043f4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043f6:	000aa583          	lw	a1,0(s5)
    800043fa:	028a2503          	lw	a0,40(s4)
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	ce4080e7          	jalr	-796(ra) # 800030e2 <bread>
    80004406:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004408:	40000613          	li	a2,1024
    8000440c:	05850593          	add	a1,a0,88
    80004410:	05848513          	add	a0,s1,88
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	916080e7          	jalr	-1770(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	db6080e7          	jalr	-586(ra) # 800031d4 <bwrite>
    brelse(from);
    80004426:	854e                	mv	a0,s3
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	dea080e7          	jalr	-534(ra) # 80003212 <brelse>
    brelse(to);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	de0080e7          	jalr	-544(ra) # 80003212 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443a:	2905                	addw	s2,s2,1
    8000443c:	0a91                	add	s5,s5,4
    8000443e:	02ca2783          	lw	a5,44(s4)
    80004442:	f8f94ee3          	blt	s2,a5,800043de <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	c8c080e7          	jalr	-884(ra) # 800040d2 <write_head>
    install_trans(0); // Now install writes to home locations
    8000444e:	4501                	li	a0,0
    80004450:	00000097          	auipc	ra,0x0
    80004454:	cec080e7          	jalr	-788(ra) # 8000413c <install_trans>
    log.lh.n = 0;
    80004458:	0001d797          	auipc	a5,0x1d
    8000445c:	b807a223          	sw	zero,-1148(a5) # 80020fdc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004460:	00000097          	auipc	ra,0x0
    80004464:	c72080e7          	jalr	-910(ra) # 800040d2 <write_head>
    80004468:	bdf5                	j	80004364 <end_op+0x52>

000000008000446a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000446a:	1101                	add	sp,sp,-32
    8000446c:	ec06                	sd	ra,24(sp)
    8000446e:	e822                	sd	s0,16(sp)
    80004470:	e426                	sd	s1,8(sp)
    80004472:	e04a                	sd	s2,0(sp)
    80004474:	1000                	add	s0,sp,32
    80004476:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004478:	0001d917          	auipc	s2,0x1d
    8000447c:	b3890913          	add	s2,s2,-1224 # 80020fb0 <log>
    80004480:	854a                	mv	a0,s2
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	750080e7          	jalr	1872(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000448a:	02c92603          	lw	a2,44(s2)
    8000448e:	47f5                	li	a5,29
    80004490:	06c7c563          	blt	a5,a2,800044fa <log_write+0x90>
    80004494:	0001d797          	auipc	a5,0x1d
    80004498:	b387a783          	lw	a5,-1224(a5) # 80020fcc <log+0x1c>
    8000449c:	37fd                	addw	a5,a5,-1
    8000449e:	04f65e63          	bge	a2,a5,800044fa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	b2e7a783          	lw	a5,-1234(a5) # 80020fd0 <log+0x20>
    800044aa:	06f05063          	blez	a5,8000450a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044ae:	4781                	li	a5,0
    800044b0:	06c05563          	blez	a2,8000451a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044b4:	44cc                	lw	a1,12(s1)
    800044b6:	0001d717          	auipc	a4,0x1d
    800044ba:	b2a70713          	add	a4,a4,-1238 # 80020fe0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044be:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c0:	4314                	lw	a3,0(a4)
    800044c2:	04b68c63          	beq	a3,a1,8000451a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044c6:	2785                	addw	a5,a5,1
    800044c8:	0711                	add	a4,a4,4
    800044ca:	fef61be3          	bne	a2,a5,800044c0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044ce:	0621                	add	a2,a2,8
    800044d0:	060a                	sll	a2,a2,0x2
    800044d2:	0001d797          	auipc	a5,0x1d
    800044d6:	ade78793          	add	a5,a5,-1314 # 80020fb0 <log>
    800044da:	97b2                	add	a5,a5,a2
    800044dc:	44d8                	lw	a4,12(s1)
    800044de:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044e0:	8526                	mv	a0,s1
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	dcc080e7          	jalr	-564(ra) # 800032ae <bpin>
    log.lh.n++;
    800044ea:	0001d717          	auipc	a4,0x1d
    800044ee:	ac670713          	add	a4,a4,-1338 # 80020fb0 <log>
    800044f2:	575c                	lw	a5,44(a4)
    800044f4:	2785                	addw	a5,a5,1
    800044f6:	d75c                	sw	a5,44(a4)
    800044f8:	a82d                	j	80004532 <log_write+0xc8>
    panic("too big a transaction");
    800044fa:	00004517          	auipc	a0,0x4
    800044fe:	15650513          	add	a0,a0,342 # 80008650 <syscalls+0x200>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	03a080e7          	jalr	58(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    8000450a:	00004517          	auipc	a0,0x4
    8000450e:	15e50513          	add	a0,a0,350 # 80008668 <syscalls+0x218>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	02a080e7          	jalr	42(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    8000451a:	00878693          	add	a3,a5,8
    8000451e:	068a                	sll	a3,a3,0x2
    80004520:	0001d717          	auipc	a4,0x1d
    80004524:	a9070713          	add	a4,a4,-1392 # 80020fb0 <log>
    80004528:	9736                	add	a4,a4,a3
    8000452a:	44d4                	lw	a3,12(s1)
    8000452c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000452e:	faf609e3          	beq	a2,a5,800044e0 <log_write+0x76>
  }
  release(&log.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	a7e50513          	add	a0,a0,-1410 # 80020fb0 <log>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	74c080e7          	jalr	1868(ra) # 80000c86 <release>
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	add	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000454e:	1101                	add	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	e04a                	sd	s2,0(sp)
    80004558:	1000                	add	s0,sp,32
    8000455a:	84aa                	mv	s1,a0
    8000455c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000455e:	00004597          	auipc	a1,0x4
    80004562:	12a58593          	add	a1,a1,298 # 80008688 <syscalls+0x238>
    80004566:	0521                	add	a0,a0,8
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	5da080e7          	jalr	1498(ra) # 80000b42 <initlock>
  lk->name = name;
    80004570:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004574:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004578:	0204a423          	sw	zero,40(s1)
}
    8000457c:	60e2                	ld	ra,24(sp)
    8000457e:	6442                	ld	s0,16(sp)
    80004580:	64a2                	ld	s1,8(sp)
    80004582:	6902                	ld	s2,0(sp)
    80004584:	6105                	add	sp,sp,32
    80004586:	8082                	ret

0000000080004588 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004588:	1101                	add	sp,sp,-32
    8000458a:	ec06                	sd	ra,24(sp)
    8000458c:	e822                	sd	s0,16(sp)
    8000458e:	e426                	sd	s1,8(sp)
    80004590:	e04a                	sd	s2,0(sp)
    80004592:	1000                	add	s0,sp,32
    80004594:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004596:	00850913          	add	s2,a0,8
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	636080e7          	jalr	1590(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800045a4:	409c                	lw	a5,0(s1)
    800045a6:	cb89                	beqz	a5,800045b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045a8:	85ca                	mv	a1,s2
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffe097          	auipc	ra,0xffffe
    800045b0:	ab6080e7          	jalr	-1354(ra) # 80002062 <sleep>
  while (lk->locked) {
    800045b4:	409c                	lw	a5,0(s1)
    800045b6:	fbed                	bnez	a5,800045a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045b8:	4785                	li	a5,1
    800045ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045bc:	ffffd097          	auipc	ra,0xffffd
    800045c0:	3ea080e7          	jalr	1002(ra) # 800019a6 <myproc>
    800045c4:	591c                	lw	a5,48(a0)
    800045c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	6bc080e7          	jalr	1724(ra) # 80000c86 <release>
}
    800045d2:	60e2                	ld	ra,24(sp)
    800045d4:	6442                	ld	s0,16(sp)
    800045d6:	64a2                	ld	s1,8(sp)
    800045d8:	6902                	ld	s2,0(sp)
    800045da:	6105                	add	sp,sp,32
    800045dc:	8082                	ret

00000000800045de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045de:	1101                	add	sp,sp,-32
    800045e0:	ec06                	sd	ra,24(sp)
    800045e2:	e822                	sd	s0,16(sp)
    800045e4:	e426                	sd	s1,8(sp)
    800045e6:	e04a                	sd	s2,0(sp)
    800045e8:	1000                	add	s0,sp,32
    800045ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ec:	00850913          	add	s2,a0,8
    800045f0:	854a                	mv	a0,s2
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	5e0080e7          	jalr	1504(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    800045fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004602:	8526                	mv	a0,s1
    80004604:	ffffe097          	auipc	ra,0xffffe
    80004608:	ac2080e7          	jalr	-1342(ra) # 800020c6 <wakeup>
  release(&lk->lk);
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	678080e7          	jalr	1656(ra) # 80000c86 <release>
}
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	64a2                	ld	s1,8(sp)
    8000461c:	6902                	ld	s2,0(sp)
    8000461e:	6105                	add	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004622:	7179                	add	sp,sp,-48
    80004624:	f406                	sd	ra,40(sp)
    80004626:	f022                	sd	s0,32(sp)
    80004628:	ec26                	sd	s1,24(sp)
    8000462a:	e84a                	sd	s2,16(sp)
    8000462c:	e44e                	sd	s3,8(sp)
    8000462e:	1800                	add	s0,sp,48
    80004630:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004632:	00850913          	add	s2,a0,8
    80004636:	854a                	mv	a0,s2
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	59a080e7          	jalr	1434(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004640:	409c                	lw	a5,0(s1)
    80004642:	ef99                	bnez	a5,80004660 <holdingsleep+0x3e>
    80004644:	4481                	li	s1,0
  release(&lk->lk);
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	63e080e7          	jalr	1598(ra) # 80000c86 <release>
  return r;
}
    80004650:	8526                	mv	a0,s1
    80004652:	70a2                	ld	ra,40(sp)
    80004654:	7402                	ld	s0,32(sp)
    80004656:	64e2                	ld	s1,24(sp)
    80004658:	6942                	ld	s2,16(sp)
    8000465a:	69a2                	ld	s3,8(sp)
    8000465c:	6145                	add	sp,sp,48
    8000465e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004660:	0284a983          	lw	s3,40(s1)
    80004664:	ffffd097          	auipc	ra,0xffffd
    80004668:	342080e7          	jalr	834(ra) # 800019a6 <myproc>
    8000466c:	5904                	lw	s1,48(a0)
    8000466e:	413484b3          	sub	s1,s1,s3
    80004672:	0014b493          	seqz	s1,s1
    80004676:	bfc1                	j	80004646 <holdingsleep+0x24>

0000000080004678 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004678:	1141                	add	sp,sp,-16
    8000467a:	e406                	sd	ra,8(sp)
    8000467c:	e022                	sd	s0,0(sp)
    8000467e:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004680:	00004597          	auipc	a1,0x4
    80004684:	01858593          	add	a1,a1,24 # 80008698 <syscalls+0x248>
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	a7050513          	add	a0,a0,-1424 # 800210f8 <ftable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	4b2080e7          	jalr	1202(ra) # 80000b42 <initlock>
}
    80004698:	60a2                	ld	ra,8(sp)
    8000469a:	6402                	ld	s0,0(sp)
    8000469c:	0141                	add	sp,sp,16
    8000469e:	8082                	ret

00000000800046a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046a0:	1101                	add	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046aa:	0001d517          	auipc	a0,0x1d
    800046ae:	a4e50513          	add	a0,a0,-1458 # 800210f8 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	520080e7          	jalr	1312(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ba:	0001d497          	auipc	s1,0x1d
    800046be:	a5648493          	add	s1,s1,-1450 # 80021110 <ftable+0x18>
    800046c2:	0001e717          	auipc	a4,0x1e
    800046c6:	9ee70713          	add	a4,a4,-1554 # 800220b0 <disk>
    if(f->ref == 0){
    800046ca:	40dc                	lw	a5,4(s1)
    800046cc:	cf99                	beqz	a5,800046ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ce:	02848493          	add	s1,s1,40
    800046d2:	fee49ce3          	bne	s1,a4,800046ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046d6:	0001d517          	auipc	a0,0x1d
    800046da:	a2250513          	add	a0,a0,-1502 # 800210f8 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5a8080e7          	jalr	1448(ra) # 80000c86 <release>
  return 0;
    800046e6:	4481                	li	s1,0
    800046e8:	a819                	j	800046fe <filealloc+0x5e>
      f->ref = 1;
    800046ea:	4785                	li	a5,1
    800046ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046ee:	0001d517          	auipc	a0,0x1d
    800046f2:	a0a50513          	add	a0,a0,-1526 # 800210f8 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	590080e7          	jalr	1424(ra) # 80000c86 <release>
}
    800046fe:	8526                	mv	a0,s1
    80004700:	60e2                	ld	ra,24(sp)
    80004702:	6442                	ld	s0,16(sp)
    80004704:	64a2                	ld	s1,8(sp)
    80004706:	6105                	add	sp,sp,32
    80004708:	8082                	ret

000000008000470a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000470a:	1101                	add	sp,sp,-32
    8000470c:	ec06                	sd	ra,24(sp)
    8000470e:	e822                	sd	s0,16(sp)
    80004710:	e426                	sd	s1,8(sp)
    80004712:	1000                	add	s0,sp,32
    80004714:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004716:	0001d517          	auipc	a0,0x1d
    8000471a:	9e250513          	add	a0,a0,-1566 # 800210f8 <ftable>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	4b4080e7          	jalr	1204(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004726:	40dc                	lw	a5,4(s1)
    80004728:	02f05263          	blez	a5,8000474c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000472c:	2785                	addw	a5,a5,1
    8000472e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004730:	0001d517          	auipc	a0,0x1d
    80004734:	9c850513          	add	a0,a0,-1592 # 800210f8 <ftable>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	54e080e7          	jalr	1358(ra) # 80000c86 <release>
  return f;
}
    80004740:	8526                	mv	a0,s1
    80004742:	60e2                	ld	ra,24(sp)
    80004744:	6442                	ld	s0,16(sp)
    80004746:	64a2                	ld	s1,8(sp)
    80004748:	6105                	add	sp,sp,32
    8000474a:	8082                	ret
    panic("filedup");
    8000474c:	00004517          	auipc	a0,0x4
    80004750:	f5450513          	add	a0,a0,-172 # 800086a0 <syscalls+0x250>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	de8080e7          	jalr	-536(ra) # 8000053c <panic>

000000008000475c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000475c:	7139                	add	sp,sp,-64
    8000475e:	fc06                	sd	ra,56(sp)
    80004760:	f822                	sd	s0,48(sp)
    80004762:	f426                	sd	s1,40(sp)
    80004764:	f04a                	sd	s2,32(sp)
    80004766:	ec4e                	sd	s3,24(sp)
    80004768:	e852                	sd	s4,16(sp)
    8000476a:	e456                	sd	s5,8(sp)
    8000476c:	0080                	add	s0,sp,64
    8000476e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004770:	0001d517          	auipc	a0,0x1d
    80004774:	98850513          	add	a0,a0,-1656 # 800210f8 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	45a080e7          	jalr	1114(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004780:	40dc                	lw	a5,4(s1)
    80004782:	06f05163          	blez	a5,800047e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004786:	37fd                	addw	a5,a5,-1
    80004788:	0007871b          	sext.w	a4,a5
    8000478c:	c0dc                	sw	a5,4(s1)
    8000478e:	06e04363          	bgtz	a4,800047f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004792:	0004a903          	lw	s2,0(s1)
    80004796:	0094ca83          	lbu	s5,9(s1)
    8000479a:	0104ba03          	ld	s4,16(s1)
    8000479e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047aa:	0001d517          	auipc	a0,0x1d
    800047ae:	94e50513          	add	a0,a0,-1714 # 800210f8 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	4d4080e7          	jalr	1236(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800047ba:	4785                	li	a5,1
    800047bc:	04f90d63          	beq	s2,a5,80004816 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047c0:	3979                	addw	s2,s2,-2
    800047c2:	4785                	li	a5,1
    800047c4:	0527e063          	bltu	a5,s2,80004804 <fileclose+0xa8>
    begin_op();
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	ad0080e7          	jalr	-1328(ra) # 80004298 <begin_op>
    iput(ff.ip);
    800047d0:	854e                	mv	a0,s3
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	2da080e7          	jalr	730(ra) # 80003aac <iput>
    end_op();
    800047da:	00000097          	auipc	ra,0x0
    800047de:	b38080e7          	jalr	-1224(ra) # 80004312 <end_op>
    800047e2:	a00d                	j	80004804 <fileclose+0xa8>
    panic("fileclose");
    800047e4:	00004517          	auipc	a0,0x4
    800047e8:	ec450513          	add	a0,a0,-316 # 800086a8 <syscalls+0x258>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	d50080e7          	jalr	-688(ra) # 8000053c <panic>
    release(&ftable.lock);
    800047f4:	0001d517          	auipc	a0,0x1d
    800047f8:	90450513          	add	a0,a0,-1788 # 800210f8 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	48a080e7          	jalr	1162(ra) # 80000c86 <release>
  }
}
    80004804:	70e2                	ld	ra,56(sp)
    80004806:	7442                	ld	s0,48(sp)
    80004808:	74a2                	ld	s1,40(sp)
    8000480a:	7902                	ld	s2,32(sp)
    8000480c:	69e2                	ld	s3,24(sp)
    8000480e:	6a42                	ld	s4,16(sp)
    80004810:	6aa2                	ld	s5,8(sp)
    80004812:	6121                	add	sp,sp,64
    80004814:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004816:	85d6                	mv	a1,s5
    80004818:	8552                	mv	a0,s4
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	348080e7          	jalr	840(ra) # 80004b62 <pipeclose>
    80004822:	b7cd                	j	80004804 <fileclose+0xa8>

0000000080004824 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004824:	715d                	add	sp,sp,-80
    80004826:	e486                	sd	ra,72(sp)
    80004828:	e0a2                	sd	s0,64(sp)
    8000482a:	fc26                	sd	s1,56(sp)
    8000482c:	f84a                	sd	s2,48(sp)
    8000482e:	f44e                	sd	s3,40(sp)
    80004830:	0880                	add	s0,sp,80
    80004832:	84aa                	mv	s1,a0
    80004834:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004836:	ffffd097          	auipc	ra,0xffffd
    8000483a:	170080e7          	jalr	368(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000483e:	409c                	lw	a5,0(s1)
    80004840:	37f9                	addw	a5,a5,-2
    80004842:	4705                	li	a4,1
    80004844:	04f76763          	bltu	a4,a5,80004892 <filestat+0x6e>
    80004848:	892a                	mv	s2,a0
    ilock(f->ip);
    8000484a:	6c88                	ld	a0,24(s1)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	0a6080e7          	jalr	166(ra) # 800038f2 <ilock>
    stati(f->ip, &st);
    80004854:	fb840593          	add	a1,s0,-72
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	322080e7          	jalr	802(ra) # 80003b7c <stati>
    iunlock(f->ip);
    80004862:	6c88                	ld	a0,24(s1)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	150080e7          	jalr	336(ra) # 800039b4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000486c:	46e1                	li	a3,24
    8000486e:	fb840613          	add	a2,s0,-72
    80004872:	85ce                	mv	a1,s3
    80004874:	05093503          	ld	a0,80(s2)
    80004878:	ffffd097          	auipc	ra,0xffffd
    8000487c:	dee080e7          	jalr	-530(ra) # 80001666 <copyout>
    80004880:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004884:	60a6                	ld	ra,72(sp)
    80004886:	6406                	ld	s0,64(sp)
    80004888:	74e2                	ld	s1,56(sp)
    8000488a:	7942                	ld	s2,48(sp)
    8000488c:	79a2                	ld	s3,40(sp)
    8000488e:	6161                	add	sp,sp,80
    80004890:	8082                	ret
  return -1;
    80004892:	557d                	li	a0,-1
    80004894:	bfc5                	j	80004884 <filestat+0x60>

0000000080004896 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004896:	7179                	add	sp,sp,-48
    80004898:	f406                	sd	ra,40(sp)
    8000489a:	f022                	sd	s0,32(sp)
    8000489c:	ec26                	sd	s1,24(sp)
    8000489e:	e84a                	sd	s2,16(sp)
    800048a0:	e44e                	sd	s3,8(sp)
    800048a2:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048a4:	00854783          	lbu	a5,8(a0)
    800048a8:	c3d5                	beqz	a5,8000494c <fileread+0xb6>
    800048aa:	84aa                	mv	s1,a0
    800048ac:	89ae                	mv	s3,a1
    800048ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b0:	411c                	lw	a5,0(a0)
    800048b2:	4705                	li	a4,1
    800048b4:	04e78963          	beq	a5,a4,80004906 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048b8:	470d                	li	a4,3
    800048ba:	04e78d63          	beq	a5,a4,80004914 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048be:	4709                	li	a4,2
    800048c0:	06e79e63          	bne	a5,a4,8000493c <fileread+0xa6>
    ilock(f->ip);
    800048c4:	6d08                	ld	a0,24(a0)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	02c080e7          	jalr	44(ra) # 800038f2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048ce:	874a                	mv	a4,s2
    800048d0:	5094                	lw	a3,32(s1)
    800048d2:	864e                	mv	a2,s3
    800048d4:	4585                	li	a1,1
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	2ce080e7          	jalr	718(ra) # 80003ba6 <readi>
    800048e0:	892a                	mv	s2,a0
    800048e2:	00a05563          	blez	a0,800048ec <fileread+0x56>
      f->off += r;
    800048e6:	509c                	lw	a5,32(s1)
    800048e8:	9fa9                	addw	a5,a5,a0
    800048ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048ec:	6c88                	ld	a0,24(s1)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	0c6080e7          	jalr	198(ra) # 800039b4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048f6:	854a                	mv	a0,s2
    800048f8:	70a2                	ld	ra,40(sp)
    800048fa:	7402                	ld	s0,32(sp)
    800048fc:	64e2                	ld	s1,24(sp)
    800048fe:	6942                	ld	s2,16(sp)
    80004900:	69a2                	ld	s3,8(sp)
    80004902:	6145                	add	sp,sp,48
    80004904:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004906:	6908                	ld	a0,16(a0)
    80004908:	00000097          	auipc	ra,0x0
    8000490c:	3c2080e7          	jalr	962(ra) # 80004cca <piperead>
    80004910:	892a                	mv	s2,a0
    80004912:	b7d5                	j	800048f6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004914:	02451783          	lh	a5,36(a0)
    80004918:	03079693          	sll	a3,a5,0x30
    8000491c:	92c1                	srl	a3,a3,0x30
    8000491e:	4725                	li	a4,9
    80004920:	02d76863          	bltu	a4,a3,80004950 <fileread+0xba>
    80004924:	0792                	sll	a5,a5,0x4
    80004926:	0001c717          	auipc	a4,0x1c
    8000492a:	73270713          	add	a4,a4,1842 # 80021058 <devsw>
    8000492e:	97ba                	add	a5,a5,a4
    80004930:	639c                	ld	a5,0(a5)
    80004932:	c38d                	beqz	a5,80004954 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004934:	4505                	li	a0,1
    80004936:	9782                	jalr	a5
    80004938:	892a                	mv	s2,a0
    8000493a:	bf75                	j	800048f6 <fileread+0x60>
    panic("fileread");
    8000493c:	00004517          	auipc	a0,0x4
    80004940:	d7c50513          	add	a0,a0,-644 # 800086b8 <syscalls+0x268>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	bf8080e7          	jalr	-1032(ra) # 8000053c <panic>
    return -1;
    8000494c:	597d                	li	s2,-1
    8000494e:	b765                	j	800048f6 <fileread+0x60>
      return -1;
    80004950:	597d                	li	s2,-1
    80004952:	b755                	j	800048f6 <fileread+0x60>
    80004954:	597d                	li	s2,-1
    80004956:	b745                	j	800048f6 <fileread+0x60>

0000000080004958 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004958:	00954783          	lbu	a5,9(a0)
    8000495c:	10078e63          	beqz	a5,80004a78 <filewrite+0x120>
{
    80004960:	715d                	add	sp,sp,-80
    80004962:	e486                	sd	ra,72(sp)
    80004964:	e0a2                	sd	s0,64(sp)
    80004966:	fc26                	sd	s1,56(sp)
    80004968:	f84a                	sd	s2,48(sp)
    8000496a:	f44e                	sd	s3,40(sp)
    8000496c:	f052                	sd	s4,32(sp)
    8000496e:	ec56                	sd	s5,24(sp)
    80004970:	e85a                	sd	s6,16(sp)
    80004972:	e45e                	sd	s7,8(sp)
    80004974:	e062                	sd	s8,0(sp)
    80004976:	0880                	add	s0,sp,80
    80004978:	892a                	mv	s2,a0
    8000497a:	8b2e                	mv	s6,a1
    8000497c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000497e:	411c                	lw	a5,0(a0)
    80004980:	4705                	li	a4,1
    80004982:	02e78263          	beq	a5,a4,800049a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004986:	470d                	li	a4,3
    80004988:	02e78563          	beq	a5,a4,800049b2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000498c:	4709                	li	a4,2
    8000498e:	0ce79d63          	bne	a5,a4,80004a68 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004992:	0ac05b63          	blez	a2,80004a48 <filewrite+0xf0>
    int i = 0;
    80004996:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004998:	6b85                	lui	s7,0x1
    8000499a:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000499e:	6c05                	lui	s8,0x1
    800049a0:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800049a4:	a851                	j	80004a38 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049a6:	6908                	ld	a0,16(a0)
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	22a080e7          	jalr	554(ra) # 80004bd2 <pipewrite>
    800049b0:	a045                	j	80004a50 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049b2:	02451783          	lh	a5,36(a0)
    800049b6:	03079693          	sll	a3,a5,0x30
    800049ba:	92c1                	srl	a3,a3,0x30
    800049bc:	4725                	li	a4,9
    800049be:	0ad76f63          	bltu	a4,a3,80004a7c <filewrite+0x124>
    800049c2:	0792                	sll	a5,a5,0x4
    800049c4:	0001c717          	auipc	a4,0x1c
    800049c8:	69470713          	add	a4,a4,1684 # 80021058 <devsw>
    800049cc:	97ba                	add	a5,a5,a4
    800049ce:	679c                	ld	a5,8(a5)
    800049d0:	cbc5                	beqz	a5,80004a80 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800049d2:	4505                	li	a0,1
    800049d4:	9782                	jalr	a5
    800049d6:	a8ad                	j	80004a50 <filewrite+0xf8>
      if(n1 > max)
    800049d8:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	8bc080e7          	jalr	-1860(ra) # 80004298 <begin_op>
      ilock(f->ip);
    800049e4:	01893503          	ld	a0,24(s2)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	f0a080e7          	jalr	-246(ra) # 800038f2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049f0:	8756                	mv	a4,s5
    800049f2:	02092683          	lw	a3,32(s2)
    800049f6:	01698633          	add	a2,s3,s6
    800049fa:	4585                	li	a1,1
    800049fc:	01893503          	ld	a0,24(s2)
    80004a00:	fffff097          	auipc	ra,0xfffff
    80004a04:	29e080e7          	jalr	670(ra) # 80003c9e <writei>
    80004a08:	84aa                	mv	s1,a0
    80004a0a:	00a05763          	blez	a0,80004a18 <filewrite+0xc0>
        f->off += r;
    80004a0e:	02092783          	lw	a5,32(s2)
    80004a12:	9fa9                	addw	a5,a5,a0
    80004a14:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a18:	01893503          	ld	a0,24(s2)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	f98080e7          	jalr	-104(ra) # 800039b4 <iunlock>
      end_op();
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	8ee080e7          	jalr	-1810(ra) # 80004312 <end_op>

      if(r != n1){
    80004a2c:	009a9f63          	bne	s5,s1,80004a4a <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004a30:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a34:	0149db63          	bge	s3,s4,80004a4a <filewrite+0xf2>
      int n1 = n - i;
    80004a38:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004a3c:	0004879b          	sext.w	a5,s1
    80004a40:	f8fbdce3          	bge	s7,a5,800049d8 <filewrite+0x80>
    80004a44:	84e2                	mv	s1,s8
    80004a46:	bf49                	j	800049d8 <filewrite+0x80>
    int i = 0;
    80004a48:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a4a:	033a1d63          	bne	s4,s3,80004a84 <filewrite+0x12c>
    80004a4e:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a50:	60a6                	ld	ra,72(sp)
    80004a52:	6406                	ld	s0,64(sp)
    80004a54:	74e2                	ld	s1,56(sp)
    80004a56:	7942                	ld	s2,48(sp)
    80004a58:	79a2                	ld	s3,40(sp)
    80004a5a:	7a02                	ld	s4,32(sp)
    80004a5c:	6ae2                	ld	s5,24(sp)
    80004a5e:	6b42                	ld	s6,16(sp)
    80004a60:	6ba2                	ld	s7,8(sp)
    80004a62:	6c02                	ld	s8,0(sp)
    80004a64:	6161                	add	sp,sp,80
    80004a66:	8082                	ret
    panic("filewrite");
    80004a68:	00004517          	auipc	a0,0x4
    80004a6c:	c6050513          	add	a0,a0,-928 # 800086c8 <syscalls+0x278>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	acc080e7          	jalr	-1332(ra) # 8000053c <panic>
    return -1;
    80004a78:	557d                	li	a0,-1
}
    80004a7a:	8082                	ret
      return -1;
    80004a7c:	557d                	li	a0,-1
    80004a7e:	bfc9                	j	80004a50 <filewrite+0xf8>
    80004a80:	557d                	li	a0,-1
    80004a82:	b7f9                	j	80004a50 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004a84:	557d                	li	a0,-1
    80004a86:	b7e9                	j	80004a50 <filewrite+0xf8>

0000000080004a88 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a88:	7179                	add	sp,sp,-48
    80004a8a:	f406                	sd	ra,40(sp)
    80004a8c:	f022                	sd	s0,32(sp)
    80004a8e:	ec26                	sd	s1,24(sp)
    80004a90:	e84a                	sd	s2,16(sp)
    80004a92:	e44e                	sd	s3,8(sp)
    80004a94:	e052                	sd	s4,0(sp)
    80004a96:	1800                	add	s0,sp,48
    80004a98:	84aa                	mv	s1,a0
    80004a9a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a9c:	0005b023          	sd	zero,0(a1)
    80004aa0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	bfc080e7          	jalr	-1028(ra) # 800046a0 <filealloc>
    80004aac:	e088                	sd	a0,0(s1)
    80004aae:	c551                	beqz	a0,80004b3a <pipealloc+0xb2>
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	bf0080e7          	jalr	-1040(ra) # 800046a0 <filealloc>
    80004ab8:	00aa3023          	sd	a0,0(s4)
    80004abc:	c92d                	beqz	a0,80004b2e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	024080e7          	jalr	36(ra) # 80000ae2 <kalloc>
    80004ac6:	892a                	mv	s2,a0
    80004ac8:	c125                	beqz	a0,80004b28 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aca:	4985                	li	s3,1
    80004acc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ad0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ad4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ad8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004adc:	00004597          	auipc	a1,0x4
    80004ae0:	bfc58593          	add	a1,a1,-1028 # 800086d8 <syscalls+0x288>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	05e080e7          	jalr	94(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004aec:	609c                	ld	a5,0(s1)
    80004aee:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004af2:	609c                	ld	a5,0(s1)
    80004af4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004af8:	609c                	ld	a5,0(s1)
    80004afa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004afe:	609c                	ld	a5,0(s1)
    80004b00:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b04:	000a3783          	ld	a5,0(s4)
    80004b08:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b0c:	000a3783          	ld	a5,0(s4)
    80004b10:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b14:	000a3783          	ld	a5,0(s4)
    80004b18:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b1c:	000a3783          	ld	a5,0(s4)
    80004b20:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b24:	4501                	li	a0,0
    80004b26:	a025                	j	80004b4e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b28:	6088                	ld	a0,0(s1)
    80004b2a:	e501                	bnez	a0,80004b32 <pipealloc+0xaa>
    80004b2c:	a039                	j	80004b3a <pipealloc+0xb2>
    80004b2e:	6088                	ld	a0,0(s1)
    80004b30:	c51d                	beqz	a0,80004b5e <pipealloc+0xd6>
    fileclose(*f0);
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	c2a080e7          	jalr	-982(ra) # 8000475c <fileclose>
  if(*f1)
    80004b3a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b3e:	557d                	li	a0,-1
  if(*f1)
    80004b40:	c799                	beqz	a5,80004b4e <pipealloc+0xc6>
    fileclose(*f1);
    80004b42:	853e                	mv	a0,a5
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	c18080e7          	jalr	-1000(ra) # 8000475c <fileclose>
  return -1;
    80004b4c:	557d                	li	a0,-1
}
    80004b4e:	70a2                	ld	ra,40(sp)
    80004b50:	7402                	ld	s0,32(sp)
    80004b52:	64e2                	ld	s1,24(sp)
    80004b54:	6942                	ld	s2,16(sp)
    80004b56:	69a2                	ld	s3,8(sp)
    80004b58:	6a02                	ld	s4,0(sp)
    80004b5a:	6145                	add	sp,sp,48
    80004b5c:	8082                	ret
  return -1;
    80004b5e:	557d                	li	a0,-1
    80004b60:	b7fd                	j	80004b4e <pipealloc+0xc6>

0000000080004b62 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b62:	1101                	add	sp,sp,-32
    80004b64:	ec06                	sd	ra,24(sp)
    80004b66:	e822                	sd	s0,16(sp)
    80004b68:	e426                	sd	s1,8(sp)
    80004b6a:	e04a                	sd	s2,0(sp)
    80004b6c:	1000                	add	s0,sp,32
    80004b6e:	84aa                	mv	s1,a0
    80004b70:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	060080e7          	jalr	96(ra) # 80000bd2 <acquire>
  if(writable){
    80004b7a:	02090d63          	beqz	s2,80004bb4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b7e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b82:	21848513          	add	a0,s1,536
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	540080e7          	jalr	1344(ra) # 800020c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b8e:	2204b783          	ld	a5,544(s1)
    80004b92:	eb95                	bnez	a5,80004bc6 <pipeclose+0x64>
    release(&pi->lock);
    80004b94:	8526                	mv	a0,s1
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	0f0080e7          	jalr	240(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	e44080e7          	jalr	-444(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004ba8:	60e2                	ld	ra,24(sp)
    80004baa:	6442                	ld	s0,16(sp)
    80004bac:	64a2                	ld	s1,8(sp)
    80004bae:	6902                	ld	s2,0(sp)
    80004bb0:	6105                	add	sp,sp,32
    80004bb2:	8082                	ret
    pi->readopen = 0;
    80004bb4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bb8:	21c48513          	add	a0,s1,540
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	50a080e7          	jalr	1290(ra) # 800020c6 <wakeup>
    80004bc4:	b7e9                	j	80004b8e <pipeclose+0x2c>
    release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0be080e7          	jalr	190(ra) # 80000c86 <release>
}
    80004bd0:	bfe1                	j	80004ba8 <pipeclose+0x46>

0000000080004bd2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bd2:	711d                	add	sp,sp,-96
    80004bd4:	ec86                	sd	ra,88(sp)
    80004bd6:	e8a2                	sd	s0,80(sp)
    80004bd8:	e4a6                	sd	s1,72(sp)
    80004bda:	e0ca                	sd	s2,64(sp)
    80004bdc:	fc4e                	sd	s3,56(sp)
    80004bde:	f852                	sd	s4,48(sp)
    80004be0:	f456                	sd	s5,40(sp)
    80004be2:	f05a                	sd	s6,32(sp)
    80004be4:	ec5e                	sd	s7,24(sp)
    80004be6:	e862                	sd	s8,16(sp)
    80004be8:	1080                	add	s0,sp,96
    80004bea:	84aa                	mv	s1,a0
    80004bec:	8aae                	mv	s5,a1
    80004bee:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	db6080e7          	jalr	-586(ra) # 800019a6 <myproc>
    80004bf8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fd6080e7          	jalr	-42(ra) # 80000bd2 <acquire>
  while(i < n){
    80004c04:	0b405663          	blez	s4,80004cb0 <pipewrite+0xde>
  int i = 0;
    80004c08:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c0a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c0c:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c10:	21c48b93          	add	s7,s1,540
    80004c14:	a089                	j	80004c56 <pipewrite+0x84>
      release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	06e080e7          	jalr	110(ra) # 80000c86 <release>
      return -1;
    80004c20:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c22:	854a                	mv	a0,s2
    80004c24:	60e6                	ld	ra,88(sp)
    80004c26:	6446                	ld	s0,80(sp)
    80004c28:	64a6                	ld	s1,72(sp)
    80004c2a:	6906                	ld	s2,64(sp)
    80004c2c:	79e2                	ld	s3,56(sp)
    80004c2e:	7a42                	ld	s4,48(sp)
    80004c30:	7aa2                	ld	s5,40(sp)
    80004c32:	7b02                	ld	s6,32(sp)
    80004c34:	6be2                	ld	s7,24(sp)
    80004c36:	6c42                	ld	s8,16(sp)
    80004c38:	6125                	add	sp,sp,96
    80004c3a:	8082                	ret
      wakeup(&pi->nread);
    80004c3c:	8562                	mv	a0,s8
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	488080e7          	jalr	1160(ra) # 800020c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c46:	85a6                	mv	a1,s1
    80004c48:	855e                	mv	a0,s7
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	418080e7          	jalr	1048(ra) # 80002062 <sleep>
  while(i < n){
    80004c52:	07495063          	bge	s2,s4,80004cb2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c56:	2204a783          	lw	a5,544(s1)
    80004c5a:	dfd5                	beqz	a5,80004c16 <pipewrite+0x44>
    80004c5c:	854e                	mv	a0,s3
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	6b8080e7          	jalr	1720(ra) # 80002316 <killed>
    80004c66:	f945                	bnez	a0,80004c16 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c68:	2184a783          	lw	a5,536(s1)
    80004c6c:	21c4a703          	lw	a4,540(s1)
    80004c70:	2007879b          	addw	a5,a5,512
    80004c74:	fcf704e3          	beq	a4,a5,80004c3c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c78:	4685                	li	a3,1
    80004c7a:	01590633          	add	a2,s2,s5
    80004c7e:	faf40593          	add	a1,s0,-81
    80004c82:	0509b503          	ld	a0,80(s3)
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	a6c080e7          	jalr	-1428(ra) # 800016f2 <copyin>
    80004c8e:	03650263          	beq	a0,s6,80004cb2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c92:	21c4a783          	lw	a5,540(s1)
    80004c96:	0017871b          	addw	a4,a5,1
    80004c9a:	20e4ae23          	sw	a4,540(s1)
    80004c9e:	1ff7f793          	and	a5,a5,511
    80004ca2:	97a6                	add	a5,a5,s1
    80004ca4:	faf44703          	lbu	a4,-81(s0)
    80004ca8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cac:	2905                	addw	s2,s2,1
    80004cae:	b755                	j	80004c52 <pipewrite+0x80>
  int i = 0;
    80004cb0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cb2:	21848513          	add	a0,s1,536
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	410080e7          	jalr	1040(ra) # 800020c6 <wakeup>
  release(&pi->lock);
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	fc6080e7          	jalr	-58(ra) # 80000c86 <release>
  return i;
    80004cc8:	bfa9                	j	80004c22 <pipewrite+0x50>

0000000080004cca <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cca:	715d                	add	sp,sp,-80
    80004ccc:	e486                	sd	ra,72(sp)
    80004cce:	e0a2                	sd	s0,64(sp)
    80004cd0:	fc26                	sd	s1,56(sp)
    80004cd2:	f84a                	sd	s2,48(sp)
    80004cd4:	f44e                	sd	s3,40(sp)
    80004cd6:	f052                	sd	s4,32(sp)
    80004cd8:	ec56                	sd	s5,24(sp)
    80004cda:	e85a                	sd	s6,16(sp)
    80004cdc:	0880                	add	s0,sp,80
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	892e                	mv	s2,a1
    80004ce2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	cc2080e7          	jalr	-830(ra) # 800019a6 <myproc>
    80004cec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	ee2080e7          	jalr	-286(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	2184a703          	lw	a4,536(s1)
    80004cfc:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d00:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d04:	02f71763          	bne	a4,a5,80004d32 <piperead+0x68>
    80004d08:	2244a783          	lw	a5,548(s1)
    80004d0c:	c39d                	beqz	a5,80004d32 <piperead+0x68>
    if(killed(pr)){
    80004d0e:	8552                	mv	a0,s4
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	606080e7          	jalr	1542(ra) # 80002316 <killed>
    80004d18:	e949                	bnez	a0,80004daa <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d1a:	85a6                	mv	a1,s1
    80004d1c:	854e                	mv	a0,s3
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	344080e7          	jalr	836(ra) # 80002062 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d26:	2184a703          	lw	a4,536(s1)
    80004d2a:	21c4a783          	lw	a5,540(s1)
    80004d2e:	fcf70de3          	beq	a4,a5,80004d08 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d32:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d34:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d36:	05505463          	blez	s5,80004d7e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004d3a:	2184a783          	lw	a5,536(s1)
    80004d3e:	21c4a703          	lw	a4,540(s1)
    80004d42:	02f70e63          	beq	a4,a5,80004d7e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d46:	0017871b          	addw	a4,a5,1
    80004d4a:	20e4ac23          	sw	a4,536(s1)
    80004d4e:	1ff7f793          	and	a5,a5,511
    80004d52:	97a6                	add	a5,a5,s1
    80004d54:	0187c783          	lbu	a5,24(a5)
    80004d58:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5c:	4685                	li	a3,1
    80004d5e:	fbf40613          	add	a2,s0,-65
    80004d62:	85ca                	mv	a1,s2
    80004d64:	050a3503          	ld	a0,80(s4)
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	8fe080e7          	jalr	-1794(ra) # 80001666 <copyout>
    80004d70:	01650763          	beq	a0,s6,80004d7e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d74:	2985                	addw	s3,s3,1
    80004d76:	0905                	add	s2,s2,1
    80004d78:	fd3a91e3          	bne	s5,s3,80004d3a <piperead+0x70>
    80004d7c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d7e:	21c48513          	add	a0,s1,540
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	344080e7          	jalr	836(ra) # 800020c6 <wakeup>
  release(&pi->lock);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	efa080e7          	jalr	-262(ra) # 80000c86 <release>
  return i;
}
    80004d94:	854e                	mv	a0,s3
    80004d96:	60a6                	ld	ra,72(sp)
    80004d98:	6406                	ld	s0,64(sp)
    80004d9a:	74e2                	ld	s1,56(sp)
    80004d9c:	7942                	ld	s2,48(sp)
    80004d9e:	79a2                	ld	s3,40(sp)
    80004da0:	7a02                	ld	s4,32(sp)
    80004da2:	6ae2                	ld	s5,24(sp)
    80004da4:	6b42                	ld	s6,16(sp)
    80004da6:	6161                	add	sp,sp,80
    80004da8:	8082                	ret
      release(&pi->lock);
    80004daa:	8526                	mv	a0,s1
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	eda080e7          	jalr	-294(ra) # 80000c86 <release>
      return -1;
    80004db4:	59fd                	li	s3,-1
    80004db6:	bff9                	j	80004d94 <piperead+0xca>

0000000080004db8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004db8:	1141                	add	sp,sp,-16
    80004dba:	e422                	sd	s0,8(sp)
    80004dbc:	0800                	add	s0,sp,16
    80004dbe:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dc0:	8905                	and	a0,a0,1
    80004dc2:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004dc4:	8b89                	and	a5,a5,2
    80004dc6:	c399                	beqz	a5,80004dcc <flags2perm+0x14>
      perm |= PTE_W;
    80004dc8:	00456513          	or	a0,a0,4
    return perm;
}
    80004dcc:	6422                	ld	s0,8(sp)
    80004dce:	0141                	add	sp,sp,16
    80004dd0:	8082                	ret

0000000080004dd2 <exec>:

int
exec(char *path, char **argv)
{
    80004dd2:	df010113          	add	sp,sp,-528
    80004dd6:	20113423          	sd	ra,520(sp)
    80004dda:	20813023          	sd	s0,512(sp)
    80004dde:	ffa6                	sd	s1,504(sp)
    80004de0:	fbca                	sd	s2,496(sp)
    80004de2:	f7ce                	sd	s3,488(sp)
    80004de4:	f3d2                	sd	s4,480(sp)
    80004de6:	efd6                	sd	s5,472(sp)
    80004de8:	ebda                	sd	s6,464(sp)
    80004dea:	e7de                	sd	s7,456(sp)
    80004dec:	e3e2                	sd	s8,448(sp)
    80004dee:	ff66                	sd	s9,440(sp)
    80004df0:	fb6a                	sd	s10,432(sp)
    80004df2:	f76e                	sd	s11,424(sp)
    80004df4:	0c00                	add	s0,sp,528
    80004df6:	892a                	mv	s2,a0
    80004df8:	dea43c23          	sd	a0,-520(s0)
    80004dfc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	ba6080e7          	jalr	-1114(ra) # 800019a6 <myproc>
    80004e08:	84aa                	mv	s1,a0

  begin_op();
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	48e080e7          	jalr	1166(ra) # 80004298 <begin_op>

  if((ip = namei(path)) == 0){
    80004e12:	854a                	mv	a0,s2
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	284080e7          	jalr	644(ra) # 80004098 <namei>
    80004e1c:	c92d                	beqz	a0,80004e8e <exec+0xbc>
    80004e1e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	ad2080e7          	jalr	-1326(ra) # 800038f2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e28:	04000713          	li	a4,64
    80004e2c:	4681                	li	a3,0
    80004e2e:	e5040613          	add	a2,s0,-432
    80004e32:	4581                	li	a1,0
    80004e34:	8552                	mv	a0,s4
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	d70080e7          	jalr	-656(ra) # 80003ba6 <readi>
    80004e3e:	04000793          	li	a5,64
    80004e42:	00f51a63          	bne	a0,a5,80004e56 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e46:	e5042703          	lw	a4,-432(s0)
    80004e4a:	464c47b7          	lui	a5,0x464c4
    80004e4e:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e52:	04f70463          	beq	a4,a5,80004e9a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e56:	8552                	mv	a0,s4
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	cfc080e7          	jalr	-772(ra) # 80003b54 <iunlockput>
    end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	4b2080e7          	jalr	1202(ra) # 80004312 <end_op>
  }
  return -1;
    80004e68:	557d                	li	a0,-1
}
    80004e6a:	20813083          	ld	ra,520(sp)
    80004e6e:	20013403          	ld	s0,512(sp)
    80004e72:	74fe                	ld	s1,504(sp)
    80004e74:	795e                	ld	s2,496(sp)
    80004e76:	79be                	ld	s3,488(sp)
    80004e78:	7a1e                	ld	s4,480(sp)
    80004e7a:	6afe                	ld	s5,472(sp)
    80004e7c:	6b5e                	ld	s6,464(sp)
    80004e7e:	6bbe                	ld	s7,456(sp)
    80004e80:	6c1e                	ld	s8,448(sp)
    80004e82:	7cfa                	ld	s9,440(sp)
    80004e84:	7d5a                	ld	s10,432(sp)
    80004e86:	7dba                	ld	s11,424(sp)
    80004e88:	21010113          	add	sp,sp,528
    80004e8c:	8082                	ret
    end_op();
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	484080e7          	jalr	1156(ra) # 80004312 <end_op>
    return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	bfc9                	j	80004e6a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	bce080e7          	jalr	-1074(ra) # 80001a6a <proc_pagetable>
    80004ea4:	8b2a                	mv	s6,a0
    80004ea6:	d945                	beqz	a0,80004e56 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea8:	e7042d03          	lw	s10,-400(s0)
    80004eac:	e8845783          	lhu	a5,-376(s0)
    80004eb0:	10078463          	beqz	a5,80004fb8 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eb4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb6:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004eb8:	6c85                	lui	s9,0x1
    80004eba:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ebe:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004ec2:	6a85                	lui	s5,0x1
    80004ec4:	a0b5                	j	80004f30 <exec+0x15e>
      panic("loadseg: address should exist");
    80004ec6:	00004517          	auipc	a0,0x4
    80004eca:	81a50513          	add	a0,a0,-2022 # 800086e0 <syscalls+0x290>
    80004ece:	ffffb097          	auipc	ra,0xffffb
    80004ed2:	66e080e7          	jalr	1646(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004ed6:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ed8:	8726                	mv	a4,s1
    80004eda:	012c06bb          	addw	a3,s8,s2
    80004ede:	4581                	li	a1,0
    80004ee0:	8552                	mv	a0,s4
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	cc4080e7          	jalr	-828(ra) # 80003ba6 <readi>
    80004eea:	2501                	sext.w	a0,a0
    80004eec:	24a49863          	bne	s1,a0,8000513c <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004ef0:	012a893b          	addw	s2,s5,s2
    80004ef4:	03397563          	bgeu	s2,s3,80004f1e <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004ef8:	02091593          	sll	a1,s2,0x20
    80004efc:	9181                	srl	a1,a1,0x20
    80004efe:	95de                	add	a1,a1,s7
    80004f00:	855a                	mv	a0,s6
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	154080e7          	jalr	340(ra) # 80001056 <walkaddr>
    80004f0a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f0c:	dd4d                	beqz	a0,80004ec6 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004f0e:	412984bb          	subw	s1,s3,s2
    80004f12:	0004879b          	sext.w	a5,s1
    80004f16:	fcfcf0e3          	bgeu	s9,a5,80004ed6 <exec+0x104>
    80004f1a:	84d6                	mv	s1,s5
    80004f1c:	bf6d                	j	80004ed6 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f1e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f22:	2d85                	addw	s11,s11,1
    80004f24:	038d0d1b          	addw	s10,s10,56
    80004f28:	e8845783          	lhu	a5,-376(s0)
    80004f2c:	08fdd763          	bge	s11,a5,80004fba <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f30:	2d01                	sext.w	s10,s10
    80004f32:	03800713          	li	a4,56
    80004f36:	86ea                	mv	a3,s10
    80004f38:	e1840613          	add	a2,s0,-488
    80004f3c:	4581                	li	a1,0
    80004f3e:	8552                	mv	a0,s4
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	c66080e7          	jalr	-922(ra) # 80003ba6 <readi>
    80004f48:	03800793          	li	a5,56
    80004f4c:	1ef51663          	bne	a0,a5,80005138 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004f50:	e1842783          	lw	a5,-488(s0)
    80004f54:	4705                	li	a4,1
    80004f56:	fce796e3          	bne	a5,a4,80004f22 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004f5a:	e4043483          	ld	s1,-448(s0)
    80004f5e:	e3843783          	ld	a5,-456(s0)
    80004f62:	1ef4e863          	bltu	s1,a5,80005152 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f66:	e2843783          	ld	a5,-472(s0)
    80004f6a:	94be                	add	s1,s1,a5
    80004f6c:	1ef4e663          	bltu	s1,a5,80005158 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004f70:	df043703          	ld	a4,-528(s0)
    80004f74:	8ff9                	and	a5,a5,a4
    80004f76:	1e079463          	bnez	a5,8000515e <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f7a:	e1c42503          	lw	a0,-484(s0)
    80004f7e:	00000097          	auipc	ra,0x0
    80004f82:	e3a080e7          	jalr	-454(ra) # 80004db8 <flags2perm>
    80004f86:	86aa                	mv	a3,a0
    80004f88:	8626                	mv	a2,s1
    80004f8a:	85ca                	mv	a1,s2
    80004f8c:	855a                	mv	a0,s6
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	47c080e7          	jalr	1148(ra) # 8000140a <uvmalloc>
    80004f96:	e0a43423          	sd	a0,-504(s0)
    80004f9a:	1c050563          	beqz	a0,80005164 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f9e:	e2843b83          	ld	s7,-472(s0)
    80004fa2:	e2042c03          	lw	s8,-480(s0)
    80004fa6:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004faa:	00098463          	beqz	s3,80004fb2 <exec+0x1e0>
    80004fae:	4901                	li	s2,0
    80004fb0:	b7a1                	j	80004ef8 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fb2:	e0843903          	ld	s2,-504(s0)
    80004fb6:	b7b5                	j	80004f22 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fb8:	4901                	li	s2,0
  iunlockput(ip);
    80004fba:	8552                	mv	a0,s4
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	b98080e7          	jalr	-1128(ra) # 80003b54 <iunlockput>
  end_op();
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	34e080e7          	jalr	846(ra) # 80004312 <end_op>
  p = myproc();
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	9da080e7          	jalr	-1574(ra) # 800019a6 <myproc>
    80004fd4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fd6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004fda:	6985                	lui	s3,0x1
    80004fdc:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004fde:	99ca                	add	s3,s3,s2
    80004fe0:	77fd                	lui	a5,0xfffff
    80004fe2:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fe6:	4691                	li	a3,4
    80004fe8:	6609                	lui	a2,0x2
    80004fea:	964e                	add	a2,a2,s3
    80004fec:	85ce                	mv	a1,s3
    80004fee:	855a                	mv	a0,s6
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	41a080e7          	jalr	1050(ra) # 8000140a <uvmalloc>
    80004ff8:	892a                	mv	s2,a0
    80004ffa:	e0a43423          	sd	a0,-504(s0)
    80004ffe:	e509                	bnez	a0,80005008 <exec+0x236>
  if(pagetable)
    80005000:	e1343423          	sd	s3,-504(s0)
    80005004:	4a01                	li	s4,0
    80005006:	aa1d                	j	8000513c <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005008:	75f9                	lui	a1,0xffffe
    8000500a:	95aa                	add	a1,a1,a0
    8000500c:	855a                	mv	a0,s6
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	626080e7          	jalr	1574(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80005016:	7bfd                	lui	s7,0xfffff
    80005018:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000501a:	e0043783          	ld	a5,-512(s0)
    8000501e:	6388                	ld	a0,0(a5)
    80005020:	c52d                	beqz	a0,8000508a <exec+0x2b8>
    80005022:	e9040993          	add	s3,s0,-368
    80005026:	f9040c13          	add	s8,s0,-112
    8000502a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	e1c080e7          	jalr	-484(ra) # 80000e48 <strlen>
    80005034:	0015079b          	addw	a5,a0,1
    80005038:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000503c:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    80005040:	13796563          	bltu	s2,s7,8000516a <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005044:	e0043d03          	ld	s10,-512(s0)
    80005048:	000d3a03          	ld	s4,0(s10)
    8000504c:	8552                	mv	a0,s4
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	dfa080e7          	jalr	-518(ra) # 80000e48 <strlen>
    80005056:	0015069b          	addw	a3,a0,1
    8000505a:	8652                	mv	a2,s4
    8000505c:	85ca                	mv	a1,s2
    8000505e:	855a                	mv	a0,s6
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	606080e7          	jalr	1542(ra) # 80001666 <copyout>
    80005068:	10054363          	bltz	a0,8000516e <exec+0x39c>
    ustack[argc] = sp;
    8000506c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005070:	0485                	add	s1,s1,1
    80005072:	008d0793          	add	a5,s10,8
    80005076:	e0f43023          	sd	a5,-512(s0)
    8000507a:	008d3503          	ld	a0,8(s10)
    8000507e:	c909                	beqz	a0,80005090 <exec+0x2be>
    if(argc >= MAXARG)
    80005080:	09a1                	add	s3,s3,8
    80005082:	fb8995e3          	bne	s3,s8,8000502c <exec+0x25a>
  ip = 0;
    80005086:	4a01                	li	s4,0
    80005088:	a855                	j	8000513c <exec+0x36a>
  sp = sz;
    8000508a:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000508e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005090:	00349793          	sll	a5,s1,0x3
    80005094:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcda0>
    80005098:	97a2                	add	a5,a5,s0
    8000509a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000509e:	00148693          	add	a3,s1,1
    800050a2:	068e                	sll	a3,a3,0x3
    800050a4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050a8:	ff097913          	and	s2,s2,-16
  sz = sz1;
    800050ac:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800050b0:	f57968e3          	bltu	s2,s7,80005000 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050b4:	e9040613          	add	a2,s0,-368
    800050b8:	85ca                	mv	a1,s2
    800050ba:	855a                	mv	a0,s6
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	5aa080e7          	jalr	1450(ra) # 80001666 <copyout>
    800050c4:	0a054763          	bltz	a0,80005172 <exec+0x3a0>
  p->trapframe->a1 = sp;
    800050c8:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800050cc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050d0:	df843783          	ld	a5,-520(s0)
    800050d4:	0007c703          	lbu	a4,0(a5)
    800050d8:	cf11                	beqz	a4,800050f4 <exec+0x322>
    800050da:	0785                	add	a5,a5,1
    if(*s == '/')
    800050dc:	02f00693          	li	a3,47
    800050e0:	a039                	j	800050ee <exec+0x31c>
      last = s+1;
    800050e2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050e6:	0785                	add	a5,a5,1
    800050e8:	fff7c703          	lbu	a4,-1(a5)
    800050ec:	c701                	beqz	a4,800050f4 <exec+0x322>
    if(*s == '/')
    800050ee:	fed71ce3          	bne	a4,a3,800050e6 <exec+0x314>
    800050f2:	bfc5                	j	800050e2 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800050f4:	4641                	li	a2,16
    800050f6:	df843583          	ld	a1,-520(s0)
    800050fa:	158a8513          	add	a0,s5,344
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	d18080e7          	jalr	-744(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005106:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000510a:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000510e:	e0843783          	ld	a5,-504(s0)
    80005112:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005116:	058ab783          	ld	a5,88(s5)
    8000511a:	e6843703          	ld	a4,-408(s0)
    8000511e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005120:	058ab783          	ld	a5,88(s5)
    80005124:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005128:	85e6                	mv	a1,s9
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	9dc080e7          	jalr	-1572(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005132:	0004851b          	sext.w	a0,s1
    80005136:	bb15                	j	80004e6a <exec+0x98>
    80005138:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000513c:	e0843583          	ld	a1,-504(s0)
    80005140:	855a                	mv	a0,s6
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	9c4080e7          	jalr	-1596(ra) # 80001b06 <proc_freepagetable>
  return -1;
    8000514a:	557d                	li	a0,-1
  if(ip){
    8000514c:	d00a0fe3          	beqz	s4,80004e6a <exec+0x98>
    80005150:	b319                	j	80004e56 <exec+0x84>
    80005152:	e1243423          	sd	s2,-504(s0)
    80005156:	b7dd                	j	8000513c <exec+0x36a>
    80005158:	e1243423          	sd	s2,-504(s0)
    8000515c:	b7c5                	j	8000513c <exec+0x36a>
    8000515e:	e1243423          	sd	s2,-504(s0)
    80005162:	bfe9                	j	8000513c <exec+0x36a>
    80005164:	e1243423          	sd	s2,-504(s0)
    80005168:	bfd1                	j	8000513c <exec+0x36a>
  ip = 0;
    8000516a:	4a01                	li	s4,0
    8000516c:	bfc1                	j	8000513c <exec+0x36a>
    8000516e:	4a01                	li	s4,0
  if(pagetable)
    80005170:	b7f1                	j	8000513c <exec+0x36a>
  sz = sz1;
    80005172:	e0843983          	ld	s3,-504(s0)
    80005176:	b569                	j	80005000 <exec+0x22e>

0000000080005178 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005178:	7179                	add	sp,sp,-48
    8000517a:	f406                	sd	ra,40(sp)
    8000517c:	f022                	sd	s0,32(sp)
    8000517e:	ec26                	sd	s1,24(sp)
    80005180:	e84a                	sd	s2,16(sp)
    80005182:	1800                	add	s0,sp,48
    80005184:	892e                	mv	s2,a1
    80005186:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005188:	fdc40593          	add	a1,s0,-36
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	b0c080e7          	jalr	-1268(ra) # 80002c98 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005194:	fdc42703          	lw	a4,-36(s0)
    80005198:	47bd                	li	a5,15
    8000519a:	02e7eb63          	bltu	a5,a4,800051d0 <argfd+0x58>
    8000519e:	ffffd097          	auipc	ra,0xffffd
    800051a2:	808080e7          	jalr	-2040(ra) # 800019a6 <myproc>
    800051a6:	fdc42703          	lw	a4,-36(s0)
    800051aa:	01a70793          	add	a5,a4,26
    800051ae:	078e                	sll	a5,a5,0x3
    800051b0:	953e                	add	a0,a0,a5
    800051b2:	611c                	ld	a5,0(a0)
    800051b4:	c385                	beqz	a5,800051d4 <argfd+0x5c>
    return -1;
  if(pfd)
    800051b6:	00090463          	beqz	s2,800051be <argfd+0x46>
    *pfd = fd;
    800051ba:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051be:	4501                	li	a0,0
  if(pf)
    800051c0:	c091                	beqz	s1,800051c4 <argfd+0x4c>
    *pf = f;
    800051c2:	e09c                	sd	a5,0(s1)
}
    800051c4:	70a2                	ld	ra,40(sp)
    800051c6:	7402                	ld	s0,32(sp)
    800051c8:	64e2                	ld	s1,24(sp)
    800051ca:	6942                	ld	s2,16(sp)
    800051cc:	6145                	add	sp,sp,48
    800051ce:	8082                	ret
    return -1;
    800051d0:	557d                	li	a0,-1
    800051d2:	bfcd                	j	800051c4 <argfd+0x4c>
    800051d4:	557d                	li	a0,-1
    800051d6:	b7fd                	j	800051c4 <argfd+0x4c>

00000000800051d8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051d8:	1101                	add	sp,sp,-32
    800051da:	ec06                	sd	ra,24(sp)
    800051dc:	e822                	sd	s0,16(sp)
    800051de:	e426                	sd	s1,8(sp)
    800051e0:	1000                	add	s0,sp,32
    800051e2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	7c2080e7          	jalr	1986(ra) # 800019a6 <myproc>
    800051ec:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051ee:	0d050793          	add	a5,a0,208
    800051f2:	4501                	li	a0,0
    800051f4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051f6:	6398                	ld	a4,0(a5)
    800051f8:	cb19                	beqz	a4,8000520e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051fa:	2505                	addw	a0,a0,1
    800051fc:	07a1                	add	a5,a5,8
    800051fe:	fed51ce3          	bne	a0,a3,800051f6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005202:	557d                	li	a0,-1
}
    80005204:	60e2                	ld	ra,24(sp)
    80005206:	6442                	ld	s0,16(sp)
    80005208:	64a2                	ld	s1,8(sp)
    8000520a:	6105                	add	sp,sp,32
    8000520c:	8082                	ret
      p->ofile[fd] = f;
    8000520e:	01a50793          	add	a5,a0,26
    80005212:	078e                	sll	a5,a5,0x3
    80005214:	963e                	add	a2,a2,a5
    80005216:	e204                	sd	s1,0(a2)
      return fd;
    80005218:	b7f5                	j	80005204 <fdalloc+0x2c>

000000008000521a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000521a:	715d                	add	sp,sp,-80
    8000521c:	e486                	sd	ra,72(sp)
    8000521e:	e0a2                	sd	s0,64(sp)
    80005220:	fc26                	sd	s1,56(sp)
    80005222:	f84a                	sd	s2,48(sp)
    80005224:	f44e                	sd	s3,40(sp)
    80005226:	f052                	sd	s4,32(sp)
    80005228:	ec56                	sd	s5,24(sp)
    8000522a:	e85a                	sd	s6,16(sp)
    8000522c:	0880                	add	s0,sp,80
    8000522e:	8b2e                	mv	s6,a1
    80005230:	89b2                	mv	s3,a2
    80005232:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005234:	fb040593          	add	a1,s0,-80
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	e7e080e7          	jalr	-386(ra) # 800040b6 <nameiparent>
    80005240:	84aa                	mv	s1,a0
    80005242:	14050b63          	beqz	a0,80005398 <create+0x17e>
    return 0;

  ilock(dp);
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	6ac080e7          	jalr	1708(ra) # 800038f2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000524e:	4601                	li	a2,0
    80005250:	fb040593          	add	a1,s0,-80
    80005254:	8526                	mv	a0,s1
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	b80080e7          	jalr	-1152(ra) # 80003dd6 <dirlookup>
    8000525e:	8aaa                	mv	s5,a0
    80005260:	c921                	beqz	a0,800052b0 <create+0x96>
    iunlockput(dp);
    80005262:	8526                	mv	a0,s1
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	8f0080e7          	jalr	-1808(ra) # 80003b54 <iunlockput>
    ilock(ip);
    8000526c:	8556                	mv	a0,s5
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	684080e7          	jalr	1668(ra) # 800038f2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005276:	4789                	li	a5,2
    80005278:	02fb1563          	bne	s6,a5,800052a2 <create+0x88>
    8000527c:	044ad783          	lhu	a5,68(s5)
    80005280:	37f9                	addw	a5,a5,-2
    80005282:	17c2                	sll	a5,a5,0x30
    80005284:	93c1                	srl	a5,a5,0x30
    80005286:	4705                	li	a4,1
    80005288:	00f76d63          	bltu	a4,a5,800052a2 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000528c:	8556                	mv	a0,s5
    8000528e:	60a6                	ld	ra,72(sp)
    80005290:	6406                	ld	s0,64(sp)
    80005292:	74e2                	ld	s1,56(sp)
    80005294:	7942                	ld	s2,48(sp)
    80005296:	79a2                	ld	s3,40(sp)
    80005298:	7a02                	ld	s4,32(sp)
    8000529a:	6ae2                	ld	s5,24(sp)
    8000529c:	6b42                	ld	s6,16(sp)
    8000529e:	6161                	add	sp,sp,80
    800052a0:	8082                	ret
    iunlockput(ip);
    800052a2:	8556                	mv	a0,s5
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	8b0080e7          	jalr	-1872(ra) # 80003b54 <iunlockput>
    return 0;
    800052ac:	4a81                	li	s5,0
    800052ae:	bff9                	j	8000528c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052b0:	85da                	mv	a1,s6
    800052b2:	4088                	lw	a0,0(s1)
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	4a6080e7          	jalr	1190(ra) # 8000375a <ialloc>
    800052bc:	8a2a                	mv	s4,a0
    800052be:	c529                	beqz	a0,80005308 <create+0xee>
  ilock(ip);
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	632080e7          	jalr	1586(ra) # 800038f2 <ilock>
  ip->major = major;
    800052c8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052cc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052d0:	4905                	li	s2,1
    800052d2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052d6:	8552                	mv	a0,s4
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	54e080e7          	jalr	1358(ra) # 80003826 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052e0:	032b0b63          	beq	s6,s2,80005316 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e4:	004a2603          	lw	a2,4(s4)
    800052e8:	fb040593          	add	a1,s0,-80
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	cf8080e7          	jalr	-776(ra) # 80003fe6 <dirlink>
    800052f6:	06054f63          	bltz	a0,80005374 <create+0x15a>
  iunlockput(dp);
    800052fa:	8526                	mv	a0,s1
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	858080e7          	jalr	-1960(ra) # 80003b54 <iunlockput>
  return ip;
    80005304:	8ad2                	mv	s5,s4
    80005306:	b759                	j	8000528c <create+0x72>
    iunlockput(dp);
    80005308:	8526                	mv	a0,s1
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	84a080e7          	jalr	-1974(ra) # 80003b54 <iunlockput>
    return 0;
    80005312:	8ad2                	mv	s5,s4
    80005314:	bfa5                	j	8000528c <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005316:	004a2603          	lw	a2,4(s4)
    8000531a:	00003597          	auipc	a1,0x3
    8000531e:	3e658593          	add	a1,a1,998 # 80008700 <syscalls+0x2b0>
    80005322:	8552                	mv	a0,s4
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	cc2080e7          	jalr	-830(ra) # 80003fe6 <dirlink>
    8000532c:	04054463          	bltz	a0,80005374 <create+0x15a>
    80005330:	40d0                	lw	a2,4(s1)
    80005332:	00003597          	auipc	a1,0x3
    80005336:	3d658593          	add	a1,a1,982 # 80008708 <syscalls+0x2b8>
    8000533a:	8552                	mv	a0,s4
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	caa080e7          	jalr	-854(ra) # 80003fe6 <dirlink>
    80005344:	02054863          	bltz	a0,80005374 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005348:	004a2603          	lw	a2,4(s4)
    8000534c:	fb040593          	add	a1,s0,-80
    80005350:	8526                	mv	a0,s1
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	c94080e7          	jalr	-876(ra) # 80003fe6 <dirlink>
    8000535a:	00054d63          	bltz	a0,80005374 <create+0x15a>
    dp->nlink++;  // for ".."
    8000535e:	04a4d783          	lhu	a5,74(s1)
    80005362:	2785                	addw	a5,a5,1
    80005364:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005368:	8526                	mv	a0,s1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	4bc080e7          	jalr	1212(ra) # 80003826 <iupdate>
    80005372:	b761                	j	800052fa <create+0xe0>
  ip->nlink = 0;
    80005374:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005378:	8552                	mv	a0,s4
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	4ac080e7          	jalr	1196(ra) # 80003826 <iupdate>
  iunlockput(ip);
    80005382:	8552                	mv	a0,s4
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	7d0080e7          	jalr	2000(ra) # 80003b54 <iunlockput>
  iunlockput(dp);
    8000538c:	8526                	mv	a0,s1
    8000538e:	ffffe097          	auipc	ra,0xffffe
    80005392:	7c6080e7          	jalr	1990(ra) # 80003b54 <iunlockput>
  return 0;
    80005396:	bddd                	j	8000528c <create+0x72>
    return 0;
    80005398:	8aaa                	mv	s5,a0
    8000539a:	bdcd                	j	8000528c <create+0x72>

000000008000539c <sys_dup>:
{
    8000539c:	7179                	add	sp,sp,-48
    8000539e:	f406                	sd	ra,40(sp)
    800053a0:	f022                	sd	s0,32(sp)
    800053a2:	ec26                	sd	s1,24(sp)
    800053a4:	e84a                	sd	s2,16(sp)
    800053a6:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053a8:	fd840613          	add	a2,s0,-40
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	dc8080e7          	jalr	-568(ra) # 80005178 <argfd>
    return -1;
    800053b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ba:	02054363          	bltz	a0,800053e0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800053be:	fd843903          	ld	s2,-40(s0)
    800053c2:	854a                	mv	a0,s2
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	e14080e7          	jalr	-492(ra) # 800051d8 <fdalloc>
    800053cc:	84aa                	mv	s1,a0
    return -1;
    800053ce:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053d0:	00054863          	bltz	a0,800053e0 <sys_dup+0x44>
  filedup(f);
    800053d4:	854a                	mv	a0,s2
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	334080e7          	jalr	820(ra) # 8000470a <filedup>
  return fd;
    800053de:	87a6                	mv	a5,s1
}
    800053e0:	853e                	mv	a0,a5
    800053e2:	70a2                	ld	ra,40(sp)
    800053e4:	7402                	ld	s0,32(sp)
    800053e6:	64e2                	ld	s1,24(sp)
    800053e8:	6942                	ld	s2,16(sp)
    800053ea:	6145                	add	sp,sp,48
    800053ec:	8082                	ret

00000000800053ee <sys_read>:
{
    800053ee:	7179                	add	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800053f6:	fd840593          	add	a1,s0,-40
    800053fa:	4505                	li	a0,1
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	8bc080e7          	jalr	-1860(ra) # 80002cb8 <argaddr>
  argint(2, &n);
    80005404:	fe440593          	add	a1,s0,-28
    80005408:	4509                	li	a0,2
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	88e080e7          	jalr	-1906(ra) # 80002c98 <argint>
  if(argfd(0, 0, &f) < 0)
    80005412:	fe840613          	add	a2,s0,-24
    80005416:	4581                	li	a1,0
    80005418:	4501                	li	a0,0
    8000541a:	00000097          	auipc	ra,0x0
    8000541e:	d5e080e7          	jalr	-674(ra) # 80005178 <argfd>
    80005422:	87aa                	mv	a5,a0
    return -1;
    80005424:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005426:	0007cc63          	bltz	a5,8000543e <sys_read+0x50>
  return fileread(f, p, n);
    8000542a:	fe442603          	lw	a2,-28(s0)
    8000542e:	fd843583          	ld	a1,-40(s0)
    80005432:	fe843503          	ld	a0,-24(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	460080e7          	jalr	1120(ra) # 80004896 <fileread>
}
    8000543e:	70a2                	ld	ra,40(sp)
    80005440:	7402                	ld	s0,32(sp)
    80005442:	6145                	add	sp,sp,48
    80005444:	8082                	ret

0000000080005446 <sys_write>:
{
    80005446:	7179                	add	sp,sp,-48
    80005448:	f406                	sd	ra,40(sp)
    8000544a:	f022                	sd	s0,32(sp)
    8000544c:	1800                	add	s0,sp,48
  argaddr(1, &p);
    8000544e:	fd840593          	add	a1,s0,-40
    80005452:	4505                	li	a0,1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	864080e7          	jalr	-1948(ra) # 80002cb8 <argaddr>
  argint(2, &n);
    8000545c:	fe440593          	add	a1,s0,-28
    80005460:	4509                	li	a0,2
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	836080e7          	jalr	-1994(ra) # 80002c98 <argint>
  if(argfd(0, 0, &f) < 0)
    8000546a:	fe840613          	add	a2,s0,-24
    8000546e:	4581                	li	a1,0
    80005470:	4501                	li	a0,0
    80005472:	00000097          	auipc	ra,0x0
    80005476:	d06080e7          	jalr	-762(ra) # 80005178 <argfd>
    8000547a:	87aa                	mv	a5,a0
    return -1;
    8000547c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000547e:	0007cc63          	bltz	a5,80005496 <sys_write+0x50>
  return filewrite(f, p, n);
    80005482:	fe442603          	lw	a2,-28(s0)
    80005486:	fd843583          	ld	a1,-40(s0)
    8000548a:	fe843503          	ld	a0,-24(s0)
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	4ca080e7          	jalr	1226(ra) # 80004958 <filewrite>
}
    80005496:	70a2                	ld	ra,40(sp)
    80005498:	7402                	ld	s0,32(sp)
    8000549a:	6145                	add	sp,sp,48
    8000549c:	8082                	ret

000000008000549e <sys_close>:
{
    8000549e:	1101                	add	sp,sp,-32
    800054a0:	ec06                	sd	ra,24(sp)
    800054a2:	e822                	sd	s0,16(sp)
    800054a4:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054a6:	fe040613          	add	a2,s0,-32
    800054aa:	fec40593          	add	a1,s0,-20
    800054ae:	4501                	li	a0,0
    800054b0:	00000097          	auipc	ra,0x0
    800054b4:	cc8080e7          	jalr	-824(ra) # 80005178 <argfd>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054ba:	02054463          	bltz	a0,800054e2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	4e8080e7          	jalr	1256(ra) # 800019a6 <myproc>
    800054c6:	fec42783          	lw	a5,-20(s0)
    800054ca:	07e9                	add	a5,a5,26
    800054cc:	078e                	sll	a5,a5,0x3
    800054ce:	953e                	add	a0,a0,a5
    800054d0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800054d4:	fe043503          	ld	a0,-32(s0)
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	284080e7          	jalr	644(ra) # 8000475c <fileclose>
  return 0;
    800054e0:	4781                	li	a5,0
}
    800054e2:	853e                	mv	a0,a5
    800054e4:	60e2                	ld	ra,24(sp)
    800054e6:	6442                	ld	s0,16(sp)
    800054e8:	6105                	add	sp,sp,32
    800054ea:	8082                	ret

00000000800054ec <sys_fstat>:
{
    800054ec:	1101                	add	sp,sp,-32
    800054ee:	ec06                	sd	ra,24(sp)
    800054f0:	e822                	sd	s0,16(sp)
    800054f2:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800054f4:	fe040593          	add	a1,s0,-32
    800054f8:	4505                	li	a0,1
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	7be080e7          	jalr	1982(ra) # 80002cb8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005502:	fe840613          	add	a2,s0,-24
    80005506:	4581                	li	a1,0
    80005508:	4501                	li	a0,0
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	c6e080e7          	jalr	-914(ra) # 80005178 <argfd>
    80005512:	87aa                	mv	a5,a0
    return -1;
    80005514:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005516:	0007ca63          	bltz	a5,8000552a <sys_fstat+0x3e>
  return filestat(f, st);
    8000551a:	fe043583          	ld	a1,-32(s0)
    8000551e:	fe843503          	ld	a0,-24(s0)
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	302080e7          	jalr	770(ra) # 80004824 <filestat>
}
    8000552a:	60e2                	ld	ra,24(sp)
    8000552c:	6442                	ld	s0,16(sp)
    8000552e:	6105                	add	sp,sp,32
    80005530:	8082                	ret

0000000080005532 <sys_link>:
{
    80005532:	7169                	add	sp,sp,-304
    80005534:	f606                	sd	ra,296(sp)
    80005536:	f222                	sd	s0,288(sp)
    80005538:	ee26                	sd	s1,280(sp)
    8000553a:	ea4a                	sd	s2,272(sp)
    8000553c:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553e:	08000613          	li	a2,128
    80005542:	ed040593          	add	a1,s0,-304
    80005546:	4501                	li	a0,0
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	790080e7          	jalr	1936(ra) # 80002cd8 <argstr>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005552:	10054e63          	bltz	a0,8000566e <sys_link+0x13c>
    80005556:	08000613          	li	a2,128
    8000555a:	f5040593          	add	a1,s0,-176
    8000555e:	4505                	li	a0,1
    80005560:	ffffd097          	auipc	ra,0xffffd
    80005564:	778080e7          	jalr	1912(ra) # 80002cd8 <argstr>
    return -1;
    80005568:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000556a:	10054263          	bltz	a0,8000566e <sys_link+0x13c>
  begin_op();
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	d2a080e7          	jalr	-726(ra) # 80004298 <begin_op>
  if((ip = namei(old)) == 0){
    80005576:	ed040513          	add	a0,s0,-304
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	b1e080e7          	jalr	-1250(ra) # 80004098 <namei>
    80005582:	84aa                	mv	s1,a0
    80005584:	c551                	beqz	a0,80005610 <sys_link+0xde>
  ilock(ip);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	36c080e7          	jalr	876(ra) # 800038f2 <ilock>
  if(ip->type == T_DIR){
    8000558e:	04449703          	lh	a4,68(s1)
    80005592:	4785                	li	a5,1
    80005594:	08f70463          	beq	a4,a5,8000561c <sys_link+0xea>
  ip->nlink++;
    80005598:	04a4d783          	lhu	a5,74(s1)
    8000559c:	2785                	addw	a5,a5,1
    8000559e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	282080e7          	jalr	642(ra) # 80003826 <iupdate>
  iunlock(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	406080e7          	jalr	1030(ra) # 800039b4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055b6:	fd040593          	add	a1,s0,-48
    800055ba:	f5040513          	add	a0,s0,-176
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	af8080e7          	jalr	-1288(ra) # 800040b6 <nameiparent>
    800055c6:	892a                	mv	s2,a0
    800055c8:	c935                	beqz	a0,8000563c <sys_link+0x10a>
  ilock(dp);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	328080e7          	jalr	808(ra) # 800038f2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055d2:	00092703          	lw	a4,0(s2)
    800055d6:	409c                	lw	a5,0(s1)
    800055d8:	04f71d63          	bne	a4,a5,80005632 <sys_link+0x100>
    800055dc:	40d0                	lw	a2,4(s1)
    800055de:	fd040593          	add	a1,s0,-48
    800055e2:	854a                	mv	a0,s2
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	a02080e7          	jalr	-1534(ra) # 80003fe6 <dirlink>
    800055ec:	04054363          	bltz	a0,80005632 <sys_link+0x100>
  iunlockput(dp);
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	562080e7          	jalr	1378(ra) # 80003b54 <iunlockput>
  iput(ip);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	4b0080e7          	jalr	1200(ra) # 80003aac <iput>
  end_op();
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	d0e080e7          	jalr	-754(ra) # 80004312 <end_op>
  return 0;
    8000560c:	4781                	li	a5,0
    8000560e:	a085                	j	8000566e <sys_link+0x13c>
    end_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	d02080e7          	jalr	-766(ra) # 80004312 <end_op>
    return -1;
    80005618:	57fd                	li	a5,-1
    8000561a:	a891                	j	8000566e <sys_link+0x13c>
    iunlockput(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	536080e7          	jalr	1334(ra) # 80003b54 <iunlockput>
    end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	cec080e7          	jalr	-788(ra) # 80004312 <end_op>
    return -1;
    8000562e:	57fd                	li	a5,-1
    80005630:	a83d                	j	8000566e <sys_link+0x13c>
    iunlockput(dp);
    80005632:	854a                	mv	a0,s2
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	520080e7          	jalr	1312(ra) # 80003b54 <iunlockput>
  ilock(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	2b4080e7          	jalr	692(ra) # 800038f2 <ilock>
  ip->nlink--;
    80005646:	04a4d783          	lhu	a5,74(s1)
    8000564a:	37fd                	addw	a5,a5,-1
    8000564c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	1d4080e7          	jalr	468(ra) # 80003826 <iupdate>
  iunlockput(ip);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	4f8080e7          	jalr	1272(ra) # 80003b54 <iunlockput>
  end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	cae080e7          	jalr	-850(ra) # 80004312 <end_op>
  return -1;
    8000566c:	57fd                	li	a5,-1
}
    8000566e:	853e                	mv	a0,a5
    80005670:	70b2                	ld	ra,296(sp)
    80005672:	7412                	ld	s0,288(sp)
    80005674:	64f2                	ld	s1,280(sp)
    80005676:	6952                	ld	s2,272(sp)
    80005678:	6155                	add	sp,sp,304
    8000567a:	8082                	ret

000000008000567c <sys_unlink>:
{
    8000567c:	7151                	add	sp,sp,-240
    8000567e:	f586                	sd	ra,232(sp)
    80005680:	f1a2                	sd	s0,224(sp)
    80005682:	eda6                	sd	s1,216(sp)
    80005684:	e9ca                	sd	s2,208(sp)
    80005686:	e5ce                	sd	s3,200(sp)
    80005688:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000568a:	08000613          	li	a2,128
    8000568e:	f3040593          	add	a1,s0,-208
    80005692:	4501                	li	a0,0
    80005694:	ffffd097          	auipc	ra,0xffffd
    80005698:	644080e7          	jalr	1604(ra) # 80002cd8 <argstr>
    8000569c:	18054163          	bltz	a0,8000581e <sys_unlink+0x1a2>
  begin_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	bf8080e7          	jalr	-1032(ra) # 80004298 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a8:	fb040593          	add	a1,s0,-80
    800056ac:	f3040513          	add	a0,s0,-208
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	a06080e7          	jalr	-1530(ra) # 800040b6 <nameiparent>
    800056b8:	84aa                	mv	s1,a0
    800056ba:	c979                	beqz	a0,80005790 <sys_unlink+0x114>
  ilock(dp);
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	236080e7          	jalr	566(ra) # 800038f2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056c4:	00003597          	auipc	a1,0x3
    800056c8:	03c58593          	add	a1,a1,60 # 80008700 <syscalls+0x2b0>
    800056cc:	fb040513          	add	a0,s0,-80
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	6ec080e7          	jalr	1772(ra) # 80003dbc <namecmp>
    800056d8:	14050a63          	beqz	a0,8000582c <sys_unlink+0x1b0>
    800056dc:	00003597          	auipc	a1,0x3
    800056e0:	02c58593          	add	a1,a1,44 # 80008708 <syscalls+0x2b8>
    800056e4:	fb040513          	add	a0,s0,-80
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	6d4080e7          	jalr	1748(ra) # 80003dbc <namecmp>
    800056f0:	12050e63          	beqz	a0,8000582c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056f4:	f2c40613          	add	a2,s0,-212
    800056f8:	fb040593          	add	a1,s0,-80
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	6d8080e7          	jalr	1752(ra) # 80003dd6 <dirlookup>
    80005706:	892a                	mv	s2,a0
    80005708:	12050263          	beqz	a0,8000582c <sys_unlink+0x1b0>
  ilock(ip);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	1e6080e7          	jalr	486(ra) # 800038f2 <ilock>
  if(ip->nlink < 1)
    80005714:	04a91783          	lh	a5,74(s2)
    80005718:	08f05263          	blez	a5,8000579c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000571c:	04491703          	lh	a4,68(s2)
    80005720:	4785                	li	a5,1
    80005722:	08f70563          	beq	a4,a5,800057ac <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005726:	4641                	li	a2,16
    80005728:	4581                	li	a1,0
    8000572a:	fc040513          	add	a0,s0,-64
    8000572e:	ffffb097          	auipc	ra,0xffffb
    80005732:	5a0080e7          	jalr	1440(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005736:	4741                	li	a4,16
    80005738:	f2c42683          	lw	a3,-212(s0)
    8000573c:	fc040613          	add	a2,s0,-64
    80005740:	4581                	li	a1,0
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	55a080e7          	jalr	1370(ra) # 80003c9e <writei>
    8000574c:	47c1                	li	a5,16
    8000574e:	0af51563          	bne	a0,a5,800057f8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005752:	04491703          	lh	a4,68(s2)
    80005756:	4785                	li	a5,1
    80005758:	0af70863          	beq	a4,a5,80005808 <sys_unlink+0x18c>
  iunlockput(dp);
    8000575c:	8526                	mv	a0,s1
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	3f6080e7          	jalr	1014(ra) # 80003b54 <iunlockput>
  ip->nlink--;
    80005766:	04a95783          	lhu	a5,74(s2)
    8000576a:	37fd                	addw	a5,a5,-1
    8000576c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005770:	854a                	mv	a0,s2
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	0b4080e7          	jalr	180(ra) # 80003826 <iupdate>
  iunlockput(ip);
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	3d8080e7          	jalr	984(ra) # 80003b54 <iunlockput>
  end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	b8e080e7          	jalr	-1138(ra) # 80004312 <end_op>
  return 0;
    8000578c:	4501                	li	a0,0
    8000578e:	a84d                	j	80005840 <sys_unlink+0x1c4>
    end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	b82080e7          	jalr	-1150(ra) # 80004312 <end_op>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	a05d                	j	80005840 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000579c:	00003517          	auipc	a0,0x3
    800057a0:	f7450513          	add	a0,a0,-140 # 80008710 <syscalls+0x2c0>
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	d98080e7          	jalr	-616(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ac:	04c92703          	lw	a4,76(s2)
    800057b0:	02000793          	li	a5,32
    800057b4:	f6e7f9e3          	bgeu	a5,a4,80005726 <sys_unlink+0xaa>
    800057b8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057bc:	4741                	li	a4,16
    800057be:	86ce                	mv	a3,s3
    800057c0:	f1840613          	add	a2,s0,-232
    800057c4:	4581                	li	a1,0
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	3de080e7          	jalr	990(ra) # 80003ba6 <readi>
    800057d0:	47c1                	li	a5,16
    800057d2:	00f51b63          	bne	a0,a5,800057e8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057d6:	f1845783          	lhu	a5,-232(s0)
    800057da:	e7a1                	bnez	a5,80005822 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057dc:	29c1                	addw	s3,s3,16
    800057de:	04c92783          	lw	a5,76(s2)
    800057e2:	fcf9ede3          	bltu	s3,a5,800057bc <sys_unlink+0x140>
    800057e6:	b781                	j	80005726 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e8:	00003517          	auipc	a0,0x3
    800057ec:	f4050513          	add	a0,a0,-192 # 80008728 <syscalls+0x2d8>
    800057f0:	ffffb097          	auipc	ra,0xffffb
    800057f4:	d4c080e7          	jalr	-692(ra) # 8000053c <panic>
    panic("unlink: writei");
    800057f8:	00003517          	auipc	a0,0x3
    800057fc:	f4850513          	add	a0,a0,-184 # 80008740 <syscalls+0x2f0>
    80005800:	ffffb097          	auipc	ra,0xffffb
    80005804:	d3c080e7          	jalr	-708(ra) # 8000053c <panic>
    dp->nlink--;
    80005808:	04a4d783          	lhu	a5,74(s1)
    8000580c:	37fd                	addw	a5,a5,-1
    8000580e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	012080e7          	jalr	18(ra) # 80003826 <iupdate>
    8000581c:	b781                	j	8000575c <sys_unlink+0xe0>
    return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	a005                	j	80005840 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	330080e7          	jalr	816(ra) # 80003b54 <iunlockput>
  iunlockput(dp);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	326080e7          	jalr	806(ra) # 80003b54 <iunlockput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	adc080e7          	jalr	-1316(ra) # 80004312 <end_op>
  return -1;
    8000583e:	557d                	li	a0,-1
}
    80005840:	70ae                	ld	ra,232(sp)
    80005842:	740e                	ld	s0,224(sp)
    80005844:	64ee                	ld	s1,216(sp)
    80005846:	694e                	ld	s2,208(sp)
    80005848:	69ae                	ld	s3,200(sp)
    8000584a:	616d                	add	sp,sp,240
    8000584c:	8082                	ret

000000008000584e <sys_open>:

uint64
sys_open(void)
{
    8000584e:	7131                	add	sp,sp,-192
    80005850:	fd06                	sd	ra,184(sp)
    80005852:	f922                	sd	s0,176(sp)
    80005854:	f526                	sd	s1,168(sp)
    80005856:	f14a                	sd	s2,160(sp)
    80005858:	ed4e                	sd	s3,152(sp)
    8000585a:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000585c:	f4c40593          	add	a1,s0,-180
    80005860:	4505                	li	a0,1
    80005862:	ffffd097          	auipc	ra,0xffffd
    80005866:	436080e7          	jalr	1078(ra) # 80002c98 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000586a:	08000613          	li	a2,128
    8000586e:	f5040593          	add	a1,s0,-176
    80005872:	4501                	li	a0,0
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	464080e7          	jalr	1124(ra) # 80002cd8 <argstr>
    8000587c:	87aa                	mv	a5,a0
    return -1;
    8000587e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005880:	0a07c863          	bltz	a5,80005930 <sys_open+0xe2>

  begin_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	a14080e7          	jalr	-1516(ra) # 80004298 <begin_op>

  if(omode & O_CREATE){
    8000588c:	f4c42783          	lw	a5,-180(s0)
    80005890:	2007f793          	and	a5,a5,512
    80005894:	cbdd                	beqz	a5,8000594a <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005896:	4681                	li	a3,0
    80005898:	4601                	li	a2,0
    8000589a:	4589                	li	a1,2
    8000589c:	f5040513          	add	a0,s0,-176
    800058a0:	00000097          	auipc	ra,0x0
    800058a4:	97a080e7          	jalr	-1670(ra) # 8000521a <create>
    800058a8:	84aa                	mv	s1,a0
    if(ip == 0){
    800058aa:	c951                	beqz	a0,8000593e <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058ac:	04449703          	lh	a4,68(s1)
    800058b0:	478d                	li	a5,3
    800058b2:	00f71763          	bne	a4,a5,800058c0 <sys_open+0x72>
    800058b6:	0464d703          	lhu	a4,70(s1)
    800058ba:	47a5                	li	a5,9
    800058bc:	0ce7ec63          	bltu	a5,a4,80005994 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	de0080e7          	jalr	-544(ra) # 800046a0 <filealloc>
    800058c8:	892a                	mv	s2,a0
    800058ca:	c56d                	beqz	a0,800059b4 <sys_open+0x166>
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	90c080e7          	jalr	-1780(ra) # 800051d8 <fdalloc>
    800058d4:	89aa                	mv	s3,a0
    800058d6:	0c054a63          	bltz	a0,800059aa <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058da:	04449703          	lh	a4,68(s1)
    800058de:	478d                	li	a5,3
    800058e0:	0ef70563          	beq	a4,a5,800059ca <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e4:	4789                	li	a5,2
    800058e6:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800058ea:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800058ee:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	0017c713          	xor	a4,a5,1
    800058fa:	8b05                	and	a4,a4,1
    800058fc:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005900:	0037f713          	and	a4,a5,3
    80005904:	00e03733          	snez	a4,a4
    80005908:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000590c:	4007f793          	and	a5,a5,1024
    80005910:	c791                	beqz	a5,8000591c <sys_open+0xce>
    80005912:	04449703          	lh	a4,68(s1)
    80005916:	4789                	li	a5,2
    80005918:	0cf70063          	beq	a4,a5,800059d8 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    8000591c:	8526                	mv	a0,s1
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	096080e7          	jalr	150(ra) # 800039b4 <iunlock>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	9ec080e7          	jalr	-1556(ra) # 80004312 <end_op>

  return fd;
    8000592e:	854e                	mv	a0,s3
}
    80005930:	70ea                	ld	ra,184(sp)
    80005932:	744a                	ld	s0,176(sp)
    80005934:	74aa                	ld	s1,168(sp)
    80005936:	790a                	ld	s2,160(sp)
    80005938:	69ea                	ld	s3,152(sp)
    8000593a:	6129                	add	sp,sp,192
    8000593c:	8082                	ret
      end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	9d4080e7          	jalr	-1580(ra) # 80004312 <end_op>
      return -1;
    80005946:	557d                	li	a0,-1
    80005948:	b7e5                	j	80005930 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    8000594a:	f5040513          	add	a0,s0,-176
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	74a080e7          	jalr	1866(ra) # 80004098 <namei>
    80005956:	84aa                	mv	s1,a0
    80005958:	c905                	beqz	a0,80005988 <sys_open+0x13a>
    ilock(ip);
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	f98080e7          	jalr	-104(ra) # 800038f2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005962:	04449703          	lh	a4,68(s1)
    80005966:	4785                	li	a5,1
    80005968:	f4f712e3          	bne	a4,a5,800058ac <sys_open+0x5e>
    8000596c:	f4c42783          	lw	a5,-180(s0)
    80005970:	dba1                	beqz	a5,800058c0 <sys_open+0x72>
      iunlockput(ip);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	1e0080e7          	jalr	480(ra) # 80003b54 <iunlockput>
      end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	996080e7          	jalr	-1642(ra) # 80004312 <end_op>
      return -1;
    80005984:	557d                	li	a0,-1
    80005986:	b76d                	j	80005930 <sys_open+0xe2>
      end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	98a080e7          	jalr	-1654(ra) # 80004312 <end_op>
      return -1;
    80005990:	557d                	li	a0,-1
    80005992:	bf79                	j	80005930 <sys_open+0xe2>
    iunlockput(ip);
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	1be080e7          	jalr	446(ra) # 80003b54 <iunlockput>
    end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	974080e7          	jalr	-1676(ra) # 80004312 <end_op>
    return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	b761                	j	80005930 <sys_open+0xe2>
      fileclose(f);
    800059aa:	854a                	mv	a0,s2
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	db0080e7          	jalr	-592(ra) # 8000475c <fileclose>
    iunlockput(ip);
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	19e080e7          	jalr	414(ra) # 80003b54 <iunlockput>
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	954080e7          	jalr	-1708(ra) # 80004312 <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7a5                	j	80005930 <sys_open+0xe2>
    f->type = FD_DEVICE;
    800059ca:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800059ce:	04649783          	lh	a5,70(s1)
    800059d2:	02f91223          	sh	a5,36(s2)
    800059d6:	bf21                	j	800058ee <sys_open+0xa0>
    itrunc(ip);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	026080e7          	jalr	38(ra) # 80003a00 <itrunc>
    800059e2:	bf2d                	j	8000591c <sys_open+0xce>

00000000800059e4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059e4:	7175                	add	sp,sp,-144
    800059e6:	e506                	sd	ra,136(sp)
    800059e8:	e122                	sd	s0,128(sp)
    800059ea:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8ac080e7          	jalr	-1876(ra) # 80004298 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059f4:	08000613          	li	a2,128
    800059f8:	f7040593          	add	a1,s0,-144
    800059fc:	4501                	li	a0,0
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	2da080e7          	jalr	730(ra) # 80002cd8 <argstr>
    80005a06:	02054963          	bltz	a0,80005a38 <sys_mkdir+0x54>
    80005a0a:	4681                	li	a3,0
    80005a0c:	4601                	li	a2,0
    80005a0e:	4585                	li	a1,1
    80005a10:	f7040513          	add	a0,s0,-144
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	806080e7          	jalr	-2042(ra) # 8000521a <create>
    80005a1c:	cd11                	beqz	a0,80005a38 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	136080e7          	jalr	310(ra) # 80003b54 <iunlockput>
  end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	8ec080e7          	jalr	-1812(ra) # 80004312 <end_op>
  return 0;
    80005a2e:	4501                	li	a0,0
}
    80005a30:	60aa                	ld	ra,136(sp)
    80005a32:	640a                	ld	s0,128(sp)
    80005a34:	6149                	add	sp,sp,144
    80005a36:	8082                	ret
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	8da080e7          	jalr	-1830(ra) # 80004312 <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b7fd                	j	80005a30 <sys_mkdir+0x4c>

0000000080005a44 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a44:	7135                	add	sp,sp,-160
    80005a46:	ed06                	sd	ra,152(sp)
    80005a48:	e922                	sd	s0,144(sp)
    80005a4a:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	84c080e7          	jalr	-1972(ra) # 80004298 <begin_op>
  argint(1, &major);
    80005a54:	f6c40593          	add	a1,s0,-148
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	23e080e7          	jalr	574(ra) # 80002c98 <argint>
  argint(2, &minor);
    80005a62:	f6840593          	add	a1,s0,-152
    80005a66:	4509                	li	a0,2
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	230080e7          	jalr	560(ra) # 80002c98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a70:	08000613          	li	a2,128
    80005a74:	f7040593          	add	a1,s0,-144
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	25e080e7          	jalr	606(ra) # 80002cd8 <argstr>
    80005a82:	02054b63          	bltz	a0,80005ab8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a86:	f6841683          	lh	a3,-152(s0)
    80005a8a:	f6c41603          	lh	a2,-148(s0)
    80005a8e:	458d                	li	a1,3
    80005a90:	f7040513          	add	a0,s0,-144
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	786080e7          	jalr	1926(ra) # 8000521a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9c:	cd11                	beqz	a0,80005ab8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	0b6080e7          	jalr	182(ra) # 80003b54 <iunlockput>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	86c080e7          	jalr	-1940(ra) # 80004312 <end_op>
  return 0;
    80005aae:	4501                	li	a0,0
}
    80005ab0:	60ea                	ld	ra,152(sp)
    80005ab2:	644a                	ld	s0,144(sp)
    80005ab4:	610d                	add	sp,sp,160
    80005ab6:	8082                	ret
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	85a080e7          	jalr	-1958(ra) # 80004312 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	b7fd                	j	80005ab0 <sys_mknod+0x6c>

0000000080005ac4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ac4:	7135                	add	sp,sp,-160
    80005ac6:	ed06                	sd	ra,152(sp)
    80005ac8:	e922                	sd	s0,144(sp)
    80005aca:	e526                	sd	s1,136(sp)
    80005acc:	e14a                	sd	s2,128(sp)
    80005ace:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad0:	ffffc097          	auipc	ra,0xffffc
    80005ad4:	ed6080e7          	jalr	-298(ra) # 800019a6 <myproc>
    80005ad8:	892a                	mv	s2,a0
  
  begin_op();
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	7be080e7          	jalr	1982(ra) # 80004298 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ae2:	08000613          	li	a2,128
    80005ae6:	f6040593          	add	a1,s0,-160
    80005aea:	4501                	li	a0,0
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	1ec080e7          	jalr	492(ra) # 80002cd8 <argstr>
    80005af4:	04054b63          	bltz	a0,80005b4a <sys_chdir+0x86>
    80005af8:	f6040513          	add	a0,s0,-160
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	59c080e7          	jalr	1436(ra) # 80004098 <namei>
    80005b04:	84aa                	mv	s1,a0
    80005b06:	c131                	beqz	a0,80005b4a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	dea080e7          	jalr	-534(ra) # 800038f2 <ilock>
  if(ip->type != T_DIR){
    80005b10:	04449703          	lh	a4,68(s1)
    80005b14:	4785                	li	a5,1
    80005b16:	04f71063          	bne	a4,a5,80005b56 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	e98080e7          	jalr	-360(ra) # 800039b4 <iunlock>
  iput(p->cwd);
    80005b24:	15093503          	ld	a0,336(s2)
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	f84080e7          	jalr	-124(ra) # 80003aac <iput>
  end_op();
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	7e2080e7          	jalr	2018(ra) # 80004312 <end_op>
  p->cwd = ip;
    80005b38:	14993823          	sd	s1,336(s2)
  return 0;
    80005b3c:	4501                	li	a0,0
}
    80005b3e:	60ea                	ld	ra,152(sp)
    80005b40:	644a                	ld	s0,144(sp)
    80005b42:	64aa                	ld	s1,136(sp)
    80005b44:	690a                	ld	s2,128(sp)
    80005b46:	610d                	add	sp,sp,160
    80005b48:	8082                	ret
    end_op();
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	7c8080e7          	jalr	1992(ra) # 80004312 <end_op>
    return -1;
    80005b52:	557d                	li	a0,-1
    80005b54:	b7ed                	j	80005b3e <sys_chdir+0x7a>
    iunlockput(ip);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	ffc080e7          	jalr	-4(ra) # 80003b54 <iunlockput>
    end_op();
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	7b2080e7          	jalr	1970(ra) # 80004312 <end_op>
    return -1;
    80005b68:	557d                	li	a0,-1
    80005b6a:	bfd1                	j	80005b3e <sys_chdir+0x7a>

0000000080005b6c <sys_exec>:

uint64
sys_exec(void)
{
    80005b6c:	7121                	add	sp,sp,-448
    80005b6e:	ff06                	sd	ra,440(sp)
    80005b70:	fb22                	sd	s0,432(sp)
    80005b72:	f726                	sd	s1,424(sp)
    80005b74:	f34a                	sd	s2,416(sp)
    80005b76:	ef4e                	sd	s3,408(sp)
    80005b78:	eb52                	sd	s4,400(sp)
    80005b7a:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b7c:	e4840593          	add	a1,s0,-440
    80005b80:	4505                	li	a0,1
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	136080e7          	jalr	310(ra) # 80002cb8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b8a:	08000613          	li	a2,128
    80005b8e:	f5040593          	add	a1,s0,-176
    80005b92:	4501                	li	a0,0
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	144080e7          	jalr	324(ra) # 80002cd8 <argstr>
    80005b9c:	87aa                	mv	a5,a0
    return -1;
    80005b9e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ba0:	0c07c263          	bltz	a5,80005c64 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005ba4:	10000613          	li	a2,256
    80005ba8:	4581                	li	a1,0
    80005baa:	e5040513          	add	a0,s0,-432
    80005bae:	ffffb097          	auipc	ra,0xffffb
    80005bb2:	120080e7          	jalr	288(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb6:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005bba:	89a6                	mv	s3,s1
    80005bbc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bbe:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391513          	sll	a0,s2,0x3
    80005bc6:	e4040593          	add	a1,s0,-448
    80005bca:	e4843783          	ld	a5,-440(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	02a080e7          	jalr	42(ra) # 80002bfa <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e4043783          	ld	a5,-448(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f00080e7          	jalr	-256(ra) # 80000ae2 <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e4043503          	ld	a0,-448(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	054080e7          	jalr	84(ra) # 80002c4c <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005c04:	0905                	add	s2,s2,1
    80005c06:	09a1                	add	s3,s3,8
    80005c08:	fb491de3          	bne	s2,s4,80005bc2 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	f5040913          	add	s2,s0,-176
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c921                	beqz	a0,80005c62 <sys_exec+0xf6>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	dd0080e7          	jalr	-560(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	add	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xa4>
  return -1;
    80005c22:	557d                	li	a0,-1
    80005c24:	a081                	j	80005c64 <sys_exec+0xf8>
      argv[i] = 0;
    80005c26:	0009079b          	sext.w	a5,s2
    80005c2a:	078e                	sll	a5,a5,0x3
    80005c2c:	fd078793          	add	a5,a5,-48
    80005c30:	97a2                	add	a5,a5,s0
    80005c32:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005c36:	e5040593          	add	a1,s0,-432
    80005c3a:	f5040513          	add	a0,s0,-176
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	194080e7          	jalr	404(ra) # 80004dd2 <exec>
    80005c46:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c48:	f5040993          	add	s3,s0,-176
    80005c4c:	6088                	ld	a0,0(s1)
    80005c4e:	c901                	beqz	a0,80005c5e <sys_exec+0xf2>
    kfree(argv[i]);
    80005c50:	ffffb097          	auipc	ra,0xffffb
    80005c54:	d94080e7          	jalr	-620(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c58:	04a1                	add	s1,s1,8
    80005c5a:	ff3499e3          	bne	s1,s3,80005c4c <sys_exec+0xe0>
  return ret;
    80005c5e:	854a                	mv	a0,s2
    80005c60:	a011                	j	80005c64 <sys_exec+0xf8>
  return -1;
    80005c62:	557d                	li	a0,-1
}
    80005c64:	70fa                	ld	ra,440(sp)
    80005c66:	745a                	ld	s0,432(sp)
    80005c68:	74ba                	ld	s1,424(sp)
    80005c6a:	791a                	ld	s2,416(sp)
    80005c6c:	69fa                	ld	s3,408(sp)
    80005c6e:	6a5a                	ld	s4,400(sp)
    80005c70:	6139                	add	sp,sp,448
    80005c72:	8082                	ret

0000000080005c74 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c74:	7139                	add	sp,sp,-64
    80005c76:	fc06                	sd	ra,56(sp)
    80005c78:	f822                	sd	s0,48(sp)
    80005c7a:	f426                	sd	s1,40(sp)
    80005c7c:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	d28080e7          	jalr	-728(ra) # 800019a6 <myproc>
    80005c86:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c88:	fd840593          	add	a1,s0,-40
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	02a080e7          	jalr	42(ra) # 80002cb8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c96:	fc840593          	add	a1,s0,-56
    80005c9a:	fd040513          	add	a0,s0,-48
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	dea080e7          	jalr	-534(ra) # 80004a88 <pipealloc>
    return -1;
    80005ca6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ca8:	0c054463          	bltz	a0,80005d70 <sys_pipe+0xfc>
  fd0 = -1;
    80005cac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb0:	fd043503          	ld	a0,-48(s0)
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	524080e7          	jalr	1316(ra) # 800051d8 <fdalloc>
    80005cbc:	fca42223          	sw	a0,-60(s0)
    80005cc0:	08054b63          	bltz	a0,80005d56 <sys_pipe+0xe2>
    80005cc4:	fc843503          	ld	a0,-56(s0)
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	510080e7          	jalr	1296(ra) # 800051d8 <fdalloc>
    80005cd0:	fca42023          	sw	a0,-64(s0)
    80005cd4:	06054863          	bltz	a0,80005d44 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd8:	4691                	li	a3,4
    80005cda:	fc440613          	add	a2,s0,-60
    80005cde:	fd843583          	ld	a1,-40(s0)
    80005ce2:	68a8                	ld	a0,80(s1)
    80005ce4:	ffffc097          	auipc	ra,0xffffc
    80005ce8:	982080e7          	jalr	-1662(ra) # 80001666 <copyout>
    80005cec:	02054063          	bltz	a0,80005d0c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf0:	4691                	li	a3,4
    80005cf2:	fc040613          	add	a2,s0,-64
    80005cf6:	fd843583          	ld	a1,-40(s0)
    80005cfa:	0591                	add	a1,a1,4
    80005cfc:	68a8                	ld	a0,80(s1)
    80005cfe:	ffffc097          	auipc	ra,0xffffc
    80005d02:	968080e7          	jalr	-1688(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d06:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d08:	06055463          	bgez	a0,80005d70 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d0c:	fc442783          	lw	a5,-60(s0)
    80005d10:	07e9                	add	a5,a5,26
    80005d12:	078e                	sll	a5,a5,0x3
    80005d14:	97a6                	add	a5,a5,s1
    80005d16:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1a:	fc042783          	lw	a5,-64(s0)
    80005d1e:	07e9                	add	a5,a5,26
    80005d20:	078e                	sll	a5,a5,0x3
    80005d22:	94be                	add	s1,s1,a5
    80005d24:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d28:	fd043503          	ld	a0,-48(s0)
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	a30080e7          	jalr	-1488(ra) # 8000475c <fileclose>
    fileclose(wf);
    80005d34:	fc843503          	ld	a0,-56(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	a24080e7          	jalr	-1500(ra) # 8000475c <fileclose>
    return -1;
    80005d40:	57fd                	li	a5,-1
    80005d42:	a03d                	j	80005d70 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d44:	fc442783          	lw	a5,-60(s0)
    80005d48:	0007c763          	bltz	a5,80005d56 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d4c:	07e9                	add	a5,a5,26
    80005d4e:	078e                	sll	a5,a5,0x3
    80005d50:	97a6                	add	a5,a5,s1
    80005d52:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005d56:	fd043503          	ld	a0,-48(s0)
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	a02080e7          	jalr	-1534(ra) # 8000475c <fileclose>
    fileclose(wf);
    80005d62:	fc843503          	ld	a0,-56(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	9f6080e7          	jalr	-1546(ra) # 8000475c <fileclose>
    return -1;
    80005d6e:	57fd                	li	a5,-1
}
    80005d70:	853e                	mv	a0,a5
    80005d72:	70e2                	ld	ra,56(sp)
    80005d74:	7442                	ld	s0,48(sp)
    80005d76:	74a2                	ld	s1,40(sp)
    80005d78:	6121                	add	sp,sp,64
    80005d7a:	8082                	ret
    80005d7c:	0000                	unimp
	...

0000000080005d80 <kernelvec>:
    80005d80:	7111                	add	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	d07fc0ef          	jal	80002ac6 <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	add	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	add	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	add	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	add	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b22080e7          	jalr	-1246(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	sllw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	sllw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	97aa                	add	a5,a5,a0
    80005e7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	add	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	add	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	aea080e7          	jalr	-1302(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5151b          	sllw	a0,a0,0xd
    80005e9c:	0c2017b7          	lui	a5,0xc201
    80005ea0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ea2:	43c8                	lw	a0,4(a5)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	add	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	add	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	add	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ac2080e7          	jalr	-1342(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	sllw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	add	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	add	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	add	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	04a7cc63          	blt	a5,a0,80005f38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	0001c797          	auipc	a5,0x1c
    80005ee8:	1cc78793          	add	a5,a5,460 # 800220b0 <disk>
    80005eec:	97aa                	add	a5,a5,a0
    80005eee:	0187c783          	lbu	a5,24(a5)
    80005ef2:	ebb9                	bnez	a5,80005f48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ef4:	00451693          	sll	a3,a0,0x4
    80005ef8:	0001c797          	auipc	a5,0x1c
    80005efc:	1b878793          	add	a5,a5,440 # 800220b0 <disk>
    80005f00:	6398                	ld	a4,0(a5)
    80005f02:	9736                	add	a4,a4,a3
    80005f04:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005f08:	6398                	ld	a4,0(a5)
    80005f0a:	9736                	add	a4,a4,a3
    80005f0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f18:	97aa                	add	a5,a5,a0
    80005f1a:	4705                	li	a4,1
    80005f1c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005f20:	0001c517          	auipc	a0,0x1c
    80005f24:	1a850513          	add	a0,a0,424 # 800220c8 <disk+0x18>
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	19e080e7          	jalr	414(ra) # 800020c6 <wakeup>
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	add	sp,sp,16
    80005f36:	8082                	ret
    panic("free_desc 1");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	81850513          	add	a0,a0,-2024 # 80008750 <syscalls+0x300>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	5fc080e7          	jalr	1532(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	81850513          	add	a0,a0,-2024 # 80008760 <syscalls+0x310>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5ec080e7          	jalr	1516(ra) # 8000053c <panic>

0000000080005f58 <virtio_disk_init>:
{
    80005f58:	1101                	add	sp,sp,-32
    80005f5a:	ec06                	sd	ra,24(sp)
    80005f5c:	e822                	sd	s0,16(sp)
    80005f5e:	e426                	sd	s1,8(sp)
    80005f60:	e04a                	sd	s2,0(sp)
    80005f62:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f64:	00003597          	auipc	a1,0x3
    80005f68:	80c58593          	add	a1,a1,-2036 # 80008770 <syscalls+0x320>
    80005f6c:	0001c517          	auipc	a0,0x1c
    80005f70:	26c50513          	add	a0,a0,620 # 800221d8 <disk+0x128>
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	bce080e7          	jalr	-1074(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f7c:	100017b7          	lui	a5,0x10001
    80005f80:	4398                	lw	a4,0(a5)
    80005f82:	2701                	sext.w	a4,a4
    80005f84:	747277b7          	lui	a5,0x74727
    80005f88:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f8c:	14f71b63          	bne	a4,a5,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f90:	100017b7          	lui	a5,0x10001
    80005f94:	43dc                	lw	a5,4(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f98:	4709                	li	a4,2
    80005f9a:	14e79463          	bne	a5,a4,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	479c                	lw	a5,8(a5)
    80005fa4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fa6:	12e79e63          	bne	a5,a4,800060e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005faa:	100017b7          	lui	a5,0x10001
    80005fae:	47d8                	lw	a4,12(a5)
    80005fb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb2:	554d47b7          	lui	a5,0x554d4
    80005fb6:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fba:	12f71463          	bne	a4,a5,800060e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc6:	4705                	li	a4,1
    80005fc8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fca:	470d                	li	a4,3
    80005fcc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fd0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005fd4:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc56f>
    80005fd8:	8f75                	and	a4,a4,a3
    80005fda:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fdc:	472d                	li	a4,11
    80005fde:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fe0:	5bbc                	lw	a5,112(a5)
    80005fe2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fe6:	8ba1                	and	a5,a5,8
    80005fe8:	10078563          	beqz	a5,800060f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fec:	100017b7          	lui	a5,0x10001
    80005ff0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ff4:	43fc                	lw	a5,68(a5)
    80005ff6:	2781                	sext.w	a5,a5
    80005ff8:	10079563          	bnez	a5,80006102 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ffc:	100017b7          	lui	a5,0x10001
    80006000:	5bdc                	lw	a5,52(a5)
    80006002:	2781                	sext.w	a5,a5
  if(max == 0)
    80006004:	10078763          	beqz	a5,80006112 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006008:	471d                	li	a4,7
    8000600a:	10f77c63          	bgeu	a4,a5,80006122 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	ad4080e7          	jalr	-1324(ra) # 80000ae2 <kalloc>
    80006016:	0001c497          	auipc	s1,0x1c
    8000601a:	09a48493          	add	s1,s1,154 # 800220b0 <disk>
    8000601e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	ac2080e7          	jalr	-1342(ra) # 80000ae2 <kalloc>
    80006028:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000602a:	ffffb097          	auipc	ra,0xffffb
    8000602e:	ab8080e7          	jalr	-1352(ra) # 80000ae2 <kalloc>
    80006032:	87aa                	mv	a5,a0
    80006034:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006036:	6088                	ld	a0,0(s1)
    80006038:	cd6d                	beqz	a0,80006132 <virtio_disk_init+0x1da>
    8000603a:	0001c717          	auipc	a4,0x1c
    8000603e:	07e73703          	ld	a4,126(a4) # 800220b8 <disk+0x8>
    80006042:	cb65                	beqz	a4,80006132 <virtio_disk_init+0x1da>
    80006044:	c7fd                	beqz	a5,80006132 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006046:	6605                	lui	a2,0x1
    80006048:	4581                	li	a1,0
    8000604a:	ffffb097          	auipc	ra,0xffffb
    8000604e:	c84080e7          	jalr	-892(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80006052:	0001c497          	auipc	s1,0x1c
    80006056:	05e48493          	add	s1,s1,94 # 800220b0 <disk>
    8000605a:	6605                	lui	a2,0x1
    8000605c:	4581                	li	a1,0
    8000605e:	6488                	ld	a0,8(s1)
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	c6e080e7          	jalr	-914(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80006068:	6605                	lui	a2,0x1
    8000606a:	4581                	li	a1,0
    8000606c:	6888                	ld	a0,16(s1)
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	c60080e7          	jalr	-928(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006076:	100017b7          	lui	a5,0x10001
    8000607a:	4721                	li	a4,8
    8000607c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000607e:	4098                	lw	a4,0(s1)
    80006080:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006084:	40d8                	lw	a4,4(s1)
    80006086:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000608a:	6498                	ld	a4,8(s1)
    8000608c:	0007069b          	sext.w	a3,a4
    80006090:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006094:	9701                	sra	a4,a4,0x20
    80006096:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000609a:	6898                	ld	a4,16(s1)
    8000609c:	0007069b          	sext.w	a3,a4
    800060a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060a4:	9701                	sra	a4,a4,0x20
    800060a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060aa:	4705                	li	a4,1
    800060ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060ae:	00e48c23          	sb	a4,24(s1)
    800060b2:	00e48ca3          	sb	a4,25(s1)
    800060b6:	00e48d23          	sb	a4,26(s1)
    800060ba:	00e48da3          	sb	a4,27(s1)
    800060be:	00e48e23          	sb	a4,28(s1)
    800060c2:	00e48ea3          	sb	a4,29(s1)
    800060c6:	00e48f23          	sb	a4,30(s1)
    800060ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060ce:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d2:	0727a823          	sw	s2,112(a5)
}
    800060d6:	60e2                	ld	ra,24(sp)
    800060d8:	6442                	ld	s0,16(sp)
    800060da:	64a2                	ld	s1,8(sp)
    800060dc:	6902                	ld	s2,0(sp)
    800060de:	6105                	add	sp,sp,32
    800060e0:	8082                	ret
    panic("could not find virtio disk");
    800060e2:	00002517          	auipc	a0,0x2
    800060e6:	69e50513          	add	a0,a0,1694 # 80008780 <syscalls+0x330>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	452080e7          	jalr	1106(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800060f2:	00002517          	auipc	a0,0x2
    800060f6:	6ae50513          	add	a0,a0,1710 # 800087a0 <syscalls+0x350>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	442080e7          	jalr	1090(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006102:	00002517          	auipc	a0,0x2
    80006106:	6be50513          	add	a0,a0,1726 # 800087c0 <syscalls+0x370>
    8000610a:	ffffa097          	auipc	ra,0xffffa
    8000610e:	432080e7          	jalr	1074(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006112:	00002517          	auipc	a0,0x2
    80006116:	6ce50513          	add	a0,a0,1742 # 800087e0 <syscalls+0x390>
    8000611a:	ffffa097          	auipc	ra,0xffffa
    8000611e:	422080e7          	jalr	1058(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006122:	00002517          	auipc	a0,0x2
    80006126:	6de50513          	add	a0,a0,1758 # 80008800 <syscalls+0x3b0>
    8000612a:	ffffa097          	auipc	ra,0xffffa
    8000612e:	412080e7          	jalr	1042(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006132:	00002517          	auipc	a0,0x2
    80006136:	6ee50513          	add	a0,a0,1774 # 80008820 <syscalls+0x3d0>
    8000613a:	ffffa097          	auipc	ra,0xffffa
    8000613e:	402080e7          	jalr	1026(ra) # 8000053c <panic>

0000000080006142 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006142:	7159                	add	sp,sp,-112
    80006144:	f486                	sd	ra,104(sp)
    80006146:	f0a2                	sd	s0,96(sp)
    80006148:	eca6                	sd	s1,88(sp)
    8000614a:	e8ca                	sd	s2,80(sp)
    8000614c:	e4ce                	sd	s3,72(sp)
    8000614e:	e0d2                	sd	s4,64(sp)
    80006150:	fc56                	sd	s5,56(sp)
    80006152:	f85a                	sd	s6,48(sp)
    80006154:	f45e                	sd	s7,40(sp)
    80006156:	f062                	sd	s8,32(sp)
    80006158:	ec66                	sd	s9,24(sp)
    8000615a:	e86a                	sd	s10,16(sp)
    8000615c:	1880                	add	s0,sp,112
    8000615e:	8a2a                	mv	s4,a0
    80006160:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006162:	00c52c83          	lw	s9,12(a0)
    80006166:	001c9c9b          	sllw	s9,s9,0x1
    8000616a:	1c82                	sll	s9,s9,0x20
    8000616c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006170:	0001c517          	auipc	a0,0x1c
    80006174:	06850513          	add	a0,a0,104 # 800221d8 <disk+0x128>
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	a5a080e7          	jalr	-1446(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006180:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006182:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006184:	0001cb17          	auipc	s6,0x1c
    80006188:	f2cb0b13          	add	s6,s6,-212 # 800220b0 <disk>
  for(int i = 0; i < 3; i++){
    8000618c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000618e:	0001cc17          	auipc	s8,0x1c
    80006192:	04ac0c13          	add	s8,s8,74 # 800221d8 <disk+0x128>
    80006196:	a095                	j	800061fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006198:	00fb0733          	add	a4,s6,a5
    8000619c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061a0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800061a2:	0207c563          	bltz	a5,800061cc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800061a6:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800061a8:	0591                	add	a1,a1,4
    800061aa:	05560d63          	beq	a2,s5,80006204 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061ae:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800061b0:	0001c717          	auipc	a4,0x1c
    800061b4:	f0070713          	add	a4,a4,-256 # 800220b0 <disk>
    800061b8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800061ba:	01874683          	lbu	a3,24(a4)
    800061be:	fee9                	bnez	a3,80006198 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800061c0:	2785                	addw	a5,a5,1
    800061c2:	0705                	add	a4,a4,1
    800061c4:	fe979be3          	bne	a5,s1,800061ba <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800061c8:	57fd                	li	a5,-1
    800061ca:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800061cc:	00c05e63          	blez	a2,800061e8 <virtio_disk_rw+0xa6>
    800061d0:	060a                	sll	a2,a2,0x2
    800061d2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800061d6:	0009a503          	lw	a0,0(s3)
    800061da:	00000097          	auipc	ra,0x0
    800061de:	cfc080e7          	jalr	-772(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    800061e2:	0991                	add	s3,s3,4
    800061e4:	ffa999e3          	bne	s3,s10,800061d6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061e8:	85e2                	mv	a1,s8
    800061ea:	0001c517          	auipc	a0,0x1c
    800061ee:	ede50513          	add	a0,a0,-290 # 800220c8 <disk+0x18>
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	e70080e7          	jalr	-400(ra) # 80002062 <sleep>
  for(int i = 0; i < 3; i++){
    800061fa:	f9040993          	add	s3,s0,-112
{
    800061fe:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006200:	864a                	mv	a2,s2
    80006202:	b775                	j	800061ae <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006204:	f9042503          	lw	a0,-112(s0)
    80006208:	00a50713          	add	a4,a0,10
    8000620c:	0712                	sll	a4,a4,0x4

  if(write)
    8000620e:	0001c797          	auipc	a5,0x1c
    80006212:	ea278793          	add	a5,a5,-350 # 800220b0 <disk>
    80006216:	00e786b3          	add	a3,a5,a4
    8000621a:	01703633          	snez	a2,s7
    8000621e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006220:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006224:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006228:	f6070613          	add	a2,a4,-160
    8000622c:	6394                	ld	a3,0(a5)
    8000622e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006230:	00870593          	add	a1,a4,8
    80006234:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006236:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006238:	0007b803          	ld	a6,0(a5)
    8000623c:	9642                	add	a2,a2,a6
    8000623e:	46c1                	li	a3,16
    80006240:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006242:	4585                	li	a1,1
    80006244:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006248:	f9442683          	lw	a3,-108(s0)
    8000624c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006250:	0692                	sll	a3,a3,0x4
    80006252:	9836                	add	a6,a6,a3
    80006254:	058a0613          	add	a2,s4,88
    80006258:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000625c:	0007b803          	ld	a6,0(a5)
    80006260:	96c2                	add	a3,a3,a6
    80006262:	40000613          	li	a2,1024
    80006266:	c690                	sw	a2,8(a3)
  if(write)
    80006268:	001bb613          	seqz	a2,s7
    8000626c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006270:	00166613          	or	a2,a2,1
    80006274:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006278:	f9842603          	lw	a2,-104(s0)
    8000627c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006280:	00250693          	add	a3,a0,2
    80006284:	0692                	sll	a3,a3,0x4
    80006286:	96be                	add	a3,a3,a5
    80006288:	58fd                	li	a7,-1
    8000628a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000628e:	0612                	sll	a2,a2,0x4
    80006290:	9832                	add	a6,a6,a2
    80006292:	f9070713          	add	a4,a4,-112
    80006296:	973e                	add	a4,a4,a5
    80006298:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000629c:	6398                	ld	a4,0(a5)
    8000629e:	9732                	add	a4,a4,a2
    800062a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062a2:	4609                	li	a2,2
    800062a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800062a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062ac:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800062b0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062b4:	6794                	ld	a3,8(a5)
    800062b6:	0026d703          	lhu	a4,2(a3)
    800062ba:	8b1d                	and	a4,a4,7
    800062bc:	0706                	sll	a4,a4,0x1
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800062c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062c8:	6798                	ld	a4,8(a5)
    800062ca:	00275783          	lhu	a5,2(a4)
    800062ce:	2785                	addw	a5,a5,1
    800062d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062e0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800062e4:	0001c917          	auipc	s2,0x1c
    800062e8:	ef490913          	add	s2,s2,-268 # 800221d8 <disk+0x128>
  while(b->disk == 1) {
    800062ec:	4485                	li	s1,1
    800062ee:	00b79c63          	bne	a5,a1,80006306 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062f2:	85ca                	mv	a1,s2
    800062f4:	8552                	mv	a0,s4
    800062f6:	ffffc097          	auipc	ra,0xffffc
    800062fa:	d6c080e7          	jalr	-660(ra) # 80002062 <sleep>
  while(b->disk == 1) {
    800062fe:	004a2783          	lw	a5,4(s4)
    80006302:	fe9788e3          	beq	a5,s1,800062f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006306:	f9042903          	lw	s2,-112(s0)
    8000630a:	00290713          	add	a4,s2,2
    8000630e:	0712                	sll	a4,a4,0x4
    80006310:	0001c797          	auipc	a5,0x1c
    80006314:	da078793          	add	a5,a5,-608 # 800220b0 <disk>
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000631e:	0001c997          	auipc	s3,0x1c
    80006322:	d9298993          	add	s3,s3,-622 # 800220b0 <disk>
    80006326:	00491713          	sll	a4,s2,0x4
    8000632a:	0009b783          	ld	a5,0(s3)
    8000632e:	97ba                	add	a5,a5,a4
    80006330:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006334:	854a                	mv	a0,s2
    80006336:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000633a:	00000097          	auipc	ra,0x0
    8000633e:	b9c080e7          	jalr	-1124(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006342:	8885                	and	s1,s1,1
    80006344:	f0ed                	bnez	s1,80006326 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006346:	0001c517          	auipc	a0,0x1c
    8000634a:	e9250513          	add	a0,a0,-366 # 800221d8 <disk+0x128>
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	938080e7          	jalr	-1736(ra) # 80000c86 <release>
}
    80006356:	70a6                	ld	ra,104(sp)
    80006358:	7406                	ld	s0,96(sp)
    8000635a:	64e6                	ld	s1,88(sp)
    8000635c:	6946                	ld	s2,80(sp)
    8000635e:	69a6                	ld	s3,72(sp)
    80006360:	6a06                	ld	s4,64(sp)
    80006362:	7ae2                	ld	s5,56(sp)
    80006364:	7b42                	ld	s6,48(sp)
    80006366:	7ba2                	ld	s7,40(sp)
    80006368:	7c02                	ld	s8,32(sp)
    8000636a:	6ce2                	ld	s9,24(sp)
    8000636c:	6d42                	ld	s10,16(sp)
    8000636e:	6165                	add	sp,sp,112
    80006370:	8082                	ret

0000000080006372 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006372:	1101                	add	sp,sp,-32
    80006374:	ec06                	sd	ra,24(sp)
    80006376:	e822                	sd	s0,16(sp)
    80006378:	e426                	sd	s1,8(sp)
    8000637a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000637c:	0001c497          	auipc	s1,0x1c
    80006380:	d3448493          	add	s1,s1,-716 # 800220b0 <disk>
    80006384:	0001c517          	auipc	a0,0x1c
    80006388:	e5450513          	add	a0,a0,-428 # 800221d8 <disk+0x128>
    8000638c:	ffffb097          	auipc	ra,0xffffb
    80006390:	846080e7          	jalr	-1978(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006394:	10001737          	lui	a4,0x10001
    80006398:	533c                	lw	a5,96(a4)
    8000639a:	8b8d                	and	a5,a5,3
    8000639c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000639e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063a2:	689c                	ld	a5,16(s1)
    800063a4:	0204d703          	lhu	a4,32(s1)
    800063a8:	0027d783          	lhu	a5,2(a5)
    800063ac:	04f70863          	beq	a4,a5,800063fc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063b0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063b4:	6898                	ld	a4,16(s1)
    800063b6:	0204d783          	lhu	a5,32(s1)
    800063ba:	8b9d                	and	a5,a5,7
    800063bc:	078e                	sll	a5,a5,0x3
    800063be:	97ba                	add	a5,a5,a4
    800063c0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063c2:	00278713          	add	a4,a5,2
    800063c6:	0712                	sll	a4,a4,0x4
    800063c8:	9726                	add	a4,a4,s1
    800063ca:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063ce:	e721                	bnez	a4,80006416 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063d0:	0789                	add	a5,a5,2
    800063d2:	0792                	sll	a5,a5,0x4
    800063d4:	97a6                	add	a5,a5,s1
    800063d6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063dc:	ffffc097          	auipc	ra,0xffffc
    800063e0:	cea080e7          	jalr	-790(ra) # 800020c6 <wakeup>

    disk.used_idx += 1;
    800063e4:	0204d783          	lhu	a5,32(s1)
    800063e8:	2785                	addw	a5,a5,1
    800063ea:	17c2                	sll	a5,a5,0x30
    800063ec:	93c1                	srl	a5,a5,0x30
    800063ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063f2:	6898                	ld	a4,16(s1)
    800063f4:	00275703          	lhu	a4,2(a4)
    800063f8:	faf71ce3          	bne	a4,a5,800063b0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063fc:	0001c517          	auipc	a0,0x1c
    80006400:	ddc50513          	add	a0,a0,-548 # 800221d8 <disk+0x128>
    80006404:	ffffb097          	auipc	ra,0xffffb
    80006408:	882080e7          	jalr	-1918(ra) # 80000c86 <release>
}
    8000640c:	60e2                	ld	ra,24(sp)
    8000640e:	6442                	ld	s0,16(sp)
    80006410:	64a2                	ld	s1,8(sp)
    80006412:	6105                	add	sp,sp,32
    80006414:	8082                	ret
      panic("virtio_disk_intr status");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	42250513          	add	a0,a0,1058 # 80008838 <syscalls+0x3e8>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	11e080e7          	jalr	286(ra) # 8000053c <panic>
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
