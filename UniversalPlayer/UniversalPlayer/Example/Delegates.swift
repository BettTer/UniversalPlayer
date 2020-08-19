//
//  Delegates.swift
//  Test_ResponseEvent
//
//  Created by Young Robine on 2020/5/9.
//  Copyright © 2020 Young Robine. All rights reserved.
//  一对多代理的实现

import UIKit

@objc public protocol ColorDelegate {
    func setTargetColorWith(_ color: UIColor) -> Void
    
}

class MainManagar: NSObject {
    static let shared = MainManagar.init()
    
    private var itemDelegateMaptable = NSMapTable<NSObject, ColorDelegate>.init(keyOptions: .weakMemory, valueOptions: .strongMemory, capacity: 1)

    var targetColor: UIColor = .white {
        didSet {
            /// 列举者
            if let enumerator = itemDelegateMaptable.objectEnumerator() {
                
                while let itemDelegate = enumerator.nextObject() {
                    (itemDelegate as! ColorDelegate).setTargetColorWith(targetColor)
                    
                }
                
            }
            
        }
    }
    
    func addDelegate(_ delegate: ColorDelegate, owner: NSObject) -> Void {
        self.itemDelegateMaptable.setObject(delegate, forKey: owner)
            
    }
    
    func removeDelegate(owner: NSObject) {
        /// 列举者
        let enumerator = itemDelegateMaptable.keyEnumerator()
        
        let hasOwner = enumerator.allObjects.contains { $0 as! NSObject == owner }
        
        if hasOwner {
            self.itemDelegateMaptable.removeObject(forKey: owner)
            
        }

    }
    
}
