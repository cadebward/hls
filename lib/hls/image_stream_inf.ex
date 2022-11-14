defmodule HLS.ImageStreamInf do
  require Logger
  # These are attributes that should not be quoted.
  @unquoted_values ~w(bandwidth resolution video)a

  # These are attributes that MUST have their values double quoted.
  @quoted_values ~w(codecs uri)a

  # This defines the order, as specified in the RFC. Its not strictly
  # required, but makes things more consistent and easier to test.
  @attribute_order ~w(uri bandwidth codecs resolution video)a

  defstruct ~w(uri bandwidth codecs resolution video)a

  def build(%HLS.M3ULine{} = line) do
    %__MODULE__{
      uri: HLS.M3ULine.get_attribute(line, "uri"),
      bandwidth: HLS.M3ULine.get_integer_attribute(line, "bandwidth"),
      codecs: HLS.M3ULine.get_attribute(line, "codecs"),
      resolution: HLS.M3ULine.get_attribute(line, "resolution"),
      video: HLS.M3ULine.get_attribute(line, "video")
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
