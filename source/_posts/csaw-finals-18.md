---
title: "CSAW Finals 2018 Writeups"
date: 2018-11-18
categories:
 - Write-Ups
 - CSAW 2018
tags:
 - csaw
 - pwnadventure
---

Hey everyone! I came back from a long 36-hour CSAW ctf finals competition,
competing as dcua. 

So I wrote a quick (long) reflection on [what I thought about CSAW ctf][1]. Here
are some of the writeups that I have for CSAW CTF

## Pwn Adventure: Sourcery
This was a fun game released by Vector35. My personal thanks to the team who
wrote this game just for CSAW 2018!

To start off you had to write some assembly code to "cast" a fire spell, and
`ebx` can be changed to modify the power level of the fire. So looks like they
have an x86 emulator within the game.

So they give you a "Spell Extractor" which you can use to extract "enchantment"
spells and code. This is also x86 code (32-bit). Interestingly, they use the
`in` and `out` family of instructions to communicate directly with certain I/O
ports (such as output and stuff like that). 

They also give you a "Pwn Tool" that can send/read data to the console or the
"enchanted" object via using I/O ports (you write to port 0 as user input, and
read from port 1 to read code output, and write to port 2 to write debug data.)

Originally, I thought that you can use the in/out instructions to read from
ports of the console/object, but quickly I realized that that is not the case.

