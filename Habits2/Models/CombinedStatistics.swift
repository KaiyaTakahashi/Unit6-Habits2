//
//  CombinedStatistics.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-22.
//

import Foundation

struct CombinedStatistics {
    let userStatistics: [UserStatistic]
    let habitStatistics: [HabitStatistics]
}

extension CombinedStatistics: Codable { }
