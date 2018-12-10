#
# Be sure to run `pod lib lint TTPlayerLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TTPlayerLib'
  s.version          = '1.1.2'
  s.summary          = '基于IJKPlayer，支持直播、点播，搭载本地服务器实现缓冲、缓存减少视频流量，支持点播视频边线边播，支持视频记忆功能'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ClaudeLi/TTPlayerLib'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'claudeli@yeah.net' => 'ClaudeLi' }
  s.source           = { :git => 'https://github.com/ClaudeLi/TTPlayerLib.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.public_header_files = 'TTPlayerLib/TTPlayerLib.h'
  s.source_files = 'TTPlayerLib/TTPlayerLib.h'
  s.ios.deployment_target = '8.0'

  s.resource     = 'TTPlayerLib/Assets/TTPlayerSDK.bundle'
  s.vendored_frameworks = 'TTPlayerLib/TTPlayerSDK.framework'

  # s.source_files = 'TTPlayerLib/Classes/**/*.{h,m}'
  # s.resource_bundles = {
  #   'TTPlayerLib' => ['TTPlayerLib/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'IJKFramework'
    s.dependency 'ksyhttpcache'
    s.dependency 'FMDB'
    s.dependency 'CLTools'
    s.dependency 'TTAlertKit'
    s.dependency 'CLProgressFPD'
end
