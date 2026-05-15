//
//  HomeView.swift
//  MixFix
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Bird Model
struct Bird: Identifiable {
    let id: UUID
    var position: CGPoint
    let duration: Double
}

// MARK: - Animated Cloud Model
struct AnimatedCloud: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGSize
    let opacity: Double
    let duration: Double
}

// MARK: - Shooting Star Model
struct ShootingStar: Identifiable {
    let id: UUID
    var position: CGPoint
    let angle: Double
    let length: CGFloat
    let duration: Double
}

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var appSession: AppSession
    @EnvironmentObject var examState: ExamState
    @ObservedObject private var sessionManager = SessionManager.shared
    @Binding var selectedTab: Int
    @State private var showMoodSheet = false
    @State private var showAddTaskSheet = false
    @State private var showPersonalCheckList = false
    @State private var showDayDetail = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showSupportOptions = false
    @State private var showSupportResources = false
    @State private var currentMoodName: String = ""
    @State private var selectedDayDetailTab: String = "Classes"
    @State private var currentMonth = Date()
    @State private var selectedCardScale: String? = nil
    @State private var moodEmojiScale: CGFloat = 1.0
    @State private var showAffirmation = true
    @State private var poppingTaskId: UUID? = nil
    @State private var affirmationIndex: Int = 0
    @State private var birds: [Bird] = []
    @State private var clouds: [AnimatedCloud] = []
    @State private var shootingStars: [ShootingStar] = []
    @State private var screenWidth: CGFloat = 400  // Default fallback
    @AppStorage("userName") private var userName: String = "Ava"
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("moodColorsEnabled") private var moodColorsEnabled: Bool = true
    
    // Check if the latest mood is recent (within 6 hours)
    private var hasRecentMood: Bool {
        guard let latestMoodDate = store.moods.first?.date else {
            return false
        }
        let hoursSinceLastMood = Date().timeIntervalSince(latestMoodDate) / 3600
        return hoursSinceLastMood < 6
    }
    
    private var profileCircleColor: Color {
        switch profileCircleColorName {
        case "sage": return Color(hex: "#8AB86D")
        case "terracotta": return Color(hex: "#D97358")
        case "sand": return Color(hex: "#D9C28F")
        case "clay": return Color(hex: "#A0855C")
        case "moss": return Color(hex: "#7F9C4C")
        case "stone": return Color(hex: "#8F8F8F")
        case "olive": return Color(hex: "#9A9766")
        case "cream": return Color(hex: "#DCC6A5")
        case "slate": return Color(hex: "#697E8D")
        case "taupe": return Color(hex: "#AD8564")
        case "lavender": return Color(hex: "#AA95C8")
        case "periwinkle": return Color(hex: "#8E9CD0")
        case "amethyst": return Color(hex: "#9568A8")
        case "sky": return Color(hex: "#7BBCD4")
        case "ocean": return Color(hex: "#558DB8")
        case "indigo": return Color(hex: "#6270BA")
        case "rose": return Color(hex: "#E38DAC")
        case "blush": return Color(hex: "#FFA3B9")
        case "coral": return Color(hex: "#FF8371")
        case "peach": return Color(hex: "#FF9978")
        case "tangerine": return Color(hex: "#FFA83F")
        case "crimson": return Color(hex: "#D95C5C")
        case "ruby": return Color(hex: "#CB4544")
        case "mint": return Color(hex: "#98D8C8")
        case "burgundy": return Color(hex: "#B8697D")
        default: return Color(hex: "#8AB86D")
        }
    }
    
    private var headerGradient: LinearGradient {
        MFHeaderStyle.unifiedHeaderGradient(
            moodColorsEnabled: moodColorsEnabled,
            hasRecentMood: hasRecentMood,
            latestMood: store.moods.first?.mood,
            profileCircleColorName: profileCircleColorName
        )
    }
    
    private var profileCircleGradient: LinearGradient {
        switch profileCircleColorName {
        case "sage": return LinearGradient(colors: [Color(hex: "#8AB86D"), Color(hex: "#2D4A1A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "terracotta": return LinearGradient(colors: [Color(hex: "#D97358"), Color(hex: "#5A1810")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "sand": return LinearGradient(colors: [Color(hex: "#D9C28F"), Color(hex: "#6B4A2D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "clay": return LinearGradient(colors: [Color(hex: "#A0855C"), Color(hex: "#3A2010")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "moss": return LinearGradient(colors: [Color(hex: "#7F9C4C"), Color(hex: "#1F2A0A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "stone": return LinearGradient(colors: [Color(hex: "#8F8F8F"), Color(hex: "#2A2A2A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "olive": return LinearGradient(colors: [Color(hex: "#9A9766"), Color(hex: "#3A3A18")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "cream": return LinearGradient(colors: [Color(hex: "#DCC6A5"), Color(hex: "#7A5A30")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "slate": return LinearGradient(colors: [Color(hex: "#697E8D"), Color(hex: "#1A2530")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "taupe": return LinearGradient(colors: [Color(hex: "#AD8564"), Color(hex: "#4A2815")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "lavender": return LinearGradient(colors: [Color(hex: "#AA95C8"), Color(hex: "#4A3060")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "periwinkle": return LinearGradient(colors: [Color(hex: "#8E9CD0"), Color(hex: "#2A3560")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "amethyst": return LinearGradient(colors: [Color(hex: "#9568A8"), Color(hex: "#2D1040")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "sky": return LinearGradient(colors: [Color(hex: "#7BBCD4"), Color(hex: "#1A4A68")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "ocean": return LinearGradient(colors: [Color(hex: "#558DB8"), Color(hex: "#0D2A50")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "indigo": return LinearGradient(colors: [Color(hex: "#6270BA"), Color(hex: "#0D1A45")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "rose": return LinearGradient(colors: [Color(hex: "#E38DAC"), Color(hex: "#8A2545")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "blush": return LinearGradient(colors: [Color(hex: "#FFA3B9"), Color(hex: "#C83050")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "coral": return LinearGradient(colors: [Color(hex: "#FF8371"), Color(hex: "#C82018")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "peach": return LinearGradient(colors: [Color(hex: "#FF9978"), Color(hex: "#C83520")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "tangerine": return LinearGradient(colors: [Color(hex: "#FFA83F"), Color(hex: "#C84000")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "crimson": return LinearGradient(colors: [Color(hex: "#D95C5C"), Color(hex: "#6A0808")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "ruby": return LinearGradient(colors: [Color(hex: "#CB4544"), Color(hex: "#5A0404")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "mint": return LinearGradient(colors: [Color(hex: "#98D8C8"), Color(hex: "#1A5A4A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "burgundy": return LinearGradient(colors: [Color(hex: "#B8697D"), Color(hex: "#4A1520")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [Color(hex: "#8AB86D"), Color(hex: "#2D4A1A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var moodColor: Color {
        // If mood colors disabled OR no recent mood (6hr expiration), use profile color
        guard moodColorsEnabled, hasRecentMood, let latestMood = store.moods.first?.mood else {
            return profileCircleColor
        }
        switch latestMood {
        case 9: return Color(hex: "#B565D8") // Amazing - Purple
        case 8: return Color(hex: "#FFE66D") // Good - Yellow
        case 7: return Color(hex: "#7BA8D9") // Okay - Blue
        case 6: return Color(hex: "#FFA726") // Annoyed - Orange
        case 5: return Color(hex: "#8FB86D") // Anxious - Sage Green
        case 4: return Color(hex: "#A1887F") // Drained - Brown
        case 3: return Color(hex: "#7E7E9A") // Overwhelmed - Gray
        case 2: return Color(hex: "#3949AB") // Sad - Dark Blue
        case 1: return Color(hex: "#C62828") // Angry - Red
        default: return Color(.systemGray6)
        }
    }
    
    private var moodGradient: LinearGradient {
        // If mood colors disabled OR no recent mood (6hr expiration), use profile gradient
        guard moodColorsEnabled, hasRecentMood, let latestMood = store.moods.first?.mood else {
            return profileCircleGradient
        }
        switch latestMood {
        case 9: return LinearGradient(colors: [Color(hex: "#B565D8"), Color(hex: "#5E35B1")], startPoint: .topLeading, endPoint: .bottomTrailing) // Amazing - Purple
        case 8: return LinearGradient(colors: [Color(hex: "#FFE66D"), Color(hex: "#F39C12")], startPoint: .topLeading, endPoint: .bottomTrailing) // Good - Yellow
        case 7: return LinearGradient(colors: [Color(hex: "#7BA8D9"), Color(hex: "#4A7AB8")], startPoint: .topLeading, endPoint: .bottomTrailing) // Okay - Blue
        case 6: return LinearGradient(colors: [Color(hex: "#FFA726"), Color(hex: "#E53935")], startPoint: .topLeading, endPoint: .bottomTrailing) // Annoyed - Orange
        case 5: return LinearGradient(colors: [Color(hex: "#8FB86D"), Color(hex: "#4A7A2F")], startPoint: .topLeading, endPoint: .bottomTrailing) // Anxious - Sage Green
        case 4: return LinearGradient(colors: [Color(hex: "#A1887F"), Color(hex: "#3E2723")], startPoint: .topLeading, endPoint: .bottomTrailing) // Drained - Brown
        case 3: return LinearGradient(colors: [Color(hex: "#7E7E9A"), Color(hex: "#2E2E3F")], startPoint: .topLeading, endPoint: .bottomTrailing) // Overwhelmed - Gray
        case 2: return LinearGradient(colors: [Color(hex: "#3949AB"), Color(hex: "#0D1B3E")], startPoint: .topLeading, endPoint: .bottomTrailing) // Sad - Dark Blue
        case 1: return LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#4A0000")], startPoint: .topLeading, endPoint: .bottomTrailing) // Angry - Red
        default: return LinearGradient(colors: [Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var urgentTasks: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        _ = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        
        return store.events.filter { event in
            // Only include Tests and Assignments (school work)
            guard event.category == "Tests" || event.category == "Assignments" || event.category == "Exams" else {
                return false
            }
            
            // Check if incomplete
            guard !event.isCompleted else {
                return false
            }
            
            // Check if due today or tomorrow
            let eventDate = calendar.startOfDay(for: event.start)
            return eventDate == today || eventDate == tomorrow
        }
        .sorted { $0.start < $1.start }
    }
    
    private var todayClasses: Int {
        let calendar = Calendar.current
        return store.events.filter { 
            calendar.isDateInToday($0.start) && $0.category == "Classes"
        }.count
    }
    
    /// SINGLE SOURCE OF TRUTH: Planned study time from today's schedule (in minutes)
    /// Shows how much study time you NEED to do based on your schedule
    private var plannedStudyMinutesToday: Double {
        // Use same logic as AI Study Schedule
        let studyBlocks = generateTodayStudySchedule()
        var totalMinutes = Double(studyBlocks.reduce(0) { $0 + $1.duration })
        
        // Add review blocks (Ebbinghaus principle) if enabled
        if showReviewBlocks {
            let calendar = Calendar.current
            let todayClasses = store.events.filter { 
                calendar.isDateInToday($0.start) && $0.category == "Classes"
            }
            let reviewMinutes = Double(todayClasses.count * 20) // 20 min per class review
            totalMinutes += reviewMinutes
            
            print("📊 Study Card: Found \(studyBlocks.count) study blocks + \(todayClasses.count) review sessions")
        } else {
            print("📊 Study Card: Found \(studyBlocks.count) study blocks (reviews disabled)")
        }
        
        print("   Total: \(String(format: "%.1f", totalMinutes)) min")
        for (i, block) in studyBlocks.enumerated() {
            print("   Block \(i+1): \(block.title) - \(block.duration) min")
        }
        
        return totalMinutes
    }
    
    @AppStorage("showReviewBlocks") private var showReviewBlocks: Bool = true
    
    /// Convert minutes to hours for display (conversion happens once at display time)
    private var plannedStudyHoursToday: Double {
        return plannedStudyMinutesToday / 60.0
    }

    private var studiedHoursToday: Double {
        return Double(sessionManager.todayStudyMinutes) / 60.0
    }
    
    // Generate today's study schedule (mirrors AIStudyScheduleView logic)
    private func generateTodayStudySchedule() -> [StudyBlock] {
        let calendar = Calendar.current
        let today = Date()
        var blocks: [StudyBlock] = []
        
        // Get user's mood
        let todayMood = store.moods.first(where: { calendar.isDateInToday($0.date) })?.mood
        let cognitiveCapacity = calculateCognitiveCapacity(mood: todayMood)
        
        // Get incomplete school work
        let schoolWork = store.events.filter { event in
            (event.category == "Tests" || event.category == "Exams" || event.category == "Assignments") &&
            !event.isCompleted &&
            event.start >= calendar.startOfDay(for: today)
        }.sorted { $0.start < $1.start }
        
        // Prioritize by urgency
        let prioritizedWork = schoolWork.sorted { work1, work2 in
            let days1 = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: work1.start)).day ?? 999
            let days2 = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: work2.start)).day ?? 999
            return days1 < days2
        }
        
        // Calculate max study time for today
        let maxDailyMinutes = calculateMaxStudyTime(mood: todayMood, cognitiveCapacity: cognitiveCapacity)
        var totalStudyMinutesToday = 0
        
        // Create study blocks for prioritized work
        for work in prioritizedWork {
            guard totalStudyMinutesToday < maxDailyMinutes else { break }
            
            let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: calendar.startOfDay(for: work.start)).day ?? 0
            
            // Calculate optimal duration using mood-based 7-day framework
            let duration = calculateOptimalSessionDurationMoodBased(
                daysUntilDue: daysUntilDue,
                mood: todayMood
            )
            
            let adjustedDuration = min(duration, maxDailyMinutes - totalStudyMinutesToday)
            guard adjustedDuration >= 15 else { continue }
            
            blocks.append(StudyBlock(
                id: UUID(),
                title: work.title,
                subject: work.title,
                startTime: Date(),
                duration: adjustedDuration,
                dueDate: work.start,
                daysUntilDue: daysUntilDue,
                priority: daysUntilDue == 0 ? .urgent : (daysUntilDue == 1 ? .high : .medium),
                strategy: "",
                type: work.category,
                classColorHex: nil
            ))
            
            totalStudyMinutesToday += adjustedDuration
        }
        
        // Note: This function generates planned blocks (not completed time)
        // The study card now shows actual completed sessions from logs
        
        return blocks
    }
    
    @AppStorage("moodBasedScheduleEnabled") private var moodBasedScheduleEnabled: Bool = true
    @AppStorage("reminderDaysAhead") private var reminderDaysAhead: Int = 7
    
    // MARK: - Mood-Based 7-Day Duration Calculation (matches AI Study Schedule exactly)
    private func calculateOptimalSessionDurationMoodBased(daysUntilDue: Int, mood: Int?) -> Int {
        // Calculate which day in the prep cycle (1 to reminderDaysAhead)
        let rawDayInCycle = max(1, min(reminderDaysAhead, reminderDaysAhead + 1 - daysUntilDue))
        
        // Map to 7-day framework
        let dayInCycle = min(7, Int(ceil(Double(rawDayInCycle) / Double(reminderDaysAhead) * 7.0)))
        let safeIndex = min(dayInCycle - 1, 6) // Ensure index is 0-6
        
        // If mood-based schedule is disabled, use MixFix Study Flow defaults
        if !moodBasedScheduleEnabled {
            let defaultDurations = [105, 60, 82, 60, 90, 52, 25]
            return defaultDurations[safeIndex]
        }
        
        // MOOD-BASED DURATIONS (7-day arrays)
        let baseDuration: Int
        
        switch mood {
        case 9: // Amazing
            baseDuration = [90, 90, 75, 100, 80, 90, 45][safeIndex]
        case 8: // Good
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        case 7: // Okay
            baseDuration = [45, 45, 60, 45, 50, 40, 25][safeIndex]
        case 6: // Annoyed
            baseDuration = [50, 60, 45, 50, 60, 45, 30][safeIndex]
        case 5, 3: // Overwhelmed
            baseDuration = [30, 40, 35, 40, 45, 30, 20][safeIndex]
        case 4: // Drained
            baseDuration = [20, 25, 30, 20, 25, 20, 15][safeIndex]
        case 2: // Sad
            baseDuration = [25, 30, 35, 25, 30, 25, 20][safeIndex]
        case 1: // Angry
            baseDuration = [50, 60, 45, 55, 50, 45, 30][safeIndex]
        default: // No mood - use Good mood defaults
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        }
        
        return baseDuration
    }
    
    // MARK: - Mood-Based Cognitive Capacity (matches AI Study Schedule)
    private func calculateCognitiveCapacity(mood: Int?) -> Double {
        // If mood-based schedule is disabled, use "Good" mood baseline
        if !moodBasedScheduleEnabled {
            return 0.85 // Optimized baseline between Good (0.95) and Okay (0.75)
        }
        
        guard let mood = mood else { return 0.7 }
        
        switch mood {
        case 9: return 1.0  // Amazing - peak performance
        case 8: return 0.95 // Good - high capacity
        case 7: return 0.75 // Okay - moderate capacity
        case 6: return 0.6  // Annoyed - reduced capacity
        case 5: return 0.55 // Anxious - lower capacity
        case 4: return 0.5  // Drained - low energy
        case 3: return 0.45 // Overwhelmed - very low capacity
        case 2: return 0.4  // Sad - minimal capacity
        case 1: return 0.35 // Angry - lowest capacity
        default: return 0.7
        }
    }
    
    private func calculateMaxStudyTime(mood: Int?, cognitiveCapacity: Double) -> Int {
        // If mood-based schedule is disabled, use consistent 3.5 hour limit
        if !moodBasedScheduleEnabled {
            return 210 // 3.5 hours - optimized baseline
        }
        
        let baseMaxMinutes = 240 // 4 hours maximum (Cal Newport's deep work limit)
        let adjustedMax = Int(Double(baseMaxMinutes) * cognitiveCapacity)
        return max(60, min(adjustedMax, 240))
    }
    
    private var totalTasks: Int {
        store.tasks.count
    }
    
    private var completedTasksToday: Int {
        store.tasks.filter { $0.isDone }.count
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<20: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var isNightTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 20 || hour < 4
    }
    
    private var isMorningTime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 4 && hour < 12
    }
    
    // Get upcoming tests this week
    private var upcomingTests: [CalendarEvent] {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return store.events.filter { event in
            event.category == "Tests" &&
            event.start >= today &&
            event.start <= weekFromNow &&
            !event.isCompleted  // Exclude completed tests
        }.sorted { $0.start < $1.start }
    }
    
    private var nextTest: CalendarEvent? {
        upcomingTests.first
    }

    // Exam Mode helpers for the Home "Today's Study Plan" card
    private var examHomeSubtitle: String {
        let days = examState.daysUntilExam
        if days <= 0 {
            return "Exam is today or has passed"
        } else if days == 1 {
            return "1 day until your exam"
        } else {
            return "\(days) days until your exam"
        }
    }
    
    private var examHomeWeakestSections: [ExamSection] {
        let sections = examState.activeExam.sections
        let source = sections.isEmpty ? ExamSectionTemplates.templates(for: examState.activeExam.examName).map { ExamSection(name: $0.label, confidence: 0.0, knowledgeLevel: 0.0) } : sections
        return source.sorted { $0.confidence < $1.confidence }
    }
    
    private var examHomeTodayPlanItems: [StudyPlanItem] {
        let plan = examState.studyPlanDay(for: Date())
        return plan.items
    }
    
    private func startBirdAnimation() {
        // Add initial bird
        addBird()
        
        // Create birds periodically with more spacing
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { timer in
            guard isMorningTime else { 
                timer.invalidate()
                return 
            }
            // Add random delay between 12-18 seconds for natural spacing
            let delay = Double.random(in: 12...18)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard self.isMorningTime else { return }
                self.addBird()
            }
        }
    }
    
    private func addBird() {
        let startY = CGFloat.random(in: 100...300)
        let duration = Double.random(in: 8...12)
        
        let bird = Bird(
            id: UUID(),
            position: CGPoint(x: -30, y: startY),
            duration: duration
        )
        
        birds.append(bird)
        
        // Animate bird across screen (will use GeometryReader bounds)
        withAnimation(.linear(duration: duration)) {
            if let index = birds.firstIndex(where: { $0.id == bird.id }) {
                birds[index].position = CGPoint(x: 500, y: startY - 50) // Will be adjusted by GeometryReader
            }
        }
        
        // Remove bird after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1) {
            birds.removeAll { $0.id == bird.id }
        }
    }
    
    private func startCloudAnimation() {
        // Add initial cloud
        addCloud()
        
        // Create clouds periodically with more spacing
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            guard isMorningTime else { 
                timer.invalidate()
                return 
            }
            // Add random delay between 25-40 seconds for natural spacing
            let delay = Double.random(in: 25...40)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard self.isMorningTime else { return }
                self.addCloud()
            }
        }
    }
    
    private func addCloud() {
        let startY = CGFloat.random(in: 80...250)
        let width = CGFloat.random(in: 80...140)
        let height = width * CGFloat.random(in: 0.4...0.5)
        let duration = Double.random(in: 40...60) // Clouds move slower than birds
        let opacity = Double.random(in: 0.5...0.8)
        
        let cloud = AnimatedCloud(
            id: UUID(),
            position: CGPoint(x: -width, y: startY),
            size: CGSize(width: width, height: height),
            opacity: opacity,
            duration: duration
        )
        
        clouds.append(cloud)
        
        // Animate cloud across screen (will use GeometryReader bounds)
        withAnimation(.linear(duration: duration)) {
            if let index = clouds.firstIndex(where: { $0.id == cloud.id }) {
                clouds[index].position = CGPoint(x: 1000, y: startY) // Will be adjusted by GeometryReader
            }
        }
        
        // Remove cloud after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1) {
            clouds.removeAll { $0.id == cloud.id }
        }
    }
    
    private func startShootingStarAnimation() {
        // Add initial shooting star
        addShootingStar()
        
        // Create shooting stars periodically with random intervals (more frequent)
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            guard isNightTime else {
                timer.invalidate()
                return
            }
            // Random delay between 5-15 seconds for more frequent stars
            let delay = Double.random(in: 5...15)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard self.isNightTime else { return }
                self.addShootingStar()
            }
        }
    }
    
    private func addShootingStar() {
        // Spawn from wider range across entire screen width
        let startX = CGFloat.random(in: 0...screenWidth)
        // Vary height from top to upper-middle of screen
        let startY = CGFloat.random(in: 0...300)
        // More varied angles for different trajectories
        let angle = Double.random(in: -70...(-20))
        let length = CGFloat.random(in: 60...120)
        let duration = Double.random(in: 0.8...1.5)
        
        let star = ShootingStar(
            id: UUID(),
            position: CGPoint(x: startX, y: startY),
            angle: angle,
            length: length,
            duration: duration
        )
        
        shootingStars.append(star)
        
        // Calculate end position based on angle
        let radians = angle * .pi / 180
        let endX = startX + cos(radians) * 400
        let endY = startY + sin(radians) * 400
        
        // Animate shooting star
        withAnimation(.linear(duration: duration)) {
            if let index = shootingStars.firstIndex(where: { $0.id == star.id }) {
                shootingStars[index].position = CGPoint(x: endX, y: endY)
            }
        }
        
        // Remove shooting star after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            shootingStars.removeAll { $0.id == star.id }
        }
    }
    
    private var userInitial: String {
        String(userName.prefix(1).uppercased())
    }
    
    private func dueLabel(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let eventDate = calendar.startOfDay(for: event.start)
        
        // Format the time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: event.start)
        
        // Determine if this is a test/exam
        let isTest = event.category == "Tests" || event.category == "Exams"
        
        // Check if overdue (past due time and not completed)
        if event.start < now && !event.isCompleted {
            return "Overdue"
        } else if eventDate == today {
            return isTest ? "Today at \(timeString)" : "Due today at \(timeString)"
        } else if eventDate == calendar.date(byAdding: .day, value: 1, to: today) {
            return isTest ? "Tomorrow at \(timeString)" : "Due tomorrow at \(timeString)"
        } else {
            return isTest ? "Coming soon" : "Due soon"
        }
    }
    
    private var moodEmoji: String {
        guard hasRecentMood, let latestMood = store.moods.first?.mood else {
            return "" // No emoji if no recent mood (within 6 hours)
        }
        switch latestMood {
        case 1: return "😡"
        case 2: return "☹️"
        case 3: return "😵‍💫"
        case 4: return "🫠"
        case 5: return "😰"
        case 6: return "😒"
        case 7: return "😐"
        case 8: return "🙂"
        case 9: return "😄"
        default: return ""
        }
    }
    
    private var affirmationIcon: String {
        guard let latestMood = store.moods.first?.mood else {
            return "✨"
        }
        switch latestMood {
        case 1: return "🔥" // Angry - Fire for intensity
        case 2: return "🌊" // Sad - Wave for emotions
        case 3: return "🌀" // Overwhelmed - Spiral
        case 4: return "🌱" // Drained - Seedling for growth/rest
        case 5: return "🍃" // Anxious - Leaf for calm
        case 6: return "⚡" // Annoyed - Lightning
        case 7: return "🌤️" // Okay - Partly cloudy
        case 8: return "☀️" // Good - Sun
        case 9: return "✨" // Amazing - Sparkles
        default: return "✨"
        }
    }
    
    private var moodTextColor: Color {
        guard let latestMood = store.moods.first?.mood else {
            return .primary // Default to primary text color if no mood logged
        }
        // Use white text for dark backgrounds
        return (latestMood == 1 || latestMood == 2 || latestMood == 3 || latestMood == 4 || latestMood == 9) ? .white : .primary
    }
    
    private var greetingTextColor: Color {
        guard let latestMood = store.moods.first?.mood else {
            return moodColor
        }
        // Use darker yellow for "Good" mood to show against tan background
        if latestMood == 8 {
            return Color(hex: "#D4A017") // Darker golden yellow
        }
        return moodColor
    }
    
    private var primaryTextColor: Color {
        isNightTime ? Color.white : .primary
    }
    
    private var secondaryTextColor: Color {
        isNightTime ? Color.white.opacity(0.8) : .secondary
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .onAppear {
                        screenWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        screenWidth = newWidth
                    }
                // Background layer that extends to bottom
                MF.appBackground()
                    .ignoresSafeArea()
                
                // Shooting stars overlay (only at night)
                if isNightTime {
                    ForEach(shootingStars) { star in
                        ShootingStarView(star: star)
                            .position(star.position)
                    }
                    .allowsHitTesting(false)
                }
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        Color.clear
                            .frame(height: 0.1)
                            .id("homeTop")
                // Greeting Section
                HStack {
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 12) {
                        // Greeting text with premium styling
                        if isNightTime {
                            Text(greeting)
                                .font(.system(size: 32, weight: .light, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(.white)
                                .opacity(0.9)
                        } else if MF.isEveningTime {
                            VStack(spacing: -8) {
                                Text("Good")
                                    .font(.system(size: 38, weight: .light, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundStyle(Color(hex: "#3A3A3A"))
                                    .opacity(0.85)
                                
                                Text("Evening")
                                    .font(.system(size: 38, weight: .light, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundStyle(Color(hex: "#3A3A3A"))
                                    .opacity(0.85)
                            }
                        } else {
                            VStack(spacing: -8) {
                                Text("Good")
                                    .font(.system(size: 36, weight: .light, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundStyle(Color(hex: "#3A3A3A"))
                                    .opacity(0.85)
                                Text(greeting.replacingOccurrences(of: "Good ", with: ""))
                                    .font(.system(size: 36, weight: .light, design: .rounded))
                                    .tracking(2.5)
                                    .foregroundStyle(Color(hex: "#3A3A3A"))
                                    .opacity(0.85)
                            }
                        }
                        
                        // Name with premium gradient and effects
                        Text(userName)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(
                                moodColorsEnabled ? 
                                    AnyShapeStyle(moodGradient) : 
                                    AnyShapeStyle(profileCircleGradient)
                            )
                            .shadow(color: (moodColorsEnabled ? moodColor : profileCircleColor).opacity(0.15), radius: 8, x: 0, y: 4)
                            .shadow(color: (moodColorsEnabled ? moodColor : profileCircleColor).opacity(0.08), radius: 20, x: 0, y: 8)
                            .animation(.easeInOut(duration: 1.2), value: store.moods.first?.mood)
                    }
                    .scaleEffect(selectedCardScale == nil ? 1.0 : 0.98)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardScale)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                
                // Daily Affirmation Card
                Button {
                    // Cycle to next affirmation
                    showAffirmation = false
                    withAnimation(.easeOut(duration: 0.3)) {
                        affirmationIndex += 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            showAffirmation = true
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Text(affirmationIcon)
                                .font(.system(size: 16))
                            Text("Daily Affirmation")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryTextColor.opacity(0.7))
                                .textCase(.uppercase)
                                .tracking(1)
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(primaryTextColor.opacity(0.5))
                        }
                        
                        if showAffirmation {
                            Text(AffirmationService.getAffirmation(basedOnMood: store.moods.first?.mood, index: affirmationIndex))
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(primaryTextColor)
                                .lineSpacing(4)
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .onAppear {
                    // Crossfade animation on appear
                    showAffirmation = false
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showAffirmation = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color(.systemGray6))
                        .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: moodColorsEnabled ? [moodColor.opacity(0.5), moodColor.opacity(0.2)] : [Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .animation(.easeInOut(duration: 1.2), value: profileCircleColorName)
                )
                .padding(.horizontal, 20)
                
                // Stats Cards
                HStack(spacing: 16) {
                    Button {
                        selectedCardScale = "tasks"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCardScale = nil
                            showPersonalCheckList = true
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Spacer()
                                Text("\(totalTasks)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryTextColor)
                                Spacer()
                            }
                            
                            Text("Must-dos")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryTextColor)
                            
                            Text("\(completedTasksToday) checked off")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(primaryTextColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MF.isNightTime ? Color.white.opacity(0.12) : Color(.systemBackground))
                                .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(MF.isNightTime ? 0.3 : 0.2), lineWidth: 1)
                        )
                        .scaleEffect(selectedCardScale == "tasks" ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardScale)
                    }
                    
                    Button {
                        // Bounce animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            moodEmojiScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                moodEmojiScale = 1.0
                            }
                        }
                        
                        selectedCardScale = "mood"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCardScale = nil
                            showMoodSheet = true
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Text(moodEmoji)
                                .font(.system(size: 40))
                                .scaleEffect(moodEmojiScale)
                            
                            Text("Check In")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryTextColor)
                            
                            Text("Track your mood")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(primaryTextColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MF.isNightTime ? Color.white.opacity(0.12) : Color(.systemBackground))
                                .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: moodColorsEnabled ? [moodColor.opacity(MF.isNightTime ? 0.6 : 0.5), moodColor.opacity(MF.isNightTime ? 0.3 : 0.2)] : [Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .animation(.easeInOut(duration: 1.2), value: store.moods.first?.mood)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .shadow(color: moodColorsEnabled ? moodColor.opacity(0.2) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(moodColorsEnabled ? AnyShapeStyle(LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color.black), lineWidth: 3)
                        )
                        .scaleEffect(selectedCardScale == "mood" ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardScale)
                    }
                    
                    Button {
                        selectedCardScale = "classes"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedCardScale = nil
                            selectedTab = 1
                        }
                    } label: {
                        VStack(alignment: .center, spacing: 8) {
                            HStack {
                                Spacer()
                                if studiedHoursToday < 1.0 {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("\(sessionManager.todayStudyMinutes)")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundStyle(primaryTextColor)
                                        Text("min")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundStyle(primaryTextColor.opacity(0.6))
                                    }
                                    .fixedSize()
                                } else {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(String(format: "%.1f", studiedHoursToday))
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundStyle(primaryTextColor)
                                        Text(studiedHoursToday == 1.0 ? "hr" : "hrs")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundStyle(primaryTextColor.opacity(0.6))
                                    }
                                    .fixedSize()
                                }
                                Spacer()
                            }
                            
                            Text("Studied")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(primaryTextColor)
                            
                            Text("Today")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(primaryTextColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MF.isNightTime ? Color.white.opacity(0.12) : Color(.systemBackground))
                                .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(MF.isNightTime ? 0.3 : 0.2), lineWidth: 1)
                        )
                        .scaleEffect(selectedCardScale == "classes" ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCardScale)
                    }
                }
                .padding(.horizontal)
                
                // Scroll indicator for urgent tasks (only show if test notification exists, which pushes urgent tasks below fold)
                if !urgentTasks.isEmpty && appSession.mode == .student && nextTest != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("urgentTasks", anchor: .top)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.red)
                                        .symbolEffect(.bounce.down, options: .repeating.speed(0.5))
                                    Text("Urgent tasks below")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.red)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                Spacer()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Test Notification with Study Tip
                if let test = nextTest {
                    TestNotificationCard(test: test, allEvents: store.events, selectedTab: $selectedTab)
                        .padding(.horizontal)
                }
                
                // Urgent Tasks (Student Mode) or Exam Study Plan (Exam Mode)
                Group {
                    if appSession.mode == .student {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Urgent Tasks")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            
                            if urgentTasks.isEmpty {
                                Text("No urgent school work due soon")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(urgentTasks) { event in
                                    Button {
                                        selectedTab = 1 // Switch to Study tab
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Red status dot on the far left
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 14, height: 14)
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 6) {
                                                    Text("!")
                                                        .font(.headline)
                                                        .foregroundStyle(.red)
                                                    Text(event.title)
                                                        .font(.body)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.primary)
                                                }
                                                Text(dueLabel(for: event))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF8E53")],
                                                                    startPoint: .leading,
                                                                    endPoint: .trailing
                                                                )
                                                            )
                                                    )
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .id("urgentTasks")
                    } else {
                        // Exam Mode: show compact "Today's Study Plan" using exam data
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today's Study Plan")
                                        .font(.headline)
                                        .foregroundStyle(primaryTextColor)
                                    Text(examHomeSubtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(secondaryTextColor)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(examState.daysUntilExam)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(primaryTextColor)
                                    Text("days left")
                                        .font(.caption)
                                        .foregroundStyle(secondaryTextColor)
                                }
                            }
                            .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 4) {
                                let items = examHomeTodayPlanItems
                                if let first = items.first {
                                    Text("1. \(first.durationMinutes) min - \(first.description)")
                                        .font(.footnote)
                                        .foregroundStyle(primaryTextColor)
                                }
                                if items.count > 1 {
                                    let second = items[1]
                                    Text("2. \(second.durationMinutes) min - \(second.description)")
                                        .font(.footnote)
                                        .foregroundStyle(primaryTextColor)
                                }
                                if items.count > 2 {
                                    let third = items[2]
                                    Text("3. \(third.durationMinutes) min - \(third.description)")
                                        .font(.footnote)
                                        .foregroundStyle(primaryTextColor)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 120)
            }
            .onAppear {
                // Always reset scroll position to top when HomeView appears
                DispatchQueue.main.async {
                    proxy.scrollTo("homeTop", anchor: .top)
                }
            }
        }
        .gradientHeader(title: "MixFix", subtitle: "Your brain's dashboard", gradient: headerGradient)
        }  // ScrollViewReader
        }  // ZStack
        .onAppear {
            if isNightTime {
                startShootingStarAnimation()
            }
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodSheet { mood in
                handleMoodSelection(mood)
            }
        }
        .sheet(isPresented: $showSupportOptions) {
            SupportOptionsScreen(
                moodName: currentMoodName,
                onOpenResources: {
                    showSupportOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSupportResources = true
                    }
                },
                onContinueToStudy: {
                    showSupportOptions = false
                }
            )
        }
        .sheet(isPresented: $showSupportResources) {
            SupportResourcesView {
                showSupportResources = false
            }
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskSheet { title in
                store.addTask(title: title, priority: 2)
            }
        }
        .sheet(isPresented: $showPersonalCheckList) {
            PersonalCheckListView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            ProfileSettingsView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showDayDetail) {
            DayDetailView(selectedDate: Date(), currentMonth: $currentMonth, initialTab: selectedDayDetailTab, showCloseButton: true, showScheduleMode: false)
                .environmentObject(store)
        }
    }  // GeometryReader and var body
    
    // MARK: - Low Mood Response Handlers
    
    private func handleMoodSelection(_ mood: Int) {
        // Save the mood first
        store.addMood(mood)
        
        // Store mood name for display
        currentMoodName = MoodStreakManager.shared.moodName(for: mood)
        
        // Check if this is a low mood
        let streakManager = MoodStreakManager.shared
        guard streakManager.isLowMood(mood) else {
            // Not a low mood, no special handling needed
            return
        }
        
        // Check if there's a 4-day low mood streak
        let (shouldShowSupport, _) = streakManager.shouldShowChallenge(moods: store.moods, currentMood: mood)
        
        if shouldShowSupport {
            // Show support options after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSupportOptions = true
            }
        }
        // If no streak, just save the mood - no additional UI
    }
}  // HomeView

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let count: Int
    let label: String
    let sublabel: String
    var textColor: Color = .primary
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(textColor)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(textColor)
            
            Text(sublabel)
                .font(.caption2)
                .foregroundStyle(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Wavy Line Shape
struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 6
        let waveWidth: CGFloat = 40
        let numberOfWaves = Int(rect.width / waveWidth) + 1
        
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        for i in 0..<numberOfWaves {
            let startX = CGFloat(i) * waveWidth
            let endX = min(startX + waveWidth, rect.width)
            _ = startX + waveWidth / 2
            
            _ = rect.midY + (i % 2 == 0 ? 0 : waveHeight)
            let endY = rect.midY + (i % 2 == 0 ? waveHeight : 0)
            let controlY = rect.midY + (i % 2 == 0 ? waveHeight : 0)
            
            path.addCurve(
                to: CGPoint(x: endX, y: endY),
                control1: CGPoint(x: startX + waveWidth * 0.25, y: controlY),
                control2: CGPoint(x: startX + waveWidth * 0.75, y: controlY)
            )
        }
        
        return path
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: TaskItem
    @ObservedObject var store: DataStore
    @State private var showDeleteButton = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTask(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
            }
            
            Button {
                withAnimation {
                    showDeleteButton.toggle()
                }
            } label: {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if showDeleteButton {
                Button {
                    withAnimation {
                        store.deleteTask(task)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MoodSheet: View {
    var onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: Int? = nil
    
    private let moods: [(emoji: String, label: String, value: Int)] = [
        ("😄", "Amazing", 9),
        ("🙂", "Good", 8),
        ("😐", "Okay", 7),
        ("😒", "Annoyed", 6),
        ("😰", "Anxious", 5),
        ("🫠", "Drained", 4),
        ("😵‍💫", "Overwhelmed", 3),
        ("☹️", "Sad", 2),
        ("😡", "Angry", 1)
    ]
    
    private var backgroundGradient: LinearGradient {
        guard let mood = selectedMood else {
            return LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        switch mood {
        case 9: return LinearGradient(colors: [Color(hex: "#B565D8"), Color(hex: "#5E35B1")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 8: return LinearGradient(colors: [Color(hex: "#FFE66D"), Color(hex: "#F39C12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 7: return LinearGradient(colors: [Color(hex: "#B8D4F1"), Color(hex: "#5B8DBE")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 6: return LinearGradient(colors: [Color(hex: "#FFA726"), Color(hex: "#E53935")], startPoint: .topLeading, endPoint: .bottomTrailing) // Annoyed - Orange
        case 5: return LinearGradient(colors: [Color(hex: "#C5E1A5"), Color(hex: "#558B2F")], startPoint: .topLeading, endPoint: .bottomTrailing) // Anxious - Sage green
        case 4: return LinearGradient(colors: [Color(hex: "#A1887F"), Color(hex: "#3E2723")], startPoint: .topLeading, endPoint: .bottomTrailing) // Drained - Muted brown
        case 3: return LinearGradient(colors: [Color(hex: "#7E7E9A"), Color(hex: "#2E2E3F")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [Color(hex: "#3949AB"), Color(hex: "#0D1B3E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#4A0000")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var textColor: Color {
        guard let mood = selectedMood else {
            return .primary
        }
        // Use white text for dark backgrounds
        return (mood == 1 || mood == 2 || mood == 3 || mood == 4 || mood == 9) ? .white : .primary
    }
    
    private func moodColor(for mood: Int) -> Color {
        switch mood {
        case 9: return Color(hex: "#B565D8") // Amazing - Purple
        case 8: return Color(hex: "#FFE66D") // Good - Yellow
        case 7: return Color(hex: "#B8D4F1") // Okay - Blue
        case 6: return Color(hex: "#FFA726") // Annoyed - Orange
        case 5: return Color(hex: "#C5E1A5") // Anxious - Sage Green
        case 4: return Color(hex: "#A1887F") // Drained - Brown
        case 3: return Color(hex: "#7E7E9A") // Overwhelmed - Gray
        case 2: return Color(hex: "#3949AB") // Sad - Dark Blue
        case 1: return Color(hex: "#C62828") // Angry - Red
        default: return Color.blue
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("How are you feeling right now?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(textColor)
                    
                    Text("Be honest - this helps us give you better suggestions")
                        .font(.subheadline)
                        .foregroundStyle(textColor.opacity(0.7))
                }
                .padding(.top, 8)
                
                // Mood Grid - 3x3
                VStack(spacing: 16) {
                    // Row 1
                    HStack(spacing: 16) {
                        ForEach(Array(moods.prefix(3)), id: \.value) { mood in
                            MoodButton(
                                emoji: mood.emoji,
                                label: mood.label,
                                isSelected: selectedMood == mood.value,
                                borderColor: moodColor(for: mood.value)
                            ) {
                                selectedMood = mood.value
                            }
                        }
                    }
                    
                    // Row 2
                    HStack(spacing: 16) {
                        ForEach(Array(moods.dropFirst(3).prefix(3)), id: \.value) { mood in
                            MoodButton(
                                emoji: mood.emoji,
                                label: mood.label,
                                isSelected: selectedMood == mood.value,
                                borderColor: moodColor(for: mood.value)
                            ) {
                                selectedMood = mood.value
                            }
                        }
                    }
                    
                    // Row 3
                    HStack(spacing: 16) {
                        ForEach(Array(moods.dropFirst(6).prefix(3)), id: \.value) { mood in
                            MoodButton(
                                emoji: mood.emoji,
                                label: mood.label,
                                isSelected: selectedMood == mood.value,
                                borderColor: moodColor(for: mood.value)
                            ) {
                                selectedMood = mood.value
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Next Button
                Button {
                    if let mood = selectedMood {
                        onSelect(mood)
                    }
                    dismiss()
                } label: {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMood != nil ? moodColor(for: selectedMood!) : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(selectedMood == nil)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .background(backgroundGradient)
            .animation(.easeInOut(duration: 1.0), value: selectedMood)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .foregroundStyle(textColor)
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(false)
    }
}

struct MoodButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let borderColor: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 48))
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? borderColor : Color.clear, lineWidth: 3)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

struct AddTaskSheet: View {
    var onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var taskTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter task title", text: $taskTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button {
                    if !taskTitle.isEmpty {
                        onAdd(taskTitle)
                        dismiss()
                    }
                } label: {
                    Text("Add Task")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Group {
                                if taskTitle.isEmpty {
                                    Color.gray
                                } else {
                                    MF.gradient
                                }
                            }
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: MF.smallRadius))
                }
                .disabled(taskTitle.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Must Dos View
struct PersonalCheckListView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showAddTaskSheet = false
    @State private var showNotificationAlert = false
    @State private var selectedTask: TaskItem?
    @AppStorage("mustDoStreak") private var mustDoStreak: Int = 0
    @AppStorage("lastMustDoCompletionDate") private var lastCompletionDateString: String = ""
    @State private var showStreakCelebration = false
    
    private var sortedTasks: [TaskItem] {
        store.tasks.sorted { !$0.isDone && $1.isDone }
    }
    
    private var canAddMoreTasks: Bool {
        store.tasks.count < 3
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak banner
                    if mustDoStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(mustDoStreak) Day Streak!")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Keep it going!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Info card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Your 3 Must-dos")
                                .font(.headline)
                        }
                        Text("Focus on your top 3 priorities each day. Set reminders to stay on track.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if sortedTasks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "star.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(.orange)
                            Text("No non-negotiables yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Add up to 3 must-do tasks for today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(sortedTasks) { task in
                            NonNegotiableTaskRow(task: task, store: store, onSetReminder: { task in
                                selectedTask = task
                                showNotificationAlert = true
                            })
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let task = sortedTasks[index]
                                // Cancel notification if exists
                                if let identifier = task.notificationIdentifier {
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                                }
                                store.deleteTask(task)
                            }
                        }
                    }
                }
                .animation(.default, value: sortedTasks.map { $0.id })
                .padding()
            }
            .navigationTitle("3 Must-dos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { 
                        dismiss() 
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if canAddMoreTasks {
                            showAddTaskSheet = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!canAddMoreTasks)
                    .opacity(canAddMoreTasks ? 1.0 : 0.5)
                }
            }
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskSheet { title in
                if store.tasks.count < 3 {
                    store.addTask(title: title, priority: 1)
                }
            }
        }
        .alert("Set Reminder", isPresented: $showNotificationAlert) {
            Button("Morning (9 AM)") {
                if let task = selectedTask {
                    scheduleNotification(for: task, hour: 9)
                }
            }
            Button("Afternoon (2 PM)") {
                if let task = selectedTask {
                    scheduleNotification(for: task, hour: 14)
                }
            }
            Button("Evening (6 PM)") {
                if let task = selectedTask {
                    scheduleNotification(for: task, hour: 18)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("When would you like to be reminded about this task?")
        }
        .onChange(of: store.tasks) { _, newTasks in
            checkStreakCompletion(tasks: newTasks)
        }
    }
    
    private func checkStreakCompletion(tasks: [TaskItem]) {
        // Check if all 3 tasks are completed
        guard tasks.count == 3 else { return }
        let allCompleted = tasks.allSatisfy { $0.isDone }
        
        if allCompleted {
            updateStreak()
        }
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Parse last completion date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let lastDateString = lastCompletionDateString.isEmpty ? nil : lastCompletionDateString,
           let lastDate = dateFormatter.date(from: lastDateString) {
            let lastDay = calendar.startOfDay(for: lastDate)
            
            // Check if already completed today
            if calendar.isDate(today, inSameDayAs: lastDay) {
                return // Already counted today
            }
            
            // Check if yesterday (streak continues)
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               calendar.isDate(yesterday, inSameDayAs: lastDay) {
                mustDoStreak += 1
            } else {
                // Streak broken, start new
                mustDoStreak = 1
            }
        } else {
            // First time completing
            mustDoStreak = 1
        }
        
        // Save today's date
        lastCompletionDateString = dateFormatter.string(from: today)
        
        // Show celebration
        showStreakCelebration = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func scheduleNotification(for task: TaskItem, hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Must-do Reminder"
        content.body = task.title
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let identifier = "nonnegotiable-\(task.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                // Update task with notification info on main actor
                Task { @MainActor in
                    var updatedTask = task
                    updatedTask.notificationIdentifier = identifier
                    let calendar = Calendar.current
                    var notificationDate = calendar.startOfDay(for: Date())
                    notificationDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: notificationDate) ?? Date()
                    updatedTask.notificationTime = notificationDate
                    store.updateTask(updatedTask)
                }
            }
        }
    }
}

// MARK: - Must Do Task Row
struct NonNegotiableTaskRow: View {
    let task: TaskItem
    @ObservedObject var store: DataStore
    let onSetReminder: (TaskItem) -> Void
    @State private var showDeleteButton = false
    @State private var taskOffset: CGFloat = 0
    @State private var taskOpacity: Double = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !task.isDone {
                    // Slide down and fade animation when completing
                    withAnimation(.easeOut(duration: 0.4)) {
                        taskOffset = 20
                        taskOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.toggleTask(task)
                        // Cancel notification when task is completed
                        if let identifier = task.notificationIdentifier {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                        }
                        // Reset for when it reappears
                        taskOffset = 0
                        taskOpacity = 1.0
                    }
                } else {
                    store.toggleTask(task)
                }
            } label: {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let notificationTime = task.notificationTime, !task.isDone {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                        Text(notificationTime, style: .time)
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                }
            }
            
            if !task.isDone {
                Button {
                    onSetReminder(task)
                } label: {
                    Image(systemName: task.notificationTime == nil ? "bell" : "bell.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
            
            Button {
                // Cancel notification if exists
                if let identifier = task.notificationIdentifier {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                }
                withAnimation {
                    store.deleteTask(task)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .offset(y: taskOffset)
        .opacity(taskOpacity)
    }
}

// MARK: - Personal CheckList Task Row (Legacy - kept for compatibility)
struct PersonalCheckListTaskRow: View {
    let task: TaskItem
    @ObservedObject var store: DataStore
    @State private var showDeleteButton = false
    @State private var taskOffset: CGFloat = 0
    @State private var taskOpacity: Double = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !task.isDone {
                    // Slide down and fade animation when completing
                    withAnimation(.easeOut(duration: 0.4)) {
                        taskOffset = 20
                        taskOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        store.toggleTask(task)
                        // Reset for when it reappears
                        taskOffset = 0
                        taskOpacity = 1.0
                    }
                } else {
                    store.toggleTask(task)
                }
            } label: {
                Image(systemName: task.isDone ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.blue)
            }
            
            Button {
                withAnimation {
                    showDeleteButton.toggle()
                }
            } label: {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if showDeleteButton {
                Button {
                    showDeleteButton = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            store.deleteTask(task)
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .offset(y: taskOffset)
        .opacity(taskOpacity)
    }
}

// MARK: - Animated Bird View
struct AnimatedBirdView: View {
    @State private var wingFlap: CGFloat = 0
    
    var body: some View {
        AnimatedBirdShape(wingFlap: wingFlap)
            .fill(Color.black.opacity(0.8))
            .onAppear {
                // Flap wings continuously
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    wingFlap = 1
                }
            }
    }
}

// MARK: - Animated Bird Shape
struct AnimatedBirdShape: Shape {
    var wingFlap: CGFloat
    
    var animatableData: CGFloat {
        get { wingFlap }
        set { wingFlap = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Wing flap angle (0 to 1, where 0 is down, 1 is up)
        let flapAngle = wingFlap * 0.3 // Max 30% movement
        
        // Left wing
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.1, y: height * (0.2 + flapAngle)),
            control: CGPoint(x: width * 0.2, y: height * (0.3 + flapAngle * 0.5))
        )
        
        // Back to body
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.5))
        
        // Right wing
        path.addQuadCurve(
            to: CGPoint(x: width * 0.9, y: height * (0.2 + flapAngle)),
            control: CGPoint(x: width * 0.8, y: height * (0.3 + flapAngle * 0.5))
        )
        
        return path
    }
}

// MARK: - Bird Shape (Legacy - kept for reference)
struct BirdShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Simple bird silhouette (V shape with body)
        // Left wing
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.2),
            control: CGPoint(x: width * 0.2, y: height * 0.3)
        )
        
        // Back to body
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.5))
        
        // Right wing
        path.addQuadCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.2),
            control: CGPoint(x: width * 0.8, y: height * 0.3)
        )
        
        return path
    }
}

// MARK: - Badge View for Home
struct BadgeViewHome: View {
    let userBadge: UserBadge
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: userBadge.badge.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: userBadge.badge.color.opacity(0.5), radius: 6, x: 0, y: 3)
                
                Image(systemName: userBadge.badge.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
            
            Text(userBadge.badge.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(userBadge.badge.color.opacity(0.08))
        )
    }
}

// MARK: - Cloud Shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create a fluffy cloud using circles
        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.4, width: width * 0.3, height: height * 0.5))
        path.addEllipse(in: CGRect(x: width * 0.25, y: height * 0.2, width: width * 0.35, height: height * 0.6))
        path.addEllipse(in: CGRect(x: width * 0.45, y: height * 0.3, width: width * 0.4, height: height * 0.55))
        path.addEllipse(in: CGRect(x: width * 0.6, y: height * 0.4, width: width * 0.3, height: height * 0.5))
        
        return path
    }
}

