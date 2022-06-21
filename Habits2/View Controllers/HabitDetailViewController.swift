//
//  HabitDetailViewController.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

@MainActor
class HabitDetailViewController: UIViewController {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!

    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    var updateTimer: Timer?
    var habit: Habit!
    var model = Model()
    var dataSource: DataSourceType!
    var habitStatsRequestTask: Task<Void, Never>? = nil
    deinit { habitStatsRequestTask?.cancel() }
    
    enum ViewModel {
        enum Section: Hashable {
            case leaders(count: Int)
            case remaining
        }
        
        enum Item: Hashable, Comparable {
            case single(_ stat: UserCount)
            case multiple(_ stats: [UserCount])
            
            static func < (lhs: HabitDetailViewController.ViewModel.Item, rhs: HabitDetailViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs) {
                case (.single(let lCount), .single(let rCount)):
                    return lCount.count < rCount.count
                case (.multiple(let lCounts), .multiple(let rCounts)):
                    return lCounts.first!.count < rCounts.first!.count
                case (.single, .multiple):
                    return false
                case (.multiple, .single):
                    return true
                }
            }
        }
    }
    
    struct Model {
        var habitStatistics: HabitStatistics?
        var userCounts: [UserCount] {
            habitStatistics?.userCounts ?? []
//            return [UserCount(user: User(bio: "", name: "kaiya", color: nil, id: "123"), count: 1)]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = habit.name
        categoryLabel.text = habit.category.name
        infoLabel.text = habit.info
        
        dataSource = createDataSource()
        collectionView.dataSource = self.dataSource
        collectionView.collectionViewLayout = createLayout()
        
        update()
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

    init?(coder: NSCoder, habit: Habit) {
        super.init(coder: coder)
        self.habit = habit
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        habitStatsRequestTask?.cancel()
        habitStatsRequestTask = Task {
            if let habitStats = try? await HabitStatisticsRequest(habitNames: [habit.name]).send(), habitStats.count > 0 {
                self.model.habitStatistics = habitStats[0]
            } else {
                self.model.habitStatistics = nil
            }
            self.updateCollectionView()
            habitStatsRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        // Set up View Model and apply Snapshot
        let items = (self.model.userCounts.map { ViewModel.Item.single($0)} ?? []).sorted(by: >)
        print(items)
        dataSource.applySnapshotUsing(SectionIDS: [.remaining], itemsBySection: [.remaining: items])
    }
    
    func createDataSource() -> DataSourceType {
        dataSource = UICollectionViewDiffableDataSource(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "UserCount", for: indexPath) as! UICollectionViewListCell
            var content = UIListContentConfiguration.subtitleCell()
            content.prefersSideBySideTextAndSecondaryText = true
            switch itemIdentifier {
            case .single(let stat):
                content.text = stat.user.name
                content.secondaryText = "\(stat.count)"
                content.textProperties.font = .preferredFont(forTextStyle: .headline)
                content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
            default:
                break
            }
            cell.contentConfiguration = content
            return cell
        })
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(44)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
