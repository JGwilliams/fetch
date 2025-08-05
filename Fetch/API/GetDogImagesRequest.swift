//
//  GetDogImagesRequest.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import Foundation

struct GetDogImagesRequest: APIRequest {
    let breed: String
    let subbreed: String?
    let count: Int
    
    typealias ResponseType = DogImageList
    var path: String {
        if let subbreed = subbreed {
            return "breed/\(breed.lowercased())/\(subbreed.lowercased())/images/random/\(count)"
        } else {
            return "breed/\(breed.lowercased())/images/random/\(count)"
        }
    }
    var returnOnMainThread: Bool { return true }
}

struct DogImageList: Decodable {
    let images: [DogImage]
    
    enum CodingKeys: CodingKey {
        case message
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decode([String].self, forKey: .message).compactMap {
            guard let url = URL(string: $0) else { return nil }
            return DogImage(url: url)
        }
    }
}

struct DogImage: Identifiable {
    let id = UUID()
    let url: URL
}
