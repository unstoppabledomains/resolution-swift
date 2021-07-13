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
/// *uns:*
///     .crypto
///
/// *zns*
///     .zil
///
/// ```swift
/// let resolution = try Resolution();
/// resolution.addr(domain: "brad.crypto", ticker: "btc") { (result) in
///   switch result {
///   case .success(let returnValue):
///         // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
///       let btcAddress = returnValue
///   case .failure(let error):
///       print("Expected btc Address, but got \(error)")
///   }
/// }
/// ```
/// You can configure namingServices by providing NamingServiceConfig struct to the constructor for the interested service
/// If you ommit network we are making a "net_version" JSON RPC call to the provider to determine the chainID
/// for example lets configure crypto naming service to use rinkeby while left etherium naming service with default configurations:
/// ```swift
/// let resolution = try Resolution(
///   configs: Configurations(
///     uns: NamingServiceConfig(
///       providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
///       network: "rinkeby"
///    )
///   )
/// );
/// resolution.addr(domain: "udtestdev-creek.crypto", ticker: "eth") { (result) in
///     switch result {
///     case .success(let returnValue):
///           // 0x1C8b9B78e3085866521FE206fa4c1a67F49f153A
///         let ethAddress = returnValue
///     case .failure(let error):
///         print("Expected eth Address, but got \(error)")
///     }
/// }
/// ```
public class Resolution {
    private var services: [NamingService] = []

    public init(configs: Configurations = Configurations() ) throws {
        self.services = try constructNetworkServices(configs)
    }

    /// Returns a network that NamingService was configure with
    public func getNetwork(from serviceName: String) throws -> String {
        guard let service = services.first(where: {$0.name.rawValue == serviceName.lowercased() }) else {
            throw ResolutionError.unsupportedServiceName
        }
        return service.network
    }

