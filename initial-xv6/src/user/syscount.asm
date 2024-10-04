
user/_syscount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <getSyscallName>:
#include "user/user.h"
#include "kernel/syscall.h"

// Function to map the mask to the corresponding syscall name
const char *getSyscallName(int mask)
{
   0:	1141                	add	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	add	s0,sp,16
    switch (mask)
   6:	6705                	lui	a4,0x1
   8:	18e50b63          	beq	a0,a4,19e <getSyscallName+0x19e>
   c:	87aa                	mv	a5,a0
   e:	04a75363          	bge	a4,a0,54 <getSyscallName+0x54>
  12:	00040737          	lui	a4,0x40
  16:	1ae50d63          	beq	a0,a4,1d0 <getSyscallName+0x1d0>
  1a:	0ea75263          	bge	a4,a0,fe <getSyscallName+0xfe>
  1e:	00200737          	lui	a4,0x200
  22:	1ce50163          	beq	a0,a4,1e4 <getSyscallName+0x1e4>
  26:	12a75863          	bge	a4,a0,156 <getSyscallName+0x156>
  2a:	00400737          	lui	a4,0x400
    case (1 << (SYS_mkdir)):
        return "mkdir";
    case (1 << (SYS_close)):
        return "close";
    case (1 << (SYS_waitx)):
        return "waitx";
  2e:	00001517          	auipc	a0,0x1
  32:	b0a50513          	add	a0,a0,-1270 # b38 <malloc+0x192>
    switch (mask)
  36:	0ae78c63          	beq	a5,a4,ee <getSyscallName+0xee>
  3a:	00800737          	lui	a4,0x800
    case (1 << (SYS_getSysCount)):
        return "getSysCount";
  3e:	00001517          	auipc	a0,0x1
  42:	b0250513          	add	a0,a0,-1278 # b40 <malloc+0x19a>
    switch (mask)
  46:	0ae78463          	beq	a5,a4,ee <getSyscallName+0xee>
    default:
        return "unknown";
  4a:	00001517          	auipc	a0,0x1
  4e:	a4e50513          	add	a0,a0,-1458 # a98 <malloc+0xf2>
  52:	a871                	j	ee <getSyscallName+0xee>
    switch (mask)
  54:	04000713          	li	a4,64
  58:	14e50863          	beq	a0,a4,1a8 <getSyscallName+0x1a8>
  5c:	02a75c63          	bge	a4,a0,94 <getSyscallName+0x94>
  60:	20000713          	li	a4,512
  64:	16e50163          	beq	a0,a4,1c6 <getSyscallName+0x1c6>
  68:	06a75363          	bge	a4,a0,ce <getSyscallName+0xce>
  6c:	40000713          	li	a4,1024
        return "dup";
  70:	00001517          	auipc	a0,0x1
  74:	a6850513          	add	a0,a0,-1432 # ad8 <malloc+0x132>
    switch (mask)
  78:	06e78b63          	beq	a5,a4,ee <getSyscallName+0xee>
  7c:	8007879b          	addw	a5,a5,-2048
        return "getpid";
  80:	00001517          	auipc	a0,0x1
  84:	a6050513          	add	a0,a0,-1440 # ae0 <malloc+0x13a>
    switch (mask)
  88:	c3bd                	beqz	a5,ee <getSyscallName+0xee>
        return "unknown";
  8a:	00001517          	auipc	a0,0x1
  8e:	a0e50513          	add	a0,a0,-1522 # a98 <malloc+0xf2>
  92:	a8b1                	j	ee <getSyscallName+0xee>
    switch (mask)
  94:	ffe5071b          	addw	a4,a0,-2
  98:	46f9                	li	a3,30
  9a:	10e6ec63          	bltu	a3,a4,1b2 <getSyscallName+0x1b2>
  9e:	02000713          	li	a4,32
  a2:	02a76163          	bltu	a4,a0,c4 <getSyscallName+0xc4>
  a6:	00251793          	sll	a5,a0,0x2
  aa:	00001717          	auipc	a4,0x1
  ae:	b3270713          	add	a4,a4,-1230 # bdc <malloc+0x236>
  b2:	97ba                	add	a5,a5,a4
  b4:	439c                	lw	a5,0(a5)
  b6:	97ba                	add	a5,a5,a4
  b8:	8782                	jr	a5
        return "fork";
  ba:	00001517          	auipc	a0,0x1
  be:	9d650513          	add	a0,a0,-1578 # a90 <malloc+0xea>
  c2:	a035                	j	ee <getSyscallName+0xee>
        return "unknown";
  c4:	00001517          	auipc	a0,0x1
  c8:	9d450513          	add	a0,a0,-1580 # a98 <malloc+0xf2>
  cc:	a00d                	j	ee <getSyscallName+0xee>
    switch (mask)
  ce:	08000713          	li	a4,128
        return "exec";
  d2:	00001517          	auipc	a0,0x1
  d6:	9ee50513          	add	a0,a0,-1554 # ac0 <malloc+0x11a>
    switch (mask)
  da:	00e78a63          	beq	a5,a4,ee <getSyscallName+0xee>
  de:	10000713          	li	a4,256
        return "fstat";
  e2:	00001517          	auipc	a0,0x1
  e6:	9e650513          	add	a0,a0,-1562 # ac8 <malloc+0x122>
    switch (mask)
  ea:	00e79563          	bne	a5,a4,f4 <getSyscallName+0xf4>
    }
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	add	sp,sp,16
  f2:	8082                	ret
        return "unknown";
  f4:	00001517          	auipc	a0,0x1
  f8:	9a450513          	add	a0,a0,-1628 # a98 <malloc+0xf2>
  fc:	bfcd                	j	ee <getSyscallName+0xee>
    switch (mask)
  fe:	6721                	lui	a4,0x8
 100:	0ce50d63          	beq	a0,a4,1da <getSyscallName+0x1da>
 104:	02a75663          	bge	a4,a0,130 <getSyscallName+0x130>
 108:	6741                	lui	a4,0x10
        return "write";
 10a:	00001517          	auipc	a0,0x1
 10e:	9fe50513          	add	a0,a0,-1538 # b08 <malloc+0x162>
    switch (mask)
 112:	fce78ee3          	beq	a5,a4,ee <getSyscallName+0xee>
 116:	00020737          	lui	a4,0x20
        return "mknod";
 11a:	00001517          	auipc	a0,0x1
 11e:	9f650513          	add	a0,a0,-1546 # b10 <malloc+0x16a>
    switch (mask)
 122:	fce786e3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 126:	00001517          	auipc	a0,0x1
 12a:	97250513          	add	a0,a0,-1678 # a98 <malloc+0xf2>
 12e:	b7c1                	j	ee <getSyscallName+0xee>
    switch (mask)
 130:	6709                	lui	a4,0x2
        return "sleep";
 132:	00001517          	auipc	a0,0x1
 136:	9be50513          	add	a0,a0,-1602 # af0 <malloc+0x14a>
    switch (mask)
 13a:	fae78ae3          	beq	a5,a4,ee <getSyscallName+0xee>
 13e:	6711                	lui	a4,0x4
        return "uptime";
 140:	00001517          	auipc	a0,0x1
 144:	9b850513          	add	a0,a0,-1608 # af8 <malloc+0x152>
    switch (mask)
 148:	fae783e3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 14c:	00001517          	auipc	a0,0x1
 150:	94c50513          	add	a0,a0,-1716 # a98 <malloc+0xf2>
 154:	bf69                	j	ee <getSyscallName+0xee>
    switch (mask)
 156:	00080737          	lui	a4,0x80
        return "link";
 15a:	00001517          	auipc	a0,0x1
 15e:	9c650513          	add	a0,a0,-1594 # b20 <malloc+0x17a>
    switch (mask)
 162:	f8e786e3          	beq	a5,a4,ee <getSyscallName+0xee>
 166:	00100737          	lui	a4,0x100
        return "mkdir";
 16a:	00001517          	auipc	a0,0x1
 16e:	9be50513          	add	a0,a0,-1602 # b28 <malloc+0x182>
    switch (mask)
 172:	f6e78ee3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 176:	00001517          	auipc	a0,0x1
 17a:	92250513          	add	a0,a0,-1758 # a98 <malloc+0xf2>
 17e:	bf85                	j	ee <getSyscallName+0xee>
        return "wait";
 180:	00001517          	auipc	a0,0x1
 184:	92050513          	add	a0,a0,-1760 # aa0 <malloc+0xfa>
 188:	b79d                	j	ee <getSyscallName+0xee>
        return "pipe";
 18a:	00001517          	auipc	a0,0x1
 18e:	91e50513          	add	a0,a0,-1762 # aa8 <malloc+0x102>
 192:	bfb1                	j	ee <getSyscallName+0xee>
        return "read";
 194:	00001517          	auipc	a0,0x1
 198:	91c50513          	add	a0,a0,-1764 # ab0 <malloc+0x10a>
 19c:	bf89                	j	ee <getSyscallName+0xee>
        return "sbrk";
 19e:	00001517          	auipc	a0,0x1
 1a2:	94a50513          	add	a0,a0,-1718 # ae8 <malloc+0x142>
 1a6:	b7a1                	j	ee <getSyscallName+0xee>
        return "kill";
 1a8:	00001517          	auipc	a0,0x1
 1ac:	91050513          	add	a0,a0,-1776 # ab8 <malloc+0x112>
 1b0:	bf3d                	j	ee <getSyscallName+0xee>
        return "unknown";
 1b2:	00001517          	auipc	a0,0x1
 1b6:	8e650513          	add	a0,a0,-1818 # a98 <malloc+0xf2>
 1ba:	bf15                	j	ee <getSyscallName+0xee>
    switch (mask)
 1bc:	00001517          	auipc	a0,0x1
 1c0:	99450513          	add	a0,a0,-1644 # b50 <malloc+0x1aa>
 1c4:	b72d                	j	ee <getSyscallName+0xee>
        return "chdir";
 1c6:	00001517          	auipc	a0,0x1
 1ca:	90a50513          	add	a0,a0,-1782 # ad0 <malloc+0x12a>
 1ce:	b705                	j	ee <getSyscallName+0xee>
        return "unlink";
 1d0:	00001517          	auipc	a0,0x1
 1d4:	94850513          	add	a0,a0,-1720 # b18 <malloc+0x172>
 1d8:	bf19                	j	ee <getSyscallName+0xee>
        return "open";
 1da:	00001517          	auipc	a0,0x1
 1de:	92650513          	add	a0,a0,-1754 # b00 <malloc+0x15a>
 1e2:	b731                	j	ee <getSyscallName+0xee>
        return "close";
 1e4:	00001517          	auipc	a0,0x1
 1e8:	94c50513          	add	a0,a0,-1716 # b30 <malloc+0x18a>
 1ec:	b709                	j	ee <getSyscallName+0xee>

