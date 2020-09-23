defmodule TerrisTest do
  use ExUnit.Case
  doctest Terris

  test "greets the world" do
    assert Terris.hello() == :world
  end
end
