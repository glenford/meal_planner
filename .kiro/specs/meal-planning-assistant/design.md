# Design Document: Meal Planning Assistant

## Overview

The Meal Planning Assistant is an iOS application built with Swift and SwiftUI that enables users to create, manage, filter, and schedule meals across a weekly calendar. The system follows the MVVM (Model-View-ViewModel) architecture pattern, leveraging SwiftUI's reactive data flow and Combine framework for state management.

The application consists of three primary functional areas:
1. **Meal Management**: Creating and storing meal entries with nutritional information
2. **Meal Discovery**: Filtering and browsing meals by nutritional criteria
3. **Weekly Planning**: Assigning meals to specific days and navigating through weeks

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Meal List   │  │   Meal Form  │  │Weekly Planner│     │
│  │     View     │  │     View     │  │     View     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────┬────────────────┬────────────────┬─────────────┘
             │                │                │
             ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                         ViewModels                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  MealList    │  │   MealForm   │  │WeeklyPlanner │     │
│  │  ViewModel   │  │  ViewModel   │  │  ViewModel   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────┬────────────────┬────────────────┬─────────────┘
             │                │                │
             └────────────────┼────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │MealRepository│  │FilterService │  │PlannerService│     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────┬────────────────┬────────────────┬─────────────┘
             │                │                │
             └────────────────┼────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────────────────────────────────────────┐       │
│  │          StorageManager (UserDefaults)           │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Architecture Decisions

**MVVM Pattern**: Separates UI (Views) from business logic (ViewModels) and data (Models), enabling testability and maintainability.

**SwiftUI + Combine**: Leverages SwiftUI's declarative syntax and Combine's reactive programming for automatic UI updates when data changes.

**UserDefaults for Storage**: Simple, lightweight persistence suitable for meal data and assignments. For larger datasets, this could be migrated to Core Data or SQLite.

**Repository Pattern**: Abstracts data access, making it easy to swap storage implementations without affecting business logic.

## Components and Interfaces

### Data Models

#### Meal Model

```swift
struct Meal: Identifiable, Codable, Equatable {
    let id: UUID
    var description: String
    var primaryProtein: String
    var primaryCarb: String
    var otherComponents: [String]
    var createdAt: Date
    
    init(id: UUID = UUID(),
         description: String,
         primaryProtein: String,
         primaryCarb: String,
         otherComponents: [String] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.description = description
        self.primaryProtein = primaryProtein
        self.primaryCarb = primaryCarb
        self.otherComponents = otherComponents
        self.createdAt = createdAt
    }
}
```

#### MealAssignment Model

```swift
struct MealAssignment: Identifiable, Codable, Equatable {
    let id: UUID
    let mealId: UUID
    let date: Date // Normalized to start of day
    var createdAt: Date
    
    init(id: UUID = UUID(),
         mealId: UUID,
         date: Date,
         createdAt: Date = Date()) {
        self.id = id
        self.mealId = mealId
        self.date = date.startOfDay
        self.createdAt = createdAt
    }
}
```

#### FilterCriteria Model

```swift
struct FilterCriteria: Equatable {
    var proteinFilter: String?
    var carbFilter: String?
    var componentFilters: Set<String>
    
    var isActive: Bool {
        proteinFilter != nil || carbFilter != nil || !componentFilters.isEmpty
    }
    
    init(proteinFilter: String? = nil,
         carbFilter: String? = nil,
         componentFilters: Set<String> = []) {
        self.proteinFilter = proteinFilter
        self.carbFilter = carbFilter
        self.componentFilters = componentFilters
    }
}
```

### Repository Layer

#### MealRepository

