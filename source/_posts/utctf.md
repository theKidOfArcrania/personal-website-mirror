---
title: UTCTF-19
date: 2019-03-11 22:31:04
 - Write-Ups
 - UTCTF
tags:
 - brop
---

Last weekend I competed at UTCTF with team dcua (or at least representing dcua,
as this was only open to American university students, and up to 5 people).

Wow. UT has it's own CTF now! Woot. Now I'm jealous, 'cause my university, UTD
has not done a ctf :'( . Anyways, UT is a special university in my heart, as I
have quite a few highschool friends down at UT right now, and I have a few
(small) connections with the officers down there, (and it would also be the
university that I would've been at had I not chosen UTD, tehehe!) 

Honestly, the CTF was quite a blast and I had a lot of fun with the pwns. One of
my favs was the ECHO challenge. (The PPC was just very annoying and I would say
that was the one challenge that caused us 2nd place) :/  Hey! When there's
basically only pwner on the team (you) there's kinda a huge pressure on the
whole thing... plus I was busy for half of the time qqqqqqq...

Okay so I am currently sitting on loads of homework, which I totally ignored
over the CTF, so I might be unable to do writeups for many challenges. Probably
just gonna write ECHO for now.

Anyways enough talk, and let's move on to the CTF writeups! Woot, woot!

## ECHO

### tl;dr
See this [article][1] for more detail. First bruteforce stack layout, then
search for ROP gadgets, then find a `write` function, leak binary, and then
finally get shell and profit.

This IS NOT a beginner's blog. So before trying to understand this one, I would
suggest maybe looking at `babypwn`, and understand stack overflow and ROP stuff
first!

### Scratching my head
Okay so initially when I opened the problem description, I instinctively decided
to click the download button to download binary, but I clicked on it, I got a
hint instead:

> socket fd is always 4.

Huh... weird... no binary to REad... So next thing I decided to just copy-paste
the netcat command to see what it is. Okay so it is some sort of echo server
(duh!): you input some data, it prints out some data. 

At this point, I decided to play with it a bit. First thing I always try, is
input a lot of data, as this may be a sign of some overflow. Hmm... weird, it
seems to just hang like that, and doesn't close the connection... weird... I
also see to try printf stuff (unlikely) as this was the bug in `babyecho`.
Nothing for format errors.

I've also made a few other observations with this program. This program hangs
actually under two conditions: (a) if you enter too much at once (I think it was
16 characters), and (b) after 10 seconds it will also hang. I say "hang" but not
really, as that is the behavior I get when I run it under netcat. In both cases, 
the server actually closes prematurely or crashes as I will mention later on.

So this is probably a buffer overflow thing. One thing that was weird tho, why
when an error occurred my netcat connection doesn't close at all... *weird*...
I'm guessing on the server side, it only shuts down the write side, and not the
read side, anyways, I don't know. In my code, if I did a `shutdown(write)` after
I finish writing the echo line, the socket seems to close promptly after a crash
occurs. Great! This will come in handy later on. 

At this point, I wanted to look at other problems as this seems too fuzzy to
really get a good grip on it. Plus the admin was like this problem was so much
"fun" to write it, I thought there has to be a lot more to it than just a crash. 

### Bruteforcing for profit
Then after a few moments, I had a breakthrough... I had remembered xoreaxeaxeax
talk about some [sandsifter][2] tool in a talk [here][3]. Basically this program
utilizes technique called **tunneling** (I will explain later) to try to probe
for undocumented or unknown x86 instructions found on different chipsets.

Tunneling is a method of only incrementing the last byte of an instruction
Then if this change results in a different exception or instruction length, we
traverse further along this instruction incrementing the last byte again. This
ensures minimizing testing of unuseful/similar instructions and instead focuses
more time on fuzzing instruction opcodes/prefixes, etc... Of course, 
xoreaxeaxeax's [white paper][4] on this explains it in a lot more detail (see
section IV). 

