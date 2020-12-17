//
//  YYAudioPlayer.swift
//  UniversalPlayer
//
//  Created by X.Young on 2020/8/30.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import CoreAudio
import AudioToolbox

enum PlayerStatus: Int {
    case Stopped = 0
    case Playing
    case Waiting
    case Paused
    case Flushing
    
}

enum PlayerRealizeMode: Int {
    case AudioStream = 0
    case AudioFile
    
}

enum PlayerOperatingType: Int {
    /// 需要暂停
    case pauseRequired = 0
    /// 需要停止
    case stopRequired
    /// 打断导致暂停
    case pausedByInterrupt
    
}

class YYAudioPlayer: NSObject {
    let filePath: String!
    let fileType: AudioFileTypeID!
    /// 是否成功创建?
    private (set) var isSuccessed = false
    
    private (set) var currentStatus: PlayerStatus = .Stopped
    /// 实现方式
    private (set) var realizeMode: PlayerRealizeMode?
    private (set) var isPlayingOrWaiting = false
    
    private (set) var progress: TimeInterval = 0
    private (set) var duration: TimeInterval = 0
    
    // * 线程相关
    private var thread = Thread.init()
    private var mutex = pthread_mutex_t.init()
    private var cond = pthread_cond_t.init()
    
    private var fileSize: Int64 = 0
    private var offset: Int64 = 0
    private var fileHandler: FileHandle?
    
    private var bufferSize: UInt32 = 0
    private var buffer: YYAudioBuffer = YYAudioBuffer.default
    
    private var audioFileStream: YYAudioStreamManager?
    private var audioFile: YYAudioFile?
    private var audioQueue: YYAudioOutputQueue?
    
    private (set) var started = false
    private (set) var operatingType: PlayerOperatingType?
    
    private var seekRequired = false
    private var seekTime: TimeInterval = 0
    private var timingOffset: TimeInterval = 0
    
    
    init(filePath: String, fileType: AudioFileTypeID = 0) {
        self.filePath = filePath
        self.fileType = fileType
        
        super.init()
        
        fileHandler = FileHandle.init(forReadingAtPath: filePath)
        fileSize = try! FileManager.default.attributesOfItem(atPath: filePath)[.size] as! Int64
        
        guard fileHandler != nil, fileSize > 0 else {
            fileHandler?.closeFile()
            return
            
        }
        
        isSuccessed = true
        
    }

    deinit {
        cleanup()
        fileHandler?.closeFile()
        
    }
    
    private func cleanup() {
        offset = 0
        fileHandler?.seek(toFileOffset: 0)
        
        buffer.clean()
        
        audioFileStream?.closeAudioFileStream()
        audioFileStream = nil
        audioFile?.closeAudioFile()
        audioFile = nil
        if let error = audioQueue?.stop(immediately: true) {
            print(error)
            
        }
        audioQueue = nil
        
        mutexDestory()
        
        started = false
        
        operatingType = nil
        
        seekRequired = false
        seekTime = 0
        timingOffset = 0
        
        currentStatus = .Stopped
        
    }
    

}

// MARK: - pthead - mutex
extension YYAudioPlayer {
    private func mutexInit() {
        pthread_mutex_init(&mutex, nil)
        pthread_cond_init(&cond, nil)
        
    }
    
    private func mutexDestory() {
        pthread_mutex_destroy(&mutex)
        pthread_cond_destroy(&cond)
    }
    
    private func mutexWait() {
        pthread_mutex_lock(&mutex)
        pthread_cond_wait(&cond, &mutex)
        pthread_mutex_unlock(&mutex)
    }
    
    private func mutexSignal() {
        pthread_mutex_lock(&mutex)
        pthread_cond_signal(&cond)
        pthread_mutex_unlock(&mutex)
        
    }
    
}

// MARK: - thread & audioQueue
extension YYAudioPlayer {
    private func createAudioQueue() -> Bool {
        if audioQueue != nil {
            return true
            
        }
        
        let tmpDuration = duration
        let audioDataByteCount: UInt64 = {
            
            if realizeMode == .AudioStream {
                return audioFileStream!.audioDataByteCount
                
            }else if realizeMode == .AudioFile {
                return audioFile!.audioDataByteCount
                
            }else {
                return 0
                
            }
            
        }()
        
        if audioDataByteCount == 0 {
            return false
            
        }
        
        
        bufferSize = 0
        
        if tmpDuration != 0 {
            bufferSize = UInt32((0.2 / tmpDuration) * Double(audioDataByteCount))
            
        }
        
        if bufferSize > 0 {
            let format = realizeMode == .AudioStream ? audioFileStream!.format : audioFile!.format
            let magicCookie = realizeMode == .AudioStream ? audioFileStream!.fetchMagicCookie() : audioFile!.fetchMagicCookie()
            
            audioQueue = YYAudioOutputQueue.init(format: format, bufferSize: bufferSize, magicCookie: magicCookie)
            
            if audioQueue!.doesSuccessfullyInit() == true {
                return true
                
            }else {
                audioQueue = nil
                return false
                
            }
            
            
        }else {
            return false
            
        }
        
        
    }
    
