Pod::Spec.new do |s|
    s.name                    = "CleverPush"
    s.version                 = "1.12.4"
    s.summary                 = "CleverPush library for iOS."
    s.homepage                = "https://cleverpush.com"
    s.license                 = { :type => 'MIT (modified)', :file => 'LICENSE' }
    s.author                  = { "CleverPush" => "support@cleverpush.com" }
    s.ios.deployment_target   = "9.0"
    s.source                  = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }
    s.resource_bundles        = { 'CleverPush' => ['CleverPush/Source/*.{xib,storyboard,xcassets}'] }
    s.platform                = :ios
    s.requires_arc            = true
    s.framework               = "SystemConfiguration", "UIKit", "UserNotifications", "StoreKit", "WebKit", "JavaScriptCore", "SafariServices"
    s.ios.vendored_frameworks = "CleverPush/Framework/CleverPush.framework"
    s.pod_target_xcconfig     = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    s.user_target_xcconfig    = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
