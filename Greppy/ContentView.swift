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
    @State private var showingEditor: Bool = false // Controlla se mostrare l'editor
    @State private var selectedText: String? = nil // Traccia il testo selezionato
    @State private var submittedText: String = ""
    @ObservedObject var appState = AppState.shared
    @State private var maxLine: Int = UserDefaults.standard.integer(forKey: "maxLines") != 0 ? UserDefaults.standard.integer(forKey: "maxLines") : 2000
    @State private var searchTabs: [String] = [] 
    @State private var messageMaxLine: String = "!! RESULTS LIMITED TO 2000 DUE TO MEMORY FOOTPRINT. REFINE SEARCH FOR MORE SPECIFIC OUTCOMES !!"
    @State private var selectedTabIndex: Int = 0
    @State private var showingSettingLinesBeforeAfter = false
    @State private var firstLoad: Bool = false
    @State private var userInput: String = ""
    
    func textRows(for submittedText: String) -> [String] {
        var allRows = submittedText.isEmpty ? fileContent.components(separatedBy: "\n") : filteredContent(for: submittedText)
        print(allRows.count)
        allRows = Array(allRows.prefix(maxLine))
        if(allRows.count >= maxLine) {
            allRows.append(messageMaxLine)
        }
        return allRows
    }    
    
    func makeAttributedString(fullText: String, highlight: String, isCaseSensitive: Bool) -> AttributedString {
        var attributedString = AttributedString(fullText)
        
        // Determina le opzioni di ricerca in base alla sensibilità alle maiuscole e minuscole
        let options: String.CompareOptions = isCaseSensitive ? [] : .caseInsensitive
        
        // Flag per tenere traccia se abbiamo trovato almeno un match
        var foundMatch = false
        
        // Utilizza un ciclo per trovare tutte le corrispondenze
        var currentIndex = fullText.startIndex
        while let range = fullText.range(of: highlight, options: options, range: currentIndex..<fullText.endIndex), !range.isEmpty {
            foundMatch = true // Abbiamo trovato almeno un match
            // Converti il range di String in un range di AttributedString
            if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                attributedString[attributedRange].backgroundColor = .yellow
                attributedString[attributedRange].foregroundColor = .red
            }
            currentIndex = range.upperBound
        }
        
        // Se non abbiamo trovato alcun match, applica uno stile di default all'intero testo
        if !foundMatch {
            attributedString.foregroundColor = .gray // Esempio di applicazione di un colore di foreground di default
            // Puoi impostare qui altri stili di default se necessario
        }
        
        return attributedString
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
                TabView(selection: $selectedTabIndex) {
                    ForEach(searchTabs, id: \.self) { searchTerm in
                        List {
                            ForEach(textRows(for: searchTerm), id: \.self) { row in
                                HStack {
                                    Text(makeAttributedString(fullText: row, highlight: searchTerm, isCaseSensitive: UserDefaults.standard.bool(forKey: "caseSensitiveSearch"))).background(row == messageMaxLine ? Color.red : Color.clear)
                                    Spacer()
                                    // VStack per le icone allineate verticalmente
                                    VStack {
                                        Button(action: {
                                            self.selectedText = row // Imposta il testo selezionato sulla riga toccata
                                            self.showingEditor = true // Mostra l'editor
                                        }) {
                                            Image(systemName: "filemenu.and.selection") // Icona per l'azione di selezione
                                                .foregroundColor(.blue)
                                        }.accessibilityIdentifier("buttonShowingEditor")
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
                            }).tabItem {
                                Label(searchTerm == "" ? "Original" : searchTerm, systemImage: "doc.text.magnifyingglass")
                            }.contextMenu {
                                Button {
                                    if let index = searchTabs.firstIndex(of: searchTerm) {
                                        if(index > 0) {
                                            searchTabs.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Label("Close", systemImage: "xmark")
                                }
                            }.tag(Int(searchTabs.firstIndex(of: searchTerm) ?? 0))
                    }
                }
                
                HStack {
                    Button(action: {
                                   showingFilePicker = true
                                    searchText = ""
                                    submittedText = ""
                                    searchTabs.removeAll()
                                    addNewSearchTab(searchText: "")
                               }) {
                                   Image(systemName: "folder") // Esempio di icona di apertura file
                                       .resizable() // Rendi l'immagine resizable
                                       .aspectRatio(contentMode: .fit) // Mantiene le proporzioni dell'immagine
                                       .frame(width: 24, height: 24) // Imposta dimensioni dell'icona
                               }
                               .padding()

                    Button(action: {
                                showingSettingLinesBeforeAfter = true
                               }) {
                                   Image(systemName: "gear")
                                       .resizable() // Rendi l'immagine resizable
                                       .aspectRatio(contentMode: .fit) // Mantiene le proporzioni dell'immagine
                                       .frame(width: 24, height: 24) // Imposta dimensioni dell'icona
                               }.sheet(isPresented: $showingSettingLinesBeforeAfter) {
                                   settingLinesBeforeAfterView()
                               }
                    
                    TextField("Search", text: $userInput)
                                .padding()
                                .accessibilityIdentifier("searchBox")
                                .submitLabel(.done) // Imposta la label del tasto di invio a "Done"
                                .onSubmit {
                                    
                                    // if exist, I will remove
                                    searchText = userInput
                                    if let index = searchTabs.firstIndex(of: searchText) {
                                        if(index > 0) {
                                            searchTabs.remove(at: index)
                                        }
                                    }
                                    // Questa azione viene eseguita quando l'utente preme "Done"
                                    submittedText = searchText // Aggiorna `submittedText` con il valore attuale di `searchText`
                                    // Aggiungi qui ulteriori azioni che desideri eseguire dopo la sottomissione
                                    addNewSearchTab(searchText: searchText)
                                }
                                .textInputAutocapitalization(.none) // Opzionale: disabilita l'autocapitalizzazione
                                .disableAutocorrection(true) // Opzionale: disabilita l'autocorrezione
                    
                    Button(action: {
                        // Azione per chiudere l'editor
                        userInput = ""
                        searchText = ""
                        submittedText = ""
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
            .frame(maxWidth: .infinity, maxHeight: .infinity).onAppear(perform: {
                if(firstLoad == false) {
                    addNewSearchTab(searchText: "")
                    firstLoad = true
                }
            })
    }
    func addNewSearchTab(searchText: String) {
        searchTabs.append(searchText) // Aggiungi il nuovo termine di ricerca alla lista dei tab
        selectedTabIndex = searchTabs.count - 1
        print("selectedTabIndex \(selectedTabIndex)")
    }

    private func filteredContent(for submittedText: String) -> [String] {
        let lines = fileContent.components(separatedBy: "\n")
        var filteredLines = [String]()

        // Recupera i valori dai settaggi usando UserDefaults
        let linesBefore = UserDefaults.standard.integer(forKey: "linesBefore")
        let linesAfter = UserDefaults.standard.integer(forKey: "linesAfter")
        let isCaseSensitive = UserDefaults.standard.bool(forKey: "caseSensitiveSearch")

        for (index, line) in lines.enumerated() {
            // Applica la logica di confronto in base alla sensibilità alle maiuscole
            let doesMatch: Bool
            if isCaseSensitive {
                doesMatch = line.contains(submittedText)
            } else {
                doesMatch = line.lowercased().contains(submittedText.lowercased())
            }

            if doesMatch {
                // Calcola l'intervallo di linee prima della corrispondenza
                let startRange = max(0, index - linesBefore)
                let endRange = min(lines.count, index + linesAfter + 1) // Aggiustato per includere la linea dopo

                // Aggiungi le linee di contesto prima, la linea corrente e dopo
                for contextIndex in startRange..<endRange {
                    let contextLine = lines[contextIndex]
                    // Evita di aggiungere duplicati se ci sono corrispondenze multiple vicine
                    if !filteredLines.contains(contextLine) {
                        filteredLines.append(contextLine)
                    }
                }

                // Controlla se abbiamo raggiunto il limite massimo di linee
                if filteredLines.count >= maxLine {
                    break
                }
            }
        }

        if(filteredLines.count >= maxLine) {
            filteredLines.append(messageMaxLine)
        }

        return Array(filteredLines.prefix(maxLine))
    }

    func loadFileContent(from url: URL) -> String {
        searchTabs.removeAll()
        addNewSearchTab(searchText: "")
        // Assumi che questa funzione legga il contenuto del file e lo ritorni come String
        do {
            return try String(contentsOf: url)
        } catch {
            print("Errore nella lettura del file: \(error)")
            return "Errore nella lettura del file \(error.localizedDescription)"
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
