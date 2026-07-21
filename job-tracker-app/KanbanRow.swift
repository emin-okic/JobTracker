//
//  KanbanRow.swift
//  job-tracker-app
//
//  Extracted by Assistant
//

import SwiftUI

struct KanbanRow: View {
    let app: JobApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(app.position)
                    .font(.headline)
                Spacer()
                StatusPill(status: app.status)
            }
            HStack(spacing: 8) {
                Label(app.company, systemImage: "building.2")
                if let location = app.location, !location.isEmpty {
                    Text("•")
                    Label(location, systemImage: "mappin.and.ellipse")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            HStack {
                Text(app.dateApplied, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.vertical, 4)
    }
}
