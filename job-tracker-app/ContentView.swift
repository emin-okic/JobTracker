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
    @State private var selectedApplicationID: UUID?
    @State private var selectedIDs: Set<UUID> = []
    @State private var landscapeDetailFraction: CGFloat = 0.5
    @State private var landscapeDragStartFraction: CGFloat?
    @State private var isLandscapeDetailClosed = false

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

    private enum ApplicationListMode {
        case navigationStack
        case landscapeSelection
    }

    var body: some View {
        GeometryReader { proxy in
            if usesLandscapeSplit(for: proxy.size) {
                landscapeSplitView
            } else {
                portraitNavigationView
            }
        }
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
        .onChange(of: editMode) { _, newValue in
            if newValue != .active { selectedIDs.removeAll() }
        }
        .onChange(of: applications.map(\.id)) { _, ids in
            syncLandscapeSelection(with: ids)
        }
        .onChange(of: filteredApplications.map(\.id)) { _, ids in
            syncLandscapeSelection(with: ids)
        }
        .environment(\.editMode, $editMode)
    }

    private var portraitNavigationView: some View {
        NavigationStack(path: $path) {
            applicationList(mode: .navigationStack, includesOverview: true)
            .navigationTitle("Job Tracker")
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
        }
    }

    private var landscapeSplitView: some View {
        GeometryReader { proxy in
            let handleWidth: CGFloat = 22
            let availableWidth = max(proxy.size.width - handleWidth, 1)
            let detailWidth = landscapeDetailWidth(for: availableWidth)
            let listWidth = availableWidth - detailWidth

            HStack(spacing: 0) {
                NavigationStack {
                    VStack(spacing: 0) {
                        landscapeSummaryHeader
                        applicationList(mode: .landscapeSelection)
                    }
                    .navigationTitle("Job Tracker")
                    .navigationBarTitleDisplayMode(.inline)
                    .overlay(alignment: .bottomLeading) {
                        floatingToolbar
                    }
                }
                .frame(width: selectedApplication == nil ? proxy.size.width : listWidth)

                if selectedApplication != nil {
                    landscapeResizeHandle(availableWidth: availableWidth)
                        .frame(width: handleWidth)

                    NavigationStack {
                        landscapeDetailPane
                    }
                    .frame(width: detailWidth)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(Color(.systemGroupedBackground))
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: selectedApplicationID)
        }
        .onAppear {
            selectDefaultApplicationIfNeeded()
        }
    }

    private func usesLandscapeSplit(for size: CGSize) -> Bool {
        size.width > size.height && size.width >= 640
    }

    private func landscapeDetailWidth(for availableWidth: CGFloat) -> CGFloat {
        let minimumListWidth: CGFloat = 300
        let minimumDetailWidth: CGFloat = 340
        let lowerBound = min(minimumDetailWidth, availableWidth)
        let upperBound = max(lowerBound, availableWidth - minimumListWidth)
        let proposedWidth = availableWidth * landscapeDetailFraction
        return min(max(proposedWidth, lowerBound), upperBound)
    }

    private func updateLandscapeDetailWidth(availableWidth: CGFloat, translation: CGFloat) {
        let startFraction = landscapeDragStartFraction ?? landscapeDetailFraction
        landscapeDragStartFraction = startFraction

        let proposedWidth = availableWidth * startFraction - translation
        let minimumListWidth: CGFloat = 300
        let minimumDetailWidth: CGFloat = 340
        let lowerBound = min(minimumDetailWidth, availableWidth)
        let upperBound = max(lowerBound, availableWidth - minimumListWidth)
        let clampedWidth = min(max(proposedWidth, lowerBound), upperBound)
        landscapeDetailFraction = clampedWidth / availableWidth
    }

    private func landscapeResizeHandle(availableWidth: CGFloat) -> some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.55))
            .frame(width: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 4, height: 48)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateLandscapeDetailWidth(availableWidth: availableWidth, translation: value.translation.width)
                    }
                    .onEnded { _ in
                        landscapeDragStartFraction = nil
                    }
            )
            .accessibilityLabel("Resize details pane")
            .accessibilityHint("Drag left or right to resize the job application details screen")
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

    private var landscapeSummaryHeader: some View {
        VStack(spacing: 12) {
            progressCards

            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundStyle(.blue)
                Text("Landscape review")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(filteredApplications.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func applicationList(mode: ApplicationListMode, includesOverview: Bool = false) -> some View {
        List(selection: $selectedIDs) {
            if includesOverview {
                progressCards
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                banner
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

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
                        select(app, mode: mode)
                    } label: {
                        KanbanRow(app: app)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectionColor(for: app, mode: mode), lineWidth: 2)
                            )
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

    @ViewBuilder
    private var landscapeDetailPane: some View {
        if let selectedApplication {
            ApplicationDetailView(app: selectedApplication)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            closeLandscapeDetail()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close Details")
                    }
                }
        } else {
            ContentUnavailableView(
                "Select an application",
                systemImage: "rectangle.split.2x1",
                description: Text("Choose a job application from the list to review its details.")
            )
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
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

    private var selectedApplication: JobApplication? {
        guard let selectedApplicationID else { return nil }
        return applications.first { $0.id == selectedApplicationID }
    }

    private func select(_ app: JobApplication, mode: ApplicationListMode) {
        switch mode {
        case .navigationStack:
            path.append(app.id)
        case .landscapeSelection:
            isLandscapeDetailClosed = false
            selectedApplicationID = app.id
        }
    }

    private func selectionColor(for app: JobApplication, mode: ApplicationListMode) -> Color {
        guard mode == .landscapeSelection, selectedApplicationID == app.id else {
            return .clear
        }
        return .blue.opacity(0.65)
    }

    private func selectDefaultApplicationIfNeeded() {
        syncLandscapeSelection(with: filteredApplications.map(\.id))
    }

    private func syncLandscapeSelection(with ids: [UUID]) {
        guard !isLandscapeDetailClosed else { return }

        if let selectedApplicationID, ids.contains(selectedApplicationID) {
            return
        }
        selectedApplicationID = ids.first
    }

    private func closeLandscapeDetail() {
        isLandscapeDetailClosed = true
        selectedApplicationID = nil
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
