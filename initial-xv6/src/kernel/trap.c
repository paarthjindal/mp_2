#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#define NULL ((void *)0)

struct spinlock tickslock;
uint ticks; // stores the time

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}
#define total_queue 4

int get_time_slice(int priority)
{
  switch (priority)
  {
  case 0:
    return 1;
  case 1:
    return 4;
  case 2:
    return 8;
  case 3:
    return 16;
  default:
    return 1;
  }
}
// #define BOOST_INTERVAL 48
// void boost_all_processes(void)
// {
//   struct proc *p;
//   for (int i = 0; i < NPROC; i++)
//   {
//     p = &proc[i];
//     if (p->state != UNUSED)
//     {
//       p->priority = 0;              // Move all processes to priority 0
//       p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
//       enqueue(0, p);                // Enqueue into priority 0
//     }
//   }
// }

void adjust_process_priority(struct proc *p)
{
  // Check if the process has exhausted its time slice
  if (p->ticks_count >= get_time_slice(p->priority))
  {
    // Move to the next lower priority queue if not already at the lowest level
    if (p->priority < total_queue - 1) // Assuming total_queue is the number of queues
    {
      // Move the process to a lower priority
      p->priority++;
    }
  }
  else
  {
    // If the process has not exhausted its time slice, we can choose to keep it in the same queue.
    // Optional: You could implement logic here to possibly increase the priority based on behavior.
  }

  // Reset the tick count for the next time slice
  p->ticks_count = 0; // Reset ticks count for the next time slice
}

void lastscheduled(void)
{
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == RUNNING)
    {
      p->lastscheduledticks = 0;
    }
    else if (p->state == RUNNABLE)
    {
      p->lastscheduledticks += 1;
    }
  }
}

void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);
    myproc()->lastscheduledticks = 0;

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
    myproc()->lastscheduledticks = 0;
    // ok
  }
  else
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if (killed(p))
  {
    exit(-1);
  }
  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2)
  {

    if (SCHEDULER == 2)
    {
      // Timer interrupt
      // boost_ticks++;
      // if (p && p->state == RUNNING)
      // {
      //   // Increment the tick count for the current process
      //   p->ticks_count++;
      //   // need to implement aging over here
      //   // Get the time slice for the current process's priority
      //   int time_slice = get_time_slice(p->priority);

      //   // Preempt only if the process has used up its time slice
      //   if (p->ticks_count >= time_slice)
      //   {
      //     // Move process to the next queue (if applicable) and reset ticks
      //     adjust_process_priority(p);
      //     // Reset process ticks for the next time slice
      //     p->ticks_count = 0;
      //     yield();
      //   }
      //   // Check for process boosting
      //   if (ticks% BOOST_INTERVAL==0)
      //   {
      //     boost_all_processes(); // Boost all processes to the highest priority
      //     // boost_ticks = 0;       // Reset the boost tick counter
      //   }

      //   // Check for preemption by looking for a higher priority process
      //   struct proc *higher_priority_process = NULL;
      //   for (int i = 0; i < total_queue; i++)
      //   {
      //     if (i < p->priority) // Only check higher priority queues
      //     {
      //       struct proc *temp = mlfq_queues[i].head;
      //       while (temp != NULL)
      //       {
      //         if (temp->state == RUNNABLE)
      //         {
      //           higher_priority_process = temp; // Found a higher priority process
      //           break;                          // No need to continue searching
      //         }
      //         temp = temp->next; // Move to the next process
      //       }
      //     }
      //     if (higher_priority_process)
      //       break; // Exit the outer loop if we found a higher priority process
      //   }

      //   // If a higher priority process is found, preempt the current process
      //   if (higher_priority_process)
      //   {
      //     // Dequeue the current process
      //     if(p&&p->state==RUNNABLE)
      //     {
      //     dequeue(p->priority, p);
      //     enqueue(p->priority,p);
      //     }
      //     // Yield to the higher priority process
      //     yield();
      //     return; // Exit to re-evaluate which process to run
      //   }
      // }
      // i am shifting mine implementation to without queues commenting it
      lastscheduled();
      p->ticks += 1;
      int flag = 0;
      // over here mine start_time will always remain equal to zero cause its called at the start of the function not schedulertest
      // if ((ticks - start_time) % BOOST_INTERVAL == 0)
      // {
      //   printf("%d\n", start_time);

      //   boost_all_processes();
      // }
      for (struct proc *t = proc; t < &proc[NPROC]; t++)
      {
        if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
        {
          t->lastscheduledticks = 0;
          t->priority = 0;
          if (p->priority > t->priority)
          {
            flag = 1;
            break;
          }
        }
      }
      if (p->priority == 0 && p->ticks == 1)
      {
        p->priority = 1;
        p->ticks = 0;
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
        {
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
          {
            t->lastscheduledticks = 0;
            t->priority = 0;
          }
        }
        yield();
      }
      else if (p->priority == 1 && p->ticks == 4)
      {
        p->priority = 2;
        p->ticks = 0;
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
        {
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
          {
            t->lastscheduledticks = 0;
            t->priority = 0;
          }
        }
        yield();
      }
      else if (p->priority == 2 && p->ticks == 8)
      {
        p->priority = 3;
        p->ticks = 0;
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
        {
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
          {
            t->lastscheduledticks = 0;
            t->priority = 0;
          }
        }
        yield();
      }
      else if (p->priority == 3 && p->ticks == 16)
      {
        p->ticks = 0;
        for (struct proc *t = proc; t < &proc[NPROC]; t++)
        {
          if (t->lastscheduledticks >= BOOST_INTERVAL && t->priority != 0 && t->state == RUNNABLE)
          {
            t->lastscheduledticks = 0;
            t->priority = 0;
          }
        }
        // printf("RUNNER:%d\n",p->pid);
        yield();
      }
      else if (flag == 1)
      {
        yield();
      }
    }
    else
    {
      if (p != 0 && p->state == RUNNING)
      {
        p->ticks_count++;
        if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
        {
          p->alarm_on = 0; // Disable alarm while handler is running
          p->alarm_tf = kalloc();
          if (p->alarm_tf == 0)
            panic("Error !! usertrap: out of memory");
          memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
          p->trapframe->epc = (uint64)p->alarm_handler;
          p->ticks_count = 0;
        }
      }
      yield();
    }
    if (p != 0 && p->state == RUNNING)
    {
      p->ticks_count++;
      if (p->alarm_interval > 0 && p->ticks_count >= p->alarm_interval && p->alarm_on)
      {
        p->alarm_on = 0; // Disable alarm while handler is running
        p->alarm_tf = kalloc();
        if (p->alarm_tf == 0)
          panic("Error !! usertrap: out of memory");
        memmove(p->alarm_tf, p->trapframe, sizeof(struct trapframe));
        p->trapframe->epc = (uint64)p->alarm_handler;
        p->ticks_count = 0;
      }
    }
  }
  // if(which_dev == 2){

  // // yield();
  // }

  usertrapret();
}
//
// return to user space
//
void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
