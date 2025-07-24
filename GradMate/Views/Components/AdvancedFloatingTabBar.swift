import SwiftUI
import Foundation
import Combine

// MARK: - View Modifier for Tab Bar Spacing
struct TabBarSpacing: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 100) // Space for capsule floating tab bar
    }
}

extension View {
    func tabBarSpacing() -> some View {
        modifier(TabBarSpacing())
    }
}

// Add WaveShape for water effect
struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = 0.0
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + phase) * .pi * frequency)
            let y = midY + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

struct AdvancedFloatingTabBar: View {
    @Binding var selectedTab: Int
    @State private var animationOffset: CGFloat = 0
    @Namespace private var tabBarNamespace
    @State private var wavePhase: CGFloat = 0
    private let waveTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    private let tabs = [
        TabItem(icon: "house.fill", title: "Home"),
        TabItem(icon: "list.bullet", title: "Planner"),
        TabItem(icon: "message.fill", title: "Chats"),
        TabItem(icon: "person.fill", title: "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    tab: tabs[index],
                    isSelected: selectedTab == index,
                    tabIndex: index,
                    selectedTab: selectedTab,
                    animationOffset: animationOffset,
                    action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedTab = index
                            animationOffset = CGFloat(index)
                        }
                        hapticFeedback()
                    }
                )
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("appCardBG"))
                .clipShape(
                    RoundedCorner(radius: 28, corners: [UIRectCorner.topLeft, UIRectCorner.topRight])
                )
                // Enhanced shadow for floating effect
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: -8)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct TabItem {
    let icon: String
    let title: String
}

// Add ArcText view for curved tab labels
struct ArcText: View {
    let text: String
    let radius: CGFloat
    let angle: Double // Total arc angle in degrees (e.g., 120)
    let font: Font
    let color: Color
    let kerning: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let chars = Array(text)
            let count = chars.count
            let arc = Angle(degrees: angle)
            let startAngle = -arc / 2
            let step = arc / Double(max(count - 1, 1))
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let charAngle = startAngle + step * Double(i)
                    let x = radius * CGFloat(sin(charAngle.radians))
                    let y = radius * CGFloat(1 - cos(charAngle.radians))
                    Text(String(chars[i]))
                        .font(font)
                        .foregroundColor(color)
                        .kerning(kerning)
                        .position(x: geometry.size.width / 2 + x, y: geometry.size.height / 2 + y)
                        .rotationEffect(charAngle)
                }
            }
        }
        .frame(height: radius * 0.7 + 18) // Height for arc + font
    }
}

struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let tabIndex: Int
    let selectedTab: Int
    let animationOffset: CGFloat
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @Namespace private var tabCircleNamespace
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color("appPrimaryAccent").opacity(0.18))
                            .frame(width: 36, height: 36)
                            .matchedGeometryEffect(id: "tabCircle\(tabIndex)", in: tabCircleNamespace)
                            .transition(.scale)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? Color("appPrimaryAccent") : Color("appTextSecondary"))
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
                        .animation(.easeInOut(duration: 0.3), value: rotation)
                }
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color("appPrimaryAccent") : Color("appTextSecondary"))
                    .opacity(isSelected ? 1.0 : 0.7)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == tabIndex {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 0.8
                    rotation = 360
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            } else {
                scale = 1.0
                rotation = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color("appScreenBG")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            AdvancedFloatingTabBar(selectedTab: .constant(0))
                .padding(.bottom, 8)
        }
    }
} 
