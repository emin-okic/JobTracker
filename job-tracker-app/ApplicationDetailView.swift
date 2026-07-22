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
    @StateObject private var viewModel: ApplicationDetailViewModel

    let app: JobApplication

    init(app: JobApplication) {
        self.app = app
        _viewModel = StateObject(wrappedValue: ApplicationDetailViewModel(app: app, policy: .lockedIfExisting))
    }

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
        .sheet(isPresented: $viewModel.showingEdit) {
            NavigationStack {
                ApplicationEditFormView(existing: app) { updated in
                    viewModel.update(with: updated)
                    viewModel.showingEdit = false
                } onCancel: {
                    viewModel.showingEdit = false
                }
            }
        }
        .sheet(isPresented: $viewModel.showShare) {
            ShareSheet(activityItems: [viewModel.shareText])
        }
        .sheet(isPresented: $viewModel.showingDeleteConfirm) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

                Text("Delete this application?")
                    .font(.headline)

                Text("This will permanently remove the application for \(app.position) at \(app.company). This action cannot be undone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.showingDeleteConfirm = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button(role: .destructive) {
                        modelContext.delete(app)
                        feedbackDelete()
                        viewModel.showingDeleteConfirm = false
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
            }
            .padding(20)
            .presentationDetents([.fraction(0.33)])
            .presentationDragIndicator(.visible)
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
            QuickActionButton(systemName: "square.and.pencil", title: "Edit") { viewModel.showingEdit = true }
            QuickActionButton(systemName: "square.and.arrow.up", title: "Share") { viewModel.showShare = true }
            if let location = app.location, !location.isEmpty {
                QuickActionButton(systemName: "map", title: "Maps") {
                    openMaps(for: location)
                }
            }
            if let urlString = app.companyURL, let url = URL(string: urlString), !urlString.isEmpty {
                QuickActionButton(systemName: "globe", title: "Website") {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
            if let urlString = app.jobURL, let url = URL(string: urlString), !urlString.isEmpty {
                QuickActionButton(systemName: "link", title: "Job Post") {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
            }
            QuickActionButton(systemName: "trash", title: "Delete", role: .destructive) {
                viewModel.showingDeleteConfirm = true
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
            if let urlString = app.companyURL, !urlString.isEmpty {
                InfoCard(title: "Company URL", systemImage: "globe") {
                    Text(urlString)
                }
            }
            if let urlString = app.jobURL, !urlString.isEmpty {
                InfoCard(title: "Job URL", systemImage: "link") {
                    Text(urlString)
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

    private func openMaps(for query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
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
