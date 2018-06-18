defmodule StreamingServiceTest do
  use ExUnit.Case
  doctest StreamingService

  test "greets the world" do
    assert StreamingService.hello() == :world
  end
end
