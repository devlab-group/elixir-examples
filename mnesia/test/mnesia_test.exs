defmodule MnesiaTest do
  use ExUnit.Case
  doctest Mnesia

  test "greets the world" do
    assert Mnesia.hello() == :world
  end
end
