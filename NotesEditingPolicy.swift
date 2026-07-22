//
//  NotesEditingPolicy.swift
//  job-tracker-app
//
//  Introduced by Assistant to enforce read-only behavior for existing notes.
//

import Foundation

/// Describes how the Notes field should behave in editing flows.
enum NotesEditingPolicy {
    /// Notes are always editable.
    case alwaysEditable
    /// If an existing note is present (non-empty), it becomes read-only.
    case lockedIfExisting
}

extension NotesEditingPolicy {
    /// Determines whether the notes should be editable given an existing value.
    /// - Parameter existingNotes: The existing notes value, if any.
    /// - Returns: `true` if notes should be editable, otherwise `false`.
    func isEditable(existingNotes: String?) -> Bool {
        switch self {
        case .alwaysEditable:
            return true
        case .lockedIfExisting:
            let trimmed = (existingNotes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
        }
    }
}
