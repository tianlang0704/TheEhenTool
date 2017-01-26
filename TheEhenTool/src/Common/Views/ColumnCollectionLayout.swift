//
//  DynamicHeightCollectionLayout.swift
//  TheEhenTool
//
//  Created by CMonk on 1/14/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

protocol ColumnCollectionLayoutDelegate {
    func collectionView(collectionView: UICollectionView, forCellContentHeightAt indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
    func collectionViewColumnNumberFor(collectionView: UICollectionView) -> Int
    func collectionViewCellMarginFor(collectionView: UICollectionView) -> CGFloat
    func collectionViewTopInset() -> CGFloat
}

class ColumnCollectionLayout: UICollectionViewLayout {
    
//Mark: variables
    var delegate: ColumnCollectionLayoutDelegate?
    var calculatedCache = [UICollectionViewLayoutAttributes]()
    
    internal var collectionWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - insets.left - insets.right
    }
    internal var collectionHeight: CGFloat = 0
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: self.collectionWidth, height: self.collectionHeight)
    }
//End: variables
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(Rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(Rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    //Mark: Notification functions
    @objc func Rotated() {
        DispatchQueue.main.async {
            self.invalidateLayout()
        }
    }
    //End: Notification functions
    
    func NextColumn(currentColumn: Int, columnNumber: Int, currentCellRect: CGRect) -> Int {
        return currentColumn >= columnNumber - 1 ? 0 : currentColumn + 1
    }
    
    
    
//Mark: overriden functions
    override func prepare() {
        guard let itemNumber = self.collectionView?.numberOfItems(inSection: 0) else { return }
        guard itemNumber >= 0 else { return }
        let columnNumber = self.delegate?.collectionViewColumnNumberFor(collectionView: self.collectionView!) ?? 2
        let cellMargin = self.delegate?.collectionViewCellMarginFor(collectionView: self.collectionView!) ?? 10
        self.ClearCache()
        
        
        let contentTopInset = self.delegate?.collectionViewTopInset() ?? 0
        let halfCellMargin = cellMargin / 2
        let collectionContentWidth = self.collectionWidth - 2 * halfCellMargin
        let cellWidth = collectionContentWidth / CGFloat(columnNumber)
        var xOffsets = [CGFloat]()
        for currentCol in 0..<columnNumber {
            xOffsets.append(halfCellMargin + CGFloat(currentCol) * cellWidth)
        }
        
        var currentColumn = 0
        var yOffsets = [CGFloat](repeating: contentTopInset + halfCellMargin, count: columnNumber)
        for itemIndex in 0..<itemNumber {
            let indexPath = NSIndexPath(item: itemIndex, section: 0)
            
            //Get cell height and width
            let cellContentWidth = cellWidth - halfCellMargin * 2
            let cellContentHeight = self.delegate?.collectionView(collectionView: self.collectionView!, forCellContentHeightAt: indexPath, withWidth: cellContentWidth) ?? 0
            let cellHeight = cellContentHeight + halfCellMargin * 2
            
            //Get cell rect with margin
            let cellRect = CGRect(x: xOffsets[currentColumn], y: yOffsets[currentColumn], width: cellWidth, height: cellHeight)
            let cellRectAfterInset = cellRect.insetBy(dx: halfCellMargin, dy: halfCellMargin)
            
            //Push onto cache
            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
            attribute.frame = cellRectAfterInset
            calculatedCache.append(attribute)
            
            //Update collection height and current column
            yOffsets[currentColumn] = yOffsets[currentColumn] + cellHeight
            currentColumn = NextColumn(
                currentColumn: currentColumn,
                columnNumber: columnNumber,
                currentCellRect: cellRectAfterInset
            )
            self.collectionHeight = max(self.collectionHeight, cellRectAfterInset.maxY)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesInRect = [UICollectionViewLayoutAttributes]()
        
        for curAttr in self.calculatedCache {
            if rect.intersects(curAttr.frame) {
                attributesInRect.append(curAttr)
            }
        }
        
        return attributesInRect
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.calculatedCache[indexPath.item]
    }
//End: overriden functions
    
//Mark: Helper functions
    func ClearCache() {
        self.calculatedCache.removeAll()
        self.collectionHeight = 0
    }
//End: Helper functions
}
