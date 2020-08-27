//
//  YYAudioBuffer.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/8/27.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import CoreAudio

class YYAudioBuffer: NSObject {
    static let shared = YYAudioBuffer.init()
    
    private (set) var bufferBlockArray: [AudioParsedData] = []
    private (set) var bufferedSize: UInt32 = 0

}

extension YYAudioBuffer {
    func enqueue(from audioParsedDatas: [AudioParsedData]) {
        bufferBlockArray = audioParsedDatas
        
        let _ = bufferBlockArray.map {
            bufferedSize += UInt32($0.data.count)
            
        }
        
    }
    
    func dequeueData(requestSize: UInt32, packetCountPointer: UnsafeMutablePointer<UInt32>, descriptionsPointer: UnsafeMutablePointer<AudioStreamPacketDescription>) -> Data? {
        
        if requestSize == 0 && bufferBlockArray.count == 0 {
            return nil
            
        }
        
        var size = Int64(requestSize)
        var targetIndex = 0
        
        for index in 0 ..< bufferBlockArray.count {
            let block = bufferBlockArray[index]
            let blockDataLength = block.data.count
            
            if size > blockDataLength {
                size -= Int64(blockDataLength)
                
            }else {
                if size < blockDataLength {
                    targetIndex = index - 1
                    
                }
                
                break
                
            }
            
        }
        
        if targetIndex < 0 {
            return nil
            
        }
        
        let count: UInt32 = targetIndex >= bufferBlockArray.count ? UInt32(bufferBlockArray.count) : UInt32(targetIndex) + 1
        
        
        
    }
    
    
}

// AudioParsedData
