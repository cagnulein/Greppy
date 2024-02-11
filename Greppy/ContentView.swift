import SwiftUI
import UniformTypeIdentifiers


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fileContent: "To start using the app, \nfirst locate the icon positioned \nat the bottom left corner \nof your screen. This icon \nis designed for opening files \nand is your gateway to \naccessing the documents stored on \nyour device. Once you tap \non this icon, you will \nbe presented with a list \nof files\n\nFrom this list, select the \nfile you wish to explore. \nUpon selection, the file will \nopen within the app, displaying \nits contents in a readable \nformat. Now, to search for \nspecific content within the opened \nfile, direct your attention to \nthe text box located at \nthe top of the screen.\n\nThis text box is your \nsearch tool. Enter the keywords \nor phrases you're looking for, \nand the app will highlight \nand navigate you through the \noccurrences of the searched terms \nwithin the document. This feature \nallows for an efficient and \neffective way to find the \ninformation you need without manually \nscouring the entire document.\n\nThe combination of these functionalities—opening \nfiles and searching within them—makes \nthis app an invaluable tool \nfor anyone who needs to \nwork with text documents efficiently. \nWhether you are a student, \na professional, or just someone \nwho handles a lot of \ndocuments, this app simplifies the \nprocess of finding the exact \ninformation you need, when you \nneed it.")

    }
}

struct ContentView: View {
    @State public var fileContent: String = "To start using the app, \nfirst locate the icon positioned \nat the bottom left corner \nof your screen. This icon \nis designed for opening files \nand is your gateway to \naccessing the documents stored on \nyour device. Once you tap \non this icon, you will \nbe presented with a list \nof files\n\nFrom this list, select the \nfile you wish to explore. \nUpon selection, the file will \nopen within the app, displaying \nits contents in a readable \nformat. Now, to search for \nspecific content within the opened \nfile, direct your attention to \nthe text box located at \nthe top of the screen.\n\nThis text box is your \nsearch tool. Enter the keywords \nor phrases you're looking for, \nand the app will highlight \nand navigate you through the \noccurrences of the searched terms \nwithin the document. This feature \nallows for an efficient and \neffective way to find the \ninformation you need without manually \nscouring the entire document.\n\nThe combination of these functionalities—opening \nfiles and searching within them—makes \nthis app an invaluable tool \nfor anyone who needs to \nwork with text documents efficiently. \nWhether you are a student, \na professional, or just someone \nwho handles a lot of \ndocuments, this app simplifies the \nprocess of finding the exact \ninformation you need, when you \nneed it."
    @State private var searchText: String = ""
    @State private var searchResults: String = ""
    @State private var showingFilePicker = false
    @State private var showToast: Bool = false
    @State private var showingEditor: Bool = false // Controlla se mostrare l'editor
    @State private var selectedText: String? = nil // Traccia il testo selezionato
    
    private var textRows: [String] {
            searchText.isEmpty ? fileContent.components(separatedBy: "\n") : filteredContent()
        }

    

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
            List {
                ForEach(textRows, id: \.self) { row in
                    HStack {
                        Text(row).onLongPressGesture {
                            self.selectedText = row // Imposta il testo selezionato sulla riga toccata
                            self.showingEditor = true // Mostra l'editor
                        }
                        Spacer() // Crea spazio tra il testo e l'icona
                        Button(action: {
                            showToast = true
                            // Nascondi il toast dopo 2 secondi
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showToast = false
                            }
                            // Copia il contenuto della riga negli appunti
                            UIPasteboard.general.string = row
                        }) {
                            Image(systemName: "doc.on.clipboard") // Usa un'icona che suggerisce la copia
                                .foregroundColor(.blue) // Colore dell'icona
                        }
                    }
                    .padding(.vertical, 4) // Aggiungi un po' di padding per facilitare la pressione del bottone
                }
            }.frame(maxHeight: .infinity) // Assicura che la ScrollView utilizzi lo spazio disponibile

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
