import XCTest

import resolutionTests

var tests = [XCTestCaseEntry]()
tests += resolutionTests.allTests()
XCTMain(tests)
