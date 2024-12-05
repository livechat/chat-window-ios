Pod::Spec.new do |s|
  s.name             = 'LiveChat'
  s.version          = '2.0.26'
  s.summary          = 'LiveChat chat window for your iOS app.'
  s.homepage         = 'https://github.com/livechat/chat-window-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LiveChat Inc' => 'kamil.szostakowski@gmail.com' }
  s.source           = { :git => 'https://github.com/livechat/chat-window-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.6'
  s.source_files = 'Sources/*.{swift}'
  s.resources = 'Sources/*.{js}'
  s.frameworks = 'UIKit', 'WebKit'
  s.swift_version = '5.0'
end
