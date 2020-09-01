//
//  Errors.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

public enum ResolutionError: Equatable, Error {
    case UnregisteredDomain
    case UnsupportedDomain
    case UnconfiguredDomain
    case RecordNotFound
    case UnsupportedNetwork
    case UnknownError(Error)

    static public func == (lhs: ResolutionError, rhs: ResolutionError) -> Bool {
        switch (lhs, rhs) {
        case ( .UnregisteredDomain, .UnregisteredDomain):
            return true
        case ( .UnsupportedDomain, .UnsupportedDomain):
            return true
        case ( .UnconfiguredDomain, .UnconfiguredDomain):
            return true
        case ( .RecordNotFound, .RecordNotFound):
            return true
        case ( .UnsupportedNetwork, .UnsupportedNetwork):
            return true
        case ( .UnknownError(_), .UnknownError(_)):
            return false
        default:
            return false
        }
    }
}
