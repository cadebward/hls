defmodule HLS.Segment.Tiles do
  defstruct [
    :duration,
    :layout,
    :resolution
  ]

  @tag_name "EXT-X-TILES"
  @attrs ~w(resolution layout duration)a

  def build(%HLS.M3ULine{} = line) do
    %__MODULE__{
      duration: line.attributes["DURATION"],
      layout: line.attributes["LAYOUT"],
      resolution: line.attributes["RESOLUTION"]
    }
  end

  def serialize(%__MODULE__{} = tiles) do
    tiles
    |> Map.from_struct()
    |> Map.take(@attrs)
    |> do_serialize()
  end

  defp do_serialize(attrs) do
    @attrs
    |> Enum.reduce([], fn key, acc ->
      value = Map.get(attrs, key)

      if value != nil do
        [serialize_attribute(key, value) | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
    |> Enum.join(",")
    |> append_tag()
  end

  defp serialize_attribute(key, value) do
    "#{key |> to_string() |> String.upcase()}=#{value}"
  end

  defp append_tag(line_string) do
    "##{@tag_name}:#{line_string}"
  end
end
