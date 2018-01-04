---
title: "Using NIFs With Nerves"
date: 2017-12-23T12:48:08-08:00
author: Connor Rigby
draft: false
tags: ["nerves", "nif", "c"]
---
While working on a Nerves project, you will likely do most hard work in the
`host` environnment. This means you get to develop features quickly, and when
are ready, you simply deploy your known working firmware to your embedded
devices. This however can lead to a situation where the code runs really well
on your i7 powered beast computer, but when deployed on a less
powerful Raspberry Pi 0, for example. Nothing will be broken, but things are just
_too_ slow. There are a number of solutions to this problem and in this post,
I will walk you through a simplified real world example of one possible solution
of using an [Erlang NIF](http://erlang.org/doc/tutorial/nif.html) to speed
up one particular functionality.

<!--more-->

I would like to preface this by saying a NIF will not always be the solution for
you. The documentation explains this: "NIFs are most suitable for synchronous functions".
The other scary thing about NIFs is that

>>>
Since a NIF library is dynamically linked into the emulator process,
this is the fastest way of calling C-code from Erlang
(alongside port drivers).
Calling NIFs requires no context switches.
But it is also the least safe,
because a crash in a NIF brings the emulator down too.
>>>

To simplify - a segfault in the code you are calling will result
in the Erlang virtual machine crashing. This crash usually falls out of the scope
of the `let it crash` mantra. Nerves will reboot your device when this happens
by default.

Now lets get started with that example. Full disclaimer: This example might get
a little complex and long winded because I pulled it out of a real world project,
but I think it is simple enough to follow.

Say we want a data structure that does
something on in a repeating manor. So do _*something*_ every _*number*_ of _*units*_
starting on _*datetime*_ ending on _*datetime*_. It turns out generating a list
of events in this manor can be pretty taxing. Let's get started.

First we create a new Nerves app like normal:

```bash
mix nerves.new hello_calendar
```

Now in a real project we would likely want to store these `Calendar`s inside a
database of some sort. We won't cover that here, but if you're interested in that,
check out [this](http://embedded-elixir.com/post/2017-09-22-using-ecto-and-sqlite3-with-nerves/)
post.

Make a new file `lib/hello_calendar/calendar.ex`:

```elixir
defmodule HelloCalendar.Calendar do
  defstruct [:start_time, :end_time, :repeat, :time_unit, :calendar]
  @valid_time_units ["minutely", "hourly", "daily", "weekly", "monthly", "yearly"]
  @doc """
  Start a new calendar
  * start_time - DataTime struct
  * end_time - DateTime struct
  * repeat - integer number of repeats
  * time_unit - one of
    * "minutely"
    * "hourly"
    * "daily"
    * "weekly"
    * "monthly"
    * "yearly"
  """
  def new(%DateTime{} = start_time, %DateTime{} = end_time, repeat, time_unit)
  when time_unit in @valid_time_units do
    %__MODULE__{
      start_time: start_time,
      end_time: end_time,
      repeat: repeat,
      time_unit: time_unit
    }
    |> build_calendar()
  end
end
```

Now for the hard (ish) part: the `build_calendar/1` function. We want a list
of events to operate on.

```elixir
def build_calendar(%__MODULE__{} = calendar) do
  current_time_seconds = :os.system_time(:second)
  start_time_seconds = DateTime.to_unix(calendar.start_time, :seconds)
  end_time_seconds = DateTime.to_unix(calendar.end_time :seconds)
  repeat = calendar.repeat
  repeat_frequency_seconds = time_unit_to_seconds(calendar.time_unit)

  new_calendar =
    do_build_calendar(current_time_seconds,
                      start_time_seconds,
                      end_time_seconds,
                      repeat,
                      repeat_frequency_seconds)
                      |> Enum.map(&DateTime.from_unix!(&1))
  %{calendar | calendar: new_calendar}
end

# This function will be replaced with our NIF.
def do_build_calendar(now_seconds, start_time_seconds, end_time_seconds, repeat, repeat_frequency_seconds) do
  Logger.warn "Using (very) slow calendar builder!"
  grace_period_cutoff_seconds = now_seconds - 60
    Range.new(start_time_seconds, end_time_seconds)
    |> Enum.take_every(repeat * repeat_frequency_seconds)
    |> Enum.filter(&Kernel.>(&1, grace_period_cutoff_seconds))
    |> Enum.take(60)
    |> Enum.map(&Kernel.-(&1, div(&1, 60)))
end

@compile {:inline, [time_unit_to_seconds: 2]}
defp time_unit_to_seconds("never"), do: 0
defp time_unit_to_seconds("minutely"), do: 60
defp time_unit_to_seconds("hourly"), do: 60 * 60
defp time_unit_to_seconds("daily"), do: 60 * 60 * 24
defp time_unit_to_seconds("weekly"), do: 60 * 60 * 24 * 7
defp time_unit_to_seconds("monthly"), do: 60 * 60 * 24 * 30
defp time_unit_to_seconds("yearly"), do: 60 * 60 * 24 * 365
```

Now that was a mouthful, but we are mostly interested in `do_build_calendar/5`.
First we build a `grace_period` by subtracting one minute from `now`. Then we build a `Range`
from the `start_time` to the `end_time`, and take the number of steps. Then we
filter out every event that isn't after our grace period. Then we grab 60 of those
events, and round down to the nearest minute.

Now we can test it out:

```elixir
iex()> now = DateTime.utc_now()
iex()> start_time = %{now | minute: now.minute + 5}
iex()> end_time = %{now | hour: now.hour + 1}
iex()> HelloCalendar.Calendar.new(start_time, end_time, 1, "minutely")
14:10:03.864 [warn]  Using (very) slow calendar builder!
%HelloCalendar.Calendar{calendar: [#DateTime<2017-03-06 20:35:52Z>,
  #DateTime<2017-03-06 20:36:51Z>, ...],
 end_time: #DateTime<2017-12-23 27:10:02.653171Z>, repeat: 1,
 start_time: #DateTime<2017-12-23 22:10:02.653171Z>, time_unit: "minutely"}
```

And it was very quick. But now say you want `end_time` to be in 5 years...

```elixir
HelloCalendar.Calendar.new(start_time, %{end_time | year: end_time.year + 5}, 1, "minutely")
```

That takes signifigantly longer, because it still needs to enumerate over every
time before our `gracec_period` here: `|> Enum.filter(&Kernel.>(&1, grace_period_cutoff_seconds))`

So let's get into the fun NIF stuff.

First we need to setup our `make` environment. We add a dependency to the `mix.exs`:

```elixir
def project do
  [...
   compilers: [:elixir_make] ++ Mix.compilers(),
   make_clean: ["clean"],
   ...
  ]
end

def deps do
  [
    {:nerves, "~> 0.7", runtime: false},
    {:elixir_make, "~> 0.4.0"}
  ] ++ deps(@target)
end
```

and we will need a `Makefile`. This is the complex part with Nerves.

```Makefile
ifeq ($(ERTS_DIR),)
ERTS_DIR = $(shell erl -eval "io:format(\"~s/erts-~s~n\", [code:root_dir(), erlang:system_info(version)])" -s init stop -noshell)
ifeq ($(ERTS_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH or export ERTS_DIR)
endif
endif

ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

LDFLAGS += -fPIC -shared
CFLAGS ?= -fPIC -O2 -Wall -Wextra -Wno-unused-parameter

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup
endif
endif

NIF=priv/build_calendar.so

all: priv $(NIF)

priv:
	mkdir -p priv

$(NIF): c_src/build_calendar.c
	$(CC) $(ERL_CFLAGS) $(CFLAGS) $(ERL_LDFLAGS) $(LDFLAGS) \
	    -o $@ $<

clean:
	$(RM) $(NIF)
```

ERTS_DIR
ERL_EI_INCLUDE_DIR

Basically what that Makefile does is makes sure both the `ERTS_DIR` and
`ERL_EI_INCLUDE_DIR` environment variables are set, then included during
the compile. This will give us access to the `erl_nif.h` header we will see
later, and allows the compiler to properly link against it.

Now we can finally get to writing our C code! Lets reimplement that slow
`do_build_calendar` function. Create a new file `c_src/build_calendar.c`

```c
#include <stdlib.h>
#include <string.h>
#include <erl_nif.h>

static ERL_NIF_TERM do_build_calendar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  ERL_NIF_TERM atom_err = enif_make_atom(env, "error");
  ERL_NIF_TERM atom_not_implemented = enif_make_atom(env, "not_implemented");
  return enif_make_tuple(env, 2, atom_err, atom_not_implemented);
}

static ErlNifFunc nif_funcs[] =
{
    {"do_build_calendar", 5, do_build_calendar}
};

ERL_NIF_INIT(HelloCalendar.Calendar, nif_funcs, NULL,NULL,NULL,NULL)
```

Now, you can do either `mix compile` or `make` to generate your new NIF.
You should have a file called `make_calendar.so` in your `priv` directory. Lets
walk thru that file really quickly, starting from the bottom.

`ERL_NIF_INIT(Elixir.HelloCalendar.Calendar, nif_funcs, NULL,NULL,NULL,NULL)` Tells
the NIF what the module name is, the functions to be exported, and then there are
arguments for `on_load`, `on_reload`, `on_unload`, and `on_upgrade`. We won't be
using those today.

```c
static ErlNifFunc nif_funcs[] =
{
    {"do_build_calendar", 5, do_build_calendar}
};
```

This tells the NIF which functions and their arity to export.

```c
static ERL_NIF_TERM do_build_calendar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  ERL_NIF_TERM atom_err = enif_make_atom(env, "error");
  ERL_NIF_TERM atom_not_implemented = enif_make_atom(env, "not_implemented");
  return enif_make_tuple(env, atom_err, atom_not_implemented);
}
```

This is our actual function. The last part is to wire it up in Elixir. Open up
`lib/hello_calendar/calendar.ex` again and add this:

```elixir
  @on_load :load_nif
  def load_nif do
    nif_file = '#{:code.priv_dir(:hello_calendar)}/build_calendar'
    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> Logger.warn "Failed to load NIF: #{inspect reason}"
    end
  end
```

Now lets walk through that.
`@on_load :load_nif` is a compiler attribute that tells Elixir/Erlang to do something when
the module is loaded. In this case we want to load a NIF.
If the NIF loading fails, we want to fallback to the default implementation. This
is required in Nerves, since when running `mix firmware`, the Elixir compiler `load`s
your code, which will load the NIF.

Now if we run the `iex` tests from above:

```elixir
iex(1)> now = DateTime.utc_now()
#DateTime<2017-12-23 22:39:33.259057Z>

iex(2)> start_time = now
#DateTime<2017-12-23 22:39:33.259057Z>

iex(3)> end_time = %{start_time | hour: now.hour + 5, year: now.year + 1000}
#DateTime<3017-12-23 27:39:33.259057Z>

iex(4)> HelloCalendar.Calendar.new(start_time, %{end_time | year: end_time.year + 5}, 1, "minutely")
** (Protocol.UndefinedError) protocol Enumerable not implemented for {:error, :not_implemented}. This protocol is implemented for: Date.Range, File.Stream, Function, GenEvent.Stream, HashDict, HashSet, IO.Stream, List, Map, MapSet, Range, Stream
    (elixir) lib/enum.ex:1: Enumerable.impl_for!/1
    (elixir) lib/enum.ex:116: Enumerable.reduce/3
    (elixir) lib/enum.ex:1847: Enum.map/2
    (hello_calendar) lib/hello_calendar/calendar.ex:46: HelloCalendar.Calendar.build_calendar/1
```

Now we get `{:error, :not_implemented}` as a return from our `do_build_calendar`
function. Obviously this is an error, but it didn't use the old Elixir implementation.

Lets finish up the C version of that function:

```c
static ERL_NIF_TERM do_build_calendar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  // Arguments
  long int nowSeconds, startTimeSeconds, endTimeSeconds, frequencySeconds;
  int repeat;

  // Fetch arguments.
  enif_get_long(env, argv[0], &nowSeconds);
  enif_get_long(env, argv[1], &startTimeSeconds);
  enif_get_long(env, argv[2], &endTimeSeconds);
  enif_get_int(env, argv[3], &repeat);
  enif_get_long(env, argv[4], &frequencySeconds);

  // Data used to build the calendar.
  long int gracePeriodSeconds;
  gracePeriodSeconds = nowSeconds - 60;
  long int step = frequencySeconds * repeat;

  // iterators for loops
  long int i, j;

  // build our events array, fill it with zeroes.
  long int events[MAX_GENERATED];
  for(i = 0; i < MAX_GENERATED; i++)
    events[i] = 0;

  // put up to MAX_GENERATED events into the array
  for(j = 0, i = startTimeSeconds; (i < endTimeSeconds) && (j < MAX_GENERATED); i += step) {
    // if this event (i) is after the grace period, add it to the array.
    if(i > gracePeriodSeconds) {
      events[j] = i;
      events[j] -= (events[j] % 60);
      j++;
    }
  }

  // Count up our total generated events
  for(i=0, j=0; j<MAX_GENERATED; j++) { if(events[j] > 0) { i++; } }

  // Build the array to be returned.
  ERL_NIF_TERM retArr [i];
  for(j=0; j<i ; j++)
    retArr[j] = enif_make_long(env, events[j]);

  // we survived.
  return enif_make_list_from_array(env, retArr,  i);
}
```

Don't worry if you didn't catch all that. We'll go thru it.

```c
// Arguments
long int nowSeconds, startTimeSeconds, endTimeSeconds, frequencySeconds;
int repeat;

// Fetch arguments.
enif_get_long(env, argv[0], &nowSeconds);
enif_get_long(env, argv[1], &startTimeSeconds);
enif_get_long(env, argv[2], &endTimeSeconds);
enif_get_int(env, argv[3], &repeat);
enif_get_long(env, argv[4], &frequencySeconds);
```

`argv[]` is an array passed in as the arguments to our function.
We know the first 3 are `long`s so we use the `enif_get_long` function to get them.
`repeat` is an integer so we do `enif_get_int` to get it. Those functions pass
the address of the variables you wish to populate. (`&`).

```c
// Data used to build the calendar.
long int gracePeriodSeconds;
gracePeriodSeconds = nowSeconds - 60;
long int step = frequencySeconds * repeat;
```

Just building up some information we will need later.

```c
// Build our events array and fill it with zeroes.
long int events[MAX_GENERATED];
for(i = 0; i < MAX_GENERATED; i++)
  events[i] = 0;

// put up to MAX_GENERATED events into the array
for(j = 0, i = startTimeSeconds; (i < endTimeSeconds) && (j < MAX_GENERATED); i += step) {
  // if this event (i) is after the grace period, add it to the array.
  if(i > gracePeriodSeconds) {
    events[j] = i;
    events[j] -= (events[j] % 60);
    j++;
  }
}
```

Build an array, and fill it with zeroes, then populate it with up to `MAX_GENERATED`
events.

```c
// Count up our total generated events
for(i=0, j=0; j<MAX_GENERATED; j++) { if(events[j] > 0) { i++; } }

// Build the array to be returned.
ERL_NIF_TERM retArr [i];
for(j=0; j<i ; j++)
  retArr[j] = enif_make_long(env, events[j]);
```

build the `list` of items to return to Erlang/Elixir. and finally
`return enif_make_list_from_array(env, retArr,  i);`

Now if we run our examples again, they will be almost instant on our host machine.
You can deploy to a nerves device now, and it should be still quite fast.

```sh
MIX_TARGET=rpi0 mix do deps.get, firmware
```

You may notice a warning:
`14:52:29.876 [warn]  Failed to load nif: {:load_failed, 'Failed to load NIF library:
hello_calendar/_build/rpi0/dev/lib/hello_calendar/priv/build_calendar.so: wrong ELF class: ELFCLASS32\''}`

This is happening because the Elixir compiler is trying to load your Nerves
crosscompiled NIF. You can safely ignore or disable this message.

All the code for this project is on Github [here](https://github.com/ConnorRigby/hello_calendar)