//
//  StatusPill.swift
//  job-tracker-app
//
//  Extracted by Assistant
//

import SwiftUI

struct StatusPill: View {
    let status: String
    var body: some View {
        Text(status)
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(capsuleColor(status))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(status)")
    }

    private func capsuleColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "applied": return .blue
        case "interview": return .orange
        case "offer": return .green
        case "rejected": return .red
        default: return .gray
        }
    }
}
