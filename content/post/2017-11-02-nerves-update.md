---
title: The Nerves Update
#subtitle:
date: 2017-11-02
author: Frank Hunleth
draft: false
tags: ["nerves", "update"]
---

Wondering what's happening on the Nerves project? You're not alone. We're planning semi-regular updates so that you don't need to lurk on the [elixir-lang Slack][elixir-lang slack]'s #nerves and #nerves-dev channels all the time.

Before the updates, I'd like to thank our [Open Collective backers][oc-nerves], [Le Tote][Le Tote] and [FarmBot][FarmBot], since they're majorly helping all of us make this project sustainable for the long term.

Alright, here are the highlights:
<!--more-->

1. We integrated a Buildroot update that addressed the [KRACK][KRACK] and a few other security vulnerabilities into [nerves_system_br v0.14.1][nerves_system_br] and released updates to the official systems.
1. Connor Rigby has been busy cleaning up [nerves_network][nerves_network] and associated projects for 1.0. We know that networking support has been rough for a few use cases and we're working on addressing this.
1. Connor also has a [linter][nerves_system_linter] for those of you creating custom Nerves systems. We'll be adding to it with the goal of catching subtle kernel and Linux package configurations that don't work.
1. Console resizing works on the Raspberry Pi Zero. The fix (currently in [nbtty][nbtty]) is portable to other platforms. More importantly, nbtty also fixes a nasty hang issue on platforms using the gadget USB port for the IEx console.
1. The Beaglebone port, [nerves_system_bbb][nerves_system_bbb] now supports the [PocketBeagle][PocketBeagle].
1. Initial support for the [Raspberry Pi Compute Module 3][cm3] has been added to [nerves_system_rpi3][nerves_system_rpi3]. Advanced support for USB gadget mode and running off eMMC Flash is not available yet.
1. The [GrovePi][grovepi] project now supports servo control using the PivotPi.
1. Some corporate sponsorship has enabled work on integrating Chromium into a Nerves system. This will replace the current kiosk webbrowser solution that uses qtwebkitkiosk which can be found at [kiosk_system_rpi3][kiosk_system_rpi3].
1. Corporate sponsorship is also enabling support for platforms with raw NAND flash in [fwup][fwup]. This is relevent to Nerves use on very high volume devices.

Community initiatives:

1. Mikel Cranfill has created a [pru][pru] package to support the PRU microcontrollers found on the Beaglebone and similar boards. These are super useful for handling hard real-time tasks in embedded systems and we hope it will make them more accessible.
1. Bluetooth support (specificially BLE support) has been a regular request for integration in Nerves. Several people have made custom systems with BlueZ installed or attached BLE modules (like Adafruit Bluefruit modules) via [nerves_uart][nerves_uart], but nothing has been integrated with an easy-to-use Hex package yet. Watch [this issue][ble-issue] if you're interested in this.

Upcoming Nerves talks and training:

[Elixir with Love][ElixirWithLove] - Providence, RI, November 10, 2017

* Functional Full-Stack Systems with Elixir, Phoenix, Nerves, and Elm - Greg Mefford

[ElixirConfMX 2017][ElixirConfMX] - Mexico City, November 18, 2017

* Keynote - Justin Schneck
* Nerves Training - Ricardo Echavarría

[Lonestar ElixirConf][Lonestar] - Austin, TX, February 22-24, 2018

* Keynote - Tim Mecklem
* Nerves Training - Greg Mefford

[ElixirConfEU 2018][ElixirConfEU] - Warsaw, April 18th, 2018

* Nerves Training - Frank Hunleth

Lastly, if I've missed anything, please let me know either here or on the [elixir-lang Slack][elixir-lang slack].

[ble-issue]: https://github.com/nerves-project/nerves/issues/210
[cm3]: https://www.raspberrypi.org/products/compute-module-3/
[elixir-lang slack]: https://elixir-slackin.herokuapp.com/
[ElixirConfEU]: http://www.elixirconf.eu/
[ElixirConfMX]: http://elixirconf.mx
[ElixirWithLove]: https://www.elixir-with-love.com/
[FarmBot]: https://farmbot.io/
[fwup]: https://github.com/fhunleth/fwup
[grovepi]: https://github.com/adkron/grovepi
[kiosk_system_rpi3]: https://github.com/LeToteTeam/kiosk_system_rpi3
[KRACK]: https://www.krackattacks.com/
[Le Tote]: https://www.letote.com
[Lonestar]: http://lonestarelixir.com/
[nbtty]: https://github.com/fhunleth/nbtty/
[nerves_network]: https://github.com/nerves-project/nerves_network/
[nerves_system_bbb]: https://github.com/nerves-project/nerves_system_bbb/
[nerves_system_linter]: https://github.com/nerves-project/nerves_system_linter
[nerves_system_rpi3]: https://github.com/nerves-project/nerves_system_rpi3/
[nerves_system_br]: https://github.com/nerves-project/nerves_system_br/
[nerves_uart]: https://github.com/nerves-project/nerves_uart/
[oc-nerves]: https://opencollective.com/nerves-project/
[PocketBeagle]: http://beagleboard.org/pocket/
[pru]: https://github.com/nuclearcanary/pru
