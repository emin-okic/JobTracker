//
//  ApplicationDetailViewModel.swift
//  job-tracker-app
//
//  Introduced by Assistant to separate view logic from UI (MVVM).
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class ApplicationDetailViewModel: ObservableObject {
    @Published var showingEdit: Bool = false
    @Published var showingDeleteConfirm: Bool = false
    @Published var showShare: Bool = false

    let policy: NotesEditingPolicy
    private(set) var app: JobApplication

    init(app: JobApplication, policy: NotesEditingPolicy = .lockedIfExisting) {
        self.app = app
        self.policy = policy
    }

    var shareText: String {
        var parts: [String] = []
        parts.append("Position: \(app.position)")
        parts.append("Company: \(app.company)")
        if let location = app.location { parts.append("Location: \(location)") }
        parts.append("Status: \(app.status)")
        parts.append("Applied: \(app.dateApplied.formatted(date: .abbreviated, time: .omitted))")
        if let notes = app.notes, !notes.isEmpty { parts.append("Notes: \(notes)") }
        return parts.joined(separator: "\n")
    }

    func update(with updated: JobApplication) {
        app.company = updated.company
        app.position = updated.position
        app.status = updated.status
        app.dateApplied = updated.dateApplied
        app.location = updated.location
        // Respect policy: if existing notes are non-empty and policy locks, keep original notes
        if policy.isEditable(existingNotes: app.notes) {
            app.notes = updated.notes
        }
        app.companyURL = updated.companyURL
        app.jobURL = updated.jobURL
    }
}

