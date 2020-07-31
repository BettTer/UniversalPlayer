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
    
    var bitRate: UInt32 = 0
    var duration: TimeInterval = 0
    
    var format: AudioStreamBasicDescription?
    
    
    private var streamId: AudioFileStreamID?
    
    private var dataOffset = 0
    private var packetDuration: TimeInterval = 0
    
    private var processedPacketsCount = 0
    private var processedPacketsSizeTotal = 0
    
    
    
    init(fileType: AudioFileTypeID = 0, fileSize: Int, callback: (NSError?) -> Void) {
        self.fileType = fileType
        self.fileSize = fileSize
        
        super.init()
        
        openAudioFileStream(callback: callback)
    }
    
    deinit {
        if streamId != nil {
            closeAudioFileStream()
            
        }
    }
    
    func openAudioFileStream(callback: (NSError?) -> Void) {
        let clientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status: OSStatus = AudioFileStreamOpen(clientData, { (selfPointer, streamId, propertyId, flags) in
            AudioStreamManager.propertyListener(inClientData: selfPointer, streamId: streamId, propertyId: propertyId, ioFlags: flags)
            
        }, { (clientData, numberBytes, numberPackets, inputData, packetDescriptions) in
            AudioStreamManager.packetsProc(clientData: clientData, numberBytes: numberBytes, numberPackets: numberPackets, inputData: inputData, packetDescriptionsPointer: packetDescriptions)

        }, fileType, &streamId)
                
        var error: NSError? = nil
        
        if status != noErr {
            error = NSError.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            
        }
        
        callback(error)
        
        
    }
    
    // TODO: 关闭文件流的实现
    func closeAudioFileStream() {
        if streamId != nil {
            AudioFileStreamClose(streamId!)
            streamId = nil;
            
        }

    }
    

}


// MARK: - 监听
extension AudioStreamManager {
    /// 静态歌曲信息解析监听
    static func propertyListener(inClientData: UnsafeMutableRawPointer, streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        let unsafeRawPointer = UnsafeRawPointer.init(inClientData)
        let manager: AudioStreamManager = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        manager.handlePropertyListener(streamId: streamId, propertyId: propertyId, ioFlags: ioFlags)
        
    }
    
    /// 歌曲信息解析监听
    /// - Parameters:
    ///   - inClientData: 上下文对象
    ///   - streamId: 当前文件流Id
    ///   - propertyId: 当前解析的信息Id
    ///   - ioFlags: 返回参数
    private func handlePropertyListener(streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
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
    
    /// 静态分离帧监听
    static func packetsProc(clientData: UnsafeMutableRawPointer, numberBytes: UInt32, numberPackets:  UInt32, inputData: UnsafeRawPointer, packetDescriptionsPointer: UnsafeMutablePointer<AudioStreamPacketDescription>)  {
        
        if numberBytes == 0 || numberPackets == 0 {
            return
            
        }
        
        let unsafeRawPointer = UnsafeRawPointer.init(clientData)
        let manager: AudioStreamManager = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        manager.handlePacketsProc(numberBytes: numberBytes, numberPackets: numberPackets, inputData: inputData, packetDescriptionsPointer: packetDescriptionsPointer)
        
    }
    
    
    /// 分离帧监听
    /// - Parameters:
    ///   - numberBytes: 本次处理的数据大小
    ///   - numberPackets: 本次总共处理了多少帧
    ///   - inputData: 本次处理的所有数据
    ///   - packetDescriptionsPointer: AudioStreamPacketDescription数组(存储了每一帧数据是从第几个字节开始的，这一帧总共多少字节)
    private func handlePacketsProc(numberBytes: UInt32, numberPackets:  UInt32, inputData: UnsafeRawPointer, packetDescriptionsPointer: UnsafeMutablePointer<AudioStreamPacketDescription>)  {
            /// 是否需要需要手动释放内存
            var doesNeedToFreeMemory = false
            var descriptionsPointer = packetDescriptionsPointer
            
            // * 为空 按照CBR处理 平均每一帧的数据后生成packetDescriptioins
            if descriptionsPointer == UnsafeMutablePointer<AudioStreamPacketDescription>(nil) {
                doesNeedToFreeMemory = true
                
                let memorySize = MemoryLayout.size(ofValue: AudioStreamPacketDescription.self) * Int(numberPackets)
                descriptionsPointer = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: memorySize)
                
                let packetSize = numberBytes / numberPackets
                
                
                for index in 0 ..< Int(numberPackets) {
                    /// 计算帧偏移量
                    let packetOffset = packetSize * UInt32(index)
                    
                    descriptionsPointer[index].mStartOffset = Int64(packetOffset)
                    descriptionsPointer[index].mVariableFramesInPacket = 0
                    
                    if index == numberPackets - 1 { // * 最后一帧
                        descriptionsPointer[index].mDataByteSize = numberBytes - packetOffset
                        
                    }else {
                        descriptionsPointer[index].mDataByteSize = packetSize
                        
                    }
                    
                }
                
                
            } // * 不能因为有inPacketDescriptions没有返回NULL而判定音频数据就是VBR编码的
            
            
            var array: [AudioParsedData] = []
            
            for index in 0 ..< Int(numberPackets) {
                /// 获取帧偏移量
                let packetOffset = descriptionsPointer[index].mStartOffset
                
                if let parsedData = AudioParsedData.init(bytes: UnsafeRawPointer.init(bitPattern: Int(numberPackets) + Int(packetOffset)), description: descriptionsPointer[index]) {
                    
                    array.append(parsedData)
                    
                    if processedPacketsCount < Self.BitRateEstimationMaxPackets {
                        processedPacketsSizeTotal += Int(parsedData.packetDescription.mDataByteSize)
                        processedPacketsCount += 1
                        
                        calculateBitRate()
                        calculateDuration()
                        
                    }
                    
                }
                
                
            }
            
        
            // TODO: 外部代理
            
            if doesNeedToFreeMemory {
                free(descriptionsPointer)

            }
        
    }
}

// MARK: - calculate
extension AudioStreamManager {
    func calculateBitRate() {
        if packetDuration != 0
            && processedPacketsCount > Self.BitRateEstimationMinPackets
            && processedPacketsCount <= Self.BitRateEstimationMaxPackets {
            
            let averagePacketByteSize = Double(processedPacketsSizeTotal / processedPacketsCount)
            bitRate = UInt32(8.0 * averagePacketByteSize / packetDuration)
            
        }
        
    }
    
    func calculateDuration() {
        if fileSize > 0 && bitRate > 0 {
            duration = Double(fileSize - dataOffset) * 8.0 / Double(bitRate)
            
        }
        
    }
    
    func calculatepPacketDuration() {
        guard let beingFormat = format, beingFormat.mSampleRate > 0 else {
            return
                
        }
        
        packetDuration = Double(beingFormat.mFramesPerPacket) / beingFormat.mSampleRate
    }
}

// MARK: - 伪宏
extension AudioStreamManager {
    static let BitRateEstimationMaxPackets = 5000
    static let BitRateEstimationMinPackets = 10
    
}