```swift
protocol MealRepositoryProtocol {
    func saveMeal(_ meal: Meal) throws
    func fetchAllMeals() throws -> [Meal]
    func deleteMeal(id: UUID) throws
    func updateMeal(_ meal: Meal) throws
}

class MealRepository: MealRepositoryProtocol {
    private let storageManager: StorageManager
    private let mealsKey = "meals"
    
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
    }
    
    func saveMeal(_ meal: Meal) throws {
        var meals = try fetchAllMeals()
        if let index = meals.firstIndex(where: { $0.id == meal.id }) {
            meals[index] = meal
        } else {
            meals.append(meal)
        }
        try storageManager.save(meals, forKey: mealsKey)
    }
    
    func fetchAllMeals() throws -> [Meal] {
        return try storageManager.fetch([Meal].self, forKey: mealsKey) ?? []
    }
    
    func deleteMeal(id: UUID) throws {
        var meals = try fetchAllMeals()
        meals.removeAll { $0.id == id }
        try storageManager.save(meals, forKey: mealsKey)
    }
    
    func updateMeal(_ meal: Meal) throws {
        try saveMeal(meal)
    }
}
```

#### AssignmentRepository

```swift
protocol AssignmentRepositoryProtocol {
    func saveAssignment(_ assignment: MealAssignment) throws
    func fetchAllAssignments() throws -> [MealAssignment]
    func fetchAssignments(for date: Date) throws -> [MealAssignment]
    func deleteAssignment(id: UUID) throws
}

class AssignmentRepository: AssignmentRepositoryProtocol {
    private let storageManager: StorageManager
    private let assignmentsKey = "mealAssignments"
    
    init(storageManager: StorageManager = .shared) {
        self.storageManager = storageManager
    }
    
    func saveAssignment(_ assignment: MealAssignment) throws {
        var assignments = try fetchAllAssignments()
        assignments.append(assignment)
        try storageManager.save(assignments, forKey: assignmentsKey)
    }
    
    func fetchAllAssignments() throws -> [MealAssignment] {
        return try storageManager.fetch([MealAssignment].self, forKey: assignmentsKey) ?? []
    }
    
    func fetchAssignments(for date: Date) throws -> [MealAssignment] {
        let normalizedDate = date.startOfDay
        return try fetchAllAssignments().filter { $0.date == normalizedDate }
    }
    
    func deleteAssignment(id: UUID) throws {
        var assignments = try fetchAllAssignments()
        assignments.removeAll { $0.id == id }
        try storageManager.save(assignments, forKey: assignmentsKey)
    }
}
```

### Service Layer

#### FilterService

```swift
class FilterService {
    func filterMeals(_ meals: [Meal], criteria: FilterCriteria) -> [Meal] {
        guard criteria.isActive else { return meals }
        
        return meals.filter { meal in
            var matches = true
            
            if let proteinFilter = criteria.proteinFilter {
                matches = matches && meal.primaryProtein.lowercased() == proteinFilter.lowercased()
            }
            
            if let carbFilter = criteria.carbFilter {
                matches = matches && meal.primaryCarb.lowercased() == carbFilter.lowercased()
            }
            
            if !criteria.componentFilters.isEmpty {
                let mealComponents = Set(meal.otherComponents.map { $0.lowercased() })
                let filterComponents = Set(criteria.componentFilters.map { $0.lowercased() })
                matches = matches && filterComponents.isSubset(of: mealComponents)
            }
            
            return matches
        }
    }
    
    func extractUniqueProteins(from meals: [Meal]) -> [String] {
        return Array(Set(meals.map { $0.primaryProtein })).sorted()
    }
    
    func extractUniqueCarbs(from meals: [Meal]) -> [String] {
        return Array(Set(meals.map { $0.primaryCarb })).sorted()
    }
    
    func extractUniqueComponents(from meals: [Meal]) -> [String] {
        let allComponents = meals.flatMap { $0.otherComponents }
        return Array(Set(allComponents)).sorted()
    }
}
```

#### PlannerService

```swift
class PlannerService {
    private let assignmentRepository: AssignmentRepositoryProtocol
    
    init(assignmentRepository: AssignmentRepositoryProtocol) {
        self.assignmentRepository = assignmentRepository
    }
    
    func generateWeekDays(startingFrom date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = date.startOfDay
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    func assignMeal(mealId: UUID, to date: Date) throws {
        let assignment = MealAssignment(mealId: mealId, date: date)
        try assignmentRepository.saveAssignment(assignment)
    }
    
    func fetchAssignments(for dates: [Date]) throws -> [Date: [MealAssignment]] {
        let allAssignments = try assignmentRepository.fetchAllAssignments()
        var grouped: [Date: [MealAssignment]] = [:]
        
        for date in dates {
            let normalizedDate = date.startOfDay
            grouped[normalizedDate] = allAssignments.filter { $0.date == normalizedDate }
        }
        
        return grouped
    }
    
    func removeAssignment(id: UUID) throws {
        try assignmentRepository.deleteAssignment(id: id)
    }
}
```

