//
//  HabitCollectionViewController.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

private let reuseIdentifier = "Cell"

class HabitCollectionViewController: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    var model = Model()
    var dataSource: DataSource!
    var habitsRequestTask: Task<Void, Never>? = nil
    deinit { habitsRequestTask?.cancel() }
    
    enum ViewModel {
        enum Section: Hashable, Comparable {
            // To Sort Section in the order from " .favourite ---> .category "
            static func < (lhs: HabitCollectionViewController.ViewModel.Section, rhs: HabitCollectionViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs) {
                case (category(let l), category(let r)):
                    return l.name > r.name
                case(.favorite, _):
                    return true
                case(_, .favorite):
                    return false
                }
            }
            
            case favorite
            case category(_ category: Category)
        }
        
        typealias Item = Habit
    }
    
    struct Model {
        var habitsByName = [String: Habit]()
        var favouriteHabits: [Habit] {
            return Settings.shared.favouriteHabits
        }
    }
    
    enum SectionHeader: String {
        case kind = "SectionHeader"
        case reuse = "HeaderView"
        
        var identifier: String {
            return rawValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(NamedSectionHeaderView.self, forSupplementaryViewOfKind: SectionHeader.kind.rawValue, withReuseIdentifier: SectionHeader.reuse.rawValue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        update()
    }

    // Get habit objects from a server to update MODEL
    func update() {
        habitsRequestTask?.cancel()
        habitsRequestTask = Task {
            if let habits = try? await HabitRequest().send() {
                // Store data into Swift type
                self.model.habitsByName = habits
            } else {
                self.model.habitsByName = [:]
            }
            // Update ViewModel
            self.updateCollectionView()
            habitsRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        // Distinguish the favoutire habits and category habits, and store them into VIEW MODEL
        // Create dictionary for Snapshot using VIEWMODEL
        var itemsBySection = model.habitsByName.values.reduce(into: [ViewModel.Section: [ViewModel.Item]]()) { partial, habit in
            // This Collection View has ""MULTIPLE SECTION""
            let item = habit
            
            let section: ViewModel.Section
            // Separate Items based on their sections, favourite or category
            if model.favouriteHabits.contains(habit) {
                section = .favorite
            } else {
                section = .category(habit.category)
            }
            partial[section, default: []].append(item)
        }
        // Create an array of section IDs
        let sectionIDs = itemsBySection.keys.sorted()
        itemsBySection = itemsBySection.mapValues { $0.sorted() }
        // Create snapshot and apply to Data Source
        dataSource.applySnapshotUsing(SectionIDS: sectionIDs, itemsBySection: itemsBySection)
    }
    
    func createDataSource() -> DataSource {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Habit", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = itemIdentifier.name
            cell.contentConfiguration = content
            
            return cell
        })
        
        // Supplementary View -> where you set the SECTION'S NAME(ex, favourite, eating etc,)
        dataSource.supplementaryViewProvider = {(collectionView, kind, indexPath) in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: SectionHeader.kind.rawValue, withReuseIdentifier: SectionHeader.reuse.rawValue, for: indexPath) as! NamedSectionHeaderView
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            switch section {
            case .favorite:
                header.nameLabel.text = "Fravourite"
            case .category(let category):
                header.nameLabel.text = category.name
            }
            return header
        }
        
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
           heightDimension: .absolute(44)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item, count: 1
        )
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(36)
        )
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: SectionHeader.kind.rawValue, alignment: .top)
        sectionHeader.pinToVisibleBounds = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        section.boundarySupplementaryItems = [sectionHeader]
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            let item = self.dataSource.itemIdentifier(for: indexPath)!
            
            let favouriteToggle = UIAction(title: self.model.favouriteHabits.contains(item) ? "Unfavourite": "Favourite") { (action) in
                Settings.shared.toggleFavourite(item)
                self.updateCollectionView()
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [favouriteToggle])
        }
        return config
    }
    

    @IBSegueAction func showHabitDetail(_ coder: NSCoder, sender: UICollectionViewCell?, segueIdentifier: String?) -> HabitDetailViewController? {
        guard let cell = sender, let indexPath = collectionView.indexPath(for: cell), let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return HabitDetailViewController(coder: coder, habit: item)
    }
    
}