### Cheats
Before I start explaining some of the flags walkthrough, I want to divert a bit.
So basically all the flags here do NOT need you to cheat the game, i.e. all can
be solved in-game. However, we are hackers, and we want to go through the game
much more quickly and smoothly. Unfortunately, during the competition I was not
able to find a way to cheat the game (probably it was because I never done
web-assembly before). After the competition, I found that I can modify the
memory directly in javascript using the `HASH##` global variables. I ended up
searching for the health/mana scores in the memory, changing it a bit, to find
the indicies... err... addresses of where these values reside in memory.
Unfortunately, I think the addresses are randomized each time, so I ended up
writing some [code](http://bit.ly/2DO2aPE) to do that for me. This code is a
userscript that runs on TamperMonkey whenever you load the game. 

As part of the program, you press Ctrl+B twice (when you have different
health/mana scores) and it will automatically search where these values are.
After that the program will set your health and mana to max rapidly so that it
appears that you have infinite health and mana. Here is a run through of my
cheat (the glitches in the music are due the fact that the cheat program is
trying to search through the same memory that is used by the pwnadventure game)

<iframe width="560" height="315" src="https://www.youtube.com/embed/NlUmgsNbQlk"
frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope;
picture-in-picture" allowfullscreen></iframe>

I had particular disliking towards the spiders during the competition as
I had to manually play through everything :\

### Jailbreak

![Break out of jail!][2]

The first "console" was a hard-coded passcode `5129`. Enter that and you pass.

The second "console" read in a line as a string, and compared it with some
secure password that was read off of another I/O port. This was pretty evident
that it was a simple buffer overflow issue. So we just overflowed the return
address, and redirected it to the access granted code:

```x86asm
mov ecx, exp_len - exp
mov esi, exp
mov dx, 0
rep outsb
hlt

exp:
  db "12345678901234567890123456789012345678901234", 0xa7, 0x10, 0x00, 0x00, '\n'
exp_len:
```

### Zombie boss battle

Before we were able to get to ANY other challenge, we had to go to deadwood, (go
in town and then kill the zombie boss). 

![(Getting beaten by) the zombie boss][3]

This was particularly frustrating because we had to manually play through this
game... (no cheats :/ ). Anyways after that battle, you get an exploding rod
which you need to explode the stone in the mountain area. Then you go south to
a desert area. In that area you will see two entrances, one leads to the 'Cave
of Nope' (which I foolishly went into and wasted a bunch of time there), and the
other (farther down) leads to a lab area. There are three lab segments, and all
of them are reverse engineering problems

### Lab 1

![Entering the PIN for lab 1][4]

This time, we can only enter "printable" characters, which means we can't do a
ROP exploit... we will have to enter a valid PIN id. Okay so we have this
verification code: ([full code here][6])

```x86asm
verify_code:
  push esi
  push ebp
  mov ebp, esp
  sub esp, 8

  push dword [ebp + 12]
  call strlen
  cmp eax, 16
  jne .bad

  mov esi, [ebp + 12]
  lea edx, [ebp - 8]
  mov ecx, 8
.loop1:
  mov al, [esi]
  xor al, [esi + 8]
  mov [edx], al
  inc esi
  inc edx
  loop .loop1

  lea esi, [ebp - 8]
  mov edx, valid
  mov ecx, 8
.check:
  mov al, [esi]
  cmp al, [edx]
  jne .bad
  inc esi
  inc edx
  loop .check

  mov al, 1
  mov esp, ebp
  pop ebp
  pop esi
  ret 4

.bad:
  xor al, al
  mov esp, ebp
  pop ebp
  pop esi
  ret 4
```

Okay so the first loop simply xors the 0th/8th input character, 1st/9th,
2nd/10th, etc... Then The check loop compares this xor result (addressed as
`esi`, and stored on stack) with the `valid` array, which is defined somewhere
else: 

```x86asm
valid:
  db 0x09, 0x23, 0x06, 0x07, 0x36, 0x38, 0x22, 0x2c
```

So basically we need to find two characters, when xor'ed will have the result
stored in the `valid` array. The only catch is that it has to be printable. So
my answer was this `0@00@@@@9c67vxbl`. 

We also get hover boots, which are needed to pass over the bridge to enter the
swamp area. We will explore there some time later.

### Lab 2
Onto lab 2! Our second lab is a little bit more difficult to complete... here is
our verify code: ([full code here][5])

```x86asm
verify_code:
  push esi
  push ebp
  mov ebp, esp
  sub esp, 8

  push dword [ebp + 12]
  call strlen
  cmp eax, 16
  jne .bad

  mov esi, [ebp + 12]

  mov edx, 0xfa
  mov al, [esi]
  rol edx, 5
  xor dl, al
  add dl, 0xab
  mov al, [esi+1]
  rol edx, 3
  xor dl, al
  add dl, 0x45
  mov al, [esi+2]
  rol edx, 1
  xor dl, al
  add dl, 0x12
  mov al, [esi+3]
  rol edx, 9
  xor dl, al
  add dl, 0xcd
  mov cl, dl
  and cl, 15
  add cl, 'a'
  cmp [esi+4], cl
  jne .bad
  and cl, 15
; ... full code cut for brevity
  rol edx, 6
  xor dl, cl
  add dl, 0xf1
  mov cl, dl
  and cl, 15
  add cl, 'e'
  cmp [esi+13], cl
  jne .bad
  rol edx, 3
  xor dl, cl
  add dl, 0x1f
  mov cl, dl
  and cl, 15
  add cl, 'B'
  cmp [esi+14], cl
  jne .bad
  rol edx, 4
  xor dl, cl
  add dl, 0x90
  mov cl, dl
  and cl, 15
  add cl, 'f'
  cmp [esi+15], cl
  jne .bad
  add cl, 'f'
  cmp [esi+15], cl
  jne .bad

  mov al, 1
  mov esp, ebp
  pop ebp
  pop esi
  ret 4
```

So the full code is extremly long so I cut it out. But essentially, it you note
carefully, it is basically performing a very similar monotonous algorithm for
all the letters. The algorithm take the first few letters to initialize some
sort of state. Then with the next few letters, it will take the current state of
`cl` and `dl`, do some stuff with it, and then check that the user input
character is equal to that. 

Most of the operations appear to only apply to the single character. There is
one exception to that rule: the `rol` actually works with 32-bit values, so
eventually some of those values from previous rounds will begin to eventually
factor into the lower 8 bit in a rather unpredicatable manner. Because of this
complexity, I have decided to just simply copy the assembly code, and then have
it print out the PIN id, rather than checking the PIN id. Even with the
printable character requirement, I can actually choose any random initial state,
and it will generate a valid state because of the `and cl, 15; add cl, ...`
instructions, which guarenteed that the value we are comparing with is
printable, as long as the add offset is well within the printable range. This is
my [solver code][7] (which uses nasm+nasmx to work). The key that it generates
is `DSFFdcChiFRoOeBf`. Okay cool we pass this lab.

### Lab 3

Okay now onto lab 3! Okay when I opened this code, I was a bit in a shock to see
how much code it has... (but most of it is very repetitive). Immediately, I went
to the decipher function and ignored everything else for the moment (this will
bite me later on...). Here's that code snippet, (and the [full code][8]): 

```x86asm
decipher:
  push   ebp
  mov    ebp,esp
  push   esi
  push   ebx
  mov    ecx,dword [ebp+0x8]
  mov    edx,dword [ecx]
  mov    esi,dword [ecx+0x4]
  mov    eax,edx
  mov    ebx,edx
  shr    ebx,0x5
  shl    eax,0x4
  xor    eax,ebx
  add    eax,edx
  xor    eax,0x2913260a
  sub    esi,eax
  mov    ebx,esi
  mov    eax,esi
  shr    esi,0x5
  shl    ebx,0x4
  xor    ebx,esi
  add    ebx,eax
  xor    ebx,0x37dbdd6f
  sub    edx,ebx
  ; code trimmed here...
  mov    ebx,eax
  mov    esi,eax
  mov    dword [ecx+0x4],eax
  shr    esi,0x5
  shl    ebx,0x4
  xor    ebx,esi
  add    ebx,eax
  xor    ebx,0xdeadbeef
  sub    edx,ebx
  mov    dword [ecx],edx
  pop    ebx
  pop    esi
  pop    ebp
  ret  
```

So first we note that the argument passed to `decipher` is a pointer to some
buffer user input, and it is reading the first 8 bytes into `edx` and `esi`.
Then clearly we go through some sort of loop which puts this data into several
hundred rounds of encryption.

Then after decipher returns, the program goes into this code to check...
```x86asm
  cld
  mov    esi, v0
  lodsd
  cmp    eax, 0x57415343    ; 'CSAW'
  jne    .fail
  lodsd
  cmp    eax, 0x41484148    ; 'HAHA'
  jne    .fail
```

...that user input array now decrypts to two numbers `0x57415343` and
`0x41484148`

For this problem I decided to just simply assemble this code, and pop it into
IDA Hexrays. We find that this serverely simplifies the code:

```c
void decipher(char *a1) {
  v2 = a1[1] - ((*a1 + ((*a1 >> 5) ^ 16 * *a1)) ^ 0x2913260A);
  v3 = *a1 - ((v2 + ((v2 >> 5) ^ 16 * v2)) ^ 0x37DBDD6F);
  v4 = v2 - ((v3 + ((v3 >> 5) ^ 16 * v3)) ^ 0x772CA820);
  v5 = v3 - ((v4 + ((v4 >> 5) ^ 16 * v4)) ^ 0xD8F52E67);
  v6 = v4 - ((v5 + ((v5 >> 5) ^ 16 * v5)) ^ 0x99A463B6);
  // ... code snippet cut here
  v737 = v735 - ((v736 + ((v736 >> 5) ^ 16 * v736)) ^ 0x9B7A3D38);
  v738 = v736 - ((v737 + ((v737 >> 5) ^ 16 * v737)) ^ 0xA5A527E9);
  v739 = v737 - ((v738 + ((v738 >> 5) ^ 16 * v738)) ^ 0xC81CE37F);
  v740 = v738 - ((v739 + ((v739 >> 5) ^ 16 * v739)) ^ 0xC81CE37F);
  v741 = v739 - ((v740 + ((v740 >> 5) ^ 16 * v740)) ^ 0x69363477);
  v742 = v740 - ((v741 + ((v741 >> 5) ^ 16 * v741)) ^ 0x5F0B49C6);
  a1[1] = v742;
  *a1 = v741 - ((v742 + ((v742 >> 5) ^ 16 * v742)) ^ 0xDEADBEEF);
}
```

Now we can more easily sift through this code... taking into account that we are
using 32-bit integers for these computations, we can simply represent each
round as a recurance relationship of previous rounds:

```
f(0) = a1[1]
f(1) = a1[0]
f(n) = f(n-2) - (mix(f(n-1)) ^ XOR[n-2]) (mod 2**32)

where:
mix(x) = x + ((x >> 5) ^ (16 * x))
```

Okay so we know that the last two values that this recurance must end with, i.e.
`f(n+k) = 0x57415343` and `f(n+k-1) = 0x41484148`. So all we have to do is
extract the xor'd values, and we can solve the recurance relationship backwords! 

Now the only think I completely blew past at first was how to format this
answer. At this point, I was so happy I found the code breaker that I forgot
that this thing is reading in hex numbers. If only I looked at the code more
closely I would see a line that says:

```
; read in the input, expect "XXXXXXXX-XXXXXXXX"
```

Facepalm... oh well. That took me a while to realize that. But after that I
solve it. Here's my python code (without the xor values):

```python
from lab3_values import values
from struct import pack
from binascii import hexlify

def mix(x):
    return (x + ((x >> 5)^(x<<4))) & 0xffffffff

fn     = 0x57415343
fprev  = 0x41484148

for x in values[::-1]:
    tmp = (fn + (mix(fprev) ^ x)) & 0xffffffff
    fn = fprev
    fprev = tmp

#print("a[0:4] = {}; a[4:8] = {}".format(fn, fprev))
print(hex(fn)[2:] + '-' + hex(fprev)[2:])
```

And the correct PIN is: `9b916917-b6117336`. Okay I got all three labs, three
flags, and a key. Now onto the other stuff!

### Swamp Maze
![Can you lead the robot to the end?][8]

Okay so the premise of this game is you have a robot that you can program to do
whatever you want. To get here, you need to get hover boots from lab 1, and hop
over the broken bridge. You have to deal with some sharks, and then arrive at a
lab. The first challenge was getting the robot to move forward. This task is
done by using the `SYS_WALK` syscall: (Note that we also can't have null bytes
in our code.

```x86asm
mov esi, payload
mov ecx, payload_len - payload
mov dx, 0
rep outsb
hlt

payload:
  xor eax, eax
  mov al, SYS_WALK
  mov ebx, -1  ; x-vel
  xor ecx, ecx ; y-vel
  int 0x80
  hlt
payload_len:
```

This code is used by the pwntool to write new code for the robot. When the robot
executes this command, it will walk in the negative x direction.

Now then with this baby challenge out of the way, we see the next challenge is
to guide the robot through a maze. Of course the (small) problem was that the
robot only had 64 bytes of memory (not a lot!) to work with...

We didn't actually solve this problem during the competition, but afterwards, we
asked team perfect blue, and they told us that they just had the robot follow
whereever the character went (facepalm!). Anyway here's the code I wrote after
the contest:

```x86asm
mov esi, payload
mov ecx, payload_len - payload
mov dx, 0
rep outsb
hlt

payload:
  mov ebp, esp
  sub esp, 0x60
.loop:
  pause
  xor eax, eax
  xor ebx, ebx
  xor edx, edx

  mov al, SYS_SCAN_AREA
  dec bl
  mov ecx, esp
  mov dl, 0x60
  int 0x80

  lea edi, [ebp - 0x60]
  mov bl, SCAN_PLAYER

  xor ecx, ecx
.scan_loop:
  cmp ecx, eax
  jge .loop

  imul edx, ecx, 12
  cmp dword [edi + edx + 8], ebx
  jne .not_found

  mov al, SYS_WALK
  mov ebx, [edi + edx]
  mov ecx, [edi + edx + 4]
  int 0x80
  jmp .loop
.not_found:
  inc ecx
  jmp .scan_loop
  db 0x00
payload_len:
```

Yeah so that was that, and then we had to fight the boss battle, which was
freaking annoying if you didn't have a cheat. The first time I tried solving
through this challenge (after the competition) the boss somehow glitched and did
not spawn any rats after some time. 

# Hacker Overlord
This one was the final boss challenge. Again we have a buffer overflow, but this
time we also have "ASLR" and a stack canary, so not as easy to exploit. To be
continued...

[1]: /2018/11/12/csaw-finals-reflect/
[2]: /files/csaw/jailbreak.png
[3]: /files/csaw/zombie.png
[4]: /files/csaw/lab.png
[5]: https://gist.github.com/theKidOfArcrania/7d3744c443bce6eee7093dbf9401d32a
[6]: https://gist.github.com/theKidOfArcrania/ab7e05c14a097346db6c3a13b0308cf9
[7]: https://gist.github.com/theKidOfArcrania/d179283b221a1e6d72a79bed057bf42b
[8]: /files/csaw/maze.png
