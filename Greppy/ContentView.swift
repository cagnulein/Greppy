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
                        let rows = textRows(for: searchTerm)
                        let uniqueFiles = Set(rows.map { $0.file }).count

                        List {

                             ForEach(rows, id: \.id) { row in
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
                                    if(uniqueFiles > 1 && !row.file.isEmpty) {
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
                                            // loadedContent è ora un dictionary che può contenere più file
                                            for (filename, content) in loadedContent {
                                                fileContent[filename] = content
                                            }
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
                                            let allFilteredLines = filteredContent(for: searchTerm).map { $0.text }
                                            for line in allFilteredLines {
                                                if line != messageMaxLine && !bookmarkedLines.contains(line) {
                                                    bookmarkedLines.append(line)
                                                }
                                            }
                                        } label: {
                                            Label("Bookmark all the lines", systemImage: "bookmark")
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
            var result: [(lineNumber: Int, text: String, file: String, id: UUID)] = []
            var matchIndices: [Int] = []

            // Trova tutti i match
            for (index, line) in lines.enumerated() {
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
                    matchIndices.append(index)
                }
            }

            // Processa i match e aggiungi le linee prima e dopo
            for matchIndex in matchIndices {
                let startIndex = max(0, matchIndex - linesBefore)
                let endIndex = min(lines.count - 1, matchIndex + linesAfter)

                for index in startIndex...endIndex {
                    let line = lines[index]
                    result.append((lineNumber: index + 1, text: line, file: key, id: UUID()))
                }
            }

            // Rimuovi i duplicati mantenendo l'ordine
            var uniqueResult: [(lineNumber: Int, text: String, file: String, id: UUID)] = []
            var seenLineNumbers = Set<Int>()
            for item in result {
                if !seenLineNumbers.contains(item.lineNumber) {
                    uniqueResult.append(item)
                    seenLineNumbers.insert(item.lineNumber)
                }
            }

            return uniqueResult
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

    func loadFileContent(from url: URL) -> [String: String] {
        bookmarkedLines = []
        searchTabs.removeAll()
        addNewSearchTab(searchText: "")

        var result: [String: String] = [:]

        do {
            // Controlla se è un file ZIP usando estensione e magic bytes
            let isZip = url.pathExtension.lowercased() == "zip" || FileHelper.isZipFile(url)

            if isZip {
                print("📦 Detected ZIP file, extracting...")
                // Estrai e leggi i file dallo ZIP
                let extractedFiles = try FileHelper.extractAndReadZip(from: url)
                print("📦 Extracted \(extractedFiles.count) files from ZIP")

                if extractedFiles.isEmpty {
                    // Show visible message in UI
                    result["⚠️ \(url.lastPathComponent)"] = """
                    ⚠️ NO TEXT FILES FOUND IN ZIP

                    File name: \(url.lastPathComponent)
                    The ZIP was read but contains no readable text files.

                    Possible causes:
                    - ZIP contains only binary files (images, executables, etc.)
                    - Files are in a non-text format
                    - Decompression error

                    Check console logs for details.
                    """
                } else {
                    for (filename, content) in extractedFiles {
                        let displayName = "\(url.lastPathComponent)/\(filename)"
                        result[displayName] = content
                        print("📄 Loaded: \(displayName) (\(content.count) chars)")
                    }
                }
            } else {
                print("📄 Loading text file...")
                // Leggi come file di testo normale
                let content = try FileHelper.readWithMultipleEncodings(from: url)
                result[url.lastPathComponent] = content
                print("📄 Loaded: \(url.lastPathComponent) (\(content.count) chars)")
            }
        } catch {
            print("❌ Error loading file: \(error)")
            result["❌ ERROR: \(url.lastPathComponent)"] = """
            ❌ ERROR OPENING FILE

            File name: \(url.lastPathComponent)
            Error: \(error.localizedDescription)

            Technical details:
            \(error)

            If this is a ZIP file, check that it's not corrupted.
            If this is a text file, check the encoding.
            """
        }

        return result
    }         
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContent: [String: String]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.plainText, UTType.zip, UTType.data, UTType.content], asCopy: true)
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
            print("📂 DocumentPicker: Selected \(urls.count) file(s)")
            var fC: [String: String] = [:]

            for url in urls {
                print("📄 Processing: \(url.lastPathComponent)")
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                do {
                    // Controlla se è un file ZIP usando sia estensione che magic bytes
                    let isZip = url.pathExtension.lowercased() == "zip" || FileHelper.isZipFile(url)
                    print("🔍 isZip: \(isZip) (extension: \(url.pathExtension))")

                    if isZip {
                        print("📦 Processing as ZIP file...")
                        // Decomprime lo ZIP e leggi tutti i file di testo
                        let extractedFiles = try FileHelper.extractAndReadZip(from: url)
                        print("📦 Extracted \(extractedFiles.count) files from ZIP")

                        if extractedFiles.isEmpty {
                            // Show visible message in UI
                            fC["⚠️ \(url.lastPathComponent)"] = """
                            ⚠️ NO TEXT FILES FOUND IN ZIP

                            File name: \(url.lastPathComponent)
                            The ZIP was read but contains no readable text files.

                            Possible causes:
                            - ZIP contains only binary files (images, executables, etc.)
                            - Files are in a non-text format
                            - Decompression error

                            Check console logs for details.
                            """
                        } else {
                            for (filename, content) in extractedFiles {
                                // Usa il nome del file con il formato "archive.zip/file.txt"
                                let displayName = "\(url.lastPathComponent)/\(filename)"
                                fC[displayName] = content
                                print("✅ Added to fileContent: \(displayName)")
                            }
                        }
                    } else {
                        print("📄 Processing as text file...")
                        // Leggi il contenuto del file selezionato
                        let fileContent = try FileHelper.readWithMultipleEncodings(from: url)
                        fC[url.lastPathComponent] = fileContent
                        print("✅ Loaded: \(url.lastPathComponent) (\(fileContent.count) chars)")
                    }
                } catch {
                    print("❌ Unable to read file content: \(error)")
                    // Show error in UI
                    fC["❌ ERROR: \(url.lastPathComponent)"] = """
                    ❌ ERROR OPENING FILE

                    File name: \(url.lastPathComponent)
                    Error: \(error.localizedDescription)

                    Technical details:
                    \(error)

                    If this is a ZIP file, check that it's not corrupted.
                    If this is a text file, check the encoding.
                    """
                }

                print("📊 Total files in dictionary: \(fC.count)")
                DispatchQueue.main.async {
                    print("🔄 Updating parent.fileContent on main thread")
                    self.parent.fileContent = fC
                    print("✅ parent.fileContent updated with \(fC.count) files")
                }
            }
        }
    }
}

