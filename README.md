# resolution-swift
Swift framework for resolving unstoppable domains

This framework helps to resolve a decentralized domain name such as `brad.crypto`

# Usage ( not sure yet how to use it in a live project) 
 - Include this framework in your project
 - Initialize Resolution class
 - use any method of resolution class
 
 # Common examples
 ```
  let resolution = try Resolution(providerUrl: "https://main-rpc.linkpool.io", network: "mainnet");
  
  let btcAddress = try resolution.addr(domain: "brad.crypto", ticker: "btc"); // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
  let ethAddress = try resolution.addr(domain: "brad.crypto", ticker: "eth"); // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
  
  let domainOwner = try resolution.owner(domain: "brad.crypto"); // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
 ```
 
 # Possible Errors:
 In case if domain is not registered, or doesn't contain some information you are requesting this framework will throw ResolutionError with these possible cases:
 It is adviced to check for the errors and show the users an appropriate localized message

```
 enum ResolutionError: Error {
    case UnregisteredDomain
    case UnsupportedDomain
    case UnconfiguredDomain
    case RecordNotFound
    case UnsupportedNetwork
}
```
