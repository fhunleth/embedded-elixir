---
title: January 2018 Nerves Update
#subtitle:
date: 2018-01-02
author: Frank Hunleth
draft: false
tags: ["nerves", "update"]
---

Happy New Year from the Nerves team!

We're marching ahead with our 1.0 plans and methodically going through our
constituent projects to get them across the "finish" line. Work priorities have
forced some Nerves development on tangents, but some of those may be of interest
as well. Here's a summary of what's been happening:

<!--more-->

1. [nerves_uart][nerves_uart] graduated to 1.0! If you're working with serial
   ports, you may have encountered this project. The Nerves part of the name is
   often misunderstood. We use it a lot on Nerves devices, but it runs on
   Windows, Mac, and Linux too. If you're working with serial ports, don't
   forget that you can develop on your laptop too!
1. Tim Mecklem and Michael Schmidt have been busy making Windows support better.
   Tim posted a [video][nerves_on_windows] and we hope to update the docs to
   make things easier on Windows users.
1. Connor Rigby's [linter][nerves_system_linter] is now live in almost all of
   our officially-supported systems. We recommend including it in your custom
   systems to catch subtle assumptions that Elixir and Nerves have with the
   Buildroot and Linux configurations. If you've run into a custom system
   issue, let us know about it - maybe we can help others avoid it using the
   linter.
1. We've been busy making it easier to revert software images loaded on devices.
   While this has always been possible with our A/B partition setup, it isn't
   obvious how to use it. [nerves_runtime][nerves_runtime] now has a helper
   function for reverting to the previous good firmware. It relies on updates to
   the official systems that haven't been released yet, but they're coming soon.
1. While not a Nerves feature that we worked on, we recently merged in Erlang
   20.2.1 to [nerves_system_br][nerves_system_br]. This brings in support in
   Erlang's `ssh` application for using ssh-agent. If you use
   [nerves_firmware_ssh][nerves_firmware_ssh] or anything ssh-related on your
   devices and password protect your ssh private keys, this will be
   life-changing. Thank you OTP team!
1. Work has progressed on the Chromium integration in LeTote's
   [kiosk_system_rpi3][kiosk_system_rpi3] and
   [kiosk_system_x86_64][kiosk_system_x86_64] projects. Users comfortable with
   custom Nerves systems who have very fast Linux machines may want to try it
   out. This provides an alternative to the somewhat limited WebKit-based
   browser.
1. [Smartrent][Smartrent] has promised sponsorship of an open source pull-based
   firmware update server. This will fill a big gap in the Nerves ecosystem, so
   we're quite excited about it.
1. Our hardware-based regression test setup is progressing. I had hoped to have
   pictures of it in operation right now, but it's not ready yet. It's sooo
   close, though.

Community initiatives:

We continue to hear about interesting projects and posts around our community.
Here are a few:

1. Steven Fuchs wrote a great [blog post][steven_fuchs_0_11] on setting up a
   Nerves device that includes Phoenix and some Python.
1. Garry Hill has an [open source multi-room audio project][garry_hill_audio]
   that looks awesome
1. Derek Kraan is making good progress with an Elixir-based [Z-wave serial API
   stack][dkraan_zwave] for controlling devices in his home
1. If you're into home automation and using WeMo, check out Chris Coté's new
   [ex_wemo][ex_wemo] library.
1. Tim Gilbert described how he was able to [collect logs from a Nerves
   device with Papertrail][tim_gilbert_papertrail].
1. Michał Kalbarczyk showed how he used Nerves with a Raspberry Pi to [control
   an LED matrix display][brewing_firmware].

Upcoming Nerves talks and training:

[CodeMash][codemash] - Sandusky, Ohio, January 9-12, 2018

* Building an Artificial Pancreas - Tim Mecklem

[Lonestar ElixirConf][Lonestar] - Austin, TX, February 22-24, 2018

* Keynote - Tim Mecklem
* Customize your Car: An Adventure in Using Elixir and Nerves to Hack Your
  Vehicle's Electronics Network - Brian Wankel
* Nerves Training w/ Greg Mefford - Come build your own Nerves-based,
  WiFi-enabled camera based on the Raspberry Pi Zero W. There's still space left,
  but registration will close around the end of January, so don't delay if you're
  planning to sign up!

[ElixirConfEU 2018][ElixirConfEU] - Warsaw, April 18th, 2018

* Nerves Training w/ Frank Hunleth - I've created a new project for this one-day
  training class that includes the best parts of the popular ElixirConf 2017
  training in Seattle.

As always, if I've missed anything, please let me know either here or on the
[elixir-lang Slack][elixir-lang slack].

Lastly, please don't forget our [Open Collective backers][oc-nerves] and
corporate sponsors [Le Tote][Le Tote], [Smartrent][Smartrent], and
[FarmBot][FarmBot]. They're majorly helping all of us make this project
sustainable for the long term.

[nerves_uart]: https://github.com/nerves-project/nerves_uart/
[nerves_on_windows]: https://www.youtube.com/watch?v=rzV0qfhzzqc&feature=youtu.be&a=
[nerves_system_linter]: https://github.com/nerves-project/nerves_system_linter
[nerves_runtime]: https://github.com/nerves-project/nerves_runtime/
[nerves_system_br]: https://github.com/nerves-project/nerves_system_br/
[nerves_firmware_ssh]: https://github.com/nerves-project/nerves_firmware_ssh/
[kiosk_system_rpi3]: https://github.com/LeToteTeam/kiosk_system_rpi3
[kiosk_system_x86_64]: https://github.com/LeToteTeam/kiosk_system_x86_64
[Smartrent]: https://smartrent.com/
[steven_fuchs_0_11]: http://nerves.build/posts/nerves-0-11
[garry_hill_audio]: http://strobe.audio/
[dkraan_zwave]: https://github.com/derekkraan/domolixir
[FarmBot]: https://farmbot.io/
[Le Tote]: https://www.letote.com
[elixir-lang slack]: https://elixir-slackin.herokuapp.com/
[ElixirConfEU]: http://www.elixirconf.eu/
[Lonestar]: http://lonestarelixir.com/
[ex_wemo]: https://github.com/NationalAssociationOfRealtors/ex_wemo
[oc-nerves]: https://opencollective.com/nerves-project/
[tim_gilbert_papertrail]: https://timgilbert.wordpress.com/2017/12/31/logging-from-headless-nerves-machines-to-papertrail/
[brewing_firmware]: https://blog.fazibear.me/brewing-the-firmware-for-raspberry-pi-with-elixir-and-nerves-5dd67970d073
[codemash]: http://www.codemash.org/sessions?id=6796
