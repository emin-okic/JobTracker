//
//  ApplicationDetailView.swift
//  job-tracker-app
//
//  Modernized detail screen by Assistant
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ApplicationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var showShare = false

    let app: JobApplication

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                quickActions
                infoGrid
                notesSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(app.position)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingMenu }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ApplicationFormView(existing: app) { updated in
                    // Update existing model with new values
                    app.company = updated.company
                    app.position = updated.position
                    app.status = updated.status
                    app.dateApplied = updated.dateApplied
                    app.location = updated.location
                    app.notes = updated.notes
                    showingEdit = false
                } onCancel: {
                    showingEdit = false
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(activityItems: [shareText])
        }
        .confirmationDialog("Delete Application?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(app)
                feedbackDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            MonogramView(text: app.company)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text(app.position)
                    .font(.title3).bold()
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                    Text(app.company)
                    if let location = app.location, !location.isEmpty {
                        Text("•")
                        Image(systemName: "mappin.and.ellipse")
                        Text(location)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            StatusPill(status: app.status)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(systemName: "square.and.pencil", title: "Edit") { showingEdit = true }
            QuickActionButton(systemName: "square.and.arrow.up", title: "Share") { showShare = true }
            if let location = app.location, !location.isEmpty {
                QuickActionButton(systemName: "map", title: "Maps") {
                    openMaps(for: location)
                }
            }
            QuickActionButton(systemName: "trash", title: "Delete", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
        .padding(.horizontal, 4)
    }

    private var infoGrid: some View {
        VStack(spacing: 12) {
            InfoCard(title: "Status", systemImage: "checkmark.seal.fill") {
                Text(app.status)
            }
            HStack(spacing: 12) {
                InfoCard(title: "Applied", systemImage: "calendar") {
                    Text(app.dateApplied.formatted(date: .abbreviated, time: .omitted))
                }
                InfoCard(title: "Company", systemImage: "building.2") {
                    Text(app.company)
                }
            }
            if let location = app.location, !location.isEmpty {
                InfoCard(title: "Location", systemImage: "mappin.and.ellipse") {
                    Text(location)
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if let notes = app.notes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
    }

    private var shareText: String {
        var parts: [String] = []
        parts.append("Position: \(app.position)")
        parts.append("Company: \(app.company)")
        if let location = app.location { parts.append("Location: \(location)") }
        parts.append("Status: \(app.status)")
        parts.append("Applied: \(app.dateApplied.formatted(date: .abbreviated, time: .omitted))")
        if let notes = app.notes, !notes.isEmpty { parts.append("Notes: \(notes)") }
        return parts.joined(separator: "\n")
    }

    private func openMaps(for query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
    }

    private var trailingMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Edit") { showingEdit = true }
                Button("Share") { showShare = true }
                Button(role: .destructive) { showingDeleteConfirm = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func feedbackDelete() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #endif
    }
}

