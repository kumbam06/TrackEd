import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var noteListViewModel: NoteListViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingAddNote = false
    @State private var editingNote: NoteEntity? = nil
    @State private var searchText = ""
    @State private var selectedFilter: NoteFilter = .all
    
    private var filteredNotes: [NoteEntity] {
        let filtered = noteListViewModel.notes.filter { note in
            if searchText.isEmpty { return true }
            return (note.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (note.content?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .recent:
            return filtered.filter { note in
                guard let updatedAt = note.updatedAt else { return false }
                return Calendar.current.isDate(updatedAt, inSameDayAs: Date()) ||
                       Calendar.current.isDate(updatedAt, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            }
        case .favorites:
            return filtered.filter { $0.isFavorite }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search notes...")
        .fullScreenCover(isPresented: $showingAddNote) {
            NoteEditView(note: nil) { title, content in
                noteListViewModel.addNote(title: title, content: content)
            }
        }
        .fullScreenCover(item: $editingNote) { note in
            NoteEditView(note: note) { title, content in
                noteListViewModel.updateNote(note, title: title, content: content)
            }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NoteFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            count: filterCount(for: filter),
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredNotes) { note in
                    ModernNoteCard(note: note) {
                        editingNote = note
                    }
                    .contextMenu {
                        Button(action: { toggleFavorite(note) }) {
                            Label(
                                note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: note.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                        
                        Button(action: { editingNote = note }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { deleteNote(note) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for floating button
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.1),
                                Color.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "note.text")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(emptyStateSubtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddNote = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Create Your First Note")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
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
                        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Notes Found"
        }
        switch selectedFilter {
        case .all:
            return "No Notes Yet"
        case .recent:
            return "No Recent Notes"
        case .favorites:
            return "No Favorite Notes"
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms"
        }
        switch selectedFilter {
        case .all:
            return "Start capturing your thoughts, ideas, and important information"
        case .recent:
            return "Notes from today and yesterday will appear here"
        case .favorites:
            return "Mark notes as favorites to see them here"
        }
    }
    
    private func filterCount(for filter: NoteFilter) -> Int {
        switch filter {
        case .all:
            return noteListViewModel.notes.count
        case .recent:
            return noteListViewModel.notes.filter { note in
                guard let updatedAt = note.updatedAt else { return false }
                return Calendar.current.isDate(updatedAt, inSameDayAs: Date()) ||
                       Calendar.current.isDate(updatedAt, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            }.count
        case .favorites:
            return noteListViewModel.notes.filter { $0.isFavorite }.count
        }
    }
    
    private func toggleFavorite(_ note: NoteEntity) {
        note.isFavorite.toggle()
        noteListViewModel.updateNote(note, title: note.title ?? "", content: note.content ?? "")
    }
    
    private func deleteNote(_ note: NoteEntity) {
        noteListViewModel.deleteNote(note)
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.2) : Color(.systemGray5))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? .accentColor : Color(.systemGray6))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? .accentColor : Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernNoteCard: View {
    let note: NoteEntity
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title ?? "Untitled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        if let updatedAt = note.updatedAt {
                            Text(formattedDate(updatedAt))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if note.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                
                // Content Preview
                if let content = note.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Tags (if any)
                if let tags = note.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.systemBackground).opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.05),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(.separator).opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Models

enum NoteFilter: CaseIterable {
    case all, recent, favorites
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .recent: return "Recent"
        case .favorites: return "Favorites"
        }
    }
} 
