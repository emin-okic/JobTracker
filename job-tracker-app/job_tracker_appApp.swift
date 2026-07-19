//
//  job_tracker_appApp.swift
//  job-tracker-app
//
//  Created by Emin Okic on 7/18/26.
//

import SwiftUI
import SwiftData

@main
struct job_tracker_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JobApplication.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