    /// Checks if the domain name is valid according to naming service rules for valid domain names.
    ///
    /// - Parameter domain: domain name to be checked
    /// - Parameter completion: A callback that resolves `Result` with  a `Bool` value
    ///
    public func isSupported(domain: String, completion: @escaping BoolResultConsumer) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let _ = self?.services.first(where: {$0.isSupported(domain: preparedDomain)}) else {
                    throw ResolutionError.unsupportedDomain
                }
                completion(.success(true))
            } catch {
                completion(.success(false))
            }
        }
    }

    /// Resolves a hash  of the `domain` according to https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
    /// - Parameter domain: - domain name to be converted
    /// - Returns: Produces a namehash from supported naming service in hex format with 0x prefix.
    /// Corresponds to ERC721 token id.
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

    /// Returns domains owned by `address`
    /// - Parameter address: - address of a user you want to get domains of
    /// - Parameter service: - name of the service you want to check agains CNS or ZNS
    /// - Parameter completion: - A callback taht resolves `Result` with an `array of domain names` or `Error`
    public func tokensOwnedBy(address: String, service: String, completion: @escaping StringsArrayResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {

                guard let serviceName = NamingServiceName(rawValue: service),
                    let namingService = self?.services.first(where: { $0.name == serviceName }) else {
                    throw ResolutionError.unsupportedServiceName
                }
                let result = try namingService.tokensOwnedBy(address: address)
                completion(.success(result))
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

    /// Resolves a multiChainAddress of a `domain` for specific `chain`
    /// - Parameter domain: - domain name to be resolved
    /// - Parameter ticker: - currency ticker like USDT, FTM and others
    /// - Parameter chain: - chain version like ERC20, OMNI, TRON and others
    /// - Parameter completion: A callback that resolves `Result` with a `multiChain Address` for a specific ticker and chain
    public func multiChainAddress(domain: String, ticker: String, chain: String, completion: @escaping StringResultConsumer ) {
        let preparedDomain = prepare(domain: domain)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let service = try self?.getServiceOf(domain: preparedDomain) else {
                    throw ResolutionError.methodNotSupported
                }
                let recordKey = "crypto.\(ticker.uppercased()).version.\(chain.uppercased()).address"
                let result = try service.record(domain: preparedDomain, key: recordKey)
                completion(.success(result))
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
                      service.name == .uns else {
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

    /// Retrieves the tokenURI from the registry smart contract.
    /// - Parameter domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with a `tokenURI` for a specific domain or `Error`
    public func tokenURI(domain: String, completion:@escaping StringResultConsumer) {
        do {
            let namehash = try self.namehash(domain: domain)
            let result = try self.getServiceOf(domain: domain).getTokenUri(tokenId: namehash)
            completion(.success(result))
        } catch {
            self.catchError(error, completion: completion)
        }
    }

    /// Retrieves the data from the endpoint provided by tokenURI from the registry smart contract.
    /// - Parameter domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result` with a `TokenUriMetadata` for a specific domain or `Error`
    public func tokenURIMetadata(domain: String, completion:@escaping TokenUriMetadataResultConsumer) {
        do {
            let namehash = try self.namehash(domain: domain)
            let tokenURI = try self.getServiceOf(domain: domain).getTokenUri(tokenId: namehash)
            try self.fetchTokenUriMetadata(tokenURI: tokenURI, completion: completion)
        } catch {
            self.catchError(error, completion: completion)
        }
    }

    /// Retrieves the domain name from token metadata that is provided by tokenURI from the registry smart contract.
    /// The function will throw an error if the domain in the metadata does not match the hash (e.g. if the metadata is outdated).
    /// - Parameter hash: - domain hash to be resolved
    /// - Parameter serviceName: - name of the service to use to get metadata
    /// - Parameter completion: A callback that resolves `Result` with a `domainName` for a specific domain or `Error`
    public func unhash(hash: String, serviceName: NamingServiceName, completion:@escaping StringResultConsumer) {
        do {
            let domain = try self.findService(name: serviceName).getDomainName(tokenId: hash)
            
            let receivedHash = try self.namehash(domain: domain)
            if receivedHash != hash {
                completion(.failure(ResolutionError.badRequestOrResponse))
            }
            completion(.success(domain))
        } catch {
            self.catchError(error, completion: completion)
        }
    }

    // MARK: - Uttilities function

    /// this returns [NamingService] from the configurations
    private func constructNetworkServices(_ configs: Configurations) throws -> [NamingService] {
        var networkServices: [NamingService] = []
        var errorService: Error?
        do {
            networkServices.append(try UNS(configs.uns))
        } catch {
            errorService = error
        }

        do {
            networkServices.append(try ZNS(configs.zns))
        } catch {
            errorService = error
        }

        if let error = errorService {
            throw error
        }
        return networkServices
    }

    /// This returns the correct naming service based on the `domain` asked for
    private func getServiceOf(domain: String) throws -> NamingService {
        if domain.hasSuffix(".zil") {
            return try self.findService(name: .zns)
        }
        return try self.findService(name: .uns)
    }

    /// This returns the correct naming service based on the `domain`'s array asked for
    private func getServiceOf(domains: [String]) throws -> NamingService {
        guard domains.count > 0 else {
            throw ResolutionError.unsupportedDomain
        }

        let possibleServices = try domains.compactMap { domain in
            return try self.getServiceOf(domain: domain)
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

    /// This returns the correct naming service based on the service name asked for
    private func findService(name: NamingServiceName) throws -> NamingService {
        guard let service = services.first(where: {$0.name == name}) else {
            throw ResolutionError.unsupportedServiceName
        }
        return service
    }

    /// Gets the token metadata from metadata API
    private func fetchTokenUriMetadata(tokenURI: String, completion:@escaping TokenUriMetadataResultConsumer) throws {
        let networking = try findService(name: .uns).networking
        let url = URL(string: tokenURI)
        networking.makeHttpGetRequest(url: url!,
                                    completion: {result in
                                        switch result {
                                        case .success(let response):
                                            completion(.success(response))
                                        case .failure(let error):
                                            self.catchError(error, completion: completion)
                                        }
                                    })
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

    /// Process the 'error'
    private func catchError(_ error: Error, completion:@escaping TokenUriMetadataResultConsumer ) {
        guard let catched = error as? ResolutionError else {
            completion(.failure(.unknownError(error)))
            return
        }
        completion(.failure(catched))
    }
}
