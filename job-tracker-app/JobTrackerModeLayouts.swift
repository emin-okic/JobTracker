//
//  JobTrackerModeLayouts.swift
//  job-tracker-app
//
//  Layout containers for portrait and landscape job tracker modes.
//

import SwiftUI

struct JobTrackerPortraitView<ListContent: View, ToolbarContent: View>: View {
    @Binding var path: [UUID]

    let applications: [JobApplication]
    @ViewBuilder var listContent: () -> ListContent
    @ViewBuilder var toolbarContent: () -> ToolbarContent

    var body: some View {
        NavigationStack(path: $path) {
            listContent()
                .navigationTitle("Job Tracker")
                .navigationDestination(for: UUID.self) { id in
                    if let app = applications.first(where: { $0.id == id }) {
                        ApplicationDetailView(app: app)
                    } else {
                        Text("Application not found")
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    toolbarContent()
                }
        }
    }
}

struct JobTrackerLandscapeSplitView<ListContent: View, DetailContent: View, ToolbarContent: View>: View {
    @Binding var detailFraction: CGFloat
    @Binding var dragStartFraction: CGFloat?

    let selectedApplication: JobApplication?
    @ViewBuilder var listContent: () -> ListContent
    @ViewBuilder var detailContent: () -> DetailContent
    @ViewBuilder var toolbarContent: () -> ToolbarContent

    var body: some View {
        GeometryReader { proxy in
            let handleWidth: CGFloat = 22
            let availableWidth = max(proxy.size.width - handleWidth, 1)
            let detailWidth = detailWidth(for: availableWidth)
            let listWidth = availableWidth - detailWidth

            HStack(spacing: 0) {
                NavigationStack {
                    listContent()
                        .navigationTitle("Job Tracker")
                        .navigationBarTitleDisplayMode(.inline)
                        .overlay(alignment: .bottomLeading) {
                            if selectedApplication == nil {
                                toolbarContent()
                            }
                        }
                }
                .frame(width: selectedApplication == nil ? proxy.size.width : listWidth)

                if selectedApplication != nil {
                    resizeHandle(availableWidth: availableWidth)
                        .frame(width: handleWidth)

                    NavigationStack {
                        detailContent()
                    }
                    .frame(width: detailWidth)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(Color(.systemGroupedBackground))
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: selectedApplication?.id)
        }
    }

    private func detailWidth(for availableWidth: CGFloat) -> CGFloat {
        let minimumListWidth: CGFloat = 300
        let minimumDetailWidth: CGFloat = 340
        let lowerBound = min(minimumDetailWidth, availableWidth)
        let upperBound = max(lowerBound, availableWidth - minimumListWidth)
        let proposedWidth = availableWidth * detailFraction
        return min(max(proposedWidth, lowerBound), upperBound)
    }

    private func updateDetailWidth(availableWidth: CGFloat, translation: CGFloat) {
        let startFraction = dragStartFraction ?? detailFraction
        dragStartFraction = startFraction

        let proposedWidth = availableWidth * startFraction - translation
        let minimumListWidth: CGFloat = 300
        let minimumDetailWidth: CGFloat = 340
        let lowerBound = min(minimumDetailWidth, availableWidth)
        let upperBound = max(lowerBound, availableWidth - minimumListWidth)
        let clampedWidth = min(max(proposedWidth, lowerBound), upperBound)
        detailFraction = clampedWidth / availableWidth
    }

    private func resizeHandle(availableWidth: CGFloat) -> some View {
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
                        updateDetailWidth(availableWidth: availableWidth, translation: value.translation.width)
                    }
                    .onEnded { _ in
                        dragStartFraction = nil
                    }
            )
            .accessibilityLabel("Resize details pane")
            .accessibilityHint("Drag left or right to resize the job application details screen")
    }
}
