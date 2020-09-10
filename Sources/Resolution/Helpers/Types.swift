//
//  Types.swift
//  Resolution
//
//  Created by Admin on 08.09.20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

public typealias StringResult = (Result<String, ResolutionError>) -> Void
public typealias DictionaryResult = (Result<[String: String], ResolutionError>) -> Void
