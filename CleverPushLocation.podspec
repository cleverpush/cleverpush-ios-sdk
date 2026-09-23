Pod::Spec.new do |s|
    s.name                    = "CleverPushLocation"
    s.version                 = "0.5.0"
    s.dependency              "CleverPush", "~> 1.31.1"
    s.static_framework        = true
    s.summary                 = "CleverPush Location library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => "MIT (modified)", :file => "LICENSE" }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.platform                = :ios, '11.0'
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.requires_arc            = true
    s.frameworks              = ["SystemConfiguration", "UIKit", "CoreLocation"]
    s.ios.vendored_frameworks = "Frameworks/CleverPushLocation.xcframework"
    s.ios.preserve_paths = "Frameworks/CleverPushLocation.dSYMs/**/*"
end
