//
//  CNS.swift
//  resolution
//
//  Created by Serg Merenkov on 9/14/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
import EthereumAddress

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
        return domain ~= "^[^-]*[^-]*\\.(eth|luxe|xyz|kred|addr\\.reverse)$"
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
        guard ticker.uppercased() == "ETH" else {
            throw ResolutionError.recordNotSupported
        }

        let tokenId = super.namehash(domain: domain)
        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)

        guard let dict = try resolverContract.callMethod(methodName: "addr", args: [tokenId, EthCoinIndex]) as? [String: Data],
              let dataAddress = dict["0"],
              let address = EthereumAddress(dataAddress),
              Utillities.isNotEmpty(address.address) else {
                throw ResolutionError.recordNotFound
        }
        return address.address
    }

    // MARK: - Get Record
    func record(domain: String, key: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.record(tokenId: tokenId, key: key)
    }

    func record(tokenId: String, key: String) throws -> String {
        if key == "ipfs.html.value" {
            throw ResolutionError.recordNotSupported
        }

        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)

        let ensKeyName = self.fromUDNameToEns(record: key)

        guard let dict = try resolverContract.callMethod(methodName: "text", args: [tokenId, ensKeyName]) as? [String: String],
              let result = dict["0"],
            Utillities.isNotEmpty(result) else {
                throw ResolutionError.recordNotFound
        }
        return result
    }

    func records(keys: [String], for domain: String) throws -> [String: String] {
        //TODO: Add some batch request and collect all keys by few request
        throw ResolutionError.recordNotSupported
    }

    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }

    func resolver(tokenId: String) throws -> String {
        guard let resolverAddress = try askRegistryContract(for: "resolver", with: [tokenId]),
            Utillities.isNotEmpty(resolverAddress) else {
                throw ResolutionError.unspecifiedResolver
        }
        return resolverAddress
    }

    // MARK: - Helper functions
    private func askRegistryContract(for methodName: String, with args: [String]) throws -> String? {
        let registryContract: Contract = try super.buildContract(address: self.registryAddress, type: .registry)
        guard let ethereumAddress = try registryContract.callMethod(methodName: methodName, args: args) as? [String: EthereumAddress],
              let address = ethereumAddress["0"] else {
            return nil
        }
        return address.address
    }

    private func fromUDNameToEns(record: String) -> String {
        let mapper: [String: String] = [
            "ipfs.redirect_domain.value": "url",
            "whois.email.value": "email",
            "gundb.username.value": "gundb_username",
            "gundb.public_key.value": "gundb_public_key"
        ]
        return mapper[record] ?? record
    }
}
