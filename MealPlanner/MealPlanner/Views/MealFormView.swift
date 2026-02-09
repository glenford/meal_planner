//
//  MealFormView.swift
//  MyApp
//
//  Created for Meal Planning Assistant
//

import SwiftUI

/// View for creating and editing meals
/// Provides form inputs for meal description, protein, carb, and other components
struct MealFormView: View {
    @StateObject private var viewModel: MealFormViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let onMealSaved: (() -> Void)?
    
    /// Initialize with a view model and optional callback
    /// - Parameters:
    ///   - viewModel: The view model to use (defaults to new instance)
    ///   - onMealSaved: Optional callback to execute when a meal is saved
    init(viewModel: MealFormViewModel = MealFormViewModel(),
         onMealSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onMealSaved = onMealSaved
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Description Section
                Section(header: Text("Meal Description")) {
                    TextField("Description", text: $viewModel.description)
                }
                
                // Nutritional Information Section
                Section(header: Text("Nutritional Information")) {
                    TextField("Primary Protein", text: $viewModel.primaryProtein)
                    TextField("Primary Carb", text: $viewModel.primaryCarb)
                }
                
                // Other Components Section
                Section(header: Text("Other Components")) {
                    ForEach(Array(viewModel.otherComponents.enumerated()), id: \.offset) { index, component in
                        HStack {
                            Text(component)
                            Spacer()
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.removeComponent(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                    
                    HStack {
                        TextField("Add component", text: $viewModel.newComponent)
                            .onSubmit {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.addComponent()
                                }
                            }
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.addComponent()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(viewModel.newComponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Error Message Section
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveMeal()
                    }
                }
            }
            .onReceive(viewModel.$errorMessage) { errorMessage in
                // Keep form open if there's an error
                if errorMessage == nil && viewModel.description.isEmpty == false {
                    // Only dismiss if save was successful (no error and description was filled)
                }
            }
        }
        .onAppear {
            viewModel.onSaveComplete = {
                onMealSaved?()
                dismiss()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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

#Preview {
    MealFormView()
}
