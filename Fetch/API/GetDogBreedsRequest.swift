//
//  GetDogBreedsRequest.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import Foundation

struct GetDogBreedsRequest: APIRequest {
    typealias ResponseType = DogBreedList
    var path: String { return "breeds/list/all" }
    var returnOnMainThread: Bool { return true }
}

struct DogBreedList: Decodable {
    let breeds: [DogBreed]
    let status: String
    
    enum CodingKeys: CodingKey {
        case message
        case status
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let breedDictionary = try container.decode([String : [String]].self, forKey: .message)
        
        // To be compatible with SwiftUI hierarchic lists, we convert the dictionary
        // of dog breeds into a hierarchic array.
        self.breeds = breedDictionary.map({ key, value in
            
            // If there are no subbreeds, ensure that the hierarchy ends here
            if value.isEmpty {
                return DogBreed(name: key.sentenceCased(), parent: nil, subBreeds: nil)
            }
            
            // Map and sort the subbreed array
            let subbreeds = value.map { DogBreed(name: $0.sentenceCased(), parent: key, subBreeds: nil) }
                .sorted(by: { $0.name < $1.name })
            
            // Return a dog breed with a child array of subbreeds
            return DogBreed(name: key.sentenceCased(), parent: nil, subBreeds: subbreeds)
        })
        .sorted(by: { $0.name < $1.name })
        
        self.status = try container.decode(String.self, forKey: .status)
    }
    
    /// Segments the dog breed list by the initial letter
    func splitIntoSections() -> [AlphabeticSection] {
        var result = [AlphabeticSection]()
        var sectionBreeds = [DogBreed]()
        var currentLetter: String.Element?
        
        for breed in breeds {
            if currentLetter == nil {
                currentLetter = breed.name.first
            }
            
            if currentLetter != breed.name.first {
                let section = AlphabeticSection(character: currentLetter!, breeds: sectionBreeds)
                result.append(section)
                sectionBreeds = [breed]
                currentLetter = breed.name.first
            } else {
                sectionBreeds.append(breed)
            }
        }
        
        let section = AlphabeticSection(character: currentLetter!, breeds: sectionBreeds)
        result.append(section)
        return result
    }
}

struct AlphabeticSection: Identifiable {
    let id = UUID()
    let character: String.Element
    let breeds: [DogBreed]
}

struct DogBreed: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let parent: String?
    let subBreeds: [DogBreed]?
    
    func detailView() -> DogBreedDetailView {
        if let parent = parent {
            DogBreedDetailView(breed: parent, subbreed: name)
        } else {
            DogBreedDetailView(breed: name, subbreed: nil)
        }
    }
    
    func matches(_ term: String) -> DogBreed? {
        if name.lowercased().contains(term) {
            return self
        }
        
        if let subBreeds = subBreeds {
            let validSubbreeds = subBreeds.compactMap {
                $0.matches(term)
            }
            if !validSubbreeds.isEmpty {
                return DogBreed(name: name, parent: parent, subBreeds: validSubbreeds)
            }
        }
        
        return nil
    }
}
