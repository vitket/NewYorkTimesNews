//
//  MostEmailedTableViewCell.swift
//  NewYorkTimesNews
//
//  Created by Vitaliy on 29.05.2020.
//  Copyright © 2020 Vitaliy. All rights reserved.
//

import UIKit
import SDWebImage

protocol IsFavoriteMakeble {
    func makeFavorite(cell: UITableViewCell)
}

class BaseTableViewCell: UITableViewCell {
    
    private let coreDataNewsModel = CoreDataNewsViewModel()
    
    @IBOutlet weak var titleNewsLabel: UILabel!
    @IBOutlet weak var iconNewsImageView: UIImageView!
    @IBOutlet weak var publishedDateLabel: UILabel!
    @IBOutlet weak var isFavoriteButton: UIButton!
    
    var delegate: IsFavoriteMakeble?
    private var iconLink: String?
    private var newsLink = ""
    class var cellID: String {
        return ""
    }
    
    func updateCell(news: NewsCoreDataModel) {
        iconLink = news.iconLink
        newsLink = news.newsLink
        titleNewsLabel.text = news.title
        isFavoriteButton.isSelected = news.isFavorite
        publishedDateLabel.text = news.publishedDate
        iconNewsImageView.sd_setImage(with: URL(string: news.iconLink ?? ""), placeholderImage: UIImage(named: "news_icon_placeholder"))
    }
    
    @IBAction func makeFavoriteButton(_ sender: UIButton) {
        if isFavoriteButton.isSelected {
            isFavoriteButton.isSelected = false
            coreDataNewsModel.delNewsByTitle(newsTitle: titleNewsLabel.text!)
        } else {
            isFavoriteButton.isSelected = true
            let currentNews = getCurrentNews()
            coreDataNewsModel.saveFavNewsToDB(news: currentNews)
        }
        delegate?.makeFavorite(cell: self)
    }
    
    private func getCurrentNews() -> NewsCoreDataModel {
        guard let title = titleNewsLabel.text,
              let iconData = iconNewsImageView.image?.pngData(),
              let iconLink = iconLink,
              let publishedData = publishedDateLabel.text else { return NewsCoreDataModel.placeholder }
        
        let currentNews = NewsCoreDataModel(title: title,
                                            iconData: iconData,
                                            iconLink: iconLink,
                                            newsLink: newsLink,
                                            publishedDate: publishedData,
                                            isFavorite: isFavoriteButton.isSelected)
        return currentNews
    }
}
