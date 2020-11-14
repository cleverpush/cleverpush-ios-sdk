import Foundation

enum BannerStatus: String {
    case published = "published",
         draft = "draft"

    static func from(raw: String) -> BannerStatus {
        return BannerStatus(rawValue: raw) ?? draft
    }
}
