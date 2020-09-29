//
//  CommonNamingService.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
import EthereumABI

class CommonNamingService {
    static let HEXADECIMAL_PREFIX = "0x"
    static let JSON_EXTENSION = "json"

    let name: String
    let providerUrl: String
    let networking: NetworkingLayer

    enum ContractType {
        case registry
        case resolver
        case proxyReader
    }

    init(name: String, providerUrl: String, networking: NetworkingLayer) {
        self.name = name
        self.providerUrl = providerUrl
        self.networking = networking
    }

    func buildContract(address: String, type: ContractType) throws -> Contract {
        let jsonFileName: String

        let nameLowCased = name.lowercased()
        switch type {
        case .registry:
            jsonFileName = "\(nameLowCased)Registry"
        case .resolver:
            jsonFileName = "\(nameLowCased)Resolver"
        case .proxyReader:
            jsonFileName = "\(nameLowCased)ProxyReader"
        }

        let abi: ABIContract = try parseAbi(fromFile: jsonFileName)!
        return Contract(providerUrl: self.providerUrl, address: address, abi: abi, networking: networking)
    }

    func parseAbi(fromFile name: String) throws -> ABIContract? {
        if let filePath = Bundle(for: type(of: self)).url(forResource: name, withExtension: "json") {
            let data = try Data(contentsOf: filePath)
            let jsonDecoder = JSONDecoder()
            let abi = try jsonDecoder.decode([ABI.Record].self, from: data)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })

            return abiNative
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
        return "\(Self.HEXADECIMAL_PREFIX)\(node.toHexString())"
    }

    func childHash(parent: [UInt8], label: [UInt8]) -> [UInt8] {
        let childHash = label.sha3(.keccak256)
        return (parent + childHash).sha3(.keccak256)
    }
}
