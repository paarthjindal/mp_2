#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include <sys/time.h> // For gettimeofday()
#include <time.h>
// Define the default scheduler if none is selected
#define total_queue 4
#define TICKS_0 1  // 1 timer tick for priority 0
#define TICKS_1 4  // 4 timer ticks for priority 1
#define TICKS_2 8  // 8 timer ticks for priority 2
#define TICKS_3 16 // 16 timer ticks for priority 3
#define BOOST_INTERVAL 48

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.

struct queue mlfq_queues[total_queue]; // this is mine array of size 4

void init_queues()
{
  for (int i = 0; i < total_queue; i++)
  {
    mlfq_queues[i].head = NULL;
    mlfq_queues[i].tail = NULL;
  }
}

void enqueue(int priority, struct proc *p)
{
  if (priority < 0 || priority >= total_queue)
  {
    printf("Enter valid priority\n");
    return;
  }
  // Set next pointer to NULL
  p->next = NULL;

  // Insert into the linked list  we need to insert at the end
  if (mlfq_queues[priority].tail)
  {
    mlfq_queues[priority].tail->next = p; // Append to the end
  }
  else
  {
    mlfq_queues[priority].head = p; // First element
  }
  mlfq_queues[priority].tail = p; // Update tail
}

struct proc *dequeue(int priority)
{
  if (priority < 0 || priority >= total_queue)
  {
    return NULL;
  }
  // Remove from the front of the linked list
  struct proc *p = mlfq_queues[priority].head;
  if (p != NULL)
  {
    mlfq_queues[priority].head = p->next; // Update head
    if (!mlfq_queues[priority].head)
    {
      mlfq_queues[priority].tail = NULL; // List is empty
    }
  }
  return p;
}

void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,sy
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  // Search for an UNUSED process slot
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found; // Found an UNUSED process
    }
    else
    {
      release(&p->lock); // Release lock if not UNUSED
    }
  }
  return 0; // No UNUSED process found, return 0

