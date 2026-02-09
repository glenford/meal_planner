//
//  MealRepository.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

/// Protocol defining the interface for meal data operations
protocol MealRepositoryProtocol {
    func saveMeal(_ meal: Meal) throws
    func fetchAllMeals() throws -> [Meal]
    func deleteMeal(id: UUID) throws
    func updateMeal(_ meal: Meal) throws
}

/// Repository for managing meal persistence using StorageManager
class MealRepository: MealRepositoryProtocol {
    private let storageManager: StorageManager
    private let mealsKey = "meals"
    
    /// Initialize with a StorageManager instance
    /// - Parameter storageManager: The storage manager to use (defaults to .shared)
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
    }
    
    /// Save a meal to storage
    /// If a meal with the same ID already exists, it will be updated
    /// Otherwise, the meal will be added to the collection
    /// - Parameter meal: The meal to save
    /// - Throws: StorageError if the operation fails
    func saveMeal(_ meal: Meal) throws {
        var meals = try fetchAllMeals()
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            // Update existing meal
            meals[index] = meal
        } else {
            // Add new meal
            meals.append(meal)
        }
        try storageManager.save(meals, forKey: mealsKey)
    }
    
    /// Fetch all meals from storage
    /// - Returns: An array of all stored meals, or an empty array if none exist
    /// - Throws: StorageError if the operation fails
    func fetchAllMeals() throws -> [Meal] {
        return try storageManager.fetch([Meal].self, forKey: mealsKey) ?? []
    }
    
    /// Delete a meal from storage by ID
    /// - Parameter id: The UUID of the meal to delete
    /// - Throws: StorageError if the operation fails
    func deleteMeal(id: UUID) throws {
        var meals = try fetchAllMeals()
        meals.removeAll { $0.id == id }
        try storageManager.save(meals, forKey: mealsKey)
    }
    
    /// Update an existing meal in storage
    /// This is equivalent to saveMeal and will add the meal if it doesn't exist
    /// - Parameter meal: The meal to update
    /// - Throws: StorageError if the operation fails
    func updateMeal(_ meal: Meal) throws {
        try saveMeal(meal)
    }
}
