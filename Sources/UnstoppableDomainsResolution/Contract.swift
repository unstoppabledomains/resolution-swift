//
//  Contract.swift
//  resolution
//
//  Created by Johnny Good on 8/12/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
internal class Contract {
    static let OWNER_KEY = "owner"
    static let RESOLVER_KEY = "resolver"
    static let VALUES_KEY = "values"

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
            let body: JsonRpcPayload = JsonRpcPayload(
                jsonrpc: "2.0",
                id: "1",
                method: "eth_call",
                params: [
                    ParamElement.paramClass(ParamClass(data: encodedData, to: address)),
                    ParamElement.string("latest")
                ]
            )
            let response = try postRequest(body)!
            return try self.coder.decode(response, from: methodName)
    }
    
    func callBatchMethod(methodName: String, argsArray: [[Any]]) throws -> [Any] {
        let encodedDataArray = try argsArray.map { try self.coder.encode(method: methodName, args: $0) }
        let bodyArray: [JsonRpcPayload] = encodedDataArray.map { JsonRpcPayload(
            jsonrpc: "2.0",
            id: "1",
            method: "eth_call",
            params: [
                ParamElement.paramClass(ParamClass(data: $0, to: address)),
                ParamElement.string("latest")
            ]
        ) }
        let response = try postBatchRequest(bodyArray)!
        return try self.coder.decode(response, from: methodName)
}

    private func postRequest(_ body: JsonRpcPayload) throws -> String? {
        let postRequest = APIRequest(providerUrl, networking: networking)
        var resp: JsonRpcResponse?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        postRequest.post(body, completion: {result in
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
        switch resp?.result {
        case .string(let result):
            return result
        default:
            return nil
        }
    }
    
    private func postBatchRequest(_ bodyArray: [JsonRpcPayload]) throws -> String? {
        let postRequest = APIRequest(providerUrl, networking: networking)
        var resp: JsonRpcResponse?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        postRequest.post(bodyArray, completion: {result in
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
        switch resp?.result {
        case .string(let result):
            return result
        default:
            return nil
        }
        
        
        
    }
}
