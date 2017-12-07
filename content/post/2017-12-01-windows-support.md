---
title: The Road to Windows
#subtitle:
date: 2017-12-0\1
author: Michael Schmidt
draft: true
tags: ["nerves", "windows"]
---

Most Elixir developers prefer Mac or Linux, but Windows is historically the platform of choice for embedded developers.  Fortunately there are many ways to get Nerves running on Windows.  Unfortunately, there is no "silver bullet"--each approach has its trade-offs.  


# 10,000 foot Overview

There are 2 fundamental approaches to Nerves-on-Windows:
1. Pretend its Unix
1. Run it as a Windows App

Each approach has its trade-offs

Furthermore, there are several Toolchains that can generate Embedded Linux Images.  

1. Buildroot
1. Yocto

As you can images, there are many permutations of the two groups.    

## Pretend its Unix

There are several ways to make Windows pretend its Unix:
1. Cygwin
1. Mingw
1. Linux VM
   1. WSL
   1. Docker
   1. Virtualized (Virtual Box / VMWare)

At present, there really aren't any solutions that leverage Cygwin or Mingw.  Virtualized solutions tend to act like Native Linux, so we will focus on WSL and Docker.

### WSL

Mac users have long enjoyed a robust Unix environmnet.  With Windows 10, Microsoft has finally decided to follow suite with is Windows for Linux Subsystem.  Unfornately there are several distinct versions of Windows 10, each with their distinct version of Ubuntu.

1. Original Release - No WSL
1. Anniversary Update - WSL is in its infancy @ Ubuntu 14.04.  Cannot run Erlang and thus Elixir 
1. Creators Update - WSL updated to Ubuntu 16.04.  First Version that runs Elixir
1. Fall Creators Update - Additional features that don't impact Elixir/Nerves


Updating Windows between these releases is problematic (at best), but if your machine can run Creators Update (or later), Nerves becomes a 1st class citizen.

* The Good
  * Nerves can run all steps except `firmware.burn` the same as Mac and Linux
* The Bad
  * No access to SD Cards from WSL
  * Choice of git directory has consequences
    * /mnt/c/* - Permission issues will abound
    * ~/* - Can't access files via Windows Editors

### Docker

Docker for Windows comes in 2 distinct flavors:
1. Docker Toolbox - Uses Virtualbox to create a Linux VM.  Supports Windows 7+
1. Docker for Windows - Uses Hyper-V to create a Linux VM.  Windows Anniversary Update+ (Note that Original Release is officially supported, sever issues are common.  You Have Been Warned)

* The Good
  * Same as WSL
  * Can use "volumes" which are Linux Native FS.  Thus preservers permissions
  * Expose volumes via Samba for Windows Editors
* The Bad
  * No access to SD Cards (same as WSL)
  * Docker Toolbox has same issues as WSL ~/* files
  * Docker for Windows has same issues as /mnt/c/* for non-volumes
  * Git over Samba has issues tracking execute permissions

  
## Run as Windows