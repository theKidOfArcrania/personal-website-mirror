---
title:  "Week 6 and 7"
date:   2018-07-06
categories:
 - Blogs
 - Taiwan Internship
tags: 
 - AFL Fuzz
---

Wow! It's already been seven weeks being here in Taiwan, (I did a bit of 
calculations because I could not believe it at first). Seriously, time does fly
when you aren't paying attention. Also, I think by now, this trip marks the
longest I have been to Taiwan, (in fact, perhaps longest time away from home,
period!)

## AFL Fuzz

Last week I wasn't able to write an entry because I turned out to be quite busy.
Last Tuesday, I was assigned a task to actually implement some code to add a
frontier heuristic into AFL. Initially I thought that this only required some
minor changes, and can be extrapolated from existing data, something to the tune
of finding the delta change in the bitmap size per input. Here is my current
[report][1].

### From a small fix to a major rework...

After some critical thinking, I realized that it completely failed to even
remotely describe frontiers. At its core, new paths that have been discovered in
input A would not be marked as "frontier" in input B. This meant that possibly
we might *undercount* the number of frontiers that actually exist. Then on the
other hand, if we keep fuzzing input A after finding some more frontiers, we
also might *overcount* the number of frontiers because frontiers no longer are
frontiers when they are visited (and when its surrounding branches are visited). 

What I ended up doing was I had to add more instrumentation information and
respective analysis code to detect frontiers. See the big problem lies in the
fact that the instrumentation assembly code is **heavily** optimized. Optimized
to the point that it is very difficult to add anymore code; this was especially
true as I tried to figure out how to make complex arithmetic with use of only
one/two registers! It was pretty *painful*, and at the end, I ended up having to
squeeze two entire values within some registers! 

Though, I was actually quite surprised that overall, the debugging aspect for
the assembly instrumentation code was brought to a minimal. 

After some of the low-level work already underway, I shifted my focus to the
fuzzing code. The code overall was pretty dense, and although most of the code
was documented relatively well, there were still a few undocumented aspects that
I had to pore over the code to figure out what it is doing. 

One of the products that I am very proud of is the statistics window. There is a
sort of amusement when you can see panels and panels of numbers flip around, but
it is even more amusing when you know what those numbers mean. For me, it meant
that the frontier code I wrote was doing well.

Well, actually, I had to spend quite a while (two-ish days) trying to debug my
statistics window, wondering why those stats are so off. At the end I also had
to resort to writing to debug file, while building and running the program each
time to test it out (building took *soooooo sllloooooowww!*). Well, turns out,
most of these errors are a result of noobie coding errors. 

![My noobie coding errors, or why parenthesis are so important (correct is on
top)][2]

## Leaving...

Sniffle... Well I just realized I will be leaving in about 2 weeks. (Correction:
I will be leaving work in 2 weeks). It seems like this week will be my last
report for this project. It was a fun journey working with AFL fuzzing. I
realized I will probably leave with this project wholy unfinished. If you also
observe in the report, I have quite a few things that I'd like to get to. Most
importantly, I wanted to use Dynamic Taint Analysis (DTA) and the frontier
heuristics to try to really direct AFL to fuzzing these hot bytes. 

The one thing that I hope as I leave this is that I would like somebody to be
able to to continue onward with this project. However, currently, the other 
intern who is also directly involved with AFL fuzzing does not seem to be
competent enough to be able to really continue this project, not without a lot
of more research and learning. Maybe someone else might come to continue this
project, but as it stands now, the prospects for this project does not look too
good. Oh well. This was both fun and educational internship thus far!

[1]: https://gist.github.com/theKidOfArcrania/cfbbb75bdbd1d2059eea9ba4cc517964
[2]: /files/noobie_coding.png

