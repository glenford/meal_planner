//
//  MealFormViewModel.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation
import Combine

/// ViewModel for managing meal form state and operations
/// Handles user input, validation, and meal creation
class MealFormViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The meal description entered by the user
    @Published var description: String = ""
    
    /// The primary protein for the meal
    @Published var primaryProtein: String = ""
    
    /// The primary carbohydrate for the meal
    @Published var primaryCarb: String = ""
    
    /// List of other nutritional components
    @Published var otherComponents: [String] = []
    
    /// Temporary field for entering a new component
    @Published var newComponent: String = ""
    
    /// Error message to display to the user, if any
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let mealRepository: MealRepositoryProtocol
    
    /// Callback invoked when a meal is successfully saved
    var onSaveComplete: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize the view model with a meal repository
    /// - Parameter mealRepository: The repository to use for meal persistence (defaults to MealRepository())
    init(mealRepository: MealRepositoryProtocol = MealRepository()) {
        self.mealRepository = mealRepository
    }
    
    // MARK: - Public Methods
    
    /// Add the current newComponent to the otherComponents list
    /// Trims whitespace and ignores empty strings
    func addComponent() {
        let trimmed = newComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        otherComponents.append(trimmed)
        newComponent = ""
    }
    
    /// Remove a component from the otherComponents list at the specified index
    /// - Parameter index: The index of the component to remove
    func removeComponent(at index: Int) {
        guard index >= 0 && index < otherComponents.count else { return }
        otherComponents.remove(at: index)
    }
    
    /// Clear all form fields to prepare for entering a new meal
    func clearForm() {
        description = ""
        primaryProtein = ""
        primaryCarb = ""
        otherComponents = []
        newComponent = ""
        errorMessage = nil
    }
    
    /// Save the meal with current form data
    /// Validates that description is not empty, then creates and persists the meal
    /// Calls onSaveComplete callback on success
    func saveMeal() {
        errorMessage = nil
        
        // Validate description is not empty (Requirement 1.4)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Please enter a meal description to continue."
            return
        }
        
        // Create meal with current form data (Requirements 1.1, 1.2)
        let meal = Meal(
            description: trimmedDescription,
            primaryProtein: primaryProtein,
            primaryCarb: primaryCarb,
            otherComponents: otherComponents
        )
        
        do {
            // Persist meal immediately (Requirement 1.3)
            try mealRepository.saveMeal(meal)
            
            // Clear form for next entry
            clearForm()
            
            onSaveComplete?()
        } catch {
            // Handle storage errors (Requirement 1.5)
            errorMessage = "Unable to save your meal. Please try again."
        }
    }
}
