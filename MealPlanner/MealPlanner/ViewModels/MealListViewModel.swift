//
//  MealListViewModel.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation
import Combine

/// ViewModel for managing meal list display and filtering
/// Handles meal loading, filtering, and deletion operations
class MealListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All meals loaded from storage
    @Published var meals: [Meal] = []
    
    /// Filtered meals based on current filter criteria
    @Published var filteredMeals: [Meal] = []
    
    /// Current filter criteria applied to the meal list
    @Published var filterCriteria = FilterCriteria()
    
    /// Loading state indicator
    @Published var isLoading = false
    
    /// Error message to display to the user, if any
    @Published var errorMessage: String?
    
    /// Whether to show retry option for the last error
    @Published var showRetryOption = false
    
    /// The last failed operation to retry
    private var lastFailedOperation: (() -> Void)?
    
    // MARK: - Dependencies
    
    private let mealRepository: MealRepositoryProtocol
    private let filterService: FilterService
    
    // MARK: - Computed Properties
    
    /// Available protein options extracted from all meals
    var availableProteins: [String] {
        filterService.extractUniqueProteins(from: meals)
    }
    
    /// Available carb options extracted from all meals
    var availableCarbs: [String] {
        filterService.extractUniqueCarbs(from: meals)
    }
    
    /// Available component options extracted from all meals
    var availableComponents: [String] {
        filterService.extractUniqueComponents(from: meals)
    }
    
    // MARK: - Initialization
    
    /// Initialize the view model with dependencies
    /// - Parameters:
    ///   - mealRepository: The repository to use for meal persistence (defaults to MealRepository())
    ///   - filterService: The service to use for filtering (defaults to FilterService())
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         filterService: FilterService = FilterService()) {
        self.mealRepository = mealRepository
        self.filterService = filterService
    }
    
    // MARK: - Public Methods
    
    /// Load all meals from storage and apply current filters
    /// Updates isLoading state and handles errors
    /// Requirements: 2.1, 2.2
    func loadMeals() {
        isLoading = true
        errorMessage = nil
        showRetryOption = false
        
        do {
            meals = try mealRepository.fetchAllMeals()
            applyFilters()
        } catch {
            errorMessage = "Unable to load your meals. Please check your connection and try again."
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                self?.loadMeals()
            }
        }
        
        isLoading = false
    }
    
    /// Apply current filter criteria to the meal list
    /// Updates filteredMeals with the results
    /// Requirements: 3.1, 3.2, 3.3, 3.4
    func applyFilters() {
        filteredMeals = filterService.filterMeals(meals, criteria: filterCriteria)
    }
    
    /// Delete a meal by ID
    /// Reloads the meal list after successful deletion
    /// - Parameter id: The UUID of the meal to delete
    /// Requirements: 2.1
    func deleteMeal(id: UUID) {
        errorMessage = nil
        showRetryOption = false
        
        do {
            try mealRepository.deleteMeal(id: id)
            loadMeals()
        } catch {
            errorMessage = "Unable to delete this meal. Please try again."
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                self?.deleteMeal(id: id)
            }
        }
    }
    
    /// Retry the last failed operation
    func retryLastOperation() {
        lastFailedOperation?()
    }
}
