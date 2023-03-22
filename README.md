# UnstoppableDomainsResolution

[![Get help on Discord](https://img.shields.io/badge/Get%20help%20on-Discord-blueviolet)](https://discord.gg/b6ZVxSZ9Hn)
[![Unstoppable Domains Documentation](https://img.shields.io/badge/Documentation-unstoppabledomains.com-blue)](https://docs.unstoppabledomains.com/)

Resolution is a library for interacting with blockchain domain names. It can be used to retrieve payment addresses and IPFS hashes for decentralized websites.

Resolution is primarily built and maintained by [Unstoppable Domains](https://unstoppabledomains.com/).

- [Installing Resolution](#installing-resolution-swift)
- [Using Resolution](#using-resolution)
- [Contributions](#contributions)
- [Free advertising for integrated apps](#free-advertising-for-integrated-apps)

# Installing resolution-swift

## Cocoa Pods

```ruby
pod 'UnstoppableDomainsResolution', '~> 6.0.0'
```

## Swift Package Manager

```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "6.0.0")
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

# Using Resolution

 - Create an instance of the Resolution class
 - Call any method of the Resolution class asyncronously

> NOTE: make sure an instance of the Resolution class is not deallocated until the asyncronous call brings in the result. Your code is the **only owner** of the instance so keep it as long as you need it.

## Initialize with Unstoppable Domains' Proxy Provider

```swift
import UnstoppableDomainsResolution

// obtain a key from https://unstoppabledomains.com/partner-api-dashboard if you are a partner
guard let resolution = try? Resolution(apiKey: "<api_key>") else {
  print ("Init of Resolution instance failed...")
  return
}
```

> NOTE: The `apiKey` is only used resolve domains from UNS. Behind the scene, it still uses the default ZNS (Zilliqa) RPC url. For additional control, please specify your ZNS configuration.

```swift
import UnstoppableDomainsResolution

// obtain a key from https://unstoppabledomains.com/partner-api-dashboard if you are a partner
guard let resolution = try? Resolution(
  apiKey: "<api_key>",
  znsLayer: NamingServiceConfig(
    providerUrl: "https://api.zilliqa.com",
    network: "mainnet")
) else {
  print ("Init of Resolution instance with default parameters failed...")
  return
}
```

## Initialize with Custom Ethereum Configuration

The `Configurations` struct that is used for configuring each connected naming service.
Library supports three networks at the moment Ethereum, Polygon and Zilliqa. You can update each network separately.

```swift
import UnstoppableDomainsResolution

// obtain a key from https://www.infura.io
let resolution = try Resolution(configs: Configurations(
        uns: UnsLocations = UnsLocations(
            layer1: NamingServiceConfig(
                providerUrl: "https://mainnet.infura.io/v3/<infura_api_key>",
                network: "mainnet"),
            layer2: NamingServiceConfig(
                providerUrl: "https://polygon-mainnet.infura.io/v3/<infura_api_key>",
                network: "polygon-mainnet"),
            zlayer: NamingServiceConfig(
                providerUrl: "https://api.zilliqa.com",
                network: "mainnet")
        )
);

```

## Examples

### Getting a domain's crypto address
```swift
resolution.addr(domain: "brad.crypto", ticker: "eth") { (result) in
    switch result {
    case .success(let returnValue):
        ethAddress = returnValue
        domainReceived.fulfill()
    case .failure(let error):
        XCTFail("Expected Eth Address, but got \(error)")
    }
}
```

### Batch requesting of owners

the `batchOwners(domains: _, completion: _ )` method adds additional convenience when making multiple domain owner queries.

> This method is only compatible with uns-based domains. Using this method with any other domain type will throw the error: `ResolutionError.methodNotSupported`.

As opposed to the single `owner(domain: _, completion: _)` method, this batch request will return an array of owners `[String?]`. If the the domain is not registered or its value is `null`, the corresponding array element of the response will be `nil` without throwing an error.

```swift
resolution.batchOwners(domains: ["brad.crypto", "homecakes.crypto"]) { result in
  switch result {
  case .success(let returnValue):
    // returnValue: [String: String?] = <map of domains to owner address>
    let domainOwner = returnValue
  case .failure(let error):
    XCTFail("Expected owner, but got \(error)")
  }
}

resolution.locations(domains: ["brad.crypto", "homecakes.crypto"]) { result in
  switch result {
  case .success(let returnValue):
    // returnValue: [String: String?] = <map of domains to domain locations>
    let locations = returnValue
  case .failure(let error):
    XCTFail("Expected owner, but got \(error)")
  }
}
```

## Networking

> Make sure your app has AppTransportSecurity settings to allow HTTP access to the `https://main-rpc.linkpool.io` domain.

### Custom Networking Layer

By default, this library uses the native iOS networking API to connect to the internet. If you want the library to use your own networking layer instead, you must conform your networking layer to the `NetworkingLayer` protocol. This protocol requires three methods to be implemented: 
* `func makeHttpPostRequest(url:, httpMethod:, httpHeaderContentType:, httpBody:, completion:)`
* `func makeHttpGetRequest(url: URL, completion:)`
* `mutating func addHeader(header: String, value: String)`

Using these methods will bypass the default behavior and delegate the request to your own networking code.

For example, construct the Resolution instance like so:

```swift
let customNetworking = MyNetworkingApi()
let resolution = try Resolution(configs: Configurations(
        uns: UnsLocations = UnsLocations(
            layer1: NamingServiceConfig(
                providerUrl: "https://mainnet.infura.io/v3/<infura_api_key>",
                network: "mainnet",
                networking: customNetworking),
            layer2: NamingServiceConfig(
                providerUrl: "https://polygon-mainnet.infura.io/v3/<infura_api_key>",
                network: "polygon-mainnet",
                networking: customNetworking),
            zlayer: NamingServiceConfig(
                providerUrl: "https://api.zilliqa.com",
                network: "mainnet")
        )
);
```

## Possible Errors:

If the domain you are attempting to resolve is not registered or doesn't contain the information you are requesting, this framework will return a `ResolutionError` with the possible causes below. We advise creating customized errors in your app based on the return value of the error.

```swift
enum ResolutionError: Error {
    case unregisteredDomain
    case unsupportedDomain
    case recordNotFound
    case recordNotSupported
    case unsupportedNetwork
    case unspecifiedResolver
    case unknownError
    case proxyReaderNonInitialized
    case registryAddressIsNotProvided
    case inconsistentDomainArray
    case methodNotSupported
    case tooManyResponses
    case executionReverted
    case badRequestOrResponse
    case unsupportedServiceName
    case invalidDomainName
    case contractNotInitialized
    case reverseResolutionNotSpecified
    case unauthenticatedRequest
    case requestBeingRateLimited
}
```

Please see the [Resolution-Swift Error Codes](https://docs.unstoppabledomains.com/developer-toolkit/resolution-integration-methods/resolution-libraries/resolution-swift/#error-codes) page for details of the specific error codes.

# Contributions

Contributions to this library are more than welcome. The easiest way to contribute is through GitHub issues and pull requests.

## Build & test

Resolution library relies on environment variables to load TestNet RPC Urls. This way, our keys don't expose directly to the code. These environment variables are:

* L1_TEST_NET_RPC_URL
* L2_TEST_NET_RPC_URL

Use `swift build` to build, and `swift test -v` to run the tests

# Free advertising for integrated apps

Once your app has a working Unstoppable Domains integration, [register it here](https://unstoppabledomains.com/app-submission). Registered apps appear on the Unstoppable Domains [homepage](https://unstoppabledomains.com/) and [Applications](https://unstoppabledomains.com/apps) page — putting your app in front of tens of thousands of potential customers per day.

Also, every week we select a newly-integrated app to feature in the Unstoppable Update newsletter. This newsletter is delivered to straight into the inbox of ~100,000 crypto fanatics — all of whom could be new customers to grow your business.

# Get help
[Join our discord community](https://discord.gg/unstoppabledomains) and ask questions.

# Help us improve

We're always looking for ways to improve how developers use and integrate our products into their applications. We'd love to hear about your experience to help us improve by [taking our survey](https://form.typeform.com/to/uHPQyHO6).
