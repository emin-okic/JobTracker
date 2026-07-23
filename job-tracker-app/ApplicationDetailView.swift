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
    @FocusState private var isNoteComposerFocused: Bool

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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label("Notes", systemImage: "text.bubble.fill")
                    .font(.headline)

                Spacer()

                if !viewModel.notes.isEmpty {
                    Text("\(viewModel.notes.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                        )
                }
            }

            if viewModel.notes.isEmpty {
                emptyNotesView
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.notes) { note in
                        noteRow(note)
                    }
                }
            }

            noteComposer
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

    private var emptyNotesView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "note.text")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.subheadline.weight(.semibold))
            Text("Add a quick update after recruiter calls, interviews, follow-ups, or offer changes.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var noteComposer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add a note", text: $viewModel.draftNote, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.plain)
                .focused($isNoteComposerFocused)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isNoteComposerFocused ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.12), lineWidth: 1)
                )
                .accessibilityIdentifier("noteComposerField")

            Button {
                addNote()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canAddNote)
            .foregroundStyle(viewModel.canAddNote ? Color.accentColor : Color.secondary.opacity(0.45))
            .accessibilityLabel("Add Note")
            .accessibilityIdentifier("addNoteButton")
        }
    }

    private func noteRow(_ note: ApplicationNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(role: .destructive) {
                    deleteNote(note)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .accessibilityLabel("Delete Note")
            }

            Text(note.body)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func addNote() {
        viewModel.addDraftNote()
        try? modelContext.save()
        feedbackNoteAdded()
        isNoteComposerFocused = false
    }

    private func deleteNote(_ note: ApplicationNote) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            viewModel.deleteNote(id: note.id)
        }
        try? modelContext.save()
        feedbackDelete()
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

    private func feedbackNoteAdded() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}
