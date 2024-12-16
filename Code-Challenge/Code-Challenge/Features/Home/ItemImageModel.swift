//
//  ItemImageModel.swift
//  Code-Challenge
//
//  Created by Nhi on 12/16/24.
//

import Foundation

struct ItemImageModel: Codable {
    let id, author: String?
    let width, height: Int?
    let url, downloadURL: String?

    enum CodingKeys: String, CodingKey {
        case id, author, width, height, url
        case downloadURL = "download_url"
    }
}