Now I decided to implement a simpler version of this. I decided to start by
sending a 1 byte input, permutating last byte with all 256 values. I know that
if the server crashes, it will immediately exit after my input; otherwise, it
will continue and prompt me for a second input. This is the binary answer that I
want to differentiate between inputs, (note that I would have to invoke a
`shutdown(write)` so that the prompting will not take forever on a wait
timeout). Then if I find a small fraction that "crashes" or "passes" then I will
choose a value from that set and move on. Otherwise, if all of them is one way
or the other, I just choose "A" for simplicity. Here is my [brute script][5].

I also ended up adding multiple threads to try to get the result faster. At this
point I got something like this: `'A' * 16 + p64(0x7fff262c0500) + 
p64(0x400ddf) + 'A' * 12 + p32(4) + 'AAAAAAAAA....'`. Apparently, I tried
setting this to run for a bit longer, but I didn't get much success beyond
that... apparently, any string after that seems to work. One thing that I got a
bit hung up was why that random `4`. I'll let you think about this for a sec ;)

### Piece by piece, brick by brick, ROP by ROP
At this point, I had absolutely no idea what to do. I knew that the large
pointer was probably a stack pointer, the next was a return address, (and
apparently the LSB of the return address had a lot of potential candidates,
which made sense). So I knew I was dealing with some sort of blind-ROP stuff.
Except I don't know how to do it qqqqqqqq.... T\_T. 

At this point, I decided I could just test out all the potential addresses and
see what I come up with... *maybe* there's a magical address that gets me shell
(nope!). I decided to go through every single address to see if I can get some
sort of special output. I don't think I could've gotten much from it since there
was so much data to filter through. Also I noticed some of the outputs took a
little bit longer than others... hmm... that's odd. I thought I had that
`shutdown(write)` thing going on. Well turns out this will be important later on
;)

Also then there was that random 4 in the stack... hmm... OOOHHH! The hint.
That's probably the socket fd (which explains, if I change that, I don't get
printed output at all)! Ultimately, though I still don't know how to solve it.

So I decided to ping hk to see what he has to say. He referred me to [this][1]
article, which was definitely a HUGE help and a boost to my moral. So I went
along and quicky skimmed the article and went and continued. So first I needed
to find two differing gadgets: a "crash" or "halt" gadget, and a "stop" or
"hang" gadget. When retesting all the possible return values, I found that
`0x4009aa` was a good candidate for hanging the system. For crash, I just took
an address that was definitely not a valid address: `0xffffffff`. 

