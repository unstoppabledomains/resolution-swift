// StateMutability.swift

import Foundation

enum StateMutability: String, Codable {
    case nonpayable = "nonpayable"
    case pure = "pure"
    case view = "view"
}
