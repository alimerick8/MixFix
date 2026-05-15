# MixFix — Student Productivity & Wellness App

**MVP Build Status:** ✅ Core features implemented

## 🎯 What is MixFix?

A lightweight student-first app that blends smart scheduling, productivity tools, and stress-relief into one daily routine. Built for high school and college students managing classes, clubs, sports, jobs, and mental health.

---

## 📱 Features Implemented

### ✅ Core Navigation
- **5-tab interface**: Home, Calendar, Study, Mind, Profile
- Custom gradients per section:
  - **Home**: Gray (#b0b0b0) → Blue (#3b5998)
  - **Study**: Beige (#EEE8D5) → Off-white (#FAF9F6)
  - **Mind**: Green (#A3C586) → Blue (#3b5998)

### ✅ Home Tab
- Daily ritual flow: mood check → agenda → focus
- Quick actions: Mood tracker, Focus timer, Add task
- Agenda preview with today's events
- Mood check sheet with 1-5 emoji scale

### ✅ Calendar Tab
- Day view with class schedule
- Event list with time and location
- Add event hook (ready for EventKit integration)

### ✅ Study Tab
- **Pomodoro timer** with animated progress ring
- Start/Pause/Reset controls
- Task list with priority tags
- Custom beige gradient theme

### ✅ Mind Tab
- **Breathing exercises** quick start
- Curated meditation library (Exam Calm, Pre-Presentation, Sleep Wind-Down)
- Journal entry CTA
- Green→blue gradient theme

### ✅ Profile Tab
- Account info display
- **Plus subscription status** (active/inactive)
- Privacy toggles (personalized suggestions, analytics)
- Data export & delete account hooks
- Upgrade to Plus button → Paywall

### ✅ Monetization (StoreKit 2)
- **Product IDs configured**:
  - `com.mixfix.plus.monthly` — $4.99/month
  - `com.mixfix.plus.annual` — $29.99/year (Best Value)
  - `com.mixfix.founding.lifetime` — $19.99 lifetime (Founding Member)
- Paywall with transparent pricing
- Purchase flow integrated
- Restore purchases
- Subscription status tracking

### ✅ Persistence (SwiftData)
- **Models**: TaskItem, CalendarEvent, MoodEntry, Habit
- Local persistence with SwiftData
- Seed data for testing
- CRUD operations for tasks, events, moods

---

## 🛠 Tech Stack

- **SwiftUI** — Modern declarative UI
- **SwiftData** — Local persistence
- **StoreKit 2** — In-app purchases & subscriptions
- **Combine** — Reactive data flow
- **iOS 17+** — Target deployment

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- macOS Sonoma or later
- iOS 17+ device or simulator

### Setup Instructions

1. **Open the project**
   ```bash
   cd /Users/avalimerick/Downloads/MixFix/MixFix
   open MixFix.xcodeproj  # or .xcworkspace if using CocoaPods
   ```

2. **Configure Signing & Capabilities**
   - Select the MixFix target
   - Go to **Signing & Capabilities**
   - Set your **Team** and **Bundle Identifier**
   - Enable **In-App Purchase** capability

3. **StoreKit Configuration**
   - The project includes `Configuration.storekit` for local testing
   - In Xcode: **Product → Scheme → Edit Scheme → Run → Options**
   - Set **StoreKit Configuration** to `Configuration.storekit`

4. **Build & Run**
   - Select a simulator or device
   - Press **Cmd+R** to build and run

---

## 💳 Testing In-App Purchases

### Local Testing (Sandbox)
1. Use the included `Configuration.storekit` file
2. Run the app in the simulator
3. Navigate to **Profile → Upgrade to Plus**
4. Test purchases with sandbox accounts (no real charges)

### App Store Connect Setup (Production)
1. Create products in **App Store Connect → My Apps → [Your App] → In-App Purchases**
2. Product IDs must match:
   - `com.mixfix.plus.monthly`
   - `com.mixfix.plus.annual`
   - `com.mixfix.founding.lifetime`
3. Add localizations and pricing
4. Submit for review with app binary

---

## 📂 Project Structure

```
MixFix/
├── MixFixApp.swift              # App entry point, ModelContainer injection
├── ContentView.swift            # 5-tab navigation
├── Theme.swift                  # Colors, gradients, reusable UI components
├── Models.swift                 # View models (TaskItem, CalendarEvent, etc.)
├── DataStore.swift              # ObservableObject wrapping SwiftData
├── Views/
│   ├── HomeView.swift           # Daily ritual, mood check, agenda
│   ├── CalendarView.swift       # Day schedule
│   ├── StudyView.swift          # Pomodoro timer & tasks
│   ├── MindView.swift           # Breathing, meditations, journal
│   ├── ProfileView.swift        # Account, subscription, privacy
│   └── PaywallView.swift        # IAP purchase flow
├── Persistence/
│   ├── PersistenceModels.swift  # SwiftData @Model classes
│   └── PersistenceController.swift # ModelContainer setup
├── StoreKit/
│   └── SubscriptionManager.swift # StoreKit 2 purchase logic
└── Configuration.storekit       # Local IAP testing config
```

---

## 🎨 Design System

### Colors
- **Home gradient**: `#b0b0b0` → `#3b5998`
- **Study gradient**: `#EEE8D5` → `#FAF9F6`
- **Mind gradient**: `#A3C586` → `#3b5998`
- **Default gradient**: Purple → Blue → Cyan (Profile, Calendar)

### Typography
- **System font**: SF Pro (Apple's default)
- **Headings**: Bold, Large Title
- **Body**: Regular, Subheadline
- **Captions**: Secondary color

### Components
- **Glass cards**: `.ultraThinMaterial` with border
- **Corner radius**: 12pt (large), 8pt (small)
- **Tab icons**: Filled variants for better visibility

---

## 🔐 Privacy & Data Security

### Implemented
- Local-only data storage (SwiftData)
- No cloud sync (MVP)
- Privacy toggles in Profile
- Data export hook (ready for implementation)
- Account deletion hook (ready for implementation)

### Compliance Roadmap
- **FERPA**: Student data protection (minimal collection)
- **GDPR**: Data export, deletion, consent (hooks ready)
- **COPPA**: Parental consent for <13 (if applicable)
- **CCPA**: "Do Not Sell" option (hooks ready)

---

## 📈 Next Steps (Post-MVP)

### High Priority
1. **EventKit Integration**
   - Import Apple Calendar events
   - Google Calendar sync (OAuth)
   - Canvas/Google Classroom assignment import

2. **Notifications**
   - Class reminders
   - Task deadlines
   - Pomodoro break alerts
   - Habit streak nudges

3. **Habits (Full)**
   - Daily check-ins
   - Streak tracking
   - Progress charts
   - Group challenges

4. **Meditation Audio**
   - Audio player for guided meditations
   - Downloadable content packs (IAP)
   - Background audio support

5. **Onboarding**
   - 3-4 question setup flow
   - Progressive personalization
   - First-time user tutorial

### Medium Priority
6. **AI Personalization**
   - Adaptive study break suggestions
   - Stress-relief nudges based on calendar
   - Busy week alerts

7. **Widgets**
   - Home screen widget: Today's agenda + mood
   - Lock screen widget: Next class
   - Live Activity: Pomodoro timer

8. **Analytics**
   - Firebase Analytics integration
   - A/B testing framework
   - Retention metrics

### Low Priority
9. **Social Features**
   - Optional peer communities
   - Study groups
   - Wellness challenges

10. **Advanced Wellness**
    - Sleep tracking
    - Recovery tools
    - Guided journaling prompts

---

## 🐛 Known Issues / TODO

- [ ] Pomodoro timer doesn't persist across app restarts
- [ ] Task toggle doesn't update UI immediately (needs refresh)
- [ ] Calendar events are seed data only (no CRUD yet)
- [ ] Mood history not displayed anywhere
- [ ] Habit streaks not calculated correctly
- [ ] No error handling for failed purchases
- [ ] No loading states for data fetch
- [ ] Preview providers need in-memory persistence

---

## 📝 Business Model

### Freemium Tiers
- **Free**: Core schedule, basic tasks, limited wellness, ads, basic habits
- **Plus** ($4.99/mo or $29.99/yr):
  - Ad-free
  - Full wellness library
  - Unlimited habits
  - Custom reminders
  - Busy week alerts
- **Founding Member** ($19.99 lifetime): Limited promo for first 500 users

### Revenue Goals
- **Year 1 Target**: $6,000 net (to release deferred dev payment)
- **Scenarios**:
  - Pessimistic: ~$7.2k (1.5% conversion)
  - Base: ~$21.8k (3% conversion)
  - Optimistic: ~$55.9k (5% conversion)

---

## 👥 Team & Credits

- **Product Owner**: Ava Limerick
- **Developer**: [Your Name / Team]
- **Design**: Student-centric, inspired by Notion, Headspace, Calm
- **Business Plan**: Aug 26, 2025 MVP spec

---

## 📄 License

Proprietary — All rights reserved. Not open source.

---

## 📞 Support

For questions or issues:
- Email: ava@example.com
- GitHub Issues: (if applicable)
- Discord: (if applicable)

---

**Built with ❤️ for students, by students.**
