---
title:  "RE^2"
date:   2018-03-21 00:11:36 -0500
categories:
 - Blogs
tags:
 - re2
---

A while back, I wrote an esoteric assembly language called [RE^2][1]. The main 
purpose of this language was to write for a [CTFLearn problem][2]. I will take
this time to briefly explain the mechanics for this language. (If you are trying
to solve this problem, hehehe... you struck gold). First, a background story
behind this:

RE^2 came about from the idea that you would have to reverse engineer the
assembler interpreter and then any code written in that esoteric assembly
language. The interpreter (which was written in Java) should've been easily
disassembled, even without accompanying source code, since Java itself is
relatively easy to have automatic decompilation to a degree that produces
somewhat readable source code. At the time of this writing, I had an intrigue
towards both the x86 assembly and Java bytecode, whom I based this assembly
language off of. I made this a hybrid of Java bytecode and x86 assembly. This
allowed me to create an interesting language to explore some of the typical
exploits (buffer overflow, ROP) in a different surrounding.

RE^2 does many of its arithmetic operations off of the stack, i.e. the
instructions `ADD`, `SUB`, `MULT`, `DIV`, and the assorted binary bitwise 
operations internally pop two values from the stack (in reverse order) and then
push the result value back on the stack. This implicit stack allows for much
more condensed instructions (without the need of operands in the basic
instructions). Of course this does incur a large speed deficiency (doesn't
matter in a small scale scenareo) with the frequent access to the stack memory. 

Here's a brief example of the RE^2 language: 

```
.entry start

#Text section
.section
.base 0x1000

start:
  enter              # Prepare bp-stack

  # Load address of encrypted code
  push  $0x2000      # code
  loadb code
  jmp   loop_cond

loop:
  push  $97          # 'a'
  sub                # *code - 'a'
  dup
  dup
  jn    loop_bad1    # Skip if *code < 'a'
  push  $25          # 'z' - 'a'
  sub
  jp    loop_bad2    # Skip if *code > 'z'

  loadw 2(%SP)       # Load stack value 1 up (code)
  pop   %0

  push  $13          
  add
  push  $26
  mod
  push  $97          # 'a'
  add
  storeb (%0)        # *code = ((*code - 'a') + 13) % 26 + 'a'

  jmp loop_incr
loop_bad1:
  pop
loop_bad2:
  pop
loop_incr:  
  push  $1
  add                # code++
  dup
  pop   %0
  loadb (%0)         # *code
loop_cond:
  dup
  jnz   loop         # Loop back if we have not encountered nullbyte

  pop

  outputstr code     # Output decrypted messsage

  leave
  exit $0
  

#Data section
.section
.base 0x2000

code:
  .str "uryyb jbeyq!\n"
```

This code performs an ROT13 on the `code` string and then prints out `hello
world!` As can be noted by the code, I created this language just to demonstrate
an aspect of illegibility in assembler code because of the complex states when
you involve a stack. For example within that loop, we duplicated our current
character read of our string on the stack, but if we prematurely exit that loop,
i.e. if the character was outside a particular bounds, we had to then clean up
the stack and remove those extra values (or we could ignore that and let the
bp-based stack fix that). 

This code, unlike x86, has a lot of its states in the stack itself, and in fact,
the registers play a minimal role in the code (it only serves any purpose in
indirect memory loads/stores). 

This was a code that I created a while back just as a brainteaser. After an year
or so (and learning how a RISC language like MIPS works), I find this particular
instruction set quite amateur because of its inconsitency and such. Looking back 
on this project, I think I would definitely had made the language a little more 
standard (either completely utilize a stack, or just use registers to perform 
operations). Nevertheless, it was amazing how convoluted assembly code could get, 
even compared to MIPS or x86, when you involve operations on a stack. 

[1]: https://github.com/theKidOfArcrania/RE-2-Language
[2]: https://ctflearn.com/index.php?action=find_problem_details&problem_id=319
