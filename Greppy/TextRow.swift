//
//  TextRow.swift
//  Greppy
//
//  Created by Roberto Viola on 10/05/24.
//

import Foundation
class TextRows {
    var rows: [TextRow] = []
    init(rows: [TextRow]) {
        self.rows = rows
    }
}

class TextRow {
    var submittedText: String
    var lineNumber: Int
    var text: String
    var file: String
    var id: UUID

    init(submittedText: String, lineNumber: Int, text: String, file: String, id: UUID) {
        self.submittedText = submittedText
        self.lineNumber = lineNumber
        self.text = text
        self.file = file
        self.id = id
    }
}
