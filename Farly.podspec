#
# Be sure to run `pod lib lint Farly.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Farly'
  s.version          = ENV['LIB_VERSION'] || '0.1.0' #fallback to last published version
  s.summary          = 'Farly SDK for publishers.'
  s.swift_versions   = '5.5.2'

  s.description      = <<-DESC
Farly SDK for iOS, as a Pod. Full documentation at https://mobsuccess.notion.site/Farly-iOS-SDK-d4c1ff68a3584b0e9fb5bb8a77597f10
                       DESC

  s.homepage         = 'https://github.com/farly-sdk/farly-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Philippe Auriach' => 'philippe.auriach@mobsuccess.com' }
  s.source           = { :git => 'https://github.com/farly-sdk/farly-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.3'

  s.source_files = 'Sources/Farly/**/*'  
end
