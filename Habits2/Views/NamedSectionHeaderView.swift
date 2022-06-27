//
//  NamedSectionHeaderView.swift
//  Habits2
//
//  Created by Kaiya Takahashi on 2022-06-10.
//

import UIKit

class NamedSectionHeaderView: UICollectionReusableView {
    
    var _centerYConstraint: NSLayoutConstraint?
    var centerYConstraint: NSLayoutConstraint {
        if _centerYConstraint == nil {
            _centerYConstraint = nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        }
        return _centerYConstraint!
    }
    
    var _topYConstraint: NSLayoutConstraint?
    var topYConstraint: NSLayoutConstraint {
        if _topYConstraint == nil {
            _topYConstraint = nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12)
        }
        return _topYConstraint!
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpView()
    }
    
    private func setUpView() {
        backgroundColor = .systemGray5
        
        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        alignLabelToYCenter()
    }
    
    func alignLabelToTop() {
        topYConstraint.isActive = true
        centerYConstraint.isActive = false
    }
    
    func alignLabelToYCenter() {
        topYConstraint.isActive = false
        centerYConstraint.isActive = true
    }
}
