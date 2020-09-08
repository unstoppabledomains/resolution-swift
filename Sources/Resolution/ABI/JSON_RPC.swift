//
//  JSON_RPC.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

// swiftlint:disable type_name identifier_name
struct JSON_RPC_REQUEST: Codable {
    let jsonrpc, id, method: String
    let params: [ParamElement]
}

enum ParamElement: Codable {
    case paramClass(ParamClass)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let elem = try? container.decode(String.self) {
            self = .string(elem)
            return
        }
        if let elem = try? container.decode(ParamClass.self) {
            self = .paramClass(elem)
            return
        }
        throw DecodingError.typeMismatch(ParamElement.self,
                                         DecodingError.Context(
                                            codingPath: decoder.codingPath,
                                            debugDescription: "Wrong type for ParamElement")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .paramClass(let elem):
            try container.encode(elem)
        case .string(let elem):
            try container.encode(elem)
        }
    }
}

struct ParamClass: Codable {
    let data, to: String
}

struct JSON_RPC_RESPONSE: Codable {
    let jsonrpc, id, result: String
}
