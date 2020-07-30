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
import CoreAudio

class AudioStreamManager: NSObject {
    let fileType: AudioFileTypeID!
    let fileSize: Int!
    
    var streamId: AudioFileStreamID?
    
    init(fileType: AudioFileTypeID = 0, fileSize: Int, callback: (NSError?) -> Void) {
        self.fileType = fileType
        self.fileSize = fileSize
        
        super.init()
        
        openAudioFileStream(callback: callback)
    }
    
    deinit {
        if streamId != nil {
            /// 关闭
            
        }
    }
    
    func openAudioFileStream(callback: (NSError?) -> Void) {
        let clientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status: OSStatus = AudioFileStreamOpen(clientData, { (selfPointer, streamId, propertyId, flags) in
            AudioStreamManager.propertyListener(inClientData: clientData, streamId: streamId, propertyId: propertyId, ioFlags: flags)
            
        }, { (clientData, numberBytes, numberPackets, inputData, packetDescriptions) in
            AudioStreamManager.packetsProc(clientData: clientData, numberBytes: numberBytes, numberPackets: numberPackets, inputData: inputData, packetDescriptionsPointer: packetDescriptions)

        }, fileType, &streamId)
                
        var error: NSError? = nil
        
        if status != noErr {
            error = NSError.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            
        }
        
        callback(error)
        
        
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

// MARK: - 静态监听
extension AudioStreamManager {
    /// 歌曲信息解析监听
    /// - Parameters:
    ///   - inClientData: 上下文对象
    ///   - streamId: 当前文件流Id
    ///   - propertyId: 当前解析的信息Id
    ///   - ioFlags: 返回参数
    static func propertyListener(inClientData: UnsafeMutableRawPointer, streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        let unsafeRawPointer = UnsafeRawPointer.init(inClientData)
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
        
        
    }
    
    /// 分离帧监听
    /// - Parameters:
    ///   - clientData: 上下文对象
    ///   - numberBytes: 本次处理的数据大小
    ///   - numberPackets: 本次总共处理了多少帧
    ///   - inputData: 本次处理的所有数据
    ///   - packetDescriptions: AudioStreamPacketDescription数组(存储了每一帧数据是从第几个字节开始的，这一帧总共多少字节)
    /*
     struct  AudioStreamPacketDescription
     {
         SInt64  mStartOffset;
         UInt32  mVariableFramesInPacket;
         UInt32  mDataByteSize;
     };
     */
    static func packetsProc(clientData: UnsafeMutableRawPointer, numberBytes: UInt32, numberPackets:  UInt32, inputData: UnsafeRawPointer, packetDescriptionsPointer: UnsafeMutablePointer<AudioStreamPacketDescription>)  {
        
        guard numberBytes != 0 && numberPackets != 0 else {
            return
            
        }
        
        var deletePackDesc = false
        
        var packetDescriptions = packetDescriptionsPointer.pointee
        
        if packetDescriptions == nil { // * 按照CBR处理，平均每一帧的数据后生成packetDescriptioins
            deletePackDesc = true
            let packetSize = numberBytes / numberPackets
            
            packetDescriptions = AudioStreamPacketDescription.init(mStartOffset: 0, mVariableFramesInPacket: numberPackets, mDataByteSize: MemoryLayout.size(ofValue: AudioStreamPacketDescription.self) as! UInt32)
            
            
            for index in 0 ..< numberPackets {
                let packetOffset = packetSize * index
                
                
                
            }
            
//            AudioStreamPacketDescription
//            packetDescriptions = packetDescriptionsPointer.pointee.mDataByteSize * numberPackets
            
            
            
            
            
            
            
        } // * 不能因为有inPacketDescriptions没有返回NULL而判定音频数据就是VBR编码的
        
        
        
        /*
         STKAudioPlayer* player = (__bridge STKAudioPlayer*)clientData;
         
         [player handleAudioPackets:inputData numberBytes:numberBytes numberPackets:numberPackets packetDescriptions:packetDescriptions];
         */
        
        
    }
    
    
}