found:
  p->pid = allocpid(); // Assign PID
  p->state = USED;     // Mark process as USED

  // Initialize syscall_count array after process is allocated
  for (int i = 0; i < 31; i++)
  {
    p->syscall_count[i] = 0;
  }
  p->tickets = 1; // since by default a process should have 1 ticket
  p->creation_time = ticks;

  // Allocate a trapframe page
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);       // Clean up if allocation fails
    release(&p->lock); // Release lock
    return 0;
  }

  // Allocate user page table
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);       // Clean up if allocation fails
    release(&p->lock); // Release lock
    return 0;
  }

  // Set up the new context to start executing at forkret
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  p->rtime = 0;     // Initialize runtime
  p->etime = 0;     // Initialize exit time
  p->ctime = ticks; // Record creation time
  p->alarm_interval = 0;
  p->alarm_handler = 0;
  p->ticks_count = 0;
  p->alarm_on = 0;

  p->priority = 0;              // Start in highest priority queue
  p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
  enqueue(0, p);                // Add to queue 0

  return p; // Return the newly allocated process
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  p->tickets = 1;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
  np->tickets = p->tickets;  // ensuring that the child and the parent has the same tickets as specified in the document
  np->creation_time = ticks; // record its creation time
  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {

          for (int i = 0; i < 31; i++)
          {
            p->syscall_count[i] = pp->syscall_count[i];
          }

          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

#define MAX_SIZE 1000 // Max size for the random number list

int lst[MAX_SIZE]; // Array to store generated random numbers
int lst_index = 0; // Keep track of the current index in the array

// Simple implementation of `atol` (convert string to long integer)
long simple_atol(char *str)
{
  long res = 0;
  for (int i = 0; str[i] != '\0'; ++i)
  {
    res = res * 10 + str[i] - '0';
  }
  return res;
}
static unsigned long seed = 123456789; // Initialize with a fixed seed

int get_random_seed()
{
  // Parameters for the LCG
  const unsigned long a = 1103515245;
  const unsigned long c = 12345;
  const unsigned long m = (1UL << 31); // 2^31

  // Update the seed and return a pseudo-random seed
  seed = (a * seed + c) % m;
  return (int)(seed % 10000); // Use the last 4 digits of the generated number
}

void long_to_padded_string(long num, int total_length, char *result)
{
  int len = 0;
  long temp = num;

  // Calculate the number of digits in the number
  do
  {
    len++;
    temp /= 10;
  } while (temp > 0);

  // Add leading zeros if necessary
  int padding = total_length - len;
  for (int i = 0; i < padding; i++)
  {
    result[i] = '0';
  }

  // Convert the number to a string starting after the padding
  for (int i = total_length - 1; i >= padding; i--)
  {
    result[i] = (num % 10) + '0';
    num /= 10;
  }

  result[total_length] = '\0'; // Null-terminate the string
}

int pseudo_rand_num_generator(char *initial_seed, int iterations)
{
  if (iterations == 0 && lst_index > 0)
  {
    return lst[lst_index - 1]; // Return the last generated number
  }

  int seed_size = strlen(initial_seed);
  long seed_val = simple_atol(initial_seed); // Convert the seed to an integer
  if (seed_val == 0)
  {
    seed_val = get_random_seed(); // Use dynamic seed if seed is 0
  }

  for (int i = 0; i < iterations; i++)
  {
    // Square the seed value
    seed_val = seed_val * seed_val;

    // Extract the middle portion of the squared value as the new seed
    char seed_str[30]; // Buffer large enough for seed as string

    // Manually convert the seed_val to a string with zero-padding
    long_to_padded_string(seed_val, 2 * seed_size, seed_str);

    int mid_start = seed_size / 2;
    char new_seed[seed_size + 1];
    strncpy(new_seed, seed_str + mid_start, seed_size); // Extract middle part
    new_seed[seed_size] = '\0';                         // Null-terminate

    // Convert back to long and store in the list
    lst[lst_index++] = simple_atol(new_seed);

    // Use this new seed for the next iteration
    seed_val = simple_atol(new_seed);
  }

  // Return the last generated number
  return lst[lst_index - 1];
}
// Returns a random number in the range [1, max]
// Helper function to convert an integer to a string
void int_to_string(int num, char *result)
{
  int len = 0;
  int temp = num;

  // Calculate the number of digits in the number
  do
  {
    len++;
    temp /= 10;
  } while (temp > 0);

  // Convert the number to a string (from the end towards the start)
  result[len] = '\0'; // Null-terminate the string
  for (int i = len - 1; i >= 0; i--)
  {
    result[i] = (num % 10) + '0';
    num /= 10;
  }
}

// int random_at_most(int max)
// {
//   // Generate a random number using the pseudo-random number generator
//   char seed[6];
//   int_to_string(get_random_seed(), seed); // Convert dynamic seed to string

//   int random_num = pseudo_rand_num_generator(seed, 10); // Generate 10 random iterations
//   return 1 + (random_num % max);                        // Return number in the range [1, max]
// }
// static unsigned long seed = 123456789;

// perhaps mine infinite loop reason is because of the way i am generating mine random numbers

int simple_rand()
{
  const unsigned long a = 1103515245;
  const unsigned long c = 1234567;
  const unsigned long m = (1UL << 31);

  seed = (a * seed + c) % m;
  return (int)(seed % 10000); // Return a number between 0 and 9999
}

int random_at_most(int max)
{
  int random_num = simple_rand(); // Use the LCG for random generation
  return 1 + (random_num % max);  // Return a number in the range [1, max]
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.

void round_robin_scheduler(void) // it is a round robin approach for scheduling of various processes (its the default processor)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}

void lottery_scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;

  for (;;)
  {
    // printf("LBSSSSSSS\n");
    // Enable interrupts on this processor to avoid deadlocks.
    intr_on();

    int total_tickets = 0;   // Total number of tickets for all RUNNABLE processes
    struct proc *winner = 0; // Store the winning process

    // Calculate total number of tickets for all RUNNABLE processes
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        total_tickets += p->tickets; // Accumulate total tickets
      }
      release(&p->lock);
    }

    // If no tickets, there are no runnable processes, continue the loop
    if (total_tickets == 0)
    {
      continue;
    }
    // printf("reaching 1\n");
    // Randomly select a winning ticket
    // Generate a random number in the range [1, total_tickets]
    // int winning_ticket = (rand() % total_tickets) + 1;

    int winning_ticket = random_at_most(total_tickets); // Generate a random number in the range [1, total_tickets]
    int ticket_counter = 0;                             // Track ticket count while iterating over processes

    // Find the winning process by counting tickets until the winner is reached
    for (p = proc; p < &proc[NPROC]; p++)
    {
      if (p == 0)
      {
        continue; // avoiding the null pointers
      }
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        ticket_counter += p->tickets; // Increment the ticket counter

        // If the ticket counter exceeds the winning ticket, select this process
        if (ticket_counter >= winning_ticket)
        {
          // If no winner yet, or this process has fewer tickets, or arrived earlier with the same number of tickets
          if (winner == 0 || p->tickets > winner->tickets ||
              (p->tickets == winner->tickets && p->ctime < winner->ctime))
          {
            winner = p; // This process becomes the winner
            release(&p->lock);

            break;
          }
        }
      }
      release(&p->lock);
    }
    // printf("reaching 2\n");

    // Run the winning process
    if (winner != 0)
    {
      acquire(&winner->lock);
      if (winner->state == RUNNABLE)
      {
        winner->state = RUNNING;
        c->proc = winner;

        // Context switch to the winning process
        swtch(&c->context, &winner->context);

        // Process has finished running, reset CPU's proc
        c->proc = 0;
      }
      release(&winner->lock);
    }
    else
    {
      continue;
    }
    // printf("reaching 3\n");

    // yield();
  }
}
int get_ticks_for_priority(int priority)
{
  switch (priority)
  {
  case 0:
    return TICKS_0; // 1 tick for priority 0
  case 1:
    return TICKS_1; // 4 ticks for priority 1
  case 2:
    return TICKS_2; // 8 ticks for priority 2
  case 3:
    return TICKS_3; // 16 ticks for priority 3
  default:
    return TICKS_0; // Default to priority 0 if something goes wrong
  }
}

