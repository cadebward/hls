defmodule HLS.Variant do
  require Logger

  defstruct [
    :uri,
    :bandwidth,
    :average_bandwidth,
    :codecs,
    :resolution
  ]

  def build(lines) do
    tag_line = Enum.find(lines, &(&1.type == :tag))
    uri = Enum.find(lines, &(&1.type == :uri))

    if Enum.count(lines) > 2 do
      Logger.warn("Encountered more than two lines in variant. Unknown situation")
    end

    if tag_line == nil or uri == nil do
      raise """
      Invalid variant was encountered. Both URI and Tag is required, but got:

        #{inspect(lines)}
      """
    end

    %__MODULE__{
      uri: uri.value,
      bandwidth: HLS.M3ULine.get_attribute(tag_line, "bandwidth"),
      average_bandwidth: HLS.M3ULine.get_attribute(tag_line, "average-bandwidth"),
      codecs: HLS.M3ULine.get_attribute(tag_line, "codecs"),
      resolution: HLS.M3ULine.get_attribute(tag_line, "resolution")
    }
  end
end
