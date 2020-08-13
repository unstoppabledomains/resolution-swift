//
//  ABIElement.swift
//  resolution
//
//  Created by Johnny Good on 8/12/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
protocol ABIElement { }

extension RegistryElement: ABIElement {}
extension ResolverElement: ABIElement {}

typealias ABI = [ABIElement]
