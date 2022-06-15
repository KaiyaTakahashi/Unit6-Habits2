//
//  UICollectionViewDiffableDataSource+ViewModel.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-09.
//

import Foundation
import UIKit

extension UICollectionViewDiffableDataSource {
    
    func applySnapshotUsing(SectionIDS: [SectionIdentifierType], itemsBySection: [SectionIdentifierType: [ItemIdentifierType]], sectionRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>()) {
        applySnapshotUsing(sectionIDs: SectionIDS, itemsBySection: itemsBySection, animatingDifferences: true, sectionsRetainedIfEmpty: sectionRetainedIfEmpty)
    }
    
    func applySnapshotUsing(sectionIDs: [SectionIdentifierType], itemsBySection: [SectionIdentifierType: [ItemIdentifierType]], animatingDifferences: Bool, sectionsRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>()) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        
        // sectionIDs = categories ["Mindfulness", "Exercise", "Eating", "Culture", "Creativity"]
        for sectionID in sectionIDs {
            guard let sectionItems = itemsBySection[sectionID], sectionItems.count > 0 || sectionsRetainedIfEmpty.contains(sectionID) else { continue }
            // sectionItems = bunch of habits in each categories: [Habit]
            snapshot.appendSections([sectionID])
            snapshot.appendItems(sectionItems, toSection: sectionID)
        }
        
        self.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