// MARK: - Test Notification Card
struct TestNotificationCard: View {
    let test: CalendarEvent
    let allEvents: [CalendarEvent]
    @Binding var selectedTab: Int
    
    private var daysUntilTest: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let testDay = calendar.startOfDay(for: test.start)
        return calendar.dateComponents([.day], from: today, to: testDay).day ?? 0
    }
    
    private var assignmentsThisWeek: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return allEvents.filter { event in
            event.category == "Assignments" &&
            event.start >= today &&
            event.start <= weekFromNow &&
            !event.isCompleted
        }.count
    }
    
    private var studyTip: StudyTip {
        // Select study tip based on days until test and workload
        let urgentTips: [StudyTip] = [.testBeforeReady, .activeRecall, .practiceTesting, .selfExplanation, .feynmanTechnique]
        let shortTermTips: [StudyTip] = [.studySmartNotLong, .teachToLearn, .pomodoroMethod, .breakItDown, .errorAnalysis]
        let mediumTermTips: [StudyTip] = [.spaceItOut, .distributedPractice, .interleaving, .elaborativeInterrogation, .mindMapping]
        let longTermTips: [StudyTip] = [.connectNewToKnown, .doubleUpVisuals, .mnemonicDevices, .studyEnvironment, .mixSubjects]
        let generalTips: [StudyTip] = [.studySleepSuccess, .exerciseBoost, .hydrateYourBrain, .stopRereading, .makeItHard]
        
        if daysUntilTest <= 1 {
            // Test is tomorrow or today - urgent active recall strategies
            return urgentTips.randomElement() ?? .testBeforeReady
        } else if daysUntilTest <= 3 {
            // Test is 2-3 days away
            if assignmentsThisWeek > 3 {
                // Heavy workload - efficient study methods
                return shortTermTips.randomElement() ?? .studySmartNotLong
            } else {
                // Moderate workload - mix of active techniques and general tips
                return (urgentTips + generalTips).randomElement() ?? .teachToLearn
            }
        } else if daysUntilTest <= 5 {
            // Test is 4-5 days away - spacing and distributed practice
            return mediumTermTips.randomElement() ?? .spaceItOut
        } else {
            // Test is 6-7 days away - foundation building
            if assignmentsThisWeek > 4 {
                // Heavy workload - organization and efficiency
                return (longTermTips + shortTermTips).randomElement() ?? .mixSubjects
            } else {
                // Light workload - deep learning strategies
                return (longTermTips + generalTips).randomElement() ?? .connectNewToKnown
            }
        }
    }
    
    var body: some View {
        Button {
            selectedTab = 1 // Switch to Study tab
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text("Upcoming Test")
                        .font(.headline)
                        .foregroundStyle(MF.isNightTime ? .white : .primary)
                }
                
                // Test info
                Text("You have a test \(formattedDate == "today" || formattedDate == "tomorrow" ? "" : "on ")\(formattedDate)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MF.isNightTime ? .white : .primary)
                
                if let className = test.className, !className.isEmpty, !className.contains("NSManagedObject") {
                    Text(className)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MF.isNightTime ? .white.opacity(0.9) : .primary)
                }
                
                Divider()
                    .background(MF.isNightTime ? .white.opacity(0.3) : .gray.opacity(0.3))
                
                // Study tip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(studyTip.emoji)
                            .font(.title2)
                        Text(studyTip.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(MF.isNightTime ? .white : .primary)
                    }
                    
                    Text(studyTip.description)
                        .font(.caption)
                        .foregroundStyle(MF.isNightTime ? .white.opacity(0.8) : .secondary)
                    
                    Text(studyTip.benefit)
                        .font(.caption)
                        .foregroundStyle(MF.isNightTime ? Color.orange : Color(hex: "#D2691E"))
                        .fontWeight(.medium)
                        .italic()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let testDate = calendar.startOfDay(for: test.start)
        
        if calendar.isDate(testDate, inSameDayAs: today) {
            return "today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  calendar.isDate(testDate, inSameDayAs: tomorrow) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: test.start)
        }
    }
}

