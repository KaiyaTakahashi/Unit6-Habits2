//
//  UserStatistics.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-18.
//

import Foundation

struct UserStatistic {
    let user: User
    let habitCounts: [HabitCount]
}

extension UserStatistic: Codable { }
