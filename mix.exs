defmodule StreamingService.MixProject do
  use Mix.Project

  def project do
    [
      app: :streaming_service,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :kafka_ex],
      mod: {StreamingService.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kafka_ex, "~> 0.8.3"}
    ]
  end
end
