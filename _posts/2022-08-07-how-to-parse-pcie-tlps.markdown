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

## PCI Express Error reporting

## Using TLP-Tool to parse TLPs

### Setting up tlp tool

### Header Log

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
