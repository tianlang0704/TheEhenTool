//
//  PlayViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

class PlayViewController: UIViewController {
    //Types
    enum PlayError: Error {
        case ErrorOutOfPageRange
        case InvalidImageData
    }
    
//Mark: Variables
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playScrollView: UIScrollView!
    
    //TODO: Need to move to config
    static var permContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    static var permBookEntityName = "BookInfo"
    static var permPageEntityName = "BookPage"
    
    static var cacheContainer = (UIApplication.shared.delegate as! AppDelegate).cacheContainer
    static var tempBookEntityName = "PlayTempBookInfo"
    static var tempPageEntityName = "PlayTempBookPage"
    
    var isTemp:Bool = false
    var id: Int32? = nil
    
    var container: NSPersistentContainer? = nil
    var context: NSManagedObjectContext? = nil
    var pageEntityName: String? = nil
    var bookEntityName: String? = nil
    var bookService: BookService? = nil
    var downloadService: DownloadService? = nil
    
    internal var totalPageNumber: Int = 0
    internal var playResultsController: NSFetchedResultsController<NSManagedObject>!
    internal var _currentPageIndex: Int = 0
    internal var currentPageIndex: Int {
        set(value) {
            guard value >= 0, value < self.totalPageNumber else { print("PlayViewControl: Invalid index value"); return }
            self._currentPageIndex = value
        }
        get {
            return self._currentPageIndex
        }
    }
//End: Variables
    
//Mark: Overloads & Initializations
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.InitializeScrollView()
        self.InitializeGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.InitializeFetchedResultsController()
        self.UpdatePageInfo()
        try? self.GotoPage(pageIndex: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard self.isTemp else { return }
        guard let validId = self.id else { print("PlayViewController: Invalid book id"); return }
        guard let validBookService = self.bookService else { print("PlayViewController: Invalid bookService when is temp view"); return }
        validBookService.RemoveBook(WithId: validId)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitializeScrollView() {
        self.playScrollView.delegate = self
    }
    
    func InitializeFetchedResultsController() {
        guard let validEntityName = self.pageEntityName else { print("PlayViewController: Invalid entity name"); return }
        guard let validContext = self.context else { print("PlayViewController: Invalid context"); return }
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: validEntityName)
        request.predicate = NSPredicate(format: "bookId == \(self.id!) && isBookPageDownloaded == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "bookPageIndex", ascending: true)]
        self.playResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: validContext, sectionNameKeyPath: nil, cacheName: nil)
        self.playResultsController.delegate = self
        do { try self.playResultsController.performFetch() } catch { print(error) }
    }
//End: Overloads & Initializations
    
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
        guard let validImageData = self.playResultsController.fetchedObjects?[pageIndex].value(forKey: "bookPageData") as? Data else { throw PlayError.InvalidImageData }
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
    
//Mark: Static functions
    static func ShowTemp(
        InParentViewController parentVC: UIViewController,
        BookURL urlString: String,
        BookId bookId: Int32
    ) {
        guard let playVC = PlayViewController.InitFromStoryboard(WithName: "Main", Identifier: "PlayViewController") else { print("BookViewController.ViewInvoked: Error initiating playViewController"); return }
        playVC.isTemp = true
        playVC.bookService = BookService(DefaultContext: PlayViewController.cacheContainer.newBackgroundContext(), DefaultEntityName: PlayViewController.tempBookEntityName)
        playVC.downloadService = DownloadService(DefaultContainer: PlayViewController.cacheContainer, DefaultEntityName: PlayViewController.tempPageEntityName, DefaultBookService: playVC.bookService)
        playVC.bookService!.defaultDownloadService = playVC.downloadService!

        parentVC.view.ShowActivityIndicator()
        playVC.bookService!.PromiseToFetchData(WithBookURL: urlString)
        .then { () -> Void in
            playVC.modalPresentationStyle = .fullScreen
            playVC.modalTransitionStyle = .coverVertical
            playVC.context = PlayViewController.cacheContainer.viewContext
            playVC.pageEntityName = PlayViewController.tempPageEntityName
            playVC.id = bookId
            parentVC.present(playVC, animated: true)
        }.always{
            parentVC.view.RemoveActivityIndicator()
        }.catch { error in
            print("PlayViewController.ShowTemp:\(error)")
        }
    }
    
    static func Show(
        InParentViewController parentVC: UIViewController,
        BookId bookId: Int32
    ) {
        guard let playVC = PlayViewController.InitFromStoryboard(WithName: "Main", Identifier: "PlayViewController") else { print("BookViewController.ViewInvoked: Error initiating playViewController"); return }
        playVC.modalPresentationStyle = .fullScreen
        playVC.modalTransitionStyle = .coverVertical
        playVC.context = PlayViewController.permContext
        playVC.pageEntityName = PlayViewController.permPageEntityName
        playVC.id = bookId
        parentVC.present(playVC, animated: true)
    }
//End: Static functions
}

//Mark: NSFetchedResultsControllerDelegate
extension PlayViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.UpdatePageInfo()
        if self.totalPageNumber <= 1{
            try? self.GotoPage(pageIndex: 0)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            print("Play Section insert")
        case .delete:
            print("Play Section delete")
        case .move:
            print("Play Section move")
        case .update:
            print("Play Section update")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("PlayView: ")
        switch type {
        case .insert:
            print("Play Object insert")
        case .delete:
            print("Play Object delete")
        case .move:
            print("Play Object move")
        case .update:
            print("Play Object update")
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
