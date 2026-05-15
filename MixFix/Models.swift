//
//  Models.swift
//  MixFix
//

import Foundation
import SwiftUI

struct TaskItem: Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var priority: Int // 1=high, 2=med, 3=low
    var isDone: Bool = false
    var notificationTime: Date? // Time to send reminder notification
    var notificationIdentifier: String? // For canceling notifications
}

enum AssignmentStatus: String, Codable, Hashable {
    case notStarted
    case inProgress
    case completed
}

struct CalendarEvent: Identifiable, Hashable {
    let id: UUID
    var title: String
    var start: Date
    var end: Date
    var location: String?
    var category: String // "Extra Curriculars", "Exams", "Assignments"
    var timeString: String // User-entered time string like "5:06pm" or "7/2/25"
    var isCompleted: Bool = false
    var status: AssignmentStatus = .notStarted
    var className: String? // The class this assignment/exam belongs to (e.g., "Math", "History")
    
    init(id: UUID = UUID(), title: String, start: Date, end: Date, location: String? = nil, category: String = "", timeString: String = "", isCompleted: Bool = false, status: AssignmentStatus = .notStarted, className: String? = nil) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.category = category
        self.timeString = timeString
        self.isCompleted = isCompleted
        self.status = status
        self.className = className
    }
}

struct MoodEntry: Identifiable, Hashable {
    let id: UUID = UUID()
    var date: Date = .now
    var mood: Int // 1..5
    var note: String?
}

struct Habit: Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var streak: Int
}

struct JournalEntry: Identifiable, Hashable {
    var id: UUID
    var title: String?
    var content: String
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String? = nil, content: String, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

struct StudentClass: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: String // Hex color for visual identification
    var teacher: String?
    
    init(id: UUID = UUID(), name: String, color: String = "#4CAF50", teacher: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.teacher = teacher
    }
}

struct ClassScheduleInfo: Codable, Hashable {
    var days: Set<String>
    var startTime: Date
    var endTime: Date
}

struct ClassCheckIn: Identifiable, Hashable {
    let id: UUID
    var date: Date          // Start-of-day for the class date
    var classId: UUID?
    var className: String
    var understandingScore: Int // 0–100
    var energyScore: Int        // 0–100
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct WeeklyReport: Identifiable, Hashable {
    let id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var totalStudySessions: Int
    var totalStudyMinutes: Int
    var perClassStudyStats: [PerClassStudyStats]
    var checkIns: [ClassCheckIn]
    var averageUnderstanding: Double // 0–100
    var averageEnergy: Double        // 0–100
    var perClassCheckInStats: [PerClassCheckInStats]
    var isViewed: Bool
    var generatedAt: Date
}

struct PerClassStudyStats: Identifiable, Hashable {
    let id: UUID
    var classId: UUID?
    var className: String
    var sessionCount: Int
    var totalMinutes: Int
}

struct PerClassCheckInStats: Identifiable, Hashable {
    let id: UUID
    var classId: UUID?
    var className: String
    var checkInCount: Int
    var averageUnderstanding: Double // 0–100
    var averageEnergy: Double        // 0–100
}
