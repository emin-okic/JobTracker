import Foundation

protocol JobTitleSuggesting {
    func suggestions(for query: String, limit: Int) -> [StandardJobTitle]
}

struct JobTitleSuggestionService: JobTitleSuggesting {
    private let titles: [StandardJobTitle]

    init(titles: [StandardJobTitle] = StandardJobTitleCatalog.titles) {
        self.titles = titles
    }

    func suggestions(for query: String, limit: Int = 8) -> [StandardJobTitle] {
        let normalizedQuery = query.normalizedForJobTitleSearch
        let scoredTitles = titles.compactMap { title -> (StandardJobTitle, Int)? in
            let score = score(title, normalizedQuery: normalizedQuery)
            guard score > 0 else { return nil }
            return (title, score)
        }

        return scoredTitles
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.priority < rhs.0.priority
            }
            .prefix(limit)
            .map(\.0)
    }

    private func score(_ jobTitle: StandardJobTitle, normalizedQuery: String) -> Int {
        guard !normalizedQuery.isEmpty else {
            return defaultScore(for: jobTitle)
        }

        let searchableValues = ([jobTitle.title] + jobTitle.aliases).map(\.normalizedForJobTitleSearch)
        var bestScore = 0

        for value in searchableValues {
            if value == normalizedQuery {
                bestScore = max(bestScore, 1_000)
            } else if value.hasPrefix(normalizedQuery) {
                bestScore = max(bestScore, 800)
            } else if value.components(separatedBy: " ").contains(where: { $0.hasPrefix(normalizedQuery) }) {
                bestScore = max(bestScore, 650)
            } else if value.contains(normalizedQuery) {
                bestScore = max(bestScore, 450)
            } else if allTokens(in: normalizedQuery, match: value) {
                bestScore = max(bestScore, 350)
            }
        }

        guard bestScore > 0 else { return 0 }
        return bestScore + categoryBoost(for: jobTitle.category) - jobTitle.priority
    }

    private func allTokens(in normalizedQuery: String, match value: String) -> Bool {
        let tokens = normalizedQuery.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return false }
        return tokens.allSatisfy { token in
            value.components(separatedBy: " ").contains { $0.hasPrefix(token) }
        }
    }

    private func defaultScore(for jobTitle: StandardJobTitle) -> Int {
        categoryBoost(for: jobTitle.category) - jobTitle.priority
    }

    private func categoryBoost(for category: JobTitleCategory) -> Int {
        switch category {
        case .softwareEngineering: return 2_000
        case .dataAI: return 1_800
        case .infrastructure: return 1_600
        case .security: return 1_400
        case .productDesign: return 1_200
        case .technicalLeadership: return 1_000
        case .general: return 100
        }
    }
}

private extension String {
    var normalizedForJobTitleSearch: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9+#.]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
