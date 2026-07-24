//
//  KanbanRow.swift
//  job-tracker-app
//
//  Extracted by Assistant
//

import SwiftUI

struct KanbanRow: View {
    enum Style {
        case standard
        case compact
    }

    let app: JobApplication
    var style: Style = .standard

    var body: some View {
        switch style {
        case .standard:
            standardBody
        case .compact:
            compactBody
        }
    }

    private var standardBody: some View {
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

    private var compactBody: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(app.company)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Label(app.dateApplied.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            StatusPill(status: app.status)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.vertical, 2)
    }
}
