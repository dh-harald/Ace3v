# LibDeflate

Pure Lua DEFLATE / zlib compressor and decompressor, with the printable and
WoW-channel encodings. WoW 1.12.1 (Lua 5.0) and Unreal Azeroth (Lua 5.1) port
of LibDeflate 1.0.2 by Haoqian He (SafeteeWoW), API-compatible. License: zlib
(see `LICENSE`); this is an altered version, marked as such in the file
header.

## Dependencies

```
LibStub\LibStub.lua
LibDeflate\LibDeflate.xml
```

LibStub is optional: without it the library is the file's return value.

## Loading / usage

```xml
<Include file="Libs\LibDeflate\LibDeflate.xml"/>
```

```lua
local LibDeflate = LibStub("LibDeflate")
local compressed = LibDeflate:CompressDeflate(data, { level = 9 })
local printable = LibDeflate:EncodeForPrint(compressed)
local back = LibDeflate:DecompressDeflate(LibDeflate:DecodeForPrint(printable))
```

The full API is the original's: `CompressDeflate`, `CompressDeflateWithDict`,
`CompressZlib`, `CompressZlibWithDict`, the matching `Decompress*`,
`CreateDictionary`, `Adler32`, `CreateCodec`, `EncodeForPrint` /
`DecodeForPrint`, `EncodeForWoWAddonChannel` / `DecodeForWoWAddonChannel`,
`EncodeForWoWChatChannel` / `DecodeForWoWChatChannel`.

## Differences from the original

Registered with LibStub as `"LibDeflate"`, MINOR 1 (the original is MINOR 3:
on a Lua 5.1 client an addon shipping the original replaces this copy, which
is harmless — same API).

What Lua 5.0 needed:

- `%` → a local `mod(a, b)` with the same floored semantics
  (`a - floor(a / b) * b`); `#` → `string.len` on strings and explicit size
  counters on arrays. `table.getn` is only used outside hot loops: on Lua 5.0
  it counts the array on every call, which made the LZ77 hash chains
  quadratic. Hash chains keep their length in the field `n`.
- `string.byte(s, i, j)` returns one byte on Lua 5.0, so every multi-byte
  read (the unrolled Adler-32, `LoadStringToTable`, the bit reader, the
  6-bit codec) reads byte by byte.
- `string.gsub` takes no table as the replacement on Lua 5.0: the codecs use
  a function that looks the capture up (`TableReplacement`).
- String methods (`str:sub`, `("..."):format`) do not exist on Lua 5.0 →
  `string.*` calls.
- The `until` condition of a `repeat` loop does not see the loop body's
  locals on Lua 5.0; the decoder's `symbol` is declared before its loop.
- The command-line interface at the end of the original file is removed.

## Tests

Offline tests on Lua 5.0.3 with a cross-check against the real zlib are kept
in the PunyAuras development tree, outside this repository: round trips at
every level and
strategy (including inputs over the 64 KB first block), dictionaries, the
three codecs, zlib inflating this library's output, and this library
inflating zlib's.
