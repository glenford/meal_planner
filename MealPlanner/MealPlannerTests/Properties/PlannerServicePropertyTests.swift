//
//  PlannerServicePropertyTests.swift
//  MyAppTests
//
//  Property-based tests for PlannerService
//  Feature: meal-planning-assistant
//

import XCTest
import SwiftCheck
@testable import MealPlanner

/// Property-based tests for PlannerService using SwiftCheck
/// These tests verify universal correctness properties across randomized inputs
class PlannerServicePropertyTests: XCTestCase {
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
    
    // MARK: - Property 6: Week Generation Consistency
    
    /// **Validates: Requirements 4.1, 4.3, 5.3**
    ///
    /// Property 6: Week Generation Consistency
    /// For any starting date, generating a week should produce exactly 7 consecutive
    /// dates in chronological order, with each date being exactly one day after the previous.
    func testProperty6_WeekGenerationConsistency() {
        property("Generating a week produces 7 consecutive dates in chronological order") <- forAll { (arbitraryDate: ArbitraryDate) in
            // Given: Any starting date
            let startDate = arbitraryDate.value
            
            // When: Generate week days
            let weekDays = self.plannerService.generateWeekDays(startingFrom: startDate)
            
            // Then: Should produce exactly 7 dates
            guard weekDays.count == 7 else {
                return false <?> "Week should contain exactly 7 days, got \(weekDays.count)"
            }
            
            // And: All dates should be normalized to start of day
            let calendar = Calendar.current
            for day in weekDays {
                let components = calendar.dateComponents([.hour, .minute, .second], from: day)
                guard components.hour == 0 && components.minute == 0 && components.second == 0 else {
                    return false <?> "Date not normalized to start of day: \(day)"
                }
            }
            
            // And: First date should be the normalized start date
            let expectedFirstDay = startDate.startOfDay
            guard weekDays[0] == expectedFirstDay else {
                return false <?> "First day should be normalized start date"
            }
            
            // And: Each date should be exactly one day after the previous
            for i in 0..<6 {
                let currentDay = weekDays[i]
                let nextDay = weekDays[i + 1]
                
                guard let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                    return false <?> "Failed to calculate next day"
                }
                
                guard nextDay == expectedNextDay else {
                    return false <?> "Days not consecutive: \(currentDay) -> \(nextDay)"
                }
            }
            
            // And: Dates should be in chronological order
            for i in 0..<6 {
                guard weekDays[i] < weekDays[i + 1] else {
                    return false <?> "Dates not in chronological order"
                }
            }
            
            return true
        }.verbose
    }
    
    // MARK: - Property 8: Week Navigation Correctness
    
    /// **Validates: Requirements 5.1, 5.2, 5.4**
    ///
    /// Property 8: Week Navigation Correctness
    /// For any starting date, navigating forward should produce a week starting 7 days later,
    /// and navigating backward should produce a week starting 7 days earlier, with both
    /// operations maintaining the 7-day structure.
    func testProperty8_WeekNavigationCorrectness() {
        property("Week navigation maintains 7-day structure and correct offsets") <- forAll { (arbitraryDate: ArbitraryDate) in
            // Given: Any starting date
            let startDate = arbitraryDate.value
            let calendar = Calendar.current
            
            // When: Generate initial week
            let initialWeek = self.plannerService.generateWeekDays(startingFrom: startDate)
            
            // And: Calculate forward week (7 days later)
            guard let forwardStartDate = calendar.date(byAdding: .day, value: 7, to: startDate.startOfDay) else {
                return false <?> "Failed to calculate forward date"
            }
            let forwardWeek = self.plannerService.generateWeekDays(startingFrom: forwardStartDate)
            
            // And: Calculate backward week (7 days earlier)
            guard let backwardStartDate = calendar.date(byAdding: .day, value: -7, to: startDate.startOfDay) else {
                return false <?> "Failed to calculate backward date"
            }
            let backwardWeek = self.plannerService.generateWeekDays(startingFrom: backwardStartDate)
            
            // Then: All weeks should have exactly 7 days
            guard initialWeek.count == 7 && forwardWeek.count == 7 && backwardWeek.count == 7 else {
                return false <?> "All weeks should contain exactly 7 days"
            }
            
            // And: Forward week should start exactly 7 days after initial week
            guard forwardWeek[0] == calendar.date(byAdding: .day, value: 7, to: initialWeek[0]) else {
                return false <?> "Forward week should start 7 days after initial week"
            }
            
            // And: Backward week should start exactly 7 days before initial week
            guard backwardWeek[0] == calendar.date(byAdding: .day, value: -7, to: initialWeek[0]) else {
                return false <?> "Backward week should start 7 days before initial week"
            }
            
            // And: Forward week's last day should be 13 days after initial week's first day
            guard let expectedForwardLastDay = calendar.date(byAdding: .day, value: 13, to: initialWeek[0]) else {
                return false <?> "Failed to calculate expected forward last day"
            }
            guard forwardWeek[6] == expectedForwardLastDay else {
                return false <?> "Forward week's last day should be 13 days after initial week's first day"
            }
            
            // And: Backward week's last day should be 1 day before initial week's first day
            guard let expectedBackwardLastDay = calendar.date(byAdding: .day, value: -1, to: initialWeek[0]) else {
                return false <?> "Failed to calculate expected backward last day"
            }
            guard backwardWeek[6] == expectedBackwardLastDay else {
                return false <?> "Backward week's last day should be 1 day before initial week's first day"
            }
            
            // And: Each week should maintain consecutive day structure
            for week in [initialWeek, forwardWeek, backwardWeek] {
                for i in 0..<6 {
                    guard let expectedNext = calendar.date(byAdding: .day, value: 1, to: week[i]) else {
                        return false <?> "Failed to calculate expected next day"
                    }
                    guard week[i + 1] == expectedNext else {
                        return false <?> "Week days not consecutive"
                    }
                }
            }
            
            return true
        }.verbose
    }
    
    // MARK: - Property 10: Multiple Assignments Per Day
    
    /// **Validates: Requirements 6.3, 6.4**
    ///
    /// Property 10: Multiple Assignments Per Day
    /// For any date and any set of meals, assigning all meals to that date and then
    /// fetching assignments for that date should return all assigned meals.
    func testProperty10_MultipleAssignmentsPerDay() {
        property("Multiple meals can be assigned to the same day and all are retrieved") <- forAll { (arbitraryAssignments: ArbitraryMultipleAssignments) in
            // Reset mock repository for each iteration
            self.mockRepository.reset()
            
            // Given: Multiple meal IDs and a single date
            let mealIds = arbitraryAssignments.mealIds
            let date = arbitraryAssignments.date
            
            guard !mealIds.isEmpty else {
                return true // Empty case is trivially true
            }
            
            // When: Assign all meals to the same date
            do {
                for mealId in mealIds {
                    try self.plannerService.assignMeal(mealId: mealId, to: date)
                }
                
                // Then: All assignments should be saved
                guard self.mockRepository.savedAssignments.count == mealIds.count else {
                    return false <?> "Expected \(mealIds.count) assignments, got \(self.mockRepository.savedAssignments.count)"
                }
                
                // And: All assignments should be for the normalized date
                let normalizedDate = date.startOfDay
                for assignment in self.mockRepository.savedAssignments {
                    guard assignment.date == normalizedDate else {
                        return false <?> "Assignment date not normalized: \(assignment.date)"
                    }
                }
                
                // And: Fetching assignments for that date should return all of them
                let grouped = try self.plannerService.fetchAssignments(for: [date])
                guard let fetchedAssignments = grouped[normalizedDate] else {
                    return false <?> "No assignments found for date"
                }
                
                guard fetchedAssignments.count == mealIds.count else {
                    return false <?> "Expected \(mealIds.count) fetched assignments, got \(fetchedAssignments.count)"
                }
                
                // And: All meal IDs should be present in fetched assignments
                let savedMealIds = Set(mealIds)
                let fetchedMealIds = Set(fetchedAssignments.map { $0.mealId })
                
                guard savedMealIds == fetchedMealIds else {
                    return false <?> "Meal ID sets don't match"
                }
                
                return true
            } catch {
                return false <?> "Operation failed: \(error)"
            }
        }.verbose
    }
    
    // MARK: - Property 12: Date Normalization Invariant
    
    /// **Validates: Requirements 6.1**
    ///
    /// Property 12: Date Normalization Invariant
    /// For any date with any time component, normalizing to start of day and then
    /// comparing should treat all times on the same calendar day as equal.
    func testProperty12_DateNormalizationInvariant() {
        property("Dates with different times on the same day are treated as equal after normalization") <- forAll { (arbitraryDatePair: ArbitraryDatePair) in
            // Given: Two dates on the same calendar day but with different times
            let date1 = arbitraryDatePair.date1
            let date2 = arbitraryDatePair.date2
            
            let calendar = Calendar.current
            let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
            let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
            
            // Verify they're on the same calendar day
            guard components1.year == components2.year &&
                  components1.month == components2.month &&
                  components1.day == components2.day else {
                return false <?> "Dates not on the same calendar day"
            }
            
            // Reset mock repository
            self.mockRepository.reset()
            
            // When: Assign a meal to date1
            let mealId = UUID()
            do {
                try self.plannerService.assignMeal(mealId: mealId, to: date1)
                
                // Then: Fetching assignments for date2 should return the assignment
                let grouped = try self.plannerService.fetchAssignments(for: [date2])
                let normalizedDate = date2.startOfDay
                
                guard let fetchedAssignments = grouped[normalizedDate] else {
                    return false <?> "No assignments found for date2"
                }
                
                guard fetchedAssignments.count == 1 else {
                    return false <?> "Expected 1 assignment, got \(fetchedAssignments.count)"
                }
                
                guard fetchedAssignments[0].mealId == mealId else {
                    return false <?> "Meal ID doesn't match"
                }
                
                // And: Both dates should normalize to the same value
                let normalized1 = date1.startOfDay
                let normalized2 = date2.startOfDay
                
                guard normalized1 == normalized2 else {
                    return false <?> "Normalized dates should be equal"
                }
                
                // And: The assignment's date should match both normalized dates
                guard fetchedAssignments[0].date == normalized1 && fetchedAssignments[0].date == normalized2 else {
                    return false <?> "Assignment date should match both normalized dates"
                }
                
                return true
            } catch {
                return false <?> "Operation failed: \(error)"
            }
        }.verbose
    }
}

