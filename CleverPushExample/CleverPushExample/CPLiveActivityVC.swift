import Foundation
import ActivityKit
import UserNotifications

struct CleverPushWidgetExtensionAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    
    public struct ContentState: Codable, Hashable {
        var message: String
    }
    var id = UUID()
    var title: String
}

@objc
class CPLiveActivityVC: NSObject {
    
    @available(iOS 13.0, *)
    @objc
    static func createActivity() async -> NSDictionary? {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                return
            }
        }
        if #available(iOS 16.1, *) {
            let attributes = CleverPushWidgetExtensionAttributes(title: "CleverPush ")
            let contentState = CleverPushWidgetExtensionAttributes.LiveDeliveryData(message: "Live Activity Stared")
            do {
                let activity = try Activity<CleverPushWidgetExtensionAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: .token)
                for await data in activity.pushTokenUpdates {
                    let actvityToken = data.map {String(format: "%02x", $0)}.joined()
                    let liveActivityData:NSDictionary = ["activityId" : activity.id,"activityPushToken":actvityToken]
                    return liveActivityData
                }
            } catch (let error) {
                print(error.localizedDescription)
                return nil
            }
        }
        return nil
    }
}
