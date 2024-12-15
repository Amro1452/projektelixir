defmodule Chatbot.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatbot,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison, :jason]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"}
    ]
  end
end
