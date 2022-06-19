//
//  UserDetailViewController.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

class UserDetailViewController: UIViewController {

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    var user: User!
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    var dataSource: DataSourceType!
    var model = Model()
    
    var userStatisticsRequestTask: Task<Void, Never>? = nil
    var habitLeadStatisticsRequestTask: Task<Void, Never>? = nil
    var imageRequestTask: Task<Void, Never>? = nil
    deinit {
        userStatisticsRequestTask?.cancel()
        habitLeadStatisticsRequestTask?.cancel()
        imageRequestTask?.cancel()
    }
    
    enum ViewModel {
        enum Section: Hashable, Comparable {
            static func < (lhs: UserDetailViewController.ViewModel.Section, rhs: UserDetailViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs) {
                case (.leading, .category), (.leading, .leading) :
                    return true
                case (.category, .leading):
                    return false
                case (.category(let category1), .category(let category2)):
                    return category1.name > category2.name
                }
            }
            
            case leading
            case category(_ category: Category)
        }
        
        typealias Item = HabitCount
    }
    
    struct Model {
        var userStats: UserStatistic?
        var leadingStats: UserStatistic?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userNameLabel.text = user.name
        bioLabel.text = user.bio
    }
    
    init?(coder: NSCoder, user: User) {
        super.init(coder: coder)
        self.user = user
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        userStatisticsRequestTask?.cancel()
        userStatisticsRequestTask = Task {
            if let userStats = try? await UserStatisticsRequest(userIDs: [user.id]).send(), userStats.count > 0 {
                self.model.userStats = userStats[0]
            } else {
                self.model.userStats = nil
            }
            self.updateCollectionView()
            
            userStatisticsRequestTask = nil
        }
        
        habitLeadStatisticsRequestTask?.cancel()
        habitLeadStatisticsRequestTask = Task {
            if let userStats = try? await HabitLeadStatisticsRequest(userID: user.id).send() {
                self.model.leadingStats = userStats
            } else {
                self.model.leadingStats = nil
            }
            self.updateCollectionView()
            
            habitLeadStatisticsRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        guard let userStatistics = self.model.userStats, let leadingStatistics = self.model.leadingStats else { return }
        
        var itemsBySection = userStatistics.habitCounts.reduce(into: [ViewModel.Section: [ViewModel.Item]]()) { partialResult, habitCount in
            let section: ViewModel.Section
            
            if leadingStatistics.habitCounts.contains(habitCount) {
                section = .leading
            } else {
                section = .category(habitCount.habit.category)
            }
            partialResult[section, default: []].append(habitCount)
        }
        
        itemsBySection = itemsBySection.mapValues { $0.sorted() }
        
        let sectionIDs = itemsBySection.keys.sorted()
        
        dataSource.applySnapshotUsing(SectionIDS: sectionIDs, itemsBySection: itemsBySection)
    }
}
