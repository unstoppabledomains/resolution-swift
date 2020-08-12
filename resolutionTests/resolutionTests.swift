//
//  resolutionTests.swift
//  resolutionTests
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import XCTest
@testable import resolution

class resolutionTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let resolution = try Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
        let service = try resolution.doSomethingWith(domain: "brad.crypto");
        print(service);
    }
    
    func namehash() throws {
        let resolution = try Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
        let firstHashTest = try resolution.namehash(domain: "test.crypto");
        let secondHashTest = try resolution.namehash(domain: "mongral.crypto");
        let thirdHashTest = try resolution.namehash(domain: "brad.crypto");
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
