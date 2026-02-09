//
//  WeeklyPlannerViewModel.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation
import Combine

/// ViewModel for managing weekly meal planner state and operations
/// Handles week navigation, meal assignments, and assignment display
class WeeklyPlannerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of 7 consecutive dates representing the current week
    @Published var weekDays: [Date] = []
    
    /// Dictionary mapping dates to their meal assignments
    @Published var assignments: [Date: [MealAssignment]] = [:]
    
    /// Dictionary mapping meal IDs to meal objects for quick lookup
    @Published var meals: [UUID: Meal] = [:]
    
    /// The start date of the current week being displayed
    @Published var currentWeekStart: Date
    
    /// Loading state indicator
    @Published var isLoading = false
    
    /// Error message to display to the user, if any
    @Published var errorMessage: String?
    
    /// Whether to show retry option for the last error
    @Published var showRetryOption = false
    
    /// The last failed operation to retry
    private var lastFailedOperation: (() -> Void)?
    
    // MARK: - Dependencies
    
    private let plannerService: PlannerService
    private let mealRepository: MealRepositoryProtocol
    
    // MARK: - Initialization
    
    /// Initialize the view model with dependencies
    /// - Parameters:
    ///   - plannerService: The service to use for planning operations
    ///   - mealRepository: The repository to use for meal data (defaults to MealRepository())
    ///   - startDate: The initial start date for the week (defaults to today)
    init(plannerService: PlannerService,
         mealRepository: MealRepositoryProtocol = MealRepository(),
         startDate: Date = Date()) {
        self.plannerService = plannerService
        self.mealRepository = mealRepository
        self.currentWeekStart = startDate.startOfDay
        loadWeek()
    }
    
    // MARK: - Public Methods
    
    /// Load the current week's data including days, assignments, and meals
    /// Updates isLoading state and handles errors
    /// Requirements: 4.1, 4.2, 6.1, 6.4
    func loadWeek() {
        isLoading = true
        errorMessage = nil
        showRetryOption = false
        
        // Generate 7 consecutive days starting from currentWeekStart
        weekDays = plannerService.generateWeekDays(startingFrom: currentWeekStart)
        
        do {
            // Fetch assignments for all days in the week
            assignments = try plannerService.fetchAssignments(for: weekDays)
            
            // Load all meals and create a lookup dictionary
            let allMeals = try mealRepository.fetchAllMeals()
            meals = Dictionary(uniqueKeysWithValues: allMeals.map { ($0.id, $0) })
        } catch {
            errorMessage = "Unable to load your weekly plan. Please try again."
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                self?.loadWeek()
            }
        }
        
        isLoading = false
    }
    
    /// Navigate forward to the next week (7 days later)
    /// Requirements: 5.1, 5.2
    func navigateForward() {
        guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) else {
            return
        }
        currentWeekStart = nextWeek
        loadWeek()
    }
    
    /// Navigate backward to the previous week (7 days earlier)
    /// Requirements: 5.1, 5.2
    func navigateBackward() {
        guard let previousWeek = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            return
        }
        currentWeekStart = previousWeek
        loadWeek()
    }
    
    /// Assign a meal to a specific date
    /// Reloads the week after successful assignment
    /// - Parameters:
    ///   - mealId: The UUID of the meal to assign
    ///   - date: The date to assign the meal to
    /// Requirements: 6.1, 6.3
    func assignMeal(mealId: UUID, to date: Date) {
        errorMessage = nil
        showRetryOption = false
        
        do {
            try plannerService.assignMeal(mealId: mealId, to: date)
            loadWeek()
        } catch {
            errorMessage = "Unable to assign this meal. Please try again."
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                self?.assignMeal(mealId: mealId, to: date)
            }
        }
    }
    
    /// Remove a meal assignment by ID
    /// Reloads the week after successful removal
    /// - Parameter id: The UUID of the assignment to remove
    /// Requirements: 6.5
    func removeAssignment(id: UUID) {
        errorMessage = nil
        showRetryOption = false
        
        do {
            try plannerService.removeAssignment(id: id)
            loadWeek()
        } catch {
            errorMessage = "Unable to remove this assignment. Please try again."
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                self?.removeAssignment(id: id)
            }
        }
    }
    
    /// Retry the last failed operation
    func retryLastOperation() {
        lastFailedOperation?()
    }
    
    /// Get all meals assigned to a specific day
    /// - Parameter date: The date to get meals for
    /// - Returns: An array of meals assigned to that date
    /// Requirements: 6.4
    func getMealsForDay(_ date: Date) -> [Meal] {
        let normalizedDate = date.startOfDay
        guard let dayAssignments = assignments[normalizedDate] else { return [] }
        return dayAssignments.compactMap { meals[$0.mealId] }
    }
}
