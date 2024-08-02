defmodule Hls.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/cadebward/hls"

  def project do
    [
      app: :hls,
      version: @version,
      elixir: "~> 1.6",
      name: "HLS",
      description: "A simple and fast parser for HLS manifests.",
      aliases: [docs: &build_docs/1],
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Cade Ward"],
      links: %{
        "GitHub" => @url,
        "Changelog" => "#{@url}/blob/master/CHANGELOG.md"
      }
    }
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["HLS", @version, Mix.Project.compile_path()]
    opts = ~w[--main HLS --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
