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

enum ApplicationActivityType: String, CaseIterable, Identifiable {
    case note
    case followUp
    case interview
    case offer
    case rejection

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note:
            return "Note"
        case .followUp:
            return "Follow-up"
        case .interview:
            return "Interview"
        case .offer:
            return "Offer"
        case .rejection:
            return "Rejection"
        }
    }

    var systemImage: String {
        switch self {
        case .note:
            return "text.bubble"
        case .followUp:
            return "arrowshape.turn.up.right"
        case .interview:
            return "person.2"
        case .offer:
            return "checkmark.seal"
        case .rejection:
            return "xmark.octagon"
        }
    }

    func formattedBody(from body: String) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard self != .note else { return trimmed }
        guard !trimmed.isEmpty else { return title }
        return "\(title): \(trimmed)"
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

    static func initialActivity(company: String, position: String, status: String, at date: Date) -> ApplicationNote {
        let company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let position = position.trimmingCharacters(in: .whitespacesAndNewlines)
        let status = status.trimmingCharacters(in: .whitespacesAndNewlines)

        if status == "Applied" {
            return ApplicationNote(createdAt: date, body: "Applied to \(company) for \(position).")
        }

        return ApplicationNote(createdAt: date, body: "Added application for \(position) at \(company) with status \(status).")
    }

    static func statusChange(from oldStatus: String, to newStatus: String, at date: Date = Date()) -> ApplicationNote? {
        let oldStatus = oldStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        let newStatus = newStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard oldStatus != newStatus else { return nil }
        return ApplicationNote(createdAt: date, body: "Status changed from \(oldStatus) to \(newStatus).")
    }

    static func activitiesForNewApplication(company: String, position: String, status: String, dateApplied: Date, notes: String?) -> [ApplicationNote] {
        var activities = [initialActivity(company: company, position: position, status: status, at: dateApplied)]
        let trimmedNotes = (notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            activities.append(ApplicationNote(body: trimmedNotes))
        }
        return activities
    }
}
