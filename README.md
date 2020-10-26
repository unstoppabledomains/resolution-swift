# UnstoppableDomainsResolution
[![Chat on Telegram](https://img.shields.io/badge/Chat%20on-Telegram-brightgreen.svg)](https://t.me/unstoppabledev)

Swift framework for resolving unstoppable domains

This framework helps to resolve a decentralized domain name such as `brad.crypto`

# Installation into the project

## Cocoa Pods
```ruby
pod 'UnstoppableDomainsResolution', '~> 0.1.4'
```
## Swift Package Manager
```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "0.1.5")
)
```

# Usage

 - Create an instance of the Resolution class
 - Call any method of the Resolution class asyncronously
 
-- NOTE: make sure an instance of the Resolution class is not deallocated until the asyncronous call brings in the result
 
# Common examples
 ```swift
 import UnstoppableDomainsResolution
 
    ....
 
  guard let resolution = try? Resolution() else {
     print ("Init of Resolution instance with default parameters failed...")
     return
  }
  
  // or, if you want to specify providerUrl and network by yourself:
  guard let resolution = try? Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet") else {
     print ("Init of Resolution instance with custom parameters failed...")
     return
  }
  
  
  resolution.addr(domain: "brad.crypto", ticker: "btc") { result in
      switch result {
      case .success(let returnValue):
            // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
          let btcAddress = returnValue
      case .failure(let error):
          print("Expected btc Address, but got \(error)")
      }
  }
  
  resolution.addr(domain: "brad.crypto", ticker: "eth") { result in
      switch result {
      case .success(let returnValue):
            // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
          let ethAddress = returnValue
      case .failure(let error):
          print("Expected eth Address, but got \(error)")
      }
  }
  
  resolution.owner(domain: "brad.crypto") { result in
      switch result {
      case .success(let returnValue):
            // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
          let domainOwner = returnValue
      case .failure(let error):
          XCTFail("Expected owner, but got \(error)")
      }
  }
 ```
 
 ## Batch request of owners
 In the version 0.1.3 there was introduced a method `batchOwners(domains: _, completion: _ )` that adds additional convenience to query the owners of the array of domains. The domains must be only CNS-compatible (other kind of domains will throw `ResolutionError.methodNotSupported`). As opposed to the single `owner(domain: _, completion: _)` method, this batch request will return the array of owners `[String?]`: if the the domain is not registered (or its resolver is `null`, the related array element of the response will be `nil` without throwing an error.
 
 ```swift
 
 resolution.batchOwners(domains: ["brad.crypto", "otherbrad.crypto"]) { result in
     switch result {
     case .success(let returnValue):
           // returnValue: [String?] = <array of owners's addresses>
         let domainOwner = returnValue
     case .failure(let error):
         XCTFail("Expected owner, but got \(error)")
     }
 }
 ```
 
 # Networking
 Make sure your app has AppTransportSecurity settings to allow HTTP access to the `https://main-rpc.linkpool.io` domain.
 
 ## Custom Networking Layer
 The UnstoppableDomainsResolution library is using native iOS networking API to connect to the internet. If you want the library to use your own networking layer you need to conform your networking layer to the `NetworkingLayer` protocol, which requires only one method to be implemented: `makeHttpPostRequest(url:, httpMethod:, httpHeaderContentType:, httpBody:, completion:)` This method would delegate the request to your own networking code.
 
 In this case the construction of the Resolution instance would be like so:
 
 ```swift 
 
 guard let resolution = try? Resolution(networking: MyNetworkingApi) else {
    print ("Init of Resolution instance failed...")
    return
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
    case inconsistenDomainArray
    case methodNotSupported
}
```

# Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.
