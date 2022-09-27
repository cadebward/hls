defmodule HLSTest do
  use ExUnit.Case
  doctest HLS

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
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224
    media.m3u8
    """

    result = HLS.parse(master_playlist)
    assert Enum.count(result.variants) == 1

    variant = hd(result.variants)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == "240000"
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
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
    assert variant.bandwidth == "240000"
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
    assert variant.uri == "media.m3u8"

    variant = Enum.at(result.variants, 1)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == "240000"
    assert variant.codecs == nil
    assert variant.resolution == "396x224"
    assert variant.uri == "media.m3u8"
  end

  test "one of everything" do
    playlist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",LANGUAGE="spa",NAME="Spanish",AUTOSELECT=YES,DEFAULT=NO,URI="audio/spa/The_Chosen_S01E01_audio_spa_20211108_134000.m3u8"
    #EXT-X-MEDIA:TYPE=SUBTITLES,AUTOSELECT=YES,DEFAULT=NO,FORCED=NO,GROUP-ID="subs",LANGUAGE="en",NAME="English",URI="subtitles/eng/The_Chosen_S01E01_eng.m3u8"
    #EXT-X-STREAM-INF:BANDWIDTH=739200,RESOLUTION=480x270,CODECS="avc1.640015,mp4a.40.2",AUDIO="aud",SUBTITLES="subs"
    video/CHO_EP101_Angel-thechosen_270p.m3u8
    """

    result = HLS.parse(playlist)

    assert Enum.count(result.variants) == 1
    variant = hd(result.variants)
    assert variant.average_bandwidth == nil
    assert variant.bandwidth == "739200"
    assert variant.resolution == "480x270"
    assert variant.codecs == "avc1.640015,mp4a.40.2"

    assert Enum.count(result.audio_renditions) == 1
    audio = hd(result.audio_renditions)
    assert audio.autoselect == true
    assert audio.default == true
    assert audio.forced == false
    assert audio.group_id == "aud"
    assert audio.language == "spa"
    assert audio.name == "Spanish"
    assert audio.type == "AUDIO"
    assert audio.uri == "audio/spa/The_Chosen_S01E01_audio_spa_20211108_134000.m3u8"

    assert Enum.count(result.subtitle_renditions) == 1
    sub = hd(result.subtitle_renditions)
    assert sub.autoselect == true
    assert sub.default == true
    assert sub.forced == true
    assert sub.group_id == "subs"
    assert sub.language == "en"
    assert sub.name == "English"
    assert sub.type == "SUBTITLES"
    assert sub.uri == "subtitles/eng/The_Chosen_S01E01_eng.m3u8"
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
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224
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
    assert m3u8 == master_playlist
  end
end