// MARK: - Arbitrary Generators

/// Generator for arbitrary dates within a reasonable range
struct ArbitraryDate: Arbitrary {
    let value: Date
    
    static var arbitrary: Gen<ArbitraryDate> {
        return Gen.compose { composer in
            // Generate dates from 365 days ago to 365 days in the future
            let daysOffset = composer.generate(using: Gen<Int>.choose((-365, 365)))
            let calendar = Calendar.current
            let baseDate = Date()
            
            // Add random time components (0-23 hours, 0-59 minutes, 0-59 seconds)
            let hour = composer.generate(using: Gen<Int>.choose((0, 23)))
            let minute = composer.generate(using: Gen<Int>.choose((0, 59)))
            let second = composer.generate(using: Gen<Int>.choose((0, 59)))
            
            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.day = (components.day ?? 1) + daysOffset
            components.hour = hour
            components.minute = minute
            components.second = second
            
            let date = calendar.date(from: components) ?? baseDate
            
            return ArbitraryDate(value: date)
        }
    }
}

/// Generator for multiple meal IDs and a single date (1-10 meals)
struct ArbitraryMultipleAssignments: Arbitrary {
    let mealIds: [UUID]
    let date: Date
    
    static var arbitrary: Gen<ArbitraryMultipleAssignments> {
        return Gen.compose { composer in
            // Generate 1-10 meal IDs
            let count = composer.generate(using: Gen<Int>.choose((1, 10)))
            let mealIds = (0..<count).map { _ in UUID() }
            
            // Generate a random date
            let arbitraryDate = composer.generate(using: ArbitraryDate.arbitrary)
            
            return ArbitraryMultipleAssignments(mealIds: mealIds, date: arbitraryDate.value)
        }
    }
}

