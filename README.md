# HLS

[Online Documenation](https://hexdocs.pm/hls).

<!-- MDOC !-->

`HLS` is a simple and fast library for parsing and building HLS manifests.

## Examples

```elixir
master_playlist = """
#EXTM3U
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

HLS.parse(master_playlist)
#=> %HLS.Manifest{type: :master, variants: [%HLS.Variant{}], ...}
```

The result of `HLS.parse/1` will be an `HLS.Manifest` struct. This struct will
contain all the data from the .m3u8 files, parsed into elixir data types.

## Installation

Add `hls` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:hls, "~> 0.1"}
  ]
end
```

