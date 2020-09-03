//
//  CNS.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

internal class CNS: CommonNamingService, NamingService {
    let network: String;
    let registryAddress: String;
    let RegistryMap: [String: String] = [
        "mainnet": "0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe",
        "kovan": "0x22c2738cdA28C5598b1a68Fb1C89567c2364936F"
    ]
    
    init(network: String, providerUrl: String) throws {
        guard let registryAddress = RegistryMap[network] else {
            throw ResolutionError.UnsupportedNetwork
        }
        self.network = network;
        self.registryAddress = registryAddress;
        super.init(name: "CNS", providerUrl: providerUrl)
    }
    
    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".crypto");
    }
    
    func owner(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain);
        guard let ownerAddress = try askRegistryContract(for: "ownerOf", with: [tokenId]),
            Utillities.isNotEmpty(ownerAddress) else {
                throw ResolutionError.UnregisteredDomain;
        }
        return ownerAddress;
    }
    
    func addr(domain: String, ticker: String) throws -> String {
        let tokenId = super.namehash(domain: domain);
        let key = "crypto.\(ticker.uppercased()).address";
        let result = try record(tokenId: tokenId, key: key);
        return result;
    }
    
    
    // MARK: - Get Record
    func record(domain: String, key: String) throws -> String {
        let tokenId = super.namehash(domain: domain);
        return try self.record(tokenId: tokenId, key: key);
    }
    
    func record(tokenId: String, key: String) throws -> String {
        let resolverAddress = try resolver(tokenId: tokenId);
        let resolverContract = try super.buildContract(address: resolverAddress, type: .Resolver);
        guard let result = try resolverContract.fetchMethod(methodName: "get", args: [key, tokenId]) as? String,
            Utillities.isNotEmpty(result) else {
                throw ResolutionError.RecordNotFound;
        }
        return result;
    }
    
    func records(keys: [String], for domain: String) throws -> [String: String] {
        let tokenId = super.namehash(domain: domain);
        let resolverAddress = try resolver(tokenId: tokenId);
        let resolverContract = try super.buildContract(address: resolverAddress, type: .Resolver);
        guard let result = try resolverContract.fetchMethod(methodName: "getMany", args: [keys, tokenId]) as? [String]
            else {
                throw ResolutionError.RecordNotFound;
        }
        
        let returnValue = zip(keys, result).reduce(into: [String: String]()) { dict, pair in
            let (key, value) = pair
            dict[key] = value
        }

        return returnValue
    }
    
    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain);
        return try self.resolver(tokenId: tokenId);
    }
    
    func resolver(tokenId: String) throws -> String {
        guard let resolverAddress = try askRegistryContract(for: "resolverOf", with: [tokenId]),
            Utillities.isNotEmpty(resolverAddress) else {
                throw ResolutionError.UnconfiguredDomain;
        }
        return resolverAddress;
    }
    
    // MARK: - Helper functions
    private func askRegistryContract(for methodName: String, with args: [String]) throws -> String? {
        let registryContract: Contract = try super.buildContract(address: self.registryAddress, type: .Registry);
        return try registryContract.fetchMethod(methodName: methodName, args: args) as? String;
    }
}
