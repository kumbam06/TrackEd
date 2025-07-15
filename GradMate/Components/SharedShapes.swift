import SwiftUI

// Shared shape for rounding specific corners
public struct RoundedCorner: Shape {
    public var radius: CGFloat = 0.0
    public var corners: UIRectCorner = .allCorners
    public init(radius: CGFloat, corners: UIRectCorner) {
        self.radius = radius
        self.corners = corners
    }
    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 