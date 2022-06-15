//
//  Settings.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-07.
//

import Foundation

struct Settings {
    static var shared = Settings()
    private let defaults = UserDefaults.standard
    var favouriteHabits: [Habit] {
        get {
            // Retrive data like this
            // <["favouriteHabits": [Habit, Habit, ... Habit]]> -> Dictionary
            //         Key                   Value
            // Get "Value" from "Key", Convert "Value" into Data
            return unarchiveJSON(key: Setting.favouriteHabits) ?? []
        }
        set {
            // Store data like this
            // <["favouriteHabits": [Habit, Habit, ... Habit]]> -> Dictionary
            //        key: String           .utf8
            archiveJSON(value: newValue, key: Setting.favouriteHabits)
        }
    }
    var followedUserIDs: [String] {
        get {
            return unarchiveJSON(key: Setting.followedUserUserIDs) ?? []
        }
        set {
            archiveJSON(value: newValue, key: Setting.followedUserUserIDs)
        }
    }
    
    enum Setting {
        static let favouriteHabits = "favouriteHabits"
        static let followedUserUserIDs = "followedUserIDs"
    }
    
    private func archiveJSON<T: Codable>(value: T, key: String) {
        let data = try! JSONEncoder().encode(value)
        let string = String(data: data, encoding: .utf8)
        defaults.set(string, forKey: key)
    }
    
    private func unarchiveJSON<T: Codable>(key: String) -> T? {
        guard let string = defaults.string(forKey: key), let data = string.data(using: .utf8) else { return nil }
        return try! JSONDecoder().decode(T.self, from: data)
    }
    
    // Check if the habit is favourite. if it's in favouriteHabits, filter it out.
    mutating func toggleFavourite(_ habit: Habit) {
        var favourite = favouriteHabits
        
        if favourite.contains(habit) {
            favourite = favourite.filter { $0 != habit }
        } else {
            favourite.append(habit)
        }
        
        favouriteHabits = favourite
    }
    
    mutating func toggleFollowed(_ user: User) {
        var updated = followedUserIDs
        
        if updated.contains(user.id) {
            updated = updated.filter { $0 != user.id }
        } else {
            updated.append(user.id)
        }
        
        followedUserIDs = updated
    }
}
