#
# Be sure to run `pod lib lint DistributedDomainResolution.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DistributedDomainResolution'
  s.version          = '0.1.0'
  s.summary          = 'Swift framework for resolving unstoppable domains.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'This framework helps to resolve a decentralized domain name such as brad.crypto'

  s.homepage         = 'https://github.com/unstoppabledomains/resolution-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rommex' => 'dev@kadru.net' }
  s.source           = { :git => 'https://github.com/unstoppabledomains/resolution-swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/unstoppableweb'
  
  s.swift_version = '5.0'

  s.ios.deployment_target = '13.6'

  s.source_files = 'Sources/Resolution/**/*'
  
  # s.resource_bundles = {
  #   'DistributedDomainResolution' => ['DistributedDomainResolution/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
