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
1. Docker for Windows - Uses Hyper-V to create a Linux VM.  Windows Anniversary
Update+ (Note that Original Release is officially supported, severe issues are
common.  You Have Been Warned)

* The Good
  * Same as WSL
  * Can use "volumes" which are Linux Native FS.  Thus preserves permissions
  * Expose volumes via Samba for Windows Editors
* The Bad
  * No access to SD Cards (same as WSL)
  * Docker Toolbox has same issues as WSL ~/* files
  * Docker for Windows has same issues as /mnt/c/* for non-volumes
  * Git over Samba has issues tracking execute permissions


## Run as Windows

The second major approach is to run Nerves "natively" on Windows the same way
its run on Mac.  Since Windows is not a Unix OS, there are some extra catches.

1. Paths:  The modules which setup the cross-compiler have to be modified to
support Windows-style paths
1. Symbolic links:  Windows has progressiviely addes symbolic links over the
last several versions, but they still operate differently than their Unix
counter-parts.  The major sticking point is that Windows does not allow the
creation of symbolic links to a location that does not exist.  This causes
huge issues when trying to unpack a nerves_system archive, as the symbolic
links may occur before the files that they reference
1. File Case Sensitivity:  The Linux kernel has files that differs only in case.
This makes it hard to even upack on a Windows file system
1. Ecosystem:  Many dependencies (accidentally??) require a unix environment to compile


## Recomendations

If you are running Windows 10 Creator's Update, then the choice is easy:  use WSL.
Tim Mecklem has a great [video here](https://www.youtube.com/watch?v=rzV0qfhzzqc).  Just watch out where you checkout code, and make sure "git" is always run from WSL.

For previous version of Windows, Docker Toolbox works fairly well, and gives an environment
close to WSL.  The CROPS project has step-by-step [instructions here](https://github.com/crops/docker-win-mac-docs/wiki/Windows-Instructions-%28Docker-Toolbox%29)
