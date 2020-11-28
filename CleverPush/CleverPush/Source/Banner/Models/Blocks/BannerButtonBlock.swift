import Foundation

class BannerButtonBlock: BannerBlock {
    private(set) var text: String
    private(set) var color: String
    private(set) var background: String
    private(set) var size: Int
    private(set) var alignment: Alignment
    private(set) var dismiss: Bool
    private(set) var radius: Int
    
    override init(json: [String: Any?]) {
        self.text = json["text"] as? String ?? ""
        self.color = json["color"] as? String ?? "#000000"
        self.background = json["background"] as? String ?? "#FFFFFF"
        self.size = json["size"] as? Int ?? 18
        self.alignment = Alignment.from(raw: json["alignment"] as? String ?? "")
        self.dismiss = json["dismiss"] as? Bool ?? true
        self.radius = json["radius"] as? Int ?? 0
        
        super.init(json: json)
    }
}
