defmodule HLS.M3ULine do
  @moduledoc """
  Struct and functions to handle a line in the M3U8 file.
  """

  defstruct [
    :type,
    :tag_name,
    :value,
    :attributes,
    :raw
  ]

  @tag_pattern ~r/#(?:-X-)?([^:]+):?(.*)$/

  # kv_tags are tags that come in pairs, like #EXT-X-VERSION:4
  @kv_tags ~w(EXTINF EXT-X-TARGETDURATION EXT-X-MEDIA-SEQUENCE EXT-X-VERSION EXT-X-DISCONTINUITY-SEQUENCE EXT-X-PLAYLIST-TYPE EXT-X-PROGRAM-DATE-TIME EXT-X-ALLOW-CACHE EXT-X-BYTERANGE)
  @segment_tags ~w(EXTINF EXT-X-BYTERANGE EXT-X-DISCONTINUITY EXT-X-KEY EXT-X-MAP EXT-X-DATERANGE EXT-X-PROGRAM-DATE-TIME EXT-X-TILES)

  def build(raw_line) do
    case Regex.run(@tag_pattern, raw_line) do
      nil ->
        %__MODULE__{
          type: :uri,
          tag_name: "URI",
          value: raw_line,
          attributes: %{},
          raw: raw_line
        }

      [_tag, tag_name, value] ->
        %__MODULE__{
          type: :tag,
          tag_name: tag_name,
          value: value,
          attributes: parse_attributes(tag_name, value),
          raw: raw_line
        }
    end
  end

  # tags with no values or attributes, like #EXTM3U
  defp parse_attributes(_, ""), do: %{}

  # these tags come in key value pairs, like #EXT-X-VERSION:4
  defp parse_attributes(tag, value) when tag in @kv_tags do
    %{"VALUE" => value}
  end

  defp parse_attributes(_tag, attributes) do
    attributes
    |> String.split(~r/,(?=(?:[^"]|"[^"]*")*$)/)
    |> Enum.map(fn pair ->
      [k, v] = String.split(pair, "=", parts: 2)
      {k, v}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Checks the existence of the provide key, and that it matches the provide value.

  ## Example

      iex> has_attribute?(%HLS.M3ULine{}, "noexity", "no")
      false

      iex> has_attribute?(%HLS.M3ULine{attributes: %{"KEY" => "VAL}}, "key", "val")
      true
  """
  def has_attribute?(%__MODULE__{attributes: attrs}, key, value) do
    Enum.find(attrs, fn {k, v} ->
      String.downcase(k) == String.downcase(key) && String.downcase(v) == String.downcase(value)
    end)
  end

  @doc """
  Retrieves the value of the given key from the M3ULine's attributes.
  """
  # @spec get_attribute(HLS.M3ULine.t(), String.t()) :: any() | nil
  def get_attribute(%__MODULE__{} = line, key) do
    find_attribute(line, key)
  end

  def get_attribute(nil, _key), do: nil

  @doc """
  Retrieves the value of the given key from the M3ULine's attributes
  while ensuring the result is a boolean.
  """
  def get_boolean_attribute(%__MODULE__{} = line, key) do
    line
    |> find_attribute(key)
    |> to_boolean()
  end

  defp to_boolean("NO"), do: false
  defp to_boolean("YES"), do: true
  defp to_boolean(_), do: false

  @doc """
  Retrieves the value of the given key from the M3ULine's attributes
  while ensuring the result is a float
  """
  def get_float_attribute(%__MODULE__{} = line, key) do
    case find_attribute(line, key) do
      nil -> 0.0
      value -> Float.parse(value)
    end
    |> case do
      {float, _remainder} -> float
      _error_or_zero -> 0.0
    end
  end

  @doc """
  Retrieves the value of the given key from the M3ULine's attributes
  while ensuring the result is an integer
  """
  def get_integer_attribute(%__MODULE__{} = line, key) do
    case find_attribute(line, key) do
      nil -> 0
      value -> Integer.parse(value)
    end
    |> case do
      {int, _remainder} -> int
      _error_or_zero -> 0
    end
  end

  defp find_attribute(%__MODULE__{attributes: attrs}, key) do
    Enum.find(attrs, fn {k, _v} ->
      String.downcase(k) == String.downcase(key)
    end)
    |> case do
      {_key, value} -> String.replace(value, "\"", "")
      _ -> nil
    end
  end

  @doc """
  Parses a resolution string under the given attr on the line struct. Returns a
  tuple of {width, height}, as integers.

  Expects a string at the given attr to look like 111x111.
  """
  def parse_resolution(%__MODULE__{} = line, attr) do
    case get_attribute(line, attr) do
      nil ->
        {0, 0}

      resolution_string ->
        [width, height] = String.split(resolution_string, "x")
        {resolution_to_integer(width), resolution_to_integer(height)}
    end
  end

  defp resolution_to_integer(resolution_string) do
    case Integer.parse(resolution_string) do
      {integer, _} -> integer
      _error -> 0
    end
  end

  @doc """
  Returns true if the provided M3ULine is a variant tag.
  """
  def variant_tag_line?(%{tag_name: tag}) when tag in ["EXT-X-STREAM-INF"] do
    true
  end

  def variant_tag_line?(_line), do: false

  @doc """
  Returns true if the provided M3ULine is an audio tag.
  """
  def audio_tag_line?(%{tag_name: "EXT-X-MEDIA"} = line) do
    HLS.M3ULine.has_attribute?(line, "type", "audio")
  end

  def audio_tag_line?(_line), do: false

  @doc """
  Returns true if the provided M3ULine is a subtitle tag.
  """
  def subtitle_tag_line?(%{tag_name: "EXT-X-MEDIA"} = line) do
    HLS.M3ULine.has_attribute?(line, "type", "subtitles")
  end

  def subtitle_tag_line?(_line), do: false

  @doc """
  Returns true if the provided M3ULine is an EXT-X-IMAGE-STREAM-INF tag,
    used for trick play
  """
  def image_stream_line?(%__MODULE__{} = line) do
    line.tag_name === "EXT-X-IMAGE-STREAM-INF"
  end

  def image_stream_line?(_), do: false

  @doc """
  Returns true if the provided M3ULine is an EXT-X-IMAGE-STREAM-INF tag,
    used for trick play
  """
  def i_frame_stream_line?(%__MODULE__{} = line) do
    line.tag_name === "EXT-X-I-FRAME-STREAM-INF"
  end

  def i_frame_stream_line?(_), do: false

  @doc """
  Returns true if the provided M3ULine is a segment tag.
  """
  def segment_tag_line?(%{type: :tag, tag_name: tag}) when tag in @segment_tags do
    true
  end

  def segment_tag_line?(_line), do: false

  @doc """
  Returns true if the provided M3ULine is a URI.
  """
  def uri_line?(%{type: :uri}), do: true
  def uri_line?(_line), do: false
end
