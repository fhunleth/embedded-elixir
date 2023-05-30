---
title: "Autoloading NIFs on Nerves"
subtitle: "Making load-time crashes easier to debug"
date: 2023-05-29
author: Frank Hunleth
draft: false
tags: ["nerves", "elixir", "nif"]
---

Native Implemented Functions (NIFs) let you significantly speed up code or
make system calls that would otherwise be unavailable. However, they come with a
significant cost in that when they go wrong, they can take down the entire
Erlang VM. This is particularly challenging when using NIFs with Nerves when
crashes happen at boot time.

<!--more-->

A common Elixir idiom for loading NIFs with Nerves is defining a custom
`on_load` function for a module and turning off autoloading:

```elixir
@on_load {:load_nif, 0}
@compile {:autoload, false}

def load_nif() do
  nif_binary = Application.app_dir(:my_library, "priv/my_nif")
  :erlang.load_nif(to_charlist(nif_binary), 0)
end
```

By default, Elixir autoloads the module after compilation. Since Nerves
crosscompiles NIFs for the target, the NIF will almost certainly fail to load on
the build machine.

While effective, this idiom can make debugging NIFs harder. When a NIF fails to
load on Nerves, the device reboots. This can lead to a slow and painful debug
loop, involving adding `printf`s and repeatedly reflashing MicroSD cards. Even
though Erlang supports loading modules on demand which can sometimes get NIF
loads to occur after initialization, it still may not be easy to move the crash
to a more convenient time.

There's an alternative approach that offers easier debugging: Load the NIF when
a function that actually calls into the NIF is invoked. This approach is
straightforward since Elixir requires us to write stub functions for every
function in the NIF any. Here's a typical stub for a NIF function:

```elixir
def do_something(), do: :erlang.nif_error(:nif_not_loaded)
```

The `:erlang.nif_error/1` helper raises an exception if the NIF isn't loaded.
However, if the NIF is loaded, the corresponding C (or Zig or Rust, etc.)
function is called instead.

Now, how can we load the NIF the first time the `do_something/0` function is
called?

First, remove the `@on_load` and `@compile` attributes at the top of the file
since those are no longer needed. Then, modify `do_something/0` as follows:

```elixir
def do_something() do
  :ok = load_nif()
  apply(__MODULE__, :do_something, [])
end
```

Two points need to be highlighted:

1. The `:ok` match for `load_nif/0` ensures that the loading process works.
   Without this, if the loading doesn't work, the next line will enter an
   endless recursion.
2. The second point to note is that the `apply/3` call is necessary to satisfy
   Dialyzer, a static analysis tool for BEAM languages. Dialyzer struggles to
   infer that `load_nif/0` will replace the `do_something/0` implementation and
   thus will complain that `do_something/0` never returns.

With this change, if the NIF crashes on load and you need to debug, its easier
to get the function call out of the boot or initialization path so that there's
an IEx prompt. Even though the call still crashes, more options are available:

* Uploading new firmware over the network rather than replacing MicroSD cards
* Uploading (like via `sftp`) test shared libraries to `/data` and loading those
  instead. See `:code.delete/1` and `:code.purge/1` for unloading the NIF.
* Enabling more logging and sending it to a console port

One small side effect of delaying loading the NIF until use is that it might
reduce boot time slightly. Loading NIFs is generally pretty quick, but if boot
time is an issue, it's one less thing to see when profiling.

Hopefully this alternative way of loading NIFs will prove handy to you as well.
