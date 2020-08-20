//
//  YYAudioFile.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/8/10.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import AVFoundation

class YYAudioFile: NSObject {
    let filePath: String
    let fileType: AudioFileTypeID
    
    private (set) var format: AudioStreamBasicDescription?
    private (set) var fileSize: Int64 = 0
    private (set) var duration: TimeInterval = 0
    private (set) var bitRate: UInt32 = 0
    private (set) var maxPacketSize: UInt32 = 0
    private (set) var audioDataByteCount: UInt64 = 0
    
    private var packetOffset = 0
    private var fileHandler: FileHandle?
    private var dataOffset = 0
    private var packetDuration: TimeInterval = 0
    private (set) var audioFileId: AudioFileID?
    
    init(filePath: String, fileType: AudioFileTypeID = 0) {
        self.filePath = filePath
        self.fileType = fileType
        
        super.init()
        
//        if FileManager.default.fileExists(atPath: filePath) == true { // * 文件是否存在?
//
//
//        }
        
        setupData()
    }
    
    func setupData() {
        fileHandler = FileHandle.init(forReadingAtPath: filePath)
        fileSize = try! FileManager.default.attributesOfItem(atPath: filePath)[.size] as! Int64
        
        guard fileHandler != nil, fileSize > 0 else {
            fileHandler?.closeFile()
            return
            
        }
        
        let status = openAudioFile()
        
        if AudioTool.shared.decideStatus(status) == nil {
            fetchFormatInfo()
        }

    }
    
    deinit {
        if let _ = fileHandler {
            fileHandler!.closeFile()
            
        }
        
        closeAudioFile()
    }
    
}

// MARK: - audiofile
extension YYAudioFile {
    func openAudioFile() -> OSStatus {
        let clientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status = AudioFileOpenWithCallbacks(clientData, YYAudioFile.readProcHandler, nil, YYAudioFile.getSizeProcHandler, nil, fileType, &audioFileId)
        
        return status
        
    }
    
    func closeAudioFile() {
        if let _ = audioFileId {
            AudioFileClose(audioFileId!);
            audioFileId = nil;
            
        }
        
    }
    
    func fetchFormatInfo() {
        var formatListSize: UInt32 = 0
        
        let infoStatus = AudioFileGetPropertyInfo(audioFileId!, kAudioFilePropertyFormatList, &formatListSize, nil)
        
        if AudioTool.shared.decideStatus(infoStatus) == nil {
            var doesFoundFormat = false
            
            var formatListPointer = UnsafeMutablePointer<AudioFormatListItem>.allocate(capacity: Int(formatListSize))
            defer {
                free(formatListPointer)

            }
            
            let propertyStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyFormatList, &formatListSize, formatListPointer)
            
            if AudioTool.shared.decideStatus(propertyStatus) == nil {
                var supportedFormatsSize: UInt32 = 0
                
                let infoStatus_DecodeFormatIDs = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, nil, &supportedFormatsSize)
                
                if let error = AudioTool.shared.decideStatus(infoStatus_DecodeFormatIDs) { // * 如果出错就直接关闭
                    print(error)
                    print("关闭")
                    closeAudioFile()
                    return
                    
                }else {
                    let supportedFormatCount = supportedFormatsSize / UInt32(MemoryLayout<OSType>.size)
                    let supportedFormats = UnsafeMutablePointer<OSType>.allocate(capacity: Int(supportedFormatsSize))
                    defer {
                        free(supportedFormats)
                    }
                    
                    let propertyStatus_DecodeFormatIDs = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, nil, &supportedFormatsSize, supportedFormats)
                    
                    if let error = AudioTool.shared.decideStatus(propertyStatus_DecodeFormatIDs) {
                        // * 如果出错就直接关闭
                        print(error)
                        print("关闭")
                        closeAudioFile()
                        return
                        
                    }
                    
                    let endIndex = Int(formatListSize) / MemoryLayout<AudioFormatListItem>.size
                    
                    FindFormatLoop: for index in 0 ..< endIndex + 1 {
                        let currentFormat = formatListPointer[index].mASBD
                        
                        for jndex in 0 ..< supportedFormatCount {
                            
                            if currentFormat.mFormatID == supportedFormats[Int(jndex)] {
                                format = currentFormat
                                doesFoundFormat = true
                                 
                                break FindFormatLoop
                            }
                            
                            
                        }
                        
                    }
                    
                    
                }
                
