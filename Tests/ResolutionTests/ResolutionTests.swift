//
//  resolutionTests.swift
//  resolutionTests
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Johnny Good. All rights reserved.
//

import XCTest
@testable import Resolution

var resolution: Resolution!

class ResolutionTests: XCTestCase {

    let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        resolution = try! Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet")
    }

    func testNamehash() throws {
        // Given // When
        let firstHashTest = try resolution.namehash(domain: "test.crypto")
        let secondHashTest = try resolution.namehash(domain: "mongral.crypto")
        let thirdHashTest = try resolution.namehash(domain: "brad.crypto")
        let zilHashTest = try resolution.namehash(domain: "hello.zil")
        
        // Then
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
        assert(zilHashTest == "0xd7587a5c8caad4941c598440d34f3a454e79889c48e510d13c7c5d1dfc6eab45")
    }

    func testGetOwner() throws {

        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let domainZilReceived = expectation(description: "Exist ziliq domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var owner = ""
        var zilOwner = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.owner(domain: "brad.crypto") { (result) in
            switch result {
            case .success(let returnValue):
                domainCryptoReceived.fulfill()
                owner = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }
        
        resolution.owner(domain: "brad.zil") { (result) in
            switch result {
            case .success(let returnValue):
                domainZilReceived.fulfill()
                zilOwner = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }
        

        resolution.owner(domain: "unregistered.crypto") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(owner == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased())
        assert(zilOwner == "0x2d418942dce1afa02d0733a2000c71b371a6ac07".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testGetResolver() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var resolverAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.resolver(domain: "brad.crypto") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                resolverAddress = returnValue
            case .failure(let error):
                XCTFail("Expected resolver Address, but got \(error)")
            }
        }

        resolution.resolver(domain: "unregistered.crypto") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(resolverAddress == "0xb66DcE2DA6afAAa98F2013446dBCB0f4B0ab2842".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unconfiguredDomain)
    }

    func testAddr() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ethAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.addr(domain: "brad.crypto", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                ethAddress = returnValue
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }

        resolution.addr(domain: "brad.crypto", ticker: "unknown") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testIpfs() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var hash = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.ipfsHash(domain: "brad.crypto") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                hash = returnValue
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        resolution.ipfsHash(domain: "unregistered.crypto") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(hash == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unconfiguredDomain)
    }

    func testCustomRecord() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ipfshash = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.record(domain: "brad.crypto", key: "ipfs.html.value") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                ipfshash = returnValue
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        resolution.record(domain: "brad.crypto", key: "unknown.value") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(ipfshash == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testGetMany() throws {

        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let keys = ["ipfs.html.value", "crypto.BTC.address", "crypto.ETH.address", "someweirdstuf"]
        let domain = "brad.crypto"
        var values = [String: String]()

        // When
        resolution.records(domain: domain, keys: keys) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                values = returnValue
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        print(values)
        assert(values["ipfs.html.value"] == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6")
        assert(values["crypto.BTC.address"] == "bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y")
        assert(values["crypto.ETH.address"] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
        assert(values["someweirdstuf"] == "")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func checkError(completion: @escaping() throws -> Void, expectedError: ResolutionError) {
        do {
            try completion()
            XCTFail("Expected \(expectedError), but got none")
        } catch {
            if let catched = error as? ResolutionError {
                assert(catched == expectedError, "Expected \(expectedError), but got \(catched)")
                return
            }
            XCTFail("Expected ResolutionError, but got different \(error)")
        }
    }

    func checkError(result: Result<String, ResolutionError>, expectedError: ResolutionError) {
        switch result {
        case .success:
            XCTFail("Expected \(expectedError), but got none")
        case .failure(let error):
            if let catched = error as? ResolutionError {
                assert(catched == expectedError, "Expected \(expectedError), but got \(catched)")
                return
            }
            XCTFail("Expected ResolutionError, but got different \(error)")
        }
    }

}

extension ResolutionError: Equatable {
    public static func == (lhs: ResolutionError, rhs: ResolutionError) -> Bool {

        switch (lhs, rhs) {
        case ( .unregisteredDomain, .unregisteredDomain):
            return true
        case ( .unsupportedDomain, .unsupportedDomain):
            return true
        case ( .unconfiguredDomain, .unconfiguredDomain):
            return true
        case ( .recordNotFound, .recordNotFound):
            return true
        case ( .unsupportedNetwork, .unsupportedNetwork):
            return true
        case (.unspecifiedResolver, .unspecifiedResolver):
            return true
        // We don't use `default` here on purpose, so we don't forget updating this method on adding new variants.
        case (.unregisteredDomain, _),
            (.unsupportedDomain, _),
            (.unconfiguredDomain, _),
            (.recordNotFound, _),
            (.unsupportedNetwork, _),
            (.unknownError, _ ),
            (.unspecifiedResolver, _):
            return false
        }
    }
}
