//
//  GalleryModel.swift
//  stamppal
//
//  Created by Muhammad Alief Rahman Fardillah on 06/09/26.
//

import Foundation
import SwiftData
import UIKit

@Model
final class GallerySession {

    var id: UUID

    var title: String

    var date: Date

    // Five movement photos
    var photo1Data: Data?
    var photo2Data: Data?
    var photo3Data: Data?
    var photo4Data: Data?
    var photo5Data: Data?

    init(
        title: String,
        date: Date = Date(),
        images: [UIImage]
    ) {

        self.id = UUID()

        self.title = title

        self.date = date

        self.photo1Data =
            images.indices.contains(0)
            ? images[0].jpegData(compressionQuality: 0.90)
            : nil

        self.photo2Data =
            images.indices.contains(1)
            ? images[1].jpegData(compressionQuality: 0.90)
            : nil

        self.photo3Data =
            images.indices.contains(2)
            ? images[2].jpegData(compressionQuality: 0.90)
            : nil

        self.photo4Data =
            images.indices.contains(3)
            ? images[3].jpegData(compressionQuality: 0.90)
            : nil

        self.photo5Data =
            images.indices.contains(4)
            ? images[4].jpegData(compressionQuality: 0.90)
            : nil
    }

    // MARK: - Images

    var images: [UIImage] {

        [
            photo1Data,
            photo2Data,
            photo3Data,
            photo4Data,
            photo5Data
        ]
        .compactMap { data in

            guard let data else {
                return nil
            }

            return UIImage(data: data)
        }
    }

    // MARK: - Number of Photos

    var photoCount: Int {

        [
            photo1Data,
            photo2Data,
            photo3Data,
            photo4Data,
            photo5Data
        ]
        .compactMap { $0 }
        .count
    }
}
