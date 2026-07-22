//
//  ApplicationFormView.swift
//  job-tracker-app
//
//  Extracted by Assistant
//

import SwiftUI
import MapKit
import Contacts

struct ApplicationFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var company: String
    @State private var position: String
    @State private var status: String
    @State private var dateApplied: Date
    @State private var location: String
    @State private var notes: String

    @State private var companyURL: String
    @State private var jobURL: String

    @StateObject private var searchVM = CompanySearchViewModel()
//    @State private var showSuggestions: Bool = true  // Removed as per instruction
    @State private var suppressSuggestionRefresh: Bool = false

    var onSave: (JobApplication) -> Void
    var onCancel: () -> Void

    enum Step: Int, CaseIterable { case basics, details, notes, review }
    @State private var step: Step = .basics

    enum Field { case company, position }
    @FocusState private var focusedField: Field?
    @State private var attemptedAdvance: Bool = false
    @State private var navigationDirection: Int = 1
    @State private var selectedDetent: PresentationDetent = .medium

    init(existing: JobApplication? = nil, onSave: @escaping (JobApplication) -> Void, onCancel: @escaping () -> Void) {
        _company = State(initialValue: existing?.company ?? "")
        _position = State(initialValue: existing?.position ?? "")
        _status = State(initialValue: existing?.status ?? "Applied")
        _dateApplied = State(initialValue: existing?.dateApplied ?? Date())
        _location = State(initialValue: existing?.location ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _companyURL = State(initialValue: existing?.companyURL ?? "")
        _jobURL = State(initialValue: existing?.jobURL ?? "")
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
                case .notes:
                    notesForm
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
                        guard abs(horizontal) > vertical else { return }
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
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .onAppear { updateDetentForStep() }
        .onChange(of: step) { _ in updateDetentForStep() }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .tint(.blue)
            HStack {
                stepLabel(for: .basics, title: "Basics")
                Spacer(minLength: 8)
                stepLabel(for: .details, title: "Details")
                Spacer(minLength: 8)
                stepLabel(for: .notes, title: "Notes")
                Spacer(minLength: 8)
                stepLabel(for: .review, title: "Confirm")
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
                    ZStack(alignment: .leading) {
                        TextField("Company", text: $company)
                            .textContentType(.organizationName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .company)
                            .onChange(of: company) { newValue in
                                if suppressSuggestionRefresh {
                                    suppressSuggestionRefresh = false
                                    return
                                }
                                searchVM.query = newValue
                            }
                            .onSubmit {
                                acceptInlinePredictionOrAdvance()
                            }

                        if let suffix = inlinePredictionSuffix, !suffix.isEmpty {
                            HStack(spacing: 0) {
                                Text(company)
                                    .font(.body)
                                    .opacity(0)
                                    .allowsHitTesting(false)
                                Button(action: {
                                    acceptInlinePredictionOrAdvance()
                                }) {
                                    Text(suffix)
                                        .font(.body)
                                        .foregroundStyle(.secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .modifier(ValidationModifier(isInvalid: companyInvalid))

                    if companyInvalid {
                        InlineErrorText("Company is required.")
                    }

                    // Removed Suggestions List UI as per instructions
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
            Section("Links") {
                TextField("Company website (optional)", text: $companyURL)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Job posting URL (optional)", text: $jobURL)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private var notesForm: some View {
        Form {
            Section("Notes") {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
    }

    private var reviewForm: some View {
        Form {
            Section("Summary") {
                LabeledContent("Company", value: company.isEmpty ? "—" : company)
                LabeledContent("Position", value: position.isEmpty ? "—" : position)
                LabeledContent("Status", value: status)
                LabeledContent("Applied", value: dateApplied.formatted(date: .abbreviated, time: .omitted))
                if !companyURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Company URL", value: companyURL)
                }
                if !jobURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Job URL", value: jobURL)
                }
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

    private var inlinePrediction: SearchResult? {
        let typed = company.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty else { return nil }
        guard let first = searchVM.results.first else { return nil }
        if first.name.lowercased().hasPrefix(typed.lowercased()) {
            return first
        }
        return nil
    }

    private var inlinePredictionSuffix: String? {
        guard let prediction = inlinePrediction else { return nil }
        let typedCount = company.count
        guard prediction.name.count > typedCount else { return nil }
        return String(prediction.name.dropFirst(typedCount))
    }

    private func acceptInlinePredictionOrAdvance() {
        if let prediction = inlinePrediction {
            suppressSuggestionRefresh = true
            company = prediction.name
            if !prediction.domain.isEmpty {
                companyURL = "https://\(prediction.domain)"
            }
            autofillCompanyAddress(name: prediction.name, domain: prediction.domain)
//            showSuggestions = false  // Removed as per instructions
            searchVM.clearResults()
            focusedField = .position
        } else {
            focusedField = .position
        }
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
        case .notes: return "Notes"
        case .review: return "Confirm"
        }
    }

    private func updateDetentForStep() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            selectedDetent = (step == .basics) ? .medium : .large
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
                step = .notes
            }
            feedbackAdvance()
        case .notes:
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
        case .notes:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigationDirection = -1
                step = .details
            }
            feedbackBack()
        case .review:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigationDirection = -1
                step = .notes
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
                                 notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                                 companyURL: companyURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : companyURL,
                                 jobURL: jobURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : jobURL)
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

    // MARK: - Apple Places (MapKit) lookup for company address
    private func autofillCompanyAddress(name: String, domain: String) {
        Task {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            let queries: [String] = [
                "\(trimmedName) headquarters",
                "\(trimmedName) corporate headquarters",
                trimmedDomain.isEmpty ? trimmedName : "\(trimmedName) \(trimmedDomain)"
            ]

            var chosen: MKMapItem?
            for q in queries {
                var request = MKLocalSearch.Request()
                request.naturalLanguageQuery = q
                // Prefer POIs (businesses) over generic addresses
                request.resultTypes = [.pointOfInterest]
                let search = MKLocalSearch(request: request)
                do {
                    let response = try await search.start()
                    if let best = bestMapItem(from: response.mapItems, forName: trimmedName, domain: trimmedDomain) {
                        chosen = best
                        break
                    }
                } catch {
                    // Try next query
                }
            }

            if let item = chosen {
                let address = formattedAddress(from: item)
                await MainActor.run {
                    self.location = address
                }
            }
        }
    }

    private func bestMapItem(from items: [MKMapItem], forName name: String, domain: String) -> MKMapItem? {
        guard !items.isEmpty else { return nil }
        let target = name.lowercased()
        let scored = items.map { item -> (MKMapItem, Int) in
            var score = 0
            let lowerName = (item.name ?? "").lowercased()

            // Prefer exact/partial name match
            if lowerName == target { score += 20 }
            if lowerName.contains(target) { score += 10 }

            // Prefer official/corporate results
            if lowerName.contains("headquarters") || lowerName.contains("hq") || lowerName.contains("campus") { score += 40 }

            // Prefer items whose URL matches the company's domain
            if domainMatches(url: item.url, domain: domain) { score += 60 }

            // Penalize retail/service locations
            if lowerName.contains("store") || lowerName.contains("reseller") || lowerName.contains("service") || lowerName.contains("care") { score -= 50 }

            // Prefer items with a precise street address
            if let postal = item.placemark.postalAddress, !postal.street.isEmpty { score += 10 }

            return (item, score)
        }
        .sorted { $0.1 > $1.1 }

        if let best = scored.first, best.1 > 0 { return best.0 }
        return nil
    }

    private func domainMatches(url: URL?, domain: String) -> Bool {
        guard let url = url, !domain.isEmpty, let host = url.host?.lowercased() else { return false }
        let d = domain.lowercased()
        return host == d || host.hasSuffix("." + d)
    }

    private func formattedAddress(from item: MKMapItem) -> String {
        if let postal = item.placemark.postalAddress {
            let formatter = CNPostalAddressFormatter()
            formatter.style = .mailingAddress
            return formatter.string(from: postal).replacingOccurrences(of: "\n", with: ", ")
        }
        return item.placemark.title ?? item.name ?? ""
    }
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
