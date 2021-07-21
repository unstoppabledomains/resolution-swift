import XCTest

import ResolutionTests

var tests = [XCTestCaseEntry]()
tests += ResolutionTests.allTests()
tests += EthereumABITests.allTests()
tests += TokenUriMetadataTests.allTests()
tests += ABICoderTests.allTests()
XCTMain(tests)
