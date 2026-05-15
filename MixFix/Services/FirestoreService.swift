//
//  FirestoreService.swift
//  MixFix
//
//  Cloud sync service for Firebase Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User ID Helper
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Calendar Events
    func syncCalendarEvent(_ event: CalendarEventSD) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let eventData: [String: Any] = [
            "id": event.id.uuidString,
            "title": event.title,
            "start": Timestamp(date: event.start),
            "end": Timestamp(date: event.end),
            "location": event.location ?? "",
            "category": event.category,
            "timeString": event.timeString,
            "isCompleted": event.isCompleted,
            "status": event.status,
            "assignedClass": event.assignedClass,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId)
            .collection("events").document(event.id.uuidString)
            .setData(eventData, merge: true)
    }
    
    func fetchCalendarEvents() async throws -> [[String: Any]] {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("events").getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func deleteCalendarEvent(id: UUID) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        try await db.collection("users").document(userId)
            .collection("events").document(id.uuidString).delete()
    }
    
    // MARK: - Mood Entries
    func syncMoodEntry(_ mood: MoodEntrySD) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let moodData: [String: Any] = [
            "id": mood.id.uuidString,
            "mood": mood.mood,
            "date": Timestamp(date: mood.date),
            "note": mood.note ?? "",
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId)
            .collection("moods").document(mood.id.uuidString)
            .setData(moodData, merge: true)
    }
    
    func fetchMoodEntries() async throws -> [[String: Any]] {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("moods").getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    // MARK: - Journal Entries
    func syncJournalEntry(_ journal: JournalEntrySD) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let journalData: [String: Any] = [
            "id": journal.id.uuidString,
            "title": journal.title ?? "",
            "content": journal.content,
            "createdAt": Timestamp(date: journal.createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId)
            .collection("journals").document(journal.id.uuidString)
            .setData(journalData, merge: true)
    }
    
    func fetchJournalEntries() async throws -> [[String: Any]] {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("journals").getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    // MARK: - User Settings
    func syncUserSettings(_ settings: [String: Any]) async throws {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        var settingsData = settings
        settingsData["updatedAt"] = Timestamp(date: Date())
        
        try await db.collection("users").document(userId)
            .collection("settings").document("preferences")
            .setData(settingsData, merge: true)
    }
    
    func fetchUserSettings() async throws -> [String: Any]? {
        guard let userId = currentUserId else {
            throw FirestoreError.noUser
        }
        
        let doc = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()
        
        return doc.data()
    }
    
    // MARK: - Batch Sync All Data
    func syncAllUserData(events: [CalendarEventSD], moods: [MoodEntrySD], journals: [JournalEntrySD]) async throws {
        print("🔄 Starting full data sync to Firestore...")
        
        // Sync all events
        for event in events {
            try await syncCalendarEvent(event)
        }
        print("✅ Synced \(events.count) events")
        
        // Sync all moods
        for mood in moods {
            try await syncMoodEntry(mood)
        }
        print("✅ Synced \(moods.count) mood entries")
        
        // Sync all journals
        for journal in journals {
            try await syncJournalEntry(journal)
        }
        print("✅ Synced \(journals.count) journal entries")
        
        print("✅ Full data sync complete!")
    }
}

// MARK: - Errors
enum FirestoreError: Error {
    case noUser
    case syncFailed
    case fetchFailed
}