00000000000001ee <main>:

int main(int argc, char *argv[])
{
 1ee:	7139                	add	sp,sp,-64
 1f0:	fc06                	sd	ra,56(sp)
 1f2:	f822                	sd	s0,48(sp)
 1f4:	f426                	sd	s1,40(sp)
 1f6:	f04a                	sd	s2,32(sp)
 1f8:	ec4e                	sd	s3,24(sp)
 1fa:	0080                	add	s0,sp,64
    // Check if the number of arguments is correct
    if (argc < 3)
 1fc:	4789                	li	a5,2
 1fe:	00a7cf63          	blt	a5,a0,21c <main+0x2e>
    { // Must have at least mask and command
        printf("Usage: syscount <mask> command [args]\n");
 202:	00001517          	auipc	a0,0x1
 206:	95650513          	add	a0,a0,-1706 # b58 <malloc+0x1b2>
 20a:	00000097          	auipc	ra,0x0
 20e:	6e4080e7          	jalr	1764(ra) # 8ee <printf>
        exit(1);
 212:	4505                	li	a0,1
 214:	00000097          	auipc	ra,0x0
 218:	352080e7          	jalr	850(ra) # 566 <exit>
 21c:	84ae                	mv	s1,a1
    }

    // Convert the mask argument to an integer
    int mask = atoi(argv[1]);
 21e:	6588                	ld	a0,8(a1)
 220:	00000097          	auipc	ra,0x0
 224:	24c080e7          	jalr	588(ra) # 46c <atoi>
 228:	892a                	mv	s2,a0
    if (mask == 0)
 22a:	ed11                	bnez	a0,246 <main+0x58>
    {
        printf("Invalid mask provided.\n");
 22c:	00001517          	auipc	a0,0x1
 230:	95450513          	add	a0,a0,-1708 # b80 <malloc+0x1da>
 234:	00000097          	auipc	ra,0x0
 238:	6ba080e7          	jalr	1722(ra) # 8ee <printf>
        exit(1);
 23c:	4505                	li	a0,1
 23e:	00000097          	auipc	ra,0x0
 242:	328080e7          	jalr	808(ra) # 566 <exit>
    }

    // Fork and run the specified command
    int pid = fork();
 246:	00000097          	auipc	ra,0x0
 24a:	318080e7          	jalr	792(ra) # 55e <fork>
 24e:	89aa                	mv	s3,a0
    if(pid<0)
 250:	00054f63          	bltz	a0,26e <main+0x80>
    {
        printf("erorr");
        exit(1);
    }
    if (pid == 0)
 254:	e915                	bnez	a0,288 <main+0x9a>
    {
        // In child process, execute the command
        exec(argv[2], &argv[2]);                // Execute the command
 256:	01048593          	add	a1,s1,16
 25a:	6888                	ld	a0,16(s1)
 25c:	00000097          	auipc	ra,0x0
 260:	342080e7          	jalr	834(ra) # 59e <exec>
        // printf("Failed to exec %s\n", argv[2]); // Print error if exec fails
        // exit(1);                                // Exit child if exec fails
        exit(0);
 264:	4501                	li	a0,0
 266:	00000097          	auipc	ra,0x0
 26a:	300080e7          	jalr	768(ra) # 566 <exit>
        printf("erorr");
 26e:	00001517          	auipc	a0,0x1
 272:	92a50513          	add	a0,a0,-1750 # b98 <malloc+0x1f2>
 276:	00000097          	auipc	ra,0x0
 27a:	678080e7          	jalr	1656(ra) # 8ee <printf>
        exit(1);
 27e:	4505                	li	a0,1
 280:	00000097          	auipc	ra,0x0
 284:	2e6080e7          	jalr	742(ra) # 566 <exit>
    }
    else
    {
        // In parent process, wait for the child to finish
        int wstatus;
        wait(&wstatus);  // Wait for the child process to finish
 288:	fcc40513          	add	a0,s0,-52
 28c:	00000097          	auipc	ra,0x0
 290:	2e2080e7          	jalr	738(ra) # 56e <wait>

        // Get the syscall count for the child process
        int count = getSysCount(mask);
 294:	854a                	mv	a0,s2
 296:	00000097          	auipc	ra,0x0
 29a:	378080e7          	jalr	888(ra) # 60e <getSysCount>
 29e:	84aa                	mv	s1,a0
        if (count < 0)
 2a0:	02054763          	bltz	a0,2ce <main+0xe0>
        {
            printf("Error in counting syscalls.\n");
        }
        else
        {
            printf("PID %d called %s %d times.\n", pid, getSyscallName(mask), count);
 2a4:	854a                	mv	a0,s2
 2a6:	00000097          	auipc	ra,0x0
 2aa:	d5a080e7          	jalr	-678(ra) # 0 <getSyscallName>
 2ae:	862a                	mv	a2,a0
 2b0:	86a6                	mv	a3,s1
 2b2:	85ce                	mv	a1,s3
 2b4:	00001517          	auipc	a0,0x1
 2b8:	90c50513          	add	a0,a0,-1780 # bc0 <malloc+0x21a>
 2bc:	00000097          	auipc	ra,0x0
 2c0:	632080e7          	jalr	1586(ra) # 8ee <printf>
        }
    }

    exit(0); // Exit the parent process
 2c4:	4501                	li	a0,0
 2c6:	00000097          	auipc	ra,0x0
 2ca:	2a0080e7          	jalr	672(ra) # 566 <exit>
            printf("Error in counting syscalls.\n");
 2ce:	00001517          	auipc	a0,0x1
 2d2:	8d250513          	add	a0,a0,-1838 # ba0 <malloc+0x1fa>
 2d6:	00000097          	auipc	ra,0x0
 2da:	618080e7          	jalr	1560(ra) # 8ee <printf>
 2de:	b7dd                	j	2c4 <main+0xd6>

00000000000002e0 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 2e0:	1141                	add	sp,sp,-16
 2e2:	e406                	sd	ra,8(sp)
 2e4:	e022                	sd	s0,0(sp)
 2e6:	0800                	add	s0,sp,16
  extern int main();
  main();
 2e8:	00000097          	auipc	ra,0x0
 2ec:	f06080e7          	jalr	-250(ra) # 1ee <main>
  exit(0);
 2f0:	4501                	li	a0,0
 2f2:	00000097          	auipc	ra,0x0
 2f6:	274080e7          	jalr	628(ra) # 566 <exit>

00000000000002fa <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 2fa:	1141                	add	sp,sp,-16
 2fc:	e422                	sd	s0,8(sp)
 2fe:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 300:	87aa                	mv	a5,a0
 302:	0585                	add	a1,a1,1
 304:	0785                	add	a5,a5,1
 306:	fff5c703          	lbu	a4,-1(a1)
 30a:	fee78fa3          	sb	a4,-1(a5)
 30e:	fb75                	bnez	a4,302 <strcpy+0x8>
    ;
  return os;
}
 310:	6422                	ld	s0,8(sp)
 312:	0141                	add	sp,sp,16
 314:	8082                	ret

