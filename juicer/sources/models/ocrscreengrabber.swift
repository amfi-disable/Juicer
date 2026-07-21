import Foundation
import AppKit
import Vision
import Combine

class OCRScreenGrabberManager: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var statusMessage: String = ""
    
    func captureAndRecognizeText() {
        isProcessing = true
        statusMessage = "Taking interactive screen capture..."
        
        Task.detached(priority: .userInitiated) {
            // Trigger screencapture -i to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ocr_capture_\(UUID().uuidString).png")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", tempURL.path]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                guard FileManager.default.fileExists(atPath: tempURL.path),
                      let image = NSImage(contentsOf: tempURL),
                      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    await MainActor.run {
                        self.isProcessing = false
                        self.statusMessage = "Screen capture cancelled or invalid."
                    }
                    return
                }
                
                await MainActor.run { self.statusMessage = "Performing OCR text recognition..." }
                
                // Run Vision OCR request
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNRecognizeTextRequest { [weak self] req, error in
                    guard let observations = req.results as? [VNRecognizedTextObservation] else {
                        DispatchQueue.main.async {
                            self?.isProcessing = false
                            self?.statusMessage = "No text recognized."
                        }
                        return
                    }
                    
                    let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                    let fullText = recognizedStrings.joined(separator: "\n")
                    
                    DispatchQueue.main.async {
                        self?.recognizedText = fullText
                        self?.isProcessing = false
                        self?.statusMessage = "Recognized \(recognizedStrings.count) lines of text."
                        
                        // Automatically copy to clipboard if text found
                        if !fullText.isEmpty {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(fullText, forType: .string)
                        }
                    }
                }
                
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                
                try requestHandler.perform([request])
                try? FileManager.default.removeItem(at: tempURL)
                
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.statusMessage = "OCR Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
