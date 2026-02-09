//
//  AssignmentRepositoryPropertyTests.swift
//  MyAppTests
//
//  Property-based tests for AssignmentRepository
//  Feature: meal-planning-assistant
//

import XCTest
import SwiftCheck
@testable import MealPlanner

/// Property-based tests for AssignmentRepository using SwiftCheck
/// These tests verify universal correctness properties across randomized inputs
class AssignmentRepositoryPropertyTests: XCTestCase {
    var repository: AssignmentRepository!
    var mockUserDefaults: UserDefaults!
    var mockStorageManager: StorageManager!
    
    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to ensure isolation
        mockUserDefaults = UserDefaults(suiteName: "AssignmentRepositoryPropertyTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = AssignmentRepository(storageManager: mockStorageManager)
    }
    
    override func tearDown() {
        // Clean up the test suite
        if let suiteName = mockUserDefaults.dictionaryRepresentation().keys.first {
            mockUserDefaults.removePersistentDomain(forName: suiteName)
        }
        mockUserDefaults = nil
        mockStorageManager = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Property 9: Assignment Persistence Round-Trip
    
    /// **Validates: Requirements 6.1, 6.2, 7.2**
    ///
    /// Property 9: Assignment Persistence Round-Trip
    /// For any valid meal and date, creating an assignment and then fetching
    /// assignments for that date should return a collection that includes an
    /// assignment linking that meal to that date.
    func testProperty9_AssignmentPersistenceRoundTrip() {
        property("Saving an assignment and fetching should return the same assignment data") <- forAll { (assignment: ArbitraryAssignment) in
            // Reset storage for each iteration
            self.resetStorage()
            
            // Given: A valid assignment
            let testAssignment = assignment.value
            
            // When: Save the assignment and fetch assignments for that date
            do {
                try self.repository.saveAssignment(testAssignment)
                let fetchedAssignments = try self.repository.fetchAssignments(for: testAssignment.date)
                
                // Then: The fetched assignments should contain an assignment with identical properties
                guard let savedAssignment = fetchedAssignments.first(where: { $0.id == testAssignment.id }) else {
                    return false <?> "Assignment not found in fetched results"
                }
                
                // Verify all properties match
                let idMatches = savedAssignment.id == testAssignment.id
                let mealIdMatches = savedAssignment.mealId == testAssignment.mealId
                let dateMatches = savedAssignment.date == testAssignment.date
                
                guard idMatches && mealIdMatches && dateMatches else {
                    return false <?> "Assignment properties don't match"
                }
                
                return true
            } catch {
                return false <?> "Storage operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Property 11: Assignment Deletion
    
    /// **Validates: Requirements 6.5**
    ///
    /// Property 11: Assignment Deletion
    /// For any assignment that has been created, deleting that assignment and then
    /// fetching assignments for its date should return a collection that does not
    /// include that assignment.
    func testProperty11_AssignmentDeletion() {
        property("Deleting an assignment removes it from storage") <- forAll { (assignment: ArbitraryAssignment) in
            // Reset storage for each iteration
            self.resetStorage()
            
            // Given: A saved assignment
            let testAssignment = assignment.value
            
            do {
                try self.repository.saveAssignment(testAssignment)
                
                // Verify it was saved
                let beforeDelete = try self.repository.fetchAssignments(for: testAssignment.date)
                guard beforeDelete.contains(where: { $0.id == testAssignment.id }) else {
                    return false <?> "Assignment was not saved properly"
                }
                
                // When: Delete the assignment
                try self.repository.deleteAssignment(id: testAssignment.id)
                
                // Then: Fetching assignments for that date should not include the deleted assignment
                let afterDelete = try self.repository.fetchAssignments(for: testAssignment.date)
                let stillExists = afterDelete.contains(where: { $0.id == testAssignment.id })
                
                return !stillExists <?> "Assignment still exists after deletion"
            } catch {
                return false <?> "Storage operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Additional Property: Multiple Assignments Persistence
    
    /// Additional property test to verify multiple assignments can be saved and retrieved
    /// This supports Property 10 (Multiple Assignments Per Day) from the design document
    func testProperty_MultipleAssignmentsPersistence() {
        property("Multiple assignments for the same date are all persisted") <- forAll { (assignments: ArbitraryAssignmentArray) in
            // Reset storage for each iteration
            self.resetStorage()
            
            // Given: Multiple assignments for the same date
            let testAssignments = assignments.value
            guard !testAssignments.isEmpty else {
                return true // Empty case is trivially true
            }
            
            let testDate = testAssignments[0].date
            
            // When: Save all assignments
            do {
                for assignment in testAssignments {
                    try self.repository.saveAssignment(assignment)
                }
                
                // Then: Fetching assignments for that date should return all of them
                let fetchedAssignments = try self.repository.fetchAssignments(for: testDate)
                
                // Verify count matches
                guard fetchedAssignments.count == testAssignments.count else {
                    return false <?> "Count mismatch: expected \(testAssignments.count), got \(fetchedAssignments.count)"
                }
                
                // Verify all assignment IDs are present
                let savedIds = Set(testAssignments.map { $0.id })
                let fetchedIds = Set(fetchedAssignments.map { $0.id })
                
                guard savedIds == fetchedIds else {
                    return false <?> "ID sets don't match"
                }
                
                // Verify each assignment's properties match
                for testAssignment in testAssignments {
                    guard let fetchedAssignment = fetchedAssignments.first(where: { $0.id == testAssignment.id }) else {
                        return false <?> "Assignment with ID \(testAssignment.id) not found"
                    }
                    
                    if fetchedAssignment.mealId != testAssignment.mealId ||
                       fetchedAssignment.date != testAssignment.date {
                        return false <?> "Assignment properties don't match for ID \(testAssignment.id)"
                    }
                }
                
                return true
            } catch {
                return false <?> "Storage operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Helper Methods
    
    /// Reset storage between test iterations
    private func resetStorage() {
        // Create a new storage manager with a fresh UserDefaults suite
        mockUserDefaults = UserDefaults(suiteName: "AssignmentRepositoryPropertyTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = AssignmentRepository(storageManager: mockStorageManager)
    }
}

// MARK: - Arbitrary Generators

/// Generator for arbitrary MealAssignment instances
struct ArbitraryAssignment: Arbitrary {
    let value: MealAssignment
    
    static var arbitrary: Gen<ArbitraryAssignment> {
        return Gen.compose { composer in
            // Generate a random meal ID
            let mealId = UUID()
            
            // Generate a random date within a reasonable range
            // Use dates from 30 days ago to 30 days in the future
            let daysOffset = composer.generate(using: Gen<Int>.choose((-30, 30)))
            let calendar = Calendar.current
            let baseDate = Date()
            let date = calendar.date(byAdding: .day, value: daysOffset, to: baseDate) ?? baseDate
            
            let assignment = MealAssignment(
                mealId: mealId,
                date: date
            )
            
            return ArbitraryAssignment(value: assignment)
        }
    }
}

/// Generator for arbitrary arrays of MealAssignments for the same date (1-10 assignments)
struct ArbitraryAssignmentArray: Arbitrary {
    let value: [MealAssignment]
    
    static var arbitrary: Gen<ArbitraryAssignmentArray> {
        return Gen.compose { composer in
            // Generate 1-10 assignments
            let count = composer.generate(using: Gen<Int>.choose((1, 10)))
            
            // Generate a single date for all assignments
            let daysOffset = composer.generate(using: Gen<Int>.choose((-30, 30)))
            let calendar = Calendar.current
            let baseDate = Date()
            let sharedDate = calendar.date(byAdding: .day, value: daysOffset, to: baseDate) ?? baseDate
            
            var assignments: [MealAssignment] = []
            
            for _ in 0..<count {
                // Each assignment has a unique meal ID but shares the same date
                let mealId = UUID()
                let assignment = MealAssignment(
                    mealId: mealId,
                    date: sharedDate
                )
                assignments.append(assignment)
            }
            
            return ArbitraryAssignmentArray(value: assignments)
        }
    }
}