// MARK: - Study Tips
enum StudyTip: CaseIterable {
    case testBeforeReady
    case spaceItOut
    case mixSubjects
    case makeItHard
    case connectNewToKnown
    case doubleUpVisuals
    case studySleepSuccess
    case stopRereading
    case teachToLearn
    case studySmartNotLong
    case feynmanTechnique
    case pomodoroMethod
    case activeRecall
    case elaborativeInterrogation
    case selfExplanation
    case practiceTesting
    case distributedPractice
    case interleaving
    case mnemonicDevices
    case studyEnvironment
    case exerciseBoost
    case hydrateYourBrain
    case breakItDown
    case errorAnalysis
    case mindMapping
    
    var emoji: String {
        switch self {
        case .testBeforeReady: return "🧠"
        case .spaceItOut: return "⏳"
        case .mixSubjects: return "🎨"
        case .makeItHard: return "🔥"
        case .connectNewToKnown: return "🔗"
        case .doubleUpVisuals: return "🖍️"
        case .studySleepSuccess: return "💤"
        case .stopRereading: return "🚫"
        case .teachToLearn: return "🗣️"
        case .studySmartNotLong: return "⏰"
        case .feynmanTechnique: return "👨‍🏫"
        case .pomodoroMethod: return "🍅"
        case .activeRecall: return "💭"
        case .elaborativeInterrogation: return "❓"
        case .selfExplanation: return "💬"
        case .practiceTesting: return "📝"
        case .distributedPractice: return "📅"
        case .interleaving: return "🔀"
        case .mnemonicDevices: return "🎯"
        case .studyEnvironment: return "🏠"
        case .exerciseBoost: return "🏃"
        case .hydrateYourBrain: return "💧"
        case .breakItDown: return "🧩"
        case .errorAnalysis: return "🔍"
        case .mindMapping: return "🗺️"
        }
    }
    
