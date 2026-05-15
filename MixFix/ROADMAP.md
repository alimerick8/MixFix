# MixFix Product Roadmap

**Last Updated**: October 1, 2025  
**Current Version**: MVP (v1.0)

---

## 🎯 Vision

MixFix is the only app that integrates student productivity and mental wellness into one seamless daily ritual. We help students manage their time, focus on what matters, and protect their mental health—all without switching between 5 different apps.

---

## 📍 Current State (MVP — v1.0)

### ✅ Shipped Features
- 5-tab navigation (Home, Calendar, Study, Mind, Profile)
- Mood tracking with emoji scale
- Daily agenda preview
- Pomodoro timer with animated progress
- Basic task list
- Meditation library (UI only)
- Breathing exercises (UI only)
- StoreKit 2 subscriptions (Monthly, Annual, Lifetime)
- SwiftData persistence
- Custom gradients per section
- Paywall with transparent pricing

### 🚧 Known Limitations
- No calendar sync (EventKit not integrated)
- No audio playback for meditations
- No push notifications
- No habit tracking logic (UI only)
- No onboarding flow
- No analytics or A/B testing
- No widgets or Live Activities

---

## 🗓 Release Timeline

### v1.0 — MVP Launch (Oct 2025)
**Goal**: Validate product-market fit with 500 MAU and 2-3% conversion

**Focus**: Core loop working end-to-end
- ✅ Navigation and branding
- ✅ Mood check + agenda + Pomodoro
- ✅ Subscriptions (StoreKit 2)
- ✅ Local persistence (SwiftData)

**Launch Strategy**:
- Soft launch to 2-3 campuses (Marlborough HS, NYU)
- Campus ambassador program (5-10 students)
- Waitlist with referral codes
- Product Hunt launch

---

### v1.1 — Calendar Integration (Nov 2025)
**Goal**: 1,000 MAU, improve retention to 40% D7

**Features**:
1. **EventKit Integration** (High Priority)
   - Import Apple Calendar events
   - Read-only sync
   - Privacy: request permission, explain why
   - Display imported events in Calendar tab and Home agenda

2. **Google Calendar Sync** (Medium Priority)
   - OAuth 2.0 flow
   - Read-only access
   - Sync on app launch + background refresh

3. **Task Management** (High Priority)
   - Add/edit/delete tasks
   - Priority levels (P1, P2, P3)
   - Due dates
   - Swipe actions (complete, delete)
   - Filter: Today, Upcoming, Completed

4. **Notifications** (High Priority)
   - Local notifications for:
     - Class reminders (15 min before)
     - Task deadlines
     - Pomodoro breaks
   - Quiet hours (10pm–7am)
   - User-configurable

**Success Metrics**:
- 40% D7 retention
- 3-5% paid conversion
- <5% churn rate

---

### v1.2 — Wellness Expansion (Dec 2025)
**Goal**: 2,500 MAU, launch Plus tier features

**Features**:
1. **Audio Meditations** (High Priority)
   - AVPlayer integration
   - 5-10 minute guided meditations
   - Categories: Exam Calm, Sleep, Focus, Stress Relief
   - Background audio support
   - Download for offline playback

2. **Breathing Animations** (Medium Priority)
   - Animated circle: inhale → hold → exhale
   - Haptic feedback
   - 1-5 minute sessions
   - Presets: 4-7-8, Box Breathing, Calm

3. **Journal** (Medium Priority)
   - Daily prompts: "What stressed you today?"
   - Rich text editor
   - Mood tagging
   - Search and filter by date/mood

4. **Habit Tracking (Full)** (High Priority)
   - Daily check-ins
   - Streak calculation
   - Progress charts (7-day, 30-day)
   - Habit suggestions: Hydrate, Exercise, Sleep 8hrs, Journal

**Success Metrics**:
- 50% D7 retention
- 5% paid conversion
- $6k net revenue (unlock deferred dev payment)

---

### v1.3 — Personalization & AI (Jan 2026)
**Goal**: 5,000 MAU, 7% paid conversion

**Features**:
1. **AI-Driven Suggestions** (High Priority)
   - Analyze calendar + mood history
   - Suggest study breaks before exams
   - Recommend meditations during high-stress weeks
   - "Busy week alert" (Plus feature)

