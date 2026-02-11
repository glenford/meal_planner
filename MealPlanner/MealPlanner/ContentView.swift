//
//  ContentView.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import SwiftUI

/// Main content view with tab navigation
/// Provides access to meal list, meal form, and weekly planner
struct ContentView: View {
    // Shared view models injected from app entry point
    @ObservedObject var mealListViewModel: MealListViewModel
    @ObservedObject var weeklyPlannerViewModel: WeeklyPlannerViewModel
    
    // Tab selection state
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Meal List Tab
            MealListView(
                viewModel: mealListViewModel,
                plannerViewModel: weeklyPlannerViewModel
            )
                .tabItem {
                    Label("Meals", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Add Meal Tab
            MealFormView(
                onMealSaved: {
                    // Reload meals when a new meal is saved
                    mealListViewModel.loadMeals()
                    weeklyPlannerViewModel.loadWeek()
                },
                onCancel: {
                    // Switch to Meals tab when cancel is pressed
                    selectedTab = 0
                }
            )
                .tabItem {
                    Label("Add Meal", systemImage: "plus.circle")
                }
                .tag(1)
            
            // Weekly Planner Tab
            WeeklyPlannerView(viewModel: weeklyPlannerViewModel)
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
                .tag(2)
        }
    }
}

#Preview {
    let storageManager = StorageManager.shared
    let mealRepo = MealRepository(storageManager: storageManager)
    let assignmentRepo = AssignmentRepository(storageManager: storageManager)
    let filterService = FilterService()
    let plannerService = PlannerService(assignmentRepository: assignmentRepo)
    
    let mealListVM = MealListViewModel(
        mealRepository: mealRepo,
        filterService: filterService
    )
    
    let plannerVM = WeeklyPlannerViewModel(
        plannerService: plannerService,
        mealRepository: mealRepo
    )
    
    return ContentView(
        mealListViewModel: mealListVM,
        weeklyPlannerViewModel: plannerVM
    )
}
