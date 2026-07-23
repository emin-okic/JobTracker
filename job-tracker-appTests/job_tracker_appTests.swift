//
//  job_tracker_appTests.swift
//  job-tracker-appTests
//
//  Created by Emin Okic on 7/18/26.
//

import Foundation
import Testing
@testable import job_tracker_app

struct job_tracker_appTests {

    @MainActor
    @Test func applicationNotesDecodeLegacyText() async throws {
        let legacyDate = Date(timeIntervalSince1970: 1_800)

        let notes = ApplicationNote.decoded(from: "Recruiter call went well.", legacyDate: legacyDate)

        #expect(notes.count == 1)
        #expect(notes.first?.body == "Recruiter call went well.")
        #expect(notes.first?.createdAt == legacyDate)
    }

    @MainActor
    @Test func applicationNotesRoundTripMultipleNotes() async throws {
        let firstDate = Date(timeIntervalSince1970: 2_000)
        let secondDate = Date(timeIntervalSince1970: 3_000)
        let originalNotes = [
            ApplicationNote(id: UUID(), createdAt: firstDate, body: "Applied through referral."),
            ApplicationNote(id: UUID(), createdAt: secondDate, body: "Scheduled technical interview.")
        ]

        let encoded = try #require(ApplicationNote.encoded(originalNotes))
        let decoded = ApplicationNote.decoded(from: encoded, legacyDate: .distantPast)

        #expect(decoded == originalNotes)
    }
}
