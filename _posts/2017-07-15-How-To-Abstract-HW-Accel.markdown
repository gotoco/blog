---
layout: post
title:  "How to Abstract Hardware Accelerator"
date:   2017-07-15 10:15:23 -0700
categories: Xen Conference
---

### How to abstract hardware acceleration device in cloud environment
During this year Xen Developer Summit, I gave a presentation about abstracting hardware acceleration device. The presentation went from topics related to accelerators in general to specific areas important for virtualization and cloud.

<!-- more -->
### Xen Summit 2017
This year during Xen Summit there was a bunch of different topics, still the main purpose of using Xen is server virtualization for Data Centers which is mainly x86 based, but there is visible trend from embedded devices driven by ARM when people are using Xen because they wanted to get isolation that hypervisor type 1 can provide. 

### Abstracting Hardware Accelerator
From my perspective (as a performance and system guy), Xen is also not only hypervisor but a platform itself. As Cloud transformation is still moving forward people are changing their mindset and instead of thinking about buying better hardware like CPUs, NICs, SSD they think about buying more capacity or better features from their cloud provider.
I don't really like that transformation because I grow up in times when every physical server has its own name and whims, but from the other site, there is no doubt why having number of lightweight anonymous instances can provide flexibility, savings and even much more goodness to your organization. Because of that, I think about cloud in terms of next generation platform that need to be understood and support.
Because the last couple of years I spent solving different issues and developing solutions for Cloud, I was more than happy when I got the opportunity to work with Intel QuickAssist Technology and work on virtualization and cloud enablement for this product. In my presentation, I summarized last year progress that we have done to enable QAT to work in Virtualized environment.

Presentation can be found on [Xen Summit web site](https://schd.ws/hosted_files/xendeveloperanddesignsummit2017/6d/XenDevSummit17_AHDIC_mgrochowski.pdf) or at followed [link](http://res.cloudinary.com/gotocco/image/upload/v1500758597/XenDevSummit17_AHDIC_mgrochowski_cloiqc.pdf).

### Key Notes from Presentation.

1. There is a visible trend of platform awareness: best summary can be viewed on this year AWS Summit where Werner Vogels presented a set of currently available [AWS Instance flavors](https://www.youtube.com/watch?v=RpPf38L0HHU&t=24m30s). Customers want to be able to buy/rent custom hardware types like SSD drives or NICs or even FPGA to get performance acceleration.
2. Hardware Accelerators need to come with the more generic solution for QoS because throughput can really vary depends on hardware design, algorithm, and other parameters.
