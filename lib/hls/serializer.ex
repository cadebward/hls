defmodule HLS.Serializer do


  def run(%HLS.Manifest{} = manifest) do
    # build up m3u8 as IO Data.  Could be done as an eex template too.
    {iodata, _} =
      {[], manifest}
      |> add_basic_tags()
      |> add_version()
      |> add_independent_segments()
      |> reverse_data()

    # adds newlines to the iodata above by using IO.puts.
    {:ok, pid} = StringIO.open("")
    Enum.each(iodata, fn line -> IO.puts(pid, line) end)
    
    # return a string from StringIO
    {:ok, {_input_buffer, output_buffer}} = StringIO.close(pid)
    output_buffer
  end

  defp add_basic_tags({data, manifest}) do
    {[ "#EXTM3U" | data], manifest}
  end

  defp add_version({_data, %{version: nil}} = tuple), do: tuple

  defp add_version({data, %{version: ver} = manifest}) do
    {[["#EXT-X-VERSION:", to_string(ver)] | data], manifest}
  end

  defp add_independent_segments({data, %{independent_segments: true} = manifest}) do
    {["#EXT-X-INDEPENDENT-SEGMENTS" | data], manifest}
  end

  defp add_independent_segments({_data, %{independent_segments: nil}} = tuple), do: tuple

  defp reverse_data({data, manifest}), do: {Enum.reverse(data), manifest}
end

defimpl String.Chars, for: HLS.Manifest do
  def to_string(manifest) do
    HLS.Serializer.run(manifest)
  end
end