0000000000000316 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 316:	1141                	add	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	add	s0,sp,16
  while(*p && *p == *q)
 31c:	00054783          	lbu	a5,0(a0)
 320:	cb91                	beqz	a5,334 <strcmp+0x1e>
 322:	0005c703          	lbu	a4,0(a1)
 326:	00f71763          	bne	a4,a5,334 <strcmp+0x1e>
    p++, q++;
 32a:	0505                	add	a0,a0,1
 32c:	0585                	add	a1,a1,1
  while(*p && *p == *q)
 32e:	00054783          	lbu	a5,0(a0)
 332:	fbe5                	bnez	a5,322 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 334:	0005c503          	lbu	a0,0(a1)
}
 338:	40a7853b          	subw	a0,a5,a0
 33c:	6422                	ld	s0,8(sp)
 33e:	0141                	add	sp,sp,16
 340:	8082                	ret

0000000000000342 <strlen>:

uint
strlen(const char *s)
{
 342:	1141                	add	sp,sp,-16
 344:	e422                	sd	s0,8(sp)
 346:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 348:	00054783          	lbu	a5,0(a0)
 34c:	cf91                	beqz	a5,368 <strlen+0x26>
 34e:	0505                	add	a0,a0,1
 350:	87aa                	mv	a5,a0
 352:	86be                	mv	a3,a5
 354:	0785                	add	a5,a5,1
 356:	fff7c703          	lbu	a4,-1(a5)
 35a:	ff65                	bnez	a4,352 <strlen+0x10>
 35c:	40a6853b          	subw	a0,a3,a0
 360:	2505                	addw	a0,a0,1
    ;
  return n;
}
 362:	6422                	ld	s0,8(sp)
 364:	0141                	add	sp,sp,16
 366:	8082                	ret
  for(n = 0; s[n]; n++)
 368:	4501                	li	a0,0
 36a:	bfe5                	j	362 <strlen+0x20>

000000000000036c <memset>:

void*
memset(void *dst, int c, uint n)
{
 36c:	1141                	add	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 372:	ca19                	beqz	a2,388 <memset+0x1c>
 374:	87aa                	mv	a5,a0
 376:	1602                	sll	a2,a2,0x20
 378:	9201                	srl	a2,a2,0x20
 37a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 37e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 382:	0785                	add	a5,a5,1
 384:	fee79de3          	bne	a5,a4,37e <memset+0x12>
  }
  return dst;
}
 388:	6422                	ld	s0,8(sp)
 38a:	0141                	add	sp,sp,16
 38c:	8082                	ret

000000000000038e <strchr>:

