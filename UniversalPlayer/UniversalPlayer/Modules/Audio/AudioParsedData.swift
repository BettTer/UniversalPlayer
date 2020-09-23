//
//  AudioParsedData.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/31.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import CoreAudio

class YYAudioParsedData: NSObject {
    let data: Data!
    let packetDescription: AudioStreamPacketDescription!
    
    init?(bytes: UnsafeRawPointer?, description: AudioStreamPacketDescription) {
        
        if bytes == nil || bytes == UnsafeRawPointer(nil) || description.mDataByteSize == 0 {
            return nil
            
        }
        
        data = Data.init(bytes: bytes!, count: Int(description.mDataByteSize))
        packetDescription = description
        
        super.init()
        
    }

}
