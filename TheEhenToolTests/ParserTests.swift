//
//  DownloadServiceTests.swift
//  TheEhenTool
//
//  Created by CMonk on 1/16/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import XCTest

class ParserTests: XCTestCase {
    
    let testURL = "http://g.e-hentai.org/g/1018469/a58cd30074/"
    let testXPath = "//*[@id=\"gn\"]"
    var ParseConfig = Dictionary<String, XPathParser.ParseItemConfig>()

    override func setUp() {
        self.ParseConfig["title"] = (XPath: testXPath,
                                     ParseType:.Content,
                                     ValueType:.String,
                                     AttributeName:nil,
                                     DefaultValue:nil,
                                     RegEx: nil)
    }
    
    override func tearDown() {
        
    }
    
    func testParse() {

    }
}
