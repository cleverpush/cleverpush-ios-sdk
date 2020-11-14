import Foundation

enum BannerType: String {
    case top = "top",
         bottom = "bottom",
         center = "center",
         full = "full"

    static func from(raw: String) -> BannerType  {
        return BannerType(rawValue: raw) ?? center
    }
}
