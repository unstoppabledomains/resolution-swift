Pod::Spec.new do |spec|
  spec.name         = "UnstoppableDomainsResolution"
  spec.version      = "0.3.0"
  spec.summary      = "Swift framework for resolving Unstoppable domains."

  spec.description  = <<-DESC
	This framework helps to resolve a decentralised domain names such as brad.crypto
                   DESC

  spec.homepage     = "https://github.com/unstoppabledomains/resolution-swift"

  spec.license      = { :type => "MIT", :file => "LICENSE.md" }

  spec.author             = { "JohnnyJumper" => "jeyhunt@gmail.com", "Sergei Merenkov" => "mer.sergei@gmail.com", "Roman Medvid" => "roman@unstoppabledomains.com" }
  spec.social_media_url = 'https://twitter.com/unstoppableweb'

  spec.ios.deployment_target = "11.0"

  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/unstoppabledomains/resolution-swift.git", :tag => spec.version }
  spec.source_files  = "Sources/UnstoppableDomainsResolution/**/*"

  spec.resources = "Sources/UnstoppableDomainsResolution/Resources/**/*"

  spec.dependency 'Base58Swift', '~> 2.1'
  spec.dependency 'EthereumAddress', '~> 1.3'
  spec.dependency 'CryptoSwift', '~> 1.0'
  spec.dependency 'BigInt'
end
