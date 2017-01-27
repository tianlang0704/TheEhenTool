//
//  DownloadService.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PromiseKit

class DownloadService: ServiceBase, XPathParserDelegate {
    enum DownloadServiceError: Error {
        case FailedCreatingMOC
        case InvalidURLString
        case InvalidBookId
        case InvalidSectionNumber
        case InvalidSectionXPath
    }
    
    let config = ConfigurationHelper.shared
    var timer: Timer? = nil
    var workers = [Int32: SyncBookDownloadWorker]()
    var defaultContainer: NSPersistentContainer
    lazy var defaultBookService: BookService = BookService.sharedBookService
    
    init(
        DefaultContainer container: NSPersistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer,
        DefaultEntityName entityName: String = "BookPage",
        DefaultBookService bookService: BookService? = nil
    ) {
        self.defaultContainer = container
        //        typealias ParseItemConfig = (
        //            Source: String?,
        //            SourceType: SourceType,
        //            SourceModifier: String?,
        //            ConversionType: ConversionType,
        //            DefaultValue: Any?,
        //            IsUpdateMatcher: Bool?
        //        )
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookPageURL"] = (Source: self.config.pageHrefXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["bookPageIndex"] = (Source: self.config.pageNumberXPath, SourceType: .XPath, SourceModifier: self.config.pageNumberRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        
        super.init(
//            DefaultContainer: container,
            DefaultContext: container.newBackgroundContext(),
            DefaultEntityName: entityName,
            DefaultListXPath: self.config.pageListXPath,
            DefaultQueryURLString: nil,
            DefaultParseConfig: parseConfig
        )
        
        if let validServiceOverride = bookService {
            self.defaultBookService = validServiceOverride
        }
        self.parserDelegate = self
    }
    
    deinit {
        self.StopUpdatingDownloadProgress()
    }
//Mark: Helper functions
    //returns [Attributes]
    func GetPageList(
        ForBookId id: Int32,
        WithPredicate predString: String? = nil,
        Sort sortDesc: [NSSortDescriptor] = [NSSortDescriptor(key: "bookPageIndex", ascending: true)]
        ) -> [[String: Any]] {
        var list = [[String: Any]]()
        let moc = self.defaultContainer.newBackgroundContext()
        moc.performAndWait {
            let req: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: self.defaultEntityName)
            var combinedPredString = "bookId == \(id)"
            if let validAddPredString = predString {
                combinedPredString += " && " + validAddPredString
            }
            req.predicate = NSPredicate(format: combinedPredString)
            req.sortDescriptors = sortDesc
            var results = [NSManagedObject]()
            do { results = try moc.fetch(req) } catch let error { print(error) }
            for result in results {
                let allKeys = Array(result.entity.attributesByName.keys)
                let keyValues = result.dictionaryWithValues(forKeys: allKeys)
                list.append(keyValues)
            }
        }
        return list
    }
    
    func CountPageNumberFor(
        ForBookId id: Int32,
        WithPredicate predString: String? = nil
    ) -> Int {
        var count = 0
        let moc = self.defaultContainer.newBackgroundContext()
        moc.performAndWait {
            let req: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: self.defaultEntityName)
            var combinedPredString = "bookId == \(id)"
            if let validAddPredString = predString {
                combinedPredString += " && " + validAddPredString
            }
            req.predicate = NSPredicate(format: combinedPredString)
            do { count = try moc.count(for: req) } catch let error { print(error) }
        }
        return count
    }
    
    func IsPagesDownloading(ForBookId id: Int32) -> Bool {
        return self.workers[id] != nil
    }
    
    func PromiseToDeletePages(WithBookId id: Int32) -> Promise<Int32> {
        return Promise {fulfill, reject in
            if self.IsPagesDownloading(ForBookId: id) { self.StopDownloading(ForId: id) }
            self.ClearEntity(WithPredicate: "bookId == \(id)")
            fulfill(id)
        }
    }
//End: Helper functions
    
//Mark: Progress functions
    func StartToUpdateDownloadProgress(EveryXSeconds interval: Float) {
        guard self.timer == nil else { print("Timeer already set"); return }
        self.timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(interval),
            repeats: true
        ) { _ in
            self.defaultBookService.UpdateDownloadProgressForAll()
        }
    }
    
    func StopUpdatingDownloadProgress() {
        self.timer?.invalidate()
        self.timer = nil
    }
//End: Progress functions

