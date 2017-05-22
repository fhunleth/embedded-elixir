---
title: Using ASDF-vm
subtitle: Solve All of Your Version Problems
date: 2017-05-21
author: Connor Rigby
draft: false
tags: ["nerves"]
---

Recently there has been a number of breaking changes in the Erlang/Elixir world that have caused Nerves-based projects to fail to compile, causing a lot of confusion in slack. Follow along as we solve all your version inconsistencies with ASDF-vm.

<!--more-->

# What caused the problem?
Erlang released OTP 20 into bleeding edge repositories last week, and in response to that Elixir released `v1.4.4`. If you follow the basic rules of [semver](http://semver.org/) you might spot a big red flag here.

* OTP did a MAJOR version bump
* Elixir (which is heavily dependent on OTP) did a PATCH

Granted OTP 20 is still RC, there is still a versioning inconsistency that ironically came from Elixir's `version` module.
So heres a short description of Elixir and OTP versions.

* If you want Elixir 1.4.4 you _*NEED*_ OTP 20.
  * OTP 19.x is broken with Elixir newer than 1.4.3 and vice versa
* If you want older elixir you _*CAN NOT*_ have OTP 20.
  * Elixir older than 1.4.4 is broken with OTP newer than 19

Then go ahead and sprinkle Nerves on top of that which usually uses the bleeding edge of Elixir and now we have quite the mess to manage ourselves.


# How can we solve this?
Well we enlist the help of a version manager. I've been using [ASDF-vm](https://github.com/asdf-vm/asdf) for two years now on various Linux distros (including Arch if you want to be _that_ bleeding edge) And don't worry it works on OSX too!

## Instalation
You pretty much will just need `git` for installation.
``` bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
source ~/.asdf/asdf.sh
```

then we will want to install the `plugin`s for both Erlang and Elixir

## Instal Plugins
``` bash
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
```

## Choose Versions
``` bash
asdf install erlang 19.3 # This one can take a while depending on your machine
asdf install elixir 1.4.2
```

## Setup
``` bash
asdf global erlang 19.3
asdf global elixir 1.4.2
```

## Updating
When a new stable release comes out we can do similar commands. Heres the OTP 20/ Elixir 1.4.4 example:
``` bash
asdf install erlang 20
asdf install elixir 1.4.4

asdf global erlang 20
asdf global elixir 1.4.4
```

Then when that breaks (it will) you can simply change back:
``` bash
asdf global erlang 19.3
asdf global elixir 1.4.2
```
