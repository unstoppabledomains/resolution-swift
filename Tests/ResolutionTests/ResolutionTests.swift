//
//  resolutionTests.swift
//  resolutionTests
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
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

    func testSupportedDomains() throws {
        // Given // When // Then
        assert(false == resolution.isSupported(domain: "notsupported.crypto1"))
        assert(true == resolution.isSupported(domain: "supported.crypto"))
        assert(false == resolution.isSupported(domain: "notsupported.eth1"))
        assert(true == resolution.isSupported(domain: "supported.eth"))
        assert(false == resolution.isSupported(domain: "notsupported.xyz1"))
        assert(true == resolution.isSupported(domain: "supported.xyz"))
        assert(false == resolution.isSupported(domain: "notsupported.luxe1"))
        assert(true == resolution.isSupported(domain: "supported.luxe"))
        assert(false == resolution.isSupported(domain: "-notsupported.eth"))
        assert(true == resolution.isSupported(domain: "supported.kred"))
        assert(true == resolution.isSupported(domain: "supported.addr.reverse"))
    }
    
    func testNamehash() throws {
        // Given // When
        let firstHashTest = try resolution.namehash(domain: "test.crypto")
        let secondHashTest = try resolution.namehash(domain: "mongral.crypto")
        let thirdHashTest = try resolution.namehash(domain: "brad.crypto")
        let zilHashTest = try resolution.namehash(domain: "hello.zil")
        let ethHashTest = try resolution.namehash(domain: "matthewgould.eth")
        // Then
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
        assert(zilHashTest == "0xd7587a5c8caad4941c598440d34f3a454e79889c48e510d13c7c5d1dfc6eab45")
        assert(ethHashTest == "0x2b53e3f567989ee41b897998d89eb4d8cf0715fb2cfb41a64939a532c09e495e")
    }

    func testGetOwner() throws {

        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let domainZilReceived = expectation(description: "Exist ziliq domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var owner = ""
        var zilOwner = ""
        var ethOwner = ""
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
        
        resolution.owner(domain: "matthewgould.eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainEthReceived.fulfill()
                ethOwner = returnValue
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
        assert(owner.lowercased() == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased())
        assert(zilOwner.lowercased() == "0x2d418942dce1afa02d0733a2000c71b371a6ac07".lowercased())
        assert(ethOwner.lowercased() == "0x714ef33943d925731fbb89c99af5780d888bd106".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testGetResolver() throws {
        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var resolverAddress = ""
        var ethResolverAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.resolver(domain: "brad.crypto") { (result) in
            switch result {
            case .success(let returnValue):
                domainCryptoReceived.fulfill()
                resolverAddress = returnValue
            case .failure(let error):
                XCTFail("Expected resolver Address, but got \(error)")
            }
        }
        
        resolution.resolver(domain: "monkybrain.eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainEthReceived.fulfill()
                ethResolverAddress = returnValue
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
        assert(resolverAddress.lowercased() == "0xb66DcE2DA6afAAa98F2013446dBCB0f4B0ab2842".lowercased())
        assert(ethResolverAddress.lowercased() == "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unspecifiedResolver)
    }

    func testAddr() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ethAddress = ""
        var ethENSAddress = ""
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

        resolution.addr(domain: "monkybrain.eth", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainEthReceived.fulfill()
                ethENSAddress = returnValue
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
        assert(ethENSAddress == "0x842f373409191Cff2988A6F19AB9f605308eE462")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testChatID() throws {
        // Given
        let chatReceived = expectation(description: "Exist chat ID should be received")
        var chatID = ""

        // When
        resolution.chatId(domain: "crunk.eth")  { (result) in
            switch result {
            case .success(let returnValue):
                chatReceived.fulfill()
                chatID = returnValue
            case .failure(let error):
                XCTFail("Expected chat ID, but got \(error)")
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(chatID == "0x7e1d12f34e038a2bda3d5f6ee0809d72f668c357d9e64fd7f622513f06ea652146ab5fdee35dc4ce77f1c089fd74972691fccd48130306d9eafcc6e1437d1ab21b")
    }
    
    func testIpfs() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var hash = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.ipfsHash(domain: "brad.crypto") { result in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                hash = returnValue
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        resolution.ipfsHash(domain: "unregistered.crypto") { result in
            unregisteredResult = result
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(hash == "Qme54oEzRkgooJbCDr78vzKAWcv6DDEZqRhhDyDtzgrZP6")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unspecifiedResolver)
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
            assert(error == expectedError, "Expected \(expectedError), but got \(error)")
            return
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
        case ( .recordNotFound, .recordNotFound):
            return true
        case ( .recordNotSupported, .recordNotSupported):
            return true
        case ( .unsupportedNetwork, .unsupportedNetwork):
            return true
        case (.unspecifiedResolver, .unspecifiedResolver):
            return true
        case (.proxyReaderNonInitialized, .proxyReaderNonInitialized):
            return true
        // We don't use `default` here on purpose, so we don't forget updating this method on adding new variants.
        case (.unregisteredDomain, _),
            (.unsupportedDomain, _),
            (.recordNotFound, _),
            (.recordNotSupported, _),
            (.unsupportedNetwork, _),
            (.unspecifiedResolver, _),
            (.unknownError, _ ),
            (.proxyReaderNonInitialized, _):

            return false
        }
    }
}
