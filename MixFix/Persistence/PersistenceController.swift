//
//  PersistenceController.swift
//  MixFix
//

import Foundation
import SwiftData
import FirebaseAuth

@MainActor
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    init(inMemory: Bool = false) {
        let schema = Schema([
            TaskItemSD.self,
            CalendarEventSD.self,
            MoodEntrySD.self,
            HabitSD.self,
            JournalEntrySD.self,
            ClassCheckInSD.self,
            WeeklyReportSD.self,
            ReelSD.self,
            UserReelInteractionSD.self,
            UserReelPreferencesSD.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If schema migration fails, try deleting and recreating
            print("⚠️ ModelContainer creation failed: \(error)")
            print("Attempting to reset database...")
            
            // Delete the default SwiftData store
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
            }
            
            // Try again with fresh database
            do {
                container = try ModelContainer(for: schema, configurations: [configuration])
                print("✅ Database reset successful")
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }
    
    // Seed data for preview/testing
    func seedData(context: ModelContext) {
        // Use current user ID or seed_user for previews
        let seedUserId = Auth.auth().currentUser?.uid ?? "seed_user"
        
        let tasks = [
            TaskItemSD(userId: seedUserId, title: "Finish lab report", priority: 1),
            TaskItemSD(userId: seedUserId, title: "Read Chapter 4", priority: 2),
            TaskItemSD(userId: seedUserId, title: "Email club officer", priority: 3)
        ]
        tasks.forEach { context.insert($0) }
        
        let cal = Calendar.current
        let now = Date()
        if let s1 = cal.date(bySettingHour: 9, minute: 0, second: 0, of: now),
           let e1 = cal.date(byAdding: .minute, value: 50, to: s1),
           let s2 = cal.date(bySettingHour: 11, minute: 0, second: 0, of: now),
           let e2 = cal.date(byAdding: .minute, value: 75, to: s2),
           let s3 = cal.date(bySettingHour: 15, minute: 30, second: 0, of: now),
           let e3 = cal.date(byAdding: .minute, value: 60, to: s3),
           let s4 = cal.date(bySettingHour: 20, minute: 0, second: 0, of: now),
           let e4 = cal.date(byAdding: .minute, value: 60, to: s4) {
            let events = [
                CalendarEventSD(userId: seedUserId, title: "Math 201", start: s1, end: e1, location: "Hall A", category: "Exams", timeString: "9:00am", isCompleted: false, status: "notStarted"),
                CalendarEventSD(userId: seedUserId, title: "CS 101", start: s2, end: e2, location: "Lab 3", category: "Exams", timeString: "11:00am", isCompleted: false, status: "notStarted"),
                CalendarEventSD(userId: seedUserId, title: "Volleyball", start: s3, end: e3, location: nil, category: "Extra Curriculars", timeString: "3:30pm", isCompleted: false, status: "notStarted"),
                CalendarEventSD(userId: seedUserId, title: "History", start: s4, end: e4, location: nil, category: "Classes", timeString: "8:00pm", isCompleted: false, status: "notStarted")
            ]
            events.forEach { context.insert($0) }
        }
        
        let habits = [
            HabitSD(userId: seedUserId, title: "Hydrate", streak: 3),
            HabitSD(userId: seedUserId, title: "Journal", streak: 1)
        ]
        habits.forEach { context.insert($0) }
        
        let mood = MoodEntrySD(userId: seedUserId, mood: 3, note: "Okay morning")
        context.insert(mood)
        
        try? context.save()
    }
}
