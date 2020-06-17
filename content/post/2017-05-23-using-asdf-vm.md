---
title: Using ASDF-vm
subtitle: Solve All of Your Version Problems
date: 2017-05-23
author: Connor Rigby
draft: false
tags: ["nerves"]
---

Nerves usually pushes the bleeding edge of Elixir, which means we sometimes
sometimes hear about problems in our Nerves Slack channel that can be solved by
updating to the latest version of Elixir and OTP. Now, there are built-in
options in most operating systems to do this, such as `brew`, `apt-get`,
`pacman` etc, and they all work with varying levels of success. ASDF-vm is an
alternate version manager that allows easy installation and switching between
different versions of various packages.

<!--more-->

# Managing Elixir and Erlang with ASDF-vm

Let's go through how easy it is to set up Elixir and Erlang with ASDF.

## Installation

You pretty much will just need `git` for installation.

```sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.6
source ~/.asdf/asdf.sh
```

We try to keep this up to date, but if you run into any issues or if this is
unclear, check out the [official instructions](https://asdf-vm.com/#/core-manage-asdf-vm).

Then you will want to install the `plugin`s for both Erlang and Elixir.

## Install plugins

```sh
asdf plugin-add erlang
asdf plugin-add elixir
```

## Choose versions

```sh
# Build and install Erlang/OTP
asdf install erlang 23.0.2

# Install Elixir 1.10 as compiled against Erlang/OTP 23
asdf install elixir 1.10.3-otp-23
```

## Setup

The following sets the Erlang and Elixir versions system-wide.

```sh
asdf global erlang 23.0.2
asdf global elixir 1.10.3-otp-23
```

If you want to fix the version used in a directory, specify `local`:

```sh
asdf local erlang 23.0.2
asdf local elixir 1.10.3-otp-23
```

The local option works by creating or updating a `.tool-versions` file in
the directory.

## Updating

When a new stable release comes out, you can do similar commands. Here's a
currently hypothetical OTP 24/Elixir 1.10 example:

```sh
asdf install erlang 24.0
asdf install elixir 1.10.3-otp-24

asdf global erlang 24.0
asdf global elixir 1.10.3-otp-24
```

Then, if that were to break, you can simply change back:

```sh
asdf global erlang 23.0.2
asdf global elixir 1.10.3-otp-23
```

## Nerves

The Nerves Project currently builds ERTS (Erlang Run Time System) into the
officially-supported systems. The build tools will throw an error if the host
machine's OTP version doesn't match the version built into the system for your
target.  This is done to ensure you can develop your application on your host
machine, then push to your embedded device and everything will work as expected.
This is where a version manager really comes in handy. Instead of sifting thru
`.deb` files, or trying to install a newer or older version of OTP using your
operating system's package manager, you can run two commands that explicitly
explain the version of a package you want.
