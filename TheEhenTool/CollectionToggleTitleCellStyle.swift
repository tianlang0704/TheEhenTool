//
//  QueryCellStyle1.swift
//  TheEhenTool
//
//  Created by CMonk on 1/23/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

protocol CollectionToggleTitleCellDelegate {
    func ToggleTitleCellLeftButtonInvoked(ForCell cell: UICollectionViewCell)
    func ToggleTitleCellRightButtonInvoked(ForCell cell: UICollectionViewCell)
}

class CollectionToggleTitleCellStyle: CollectionViewCellRoundBorderShadow {
    @IBOutlet fileprivate weak var thumbView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var titleView: UIView!
    @IBOutlet fileprivate weak var layoutConstraintTitleViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var layoutConstraintTitleViewHeightLoPrio: NSLayoutConstraint!
    
    var delegate: CollectionToggleTitleCellDelegate? = nil
    
    var title: String? {
        set(newTitle) { self.titleLabel.text = newTitle }
        get { return self.titleLabel.text }
    }
    var thumb: UIImage? {
        set(newThumb) { self.thumbView.image = newThumb }
        get { return self.thumbView.image }
    }
    
    
    
    @IBAction func Left(_ sender: UIButton) {
        if let validDelegate = self.delegate {
            validDelegate.ToggleTitleCellLeftButtonInvoked(ForCell: self)
        }
    }
    
    @IBAction func Right(_ sender: UIButton) {
        if let validDelegate = self.delegate {
            validDelegate.ToggleTitleCellRightButtonInvoked(ForCell: self)
        }
    }
    
    
    override var isSelected: Bool {
        didSet {
            AnimateTitle(isShowing: self.isSelected)
        }
    }
    
    func AnimateTitle(isShowing: Bool = true) {
        if isShowing {
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationCurve(.easeInOut)
            UIView.animate(
                withDuration: 0.2, delay: 0, options:.allowUserInteraction,
                animations: {
                    self.titleView.removeConstraint(self.layoutConstraintTitleViewHeight)
                    self.titleView.addConstraint(self.layoutConstraintTitleViewHeightLoPrio)
                    self.layoutIfNeeded() },
                completion: nil)
        }else{
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationCurve(.easeInOut)
            UIView.animate(
                withDuration: 0.2, delay: 0, options:.allowUserInteraction,
                animations: {
                    self.titleView.removeConstraint(self.layoutConstraintTitleViewHeightLoPrio)
                    self.titleView.addConstraint(self.layoutConstraintTitleViewHeight)
                    self.layoutIfNeeded() },
                completion: nil)
        }
    }
}
