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
        resolution = try! Resolution();
    }
    
    func testOldConstructor() throws {
        // old constructor assumed providerUrl would be the same for cns
        // using this key cause it is not limitted by contract whitelist.
        resolution = try Resolution(providerUrl: "https://mainnet.infura.io/v3/d423cf2499584d7fbe171e33b42cfbee", network: "mainnet");
        try testAddr();
    }
    
    func testNetworkFromUrl() throws {
        resolution = try Resolution(configs: Configurations(
            cns: NamingServiceConfig(providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817")
            )
        );
        
        let cnsNetwork = try resolution.getNetwork(from: "cns");
        let znsNetwork = try resolution.getNetwork(from: "zns");
        assert(cnsNetwork == "rinkeby");
        assert(znsNetwork == "mainnet");
    }
    
    func testUnsupportedNetwork() throws {
        self.checkError(completion: {
            try Resolution(configs: Configurations(
                cns: NamingServiceConfig(providerUrl: "https://ropsten.infura.io/v3/3c25f57353234b1b853e9861050f4817")
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
                cns: NamingServiceConfig(
                    providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                    network: "rinkeby"
                )
            )
        );
        let domainReceived = expectation(description: "Exist domain should be received")
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
        waitForExpectations(timeout: timeout, handler: nil)
        assert(ethAddress == "0x1C8b9B78e3085866521FE206fa4c1a67F49f153A")
    }
    
    func testZilliqaTestNet() throws {
        resolution = try Resolution(configs: Configurations(
                zns: NamingServiceConfig(
                    providerUrl: "https://dev-api.zilliqa.com",
                    network: "testnet"
                )
            )
        );
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
        assert(false == resolution.isSupported(domain: "notsupported.crypto1"))
        assert(true == resolution.isSupported(domain: "supported.crypto"))
        assert(true == resolution.isSupported(domain: "supported.zil"))
        assert(false == resolution.isSupported(domain: "notsupported.eth1"))
        assert(false == resolution.isSupported(domain: "supported.eth"))
        assert(false == resolution.isSupported(domain: "notsupported.xyz1"))
        assert(false == resolution.isSupported(domain: "supported.xyz"))
        assert(false == resolution.isSupported(domain: "notsupported.luxe1"))
        assert(false == resolution.isSupported(domain: "supported.luxe"))
        assert(false == resolution.isSupported(domain: "-notsupported.eth"))
        assert(false == resolution.isSupported(domain: "supported.kred"))
        assert(false == resolution.isSupported(domain: "supported.addr.reverse"))
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
    
    func testDns() throws {
        
        // Given
        let domain: String = "udtestdev-reseller-test-udtesting-875948372642.crypto";
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
        let domain: String = "udtestdev-usdt.crypto";
        
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
        resolution.multiChainAddress(domain: "brad.crypto", ticker: "usdt", chain: "erc20") {
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
    
    // TODO: remove this in 1.0.0
    func testUsdtVersion() throws {
        // Given
        let domain: String = "udtestdev-usdt.crypto";
        
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
        resolution.usdt(domain: "brad.crypto", version: .ERC20) {
            NoRecordResult = $0
            NoRecordReceived.fulfill()
        }
        
        resolution.usdt(domain: domain, version: .ERC20) { (result) in
            switch result {
            case .success(let returnValue):
                erc20Received.fulfill();
                erc20 = returnValue;
            case .failure(let error):
                XCTFail("Expected erc20 usdt address, but got \(error)")
            }
        }

        resolution.usdt(domain: domain, version: .EOS) { (result) in
            switch result {
            case .success(let returnValue):
                eosReceived.fulfill();
                eos = returnValue;
            case .failure(let error):
                XCTFail("Expected eos usdt address, but got \(error)")
            }
        }

        resolution.usdt(domain: domain, version: .TRON) { (result) in
            switch result {
            case .success(let returnValue):
                tronReceived.fulfill();
                tron = returnValue;
            case .failure(let error):
                XCTFail("Expected tron usdt address, but got \(error)")
            }
        }

        resolution.usdt(domain: domain, version: .OMNI) { (result) in
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
        assert(owner.lowercased() == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased())
        assert(zilOwner.lowercased() == "0x2d418942dce1afa02d0733a2000c71b371a6ac07".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
    }
    
    func testGetBatchOwner() throws {
        
        // Given
        let domainCryptoReceived = expectation(description: "Existing Crypto domains' owners should be received")
        let particalResultReceived = expectation(description: "An existing domain and non-existing domain should result in mized response ")

        var owners: [String?] = []
        var partialResult: Result<[String?], ResolutionError>!

        // When
        resolution.batchOwners(domains: ["brad.crypto", "unstoppablecaribou.crypto"]) { (result) in
            switch result {
            case .success(let returnValue):
                owners = returnValue
                domainCryptoReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected owners, but got \(error)")
            }
        }
        
        resolution.batchOwners(domains: ["brad.crypto", "unregistered.crypto"]) {
            partialResult = $0
            particalResultReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        switch partialResult {
        case .success(let array):
            let lowercasedOwners = array.map( {$0?.lowercased()} )
            assert( lowercasedOwners[0] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased() )
            assert( lowercasedOwners[1] == nil )

        case .failure(let error):
            XCTFail("Expected owners, but got \(error)")
        case .none:
            XCTFail("Expected owners, but got .none")
        }
        
        let lowercasedOwners = owners.compactMap({$0}).map{$0.lowercased()}
        assert( lowercasedOwners[0] == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8".lowercased() )
        assert( lowercasedOwners[1] == "0x53E238E686BeFF9853b2d8ede1D6B3067A921AAa".lowercased() )
    }
    
    func testGetResolver() throws {
        // Given
        let domainCryptoReceived = expectation(description: "Exist Crypto domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var resolverAddress = ""
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

        resolution.resolver(domain: "unregistered.crypto") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(resolverAddress.lowercased() == "0xb66DcE2DA6afAAa98F2013446dBCB0f4B0ab2842".lowercased())
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unspecifiedResolver)
    }

    func testAddr() throws {
        // Given
        let domainReceived = expectation(description: "Exist domain should be received")
        let domainZilReceived = expectation(description: "Exist ETH domain should be received")
        let unregisteredReceived = expectation(description: "Unregistered domain should be received")

        var ethAddress = ""
        var zilENSAddress = ""
        var unregisteredResult: Result<String, ResolutionError>!

        // When
        resolution.addr(domain: "brad.crypto", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                ethAddress = returnValue
                domainReceived.fulfill()
            case .failure(let error):
                XCTFail("Expected Eth Address, but got \(error)")
            }
        }
        
        resolution.addr(domain: "brad.zil", ticker: "eth") { (result) in
            switch result {
            case .success(let returnValue):
                domainZilReceived.fulfill()
                zilENSAddress = returnValue
            case .failure(let error):
                XCTFail("Expected owner, but got \(error)")
            }
        }
        
        resolution.addr(domain: "brad.crypto", ticker: "unknown") {
            unregisteredResult = $0
            unregisteredReceived.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)

        // Then
        assert(ethAddress == "0x8aaD44321A86b170879d7A244c1e8d360c99DdA8")
        assert(zilENSAddress == "0x45b31e01AA6f42F0549aD482BE81635ED3149abb")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.recordNotFound)
    }

    func testChatID() throws {
        // Given
        let chatReceived = expectation(description: "Exist chat ID should be received")
        var chatID = ""

        // When
        resolution.chatId(domain: "brad.crypto")  { (result) in
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
        resolution.ipfsHash(domain: "brad.crypto") { result in
            switch result {
            case .success(let returnValue):
                hash = returnValue
                domainReceived.fulfill()
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
        assert(hash == "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb")
        self.checkError(result: unregisteredResult, expectedError: ResolutionError.unregisteredDomain)
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
        assert(ipfshash == "QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb")
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
