---
layout: post
title:  "EuroBSDCon 2018"
date:   2018-09-29 00:00:01 -0700
category: presentation
---

This year I attended the EuroBSD conference in Bucharest as a presenter. During my talk, I summarized last year of research and development of Live-patching feature for the FreeBSD kernel. 

<!-- more -->
### EuroBSD
BSD is mostly considered by people in the industry as niche/hobbyist technologies, but once you will appear at any of the BSD events you can feel a lot of energy and enthusiasm. 
Starting from the welcome package: T-Shirt, Hardware PGP token with instruction, and two job ads one from Apple. Not bad as for hobbyist event right? 
The only minus that I can think of is lack of the recording from the presentations.

![Picture 1. FreeBSD Livepatching Logo](https://res.cloudinary.com/gotocco/image/upload/v1538323866/BSD_welcome_pack_ajhsmw.jpg)

### Community
One thing that I really like about BSD is the community. No doubt that is hard to find another open source project with such a welcoming and warm community.
Many events are attended by groups people from the same organizations or folks that already know core community from the mailing list. BSD is different, although there are many people that know each other for 20 years (or even longer), you still will find many friends to discuss interesting things or enjoy together the social event.

### Other interested presentation
Some interesting presentations that get my attention:

* Kernel Sanitazers by Kamil Rytarowski [presentation](http://netbsd.org/~kamil/eurobsdcon2018_ksanitizers.html)
* FreeBSD on PowerNV by Michal Stanek [presentation](https://2018.eurobsdcon.org/static/slides/FreeBSD%20on%20PowerNV%20-%20Michal%20Stanek.pdf) 
* The End of DNS as we know it by Carsten Strotmann [presentation](https://doh.defaultroutes.de/The-End-of-DNS-as-we-know.html)
* Using Boot Environments at Scale by Allan Jude
* FreeBSD/VPC: a new kernel subsystem for cloud workloads by Sean Chittenden [presentation](https://www.slideshare.net/SeanChittenden/freebsd-vpc-introduction)
Also really interesting presentation about the history and direction of the collaboration of the FreeBSD community: The Evolution of FreeBSD Governance by Marshall Kirk McKusick

![Picture 2. FreeBSD Livepatching Logo](https://res.cloudinary.com/gotocco/image/upload/c_scale,w_500/v1537364489/patching_furnace_djqlav.png)

### Keynotes from my presentation about livepatching:

 * Security and stability fixes are the most common reason of scheduling servers updates/downtime
 * Users can get benefit by patching the system without a downtime, downtime == cost
 * Live patching is a common technique used by other kernels, Linux Xen using it already, AIX also has it
 * FreeBSD kernel did not implement this feature so far but has everything that is required
 * Initial implementation based on common known practices, community feedback required, not fully functional yet.

#### Feedback after presentation
After the presentation I got a few conversations with folks from the BSD community:

 * Patch to the kernel as  LKM module is acceptable
 * For security reason need of signing the patches
 * Possible dual architecture with kernel daemon for doing live-patching
 * DTrace can bring more advantages than problems

### EuroBSDCon 2019
Next Year EuroBSD will take place in the Lillehammer, Norway on September 19-22. Definitely worth to mark it in your calendar!


### Additional resources:

EuroBSDcon Twitter: @EuroBSDcon
Presentation Slides from EuroBSDCon: [talks-speakers](https://2018.eurobsdcon.org/talks-speakers/)
Livepatching FreeBSD kernel: [presentation-slides](https://2018.eurobsdcon.org/static/slides/Livepatching%20FreeBSD%20kernel%20-%20Maciej%20Grochowski.pdf)



