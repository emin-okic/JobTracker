//
//  JobApplication.swift
//  job-tracker-app
//
//  Created by MVP generator
//

import Foundation
import SwiftData

@Model
final class JobApplication: Identifiable {
    var id: UUID
    var company: String
    var position: String
    var status: String
    var dateApplied: Date
    var location: String?
    var notes: String?

    init(id: UUID = UUID(),
         company: String,
         position: String,
         status: String = "Applied",
         dateApplied: Date = Date(),
         location: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.company = company
        self.position = position
        self.status = status
        self.dateApplied = dateApplied
        self.location = location
        self.notes = notes
    }
}
