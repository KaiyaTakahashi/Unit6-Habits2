//
//  UserCount.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-11.
//

import Foundation

struct UserCount {
    let user: User
    let count: Int
}

extension UserCount: Codable { }

extension UserCount: Hashable { }
