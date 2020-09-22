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
        let proxyResult = try askProxyReaderContract(for: "ownerOf", with: [tokenId])
        guard let ownerAddress = self.unfold(contractResult: proxyResult),
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
        let proxyResult = try proxyReaderContract.callMethod(methodName: "get", args: [key, tokenId])

        guard let result = self.unfold(contractResult: proxyResult),
              Utillities.isNotEmpty(result) else {
            throw ResolutionError.recordNotFound
        }
        return result
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

    typealias GetDataResponse = [Any]
    func getData(keys: [String], for tokenId: String) throws -> [Any] {

        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)

        let result = try proxyReaderContract.callMethod(methodName: "getData", args: [keys, tokenId])

        return []

//        guard let result = try proxyReaderContract.callMethod(methodName: "getData", args: [keys, tokenId]) as? [Any],
//              let resolver = result[0] as? String,
//              let owner = result[1] as? String,
//              let values = result[3] as? [String],
//            Utillities.isNotEmpty(result) else {
//            throw ResolutionError.recordNotFound
//        }
//        return [resolver, owner, values] as [Any]
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        let proxyResult = try askProxyReaderContract(for: "resolverOf", with: [tokenId])
        guard let resolverAddress = self.unfold(contractResult: proxyResult),
            Utillities.isNotEmpty(resolverAddress) else {
                throw ResolutionError.unspecifiedResolver
        }
        return resolverAddress
    }

    // MARK: - Helper functions
    func unfold(contractResult: Any) -> String? {
        var result: String?

        if let dictAddress = contractResult as? [String: EthereumAddress],
           let address = dictAddress["0"] {
            result = address.address
        }

        if let dict = contractResult as? [String: String],
           let resultStr = dict["0"] {
            result = resultStr
        }

        if let resultStr = contractResult as? String {
            result = resultStr
        }

        return result
    }

    private func askProxyReaderContract(for methodName: String, with args: [String]) throws -> Any {
        let proxyReaderContract: Contract = try super.buildContract(address: self.proxyReaderAddress, type: .proxyReader)
        return try proxyReaderContract.callMethod(methodName: methodName, args: args)
    }
}
