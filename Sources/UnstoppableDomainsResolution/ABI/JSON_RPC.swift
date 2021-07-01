//
//  JSON_RPC.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct JsonRpcPayload: Codable {
    let jsonrpc, id, method: String
    let params: [ParamElement]

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    init(jsonrpc: String, id: String, method: String, params: [ParamElement]) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }

    init (id: String, data: String, to address: String) {
        self.init(jsonrpc: "2.0",
                  id: id,
                  method: "eth_call",
                  params: [
                    ParamElement.paramClass(ParamClass(data: data, to: address)),
                    ParamElement.string("latest")
                  ])
    }

    init (params: ParamLogClass) {
        self.init(
            jsonrpc: "2.0",
              id: "1.0",
              method: "eth_getLogs",
              params: [
                  ParamElement.paramLogClass(params)
              ]
        )
    }
}

public enum ParamElement: Codable {
    case paramClass(ParamClass)
    case paramLogClass(ParamLogClass)
    case paramLogResponse(JsonRpcLogResponse)
    case string(String)
    case array([ParamElement])
    case dictionary([String: ParamElement])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let elem = try? container.decode(String.self) {
            self = .string(elem)
            return
        }
        if let elem = try? container.decode(ParamClass.self) {
            self = .paramClass(elem)
            return
        }
        if let elem = try? container.decode(ParamLogClass.self) {
            self = .paramLogClass(elem)
            return
        }
        if let elem = try? container.decode(JsonRpcLogResponse.self) {
            self = .paramLogResponse(elem)
            return
        }
        if let elem = try? container.decode(Array<ParamElement>.self) {
            self = .array(elem)
            return
        }
        if let elem = try? container.decode([String: ParamElement].self) {
            self = .dictionary(elem)
            return
        }

        throw DecodingError.typeMismatch(ParamElement.self,
                                         DecodingError.Context(
                                            codingPath: decoder.codingPath,
                                            debugDescription: "Wrong type for ParamElement")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .paramClass(let elem):
            try container.encode(elem)
        case .paramLogClass(let elem):
            try container.encode(elem)
        case .paramLogResponse(let elem):
            try container.encode(elem)
        case .string(let elem):
            try container.encode(elem)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dict):
            try container.encode(dict)
        }
    }
}

public struct ParamClass: Codable {
    let data: String
    let to: String
}

public struct ParamLogClass: Codable {
    let fromBlock: String
    let address: String
    let topics: [String?]
}

public struct JsonRpcLogResponse: Codable {
    let address: String
    let blockHash: String
    let blockNumber: String
    let data: String
    let logIndex: String
    let removed: Bool
    let topics: [String]
    let transactionHash: String
    let transactionIndex: String
}

public struct JsonRpcResponse: Decodable {
    let jsonrpc: String
    let id: String
    let result: ParamElement

    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
    }
}
