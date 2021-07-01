//
//  Contract.swift
//  resolution
//
//  Created by Johnny Good on 8/12/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

struct IdentifiableResult<T> {
    var id: String
    var result: T
}

import Foundation
internal class Contract {
    let batchIdOffset = 128

    static let ownersKey = "owners"
    static let resolversKey = "resolvers"
    static let valuesKey = "values"

    let address: String
    let providerUrl: String
    let coder: ABICoder
    let networking: NetworkingLayer

    init(providerUrl: String, address: String, abi: ABIContract, networking: NetworkingLayer) {
        self.address = address
        self.providerUrl = providerUrl
        self.coder = ABICoder(abi)
        self.networking = networking
    }

    func callMethod(methodName: String, args: [Any]) throws -> Any {
        let encodedData = try self.coder.encode(method: methodName, args: args)
        let body = JsonRpcPayload(id: "1", data: encodedData, to: address)
        let response = try postRequest(body)!
        guard case .string(let result) = response else {
            throw ResolutionError.badRequestOrResponse
        }
        return try self.coder.decode(result, from: methodName)
    }

    func getLogs(eventName: String, params: [String:String]) throws -> [[String: Any]] {
        let topics = try self.coder.encodeEventTopics(eventName: eventName, params: params)
        let body = JsonRpcPayload(jsonrpc: "2.0", id: "1", method: "eth_getLogs", params: [ParamElement.dictionary(
                                                                        [
                                                                            "address": ParamElement.string(self.address),
                                                                            "fromBlock" : ParamElement.string("earliest"), 
                                                                            "toBlock" : ParamElement.string("latest"),
                                                                            "topics": ParamElement.array(topics.map({str in ParamElement.string(str)}))
                                                                        ])
                                                                    ])
        let response = try postRequest(body)!
        guard case .array(let resultArray) = response else {
            throw ResolutionError.badRequestOrResponse
        }
        var eventLogs: [[String: Any]] = []
        for resultItem in resultArray {
            guard case .dictionary(let result) = resultItem else {
                throw ResolutionError.badRequestOrResponse
            }
            let data = try self.stringParamElementToData(result["data"])

            guard case .array(let resultTopicsArray) = result["topics"] else {
                throw ResolutionError.badRequestOrResponse
            }
            let resultTopics = try resultTopicsArray.map({topic in try self.stringParamElementToData(topic)})
            eventLogs.append(try self.coder.decodeEventTopics(eventName: eventName, eventLogTopics: resultTopics, eventLogData: data))
        }
        return eventLogs
    }

    func callBatchMethod(methodName: String, argsArray: [[Any]]) throws -> [IdentifiableResult<Any?>] {
        let encodedDataArray = try argsArray.map { try self.coder.encode(method: methodName, args: $0) }
        let bodyArray: [JsonRpcPayload] = encodedDataArray.enumerated()
                                                            .map { JsonRpcPayload(id: String($0.offset + batchIdOffset),
                                                                                  data: $0.element,
                                                                                  to: address) }
        let response = try postBatchRequest(bodyArray)
        return try response.map {
            guard let responseElement = $0 else {
                throw ResolutionError.recordNotSupported
            }

            var res: Any?
            do {
                res = try self.coder.decode(responseElement.result, from: methodName)
            } catch ABICoderError.couldNotDecode {
                res = nil
            }
            return IdentifiableResult<Any?>(id: responseElement.id, result: res)
        }
    }

    private func postRequest(_ body: JsonRpcPayload) throws -> ParamElement? {
        let postRequest = APIRequest(providerUrl, networking: networking)
        var resp: JsonRpcResponseArray?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        try postRequest.post(body, completion: {result in
            switch result {
            case .success(let response):
                resp = response
            case .failure(let error):
                err = error
            }
            semaphore.signal()
        })
        semaphore.wait()
        guard err == nil else {
            throw err!
        }
        return resp?[0].result
    }

    private func postBatchRequest(_ bodyArray: [JsonRpcPayload]) throws -> [IdentifiableResult<String>?] {
        let postRequest = APIRequest(providerUrl, networking: networking)
        var resp: JsonRpcResponseArray?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        try postRequest.post(bodyArray, completion: {result in
            switch result {
            case .success(let response):
                resp = response
            case .failure(let error):
                err = error
            }
            semaphore.signal()
        })
        semaphore.wait()
        guard err == nil else {
            throw err!
        }

        guard let responseArray = resp else { throw APIError.decodingError }

        let parsedResponseArray: [IdentifiableResult<String>?] = responseArray.map {
            if case let ParamElement.string( stringResult ) = $0.result {
                return IdentifiableResult<String>(id: $0.id, result: stringResult)
            }
            return nil
        }
        return parsedResponseArray
    }

    private func stringParamElementToData(_ param: ParamElement?) throws -> Data {
        guard case .string(let paramString) = param else {
            throw ResolutionError.badRequestOrResponse
        }
        return Data(hex: paramString)
    }
}
