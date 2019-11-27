---
title: "Embedded Networking"
subtitle: "Networking like the good'ol days"
date: 2019-11-22
author: Jon Carstens
draft: false
tags: ["nerves", "elixir", "networking"]
---

Introducing `VintageNet` - a new networking library for embedded Elixir devices,
specially designed for Nerves 💙💻📶

https://github.com/nerves-networking/vintage_net

<!--more-->

# Why?

Good question.

Truth be told, I wasn't directly involved in the struggles of `nerves_network`
or building `vintage_net`, but am on the advocating end. So I think this can be
better explained from this blurb in the `vintage_net` README.md by those who
built it:

> `VintageNet` takes a different approach to networking from `nerves_network`.
> It supports calling "old school" Linux utilities like `ifup` and `ifdown` to
> configure networks. While this has many limitations, it can be a timesaver for
> migrating a known working Linux setup to Nerves. After that you can change the
> setup to call the `ip` command directly and supervise the daemons that you may
> need with [MuonTrap](https://github.com/fhunleth/muontrap). And from there you
> can replace C implementations with Elixir and Erlang ones if you desire.
>
> Another important difference is that `VintageNet` doesn't attempt to make
> incremental modifications to configurations. It completely tears down an
> interface's connection and then brings up new configurations in a fresh state.
> Network reconfiguration is assumed to be an infrequent event so while this can
> cause a hiccup in the network connectivity, it removes state machine code that
> made `nerves_network` hard to maintain.

noice.

Also, it is technically more directed towards Nerves, but extensible for running
in other environments if needed. If you're looking to go down that path, check
out the [system
requirements](https://github.com/nerves-networking/vintage_net#system-requirements)
for what you need to get running.

Depending on who you talk to, the answer to _why?_ could really get in depth. If
that tickles your fancy, then feel free to reach out for more discussion in the
[#nerves slack channel](https://elixir-lang.slack.com/messages/C0AB4A879/) or
Elixir forum. However, for this article I want to focus on some of the new
hotness that makes it a great library to use for your embedded networking.

# The Bells & Whistles

Mm, yes. The good stuff.

This isn't going to be an exhaustive list but will hopefully shed light on being
able to do more than connect to a WiFi network. I've broken it down to a few
sections and linked below so you don't have to take it all in at once:

* [Extensible](#extensible)
* [Runtime Configuration](#runtime-Configuration)
* [Persisted](#persisted)
* [Access-Point Mode Support](#access-point-mode-support)
* [Network Event Subscriptions](#network-event-subscriptions)
* [Multi-interface Prioritization](#multi-interface-prioritization)
* [WiFi Network Prioritization](#wifi-network-prioritization)
* [Bonus - Nerves Pack](#bonus-nerves-pack)

🍻

## Extensible

As stated earlier, `vintage_net` is based on "old school" linux utilities and
designed so that you can replace most of those utilities with your own should
you so desire. Have your own implementation of `ip`? Use it. Have a different
`ifup`/`ifdown` requirement?  Ya, you can change that out. You wrote a custom
Unix domain socket for C to Elixir communication? Drop it in!

In fact, you can also even change what host that is pinged to check that
internet is actually up which is useful if, say, you only consider network "up"
if it can talk to your special server because the rest of the internet is dead
to you.

If this is your jam, check out the
[Configuration](https://hexdocs.pm/vintage_net/readme.html#configuration)
documentation.

`VintageNet` is also setup to support multiple technologies like `WiFi`,
`Ethernet`, and `USB Gadget` right out of the box. And if you need to support a
new interface, you can implement the `VintageNet.Technology` behaviour and drop
it right in with the rest.  Check out the [`VintageNet.Technology`
documentation](https://hexdocs.pm/vintage_net/VintageNet.Technology.html#content)
for more info.

## Runtime Configuration

If you tried this with `nerves_network`, then this might bring tears of joy to
your eyes. _(hint: it was painful)_

`VintageNet` still supports compile time configuration, but in some cases one
may not _want_ to store sensitive values in a config. For example, WiFi
credentials probably don't need to be stored in the clear. Or say you're
deploying to 1000 different devices that all connecting to different networks.
You may not want to store all 1000 network credentials in the config on _every_
device.

So, runtime it is!

Example:

```elixir
config = %{
  ipv4: %{method: :dhcp},
  type: VintageNet.Technology.WiFi,
  wifi: %{
    networks: [
      %{key_mgmt: :wpa_psk, ssid: "sesame", psk: "open-sesame!"}
    ]
  }
}

VintageNet.configure("wlan0", config)
:ok
```

👏 dust your hands off, cause that's it.

One big thing to note here is that configuration is a *total replacement* and
doesn't add to existing configuration. The code above is the final config
result. If you need to _add_ to your config, simply fetch it first, add your
network, then apply:

```elixir
new_network = %{key_mgmt: :wpa_psk, ssid: "bullpen", psk: "peralta-ultimate-human-slash-genius"}
config = VintageNet.get_configuration("wlan0")
         |> update_in([:wifi, :networks], & [new_network | &1])

VintageNet.configure("wlan0", config)
```

See [Network Interface
Configuration](https://hexdocs.pm/vintage_net/readme.html#network-interface-configuration)
for more deets.

## Persisted

Simply put, when you configure network settings, they are persisted to disk. So
add that WiFi network with the stupid long password _one time_, then
_"fuggedaboutit"_.

This is especially useful during firmware updates so that you still have the
network configured after updating the code. On start, `VintageNet` also reads
the persisted configuration so you could pass around this configured file with
encrypted PSK so its there when needed, like during manufacturing.

Or, you can disable it entirely to prevent persistence cause you don't need it.
`VintageNet` has your back.

[Persistence docs](https://hexdocs.pm/vintage_net/readme.html#persistence) is the place
to be for this.

## Access-Point Mode Support

Sometimes you may want a device to broadcast a network instead of connect to a
network, or in other words, turn it into and Access Point. Well `VintageNet` has
you covered!  There is a bit of configuration, but it would look something like
this:

```elixir
ap_config =
  %{
    dhcpd: %{
      end: {192, 168, 0, 254},
      max_leases: 235,
      options: %{
        dns: [{192, 168, 0, 1}],
        domain: "nerves.local",
        router: [{192, 168, 0, 1}],
        search: ["nerves.local"],
        subnet: {255, 255, 255, 0}
      },
      start: {192, 168, 0, 20}
    },
    dnsd: %{records: [{"nerves.local", {192, 168, 0, 1}}]},
    ipv4: %{address: {192, 168, 0, 1}, method: :static, prefix_length: 24},
    type: VintageNet.Technology.WiFi,
    wifi: %{networks: [%{key_mgmt: :none, mode: :ap, ssid: "connect-to-me!"}]}
  }

VintageNet.configure("wlan0", ap_config)
```

There's a lot there, but the break down is device gets configured with
`mode: :ap`, sets a static IP of `192.168.0.1`, sets up DHCP so it can give
out IP's, and uses `dnsd` so that hostname can resolve to the static IP.

This specific example is used with
[`VintageNetWizard`](https://github.com/nerves-networking/vintage_net_wizard)
which is a tool for using your a web page to configure networks on your device.
Check out the repo or our other write up -> [Wizards &
WiFi](https://embedded-elixir/posts/2019-11-22-wizards-and-wifi)

But using as a setup wizard is not the only use case. I, for example, will use
it frequently on the go so I can still connect to a device when no cable or
joint network is available.

## Network Event Subscriptions

This is really cool 😎

`VintageNet` keeps a key/value store of network information that can be queried
at any time. So say you want to know what the state of your ethernet connection
is? easy

```elixir
iex)> VintageNet.get(["interface", "eth0", "connection"])
:internet
```

Or maybe your device is in [AP mode](#access-point-mode-support) and you want to
see what clients are connect? Done

```elixir
iex)> VintageNet.get(["interface", "wlan0", "wifi", "clients"])
["8c:86:1e:b6:e5:ba"]
```

Not only can you fetch, but you can also subscribe to the properties to get
notified when they happen. Continuing with this example, what if I want to do
some action only when a _specific_ client connects? Well a simple GenServer
'ought to do the trick ¬

```elixir
defmodule MyApp do
  use GenServer

  @subscription ["interface", "wlan0", "wifi", "clients"]
  @special_client "8c:86:1e:b6:e5:ba"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    VintageNet.get(@subscription)
    {:ok, %{}}
  end

  def handle_info({VintageNet, @subscription, left, joined, %{}}, state) do
    cond do
      @special_client in joined ->
        # client joined. Sing and dance! or something else...
      @special_client in left ->
        # the client left the network, tell someone?
      true ->
        # not special so do whatever
    end
  end
end
```

Or maybe you want to perform actions when connections go up or down. In any
case, [Properties](https://hexdocs.pm/vintage_net/readme.html#properties) is
where you want to look for more ideas.

## Multi-interface Prioritization

## WiFi Network Prioritization

Not only does `VintageNet` allow you to configure multiple networks at once, but
you can set priorities for them which is helpful when you might be in an area
with multiple networks available, but you prefer network A over the others. Or
you prefer the 5 Ghz network over 2.4 Ghz, etc etc. An example might look like¬

```elixir
config = %{
  ipv4: %{method: :dhcp},
  type: VintageNet.Technology.WiFi,
  wifi: %{
    networks: [
      %{key_mgmt: :wpa_psk, ssid: "sesame", psk: "open-sesame!", priority: 90},
      %{key_mgmt: :wpa_psk, ssid: "bullpen", psk: "peralta-ultimate-human-slash-genius", priority: 100}
    ]
  }
}

VintageNet.configure("wlan0", config)
```

**Note**: If you're not familiar with `wpa_supplicant` priority values, the
_higher_ value is _higher_ priority (vs a ranking system where 1 == highest)

## Bonus - Nerves Pack

A common desire practice in Nerves and the embedded Elixir space is to try to
keep pieces modular because not every case needs every piece. It allows you to
pull in only what you need and keep firmware images small. `VintageNet` is no
different here and to get a fully working user-end setup (SSH, mDNS, wifi wizard
configuration, etc) might require more pieces. For the more advance use, ndb.
For new to Nerves/Embedded, it could be a hurdle.

In the past, this was aided with `nerves_init_gadget` which was a compilation of
all the _typical_ pieces needed to make a firmware, install, and get to an iex
prompt within a few minutes. However, `VintageNet` is totally incompatible with
`nerves_init_gadget` ...  so I created a new one called `NervesPack`! 🎉

By adding `nerves_pack` as a dependency, you'll get all these benefits plus
pre-configured SSH, SFTP, mDNS, and all supported interfaces for your device
will automatically be configured at runtime.

Checkout the [`NervesPack` repo](https://github.com/jjcarstens/nerves_pack) for
more info.
