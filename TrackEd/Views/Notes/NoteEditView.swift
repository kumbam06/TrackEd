import SwiftUI

struct NoteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var title: String
    @State private var content: String
    @State private var isFavorite: Bool
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var showingTagInput = false
    
    let onSave: (String, String) -> Void
    
    init(note: NoteEntity?, onSave: @escaping (String, String) -> Void) {
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _isFavorite = State(initialValue: note?.isFavorite ?? false)
        _tags = State(initialValue: note?.tags ?? [])
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with favorite toggle
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Title Section
                            titleSection
                            
                            // Content Section
                            contentSection
                            
                            // Tags Section
                            tagsSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(isNewNote ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingTagInput) {
                tagInputSheet
            }
        }
    }
    
    private var isNewNote: Bool {
        title.isEmpty && content.isEmpty
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { isFavorite.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFavorite ? .red : .secondary)
                    
                    Text(isFavorite ? "Favorited" : "Add to Favorites")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFavorite ? .red : .secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isFavorite ?
                            Color.red.opacity(0.1) :
                            Color(.systemGray6)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("\(content.count) characters")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TITLE")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            TextField("Enter note title...", text: $title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTENT")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .kerning(0.5)
            
            TextEditor(text: $content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                .frame(minHeight: 200)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TAGS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .kerning(0.5)
                
                Spacer()
                
                Button(action: { showingTagInput = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Tag")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
            }
            
            if tags.isEmpty {
                Text("No tags added yet")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            removeTag(tag)
                        }
                    }
                }
            }
        }
    }
    
    private var tagInputSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Tag")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag Name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter tag name...", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTag()
                        }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: addTag) {
                    Text("Add Tag")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [.accentColor, .accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingTagInput = false
                        newTag = ""
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
            showingTagInput = false
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveNote() {
        // For now, we'll just save title and content
        // In a full implementation, you'd also save isFavorite and tags
        onSave(title, content)
        dismiss()
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.accentColor)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.1))
        )
    }
} 