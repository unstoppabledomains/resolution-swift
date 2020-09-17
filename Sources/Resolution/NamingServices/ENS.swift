//
//  CNS.swift
//  resolution
//
//  Created by Serg Merenkov on 9/14/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

internal class ENS: CommonNamingService, NamingService {
    let network: String
    let registryAddress: String
    let registryMap: [String: String] = [
        "mainnet": "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
        "ropsten": "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
        "rinkeby": "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
        "goerli": "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e"
    ]

    init(network: String, providerUrl: String) throws {
        guard let registryAddress = registryMap[network] else {
            throw ResolutionError.unsupportedNetwork
        }
        self.network = network
        self.registryAddress = registryAddress
        super.init(name: "ENS", providerUrl: providerUrl)
    }

    func isSupported(domain: String) -> Bool {
        //Add additional domains
        return domain.hasSuffix(".eth")
    }

    func owner(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        guard let ownerAddress = try askRegistryContract(for: "owner", with: [tokenId]),
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
        if key == "ipfs.html.value" {
            let hash = try self.getContentHash(tokenId: tokenId)
            return hash
        }

        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)

        let ensKeyName = self.fromUDNameToENS(record: key)

        guard let result = try resolverContract.callMethod(methodName: "text", args: [tokenId, ensKeyName]) as? String,
            Utillities.isNotEmpty(result) else {
                throw ResolutionError.recordNotFound
        }
        return result
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        throw OtherError.runtimeError("Method not implemented.")
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        guard let resolverAddress = try askRegistryContract(for: "resolver", with: [tokenId]),
            Utillities.isNotEmpty(resolverAddress) else {
                throw ResolutionError.unconfiguredDomain
        }
        return resolverAddress
    }

    // MARK: - Helper functions
    private func askRegistryContract(for methodName: String, with args: [String]) throws -> String? {
        let registryContract: Contract = try super.buildContract(address: self.registryAddress, type: .registry)
        return try registryContract.callMethod(methodName: methodName, args: args) as? String
    }

    private func fromUDNameToENS(record: String) -> String {
        let mapper: [String: String] = [
            "ipfs.redirect_domain.value": "url",
            "whois.email.value": "email",
            "gundb.username.value": "gundb_username",
            "gundb.public_key.value": "gundb_public_key"
        ]
        return mapper[record] ?? record
    }

    private func getContentHash(tokenId: String) throws -> String {

        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)

        guard let contentHashEncoded = try resolverContract.callMethod(methodName: "contenthash", args: [tokenId]) as? String else {
            throw OtherError.runtimeError("Content hash is NULL")
        }

        //      const codec = contentHash.getCodec(contentHashEncoded);
        //      if (codec !== 'ipfs-ns') return undefined;
        //      return contentHash.decode(contentHashEncoded);

        return contentHashEncoded
    }

}
