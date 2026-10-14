# UniversalPlayer

English | [中文](#中文)

A streaming audio player for iOS written in Swift directly on Core Audio: `AudioFileStream` / `AudioFile` for parsing, a hand-rolled packet buffer, and `AudioQueue` for output. No third-party audio library in the engine. Playback is currently driven from code (play, pause, stop, seek); there is no player UI yet.

## Pipeline

```
network / file  ->  parse  ->  buffer  ->  AudioQueue  ->  speaker
                 AudioFileStream   YYAudioBuffer   YYAudioOutputQueue
                 AudioFile
```

| Class | Role |
| --- | --- |
| `YYAudioPlayer` | The player. Owns a dedicated playback thread, a state machine (`Stopped` / `Playing` / `Waiting` / `Paused` / `Flushing`) and the pause / stop / interrupt operations, synchronized with a pthread mutex and condition. Can run in `AudioStream` mode (progressive bytes) or `AudioFile` mode (local file). |
| `YYAudioStreamManager` | Streaming parser on `AudioFileStreamOpen` / `AudioFileStreamParseBytes`. Handles format list, data offset, VBR and CBR packets, magic cookie, bit rate and duration estimation, and time-to-byte-offset seeking. |
| `YYAudioFile` | Local parser on `AudioFileOpenWithCallbacks` / `AudioFileReadPacketData` with custom read and size callbacks, so it also works on a file that is still downloading. Reads format, bit rate, duration, packet size bounds, magic cookie and the info dictionary. |
| `YYAudioBuffer` | Packet queue between parser and output. Enqueues parsed packets, dequeues by requested byte size and rebuilds the packet descriptions for the queue buffer. |
| `YYAudioOutputQueue` | `AudioQueue` wrapper: creates the output queue from the stream format, allocates and recycles queue buffers, enqueues data, `start` / `pause` / `stop`, applies the magic cookie. |
| `YYAudioSession` | `AVAudioSession` category setup and interruption notifications, forwarded to the player so playback pauses on a phone call and resumes after. |
| `YYAudioParsedData` | One parsed packet: bytes plus `AudioStreamPacketDescription`. |

## How playback runs

1. The player opens the source and starts parsing. Parsed packets go into `YYAudioBuffer`.
2. The playback thread waits until the buffer holds enough bytes for one queue buffer (sized to about 0.2 s of audio from duration and data byte count), then creates the `AudioQueue` with the stream format and magic cookie.
3. Each loop iteration dequeues one buffer's worth of packets, enqueues it to the queue, and goes back to parsing. When parsing is behind, the state becomes `Waiting`; at end of file the queue is flushed and stopped.
4. Pause, stop and seek are requested from any thread and executed on the playback thread. Seek converts the target time to a byte offset through the parser, clears the buffer and resets the queue.

## Build

Xcode, iOS 9.0+, Swift 5. Run `pod install` and open the workspace. The demo view controller plays an MP3 bundled with the app target. The player classes live on the `Dev_AudioQueue` branch; `master` holds the parsing layer.

---

# 中文

一个直接基于 Core Audio 写的 iOS 流式音频播放器，Swift 实现：`AudioFileStream` / `AudioFile` 负责解析，自己写的包缓冲，`AudioQueue` 负责输出。引擎里不用任何第三方音频库。播放目前在代码里控制（播放、暂停、停止、seek），还没有播放器界面。

## 流水线

```
网络 / 文件  ->  解析  ->  缓冲  ->  AudioQueue  ->  扬声器
              AudioFileStream   YYAudioBuffer   YYAudioOutputQueue
              AudioFile
```

| 类 | 作用 |
| --- | --- |
| `YYAudioPlayer` | 播放器本体。独立的播放线程，状态机（`Stopped` / `Playing` / `Waiting` / `Paused` / `Flushing`），暂停、停止、被打断这些操作用 pthread 互斥锁和条件变量同步。支持 `AudioStream`（边下边播）和 `AudioFile`（本地文件）两种模式。 |
| `YYAudioStreamManager` | 流式解析器，封装 `AudioFileStreamOpen` / `AudioFileStreamParseBytes`。处理格式列表、数据偏移、VBR 和 CBR 包、magic cookie、码率和时长估算，以及时间到字节偏移的 seek。 |
| `YYAudioFile` | 本地解析器，封装 `AudioFileOpenWithCallbacks` / `AudioFileReadPacketData`，用自定义的读取和取长度回调，所以对还没下载完的文件也能用。读取格式、码率、时长、包长上限、magic cookie 和 info dictionary。 |
| `YYAudioBuffer` | 解析和输出之间的包队列。入队解析出来的包，按请求的字节数出队，并为队列缓冲重建包描述。 |
| `YYAudioOutputQueue` | `AudioQueue` 封装：按流格式创建输出队列，分配和回收队列缓冲，入队数据，`start` / `pause` / `stop`，设置 magic cookie。 |
| `YYAudioSession` | `AVAudioSession` 分类设置和打断通知，转发给播放器，来电时暂停、结束后恢复。 |
| `YYAudioParsedData` | 一个解析出来的包：字节加 `AudioStreamPacketDescription`。 |

## 播放流程

1. 播放器打开音源开始解析，解析出来的包进 `YYAudioBuffer`。
2. 播放线程等缓冲里攒够一个队列缓冲的字节数（按时长和数据总字节数算，约 0.2 秒音频），再用流格式和 magic cookie 创建 `AudioQueue`。
3. 每轮循环出队一个缓冲的包，入队到 AudioQueue，然后回去继续解析。解析跟不上时状态变成 `Waiting`；文件读完后把队列刷完再停。
4. 暂停、停止、seek 可以从任意线程发起，在播放线程执行。seek 通过解析器把目标时间换算成字节偏移，清空缓冲并重置队列。

## 构建

Xcode，iOS 9.0+，Swift 5。`pod install` 后打开 workspace。示例控制器会播放 app 内置的一首 MP3。播放器相关的类在 `Dev_AudioQueue` 分支，`master` 是解析层。
