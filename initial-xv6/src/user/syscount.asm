
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
  32:	b1a50513          	add	a0,a0,-1254 # b48 <malloc+0x19a>
    switch (mask)
  36:	0ae78c63          	beq	a5,a4,ee <getSyscallName+0xee>
  3a:	00800737          	lui	a4,0x800
    case (1 << (SYS_getSysCount)):
        return "getSysCount";
  3e:	00001517          	auipc	a0,0x1
  42:	b1250513          	add	a0,a0,-1262 # b50 <malloc+0x1a2>
    switch (mask)
  46:	0ae78463          	beq	a5,a4,ee <getSyscallName+0xee>
    default:
        return "unknown";
  4a:	00001517          	auipc	a0,0x1
  4e:	a5e50513          	add	a0,a0,-1442 # aa8 <malloc+0xfa>
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
  74:	a7850513          	add	a0,a0,-1416 # ae8 <malloc+0x13a>
    switch (mask)
  78:	06e78b63          	beq	a5,a4,ee <getSyscallName+0xee>
  7c:	8007879b          	addw	a5,a5,-2048
        return "getpid";
  80:	00001517          	auipc	a0,0x1
  84:	a7050513          	add	a0,a0,-1424 # af0 <malloc+0x142>
    switch (mask)
  88:	c3bd                	beqz	a5,ee <getSyscallName+0xee>
        return "unknown";
  8a:	00001517          	auipc	a0,0x1
  8e:	a1e50513          	add	a0,a0,-1506 # aa8 <malloc+0xfa>
  92:	a8b1                	j	ee <getSyscallName+0xee>
    switch (mask)
  94:	ffe5071b          	addw	a4,a0,-2
  98:	46f9                	li	a3,30
  9a:	10e6ec63          	bltu	a3,a4,1b2 <getSyscallName+0x1b2>
  9e:	02000713          	li	a4,32
  a2:	02a76163          	bltu	a4,a0,c4 <getSyscallName+0xc4>
  a6:	00251793          	sll	a5,a0,0x2
  aa:	00001717          	auipc	a4,0x1
  ae:	b4270713          	add	a4,a4,-1214 # bec <malloc+0x23e>
  b2:	97ba                	add	a5,a5,a4
  b4:	439c                	lw	a5,0(a5)
  b6:	97ba                	add	a5,a5,a4
  b8:	8782                	jr	a5
        return "fork";
  ba:	00001517          	auipc	a0,0x1
  be:	9e650513          	add	a0,a0,-1562 # aa0 <malloc+0xf2>
  c2:	a035                	j	ee <getSyscallName+0xee>
        return "unknown";
  c4:	00001517          	auipc	a0,0x1
  c8:	9e450513          	add	a0,a0,-1564 # aa8 <malloc+0xfa>
  cc:	a00d                	j	ee <getSyscallName+0xee>
    switch (mask)
  ce:	08000713          	li	a4,128
        return "exec";
  d2:	00001517          	auipc	a0,0x1
  d6:	9fe50513          	add	a0,a0,-1538 # ad0 <malloc+0x122>
    switch (mask)
  da:	00e78a63          	beq	a5,a4,ee <getSyscallName+0xee>
  de:	10000713          	li	a4,256
        return "fstat";
  e2:	00001517          	auipc	a0,0x1
  e6:	9f650513          	add	a0,a0,-1546 # ad8 <malloc+0x12a>
    switch (mask)
  ea:	00e79563          	bne	a5,a4,f4 <getSyscallName+0xf4>
    }
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	add	sp,sp,16
  f2:	8082                	ret
        return "unknown";
  f4:	00001517          	auipc	a0,0x1
  f8:	9b450513          	add	a0,a0,-1612 # aa8 <malloc+0xfa>
  fc:	bfcd                	j	ee <getSyscallName+0xee>
    switch (mask)
  fe:	6721                	lui	a4,0x8
 100:	0ce50d63          	beq	a0,a4,1da <getSyscallName+0x1da>
 104:	02a75663          	bge	a4,a0,130 <getSyscallName+0x130>
 108:	6741                	lui	a4,0x10
        return "write";
 10a:	00001517          	auipc	a0,0x1
 10e:	a0e50513          	add	a0,a0,-1522 # b18 <malloc+0x16a>
    switch (mask)
 112:	fce78ee3          	beq	a5,a4,ee <getSyscallName+0xee>
 116:	00020737          	lui	a4,0x20
        return "mknod";
 11a:	00001517          	auipc	a0,0x1
 11e:	a0650513          	add	a0,a0,-1530 # b20 <malloc+0x172>
    switch (mask)
 122:	fce786e3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 126:	00001517          	auipc	a0,0x1
 12a:	98250513          	add	a0,a0,-1662 # aa8 <malloc+0xfa>
 12e:	b7c1                	j	ee <getSyscallName+0xee>
    switch (mask)
 130:	6709                	lui	a4,0x2
        return "sleep";
 132:	00001517          	auipc	a0,0x1
 136:	9ce50513          	add	a0,a0,-1586 # b00 <malloc+0x152>
    switch (mask)
 13a:	fae78ae3          	beq	a5,a4,ee <getSyscallName+0xee>
 13e:	6711                	lui	a4,0x4
        return "uptime";
 140:	00001517          	auipc	a0,0x1
 144:	9c850513          	add	a0,a0,-1592 # b08 <malloc+0x15a>
    switch (mask)
 148:	fae783e3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 14c:	00001517          	auipc	a0,0x1
 150:	95c50513          	add	a0,a0,-1700 # aa8 <malloc+0xfa>
 154:	bf69                	j	ee <getSyscallName+0xee>
    switch (mask)
 156:	00080737          	lui	a4,0x80
        return "link";
 15a:	00001517          	auipc	a0,0x1
 15e:	9d650513          	add	a0,a0,-1578 # b30 <malloc+0x182>
    switch (mask)
 162:	f8e786e3          	beq	a5,a4,ee <getSyscallName+0xee>
 166:	00100737          	lui	a4,0x100
        return "mkdir";
 16a:	00001517          	auipc	a0,0x1
 16e:	9ce50513          	add	a0,a0,-1586 # b38 <malloc+0x18a>
    switch (mask)
 172:	f6e78ee3          	beq	a5,a4,ee <getSyscallName+0xee>
        return "unknown";
 176:	00001517          	auipc	a0,0x1
 17a:	93250513          	add	a0,a0,-1742 # aa8 <malloc+0xfa>
 17e:	bf85                	j	ee <getSyscallName+0xee>
        return "wait";
 180:	00001517          	auipc	a0,0x1
 184:	93050513          	add	a0,a0,-1744 # ab0 <malloc+0x102>
 188:	b79d                	j	ee <getSyscallName+0xee>
        return "pipe";
 18a:	00001517          	auipc	a0,0x1
 18e:	92e50513          	add	a0,a0,-1746 # ab8 <malloc+0x10a>
 192:	bfb1                	j	ee <getSyscallName+0xee>
        return "read";
 194:	00001517          	auipc	a0,0x1
 198:	92c50513          	add	a0,a0,-1748 # ac0 <malloc+0x112>
 19c:	bf89                	j	ee <getSyscallName+0xee>
        return "sbrk";
 19e:	00001517          	auipc	a0,0x1
 1a2:	95a50513          	add	a0,a0,-1702 # af8 <malloc+0x14a>
 1a6:	b7a1                	j	ee <getSyscallName+0xee>
        return "kill";
 1a8:	00001517          	auipc	a0,0x1
 1ac:	92050513          	add	a0,a0,-1760 # ac8 <malloc+0x11a>
 1b0:	bf3d                	j	ee <getSyscallName+0xee>
        return "unknown";
 1b2:	00001517          	auipc	a0,0x1
 1b6:	8f650513          	add	a0,a0,-1802 # aa8 <malloc+0xfa>
 1ba:	bf15                	j	ee <getSyscallName+0xee>
    switch (mask)
 1bc:	00001517          	auipc	a0,0x1
 1c0:	9a450513          	add	a0,a0,-1628 # b60 <malloc+0x1b2>
 1c4:	b72d                	j	ee <getSyscallName+0xee>
        return "chdir";
 1c6:	00001517          	auipc	a0,0x1
 1ca:	91a50513          	add	a0,a0,-1766 # ae0 <malloc+0x132>
 1ce:	b705                	j	ee <getSyscallName+0xee>
        return "unlink";
 1d0:	00001517          	auipc	a0,0x1
 1d4:	95850513          	add	a0,a0,-1704 # b28 <malloc+0x17a>
 1d8:	bf19                	j	ee <getSyscallName+0xee>
        return "open";
 1da:	00001517          	auipc	a0,0x1
 1de:	93650513          	add	a0,a0,-1738 # b10 <malloc+0x162>
 1e2:	b731                	j	ee <getSyscallName+0xee>
        return "close";
 1e4:	00001517          	auipc	a0,0x1
 1e8:	95c50513          	add	a0,a0,-1700 # b40 <malloc+0x192>
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
 206:	96650513          	add	a0,a0,-1690 # b68 <malloc+0x1ba>
 20a:	00000097          	auipc	ra,0x0
 20e:	6ec080e7          	jalr	1772(ra) # 8f6 <printf>
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
 230:	96450513          	add	a0,a0,-1692 # b90 <malloc+0x1e2>
 234:	00000097          	auipc	ra,0x0
 238:	6c2080e7          	jalr	1730(ra) # 8f6 <printf>
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
 272:	93a50513          	add	a0,a0,-1734 # ba8 <malloc+0x1fa>
 276:	00000097          	auipc	ra,0x0
 27a:	680080e7          	jalr	1664(ra) # 8f6 <printf>
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
 2b8:	91c50513          	add	a0,a0,-1764 # bd0 <malloc+0x222>
 2bc:	00000097          	auipc	ra,0x0
 2c0:	63a080e7          	jalr	1594(ra) # 8f6 <printf>
        }
    }

    exit(0); // Exit the parent process
 2c4:	4501                	li	a0,0
 2c6:	00000097          	auipc	ra,0x0
 2ca:	2a0080e7          	jalr	672(ra) # 566 <exit>
            printf("Error in counting syscalls.\n");
 2ce:	00001517          	auipc	a0,0x1
 2d2:	8e250513          	add	a0,a0,-1822 # bb0 <malloc+0x202>
 2d6:	00000097          	auipc	ra,0x0
 2da:	620080e7          	jalr	1568(ra) # 8f6 <printf>
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