### Storage Layer

#### StorageManager

```swift
enum StorageError: Error {
    case encodingFailed
    case decodingFailed
    case saveFailed
    case fetchFailed
}

class StorageManager {
    static let shared = StorageManager()
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed
        }
    }
    
    func fetch<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
```

### ViewModels

#### MealListViewModel

```swift
class MealListViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var filteredMeals: [Meal] = []
    @Published var filterCriteria = FilterCriteria()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let mealRepository: MealRepositoryProtocol
    private let filterService: FilterService
    
    var availableProteins: [String] {
        filterService.extractUniqueProteins(from: meals)
    }
    
    var availableCarbs: [String] {
        filterService.extractUniqueCarbs(from: meals)
    }
    
    var availableComponents: [String] {
        filterService.extractUniqueComponents(from: meals)
    }
    
    init(mealRepository: MealRepositoryProtocol = MealRepository(),
         filterService: FilterService = FilterService()) {
        self.mealRepository = mealRepository
        self.filterService = filterService
    }
    
    func loadMeals() {
        isLoading = true
        errorMessage = nil
        
        do {
            meals = try mealRepository.fetchAllMeals()
            applyFilters()
        } catch {
            errorMessage = "Failed to load meals"
        }
        
        isLoading = false
    }
    
    func applyFilters() {
        filteredMeals = filterService.filterMeals(meals, criteria: filterCriteria)
    }
    
    func deleteMeal(id: UUID) {
        do {
            try mealRepository.deleteMeal(id: id)
            loadMeals()
        } catch {
            errorMessage = "Failed to delete meal"
        }
    }
}
```

#### MealFormViewModel

```swift
class MealFormViewModel: ObservableObject {
    @Published var description: String = ""
    @Published var primaryProtein: String = ""
    @Published var primaryCarb: String = ""
    @Published var otherComponents: [String] = []
    @Published var newComponent: String = ""
    @Published var errorMessage: String?
    
    private let mealRepository: MealRepositoryProtocol
    var onSaveComplete: (() -> Void)?
    
    init(mealRepository: MealRepositoryProtocol = MealRepository()) {
        self.mealRepository = mealRepository
    }
    
    func addComponent() {
        let trimmed = newComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        otherComponents.append(trimmed)
        newComponent = ""
    }
    
    func removeComponent(at index: Int) {
        otherComponents.remove(at: index)
    }
    
    func saveMeal() {
        errorMessage = nil
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Description is required"
            return
        }
        
        let meal = Meal(
            description: trimmedDescription,
            primaryProtein: primaryProtein,
            primaryCarb: primaryCarb,
            otherComponents: otherComponents
        )
        
        do {
            try mealRepository.saveMeal(meal)
            onSaveComplete?()
        } catch {
            errorMessage = "Failed to save meal"
        }
    }
}
```

#### WeeklyPlannerViewModel

