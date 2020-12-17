//
//  AudioStreamManager.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/29.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation
//import CoreAudio

protocol YYAudioStreamDelegate: NSObjectProtocol {
    func finishParseProperty(manager: YYAudioStreamManager)
    func audioDataParsed(manager: YYAudioStreamManager, datas: [YYAudioParsedData])
    
}

class YYAudioStreamManager: NSObject {
    let fileType: AudioFileTypeID
    let fileSize: UInt64
    
    private (set) var bitRate: UInt32 = 0
    private (set) var duration: TimeInterval = 0
    
    private (set) var format: AudioStreamBasicDescription = AudioStreamBasicDescription.init()
    private (set) var maxPacketSize: UInt32 = 0
    private (set) var audioDataByteCount: UInt64 = 0
    
    weak var delegate: YYAudioStreamDelegate?

    private var streamId: AudioFileStreamID?
    
    private var dataOffset: Int64 = 0
    private var packetDuration: TimeInterval = 0
    
    private var processedPacketsCount: UInt64 = 0
    private var processedPacketsSizeTotal: UInt64 = 0
    
    private (set) var readyToProducePackets = false
    private var discontinuous = false
    
    
    init(fileType: AudioFileTypeID = 0, fileSize: UInt64) {
        self.fileType = fileType
        self.fileSize = fileSize
        
        super.init()
        
    }
    
    /// 打开文件流
    func openAudioFileStream() -> NSError? {
        let clientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status: OSStatus = AudioFileStreamOpen(clientData, { (selfPointer, streamId, propertyId, flags) in
            YYAudioStreamManager.propertyListener(inClientData: selfPointer, streamId: streamId, propertyId: propertyId, ioFlags: flags)
            
        }, { (clientData, numberBytes, numberPackets, inputData, packetDescriptions) in
            YYAudioStreamManager.packetsProc(clientData: clientData, numberBytes: numberBytes, numberPackets: numberPackets, inputData: inputData, packetDescriptionsPointer: packetDescriptions!)

        }, fileType, &streamId)
        
        if let error = AudioTool.shared.decideStatus(status) {
            return error
            
        }else {
            return nil
            
        }
        
        
    }
    
    /// 关闭文件流
    func closeAudioFileStream() {
        if streamId != nil {
            AudioFileStreamClose(streamId!)
            streamId = nil;
            
        }

    }
}


// MARK: - 监听
extension YYAudioStreamManager {
    /// 静态歌曲信息解析监听
    static func propertyListener(inClientData: UnsafeMutableRawPointer, streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        let unsafeRawPointer = UnsafeRawPointer.init(inClientData)
        let manager: YYAudioStreamManager = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        manager.handlePropertyListener(propertyId: propertyId, ioFlags: ioFlags)
        
    }
    
    /// 歌曲信息解析监听
    /// - Parameters:
    ///   - inClientData: 上下文对象
    ///   - streamId: 当前文件流Id
    ///   - propertyId: 当前解析的信息Id
    ///   - ioFlags: 返回参数
    private func handlePropertyListener(propertyId: AudioFileStreamPropertyID, ioFlags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
        
        switch propertyId {
        case kAudioFileStreamProperty_BitRate: // * 音频数据的码率
            break
            
        case kAudioFileStreamProperty_DataOffset: // * 音频数据在整个音频文件中的offset
            var offsetSize: UInt32 = UInt32(MemoryLayout.size(ofValue: dataOffset))
            
            // * 获取dataOffset
            let _ = AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_PacketSizeUpperBound, &offsetSize, &dataOffset)
            
            audioDataByteCount = UInt64(Int64(fileSize) - dataOffset)
            calculateDuration()
            
            break
            
        case kAudioFileStreamProperty_DataFormat: // * 音频文件结构信息(处理AAC / SBR等包含多个文件类型的音频格式)
            var descriptionSize: UInt32 = UInt32(MemoryLayout.size(ofValue: format))
            
            // * 获取format
            let status = AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_DataFormat, &descriptionSize, &format)
            
            
            if let error = AudioTool.shared.decideStatus(status) {
                print(error)
                
            }else {
                calculatepPacketDuration()
                
            }
            
            break
            
        case kAudioFileStreamProperty_AudioDataByteCount: // * 音频数据的总量
            break
            
        case kAudioFileStreamProperty_FormatList: // * AudioStreamBasicDescription
            var outWriteable = DarwinBoolean.init(false)
            var formatListSize: UInt32 = 0
            guard AudioFileStreamGetPropertyInfo(streamId!, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable) == noErr  else {
                break
                
            }
            