0000000000000626 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 626:	48e9                	li	a7,26
 ecall
 628:	00000073          	ecall
 ret
 62c:	8082                	ret

000000000000062e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 62e:	1101                	add	sp,sp,-32
 630:	ec06                	sd	ra,24(sp)
 632:	e822                	sd	s0,16(sp)
 634:	1000                	add	s0,sp,32
 636:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 63a:	4605                	li	a2,1
 63c:	fef40593          	add	a1,s0,-17
 640:	00000097          	auipc	ra,0x0
 644:	f46080e7          	jalr	-186(ra) # 586 <write>
}
 648:	60e2                	ld	ra,24(sp)
 64a:	6442                	ld	s0,16(sp)
 64c:	6105                	add	sp,sp,32
 64e:	8082                	ret

0000000000000650 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 650:	7139                	add	sp,sp,-64
 652:	fc06                	sd	ra,56(sp)
 654:	f822                	sd	s0,48(sp)
 656:	f426                	sd	s1,40(sp)
 658:	f04a                	sd	s2,32(sp)
 65a:	ec4e                	sd	s3,24(sp)
 65c:	0080                	add	s0,sp,64
 65e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 660:	c299                	beqz	a3,666 <printint+0x16>
 662:	0805c963          	bltz	a1,6f4 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 666:	2581                	sext.w	a1,a1
  neg = 0;
 668:	4881                	li	a7,0
 66a:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 66e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 670:	2601                	sext.w	a2,a2
 672:	00000517          	auipc	a0,0x0
 676:	65e50513          	add	a0,a0,1630 # cd0 <digits>
 67a:	883a                	mv	a6,a4
 67c:	2705                	addw	a4,a4,1
 67e:	02c5f7bb          	remuw	a5,a1,a2
 682:	1782                	sll	a5,a5,0x20
 684:	9381                	srl	a5,a5,0x20
 686:	97aa                	add	a5,a5,a0
 688:	0007c783          	lbu	a5,0(a5)
 68c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 690:	0005879b          	sext.w	a5,a1
 694:	02c5d5bb          	divuw	a1,a1,a2
 698:	0685                	add	a3,a3,1
 69a:	fec7f0e3          	bgeu	a5,a2,67a <printint+0x2a>
  if(neg)
 69e:	00088c63          	beqz	a7,6b6 <printint+0x66>
    buf[i++] = '-';
 6a2:	fd070793          	add	a5,a4,-48
 6a6:	00878733          	add	a4,a5,s0
 6aa:	02d00793          	li	a5,45
 6ae:	fef70823          	sb	a5,-16(a4)
 6b2:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 6b6:	02e05863          	blez	a4,6e6 <printint+0x96>
 6ba:	fc040793          	add	a5,s0,-64
 6be:	00e78933          	add	s2,a5,a4
 6c2:	fff78993          	add	s3,a5,-1
 6c6:	99ba                	add	s3,s3,a4
 6c8:	377d                	addw	a4,a4,-1
 6ca:	1702                	sll	a4,a4,0x20
 6cc:	9301                	srl	a4,a4,0x20
 6ce:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6d2:	fff94583          	lbu	a1,-1(s2)
 6d6:	8526                	mv	a0,s1
 6d8:	00000097          	auipc	ra,0x0
 6dc:	f56080e7          	jalr	-170(ra) # 62e <putc>
  while(--i >= 0)
 6e0:	197d                	add	s2,s2,-1
 6e2:	ff3918e3          	bne	s2,s3,6d2 <printint+0x82>
}
 6e6:	70e2                	ld	ra,56(sp)
 6e8:	7442                	ld	s0,48(sp)
 6ea:	74a2                	ld	s1,40(sp)
 6ec:	7902                	ld	s2,32(sp)
 6ee:	69e2                	ld	s3,24(sp)
 6f0:	6121                	add	sp,sp,64
 6f2:	8082                	ret
    x = -xx;
 6f4:	40b005bb          	negw	a1,a1
    neg = 1;
 6f8:	4885                	li	a7,1
    x = -xx;
 6fa:	bf85                	j	66a <printint+0x1a>

