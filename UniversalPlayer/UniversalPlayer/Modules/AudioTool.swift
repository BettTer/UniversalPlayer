//
//  AudioTool.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/28.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation
import StreamingKit

class AudioTool: NSObject {
    static let shared = AudioTool()
    
    /// 设置AudioSession
    func setupAudioSession()  {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback)
            
        } catch let error {
            print("setCategory失败")
            print(error)
            
        }
        
        do {
            try session.setMode(.moviePlayback)
            
        } catch let error {
            print("setMode失败")
            print(error)
            
        }
        
        try! session.setActive(true)
        
    }
    
    /// 绑定通知
    func bindAudioSessionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        
    }
    
    /// bridge
    func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }

    func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    }

    func bridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
    }

    func bridgeTransfer<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()
    }
    
    func test() {
//        let player = STKAudioPlayer()
//        player.play(URL.init(string: "")!)
//        
//        let s = AudioFileStreamOpen(bridge(obj: self), <#T##inPropertyListenerProc: AudioFileStream_PropertyListenerProc##AudioFileStream_PropertyListenerProc##(UnsafeMutableRawPointer, AudioFileStreamID, AudioFileStreamPropertyID, UnsafeMutablePointer<AudioFileStreamPropertyFlags>) -> Void#>, <#T##inPacketsProc: AudioFileStream_PacketsProc##AudioFileStream_PacketsProc##(UnsafeMutableRawPointer, UInt32, UInt32, UnsafeRawPointer, UnsafeMutablePointer<AudioStreamPacketDescription>) -> Void#>, <#T##inFileTypeHint: AudioFileTypeID##AudioFileTypeID#>, <#T##outAudioFileStream: UnsafeMutablePointer<AudioFileStreamID?>##UnsafeMutablePointer<AudioFileStreamID?>#>)
        
        
    }
    
    
}

extension AudioTool {
    /// 处理打断通知
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue)
        
            else {
            return
                
        }
        
        switch interruptionType {
        case AVAudioSession.InterruptionType.began: // * 打断开始
            print("打断开始")
            break
            
        case AVAudioSession.InterruptionType.ended: // * 打断结束
            print("打断结束")
            break
            
        default:
            break
            
        }
        
        
    }
    
}

