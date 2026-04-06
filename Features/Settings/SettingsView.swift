//
//  SettingsView.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var limits = CalorieStore.shared.limits

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goals") {
                    LimitRow(label: "Calories", value: $limits.calories, unit: "kcal", color: .green)
                    LimitRow(label: "Protein", value: $limits.protein, unit: "g", color: .blue)
                    LimitRow(label: "Carbs", value: $limits.carbs, unit: "g", color: .orange)
                    LimitRow(label: "Fat", value: $limits.fat, unit: "g", color: .pink)
                }

                Section("Calorie Presets") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                        ForEach([1500, 1800, 2000, 2200, 2500, 3000], id: \.self) { cal in
                            Button(action: { limits.calories = cal }) {
                                Text("\(cal)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(limits.calories == cal ? Color.green : Color(.secondarySystemBackground))
                                    .foregroundStyle(limits.calories == cal ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("API") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USDA API Key")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Edit kUSDAKey in FoodSearchService.swift")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Link("Get Free Key →", destination: URL(string: "https://fdc.nal.usda.gov/api-key-signup.html")!)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        CalorieStore.shared.limits = limits
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

struct LimitRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
            Spacer()
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .fontWeight(.semibold)
            Text(unit)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
