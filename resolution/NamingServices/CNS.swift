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
        let result = try getRecord(tokenId: tokenId, key: key);
        return result;
    }
    
    
    // MARK: - Get Record
    func getRecord(domain: String, key: String) throws -> String {
        let tokenId = super.namehash(domain: domain);
        return try self.getRecord(tokenId: tokenId, key: key);
    }
    
    func getRecord(tokenId: String, key: String) throws -> String {
        let resolverAddress = try resolver(tokenId: tokenId);
        let resolverContract = super.buildContract(address: resolverAddress, type: .Resolver);
        guard let result = resolverContract.fetchMethod(methodName: "get", args: [key, tokenId]),
            Utillities.isNotEmpty(result) else {
                throw ResolutionError.RecordNotFound;
        }
        return result;
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
        let registryContract: Contract = super.buildContract(address: self.registryAddress, type: .Registry);
        return registryContract.fetchMethod(methodName: methodName, args: args);
    }
}
