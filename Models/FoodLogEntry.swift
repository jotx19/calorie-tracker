//
//  FoodLogEntry.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//

import Foundation

struct FoodLogEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
    let date: Date

    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        servingSize: String,
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.date = date
    }
}
