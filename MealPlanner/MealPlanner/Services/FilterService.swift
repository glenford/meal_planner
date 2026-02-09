//
//  FilterService.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

class FilterService {
    
    /// Filters meals based on the provided criteria
    /// - Parameters:
    ///   - meals: Array of meals to filter
    ///   - criteria: Filter criteria to apply
    /// - Returns: Filtered array of meals matching all criteria (AND logic)
    func filterMeals(_ meals: [Meal], criteria: FilterCriteria) -> [Meal] {
        guard criteria.isActive else { return meals }
        
        return meals.filter { meal in
            var matches = true
            
            // Apply protein filter (case-insensitive)
            if let proteinFilter = criteria.proteinFilter {
                matches = matches && meal.primaryProtein.lowercased() == proteinFilter.lowercased()
            }
            
            // Apply carb filter (case-insensitive)
            if let carbFilter = criteria.carbFilter {
                matches = matches && meal.primaryCarb.lowercased() == carbFilter.lowercased()
            }
            
            // Apply component filters (case-insensitive, all must be present - AND logic)
            if !criteria.componentFilters.isEmpty {
                let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
                let filterComponents = Set(criteria.componentFilters.map { $0.lowercased() })
                matches = matches && filterComponents.isSubset(of: mealComponents)
            }
            
            return matches
        }
    }
    
    /// Extracts unique protein values from meals
    /// - Parameter meals: Array of meals
    /// - Returns: Sorted array of unique protein values
    func extractUniqueProteins(from meals: [Meal]) -> [String] {
        return Array(Set(meals.map { $0.primaryProtein })).sorted()
    }
    
    /// Extracts unique carb values from meals
    /// - Parameter meals: Array of meals
    /// - Returns: Sorted array of unique carb values
    func extractUniqueCarbs(from meals: [Meal]) -> [String] {
        return Array(Set(meals.map { $0.primaryCarb })).sorted()
    }
    
    /// Extracts unique component values from all meals
    /// - Parameter meals: Array of meals
    /// - Returns: Sorted array of unique component values
    func extractUniqueComponents(from meals: [Meal]) -> [String] {
        let allComponents = meals.flatMap { $0.otherComponents }
        return Array(Set(allComponents)).sorted()
    }
}
