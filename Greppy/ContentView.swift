import SwiftUI
import UniformTypeIdentifiers


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fileContent: "To start using the app, first locate the icon positioned at the bottom left corner of your\nscreen. This icon is designed for opening files and is your gateway to accessing the documents stored\non your device. Once you tap on this icon, you will be presented with a list of\nfiles. From this list, select the file you wish to explore. Upon selection, the file will\nopen within the app, displaying its contents in a readable format. Now, to search for specific\ncontent within the opened file, direct your attention to the text box located at the top\nof the screen. This text box is your search tool. Enter the keywords or phrases you're looking\nfor, and the app will highlight and navigate you through the occurrences of the searched terms\nwithin the document. This feature allows for an efficient and effective way to find the information\nyou need without manually scouring the entire document.\n\nThe combination of these functionalities—opening files and searching within them—makes this app an invaluable tool\nfor anyone who needs to work with text documents efficiently. Whether you are a student, a professional,\nor just someone who handles a lot of documents, this app simplifies the process of finding the exact\ninformation you need, when you need it.\n")

    }
}

struct ContentView: View {
    @State public var fileContent: String = "To start using the app, first locate the icon positioned at the bottom left corner of your\nscreen. This icon is designed for opening files and is your gateway to accessing the documents stored\non your device. Once you tap on this icon, you will be presented with a list of\nfiles. From this list, select the file you wish to explore. Upon selection, the file will\nopen within the app, displaying its contents in a readable format. Now, to search for specific\ncontent within the opened file, direct your attention to the text box located at the top\nof the screen. This text box is your search tool. Enter the keywords or phrases you're looking\nfor, and the app will highlight and navigate you through the occurrences of the searched terms\nwithin the document. This feature allows for an efficient and effective way to find the information\nyou need without manually scouring the entire document.\n\nThe combination of these functionalities—opening files and searching within them—makes this app an invaluable tool\nfor anyone who needs to work with text documents efficiently. Whether you are a student, a professional,\nor just someone who handles a lot of documents, this app simplifies the process of finding the exact\ninformation you need, when you need it.\n"
    @State private var searchText: String = ""
    @State private var searchResults: String = ""
    @State private var showingFilePicker = false
    @State private var showToast: Bool = false
    @State private var showingEditor: Bool = false // Controlla se mostrare l'editor
    @State private var selectedText: String? = nil // Traccia il testo selezionato
    @ObservedObject var appState = AppState.shared
    
    @State private var textRows: [String] = []
    @State private var isLoading = false

    @State private var loadedItemCount: Int = 0

        var body: some View {
            VStack {
                if showingEditor, let selectedText = selectedText {
                    VStack {
                        HStack {
                            Spacer() // Spinge l'icona tutto a destra
                            Button(action: {
                                // Azione per chiudere l'editor
                                self.showingEditor = false
                            }) {
                                Image(systemName: "xmark.circle.fill") // Icona di chiusura
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        TextEditor(text: .constant(selectedText))
                            .frame(height: 100) // Altezza dell'editor
                            .border(Color.gray, width: 1) // Bordo dell'editor
                    }
                    .transition(.slide) // Aggiunge un'animazione quando l'editor appare/scompare
                    .padding()
                }
            List(textRows.indices, id: \.self) { index in
                HStack {
                    Text(textRows[index])
                    .onAppear {
                        loadMoreContentIfNeeded(currentItem: textRows[index])
                    }
                    Spacer()
                    // VStack per le icone allineate verticalmente
                    VStack {
                        Button(action: {
                            self.selectedText = row // Imposta il testo selezionato sulla riga toccata
                            self.showingEditor = true // Mostra l'editor
                        }) {
                            Image(systemName: "filemenu.and.selection") // Icona per l'azione di selezione
                                .foregroundColor(.blue)
                        }
                    }                    }
                    .padding(.vertical, 4) // Aggiungi un po' di padding per facilitare la pressione del bottone                    
            }.frame(maxHeight: .infinity) // Assicura che la ScrollView utilizzi lo spazio disponibile
                    .onOpenURL(perform: { url in
                        fileContent = "Loading..."
                        // Esegui la lettura del file in background
                          DispatchQueue.global(qos: .userInitiated).async {
                              let loadedContent = loadFileContent(from: url)
                              
                              // Una volta caricato il contenuto, aggiorna l'UI sulla main queue
                              DispatchQueue.main.async {
                                  fileContent = loadedContent
                              }
                          }
                    })

            if showToast {
                   Text("Copied to clipboard")
                       .bold()
                       .foregroundColor(.white)
                       .padding()
                       .background(Color.black.opacity(0.7))
                       .clipShape(Capsule())
                       .transition(.opacity)
                       .zIndex(1) // Assicurati che sia sopra gli altri elementi
               }
            
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
                
                Button(action: {
                    // Azione per chiudere l'editor
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill") // Icona di chiusura
                        .foregroundColor(.gray)
                        .padding()
                }

            }

            // Mostra il picker quando showingFilePicker è true
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(fileContent: $fileContent)
            }
        }.animation(.default, value: showToast)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func filteredContent() -> [String] {
        let lines = fileContent.components(separatedBy: "\n")
        return lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadFileContent(from url: URL) -> String {
        // Assumi che questa funzione legga il contenuto del file e lo ritorni come String
        do {
            return try String(contentsOf: url)
        } catch {
            print("Errore nella lettura del file: \(error)")
            return "Errore nella lettura del file."
        }
    }

    func loadMoreContentIfNeeded(currentItem item: String?) {
        guard let item = item else {
            loadInitialContent()
            return
        }
        
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0 == item }) == thresholdIndex {
            loadMoreContent()
        }
    }

    func loadInitialContent() {
        let lines = fileContent.components(separatedBy: "\n")
        let filteredLines = lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
        self.loadedItemCount += 20
        return Array(filteredLines.prefix(20))
    }

    func loadMoreContent() {
        guard !isLoading else { return }
        isLoading = true
        
        // Simula il caricamento di più dati
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let lines = fileContent.components(separatedBy: "\n")
            let filteredLines = lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
            let results = Array(filteredLines.dropFirst(20).prefix(20))
            self.loadedItemCount += 20
            self.items.append(contentsOf: results)
            self.isLoading = false
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
