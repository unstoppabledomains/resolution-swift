//
//  resolutionTests.swift
//  resolutionTests
//
//  Created by Johnny Good on 8/11/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import XCTest
#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

var resolution: Resolution!

class ResolutionTests: XCTestCase {

    let timeout: TimeInterval = 30
    override func setUp() {
        super.setUp()
        resolution = try! Resolution(
            configs: Configurations(
                uns: UnsLocations(
                    layer1: NamingServiceConfig(
                                providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                                network: "rinkeby"),
                    layer2: NamingServiceConfig(
                                providerUrl: "https://polygon-mumbai.infura.io/v3/c4bb906ed6904c42b19c95825fe55f39",
                                network: "polygon-mumbai")
                ),
                zns: NamingServiceConfig(
                    providerUrl: "https://dev-api.zilliqa.com",
                    network: "testnet")
            )
        );
    }
    
    func testUnsupportedNetwork() throws {
        TestHelpers.checkError(completion: {
            _ = try Resolution(configs: Configurations(
                uns:UnsLocations(
                    layer1: NamingServiceConfig(providerUrl: "https://ropsten.infura.io/v3/3c25f57353234b1b853e9861050f4817"),
                    layer2: NamingServiceConfig(
                                providerUrl: "https://matic-testnet-archive-rpc.bwarelabs.com",
                                network: "polygon-mumbai")
                )
            ));
        }, expectedError: .proxyReaderNonInitialized)
        
        TestHelpers.checkError(completion: {
            _ = try Resolution(configs: Configurations(
                ens: NamingServiceConfig(providerUrl: "https://kovan.infura.io/v3/d423cf2499584d7fbe171e33b42cfbee")
            ));
        }, expectedError: .registryAddressIsNotProvided)
        
        TestHelpers.checkError(completion: {
            _ = try Resolution(configs: Configurations(
                zns: NamingServiceConfig(providerUrl: "https://kovan.infura.io/v3/d423cf2499584d7fbe171e33b42cfbee")
            ));
        }, expectedError: .registryAddressIsNotProvided)
    }

    
    func testForUnregisteredDomain() throws {
        let UnregirestedDomainExpectation = expectation(description: "Domain should not be registered!")
        var NoRecordResult: Result<String, ResolutionError>!
        resolution.addr(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN), ticker: "eth") {
            NoRecordResult = $0
            UnregirestedDomainExpectation.fulfill();
        }
        waitForExpectations(timeout: timeout, handler: nil)
        TestHelpers.checkError(result: NoRecordResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testForUnspecifiedResolver() throws {
        resolution = try Resolution(configs: Configurations(
                    uns: UnsLocations(
                        layer1: NamingServiceConfig(providerUrl: "https://mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                                                    network: "mainnet"),
                        layer2:NamingServiceConfig(providerUrl: "https://matic-testnet-archive-rpc.bwarelabs.com",
                                                    network: "polygon-mumbai") )
        ))
        let UnregirestedDomainExpectation = expectation(description: "Domain should not have a Resolver!")
        var NoRecordResult: Result<String, ResolutionError>!
        resolution.addr(domain: TestHelpers.getTestDomain(.UNSPECIFIED_RESOLVER_DOMAIN), ticker: "eth") {
            NoRecordResult = $0
            UnregirestedDomainExpectation.fulfill();
        }
        waitForExpectations(timeout: timeout, handler: nil)
        TestHelpers.checkError(result: NoRecordResult, expectedError: ResolutionError.unspecifiedResolver("layer1"))
    }
    
    func testRinkeby() throws {
        resolution = try Resolution(configs: Configurations(
                uns: UnsLocations(
                    layer1: NamingServiceConfig(
                        providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                        network: "rinkeby"
                    ),
                    layer2: NamingServiceConfig(
                        providerUrl: "https://matic-testnet-archive-rpc.bwarelabs.com",
                        network: "polygon-mumbai")
                )
            )
        );
        let domainReceived = expectation(description: "Exist domain should be received")
        let ownerReceived = expectation(description: "Exist domain should be received")
        var ethAddress = ""
        var owner = "";
        resolution.addr(domain: TestHelpers.getTestDomain(.RINKEBY_DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        resolution.owner(domain: TestHelpers.getTestDomain(.RINKEBY_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                owner = returnValue;
                ownerReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(ethAddress == "0x1C8b9B78e3085866521FE206fa4c1a67F49f153A")
        assert(owner == "0x6EC0DEeD30605Bcd19342f3c30201DB263291589")
    }
    
    func testZilliqaTestNet() throws {
        let domainReceived = expectation(description: "Exist domain should be received")
        var zilOwner = ""
        resolution.owner(domain: TestHelpers.getTestDomain(.ZIL_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                zilOwner = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Owner Address, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(zilOwner == "0x5e398755d4e010e144e454fb5554bd68b28a8d9f")
    }

    func testSupportedDomains() throws {
        
        struct TestCase {
            let domain: String
            let expectation: XCTestExpectation
            var result: Bool?
            let expectedResult: Bool
        }
        
        let domains: [String] = [
            "supported.crypto",
            "supported.zil",
            "supported.nft",
            "supported.888",
            "supported.coin",
            "supported.blockchain",
            "supported.dao",
            "supported.bitcoin",
            "supported.wallet",
            "supported.x",
            "notsupported.crypto1",
            "notsupported.eth1",
            "supported.eth",
            "notsupported.xyz1",
            "supported.xyz",
            "notsupported.luxe1",
            "-notsupported.eth",
            "supported.kred",
            "supported.addr.reverse",
            "notsupported.definetelynotright"
        ]
        
        var cases = domains.compactMap {
            TestCase(
                domain: $0,
                expectation: expectation(description: "received answer for \($0)"),
                result: nil,
                expectedResult: $0.components(separatedBy: ".").first! == "supported"
            )
        }

        for i in 0..<cases.count {
            resolution.isSupported(domain: cases[i].domain) { result in
                switch result {
                case .success(let returnValue):
                    cases[i].result = returnValue
                    cases[i].expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected boolen, but got \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        for i in 0..<cases.count {
            assert(cases[i].result == cases[i].expectedResult)
        }
    }
    
    func testNamehash() throws {
        // Given // When
        let firstHashTest = try resolution.namehash(domain: "test.crypto")
        let secondHashTest = try resolution.namehash(domain: "mongral.crypto")
        let thirdHashTest = try resolution.namehash(domain: "brad.crypto")
        let zilHashTest = try resolution.namehash(domain: "hello.zil")
        let eightsHashTest = try resolution.namehash(domain: "supported.888")
        let nftHashTest = try resolution.namehash(domain: "supported.nft")
        let coinHashTest = try resolution.namehash(domain: "supported.coin")
        let walletHashTest = try resolution.namehash(domain: "supported.wallet")
        let blockchainHashTest = try resolution.namehash(domain: "supported.blockchain")
        let daoHashTest = try resolution.namehash(domain: "supported.dao")
        let ethHashTest = try resolution.namehash(domain: "matthewgould.eth")

        // Then
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
        assert(zilHashTest == "0xd7587a5c8caad4941c598440d34f3a454e79889c48e510d13c7c5d1dfc6eab45")
        assert(eightsHashTest == "0x991e7b420923938d448ac29878db96ce7176b6e76b661f9053989c3dc55c5ddf")
        assert(nftHashTest == "0x775c9305094df44261aae2a00c26829cf1af9b3b1aff867e3b22442a97dcc3a4")
        assert(coinHashTest == "0xa3dc422211db6cf55297e60de7b3c4e60e9b14365e159731fc10102dd90e394e")
        assert(walletHashTest == "0x2ee016c6cd8a5de80ec6a944b0d553ea0b86401ca87a515afb38d1553a85e197")
        assert(blockchainHashTest == "0x08b9bf8e0e42054ae8770a5cb8980c891f0b3842207692c375ea225a85962562")
        assert(daoHashTest == "0x5220cb2715d1d8df103752df7fbfc64b2ee51ede0c5cb57c534a984893e349c4")
        assert(ethHashTest == "0x2b53e3f567989ee41b897998d89eb4d8cf0715fb2cfb41a64939a532c09e495e")
    }
    
    func testWalletDomain() throws {
        let domainReceived = expectation(description: "Exist domain should be received")
        var ethAddress = "";
        resolution.addr(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(ethAddress == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037")
    }

    func testCoinDomain() throws {
        let domainReceived = expectation(description: "Exist domain should be received")
        var ethAddress = "";
        resolution.addr(domain: TestHelpers.getTestDomain(.COIN_DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(ethAddress == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037")
    }
    
    func testDns() throws {
        
        // Given
        let domain: String = TestHelpers.getTestDomain(.DOMAIN);
        let domainDnsReceived = expectation(description: "Dns record should be received")
        let dnsTypes: [DnsType] = [.A, .AAAA];
        
        var testResult: [DnsRecord] = []

        //When
        resolution.dns(domain: domain, types: dnsTypes) { (result) in
            switch result {
            case .success(let returnValue):
                domainDnsReceived.fulfill();
                testResult = returnValue;
            case .failure(let error):
                XCTFail("Expected dns record, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        assert(testResult[0] == DnsRecord(ttl: 98, type: "A", data: "10.0.0.1"));
        assert(testResult[1] == DnsRecord(ttl: 98, type: "A", data: "10.0.0.3"));
        
        let utils = DnsUtils.init();
        let backConversion = try utils.toMap(records: testResult);
        assert(backConversion["dns.A.ttl"] == "98");
        assert(backConversion["dns.A"] == """
        ["10.0.0.1","10.0.0.3"]
        """);
        
    }
    
    func testMultiChainAddress() throws {
        // Given
        let domain: String = TestHelpers.getTestDomain(.DOMAIN);
        let unNormalizedDomain: String = TestHelpers.getTestDomain(.UNNORMALIZED_DOMAIN);
        
        let erc20Received = expectation(description: "Erc20 record should be received");
        var erc20: String = "";
        
        let tronReceived = expectation(description: "tron record should be received");
        var tron: String = "";
        
        let eosReceived = expectation(description: "eos record should be received");
        var eos: String = "";
        
        let omniReceived = expectation(description: "omni record should be received");
        var omni: String = "";
        
        let NoRecordReceived = expectation(description: "no record error should be received")
        var NoRecordResult: Result<String, ResolutionError>!
        
        // When
        resolution.multiChainAddress(domain: TestHelpers.getTestDomain(.DOMAIN3), ticker: "usdt", chain: "erc20") {
            NoRecordResult = $0
            NoRecordReceived.fulfill()
        }
        
        resolution.multiChainAddress(domain: domain, ticker: "usdt", chain: "erc20") { (result) in
            switch result {
            case .success(let returnValue):
                erc20Received.fulfill();
                erc20 = returnValue;
            case .failure(let error):
                XCTFail("Expected erc20 usdt address, but got \(error)")
            }
        }

        resolution.multiChainAddress(domain: unNormalizedDomain, ticker: "usdt", chain: "eos") { (result) in
            switch result {
            case .success(let returnValue):
                eosReceived.fulfill();
                eos = returnValue;
            case .failure(let error):
                XCTFail("Expected eos usdt address, but got \(error)")
            }
        }

        resolution.multiChainAddress(domain: domain, ticker: "usdt", chain: "tron") { (result) in
            switch result {
            case .success(let returnValue):
                tronReceived.fulfill();
                tron = returnValue;
            case .failure(let error):
                XCTFail("Expected tron usdt address, but got \(error)")
            }
        }

        resolution.multiChainAddress(domain: unNormalizedDomain, ticker: "usdt", chain: "omni") { (result) in
            switch result {
            case .success(let returnValue):
                omniReceived.fulfill();
                omni = returnValue;
            case .failure(let error):
                XCTFail("Expected omni usdt address, but got \(error)")
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
        
        // Then
        assert(erc20 == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037")
        assert(eos == "letsminesome")
        assert(omni == "19o6LvAdCPkjLi83VsjrCsmvQZUirT4KXJ")
        assert(tron == "TNemhXhpX7MwzZJa3oXvfCjo5pEeXrfN2h")
        TestHelpers.checkError(result: NoRecordResult, expectedError: ResolutionError.recordNotFound("layer1"))
    }

    func testGetOwner() throws {
        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var owner = ""
        var ethOwner = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.owner(domain: TestHelpers.getTestDomain(.UNNORMALIZED_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                domainCryptoReceived.fulfill()
                owner = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }
        
        
        resolution.owner(domain: TestHelpers.getTestDomain(.ETH_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                domainEthReceived.fulfill()
                ethOwner = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }
        
        resolution.owner(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(owner.lowercased() == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased())
        assert(ethOwner.lowercased() == "0x842f373409191Cff2988A6F19AB9f605308eE462".lowercased())
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testGetBatchOwner() throws {
        
        // Given
        let domainCryptoReceived = expectation(description: "Existing Crypto domains' owners should be received")
        let particalResultReceived = expectation(description: "An existing domain and non-existing domain should result in mized response ")

        var owners: [String: String?] = [:]
        var partialResult: Result<[String: String?], ResolutionError>!

        // When
        resolution.batchOwners(domains: [TestHelpers.getTestDomain(.DOMAIN), TestHelpers.getTestDomain(.DOMAIN2)]) { (result) in
            switch result {
            case .success(let returnValue):
                owners = returnValue
                domainCryptoReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected owners, but got \(error)")
            }
        }
        
        resolution.batchOwners(domains: [TestHelpers.getTestDomain(.DOMAIN), TestHelpers.getTestDomain(.LAYER2_DOMAIN) ,TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)]) {
            partialResult = $0
            particalResultReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        switch partialResult {
        case .success(let dict):
            let lowercasedDict = dict.mapValues { $0?.lowercased()};
            assert( lowercasedDict[TestHelpers.getTestDomain(.DOMAIN)] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
            assert( lowercasedDict[TestHelpers.getTestDomain(.LAYER2_DOMAIN)] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
            XCTAssertNil(lowercasedDict[TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)]!);

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }
        
        let lowercasedOwners = owners.mapValues{$0?.lowercased()};
        assert( lowercasedOwners[TestHelpers.getTestDomain(.DOMAIN)] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
        assert( lowercasedOwners[TestHelpers.getTestDomain(.DOMAIN2)] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
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
        resolution.resolver(domain: TestHelpers.getTestDomain(.UNNORMALIZED_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                domainCryptoReceived.fulfill()
                resolverAddress = returnValue
            case .failure(let error):
                XCTFail("Expected resolver Address, but got \(error)")
            }
        }
        
        resolution.resolver(domain: TestHelpers.getTestDomain(.ETH_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                domainEthReceived.fulfill()
                ethResolverAddress = returnValue
            case .failure(let error):
                XCTFail("Expected resolver Address, but got \(error)")
            }
        }

        resolution.resolver(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then

        assert(resolverAddress.lowercased() == "0x95AE1515367aa64C462c71e87157771165B1287A".lowercased())
        assert(ethResolverAddress.lowercased() == "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41".lowercased())
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    //TODO Add zilliqa testnet domain
    func testAddr() throws {
        // Given
        let domainReceived = expectation(description: "Exist UNS domain should be received")
        let domainEthReceived = expectation(description: "Exist ENS domain should be received")
//        let domainZilReceived = expectation(description: "Exist ZNS domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ethAddress = ""
//        var zilENSAddress = ""
        var ethENSAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.addr(domain: TestHelpers.getTestDomain(.DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }

        resolution.addr(domain: TestHelpers.getTestDomain(.ETH_DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethENSAddress = returnValue
                domainEthReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        
// Todo replace brad.zil with a testnet domain
//        resolution.addr(domain: "brad.zil", ticker: "eth") { (result) in
//            switch result {
//            case .success(let returnValue):
//                domainZilReceived.fulfill()
//                zilENSAddress = returnValue
//            case .failure(let error):
//                XCTFail("Expected owner, but got \(error)")
//            }
//        }

        resolution.addr(domain: TestHelpers.getTestDomain(.DOMAIN), ticker: "unknown") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
//        assert(zilENSAddress == "0x45b31e01AA6f42F0549aD482BE81635ED3149abb")
        assert(ethENSAddress == "0x842f373409191Cff2988A6F19AB9f605308eE462")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound("layer1"))
    }

    func testChatID() throws {
        // Given
        let chatReceived = expectation(description: "Exist chat ID should be received")
        var chatID = ""

        // When

        resolution.chatId(domain: TestHelpers.getTestDomain(.DOMAIN))  { (result) in
            switch result {
            case .success(let returnValue):
                chatID = returnValue
                chatReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected chat ID, but got \(error)")
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)
        // Then
        assert(chatID == "0x8912623832e174f2eb1f59cc3b587444d619376ad5bf10070e937e0dc22b9ffb2e3ae059e6ebf729f87746b2f71e5d88ec99c1fb3c7c49b8617e2520d474c48e1c")
    }

    func testIpfs() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var hash = ""
        var etcHash = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.ipfsHash(domain: TestHelpers.getTestDomain(.DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                hash = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        resolution.ipfsHash(domain: TestHelpers.getTestDomain(.ETH_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                etcHash = returnValue
                domainEthReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }
        
        resolution.ipfsHash(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) { result in
            unregisteredResult = result
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(hash == "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb")
        assert(etcHash == "QmXSBLw6VMegqkCHSDBPg7xzfLhUyuRBzTb927KVzKC1vq")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testCustomRecord() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var customRecord = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.record(domain: TestHelpers.getTestDomain(.DOMAIN), key: "custom.record") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                customRecord = returnValue
            case .failure(let error):
                XCTFail("Expected custom record, but got \(error)")
            }
        }

        resolution.record(domain: TestHelpers.getTestDomain(.DOMAIN), key: "unknown.value") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(customRecord == "custom.value")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound("layer1"))
    }

    func testTokenUri() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var tokenURI = ""
        var unregisteredResult: Result<String, ResolutionError>!
        
        // When
        resolution.tokenURI(domain: TestHelpers.getTestDomain(.DOMAIN3)) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                tokenURI = returnValue
            case .failure(let error):
                XCTFail("Expected tokenURI, but got \(error)")
            }
        }
        resolution.tokenURI(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(tokenURI == "https://metadata.staging.unstoppabledomains.com/metadata/brad.crypto")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testTokenUriMetadata() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var tokenURIMetadata: TokenUriMetadata? = nil
        var unregisteredResult: Result<TokenUriMetadata, ResolutionError>!

        // When
        resolution.tokenURIMetadata(domain: TestHelpers.getTestDomain(.DOMAIN3)) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                tokenURIMetadata = returnValue
            case .failure(let error):
                XCTFail("Expected tokenURIMetadata, but got \(error)")
            }
        }
        resolution.tokenURIMetadata(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(tokenURIMetadata?.name == TestHelpers.getTestDomain(.DOMAIN3))
        assert(tokenURIMetadata?.attributes.count == 5)
        assert(tokenURIMetadata?.properties.records["crypto.ETH.address"] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testUnhash() throws {
        // Given
        let domainReceived = expectation(description: "Existing domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var domainName: String = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.unhash(hash: "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9", serviceName: .uns) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                domainName = returnValue
            case .failure(let error):
                XCTFail("Expected domainName, but got \(error)")
            }
        }
        resolution.unhash(hash: "0xdeaddeaddead", serviceName: .uns) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(domainName == TestHelpers.getTestDomain(.DOMAIN3))
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testGetMany() throws {

        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let keys = ["ipfs.html.value", "crypto.BTC.address", "crypto.ETH.address", "someweirdstuf"]
        let domain = TestHelpers.getTestDomain(.DOMAIN3)
        var values = [String: String]()

        // When
        resolution.records(domain: domain, keys: keys) { (result) in
            switch result {
            case .success(let returnValue):
                values = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(values["ipfs.html.value"] == "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb")
        assert(values["crypto.BTC.address"] == "bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y")
        assert(values["crypto.ETH.address"] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
        assert(values["someweirdstuf"] == "")
    }

    func testLocations() throws {
        let locationsReceived = expectation(description: "Locations for each domain should be received");
        let unsuportedEnsReceived = expectation(description: "ENS is not supported");
        let unsuportedZnsReceived = expectation(description: "ZNS is not supported");
        
        let domains = [
            TestHelpers.getTestDomain(.DOMAIN),
            TestHelpers.getTestDomain(.LAYER2_DOMAIN),
            TestHelpers.getTestDomain(.COIN_DOMAIN),
            TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)
        ];
        let ensDomain = TestHelpers.getTestDomain(.ETH_DOMAIN);
        let znsDomain = TestHelpers.getTestDomain(.ZIL_DOMAIN);
        
        var EnsResult: Result<[String: Location], ResolutionError>!
        var ZnsResult: Result<[String: Location], ResolutionError>!
        
        var locations: [String: Location] = [:];
        resolution.locations(domains: domains) { result in
            switch result {
            case .success(let returnValue):
                locationsReceived.fulfill()
                locations = returnValue;
            case .failure(let error):
                XCTFail("Expected locations, but got \(error)");
            }
        }
        
        resolution.locations(domains: [ensDomain]) {
            EnsResult = $0;
            unsuportedEnsReceived.fulfill()
        }
        
        resolution.locations(domains: [znsDomain]) {
            ZnsResult = $0;
            unsuportedZnsReceived.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        
        let answers: [String: Location] = [
            TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN): Location(
                registryAddress: nil,
                resolverAddress: nil,
                networkId: nil,
                blockchain: nil,
                owner: nil,
                providerURL: nil
            ),
            TestHelpers.getTestDomain(.DOMAIN): Location(
                registryAddress: "0xaad76bea7cfec82927239415bb18d2e93518ecbb",
                resolverAddress: "0x95AE1515367aa64C462c71e87157771165B1287A",
                networkId: "4",
                blockchain: "ETH",
                owner: "0xe7474D07fD2FA286e7e0aa23cd107F8379085037",
                providerURL: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817"
            ),
            TestHelpers.getTestDomain(.COIN_DOMAIN):Location(
                registryAddress: "0x7fb83000b8ed59d3ead22f0d584df3a85fbc0086",
                resolverAddress: "0x7fb83000B8eD59D3eAD22f0D584Df3a85fBC0086",
                networkId: "4",
                blockchain: "ETH",
                owner: "0xe7474D07fD2FA286e7e0aa23cd107F8379085037",
                providerURL: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817"
            ),
            TestHelpers.getTestDomain(.LAYER2_DOMAIN): Location(
                registryAddress: "0x2a93c52e7b6e7054870758e15a1446e769edfb93",
                resolverAddress: "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
                networkId: "80001",
                blockchain: "MATIC",
                owner: "0xe7474D07fD2FA286e7e0aa23cd107F8379085037",
                providerURL: "https://polygon-mumbai.infura.io/v3/c4bb906ed6904c42b19c95825fe55f39"
            ),
        ];
        
        assert(!locations.isEmpty);
        assert(locations.count == domains.count);
        domains.forEach { domain in
            print(locations[domain]);
            print(answers[domain]);
            
            assert(locations[domain] == answers[domain])
        }
        
        TestHelpers.checkError(result: EnsResult, expectedError: .methodNotSupported)
        TestHelpers.checkError(result: ZnsResult, expectedError: .methodNotSupported)
    }
    
    
    func testCheckDomain() throws {
        // Given
        let validDomainName: String = "valid.domain-test-123.crypto"
        let invalidDomainName: String = "in!va(li)d+domain"

        // When
        do {
            _ = try resolution.namehash(domain: validDomainName)
        } catch {
            // Then
            XCTFail("Expected to not throw, but got \(error)")
        }
        TestHelpers.checkError(completion: { _ = try resolution.namehash(domain: invalidDomainName)}, expectedError: ResolutionError.invalidDomainName)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testOwner() throws {
        // Given
        let layer2OwnerReceived = expectation(description: "Domain should return owner address on layer2");
        let layer1OwnerReceived = expectation(description: "Domain should return owner address on layer1");
        let unregisteredReceived = expectation(description: "Unregistered domain should be received");
        

        var layer2Owner = ""
        var layer1Owner = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.owner(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                layer2OwnerReceived.fulfill()
                layer2Owner = returnValue
            case .failure(let error):
                XCTFail("Expected owner from layer2, but got \(error)")
            }
        }
        
        resolution.owner(domain: TestHelpers.getTestDomain(.DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                layer1OwnerReceived.fulfill();
                layer1Owner = returnValue;
            case .failure(let error):
                XCTFail("Expected owner from layer1, but got \(error)")
            }
        }
        
        resolution.owner(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(layer2Owner.lowercased() == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased())
        assert(layer1Owner.lowercased() == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased())
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    
    func testGetBatchOwnerMultiLayer() throws {
        let layer2Domain: String = TestHelpers.getTestDomain(.LAYER2_DOMAIN);
        let layer1Domain: String = TestHelpers.getTestDomain(.DOMAIN);
        let unregisteredDomain: String = TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN);

        // Given
        let domainCryptoReceived = expectation(description: "Existing Crypto domains' owners should be received")
        let particalResultReceived = expectation(description: "An existing domain and non-existing domain should result in mized response ")

        var owners: [String: String?] = [:]
        var partialResult: Result<[String: String?], ResolutionError>!

        // When
        resolution.batchOwners(domains: [layer2Domain, layer1Domain]) { (result) in
            switch result {
            case .success(let returnValue):
                owners = returnValue
                domainCryptoReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected owners, but got \(error)")
            }
        }

        resolution.batchOwners(domains: [layer2Domain, unregisteredDomain]) {
            partialResult = $0
            particalResultReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        switch partialResult {
        case .success(let dict):
            let lowercasedOwners = dict.mapValues( {$0?.lowercased()} )
            assert( lowercasedOwners[layer2Domain] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
            assert( lowercasedOwners[unregisteredDomain]! == nil )

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }

        let lowercasedOwners = owners.mapValues{ $0?.lowercased() }
        assert( lowercasedOwners[layer2Domain] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
        assert( lowercasedOwners[layer1Domain] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
    }
    
    func testAddrMultiLayer() throws {
        // Given
        let ethFroml2Received = expectation(description: "Eth address from layer 2 should be received");
        let ethFroml1Received = expectation(description: "Eth address from layer 1 should be received");
        let unregisteredReceived = expectation(description: "Unregistered domain should be received");
        let noRecordReceived = expectation(description: "No such record exists should be received");

        var layer2EthAddress = "";
        var layer1EthAddress = "";
        var unregisteredResult: Result<String, ResolutionError>!
        var noRecordResult: Result<String, ResolutionError>!

        // When
        resolution.addr(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                layer2EthAddress = returnValue
                ethFroml2Received.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address from layer2, but got \(error)")
            }
        }

        resolution.addr(domain: TestHelpers.getTestDomain(.DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                layer1EthAddress = returnValue
                ethFroml1Received.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address from layer1, but got \(error)")
            }
        }
        
        resolution.addr(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN), ticker: "unknown") {
            unregisteredResult = $0;
            unregisteredReceived.fulfill()
        }

        resolution.addr(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), ticker: "dummy") {
            noRecordResult = $0;
            noRecordReceived.fulfill();
        }
        
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(layer2EthAddress == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037");
        assert(layer1EthAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain);
        TestHelpers.checkError(result: noRecordResult, expectedError: ResolutionError.recordNotFound("layer2"));
    }
    
    func testRecord() throws {
        // Given
        let customRecordReceived = expectation(description: "Custom record should be recieved");
        let noRecordReceived = expectation(description: "No such record should exists");
        
        var customRecord = "";
        var noRecordResut: Result<String, ResolutionError>!;
        // When
        resolution.record(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), key: "custom.record") { (result) in
            switch result {
            case.success(let returnValue):
                customRecord = returnValue;
                customRecordReceived.fulfill();
            case .failure(let error):
                XCTFail("Expected to get a custom record from layer 2, but got \(error)");
            }
        }
        
        resolution.record(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), key: "noSuchRecord") {
            noRecordResut = $0;
            noRecordReceived.fulfill();
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        // Then
        
        assert(customRecord == "custom.value");
        TestHelpers.checkError(result: noRecordResut, expectedError: ResolutionError.recordNotFound("layer2"));
    }
    
    func testRecords() throws {
        // Given
        let recordsFromL2Received = expectation(description: "Records from layer2 should be received");
        let recordKeys: [String] = ["crypto.ETH.address", "custom.record", "weirdrecord"];
        
        var layer2Records: [String: String] = [:]
        // When
        resolution.records(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), keys: recordKeys) { result in
            switch result {
            case .success(let returnValue):
                layer2Records = returnValue;
                recordsFromL2Received.fulfill();
            case.failure(let error):
                XCTFail("Expected to get record from layer 2, but got \(error)");
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        // Then
        assert(layer2Records.count == recordKeys.count);
        assert(layer2Records["crypto.ETH.address"] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037");
        assert(layer2Records["custom.record"] == "custom.value");
        assert(layer2Records["weirdrecord"] == "");
    }
    
    func testAllRecordsErrors() throws {
        let ensIsNotSupportedReceived = expectation(description: "ENS is not supported for this method");
        let unregisteredUNSDomainReceived = expectation(description: "Unregistered UNS domain should be thrown");
        let unregisteredZNSDomainReceived = expectation(description: "Unregistered UNS domain should be thrown");
        
        var ensResult: Result<[String: String], ResolutionError>!;
        var unsResult: Result<[String: String], ResolutionError>!;
        var znsResult: Result<[String: String], ResolutionError>!;
        
        resolution.allRecords(domain: TestHelpers.getTestDomain(.ETH_DOMAIN)) { result in
            ensIsNotSupportedReceived.fulfill();
            ensResult = result;
        }
        
        resolution.allRecords(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) { result in
            unregisteredUNSDomainReceived.fulfill();
            unsResult = result;
        }
        
        resolution.allRecords(domain: TestHelpers.getTestDomain(.UNREGISTERED_ZIL)) { result in
            unregisteredZNSDomainReceived.fulfill();
            znsResult = result;
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        TestHelpers.checkError(result: ensResult, expectedError: .methodNotSupported);
        TestHelpers.checkError(result: unsResult, expectedError: .unregisteredDomain);
        TestHelpers.checkError(result: znsResult, expectedError: .unregisteredDomain);
    }
    
    func testAllRecords() throws {
        
        let receievedAllRecordsFromUnsDomain = expectation(description: "Should receieve all records from uns domain");
        var unsDomainRecords: [String: String]!;
        
        resolution.allRecords(domain: TestHelpers.getTestDomain(.DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                unsDomainRecords = returnValue;
                receievedAllRecordsFromUnsDomain.fulfill();
            case .failure(let error):
                XCTFail("Expected all records from uns domain, but got \(error)");
            }
        }
        
        
        waitForExpectations(timeout: timeout, handler: nil);
        let expectedRecords: [String: String] = [
            "dns.ttl": "128",
            "dns.A.ttl": "98",
            "dns.A": "[\"10.0.0.1\", \"10.0.0.3\"]",
            "crypto.USDT.version.OMNI.address": "19o6LvAdCPkjLi83VsjrCsmvQZUirT4KXJ",
            "crypto.USDT.version.TRON.address": "TNemhXhpX7MwzZJa3oXvfCjo5pEeXrfN2h",
            "custom.record": "custom.value",
            "dweb.ipfs.hash": "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb",
            "crypto.ETH.address": "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8",
            "dns.AAAA": "[]",
            "gundb.username.value": "0x8912623832e174f2eb1f59cc3b587444d619376ad5bf10070e937e0dc22b9ffb2e3ae059e6ebf729f87746b2f71e5d88ec99c1fb3c7c49b8617e2520d474c48e1c",
            "crypto.USDT.version.ERC20.address": "0xe7474D07fD2FA286e7e0aa23cd107F8379085037",
            "ipfs.html.value": "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb",
            "crypto.USDT.version.EOS.address": "letsminesome"
        ];
        assert(expectedRecords == unsDomainRecords);
    }
    
    func testZilAllRecords() throws {
        let recordsReceived = expectation(description: "Zilliqa records should be received");
        var zilRecords: [String: String] = [:]
        
        resolution.allRecords(domain: TestHelpers.getTestDomain(.ZIL_DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                zilRecords = returnValue;
                recordsReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected to get zilliqa records, but got \(error)");
            }
        }

        waitForExpectations(timeout: timeout, handler: nil);

        let expectedRecords: [String: String] = [
            "ZIL": "zil1tcucw4w5uqgwz38y2na4249adzeg4rvl94kwhm",
            "crypto.ETH.address": "0x084Ac37CDEfE1d3b68a63c08B203EFc3ccAB9742"
        ];
        assert(zilRecords == expectedRecords);
    }
    
    
    func testTokenUriMultiLayer() throws {
        let tokenUriFromL2 = expectation(description: "TokenUri from layer2 domain should be receieved");
        let tokenUriFromL1 = expectation(description: "TokenUri from layer1 domain should be received");
        
        var layer2TokenUri = "";
        var layer1TokenUri = "";
        
        
        resolution.tokenURI(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                layer2TokenUri = returnValue;
                tokenUriFromL2.fulfill();
            case .failure(let error):
                XCTFail("Expected token URI from L2, but got \(error)");
            }
        }
        
        resolution.tokenURI(domain: TestHelpers.getTestDomain(.DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                layer1TokenUri = returnValue;
                tokenUriFromL1.fulfill();
            case .failure(let error):
                XCTFail("Expected token URI from L1, but got \(error)");
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        
        assert(layer1TokenUri == "https://metadata.staging.unstoppabledomains.com/metadata/udtestdev-265f8f.crypto");
        assert(layer2TokenUri == "https://metadata.staging.unstoppabledomains.com/metadata/47175376536410263098700840153319778926909723329866678110537362361339406517871");
    }
    
    func testUnhashMultiLayer() throws {
        
        let layer2Domain = expectation(description: "Layer 2 domain name should be received");
        let layer1Domain = expectation(description: "Layer 1 domain name should be received");
        
        let layer2Hash = "0x684c51201935fdd42fbaebe43b1986f13984b94569c4c4827beda913232d066f";
        let layer1Hash = "0x8bbfa2d157c884c94ed35832a4c327a795c12b64bc4282e3521bcad1fc4d6a8d";
        
        var layer2DomainName = "";
        var layer1DomainName = "";
        
        resolution.unhash(hash: layer2Hash, serviceName: .uns) { result in
            switch (result) {
            case .success(let returnValue):
                layer2DomainName = returnValue;
                layer2Domain.fulfill();
            case .failure(let error):
                XCTFail("Expected layer2 domain name, but got \(error)");
            }
        }
        
        resolution.unhash(hash: layer1Hash, serviceName: .uns) { result in
            switch (result) {
            case .success(let returnValue):
                layer1DomainName = returnValue;
                layer1Domain.fulfill();
            case .failure(let error):
                XCTFail("Expected layer1 domain name, but got \(error)");
            }
        }
        
        waitForExpectations(timeout: timeout, handler: nil);
        
        assert(layer1DomainName == "johnnytestdev6357.crypto");
        assert(layer2DomainName == "udtestdev-johnnytest.wallet");
    }
    
}
