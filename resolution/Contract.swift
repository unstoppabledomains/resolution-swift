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
    
    func fetchMethod(methodName: String, args: [String]) -> Any? {
        do {
            let encodedData = try self.coder.encode(method: methodName, args: args);
            print(encodedData);
            return nil;
        } catch {
            print(error);
        }
        return nil;
    }
    
    
    private func postRequest(url: URL, params: String) -> Any {
        // Need to perform a post request
        return "some data from the providerUrl"
    }
}
