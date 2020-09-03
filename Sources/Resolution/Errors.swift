//
//  Errors.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

public enum ResolutionError: Error {
    case UnregisteredDomain
    case UnsupportedDomain
    case UnconfiguredDomain
    case RecordNotFound
    case UnsupportedNetwork
    case UnknownError(Error)
}
