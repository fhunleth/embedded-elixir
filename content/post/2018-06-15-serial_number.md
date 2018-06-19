---
title: Provisioning Nerves Devices
subtitle: Life after nerves.local
date: 2018-06-15
author: Frank Hunleth
draft: false
tags: ["nerves", "provisioning"]
---

When you're starting out with Nerves, you may have connected to your first
projects over the network using `nerves.local`. Libraries like
[nerves_init_gadget](nerves_init_gadget) make this easy and when you're
starting out, it's really convenient. Don't know the IP address that your
device was assigned? Try `nerves.local` and you're good to go.

And then you add a second device to your network. `nerves.local` isn't looking
so convenient any more.

<!--more-->

Suffice it to say that there are a number of ways of solving this problem. This
post shows how to provision names or numbers to devices. You'll likely need to
provision additional information to devices and that can be done in a similar
way.

The first step is to decide on a way of identifying devices. Nearly every
Nerves System has a way of finding a unique identifier for a board by default.
The default is to use that number to create a unique hostname and you can see
it by running `:inet.gethostname()`. It will be something like `nerves-1234`.
(This hostname is only local unless something registers it in the DNS.
`nerves.local` is a mDNS name.) The `erlinit.config` file specifies how to
create the hostname. All of the Raspberry Pi boards have a similar setting.
Here is the one for the [Raspberry Pi 3](rpi3_erlinit):

```elixir
-d "/usr/bin/boardid -b uboot_env -u serial_number -b rpi -n 4"
-n nerves-%s
```

The `-d` setting specifies how to find a unique ID. This invokes
[boardid](boardid) to look it up. Don't worry about the commandline arguments
yet. The unique ID could be stored in the CPU (like on the Raspberry Pi), an
EEPROM, or a few other places depending on the board. The `-n` setting specifies
the format of the hostname where the `%s` is substituted for the identifier.

Getting back to the `boardid` commandline, the arguments say to use the
`serial_number` key from the U-Boot environment first or if that doesn't exist,
use 4 digits of the Raspberry Pi's serial number.

Nerves uses the U-Boot environment for many things, but mostly for keeping track
of the running firmware by default. You can think of it as a very simple and
small key-value store that's on the SDCard (if you're using a Raspberry Pi) but
stored outside of any of the filesystems.
[Nerves.Runtime](nerves_runtime_metadata) documents the keys that Nerves uses. A
device doesn't have to run the U-Boot bootloader to have a U-Boot environment.
The format is convenient so Nerves reuses it.

Nerves does not make writing values to the U-Boot environment convenient to
reduce the chance of corrupting or losing data in it. Users should prefer to
store application settings and data in the Nerves application partition. The
U-Boot environment is appropriate for provisioning information that is unlikely
to change over the device's lifetime. The serial number of the device is
one example. To write it, attach to your Nerves device's console at type:

```elixir
iex> cmd("fw_setenv serial_number abc123")
:ok
```

Reboot and the next time the device comes up, you should be able to see the new
serial number:

```elixir
iex> Nerves.Runtime.KV.get("serial_number")
"abc123"
Iex> :inet.gethostname()
{:ok, 'nerves-abc123'}
```

Now getting back to the original issue, how does this fix the `nerves.local`
problem? The answer is that you need to update the `nerves_init_gadget`
configuration to tell it to construct the mDNS name off of the hostname. Modify
your `config.exs` to look something like this:

```elixir
config :nerves_init_gadget,
  mdns_domain: :hostname,
  ssh_console_port: 22
```

Rebuild and update the device. On your laptop, you should be able to `ping
nerves-abc123.local` now.

## Provisioning devices offline

Imagine that you need to make SDCards for a lot of devices. Logging on to the
console to set the serial number on each device will get old quick. You can
program the serial number at the same time that you're burning the SDCard.
Instead of using `mix firmware.burn`, it is easier to call `fwup` directly. `mix
firmware.burn` is a minimal wrapper on `fwup` anyway.

```sh
sudo SERIAL_NUMBER=abc123 fwup ./_build/rpi3/dev/nerves/images/myproj.fw
```

If you're wondering how this works, look for the following line in your system's
`fwup.conf` file:

```config
uboot_setenv(uboot-env, "serial_number", "\${SERIAL_NUMBER}")
```

## Security

The U-Boot environment block is stored in the clear on the SDCard and is
accessible via Nerves.Runtime.KV. The data isn't authenticated and tools are
readily available to modify it. Since you'll be tempted to provision secret key
material in the U-Boot environment block, please review the security
ramifications of that decision before doing so.


[nerves_init_gadget]: https://github.com/nerves-project/nerves_init_gadget
[rpi3_erlinit]: https://github.com/nerves-project/nerves_system_rpi3/blob/master/rootfs_overlay/etc/erlinit.config
[boardid]: https://github.com/fhunleth/boardid
[nerves_runtime_metadata]: https://github.com/nerves-project/nerves_runtime#nerves-system-and-firmware-metadata
