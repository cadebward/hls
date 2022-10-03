defmodule HLS.Segment do
  require Logger

  # These attributes are enum and all caps without quotes
  @enum_values ~w(type default autoselect forced)a

  # These are attributes that MUST have their values double quoted.
  @string_values ~w(uri group_id language assoc_language name instream_id characteristics channels)a

  # This defines the order, as specified in the RFC. Its not strictly
  # required, but makes things more consistent and easier to test.
  @attribute_order ~w(type uri group_id language assoc_language name default autoselect forced instream_id characteristics channels)a

  defstruct [
    :uri,
    :duration,
    :title,
    :discontinuity,
    :byte_range,
    :program_date_time,
    :bit_rate
  ]

  def build(lines) do
    # TODO should have helper functions for retrieving these tags
    extinf = Enum.find(lines, &(&1.tag_name == "EXTINF"))
    uri = Enum.find(lines, &(&1.type == :uri))
    prog_date_time = Enum.find(lines, &(&1.tag_name == "EXT-X-PROGRAM-DATE-TIME"))

    %__MODULE__{
      uri: uri.value,
      duration: HLS.M3ULine.get_float_attribute(extinf, "value"),
      title: HLS.M3ULine.get_attribute(extinf, "title"),
      discontinuity: Enum.any?(lines, &(&1.tag_name == "EXT-X-DISCONTINUITY")),
      program_date_time: HLS.M3ULine.get_attribute(prog_date_time, "value"),
      byte_range: "TODO",
      bit_rate: "TODO"
    }
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
