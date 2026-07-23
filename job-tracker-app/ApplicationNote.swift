//
//  ApplicationNote.swift
//  job-tracker-app
//
//  Created by Assistant
//

import Foundation

struct ApplicationNote: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    var body: String

    init(id: UUID = UUID(), createdAt: Date = Date(), body: String) {
        self.id = id
        self.createdAt = createdAt
        self.body = body
    }
}

extension ApplicationNote {
    private struct StoredNotes: Codable {
        var notes: [ApplicationNote]
    }

    static func decoded(from storedValue: String?, legacyDate: Date) -> [ApplicationNote] {
        let trimmed = (storedValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if let data = trimmed.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let storedNotes = try? decoder.decode(StoredNotes.self, from: data) {
                return storedNotes.notes
            }

            if let notes = try? decoder.decode([ApplicationNote].self, from: data) {
                return notes
            }
        }

        return [ApplicationNote(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, createdAt: legacyDate, body: trimmed)]
    }

    static func encoded(_ notes: [ApplicationNote]) -> String? {
        guard !notes.isEmpty else { return nil }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(StoredNotes(notes: notes)) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
