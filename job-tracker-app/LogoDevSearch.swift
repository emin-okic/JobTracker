import Combine
import Foundation
import SwiftUI

// MARK: - Logo.dev Search Result Model
struct SearchResult: Codable, Identifiable {
    let name: String
    let domain: String
    let logo_url: String

    var id: String { domain }

    enum CodingKeys: String, CodingKey {
        case name
        case domain
        case logo_url
    }

    init(name: String, domain: String) {
        self.name = name
        self.domain = domain
        self.logo_url = "https://img.logo.dev/\(domain)?token=pk_e2tx2LTbSmS5_hieLIi5Qw&size=128"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let domain = try container.decode(String.self, forKey: .domain)
        self.name = name
        self.domain = domain
        if let provided = try? container.decode(String.self, forKey: .logo_url), !provided.isEmpty {
            self.logo_url = provided
        } else {
            self.logo_url = "https://img.logo.dev/\(domain)?token=pk_e2tx2LTbSmS5_hieLIi5Qw&size=128"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(domain, forKey: .domain)
        try container.encode(logo_url, forKey: .logo_url)
    }
}

// MARK: - ViewModel with Debounced Search
@MainActor
final class CompanySearchViewModel: ObservableObject {
    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }
    @Published var results: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    func clearResults() {
        results = []
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard currentQuery.count >= 2 else {
            results = []
            isLoading = false
            return
        }
        searchTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.errorMessage = nil
            // Debounce: wait 300ms before firing the request
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await self.performSearch(for: currentQuery)
        }
    }

    private func performSearch(for query: String) async {
        defer { self.isLoading = false }
        guard var components = URLComponents(string: "https://autocomplete.clearbit.com/v1/companies/suggest") else { return }
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                self.errorMessage = "Search failed."
                self.results = []
                return
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // The backend may return either an array or an object with a `results` key.
            if let array = try? decoder.decode([SearchResult].self, from: data) {
                self.results = array
            } else {
                struct Wrapper: Decodable { let results: [SearchResult] }
                let wrapper = try decoder.decode(Wrapper.self, from: data)
                self.results = wrapper.results
            }
        } catch {
            if Task.isCancelled { return }
            self.errorMessage = "Network error."
            self.results = []
        }
    }
}

