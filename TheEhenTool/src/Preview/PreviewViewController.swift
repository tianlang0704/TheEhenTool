//
//  ViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/6/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class PreviewViewController: UIViewController {
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var layoutConstraintLargeViewHeight: NSLayoutConstraint!
    @IBOutlet weak var layoutConstraintLargeViewHeightLoPrio: NSLayoutConstraint!
    @IBOutlet weak var largePreviewView: UIView!
    @IBOutlet weak var largeTitleLabel: UILabel!
    @IBOutlet weak var largePreviewImage: UIImageView!
    @IBOutlet weak var searchInputView: SearchInputView!
    
    let localConfig = ConfigurationHelper()
    let globalConfig = ConfigurationHelper.shared
    let previewService = PreviewService.sharedPreviewService
    var previewResultsController: NSFetchedResultsController<PreviewBookInfoEntity>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.InitializeComponentSubviews()
        self.InitializeScrollView()
        self.InitializeCollectionView()
        self.InitializeFetchedResultsController()
        self.initializeService()
        self.previewService.FetchData(WithSearchString: "", Page: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("==========================memory warning")
    }
    func initializeService() {
        self.previewService.delegate = self
    }
    
    func InitializeComponentSubviews() {
        self.searchInputView = self.searchInputView.fromNib()
        self.searchInputView.endEditingTapGestureTarget = self.previewCollectionView
        self.searchInputView.SetSearchBarHeight(Height: 0)
        self.searchInputView.delegate = self
    }
    
    func InitializeScrollView() {
        (self.previewCollectionView as UIScrollView).delegate = self
    }
    
    func InitializeCollectionView() {
        let cellNIB = UINib(nibName: "CollectionToggleTitleCellStyle", bundle: nil)
        self.previewCollectionView.register(cellNIB, forCellWithReuseIdentifier: "CollectionToggleTitleCellStyle")
        if let layout = self.previewCollectionView.collectionViewLayout as? DynamicHeightCollectionLayout{
            layout.delegate = self
        }
    }
    
    func InitializeFetchedResultsController() {
        let appDele: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let request: NSFetchRequest = PreviewBookInfoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        self.previewResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: appDele.cacheContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.previewResultsController.delegate = self
        do { try self.previewResultsController.performFetch() } catch { print(error) }
    }
}

//Mark: NSFetchedResultsControllerDelegate
extension PreviewViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.previewCollectionView.reloadData()
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
extension PreviewViewController: UICollectionViewDataSource {
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.previewResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.previewResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.ConfigureCollectionViewCell(collectionView: collectionView, indexPath: indexPath)
    }
    
    func ConfigureCollectionViewCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionToggleTitleCellStyle", for: indexPath) as! CollectionToggleTitleCellStyle
        guard let previewEntity = previewResultsController.fetchedObjects?[indexPath.item] else { return cell }
        
        cell.delegate = self
        cell.title = previewEntity.title
        if let thumbData = previewEntity.thumbImageData {
            cell.thumb = UIImage(data: thumbData as Data)
        }
        
        return cell
    }
}
//End: UICollectionViewDataSource

//Mark: UICollectionViewDelegate
extension PreviewViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionToggleTitleCellStyle
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = self.previewCollectionView.cellForItem(at: indexPath) as! CollectionToggleTitleCellStyle
        self.largeTitleLabel.text = cell.title
        if let image = cell.thumb {
            self.largePreviewImage.image = UIImageHelper.Aspect(Image: image, WithWidth: self.view.frame.width)
        }else{
            self.largePreviewImage.image = cell.thumb
        }
        
        UIView.animate(withDuration: 0.2) {
            self.largePreviewView.removeConstraint(self.layoutConstraintLargeViewHeight)
            self.largePreviewView.addConstraint(self.layoutConstraintLargeViewHeightLoPrio)
            self.view.layoutIfNeeded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.2) {
            self.largePreviewView.removeConstraint(self.layoutConstraintLargeViewHeightLoPrio)
            self.largePreviewView.addConstraint(self.layoutConstraintLargeViewHeight)
            self.view.layoutIfNeeded()
        }
    }
}
//End: UICollectionViewDelegate

