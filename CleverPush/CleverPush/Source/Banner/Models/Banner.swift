import Foundation

class Banner {
    private static let DEFAULT_DATE_TIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
    
    private static var defaultDateFormater: DateFormatter {
        get {
            let formater = DateFormatter()
            formater.locale = Locale(identifier: "en_US_POSIX")
            formater.dateFormat = DEFAULT_DATE_TIME_FORMAT
            
            return formater
        }
    }

    private(set) var id: String
    private(set) var channel: String
    private(set) var name: String
    private(set) var type: BannerType
    private(set) var status: BannerStatus
    private(set) var blocks: [BannerBlock]
    private(set) var background: BannerBackground;
    private(set) var startAt: Date
    private(set) var dismissType: BannerDismissType
    private(set) var dismissTimeout: Int
    private(set) var stopAtType: BannerStopAtType
    private(set) var stopAt: Date
    private(set) var frequency: BannerFrequency
    private(set) var createdAt: Date

    init(json: [String: Any?]) {
        self.id = json["_id"] as? String ?? "bannerId"
        self.channel = json["channel"] as? String ?? "bannerChannel"
        self.name = json["name"] as? String ?? "bannerName"
        self.type = BannerType.from(raw: json["type"] as? String ?? "")
        self.status = BannerStatus.from(raw: json["status"] as? String ?? "")
        self.background = BannerBackground(json: json["background"] as? [String: Any?] ?? [:])
        
        let blocksJson = json["blocks"] as? [[String: Any?]] ?? []
        self.blocks = blocksJson.map { BannerBlock.create(json: $0) }
        
        self.startAt = Banner.defaultDateFormater.date(
            from: json["startAt"] as? String ?? ""
        ) ?? Date()
        self.dismissType = BannerDismissType.from(raw: json["dismissType"] as? String ?? "")
        self.dismissTimeout = json["dismissTimeout"] as? Int ?? 60
        self.stopAtType = BannerStopAtType.from(raw: json["stopAtType"] as? String ?? "")
        self.stopAt = Banner.defaultDateFormater.date(
            from: json["stopAt"] as? String ?? ""
        ) ?? Date()
        
        self.frequency = BannerFrequency.from(raw: json["frequency"] as? String ?? "")
        
        self.createdAt = Banner.defaultDateFormater.date(
            from: json["createdAt"] as? String ?? ""
        ) ?? Date()
    }

//    static create(JSONObject json) throws JSONException -> Banner {
//        Banner banner = new Banner();
//
//        banner.id = json.getString("_id");
//        banner.channel = json.getString("channel");
//        banner.name = json.getString("name");
//        banner.type = BannerType.fromString(json.getString("type"));
//        banner.status = BannerStatus.fromString(json.getString("status"));
//        banner.blocks = new LinkedList<>();
//
//        JSONArray blockArray = json.getJSONArray("blocks");
//        for(int i = 0; i < blockArray.length(); ++i) {
//            banner.blocks.add(BannerBlock.create(blockArray.getJSONObject(i)));
//        }
//
//        banner.background = BannerBackground.create(json.getJSONObject("background"));
//
//        try {
//            SimpleDateFormat format = new SimpleDateFormat(DEFAULT_DATE_TIME_FORMAT, Locale.US);
//            banner.startAt = format.parse(json.getString("startAt"));
//        } catch (ParseException e) {
//            banner.startAt = new Date();
//        }
//
//        banner.dismissType = BannerDismissType.fromString(json.getString("dismissType"));
//        banner.dismissTimeout = json.getInt("dismissTimeout");
//        banner.stopAtType = BannerStopAtType.fromString(json.getString("stopAtType"));
//
//        try {
//            SimpleDateFormat format = new SimpleDateFormat(DEFAULT_DATE_TIME_FORMAT, Locale.US);
//            banner.stopAt = json.isNull("stopAt") ? null : format.parse(json.getString("stopAt"));
//        } catch (ParseException e) {
//            banner.stopAt = null;
//        }
//
//        try {
//            SimpleDateFormat format = new SimpleDateFormat(DEFAULT_DATE_TIME_FORMAT, Locale.US);
//            banner.createdAt = json.isNull("createdAt") ? null : format.parse(json.getString("createdAt"));
//        } catch (ParseException e) {
//            banner.createdAt = null;
//        }
//
//        return banner;
//    }
}
