//
//  User.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import Foundation

struct User {
    let bio: String?
    let name: String
    let color: Color?
    let id: String
}

extension User: Codable { }

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

extension User: Comparable {
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.name < rhs.name
    }    
}
