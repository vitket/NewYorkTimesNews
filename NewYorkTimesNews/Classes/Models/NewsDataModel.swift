//
//  NewsModel.swift
//  NewYorkTimesNews
//
//  Created by Vitaliy on 26.05.2020.
//  Copyright © 2020 Vitaliy. All rights reserved.
//

import Foundation

struct NewsDataWrapper: Decodable {
    let results: [WebNewsInfo]
}

struct WebNewsInfo: Decodable {
    let url: String
    let title: String
    let publishedDate: String
    let media: [MediaInfo]
    
    enum CodingKeys: String, CodingKey {
        case url, title, media
        case publishedDate = "published_date"
    }
}

struct MediaInfo: Decodable {
    let metaData: [MetaDataInfo]
    
    enum CodingKeys: String, CodingKey {
        case metaData = "media-metadata"
    }
}

struct MetaDataInfo: Decodable {
    let iconURL: String
    
    enum CodingKeys: String, CodingKey {
        case iconURL = "url"
    }
}
