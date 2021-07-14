import XCTest

#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

var coder: ABICoder!

class ABICoderTests: XCTestCase {
    let abiJsonString: String = "[{\"inputs\": [{ \"indexed\": true, \"internalType\": \"uint256\","
        + "\"name\": \"id\", \"type\": \"uint256\" },{ \"indexed\": false,"
        + "\"internalType\": \"string\", \"name\": \"value\", \"type\": \"string\" }],"
        + "\"name\": \"testEvent\", \"type\": \"event\" },{ \"inputs\": ["
        + "  { \"internalType\": \"uint256\", \"name\": \"valueId\", \"type\": \"uint256\" } ],"
        + "\"name\": \"getValue\", \"outputs\": ["
        + "  { \"internalType\": \"string\", \"name\": \"value\", \"type\": \"string\" } ],"
        + "\"stateMutability\": \"view\", \"payable\": false,  \"type\": \"function\" }]"

    override func setUp() {
        super.setUp()
        do {
            let jsonData = abiJsonString.data(using: .utf8)
            let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })
            coder = ABICoder(abiNative)
        } catch {
            XCTFail("Unexpected error during setup")
        }
    }

    func testFunctionParametersEncoding() throws
    {
        let data = try coder.encode(method: "getValue", args: ["0000000000000000000000000000000000000000000000000000000000000001"])
        let expected = "0x0ff4c9160000000000000000000000000000000000000000000000000000000000000001"
        XCTAssert(data.lowercased() == expected, "failed to encode")
    }
    
    func testFunctionParametersEncodingInvalidMethod()
    {
        self.checkError(completion: {
            _ = try coder.encode(method: "invalid", args: ["0000000000000000000000000000000000000000000000000000000000000001"])
        }, expectedError: .wrongABIInterfaceForMethod(method: "invalid"))
    }
    
    func testFunctionParametersEncodingInvalidArgs()
    {
        self.checkError(completion: {
            _ = try coder.encode(method: "getValue", args: ["invalid"])
        }, expectedError: .couldNotEncode(method: "getValue", args: ["invalid"]))
    }

    func testFunctionReturnDecoding() throws
    {
        let dataString = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000117465737420737472696e672076616c7565000000000000000000000000000000"
        let result = try coder.decode(dataString, from: "getValue")
        let expected = "test string value"
        let dict = result as? Dictionary<String, Any>
        XCTAssert(dict != nil, "failed to decode")
        let val = dict?["0"] as? String
        XCTAssert(val == expected, "failed to decode")
    }

    func testFunctionReturnDecodingEmptyString() throws
    {
        let dataString = ""
        let result = try coder.decode(dataString, from: "getValue")
        let dict = result as? Dictionary<String, Any>
        XCTAssert(dict != nil, "failed to decode")
        let val = dict?["0"] as? String
        XCTAssert(val == "", "failed to decode")
    }
    
    func testFunctionReturnDecodingInvalidMethod() throws
    {
        let dataString = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000117465737420737472696e672076616c7565000000000000000000000000000000"
        self.checkError(completion: {
            _ = try coder.decode(dataString, from: "invalid")
        }, expectedError: .wrongABIInterfaceForMethod(method: "invalid"))
    }
    
    func testFunctionReturnDecodingNotFunction() throws
    {
        let dataString = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000117465737420737472696e672076616c7565000000000000000000000000000000"
        self.checkError(completion: {
            _ = try coder.decode(dataString, from: "testEvent")
        }, expectedError: .wrongABIInterfaceForMethod(method: "testEvent"))
    }
    
    func testFunctionReturnDecodingInvalidData() throws
    {
        let dataString = "0x01"
        self.checkError(completion: {
            _ = try coder.decode(dataString, from: "getValue")
        }, expectedError: .couldNotDecode(method: "getValue", value: dataString))
    }

    func checkError(completion: @escaping() throws -> Void, expectedError: ABICoderError) {
        do {
            try completion()
            XCTFail("Expected \(expectedError), but got none")
        } catch {
            if let catched = error as? ABICoderError {
                assert(catched == expectedError, "Expected \(expectedError), but got \(catched)")
                return
            }
            XCTFail("Expected ABICoderError, but got different \(error)")
        }
    }
}

extension ABICoderError {
    static func ==(a: ABICoderError, b: ABICoderError) -> Bool {
        switch (a, b) {
            case (.wrongABIInterfaceForMethod(let a), .wrongABIInterfaceForMethod(let b)) where a == b: return true
            case (.couldNotEncode(let a, _), .couldNotEncode(let b, _)) where a == b: return true
            case (.couldNotDecode(let a, let aValue), .couldNotDecode(let b, let bValue)) where a == b && aValue == bValue: return true
            default: return false
        }
    }
}