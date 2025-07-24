# GradMate - Student Productivity App

## 🚦 Badges

![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange)
![Google Sign-In](https://img.shields.io/badge/Google%20Sign--In-Supported-green)

A comprehensive, production-ready iOS app built with SwiftUI, Core Data, and Firebase to help students manage tasks, notes, skills, and career development.

## 🚀 Features

### 📱 Core Functionality
- **Home Dashboard**: Overview of daily tasks, skills, and quick actions with customizable sections
- **Smart Planner**: Hour-based task planning with natural language input, calendar integration, and category management
- **Chat System**: Firestore-backed chat interface with real-time messaging and push notifications
- **Profile Management**: Digital ID card with front/back views, shareable profile, and comprehensive career tracking
- **Focus Mode**: Pomodoro-style focus sessions with breaks and progress tracking
- **Modern Onboarding & Auth**: Multi-step profile completion, redesigned login, Google Sign-In integration

### 🎯 Key Features
- **Natural Language Task Creation**: "Study SwiftUI at 8pm tomorrow"
- **Calendar Integration**: Monthly calendar view with task indicators and date-based filtering
- **Resume Builder**: Auto-generate PDF resumes from profile and skills
- **Theme System**: Beautiful themes with persistent selection
- **Core Data & Firestore Integration**: Robust data persistence and sync
- **Dark Mode Support**: Full light/dark mode compatibility with modern color scheme
- **Modular Architecture**: Clean separation of concerns
- **Google Sign-In**: Seamless authentication with Google accounts
- **Real-time Chat**: Firestore-powered chat system with push notifications
- **Focus Sessions**: Pomodoro timer with short/long breaks and progress tracking
- **Career Management**: Projects, internships, certifications, and work experience tracking
- **Customizable Home Screen**: User-configurable dashboard sections and quick actions
- **Progress Analytics**: Track productivity trends, career progress, and achievements
- **Profile Completion Flow**: Guided multi-step profile setup for new users

### 🛠 Technical Stack
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Robust data persistence (not SwiftData)
- **Firebase**: Authentication, Firestore database, Storage, and Cloud Messaging
- **Google Sign-In**: OAuth authentication
- **PDFKit**: Resume generation and export
- **PhotosUI**: Profile photo selection
- **AVFoundation**: Focus session sounds and notifications
- **Combine**: Reactive programming for state management
- **Modular Architecture**: Models, Views, ViewModels, Services

## 📁 Project Structure

```
GradMate/
├── GradMate/
│   ├── GradMate.swift                # Main app entry point
│   ├── AppDelegate.swift             # Firebase & Google Sign-In setup
│   ├── ContentView.swift             # Tab-based main view
│   ├── CoreData/
│   │   ├── GradMate.xcdatamodeld/    # Core Data model
│   │   └── PersistenceController.swift
│   ├── Models/
│   │   ├── AuthViewModel.swift       # Authentication management
│   │   ├── ProfileManager.swift      # Profile data management
│   │   ├── TaskManager.swift         # Task CRUD operations
│   │   ├── SkillManager.swift        # Skills management
│   │   ├── Firestore/
│   │   │   ├── FirestoreChatService.swift
│   │   │   └── ChatServiceProtocol.swift
│   │   └── Services/
│   │       ├── CareerDataService.swift
│   │       ├── CoverLetterDataService.swift
│   │       └── ProgressDataService.swift
│   ├── Components/
│   │   ├── CardView.swift            # Reusable card components
│   │   ├── TaskView.swift            # Task display components
│   │   ├── CustomLoaderOverlay.swift # Global loading overlay
│   │   └── GradMateLoader.swift      # Custom loading animation
│   ├── Views/
│   │   ├── Home/
│   │   │   └── HomeView.swift        # Dashboard view
│   │   ├── Planner/
│   │   │   ├── PlannerView.swift     # Main planner interface with calendar
│   │   │   ├── AddTaskView.swift     # Task creation
│   │   │   └── NaturalLanguageInputView.swift
│   │   ├── Chat/
│   │   │   ├── ChatListView.swift    # Chat list
│   │   │   ├── ChatDetailView.swift  # Individual chat
│   │   │   └── NewChatView.swift     # Create new chat
│   │   ├── Onboarding/
│   │   │   ├── AuthView.swift        # Login & Google Sign-In
│   │   │   ├── SignupFormView.swift  # Signup form
│   │   │   ├── ProfileCompletionView.swift # Multi-step profile setup
│   │   │   └── OnboardingView.swift  # App introduction
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift     # Profile display with ID card
│   │   │   ├── EditProfileView.swift # Profile editing
│   │   │   ├── ResumeExportView.swift # PDF generation
│   │   │   ├── AddSkillView.swift    # Skill addition
│   │   │   ├── ProjectListView.swift # Project management
│   │   │   ├── InternshipListView.swift # Internship tracking
│   │   │   └── WorkExperienceListView.swift # Work experience
│   │   └── Analytics/
│   │       └── ProgressDashboardView.swift # Progress tracking
│   ├── Assets.xcassets/              # Color assets and images
│   ├── GoogleService-Info.plist      # Firebase configuration
│   └── Info.plist                    # App configuration
```

## 🔥 Firebase Integration

### Authentication
- **Google Sign-In**: OAuth authentication with Google accounts
- **Email/Password**: Traditional email and password authentication
- **User Profile Sync**: Automatic profile data saving to Firestore
- **Profile Completion Flow**: Guided setup for new users

### Firestore Database
- **User Profiles**: Stored with Google account information
- **Chat System**: Real-time messaging with Firestore
- **Data Persistence**: Core Data + Firestore hybrid approach
- **Push Notifications**: Firebase Cloud Messaging integration

### Cloud Functions
- **Notification Triggers**: Automated push notifications for chat messages
- **Background Tasks**: Serverless functions for data processing
- **User Events**: Event-driven architecture for real-time updates

### Security Rules
```javascript
// Firestore Rules
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.resource.data.participants.hasAny([request.auth.uid]);
    }
  }
}
```

## 🎨 Design System

### Color Palette (Semantic, Accessible, Light/Dark Mode)
| Name              | Light Mode      | Dark Mode      | Usage                |
|-------------------|-----------------|---------------|----------------------|
| appPrimaryAccent  | #3877F2         | #4B9AFF        | Primary actions, logo|
| appCardBG         | #FFFFFF         | #1B1D22        | Card backgrounds     |
| appTextPrimary    | #1C1E26         | #F7F8FA        | Main text            |
| appTextSecondary  | #7C7E85         | #B4B6BC        | Secondary text       |
| appError          | #D93B4A         | #FF6B7A        | Error states         |
| appSuccess        | #38A169         | #4ADE80        | Success states       |
| appWarning        | #F2A73D         | #FBBF24        | Warning states       |
| appInfo           | #38B2AC         | #2DD4BF        | Info states          |
| appScreenBG       | #FAFCFC         | #111318        | Screen backgrounds   |
| appStrokeGray     | #F7F8FA         | #252A32        | Borders, strokes     |

### Components & UI Principles
- **CardView**: Consistent card styling with rounded corners and shadows
- **Modern Auth & Onboarding**: Redesigned login screen, multi-step profile completion, Google Sign-In integration
- **Global Loading System**: Centralized loading state management
- **Floating Action Buttons**: Modern, circular, and adaptive
- **Accessibility**: High contrast, large touch targets, VoiceOver support
- **Consistent Spacing**: Generous padding and spacing for clarity and comfort
- **Light/Dark Mode**: All screens and components adapt to system appearance
- **Calendar Integration**: Monthly calendar with task indicators and smooth animations

## 📊 Core Data & Firestore Model

### Entities
- **Profile**: User profile information and digital ID card data
- **PlannerTask**: Task management with priorities and categories
- **SkillEntity**: Skills for resume building
- **Chat**: Chat conversations and messages
- **FocusSession**: Focus mode tracking and statistics
- **Project**: Project portfolio management
- **Internship**: Internship experiences
- **Certification**: Professional certifications
- **WorkExperience**: Work history and roles
- **TaskCategory**: Custom task categorization
- **HomeScreenPreferences**: User dashboard preferences

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Firebase project setup

### Installation
1. Clone the repository
2. Open `GradMate.xcodeproj` in Xcode
3. Configure Firebase:
   - Add your `GoogleService-Info.plist` to the project
   - Update Firestore security rules
   - Configure Google Sign-In in Firebase Console
4. Build and run on simulator or device

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add iOS app to your Firebase project
3. Download `GoogleService-Info.plist` and add to project
4. Enable Authentication with Google Sign-In
5. Set up Firestore database with security rules
6. Configure Firebase Storage for profile photos

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

### Authentication
- **Google Sign-In**: Tap the Google Sign-In button for seamless authentication
- **Email/Password**: Traditional login with email and password
- **Profile Completion**: New users are guided through a multi-step profile setup
- **Profile Sync**: User data automatically syncs between Google account and app

### Task Management
- Use natural language: "Study SwiftUI at 8pm tomorrow"
- Set priorities: "Submit report urgent"
- All-day tasks: "Team meeting all day Friday"
- Calendar view: Monthly calendar with task indicators and date selection

### Resume Building
1. Add skills with categories and proficiency levels
2. Edit profile information
3. Export professional PDF resume

### Chat System
- Create new chats for different topics
- Real-time message updates via Firestore
- Persistent chat history

## 🎯 Recent Updates

### v2.2.0 - Profile Completion & Calendar Integration
- ✅ **Profile Completion Flow**: Multi-step guided profile setup for new users
- ✅ **Calendar Integration**: Monthly calendar view with task indicators and date-based filtering
- ✅ **Dynamic Navigation**: Collapsible navigation titles based on calendar state
- ✅ **Enhanced UI**: Improved shadows, animations, and visual hierarchy
- ✅ **Bug Fixes**: Resolved compilation errors and improved stability
- ✅ **Code Cleanup**: Removed deprecated features and improved architecture

### v2.1.0 - Firebase Push Notifications & Focus Mode
- ✅ **Push Notifications**: Implemented Firebase Cloud Messaging (FCM)
- ✅ **Focus Sessions**: Added Pomodoro-style focus mode with breaks
- ✅ **Digital ID Card**: New profile card with front/back views and sharing
- ✅ **Career Management**: Added projects, internships, and certifications tracking
- ✅ **Home Customization**: User-configurable dashboard sections
- ✅ **Task Categories**: Custom task categorization and filtering
- ✅ **Progress Analytics**: Enhanced tracking and visualization
- ✅ **UI Improvements**: Refined animations and transitions

### v2.0.0 - Firebase Integration & Authentication
- ✅ **Google Sign-In**: Complete OAuth integration with Google accounts
- ✅ **Firebase Configuration**: Proper AppDelegate setup and initialization
- ✅ **User Data Persistence**: Automatic profile data saving to Firestore
- ✅ **Global Loading System**: Centralized loading state management
- ✅ **Real-time Chat**: Firestore-powered chat system
- ✅ **Security**: Proper Firestore security rules implementation
- ✅ **UI Improvements**: Fixed loader behavior and Google Sign-In button

### Technical Improvements
- **AppDelegate Integration**: Proper Firebase initialization
- **Error Handling**: Comprehensive error management for authentication
- **Data Sync**: Seamless Core Data and Firestore integration
- **Performance**: Optimized loading states and data fetching
- **Code Quality**: Fixed compilation errors and improved stability

## 🎯 Future Enhancements

### Planned Features
- **AI Integration**: ChatGPT API integration for study assistance
- **Notifications**: Enhanced local and push notifications
- **Cloud Sync**: iCloud Core Data sync
- **Analytics**: Advanced progress tracking and insights
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
- Firebase documentation and SDKs
- Google Sign-In iOS SDK
- Apple Human Interface Guidelines
- iOS development community

---

**GradMate** - Empowering students to track their educational journey and build their future careers with modern authentication, real-time collaboration, and comprehensive productivity tools. 