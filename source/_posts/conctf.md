---
title: Confidence CTF 2019
date: 2019-03-19 12:09:52
tags: 
 - windows
 - ptrace
 - re
 - debug-ception
categories:
 - Write-Ups
 - ConfidenceCTF'19
---

## Watchmen

So first glance at this binary, I noticed that it is a windows binary (ewww!) so
that was kinda annoying. I also took a quick glance at the code, I saw some sort
of assembly instructions (did the orgs link this binary to some
assembler/disassembler code?). Initially, I thought I would have to actually
reverse this code, but turns out, it wasn't necessary (either it wasn't used or
doesn't play an essential role, I don't know).

So initially, digging throught the code, IDA has easily demarcated the main
function (that was cool). Initally I found that the code was very simple, and I
was wondering when the code would start getting hairy. So in the main function I
get this code:

```c
int __cdecl main(int argc, const char **argv, const char **envp)
{
  int v4; // [esp-Ch] [ebp-44h]
  int v5; // [esp-8h] [ebp-40h]
  int v6; // [esp-4h] [ebp-3Ch]
  PROCESS_INFORMATION a1; // [esp+14h] [ebp-24h]
  int err; // [esp+24h] [ebp-14h]
  int v9; // [esp+28h] [ebp-10h]
  int v10; // [esp+2Ch] [ebp-Ch]

  sub_435EC0();
  init_procs();
  v9 = CreateMutexA(0, 1, "DYNAMIC_EXEC");
  err = GetLastError_0(v4, v5, v6);
  v10 = 0;
  if ( !v9 )
    v10 = 1;
  if ( err == ERROR_ALREADY_EXISTS )
    myst();
  if ( err )
  {
    v10 = 1;
  }
  else
  {
    fork(&a1);
    ptrace(a1.hProcess, a1.hThread);
    ReleaseMutex(v9);
  }
  if ( v10 )
    exit(1);
  return 0;
}

int __cdecl ptrace(HANDLE hProcess, HANDLE hThread)
{
  init_bkpts();
  return do_debug(hProcess, hThread);
}

int __cdecl do_debug(HANDLE hProcess, HANDLE hThread)
{
  int result; // eax
  struct _DEBUG_EVENT DebugEvent; // [esp+1Ch] [ebp-6Ch]
  int v4; // [esp+7Ch] [ebp-Ch]

  v4 = 0;
  result = memset_0(&DebugEvent, 0, 96);
  while ( !v4 )
  {
    WaitForDebugEvent(&DebugEvent, 0xFFFFFFFF);
    if ( DebugEvent.dwDebugEventCode == EXCEPTION_DEBUG_EVENT )
    {
      dbg_handle_exc(hProcess, hThread, &DebugEvent);
    }
    else if ( DebugEvent.dwDebugEventCode == EXIT_PROCESS_DEBUG_EVENT )
    {
      v4 = 1;
    }
    result = ContinueDebugEvent(DebugEvent.dwProcessId, DebugEvent.dwThreadId, 0x10002u);
  }
  return result;
}
```

Okay so looks simple enough. It looks like it is creating some sort of mutex so
that... oh noes... can it be... is it trying to do some sort of debugger inception
like the [keygenme][1] problem that I tried to solve in Google CTF??? Gasp!

Back in keygenme, I found that the parent "debugger" was actually hot-patching
some parts of the child "debuggee" as soon as the child reaches that
instruction. In that place a few `int3` instructions are carefully placed to do
just that, notifying the parent that the child has reached that spot.

A slight note: the `fork` and `ptrace` functions that I have labeled here are
actually my own naming, as that is what I think those two functions are doing
(in relation to keygenme) but in reality, there are no fork and ptrace functions
in Windows xD xD.

Apparently the mutex is used here to cause the child to fork to a separate
function `myst()`. Initially that function had a `ud2` instruction, but then I
noticed in `do_debug()` the parent will then hot-patch those locations as soon
as it receives a `SIGILL` (or `EXCEPTION_ILLEGAL_INSTRUCTION` in Windows lingo).
Okay, so far, it looks very much like the same thing, but when I looked at the
code for handling exceptions, I noticed two branches:

```
int __cdecl dbg_handle_exc(HANDLE hProcess, HANDLE hThread, _DEBUG_EVENT *a3)
{
  _DEBUG_EVENT::$1CA59A7E570F154F98F56770E4FE79B4 v3; // [esp+18h] [ebp-60h]
  void *addr; // [esp+6Ch] [ebp-Ch]

  qmemcpy(&v3, &a3->u, sizeof(v3));
  addr = v3.Exception.ExceptionRecord.ExceptionAddress;
  if ( v3.Exception.ExceptionRecord.ExceptionCode != EXCEPTION_SINGLE_STEP )
  {
    if ( v3.Exception.ExceptionRecord.ExceptionCode != EXCEPTION_ILLEGAL_INSTRUCTION )
      JUMPOUT(&unk_40182E);
    exc_ill(hProcess, hThread, addr);
    JUMPOUT(unk_40182E);
  }
  exc_step(hProcess, hThread, addr);
}
```

