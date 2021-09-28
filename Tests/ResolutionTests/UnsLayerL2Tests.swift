//
//  UnsLayerL2Tests.swift
//  ResolutionTests
//
//  Created by Johnny Good on 9/23/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import XCTest

#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

class UnsLayerL2Tests: XCTestCase {
    var unsLayer: UNSLayer!;
    
    
    override func setUp() {
        let providerUrl = "https://matic-testnet-archive-rpc.bwarelabs.com";
        let config = NamingServiceConfig(
            providerUrl: providerUrl,
            network: "polygon-mumbai");
        let contracts: [UNSContract] = [
          UNSContract(
            name: "UNSRegistry",
            contract: Contract(
                providerUrl: providerUrl,
                address: "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
                abi: try! parseAbi(fromFile: "unsRegistry")!,
                networking: DefaultNetworkingLayer()
            ),
            deploymentBlock: "0x01213f43"),
            UNSContract(
              name: "ProxyReader",
              contract: Contract(
                  providerUrl: providerUrl,
                  address: "0x332A8191905fA8E6eeA7350B5799F225B8ed30a9",
                  abi: try! parseAbi(fromFile: "unsProxyReader")!,
                  networking: DefaultNetworkingLayer()
              ),
              deploymentBlock: "0x01213f87"),
        ];
        unsLayer = try! UNSLayer(name: .uns, config: config, contracts: contracts)
    }
    
    func parseAbi(fromFile name: String) throws -> ABIContract? {
        #if INSIDE_PM
        let bundler = Bundle.module
        #else
        let bundler = Bundle(for: type(of: self))
        #endif
        if let filePath = bundler.url(forResource: name, withExtension: "json") {
            let data = try Data(contentsOf: filePath)
            let jsonDecoder = JSONDecoder()
            let abi = try jsonDecoder.decode([ABI.Record].self, from: data)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })

            return abiNative
        }
        return nil
    }
    
    // All functions of Layer2 except tokensOwnedBy and batchOwner should throw UnregisteredDomain when domain does not exists
    // functions batchOwner and tokensOwnedBy will return either array full of nil or empty [String]
    // It is expected to parse and combine the results of above functions with results from layer1
    func testUnregistered() throws {
        let domain = TestHelpers.TEST_DOMAINS[.UNREGISTERED_DOMAIN]!;
        let tokenId = "0x6d8b296e38dfd295f2f4feb9ef2721c48210b7d77c0a08867123d9bd5150cf47";
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.owner(domain: domain) },
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.addr(domain: domain, ticker: "whatever")},
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.getDomainName(tokenId: tokenId) },
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.getTokenUri(tokenId: tokenId) },
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.record(domain: domain, key: "whatever") },
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.records(keys: ["whatever"], for: domain) },
            expectedError: ResolutionError.unregisteredDomain
        );
        TestHelpers.checkError(
            completion: { let _ = try self.unsLayer.resolver(domain: domain) },
            expectedError: ResolutionError.unregisteredDomain
        );
    }
}
