//
//  CommonNamingService.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
import CryptoSwift

class CommonNamingService {
    let name: String;
    let providerUrl: String;
    
    enum ContractType {
        case Registry;
        case Resolver;
    }
    
    init(name: String, providerUrl: String) {
        self.name = name;
        self.providerUrl = providerUrl
    }
    
    func buildContract(address: String, type: ContractType) throws -> Contract {
        var jsonFileName: String;
        
        switch type {
        case .Registry:
            jsonFileName = "\(name.lowercased())Registry"
        case .Resolver:
            jsonFileName = "\(name.lowercased())Resolver"
        }
        
        let abi: ABI = try parseAbi(fromFile: jsonFileName)!;
        return Contract(providerUrl: self.providerUrl, address: address, abi: abi);
    }
    
    func parseAbi(fromFile name: String) throws -> ABI? {
        if let filePath = Bundle(for: type(of: self)).url(forResource: name, withExtension: "json") {
            let data = try Data(contentsOf: filePath);
            let jsonDecoder = JSONDecoder();
            let dataFromJson = try jsonDecoder.decode(ABI.self, from: data);
            return dataFromJson;
        }
        return nil
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
}
