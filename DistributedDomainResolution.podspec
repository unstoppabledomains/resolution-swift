Pod::Spec.new do |spec|
  spec.name         = "DistributedDomainResolution"
  spec.version      = "0.1.1"
  spec.summary      = "Swift framework for resolving unstoppable domains."

  spec.description  = <<-DESC
	This framework helps to resolve a decentralized domain name such as brad.crypto
                   DESC

  spec.homepage     = "https://github.com/unstoppabledomains/resolution-swift"

  spec.license      = { :type => "MIT", :file => "LICENSE.md" }

  spec.author             = { "JohnnyJumper" => "jeyhunt@gmail.com", "Sergei Merenkov" => "mer.sergei@gmail.com", "Roman Medvid" => "roman@unstoppabledomains.com" }
  spec.social_media_url = 'https://twitter.com/unstoppableweb'

  spec.ios.deployment_target = "13.6"
  spec.osx.deployment_target = "10.15"

  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/unstoppabledomains/resolution-swift.git", :tag => spec.version }
  spec.source_files  = "Sources/Resolution", "Sources/Resolution/**/*"

  spec.dependency 'EthereumABI', '~> 1.2'
  spec.dependency 'Base58Swift', '~> 2.1'
end
