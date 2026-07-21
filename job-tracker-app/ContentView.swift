//
//  ContentView.swift
//  job-tracker-app
//
//  Created by Emin Okic on 7/18/26.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\JobApplication.dateApplied, order: .reverse)]) private var applications: [JobApplication]
    @State private var editMode: EditMode = .inactive

    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var path: [UUID] = []
    @State private var selectedIDs: Set<UUID> = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                banner
                list
            }
            .navigationTitle("Job Tracker")
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
            .overlay(alignment: .bottomLeading) {
                floatingToolbar
            }
            .onChange(of: editMode) { newValue in
                if newValue != .active { selectedIDs.removeAll() }
            }
            .environment(\.editMode, $editMode)
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
        List(selection: $selectedIDs) {
            if isEditing {
                ForEach(filteredApplications) { app in
                    KanbanRow(app: app)
                        .tag(app.id)
                        .contextMenu {
                            Button(role: .destructive) { delete(app) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } else {
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
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .deleteDisabled(isEditing)
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

    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        withAnimation {
            for id in selectedIDs {
                if let app = applications.first(where: { $0.id == id }) {
                    modelContext.delete(app)
                }
            }
        }
        selectedIDs.removeAll()
    }

    // MARK: - Floating Toolbar

    private var isEditing: Bool {
        editMode == .active
    }

    private func toggleEditMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            if isEditing {
                editMode = .inactive
                selectedIDs.removeAll()
            } else {
                editMode = .active
            }
        }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
        #endif
    }

    @ViewBuilder
    private var floatingToolbar: some View {
        if path.isEmpty {
            VStack(spacing: 12) {
                // Add button (only when not editing)
                if !isEditing {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle().fill(
                                    LinearGradient(colors: [Color.blue, Color.cyan],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
                    .accessibilityIdentifier("addApplicationButton")
                    .accessibilityLabel("Add Job Application")
                }

                // Trash (only while editing)
                if isEditing {
                    Button(action: deleteSelected) {
                        Image(systemName: "trash")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle().fill(
                                    LinearGradient(colors: selectedIDs.isEmpty ? [Color.gray.opacity(0.95), Color.gray.opacity(0.8)] : [Color.red, Color.orange],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
                    .disabled(selectedIDs.isEmpty)
                    .accessibilityIdentifier("deleteSelectedButton")
                    .accessibilityLabel("Delete Selected Applications")
                }

                // Edit toggle (bottom, like Hinge's X position)
                Button(action: toggleEditMode) {
                    Image(systemName: isEditing ? "xmark" : "pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(
                                LinearGradient(colors: isEditing ? [Color.red, Color.orange] : [Color.gray.opacity(0.95), Color.gray.opacity(0.8)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        )
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
                .accessibilityIdentifier("editModeToggleButton")
                .accessibilityLabel(isEditing ? "Exit Edit Mode" : "Enter Edit Mode")
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
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

    enum Step: Int, CaseIterable { case basics, details, review }
    @State private var step: Step = .basics

    // Focus & validation state
    enum Field { case company, position }
    @FocusState private var focusedField: Field?
    @State private var attemptedAdvance: Bool = false

    // Transition direction: 1 = forward, -1 = back
    @State private var navigationDirection: Int = 1

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
        VStack(spacing: 12) {
            stepHeader

            ZStack {
                switch step {
                case .basics:
                    basicsForm
                        .transition(stepTransition)
                case .details:
                    detailsForm
                        .transition(stepTransition)
                case .review:
                    reviewForm
                        .transition(stepTransition)
                }
            }
            .id(step)
            .contentTransition(.opacity)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
            .highPriorityGesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        guard abs(horizontal) > vertical else { return } // ignore mostly-vertical drags
                        if horizontal < -40 {
                            goNext()
                        } else if horizontal > 40 {
                            goBack()
                        }
                    }
            )
        }
        .navigationTitle(stepNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onCancel(); dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .tint(.blue)
            HStack {
                stepLabel(for: .basics, title: "Basics")
                Spacer()
                stepLabel(for: .details, title: "Details")
                Spacer()
                stepLabel(for: .review, title: "Review")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func stepLabel(for s: Step, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "\(s.rawValue + 1).circle\(step == s ? ".fill" : "")")
                .foregroundStyle(step == s ? .blue : .secondary)
            Text(title)
                .foregroundStyle(step == s ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(step == s ? Color.blue.opacity(0.12) : Color.secondary.opacity(0.08))
        )
    }

    private var basicsForm: some View {
        Form {
            Section("Basics") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .company)
                        .padding(.vertical, 2)
                        .modifier(ValidationModifier(isInvalid: companyInvalid))
                        .onSubmit {
                            focusedField = .position
                        }
                    if companyInvalid {
                        InlineErrorText("Company is required.")
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Role / Position", text: $position)
                        .textContentType(.jobTitle)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .position)
                        .padding(.vertical, 2)
                        .modifier(ValidationModifier(isInvalid: positionInvalid))
                        .onSubmit {
                            goNext()
                        }
                    if positionInvalid {
                        InlineErrorText("Position is required.")
                    }
                }
            }
        }
    }

    private var detailsForm: some View {
        Form {
            Section("Status & Timing") {
                Picker("Status", selection: $status) {
                    ForEach(["Applied", "Interview", "Offer", "Rejected"], id: \.self) { s in
                        Text(s).tag(s)
                    }
                }
                .pickerStyle(.segmented)

                DatePicker("Date Applied", selection: $dateApplied, displayedComponents: .date)
            }
            Section("Location") {
                TextField("Location (optional)", text: $location)
                    .textContentType(.addressCity)
            }
        }
    }

    private var reviewForm: some View {
        Form {
            Section("Notes") {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }

            Section("Summary") {
                LabeledContent("Company", value: company.isEmpty ? "—" : company)
                LabeledContent("Position", value: position.isEmpty ? "—" : position)
                LabeledContent("Status", value: status)
                LabeledContent("Applied", value: dateApplied.formatted(date: .abbreviated, time: .omitted))
                if !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Location", value: location)
                }
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Notes", value: notes)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            if step != .basics {
                Button {
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            Spacer()
            if step == .review {
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isBasicsValid)
                .accessibilityIdentifier("saveApplicationButton")
            } else {
                Button {
                    goNext()
                } label: {
                    Label("Next", systemImage: "chevron.right.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("nextStepButton")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
    }

    private var companyInvalid: Bool {
        attemptedAdvance && company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var positionInvalid: Bool {
        attemptedAdvance && position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isBasicsValid: Bool {
        !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var stepTransition: AnyTransition {
        let insertionEdge: Edge = navigationDirection > 0 ? .trailing : .leading
        let removalEdge: Edge = navigationDirection > 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var stepNavigationTitle: String {
        switch step {
        case .basics: return "Basics"
        case .details: return "Details"
        case .review: return "Review"
        }
    }

    private func goNext() {
        switch step {
        case .basics:
            attemptedAdvance = true
            if isBasicsValid {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    navigationDirection = 1
                    step = .details
                }
                feedbackAdvance()
            } else {
                // focus first invalid field and provide error feedback
                if company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    focusedField = .company
                } else if position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    focusedField = .position
                }
                feedbackError()
            }
        case .details:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigationDirection = 1
                step = .review
            }
            feedbackAdvance()
        case .review:
            save()
        }
    }

    private func goBack() {
        switch step {
        case .basics:
            break
        case .details:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigationDirection = -1
                step = .basics
            }
            feedbackBack()
        case .review:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigationDirection = -1
                step = .details
            }
            feedbackBack()
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
        feedbackSuccess()
        dismiss()
    }

    // MARK: - Haptics
    private func feedbackAdvance() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.8)
        #endif
    }

    private func feedbackBack() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 0.6)
        #endif
    }

    private func feedbackError() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        #endif
    }

    private func feedbackSuccess() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }

    // MARK: - Inline validation helpers
    private struct ValidationModifier: ViewModifier {
        let isInvalid: Bool
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isInvalid ? Color.red.opacity(0.06) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isInvalid ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func InlineErrorText(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        }
        .accessibilityHint(message)
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

