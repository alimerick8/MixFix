# Firebase Setup Instructions for MixFix

## Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- A Google/Firebase account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "MixFix"
4. Disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter iOS bundle ID: `com.avalimerick.MixFix` (or your actual bundle ID)
3. Enter App nickname: "MixFix"
4. Download `GoogleService-Info.plist`
5. Drag `GoogleService-Info.plist` into your Xcode project (make sure "Copy items if needed" is checked)

## Step 3: Install Firebase SDK

### Using Swift Package Manager (Recommended)

1. In Xcode, go to File → Add Package Dependencies
2. Enter the Firebase SDK URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: 10.20.0 or later
4. Select the following packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseFirestoreSwift
5. Click "Add Package"

## Step 4: Initialize Firebase in Your App

Add this to your `MixFixApp.swift` file at the top:

```swift
import Firebase
```

Then in the `init()` of your App struct, add:

```swift
init() {
    FirebaseApp.configure()
    let context = PersistenceController.shared.container.mainContext
    _store = StateObject(wrappedValue: DataStore(modelContext: context, seed: false))
}
```

## Step 5: Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method
4. Click "Save"

## Step 6: Set Up Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Choose "Start in production mode" (we'll add rules next)
4. Select a Cloud Firestore location (choose closest to your users)
5. Click "Enable"

## Step 7: Configure Firestore Security Rules

In Firestore Database → Rules tab, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's subcollections (events, moods, etc.)
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Click "Publish"

## Step 8: Test Authentication

1. Build and run your app
2. Try signing up with a test email
3. Check Firebase Console → Authentication to see the new user
4. Try logging out and logging back in

## Step 9: Enable Data Syncing

The app will automatically sync data when:
- User completes onboarding
- User makes changes to events, moods, or settings
- User logs in (data is loaded from cloud)

## Troubleshooting

### "GoogleService-Info.plist not found"
- Make sure the file is in your project root
- Check that it's added to your app target

### "Firebase not initialized"
- Make sure `FirebaseApp.configure()` is called before any Firebase code
- Check that GoogleService-Info.plist is properly added

### Authentication errors
- Check that Email/Password is enabled in Firebase Console
- Verify your bundle ID matches in Firebase and Xcode

### Firestore permission denied
- Check security rules are properly configured
- Make sure user is authenticated before accessing Firestore

## Data Structure

Your Firestore database will have this structure:

```
users/
  {userId}/
    - email: string
    - userName: string
    - profileCircleColor: string
    - moodColorsEnabled: boolean
    - reminderDaysAhead: number
    - hasCompletedOnboarding: boolean
    - createdAt: timestamp
    - lastSyncDate: timestamp
    
    events/
      {eventId}/
        - title: string
        - start: timestamp
        - end: timestamp
        - category: string
        - className: string
        - isCompleted: boolean
        - status: string
    
    moods/
      {moodId}/
        - date: timestamp
        - mood: number
        - note: string
```

## Next Steps

1. Test the authentication flow
2. Add data syncing calls in appropriate places
3. Consider adding offline persistence
4. Implement password reset functionality
5. Add email verification (optional)

## Cost Considerations

Firebase Free Tier includes:
- 50,000 document reads/day
- 20,000 document writes/day
- 1 GB storage
- 10 GB/month network egress

This should be sufficient for development and moderate usage.