/// Generator for two dates on the same calendar day but with different times
struct ArbitraryDatePair: Arbitrary {
    let date1: Date
    let date2: Date
    
    static var arbitrary: Gen<ArbitraryDatePair> {
        return Gen.compose { composer in
            let calendar = Calendar.current
            
            // Generate a base date
            let daysOffset = composer.generate(using: Gen<Int>.choose((-365, 365)))
            let baseDate = Date()
            
            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.day = (components.day ?? 1) + daysOffset
            
            // Generate two different times for the same day
            let hour1 = composer.generate(using: Gen<Int>.choose((0, 23)))
            let minute1 = composer.generate(using: Gen<Int>.choose((0, 59)))
            let second1 = composer.generate(using: Gen<Int>.choose((0, 59)))
            
            let hour2 = composer.generate(using: Gen<Int>.choose((0, 23)))
            let minute2 = composer.generate(using: Gen<Int>.choose((0, 59)))
            let second2 = composer.generate(using: Gen<Int>.choose((0, 59)))
            
            var components1 = components
            components1.hour = hour1
            components1.minute = minute1
            components1.second = second1
            
            var components2 = components
            components2.hour = hour2
            components2.minute = minute2
            components2.second = second2
            
            let date1 = calendar.date(from: components1) ?? baseDate
            let date2 = calendar.date(from: components2) ?? baseDate
            
            return ArbitraryDatePair(date1: date1, date2: date2)
        }
    }
}

// MARK: - Mock Assignment Repository Extension

extension MockAssignmentRepository {
    /// Reset the mock repository to a clean state
    func reset() {
        assignments = []
        savedAssignments = []
        deletedAssignmentIds = []
        shouldThrowError = false
    }
}
