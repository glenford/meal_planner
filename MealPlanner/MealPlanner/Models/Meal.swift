//
//  Meal.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    var description: String
    var primaryProtein: String
    var primaryCarb: String
    var otherComponents: [String]
    var createdAt: Date
    
    init(id: UUID = UUID(),
         description: String,
         primaryProtein: String,
         primaryCarb: String,
         otherComponents: [String] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.description = description
        self.primaryProtein = primaryProtein
        self.primaryCarb = primaryCarb
        self.otherComponents = otherComponents
        self.createdAt = createdAt
    }
}
