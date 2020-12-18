//
//  DnsUtils.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 12/18/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct DnsRecord: Equatable {
    var ttl: Int
    var type: String
    var data: String

    static public func == (lhs: DnsRecord, rhs: DnsRecord) -> Bool {
        return lhs.ttl == rhs.ttl && lhs.type == rhs.type && lhs.data == rhs.data
    }
}

public class DnsUtils {
    init() {}

    static let DefaultTtl: Int = 300

    public func toList(map: [String: String]) throws -> [DnsRecord] {
        let dnsTypes = self.getAllDnsTypes(map: map)
        var recordList: [DnsRecord] = []
        for type in dnsTypes {
            recordList += try self.constructDnsRecord(map: map, type: type)
        }
        return recordList
    }

    private func constructDnsRecord(map: [String: String], type: DnsType) throws -> [DnsRecord] {
        var dnsRecords: [DnsRecord] = []
        let ttl: Int = self.parseTtl(map: map, type: type)
        guard let jsonValueString: String = map["dns.\(type)"] else {
            return []
        }
        do {
            let data = Data(jsonValueString.utf8)
            // swiftlint:disable force_cast
            let recordDataArray = try JSONSerialization.jsonObject(with: data) as! [String]
            // swiftlint:enable force_cast
            for record in recordDataArray {
                dnsRecords.append(DnsRecord(ttl: ttl, type: "\(type)", data: record))
            }
            return dnsRecords
        } catch {
            throw DnsRecordsError.dnsRecordCorrupted(recordType: type)
        }
    }

    private func getAllDnsTypes(map: [String: String]) -> [DnsType] {
        var types: Set<DnsType> = []
        for (key, _) in map {
            let chunks: [String] = key.components(separatedBy: ".")
            if chunks.count >= 1 && chunks[1] != "ttl" {
                if let type = DnsType(rawValue: chunks[1]) {
                    types.insert(type)
                }
            }
        }
        return Array(types)
    }

    private func parseTtl(map: [String: String], type: DnsType) -> Int {
        if let recordTtl = Int(map["dns.\(type).ttl"]!) {
            return recordTtl
        }
        if let defaultRecordTtl = Int(map["dns.ttl"]!) {
            return defaultRecordTtl
        }
        return DnsUtils.DefaultTtl
    }
}
