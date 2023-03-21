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
    let zlayer: NamingServiceConfig
    
    public init(
        layer1: NamingServiceConfig,
        layer2: NamingServiceConfig,
        zlayer: NamingServiceConfig
    ) {
        self.layer1 = layer1
        self.layer2 = layer2
        self.zlayer = zlayer
    }
}

let UD_RPC_PROXY_BASE_URL = "https://api.unstoppabledomains.com/resolve"
let DEFAULT_ETH_RPC_URL = "https://mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817"
let DEFAULT_MATIC_RPC_URL = "https://polygon-mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817"

public struct Configurations {
    let uns: UnsLocations
    let apiKey: String? = nil
    
    public init(
        uns: UnsLocations = UnsLocations(
            layer1: NamingServiceConfig(
                providerUrl: "https://mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                network: "mainnet"),
            layer2: NamingServiceConfig(
                providerUrl: "https://polygon-mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                network: "polygon-mainnet"),
            zlayer: NamingServiceConfig(
                providerUrl: "https://api.zilliqa.com",
                network: "mainnet")
        )
    ) {
        self.uns = uns
    }

    public init(apiKey: String) {
        var layer1NamingService = NamingServiceConfig(
                providerUrl: "\(UD_RPC_PROXY_BASE_URL)/chains/eth/rpc",
                network: "mainnet")

        layer1NamingService.networking.addHeader(header: "Authorization", value: "Bearer \(apiKey)")

        var layer2NamingService = NamingServiceConfig(
            providerUrl: "\(UD_RPC_PROXY_BASE_URL)/chains/matic/rpc",
            network: "polygon-mainnet")

        layer2NamingService.networking.addHeader(header: "Authorization", value: "Bearer \(apiKey)")

        self.uns = UnsLocations(
            layer1: layer1NamingService,
            layer2: layer2NamingService,
            zlayer:  NamingServiceConfig(
                providerUrl: "https://api.zilliqa.com",
                network: "mainnet")
        )
    }
}
