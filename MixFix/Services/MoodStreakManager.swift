//
//  MoodStreakManager.swift
//  MixFix
//
//  Tracks low mood streaks and determines when to show challenge prompts
//

import Foundation
import SwiftData

class MoodStreakManager {
    static let shared = MoodStreakManager()
    
    private init() {}
    
    // Define low moods
    private let lowMoods: Set<Int> = [1, 2, 3, 4, 6] // Angry, Sad, Overwhelmed, Drained, Annoyed
    
    /// Check if a mood value is considered "low"
    func isLowMood(_ mood: Int) -> Bool {
        return lowMoods.contains(mood)
    }
    
    /// Get the mood name for display
    func moodName(for mood: Int) -> String {
        switch mood {
        case 1: return "Angry"
        case 2: return "Sad"
        case 3: return "Overwhelmed"
        case 4: return "Drained"
        case 5: return "Anxious"
        case 6: return "Annoyed"
        case 7: return "Okay"
        case 8: return "Good"
        case 9: return "Amazing"
        default: return "Unknown"
        }
    }
    
    /// Check if user has logged a low mood for 4 consecutive days (including today)
    func hasLowMoodStreak(moods: [MoodEntry], days: Int = 4) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check each of the last 'days' days
        for dayOffset in 0..<days {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return false
            }
            
            // Check if there's at least one low mood logged on this day
            let hasLowMoodOnDay = moods.contains { mood in
                calendar.isDate(mood.date, inSameDayAs: checkDate) && isLowMood(mood.mood)
            }
            
            if !hasLowMoodOnDay {
                return false
            }
        }
        
        return true
    }
    
    /// Get the most recent mood from today
    func getTodayMood(moods: [MoodEntry]) -> Int? {
        let calendar = Calendar.current
        let todayMoods = moods.filter { calendar.isDateInToday($0.date) }
        return todayMoods.first?.mood
    }
    
    /// Check if we should show the challenge prompt
    /// Returns (shouldShow, currentMoodName)
    func shouldShowChallenge(moods: [MoodEntry], currentMood: Int) -> (shouldShow: Bool, moodName: String) {
        guard isLowMood(currentMood) else {
            return (false, "")
        }
        
        let hasStreak = hasLowMoodStreak(moods: moods, days: 4)
        let name = moodName(for: currentMood)
        
        return (hasStreak, name)
    }
}
