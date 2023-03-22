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
    case recordNotFound(String)
    case recordNotSupported
    case unsupportedNetwork
    case unspecifiedResolver(String)
    case unknownError(Error)
    case proxyReaderNonInitialized
    case registryAddressIsNotProvided
    case inconsistentDomainArray
    case methodNotSupported
    case tooManyResponses
    case executionReverted
    case badRequestOrResponse
    case unsupportedServiceName
    case invalidDomainName
    case contractNotInitialized(String)
    case reverseResolutionNotSpecified
    case unauthenticatedRequest
    case requestBeingRateLimited


    static let tooManyResponsesCode = -32005
    static let badRequestOrResponseCode = -32042

    static func parse (errorResponse: NetworkErrorResponse) -> ResolutionError? {
        let error = errorResponse.error

        if error.message.starts(with: "execution reverted") {
            return .executionReverted
        }

        switch error.code {
        case tooManyResponsesCode:
            return .tooManyResponses
        case badRequestOrResponseCode:
            return .badRequestOrResponse
        default:
            return nil
        }
    }
}

struct NetworkErrorResponse: Decodable {
    var jsonrpc: String
    var id: String
    var error: ErrorId
}

struct ErrorId: Codable {
    var code: Int
    var message: String
    var data: String?
}
