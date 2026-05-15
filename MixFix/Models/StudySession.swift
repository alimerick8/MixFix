//
//  StudySession.swift
//  MixFix
//
//  Session logging model for tracking actual completed study time
//

import Foundation
import SwiftData

// MARK: - Study Session Status
enum SessionStatus: String, Codable {
    case completed = "completed"
    case abandoned = "abandoned"
    case paused = "paused"
    case autoEnded = "auto_ended"
}

// MARK: - SwiftData Model
@Model
class StudySessionLogSD {
    @Attribute(.unique) var id: UUID
    var userId: String
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int  // Actual completed time (endTime - startTime)
    var plannedDurationMinutes: Int  // Original timer target
    var status: String  // SessionStatus raw value
    var timerPreset: String?  // Which preset was used (classic, study, etc.)
    var pausedDurationMinutes: Int  // Time spent paused
    var mood: Int?  // Mood when session started
    var notes: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        startTime: Date,
        endTime: Date? = nil,
        durationMinutes: Int = 0,
        plannedDurationMinutes: Int,
        status: String = SessionStatus.completed.rawValue,
        timerPreset: String? = nil,
        pausedDurationMinutes: Int = 0,
        mood: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.plannedDurationMinutes = plannedDurationMinutes
        self.status = status
        self.timerPreset = timerPreset
        self.pausedDurationMinutes = pausedDurationMinutes
        self.mood = mood
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - In-Memory Model
struct StudySessionLog: Identifiable, Codable {
    let id: UUID
    let userId: String
    let startTime: Date
    let endTime: Date?
    let durationMinutes: Int
    let plannedDurationMinutes: Int
    let status: SessionStatus
    let timerPreset: String?
    let pausedDurationMinutes: Int
    let mood: Int?
    let notes: String?
    let createdAt: Date
    
    var actualMinutes: Int {
        // Only count completed sessions
        guard status == .completed else { return 0 }
        return durationMinutes
    }
    
    var completionRate: Double {
        guard plannedDurationMinutes > 0 else { return 0 }
        return Double(durationMinutes) / Double(plannedDurationMinutes)
    }
    
    init(from sessionSD: StudySessionLogSD) {
        self.id = sessionSD.id
        self.userId = sessionSD.userId
        self.startTime = sessionSD.startTime
        self.endTime = sessionSD.endTime
        self.durationMinutes = sessionSD.durationMinutes
        self.plannedDurationMinutes = sessionSD.plannedDurationMinutes
        self.status = SessionStatus(rawValue: sessionSD.status) ?? .completed
        self.timerPreset = sessionSD.timerPreset
        self.pausedDurationMinutes = sessionSD.pausedDurationMinutes
        self.mood = sessionSD.mood
        self.notes = sessionSD.notes
        self.createdAt = sessionSD.createdAt
    }
}

// MARK: - Session Statistics
struct StudySessionStats {
    let totalMinutes: Int
    let sessionCount: Int
    let avgDailyMinutes: Double
    let avgSessionLength: Double
    let completionRate: Double
    let last7DaysMinutes: Int
    let last3DaysMinutes: Int
    
    static let empty = StudySessionStats(
        totalMinutes: 0,
        sessionCount: 0,
        avgDailyMinutes: 0,
        avgSessionLength: 0,
        completionRate: 0,
        last7DaysMinutes: 0,
        last3DaysMinutes: 0
    )
}
