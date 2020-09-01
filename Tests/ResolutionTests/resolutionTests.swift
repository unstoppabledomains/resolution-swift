//
//  resolutionTests.swift
//  resolutionTests
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import XCTest
@testable import Resolution

var resolution: Resolution!;

class resolutionTests: XCTestCase {
    
    override func setUp() {
        super.setUp();
        resolution = try! Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
    }
    
    func testNamehash() throws {
        let firstHashTest = try resolution.namehash(domain: "test.crypto");
        let secondHashTest = try resolution.namehash(domain: "mongral.crypto");
        let thirdHashTest = try resolution.namehash(domain: "brad.crypto");
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
    }
    
    func testGetOwner() throws {
        let owner = try resolution.owner(domain: "brad.crypto");
        assert(owner == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased() );
        
        checkError(completion: {
            let _ = try resolution.owner(domain: "unregistered.crypto");
        }, expectedError: ResolutionError.UnregisteredDomain)
    }
    
    func testGetResolver() throws {
        let resolverAddress = try resolution.resolver(domain: "brad.crypto");
        assert(resolverAddress == "0xb66DcE2DA6afAAa98F2013446dBCB0f4B0ab2842".lowercased());
        
        checkError(completion: {
            let _ = try resolution.resolver(domain: "unregistered.crypto");
        }, expectedError: ResolutionError.UnconfiguredDomain)
    }
    
    func testAddr() throws {
        let ethAddress = try resolution.addr(domain: "brad.crypto", ticker: "eth");
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        
        checkError(completion: {
            let _ = try resolution.addr(domain: "brad.crypto", ticker: "unknown");
        }, expectedError: ResolutionError.RecordNotFound)
    }
    
    func testIpfs() throws {
        let hash = try resolution.ipfsHash(domain: "brad.crypto");
        assert(hash == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6");
        
        checkError(completion: {
            let _ = try resolution.ipfsHash(domain: "unregistered.crypto")
        }, expectedError: ResolutionError.UnconfiguredDomain)
    }
    
    func testCustomRecord() throws {
        let ipfshash = try resolution.getCustomRecord(domain: "brad.crypto", key: "ipfs.html.value");
        assert (ipfshash == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6")
        
        checkError(completion: {
            let _ = try resolution.getCustomRecord(domain: "brad.crypto", key: "unknown.value");
        }, expectedError: ResolutionError.RecordNotFound)
    }
    
    func testGetMany() throws {
        let keys = ["ipfs.html.value", "crypto.BTC.address", "crypto.ETH.address", "someweirdstuf"];
        let domain = "brad.crypto";
        let manyResults = try resolution.getMany(domain: domain, keys: keys);
        print(manyResults);
        assert(manyResults[0] == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6");
        assert(manyResults[1] == "bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y");
        assert(manyResults[2] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        assert(manyResults[3] == "");
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func checkError(completion: @escaping() throws -> Void, expectedError: ResolutionError)  {
        do {
            try completion()
            XCTFail("Expected \(expectedError), but got none")
        } catch {
            if let catched = error as? ResolutionError {
                assert(catched == expectedError, "Expected \(expectedError), but got \(catched)");
                return ;
            }
            XCTFail("Expected ResolutionError, but got different \(error)");
        }
    }
    
}
