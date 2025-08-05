//
//  DogBreedDetailView.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import SwiftUI

struct DogBreedDetailView: View {
    static let imageCount = 10
    
    let breed: String
    let subbreed: String?
    
    @State private var fetchTask: URLSessionTask?
    @State private var imageURLs: [DogImage] = []
    @State private var showAlert = false
    @State private var error: Error? = nil
    
    private var title: String {
        if let subbreed = subbreed {
            return "\(breed.sentenceCased()) (\(subbreed.sentenceCased()))"
        } else {
            return breed
        }
    }
    
    var body: some View {
        NavigationView {
            List(imageURLs) { image in
                HStack {
                    Spacer()
                    AsyncImage(url: image.url) { result in
                        result.image?
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(height: 300)
                    Spacer()
                }
            }
            .refreshable {
                reloadContent()
            }
            .listRowSpacing(20)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(error?.localizedDescription ?? "Unknown error occurred."))
            }
        }
        .task {
            reloadContent()
        }
    }
    
    func reloadContent() {
        self.fetchTask = GetDogImagesRequest(breed: breed, subbreed: subbreed, count: DogBreedDetailView.imageCount).start(on: WebEnvironment.standardUrlSession, completion: { response in
            switch response {
            case .noData:
                self.imageURLs = []
            case .success(let r):
                self.imageURLs = r.images
            case .failure(let error):
                self.imageURLs = []
                self.error = error
                self.showAlert = true
            }
        })
    }
}

#Preview {
    DogBreedDetailView(breed: "Chow", subbreed: nil)
}
