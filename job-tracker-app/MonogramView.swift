//
//  MonogramView.swift
//  job-tracker-app
//
//  Created by Assistant
//

import SwiftUI

struct MonogramView: View {
    let text: String

    var body: some View {
        let initials = initialsFrom(text)
        ZStack {
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(initials)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private func initialsFrom(_ text: String) -> String {
        let words = text.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first?.uppercased() }.joined()
        return initials.isEmpty ? String(text.prefix(2)).uppercased() : initials
    }
}
