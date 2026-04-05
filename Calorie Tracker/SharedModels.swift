import Foundation

let appGroupID = "group.hello-world.Calorie-Tracker"
struct FoodLogEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let calories: Double
    let servingSize: String
    let date: Date

    init(id: UUID = UUID(), name: String, calories: Double, servingSize: String, date: Date = Date()) {
        self.id = id
        self.name = name
        self.calories = calories
        self.servingSize = servingSize
        self.date = date
    }
}
class SharedCalorieStore {
    static let shared = SharedCalorieStore()
    private let defaults: UserDefaults
    private let logKey = "calorieLog"
    private let limitKey = "dailyCalorieLimit"

    private init() {
        defaults = UserDefaults(suiteName: appGroupID) ?? .standard
    }

    var dailyLimit: Int {
        get { defaults.integer(forKey: limitKey) == 0 ? 2000 : defaults.integer(forKey: limitKey) }
        set { defaults.set(newValue, forKey: limitKey) }
    }

    func loadTodayEntries() -> [FoodLogEntry] {
        guard let data = defaults.data(forKey: logKey),
              let entries = try? JSONDecoder().decode([FoodLogEntry].self, from: data)
        else { return [] }
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }

    func loadAllEntries() -> [FoodLogEntry] {
        guard let data = defaults.data(forKey: logKey),
              let entries = try? JSONDecoder().decode([FoodLogEntry].self, from: data)
        else { return [] }
        return entries
    }

    func save(entry: FoodLogEntry) {
        var all = loadAllEntries()
        all.append(entry)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        all = all.filter { $0.date > cutoff }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: logKey)
        }
    }

    func delete(id: UUID) {
        var all = loadAllEntries()
        all.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: logKey)
        }
    }

    func todayTotalCalories() -> Double {
        loadTodayEntries().reduce(0) { $0 + $1.calories }
    }
}
