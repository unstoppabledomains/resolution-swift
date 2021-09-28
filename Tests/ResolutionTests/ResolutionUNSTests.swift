//
//  UnsLayerTest.swift
//  ResolutionTests
//
//  Created by Johnny Good on 9/21/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import XCTest

#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

class ResolutionUNSTests: XCTestCase {

    var resolution: Resolution!;
    let timeout: TimeInterval = 30
    
    override func setUp() {
        resolution = try! Resolution(
            configs: Configurations(
                uns: UnsLocations(
                    layer1: NamingServiceConfig(
                                providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
                                network: "rinkeby"),
                    layer2: NamingServiceConfig(
                                providerUrl: "https://matic-testnet-archive-rpc.bwarelabs.com",
                                network: "polygon-mumbai")
                ),
                zns: NamingServiceConfig(
                    providerUrl: "https://dev-api.zilliqa.com",
                    network: "testnet")
            )
        );
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
    
    
    func testGetBatchOwner() throws {
        let layer2Domain: String = TestHelpers.getTestDomain(.LAYER2_DOMAIN);
        let layer1Domain: String = TestHelpers.getTestDomain(.DOMAIN);
        let unregisteredDomain: String = TestHelpers.getTestDomain(.UNREGISTERED_DOMAIN);
        
        // Given
        let domainCryptoReceived = expectation(description: "Existing Crypto domains' owners should be received")
        let particalResultReceived = expectation(description: "An existing domain and non-existing domain should result in mized response ")

        var owners: [String?] = []
        var partialResult: Result<[String?], ResolutionError>!

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
    
    func testAddr() throws {
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
        TestHelpers.checkError(result: noRecordResult, expectedError: ResolutionError.recordNotFound);
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
        TestHelpers.checkError(result: noRecordResut, expectedError: ResolutionError.recordNotFound);
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
    
    func testTokenUri() throws {
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
        // TODO uncomment once L2 contract starts to return the metadata url.
//        assert(layer2TokenUri == "https://metadata.staging.unstoppabledomains.com/metadata/udtestdev-johnnytest.wallet");
    }
    
    func testUnhash() throws {
        
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
