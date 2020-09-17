//
//  ABICoder.swift
//  resolution
//
//  Created by Johnny Good on 8/17/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation
import CryptoSwift

// swiftlint:disable identifier_name cyclomatic_complexity
internal class ABICoder {
    let abi: ABI
    let errorSignature: String

    struct CodingOperations {
        var signatureBytes: String = ""
        var Dynamic: [String] = []
        var Static: [String] = []
    }

    enum ABICoderError: Error {
        case WrongABIInterfaceForMethod(method: String)
        case UnsupportedEncodingType(type: String)
        case UnsupportedDecodingType(type: String)
        case CouldNotEncode(type: String, value: String)
        case CouldNotDecode(type: String, value: String)
    }

    init(_ abi: ABI) {
        self.abi = abi
        self.errorSignature = "0x08c379a"
    }

    // MARK: - Decode Block
    public func decode(_ data: String, from method: String) throws -> Any {
        let element: ABIElement = try getElement(method)
        guard let output = element.outputs?[0] else {
            throw ABICoderError.CouldNotDecode(type: "Not Found", value: data)
        }

        switch output.type {
        case .address:
            guard !data.starts(with: errorSignature) else {
                return "0x0000000000000000000000000000000000000000"
            }
            return data.removeLeadingZeros()
        case .string, .bytes:
            if let offset = data.getNumberFromAbi(inBytes: false) {
                let messageFullData = String(data.dropFirst(2 + offset))
                if let messageLength = messageFullData.getNumberFromAbi(inBytes: false) {
                    let messageData = String(messageFullData.dropFirst(64)).prefix(messageLength)
                    if let message = String(messageData).hexToString() {
                        return message
                    }
                }
            }
            throw ABICoderError.CouldNotDecode(type: output.type.rawValue, value: data)
        case .stringArray:
            let data = String(data.dropFirst(2))
            if let dynamicOffset = data.getNumberFromAbi(inBytes: false) {
                let encodedArray = String(data.dropFirst(dynamicOffset))
                if let arraySize = encodedArray.getNumberFromAbi(inBytes: true) {
                    let arrayData = String(encodedArray.dropFirst(64))
                    let parsedArrayData = parseDynamicArray(arr: arrayData, size: arraySize)
                    var resultedArray: [String] = []
                    parsedArrayData.forEach({ resultedArray.append($0.hexToString(prefix: false)!)})
                    return resultedArray
                }
            }
            throw ABICoderError.CouldNotDecode(type: output.type.rawValue, value: data)
        default:
            throw ABICoderError.UnsupportedDecodingType(type: output.type.rawValue)
        }
    }

    private func parseDynamicArray(arr: String, size: Int) -> [String] {
        var parsedArray: [String] = []
        for i in 0..<size {
            let temp = String(arr.dropFirst(i * 64))
            let offset = temp.getNumberFromAbi(inBytes: false)!
            let data = String(arr.dropFirst(offset))
            let dataSize = data.getNumberFromAbi(inBytes: false)!
            let actualData = String(data.dropFirst(64).prefix(dataSize))
            parsedArray.append(actualData)
        }
        return parsedArray
    }

    // MARK: - Encode Block
    public func encode(method: String, args: [Any]) throws -> String {
        let element: ABIElement = try getElement(method)
        let operations = try parseEncoding(element, args)
        var encoded = operations.signatureBytes
        guard operations.Dynamic.isEmpty else {
            var offset = String(operations.Static.reduce(0, {$1.count}), radix: 16).leftPadding(toLength: 64, withPad: "0")
            // if there is no static headers then standart offset is 32 bytes
            if offset == "0000000000000000000000000000000000000000000000000000000000000000" {
                offset = "0000000000000000000000000000000000000000000000000000000000000020"
            }
            encoded.append(offset)
            operations.Static.forEach({encoded.append($0)})
            operations.Dynamic.forEach({encoded.append($0)})
            return encoded
        }
        operations.Static.forEach({encoded.append($0)})
        return encoded
    }

    private func parseEncoding(_ element: ABIElement, _ args: [Any]) throws -> CodingOperations {
        var operations = CodingOperations()
        operations.signatureBytes = getSignature(element)
        for (index, input) in element.inputs.enumerated() {
            var encodedArg = ""
            let rawArg = args[index]
            switch rawArg {
            case is String, is [String]:
                encodedArg = try encodeType(data: rawArg, type: input.type)
            default:
                throw ABICoderError.UnsupportedEncodingType(type: input.type.rawValue)
            }
            guard isDynamicType(type: input.type) else {
                operations.Static.append(encodedArg)
                continue
            }
            operations.Dynamic.append(encodedArg)
        }
        return operations
    }

