//
//  LoggedHabit.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-20.
//

import Foundation

struct LoggedHabit {
    let userID: String
    let habitName: String
    let timestamp: Date
}

extension LoggedHabit: Codable { }