```swift
class WeeklyPlannerViewModel: ObservableObject {
    @Published var weekDays: [Date] = []
    @Published var assignments: [Date: [MealAssignment]] = [:]
    @Published var meals: [UUID: Meal] = [:]
    @Published var currentWeekStart: Date
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let plannerService: PlannerService
    private let mealRepository: MealRepositoryProtocol
    
    init(plannerService: PlannerService,
         mealRepository: MealRepositoryProtocol = MealRepository(),
         startDate: Date = Date()) {
        self.plannerService = plannerService
        self.mealRepository = mealRepository
        self.currentWeekStart = startDate.startOfDay
        loadWeek()
    }
    
    func loadWeek() {
        isLoading = true
        errorMessage = nil
        
        weekDays = plannerService.generateWeekDays(startingFrom: currentWeekStart)
        
        do {
            assignments = try plannerService.fetchAssignments(for: weekDays)
            let allMeals = try mealRepository.fetchAllMeals()
            meals = Dictionary(uniqueKeysWithValues: allMeals.map { ($0.id, $0) })
        } catch {
            errorMessage = "Failed to load week data"
        }
        
        isLoading = false
    }
    
    func navigateForward() {
        guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) else {
            return
        }
        currentWeekStart = nextWeek
        loadWeek()
    }
    
    func navigateBackward() {
        guard let previousWeek = Calendar.current.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            return
        }
        currentWeekStart = previousWeek
        loadWeek()
    }
    
    func assignMeal(mealId: UUID, to date: Date) {
        do {
            try plannerService.assignMeal(mealId: mealId, to: date)
            loadWeek()
        } catch {
            errorMessage = "Failed to assign meal"
        }
    }
    
    func removeAssignment(id: UUID) {
        do {
            try plannerService.removeAssignment(id: id)
            loadWeek()
        } catch {
            errorMessage = "Failed to remove assignment"
        }
    }
    
    func getMealsForDay(_ date: Date) -> [Meal] {
        let normalizedDate = date.startOfDay
        guard let dayAssignments = assignments[normalizedDate] else { return [] }
        return dayAssignments.compactMap { meals[$0.mealId] }
    }
}
```

## Data Models

### Date Extension

```swift
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
```

### Validation Rules

1. **Meal Description**: Must be non-empty after trimming whitespace
2. **Primary Protein**: Can be empty string (optional)
3. **Primary Carb**: Can be empty string (optional)
4. **Other Components**: Array can be empty
5. **Date Normalization**: All dates stored as start of day (00:00:00) for consistent comparison


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Meal Persistence Round-Trip

*For any* valid Meal with a non-empty description, saving the meal and then fetching all meals should return a collection that includes a meal with identical description, primaryProtein, primaryCarb, and otherComponents.

**Validates: Requirements 1.1, 1.2, 1.3, 7.1**

### Property 2: Invalid Meal Rejection

*For any* string composed entirely of whitespace or empty string, attempting to create a meal with that description should result in an error and no meal should be persisted.

**Validates: Requirements 1.4**

### Property 3: Meal Retrieval Completeness

*For any* set of valid meals that have been saved, fetching all meals should return exactly that set of meals with no additions or omissions.

**Validates: Requirements 2.1**

### Property 4: Meal Display Completeness

*For any* meal, the rendered display string should contain the meal's description, primaryProtein, primaryCarb, and all otherComponents.

**Validates: Requirements 2.2**

### Property 5: Filter Correctness

*For any* set of meals and any filter criteria (protein, carb, or component filters), the filtered results should contain only meals that match ALL specified criteria, and should contain ALL meals that match the criteria.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 6: Week Generation Consistency

*For any* starting date, generating a week should produce exactly 7 consecutive dates in chronological order, with each date being exactly one day after the previous.

**Validates: Requirements 4.1, 4.3, 5.3**

### Property 7: Day Display Completeness

*For any* day with assigned meals, the rendered display should include the day name, date, and all assigned meal information.

**Validates: Requirements 4.2**

### Property 8: Week Navigation Correctness

*For any* starting date, navigating forward should produce a week starting 7 days later, and navigating backward should produce a week starting 7 days earlier, with both operations maintaining the 7-day structure.

**Validates: Requirements 5.1, 5.2, 5.4**

### Property 9: Assignment Persistence Round-Trip

*For any* valid meal and date, creating an assignment and then fetching assignments for that date should return a collection that includes an assignment linking that meal to that date.

**Validates: Requirements 6.1, 6.2, 7.2**

### Property 10: Multiple Assignments Per Day

*For any* date and any set of meals, assigning all meals to that date and then fetching assignments for that date should return all assigned meals.

**Validates: Requirements 6.3, 6.4**

### Property 11: Assignment Deletion

*For any* assignment that has been created, deleting that assignment and then fetching assignments for its date should return a collection that does not include that assignment.

