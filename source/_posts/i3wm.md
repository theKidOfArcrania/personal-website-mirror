---
layout: post
title:  "i3 Windows Manager"
date:   2018-05-17 05:10:26 -0500
categories:
 - Blogs
tags: 
 - Linux
 - i3 
---

[i3][1] is a pretty windows manager. I think it's a pretty cool add-on
considering how frequent I like to use terminal (and would like to streamline my
terminal usages to other GUI stuff like web-browsing). I especially love their
tab layout (`$mod+w`) and horizontal/vertical split function (`$mod+h` and
`$mod+v` respectively). 

Before I used i3, I would use a multiplexer called tmux to open multiple tabs
when I am working on different parts of code (or working with different 
programs). This would be useful if I were just needing to work with terminal and
tui stuff. However, this would not work (at least I don't think) with graphical
interfaces. Then a friend recommended me to switch to i3 from the default Unity
desktop manager, and I definitely appreciated that change.

Especially since I mainly work on a laptop now, which means you have to use a
awkward trackpad, or plug in an additional mouse (sometimes I am too lazy to do
that) to direct the cursor, being able to use a keyboard to do everything makes
life SO MUCH BETTER <3. 

There are some scripts/configurations that I had to write to help make my life 
easier though... I will add them on as I remember:

* To execute some bash scripts/ applications on startup, I had to go to the 
  `~/.config/i3/config` and add an `exec --no-start-id <command>` line to it. 
* I used to have redshift in the background whenever I logged in, (it makes my
  screen so much easier on the eyes, especially when staring at a white
  browser). Apparently sometimes just calling redshift makes it stuck on the
  `geoclue` stage, so I ended up writing a [script][2] that ran the `where-am-i`
  demo provided by geoclue to get coordinates and somehow that works.
* I also realized that i3 did not have a battery low notifications (sometimes I
  don't notice the battery life, especially with its small font in the lower
  right corner, so I searched up on Google and they suggestd to write a script 
  using output from `acpi -b`. (I also had to install that first using
  `apt-get`). Here is that [script][3] that hopefully notifies me whenever my
  battery is low. TODO: I need to add some sounds to that so that I will hear
  that as well.  
* I also had to change the `$mod` key to the Win key (`Mod4`) because Intellij
  likes to put the `Alt` key in a lot of their shortcuts, (including the
  almighty, all-purpose `Alt-Enter` shortcut key).


[1]: https://i3wm.org/
[2]: /files/start-redshift
[3]: /files/check_batt.sh
