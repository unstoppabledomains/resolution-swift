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
    let ABI: ABI;
    let providerUrl: String;
    
    init(providerUrl: String, address: String, ABI: ABI) {
        self.address = address;
        self.ABI = ABI;
        self.providerUrl = providerUrl
    }
    
    func fetchMethod(methodName: String, args: [String]) -> Any? {
        let element: ABIElement? = findAbiElement(methodName: methodName, args: args, abi: self.ABI)
        if (element == nil) { return nil; }
        let encodedData = encodeAbiElement(element: element!)
        return nil;
    }
    
    private func findAbiElement(methodName: String, args: [String], abi: ABI) -> ABIElement? {
        let method = abi.first(where: {$0.name == methodName && $0.inputs.count == args.count});
        return method ?? nil;
    }
    
    private func encodeAbiElement(element: ABIElement) -> String {
        // Need to encode the data somehow, probably look for some ABIEncoder swift package
        return "encoded data ?? "
    }
    
    private func postRequest(url: URL, params: String) -> Any {
        // Need to perform a post request
        return "some data from the providerUrl"
    }
}
