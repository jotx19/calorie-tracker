//
//  Extensions.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import Foundation

extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(self))" : String(format: "%.1f", self)
    }
}

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }
}
