//
//  EnumSet.swift
//  AboutAK_V3.0
//
//  Created by XYoung on 2019/5/22.
//  Copyright © 2019 timedomAIn. All rights reserved.
//

import UIKit

class EnumSet: NSObject {
    
}

// MARK: - iPhone屏幕类型 ==============================
extension EnumSet {
    enum iPhoneType: String {
        case iPhone = "{375, 667}"
        case iPhonePlus = "{414, 736}"
        case iPhoneX = "{375, 812}"
        case iPhoneXsMax = "{414, 896}"
        
    }
    
    static func screenSize(type: iPhoneType) -> CGSize {
        let screenSize = NSCoder.cgSize(for: type.rawValue)
        
        return screenSize
        
    }
}

// MARK: - 基本数据类型 ==============================
extension EnumSet {
    enum TimeIntervalUnit: Int {
        /// 秒
        case second = 1
        /// 毫秒
        case millisecond = 1000
        /// 微秒
        case microsecond = 1000000
        
    }
    
}
