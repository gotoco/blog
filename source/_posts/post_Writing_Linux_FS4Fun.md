title: Writing Linux Filesystem 4Fun
date: 2018-05-16 00:00:01
categories:
- Filesystems
tags:
- Tutorial
- Storage
- Kernel
clearReading: true
feature: http://res.cloudinary.com/gotocco/image/upload/v1531602755/pieces-of-the-puzzle-1925425_1920_po26f6.jpg
thumbnailImagePosition: right
autoThumbnailImage: yes
metaAlignment: center
coverCaption:
coverMeta: out
coverSize: partial
comments: false
---
### Writing Linux Filesystem 4Fun
In May I did a talk for C/Cpp Dublin meetup group, which took place in MongoDB office.
During the presentation, I went from a historical background to the real implementation of simple filesystem on the Linux.

<!-- more -->
### Dummy FS motivation
Filesystems were the part of the OS that I usually felt is lacking in my knowledge. After I changed my employer I started working with storage stack. This change result with the feeling that is a right time to change my state of knowledge.
As part of learning, I wrote a simple filesystem which I called "dummy filesystem". (The name dummyFS is because the implementation is trivial). I paid most attention to structures used to represent filesystem, disk layout and the way how OS (in this case Linux) interact with FS.

### Writing Linux FS4Fun

Recording can be found on the youtube [here](https://www.youtube.com/watch?v=sLR17lUjTpc), also please take a look on other presentation from C/Cpp Dublin User Group meetups there is a lot of interesting stuff.

The slides can be found [here](http://res.cloudinary.com/gotocco/image/upload/v1529615737/WritingFS4Fun_tnwis2.pdf) and last but not least FS implementation on my [github](https://github.com/gotoco/dummyfs)

### Futher live of dummy filesystem

I plan to release a few more releases of dummyFS, to go through more advanced topics from FS area:
- Provide real FS algorithms for managing block allocation, bitmaps and extensions
- Implement virtual memory capabilities
- Change FSlayout from an update in place to copy on write.

