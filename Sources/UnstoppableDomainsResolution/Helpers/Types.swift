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
public typealias DnsRecordsResultConsumer = (Result<[DnsRecord], Error>) -> Void
public typealias TokenUriMetadataResultConsumer = (Result<TokenUriMetadata, ResolutionError>) -> Void
public typealias BoolResultConsumer = (Result<Bool, Error>) -> Void

public enum NamingServiceName: String {
    case uns
    case unsl1
    case unsl2
    case ens
    case zns
}

public enum UNSLocation: String {
    case l1
    case l2
}

public struct UNSContract {
    let name: String
    let contract: Contract
    let deploymentBlock: String
}
public let ethCoinIndex = 60
