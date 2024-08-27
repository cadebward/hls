## v0.1.1 (2024-08-27)

- `AVERAGE-BANDWIDTH` _inside of the variant struct_ was still being parsed as a string. It is now parsed as an integer. Computers are so hard. Please forgive me.

## v0.1.0 (2024-08-02)

- BACKWARD INCOMPATIBLE CHANGE: `AVERAGE-BANDWIDTH` is now parsed as an integer. Previously parsed as a string.
- Fixed an issue introduced in 0.0.14 where many attributes would fail to parse, resulting in `nil` values.

## v0.0.14 (2024-08-01)

- ignore unknown tags when parsing m3u8 manifest. Previously we would attempt to parse everything, but we made assumptions it was formatted as key=value. When this assumption was incorrect, parsing would blow up.

## v0.0.13 (2024-07-22)

- add CHARACTERISTICS attribute

## v0.0.12 (2024-07-19)

- add parsing of resolution_width and resolution_height on i-frame structs

## v0.0.11 (2024-04-26)

- add support for CHANNELS attribute on X-STREAM-INF tags

## v0.0.10 (2024-04-23)

- add support for byte_range
- add support for EXT-X-I-FRAME-STREAM-INF

## v0.0.9 (2024-04-11)

- add `resolution_width` and `resolution_height` to the variant struct as parsed integers
- replace usage of `Kernel.then`

## v0.0.8 (2023-07-18)

- handle `EXT-X-ALLOW-CACHE` tag in hls playlist (#7) (@rajrajhans)
- remove deprecated Logger.warn

## v0.0.7 (2023-01-24)

- Add missing frame rate attribute (PR #5) (@ddresselhaus)

## v0.0.6 (2022-11-14)

- Fixes parsing and serialization for EXT-X-IMAGE-STREAM-INF (@omginbd)

## v0.0.5 (2022-11-10)

- Add support for EXT-X-IMAGE-STREAM-INF (@omginbd)

## v0.0.4 (2022-10-17)

- Add proper spacing when serializing EXT-X-MEDIA tags

## v0.0.3 (2022-10-03)

- Added support for EXT-X-PROGRAM-DATE-TIME

## v0.0.2 (2022-10-02)

- Fix bugs

## v0.0.1 (2022-10-02)

- Add `HLS.serialize` to produce a text file from an `HLS.Manifest` struct.

## v0.0.1-dev (2022-08-21)

- Initial Release
