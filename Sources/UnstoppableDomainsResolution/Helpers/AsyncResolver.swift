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
        let results = try resolve(listOfFunc: [listOfFunc[0], listOfFunc[1], listOfFunc[2]])
        return try parseResult(results)
    }

    func resolve<T>(
            listOfFunc: Array<GeneralFunction<T>>
        ) throws -> [UNSLocation: AsyncConsumer<T>] {
            var results: [UNSLocation: AsyncConsumer<T>] = [:]
            let functions: [UNSLocation: GeneralFunction<T>] = [
                .layer2: listOfFunc[1], .layer1: listOfFunc[0], .zlayer: listOfFunc[2]
            ]
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
        let l2Result = Utillities.getLayerResultWrapper(from: results, for: .layer2)
        let l1Result = Utillities.getLayerResultWrapper(from: results, for: .layer1)
        let zResult = Utillities.getLayerResultWrapper(from: results, for: .zlayer)
        
        print("L2RESULT", l2Result)
        print("L1RESULT", l1Result)
        print("ZRESULT", zResult)

        if let l2error = l2Result.1 {
            if !isUnregisteredDomain(error: l2error) {
                throw l2error
            }
        } else {
            if let l2answer = l2Result.0 {
                return l2answer
            }
        }
        
        if let l1error = l1Result.1 {
            if !isUnregisteredDomain(error: l1error) {
                throw l1error
            }
        } else {
            if let l1answer = l1Result.0 {
                return l1answer
            }
        }

        if let zerror = zResult.1 {
            throw zerror
        }

        return zResult.0!
    }

    private func isUnregisteredDomain(error: Error?) -> Bool {
        if let error = error as? ResolutionError {
            if case ResolutionError.unregisteredDomain = error {
                return true
            }
        }
        return false
    }
}
