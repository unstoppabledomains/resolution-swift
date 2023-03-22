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

    static func getL1TestNetRpcUrl() -> String {
        return ProcessInfo.processInfo.environment["L1_TEST_NET_RPC_URL"] ?? "https://goerli.infura.io/v3/3c25f57353234b1b853e9861050f4817";
    }

    static func getL2TestNetRpcUrl() -> String {
        return ProcessInfo.processInfo.environment["L2_TEST_NET_RPC_URL"] ?? "https://polygon-mumbai.infura.io/v3/3c25f57353234b1b853e9861050f4817";
    }

    let timeout: TimeInterval = 30
    override func setUp() {
        super.setUp()
        resolution = try! Resolution(
            configs: Configurations(
                uns: UnsLocations(
                    layer1: NamingServiceConfig(
                                providerUrl: ResolutionTests.getL1TestNetRpcUrl(),
                                network: "goerli"),
                    layer2: NamingServiceConfig(
                                providerUrl: ResolutionTests.getL2TestNetRpcUrl(),
                                network: "polygon-mumbai"),
                    zlayer: NamingServiceConfig(
                        providerUrl: "https://dev-api.zilliqa.com",
                        network: "testnet"
                    )
                )
            )
        );
    }

    func testInitWithApiKey() throws {
        let resolution = try? Resolution(
            apiKey: "some key"
        );

        assert(resolution != nil);
    }

    func testInitWithApiKeyAndZns() throws {
        let resolution = try? Resolution(
            apiKey: "some key",
            znsLayer: NamingServiceConfig(providerUrl: "https://someurl", network: "mainnet")
        );

        assert(resolution != nil);
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
            "brad.zil",
            "supported.nft",
            "supported.888",
            "supported.blockchain",
            "supported.dao",
            "supported.bitcoin",
            "supported.wallet",
            "supported.x",
            "notsupported.crypto1",
            "notsupported.eth1",
            "notsupported.eth",
            "notsupported.xyz1",
            "notsupported.xyz",
            "notsupported.luxe1",
            "-notsupported.eth",
            "notsupported.kred",
            "notsupported.addr.reverse",
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
        let walletHashTest = try resolution.namehash(domain: "supported.wallet")
        let blockchainHashTest = try resolution.namehash(domain: "supported.blockchain")
        let daoHashTest = try resolution.namehash(domain: "supported.dao")
        let ethHashTest = try resolution.namehash(domain: "matthewgould.eth")

        // Then
        assert(firstHashTest == "0xb72f443a17edf4a55f766cf3c83469e6f96494b16823a41a4acb25800f303103")
        assert(secondHashTest == "0x2038e73f23cbe8c0774c901fbfa77d3ac21c0b13b8f6456f89030d4f13eebba9")
        assert(thirdHashTest == "0x756e4e998dbffd803c21d23b06cd855cdc7a4b57706c95964a37e24b47c10fc9")
        assert(zilHashTest == "0xf76369aa1547bd507201e497b75dc66961224ce61cf64b84b5cef81f340706d8")
        assert(eightsHashTest == "0x991e7b420923938d448ac29878db96ce7176b6e76b661f9053989c3dc55c5ddf")
        assert(nftHashTest == "0x775c9305094df44261aae2a00c26829cf1af9b3b1aff867e3b22442a97dcc3a4")
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
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
    }

    func testDns() throws {

        // Given
        let domain: String = TestHelpers.getTestDomain(.WALLET_DOMAIN);
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
        let domain: String = TestHelpers.getTestDomain(.WALLET_DOMAIN);
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
        resolution.multiChainAddress(domain: TestHelpers.getTestDomain(.LAYER2_DOMAIN), ticker: "usdt", chain: "erc20") {
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
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var owner = ""
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

        resolution.owner(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(owner.lowercased() == "0xD92d2A749424a5181AD7d45f786a9FFE46c10A7C".lowercased())
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
            assert( lowercasedDict[TestHelpers.getTestDomain(.DOMAIN)] == "0xe586d5Bf4d7779498648DF67b73c88a712E4359d".lowercased() )
            assert( lowercasedDict[TestHelpers.getTestDomain(.LAYER2_DOMAIN)] == "0x499dD6D875787869670900a2130223D85d4F6Aa7".lowercased() )
            XCTAssertNil(lowercasedDict[TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)]!);

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }

        let lowercasedOwners = owners.mapValues{$0?.lowercased()};
        assert( lowercasedOwners[TestHelpers.getTestDomain(.DOMAIN)] == "0xe586d5Bf4d7779498648DF67b73c88a712E4359d".lowercased() )
        assert( lowercasedOwners[TestHelpers.getTestDomain(.DOMAIN2)] == "0x499dD6D875787869670900a2130223D85d4F6Aa7".lowercased() )
    }

    func testGetResolver() throws {
        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var resolverAddress = ""
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


        resolution.resolver(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(resolverAddress.lowercased() == "0x2a93C52E7B6E7054870758e15A1446E769EdfB93".lowercased())
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testAddr() throws {
        // Given
        let domainReceived = expectation(description: "Exist UNS domain should be received")
        let domainZilReceived = expectation(description: "Exist ZNS domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ethAddress = ""
        var zilUNSAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.addr(domain: TestHelpers.getTestDomain(.DOMAIN), ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error.localizedDescription)")
            }
        }

        resolution.addr(domain: "uns-devtest-testdomain303030.zil", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainZilReceived.fulfill()
                zilUNSAddress = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }

        resolution.addr(domain: TestHelpers.getTestDomain(.DOMAIN), ticker: "unknown") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        print("Eth Address: ")
        print(ethAddress)
        assert(ethAddress == "0x084Ac37CDEfE1d3b68a63c08B203EFc3ccAB9742")
        assert(zilUNSAddress == "0x45b31e01AA6f42F0549aD482BE81635ED3149abb")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound("layer1"))
    }

    func testChatID() throws {

        // Given
        let chatReceived = expectation(description: "Exist chat ID should be received")
        var chatID = ""

        // When
        resolution.chatId(domain: TestHelpers.getTestDomain(.DOMAIN3))  { (result) in
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
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var hash = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.ipfsHash(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN)) { result in
            switch result {
            case .success(let returnValue):
                hash = returnValue
                domainReceived.fulfill()
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
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testCustomRecord() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var customRecord = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.record(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN), key: "custom.record") { (result) in
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
        resolution.tokenURI(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN)) { (result) in
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
        assert(tokenURI == "https://metadata.ud-staging.com/metadata/6304531997610998161237844647282663196661123000121147597890468333969432655810")
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testTokenUriMetadata() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var tokenURIMetadata: TokenUriMetadata? = nil
        var unregisteredResult: Result<TokenUriMetadata, ResolutionError>!

        // When
        resolution.tokenURIMetadata(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN)) { (result) in
            switch result {
            case .success(let returnValue):
                tokenURIMetadata = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected tokenURIMetadata, but got \(error)")
            }
        }

        resolution.tokenURIMetadata(domain: TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        let domainNamehash = try resolution.namehash(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN))
        // Then
        assert(tokenURIMetadata?.name == TestHelpers.getTestDomain(.WALLET_DOMAIN))
        assert(tokenURIMetadata?.attributes.count == 5)
        assert(tokenURIMetadata?.namehash == domainNamehash)
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testUnhash() throws {
        // Given
        let domainReceived = expectation(description: "Existing domain should be received")
        var domainName: String = ""

        // When
        resolution.unhash(hash: "0x684c51201935fdd42fbaebe43b1986f13984b94569c4c4827beda913232d066f", serviceName: .uns) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                domainName = returnValue
            case .failure(let error):
                XCTFail("Expected domainName, but got \(error)")
            }
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(domainName == "udtestdev-johnnytest.wallet")
    }

    func testGetMany() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let keys = ["ipfs.html.value", "crypto.ETH.address", "someweirdstuf"]
        let domain = TestHelpers.getTestDomain(.WALLET_DOMAIN)
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
        assert(values["crypto.ETH.address"] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
        assert(values["someweirdstuf"] == "")
    }

    func testLocations() throws {
        let locationsReceived = expectation(description: "Locations for each domain should be received");

        let domains = [
            TestHelpers.getTestDomain(.DOMAIN),
            TestHelpers.getTestDomain(.LAYER2_DOMAIN),
            TestHelpers.getTestDomain(.WALLET_DOMAIN),
            TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN)
        ];

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
                registryAddress: "0x801452cfac27e79a11c6b185986fde09e8637589",
                resolverAddress: "0x0555344A5F440Bd1d8cb6B42db46c5e5D4070437",
                networkId: "5",
                blockchain: "ETH",
                owner: "0xe586d5Bf4d7779498648DF67b73c88a712E4359d",
                providerURL: ResolutionTests.getL1TestNetRpcUrl()
            ),
            TestHelpers.getTestDomain(.WALLET_DOMAIN):Location(
                registryAddress: "0x2a93c52e7b6e7054870758e15a1446e769edfb93",
                resolverAddress: "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
                networkId: "80001",
                blockchain: "MATIC",
                owner: "0xD92d2A749424a5181AD7d45f786a9FFE46c10A7C",
                providerURL: ResolutionTests.getL2TestNetRpcUrl()
            ),
            TestHelpers.getTestDomain(.LAYER2_DOMAIN): Location(
                registryAddress: "0x2a93c52e7b6e7054870758e15a1446e769edfb93",
                resolverAddress: "0x2a93C52E7B6E7054870758e15A1446E769EdfB93",
                networkId: "80001",
                blockchain: "MATIC",
                owner: "0x499dD6D875787869670900a2130223D85d4F6Aa7",
                providerURL: ResolutionTests.getL2TestNetRpcUrl()
            ),
        ];

        assert(!locations.isEmpty);
        assert(locations.count == domains.count);
        domains.forEach { domain in
            assert(locations[domain] == answers[domain])
        }
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
        assert(layer2Owner.lowercased() == "0x499dD6D875787869670900a2130223D85d4F6Aa7".lowercased())
        assert(layer1Owner.lowercased() == "0xe586d5Bf4d7779498648DF67b73c88a712E4359d".lowercased())
        TestHelpers.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testLayer2Mainnet() throws {
        let addrExp = expectation(description: "should resolve eth address");
        let recordNotFoundExp = expectation(description: "should throw a record not found");
        let locationExp = expectation(description: "should return correct location obj");
        let ownerExp = expectation(description: "should return correct owner");
        let resolverExp = expectation(description: "should return resolver address");

        var recordNotFoundResult: Result<String, ResolutionError>!

        var addr = "";
        var resolver = "";
        var owner = "";
        var loc = Location();

        resolution = try Resolution();

        resolution.record(domain: "udtestdev-matic-mainnet-test.crypto", key: "crypto.ETH.addresso") { result in
                switch result {
                case .success(let returnValue):
                    addrExp.fulfill();
                    addr = returnValue;
                case .failure(let error):
                    XCTFail("Expected eth address, but got \(error)");
            }
        }

        // key is incorrect so this method should throw record not found
        resolution.addr(domain: "udtestdev-matic-mainnet-test.crypto", ticker: "ETH") {
            recordNotFoundResult = $0;
            recordNotFoundExp.fulfill();
        }

        resolution.owner(domain: "udtestdev-matic-mainnet-test.crypto") { result in
                switch result {
                case .success(let returnValue):
                    ownerExp.fulfill();
                    owner = returnValue
                case .failure(let error):
                    XCTFail("Expected owner address, but got \(error)");
            }
        }

        resolution.resolver(domain: "udtestdev-matic-mainnet-test.crypto") { result in
                switch result {
                case .success(let returnValue):
                    resolverExp.fulfill();
                    resolver = returnValue
                case .failure(let error):
                    XCTFail("Expected owner address, but got \(error)");
            }
        }

        resolution.locations(domains: ["udtestdev-matic-mainnet-test.crypto"]) { result in
                switch result {
                case .success(let returnValue):
                    locationExp.fulfill();
                    assert(returnValue.count == 1);
                    loc = returnValue["udtestdev-matic-mainnet-test.crypto"]!;
                case .failure(let error):
                    XCTFail("Expected location obj, but got \(error)");
            }
        }

        waitForExpectations(timeout: 200, handler: nil);

        assert(addr == "0xc2cc046e7f4f7a3e9715a853fc54907c12364b6b");
        assert(resolver == "0xa9a6A3626993D487d2Dbda3173cf58cA1a9D9e9f");
        assert(owner == "0xc2cC046e7F4f7A3e9715A853Fc54907c12364b6B");
        assert(loc == Location(
            registryAddress: "0xa9a6a3626993d487d2dbda3173cf58ca1a9d9e9f",
            resolverAddress: "0xa9a6A3626993D487d2Dbda3173cf58cA1a9D9e9f",
            networkId: "137",
            blockchain: "MATIC",
            owner: "0xc2cC046e7F4f7A3e9715A853Fc54907c12364b6B",
            providerURL: "https://polygon-mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817"))
        TestHelpers.checkError(result: recordNotFoundResult, expectedError: ResolutionError.recordNotFound("layer 2"))
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
            assert( lowercasedOwners[layer2Domain] == "0x499dD6D875787869670900a2130223D85d4F6Aa7".lowercased() )
            assert( lowercasedOwners[unregisteredDomain]! == nil )

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }

        let lowercasedOwners = owners.mapValues{ $0?.lowercased() }
        assert( lowercasedOwners[layer2Domain] == "0x499dD6D875787869670900a2130223D85d4F6Aa7".lowercased() )
        assert( lowercasedOwners[layer1Domain] == "0xe586d5Bf4d7779498648DF67b73c88a712E4359d".lowercased() )
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
        resolution.addr(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN), ticker: "eth") { (result) in
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
        assert(layer2EthAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        assert(layer1EthAddress == "0x084Ac37CDEfE1d3b68a63c08B203EFc3ccAB9742");
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
        resolution.record(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN), key: "custom.record") { (result) in
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
        resolution.records(domain: TestHelpers.getTestDomain(.WALLET_DOMAIN), keys: recordKeys) { result in
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
        assert(layer2Records["crypto.ETH.address"] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8");
        assert(layer2Records["custom.record"] == "custom.value");
        assert(layer2Records["weirdrecord"] == "");
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

        assert(layer1TokenUri == "https://metadata.ud-staging.com/metadata/reseller-test-udtesting-459239285.crypto");
        assert(layer2TokenUri == "https://metadata.ud-staging.com/metadata/29206072489201256414040015626327292653094949751666860355749665089956336890808");
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

    func testReverseTokenId() {
        // Given
        let reverseReceived = expectation(description: "Reverse resolution should be received");
        let reverseL2Received = expectation(description: "Reverse resolution should be received with explicit layer");
        let reverseDoesntExistReceived = expectation(description: "Error should be received for not existing reverse resolution");

        let reverseAddress = "0xd92d2a749424a5181ad7d45f786a9ffe46c10a7c"
        let reverseDoesntExist = "0x0000000000000000000000000000000000000001"

        var reverseResult = ""
        var reverseL2Result = ""
        var reverseDoesntExistResult: Result<String, ResolutionError>!

        // When
        resolution.reverseTokenId(address: reverseAddress, location: nil) { (result) in
            switch result {
            case .success(let returnValue):
                reverseReceived.fulfill()
                reverseResult = returnValue
            case .failure(let error):
                XCTFail("Expected reverse resolution, but got \(error)")
            }
        }

        resolution.reverseTokenId(address: reverseAddress, location: .layer2) { (result) in
            switch result {
            case .success(let returnValue):
                reverseL2Received.fulfill();
                reverseL2Result = returnValue;
            case .failure(let error):
                XCTFail("Expected reverse resolution from layer2, but got \(error)")
            }
        }

        resolution.reverseTokenId(address: reverseDoesntExist, location: nil) {
            reverseDoesntExistResult = $0
            reverseDoesntExistReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(reverseResult == "0x0df03d18a0a02673661da22d06f43801a986840e5812989139f0f7a2c41037c2")
        assert(reverseL2Result == "0x0df03d18a0a02673661da22d06f43801a986840e5812989139f0f7a2c41037c2")
        TestHelpers.checkError(result: reverseDoesntExistResult, expectedError: ResolutionError.reverseResolutionNotSpecified)
    }

    func testReverse() {
        // Given
        let reverseReceived = expectation(description: "Reverse resolution should be received");
        let reverseL2Received = expectation(description: "Reverse resolution should be received with explicit layer");
        let reverseDoesntExistReceived = expectation(description: "Error should be received for not existing reverse resolution");

        let reverseAddress = "0xd92d2a749424a5181ad7d45f786a9ffe46c10a7c"
        let reverseDoesntExist = "0x0000000000000000000000000000000000000001"

        var reverseResult = ""
        var reverseL2Result = ""
        var reverseDoesntExistResult: Result<String, ResolutionError>!

        // When
        resolution.reverse(address: reverseAddress, location: nil) { (result) in
            switch result {
            case .success(let returnValue):
                reverseReceived.fulfill()
                reverseResult = returnValue
            case .failure(let error):
                XCTFail("Expected reverse resolution, but got \(error)")
            }
        }

        resolution.reverse(address: reverseAddress, location: .layer2) { (result) in
            switch result {
            case .success(let returnValue):
                reverseL2Received.fulfill();
                reverseL2Result = returnValue;
            case .failure(let error):
                XCTFail("Expected reverse resolution from layer2, but got \(error)")
            }
        }

        resolution.reverse(address: reverseDoesntExist, location: nil) {
            reverseDoesntExistResult = $0
            reverseDoesntExistReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(reverseResult == "uns-devtest-265f8f.wallet")
        assert(reverseL2Result == "uns-devtest-265f8f.wallet")
        TestHelpers.checkError(result: reverseDoesntExistResult, expectedError: ResolutionError.reverseResolutionNotSpecified)
    }
}
