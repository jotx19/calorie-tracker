//
//  AddFoodView.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = FoodSearchViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search food...", text: $vm.query)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: vm.query) { _, _ in vm.onQueryChange() }
                    if !vm.query.isEmpty {
                        Button(action: vm.clear) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding()

                // Selected food detail
                if let food = vm.selectedFood {
                    FoodDetailCard(vm: vm, food: food) {
                        if vm.logFood() { dismiss() }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // States
                Group {
                    if vm.isLoading {
                        Spacer()
                        ProgressView("Searching USDA...").tint(.green)
                        Spacer()
                    } else if let err = vm.error {
                        Spacer()
                        Text(err).foregroundStyle(.secondary)
                        Spacer()
                    } else if vm.query.isEmpty && vm.selectedFood == nil {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.4))
                            Text("Search 1M+ foods")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else if vm.selectedFood == nil {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(vm.results) { food in
                                    FoodResultRow(food: food) {
                                        withAnimation(.spring(duration: 0.3)) {
                                            vm.select(food)
                                            focused = false
                                        }
                                    }
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}

// MARK: - Food Result Row
struct FoodResultRow: View {
    let food: FoodItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(food.emoji)
                    .font(.title2)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(food.calories))")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Food Detail Card
struct FoodDetailCard: View {
    @ObservedObject var vm: FoodSearchViewModel
    let food: FoodItem
    let onLog: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Name + calories
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(food.servingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(vm.calculatedCalories))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
            }

            // Macros bar
            HStack(spacing: 0) {
                MacroMiniCell(label: "Protein", value: vm.calculatedProtein, color: .blue)
                MacroMiniCell(label: "Carbs", value: vm.calculatedCarbs, color: .orange)
                MacroMiniCell(label: "Fat", value: vm.calculatedFat, color: .pink)
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            // Servings
            HStack {
                Text("Servings")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { vm.adjustServings(by: -0.5) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    Text(vm.servings.truncatingRemainder(dividingBy: 1) == 0
                         ? "\(Int(vm.servings))"
                         : String(format: "%.1f", vm.servings))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                    Button(action: { vm.adjustServings(by: 0.5) }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }
            }

            // Log button
            Button(action: onLog) {
                Text("Log \(Int(vm.calculatedCalories)) kcal")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.green)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MacroMiniCell: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}
