import Foundation

class BannerBlock {
    private(set) var type: BannerBlockType
    
    init(json: [String: Any?]) {
        self.type = BannerBlockType.from(raw: json["type"] as? String ?? "")
    }
    
    static func create(json: [String: Any?]) -> BannerBlock  {
        let bannerBlock = BannerBlock(json: json)
        
        switch bannerBlock.type {
        case .button:
            return BannerButtonBlock(json: json)
        case .text:
            return BannerTextBlock(json: json)
        case .image:
            return BannerImageBlock(json: json)
        }
    }
}
