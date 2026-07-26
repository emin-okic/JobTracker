//
//  CompanyLogoView.swift
//  job-tracker-app
//
//  Shows a persisted company logo when available.
//

import SwiftUI

struct CompanyLogoView: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                    case .failure:
                        fallback
                    case .empty:
                        ProgressView()
                            .controlSize(.mini)
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        Image(systemName: "building.2.crop.circle")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}