    var title: String {
        switch self {
        case .testBeforeReady: return "Test Before You're Ready"
        case .spaceItOut: return "Space It Out"
        case .mixSubjects: return "Mix Subjects"
        case .makeItHard: return "Make It Hard on Purpose"
        case .connectNewToKnown: return "Connect New to Known"
        case .doubleUpVisuals: return "Double Up With Visuals"
        case .studySleepSuccess: return "Study → Sleep → Success"
        case .stopRereading: return "Stop Rereading on Repeat"
        case .teachToLearn: return "Teach to Learn"
        case .studySmartNotLong: return "Study Smart, Not Long"
        case .feynmanTechnique: return "The Feynman Technique"
        case .pomodoroMethod: return "Pomodoro Power"
        case .activeRecall: return "Active Recall Wins"
        case .elaborativeInterrogation: return "Ask 'Why?' and 'How?'"
        case .selfExplanation: return "Explain It to Yourself"
        case .practiceTesting: return "Practice Like It's the Real Thing"
        case .distributedPractice: return "Spread It Out Over Time"
        case .interleaving: return "Interleave Your Practice"
        case .mnemonicDevices: return "Use Memory Tricks"
        case .studyEnvironment: return "Change Your Study Spot"
        case .exerciseBoost: return "Move Before You Study"
        case .hydrateYourBrain: return "Drink Water, Think Better"
        case .breakItDown: return "Chunk It Into Pieces"
        case .errorAnalysis: return "Learn From Your Mistakes"
        case .mindMapping: return "Map Your Thoughts"
        }
    }
    
