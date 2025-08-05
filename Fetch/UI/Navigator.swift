//
//  Navigator.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import SwiftUI

struct Navigator: View {
    var body: some View {
        NavigationSplitView {
            DogBreedListView()
        } detail: {
            Text("Select a Dog Breed")
        }
    }
}

#Preview {
    Navigator()
}
