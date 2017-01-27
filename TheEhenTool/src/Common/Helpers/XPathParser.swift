//
//  XPathListParser.swift
//  TheEhenTool
//
//  Created by CMonk on 1/16/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import PromiseKit
import Kanna
import CoreData

protocol XPathParserDelegate {
    func XPathParserBeforeConvertingFilter(RawData data: [[String: String?]]) -> [[String: String?]]
    func XPathParserBeforeSavingModifyNewEntityWithKeyValue() -> [String:Any?]
    func XPathParserStartingToDownloadData(WithUrl url:String, Request request: Request)
    func XPathParserDownloadDataCompleted(IsSuccess isSuccess: Bool, WithUrl url:String, Request request: Request)
}

class XPathParser: NSObject {
    enum ParseError: Error {
        case ErrorParsingHTML
        case ErrorParsingStringWithRegEx
        case ErrorCapturingStringInRegEx
        case ErrorDownloadingData
        case ErrorCreatingEntityDescription
        case ErrorConvertingStringToInt32
        case ErrorConvertingStringToFloat
        case ErrorEntryToUpdateNotFound
        case ErrorEntryToAddNotFound
        case InvalidRegExString
        case InvalidConfigNoXPath
        case InvalidConfigNoParseType
        case InvalidParseItemName
        case InvalidEntityName
    }
    enum SourceType {
        case XPath
        case String
        //case Predicate //Source modifier becomes target entity name
        
    }
    enum ConversionType {
        case String
        case Int32
        case Float
        case URLToDownloadData
        case AttributeToMatch
        //case PredicateToSetEntity //Source modifier becomes target entity name
    }
    typealias ParseItemConfig = (
        Source: String?,
        SourceType: SourceType,
        SourceModifier: String?,
        ConversionType: ConversionType,
        DefaultValue: String?,
        IsUpdateMatcher: Bool?
    )
    
    var ParseConfig = Dictionary<String, XPathParser.ParseItemConfig>()
    var delegate: XPathParserDelegate? = nil
    var downloadCancelled = false
    
    func AddItemConfig(_ config: ParseItemConfig, ForKey key: String) {
        ParseConfig[key] = config
    }
    
    func PromiseToAppendEntries(
        ToCoreDataEntity entityName: String,
        InMOC moc:NSManagedObjectContext,
        WithItemsInPageWithURL urlString: String
        ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        return XPathParser.PromiseToParseItemsInPage(WithURLString: urlString, ItemConfig: self.ParseConfig)
            .then { data -> Promise<(NSManagedObjectContext, [NSManagedObject])> in
                return self.PromiseToAppendEntries(ToCoreDataEntity: entityName, InMOC: moc, WithData: data)
        }
    }
    
    func PromiseToAppendEntries(
        ToCoreDataEntity entityName: String,
        InMOC moc:NSManagedObjectContext,
        WithItemsInListAtXPath listXPathString: String,
        InPageWithURL urlString: String
    ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        return XPathParser.PromiseToParseListInPage(WithURLString: urlString, ListXPath: listXPathString, ItemConfig: self.ParseConfig)
            .then { data -> Promise<(NSManagedObjectContext, [NSManagedObject])> in
                return self.PromiseToAppendEntries(ToCoreDataEntity: entityName, InMOC: moc, WithData: data)
            }
    }

//    Execution order:
//    0.5, Filter data through delegate before everything else
//    1,   Find entity to update according to update macher in config
//    2,   Convert string to data types and set value in entity
//    2.5  Set additional data through delegate before downloading and saving
//    3,   Download data for .URLToDownloadData
//    4,   Save to core data
    
