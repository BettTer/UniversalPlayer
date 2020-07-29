//
//  AudioTool.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/28.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation

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