                if doesFoundFormat {
                    calculatepPacketDuration()
                    
                }else {
                    closeAudioFile()
                    return
                    
                    
                }
                
                
            }
            
            
        }
        
        var size: UInt32 = UInt32(MemoryLayout.size(ofValue: bitRate))
        let bitRateStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyBitRate, &size, &bitRate)
        
        if let error = AudioTool.shared.decideStatus(bitRateStatus) {
            // * 如果出错就直接关闭
            print(error)
            print("关闭")
            closeAudioFile()
            return
            
        }
        
        size = UInt32(MemoryLayout.size(ofValue: dataOffset))
        let dataOffsetStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyDataOffset, &size, &dataOffset)
        if let error = AudioTool.shared.decideStatus(dataOffsetStatus) {
            // * 如果出错就直接关闭
            print(error)
            print("关闭")
            closeAudioFile()
            return
            
        }
        
        audioDataByteCount = UInt64(fileSize - Int64(dataOffset))
        
        size = UInt32(MemoryLayout.size(ofValue: duration))
        var tmpStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyEstimatedDuration, &size, &duration)
        
        if let _ = AudioTool.shared.decideStatus(tmpStatus) {
            calculateDuration()
            
        }
        
        size = UInt32(MemoryLayout.size(ofValue: maxPacketSize))
        tmpStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize)
        
        if AudioTool.shared.decideStatus(tmpStatus) != nil  || maxPacketSize == 0 {
            tmpStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyMaximumPacketSize, &size, &maxPacketSize)
            
            if let error = AudioTool.shared.decideStatus(tmpStatus) {
                // * 如果出错就直接关闭
                print(error)
                print("关闭")
                closeAudioFile()
                return
            }
        }
        
        
    }
    
    func fetchMagicCookie() -> Data? {
        
        var cookieSize: UInt32 = 0
        var status = AudioFileGetPropertyInfo(audioFileId!, kAudioFilePropertyMagicCookieData, &cookieSize, nil)
        if let error = AudioTool.shared.decideStatus(status) {
            print(error)
            return nil
            
        }

        let cookieDataPointer = UnsafeMutablePointer<Data>.allocate(capacity: Int(cookieSize))
        defer {
            free(cookieDataPointer)
        }
        
        status = AudioFileGetProperty(audioFileId!, kAudioFilePropertyMagicCookieData, &cookieSize, cookieDataPointer)
        if let error = AudioTool.shared.decideStatus(status) {
            print(error)
            return nil
            
        }
        
        let cookie = Data.init(bytes: cookieDataPointer, count: Int(cookieSize))
        return cookie
        
    }
    
    func parseData(isEof: inout Bool) -> [AudioParsedData]? {
        var ioNumPackets = Self.PacketPerRead
        var ioNumBytes = ioNumPackets * maxPacketSize
        var outBuffer = UnsafeMutablePointer<Data>.allocate(capacity: Int(ioNumBytes))
        defer {
            free(outBuffer)
        }
        
        var status: OSStatus
        var outPacketDescriptionsPointer: (UnsafeMutablePointer<AudioStreamPacketDescription>)? = nil
        
        if format?.mFormatID != kAudioFormatLinearPCM {
            let descSize: UInt32 = UInt32(MemoryLayout<AudioStreamPacketDescription>.size) * ioNumPackets
            outPacketDescriptionsPointer = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: Int(descSize))
            status = AudioFileReadPacketData(audioFileId!, false, &ioNumBytes, outPacketDescriptionsPointer, Int64(packetOffset), &ioNumPackets, outBuffer)
            
        }else {
            
            status = AudioFileReadPackets(audioFileId!, false, &ioNumBytes, outPacketDescriptionsPointer, Int64(packetOffset), &ioNumPackets, outBuffer)
            
        }
        
        if let error = AudioTool.shared.decideStatus(status) {
            
            if error.code == Int(kAudioFileEndOfFileError) {
                isEof = true
                
            }else {
                isEof = false
                
            }
            
            return nil
            
        }
        
        packetOffset += Int(ioNumPackets)
        
        if ioNumPackets > 0 && format != nil {
            var parsedDataArray: [AudioParsedData] = []
            
            for index in 0 ..< Int(ioNumPackets) {
                var packetDescription: AudioStreamPacketDescription
                
                if outPacketDescriptionsPointer != nil {
                    packetDescription = outPacketDescriptionsPointer![index]
                    
                }else {
                    packetDescription = AudioStreamPacketDescription.init(
                        mStartOffset: Int64(index) * Int64(format!.mBytesPerPacket),
                        mVariableFramesInPacket: format!.mFramesPerPacket,
                        mDataByteSize: format!.mBytesPerPacket)
                    
                }
                
                let parsedData = AudioParsedData.init(bytes: outBuffer.advanced(by: Int(packetDescription.mStartOffset)), description: packetDescription)
                
                if (parsedData != nil) {
                    parsedDataArray.append(parsedData!)
                }
                
            }
            
            return parsedDataArray
            
        }
        
        return nil
        
    }
    
    /// 测试提取音频信息
    func testToFetchMessage() {
        var propertyDataSize: UInt32 = 0
        var status = AudioFileGetPropertyInfo(audioFileId!, kAudioFilePropertyInfoDictionary, &propertyDataSize, nil)

        if let _ = AudioTool.shared.decideStatus(status) {
            return

        }
        
        var infoDict = NSObject.init()
        status = AudioFileGetProperty(audioFileId!, kAudioFilePropertyInfoDictionary, &propertyDataSize, &infoDict)
        
        if let _ = AudioTool.shared.decideStatus(status) {
            return
            
        }else {
            print(infoDict)
            print(infoDict.classTypeName)
            
            
            if let dict = infoDict as? [AnyHashable: Any] {
                print(dict[kAFInfoDictionary_Title]!)
                
            }
            
            
        }
        
        
    }
    
}

