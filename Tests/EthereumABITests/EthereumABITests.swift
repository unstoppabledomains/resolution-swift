import XCTest
import BigInt
import EthereumAddress

#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

class EthereumABITests: XCTestCase {

    func testRealABI() {
        let jsonString = "[{\"constant\":true,\"inputs\":[],\"name\":\"getUsers\",\"outputs\":[{\"name\":\"\",\"type\":\"address[]\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"handle\",\"type\":\"string\"},{\"name\":\"city\",\"type\":\"bytes32\"},{\"name\":\"state\",\"type\":\"bytes32\"},{\"name\":\"country\",\"type\":\"bytes32\"}],\"name\":\"registerNewUser\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"SHA256notaryHash\",\"type\":\"bytes32\"}],\"name\":\"getImage\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"},{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"userAddress\",\"type\":\"address\"}],\"name\":\"getUser\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"bytes32\"},{\"name\":\"\",\"type\":\"bytes32[]\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"getAllImages\",\"outputs\":[{\"name\":\"\",\"type\":\"bytes32[]\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"imageURL\",\"type\":\"string\"},{\"name\":\"SHA256notaryHash\",\"type\":\"bytes32\"}],\"name\":\"addImageToUser\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"userAddress\",\"type\":\"address\"}],\"name\":\"getUserImages\",\"outputs\":[{\"name\":\"\",\"type\":\"bytes32[]\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}]"
        do {
            let jsonData = jsonString.data(using: .utf8)
            let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })
            print(abiNative)
            XCTAssert(abiNative.count > 0, "Can't parse some real-world ABI")
        } catch {
            XCTFail()
            print(error)
        }
    }
    
    func testABIParsing () {
        let jsonString = "[{\"name\":\"f\",\"type\":\"function\",\"inputs\":[{\"name\":\"s\",\"type\":\"tuple\",\"components\":[{\"name\":\"a\",\"type\":\"uint256\"},{\"name\":\"b\",\"type\":\"uint256[]\"},{\"name\":\"c\",\"type\":\"tuple[]\",\"components\":[{\"name\":\"x\",\"type\":\"uint256\"},{\"name\":\"y\",\"type\":\"uint256\"}]}]},{\"name\":\"t\",\"type\":\"tuple\",\"components\":[{\"name\":\"x\",\"type\":\"uint256\"},{\"name\":\"y\",\"type\":\"uint256\"}]},{\"name\":\"a\",\"type\":\"uint256\"},{\"name\":\"z\",\"type\":\"uint256[3]\"}],\"outputs\":[]}]"
        do {
            let jsonData = jsonString.data(using: .utf8)
            let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })
            print(abiNative)
            XCTAssert(abiNative.count > 0, "Can't parse some real-world ABI")
        } catch {
            XCTFail()
            print(error)
        }
    }
    
    func testABIdecoding() {
        let jsonString = "[{\"type\":\"function\",\"name\":\"balance\",\"constant\":true},{\"type\":\"function\",\"name\":\"send\",\"constant\":false,\"inputs\":[{\"name\":\"amount\",\"type\":\"uint256\"}]},{\"type\":\"function\",\"name\":\"test\",\"constant\":false,\"inputs\":[{\"name\":\"number\",\"type\":\"uint32\"}]},{\"type\":\"function\",\"name\":\"string\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"string\"}]},{\"type\":\"function\",\"name\":\"bool\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"bool\"}]},{\"type\":\"function\",\"name\":\"address\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"address\"}]},{\"type\":\"function\",\"name\":\"uint64[2]\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint64[2]\"}]},{\"type\":\"function\",\"name\":\"uint64[]\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint64[]\"}]},{\"type\":\"function\",\"name\":\"foo\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint32\"}]},{\"type\":\"function\",\"name\":\"bar\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint32\"},{\"name\":\"string\",\"type\":\"uint16\"}]},{\"type\":\"function\",\"name\":\"slice\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint32[2]\"}]},{\"type\":\"function\",\"name\":\"slice256\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"uint256[2]\"}]},{\"type\":\"function\",\"name\":\"sliceAddress\",\"constant\":false,\"inputs\":[{\"name\":\"inputs\",\"type\":\"address[]\"}]},{\"type\":\"function\",\"name\":\"sliceMultiAddress\",\"constant\":false,\"inputs\":[{\"name\":\"a\",\"type\":\"address[]\"},{\"name\":\"b\",\"type\":\"address[]\"}]}]"
        do {
            let jsonData = jsonString.data(using: .utf8)
            let abi = try JSONDecoder().decode([ABI.Record].self, from: jsonData!)
            let abiNative = try abi.map({ (record) -> ABI.Element in
                return try record.parse()
            })
            print(abiNative)
            XCTAssert(true, "Failed to parse ABI")
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testABIencoding1()
    {
        //        var a = abi.methodID('baz', [ 'uint32', 'bool' ]).toString('hex') + abi.rawEncode([ 'uint32', 'bool' ], [ 69, 1 ]).toString('hex')
        //        var b = 'cdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001'
        //
        let types = [
            ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.uint(bits: 32)),
            ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.bool)
        ]
        let data = ABIEncoder.encode(types: types, values: [BigUInt(69), true] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0x00000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased().addHexPrefix() == expected, "failed to encode")
    }
    
    func testABIencoding2()
    {
        let types = [
            ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.string)
        ]
        let data = ABIEncoder.encode(types: types, values: ["dave"] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000046461766500000000000000000000000000000000000000000000000000000000"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased().addHexPrefix() == expected, "failed to encode")
    }
    
    func testABIencoding3()
    {
        //        var a = abi.methodID('sam', [ 'bytes', 'bool', 'uint256[]' ]).toString('hex') + abi.rawEncode([ 'bytes', 'bool', 'uint256[]' ], [ 'dave', true, [ 1, 2, 3 ] ]).toString('hex')
        //        var b = 'a5643bf20000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000464617665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003'
        let types = [
            ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.dynamicBytes),
            ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.bool),
            ABI.Element.InOut(name: "3", type: ABI.Element.ParameterType.array(type: .uint(bits: 256), length: 0))
        ]
        
        let data = ABIEncoder.encode(types: types, values: ["dave".data(using: .utf8)!, true, [BigUInt(1), BigUInt(2), BigUInt(3)] ] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0x0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000464617665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased().addHexPrefix() == expected, "failed to encode")
    }
    
    func testABIencoding4()
    {
        //        var a = abi.rawEncode([ 'int256' ], [ new BN('-19999999999999999999999999999999999999999999999999999999999999', 10) ]).toString('hex')
        //        var b = 'fffffffffffff38dd0f10627f5529bdb2c52d4846810af0ac000000000000001'
        
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.int(bits: 256))]
        let number = BigInt("-19999999999999999999999999999999999999999999999999999999999999", radix: 10)
        let data = ABIEncoder.encode(types: types,
                                       values: [number!] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0xfffffffffffff38dd0f10627f5529bdb2c52d4846810af0ac000000000000001"
        let result = data?.toHexString().lowercased().addHexPrefix()
        print(result ?? "")
        XCTAssert(result == expected, "failed to encode")
    }
    
    func testABIencoding5()
    {
        //        var a = abi.rawEncode([ 'string' ], [ ' hello world hello world hello world hello world  hello world hello world hello world hello world  hello world hello world hello world hello world hello world hello world hello world hello world' ]).toString('hex')
        //        var b = '000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c22068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64000000000000000000000000000000000000000000000000000000000000'
        
        let string = " hello world hello world hello world hello world  hello world hello world hello world hello world  hello world hello world hello world hello world hello world hello world hello world hello world"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.string)]
        let data = ABIEncoder.encode(types: types,
                                       values: [string] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c22068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64202068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c642068656c6c6f20776f726c64000000000000000000000000000000000000000000000000000000000000"
        print(data?.toHexString().lowercased().addHexPrefix() ?? "")
        XCTAssert(data?.toHexString().lowercased().addHexPrefix() == expected, "failed to encode")
    }
    
    func testABIencoding6()
    {
        //        var a = abi.methodID('f', [ 'uint', 'uint32[]', 'bytes10', 'bytes' ]).toString('hex') + abi.rawEncode([ 'uint', 'uint32[]', 'bytes10', 'bytes' ], [ 0x123, [ 0x456, 0x789 ], '1234567890', 'Hello, world!' ]).toString('hex')
        //        var b = '8be6524600000000000000000000000000000000000000000000000000000000000001230000000000000000000000000000000000000000000000000000000000000080313233343536373839300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004560000000000000000000000000000000000000000000000000000000000000789000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000'
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.uint(bits: 256)),
                     ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.array(type: .uint(bits: 32), length: 0)),
                     ABI.Element.InOut(name: "3", type: ABI.Element.ParameterType.bytes(length: 10)),
                     ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.dynamicBytes)
        ]
        let data = ABIEncoder.encode(types: types,
                                       values: [BigUInt("123", radix: 16)!,
                                                [BigUInt("456", radix: 16)!, BigUInt("789", radix: 16)!] as [AnyObject],
                                                "1234567890",
                                                "Hello, world!"] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0x00000000000000000000000000000000000000000000000000000000000001230000000000000000000000000000000000000000000000000000000000000080313233343536373839300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000004560000000000000000000000000000000000000000000000000000000000000789000000000000000000000000000000000000000000000000000000000000000d48656c6c6f2c20776f726c642100000000000000000000000000000000000000"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased().addHexPrefix() == expected, "failed to encode")
    }
    
    func testABIencoding7()
    {
        let types = [
            ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.array(type: .string, length: 0))
        ]
        let data = ABIEncoder.encode(types: types,
                                       values: [["Hello", "World"]] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000548656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005576f726c64000000000000000000000000000000000000000000000000000000"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased() == expected, "failed to encode")
    }
    
    func testABIencoding8()
    {
        let types = [
            ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.array(type: .string, length: 2))
        ]
        let data = ABIEncoder.encode(types: types,
                                       values: [["Hello", "World"]] as [AnyObject])
        XCTAssert(data != nil, "failed to encode")
        let expected = "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000548656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005576f726c64000000000000000000000000000000000000000000000000000000"
        print(data!.toHexString().lowercased())
        XCTAssert(data?.toHexString().lowercased() == expected, "failed to encode")
    }
    
    
    
    func testABIDecoding1() {
        let data = "0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000000000000000000000000000000000000000003"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.array(type: .uint(bits: 256), length: 2)),
                     ABI.Element.InOut(name: "2", type: ABI.Element.ParameterType.uint(bits: 256))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 2)
        guard let firstElement = result[0] as? [BigUInt] else {return XCTFail()}
        XCTAssert(firstElement.count == 2)
        guard let secondElement = result[1] as? BigUInt else {return XCTFail()}
        XCTAssert(firstElement[0] == BigUInt(1))
        XCTAssert(firstElement[1] == BigUInt(92))
        XCTAssert(secondElement == BigUInt(3))
    }
    
    func testABIDecoding2() {
        let data = "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.array(type: .uint(bits: 256), length: 0))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 1)
        guard let firstElement = result[0] as? [BigUInt] else {return XCTFail()}
        XCTAssert(firstElement.count == 3)
        XCTAssert(firstElement[0] == BigUInt(1))
        XCTAssert(firstElement[1] == BigUInt(2))
        XCTAssert(firstElement[2] == BigUInt(3))
    }
    
    func testABIDecoding3() {
        let data = "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.dynamicBytes)]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 1)
        guard let firstElement = result[0] as? Data else {return XCTFail()}
        XCTAssert(firstElement.count == 11)
    }
    
    func testABIDecoding4() {
        let data = "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.string)]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 1)
        guard let firstElement = result[0] as? String else {return XCTFail()}
        XCTAssert(firstElement == "hello world")
    }
    
    func testABIDecoding5() {
        let data = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.int(bits: 32))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 1)
        guard let firstElement = result[0] as? BigInt else {return XCTFail()}
        XCTAssert(firstElement == BigInt(-2))
    }
    
    func testABIDecoding6() {
        let data = "ffffffffffffffffffffffffffffffffffffffffffffffffffffb29c26f344fe"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.int(bits: 64))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == 1)
        guard let firstElement = result[0] as? BigInt else {return XCTFail()}
        XCTAssert(firstElement == BigInt("-85091238591234"))
    }
    
    func testABIDecoding7() {
        let data = "0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002a"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.bool),
                     ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.uint(bits: 32))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == types.count)
        guard let firstElement = result[0] as? Bool else {return XCTFail()}
        XCTAssert(firstElement == true)
        guard let secondElement = result[1] as? BigUInt else {return XCTFail()}
        XCTAssert(secondElement == 42)
    }
    
    func testABIDecoding8() {
        let data = "000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002a"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.bool),
                     ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.array(type: .uint(bits: 256), length: 0))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == types.count)
        guard let firstElement = result[0] as? Bool else {return XCTFail()}
        XCTAssert(firstElement == true)
        guard let secondElement = result[1] as? [BigUInt] else {return XCTFail()}
        XCTAssert(secondElement.count == 1)
        XCTAssert(secondElement[0] == 42)
    }
    
    func testABIDecoding9() {
        let data = "0000000000000000000000000000000000000000000000000000000000000020" +
            "0000000000000000000000000000000000000000000000000000000000000002" +
            "000000000000000000000000407d73d8a49eeb85d32cf465507dd71d507100c1" +
        "000000000000000000000000407d73d8a49eeb85d32cf465507dd71d507100c3"
        let types = [ABI.Element.InOut(name: "1", type: ABI.Element.ParameterType.array(type: .address, length: 0))]
        let res = ABIDecoder.decode(types: types, data: Data.fromHex(data)!)
        guard let result = res else {return XCTFail()}
        XCTAssert(result.count == types.count)
        guard let firstElement = result[0] as? [EthereumAddress] else {return XCTFail()}
        XCTAssert(firstElement.count == 2)
        XCTAssert(firstElement[0].address.lowercased().stripHexPrefix() == "407d73d8a49eeb85d32cf465507dd71d507100c1")
        XCTAssert(firstElement[1].address.lowercased().stripHexPrefix() == "407d73d8a49eeb85d32cf465507dd71d507100c3")
    }

}
