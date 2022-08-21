defmodule HLS.M3ULineTest do
  use ExUnit.Case

  alias HLS.M3ULine

  test "parses #EXTM3U" do
    assert M3ULine.build("#EXTM3U") == %HLS.M3ULine{
             attributes: %{},
             raw: "#EXTM3U",
             tag_name: "EXTM3U",
             type: :tag,
             value: ""
           }
  end

  test "parses #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224" do
    assert M3ULine.build("#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224") ==
             %HLS.M3ULine{
               attributes: %{
                 "BANDWIDTH" => "240000",
                 "PROGRAM-ID" => "1",
                 "RESOLUTION" => "396x224"
               },
               raw: "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224",
               tag_name: "EXT-X-STREAM-INF",
               type: :tag,
               value: "PROGRAM-ID=1,BANDWIDTH=240000,RESOLUTION=396x224"
             }
  end

  test "parses http://example.com/media1.m3u8 into a URI type" do
    assert M3ULine.build("http://example.com/media1.m3u8") == %HLS.M3ULine{
             attributes: %{},
             raw: "http://example.com/media1.m3u8",
             tag_name: "URI",
             type: :uri,
             value: "http://example.com/media1.m3u8"
           }
  end
end
