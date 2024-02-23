import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SaveDocumentPicker: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: UIViewControllerRepresentableContext<SaveDocumentPicker>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<SaveDocumentPicker>) {
        // Non è necessario aggiornare il controller in questo contesto.
    }
}
