import ActivityKit
import WidgetKit
import SwiftUI

struct CleverPushWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CleverPushWidgetExtensionAttributes.self) { context in
            VStack {
                Spacer()
                Text(context.attributes.title).font(.headline)
                Spacer()
                HStack {
                    Spacer()
                    Label {
                        Text(context.state.message)
                    } icon: {
                        Image("CleverPushicon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40.0, height: 40.0)
                    }
                    Spacer()
                }
                Spacer()
            }
            .activitySystemActionForegroundColor(.black)
            .activityBackgroundTint(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("Min")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
