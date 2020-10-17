//
//  APIRequest.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public enum APIError: Error {
    case responseError
    case decodingError
    case encodingError
}

public typealias JsonRpcResponseArray = [JsonRpcResponse]

public protocol NetworkingLayer {
    func makeHttpPostRequest (url: URL,
                              httpMethod: String,
                              httpHeaderContentType: String,
                              httpBody: Data,
                              completion: @escaping(Result<JsonRpcResponseArray, APIError>) -> Void)
}

struct APIRequest {
    let url: URL
    let networking: NetworkingLayer

    init(_ endpoint: String, networking: NetworkingLayer) {
        guard let url = URL(string: endpoint) else {fatalError()}
        self.url = url
        self.networking = networking
    }

    func post(_ body: JsonRpcPayload, completion: @escaping(Result<JsonRpcResponseArray, APIError>) -> Void ) throws {
        do {
            networking.makeHttpPostRequest(url: self.url,
                                           httpMethod: "POST",
                                           httpHeaderContentType: "application/json",
                                           httpBody: try JSONEncoder().encode(body),
                                           completion: completion)
        } catch { throw APIError.encodingError }
    }
    
    func post(_ bodyArray: [JsonRpcPayload], completion: @escaping(Result<JsonRpcResponseArray, APIError>) -> Void ) throws {
        do {
            networking.makeHttpPostRequest(url: self.url,
                                           httpMethod: "POST",
                                           httpHeaderContentType: "application/json",
                                           httpBody: try JSONEncoder().encode(bodyArray),
                                           completion: completion)
        } catch { throw APIError.encodingError }
    }
}

public struct DefaultNetworkingLayer: NetworkingLayer {
    public init() { }
    
    public func makeHttpPostRequest(url: URL,
                                    httpMethod: String,
                                    httpHeaderContentType: String,
                                    httpBody: Data,
                                    completion: @escaping(Result<JsonRpcResponseArray, APIError>) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod
        urlRequest.addValue(httpHeaderContentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = httpBody
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let jsonData = data else {
                completion(.failure(.responseError))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(JsonRpcResponseArray.self, from: jsonData)
                completion(.success(result))
            } catch {
                do {
                    let result = try JSONDecoder().decode(JsonRpcResponse.self, from: jsonData)
                    completion(.success([result]))
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }
        dataTask.resume()
    }
}
