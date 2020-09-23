//
//  YYAudioSession.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/9/14.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation

protocol YYAudioSessionDelegate: NSObjectProtocol {
    func interruptionEvent(type: AVAudioSession.InterruptionType)
    
}

class YYAudioSession: NSObject {
    static let shared = YYAudioSession.init()
    weak var delegate: YYAudioSessionDelegate? = nil
    
    private (set) var setupError: Error?
    
    
    override init() {
        super.init()
        
    }
    
    deinit {
        if setupError == nil {
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
            
        }
        
        
    }
    
    /// 设置AudioSession
    func setupAudioSession() -> Error? {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback)
            
        } catch let error {
            print("setCategory失败")
            setupError = error
            return setupError
            
        }
        
        do {
            try session.setMode(.moviePlayback)
            
        } catch let error {
            print("setMode失败")
            setupError = error
            return setupError
            
        }
        
        do {
            try session.setActive(true)
            
        } catch let error {
            print("setActive失败")
            setupError = error
            return setupError
            
        }
        
        // * 绑定通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        
        return setupError
        
    }
    
}

extension YYAudioSession {
    /// 处理打断通知
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue)
        
            else {
            return
                
        }
        
        switch interruptionType {
        case .began, // * 打断开始
             .ended: // * 打断结束
            
            if let _ = delegate {
                delegate!.interruptionEvent(type: interruptionType)
                
            }
            
            
        default:
            break
            
        }
        
        
        
    }
    
    
}


