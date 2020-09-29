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
    static let SPECIFIC_DOMAIN = ".crypto"
    static let name = "CNS"
    static let proxyReaderAddress = "0x7ea9Ee21077F84339eDa9C80048ec6db678642B1"
    let registryMap: [String: String] = [
        "mainnet": "0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe",
        "kovan": "0x22c2738cdA28C5598b1a68Fb1C89567c2364936F"
    ]

    let network: String
    let registryAddress: String
    var proxyReaderContract: Contract?

    init(network: String, providerUrl: String, networking: NetworkingLayer) throws {
        guard let registryAddress = registryMap[network] else {
            throw ResolutionError.unsupportedNetwork
        }
        self.network = network
        self.registryAddress = registryAddress
        super.init(name: Self.name, providerUrl: providerUrl, networking: networking)
        proxyReaderContract = try super.buildContract(address: Self.proxyReaderAddress, type: .proxyReader)
    }

    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(Self.SPECIFIC_DOMAIN)
    }

    // MARK: - geters of Owner and Resolver
    func owner(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        let res: Any
        do {
            res = try self.getData(keys: [Contract.OWNER_KEY], for: tokenId)
        } catch {
            throw ResolutionError.unregisteredDomain
        }
        guard let rec = self.unfold(contractResult: res, key: Contract.OWNER_KEY) else {
            throw ResolutionError.unregisteredDomain
        }
        return rec
    }

    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        let res: Any
        do {
            res = try self.getData(keys: [Contract.RESOLVER_KEY], for: tokenId)
        } catch {
            throw ResolutionError.unspecifiedResolver
        }
        guard let rec = self.unfold(contractResult: res, key: Contract.RESOLVER_KEY) else {
            throw ResolutionError.unspecifiedResolver
        }
        return rec
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
        var result: (owner: String, resolver: String, record: String) = ("", "", "")
        do {
            result = try self.getOwnerResolverRecord(tokenId: tokenId, key: key)
        } catch {
            throw ResolutionError.unspecifiedResolver
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

    private func unfold(contractResult: Any, key: String = "0") -> String? {
        if let dict = contractResult as? [String: Any],
           let el = dict[key] {
            return unfoldAddress(el)
        }
        return nil
    }

    private func getOwnerResolverRecord(tokenId: String, key: String) throws -> (owner: String, resolver: String, record: String) {
        let res = try self.getData(keys: [key], for: tokenId)
        if let dict = res as? [String: Any] {
            if let owner = unfoldAddress(dict[Contract.OWNER_KEY]),
               let resolver = unfoldAddress(dict[Contract.RESOLVER_KEY]),
               let values = dict[Contract.VALUES_KEY] as? [String] {
                let record = values[0]
                return (owner: owner, resolver: resolver, record: record)
            }
        }
        throw ResolutionError.unregisteredDomain
    }

    private func getData(keys: [String], for tokenId: String) throws -> Any {
        if let result = try proxyReaderContract?.callMethod(methodName: "getData", args: [keys, tokenId]) {
            return result }
        throw ResolutionError.proxyReaderNonInitialized
    }

    private func askProxyReaderContract(for methodName: String, with args: [String]) throws -> Any {
        return try proxyReaderContract!.callMethod(methodName: methodName, args: args)
    }
}
