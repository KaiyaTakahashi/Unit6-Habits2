//
//  APIRequest.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

protocol APIRequest {
    associatedtype Response
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
    var postData: Data? { get }
}

extension APIRequest {
    var host: String { "localhost" }
    var port: Int { 8080 }
}

extension APIRequest {
    var queryItems: [URLQueryItem]? { nil }
    var postData: Data? { nil }
}

extension APIRequest {
    var request: URLRequest {
        var componets = URLComponents()
        
        componets.scheme = "http"
        componets.host = host
        componets.port = port
        componets.path = path
        componets.queryItems = queryItems
        
        var request = URLRequest(url: componets.url!)
        
        if let data = postData {
            request.httpMethod  = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

enum APIRequestError: Error {
    case itemsNotFound
    case requestFalied
}

extension APIRequest where Response: Decodable {
    func send() async throws -> Response {
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIRequestError.itemsNotFound
        }

        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(Response.self, from: data)
        
        return decodedData
    }
}

extension APIRequest {
    func send() async throws -> Void {
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIRequestError.requestFalied
        }
    }
}

enum ImageRequestError: Error {
    case couldNotInitialisedFromData
    case imageDataMissing
}

extension APIRequest where Response == UIImage {
    func send() async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ImageRequestError.imageDataMissing
        }
        guard let image = UIImage(data: data) else {
            throw ImageRequestError.couldNotInitialisedFromData
        }
        
        return image
    }
}
