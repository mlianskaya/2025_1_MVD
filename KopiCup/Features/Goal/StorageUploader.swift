import Foundation
import UIKit

enum UploaderError: Error {
    case notSignedIn
    case encodingFailed
    case notImplemented
}

struct StorageUploader {
    // Ранее загружал картинку в Firebase Storage и возвращал downloadURL.
    // Сейчас загрузка отключена.
    static func uploadGoalImage(_ image: UIImage) async throws -> String {
        throw UploaderError.notImplemented
    }
}
