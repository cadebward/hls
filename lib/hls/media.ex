defmodule HLS.Media do
  # These attributes are enum and all caps without quotes
  @enum_values ~w(type default autoselect forced)a

  # These are attributes that MUST have their values double quoted.
  @string_values ~w(uri group_id language assoc_language name instream_id characteristics channels)a

  # This defines the order, as specified in the RFC. Its not strictly
  # required, but makes things more consistent and easier to test.
  @attribute_order ~w(type uri group_id language assoc_language name default autoselect forced instream_id characteristics channels)a

  defstruct [
    :name,
    :type,
    :uri,
    :group_id,
    :language,
    :default,
    :autoselect,
    :forced,
    :characteristics,
    :channels
  ]

  def build_audio(%HLS.M3ULine{} = line) do
    %__MODULE__{
      name: HLS.M3ULine.get_attribute(line, "name"),
      type: HLS.M3ULine.get_attribute(line, "type"),
      uri: HLS.M3ULine.get_attribute(line, "uri"),
      group_id: HLS.M3ULine.get_attribute(line, "group-id"),
      language: HLS.M3ULine.get_attribute(line, "language"),
      default: HLS.M3ULine.get_boolean_attribute(line, "default"),
      autoselect: HLS.M3ULine.get_boolean_attribute(line, "autoselect"),
      forced: HLS.M3ULine.get_boolean_attribute(line, "forced"),
      characteristics: HLS.M3ULine.get_attribute(line, "characteristics"),
      channels: HLS.M3ULine.get_attribute(line, "channels") |> maybe_parse_int()
    }
  end

  def build_subtitle(%HLS.M3ULine{} = line) do
    %__MODULE__{
      name: HLS.M3ULine.get_attribute(line, "name"),
      type: HLS.M3ULine.get_attribute(line, "type"),
      uri: HLS.M3ULine.get_attribute(line, "uri"),
      group_id: HLS.M3ULine.get_attribute(line, "group-id"),
      language: HLS.M3ULine.get_attribute(line, "language"),
      default: HLS.M3ULine.get_boolean_attribute(line, "default"),
      autoselect: HLS.M3ULine.get_boolean_attribute(line, "autoselect"),
      forced: HLS.M3ULine.get_boolean_attribute(line, "forced")
    }
  end

  defp maybe_parse_int(nil), do: nil

  defp maybe_parse_int(value) do
    case Integer.parse(value) do
      {int, _remainder} -> int
      _error_or_zero -> 0
    end
  end

  @doc """
  Given a key and value, correctly serializes the attribute into 
  a KEY=value string, respecting the spec for which keys should
  or should not be quoted.

  https://www.rfc-editor.org/rfc/rfc8216.html#section-4.3.4.2
  """
  def serialize_attribute(key, value) when key in @string_values do
    ~s<#{format_attribute_key(key)}="#{value}">
  end

  def serialize_attribute(key, true) when key in @enum_values do
    ~s<#{format_attribute_key(key)}=YES>
  end

  def serialize_attribute(key, false) when key in @enum_values do
    ~s<#{format_attribute_key(key)}=NO>
  end

  def serialize_attribute(key, value) when key in @enum_values do
    ~s<#{format_attribute_key(key)}=#{String.upcase(value)}>
  end

  def serialize_attributes(%__MODULE__{} = attributes) do
    attributes
    |> Map.from_struct()
    |> Map.take(@attribute_order)
    |> do_serialize_attributes()
  end

  # This writes the attributes to a map in the order that 
  # the RFC specifies.
  defp do_serialize_attributes(attribute_map) do
    @attribute_order
    |> Enum.reduce([], fn key, acc ->
      value = Map.get(attribute_map, key)

      if value != nil do
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
