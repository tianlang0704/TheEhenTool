//
//  File.swift
//  TheEhenTool
//
//  Created by CMonk on 1/23/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SearchService: QueryService {
    typealias defaultEntity = SearchBookInfoEntity
    var currentSearchString: String = ""
    
    
    init() {
        super.init(DefaultEntityName: defaultEntity.entity().name!)
    }
    
    override func FetchData(
        WithSearchString searchString: String? = nil,
        Page page: Int? = nil,
        ConfigOverride configOverride: ConfigurationHelper? = nil
    ) {
        if let validSearchString = searchString {
            self.currentSearchString = validSearchString
        }
        super.FetchData(
            WithSearchString: self.currentSearchString,
            Page: page,
            ConfigOverride: configOverride)
    }
    
    static let sharedSearchService = SearchService()
}
