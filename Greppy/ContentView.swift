import SwiftUI
import UniformTypeIdentifiers


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fileContent: ["":"To start using the app, first locate the icon positioned at the bottom left corner of your\nscreen. This icon is designed for opening files and is your gateway to accessing the documents stored\non your device. Once you tap on this icon, you will be presented with a list of\nfiles. From this list, select the file you wish to explore. Upon selection, the file will\nopen within the app, displaying its contents in a readable format. Now, to search for specific\ncontent within the opened file, direct your attention to the text box located at the top\nof the screen. This text box is your search tool. Enter the keywords or phrases you're looking\nfor, and the app will highlight and navigate you through the occurrences of the searched terms\nwithin the document. This feature allows for an efficient and effective way to find the information\nyou need without manually scouring the entire document.\n\nThe combination of these functionalities—opening files and searching within them—makes this app an invaluable tool\nfor anyone who needs to work with text documents efficiently. Whether you are a student, a professional,\nor just someone who handles a lot of documents, this app simplifies the process of finding the exact\ninformation you need, when you need it.\n"])

    }
}

struct ContentView: View {
    @State public var fileContent: [String: String] = ["": "To start using the app, first locate the icon positioned at the bottom left corner of your\nscreen. This icon is designed for opening files and is your gateway to accessing the documents stored\non your device. Once you tap on this icon, you will be presented with a list of\nfiles. From this list, select the file you wish to explore. Upon selection, the file will\nopen within the app, displaying its contents in a readable format. Now, to search for specific\ncontent within the opened file, direct your attention to the text box located at the top\nof the screen. This text box is your search tool. Enter the keywords or phrases you're looking\nfor, and the app will highlight and navigate you through the occurrences of the searched terms\nwithin the document. This feature allows for an efficient and effective way to find the information\nyou need without manually scouring the entire document.\n\nThe combination of these functionalities—opening files and searching within them—makes this app an invaluable tool\nfor anyone who needs to work with text documents efficiently. Whether you are a student, a professional,\nor just someone who handles a lot of documents, this app simplifies the process of finding the exact\ninformation you need, when you need it.\n"]
    @State private var searchText: String = ""
    @State private var searchResults: String = ""
    @State private var showingFilePicker = false
    @State private var showingEditor: Bool = false // Controlla se mostrare l'editor
    @State private var selectedText: String? = nil // Traccia il testo selezionato
    @State private var submittedText: String = ""
    @ObservedObject var appState = AppState.shared
    @State private var searchTabs: [String] = []
    @State private var messageMaxLine: String = "!! RESULTS LIMITED AS SETTING. REFINE SEARCH FOR MORE SPECIFIC OUTCOMES !!"
    @State private var selectedTabIndex: Int = 0
    @State private var showingSettingLinesBeforeAfter = false
    @State private var firstLoad: Bool = false
    @State private var userInput: String = ""
    @State private var sheetWasPresented = false
    @State private var bookmarkedLines: [String] = []
    @State private var isEditing: Bool = false
    @State private var showSaveDocumentPicker = false
    @State private var lastSelectionDate: Date?
    
    func textRows(for submittedText: String) -> [(lineNumber: Int, text: String, file: String, id: UUID)] {
        var allRows = submittedText.isEmpty || isEditing  // isEditing to speed up the keyboard
        ?  filteredContent(for: "")
            : filteredContent(for: submittedText)
        
        if(allRows.count > maxLine()) {
            allRows = Array(allRows.prefix(maxLine()))
            allRows.append((lineNumber: -1, text: messageMaxLine, file: fileContent.first?.key ?? "", id: UUID()))
        }
        
        return allRows
    }

    func fileGrepped(for submittedText: String) -> String {
        let filteredLinesTuples = filteredContent(for: submittedText)
        let allLinesJoined = filteredLinesTuples.map { $0.text }.joined(separator: "\n")
        return allLinesJoined
    }

    
    func maxLine() -> Int {
        return (UserDefaults.standard.integer(forKey: "maxLines") != 0 ? UserDefaults.standard.integer(forKey: "maxLines") : 2000)
    }