char*
strchr(const char *s, char c)
{
 38e:	1141                	add	sp,sp,-16
 390:	e422                	sd	s0,8(sp)
 392:	0800                	add	s0,sp,16
  for(; *s; s++)
 394:	00054783          	lbu	a5,0(a0)
 398:	cb99                	beqz	a5,3ae <strchr+0x20>
    if(*s == c)
 39a:	00f58763          	beq	a1,a5,3a8 <strchr+0x1a>
  for(; *s; s++)
 39e:	0505                	add	a0,a0,1
 3a0:	00054783          	lbu	a5,0(a0)
 3a4:	fbfd                	bnez	a5,39a <strchr+0xc>
      return (char*)s;
  return 0;
 3a6:	4501                	li	a0,0
}
 3a8:	6422                	ld	s0,8(sp)
 3aa:	0141                	add	sp,sp,16
 3ac:	8082                	ret
  return 0;
 3ae:	4501                	li	a0,0
 3b0:	bfe5                	j	3a8 <strchr+0x1a>

00000000000003b2 <gets>:

char*
gets(char *buf, int max)
{
 3b2:	711d                	add	sp,sp,-96
 3b4:	ec86                	sd	ra,88(sp)
 3b6:	e8a2                	sd	s0,80(sp)
 3b8:	e4a6                	sd	s1,72(sp)
 3ba:	e0ca                	sd	s2,64(sp)
 3bc:	fc4e                	sd	s3,56(sp)
 3be:	f852                	sd	s4,48(sp)
 3c0:	f456                	sd	s5,40(sp)
 3c2:	f05a                	sd	s6,32(sp)
 3c4:	ec5e                	sd	s7,24(sp)
 3c6:	1080                	add	s0,sp,96
 3c8:	8baa                	mv	s7,a0
 3ca:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3cc:	892a                	mv	s2,a0
 3ce:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3d0:	4aa9                	li	s5,10
 3d2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3d4:	89a6                	mv	s3,s1
 3d6:	2485                	addw	s1,s1,1
 3d8:	0344d863          	bge	s1,s4,408 <gets+0x56>
    cc = read(0, &c, 1);
 3dc:	4605                	li	a2,1
 3de:	faf40593          	add	a1,s0,-81
 3e2:	4501                	li	a0,0
 3e4:	00000097          	auipc	ra,0x0
 3e8:	19a080e7          	jalr	410(ra) # 57e <read>
    if(cc < 1)
 3ec:	00a05e63          	blez	a0,408 <gets+0x56>
    buf[i++] = c;
 3f0:	faf44783          	lbu	a5,-81(s0)
 3f4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3f8:	01578763          	beq	a5,s5,406 <gets+0x54>
 3fc:	0905                	add	s2,s2,1
 3fe:	fd679be3          	bne	a5,s6,3d4 <gets+0x22>
  for(i=0; i+1 < max; ){
 402:	89a6                	mv	s3,s1
 404:	a011                	j	408 <gets+0x56>
 406:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 408:	99de                	add	s3,s3,s7
 40a:	00098023          	sb	zero,0(s3)
  return buf;
}
 40e:	855e                	mv	a0,s7
 410:	60e6                	ld	ra,88(sp)
 412:	6446                	ld	s0,80(sp)
 414:	64a6                	ld	s1,72(sp)
 416:	6906                	ld	s2,64(sp)
 418:	79e2                	ld	s3,56(sp)
 41a:	7a42                	ld	s4,48(sp)
 41c:	7aa2                	ld	s5,40(sp)
 41e:	7b02                	ld	s6,32(sp)
 420:	6be2                	ld	s7,24(sp)
 422:	6125                	add	sp,sp,96
 424:	8082                	ret

0000000000000426 <stat>:

int
stat(const char *n, struct stat *st)
{
 426:	1101                	add	sp,sp,-32
 428:	ec06                	sd	ra,24(sp)
 42a:	e822                	sd	s0,16(sp)
 42c:	e426                	sd	s1,8(sp)
 42e:	e04a                	sd	s2,0(sp)
 430:	1000                	add	s0,sp,32
 432:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 434:	4581                	li	a1,0
 436:	00000097          	auipc	ra,0x0
 43a:	170080e7          	jalr	368(ra) # 5a6 <open>
  if(fd < 0)
 43e:	02054563          	bltz	a0,468 <stat+0x42>
 442:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 444:	85ca                	mv	a1,s2
 446:	00000097          	auipc	ra,0x0
 44a:	178080e7          	jalr	376(ra) # 5be <fstat>
 44e:	892a                	mv	s2,a0
  close(fd);
 450:	8526                	mv	a0,s1
 452:	00000097          	auipc	ra,0x0
 456:	13c080e7          	jalr	316(ra) # 58e <close>
  return r;
}
 45a:	854a                	mv	a0,s2
 45c:	60e2                	ld	ra,24(sp)
 45e:	6442                	ld	s0,16(sp)
 460:	64a2                	ld	s1,8(sp)
 462:	6902                	ld	s2,0(sp)
 464:	6105                	add	sp,sp,32
 466:	8082                	ret
    return -1;
 468:	597d                	li	s2,-1
 46a:	bfc5                	j	45a <stat+0x34>

000000000000046c <atoi>:

int
atoi(const char *s)
{
 46c:	1141                	add	sp,sp,-16
 46e:	e422                	sd	s0,8(sp)
 470:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 472:	00054683          	lbu	a3,0(a0)
 476:	fd06879b          	addw	a5,a3,-48
 47a:	0ff7f793          	zext.b	a5,a5
 47e:	4625                	li	a2,9
 480:	02f66863          	bltu	a2,a5,4b0 <atoi+0x44>
 484:	872a                	mv	a4,a0
  n = 0;
 486:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 488:	0705                	add	a4,a4,1 # 100001 <base+0xfeff1>
 48a:	0025179b          	sllw	a5,a0,0x2
 48e:	9fa9                	addw	a5,a5,a0
 490:	0017979b          	sllw	a5,a5,0x1
 494:	9fb5                	addw	a5,a5,a3
 496:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 49a:	00074683          	lbu	a3,0(a4)
 49e:	fd06879b          	addw	a5,a3,-48
 4a2:	0ff7f793          	zext.b	a5,a5
 4a6:	fef671e3          	bgeu	a2,a5,488 <atoi+0x1c>
  return n;
}
 4aa:	6422                	ld	s0,8(sp)
 4ac:	0141                	add	sp,sp,16
 4ae:	8082                	ret
  n = 0;
 4b0:	4501                	li	a0,0
 4b2:	bfe5                	j	4aa <atoi+0x3e>

00000000000004b4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4b4:	1141                	add	sp,sp,-16
 4b6:	e422                	sd	s0,8(sp)
 4b8:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4ba:	02b57463          	bgeu	a0,a1,4e2 <memmove+0x2e>
    while(n-- > 0)
 4be:	00c05f63          	blez	a2,4dc <memmove+0x28>
 4c2:	1602                	sll	a2,a2,0x20
 4c4:	9201                	srl	a2,a2,0x20
 4c6:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 4ca:	872a                	mv	a4,a0
      *dst++ = *src++;
 4cc:	0585                	add	a1,a1,1
 4ce:	0705                	add	a4,a4,1
 4d0:	fff5c683          	lbu	a3,-1(a1)
 4d4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4d8:	fee79ae3          	bne	a5,a4,4cc <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4dc:	6422                	ld	s0,8(sp)
 4de:	0141                	add	sp,sp,16
 4e0:	8082                	ret
    dst += n;
 4e2:	00c50733          	add	a4,a0,a2
    src += n;
 4e6:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4e8:	fec05ae3          	blez	a2,4dc <memmove+0x28>
 4ec:	fff6079b          	addw	a5,a2,-1
 4f0:	1782                	sll	a5,a5,0x20
 4f2:	9381                	srl	a5,a5,0x20
 4f4:	fff7c793          	not	a5,a5
 4f8:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4fa:	15fd                	add	a1,a1,-1
 4fc:	177d                	add	a4,a4,-1
 4fe:	0005c683          	lbu	a3,0(a1)
 502:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 506:	fee79ae3          	bne	a5,a4,4fa <memmove+0x46>
 50a:	bfc9                	j	4dc <memmove+0x28>

000000000000050c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 50c:	1141                	add	sp,sp,-16
 50e:	e422                	sd	s0,8(sp)
 510:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 512:	ca05                	beqz	a2,542 <memcmp+0x36>
 514:	fff6069b          	addw	a3,a2,-1
 518:	1682                	sll	a3,a3,0x20
 51a:	9281                	srl	a3,a3,0x20
 51c:	0685                	add	a3,a3,1
 51e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 520:	00054783          	lbu	a5,0(a0)
 524:	0005c703          	lbu	a4,0(a1)
 528:	00e79863          	bne	a5,a4,538 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 52c:	0505                	add	a0,a0,1
    p2++;
 52e:	0585                	add	a1,a1,1
  while (n-- > 0) {
 530:	fed518e3          	bne	a0,a3,520 <memcmp+0x14>
  }
  return 0;
 534:	4501                	li	a0,0
 536:	a019                	j	53c <memcmp+0x30>
      return *p1 - *p2;
 538:	40e7853b          	subw	a0,a5,a4
}
 53c:	6422                	ld	s0,8(sp)
 53e:	0141                	add	sp,sp,16
 540:	8082                	ret
  return 0;
 542:	4501                	li	a0,0
 544:	bfe5                	j	53c <memcmp+0x30>

