//
//  SearchInputView.swift
//  TheEhenTool
//
//  Created by CMonk on 1/23/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

protocol SearchInputViewDelegate {
    func SearchInputViewSelectionChanged(ToggleList list: [(String?, Bool)])
    func SearchInputViewSearchInvoked(WithString string: String)
}

class SearchInputView: UIView {
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var multiSelectionView: MultiSelectionView!
    @IBOutlet weak var layoutConstraintContainer: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintSearchBarHeight: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintToggleBarHeight: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintToggleBarHide: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintSearchBarHide: NSLayoutConstraint!
    
    var endEditingTapGestureTarget: UIView? = nil
    var tapGesRec: UITapGestureRecognizer? = nil
    var delegate: SearchInputViewDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard self.subviews.count > 0 else { return }
        self.multiSelectionView.fromNib()
        let titleList = Array(ConfigurationHelper.EHenFilterOptions.cases()).map{ return $0.rawValue }
        self.multiSelectionView.SetTitleList(titleList)
        self.multiSelectionView.delegate = self
    }
    
    func SetTopOffset(Offset offset: CGFloat) {
        self.layoutConstraintContainer.constant = offset
    }
    
    func SetSearchBarHeight(Height height: CGFloat, Animated isAnimated: Bool = false) {
        if isAnimated {
            UIView.animate(withDuration: 0.4) {
                self.layoutConstraintSearchBarHeight.constant = height
                self.layoutIfNeeded()
            }
        }else{
            self.layoutConstraintSearchBarHeight.constant = height
        }
    }
    
    func SetSearchBarShow(_ isShow: Bool = true, Animated isAnimated: Bool = false) {
        var duration: Double = 0
        if isAnimated {
            duration = 0.4
        }
        
        if isShow {
            UIView.animate(withDuration: duration) {
                self.searchTextField.removeConstraint(self.layoutConstraintSearchBarHide)
                self.searchTextField.addConstraint(self.layoutConstraintSearchBarHeight)
                self.layoutIfNeeded()
            }
        }else{
            UIView.animate(withDuration: duration) {
                self.searchTextField.removeConstraint(self.layoutConstraintSearchBarHeight)
                self.searchTextField.addConstraint(self.layoutConstraintSearchBarHide)
                self.layoutIfNeeded()
            }
        }
    }
    
    func SetToggleBarHeight(Height height: CGFloat, Animated isAnimated: Bool = false) {
        var duration: Double = 0
        if isAnimated {
            duration = 0.4
        }
        
        UIView.animate(withDuration: duration) {
            self.layoutConstraintToggleBarHeight.constant = height
            self.layoutIfNeeded()
        }
    }
}

extension SearchInputView: MultiSelectionViewDelegate {
    func MultiSelectionViewSelectionChanged(ButtonList list: [ToggleButton]) {
        self.delegate?.SearchInputViewSelectionChanged(ToggleList: list.map{ return ($0.titleLabel?.text, $0.isSelected) })
    }
}


//Mark: UITextViewDelegate
extension SearchInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        if let validText = self.searchTextField?.text {
            self.delegate?.SearchInputViewSearchInvoked(WithString: validText)
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let validTarget = self.endEditingTapGestureTarget else { return true }
        self.tapGesRec = UITapGestureRecognizer(target: self, action: #selector(EE))
        self.tapGesRec?.numberOfTapsRequired = 1
        validTarget.addGestureRecognizer(self.tapGesRec!)
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let validTarget = self.endEditingTapGestureTarget else { return true }
        guard let validGesture = self.tapGesRec else { return true }
        validTarget.removeGestureRecognizer(validGesture)
        self.tapGesRec = nil
        return true
    }

    func EE() {
        self.endEditing(true)
    }
}
//End: UITextViewDelegate
