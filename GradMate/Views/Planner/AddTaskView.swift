import SwiftUI

struct AddTaskView: View {
    var onAdd: (String, String, Date, Bool, Int16) -> Void // title, notes, dueDate, isAllDay, priority
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var isAllDay: Bool = false
    @State private var priority: Int16 = 1
    
    private let priorities = [
        (1, "Low", Color("appSuccess")),
        (2, "Medium", Color("appWarning")),
        (3, "High", Color("appError"))
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("appScreenBG").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Section
                        CustomTextField(title: "Task Title", text: $title, placeholder: "Enter task title")
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color("appStrokeGray"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("appStrokeGray"), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if notes.isEmpty {
                                            Text("Add notes about this task...")
                                                .foregroundColor(Color("appTextSecondary"))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                                .accessibilityLabel(Text("Task notes"))
                        }
                        
                        // Due Date Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Due Date")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            VStack(spacing: 16) {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .labelsHidden()
                                
                                Toggle("All Day", isOn: $isAllDay)
                                    .toggleStyle(SwitchToggleStyle(tint: Color("appPrimaryAccent")))
                            }
                            .padding(16)
                            .background(Color("appStrokeGray"))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        
                        // Priority Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            HStack(spacing: 12) {
                                ForEach(priorities, id: \.0) { value, label, color in
                                    PriorityButton(
                                        title: label,
                                        isSelected: priority == value,
                                        color: color
                                    ) {
                                        priority = Int16(value)
                                    }
                                }
                            }
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("appTextPrimary"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                QuickActionButton(
                                    title: "Today",
                                    icon: "calendar",
                                    color: Color("appPrimaryAccent")
                                ) {
                                    dueDate = Date()
                                    isAllDay = false
                                }
                                
                                QuickActionButton(
                                    title: "Tomorrow",
                                    icon: "calendar.badge.plus",
                                    color: Color("appSuccess")
                                ) {
                                    dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                    isAllDay = false
                                }
                                
                                QuickActionButton(
                                    title: "This Week",
                                    icon: "calendar.circle",
                                    color: Color("appWarning")
                                ) {
                                    dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
                                    isAllDay = false
                                }
                                
                                QuickActionButton(
                                    title: "High Priority",
                                    icon: "exclamationmark.triangle",
                                    color: Color("appError")
                                ) {
                                    priority = 3
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("appTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onAdd(title, notes, dueDate, isAllDay, priority)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(Color("appPrimaryAccent"))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Supporting Views
// Note: CustomTextFieldStyle is now defined in SharedFormComponents.swift

struct PriorityButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? color : Color.clear)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: 2)
                    )
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? color : Color("appTextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? color.opacity(0.1) : Color("appStrokeGray"))
            .cornerRadius(12)
            .shadow(color: isSelected ? color.opacity(0.2) : Color.black.opacity(0.04), radius: isSelected ? 6 : 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color("appStrokeGray"), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
