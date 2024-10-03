defmodule HLS.Serializers.M3U8 do
  require EEx

  EEx.function_from_file(:def, :render, "lib/hls/serializers/m3u8.eex", [:assigns], trim: true)

  defp insert_header(%HLS.Manifest{} = manifest) do
    """
    #EXTM3U
    """
    |> String.trim()
    |> maybe_insert_version(manifest)
    |> maybe_insert_media_sequence(manifest)
    |> maybe_insert_x_map(manifest)
    |> maybe_insert_images_only(manifest)
    |> maybe_insert_independent_segments(manifest)
    |> maybe_insert_target_duration(manifest)
    |> maybe_insert_playlist_type(manifest)
    |> maybe_insert_i_frames_only(manifest)
  end

  def insert_master_body(manifest) do
    ""
    |> maybe_insert_variant_streams(manifest)
    |> maybe_insert_audio_renditions(manifest)
    |> maybe_insert_subtitle_renditions(manifest)
    |> maybe_insert_image_renditions(manifest)
    |> maybe_insert_i_frame_stream_renditions(manifest)
  end

  defp maybe_insert_version(content, %HLS.Manifest{version: nil}), do: content

  defp maybe_insert_version(content, %HLS.Manifest{version: version}) do
    content <> "\n#EXT-X-VERSION:#{version}"
  end

  defp maybe_insert_media_sequence(content, %HLS.Manifest{media_sequence: nil}), do: content

  defp maybe_insert_media_sequence(content, %HLS.Manifest{media_sequence: media_sequence}) do
    content <> "\n#EXT-X-MEDIA-SEQUENCE:#{media_sequence}"
  end

  defp maybe_insert_x_map(content, %HLS.Manifest{x_map: nil}), do: content
  defp maybe_insert_x_map(content, %HLS.Manifest{x_map: []}), do: content

  defp maybe_insert_x_map(content, %HLS.Manifest{x_map: attributes}) do
    serialized_attrs =
      attributes
      |> Enum.map(fn {key, value} ->
        "#{key}=\"#{value}\""
      end)
      |> Enum.join(",")

    content <> "\n#EXT-X-MAP:#{serialized_attrs}"
  end

  defp maybe_insert_images_only(content, %HLS.Manifest{images_only: true}) do
    content <> "\n#EXT-X-IMAGES-ONLY"
  end

  defp maybe_insert_images_only(content, _manifest), do: content

  defp maybe_insert_independent_segments(content, %HLS.Manifest{independent_segments: true}) do
    content <> "\n#EXT-X-INDEPENDENT-SEGMENTS"
  end

  defp maybe_insert_independent_segments(content, _), do: content

  defp maybe_insert_target_duration(content, %HLS.Manifest{target_duration: duration})
       when is_integer(duration) do
    content <> "\n#EXT-X-TARGETDURATION:#{duration}"
  end

  defp maybe_insert_target_duration(content, _), do: content

  defp maybe_insert_playlist_type(content, %HLS.Manifest{type: :vod}) do
    content <> "\n#EXT-X-PLAYLIST-TYPE:VOD"
  end

  defp maybe_insert_playlist_type(content, _), do: content

  defp maybe_insert_i_frames_only(content, %HLS.Manifest{i_frames_only: true}) do
    content <> "\n#EXT-X-I-FRAMES-ONLY"
  end

  defp maybe_insert_i_frames_only(content, _), do: content

  defp maybe_insert_variant_streams(content, %HLS.Manifest{variants: nil}), do: content

  defp maybe_insert_variant_streams(content, %HLS.Manifest{variants: []}), do: content

  defp maybe_insert_variant_streams(content, %HLS.Manifest{variants: variants}) do
    Enum.reduce(variants, content, fn variant, acc ->
      """
      #{acc}
      #EXT-X-STREAM-INF:#{HLS.Variant.serialize_attributes(variant)}
      #{variant.uri}
      """
    end)
  end

  defp maybe_insert_audio_renditions(content, %HLS.Manifest{audio_renditions: nil}), do: content
  defp maybe_insert_audio_renditions(content, %HLS.Manifest{audio_renditions: []}), do: content

  defp maybe_insert_audio_renditions(content, %HLS.Manifest{audio_renditions: renditions}) do
    Enum.reduce(renditions, content, fn rendition, acc ->
      """
      #{acc}
      #EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}
      """
    end)
  end

  defp maybe_insert_subtitle_renditions(content, %HLS.Manifest{subtitle_renditions: nil}),
    do: content

  defp maybe_insert_subtitle_renditions(content, %HLS.Manifest{subtitle_renditions: []}),
    do: content

  defp maybe_insert_subtitle_renditions(content, %HLS.Manifest{subtitle_renditions: renditions}) do
    Enum.reduce(renditions, content, fn rendition, acc ->
      """
      #{acc}
      #EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}
      """
    end)
  end

  defp maybe_insert_image_renditions(content, %HLS.Manifest{image_renditions: nil}), do: content

  defp maybe_insert_image_renditions(content, %HLS.Manifest{image_renditions: []}), do: content

  defp maybe_insert_image_renditions(content, %HLS.Manifest{image_renditions: renditions}) do
    Enum.reduce(renditions, content, fn rendition, acc ->
      """
      #{acc}
      #EXT-X-IMAGE-STREAM-INF:#{HLS.ImageStreamInf.serialize_attributes(rendition)}
      """
    end)
  end

  defp maybe_insert_i_frame_stream_renditions(content, %HLS.Manifest{i_frame_renditions: nil}),
    do: content

  defp maybe_insert_i_frame_stream_renditions(content, %HLS.Manifest{i_frame_renditions: []}),
    do: content

  defp maybe_insert_i_frame_stream_renditions(content, %HLS.Manifest{
         i_frame_renditions: renditions
       }) do
    Enum.reduce(renditions, content, fn rendition, acc ->
      "#{acc}\n#EXT-X-I-FRAME-STREAM-INF:#{HLS.IFrameStreamInf.serialize_attributes(rendition)}"
    end)
  end

  defp insert_extinf_tags(%HLS.Manifest{segments: segments}) do
    for segment <- segments do
      duration =
        if floor(segment.duration) == segment.duration do
          floor(segment.duration)
        else
          segment.duration
        end

      "#EXTINF:#{duration},#{segment.title}\n"
      |> maybe_insert_tiles(segment)
      |> maybe_insert_byte_range(segment)
      |> then(&(&1 <> "#{segment.uri}\n"))
      |> maybe_prepend_program_date_time(segment)
    end
  end

  defp maybe_insert_byte_range(content, %HLS.Segment{byte_range: nil}), do: content

  defp maybe_insert_byte_range(content, %HLS.Segment{byte_range: byte_string}) do
    content <> "#EXT-X-BYTERANGE:#{byte_string}\n"
  end

  defp maybe_insert_tiles(content, %HLS.Segment{tiles: nil}), do: content

  defp maybe_insert_tiles(content, %HLS.Segment{tiles: %HLS.Segment.Tiles{} = tiles}) do
    content <> "#{HLS.Segment.Tiles.serialize(tiles)}\n"
  end

  defp maybe_prepend_program_date_time(string, %HLS.Segment{program_date_time: nil}) do
    string
  end

  defp maybe_prepend_program_date_time(string, %HLS.Segment{program_date_time: date}) do
    "#EXT-X-PROGRAM-DATE-TIME:#{date}\n" <> string
  end

  defp insert_end_tag(%HLS.Manifest{type: :vod}), do: "#EXT-X-ENDLIST"
  defp insert_end_tag(%HLS.Manifest{type: _}), do: ""
end
