//
//  DownloadViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import CoreData
import UIKit

class DownloadViewController: UIViewController {
    @IBOutlet weak var downloadTableView: UITableView!
    
    var downloadService = DownloadService.sharedDownloadService
    var downloadResultsController: NSFetchedResultsController<BookInfoEntity>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.InitializeFetchedResultsController()
        self.InitializeTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BookService.sharedBookService.UpdateDownloadProgressForAll()
        self.downloadService.StartToUpdateDownloadProgress(EveryXSeconds: 2)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.downloadService.StopUpdatingDownloadProgress()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitializeTableView() {
        let nib = UINib(nibName: "TableProgressCellStyle", bundle: nil)
        self.downloadTableView.register(nib, forCellReuseIdentifier: "TableProgressCellStyle")
    }
    
    func InitializeFetchedResultsController() {
        let appDele: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let request: NSFetchRequest = BookInfoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isBookDownloadComplete == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "bookAddDate", ascending: false)]
        //request.predicate = NSPredicate(format: "isBookDownloading == YES")
        self.downloadResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: appDele.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.downloadResultsController.delegate = self
        do { try self.downloadResultsController.performFetch() } catch { print(error) }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

//Mark: NSFetchedResultsControllerDelegate
extension DownloadViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.downloadTableView.reloadData()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            print("Section insert")
        case .delete:
            print("Section delete")
        case .move:
            print("Section move")
        case .update:
            print("Section update")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("Object insert")
        case .delete:
            print("Object delete")
        case .move:
            print("Object move")
        case .update:
            print("Object update")
        }
    }
}
//End: NSFetchedResultsControllerDelegate

//Mark: UICollectionViewDataSource
extension DownloadViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.downloadResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloadResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.ConfigureTableViewCell(tabelView: tableView, indexPath: indexPath)
    }
    
    func ConfigureTableViewCell(tabelView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tabelView.dequeueReusableCell(withIdentifier: "TableProgressCellStyle", for: indexPath) as! TableProgressCellStyle
        guard let bookInfoEntity = downloadResultsController.fetchedObjects?[indexPath.item] else { return cell }
        
        
        cell.title.text = bookInfoEntity.bookTitle
        if let thumbData = bookInfoEntity.bookThumbData {
            cell.thumb.image = UIImage(data: thumbData as Data)
        }
        cell.percentage.text = String(format:"%.1f%%" , bookInfoEntity.bookDownloadProgress * 100)
        cell.page.text = "\(bookInfoEntity.bookDownloadedPageNumber)/\(bookInfoEntity.bookPageNumber)"
        cell.progress.progress = bookInfoEntity.bookDownloadProgress
        
        return cell
    }
}
//End: UICollectionViewDataSource

//Mark: UITableViewDelegate
extension DownloadViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let bookInfoEntity = downloadResultsController.fetchedObjects?[indexPath.item] else { return }
        if bookInfoEntity.isBookDownloading {
            let _ = DownloadService.sharedDownloadService.StopDownloading(ForId: bookInfoEntity.bookId)
        }else{
            DownloadService.sharedDownloadService.PromiseToDownloadPages(ForId: bookInfoEntity.bookId)
            .catch{error in print("DownloadViewController.tableViewDidSelect: \(error)")}
        }
        
    }
}
//End: UITableViewDelegate
