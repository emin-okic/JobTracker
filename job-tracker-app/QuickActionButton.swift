//
//  QuickActionButton.swift
//  job-tracker-app
//
//  Created by Assistant
//

import SwiftUI

struct QuickActionButton: View {
    var systemName: String
    var title: String
    var role: ButtonRole? = nil
    var action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolVariant(.fill)
                Text(title)
                    .font(.caption)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(role == .destructive ? Color.red.opacity(0.12) : Color.accentColor.opacity(0.12))
            )
            .foregroundStyle(role == .destructive ? .red : .accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
