---
title: "Nerves Upgrade Guide"
subtitle: "Upgrading your Nerves firmware project to a newer version of Nerves System"
date: 2023-07-11
author: Masatoshi Nishiguchi
draft: false
tags: ["nerves", "elixir"]
---

This guide provides steps to be followed when you upgrade your Nerves firmware
project to a newer version of Nerves System.

<!--more-->

## Preparation

Before getting down to business, you want to find out the current status of
your Nerves project.

### Elixir and Erlang/OTP Versions

One easy way to find Elixir and Erlang/OTP versions that your Nerves project
currently uses is to run `elixir --version` in the project directory.

```bash
$ cd path/to/my_project

$ elixir --version
```

Running the command may print something like this:

```
Erlang/OTP 26 [erts-14.0.2] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Elixir 1.15.2 (compiled with Erlang/OTP 26)
```

### Mix Target and Nerves System

Find the [Mix Target] for your target device and the corresponding Nerves
System dependency (the build platform for the target). See the [Nerves Targets
document].

As an example, if your target device is [Raspberry Pi 4]:
- Mix Target: `rpi4`
- Nerves System: [nerves_system_rpi4][nerves_system_rpi4 package]

[nerves package]: https://hex.pm/packages/nerves
[nerves_system_rpi4 package]: https://hex.pm/packages/nerves_system_rpi4
[Mix Target]: https://hexdocs.pm/mix/main/Mix.html#module-targets
[Raspberry Pi 4]: https://www.raspberrypi.com/products/raspberry-pi-4-model-b
[Nerves Targets document]: https://hexdocs.pm/nerves/targets.html

### mix.exs

The Nerves project is spread over many packages in order to focus on a limited scope per concern.
You can find them in the list of dependencies in your `mix.exs`.

```elixir
defp deps do
  [
    # Dependencies for all targets
    {:nerves, "~> 1.10", runtime: false},
    {:shoehorn, "~> 0.9.0"},
    {:ring_logger, "~> 0.10.2"},
    {:toolshed, "~> 0.3.1"},

    # Dependencies for all targets except :host
    {:nerves_runtime, "~> 0.13.0", targets: @all_targets},
    {:nerves_pack, "~> 0.7.0", targets: @all_targets},
    ...
    # Dependencies for specific targets
    {:nerves_system_rpi4, "~> 1.21", runtime: false, targets: :rpi4},
    ...
  ]
end
```

Most of the time, they are backward-compatible unless specified in changelogs
and generally it is OK to use the latest versions; however, the Nerves System
dependency is picky about the Erlang/OTP versions. More specifically, the major
version of Erlang/OTP that your project uses must match what the Nerves System
dependency expects.

The Nerves System dependency determines the OTP version running on the target.
It is possible that a recent update to the Nerves System pulled in a new
version of Erlang/OTP. If you are using an official Nerves System, you can
verify this by reviewing the [Nerves System compatibility chart] in the Nerves
documentation or changelog that comes with the release like
[this](https://github.com/nerves-project/nerves_system_rpi4/commit/0cff1d8b9d66c117cf00a8f5753dc9bc4a70b59a).

[Nerves System compatibility chart]: https://hexdocs.pm/nerves/systems.html#compatibility

## Basic workflow

Once you have collected information about your Nerves project, you are ready
for the Nerves System upgrade.

### Edit dependencies in mix.exs

Change the version numbers of the dependencies in your `mix.exs` as needed.

### Clean dependencies

```bash
# Option 1
$ mix clean --deps

# Option 2
$ rm -rf _build deps
```

### Unlock dependencies

```bash
# Option 1
$ mix deps.unlock --all

# Option 2
$ rm mix.lock
```

### Update dependencies

```bash
# Set the MIX_TARGET to the desired platform (rpi4, bbb, mangopi_mq_pro, etc.)
$ export MIX_TARGET=rpi4
$ mix deps.get
```

### Build firmware

```bash
$ mix firmware
```

```bash
# Option 1: Insert a MicroSD card to your host machine
$ mix burn

# Option 2: Upload to an existing Nerves device
$ mix firmware.gen.script
$ ./upload.sh nerves-1234.local
```

## Version mismatch

In case the Erlang/OTP version mismatch occurs between your project and your
Nerves System dependency, a friendly error message will show. It is intended to
help you, so please don't be scared of these red paragraphs and do read them
carefully.

![nerves-system-otp-version-not-matching](https://user-images.githubusercontent.com/7563926/252093501-5e8264ac-3e51-4d19-8a23-15c303b04651.png)

## Breaking changes

The Nerves core team is doing their best to ensure the backward-compatibility
in all the packages they manage whenever possible; however sometimes they do
not have control over it when, for example, external dependencies introduce
breaking changes. In such cases, the Nerves core team will devise friendly
self-explanatory messages as well as detailed explanation in changelogs.

One example is [VM args]. In order to support Elixir 1.15 and Erlang/OTP 26,
the Nerves users need to change arguments for the Erlang VM due to the changes
in Elixir and Erlang/OTP. Those arguments will vary depending of the versions.

As a solution, the Nerves core team implemented the logic to print an
appropriate message with helpful instructions according to the versions
currently being used.

https://github.com/nerves-project/nerves/pull/884/files

![incompatible-vm-args](https://user-images.githubusercontent.com/7563926/252123039-10d8d4ae-88ef-4ede-9121-378b9648d39a.png)

Also the Nerves project template has been updated to generate appropreate
`vm.args` conditionally.

https://github.com/nerves-project/nerves_bootstrap/pull/273/files


[VM args]: https://elixir-lang.org/getting-started/mix-otp/config-and-releases.html#vm-args

## Delete old artifacts optionally

This is totally optional but it is a good opportunity to delete downloaded artifacts for the versions you no longer use.

Nerves automatically fetches the System and Toolchain from one of the cache
mirrors. These artifacts are cached locally in `~/.nerves/artifacts` so they
can be shared across projects.

It is always OK to `rm -fr ~/.nerves`. The consequence is that the archives
that you're using will need to be re-downloaded when you run `mix deps.get`.

## Nerves Community

Nerves strives to be an open and community-driven project. The Nerves core team
is curious about how others are building with Nerves and want to highlight
others contributions whenever possible.

If you need any help or you are willing to help others, we have [Nerves community](https://nerves-project.org/community).

Also if you find any problems, please try sending Github issues and Pull
Requests to [Nerves Project repositories](https://github.com/nerves-project).

