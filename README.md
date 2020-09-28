# UnstoppableDomainsResolution
[![Chat on Telegram](https://img.shields.io/badge/Chat%20on-Telegram-brightgreen.svg)](https://t.me/unstoppabledev)

Swift framework for resolving unstoppable domains

This framework helps to resolve a decentralized domain name such as `brad.crypto`

# Installation into the project

## Cocoa Pods
```ruby
pod 'UnstoppableDomainsResolution', '~> 0.1.2'
```
## Swift Package Manager
```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "0.1.2")
)
```

# Usage

 - Create an instance of the Resolution class
 - Call any method of the Resolution class asyncronously
 
-- NOTE: make sure an instance of the Resolution class (<Resolution?> type) is not deallocated until the asyncronous call brings in the result
 
# Common examples
 ```swift
 import UnstoppableDomainsResolution
 
    ....
 
  let resolution = try! Resolution()
  
  // or, if you want to specify providerUrl and network by yourself:
  let resolution = try! Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet")
  
  
  resolution!.addr(domain: "brad.crypto", ticker: "btc") { result in
      switch result {
      case .success(let returnValue):
            // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
          let btcAddress = returnValue
      case .failure(let error):
          print("Expected btc Address, but got \(error)")
      }
  }
  
  resolution!.addr(domain: "brad.crypto", ticker: "eth") { result in
      switch result {
      case .success(let returnValue):
            // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
          let ethAddress = returnValue
      case .failure(let error):
          print("Expected eth Address, but got \(error)")
      }
  }
  
  resolution!.owner(domain: "brad.crypto") { result in
      switch result {
      case .success(let returnValue):
            // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
          let domainOwner = returnValue
      case .failure(let error):
          XCTFail("Expected owner, but got \(error)")
      }
  }
 ```
 
 # Possible Errors:
 In case if domain is not registered, or doesn't contain some information you are requesting this framework will return ResolutionError with these possible cases:
 It is adviced to check for the errors and show the users an appropriate localized message

```
enum ResolutionError: Error {
    case unregisteredDomain
    case unsupportedDomain
    case recordNotFound
    case recordNotSupported
    case unsupportedNetwork
    case unspecifiedResolver
    case unknownError(Error)
    case proxyReaderNonInitialized
}
```

# Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.