0000000000000546 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 546:	1141                	add	sp,sp,-16
 548:	e406                	sd	ra,8(sp)
 54a:	e022                	sd	s0,0(sp)
 54c:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 54e:	00000097          	auipc	ra,0x0
 552:	f66080e7          	jalr	-154(ra) # 4b4 <memmove>
}
 556:	60a2                	ld	ra,8(sp)
 558:	6402                	ld	s0,0(sp)
 55a:	0141                	add	sp,sp,16
 55c:	8082                	ret

000000000000055e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 55e:	4885                	li	a7,1
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <exit>:
.global exit
exit:
 li a7, SYS_exit
 566:	4889                	li	a7,2
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <wait>:
.global wait
wait:
 li a7, SYS_wait
 56e:	488d                	li	a7,3
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 576:	4891                	li	a7,4
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <read>:
.global read
read:
 li a7, SYS_read
 57e:	4895                	li	a7,5
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <write>:
.global write
write:
 li a7, SYS_write
 586:	48c1                	li	a7,16
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <close>:
.global close
close:
 li a7, SYS_close
 58e:	48d5                	li	a7,21
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <kill>:
.global kill
kill:
 li a7, SYS_kill
 596:	4899                	li	a7,6
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <exec>:
.global exec
exec:
 li a7, SYS_exec
 59e:	489d                	li	a7,7
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <open>:
.global open
open:
 li a7, SYS_open
 5a6:	48bd                	li	a7,15
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5ae:	48c5                	li	a7,17
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5b6:	48c9                	li	a7,18
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5be:	48a1                	li	a7,8
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <link>:
.global link
link:
 li a7, SYS_link
 5c6:	48cd                	li	a7,19
 ecall
 5c8:	00000073          	ecall
 ret
 5cc:	8082                	ret

00000000000005ce <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5ce:	48d1                	li	a7,20
 ecall
 5d0:	00000073          	ecall
 ret
 5d4:	8082                	ret

00000000000005d6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5d6:	48a5                	li	a7,9
 ecall
 5d8:	00000073          	ecall
 ret
 5dc:	8082                	ret

00000000000005de <dup>:
.global dup
dup:
 li a7, SYS_dup
 5de:	48a9                	li	a7,10
 ecall
 5e0:	00000073          	ecall
 ret
 5e4:	8082                	ret

00000000000005e6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5e6:	48ad                	li	a7,11
 ecall
 5e8:	00000073          	ecall
 ret
 5ec:	8082                	ret

00000000000005ee <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5ee:	48b1                	li	a7,12
 ecall
 5f0:	00000073          	ecall
 ret
 5f4:	8082                	ret

00000000000005f6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5f6:	48b5                	li	a7,13
 ecall
 5f8:	00000073          	ecall
 ret
 5fc:	8082                	ret

00000000000005fe <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5fe:	48b9                	li	a7,14
 ecall
 600:	00000073          	ecall
 ret
 604:	8082                	ret

0000000000000606 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 606:	48d9                	li	a7,22
 ecall
 608:	00000073          	ecall
 ret
 60c:	8082                	ret

000000000000060e <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 60e:	48dd                	li	a7,23
 ecall
 610:	00000073          	ecall
 ret
 614:	8082                	ret

0000000000000616 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 616:	48e1                	li	a7,24
 ecall
 618:	00000073          	ecall
 ret
 61c:	8082                	ret

000000000000061e <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 61e:	48e5                	li	a7,25
 ecall
 620:	00000073          	ecall
 ret
 624:	8082                	ret

0000000000000626 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 626:	1101                	add	sp,sp,-32
 628:	ec06                	sd	ra,24(sp)
 62a:	e822                	sd	s0,16(sp)
 62c:	1000                	add	s0,sp,32
 62e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 632:	4605                	li	a2,1
 634:	fef40593          	add	a1,s0,-17
 638:	00000097          	auipc	ra,0x0
 63c:	f4e080e7          	jalr	-178(ra) # 586 <write>
}
 640:	60e2                	ld	ra,24(sp)
 642:	6442                	ld	s0,16(sp)
 644:	6105                	add	sp,sp,32
 646:	8082                	ret

