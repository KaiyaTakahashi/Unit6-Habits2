//
//  HomeCollectionViewController.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

private let reuseIdentifier = "Cell"

class HomeCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    var updateTimer: Timer?
    var userRequestTask: Task<Void, Never>? = nil
    var habitRequestTask: Task<Void, Never>? = nil
    var combinedStatisticsRequestTask: Task<Void, Never>? = nil
    deinit {
        userRequestTask?.cancel()
        habitRequestTask?.cancel()
        combinedStatisticsRequestTask?.cancel()
    }
    
    enum ViewModel {
        enum Section: Hashable {
            case leaderBoard
            case followedUsers
        }
        
        enum Item: Hashable {
            case leaderBoardHabit(name: String, leadingUserRanking: String?, secondaryUserRanking: String?)
            case followedUser(_ user: User, _ message: String)
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .leaderBoardHabit(let name, _, _):
                    hasher.combine(name)
                case .followedUser(let user,_):
                    hasher.combine(user)
                }
            }
            
            static func ==(_ lhs: Item, _ rhs: Item) -> Bool {
                switch (lhs, rhs) {
                case (.leaderBoardHabit(let lName, _, _), .leaderBoardHabit(let rName, _, _)):
                    return lName == rName
                case (.followedUser(let lUser, _), .followedUser(let rUser, _)):
                    return lUser == rUser
                default:
                    return false
                }
            }
        }
    }
    
    struct Model {
        var usersByID = [String: User]()
        var habitsByName = [String: Habit]()
        var habitStatistics = [HabitStatistics]()
        var userStatistics = [UserStatistic]()
        
        var currentUser: User {
            return Settings.shared.currentUser
        }
        
        var users: [User] {
            return Array(usersByID.values)
        }
        
        var habits: [Habit] {
            return Array(habitsByName.values)
        }
        
        var followedUser: [User] {
            return Array(usersByID.filter {
                Settings.shared.followedUserIDs.contains($0.key)
            }.values)
        }
        
        var favouriteHabits: [Habit] {
            return Settings.shared.favouriteHabits
        }
        
        var nonfavouriteHabits: [Habit] {
            return habits.filter { !favouriteHabits.contains($0) }
        }
    }
    
    var model = Model()
    var dataSource: DataSourceType!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userRequestTask = Task {
            if let users = try? await UserRequest().send() {
                self.model.usersByID = users
            }
            self.updateCollectionView()
            
            userRequestTask = nil
        }
        
        habitRequestTask = Task {
            if let habits = try? await HabitRequest().send() {
                self.model.habitsByName = habits
            }
            self.updateCollectionView()
            
            habitRequestTask = nil
        }
        
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        update()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.update()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        updateTimer?.invalidate()
        updateTimer = nil
    }

    
    func updateCollectionView() {
        var sectionIDs = [ViewModel.Section]()
        
        let leaderboardItems = self.model.habitStatistics.filter { statistics in
            return self.model.favouriteHabits.contains { $0.name == statistics.habit.name }
        }.sorted {
            $0.habit.name < $1.habit.name
        }.reduce(into: [ViewModel.Item]()) { partialResult, statistic in
            // Rank the user counts from highest to lowest
            let rankedUserCounts = statistic.userCounts.sorted { $0.count > $1.count }
            // Find index of the current user's count
            let myCountIndex = rankedUserCounts.firstIndex { $0.user.id == self.model.currentUser.id }
            
            func userRankString(from userCount: UserCount) -> String {
                var name = userCount.user.name
                var ranking = ""
                
                if userCount.user.id == self.model.currentUser.id {
                    name = "You"
                    ranking = "\(ordinalString(from: myCountIndex!))"
                }
                return "\(name) \(userCount.count)" + ranking
            }
            
            var leadingRanking: String?
            var secondaryRanking: String?
            
            switch rankedUserCounts.count {
            case 0:
                leadingRanking = "Nobody yet!"
            case 1:
                let onlyCount = rankedUserCounts.first!
                leadingRanking = userRankString(from: onlyCount)
            default:
                leadingRanking = userRankString(from: rankedUserCounts[0])
                
                if let myCountIndex = myCountIndex, myCountIndex != rankedUserCounts.startIndex {
                    // If true, user's count and ranking should be displaed in secondary label.
                    secondaryRanking = userRankString(from: rankedUserCounts[myCountIndex])
                } else {
                    // If false, the second-place user should be displayed in seconday label.
                    secondaryRanking = userRankString(from: rankedUserCounts[1])
                }
            }
            let leaderboardItem = ViewModel.Item.leaderBoardHabit(name: statistic.habit.name, leadingUserRanking: leadingRanking, secondaryUserRanking: secondaryRanking)
            
            partialResult.append(leaderboardItem)
        }
        sectionIDs.append(.leaderBoard)
        var itemsBySection = [ViewModel.Section.leaderBoard: leaderboardItems]
        
        
        var followedUserItems = [ViewModel.Item]()
        
        let currentUserLoggedHabits = loggedHabitNames(model.currentUser)
        let favouriteLoggedHabits = Set(model.favouriteHabits.map { $0.name }).intersection(currentUserLoggedHabits)
        
      
        for followedUser in model.followedUser.sorted(by: { $0.name < $1.name }) {
            var message: String
            
            let followedUserLoggedHabits = loggedHabitNames(followedUser)
            let commonLoggedHabits = followedUserLoggedHabits.intersection(currentUserLoggedHabits)
            
            if commonLoggedHabits.count > 0 {
                let habitName: String
                let commonFavouriteLoggedHabits = favouriteLoggedHabits.intersection(commonLoggedHabits)
                
                if commonFavouriteLoggedHabits.count > 0 {
                    habitName = commonFavouriteLoggedHabits.sorted().first!
                } else {
                    habitName = commonLoggedHabits.sorted().first!
                }
                
                let habitStats = model.habitStatistics.first { $0.habit.name == habitName }!
                let rankedUserCounts = habitStats.userCounts.sorted { $0.count < $1.count }
                let currentUserRanking = rankedUserCounts.firstIndex { $0.user == model.currentUser }!
                let followedUserRanking = rankedUserCounts.firstIndex { $0.user == followedUser }!
                
                if currentUserRanking < followedUserRanking {
                    message = "Currently #\(ordinalString(from: currentUserRanking)), behind you (#\(ordinalString(from: followedUserRanking))) in \(habitName). \nSend them a friendly reminder!"
                } else if currentUserRanking > followedUserRanking {
                    message = "Currently #\(ordinalString(from: currentUserRanking)), ahead of you (#\(ordinalString(from: followedUserRanking))) in \(habitName). \nYou might catch up with a little extra effort!"
                } else {
                    message = "You're tied at \(ordinalString(from: currentUserRanking)) in \(habitName)! Now's your chance to pull ahead."
                }
            } else if followedUserLoggedHabits.count > 0 {
                let habitName = followedUserLoggedHabits.sorted().first!
                let habitStats = model.habitStatistics.first { $0.habit.name == habitName }!
                let rankedUserCounts = habitStats.userCounts.sorted { $0.count > $1.count }
                let followedUserRanking = rankedUserCounts.firstIndex { $0.user == followedUser }!
                
                message = "Currently #\(ordinalString(from: followedUserRanking)), in \(habitName). \nMaybe You should give this habit a look."
            } else {
                message = "This user doesn't seem to have done much yet. Check in to see if they need any help getting started."
            }
            followedUserItems.append(.followedUser(followedUser, message))
        }
        sectionIDs.append(.followedUsers)
        itemsBySection[.followedUsers] = followedUserItems
        
        dataSource.applySnapshotUsing(SectionIDS: sectionIDs, itemsBySection: itemsBySection)
    }
    
    static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()
    
    func ordinalString(from number: Int) -> String {
        return Self.formatter.string(from: NSNumber(integerLiteral: number + 1))!
    }
    
    func loggedHabitNames(_ user: User) -> Set<String> {
        var names = [String]()
        
        if let stats = model.userStatistics.first(where: { $0.user == user }) {
            names = stats.habitCounts.map { $0.habit.name }
        }
        
        return Set(names)
    }
    
    
    func update() {
        combinedStatisticsRequestTask?.cancel()
        combinedStatisticsRequestTask = Task {
            if let combinedStats = try? await CombinedStatsRequest().send() {
                self.model.userStatistics = combinedStats.userStatistics
                self.model.habitStatistics = combinedStats.habitStatistics
            } else {
                self.model.userStatistics = []
                self.model.habitStatistics = []
            }
            self.updateCollectionView()
            
            combinedStatisticsRequestTask = nil
        }
    }
    
    func createDataSource() -> DataSourceType {
        let dataSource = DataSourceType(collectionView: collectionView) { (collectionView, indexPath, itemIdentifier) -> UICollectionViewCell? in
            switch itemIdentifier {
            case .leaderBoardHabit(let name, leadingUserRanking: let leadingUserRanking, secondaryUserRanking: let secondaryUserRanking) :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LeaderBoardHabit", for: indexPath) as! LeaderboardHabitCollectionViewCell
                cell.habitNameLabel.text = name
                cell.leaderLabel.text = leadingUserRanking
                cell.secondaryLabel.text = secondaryUserRanking
                return cell
            case .followedUser(let user, let message):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowedUser", for: indexPath) as! FollowedUserCollectionViewCell
                cell.primaryTextLabel.text = user.name
                cell.secondaryTextLabel.text = message
                return cell
            }
        }
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            switch self.dataSource.snapshot().sectionIdentifiers[sectionIndex]{
            case .leaderBoard:
                let leaderboardItemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(0.3)
                )
                let leaderboardItem = NSCollectionLayoutItem(layoutSize: leaderboardItemSize)
                
                let verticalTrioSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.75),
                    heightDimension: .fractionalWidth(0.75)
                )
                let leaderBoardverticalTrio = NSCollectionLayoutGroup.vertical(layoutSize: verticalTrioSize, subitem: leaderboardItem, count: 3)
                leaderBoardverticalTrio.interItemSpacing = .fixed(10)
                
                let leaderboardSection = NSCollectionLayoutSection(group: leaderBoardverticalTrio)
                leaderboardSection.interGroupSpacing = 20
                leaderboardSection.orthogonalScrollingBehavior = .continuous
                leaderboardItem.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20)
                return leaderboardSection
            case .followedUsers:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let followedUserItem = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
                let followedUserGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: followedUserItem, count: 1)
                let followedUserSection = NSCollectionLayoutSection(group: followedUserGroup)
                return followedUserSection
            }
        }
        return layout
    }
}
