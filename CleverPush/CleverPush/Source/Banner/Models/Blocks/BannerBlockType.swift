import Foundation

enum BannerBlockType: String {
    case text = "text",
         image = "image",
         button = "button"
    
    static func from(raw: String) -> BannerBlockType  {
        return BannerBlockType(rawValue: raw) ?? text
    }
}
