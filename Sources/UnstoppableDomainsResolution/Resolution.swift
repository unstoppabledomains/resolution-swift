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
///
/// ```swift
/// let resolution = try Resolution(apiKey: "<api_key>");
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
/// for example lets configure crypto naming service to use goerli while left etherium naming service with default configurations:
/// ```swift
/// let resolution = try Resolution(configs: Configurations(
///         uns: UnsLocations = UnsLocations(
///             layer1: NamingServiceConfig(
///                 providerUrl: "https://mainnet.infura.io/v3/<infura_api_key>",
///                 network: "mainnet"),
///             layer2: NamingServiceConfig(
///                 providerUrl: "https://polygon-mainnet.infura.io/v3/<infura_api_key>",
///                 network: "polygon-mainnet"),
///             znsLayer: NamingServiceConfig(
///                 providerUrl: "https://api.zilliqa.com",
///                 network: "mainnet")
///         )
/// );
/// resolution.addr(domain: "homecakes.crypto", ticker: "eth") { (result) in
///     switch result {
///     case .success(let returnValue):
///           // 0xe7474D07fD2FA286e7e0aa23cd107F8379085037
///         let ethAddress = returnValue
///     case .failure(let error):
///         print("Expected eth Address, but got \(error)")
///     }
/// }
/// ```
public class Resolution {
    private var services: [NamingService] = []
    // swiftlint:disable:next force_try
    private var domainRegex = try! NSRegularExpression(pattern: "^[.a-z\\d-]+$")

    public init(configs: Configurations) throws {
        self.services = try constructNetworkServices(configs)
    }

    public init(apiKey: String) throws {
        self.services = try constructNetworkServices(Configurations(apiKey: apiKey))
    }

    public init(apiKey: String, znsLayer: NamingServiceConfig) throws {
        self.services = try constructNetworkServices(Configurations(apiKey: apiKey, znsLayer: znsLayer))
    }

