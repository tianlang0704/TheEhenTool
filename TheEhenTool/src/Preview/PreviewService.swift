//
//  EHenPreviewService.swift
//  TheEhenTool
//
//  Created by CMonk on 1/7/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PreviewService: QueryService {
    
    init() {
        super.init(DefaultEntityName: "PreviewBookInfo")
    }
    
    static let sharedPreviewService = PreviewService()
}
