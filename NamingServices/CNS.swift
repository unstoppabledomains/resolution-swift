//
//  CNS.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
import CryptoSwift

class CNS:NamingService {
    let name: String = "CNS";
    let network: String;
    let providerUrl: String;
    
    init(network: String, providerUrl: String) throws {
        if (network != "mainnet" ) {
            throw ResolutionError.UnsupportedNetwork;
        }
        self.network = network;
        self.providerUrl = providerUrl;
    }
    
    func namehash(domain: String) -> String {
        var node = Array<UInt8>.init(repeating: 0x0, count: 32)
        if domain.count > 0 {
            node = domain.split(separator: ".")
                .map { Array($0.utf8).sha3(.keccak256) }
                .reversed()
                .reduce(node) { return ($0 + $1).sha3(.keccak256) }
        }
            return "0x" + node.toHexString()
    }
    
    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".crypto");
    }
}
