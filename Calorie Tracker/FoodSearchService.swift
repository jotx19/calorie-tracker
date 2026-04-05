import Foundation
let usdaAPIKey = "KLauaTx8hDkeuHyrk6akRL69w4qLU57FoGf857bx" // Replace with your actual key

struct USDASearchResult: Codable {
    let foods: [USDAFood]
    let totalHits: Int?
}

struct USDAFood: Codable, Identifiable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDANutrient]?

    var id: Int { fdcId }

    var caloriesPer100g: Double? {
        foodNutrients?.first(where: { $0.nutrientId == 1008 })?.value
    }

    var displayName: String {
        if let brand = brandOwner, !brand.isEmpty {
            return "\(description) (\(brand))"
        }
        return description
    }

    var servingDescription: String {
        if let size = servingSize, let unit = servingSizeUnit {
            return "\(Int(size))\(unit)"
        }
        return "100g"
    }

    var caloriesPerServing: Double {
        guard let cal = caloriesPer100g else { return 0 }
        if let size = servingSize {
            return (cal * size) / 100
        }
        return cal
    }
}

struct USDANutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case nutrientId
        case nutrientName
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nutrientId = try container.decodeIfPresent(Int.self, forKey: .nutrientId)
        nutrientName = try container.decodeIfPresent(String.self, forKey: .nutrientName)
        value = try container.decodeIfPresent(Double.self, forKey: .value)
    }
}

class FoodSearchService: ObservableObject {
    @Published var results: [USDAFood] = []
    @Published var isLoading = false
    @Published var error: String?

    private var searchTask: Task<Void, Never>?

    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run { isLoading = true; error = nil }

            do {
                let foods = try await fetchFoods(query: query)
                await MainActor.run {
                    self.results = foods
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Search failed. Check API key."
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchFoods(query: String) async throws -> [USDAFood] {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: usdaAPIKey),
            URLQueryItem(name: "pageSize", value: "15"),
            URLQueryItem(name: "dataType", value: "Branded,SR Legacy,Foundation")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let result = try JSONDecoder().decode(USDASearchResult.self, from: data)
        return result.foods
    }

    func clear() {
        results = []
        error = nil
    }
}
