//
//  CommonNamingService.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

class CommonNamingService {
    static let hexadecimalPrefix = "0x"
    static let jsonExtension = "json"

    let name: NamingServiceName
    let providerUrl: String
    let networking: NetworkingLayer

    enum ContractType: String {
        case unsRegistry = "UNSRegistry"
        case cnsRegistry = "CNSRegistry"
        case ensRegistry = "ENSRegistry"
        case resolver = "Resolver"
        case proxyReader = "ProxyReader"

        var name: String {
            self.rawValue
        }
    }

    init(name: NamingServiceName, providerUrl: String, networking: NetworkingLayer) {
        self.name = name
        self.providerUrl = providerUrl
        self.networking = networking
    }

    func buildContract(address: String, type: ContractType) throws -> Contract {
        return try self.buildContract(address: address, type: type, providerUrl: self.providerUrl)
    }

    func buildContract(address: String, type: ContractType, providerUrl: String) throws -> Contract {
        let jsonFileName: String
        let url = providerUrl
        let nameLowCased = name.rawValue.lowercased()
        switch type {
        case .unsRegistry:
            jsonFileName = "\(nameLowCased)Registry"
        case .ensRegistry:
            jsonFileName = "\(nameLowCased)Registry"
        case .cnsRegistry:
            jsonFileName = "cnsRegistry"
        case .resolver:
            jsonFileName = "\(nameLowCased)Resolver"
        case .proxyReader:
            jsonFileName = "\(nameLowCased)ProxyReader"
        }

        let abi: ABIContract = try parseAbi(fromFile: jsonFileName)!
        return Contract(providerUrl: url, address: address, abi: abi, networking: networking)
    }

    func parseAbi(fromFile name: String) throws -> ABIContract? {
        #if INSIDE_PM
        let bundler = Bundle.module
        #else
        let bundler = Bundle(for: type(of: self))
        #endif
        if let filePath = bundler.url(forResource: name, withExtension: "json") {
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
        return "\(Self.hexadecimalPrefix)\(node.toHexString())"
    }

    func childHash(parent: [UInt8], label: [UInt8]) -> [UInt8] {
        let childHash = label.sha3(.keccak256)
        return (parent + childHash).sha3(.keccak256)
    }
}

extension CommonNamingService {
    static let networkConfigFileName = "uns-config"
    static let recordKeysFileName = "resolver-keys"
    static let networkIds = ["mainnet": "1",
                             "ropsten": "3",
                             "goerli": "5",
                             "polygon-mumbai": "80001",
                             "polygon-mainnet": "137"
    ]
    static let networkToBlockchain = [
        "mainnet": "ETH",
        "goerli": "ETH",
        "polygon-mumbai": "MATIC",
        "polygon-mainnet": "MATIC"
    ]

    struct NewtorkConfigJson: Decodable {
        let version: String
        let networks: [String: ContractsEntry]
    }

    struct ResolverKeysJson: Decodable {
        let version: String
        let keys: [String: RecordEntry]
    }

    struct RecordEntry: Decodable {
        let deprecatedKeyName: String
        let deprecated: Bool
        let validationRegex: String?
    }

    struct ContractsEntry: Decodable {
        let contracts: [String: ContractAddressEntry]
    }

    struct ContractAddressEntry: Decodable {
        let address: String
        let legacyAddresses: [String]
        let deploymentBlock: String
    }

    static func parseContractAddresses(network: String) throws -> [String: ContractAddressEntry]? {
        #if INSIDE_PM
        let bundler = Bundle.module
        #else
        let bundler = Bundle(for: self)
        #endif

        guard let idString = networkIds[network] else { return nil }

        if let filePath = bundler.url(forResource: Self.networkConfigFileName, withExtension: "json") {
            guard let data = try? Data(contentsOf: filePath) else { return nil }
            guard let info = try? JSONDecoder().decode(NewtorkConfigJson.self, from: data) else { return nil }
            guard let currentNetwork = info.networks[idString] else { return nil }
            return currentNetwork.contracts
        }
        return nil
    }

    static func parseRecordKeys() throws -> [String]? {
        #if INSIDE_PM
        let bundler = Bundle.module
        #else
        let bundler = Bundle(for: self)
        #endif

        if let filePath = bundler.url(forResource: Self.recordKeysFileName, withExtension: "json") {
            guard let data = try? Data(contentsOf: filePath) else { return nil }
            guard let recordFile = try? JSONDecoder().decode(ResolverKeysJson.self, from: data) else { return nil }
            let keyEntries = recordFile.keys
            let keys = Array(keyEntries.keys)
            return keys
        }
        return nil
    }

    static func getNetworkName(providerUrl: String, networking: NetworkingLayer) throws -> String {
        let networkId = try Self.getNetworkId(providerUrl: providerUrl, networking: networking)
        return networkIds.key(forValue: networkId) ?? ""
    }

    static func getNetworkId(providerUrl: String, networking: NetworkingLayer) throws -> String {
        let url = URL(string: providerUrl)!
        let payload: JsonRpcPayload = JsonRpcPayload(jsonrpc: "2.0", id: "67", method: "net_version", params: [])

        var resp: JsonRpcResponseArray?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)

        networking.makeHttpPostRequest(
            url: url,
            httpMethod: "POST",
            httpHeaderContentType: "application/json",
            httpBody: try JSONEncoder().encode(payload)
        ) { result in
            switch result {
            case .success(let response):
                resp = response
            case .failure(let error):
                err = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        guard err == nil else {
            throw err!
        }
        switch resp?[0].result {
        case .string(let result):
            return result
        default:
            return ""
        }
    }
}

fileprivate extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}