// Boost all processes to priority 0
void boost_all_processes(void)
{
  struct proc *p;
  for (int i = 0; i < NPROC; i++)
  {
    p = &proc[i];
    if (p->state != UNUSED)
    {
      p->priority = 0;              // Move all processes to priority 0
      p->remaining_ticks = TICKS_0; // Assign the time slice for priority 0
      enqueue(0, p);                // Enqueue into priority 0
    }
  }
}

int boost_ticks = 0; // Global variable to track boost intervals
void mlfq_scheduler(void)
{
  struct proc *p;
  struct proc *selected_proc = 0;
  struct cpu *c = mycpu();
  c->proc = 0;

  for (;;)
  {
    intr_on();

    // Priority boosting: Every X ticks, move all processes to queue 0
    if (boost_ticks >= BOOST_INTERVAL)
    {
      boost_all_processes(); // Boost all processes back to the highest priority queue
      boost_ticks = 0;       // Reset boost tick counter
    }

    // Traverse all queues from highest (0) to lowest (total_queue - 1)
    for (int i = 0; i < total_queue; i++)
    {
      selected_proc = 0;

      // Iterate over all processes in queue i
      for (p = mlfq_queues[i].head; p != 0; p = p->next)
      {
        if (p->state == RUNNABLE) // Check if the process is runnable
        {
          selected_proc = p; // Select the first RUNNABLE process
          break;             // Once we find a RUNNABLE process, we stop searching this queue
        }
      }

      // If a process was found in this queue, run it
      if (selected_proc)
      {
        break; // Exit the queue traversal loop
      }
    }

    // If no process is found (all queues empty), continue the loop
    if (!selected_proc)
    {
      continue; // No process found, just continue the loop
    }

    // Run the selected process
    acquire(&selected_proc->lock); // Lock the selected process

    if (selected_proc->state == RUNNABLE)
    {
      selected_proc->state = RUNNING; // Change state to RUNNING
      c->proc = selected_proc;

      // Perform context switch to the selected process
      swtch(&c->context, &selected_proc->context);

      // The process finished its time slice or voluntarily yielded the CPU
      c->proc = 0;

      // Decrease remaining time slice for this process
      selected_proc->remaining_ticks--;

      // Check if the process used up its time slice
      if (selected_proc->remaining_ticks <= 0)
      {
        // If the process hasn't finished and is still runnable, lower its priority
        if (selected_proc->priority < total_queue - 1)
        {
          selected_proc->priority++; // Move to a lower-priority queue
        }
        // Reset the remaining time slice for the new priority level
        selected_proc->remaining_ticks = get_ticks_for_priority(selected_proc->priority);
        enqueue(selected_proc->priority, selected_proc); // Requeue the process
      }
      else
      {
        // Requeue the process in the same queue if it hasn't used up its slice
        enqueue(selected_proc->priority, selected_proc);
      }
    }

    release(&selected_proc->lock); // Release the lock for the selected process
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.

void scheduler(void)
{
  // printf("value of scheduer is %d",SCHEDULER);
  
  // printf("laaiwndlq\n");
  if (SCHEDULER == 2)
  {
    printf("mlfq will run");
    mlfq_scheduler();
  }
  else if (SCHEDULER == 1)
  {
    printf("LBS will run\n");
    lottery_scheduler();
  }
  else
  {
    printf("are you always running instead of others\n");
    round_robin_scheduler(); // Round-robin or default scheduler
  }

  // Indicate to the compiler that this code should never return
  __builtin_unreachable();
}

void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
    }
    release(&p->lock);
  }
}