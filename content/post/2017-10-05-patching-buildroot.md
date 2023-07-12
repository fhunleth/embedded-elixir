---
title: Creating Patches Using Git
#subtitle:
date: 2017-10-05
author: Frank Hunleth
draft: false
tags: ["git", "buildroot"]
---

This is not an Elixir post, but it comes up when working with custom Nerves
systems. The problem is how to deal with custom patches to Buildroot, Linux, or
any of the non-Elixir libraries that your application might use. You may have
seen patch files like
[these](https://github.com/nerves-project/nerves_system_br/tree/main/patches/buildroot).
These patch files are used to create local changes to projects when
modifications either can't be sent upstream (partial workarounds, hacks for
specific systems, etc.) or haven't been integrated yet. This post describes a
way to create them.

<!--more-->

First, you'll need the source code as it exists before your changes. Usually
this means cloning a repository and checking out the tag. For example, if you're
patching Buildroot start by doing this:

```sh
git clone git://git.buildroot.net/buildroot
cd buildroot
git checkout 2017.05   # or whatever release you want
```

Remember the `2017.05` part. I'll refer to it later as the `<starting tag>`.

If the source code isn't in `git`, copy it to a new directory, initialize a
`git` repository, and add all files to it. Your starting tag will be `main`.

Next you'll want to create a branch so that all of the work that you're doing
can be tracked independently from upstream:

```sh
git checkout -b my_updates
```

The project that you want to patch may already have patches. Those should be
applied first:

```sh
git am path_to_existing/*.patch
```

It's possible that some of the existing patches are not in `git` format and you
get an error.  When that happens, I manually apply the patch with the `patch`
command. This looks like `patch -p1 < path_to_existing/thing.patch`. It can
become tedious. Be sure to `git add` and `git commit` after applying each patch
so that the order is preserved. This also will have the effect of turning
non-`git` patches into `git` ones later on. This is good.

Now it's time to make your changes. Hopefully you've already tested them so that
you're not iterating with patches files. That becomes painful. Make your changes
and commit them.

At this point, I usually run `git rebase -i <starting tag>` and see if I want to
squash my new change with an existing patch. I like to do this to keep my
patches neat and tidy, but that's optional.

Now it's time to create the patches. Run the following:

```sh
git format-patch -N <starting tag>
```

You should get a set of numbered `.patch` files.  Copy these over to wherever
patches are stored. You may need to clean up the destination patch directory
since patch numbers could move around or commit titles change.  One final note:
the `-N` keeps `git` from adding `[PATCH n/m]` to your patches. This will reduce
changes between patch files when you add a patch in the future.
