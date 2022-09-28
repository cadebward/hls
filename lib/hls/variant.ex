defmodule HLS.Variant do
  require Logger

  # These are attributes that should not be quoted.
  @decimal_values ~w(bandwidth average_bandwidth resolution frame_rate)a

  # These are attributes that MUST have their values double quoted.
  @string_values ~w(codecs audio video subtitles closed_captions)a

  # This defines the order, as specified in the RFC. Its not strictly
  # required, but makes things more consistent and easier to test.
  @attribute_order ~w(bandwidth average_bandwidth codecs resolution frame_rate hdcp_level audio video subtitles closed_captions)a

  defstruct [
    :uri,
    :bandwidth,
    :average_bandwidth,
    :codecs,
    :resolution,
    :audio,
    :subtitles
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
      bandwidth: HLS.M3ULine.get_integer_attribute(tag_line, "bandwidth"),
      average_bandwidth: HLS.M3ULine.get_attribute(tag_line, "average-bandwidth"),
      codecs: HLS.M3ULine.get_attribute(tag_line, "codecs"),
      resolution: HLS.M3ULine.get_attribute(tag_line, "resolution"),
      audio: HLS.M3ULine.get_attribute(tag_line, "audio"),
      subtitles: HLS.M3ULine.get_attribute(tag_line, "subtitles")
    }
  end

  @doc """
  Given a key and value, correctly serializes the attribute into 
  a KEY=value string, respecting the spec for which keys should
  or should not be quoted.

  https://www.rfc-editor.org/rfc/rfc8216.html#section-4.3.4.2
  """
  def serialize_attribute(key, value) when key in @decimal_values do
    ~s<#{format_attribute_key(key)}=#{value}>
  end

  def serialize_attribute(key, value) when key in @string_values do
    ~s<#{format_attribute_key(key)}="#{value}">
  end

  def serialize_attributes(%HLS.Variant{} = variant_attributes) do
    variant_attributes
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