2. **Onboarding Flow** (High Priority)
   - 3-4 questions: Year in school, stress level, goals
   - Progressive personalization (not all at once)
   - First-time tutorial: "Try a mood check"

3. **Widgets** (Medium Priority)
   - Home screen widget: Today's agenda + mood
   - Lock screen widget: Next class
   - Live Activity: Pomodoro timer

4. **Gamification** (Low Priority)
   - Streaks for balanced days (study + wellness)
   - Badges: "7-day calm streak", "Pomodoro master"
   - Progress dashboard

**Success Metrics**:
- 60% D7 retention
- 7-10% paid conversion
- $15k net revenue

---

### v1.4 — Social & Community (Feb 2026)
**Goal**: 10,000 MAU, expand to 10+ campuses

**Features**:
1. **Peer Communities** (Optional, Moderated)
   - Study groups
   - Wellness challenges: "Sleep 8 hours for 7 days"
   - Safe, opt-in only
   - Moderation tools

2. **Campus Partnerships** (High Priority)
   - Institutional licenses for counseling centers
   - Bulk discounts for student orgs
   - Co-branded wellness events

3. **Referral Program** (High Priority)
   - "Invite 3 friends, get 1 month free"
   - Shareable links
   - Track referrals in Profile

**Success Metrics**:
- 15,000 MAU
- 10% paid conversion
- $40k net revenue

---

### v2.0 — Platform Expansion (Q2 2026)
**Goal**: 25,000 MAU, launch Android

**Features**:
1. **Android App** (High Priority)
   - Kotlin + Jetpack Compose
   - Feature parity with iOS
   - Google Play Store launch

2. **Web App** (Medium Priority)
   - React + TypeScript
   - Desktop experience for study sessions
   - Sync with mobile via cloud backend

3. **Cloud Sync** (High Priority)
   - Firebase or custom backend
   - Cross-device sync (iOS, Android, Web)
   - End-to-end encryption

4. **Learning Platform Integration** (High Priority)
   - Canvas LMS: pull assignments, deadlines
   - Google Classroom: sync announcements
   - Slack: team notifications

**Success Metrics**:
- 50,000 MAU (iOS + Android)
- 12% paid conversion
- $100k net revenue

---

## 🎨 Design Priorities

### Always
- **Mobile-first**: Fast, clean, intuitive
- **Student voice**: Relatable, not corporate
- **Transparency**: Clear pricing, no hidden fees
- **Privacy**: Minimal data collection, user control

### v1.x Focus
- Simplicity over features
- Quick wins (under 2 minutes)
- Delight moments (animations, haptics)

### v2.x Focus
- Cross-platform consistency
- Power user features (keyboard shortcuts, bulk actions)
- Advanced personalization

---

## 🚀 Go-to-Market Strategy

### Phase 1: Campus Seeding (Oct–Nov 2025)
- **Target**: 500 MAU
- **Channels**:
  - Campus ambassadors (Marlborough HS, NYU)
  - Instagram/TikTok micro-influencers
  - Waitlist with referral codes
  - Product Hunt soft launch

### Phase 2: Paid Acquisition (Dec 2025–Jan 2026)
- **Target**: 2,500 MAU
- **Channels**:
  - Facebook/Instagram ads (lookalike audiences)
  - TikTok ads (study content creators)
  - Apple Search Ads
  - Content marketing (blog, SEO)

### Phase 3: Partnerships (Feb–Apr 2026)
- **Target**: 10,000 MAU
- **Channels**:
  - University counseling centers
  - Student government associations
  - Active Minds chapters (600+ campuses)
  - Wellness fairs and events

### Phase 4: Scale (Q2 2026+)
- **Target**: 50,000+ MAU
- **Channels**:
  - Viral referral program
  - Press coverage (TechCrunch, EdSurge)
  - Influencer partnerships (macro-influencers)
  - Institutional sales (B2B2C)

---

## 💰 Revenue Projections

### Year 1 (Oct 2025–Oct 2026)
- **MAU Growth**: 500 → 15,000
- **Paid Conversion**: 2% → 7%
- **Net Revenue**: $6k → $40k
- **Key Milestone**: Unlock $6k deferred dev payment by Month 7