class FileHelper {
    // Controlla se un file è un ZIP usando i magic bytes (signature)
    public static func isZipFile(_ url: URL) -> Bool {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            // Leggi i primi 4 byte per controllare la signature ZIP
            let data = handle.readData(ofLength: 4)

            // ZIP signature: 0x50 0x4B 0x03 0x04 ("PK\x03\x04")
            if data.count >= 4 {
                let bytes = [UInt8](data)
                return bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04
            }
        } catch {
            print("Error checking if file is ZIP: \(error)")
        }
        return false
    }

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

    public static func extractAndReadZip(from zipURL: URL) throws -> [String: String] {
        var extractedContents: [String: String] = [:]
        var allFilesFound: [String] = []
        var failedFiles: [(String, String)] = [] // (filename, reason)
        var debugLog: [String] = [] // Collect all log messages

        let log = { (message: String) in
            print(message)
            debugLog.append(message)
        }

        log("🔍 Starting ZIP extraction from: \(zipURL.lastPathComponent)")

        // Leggi il file ZIP come dati binari
        let zipData = try Data(contentsOf: zipURL)
        log("📊 ZIP file size: \(zipData.count) bytes")

        // Cerca i local file headers nel file ZIP
        let localFileHeaderSignature: UInt32 = 0x04034b50
        var offset = 0
        var filesFound = 0

        while offset < zipData.count - 30 {
            // Leggi la signature a 4 byte
            let signature = zipData.withUnsafeBytes { buffer in
                buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
            }

            if signature == localFileHeaderSignature {
                filesFound += 1
                // Abbiamo trovato un local file header
                // Offset 26-28: lunghezza nome file (2 byte)
                let filenameLength = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: offset + 26, as: UInt16.self))
                }

                // Offset 28-30: lunghezza extra field (2 byte)
                let extraFieldLength = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: offset + 28, as: UInt16.self))
                }

                // Offset 18-22: dimensione compressa (4 byte)
                let compressedSize = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: offset + 18, as: UInt32.self))
                }

                // Offset 22-26: dimensione non compressa (4 byte)
                let uncompressedSize = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: offset + 22, as: UInt32.self))
                }

                // Offset 8-10: metodo compressione (2 byte) - 0=stored, 8=deflated
                let compressionMethod = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: offset + 8, as: UInt16.self))
                }

                // Leggi il nome del file
                let filenameStart = offset + 30
                let filenameData = zipData.subdata(in: filenameStart..<(filenameStart + filenameLength))
                guard let filename = String(data: filenameData, encoding: .utf8) else {
                    log("⚠️  Cannot decode filename at offset \(offset)")
                    offset += 30 + filenameLength + extraFieldLength + compressedSize
                    continue
                }

                log("📁 Found: \(filename)")
                log("   Compression method: \(compressionMethod) (0=stored, 8=DEFLATE)")
                log("   Compressed size from local header: \(compressedSize) bytes")
                log("   Uncompressed size from local header: \(uncompressedSize) bytes")

                // Track all files found
                allFilesFound.append(filename)

                // Salta i file directory (terminano con /)
                if filename.hasSuffix("/") {
                    log("📂 Skipping directory: \(filename)")
                    offset += 30 + filenameLength + extraFieldLength + compressedSize
                    continue
                }

                // Se compressed size è 0, il file usa data descriptor
                // Dobbiamo saltarlo e usare il Central Directory invece
                if compressedSize == 0 {
                    log("⚠️  Compressed size is 0 - file uses data descriptor")
                    log("   Skipping local header, will read from Central Directory instead")
                    failedFiles.append((filename, "Local header has size 0 - need Central Directory"))

                    // Cerca il prossimo local file header invece di calcolare l'offset
                    offset += 30 + filenameLength + extraFieldLength
                    continue
                }

                // Posizione dei dati compressi
                let dataStart = offset + 30 + filenameLength + extraFieldLength
                let dataEnd = dataStart + compressedSize

                if dataEnd <= zipData.count {
                    let compressedData = zipData.subdata(in: dataStart..<dataEnd)

                    var decompressedData: Data?

                    if compressionMethod == 8 {
                        // DEFLATE compression
                        log("🔄 Decompressing with DEFLATE...")
                        decompressedData = decompressData(compressedData)
                        if let data = decompressedData {
                            log("✅ Decompressed to \(data.count) bytes (expected \(uncompressedSize))")

                            // Show hex dump of first 32 bytes
                            let previewLength = min(32, data.count)
                            let previewBytes = data.prefix(previewLength).map { String(format: "%02X", $0) }.joined(separator: " ")
                            log("   First \(previewLength) bytes (hex): \(previewBytes)")

                            // Try to show as ASCII for quick check
                            let asciiPreview = data.prefix(previewLength).map { byte -> String in
                                if byte >= 32 && byte <= 126 {
                                    return String(UnicodeScalar(byte))
                                } else if byte == 10 {
                                    return "\\n"
                                } else if byte == 13 {
                                    return "\\r"
                                } else if byte == 9 {
                                    return "\\t"
                                } else {
                                    return "·"
                                }
                            }.joined()
                            log("   First \(previewLength) bytes (ASCII): \(asciiPreview)")
                        } else {
                            log("❌ DEFLATE decompression failed")
                            failedFiles.append((filename, "DEFLATE decompression failed"))
                        }
                    } else if compressionMethod == 0 {
                        // Stored (no compression)
                        log("📋 File stored without compression")
                        decompressedData = compressedData

                        // Show hex dump of first 32 bytes
                        let previewLength = min(32, compressedData.count)
                        let previewBytes = compressedData.prefix(previewLength).map { String(format: "%02X", $0) }.joined(separator: " ")
                        log("   First \(previewLength) bytes (hex): \(previewBytes)")
                    } else {
                        log("⚠️  Unsupported compression method: \(compressionMethod)")
                        failedFiles.append((filename, "Unsupported compression method \(compressionMethod)"))
                    }

                    if let data = decompressedData {
                        log("🔤 Attempting to decode \(data.count) bytes as text...")
                        // Prova a convertire in stringa usando vari encoding
                        if let content = tryDecodeString(from: data, log: log) {
                            extractedContents[filename] = content
                            log("✅ Successfully loaded \(filename) (\(content.count) chars)")
                        } else {
                            log("❌ Cannot decode \(filename) as text (data size: \(data.count) bytes)")
                            log("   This is probably a binary file, not a text file")
                            failedFiles.append((filename, "Cannot decode as text (probably binary file)"))
                        }
                    }
                } else {
                    log("❌ Data range out of bounds for \(filename)")
                }

                offset += 30 + filenameLength + extraFieldLength + compressedSize
            } else {
                offset += 1
            }
        }

        log("🎉 ZIP extraction complete: \(filesFound) files found, \(extractedContents.count) text files loaded")

        // Se ci sono file falliti con size 0, proviamo a leggerli dal Central Directory
        if !failedFiles.isEmpty && failedFiles.contains(where: { $0.1.contains("size 0") }) {
            log("")
            log("📖 Reading Central Directory for files with size 0...")

            // Cerca End of Central Directory Record (EOCD) dalla fine del file
            // Signature: 0x06054b50
            let eocdSignature: UInt32 = 0x06054b50
            var eocdOffset = -1

            // Cerca dalla fine (max 65KB indietro per il commento)
            let searchStart = max(0, zipData.count - 65536)
            for i in stride(from: zipData.count - 22, through: searchStart, by: -1) {
                if i + 4 <= zipData.count {
                    let sig = zipData.withUnsafeBytes { buffer in
                        buffer.loadUnaligned(fromByteOffset: i, as: UInt32.self)
                    }
                    if sig == eocdSignature {
                        eocdOffset = i
                        log("✅ Found End of Central Directory at offset \(i)")
                        break
                    }
                }
            }

            if eocdOffset >= 0 {
                // Leggi offset del Central Directory (offset 16-20 in EOCD)
                let centralDirOffset = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: eocdOffset + 16, as: UInt32.self))
                }

                let centralDirSize = zipData.withUnsafeBytes { buffer in
                    Int(buffer.loadUnaligned(fromByteOffset: eocdOffset + 12, as: UInt32.self))
                }

                log("📁 Central Directory at offset \(centralDirOffset), size \(centralDirSize) bytes")

                // Leggi il Central Directory
                var cdOffset = centralDirOffset
                let cdSignature: UInt32 = 0x02014b50

                while cdOffset < centralDirOffset + centralDirSize {
                    let sig = zipData.withUnsafeBytes { buffer in
                        buffer.loadUnaligned(fromByteOffset: cdOffset, as: UInt32.self)
                    }

                    if sig == cdSignature {
                        // Central Directory File Header trovato
                        let cdCompMethod = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 10, as: UInt16.self))
                        }

                        let cdCompSize = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 20, as: UInt32.self))
                        }

                        let cdUncompSize = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 24, as: UInt32.self))
                        }

                        let cdFilenameLen = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 28, as: UInt16.self))
                        }

                        let cdExtraLen = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 30, as: UInt16.self))
                        }

                        let cdCommentLen = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 32, as: UInt16.self))
                        }

                        let localHeaderOffset = zipData.withUnsafeBytes { buffer in
                            Int(buffer.loadUnaligned(fromByteOffset: cdOffset + 42, as: UInt32.self))
                        }

                        // Nome file
                        let cdFilenameData = zipData.subdata(in: (cdOffset + 46)..<(cdOffset + 46 + cdFilenameLen))
                        guard let cdFilename = String(data: cdFilenameData, encoding: .utf8) else {
                            cdOffset += 46 + cdFilenameLen + cdExtraLen + cdCommentLen
                            continue
                        }

                        // Salta directory
                        if cdFilename.hasSuffix("/") {
                            cdOffset += 46 + cdFilenameLen + cdExtraLen + cdCommentLen
                            continue
                        }

                        log("")
                        log("📄 Central Directory entry: \(cdFilename)")
                        log("   Compressed: \(cdCompSize) bytes, Uncompressed: \(cdUncompSize) bytes")
                        log("   Local header at offset: \(localHeaderOffset)")

                        // Ora leggi i dati dalla posizione del local header
                        if localHeaderOffset >= 0 && localHeaderOffset < zipData.count {
                            // Salta il local header per arrivare ai dati
                            let lfhFilenameLen = zipData.withUnsafeBytes { buffer in
                                Int(buffer.loadUnaligned(fromByteOffset: localHeaderOffset + 26, as: UInt16.self))
                            }

                            let lfhExtraLen = zipData.withUnsafeBytes { buffer in
                                Int(buffer.loadUnaligned(fromByteOffset: localHeaderOffset + 28, as: UInt16.self))
                            }

                            let dataOffset = localHeaderOffset + 30 + lfhFilenameLen + lfhExtraLen
                            let dataEnd = dataOffset + cdCompSize

                            if dataEnd <= zipData.count && cdCompSize > 0 {
                                let compData = zipData.subdata(in: dataOffset..<dataEnd)

                                var decompData: Data?
                                if cdCompMethod == 8 {
                                    log("🔄 Decompressing with DEFLATE...")
                                    decompData = decompressData(compData)
                                } else if cdCompMethod == 0 {
                                    log("📋 File stored without compression")
                                    decompData = compData
                                }

                                if let data = decompData {
                                    log("✅ Decompressed to \(data.count) bytes")

                                    if let content = tryDecodeString(from: data, log: log) {
                                        extractedContents[cdFilename] = content
                                        log("✅ Successfully loaded \(cdFilename) from Central Directory!")

                                        // Rimuovi da failedFiles
                                        if let index = failedFiles.firstIndex(where: { $0.0 == cdFilename }) {
                                            failedFiles.remove(at: index)
                                        }
                                    }
                                }
                            }
                        }

                        cdOffset += 46 + cdFilenameLen + cdExtraLen + cdCommentLen
                    } else {
                        break
                    }
                }
            } else {
                log("❌ Could not find End of Central Directory")
            }
        }

        if !failedFiles.isEmpty {
            log("⚠️  Failed to load \(failedFiles.count) file(s):")
            for (filename, reason) in failedFiles {
                log("   - \(filename): \(reason)")
            }
        }

        // Add debug log only if there were errors
        if !failedFiles.isEmpty {
            let logContent = debugLog.joined(separator: "\n")
            extractedContents["🔍 Debug Log.txt"] = """
            DEBUG LOG - ZIP EXTRACTION
            ==========================
            File: \(zipURL.lastPathComponent)
            Date: \(Date())

            \(logContent)

            ==========================
            END OF LOG
            """
        }

        return extractedContents
    }

    private static func decompressData(_ data: Data) -> Data? {
        let bufferSize = 64 * 1024
        var decompressedData = Data()

        data.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
            guard let baseAddress = inputPointer.baseAddress else { return }

            var stream = z_stream()
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: baseAddress.assumingMemoryBound(to: UInt8.self))
            stream.avail_in = uint(data.count)

            // Inizializza per DEFLATE raw (senza header zlib)
            if inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK {
                defer { inflateEnd(&stream) }

                var buffer = [UInt8](repeating: 0, count: bufferSize)
                var finished = false

                while !finished {
                    let status = buffer.withUnsafeMutableBytes { bufferPointer -> Int32 in
                        stream.next_out = bufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        stream.avail_out = uint(bufferSize)
                        return inflate(&stream, Z_NO_FLUSH)
                    }

                    let bytesWritten = bufferSize - Int(stream.avail_out)
                    if bytesWritten > 0 {
                        decompressedData.append(buffer, count: bytesWritten)
                    }

                    if status == Z_STREAM_END {
                        finished = true
                    } else if status != Z_OK || stream.avail_out != 0 {
                        finished = true
                    }
                }
            }
        }

        return decompressedData.isEmpty ? nil : decompressedData
    }

    private static func tryDecodeString(from data: Data, log: ((String) -> Void)? = nil) -> String? {
        // Use same encodings as readWithMultipleEncodings for consistency
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

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                // Don't check isEmpty - some files might be legitimately empty
                if string.count > 0 {
                    let message = "   ✅ Decoded successfully with encoding: \(encoding)"
                    if let log = log {
                        log(message)
                    } else {
                        print(message)
                    }
                    return string
                }
            }
        }

        let message = "   ❌ Failed with all \(encodings.count) encodings"
        if let log = log {
            log(message)
        } else {
            print(message)
        }
        return nil
    }
}
