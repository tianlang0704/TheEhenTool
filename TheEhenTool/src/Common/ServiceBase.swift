//
//  ServiceBase.swift
//  TheEhenTool
//
//  Created by CMonk on 1/17/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

class ServiceBase {
    enum ServiceBaseError: Error {
        case InvalidParseConfig
        case InvalidParseURL
    }
    
    var defaultContainer: NSPersistentContainer
    var defaultMOC: NSManagedObjectContext
    var defaultEntityName: String
    var defaultListXPath: String
    var defaultParseConfig: [String: XPathParser.ParseItemConfig]? = nil
    var defaultQueryURLString: String? = nil
    var parserDelegate: XPathParserDelegate? = nil
    
//Mark: Public interfaces
    init(
        DefaultContainer container: NSPersistentContainer,
        DefaultEntityName en: String,
        DefaultListXPath lp: String,
        DefaultQueryURLString qurls: String? = nil,
        DefaultParseConfig pc: [String: XPathParser.ParseItemConfig]? = nil
    ){
        self.defaultContainer = container
        self.defaultMOC = container.newBackgroundContext()
        self.defaultEntityName = en
        self.defaultListXPath = lp
        self.defaultQueryURLString = qurls
        self.defaultParseConfig = pc
    }
    
    func PromiseToClearEntity(WithPredicate predString: String? = nil) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.ClearEntity(WithPredicate: predString)
            fulfill()
        }
    }
    
    func ClearEntity(WithPredicate predString: String? = nil) {        
        let moc = self.defaultMOC
        moc.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: self.defaultEntityName)
            if let validPredString = predString {
                req.predicate = NSPredicate(format: validPredString)
            }
            var objectsToDelete = [NSManagedObject]()
            do { objectsToDelete = try moc.fetch(req) } catch let error { print("ServiceBase.ClearEntity: \(error)") }
            for object in objectsToDelete {
                moc.delete(object)
            }
            if moc.hasChanges { do { try moc.save() } catch { print(error) } }
        }
    }
    
    func PromiseToFetchData(
        WithAdditionalConfig addConfig: [String: XPathParser.ParseItemConfig]?,
        NewURL newURLString: String?
    ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        return Promise<(XPathParser, String)> { fulfill, reject in
            //sanity check
            guard (self.defaultParseConfig != nil) || (addConfig != nil) else { throw ServiceBaseError.InvalidParseConfig }
            var validQueryURLString: String
            if newURLString == nil {
                guard let checkDefaultURLString = self.defaultQueryURLString else { throw ServiceBaseError.InvalidParseURL }
                validQueryURLString = checkDefaultURLString
            }else{
                validQueryURLString = newURLString!
            }
            
            //configure parser with additional data
            let parser = XPathParser()
            parser.delegate = self.parserDelegate
            if let validConfig = self.defaultParseConfig {
                for (key, config) in validConfig {
                    parser.AddItemConfig(config, ForKey: key)
                }
            }
            if let validConfig = addConfig {
                for (key, config) in validConfig {
                    parser.AddItemConfig(config, ForKey: key)
                }
            }
            //pass on configs to next promise
            fulfill((parser, validQueryURLString))
        }.then { (parser, validQueryURLString) -> Promise<(NSManagedObjectContext, [NSManagedObject])> in
            return parser.PromiseToAppendEntries(
                ToCoreDataEntity: self.defaultEntityName,
                InMOC: self.defaultMOC,
                WithItemsInListAtXPath: self.defaultListXPath,
                InPageWithURL: validQueryURLString
            )
        }
    }
//End: Public interfaces
}
