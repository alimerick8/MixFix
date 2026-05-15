//
//  PersistenceModels.swift
//  MixFix
//
//  SwiftData models for persistence
//

import Foundation
import SwiftData

@Model
final class TaskItemSD {
    var id: UUID
    var userId: String
    var title: String
    var priority: Int // 1=high, 2=med, 3=low
    var isDone: Bool
    var createdAt: Date
    var notificationTime: Date?
    var notificationIdentifier: String?
    
    init(id: UUID = UUID(), userId: String, title: String, priority: Int, isDone: Bool = false, createdAt: Date = .now, notificationTime: Date? = nil, notificationIdentifier: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.createdAt = createdAt
        self.notificationTime = notificationTime
        self.notificationIdentifier = notificationIdentifier
    }
}

@Model
final class CalendarEventSD {
    var id: UUID
    var userId: String
    var title: String
    var start: Date
    var end: Date
    var location: String?
    var category: String
    var timeString: String
    var isCompleted: Bool
    var status: String
    var assignedClass: String // Changed from optional to non-optional to fix SwiftData corruption
    
    init(id: UUID = UUID(), userId: String, title: String, start: Date, end: Date, location: String? = nil, category: String = "", timeString: String = "", isCompleted: Bool = false, status: String = "notStarted", className: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.category = category
        self.timeString = timeString
        self.isCompleted = isCompleted
        self.status = status
        self.assignedClass = className ?? "" // Store empty string instead of nil
    }
}

@Model
final class MoodEntrySD {
    var id: UUID
    var userId: String
    var date: Date
    var mood: Int // 1..5
    var note: String?
    
    init(id: UUID = UUID(), userId: String, date: Date = .now, mood: Int, note: String? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.mood = mood
        self.note = note
    }
}

@Model
final class HabitSD {
    var id: UUID
    var userId: String
    var title: String
    var streak: Int
    var lastCompletedDate: Date?
    
    init(id: UUID = UUID(), userId: String, title: String, streak: Int = 0, lastCompletedDate: Date? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.streak = streak
        self.lastCompletedDate = lastCompletedDate
    }
}

@Model
final class JournalEntrySD {
    var id: UUID
    var userId: String
    var title: String?
    var content: String
    var createdAt: Date
    
    init(id: UUID = UUID(), userId: String, title: String? = nil, content: String, createdAt: Date = .now) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

@Model
final class ClassCheckInSD {
    var id: UUID
    var userId: String          // User isolation
    var date: Date              // Normalized to start of day in user's locale
    var classId: UUID?          // Optional link to StudentClass.id
    var className: String       // Denormalized name for display
    var understandingScore: Int // 0–100
    var energyScore: Int        // 0–100
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(),
         userId: String,
         date: Date,
         classId: UUID? = nil,
         className: String,
         understandingScore: Int,
         energyScore: Int,
         notes: String? = nil,
         createdAt: Date = .now,
         updatedAt: Date = .now) {
        self.id = id
        self.userId = userId
        self.date = date
        self.classId = classId
        self.className = className
        self.understandingScore = understandingScore
        self.energyScore = energyScore
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class WeeklyReportSD {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var isViewed: Bool
    var generatedAt: Date
    
    init(id: UUID = UUID(),
         weekStartDate: Date,
         weekEndDate: Date,
         isViewed: Bool = false,
         generatedAt: Date = .now) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.isViewed = isViewed
        self.generatedAt = generatedAt
    }
}
