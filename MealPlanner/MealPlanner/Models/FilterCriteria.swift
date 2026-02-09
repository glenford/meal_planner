//
//  FilterCriteria.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

struct FilterCriteria: Equatable {
    var proteinFilter: String?
    var carbFilter: String?
    var componentFilters: Set<String>
    
    var isActive: Bool {
        proteinFilter != nil || carbFilter != nil || !componentFilters.isEmpty
    }
    
    init(proteinFilter: String? = nil,
         carbFilter: String? = nil,
         componentFilters: Set<String> = []) {
        self.proteinFilter = proteinFilter
        self.carbFilter = carbFilter
        self.componentFilters = componentFilters
    }
}
