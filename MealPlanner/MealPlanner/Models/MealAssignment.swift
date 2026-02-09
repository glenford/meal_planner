//
//  MealAssignment.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

struct MealAssignment: Identifiable, Codable, Equatable {
    let id: UUID
    let mealId: UUID
    let date: Date // Normalized to start of day
    var createdAt: Date
    
    init(id: UUID = UUID(),
         mealId: UUID,
         date: Date,
         createdAt: Date = Date()) {
        self.id = id
        self.mealId = mealId
        self.date = date.startOfDay
        self.createdAt = createdAt
    }
}
