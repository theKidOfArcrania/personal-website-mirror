---
title: Setting up this blog!
date: 2018-06-15 14:02:27 +0800
categories: Blogs
tags: hexo
---

From the last few months, I have decided to write some blog posts (using
markdown) so to document some of the stuff that I've been working on. Previously
I have placed it in this [github repository][1], hoping that one day I would be
able to transfer those blog posts into a permenant website. 

I have been pretty lazy to try to set up a web, writing the HTML pages and the
theme that comes with it, especially since I haven't really worked a lot with
aesthetics of a website. And besides, it is the 21st century, who codes in raw
HTML anymore? So I decided that probably I would write in markdown, and find
some way to use static webpage generators to do the HTML work for me. 

Initially, I was considering using Github pages with Jekyll, but it seems pretty
riddled with a lot of issues installing and stuff. Also, I wasn't able to find a
decent theme with Github pages.

Furthermore, with the recent Microsoft acquisition of Github, I decided to host
this website on Gitlab (since I haven't really done anything on Github yet.)
Then I found this cool alternative static webpage generator called [hexo][2] (or
initially, I found a cool theme based on top of hexo called [hueman][3] which
this website is based off of). So far, I think it is pretty neat theme, and
relatively easy to use.

There were a few issues I had with this initially, maybe if someone saw this and
needed to figure out how to set this up, this might help:

* **Hexo installation issues**: This is more of my own issue, particularly with
  Node.js and how it is packaged in Ubuntu. Apparently, Ubuntu *only*
  distributes Node.js at the version `v4.2.6`. Sighs... why? The latest stable
  version of Node.js is `v10.4.1`!! Okay, well anyways, the installer for hexo
  complained about some weird errors because Node.js is out of date. Okay, then,
  how do I install the latest version of Node.js? I could go to their website,
  but it's such a hassle going there and then downloading it and then building
  from source/ running an installer. In the end I used this [answer][5] (install
  a helper package called `n` that installs a version of Node.js) to solve my
  issues.

* **Language issues**: Hueman had quite a few different languages to use for
  internationalization. However, by default, when using `hexo init` to
  initialize the website, it did not set the language by default. Furthermore,
  hueman didn't seem to have a "default" language to choose from. So hexo
  decided to choose the first language in alphabetical order: Catalonia. That
  really bothered me when I can't read any words on the blog when testing it. :(

* **Config.yml**: Apparently, I did not read the [installation instructions][4]
  all the way for installing the hueman theme. So I cloned the theme, then
  directly went to run hexo. When I tried to load a page, hexo kept on spitting
  out some errors (because certain configurations were undefined). Within the
  hueman repository, I found a config file with the name `_config.yml.example`,
  and found that they defined some of the configurations needed by Hueman. So I
  copied that file and overriden my root `_config.yml` file (I made a backup of
  the old one just in case). Apparently, I overlooked this step:

    > 3. Rename `_config.yml.example` in the theme folder to `_config.yml`.

  In the end, I just copied the contents of `_config.yml.example` into my
  `_config.yml` file.

* **categories vs tags**: When writing blog posts, you have a place on top of
  each post to place some metadata (date, title, etc...). Apparently with hexo,
  they support both the `categories` and `tags` fields. What's the difference?
  Well, the biggest difference is how hexo interprets these: categories are like
  "directories" you can organize your posts in. You can use multiple categories
  to represent subdirectoriess within a directory. On the other hand tags are
  like "keywords" that you annotate within each post. It does not have a
  hierarchy structure like categories. Most of my posts will be under the
  "Blogs" category, but I might add multiple tags to help specify what my blog
  post is about.

Okay well that's my journey to setting up a website. Hopefully, now that it's
set up, I'll be able to more easily maintain it, (it has been one of those
things I wanted to get set for so long, but never found the time to do it...)

[1]: https://github.com/theKidOfArcrania/blogs
[2]: http://hexo.io
[3]: https://github.com/ppoffice/hexo-theme-hueman.git 
[4]: https://github.com/ppoffice/hexo-theme-hueman/wiki/Installation
[5]: https://askubuntu.com/a/663052/831088
