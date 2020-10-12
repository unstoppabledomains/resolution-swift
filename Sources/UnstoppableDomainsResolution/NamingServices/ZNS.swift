//
//  ZNS.swift
//  Resolution
//
//  Created by Serg Merenkov on 9/8/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class ZNS: CommonNamingService, NamingService {
    var network: String

    let registryAddress: String
    let registryMap: [String: String] = [
        "mainnet": "0x9611c53be6d1b32058b2747bdececed7e1216793"
    ]
    
    let ARGUMENTS_KEY = "arguments"

    init(network: String, providerUrl: String, networking: NetworkingLayer) throws {
        guard let registryAddress = registryMap[network] else {
            throw ResolutionError.unsupportedNetwork
        }
        self.network = network
        self.registryAddress = registryAddress
        super.init(name: "ZNS", providerUrl: providerUrl, networking: networking)
    }

    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".zil")
    }

    func owner(domain: String) throws -> String {
        let recordAddresses = try self.recordsAddresses(domain: domain)
        let (ownerAddress, _ ) = recordAddresses
        guard Utillities.isNotEmpty(ownerAddress) else {
                throw ResolutionError.unregisteredDomain
        }

        return ownerAddress
    }
    
    //stub
    func batchOwners(domains: [String]) throws -> [String?] {
        let recordAddressesArray = try self.recordsAddressesBatch(domains: domains)
//        let (ownerAddress, _ ) = recordAddresses
//        guard Utillities.isNotEmpty(ownerAddress) else {
//                throw ResolutionError.unregisteredDomain
//        }
//
//        return ownerAddress
    }

    func addr(domain: String, ticker: String) throws -> String {
        let key = "crypto.\(ticker.uppercased()).address"
        let result = try record(domain: domain, key: key)
        return result
    }

    func record(domain: String, key: String) throws -> String {
        let records = try self.records(keys: [key], for: domain)

        guard
            let record = records[key] else {
            throw ResolutionError.recordNotFound
        }

        return record
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        guard let records = try self.records(address: try resolver(domain: domain), keys: keys) as? [String: String] else {
            throw ResolutionError.recordNotFound
        }
        return records
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let recordAddresses = try self.recordsAddresses(domain: domain)
        let (_, resolverAddress ) = recordAddresses
        guard Utillities.isNotEmpty(resolverAddress) else {
            throw ResolutionError.unspecifiedResolver
        }

        return resolverAddress
    }

    // MARK: - CommonNamingService
    override func childHash(parent: [UInt8], label: [UInt8]) -> [UInt8] {
        return (parent + label.sha2(.sha256)).sha2(.sha256)
    }

    // MARK: - Helper functions

    private func recordsAddresses(domain: String) throws -> (String, String) {

        guard self.isSupported(domain: domain) else {
            throw ResolutionError.unsupportedDomain
        }

        let namehash = self.namehash(domain: domain)
        let records = try self.records(address: self.registryAddress, keys: [namehash])

        guard
            let record = records[namehash] as? [String: Any],
            let arguments = record[ARGUMENTS_KEY] as? [Any], arguments.count == 2,
            let ownerAddress = arguments[0] as? String, let resolverAddress = arguments[1] as? String
            else {
                throw ResolutionError.unregisteredDomain
        }

        return (ownerAddress, resolverAddress)
    }
    
    private func recordsAddressesBatch(domains: [String]) throws -> ([String], [String]) {
        guard domains.map({ self.isSupported(domain: $0) })
                .reduce(true, {allSupported, isSupported in return allSupported && isSupported}) else {
            throw ResolutionError.unsupportedDomain
        }
        let namehashArray = domains.map { self.namehash(domain: $0) }
        let recordsArray: [[String: Any]] = try self.batchRecords(address: self.registryAddress, keysArray: [[namehash]])
        
        guard
            let recordArray = recordsArray.map({ $0[namehash] as? [String: Any] }), recordArray.areAllNonNil,
            let argumentsArray = recordArray.map ({ $0[ARGUMENTS_KEY] as? [Any] }), argumentsArray.map({$0.count == 2}).areAllTrue,
            //let arguments = record["arguments"] as? [Any], arguments.count == 2,
            let ownerAddressArray = argumentsArray.map ({ $0[0] as? String }), ownerAddressArray.areAllNonNil,
            let resolverAddressArray = argumentsArray.map ({ $0[1] as? String }), resolverAddressArray.areAllNonNil
            else {
                throw ResolutionError.unregisteredDomain
        }

        return (ownerAddressArray, resolverAddressArray)
    }

    private func records(address: String, keys: [String] = []) throws -> [String: Any] {
        let resolverContract: ContractZNS = self.buildContract(address: address)

        guard let records = try resolverContract.fetchSubState(
                    field: "records",
                    keys: keys
                  ) as? [String: Any]
        else {
            throw ResolutionError.unspecifiedResolver
        }

      return records
    }
    
    private func batchRecords(address: String, keysArray: [[String]] = [[]]) throws -> [[String: Any]] {
        
        
    }

    func buildContract(address: String) -> ContractZNS {
        return ContractZNS(providerUrl: self.providerUrl, address: address.replacingOccurrences(of: "0x", with: ""), networking: networking)
    }

}

extension Array where Element == Bool {
    var areAllTrue: Bool {
        self.reduce(true, {all, element in all && element})
    }
}
extension Array where Element == Optional<Any> {
    var areAllNonNil: Bool {
        self.reduce(true, {all, element in all && (element != nil) })
    }
}
