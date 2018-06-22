---
title:  "Week 3 and 4"
date:   2018-06-17
categories:
 - Blogs
 - Taiwan Internship
tags: 
 - AFL Fuzzing
 - Presentations
 - Inspirational
---

I have not wrote a post for a week now. Hmm... well I guess I will just update
what happens now. So just last week (on Tuesday) I made my first actual
presentation in front of the manager. 

## Preparing the Presentation
For me I was actually quite nervous of how I would do, especially since a lot of
people in the previous round of presentations did pretty awful. I have to
remember that this manager is a very demanding person, and he does not give a
lot of leeway if you do not present well. Another problem I found that the week
before, I did very little work, so I was also a bit nervous that I did not
prepare enough. 

Now, mind you, I did in fact finish what I was assigned to do, read the source
code of AFL, and figure out what it did in and out, something that I was shocked
as to that the other intern was unable to get. Here is my [report][1] for that. 

## Learning from the Internals...
However, despite the result of the presentation, I think something more
important from this is what I have learned as a result. Hence, I will take this
time to tell what I learned about AFL fuzzer after reading the source code.
After going pass the smokes and mirrors of the high level implementation of AFL,
I realized how simple AFL actually is.  Essentially AFL tries out a lot of small
deterministic mutations (bit flips, byte flips, arithmetic operations,
dictionary splices) permuating over each possible position in a seed input. Most
of the time, a program's branch condition only utilizes a small portion of a
seed input. In this common case, AFL will be able to perform a "smart"
bruteforce method that simply tries to increase the coverage of the binary
without deep underlying symbolic knowledge of the program. 

Once it performs a round of deterministic mutations, it will then switch to
undeterministic mutations. How much should AFL try to mutate undeterministically
before calling it quits, (since undeterministic mutations can, in theory, can
cover a much larger input space than the deterministic mutation stage can. This
input space is probably way too large to try all of them, so AFL can only test a
small subset of this input space). So AFL actually uses some factors that help
give more weight to certain test cases. I go into more detail in the
[report][2]. 

Lastly, AFL also has something called an "interesting input case" where a
mutated input data would be "interesting" enough to add as a new seed input.
This way, AFL will "remember" what paths it has already seen work and will build
new input data that builds on top of these new seed inputs and advance deeper
into the program. This is the genetic algorithm part of the program.

## Elegant and Efficient
The most elegant thing I like about this AFL algorithm is that AFL does not in
no way try to be accurate and precise. Instead it just approximates "interesting
cases", i.e. cases with unique execution paths. This is both beneficial in only
marking very differing input cases as "interesting" and also making a very time
and memory efficient way of indicating this execution path. I think (tangent
alert!) completely focusing on exact algorithms when preparing for coding
competitions in high school, I completely forget another class of heuristics
algorithms that don't compute the **optimal** solution, but a **close enough**
solution. I think Dijkstra's algorithm is pretty cool in path finding, but when
you try to apply this to the real world in GPS path finding, you realize your
*exact* algorithm is just <u>too slow</u> to work. So in the world where **close
enough** is good enough, this gives rise to these heuristics algorithm that
trade-off some faster time/memory efficient algorithm for some minor
inaccuracies. Maybe there is a faster route that is 50 meters shorter, but when
you are driving a car around, WHO CARES?

AFL is a pretty cool software, something that would've never come up my radar
had I had to prepare a report over it. However, I am glad that I looked at this
software. I even started to use this to check some bugs in my program (just slap
a few asserts into your program, and run AFL on it!). It reminds of this
Liveoverflow's [video][3] that I just rewatched. (I very much <3 watching
Liveoverflow's videos because they are both educational and fun to learn). 

## The Value in Little Chunks
Honestly, it felt like currently I was given too little work; however, I am
still able to take away some really valuable information that I would not have
touched otherwise. I told some of my friends that I haven't really done much so
far during my summer internship (just did some research, read some source code,
etc...), but I failed to really touch on the valuable information that I was
able garner from this research. Now that I was able to gain this information, it
becomes my own, and I can now integrate it into another tool inside my toolkit
of knowledge.

Turns out, that presentation I made on Tuesday turned out to be much better than
I had expected. I think I should've given more confidence than what I gave
myself :/

[1]: https://gist.github.com/theKidOfArcrania/b911fa586ef9b6ddcd1303c169cb5269
[2]: https://gist.github.com/theKidOfArcrania/b911fa586ef9b6ddcd1303c169cb5269#performance-score
[3]: https://www.youtube.com/watch?v=2TofunAI6fU
