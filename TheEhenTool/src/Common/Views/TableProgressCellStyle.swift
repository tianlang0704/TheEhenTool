//
//  DownloadCellStyle1.swift
//  TheEhenTool
//
//  Created by CMonk on 1/18/17.
//  Copyright © 2017 acrew. All rights reserved.
//

import UIKit

class TableProgressCellStyle: UITableViewCell {
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var thumb: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var page: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        self.LayerRoundBorder(layer: self.contentView.layer)
        self.LayerRoundBorder(layer: self.thumb.layer)
        self.CellShadow(cell: self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func LayerRoundBorder(layer: CALayer) {
        layer.cornerRadius = 3.0;
        layer.borderWidth = 0.5;
        layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.9).cgColor
        layer.masksToBounds = true;
    }
    
    func CellShadow(cell: UITableViewCell) {
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        //cell.layer.shadowRadius = 2.0
        //cell.layer.shadowOpacity = 0.3
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
    }

}
