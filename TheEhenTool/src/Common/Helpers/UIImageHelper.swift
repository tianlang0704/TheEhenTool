//
//  UIImageHelper.swift
//  TheEhenTool
//
//  Created by CMonk on 1/16/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class UIImageHelper {
    static func Aspect(HeightForSize size: CGSize, WithWidth width: CGFloat) -> CGFloat {
        return self.Aspect(RectForSize: size, WithWidth: width).height
    }
    
    static func Aspect(SizeForSize size: CGSize, WithWidth width: CGFloat) -> CGSize {
        return self.Aspect(RectForSize: size, WithWidth: width).size
    }
    
    static func Aspect(RectForSize size: CGSize, WithWidth width: CGFloat) -> CGRect {
        let boundingRect = CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        var newRect = AVMakeRect(aspectRatio: size, insideRect: boundingRect)
        newRect.origin = CGPoint(x: 0, y: 0)
        return newRect
    }
    
    static func Aspect(Image image: UIImage, WithWidth width: CGFloat) -> UIImage? {
        let newRect = Aspect(RectForSize: image.size, WithWidth: width)
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, 0.0)
        image.draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
