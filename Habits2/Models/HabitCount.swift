//
//  HabitCount.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-18.
//

import Foundation

struct HabitCount {
    let habit: Habit
    let count: Int
}

extension HabitCount: Codable { }

extension HabitCount: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(habit)
    }
    
    static func ==(_ lhs: HabitCount, _ rhs: HabitCount) -> Bool {
        return lhs.habit == rhs.habit
    }
}