Judging from this code, it looks like that the code is actually single stepping
after it reaches the SIGILL, and each single step, some sort of patching is
occurring, i.e. being done by `WriteProcessMemory`. Another annoying thing is
that it will revert previous patches before making new patches. 

Okay, at this point, I did not want to actually go and reverse that
huge junk of code, so I was bent on using some `strace` equivalent on Windows. I
had a bit of issue trying to set it up. I found that [DynamoRIO][2] is probably
one of the de-facto instrumentation tools used on Windows, but I couldn't find a
easy way to use it. I also used drstrace, but I realized that it apparently
failed to print out the actual data (and it also produced a lot of other noise,
as each patch was paired up with an unpatch, and it quickly got confusing.

> Anyways a quick disclaimer: this is kinda one of my first takes on reversing
Windows binaries; that being said, I have very little experience as to how to
properly do this...

At this point, I was lazy to learn DynamoRIO, so I decided to do a bit of low
assembly monkey patching. I decided to hook both the `WriteProcessMemory` 
function and the tail end of the debug exception handler function
(`dbg_handle_exc` here). I then printed out hexdump of the WriteProcessMemory
and location, along with whenever the process continues execution, so that way I
know when the changes invoked by `WriteProcessMemory` are commited and the
instruction pointer is advanced once forward.

Here's the [final form] of my patch code (and after the n-th time of trying to
mess with IDA's gui, I decided to fully automate the patch part with a script.

I decided to place the bulk of my hook code at address `0x431BF4`, since it
appears that code is some dead code. Anyways, hopefully that did not cause any
issues down the line. After this, I ran the program, cross my fingers (it didn't
work initially), and got this:

```
Cont 0x80000003 from @ 779A0F74
Write @ 00401E69
  c9 8d
Write @ 00401E69
  55 95 a9 bd 94 10 b1 0e 08 28 96 55 ca b0 c3 0b
Cont 0xc000001d from @ 00401E69
Write @ 00401E69
  c9 8d 31 9b 2a 56 57 12 7a b0 72 15 fe 36 4d 4f
Write @ 00401E69
  0f 0b
Write @ 00401E6A
  95
Write @ 00401E6A
  89 e5 1b c4 e2 7b 26 d0 3a 78 b1 62 42 93 3f ab
Cont 0x80000004 from @ 00401E6A
...
```

Which is very nice, because now I can go into python and process these patches.
What I ended up doing is run through each patch in python and stepping one
instruction through, printing that instruction to output and then rinse and
repeat. Here's my [parse python script][4]. I ended up with this interesting
[instruction trace][5] (with a lack of other words to say...):
```x86asm
00401e6a+2: mov ebp, esp
00401e6c+3: sub esp, 0x48
00401e6f+7: mov dword ptr [esp], 0x43a0cc
00401e76+5: call 0x436e44
00436e44+0: ???
00436e44+6: jmp dword ptr [0x43d1e0]
774e8d2c+0: ???
00401e7b+3: lea eax, [ebp - 0x2a]
...
```

which was a freaking cool display. It is basically what you would get if you
flattened out ALL the calls and jumps into a linear line. I also ended up
removing duplicates that would printed out, as there were many nested loops
inside this thing. 

Anyways, I ended up spending a bit of time trying to reconstruct and repatch the
binary in IDA (manually), as I was having a bit too much fun just unravelling
this code, teehee, but I ended up with this decompiled code:

```c
void __noreturn myst()
{
  char buff[32]; // [esp+1Eh] [ebp-2Ah]
  char v1; // [esp+3Fh] [ebp-9h]

  puts("Once you realize what a joke everything is, being the Comedian is the only thing that makes sense.");
  scanf("%32s", buff);
  fflush((FILE *)iob[0]._ptr);
  v1 = check(buff);
  if ( v1 )
    puts("What happened to the American Dream? It came true! You're lookin' at it.");
  else
    puts("No. Not even in the face of Armageddon. Never compromise");
}

int __cdecl check(char *inp)
{
  int result; // eax

  encrypt(inp);
  result = memcmp(correct, inp, 0x20u);
  LOBYTE(result) = result == 0;
  return result;
}

void __cdecl encrypt(char *a1)
{
  signed int i; // [esp+10h] [ebp-4h]

  for ( i = 0; i <= 15; ++i )
    sub_401DDF(a1);
}

void __cdecl sub_401DDF(char *a1)
{
  xor_msg(a1);
  shift(a1);
  shuffle(a1);
}

void __cdecl xor_msg(char *a1)
{
  signed int i; // [esp+Ch] [ebp-8h]

  for ( i = 0; i <= 31; ++i )
    a1[i] ^= aOctober12th198[i];
}

void __cdecl shift(char *a1)
{
  char v1; // [esp+Bh] [ebp-5h]
  signed int i; // [esp+Ch] [ebp-4h]

  v1 = *a1;
  for ( i = 0; i <= 30; ++i )
    a1[i] = *(_WORD *)&a1[i] >> 4;
  a1[31] = 16 * v1 | ((unsigned __int8)a1[31] >> 4);
}

int __cdecl shuffle(char *inp)
{
  int result; // eax
  char tmp_arr[32]; // [esp+Ch] [ebp-B4h]
  int lookup[32]; // [esp+2Ch] [ebp-94h]
  unsigned __int8 tmp; // [esp+AFh] [ebp-11h]
  const char *shuf; // [esp+B0h] [ebp-10h]
  int k; // [esp+B4h] [ebp-Ch]
  int j; // [esp+B8h] [ebp-8h]
  int i; // [esp+BCh] [ebp-4h]

  shuf = "I am tired of Earth, these people. I'm tired of being caught in the tangle of their lives.";
  for ( i = 0; i <= 31; ++i )
  {
    lookup[i] = i;
    tmp_arr[i] = inp[i];
  }
  for ( j = 0; ; ++j )
  {
    result = (unsigned __int8)shuf[j];
    if ( !(_BYTE)result )
      break;
    tmp = lookup[j % 32];
    lookup[j % 32] = lookup[shuf[j] & 0x1F];
    lookup[shuf[j] & 0x1F] = tmp;
  }
  for ( k = 0; k <= 31; ++k )
  {
    result = (unsigned __int8)tmp_arr[lookup[k]];
    inp[k] = result;
  }
  return result;
}
```

And my final solve code:
```python
#!/usr/bin/python3

tbl_shuff = b"I am tired of Earth, these people. I'm tired of being caught in the tangle of their lives."

lookup = [i for i in range(32)]
for i in range(len(tbl_shuff)):
    j = tbl_shuff[i] & 0x1f
    i &= 0x1f

    tmp = lookup[j]
    lookup[j] = lookup[i]
    lookup[i] = tmp

def shuf(inp):
    arr = list(inp)
    for i in range(len(inp)):
        inp[i] = arr[lookup[i]]

def unshuf(inp):
    arr = list(inp)
    for i in range(len(inp)):
        inp[lookup[i]] = arr[i]

def shift(inp):
    tmp = inp[0]
    for i in range(len(inp) - 1):
        inp[i] = (inp[i] >> 4 | inp[i+1] << 4) & 0xff
    inp[31] = (inp[31] >> 4 | tmp << 4) & 0xff

def unshift(inp):
    tmp = inp[31]
    for i in reversed(range(1, len(inp))):
        inp[i] = (inp[i-1] >> 4 | inp[i] << 4) & 0xff
    inp[0] = (tmp >> 4 | inp[0] << 4) & 0xff

def key_xor(inp):
    key = b'October 12th, 1985. Tonight, a comedian died in New York'
    for i in range(len(inp)):
        inp[i] ^= key[i]

code = [0xE8, 0xF4, 0xDA, 0xF1, 0x15, 0xC6, 0xB8, 0xBD, 0x77, 0x8C, 0xC1, 0xF9,
        0x74, 0x46, 0x78, 0xBA, 0xD1, 0x4E, 0xBC, 0x3A, 0xF3, 0x6D, 0xA9, 0x61,
        0x44, 0x61, 0x65, 0x13, 0x6D, 0x3D, 0xCE, 0x7B]

for i in range(16):
    unshuf(code)
    unshift(code)
    key_xor(code)

print(bytes(code))
```

Needless to say, this was quite a fun challenge to unravel, though I think spent
MOST of my time trying to find a way to dump the patches :( I need to go and do
more Windows reversing and learn more tools...


[1]: /2018/06/25/gctf/
[2]: http://dynamorio.org/
[3]: https://gist.github.com/theKidOfArcrania/02ee78f179a2a52869a92c1f14ae9836
[4]: https://gist.github.com/theKidOfArcrania/02ee78f179a2a52869a92c1f14ae9836#file-parse-py
[5]: https://gist.github.com/theKidOfArcrania/02ee78f179a2a52869a92c1f14ae9836#file-trace-asm

