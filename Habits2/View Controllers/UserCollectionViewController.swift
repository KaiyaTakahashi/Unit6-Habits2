//
//  UserCollectionViewController.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-06.
//

import UIKit

private let reuseIdentifier = "Cell"

class UserCollectionViewController: UICollectionViewController {
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    var userRequestTask: Task<Void, Never>? = nil
    deinit { userRequestTask?.cancel() }
    var model = Model()
    var dataSource: DataSourceType!
    
    enum ViewModel {
        typealias Section = Int
        
        struct Item: Hashable {
            let user: User
            let isFollowed: Bool
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(user)
            }
            
            static func ==(_ lhs: Item, _ rhs: Item) -> Bool {
                return lhs.user == rhs.user
            }
            
        }
    }
    
    struct Model {
        var usersByIDs = [String: User]()
        var followedUser: [User] {
            return Array(usersByIDs.filter{
                Settings.shared.followedUserIDs.contains($0.key)
            }.values)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = createDataSource()
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        
        update()
    }

    func update() {
        userRequestTask?.cancel()
        userRequestTask = Task {
            if let users = try? await UserRequest().send() {
                model.usersByIDs = users
            } else {
                model.usersByIDs = [:]
            }
            self.updateCollectionView()
            userRequestTask = nil
        }
    }
    
    func updateCollectionView() {
        // This Collection View has only ""ONE SECTION""
        let users = model.usersByIDs.values.sorted().reduce(into: [ViewModel.Item]()) { partialResult, user in
            partialResult.append(ViewModel.Item(user: user, isFollowed: model.followedUser.contains(user)))
        }
        let itemsBySection = [0: users]
        
        dataSource.applySnapshotUsing(SectionIDS: [0], itemsBySection: itemsBySection)
    }
    
    func createDataSource() -> DataSourceType {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "User", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = itemIdentifier.user.name
            content.directionalLayoutMargins =
            NSDirectionalEdgeInsets(top: 11, leading: 8, bottom: 11, trailing: 8)
            content.textProperties.alignment = .center
            cell.contentConfiguration = content
            return cell
        })
        return dataSource
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalHeight(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(0.45)
           )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        group.interItemSpacing = .fixed(20)
    
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (element) -> UIMenu? in
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            
            let favouriteToggle = UIAction(title: item.isFollowed ? "Unfollow": "Follow") { (action) in
                Settings.shared.toggleFollowed(item.user)
                self.updateCollectionView()
            }
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [favouriteToggle])
        }
        return config
    }
}
