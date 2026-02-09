//
//  PlannerService.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

/// Service for managing weekly meal planning operations
/// Handles week generation, meal assignments, and assignment retrieval
class PlannerService {
    private let assignmentRepository: AssignmentRepositoryProtocol
    
    /// Initialize with an assignment repository
    /// - Parameter assignmentRepository: The repository to use for assignment persistence
    init(assignmentRepository: AssignmentRepositoryProtocol) {
        self.assignmentRepository = assignmentRepository
    }
    
    /// Generate an array of 7 consecutive dates starting from the given date
    /// - Parameter date: The starting date (will be normalized to start of day)
    /// - Returns: An array of 7 consecutive dates in chronological order
    func generateWeekDays(startingFrom date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = date.startOfDay
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    /// Assign a meal to a specific date
    /// Creates a new MealAssignment and persists it
    /// - Parameters:
    ///   - mealId: The UUID of the meal to assign
    ///   - date: The date to assign the meal to (will be normalized to start of day)
    /// - Throws: StorageError if the operation fails
    func assignMeal(mealId: UUID, to date: Date) throws {
        let assignment = MealAssignment(mealId: mealId, date: date)
        try assignmentRepository.saveAssignment(assignment)
    }
    
    /// Fetch assignments for multiple dates and group them by date
    /// - Parameter dates: An array of dates to fetch assignments for
    /// - Returns: A dictionary mapping normalized dates to their assignments
    /// - Throws: StorageError if the operation fails
    func fetchAssignments(for dates: [Date]) throws -> [Date: [MealAssignment]] {
        let allAssignments = try assignmentRepository.fetchAllAssignments()
        var grouped: [Date: [MealAssignment]] = [:]
        
        for date in dates {
            let normalizedDate = date.startOfDay
            grouped[normalizedDate] = allAssignments.filter { $0.date == normalizedDate }
        }
        
        return grouped
    }
    
    /// Remove a meal assignment by ID
    /// - Parameter id: The UUID of the assignment to remove
    /// - Throws: StorageError if the operation fails
    func removeAssignment(id: UUID) throws {
        try assignmentRepository.deleteAssignment(id: id)
    }
}
