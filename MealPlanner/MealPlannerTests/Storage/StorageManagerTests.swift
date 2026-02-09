//
//  StorageManagerTests.swift
//  MyAppTests
//
//  Created for Meal Planning Assistant
//

import XCTest
@testable import MealPlanner

/// Unit tests for StorageManager
/// Tests saving, fetching, and error handling for various Codable types
/// Requirements: 1.3, 7.4
final class StorageManagerTests: XCTestCase {
    
    var storageManager: StorageManager!
    var mockUserDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        // Create a unique suite name for each test to ensure isolation
        let suiteName = "test.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)
        storageManager = StorageManager(userDefaults: mockUserDefaults)
    }
    
    override func tearDownWithError() throws {
        // Clean up by removing the test suite
        if let suiteName = mockUserDefaults.dictionaryRepresentation().keys.first {
            mockUserDefaults.removePersistentDomain(forName: suiteName)
        }
        mockUserDefaults = nil
        storageManager = nil
    }
    
    // MARK: - Basic Save and Fetch Tests
    
    func testSaveAndFetchString() throws {
        // Given
        let testString = "Test String"
        let key = "testStringKey"
        
        // When
        try storageManager.save(testString, forKey: key)
        let fetchedString: String? = try storageManager.fetch(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(fetchedString, testString)
    }
    
    func testSaveAndFetchInt() throws {
        // Given
        let testInt = 42
        let key = "testIntKey"
        
        // When
        try storageManager.save(testInt, forKey: key)
        let fetchedInt: Int? = try storageManager.fetch(Int.self, forKey: key)
        
        // Then
        XCTAssertEqual(fetchedInt, testInt)
    }
    
    func testSaveAndFetchArray() throws {
        // Given
        let testArray = ["one", "two", "three"]
        let key = "testArrayKey"
        
        // When
        try storageManager.save(testArray, forKey: key)
        let fetchedArray: [String]? = try storageManager.fetch([String].self, forKey: key)
        
        // Then
        XCTAssertEqual(fetchedArray, testArray)
    }
    
    func testSaveAndFetchDictionary() throws {
        // Given
        let testDict = ["key1": "value1", "key2": "value2"]
        let key = "testDictKey"
        
        // When
        try storageManager.save(testDict, forKey: key)
        let fetchedDict: [String: String]? = try storageManager.fetch([String: String].self, forKey: key)
        
        // Then
        XCTAssertEqual(fetchedDict, testDict)
    }
    
    // MARK: - Complex Type Tests (Meal and MealAssignment)
    
    func testSaveAndFetchMeal() throws {
        // Given
        let meal = Meal(
            description: "Grilled Chicken with Rice",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: ["Vegetables", "Olive Oil"]
        )
        let key = "testMealKey"
        
        // When
        try storageManager.save(meal, forKey: key)
        let fetchedMeal: Meal? = try storageManager.fetch(Meal.self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedMeal)
        XCTAssertEqual(fetchedMeal?.id, meal.id)
        XCTAssertEqual(fetchedMeal?.description, meal.description)
        XCTAssertEqual(fetchedMeal?.primaryProtein, meal.primaryProtein)
        XCTAssertEqual(fetchedMeal?.primaryCarb, meal.primaryCarb)
        XCTAssertEqual(fetchedMeal?.otherComponents, meal.otherComponents)
    }
    
    func testSaveAndFetchMealArray() throws {
        // Given
        let meals = [
            Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice"),
            Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta"),
            Meal(description: "Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa")
        ]
        let key = "testMealsKey"
        
        // When
        try storageManager.save(meals, forKey: key)
        let fetchedMeals: [Meal]? = try storageManager.fetch([Meal].self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedMeals)
        XCTAssertEqual(fetchedMeals?.count, meals.count)
        XCTAssertEqual(fetchedMeals?[0].description, meals[0].description)
        XCTAssertEqual(fetchedMeals?[1].description, meals[1].description)
        XCTAssertEqual(fetchedMeals?[2].description, meals[2].description)
    }
    
    func testSaveAndFetchMealAssignment() throws {
        // Given
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        let key = "testAssignmentKey"
        
        // When
        try storageManager.save(assignment, forKey: key)
        let fetchedAssignment: MealAssignment? = try storageManager.fetch(MealAssignment.self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedAssignment)
        XCTAssertEqual(fetchedAssignment?.id, assignment.id)
        XCTAssertEqual(fetchedAssignment?.mealId, assignment.mealId)
        XCTAssertEqual(fetchedAssignment?.date, assignment.date)
    }
    
    func testSaveAndFetchMealAssignmentArray() throws {
        // Given
        let assignments = [
            MealAssignment(mealId: UUID(), date: Date()),
            MealAssignment(mealId: UUID(), date: Date().addingTimeInterval(86400)),
            MealAssignment(mealId: UUID(), date: Date().addingTimeInterval(172800))
        ]
        let key = "testAssignmentsKey"
        
        // When
        try storageManager.save(assignments, forKey: key)
        let fetchedAssignments: [MealAssignment]? = try storageManager.fetch([MealAssignment].self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedAssignments)
        XCTAssertEqual(fetchedAssignments?.count, assignments.count)
        XCTAssertEqual(fetchedAssignments?[0].mealId, assignments[0].mealId)
        XCTAssertEqual(fetchedAssignments?[1].mealId, assignments[1].mealId)
        XCTAssertEqual(fetchedAssignments?[2].mealId, assignments[2].mealId)
    }
    
    // MARK: - Fetch Non-Existent Key Tests
    
    func testFetchNonExistentKeyReturnsNil() throws {
        // Given
        let key = "nonExistentKey"
        
        // When
        let result: String? = try storageManager.fetch(String.self, forKey: key)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testFetchNonExistentMealReturnsNil() throws {
        // Given
        let key = "nonExistentMealKey"
        
        // When
        let result: Meal? = try storageManager.fetch(Meal.self, forKey: key)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Update/Overwrite Tests
    
    func testSaveOverwritesExistingValue() throws {
        // Given
        let key = "overwriteKey"
        let originalValue = "Original"
        let newValue = "Updated"
        
        // When
        try storageManager.save(originalValue, forKey: key)
        let firstFetch: String? = try storageManager.fetch(String.self, forKey: key)
        
        try storageManager.save(newValue, forKey: key)
        let secondFetch: String? = try storageManager.fetch(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(firstFetch, originalValue)
        XCTAssertEqual(secondFetch, newValue)
    }
    
    func testSaveOverwritesMealArray() throws {
        // Given
        let key = "mealsKey"
        let originalMeals = [
            Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice")
        ]
        let updatedMeals = [
            Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice"),
            Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta")
        ]
        
        // When
        try storageManager.save(originalMeals, forKey: key)
        let firstFetch: [Meal]? = try storageManager.fetch([Meal].self, forKey: key)
        
        try storageManager.save(updatedMeals, forKey: key)
        let secondFetch: [Meal]? = try storageManager.fetch([Meal].self, forKey: key)
        
        // Then
        XCTAssertEqual(firstFetch?.count, 1)
        XCTAssertEqual(secondFetch?.count, 2)
    }
    
    // MARK: - Remove Tests
    
    func testRemoveDeletesValue() throws {
        // Given
        let key = "removeKey"
        let value = "Test Value"
        
        // When
        try storageManager.save(value, forKey: key)
        let beforeRemove: String? = try storageManager.fetch(String.self, forKey: key)
        
        storageManager.remove(forKey: key)
        let afterRemove: String? = try storageManager.fetch(String.self, forKey: key)
        
        // Then
        XCTAssertNotNil(beforeRemove)
        XCTAssertNil(afterRemove)
    }
    
    func testRemoveNonExistentKeyDoesNotThrow() throws {
        // Given
        let key = "nonExistentRemoveKey"
        
        // When/Then - Should not throw
        storageManager.remove(forKey: key)
    }
    
    // MARK: - Error Handling Tests
    
    func testFetchWithInvalidDataThrowsDecodingError() throws {
        // Given
        let key = "invalidDataKey"
        let invalidData = "Not valid JSON data".data(using: .utf8)!
        mockUserDefaults.set(invalidData, forKey: key)
        
        // When/Then
        XCTAssertThrowsError(try storageManager.fetch(Meal.self, forKey: key)) { error in
            XCTAssertTrue(error is StorageError)
            if let storageError = error as? StorageError {
                XCTAssertEqual(storageError, StorageError.decodingFailed)
            }
        }
    }
    
    func testFetchWithWrongTypeThrowsDecodingError() throws {
        // Given
        let key = "wrongTypeKey"
        let stringValue = "Just a string"
        try storageManager.save(stringValue, forKey: key)
        
        // When/Then - Try to fetch as Int
        XCTAssertThrowsError(try storageManager.fetch(Int.self, forKey: key)) { error in
            XCTAssertTrue(error is StorageError)
            if let storageError = error as? StorageError {
                XCTAssertEqual(storageError, StorageError.decodingFailed)
            }
        }
    }
    
    func testFetchWithCorruptedJSONThrowsDecodingError() throws {
        // Given
        let key = "corruptedJSONKey"
        // Create corrupted JSON data that looks like JSON but isn't valid for Meal
        let corruptedJSON = "{\"invalid\": \"structure\"}".data(using: .utf8)!
        mockUserDefaults.set(corruptedJSON, forKey: key)
        
        // When/Then
        XCTAssertThrowsError(try storageManager.fetch(Meal.self, forKey: key)) { error in
            XCTAssertTrue(error is StorageError)
            if let storageError = error as? StorageError {
                XCTAssertEqual(storageError, StorageError.decodingFailed)
            }
        }
    }
    
    // MARK: - Empty Collection Tests
    
    func testSaveAndFetchEmptyArray() throws {
        // Given
        let emptyArray: [Meal] = []
        let key = "emptyArrayKey"
        
        // When
        try storageManager.save(emptyArray, forKey: key)
        let fetchedArray: [Meal]? = try storageManager.fetch([Meal].self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedArray)
        XCTAssertEqual(fetchedArray?.count, 0)
    }
    
    func testSaveAndFetchEmptyDictionary() throws {
        // Given
        let emptyDict: [String: String] = [:]
        let key = "emptyDictKey"
        
        // When
        try storageManager.save(emptyDict, forKey: key)
        let fetchedDict: [String: String]? = try storageManager.fetch([String: String].self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedDict)
        XCTAssertEqual(fetchedDict?.count, 0)
    }
    
    // MARK: - Multiple Keys Isolation Tests
    
    func testMultipleKeysAreIsolated() throws {
        // Given
        let key1 = "key1"
        let key2 = "key2"
        let value1 = "Value 1"
        let value2 = "Value 2"
        
        // When
        try storageManager.save(value1, forKey: key1)
        try storageManager.save(value2, forKey: key2)
        
        let fetched1: String? = try storageManager.fetch(String.self, forKey: key1)
        let fetched2: String? = try storageManager.fetch(String.self, forKey: key2)
        
        // Then
        XCTAssertEqual(fetched1, value1)
        XCTAssertEqual(fetched2, value2)
        
        // When - Remove one key
        storageManager.remove(forKey: key1)
        
        let afterRemove1: String? = try storageManager.fetch(String.self, forKey: key1)
        let afterRemove2: String? = try storageManager.fetch(String.self, forKey: key2)
        
        // Then - Only key1 should be removed
        XCTAssertNil(afterRemove1)
        XCTAssertEqual(afterRemove2, value2)
    }
    
    // MARK: - Special Characters in Keys Tests
    
    func testSaveAndFetchWithSpecialCharactersInKey() throws {
        // Given
        let key = "test.key-with_special@characters#123"
        let value = "Test Value"
        
        // When
        try storageManager.save(value, forKey: key)
        let fetched: String? = try storageManager.fetch(String.self, forKey: key)
        
        // Then
        XCTAssertEqual(fetched, value)
    }
    
    // MARK: - Large Data Tests
    
    func testSaveAndFetchLargeMealArray() throws {
        // Given
        let largeMealArray = (0..<100).map { index in
            Meal(
                description: "Meal \(index)",
                primaryProtein: "Protein \(index)",
                primaryCarb: "Carb \(index)",
                otherComponents: ["Component 1", "Component 2", "Component 3"]
            )
        }
        let key = "largeMealArrayKey"
        
        // When
        try storageManager.save(largeMealArray, forKey: key)
        let fetchedArray: [Meal]? = try storageManager.fetch([Meal].self, forKey: key)
        
        // Then
        XCTAssertNotNil(fetchedArray)
        XCTAssertEqual(fetchedArray?.count, 100)
        XCTAssertEqual(fetchedArray?.first?.description, "Meal 0")
        XCTAssertEqual(fetchedArray?.last?.description, "Meal 99")
    }
}
