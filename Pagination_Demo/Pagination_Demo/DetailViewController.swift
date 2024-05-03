
//  DetailViewController.swift
//  Pagination_Demo
//  Created by Mansi Thakur on 03/05/24.


import UIKit

class DetailViewController: UIViewController {
    
    var dataArr:ListDataModel?

    @IBOutlet weak var idLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.idLbl.text = "ID:\(dataArr?.id ?? 0)"
        self.titleLbl.text = "Title: "+(dataArr?.title ?? "")
        self.descLbl.text = "Description: "+(dataArr?.body ?? "")
    }
 
}
