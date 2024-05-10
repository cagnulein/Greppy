//
//  settingLinesBeforeAfter.swift
//  Greppy
//
//  Created by Roberto Viola on 20/02/24.
//

import SwiftUI
import MessageUI

struct settingLinesBeforeAfterView: View {
    @AppStorage("caseSensitiveSearch") private var caseSensitiveSearch = false
    @AppStorage("linesBefore") private var linesBefore = 0
    @AppStorage("linesAfter") private var linesAfter = 0
    @AppStorage("maxLines") private var maxLines = 2000
    @AppStorage("lineNumber") private var lineNumber = false
    @AppStorage("inverted") private var inverted = false
    @AppStorage("fontSize") private var fontSize = 18
    @AppStorage("regEx") private var regEx = false
    @AppStorage("reverse") private var reverse = false
    @AppStorage("folder") private var folder = false
    
    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "N/A"
    }
    
    private var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "N/A"
    }

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    Toggle("Case Sensitive", isOn: $caseSensitiveSearch).disabled(regEx)
                    Toggle("Invert Match", isOn: $inverted)
                    Toggle("Start from the end of the file", isOn: $reverse)
                    Toggle("Regular Expressions", isOn: $regEx).onChange(of: regEx) { newValue in
                        caseSensitiveSearch = newValue
                    }
                    Toggle("Line Numbers", isOn: $lineNumber)
                    Stepper(value: $fontSize, in: 6...32) {
                        Text("Font Size: \(fontSize)")
                    }                    
                    Stepper(value: $maxLines, in: 1000...10000, step: 100) {
                        Text("Max Output Lines: \(maxLines)")
                    }
                }
                
                Section(header: Text("Folders")) {
                    Toggle("Search in the folder", isOn: $folder)
                }
                
                Section(header: Text("Context Lines")) {
                    Stepper(value: $linesBefore, in: 0...10) {
                        Text("Before: \(linesBefore)")
                    }
                    Stepper(value: $linesAfter, in: 0...10) {
                        Text("After: \(linesAfter)")
                    }
                }
                Section(header: Text("Support")) {
                    Link("Help - Ask me a new feature", destination: URL(string: "mailto:roberto.viola83@gmail.com?subject=greppy%20support")!)
                }
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion + " build " + appBuild)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct settingLinesBeforeAfterView_Previews: PreviewProvider {
    static var previews: some View {
        settingLinesBeforeAfterView()
    }
}
