---
layout: post
title:  "The Xen way"
date:   2016-08-11 20:29:12 -0700
categories: Xen Virtualization
category: tutorial
---

### What is Xen?
In terms of open source hypervisor main players are: KVM and Xen, these projects can be used on a personal laptop as well as in commercial. There are also: Virtual Box which is good if you are using Windows and bhyve for these that are die hard BSD fans. From commercial solution should be mentioned: VMware ESXi and Microsoft Hyper-V.
In this article, I'm going to describe some basics concepts of Xen hypervisor. Usually, Xen is considered as difficult to configure and manage, but In this article, I would like to overturn this myth. My goal is to make a short introduction and highlight basic concepts and show some examples. One thing that I didn't want to do is to provide a complex overview of each tool, installation etc, rather than I will provide more links to better and more focused on one topic articles.

<!-- more -->
<!-- toc -->
### Xen not exactly type 1 hypervisor.
In general, there are two types of hypervisors: type 1 and 2. This distinction is not something new, it came in 1974 [Formal Requirements for Virtualizable Third Generation Architectures](http://doi.acm.org/10.1145/361011.361073), but after years of hardware improvement and introduction technologies like intel VT-d, IOMMU this criterium is not as clear. To do not introduce more theory about CPU protection rings and x86/ARM virtualization features, it can be assumed simplified definition of type 1-2 hypervisors:
  - Type one hypervisor is running natively on bare metal hardware, and VMs run directly in this environment.
  - Type two hypervisor run on the conventional operating system (i.e as a kernel module) with other parallel OS processes, also other VMs run as another process.

![Picture.1 Graphical explanation of type 1-2 hypervisors. Thanks to Wikipedia Thanks to Wikipedia](http://res.cloudinary.com/gotocco/image/upload/v1478207185/Hyperviseur_ssvhij.png)

If we compare Type-1 hypervisor concepts with Xen architecture, we can see a similarity. However, there is one difference: Dom0 VM. In Xen concept device drivers and other tools are moved from hypervisor to Dom0. This VM behave as a normal operating system and is used to the management of VMs and drivers.

![Picture.2 Xen hypervisor architecture. Thanks to Xen Project](http://res.cloudinary.com/gotocco/image/upload/c_scale,w_460/v1478207748/XenArchitecture_oj16yz.png)

### Some theory
As for start lets take a look at sample VM configuration file. In open source Xen VM are created based on configuration files.
To better understand how Xen create, manage and works with VMs, template configuration file is really useful (it show many options). For the first view, it can look really complicated and large, but in practice, we usually need only a few properties to deploy and manage most of the VMs.

{% highlight bash %}
import os, re
arch = os.uname()[4]
if re.search('64', arch):
    arch_libdir = 'lib64'
else:
    arch_libdir = 'lib'

#----------------------------------------------------------------------------
# Kernel image file.
kernel = "/usr/lib/xen/boot/hvmloader"

# The domain build function. HVM domain uses 'hvm'.
builder='hvm'

# Initial memory allocation (in megabytes) for the new domain.
#
# WARNING: Creating a domain with insufficient memory may cause out of
#          memory errors. The domain needs enough memory to boot kernel
#          and modules. Allocating less than 32MBs is not recommended.
memory = 128

# Shadow page table memory for the domain, in MB.
# If not explicitly set, xend will pick an appropriate value.  
# Should be at least 2KB per MB of domain memory, plus a few MB per vcpu.
# shadow_memory = 8

# A name for your domain. All domains must have different names.
name = "ExampleHVMDomain"

# 128-bit UUID for the domain.  The default behavior is to generate a new UUID
# on each call to 'xm create'.
#uuid = "06ed00fe-1162-4fc4-b5d8-11993ee4a8b9"

#-----------------------------------------------------------------------------
# The number of cpus guest platform has, default=1
#vcpus=1

# Enable/disable HVM guest PAE, default=1 (enabled)
#pae=1

# Enable/disable HVM guest ACPI, default=1 (enabled)
#acpi=1

# Enable/disable HVM APIC mode, default=1 (enabled)
# Note that this option is ignored if vcpus > 1
#apic=1

# List of which CPUS this domain is allowed to use, default Xen picks
#cpus = ""         # leave to Xen to pick
#cpus = "0"        # all vcpus run on CPU0
#cpus = "0-3,5,^1" # run on cpus 0,2,3,5

# Optionally define mac and/or bridge for the network interfaces.
# Random MACs are assigned if not given.
#vif = [ 'type=ioemu, mac=00:16:3e:00:00:11, bridge=xenbr0, model=ne2k_pci' ]
# type=ioemu specify the NIC is an ioemu device not netfront
vif = [ 'type=ioemu, bridge=xenbr0' ]

#----------------------------------------------------------------------------
# Define the disk devices you want the domain to have access to, and
# what you want them accessible as.
# Each disk entry is of the form phy:UNAME,DEV,MODE
# where UNAME is the device, DEV is the device name the domain will see,
# and MODE is r for read-only, w for read-write.

#disk = [ 'phy:hda1,hda1,r' ]
disk = [ 'file:/var/images/min-el3-i386.img,hda,w', ',hdc:cdrom,r' ]

#----------------------------------------------------------------------------
# Configure the behaviour when a domain exits.  There are three 'reasons'
# for a domain to stop: poweroff, reboot, and crash.  For each of these you
# may specify:
#
#   "destroy",        meaning that the domain is cleaned up as normal;
#   "restart",        meaning that a new domain is started in place of the old
#                     one;
#   "preserve",       meaning that no clean-up is done until the domain is
#                     manually destroyed (using xm destroy, for example); or
#   "rename-restart", meaning that the old domain is not cleaned up, but is
#                     renamed and a new domain started in its place.
#
# The default is
#
#   on_poweroff = 'destroy'
#   on_reboot   = 'restart'
#   on_crash    = 'restart'
#
# For backwards compatibility we also support the deprecated option restart
#
# restart = 'onreboot' means on_poweroff = 'destroy'
#                            on_reboot   = 'restart'
#                            on_crash    = 'destroy'
#
# restart = 'always'   means on_poweroff = 'restart'
#                            on_reboot   = 'restart'
#                            on_crash    = 'restart'
#
# restart = 'never'    means on_poweroff = 'destroy'
#                            on_reboot   = 'destroy'
#                            on_crash    = 'destroy'

#on_poweroff = 'destroy'
#on_reboot   = 'restart'
#on_crash    = 'restart'

#============================================================================

# New stuff
device_model = '/usr/' + arch_libdir + '/xen/bin/qemu-dm'

#-----------------------------------------------------------------------------
# boot on floppy (a), hard disk (c), Network (n) or CD-ROM (d)
# default: hard disk, cd-rom, floppy
#boot="cda"

#-----------------------------------------------------------------------------
#  write to temporary files instead of disk image files
#snapshot=1

#----------------------------------------------------------------------------
# enable SDL library for graphics, default = 0
sdl=0

#----------------------------------------------------------------------------
# enable VNC library for graphics, default = 1
vnc=1

#----------------------------------------------------------------------------
# address that should be listened on for the VNC server if vnc is set.
# default is to use 'vnc-listen' setting from /etc/xen/xend-config.sxp
#vnclisten="127.0.0.1"

#----------------------------------------------------------------------------
# set VNC display number, default = domid
#vncdisplay=1

#----------------------------------------------------------------------------
# try to find an unused port for the VNC server, default = 1
#vncunused=1

#----------------------------------------------------------------------------
# enable spawning vncviewer for domain's console
# (only valid when vnc=1), default = 0
#vncconsole=0

#----------------------------------------------------------------------------
# set password for domain's VNC console
# default depends on vncpasswd in xend-config.sxp
vncpasswd=''

#----------------------------------------------------------------------------
# no graphics, use serial port
#nographic=0

#----------------------------------------------------------------------------
# enable stdvga, default = 0 (use cirrus logic device model)
stdvga=0

#-----------------------------------------------------------------------------
#   serial port re-direct to pty deivce, /dev/pts/n
#   then xl console or minicom can connect
serial='pty'


#-----------------------------------------------------------------------------
#   Qemu Monitor, default is disable
#   Use ctrl-alt-2 to connect
#monitor=1


#-----------------------------------------------------------------------------
#   enable sound card support, [sb16|es1370|all|..,..], default none
#soundhw='sb16'


#-----------------------------------------------------------------------------
#    set the real time clock to local time [default=0 i.e. set to utc]
#localtime=1


#-----------------------------------------------------------------------------
#    set the real time clock offset in seconds [default=0 i.e. same as dom0]
#rtc_timeoffset=3600

#-----------------------------------------------------------------------------
#    start in full screen
#full-screen=1   


#-----------------------------------------------------------------------------
#   Enable USB support (specific devices specified at runtime through the
#                       monitor window)
#usb=1

#   Enable USB mouse support (only enable one of the following, `mouse' for
#                             PS/2 protocol relative mouse, `tablet' for
#                             absolute mouse)
#usbdevice='mouse'
#usbdevice='tablet'

#-----------------------------------------------------------------------------
#   Set keyboard layout, default is en-us keyboard.
#keymap='ja'
{% endhighlight %}

### Xen installation: transform your OS to Dom0
Installation of Xen hypervisor for most of Linux distribution is really straightforward and can be done using packet management tool.  

{% highlight bash %}
# For Debian based systems
$ sudo apt-get install xen-hypervisor-amd64 xen-libs
# RedHat/Fedora
$ sudo yum -y install xen xen-hypervisor xen-libs xen-runtime
$ sudo dnf install xen xen-hypervisor xen-libs xen-runtime
{% endhighlight %}

As of Fedora/Ubuntu and other new distros, GRUB will automatically choose to boot Xen first if Xen is installed.
After installation reboot system and check if xen was installed correctly:

{% highlight bash %}
$ sudo reboot
....
$ sudo xl list
Name                                        ID   Mem VCPUs    State    Time(s)
Domain-0                                     0 15957     8     r-----    1643.0
{% endhighlight %}
Last command `xl list` show all VMs that currently running on Xen hypervisor. After installation, our Linux turns into VM Dom0.

More details about installation on Debian-based systems including disk configuration can be found at Ubuntu official [wiki](https://help.ubuntu.com/community/Xen)

### Xen tool stack
As it was said before, after installation of Xen hypervisor, new level of dependencies is created. Starting from bottom we have hardware, microkernel of hypervisor, and VMs including special by default running Dom0. One main concept of virtualization is isolation, because of that interaction between hypervisor Dom0 and other guests (In the Xen world they are called DomU) is really limited. To be able to manage hypervisor and other VMs Dom0 has running Xend daemon process which is collecting calls from different sources, and communicate with kernel using `/dev/xen`. To be able to send any message from kernel to the hypervisor there is only one method available: 'hypercalls'. From the other hand, there are many available tools to communicate with xend daemon process: there is interface for scripts languages that is used to run shell based interfaces like xl, also there exist API that can be run from C code.
Because the easiest way to manage Xen from Dom0 is by using xl command line tool, in next few paragraphs I will describe basics use-cases and different parts of stack that can be controlled using xl.
Below is a diagram that shows dependencies between different Xen components.

![Picture.3 Xen interfaces hierarchy architecture](http://res.cloudinary.com/gotocco/image/upload/c_scale,w_468/v1478634928/xenstack_jr83rv.png)

#### DOMAIN SUBCOMMANDS
The first group of commands that are used to VM management is domain subcommand. There are executed on Dom0 but their target is DomU. To manage subdomains xl toolchain allows:
  - management of VM lifecycle (create, pause, reboot, shutdown)
  - list running VMs with stats (list)
  - VM migration (migrate)
  - Debugging and Administration: dumping core, console (dump, console)

#### XEN HOST SUBCOMMANDS
The second group is used to manage host, getting information logs or even debug information:
  - hypervisor messaged (dmesg)
  - information about available and assigned memory, numa node etc (info)
  - usage of CPU by different (top)
  - the amount of memory claimed by different guests (claims)

#### SCHEDULER AND CPUs SUBCOMMANDS
Xen comes with numbers of schedules, its type can be specified during boot time using command line arguments (sched=). By default, scheduling is done by algorithm based on credits. Also for scheduling important is configuration of CPU, that also can be done using xl toolchain.
  - manage scheduling algorithms (sched-credit, sched-rtds)
  - pin CPU to domain or assign CPU-pool to VMs [including Dom0]
  - migrate of VM between pools/CPUs

#### DEVICE DRIVERS
This group is used mainly to manage external devices that are connected to DomU. An example of that can be PCI/USB devices that are passed through VM, block devices like physical disks, CD-ROM. Most of them are hotplug.
  - List all assignable devices PCI/USB/Network/Block (pci-assignable-list, pci-attach, usb-list, usbdev-attach, network-list, network-attach, block-list, block-attach )

#### OTHER: CACHE MONITORING and TRANSCENDENT MEMORY
  - Starting from Intel Haswell, servers provide monitoring capability in each logical processor to measure specific shared resource metric, as L3 cache occupancy. That can be done using (psr-cmt-attach, psr-cmt-show, psr-cmt-detach)
  - Transcendent Memory from the other hand is feature which can provide resource savings by allowing otherwise underutilized resources to be time-shared between multiple virtual machines. By definition, Transcendent Memory is: a collection of idle physical memory in a system and an interface providing indirect access to that memory (tmem-list, tmem-freeze, tmem-set)

### Fast ramp up
After I described basics concepts of Xen and tools that can be used for administration or profiling, is time to see how it looks in practice. to deploy VM we will need few things:
  - Storage for image of VM
  - Installation medium
  - Network configuration
  - A configuration file that will be created based on previous points.

#### Storage management
Xen can work with file based images like qemu `qcow2`, and also repository type which can be created based on physical partition on a disk. Usually, VMs are create using second approach, the reason for that is keeping repository based VM images is safer than taking care of different files.
I will describe these two approaches, starting from LVM repository, as it is more difficult, and after that file based which I found really valuable for development and testing/debugging as it is easily manageable and also they can be automatically scaled in run time.

#### LVM repository
To be able to manage LVM repository first think that is needed is some free unformatted disk space i.e. additional partition.
Lets assume that we have additional partition sda5 that is designed for VMs repository:

{% highlight bash %}
# Install LVM Debian based systems:
   apt-get install lvm2
# LVM configuration to use /dev/sda5 as its physical volume
   pvcreate /dev/sda5
# Create volume (logical equivalent of partition) group called ‘vg0’ using this physical volume:
   vgcreate vg0 /dev/sda5
# Now LVM is setup and initialized so that we can later create logical volumes for our virtual machines.
# For the interested below is a number of useful commands and tricks when using LVM.
# Create a new logical volume:
#   lvcreate -n<name of the volume> -L<size, you can use G and M here> <volume group>
# Example, creating a 10-gigabyte volume called image-test on a volume group called vg0.
   lvcreate -nimage-test -L10G vg0
# Remove of this volume can be done with the following:
   lvremove /dev/vg0/image-test
{% endhighlight %}

After we will create disk for VM we can create VM, but before that there are two things needed: networking and installation media.
Typical use case for VM is deployment of Windows machine. To do that installation CD is more than needed, and way to interact with external world by using network.
As network configuration, we will use bridge type of interface which can be done on main system interface (excluding wireless type interfaces) `xenbr0` (more information about configuration can be found [here](https://help.ubuntu.com/community/Xen) in section Network Configuration)

{% highlight bash %}
# 1. Hardware resources section
memory = 4096
vcpus=4
name = "WindowsVM"
# 2. Xen specific commands xen-4.X have to be replaced with correct version
kernel = "/usr/lib/xen-4.X/boot/hvmloader"
builder='hvm'
device_model_version = 'qemu-xen'
# 3. Networking/Storage
vif = ['bridge=xenbr0']
disk = ['phy:/dev/vg0/windows,hda,w','file:/media/windows.iso,hdc:cdrom,r']
# during installation use dc (boot from CD-Rom and disk), then change booting to disk c
boot = "dc" # c
# 4. Other configuration
acpi = 1
sdl=0
serial='pty'
# catch vnc to interact system
vnc = '1'
vnclisten = '0.0.0.0'
{% endhighlight %}

As can be easily seen, configuration file for windows is not as big and complex as for example configuration from beginning of article. Also
reassuring the reader may be that the xen configurations for windows is one of the most complex in terms of size and options needed.

Analysis of configuration file can be divided into few parts:
  1. Hardware resources: `memory` and `vcpu` numbers (no comment needed)
  2. Xen specific commands: `kernel` and `builder` options determine what kind of VM we are running. For windows, we don't have choice we have to run HVM (hardware virtualization). This topic will be described later, right now we assume that hvm is the only choice for Windows and for other OSes there are available also other options. `device_model_version` is also really important: as Windows always to run on real hardware, not as a VM, we have to provide it emulated hardware environment that will look from a guest perspective as real hardware.
  3. Network/Storage: As a network interface we provide real existing interface that can be displayed using `ifconfig <if>`, in this time we connect the guest to the bridge. Storage has two records: first is disk that we created inside LVM repository in vg0 group, `phy` suffix describe that this is real physical device, `hda` is a name visible for guest, and `w` describe permission to device (in this case obviously we need to write to this device). Second is CD-ROM file that we will use for installation, `file` describe that we are dealing with file based medium, `hdc:cdrom` guest will see it as CD-ROM, and `r` mean that we don't expect any write to file that emulate optical disk.
  4. Other configuration: `acpi=1` is required by Windows from similar reason that `device_model_version`, other `sdl` and `serial` are recommended for Windows VM to emulate hardware as much as possible. The last thing is configuration of VNC, that we will use to get Windows desktop. For windows is the easiest way to install OS in way how we used to do on physical machines.

Now we have working configuration we have to create VM using `xl`, and after that, we will have open VNC port on localhost:5900.

{% highlight bash %}
xl create ./windows.cfg
{% endhighlight %}

#### File based approach
In this approach rather than create full repository inside partition we will just going to create 10 Gb size VM image file:

{% highlight bash %}
qemu-img create -f qcow2 vm_image.img 10G
{% endhighlight %}

After we have image that we will be installing OS

{% highlight bash %}
memory = 2048
vcpu = 4
name = "FreeBSDVM"

# PVHVM stuff
builder = "hvm"
kernel = "hvmloader"
# during installation use cd then change to disk c
boot = "c" # dc

vif = [ 'mac=00:16:3E:01:AB:23, bridge=xenbr0' ]
disk = [ 'tap:qcow2:/media/vm_image.img, xvda, w',
         'file:/media/FreeBSD-10.2-RELEASE-amd64-disc1.iso,hdb:cdrom,r'
       ]
# catch vnc to interact system
vnc = '1'
vnclisten = '0.0.0.0'
{% endhighlight %}

In this case, the configuration is even shorter, main difference is in `disk` section: in this case we have `tap:qcow2` which describe that we have a file with image type qcow2.

In previous examples, we saw how to deploy VM, and provide simple configurations. I especially used two different OS-es: Windows and FreeBSD to show how to provide configuration for specific systems. I didn't bring Linux configuration because fortunately, Linux is able to boot with both of these configuration files.

### Debugging Xen
Xen is separated from Dom0, and it make sense to don't allow user to interact with hypervisor
{% highlight bash %}
$ cd $XEN_SRC
$ ./configure --enable-debug --enable-debugger --enable-verbose
$ make -jN
$ sudo make install
{% endhighlight %}

After that, we got additional logging for Xen kernel and also for guests we got debug hypercalls that can be saw inside `xl dmesg`

### Debugging with Xen!

#### Linux VM + Xen + gdb

Same thing that we made for FreeBSD we can apply for Linux. The fastest way to make kernel debug is just to run our qemu image nad then connect with gdb and point kernel image.
So again we need to build kernel sources with debug option. After `make menuconfig` we can verify in `.config` if `CONFIG_DEBUG_INFO=y`.
Then we need to choose a right binary image for kernel usually it is `vmlinux` in root kernel source folder. Using gdb we can verify if our image contains debug symbols.
Below simple configuration based on qcow2 image for Linux:

{% highlight bash %}
memory = 4096
vcpu = 2
name = "LinuxVM"

# PVHVM stuff
builder = "hvm"
# during installation use CD “d” then change to disk “c”
boot = "c" # dc

vif = [ 'mac=00:16:3E:01:AB:23,bridge=xenapi' ]
disk = [ 'tap:qcow2:/media/debian_amd64_standard.qcow2,xvda,w' ]

# catch vnc to interact system
vnc = '1'
vnclisten = '0.0.0.0'
{% endhighlight %}


{% highlight bash %}
$dom0> xl list
Name        ID   Mem  VCPUs    State   Time(s)
Domain-0    0  11955     8     r-----    2282.8
LinuxVM     2   3840     1     r-----    647.6

#connects to a 64bit guest with domid 2 and waits for gdb connection
$dom0> gdbsx -a 2 64 9999
{% endhighlight %}

After that we need to connect remote debugging via gdb, as an argument, we need to pass `vmlinux` image that is binary with debug symbols.

{% highlight bash %}
$dom0> gdb ./vmlinux

(gdb) set directories `(path to kernel src)`
(gdb) tar remote :9999
(gdb) n  
(gdb) bt                                                                             
#0  cpu_idle_loop () at kernel/sched/idle.c:221
#1  cpu_startup_entry (state=<optimized out>) at kernel/sched/idle.c:299  
#2  0xffffffff8147b367 in rest_init () at init/main.c:412      
#3  0xffffffff81cb1f0c in start_kernel () at init/main.c:683
#4  0xffffffff81cb148b in x86_64_start_reservations (real_mode_data=<optimized out>)
    at arch/x86/kernel/head64.c:195
#5  0xffffffff81cb157d in x86_64_start_kernel (
    real_mode_data=0x8c800 <cpu_lock_stats+522400> <error: Cannot access memory at address 0x8c800>
    ) at arch/x86/kernel/head64.c:184
#6  0x0000000000000000 in ?? ()
{% endhighlight %}

### Future references

##### External links:
{% highlight bash %}
  1. Xen installation for Ubuntu
    https://help.ubuntu.com/community/Xen
  2. xl toolchain man page
    https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html
    https://xenbits.xen.org/docs/unstable/man/xl.1.html
  3. configuration file options descriptions
    https://wiki.xenproject.org/wiki/Xen_3.x_Configuration_File_Options
  4. Network configurations examples
    https://wiki.xen.org/index.php?title=Host_Configuration/Networking&redirect=no
  5. Transcendent memory description, cooperation with xen.
    https://oss.oracle.com/projects/tmem/
  6. Xen Wiki beginner guide
    https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide

{% endhighlight %}
