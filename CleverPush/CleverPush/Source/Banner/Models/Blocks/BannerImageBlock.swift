import Foundation

class BannerImageBlock: BannerBlock {
    private(set) var imageUrl: String
    private(set) var scale: Int
    private(set) var dismiss: Bool
    
    override init(json: [String: Any?]) {
        self.imageUrl = json["imageUrl"] as? String ?? ""
        self.scale = json["scale"] as? Int ?? 100
        self.dismiss = json["dismiss"] as? Bool ?? false
        
        super.init(json: json)
    }
}
