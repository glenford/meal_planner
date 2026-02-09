//
//  FilterServicePropertyTests.swift
//  MyAppTests
//
//  Property-based tests for FilterService
//  Feature: meal-planning-assistant
//

import XCTest
import SwiftCheck
@testable import MealPlanner

/// Property-based tests for FilterService using SwiftCheck
/// These tests verify universal correctness properties across randomized inputs
class FilterServicePropertyTests: XCTestCase {
    var filterService: FilterService!
    
    override func setUp() {
        super.setUp()
        filterService = FilterService()
    }
    
    override func tearDown() {
        filterService = nil
        super.tearDown()
    }
    
    // MARK: - Property 5: Filter Correctness
    
    /// **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    ///
    /// Property 5: Filter Correctness
    /// For any set of meals and any filter criteria (protein, carb, or component filters),
    /// the filtered results should contain only meals that match ALL specified criteria,
    /// and should contain ALL meals that match the criteria.
    func testProperty5_FilterCorrectness() {
        property("Filtered results contain only and all meals matching criteria") <- forAll { 
            (mealsGen: ArbitraryMealArray, criteriaGen: ArbitraryFilterCriteria) in
            
            // Given: A set of meals and filter criteria
            let meals = mealsGen.value
            let criteria = criteriaGen.value
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: Verify two properties:
            // 1. All filtered meals match the criteria (no false positives)
            // 2. All meals that match the criteria are in the filtered results (no false negatives)
            
            // Property 1: No false positives - every filtered meal must match all criteria
            for meal in filteredMeals {
                if !self.mealMatchesCriteria(meal, criteria: criteria) {
                    return false <?> "False positive: Meal '\(meal.description)' doesn't match criteria but was included"
                }
            }
            
            // Property 2: No false negatives - every meal that matches criteria must be in results
            for meal in meals {
                let shouldBeIncluded = self.mealMatchesCriteria(meal, criteria: criteria)
                let isIncluded = filteredMeals.contains(where: { $0.id == meal.id })
                
                if shouldBeIncluded && !isIncluded {
                    return false <?> "False negative: Meal '\(meal.description)' matches criteria but was excluded"
                }
                
                if !shouldBeIncluded && isIncluded {
                    return false <?> "False positive: Meal '\(meal.description)' doesn't match criteria but was included"
                }
            }
            
            return true
        }.verbose
    }
    
    /// **Validates: Requirements 3.1**
    ///
    /// Property 5a: Protein Filter Correctness
    /// When a protein filter is applied, all filtered meals must have that protein
    /// and all meals with that protein must be included.
    func testProperty5a_ProteinFilterCorrectness() {
        property("Protein filter returns only meals with matching protein") <- forAll {
            (mealsGen: ArbitraryMealArray, proteinGen: ArbitraryProtein) in
            
            // Given: A set of meals and a protein filter
            let meals = mealsGen.value
            let protein = proteinGen.value
            let criteria = FilterCriteria(proteinFilter: protein)
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: All filtered meals must have the specified protein (case-insensitive)
            for meal in filteredMeals {
                if meal.primaryProtein.lowercased() != protein.lowercased() {
                    return false <?> "Meal '\(meal.description)' has protein '\(meal.primaryProtein)' but filter is '\(protein)'"
                }
            }
            
            // And: All meals with that protein must be included
            for meal in meals {
                if meal.primaryProtein.lowercased() == protein.lowercased() {
                    if !filteredMeals.contains(where: { $0.id == meal.id }) {
                        return false <?> "Meal '\(meal.description)' with protein '\(meal.primaryProtein)' was excluded"
                    }
                }
            }
            
            return true
        }.verbose
    }
    
    /// **Validates: Requirements 3.2**
    ///
    /// Property 5b: Carb Filter Correctness
    /// When a carb filter is applied, all filtered meals must have that carb
    /// and all meals with that carb must be included.
    func testProperty5b_CarbFilterCorrectness() {
        property("Carb filter returns only meals with matching carb") <- forAll {
            (mealsGen: ArbitraryMealArray, carbGen: ArbitraryCarb) in
            
            // Given: A set of meals and a carb filter
            let meals = mealsGen.value
            let carb = carbGen.value
            let criteria = FilterCriteria(carbFilter: carb)
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: All filtered meals must have the specified carb (case-insensitive)
            for meal in filteredMeals {
                if meal.primaryCarb.lowercased() != carb.lowercased() {
                    return false <?> "Meal '\(meal.description)' has carb '\(meal.primaryCarb)' but filter is '\(carb)'"
                }
            }
            
            // And: All meals with that carb must be included
            for meal in meals {
                if meal.primaryCarb.lowercased() == carb.lowercased() {
                    if !filteredMeals.contains(where: { $0.id == meal.id }) {
                        return false <?> "Meal '\(meal.description)' with carb '\(meal.primaryCarb)' was excluded"
                    }
                }
            }
            
            return true
        }.verbose
    }
    
