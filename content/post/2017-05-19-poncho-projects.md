---
title: Poncho Projects
subtitle: An Alternative to Umbrella Projects
date: 2017-05-19
author: Greg Mefford
draft: false
tags: ["nerves", "umbrella", "poncho"]
---

Recently in the Nerves community Slack channel, we have been talking about how [umbrella projects](http://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html#umbrella-projects) can be problematic for a Nerves-based project.
As a result, we have coined the tongue-in-cheek term "poncho projects" to refer to plain-old-Elixir projects with applications that use plain-old-dependencies.
This is different than using an umbrella project, which come with some standard conveniences and interdependencies between applications in the project.

<!--more-->

# What's Wrong with Umbrellas

Nerves-based umbrella projects nearly always have a "special" app in their umbrella that's used to build the firmware image that will be written to the bootable media.
You can see a simple guide on how that's done [here](https://hexdocs.pm/nerves/user-interfaces.html) and some working example code [here](https://github.com/nerves-project/nerves-examples/tree/main/hello_phoenix).

By default, umbrella projects have the following in their top-level `config/config.exs` file:

```
import_config "../apps/*/config/config.exs"
```

This tends to be unhelpful for Nerves-based projects because you probably want to control the order in which configurations are applied, or perhaps not apply some apps' configuration at all when building firmware.
This drives the requirement of always building from the "firmware" directory in the umbrella so that the correct settings are applied.

# Poncho Life

What we have found is that, since you have to do the `mix firmware` step from the "firmware" application directory anyway, it's less surprising to have a separate, non-umbrella project for building firmware.
This application can use a `path: "../your_business_logic"` dependency to achieve the same result as the `in_umbrella: true` convenience if you keep them side-by-side.
We call it a "poncho project" because it protects you from things leaking in from the sides rather than from above.

Yeah, super nerdy.
