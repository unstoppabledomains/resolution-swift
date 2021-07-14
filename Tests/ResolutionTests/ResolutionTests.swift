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

    static let TEST_DOMAIN: String = "udtestdev-265f8f.crypto"
    static let TEST_DOMAIN2: String = "johnnytestdev6357.crypto"
    static let TEST_DOMAIN3: String = "brad.crypto"
    static let TEST_WALLET_DOMAIN: String = "udtestdev-johnnywallet.wallet"
    static let TEST_COIN_DOMAIN: String = "udtestdev-johnnycoin.coin"
    static let UNREGISTERED_DOMAIN: String = "unregistered.crypto"
    
    let timeout: TimeInterval = 30
    override func setUp() {
        super.setUp()
        resolution = try! Resolution(
            configs: Configurations(
                uns: NamingServiceConfig(
                    providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                    network: "rinkeby"),
                zns: NamingServiceConfig(
                    providerUrl: "https://dev-api.zilliqa.com",
                    network: "testnet")
            )
        );
    }
    
    func testNetworkFromUrl() throws {
        resolution = try Resolution(configs: Configurations(
            uns: NamingServiceConfig(providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817"),
            ens: NamingServiceConfig(providerUrl: "https://ropsten.infura.io/v3/3c25f57353234b1b853e9861050f4817")
            )
        );
        
        let unsNetwork = try resolution.getNetwork(from: "uns");
        let znsNetwork = try resolution.getNetwork(from: "zns");
        let ensNetwork = try resolution.getNetwork(from: "ens");
        assert(unsNetwork == "rinkeby");
        assert(ensNetwork == "ropsten");
        assert(znsNetwork == "mainnet");
    }
    
    func testUnsupportedNetwork() throws {
        self.checkError(completion: {
            try Resolution(configs: Configurations(
                uns: NamingServiceConfig(providerUrl: "https://ropsten.infura.io/v3/3c25f57353234b1b853e9861050f4817")
            ));
        }, expectedError: .unsupportedNetwork)
        
        self.checkError(completion: {
            try Resolution(configs: Configurations(
                ens: NamingServiceConfig(providerUrl: "https://kovan.infura.io/v3/3c25f57353234b1b853e9861050f4817")
            ));
        }, expectedError: .unsupportedNetwork)
    }
    
    func testForUnregisteredDomain() throws {
        let UnregirestedDomainExpectation = expectation(description: "Domain should not be registered!")
        var NoRecordResult: Result<String, ResolutionError>!
        resolution.addr(domain: "unregistered.crypto", ticker: "eth") {
            NoRecordResult = $0
            UnregirestedDomainExpectation.fulfill();
        }
        waitForExpectations(timeout: timeout, handler: nil)
        self.checkError(result: NoRecordResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testForUnspecifiedResolver() throws {
        let UnregirestedDomainExpectation = expectation(description: "Domain should not have a Resolver!")
        var NoRecordResult: Result<String, ResolutionError>!
        resolution.addr(domain: "twistedmusic.crypto", ticker: "eth") {
            NoRecordResult = $0
            UnregirestedDomainExpectation.fulfill();
        }
        waitForExpectations(timeout: timeout, handler: nil)
        self.checkError(result: NoRecordResult, expectedError: ResolutionError.unspecifiedResolver)
    }
    
    func testRinkeby() throws {
        resolution = try Resolution(configs: Configurations(
                uns: NamingServiceConfig(
                    providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                    network: "rinkeby"
                )
            )
        );
        let domainReceived = expectation(description: "Exist domain should be received")
        let ownerReceived = expectation(description: "Exist domain should be received")
        var ethAddress = ""
        resolution.addr(domain: "udtestdev-creek.crypto", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        resolution.owner(domain: "udtestdev-creek.crypto") { (result) in
            switch result {
            case .success(let returnValue):
                print(returnValue)
                ownerReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        waitForExpectations(timeout: timeout, handler: nil)
        Swift.assert(ethAddress == "0x1C8b9B78e3085866521FE206fa4c1a67F49f153A")
    }
    
    func testZilliqaTestNet() throws {
        let domainReceived = expectation(description: "Exist domain should be received")
        var zilOwner = ""
        resolution.owner(domain: "test-udtesting-654.zil") { (result) in
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
        // Given // When // Then
        resolution = try Resolution(configs: Configurations(
            uns: NamingServiceConfig(
                providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                network: "rinkeby"
            ),
            zns: NamingServiceConfig(
                providerUrl: "https://dev-api.zilliqa.com",
                network: "testnet"
            )
        ));
        
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
        resolution.addr(domain: ResolutionTests.TEST_WALLET_DOMAIN, ticker: "eth") { (result) in
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
        resolution.addr(domain: ResolutionTests.TEST_COIN_DOMAIN, ticker: "eth") { (result) in
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
        let domain: String = ResolutionTests.TEST_DOMAIN;
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
        let domain: String = ResolutionTests.TEST_DOMAIN;
        
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
        resolution.multiChainAddress(domain: ResolutionTests.TEST_DOMAIN3, ticker: "usdt", chain: "erc20") {
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

        resolution.multiChainAddress(domain: domain, ticker: "usdt", chain: "eos") { (result) in
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

        resolution.multiChainAddress(domain: domain, ticker: "usdt", chain: "omni") { (result) in
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
        self.checkError(result: NoRecordResult, expectedError: ResolutionError.recordNotFound)
    }

    func testGetOwner() throws {

        let CNSDomain = ResolutionTests.TEST_DOMAIN;
        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let domainEthReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var owner = ""
        var ethOwner = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.owner(domain: CNSDomain) { (result) in
            switch result {
            case .success(let returnValue):
                domainCryptoReceived.fulfill()
                owner = returnValue
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
        assert(owner.lowercased() == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased())
        assert(ethOwner.lowercased() == "0x714ef33943d925731fbb89c99af5780d888bd106".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testGetBatchOwner() throws {
        
        // Given
        let domainCryptoReceived = expectation(description: "Existing Crypto domains' owners should be received")
        let particalResultReceived = expectation(description: "An existing domain and non-existing domain should result in mized response ")

        var owners: [String?] = []
        var partialResult: Result<[String?], ResolutionError>!

        // When
        resolution.batchOwners(domains: [ResolutionTests.TEST_DOMAIN, ResolutionTests.TEST_DOMAIN2]) { (result) in
            switch result {
            case .success(let returnValue):
                owners = returnValue
                domainCryptoReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected owners, but got \(error)")
            }
        }
        
        resolution.batchOwners(domains: [ResolutionTests.TEST_DOMAIN, ResolutionTests.UNREGISTERED_DOMAIN]) {
            partialResult = $0
            particalResultReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        switch partialResult {
        case .success(let array):
            let lowercasedOwners = array.map( {$0?.lowercased()} )
            assert( lowercasedOwners[0] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
            assert( lowercasedOwners[1] == nil )

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }
        
        let lowercasedOwners = owners.compactMap({$0}).map{$0.lowercased()}
        assert( lowercasedOwners[0] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
        assert( lowercasedOwners[1] == "0xe7474D07fD2FA286e7e0aa23cd107F8379085037".lowercased() )
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
        resolution.resolver(domain: ResolutionTests.TEST_DOMAIN) { (result) in
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

        resolution.resolver(domain: ResolutionTests.UNREGISTERED_DOMAIN) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then

        assert(resolverAddress.lowercased() == "0x95AE1515367aa64C462c71e87157771165B1287A".lowercased())
        assert(ethResolverAddress.lowercased() == "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unspecifiedResolver)
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
        resolution.addr(domain: ResolutionTests.TEST_DOMAIN, ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }

        resolution.addr(domain: "monkybrain.eth", ticker: "eth") { (result) in
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

        resolution.addr(domain: ResolutionTests.TEST_DOMAIN, ticker: "unknown") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
//        assert(zilENSAddress == "0x45b31e01AA6f42F0549aD482BE81635ED3149abb")
        assert(ethENSAddress == "0x842f373409191Cff2988A6F19AB9f605308eE462")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testChatID() throws {
        // Given
        let chatReceived = expectation(description: "Exist chat ID should be received")
        var chatID = ""

        // When

        resolution.chatId(domain: ResolutionTests.TEST_DOMAIN)  { (result) in
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
    
    func testForTokensOwnedByCns() throws {
        let tokenReceived = expectation(description: "tokens for 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8 address should be received");
        var returnedDomains: [String] = [];
        resolution.tokensOwnedBy(address: "0xe7474D07fD2FA286e7e0aa23cd107F8379085037", service: "uns") { (result) in
            switch result {
            case .success(let returnValue):
                returnedDomains = returnValue.compactMap{ $0 }
                tokenReceived.fulfill()
            case .failure(let error):
                XCTFail("something went wrong \(error)")
            }

        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(returnedDomains.count >= 3)
        assert(returnedDomains.contains("johnnytestdev6357.crypto"))
        assert(returnedDomains.contains("johnnydevtest6357.crypto"))
        assert(returnedDomains.contains("udtestdev-265f8f.crypto"))
    }
    
    func testForTokensOwnedByCnsFromRinkeby() throws {
        let tetReceived = expectation(description: "This is just for test");
        let resolutionB = try Resolution(configs: Configurations(
            uns: NamingServiceConfig(
                providerUrl: "https://rinkeby.infura.io/v3/e05c36b6b2134ccc9f2594ddff94c136",
                network: "rinkeby"
            )))
        var returnedDomains: [String] = [];
        resolutionB.tokensOwnedBy(address: "0x6EC0DEeD30605Bcd19342f3c30201DB263291589", service: "uns") { (result) in
            switch result {
            case .success(let returnValue):
                returnedDomains = returnValue.compactMap{ $0 }
                tetReceived.fulfill()
            case .failure(let error):
                XCTFail("something went wrong \(error)")
            }

        }
        waitForExpectations(timeout: timeout, handler: nil)
        assert(returnedDomains.count == 5)
        assert(returnedDomains.contains("udtestdev-creek.crypto"))
        assert(returnedDomains.contains("udtestdev-my-new-tls.wallet"))
        assert(returnedDomains.contains("reseller-test-udtesting-630444001358.crypto"))
        assert(returnedDomains.contains("test-test-test-test.crypto"))
        assert(returnedDomains.contains("reseller-test-udtesting-483809515990.crypto"))
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
        resolution.ipfsHash(domain: ResolutionTests.TEST_DOMAIN) { result in
            switch result {
            case .success(let returnValue):
                hash = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }

        resolution.ipfsHash(domain: "monkybrain.eth") { (result) in
            switch result {
            case .success(let returnValue):
                etcHash = returnValue
                domainEthReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected ipfsHash, but got \(error)")
            }
        }
        
        resolution.ipfsHash(domain: ResolutionTests.UNREGISTERED_DOMAIN) { result in
            unregisteredResult = result
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(hash == "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb")
        assert(etcHash == "QmXSBLw6VMegqkCHSDBPg7xzfLhUyuRBzTb927KVzKC1vq")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testCustomRecord() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var customRecord = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.record(domain: ResolutionTests.TEST_DOMAIN, key: "custom.record") { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                customRecord = returnValue
            case .failure(let error):
                XCTFail("Expected custom record, but got \(error)")
            }
        }

        resolution.record(domain: ResolutionTests.TEST_DOMAIN, key: "unknown.value") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(customRecord == "custom.value")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testTokenUri() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var tokenURI = ""
        var unregisteredResult: Result<String, ResolutionError>!
        
        // When
        resolution.tokenURI(domain: ResolutionTests.TEST_DOMAIN3) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                tokenURI = returnValue
            case .failure(let error):
                XCTFail("Expected tokenURI, but got \(error)")
            }
        }
        resolution.tokenURI(domain: ResolutionTests.UNREGISTERED_DOMAIN) {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(tokenURI == "https://staging-dot-dot-crypto-metadata.appspot.com/metadata/brad.crypto")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testTokenUriMetadata() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var tokenURIMetadata: TokenUriMetadata? = nil
        var unregisteredResult: Result<TokenUriMetadata, ResolutionError>!

        // When
        resolution.tokenURIMetadata(domain: ResolutionTests.TEST_DOMAIN3) { (result) in
            switch result {
            case .success(let returnValue):
                domainReceived.fulfill()
                tokenURIMetadata = returnValue
            case .failure(let error):
                XCTFail("Expected tokenURIMetadata, but got \(error)")
            }
        }
        resolution.tokenURIMetadata(domain: "afakedomainthatdoesnotexist-test-20210616.crypto") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(tokenURIMetadata?.name == ResolutionTests.TEST_DOMAIN3)
        assert(tokenURIMetadata?.attributes.count == 8)
        assert(self.checkAttributeArrayContains(array: tokenURIMetadata?.attributes ?? [], traitType: "ETH", value: "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8"))

        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func checkAttributeArrayContains(array: [TokenUriMetadataAttribute], traitType: String, value: String) -> Bool {
        for attr in array {
            if attr.traitType == traitType && attr.value.value == value {
                return true
            }
        }
        return false
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
        assert(domainName == ResolutionTests.TEST_DOMAIN3)
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }

    func testGetMany() throws {

        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let keys = ["ipfs.html.value", "crypto.BTC.address", "crypto.ETH.address", "someweirdstuf"]
        let domain = ResolutionTests.TEST_DOMAIN3
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
    
    func checkError(result: Result<[String?], ResolutionError>, expectedError: ResolutionError) {
        switch result {
        case .success:
            XCTFail("Expected \(expectedError), but got none")
        case .failure(let error):
            assert(error == expectedError, "Expected \(expectedError), but got \(error)")
            return
        }
    }

    func checkError(result: Result<TokenUriMetadata, ResolutionError>, expectedError: ResolutionError) {
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
        case (.inconsistenDomainArray, .inconsistenDomainArray):
            return true
        case (.methodNotSupported, .methodNotSupported):
            return true
        case (.tooManyResponses, .tooManyResponses):
            return true
        case (.badRequestOrResponse, .badRequestOrResponse):
            return true
        case (.unsupportedServiceName, .unsupportedServiceName):
            return true
            
        case (.unregisteredDomain, _),
             (.unsupportedDomain, _),
             (.recordNotFound, _),
             (.recordNotSupported, _),
             (.unsupportedNetwork, _),
             (.unspecifiedResolver, _),
             (.unknownError, _ ),
             (.inconsistenDomainArray, _),
             (.methodNotSupported, _),
             (.proxyReaderNonInitialized, _),
             (.tooManyResponses, _),
             (.badRequestOrResponse, _),
             (.unsupportedServiceName, _):
            
            return false
        // Xcode with Version 12.4 (12D4e) can't compile this without default
        // throws error: The compiler is unable to check that this switch is exhaustive in a reasonable time
        default:
            return false
        }
    }
}
