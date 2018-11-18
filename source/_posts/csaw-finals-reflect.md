---
title: "CSAW Finals Reflection"
date: 2018-11-12 10:20:58
categories:
 - Blogs
 - Reflections
tags:
 - csaw
---

Hey everyone! I just came back from a long 36-hour CSAW ctf finals competition,
competing as dcua. 

First of all I would like to explain why this competition is quite a special and
unique experience. First of all, this is an on-site competition, as compared to
most other online CTFs. Furthermore, this competition is only open to the top 10
teams (of four players) in the entire country; so basically, I am competiting
with people who are probably the best people in university. I cannot understate
how privileged I was to be able to even compete in this prestigious competition.

I feel privileged that I can compete among good teams such as perfect blue and
PPP. I was also able to meet cool people like Rusty Wagner (who designed the Pwn
adventure 3: Pwnie Island game) during this competition, and be able to play his
newest released game that made a great addition to the pwn adventure series.

Okay, okay, enough of inner little child me exclaiming about meeting famous
people... I will also release write-ups for our dcua team in a few days later,
stay tuned! 

Anyways, this competition itself was a very fun and unique experience, although
I was a bit disappointed that there wasn't any cool kernel or KVM related
problems (maybe next time). At one point we were in 2nd place (which was pretty
cool), but in the end we ended up as 6th place. If we competed in any other
region, we would've gotten first easily.

![We were second place during the game!][2]

## Pwn Adventure: Sourcery
Anyways, as I hinted before, Vector35 (the company that also released both
binary ninja and the pwn adventure series) wrote a pretty awesome game called
[Pwn Adventure: Sourcery][1]. This game was actually quite unlike other previous
games that they released. First of all, this was written in Rust, and compiled
to Web Assembly (yuck!). I tried to disassemble the web assembly game, but
ultimately failed because I don't know enough web assembly, and the game was too
big to reverse. What was cool was that I think the game also implements a
minimal kernel written in the javascript code to service the web assembly (which
was cool). However, in the end, no actual reverse engineering of the web
assembly was super necessary. In addition, after asking a team, we found that
the flags that were needed for all the problems were actually server-side
verified, so hacking the game will not let you get flags (though it may have
made the game easier to play).

## Other Remarks
This was quite a fun experience, and I think in total I slepted about 12 hrs out
of the 36 hrs competition (probably a little too much?), and I was quite tilted
by multiple pwn adventure problems, sighs... I should've paid closer attention
to the details!

Also before finishing out this post, I would like to pose a small thought
experiment:

> Consider this, a team who was 8th place at day-1, 5th place on day-2, 3rd place
before the end, instantly won the competition. Either they got their skill-set
out at the very last moment... or is this just another fairy tale to cover up
something else more sinister hmm...? Of course there shouldn't possibly be the
slight concept that somebody is *cheating*, but you never know...

I will post all my writeups in a future post.

[1]: https://sourcery.pwnadventure.com/
[2]: /files/csaw/second_place.jpg

