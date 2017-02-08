//
//  SearchViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class SearchViewController: UIViewController {
    @IBOutlet weak var searchCollectionView: UICollectionView!
    @IBOutlet weak var layoutConstraintLargeViewHeight: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintLargeViewHeightLoPrio: NSLayoutConstraint!
    @IBOutlet weak var largeSearchView: UIView!
    @IBOutlet weak var largeTitleLabel: UILabel!
    @IBOutlet weak var largeSearchImage: UIImageView!
    @IBOutlet weak var searchInputView: SearchInputView!
    
    let localConfig = ConfigurationHelper()
    let globalConfig = ConfigurationHelper.shared
    var searchService = SearchService.sharedSearchService
    var searchResultsController: NSFetchedResultsController<SearchBookInfoEntity>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.InitializeView()
        self.InitializeComponentSubviews()
        self.InitializeObservers()
        self.InitializeScrollView()
        self.InitializeCollectionView()
        self.InitializeFetchedResultsController()
        self.InitializeService()
        self.searchService.FetchData(WithSearchString: "", Page: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("==========================memory warning")
    }
    
    func InitializeView() {
        if let bgImg = UIImage(named: "bg") {
            self.view.backgroundColor = UIColor(patternImage: bgImg);
        }
    }
    
    func InitializeService() {
        self.searchService.delegate = self
    }

    func InitializeObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func InitializeComponentSubviews() {
        self.searchInputView = self.searchInputView.fromNib()
        self.searchInputView.endEditingTapGestureTarget = self.searchCollectionView
        self.searchInputView.delegate = self
    }
    
    func InitializeScrollView() {
        (self.searchCollectionView as UIScrollView).delegate = self
        (self.searchCollectionView as UIScrollView).scrollIndicatorInsets =
            UIEdgeInsets(top: 65, left: 0, bottom: 0, right: 0)
    }
    
    func InitializeCollectionView() {
        let cellNIB = UINib(nibName: "CollectionToggleTitleCellStyle", bundle: nil)
        self.searchCollectionView.register(cellNIB, forCellWithReuseIdentifier: "CollectionToggleTitleCellStyle")
        if let layout = self.searchCollectionView.collectionViewLayout as? ColumnCollectionLayout{
            layout.delegate = self
        }
    }
    
    func InitializeFetchedResultsController() {
        let appDele: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let request: NSFetchRequest = SearchBookInfoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        self.searchResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: appDele.cacheContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.searchResultsController.delegate = self
        do { try self.searchResultsController.performFetch() } catch { print(error) }
    }
    
}

//Mark: Notification Handlers
extension SearchViewController {
    func KeyboardWillShow(notification: NSNotification){
        
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
            let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        {
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                var tempFrame = self.view.frame
                tempFrame.size.height -= keyboardHeight
                self.view.frame = tempFrame
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func KeyboardWillHide(notification: NSNotification){
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject>,
            let keyboardHeight = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height,
            let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        {
            UIView.animate(withDuration: animationDuration, animations: { () -> Void in
                var tempFrame = self.view.frame
                tempFrame.size.height += keyboardHeight
                self.view.frame = tempFrame
                self.view.layoutIfNeeded()
            })
        }
    }
}
//ENd: Notification Handlers

//Mark: NSFetchedResultsControllerDelegate
extension SearchViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.searchCollectionView.reloadData()
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
extension SearchViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.searchResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.searchResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.ConfigureCollectionViewCell(collectionView: collectionView, indexPath: indexPath)
    }
    
    func ConfigureCollectionViewCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionToggleTitleCellStyle", for: indexPath) as! CollectionToggleTitleCellStyle
        guard let searchEntity = searchResultsController.fetchedObjects?[indexPath.item] else { return cell }
        
        cell.delegate = self
        cell.title = searchEntity.title
        if let thumbData = searchEntity.thumbImageData {
            cell.thumb = UIImage(data: thumbData as Data)
        }
        
        return cell
    }
}
//End: UICollectionViewDataSource

//Mark: UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionToggleTitleCellStyle
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = self.searchCollectionView.cellForItem(at: indexPath) as! CollectionToggleTitleCellStyle
        self.largeTitleLabel.text = cell.title
        if let image = cell.thumb {
            self.largeSearchImage.image = UIImageHelper.Aspect(Image: image, WithWidth: self.view.frame.width)
        }else{
            self.largeSearchImage.image = cell.thumb
        }
        
        UIView.animate(withDuration: 0.2) {
            self.largeSearchView.removeConstraint(self.layoutConstraintLargeViewHeight)
            self.largeSearchView.addConstraint(self.layoutConstraintLargeViewHeightLoPrio)
            self.view.layoutIfNeeded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.2) {
            self.largeSearchView.removeConstraint(self.layoutConstraintLargeViewHeightLoPrio)
            self.largeSearchView.addConstraint(self.layoutConstraintLargeViewHeight)
            self.view.layoutIfNeeded()
        }
    }
}
//End: UICollectionViewDelegate

