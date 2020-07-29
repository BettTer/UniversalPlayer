//
//  GenericFuncs.swift
//  UniversalPlayer
//
//  Created by XC_Young on 2020/7/29.
//  Copyright © 2020 X_Young. All rights reserved.
//

import UIKit

class GenericFuncs: NSObject {
    static let shared = GenericFuncs()
    
}

// MARK: - 指针
extension GenericFuncs {
    func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }

    func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
    }

    func bridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
    }

    func bridgeTransfer<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()
    }
    
}
