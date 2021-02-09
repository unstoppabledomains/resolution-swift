import XCTest

import ResolutionTests

var tests = [XCTestCaseEntry]()
tests += ResolutionTests.allTests()
tests += EthereumABITests.allTests()
XCTMain(tests)
