//
//  Thread+Utilites.swift
//  PhotosAppViewer
//
//  Created by Praveen Sitaraman on 5/7/17.
//  Copyright © 2017 Praveen Sitaraman. All rights reserved.
//

import Foundation

extension Thread {
    
    /**
     Executes code block on main thread
     - parameter block: escaping block of code to be executed
     */
    static func executeOnMainThread(block: @escaping () -> ()) {
        
        guard !Thread.isMainThread else {
            block()
            return
        }
        
        DispatchQueue.main.async {
            block()
        }
    }
    
    /**
     Executes code block on background thread
     - parameter qos: quality of service level, defaults to .default
     - parameter isAsynchronous: indicates whether to execute code block synchronously or asynchronously, defaults to bool true which means the block, by default, is executed asynchronously
     - parameter block: escaping block of code to be executed
     */
    static func executeOnBackgroundThread(qos: DispatchQoS.QoSClass = .default, isAsynchronous: Bool = true, block: @escaping () -> ()) {
        
        guard Thread.isMainThread else {
            block()
            return
        }
        
        guard isAsynchronous else {
            
            DispatchQueue.global(qos: qos).sync {
                block()
            }
            return
        }
        
        DispatchQueue.global(qos: qos).async {
            block()
        }
    }
}

