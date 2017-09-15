---
title: Using Ecto and Sqlite3 with Nerves
date: 2017-09-14
author: Connor Rigby
draft: false
tags: ["nerves"]
---

One of the most common questions we answer in the Nerves help channels is how to
store persistant data accross reboots.
Since the file system read only, the normal avenues usually will not work with Nerves.

There are several solutions that have yielded varrying levels of success accross
projects. Before we dive too deep into Sqlite, lets take a look at the other options:

*  Key Value Storage such as the ever popular (Persistant Storage)[https://github.com/cellulose/persistent_storage]
  * PROS: Super easy setup. Simple api.
  * CONS: May be too simple. No migrations, File size may be an  issue.

* ETS and DETS
  * PROS: Built into Erlang. Easy setup. Distributed.
  * CONS: No migrations system. Can be difficult to maintain.

* Full Databases such as postgres, mongo
  * PROS: Ecto adapters make these relatively easy, multi user, etc.
  * CONS: Require a large setup on Nerves - Custom system, configs, setup etc.

And depending on your use case, one or more of those might be more useful to you.
But I've found in many cases a simple,
local, non clustered database is the perfect data storage mechanism for an
embedded system like Nerves.

## Application setup
Lets walk through a quick example app to get us up and running with Nerves and Ecto+Sqlite3.

```elixir
mix nerves.new hello_db
```

First off crack open the `mix.exs` file and add two dependencies to your list.
```elixir
# ommited for clarity
def deps do
  [
    {:ecto, "~> 2.2.2"},
    {:sqlite_ecto2, "~> 2.2.1"}
  ]
end
```

Next open your `lib/hello_db/application.ex` file and add this line:

```elixir
# ommited for clarity.
children = [
  # worker(HelloDb.Worker, [arg1, arg2, arg3]),
  supervisor(HelloDb.Repo, [])
]

```

Then open up our `config.exs` file to configure ecto and our new adapter.
```elixir
config :hello_db, HelloDb.Repo,
  adapter: Sqlite.Ecto2,
  database: "#{Mix.env}.sqlite3"

config :hello_db, ecto_repos: [HelloDb.Repo]
```

If you've used phoenix before this will be straight forward.
`adapter: Sqlite.Ecto2` tell ecto to use the Sqlite adapter we installed.
`database: "#{Mix.env}.Sqlite3"` tells the adapter what the name of the file is
that will house our database. We sort it by env for standard testing practices.

Now if we do a
```elixir
mix deps.get
iex -S mix
```

You'll notice that in the root of your project you will have a `dev.sqlite3` file.
The keen eye will notice that when deployed to our Nerves device, Sqlite will not
be aloud to write to that directory because of the read only filesystem.

That is relatively easy to solve. Back in our `config.exs` file uncomment this line:
`# import_config "#{Mix.Project.config[:target]}.exs"`
Then create a new file `config/rpi0w.exs` (Or whatever you plan on deploying to).

in that file we can overwrite the ecto config:
```elixir
config :hello_db, HelloDb.Repo,
  adapter: Sqlite.Ecto2,
  database: "/root/#{Mix.env}.sqlite3"

config :hello_db, ecto_repos: [HelloDb.Repo]
```
Notice the only thing we changed was the `database` field. This means that when deployed
our database will be written to the read+write application data partition of Nerves.


## Database Setup
Great! now we have an embedded database! but it will need to be setup before runtime won't it?
If you come from Phoenix, you know about all of Ecto's cool Mix Tasks. So lets do that.

```
mix ecto.create
```

You may notice this will only provision our database in our host environment, but when deployed to our Nerves device,
we unfortunately don't have the luxury of Mix Tasks. We are going to have to do something a little custom.

Note: There is a number of ways to possibly accomplish getting your database setup in Nerves,
and this is by no means the only way.

Naturally we should just be able to run the Mix Tasks from our application code.
Unfortunately this won't work. The Ecto tasks rely on things that just aren't available
in our Nerves release. So we will have to implement them a little bit manually.

First make sure we have a migration.
`mix ecto.gen.migration add_some_stuff`
Edit this file accordingly. (leaving it empty is fine too.)

In our `application.ex` file again lets add some functionality.

```elixir
@otp_app Mix.Project.config[:app]
def start(_type, _args) do
  import Supervisor.Spec, warn: false
  :ok = setup_db!()
  children = [
    supervisor(HelloDb.Repo, [])
  ]

  opts = [strategy: :one_for_one, name: HelloDb.Supervisor]
  Supervisor.start_link(children, opts)
end

defp setup_db! do
  repos = Application.get_env(@otp_app, :ecto_repos)
  for repo <- repos do
    setup_repo!(repo)
    migrate_repo!(repo)
  end
  :ok
end

defp setup_repo!(repo) do
  db_file = Application.get_env(@otp_app, repo)[:database]
  unless File.exists?(db_file) do
    :ok = repo.__adapter__.storage_up(repo.config)
  end
end

defp migrate_repo!(repo) do
  opts = [all: true]
  {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)

  migrator = &Ecto.Migrator.run/4
  pool = repo.config[:pool]
  migrations_path = Path.join((:code.priv_dir(@otp_app) |> to_string), "repo")
  migrated =
    if function_exported?(pool, :unboxed_run, 2) do
      pool.unboxed_run(repo, fn -> migrator.(repo, migrations_path, :up, opts) end)
    else
      migrator.(repo, migrations_path, :up, opts)
    end

  pid && repo.stop(pid)
  Mix.Ecto.restart_apps_if_migrated(apps, migrated)
end
```


We can brake that down a bit here:

The `setup_repo!/1` was derived from the (create)[https://github.com/elixir-ecto/ecto/blob/master/lib/mix/tasks/ecto.create.ex]
mix task. It just checks for the database file's existance, and creates it if the file
is non existant.

The `migrate_repo/1` function is a bit more interesting. We actually need to start
the repo (and its pool), find the path to our migrations, then of course run the migrations,
and finally restart everything. Lucily `Mix.Ecto` is available for us that does
much of the hard work for us.

And there we have it, Your Sqlite repo will be setup and migrated at application startup.
Obviously this is a little bit more config than your average Elixir or even Phoenix
setup, but It's all fairly straight forward. Hopefully this gives a good
jumping off point to storing data on a Nerves project.


## Bonus points
Obviously some things weren't concidered here. Be sure to concider some things
when setting up a database on your embedded device.

* If you plan on having migrations
what will you do about failed migrations?

* When and how do you drop the database/repo if at all?

* Should migrations _allways_ be ran? Maybe you want to hook into OTA updates, and
only run them on an update. (With the above code, it would be ran every boot.)
