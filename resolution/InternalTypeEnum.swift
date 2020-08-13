// InternalTypeEnum.swift

import Foundation

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
