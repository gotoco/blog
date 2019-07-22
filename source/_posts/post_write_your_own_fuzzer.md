title: Write yout own fuzzer for NetBSD kernel!
date: 2019-07-22 00:00:01
categories:
- Kernel
- Fuzzing
tags:
- BSD
clearReading: true
feature: https://res.cloudinary.com/gotocco/image/upload/c_scale,w_500/v1562072354/krolik_iuavvr.jpg
thumbnailImagePosition: right
autoThumbnailImage: yes
metaAlignment: center
coverCaption:
coverMeta: out
coverSize: partial
comments: false
---


### How Fuzzing works? The dummy Fuzzer.
<img align="right" src="https://res.cloudinary.com/gotocco/image/upload/c_scale,w_500/v1562072354/krolik_iuavvr.jpg">

The easy way to describe fuzzing is to compare it to the process of unit testing a program, but with different input. This input can be random, or it can be generated in some way that makes it unexpected form standard execution perspective.

The simplest 'fuzzer' can be written in few lines of bash, by getting N bytes from `/dev/rand`, and putting them to the program as a parameter. 

<!-- more -->
<!-- toc -->
#### Coverage and Fuzzing
 What can be done to make fuzzing more effective? If we think about fuzzing as a process, where we place data into the input of the program (which is a black box), and we can only interact via input, not much more can be done.

However, programs usually process different inputs at different speeds, which can give us some insight into the program's behavior. During fuzzing, we are trying to crash the program, thus we need additional probes to observe the program's behaviour.

Additional knowledge about program state can be exploited as a feedback loop for generating new input vectors. Knowledge about the program itself and the structure of input data can also be considered. As an example, if the input data is in the form of HTML, changing characters inside the body will probably cause less problems for the parser than experimenting with headers and HTML tags.

For open source programs, we can read the source code to know what input takes which execution path. Nonetheless, this might be very time consuming, and it would be much more helpful if this can be automated. As it turns out, this process can be improved by tracing coverage of the execution. 

<img align="right" src="https://res.cloudinary.com/gotocco/image/upload/c_scale,w_279/v1562019535/maze-3312540_960_720_gj9g0b.png">

 AFL (American Fuzzy Lop) is one of the first successful fuzzers. It uses a technique where the program is compiled with injected traces for every execution branch instruction. During the program execution, every branch is counted, and the analyzer builds a graph out of execution paths and then explores different "interesting" paths.

Now, fuzzing has become a mainstream technique, and compilers provide an option to embed fuzzing hooks at compilation time via switches.

The same process can be applied to the kernel world. However, it would be quite hard to run another program on the same machine outside of the kernel to read these counters. Because of that, they usually are made available inside the kernel. 
To illustrate how that is done, we can compile a `hello world` program written in C for tracing the `Program Counter (PC)`. 

