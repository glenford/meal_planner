# Implementation Plan: Meal Planning Assistant

## Overview

This implementation plan breaks down the meal planning assistant feature into discrete, incremental coding tasks. The approach follows a bottom-up strategy: starting with data models and storage, building up through repositories and services, then ViewModels, and finally the UI layer. Each task builds on previous work, with property-based tests integrated close to implementation to catch errors early.

## Tasks

- [x] 1. Set up project structure and core models
  - Create directory structure for Models, Repositories, Services, ViewModels, Views, and Storage
  - Define Meal, MealAssignment, and FilterCriteria models with Codable conformance
  - Add Date extension with startOfDay, dayName, and formatting utilities
  - Set up XCTest target and add SwiftCheck dependency for property-based testing
  - _Requirements: 1.1, 1.2, 6.1_

- [ ] 2. Implement storage layer
  - [x] 2.1 Create StorageManager with generic save/fetch methods
    - Implement StorageManager class with UserDefaults integration
    - Add error types for encoding/decoding failures
    - Include methods for save, fetch, and remove operations
    - _Requirements: 1.3, 6.2, 7.1, 7.2_
  
  - [x] 2.2 Write unit tests for StorageManager
    - Test saving and fetching various Codable types
    - Test error handling for invalid data
    - Mock UserDefaults for isolated testing
    - _Requirements: 1.3, 7.4_

- [ ] 3. Implement repository layer
  - [x] 3.1 Create MealRepository with CRUD operations
    - Implement saveMeal, fetchAllMeals, deleteMeal, updateMeal methods
    - Use StorageManager for persistence
    - Handle meal collection updates (add/update logic)
    - _Requirements: 1.1, 1.2, 1.3, 2.1_
  
  - [x] 3.2 Write property test for MealRepository
    - **Property 1: Meal Persistence Round-Trip**
    - **Property 3: Meal Retrieval Completeness**
    - **Validates: Requirements 1.1, 1.2, 1.3, 2.1, 7.1**
  
  - [x] 3.3 Create AssignmentRepository with CRUD operations
    - Implement saveAssignment, fetchAllAssignments, fetchAssignments(for:), deleteAssignment methods
    - Use StorageManager for persistence
    - Normalize dates to start of day
    - _Requirements: 6.1, 6.2, 6.5_
  
  - [x] 3.4 Write property test for AssignmentRepository
    - **Property 9: Assignment Persistence Round-Trip**
    - **Property 11: Assignment Deletion**
    - **Validates: Requirements 6.1, 6.2, 6.5, 7.2**

- [ ] 4. Implement service layer
  - [x] 4.1 Create FilterService with meal filtering logic
    - Implement filterMeals method with support for protein, carb, and component filters
    - Implement extractUniqueProteins, extractUniqueCarbs, extractUniqueComponents methods
    - Handle case-insensitive matching
    - Support multiple simultaneous filters (AND logic)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [x] 4.2 Write property test for FilterService
    - **Property 5: Filter Correctness**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
  
  - [x] 4.3 Write unit tests for FilterService edge cases
    - Test empty meal list
    - Test no filters applied (returns all)
    - Test filters with no matches
    - _Requirements: 3.5, 3.6_
  
  - [x] 4.4 Create PlannerService with week generation and assignment logic
    - Implement generateWeekDays(startingFrom:) to create 7-day arrays
    - Implement assignMeal(mealId:to:) for creating assignments
    - Implement fetchAssignments(for:) to group assignments by date
    - Implement removeAssignment(id:) for deletion
    - _Requirements: 4.1, 5.1, 5.2, 6.1, 6.3, 6.5_
  
  - [x] 4.5 Write property test for PlannerService
    - **Property 6: Week Generation Consistency**
    - **Property 8: Week Navigation Correctness**
    - **Property 10: Multiple Assignments Per Day**
    - **Property 12: Date Normalization Invariant**
    - **Validates: Requirements 4.1, 4.3, 5.1, 5.2, 5.3, 6.1, 6.3, 6.4**

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement ViewModels
  - [x] 6.1 Create MealFormViewModel
    - Implement @Published properties for form fields
    - Implement addComponent, removeComponent, saveMeal methods
    - Add validation for empty descriptions
    - Include error handling and onSaveComplete callback
    - _Requirements: 1.1, 1.2, 1.4, 1.5_
  
  - [ ]* 6.2 Write property test for MealFormViewModel
    - **Property 2: Invalid Meal Rejection**
    - **Validates: Requirements 1.4**
  
  - [ ]* 6.3 Write unit tests for MealFormViewModel
    - Test successful meal creation
    - Test component addition and removal
    - Test validation error messages
    - _Requirements: 1.1, 1.4_
  
  - [x] 6.4 Create MealListViewModel
    - Implement @Published properties for meals, filteredMeals, filterCriteria
    - Implement loadMeals, applyFilters, deleteMeal methods
    - Add computed properties for available filters (proteins, carbs, components)
    - Include loading states and error handling
    - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.3, 3.4_
  
  - [ ]* 6.5 Write unit tests for MealListViewModel
    - Test meal loading
    - Test filter application
    - Test meal deletion
    - Mock MealRepository for isolated testing
    - _Requirements: 2.1, 3.1, 3.2, 3.3, 3.4_
  
  - [x] 6.6 Create WeeklyPlannerViewModel
    - Implement @Published properties for weekDays, assignments, meals, currentWeekStart
    - Implement loadWeek, navigateForward, navigateBackward methods
    - Implement assignMeal, removeAssignment, getMealsForDay methods
    - Include loading states and error handling
    - _Requirements: 4.1, 4.2, 5.1, 5.2, 6.1, 6.3, 6.4, 6.5_
  
  - [ ]* 6.7 Write unit tests for WeeklyPlannerViewModel
    - Test week loading
    - Test forward/backward navigation
    - Test meal assignment and removal
    - Mock repositories for isolated testing
    - _Requirements: 4.1, 5.1, 5.2, 6.1, 6.5_

