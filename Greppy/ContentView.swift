import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var fileContent: String = ""
    @State private var searchText: String = ""
    @State private var showingFilePicker = false

    var body: some View {
        VStack {
            // TextEditor sostituito con ScrollView + Text per visualizzare il contenuto del file
            ScrollView {
                TextEditor(text: $fileContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: .infinity) // Assicura che la ScrollView utilizzi lo spazio disponibile
            .border(Color.gray, width: 1)

            HStack {
                Button("Open File") {
                    showingFilePicker = true
                }
                .padding()

                TextField("Search", text: $searchText)
                    .padding()
            }

            // Mostra il picker quando showingFilePicker è true
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(fileContent: $fileContent)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContent: String

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.plainText], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ documentPicker: DocumentPicker) {
            self.parent = documentPicker
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else {
                return
            }
            
            // Tentativo di accedere alla risorsa; se fallisce, procedi comunque al tentativo di lettura
            let canAccess = selectedFileURL.startAccessingSecurityScopedResource()
            
            defer {
                if canAccess {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let fileContent = try String(contentsOf: selectedFileURL, encoding: .utf8)
                DispatchQueue.main.async {
                    self.parent.fileContent = fileContent
                }
            } catch {
                print("Unable to read file content: \(error)")
            }
        }
    }
}
