//
//  PipelineHistoryView.swift
//  job-tracker-app
//
//  Visual pipeline history for job applications.
//

import SwiftUI

struct PipelineHistoryView: View {
    let applications: [JobApplication]
    var compact: Bool = false
    var onSelect: (JobApplication) -> Void

    private let lanes = PipelineStage.ordered

    var body: some View {
        if applications.isEmpty {
            ContentUnavailableView(
                "No applications",
                systemImage: "point.3.connected.trianglepath.dotted",
                description: Text("Add applications to see your pipeline history.")
            )
            .frame(maxWidth: .infinity, minHeight: 240)
        } else {
            VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                stageHeader

                LazyVStack(spacing: compact ? 8 : 12) {
                    ForEach(applications) { app in
                        Button {
                            onSelect(app)
                        } label: {
                            PipelineHistoryRow(app: app, compact: compact)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open pipeline history for \(app.position) at \(app.company)")
                    }
                }
            }
            .padding(compact ? 10 : 14)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var stageHeader: some View {
        HStack(spacing: 0) {
            ForEach(lanes) { lane in
                VStack(spacing: 5) {
                    Image(systemName: lane.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(lane.color)
                    Text(lane.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }
}

private struct PipelineHistoryRow: View {
    let app: JobApplication
    var compact: Bool

    private var events: [PipelineEvent] {
        PipelineEvent.events(for: app)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.position)
                        .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(compact ? 1 : 2)

                    Text(app.company)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
                StatusPill(status: app.status)
            }

            PipelineGraph(events: events, compact: compact)
                .frame(height: compact ? 44 : 58)

            if !compact, let lastEvent = events.last {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text(lastEvent.date.formatted(date: .abbreviated, time: .omitted))
                    Text(lastEvent.stage.title)
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PipelineGraph: View {
    let events: [PipelineEvent]
    var compact: Bool

    private let stages = PipelineStage.ordered

    var body: some View {
        GeometryReader { proxy in
            let points = graphPoints(in: proxy.size)

            ZStack {
                ForEach(stages) { stage in
                    Capsule(style: .continuous)
                        .fill(stage.color.opacity(0.12))
                        .frame(width: 2, height: proxy.size.height)
                        .position(x: xPosition(for: stage, width: proxy.size.width), y: proxy.size.height / 2)
                }

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first.point)

                    for pair in zip(points, points.dropFirst()) {
                        let start = pair.0.point
                        let end = pair.1.point
                        let controlOffset = max(abs(end.x - start.x) * 0.45, 18)
                        path.addCurve(
                            to: end,
                            control1: CGPoint(x: start.x + controlOffset, y: start.y),
                            control2: CGPoint(x: end.x - controlOffset, y: end.y)
                        )
                    }
                }
                .stroke(
                    LinearGradient(colors: [.blue, .orange, .red, .green], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: compact ? 3 : 4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

                ForEach(points) { graphPoint in
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: compact ? 17 : 21, height: compact ? 17 : 21)

                        Circle()
                            .fill(graphPoint.event.stage.color)
                            .frame(width: compact ? 11 : 14, height: compact ? 11 : 14)
                    }
                    .overlay(
                        Circle()
                            .stroke(graphPoint.event.stage.color.opacity(0.35), lineWidth: 2)
                    )
                    .position(graphPoint.point)
                }
            }
        }
    }

    private func graphPoints(in size: CGSize) -> [GraphPoint] {
        let sortedEvents = events.sorted { $0.date < $1.date }
        guard !sortedEvents.isEmpty else { return [] }
        let verticalPadding: CGFloat = compact ? 10 : 12
        let availableHeight = max(size.height - verticalPadding * 2, 1)
        let denominator = max(sortedEvents.count - 1, 1)

        return sortedEvents.enumerated().map { index, event in
            let y = verticalPadding + (availableHeight * CGFloat(index) / CGFloat(denominator))
            return GraphPoint(event: event, point: CGPoint(x: xPosition(for: event.stage, width: size.width), y: y))
        }
    }

    private func xPosition(for stage: PipelineStage, width: CGFloat) -> CGFloat {
        guard let index = stages.firstIndex(of: stage), stages.count > 1 else { return width / 2 }
        let inset: CGFloat = compact ? 16 : 22
        let availableWidth = max(width - inset * 2, 1)
        return inset + availableWidth * CGFloat(index) / CGFloat(stages.count - 1)
    }
}

private struct GraphPoint: Identifiable {
    let id = UUID()
    let event: PipelineEvent
    let point: CGPoint
}

private struct PipelineEvent: Identifiable {
    let id = UUID()
    let stage: PipelineStage
    let date: Date

    static func events(for app: JobApplication) -> [PipelineEvent] {
        let notes = ApplicationNote.decoded(from: app.notes, legacyDate: app.dateApplied)
            .sorted { $0.createdAt < $1.createdAt }
        var events = [PipelineEvent(stage: .applied, date: app.dateApplied)]

        for note in notes {
            if let status = statusFromInitialActivity(note.body) ?? statusFromChange(note.body) {
                append(status: status, date: note.createdAt, to: &events)
            }
        }

        append(status: app.status, date: notes.last?.createdAt ?? app.dateApplied, to: &events)
        return events
    }

    private static func append(status: String, date: Date, to events: inout [PipelineEvent]) {
        guard let stage = PipelineStage(status: status) else { return }
        if events.last?.stage == stage { return }
        events.append(PipelineEvent(stage: stage, date: date))
    }

    private static func statusFromInitialActivity(_ body: String) -> String? {
        guard let range = body.range(of: " with status ") else { return nil }
        let status = body[range.upperBound...]
            .trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespacesAndNewlines))
        return status.isEmpty ? nil : status
    }

    private static func statusFromChange(_ body: String) -> String? {
        guard body.hasPrefix("Status changed from "), let range = body.range(of: " to ") else { return nil }
        let status = body[range.upperBound...]
            .trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespacesAndNewlines))
        return status.isEmpty ? nil : status
    }
}

private enum PipelineStage: String, CaseIterable, Identifiable {
    case applied
    case interview
    case offer
    case rejected

    static let ordered: [PipelineStage] = [.applied, .interview, .offer, .rejected]

    var id: String { rawValue }

    init?(status: String) {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "applied": self = .applied
        case "interview": self = .interview
        case "offer": self = .offer
        case "rejected": self = .rejected
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .applied: return "Applied"
        case .interview: return "Interview"
        case .offer: return "Offer"
        case .rejected: return "Rejected"
        }
    }

    var systemImage: String {
        switch self {
        case .applied: return "paperplane.fill"
        case .interview: return "person.2.fill"
        case .offer: return "checkmark.seal.fill"
        case .rejected: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .applied: return .blue
        case .interview: return .orange
        case .offer: return .green
        case .rejected: return .red
        }
    }
}
