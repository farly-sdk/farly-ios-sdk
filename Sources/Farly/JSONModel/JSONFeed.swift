import Foundation

// MARK: - FeedElement
@objc
public class FeedElement: NSObject, Codable {
    @objc public let id, name, devName, os, status: String
    @objc public let link, icon, priceApp: String
    @objc public let moneyIcon, moneyName: String?
    @objc public let rewardAmount: Double
    @objc public let smallDescription, smallDescriptionHTML: String
    @objc public let actions: [Action]
    @objc public let totalPayout: TotalPayout?
    @objc public let categories: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, devName = "devname", os, link, icon = "icone", status
        case moneyIcon = "money_icon", moneyName = "money_name", priceApp = "price_app"
        case rewardAmount = "reward_amount"
        case smallDescription = "small_description"
        case smallDescriptionHTML = "small_description_html"
        case actions, categories
        case totalPayout = "total_payout"
    }
}

// MARK: - Action
@objc
public class Action: NSObject, Codable {
    @objc public let id: String
    @objc public let amount: Double
    @objc public let text, html: String
}

// MARK: - TotalPayout
@objc
public class TotalPayout: NSObject, Codable {
    @objc public let amount: Double
    @objc public let currency: String
    
    enum CodingKeys: String, CodingKey {
        case amount
        case currency = "cur"
    }
}

typealias Feed = [FeedElement]
