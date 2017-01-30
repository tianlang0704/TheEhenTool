//
//  File.swift
//  TheEhenTool
//
//  Created by CMonk on 1/21/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

//Mark: Download worker class
class SyncBookDownloadWorker {
    enum WorkerError: Error {
        case InvalidBookId
        case InvalidXPath
        case InvalidKeyName
        case ErrorStopped
    }
    
    private var bookId: Int32
    private var moc: NSManagedObjectContext
    private var dataEntityName: String
    private var dataKey: String
    private var downloadService: DownloadService
    var currentManager: Alamofire.SessionManager
    var currentRequest: DataRequest? = nil
    var workItem: DispatchWorkItem? = nil
    private var stop = false
    
    init(
        downloadService: DownloadService,
        bookId: Int32,
        moc: NSManagedObjectContext,
        dataEntityName: String,
        dataKey: String
        ) {
        self.bookId = bookId
        self.moc = moc
        self.dataEntityName = dataEntityName
        self.dataKey = dataKey
        self.downloadService = downloadService
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 12
        self.currentManager = Alamofire.SessionManager(configuration: config)
    }
    
    func PromiseToStartWorker() -> Promise<Int32> {
        return Promise { fulfill, reject in
//            let q = DispatchQueue(
//                label: DownloadService.downloadQueueName,
//                qos: .background,
//                attributes: DispatchQueue.Attributes.concurrent)
            self.workItem = DispatchWorkItem {
                self.stop = false
                let downloadList = self.downloadService.GetPageList(
                    ForBookId: self.bookId,
                    WithPredicate: "isBookPageDownloaded == NO")
                let mutex = PThreadMutex()
                var downloadConfig = Dictionary<String, XPathParser.ParseItemConfig>()
                downloadConfig["imgURLToDownload"] = (
                    Source: ConfigurationHelper.shared.Page2ndHrefXPath,
                    SourceType: .XPath,
                    SourceModifier: nil,
                    ConversionType:.String,
                    DefaultValue: nil,
                    IsUpdateMatcher: nil)
                
                let moc = self.moc
                for attributes in downloadList {
                    guard !self.stop else { reject(WorkerError.ErrorStopped); return }
                    let url = attributes["bookPageURL"] as? String
                    guard let validURL = url else { continue }
                    
                    mutex.unbalancedLock()
                    //TODO: Maybe change it to XPathParser.PromiseToParseItem
                    Alamofire.request(validURL).responseString().then { html -> Promise<Data> in
                        let res = try XPathParser.ParseList(InHTML: html, ListXPath: "/", ItemConfig: downloadConfig)
                        guard res.count > 0 else { throw WorkerError.InvalidXPath }
                        guard let imageURL = res[0]["imgURLToDownload"], let validImageURL = imageURL else { throw WorkerError.InvalidKeyName }
                        self.currentRequest = self.currentManager.request(validImageURL)
//                        self.currentRequest = Alamofire.request(validImageURL)
                        guard !self.stop else { reject(WorkerError.ErrorStopped); return Promise<Data>(value: Data()) }
                        return self.currentRequest!.responseData()
                    }.then{ data -> Void in
                        guard !data.isEmpty else { return }
                        guard !self.stop else { reject(WorkerError.ErrorStopped); return }
                        moc.performAndWait {
                            let req: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: self.dataEntityName)
                            req.predicate = NSPredicate(format: "bookPageURL == '\(validURL)'")
                            var targetPages: [NSManagedObject]
                            do { targetPages = try moc.fetch(req) } catch let error { print(error); return }
                            guard targetPages.count == 1 else { print("Error target page not found or more than one found."); return }
                            let targetPage = targetPages[0]
                            targetPage.setValue(data, forKey: self.dataKey)
                            targetPage.setValue(true, forKey: "isBookPageDownloaded")
                            do { try moc.save() } catch let error { print(error); return }
                        }
                    }.always {
                        mutex.unbalancedUnlock()
                    }.catch { error in
                        print(error)
                        reject(error)
                    }
                }
                fulfill(self.bookId)
            }
            let dq = DispatchQueue(label: DownloadService.downloadQueueName)
            dq.async(execute: self.workItem!)
        }
    }
    
    func Stop() {
        self.stop = true
        self.currentRequest?.cancel()
    }
}
