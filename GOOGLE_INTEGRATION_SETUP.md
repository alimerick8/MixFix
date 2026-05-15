# Google Integration Setup Guide

## Prerequisites

1. **Google Cloud Project**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select existing
   - Enable APIs:
     - Google Classroom API
     - Google Calendar API

2. **OAuth 2.0 Credentials**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Application type: **iOS**
   - Bundle ID: `com.yourcompany.MixFix` (or your actual bundle ID)
   - Download the credentials JSON

## Step 1: Install Dependencies

### Using Swift Package Manager (Recommended)

Add these packages to your project:

1. **GoogleSignIn-iOS**
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Version: 7.0.0 or later

2. **Google API Client for REST**
   - URL: `https://github.com/google/google-api-objectivec-client-for-rest`
   - Version: 3.0.0 or later

### Using CocoaPods (Alternative)

Add to your `Podfile`:

```ruby
pod 'GoogleSignIn'
pod 'GoogleAPIClientForREST/Calendar'
pod 'GoogleAPIClientForREST/Classroom'
```

Then run: `pod install`

## Step 2: Configure Info.plist

Add these keys to your `Info.plist`:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID_HERE.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
    <string>googlemail</string>
</array>
```

**Important:** Replace `YOUR_CLIENT_ID_HERE` with your actual Client ID from Google Cloud Console.

## Step 3: Update MixFixApp.swift

Add Google Sign-In initialization:

```swift
import GoogleSignIn

@main
struct MixFixApp: App {
    @StateObject private var store = DataStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    Task {
                        await GoogleServicesManager.shared.restorePreviousSignIn()
                    }
                }
        }
    }
}
```

## Step 4: Add Integration Button to ProfileView

Add this button to your ProfileView settings:

```swift
Section {
    NavigationLink {
        GoogleIntegrationView()
            .environmentObject(dataStore)
    } label: {
        HStack {
            Image(systemName: "g.circle.fill")
                .foregroundStyle(.blue)
            Text("Google Integration")
            Spacer()
            if GoogleServicesManager.shared.isSignedIn {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
} header: {
    Text("Integrations")
}
```

## Step 5: Test the Integration

1. **Sign In**
   - Open Profile → Google Integration
   - Tap "Sign in with Google"
   - Grant permissions for Classroom and Calendar

2. **Import Data**
   - Choose "Import Everything" or individual imports
   - Wait for sync to complete
   - Check your calendar for imported events

## Features

### Google Classroom Import
- ✅ Active courses
- ✅ Course assignments
- ✅ Due dates and descriptions
- ✅ Automatic categorization (Tests vs Assignments)
- ✅ Links assignments to course names

### Google Calendar Import
- ✅ Calendar events (4 months: -1 to +3)
- ✅ Event titles, descriptions, locations
- ✅ All-day events
- ✅ Timed events
- ✅ Automatic categorization

## Data Mapping

### Classroom Course → MixFix Class
- Course name → Class title
- Room → Location
- Schedule → Class times (manual setup needed)

### Classroom Assignment → MixFix Assignment/Test
- Title → Event title
- Due date → Event date
- Description → Notes
- Course name → className field
- Work type → Category (Assignment/Test)

### Calendar Event → MixFix Event
- Summary → Event title
- Start/End → Event times
- Location → Location
- Description → Notes
- Category → Extra Curriculars (default)

## Troubleshooting

### "Client ID not found"
- Verify `GIDClientID` is in Info.plist
- Check for typos in the Client ID

### "Authorization failed"
- Ensure OAuth consent screen is configured
- Check that APIs are enabled in Google Cloud
- Verify bundle ID matches OAuth credentials

### "No courses found"
- Ensure you're enrolled in Google Classroom courses
- Check that courses are ACTIVE (not archived)

### "No calendar events"
- Verify you have events in your Google Calendar
- Check date range (default: -1 to +3 months)

## Privacy & Security

- ✅ OAuth 2.0 secure authentication
- ✅ Credentials never stored locally
- ✅ Read-only access (no modifications to Google data)
- ✅ User can revoke access anytime
- ✅ One-time import (no continuous sync)

## Permissions Required

The app requests these Google scopes:

1. `classroom.courses.readonly` - Read course information
2. `classroom.coursework.me.readonly` - Read your assignments
3. `classroom.announcements.readonly` - Read announcements
4. `calendar.readonly` - Read calendar events

## Future Enhancements

Potential features to add:

- [ ] Two-way sync (update Google when MixFix changes)
- [ ] Automatic periodic sync
- [ ] Selective course import
- [ ] Grade sync from Classroom
- [ ] Assignment submission tracking
- [ ] Calendar event creation from MixFix

## Support

For issues with Google APIs:
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/ios)
- [Google Classroom API](https://developers.google.com/classroom)
- [Google Calendar API](https://developers.google.com/calendar)
