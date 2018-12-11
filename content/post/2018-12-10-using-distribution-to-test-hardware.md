---
title: Using Erlang Distribution to test hardware
subtitle: Not just for distributed networks
date: 2018-12-10
author: Connor Rigby
draft: false
tags: ["nerves", "erlang", "distribution"]
---

Iterating quickly over code changes when working with new hardware can be
tricky. Nerves has built-in mechanisms that can be helpful, but what if there
were an even faster, more efficient way?

<!--more-->

## The problem

Imagine you are writing code that targets a specific piece of hardware. For
this basic example, lets assume you have a button attached to a pin on a Nerves
powered device.

You want to iterate quickly over your code. It's early days and you don't know
_exactly_ what your modules will look like. You know you need to turn the LED
on but are unsure of how to do this right now.

## Solution 1: The "intuitive" solution

This will be one way to accomplish what you are after. I will outline basic
steps below:

1) write code

2) `mix firmware`

3) `mix firmware.burn` or `mix firmware.push`

4) (only if used `firmware.burn`) insert SDCard + power

5) (only if used `firmware.push`) wait for reboot

6) test changes

7) back to step 1

### Pros to the "intuitive" solution

1. It is _relatively_ quick.

On my machine building + pushing firmware takes about 1.5 minutes all in all,
then waiting for boot is another minute or so depending on the complexity of
the application. Say 2 minutes to start to finish. Note this is the same for
one single character change, or an entire rewrite of your module/application.

2. It is simple.

This is about the easiest thing one could understand. Change code, push code,
reboot. No complexity added to code.

### Cons to the "intuitive" solution

1) it could be quicker.

2 minutes seems fast to push an update, until you are in a position where you
are doing tons of iteration. Waiting 2 minutes to test out a one line change is
a ton of time spent waiting. [Relevant XKCD Comic](https://xkcd.com/303/).

2) it's inefficient.

You only changed one line? why should you have to wait for an entire update
_AND_ a reboot for that?

## Solution 2: The "Raspbian" Solution

This is another common way to bootstrap an application or feature.  Basically,
you spin up a version of
[Raspbian](https://www.raspberrypi.org/downloads/raspbian/) or similar distro
on your device such as plain [Debian on Beagle based
boards](https://beagleboard.org/latest-images).  I'll outline the steps to this
one:

1) Install OS.

2) Connect to OS via ssh, keyboard+mouse, UART etc.

3) configure/update OS (one time only if you keep the SDCard handy).

4) get code onto OS.

5) edit code.

6) test code.

7) back to step 5.

### Pros of the "Raspbian" Solution

1) After initial setup it can be quick

After you've got your OS up and running and configured, iteration is pretty
fast, as long as you can make changes quickly.

2) It's good for testing hardware

A lot of sensors/hats/hardware has libraries that expect you to be using the
standard OS for your device. Libraries are often written in languages such as
Python, and may require porting to Elixir to work with Nerves easily. Testing
on the standard OS is a good way to test out hardware and check which
dependencies might be needed for Nerves.

### Cons of the "Raspbian" Solution

1) It's awkward to setup

Getting up and running can be easy, but bloated OS makes it take a long time,
you need to know OS tools to get connected.

2) It's awkward to use

Even after getting up and running, using this solution is hard.  You need to be
connected directly to the device, to write code and test it. Most of these
devices aren't quite powerful enough to run a web browser, or you aren't using
a desktop environment at all, so you need a way of reading docs on a different
machine, or loading them a different way. Copying examples from a web browser
is a no-go if not using SSH or UART. If using SSH or UART, you won't have a
visual text editor.

## Solution 3: The "Erlang" Solution

Since Nerves is built on top of Erlang and OTP, we have the ability to get the
best of both worlds. By design Erlang has the following built into the
language:

* Hot code reloading
* Remote code loading

This solves both of the issues with the "intuitive" solution. Code can be
reloaded in real time without pushing a new update, and without a reboot. Your
iteration is now only limited to how fast it can be tested.  I'll outline the
steps to this one:

1) build/push firmware. Same as steps 1-3 of the "Intuitive" solution.
   but it only needs to be done once.

2) Edit code.

3) load code.

4) test code.

5) back to step 2.

### Pros of the "Erlang" Solution

1) It's Instant

Code can be reloaded and tested as fast as you can type it. (well almost)
Reloading an OTP app takes about 3 seconds for my machine.

2) It keeps you on the "host" machine as much as possible

When implemented properly, you will be pressed to find a reason to actually
connect directly to your device to investigate things.

### Cons of the "Erlang" Solution

1) It's more complex than other solutions

This solution requires you to actively write code in a way that can work this
way. It's not that bad once you get the hang of it.

