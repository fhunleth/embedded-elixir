---
title: Using ASDF-vm
subtitle: Solve All of Your Version Problems
date: 2017-05-23
author: Connor Rigby
draft: false
tags: ["nerves"]
---

Nerves usually pushes the bleeding edge of Elixir, which means we sometimes see problems in support channels that can be solved
by updating to the latest version of Elixir and OTP. Now there are built in options in most operating systems to do this such as
`brew`, `apt-get`, `pacman` etc, and they all work with varying levels of success. ASDF-vm is an alternate version manager that allows easy installation and smooth moves between different versions of various packages.

<!--more-->

# Managing Elixir and Erlang with ASDF-vm
Lets go through how easy it is to set up Elixir and Erlang with ASDF.

## Instalation
You pretty much will just need `git` for installation.
``` bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0
source ~/.asdf/asdf.sh
```

then we will want to install the `plugin`s for both Erlang and Elixir

## Install Plugins
``` bash
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
```

## Choose Versions
``` bash
asdf install erlang 19.2 # This one can take a while depending on your machine
asdf install elixir 1.4.2
```

## Setup
``` bash
asdf global erlang 19.2
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