0000000000000648 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 648:	7139                	add	sp,sp,-64
 64a:	fc06                	sd	ra,56(sp)
 64c:	f822                	sd	s0,48(sp)
 64e:	f426                	sd	s1,40(sp)
 650:	f04a                	sd	s2,32(sp)
 652:	ec4e                	sd	s3,24(sp)
 654:	0080                	add	s0,sp,64
 656:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 658:	c299                	beqz	a3,65e <printint+0x16>
 65a:	0805c963          	bltz	a1,6ec <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 65e:	2581                	sext.w	a1,a1
  neg = 0;
 660:	4881                	li	a7,0
 662:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 666:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 668:	2601                	sext.w	a2,a2
 66a:	00000517          	auipc	a0,0x0
 66e:	65650513          	add	a0,a0,1622 # cc0 <digits>
 672:	883a                	mv	a6,a4
 674:	2705                	addw	a4,a4,1
 676:	02c5f7bb          	remuw	a5,a1,a2
 67a:	1782                	sll	a5,a5,0x20
 67c:	9381                	srl	a5,a5,0x20
 67e:	97aa                	add	a5,a5,a0
 680:	0007c783          	lbu	a5,0(a5)
 684:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 688:	0005879b          	sext.w	a5,a1
 68c:	02c5d5bb          	divuw	a1,a1,a2
 690:	0685                	add	a3,a3,1
 692:	fec7f0e3          	bgeu	a5,a2,672 <printint+0x2a>
  if(neg)
 696:	00088c63          	beqz	a7,6ae <printint+0x66>
    buf[i++] = '-';
 69a:	fd070793          	add	a5,a4,-48
 69e:	00878733          	add	a4,a5,s0
 6a2:	02d00793          	li	a5,45
 6a6:	fef70823          	sb	a5,-16(a4)
 6aa:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 6ae:	02e05863          	blez	a4,6de <printint+0x96>
 6b2:	fc040793          	add	a5,s0,-64
 6b6:	00e78933          	add	s2,a5,a4
 6ba:	fff78993          	add	s3,a5,-1
 6be:	99ba                	add	s3,s3,a4
 6c0:	377d                	addw	a4,a4,-1
 6c2:	1702                	sll	a4,a4,0x20
 6c4:	9301                	srl	a4,a4,0x20
 6c6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ca:	fff94583          	lbu	a1,-1(s2)
 6ce:	8526                	mv	a0,s1
 6d0:	00000097          	auipc	ra,0x0
 6d4:	f56080e7          	jalr	-170(ra) # 626 <putc>
  while(--i >= 0)
 6d8:	197d                	add	s2,s2,-1
 6da:	ff3918e3          	bne	s2,s3,6ca <printint+0x82>
}
 6de:	70e2                	ld	ra,56(sp)
 6e0:	7442                	ld	s0,48(sp)
 6e2:	74a2                	ld	s1,40(sp)
 6e4:	7902                	ld	s2,32(sp)
 6e6:	69e2                	ld	s3,24(sp)
 6e8:	6121                	add	sp,sp,64
 6ea:	8082                	ret
    x = -xx;
 6ec:	40b005bb          	negw	a1,a1
    neg = 1;
 6f0:	4885                	li	a7,1
    x = -xx;
 6f2:	bf85                	j	662 <printint+0x1a>

