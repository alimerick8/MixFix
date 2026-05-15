//
//  SessionManager.swift
//  MixFix
//
//  Single source of truth for study session logging and adaptive time calculation
//

import Foundation
import SwiftData
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var todayStudyMinutes: Int = 0
    @Published var recommendedStudyMinutesToday: Double = 60.0  // Default starter estimate
    @Published var isUpdating: Bool = false
    
    private var modelContext: ModelContext?
    private var userId: String = ""
    
    // Constraints
    private let minDailyMinutes: Int = 30
    private let maxDailyMinutes: Int = 360  // 6 hours
    private let maxChangePercent: Double = 0.20  // Max 20% change per day
    private let smoothingFactor: Double = 0.3  // 30% new, 70% old
    
    private init() {}
    
    func configure(modelContext: ModelContext, userId: String) {
        self.modelContext = modelContext
        self.userId = userId
        print("📊 SessionManager: Configured for user \(userId)")
        
        // Initial load
        Task {
            await refreshStats()
        }
    }
    
    // MARK: - Session Logging (Single Source of Truth)
    
    /// Log a completed study session - THIS IS THE ONLY WAY TO UPDATE "ACTUAL STUDYING"
    func logCompletedSession(
        startTime: Date,
        endTime: Date,
        plannedMinutes: Int,
        timerPreset: String? = nil,
        mood: Int? = nil,
        notes: String? = nil
    ) {
        guard let modelContext = modelContext else {
            print("❌ SessionManager: No model context")
            return
        }
        
        // Calculate actual duration (excluding any paused time that might have been tracked separately)
        let actualDuration = Int(endTime.timeIntervalSince(startTime) / 60)
        
        let session = StudySessionLogSD(
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: actualDuration,
            plannedDurationMinutes: plannedMinutes,
            status: SessionStatus.completed.rawValue,
            timerPreset: timerPreset,
            pausedDurationMinutes: 0,  // TODO: Track paused time if needed
            mood: mood
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            print("✅ SessionManager: Logged session - \(actualDuration) min")
            
            // Fire update event
            Task {
                await refreshStats()
            }
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .studyDataDidChange, object: nil)
        } catch {
            print("❌ SessionManager: Failed to save session - \(error)")
        }
    }
    
    /// Log an abandoned session (user quit early)
    func logAbandonedSession(
        startTime: Date,
        endTime: Date,
        plannedMinutes: Int,
        actualMinutes: Int
    ) {
        guard let modelContext = modelContext else { return }
        
        let session = StudySessionLogSD(
            userId: userId,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: actualMinutes,
            plannedDurationMinutes: plannedMinutes,
            status: SessionStatus.abandoned.rawValue
        )
        
        modelContext.insert(session)
        try? modelContext.save()
        
        Task {
            await refreshStats()
        }
    }
    
    // MARK: - Data Retrieval (Query SessionLogs, NOT Schedule Objects)
    
    /// Get all completed sessions for a user in a time window
    func getCompletedSessions(from startDate: Date, to endDate: Date) -> [StudySessionLog] {
        guard let modelContext = modelContext else { return [] }
        
        // Capture instance variables as local constants for predicate
        let currentUserId = self.userId
        
        let descriptor = FetchDescriptor<StudySessionLogSD>(
            predicate: #Predicate { session in
                session.userId == currentUserId &&
                session.startTime >= startDate &&
                session.startTime <= endDate &&
                session.status == "completed"
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        return sessions.map { StudySessionLog(from: $0) }
    }
    
    /// Get sessions for today
    func getTodaySessions() -> [StudySessionLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return getCompletedSessions(from: startOfDay, to: endOfDay)
    }
    
    /// Get sessions for last N days
    func getSessionsForLastDays(_ days: Int) -> [StudySessionLog] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return getCompletedSessions(from: startDate, to: endDate)
    }
    
    // MARK: - Adaptive Study Time (Computed Value - NOT Stored)
    
    /// Compute recommended study time based on recent actual pace
    /// This is THE SINGLE FUNCTION used everywhere for adaptive time
    func computeRecommendedStudyTime(
        recentSessions: [StudySessionLog],
        plannedDailyMinutes: Int = 90,
        todayMood: Int? = nil
    ) -> Double {
        
        // Edge Case 1: No history yet - show starter estimate
        if recentSessions.isEmpty {
            return 60.0  // Default: 1 hour
        }
        
        // Edge Case 2: Only 1-2 sessions - use median
        if recentSessions.count <= 2 {
            let sorted = recentSessions.map { $0.actualMinutes }.sorted()
            let median = sorted.count == 1 ? sorted[0] : (sorted[0] + sorted[1]) / 2
            return Double(median)
        }
        
        // Step A: Calculate recent actual pace (last 7 days)
        let last7Days = recentSessions.prefix(while: { session in
            let daysSince = Calendar.current.dateComponents([.day], from: session.startTime, to: Date()).day ?? 0
            return daysSince <= 7
        })
        
        // Weighted average: last 3 days count more
        let last3Days = Array(last7Days.prefix(3))
        let older4Days = Array(last7Days.dropFirst(3))
        
        let last3DaysTotal = last3Days.reduce(0) { $0 + $1.actualMinutes }
        let older4DaysTotal = older4Days.reduce(0) { $0 + $1.actualMinutes }
        
        // Weight: 70% recent, 30% older
        let weightedTotal = (Double(last3DaysTotal) * 0.7) + (Double(older4DaysTotal) * 0.3)
        let avgDailyMinutes = weightedTotal / 7.0
        
        // Step B: Compare to plan
        let delta = Double(plannedDailyMinutes) - avgDailyMinutes
        
        // Step C: Adjust gradually with smoothing
        let oldRecommendation = recommendedStudyMinutesToday
        let targetAdjusted = avgDailyMinutes + (delta * 0.5)  // Move halfway toward plan
        
        var newRecommendation = (oldRecommendation * (1 - smoothingFactor)) + (targetAdjusted * smoothingFactor)
        
        // Cap changes: max ±20% per update
        let maxChange = oldRecommendation * maxChangePercent
        if abs(newRecommendation - oldRecommendation) > maxChange {
            newRecommendation = oldRecommendation + (newRecommendation > oldRecommendation ? maxChange : -maxChange)
        }
        
        // Apply absolute caps
        newRecommendation = max(Double(minDailyMinutes), min(Double(maxDailyMinutes), newRecommendation))
        
        return newRecommendation
    }
    
    /// Refresh today's stats and recommended time
    @MainActor
    func refreshStats() async {
        isUpdating = true
        
        // Get today's completed sessions
        let todaySessions = getTodaySessions()
        todayStudyMinutes = todaySessions.reduce(0) { $0 + $1.actualMinutes }
        
        print("📊 SessionManager: Found \(todaySessions.count) completed sessions today")
        for (i, session) in todaySessions.enumerated() {
            print("   Session \(i+1): \(session.durationMinutes) min (\(session.timerPreset ?? "unknown"))")
        }
        
        // Get last 7 days for adaptive calculation
        let recentSessions = getSessionsForLastDays(7)
        
        // Compute recommended time
        recommendedStudyMinutesToday = computeRecommendedStudyTime(
            recentSessions: recentSessions,
            plannedDailyMinutes: 90  // TODO: Get from user settings
        )
        
        isUpdating = false
        print("📊 SessionManager: TODAY ACTUAL = \(todayStudyMinutes) min, RECOMMENDED = \(Int(recommendedStudyMinutesToday)) min")
    }
    
    /// Get detailed statistics for debug view
    func getDetailedStats() -> StudySessionStats {
        let last7Days = getSessionsForLastDays(7)
        let last3Days = getSessionsForLastDays(3)
        
        let total7 = last7Days.reduce(0) { $0 + $1.actualMinutes }
        let total3 = last3Days.reduce(0) { $0 + $1.actualMinutes }
        
        let avgDaily = last7Days.isEmpty ? 0 : Double(total7) / 7.0
        let avgSession = last7Days.isEmpty ? 0 : Double(total7) / Double(last7Days.count)
        
        let completionRates = last7Days.map { $0.completionRate }
        let avgCompletion = completionRates.isEmpty ? 0 : completionRates.reduce(0, +) / Double(completionRates.count)
        
        return StudySessionStats(
            totalMinutes: total7,
            sessionCount: last7Days.count,
            avgDailyMinutes: avgDaily,
            avgSessionLength: avgSession,
            completionRate: avgCompletion,
            last7DaysMinutes: total7,
            last3DaysMinutes: total3
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let studyDataDidChange = Notification.Name("studyDataDidChange")
}
