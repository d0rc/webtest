defmodule Webtest.Mixfile do
  use Mix.Project

  def project do
    [ app: :webtest,
      version: "0.0.1",
      deps: deps ]
  end

  def application do
    [
      applications: [ :jsex, :httpoison ]
    ]
  end

  defp deps do
    [
      { :jsex, github: "talentdeficit/jsex" },
      { :cookiejar, github: "d0rc/elixir-cookiejar" },
      { :hackney, github: "benoitc/hackney", override: true},
      { :hackney_lib, github: "benoitc/hackney_lib", override: true},
      { :httpoison, github: "d0rc/httpoison"}
    ]
  end
end
