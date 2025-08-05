//
//  WebEnvironment.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//
import Foundation

/// A convenient wrapper for various standard values.
struct WebEnvironment {
        
    /// A shared URL Session with a default configuration.
    static var standardUrlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    /// The base URL for most web requests.
    static var baseURL: URL {
        return URL(string: "https://dog.ceo/api")!
    }
    
    /// The default timeout for web requests.
    static var timeout: TimeInterval = 10
    
    /// The default HTTP headers to apply to web requests.
    static var defaultHeaders: [String: String]? {
        return nil
    }
    
}
