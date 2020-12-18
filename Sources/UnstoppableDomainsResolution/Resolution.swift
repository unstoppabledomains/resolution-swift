//
//  Resolution.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

/// A library for interacting with blockchain domain names.
///
/// Supported domain zones:
///
/// *CNS:*
///     .crypto
///
/// *ZNS*
///     .zil
///
/// *ENS*
///     .eth
///     .kred
///     .xyz
///     .luxe
///
/// ```swift
/// let resolution = try Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
///
/// resolution.addr(domain: "brad.crypto", ticker: "btc") { (result) in
///     switch result {
///     case .success(let returnValue):
///           // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
///         let btcAddress = returnValue
///     case .failure(let error):
///         print("Expected btc Address, but got \(error)")
///     }
/// }
/// ```
///
public class Resolution {

    private var providerUrl: String
    private let services: [NamingService]

    public init(providerUrl: String = "https://main-rpc.linkpool.io",
                network: String = "mainnet",
                networking: NetworkingLayer = DefaultNetworkingLayer() ) throws {
        self.providerUrl = providerUrl
        let cns = try CNS(network: network, providerUrl: providerUrl, networking: networking)
        let ens = try ENS(network: network, providerUrl: providerUrl, networking: networking)
        let zns = try ZNS(network: network, providerUrl: "https://api.zilliqa.com/", networking: networking)
        self.services = [cns, ens, zns]
    }

    /// Checks if the domain name is valid according to naming service rules for valid domain names.
    ///
    /// **Example:** ENS doesn't allow domains that start from '-' symbol.
    ///
    /// - Parameter domain: domain name to be checked
    ///
    /// - Returns: The return true or false.
    ///
    public func isSupported(domain: String) -> Bool {
        do {
            let preparedDomain = prepare(domain: domain)
            return try getServiceOf(domain: preparedDomain).isSupported(domain: preparedDomain)
        } catch {
            return false
        }
    }

    /// Resolves a hash  of the `domain` according to https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
    /// - Parameter domain: - domain name to be converted
    /// - Returns: Produces a namehash from supported naming service in hex format with 0x prefix.
    /// Corresponds to ERC721 token id in case of Ethereum based naming service like ENS or CNS.
    /// - Throws: ```ResolutionError.unsupportedDomain```  if domain extension is unknown
    ///
    public func namehash(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain)
        return try getServiceOf(domain: preparedDomain).namehash(domain: preparedDomain)
    }

    /// Resolves an owner address of a `domain`
    /// - Parameter domain: - domain name
    /// - Parameter completion: A callback that resolves `Result`  with an `owner address` or `Error`
    public func owner(domain: String, completion: @escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).owner(domain: preparedDomain) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves owner addresses of an array of `domain`s
    /// - Parameter domains: - array of domain names, with nil value if the domain is not registered or
    ///     its resolver is null
    /// - Parameter completion: A callback that resolves `Result`  with an array of `owner address`'s or `Error`
    public func batchOwners(domains: [String], completion: @escaping StringsArrayResultConsumer ) {
        let preparedDomains = domains.map { prepare(domain: $0) }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domains: preparedDomains).batchOwners(domains: preparedDomains) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves give `domain` name to a specific `currency address` if exists
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  ticker: - currency ticker like BTC, ETH, ZIL
    /// - Parameter  completion: A callback that resolves `Result`  with an `address` or `Error`
    public func addr(domain: String, ticker: String, completion: @escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: domain).addr(domain: preparedDomain, ticker: ticker) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves a resolver address of a `domain`
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with a `resolver address` for a specific domain or `Error`
    public func resolver(domain: String, completion: @escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).resolver(domain: preparedDomain) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves an ipfs hash of a `domain`
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with an `IPFS hash` for a specific domain or `Error`
    public func ipfsHash(domain: String, completion: @escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "ipfs.html.value") {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves an `email` field from whois configurations
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with an `email` for a specific domain or `Error`
    public func email(domain: String, completion:@escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "whois.email.value") {
                completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves a  `chat id` of a `domain` record
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with an `chat id` for a specific domain or `Error`
    public func chatId(domain: String, completion:@escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "gundb.username.value") {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves  a  `gundb public key` of a `domain` record
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with an `gundb public key` for a specific domain or `Error`
    public func chatPk(domain: String, completion:@escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain)
                    .record(domain: preparedDomain, key: "gundb.public_key.value") {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves redirect url of a `domain`
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with an `url` for a specific domain or `Error`
    public func httpUrl(domain: String, completion:@escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain)
                    .record(domain: preparedDomain, key: "ipfs.redirect_domain.value") {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }
    /// Resolves dns record of a `domain`
    /// - Parameter domain: - domain name to be resolved
    /// - Parameter type: - dns record type
    public func dns(domain: String, types: [DnsType], completion:@escaping DnsRecordsResultConsumer) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let service = try self?.getServiceOf(domain: preparedDomain),
                      service.name == "CNS" else {
                    throw ResolutionError.methodNotSupported
                }

                let cryptoRecords = DnsType.getCryptoRecords(types: types, ttl: true)
                let result = try service.records(keys: cryptoRecords, for: preparedDomain)

                let parsed = try DnsUtils.init().toList(map: result)
                completion(.success(parsed))

            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves custom record of a `domain`
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  key: - a name of a record to be resolved
    public func record(domain: String, key: String, completion:@escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: key) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Allows to get Many records from a `domain` in a single transaction
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  keys: -  is an array of keys
    /// - Parameter  completion: A callback that resolves `Result`  with an `map [key: value]` for a specific domain or `Error`
    public func records(domain: String, keys: [String], completion:@escaping DictionaryResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let result = try self?.getServiceOf(domain: preparedDomain).records(keys: keys, for: preparedDomain) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    // MARK: - Uttilities function
    /// This returns the correct naming service based on the `domain` asked for
    private func getServiceOf(domain: String) throws -> NamingService {
        guard let service = services.first(where: {$0.isSupported(domain: domain)}) else {
            throw ResolutionError.unsupportedDomain
        }
        return service
    }

    /// This returns the correct naming service based on the `domain`'s array asked for
    private func getServiceOf(domains: [String]) throws -> NamingService {
        guard domains.count > 0 else {
            throw ResolutionError.unsupportedDomain
        }

        let possibleServices = domains.compactMap { domain in
            return services.first(where: {$0.isSupported(domain: domain)})
        }
        guard possibleServices.count == domains.count else {
            throw ResolutionError.unsupportedDomain
        }

        let service: NamingService? = try possibleServices.reduce(nil, {result, currNS in
            guard result != nil else { return currNS }
            guard result!.name == currNS.name else { throw ResolutionError.inconsistenDomainArray }
            return currNS
        })
        return service!
    }

    /// Preproccess the `domain`
    private func prepare(domain: String) -> String {
        return domain.lowercased()
    }

    /// Process the 'error'
    private func catchError(_ error: Error, completion:@escaping DictionaryResultConsumer ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }
        completion(.failure(catched))
    }

    /// Process the 'error'
    private func catchError(_ error: Error, completion:@escaping StringResultConsumer ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }
        completion(.failure(catched))
    }

    /// Process the 'error'
    private func catchError(_ error: Error, completion:@escaping StringsArrayResultConsumer ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }
        completion(.failure(catched))
    }

    private func catchError(_ error: Error, completion:@escaping DnsRecordsResultConsumer) {
        guard let catched = error as? ResolutionError else {
            guard let catched = error as? DnsRecordsError else {
                completion(.failure(ResolutionError.unknownError(error)))
                return
            }
            completion(.failure(catched))
            return
        }
        completion(.failure(catched))
    }
}
