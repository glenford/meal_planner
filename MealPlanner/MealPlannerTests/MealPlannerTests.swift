//
//  MealPlannerTests.swift
//  MealPlannerTests
//
//  Created for Meal Planning Assistant
//

import XCTest
@testable import MealPlanner

final class MealPlannerTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMealCreation() throws {
        // Test that we can create a Meal model
        let meal = Meal(
            description: "Chicken and Rice",
            primaryProtein: "Chicken",
            primaryCarb: "Rice",
            otherComponents: ["Vegetables"]
        )
        
        XCTAssertEqual(meal.description, "Chicken and Rice")
        XCTAssertEqual(meal.primaryProtein, "Chicken")
        XCTAssertEqual(meal.primaryCarb, "Rice")
        XCTAssertEqual(meal.otherComponents, ["Vegetables"])
    }
    
    func testMealAssignmentCreation() throws {
        // Test that we can create a MealAssignment model
        let mealId = UUID()
        let date = Date()
        let assignment = MealAssignment(mealId: mealId, date: date)
        
        XCTAssertEqual(assignment.mealId, mealId)
        XCTAssertEqual(assignment.date, date.startOfDay)
    }
    
    func testFilterCriteriaIsActive() throws {
        // Test FilterCriteria isActive property
        var criteria = FilterCriteria()
        XCTAssertFalse(criteria.isActive)
        
        criteria.proteinFilter = "Chicken"
        XCTAssertTrue(criteria.isActive)
        
        criteria = FilterCriteria(carbFilter: "Rice")
        XCTAssertTrue(criteria.isActive)
        
        criteria = FilterCriteria(componentFilters: ["Vegetables"])
        XCTAssertTrue(criteria.isActive)
    }
    
    func testDateExtensions() throws {
        // Test Date extensions
        let date = Date()
        let startOfDay = date.startOfDay
        
        // Verify startOfDay removes time component
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
        
        // Test dayName returns a non-empty string
        XCTAssertFalse(date.dayName.isEmpty)
        
        // Test formatted returns a non-empty string
        XCTAssertFalse(date.formatted(style: .short).isEmpty)
    }
}
