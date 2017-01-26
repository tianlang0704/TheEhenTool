//
//  TitleCellStyle1.swift
//  TheEhenTool
//
//  Created by CMonk on 1/17/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

protocol CollectionTitleCellDelegate {
    func RemoveInvoked(ForCell cell: UICollectionViewCell)
    func ViewInvoked(ForCell cell: UICollectionViewCell)
}

class CollectionTitleCellStyle: CollectionViewCellRoundBorderShadow {
    @IBOutlet fileprivate weak var thumb: UIImageView!
    @IBOutlet fileprivate weak var title: UILabel!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var layoutConstraintTopBarHeight30: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintTopBarHeight0: NSLayoutConstraint!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var layoutConstraintBottomBarHeight40: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintBottomBarHeight0: NSLayoutConstraint!
    
    var delegate: CollectionTitleCellDelegate? = nil
    
    var isOptionsShown = false
    
    var bookThumb: UIImage? {
        set(newThumb) { self.thumb.image = newThumb }
        get { return self.thumb.image }
    }
    
    var bookTitle: String? {
        set(newTitle) { self.title.text = newTitle }
        get { return self.title.text }
    }
    
    override var isSelected: Bool {
        didSet {
            self.AnimateOptionsBar(ToShow: self.isSelected)
        }
    }
    
    func AnimateOptionsBar(ToShow isShow: Bool) {
        self.isOptionsShown = isShow
        if self.isOptionsShown {
            UIView.animate(withDuration: 0.2) {
                self.topBar.removeConstraint(self.layoutConstraintTopBarHeight0)
                self.topBar.addConstraint(self.layoutConstraintTopBarHeight30)
                self.bottomBar.removeConstraint(self.layoutConstraintBottomBarHeight0)
                self.bottomBar.addConstraint(self.layoutConstraintBottomBarHeight40)
                self.layoutIfNeeded()
            }
        }else{
            UIView.animate(withDuration: 0.2) {
                self.topBar.removeConstraint(self.layoutConstraintTopBarHeight30)
                self.topBar.addConstraint(self.layoutConstraintTopBarHeight0)
                self.bottomBar.removeConstraint(self.layoutConstraintBottomBarHeight40)
                self.bottomBar.addConstraint(self.layoutConstraintBottomBarHeight0)
                self.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func Remove(_ sender: UIButton) {
        self.delegate?.RemoveInvoked(ForCell: self)
    }
    
    
    @IBAction func View(_ sender: UIButton) {
        self.delegate?.ViewInvoked(ForCell: self)
    }
}
