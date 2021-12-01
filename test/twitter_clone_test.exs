defmodule TwitterCloneTest do
  use ExUnit.Case
  doctest TwitterClone

  test "greets the world" do
    assert TwitterClone.hello() == :world
  end
end