- [ ] 7. Implement SwiftUI Views
  - [x] 7.1 Create MealFormView
    - Build form UI with TextField for description, protein, carb
    - Add list for other components with add/remove functionality
    - Include save button with validation feedback
    - Display error messages when validation fails
    - _Requirements: 1.1, 1.2, 1.4_
  
  - [x] 7.2 Create MealListView
    - Build list UI displaying all meals with their nutritional info
    - Add filter controls for protein, carb, and components
    - Include navigation to MealFormView for adding new meals
    - Display empty state when no meals exist or filters produce no results
    - Add swipe-to-delete functionality
    - Implement requirement 2.5: meals already in plan shown at end with grey background and italics
    - _Requirements: 2.1, 2.2, 2.3, 2.5, 3.1, 3.2, 3.3, 3.4, 3.6_
  
  - [ ]* 7.3 Write property test for meal display
    - **Property 4: Meal Display Completeness**
    - **Validates: Requirements 2.2**
  
  - [x] 7.4 Create WeeklyPlannerView
    - Build week view UI showing 7 days in a scrollable layout
    - Display day name, date, and assigned meals for each day
    - Add forward/backward navigation buttons
    - Include meal selection interface for assigning meals to days
    - Display empty state for days with no assignments
    - Add remove functionality for assignments
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 6.1, 6.3, 6.4, 6.5_
  
  - [ ]* 7.5 Write property test for day display
    - **Property 7: Day Display Completeness**
    - **Validates: Requirements 4.2**
  
  - [x] 7.6 Create main ContentView with tab navigation
    - Set up TabView with three tabs: Meal List, Add Meal, Weekly Planner
    - Wire up ViewModels to Views
    - Ensure proper navigation flow between views
    - _Requirements: All_

- [-] 8. Implement app initialization and data loading
  - [x] 8.1 Set up app entry point
    - Configure App struct with proper initialization
    - Initialize shared repositories and services
    - Load initial data on app launch
    - _Requirements: 7.3_
  
  - [ ]* 8.2 Write unit test for storage failure handling
    - Test error notification when storage fails
    - Verify data remains in memory on storage failure
    - _Requirements: 7.4_

- [x] 9. Polish and refinement
  - [x] 9.1 Add loading indicators
    - Show loading states during data fetch operations
    - Add pull-to-refresh on meal list
    - _Requirements: 8.2_
  
  - [x] 9.2 Improve error messaging
    - Ensure all error messages are user-friendly
    - Add retry options where appropriate
    - Test all error paths
    - _Requirements: 7.4_
  
  - [x] 9.3 Add visual feedback for user actions
    - Ensure immediate feedback for all interactions
    - Add animations for state transitions
    - Test responsiveness across different devices
    - _Requirements: 8.1, 8.3, 8.4_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Run all unit tests and property tests
  - Verify all requirements are met
  - Test on iOS simulator and physical device
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties with minimum 100 iterations
- Unit tests validate specific examples and edge cases
- SwiftCheck should be configured for property-based testing
- All ViewModels use dependency injection for testability
- Date normalization is critical for consistent assignment behavior