To make my test more robust, I added two more test results, a `PASS` and a
`READ` case. The `PASS` occurs if execution appears to print out some stuff. The
`READ` case occurs if and only if the program hangs when I do not do a
`shutdown(read)` (and it is fine when do do that). Okay for determining hangs, I
normally set timeout to something low, .5 seconds initially, but than ramp it up
to 5 seconds if necessary to confirm a hang (so I don't waste too many cycles
whenever I don't need to test for hangs). 

Here's my [full script][7] that details the steps I took while crafting my brop,
and piecing together the entire binary. There are a few commented out lines
corresponding to steps I took. This may also not fully work as the stack
addresses may have changed from execution to execution. 

Then the article suggest to search for ROP gadgets. To search, for example, a
single pop gadget, you can prepare the stack as such:

```
+---------------------------------+
| probe | crash | hang | crash... |
+---------------------------------+
```

Where `probe` is the return address we want to test if it is a ROP. This means
that the server will hang if and only if this probe pops a stack element, AND
THEN returns, returning execution to `hang`. The article then suggests searching
for a 6-POP ROP (or BROP) as this had a very "unique" signature found in every
single x86-64 linux binary, and corresponds to the following assembly code
(found in `__libc_init_csu`):

![The almighty BROP gadget][6]

This is also pretty nice as it also contains a `pop rsi` and `pop rdi` so I can
control first two arguments of a function. Then the article calls to find
`strcmp`, although it didn't really work for me in this challenge, and I found
that I didn't need to do that as rdx is already set to some low non-zero value.
After a bit of pins and needles, my script (miraculously) generated this segment
of output: 

```
0x00400bfb: potential BROP
  0x00400bfb: POP(6)
0x00400bfc: potential BROP
  0x00400bfc: POP(5)
0x00400bfd: potential BROP
  0x00400bfd: POP(4)
0x00400bfe:
0x00400bff: potential BROP
  0x00400bff: POP(3)
0x00400c00: potential BROP
  0x00400c00: POP(3)
0x00400c01: POP(2)
0x00400c02: POP(2)
0x00400c03: POP(1)
0x00400c04: POP(1)
```

Hooray! That's exactly the type of signature that I would get from finding a
BROP seen above. See the interesting thing is with `pop r##`, there is a prefix
byte that comes before a base pop instruction, which will modify the register to
use a different set of registers, so `41 5f` maps to `pop r15`, but `5f` alone
maps to `pop rdi`. 

At this point, it was late, I had somewhere to go Sunday morning, and it was
daylight saving qqqq...  Now, come afternoon, when I came back to this
challenge, I went to the next step, which was to figure out where the .plt
section was.

### Plt and the road to leak success
The article then reasons that to find a potential spot for PLT is a place where
no crashes occur approximately 16 bytes away (since most PLT functions cause no
crashes at all, and syscall functions only return error codes). To check that it
is correct, if some address causes no crash, 6 bytes later should also have no
crash. I found that PLT started roughly somewhere around `0x400880`. 

Now comes to find the functions. I found a `strcmp` function, and when I tried
searching for the `write` function, it didn't work for me like I said. So I
decided in a last ditch effort to remove `strcmp` from my ROP chain and start
probing for write.

So I can easily control first two arguments. First must be fd (which is 4),
second must be some address, and third must be some positive length (which I
cannot easily control). After stripping out the `strcmp` I just hope to see the
iconic ELF or `7f454c46` in hex signature of an ELF binary. After a bit of
fudging, I found this in my logs:
```
Testing 0x004008b0
Testing 0x004008c0
  PASS (4, roaddr)
*******
7f454c4602010100000000000000000002003e0001000000200a4000000000004000000000000000a82e0000000000000000000040003800090040001f001c0006
*******
Testing 0x004008d0
Testing 0x004008e0
  PASS (4, roaddr)
*******
```

### Profit $$$
Whoot, woot, woot! So it looks like `write@plt` is at `0x4008c0`!!!! Yeah let's
go! Now time to go leak the binary, which is easy here, as it was simply just
modifying my ROP chain to change the second argument. Also I needed to leak libc
via the got address. In other problems, I think UT uses ubuntu 16.04 `libc_23`
version, so I just assumed it was same here. Turns out the GOT address of writes
seems to match up on the binary. So now I have a much larger arsenal of ROPs to
choose from. I can potentially now control RDX and RAX, (which is enough to
build a ROP syscall chain). 

I had one complication when trying to call `system`. It would completely not
work. I also made sure to do the dup(4, {0|1|2}) properly, so that shell will
work. After solving it, I realized they actually disabled fork (by limiting the
number of processes that can be run to 1, doh!). Okay so I ended up writing a
syscall execve ROP chain, and that worked. And I got flag. QED. 

This was a fun challenge, kudos to @hk, and first time I heard of BROP! Also
@hk, you owe me a 3d-printed prize! :P

![That msg tho uwu][8]

[1]: http://www.scs.stanford.edu/brop/bittau-brop.pdf
[2]: https://github.com/xoreaxeaxeax/sandsifter
[3]: https://www.youtube.com/watch?v=KrksBdWcZgQ
[4]: https://github.com/xoreaxeaxeax/sandsifter/blob/master/references/domas_breaking_the_x86_isa_wp.pdf
[5]: https://gist.github.com/theKidOfArcrania/1338229bd53c3684b4735dd9eec22fe6
[6]: /files/utctf/echo/brop.png
[7]: https://gist.github.com/theKidOfArcrania/4d0fb3703ebba639353cc467431afa0f
[8]: /files/utctf/echo/prize.png
