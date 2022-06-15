//
//  HabitStatistics.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-11.
//

import Foundation

struct HabitStatistics {
    let habit: Habit
    let userCounts: [UserCount]
}

extension HabitStatistics: Codable { }