    private func threadMain() {
        isSuccessed = false
        
        if let error = YYAudioSession.shared.setupAudioSession() {
            print(error)
            
        }else {
            audioFileStream = YYAudioStreamManager.init(fileSize: UInt64(fileSize))
            
            if let error = audioFileStream!.openAudioFileStream() {
                print(error)
                
            }else {
                isSuccessed = true
                audioFileStream!.delegate = self
            }
            
        }
        
        
        if isSuccessed == false {
            // * cleanUP
            cleanup()
            return
        }
        
        currentStatus = .Waiting
        var isEof = false
        
        
        autoreleasepool {
            
            whileLoop: while currentStatus != .Stopped, isSuccessed == true, started == true {
                
                if realizeMode == .AudioFile {
                    if audioFile == nil {
                        audioFile = YYAudioFile.init(filePath: filePath)
                        
                    }
                    
                    audioFile!.seekTo(time: seekTime)
                    
                    if buffer.bufferedSize < bufferSize || audioQueue == nil {
                        let parsedDatas = audioFile!.parseData(isEof: &isEof)
                        
                        if let datas = parsedDatas {
                            buffer.enqueue(from: datas)
                            
                        }else {
                            isSuccessed = false
                            break whileLoop
                            
                        }
                        
                        
                    }
                    
                    
                    
                }else if realizeMode == .AudioStream {
                    if offset < fileSize && audioFileStream?.readyToProducePackets == false || buffer.bufferedSize < bufferSize || audioQueue == nil {
                        
                        if let data = fileHandler?.readData(ofLength: 1000) {
                            offset += Int64(data.count)
                            
                            if offset >= fileSize {
                                isEof = true
                                
                            }
                            
                            
                            if audioFileStream!.parseData(data: data) != nil {
                                realizeMode = .AudioFile
                                continue whileLoop
                                
                            }

                        }
                        
                    }
                    
                    
                }
                
                if audioFileStream?.readyToProducePackets == true || realizeMode == .AudioFile {
                    
                    if createAudioQueue() == false {
                        isSuccessed = false
                        break whileLoop
                        
                    }
                    
                    if audioQueue == nil {
                        continue whileLoop
                        
                    }
                    
                    if currentStatus == .Flushing, audioQueue!.isRunning == false {
                        break whileLoop
                        
                    }
                    
                    if let type = operatingType {
                        runOperation(with: type, handler: {
                            operatingType = nil
                        
                        })
                        
                        if type == .stopRequired {
                            break whileLoop
                            
                        }
                        
                    }
                    
                    if buffer.bufferedSize >= bufferSize || isEof {
                        var packetCount: UInt32 = 0
                        var descesPointer: UnsafeMutablePointer<AudioStreamPacketDescription>? = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: MemoryLayout<AudioStreamPacketDescription>.size)
                        
                        var playData = buffer.dequeueData(requestSize: bufferSize, packetCountPointer: &packetCount, descriptionsPointer: &descesPointer)
                        
                        defer {
                            free(descesPointer)
                        }
                        
                        if packetCount != 0 {
                            currentStatus = .Playing
                            
                            if let data = playData {
                                
                                if let error = audioQueue?.play(with: data, packetCount: packetCount, inPacketDescs: descesPointer, isEof: isEof) {
                                    
                                    break whileLoop
                                }
                                
                                if buffer.bufferBlockArray.count > 0, audioQueue?.isRunning == true {
                                    let _ = audioQueue?.stop(immediately: false)
                                    
                                    
                                }
                                
                                
                                 
                            }
                            
                            
                            
                        }
                        
                        
                        
                    }
                    
                }
                
                
            }
            
        }
        
        
        
        
        
    }
    
    /// 执行操作
    private func runOperation(with type: PlayerOperatingType, handler: (() -> Void)) {
        switch type {
        case .pauseRequired:
            currentStatus = .Paused
            let _ = audioQueue?.pause()
            mutexWait()
            
            break
            
        case .stopRequired:
            started = false
            let _ = audioQueue?.stop(immediately: true)
            
            break
            
        case .pausedByInterrupt:
            break
            
        default:
            break
            
        }
        
        handler()
        
    }
    
}

// MARK: - YYAudioStreamDelegate
extension YYAudioPlayer: YYAudioStreamDelegate {
    func finishParseProperty(manager: YYAudioStreamManager) {
        
        
    }
    
    func audioDataParsed(manager: YYAudioStreamManager, datas: [YYAudioParsedData]) {
        
        
    }
    
    
    
}
