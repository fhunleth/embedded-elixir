---
title: Firmware Updates
#subtitle:
date: 2017-05-
author: Justin Schneck
draft: false
tags: ["nerves", "fwup", "reactor", "bootloader"]
---

Firmware updates are an important aspect to all parts of the device lifecycle, not just production. In development, they can save you time not burning SD cards by using mechanisms like pushing firmware bundles over the network. Network updates can also pave the way to automate executing canary tests using real hardware. Firmware updates are important to these stages because they are the only way to modify the contents of the read only filesystem.

# What is a Firmware Bundle?
Firmware bundles are created using [fwup](https://github.com/fhunleth/fwup/). In Nerves, Firmware bundles are `.fw` archive files that are constructed as the output of calls to `mix firmware`. You can think of these bundles as instructions attached to a payload. In modern Nerves based Mix projects, you'll find these bundles at `_build/#{Mix.target}/#{Mix.Env}/nerves/images`, for example, if we were in a project called `my_app` for Raspberry Pi Zero and running in dev, `_build/rpi0/dev/nerves/images/my_app.fw`.

The instructions contained in the bundle are declared in the fwup.conf included in the Nerves system. These instructions contain tasks like `complete` and `upgrade`.  

When the `complete` task is applied, the destination device is written fresh, like an initial install producing a layout of 2 slots for firmware on the device. This A/B layout provides some safeguards by retaining a known good working firmware. For example, when an `upgrade` task is applied, the new firmware is written to the inactive slot on the device and made active on next the next boot.

# How Do I Apply Them?
To apply a firmware bundle you need `fwup` installed, the destination device (ex: `/dev/mmcblk0`), and a task to execute from the fwup.conf (ex: `upgrade`). Fwup is already included in all Nerves systems. you can interact with it from a console session running on the device.

```elixir
iex> :os.cmd('fwup --version')
'0.13.0\n'
```

Applying a firmware bundle is a matter of passing the arguments into the fwup command. Here is an example of how to apply a firmware bundle to `/dev/mmcblk0` using the `upgrade` task.

`fwup -aU -i /path/to/my_app.fw -d /dev/mmcblk0 -t upgrade`

Using this technique, we can perform these tasks in a number of ways.

### SD Card
As a matter of fact, this is the way that `nerves firmware.burn` writes firmware to your SD card, by interacting with `fwup` running on your host. The `firmware.burn` mix task will use the `complete` task by default, but you could insert an SD card with a prior firmware and pass `--task upgrade` and upgrade the firmware instead.

### Over the Network
You can stream the fw files over the network to a device by using the `nerves_firmware_http` package. Simply add this package to your target dependencies, then use `mix firmware.push` to push to a device. You can specify a fw file directly, or let mix figure it our for you based off your target.

`mix firmware.push 192.168.1.100 --target rpi0`

# Whats New?
The v0.4.0 release of `nerves_firmware_http` contains several bug fixes and improvements for the network update process.

One of the big improvements with this version is that we can now stream the firmware bundle to the inactive firmware slot in chunks while its coming across the network. This saves space and resources instead of writing it to a temporary file, or storing it in large chunks in memory. This means stable support for devices with more limited resources like Raspberry Pi Zero and LinkIt Smart.

# What about Nerves Reactor?
Nerves Reactor and Bootloader are still on their way, and this update to network based firmware updates is a step towards their release. Nerves Reactor will give you extremely fast iteration in the development of your Elixir code and priv dir files, but doesn't directly handle changes to the Nerves system config, they are handled by firmware upgrades.
