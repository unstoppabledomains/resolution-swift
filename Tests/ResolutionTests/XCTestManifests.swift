import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ResolutionTests.allTests),
        testCase(EthereumABITests.allTests),
        testCase(TokenUriMetadataTests.allTests)
        testCase(ABICoderTests.allTests)
    ]
}
#endif
