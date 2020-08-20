// ABIElement.swift

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let abi = try jsonDecoder.decode(ABI.self, from: json);

import Foundation

typealias ABI = [ABIElement]

// MARK: - ABIElement
struct ABIElement: Codable {
    let constant: Bool?
    let inputs: [Put]
    let name: String?
    let outputs: [Put]?
    let payable: Bool?
    let stateMutability: StateMutability?
    let type: Type
    let anonymous: Bool?
}

// MARK: - Put
struct Put: Codable {
    let internalType: InternalTypeEnum
    let name: String
    let type: InternalTypeEnum
    let indexed: Bool?
}

// MARK: - StateMutability
enum StateMutability: String, Codable {
    case nonpayable = "nonpayable"
    case pure = "pure"
    case view = "view"
}

// MARK: - InternalTypeEnum
enum InternalTypeEnum: String, Codable {
    case address = "address"
    case bool = "bool"
    case bytes = "bytes"
    case bytes4 = "bytes4"
    case string = "string"
    case uint256 = "uint256"
    case contractMintingController = "contract MintingController"
    case contractRegistry = "contract Registry"
    case typeString = "string[]"
    case typeUint256 = "uint256[]"
}

// MARK: - Type
enum Type: String, Codable {
    case constructor = "constructor"
    case event = "event"
    case function = "function"
}
