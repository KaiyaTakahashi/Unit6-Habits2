//
//  APIService.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-07.
//

import Foundation
import UIKit

struct HabitRequest: APIRequest {
    typealias Response = [String: Habit]
    
    var path: String { "/habits" }
    
    var habitName: String?
}

struct UserRequest: APIRequest {
    typealias Response = [String: User]
    
    var path: String { "/users" }
}

struct HabitStatisticsRequest: APIRequest {
    typealias Response = [HabitStatistics]
    
    var path: String { "/habitStats" }
    
    var habitNames: [String]?
    
    var queryItems: [URLQueryItem]? {
        if let habitNames = habitNames {
            return [URLQueryItem(name: "names", value: habitNames.joined(separator: ","))]
        } else {
            return nil
        }
    }
}

struct UserStatisticsRequest: APIRequest {
    typealias Response = [UserStatistic]
    
    var path: String { "/userStats"}
    
    var userIDs: [String]?
    
    var queryItems: [URLQueryItem]? {
        if let userIDs = userIDs {
            return [URLQueryItem(name: "ids", value: userIDs.joined(separator: ","))]
        } else {
            return nil
        }
    }
}

struct HabitLeadStatisticsRequest: APIRequest {
    typealias Response = UserStatistic
    
    var userID: String
    
    var path: String { "/userLeadingStats/\(userID)" }
}

struct ImageRequest: APIRequest {
    typealias Response = UIImage
    
    var imageID: String
    
    var path: String { "/images/" + imageID }
}

struct LoggedHabitRequest: APIRequest {
    typealias Response = Void
    
    var loggedHabit: LoggedHabit
    
    var path: String { "/loggedHabit" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try! encoder.encode(loggedHabit)
    }
}

struct CombinedStatsRequest: APIRequest {
    typealias Response = CombinedStatistics
    
    var path: String { "/combinedStats" }
}
