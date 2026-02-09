//
//  AssignmentRepositoryTests.swift
//  MyAppTests
//
//  Created for Meal Planning Assistant
//

import XCTest
@testable import MealPlanner

class AssignmentRepositoryTests: XCTestCase {
    var repository: AssignmentRepository!
    var mockUserDefaults: UserDefaults!
    var mockStorageManager: StorageManager!
    
    override func setUp() {
        super.setUp()
        // Use a unique suite name for each test to ensure isolation
        mockUserDefaults = UserDefaults(suiteName: "AssignmentRepositoryTests_\(UUID().uuidString)")!
        mockStorageManager = StorageManager(userDefaults: mockUserDefaults)
        repository = AssignmentRepository(storageManager: mockStorageManager)
    }
    
    override func tearDown() {
        // Clean up the test suite
        mockUserDefaults.removePersistentDomain(forName: "AssignmentRepositoryTests")
        mockUserDefaults = nil
        mockStorageManager = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Save Assignment Tests
    
    func testSaveAssignment_NewAssignment_ShouldPersist() throws {
        // Given
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        
        // When
        try repository.saveAssignment(assignment)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.id, assignment.id)
        XCTAssertEqual(assignments.first?.mealId, mealId)
        XCTAssertEqual(assignments.first?.date, date.startOfDay)
    }
    
    func testSaveAssignment_MultipleAssignments_ShouldPersistAll() throws {
        // Given
        let mealId1 = UUID()
        let mealId2 = UUID()
        let mealId3 = UUID()
        let date = Date()
        
        let assignment1 = MealAssignment(mealId: mealId1, date: date)
        let assignment2 = MealAssignment(mealId: mealId2, date: date)
        let assignment3 = MealAssignment(mealId: mealId3, date: date)
        
        // When
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        try repository.saveAssignment(assignment3)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        XCTAssertEqual(assignments.count, 3)
        XCTAssertTrue(assignments.contains(where: { $0.id == assignment1.id }))
        XCTAssertTrue(assignments.contains(where: { $0.id == assignment2.id }))
        XCTAssertTrue(assignments.contains(where: { $0.id == assignment3.id }))
    }
    
    func testSaveAssignment_DateNormalization_ShouldNormalizeToStartOfDay() throws {
        // Given
        let mealId = UUID()
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 1, day: 15, hour: 14, minute: 30, second: 45)
        let dateWithTime = calendar.date(from: components)!
        let assignment = MealAssignment(mealId: mealId, date: dateWithTime)
        
        // When
        try repository.saveAssignment(assignment)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        let savedDate = assignments.first?.date
        
