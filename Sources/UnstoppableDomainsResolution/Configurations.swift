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
    let networking: NetworkingLayer
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

public struct Configurations {
    let uns: NamingServiceConfig
    let zns: NamingServiceConfig

    public init(
        uns: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817",
            network: "mainnet"),
        zns: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://api.zilliqa.com",
            network: "mainnet")
    ) {
        self.uns = uns
        self.zns = zns
    }
}