//Mark: UIScrollViewDelegate
extension PreviewViewController: UIScrollViewDelegate {
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
            self.previewService.FetchData(WithSearchString: nil, Page: nil, ConfigOverride: self.localConfig)
        }
        
        //Top - reload
        if(topEdge < scrollLoadOffset * -1) {
            scrollView.isScrollEnabled = false
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            scrollView.isScrollEnabled = true
            self.previewService.ClearEntity()
            self.previewService.FetchData(WithSearchString: nil, Page: 0, ConfigOverride: self.localConfig)
        }
    }
}
//End: UIScrollViewDelegate


//Mark: DynamicHeightCollectionLayoutDelegate
extension PreviewViewController: DynamicHeightCollectionLayoutDelegate {
    func collectionViewColumnNumberFor(collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionViewCellMarginFor(collectionView: UICollectionView) -> CGFloat {
        return CGFloat(14)
    }
    
    func collectionViewTopInset() -> CGFloat {
        return self.searchInputView.frame.height
    }
    
    func collectionView(collectionView: UICollectionView, forCellContentHeightAt indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let defaultHeight = CGFloat(25)
        guard let previewEntity = previewResultsController.fetchedObjects?[indexPath.item] else { return defaultHeight }
        guard let imageData = previewEntity.thumbImageData else { return defaultHeight }
        guard let tempImage = UIImage(data: imageData as Data) else { return defaultHeight }
        let boundingRect = CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        let resizedRect = AVMakeRect(aspectRatio: tempImage.size, insideRect: boundingRect)
        
        return resizedRect.height < defaultHeight ? defaultHeight : resizedRect.height
    }
}
//End: DynamicHeightCollectionLayoutDelegate

//Mark: QueryCellDelegate
extension PreviewViewController: CollectionToggleTitleCellDelegate {
    func ToggleTitleCellLeftButtonInvoked(ForCell cell: UICollectionViewCell) {
        guard let validIndexPath = self.previewCollectionView.indexPath(for: cell) else { return }
        guard let validPreview = self.previewResultsController.fetchedObjects?[validIndexPath.item] else { return }
        guard let validBookURL = validPreview.hrefURL else { return }
        BookService.sharedBookService.FetchData(WithBookURL: validBookURL)
    }
    
    func ToggleTitleCellRightButtonInvoked(ForCell cell: UICollectionViewCell) {
        guard let indexPath = self.previewCollectionView.indexPath(for: cell) else { print("No book cell found"); return }
        guard let previewBookInfo = self.previewResultsController.fetchedObjects?[indexPath.item] else { return }
        guard let validURL = previewBookInfo.hrefURL else { return }
        PlayViewController.ShowTemp(InParentViewController: self, BookURL: validURL, BookId: previewBookInfo.id)
    }
}
//End: QueryCellDelegate

//Mark: SearchInputViewDelegate
extension PreviewViewController: SearchInputViewDelegate {
    static var pendingCatagoryRefreshWorkItem: DispatchWorkItem? = nil
    
    func SearchInputViewSelectionChanged(ToggleList list: [(String?, Bool)]) {
        for (buttonTitle, isSelected) in list {
            guard let validTitle = buttonTitle else { continue }
            guard let key = ConfigurationHelper.EHenFilterOptions(rawValue: validTitle) else { continue }
            self.localConfig.toggleFilterSettings[key] = isSelected
        }
        
        if let validWorkItem = PreviewViewController.pendingCatagoryRefreshWorkItem {
            validWorkItem.cancel()
        }
        PreviewViewController.pendingCatagoryRefreshWorkItem = DispatchWorkItem {
            self.previewCollectionView.setContentOffset(
                CGPoint(x: 0, y: self.previewCollectionView.contentInset.top), animated: false)
            self.previewService.ClearEntity()
            self.previewService.FetchData(WithSearchString: nil, Page: 0, ConfigOverride: self.localConfig)
            PreviewViewController.pendingCatagoryRefreshWorkItem = nil
        }
        if let validWorkItem = PreviewViewController.pendingCatagoryRefreshWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: validWorkItem)
        }
    }
    
    func SearchInputViewSearchInvoked(WithString string: String) { }
}
//End: SearchInputViewDelegate

//Mark: QueryServiceDelegate
extension PreviewViewController: QueryServiceDelegate {
    func QueryServiceStartingToFetchData(WithService service: ServiceBase) {
        self.view.ShowActivityIndicator()
    }
    
    func QueryServiceFinishedFetchingData(WithService service: ServiceBase) {
        self.view.RemoveActivityIndicator()
    }
}
//End: QueryServiceDelegate
