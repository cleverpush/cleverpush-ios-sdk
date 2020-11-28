import Foundation

enum BannerFrequency: String {
    case once = "once",
         oncePerSession = "once_per_session"
    
    static func from(raw: String) -> BannerFrequency {
        return BannerFrequency(rawValue: raw) ?? once
    }
}
