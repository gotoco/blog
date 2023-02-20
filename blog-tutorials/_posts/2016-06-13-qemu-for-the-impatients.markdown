---
layout: post
title:  "Qemu for the impatient"
date:   2016-06-13 10:15:23 -0700
categories: Virtualization Qemu
category: tutorial
---

### Why not using qemu?
In this article, I am trying to provide some useful qemu configuration for debugging or evaluation purposes. I will assume that reader is already using qemu so I am not going to describe any theoretical aspects of this tool but focus on real use-cases that can increase productivity and save some time. Rather than describing why we should use qemu I will try just touch few cases when in my opinion qemu is not the best choice.

<!-- more -->
<!-- toc -->
At the beginning let me clarify few things: by using qemu I mean run manually qemu from a command line (sometimes with KVM hypervisor), that is really important because qemu is a common component in virtual environments and work perfectly with XEN or KVM hypervisors.
- Don't use qemu (qemu-kvm) command line style deployment for nontesting purposes, there are better tools like virsh to do this job.
- Deploying VM's with qemu style as root is opening a lot of attacks vectors.
- Don't do scripting+qemu for automation of important jobs, again there are better tools for that.

Assuming, my statement is thing twice (or more) times before you will use qemu cmd-line approach for production.

### Fast ramp up
To use qemu, we need image and configuration script. To get the image we can create it on our own or just download.
I very often return to this page: [debian repo](https://people.debian.org/~aurel32/qemu/amd64/) you can just peak ready to go Debian.
In this tutorial we will use two images: Debian that is downloaded from above the repository `debian_wheezy.qcow2` and FreeBSD 10.2 that we will install from CD-ROM and create image `freeBSD10_2.img`.

To create 10 Gb size VM image:
```bash
qemu-img create -f qcow2 qemu_image.img 10G
```
`qemu-img` is a command from qemu toolchain it requires format and size. The qcow2 format is widely used and has come advantages i.e. is dynamically allocated.
There are few others like vdi, vmdk or raw that can be used in case of migration VM to other platform or even to real hardware.

Now when we have an image we can run our VM with this image. The simplest run can be achieved by command `qemu-system-x86_64 -hda (image file)` :
```bash
qemu-system-x86_64 -hda qemu_image.img
```

In terms of downloaded OS (like above Debian), this command will create the pop-up window with a console, and after few second we will see a welcome screen.
But what in case if we need to install own OS?
Nothing easier, just add medium (like CD-ROM) after disk name. Followed example show installation configuration for FreeBSD-10.2
```bash
qemu-system-x86_64 -hda freeBSD10_2.img -cdrom FreeBSD-10.2-RELEASE-amd64-disc1.iso
```

After installation, don't forget to remove `-cdrom` flags from command to start fresh OS.
We can be happy at this point but this minimal run didn't provide to us any useful features. We even don't have a network connection.
So next we are going through few common use-cases and examples of:
1. Network configuration
2. Useful options
3. Performance configuration
4. Platform configuration
5. Debugging configuration

### Network configuration

#### Net device
If we just need the simplest Network configuration we can use `-netdev` options:
```bash
qemu-system-x86_64 -hda debian_wheezy.qcow2 -netdev user,id=user.0 -device e1000,netdev=user.0
```
After starting, we can see that VM has a network interface (in this case we created using qemu software emulation of Intel e1000 NIC).
But if we try to reach the external internet, probably we will fail.

Let's try to ping **8.8.8.8** from guest, and run tcpdump on host to see if we have any ongoing traffic:
```bash
tcpdump -nnv dst 8.8.8.8
tcpdump: listening on wlp3s0, link-type EN10MB (Ethernet), capture size 262144 bytes
18:12:13.994511 IP (tos 0x0, ttl 64, id 14959, offset 0, flags [DF], proto UDP (17), length 109)
    192.168.1.247.45503 > 8.8.8.8.7: UDP, length 81
18:12:15.002154 IP (tos 0x0, ttl 64, id 14992, offset 0, flags [DF], proto UDP (17), length 109)
    192.168.1.247.50525 > 8.8.8.8.7: UDP, length 81
```
As we see there is traffic from VM but we didn't get any response, also IP address is different that VM, hold on this is actually our HOST address! So that mean we did NAT.

#### Port forwarding
How to reach VM from a host in this case of NAT? Well, we can just use a different option to make port redirect by -hostfwd option.
```bash
qemu-system-x86_64 -hda debian_wheezy.qcow2 -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::5555-:22
```
After boot, we can just run simple ssh command pointing port **5555**, and we are inside VM.
```bash
ssh root@localhost -p 5555
```

#### Software tun/tap interface
Last networking example will be to use software tun/tap interface. Thanks for that we have full control about both sides also we can add as many interfaces as we need, but this approach requires more configuration.
Starting from host, just create interface:
```bash
tunctl -t tapvm01
```
We can verify using ifconfig if the interface was created.
After that run VM with tap interface
```bash
qemu-system-x86_64 -hda debian_wheezy.qcow2        \
  -net nic,model=e1000,vlan=1,macaddr=52:54:00:fa:ce:04  \
  -net tap,vlan=1,ifname=tapvm01,script=no,downscript=no
```
Then we need to configure the host. Let's assume that we will create a network: **10.0.2.0/24** with the gateway that is our host with IP **10.0.2.1**, and let's assign static IP for guest **10.0.2.100** (because this static IP option doesn't require additional DHCP server running).
```bash
ifconfig tapvm01 up
ifconfig tapvm01 10.0.2.1/24
route add -host 10.0.2.1 dev tapvm01
```
Then on the guest we need to also configure static IP, and GW as well (in this case guest has eth0 interface).
```bash
ifconfig eth0 10.0.2.100/24
ifconfig eth0 up
route add default gw 10.0.2.1 eth0
```
If you are using BSD guest this commands can be replaced by (interface name is em0) in file /etc/rc.conf:
```bash
ifconfig_em0="inet 10.0.2.100 netmask 255.255.255.0" defaultrouter="10.0.2.1"
```

#### Setup IP forwarding on host machine
After that we can ping from host guest and vice versa, also we are able to ssh/scp between machines. But we still can't reach external network from the guest.
To achieve this we need to add IP forwarding. In my case, I have wireless interface **wlp3s0** connected to wifi and tapvm01 connected to VM.
```bash
iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE
iptables -I FORWARD 1 -i tapvm01 -j ACCEPT
iptables -I FORWARD 1 -o tapvm01 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Last thing to do, to allow guest to communicate with network is to enable IP forwarding:
```bash
#Check if ip_forwarding is enable:
cat /proc/sys/net/ipv4/ip_forward
0
#Enable forwarding:
echo 1 > /proc/sys/net/ipv4/ip_forward
#Or using sysctl
sysctl -w net.ipv4.ip_forward=1
```

### Performance optimalization

#### Hypervisor
You can read that qemu can be hypervisor but it bases on purely software approach. To get more performance KVM should be used. Sometimes qemu by default is using KVM if available, but if we need to be sure we can choose it using flag  `-enable-kvm`

#### More resources
Just simple we can specify memory and also number of threads/cores that will run our VM to do this use `-m` and `-smp` flags

#### IO
Resources as a number of cores or memory are really intuitive things, but usually, performance suffers because of IO operations. To increase our performance we can use `Virtio` interfaces. These interfaces are called para-virtualized, that mean we don't simulate real hardware instead of this we can create a simple buffer between guest and host and tell the guest that it deal with a virtual interface, not real hardware. This approach requires additional driver on guest but fortunately, it is really common approach so Linux and BSD systems by default will handle this. For windows we didn't have this possibility, we always need to emulate hardware.
We can are using Virtio usually for disks and network interface.

Let's run our guest with 16 cores 2 sockets x8 cores, 2Gb of RAM and Virtio for disk and network card:
```bash
qemu-system-x86_64                                                   \
  -smp 16,cores=8,threads=1,sockets=2,maxcpus=32 -m 2048 -enable-kvm \
  -drive file=debian_wheezy.qcow2,if=virtio,index=0            \
  -net nic,model=virtio,vlan=1,macaddr=52:54:00:fa:ce:04             \
  -net tap,vlan=1,ifname=tapvm01,script=no,downscript=no
```

After the run, we can check how these interfaces are visible. Just start with lspci:
```bash
00:03.0 Ethernet controller: Red Hat, Inc Virtio network device
00:04.0 SCSI storage controller: Red Hat, Inc Virtio block device
```

Also, we can examine /proc/cpuinfo to check a number of processors, and /proc/meminfo to see the amount of RAM memory.

#### Passthrough
Sometimes even Virtio can be not enough and we can need to pass whole physical device to our VM. To do this we need `iommu` enabled as a command line arg for our host, and also `VT-d` enabled in BIOS.
for intel machines we can add to grub followed line:
```bash
iommu=pt intel_iommu=on
```

To take effect, reboot host machine and check if IOMMU is enabled i.e.
```bash
dmesg | grep -e DMAR -e IOMMU
```

If we are ok with IOMMU, we need to tell the kernel to stop using this PCI device. It can be done using vifo or pci-stub modules.

```bash
modprobe vfio
modprobe vfio-pci

# detach the VFs from the host
echo -n "0000:03:00.0" > /sys/bus/pci/drivers/<drivername>/unbind

# attach VFs to vfio
lspci -n | grep "addres"
echo "<ManufacturerID> <ID>" > /sys/bus/pci/drivers/vfio-pci/new_id
```
If driver was bind to new PCI driver, to use it on VM we need to add -device vfio-pci,host=03:00.0 line to our start script
```bash
qemu-system-x86_64                                                    \
  -smp 16,cores=8,threads=1,sockets=2,maxcpus=32 -m 2048 -enable-kvm  \
  -drive file=debian_wheezy.qcow2,if=virtio,index=0                   \
  -net nic,model=virtio,vlan=1,macaddr=52:54:00:fa:ce:04              \
  -net tap,vlan=1,ifname=tapvm01,script=no,downscript=no              \
  -device vfio-pci,host=03:00.0
```


### Platform configuration

#### Display options.

Sometimes when you are running VM popup window can be annoying. We can disable it and forward output to the console by using `-nographic` flag.
Also sometimes, i.e. for freeBSD or windows kernel don't allow to forward console, and we need a different approach. To omit this limit we can use `-vnc` option.
```bash
qemu-system-x86_64 -smp 4 -m 2048 -enable-kvm   -nographic  -vnc 0.0.0.0:5  -drive file=freeBSD10_2.img,if=virtio,index=0
```

Followed command will not show us pop-up and run VNC on localhost on port 5905 (default port is 5900, and the last number is offset that is added to base)

There is also useful flag `-curses`, using it we will cast graphic mode to terminal curses/ncurses interface. Nothing is displayed in graphical mode.
```bash
qemu-system-x86_64 -smp 4 -m 2048 -enable-kvm -drive file=debian_wheezy.qcow2,if=virtio,index=0  -curses
```

#### Bios
Sometimes for fully virtualized guest is a nice tool to reconfigure system clock, doing that we can check how our drivers will behave with different dates. To isolate guest time from host we also need clock=vm option.
```bash
qemu-system-x86_64 -smp 4 -m 2048 -enable-kvm  -drive file=freeBSD10_2.img,if=virtio,index=0   -rtc base="1999-01-01",clock=vm
```

Boot order can be specified using `-boot` flag with options: `a, b (floppy 1 and 2)`, `c (first hard disk)`, `d (first CD-ROM)`, `n-p (Etherboot from network adapter 1-4)`, followed command will run Debian with disabling graphic mode (just console) that will try to boot from hard disk, also we attached cdrom to give user possibility to install other software.
```bash
qemu-system-x86_64 -hda debian_wheezy.qcow2 -nographic -boot c -cdrom image.iso
```

Last option that I wanted to highlight is `-no-acpi` flag. For some old VM images (especially non-opensource OS-es) it can make a sense to disable acpi, that can give performance benefit. From the other hand other more high-level tools like virsh don't set this flag by default, and it should be specified directly that we are using acpi interface `(by <features><acpi/></features>)`.


### Debugging with qemu!

In the last paragraph, we will talk about how we can debug guest VM with qemu.

#### Slow down the VM

First of all, I will start with `-icount` option. This will enable virtual instruction counter. The virtual CPU will execute one instruction every 2^N ns of virtual time. If "auto" is specified then the virtual CPU speed will be automatically adjusted to keep virtual time within a few seconds of real time. It is really helpful if we need to track VM behaviour in real time and events can occur faster than we can notice that. For some non-Linux legacy VM using `-icount` greater than 17 can entirely hang VM execution (The number 17 comes only from my past experience it is not any magic number, and I show it only to give reader some reference)

#### FreeBSD + QEMU + gdb

Now we will start with debugging. First of all, we will examine freeBSD and then we will switch to Linux. From qemu, there are two useful flags for debugging with gdb: `-s -S`.
Following qemu man:
`-S` Do not start CPU at startup (you must type 'c' in the monitor).
`-s` Shorthand for `-gdb tcp::1234`, i.e. open a gdb server on TCP port 1234.
But before we will run our machine we will also need the kernel and debug symbols for debugging pruposes. So lets just run guest VM and copy  `kernel` and `kernel.symbols` from `/boot/kernel` to the host machine.

To debug freeBSD we need kernel and kernel.symbols that can be found in  /boot/kernel directory. We can start VM with `-s -S` options.
```bash
qemu-system-x86_64 -smp 1 -m 1024 -s -S    -drive file=bsd8_4.img,if=virtio,index=0
```

After that, we need to run gdb, but thanks for `-S` VM will not run without cont command.
To run gdb with ./kernel binary, and connect to remote target followed command can be used.
```bash
gdb ./kernel
(gdb) tar remote :1234
```

Sometimes there can be issues similar to followed one:
```bash
Remote 'g' packet reply is too long: 0b0000000000000000000000000000001027000000000000ae0b00000000000009000000000000000200000000000000e04b020080ffffff704b020080ffffff00000000000000000000000000000000ed00000000000000201d9b80ffffffff70b45e0200ffffff70845e0200ffffff0c00000000000000c083df80ffffffffcbea6580ffffffff4602000020000000000000003b000....
```
To omit that, first of all, I recommend you for debugging and hacking to use own (by own I mean version that is not delivered by default to your distro) built stable qemu and gdb version.
Also followed command can be helpful.
```bash
(gdb) set remote target-features-packet  on
(gdb) set architecture i386:x86-64
(gdb) set debug remote 1
```

This problem is really well described on [SO](http://stackoverflow.com/questions/8662468/remote-g-packet-reply-is-too-long) including followed options, patching gdb and also by don't using `-S` flag.

After that, we can just setup breakpoints and see how kernel sources are executed
```bash
(gdb) b mi_startup
(gdb) c
```

#### Linux kernel + QEMU + gdb

Same thing that we made for FreeBSD we can apply for Linux. The fastest way to make kernel debug is just to run our qemu image nad then connect with gdb and point kernel image.
So again we need to build kernel sources with debug option. After `make menuconfig` we can verify in `.config` if `CONFIG_DEBUG_INFO=y`.
Then we need to choose a right binary image for kernel usually it is `vmlinux` in root kernel source folder. Using gdb we can verify if our image contains debug symbols.

To make debug we just need start VM with `-s -S` options.
```bash
qemu-system-x86_64 -smp 1 -m 1024 -s -S   -drive file=debian_wheezy.qcow2,if=virtio,index=0
```

After that we need to connect remote debugging via gdb, as an argument we need to pass `vmlinux` image that is binary with debug symbols.

```bash
gdb ./vmlinux

(gdb) set directories `(path to kernel src)`
(gdb) tar remote :1234
```

```bash
#0  default_idle () at arch/x86/kernel/process.c:308
#1  0xffffffff8101da60 in arch_cpu_idle () at arch/x86/kernel/process.c:298
#2  0xffffffff81079efc in default_idle_call () at kernel/sched/idle.c:93
#3  0xffffffff8107a022 in cpuidle_idle_call () at kernel/sched/idle.c:151
#4  cpu_idle_loop () at kernel/sched/idle.c:242
#5  cpu_startup_entry (state=<optimized out>) at kernel/sched/idle.c:291
#6  0xffffffff8141e13e in rest_init () at init/main.c:408
#7  0xffffffff818d3e90 in start_kernel () at init/main.c:661
#8  0xffffffff818d346d in x86_64_start_reservations (real_mode_data=<optimized out>) at arch/x86/kernel/head64.c:195
#9  0xffffffff818d355f in x86_64_start_kernel (real_mode_data=0x8c800 <error: Cannot access memory at address 0x8c800>)
    at arch/x86/kernel/head64.c:176
#10 0x0000000000000000 in ?? ()
Packet received: 0000000000000000
(gdb) list
303	 */
304	void default_idle(void)
305	{
306		trace_cpu_idle_rcuidle(1, smp_processor_id());
307		safe_halt();
308		trace_cpu_idle_rcuidle(PWR_EVENT_EXIT, smp_processor_id());
309	}
310	#ifdef CONFIG_APM_MODULE
311	EXPORT_SYMBOL(default_idle);
312	#endif
```

In real life we often don't need full-featured root filesystem, so to simplify we can just prepare own initramfs with small test applications and loadable kernel modules. That approach was described by Stefan Hajnoczi on his [blog](http://vmsplice.net/~stefan/stefanha-kernel-recipes-2015.pdf) and also as well on [LWN.net](https://lwn.net/Articles/660404/)

#### qemu monitor (with graphic mode ctl+alt+2)

##### Memory Dump:
With qemu monitor, we can make things like dumping VM memory using pmemsave
```bash
pmemsave <start address> <length> <filename>
```
##### Log specification:
We can also specify log files using `logfile <filename>` option if the `-d` flag will not be enough for us.
##### Memory examination:
There also a lot of embedded debugging option like examination of physical guest memory
 Example - Display the last 20 words on the stack for an x86 processor:
```bash
(qemu) xp /20wx $esp

fffff8000024b70:  0x00000000  0x00000000  0x00000000  0x00000000
fffff8000024b80:  0x00000000  0x00000000  0x00000000  0x00000000
fffff8000024b90:  0x00800000  0x00000000  0x00000000  0x00000000
fffff8000024ba0:  0x04320000  0x00000012  0x00000000  0x00000000
fffff8000024bb0:  0x00000000  0x0000fff0  0x00000000  0x00000000
```

### Future references
In this tutorial, we covered a lot of different use cases for qemu that can be used as a reference during work with qemu VMs.
Of course, here we show just a basics. We don't speak about some other interesting topics like numa and memory configuration.
From the driver perspective there are also other devices like chardev, which are useful for kernel development.
Also, another huge topic is about combining kvm with qemu and getting advantages from this configuration.
To mastering qemu the absolute must have is man page of qemu. Also, other qemu tools like monitor or qemu-img have different documentation, and as you can expect qemu monitor is alone huge topic to create even bigger tutorial about it.

##### External links:
> [Man Page for QEMU](http://linux.die.net/man/1/qemu-kvm)
> [Man Page for QEMU-IMG](http://linux.die.net/man/1/qemu-img)
> [QEMU Different Logging options](https://en.wikibooks.org/wiki/QEMU/Monitor#log)
> [Speeding up kernel development with QEMU](https://lwn.net/Articles/660404/)
