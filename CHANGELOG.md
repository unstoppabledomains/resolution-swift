### 0.3.5
 * Introduce DomainResolution#getMultiChainAddress general method to fetch a ticker address from specific chain
 * Deprecate DomainResolution#getUsdt method in favor of DomainResolution#getMultiChainAddress
 
- General multichain support ([#33](https://github.com/unstoppabledomains/resolution-swift/pull/33)) via [@JohnnyJumper](https://github.com/JohnnyJumper)
- Auto network ([#32](https://github.com/unstoppabledomains/resolution-swift/pull/32)) via [@JohnnyJumper](https://github.com/JohnnyJumper)
- Move Base58 lib from dependencies to internal sources.

### 0.3.0 
- [Customizing naming services](https://github.com/unstoppabledomains/resolution-swift#customizing-naming-services)
Version 0.3.0 introduced the `Configurations` struct that is used for configuring each connected naming service.
Library can offer three naming services at the moment:

* `cns` resolves `.crypto` domains,
* `ens` resolves `.eth` domains,
* `zns` resolves `.zil` domains

*By default, each of them is using the mainnet network via infura provider. 
Unstoppable domains are using the infura key with no restriction for CNS.
Unstoppable domains recommends setting up your own provider for ENS, as we don't guarantee ENS Infura key availability. 
You can update each naming service separately*

- Update keys ([#30](https://github.com/unstoppabledomains/resolution-swift/pull/30)) via [@JohnnyJumper](https://github.com/JohnnyJumper)
- Change ABI codec dependency ([#31](https://github.com/unstoppabledomains/resolution-swift/pull/31)) via [@merenkoff](https://github.com/merenkoff)

### 0.2.0
- Added correct initialization of Resolution object if `rinkeby` test network used([#27](https://github.com/unstoppabledomains/resolution-swift/pull/27)) via [@merenkoff](https://github.com/merenkoff)
- Dns records support ([#25](https://github.com/unstoppabledomains/resolution-swift/pull/25)) via [@JohnnyJumper](https://github.com/JohnnyJumper)
- Resolution#usdt ([#26](https://github.com/unstoppabledomains/resolution-swift/pull/26)) via [@JohnnyJumper](https://github.com/JohnnyJumper)
- CNS supports both `mainnet` and `rinkeby` from network-config.json file ([#23](https://github.com/unstoppabledomains/resolution-swift/pull/23)) via [@rommex](https://github.com/rommex)
- BadRequestOrResponse is Handled ([#21](https://github.com/unstoppabledomains/resolution-swift/pull/21)) via [@rommex](https://github.com/rommex)
- Proxy reader 2 0 support ([#22](https://github.com/unstoppabledomains/resolution-swift/pull/22)) via [@rommex](https://github.com/rommex)

### 0.1.6
- Downgrade minimum support version ([#20](https://github.com/unstoppabledomains/resolution-swift/pull/20)) via [@vladyslav-iosdev](https://github.com/vladyslav-iosdev)
- iOS11 support in swiftPM

### 0.1.4
- Batch Request for owners of domains

### 0.1.2
- Ininial release