import SwiftUI
import UniformTypeIdentifiers

struct LazyTextList: View {
    var textRows: [String] // Array contenente ogni riga del testo

    var body: some View {
        List(textRows.indices, id: \.self) { index in
            Text(textRows[index])
                .onAppear {
                    loadMoreContentIfNeeded(currentItem: textRows[index])
                }
        }
    }

    private func loadMoreContentIfNeeded(currentItem: String) {
        guard let currentIndex = textRows.firstIndex(of: currentItem) else {
            return
        }

        // Se l'utente ha raggiunto l'ultima riga, carica più contenuto
        if currentIndex == textRows.count - 1 {
            // Qui puoi aggiungere la logica per caricare più righe di testo
            // Ad esempio, leggere ulteriori righe da un file o da una fonte di dati
            print("Carica più contenuto")
        }
    }
}

// Estensione per suddividere una stringa di testo in righe
extension String {
    func lines() -> [String] {
        self.components(separatedBy: .newlines)
    }
}

struct LazyTextList_Previews: PreviewProvider {
    static var previews: some View {
        // Esempio di utilizzo
        LazyTextList(textRows: "Questa è una lunga stringa di testo\nche verrà divisa in righe\nogni riga sarà visualizzata come una cella separata in una List\nl'ultima riga qui".lines())
    }
}

struct ContentView: View {
    @State private var fileContent: String = ""
    @State private var searchText: String = ""
    @State private var searchResults: String = ""
    @State private var showingFilePicker = false
    
    private var textRows: [String] {
            searchText.isEmpty ? fileContent.components(separatedBy: "\n") : filteredContent()
        }

    var body: some View {
        VStack {
            // TextEditor sostituito con ScrollView + Text per visualizzare il contenuto del file
            List {
                        ForEach(textRows, id: \.self) { row in
                            Text(row)
                        }
                    }
            .frame(maxHeight: .infinity) // Assicura che la ScrollView utilizzi lo spazio disponibile

            HStack {
                Button(action: {
                               showingFilePicker = true
                           }) {
                               Image(systemName: "paperplane") // Esempio di icona di apertura file
                                   .resizable() // Rendi l'immagine resizable
                                   .aspectRatio(contentMode: .fit) // Mantiene le proporzioni dell'immagine
                                   .frame(width: 24, height: 24) // Imposta dimensioni dell'icona
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
    private func filteredContent() -> [String] {
        let lines = fileContent.components(separatedBy: "\n")
        return lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
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
