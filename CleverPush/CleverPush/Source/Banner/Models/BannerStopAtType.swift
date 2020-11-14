import Foundation

enum BannerStopAtType: String {
    case forever = "forever",
         specificTime = "specific_time"
    
    static func from(raw: String) -> BannerStopAtType {
        return BannerStopAtType(rawValue: raw) ?? forever
    }
}
