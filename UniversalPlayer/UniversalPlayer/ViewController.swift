//
//  ViewController.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/28.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit
import StreamingKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // * 加载文件
        let filePath = Bundle.main.path(forResource: "情 乱 夜 梦 東 京 - Nanvo", ofType: "mp3")!
        let file = FileHandle.init(forReadingAtPath: filePath)!
        defer {
            file.closeFile()
        }
        var fileSize = try! FileManager.default.attributesOfItem(atPath: filePath)[.size] as! Int
        
        let audioStreamManager = AudioStreamManager.init(fileSize: fileSize) { (error, manager)  in
            if let _ = error {
                print(error!)
                print("初始化失败")
                return
                
            }
            
            print("初始化成功")
            let lengthPerRead = 10000
            
            while fileSize > 0 {
                let data = file.readData(ofLength: lengthPerRead)
                fileSize -= data.count
                
                let error = manager!.parseData(data: data)
                
                if let beingError = error {
                    
                    if beingError.code == kAudioFileStreamError_NotOptimized {
                        print("audio not optimized.")
                        
                    }
                    
                    break
                }
                
                
            }
            
            print("audio format: bitrate = \(manager!.bitRate), duration = \(manager!.duration).")
            manager!.closeAudioFileStream()
            
        }
        

        
        
//        let player = STKAudioPlayer.init()
//        player.play(URL.init(string: "https://s320.xiami.net/259/23259/456120/1770378795_1518231746311.mp3?ccode=xiami_web_web&expire=86400&duration=215&psid=7a323645161be2d9fd9f7e62d88528fc&ups_client_netip=58.250.250.75&ups_ts=1595992774&ups_userid=0&utid=vlWcF5lJhiYCATr6+ktk+5A0&vid=1770378795&fn=1770378795_1518231746311.mp3&vkey=Bf285554922fafaa118dce8f106cfcc3a")!)
        
        
    }


}

