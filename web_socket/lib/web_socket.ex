defmodule WebSocket do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, WebSocket.Router, [], [
        dispatch: WebSocket.dispatch,
        port: 4000,
      ])
    ]

    IO.puts("Running server...")

    opts = [strategy: :one_for_one, name: Navis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def dispatch do
    [
      {:_, [
        {"/logs/:log", WebSocket.Handler, []},
        {:_, Plug.Adapters.Cowboy.Handler, {WebSocket.Router, []}}
        ]}
      ]
    end
end
