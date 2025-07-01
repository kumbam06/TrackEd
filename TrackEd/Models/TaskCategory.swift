import Foundation
import SwiftUI

struct TaskCategory: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var color: String // Store as hex string
    var icon: String
    var isDefault: Bool = false
    
    static let defaultCategories: [TaskCategory] = [
        TaskCategory(name: "Academic", color: "#007AFF", icon: "book.fill", isDefault: true),
        TaskCategory(name: "Career", color: "#34C759", icon: "briefcase.fill", isDefault: true),
        TaskCategory(name: "Personal", color: "#FF9500", icon: "person.fill", isDefault: true),
        TaskCategory(name: "Health", color: "#FF3B30", icon: "heart.fill", isDefault: true),
        TaskCategory(name: "Social", color: "#AF52DE", icon: "person.2.fill", isDefault: true),
        TaskCategory(name: "Finance", color: "#FFCC00", icon: "dollarsign.circle.fill", isDefault: true)
    ]
    
    var uiColor: Color {
        Color(hex: color) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 