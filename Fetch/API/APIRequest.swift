//
//  APIRequest.swift
//  Testbed
//
//  Created by Jonathan Gwilliams on 12/03/2020.
//  Copyright © 2020 Jonathan Gwilliams. All rights reserved.
//

import Foundation

/// An enumeration defining whether a web request succeeded or failed.
/// A success contains the response value, while a failure contains the error.
/// `noData` is a special success case for calls with no response.
indirect enum APIResult<R: Decodable> {
    case noData // Some services can legitimately return no data
    case success(R)
    case failure(Error)
}

/// An enumeration of standard HTTP methods. Use `name` to access the all-caps version.
enum HTTPMethod: String {
    case get
    case head
    case post
    case put
    case delete
    case connect
    case options
    case trace
    case patch
    
    /// The standard uppercase version of the method name.
    var name: String { return "\(self)".uppercased() }
}

/// Errors that could occur during a request.
enum WebRequestError: LocalizedError, Equatable {
    case httpError(Int)
    case nilResponse
    case noDataReturned
    
    var errorDescription: String? {
        switch self {
        case .httpError(let value): return "HTTP error code \(value)"
        case .nilResponse: return "no HTTP response code"
        case .noDataReturned: return "no data"
        }
    }
    
    static func ==(lhs: WebRequestError, rhs: WebRequestError) -> Bool {
        switch (lhs, rhs) {
        case (httpError(let a), httpError(let b)):
            return a == b
        case (nilResponse, nilResponse),
            (noDataReturned, noDataReturned):
            return true
        default: return false
        }
    }
    
}

/**
 This protocol represents the basic web request. It provides defaults for all items that have common
 values, such as the base URL or the period to wait before timing out. It also provides the standard
 functions required to execute the request.
 
 To use, conform to this protocol - a `struct` is sufficient for this - and provide a`path` and a
 `ResponseType`. Other values may be overridden as required by the individual call.
 */
protocol APIRequest {
    associatedtype ResponseType: Decodable
    
    /// The timeout interval of the call. Defaults to 30 seconds
    var timeout: TimeInterval { get }
    
    /// The standard HTTP method of the call, i.e. GET or POST. Defaults to GET.
    var method: HTTPMethod { get }
    
    /// Any HTTP headers required by the call should be passed here as a dictionary. The key is
    /// the name of the header, while the associated value is its content. Defaults to nil.
    var headers: [String: String]? { get }
    
    /// The base URL for the call. This makes it easy to change servers if necessary. Defaults to
    /// `https://dog.ceo/api`
    var baseUrl: URL { get }
    
    /// The path of the request. Appended to the end of the base URL to produce the full URL.
    var path: String { get }
    
    /// Parameters to append to the end of the path. These are prefixed with `?` and joined together
    /// with `&` characters as is standard.
    var parameters: [String: String]? { get }
    
    /// The body to associate with the web request. Defaults to nil.
    var body: Data? { get }
        
    /// If true, completion is automatically performed on the main thread. Defaults to false.
    var returnOnMainThread: Bool { get }
}

extension APIRequest {
    
    // Default values
    var timeout: TimeInterval { return WebEnvironment.timeout }
    var method: HTTPMethod { return .get }
    var headers: [String: String]? { return WebEnvironment.defaultHeaders }
    var baseUrl: URL { return WebEnvironment.baseURL }
    var parameters: [String: String]? { return nil }
    var body: Data? { return nil }
    var returnOnMainThread: Bool { return false }
    
    /// Returns a ready-to-use `URL` for the request
    var fullUrl: URL {
        // Assemble from the base URL, path and any parameters
        let url = baseUrl.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if let parameters = parameters {
            components.queryItems = parameters.map {
                URLQueryItem(name: $0.0, value: $0.1)
            }
        }
        
        return components.url!
    }
    
    /// Generates a `URLRequest` for this request
    var request: URLRequest {
        // Create the request with the correct URL and timeout
        var request = URLRequest(url: fullUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        
        // Add any required headers
        request.setValue("true", forHTTPHeaderField: "isREST")
        if let headers = headers {
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        // Configure the rest of the request
        request.httpMethod = method.name
        request.httpBody = body
        print("Executing request \(request.url?.description ?? "<None>")")
        return request
    }
        
    private func validateResponse(response: URLResponse?, error: Error? ) throws {
        // Check to see if an error was returned
        if let error = error {
            print("Error executing request: \(error.localizedDescription)")
            throw error
        }
        
        // Check for invalid HTTP response codes
        guard let response = response as? HTTPURLResponse else {
            throw WebRequestError.nilResponse
        }
        
        if !(200 ..< 300).contains(response.statusCode) {
            throw WebRequestError.httpError(response.statusCode)
        }
    }
    
    /**
     Call this function to execute the request. Make sure that you retain a reference to the object
     before doing so. The completion block will be called with an appropriate `WebResult`.
     Note that the `WebResponse` encapsulated by successful results will vary in type based
     upon the `ResponseType` associated value of the request.
     **/
    @discardableResult func start(on session: URLSession, completion: @escaping (APIResult<ResponseType>) -> Void) -> URLSessionTask {
        let task = session.dataTask(with: request) { (data, response, error) in
            // Convert the data into the correct response
            do {
                try self.validateResponse(response: response, error: error)
                
                // Check for nil data
                if data == nil {
                    throw WebRequestError.noDataReturned
                }
                
                // Formulate an appropriate response
                if let data = data, !data.isEmpty {
                    let response = try JSONDecoder().decode(ResponseType.self, from: data)
                    self.complete(for: .success(response), completion: completion)
                } else {
                    self.complete(for: .noData, completion: completion)
                }
            } catch let error {
                 // Thrown errors are simply passed to completion
                self.complete(for: .failure(error), completion: completion)
            }
        }
        task.resume()
        return task
    }
    
    private func complete(for result: APIResult<ResponseType>, completion: @escaping (APIResult<ResponseType>) -> Void) {
        if returnOnMainThread {
            DispatchQueue.main.async { completion(result) }
        } else {
            completion(result)
        }
    }
    
}

