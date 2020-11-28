import Foundation

class BannerBackground {
    private(set) var imageUrl: String?
    private(set) var color: String
    private(set) var dismiss: Bool
    
    init(json: [String: Any?]) {
        self.imageUrl = json["imageUrl"] as? String
        self.color = json["color"] as? String ?? "#FFFFFF"
        self.dismiss = json["dismiss"] as? Bool ?? true
    }
}
