//
//  AsyncResolver.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 9/9/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

 import Foundation

internal class AsyncResolver {

    typealias ResultConsumer<T> = (T?, Error?)
    typealias GenericFunction<T, U> = (_: T) throws -> (_: U)
    typealias GenericFunctionTwoArgs<T, U, Z> = (_: T, _: U) throws -> (_: Z)

    let asyncGroup = DispatchGroup()

    func safeResolve<T, U>(l1func: @escaping GenericFunction<T, U>, l2func: @escaping GenericFunction<T, U>, arg: T) throws -> U {
        let results = try resolve(l1func: l1func, l2func: l2func, arg: arg)
        return try parseResult(results)
    }

    // had to duplicate the below function due to limitation of swift language for function typings.
    func safeResolve<T, U, Z>(l1func: @escaping GenericFunctionTwoArgs<T, U, Z>, l2func: @escaping GenericFunctionTwoArgs<T, U, Z>, arg1: T, arg2: U) throws -> Z {
        let results = try resolve(l1func: l1func, l2func: l2func, arg1: arg1, arg2: arg2)
        return try parseResult(results)
    }

    // had to duplicate the below function due to limitation of swift language for function typings.
    func resolve<T, U, Z>(l1func: @escaping GenericFunctionTwoArgs<T, U, Z>, l2func: @escaping GenericFunctionTwoArgs<T, U, Z>, arg1: T, arg2: U) throws -> [UNSLocation: ResultConsumer<Z>] {
        var results: [UNSLocation: ResultConsumer<Z>] = [:]
        let functions: [UNSLocation: GenericFunctionTwoArgs<T, U, Z>] = [.layer2: l2func, .layer1: l1func]

        functions.forEach { function in
            self.asyncGroup.enter()
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                do {
                    let value = try function.value(arg1, arg2)
                    results[function.key] = (value, nil)
                    self.asyncGroup.leave()
                } catch {
                    results[function.key] = (nil, error)
                    self.asyncGroup.leave()
                }
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        self.asyncGroup.notify(queue: .global()) {
            semaphore.signal()
        }
        semaphore.wait()
        return results
    }

    func resolve<T, U>(l1func: @escaping GenericFunction<T, U>, l2func: @escaping GenericFunction<T, U>, arg: T) throws -> [UNSLocation: ResultConsumer<U>] {
        var results: [UNSLocation: ResultConsumer<U>] = [:]
        let functions: [UNSLocation: GenericFunction<T, U>] = [.layer2: l2func, .layer1: l1func]

        functions.forEach { function in
            self.asyncGroup.enter()
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                do {
                    let value = try function.value(arg)
                    results[function.key] = (value, nil)
                    self.asyncGroup.leave()
                } catch {
                    results[function.key] = (nil, error)
                    self.asyncGroup.leave()
                }
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        self.asyncGroup.notify(queue: .global()) {
            semaphore.signal()
        }
        semaphore.wait()
        return results
    }

    private func parseResult<T>(_ results: [UNSLocation: ResultConsumer<T>] ) throws -> T {
        let l2Result = results[.layer2]!
        let l1Result = results[.layer1]!

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
