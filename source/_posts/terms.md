---
title: Terminals are cool!
date: 2019-01-15 09:58:19
categories:
 - Blogs
tags: 
 - Linux
 - pty

---

Terminals are cool! There's no doubt about that... and even if you are not a
seasoned CTF player, if you have really played with any Linux distribution, you
would've known the ubiquity of the terminal. But I would like to say that even
behind a simple fascade of terminals, there's a lot more than meets the eye,
(even if you ignore the graphics rendering routines and that sort of stuff).

If you still don't believe me, I would like to invite you on a wild journey with
creating a tty from ground up.

## Motiviation
So with a particular CTF event, I was given a container service that had some
remote command execution (I can execute any commands that will then run as a
local user of that computer). The problem was, I could only send one command at
a time, and since each command would be a separate request, I couldn't do really
complex actions (i.e. editing a file) easily. 

Well I did built a sort of shell interpreter that will execute command per
request, but I also wanted to do something *more* ambitious: write a reverse
shell. Yes, I do know that there are plenty of [reverse shell codes][1], but I
felt that these were lacking in a way. I wanted a terminal that had the
following specs:
 * Doesn't terminate if I press `Ctrl+C` or `Ctrl+Z`.
 * Be able to use special keys (like arrow keys).
 * Act and feel like a real terminal (like those you get on a ssh session).

Now I know that I might possibly be asking too much, but I do know that one does
exist (like in ssh). So here we go... 

## Redirecting socket as stdin/stdout/stderr
So I will organize this essay as in incremental steps to getting a more
"terminal"-like experience

So the first step is to just simply open up a socket connection and then just
redirect the socket fd's to 0,1,2 (which are the standard input, output, and
error, respectively). This was probably the most basic step to getting reverse
shell. I will program this part in C since I don't think my target has python
installed. 

[1]: http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet

