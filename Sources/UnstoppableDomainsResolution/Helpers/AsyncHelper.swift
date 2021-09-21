////
////  AsyncHelper.swift
////  UnstoppableDomainsResolution
////
////  Created by Johnny Good on 9/9/21.
////  Copyright © 2021 Unstoppable Domains. All rights reserved.
////
//
// import Foundation
//
// internal class AsyncHelper {
//    static let asyncGroup = DispatchGroup();
//    static let dispatchQueue = DispatchQueue.global();
//    
//    static func resolve(l1func: () -> (), l2func: () -> (), completion: @escaping ) {
//        Self.asyncGroup.enter();
//        Self.dispatchQueue.async {
//            l1func();
//            Self.asyncGroup.leave();
//        }
//        Self.asyncGroup.enter();
//        Self.dispatchQueue.async {
//            l2func();
//            Self.asyncGroup.leave();
//        }
//        Self.asyncGroup.notify(queue: Self.dispatchQueue) {
//            
//        }
//        
//    }
//    
//    
//    
//    
//    
//    
// }
