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
    
    init(_ config: NamingServiceConfig) throws {
        self.network = config.network.isEmpty
        ? try Self.getNetworkName(providerUrl: config.providerUrl, networking: config.networking)
        : config.network
        
        var registryAddress: String? = registryMap[self.network]
        if config.registryAddresses != nil && !config.registryAddresses!.isEmpty {
            registryAddress = config.registryAddresses![0]
        }
        
        guard registryAddress != nil else {
            throw ResolutionError.registryAddressIsNotProvided
        }
        self.registryAddress = registryAddress!
        super.init(name: .ens, providerUrl: config.providerUrl, networking: config.networking)
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
    
    func batchOwners(domains: [String]) throws -> [String: String?] {
        throw ResolutionError.methodNotSupported
    }
    
    func addr(domain: String, ticker: String) throws -> String {
        guard ticker.uppercased() == "ETH" else {
            throw ResolutionError.recordNotSupported
        }
        let tokenId = super.namehash(domain: domain)
        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)

        guard let dict = try resolverContract.callMethod(methodName: "addr", args: [tokenId, ethCoinIndex]) as? [String: Data],
              let dataAddress = dict["0"],
              let address = EthereumAddress(dataAddress),
              Utillities.isNotEmpty(address.address) else {
            throw ResolutionError.recordNotFound(self.name.rawValue)
        }
        return address.address
    }
    
    func addr(domain: String, network: String, token: String) throws -> String {
        return "NA"
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
        
        let ensKeyName = self.fromUDNameToEns(record: key)
        
        guard let dict = try resolverContract.callMethod(methodName: "text", args: [tokenId, ensKeyName]) as? [String: String],
              let result = dict["0"],
              Utillities.isNotEmpty(result) else {
            throw ResolutionError.recordNotFound(self.name.rawValue)
        }
        return result
    }
    
    func records(keys: [String], for domain: String) throws -> [String: String] {
        throw ResolutionError.methodNotSupported
    }
    
    func allRecords(domain: String) throws -> [String: String] {
        throw ResolutionError.methodNotSupported
    }
    
    func getTokenUri(tokenId: String) throws -> String {
        throw ResolutionError.methodNotSupported
    }
    
    func getDomainName(tokenId: String) throws -> String {
        throw ResolutionError.methodNotSupported
    }
    
    func locations(domains: [String]) throws -> [String: Location] {
        throw ResolutionError.methodNotSupported
    }
    
    // MARK: - get Resolver
    func resolver(domain: String) throws -> String {
        let tokenId = super.namehash(domain: domain)
        return try self.resolver(tokenId: tokenId)
    }
    
    func resolver(tokenId: String) throws -> String {
        guard let resolverAddress = try askRegistryContract(for: "resolver", with: [tokenId]),
              Utillities.isNotEmpty(resolverAddress) else {
            throw ResolutionError.unspecifiedResolver(self.name.rawValue)
        }
        return resolverAddress
    }
    
    // MARK: - Helper functions
    private func askRegistryContract(for methodName: String, with args: [String]) throws -> String? {
        let registryContract: Contract = try super.buildContract(address: self.registryAddress, type: .ensRegistry)
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
    
    /*
     //https://ethereum.stackexchange.com/questions/17094/how-to-store-ipfs-hash-using-bytes32
     getIpfsHashFromBytes32(bytes32Hex) {
     // Add our default ipfs values for first 2 bytes:
     // function:0x12=sha2, size:0x20=256 bits
     // and cut off leading "0x"
     const hashHex = "1220" + bytes32Hex.slice(2)
     const hashBytes = Buffer.from(hashHex, 'hex');
     const hashStr = bs58.encode(hashBytes)
     return hashStr
     }
     */
    private func getContentHash(tokenId: String) throws -> String {
        let resolverAddress = try resolver(tokenId: tokenId)
        let resolverContract = try super.buildContract(address: resolverAddress, type: .resolver)
        
        let hash = try resolverContract.callMethod(methodName: "contenthash", args: [tokenId]) as? [String: Any]
        guard let data = hash?["0"] as? Data else {
            throw ResolutionError.recordNotFound(self.name.rawValue)
        }
        
        let contentHash = [UInt8](data)
        guard let codec = Array(contentHash[0..<1]).last,
              codec == 0xE3 // 'ipfs-ns'
        else {
            throw ResolutionError.recordNotFound(self.name.rawValue)
        }
        
        return Base58.base58Encode(Array(contentHash[4..<contentHash.count]))
    }
}
