defmodule SmokeTestingService do
  def produce_message(message, topic_name) do
    KafkaEx.produce(topic_name, 0, message, required_acks: 1, timeout: 10_000)
  end

  def consume_message(topic_name, offset) do
    KafkaEx.fetch(topic_name, 0, [offset: offset, wait_time: 10_000])
    |> List.first()
    |> Map.get(:partitions)
    |> List.first()
    |> Map.get(:message_set)
    |> List.first()
    |> Map.get(:value)
  end
end