    var description: String {
        switch self {
        case .testBeforeReady: return "Don't reread — recall. Quiz yourself or explain the topic out loud."
        case .spaceItOut: return "Cramming feels fast, but fades fast. Review a topic again after a day, then after a few days."
        case .mixSubjects: return "Don't block — blend. Rotate between different subjects or problem types."
        case .makeItHard: return "Struggle = growth. Change your study order or quiz yourself blind."
        case .connectNewToKnown: return "Link ideas together. Ask, 'What does this remind me of?'"
        case .doubleUpVisuals: return "Draw what you learn. Add doodles, mind maps, or color codes after reading."
        case .studySleepSuccess: return "Sleep isn't skipping — it's storing. Review before bed, let your brain replay it overnight."
        case .stopRereading: return "Feeling familiar ≠ knowing. Read once, then close your notes and recall what stuck."
        case .teachToLearn: return "Say it like you're the teacher. Explain the concept out loud — even to your dog."
        case .studySmartNotLong: return "Short and sharp beats long and dull. Try 25 minutes on, 5 off — repeat 3x."
        case .feynmanTechnique: return "Pretend you're teaching a 10-year-old. If you can't explain it simply, you don't understand it yet."
        case .pomodoroMethod: return "Set a timer for 25 minutes. Focus hard, then take a 5-minute break. Repeat 4 times, then take a longer break."
        case .activeRecall: return "Close your notes and write down everything you remember. Then check what you missed."
        case .elaborativeInterrogation: return "Don't just memorize facts — ask why they're true. 'Why does this work?' deepens understanding."
        case .selfExplanation: return "After reading a section, pause and explain it in your own words without looking."
        case .practiceTesting: return "Take practice tests under real conditions. Simulate the pressure to train your brain for test day."
        case .distributedPractice: return "Study a little every day instead of cramming. Your brain needs time to consolidate memories."
        case .interleaving: return "Mix up different types of problems or topics in one session. It builds flexible thinking."
        case .mnemonicDevices: return "Create acronyms, rhymes, or stories to remember lists. Make it weird — weird sticks."
        case .studyEnvironment: return "Study in different places. Your brain links info to locations, so variety = more retrieval cues."
        case .exerciseBoost: return "A 10-minute walk or quick workout before studying boosts focus and memory retention."
        case .hydrateYourBrain: return "Even mild dehydration hurts focus and memory. Keep water nearby and sip regularly."
        case .breakItDown: return "Break big topics into smaller chunks. Master one piece at a time instead of drowning in everything."
        case .errorAnalysis: return "Review your mistakes deeply. Ask: Why did I get this wrong? What pattern am I missing?"
        case .mindMapping: return "Start with a central idea and branch out. Visual connections help you see the big picture."
        }
    }
    
