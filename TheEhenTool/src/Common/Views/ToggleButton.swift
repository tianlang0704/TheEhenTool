//
//  ToggleButton.swift
//  TheEhenTool
//
//  Created by CMonk on 1/24/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

protocol ToggleButtonDelegate {
    func ToggleButtonSelectionChanged(sender: ToggleButton)
}

class ToggleButton: UIButton {
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var delegate: ToggleButtonDelegate? = nil
    var oldBackgroundColor: UIColor? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel?.allowsDefaultTighteningForTruncation = true
    }
    
    override var isHighlighted: Bool {
        didSet {
            if !self.isHighlighted {
                self.isSelected = !self.isSelected
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            self.delegate?.ToggleButtonSelectionChanged(sender: self)
            
            if self.isSelected {
                self.oldBackgroundColor = self.backgroundColor
                UIView.setAnimationBeginsFromCurrentState(true)
                UIView.setAnimationCurve(.easeInOut)
                UIView.animate(
                    withDuration: 0.2, delay: 0, options:.allowUserInteraction,
                    animations: {
                        self.backgroundColor = self.tintColor
                        self.titleLabel?.textColor = self.titleColor(for: .selected)
                        self.layoutIfNeeded() },
                    completion: nil)
            }else{
                UIView.setAnimationBeginsFromCurrentState(true)
                UIView.setAnimationCurve(.easeInOut)
                UIView.animate(
                    withDuration: 0.2, delay: 0, options:.allowUserInteraction,
                    animations: {
                        self.backgroundColor = self.oldBackgroundColor ?? UIColor.clear
                        self.titleLabel?.textColor = self.titleColor(for: .normal)
                        self.layoutIfNeeded() },
                    completion: nil)
                
            }
        }
    }
}