00000000000006fc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6fc:	715d                	add	sp,sp,-80
 6fe:	e486                	sd	ra,72(sp)
 700:	e0a2                	sd	s0,64(sp)
 702:	fc26                	sd	s1,56(sp)
 704:	f84a                	sd	s2,48(sp)
 706:	f44e                	sd	s3,40(sp)
 708:	f052                	sd	s4,32(sp)
 70a:	ec56                	sd	s5,24(sp)
 70c:	e85a                	sd	s6,16(sp)
 70e:	e45e                	sd	s7,8(sp)
 710:	e062                	sd	s8,0(sp)
 712:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 714:	0005c903          	lbu	s2,0(a1)
 718:	18090c63          	beqz	s2,8b0 <vprintf+0x1b4>
 71c:	8aaa                	mv	s5,a0
 71e:	8bb2                	mv	s7,a2
 720:	00158493          	add	s1,a1,1
  state = 0;
 724:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 726:	02500a13          	li	s4,37
 72a:	4b55                	li	s6,21
 72c:	a839                	j	74a <vprintf+0x4e>
        putc(fd, c);
 72e:	85ca                	mv	a1,s2
 730:	8556                	mv	a0,s5
 732:	00000097          	auipc	ra,0x0
 736:	efc080e7          	jalr	-260(ra) # 62e <putc>
 73a:	a019                	j	740 <vprintf+0x44>
    } else if(state == '%'){
 73c:	01498d63          	beq	s3,s4,756 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 740:	0485                	add	s1,s1,1
 742:	fff4c903          	lbu	s2,-1(s1)
 746:	16090563          	beqz	s2,8b0 <vprintf+0x1b4>
    if(state == 0){
 74a:	fe0999e3          	bnez	s3,73c <vprintf+0x40>
      if(c == '%'){
 74e:	ff4910e3          	bne	s2,s4,72e <vprintf+0x32>
        state = '%';
 752:	89d2                	mv	s3,s4
 754:	b7f5                	j	740 <vprintf+0x44>
      if(c == 'd'){
 756:	13490263          	beq	s2,s4,87a <vprintf+0x17e>
 75a:	f9d9079b          	addw	a5,s2,-99
 75e:	0ff7f793          	zext.b	a5,a5
 762:	12fb6563          	bltu	s6,a5,88c <vprintf+0x190>
 766:	f9d9079b          	addw	a5,s2,-99
 76a:	0ff7f713          	zext.b	a4,a5
 76e:	10eb6f63          	bltu	s6,a4,88c <vprintf+0x190>
 772:	00271793          	sll	a5,a4,0x2
 776:	00000717          	auipc	a4,0x0
 77a:	50270713          	add	a4,a4,1282 # c78 <malloc+0x2ca>
 77e:	97ba                	add	a5,a5,a4
 780:	439c                	lw	a5,0(a5)
 782:	97ba                	add	a5,a5,a4
 784:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 786:	008b8913          	add	s2,s7,8
 78a:	4685                	li	a3,1
 78c:	4629                	li	a2,10
 78e:	000ba583          	lw	a1,0(s7)
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	ebc080e7          	jalr	-324(ra) # 650 <printint>
 79c:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 79e:	4981                	li	s3,0
 7a0:	b745                	j	740 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7a2:	008b8913          	add	s2,s7,8
 7a6:	4681                	li	a3,0
 7a8:	4629                	li	a2,10
 7aa:	000ba583          	lw	a1,0(s7)
 7ae:	8556                	mv	a0,s5
 7b0:	00000097          	auipc	ra,0x0
 7b4:	ea0080e7          	jalr	-352(ra) # 650 <printint>
 7b8:	8bca                	mv	s7,s2
      state = 0;
 7ba:	4981                	li	s3,0
 7bc:	b751                	j	740 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 7be:	008b8913          	add	s2,s7,8
 7c2:	4681                	li	a3,0
 7c4:	4641                	li	a2,16
 7c6:	000ba583          	lw	a1,0(s7)
 7ca:	8556                	mv	a0,s5
 7cc:	00000097          	auipc	ra,0x0
 7d0:	e84080e7          	jalr	-380(ra) # 650 <printint>
 7d4:	8bca                	mv	s7,s2
      state = 0;
 7d6:	4981                	li	s3,0
 7d8:	b7a5                	j	740 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 7da:	008b8c13          	add	s8,s7,8
 7de:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 7e2:	03000593          	li	a1,48
 7e6:	8556                	mv	a0,s5
 7e8:	00000097          	auipc	ra,0x0
 7ec:	e46080e7          	jalr	-442(ra) # 62e <putc>
  putc(fd, 'x');
 7f0:	07800593          	li	a1,120
 7f4:	8556                	mv	a0,s5
 7f6:	00000097          	auipc	ra,0x0
 7fa:	e38080e7          	jalr	-456(ra) # 62e <putc>
 7fe:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 800:	00000b97          	auipc	s7,0x0
 804:	4d0b8b93          	add	s7,s7,1232 # cd0 <digits>
 808:	03c9d793          	srl	a5,s3,0x3c
 80c:	97de                	add	a5,a5,s7
 80e:	0007c583          	lbu	a1,0(a5)
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	e1a080e7          	jalr	-486(ra) # 62e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 81c:	0992                	sll	s3,s3,0x4
 81e:	397d                	addw	s2,s2,-1
 820:	fe0914e3          	bnez	s2,808 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 824:	8be2                	mv	s7,s8
      state = 0;
 826:	4981                	li	s3,0
 828:	bf21                	j	740 <vprintf+0x44>
        s = va_arg(ap, char*);
 82a:	008b8993          	add	s3,s7,8
 82e:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 832:	02090163          	beqz	s2,854 <vprintf+0x158>
        while(*s != 0){
 836:	00094583          	lbu	a1,0(s2)
 83a:	c9a5                	beqz	a1,8aa <vprintf+0x1ae>
          putc(fd, *s);
 83c:	8556                	mv	a0,s5
 83e:	00000097          	auipc	ra,0x0
 842:	df0080e7          	jalr	-528(ra) # 62e <putc>
          s++;
 846:	0905                	add	s2,s2,1
        while(*s != 0){
 848:	00094583          	lbu	a1,0(s2)
 84c:	f9e5                	bnez	a1,83c <vprintf+0x140>
        s = va_arg(ap, char*);
 84e:	8bce                	mv	s7,s3
      state = 0;
 850:	4981                	li	s3,0
 852:	b5fd                	j	740 <vprintf+0x44>
          s = "(null)";
 854:	00000917          	auipc	s2,0x0
 858:	41c90913          	add	s2,s2,1052 # c70 <malloc+0x2c2>
        while(*s != 0){
 85c:	02800593          	li	a1,40
 860:	bff1                	j	83c <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 862:	008b8913          	add	s2,s7,8
 866:	000bc583          	lbu	a1,0(s7)
 86a:	8556                	mv	a0,s5
 86c:	00000097          	auipc	ra,0x0
 870:	dc2080e7          	jalr	-574(ra) # 62e <putc>
 874:	8bca                	mv	s7,s2
      state = 0;
 876:	4981                	li	s3,0
 878:	b5e1                	j	740 <vprintf+0x44>
        putc(fd, c);
 87a:	02500593          	li	a1,37
 87e:	8556                	mv	a0,s5
 880:	00000097          	auipc	ra,0x0
 884:	dae080e7          	jalr	-594(ra) # 62e <putc>
      state = 0;
 888:	4981                	li	s3,0
 88a:	bd5d                	j	740 <vprintf+0x44>
        putc(fd, '%');
 88c:	02500593          	li	a1,37
 890:	8556                	mv	a0,s5
 892:	00000097          	auipc	ra,0x0
 896:	d9c080e7          	jalr	-612(ra) # 62e <putc>
        putc(fd, c);
 89a:	85ca                	mv	a1,s2
 89c:	8556                	mv	a0,s5
 89e:	00000097          	auipc	ra,0x0
 8a2:	d90080e7          	jalr	-624(ra) # 62e <putc>
      state = 0;
 8a6:	4981                	li	s3,0
 8a8:	bd61                	j	740 <vprintf+0x44>
        s = va_arg(ap, char*);
 8aa:	8bce                	mv	s7,s3
      state = 0;
 8ac:	4981                	li	s3,0
 8ae:	bd49                	j	740 <vprintf+0x44>
    }
  }
}
 8b0:	60a6                	ld	ra,72(sp)
 8b2:	6406                	ld	s0,64(sp)
 8b4:	74e2                	ld	s1,56(sp)
 8b6:	7942                	ld	s2,48(sp)
 8b8:	79a2                	ld	s3,40(sp)
 8ba:	7a02                	ld	s4,32(sp)
 8bc:	6ae2                	ld	s5,24(sp)
 8be:	6b42                	ld	s6,16(sp)
 8c0:	6ba2                	ld	s7,8(sp)
 8c2:	6c02                	ld	s8,0(sp)
 8c4:	6161                	add	sp,sp,80
 8c6:	8082                	ret

00000000000008c8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8c8:	715d                	add	sp,sp,-80
 8ca:	ec06                	sd	ra,24(sp)
 8cc:	e822                	sd	s0,16(sp)
 8ce:	1000                	add	s0,sp,32
 8d0:	e010                	sd	a2,0(s0)
 8d2:	e414                	sd	a3,8(s0)
 8d4:	e818                	sd	a4,16(s0)
 8d6:	ec1c                	sd	a5,24(s0)
 8d8:	03043023          	sd	a6,32(s0)
 8dc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8e0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8e4:	8622                	mv	a2,s0
 8e6:	00000097          	auipc	ra,0x0
 8ea:	e16080e7          	jalr	-490(ra) # 6fc <vprintf>
}
 8ee:	60e2                	ld	ra,24(sp)
 8f0:	6442                	ld	s0,16(sp)
 8f2:	6161                	add	sp,sp,80
 8f4:	8082                	ret

00000000000008f6 <printf>:

void
printf(const char *fmt, ...)
{
 8f6:	711d                	add	sp,sp,-96
 8f8:	ec06                	sd	ra,24(sp)
 8fa:	e822                	sd	s0,16(sp)
 8fc:	1000                	add	s0,sp,32
 8fe:	e40c                	sd	a1,8(s0)
 900:	e810                	sd	a2,16(s0)
 902:	ec14                	sd	a3,24(s0)
 904:	f018                	sd	a4,32(s0)
 906:	f41c                	sd	a5,40(s0)
 908:	03043823          	sd	a6,48(s0)
 90c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 910:	00840613          	add	a2,s0,8
 914:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 918:	85aa                	mv	a1,a0
 91a:	4505                	li	a0,1
 91c:	00000097          	auipc	ra,0x0
 920:	de0080e7          	jalr	-544(ra) # 6fc <vprintf>
}
 924:	60e2                	ld	ra,24(sp)
 926:	6442                	ld	s0,16(sp)
 928:	6125                	add	sp,sp,96
 92a:	8082                	ret

000000000000092c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 92c:	1141                	add	sp,sp,-16
 92e:	e422                	sd	s0,8(sp)
 930:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 932:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 936:	00000797          	auipc	a5,0x0
 93a:	6ca7b783          	ld	a5,1738(a5) # 1000 <freep>
 93e:	a02d                	j	968 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 940:	4618                	lw	a4,8(a2)
 942:	9f2d                	addw	a4,a4,a1
 944:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 948:	6398                	ld	a4,0(a5)
 94a:	6310                	ld	a2,0(a4)
 94c:	a83d                	j	98a <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 94e:	ff852703          	lw	a4,-8(a0)
 952:	9f31                	addw	a4,a4,a2
 954:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 956:	ff053683          	ld	a3,-16(a0)
 95a:	a091                	j	99e <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 95c:	6398                	ld	a4,0(a5)
 95e:	00e7e463          	bltu	a5,a4,966 <free+0x3a>
 962:	00e6ea63          	bltu	a3,a4,976 <free+0x4a>
{
 966:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 968:	fed7fae3          	bgeu	a5,a3,95c <free+0x30>
 96c:	6398                	ld	a4,0(a5)
 96e:	00e6e463          	bltu	a3,a4,976 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 972:	fee7eae3          	bltu	a5,a4,966 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 976:	ff852583          	lw	a1,-8(a0)
 97a:	6390                	ld	a2,0(a5)
 97c:	02059813          	sll	a6,a1,0x20
 980:	01c85713          	srl	a4,a6,0x1c
 984:	9736                	add	a4,a4,a3
 986:	fae60de3          	beq	a2,a4,940 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 98a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 98e:	4790                	lw	a2,8(a5)
 990:	02061593          	sll	a1,a2,0x20
 994:	01c5d713          	srl	a4,a1,0x1c
 998:	973e                	add	a4,a4,a5
 99a:	fae68ae3          	beq	a3,a4,94e <free+0x22>
    p->s.ptr = bp->s.ptr;
 99e:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 9a0:	00000717          	auipc	a4,0x0
 9a4:	66f73023          	sd	a5,1632(a4) # 1000 <freep>
}
 9a8:	6422                	ld	s0,8(sp)
 9aa:	0141                	add	sp,sp,16
 9ac:	8082                	ret

00000000000009ae <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9ae:	7139                	add	sp,sp,-64
 9b0:	fc06                	sd	ra,56(sp)
 9b2:	f822                	sd	s0,48(sp)
 9b4:	f426                	sd	s1,40(sp)
 9b6:	f04a                	sd	s2,32(sp)
 9b8:	ec4e                	sd	s3,24(sp)
 9ba:	e852                	sd	s4,16(sp)
 9bc:	e456                	sd	s5,8(sp)
 9be:	e05a                	sd	s6,0(sp)
 9c0:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9c2:	02051493          	sll	s1,a0,0x20
 9c6:	9081                	srl	s1,s1,0x20
 9c8:	04bd                	add	s1,s1,15
 9ca:	8091                	srl	s1,s1,0x4
 9cc:	0014899b          	addw	s3,s1,1
 9d0:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 9d2:	00000517          	auipc	a0,0x0
 9d6:	62e53503          	ld	a0,1582(a0) # 1000 <freep>
 9da:	c515                	beqz	a0,a06 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9de:	4798                	lw	a4,8(a5)
 9e0:	02977f63          	bgeu	a4,s1,a1e <malloc+0x70>
  if(nu < 4096)
 9e4:	8a4e                	mv	s4,s3
 9e6:	0009871b          	sext.w	a4,s3
 9ea:	6685                	lui	a3,0x1
 9ec:	00d77363          	bgeu	a4,a3,9f2 <malloc+0x44>
 9f0:	6a05                	lui	s4,0x1
 9f2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9f6:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9fa:	00000917          	auipc	s2,0x0
 9fe:	60690913          	add	s2,s2,1542 # 1000 <freep>
  if(p == (char*)-1)
 a02:	5afd                	li	s5,-1
 a04:	a895                	j	a78 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a06:	00000797          	auipc	a5,0x0
 a0a:	60a78793          	add	a5,a5,1546 # 1010 <base>
 a0e:	00000717          	auipc	a4,0x0
 a12:	5ef73923          	sd	a5,1522(a4) # 1000 <freep>
 a16:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a18:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a1c:	b7e1                	j	9e4 <malloc+0x36>
      if(p->s.size == nunits)
 a1e:	02e48c63          	beq	s1,a4,a56 <malloc+0xa8>
        p->s.size -= nunits;
 a22:	4137073b          	subw	a4,a4,s3
 a26:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a28:	02071693          	sll	a3,a4,0x20
 a2c:	01c6d713          	srl	a4,a3,0x1c
 a30:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a32:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a36:	00000717          	auipc	a4,0x0
 a3a:	5ca73523          	sd	a0,1482(a4) # 1000 <freep>
      return (void*)(p + 1);
 a3e:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a42:	70e2                	ld	ra,56(sp)
 a44:	7442                	ld	s0,48(sp)
 a46:	74a2                	ld	s1,40(sp)
 a48:	7902                	ld	s2,32(sp)
 a4a:	69e2                	ld	s3,24(sp)
 a4c:	6a42                	ld	s4,16(sp)
 a4e:	6aa2                	ld	s5,8(sp)
 a50:	6b02                	ld	s6,0(sp)
 a52:	6121                	add	sp,sp,64
 a54:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a56:	6398                	ld	a4,0(a5)
 a58:	e118                	sd	a4,0(a0)
 a5a:	bff1                	j	a36 <malloc+0x88>
  hp->s.size = nu;
 a5c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a60:	0541                	add	a0,a0,16
 a62:	00000097          	auipc	ra,0x0
 a66:	eca080e7          	jalr	-310(ra) # 92c <free>
  return freep;
 a6a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a6e:	d971                	beqz	a0,a42 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a70:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a72:	4798                	lw	a4,8(a5)
 a74:	fa9775e3          	bgeu	a4,s1,a1e <malloc+0x70>
    if(p == freep)
 a78:	00093703          	ld	a4,0(s2)
 a7c:	853e                	mv	a0,a5
 a7e:	fef719e3          	bne	a4,a5,a70 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 a82:	8552                	mv	a0,s4
 a84:	00000097          	auipc	ra,0x0
 a88:	b6a080e7          	jalr	-1174(ra) # 5ee <sbrk>
  if(p == (char*)-1)
 a8c:	fd5518e3          	bne	a0,s5,a5c <malloc+0xae>
        return 0;
 a90:	4501                	li	a0,0
 a92:	bf45                	j	a42 <malloc+0x94>
