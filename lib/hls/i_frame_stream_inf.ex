defmodule HLS.IFrameStreamInf do
  # type: :tag,
  # tag_name: "EXT-X-I-FRAME-STREAM-INF",
  # value: "AVERAGE-BANDWIDTH=183689,BANDWIDTH=187492,CODECS=\"avc1.64002a\",RESOLUTION=396x224,URI=\"v7/iframe_index.m3u8\"",
  # attributes: %{
  #   "AVERAGE-BANDWIDTH" => "183689",
  #   "BANDWIDTH" => "187492",
  #   "CODECS" => "\"avc1.64002a\"",
  #   "RESOLUTION" => "396x224",
  #   "URI" => "\"v7/iframe_index.m3u8\""
  # },
  # raw: "#EXT-X-I-FRAME-STREAM-INF:AVERAGE-BANDWIDTH=183689,BANDWIDTH=187492,CODECS=\"avc1.64002a\",RESOLUTION=396x224,URI=\"v7/iframe_index.m3u8\""

  require Logger
  # These are attributes that should not be quoted.
  @unquoted_values ~w(bandwidth resolution average_bandwidth)a

  # These are attributes that MUST have their values double quoted.
  @quoted_values ~w(codecs uri)a

  # This defines the order, as specified in the RFC. Its not strictly
  # required, but makes things more consistent and easier to test.
  @attribute_order ~w(bandwidth average_bandwidth codecs resolution uri)a

  defstruct ~w(average_bandwidth bandwidth codecs resolution resolution_width resolution_height uri)a

  def build(%HLS.M3ULine{} = line) do
    {resolution_width, resolution_height} = HLS.M3ULine.parse_resolution(line, "resolution")

    %__MODULE__{
      uri: HLS.M3ULine.get_attribute(line, "uri"),
      bandwidth: HLS.M3ULine.get_integer_attribute(line, "bandwidth"),
      codecs: HLS.M3ULine.get_attribute(line, "codecs"),
      resolution: HLS.M3ULine.get_attribute(line, "resolution"),
      resolution_width: resolution_width,
      resolution_height: resolution_height,
      average_bandwidth: HLS.M3ULine.get_integer_attribute(line, "average-bandwidth")
    }
  end

  @doc """
  Given a key and value, correctly serializes the attribute into 
  a KEY=value string, respecting the spec for which keys should
  or should not be quoted.

  https://www.rfc-editor.org/rfc/rfc8216.html#section-4.3.4.2
  """
  def serialize_attribute(key, value) when key in @unquoted_values do
    ~s<#{format_attribute_key(key)}=#{value}>
  end

  def serialize_attribute(key, value) when key in @quoted_values do
    ~s<#{format_attribute_key(key)}="#{value}">
  end

  def serialize_attributes(%__MODULE__{} = attrs) do
    attrs
    |> Map.from_struct()
    |> Map.take(@attribute_order)
    |> do_serialize_attributes()
  end

  # This writes the attributes to a map in the order that 
  # the RFC specifies.
  defp do_serialize_attributes(attribute_map) do
    @attribute_order
    |> Enum.reduce([], fn key, acc ->
      if value = Map.get(attribute_map, key) do
        acc ++ [serialize_attribute(key, value)]
      else
        acc
      end
    end)
    |> Enum.join(",")
  end

  defp format_attribute_key(key) when is_atom(key) do
    key
    |> to_string()
    |> String.upcase()
    |> String.replace("_", "-")
  end
end
