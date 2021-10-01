//
//  uns.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class UNS: CommonNamingService, NamingService {

    struct NSRegistry {
        let contract: Contract
        let deploymentBlock: String
    }

    static let name: NamingServiceName = .uns
    static let TransferEventSignature = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    static let NewURIEventSignature = "0xc5beef08f693b11c316c0c8394a377a0033c9cf701b8cd8afd79cecef60c3952"
    static let getDataForManyMethodName = "getDataForMany"
    static let tokenURIMethodName = "tokenURI"
    static let registryOfMethodName = "registryOf"
    static let existName = "exists"

    let network: String
    var nsRegistries: [NSRegistry]
    var proxyReaderContract: Contract?

    init(_ config: NamingServiceConfig) throws {

        self.network = config.network.isEmpty
            ? try Self.getNetworkId(providerUrl: config.providerUrl, networking: config.networking)
            : config.network
        self.nsRegistries = []

        super.init(name: Self.name, providerUrl: config.providerUrl, networking: config.networking)

        if let contractsContainer = try Self.parseContractAddresses(network: network) {

            if let unsRegistry = contractsContainer[ContractType.unsRegistry.name]?.address {
                let unsContract = try super.buildContract(address: unsRegistry, type: .unsRegistry)
                let deploymentBlock = contractsContainer[ContractType.unsRegistry.name]?.deploymentBlock ?? "earliest"
                self.nsRegistries.append(NSRegistry(contract: unsContract, deploymentBlock: deploymentBlock))
            }

            if let cnsRegistry = contractsContainer[ContractType.cnsRegistry.name]?.address {
                let cnsContract = try super.buildContract(address: cnsRegistry, type: .cnsRegistry)
                let deploymentBlock = contractsContainer[ContractType.cnsRegistry.name]?.deploymentBlock ?? "earliest"
                self.nsRegistries.append(NSRegistry(contract: cnsContract, deploymentBlock: deploymentBlock))
            }

            if let proxyReader = contractsContainer[ContractType.proxyReader.name]?.address {
                proxyReaderContract = try super.buildContract(address: proxyReader, type: .proxyReader)
            }

        }

        if config.proxyReader != nil {
            proxyReaderContract = try super.buildContract(address: config.proxyReader!, type: .proxyReader)
        }

        if config.registryAddresses != nil && !config.registryAddresses!.isEmpty {
            self.nsRegistries = try config.registryAddresses!.compactMap {
                let contract = try super.buildContract(address: $0, type: .unsRegistry)
                return NSRegistry(contract: contract, deploymentBlock: "earliest")
            }
        }

        guard proxyReaderContract != nil else {
            throw ResolutionError.proxyReaderNonInitialized
        }
    }

    func isSupported(domain: String) -> Bool {
        if domain ~= "^[^-]*[^-]*\\.(eth|luxe|xyz|kred|addr\\.reverse)$" {
            return false
        }
        let split = domain.split(separator: ".")
        let tld = split.suffix(1).joined(separator: "")
        if tld == "zil" {
            return false
        }
        let tokenId = self.namehash(domain: tld)
        if let response = try? self.proxyReaderContract?.callMethod(methodName: Self.existName, args: [tokenId]) {
            guard
                 let result = response as? [String: Bool],
                 let isExist = result["0"] else {
                   return false
               }
            return isExist
        }
        return false
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

    func getTokenUri(tokenId: String) throws -> String {
        do {
            if let result = try proxyReaderContract?
                                    .callMethod(methodName: Self.tokenURIMethodName,
                                                args: [tokenId]) {
                let dict = result as? [String: Any]
                if let val = dict?["0"] as? String {
                    return val
                }
                throw ResolutionError.unregisteredDomain
            }
            throw ResolutionError.proxyReaderNonInitialized
        } catch APIError.decodingError {
            throw ResolutionError.unregisteredDomain
        }
    }

    func getDomainName(tokenId: String) throws -> String {
        do {
            let registryAddress = try self.getRegistryAddress(tokenId: tokenId)
            let registryContract = try self.buildContract(address: registryAddress, type: .unsRegistry)
            let result = try registryContract.callLogs(
                fromBlock: "earliest",
                signatureHash: Self.NewURIEventSignature,
                for: tokenId,
                isTransfer: false)

            guard result.count > 0 else {
                throw ResolutionError.unregisteredDomain
            }

            if let domainName = ABIDecoder.decodeSingleType(type: .string, data: Data(hex: result[0].data)).value as? String {
                return domainName
            }
            throw ResolutionError.unregisteredDomain
        } catch APIError.decodingError {
            throw ResolutionError.unregisteredDomain
        }
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

    private func getRegistryAddress(tokenId: String) throws -> String {
        do {
            if let result = try proxyReaderContract?
                                    .callMethod(methodName: Self.registryOfMethodName,
                                                args: [tokenId]) {
                let dict = result as? [String: Any]
                if let val = dict?["0"] as? EthereumAddress {
                    return val.address
                }
                throw ResolutionError.unregisteredDomain
            }
            throw ResolutionError.proxyReaderNonInitialized
        } catch APIError.decodingError {
            throw ResolutionError.unregisteredDomain
        }
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
