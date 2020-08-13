// RegistryElement.swift

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let registryElement = try RegistryElement(json)

import Foundation

// MARK: - RegistryElement
struct RegistryElement: Codable {
    let constant: String?
    let inputs: [Put]
    let name: String?
    let outputs: [Put]?
    let payable: String?
    let stateMutability: StateMutability?
    let type: RegistryType
    let anonymous: String?
}

// MARK: RegistryElement convenience initializers and mutators

extension RegistryElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(RegistryElement.self, from: data)
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
        constant: String?? = nil,
        inputs: [Put]? = nil,
        name: String?? = nil,
        outputs: [Put]?? = nil,
        payable: String?? = nil,
        stateMutability: StateMutability?? = nil,
        type: RegistryType? = nil,
        anonymous: String?? = nil
    ) -> RegistryElement {
        return RegistryElement(
            constant: constant ?? self.constant,
            inputs: inputs ?? self.inputs,
            name: name ?? self.name,
            outputs: outputs ?? self.outputs,
            payable: payable ?? self.payable,
            stateMutability: stateMutability ?? self.stateMutability,
            type: type ?? self.type,
            anonymous: anonymous ?? self.anonymous
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
