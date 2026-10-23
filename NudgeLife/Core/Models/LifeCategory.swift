import SwiftUI

/// Categories for organizing life items.
enum LifeCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case billsAndPayments = "bills_and_payments"
    case subscriptions = "subscriptions"
    case documents = "documents"
    case warranties = "warranties"
    case appointments = "appointments"
    case homeAndMaintenance = "home_and_maintenance"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .billsAndPayments: "Bills & Payments"
        case .subscriptions: "Subscriptions"
        case .documents: "Documents"
        case .warranties: "Warranties"
        case .appointments: "Appointments"
        case .homeAndMaintenance: "Home & Maintenance"
        case .custom: "Other"
        }
    }

    var sfSymbol: String {
        switch self {
        case .billsAndPayments: "creditcard.fill"
        case .subscriptions: "arrow.triangle.2.circlepath"
        case .documents: "doc.text.fill"
        case .warranties: "shield.checkered"
        case .appointments: "calendar.badge.clock"
        case .homeAndMaintenance: "house.fill"
        case .custom: "folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .billsAndPayments: .green
        case .subscriptions: .purple
        case .documents: .blue
        case .warranties: .orange
        case .appointments: .red
        case .homeAndMaintenance: .brown
        case .custom: .gray
        }
    }
}
