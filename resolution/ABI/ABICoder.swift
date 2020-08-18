//
//  ABICoder.swift
//  resolution
//
//  Created by Johnny Good on 8/17/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import Foundation
import SwiftKeccak


class ABICoder {
    let abi: ABI;
    
    enum ABICoderError: Error {
        case WrongABIInterfaceForMethod(method: String)
        case UnsupportedEncodingType(type: String)
        case CouldNotEncode(type: String, value: String)
    }
    
    init(_ abi: ABI) {
        self.abi = abi;
    }
    
    public func encode(method: String, args: [String]) throws -> String {
        let element: ABIElement = try getElement(method: method, argsCount: args.count);
        let signature: String = getSignature(element);
        var encoded = "\(signature)";
        var argEncoding:[String: String];
        for (index, input) in element.inputs.enumerated() {
            let encodedArg = try encodeType(data: args[index], type: input.type)
            // Need to store it in some data structure taht separates static types and dynamics ones.
        }
        
        // Need to check if dynamic is exists
        // if so, I need to take the size of all statics part, append it after signature
        // append static encoded data after
        // append dynamic encoded data after
        // ???
        // PROFIT!!!
        
        return encoded;
    }
    
    public func decode(data: String) throws -> String {
        return "";
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
    
    private func getElement(method: String, argsCount: Int) throws -> ABIElement {
        guard let element = abi.first(where: {$0.name == method && $0.inputs.count == argsCount}) else {
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
        let encoded = keccak256(functionSignature).toHexString().prefix(8);
        return "0x" + String(encoded);
    }
}

// MARK: - String Utils
extension String {
    func toUtf8HexString() -> String {
        let messageData = self.data(using: .utf8)!
        return messageData.toHexString();
    }
    
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
}
