//
//  UIView+ShowActivityIndicator.swift
//  TheEhenTool
//
//  Created by CMonk on 1/26/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func ShowActivityIndicator() {
        //Temporary solution, race conditoin possible
        guard self.viewWithTag(9999) == nil else { return }
        let uiView = self
        let container: UIView = UIView()
        container.tag = 9999
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80.0, height: 80.0)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red: 0.266, green: 0.266, blue: 0.266, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        actInd.frame = CGRect(x: 0, y: 0, width: 40.0, height: 40.0)
        actInd.activityIndicatorViewStyle = .gray
        actInd.center = CGPoint(
            x: loadingView.frame.size.width / 2,
            y: loadingView.frame.size.height / 2)
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        actInd.startAnimating()
    }
    
    func RemoveActivityIndicator() {
        guard let validContainer = self.viewWithTag(9999) else { return }
        validContainer.removeFromSuperview()
    }
}
