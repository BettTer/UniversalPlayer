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
    
}

extension AudioTool {
    /*
     // * malloc
     descriptionsPointer = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: memorySize)
     */
    
    func decideStatus(_ status: OSStatus) -> NSError? {
        if status != noErr {
            return NSError.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            
        }else {
            return nil
            
        }
        
    }

}