    /// **Validates: Requirements 3.3**
    ///
    /// Property 5c: Component Filter Correctness
    /// When component filters are applied, all filtered meals must contain all specified components
    /// and all meals containing all components must be included.
    func testProperty5c_ComponentFilterCorrectness() {
        property("Component filter returns only meals with all specified components") <- forAll {
            (mealsGen: ArbitraryMealArray, componentsGen: ArbitraryComponentSet) in
            
            // Given: A set of meals and component filters
            let meals = mealsGen.value
            let components = componentsGen.value
            
            // Skip if no components to filter (empty set is not a meaningful test)
            guard !components.isEmpty else { return true }
            
            let criteria = FilterCriteria(componentFilters: components)
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: All filtered meals must contain all specified components (case-insensitive)
            for meal in filteredMeals {
                let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
                let filterComponents = Set(components.map { $0.lowercased() })
                
                if !filterComponents.isSubset(of: mealComponents) {
                    return false <?> "Meal '\(meal.description)' doesn't contain all required components"
                }
            }
            
            // And: All meals with all components must be included
            for meal in meals {
                let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
                let filterComponents = Set(components.map { $0.lowercased() })
                
                if filterComponents.isSubset(of: mealComponents) {
                    if !filteredMeals.contains(where: { $0.id == meal.id }) {
                        return false <?> "Meal '\(meal.description)' with all components was excluded"
                    }
                }
            }
            
            return true
        }.verbose
    }
    
    /// **Validates: Requirements 3.4**
    ///
    /// Property 5d: Multiple Filter Correctness (AND Logic)
    /// When multiple filters are applied, all filtered meals must match ALL criteria (AND logic).
    func testProperty5d_MultipleFilterCorrectness() {
        property("Multiple filters use AND logic - meals must match all criteria") <- forAll {
            (mealsGen: ArbitraryMealArray, criteriaGen: ArbitraryFilterCriteria) in
            
            // Given: A set of meals and multiple filter criteria
            let meals = mealsGen.value
            let criteria = criteriaGen.value
            
            // Skip if no filters are active
            guard criteria.isActive else { return true }
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: All filtered meals must match ALL criteria
            for meal in filteredMeals {
                // Check protein filter
                if let proteinFilter = criteria.proteinFilter {
                    if meal.primaryProtein.lowercased() != proteinFilter.lowercased() {
                        return false <?> "Meal '\(meal.description)' doesn't match protein filter"
                    }
                }
                
                // Check carb filter
                if let carbFilter = criteria.carbFilter {
                    if meal.primaryCarb.lowercased() != carbFilter.lowercased() {
                        return false <?> "Meal '\(meal.description)' doesn't match carb filter"
                    }
                }
                
                // Check component filters
                if !criteria.componentFilters.isEmpty {
                    let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
                    let filterComponents = Set(criteria.componentFilters.map { $0.lowercased() })
                    
                    if !filterComponents.isSubset(of: mealComponents) {
                        return false <?> "Meal '\(meal.description)' doesn't match component filters"
                    }
                }
            }
            
            // And: All meals matching all criteria must be included
            for meal in meals {
                if self.mealMatchesCriteria(meal, criteria: criteria) {
                    if !filteredMeals.contains(where: { $0.id == meal.id }) {
                        return false <?> "Meal '\(meal.description)' matches all criteria but was excluded"
                    }
                }
            }
            
            return true
        }.verbose
    }
    
    /// **Validates: Requirements 3.5**
    ///
    /// Property 5e: No Filter Returns All Meals
    /// When no filters are applied, all meals should be returned.
    func testProperty5e_NoFilterReturnsAll() {
        property("No filter returns all meals") <- forAll { (mealsGen: ArbitraryMealArray) in
            // Given: A set of meals and no filter criteria
            let meals = mealsGen.value
            let criteria = FilterCriteria() // Empty criteria
            
            // When: Filter the meals
            let filteredMeals = self.filterService.filterMeals(meals, criteria: criteria)
            
            // Then: All meals should be returned
            guard filteredMeals.count == meals.count else {
                return false <?> "Expected \(meals.count) meals, got \(filteredMeals.count)"
            }
            
            // Verify all meal IDs are present
            let originalIds = Set(meals.map { $0.id })
            let filteredIds = Set(filteredMeals.map { $0.id })
            
            guard originalIds == filteredIds else {
                return false <?> "Meal IDs don't match"
            }
            
            return true
        }.verbose
    }
    
