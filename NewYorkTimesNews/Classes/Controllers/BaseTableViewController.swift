//
//  MostEmailedNewsTVC.swift
//  NewYorkTimesNews
//
//  Created by Vitaliy on 29.05.2020.
//  Copyright © 2020 Vitaliy. All rights reserved.
//

import UIKit
import SafariServices

protocol ViewModelChangeable {
    var newsViewModel: WebNewsViewModel { get set }
}

class BaseTableViewController<T: BaseTableViewCell>: UITableViewController, ViewModelChangeable, Progressable {
    
    @IBOutlet weak var favoritesBarButton: UIButton!
    
    var newsViewModel = WebNewsViewModel()
    var routerState: Router {
        return .getMostEmailedNews
    }
    
    private let coreDataNewsViewModel = CoreDataNewsViewModel()
    private let badgeTag = 777
    private let newRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshNews(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = newRefreshControl
        
        showLoader(withMessage: "Loading...")
        setupCoreDataSavingObserver()
        getFavNewsForBadge()
        getWebNews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        setupCellsFavoriteIcons()
    }
    
    @objc func refreshNews(_ sender: UIRefreshControl) {
        getWebNews()
        sender.endRefreshing()
    }
    
    private func setupCoreDataSavingObserver() {
        let name = NSNotification.Name.NSManagedObjectContextDidSave
        NotificationCenter.default.addObserver(self, selector: #selector(receiveFavNews(_:)), name: name, object: nil)
    }
    
    @objc func receiveFavNews(_ notification: NSNotification) {
        getFavNewsForBadge()
    }
    
    private func getFavNewsForBadge() {
        coreDataNewsViewModel.getFavNewsFromDB { result in
            switch result {
            case .success(_):
                self.setupBarButtonBadge()
                self.setupCellsFavoriteIcons()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func setupCellsFavoriteIcons() {
        for index in 0..<newsViewModel.news.count {
            newsViewModel.news[index].isFavorite = false
        }
        coreDataNewsViewModel.getFavNewsFromDB { result in
            switch result {
            case .success(_):
                self.coreDataNewsViewModel.news.forEach { favNews in
                    if let equalsNewsIndex = self.newsViewModel.news.firstIndex(where: {$0 == favNews}) {
                        self.newsViewModel.news[equalsNewsIndex].makeFavorite(true)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setupBarButtonBadge() {
        let favNewsCount = coreDataNewsViewModel.news.count
        DispatchQueue.main.async {
            if favNewsCount > 0 {
                if let badge = self.favoritesBarButton.viewWithTag(self.badgeTag) as? UILabel {
                    badge.text = String(favNewsCount)
                } else {
                    self.showBadge(withCount: favNewsCount)
                }
            } else {
                self.removeBadge()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showBadge(withCount count: Int) {
        let badgeSize: CGFloat = 20
        let badge = badgeLabel(withCount: count, badgeSize: badgeSize)
        favoritesBarButton.addSubview(badge)

        NSLayoutConstraint.activate([
            badge.leftAnchor.constraint(equalTo: favoritesBarButton.leftAnchor, constant: badgeSize),
            badge.topAnchor.constraint(equalTo: favoritesBarButton.topAnchor, constant: -5),
            badge.widthAnchor.constraint(equalToConstant: badgeSize),
            badge.heightAnchor.constraint(equalToConstant: badgeSize)
        ])
    }
    
    private func removeBadge() {
        if let badge = favoritesBarButton.viewWithTag(badgeTag) {
            badge.removeFromSuperview()
        }
    }
    
    private func badgeLabel(withCount count: Int, badgeSize: CGFloat) -> UILabel {
        let badgeCount = UILabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        badgeCount.translatesAutoresizingMaskIntoConstraints = false
        badgeCount.tag = badgeTag
        badgeCount.layer.cornerRadius = badgeCount.bounds.size.height / 2
        badgeCount.textAlignment = .center
        badgeCount.layer.masksToBounds = true
        badgeCount.textColor = .white
        badgeCount.font = badgeCount.font.withSize(12)
        badgeCount.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        badgeCount.text = String(count)
        return badgeCount
    }
    
    func getWebNews() {
        newsViewModel.getNewsFromWeb(newsType: routerState) { result in
            switch result {
            case .success(_):
                self.hideLoading()
                self.setupCellsFavoriteIcons()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                self.hideLoaderWithError(withMessage: "Error loading!")
                print(error)
            }
        }
    }
    
    @IBAction func favoritesButton(_ sender: UIButton) {
        performSegue(withIdentifier: "segueToFavorites", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let favoritesTVC = segue.destination as? FavoritesNewsTableViewController {
            favoritesTVC.cameFromTVC = self
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsViewModel.news.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: T.cellID, for: indexPath) as! T
        let news = newsViewModel.news[indexPath.row]
        cell.updateCell(news: news)
        cell.delegate = self
        return cell
    }
    
    // MARK - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newsLink = newsViewModel.news[indexPath.row].newsLink
        showLinkWithSafari(link: newsLink)
    }
    
    private func showLinkWithSafari(link: String) {
        guard let linkURL = URL(string: link) else { return }
        let safariVC = SFSafariViewController(url: linkURL)
        self.present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self as? SFSafariViewControllerDelegate
    }
}

// MARK: - SFSafariViewControllerDelegate

extension BaseTableViewController {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - IsFavoriteTappable protocole

extension BaseTableViewController: IsFavoriteMakeble {
    func makeFavorite(cell: UITableViewCell) {
        if let mostEmailedCell = cell as? T {
            if let indexPath = tableView.indexPath(for: mostEmailedCell) {
                newsViewModel.news[indexPath.row].makeFavorite(mostEmailedCell.isFavoriteButton.isSelected)
            }
        }
    }
}