    func regExMatches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func makeAttributedString(fullText: String, highlight: String, isCaseSensitive: Bool) -> AttributedString {
        let isInverted = UserDefaults.standard.bool(forKey: "inverted")
        var attributedString = AttributedString(fullText)
        
        if(isEditing) {
            return attributedString
        }

        var foundMatch = false // Flag per tenere traccia se abbiamo trovato almeno un match
                
        if UserDefaults.standard.bool(forKey: "regEx") {
            // Utilizza NSRegularExpression per trovare tutte le corrispondenze con l'espressione regolare
            do {
                let regex = try NSRegularExpression(pattern: highlight)
                let range = NSRange(location: 0, length: fullText.utf16.count)
                let matches = regex.matches(in: fullText, options: [], range: range)
                
                for _ in matches {
                    for l in regExMatches(for: highlight, in: fullText) {
                        let options: String.CompareOptions = []
                        var currentIndex = fullText.startIndex
                        
                        while let range = fullText.range(of: l, options: options, range: currentIndex..<fullText.endIndex), !range.isEmpty {
                            foundMatch = true
                            if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                                attributedString[attributedRange].backgroundColor = .yellow
                                attributedString[attributedRange].foregroundColor = .red
                            }
                            currentIndex = range.upperBound
                        }                        
                    }
                }
                
                if !matches.isEmpty {
                    foundMatch = true
                }
            } catch {
                print("Errore nella creazione dell'espressione regolare: \(error)")
            }
        } else {
            // Effettua una ricerca normale di sottostringhe
            let options: String.CompareOptions = isCaseSensitive ? [] : .caseInsensitive
            var currentIndex = fullText.startIndex
            
            while let range = fullText.range(of: highlight, options: options, range: currentIndex..<fullText.endIndex), !range.isEmpty {
                foundMatch = true
                if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = .yellow
                    attributedString[attributedRange].foregroundColor = .red
                }
                currentIndex = range.upperBound
            }
        }
        
        if isInverted {
            foundMatch = !foundMatch
        }
        
        if !foundMatch {
            attributedString.foregroundColor = .gray
        }
        
        if bookmarkedLines.firstIndex(of: fullText) != nil {
            attributedString.foregroundColor = .blue
        }
        
        return attributedString
    }

    
    func textSize() -> CGFloat {
        return CGFloat(UserDefaults.standard.integer(forKey: "fontSize") != 0 ? UserDefaults.standard.integer(forKey: "fontSize") : 18)
    }
    
    var body: some View {
                VStack {
                    if showingEditor, let selectedText = selectedText {
                        VStack {
                            HStack {
                                Spacer() // Spinge le icone tutto a destra
                                
                                // Pulsante di bookmark
                                Button(action: {
                                    if let index = bookmarkedLines.firstIndex(of: selectedText) {
                                        // Se la linea è già nei bookmark, rimuovila
                                        bookmarkedLines.remove(at: index)
                                    } else {
                                        // Altrimenti, aggiungila ai bookmark
                                        bookmarkedLines.append(selectedText)
                                    }
                                }) {
                                    // Cambia l'icona in base alla presenza nella lista dei bookmark
                                    Image(systemName: bookmarkedLines.contains(selectedText) ? "bookmark.fill" : "bookmark")
                                        .foregroundColor(.blue)
                                        .padding()
                                }

                                // Pulsante per chiudere l'editor
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
                    ForEach(Array(searchTabs.enumerated()), id: \.element) { index, searchTerm in
                             List {
                                 
                                 ForEach(textRows(for: searchTerm), id: \.id) { row in
                                    VStack {
                                        HStack {
                                            if(UserDefaults.standard.bool(forKey: "lineNumber")) {
                                                Text("\(row.lineNumber).").font(.system(size: textSize()))
                                            }
                                            Text(makeAttributedString(fullText: row.text, highlight: searchTerm, isCaseSensitive: UserDefaults.standard.bool(forKey: "caseSensitiveSearch")))
                                                .background(row.text == messageMaxLine ? Color.red : Color.clear)
                                                .font(.system(size: textSize()))
                                                .onTapGesture {
                                                    if(showingEditor) {
                                                        showingEditor = false
                                                    } else {
                                                        self.selectedText = row.text
                                                        self.showingEditor = true
                                                    }
                                                }.frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        if(fileContent.keys.count > 1 && !row.file.isEmpty) {
                                            Text("from: \(row.file):\(row.lineNumber)").font(.system(size: textSize() - 2)).italic()
                                                .foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .trailing)
                                        }

                                    }
                                }
                            }.frame(maxHeight: .infinity) // Assicura che la ScrollView utilizzi lo spazio disponibile
                                .onOpenURL(perform: { url in
                                    print("openUrl \(url)")
                                    let currentTime = Date()
                                    let selectionInterval: TimeInterval = 5.0 // intervallo di tempo per considerare una selezione come unica (in secondi)
                                    
                                    if let lastSelectionDate = lastSelectionDate, currentTime.timeIntervalSince(lastSelectionDate) < selectionInterval {

                                    } else {
                                        // Nuova selezione
                                        fileContent.removeAll()
                                    }
                                    
                                    lastSelectionDate = currentTime
                                    
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let loadedContent = loadFileContent(from: url)
                                        
                                        DispatchQueue.main.async {
                                            fileContent[url.lastPathComponent] =  loadedContent
                                        }
                                    }
                                }).tabItem {
                                    Label(searchTerm == "" ? "Original" : searchTerm, systemImage: "doc.text.magnifyingglass")
                                }.contextMenu {
                                    if(searchTerm != "") {
                                        Button {
                                            if let index = searchTabs.firstIndex(of: searchTerm) {
                                                if(index > 0) {
                                                    searchTabs.remove(at: index)
                                                }
                                            }
                                        } label: {
                                            Label("Close", systemImage: "xmark")
                                        }
                                        Button {
                                            if !searchTabs.isEmpty && searchTabs.count > 1 {
                                                // Rimuovi gli elementi dall'indice 1 fino all'ultimo
                                                searchTabs.removeSubrange(1...)
                                            }
                                        } label: {
                                            Label("Close All", systemImage: "xmark")
                                        }
                                        Button {
                                            fileContent.removeAll()
                                            fileContent = ["": fileGrepped(for: searchTerm)]
                                            if !searchTabs.isEmpty && searchTabs.count > 1 {
                                                // Rimuovi gli elementi dall'indice 1 fino all'ultimo
                                                searchTabs.removeSubrange(1...)
                                            }
                                        } label: {
                                            Label("Use as a new source", systemImage: "doc.badge.plus")
                                        }
                                        Button {
                                            self.showSaveDocumentPicker = true
                                            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                                            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("ExportedFile.txt")
                                            
                                            // Scrivi il contenuto nel file temporaneo
                                            do {
                                                try fileGrepped(for: searchTerm).write(to: temporaryFileURL, atomically: true, encoding: .utf8)
                                            } catch {
                                                print("Errore durante la scrittura del file: \(error)")
                                            }
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                    } else {
                                        Button {
                                            fileContent.removeAll()
                                            if let clipboardString = UIPasteboard.general.string {
                                                fileContent = ["": clipboardString]
                                            } else {
                                                fileContent = ["": "Clipboard is empty or does not contain text."]
                                            }
                                            if !searchTabs.isEmpty && searchTabs.count > 1 {
                                                // Rimuovi gli elementi dall'indice 1 fino all'ultimo
                                                searchTabs.removeSubrange(1...)
                                            }
                                        } label: {
                                            Label("Paste from Clipboard", systemImage: "clipboard")
                                        }
                                    }
                                }.tag(Int(searchTabs.firstIndex(of: searchTerm) ?? 0))
                        }
                }
                
                HStack {
                    Button(action: {
                                   showingFilePicker = true
                                    searchText = ""
                                    submittedText = ""
                                    bookmarkedLines = []
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
                               }.onChange(of: showingSettingLinesBeforeAfter) { newValue in
                                   if sheetWasPresented && !newValue {
                                       sheetWasPresented = false
                                       submitSearch()
                                   }
                               }
                    
                    TextField("Search", text: $userInput, onEditingChanged: { editing in
                                    self.isEditing = editing
                                    if editing {
                                        // L'utente ha iniziato la modifica
                                        print("Inizio modifica")
                                    } else {
                                        // L'utente ha terminato la modifica
                                        print("Fine modifica")
                                    }
                                })
                                .padding()
                                .accessibilityIdentifier("searchBox")
                                .submitLabel(.done) // Imposta la label del tasto di invio a "Done"
                                .onSubmit {
                                    submitSearch()
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
                .sheet(isPresented: $showSaveDocumentPicker) {
                   SaveDocumentPicker(activityItems: [URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ExportedFile.txt")], applicationActivities: nil)
                }   
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity).onAppear(perform: {
                if(firstLoad == false) {
                    addNewSearchTab(searchText: "")
                    firstLoad = true
                }
            })
    }
    func submitSearch() {
        if(userInput.count == 0) {
            return
        }
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
    
    func addNewSearchTab(searchText: String) {
        if(searchText.isEmpty && searchTabs.count == 1) {
            return // only one "Original"
        }
        searchTabs.append(searchText) // Aggiungi il nuovo termine di ricerca alla lista dei tab
        selectedTabIndex = searchTabs.count - 1
        //print("selectedTabIndex \(selectedTabIndex)")
    }

    private func filteredContent(for submittedText: String) -> [(lineNumber: Int, text: String, file: String, id: UUID)] {
        let isReverse = UserDefaults.standard.bool(forKey: "reverse")
        let linesBefore = UserDefaults.standard.integer(forKey: "linesBefore")
        let linesAfter = UserDefaults.standard.integer(forKey: "linesAfter")
        let isCaseSensitive = UserDefaults.standard.bool(forKey: "caseSensitiveSearch")
        let isInverted = UserDefaults.standard.bool(forKey: "inverted")
        let isRegEx = UserDefaults.standard.bool(forKey: "regEx")
        
        let searchTerm = isCaseSensitive ? submittedText : submittedText.lowercased()
        let regex: NSRegularExpression?
        if isRegEx {
            regex = try? NSRegularExpression(pattern: searchTerm, options: isCaseSensitive ? [] : .caseInsensitive)
        } else {
            regex = nil
        }
        
        let bookmarkedSet = Set(bookmarkedLines)
        
        let filteredLines = fileContent.flatMap { (key, value) -> [(lineNumber: Int, text: String, file: String, id: UUID)] in
            let lines = value.components(separatedBy: "\n")
            
            return lines.enumerated().lazy.flatMap { (index, line) -> [(lineNumber: Int, text: String, file: String, id: UUID)] in
                let doesMatch: Bool
                if submittedText.isEmpty {
                    doesMatch = true
                } else if let regex = regex {
                    let range = NSRange(location: 0, length: line.utf16.count)
                    doesMatch = regex.firstMatch(in: line, options: [], range: range) != nil
                } else if isCaseSensitive {
                    doesMatch = line.contains(searchTerm)
                } else {
                    doesMatch = line.lowercased().contains(searchTerm)
                }
                
                let finalMatch = isInverted ? !doesMatch : doesMatch
                
                if finalMatch || bookmarkedSet.contains(line) {
                    let startRange = max(0, index - linesBefore)
                    let endRange = min(lines.count, index + linesAfter + 1)
                    return (startRange..<endRange).map { contextIndex in
                        (lineNumber: contextIndex + 1, text: lines[contextIndex], file: key, id: UUID())
                    }
                }
                return []
            }
        }
        
        var result = Array(filteredLines.prefix(maxLine()))
        
        if result.count >= maxLine() {
            result.append((lineNumber: -1, text: messageMaxLine, file: "", id: UUID()))
        }
        
        if isReverse {
            result.reverse()
        }
        
        return result
    }



    func loadFileContent(from url: URL) -> String {
        bookmarkedLines = []
        searchTabs.removeAll()
        addNewSearchTab(searchText: "")
        // Assumi che questa funzione legga il contenuto del file e lo ritorni come String
        do {
            return try FileHelper.readWithMultipleEncodings(from: url)
        } catch {
            print("Errore nella lettura del file: \(error)")
            return "Errore nella lettura del file \(error.localizedDescription)"
        }
    }         
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContent: [String: String]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.plainText], asCopy: true)
        picker.allowsMultipleSelection = true
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
            var fC: [String: String] = [:]
            for url in urls {
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                do {
                    // Leggi il contenuto del file selezionato
                    let fileContent = try FileHelper.readWithMultipleEncodings(from: url)
                    fC[url.lastPathComponent] = fileContent
                } catch {
                    print("Unable to read file content: \(error)")
                }
                
                //print(fC)
                DispatchQueue.main.async {
                    self.parent.fileContent = fC
                }
            }
        }
    }
}

class FileHelper {
    public static func readWithMultipleEncodings(from fileURL: URL) throws -> String {
        let encodings: [String.Encoding] = [
            .ascii,
            .nextstep,
            .japaneseEUC,
            .utf8,
            .isoLatin1,
            .symbol,
            .nonLossyASCII,
            .shiftJIS,
            .isoLatin2,
            .unicode,
            .windowsCP1251,
            .windowsCP1252,
            .windowsCP1253,
            .windowsCP1254,
            .windowsCP1250,
            .iso2022JP,
            .macOSRoman,
            .utf16,
            .utf16BigEndian,
            .utf16LittleEndian,
            .utf32,
            .utf32BigEndian,
            .utf32LittleEndian
        ]
        
        var fileContent: String = ""
        
        for encoding in encodings {
            do {
                fileContent = try String(contentsOf: fileURL, encoding: encoding)
                break // Stop iterating if successful
            } catch {
                print("Failed to read file content with encoding \(encoding): \(error)")
            }
        }
        
        /*guard !fileContent.isEmpty else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to read file with any encoding."])
        }*/
        
        return fileContent
    }   
}
