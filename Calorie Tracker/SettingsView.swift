import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Binding var dailyLimit: Int
    @State private var limitText: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private let presets = [1500, 1800, 2000, 2200, 2500, 3000]

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Calorie Goal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("e.g. 2000", text: $limitText)
                            .keyboardType(.numberPad)
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .focused($isFocused)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button(action: {
                                limitText = "\(preset)"
                                isFocused = false
                            }) {
                                Text("\(preset)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Int(limitText) == preset ? Color.green : Color.secondary.opacity(0.12))
                                    .foregroundStyle(Int(limitText) == preset ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } header: {
                Text("Calorie Target")
            }

            Section {
                Button(action: save) {
                    Text("Save Goal")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .listRowBackground(Color.green)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("USDA API Key", systemImage: "key.fill")
                        .font(.subheadline).fontWeight(.medium)
                    Text("Edit FoodSearchService.swift and replace the `usdaAPIKey` constant with your free key from fdc.nal.usda.gov")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Get Free API Key →", destination: URL(string: "https://fdc.nal.usda.gov/api-key-signup.html")!)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            } header: {
                Text("API Configuration")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            limitText = "\(SharedCalorieStore.shared.dailyLimit)"
        }
    }

    private func save() {
        if let val = Int(limitText), val > 0 {
            SharedCalorieStore.shared.dailyLimit = val
            dailyLimit = val
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        }
    }
}
