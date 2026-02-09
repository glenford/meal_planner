//
//  MealListView.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import SwiftUI

/// View for displaying and filtering the list of meals
/// Provides filtering controls and swipe-to-delete functionality
struct MealListView: View {
    @ObservedObject var viewModel: MealListViewModel
    @ObservedObject var plannerViewModel: WeeklyPlannerViewModel
    @State private var showingAddMeal = false
    
    /// Initialize with view models
    /// - Parameters:
    ///   - viewModel: The meal list view model
    ///   - plannerViewModel: The planner view model for checking assigned meals
    init(viewModel: MealListViewModel,
         plannerViewModel: WeeklyPlannerViewModel) {
        self.viewModel = viewModel
        self.plannerViewModel = plannerViewModel
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Controls
                if !viewModel.meals.isEmpty {
                    filterSection
                }
                
                // Meal List
                if viewModel.isLoading {
                    ProgressView("Loading meals...")
                } else if viewModel.filteredMeals.isEmpty {
                    emptyStateView
                } else {
                    mealList
                }
            }
            .navigationTitle("Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                MealFormView(onMealSaved: {
                    // Reload meals when a new meal is saved
                    viewModel.loadMeals()
                })
            }
            .onAppear {
                viewModel.loadMeals()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                if viewModel.showRetryOption {
                    Button("Retry") {
                        viewModel.retryLastOperation()
                    }
                }
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Protein Filter
            if !viewModel.availableProteins.isEmpty {
                HStack {
                    Text("Protein:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Protein", selection: $viewModel.filterCriteria.proteinFilter) {
                        Text("All").tag(nil as String?)
                        ForEach(viewModel.availableProteins, id: \.self) { protein in
                            Text(protein).tag(protein as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Carb Filter
            if !viewModel.availableCarbs.isEmpty {
                HStack {
                    Text("Carb:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Carb", selection: $viewModel.filterCriteria.carbFilter) {
                        Text("All").tag(nil as String?)
                        ForEach(viewModel.availableCarbs, id: \.self) { carb in
                            Text(carb).tag(carb as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Clear Filters Button
            if viewModel.filterCriteria.isActive {
                Button("Clear Filters") {
                    viewModel.filterCriteria = FilterCriteria()
                    viewModel.applyFilters()
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .onChange(of: viewModel.filterCriteria) { _, _ in
            viewModel.applyFilters()
        }
    }
    
    private var mealList: some View {
        List {
            // Separate meals into assigned and unassigned
            let assignedMealIds = Set(plannerViewModel.assignments.values.flatMap { $0 }.map { $0.mealId })
            let unassignedMeals = viewModel.filteredMeals.filter { !assignedMealIds.contains($0.id) }
            let assignedMeals = viewModel.filteredMeals.filter { assignedMealIds.contains($0.id) }
            
            // Show unassigned meals first
            ForEach(unassignedMeals) { meal in
                MealRow(meal: meal, isAssigned: false)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteMeal(id: unassignedMeals[index].id)
                }
            }
            
            // Show assigned meals at the end with special styling
            ForEach(assignedMeals) { meal in
                MealRow(meal: meal, isAssigned: true)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteMeal(id: assignedMeals[index].id)
                }
            }
        }
        .refreshable {
            viewModel.loadMeals()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .symbolEffect(.bounce, value: viewModel.filteredMeals.isEmpty)
            
            if viewModel.filterCriteria.isActive {
                Text("No meals match your filters")
                    .font(.headline)
                    .transition(.opacity)
                Text("Try adjusting your filter criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            } else {
                Text("No meals yet")
                    .font(.headline)
                    .transition(.opacity)
                Text("Tap + to add your first meal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.filterCriteria.isActive)
    }
}

/// Row view for displaying a single meal
struct MealRow: View {
    let meal: Meal
    let isAssigned: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.description)
                .font(.headline)
                .italic(isAssigned)
            
            HStack {
                if !meal.primaryProtein.isEmpty {
                    Label(meal.primaryProtein, systemImage: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if !meal.primaryCarb.isEmpty {
                    Label(meal.primaryCarb, systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: meal.primaryProtein)
            
            if !meal.otherComponents.isEmpty {
                Text(meal.otherComponents.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .background(isAssigned ? Color(.systemGray5) : Color.clear)
        .listRowBackground(isAssigned ? Color(.systemGray5) : Color.clear)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
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
    
    return MealListView(
        viewModel: mealListVM,
        plannerViewModel: plannerVM
    )
}
