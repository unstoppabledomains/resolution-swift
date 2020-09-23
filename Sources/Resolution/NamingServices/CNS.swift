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
        let res: Any
        do {
            res = try self.getData(keys: ["owner"], for: tokenId)
        } catch {
            throw ResolutionError.unregisteredDomain
        }
        guard let rec = self.unfold(contractResult: res, key: "owner") else {
            throw ResolutionError.unregisteredDomain
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
    
    private func unfoldAddress<T> (_ incomingData: T) -> String? {
        if let eth = incomingData as? EthereumAddress {
            return eth.address
        }
        
        if let str = incomingData as? String {
            return str
        }
        
        return nil
    }

    func getOwnerResolverRecord(tokenId: String, key: String) throws -> (owner: String, resolver: String, record: String) {
        let res = try self.getData(keys: [key], for: tokenId)
        if let dict = res as? [String: Any] {
            if let owner = unfoldAddress(dict["owner"]),
               let resolver = unfoldAddress(dict["resolver"]),
               let values = dict["values"] as? [String] {
                let record = values[0]
                return (owner: owner, resolver: resolver, record: record)
            }
        }
        throw ResolutionError.unregisteredDomain
    }
    
    func record(tokenId: String, key: String) throws -> String {
        var result: (owner: String, resolver: String, record: String) = ("", "", "")
        do {
            result = try self.getOwnerResolverRecord(tokenId: tokenId, key: key)
        }
        catch {
            throw ResolutionError.unspecifiedResolver
        }
        guard Utillities.isNotEmpty(result.owner) else { throw ResolutionError.unregisteredDomain }
        guard Utillities.isNotEmpty(result.resolver) else { throw ResolutionError.unspecifiedResolver }

        return result.record
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain)
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        guard let dict = try proxyReaderContract.callMethod(methodName: "getMany", args: [keys, tokenId]) as? [String: [String]],
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

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        let res: Any
        do {
            res = try self.getData(keys: ["resolver"], for: tokenId)
        } catch {
            throw ResolutionError.unspecifiedResolver
        }
        guard let rec = self.unfold(contractResult: res, key: "resolver") else {
            throw ResolutionError.unspecifiedResolver
        }
        return rec
    }

    // MARK: - Helper functions
    func unfold(contractResult: Any, key: String = "0") -> String? {

        if let dict = contractResult as? [String: Any], let el = dict[key] {
            if let addr = el as? EthereumAddress {
                return addr.address
            }
            
            if let string = el as? String {
                return string
            }
        }
        
        if let resultStr = contractResult as? String {
            return resultStr
        }
        return nil
    }
    
    private func getData(keys: [String], for tokenId: String) throws -> Any {
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        let result = try proxyReaderContract.callMethod(methodName: "getData", args: [keys, tokenId])
        return result
    }

    private func askProxyReaderContract(for methodName: String, with args: [String]) throws -> Any {
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        return try proxyReaderContract.callMethod(methodName: methodName, args: args)
    }
}
