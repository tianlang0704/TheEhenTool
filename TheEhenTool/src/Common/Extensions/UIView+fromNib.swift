//
//  UIView+fromNib.swift
//  TheEhenTool
//
//  Created by CMonk on 1/24/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    @discardableResult
    func fromNib<T: UIView>() -> T? {
        guard let view = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)?[0] as? T else {
            return nil
        }
        
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        return view
    }
}
