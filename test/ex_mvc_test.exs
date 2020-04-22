defmodule ExMvcTest do
  use ExUnit.Case
  doctest ExMvc

  test "greets the world" do
    assert ExMvc.hello() == :world
  end
end
