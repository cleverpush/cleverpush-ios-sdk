import Foundation

class BannerTextBlock: BannerBlock {
    private(set) var text: String
    private(set) var color: String
    private(set) var size: Int
    private(set) var alignment: Alignment
    
    override init(json: [String: Any?]) {
        self.text = json["text"] as? String ?? ""
        self.color = json["color"] as? String ?? "#FFFFFF"
        self.size = json["size"] as? Int ?? 18
        self.alignment = Alignment.from(raw: json["alignment"] as? String ?? "")
        
        super.init(json: json)
    }
}
