---
title: Reverting firmware updates
#subtitle:
date: 2018-01-08
author: Frank Hunleth
draft: false
tags: ["nerves", "fwup", "revert"]
---

Deployed a firmware image that doesn't quite work? Made a mistake in development
and don't want to remove and reprogram the MicroSD card to go back? No problem.
If the previous firmware image worked fine, then just revert back to it.

This is one of those features that has been possible since the beginning of the
Nerves project, but we didn't make it easy. That's changing.

<!--more-->

Let's go through a simple example. Imagine that you've created a trival
application that uses [nerves_init_gadget][nerves_init_gadget] and loaded on a
Raspberry Pi Zero. It doesn't do anything, but you can connect to its IEx prompt
via a virtual serial port and upload firmware. Here's a list of its metadata:

```elixir
iex> Nerves.Runtime.KV.get_all
%{
  "a.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "a.nerves_fw_application_part0_fstype" => "ext4",
  "a.nerves_fw_application_part0_target" => "/root",
  "a.nerves_fw_architecture" => "arm",
  "a.nerves_fw_author" => "The Nerves Team",
  "a.nerves_fw_description" => "",
  "a.nerves_fw_misc" => "",
  "a.nerves_fw_platform" => "rpi0",
  "a.nerves_fw_product" => "starter",
  "a.nerves_fw_vcs_identifier" => "",
  "a.nerves_fw_version" => "0.1.0",
  "nerves_fw_active" => "a",
  "nerves_fw_devpath" => "/dev/mmcblk0"
}
```

You can see information about the currently running firmware and that the active
firmware slot (`nerves_fw_active`) is the "a" slot. Nerves has two slots for
firmware images, so let's upload a new firmware image (version 0.1.1) to the RPi
Zero and reboot. If you're new to Nerves, check out the `nerves_init_gadget` and
[Nerves Getting Started][gettingstarted] docs for how to do this. Once the board
reboots, you can inspect the firmware metadata updates:

```elixir
iex> Nerves.Runtime.KV.get_all
%{
  "a.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "a.nerves_fw_application_part0_fstype" => "ext4",
  "a.nerves_fw_application_part0_target" => "/root",
  "a.nerves_fw_architecture" => "arm",
  "a.nerves_fw_author" => "The Nerves Team",
  "a.nerves_fw_description" => "",
  "a.nerves_fw_misc" => "",
  "a.nerves_fw_platform" => "rpi0",
  "a.nerves_fw_product" => "starter",
  "a.nerves_fw_vcs_identifier" => "",
  "a.nerves_fw_version" => "0.1.0",
  "b.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "b.nerves_fw_application_part0_fstype" => "ext4",
  "b.nerves_fw_application_part0_target" => "/root",
  "b.nerves_fw_architecture" => "arm",
  "b.nerves_fw_author" => "The Nerves Team",
  "b.nerves_fw_description" => "",
  "b.nerves_fw_misc" => "",
  "b.nerves_fw_platform" => "rpi0",
  "b.nerves_fw_product" => "starter",
  "b.nerves_fw_vcs_identifier" => "",
  "b.nerves_fw_version" => "0.1.1",
  "nerves_fw_active" => "b",
  "nerves_fw_devpath" => "/dev/mmcblk0"
}
```

The important line above is that `nerves_fw_active` is now pointing to slot "b".
If you've uploaded firmware to Nerves devices using `nerves_firmware_ssh`,
you'll have seen this since it tells you which slot it updates. The other
important piece of information is that `b.nerves_fw_version` is indeed "0.1.1"
so you know it's the new firmware.

Imagine now that something is wrong with this firmware and you want to go back
to "0.1.0". Just run this:

```elixir
iex> Nerves.Runtime.revert
```

The Raspberry Pi Zero will reboot. When it comes up again, we can inspect the
firmware metadata to see what happened:

```elixir
iex> Nerves.Runtime.KV.get_all
%{
  "a.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "a.nerves_fw_application_part0_fstype" => "ext4",
  "a.nerves_fw_application_part0_target" => "/root",
  "a.nerves_fw_architecture" => "arm",
  "a.nerves_fw_author" => "The Nerves Team",
  "a.nerves_fw_description" => "",
  "a.nerves_fw_misc" => "",
  "a.nerves_fw_platform" => "rpi0",
  "a.nerves_fw_product" => "starter",
  "a.nerves_fw_vcs_identifier" => "",
  "a.nerves_fw_version" => "0.1.0",
  "b.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "b.nerves_fw_application_part0_fstype" => "ext4",
  "b.nerves_fw_application_part0_target" => "/root",
  "b.nerves_fw_architecture" => "arm",
  "b.nerves_fw_author" => "The Nerves Team",
  "b.nerves_fw_description" => "",
  "b.nerves_fw_misc" => "",
  "b.nerves_fw_platform" => "rpi0",
  "b.nerves_fw_product" => "starter",
  "b.nerves_fw_vcs_identifier" => "",
  "b.nerves_fw_version" => "0.1.1",
  "nerves_fw_active" => "a",
  "nerves_fw_devpath" => "/dev/mmcblk0"
}
```

As you can see, the `nerves_fw_active` is back to "a" again. You can also revert
your revert to go back to the "b" slot again if you'd like.

There are some limitations:

1. Once you start uploading new firmware to a slot, that slot can't be reverted
   to. This comes up when a firmware update fails part way so the slot is in a
   half-written state.
1. The call to `revert` is manual. You can automate this in your application.
   For example, if some self-checks fail, you could force a revert. Be sure to
   think through your logic especially if any failures are transient.
1. You can't revert if the Erlang VM crashes or something horrible goes wrong
   with loading `Nerves.Runtime`.

That final limitation is an interesting one that can be overcome with some work.
Unfortunately, it's platform-specific. The general idea is that newly uploaded
firmware is in a provisional state. After it boots, it must do something to
confirm that it is "good". For example, it could attempt to contact a firmware
update server. The idea is that if it can contact the update server, then it's
at least good enough to take a patch should anything else be wrong. If the
firmware image doesn't determine that it's "good", then the next reboot reverts
back to the old image.

If you're interested in implementing this automatic failback feature on your
devices, check if your device runs the [U-Boot][u-boot] bootloader or another
script-able bootloader. If it does, then the "if" statement that decides which
firmware slot to boot can be placed in there. If you don't have U-Boot (i.e.
you're using a Raspberry Pi), you can implement a less robust solution, but one
that may be sufficient for your use case. The idea is to call
`Nerves.Runtime.revert` as soon as possible in your code, but tell it not to
reboot the device. Then do whatever initialization, etc. that you need to tell
that the device is in good shape. If the device reboots at any point, it will
boot the old firmware. When your firmware determines that it's ok, "revert"
again to lock in the new firmware.

There are even more ways to ensure that your device can protect against buggy
firmware. As you'd expect, this topic has quite a bit of depth that isn't
covered here. Nonetheless, Nerves can support many of these strategies since so
many lowlevel details can be tweaked. If you need to implement something more
exotic and don't know where to look, post a question to the [elixir-lang
Slack][elixir-lang slack]. It's possible that someone has a custom Nerves system
(possibly not public) that implements it.

[u-boot]: https://www.denx.de/wiki/U-Boot
[elixir-lang slack]: https://elixir-slackin.herokuapp.com/
[nerves_init_gadget]: https://github.com/nerves-project/nerves_init_gadget
[gettingstarted]: https://hexdocs.pm/nerves/getting-started.html