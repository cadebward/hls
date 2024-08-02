defmodule HLSTest do
  use ExUnit.Case
  doctest HLS

  defp trim_manifest(string) do
    string
    |> String.replace("\n\n", "\n")
    |> String.trim()
  end

  test "basic master playlist" do
    master_playlist = """
    #EXTM3U

    # This is a comment. Don't parse me. Good luck with blank comments!
    #


    #EXT-X-INDEPENDENT-SEGMENTS

    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224
    media.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=40000
    media1.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=440000,RESOLUTION=396x224
    media2.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=1928000,RESOLUTION=960x540
    media3.m3u8
    """

    result = HLS.parse(master_playlist)
    assert result.type == :master
    assert result.version == nil
    assert result.target_duration == nil
    assert result.media_sequence == nil
    assert result.discontinuity_sequence == nil
    assert result.independent_segments == true
  end

  test "basic media playlist live" do
    media_playlist = """
    #EXTM3U
    #EXT-X-TARGETDURATION:10
    #EXT-X-VERSION:4
    #EXT-X-MEDIA-SEQUENCE:0
    #EXTINF:10,	
    #EXT-X-BYTERANGE:522828@0
    hls_450k_video.ts
    #ZEN-TOTAL-DURATION:1621.07780
    """

    result = HLS.parse(media_playlist)
    assert result.type == :live
    assert result.version == 4
    assert result.target_duration == 10
    assert result.media_sequence == 0
    assert result.discontinuity_sequence == nil
    assert result.independent_segments == false
  end

  test "basic media playlist vod" do
    media_playlist = """
    #EXTM3U
    #EXT-X-TARGETDURATION:10
    #EXT-X-DISCONTINUITY-SEQUENCE:1
    #EXT-X-VERSION:4
    #EXT-X-MEDIA-SEQUENCE:0
    #EXTINF:10,	
    #EXT-X-BYTERANGE:522828@0
    hls_450k_video.ts
    #EXT-X-ENDLIST
    """

    result = HLS.parse(media_playlist)
    assert result.type == :vod
    assert result.version == 4
    assert result.target_duration == 10
    assert result.media_sequence == 0
    assert result.discontinuity_sequence == 1
    assert result.independent_segments == false
  end

  @tag :skip
  test "TODO: playlist with start time offset" do
    playlist = """
    #EXT-X-VERSION:3
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXT-X-TARGETDURATION:10
    #EXT-X-START:TIME-OFFSET=10.3
    #EXTINF:10,
    media-00001.ts
    """

    result = HLS.parse(playlist)
    assert result.type == :vod
    assert result.version == 4
    assert result.target_duration == 10
    assert result.media_sequence == 0
    assert result.discontinuity_sequence == 1
    assert result.independent_segments == false
    assert result.start == "10.3"
  end

  test "builds variant list correctly" do
    master_playlist = """
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224,FRAME-RATE=24.000
    media.m3u8
    """

    result = HLS.parse(master_playlist)
    assert Enum.count(result.variants) == 1

    variant = hd(result.variants)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == 240_000
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
    assert variant.resolution_width == 396
    assert variant.resolution_height == 224
    assert variant.frame_rate == "24.000"
    assert variant.uri == "media.m3u8"

    master_playlist = """
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224
    media.m3u8

    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224
    media.m3u8
    """

    result = HLS.parse(master_playlist)
    assert Enum.count(result.variants) == 2

    variant = Enum.at(result.variants, 0)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == 240_000
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
    assert variant.resolution_width == 396
    assert variant.resolution_height == 224
    assert variant.uri == "media.m3u8"

    variant = Enum.at(result.variants, 1)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == 240_000
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
    assert variant.resolution_width == 396
    assert variant.resolution_height == 224
    assert variant.uri == "media.m3u8"
  end

  test "one of everything" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",LANGUAGE="spa",NAME="Spanish",AUTOSELECT=YES,DEFAULT=NO,CHARACTERISTICS="public.accessibility.describes-video",URI="audio/spa/The_Chosen_S01E01_audio_spa_20211108_134000.m3u8"
    #EXT-X-MEDIA:TYPE=SUBTITLES,AUTOSELECT=YES,DEFAULT=NO,FORCED=NO,GROUP-ID="subs",LANGUAGE="en",NAME="English",URI="subtitles/eng/The_Chosen_S01E01_eng.m3u8"
    #EXT-X-STREAM-INF:BANDWIDTH=739200,RESOLUTION=480x270,CODECS="avc1.640015,mp4a.40.2",AUDIO="aud",SUBTITLES="subs"
    #EXT-X-I-FRAME-STREAM-INF:AVERAGE-BANDWIDTH=246620,BANDWIDTH=915255,CODECS="hvc1.1.6.L150.b0",RESOLUTION=3840x2160,URI="some/path/goes/here"
    video/CHO_EP101_Angel-thechosen_270p.m3u8
    """

    result = HLS.parse(playlist)

    assert Enum.count(result.variants) == 1
    variant = hd(result.variants)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == 739_200
    assert variant.resolution == "480x270"
    assert variant.codecs == "avc1.640015,mp4a.40.2"

    assert Enum.count(result.audio_renditions) == 1
    audio = hd(result.audio_renditions)
    assert audio.autoselect == true
    assert audio.default == false
    assert audio.forced == false
    assert audio.group_id == "aud"
    assert audio.language == "spa"
    assert audio.name == "Spanish"
    assert audio.type == "AUDIO"
    assert audio.characteristics == "public.accessibility.describes-video"
    assert audio.uri == "audio/spa/The_Chosen_S01E01_audio_spa_20211108_134000.m3u8"

    assert Enum.count(result.subtitle_renditions) == 1
    sub = hd(result.subtitle_renditions)
    assert sub.autoselect == true
    assert sub.default == false
    assert sub.forced == false
    assert sub.group_id == "subs"
    assert sub.language == "en"
    assert sub.name == "English"
    assert sub.type == "SUBTITLES"
    assert sub.uri == "subtitles/eng/The_Chosen_S01E01_eng.m3u8"

    assert Enum.count(result.i_frame_renditions) == 1
    frame = hd(result.i_frame_renditions)
    assert frame.average_bandwidth == 246_620
    assert frame.bandwidth == 915_255
    assert frame.codecs == "hvc1.1.6.L150.b0"
    assert frame.resolution == "3840x2160"
    assert frame.resolution_width == 3840
    assert frame.resolution_height == 2160
    assert frame.uri == "some/path/goes/here"
  end

  test "media playlist for variant track parses correctly" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-TARGETDURATION:7
    #EXTINF:6.006,
    CHO_EP101_Angel-thechosen_270p/0000.ts
    #EXT-X-ENDLIST
    """

    result = HLS.parse(playlist)
    assert result.segments
    assert Enum.count(result.segments) == 1

    segment = hd(result.segments)
    assert segment.discontinuity == false
    assert segment.duration == 6.006
    assert segment.uri == "CHO_EP101_Angel-thechosen_270p/0000.ts"
  end

  test "media playlist for subtitle parses" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:6
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-TARGETDURATION:3276
    #EXTINF:3276.000,
    The_Chosen_S01E01_vtt_vie_20211130_214917/The_Chosen_S01E01_vtt_vie_20211130_214917.vtt
    #EXT-X-ENDLIST
    """

    result = HLS.parse(playlist)
    assert result.segments
    assert Enum.count(result.segments) == 1

    segment = hd(result.segments)
    assert segment.discontinuity == false
    assert segment.duration == 3276.0

    assert segment.uri ==
             "The_Chosen_S01E01_vtt_vie_20211130_214917/The_Chosen_S01E01_vtt_vie_20211130_214917.vtt"
  end

  test "media playlist for audio parses" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-TARGETDURATION:8
    #EXTINF:8.000,
    The_Chosen_S01E01_audio_spa_20211108_134000/0000.ts
    #EXT-X-ENDLIST
    """

    result = HLS.parse(playlist)
    assert result.segments
    assert Enum.count(result.segments) == 1

    segment = hd(result.segments)
    assert segment.discontinuity == false
    assert segment.duration == 8.0
    assert segment.uri == "The_Chosen_S01E01_audio_spa_20211108_134000/0000.ts"
  end

  test "parses and rebuilds a basic master playlist" do
    master_playlist = """
    #EXTM3U
    #EXT-X-VERSION:7
    #EXT-X-INDEPENDENT-SEGMENTS
    #EXT-X-STREAM-INF:BANDWIDTH=240000,RESOLUTION=396x224
    media.m3u8
    """

    result = HLS.parse(master_playlist)
    assert result.type == :master
    assert result.version == 7
    assert result.target_duration == nil
    assert result.media_sequence == nil
    assert result.discontinuity_sequence == nil
    assert result.independent_segments == true

    m3u8 = HLS.serialize(result)
    assert trim_manifest(m3u8) == trim_manifest(master_playlist)
  end

  test "parses and rebuilds vod manifest" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-STREAM-INF:BANDWIDTH=739200,CODECS="avc1.640015,mp4a.40.2",RESOLUTION=480x270,AUDIO="aud",SUBTITLES="subs"
    video/CHO_EP101_Angel-thechosen_270p.m3u8
    #EXT-X-MEDIA:TYPE=AUDIO,URI="audio/spa/The_Chosen_S01E01_audio_spa_20211108_134000.m3u8",GROUP-ID="aud",LANGUAGE="spa",NAME="Spanish",DEFAULT=NO,AUTOSELECT=YES,FORCED=NO,CHARACTERISTICS="public.accessibility.describes-video"
    #EXT-X-MEDIA:TYPE=SUBTITLES,URI="subtitles/eng/The_Chosen_S01E01_eng.m3u8",GROUP-ID="subs",LANGUAGE="en",NAME="English",DEFAULT=NO,AUTOSELECT=YES,FORCED=NO
    """

    result = HLS.parse(playlist)
    assert Enum.count(result.variants) == 1

    m3u8 = HLS.serialize(result)
    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "parses mux vod manifest" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:6
    #EXT-X-PLAYLIST-TYPE:VOD

    #EXTINF:5,
    https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/VlA7jHpLxGeVZBFgB02JgJv3RaifnajkFNru802kdY025L500iIqBhy938PIs5zJndf4EycAbX5Atjx2Q6q5n00PIBWPNFbDSa1ggxSoOv00T014pU/0.ts?skid=default&signature=NjMzZGZlNjBfNjNjNDM4OGFlNTUxNjc1NDE4ZTRkMGIxZTExZmMwYjcwOGY0M2RlNDM3ZDZkNWQyMzdjYjdjYWRhZTI4MWEyNA==
    #EXTINF:4.588800000000006,
    https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/sRyi2yvtzqpMaDeDpyGkDbHPlDwtz502rgyks01dtn01r00XU0001zRyoD5oOBBsFqnBDMLH1NBiPiSoT00ATx4oNFgMLG602nbN9SbmjQr72Dp7LGs/15.ts?skid=default&signature=NjMzZGZlNjBfOGEyZDQ0MWFhMDNlM2EzODhkM2Y5NWUxMGMzZTlmM2IwMjgyNzEwOGYxNjE3NzViNDI1ODM5MGFjNDc3ZDEyZQ==
    #EXT-X-ENDLIST
    """

    result = HLS.parse(playlist)
    m3u8 = HLS.serialize(result)

    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "parses program date time" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:5
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXT-X-PROGRAM-DATE-TIME:2022-09-30T00:49:07.030+00:00

    #EXTINF:4,
    https://chunk-gcp-us-east1-vop1.cfcdn.mux.com/v1/chunk/Rr3PtJCD7zye2tTIE7npiAYW5WfdPgdIpR01codCYr022GFR02WyYs2eKIiGlleYr8vqXt9O96E00XBGtsfLs9zMOCA8St6myWxCNyTRa5luHiw/0.ts?skid=default&signature=NjM0NDMzNzBfZDYwZDY2MmMxNjJlNzZhZjNkYjE5ZWZmOTdjZjE5NTFiZGU3MWM0ZDE2MjFkZjc2M2QwZTY1OTJmYjJjYWZhYg==
    #EXT-X-ENDLIST
    """

    result = HLS.parse(playlist)
    assert Enum.count(result.segments) == 1
    segment = hd(result.segments)
    assert segment.program_date_time == "2022-09-30T00:49:07.030+00:00"

    m3u8 = HLS.serialize(result)
    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "serializes multiple audio renditions" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3

    #EXT-X-MEDIA:TYPE=AUDIO,URI="some/path/eng.m3u8",GROUP-ID="audio-HIGH",LANGUAGE="en-US",NAME="English",DEFAULT=NO,AUTOSELECT=YES,FORCED=NO
    #EXT-X-MEDIA:TYPE=AUDIO,URI="some/path/spn.m3u8",GROUP-ID="audio-HIGH",LANGUAGE="en-US",NAME="English",DEFAULT=NO,AUTOSELECT=YES,FORCED=NO
    """

    result = HLS.parse(playlist)
    assert Enum.count(result.audio_renditions) == 2

    m3u8 = HLS.serialize(result)
    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "serializes simple trick play m3u8" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:7
    #EXT-X-MEDIA-SEQUENCE:0
    #EXT-X-IMAGES-ONLY
    #EXT-X-TARGETDURATION:1
    #EXT-X-PLAYLIST-TYPE:VOD

    #EXTINF:30.073,
    #EXT-X-TILES:RESOLUTION=284x160,LAYOUT=5x7,DURATION=0.970
    https://image.mux.com/YcYYGioMNCwEUtqQo02EvxiihxZd7YwM2/storyboard.jpg
    #EXT-X-ENDLIST
    """

    m3u8 = playlist |> HLS.parse() |> HLS.serialize()
    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "parses trick play master m3u8" do
    playlist = File.read!(Path.join([__DIR__, "examples", "trick_play_master_mux.m3u8"]))
    result = HLS.parse(playlist)

    assert length(result.image_renditions) == 1
    rendition = hd(result.image_renditions)
    assert not is_nil(rendition.uri)
  end

  test "parses trick play image playlist m3u8" do
    playlist = File.read!(Path.join([__DIR__, "examples", "trick_play_playlist_mux.m3u8"]))
    result = HLS.parse(playlist)

    assert length(result.segments) === 1
    segment = hd(result.segments)
    assert not is_nil(segment.uri)
  end

  test "serializes apple trick play playlist" do
    playlist = File.read!(Path.join([__DIR__, "examples", "apple_trick_play_playlist.m3u8"]))

    m3u8 =
      playlist
      |> HLS.parse()
      |> HLS.serialize()

    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end

  test "serializes apple trick play master" do
    playlist = File.read!(Path.join([__DIR__, "examples", "apple_trick_play_master.m3u8"]))

    m3u8 =
      playlist
      |> HLS.parse()
      |> HLS.serialize()

    assert trim_manifest(m3u8) == trim_manifest(playlist)
  end
end
