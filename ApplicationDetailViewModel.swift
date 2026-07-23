//
//  ApplicationDetailViewModel.swift
//  job-tracker-app
//
//  Introduced by Assistant to separate view logic from UI (MVVM).
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ApplicationDetailViewModel: ObservableObject {
    @Published var showingEdit: Bool = false
    @Published var showingDeleteConfirm: Bool = false
    @Published var showShare: Bool = false
    @Published var draftNote: String = ""

    let policy: NotesEditingPolicy
    private(set) var app: JobApplication

    init(app: JobApplication, policy: NotesEditingPolicy = .lockedIfExisting) {
        self.app = app
        self.policy = policy
    }

    var notes: [ApplicationNote] {
        ApplicationNote.decoded(from: app.notes, legacyDate: app.dateApplied)
            .sorted { $0.createdAt < $1.createdAt }
    }

    var canAddNote: Bool {
        !draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var shareText: String {
        var parts: [String] = []
        parts.append("Position: \(app.position)")
        parts.append("Company: \(app.company)")
        if let location = app.location { parts.append("Location: \(location)") }
        parts.append("Status: \(app.status)")
        parts.append("Applied: \(app.dateApplied.formatted(date: .abbreviated, time: .omitted))")
        if !notes.isEmpty {
            let noteText = notes.map { note in
                "- \(note.createdAt.formatted(date: .abbreviated, time: .shortened)): \(note.body)"
            }.joined(separator: "\n")
            parts.append("Notes:\n\(noteText)")
        }
        return parts.joined(separator: "\n")
    }

    func update(with updated: JobApplication) {
        app.company = updated.company
        app.position = updated.position
        app.status = updated.status
        app.dateApplied = updated.dateApplied
        app.location = updated.location
        // Respect policy: if existing notes are non-empty and policy locks, keep original notes.
        if policy.isEditable(existingNotes: app.notes) {
            app.notes = updated.notes
        }
        app.companyURL = updated.companyURL
        app.jobURL = updated.jobURL
        objectWillChange.send()
    }

    func addDraftNote() {
        let trimmed = draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updatedNotes = notes
        updatedNotes.append(ApplicationNote(body: trimmed))
        app.notes = ApplicationNote.encoded(updatedNotes)
        draftNote = ""
        objectWillChange.send()
    }

    func deleteNote(id: ApplicationNote.ID) {
        let updatedNotes = notes.filter { $0.id != id }
        app.notes = ApplicationNote.encoded(updatedNotes)
        objectWillChange.send()
    }
}
