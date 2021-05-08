---
title: "Nerves 📂 👀"
subtitle: "A few practices for peeking into disk storage on remote Nerves devices"
date: 2021-05-08
author: Jon Carstens
draft: false
tags: ["nerves", "elixir", "disk"]
---

Remotely take a gander into your Nerves device disk space

<!--more-->

# Setup SSH

The most common way to interface remotely with your Nerves filesystem is via 
SSH (or [Secure Shell Protocol](https://en.wikipedia.org/wiki/Secure_Shell_Protocol)).
In fact, every method in this article is based on SSH in one way or another to get
that initial access to device and present the filesystem differently. So first
things first, you need to ensure you have SSH enabled on device and the simplest
way is to use [`nerves_ssh`](https://github.com/nerves-project/nerves_ssh).

If you're unfamiliar with it, take a quick break to brush up on [the documentation](https://hexdocs.pm/nerves_ssh/readme.html)
to get things setup. I'll wait...

🍹

K, great. Let's continue


# SFTP

When using `nerves_ssh`, SFTP is enabled by default. So you can connect to
your Nerves device and look around:

```sh
$ sftp nerves.local
Connected to nerves.local.
sftp> ls /root
/root/lost+found     /root/tzdata         /root/you_found_me  
```

Or get files from the device:

```sh
$ sftp 10.0.1.7
Connected to 10.0.1.7.
sftp> get /root/you_found_me .
Fetching /root/you_found_me to ./you_found_me
sftp> exit

$ ls
you_found_me          
```

Or put files to the device:

```sh
$ touch whammy
$ sftp 10.0.1.7
Connected to 10.0.1.7.
sftp> put whammy /root/
Uploading whammy to /root/whammy
whammy                             100%    0     0.0KB/s   00:00    
sftp> ls /root/
/root/whammy  
```

**NOTE:** The only _writable_ partition on a Nerves device, by default, is
the `/root` partition, which is also symlinked as `/data`.

## SSHFS

This is a program to use SSH to mount the remote file system locally and is
very convienent when working with many files quickly. It is not included
by default and needs to be installed on your host. YMMV and you may want
to research installation for your specific system, but the most
common ways are:

**Ubuntu/Debian**

```sh
sudo apt-get install sshfs
```

**MacOS**

You'll need to install `Fuse!` and `SSHFS` from OXSFuse:
https://osxfuse.github.io

**But, How?!**

There are a plethora of options for `sshfs` command and I encourage
you to read through the `man sshfs` page. But TL;DR is that it supports
all the same SSH options via the `-o` flag and you specify the remote
path and the mount point:

```sh
$ ls /tmp/nerves
$ sshfs nerves.local:/ /tmp/nerves
$ ls /tmp/nerves
bin/   boot/  data@  dev/   etc/   lib/   lib32@ media/ mnt/   opt/   proc/  root/  run/   sbin/  srv/   sys/   tmp/   usr/   var/
```

You can then interact with it as normal. View files, edit them
(on the `/root` or `/data` directory), etc etc. Then when you're done,
unmount the disk:

```sh
$ umount /tmp/nerves
$ ls /tmp/nerves
$
```

**Bonus! Use a plugin for your IDE**

Chances are there is an SSHFS plugin for you IDE. For example, VSCode has
the [SSH FS](https://marketplace.visualstudio.com/items?itemName=Kelvin.vscode-sshfs) plugin
which allows you to mount the remote Nerves file system with all
your other code nice and neat:

![vscode_sshfs](/images/2021-05-08/vscode_sshfs.png)


Cheers 🍻
