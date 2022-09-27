defmodule HLS.Serializer do
  def run(%HLS.Manifest{} = manifest) do
    {txt, _} =
      {"", manifest}
      |> add_basic_tags()
      |> add_version()
      |> add_independent_segments()

    txt
  end

  defp add_basic_tags({txt, manifest}) do
    {txt <> "#EXTM3U\n", manifest}
  end

  defp add_version({txt, %{version: nil}} = tuple), do: tuple

  defp add_version({txt, %{version: ver} = manifest}) do
    {txt <> "#EXT-X-VERSION:#{ver}\n", manifest}
  end

  defp add_independent_segments({txt, %{independent_segments: true} = manifest}) do
    {txt <> "#EXT-X-INDEPENDENT-SEGMENTS", manifest}
  end

  defp add_independent_segments({txt, %{independent_segments: nil}} = tuple), do: tuple
end