    func PromiseToAppendEntries(
        ToCoreDataEntity entityName: String,
        InMOC moc:NSManagedObjectContext,
        WithData data: [[String: String?]]
    ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        return Promise { fulfill, reject in
            //filter data
            let validData = self.delegate?.XPathParserBeforeConvertingFilter(RawData: data) ?? data
            //Convert value according to config and update core data
            
            moc.perform {
                var downloadPromises = [Promise<(NSManagedObject, NSManagedObjectContext, String, Data)>]()
                var resultEntries = [NSManagedObject]()
                for entry in validData {
                    //Generate predicate string and get entity to update or insert
                    var newEntity: NSManagedObject
                    var predStr = "", count = 0
                    for (propName, propConfig) in self.ParseConfig {
                        guard let validIsUpdateMatcher = propConfig.IsUpdateMatcher, validIsUpdateMatcher else { continue }
                        guard let propValue = entry[propName], let validValue = propValue else { reject(ParseError.InvalidParseItemName); return }
                        if count > 0 { predStr += " && " }
                        count += 1
                        if propConfig.ConversionType == .String {
                            predStr += "\(propName) == '\(validValue)'"
                        }else{
                            predStr += "\(propName) == \(validValue)"
                        }
                    }
                    if predStr != "" {
                        let req = NSFetchRequest<NSManagedObject>(entityName: entityName)
                        req.predicate = NSPredicate(format: predStr)
                        var results: [NSManagedObject] = []
                        do { results = try moc.fetch(req) } catch(let error) { print(error) }
                        if results.count > 0 {
                            newEntity = results[0]
                        }else{
                            reject(ParseError.ErrorEntryToUpdateNotFound); return
                        }
                    }else{
                        guard let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: moc) else { reject(ParseError.ErrorCreatingEntityDescription); return }
                        newEntity = NSManagedObject(entity: entityDesc, insertInto: moc)
                    }

                    //Save each property in config
                    //TODO: Move the convertion to parsing block
                    for (propName, propConfig) in self.ParseConfig {
                        guard let propValue = entry[propName] else { reject(ParseError.InvalidParseItemName); return }
                        if let unwrappedValue = propValue {
                            // convert them and save
                            switch propConfig.ConversionType {
                            case .String:
                                newEntity.setValue(unwrappedValue, forKey: propName)
                            case .URLToDownloadData:
                                downloadPromises.append(self.PromiseToDownloadData(ForEntity: newEntity, InMOC: moc, Key: propName, WithUrl: unwrappedValue))
                            case .Int32:
                                guard let convertedValue = Int32(unwrappedValue) else {print("Convert parsed value to Int32 failed"); continue }
                                newEntity.setValue(convertedValue, forKey: propName)
                            case .Float:
                                guard let convertedValue = Float(unwrappedValue) else {print("Convert parsed value to Float failed"); continue }
                                newEntity.setValue(convertedValue, forKey: propName)
//                            case .PredicateToSetEntity:
//                                guard let validEntityName = propConfig.SourceModifier else { reject(ParseError.InvalidEntityName); return }
//                                let req = NSFetchRequest<NSManagedObject>(entityName: validEntityName)
//                                req.predicate = NSPredicate(format: propConfig.Source ?? "")
//                                var results: [NSManagedObject] = []
//                                do { results = try moc.fetch(req) } catch(let error) { print(error) }
//                                if results.count > 0 {
//                                    results[0].mutableOrderedSetValue(forKey: propName).add(newEntity)
//                                    //newEntity.setValue(results[0], forKey: propName)
//                                }else{
//                                    reject(ParseError.ErrorEntryToAddNotFound); continue
//                                }
                            case .AttributeToMatch:
                                break;
                            }
                        }else{
                            newEntity.setValue(nil, forKey: propName)
                        }
                    }
                    
                    //Save additional information from delegate
                    if let validInfo = self.delegate?.XPathParserBeforeSavingModifyNewEntityWithKeyValue() {
                        for (key, value) in validInfo {
                            newEntity.setValue(value, forKey: key)
                        }
                    }
                    resultEntries.append(newEntity)
                }
                
                //Data downloading section
                //async download data and fill up core data
                when(resolved: downloadPromises).then{ results -> Void in
                    /*:Result<[(NSManagedObject, NSManagedObjectContext, String, Data)]>*/
                    moc.performAndWait{
                        for case let .fulfilled((entity, _, key, data)) in results {
                            entity.setValue(data, forKey: key)
                        }
                    }
                    if moc.hasChanges { do { try moc.save() }catch{ reject(error) } }
                    fulfill((moc, resultEntries))
                }.catch { error in
                    print(error)
                    reject(error)
                }
            }
        }
    }
    
    private func PromiseToDownloadData(
        ForEntity entity: NSManagedObject,
        InMOC moc: NSManagedObjectContext,
        Key key: String,
        WithUrl url:String
    ) -> Promise<(NSManagedObject, NSManagedObjectContext, String, Data)> {
        
        return Promise { fulfill, reject in
            let request = Alamofire.request(url)
            self.delegate?.XPathParserStartingToDownloadData(
                WithUrl: url,
                Request: request
            )
            request.responseData().then { data -> Void in
                fulfill((entity, moc, key, data))
                self.delegate?.XPathParserDownloadDataCompleted(
                    IsSuccess: true,
                    WithUrl: url,
                    Request: request)
            }.catch{ _ in
                reject(ParseError.ErrorDownloadingData)
                self.delegate?.XPathParserDownloadDataCompleted(
                    IsSuccess: false,
                    WithUrl: url,
                    Request: request)
            }
            
        }
    }


