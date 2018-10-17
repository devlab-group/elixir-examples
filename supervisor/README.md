# Supervisor Example

Example of how to use supervisor to restart process.

Run iex:

```bash
iex service.exs
```

Then start `App.Supervisor`:

```elixir
App.Supervisor.start_link #=> {:ok, #PID<0.94.0>}
```

Well supervisor is started, let's check `App.Service` is running:

```elixir
App.Service.pid #=> #PID<0.95.0>
```

Now let's kill this service's process:

```elixir
Process.exit(App.Service.pid, :kill) #=> true
```

Now lets check service status and get it's pid:

```elixir
App.Service.check #=> true
App.Service.pid #=> #PID<0.100.0>
```
Now our PID is 100. Our service was restarted and is working again. Whoa!
