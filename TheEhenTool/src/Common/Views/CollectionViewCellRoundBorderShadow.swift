//
//  CollectionViewCellRoundBorderShadow.swift
//  TheEhenTool
//
//  Created by CMonk on 1/17/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

class CollectionViewCellRoundBorderShadow: UICollectionViewCell {
    func CellRoundBorder(cell: UICollectionViewCell) {
        cell.contentView.layer.cornerRadius = 3.0;
        cell.contentView.layer.borderWidth = 0.5;
        cell.contentView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor
        cell.contentView.layer.masksToBounds = true;
    }
    
    func CellShadow(cell: UICollectionViewCell) {
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.3
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        self.CellShadow(cell: self)
        self.CellRoundBorder(cell: self)
    }
}
