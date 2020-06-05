//
//  FavoritesTableViewController.swift
//  NewYorkTimesNews
//
//  Created by Vitaliy on 02.06.2020.
//  Copyright © 2020 Vitaliy. All rights reserved.
//

import UIKit
import SafariServices

class FavoritesTableViewController: UITableViewController {
    
    let coreDataNewsViewModel = CoreDataNewsViewModel()
    var cameFromTVC: ViewModelChangeable?

    override func viewDidLoad() {
        super.viewDidLoad()
        getFavNews()
    }
    
    private func getFavNews() {
        coreDataNewsViewModel.getFavNewsFromDB { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

// MARK - Table view delegate

extension FavoritesTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newsLink = coreDataNewsViewModel.news[indexPath.row].newsLink
        showLinkWithSafari(link: newsLink)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    private func showLinkWithSafari(link: String) {
        let safariVC = SFSafariViewController(url: URL(string: link)!)
        self.present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }
}

// MARK: - Table view data source

extension FavoritesTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coreDataNewsViewModel.news.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesTableViewCell.cellID, for: indexPath) as! FavoritesTableViewCell
        let favNews = coreDataNewsViewModel.news[indexPath.row]
        cell.updateCell(news: favNews)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let editingCell = tableView.cellForRow(at: indexPath) as? FavoritesTableViewCell else { return }
            guard let editingCellTitle = editingCell.titleLabel?.text else { return }
            coreDataNewsViewModel.news.remove(at: indexPath.row)
            coreDataNewsViewModel.delNewsByTitle(newsTitle: editingCellTitle)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            guard let index = cameFromTVC?.newsViewModel.news.firstIndex(where: { $0.title == editingCellTitle }) else { return }
            cameFromTVC?.newsViewModel.news[index].isFavorite = false
        }
    }
}

// MARK: - SFSafariViewControllerDelegate

extension FavoritesTableViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