### Year 2 (Oct 2026–Oct 2027)
- **MAU Growth**: 15,000 → 75,000
- **Paid Conversion**: 7% → 12%
- **Net Revenue**: $40k → $250k
- **Key Milestone**: Break-even, hire first employee

### Year 3 (Oct 2027–Oct 2028)
- **MAU Growth**: 75,000 → 250,000
- **Paid Conversion**: 12% → 15%
- **Net Revenue**: $250k → $1M
- **Key Milestone**: Series A fundraising or profitability

---

## 🔬 Experiments & A/B Tests

### Pricing Tests (v1.1)
- Test $3.99 vs $4.99 monthly
- Test $24.99 vs $29.99 annual
- Test 7-day vs 14-day free trial

### Onboarding Tests (v1.3)
- 3 questions vs 5 questions
- Progressive vs all-at-once
- Video tutorial vs text walkthrough

### Paywall Tests (v1.2)
- Timing: Day 1 vs Day 3 vs Day 7
- Design: Full-screen vs bottom sheet
- Copy: Feature-focused vs outcome-focused

---

## 🎯 Success Metrics (KPIs)

### Acquisition
- **MAU**: Monthly Active Users
- **Install Rate**: App Store impressions → installs
- **CPI**: Cost per install (target: <$2)

### Activation
- **D1 Retention**: % users who return Day 1
- **D7 Retention**: % users who return Day 7 (target: 40%+)
- **Time to First Value**: Minutes to first mood check (target: <2 min)

### Monetization
- **Paid Conversion**: % free → paid (target: 5-10%)
- **ARPU**: Average revenue per user (target: $1-2/mo)
- **Churn Rate**: % paid users who cancel (target: <5%/mo)

### Engagement
- **Session Frequency**: Sessions per week (target: 5+)
- **Session Depth**: Features used per session (target: 2+)
- **Streak Length**: Days with balanced usage (study + wellness)

---

## 🛠 Technical Debt & Refactoring

### v1.1 Priorities
- [ ] Fix Pomodoro timer persistence across app restarts
- [ ] Optimize SwiftData queries (add indexes)
- [ ] Add error handling for all async operations
- [ ] Implement proper loading states
- [ ] Add unit tests for DataStore and SubscriptionManager

### v1.2 Priorities
- [ ] Refactor DataStore to use Repositories pattern
- [ ] Add Dependency Injection for testability
- [ ] Implement proper logging (OSLog)
- [ ] Add crash reporting (Firebase Crashlytics)
- [ ] Set up CI/CD pipeline (GitHub Actions)

---

## 🤝 Partnerships & Integrations

### Confirmed
- **Marlborough High School**: Beta testing, campus ambassadors
- **NYU**: Counseling center partnership (pending)

### In Discussion
- **Active Minds**: 600+ campus chapters, mental health advocacy
- **Canvas LMS**: Assignment sync integration
- **Google Classroom**: Announcement sync
- **Headspace**: Co-marketing or content licensing

### Wishlist
- **Apple Health**: Sleep tracking integration
- **Spotify**: Focus playlists
- **Notion**: Bi-directional sync for tasks
- **Slack**: Team notifications for study groups

---

## 📚 Resources

### Design Inspiration
- **Notion**: Customizable, student-friendly
- **Headspace**: Calm, wellness-focused
- **Duolingo**: Gamification, streaks
- **Instagram**: Content-first, gesture-driven

### Competitive Analysis
- **Notion**: Powerful but complex, no wellness
- **Headspace**: Wellness only, no productivity
- **Calm**: Sleep-focused, expensive
- **Shmoody**: Mood tracking, poor UX

### Market Research
- Student productivity app market: $1.32B (2024), 15% CAGR
- Education app market: $6.2B → $41.6B (2024-2033)
- Mental wellness apps: $4.2B (2023), 16% CAGR

---

## 🎓 Lessons Learned

### What Worked
- Simple, focused MVP
- Student-centric design language
- Transparent pricing (no bait-and-switch)
- Campus ambassador seeding

### What Didn't Work
- (TBD after launch)

### What to Try Next
- Viral referral mechanics
- Micro-influencer partnerships
- Institutional B2B2C sales

---

**Next Review**: December 1, 2025 (post-v1.1 launch)
