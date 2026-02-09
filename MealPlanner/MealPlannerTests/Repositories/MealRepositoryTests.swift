//
//  MealRepositoryTests.swift
//  MyAppTests
//
//  Created for Meal Planning Assistant
//

import XCTest
@testable import MealPlanner

class MealRepositoryTests: XCTestCase {
    var repository: MealRepository!
    var mockUserDefaults: UserDefaults!
    var mockStorageManager: StorageManager!
    
    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to ensure isolation
        mockUserDefaults = UserDefaults(suiteName: "MealRepositoryTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = MealRepository(storageManager: mockStorageManager)
    }
    
    override func tearDown() {
        // Clean up the test suite
        mockUserDefaults.removePersistentDomain(forName: "MealRepositoryTests")
        mockUserDefaults = nil
        mockStorageManager = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Save Meal Tests
    
    func testSaveMeal_NewMeal_ShouldPersist() throws {
        // Given
        let meal = Meal(
            description: "Grilled Chicken with Rice",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: ["Vegetables"]
        )
        
        // When
        try repository.saveMeal(meal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.id, meal.id)
        XCTAssertEqual(meals.first?.description, "Grilled Chicken with Rice")
        XCTAssertEqual(meals.first?.primaryProtein, "Chicken")
        XCTAssertEqual(meals.first?.primaryCarb, "Rice")
        XCTAssertEqual(meals.first?.otherComponents, ["Vegetables"])
    }
    
    func testSaveMeal_MultipleMeals_ShouldPersistAll() throws {
        // Given
        let meal1 = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        let meal2 = Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta")
        let meal3 = Meal(description: "Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa")
        
        // When
        try repository.saveMeal(meal1)
        try repository.saveMeal(meal2)
        try repository.saveMeal(meal3)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 3)
        XCTAssertTrue(meals.contains(where: { $0.id == meal1.id }))
        XCTAssertTrue(meals.contains(where: { $0.id == meal2.id }))
        XCTAssertTrue(meals.contains(where: { $0.id == meal3.id }))
    }
    
    func testSaveMeal_ExistingMeal_ShouldUpdate() throws {
        // Given
        let originalMeal = Meal(
            id: UUID(),
            description: "Original Description",
            primaryProtein: "Chicken",
            primaryCarb: "Rice"
        )
        try repository.saveMeal(originalMeal)
        
        // When - Update the meal with same ID
        let updatedMeal = Meal(
            id: originalMeal.id,
            description: "Updated Description",
            primaryProtein: "Beef",
            primaryCarb: "Pasta",
            otherComponents: ["Sauce"]
        )
        try repository.saveMeal(updatedMeal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1, "Should still have only one meal")
        XCTAssertEqual(meals.first?.id, originalMeal.id)
        XCTAssertEqual(meals.first?.description, "Updated Description")
        XCTAssertEqual(meals.first?.primaryProtein, "Beef")
        XCTAssertEqual(meals.first?.primaryCarb, "Pasta")
        XCTAssertEqual(meals.first?.otherComponents, ["Sauce"])
    }
    
    // MARK: - Fetch All Meals Tests
    
    func testFetchAllMeals_EmptyStorage_ShouldReturnEmptyArray() throws {
        // When
        let meals = try repository.fetchAllMeals()
        
        // Then
        XCTAssertEqual(meals.count, 0)
        XCTAssertTrue(meals.isEmpty)
    }
    
    func testFetchAllMeals_WithMeals_ShouldReturnAllMeals() throws {
        // Given
        let meal1 = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        let meal2 = Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta")
        try repository.saveMeal(meal1)
        try repository.saveMeal(meal2)
        
        // When
        let meals = try repository.fetchAllMeals()
        
        // Then
        XCTAssertEqual(meals.count, 2)
    }
    
    // MARK: - Delete Meal Tests
    
