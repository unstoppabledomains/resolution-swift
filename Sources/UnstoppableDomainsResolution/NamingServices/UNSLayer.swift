//
//  Layer1.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 9/8/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class UNSLayer: CommonNamingService {
    static let TransferEventSignature = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    static let NewURIEventSignature = "0xc5beef08f693b11c316c0c8394a377a0033c9cf701b8cd8afd79cecef60c3952"
    static let getDataForManyMethodName = "getDataForMany"
    static let tokenURIMethodName = "tokenURI"
    static let registryOfMethodName = "registryOf"
    static let existName = "exists"

    let network: String
    let blockchain: String?
    let layer: UNSLocation
    var nsRegistries: [UNSContract]
    var proxyReaderContract: Contract?

    init(name: UNSLocation, config: NamingServiceConfig, contracts: [UNSContract]) throws {
        self.network = config.network.isEmpty
            ? try Self.getNetworkName(providerUrl: config.providerUrl, networking: config.networking)
            : config.network
        self.blockchain = Self.networkToBlockchain[self.network]
        self.nsRegistries = []
        self.layer = name
        super.init(name: .uns, providerUrl: config.providerUrl, networking: config.networking)
        contracts.forEach {
            if $0.name == "ProxyReader" {
                proxyReaderContract = $0.contract
            } else {
                nsRegistries.append($0)
            }
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
        return try self.resolverFromTokenId(tokenId: tokenId)
    }

    private func resolverFromTokenId(tokenId: String) throws -> String {
        let res: Any
        do {
            res = try self.getDataForMany(keys: [Contract.resolversKey, Contract.ownersKey], for: [tokenId])
            guard let owners = self.unfoldForMany(contractResult: res, key: Contract.ownersKey),
                  Utillities.isNotEmpty(owners[0]) else {
                throw ResolutionError.unregisteredDomain
            }
        } catch {
            if error is ABICoderError {
                throw ResolutionError.unspecifiedResolver(self.layer.rawValue)
            }
            throw error
        }
        guard let rec = self.unfoldForMany(contractResult: res, key: Contract.resolversKey),
              rec.count > 0  else {
            throw ResolutionError.unspecifiedResolver(self.layer.rawValue)
        }
        guard Utillities.isNotEmpty(rec[0]) else {
            throw ResolutionError.unspecifiedResolver(self.layer.rawValue)
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
        let result = try recordFromTokenId(tokenId: tokenId, key: key)
        guard Utillities.isNotEmpty(result) else {
            throw ResolutionError.recordNotFound(self.layer.rawValue)
        }
        return result
    }

    func allRecords(domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain)
        let tokenUriMetadata = try getTokenUriMetadata(tokenId: tokenId)
        let metadataRecords = tokenUriMetadata.properties.records
        let commonRecordsKeys = try Self.parseRecordKeys()
        let mergedRecords = Array(Set(metadataRecords.keys + commonRecordsKeys!))
        return try self.records(keys: mergedRecords, for: domain).filter { !$0.value.isEmpty }
    }

    private func recordFromTokenId(tokenId: String, key: String) throws -> String {
        let result: OwnerResolverRecord
        do {
            result = try self.getOwnerResolverRecord(tokenId: tokenId, key: key)
        } catch {
            if error is ABICoderError {
                throw ResolutionError.unspecifiedResolver(self.layer.rawValue)
            }
            throw error
        }
        guard Utillities.isNotEmpty(result.owner) else { throw ResolutionError.unregisteredDomain }
        guard Utillities.isNotEmpty(result.resolver) else { throw ResolutionError.unspecifiedResolver(self.layer.rawValue) }

        return result.record
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain)

        guard let dict  = try self.getDataForMany(keys: keys, for: [tokenId]) as? [String: Any],
        let owners = self.unfoldForMany(contractResult: dict, key: Contract.ownersKey),
              Utillities.isNotEmpty(owners[0]) else {
            throw ResolutionError.unregisteredDomain
        }
        if let valuesArray = dict[Contract.valuesKey] as? [[String]],
           valuesArray.count > 0,
           valuesArray[0].count > 0 {
            let result = valuesArray[0]
            let returnValue = zip(keys, result).reduce(into: [String: String]()) { dict, pair in
                let (key, value) = pair
                dict[key] = value
            }
            return returnValue
        }
        // The line below will never get executed.
        fatalError("Failed unwrapping the results")
    }

    func locations(domains: [String]) throws -> [String: Location] {
        let tokenIds = domains.map { self.namehash(domain: $0) }
        var calls = tokenIds.map { return MultiCallData(methodName: Self.registryOfMethodName, args: [$0]) }
        calls.append(MultiCallData(methodName: Self.getDataForManyMethodName, args: [[], tokenIds]))
        let multiCallBytes = try proxyReaderContract?.multiCall(calls: calls)
        return try parseMultiCallForLocations(multiCallBytes!, from: calls, for: domains)
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
        } catch ResolutionError.executionReverted {
            throw ResolutionError.unregisteredDomain
        }
    }

    func getDomainName(tokenId: String) throws -> String {
        let metadata = try self.getTokenUriMetadata(tokenId: tokenId)
        guard metadata.name != nil else {
            throw ResolutionError.unregisteredDomain
        }
        return metadata.name!
    }

    // MARK: - Helper functions
    private func getTokenUriMetadata(tokenId: String) throws -> TokenUriMetadata {
        let tokenURI = try self.getTokenUri(tokenId: tokenId)
        guard !tokenURI.isEmpty else {
            throw ResolutionError.unregisteredDomain
        }

        let url = URL(string: tokenURI)
        let semaphore = DispatchSemaphore(value: 0)

        var tokenUriMetadataResult: Result<TokenUriMetadata, ResolutionError>!
        self.networking.makeHttpGetRequest(url: url!,
                                           completion: {
                                            tokenUriMetadataResult = $0
                                            semaphore.signal()
                                           })
        semaphore.wait()

        switch tokenUriMetadataResult {
        case .success(let tokenUriMetadata):
            return tokenUriMetadata
        case .failure(let error):
            throw error
        case .none:
            throw ResolutionError.badRequestOrResponse
        }
    }

    private func parseMultiCallForLocations(
        _ multiCallBytes: [Data],
        from calls: [MultiCallData],
        for domains: [String]
    ) throws -> [String: Location] {

        var registries: [String] = []
        var owners: [String] = []
        var resolvers: [String] = []

        for (data, call) in zip(multiCallBytes, calls) {
            switch call.methodName {
            case Self.registryOfMethodName:
                let hexMessage = "0x" + data.toHexString()
                if let result = try proxyReaderContract?.coder.decode(hexMessage, from: Self.registryOfMethodName),
                   let dict = result as? [String: Any],
                   let val = dict["0"] as? EthereumAddress {
                        registries.append(val._address)
                    }
            case Self.getDataForManyMethodName:
                let hexMessage = "0x" + data.toHexString()
                if let dict = try proxyReaderContract?.coder.decode(hexMessage, from: Self.getDataForManyMethodName),
                   let domainOwners = self.unfoldForMany(contractResult: dict, key: Contract.ownersKey),
                   let domainResolvers = self.unfoldForMany(contractResult: dict, key: Contract.resolversKey) {
                        owners += domainOwners
                        resolvers += domainResolvers
                    }
            default:
                throw ResolutionError.methodNotSupported
            }
        }

        return buildLocations(domains: domains, owners: owners, resolvers: resolvers, registries: registries)
    }

    private func buildLocations(domains: [String], owners: [String], resolvers: [String], registries: [String]) -> [String: Location] {
        var locations: [String: Location] = [:]
        for (domain, (owner, (resolver, registry))) in zip(domains, zip(owners, zip(resolvers, registries))) {
            if Utillities.isNotEmpty(owner) {
                locations[domain] = Location(
                    registryAddress: registry,
                    resolverAddress: resolver,
                    networkId: CommonNamingService.networkIds[self.network]!,
                    blockchain: self.blockchain,
                    owner: owner,
                    providerURL: self.providerUrl
                )
            } else {
                locations[domain] = Location()
            }
        }
        return locations
    }

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
                    throw ResolutionError.unspecifiedResolver(self.layer.rawValue)
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
                    if !Utillities.isNotEmpty(val.address) {
                        throw ResolutionError.unregisteredDomain
                    }
                    return val.address
                }
                throw ResolutionError.unregisteredDomain
            }
            throw ResolutionError.proxyReaderNonInitialized
        } catch ResolutionError.executionReverted {
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
