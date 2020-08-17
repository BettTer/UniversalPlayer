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
    private var audioFileId: AudioFileID?
    
    init(filePath: String, fileType: AudioFileTypeID = 0) {
        self.filePath = filePath
        self.fileType = fileType
        
        super.init()
        
        setupData()
        
    }
    
    func setupData() {
        if FileManager.default.fileExists(atPath: filePath) == false { // * 文件是否存在?
            return
            
        }
        
        fileHandler = FileHandle.init(forReadingAtPath: filePath)
        fileSize = try! FileManager.default.attributesOfItem(atPath: filePath)[.size] as! Int64
        let error = AudioTool.shared.decideStatus(openAudioFile())
                
        guard fileSize != 0, error == nil else {
            fileHandler!.closeFile()
            
            fileSize == 0 ? print("文件长度为0") : print("文件长度无问题")
            error != nil ? print("打开文件出错: \(error!)") : print("打开文件无问题")
         
            return
            
        }
        
        fetchFormatInfo()
        
    }
    
    deinit {
        fileHandler?.closeFile()
        closeAudioFile()
    }
    
    
}

// MARK: - audiofile
extension YYAudioFile {
    func openAudioFile() -> OSStatus {
        
        let clientData = UnsafeMutableRawPointer.init(mutating: GenericFuncs.shared.bridge(obj: self))
        
        let status = AudioFileOpenWithCallbacks(clientData, { (inClientData, inPosition, requestCount, buffer, actualCount) -> OSStatus in
            YYAudioFile.readProcListener(inClientData: inClientData, inPosition: inPosition, requestCount: requestCount, buffer: buffer, actualCount: actualCount)
            
        }, nil, { (inClientData) -> Int64 in
            YYAudioFile.getSizeProcListener(inClientData: inClientData)
            
        }, nil, fileType, &audioFileId)
        
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
            
            var formatList = UnsafeMutablePointer<AudioFormatListItem>.allocate(capacity: Int(formatListSize))
            defer {
                free(formatList)
                
            }
            
            let propertyStatus = AudioFileGetProperty(audioFileId!, kAudioFilePropertyFormatList, &formatListSize, &formatList)
            
            if AudioTool.shared.decideStatus(propertyStatus) == nil {
                var supportedFormatsSize: UInt32 = 0
                
                let infoStatus_DecodeFormatIDs = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, nil, &supportedFormatsSize)
                
                if let error = AudioTool.shared.decideStatus(infoStatus_DecodeFormatIDs) { // * 如果出错就直接关闭
                    print(error)
                    print("关闭")
                    closeAudioFile()
                    return
                    
                }else {
                    
                    let supportedFormatCount = supportedFormatsSize / UInt32(MemoryLayout.size(ofValue: OSType.self))
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
                    
                    let endIndex = Int(formatListSize) / MemoryLayout.size(ofValue: AudioFormatListItem.self)
                    
                    for index in 0 ..< endIndex + 1 {
                        let currentFormat = formatList[index].mASBD
                        
                        for jndex in 0 ..< supportedFormatCount {
                            
                            if currentFormat.mFormatID == supportedFormats[Int(jndex)] {
                                format = currentFormat
                                doesFoundFormat = true
                                break
                            }
                            
                            
                        }
                        
                    }
                    
                    
                }
                
                if doesFoundFormat {
                    calculateDuration()
                    
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
    
    
}

// MARK: - 监听
extension YYAudioFile {
    static func readProcListener(inClientData: UnsafeMutableRawPointer, inPosition: Int64, requestCount: UInt32, buffer: UnsafeMutableRawPointer, actualCount: UnsafeMutablePointer<UInt32>) -> OSStatus {
        
        let unsafeRawPointer = UnsafeRawPointer.init(inClientData)
        let audioFile: YYAudioFile = GenericFuncs.shared.bridge(ptr: unsafeRawPointer)
        
        audioFile.handleReadProcListener(inPosition: inPosition, requestCount: requestCount, buffer: buffer)
        
        return noErr
        
    }
    
    func handleReadProcListener(inPosition: Int64, requestCount: UInt32, buffer: UnsafeMutableRawPointer) {
        let actualCount = availableDataLengthAtOffset(inPosition: inPosition, requestCount: requestCount)
        
        if actualCount > 0 {
            fileHandler!.seek(toFileOffset: UInt64(inPosition))
            let data = fileHandler!.readData(ofLength: Int(actualCount))
            memcpy(buffer, (data as NSData).bytes, data.count)
            
        }
        
        
    }
    
    static func getSizeProcListener(inClientData: UnsafeMutableRawPointer) -> Int64 {
        let unsafeRawPointer = UnsafeRawPointer.init(inClientData)
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
    
    func calculateDuration() {
        if (fileSize > 0 && bitRate > 0) {
            
            duration = Double((fileSize - Int64(dataOffset) * 8) / Int64(bitRate))
        }
    }
    
}

