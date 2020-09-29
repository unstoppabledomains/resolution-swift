//
//  APIRequest.swift
//  resolution
//
//  Created by Johnny Good on 8/19/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

enum APIError: Error {
    case responseError
    case decodingError
    case encodingError
}

struct APIRequest {
    let url: URL

    init(_ endpoint: String) {
        guard let url = URL(string: endpoint) else {fatalError()}
        self.url = url
    }

    func post(_ body: JsonRpcPayload, completion: @escaping(Result<JsonRpcResponse, APIError>) -> Void ) {
        do {
            var urlRequest = URLRequest(url: self.url)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(body)

            let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, _ in
                guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                    let jsonData = data else {
                        completion(.failure(.responseError))
                        return
                }

                do {
                    let result = try JSONDecoder().decode(JsonRpcResponse.self, from: jsonData)
                    completion(.success(result))
                } catch {
                    completion(.failure(.decodingError))
                }
            }
            dataTask.resume()
        } catch {
            completion(.failure(.encodingError))
        }
    }

}
