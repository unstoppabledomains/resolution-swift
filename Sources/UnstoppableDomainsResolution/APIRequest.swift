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
                              completion: @escaping(Result<JsonRpcResponseArray, Error>) -> Void)
    func makeHttpGetRequest(url: URL, completion: @escaping TokenUriMetadataResultConsumer )

    mutating func addHeader(header: String, value: String)
}

struct APIRequest {
    let url: URL
    let networking: NetworkingLayer

    init(_ endpoint: String, networking: NetworkingLayer) {
        self.url = URL(string: endpoint)!
        self.networking = networking
    }

    func post(_ body: JsonRpcPayload, completion: @escaping(Result<JsonRpcResponseArray, Error>) -> Void ) throws {
        do {
            networking.makeHttpPostRequest(url: self.url,
                                           httpMethod: "POST",
                                           httpHeaderContentType: "application/json",
                                           httpBody: try JSONEncoder().encode(body),
                                           completion: completion)
        } catch { throw APIError.encodingError }
    }

    func post(_ bodyArray: [JsonRpcPayload], completion: @escaping(Result<JsonRpcResponseArray, Error>) -> Void ) throws {
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
    var headers: [String: String] = [String: String]()

    public init() { }

    public func makeHttpPostRequest(url: URL,
                                    httpMethod: String,
                                    httpHeaderContentType: String,
                                    httpBody: Data,
                                    completion: @escaping(Result<JsonRpcResponseArray, Error>) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod
        urlRequest.addValue(httpHeaderContentType, forHTTPHeaderField: "Content-Type")

        if (!self.headers.isEmpty) {
            for (_, keyValue) in self.headers.enumerated() {
                urlRequest.addValue(keyValue.value, forHTTPHeaderField: keyValue.key)
            }
        }

        urlRequest.httpBody = httpBody

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let jsonData = data
            else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode

                if (statusCode == 401 || statusCode == 403) {
                    completion(.failure(ResolutionError.unauthenticatedRequest))
                    return
                }

                if (statusCode == 429) {
                    completion(.failure(ResolutionError.requestBeingRateLimited))
                    return
                }

                completion(.failure(APIError.responseError))
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
                    if let errorResponse = try? JSONDecoder().decode(NetworkErrorResponse.self, from: jsonData),
                       let errorExplained = ResolutionError.parse(errorResponse: errorResponse) {
                        completion(.failure(errorExplained))
                    } else {
                        completion(.failure(APIError.decodingError))
                    }
                }
            }
        }
        dataTask.resume()
    }

    public func makeHttpGetRequest(url: URL, completion: @escaping TokenUriMetadataResultConsumer ) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let jsonData = data else {
                completion(.failure(ResolutionError.badRequestOrResponse))
                return
            }

            do {
                let result = try JSONDecoder().decode(TokenUriMetadata.self, from: jsonData)
                completion(.success(result))
            } catch {
                completion(.failure(ResolutionError.badRequestOrResponse))
            }
        }
        dataTask.resume()
    }

    public mutating func addHeader(header: String, value: String) {
        self.headers[header] = value
    }
}
