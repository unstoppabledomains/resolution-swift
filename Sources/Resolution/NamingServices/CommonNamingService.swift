//
//  CommonNamingService.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
import CryptoSwift

class CommonNamingService {
    let name: String
    let providerUrl: String

    enum ContractType {
        case registry
        case resolver
    }

    init(name: String, providerUrl: String) {
        self.name = name
        self.providerUrl = providerUrl
    }

    func buildContract(address: String, type: ContractType) throws -> Contract {
        var jsonFileName: String

        switch type {
        case .registry:
            jsonFileName = "\(name.lowercased())Registry"
        case .resolver:
            jsonFileName = "\(name.lowercased())Resolver"
        }

        let abi: ABI = try parseAbi(fromFile: jsonFileName)!
        return Contract(providerUrl: self.providerUrl, address: address, abi: abi)
    }

    func parseAbi(fromFile name: String) throws -> ABI? {
        if let filePath = Bundle(for: type(of: self)).url(forResource: name, withExtension: "json") {
            let data = try Data(contentsOf: filePath)
            let jsonDecoder = JSONDecoder()
            let dataFromJson = try jsonDecoder.decode(ABI.self, from: data)
            return dataFromJson
        }
        return nil
    }

    func namehash(domain: String) -> String {
        var node = [UInt8].init(repeating: 0x0, count: 32)
        if domain.count > 0 {
            node = domain.split(separator: ".")
                .map { Array($0.utf8)}
                .reversed()
                .reduce(node) { return self.childHash(parent: $0, label: $1)}
        }
        return "0x" + node.toHexString()
    }

    func childHash(parent: [UInt8], label: [UInt8]) -> [UInt8] {
        let childHash = label.sha3(.keccak256)
        return (parent + childHash).sha3(.keccak256)
    }
}
