//
//  Configuration.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 2/16/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct NamingServiceConfig {
    let network: String
    let providerUrl: String
    var networking: NetworkingLayer
    let proxyReader: String?
    let registryAddresses: [String]?
    
    public init(
        providerUrl: String,
        network: String = "",
        networking: NetworkingLayer = DefaultNetworkingLayer(),
        proxyReader: String? = nil,
        registryAddresses: [String]? = nil
    ) {
        self.network = network
        self.providerUrl = providerUrl
        self.networking = networking
        self.proxyReader = proxyReader
        self.registryAddresses = registryAddresses
    }
}

public struct UnsLocations {
    let layer1: NamingServiceConfig
    let layer2: NamingServiceConfig
    let znsLayer: NamingServiceConfig
    
    public init(
        layer1: NamingServiceConfig,
        layer2: NamingServiceConfig,
        znsLayer: NamingServiceConfig
    ) {
        self.layer1 = layer1
        self.layer2 = layer2
        self.znsLayer = znsLayer
    }
}

let UD_RPC_PROXY_BASE_URL = "https://api.unstoppabledomains.com/resolve"

public struct Configurations {
    let uns: UnsLocations
    let ens: NamingServiceConfig
    let apiKey: String? = nil
    
    public init(
        uns: UnsLocations,
        ens: NamingServiceConfig
    ) {
        self.uns = uns
        self.ens = ens
    }
    
    public init(
        apiKey: String,
        znsLayer: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://api.zilliqa.com",
            network: "mainnet"),
        ens: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://mainnet.infura.io/v3/<api_key>",
            network: "mainnet")
    ) {
        var networking = DefaultNetworkingLayer();
        networking.addHeader(header: "Authorization", value: "Bearer \(apiKey)")
        networking.addHeader(header: "X-Lib-Agent", value: Configurations.getLibVersion())
        
        let layer1NamingService = NamingServiceConfig(
            providerUrl: "\(UD_RPC_PROXY_BASE_URL)/chains/eth/rpc",
            network: "mainnet",
            networking: networking)
        
        let layer2NamingService = NamingServiceConfig(
            providerUrl: "\(UD_RPC_PROXY_BASE_URL)/chains/matic/rpc",
            network: "polygon-mainnet",
            networking: networking)
        
        self.uns = UnsLocations(
            layer1: layer1NamingService,
            layer2: layer2NamingService,
            znsLayer: znsLayer
        )
        
        self.ens = ens
    }
    
    static public func getLibVersion() -> String {
        return "UnstoppableDomains/resolution-swift/6.1.0"
    }
}