//Mark: Download functions
    
    func PromiseToGetSectionNumber(WithBookURL urlString: String) -> Promise<[[String: String?]]> {
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookSectionNumber"] = (Source: self.config.bookSectionNumberXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        
        return XPathParser.PromiseToParseItemsInPage(
            WithURLString: urlString,
            ItemConfig: parseConfig)
    }
    
    func PromiseToFetchPageInfoForEverySection(
        WithBookUrl urlString: String
    ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        //Parse section number and promise to fetch page data from every section
        return self.PromiseToGetSectionNumber(WithBookURL: urlString)
        .then {resultList /*:[[String: String?]]*/ -> Promise<(NSManagedObjectContext, [NSManagedObject])> in
            guard resultList.count > 0 else { throw DownloadServiceError.InvalidURLString }
            guard let sectionString = resultList[0]["bookSectionNumber"], let validSectionString = sectionString else { throw DownloadServiceError.InvalidSectionXPath }
            guard let sectionNum = Int(validSectionString) else { throw DownloadServiceError.InvalidSectionNumber }
            var sectionPromises: Promise<(NSManagedObjectContext, [NSManagedObject])> = self.PromiseToFetchPageInfo(WithBookURL: urlString, ForSection: 0)
            for currentSection in 1..<sectionNum {
                sectionPromises = sectionPromises.then{_,_ in return self.PromiseToFetchPageInfo(WithBookURL: urlString, ForSection: currentSection)}
            }
            return sectionPromises
        }
    }
    
    func PromiseToFetchPageInfo(
        WithBookURL urlString: String,
        ForSection section: Int
    ) -> Promise<(NSManagedObjectContext, [NSManagedObject])> {
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookId"] = (Source: urlString, SourceType: .String, SourceModifier: self.config.bookIdRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        
        let urlWithSection = urlString + "?p=\(section)"
        return super.PromiseToFetchData(
            WithAdditionalConfig: parseConfig,
            NewURL: urlWithSection
        )
    }
    
    func PromiseToDownloadPages(ForId id: Int32) -> Promise<Void> {
        guard !self.IsPagesDownloading(ForBookId: id) else { return Promise<()>(value: ()) }
        let newWorker = SyncBookDownloadWorker(
            downloadService: self,
            bookId: Int32(id),
            moc: self.defaultMOC,
            dataEntityName: self.defaultEntityName,
            dataKey: "bookPageData")
        self.workers[Int32(id)] = newWorker
        self.defaultBookService.UpdateBookInfo(ForId: id, WithAttributes: ["isBookDownloading": true])
        return Promise { fulfill, reject in
            newWorker.PromiseToStartWorker()
            .always {
                self.defaultBookService.UpdateBookInfo(ForId: id, WithAttributes: ["isBookDownloading":false])
                self.workers.removeValue(forKey: id)
                fulfill()
            }.catch{ error in
                reject(error)
            }
        }
    }
    
    @discardableResult
    func StopDownloading(ForId id: Int32) {
        guard let worker = self.workers[id] else {
            print("Error stopping download for id not found");
            self.defaultBookService.UpdateBookInfo(ForId: id, WithAttributes: ["isBookDownloading": false])
            return
        }
        worker.Stop()
    }
    
    func StopDownloadingForAll() {
        self.workers.forEach {
            self.StopDownloading(ForId: $0.key)
        }
    }
    
//End: Download functions
    
//Mark: Overrides & variants
    func FetchData(WithBookURL urlString: String) throws {
        guard let idString = try? XPathParser.Parse(String: urlString, WithRegExString: ConfigurationHelper.shared.bookIdRegEx) else { throw DownloadServiceError.InvalidURLString }
        guard let bookId = Int(idString) else { throw DownloadServiceError.InvalidBookId }
        guard let checkBookExist = try? self.defaultBookService.IsBookExistInEntity(BookId: bookId), checkBookExist else { return }
        
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookId"] = (Source: urlString, SourceType: .String, SourceModifier: self.config.bookIdRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        
        self.PromiseToFetchPageInfoForEverySection(WithBookUrl: urlString)
        .then { _ -> Promise<Void> in
            return self.PromiseToDownloadPages(ForId: Int32(bookId))
        }.catch { error in
            print(error)
        }
    }
//End: Overrides & variants
    
//Mark: XPathParserDelegate
    func XPathParserBeforeConvertingFilter(RawData data: [[String: String?]]) -> [[String: String?]] {
        return data.filter { item -> Bool in
            guard let urlString = item["bookPageURL"], urlString != nil else { return false }
            guard let idString = item["bookId"], idString != nil else { return false }
            return true
        }
    }
    
    func XPathParserBeforeSavingModifyNewEntityWithKeyValue() -> [String:Any?] { return [:] }
    
    func XPathParserStartingToDownloadData(
        WithUrl url:String,
        Request request: Request) {}
    
    func XPathParserDownloadDataCompleted(
        IsSuccess isSuccess: Bool,
        WithUrl url: String,
        Request request: Request) {}
//End: XPathParserDelegate
    
    static let sharedDownloadService = DownloadService()
    static let downloadQueueName = "DownloadServiceQueue"
    static let defaultDownloadQueue = DispatchQueue(label: DownloadService.downloadQueueName)
}
