import SwiftUI
import UIKit

struct SaveDocumentPicker: UIViewControllerRepresentable {
    var documentContent: String
    var contentType: UTType = .plainText // Assicurati di importare UniformTypeIdentifiers
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("ExportedFile.txt")
        
        // Scrivi il contenuto nel file temporaneo
        do {
            try documentContent.write(to: temporaryFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Errore durante la scrittura del file: \(error)")
        }
        
        let picker = UIDocumentPickerViewController(forExporting: [temporaryFileURL])
        picker.shouldShowFileExtensions = true // Mostra le estensioni dei file se necessario
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Non è necessario aggiornare il picker in questo caso
    }
}