    /// Checks if the domain name is valid according to naming service rules for valid domain names.
    ///
    /// - Parameter domain: domain name to be checked
    /// - Parameter completion: A callback that resolves `Result` with  a `Bool` value
    ///
    public func isSupported(domain: String, completion: @escaping BoolResultConsumer) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let preparedDomain = try self?.prepare(domain: domain),
                    self?.services.first(where: {$0.isSupported(domain: preparedDomain)}) != nil else {
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
    /// Corresponds to ERC721 token id in case of Ethereum based naming service like UNS.
    /// - Throws: ```ResolutionError.unsupportedDomain```  if domain extension is unknown
    ///
    public func namehash(domain: String) throws -> String {
        let preparedDomain = try prepare(domain: domain)
        return try getServiceOf(domain: preparedDomain).namehash(domain: preparedDomain)
    }

    /// Resolves an owner address of a `domain`
    /// - Parameter domain: - domain name
    /// - Parameter completion: A callback that resolves `Result`  with an `owner address` or `Error`
    public func owner(domain: String, completion: @escaping StringResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).owner(domain: preparedDomain) {
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
    public func batchOwners(domains: [String], completion: @escaping DictionaryOptionalResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let preparedDomains = try domains.map({ (try self?.prepare(domain: $0))! })
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
        do {
            let preparedDomain = try self.prepare(domain: domain)
            let result = try self.getServiceOf(domain: domain).addr(domain: preparedDomain, ticker: ticker)
            completion(.success(result))
        } catch {
            self.catchError(error, completion: completion)
        }
    }

    /// Resolves give `domain` name to a specific `currency address` if exists
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  network: - blockchain network the token is created on
    /// - Parameter  ticker: - currency ticker USDT, MATIC
    /// - Parameter  completion: A callback that resolves `Result`  with an `address` or `Error`
    public func addr(domain: String, network: String, token: String, completion: @escaping StringResultConsumer ) {
        do {
            let preparedDomain = try self.prepare(domain: domain)
            let result = try self.getServiceOf(domain: domain).addr(domain: preparedDomain,  network: network, token: token)
            completion(.success(result))
        } catch {
            self.catchError(error, completion: completion)
        }
    }

    /// Resolves a resolver address of a `domain`
    /// - Parameter  domain: - domain name to be resolved
    /// - Parameter  completion: A callback that resolves `Result`  with a `resolver address` for a specific domain or `Error`
    public func resolver(domain: String, completion: @escaping StringResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).resolver(domain: preparedDomain) {
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let preparedDomain = try self?.prepare(domain: domain),
                    let service = try self?.getServiceOf(domain: preparedDomain) else {
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "ipfs.html.value") {
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "whois.email.value") {
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: "gundb.username.value") {
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain)
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain)
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let preparedDomain = try self?.prepare(domain: domain),
                    let service = try self?.getServiceOf(domain: preparedDomain),
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).record(domain: preparedDomain, key: key) {
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
    /// - Parameter  completion: A callback that resolves `Result`  with a `map [key: value]` for a specific domain or `Error`
    public func records(domain: String, keys: [String], completion:@escaping DictionaryResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                    let result = try self?.getServiceOf(domain: preparedDomain).records(keys: keys, for: preparedDomain) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Resolves all the records from a domain
    /// - Parameter domain: - domain name to be resolved
    /// - Parameter completion: A callback that resolves `Result` with a `map [key: value]` for a specific domain or `Error`
    @available(*, deprecated, message: "allRecords method is deprecated")
    public func allRecords(domain: String, completion: @escaping DictionaryResultConsumer) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                if let preparedDomain = try self?.prepare(domain: domain),
                   let result = try self?.getServiceOf(domain: preparedDomain).allRecords(domain: preparedDomain) {
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

    public func locations(domains: [String], completion: @escaping DictionaryLocationResultConsumer) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let preparedDomains = try domains.map({ (try self?.prepare(domain: $0))! })
                if let result = try self?.getServiceOf(domains: preparedDomains).locations(domains: preparedDomains) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    /// Gets reverse resolution token id of `address`
    /// - Parameter address: - address for which to find reverse resolution
    /// - Parameter options: - if specified, will check for reverse resolution at that network. Otherwise both L1 and L2 will be checked.
    /// - Parameter completion: A callback that resolves `Result`  with a `tokenId` or `Error`
    public func reverseTokenId(address: String, location: UNSLocation? = nil, completion: @escaping StringResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let service = try self?.findService(name: .uns) as? UNS
                if let result = try service?.reverseTokenId(address: address, location: location) {
                    completion(.success(result))
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }
    
    /// Gets reverse resolution domain name of `address`
    /// - Parameter address: - address for which to find reverse resolution
    /// - Parameter options: - if specified, will check for reverse resolution at that network. Otherwise both L1 and L2 will be checked.
    /// - Parameter completion: A callback that resolves `Result`  with a `domainName` or `Error`
    public func reverse(address: String, location: UNSLocation? = nil, completion: @escaping StringResultConsumer ) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let service = try self?.findService(name: .uns) as? UNS
                if let result = try service?.reverseTokenId(address: address, location: location) {
                    self?.unhash(hash: result, serviceName: .uns, completion: completion)
                }
            } catch {
                self?.catchError(error, completion: completion)
            }
        }
    }

    // MARK: - Uttilities function

    /// this returns [NamingService] from the configurations
    private func constructNetworkServices(_ configs: Configurations) throws -> [NamingService] {
        var networkServices: [NamingService] = []
        var errorService: Error?
        do {
            networkServices.append(try UNS(configs))
        } catch {
            errorService = error
        }

        if let error = errorService {
            throw error
        }
        return networkServices
    }

    /// This returns the naming service
    private func getServiceOf(domain: String) throws -> NamingService {
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
            guard result!.name == currNS.name else { throw ResolutionError.inconsistentDomainArray }
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
    private func prepare(domain: String) throws -> String {
        let normalizedDomain = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if domainRegex.firstMatch(in: normalizedDomain, options: [], range: NSRange(location: 0, length: normalizedDomain.count)) != nil {
            return normalizedDomain
        }
        throw ResolutionError.invalidDomainName
    }

    private func catchError<T>(_ error: Error, completion: @escaping (Result<T, ResolutionError>) -> Void) {
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
