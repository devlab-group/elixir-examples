defmodule MyPlugTest do
  use ExUnit.Case
  doctest MyPlug

  test "greets the world" do
    assert MyPlug.hello() == :world
  end
end
