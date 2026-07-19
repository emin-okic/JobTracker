//
//  Item.swift
//  job-tracker-app
//
//  Legacy placeholder kept for compatibility. No longer used.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    init(timestamp: Date) { self.timestamp = timestamp }
}
