defmodule WebSocket.Handler do
  @behaviour :cowboy_websocket_handler

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @timeout 60000 # terminate if no activity for one minute

  #Called on websocket connection initialization.
  def websocket_init(_type, req, _opts) do
    path_info = elem(req, 15)
    state = %{
      log: path_info[:log],
    }
    {:ok, req, state, @timeout}
  end

  # Handle 'ping' messages from the browser - reply
  def websocket_handle({:text, "ping"}, req, state) do
    # IO.inspect(elem(req, 4))
    pid = elem(req, 4)
    Process.send pid, "#{state.log}: message", []
    {:reply, {:text, "pong 2"}, req, state}
  end

  # Handle other messages from the browser - don't reply
  def websocket_handle({:text, message}, req, state) do
    {:ok, req, state}
  end

  # Format and forward elixir messages to client
  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end
end
