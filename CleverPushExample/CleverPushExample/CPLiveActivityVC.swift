import Foundation
import ActivityKit
import UserNotifications

public struct CleverPushWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var message: String
    }
    var title: String
}

@objc
class CPLiveActivityVC: NSObject {
    static var counter = 0
    @available(iOS 13.0, *)
    @objc
    static func createActivity() async -> String? {
        if #available(iOS 16.1, *) {
            counter += 1;
            let attributes = CleverPushWidgetExtensionAttributes(title: "CleverPush")
            let contentState = CleverPushWidgetExtensionAttributes.ContentState(message: "Live Activity Started")
            do {
                let activity = try Activity<CleverPushWidgetExtensionAttributes>.request(
                        attributes: attributes,
                        contentState: contentState,
                        pushType: .token)
                for await data in activity.pushTokenUpdates {
                    let myToken = data.map {String(format: "%02x", $0)}.joined()
                    return myToken
                }
            } catch (let error) {
                print(error.localizedDescription)
                return nil
            }
        }
        return nil
    }
}
