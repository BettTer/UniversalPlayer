//
//  YYAudioPlayer.swift
//  UniversalPlayer
//
//  Created by X.Young on 2020/8/30.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import CoreAudio
import AudioToolbox

enum PlayerStatus: Int {
    case Stopped = 0
    case Playing
    case Waiting
    case Paused
    case Flushing
    
}

class YYAudioPlayer: NSObject {
    let filePath: String!
    let fileType: AudioFileTypeID!
    
    private (set) var currentStatus: PlayerStatus!
    private (set) var isPlayingOrWaiting = false
    private (set) var isFailed = false
    
    private (set) var progress: TimeInterval = 0
    private (set) var duration: TimeInterval = 0
    
    init(filePath: String, fileType: AudioFileTypeID = 0) {
        self.filePath = filePath
        self.fileType = fileType
        
        super.init()
        
        
        
    }
    
    

}
