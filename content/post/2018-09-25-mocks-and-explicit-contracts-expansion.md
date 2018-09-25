---
title: Mocks and Explicit Contracts in Nerves
date: 2018-09-25
author: Connor Rigby
draft: false
tags: ["nerves", "mock", "stub"]
---

If you are not super new to Elixir, you may have read [this blog
post](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/)
by José Valim. If you haven't read it, you may want to check it out. This post
references it frequently.

Nerves puts a lot of focus into spending as much time developing your
application on your host machine. This means you can rapidly develop your
application, write tests, etc. When you feel it is ready you can then burn your
firmware to a device and it will _just work_. This has an issue though.

<!--more-->

Sometimes your application may interact with something in the real world that
your development pc probably won't have access to. Enter: a mock. Elixir makes
this really easy to implement. You simply define a generic behaviour that an
implementation must follow. This allows your host machine to have a single
implementation that will _always_ work, not work at all, throw an exception,
etc.

## Case study: ElixirALE

José's post above had a small example on how one would
"mock" an external API. We can do the same thing, but for Nerves.

Imagine you want to do a simple task: turn a light on. An Elixir application
that can accomplish this is
[ElixirALE](https://github.com/fhunleth/elixir_ale).  It has a simple API.
Eventually you will do something like:

```elixir
# Start a GPIO GenServer
{:ok, pid} = ElixirAle.GPIO.start_link(18, :output)
# Turn the pin _ON_
:ok = GPIO.write(pid, 1)
```

And all is great. But you want to do your development on your PC right?  Well
the light isn't connected to your PC at all? One common practice as José points
out is to `mock` (the verb!) the GPIO GenServer.

```elixir
mock(ElixirAle.GPIO, :start_link, to_return: {:ok, pid})
mock(ElixirAle.GPIO, :write, to_return: :ok)
```

But there is a better way! Let's define a more usable way of setting this up.
What do you _really_ want to do? You don't specifically want to toggle pin 18,
you want to turn a light on. Lets write a `behaviour` for this.

```elixir
defmodule MyApp.Light do

  @opaque private :: term

  @doc "initialize the light"
  @callback init(opts :: Keyword.t()) :: {:ok, private} | :error

  @doc "Callback to turn the light on"
  @callback on(private) :: :ok | :error

  @doc "Callback to turn the light off"
  @callback off(private) :: :ok | :error

  use GenServer

  @args Application.get_env(:my_app, __MODULE__)

  def on(pid \\ __MODULE__) do
    GenServer.cast(pid, :on)
  end

  def off(pid \\ __MODULE__) do
    GenServer.cast(pid, :off)
  end

  def start_link(args \\ @args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    impl = Keyword.fetch!(args, :implementation)
    {:ok, priv} = impl.init(args)
    {:ok, %{impl: impl, priv: priv}}
  end

  def handle_cast(:on, state) do
    :ok = state.impl.on(state.priv)
  end

  def handle_cast(:off, state) do
    :ok = state.impl.off(state.priv)
  end
end
```

The `@callback` lines are the important things here. This defines a
`@behaviour` that new implementation can follow. Lets start with our
development host implementation that simply logs the changes to the console.

```elixir
defmodule MyApp.HostLightImpl do
  @behaviour MyApp.Light
  require Logger

  @impl MyApp.Light
  def init(_) do
    {:ok, :off}
  end

  @impl MyApp.Light
  def off(:off), do: :ok
  def off(:on) do
    Logger.debug "changing light from :on to :off"
    :ok
  end

  @impl MyApp.Light
  def on(:on), do: :ok
  def on(:off) do
    Logger.debug "changing light from :off to :on"
    :ok
  end
end
```

And _finally_, lets build the real implementation.

```elixir
defmodule MyApp.ElixirAleLightImpl do
  @behaviour MyApp.Light
  require Logger

  @impl MyApp.Light
  def init(args) do
    pin = Keyword.fetch!(args, :pin)
    {:ok, pid} = ElixirAle.GPIO.start_link(pin, :output)
    {:ok, %{pid: pid, pin: pin, state: :off}}
  end

  @impl MyApp.Light
  def off(%{state: :off}), do: :ok
  def off(:on) do
    Logger.debug "changing light from :on to :off"
    ElixirAle.GPIO.write(pid, 1)
  end

  @impl MyApp.Light
  def on(%{state: :on}), do: :ok
  def on(:off) do
    Logger.debug "changing light from :off to :on"
    ElixirAle.GPIO.write(pid, 0)
  end
end
```

## Conditional Implementation and Compilation

Now that there are two different implementations, you will need to decide
how/when each of them are compiled and used. Deciding which one to use can be
as simple as using `Mix.Config`.

```elixir
use Mix.Config

case Mix.Project.config()[:target] do
  "host" ->
    config :my_app, MyApp.Light, [
      implementation: MyApp.HostLightImpl
    ]
  "rpi0" ->
    config :my_app, MyApp.Light, [
      implementation: MyApp.ElixirAleLightImpl,
      pin: 18
    ]
end
```

The last thing you may have issues with is loading the dependency. In your
`mix.exs` file, you will probably have:

```elixir
def deps("host") do
  []
end

def deps(_target) do
  [
    {:elixir_ale, "~> 1.0"}
  ]
end
```

This means the `MyApp.ElixirAleLightImpl` module will give compiler warnings or
even errors when compiling on the `host` environment.  What I like to do to
solve this is create a directory called `platform` or similar in the root of my
`mix.exs` and tweak the `elixirc_paths` option.

```elixir
  def project() do
    [
      app: :my_app,
      target: @target
      # ...
      elixirc_paths: elixirc_paths(@target), # Add this line.
      # ...
    ]
  end

  def elixirc_paths("host"), do: ["lib", Path.join("platform", "host")]
  def elxiirc_paths(_target), do: ["lib", Path.join("platform", "target")]
```

Now you can store the `MyApp.ElixirAleLightImpl` file inside the
`platform/target` dir, and `MyApp.HostLightImpl` in the `platform/host` dir.

## Summing Up

You can keep your Nerves application concerns separated and clean by using
Elixir `@behaviour`s and explicit contracts. Something not discussed in depth
in the short post is testing with Nerves. This deserves a post all in it's own,
but mocks and contracts as described here is a huge part of writing tests for
Nerves devices.
