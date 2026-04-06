<h1 align="center">CalorieTracker</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9-FA7343?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/iOS-17.0%2B-000000?style=flat-square&logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat-square&logo=xcode&logoColor=white" />
  <img src="https://img.shields.io/badge/WidgetKit-Supported-34C759?style=flat-square" />
  <img src="https://img.shields.io/badge/USDA_FoodData-API-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" />
</p>

<p align="center">
  A native SwiftUI calorie tracking app with a live home screen widget, powered by the USDA FoodData Central API (1M+ foods).
</p>

---

## Screenshots

<p align="center">
  <img src="public/home.png" alt="Home Screen" width="20% " />
  &nbsp;&nbsp;
  <img src="public/search.png" alt="Food Search" width="20%" />
  &nbsp;&nbsp;
  <img src="public/hero.png" alt="Settings" width="20%" />
  &nbsp;&nbsp;
  <img src="public/setting.png" alt="Settings" width="20%" />
</p>

---

## Features

- [x] **Live Home Screen Widget** — Small & medium sizes showing today's calories vs. goal, auto-refreshes and resets midnight.
- [x] **Deep Link from Widget** — Tap the widget to open the Add Food sheet directly via a custom URL scheme
- [x] **USDA Autocomplete Search** — Live search across 1M+ foods with 300ms debounce powered by the FoodData Central API
- [x] **Serving Size Control** — Inline `+` / `−` stepper to adjust portions before logging
- [x] **App Group Sync** — Widget and app share data through a shared `UserDefaults` App Group suite — always in sync
- [x] **Calorie Ring** — Adaptive color ring changes according to progress
- [x] **Daily Goal Settings** — Presets + custom input; default is 2,000 kcal
- [x] **Persistent Storage** — JSON-encoded entries in App Group UserDefaults, auto-pruned to the last 30 days
- [x] **Progress Charts** — Implementing Progress Chart for kcal for past week. 

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Widget | WidgetKit (Static Configuration) |
| Data Sync | App Groups · UserDefaults suite |
| API | USDA FoodData Central REST API |
| Async | Swift Concurrency (`async/await`, `Task`) |
| Storage | `JSONEncoder` / `JSONDecoder` over UserDefaults |
| Deep Linking | Custom URL Scheme (`calorietracker://`) |


## Getting Started

### Prerequisites

- Xcode 15+
- iOS 17+ deployment target
- A free [USDA FoodData Central API key](https://fdc.nal.usda.gov/api-key-signup.html)

### 1 — Clone & Open

```bash
git clone https://github.com/jotx19/CalorieTracker.git
cd CalorieTracker
open CalorieTracker.xcodeproj
```

### 2 — Add the Widget Extension

1. **File → New → Target → Widget Extension**
2. Name: `CalorieWidget`
3. Uncheck **"Include Configuration Intent"** (uses Static configuration)

### 3 — Configure App Groups

> This is required for the widget and app to share data.

1. Select the **CalorieTracker** target → **Signing & Capabilities** → `+` → **App Groups**
2. Add: `group.com.yourname.calorietracker`
3. Repeat for the **CalorieWidget** target
4. Update `appGroupID` in `SharedModels.swift`:

```swift
let appGroupID = "group.com.yourname.calorietracker"
```

### 4 — Set Your USDA API Key

Open `FoodSearchService.swift` and replace:

```swift
let usdaAPIKey = "DEMO_KEY"
```

with your actual key. `DEMO_KEY` works but is limited to **30 req/hour, 50/day**.


## License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  Built with SwiftUI · WidgetKit · USDA FoodData Central
</p>