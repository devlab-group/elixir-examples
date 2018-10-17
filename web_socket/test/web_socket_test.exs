defmodule WebSocketTest do
  use ExUnit.Case
  doctest WebSocket

  test "greets the world" do
    assert WebSocket.hello() == :world
  end
end
