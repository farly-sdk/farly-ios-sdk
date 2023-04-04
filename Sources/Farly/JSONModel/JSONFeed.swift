import Foundation

// MARK: - FeedElement
@objc
public class FeedElement: NSObject, Codable {
    @objc public let id, name, devName: String
    @objc public let link, icon: String
    @objc public let smallDescription, smallDescriptionHTML: String
    @objc public let actions: [Action]

    enum CodingKeys: String, CodingKey {
        case id, name, devName = "devname", link, icon = "icone"
        case smallDescription = "small_description"
        case smallDescriptionHTML = "small_description_html"
        case actions
    }
}

// MARK: - Action
@objc
public class Action: NSObject, Codable {
    @objc public let id: String
    @objc public let amount: Double
    @objc public let text, html: String
}

typealias Feed = [FeedElement]
