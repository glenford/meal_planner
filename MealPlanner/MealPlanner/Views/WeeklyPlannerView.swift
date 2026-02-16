//
//  WeeklyPlannerView.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import SwiftUI

/// View for displaying and managing the weekly meal planner
/// Shows 7 days with assigned meals and navigation controls
struct WeeklyPlannerView: View {
    @StateObject private var viewModel: WeeklyPlannerViewModel
    @State private var showingMealSelector = false
    @State private var selectedDate: Date?
    
    /// Initialize with a view model
    /// - Parameter viewModel: The view model to use
    init(viewModel: WeeklyPlannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Navigation Controls
                navigationControls
                
                // Week Display
                if viewModel.isLoading {
                    ProgressView("Loading week...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.weekDays, id: \.self) { date in
                                DayCard(
                                    date: date,
                                    meals: viewModel.getMealsForDay(date),
                                    onAddMeal: {
                                        selectedDate = date
                                        showingMealSelector = true
                                    },
                                    onRemoveMeal: { mealId in
                                        if let assignment = viewModel.assignments[date.startOfDay]?.first(where: { $0.mealId == mealId }) {
                                            viewModel.removeAssignment(id: assignment.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Weekly Planner")
            .onAppear {
                viewModel.resetToCurrentWeek()
            }
            .sheet(isPresented: $showingMealSelector) {
                if let date = selectedDate {
                    MealSelectorView(
                        date: date,
                        viewModel: viewModel
                    )
                }
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
    
    private var navigationControls: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.navigateBackward()
                }
            }) {
                Label("Previous Week", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Text("Week of \(viewModel.currentWeekStart.formatted(style: .medium))")
                .font(.headline)
                .transition(.opacity)
                .id(viewModel.currentWeekStart)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.navigateForward()
                }
            }) {
                Label("Next Week", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

/// Card view for displaying a single day with its meals
struct DayCard: View {
    let date: Date
    let meals: [Meal]
    let onAddMeal: () -> Void
    let onRemoveMeal: (UUID) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day Header
            HStack {
                VStack(alignment: .leading) {
                    Text(date.dayName)
                        .font(.headline)
                    Text(date.formatted(style: .medium))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                    onAddMeal()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
            }
            
            Divider()
            
            // Meals List
            if meals.isEmpty {
                Text("No meals assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
                    .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(meals) { meal in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.description)
                                    .font(.subheadline)
                                
                                HStack {
                                    if !meal.primaryProtein.isEmpty {
                                        Label(meal.primaryProtein, systemImage: "leaf.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                    
                                    if !meal.primaryCarb.isEmpty {
                                        Label(meal.primaryCarb, systemImage: "flame.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    onRemoveMeal(meal.id)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: meals.count)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// View for selecting a meal to assign to a date
struct MealSelectorView: View {
    let date: Date
    @ObservedObject var viewModel: WeeklyPlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMealId: UUID?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.meals.values).sorted(by: { $0.description < $1.description })) { meal in
                    Button(action: {
                        selectedMealId = meal.id
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.assignMeal(mealId: meal.id, to: date)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.description)
                                    .font(.headline)
                                
                                HStack {
                                    if !meal.primaryProtein.isEmpty {
                                        Label(meal.primaryProtein, systemImage: "leaf.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    
                                    if !meal.primaryCarb.isEmpty {
                                        Label(meal.primaryCarb, systemImage: "flame.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if selectedMealId == meal.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let plannerService = PlannerService(assignmentRepository: AssignmentRepository())
    let viewModel = WeeklyPlannerViewModel(plannerService: plannerService)
    WeeklyPlannerView(viewModel: viewModel)
}
