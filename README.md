# UniversalPlayer

English | [中文](#中文)

A Swift audio parsing layer written directly on Core Audio. It takes an MP3/AAC stream or file, runs it through `AudioFileStream` / `AudioFile`, and hands back decoded packets, format description, bit rate, duration and seek offsets. The engine code has no third-party dependencies.

## What is here

| File | Role |
| --- | --- |
| `Modules/Audio/AudioStreamManager.swift` | Streaming parser on top of `AudioFileStreamOpen` / `AudioFileStreamParseBytes`. Feed it `Data` chunks as they arrive from the network or disk. |
| `Modules/Audio/YYAudioFile.swift` | Local-file parser on top of `AudioFileOpenWithCallbacks` / `AudioFileReadPacketData`. Reads packets through custom read/size callbacks instead of letting Core Audio touch the file. |
| `Modules/Audio/AudioParsedData.swift` | One parsed packet: raw bytes plus its `AudioStreamPacketDescription`. |
| `Modules/Audio/AudioTool.swift` | `AVAudioSession` setup, interruption handling, and `OSStatus` to `NSError` mapping. |
| `ViewController.swift` | Demo entry point that parses a bundled MP3 with both parsers. |

### AudioStreamManager

- Property listener handles `kAudioFileStreamProperty_ReadyToProducePackets`, `DataFormat`, `FormatList` (picks the first format with an available decoder), `AudioDataByteCount` and `DataOffset`.
- Packets callback handles both VBR and CBR input. When Core Audio returns no packet descriptions (CBR), it synthesizes them so the caller always gets per-packet offsets and sizes.
- Bit rate is estimated from the first N packets, then duration is derived from bit rate and audio data byte count. Packet duration is derived from the stream format.
- `seekTo(time:)` converts a time to a byte offset using packet duration and data offset, and resets the parser so the next parsed bytes are treated as a discontinuity.
- `fetchMagicCookie()` reads the magic cookie needed to configure a decoder for AAC and similar formats.
- Results go out through `AudioStreamDelegate`: `finishParseProperty` once the header is parsed, `audioDataParsed` for each batch of packets.

### YYAudioFile

- Opens the file with read and size callbacks, so the same class can be pointed at a partially downloaded file.
- Reads `FormatList`, `BitRate`, `DataOffset`, `EstimatedDuration`, `PacketSizeUpperBound` / `MaximumPacketSize`, the magic cookie, and the info dictionary (ID3-style metadata).
- `parseData(isEof:)` reads a fixed-size batch of packets and returns `[AudioParsedData]`, advancing an internal packet offset.

## Status

This repository covers the parsing half of a player. Output (`AudioQueue` / `AudioUnit`), buffering and the public player API are not in this repository yet. `StreamingKit` appears in the Podfile only as a reference implementation to compare against; the engine does not import it.

## Build

Xcode, iOS 9.0+, Swift 5. Run `pod install` and open the workspace. The demo parses the MP3 bundled in the app target and prints the format, bit rate, duration and packet count.

---

# 中文

一个直接基于 Core Audio 写的 Swift 音频解析层。给它一段 MP3/AAC 的流或者本地文件，它用 `AudioFileStream` / `AudioFile` 解析，返回音频包、格式描述、码率、时长和 seek 偏移。引擎代码不依赖任何第三方库。

## 代码结构

| 文件 | 作用 |
| --- | --- |
| `Modules/Audio/AudioStreamManager.swift` | 流式解析器，封装 `AudioFileStreamOpen` / `AudioFileStreamParseBytes`。网络或磁盘来一段 `Data` 就喂一段。 |
| `Modules/Audio/YYAudioFile.swift` | 本地文件解析器，封装 `AudioFileOpenWithCallbacks` / `AudioFileReadPacketData`。用自定义的读取和取长度回调读包，不让 Core Audio 直接碰文件。 |
| `Modules/Audio/AudioParsedData.swift` | 一个解析出来的包：原始字节加它的 `AudioStreamPacketDescription`。 |
| `Modules/Audio/AudioTool.swift` | `AVAudioSession` 配置、打断处理、`OSStatus` 转 `NSError`。 |
| `ViewController.swift` | 示例入口，用两种解析器解析一个内置 MP3。 |

### AudioStreamManager

- 属性监听处理 `kAudioFileStreamProperty_ReadyToProducePackets`、`DataFormat`、`FormatList`（选第一个本机有解码器的格式）、`AudioDataByteCount`、`DataOffset`。
- 包回调同时支持 VBR 和 CBR。Core Audio 不返回包描述（CBR）时自己按平均包长补出来，调用方拿到的每个包都有偏移和长度。
- 码率用前 N 个包估算，时长由码率和音频数据总字节数推出，包时长由流格式推出。
- `seekTo(time:)` 用包时长和数据偏移把时间换算成字节偏移，并重置解析器，下一段数据按不连续处理。
- `fetchMagicCookie()` 读取 AAC 这类格式配置解码器需要的 magic cookie。
- 结果通过 `AudioStreamDelegate` 回传：头部解析完回调 `finishParseProperty`，每批包回调 `audioDataParsed`。

### YYAudioFile

- 用读取和取长度回调打开文件，所以同一个类也能指向一个还没下载完的文件。
- 读取 `FormatList`、`BitRate`、`DataOffset`、`EstimatedDuration`、`PacketSizeUpperBound` / `MaximumPacketSize`、magic cookie 和 info dictionary（ID3 之类的元数据）。
- `parseData(isEof:)` 每次读固定数量的包，返回 `[AudioParsedData]`，内部维护包偏移。

## 当前状态

这个仓库是播放器的解析这一半。输出（`AudioQueue` / `AudioUnit`）、缓冲和对外的播放器接口还没有放进来。Podfile 里的 `StreamingKit` 只是用来对照的参考实现，引擎代码没有引用它。

## 构建

Xcode，iOS 9.0+，Swift 5。`pod install` 后打开 workspace。示例会解析 app 内置的 MP3，并打印格式、码率、时长和包数量。
