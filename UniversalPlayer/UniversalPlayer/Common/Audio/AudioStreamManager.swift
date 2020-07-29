//
//  AudioStreamManager.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/29.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation
import StreamingKit

class AudioStreamManager: NSObject {
    
    var streamID: AudioFileStreamID?
    
    func setAudioFileStreamOpen() {
        
        let inClientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status = AudioFileStreamOpen(inClientData, { (clientData, streamId, propertyId, flags) in
            AudioStreamManager.propertyListenerProc(clientData: clientData, streamId: streamId, propertyId: propertyId, flags: flags)

        },{ (clientData, numberBytes, numberPackets, inputData, packetDescriptions) in
            AudioStreamManager.packetsProc(clientData: clientData, numberBytes: numberBytes, numberPackets: numberPackets, inputData: inputData, packetDescriptions: packetDescriptions)

        }, 0, &streamID)
        
        if status == noErr {
            print("setAudioFileStreamOpen成功")
            
        }else {
            print("setAudioFileStreamOpen失败")
            
        }
        
    }
    
    func setAudioFileStreamParseBytes() {
        
        let status = AudioFileStreamParseBytes(streamID!,
            <#T##inDataByteSize: UInt32##UInt32#>, // * 解析的数据长度
            <#T##inData: UnsafeRawPointer?##UnsafeRawPointer?#>,  // * 解析的数据
            AudioFileStreamParseFlags(rawValue: 0))
        
        
        if status == noErr {
            print("setAudioFileStreamParseBytes成功")
            
        }else {
            print("setAudioFileStreamParseBytes失败") // * 出错就可以停了
            
            
        }
    }
    

}

// MARK: - 回调
extension AudioStreamManager {
    /// 歌曲信息解析的回调
    /// - Parameters:
    ///   - clientData: 上下文对象
    ///   - streamId: <#streamId description#>
    ///   - propertyId: <#propertyId description#>
    ///   - flags: <#flags description#>
    static func propertyListenerProc(clientData: UnsafeMutableRawPointer, streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        let unsafeRawPointer = UnsafeRawPointer.init(clientData)
        let manager: AudioStreamManager = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        switch propertyId {
        case kAudioFileStreamProperty_BitRate: // * 音频数据的码率
            break
            
        case kAudioFileStreamProperty_DataOffset: // * 音频数据在整个音频文件中的offset
            break
            
        case kAudioFileStreamProperty_DataFormat: // * 音频文件结构信息(处理AAC / SBR等包含多个文件类型的音频格式)
            break
            
        case kAudioFileStreamProperty_AudioDataByteCount: // * 音频数据的总量
            break
            
        case kAudioFileStreamProperty_ReadyToProducePackets: // * 解析完成
            break
            
        default: // * 其他忽略
            break
        }
        
        
        /*
         STKAudioPlayer* player = (__bridge STKAudioPlayer*)clientData;
         
         [player handlePropertyChangeForFileStream:audioFileStream fileStreamPropertyID:propertyId ioFlags:flags];
         */
        
    }
    
    /// 分离帧的回调
    /// - Parameters:
    ///   - clientData: <#clientData description#>
    ///   - numberBytes: <#numberBytes description#>
    ///   - numberPackets: <#numberPackets description#>
    ///   - inputData: <#inputData description#>
    ///   - packetDescriptions: <#packetDescriptions description#>
    static func packetsProc(clientData: UnsafeMutableRawPointer, numberBytes: UInt32, numberPackets:  UInt32, inputData: UnsafeRawPointer, packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>)  {
        /*
         STKAudioPlayer* player = (__bridge STKAudioPlayer*)clientData;
         
         [player handleAudioPackets:inputData numberBytes:numberBytes numberPackets:numberPackets packetDescriptions:packetDescriptions];
         */
        
        
    }
    
    
}
