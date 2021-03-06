//
//  CNS.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
import EthereumAddress

internal class CNS: CommonNamingService, NamingService {
    struct ContractAddresses {
        let registryAddress: String
        let resolverAddress: String
        let proxyReaderAddress: String
    }

    static let specificDomain = ".crypto"
    static let name = "CNS"
    static let TransferEventSignature = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    static let NewURIEventSignature = "0xc5beef08f693b11c316c0c8394a377a0033c9cf701b8cd8afd79cecef60c3952"

    static let getDataForManyMethodName = "getDataForMany"

    let network: String
    let contracts: ContractAddresses
    var proxyReaderContract: Contract?

    init(_ config: NamingServiceConfig) throws {

        self.network = config.network.isEmpty
            ? try Self.getNetworkId(providerUrl: config.providerUrl, networking: config.networking)
            : config.network

        guard let contractsContainer = try Self.parseContractAddresses(network: network),
              let registry = contractsContainer[ContractType.registry.name]?.address,
              let resolver = contractsContainer[ContractType.resolver.name]?.address,
              let proxyReader = contractsContainer[ContractType.proxyReader.name]?.address else { throw ResolutionError.unsupportedNetwork }
        self.contracts = ContractAddresses(registryAddress: registry, resolverAddress: resolver, proxyReaderAddress: proxyReader)

        super.init(name: Self.name, providerUrl: config.providerUrl, networking: config.networking)
        proxyReaderContract = try super.buildContract(address: self.contracts.proxyReaderAddress, type: .proxyReader)
    }

    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(Self.specificDomain)
    }

    struct OwnerResolverRecord {
        let owner: String
        let resolver: String
        let record: String
    }

    // MARK: - geters of Owner and Resolver
    func owner(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        let res: Any
        do {
            res = try self.getDataForMany(keys: [Contract.ownersKey], for: [tokenId])
        } catch {
            if error is ABICoderError {
                throw ResolutionError.unregisteredDomain
            }
            throw error
        }
        guard let rec = self.unfoldForMany(contractResult: res, key: Contract.ownersKey),
              rec.count > 0 else {
            throw ResolutionError.unregisteredDomain
        }

        guard Utillities.isNotEmpty(rec[0]) else {
            throw ResolutionError.unregisteredDomain
        }
        return rec[0]
    }

    func batchOwners(domains: [String]) throws -> [String?] {
        let tokenIds = domains.map { super.namehash(domain: $0) }
        let res: Any
        do {
            res = try self.getDataForMany(keys: [Contract.ownersKey], for: tokenIds)
        } catch {
            throw error
        }
        guard let data = res as? [String: Any],
              let ownersFolded = data["1"] as? [Any] else {
            return []
        }
        return ownersFolded.map { let address = unfoldAddress($0)
            return Utillities.isNotEmpty(address) ? address : nil
        }
    }

    func tokensOwnedBy(address: String) throws -> [String] {
        let registryContract = try self.buildContract(address: self.contracts.registryAddress, type: .registry)
        let origin = self.getOriginBlockFrom(network: self.network)

        let transferLogs = try registryContract.callLogs(
                fromBlock: origin,
                signatureHash: Self.TransferEventSignature,
                for: address.normalized32,
                isTransfer: true
        ).compactMap {
            $0.topics[3]
        }

        let domainsData = try transferLogs.compactMap {
            try registryContract.callLogs(
                    fromBlock: origin,
                    signatureHash: Self.NewURIEventSignature,
                    for: $0.normalized32,
                    isTransfer: false
            )[0].data
        }

        let possibleDomains = Array(Set(
                domainsData.compactMap {
                    ABIDecoder.decodeSingleType(type: .string, data: Data(hex: $0)).value as? String
                }
            )
        )

        let owners = try batchOwners(domains: possibleDomains)
        var domains: [String] = []

        for (ind, addr) in owners.enumerated() where addr == address {
            domains.append(possibleDomains[ind])
        }
        return domains
    }

    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        let res: Any
        do {
            res = try self.getDataForMany(keys: [Contract.resolversKey], for: [tokenId])
        } catch {
            if error is ABICoderError {
                throw ResolutionError.unspecifiedResolver
            }
            throw error
        }
        guard let rec = self.unfoldForMany(contractResult: res, key: Contract.resolversKey),
              rec.count > 0  else {
            throw ResolutionError.unspecifiedResolver
        }
        guard Utillities.isNotEmpty(rec[0]) else {
            throw ResolutionError.unspecifiedResolver
        }
        return rec[0]
    }

    func addr(domain: String, ticker: String) throws -> String {
        let key = "crypto.\(ticker.uppercased()).address"
        let result = try record(domain: domain, key: key)
        return result
    }

    // MARK: - Get Record
    func record(domain: String, key: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        let result = try record(tokenId: tokenId, key: key)
        guard Utillities.isNotEmpty(result) else {
            throw ResolutionError.recordNotFound
        }
        return result
    }

    func record(tokenId: String, key: String) throws -> String {
        let result: OwnerResolverRecord
        do {
            result = try self.getOwnerResolverRecord(tokenId: tokenId, key: key)
        } catch {
            if error is ABICoderError {
                throw ResolutionError.unspecifiedResolver
            }
            throw error
        }
        guard Utillities.isNotEmpty(result.owner) else { throw ResolutionError.unregisteredDomain }
        guard Utillities.isNotEmpty(result.resolver) else { throw ResolutionError.unspecifiedResolver }

        return result.record
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain)
        guard let dict = try proxyReaderContract?.callMethod(methodName: "getMany", args: [keys, tokenId]) as? [String: [String]],
              let result = dict["0"]
        else {
            throw ResolutionError.recordNotFound
        }

        let returnValue = zip(keys, result).reduce(into: [String: String]()) { dict, pair in
            let (key, value) = pair
            dict[key] = value
        }
        return returnValue
    }

    // MARK: - Helper functions
    private func unfoldAddress<T> (_ incomingData: T) -> String? {
        if let eth = incomingData as? EthereumAddress {
            return eth.address
        }
        if let str = incomingData as? String {
            return str
        }
        return nil
    }

    private func unfoldAddressForMany<T> (_ incomingData: T) -> [String]? {
        if let ethArray = incomingData as? [EthereumAddress] {
            return ethArray.map { $0.address }
        }
        if let strArray = incomingData as? [String] {
            return strArray
        }
        return nil
    }

    private func unfoldForMany(contractResult: Any, key: String = "0") -> [String]? {
        if let dict = contractResult as? [String: Any],
           let element = dict[key] {
            return unfoldAddressForMany(element)
        }
        return nil
    }

    private func getOriginBlockFrom(network: String) -> String {
        switch network {
        case "mainnet":
            return "0x8A958B"
        case "rinkeby":
            return "0x7232BC"
        default:
            return "earliest"
        }
    }

    private func getOwnerResolverRecord(tokenId: String, key: String) throws -> OwnerResolverRecord {
        let res = try self.getDataForMany(keys: [key], for: [tokenId])
        if let dict = res as? [String: Any] {
            if let owners = unfoldAddressForMany(dict[Contract.ownersKey]),
               let resolvers = unfoldAddressForMany(dict[Contract.resolversKey]),
               let valuesArray = dict[Contract.valuesKey] as? [[String]] {
                guard Utillities.isNotEmpty(owners[0]) else {
                    throw ResolutionError.unregisteredDomain
                }

                guard Utillities.isNotEmpty(resolvers[0]),
                      valuesArray.count > 0,
                      valuesArray[0].count > 0 else {
                    throw ResolutionError.unspecifiedResolver
                }

                let record = valuesArray[0][0]
                return OwnerResolverRecord(owner: owners[0], resolver: resolvers[0], record: record)
            }
        }
        throw ResolutionError.unregisteredDomain
    }

    private func getDataForMany(keys: [String], for tokenIds: [String]) throws -> Any {
        if let result = try proxyReaderContract?
                                .callMethod(methodName: Self.getDataForManyMethodName,
                                            args: [keys, tokenIds]) { return result }
        throw ResolutionError.proxyReaderNonInitialized
    }
}

fileprivate extension String {
    var normalized32: String {
        let droppedHexPrefix = self.hasPrefix("0x") ? String(self.dropFirst("0x".count)) : self
        let cleanAddress = droppedHexPrefix.lowercased()
        if cleanAddress.count < 64 {
            let zeroCharacter: Character = "0"
            let arr = Array(repeating: zeroCharacter, count: 64 - cleanAddress.count)
            let zeros = String(arr)

            return "0x" + zeros + cleanAddress
        }
        return "0x" + cleanAddress
    }
}

fileprivate extension Data {
    init?(hex: String) {
        guard hex.count.isMultiple(of: 2) else {
            return nil
        }

        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hex.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }
}
