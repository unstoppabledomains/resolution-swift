//
//  Utilities.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

typealias ZilliqaAddress = String

internal class Utillities {
    static func isNotEmpty(_ value: String) -> Bool {
        let nullValues = [
        "0x",
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000"
        ]
        return !(value.isEmpty || nullValues.contains(value))
    }

    static func isNotEmpty(_ array: [Any]) -> Bool {
        return array.count > 0
    }
}

extension String {
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }

    func addHexPrefix() -> String {
        if !self.hasPrefix("0x") {
            return "0x" + self
        }
        return self
    }

    func removeHexPrefix() -> String {
        if self.hasPrefix("0x") {
            return self.replacingOccurrences(of: "0x", with: "")
        }
        return self
    }
}

//extension Address
extension ZilliqaAddress {

    /// `toBech32Address` Encodes a canonical 20-byte Ethereum-style address as a bech32 zilliqa address.
    ///
    ///     The expected format is zil1<address><checksum> where address and checksum
    ///     are the result of bech32 encoding a Buffer containing the address bytes.
    ///
    /// - Parameter address: 20 byte canonical address
    /// - Returns: 38 char bech32 encoded zilliqa address
    func toBech32Address(address: String, testnet: Bool = false) -> String {
//      if (!isAddress(address)) {
//        throw new Error('Invalid address format.');
//      }

        let addrBz = convertBits(data: Array(address.removeHexPrefix().utf8),
                            fromWidth: 8,
                              toWidth: 5)

//      if (addrBz === null) {
//        throw new Error('Could not convert byte Buffer to 5-bit Buffer');
//      }
//
//      return encode(testnet ? tHRP : HRP, addrBz);
        return ""
    }

    /**
     * convertBits
     *
     * groups buffers of a certain width to buffers of the desired width.
     *
     * For example, converts byte buffers to buffers of maximum 5 bit numbers,
     * padding those numbers as necessary. Necessary for encoding Ethereum-style
     * addresses as bech32 ones.
     *
     * @param {Buffer} data
     * @param {number} fromWidth
     * @param {number} toWidth
     * @param {boolean} pad
     * @returns {Buffer|null}
     */

    func convertBits(data: [UInt8], fromWidth: Int, toWidth: Int, pad: Bool = true) -> [UInt8] {
        var acc = 0
        var bits = 0

        var ret: [UInt8] = []
        let maxv  = (1 << toWidth) - 1

        for value in data {

//        for (let p = 0; p < data.length; ++p) {
//            const value = data[p];
            if value < 0 || value >> fromWidth != 0 {
                return []
            }
            acc = (acc << fromWidth) | Int(value)
            bits += fromWidth
            while bits >= toWidth {
                bits -= toWidth
                ret.append(UInt8((acc >> bits) & maxv))
            }
        }

        if pad {
            if bits > 0 {
                ret.append(UInt8((acc << (toWidth - bits)) & maxv))
            }

        } else if bits >= fromWidth || (Int((acc << (toWidth - bits)) & maxv) != 0) {
            return []
        }

        return ret
        //      return Buffer.from(ret);
    }

}
