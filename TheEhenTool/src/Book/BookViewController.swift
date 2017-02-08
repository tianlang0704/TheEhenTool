//
//  BookViewController.swift
//  TheEhenTool
//
//  Created by CMonk on 1/15/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import CoreData
import UIKit

class BookViewController: UIViewController {
    @IBOutlet weak var bookCollectionView: UICollectionView!
    
    var bookResultsController: NSFetchedResultsController<BookInfoEntity>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.InitializeView()
        self.InitializeCollectionView()
        self.InitializeFetchedResultsController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func InitializeView() {
        if let bgImg = UIImage(named: "bg") {
            self.view.backgroundColor = UIColor(patternImage: bgImg);
        }
    }
    
    func InitializeCollectionView() {
        let cellNIB = UINib(nibName: "CollectionTitleCellStyle", bundle: nil)
        self.bookCollectionView.register(cellNIB, forCellWithReuseIdentifier: "CollectionTitleCellStyle")
        if let layout = self.bookCollectionView.collectionViewLayout as? ColumnCollectionLayout{
            layout.delegate = self
        }
    }
    
    func InitializeFetchedResultsController() {
        let appDele: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let request: NSFetchRequest = BookInfoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "bookAddDate", ascending: false)]
        self.bookResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: appDele.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        self.bookResultsController.delegate = self
        do { try self.bookResultsController.performFetch() } catch { print(error) }
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
extension BookViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Will Change Content")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Did Change Content")
        self.bookCollectionView.reloadData()
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
extension BookViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.bookResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.bookResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.ConfigureCollectionViewCell(collectionView: collectionView, indexPath: indexPath)
    }
    
    func ConfigureCollectionViewCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionTitleCellStyle", for: indexPath) as! CollectionTitleCellStyle

        guard let bookInfoEntity = self.bookResultsController.fetchedObjects?[indexPath.item] else { return cell }
        
        cell.bookTitle = bookInfoEntity.bookTitle
        if let thumbData = bookInfoEntity.bookThumbData {
            cell.bookThumb = UIImage(data: thumbData as Data)
        }
        cell.delegate = self
        
        return cell
    }
}
//End: UICollectionViewDataSource

//Mark: UICollectionViewDelegate
extension BookViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath)
        if cell?.isSelected ?? false {
            collectionView.deselectItem(at: indexPath, animated: true)
            return false
        }
        return true
    }
}
//End: UICollectionViewDelegate

//Mark: PreviewCollectionLayoutDelegate
extension BookViewController: ColumnCollectionLayoutDelegate {
    func collectionViewColumnNumberFor(collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionViewCellMarginFor(collectionView: UICollectionView) -> CGFloat {
        return CGFloat(5)
    }
    
    func collectionViewTopInset() -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, forCellContentHeightAt indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        
        return width + 50
    }
}
//End: PreviewCollectionLayoutDelegate

extension BookViewController: CollectionTitleCellDelegate {
    func RemoveInvoked(ForCell cell: UICollectionViewCell) {
        guard let indexPath = self.bookCollectionView.indexPath(for: cell) else { print("No book cell found"); return }
        guard let bookInfoEntity = self.bookResultsController.fetchedObjects?[indexPath.item] else { return }
        
        let alertVC = UIAlertController(title: "Deleting Book", message: "Do you really want to delete me SenPai? QAQ", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Delete", style: .default) { action in
            BookService.sharedBookService.PromiseToRemoveBook(WithId: bookInfoEntity.bookId)
            .catch { error in print("BookViewService.RemoveInvoked: \(error)") }
        })
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel){_ in })
        self.present(alertVC, animated: true)
    }
    
    func ViewInvoked(ForCell cell: UICollectionViewCell) {
        guard let indexPath = self.bookCollectionView.indexPath(for: cell) else { print("No book cell found"); return }
        guard let bookInfoEntity = self.bookResultsController.fetchedObjects?[indexPath.item] else { return }
        PlayViewController.Show(InParentViewController: self, BookId: bookInfoEntity.bookId)
    }
}
