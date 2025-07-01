# TrackEd - Student Productivity App

A comprehensive, production-ready iOS app built with SwiftUI and Core Data to help students manage tasks, notes, skills, and career development.

## 🚀 Features

### 📱 Core Functionality
- **Home Dashboard**: Overview of daily tasks, skills, and quick actions
- **Smart Planner**: Hour-based task planning with natural language input
- **Chat System**: Core Data-backed chat interface for student discussions
- **AI Assistant**: Placeholder for future AI integration (ChatGPT-ready)
- **Profile Management**: Editable profile with photo, contact info, and social links

### 🎯 Key Features
- **Natural Language Task Creation**: "Study SwiftUI at 8pm tomorrow"
- **Resume Builder**: Auto-generate PDF resumes from profile and skills
- **Theme System**: 10 beautiful themes with persistent selection
- **Core Data Integration**: Robust data persistence with proper relationships
- **Dark Mode Support**: Full light/dark mode compatibility
- **Modular Architecture**: Clean separation of concerns

### 🛠 Technical Stack
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Robust data persistence (not SwiftData)
- **PDFKit**: Resume generation and export
- **PhotosUI**: Profile photo selection
- **Modular Architecture**: Models, Views, ViewModels, Services

## 📁 Project Structure

```
TrackEd/
├── TrackEd/
│   ├── TrackEdApp.swift              # Main app entry point
│   ├── ContentView.swift             # Tab-based main view
│   ├── CoreData/
│   │   ├── TrackEd.xcdatamodeld/     # Core Data model
│   │   └── PersistenceController.swift
│   ├── Design/
│   │   ├── AppColors.swift           # Color system
│   │   └── AppTheme.swift            # Theme management
│   ├── Models/
│   │   ├── ProfileManager.swift      # Profile data management
│   │   ├── TaskManager.swift         # Task CRUD operations
│   │   ├── SkillManager.swift        # Skills management
│   │   └── ChatManager.swift         # Chat functionality
│   ├── Components/
│   │   ├── CardView.swift            # Reusable card components
│   │   └── TaskView.swift            # Task display components
│   ├── Views/
│   │   ├── Home/
│   │   │   └── HomeView.swift        # Dashboard view
│   │   ├── Planner/
│   │   │   ├── PlannerView.swift     # Main planner interface
│   │   │   ├── AddTaskView.swift     # Task creation
│   │   │   └── NaturalLanguageInputView.swift
│   │   ├── Chat/
│   │   │   ├── ChatListView.swift    # Chat list
│   │   │   └── ChatDetailView.swift  # Individual chat
│   │   ├── AskAI/
│   │   │   └── AskAIView.swift       # AI assistant placeholder
│   │   └── Profile/
│   │       ├── ProfileView.swift     # Profile display
│   │       ├── EditProfileView.swift # Profile editing
│   │       ├── ThemePickerView.swift # Theme selection
│   │       ├── ResumeExportView.swift # PDF generation
│   │       └── AddSkillView.swift    # Skill addition
│   └── Assets.xcassets/              # Color assets and images
```

## 🎨 Design System

### Colors
- `cardBG`: Card background color
- `primaryAccent`: Primary theme color
- `textPrimary`: Primary text color
- `textSecondary`: Secondary text color
- `strokeGray`: Border/stroke color
- `screenBG`: Screen background color
- `success`, `warning`, `error`, `info`: Status colors

### Components
- **CardView**: Consistent card styling with shadows
- **FloatingCardView**: Glass morphism effect
- **TaskView**: Task display with priority indicators
- **Theme System**: 10 predefined themes with gradients

## 📊 Core Data Model

### Entities
- **Profile**: User profile information
- **PlannerTask**: Task management with priorities
- **SkillEntity**: Skills for resume building
- **Chat**: Chat conversations
- **Message**: Individual chat messages
- **NoteEntity**: Notes (for future expansion)

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `TrackEd.xcodeproj` in Xcode
3. Build and run on simulator or device

### Core Data Setup
The app automatically creates the Core Data stack and initializes with sample data on first launch.

## 🔧 Configuration

### Adding New Themes
1. Add theme to `AppTheme.themes` array
2. Update color assets if needed
3. Theme will be automatically available in picker

### Extending Natural Language Parser
Modify `NaturalLanguageParser` in `TaskManager.swift` to add new time/date patterns.

## 📱 Usage

### Task Management
- Use natural language: "Study SwiftUI at 8pm tomorrow"
- Set priorities: "Submit report urgent"
- All-day tasks: "Team meeting all day Friday"

### Resume Building
1. Add skills with categories and proficiency levels
2. Edit profile information
3. Export professional PDF resume

### Chat System
- Create new chats for different topics
- Real-time message updates
- Persistent chat history

## 🎯 Future Enhancements

### Planned Features
- **AI Integration**: ChatGPT API integration
- **Notifications**: Local and push notifications
- **Cloud Sync**: iCloud Core Data sync
- **Analytics**: Progress tracking and insights
- **Collaboration**: Shared tasks and notes
- **Calendar Integration**: System calendar sync

### Technical Improvements
- **Unit Tests**: Comprehensive test coverage
- **UI Tests**: Automated UI testing
- **Performance**: Core Data optimization
- **Accessibility**: VoiceOver and accessibility improvements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- SwiftUI and Core Data documentation
- Apple Human Interface Guidelines
- iOS development community

---

**TrackEd** - Empowering students to track their educational journey and build their future careers. 