    // MARK: - Helper Methods
    
    /// Check if a meal matches the given filter criteria
    /// This replicates the filtering logic to verify correctness
    private func mealMatchesCriteria(_ meal: Meal, criteria: FilterCriteria) -> Bool {
        // If no filters are active, all meals match
        guard criteria.isActive else { return true }
        
        var matches = true
        
        // Check protein filter (case-insensitive)
        if let proteinFilter = criteria.proteinFilter {
            matches = matches && meal.primaryProtein.lowercased() == proteinFilter.lowercased()
        }
        
        // Check carb filter (case-insensitive)
        if let carbFilter = criteria.carbFilter {
            matches = matches && meal.primaryCarb.lowercased() == carbFilter.lowercased()
        }
        
        // Check component filters (case-insensitive, all must be present - AND logic)
        if !criteria.componentFilters.isEmpty {
            let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
            let filterComponents = Set(criteria.componentFilters.map { $0.lowercased() })
            matches = matches && filterComponents.isSubset(of: mealComponents)
        }
        
        return matches
    }
}

// MARK: - Arbitrary Generators

/// Generator for arbitrary FilterCriteria
struct ArbitraryFilterCriteria: Arbitrary {
    let value: FilterCriteria
    
    static var arbitrary: Gen<ArbitraryFilterCriteria> {
        return Gen.compose { composer in
            // Randomly decide which filters to apply
            let hasProteinFilter = composer.generate(using: Bool.arbitrary)
            let hasCarbFilter = composer.generate(using: Bool.arbitrary)
            let hasComponentFilters = composer.generate(using: Bool.arbitrary)
            
            let proteinFilter: String? = hasProteinFilter ? 
                composer.generate(using: ArbitraryProtein.arbitrary).value : nil
            
            let carbFilter: String? = hasCarbFilter ?
                composer.generate(using: ArbitraryCarb.arbitrary).value : nil
            
            var componentFilters: Set<String> = []
            if hasComponentFilters {
                let count = composer.generate(using: Gen<Int>.choose((1, 3)))
                let allComponents = ["Vegetables", "Sauce", "Cheese", "Herbs", "Spices", "Nuts", "Beans", "Greens"]
                for _ in 0..<count {
                    let component = composer.generate(using: Gen<String>.fromElements(of: allComponents))
                    componentFilters.insert(component)
                }
            }
            
            let criteria = FilterCriteria(
                proteinFilter: proteinFilter,
                carbFilter: carbFilter,
                componentFilters: componentFilters
            )
            
            return ArbitraryFilterCriteria(value: criteria)
        }
    }
}

/// Generator for arbitrary protein values
struct ArbitraryProtein: Arbitrary {
    let value: String
    
    static var arbitrary: Gen<ArbitraryProtein> {
        return Gen<String>.fromElements(of: [
            "Chicken", "Beef", "Fish", "Pork", "Turkey", "Tofu", "Shrimp", "Lamb", "Eggs"
        ]).map { ArbitraryProtein(value: $0) }
    }
}

/// Generator for arbitrary carb values
struct ArbitraryCarb: Arbitrary {
    let value: String
    
    static var arbitrary: Gen<ArbitraryCarb> {
        return Gen<String>.fromElements(of: [
            "Rice", "Pasta", "Quinoa", "Potatoes", "Bread", "Tortillas", "Noodles", "Couscous"
        ]).map { ArbitraryCarb(value: $0) }
    }
}

/// Generator for arbitrary component sets
struct ArbitraryComponentSet: Arbitrary {
    let value: Set<String>
    
    static var arbitrary: Gen<ArbitraryComponentSet> {
        return Gen.compose { composer in
            let count = composer.generate(using: Gen<Int>.choose((0, 4)))
            let allComponents = ["Vegetables", "Sauce", "Cheese", "Herbs", "Spices", "Nuts", "Beans", "Greens"]
            var components: Set<String> = []
            
            for _ in 0..<count {
                let component = composer.generate(using: Gen<String>.fromElements(of: allComponents))
                components.insert(component)
            }
            
            return ArbitraryComponentSet(value: components)
        }
    }
}
