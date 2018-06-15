---
title:  "How to run an 'undetectable' program"
date:   2018-04-13 03:35:36 -0500
categories:
 - Blogs
tags: 
 - Linux
---

## Daemons and Processes
What is a daemon? It is a running background process used in Unix to run
services. These typically are not attached to a terminal, and will keep running
even when users are logged off. 

A friend asked me whether if it could be possible to run a background daemon 
undetected. Now this idea intrigued me. Well, it depends on what you mean by
"undetected". Typically, a list of all currently running processes can easily be
extracted, either by using the `/proc` sub directory, or by using a program like
`htop` or `ps`. Now, if you were to run a daemon on for a long time, you could 
easily detect such program, for example, run `htop` then filter (F6) by time. 
The issue is any long-term daemons will just show up at the very top. Worse, the
large times will actually be highlighted in **RED** text! So much for undetected
program. Another limitation is with `ulimit`. Typically, sysadmins could set the
maximum CPU time of any running program to an upper bound so that you don't
waste away all their precious CPU clock cycles, especially when others are also
using the same server.

## Forking
Now there is a pretty ingenous solution to these limitations, plus more. Enter
`fork`. Fork is typically implemented as a syscall (well technically, modern
Linux systems use another syscall called `clone`, but still retains `fork` as 
a glib library function). According to the manpage, `fork()` creates a new
process by duplicating the calling process. This is all fine and dandy, but what
use is this syscall? Well, we can use fork to trick the system into thinking
that we are multiple processes. 

The idea of fork is that when you call fork, the kernel creates a copy of your
currently running program, with all it's memory, file descriptors, signal
handlers! This means that you have now two copies of the program, the "parent"
process, which was running before you called `fork()`, and the "child" process,
which is the newly created process. The only difference between the child and
parent process is simply this: in the child process, `fork()` returns 0, but in
the parent process `fork()` returns the PID of the child process.

Actually I lied, when `fork()` is called, there are some stuff that the child
does not inherit. For one, it's process resource utilizations get reset to zero
(interesting), second, it has a different pid than of its parent (obviously).
This comes in handy later on. So when we called `fork()` we simply have a clean
slate program when it comes to resources. We can simply go into a infinite loop,
do some work, then fork, kill the parent process, letting the child live, then
continuing this cycle (a sly-fork program). This is "undetected" on two-folds: 
(a) any resource times that count how much resource this process is using is 
repeatedly resetted to zero, which means the sysadmin will have no clue that 
this process has actually been running for a long time, hogging a lot of 
precious CPU time, and (b) if you fork frequently enough, such "sly-fork 
processes" actually will not show up on htop, (and even if it does, it will 
only do so for a few frames or so, and then spurriously disappear.) 

Here is a brief source code that prints the approximate number of seconds it was
alive in total, by using `sleep` and `fork`:

```c
int main() {
  long i = 0;
  while (1) {
    // Wait for one second
    sleep(1);

    // Call fork()
    pid_t ret = fork();
    if (ret == -1) {
      //An error occured
      printf("Error!\n");
      exit(1);
    } else if (ret == 0) {
      // Child process: continues to live for one more cycle.
      printf("I am live for %d seconds.\n", i++);
    } else {
      // Parent exits out of program, child becomes new parent process.
      exit(0);
    }
  }
}
```

## The Dangers (and maybe some ways to curb such a program)
This is actually quite dangerous, because now, you virutally have no way of
reliably detecting such a program (if it was written correctly). This process
could continue to run in the background, harvesting off of some CPU cycles and
run all sorts of menace calculations. This also could have potential for scaling
(the user could then run multiple instances of such slyfork programs easily.)
Then it comes to killing the program, (if you even know what the program was 
named). The problem is you cannot use the `kill` command because the pid of the 
program will keep on changing, so you are stuck using `pkill` and specifying a 
program name. `pkill` is a little heavy-handed, because it kills all programs 
with that particular name by default, (maybe there is an option to only kill 
one such program?). However, the user could get away with pkill by being more 
creative with their process name: either they can use some unsafe characters 
(like the `-` (dash) character in the beginning), or they could create a long 
program name similar to like a password, to prevent the user from bruteforcing 
the name. 

Of course, the sysadmin could also just restart the server and be done with it.
However, it can also be very difficult to detect such program, when they flash
in and out of different programs. A possible way to effectively detect such
program, could be to write a c program that detects programs that have very
short life times, and then report these such programs. If they reoccur with such
a large frequency, it should alert the admin to as a possible "sly-fork
programs". The easiest way to catch such a program is if such short-lived
programs have the same name attached to it. (However, this can be avoided, by
calling exec right after a fork, and calling a new program that also continues
on with the "sly-fork" program). Therefore, it is still advisable to just
print out all such short-lived programs; there might be some flukes and noise
within the output, but I think it should be good enough detect such rogue
processes. If on the other hand these show up for more than a few seconds, it
should more easily be caught by sysadmins and flagged if they keep cropping up
in the list of processes.
