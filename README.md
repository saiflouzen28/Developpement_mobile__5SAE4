# E-Learning Events App

A comprehensive Flutter application for discovering and joining educational events, built with modern design principles and robust SQLite database integration.

## ✨ Features

### 🔐 Authentication
- **Modern Login/Signup Screens** with impressive animations
- **Secure Password Storage** using bcrypt hashing
- **Persistent User Sessions** with Provider state management
- **Form Validation** with user-friendly error messages

### 📅 Event Management
- **Event Discovery** with beautiful grid layout
- **Advanced Search & Filtering** by category and keywords
- **Detailed Event Views** with descriptions, locations, and progress tracking
- **Event Registration** with seat availability tracking
- **User Schedule** showing joined events

### 🎨 Modern UI/UX
- **Impressive Animations** using AnimateDo package
- **Responsive Design** with Material 3
- **Dark/Light Theme Support**
- **Professional Typography** with Google Fonts
- **Smooth Transitions** and micro-interactions

### 🗺️ Location Features
- **Google Maps Integration** for event locations
- **Location-based Navigation** using maps_launcher
- **Address Display** with interactive maps

### 💾 Database Features
- **SQLite Database** with comprehensive schema
- **User Management** with secure authentication
- **Event CRUD Operations** with participant tracking
- **Junction Tables** for user-event relationships
- **Sample Data** pre-loaded for demonstration

## 🏗️ Architecture

### State Management
- **Provider Pattern** for clean state management
- **AuthProvider** for user authentication
- **EventsProvider** for event data management

### Database Schema
```sql
-- Users Table
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nom TEXT NOT NULL,
  prenom TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  numtel TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events Table
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  location TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  event_date TEXT NOT NULL,
  event_time TEXT NOT NULL,
  max_participants INTEGER NOT NULL,
  current_participants INTEGER DEFAULT 0,
  category TEXT NOT NULL,
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users (id)
);

-- User Events Junction Table
CREATE TABLE user_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  event_id INTEGER NOT NULL,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  UNIQUE(user_id, event_id)
);
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd elearning_events_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Demo Credentials
- **Email**: `demo@elearning.com`
- **Password**: `password123`

## 📱 Screens

### Authentication
- **Login Screen**: Modern design with smooth animations
- **Sign Up Screen**: Comprehensive registration form

### Main App
- **Events Screen**: Grid view with search and filtering
- **Event Details**: Comprehensive event information
- **Schedule Screen**: User's joined events
- **Profile Screen**: User management and settings

## 🎨 Design System

### Colors
- **Primary**: `#6366F1` (Indigo)
- **Secondary**: `#8B5CF6` (Purple)
- **Success**: `#10B981` (Green)
- **Warning**: `#F59E0B` (Yellow)
- **Error**: `#EF4444` (Red)

### Typography
- **Display Fonts**: Large headings with bold weights
- **Body Fonts**: Inter font family for readability
- **Consistent Spacing**: 8px grid system

### Components
- **Cards**: Elevated with subtle shadows
- **Buttons**: Consistent padding and border radius
- **Forms**: Modern input fields with validation

## 📦 Dependencies

### Core
- `flutter`: Framework
- `sqflite`: SQLite database
- `path`: Path manipulation
- `bcrypt`: Password hashing

### UI/UX
- `google_fonts`: Typography
- `animate_do`: Animations
- `cupertino_icons`: iOS icons

### State Management
- `provider`: State management

### Images & Caching
- `cached_network_image`: Network image caching
- `shimmer`: Loading placeholders

### Maps & Location
- `maps_launcher`: Map integration
- `url_launcher`: URL handling

### Utilities
- `shared_preferences`: Local storage
- `intl`: Internationalization

## 🔧 Configuration

### Database
The app uses SQLite with automatic database creation and migration. Sample data is pre-loaded for demonstration purposes.

### Themes
Both light and dark themes are supported with Material 3 design system.

### Navigation
Bottom navigation with three main sections:
- Events (Discover)
- Schedule (My Events)
- Profile (Settings)

## 🧪 Testing

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Event browsing and filtering
- [ ] Event joining and leaving
- [ ] Schedule management
- [ ] Profile management
- [ ] Navigation between screens
- [ ] Theme switching
- [ ] Database operations

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (limited)

## 🔒 Security

- Password hashing with bcrypt
- Secure database operations
- Input validation
- SQL injection prevention

## 🚀 Performance

- Image caching for better performance
- Efficient database queries
- Lazy loading of content
- Optimized animations

## 📝 Future Enhancements

- Push notifications
- Event reminders
- Social sharing
- Rating and reviews
- Advanced search filters
- Calendar integration
- Offline support
- Multi-language support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- **Your Name** - Initial work - [MyGitHub](https://github.com/achrafbannour1)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Fonts for typography
- All open-source contributors

---

**Built with ❤️ using Flutter**
