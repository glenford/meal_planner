//
//  FilterServiceTests.swift
//  MyAppTests
//
//  Unit tests for FilterService edge cases
//  Feature: meal-planning-assistant
//

import XCTest
@testable import MealPlanner

/// Unit tests for FilterService focusing on edge cases
/// **Validates: Requirements 3.5, 3.6**
class FilterServiceTests: XCTestCase {
    var filterService: FilterService!
    
    override func setUp() {
        super.setUp()
        filterService = FilterService()
    }
    
    override func tearDown() {
        filterService = nil
        super.tearDown()
    }
    
    // MARK: - Edge Case: Empty Meal List
    
    /// Test filtering an empty meal list returns an empty array
    /// **Validates: Requirement 3.5**
    func testFilterMeals_EmptyMealList_ReturnsEmptyArray() {
        // Given: An empty meal list and some filter criteria
        let meals: [Meal] = []
        let criteria = FilterCriteria(proteinFilter: "Chicken")
        
        // When: Filtering the empty list
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Filtering empty meal list should return empty array")
    }
    
    /// Test filtering an empty meal list with no filters returns an empty array
    /// **Validates: Requirement 3.5**
    func testFilterMeals_EmptyMealListNoFilters_ReturnsEmptyArray() {
        // Given: An empty meal list and no filter criteria
        let meals: [Meal] = []
        let criteria = FilterCriteria()
        
        // When: Filtering the empty list
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Filtering empty meal list with no filters should return empty array")
    }
    
    // MARK: - Edge Case: No Filters Applied
    
    /// Test that no filters applied returns all meals
    /// **Validates: Requirement 3.5**
    func testFilterMeals_NoFiltersApplied_ReturnsAllMeals() {
        // Given: A list of meals and no filter criteria
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice"),
            Meal(description: "Beef Pasta", primaryProtein: "Beef", primaryCarb: "Pasta"),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa")
        ]
        let criteria = FilterCriteria() // No filters
        
