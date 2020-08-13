//
//  CNS.swift
//  resolution
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
import CryptoSwift

class CNS:NamingService {
    let name: String = "CNS";
    let network: String;
    let providerUrl: String;
    let registryAddress: String;
    
    let RegistryMap: [String: String] = [
        "mainnet": "0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe",
        "kovan": "0x22c2738cdA28C5598b1a68Fb1C89567c2364936F"
    ]
    
    enum ContractType {
        case Registry;
        case Resolver;
    }
    
    init(network: String, providerUrl: String) throws {
        guard let registryAddress = RegistryMap[network] else {
            throw ResolutionError.UnsupportedNetwork
        }
        self.network = network;
        self.providerUrl = providerUrl;
        self.registryAddress = registryAddress;
    }
    
    func namehash(domain: String) -> String {
        var node = Array<UInt8>.init(repeating: 0x0, count: 32)
        if domain.count > 0 {
            node = domain.split(separator: ".")
                .map { Array($0.utf8).sha3(.keccak256) }
                .reversed()
                .reduce(node) { return ($0 + $1).sha3(.keccak256) }
        }
            return "0x" + node.toHexString()
    }
    
    func isSupported(domain: String) -> Bool {
        return domain.hasSuffix(".crypto");
    }
    
    func owner(domain: String) throws -> String {
        // build registry contract
        print("START TO GETTING OWNER");
        let tokenId = namehash(domain: domain);
        print("GOT NAMEHASH \(tokenId)")
        let registryContract: Contract = buildContract(address: self.registryAddress, type: ContractType.Registry);
        
        // call registry contract method
        registryContract.fetchMethod(methodName: "ownerOf", args: [tokenId]);
        
        // return result or throw an error
        return "ownerAddress"
    }
    
    private func buildContract(address: String, type: ContractType) -> Contract {
        var jsonFileName: String;
        
        switch type {
        case .Registry:
            jsonFileName = "/NamingServices/CNS_ABI/cnsRegistry.json"
        case .Resolver:
            jsonFileName = "/NamingServices/CNS_ABI/cnsResolver.json"
        }
        
        let jsonData: Data = readLocalFile(forName: jsonFileName)!;
        let abi: ABI = parse(jsonData: jsonData, type: type)!;
        return Contract(providerUrl: self.providerUrl, address: address, ABI: abi);
        
    }
    
    private func readLocalFile(forName name: String) -> Data? {
        print("TRYING TO READ FILE \(name)")
        do {
            if let bundlePath = Bundle.main.path(forResource: name,
                                                 ofType: "json"),
            let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                return jsonData
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    private func parse(jsonData: Data, type: ContractType) -> ABI? {
        do {
            switch type {
            case .Registry:
                return try JSONDecoder().decode(Registry.self, from: jsonData)
            case .Resolver:
                return try JSONDecoder().decode(Resolver.self, from: jsonData)
            }
        } catch {
            print("decode error")
            return nil;
        }
    }
}
