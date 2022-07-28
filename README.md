# UnstoppableDomainsResolution

[![Get help on Discord](https://img.shields.io/badge/Get%20help%20on-Discord-blueviolet)](https://discord.gg/b6ZVxSZ9Hn)
[![Unstoppable Domains Documentation](https://img.shields.io/badge/Documentation-unstoppabledomains.com-blue)](https://docs.unstoppabledomains.com/)

Resolution is a library for interacting with blockchain domain names. It can be used to retrieve payment addresses and IPFS hashes for decentralized websites.

Resolution is primarily built and maintained by [Unstoppable Domains](https://unstoppabledomains.com/).

# Installing the library

## Cocoa Pods

```ruby
pod 'UnstoppableDomainsResolution', '~> 5.0.0'
```

## Swift Package Manager

```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "5.0.0")
)
```

# Updating the library

## Cocoa Pods

```ruby
pod update UnstoppableDomainsResolution
```

## Swift Package Manager

```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "<latest version number>")
)
```

# Usage

 - Create an instance of the Resolution class
 - Call any method of the Resolution class asyncronously

> NOTE: make sure an instance of the Resolution class is not deallocated until the asyncronous call brings in the result. Your code is the **only owner** of the instance so keep it as long as you need it.

```swift
import UnstoppableDomainsResolution

guard let resolution = try? Resolution() else {
  print ("Init of Resolution instance with default parameters failed...")
  return
}
```

## Customizing naming services
Version 0.3.0 introduced the `Configurations` struct that is used for configuring each connected naming service.
Library supports three networks at the moment Ethereum, Polygon and Zilliqa. You can update each network separately.

```swift
let resolution = try Resolution(configs: Configurations(
        uns: UnsLocations = UnsLocations(
            layer1: NamingServiceConfig(
                providerUrl: "https://eth-mainnet.alchemyapi.io/v2/_BDuTLPgioYxULIE5cGq3wivWAJborcM",
                network: "mainnet"),
            layer2: NamingServiceConfig(
                providerUrl: "https://polygon-mainnet.g.alchemy.com/v2/bKmEKAC4HJUEDNlnoYITvXYuhrIshFsa",
                network: "polygon-mainnet"),
            zlayer: NamingServiceConfig(
                providerUrl: "https://api.zilliqa.com",
                network: "mainnet")
        )
);

resolution.addr(domain: "udtestdev-creek.crypto", ticker: "eth") { (result) in
    switch result {
    case .success(let returnValue):
        ethAddress = returnValue
        domainReceived.fulfill()
    case .failure(let error):
        XCTFail("Expected Eth Address, but got \(error)")
    }
}
```

## Batch requesting of owners

Version 0.1.3 introduced the `batchOwners(domains: _, completion: _ )` method which adds additional convenience when making multiple domain owner queries.

> This method is only compatible with uns-based domains. Using this method with any other domain type will throw the error: `ResolutionError.methodNotSupported`.

As opposed to the single `owner(domain: _, completion: _)` method, this batch request will return an array of owners `[String?]`. If the the domain is not registered or its value is `null`, the corresponding array element of the response will be `nil` without throwing an error.

```swift
resolution.batchOwners(domains: ["brad.crypto", "otherbrad.crypto"]) { result in
  switch result {
  case .success(let returnValue):
    // returnValue: [String: String?] = <map of domains to owner address>
    let domainOwner = returnValue
  case .failure(let error):
    XCTFail("Expected owner, but got \(error)")
  }
}
```

# Networking

> Make sure your app has AppTransportSecurity settings to allow HTTP access to the `https://main-rpc.linkpool.io` domain.

## Custom Networking Layer

By default, this library uses the native iOS networking API to connect to the internet. If you want the library to use your own networking layer instead, you must conform your networking layer to the `NetworkingLayer` protocol. This protocol requires only one method to be implemented: `makeHttpPostRequest(url:, httpMethod:, httpHeaderContentType:, httpBody:, completion:)`. Using this method will bypass the default behavior and delegate the request to your own networking code.

For example, construct the Resolution instance like so:

```swift
guard let resolution = try? Resolution(networking: MyNetworkingApi) else {
  print ("Init of Resolution instance failed...")
  return
}
```

# Possible Errors:

If the domain you are attempting to resolve is not registered or doesn't contain the information you are requesting, this framework will return a `ResolutionError` with the possible causes below. We advise creating customized errors in your app based on the return value of the error.

```swift
enum ResolutionError: Error {
  case unregisteredDomain
  case unsupportedDomain
  case recordNotFound
  case recordNotSupported
  case unsupportedNetwork
  case unspecifiedResolver
  case unknownError(Error)
  case proxyReaderNonInitialized
  case inconsistentDomainArray
  case methodNotSupported
}
```

Please see the [Resolution-Swift Error Codes](https://docs.unstoppabledomains.com/developer-toolkit/resolution-integration-methods/resolution-libraries/resolution-swift/#error-codes) page for details of the specific error codes.

# Contributions

Contributions to this library are more than welcome. The easiest way to contribute is through GitHub issues and pull requests.


# Free advertising for integrated apps

Once your app has a working Unstoppable Domains integration, [register it here](https://unstoppabledomains.com/app-submission). Registered apps appear on the Unstoppable Domains [homepage](https://unstoppabledomains.com/) and [Applications](https://unstoppabledomains.com/apps) page — putting your app in front of tens of thousands of potential customers per day.

Also, every week we select a newly-integrated app to feature in the Unstoppable Update newsletter. This newsletter is delivered to straight into the inbox of ~100,000 crypto fanatics — all of whom could be new customers to grow your business.

# Get help
[Join our discord community](https://discord.gg/unstoppabledomains) and ask questions.

# Help us improve

We're always looking for ways to improve how developers use and integrate our products into their applications. We'd love to hear about your experience to help us improve by [taking our survey](https://form.typeform.com/to/uHPQyHO6).
