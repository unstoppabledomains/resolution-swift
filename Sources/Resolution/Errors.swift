//
//  Errors.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public enum ResolutionError: Error {
    case unregisteredDomain
    case unsupportedDomain
    case unconfiguredDomain
    case recordNotFound
    case unsupportedNetwork
    case unspecifiedResolver
    case unknownError(Error)
}

enum OtherError: Error {
    case runtimeError(String)
}
