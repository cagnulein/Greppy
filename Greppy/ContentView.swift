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
    
    private var textRows: [String] {
            let allRows = searchText.isEmpty ? fileContent.components(separatedBy: "\n") : filteredContent()
            if(allRows.count > 10000) {
                // Mostra il toast
                self.showToast = true
                
                // Nascondi il toast dopo 3 secondi
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showToast = false
                }
            }
            return Array(allRows.prefix(10000))
        }

        var body: some View {
            
            ZStack {
                // Toast message
                if showToast {
                    Text("Too many lines, grep more...")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(Color.white)
                        .cornerRadius(20)
                        // Aggiusta la posizione e l'animazione come preferisci
                        .transition(.opacity)
                        .animation(.easeInOut, value: showToast)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
            List {
                ForEach(textRows, id: \.self) { row in
                    HStack {
                        Text(row)
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
                        }
                    }
                    .padding(.vertical, 4) // Aggiungi un po' di padding per facilitare la pressione del bottone
                }
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
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
