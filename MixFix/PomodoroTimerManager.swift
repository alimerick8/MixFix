//
//  PomodoroTimerManager.swift
//  MixFix
//

import SwiftUI
import UserNotifications
import Combine

enum PomodoroPreset: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case extended = "Extended"
    case short = "Short Focus"
    case study = "Study Session"
    case creative = "Creative Work"
    case anxious = "Calm Mode"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    func focusDuration(customFocus: Int? = nil) -> Int {
        switch self {
        case .classic: return 25 * 60
        case .extended: return 40 * 60
        case .short: return 15 * 60
        case .study: return 50 * 60
        case .creative: return 30 * 60
        case .anxious: return 20 * 60
        case .custom: return (customFocus ?? 25) * 60
        }
    }
    
    func breakDuration(customBreak: Int? = nil) -> Int {
        switch self {
        case .classic: return 5 * 60
        case .extended: return 10 * 60
        case .short: return 3 * 60
        case .study: return 10 * 60
        case .creative: return 7 * 60
        case .anxious: return 5 * 60
        case .custom: return (customBreak ?? 5) * 60
        }
    }
    
    func description(customFocus: Int? = nil, customBreak: Int? = nil) -> String {
        switch self {
        case .classic: return "25 min focus · 5 min break"
        case .extended: return "40 min focus · 10 min break"
        case .short: return "15 min focus · 3 min break"
        case .study: return "50 min focus · 10 min break"
        case .creative: return "30 min focus · 7 min break"
        case .anxious: return "20 min focus · 5 min break"
        case .custom: return "\(customFocus ?? 25) min focus · \(customBreak ?? 5) min break"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "timer"
        case .extended: return "clock.arrow.circlepath"
        case .short: return "bolt.fill"
        case .study: return "book.fill"
        case .creative: return "paintbrush.fill"
        case .anxious: return "heart.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

class PomodoroTimerManager: ObservableObject {
    static let shared = PomodoroTimerManager()
    
    @Published var isRunning = false
    @Published var seconds: Int = 25 * 60
    @Published var timerMode: TimerMode = .focus
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var currentPreset: PomodoroPreset = .classic
    @Published var customFocusMinutes: Int = 25
    @Published var customBreakMinutes: Int = 5
    @Published var inStudySession: Bool = false
    @Published var didCompleteFocusInSession: Bool = false
    @Published var sessionExtensionMinutes: Int = 10
    @Published var completedCycles: Int = 0 // One cycle = focus + break
    @Published var isLockedSession: Bool = false // When true, app should stay on the timer screen
    
    private var timer: Timer?
    private var targetEndDate: Date? // Wall-clock end time for the current segment
    private let maxCycles: Int = 4   // Stop after 4 full focus+break cycles
    private var currentNotificationId: String? // Pending system notification for current segment
    
    // Session tracking for logging actual study time
    private var focusSessionStartTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var lastPauseTime: Date?
    
    // Persistence for locked sessions
    @AppStorage("persistedLockedSession") private var persistedLockedSession: Bool = false
    @AppStorage("persistedTimerSeconds") private var persistedTimerSeconds: Int = 0
    @AppStorage("persistedTimerMode") private var persistedTimerModeRaw: String = "focus"
    @AppStorage("persistedTargetEndDate") private var persistedTargetEndDateTimestamp: Double = 0
    @AppStorage("persistedWasRunning") private var persistedWasRunning: Bool = false
    @AppStorage("persistedInStudySession") private var persistedInStudySession: Bool = false
    @AppStorage("persistedCompletedCycles") private var persistedCompletedCycles: Int = 0
    
    private init() {
        // Restore locked session on init if one exists
        restoreLockedSessionIfNeeded()
    }
    
    func startTimer() {
        isRunning = true
        
        // Track focus session start time for logging
        if timerMode == .focus && focusSessionStartTime == nil {
            focusSessionStartTime = Date()
            pausedDuration = 0
        }
        
        // Resume from pause
        if let pauseTime = lastPauseTime {
            pausedDuration += Date().timeIntervalSince(pauseTime)
            lastPauseTime = nil
        }
        
        // If we don't already have a target end date for this segment, set one now
        if targetEndDate == nil {
            targetEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        }
        
        // Schedule a system notification so the user is alerted even if the
        // app is backgrounded or the phone is locked.
        scheduleSegmentNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let target = self.targetEndDate {
                let remaining = Int(max(0, floor(target.timeIntervalSinceNow)))
                self.seconds = remaining
                if remaining <= 0 {
                    self.handleTimerComplete()
                }
            } else {
                // Fallback in case targetEndDate is missing
                if self.seconds > 0 {
                    self.seconds -= 1
                } else {
                    self.handleTimerComplete()
                }
            }
        }
    }
    
    func stopTimer() {
        // Track pause time if stopping mid-session
        if isRunning && timerMode == .focus {
            lastPauseTime = Date()
        }
        
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetEndDate = nil
        cancelSegmentNotification()
    }
    
    func resetTimer() {
        // Log abandoned session if user resets mid-focus
        if timerMode == .focus, let startTime = focusSessionStartTime {
            let actualMinutes = Int((Date().timeIntervalSince(startTime) - pausedDuration) / 60)
            if actualMinutes > 0 {
                let plannedMinutes = currentPreset.focusDuration(customFocus: customFocusMinutes) / 60
                SessionManager.shared.logAbandonedSession(
                    startTime: startTime,
                    endTime: Date(),
                    plannedMinutes: plannedMinutes,
                    actualMinutes: actualMinutes
                )
            }
        }
        
        stopTimer()
        timerMode = .focus
        seconds = currentPreset.focusDuration(customFocus: customFocusMinutes)
        completedCycles = 0
        focusSessionStartTime = nil
        pausedDuration = 0
        lastPauseTime = nil
        
        // Clear persisted state when session is reset
        clearPersistedSession()
    }
    
    func changePreset(_ preset: PomodoroPreset) {
        let wasRunning = isRunning
        stopTimer()
        currentPreset = preset
        timerMode = .focus
        seconds = preset.focusDuration(customFocus: customFocusMinutes)
        completedCycles = 0
        if wasRunning {
            startTimer()
        }
    }
    
    private func handleTimerComplete() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // When a break finishes, count a completed cycle and optionally stop
        if timerMode == .break_ {
            completedCycles += 1
            if completedCycles >= maxCycles {
                // Session complete after 4 full cycles (focus+break pairs)
                stopTimer()
                alertMessage = "Session Complete"
                showAlert = true
                sendNotification(title: "Session Complete ✅", body: "You've finished 4 focus + break cycles. Take a longer rest or extend if you like.")
                return
            }
        }
        
        // Alternate between focus and break modes when a timer completes,
        // preserving the classic Pomodoro loop (focus → break → focus → break ...)
        if timerMode == .focus {
            // LOG COMPLETED FOCUS SESSION
            if let startTime = focusSessionStartTime {
                let endTime = Date()
                let actualMinutes = Int((endTime.timeIntervalSince(startTime) - pausedDuration) / 60)
                let plannedMinutes = currentPreset.focusDuration(customFocus: customFocusMinutes) / 60
                
                print("⏱️ Timer: Logging completed session - \(actualMinutes) min (planned: \(plannedMinutes) min)")
                
                SessionManager.shared.logCompletedSession(
                    startTime: startTime,
                    endTime: endTime,
                    plannedMinutes: plannedMinutes,
                    timerPreset: currentPreset.rawValue,
                    mood: nil  // TODO: Get current mood if available
                )
                focusSessionStartTime = nil
                pausedDuration = 0
            }
            
            timerMode = .break_
            seconds = currentPreset.breakDuration(customBreak: customBreakMinutes)
            alertMessage = "Break Time"
            let breakMins = currentPreset.breakDuration(customBreak: customBreakMinutes) / 60
            sendNotification(title: "Break Time! 🎉", body: "Take a \(breakMins)-minute break. You earned it!")
        } else {
            timerMode = .focus
            seconds = currentPreset.focusDuration(customFocus: customFocusMinutes)
            alertMessage = "Focus Time"
            let focusMins = currentPreset.focusDuration(customFocus: customFocusMinutes) / 60
            sendNotification(title: "Focus Time! 💪", body: "Time to get back to work. \(focusMins) minutes of focus ahead.")
        }
        
        // Start a new wall-clock segment for the next phase
        targetEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        scheduleSegmentNotification()
        
        // Show alert
        showAlert = true
        
        // Auto-dismiss alert after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showAlert = false
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Segment Notifications (background-safe)

    /// Schedule a local notification for the current focus/break segment so the
    /// user is alerted even if the app is backgrounded or the device is locked.
    private func scheduleSegmentNotification() {
        // Cancel any existing pending notification for this segment
        cancelSegmentNotification()
        
        guard seconds > 0 else { return }
        
        let content = UNMutableNotificationContent()
        if timerMode == .focus {
            content.title = "Focus Block Done"
            content.body = "Time for a break. Nice work."
        } else {
            content.title = "Break Finished"
            content.body = "Ready for the next focus block?"
        }
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let id = UUID().uuidString
        currentNotificationId = id
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancel the pending segment notification, e.g. when the user pauses or resets.
    private func cancelSegmentNotification() {
        if let id = currentNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            currentNotificationId = nil
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    // MARK: - Locked Session Persistence
    
    /// Save locked session state when app backgrounds
    func persistLockedSession() {
        guard isLockedSession else {
            // Not locked - clear any persisted state
            clearPersistedSession()
            return
        }
        
        print("💾 Persisting locked session state")
        persistedLockedSession = true
        persistedTimerSeconds = seconds
        persistedTimerModeRaw = timerMode == .focus ? "focus" : "break"
        persistedTargetEndDateTimestamp = targetEndDate?.timeIntervalSince1970 ?? 0
        persistedWasRunning = isRunning
        persistedInStudySession = inStudySession
        persistedCompletedCycles = completedCycles
    }
    
    /// Restore locked session state when app reopens
    private func restoreLockedSessionIfNeeded() {
        guard persistedLockedSession else { return }
        
        print("♻️ Restoring locked session state")
        isLockedSession = true
        seconds = persistedTimerSeconds
        timerMode = persistedTimerModeRaw == "focus" ? .focus : .break_
        completedCycles = persistedCompletedCycles
        inStudySession = persistedInStudySession
        
        // Restore target end date if valid
        if persistedTargetEndDateTimestamp > 0 {
            targetEndDate = Date(timeIntervalSince1970: persistedTargetEndDateTimestamp)
            
            // Recalculate remaining seconds based on target end date
            if let target = targetEndDate {
                let remaining = Int(max(0, floor(target.timeIntervalSinceNow)))
                seconds = remaining
                
                // If time has expired while app was closed, handle completion
                if remaining <= 0 {
                    handleTimerComplete()
                }
            }
        }
        
        // DO NOT auto-resume timer - wait for user to see the session first
        // Timer will resume when user returns to foreground (handled in LockEnforcementContainer)
    }
    
    /// Clear persisted session data
    private func clearPersistedSession() {
        persistedLockedSession = false
        persistedTimerSeconds = 0
        persistedTimerModeRaw = "focus"
        persistedTargetEndDateTimestamp = 0
        persistedWasRunning = false
        persistedInStudySession = false
        persistedCompletedCycles = 0
    }
    
    /// Pause timer when app backgrounds during locked session
    func pauseForBackground() {
        guard isLockedSession, isRunning else { return }
        
        print("⏸️ Pausing locked session for background")
        stopTimer() // This will set lastPauseTime
        persistLockedSession()
    }
    
    /// Resume timer when app foregrounds during locked session
    func resumeFromBackground() {
        guard isLockedSession, persistedWasRunning else { return }
        
        print("▶️ Resuming locked session from background")
        startTimer()
    }
    
    func updatePresetBasedOnMood(_ mood: Int?) {
        guard let mood = mood else {
            // No mood logged, use classic
            if currentPreset != .classic {
                changePreset(.classic)
            }
            return
        }
        
        let recommendedPreset: PomodoroPreset
        
        switch mood {
        case 1: // Angry - Short bursts to channel energy
            recommendedPreset = .short
        case 2: // Sad - Creative work to process emotions
            recommendedPreset = .creative
        case 3: // Overwhelmed - Short focus to reduce stress
            recommendedPreset = .short
        case 4: // Drained - Calm mode with shorter sessions
            recommendedPreset = .anxious
        case 5: // Anxious - Calm mode for manageable chunks
            recommendedPreset = .anxious
        case 6: // Annoyed - Short focus to work through irritation
            recommendedPreset = .short
        case 7: // Okay - Classic Pomodoro
            recommendedPreset = .classic
        case 8: // Good - Extended sessions for productivity
            recommendedPreset = .extended
        case 9: // Amazing - Study mode for peak performance
            recommendedPreset = .study
        default:
            recommendedPreset = .classic
        }
        
        if currentPreset != recommendedPreset && !isRunning {
            changePreset(recommendedPreset)
        }
    }
}
