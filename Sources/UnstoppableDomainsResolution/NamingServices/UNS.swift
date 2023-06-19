//
//  uns.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class UNS: CommonNamingService, NamingService {
    var layer1: UNSLayer!
    var layer2: UNSLayer!
    var znsLayer: ZNS!
    let asyncResolver: AsyncResolver

    static let name: NamingServiceName = .uns
    
    typealias GeneralFunction<T> = () throws -> T

    init(_ config: Configurations) throws {
        self.asyncResolver = AsyncResolver()
        super.init(
            name: Self.name,
            providerUrl: config.uns.layer1.providerUrl,
            networking: config.uns.layer1.networking
        )
        let layer1Contracts = try parseContractAddresses(config: config.uns.layer1)
        let layer2Contracts = try parseContractAddresses(config: config.uns.layer2)

        self.layer1 = try UNSLayer(name: .layer1, config: config.uns.layer1, contracts: layer1Contracts)
        self.layer2 = try UNSLayer(name: .layer2, config: config.uns.layer2, contracts: layer2Contracts)
        self.znsLayer = try ZNS(config.uns.znsLayer)
        
        guard self.layer1 != nil, self.layer2 != nil, self.znsLayer != nil else {
            throw ResolutionError.proxyReaderNonInitialized
        }
    }

    func isSupported(domain: String) -> Bool {
        return layer2.isSupported(domain: domain)
    }
        
    func owner(domain: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.owner(domain: domain)},
                         {try self.layer2.owner(domain: domain)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.owner(domain: domain)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func record(domain: String, key: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.record(domain: domain, key: key)},
                         {try self.layer2.record(domain: domain, key: key)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.record(domain: domain, key: key)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.records(keys: keys, for: domain)},
                         {try self.layer2.records(keys: keys, for: domain)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.records(keys: keys, for: domain)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func allRecords(domain: String) throws -> [String: String] {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.allRecords(domain: domain)},
                         {try self.layer2.allRecords(domain: domain)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.allRecords(domain: domain)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func getTokenUri(tokenId: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.getTokenUri(tokenId: tokenId)},
                         {try self.layer2.getTokenUri(tokenId: tokenId)}]
        )
    }

    func getDomainName(tokenId: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.getDomainName(tokenId: tokenId)},
                         {try self.layer2.getDomainName(tokenId: tokenId)}]
        )
    }

    func addr(domain: String, ticker: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.addr(domain: domain, ticker: ticker)},
                         {try self.layer2.addr(domain: domain, ticker: ticker)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.addr(domain: domain, ticker: ticker)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func addr(domain: String, network: String, token: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.addr(domain: domain, network: network, token: token)},
                         {try self.layer2.addr(domain: domain, network: network, token: token)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.addr(domain: domain, network: network, token: token)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func resolver(domain: String) throws -> String {
        return try asyncResolver.safeResolve(
            listOfFunc: [{try self.layer1.resolver(domain: domain)},
                         {try self.layer2.resolver(domain: domain)},
                         {
                             if self.znsLayer.isSupported(domain: domain) {
                                 return try self.znsLayer.resolver(domain: domain)
                             }
                             throw ResolutionError.unregisteredDomain
                         }]
        )
    }

    func locations(domains: [String]) throws -> [String: Location] {
        let results = try asyncResolver.resolve(
            listOfFunc: [{try self.layer1.locations(domains: domains)},
                         {try self.layer2.locations(domains: domains)}]
        )
        
        try self.throwIfLayerHasError(results)

        var locations: [String: Location] = [:]
        let l2Response = Utillities.getLayerResult(from: results, for: .layer2)
        let l1Response = Utillities.getLayerResult(from: results, for: .layer1)

        domains.forEach {
            let l2Loc = l2Response[$0]!
            let l1Loc = l1Response[$0]!

            locations[$0] = l2Loc.owner == nil ? l1Loc : l2Loc
        }

        return locations
    }

    func batchOwners(domains: [String]) throws -> [String: String?] {
        let results = try asyncResolver.resolve(
            listOfFunc: [{try self.layer1.batchOwners(domains: domains)},
                         {try self.layer2.batchOwners(domains: domains)},
                        ]
        )
        
        var owners: [String: String?] = [:]
        try self.throwIfLayerHasError(results)
        
        let l2Result = Utillities.getLayerResult(from: results, for: .layer2)
        let l1Result = Utillities.getLayerResult(from: results, for: .layer1)
        
        for (domain, (l2owner, l1owner)) in zip(domains, zip(l2Result, l1Result)) {
            owners[domain] = l2owner == nil ? l1owner : l2owner
        }
        
        return owners
    }
    
    func reverseTokenId(address: String, location: UNSLocation?) throws -> String {
        let results = try asyncResolver.resolve(
            listOfFunc: [{try self.layer1.reverseTokenId(address: address)},
                         {try self.layer2.reverseTokenId(address: address)},
                        ]
        )
        
        if location != nil {
            let result = Utillities.getLayerResultWrapper(from: results, for: location!)
            if let err = result.1 {
                throw err
            }
            return result.0!
        }
        
        let l1Result = Utillities.getLayerResultWrapper(from: results, for: .layer1)

        if let l1error = l1Result.1 {
            if !Utillities.isResolutionError(expected: .reverseResolutionNotSpecified, error: l1error) {
                throw l1error
            }
        } else if let l1Value = l1Result.0 {
            return l1Value
        }
        
        let l2Result = Utillities.getLayerResultWrapper(from: results, for: .layer2)
        
        if let l2error = l2Result.1 {
            throw l2error
        }
        return l2Result.0!
    }

    private func parseContractAddresses(config: NamingServiceConfig) throws -> [UNSContract] {
        var contracts: [UNSContract] = []
        var proxyReaderContract: UNSContract?
        var unsContract: UNSContract?
        var cnsContract: UNSContract?

        let network = config.network.isEmpty
            ? try Self.getNetworkId(providerUrl: config.providerUrl, networking: config.networking)
            : config.network

        if let contractsContainer = try Self.parseContractAddresses(network: network) {
            unsContract = try getUNSContract(contracts: contractsContainer, type: .unsRegistry, providerUrl: config.providerUrl)
            cnsContract = try getUNSContract(contracts: contractsContainer, type: .cnsRegistry, providerUrl: config.providerUrl)
            proxyReaderContract = try getUNSContract(contracts: contractsContainer, type: .proxyReader, providerUrl: config.providerUrl)
        }

        if config.proxyReader != nil {
            let contract = try super.buildContract(address: config.proxyReader!, type: .proxyReader, providerUrl: config.providerUrl)
            proxyReaderContract = UNSContract(name: "ProxyReader", contract: contract, deploymentBlock: "earliest")
        }

        guard proxyReaderContract != nil else {
            throw ResolutionError.proxyReaderNonInitialized
        }
        contracts.append(proxyReaderContract!)
        if config.registryAddresses != nil && !config.registryAddresses!.isEmpty {
            try config.registryAddresses!.forEach {
                let contract = try super.buildContract(address: $0, type: .unsRegistry, providerUrl: config.providerUrl)
                contracts.append(UNSContract(name: "Registry", contract: contract, deploymentBlock: "earliest"))
            }
        }

        // if no registryAddresses has been provided to the config use the default ones
        if contracts.count == 1 {
            guard unsContract != nil else {
                throw ResolutionError.contractNotInitialized("UNSContract")
            }
            guard cnsContract != nil else {
                throw ResolutionError.contractNotInitialized("CNSContract")
            }
            contracts.append(unsContract!)
            contracts.append(cnsContract!)
        }

        return contracts
    }

    private func getUNSContract(contracts: [String: CommonNamingService.ContractAddressEntry], type: ContractType, providerUrl: String ) throws -> UNSContract? {
        if let address = contracts[type.name]?.address {
            let contract = try super.buildContract(address: address, type: type, providerUrl: providerUrl)
            let deploymentBlock = contracts[type.name]?.deploymentBlock ?? "earliest"
            return UNSContract(name: type.name, contract: contract, deploymentBlock: deploymentBlock)
        }
        return nil
    }

    // This is used only when all layers should not throw any errors. Methods like batchOwners or locations require both layers.
    private func throwIfLayerHasError<T>(_ results: [UNSLocation: AsyncConsumer<T>]) throws {
        let l2Results = Utillities.getLayerResultWrapper(from: results, for: .layer2)
        let l1Results = Utillities.getLayerResultWrapper(from: results, for: .layer1)
        let zResults = Utillities.getLayerResultWrapper(from: results, for: .znsLayer)

        guard l2Results.1 == nil else {
            throw l2Results.1!
        }

        guard l1Results.1 == nil else {
            throw l1Results.1!
        }
        
        guard zResults.1 == nil else {
            throw zResults.1!
        }

    }
}

fileprivate extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
