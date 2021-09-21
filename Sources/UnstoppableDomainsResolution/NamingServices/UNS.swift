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
    let asyncResolver: AsyncResolver

    static let name: NamingServiceName = .uns

    init(_ config: UNSConfig) throws {
        self.asyncResolver = AsyncResolver()
        super.init(name: Self.name, providerUrl: config.layer1.providerUrl, networking: config.layer1.networking)
        let layer1Contracts = try parseContractAddresses(config: config.layer1)
        let layer2Contracts = try parseContractAddresses(config: config.layer2)

        self.layer1 = try UNSLayer(name: .unsl1, config: config.layer1, contracts: layer1Contracts)
        self.layer2 = try UNSLayer(name: .unsl2, config: config.layer2, contracts: layer2Contracts)

        guard self.layer1 != nil, self.layer2 != nil else {
            throw ResolutionError.proxyReaderNonInitialized
        }
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

    func isSupported(domain: String) -> Bool {
        return layer2.isSupported(domain: domain)
    }

    func owner(domain: String) throws -> String {
        return try asyncResolver.resolve(l1func: layer1.owner, l2func: layer2.owner, arg: domain)
    }

    func tokensOwnedBy(address: String) throws -> [String] {
        return try asyncResolver.resolve(l1func: layer1.tokensOwnedBy, l2func: layer2.tokensOwnedBy, arg: address)
    }

    func addr(domain: String, ticker: String) throws -> String {
        return try layer2.addr(domain: domain, ticker: ticker)
//        return try asyncResolver.resolve(l1func: layer1.addr, l2func: layer2.addr, arg1: domain, arg2: ticker)
    }

    func resolver(domain: String) throws -> String {
        return try asyncResolver.resolve(l1func: layer1.resolver, l2func: layer2.resolver, arg: domain)
    }

    func batchOwners(domains: [String]) throws -> [String?] {
        return try asyncResolver.resolve(l1func: layer1.batchOwners, l2func: layer2.batchOwners, arg: domains)
    }

    func record(domain: String, key: String) throws -> String {
        return try asyncResolver.resolve(l1func: layer1.record, l2func: layer2.record, arg1: domain, arg2: key)
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
//        return try layer1.records(keys: keys, for: domain)
        return try asyncResolver.resolve(l1func: layer1.records, l2func: layer2.records, arg1: keys, arg2: domain)
    }

    func getTokenUri(tokenId: String) throws -> String {
        return try asyncResolver.resolve(l1func: layer1.getTokenUri, l2func: layer2.getTokenUri, arg: tokenId)
    }

    func getDomainName(tokenId: String) throws -> String {
        return try asyncResolver.resolve(l1func: layer1.getDomainName, l2func: layer2.getDomainName, arg: tokenId)
    }
}

class AsyncResolver {

    typealias ResultConsumer<T> = (T?, Error?)
    typealias GenericFunction<T, U> = (_: T) throws -> (_: U)
    typealias GenericFunctionTwoArgs<T, U, Z> = (_: T, _: U) throws -> (_: Z)

    let asyncGroup = DispatchGroup()

    func resolve<T, U, Z>(l1func: @escaping GenericFunctionTwoArgs<T, U, Z>, l2func: @escaping GenericFunctionTwoArgs<T, U, Z>, arg1: T, arg2: U) throws -> Z {
        var results: [UNSLocation: ResultConsumer<Z>] = [:]
        let functions: [UNSLocation: GenericFunctionTwoArgs<T, U, Z>] = [.l2: l2func, .l1: l1func]

        functions.forEach { function in
            self.asyncGroup.enter()
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                do {
                    let value = try function.value(arg1, arg2)
                    results[function.key] = (value, nil)
                    self.asyncGroup.leave()
                } catch {
                    results[function.key] = (nil, error)
                    self.asyncGroup.leave()
                }
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        self.asyncGroup.notify(queue: .global()) {
            semaphore.signal()
        }
        semaphore.wait()
        return try parseResult(results)
    }

    func resolve<T, U>(l1func: @escaping GenericFunction<T, U>, l2func: @escaping GenericFunction<T, U>, arg: T) throws -> U {
        var results: [UNSLocation: ResultConsumer<U>] = [:]
        let functions: [UNSLocation: GenericFunction<T, U>] = [.l2: l2func, .l1: l1func]

        functions.forEach { function in
            self.asyncGroup.enter()
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                do {
                    let value = try function.value(arg)
                    results[function.key] = (value, nil)
                    self.asyncGroup.leave()
                } catch {
                    results[function.key] = (nil, error)
                    self.asyncGroup.leave()
                }
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        self.asyncGroup.notify(queue: .global()) {
            semaphore.signal()
        }
        semaphore.wait()
        return try parseResult(results)
    }

    private func parseResult<T>(_ results: [UNSLocation: ResultConsumer<T>] ) throws -> T {
        let l2Result = results[.l2]!
        let l1Result = results[.l1]!

        guard l2Result.1 == nil else {
            if !isUnregisteredDomain(error: l2Result.1) {
                throw l2Result.1!
            }

            guard l1Result.1 == nil else {
                throw l1Result.1!
            }
            return l1Result.0!
        }
        return l2Result.0!
    }

    private func isUnregisteredDomain(error: Error?) -> Bool {
        if let error = error as? ResolutionError {
            if case ResolutionError.unregisteredDomain = error {
                return true
            }
        }
        return false
    }
}
