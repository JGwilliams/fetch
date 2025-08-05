//
//  StringUtilities.swift
//  Fetch
//
//  Created by Jonathan Gwilliams on 04/08/2025.
//

import Foundation

extension String {
    func sentenceCased() -> String {
        return first!.uppercased() + dropFirst().lowercased()
    }
}
