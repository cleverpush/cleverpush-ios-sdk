Pod::Spec.new do |s|
    s.name             = "CleverPush"
    s.version          = "0.3.1"
    s.summary          = "CleverPush library for iOS."
    s.homepage         = "https://cleverpush.com"
    s.license          = { :type => 'MIT (modified)', :file => 'LICENSE' }
    s.author           = { "Marius Gebhardt" => "m.gebhardt@cleverpush.com" }

    s.source           = { :git => "https://github.com/cleverpush/cleverpush-ios-sdk.git", :tag => s.version.to_s }

    s.platform     = :ios
    s.requires_arc = true

    s.ios.vendored_frameworks = 'CleverPush_iOS_SDK/Framework/CleverPush.framework'
    s.framework               = 'SystemConfiguration', 'UIKit', 'UserNotifications'
end
