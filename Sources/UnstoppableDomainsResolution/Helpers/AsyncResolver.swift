//
//  AsyncResolver.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 9/9/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

 import Foundation

internal class AsyncResolver {

    typealias GeneralFunction<T> = () throws -> T

    let asyncGroup = DispatchGroup()

    func safeResolve<T>(
        listOfFunc: Array<GeneralFunction<T>>
    ) throws -> T {
        let results = try resolve(listOfFunc: listOfFunc)
        return try parseResult(results)
    }

    func resolve<T>(
            listOfFunc: Array<GeneralFunction<T>>
        ) throws -> [UNSLocation: AsyncConsumer<T>] {
            var results: [UNSLocation: AsyncConsumer<T>] = [:]
            var functions: [UNSLocation: GeneralFunction<T>] = [
                .layer2: listOfFunc[1], .layer1: listOfFunc[0]
            ]
            
            if (listOfFunc.count > 2) {
                functions[.znsLayer] = listOfFunc[2]
            }
            
            let queue = DispatchQueue(label: "LayerQueque")
            functions.forEach { function in
                self.asyncGroup.enter()
                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }
                    do {
                        let value = try function.value()
                        queue.sync {
                            results[function.key] = (value, nil)
                        }
                    } catch {
                        queue.sync {
                            results[function.key] = (nil, error)
                        }
                    }
                    self.asyncGroup.leave()
                }
            }
            let semaphore = DispatchSemaphore(value: 0)
            self.asyncGroup.notify(queue: .global()) {
                semaphore.signal()
            }
            semaphore.wait()
            return results
        }


    private func parseResult<T>(_ results: [UNSLocation: AsyncConsumer<T>] ) throws -> T {
        // filter out results that were not provided (in case some methods are not supported by some providers)
        let resultsOrder = [UNSLocation.layer2, UNSLocation.layer1, UNSLocation.znsLayer].filter { v in results.keys.contains(v) }
        
        // Omit the last result since we would have to return it regardless
        for resultKey in resultsOrder.dropLast() {
            let result = results[resultKey]!
            
            if let error = result.1 {
                if !Utillities.isUnregisteredDomain(error: error) {
                    throw error
                }
            } else if let answer = result.0 {
                return answer
            }
        }
        
        let result = results[resultsOrder.last!]!
        
        if let error = result.1 {
            throw error
        }
        return result.0!
    }
}
