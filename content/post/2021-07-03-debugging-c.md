---
title: "Debugging C Code on Nerves"
subtitle: "AKA Getting usable stack traces from core dumps"
date: 2021-07-03
author: Connor Rigby
tags: ["nerves", "coredump"]
---

Having trouble debugging C code on Nerves? This post shows how to create, obtain
and work with core dumps.

<!--more-->

## Debugging C code

Typically, when developing an application with Nerves, we like to stay inside
The Beam. Occasionally, we need to interface to existing C and C++ applications
and libraries. In this post, we'll look at new Nerves tooling to simplify using
core dumps generated by C programs on the device.

## Getting set up

These instructions use new features in the Nerves stack, so we need to make sure
we have the latest versions.  Specifically, we need [nerves
v1.7.9](https://github.com/nerves-project/nerves/releases/tag/v1.7.9) or later
and Nerves systems based on [nerves_system_br
v1.16.1](https://github.com/nerves-project/nerves_system_br/releases/tag/v1.16.1)
or later. For this tutorial, we'll create a brand new application:

```sh
mix nerves.new firmware
```

Next up we'll need to add the `elixir_make` dependency to compile our C code.
Add the following to the `deps()` function inside `mix.exs`:

```elixir
def deps do
  {:elixir_make, "~> 0.6", runtime: false}
end
```

and also add it to the `compilers` option of `project()`:

```elixir
def project do
  [
    compilers: [:elixir_make | Mix.compilers()]
  ]
end
```

Next, we will need to instruct `erlinit` to set the system's resource limits.
Specifically, we need to set the `core` dump limits. A core dump is a file
containing a process's memory and more importantly, a stacktrace when the
process terminates unexpectedly. By default core dumps are disabled. To enable
collecting core dumps, open `config/target.exs` and find the configuration for
`erlinit` and add the following:

```elixir
config :nerves,
  erlinit: [
    hostname_pattern: "nerves-%s",
    limits: "core:unlimited:unlimited"
  ]
```

The `:limits` key works similar to the shell's `ulimit` command and takes an
option and the a hard and soft limit. See
[setrlimit(2)](https://man7.org/linux/man-pages/man2/setrlimit.2.html) for a
more technical description. The important part here is that the Linux kernel
should not restrict the core dump size at all.

Finally, create a `Makefile` to build an executable called `example`. This file
will wind up in the `priv` directory on your target device's firmware.

```Makefile
# output and build directories. MIX_APP_PATH is supplied by elixir-make.
PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

all: install

# This is important for enabling debug symbols
CFLAGS += -g
LDFLAGS += -g

install: $(BUILD) $(PREFIX) $(PREFIX)/example

# ERL_CFLAGS and ERL_LDFLAGS are also set by elixir-make

# Rule for building C source
$(BUILD)/%.o: src/%.c
  $(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

# Rule for linking to the final executable
$(PREFIX)/example: $(BUILD)/example.o
  $(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

$(PREFIX) $(BUILD):
  mkdir -p $@

clean:
  $(RM) $(PREFIX)/example $(BUILD)/*.o

.PHONY: all clean install
```

## Example

Create a new `c` source file `src/example.c`:

```c
#include <stdlib.h>

int main(int argc, char const *argv[])
{
  // generate a core dump
  abort();
  return 0;
}
```

Now that all the pieces are in place, we can create and burn firmware:

```sh
mix firmware.burn
```

And load the SD Card into your device. Next, SSH into the device:

```sh
ssh nerves.local
```

At the console we have to perform one setup command:

```elixir
iex> File.write!("/proc/sys/kernel/core_pattern", "/data/core-%e-%p-%h")
```

This instructs Linux to put the core dump in `/data` using that pattern provided.

Finally, we can execute our example program:

```elixir
iex> :os.cmd(:code.priv_dir(:firmware) ++ '/example')
iex> ls("/data")
core-example-41-1622824880
```

Now that the core dump exists we need to get it back onto our host machine. The
simplest way to do that is using `sftp`:

```sh
sftp nerves.local
sftp> cd /data
sftp> get core-example-41-1622824880

```

Now on host to check this core dump out, we'll use `gdb`. Specifically, the
`gdb` that comes with the Nerves toolchain. There's some tedious path and
environment setup that needs to be done to make this work, so we put together a
short script to do it:

```sh
mix firmware.gen.gdb
```

and finally, we can use that script with our dump file:

```sh
./run-gdb.sh core-example-41-1622824880 _build/${MIX_TARGET}_dev/priv/example
```

From the GDB console, you can now type `bt` to get the `backtrace` of the
executable. You should see something like:

```gdb
(gdb) bt
#0  0x00007fdb4fadad22 in raise () from /usr/lib/libc.so.6
#1  0x00007fdb4fac4862 in abort () from /usr/lib/libc.so.6
#2  0x000055f89d40e14d in main (argc=1, argv=0x7fff1fe0a868) at src/example.c:5
```
