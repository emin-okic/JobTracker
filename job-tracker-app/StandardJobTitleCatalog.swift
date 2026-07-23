import Foundation

enum StandardJobTitleCatalog {
    static let titles: [StandardJobTitle] = {
        var priority = 0
        var entries: [StandardJobTitle] = []

        func add(_ title: String, category: JobTitleCategory, aliases: [String] = []) {
            entries.append(StandardJobTitle(title: title, category: category, priority: priority, aliases: aliases))
            priority += 1
        }

        let softwareEngineering = [
            "Software Engineer", "Frontend Engineer", "Backend Engineer", "Full Stack Engineer",
            "Mobile Engineer", "iOS Engineer", "Android Engineer", "macOS Engineer", "WatchOS Engineer",
            "VisionOS Engineer", "Swift Developer", "Kotlin Developer", "React Developer", "React Native Developer",
            "Angular Developer", "Vue Developer", "JavaScript Developer", "TypeScript Developer", "Web Developer",
            "Web Application Developer", "Node.js Developer", "Python Developer", "Java Developer", "Go Developer",
            "Rust Developer", "C++ Developer", "C# Developer", ".NET Developer", "Ruby on Rails Developer",
            "PHP Developer", "Laravel Developer", "WordPress Developer", "Shopify Developer", "Salesforce Developer",
            "ServiceNow Developer", "SAP Developer", "Oracle Developer", "Game Developer", "Unity Developer",
            "Unreal Engine Developer", "AR/VR Developer", "Embedded Software Engineer", "Firmware Engineer",
            "Robotics Software Engineer", "Autonomous Systems Engineer", "Compiler Engineer", "Graphics Engineer",
            "Rendering Engineer", "Audio Software Engineer", "Accessibility Engineer", "Localization Engineer",
            "Developer Tools Engineer", "API Engineer", "Integration Engineer", "Platform Engineer",
            "Distributed Systems Engineer", "Search Engineer", "Payments Engineer", "FinTech Software Engineer",
            "HealthTech Software Engineer", "EdTech Software Engineer", "E-commerce Engineer", "Software Development Engineer in Test",
            "QA Automation Engineer", "Manual QA Tester", "Quality Assurance Analyst", "Test Engineer", "Build Engineer",
            "Release Engineer", "Developer Advocate", "Technical Writer"
        ]
        softwareEngineering.forEach { add($0, category: .softwareEngineering, aliases: aliases(for: $0)) }

        let dataAI = [
            "AI Engineer", "Machine Learning Engineer", "ML Engineer", "Deep Learning Engineer", "NLP Engineer",
            "Computer Vision Engineer", "Generative AI Engineer", "LLM Engineer", "Prompt Engineer",
            "MLOps Engineer", "AI Research Scientist", "Applied Scientist", "Research Engineer", "Data Scientist",
            "Decision Scientist", "Product Data Scientist", "Data Analyst", "Business Intelligence Analyst",
            "BI Developer", "Analytics Engineer", "Data Engineer", "Big Data Engineer", "ETL Developer",
            "Data Warehouse Engineer", "Data Platform Engineer", "Database Developer", "Database Administrator",
            "Machine Learning Operations Specialist", "AI Product Manager", "Data Product Manager", "Quantitative Developer",
            "Quantitative Analyst", "Statistician", "Operations Research Analyst"
        ]
        dataAI.forEach { add($0, category: .dataAI, aliases: aliases(for: $0)) }

        let infrastructure = [
            "DevOps Engineer", "Site Reliability Engineer", "SRE", "Cloud Engineer", "Cloud Architect",
            "AWS Engineer", "Azure Engineer", "Google Cloud Engineer", "Kubernetes Engineer", "Infrastructure Engineer",
            "Systems Engineer", "Linux Systems Administrator", "Windows Systems Administrator", "Network Engineer",
            "Network Administrator", "Network Architect", "Database Reliability Engineer", "Storage Engineer",
            "Virtualization Engineer", "Observability Engineer", "Monitoring Engineer", "Incident Response Engineer",
            "Production Engineer", "IT Support Specialist", "Help Desk Technician", "Desktop Support Technician",
            "Technical Support Engineer", "Solutions Engineer", "Solutions Architect", "Sales Engineer",
            "Customer Success Engineer", "Implementation Engineer", "Forward Deployed Engineer"
        ]
        infrastructure.forEach { add($0, category: .infrastructure, aliases: aliases(for: $0)) }

        let security = [
            "Security Engineer", "Application Security Engineer", "Product Security Engineer", "Cloud Security Engineer",
            "Infrastructure Security Engineer", "Cybersecurity Analyst", "Information Security Analyst", "SOC Analyst",
            "Security Operations Analyst", "Incident Response Analyst", "Threat Intelligence Analyst", "Detection Engineer",
            "Penetration Tester", "Red Team Operator", "Blue Team Analyst", "Vulnerability Management Analyst",
            "Identity and Access Management Engineer", "IAM Engineer", "GRC Analyst", "Security Architect",
            "Privacy Engineer", "Trust and Safety Analyst", "Fraud Analyst"
        ]
        security.forEach { add($0, category: .security, aliases: aliases(for: $0)) }

        let productDesign = [
            "Product Manager", "Technical Product Manager", "Associate Product Manager", "Product Owner",
            "Program Manager", "Technical Program Manager", "Project Manager", "Scrum Master", "Agile Coach",
            "UX Designer", "UI Designer", "Product Designer", "Interaction Designer", "Visual Designer",
            "UX Researcher", "Design Researcher", "Content Designer", "Content Strategist", "Design Engineer",
            "Service Designer", "Product Marketing Manager", "Growth Product Manager", "Marketing Analyst"
        ]
        productDesign.forEach { add($0, category: .productDesign, aliases: aliases(for: $0)) }

        let technicalLeadership = [
            "Engineering Manager", "Software Engineering Manager", "Frontend Engineering Manager", "Backend Engineering Manager",
            "Mobile Engineering Manager", "Data Engineering Manager", "Machine Learning Manager", "QA Manager",
            "DevOps Manager", "Security Manager", "IT Manager", "Director of Engineering", "VP of Engineering",
            "Chief Technology Officer", "CTO", "Chief Information Officer", "CIO", "Chief Information Security Officer",
            "CISO", "Staff Software Engineer", "Senior Staff Software Engineer", "Principal Software Engineer",
            "Distinguished Engineer", "Architect", "Enterprise Architect", "Technical Lead", "Team Lead"
        ]
        technicalLeadership.forEach { add($0, category: .technicalLeadership, aliases: aliases(for: $0)) }

        let general = [
            "Account Executive", "Account Manager", "Administrative Assistant", "Business Analyst", "Business Development Representative",
            "Customer Success Manager", "Customer Service Representative", "Data Entry Clerk", "Executive Assistant",
            "Financial Analyst", "Human Resources Generalist", "HR Manager", "Marketing Manager", "Operations Manager",
            "Office Manager", "Recruiter", "Talent Acquisition Specialist", "Sales Representative", "Sales Manager",
            "Social Media Manager", "Content Marketing Manager", "Copywriter", "Graphic Designer", "Accountant",
            "Bookkeeper", "Controller", "Nurse", "Medical Assistant", "Pharmacy Technician", "Teacher",
            "Instructional Designer", "Professor", "Paralegal", "Legal Assistant", "Consultant", "Management Consultant",
            "Mechanical Engineer", "Electrical Engineer", "Civil Engineer", "Manufacturing Engineer", "Industrial Engineer",
            "Warehouse Associate", "Logistics Coordinator", "Supply Chain Analyst", "Truck Driver", "Electrician",
            "Plumber", "HVAC Technician", "Retail Associate", "Store Manager", "Restaurant Manager",
            "Barista", "Server", "Chef", "Construction Manager", "Real Estate Agent", "Insurance Agent"
        ]
        general.forEach { add($0, category: .general, aliases: aliases(for: $0)) }

        return entries
    }()

    private static func aliases(for title: String) -> [String] {
        switch title {
        case "iOS Engineer": return ["iOS Developer", "Swift Engineer"]
        case "SRE": return ["Site Reliability Engineer"]
        case "ML Engineer": return ["Machine Learning Engineer"]
        case "QA Automation Engineer": return ["Automation Tester", "Software Test Automation Engineer"]
        case "Software Development Engineer in Test": return ["SDET"]
        case "Business Intelligence Analyst": return ["BI Analyst"]
        case "Chief Technology Officer": return ["CTO"]
        case "Chief Information Officer": return ["CIO"]
        case "Chief Information Security Officer": return ["CISO"]
        case "Identity and Access Management Engineer": return ["IAM Engineer"]
        default: return []
        }
    }
}
