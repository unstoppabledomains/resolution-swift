//
//  Types.swift
//  Resolution
//
//  Created by Serg Merenkov on 9/8/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public typealias StringResult = (Result<String, ResolutionError>) -> Void
public typealias DictionaryResult = (Result<[String: String], ResolutionError>) -> Void
