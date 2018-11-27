---
title: ASISCTF Finals 2018
date: 2018-11-27 12:50:05
categories: 
 - Write-Ups
 - ASIS CTF
tags:
 - re
 - huffman-coding
 - patching
---

So I competed ASIS CTF Finals 2018 as part of team dcua. It was a nice
experience even though I personally was able to really tackle one problem: Light
Fence. (I also helped with other problems, but this was the main problem that
was done by myself). In the end this problem was only solved by two other teams
(which were also the top 3 teams), so I was pretty happy for solving this
problem.

## Light Fence
So a brief rundown of the problem, it takes an input file as argument. It will
also accept an optional `-d` (for decode) or `-e` (for encode) flag along with
the file to decode or encode. If no flag is supplied `-e` is assumed. The
problem is the decode operation is actually not implemented yet (would've made
the problem super easy then). 

In the encode algorithm, it creates two temporary files, a `*.nsg` file and a
`*.nsg.huff` file. These are two steps in an encoding algorithm. The first step
I have no idea about, but I had a strong intuition that the second step is a
[huffman coding](https://en.wikipedia.org/wiki/Huffman_coding) step. This
algorithm is also used as a basis for many compression algorithms found in
formats like ZIP and PNG. 

### Reversing Saga
I put this here to explain my process of thinking about this interesting
program. If you want the answer of how I did it, click [here](#Patching)

Originally I thought about simply reversing the encoding algorithms. And I got a
bit way before deciding against it (after all I also wanted to see a huffman 
coding algorithm in the works). So I started with the NSG encoding; it took a
while but I found that there are two steps in it. 

In the first step, the algorithm scrambles the order by first creating a "view"
of the entire stream by starting with the current character at some index, and
then moving forward with each character, wrapping around, until all characters
are visited. Then all the views are then placed into a list and sorted as if
each view represent a different string of that same data from some index. Then
the scrambled version would just simply be the previous character in that view
going down the list. 

This may be very useless, but in fact by picking the previous character down the
list, we can create a state machine graph detailing a partial ordering of the
characters. Of course I was a bit rusty in graph algorithm stuff, so I was kinda
lazy to solving it... But here's an example:

```
Example: Suppose I have this text "asgj3". Then each view would be

a: asgj3
s: sgj3a
g: gj3as
j: j3asg
3: 3asgj

Then sorted, we get:
3: 3asgj
a: asgj3
g: gj3as
j: j3asg
s: sgj3a

We take the following characters:
3: 3asg[j]
a: asgj[3]
g: gj3a[s]
j: j3as[g]
s: sgj3[a]

And our scrambled string would be 'j3sga'.

Since we can still sort this scrambled string, we get the following information:
j3sga
|||||
VVVVV
3agjs

Or said differently: 
j->3
3->a
s->g
g->j
a->s

And when you chain them together:
a->s->g->j->3->a...

And it also gives you the index of the smallest character. Then you can recover
the original string: `asgj3`.
```

The next step involves taking a look up table F(x), and the inverse G(y), and
then rotating this look up table for each character, encoding a new string from
this look up table. 

### Patching
Now the second part of NSG was easy to reverse, the first part took too much
algo, so I was reluctant to writing a decode algorithm. Then I realized maybe I
don't have to write one. My teammate told me that the decode functions were
actually embeded in the program itself... The huffman decoding algorithm was at
`0x18A0`, and the nsg decoding algorithm was at `0x14a0`. The nsg decoding
algorithm took two parameters, an input file and output file, but the huffman
decoding algorithm took four parameters! 

The first two were the input and output file, but the next two I didn't know
what it was. I was a bit confused at first, but slowly I realized that the third
parameter took the header+4 256-byte table of the enc file, which I realized
later was the table of bit-lengths for each character. Then the fourth character
was simply a number of bits to skip from the end. This was found at the
character offset +3. This was necessary because huffman coding encoding works on
the bit level, and may sometimes end up with an number trailing of bits at the
end because the file would have to be encoded in units of bytes.

I decided the easiest way was to do a patching of the binary file, so I wrote
some [basic assembly code][1] to write the decoding function, taking in a single
parameter: the encoded filename. To minimize the linking that would otherwise
need to be done, I wrote my own versions for some library functions, and used
raw syscalls instead of libc wrappers. In hindsight I should've at least just
linked `printf` as well, since that would result in less library functions that
I need to write. 

Then finally the patching! So I decided to overwrite the function at `0x1cb0`,
since it was considerably long, and it wasn't actually used in the executable
since it was optimized out. Oh, I also had to patch the `main` function where it
calls the "not-implemented" decode function, to instead call my decode function.

I wrote a patch script to do that for me:
```sh
#!/bin/bash
set -e

BIN=light_fence.elf
PATCH=$BIN.patched

cp $BIN $PATCH

TEMP=$(mktemp)
exec 3<> $TEMP

# Patch the call at 0xb67
echo -e "\x44\x11" >&3
dd conv=nocreat,notrunc bs=1 count=2 if=$TEMP of=$PATCH seek=2920
rm $TEMP

nasm unencrypt.asm
dd conv=nocreat,notrunc bs=1 count=526 if=unencrypt of=$PATCH seek=7344
```

Originally when I ran it, the nsg conversion seemed to work perfectly, but I had
trouble reproducing the huff decoding. I thought it was an issue with the huff
decoding in the binary, but I wasn't sure. I had no time debugging, so I decided
to write my own huffman decoding algorithm. I also had no time to reverse their
algorithm, so I went blindly and assumed that it was a huffman coding algorithm,
and decided to do mix of blackbox and whitebox reversing. This time my gamble
worked perfectly, and I have the [code here][2]. It was quite fun having to
write an huffman decoding algorithm on the spot here, and I would say that now I
have a very detailed understanding of how huffman coding really works, and have
a deeper understanding of how ZIP files compress data.

After the CTF, when writing this up, I realized that my own assembly code was to
blame (oops!)... I was passing the wrong argument to the huff decode function...
But I would not regret having to write a huffman decode algorithm... it was a
fun experience to do!

If you want to play around with the patched "fully implemented" encode/decode
binary, [here it is](/files/asisctf/light_fence.elf.patched).

[1]: https://gist.github.com/theKidOfArcrania/e793b05167bb2f2b05a308dcc9fb842b
[2]: https://gist.github.com/theKidOfArcrania/33dd72f10c45750c48062d03d8ccbb19
