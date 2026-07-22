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
    @State private var showSuggestions: Bool = true

    var onSave: (JobApplication) -> Void
    var onCancel: () -> Void

    enum Step: Int, CaseIterable { case basics, details, review }
    @State private var step: Step = .basics

    enum Field { case company, position }
    @FocusState private var focusedField: Field?
    @State private var attemptedAdvance: Bool = false
    @State private var navigationDirection: Int = 1

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
                        .onChange(of: company) { newValue in
                            searchVM.query = newValue
                            showSuggestions = true
                        }
                        .onSubmit {
                            focusedField = .position
                        }

                    if companyInvalid {
                        InlineErrorText("Company is required.")
                    }

                    // Suggestions List
                    if showSuggestions && !searchVM.results.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchVM.results.prefix(3)) { item in
                                Button {
                                    company = item.name
                                    if !item.domain.isEmpty {
                                        companyURL = "https://\(item.domain)"
                                    }
                                    autofillCompanyAddress(name: item.name, domain: item.domain)
                                    showSuggestions = false
                                    focusedField = .position
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: item.logo_url)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView().frame(width: 28, height: 28)
                                            case .success(let image):
                                                image.resizable().scaledToFit()
                                                    .frame(width: 28, height: 28)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            case .failure:
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.gray.opacity(0.2))
                                                    Image(systemName: "building.2").foregroundStyle(.secondary)
                                                }
                                                .frame(width: 28, height: 28)
                                            @unknown default:
                                                EmptyView().frame(width: 28, height: 28)
                                            }
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name).font(.subheadline)
                                            Text(item.domain).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                            HStack {
                                Spacer()
                                Link("Logos by Logo.dev", destination: URL(string: "https://logo.dev")!)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.opacity)
                    } else if searchVM.isLoading && !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Searching companies…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
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
