# resolution-swift
[![Chat on Telegram](https://img.shields.io/badge/Chat%20on-Telegram-brightgreen.svg)](https://t.me/unstoppabledev)

Swift framework for resolving unstoppable domains

This framework helps to resolve a decentralized domain name such as `brad.crypto`

# Usage ( not sure yet how to use it in a live project) 
 - Include this framework in your project
 - Initialize Resolution class
 - use any method of resolution class
 
# Common examples
 ```swift
  let resolution = try Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
  
  resolution.addr(domain: "brad.crypto", ticker: "btc") { (result) in
      switch result {
      case .success(let returnValue):
            // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
          let btcAddress = returnValue
      case .failure(let error):
          print("Expected btc Address, but got \(error)")
      }
  }
  
  resolution.addr(domain: "brad.crypto", ticker: "eth") { (result) in
      switch result {
      case .success(let returnValue):
            // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
          let ethAddress = returnValue
      case .failure(let error):
          print("Expected eth Address, but got \(error)")
      }
  }
  
  resolution.owner(domain: "brad.crypto") { (result) in
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
    case unconfiguredDomain
    case recordNotFound
    case unsupportedNetwork
}
```

# Contributions

Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.
