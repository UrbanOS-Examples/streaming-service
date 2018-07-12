use Mix.Config

config :kafka_ex,
  brokers: [
    {"streaming-service-kafka", 9092}
  ],
  consumer_group: "smoke-test-kafka-consumer-group",
  disable_default_worker: true,
  sync_timeout: 3000,
  max_restarts: 10,
  max_seconds: 60,
  commit_interval: 5_000,
  commit_threshold: 100,
  kafka_version: "0.9.0"

env_config = Path.expand("#{Mix.env}.exs", __DIR__)
if File.exists?(env_config) do
  import_config(env_config)
end
