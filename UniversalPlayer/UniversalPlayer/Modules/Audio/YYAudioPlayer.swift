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

class YYAudioPlayer: NSObject {
    let filePath: String!
    let fileType: AudioFileTypeID!
    /// 是否成功创建?
    private (set) var doesSuccessfullyInit = false
    
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
    
    private var audioFileStream: AudioStreamManager?
    private var audioFile: YYAudioFile?
    private var audioQueue: YYAudioOutputQueue?
    
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
        
        doesSuccessfullyInit = true
        
    }

    deinit {
        cleanup()
        fileHandler?.closeFile()
        
    }
    
    private func cleanup() {
        offset = 0
        fileHandler?.seek(toFileOffset: 0)
        
        #warning("待实现_处理通知")
        
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
    
}
