import SwiftUI
import UIKit

enum DeviceFeedback {
    static var supportsHaptics: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
