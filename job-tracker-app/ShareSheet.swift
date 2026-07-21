//
//  ShareSheet.swift
//  job-tracker-app
//
//  Created by Assistant
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
