import XCTest

#if INSIDE_PM
@testable import UnstoppableDomainsResolution
#else
@testable import Resolution
#endif

class TokenUriMetadataTests: XCTestCase {

    func testMetadataParsing() {
        let jsonString = "{\"name\":\"brad.crypto\",\"description\":\"A .crypto blockchain domain. Use it to resolve your cryptocurrency addresses and decentralized websites.\",\"external_url\":\"https://unstoppabledomains.com/search?searchTerm=brad.crypto\",\"image\":\"https://storage.googleapis.com/dot-crypto-metadata-api/unstoppabledomains_crypto.png\",\"attributes\":[{\"trait_type\":\"domain\",\"value\":\"brad.crypto\"},{\"trait_type\":\"level\",\"value\":2},{\"trait_type\":\"length\",\"value\":4},{\"trait_type\":\"ADA\",\"value\":\"DdzFFzCqrhsuwQKiR3CdQ1FzuPAydtVCBFTRdy9FPKepAHEoXCee2qrio975M4cEbqYwZBsWJTNyrJ8NLJmAReSwAakQEHWBEd2HvSS7\"},{\"trait_type\":\"BTC\",\"value\":\"bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y\"},{\"trait_type\":\"ETH\",\"value\":\"0x8aaD44321A86b170879d7A244c1e8d360c99DdA8\"},{\"trait_type\":\"IPFS Content\",\"value\":\"QmdyBw5oTgCtTLQ18PbDvPL8iaLoEPhSyzD91q9XmgmAjb\"},{\"trait_type\":\"type\",\"value\":\"standard\"}],\"image_data\":\"<svg></svg>\",\"background_color\":\"4C47F7\"}"
        do {
            let jsonData = jsonString.data(using: .utf8)
            let metadata = try JSONDecoder().decode(TokenUriMetadata.self, from: jsonData!)
            assert(metadata.name == "brad.crypto")
            assert(metadata.attributes.count == 8)
        } catch {
            XCTFail()
            print(error)
        }
    }
    
    func testMetadataAttributeString() {
        do {
            let attribute = try parseJsonAttribute(jsonString: "{\"trait_type\": \"domain\",\"value\": \"brad.crypto\"}")
            assert(attribute.traitType == "domain")
            assert(attribute.value.value == "brad.crypto")
        } catch {
            XCTFail()
            print(error)
        }
    }

    func testMetadataAttributeNumber() {
        do {
            let attribute = try parseJsonAttribute(jsonString: "{\"trait_type\": \"level\",\"value\": 2}")
            assert(attribute.traitType == "level")
            assert(attribute.value.value == "2")
        } catch {
            XCTFail()
            print(error)
        }
    }

    func testMetadataAttributeDouble() {
        do {
            let attribute = try parseJsonAttribute(jsonString: "{\"trait_type\": \"balance\",\"value\": 1.5}")
            assert(attribute.traitType == "balance")
            assert(attribute.value.value == "1.5")
        } catch {
            XCTFail()
            print(error)
        }
    }

    func testMetadataAttributeBoolean() {
        do {
            let attribute = try parseJsonAttribute(jsonString: "{\"trait_type\": \"enabled\",\"value\": true}")
            assert(attribute.traitType == "enabled")
            assert(attribute.value.value == "true")
        } catch {
            XCTFail()
            print(error)
        }
    }

    func testMetadataAttributeIncorrect() {
        do {
            let attribute = try parseJsonAttribute(jsonString: "{\"trait_type\": \"incorrect\",\"value\": [\"some\", \"values\"]}")
            XCTFail("Expected DecodingError, but got none")
        } catch {
            assert(error is DecodingError, "Expected DecodingError, but got different \(error)")
        }
    }

    private func parseJsonAttribute(jsonString: String) throws -> TokenUriMetadataAttribute {
        let jsonData = jsonString.data(using: .utf8)
        return try JSONDecoder().decode(TokenUriMetadataAttribute.self, from: jsonData!)
    }
}
