Pod::Spec.new do |s|
    s.name                    = "CleverPush"
    s.version                 = "1.31.3"
    s.summary                 = "CleverPush library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => "MIT (modified)", :file => "LICENSE" }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.ios.deployment_target   = "11.0"
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.platform                = :ios
    s.requires_arc            = true
    s.framework               = "SystemConfiguration", "UIKit", "UserNotifications", "StoreKit", "WebKit", "JavaScriptCore", "SafariServices", "ImageIO", "MobileCoreServices"
    s.ios.resource_bundle     = { "CleverPushResources" => "CleverPush/Resources/*" }
    s.ios.vendored_frameworks = "Frameworks/CleverPush.xcframework"
end
