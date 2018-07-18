defmodule SmokeTestingServiceTest do
  use ExUnit.Case
  import Checkov

  data_test "can produce and consume '#{message}' on topic '#{System.get_env("name")}'" do
    topic_name = System.get_env("name")
    {:ok, offset} = SmokeTestingService.produce_message(message, topic_name)
    assert SmokeTestingService.consume_message(topic_name, offset) == message

    where [
      [:message],
      ["message one"],
      ["message two"],
      ["message three"],
    ]
  end
end
