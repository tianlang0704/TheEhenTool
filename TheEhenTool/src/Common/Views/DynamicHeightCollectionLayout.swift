//
//  DynamicHeightCollectionLayout.swift
//  TheEhenTool
//
//  Created by CMonk on 1/14/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

typealias DynamicHeightCollectionLayoutDelegate = ColumnCollectionLayoutDelegate

class DynamicHeightCollectionLayout: ColumnCollectionLayout {
    override func NextColumn(currentColumn: Int, columnNumber: Int, currentCellRect: CGRect) -> Int {
        return currentCellRect.maxY > self.collectionHeight
            ? (currentColumn >= columnNumber - 1 ? 0 : currentColumn + 1)
            : currentColumn
    }

}
