defmodule StreamingService do
  @moduledoc """
  Documentation for StreamingService.
  """

  @doc """
  Hello world.

  ## Examples

      iex> StreamingService.hello
      :world

  """
  def hello do
    :world
  end

  def foo do
    KafkaEx.create_worker(:foo)
  end
end
