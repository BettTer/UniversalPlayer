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
        
//        let manager = AudioStreamManager()
//        manager.setAudioFileStreamOpen()
        
        
        let player = STKAudioPlayer.init()
        player.play(URL.init(string: "https://s320.xiami.net/259/23259/456120/1770378795_1518231746311.mp3?ccode=xiami_web_web&expire=86400&duration=215&psid=7a323645161be2d9fd9f7e62d88528fc&ups_client_netip=58.250.250.75&ups_ts=1595992774&ups_userid=0&utid=vlWcF5lJhiYCATr6+ktk+5A0&vid=1770378795&fn=1770378795_1518231746311.mp3&vkey=Bf285554922fafaa118dce8f106cfcc3a")!)
        
        
    }


}

