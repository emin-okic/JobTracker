import Combine
import SwiftUI

@MainActor
final class JobTitleSuggestionViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet { refreshSuggestions() }
    }
    @Published private(set) var suggestions: [StandardJobTitle]

    private let service: JobTitleSuggesting
    private let limit: Int

    init(service: JobTitleSuggesting? = nil, limit: Int = 6) {
        let resolvedService = service ?? JobTitleSuggestionService()
        self.service = resolvedService
        self.limit = limit
        self.suggestions = resolvedService.suggestions(for: "", limit: limit)
    }

    func refreshSuggestions() {
        suggestions = service.suggestions(for: query, limit: limit)
    }

    func clearSuggestions() {
        suggestions = []
    }
}

struct JobTitleSuggestionsView: View {
    let suggestions: [StandardJobTitle]
    let onSelect: (StandardJobTitle) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: iconName(for: suggestion.category))
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(suggestion.category.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("jobTitleSuggestion_\(suggestion.title)")
                }
            }
            .padding(.top, 4)
        }
    }

    private func iconName(for category: JobTitleCategory) -> String {
        switch category {
        case .softwareEngineering: return "curlybraces"
        case .dataAI: return "chart.xyaxis.line"
        case .infrastructure: return "server.rack"
        case .security: return "lock.shield"
        case .productDesign: return "slider.horizontal.3"
        case .technicalLeadership: return "person.2.badge.gearshape"
        case .general: return "briefcase"
        }
    }
}