        let savedComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: savedDate!)
        XCTAssertEqual(savedComponents.year, 2024)
        XCTAssertEqual(savedComponents.month, 1)
        XCTAssertEqual(savedComponents.day, 15)
        XCTAssertEqual(savedComponents.hour, 0)
        XCTAssertEqual(savedComponents.minute, 0)
        XCTAssertEqual(savedComponents.second, 0)
    }
    
    // MARK: - Fetch All Assignments Tests
    
    func testFetchAllAssignments_EmptyStorage_ShouldReturnEmptyArray() throws {
        // When
        let assignments = try repository.fetchAllAssignments()
        
        // Then
        XCTAssertEqual(assignments.count, 0)
        XCTAssertTrue(assignments.isEmpty)
    }
    
    func testFetchAllAssignments_WithAssignments_ShouldReturnAllAssignments() throws {
        // Given
        let mealId1 = UUID()
        let mealId2 = UUID()
        let date = Date()
        
        let assignment1 = MealAssignment(mealId: mealId1, date: date)
        let assignment2 = MealAssignment(mealId: mealId2, date: date)
        
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        
        // When
        let assignments = try repository.fetchAllAssignments()
        
        // Then
        XCTAssertEqual(assignments.count, 2)
    }
    
    // MARK: - Fetch Assignments for Date Tests
    
    func testFetchAssignmentsForDate_NoAssignments_ShouldReturnEmptyArray() throws {
        // Given
        let date = Date()
        
        // When
        let assignments = try repository.fetchAssignments(for: date)
        
        // Then
        XCTAssertEqual(assignments.count, 0)
        XCTAssertTrue(assignments.isEmpty)
    }
    
    func testFetchAssignmentsForDate_WithMatchingAssignments_ShouldReturnOnlyMatchingDate() throws {
        // Given
        let mealId1 = UUID()
        let mealId2 = UUID()
        let mealId3 = UUID()
        
        let calendar = Calendar.current
        let today = Date().startOfDay
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let assignment1 = MealAssignment(mealId: mealId1, date: today)
        let assignment2 = MealAssignment(mealId: mealId2, date: today)
        let assignment3 = MealAssignment(mealId: mealId3, date: tomorrow)
        
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        try repository.saveAssignment(assignment3)
        
        // When
        let todayAssignments = try repository.fetchAssignments(for: today)
        let tomorrowAssignments = try repository.fetchAssignments(for: tomorrow)
        
        // Then
        XCTAssertEqual(todayAssignments.count, 2)
        XCTAssertTrue(todayAssignments.contains(where: { $0.id == assignment1.id }))
        XCTAssertTrue(todayAssignments.contains(where: { $0.id == assignment2.id }))
        
        XCTAssertEqual(tomorrowAssignments.count, 1)
        XCTAssertEqual(tomorrowAssignments.first?.id, assignment3.id)
    }
    
    func testFetchAssignmentsForDate_DateNormalization_ShouldMatchRegardlessOfTime() throws {
        // Given
        let mealId = UUID()
        let calendar = Calendar.current
        
        // Create assignment at midnight
        let midnightComponents = DateComponents(year: 2024, month: 1, day: 15, hour: 0, minute: 0)
        let midnightDate = calendar.date(from: midnightComponents)!
        let assignment = MealAssignment(mealId: mealId, date: midnightDate)
        try repository.saveAssignment(assignment)
        
        // When - Query with different time on same day
        let afternoonComponents = DateComponents(year: 2024, month: 1, day: 15, hour: 14, minute: 30)
        let afternoonDate = calendar.date(from: afternoonComponents)!
        let assignments = try repository.fetchAssignments(for: afternoonDate)
        
        // Then
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.id, assignment.id)
    }
    
    func testFetchAssignmentsForDate_MultipleAssignmentsSameDay_ShouldReturnAll() throws {
        // Given
        let mealId1 = UUID()
        let mealId2 = UUID()
        let mealId3 = UUID()
        let date = Date()
        
        let assignment1 = MealAssignment(mealId: mealId1, date: date)
        let assignment2 = MealAssignment(mealId: mealId2, date: date)
        let assignment3 = MealAssignment(mealId: mealId3, date: date)
        
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        try repository.saveAssignment(assignment3)
        
        // When
        let assignments = try repository.fetchAssignments(for: date)
        
        // Then
        XCTAssertEqual(assignments.count, 3)
    }
    
    // MARK: - Delete Assignment Tests
    
    func testDeleteAssignment_ExistingAssignment_ShouldRemove() throws {
        // Given
        let mealId1 = UUID()
        let mealId2 = UUID()
        let date = Date()
        
        let assignment1 = MealAssignment(mealId: mealId1, date: date)
        let assignment2 = MealAssignment(mealId: mealId2, date: date)
        
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        
        // When
        try repository.deleteAssignment(id: assignment1.id)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.id, assignment2.id)
        XCTAssertFalse(assignments.contains(where: { $0.id == assignment1.id }))
    }
    
    func testDeleteAssignment_NonExistentAssignment_ShouldNotAffectStorage() throws {
        // Given
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        try repository.saveAssignment(assignment)
        
        let nonExistentId = UUID()
        
        // When
        try repository.deleteAssignment(id: nonExistentId)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.id, assignment.id)
    }
    
    func testDeleteAssignment_LastAssignment_ShouldResultInEmptyStorage() throws {
        // Given
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        try repository.saveAssignment(assignment)
        
        // When
        try repository.deleteAssignment(id: assignment.id)
        
        // Then
        let assignments = try repository.fetchAllAssignments()
        XCTAssertEqual(assignments.count, 0)
        XCTAssertTrue(assignments.isEmpty)
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence_SaveAndFetch_ShouldMaintainData() throws {
        // Given
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        try repository.saveAssignment(assignment)
        
        // When - Create a new repository instance with same storage
        let newRepository = AssignmentRepository(storageManager: mockStorageManager)
        let assignments = try newRepository.fetchAllAssignments()
        
        // Then
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.id, assignment.id)
        XCTAssertEqual(assignments.first?.mealId, mealId)
    }
    
    func testPersistence_MultipleOperations_ShouldMaintainConsistency() throws {
        // Given
        let calendar = Calendar.current
        let today = Date().startOfDay
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let mealId1 = UUID()
        let mealId2 = UUID()
        let mealId3 = UUID()
        
        let assignment1 = MealAssignment(mealId: mealId1, date: today)
        let assignment2 = MealAssignment(mealId: mealId2, date: today)
        let assignment3 = MealAssignment(mealId: mealId3, date: tomorrow)
        
        // When
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        try repository.saveAssignment(assignment3)
        try repository.deleteAssignment(id: assignment2.id)
        
        // Then
        let allAssignments = try repository.fetchAllAssignments()
        XCTAssertEqual(allAssignments.count, 2)
        XCTAssertTrue(allAssignments.contains(where: { $0.id == assignment1.id }))
        XCTAssertTrue(allAssignments.contains(where: { $0.id == assignment3.id }))
        XCTAssertFalse(allAssignments.contains(where: { $0.id == assignment2.id }))
        
        let todayAssignments = try repository.fetchAssignments(for: today)
        XCTAssertEqual(todayAssignments.count, 1)
        XCTAssertEqual(todayAssignments.first?.id, assignment1.id)
    }
    
    // MARK: - Edge Cases
    
    func testSaveAssignment_SameMealDifferentDays_ShouldPersistBoth() throws {
        // Given
        let mealId = UUID()
        let calendar = Calendar.current
        let today = Date().startOfDay
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let assignment1 = MealAssignment(mealId: mealId, date: today)
        let assignment2 = MealAssignment(mealId: mealId, date: tomorrow)
        
        // When
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        
        // Then
        let allAssignments = try repository.fetchAllAssignments()
        XCTAssertEqual(allAssignments.count, 2)
        
        let todayAssignments = try repository.fetchAssignments(for: today)
        XCTAssertEqual(todayAssignments.count, 1)
        
        let tomorrowAssignments = try repository.fetchAssignments(for: tomorrow)
        XCTAssertEqual(tomorrowAssignments.count, 1)
    }
    
    func testFetchAssignmentsForDate_DifferentDates_ShouldNotInterfere() throws {
        // Given
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        let date3 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 3))!
        
        let assignment1 = MealAssignment(mealId: UUID(), date: date1)
        let assignment2 = MealAssignment(mealId: UUID(), date: date2)
        let assignment3 = MealAssignment(mealId: UUID(), date: date3)
        
        try repository.saveAssignment(assignment1)
        try repository.saveAssignment(assignment2)
        try repository.saveAssignment(assignment3)
        
        // When
        let assignments1 = try repository.fetchAssignments(for: date1)
        let assignments2 = try repository.fetchAssignments(for: date2)
        let assignments3 = try repository.fetchAssignments(for: date3)
        
        // Then
        XCTAssertEqual(assignments1.count, 1)
        XCTAssertEqual(assignments1.first?.id, assignment1.id)
        
        XCTAssertEqual(assignments2.count, 1)
        XCTAssertEqual(assignments2.first?.id, assignment2.id)
        
        XCTAssertEqual(assignments3.count, 1)
        XCTAssertEqual(assignments3.first?.id, assignment3.id)
    }
}