2) It's not compatible with all libraries.

Since it requires code to be written in a particular way, this solution has
some issues working with some libraries. This turns out to not really be a huge
problem in practice however.

3) It only works for Erlang/Elixir code.

This solution will not work for data that winds up in the `priv` directory,
such as C ports/nifs, eex templates, etc.

## Implementing the "Erlang" Solution

Implementing this solution isn't as simple as adding a dependency. It requires
you to write your code in a way that is compatible.  I'm assuming you already
have an application scaffolded with `mix nerves.new` and it already has
`nerves_init_gadget` configured and working properly.

Looking back at our problem, let's start with toggling an LED.

Add `{:elixir_ale, "~> 1.2"}` to your deps (not just your target deps), and
push firmware to your device.

Consulting the [gpio docs](https://hexdocs.pm/elixir_ale/ElixirALE.GPIO.html)
we can see that we need to call `GPIO.start_link/3` to start a GPIO connection,
but that will start a `pid` locally on your host machine if you try it. But
turns out Erlang has the solution built in:

```elixir
defmodule MyApp.LEDs do
  @moduledoc """
  Control some LEDs
  """

  alias ElixirALE.GPIO

  def toggle(pin, time) do
    {:ok, pid} = start_gpio(pin, :output)
    :ok = GPIO.write(pid, 1)
    Process.sleep(time)
    :ok = GPIO.write(pid, 0)
    GPIO.release(pid)
  end

  case Mix.Project.config()[:target] do
    "host" ->
      defp start_gpio(pin, direction, opts \\ []) do
        # :"my_app@nerves.local" is the node name of your Nerves
        # device. See `nerves_init_gadget` docs for more info.
        :rpc.call(:"my_app@nerves.local", GPIO, :start_link, [pin, direction, opts])
      end
    _ ->
      defp start_gpio(pin, direction, opts \\ []) do
        GPIO.start_link(pin, direction, opts)
      end
  end
end
```

and on our host machine if we try it out:

```sh
iex -S mix
MyApp.LEDs.toggle(16, 100)
** (MatchError) no match of right hand side value: {:badrpc, :nodedown}
    (remote_io) lib/mix/my_app/leds.ex:9: MyApp.LEDs.toggle/2
```

What happened? Well Our host machine isn't connected to our device, so we get
an error saying `:nodedown`. We will have to setup distribution on the `host`
machine only. In `application.ex` we should have a scaffolded function:

```elixir
  # ...
  def children("host") do
  # ...
```

Lets add something to that function:

```elixir
  def children("host") do
    {:ok, _} = Node.start(:host_machine)
    # This cookie can be found in `rel/vm.args`
    Node.set_cookie(:lyclzfysmqcpj5xwxwqnlkvvlda2ukrbswalcfqm45jgikhza65xzechthr7qd7r)
    true = Node.connect(:"my_app@nerves.local")
    []
  end
```

This starts distribution and should connect to your device. Now on your host
machine try it again:

```sh
iex -S mix
Erlang/OTP 21 [erts-10.0.4] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

Interactive Elixir (1.7.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(host_machine@hostname.lan)1> MyApp.LEDs.toggle(13, 1000)
:ok
```

You should see your led turn on and back off a second later. And the best part?
You didn't need to do any firmware building, burning or pushing. Want to try it
again with a different amount of time? Just change the file, `recompile` and
try again.

So now your LED flashes for exactly how long you want, and you're ready to push
it out? Well you _could_ build firmware and push it, but we can do this a bit
faster.

Create a new file in your project called `lib/mix/tasks/firmware.reload.ex`

```elixir
defmodule Mix.Tasks.Firmware.Reload do
  use Mix.Task

  def run(_) do
    node_name = :"my_app@nerves.local"
    {:ok, _} = Node.start(:host_machine)
    # This cookie can be found in `rel/vm.args`
    Node.set_cookie(:lyclzfysmqcpj5xwxwqnlkvvlda2ukrbswalcfqm45jgikhza65xzechthr7qd7r)
    true = Node.connect(node_name)
    Application.load(:my_app)
    {:ok, my_app_mods} = :application.get_key(:my_app, :modules)
    for module <- my_app_mods do
      {:ok, [{^node_name, :loaded, ^module}]} = IEx.Helpers.nl([node_name], module)
    end
  end
end
```

This will reload your module in real time, and allow you to test it on the
device without need for a reboot.

# Conclusion

There is not always exactly one solution for iterating code on real hardware.
Erlang's built in mechanisms can allow us to iterate over code in a quick and
easy way in many circumstances. I've recently adopted this method and along
with proper [mocking and
contracts](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)
it has proved to be an incredibly valuable tool for writing Nerves applications
quickly and efficiently.
