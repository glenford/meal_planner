//
//  PlannerServiceTests.swift
//  MyAppTests
//
//  Unit tests for PlannerService
//  Feature: meal-planning-assistant
//

import XCTest
@testable import MealPlanner

/// Unit tests for PlannerService focusing on specific examples and edge cases
/// **Validates: Requirements 4.1, 5.1, 5.2, 6.1, 6.3, 6.5**
class PlannerServiceTests: XCTestCase {
    var plannerService: PlannerService!
    var mockRepository: MockAssignmentRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAssignmentRepository()
        plannerService = PlannerService(assignmentRepository: mockRepository)
    }
    
    override func tearDown() {
        plannerService = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Week Generation Tests
    
    /// Test generating a week from a specific date produces 7 consecutive days
    /// **Validates: Requirement 4.1**
    func testGenerateWeekDays_FromSpecificDate_Returns7ConsecutiveDays() {
        // Given: A specific starting date (January 1, 2024)
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        // When: Generating week days
        let weekDays = plannerService.generateWeekDays(startingFrom: startDate)
        
        // Then: Should return exactly 7 days
        XCTAssertEqual(weekDays.count, 7, "Week should contain exactly 7 days")
        
        // And: Days should be consecutive
        for i in 0..<6 {
            let currentDay = weekDays[i]
            let nextDay = weekDays[i + 1]
            let daysBetween = calendar.dateComponents([.day], from: currentDay, to: nextDay).day
            XCTAssertEqual(daysBetween, 1, "Days should be consecutive")
        }
        
        // And: First day should be the start date (normalized)
        XCTAssertEqual(weekDays[0], startDate.startOfDay, "First day should be the start date")
    }
    
    /// Test generating a week normalizes the start date to start of day
    /// **Validates: Requirement 4.1**
    func testGenerateWeekDays_WithTimeComponent_NormalizesToStartOfDay() {
        // Given: A date with a time component (3:45 PM)
        let calendar = Calendar.current
        let dateWithTime = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 15, minute: 45))!
        
        // When: Generating week days
        let weekDays = plannerService.generateWeekDays(startingFrom: dateWithTime)
        
        // Then: First day should be normalized to start of day
        let expectedStartOfDay = calendar.startOfDay(for: dateWithTime)
        XCTAssertEqual(weekDays[0], expectedStartOfDay, "Start date should be normalized to start of day")
        
        // And: All days should be at start of day (midnight)
        for day in weekDays {
            let components = calendar.dateComponents([.hour, .minute, .second], from: day)
            XCTAssertEqual(components.hour, 0, "Hour should be 0")
            XCTAssertEqual(components.minute, 0, "Minute should be 0")
            XCTAssertEqual(components.second, 0, "Second should be 0")
        }
    }
    
    /// Test generating a week from today's date
    /// **Validates: Requirement 4.1**
    func testGenerateWeekDays_FromToday_Returns7DaysStartingToday() {
        // Given: Today's date
        let today = Date()
        
        // When: Generating week days
        let weekDays = plannerService.generateWeekDays(startingFrom: today)
        
        // Then: Should return 7 days starting from today
        XCTAssertEqual(weekDays.count, 7, "Week should contain exactly 7 days")
        XCTAssertEqual(weekDays[0], today.startOfDay, "First day should be today (normalized)")
    }
    
    /// Test generating a week across month boundary
    /// **Validates: Requirement 4.1**
    func testGenerateWeekDays_AcrossMonthBoundary_HandlesCorrectly() {
        // Given: A date near the end of a month (January 29, 2024)
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 29))!
        
        // When: Generating week days
        let weekDays = plannerService.generateWeekDays(startingFrom: startDate)
        
        // Then: Should return 7 days spanning into February
        XCTAssertEqual(weekDays.count, 7, "Week should contain exactly 7 days")
        
        // And: Last day should be in February
        let lastDayComponents = calendar.dateComponents([.year, .month, .day], from: weekDays[6])
        XCTAssertEqual(lastDayComponents.month, 2, "Last day should be in February")
        XCTAssertEqual(lastDayComponents.day, 4, "Last day should be February 4")
    }
    
    /// Test generating a week across year boundary
    /// **Validates: Requirement 4.1**
    func testGenerateWeekDays_AcrossYearBoundary_HandlesCorrectly() {
        // Given: A date near the end of a year (December 29, 2023)
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2023, month: 12, day: 29))!
        
        // When: Generating week days
        let weekDays = plannerService.generateWeekDays(startingFrom: startDate)
        
        // Then: Should return 7 days spanning into 2024
        XCTAssertEqual(weekDays.count, 7, "Week should contain exactly 7 days")
        
        // And: Last days should be in 2024
        let lastDayComponents = calendar.dateComponents([.year, .month, .day], from: weekDays[6])
        XCTAssertEqual(lastDayComponents.year, 2024, "Last day should be in 2024")
        XCTAssertEqual(lastDayComponents.month, 1, "Last day should be in January")
    }
    
    // MARK: - Meal Assignment Tests
    
    /// Test assigning a meal to a date creates an assignment
    /// **Validates: Requirement 6.1**
    func testAssignMeal_ToDate_CreatesAssignment() throws {
        // Given: A meal ID and a date
        let mealId = UUID()
        let date = Date()
        
        // When: Assigning the meal to the date
        try plannerService.assignMeal(mealId: mealId, to: date)
        
        // Then: Repository should have saved an assignment
        XCTAssertEqual(mockRepository.savedAssignments.count, 1, "Should save one assignment")
        
        let savedAssignment = mockRepository.savedAssignments[0]
        XCTAssertEqual(savedAssignment.mealId, mealId, "Assignment should have correct meal ID")
        XCTAssertEqual(savedAssignment.date, date.startOfDay, "Assignment should have normalized date")
    }
    
    /// Test assigning multiple meals to the same date
    /// **Validates: Requirement 6.3**
    func testAssignMeal_MultipleMealsToSameDate_CreatesMultipleAssignments() throws {
        // Given: Multiple meal IDs and the same date
        let mealId1 = UUID()
        let mealId2 = UUID()
        let mealId3 = UUID()
        let date = Date()
        
        // When: Assigning multiple meals to the same date
        try plannerService.assignMeal(mealId: mealId1, to: date)
        try plannerService.assignMeal(mealId: mealId2, to: date)
        try plannerService.assignMeal(mealId: mealId3, to: date)
        
        // Then: Repository should have saved three assignments
        XCTAssertEqual(mockRepository.savedAssignments.count, 3, "Should save three assignments")
        
        // And: All assignments should be for the same date
        let uniqueDates = Set(mockRepository.savedAssignments.map { $0.date })
        XCTAssertEqual(uniqueDates.count, 1, "All assignments should be for the same date")
        XCTAssertEqual(uniqueDates.first, date.startOfDay, "Date should be normalized")
    }
    
    /// Test assigning a meal normalizes the date to start of day
    /// **Validates: Requirement 6.1**
    func testAssignMeal_WithTimeComponent_NormalizesDate() throws {
        // Given: A meal ID and a date with time component
        let mealId = UUID()
        let calendar = Calendar.current
        let dateWithTime = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14, minute: 30))!
        
        // When: Assigning the meal
        try plannerService.assignMeal(mealId: mealId, to: dateWithTime)
        
        // Then: Assignment should have normalized date
        let savedAssignment = mockRepository.savedAssignments[0]
        XCTAssertEqual(savedAssignment.date, dateWithTime.startOfDay, "Date should be normalized to start of day")
    }
    
    // MARK: - Fetch Assignments Tests
    
    /// Test fetching assignments for multiple dates groups them correctly
    /// **Validates: Requirement 6.4**
    func testFetchAssignments_ForMultipleDates_GroupsByDate() throws {
        // Given: Assignments for different dates
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!
        let date3 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 3))!
        
        let assignment1 = MealAssignment(mealId: UUID(), date: date1)
        let assignment2 = MealAssignment(mealId: UUID(), date: date1)
        let assignment3 = MealAssignment(mealId: UUID(), date: date2)
        
        mockRepository.assignments = [assignment1, assignment2, assignment3]
        
        // When: Fetching assignments for these dates
        let dates = [date1, date2, date3]
        let grouped = try plannerService.fetchAssignments(for: dates)
        
        // Then: Should group assignments by date
        XCTAssertEqual(grouped.keys.count, 3, "Should have entries for all 3 dates")
        XCTAssertEqual(grouped[date1.startOfDay]?.count, 2, "Date1 should have 2 assignments")
        XCTAssertEqual(grouped[date2.startOfDay]?.count, 1, "Date2 should have 1 assignment")
        XCTAssertEqual(grouped[date3.startOfDay]?.count, 0, "Date3 should have 0 assignments")
    }
    
    /// Test fetching assignments for dates with no assignments returns empty arrays
    /// **Validates: Requirement 4.4**
    func testFetchAssignments_ForDatesWithNoAssignments_ReturnsEmptyArrays() throws {
        // Given: No assignments in repository
        mockRepository.assignments = []
        
        // When: Fetching assignments for a week
        let startDate = Date()
        let weekDays = plannerService.generateWeekDays(startingFrom: startDate)
        let grouped = try plannerService.fetchAssignments(for: weekDays)
        
        // Then: All dates should have empty arrays
        XCTAssertEqual(grouped.keys.count, 7, "Should have entries for all 7 dates")
        for date in weekDays {
            XCTAssertEqual(grouped[date.startOfDay]?.count, 0, "Date should have 0 assignments")
        }
    }
    
    /// Test fetching assignments normalizes dates for comparison
    /// **Validates: Requirement 6.1**
    func testFetchAssignments_NormalizesDatesForComparison() throws {
        // Given: An assignment at start of day
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let assignment = MealAssignment(mealId: UUID(), date: date)
        mockRepository.assignments = [assignment]
        
        // When: Fetching with a date that has a time component
        let dateWithTime = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 10, minute: 30))!
        let grouped = try plannerService.fetchAssignments(for: [dateWithTime])
        
        // Then: Should find the assignment despite time difference
        XCTAssertEqual(grouped[date.startOfDay]?.count, 1, "Should find assignment despite time component")
    }
    
    // MARK: - Remove Assignment Tests
    
    /// Test removing an assignment by ID
    /// **Validates: Requirement 6.5**
    func testRemoveAssignment_ById_DeletesAssignment() throws {
        // Given: An assignment ID
        let assignmentId = UUID()
        
        // When: Removing the assignment
        try plannerService.removeAssignment(id: assignmentId)
        
        // Then: Repository should have deleted the assignment
        XCTAssertEqual(mockRepository.deletedAssignmentIds.count, 1, "Should delete one assignment")
        XCTAssertEqual(mockRepository.deletedAssignmentIds[0], assignmentId, "Should delete correct assignment")
    }
    
    /// Test removing multiple assignments
    /// **Validates: Requirement 6.5**
    func testRemoveAssignment_MultipleAssignments_DeletesEach() throws {
        // Given: Multiple assignment IDs
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        // When: Removing each assignment
        try plannerService.removeAssignment(id: id1)
        try plannerService.removeAssignment(id: id2)
        try plannerService.removeAssignment(id: id3)
        
        // Then: Repository should have deleted all assignments
        XCTAssertEqual(mockRepository.deletedAssignmentIds.count, 3, "Should delete three assignments")
        XCTAssertTrue(mockRepository.deletedAssignmentIds.contains(id1), "Should delete id1")
        XCTAssertTrue(mockRepository.deletedAssignmentIds.contains(id2), "Should delete id2")
        XCTAssertTrue(mockRepository.deletedAssignmentIds.contains(id3), "Should delete id3")
    }
}

// MARK: - Mock Assignment Repository

/// Mock implementation of AssignmentRepositoryProtocol for testing
class MockAssignmentRepository: AssignmentRepositoryProtocol {
    var assignments: [MealAssignment] = []
    var savedAssignments: [MealAssignment] = []
    var deletedAssignmentIds: [UUID] = []
    var shouldThrowError = false
    
    func saveAssignment(_ assignment: MealAssignment) throws {
        if shouldThrowError {
            throw StorageError.saveFailed
        }
        savedAssignments.append(assignment)
        assignments.append(assignment)
    }
    
    func fetchAllAssignments() throws -> [MealAssignment] {
        if shouldThrowError {
            throw StorageError.fetchFailed
        }
        return assignments
    }
    
    func fetchAssignments(for date: Date) throws -> [MealAssignment] {
        if shouldThrowError {
            throw StorageError.fetchFailed
        }
        let normalizedDate = date.startOfDay
        return assignments.filter { $0.date == normalizedDate }
    }
    
    func deleteAssignment(id: UUID) throws {
        if shouldThrowError {
            throw StorageError.saveFailed
        }
        deletedAssignmentIds.append(id)
        assignments.removeAll { $0.id == id }
    }
}
