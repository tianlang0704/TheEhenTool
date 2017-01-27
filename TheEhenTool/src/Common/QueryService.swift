//
//  QueryService.swift
//  TheEhenTool
//
//  Created by CMonk on 1/23/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Alamofire

protocol QueryServiceDelegate {
    func QueryServiceStartingToFetchData(WithService service: ServiceBase)
    func QueryServiceFinishedFetchingData(WithService service: ServiceBase)
}

class QueryService: ServiceBase, XPathParserDelegate {
    var counter = 0
    var page = 0
    var isUpdating = false
    var config = ConfigurationHelper.shared
    var delegate: QueryServiceDelegate? = nil
    
    
    init(
        DefaultEntityName entityName: String,
//        DefaultContainer container: NSPersistentContainer = (UIApplication.shared.delegate as! AppDelegate).cacheContainer,
        DefaultContext context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).cacheContainer.newBackgroundContext(),
        config: ConfigurationHelper = ConfigurationHelper.shared
    ) {
        //        typealias ParseItemConfig = (
        //            Source: String?,
        //            SourceType: SourceType,
        //            SourceModifier: String?,
        //            ConversionType: ConversionType,
        //            DefaultValue: Any?,
        //            IsUpdateMatcher: Bool?
        //        )
        self.config = config
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["title"] = (Source: self.config.previewTitleXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["hrefURL"] = (Source: self.config.previewHrefXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["thumbURL"] = (Source: self.config.previewThumbXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["id"] = (Source: self.config.previewIdXPath, SourceType: .XPath, SourceModifier: self.config.previewIdRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["thumbImageData"] = (Source: self.config.previewThumbXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.URLToDownloadData, DefaultValue: nil, IsUpdateMatcher: nil)
        super.init(
//            DefaultContainer: container,
            DefaultContext:  context,
            DefaultEntityName: entityName,
            DefaultListXPath: self.config.previewListXPath,
            DefaultQueryURLString: nil,
            DefaultParseConfig: parseConfig)
        
        self.parserDelegate = self
    }
    
//Mark: Public interfaces
    func FetchData(
        WithSearchString searchString: String? = nil,
        Page page: Int? = nil,
        ConfigOverride configOverride: ConfigurationHelper? = nil
    ) {
        guard !self.isUpdating else { print("Preview is still updating"); return }
        self.isUpdating = true
        if let validPage = page {
            self.page = validPage
        }else{
            self.page += 1
        }
        var searchURLString: String = ""
        if let validOverride = configOverride {
            searchURLString = validOverride.GetSearchString(searchWords: searchString ?? "", page: self.page)
        }else{
            searchURLString = self.config.GetSearchString(searchWords: searchString ?? "", page: self.page)
        }
        self.delegate?.QueryServiceStartingToFetchData(WithService: self)
        super.PromiseToFetchData(
            WithAdditionalConfig: nil,
            NewURL: searchURLString
            ).always{
                self.isUpdating = false
                self.delegate?.QueryServiceFinishedFetchingData(WithService: self)
            }.catch { error in
                print("Preview FetchData:\(error)")
        }
    }
    
    func ClearEntity() {
        super.ClearEntity(WithPredicate: nil)
        self.counter = 0
        self.page = 0
    }
    
    func ClearURLCache() {
        URLCache.shared.removeAllCachedResponses()
    }
//End: Public interfaces
    
//Mark: XPathParserDelegate
    func XPathParserBeforeConvertingFilter(RawData data: [[String: String?]]) -> [[String: String?]] {
        return data.filter { item -> Bool in
            guard let hrefValue = item["hrefURL"], hrefValue != nil else { return false }
            guard let idValue = item["id"], idValue != nil else { return false }
            return true
        }
    }
    
    func XPathParserBeforeSavingModifyNewEntityWithKeyValue() -> [String:Any?] {
        self.counter += 1
        return ["order": Int32(self.counter)]
    }
    
    func XPathParserStartingToDownloadData(
        WithUrl url:String,
        Request request: Request){}
    
    func XPathParserDownloadDataCompleted(
        IsSuccess isSuccess: Bool,
        WithUrl url: String,
        Request request: Request) {}
//End: XPathParserDelegate
}