            var formatList = UnsafeMutablePointer<AudioFormatListItem>.allocate(capacity: Int(formatListSize))
            defer { // * 预释放formatList
                free(formatList)
                
            }
            guard AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_FormatList, &formatListSize, formatList) == noErr  else {
                break
                
            }
            
            var supportedFormatsSize: UInt32 = 0
            guard AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, nil, &supportedFormatsSize) == noErr  else {
                
                break
                
            }
            
            let supportedFormatCount = supportedFormatsSize / UInt32(MemoryLayout<OSType>.size)
            var supportedFormats = UnsafeMutablePointer<OSType>.allocate(capacity: Int(supportedFormatCount))
            defer { // * 预释放supportedFormats
                free(supportedFormats)
                
            }
            guard AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, nil, supportedFormats) == noErr  else {

                break
                
            }
            
            let num = Int(formatListSize) / MemoryLayout<AudioFormatListItem>.size
            
            for index in 0 ..< num + 1 {
                let format = formatList[index].mASBD
                
                for jndex in 0 ..< supportedFormatCount {
                    
                    if format.mFormatID == supportedFormats[Int(jndex)] {
                        self.format = format
                        calculatepPacketDuration()
                        break;
                        
                    }
                    
                }
                
            }
            
            
            break
            
        case kAudioFileStreamProperty_ReadyToProducePackets: // * 解析完成
            readyToProducePackets = true
            discontinuous = true
            
            var sizeOfUInt32 = UInt32(MemoryLayout.size(ofValue: maxPacketSize))
            var status = AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &maxPacketSize)
            
            if status != noErr || maxPacketSize == 0 {
                print("解析完成")
                status = AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &maxPacketSize)
                
            }
            
            // * 外部代理
            delegate?.finishParseProperty(manager: self)
            
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
        let manager: YYAudioStreamManager = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        manager.handlePacketsProc(packets: inputData, numberBytes: numberBytes, numberPackets: numberPackets, packetDescriptionsPointer: packetDescriptionsPointer)
        
    }
    
    /// 分离帧监听
    /// - Parameters:
    ///   - packets: 本次处理的所有数据
    ///   - numberBytes: 本次处理的数据大小
    ///   - numberPackets: 本次总共处理了多少帧
    ///   - packetDescriptionsPointer: AudioStreamPacketDescription数组(存储了每一帧数据是从第几个字节开始的，这一帧总共多少字节)
    private func handlePacketsProc(packets: UnsafeRawPointer, numberBytes: UInt32, numberPackets: UInt32, packetDescriptionsPointer: UnsafeMutablePointer<AudioStreamPacketDescription>)  {
        /// 是否需要需要手动释放内存
        var doesNeedToFreeMemory = false
        var descriptionsPointer = packetDescriptionsPointer
        
        // * 为空 按照CBR处理 平均每一帧的数据后生成packetDescriptioins
        if descriptionsPointer == UnsafeMutablePointer<AudioStreamPacketDescription>(nil) {
            doesNeedToFreeMemory = true
            
            let memorySize = MemoryLayout<AudioStreamPacketDescription>.size * Int(numberPackets)
            // * malloc
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
        
        
        var array: [YYAudioParsedData] = []
        
        for index in 0 ..< Int(numberPackets) {
            /// 获取帧偏移量
            let packetOffset = descriptionsPointer[index].mStartOffset
            
            let pointer = packets.advanced(by: Int(packetOffset))
            
            if let parsedData = YYAudioParsedData.init(bytes: pointer, description: descriptionsPointer[index]) {
                
                array.append(parsedData)
                
                if processedPacketsCount < Self.BitRateEstimationMaxPackets {
                    processedPacketsSizeTotal += UInt64(parsedData.packetDescription.mDataByteSize)
                    processedPacketsCount += 1
                    
                    calculateBitRate()
                    calculateDuration()
                    
                }
                
            }
            
            
        }
        
        
        // * 外部代理
        delegate?.audioDataParsed(manager: self, datas: array)
        
        
        if doesNeedToFreeMemory {
            free(descriptionsPointer)
            
        }
        
    }
}

// MARK: - Calculate
extension YYAudioStreamManager {
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
            duration = Double(fileSize - UInt64(dataOffset)) * 8.0 / Double(bitRate)
            
        }
        
    }
    
    func calculatepPacketDuration() {
        guard format.mSampleRate > 0 else {
            return
                
        }
        
        packetDuration = Double(format.mFramesPerPacket) / format.mSampleRate
    }
}

// MARK: - Actions
extension YYAudioStreamManager {
    /// 获取MagicCookie
    func fetchMagicCookie() -> Data? {
        var cookieSize: UInt32 = 0
        var writable: DarwinBoolean = false

        let status1 = AudioFileStreamGetPropertyInfo(streamId!, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable)
        if let error = AudioTool.shared.decideStatus(status1) {
            print(error)
            return nil
            
        }
        
        let cookieData = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: Int(cookieSize))
        defer {
            free(cookieData)
        }
        
        let status2 = AudioFileStreamGetProperty(streamId!, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData)
        if let error = AudioTool.shared.decideStatus(status2) {
            print(error)
            return nil
            
        }
        
        let data = Data.init(bytes: cookieData, count: Int(cookieSize))
        return data
    }
    
    /// 分析Data
    func parseData(data: Data) -> NSError? {
        if readyToProducePackets && packetDuration == 0 {
            return NSError.init(domain: NSOSStatusErrorDomain, code: -1, userInfo: nil)
            
        }
        
        let status = AudioFileStreamParseBytes(streamId!, UInt32(data.count), (data as NSData).bytes, discontinuous ? .discontinuity : .init(rawValue: 0))
        
        if status == noErr {
            return nil
            
        }else {
            return NSError.init(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            
        }
    }
    
    /// 拖动时间
    func seekTo(time: TimeInterval) -> Int64 {
        
        let seekToPacket = floor(time / packetDuration)
        var ioFlags = AudioFileStreamSeekFlags.init()
        var outDataByteOffset: Int64 = 0
        
        let status = AudioFileStreamSeek(streamId!, Int64(seekToPacket), &outDataByteOffset, &ioFlags)
        
        #warning("疑问?")
        // * if (status == noErr && !(ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated))
        if AudioTool.shared.decideStatus(status) == nil && ioFlags == AudioFileStreamSeekFlags.offsetIsEstimated {
            // *time -= ((approximateSeekOffset - _dataOffset) - outDataByteOffset) * 8.0 / _bitRate;
            
            return outDataByteOffset + dataOffset
            
            
            
        }else {
            discontinuous = true
            return dataOffset + Int64(time / duration) * Int64(audioDataByteCount)
            
        }
        
    }
}

// MARK: - 伪宏
extension YYAudioStreamManager {
    static let BitRateEstimationMaxPackets = 5000
    static let BitRateEstimationMinPackets = 10
    
}
