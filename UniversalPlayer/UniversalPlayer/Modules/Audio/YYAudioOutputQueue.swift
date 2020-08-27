//
//  YYAudioOutputQueue.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/8/20.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AudioToolbox

class YYAudioOutputQueue: NSObject {
    var volume: Double = 0.0 {
        didSet {
            // * 设置音量
            let _ = AudioQueueSetProperty(audioQueue!, kAudioQueueParam_Volume, &volume, UInt32(MemoryLayout.size(ofValue: volume)))
            
        }
        
    }
    private (set) var playedTime: TimeInterval {
        set {


        }
        
        get {
            if format.mSampleRate == 0 {
                return 0
                
            }
            
            var timeStamp = AudioTimeStamp.init()
            let status = AudioQueueGetCurrentTime(audioQueue!, nil, &timeStamp, nil);
            
            if let error = AudioTool.shared.decideStatus(status) {
                print(error)
                return 0
                
            }
            
            return timeStamp.mSampleTime / format.mSampleRate
        }
    }
    
    private (set) var isRunning = false
    private (set) var isStartedPlaying = false
    private (set) var available = false
    
    private var format: AudioStreamBasicDescription!
    private let bufferSize: UInt32!
    private var buffer: AudioQueueBufferRef!
    private var yyBufferList: [YYAudioQueueBuffer] = []
    private var reusableYYBufferList: [YYAudioQueueBuffer] = []
    private var audioQueue: AudioQueueRef?
    
    private var mutex = pthread_mutex_t.init()
    private var cond = pthread_cond_t.init()
    
    init(format: AudioStreamBasicDescription, bufferSize: UInt32, magicCookie: Data?) {
        self.format = format
        self.bufferSize = bufferSize
        
        super.init()
        
        createAudioOutputQueue(with: magicCookie)
        mutexInit()
        
    }
    
    deinit {
        disposeAudioOutputQueue()
        mutexDestory()
    }

}

extension YYAudioOutputQueue {
    private func createAudioOutputQueue(with magicCookie: Data?) {
        let userData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        var status = AudioQueueNewOutput(&format, YYAudioOutputQueue.audioQueueOutputCallback, userData, nil, nil, 0, &audioQueue)
        if let error = AudioTool.shared.decideStatus(status) {
            audioQueue = nil
            
            print(error)
            return
        }
        
        status = AudioQueueAddPropertyListener(audioQueue!, kAudioQueueProperty_IsRunning, YYAudioOutputQueue.audioQueuePropertyListenerProc, userData)
        if let error = AudioTool.shared.decideStatus(status) {
            AudioQueueDispose(audioQueue!, true);
            audioQueue = nil
            
            print(error)
            return
        }
        
        if yyBufferList.count == 0 {
            for _ in 0 ..< YYAudioOutputQueue.AudioQueueBufferCount {
                var buffer: AudioQueueBufferRef? = nil
                if let error = AudioTool.shared.decideStatus(AudioQueueAllocateBuffer(audioQueue!, bufferSize, &buffer)) {
                    AudioQueueDispose(audioQueue!, true);
                    audioQueue = nil
                    
                    print(error)
                    return
                }
                
                let bufferObj = YYAudioQueueBuffer.init(buffer: buffer!)
                yyBufferList.append(bufferObj)
                reusableYYBufferList.append(bufferObj)
                
            }
            
        }
        
        #if TARGET_OS_IPHONE // * 如果是真机
        var property = kAudioQueueProperty_HardwareCodecPolicy
        
        let _ = AudioQueueSetProperty(audioQueue!, kAudioQueueProperty_HardwareCodecPolicy, property, UInt32(MemoryLayout.size(ofValue: property)))
        
        #endif
        
        if let cookie = magicCookie {
            let _ = AudioQueueSetProperty(audioQueue!, kAudioQueueProperty_MagicCookie, (cookie as NSData).bytes, UInt32(cookie.count))
            
        }
        
        // * 设置音量
        volume = 1.0
        
    }
    
    private func disposeAudioOutputQueue() {
        if let queue = audioQueue {
            AudioQueueDispose(queue, true)
            audioQueue = nil
            
        }
        
    }
    
}

// MARK: - 播放控制
extension YYAudioOutputQueue {
    func start() -> NSError? {
        let status = AudioQueueStart(audioQueue!, nil)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        isStartedPlaying = true
        return nil

    }
    
