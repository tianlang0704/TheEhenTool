//
//  PlayViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import CoreData

class PlayViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playScrollView: UIScrollView!
    
    enum PlayError: Error {
        case ErrorOutOfPageRange
        case InvalidImageData
    }
    
    var id: Int32? = nil
    private var _currentPageIndex: Int = 0
    private var currentPageIndex: Int {
        set(value) {
            guard value >= 0, value < self.totalPageNumber else { print("PlayViewControl: Invalid index value"); return }
            self._currentPageIndex = value
        }
        get {
            return self._currentPageIndex
        }
    }
    private var totalPageNumber: Int = 0
    private var playResultsController: NSFetchedResultsController<BookPageEntity>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.InitializeScrollView()
        self.InitializeGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.InitializeFetchedResultsController()
        self.UpdatePageInfo()
        try? self.GotoPage(pageIndex: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitializeScrollView() {
        self.playScrollView.delegate = self
    }
    
    func InitializeFetchedResultsController() {
        let appDele: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let request: NSFetchRequest = BookPageEntity.fetchRequest()
        request.predicate = NSPredicate(format: "bookId == \(self.id!) && isBookPageDownloaded == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "bookPageIndex", ascending: true)]
        self.playResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: appDele.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.playResultsController.delegate = self
        do { try self.playResultsController.performFetch() } catch { print(error) }
    }
    
//Mark: Gesture functions
    func InitializeGestures() {
        let tapGesRec = UITapGestureRecognizer(target: self, action: #selector(self.tapHandler))
        tapGesRec.numberOfTapsRequired = 1
        let swipeDownGesRec = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeHandler))
        swipeDownGesRec.direction = .down
        let swipeLeftGesRec = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeHandler))
        swipeLeftGesRec.direction = .left
        let swipeRightGesRec = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeHandler))
        swipeRightGesRec.direction = .right
        self.playScrollView.addGestureRecognizer(tapGesRec)
        self.playScrollView.addGestureRecognizer(swipeDownGesRec)
        self.playScrollView.addGestureRecognizer(swipeRightGesRec)
        self.playScrollView.addGestureRecognizer(swipeLeftGesRec)

    }
    
    func tapHandler(sender: UITapGestureRecognizer) {
        let view = sender.view
        guard let viewWidth = sender.view?.bounds.width else { print("Invalid view width from gesture recognizer"); return }
        let location = sender.location(in: view)
        if(location.x < viewWidth / 2) {
            self.NextPage()
        }else{
            self.PrevPage()
        }
    }
    
    func doubleTapHandler(sender: UITapGestureRecognizer) {
        if self.playScrollView.zoomScale == 1.0 {
            self.playScrollView.zoomScale = 2.0
        }else{
            self.playScrollView.zoomScale = 1.0
        }
    }
    
    func swipeHandler(sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.down:
            self.dismiss(animated: true)
        case UISwipeGestureRecognizerDirection.left:
            self.PrevPage()
        case UISwipeGestureRecognizerDirection.right:
            self.NextPage()
        default: break
        }
        
    }
    
//End: Gesture functions
    
//Mark: Pages functions
    func UpdatePageInfo() {
        guard let validPageCount = self.playResultsController.fetchedObjects?.count else { print("PlayViewController: Invalid fetch results"); return }
        self.totalPageNumber = validPageCount
    }
    
    func GotoPage(pageIndex: Int) throws {
        guard pageIndex < self.totalPageNumber, pageIndex >= 0 else { throw PlayError.ErrorOutOfPageRange }
        guard let validImageData = self.playResultsController.fetchedObjects?[pageIndex].bookPageData as? Data else { throw PlayError.InvalidImageData }
        let copyData = Data(validImageData)
        self.imageView.image = UIImage(data: copyData)
        self.currentPageIndex = pageIndex
    }
    
    func NextPage() {
        try? GotoPage(pageIndex: self.currentPageIndex + 1)
        //TODO: check and show message
    }
    
    func PrevPage() {
        try? GotoPage(pageIndex: self.currentPageIndex - 1)
        //TODO: check and show message
    }
    
//End: Page funtions
    
//Mark:

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
extension PlayViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.UpdatePageInfo()
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
        print("PlayView: ")
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

extension PlayViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
        
        scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, 0, 0);
    }
}

extension PlayViewController {
    static func InitFromStoryboard(WithName sb: String, Identifier id: String) -> PlayViewController? {
        let storyboard = UIStoryboard(name: sb, bundle: nil)
        guard let playVC = storyboard.instantiateViewController(withIdentifier: "PlayViewController") as? PlayViewController else { print("Error initiating PlayViewController from storyboard"); return nil }
        return playVC
    }
    
}