    func testDeleteMeal_ExistingMeal_ShouldRemove() throws {
        // Given
        let meal1 = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        let meal2 = Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta")
        try repository.saveMeal(meal1)
        try repository.saveMeal(meal2)
        
        // When
        try repository.deleteMeal(id: meal1.id)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.id, meal2.id)
        XCTAssertFalse(meals.contains(where: { $0.id == meal1.id }))
    }
    
    func testDeleteMeal_NonExistentMeal_ShouldNotAffectStorage() throws {
        // Given
        let meal = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        try repository.saveMeal(meal)
        let nonExistentId = UUID()
        
        // When
        try repository.deleteMeal(id: nonExistentId)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.id, meal.id)
    }
    
    func testDeleteMeal_LastMeal_ShouldResultInEmptyStorage() throws {
        // Given
        let meal = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        try repository.saveMeal(meal)
        
        // When
        try repository.deleteMeal(id: meal.id)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 0)
        XCTAssertTrue(meals.isEmpty)
    }
    
    // MARK: - Update Meal Tests
    
    func testUpdateMeal_ExistingMeal_ShouldUpdate() throws {
        // Given
        let originalMeal = Meal(
            id: UUID(),
            description: "Original",
            primaryProtein: "Chicken",
            primaryCarb: "Rice"
        )
        try repository.saveMeal(originalMeal)
        
        // When
        let updatedMeal = Meal(
            id: originalMeal.id,
            description: "Updated",
            primaryProtein: "Beef",
            primaryCarb: "Pasta"
        )
        try repository.updateMeal(updatedMeal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.description, "Updated")
        XCTAssertEqual(meals.first?.primaryProtein, "Beef")
    }
    
    func testUpdateMeal_NonExistentMeal_ShouldAddMeal() throws {
        // Given - Empty storage
        
        // When
        let newMeal = Meal(description: "New Meal", primaryProtein: "Fish", primaryCarb: "Quinoa")
        try repository.updateMeal(newMeal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.id, newMeal.id)
    }
    
    // MARK: - Edge Cases
    
    func testSaveMeal_WithEmptyComponents_ShouldPersist() throws {
        // Given
        let meal = Meal(
            description: "Simple Meal",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: []
        )
        
        // When
        try repository.saveMeal(meal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 1)
        XCTAssertTrue(meals.first?.otherComponents.isEmpty ?? false)
    }
    
    func testSaveMeal_WithMultipleComponents_ShouldPersist() throws {
        // Given
        let meal = Meal(
            description: "Complex Meal",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: ["Vegetables", "Sauce", "Spices", "Herbs"]
        )
        
        // When
        try repository.saveMeal(meal)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.first?.otherComponents.count, 4)
        XCTAssertEqual(meals.first?.otherComponents, ["Vegetables", "Sauce", "Spices", "Herbs"])
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence_SaveAndFetch_ShouldMaintainData() throws {
        // Given
        let meal = Meal(
            description: "Test Meal",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: ["Vegetables"]
        )
        try repository.saveMeal(meal)
        
        // When - Create a new repository instance with same storage
        let newRepository = MealRepository(storageManager: mockStorageManager)
        let meals = try newRepository.fetchAllMeals()
        
        // Then
        XCTAssertEqual(meals.count, 1)
        XCTAssertEqual(meals.first?.id, meal.id)
        XCTAssertEqual(meals.first?.description, meal.description)
    }
    
    func testPersistence_MultipleOperations_ShouldMaintainConsistency() throws {
        // Given
        let meal1 = Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        let meal2 = Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta")
        let meal3 = Meal(description: "Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa")
        
        // When
        try repository.saveMeal(meal1)
        try repository.saveMeal(meal2)
        try repository.saveMeal(meal3)
        try repository.deleteMeal(id: meal2.id)
        
        let updatedMeal1 = Meal(
            id: meal1.id,
            description: "Updated Meal 1",
            primaryProtein: "Turkey",
            primaryCarb: "Potatoes"
        )
        try repository.updateMeal(updatedMeal1)
        
        // Then
        let meals = try repository.fetchAllMeals()
        XCTAssertEqual(meals.count, 2)
        XCTAssertTrue(meals.contains(where: { $0.id == meal1.id && $0.description == "Updated Meal 1" }))
        XCTAssertTrue(meals.contains(where: { $0.id == meal3.id }))
        XCTAssertFalse(meals.contains(where: { $0.id == meal2.id }))
    }
}