// Mark: Static functions
    
    private static var httpsAlamofire: Alamofire.SessionManager = {
        
        // Create the server trust policies
        let serverTrustPolicies: [String: ServerTrustPolicy] = ["g.e-hentai.org": .disableEvaluation]
        
        // Create custom manager
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        let manager = Alamofire.SessionManager(
            configuration: URLSessionConfiguration.default,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
        
        return manager
    }()
    
    static func PromiseToParseItemsInPage(
        WithURLString urlString: String,
        ItemConfig config: Dictionary<String, ParseItemConfig>
    ) -> Promise<[[String: String?]]> {
        return PromiseToParseListInPage(WithURLString: urlString, ListXPath: "/", ItemConfig: config)
    }
    

    
    static func PromiseToParseListInPage(
        WithURLString urlString: String,
        ListXPath xpathString: String,
        ItemConfig config: Dictionary<String, ParseItemConfig>
    ) -> Promise<[[String: String?]]> {
        return httpsAlamofire.request(urlString).responseString().then { html -> [Dictionary<String, String?>] in
            try self.ParseList(InHTML: html, ListXPath: xpathString, ItemConfig: config)
        }
    }
    
    static func ParseList(
        InHTML html: String,
        ListXPath xpathString: String,
        ItemConfig config: Dictionary<String, ParseItemConfig>
    ) throws -> [Dictionary<String, String?>] {
        guard let doc = HTML(html: html, encoding: .utf8) else { return []}
        var result = [Dictionary<String, String?>]()
        
        
        let listToParse = doc.xpath(xpathString)
        for listEntry in listToParse {
            var newResultEntry = Dictionary<String, String?>()
            
            for (itemName, itemConfig) in config{
                var itemValue: String?
                
                switch itemConfig.SourceType {
                case .String/*, .Predicate*/:
                    itemValue = itemConfig.Source
                case .XPath:
                    guard let xpath = itemConfig.Source else { throw ParseError.InvalidConfigNoXPath }
                    let itemNode = listEntry.xpath(xpath).first
                    itemValue = itemNode?.content ?? itemConfig.DefaultValue
                }
                
                if /*itemConfig.SourceType != .Predicate,*/ let regExString = itemConfig.SourceModifier {
                    itemValue = { () -> String? in
                        guard let valueString = itemValue else { return itemConfig.DefaultValue }
                        guard let parsedString = try? self.Parse(String: valueString, WithRegExString: regExString) else { return itemConfig.DefaultValue }
                        return parsedString
                    }()
                }

                newResultEntry[itemName] = itemValue
            }
            
            result.append(newResultEntry)
        }
        return result
    }
    
    static func Parse(String string: String, WithRegExString regExString: String) throws -> String {
        guard let regex = try? NSRegularExpression(pattern: regExString, options: []) else { throw ParseError.InvalidRegExString }
        guard let match = regex.firstMatch(in: string, range: NSRange(location: 0, length: string.characters.count)) else { throw ParseError.ErrorParsingStringWithRegEx }
        guard match.numberOfRanges > 1 else { throw ParseError.ErrorCapturingStringInRegEx }
        let captureRange = match.rangeAt(1)
        return (string as NSString).substring(with: captureRange)
    }
// End: Static functions
}
