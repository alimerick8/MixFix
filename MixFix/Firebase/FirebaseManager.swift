//
//  FirebaseManager.swift
//  MixFix
//
//  Firebase authentication and data management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    @Published var currentUser: User?
    
    private init() {
        self.currentUser = auth.currentUser
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws {
        print("📝 FirebaseManager.signUp() called")
        print("📝 Email parameter: '\(email)'")
        print("📝 Email length: \(email.count)")
        print("📝 Password length: \(password.count)")
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            print("✅ Firebase sign-up successful!")
            print("✅ User ID: \(result.user.uid)")
            
            await MainActor.run {
                self.currentUser = result.user
            }
            
            // Create user document in Firestore
            try await createUserDocument(userId: result.user.uid, email: email)
        } catch let error as NSError {
            print("❌ Firebase sign-up failed in FirebaseManager")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔐 FirebaseManager.signIn() called")
        print("🔐 Email parameter: '\(email)'")
        print("🔐 Email length: \(email.count)")
        print("🔐 Email trimmed: '\(email.trimmingCharacters(in: .whitespacesAndNewlines))'")
        print("🔐 Password length: \(password.count)")
        print("🔐 Firebase App configured: \(FirebaseApp.app() != nil)")
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("✅ Firebase sign-in successful!")
            print("✅ User ID: \(result.user.uid)")
            
            await MainActor.run {
                self.currentUser = result.user
            }
            
            // Load user data from Firestore
            try await loadUserData(userId: result.user.uid)
        } catch let error as NSError {
            print("❌ Firebase sign-in failed in FirebaseManager")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            print("❌ Error userInfo: \(error.userInfo)")
            throw error
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
    }
    
    /// Validates the current auth session by attempting to refresh the token
    /// Returns true if session is valid, false if expired/invalid
    func validateCurrentSession() async -> Bool {
        guard let user = auth.currentUser else {
            print("🔐 No current user to validate")
            return false
        }
        
        do {
            // Force token refresh to validate the session
            _ = try await user.getIDTokenResult(forcingRefresh: true)
            print("✅ Auth session validated successfully")
            return true
        } catch {
            print("❌ Auth session validation failed: \(error.localizedDescription)")
            print("🔐 Session expired or invalid, signing out")
            try? auth.signOut()
            await MainActor.run {
                self.currentUser = nil
            }
            return false
        }
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = auth.currentUser, let email = user.email else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Re-authenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        
        // Update to new password
        try await user.updatePassword(to: newPassword)
    }
    
    // MARK: - User Data Management
    
    private func createUserDocument(userId: String, email: String) async throws {
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "lastSyncDate": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    private func loadUserData(userId: String) async throws {
        // Load user preferences and data from Firestore
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if let data = userDoc.data() {
            // Update UserDefaults with Firestore data
            await MainActor.run {
                if let userName = data["userName"] as? String {
                    UserDefaults.standard.set(userName, forKey: "userName")
                }
                if let profileColor = data["profileCircleColor"] as? String {
                    UserDefaults.standard.set(profileColor, forKey: "profileCircleColor")
                }
                if let moodColorsEnabled = data["moodColorsEnabled"] as? Bool {
                    UserDefaults.standard.set(moodColorsEnabled, forKey: "moodColorsEnabled")
                }
                if let reminderDaysAhead = data["reminderDaysAhead"] as? Int {
                    UserDefaults.standard.set(reminderDaysAhead, forKey: "reminderDaysAhead")
                }
                if let hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool {
                    UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
                }
            }
        }
    }
    
    // MARK: - Sync User Preferences
    
    func syncUserPreferences(
        userName: String,
        profileCircleColor: String,
        moodColorsEnabled: Bool,
        reminderDaysAhead: Int,
        hasCompletedOnboarding: Bool
    ) async throws {
        guard let userId = currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "userName": userName,
            "profileCircleColor": profileCircleColor,
            "moodColorsEnabled": moodColorsEnabled,
            "reminderDaysAhead": reminderDaysAhead,
            "hasCompletedOnboarding": hasCompletedOnboarding,
            "lastSyncDate": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId).setData(userData, merge: true)
    }
    
    // MARK: - Events Sync
    
    func syncEvents(_ events: [CalendarEvent]) async throws {
        guard let userId = currentUser?.uid else { return }
        
        let batch = db.batch()
        let eventsRef = db.collection("users").document(userId).collection("events")
        
        for event in events {
            let eventRef = eventsRef.document(event.id.uuidString)
            let eventData: [String: Any] = [
                "title": event.title,
                "start": Timestamp(date: event.start),
                "end": Timestamp(date: event.end),
                "location": event.location ?? "",
                "category": event.category,
                "timeString": event.timeString,
                "isCompleted": event.isCompleted,
                "status": event.status.rawValue,
                "className": event.className ?? ""
            ]
            batch.setData(eventData, forDocument: eventRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func loadEvents() async throws -> [CalendarEvent] {
        guard let userId = currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("users").document(userId).collection("events").getDocuments()
        
        var events: [CalendarEvent] = []
        for document in snapshot.documents {
            let data = document.data()
            
            guard let title = data["title"] as? String,
                  let startTimestamp = data["start"] as? Timestamp,
                  let endTimestamp = data["end"] as? Timestamp,
                  let category = data["category"] as? String,
                  let timeString = data["timeString"] as? String,
                  let isCompleted = data["isCompleted"] as? Bool,
                  let statusString = data["status"] as? String else {
                continue
            }
            
            let location = data["location"] as? String
            let className = data["className"] as? String
            let status = AssignmentStatus(rawValue: statusString) ?? .notStarted
            
            let event = CalendarEvent(
                id: UUID(uuidString: document.documentID) ?? UUID(),
                title: title,
                start: startTimestamp.dateValue(),
                end: endTimestamp.dateValue(),
                location: location,
                category: category,
                timeString: timeString,
                isCompleted: isCompleted,
                status: status,
                className: className
            )
            events.append(event)
        }
        
        return events
    }
    
    // MARK: - Moods Sync
    
    func syncMoods(_ moods: [MoodEntry]) async throws {
        guard let userId = currentUser?.uid else { return }
        
        let batch = db.batch()
        let moodsRef = db.collection("users").document(userId).collection("moods")
        
        for mood in moods {
            let moodRef = moodsRef.document(mood.id.uuidString)
            let moodData: [String: Any] = [
                "date": Timestamp(date: mood.date),
                "mood": mood.mood,
                "note": mood.note ?? ""
            ]
            batch.setData(moodData, forDocument: moodRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func loadMoods() async throws -> [MoodEntry] {
        guard let userId = currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("users").document(userId).collection("moods").getDocuments()
        
        var moods: [MoodEntry] = []
        for document in snapshot.documents {
            let data = document.data()
            
            guard let dateTimestamp = data["date"] as? Timestamp,
                  let moodValue = data["mood"] as? Int else {
                continue
            }
            
            let note = data["note"] as? String
            
            let mood = MoodEntry(
                date: dateTimestamp.dateValue(),
                mood: moodValue,
                note: note
            )
            moods.append(mood)
        }
        
        return moods
    }
    
    // MARK: - Delete Event
    
    func deleteEvent(eventId: UUID) async throws {
        guard let userId = currentUser?.uid else { return }
        
        try await db.collection("users")
            .document(userId)
            .collection("events")
            .document(eventId.uuidString)
            .delete()
    }
    
    // MARK: - Delete Mood
    
    func deleteMood(moodId: UUID) async throws {
        guard let userId = currentUser?.uid else { return }
        
        try await db.collection("users")
            .document(userId)
            .collection("moods")
            .document(moodId.uuidString)
            .delete()
    }
}
