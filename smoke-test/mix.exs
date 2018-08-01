defmodule SmokeTestingService.MixProject do
  use Mix.Project

  def project do
    [
      app: :smoke_testing_service,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :kafka_ex],
    ]
  end

  defp deps do
    [
      {:kafka_ex, "~> 0.8.3"},
      {:checkov, "~> 0.2.0"},
    ]
  end
end