import Foundation
import UIKit
import Vision

/// Runs Apple's on-device text recognition. The image is not uploaded or persisted.
enum ScreenshotOCRService {
    enum OCRError: LocalizedError {
        case invalidImage
        case noText

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "The selected image couldn't be opened."
            case .noText: return "No readable text was found. You can still enter the details manually."
            }
        }
    }

    static func recognize(imageData: Data) async throws -> [String] {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-CA", "en-US", "zh-Hans", "zh-Hant"]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            guard !lines.isEmpty else { throw OCRError.noText }
            return lines
        }.value
    }
}
