defmodule HLS.Segment do
  require Logger

  defstruct [
    :uri,
    :duration,
    :title,
    :discontinuity,
    :byte_range,
    :program_date,
    :bit_rate
  ]

  def build(lines) do
    extinf = Enum.find(lines, &(&1.tag_name == "EXTINF"))
    uri = Enum.find(lines, &(&1.type == :uri))

    %__MODULE__{
      uri: uri.value,
      duration: HLS.M3ULine.get_float_attribute(extinf, "value"),
      title: HLS.M3ULine.get_attribute(extinf, "title"),
      discontinuity: Enum.any?(lines, &(&1.tag_name == "EXT-X-DISCONTINUITY")),
      byte_range: "TODO",
      program_date: "TODO",
      bit_rate: "TODO"
    }
  end
end