00000000000006f4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6f4:	715d                	add	sp,sp,-80
 6f6:	e486                	sd	ra,72(sp)
 6f8:	e0a2                	sd	s0,64(sp)
 6fa:	fc26                	sd	s1,56(sp)
 6fc:	f84a                	sd	s2,48(sp)
 6fe:	f44e                	sd	s3,40(sp)
 700:	f052                	sd	s4,32(sp)
 702:	ec56                	sd	s5,24(sp)
 704:	e85a                	sd	s6,16(sp)
 706:	e45e                	sd	s7,8(sp)
 708:	e062                	sd	s8,0(sp)
 70a:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 70c:	0005c903          	lbu	s2,0(a1)
 710:	18090c63          	beqz	s2,8a8 <vprintf+0x1b4>
 714:	8aaa                	mv	s5,a0
 716:	8bb2                	mv	s7,a2
 718:	00158493          	add	s1,a1,1
  state = 0;
 71c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 71e:	02500a13          	li	s4,37
 722:	4b55                	li	s6,21
 724:	a839                	j	742 <vprintf+0x4e>
        putc(fd, c);
 726:	85ca                	mv	a1,s2
 728:	8556                	mv	a0,s5
 72a:	00000097          	auipc	ra,0x0
 72e:	efc080e7          	jalr	-260(ra) # 626 <putc>
 732:	a019                	j	738 <vprintf+0x44>
    } else if(state == '%'){
 734:	01498d63          	beq	s3,s4,74e <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 738:	0485                	add	s1,s1,1
 73a:	fff4c903          	lbu	s2,-1(s1)
 73e:	16090563          	beqz	s2,8a8 <vprintf+0x1b4>
    if(state == 0){
 742:	fe0999e3          	bnez	s3,734 <vprintf+0x40>
      if(c == '%'){
 746:	ff4910e3          	bne	s2,s4,726 <vprintf+0x32>
        state = '%';
 74a:	89d2                	mv	s3,s4
 74c:	b7f5                	j	738 <vprintf+0x44>
      if(c == 'd'){
 74e:	13490263          	beq	s2,s4,872 <vprintf+0x17e>
 752:	f9d9079b          	addw	a5,s2,-99
 756:	0ff7f793          	zext.b	a5,a5
 75a:	12fb6563          	bltu	s6,a5,884 <vprintf+0x190>
 75e:	f9d9079b          	addw	a5,s2,-99
 762:	0ff7f713          	zext.b	a4,a5
 766:	10eb6f63          	bltu	s6,a4,884 <vprintf+0x190>
 76a:	00271793          	sll	a5,a4,0x2
 76e:	00000717          	auipc	a4,0x0
 772:	4fa70713          	add	a4,a4,1274 # c68 <malloc+0x2c2>
 776:	97ba                	add	a5,a5,a4
 778:	439c                	lw	a5,0(a5)
 77a:	97ba                	add	a5,a5,a4
 77c:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 77e:	008b8913          	add	s2,s7,8
 782:	4685                	li	a3,1
 784:	4629                	li	a2,10
 786:	000ba583          	lw	a1,0(s7)
 78a:	8556                	mv	a0,s5
 78c:	00000097          	auipc	ra,0x0
 790:	ebc080e7          	jalr	-324(ra) # 648 <printint>
 794:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 796:	4981                	li	s3,0
 798:	b745                	j	738 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 79a:	008b8913          	add	s2,s7,8
 79e:	4681                	li	a3,0
 7a0:	4629                	li	a2,10
 7a2:	000ba583          	lw	a1,0(s7)
 7a6:	8556                	mv	a0,s5
 7a8:	00000097          	auipc	ra,0x0
 7ac:	ea0080e7          	jalr	-352(ra) # 648 <printint>
 7b0:	8bca                	mv	s7,s2
      state = 0;
 7b2:	4981                	li	s3,0
 7b4:	b751                	j	738 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 7b6:	008b8913          	add	s2,s7,8
 7ba:	4681                	li	a3,0
 7bc:	4641                	li	a2,16
 7be:	000ba583          	lw	a1,0(s7)
 7c2:	8556                	mv	a0,s5
 7c4:	00000097          	auipc	ra,0x0
 7c8:	e84080e7          	jalr	-380(ra) # 648 <printint>
 7cc:	8bca                	mv	s7,s2
      state = 0;
 7ce:	4981                	li	s3,0
 7d0:	b7a5                	j	738 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 7d2:	008b8c13          	add	s8,s7,8
 7d6:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 7da:	03000593          	li	a1,48
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	e46080e7          	jalr	-442(ra) # 626 <putc>
  putc(fd, 'x');
 7e8:	07800593          	li	a1,120
 7ec:	8556                	mv	a0,s5
 7ee:	00000097          	auipc	ra,0x0
 7f2:	e38080e7          	jalr	-456(ra) # 626 <putc>
 7f6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7f8:	00000b97          	auipc	s7,0x0
 7fc:	4c8b8b93          	add	s7,s7,1224 # cc0 <digits>
 800:	03c9d793          	srl	a5,s3,0x3c
 804:	97de                	add	a5,a5,s7
 806:	0007c583          	lbu	a1,0(a5)
 80a:	8556                	mv	a0,s5
 80c:	00000097          	auipc	ra,0x0
 810:	e1a080e7          	jalr	-486(ra) # 626 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 814:	0992                	sll	s3,s3,0x4
 816:	397d                	addw	s2,s2,-1
 818:	fe0914e3          	bnez	s2,800 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 81c:	8be2                	mv	s7,s8
      state = 0;
 81e:	4981                	li	s3,0
 820:	bf21                	j	738 <vprintf+0x44>
        s = va_arg(ap, char*);
 822:	008b8993          	add	s3,s7,8
 826:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 82a:	02090163          	beqz	s2,84c <vprintf+0x158>
        while(*s != 0){
 82e:	00094583          	lbu	a1,0(s2)
 832:	c9a5                	beqz	a1,8a2 <vprintf+0x1ae>
          putc(fd, *s);
 834:	8556                	mv	a0,s5
 836:	00000097          	auipc	ra,0x0
 83a:	df0080e7          	jalr	-528(ra) # 626 <putc>
          s++;
 83e:	0905                	add	s2,s2,1
        while(*s != 0){
 840:	00094583          	lbu	a1,0(s2)
 844:	f9e5                	bnez	a1,834 <vprintf+0x140>
        s = va_arg(ap, char*);
 846:	8bce                	mv	s7,s3
      state = 0;
 848:	4981                	li	s3,0
 84a:	b5fd                	j	738 <vprintf+0x44>
          s = "(null)";
 84c:	00000917          	auipc	s2,0x0
 850:	41490913          	add	s2,s2,1044 # c60 <malloc+0x2ba>
        while(*s != 0){
 854:	02800593          	li	a1,40
 858:	bff1                	j	834 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 85a:	008b8913          	add	s2,s7,8
 85e:	000bc583          	lbu	a1,0(s7)
 862:	8556                	mv	a0,s5
 864:	00000097          	auipc	ra,0x0
 868:	dc2080e7          	jalr	-574(ra) # 626 <putc>
 86c:	8bca                	mv	s7,s2
      state = 0;
 86e:	4981                	li	s3,0
 870:	b5e1                	j	738 <vprintf+0x44>
        putc(fd, c);
 872:	02500593          	li	a1,37
 876:	8556                	mv	a0,s5
 878:	00000097          	auipc	ra,0x0
 87c:	dae080e7          	jalr	-594(ra) # 626 <putc>
      state = 0;
 880:	4981                	li	s3,0
 882:	bd5d                	j	738 <vprintf+0x44>
        putc(fd, '%');
 884:	02500593          	li	a1,37
 888:	8556                	mv	a0,s5
 88a:	00000097          	auipc	ra,0x0
 88e:	d9c080e7          	jalr	-612(ra) # 626 <putc>
        putc(fd, c);
 892:	85ca                	mv	a1,s2
 894:	8556                	mv	a0,s5
 896:	00000097          	auipc	ra,0x0
 89a:	d90080e7          	jalr	-624(ra) # 626 <putc>
      state = 0;
 89e:	4981                	li	s3,0
 8a0:	bd61                	j	738 <vprintf+0x44>
        s = va_arg(ap, char*);
 8a2:	8bce                	mv	s7,s3
      state = 0;
 8a4:	4981                	li	s3,0
 8a6:	bd49                	j	738 <vprintf+0x44>
    }
  }
}
 8a8:	60a6                	ld	ra,72(sp)
 8aa:	6406                	ld	s0,64(sp)
 8ac:	74e2                	ld	s1,56(sp)
 8ae:	7942                	ld	s2,48(sp)
 8b0:	79a2                	ld	s3,40(sp)
 8b2:	7a02                	ld	s4,32(sp)
 8b4:	6ae2                	ld	s5,24(sp)
 8b6:	6b42                	ld	s6,16(sp)
 8b8:	6ba2                	ld	s7,8(sp)
 8ba:	6c02                	ld	s8,0(sp)
 8bc:	6161                	add	sp,sp,80
 8be:	8082                	ret

00000000000008c0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8c0:	715d                	add	sp,sp,-80
 8c2:	ec06                	sd	ra,24(sp)
 8c4:	e822                	sd	s0,16(sp)
 8c6:	1000                	add	s0,sp,32
 8c8:	e010                	sd	a2,0(s0)
 8ca:	e414                	sd	a3,8(s0)
 8cc:	e818                	sd	a4,16(s0)
 8ce:	ec1c                	sd	a5,24(s0)
 8d0:	03043023          	sd	a6,32(s0)
 8d4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8d8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8dc:	8622                	mv	a2,s0
 8de:	00000097          	auipc	ra,0x0
 8e2:	e16080e7          	jalr	-490(ra) # 6f4 <vprintf>
}
 8e6:	60e2                	ld	ra,24(sp)
 8e8:	6442                	ld	s0,16(sp)
 8ea:	6161                	add	sp,sp,80
 8ec:	8082                	ret

00000000000008ee <printf>:

void
printf(const char *fmt, ...)
{
 8ee:	711d                	add	sp,sp,-96
 8f0:	ec06                	sd	ra,24(sp)
 8f2:	e822                	sd	s0,16(sp)
 8f4:	1000                	add	s0,sp,32
 8f6:	e40c                	sd	a1,8(s0)
 8f8:	e810                	sd	a2,16(s0)
 8fa:	ec14                	sd	a3,24(s0)
 8fc:	f018                	sd	a4,32(s0)
 8fe:	f41c                	sd	a5,40(s0)
 900:	03043823          	sd	a6,48(s0)
 904:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 908:	00840613          	add	a2,s0,8
 90c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 910:	85aa                	mv	a1,a0
 912:	4505                	li	a0,1
 914:	00000097          	auipc	ra,0x0
 918:	de0080e7          	jalr	-544(ra) # 6f4 <vprintf>
}
 91c:	60e2                	ld	ra,24(sp)
 91e:	6442                	ld	s0,16(sp)
 920:	6125                	add	sp,sp,96
 922:	8082                	ret

0000000000000924 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 924:	1141                	add	sp,sp,-16
 926:	e422                	sd	s0,8(sp)
 928:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 92a:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 92e:	00000797          	auipc	a5,0x0
 932:	6d27b783          	ld	a5,1746(a5) # 1000 <freep>
 936:	a02d                	j	960 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 938:	4618                	lw	a4,8(a2)
 93a:	9f2d                	addw	a4,a4,a1
 93c:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 940:	6398                	ld	a4,0(a5)
 942:	6310                	ld	a2,0(a4)
 944:	a83d                	j	982 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 946:	ff852703          	lw	a4,-8(a0)
 94a:	9f31                	addw	a4,a4,a2
 94c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 94e:	ff053683          	ld	a3,-16(a0)
 952:	a091                	j	996 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 954:	6398                	ld	a4,0(a5)
 956:	00e7e463          	bltu	a5,a4,95e <free+0x3a>
 95a:	00e6ea63          	bltu	a3,a4,96e <free+0x4a>
{
 95e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 960:	fed7fae3          	bgeu	a5,a3,954 <free+0x30>
 964:	6398                	ld	a4,0(a5)
 966:	00e6e463          	bltu	a3,a4,96e <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 96a:	fee7eae3          	bltu	a5,a4,95e <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 96e:	ff852583          	lw	a1,-8(a0)
 972:	6390                	ld	a2,0(a5)
 974:	02059813          	sll	a6,a1,0x20
 978:	01c85713          	srl	a4,a6,0x1c
 97c:	9736                	add	a4,a4,a3
 97e:	fae60de3          	beq	a2,a4,938 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 982:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 986:	4790                	lw	a2,8(a5)
 988:	02061593          	sll	a1,a2,0x20
 98c:	01c5d713          	srl	a4,a1,0x1c
 990:	973e                	add	a4,a4,a5
 992:	fae68ae3          	beq	a3,a4,946 <free+0x22>
    p->s.ptr = bp->s.ptr;
 996:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 998:	00000717          	auipc	a4,0x0
 99c:	66f73423          	sd	a5,1640(a4) # 1000 <freep>
}
 9a0:	6422                	ld	s0,8(sp)
 9a2:	0141                	add	sp,sp,16
 9a4:	8082                	ret

00000000000009a6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9a6:	7139                	add	sp,sp,-64
 9a8:	fc06                	sd	ra,56(sp)
 9aa:	f822                	sd	s0,48(sp)
 9ac:	f426                	sd	s1,40(sp)
 9ae:	f04a                	sd	s2,32(sp)
 9b0:	ec4e                	sd	s3,24(sp)
 9b2:	e852                	sd	s4,16(sp)
 9b4:	e456                	sd	s5,8(sp)
 9b6:	e05a                	sd	s6,0(sp)
 9b8:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9ba:	02051493          	sll	s1,a0,0x20
 9be:	9081                	srl	s1,s1,0x20
 9c0:	04bd                	add	s1,s1,15
 9c2:	8091                	srl	s1,s1,0x4
 9c4:	0014899b          	addw	s3,s1,1
 9c8:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 9ca:	00000517          	auipc	a0,0x0
 9ce:	63653503          	ld	a0,1590(a0) # 1000 <freep>
 9d2:	c515                	beqz	a0,9fe <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9d4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9d6:	4798                	lw	a4,8(a5)
 9d8:	02977f63          	bgeu	a4,s1,a16 <malloc+0x70>
  if(nu < 4096)
 9dc:	8a4e                	mv	s4,s3
 9de:	0009871b          	sext.w	a4,s3
 9e2:	6685                	lui	a3,0x1
 9e4:	00d77363          	bgeu	a4,a3,9ea <malloc+0x44>
 9e8:	6a05                	lui	s4,0x1
 9ea:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9ee:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9f2:	00000917          	auipc	s2,0x0
 9f6:	60e90913          	add	s2,s2,1550 # 1000 <freep>
  if(p == (char*)-1)
 9fa:	5afd                	li	s5,-1
 9fc:	a895                	j	a70 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 9fe:	00000797          	auipc	a5,0x0
 a02:	61278793          	add	a5,a5,1554 # 1010 <base>
 a06:	00000717          	auipc	a4,0x0
 a0a:	5ef73d23          	sd	a5,1530(a4) # 1000 <freep>
 a0e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a10:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a14:	b7e1                	j	9dc <malloc+0x36>
      if(p->s.size == nunits)
 a16:	02e48c63          	beq	s1,a4,a4e <malloc+0xa8>
        p->s.size -= nunits;
 a1a:	4137073b          	subw	a4,a4,s3
 a1e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a20:	02071693          	sll	a3,a4,0x20
 a24:	01c6d713          	srl	a4,a3,0x1c
 a28:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a2a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a2e:	00000717          	auipc	a4,0x0
 a32:	5ca73923          	sd	a0,1490(a4) # 1000 <freep>
      return (void*)(p + 1);
 a36:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a3a:	70e2                	ld	ra,56(sp)
 a3c:	7442                	ld	s0,48(sp)
 a3e:	74a2                	ld	s1,40(sp)
 a40:	7902                	ld	s2,32(sp)
 a42:	69e2                	ld	s3,24(sp)
 a44:	6a42                	ld	s4,16(sp)
 a46:	6aa2                	ld	s5,8(sp)
 a48:	6b02                	ld	s6,0(sp)
 a4a:	6121                	add	sp,sp,64
 a4c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a4e:	6398                	ld	a4,0(a5)
 a50:	e118                	sd	a4,0(a0)
 a52:	bff1                	j	a2e <malloc+0x88>
  hp->s.size = nu;
 a54:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a58:	0541                	add	a0,a0,16
 a5a:	00000097          	auipc	ra,0x0
 a5e:	eca080e7          	jalr	-310(ra) # 924 <free>
  return freep;
 a62:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a66:	d971                	beqz	a0,a3a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a68:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a6a:	4798                	lw	a4,8(a5)
 a6c:	fa9775e3          	bgeu	a4,s1,a16 <malloc+0x70>
    if(p == freep)
 a70:	00093703          	ld	a4,0(s2)
 a74:	853e                	mv	a0,a5
 a76:	fef719e3          	bne	a4,a5,a68 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a7a:	8552                	mv	a0,s4
 a7c:	00000097          	auipc	ra,0x0
 a80:	b72080e7          	jalr	-1166(ra) # 5ee <sbrk>
  if(p == (char*)-1)
 a84:	fd5518e3          	bne	a0,s5,a54 <malloc+0xae>
        return 0;
 a88:	4501                	li	a0,0
 a8a:	bf45                	j	a3a <malloc+0x94>
