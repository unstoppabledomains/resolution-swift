//
//  Contract.swift
//  resolution
//
//  Created by Johnny Good on 8/12/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
internal class Contract {
    let address: String;
    let providerUrl: String;
    let coder: ABICoder;
    
    init(providerUrl: String, address: String, abi: ABI) {
        self.address = address;
        self.providerUrl = providerUrl;
        self.coder = ABICoder(abi);
    }
    
    func fetchMethod(methodName: String, args: [String]) throws -> String? {
            let encodedData = try self.coder.encode(method: methodName, args: args);
            let body: JSON_RPC_REQUEST = JSON_RPC_REQUEST(
                jsonrpc: "2.0",
                id: "1",
                method: "eth_call",
                params: [
                    ParamElement.paramClass(ParamClass(data: encodedData, to: address)),
                    ParamElement.string("latest")
                ]
            );
            let response = try postRequest(body)!;
            return try self.coder.decode(response, from: methodName);
    }
    
    private func postRequest(_ body: JSON_RPC_REQUEST) throws -> String? {
        let postRequest = APIRequest(providerUrl);
        var resp:JSON_RPC_RESPONSE?;
        var err: Error?;
        let semaphore = DispatchSemaphore(value: 0)
        postRequest.post(body, completion: {result in
            switch result {
            case .success(let response):
                resp = response;
            case .failure(let error):
                err = error;
            }
            semaphore.signal()
        })
        semaphore.wait()
        guard err == nil else {
            throw err!;
        }
        return resp?.result;
    }
}
