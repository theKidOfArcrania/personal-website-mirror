---
title: "CSAW finals Reflection"
date: 2018-11-12 10:20:58
categories:
 - Blogs
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

## A broken system...?
*NOTE: Here's where I get a little ranty... feel free to ignore the rest of this
post...*

Okay so this maybe a very unpopular and probably a lot of people who read this
might get mad at me for doing so. And if you are from top two teams of CSAW
(i.e. PPP, RPISEC), although this maybe very pointed at your teams, I am not
trying to point the blame squarely on you, but I am more-so trying to voice my
thoughts about this broken system. 

For me I think in general a huge obstacle in terms of really ranking high in CTF
events is the fact that I am usually just competing by myself and I don't have
the luxary have having a large team of people (like at PPP) back me up. I hail
from a university (University of Texas at Dallas) that frankly isn't typically
skilled in CTF events. I don't know practically anyone whom I could work with in
terms of reversing and binary exploitation on even terms. This automatically
stunts my ability to be able to rank high on CTF's. Especially when involving
myself with large binaries, at the end of the day, it does require just raw
man-hours, nothing much more than that. 

But coming into this competition, my expectations were that each individual team
would be capped at four people since that is what the "rules" dictate, which
meant that my former disadvantage would be almost completely compensated. I
thought that this competition was one I can actually get an even ground when I
compete with other massively strong teams like PPP. To be honest, I did not
even think of the possiblity that there would be some cheating going on, until
one of my fellow teammates told me so. 

I have been pretty disappointed about how the legitamacy of the placement of
some of these teams. One of them is too closely related to the organizers
themselves and could easily obtain flags from organizers themselves. They tried
to cover it up, but it is still pretty obvious. One of the teams has basically
an entire huge offsite group that can also help them solve problems. I can't
believe that I am getting too much involved into the politics of these things.
But the nasty truth is that there are these huge establishments and schools that
want to continue winning (and getting even higher rankings on CTFtime). 

Why does this sound so much like politics in real life.. arrrghh??!!??!!
Anyways, I think this issue of integrity is also not a first/second place issue.
Of course it is one thing that this is just a hacking contest, but it is yet an
entire other thing to be a "hacking the contest", that is bending the rules and
exploiting features that allow you to bypass the original intent of the rules.
Isn't that what hacking is all about? Well that is kinda true, but that also
defeats the purpose and the fun of the competition. I think knowing that all
this integrity issues is occurring underneath kinda makes the game not as fun
and frustrates me because that means that we aren't competing against pure
skills and knowledge but who can exploit the rules and get the most people
working on your side. I admit even our team used some offline help from others,
but I think our collaboration is only due to a reaction to the fact that others
are also cheating terribly. To be honest, I think the team Perfect Blue
should've won first. They actually do have very skilled people onsite who knows
what they are doing. 

I feel that this entire system is so critically flawed. The incentives for
cheating is just too much, and too much is at stake.  Anyways, I don't know who
will actually see this, (probably no one)... Oh well I guess I will just retire
to an identity in an obscure university, as an obscure person. The politics of
all this is just way too hot right now. 

I will post all my writeups in a future post.

[1]: https://sourcery.pwnadventure.com/
[2]: /files/csaw/second_place

