//
//  DogBreedListView.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import SwiftUI

struct DogBreedListView: View {
    @State private var searchText: String = ""
    @State private var fetchTask: URLSessionTask?
    @State private var dogBreeds: [AlphabeticSection] = []
    @State private var filteredDogBreeds: [AlphabeticSection] = []
    @State private var showAlert = false
    @State private var error: Error? = nil
    
    var body: some View {
        VStack {
            List(filteredDogBreeds) {
                section in
                Section(header:  Text(String(section.character))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                ) {
                    OutlineGroup(section.breeds, children: \.subBreeds) {
                        subbreed in
                        NavigationLink {
                            subbreed.detailView()
                        } label: {
                            Text(subbreed.name)
                        }
                    }
                }
            }
            .refreshable {
                reloadContent()
            }
            .navigationTitle("Dog Breeds")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(error?.localizedDescription ?? "Unknown error occurred."))
            }
        }
        .padding()
        .task {
            reloadContent()
        }
        .onChange(of: searchText) {
            filterContent()
        }
    }
    
    func reloadContent() {
        self.fetchTask = GetDogBreedsRequest().start(on: WebEnvironment.standardUrlSession, completion: { response in
            switch response {
            case .noData:
                self.dogBreeds = []
            case .success(let r):
                self.dogBreeds = r.splitIntoSections()
                filterContent()
            case .failure(let error):
                self.dogBreeds = []
                self.error = error
                self.showAlert = true
            }
        })
    }
    
    func filterContent() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if term.isEmpty {
            filteredDogBreeds = dogBreeds
        } else {
            filteredDogBreeds = dogBreeds.compactMap { section in
                let newBreeds = section.breeds.compactMap{
                    $0.matches(term)
                }
                if newBreeds.isEmpty {
                    return nil
                }
                return AlphabeticSection(character: section.character, breeds: newBreeds)
            }
        }
    }
}

#Preview {
    DogBreedListView()
}