//Mark: UIScrollViewDelegate
extension SearchViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let config = self.globalConfig
        let topEdge = scrollView.contentOffset.y
        let bottomEdge = topEdge + scrollView.frame.size.height
        let contentSize = scrollView.contentSize.height
        let scrollLoadOffset = UIDevice.current.orientation.isLandscape
            ? config.ScrollLoadOffsetL : config.ScrollLoadOffsetP
        
        //Bottom - load more
        if(bottomEdge > contentSize + scrollLoadOffset) {
            scrollView.isScrollEnabled = false
            scrollView.setContentOffset(CGPoint(x: 0, y: contentSize - scrollView.frame.size.height), animated: true)
            scrollView.isScrollEnabled = true
            self.searchService.FetchData(WithSearchString: nil, Page: nil, ConfigOverride: self.localConfig)
        }
        
        //Top - reload
        if(topEdge < scrollLoadOffset * -1) {
            scrollView.isScrollEnabled = false
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            scrollView.isScrollEnabled = true
            self.searchService.ClearEntity()
            self.searchService.FetchData(WithSearchString: nil, Page: 0, ConfigOverride: self.localConfig)
        }
    }
}
//End: UIScrollViewDelegate


//Mark: DynamicHeightCollectionLayoutDelegate
extension SearchViewController: ColumnCollectionLayoutDelegate {
    func collectionViewColumnNumberFor(collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionViewCellMarginFor(collectionView: UICollectionView) -> CGFloat {
        return CGFloat(14)
    }
    
    func collectionView(collectionView: UICollectionView, forCellContentHeightAt indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
//        let defaultHeight = CGFloat(25)
//        guard let searchEntity = searchResultsController.fetchedObjects?[indexPath.item] else { return defaultHeight }
//        guard let imageData = searchEntity.thumbImageData else { return defaultHeight }
//        guard let tempImage = UIImage(data: imageData as Data) else { return defaultHeight }
//        let boundingRect = CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
//        let resizedRect = AVMakeRect(aspectRatio: tempImage.size, insideRect: boundingRect)
//        
//        return resizedRect.height < defaultHeight ? defaultHeight : resizedRect.height
        return 90.0
    }
    
    func collectionViewTopInset() -> CGFloat {
        return self.searchInputView.frame.height
    }
}
//End: DynamicHeightCollectionLayoutDelegate

//Mark: QueryCellDelegate
extension SearchViewController: CollectionToggleTitleCellDelegate {
    func ToggleTitleCellLeftButtonInvoked(ForCell cell: UICollectionViewCell) {
        guard let validIndexPath = self.searchCollectionView.indexPath(for: cell) else { return }
        guard let validSearch = self.searchResultsController.fetchedObjects?[validIndexPath.item] else { return }
        guard let validBookURL = validSearch.hrefURL else { return }
        BookService.sharedBookService.FetchData(WithBookURL: validBookURL)
    }
    
    func ToggleTitleCellRightButtonInvoked(ForCell cell: UICollectionViewCell) {
        guard let indexPath = self.searchCollectionView.indexPath(for: cell) else { print("No book cell found"); return }
        guard let searchBookInfo = self.searchResultsController.fetchedObjects?[indexPath.item] else { return }
        guard let validURL = searchBookInfo.hrefURL else { return }
        PlayViewController.ShowTemp(InParentViewController: self, BookURL: validURL, BookId: searchBookInfo.id)
    }
}
//End: QueryCellDelegate

//Mark: SearchInputViewDelegate
extension SearchViewController: SearchInputViewDelegate {
    func SearchInputViewSelectionChanged(ToggleList list: [(String?, Bool)]) {
        for (buttonTitle, isSelected) in list {
            guard let validTitle = buttonTitle else { continue }
            guard let key = ConfigurationHelper.EHenFilterOptions(rawValue: validTitle) else { continue }
            self.localConfig.toggleFilterSettings[key] = isSelected
        }
    }
    
    func SearchInputViewSearchInvoked(WithString string: String) {
        self.searchCollectionView.setContentOffset(CGPoint(x: 0, y: self.searchCollectionView.contentInset.top), animated: false)
        self.searchService.ClearEntity()
        self.searchService.FetchData(
            WithSearchString: string,
            Page: 0,
            ConfigOverride: self.localConfig)
    }
}
//End: SearchInputViewDelegate

//Mark: QueryServiceDelegate
extension SearchViewController: QueryServiceDelegate {
    func QueryServiceStartingToFetchData(WithService service: ServiceBase) {
        self.view.ShowActivityIndicator()
    }
    
    func QueryServiceFinishedFetchingData(WithService service: ServiceBase) {
        self.view.RemoveActivityIndicator()
    }
}
//End: QueryServiceDelegate
