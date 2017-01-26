//
//  MultiSelectionView.swift
//  TheEhenTool
//
//  Created by CMonk on 1/24/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit

protocol MultiSelectionViewDelegate {
    func MultiSelectionViewSelectionChanged(ButtonList list: [ToggleButton])
}

class MultiSelectionView: UIView {
    var delegate: MultiSelectionViewDelegate? = nil
    var buttonList = [ToggleButton]()
    var titleList = [String]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.subviews.count > 0 {
            self.InitializeComponentViews()
        }
    }
    
    func SetTitleList(_ titles: [String]) {
        self.titleList = titles
    }
    
    func InitializeComponentViews() {
        var lastButton: ToggleButton? = nil
        for title in self.titleList {
            guard let button: ToggleButton = ToggleButton().fromNib() else { print("EhenSearchSelectionView: Cannot get button from nib"); return }
            button.setTitle(title, for: .normal)
            button.isSelected = true
            button.delegate = self
            //button.addTarget(self, action: #selector(HandleButtonPress), for: .touchUpInside)
            self.addSubview(button)
            self.buttonList.append(button)
            
            //Adding constrants
            let vc = NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[thisButton]-1-|",
                options: [], metrics: nil, views: ["thisButton": button])
            var hc: [NSLayoutConstraint] = []
            var wc: [NSLayoutConstraint] = []
            if lastButton == nil {
                hc = NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|[thisButton]",
                    options: [], metrics: nil, views: ["thisButton": button])
            }else{
                hc = NSLayoutConstraint.constraints(
                    withVisualFormat: "H:[lastButton]-1-[thisButton]",
                    options: [], metrics: nil, views: ["thisButton": button, "lastButton": lastButton!])
                wc = NSLayoutConstraint.constraints(
                    withVisualFormat: "H:[lastButton(==thisButton)]",
                    options: [], metrics: nil, views: ["thisButton": button, "lastButton": lastButton!])
            }
            self.addConstraints(hc)
            self.addConstraints(vc)
            self.addConstraints(wc)
            lastButton = button
        }
        if let validLastButton = lastButton {
            let lastC = NSLayoutConstraint.constraints(
                withVisualFormat: "H:[thisButton]|",
                options: [], metrics: nil, views: ["thisButton": validLastButton])
            self.addConstraints(lastC)
        }
    }
}

extension MultiSelectionView: ToggleButtonDelegate {
    func ToggleButtonSelectionChanged(sender: ToggleButton) {
        self.delegate?.MultiSelectionViewSelectionChanged(ButtonList: self.buttonList)
    }
}
