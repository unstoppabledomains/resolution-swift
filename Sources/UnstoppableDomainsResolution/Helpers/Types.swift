//
//  Types.swift
//  Resolution
//
//  Created by Serg Merenkov on 9/8/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public typealias StringResultConsumer = (Result<String, ResolutionError>) -> Void
public typealias StringsArrayResultConsumer = (Result<[String?], ResolutionError>) -> Void
public typealias DictionaryResultConsumer = (Result<[String: String], ResolutionError>) -> Void
public typealias DictionaryOptionalResultConsumer = (Result<[String: String?], ResolutionError>) -> Void
public typealias DictionaryLocationResultConsumer = (Result<[String: Location], ResolutionError>) -> Void
public typealias DnsRecordsResultConsumer = (Result<[DnsRecord], Error>) -> Void
public typealias TokenUriMetadataResultConsumer = (Result<TokenUriMetadata, ResolutionError>) -> Void
public typealias BoolResultConsumer = (Result<Bool, Error>) -> Void

internal typealias AsyncConsumer<T> = (T?, Error?)

public enum NamingServiceName: String {
    case uns
    case zns
}

public enum UNSLocation: String {
    case layer1
    case layer2
    case znsLayer
}

public struct UNSContract {
    let name: String
    let contract: Contract
    let deploymentBlock: String
}

public struct Location: Equatable {
    var registryAddress: String?
    var resolverAddress: String?
    var networkId: String?
    var blockchain: String?
    var owner: String?
    var providerURL: String?
}

public let ethCoinIndex = 60
