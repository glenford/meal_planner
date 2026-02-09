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
    
    var body: some View {
        TabView {
            // Meal List Tab
            MealListView(
                viewModel: mealListViewModel,
                plannerViewModel: weeklyPlannerViewModel
            )
                .tabItem {
                    Label("Meals", systemImage: "list.bullet")
                }
            
            // Add Meal Tab
            MealFormView(onMealSaved: {
                // Reload meals when a new meal is saved
                mealListViewModel.loadMeals()
                weeklyPlannerViewModel.loadWeek()
            })
                .tabItem {
                    Label("Add Meal", systemImage: "plus.circle")
                }
            
            // Weekly Planner Tab
            WeeklyPlannerView(viewModel: weeklyPlannerViewModel)
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
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
