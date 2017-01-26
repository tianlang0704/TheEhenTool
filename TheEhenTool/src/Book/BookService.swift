//
//  BookService.swift
//  TheEhenTool
//
//  Created by CMonk on 1/16/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PromiseKit

class BookService: ServiceBase, XPathParserDelegate {
    enum BookServiceError: Error {
        case InvalidProgressValue
        case InvalidURLString
        case NoBookURLInCoreData
        case ErrorBookAlreadyExist
        case ErrorCreatingMOC
        case ErrorBookIsUpdating
    }
    
    typealias defaultEntity = BookInfoEntity
    
    let config = ConfigurationHelper.shared
    var updatingList = [String]()
    
    init() {
        //        typealias ParseItemConfig = (
        //            Source: String?,
        //            SourceType: SourceType,
        //            SourceModifier: String?,
        //            ConversionType: ConversionType,
        //            DefaultValue: Any?,
        //            IsUpdateMatcher: Bool?
        //        )
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookTitle"] = (Source: self.config.bookTitleXPath, SourceType: .XPath, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["bookPageNumber"] = (Source: self.config.bookPageNumberXPath, SourceType: .XPath, SourceModifier: self.config.bookPageNumberRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["bookThumbData"] = (Source: self.config.bookThumbXPath, SourceType: .XPath, SourceModifier: nil, ConversionType: .URLToDownloadData, DefaultValue: nil, IsUpdateMatcher: nil)
        
        let appDele = UIApplication.shared.delegate as! AppDelegate
        super.init(
            DefaultContainer: appDele.persistentContainer,
            DefaultEntityName: defaultEntity.entity().name!,
            DefaultListXPath: "/",
            DefaultQueryURLString: nil,
            DefaultParseConfig: parseConfig
        )
        self.parserDelegate = self
    }
    
    func FetchData(WithBookURL urlString: String) throws {
        guard let isBookExist = try? self.IsBookExistInEntity(BookURL: urlString), !isBookExist else { throw BookServiceError.ErrorBookAlreadyExist }
        guard self.updatingList.index(of: urlString) == nil else { throw BookServiceError.ErrorBookIsUpdating }
        self.updatingList.append(urlString)
        
        var parseConfig: [String: XPathParser.ParseItemConfig] = [:]
        parseConfig["bookURL"] = (Source: urlString, SourceType: .String, SourceModifier: nil, ConversionType:.String, DefaultValue: nil, IsUpdateMatcher: nil)
        parseConfig["bookId"] = (Source: urlString, SourceType: .String, SourceModifier: self.config.bookIdRegEx, ConversionType:.Int32, DefaultValue: nil, IsUpdateMatcher: nil)
        
        
        super.PromiseToFetchData(WithAdditionalConfig: parseConfig, NewURL: urlString)
        .then { moc, entries -> Void in
            guard entries.count > 0 else { return }
            var bookURL: String? = nil
            moc.performAndWait { bookURL = entries[0].value(forKey: "bookURL") as! String? }
            guard let validBookURL = bookURL else { return }
            try? DownloadService.sharedDownloadService.FetchData(WithBookURL: validBookURL)
            //TODO: need check and show message
        }.always{
            guard let index = self.updatingList.index(of: urlString) else { return }
            self.updatingList.remove(at: index)
        }.catch{ error in
            print("BookService FetchData: \(error)")
        }
    }

    
//Mark: Helper functions
    func UpdateBookInfo(ForId id: Int32, WithAttributes attributes: [String: Any]) {
        let moc = self.defaultMOC
        moc.performAndWait {
            let req:NSFetchRequest = BookService.defaultEntity.fetchRequest()
            req.predicate = NSPredicate(format:"bookId == \(id)")
            guard let books = try? moc.fetch(req) else { print("UpdateInfo invalid id"); return }
            for book in books {
                book.setValuesForKeys(attributes)
            }
            if moc.hasChanges { do { try moc.save() } catch let error { print(error) } }
        }
    }
    
    func PromiseToDeleteBook(WithId id: Int32) -> Promise<Int32> {
        return DownloadService.sharedDownloadService.PromiseToDeletePages(WithBookId: id)
        .then{ _ in
            Promise {fulfill, reject in
                self.ClearEntity(WithPredicate: "bookId == \(id)")
                fulfill(id)
            }
        }
    }
    
    func UpdateDownloadProgressForAll() {
        let moc = self.defaultMOC
        moc.perform {
            let req:NSFetchRequest = BookService.defaultEntity.fetchRequest()
            guard let downloadingBooks = try? moc.fetch(req) else { return }
            for book in downloadingBooks {
                let downloadedPageNum = DownloadService.sharedDownloadService.CountPageNumberFor(ForBookId: book.bookId, WithPredicate: "isBookPageDownloaded == YES")
                book.bookDownloadedPageNumber = Int32(downloadedPageNum)
                book.bookDownloadProgress = Float(downloadedPageNum) / Float(book.bookPageNumber)
                
                let totalPageNumber = DownloadService.sharedDownloadService.CountPageNumberFor(ForBookId: book.bookId)
                let leftPageNum = DownloadService.sharedDownloadService.CountPageNumberFor(ForBookId: book.bookId, WithPredicate: "isBookPageDownloaded == NO")
                if totalPageNumber > 0 && leftPageNum == 0 {
                    book.isBookDownloadComplete = true
                }
            }
            if moc.hasChanges { do { try moc.save() } catch let error { print("Update progress for all: \(error)") } }
        }
    }
    
    func IsBookExistInEntity(BookURL urlString: String) throws -> Bool {
        guard let id = try Int(XPathParser.Parse(String: urlString, WithRegExString: self.config.previewIdRegEx)) else { throw BookServiceError.InvalidURLString }
        return try self.IsBookExistInEntity(BookId: id)
    }
    
    func IsBookExistInEntity(BookId id: Int) throws -> Bool {
        let moc = self.defaultMOC
        var resultNum = 0
        let req:NSFetchRequest = BookInfoEntity.fetchRequest()
        let pred = NSPredicate(format: "bookId == \(id)")
        req.predicate = pred
        moc.performAndWait { do { resultNum = try moc.count(for: req) } catch(let error) { print(error) } }
        return resultNum > 0
    }
//End: Helper functions
    
//Mark: XPathParserDelegate
    func XPathParserBeforeConvertingFilter(RawData data: [[String: String?]]) -> [[String: String?]] {
        return data.filter { item -> Bool in
            guard let hrefValue = item["bookURL"], hrefValue != nil else { return false }
            return true
        }
    }

    internal func XPathParserBeforeSavingModifyNewEntityWithKeyValue() -> [String:Any?] {
        return ["bookAddDate": NSDate()]
    }
    
    func XPathParserStartingToDownloadData(
        WithUrl url:String,
        Request request: Request){}
    
    func XPathParserDownloadDataCompleted(
        IsSuccess isSuccess: Bool,
        WithUrl url: String,
        Request request: Request) {}
//End: XPathParserDelegate
    
    static let sharedBookService = BookService()
}
