Pod::Spec.new do |s|
    s.name                    = "CleverPush"
    s.version                 = "0.5.0"
    s.summary                 = "CleverPush library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => 'MIT (modified)', :file => 'LICENSE' }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.module_name             = "CleverPush"
    s.ios.deployment_target   = "8.0"
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.platform                = :ios
    s.requires_arc            = true
    s.framework               = "SystemConfiguration", "UIKit", "UserNotifications", "StoreKit"
    s.default_subspecs        = ["Core"]

    s.subspec "Core" do |core|
       core.frameworks                 = "SystemConfiguration", "UIKit", "UserNotifications", "StoreKit"
       core.ios.frameworks             = "WebKit"
       core.ios.vendored_frameworks    = "CleverPush/Framework/CleverPush.framework"
    end

    s.subspec "Location" do |location|
       location.ios.frameworks             = "CoreLocation"
       location.ios.vendored_frameworks        = "CleverPush/Framework/CleverPushLocation.framework"
       location.dependency                   "CleverPush/Core"
    end
end
