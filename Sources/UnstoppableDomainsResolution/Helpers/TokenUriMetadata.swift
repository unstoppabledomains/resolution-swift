import Foundation

public struct TokenUriMetadata: Codable {
    let name: String?
    let tokenId: String?
    let namehash: String?
    let description: String?
    let externalUrl: String?
    let image: String?
    let attributes: [TokenUriMetadataAttribute]
    var backgroundColor: String?
    var animationUrl: String?
    var youtubeUrl: String?
    var externalLink: String?
    var imageData: String?

    enum CodingKeys: String, CodingKey {
        case name
        case tokenId
        case namehash
        case description
        case externalUrl = "external_url"
        case image
        case attributes
        case backgroundColor = "background_color"
        case animationUrl = "animation_url"
        case youtubeUrl = "youtube_url"
        case externalLink = "external_link"
        case imageData = "image_data"
    }
}

// MARK: - Attribute
public struct TokenUriMetadataAttribute: Codable {
    let displayType: String?
    let traitType: String?
    let value: TokenUriMetadataValue

    enum CodingKeys: String, CodingKey {
        case displayType = "display_type"
        case traitType = "trait_type"
        case value
    }
}

struct TokenUriMetadataValue: Codable {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // attempt to decode from all JSON primitives
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = int.description
        } else if let double = try? container.decode(Double.self) {
            value = double.description
        } else if let bool = try? container.decode(Bool.self) {
            value = bool.description
        } else {
            throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: "Failed to decode token metadata attribute value."))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
