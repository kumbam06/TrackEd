import SwiftUI

struct QuickActionsExpander: View {
    @Binding var isExpanded: Bool
    var actions: [QuickAction]
    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background when expanded
            if isExpanded {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { isExpanded = false } }
            }
            // Expander tab and panel
            HStack(spacing: 0) {
                // Tab (collapsed state)
                VStack {
                    Spacer()
                    if !isExpanded {
                        ZStack {
                            // Glass background
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                            // Vertical label
                            Text("Quick Actions")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(-90))
                                .frame(width: 110, height: 18)
                        }
                        .frame(width: 30, height: 120)
                        .padding(.vertical, 4)
                        .onTapGesture { withAnimation(.spring()) { isExpanded.toggle() } }
                    } else {
                        Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                Image(systemName: "chevron.left")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(18, corners: [UIRectCorner.topRight, UIRectCorner.bottomRight])
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 2, y: 2)
                        }
                        .frame(width: 44, height: 80)
                    }
                    Spacer()
                }
                // Panel
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick Actions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("Access your most used features")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                        
                        // Actions
                        VStack(spacing: 12) {
                            ForEach(actions) { action in
                                Button(action: { 
                                    action.handler()
                                    withAnimation { isExpanded = false } 
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: action.icon)
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .frame(width: 24, height: 24)
                                        Text(action.label)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .frame(width: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let handler: () -> Void
} 

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
} 