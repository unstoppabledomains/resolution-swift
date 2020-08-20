//
//  Resolution.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation

public class Resolution {
    
    private var providerUrl: String;
    private let services: [NamingService];
    
    init(providerUrl: String, network: String) throws {
        self.providerUrl = providerUrl;
        let cns = try CNS(network: network, providerUrl: providerUrl);
        self.services = [cns];
    }
    
    /// Resolves a hash  of the `domain` according to https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
    public func namehash(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).namehash(domain: preparedDomain)
    }
    
    /// Resolves an owner address of a `domain`
    public func owner(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).owner(domain: preparedDomain);
    }
    
    /// Resolves `ticker` cryptoaddress of a `domain`
    public func addr(domain: String, ticker: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: domain).addr(domain: preparedDomain, ticker: ticker);
    }
    
    /// Resolves a resolver address of a `domain`
    public func resolver(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).resolver(domain: preparedDomain);
    }
    
    /// Resolves an ipfs hash of a `domain`
    public func ipfsHash(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).getRecord(domain: preparedDomain, key: "ipfs.html.value");
    }
    
    /// Resolves an email of a `domain` owner
    public func email(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).getRecord(domain: preparedDomain, key: "whois.email.value");
    }
    
    /// Resolves a gunDB username of a `domain` owner
    public func gunDBchat(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).getRecord(domain: preparedDomain, key: "gundb.username.value");
    }
    
    /// Resolves a gunDB private key of a `domain` owner
    public func gunDBPk(domain: String) throws -> String {
        let preapredDomain = prepare(domain: domain);
        return try getServiceOf(domain: preapredDomain).getRecord(domain: preapredDomain, key: "gundb.public_key.value");
    }
    
    /// Resolves redirect url of a `domain`
    public func redirectUrl(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).getRecord(domain: preparedDomain, key: "ipfs.redirect_domain.value");
    }
    
    /// Resolves custom record of a `domain`
    public func getCustomRecord(domain: String, key: String) throws -> String {
        let preparedDomain = prepare(domain: domain);
        return try getServiceOf(domain: preparedDomain).getRecord(domain: preparedDomain, key: key);
    }
    
    // MARK: - Uttilities function
    /// This returns the correct naming service based on the `domain` asked for
    private func getServiceOf(domain: String) throws -> NamingService  {
        guard let service = services.first(where: {$0.isSupported(domain: domain)}) else {
            throw ResolutionError.UnsupportedDomain;
        }
        return service;
    }

    /// Preproccess the `domain`
    private func prepare(domain: String) -> String {
        return domain.lowercased()
    }
}
