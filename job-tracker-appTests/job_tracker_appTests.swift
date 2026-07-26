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

    @MainActor
    @Test func newApplicationActivitiesIncludeInitialApplicationAndNote() async throws {
        let appliedDate = Date(timeIntervalSince1970: 4_000)

        let activities = ApplicationNote.activitiesForNewApplication(
            company: "Acme",
            position: "iOS Engineer",
            status: "Applied",
            dateApplied: appliedDate,
            notes: "Sent through referral."
        )

        #expect(activities.count == 2)
        #expect(activities[0].createdAt == appliedDate)
        #expect(activities[0].body == "Applied to Acme for iOS Engineer.")
        #expect(activities[1].body == "Sent through referral.")
    }

    @MainActor
    @Test func updatingStatusAppendsActivityNote() async throws {
        let app = JobApplication(
            company: "Acme",
            position: "iOS Engineer",
            status: "Applied",
            dateApplied: Date(timeIntervalSince1970: 4_000),
            notes: ApplicationNote.encoded([ApplicationNote(body: "Initial note.")])
        )
        let updated = JobApplication(
            id: app.id,
            company: app.company,
            position: app.position,
            status: "Interview",
            dateApplied: app.dateApplied,
            notes: app.notes
        )
        let viewModel = ApplicationDetailViewModel(app: app)

        viewModel.update(with: updated)

        let activities = ApplicationNote.decoded(from: app.notes, legacyDate: app.dateApplied)
        #expect(activities.count == 2)
        #expect(activities.last?.body == "Status changed from Applied to Interview.")
    }

    @MainActor
    @Test func jobTitleSuggestionsPrioritizeTechRolesByDefault() async throws {
        let service = JobTitleSuggestionService()

        let suggestions = service.suggestions(for: "", limit: 5)

        #expect(suggestions.map(\.title) == [
            "Software Engineer",
            "Frontend Engineer",
            "Backend Engineer",
            "Full Stack Engineer",
            "Mobile Engineer"
        ])
    }

    @MainActor
    @Test func jobTitleSuggestionsMatchAliases() async throws {
        let service = JobTitleSuggestionService()

        let suggestions = service.suggestions(for: "sdet", limit: 3)

        #expect(suggestions.first?.title == "Software Development Engineer in Test")
    }

    @MainActor
    @Test func jobTitleSuggestionsIncludeGeneralRoles() async throws {
        let service = JobTitleSuggestionService()

        let suggestions = service.suggestions(for: "nurse", limit: 3)

        #expect(suggestions.first?.title == "Nurse")
    }
}