    func pause() -> NSError? {
        let status = AudioQueuePause(audioQueue!)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        isStartedPlaying = false
        return nil
    }
    
    func reset() -> NSError? {
        let status = AudioQueueReset(audioQueue!)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        return nil
    }
    
    func flush() -> NSError? {
        let status = AudioQueueFlush(audioQueue!)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        return nil
    }
    
    func stop(immediately signal: Bool) -> NSError? {
        let status = AudioQueueStop(audioQueue!, signal)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        isStartedPlaying = false
        playedTime = 0
        
        return nil
    }
    
    func play(with data: Data, packetCount: UInt32, inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?, isEof: Bool) -> NSError? {
        
        if data.count > bufferSize {
            return NSError.init(domain: "bufferSize长度问题", code: 205, userInfo: nil)
            
        }
        
        if reusableYYBufferList.count == 0 {
            if isStartedPlaying == false, let error = start() {
                return error
                
            }
            
            mutexWait()
            
        }
        
        var status: OSStatus
        
        var bufferObj: YYAudioQueueBuffer
        var buffer = AudioQueueBufferRef.init(bitPattern: 0)
        
        
        if reusableYYBufferList.count == 0 {
            status = AudioQueueAllocateBuffer(audioQueue!, bufferSize, &buffer)
            
            if let error = AudioTool.shared.decideStatus(status) {
                return error
                
            }
            
            bufferObj = YYAudioQueueBuffer.init(buffer: buffer!)
            
        }else {
            bufferObj = reusableYYBufferList.removeFirst()
            
        }
        
        memcpy(bufferObj.buffer.pointee.mAudioData, (data as NSData).bytes, data.count)
        bufferObj.buffer.pointee.mAudioDataByteSize = UInt32(data.count)
        status = AudioQueueEnqueueBuffer(audioQueue!, bufferObj.buffer, packetCount, inPacketDescs)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }
        
        if reusableYYBufferList.count == 0 || isEof {
            if isStartedPlaying == false, let error = start() {
                return error
                
            }
            
        }
        
        
        
        return nil
        
    }
    
}


// MARK: - 静态监听 & 处理
extension YYAudioOutputQueue {
    static private let audioQueueOutputCallback: AudioQueueOutputCallback = { (userData, inAQ, inBuffer) in
        if let pointer = userData {
            let audioOutputQueue: YYAudioOutputQueue = GenericFuncs.shared.bridge(ptr: UnsafeRawPointer.init(pointer))
            audioOutputQueue.handleOutputCallback(inAQ: inAQ, inBuffer: inBuffer)
            
        }
        
        
    }
    
    private func handleOutputCallback(inAQ: AudioQueueRef, inBuffer: AudioQueueBufferRef) {
        for index in 0 ..< yyBufferList.count {
            let currentBuffer = yyBufferList[index]
            
            if inBuffer == currentBuffer.buffer {
                reusableYYBufferList.append(currentBuffer)
                break
                
            }
            
        }
        
        mutexSignal()
        
    }
    
    
    static private let audioQueuePropertyListenerProc: AudioQueuePropertyListenerProc = { (userData, inAQ, inId) in
        if let pointer = userData {
            let audioOutputQueue: YYAudioOutputQueue = GenericFuncs.shared.bridge(ptr: UnsafeRawPointer.init(pointer))
            audioOutputQueue.handlePropertyListenerProc(audioQueue: inAQ, property: inId)
            
        }
        
    }
    
    private func handlePropertyListenerProc(audioQueue: AudioQueueRef, property: AudioQueuePropertyID) {
        if property == kAudioQueueProperty_IsRunning {
            var isRunning: UInt32 = 0
            var size: UInt32 = UInt32(MemoryLayout.size(ofValue: isRunning))
            AudioQueueGetProperty(audioQueue, property, &isRunning, &size)
            self.isRunning = Bool(truncating: isRunning as NSNumber)
            
        }
        
    }
    
}

// MARK: - pthead - mutex
extension YYAudioOutputQueue {
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


// MARK: - 伪宏
extension YYAudioOutputQueue {
    static let AudioQueueBufferCount = 2
    
}

 
private class YYAudioQueueBuffer: NSObject {
    var buffer: AudioQueueBufferRef!
    
    init(buffer: AudioQueueBufferRef) {
        self.buffer = buffer
        
        super.init()
        
    }
    
}
