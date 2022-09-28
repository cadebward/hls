defmodule HLS.Serializers.M3U8 do
  require EEx

  EEx.function_from_file(:def, :render, "templates/m3u8.eex", [:assigns], trim: true)

  defp insert_header(%HLS.Manifest{version: version, independent_segments: true}) do
    """
    #EXTM3U
    #EXT-X-VERSION:#{version}
    #EXT-X-INDEPENDENT-SEGMENTS
    """
  end

  defp insert_header(%HLS.Manifest{version: version, independent_segments: _}) do
    """
    #EXTM3U
    #EXT-X-VERSION:#{version}
    """
  end

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
      "#EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}"
    end
  end

  defp insert_subtitle_renditions(%HLS.Manifest{subtitle_renditions: renditions}) do
    for rendition <- renditions do
      "#EXT-X-MEDIA:#{HLS.Media.serialize_attributes(rendition)}"
    end
  end

  defp insert_end_tag(%HLS.Manifest{type: :vod}), do: "#EXT-END"
  defp insert_end_tag(%HLS.Manifest{type: _}), do: ""
end
