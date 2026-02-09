//
//  AssignmentRepository.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import Foundation

/// Protocol defining the interface for meal assignment data operations
protocol AssignmentRepositoryProtocol {
    func saveAssignment(_ assignment: MealAssignment) throws
    func fetchAllAssignments() throws -> [MealAssignment]
    func fetchAssignments(for date: Date) throws -> [MealAssignment]
    func deleteAssignment(id: UUID) throws
}

/// Repository for managing meal assignment persistence using StorageManager
class AssignmentRepository: AssignmentRepositoryProtocol {
    private let storageManager: StorageManager
    private let assignmentsKey = "mealAssignments"
    
    /// Initialize with a StorageManager instance
    /// - Parameter storageManager: The storage manager to use (defaults to .shared)
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
    }
    
    /// Save a meal assignment to storage
    /// The assignment will be added to the collection
    /// - Parameter assignment: The assignment to save
    /// - Throws: StorageError if the operation fails
    func saveAssignment(_ assignment: MealAssignment) throws {
        var assignments = try fetchAllAssignments()
        assignments.append(assignment)
        try storageManager.save(assignments, forKey: assignmentsKey)
    }
    
    /// Fetch all meal assignments from storage
    /// - Returns: An array of all stored assignments, or an empty array if none exist
    /// - Throws: StorageError if the operation fails
    func fetchAllAssignments() throws -> [MealAssignment] {
        return try storageManager.fetch([MealAssignment].self, forKey: assignmentsKey) ?? []
    }
    
    /// Fetch meal assignments for a specific date
    /// The date will be normalized to start of day for comparison
    /// - Parameter date: The date to fetch assignments for
    /// - Returns: An array of assignments for the specified date
    /// - Throws: StorageError if the operation fails
    func fetchAssignments(for date: Date) throws -> [MealAssignment] {
        let normalizedDate = date.startOfDay
        return try fetchAllAssignments().filter { $0.date == normalizedDate }
    }
    
    /// Delete a meal assignment from storage by ID
    /// - Parameter id: The UUID of the assignment to delete
    /// - Throws: StorageError if the operation fails
    func deleteAssignment(id: UUID) throws {
        var assignments = try fetchAllAssignments()
        assignments.removeAll { $0.id == id }
        try storageManager.save(assignments, forKey: assignmentsKey)
    }
}
