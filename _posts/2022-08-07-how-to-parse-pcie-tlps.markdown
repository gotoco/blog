---
layout: post
title:  "How to parse PCIe TLPs"
date:   2022-08-07 19:19:57 -0700
categories: Device Drivers
---

## Introduction
Most of today's peripheral's that can be found in computer or server are PCIe devices.
PCI Express became standard for device manufacturers, and although it broad usage because of it's internals it is still very complicated protocol to understand when things goes wrong.

Usually when device causing problems it can dissapear from the system or misfunction and sent a lot of odd errors to kernel logs. Most common errors would be reported via AER's.
In this post we won't go into the protocol but we will focus on how to make sense of error messages.

## PCI Express Advanced Error Reporting
PCI Express Advanced Error Reporting (AER) is 


## Using TLP-Tool to parse TLPs

### Setting up tlp tool and other tools.
For examples showed below we will need `lspci` utility which can be installed as part of packet `pciutils`. To install `pciutils` on Linux we need to run packet manager such: `apt` for Ubuntu, `yum` for CentOs or `dnf` for Fedora and request the packet.



## Where TLP Header can be found?
In this tutorial we will focus on two most common places where PCIe error can be posted: system log and device logs.

### Kernel logs
First place which we should check in case of any issues with devices are kernel logs.
Logs can be accessed by `dmesg` command 


### Header Log
In this example we will have NVMe device with BFD number 01:00.0. 
We can 

```
lspci -s 01:00.0 -vv
01:00.0 Non-Volatile memory controller: Phison Electronics Corporation E16 PCIe4 NVMe Controller (rev 01) (prog-if 02 [NVM Express])
...
        Capabilities: [1e0 v1] Data Link Feature <?>
        Capabilities: [200 v2] Advanced Error Reporting
                UESta:  DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
                UEMsk:  DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
                UESvrt: DLP+ SDES- TLP- FCP+ CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP+ ECRC- UnsupReq- ACSViol-
                CESta:  RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr-
                CEMsk:  RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr+
                AERCap: First Error Pointer: 00, ECRCGenCap- ECRCGenEn- ECRCChkCap+ ECRCChkEn-
                        MultHdrRecCap- MultHdrRecEn- TLPPfxPres- HdrLogCap-
                HeaderLog: 04000001 0000220f 01070000 9eece789
```

### AER Report

You’ll find this post in your `_posts` directory. Go ahead and edit it and re-build the site to see your changes. You can rebuild the site in many different ways, but the most common way is to run `jekyll serve`, which launches a web server and auto-regenerates your site when a file is updated.

To add new posts, simply add a file in the `_posts` directory that follows the convention `YYYY-MM-DD-name-of-post.ext` and includes the necessary front matter. Take a look at the source for this post to get an idea about how it works.

Jekyll also offers powerful support for code snippets:

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}

Check out the [Jekyll docs][jekyll-docs] for more info on how to get the most out of Jekyll. File all bugs/feature requests at [Jekyll’s GitHub repo][jekyll-gh]. If you have questions, you can ask them on [Jekyll Talk][jekyll-talk].

[jekyll-docs]: https://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
