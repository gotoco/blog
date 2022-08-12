---
layout: post
title:  "Short Story of Pages and Virtual Memory: Writing FS for Fun"
date:   2018-11-19 00:00:01 -0700
categories: Filesystem
category: presentation
---


### Followup Writing Linux Filesystem For Fun
After my presentation "Writing Filesystem for Fun" that I did during May C/Cpp meetup I recieved many questions and positive comments. Thus I wanted to do second part of this presentation where I explain topics related to virtual memory including short technical background of paging and swapping. 

<!-- more -->
### Dummy FS
DummyFS implements concepts of Page Cache which on Linux is very simple operation as it require using kernel framework by implementing particular Filesystem operations.

### Recording

Recording from my presentation is available on the youtube:
<iframe width="560" height="315" src="https://www.youtube.com/watch?v=AcghLh5c7ds" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
Also please take a look on other presentation from C/Cpp Dublin User Group meetups there is a lot of interesting stuff!

The slides can be found [here](https://res.cloudinary.com/gotocco/image/upload/v1542630927/WritingLinuxFS4Fun_p2_nyxrhx.pdf) and FS implementation on my [github](https://github.com/gotoco/dummyfs)
