
//  ViewController.swift
//  Pagination_Demo
//  Created by Mansi Thakur on 03/05/24.


import UIKit
import Alamofire

class ViewController: UIViewController {
    
    var pageSize = 10
    var pageNumber = 1
    var isPaginationOn = false
    var dataArr:[ListDataModel] = []
    
    @IBOutlet weak var listTblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listDataAPICall(page: pageNumber, limit: pageSize)
    }    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as! ListTableViewCell
        cell.idLbl.text = "\(self.dataArr[indexPath.row].id)"
        cell.titleLbl.text = self.dataArr[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "detailViewController") as! DetailViewController
        viewController.dataArr = self.dataArr[indexPath.row]
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension ViewController {
    func listDataAPICall(page:Int, limit:Int){
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_page=\(page)&_limit=\(limit)")!
        AF.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil)
            .responseJSON(completionHandler: { response in
                switch response.result {
                case .success:
                    if let data = response.data{
                        do {
                            let d = try JSONDecoder().decode([ListDataModel].self, from: data)
                            print(d)
                            if self.isPaginationOn{
                                self.dataArr.append(contentsOf: d)
                            }else{
                                self.dataArr.removeAll()
                                self.dataArr.append(contentsOf: d)
                            }
                            self.isPaginationOn = d.count < limit ? false : true
//                            self.dataArr = d
                            self.listTblView.reloadData()
                        }catch(let e){
                            print(e.localizedDescription)
                        }
                    }

                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
    }
    
}

extension ViewController: UIScrollViewDelegate{
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let pos = scrollView.contentOffset.y
//        if pos > listTblView.contentSize.height-50 - scrollView.frame.size.height{
            guard isPaginationOn else{ return }
            pageNumber += 1
//        }
        listDataAPICall(page: pageNumber, limit: self.pageSize)
    }
}