        // When: Filtering with no criteria
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: All meals should be returned
        XCTAssertEqual(result.count, meals.count, "No filters should return all meals")
        XCTAssertEqual(Set(result.map { $0.id }), Set(meals.map { $0.id }), "All meal IDs should be present")
    }
    
    /// Test that empty filter criteria (all nil/empty) returns all meals
    /// **Validates: Requirement 3.5**
    func testFilterMeals_EmptyFilterCriteria_ReturnsAllMeals() {
        // Given: A list of meals and explicitly empty filter criteria
        let meals = [
            Meal(description: "Tofu Noodles", primaryProtein: "Tofu", primaryCarb: "Noodles", otherComponents: ["Vegetables"]),
            Meal(description: "Shrimp Rice", primaryProtein: "Shrimp", primaryCarb: "Rice", otherComponents: ["Sauce"]),
            Meal(description: "Turkey Bread", primaryProtein: "Turkey", primaryCarb: "Bread")
        ]
        let criteria = FilterCriteria(proteinFilter: nil, carbFilter: nil, componentFilters: [])
        
        // When: Filtering with empty criteria
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: All meals should be returned
        XCTAssertEqual(result.count, 3, "Empty filter criteria should return all meals")
        XCTAssertTrue(result.contains(where: { $0.description == "Tofu Noodles" }))
        XCTAssertTrue(result.contains(where: { $0.description == "Shrimp Rice" }))
        XCTAssertTrue(result.contains(where: { $0.description == "Turkey Bread" }))
    }
    
    // MARK: - Edge Case: Filters With No Matches
    
    /// Test that protein filter with no matches returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_ProteinFilterNoMatches_ReturnsEmptyArray() {
        // Given: A list of meals and a protein filter that doesn't match any meal
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice"),
            Meal(description: "Beef Pasta", primaryProtein: "Beef", primaryCarb: "Pasta"),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa")
        ]
        let criteria = FilterCriteria(proteinFilter: "Lamb") // No meals have Lamb
        
        // When: Filtering with non-matching protein
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Protein filter with no matches should return empty array")
    }
    
    /// Test that carb filter with no matches returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_CarbFilterNoMatches_ReturnsEmptyArray() {
        // Given: A list of meals and a carb filter that doesn't match any meal
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice"),
            Meal(description: "Beef Pasta", primaryProtein: "Beef", primaryCarb: "Pasta"),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa")
        ]
        let criteria = FilterCriteria(carbFilter: "Potatoes") // No meals have Potatoes
        
        // When: Filtering with non-matching carb
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Carb filter with no matches should return empty array")
    }
    
    /// Test that component filter with no matches returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_ComponentFilterNoMatches_ReturnsEmptyArray() {
        // Given: A list of meals and a component filter that doesn't match any meal
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: ["Vegetables"]),
            Meal(description: "Beef Pasta", primaryProtein: "Beef", primaryCarb: "Pasta", otherComponents: ["Sauce"]),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: ["Herbs"])
        ]
        let criteria = FilterCriteria(componentFilters: ["Cheese"]) // No meals have Cheese
        
        // When: Filtering with non-matching component
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Component filter with no matches should return empty array")
    }
    
    /// Test that multiple filters with no matches returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_MultipleFiltersNoMatches_ReturnsEmptyArray() {
        // Given: A list of meals and multiple filters that don't match any meal
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: ["Vegetables"]),
            Meal(description: "Beef Pasta", primaryProtein: "Beef", primaryCarb: "Pasta", otherComponents: ["Sauce"]),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: ["Herbs"])
        ]
        let criteria = FilterCriteria(
            proteinFilter: "Lamb",
            carbFilter: "Potatoes",
            componentFilters: ["Cheese"]
        )
        
        // When: Filtering with multiple non-matching criteria
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Multiple filters with no matches should return empty array")
    }
    
    /// Test that partial match with multiple filters returns empty array (AND logic)
    /// **Validates: Requirement 3.6**
    func testFilterMeals_PartialMatchMultipleFilters_ReturnsEmptyArray() {
        // Given: A list of meals and multiple filters where only some criteria match
        let meals = [
            Meal(description: "Chicken Rice", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: ["Vegetables"]),
            Meal(description: "Chicken Pasta", primaryProtein: "Chicken", primaryCarb: "Pasta", otherComponents: ["Sauce"]),
            Meal(description: "Fish Quinoa", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: ["Herbs"])
        ]
        // Filter for Chicken (matches 2 meals) + Potatoes (matches 0 meals)
        let criteria = FilterCriteria(proteinFilter: "Chicken", carbFilter: "Potatoes")
        
        // When: Filtering with partial matching criteria
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty (AND logic requires all criteria to match)
        XCTAssertTrue(result.isEmpty, "Partial match with AND logic should return empty array")
    }
    
    // MARK: - Additional Edge Cases
    
    /// Test that filtering with component that no meal has returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_ComponentNotInAnyMeal_ReturnsEmptyArray() {
        // Given: Meals with various components and a filter for a component none have
        let meals = [
            Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: ["Vegetables", "Sauce"]),
            Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta", otherComponents: ["Herbs", "Spices"]),
            Meal(description: "Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: [])
        ]
        let criteria = FilterCriteria(componentFilters: ["Nuts"]) // No meal has Nuts
        
        // When: Filtering for non-existent component
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Filter for component not in any meal should return empty array")
    }
    
    /// Test that filtering meals with no components using component filter returns empty array
    /// **Validates: Requirement 3.6**
    func testFilterMeals_MealsWithNoComponentsFilteredByComponent_ReturnsEmptyArray() {
        // Given: Meals with no other components and a component filter
        let meals = [
            Meal(description: "Simple Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: []),
            Meal(description: "Simple Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta", otherComponents: []),
            Meal(description: "Simple Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: [])
        ]
        let criteria = FilterCriteria(componentFilters: ["Vegetables"])
        
        // When: Filtering meals with no components
        let result = filterService.filterMeals(meals, criteria: criteria)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Meals with no components should not match component filter")
    }
    
    // MARK: - Extract Methods Edge Cases
    
    /// Test extracting unique proteins from empty meal list
    func testExtractUniqueProteins_EmptyMealList_ReturnsEmptyArray() {
        // Given: An empty meal list
        let meals: [Meal] = []
        
        // When: Extracting unique proteins
        let result = filterService.extractUniqueProteins(from: meals)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Extracting proteins from empty list should return empty array")
    }
    
    /// Test extracting unique carbs from empty meal list
    func testExtractUniqueCarbs_EmptyMealList_ReturnsEmptyArray() {
        // Given: An empty meal list
        let meals: [Meal] = []
        
        // When: Extracting unique carbs
        let result = filterService.extractUniqueCarbs(from: meals)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Extracting carbs from empty list should return empty array")
    }
    
    /// Test extracting unique components from empty meal list
    func testExtractUniqueComponents_EmptyMealList_ReturnsEmptyArray() {
        // Given: An empty meal list
        let meals: [Meal] = []
        
        // When: Extracting unique components
        let result = filterService.extractUniqueComponents(from: meals)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Extracting components from empty list should return empty array")
    }
    
    /// Test extracting unique components from meals with no components
    func testExtractUniqueComponents_MealsWithNoComponents_ReturnsEmptyArray() {
        // Given: Meals with no other components
        let meals = [
            Meal(description: "Meal 1", primaryProtein: "Chicken", primaryCarb: "Rice", otherComponents: []),
            Meal(description: "Meal 2", primaryProtein: "Beef", primaryCarb: "Pasta", otherComponents: []),
            Meal(description: "Meal 3", primaryProtein: "Fish", primaryCarb: "Quinoa", otherComponents: [])
        ]
        
        // When: Extracting unique components
        let result = filterService.extractUniqueComponents(from: meals)
        
        // Then: Result should be empty
        XCTAssertTrue(result.isEmpty, "Extracting components from meals with no components should return empty array")
    }
}
