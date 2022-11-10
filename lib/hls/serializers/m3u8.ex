defmodule HLS.Serializers.M3U8 do
  require EEx

  EEx.function_from_file(:def, :render, "lib/hls/serializers/m3u8.eex", [:assigns], trim: true)

  defp insert_header(%HLS.Manifest{version: version} = manifest) do
    """
    #EXTM3U
    #EXT-X-VERSION:#{version}
    """
    |> maybe_insert_independent_segments(manifest)
    |> maybe_insert_target_duration(manifest)
    |> maybe_insert_playlist_type(manifest)
  end

  defp insert_header(%HLS.Manifest{version: version, independent_segments: _}) do
    """
    #EXTM3U
    #EXT-X-VERSION:#{version}
    """
  end

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

  defp insert_variant_streams(%HLS.Manifest{variants: variants}) do
    for variant <- variants do
      """
      #EXT-X-STREAM-INF:#{HLS.Variant.serialize_attributes(variant)}
      #{variant.uri}
      """
    end
  end

  defp insert_audio_renditions(%HLS.Manifest{audio_renditions: renditions}) do
    for rendition <- renditions do
      "#EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}\n"
    end
  end

  defp insert_subtitle_renditions(%HLS.Manifest{subtitle_renditions: renditions}) do
    for rendition <- renditions do
      "#EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}\n"
    end
  end

  defp insert_image_renditions(%HLS.Manifest{image_renditions: renditions}) do
    for rendition <- renditions do
      "#EXT-X-IMAGE-STREAM-INF:#{HLS.Media.serialize_attributes(rendition)}\n"
    end
  end

  defp insert_extinf_tags(%HLS.Manifest{segments: segments}) do
    for segment <- segments do
      duration =
        if floor(segment.duration) == segment.duration do
          floor(segment.duration)
        else
          segment.duration
        end

      """
      #EXTINF:#{duration},#{segment.title}
      #{segment.uri}
      """
      |> maybe_prepend_program_date_time(segment)
    end
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