    var benefit: String {
        switch self {
        case .testBeforeReady: return "🧩 Boosts memory strength."
        case .spaceItOut: return "🔁 Spacing builds lasting memory."
        case .mixSubjects: return "⚡ Your brain stays alert and adaptable."
        case .makeItHard: return "🎯 'Desirable difficulties' make learning stick."
        case .connectNewToKnown: return "🌱 Creates deeper understanding."
        case .doubleUpVisuals: return "🎥 Dual coding = double memory."
        case .studySleepSuccess: return "🌙 Turns short-term into long-term memory."
        case .stopRereading: return "🧠 Active recall beats passive review."
        case .teachToLearn: return "🎤 If you can teach it, you know it."
        case .studySmartNotLong: return "💪 Efficient studying = better results."
        case .feynmanTechnique: return "🎓 Simplifying = mastering."
        case .pomodoroMethod: return "⏱️ Focused bursts beat marathon sessions."
        case .activeRecall: return "🔥 Retrieval practice strengthens memory."
        case .elaborativeInterrogation: return "🧐 'Why' questions create lasting connections."
        case .selfExplanation: return "💡 Explaining reveals gaps in understanding."
        case .practiceTesting: return "🏆 Practice under pressure = confidence on test day."
        case .distributedPractice: return "📈 Spaced repetition = long-term retention."
        case .interleaving: return "🎯 Mixing builds problem-solving flexibility."
        case .mnemonicDevices: return "🧠 Memory tricks make recall instant."
        case .studyEnvironment: return "🌍 Multiple contexts = stronger memory cues."
        case .exerciseBoost: return "💪 Movement primes your brain for learning."
        case .hydrateYourBrain: return "💧 Hydration = sharper focus."
        case .breakItDown: return "🧩 Small chunks = manageable progress."
        case .errorAnalysis: return "🔍 Mistakes are your best teachers."
        case .mindMapping: return "🗺️ Visual organization = clearer thinking."
        }
    }
}

// MARK: - Shooting Star View
struct ShootingStarView: View {
    let star: ShootingStar
    
    var body: some View {
        ZStack {
            // Tail (gradient trail)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: star.length, height: 2)
                .blur(radius: 1)
            
            // Star head (bright point)
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .blur(radius: 0.5)
                .shadow(color: .white, radius: 3)
        }
        .rotationEffect(.degrees(star.angle))
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let store = DataStore(modelContext: controller.container.mainContext, seed: true)
    return HomeView(selectedTab: .constant(0))
        .environmentObject(store)
        .modelContainer(controller.container)
}
