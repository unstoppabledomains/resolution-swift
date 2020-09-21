//
//  CNS.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class CNS: CommonNamingService, NamingService {
    let network: String
    let registryAddress: String
    let registryMap: [String: String] = [
        "mainnet": "0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe",
        "kovan": "0x22c2738cdA28C5598b1a68Fb1C89567c2364936F"
    ]
    
    let proxyReaderAddress = "0x7ea9Ee21077F84339eDa9C80048ec6db678642B1"

    init(network: String, providerUrl: String) throws {
        guard let registryAddress = registryMap[network] else {
            throw ResolutionError.unsupportedNetwork
        }
        self.network = network
        self.registryAddress = registryAddress
        super.init(name: "CNS", providerUrl: providerUrl)
    }

    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".crypto")
    }

    func owner(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        guard let ownerAddress = try askProxyReaderContract(for: "ownerOf", with: [tokenId]),
            Utillities.isNotEmpty(ownerAddress) else {
                throw ResolutionError.unregisteredDomain
        }
        return ownerAddress
    }

    func addr(domain: String, ticker: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        let key = "crypto.\(ticker.uppercased()).address"
        let result = try record(tokenId: tokenId, key: key)
        return result
    }

    // MARK: - Get Record
    func record(domain: String, key: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.record(tokenId: tokenId, key: key)
    }

    func record(tokenId: String, key: String) throws -> String {
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        guard let result = try proxyReaderContract.fetchMethod(methodName: "get", args: [key, tokenId]) as? String,
            Utillities.isNotEmpty(result) else {
                throw ResolutionError.recordNotFound
        }
        return result
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain)
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        guard let result = try proxyReaderContract.fetchMethod(methodName: "getMany", args: [keys, tokenId]) as? [String]
            else {
                throw ResolutionError.recordNotFound
        }

        let returnValue = zip(keys, result).reduce(into: [String: String]()) { dict, pair in
            let (key, value) = pair
            dict[key] = value
        }

        return returnValue
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        guard let resolverAddress = try askProxyReaderContract(for: "resolverOf", with: [tokenId]),
            Utillities.isNotEmpty(resolverAddress) else {
                throw ResolutionError.unconfiguredDomain
        }
        return resolverAddress
    }

    // MARK: - Helper functions
    private func askProxyReaderContract(for methodName: String, with args: [String]) throws -> String? {
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        return try proxyReaderContract.fetchMethod(methodName: methodName, args: args) as? String
    }
}
