//
//  ContentView.swift
//  job-tracker-app
//
//  Created by Emin Okic on 7/18/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\JobApplication.dateApplied, order: .reverse)]) private var applications: [JobApplication]

    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                banner
                list
            }
            .navigationTitle("Job Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addApplicationButton")
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    ApplicationForm { newApp in
                        modelContext.insert(newApp)
                        showingAddSheet = false
                    } onCancel: {
                        showingAddSheet = false
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: UUID.self) { id in
                if let app = applications.first(where: { $0.id == id }) {
                    ApplicationDetail(app: app)
                } else {
                    Text("Application not found")
                }
            }
        }
    }

    private var banner: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 6) {
                Text("Track Your Job Search")
                    .font(.title2).bold()
                    .foregroundStyle(.white)
                Text("Quickly add and manage applications in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding([.horizontal, .top])
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var list: some View {
        List {
            ForEach(filteredApplications) { app in
                Button {
                    path.append(app.id)
                } label: {
                    KanbanRow(app: app)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) { delete(app) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
    }

    private var filteredApplications: [JobApplication] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return applications
        }
        let query = searchText.lowercased()
        return applications.filter { app in
            app.company.lowercased().contains(query) ||
            app.position.lowercased().contains(query) ||
            app.status.lowercased().contains(query)
        }
    }

    private func delete(_ offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(applications[index]) }
        }
    }

    private func delete(_ app: JobApplication) {
        withAnimation { modelContext.delete(app) }
    }
}

// MARK: - Kanban-style Row

private struct KanbanRow: View {
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
            .foregroundStyle(.secondary)

            HStack {
                Text(app.dateApplied, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.vertical, 4)
    }
}

private struct StatusPill: View {
    let status: String
    var body: some View {
        Text(status)
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(capsuleColor(status))
            .foregroundStyle(.white)
            .clipShape(Capsule())
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

// MARK: - Application Form

private struct ApplicationForm: View {
    @Environment(\.dismiss) private var dismiss

    @State private var company: String
    @State private var position: String
    @State private var status: String
    @State private var dateApplied: Date
    @State private var location: String
    @State private var notes: String

    var onSave: (JobApplication) -> Void
    var onCancel: () -> Void

    init(existing: JobApplication? = nil, onSave: @escaping (JobApplication) -> Void, onCancel: @escaping () -> Void) {
        _company = State(initialValue: existing?.company ?? "")
        _position = State(initialValue: existing?.position ?? "")
        _status = State(initialValue: existing?.status ?? "Applied")
        _dateApplied = State(initialValue: existing?.dateApplied ?? Date())
        _location = State(initialValue: existing?.location ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        Form {
            Section("Position") {
                TextField("Company", text: $company)
                TextField("Role / Position", text: $position)
            }
            Section("Details") {
                Picker("Status", selection: $status) {
                    ForEach(["Applied", "Interview", "Offer", "Rejected"], id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                DatePicker("Date Applied", selection: $dateApplied, displayedComponents: .date)
                TextField("Location (optional)", text: $location)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
        }
        .navigationTitle("Application")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onCancel(); dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(company.trimmingCharacters(in: .whitespaces).isEmpty || position.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func save() {
        let app = JobApplication(company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                                 position: position.trimmingCharacters(in: .whitespacesAndNewlines),
                                 status: status,
                                 dateApplied: dateApplied,
                                 location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location,
                                 notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes)
        onSave(app)
        dismiss()
    }
}

// MARK: - Detail View

private struct ApplicationDetail: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false
    let app: JobApplication

    var body: some View {
        List {
            Section {
                LabeledContent("Company", value: app.company)
                LabeledContent("Position", value: app.position)
                LabeledContent("Status", value: app.status)
                LabeledContent("Applied", value: app.dateApplied.formatted(date: .abbreviated, time: .omitted))
                if let location = app.location { LabeledContent("Location", value: location) }
            }

            if let notes = app.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(app.position)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") { showingEdit = true }
                    Button(role: .destructive) { modelContext.delete(app) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ApplicationForm(existing: app) { _ in
                    showingEdit = false
                } onCancel: {
                    showingEdit = false
                }
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: JobApplication.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ContentView()
            .modelContainer(container)
    } catch {
        return Text("Preview failed to load model container: \(error.localizedDescription)")
    }
}
