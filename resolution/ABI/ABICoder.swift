//
//  ABICoder.swift
//  resolution
//
//  Created by Johnny Good on 8/17/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
import CryptoSwift

class ABICoder {
    let abi: ABI;
    let errorSignature: String;
    struct CodingOperations {
        var signatureBytes: String = "";
        var Dynamic:[String] = [];
        var Static:[String] = [];
    }
    
    enum ABICoderError: Error {
        case WrongABIInterfaceForMethod(method: String)
        case UnsupportedEncodingType(type: String)
        case CouldNotEncode(type: String, value: String)
        case CouldNotDecode(type: String, value: String)
    }
    
    init(_ abi: ABI) {
        self.abi = abi;
        self.errorSignature = "0x08c379a";
    }
    
    // MARK: - Decode Block
    public func decode(_ data: String, from method: String) throws -> String? {
        let element: ABIElement = try getElement(method: method);
        guard let output = element.outputs?[0] else {
            throw ABICoderError.CouldNotDecode(type: "Not Found", value: data);
        }
        
        switch output.type {
        case .address:
            guard !data.starts(with: errorSignature) else {
                return "0x0000000000000000000000000000000000000000"
            }
            return data.removeLeadingZeros()
        case .string:
            if let offset = data.getNumberFromAbi(inBytes: false) {
                let messageFullData = String(data.dropFirst(2 + offset));
                if let messageLength = messageFullData.getNumberFromAbi(inBytes: false) {
                    let messageData = String(messageFullData.dropFirst(64)).prefix(messageLength)
                    if let message = String(messageData).hexToString() {
                        return message;
                    }
                }
            }
            throw ABICoderError.CouldNotDecode(type: output.type.rawValue, value: data);
        default:
            throw ABICoderError.UnsupportedEncodingType(type: output.type.rawValue)
        }
    }
    
    
    // MARK: - Encode Block
    public func encode(method: String, args: [String]) throws -> String {
        let element: ABIElement = try getElement(method: method);
        let operations = try parseEncoding(element, args);
        var encoded = operations.signatureBytes;
        guard operations.Dynamic.isEmpty else {
            let offset = String(operations.Static.reduce(0, {$1.count}), radix: 16).leftPadding(toLength: 64, withPad: "0");
            encoded.append(offset);
            operations.Static.forEach({encoded.append($0)});
            operations.Dynamic.forEach({encoded.append($0)});
            return encoded;
        }
        operations.Static.forEach({encoded.append($0)})
        return encoded;
    }
    
    private func parseEncoding(_ element: ABIElement, _ args: [String]) throws -> CodingOperations {
        var operations = CodingOperations();
        operations.signatureBytes = getSignature(element);
        for (index, input) in element.inputs.enumerated() {
            let encodedArg = try encodeType(data: args[index], type: input.type)
            guard isDynamicType(type: input.type) else {
                operations.Static.append(encodedArg);
                continue ;
            }
            operations.Dynamic.append(encodedArg)
        }
        return operations;
    }
    
    private func isDynamicType(type: InternalTypeEnum) -> Bool {
        return type == InternalTypeEnum.string || type == InternalTypeEnum.typeString;
    }
    
    private func encodeType(data: String, type: InternalTypeEnum) throws -> String {
        switch type {
        case .address, .uint256:
            let returnee = data.prefix(2) == "0x" ? String(data.dropFirst(2)) : data;
            guard returnee.count == 64 else {
                throw ABICoderError.CouldNotEncode(type: type.rawValue, value: data)
            }
            return returnee;
        case .string:
            let utf8Encoded = data.toUtf8HexString();
            let size = String(utf8Encoded.count / 2, radix: 16).leftPadding(toLength: 64, withPad: "0");
            let utf8PaddedResult = utf8Encoded.padding(toLength: 64, withPad: "0", startingAt: 0);
            return "\(size)\(utf8PaddedResult)";
        default:
            throw ABICoderError.UnsupportedEncodingType(type: type.rawValue)
        }
    }
    
    // MARK: - General ABI functions
    private func getElement(method: String) throws -> ABIElement {
        guard let element = abi.first(where: {$0.name == method}) else {
            throw ABICoderError.WrongABIInterfaceForMethod(method: method);
        }
        return element;
    }
    
    private func getSignature(_ element: ABIElement) -> String {
        let inputs = element.inputs;
        var functionSignature = element.name! + "(";
        for input in inputs {
            functionSignature = "\(functionSignature)\(input.type.rawValue),"
        }
        functionSignature.removeLast();
        functionSignature.append(")");
        let encoded = functionSignature.sha3(.keccak256).prefix(8);
        return "0x" + String(encoded);
    }
}

// MARK: - String Utils
fileprivate extension String {
    /// Converts data to utf8 in hex format
    func toUtf8HexString() -> String {
        let messageData = self.data(using: .utf8)!
        return messageData.toHexString();
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
    
    /// Splits a string into groups of `every` n characters, grouping from left-to-right
    func splitByLength(_ every: Int) -> [String] {
        var result = [String]()
        
        for i in stride(from: 0, to: self.count, by: every) {
            let startIndex = self.index(self.startIndex, offsetBy: i)
            let endIndex = self.index(startIndex, offsetBy: every, limitedBy: self.endIndex) ?? self.endIndex
            result.append(String(self[startIndex..<endIndex]))
        }
        return result
    }
    
    /// This parses 64 characters from abi response to get a number. Usually it is a length in bytes
    /// option inBytes controls whether we want the character count from string or the actual value of a number
    func getNumberFromAbi(inBytes: Bool) -> Int? {
        let tempStr = self.prefix(2) == "0x" ? String(self.dropFirst(2)) : self;
        let endIndex = tempStr.index(tempStr.startIndex, offsetBy: 64, limitedBy: tempStr.endIndex) ?? tempStr.endIndex;
        if let dynamic = Int(String(tempStr[tempStr.startIndex..<endIndex]), radix: 16) {
            return inBytes ? dynamic : dynamic * 2;
        }
        return nil;
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
