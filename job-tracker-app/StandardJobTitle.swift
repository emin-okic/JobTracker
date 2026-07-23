import Foundation

enum JobTitleCategory: String, CaseIterable, Sendable {
    case softwareEngineering = "Software Engineering"
    case dataAI = "Data & AI"
    case infrastructure = "Infrastructure"
    case security = "Security"
    case productDesign = "Product & Design"
    case technicalLeadership = "Technical Leadership"
    case general = "General"
}

struct StandardJobTitle: Identifiable, Hashable, Sendable {
    let title: String
    let category: JobTitleCategory
    let priority: Int
    let aliases: [String]

    var id: String { title }
}
