import Foundation

@objc
class AppBannerModule: NSObject {
    private static let ShownAppBannersDefaultsKey = "shownAppBanners"
    
    private static var instance: AppBannerModule? = nil;
    
    @objc static func initBanners(channel: String, showDrafts: Bool = false) {
        instance = instance ?? AppBannerModule(withChannel: channel, andShowDrafts: showDrafts)
    }
    
    private let dispatchQueue = DispatchQueue(label: "AppBannerModule")
    
    private var activeBanners: [Banner] = []
    private var channel = ""
    private var showDrafts = false
    
    private init(withChannel channel: String, andShowDrafts showDrafts: Bool) {
        super.init()
        
        self.channel = channel
        self.showDrafts = showDrafts
        
        dispatchQueue.sync { self.loadBanners(startup) }
    }
    
    private func loadBanners(_ callback: @escaping (_ banners: [Banner]) -> Void) {
        let request = CleverPushHTTPClient.shared()?.request(withMethod: "GET", path: "/channel/\(channel)/app-banners")
        CleverPush.enqueue(request as URLRequest?, onSuccess: { res in
            let jsonResponse = res as? [String: Any?] ?? [:]
            let bannersJson = jsonResponse["banners"] as? [[String: Any?]] ?? []
            let banners = bannersJson.map { Banner(json: $0) }
            
            callback(banners)
        }, onFailure: { err in
            callback([])
        })
    }
    
    private func startup(_ banners: [Banner]) {
        createBanners(banners)
        scheduleBanners()
    }
    
    private func createBanners(_ banners: [Banner]) {
        for banner in banners {
            if banner.status == .draft && !showDrafts {
                continue
            }
            
            if banner.frequency == .once && isBannerShown(withId: banner.id) {
                continue
            }
            
            if banner.stopAtType == .specificTime && banner.stopAt.compare(Date()) == .orderedAscending {
                continue
            }
            
            activeBanners.append(banner)
        }
    }
    
    private func scheduleBanners() {
        for banner in activeBanners {
            if(banner.startAt.compare(Date()) == .orderedAscending) {
                dispatchQueue.sync { self.showBanner(banner: banner) }
            } else {
                let delay: Double = Date().timeIntervalSince(banner.startAt)
                dispatchQueue.asyncAfter(deadline: .now() + delay) { self.showBanner(banner: banner) }
            }
        }
    }
    
    private func isBannerShown(withId id: String) -> Bool {
        let bannerIds = UserDefaults.standard.array(forKey: AppBannerModule.ShownAppBannersDefaultsKey) as? [String] ?? []
        
        return bannerIds.contains(id)
    }
    
    private func setBannerIsShown(withId id: String) -> Void {
        var bannerIds = UserDefaults.standard.array(forKey: AppBannerModule.ShownAppBannersDefaultsKey) as? [String] ?? []
        bannerIds.append(id)
        
        UserDefaults.standard.setValue(bannerIds, forKey: AppBannerModule.ShownAppBannersDefaultsKey)
    }
    
    private func showBanner(banner: Banner) -> Void {
        let bannerController = AppBannerController.show(forBanner: banner)
        
        if(banner.frequency == .once) {
            setBannerIsShown(withId: banner.id)
        }
        
        if(banner.dismissType == .timeout) {
            dispatchQueue.asyncAfter(deadline: .now() + Double(banner.dismissTimeout)) {
                bannerController?.onDismiss()
            }
        }
    }
}
