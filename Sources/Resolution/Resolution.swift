//
//  Resolution.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public class Resolution {

    private var providerUrl: String
    private let services: [NamingService]

    init(providerUrl: String, network: String) throws {
        self.providerUrl = providerUrl
        let cns = try CNS(network: network, providerUrl: providerUrl)
        let zns = try ZNS(network: network, providerUrl: "https://api.zilliqa.com/")
        self.services = [cns, zns]
    }

    /// Resolves a hash  of the `domain` according to https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
    public func namehash(domain: String) throws -> String {
        let preparedDomain = prepare(domain: domain)
        return try getServiceOf(domain: preparedDomain).namehash(domain: preparedDomain)
    }

    /// Resolves an owner address of a `domain`
    public func owner(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).owner(domain: preparedDomain)
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves `ticker` cryptoaddress of a `domain`
    public func addr(domain: String, ticker: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: domain).addr(domain: preparedDomain, ticker: ticker)
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves a resolver address of a `domain`
    public func resolver(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).resolver(domain: preparedDomain)
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves an ipfs hash of a `domain`
    public func ipfsHash(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "ipfs.html.value")
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves an email of a `domain` owner
    public func email(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "whois.email.value")
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves a  chat id of a `domain` owner
    public func chatId(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "gundb.username.value")
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves  a  gundb public key of a `domain`
    public func chatPk(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "gundb.public_key.value")
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves redirect url of a `domain`
    public func redirectUrl(domain: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "ipfs.redirect_domain.value")
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves custom record of a `domain`
    public func record(domain: String, key: String, completion:@escaping StringResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: key)
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
            }
        }
    }

    /// Allows to get Many records from a `domain` in a single transaction
    /// `keys` is an array of keys
    public func records(domain: String, keys: [String], completion:@escaping DictionaryResult ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async {
            do {
                let result = try self.getServiceOf(domain: preparedDomain).records(keys: keys, for: preparedDomain)
                completion(.success(result))
            } catch {
                self.catchError(error, completion: completion)
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

    /// Preproccess the `domain`
    private func prepare(domain: String) -> String {
        return domain.lowercased()
    }

    /// Process the 'error'
    private func catchError(_ error: Error, completion:@escaping DictionaryResult ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }

        completion(.failure(catched))
    }

    private func catchError(_ error: Error, completion:@escaping StringResult ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }

        completion(.failure(catched))
    }
}
