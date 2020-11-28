import Foundation

enum BannerDismissType: String {
    case tillDismissed = "til_dismissed",
         timeout = "timeout"
    
    static func from(raw: String) -> BannerDismissType {
        return BannerDismissType(rawValue: raw) ?? tillDismissed
    }
}
