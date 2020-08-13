// ResolverElement.swift

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let resolverElement = try ResolverElement(json)

import Foundation

// MARK: - ResolverElement
struct ResolverElement: Codable {
    let inputs: [Put]
    let payable: Bool?
    let stateMutability: StateMutability?
    let type: ResolverType
    let anonymous: Bool?
    let name: String?
    let constant: Bool?
    let outputs: [Put]?
}

// MARK: ResolverElement convenience initializers and mutators

extension ResolverElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ResolverElement.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        inputs: [Put]? = nil,
        payable: Bool?? = nil,
        stateMutability: StateMutability?? = nil,
        type: ResolverType? = nil,
        anonymous: Bool?? = nil,
        name: String?? = nil,
        constant: Bool?? = nil,
        outputs: [Put]?? = nil
    ) -> ResolverElement {
        return ResolverElement(
            inputs: inputs ?? self.inputs,
            payable: payable ?? self.payable,
            stateMutability: stateMutability ?? self.stateMutability,
            type: type ?? self.type,
            anonymous: anonymous ?? self.anonymous,
            name: name ?? self.name,
            constant: constant ?? self.constant,
            outputs: outputs ?? self.outputs
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
