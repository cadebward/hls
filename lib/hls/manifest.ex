defmodule HLS.Manifest do
  defstruct [
    :type,
    :lines,
    :segments,
    :variants,
    :i_frame_renditions,
    :image_renditions,
    :audio_renditions,
    :video_renditions,
    :subtitle_renditions,
    :closed_caption_renditions,
    :total_duration,
    :version,
    :independent_segments,
    :start,
    :target_duration,
    :media_sequence,
    :discontinuity_sequence,
    :end_list,
    :i_frames_only,
    :images_only
  ]

  # These tags are only found in master manifests. The existence
  # of any of these tags means it MUST be a master manifest.
  @master_manifest_tag_names ~w(EXT-X-MEDIA EXT-X-STREAM-INF)

  def build(lines) do
    %__MODULE__{
      type: get_manifest_type(lines),
      lines: lines,
      version: find_int(lines, "EXT-X-VERSION"),
      target_duration: find_int(lines, "EXT-X-TARGETDURATION"),
      media_sequence: find_int(lines, "EXT-X-MEDIA-SEQUENCE"),
      discontinuity_sequence: find_int(lines, "EXT-X-DISCONTINUITY-SEQUENCE"),
      independent_segments: exists?(lines, "EXT-X-INDEPENDENT-SEGMENTS"),
      start: "TODO",
      end_list: exists?(lines, "EXT-X-ENDLIST"),
      i_frames_only: exists?(lines, "EXT-X-I-FRAMES-ONLY"),
      images_only: exists?(lines, "EXT-X-IMAGES-ONLY")
    }
    |> put_variants()
    |> put_audio_renditions()
    |> put_subtitle_renditions()
    |> put_image_renditions()
    |> put_i_frame_renditions()
    |> put_segments()
  end

  # Loops over the lines and chunks the related lines together into a list. Each
  # list is then used to generate a Variant struct. The results are put back
  # onto the Manifest struct.
  defp put_variants(%{type: :master, lines: lines} = manifest) do
    variants =
      lines
      |> accumulate(&HLS.M3ULine.variant_tag_line?/1, &HLS.M3ULine.uri_line?/1)
      |> Enum.map(&HLS.Variant.build/1)

    %{manifest | variants: variants}
  end

  defp put_variants(manifest), do: %{manifest | variants: []}

  # Filters the parsed M3ULines for audio renditions. Each one is then parsed
  # into an HLS.Media struct and placed back onto the Manifest struct.
  defp put_audio_renditions(%{type: :master, lines: lines} = manifest) do
    renditions =
      lines
      |> Enum.filter(&HLS.M3ULine.audio_tag_line?/1)
      |> Enum.map(&HLS.Media.build_audio/1)

    %{manifest | audio_renditions: renditions}
  end

  defp put_audio_renditions(manifest), do: %{manifest | audio_renditions: []}

  # Filters the parsed M3ULines for subtitle renditions. Each one is then parsed
  # into an HLS.Media struct and placed back onto the Manifest struct.
  defp put_subtitle_renditions(%{type: :master, lines: lines} = manifest) do
    renditions =
      lines
      |> Enum.filter(&HLS.M3ULine.subtitle_tag_line?/1)
      |> Enum.map(&HLS.Media.build_subtitle/1)

    %{manifest | subtitle_renditions: renditions}
  end

  defp put_subtitle_renditions(manifest), do: %{manifest | subtitle_renditions: []}

  defp put_image_renditions(%{type: :master, lines: lines} = manifest) do
    renditions =
      lines
      |> Enum.filter(&HLS.M3ULine.image_stream_line?/1)
      |> Enum.map(&HLS.ImageStreamInf.build/1)

    %{manifest | image_renditions: renditions}
  end

  defp put_image_renditions(manifest), do: %{manifest | image_renditions: []}

  defp put_i_frame_renditions(%{type: :master, lines: lines} = manifest) do
    renditions =
      lines
      |> Enum.filter(&HLS.M3ULine.i_frame_stream_line?/1)
      |> Enum.map(&HLS.IFrameStreamInf.build/1)

    %{manifest | i_frame_renditions: renditions}
  end

  defp put_i_frame_renditions(manifest), do: %{manifest | image_renditions: []}

  defp put_segments(%{type: type, lines: lines} = manifest) when type not in [:master] do
    segments =
      lines
      |> accumulate(&HLS.M3ULine.segment_tag_line?/1, &HLS.M3ULine.uri_line?/1)
      |> Enum.map(&HLS.Segment.build/1)

    %{manifest | segments: segments}
  end

  defp put_segments(manifest), do: manifest

  # If the manifest contains a master-only tag, it is a master.
  # Otherwise, it must be vod or live.
  defp get_manifest_type(lines) do
    is_master =
      Enum.any?(lines, fn line ->
        Enum.member?(@master_manifest_tag_names, line.tag_name)
      end)

    if is_master do
      :master
    else
      get_vod_type(lines)
    end
  end

  # If EXT-X-ENDLIST exists, the manifest represents a VOD,
  # otherwise it must be live.
  defp get_vod_type(lines) do
    if Enum.any?(lines, &(&1.tag_name == "EXT-X-ENDLIST")) do
      :vod
    else
      :live
    end
  end

  # Searches through the parsed lines for the provided tag. If
  # found, attempts to parse the result to an int, or returns
  # the default.
  defp find_int(lines, tag_name, default \\ nil) do
    with %{value: value} <- Enum.find(lines, &(&1.tag_name == tag_name)) do
      case Integer.parse(value) do
        {num, ""} ->
          num

        {_num, _remainder} ->
          {num, ""} = Float.parse(value)
          round(num)

        :error ->
          default
      end
    else
      _ -> default
    end
  end

  defp exists?(lines, tag_name) do
    Enum.any?(lines, &(&1.tag_name == tag_name))
  end

  # This function starts creating "chunks" so long as `filter_fun/1` is true,
  # until `until_fun/1` returns true. This helps us combine lines that depend
  # on each other. For example, EXT-X-STREAM-INF has attributes, but they are
  # actually describing the the URI found on the next line.
  #
  # TODO: move to helpers/utils file? Then we can unit test the crap outta this
  defp accumulate(lines, filter_fun, until_fun) do
    Enum.chunk_while(
      lines,
      [],
      fn line, acc ->
        cond do
          until_fun.(line) ->
            # we have a URI, emit what we have and start new chunk
            {:cont, acc ++ [line], []}

          filter_fun.(line) ->
            # filter fun is true, start adding to acc
            {:cont, acc ++ [line]}

          true ->
            # otherwise, ignore and move on
            {:cont, acc}
        end
      end,
      &after_fun/1
    )
  end

  defp after_fun([]), do: {:cont, []}
  defp after_fun(acc), do: {:cont, acc, []}
end
