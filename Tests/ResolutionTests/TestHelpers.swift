//
//  TestHelpers.swift
//  resolution
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

class TestHelpers {


    enum DOMAINS {
        case DOMAIN
        case WALLET_DOMAIN
        case UNNORMALIZED_DOMAIN
        case DOMAIN2
        case DOMAIN3
        case UNREGISTERED_DOMAIN
        case UNREGISTERED_ZIL
        case ZIL_DOMAIN
        case LAYER2_DOMAIN
    }

    static let TEST_DOMAINS: [DOMAINS: String] = [
        .DOMAIN: "reseller-test-udtesting-459239285.crypto",
        .WALLET_DOMAIN: "uns-devtest-265f8f.wallet",
        .UNNORMALIZED_DOMAIN: "    uns-dEVtest-265f8f.wallet    ",
        .DOMAIN2: "cryptoalpaca9798.blockchain",
        .DOMAIN3: "uns-devtest-3b1663.x",
        .UNREGISTERED_DOMAIN: "unregistered.crypto",
        .UNREGISTERED_ZIL: "unregistered.zil",
        .ZIL_DOMAIN: "test-udtesting-654.zil",
        .LAYER2_DOMAIN: "udtestdev-test-l2-domain-784391.wallet"

    ]

    static func getTestDomain(_ type: DOMAINS) -> String {
        return Self.TEST_DOMAINS[type]!;
    }

    static func checkError(completion: @escaping() throws -> Void, expectedError: ResolutionError) {
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

    static func checkError<T>(result: Result<T, ResolutionError>, expectedError: ResolutionError) {
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
        case (.inconsistentDomainArray, .inconsistentDomainArray):
            return true
        case (.methodNotSupported, .methodNotSupported):
            return true
        case (.tooManyResponses, .tooManyResponses):
            return true
        case (.badRequestOrResponse, .badRequestOrResponse):
            return true
        case (.unsupportedServiceName, .unsupportedServiceName):
            return true
        case (.registryAddressIsNotProvided, .registryAddressIsNotProvided):
            return true
        case (.invalidDomainName, .invalidDomainName):
            return true
        case (.reverseResolutionNotSpecified, .reverseResolutionNotSpecified):
            return true

        case (.unregisteredDomain, _),
             (.unsupportedDomain, _),
             (.recordNotFound, _),
             (.recordNotSupported, _),
             (.unsupportedNetwork, _),
             (.unspecifiedResolver, _),
             (.unknownError, _ ),
             (.inconsistentDomainArray, _),
             (.methodNotSupported, _),
             (.proxyReaderNonInitialized, _),
             (.tooManyResponses, _),
             (.badRequestOrResponse, _),
             (.unsupportedServiceName, _),
             (.registryAddressIsNotProvided, _),
             (.invalidDomainName, _):

            return false
        // Xcode with Version 12.4 (12D4e) can't compile this without default
        // throws error: The compiler is unable to check that this switch is exhaustive in a reasonable time
        default:
            return false
        }
    }
}