```
gcc main.c -fsanitize-coverage=trace-pc

/usr/local/bin/ld: /tmp/ccIKK7Eo.o: in function `handler':
main.c:(.text+0xd): undefined reference to `__sanitizer_cov_trace_pc'
/usr/local/bin/ld: main.c:(.text+0x1b): undefined reference to `__sanitizer_cov_trace_pc'
```

The compiler added additional references to the `__sanitizer_cov_trace_pc`, but we didn't implement them or linked with something that provided the implementation.
If we grep head NetBSD kernel sources for the same function: `__sanitizer_cov_trace_pc` we will find inside `sys/kern/subr_kcov.c` an implementation [kcov(4)](https://github.com/NetBSD/src/blob/trunk/sys/kern/subr_kcov.c).

### Which Fuzzer should I choose?
In recent years, AFL has grown into an industry standard. Many projects have integrated it into their development process. This has caused many different bugs and issues to be found and fixed in a broad spectrum of projects (see [AFL website](http://lcamtuf.coredump.cx/afl/) for examples). As this technique has become mainstream, many people have started developing custom fuzzers. Some of them were just modified clones of AFL, but there were also many different and innovative approaches. Connecting a custom fuzzer or testing some unusual execution path is no longer considered as just a hackathon project, but part of security research.

I personally believe that we are still in the early state of fuzzing. A lot of interesting work and research is already available, but we cannot explain or prove why one way is better than another one, or how the reference fuzzer should work, and what are its technical specifications.

Many approaches have been developed to do efficient fuzzing, and many bugs have been reported, but most of the knowledge comes still from empirical experiments and comparison between different techniques. 

### Modular kcov inside the kernel
Coverage metrics inside kernel became a standard even before the fuzzing era. A primary use-case of coverage is not fuzzing, but testing, and measuring test coverage. While code coverage is well understood, kernel fuzzing is still kind of a Wild West, where most of the projects have their own techniques. There are some great projects with a large community around them, like `Honggfuzz` and `Syzkaller`. Various companies and projects manitain several fuzzers for kernel code. This shows us that as a kernel community, we need to be open and flexible for different approaches, that allow people interested in fuzzing to do their job efficiently. In return, various fuzzers can find different sets of bugs and improve the overall quality of our kernel. 

In the past, Oracle made some effort to upstream interface for AFL inside Linux kernel [see the patch](https://lkml.org/lkml/2016/11/16/668) however the patches were rejected via the kernel community for various reasons.
We did our own research on the needs of fuzzers in context of kcov(4) internals, and quickly figured out that per-fuzzer changes in the main code do not scale up, and can leave unused code inside the kernel driver. 
In NetBSD, we want to be compatible with `AFL`, `Hongfuzz`, `Syzkaller` and few other fuzzers, so keeping all fuzzer specific data inside the module would be hard to maintain.

One idea that we had was to keep raw coverage data inside the kernel, and process it inside the user space fuzzer module. Unfortunately, we found that current coverage verbosity in the NetBSD kernel is higher than in Linux, and more advanced traces can have thousand of entries. One of the main requirements for fuzzers is performance. If the fuzzer is slow, even if it is smarter than others, it will most likely will find fewer bugs. If it is significantly slower, then it is not useful at all. We found that storing raw kernel traces in kcov(4), copying the data into user-space, and transfoming it into the AFL format, is not an option. The performance suffers, and the fuzzing process becomes very slow, making it not useful in practice. 

We decided to keep AFL conversion of the data inside the kernel, and not introduce too much complexity to the coverage part. As a current proof of concept API, we made kcov more modular, allowing different modules to implement functionality outside of the core requirements.  The current path can be view [here](http://netbsd.org/~kamil/patch-00131-modular-kcov.txt) or on the [GitHub](https://github.com/krytarowski/kcov_modules).


#### KCOV Modules
As we mentioned earlier, coverage data available in the kernel is generated during tracing by one of the hooks enabled by the compiler. Currently, NetBSD supports PC and CMP tracing. The Kcov module can gather this data during the trace, convert it and expose to the user space via `mmap`.
To write our own coverage module for new PoC API, we need to provide such operations as: `open`, `free`, `enable`, `disable`, `mmap` and handling traces.

This can be done via using kcov_ops structure:

```
static struct kcov_ops kcov_mod_ops = {
	.open = kcov_afl_open,
	.free = kcov_afl_free,
	.setbufsize = kcov_afl_setbufsize,
	.enable = kcov_afl_enable,
	.disable = kcov_afl_disable,
	.mmap = kcov_afl_mmap,
	.cov_trace_pc = kcov_afl_cov_trace_pc,
	.cov_trace_cmp = kcov_afl_cov_trace_cmp
};
```

During load or unload, the module must to run `kcov_ops_set` or `kcov_ops_unset`.  After set, default `kcov_ops` are overwritten via the module and unset return to the default.

### Porting AFL as a module
The next step would be to develop a sub-module compatible with the AFL fuzzer.

To do that, the module would need to expose a buffer to user space, and from kernelspace would need to keep information about the 64kB SHM region, previous PC, and thread id. The thread id is crucial, as usually fuzzing runs few tasks. This data is gathered inside the AFL context structure: 

```
typedef struct afl_ctx {
	uint8_t *afl_area;
	struct uvm_object *afl_uobj;
	size_t afl_bsize;
	uint64_t afl_prev_loc;
	lwpid_t lid;
} kcov_afl_t;
```

<img align="right" src="https://res.cloudinary.com/gotocco/image/upload/c_scale,w_500/v1562073974/shm2_mtovrh.png">

The most important part of the integration is to translate the execution shadow, a list of previous PCs along the execution path, to the AFL compatible hash-map, which is a pair of (prev PC, PC). That can be done according to the documentation of [AFL](https://github.com/mirrorer/afl/blob/master/docs/technical_details.txt#L30) by this method:  .

```
++afl->afl_area[(afl->afl_prev_loc ^ pc) & (bsize-1)];
afl->afl_prev_loc = pc;
```

In our implementation, we use a trick by Quentin Casasnovas of Oracle to improve the distribution of the counters, by storing the hashed PC pairs instead of raw. 

The rest of operations like: `open`, `mmap`, `enable`  can be review in the [GitHub repository](https://github.com/krytarowski/kcov_modules/blob/afl_submodule/afl/kcov_afl.c) together with the testing code that dumps 64kB of SHM data.

### Debugg your fuzzer
<img align="right" src="https://res.cloudinary.com/gotocco/image/upload/c_scale,w_500/v1563829260/krolik-debugging_dy8mgm.png">

Everyone knows that kernel debugging is more complicated than programs running in the user space. Many tools can be used for doing that, and there is always a discussion about usability vs complexity of the setup. People tend to be divided into two groups: those that prefer to use a complicated setup like kernel debugger (with remote debugging), and those for which tools like `printf` and other simple debug interfaces are sufficient enough. 

Enabled coverage brings to the kernel debugging even more complexity. Everyone favourite `printf` also become traced, so putting it inside trace function obviously will end up with stack overflow. Also touching any `kcov` internal structures become very tricky and should be avoided if possible.

A debugger is still a sufficient tool, however, as we mentioned earlier trace function are called for every branch which can be translated to thousand or even tens of thousand break points before any specific condition will occur.
I am personally more a `printf` than `gdb` guy, and in most cases, the ability to print variables content is enough to find the issues.
For validating my AFL `kcov` plugin, I figure out that [debugcon_printf](https://github.com/krytarowski/debugcon_printf) written by Kamil Rytarowski is such a great tool.


#### Example of debugcon_printf

To illustrate that idea lets say that we want to print every PC Trace that comes to our AFL submodule.

The most intuitive way would be put `printf("#:%p\n", pc)` at very beginning of the `kcov_afl_cov_trace_pc`, but as mentioned earlier such trick would end up with the kernel crash whenever we enable tracing with our module.
However if we will switch `printf` to the `debugcon_printf`, and add simple option to our QEMU:     

`-debugcon file:/tmp/qemu.debug.log -global isa-debugcon.iobase=0xe9`     

we can see on our host machine all traces comes to the file `qemu.debug.log`


```C
kcov_afl_cov_trace_pc(void *priv, intptr_t pc) {
	kcov_afl_t *afl = priv;

	debugcon_printf("#:%x\n", pc);

	++afl->afl_area[(afl->afl_prev_loc ^ pc) & (afl->afl_bsize-1)];
	afl->afl_prev_loc = _long_hash64(pc, BITS_PER_LONG);

	return;
}
```

### Future work

The AFL submodule was developed as part of the [AFL FileSystems Fuzzing](https://wiki.netbsd.org/projects/project/afl_filesystem_fuzzing/) project to simplify the fuzzing of different parts of the NetBSD kernel.
I am using it currently for fuzzing different Filesystems, in the future article I plan to show more practical examples.

Another great thing to do will be to refactor KLEAK, which is using PC trace data and is disconnected from kcov. A good idea would be to rewrite it as a kcov module, to have one unified way to access coverage data inside NetBSD kernel. 


### Summary
In this article, we familiarized the reader with the technique of fuzzing, starting from theoretical background up to the level of kernel fuzzing. 
Based on these pieces of information, we demonstrated the purpose of the a modular coverage framework inside the kernel and an example implementation of submodule that can be consumed by AFL. 
More details can be learned via downloading and trying the sample code shown in the example. 

At the end of this article, I want to thank Kamil, for such a great idea for a project, and for allowing me to work on NetBSD development. 

