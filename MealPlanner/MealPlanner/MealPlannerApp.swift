import SwiftUI

@main
struct MealPlannerApp: App {
    // Shared storage manager
    private let storageManager = StorageManager.shared
    
    // Shared repositories
    private let mealRepository: MealRepository
    private let assignmentRepository: AssignmentRepository
    
    // Shared services
    private let filterService: FilterService
    private let plannerService: PlannerService
    
    // Shared view models
    @StateObject private var mealListViewModel: MealListViewModel
    @StateObject private var weeklyPlannerViewModel: WeeklyPlannerViewModel
    
    init() {
        // Initialize repositories with shared storage manager
        let mealRepo = MealRepository(storageManager: storageManager)
        let assignmentRepo = AssignmentRepository(storageManager: storageManager)
        
        self.mealRepository = mealRepo
        self.assignmentRepository = assignmentRepo
        
        // Initialize services
        self.filterService = FilterService()
        self.plannerService = PlannerService(assignmentRepository: assignmentRepo)
        
        // Initialize view models with dependencies
        let mealListVM = MealListViewModel(
            mealRepository: mealRepo,
            filterService: filterService
        )
        
        let plannerVM = WeeklyPlannerViewModel(
            plannerService: plannerService,
            mealRepository: mealRepo
        )
        
        _mealListViewModel = StateObject(wrappedValue: mealListVM)
        _weeklyPlannerViewModel = StateObject(wrappedValue: plannerVM)
        
        // Load initial data on app launch
        loadInitialData(mealListVM: mealListVM, plannerVM: plannerVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                mealListViewModel: mealListViewModel,
                weeklyPlannerViewModel: weeklyPlannerViewModel
            )
        }
    }
    
    /// Load initial data when app launches
    /// Satisfies Requirement 7.3: Load all Meals and Day_Assignments from local storage on app launch
    private func loadInitialData(mealListVM: MealListViewModel, plannerVM: WeeklyPlannerViewModel) {
        // Load meals
        mealListVM.loadMeals()
        
        // Load current week's assignments
        plannerVM.loadWeek()
    }
}