// MARK: - 静态监听&处理
extension YYAudioFile {
    /// 读取
    static private let readProcHandler: AudioFile_ReadProc = { (filePointer, inPosition, requestCount, buffer, actualCountPointer) -> OSStatus in
        
        let unsafeRawPointer = UnsafeRawPointer.init(filePointer)
        let audioFile: YYAudioFile = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        actualCountPointer.pointee = audioFile.availableDataLengthAtOffset(inPosition: inPosition, requestCount: requestCount)
        
        if actualCountPointer.pointee > 0 {
            audioFile.fileHandler!.seek(toFileOffset: UInt64(inPosition))
            let data = audioFile.fileHandler!.readData(ofLength: Int(actualCountPointer.pointee))
            memcpy(buffer, (data as NSData).bytes, data.count)
            
        }
        
        return noErr
    }
    
    /// 返回文件总长度
    static private let getSizeProcHandler: AudioFile_GetSizeProc = { (filePointer) -> Int64 in
        let unsafeRawPointer = UnsafeRawPointer.init(filePointer)
        let audioFile: YYAudioFile = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        return audioFile.fileSize
    }
    
}

// MARK: - Calculate
extension YYAudioFile {
    func availableDataLengthAtOffset(inPosition: Int64, requestCount: UInt32) -> UInt32 {
        if inPosition + Int64(requestCount) > fileSize {
            
            if inPosition > fileSize {
                return 0
                
            }else {
                return UInt32(fileSize - inPosition)
                
            }
            
            
        }else {
            return requestCount
            
        }
        
    }
    
    func calculatepPacketDuration() {
        guard let beingFormat = format, beingFormat.mSampleRate > 0 else {
            return
            
        }
        
        packetDuration = Double(beingFormat.mFramesPerPacket) / beingFormat.mSampleRate
        
    }
    
    func calculateDuration() {
        if (fileSize > 0 && bitRate > 0) {
            
            duration = Double((fileSize - Int64(dataOffset) * 8) / Int64(bitRate))
        }
    }
    
}

// MARK: - 伪宏
extension YYAudioFile {
    static let PacketPerRead: UInt32 = 15
    
}

