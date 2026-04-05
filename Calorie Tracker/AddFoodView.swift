import SwiftUI
import WidgetKit

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = FoodSearchService()
    @State private var query = ""
    @State private var selectedFood: USDAFood?
    @State private var customServings: String = "1"
    @State private var showingConfirmation = false
    @FocusState private var isSearchFocused: Bool

    var caloriesForEntry: Double {
        guard let food = selectedFood else { return 0 }
        let multiplier = Double(customServings) ?? 1.0
        return food.caloriesPerServing * multiplier
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search food (e.g. banana, chicken...)", text: $query)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .onChange(of: query) { _, newVal in
                            selectedFood = nil
                            searchService.search(query: newVal)
                        }
                    if !query.isEmpty {
                        Button(action: {
                            query = ""
                            selectedFood = nil
                            searchService.clear()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 12)

                if let food = selectedFood {
                    FoodDetailCard(
                        food: food,
                        servings: $customServings,
                        totalCalories: caloriesForEntry
                    ) {
                        logFood(food)
                    }
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Group {
                    if searchService.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.large)
                                .tint(.green)
                            Text("Searching USDA database...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                            Spacer()
                        }
                    } else if let err = searchService.error {
                        ErrorView(message: err)
                    } else if query.isEmpty && selectedFood == nil {
                        EmptySearchPrompt()
                    } else if searchService.results.isEmpty && !query.isEmpty {
                        NoResultsView(query: query)
                    } else if selectedFood == nil {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(searchService.results) { food in
                                    FoodResultRow(food: food) {
                                        withAnimation(.spring(duration: 0.35)) {
                                            selectedFood = food
                                            customServings = "1"
                                        }
                                        isSearchFocused = false
                                    }
                                    Divider().padding(.leading, 16)
                                }
                            }
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: searchService.isLoading)
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { isSearchFocused = true }
        }
    }

    private func logFood(_ food: USDAFood) {
        let servings = Double(customServings) ?? 1.0
        let entry = FoodLogEntry(
            name: food.description,
            calories: food.caloriesPerServing * servings,
            servingSize: "\(servings == 1 ? "" : "\(Int(servings))x ")\(food.servingDescription)"
        )
        SharedCalorieStore.shared.save(entry: entry)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

struct FoodResultRow: View {
    let food: USDAFood
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Text(foodEmoji(for: food.description))
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(food.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let brand = food.brandOwner {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(food.caloriesPerServing))")
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

    private func foodEmoji(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("apple") { return "🍎" }
        if n.contains("banana") { return "🍌" }
        if n.contains("chicken") { return "🍗" }
        if n.contains("beef") || n.contains("steak") { return "🥩" }
        if n.contains("fish") || n.contains("salmon") || n.contains("tuna") { return "🐟" }
        if n.contains("rice") { return "🍚" }
        if n.contains("egg") { return "🥚" }
        if n.contains("milk") { return "🥛" }
        if n.contains("bread") { return "🍞" }
        if n.contains("pizza") { return "🍕" }
        if n.contains("coffee") { return "☕" }
        if n.contains("orange") { return "🍊" }
        if n.contains("broccoli") { return "🥦" }
        if n.contains("carrot") { return "🥕" }
        if n.contains("potato") { return "🥔" }
        if n.contains("burger") { return "🍔" }
        if n.contains("pasta") || n.contains("spaghetti") { return "🍝" }
        if n.contains("cheese") { return "🧀" }
        if n.contains("yogurt") { return "🥛" }
        if n.contains("chocolate") { return "🍫" }
        return "🍽️"
    }
}

struct FoodDetailCard: View {
    let food: USDAFood
    @Binding var servings: String
    let totalCalories: Double
    let onLog: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.description)
                        .font(.headline)
                        .lineLimit(2)
                    if let brand = food.brandOwner {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Serving: \(food.servingDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Servings")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 12) {
                    Button(action: adjustServings(-1)) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    TextField("1", text: $servings)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 44)
                        .padding(6)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    Button(action: adjustServings(1)) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }
            }

            Button(action: onLog) {
                Label("Log \(Int(totalCalories)) kcal", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.green)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func adjustServings(_ delta: Int) -> () -> Void {
        {
            let current = Double(servings) ?? 1.0
            let new = max(0.5, current + Double(delta) * 0.5)
            servings = new.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(new))
                : String(format: "%.1f", new)
        }
    }
}

// MARK: - Empty/Error States
struct EmptySearchPrompt: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.6))
            Text("Search the USDA database")
                .font(.headline)
            Text("Over 1 million foods available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct NoResultsView: View {
    let query: String
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No results for \"\(query)\"")
                .font(.headline)
            Text("Try a more general term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct ErrorView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Make sure you have a valid USDA API key")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
