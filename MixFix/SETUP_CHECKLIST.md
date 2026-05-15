# MixFix Setup Checklist

Complete these steps before submitting to TestFlight or App Store.

---

## ✅ Xcode Project Configuration

### 1. Signing & Capabilities
- [ ] Set **Team** in Signing & Capabilities
- [ ] Set **Bundle Identifier** (e.g., `com.yourcompany.mixfix`)
- [ ] Enable **In-App Purchase** capability
- [ ] Enable **Push Notifications** (for future reminders)

### 2. Info.plist Privacy Strings

Add these keys to your `Info.plist` file:

```xml
<!-- Calendar Access (for EventKit integration) -->
<key>NSCalendarsUsageDescription</key>
<string>MixFix needs access to your calendar to show your class schedule and events in the app.</string>

<!-- Reminders Access (optional, for task sync) -->
<key>NSRemindersUsageDescription</key>
<string>MixFix can sync your tasks with Apple Reminders to keep everything in one place.</string>

<!-- Notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>MixFix sends reminders for classes, tasks, and wellness breaks to help you stay on track.</string>

<!-- App Transport Security (if using HTTP for development) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

### 3. StoreKit Configuration
- [ ] In Xcode: **Product → Scheme → Edit Scheme → Run → Options**
- [ ] Set **StoreKit Configuration** to `Configuration.storekit`
- [ ] Test purchases in simulator before production

---

## 📦 App Store Connect Setup

### 1. Create App Record
- [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Create new app with Bundle ID matching your Xcode project
- [ ] Set app name: **MixFix**
- [ ] Choose primary category: **Productivity** or **Education**
- [ ] Secondary category: **Health & Fitness**

### 2. Configure In-App Purchases
Create three products:

#### Monthly Subscription
- **Product ID**: `com.mixfix.plus.monthly`
- **Reference Name**: MixFix Plus Monthly
- **Subscription Group**: MixFix Plus
- **Duration**: 1 Month
- **Price**: $4.99 USD (Tier 5)
- **Localization**:
  - **Display Name**: MixFix Plus Monthly
  - **Description**: Ad-free, full wellness library, unlimited habits, custom reminders, busy week alerts.

#### Annual Subscription
- **Product ID**: `com.mixfix.plus.annual`
- **Reference Name**: MixFix Plus Annual
- **Subscription Group**: MixFix Plus
- **Duration**: 1 Year
- **Price**: $29.99 USD (Tier 30)
- **Localization**:
  - **Display Name**: MixFix Plus Annual
  - **Description**: Best value! Ad-free, full wellness library, unlimited habits, custom reminders, busy week alerts.

#### Lifetime (Non-Renewing Subscription)
- **Product ID**: `com.mixfix.founding.lifetime`
- **Reference Name**: Founding Member Lifetime
- **Type**: Non-Renewing Subscription
- **Duration**: 1 Year (for non-renewing, set to max)
- **Price**: $19.99 USD (Tier 20)
- **Localization**:
  - **Display Name**: Founding Member Lifetime
  - **Description**: Lifetime access to MixFix Plus features. Limited founding member offer.

### 3. App Privacy
Fill out the **App Privacy** questionnaire:
- [ ] **Data Collection**: Minimal (email, mood logs, tasks, calendar events)
- [ ] **Data Usage**: Personalization, app functionality
- [ ] **Data Sharing**: None (unless you add analytics)
- [ ] **Data Retention**: User-controlled (export/delete available)

### 4. App Review Information
- [ ] **Demo Account**: Create a test account with sample data
- [ ] **Notes**: Explain the freemium model and subscription tiers
- [ ] **Contact Info**: Your support email

---

## 🎨 Assets Checklist

### App Icon
- [ ] Create 1024×1024 app icon (PNG, no transparency)
- [ ] Add to `Assets.xcassets/AppIcon`
- [ ] Ensure all required sizes are generated

### Screenshots (Required for App Store)
Capture on:
- [ ] 6.7" iPhone (iPhone 15 Pro Max) — 1290×2796
- [ ] 5.5" iPhone (iPhone 8 Plus) — 1242×2208
- [ ] 12.9" iPad Pro — 2048×2732

**Suggested screenshots**:
1. Home screen with mood check and agenda
2. Study screen with Pomodoro timer
3. Mind screen with meditations
4. Calendar view with classes
5. Profile with Plus subscription

### App Preview Videos (Optional but Recommended)
- [ ] 15-30 second demo video
- [ ] Show key features: mood check, Pomodoro, meditations
- [ ] Upload to App Store Connect

---

## 🧪 Testing Checklist

### Functional Testing
- [ ] All tabs navigate correctly
- [ ] Mood check saves and displays
- [ ] Pomodoro timer counts down accurately
- [ ] Tasks can be added and toggled
- [ ] Calendar events display correctly
- [ ] Paywall opens and displays products
- [ ] Purchase flow completes (sandbox)
- [ ] Restore purchases works
- [ ] Subscription status updates in Profile

### Edge Cases
- [ ] App launches with no data (first time)
- [ ] App handles failed purchases gracefully
- [ ] App works offline (local data only)
- [ ] App handles interrupted Pomodoro timer
- [ ] App respects system dark mode

### Performance
- [ ] App launches in <2 seconds
- [ ] Scrolling is smooth (60fps)
- [ ] No memory leaks
- [ ] Battery usage is reasonable

---

## 🚀 Pre-Launch Checklist

### Code
- [ ] Remove all `print()` debug statements (or use `#if DEBUG`)
- [ ] Remove seed data flag in production build
- [ ] Set proper error handling for all async operations
- [ ] Add analytics events (optional)

### Build Settings
- [ ] Set **Release** configuration for Archive
- [ ] Enable **Bitcode** (if required)
- [ ] Set **Deployment Target** to iOS 17.0
- [ ] Verify **Version** and **Build** numbers

### TestFlight
- [ ] Archive and upload to App Store Connect
- [ ] Add **What's New** notes for testers
- [ ] Invite internal testers (up to 100)
- [ ] Collect feedback and iterate

### App Store Submission
- [ ] Complete all App Store Connect fields
- [ ] Upload final screenshots and videos
- [ ] Write compelling **App Description**
- [ ] Add **Keywords** for ASO (App Store Optimization)
- [ ] Set **Pricing** and **Availability**
- [ ] Submit for review

---

## 📊 Post-Launch Monitoring

### Week 1
- [ ] Monitor crash reports in App Store Connect
- [ ] Track downloads and conversion rates
- [ ] Respond to user reviews
- [ ] Fix critical bugs in hotfix release

### Month 1
- [ ] Analyze retention metrics (D1, D7, D30)
- [ ] A/B test paywall pricing
- [ ] Gather user feedback via surveys
- [ ] Plan v1.1 feature updates

---

## 🔗 Useful Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [StoreKit Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Good luck with your launch! 🚀**
