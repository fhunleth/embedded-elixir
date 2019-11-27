---
title: "🧙‍♀️Wizards & WiFi ‍🧙‍♂️"
subtitle: "Easily configure WiFi on devices"
date: 2019-11-22
author: Jon Carstens
draft: false
tags: ["nerves", "elixir", "networking"]
---

Introducing `VintageNetWizard` - Simple WiFi Configuration using a web browser

https://github.com/nerves-networking/vintage_net_wizard

<!--more-->

# VintageNet WiFi configuration wizard

![wizard](https://media.giphy.com/media/1AjULGLUb7LZZZhG3p/giphy.gif)

Well, not that kind of wizard..

​A simple library that makes it easier to configure WiFi networks on
devices without a screen or other access. It's based on the new Nerves
networking library,
[`vintage_net`](https://github.com/nerves-networking/vintage_net), which
drastically improves networking on Nerves devices. If you're interested in some
of the internals of networking, go checkout these sources on `vintage_net`¬

* [Embedded Networking article](https://embedded-elixir.com/post/2019-11-22-embedded-networking)
* [github](https://github.com/nerves-networking/vintage_net)

​When you include `:vintage_net_wizard` as a dep, it does not automatically
start the server or AP configurations on startup. When and why to start the
wizard varies from case to case and can be considered business logic so it was
decided not to handle it within the library. Because of that, you will need to
explicitly call the wizard run function somewhere in your code or IEx:

```elixir
VintageNetWizard.run_wizard()
```

​ Once started, a few things happen:

* The device WiFi is placed in `host` mode and starts networking as an Access
  Point (AP) that broadcasts an SSID
* The user joins their computer/phone to the AP
* Once joined, the user opens a web browser to `http://wifi.config` and the
  device delivers a web UI to go through configuration of any number of WiFi
  networks
    * You can also use the device hostname (i.e. `http://nerves-ce84.local`) or the IP
      address (`http://192.168.0.1`) in the browser as well
* User applies the configuration, the device attempts to connect to the networks
  specified.
* If successfully connects, device goes back into AP mode to report to the web
  that things are :ok_hand:
  * NOTE: This kills the AP network momentarily which means your machine will
    disconnect. Some machines are _very_ quick to rejoin a good network nearby
    so sometimes you may have to manually watch for the AP network to come back
    up and manually join it again.
* Once the web UI gets the OK, the user completes the setup in the UI, the
  device goes out of AP mode and reconnects to the network
* WiFi is now configured on your device! 🎉 🍻

## A note on _starting_ the wizard

As stated early, you must explicitly start the wizard, or add code to deduce
_when_ your app should start it. A common way might be checking if WiFi is
configured in your `application.ex` and start there if it is not.

```elixir
def maybe_enable_wizard() do
  configured = VintageNet.configured_interfaces()
  all = VintageNet.all_interfaces()

  with true <- "wlan0" in all,
       true <- "wlan0" not in configured,
  do
    VintageNetWizard.run_wizard()
  end
end
```

It is also suggested to implement a button hold starting the wizard as well.
Even without an actual button, you can use a jumper cable from 3.3v to the GPIO
pin for the same effect in a pinch. Take a look at an implementation
[here](https://github.com/nerves-networking/vintage_net_wizard/blob/master/example/lib/wizard_example/button.ex).

## How about an example?

Sure. 💥

![action](https://raw.githubusercontent.com/nerves-networking/vintage_net_wizard/master/assets/vintage_net_wizard.gif)

## How about a _real_ example?

Well, there are a few sources for this¬

* [`vintage_net_wizard/example`](https://github.com/nerves-networking/vintage_net_wizard/tree/master/example)
  that is part of the repo. You can set `MIX_TARGET` in there and build a
  firmware to test on a device quickly.
* [`NervesPack`](https://github.com/jjcarstens/nerves_pack) - a
  `nerves_init_gadget` replacement. By default, this will start a wizard if your
  device supports WiFi but has not been configured. It also starts a button
  monitor for forcing the wizard via long button press at anytime.
