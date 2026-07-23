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
    @State private var selectedProgressRange: ApplicationProgressRange?
    @State private var searchText = ""
    @State private var path: [UUID] = []
    @State private var selectedIDs: Set<UUID> = []

    private enum ApplicationProgressRange: String, Identifiable {
        case today
        case week

        var id: String { rawValue }

        var filterTitle: String {
            switch self {
            case .today:
                "Daily job apps sent"
            case .week:
                "Weekly job apps sent"
            }
        }

        var cardTitle: String {
            switch self {
            case .today:
                "Daily apps sent"
            case .week:
                "Weekly apps sent"
            }
        }

        var systemImage: String {
            switch self {
            case .today:
                "calendar.badge.checkmark"
            case .week:
                "calendar"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                progressCards
                banner
                list
            }
            .navigationTitle("Job Tracker")
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    ApplicationFormView { newApp in
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
                    ApplicationDetailView(app: app)
                } else {
                    Text("Application not found")
                }
            }
            .overlay(alignment: .bottomLeading) {
                floatingToolbar
            }
            .onChange(of: editMode) { _, newValue in
                if newValue != .active { selectedIDs.removeAll() }
            }
            .environment(\.editMode, $editMode)
        }
    }

    private var progressCards: some View {
        HStack(spacing: 12) {
            progressCard(for: .today, count: todaysApplications.count)
            progressCard(for: .week, count: weeklyApplications.count)
        }
        .padding([.horizontal, .top])
    }

    private func progressCard(for range: ApplicationProgressRange, count: Int) -> some View {
        let isSelected = selectedProgressRange == range

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                selectedProgressRange = range
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: range.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .symbolRenderingMode(.hierarchical)

                Text("\(count)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(range.cardTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.7) : Color.secondary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(range.rawValue)ApplicationProgressCard")
        .accessibilityLabel("\(range.filterTitle), \(count) applications")
        .accessibilityHint(isSelected ? "This filter is already active" : "Double tap to filter the job application list")
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
            if let selectedProgressRange {
                activeFilterRow(for: selectedProgressRange)
                    .listRowSeparator(.hidden)
            }

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

    private func activeFilterRow(for range: ApplicationProgressRange) -> some View {
        HStack(spacing: 10) {
            Label(range.filterTitle, systemImage: range.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    selectedProgressRange = nil
                }
            } label: {
                Text("Show All")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .accessibilityIdentifier("clearApplicationProgressFilterButton")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var filteredApplications: [JobApplication] {
        let rangeFilteredApplications = selectedProgressRange.map(applications(for:)) ?? applications

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rangeFilteredApplications
        }
        let query = searchText.lowercased()
        return rangeFilteredApplications.filter { app in
            app.company.lowercased().contains(query) ||
            app.position.lowercased().contains(query) ||
            app.status.lowercased().contains(query)
        }
    }

    private var todaysApplications: [JobApplication] {
        applications.filter { Calendar.current.isDateInToday($0.dateApplied) }
    }

    private var weeklyApplications: [JobApplication] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        return applications.filter { week.contains($0.dateApplied) }
    }

    private func applications(for range: ApplicationProgressRange) -> [JobApplication] {
        switch range {
        case .today:
            todaysApplications
        case .week:
            weeklyApplications
        }
    }

    private func delete(_ offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(filteredApplications[index]) }
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

#Preview {
    do {
        let container = try ModelContainer(for: JobApplication.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ContentView()
            .modelContainer(container)
    } catch {
        return Text("Preview failed to load model container: \(error.localizedDescription)")
    }
}