    private func isDynamicType(type: InternalTypeEnum) -> Bool {
        return type == InternalTypeEnum.string || type == InternalTypeEnum.stringArray
    }

// swiftlint:disable force_cast
    private func encodeType(data: Any, type: InternalTypeEnum) throws -> String {
        switch type {
        case .address, .uint256, .bytes32:
            let data = data as! String
            let returnee = data.prefix(2) == "0x" ? String(data.dropFirst(2)) : data
            return returnee.leftPadding(toLength: 64, withPad: "0")
        case .string, .bytes:
            let data = data as! String
            let utf8Encoded = data.toUtf8HexString()
            let size = String(utf8Encoded.count / 2, radix: 16).leftPadding(toLength: 64, withPad: "0")
            let utf8PaddedResult = utf8Encoded.padding(toLength: 64, withPad: "0", startingAt: 0)
            return "\(size)\(utf8PaddedResult)"
        case .stringArray:
            let data = data as! [String]
            let size = String(data.count, radix: 16).leftPadding(toLength: 64, withPad: "0")
            var encodedArgs: [String] = []
            try data.forEach({try encodedArgs.append(self.encodeType(data: $0, type: .string)) })
            var encoded = size
            for i in 0..<data.count {
                let staticOffset = data.count * 32; // in bytes. each offset takes 32 bytes!
                let howManyArgsToCalculate = data.count - (data.count - i)
                var dynamicOffset = 0
                for j in 0..<howManyArgsToCalculate {
                    dynamicOffset += encodedArgs[j].count / 2
                }
                encoded.append(String(staticOffset + dynamicOffset, radix: 16).leftPadding(toLength: 64, withPad: "0"))
            }
            encodedArgs.forEach({encoded.append($0)})
            return encoded
        default:
            throw ABICoderError.UnsupportedEncodingType(type: type.rawValue)
        }
    }
// swiftlint:enable force_cast

    // MARK: - General ABI functions
    private func getElement(_ method: String) throws -> ABIElement {
        guard let element = abi.first(where: {$0.name == method}) else {
            throw ABICoderError.WrongABIInterfaceForMethod(method: method)
        }
        return element
    }

    public func getSignature(_ element: ABIElement) -> String {
        let inputs = element.inputs
        var functionSignature = element.name! + "("
        for input in inputs {
            functionSignature = "\(functionSignature)\(input.type.rawValue),"
        }
        functionSignature.removeLast()
        functionSignature.append(")")
        let encoded = functionSignature.sha3(.keccak256).prefix(8)
        return "0x" + String(encoded)
    }
}

// MARK: - String Utils
fileprivate extension String {
    /// Converts data to utf8 in hex format
    func toUtf8HexString() -> String {
        let messageData = self.data(using: .utf8)!
        return messageData.toHexString()
    }

    /// Pads a beging of a string with a `character` up to `toLength`
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }

    /// remove leading zeros from hexString
    func removeLeadingZeros() -> String {
        return "0x" + self.dropFirst(2).replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }

    /// This parses 64 characters from abi response to get a number. Usually it is a length in bytes
    /// option inBytes controls whether we want the character count from string or the actual value of a number
    func getNumberFromAbi(inBytes: Bool) -> Int? {
        let tempStr = self.prefix(2) == "0x" ? String(self.dropFirst(2)) : self
        let endIndex = tempStr.index(tempStr.startIndex, offsetBy: 64, limitedBy: tempStr.endIndex) ?? tempStr.endIndex
        if let dynamic = Int(String(tempStr[tempStr.startIndex..<endIndex]), radix: 16) {
            return inBytes ? dynamic : dynamic * 2
        }
        return nil
    }

    /// converts utf-8 encoded hex string to ascii characters
    func hexToString(prefix: Bool = false) -> String? {
        guard self.count % 2 == 0 else {
            return nil
        }

        var bytes = [CChar]()

        var startIndex = self.index(self.startIndex, offsetBy: prefix ? 2 : 0)
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: 2)
            let substr = String(self[startIndex..<endIndex])

            if let byte = Int8(substr, radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }

            startIndex = endIndex
        }

        bytes.append(0)
        return String(cString: bytes)
    }
}
