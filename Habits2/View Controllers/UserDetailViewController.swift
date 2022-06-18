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
}
