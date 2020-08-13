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
    
    func fetchMethod(methodName: String, args: [String]) {
        print("FETCHING METHOD \(methodName) WITH ARGS = \(args)");
        // I need to find an appropriate ABI element from the self.ABI
        let element: ABIElement = findAbiElement(methodName: methodName, args: args, abi: self.ABI)
        // I need to encode that element
        let encodedData = encodeAbiElement(element: element)
        // I need to send POST request to the providerURL with encoded data in params
        
        // I need to decode the result and return the answer
    }
    
    private func findAbiElement(methodName: String, args: [String], abi: ABI) -> ABIElement {
        // Need to look over the abi struct and find a method with methodNAme and args.length should be the same
        
        print("TRYING TO FIND ABIELEMENT WITH NAME \(methodName) AND ARGS.LENGTH = \(args.count)");
        
        
        return abi.first!;
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
