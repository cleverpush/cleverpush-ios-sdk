import Foundation

enum Alignment: String {
    case left = "left",
         center = "center",
         right = "right"
    
    static func from(raw: String) -> Alignment  {
        return Alignment(rawValue: raw) ?? center
    }
}
