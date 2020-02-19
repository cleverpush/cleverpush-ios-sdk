Pod::Spec.new do |s|
    s.name                    = "CleverPushLocation"
    s.version                 = "0.5.0"
    s.dependency                "CleverPush", "~> 0.5.0"
    s.static_framework        = true
    s.summary                 = "CleverPush Location library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => 'MIT (modified)', :file => 'LICENSE' }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.ios.deployment_target   = "8.0"
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.platform                = :ios
    s.requires_arc            = true
    s.framework               = "SystemConfiguration", "UIKit", "CoreLocation"
    s.ios.vendored_frameworks = "CleverPush/Framework/CleverPushLocation.framework"
end
