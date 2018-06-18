---
title:  "Week 1"
date:   2018-05-27
categories:
 - Blogs
 - Taiwan Internship
tags: 
 - AFL Fuzzing
 - Language Issues
---

It's been a week on my internship. On the first day, I did mostly paperwork and
prep stuff. One of the things that was acute to me was the fact that everyone
spoke Chinese to me. Remarkably, I was able to somewhat communicate with
everyone all in Chinese (a pat on the back... yay... my Chinese surprisingly is
not too crap).

Since then I think I am able to continue increase my confidence in being able to
communicate. I think there are times when I can use English (actually my
coworkers encourage me that I can speak English, but even during those times, it
was pretty difficult because most others communicate to me and each other in
Chinese. It would seem incredibly awkward to be the only one who is speaking in
English. 

On the second day, I've attended one of their weekly meetings to present on what
they have done. This made me realize how much the supervisor was expecting, and
that he had a very clear vision of how one should present, and how stuff should
be done. Again here, Chinese was chiefly used. Here I was assigned to do
something related to AFL fuzzing (which I have not heard much about).

So the next few days, I went ahead to experiment a bit with the fuzzing tool; to
test this, I wrote a few programs that had a classic buffer overflow and one
with a heap exploit. I found out that the AFL fuzzer in fact took very little
time to realize that there was a bug. Something that makes this AFL fuzzer (a
gray-box tool) different from others was the fact that it used genetic
algorithms to try to find all the possible paths, (and possible edge cases) by
using random mutations (bit flips, dictionary attack, byte flips, splicing, and
other such mutations). It takes some valid input test cases as input, and then
mutate it, pruning out those test cases that do not cause a different path, and
then use the interesting mutations as seed for further test cases.

So on the third day, I found a fellow intern (who could not speak Chinese, so I
spoke in English :relief:) who is also working on AFL fuzzing; (she only came on
Wednesday, Thursday, and Friday afternoons because she has classes other times).
This was good for me because I will then be able to discuss some of our findings
with each other, so to figure out whether if we are going on the right track or
not. What strike me as intriguing was the fact that she was already a Ph.D
student; (meanwhile I am a mere 1st/2nd year). Hehehe, I realized basically
everyone here in this department are of a older age than me (though not that
much older, maybe only 10-15 years older).

On the fourth and fifth day, I basically continued doing the same thing as I
did, working with this fuzzer, trying to figure out what it does. Though, I am
not entirely sure if I like it or not because on one hand, it is similar to like
binary exploitation and reversing, but on the other hand, it's also very heavily
weighted in some *less interesting* (boring) stuff like the mathematical models
and all that nitty gritty stuff. Oh well, we'll see how this goes as I progress
with it. I also don't know what I would present on this (I have two weeks
probably to figure out something to present).

On a side note, I was able to connect with some of my other colleagues just by
showing my current side projects (my c compiler and my CTF problem, profile2,
which to this date, no one has solved it yet, even when one person decided to
try out angr with it, tehehehe!).

