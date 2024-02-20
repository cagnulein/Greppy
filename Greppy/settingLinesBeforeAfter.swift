//
//  settingLinesBeforeAfter.swift
//  Greppy
//
//  Created by Roberto Viola on 20/02/24.
//

import SwiftUI

struct settingLinesBeforeAfterView: View {
    @AppStorage("linesBefore") private var linesBefore = 0
    @AppStorage("linesAfter") private var linesAfter = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Context Lines")) {
                    Stepper(value: $linesBefore, in: 0...10) {
                        Text("Before: \(linesBefore)")
                    }
                    Stepper(value: $linesAfter, in: 0...10) {
                        Text("After: \(linesAfter)")
                    }
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

struct settingLinesBeforeAfterView_Previews: PreviewProvider {
    static var previews: some View {
        settingLinesBeforeAfterView()
    }
}
