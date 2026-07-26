//
//  JobPipelineView.swift
//  job-tracker-app
//
//  Visualizes current job applications across the hiring pipeline.
//

import SwiftUI

struct JobPipelineView: View {
    @Environment(\.dismiss) private var dismiss

    let applications: [JobApplication]

    private var orderedApplications: [JobApplication] {
        applications.sorted { first, second in
            if first.dateApplied == second.dateApplied {
                return first.company.localizedCaseInsensitiveCompare(second.company) == .orderedAscending
            }
            return first.dateApplied > second.dateApplied
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let graphWidth = max(proxy.size.width - 24, 320)

                ScrollView(.vertical) {
                    if orderedApplications.isEmpty {
                        ContentUnavailableView(
                            "No applications yet",
                            systemImage: "point.3.connected.trianglepath.dotted",
                            description: Text("Add job applications to see them flow through the pipeline.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding(.horizontal, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            pipelineHeader(width: graphWidth)
                            PipelineGraphView(applications: orderedApplications, width: graphWidth)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
                .scrollIndicators(.visible)
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Pipeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func pipelineHeader(width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.subheadline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)

            Text("Job Search Pipeline")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 12)

            Text("\(orderedApplications.count) jobs")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
        }
        .frame(width: width, alignment: .leading)
    }
}

private struct PipelineGraphView: View {
    let applications: [JobApplication]
    let width: CGFloat

    private let stages = PipelineStage.allCases

    private var metrics: PipelineGraphMetrics {
        PipelineGraphMetrics(width: width)
    }

    private var canvasSize: CGSize {
        CGSize(
            width: width,
            height: metrics.headerHeight + CGFloat(applications.count) * metrics.rowHeight + metrics.bottomPadding
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            stageHeader
                .zIndex(1)

            Canvas { context, _ in
                drawStageGuides(in: &context)
                drawApplicationPaths(in: &context)
            }
            .frame(width: canvasSize.width, height: canvasSize.height)

            applicationLabels
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Job search pipeline graph")
    }

    private var stageHeader: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: metrics.labelColumnWidth)

            ForEach(stages) { stage in
                VStack(spacing: 2) {
                    Image(systemName: stage.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(stage.color)
                        .frame(width: 18, height: 18)

                    Text(stage.shortTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(width: metrics.stageSpacing)
            }
        }
        .padding(.top, 7)
    }

    private var applicationLabels: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: metrics.headerHeight)

            ForEach(applications) { app in
                VStack(alignment: .leading, spacing: 1) {
                    Text(app.company)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Text(app.position)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: metrics.labelColumnWidth - 16, height: metrics.rowHeight, alignment: .leading)
                .padding(.leading, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(app.company), \(app.position), \(app.status)")
            }
        }
    }

    private func drawStageGuides(in context: inout GraphicsContext) {
        for stage in stages {
            let x = metrics.xPosition(for: stage)
            var guide = Path()
            guide.move(to: CGPoint(x: x, y: metrics.firstRowTop - 8))
            guide.addLine(to: CGPoint(x: x, y: canvasSize.height - metrics.bottomPadding + 2))
            context.stroke(guide, with: .color(.secondary.opacity(0.12)), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
        }
    }

    private func drawApplicationPaths(in context: inout GraphicsContext) {
        for (index, app) in applications.enumerated() {
            let y = metrics.yPosition(forRowAt: index)
            let currentStage = PipelineStage(status: app.status)
            let activeStages = PipelineStage.pathStages(for: currentStage)
            let pathColor = currentStage.color

            var path = Path()
            path.move(to: CGPoint(x: metrics.xPosition(for: .applied), y: y))

            for stage in activeStages.dropFirst() {
                let point = CGPoint(x: metrics.xPosition(for: stage), y: y)
                if stage == .rejected {
                    let branchStart = CGPoint(x: metrics.xPosition(for: .applied) + metrics.stageSpacing * 0.5, y: y)
                    path.addLine(to: branchStart)
                    path.addCurve(
                        to: point,
                        control1: CGPoint(x: branchStart.x + metrics.stageSpacing * 0.22, y: y),
                        control2: CGPoint(x: point.x - metrics.stageSpacing * 0.36, y: y + metrics.rejectedBranchOffset)
                    )
                } else {
                    path.addLine(to: point)
                }
            }

            context.stroke(path, with: .color(pathColor.opacity(0.72)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            for stage in activeStages {
                drawNode(for: stage, atY: y, color: pathColor, currentStage: currentStage, context: &context)
            }
        }
    }

    private func drawNode(for stage: PipelineStage, atY y: CGFloat, color: Color, currentStage: PipelineStage, context: inout GraphicsContext) {
        let center = CGPoint(x: metrics.xPosition(for: stage), y: y)
        let radius: CGFloat = stage == currentStage ? 6 : 4
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        context.fill(Path(ellipseIn: rect), with: .color(stage == currentStage ? color : color.opacity(0.55)))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: -2.5, dy: -2.5)), with: .color(color.opacity(stage == currentStage ? 0.22 : 0)), lineWidth: 2.5)
    }
}

private enum PipelineStage: Int, CaseIterable, Identifiable {
    case applied
    case interview
    case offer
    case rejected

    var id: Int { rawValue }

    var shortTitle: String {
        switch self {
        case .applied: return "Applied"
        case .interview: return "Talk"
        case .offer: return "Offer"
        case .rejected: return "No"
        }
    }

    var systemImage: String {
        switch self {
        case .applied: return "paperplane.fill"
        case .interview: return "person.2.fill"
        case .offer: return "checkmark.seal.fill"
        case .rejected: return "xmark.seal.fill"
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

    init(status: String) {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "interview": self = .interview
        case "offer": self = .offer
        case "rejected": self = .rejected
        default: self = .applied
        }
    }

    static func pathStages(for currentStage: PipelineStage) -> [PipelineStage] {
        switch currentStage {
        case .applied:
            return [.applied]
        case .interview:
            return [.applied, .interview]
        case .offer:
            return [.applied, .interview, .offer]
        case .rejected:
            return [.applied, .rejected]
        }
    }
}

private struct PipelineGraphMetrics {
    let width: CGFloat
    let headerHeight: CGFloat = 96
    let rowHeight: CGFloat = 38
    let bottomPadding: CGFloat = 8
    let rejectedBranchOffset: CGFloat = 11

    var firstRowTop: CGFloat {
        headerHeight
    }

    var labelColumnWidth: CGFloat {
        min(max(width * 0.38, 128), 178)
    }

    var stageSpacing: CGFloat {
        max((width - labelColumnWidth) / CGFloat(PipelineStage.allCases.count), 44)
    }

    func xPosition(for stage: PipelineStage) -> CGFloat {
        labelColumnWidth + CGFloat(stage.rawValue) * stageSpacing + stageSpacing / 2
    }

    func yPosition(forRowAt index: Int) -> CGFloat {
        headerHeight + CGFloat(index) * rowHeight + rowHeight / 2
    }
}

#Preview {
    JobPipelineView(applications: [
        JobApplication(company: "Northwind", position: "iOS Engineer", status: "Applied"),
        JobApplication(company: "Contoso", position: "Product Engineer", status: "Interview"),
        JobApplication(company: "Fabrikam", position: "Staff Engineer", status: "Offer"),
        JobApplication(company: "Tailspin", position: "SwiftUI Developer", status: "Rejected")
    ])
}
