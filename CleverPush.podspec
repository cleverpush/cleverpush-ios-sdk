Pod::Spec.new do |s|
    s.name                    = "CleverPush"
    s.version                 = "1.34.33"
    s.summary                 = "CleverPush library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => "MIT (modified)", :file => "LICENSE" }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.platform                = :ios, '11.0'
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.requires_arc            = true
    s.frameworks              = ["SystemConfiguration", "UIKit", "UserNotifications", "StoreKit", "WebKit", "JavaScriptCore", "SafariServices", "ImageIO", "MobileCoreServices"]
    s.default_subspec         = "CleverPush"

    s.subspec 'CleverPushExtension' do |ss|
        ss.ios.vendored_frameworks = "Frameworks/CleverPushExtension.xcframework"
    end

    s.subspec 'CleverPush' do |ss|
        ss.ios.vendored_frameworks = "Frameworks/CleverPush.xcframework"
        ss.ios.resource_bundle = { "CleverPushResources" => "CleverPush/Resources/*" }
    end
end
