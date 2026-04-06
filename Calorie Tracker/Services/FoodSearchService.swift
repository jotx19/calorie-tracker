//
//  FoodSearchService.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import Foundation

let kUSDAKey = "" // Replace with your key from fdc.nal.usda.gov

final class FoodSearchService {
    static let shared = FoodSearchService()
    private var searchTask: Task<Void, Never>?

    func search(query: String) async throws -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "api_key", value: kUSDAKey),
            URLQueryItem(name: "pageSize", value: "20"),
            URLQueryItem(name: "dataType", value: "Branded,SR Legacy,Foundation")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return response.foods.map { $0.toFoodItem() }
    }
}
