//
//  MealRepositoryPropertyTests.swift
//  MyAppTests
//
//  Property-based tests for MealRepository
//  Feature: meal-planning-assistant
//

import XCTest
import SwiftCheck
@testable import MealPlanner

/// Property-based tests for MealRepository using SwiftCheck
/// These tests verify universal correctness properties across randomized inputs
class MealRepositoryPropertyTests: XCTestCase {
    var repository: MealRepository!
    var mockUserDefaults: UserDefaults!
    var mockStorageManager: StorageManager!
    
    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to ensure isolation
        mockUserDefaults = UserDefaults(suiteName: "MealRepositoryPropertyTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = MealRepository(storageManager: mockStorageManager)
    }
    
    override func tearDown() {
        // Clean up the test suite
        if let suiteName = mockUserDefaults.dictionaryRepresentation().keys.first {
            mockUserDefaults.removePersistentDomain(forName: suiteName)
        }
        mockUserDefaults = nil
        mockStorageManager = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Property 1: Meal Persistence Round-Trip
    
    /// **Validates: Requirements 1.1, 1.2, 1.3, 7.1**
    ///
    /// Property 1: Meal Persistence Round-Trip
    /// For any valid Meal with a non-empty description, saving the meal and then
    /// fetching all meals should return a collection that includes a meal with
    /// identical description, primaryProtein, primaryCarb, and otherComponents.
    func testProperty1_MealPersistenceRoundTrip() {
        property("Saving a meal and fetching should return the same meal data") <- forAll { (meal: ArbitraryMeal) in
            // Reset storage for each iteration
            self.resetStorage()
            
            // Given: A valid meal with non-empty description
            let testMeal = meal.value
            
            // When: Save the meal and fetch all meals
            do {
                try self.repository.saveMeal(testMeal)
                let fetchedMeals = try self.repository.fetchAllMeals()
                
                // Then: The fetched meals should contain a meal with identical properties
                guard let savedMeal = fetchedMeals.first(where: { $0.id == testMeal.id }) else {
                    return false <?> "Meal not found in fetched results"
                }
                
                // Verify all properties match
                let descriptionMatches = savedMeal.description == testMeal.description
                let proteinMatches = savedMeal.primaryProtein == testMeal.primaryProtein
                let carbMatches = savedMeal.primaryCarb == testMeal.primaryCarb
                let componentsMatch = savedMeal.otherComponents == testMeal.otherComponents
                
                guard descriptionMatches && proteinMatches && carbMatches && componentsMatch else {
                    return false <?> "Meal properties don't match"
                }
                
                return true
            } catch {
                return false <?> "Storage operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Property 3: Meal Retrieval Completeness
    
    /// **Validates: Requirements 1.1, 1.2, 1.3, 2.1, 7.1**
    ///
    /// Property 3: Meal Retrieval Completeness
    /// For any set of valid meals that have been saved, fetching all meals should
    /// return exactly that set of meals with no additions or omissions.
    func testProperty3_MealRetrievalCompleteness() {
        property("Fetching all meals returns exactly the saved meals") <- forAll { (meals: ArbitraryMealArray) in
            // Reset storage for each iteration
            self.resetStorage()
            
            // Given: A set of valid meals
            let testMeals = meals.value
            
            // When: Save all meals and fetch them back
            do {
                // Save all meals
                for meal in testMeals {
                    try self.repository.saveMeal(meal)
                }
                
                let fetchedMeals = try self.repository.fetchAllMeals()
                
                // Then: The fetched meals should match exactly (same count and all IDs present)
                guard fetchedMeals.count == testMeals.count else {
                    return false <?> "Count mismatch: expected \(testMeals.count), got \(fetchedMeals.count)"
                }
                
                // Verify all saved meals are present
                let savedIds = Set(testMeals.map { $0.id })
                let fetchedIds = Set(fetchedMeals.map { $0.id })
                
                guard savedIds == fetchedIds else {
                    return false <?> "ID sets don't match: saved=\(savedIds), fetched=\(fetchedIds)"
                }
                
                // Verify each meal's properties match
                for testMeal in testMeals {
                    guard let fetchedMeal = fetchedMeals.first(where: { $0.id == testMeal.id }) else {
                        return false <?> "Meal with ID \(testMeal.id) not found"
                    }
                    
                    if fetchedMeal.description != testMeal.description ||
                       fetchedMeal.primaryProtein != testMeal.primaryProtein ||
                       fetchedMeal.primaryCarb != testMeal.primaryCarb ||
                       fetchedMeal.otherComponents != testMeal.otherComponents {
                        return false <?> "Meal properties don't match for ID \(testMeal.id)"
                    }
                }
                
                return true
            } catch {
                return false <?> "Storage operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Helper Methods
    
    /// Reset storage between test iterations
    private func resetStorage() {
        // Create a new storage manager with a fresh UserDefaults suite
        mockUserDefaults = UserDefaults(suiteName: "MealRepositoryPropertyTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = MealRepository(storageManager: mockStorageManager)
    }
}

// MARK: - Arbitrary Generators

/// Generator for arbitrary Meal instances with valid non-empty descriptions
struct ArbitraryMeal: Arbitrary {
    let value: Meal
    
    static var arbitrary: Gen<ArbitraryMeal> {
        return Gen.compose { composer in
            // Generate non-empty description (requirement 1.4)
            let description = composer.generate(using: Gen<String>.fromElements(of: [
                "Grilled Chicken with Rice",
                "Beef Stir Fry",
                "Salmon with Quinoa",
                "Vegetarian Pasta",
                "Turkey Sandwich",
                "Tofu Bowl",
                "Pork Chops with Potatoes",
                "Shrimp Tacos",
                "Chicken Curry",
                "Veggie Burger"
            ]))
            
            // Generate primary protein
            let protein = composer.generate(using: Gen<String>.fromElements(of: [
                "Chicken", "Beef", "Fish", "Pork", "Turkey", "Tofu", "Shrimp", "Lamb", "Eggs", ""
            ]))
            
            // Generate primary carb
            let carb = composer.generate(using: Gen<String>.fromElements(of: [
                "Rice", "Pasta", "Quinoa", "Potatoes", "Bread", "Tortillas", "Noodles", "Couscous", ""
            ]))
            
            // Generate other components (0-5 components)
            let componentCount = composer.generate(using: Gen<Int>.choose((0, 5)))
            let allComponents = ["Vegetables", "Sauce", "Cheese", "Herbs", "Spices", "Nuts", "Beans", "Greens"]
            var components: [String] = []
            for _ in 0..<componentCount {
                let component = composer.generate(using: Gen<String>.fromElements(of: allComponents))
                components.append(component)
            }
            
            let meal = Meal(
                description: description,
                primaryProtein: protein,
                primaryCarb: carb,
                otherComponents: components
            )
            
            return ArbitraryMeal(value: meal)
        }
    }
}

/// Generator for arbitrary arrays of Meals (0-10 meals)
struct ArbitraryMealArray: Arbitrary {
    let value: [Meal]
    
    static var arbitrary: Gen<ArbitraryMealArray> {
        return Gen.compose { composer in
            // Generate 0-10 meals
            let count = composer.generate(using: Gen<Int>.choose((0, 10)))
            var meals: [Meal] = []
            
            for _ in 0..<count {
                let arbitraryMeal = composer.generate(using: ArbitraryMeal.arbitrary)
                meals.append(arbitraryMeal.value)
            }
            
            return ArbitraryMealArray(value: meals)
        }
    }
}
