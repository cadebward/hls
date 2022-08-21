defmodule HLS do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @doc """
  Parses an HLS manifest (.m3u8) with the provided URL.

  This can be the Master Playlist or a Media Playlist.
  """
  def parse(manifest) do
    manifest
    |> parse_lines()
    |> HLS.Manifest.build()
  end

  defp parse_lines(content) do
    content
    |> String.split(~r/\r?\n/, trim: true)
    |> Enum.reject(&comment?/1)
    |> Enum.map(&HLS.M3ULine.build/1)
  end

  defp comment?("#"), do: true
  defp comment?("# " <> _rest), do: true
  defp comment?(_other), do: false
end
