//
//  Errors.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

public enum ResolutionError: Error {
    case unregisteredDomain
    case unsupportedDomain
    case unconfiguredDomain
    case recordNotFound
    case unsupportedNetwork
    case unknownError(Error)
}
