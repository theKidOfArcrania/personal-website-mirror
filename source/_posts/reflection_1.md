---
title:  "Reflection I"
date:   2018-10-13
categories:
 - Blogs
 - Reflections
tags: 
 - Linux
 - Kernel
 - Grub
---

Wow. It's been a while since I said anything here. 

Probabably because right after the internship, I entered a rather busy semester
at college. Much busier than I have thought. Much busier than the first year. 

Well looking back, these past four months, even though I had been very busy, I
found that I had learned quite a bit of depth. **But I think what I say here, 
even though it seems like you are reading from someone who has a lot of
experience, I could not say that I am someone who learned this for a long
time.** It is humbling to remember that:
 * Four months ago, if you asked me about any of this below, I could not tell
   you a lot of detail...
 * An year ago, I would still label myself as a noob within the security field.
   I may have done a few CTF events, but I would say that I was pretty bad in
   the more difficult "college" or "adult" CTF competitions. I was also very
   naive in thinking how much I actually knew about any infosecurity stuff.
 * Two years ago, I actually knew nothing about infosecurity. I had absolutely
   NO knowledge about anything, nor have I played any CTF's at all. At that
   point I didn't even know I liked to do cyber security. 

Bottomline, I think it is never too late to start learning. I think how much you
put in even over a short time, that is what you will get out. 

## Under the hood

So this summer I have been able to do and learn a lot, I think really one I was
really proud of learning is exploiting Linux kernel code. It is really a wonder
to see how bugs scale up into the kernel. I think one of the cool stuff you get
to play with that isn't as practical in regular user programs are race
conditions:

> Each time you make a request to access system resources (system call), you get
an opportunity to run the one single copy of the kernel in parallel. This type
of concurrency is not a commonplace thing in userspace programs because often
times there is only one user that interacts with the program, and any internal
states managed by the program do not need to be synchronized or restricted since
it only needs to be accessed by one running instance at a time. However, in a
kernel, there are multiple concurrently running userspace programs that can
access the same kernel, which if unchecked, can result in two programs
concurrently modifying a single state, possibly making it undefined.

Wow! The kernel level has opened up a whole new vector of vulnerabilities that I
have not thought of beforehand. I think to show this, sometime later I will
actually walk through an example of this bug because I feel information like
this cannot simply be understand by words alone, but by trial and error, as well
as thinking through the problem.

## Diving Deeper...

Another thing I have done was actually go even *deeper* than the kernel. Deeper
you say? It began with a story a month or two later:

> One day I was walking, lugging my laptop around in my backpack, and by now I
had a terrible habit of simply closing the lid (not turning off the laptop).
That day I found my laptop would not turn on. Astonished, I thought perhaps my
battery ran out, so I tried charging it. Huh... weird, it still doesn't turn on,
maybe it's because the outlet is bad. I know there were a few of the university
outlets that actually do not work. But even after trying multiple outlets and
different chargers I realized my computer motherboard burned out. 

At that point I realized I just had a hard drive with virtually everything I've
done for the past year, (which believe me is a lot!), but no bootloader (I
realized I put my grub bootloader on my attached SSD, along with my Windows
partition). So at first I thought, wait a minute, I could plug the drive into my
desktop (which has Linux), and just mount the hard drive. Then I can chroot into
it and actually use it as a virutal container. Well it almost worked; somehow
anything that required networks doesn't seem to work. At one point I even found
myself with just a computer with a worthless Windows 10 that takes eons to boot
up. *But I just want a way to boot up from my harddrive, which I have in my hand
as well...* 

### The magic of booting up?
At one point I stumbled upon an idea. Perhaps, maybe I can figure out how to
boot a system from a grub command prompt. You know, that thing that you get when
somehow your boot partition gets sort of screwed up and grub can't boot up your
Ubuntu partition. Anyone? Okay nevermind... So I had tried creating a Linux
kernel image plus initrd image from scratch for something else... so this
shouldn't be too difficult, right? So after suffering for a bit, I stumbled upon
yet another thing.  Some thing called an *MBR* (Master boot record). So
apparently, I can say take a USB stick, and then install just the grub
bootloader onto the MBR (and some other places if needed) of the USB. Then when
I boot up the computer from that USB stick, the computer will execute the grub
bootloader, and grub will first read from the `/boot/grub/grub.cfg` file
determining which partitions are bootable, which I found out was automatically
generated each time you updated the kernel on Ubuntu (which explains the
messages where they say found some xxx kernel version that you *forgot* to
remove), and then it shows you a menu of that. 

If it fails somehow, it will revert to a shell, or you can ask it to go into
shell mode. This allows you to specify bootloader commands (i.e. loading certain
partitions, loading the kernel/initrd image, etc...). After messing around with
this a lot, I found that (after fixing some missing partition issues) I can
*finally!* boot from my hard drive onto some rando computer (even if that did
not have Linux installed!). Eventually my laptop was fixed, but I have learned
how the bootloader loads itself into memory.

## Even deeper...?

Now let's go *even even* deeper into the system. What would an MBR look like?
Originally, I thought at the MBR, you basically have no support for any
hardware/devices. I thought the MBR was the beginning of any code...

> In the beginning there was nothing...

Well not quite yet. I realized that even at the MBR, there is still support for
a lot of basic I/O stuff, (hence BIOS :), more than I intially thought. There
are actually some interrupt stuff that is already initialized that is done with
the BIOS firmware stuff. Well at this level, it is basically just 16-bit x86
code, but it is far from nothing. I have then recently looked at a last year's
CSAW bootloader problem, that I thought I could've never been able to
understand. It is definitely different, but not totally unintellectable. 

I think I will want to write out a future post about going through one of these
MBR type problems. I think they deserve some mention for it. 

## In summary
Yeah I think a lot of this seems very scary, but if you read down to here, I
like to congratulate you! Yeah at first I think a lot of this under the hood
processes seem quite daunting, but I think if you take these parts bit by bit, I
think you will find it not too difficult after all. It has been a fun journey to
learn through all of this, through various coincidences, and competitions (and
also I recently done a lot of pwnable.kr challenges in this past four months. I
think one thing I really liked about them was the fact that they have so many
cool kernel challenges to tackle. Definitely, a good way to learn about the
kernel and about exploiting is through pwnable.kr)! 

