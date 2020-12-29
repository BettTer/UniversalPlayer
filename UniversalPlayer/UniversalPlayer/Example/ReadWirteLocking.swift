//
//  ReadWirteLocking.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/12/25.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit

/// 读写锁
class ReadWirteLocking: NSObject {
    /// 并发队列
    static let concurrentQueue = DispatchQueue.init(label: "ReadWirteLocking_concurrentQueue", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    private var recordTestObj: NSObject?
    
    var testObj: NSObject? {
        set {
            ReadWirteLocking.concurrentQueue.async(group: nil, qos: .default, flags: .barrier) {
                self.recordTestObj = newValue
                
            }
            
        }
        
        get {
            
            ReadWirteLocking.concurrentQueue.sync { () -> NSObject? in
                return recordTestObj
                
            }
            
        }
    }
    
}