**Validates: Requirements 6.5**

### Property 12: Date Normalization Invariant

*For any* date with any time component, normalizing to start of day and then comparing should treat all times on the same calendar day as equal.

**Validates: Requirements 6.1** (implicit requirement for consistent date handling)

## Error Handling

### Error Types

```swift
enum MealPlannerError: Error, LocalizedError {
    case invalidMealDescription
    case storageEncodingFailed
    case storageDecodingFailed
    case mealNotFound
    case assignmentNotFound
    case dateCalculationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidMealDescription:
            return "Meal description cannot be empty"
        case .storageEncodingFailed:
            return "Failed to save data"
        case .storageDecodingFailed:
            return "Failed to load data"
        case .mealNotFound:
            return "Meal not found"
        case .assignmentNotFound:
            return "Assignment not found"
        case .dateCalculationFailed:
            return "Failed to calculate date"
        }
    }
}
```

### Error Handling Strategy

1. **Validation Errors**: Caught at ViewModel level, displayed to user immediately
2. **Storage Errors**: Caught at Repository level, propagated to ViewModel, displayed to user with retry option
3. **Data Integrity Errors**: Logged and handled gracefully (e.g., missing meal for assignment shows placeholder)
4. **Date Calculation Errors**: Should never occur with proper Calendar usage, but handled defensively

### User-Facing Error Messages

- Clear, actionable messages
- No technical jargon
- Suggest next steps when possible
- Maintain app state even when errors occur

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, and error conditions
- **Property Tests**: Verify universal properties across all inputs through randomized testing

Both approaches are complementary and necessary. Unit tests catch concrete bugs in specific scenarios, while property tests verify general correctness across a wide input space.

### Property-Based Testing

**Framework**: Use [swift-check](https://github.com/typelift/SwiftCheck) for property-based testing in Swift.

**Configuration**:
- Minimum 100 iterations per property test
- Each test must reference its design document property
- Tag format: `// Feature: meal-planning-assistant, Property {number}: {property_text}`

**Property Test Coverage**:
- Each correctness property listed above must be implemented as a property-based test
- Tests should generate random valid inputs and verify the property holds
- Tests should also generate random invalid inputs where applicable to verify error handling

### Unit Testing

**Framework**: Use XCTest for unit testing.

**Focus Areas**:
1. **Edge Cases**:
   - Empty meal lists
   - Days with no assignments
   - Filters that produce no results
   - Boundary dates (year transitions, leap years)

2. **Specific Examples**:
   - Creating a meal with all fields populated
   - Creating a meal with minimal fields
   - Filtering with single criterion
   - Navigating to specific weeks

3. **Error Conditions**:
   - Storage failures (mock UserDefaults)
   - Invalid meal descriptions
   - Attempting to delete non-existent items

4. **Integration Points**:
   - ViewModel interactions with repositories
   - Repository interactions with storage
   - Service layer coordination

### Test Organization

```
Tests/
├── Models/
│   ├── MealTests.swift
│   ├── MealAssignmentTests.swift
│   └── FilterCriteriaTests.swift
├── Repositories/
│   ├── MealRepositoryTests.swift
│   └── AssignmentRepositoryTests.swift
├── Services/
│   ├── FilterServiceTests.swift
│   └── PlannerServiceTests.swift
├── ViewModels/
│   ├── MealListViewModelTests.swift
│   ├── MealFormViewModelTests.swift
│   └── WeeklyPlannerViewModelTests.swift
├── Storage/
│   └── StorageManagerTests.swift
└── Properties/
    ├── MealPropertiesTests.swift
    ├── FilterPropertiesTests.swift
    ├── PlannerPropertiesTests.swift
    └── AssignmentPropertiesTests.swift
```

### Mocking Strategy

- Mock `StorageManager` for repository tests
- Mock repositories for ViewModel tests
- Use dependency injection throughout to enable testing
- Create test doubles for UserDefaults

### Coverage Goals

- Minimum 80% code coverage
- 100% coverage of business logic (repositories, services)
- All correctness properties implemented as property tests
- All edge cases covered by unit tests
