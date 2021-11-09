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
        l1func: @escaping @autoclosure GeneralFunction<T>,
        l2func: @escaping @autoclosure GeneralFunction<T>
    ) throws -> T {
        let results = try resolve(l1func: l1func(), l2func: l2func())
        return try parseResult(results)
    }

    func resolve<T>(
        l1func: @escaping @autoclosure GeneralFunction<T>,
        l2func: @escaping @autoclosure GeneralFunction<T>
    ) throws -> [UNSLocation: AsyncConsumer<T>] {
        var results: [UNSLocation: AsyncConsumer<T>] = [:]
        let functions: [UNSLocation: GeneralFunction<T>] = [.layer2: l2func, .layer1: l1func]
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
            throw l1error
        }
        return l1Result.0!
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
