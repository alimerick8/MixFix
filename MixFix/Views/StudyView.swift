//
//  StudyView.swift
//  MixFix
//

import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

enum TimerMode {
    case focus // 25 minutes
    case break_ // 5 minutes
}

// MARK: - Student Profile Model
struct StudentProfile: Codable {
    var gradeAverage: GradeAverage
    var workStyle: WorkStyle
    var studyEnvironment: StudyEnvironment
    var studyDuration: StudyDuration
    var motivationLevel: MotivationLevel
    
    enum GradeAverage: String, Codable, CaseIterable {
        case aPlus = "A+ (97-100%)"
        case a = "A (93-96%)"
        case aMinus = "A- (90-92%)"
        case bPlus = "B+ (87-89%)"
        case b = "B (83-86%)"
        case bMinus = "B- (80-82%)"
        case cPlus = "C+ (77-79%)"
        case c = "C (73-76%)"
        case cMinus = "C- (70-72%)"
        case dPlus = "D+ (67-69%)"
        case d = "D (63-66%)"
        case dMinus = "D- (60-62%)"
        case f = "F (Below 60%)"
        
        var numericValue: Double {
            switch self {
            case .aPlus: return 98.5
            case .a: return 94.5
            case .aMinus: return 91
            case .bPlus: return 88
            case .b: return 84.5
            case .bMinus: return 81
            case .cPlus: return 78
            case .c: return 74.5
            case .cMinus: return 71
            case .dPlus: return 68
            case .d: return 64.5
            case .dMinus: return 61
            case .f: return 50
            }
        }
    }

   
    
    enum WorkStyle: String, Codable, CaseIterable {
        case alone = "Alone"
        case smallGroup = "Small Group"
        case largeGroup = "Large Group"
        case varies = "It Varies"
    }
    
    enum StudyEnvironment: String, Codable, CaseIterable {
        case quiet = "Quiet Space"
        case backgroundNoise = "Background Noise"
        case music = "With Music"
        case cafe = "Coffee Shop/Cafe"
        case library = "Library"
        case varies = "It Varies"
    }
    
    enum StudyDuration: String, Codable, CaseIterable {
        case short = "Short Bursts (15-30 min)"
        case medium = "Medium Sessions (30-60 min)"
        case long = "Long Sessions (1-2 hours)"
        case extended = "Extended (2+ hours)"
    }
    
    enum MotivationLevel: String, Codable, CaseIterable {
        case veryHigh = "Very High"
        case high = "High"
        case moderate = "Moderate"
        case low = "Low"
        case needsBoost = "Needs a Boost"
    }
    
    static var `default`: StudentProfile {
        StudentProfile(
            gradeAverage: .b,
            workStyle: .alone,
            studyEnvironment: .quiet,
            studyDuration: .medium,
            motivationLevel: .moderate
        )
    }

}

struct PomodoroTimerStandaloneView: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.5),
                                            Color.purple.opacity(0.5),
                                            Color.blue.opacity(0.5)
                                        ]),
                                        center: .center
                                    ),
                                    lineWidth: 10
                                )
                                .frame(width: 190, height: 190)
                                .opacity(0.3)

                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 155, height: 155)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                            Text(String(format: "%02d:%02d", timerManager.seconds / 60, timerManager.seconds % 60))
                                .font(.system(size: 46, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                        }

                        Menu {
                            ForEach(PomodoroPreset.allCases) { preset in
                                Button {
                                    timerManager.changePreset(preset)
                                } label: {
                                    HStack {
                                        Image(systemName: preset.icon)
                                        VStack(alignment: .leading) {
                                            Text(preset.rawValue)
                                            Text(preset.description(customFocus: timerManager.customFocusMinutes, customBreak: timerManager.customBreakMinutes))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: timerManager.currentPreset.icon)
                                Text(timerManager.currentPreset.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                        }

                        if timerManager.currentPreset == .custom {
                            VStack(spacing: 10) {
                                VStack(spacing: 4) {
                                    Text("Custom focus length")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 12) {
                                        Button {
                                            let newValue = max(5, timerManager.customFocusMinutes - 5)
                                            timerManager.customFocusMinutes = newValue
                                            if !timerManager.isRunning && timerManager.timerMode == .focus {
                                                timerManager.seconds = PomodoroPreset.custom.focusDuration(customFocus: newValue)
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.blue)
                                        }

                                        Text("\(timerManager.customFocusMinutes) min")
                                            .font(.subheadline.weight(.medium))
                                            .frame(minWidth: 60)

                                        Button {
                                            let newValue = min(180, timerManager.customFocusMinutes + 5)
                                            timerManager.customFocusMinutes = newValue
                                            if !timerManager.isRunning && timerManager.timerMode == .focus {
                                                timerManager.seconds = PomodoroPreset.custom.focusDuration(customFocus: newValue)
                                            }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.blue)
                                        }
                                    }
                                }

                                VStack(spacing: 4) {
                                    Text("Custom break length")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    HStack(spacing: 12) {
                                        Button {
                                            let newValue = max(1, timerManager.customBreakMinutes - 1)
                                            timerManager.customBreakMinutes = newValue
                                            if !timerManager.isRunning && timerManager.timerMode == .break_ {
                                                timerManager.seconds = PomodoroPreset.custom.breakDuration(customBreak: newValue)
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.green)
                                        }

                                        Text("\(timerManager.customBreakMinutes) min")
                                            .font(.subheadline.weight(.medium))
                                            .frame(minWidth: 60)

                                        Button {
                                            let newValue = min(60, timerManager.customBreakMinutes + 1)
                                            timerManager.customBreakMinutes = newValue
                                            if !timerManager.isRunning && timerManager.timerMode == .break_ {
                                                timerManager.seconds = PomodoroPreset.custom.breakDuration(customBreak: newValue)
                                            }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.green)
                                        }
                                    }
                                }
                            }
                        }

                        HStack(spacing: 16) {
                            Button(primaryTimerLabel) {
                                handlePrimaryTimerTap()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Reset") {
                                timerManager.resetTimer()
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack(spacing: 8) {
                            Text(timerManager.timerMode == .focus ? "Focus Session" : "Break Time")
                                .font(.caption)
                                .foregroundStyle(timerManager.timerMode == .focus ? Color.primary : Color.green)
                        }
                    }
                    .frame(maxWidth: 420)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
                    )
                    .padding(.top, 12)
                    .padding(.horizontal)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                timerManager.requestNotificationPermission()
            }
        }
    }

    private var primaryTimerLabel: String {
        if timerManager.isRunning {
            return "Pause"
        } else if timerManager.inStudySession {
            return "Resume"
        } else {
            return "Start"
        }
    }

    private func handlePrimaryTimerTap() {
        if timerManager.isRunning {
            timerManager.stopTimer()
        } else {
            timerManager.inStudySession = true
            timerManager.startTimer()
        }
    }
}

struct PomodoroInlineTimerCard: View {
    @EnvironmentObject var timerManager: PomodoroTimerManager
    let onExpand: () -> Void

    private var totalSecondsForCurrentMode: Int {
        switch timerManager.timerMode {
        case .focus:
            return timerManager.currentPreset.focusDuration(customFocus: timerManager.customFocusMinutes)
        case .break_:
            return timerManager.currentPreset.breakDuration(customBreak: timerManager.customBreakMinutes)
        }
    }

    private var progress: Double {
        let total = max(1, totalSecondsForCurrentMode)
        return 1.0 - (Double(timerManager.seconds) / Double(total))
    }

    private var statusText: String {
        if timerManager.isRunning {
            return "Running"
        }
        if timerManager.inStudySession {
            return "Paused"
        }
        return "Ready"
    }

    private var primaryTimerLabel: String {
        if timerManager.isRunning {
            return "Pause"
        } else if timerManager.inStudySession {
            return "Resume"
        } else {
            return "Start"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pomodoro")
                        .font(.headline)
                        .foregroundStyle(MF.primaryTextColor)
                    HStack(spacing: 8) {
                        Text(statusText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(MF.secondaryTextColor)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(MF.secondaryTextColor)
                        Text(timerManager.timerMode == .focus ? "Focus" : "Break")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(timerManager.timerMode == .focus ? MF.primaryTextColor : Color.green)
                    }
                }

                Spacer()

                Button {
                    onExpand()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MF.secondaryTextColor)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.08), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: max(0, min(1, progress)))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.9),
                                    Color.purple.opacity(0.8),
                                    Color.blue.opacity(0.9)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text(String(format: "%02d:%02d", timerManager.seconds / 60, timerManager.seconds % 60))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MF.primaryTextColor)
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 10) {
                    Menu {
                        ForEach(PomodoroPreset.allCases) { preset in
                            Button {
                                timerManager.changePreset(preset)
                            } label: {
                                HStack {
                                    Image(systemName: preset.icon)
                                    Text(preset.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: timerManager.currentPreset.icon)
                            Text(timerManager.currentPreset.rawValue)
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(MF.primaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(.systemBackground).opacity(0.6)))
                        .overlay(
                            Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    }

                    HStack(spacing: 12) {
                        Button(primaryTimerLabel) {
                            if timerManager.isRunning {
                                timerManager.stopTimer()
                            } else {
                                timerManager.inStudySession = true
                                timerManager.startTimer()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            timerManager.resetTimer()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Badge Model
enum AchievementBadge: String, Codable, CaseIterable {
    case platinum = "Platinum Scholar"      // Highest achievement
    case gold = "Gold Star"                 // Second highest
    case silver = "Silver Achievement"      // Third highest
    case bronze = "Bronze Honor"            // Fourth highest
    case improvement = "Rising Star"        // Special improvement badge
    
    var icon: String {
        switch self {
        case .platinum: return "star.circle.fill"
        case .gold: return "star.fill"
        case .silver: return "star.leadinghalf.filled"
        case .bronze: return "star"
        case .improvement: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .platinum: return Color(hex: "#E5E4E2") // Platinum
        case .gold: return Color(hex: "#FFD700")     // Gold
        case .silver: return Color(hex: "#C0C0C0")   // Silver
        case .bronze: return Color(hex: "#CD7F32")   // Bronze
        case .improvement: return Color(hex: "#4CAF50") // Green for improvement
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .platinum: return [Color(hex: "#E5E4E2"), Color(hex: "#B8B8B8"), Color(hex: "#E5E4E2")]
        case .gold: return [Color(hex: "#FFD700"), Color(hex: "#FFA500"), Color(hex: "#FFD700")]
        case .silver: return [Color(hex: "#C0C0C0"), Color(hex: "#A8A8A8"), Color(hex: "#C0C0C0")]
        case .bronze: return [Color(hex: "#CD7F32"), Color(hex: "#B87333"), Color(hex: "#CD7F32")]
        case .improvement: return [Color(hex: "#4CAF50"), Color(hex: "#66BB6A"), Color(hex: "#4CAF50")]
        }
    }
    
    static func badge(for grade: String, numericGrade: Double?, studentProfile: StudentProfile?) -> AchievementBadge? {
        guard let numeric = numericGrade else {
            // Letter grade parsing fallback
            let gradeUpper = grade.uppercased()
            if gradeUpper == "A+" { return .platinum }
            if gradeUpper == "A" { return .gold }
            if gradeUpper == "A-" { return .silver }
            if gradeUpper == "B+" || gradeUpper == "B" { return .bronze }
            return nil
        }
        
        // If no profile, use default thresholds
        guard let profile = studentProfile else {
            if numeric >= 97 { return .platinum }
            if numeric >= 93 { return .gold }
            if numeric >= 90 { return .silver }
            if numeric >= 80 { return .bronze }
            return nil
        }
        
        // Calculate improvement from average
        let average = profile.gradeAverage.numericValue
        let improvement = numeric - average
        
        // Award badges based on improvement from personal average
        if improvement >= 15 { return .platinum }  // 15+ points above average
        if improvement >= 10 { return .gold }      // 10-14 points above average
        if improvement >= 5 { return .silver }     // 5-9 points above average
        if improvement >= 2 { return .bronze }     // 2-4 points above average
        
        // Also award if grade is exceptional regardless of average
        if numeric >= 95 && improvement >= 0 { return .gold }
        if numeric >= 90 && improvement >= 0 { return .silver }
        
        return nil
    }
    
    // Class-specific badge determination
    static func classSpecificBadge(for grade: String, numericGrade: Double?, className: String?, existingGrades: [AssignmentGrade]) -> AchievementBadge? {
        guard let numeric = numericGrade, let className = className else {
            // Fall back to general badge logic if no class specified
            return badge(for: grade, numericGrade: numericGrade, studentProfile: nil)
        }
        
        // Calculate class average from existing grades
        let classGrades = existingGrades.filter { $0.className == className && $0.numericGrade != nil }
        guard !classGrades.isEmpty else {
            // First grade in this class - award based on absolute performance
            if numeric >= 95 { return .gold }
            if numeric >= 90 { return .silver }
            if numeric >= 85 { return .bronze }
            return nil
        }
        
        let classAverage = classGrades.reduce(0.0) { $0 + ($1.numericGrade ?? 0) } / Double(classGrades.count)
        let improvement = numeric - classAverage
        
        // Award badges based on improvement from class average
        // Example: If class average is B (83) and you get an A (93), that's +10 points = Gold badge
        if improvement >= 10 { return .platinum }  // 10+ points above class average
        if improvement >= 7 { return .gold }       // 7-9 points above class average
        if improvement >= 4 { return .silver }     // 4-6 points above class average
        if improvement >= 2 { return .bronze }     // 2-3 points above class average
        
        // Also award if grade is exceptional for this class
        if numeric >= 95 && improvement >= 0 { return .gold }
        if numeric >= 90 && improvement >= 0 { return .silver }
        
        return nil
    }
}

struct UserBadge: Identifiable, Codable {
    let id: UUID
    let badge: AchievementBadge
    let earnedDate: Date
    let assignmentName: String
    let grade: String
    
    init(id: UUID = UUID(), badge: AchievementBadge, earnedDate: Date, assignmentName: String, grade: String) {
        self.id = id
        self.badge = badge
        self.earnedDate = earnedDate
        self.assignmentName = assignmentName
        self.grade = grade
    }
}

// MARK: - Grade Model
struct AssignmentGrade: Identifiable, Codable {
    let id: UUID
    let assignmentId: UUID
    let assignmentName: String
    let className: String? // The class this grade belongs to
    let grade: String // e.g., "A", "B+", "95%"
    let numericGrade: Double? // For calculations
    let dateSubmitted: Date
    let weekLeadingUpData: WeekAnalysisData?
    let badge: AchievementBadge? // Badge earned for this grade (class-specific)
    let photoData: Data? // Photo proof of grade
    var badgeShown: Bool // Track if badge animation has been shown
    
    init(id: UUID = UUID(), assignmentId: UUID, assignmentName: String, className: String? = nil, grade: String, numericGrade: Double?, dateSubmitted: Date, weekLeadingUpData: WeekAnalysisData? = nil, badge: AchievementBadge? = nil, photoData: Data? = nil, badgeShown: Bool = false) {
        self.id = id
        self.assignmentId = assignmentId
        self.assignmentName = assignmentName
        self.className = className
        self.grade = grade
        self.numericGrade = numericGrade
        self.dateSubmitted = dateSubmitted
        self.weekLeadingUpData = weekLeadingUpData
        self.badge = badge
        self.photoData = photoData
        self.badgeShown = badgeShown
    }
}

struct WeekAnalysisData: Codable {
    let averageMood: Double
    let totalStudyTime: Int // minutes
    let moodTrend: String // "improving", "declining", "stable"
    let studyConsistency: Double // 0-1
    let stressLevel: String // "low", "moderate", "high"
    let recommendations: [String]
    let strengths: [String]
    let areasForImprovement: [String]
    let completedAssignments: [CompletedAssignmentInfo]?
}

struct CompletedAssignmentInfo: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let dueDate: Date
    let completionDate: Date
    let daysBeforeDue: Int
    let completionTiming: String // "early", "on-time", "last-minute"
}

// MARK: - Brain Break Activity Enum
enum BrainBreakActivity: String, Identifiable, CaseIterable {
    case fiveSenses = "5-Senses Grounding"
    case soundEscape = "Sound Escape"
    case creativePrompt = "Creative Prompt"
    case stretch = "Stretch & Move"
    case gratitude = "Gratitude Moment"
    case focusGame = "Focus Game"
    case mentalDeclutter = "Mental Declutter"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .fiveSenses: return "hand.raised.fill"
        case .soundEscape: return "headphones"
        case .creativePrompt: return "paintbrush.fill"
        case .stretch: return "figure.walk"
        case .gratitude: return "heart.fill"
        case .focusGame: return "gamecontroller.fill"
        case .mentalDeclutter: return "puzzlepiece.fill"
        }
    }
    
    var duration: String {
        switch self {
        case .fiveSenses: return "3 min"
        case .soundEscape: return "3 min"
        case .creativePrompt: return "30 sec"
        case .stretch: return "3 min"
        case .gratitude: return "1 min"
        case .focusGame: return "60 sec"
        case .mentalDeclutter: return "2 min"
        }
    }
    
    var color: Color {
        switch self {
        case .fiveSenses: return Color(hex: "#9C27B0")
        case .soundEscape: return Color(hex: "#2196F3")
        case .creativePrompt: return Color(hex: "#FF9800")
        case .stretch: return Color(hex: "#4CAF50")
        case .gratitude: return Color(hex: "#E91E63")
        case .focusGame: return Color(hex: "#00BCD4")
        case .mentalDeclutter: return Color(hex: "#673AB7")
        }
    }
}

// MARK: - Exam Mode Support Views

struct ExamProgressView: View {
    @EnvironmentObject var examState: ExamState
    @Environment(\.dismiss) private var dismiss
    
    // Reuse the same section list logic used in StudyView
    private var sectionsForDisplay: [ExamSection] {
        let sections = examState.activeExam.sections
        if sections.isEmpty {
            let templates = ExamSectionTemplates.templates(for: examState.activeExam.examName)
            return templates.map { ExamSection(name: $0.label, confidence: 0.0, knowledgeLevel: 0.0) }
        }
        return sections
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Section Mastery") {
                    ForEach(sectionsForDisplay) { section in
                        let pct = Int(max(0, min(1, section.confidence)) * 100)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(section.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(pct)%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            GeometryReader { geo in
                                let fraction = CGFloat(pct) / 100.0
                                let clamped = min(max(fraction, 0), 1)
                                let width = clamped * geo.size.width
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.2))
                                    Capsule().fill(Color.blue.opacity(0.8)).frame(width: width)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Progress Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ExamEditorView: View {
    @EnvironmentObject var examState: ExamState
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("studentType") private var studentType: String = "highschool"
    @State private var examName: String = ""
    @State private var examDate: Date = Date()
    @State private var associatedClass: String = ""
    @State private var customExamName: String = ""
    
    private var examTypeOptions: [String] {
        var base: [String]
        if studentType == "college" {
            base = [
                "GRE (Graduate Record Examination)",
                "GMAT (Graduate Management Admission Test)",
                "LSAT (Law School Admission Test)",
                "MCAT (Medical College Admission Test)",
                "DAT (Dental Admission Test)",
                "OAT (Optometry Admission Test)",
                "PCAT (Pharmacy College Admission Test)"
            ]
        } else {
            base = [
                "PSAT",
                "SAT",
                "ACT",
                "AP Exams",
                "IB Exam",
                "SSAT",
                "ISEE",
                "SHSAT",
                "Regents (NY)",
                "A-Level / IGCSE",
                "State Exit Exams",
                "Pre-ACT 9/10",
                "MAP Tests"
            ]
        }
        // Add a generic custom option at the end
        return base + ["Other / Custom"]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exam Details") {
                    Picker("Exam Type", selection: $examName) {
                        ForEach(examTypeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    if examName == "Other / Custom" {
                        TextField("Custom exam name", text: $customExamName)
                    }
                    DatePicker("Exam date & time", selection: $examDate)
                    TextField("Class (optional)", text: $associatedClass)
                }
                
                Section("Actions") {
                    Button("Save Changes") {
                        let baseName: String
                        if examName == "Other / Custom" {
                            baseName = customExamName.isEmpty ? examState.activeExam.examName : customExamName
                        } else if !examName.isEmpty {
                            baseName = examName
                        } else {
                            baseName = examState.activeExam.examName
                        }
                        examState.updateActiveExam(
                            examName: baseName,
                            examDate: examDate,
                            associatedClass: associatedClass.isEmpty ? nil : associatedClass
                        )
                        dismiss()
                    }
                    
                    Button("Add Another Exam") {
                        let baseName: String
                        if examName == "Other / Custom" {
                            baseName = customExamName.isEmpty ? "Your Exam" : customExamName
                        } else if !examName.isEmpty {
                            baseName = examName
                        } else {
                            baseName = "Your Exam"
                        }
                        examState.addExam(
                            examName: baseName,
                            examDate: examDate,
                            associatedClass: associatedClass.isEmpty ? nil : associatedClass
                        )
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Exam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                let active = examState.activeExam
                // If the current active exam name matches a preset option, select it;
                // otherwise fall back to "Other / Custom" and fill the custom field.
                if examName.isEmpty {
                    if examTypeOptions.contains(active.examName) {
                        examName = active.examName
                    } else {
                        examName = "Other / Custom"
                        customExamName = active.examName
                    }
                }
                examDate = active.examDate
                if associatedClass.isEmpty { associatedClass = active.associatedClass ?? "" }
            }
        }
    }
}

// MARK: - Brain Break Card (Forward Declaration)
struct BrainBreakCard: View {
    let activity: BrainBreakActivity
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: activity.icon)
                .font(.system(size: 28))
                .foregroundStyle(activity.color)
                .frame(height: 40)
            
            Text(activity.rawValue)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Text(activity.duration)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activity.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(activity.color.opacity(0.3), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Brain Break Activity View (Forward Declaration)
struct BrainBreakActivityView: View {
    let activity: BrainBreakActivity
    @EnvironmentObject var store: DataStore
    
    var body: some View {
        switch activity {
        case .fiveSenses:
            FiveSensesView()
        case .stretch:
            StretchMoveView()
        case .mentalDeclutter:
            MentalDeclutterView()
        case .soundEscape:
            SoundEscapeView()
                .environmentObject(store)
        case .gratitude:
            GratitudeMomentView()
                .environmentObject(store)
        default:
            // Placeholder for other activities
            Text("Coming soon: \(activity.rawValue)")
        }
    }
}

struct StudyView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @EnvironmentObject var appSession: AppSession
    @EnvironmentObject var examState: ExamState
    @State private var selectedDate = Date()
    @State private var showAddAssignment = false
    @State private var showPomodoroTimer = false
    @State private var newAssignmentName = ""
    @State private var confettiCounter = 0
    @State private var confettiOrigin: CGPoint = .zero
    @State private var selectedBrainBreak: BrainBreakActivity?
    @State private var editingEvent: CalendarEvent?
    @State private var studySessionAssignment: CalendarEvent?
    @State private var selectedClassFilter: String = "All Classes"
    @State private var selectedTypeFilter: String = "All Types"
    @State private var showCompletedWork: Bool = false
    @State private var shootingStars: [ShootingStar] = []
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("moodColorsEnabled") private var moodColorsEnabled: Bool = true
    @State private var showExamEditor: Bool = false
    @State private var showExamProgress: Bool = false
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    private var schoolWorkEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentClassNames = Set(studentClasses.map { $0.name })
        
        return store.events.filter { event in
            // Filter by category
            let isSchoolWork = event.category == "Assignments" || event.category == "Tests" || event.category == "Exams"
            
            if !isSchoolWork {
                return false
            }
            
            // Filter by selected class
            let hasCurrentClass = event.className.map { currentClassNames.contains($0) } ?? false
            let matchesClassFilter: Bool
            if selectedClassFilter == "All Classes" {
                // When "All Classes" is selected, always include all school work
                matchesClassFilter = true
            } else if !hasCurrentClass {
                // If this assignment's class is no longer logged (or it has no class at all),
                // always include it regardless of the class filter.
                matchesClassFilter = true
            } else {
                // Only apply the class filter to events that belong to one of the current classes
                matchesClassFilter = (event.className == selectedClassFilter)
            }
            
            // Filter by selected type
            let matchesTypeFilter: Bool
            if selectedTypeFilter == "All Types" {
                matchesTypeFilter = true
            } else {
                matchesTypeFilter = event.category == selectedTypeFilter
            }
            
            if !matchesClassFilter || !matchesTypeFilter {
                return false
            }
            
            // Completion and date filtering
            if event.isCompleted {
                // Only show completed work if filter is on
                // Show all completed items regardless of due date (they were just completed)
                return showCompletedWork
            } else {
                // For incomplete work, filter out past due dates (only show today and future)
                return event.start >= today
            }
        }.sorted { $0.start < $1.start } // Closest due date first, furthest last
    }

    private var urgentAssignments: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        
        return schoolWorkEvents.filter { event in
            guard !event.isCompleted else { return false }
            return calendar.isDate(event.start, inSameDayAs: today) ||
                   calendar.isDate(event.start, inSameDayAs: tomorrow)
        }
    }
    
    private func statusColor(for status: AssignmentStatus) -> Color {
        switch status {
        case .notStarted: return .red
        case .inProgress: return .yellow
        case .completed: return .green
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd EEEE"
        return formatter.string(from: Date())
    }

    private var hasRecentMood: Bool {
        guard let latestMoodDate = store.moods.first?.date else {
            return false
        }
        let hoursSinceLastMood = Date().timeIntervalSince(latestMoodDate) / 3600
        return hoursSinceLastMood < 6
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

    private var moodGradient: LinearGradient {
        guard moodColorsEnabled, hasRecentMood, let latestMood = store.moods.first?.mood else {
            return profileCircleGradient
        }
        switch latestMood {
        case 9: return LinearGradient(colors: [Color(hex: "#B565D8"), Color(hex: "#5E35B1")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 8: return LinearGradient(colors: [Color(hex: "#FFE66D"), Color(hex: "#F39C12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 7: return LinearGradient(colors: [Color(hex: "#7BA8D9"), Color(hex: "#4A7AB8")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 6: return LinearGradient(colors: [Color(hex: "#FFA726"), Color(hex: "#E53935")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 5: return LinearGradient(colors: [Color(hex: "#8FB86D"), Color(hex: "#4A7A2F")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 4: return LinearGradient(colors: [Color(hex: "#A1887F"), Color(hex: "#3E2723")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3: return LinearGradient(colors: [Color(hex: "#7E7E9A"), Color(hex: "#2E2E3F")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [Color(hex: "#3949AB"), Color(hex: "#0D1B3E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#4A0000")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return profileCircleGradient
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
    
    private var taskManagementSuggestion: (icon: String, title: String, description: String) {
        // Count visible incomplete tasks (after all filters)
        let visibleIncompleteTasks = schoolWorkEvents.filter { !$0.isCompleted }.count
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isMorning = currentHour < 12
        let isAfternoon = currentHour >= 12 && currentHour < 17
        let currentMood = store.moods.first?.mood
        
        // No tasks - celebrate!
        if visibleIncompleteTasks == 0 {
            return ("🎉", "All Clear!", "You've completed everything! Take time to recharge or get ahead on future work.")
        }
        
        // Mood-based adjustments for task strategy
        if let mood = currentMood {
            // Overwhelmed - need to let go and simplify, BUT prioritize urgent tasks
            if mood == 3 { // Overwhelmed
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                
                // Check for urgent tasks among visible tasks (due today or tomorrow)
                let urgentTasks = schoolWorkEvents.filter { event in
                    !event.isCompleted && (calendar.isDate(event.start, inSameDayAs: today) || calendar.isDate(event.start, inSameDayAs: tomorrow))
                }
                
                // Use visible task count, not just urgent count, for suggestions
                if !urgentTasks.isEmpty {
                    // Has urgent tasks - acknowledge overwhelm but emphasize urgency
                    // Use visibleIncompleteTasks to account for ALL tasks showing, not just urgent ones
                    if visibleIncompleteTasks == 1 {
                        // Single visible task (which happens to be urgent)
                        let singleTaskMessages: [(String, String, String)] = [
                            ("🎯", "One Task, Full Focus", "You're overwhelmed, but you only have one task showing. Break it into small steps. Start with just the first step. You've got this."),
                            ("💪", "Just This One", "Feeling overwhelmed? Good news: you only have one task to focus on. Give it 25 minutes of focused work. That's all you need to do right now."),
                            ("🧘", "Breathe and Begin", "Take 3 deep breaths. You have one task. Start with the easiest part. Work for 20 minutes, then take a break."),
                            ("⏰", "Single Priority", "You're overwhelmed but there's only one task showing. Focus solely on this. Break it down, start small, and tackle it step by step."),
                            ("🌊", "One Wave at a Time", "Feeling the pressure? You have one task. That's manageable. Start anywhere. Progress beats perfection.")
                        ]
                        return singleTaskMessages[0]
                    } else if urgentTasks.count == 1 && visibleIncompleteTasks > 1 {
                        // One urgent task among multiple visible tasks
                        let mixedMessages: [(String, String, String)] = [
                            ("⏰", "Urgent First", "You're overwhelmed with \(visibleIncompleteTasks) tasks, but only one is urgent. Start with what's due soonest. The rest can wait."),
                            ("🎯", "Priority Focus", "You have \(visibleIncompleteTasks) tasks showing, but focus on the one due soon. Complete it, then breathe and reassess."),
                            ("💪", "Tackle the Urgent", "Feeling overwhelmed by \(visibleIncompleteTasks) tasks? Start with what's due today/tomorrow. Give it 25 minutes. Everything else can wait.")
                        ]
                        return mixedMessages[0]
                    } else {
                        // Multiple urgent tasks among visible tasks
                        let urgentMessages: [(String, String, String)] = [
                            ("⏰", "Urgent but Manageable", "You're overwhelmed with \(visibleIncompleteTasks) tasks. Focus ONLY on what's due today/tomorrow. Start with the smallest urgent task. Everything else can wait."),
                            ("🎯", "Narrow Your Focus", "Feeling overwhelmed with \(visibleIncompleteTasks) tasks? List only what's due today/tomorrow. Pick the easiest one. Complete it. Then breathe and pick the next."),
                            ("🌊", "Ride the Urgency", "You have \(visibleIncompleteTasks) tasks, but you don't have to panic. Choose ONE due soon. Give it 25 minutes. That's all. Then reassess."),
                            ("💪", "One at a Time", "You're overwhelmed with \(visibleIncompleteTasks) tasks, but deadlines are real. Pick your most urgent task. Break it into the smallest possible first step. Do just that step."),
                            ("🧘", "Calm Urgency", "Take 3 deep breaths. You have \(visibleIncompleteTasks) tasks—what's due soonest? Start there. Work for 20 minutes, then take a break.")
                        ]
                        return urgentMessages[0]
                    }
                } else {
                    // No urgent tasks - can truly let go
                    let overwhelmedMessages: [(String, String, String)] = [
                        ("🧘", "Release the Weight", "Nothing's urgent right now. You don't have to carry it all. Pick ONE task. Just one. The rest will still be there later, and that's okay."),
                        ("🌊", "Let It Flow", "No immediate deadlines. Trying to do everything creates more stress. Choose one thing, let the rest go for now. You can only be in one moment at a time."),
                        ("🍃", "Lighten Your Load", "Overwhelm happens when we try to hold too much. Set everything down. Pick up one task. Complete it. Then reassess."),
                        ("🌅", "One Step Forward", "You can't climb a mountain in one leap. Take one step. That's all you need to do right now. One task, one breath, one moment."),
                        ("💫", "Permission to Pause", "Nothing's due immediately. It's okay to not do everything today. Pick your top priority, give it your focus, and release the guilt about the rest."),
                        ("🕊️", "Freedom in Focus", "The paradox: doing less often accomplishes more. Choose one task and give it your full attention. Let everything else wait."),
                        ("🌸", "Gentle Progress", "You're doing your best in a difficult moment. That's enough. One small task completed is better than many tasks stressed over."),
                        ("🎯", "Simplify to Succeed", "Overwhelm thrives on complexity. Make it simple: What's ONE thing you can do right now? Start there. Nothing else matters yet.")
                    ]
                    return overwhelmedMessages[0]
                }
            }
            
            // Angry/Annoyed - need to channel energy
            if mood == 1 || mood == 6 { // Angry, Annoyed
                if visibleIncompleteTasks == 1 {
                    return ("💪", "Channel Your Energy", "One task to conquer. Use that intensity to power through quickly, then take a break to reset.")
                } else if visibleIncompleteTasks <= 3 {
                    return ("🎯", "One at a Time", "Feeling stressed? Focus on just ONE task. Complete it, breathe, then decide if you want to continue. Small wins build momentum.")
                } else {
                    return ("🧘", "Reduce the Pressure", "High stress + many tasks = overwhelm. Pick your easiest task first for a quick win. You don't have to do everything today.")
                }
            }
            
            // Low energy moods - need energy management
            if mood == 2 || mood == 4 { // Sad, Drained
                if visibleIncompleteTasks <= 2 {
                    let moodText = mood == 2 ? "sad" : "drained"
                    return ("🌱", "Gentle Progress", "You logged feeling \(moodText). Start with the task that feels least draining. Even 15 minutes of progress counts. Be kind to yourself.")
                } else {
                    let moodText = mood == 2 ? "sad" : "drained"
                    return ("💧", "Energy Conservation", "You logged feeling \(moodText). Do 1 task now, then rest. Save the rest for when you're recharged. Quality over quantity today.")
                }
            }
            
            // Anxious - need structure and reassurance
            if mood == 5 { // Anxious
                let anxiousMessages: [(String, String, String)] = [
                    ("📝", "Break It Down", "Anxiety loves ambiguity. Write down exactly what each task requires. Start with the clearest, most concrete one."),
                    ("🗂️", "Create Order", "Feeling anxious? List all tasks, then pick just 2 for today. The rest can wait. You can't do everything, and that's okay."),
                    ("🌊", "Ride the Wave", "Anxiety is temporary. Take three deep breaths. You've handled uncertain moments before, and you'll handle this one too."),
                    ("🧘", "Ground Yourself", "Name 5 things you can see, 4 you can touch, 3 you can hear. Then pick one small task. You're safe, and you're capable."),
                    ("🌱", "Start Small", "When anxiety feels big, start tiny. Just 5 minutes on one task. That's all. You can always stop, but you'll probably keep going."),
                    ("💙", "Be Gentle", "Your anxiety is trying to protect you. Thank it, then remind yourself: I am safe. I am prepared. I can take this one step at a time."),
                    ("🕊️", "Release Control", "You can't control everything, and that's okay. Focus only on what's in front of you right now. This moment is manageable."),
                    ("🌟", "You've Got This", "Anxiety lies. The truth? You've overcome 100% of your hardest days. Today will be no different. One breath, one task, one moment.")
                ]
                
                if visibleIncompleteTasks <= 2 {
                    return anxiousMessages.randomElement() ?? anxiousMessages[0]
                } else {
                    // For more tasks, prioritize structure-focused messages
                    let structureMessages = [anxiousMessages[1], anxiousMessages[4], anxiousMessages[6]]
                    return structureMessages.randomElement() ?? anxiousMessages[1]
                }
            }
            
            // Positive moods - can handle more
            if mood == 8 || mood == 9 { // Good, Amazing
                if visibleIncompleteTasks == 1 {
                    return ("⚡", "Ride the Wave", "You logged feeling great! Knock this out quickly, then consider getting ahead on future work while you have the energy.")
                } else if visibleIncompleteTasks <= 3 {
                    return ("🚀", "Peak Performance", "High energy + manageable tasks = perfect combo. Tackle the hardest one first while you're at your best.")
                } else {
                    return ("🎯", "Power Session", "You logged feeling in the zone! Use the MIT method: identify your 3 most important tasks and complete them. You've got this!")
                }
            }
        }
        
        // Default time-based strategies (no mood or neutral mood)
        if visibleIncompleteTasks == 1 {
            return ("⚡", "Quick Win", "Just one task left! Knock it out now while you have momentum. The 2-minute rule: if it takes less than 2 minutes, do it immediately.")
        } else if visibleIncompleteTasks == 2 {
            if isMorning {
                return ("🌅", "Eat the Frog", "Tackle the harder task first while your willpower is strongest. Research shows decision fatigue increases throughout the day.")
            } else {
                return ("🎯", "Power Through", "Two tasks are manageable. Use the Pomodoro technique: 25 minutes of focus, then a 5-minute break.")
            }
        } else if visibleIncompleteTasks <= 4 {
            if isMorning {
                return ("🧠", "Peak Performance Window", "Your cognitive abilities peak in the morning. Start with the most mentally demanding task, then tackle easier ones.")
            } else if isAfternoon {
                return ("📊", "Prioritize & Batch", "Group similar tasks together. Studies show task-switching reduces productivity by 40%. Do 2 now, save 2 for later.")
            } else {
                return ("🌙", "Strategic Split", "Evening energy is lower. Complete 1-2 easier tasks now, save complex work for tomorrow morning when you're fresh.")
            }
        } else {
            // 5+ tasks
            if isMorning {
                return ("🚀", "MIT Method", "Identify your 3 Most Important Tasks (MITs). Complete these first—everything else is bonus. Research shows we overestimate daily capacity by 40%.")
            } else if isAfternoon {
                return ("⏰", "Time Blocking", "You have \(visibleIncompleteTasks) tasks. Block 90-minute focus sessions with 20-minute breaks. The ultradian rhythm: our brains naturally work in 90-minute cycles.")
            } else {
                return ("🎯", "Triage Mode", "High task load detected. Use the Eisenhower Matrix: Do urgent+important now, schedule important-only, delegate or defer the rest.")
            }
        }
    }
    
    // MARK: - Helper Functions
    private func calculateOptimalDuration(daysUntilDue: Int?) -> Int {
        // Get recent mood
        let recentMood = store.moods.first?.mood
        
        // Calculate day in cycle (1-7)
        let reminderDaysAhead = 7
        let days = daysUntilDue ?? 7
        let rawDayInCycle = max(1, min(reminderDaysAhead, reminderDaysAhead + 1 - days))
        let dayInCycle = min(7, Int(ceil(Double(rawDayInCycle) / Double(reminderDaysAhead) * 7.0)))
        let safeIndex = min(dayInCycle - 1, 6) // Ensure index is 0-6
        
        // Mood-based durations matching CalendarView's calculateOptimalSessionDuration
        var baseDuration: Int
        
        switch recentMood {
        case 9: // Amazing
            baseDuration = [90, 90, 75, 100, 80, 90, 45][safeIndex]
        case 8: // Good
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        case 7: // Okay
            baseDuration = [45, 45, 60, 45, 50, 40, 25][safeIndex]
        case 6: // Annoyed
            baseDuration = [50, 60, 45, 50, 60, 45, 30][safeIndex]
        case 5: // Overwhelmed
            baseDuration = [30, 40, 35, 40, 45, 30, 20][safeIndex]
        case 4: // Drained
            baseDuration = [20, 25, 30, 20, 25, 20, 15][safeIndex]
        case 3: // Overwhelmed (same as 5)
            baseDuration = [30, 40, 35, 40, 45, 30, 20][safeIndex]
        case 2: // Sad
            baseDuration = [25, 30, 35, 25, 30, 25, 20][safeIndex]
        case 1: // Angry
            baseDuration = [50, 60, 45, 55, 50, 45, 30][safeIndex]
        default: // No mood logged - use Good mood defaults
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        }
        
        return baseDuration
    }
    
    private func createStudyBlock(from event: CalendarEvent) -> StudyBlock {
        let calendar = Calendar.current
        let now = Date()
        let daysUntilDue = event.start > now ? calendar.dateComponents([.day], from: now, to: event.start).day : 0
        
        // Determine priority based on days until due
        let priority: StudyPriority = {
            guard let days = daysUntilDue else { return .medium }
            if days <= 1 { return .urgent }
            if days <= 3 { return .high }
            if days <= 7 { return .medium }
            return .low
        }()
        
        // Create study strategy based on type
        let strategy: String = {
            switch event.category {
            case "Tests":
                return "Review notes, practice problems, and key concepts"
            case "Exams":
                return "Deep review of all materials, practice tests, and comprehensive study"
            case "Assignments":
                return "Work through assignment requirements systematically"
            default:
                return "Study session for \(event.title)"
            }
        }()
        
        // Get class color if available
        let classColorHex: String? = {
            if let className = event.className,
               let studentClass = studentClasses.first(where: { $0.name == className }) {
                return studentClass.color
            }
            return nil
        }()
        
        // Calculate optimal duration based on mood and days until due
        let optimalDuration = calculateOptimalDuration(daysUntilDue: daysUntilDue)
        
        return StudyBlock(
            id: event.id,
            title: event.title,
            subject: event.className ?? event.category,
            startTime: now,
            duration: optimalDuration, // Mood-based optimal duration
            dueDate: event.start,
            daysUntilDue: daysUntilDue,
            priority: priority,
            strategy: strategy,
            type: event.category,
            classColorHex: classColorHex
        )
    }
    
    var body: some View {
        Group {
            if appSession.mode == .exam {
                examModeBody
            } else {
                studentModeBody
            }
        }
    }

    // MARK: - Exam Helpers
    private var examDisplayName: String {
        let rawName = examState.activeExam.examName
        if rawName.isEmpty {
            return "Your Exam"
        }
        // If the name contains parentheses, keep only the part before them
        let base = rawName.split(separator: "(").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? rawName
        if base.lowercased().contains("exam") {
            return base
        } else {
            return base + " Exam"
        }
    }
    
    private var examUrgencyColor: Color {
        let days = examState.daysUntilExam
        switch days {
        case let d where d >= 30:
            return Color.green
        case 15..<30:
            return Color.yellow
        case 7..<15:
            return Color.orange
        default:
            return Color.red
        }
    }

    private var examConfidencePercent: Int {
        max(0, min(100, Int(examState.activeExam.overallConfidence * 100)))
    }
    
    private var examPriorityLabel: (icon: String, text: String, color: Color) {
        let pct = Double(examConfidencePercent) / 100.0
        if pct < 0.4 {
            return ("🔥", "Critical Weak Areas", .red)
        } else if pct < 0.7 {
            return ("⚠️", "Needs Review", .orange)
        } else {
            return ("✅", "On Track", Color.green)
        }
    }

    // Use real ExamSection data when available, fall back to static GMAT-style sample when empty.
    private var examSectionsForDisplay: [ExamSection] {
        let sections = examState.activeExam.sections
        if sections.isEmpty {
            return [
                ExamSection(name: "Quantitative", confidence: 0.62, knowledgeLevel: 0.6),
                ExamSection(name: "Verbal", confidence: 0.40, knowledgeLevel: 0.4),
                ExamSection(name: "Data Insights", confidence: 0.52, knowledgeLevel: 0.5),
                ExamSection(name: "Integrated Reasoning", confidence: 0.70, knowledgeLevel: 0.7)
            ]
        }
        return sections
    }

    private var weakestExamSections: [ExamSection] {
        examSectionsForDisplay.sorted { $0.confidence < $1.confidence }
    }

    private var aiStudyInsightText: String {
        let days = examState.daysUntilExam
        let confidence = Double(examConfidencePercent) / 100.0
        
        if confidence < 0.4 && days <= 21 {
            return "Your weakest topic (Data Sufficiency) hasn’t been reviewed in 5 days. Let’s start there today."
        } else if days <= 10 {
            return "You’re close to exam day. Two 30–45 minute focused blocks today will move the needle the most."
        } else if confidence < 0.7 {
            return "You improve fastest with 30–45 minute blocks. Want to schedule two for this evening?"
        } else {
            return "You’re ahead of schedule in Quant but slightly behind in Verbal—shift one block toward Verbal this week."
        }
    }

    // MARK: - Student Mode Body (existing behavior)
    private var studentModeBody: some View {
        ZStack {
            // Background layer that extends to bottom
            MF.appBackground()
                .ignoresSafeArea()
            
            // Shooting stars overlay (only at night)
            if MF.isNightTime {
                GeometryReader { geometry in
                    ForEach(shootingStars) { star in
                        ShootingStarView(star: star)
                            .position(star.position)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    taskManagementCard

                    PomodoroInlineTimerCard(onExpand: {
                        showPomodoroTimer = true
                    })
                    .environmentObject(timerManager)

                    if !urgentAssignments.isEmpty {
                        urgentAssignmentsSection
                    }
                    assignmentsSection
                }
                .padding(.top, 32)
                .padding([.horizontal, .bottom])
                .padding(.bottom, 100)
            }
        }
        .gradientHeader(title: "Study", subtitle: "Plan your next move", gradient: headerGradient)
        .onAppear {
            if MF.isNightTime {
                startShootingStarAnimation()
            }
        }
        .overlay(
            ConfettiView(counter: $confettiCounter, origin: confettiOrigin)
        )
        .fullScreenCover(item: $selectedBrainBreak) { activity in
            BrainBreakActivityView(activity: activity)
                .environmentObject(store)
        }
        .sheet(item: $editingEvent) { event in
            EditAssignmentSheet(event: event, store: store)
        }
        .sheet(item: $studySessionAssignment) { event in
            StudySessionView(block: createStudyBlock(from: event))
                .environmentObject(store)
                .environmentObject(timerManager)
        }
        .sheet(isPresented: $showPomodoroTimer) {
            PomodoroTimerStandaloneView()
                .environmentObject(timerManager)
        }
        .sheet(isPresented: $showAddAssignment) {
            AddAssignmentSheet(defaultDate: Date()) { name, date, className, assignmentType in
                print("📅 Creating assignment: \(name)")
                print("📅 Selected date: \(date)")
                print("📅 Class: \(className ?? "None")")
                print("📅 Type: \(assignmentType)")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/d/yy h:mm a"
                let timeString = dateFormatter.string(from: date)
                
                print("📅 Time string: \(timeString)")
                
                store.addEvent(
                    title: name,
                    start: date,
                    end: date,
                    category: assignmentType,
                    timeString: timeString,
                    className: className
                )
                newAssignmentName = ""
            }
            .environmentObject(store)
        }
    }

    // MARK: - Exam Mode Body
    private var examModeBody: some View {
        ZStack {
            MF.appBackground()
                .ignoresSafeArea()
            
            if MF.isNightTime {
                GeometryReader { geometry in
                    ForEach(shootingStars) { star in
                        ShootingStarView(star: star)
                            .position(star.position)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Exam Overview (compact, with exam switcher when multiple).
                    // Tapping this opens the exam editor sheet.
                    Button {
                        showExamEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if examState.exams.count > 1 {
                                    Menu {
                                        ForEach(examState.exams) { exam in
                                            Button(exam.examName) {
                                                examState.selectedExamId = exam.id
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(examDisplayName)
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                                .foregroundStyle(MF.primaryTextColor)
                                            Image(systemName: "chevron.down")
                                                .font(.caption2)
                                                .foregroundStyle(MF.secondaryTextColor)
                                        }
                                    }
                                } else {
                                    Text(examDisplayName)
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundStyle(MF.primaryTextColor)
                                }
                                
                                Text("Exam Overview")
                                    .font(.caption)
                                    .foregroundStyle(MF.secondaryTextColor)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(examState.daysUntilExam)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(MF.primaryTextColor)
                                Text("days left")
                                    .font(.caption)
                                    .foregroundStyle(MF.secondaryTextColor)
                            }
                        }
                        
                        // Urgency bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.25))
                                Capsule()
                                    .fill(examUrgencyColor.opacity(0.9))
                                    .frame(width: max(0, geo.size.width))
                            }
                        }
                        .frame(height: 8)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#B3E5FC"), Color(hex: "#81D4FA")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Readiness Metrics (overall confidence + priority label)
                    VStack(alignment: .leading, spacing: 12) {
                        // Overall Confidence (compact)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overall Confidence")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(MF.primaryTextColor)
                                Spacer()
                                Text("\(examConfidencePercent)%")
                                    .font(.headline)
                                    .foregroundStyle(MF.primaryTextColor)
                            }
                            
                            GeometryReader { geo in
                                let widthFraction = CGFloat(examConfidencePercent) / 100.0
                                let clampedFraction = min(max(widthFraction, 0), 1)
                                let barWidth = clampedFraction * geo.size.width
                                
                                ZStack(alignment: .leading) {
                                    // Background track should be visible even at 0%
                                    Capsule()
                                        .fill(MF.isNightTime ? Color.white.opacity(0.35) : Color.gray.opacity(0.25))
                                    Capsule()
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "#81C784"), Color(hex: "#43A047")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: barWidth)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#81C784").opacity(0.4), lineWidth: 1)
                        )
                        
                        // Priority-Level Indicator
                        HStack(spacing: 8) {
                            Text(examPriorityLabel.icon)
                            Text(examPriorityLabel.text)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(examPriorityLabel.color.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(examPriorityLabel.color.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .padding(4)

                    // Quick Actions (exam-specific)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundStyle(MF.primaryTextColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                // TODO: Start adaptive exam study session
                            } label: {
                                HStack(spacing: 8) {
                                    Text("▶️")
                                    Text("Start Adaptive Study Session")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.12)))
                            }
                            
                            Button {
                                // TODO: Show weakest topics view
                            } label: {
                                HStack(spacing: 8) {
                                    Text("⚡")
                                    Text("Review Weakest Topics")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.14)))
                            }
                            
                            Button {
                                showExamProgress = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text("📊")
                                    Text("View Progress Breakdown")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.purple.opacity(0.12)))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(MF.isNightTime ? Color.white.opacity(0.05) : Color.white.opacity(0.9))
                    )

                    // AI Study Insights (assistant-style, single card at bottom)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "#7C4DFF"))
                            Text("AI Study Insight")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MF.primaryTextColor)
                        }
                        Text(aiStudyInsightText)
                            .font(.footnote)
                            .foregroundStyle(MF.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#7C4DFF").opacity(0.35), lineWidth: 1)
                    )
                }
                .padding(.top, 32)
                .padding([.horizontal, .bottom])
                .padding(.bottom, 100)
            }
        }
        .gradientHeader(title: "Study", subtitle: "Exam Mode", gradient: headerGradient)
        .sheet(isPresented: $showExamEditor) {
            ExamEditorView()
                .environmentObject(examState)
        }
        .sheet(isPresented: $showExamProgress) {
            ExamProgressView()
                .environmentObject(examState)
        }
    }
    
    private var urgentAssignmentsSection: some View {
        let topUrgent = Array(urgentAssignments.prefix(3))
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.red)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Do These First")
                        .font(.headline)
                        .foregroundStyle(MF.primaryTextColor)
                }
                Spacer()
            }

            if topUrgent.isEmpty {
                Text("Nothing due in the next 24 hours. Use this time to get ahead or take a real break.")
                    .font(.subheadline)
                    .foregroundStyle(MF.secondaryTextColor)
            } else {
                ForEach(topUrgent, id: \.id) { event in
                    urgentAssignmentRow(event: event)
                }

                if urgentAssignments.count > topUrgent.count {
                    Text("+ more urgent items")
                        .font(.caption)
                        .foregroundStyle(MF.secondaryTextColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.12), Color.orange.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }

    
    private var taskManagementCard: some View {
        // AI Task Management Suggestion
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(taskManagementSuggestion.icon)
                            .font(.title2)
                        Text(taskManagementSuggestion.title)
                            .font(.headline)
                            .foregroundStyle(MF.primaryTextColor)
                    }
                    
                    Text(taskManagementSuggestion.description)
                        .font(.subheadline)
                        .foregroundStyle(MF.secondaryTextColor)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            MF.isNightTime ? 
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color(hex: "#E8F4F8"), Color(hex: "#D4E8F0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.05), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#90CAF9").opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
    }
    
    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Assignments")
                            .font(.headline)
                            .foregroundStyle(MF.primaryTextColor)
                        Spacer()
                        Menu {
                            Button {
                                selectedClassFilter = "All Classes"
                            } label: {
                                HStack {
                                    Text("All Classes")
                                    if selectedClassFilter == "All Classes" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Divider()
                            
                            ForEach(studentClasses, id: \.name) { studentClass in
                                Button {
                                    selectedClassFilter = studentClass.name
                                } label: {
                                    HStack {
                                        Text(studentClass.name)
                                        if selectedClassFilter == studentClass.name {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.title3)
                                Text(selectedClassFilter == "All Classes" ? "Class" : selectedClassFilter)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(MF.isNightTime ? .white : Color(hex: "#4F46E5"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MF.isNightTime ? Color.white.opacity(0.15) : Color.white.opacity(0.8))
                            )
                        }
                        
                        // Type Filter Menu
                        Menu {
                            Button {
                                selectedTypeFilter = "All Types"
                            } label: {
                                HStack {
                                    Text("All Types")
                                    if selectedTypeFilter == "All Types" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                selectedTypeFilter = "Assignments"
                            } label: {
                                HStack {
                                    Text("Assignments")
                                    if selectedTypeFilter == "Assignments" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                selectedTypeFilter = "Tests"
                            } label: {
                                HStack {
                                    Text("Tests")
                                    if selectedTypeFilter == "Tests" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                selectedTypeFilter = "Exams"
                            } label: {
                                HStack {
                                    Text("Exams")
                                    if selectedTypeFilter == "Exams" {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                Text(selectedTypeFilter == "All Types" ? "Type" : selectedTypeFilter)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(MF.isNightTime ? .white : Color(hex: "#4F46E5"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MF.isNightTime ? Color.white.opacity(0.15) : Color.white.opacity(0.8))
                            )
                        }
                        
                        // Show Completed Toggle
                        Button {
                            showCompletedWork.toggle()
                        } label: {
                            Image(systemName: showCompletedWork ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title3)
                                .foregroundStyle(showCompletedWork ? .green : .gray.opacity(0.6))
                        }
                        
                        Button {
                            showAddAssignment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(MF.gradient)
                        }
                    }
                    
                    if schoolWorkEvents.isEmpty {
                        Text("No current assignments")
                            .foregroundStyle(MF.secondaryTextColor)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(schoolWorkEvents) { event in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.body)
                                        .foregroundStyle(MF.primaryTextColor)
                                        .strikethrough(event.isCompleted)
                                        .onAppear {
                                            print("📚 Event: \(event.title), Class: \(event.className ?? "nil")")
                                        }
                                    
                                    HStack(spacing: 8) {
                                        Text(event.timeString)
                                            .font(.caption)
                                            .foregroundStyle(MF.secondaryTextColor)
                                        Text("•")
                                            .foregroundStyle(MF.secondaryTextColor)
                                        if let className = event.className, !className.isEmpty, !className.contains("NSManagedObject") {
                                            Text("\(event.category) - \(className)")
                                                .font(.caption)
                                                .foregroundStyle(.purple)
                                        } else {
                                            Text(event.category)
                                                .font(.caption)
                                                .foregroundStyle(.purple)
                                        }
                                    }
                                }
                                Spacer()
                            
                            // Checkbox for Tests/Exams, Status Menu for Assignments
                            if event.category == "Tests" || event.category == "Exams" {
                                    Button {
                                        if !event.isCompleted {
                                            // Mark as completed (don't delete so it shows in completed filter)
                                            confettiCounter += 1
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                            store.toggleEventCompletion(event)
                                        } else {
                                            // Allow unchecking
                                            store.toggleEventCompletion(event)
                                        }
                                    } label: {
                                        Image(systemName: event.isCompleted ? "checkmark.square.fill" : "square")
                                            .font(.title3)
                                            .foregroundStyle(event.isCompleted ? .green : .gray.opacity(0.6))
                                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                                            .background(
                                                GeometryReader { geo in
                                                    Color.clear
                                                        .onAppear {
                                                            let frame = geo.frame(in: .global)
                                                            confettiOrigin = CGPoint(x: frame.midX, y: frame.midY)
                                                        }
                                                }
                                            )
                                    }
                                } else {
                                    // Status Menu for Assignments
                                    Menu {
                                        Button {
                                            store.updateEventStatus(event, status: .notStarted)
                                        } label: {
                                            HStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 12, height: 12)
                                                Text("Not Started")
                                            }
                                        }
                                        Button {
                                            store.updateEventStatus(event, status: .inProgress)
                                        } label: {
                                            HStack {
                                                Circle()
                                                    .fill(Color.yellow)
                                                    .frame(width: 12, height: 12)
                                                Text("In Progress")
                                            }
                                        }
                                        Button {
                                            // Trigger confetti celebration
                                            let wasNotCompleted = event.status != .completed
                                            store.updateEventStatus(event, status: .completed)
                                            if wasNotCompleted {
                                                confettiCounter += 1
                                                // Haptic feedback
                                                let generator = UINotificationFeedbackGenerator()
                                                generator.notificationOccurred(.success)
                                            }
                                        } label: {
                                            HStack {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 12, height: 12)
                                                Text("Completed")
                                            }
                                        }
                                    } label: {
                                        Circle()
                                            .fill(statusColor(for: event.status))
                                            .frame(width: 26, height: 26)
                                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                                            .padding(4) // enlarge tap target around circle
                                            .contentShape(Rectangle())
                                            .background(
                                                GeometryReader { geo in
                                                    Color.clear
                                                        .onAppear {
                                                            let frame = geo.frame(in: .global)
                                                            confettiOrigin = CGPoint(x: frame.midX, y: frame.midY)
                                                        }
                                                }
                                            )
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: MF.cornerRadius)
                                    .fill(MF.isNightTime ? Color(hex: "#1A2847").opacity(0.6) : Color(.systemGray6))
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                studySessionAssignment = event
                            }
                            .contextMenu {
                                Button {
                                    editingEvent = event
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    store.deleteEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.top)
    }
    
    private var brainBreakSection: some View {
        // Brain Break Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Brain Break")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(MF.primaryTextColor)
                    
                    Text(brainBreakSuggestion)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(MF.secondaryTextColor)
                    
                    // Brain break activity cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(brainBreakActivities) { activity in
                                BrainBreakCard(activity: activity) {
                                    selectedBrainBreak = activity
                                }
                            }
                        }
                    }
                }
                .padding(.top)
    }

    private var progress: CGFloat {
        let total = 25 * 60
        return CGFloat(1 - Double(timerManager.seconds) / Double(total))
    }

    private var timeString: String {
        let minutes = timerManager.seconds / 60
        let secs = timerManager.seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private var brainBreakSuggestion: String {
        let currentMood = store.moods.first?.mood
        let visibleIncompleteTasks = schoolWorkEvents.filter { !$0.isCompleted }.count
        
        if let mood = currentMood {
            if mood <= 3 { // Angry, Sad, Overwhelmed
                return "Feeling stressed? Take a moment to reset your mind."
            } else if mood <= 5 { // Drained, Anxious
                return "Low energy detected. A quick break can help recharge."
            } else if mood == 7 { // Okay
                return "A short mental reset can boost your focus."
            } else { // Good, Amazing
                if visibleIncompleteTasks > 3 {
                    return "You're doing great! A quick break will keep you sharp."
                } else {
                    return "Keep the momentum going with a refreshing break."
                }
            }
        }
        
        return "Take a moment to reset and recharge your mind."
    }
    
    private var brainBreakActivities: [BrainBreakActivity] {
        let currentMood = store.moods.first?.mood
        var activities: [BrainBreakActivity] = []
        
        // Always include these
        activities.append(.fiveSenses)
        activities.append(.stretch)
        
        // Mood-based additions
        if let mood = currentMood {
            if mood <= 3 { // Stressed moods
                activities.append(.soundEscape)
                activities.append(.mentalDeclutter)
                activities.append(.gratitude)
            } else if mood <= 5 { // Low energy
                activities.append(.gratitude)
                activities.append(.soundEscape)
                activities.append(.creativePrompt)
            } else if mood >= 8 { // High energy
                activities.append(.creativePrompt)
                activities.append(.focusGame)
                activities.append(.gratitude)
            } else { // Neutral
                activities.append(.soundEscape)
                activities.append(.creativePrompt)
                activities.append(.gratitude)
            }
        } else {
            // No mood - show variety
            activities.append(.soundEscape)
            activities.append(.creativePrompt)
            activities.append(.gratitude)
        }
        
        return Array(activities.prefix(5)) // Show max 5
    }
    
    // MARK: - Shooting Star Animation Functions
    private func startShootingStarAnimation() {
        addShootingStar()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            guard MF.isNightTime else {
                timer.invalidate()
                return
            }
            let delay = Double.random(in: 5...15)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard MF.isNightTime else { return }
                self.addShootingStar()
            }
        }
    }
    
    private func addShootingStar() {
        let startX = CGFloat.random(in: 100...300)
        let startY = CGFloat.random(in: 50...200)
        let angle = Double.random(in: -60...(-30))
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
        
        let radians = angle * .pi / 180
        let endX = startX + cos(radians) * 400
        let endY = startY + sin(radians) * 400
        
        withAnimation(.linear(duration: duration)) {
            if let index = shootingStars.firstIndex(where: { $0.id == star.id }) {
                shootingStars[index].position = CGPoint(x: endX, y: endY)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            shootingStars.removeAll { $0.id == star.id }
        }
    }
    // MARK: - Urgent Assignment Helpers

    private func urgentAssignmentRow(event: CalendarEvent) -> some View {
        Button {
            editingEvent = event
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MF.primaryTextColor)
                    
                    Text(urgentDueString(for: event))
                        .font(.caption)
                        .foregroundStyle(MF.secondaryTextColor)
                }
                
                Spacer()
                
                Text(urgentBadge(for: event))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(urgentBadgeColor(for: event).opacity(0.15))
                    .foregroundStyle(urgentBadgeColor(for: event))
                    .clipShape(Capsule())
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MF.isNightTime ? Color.white.opacity(0.05) : Color.white)
            )
        }
        .buttonStyle(.plain)
    }

    private func urgentBadge(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(event.start, inSameDayAs: today) {
            return "DUE TODAY"
        }
        return "DUE TOMORROW"
    }

    private func urgentBadgeColor(for event: CalendarEvent) -> Color {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(event.start, inSameDayAs: today) {
            return .red
        }
        return .orange
    }

    private func urgentDueString(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(event.start, inSameDayAs: today) {
            return "Today · \(formatter.string(from: event.start))"
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        if calendar.isDate(event.start, inSameDayAs: tomorrow) {
            return "Tomorrow · \(formatter.string(from: event.start))"
        }
        return formatter.string(from: event.start)
    }
}


struct AddAssignmentSheet: View {
    var defaultDate: Date
    var onAdd: (String, Date, String?, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var assignmentName = ""
    @State private var dueDate: Date
    @State private var selectedClass: String = "None"
    @State private var assignmentType: String = "Assignments" // "Assignments" or "Tests"
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("classSchedulesData") private var classSchedulesData: Data = Data()
    @State private var classSchedules: [UUID: ClassScheduleInfo] = [:]
    @FocusState private var isTextFieldFocused: Bool
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    init(defaultDate: Date, onAdd: @escaping (String, Date, String?, String) -> Void) {
        self.defaultDate = defaultDate
        self.onAdd = onAdd
        _dueDate = State(initialValue: defaultDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Enter assignment name", text: $assignmentName)
                
                    Picker("Type", selection: $assignmentType) {
                        Text("Assignment").tag("Assignments")
                        Text("Test").tag("Tests")
                        Text("Exam").tag("Exams")
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                    
                    FiveMinuteTimePicker(date: $dueDate, label: "Due Time")
                    
                    Picker("Class", selection: $selectedClass) {
                        Text("None").tag("None")
                        ForEach(studentClasses) { classItem in
                            Text(classItem.name).tag(classItem.name)
                        }
                    }
                    .onChange(of: selectedClass) { _, newClass in
                        updateTimeForClass(newClass)
                    }
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadClassSchedules()
            }
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isTextFieldFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let className = (selectedClass != "None") ? selectedClass : nil
                        onAdd(assignmentName, dueDate, className, assignmentType)
                        dismiss()
                    }
                    .disabled(assignmentName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var titlePlaceholder: String {
        switch assignmentType {
        case "Tests": return "Test name"
        case "Exams": return "Exam name"
        default: return "Assignment name"
        }
    }
    
    private func loadClassSchedules() {
        if let decoded = try? JSONDecoder().decode([UUID: ClassScheduleInfo].self, from: classSchedulesData) {
            classSchedules = decoded
        }
    }
    
    private func updateTimeForClass(_ className: String) {
        guard className != "None",
              let selectedClassItem = studentClasses.first(where: { $0.name == className }),
              let schedule = classSchedules[selectedClassItem.id] else {
            return
        }

        // Always set the Due Time to this class's start time, no matter what day the
        // assignment is due. This guarantees consistent behavior for every class.
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        if let newDate = calendar.date(from: dateComponents) {
            dueDate = newDate
        }
    }
}

// MARK: - Flip Clock Timer
struct FlipClockTimer: View {
    let timeString: String
    
    private var digits: [String] {
        let components = timeString.split(separator: ":")
        guard components.count == 2 else { return ["0", "0", "0", "0"] }
        let minutes = String(components[0])
        let seconds = String(components[1])
        return [
            String(minutes.prefix(1)),
            String(minutes.suffix(1)),
            String(seconds.prefix(1)),
            String(seconds.suffix(1))
        ]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Minutes
            FlipDigit(digit: digits[0])
            FlipDigit(digit: digits[1])
            
            // Colon
            VStack(spacing: 6) {
                Circle()
                    .fill(MF.primaryTextColor)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(MF.primaryTextColor)
                    .frame(width: 6, height: 6)
            }
            .padding(.horizontal, 4)
            
            // Seconds
            FlipDigit(digit: digits[2])
            FlipDigit(digit: digits[3])
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MF.isNightTime ? Color(hex: "#1A2847").opacity(0.6) : Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct FlipDigit: View {
    let digit: String
    
    var body: some View {
        Text(digit)
            .font(.system(size: 48, weight: .semibold, design: .rounded))
            .foregroundStyle(MF.primaryTextColor)
            .frame(width: 60, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MF.isNightTime ? Color.white.opacity(0.1) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - Wave Shape for Decorative Mountains
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        // First wave/mountain
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.3),
            control1: CGPoint(x: width * 0.1, y: height * 0.8),
            control2: CGPoint(x: width * 0.2, y: height * 0.4)
        )
        
        // Second wave/mountain
        path.addCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.5),
            control1: CGPoint(x: width * 0.4, y: height * 0.2),
            control2: CGPoint(x: width * 0.5, y: height * 0.4)
        )
        
        // Third wave/mountain
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.4),
            control1: CGPoint(x: width * 0.7, y: height * 0.6),
            control2: CGPoint(x: width * 0.85, y: height * 0.3)
        )
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Circle Position Preference Key
struct CirclePositionKey: PreferenceKey {
    static var defaultValue: CGPoint = CGPoint(x: 200, y: 400)
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var counter: Int
    let origin: CGPoint
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Group {
                    if piece.shape == .circle {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [piece.color, piece.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: piece.size, height: piece.size)
                    } else if piece.shape == .star {
                        StarShape()
                            .fill(
                                LinearGradient(
                                    colors: [piece.color, piece.color.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: piece.size, height: piece.size)
                    } else {
                        ConfettiShape()
                            .fill(
                                LinearGradient(
                                    colors: [piece.color, piece.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: piece.size * 1.5, height: piece.size * 0.6)
                    }
                }
                .rotationEffect(piece.rotation)
                .rotation3DEffect(
                    piece.rotation3D,
                    axis: (x: 1, y: 1, z: 0)
                )
                .position(piece.position)
                .opacity(piece.opacity)
                .shadow(color: piece.color.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: counter) { oldValue, newValue in
            if newValue > oldValue {
                createConfetti()
            }
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [
            Color(hex: "#FF6B6B"), // Coral red
            Color(hex: "#FFD93D"), // Golden yellow
            Color(hex: "#6BCF7F"), // Mint green
            Color(hex: "#4D96FF"), // Sky blue
            Color(hex: "#C77DFF"), // Purple
            Color(hex: "#FF8FAB"), // Pink
            Color(hex: "#FFB84D")  // Orange
        ]
        
        let shapes: [ConfettiShapeType] = [.rectangle, .circle, .star]
        
        // Create 80 confetti pieces for more abundance
        for _ in 0..<80 {
            let piece = ConfettiPiece(
                id: UUID(),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 10...18),
                position: origin,
                rotation: Angle(degrees: Double.random(in: 0...360)),
                rotation3D: Angle(degrees: 0),
                opacity: 1.0,
                shape: shapes.randomElement() ?? .rectangle
            )
            confettiPieces.append(piece)
        }
        
        // Animate confetti with spring physics
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            for i in confettiPieces.indices {
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 120...300)
                confettiPieces[i].position = CGPoint(
                    x: confettiPieces[i].position.x + cos(angle) * distance,
                    y: confettiPieces[i].position.y + sin(angle) * distance
                )
                confettiPieces[i].rotation = Angle(degrees: Double.random(in: 360...1080))
                confettiPieces[i].rotation3D = Angle(degrees: Double.random(in: 0...720))
            }
        }
        
        // Fade out with delay
        withAnimation(.easeIn(duration: 0.5).delay(0.7)) {
            for i in confettiPieces.indices {
                confettiPieces[i].opacity = 0
            }
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            confettiPieces.removeAll()
        }
    }
}

enum ConfettiShapeType {
    case rectangle, circle, star
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Angle
    var rotation3D: Angle
    var opacity: Double
    let shape: ConfettiShapeType
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Create a rectangle with slight rounding for confetti look
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 2, height: 2))
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        
        for i in 0..<5 {
            let angle = (Double(i) * 72 - 90) * .pi / 180
            let point = CGPoint(
                x: center.x + CGFloat(Darwin.cos(angle)) * radius,
                y: center.y + CGFloat(Darwin.sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            
            let innerAngle = (Double(i) * 72 - 90 + 36) * .pi / 180
            let innerPoint = CGPoint(
                x: center.x + CGFloat(Darwin.cos(innerAngle)) * innerRadius,
                y: center.y + CGFloat(Darwin.sin(innerAngle)) * innerRadius
            )
            path.addLine(to: innerPoint)
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Breathing Exercise View
struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var breathingPhase: BreathingPhase = .exhale  // Start contracted so first inhale expands
    @State private var secondsRemaining = 60
    @State private var cycleTimer: Timer?
    @State private var airParticles: [AirParticle] = []
    @State private var hasStarted = false
    @State private var showCountdown = false
    @State private var countdownNumber = 3
    @State private var showCompletionMessage = false
    
    var animationScale: CGFloat {
        switch breathingPhase {
        case .inhale:
            return 1.2  // Expand
        case .hold:
            return 1.2  // Stay expanded
        case .exhale:
            return 0.8  // Contract
        case .holdAfter:
            return 0.8  // Stay contracted
        }
    }
    
    enum BreathingPhase {
        case inhale      // 4 seconds
        case hold        // 4 seconds
        case exhale      // 4 seconds
        case holdAfter   // 4 seconds - hold after exhale
    }
    
    var body: some View {
        ZStack {
            // Animated background gradient based on breathing phase
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4), value: breathingPhase)
            
            if showCompletionMessage {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Nice work")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(completionMessage)
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                )
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
            } else if showCountdown {
                // Countdown screen
                VStack {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            cycleTimer?.invalidate()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    Text("\(countdownNumber)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(countdownNumber == 0 ? 1.5 : 1.0)
                        .opacity(countdownNumber == 0 ? 0 : 1)
                    
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            } else if !hasStarted {
                // Start screen
                VStack(spacing: 40) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Lung icon preview - anatomically accurate
                        ZStack {
                            // Lung icon with realistic color
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 120))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.6, blue: 0.65),
                                            Color(red: 0.90, green: 0.52, blue: 0.57),
                                            Color(red: 0.85, green: 0.45, blue: 0.5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.2), radius: 15, x: 0, y: 5)
                            
                            // Add bronchi detail overlay
                            Image(systemName: "lungs")
                                .font(.system(size: 120))
                                .foregroundStyle(
                                    Color(red: 0.75, green: 0.35, blue: 0.4).opacity(0.4)
                                )
                                .offset(x: 1, y: 1)
                        }
                        
                        Text("Breathing Exercise")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("60 seconds • 4-4-4-4 pattern")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text("Get comfortable and prepare to breathe")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Start button
                    Button {
                        startCountdown()
                    } label: {
                        Text("Start")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            } else {
                // Exercise screen
                VStack(spacing: 40) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            cycleTimer?.invalidate()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Timer
                    Text("\(secondsRemaining)s")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    // Animated lung visualization with air particles
                    ZStack {
                        // Premium air particles flowing in and out
                        ForEach(airParticles) { particle in
                            ZStack {
                                // Outer glow
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.cyan.opacity(particle.opacity * 0.4),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: particle.size
                                        )
                                    )
                                    .frame(width: particle.size * 2, height: particle.size * 2)
                                
                                // Core particle with gradient
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.white.opacity(particle.opacity * 0.8),
                                                Color.cyan.opacity(particle.opacity * 0.6),
                                                Color.blue.opacity(particle.opacity)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: particle.size / 2
                                        )
                                    )
                                    .frame(width: particle.size, height: particle.size)
                                    .shadow(color: Color.cyan.opacity(particle.opacity * 0.5), radius: 4, x: 0, y: 0)
                            }
                            .position(particle.position)
                        }
                        
                        // Anatomically accurate lung visualization
                        ZStack {
                            // Lung icon with realistic blended color
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 140))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.95, green: 0.6, blue: 0.65),   // Light pink (oxygenated)
                                            Color(red: 0.90, green: 0.52, blue: 0.57),  // Mid blend
                                            Color(red: 0.85, green: 0.45, blue: 0.5),   // Deeper pink/red
                                            Color(red: 0.78, green: 0.38, blue: 0.43)   // Darkest at bottom
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.25), radius: 20, x: 0, y: 8)
                            
                            // Add bronchi detail overlay with gradient
                            Image(systemName: "lungs")
                                .font(.system(size: 140))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.75, green: 0.35, blue: 0.4).opacity(0.5),
                                            Color(red: 0.65, green: 0.25, blue: 0.3).opacity(0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(x: 1, y: 1)
                            
                            // Subtle vein/vessel texture
                            Image(systemName: "lungs")
                                .font(.system(size: 140))
                                .foregroundStyle(
                                    Color(red: 0.65, green: 0.25, blue: 0.3).opacity(0.12)
                                )
                                .blur(radius: 3)
                        }
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 4), value: animationScale)
                    }
                    .frame(height: 400)
                    
                    // Instruction text
                    VStack(spacing: 8) {
                        Text(phaseText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(phaseColor)
                        
                        Text(phaseInstruction)
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .onDisappear {
            cycleTimer?.invalidate()
        }
    }

    private var completionMessage: String {
        let messages = [
            "You just gave your brain a real reset. Carry this calm into your next task.",
            "Your nervous system noticed that. Even one minute of steady breathing makes a difference.",
            "Well done. Notice how your body feels now compared to a minute ago.",
            "You showed up for yourself. That's what progress looks like.",
            "Breathing like this trains your brain to find calm faster next time."
        ]
        return messages.randomElement() ?? messages[0]
    }
    
    var phaseText: String {
        switch breathingPhase {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        case .holdAfter: return "Hold"
        }
    }
    
    var phaseInstruction: String {
        switch breathingPhase {
        case .inhale: return "4 seconds"
        case .hold: return "4 seconds"
        case .exhale: return "4 seconds"
        case .holdAfter: return "4 seconds"
        }
    }
    
    var phaseColor: Color {
        switch breathingPhase {
        case .inhale: return Color.blue
        case .hold: return Color.purple
        case .exhale: return Color.green
        case .holdAfter: return Color.orange
        }
    }
    
    var gradientColors: [Color] {
        switch breathingPhase {
        case .inhale:
            return [Color(hex: "#E3F2FD"), Color(hex: "#BBDEFB"), Color(hex: "#90CAF9")]
        case .hold:
            return [Color(hex: "#F3E5F5"), Color(hex: "#E1BEE7"), Color(hex: "#CE93D8")]
        case .exhale:
            return [Color(hex: "#E8F5E9"), Color(hex: "#C8E6C9"), Color(hex: "#A5D6A7")]
        case .holdAfter:
            return [Color(hex: "#FFF3E0"), Color(hex: "#FFE0B2"), Color(hex: "#FFCC80")]
        }
    }
    
    func startCountdown() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCountdown = true
        }
        
        // Countdown from 3 to 1
        countdownNumber = 3
        
        // 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                countdownNumber = 2
            }
        }
        
        // 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                countdownNumber = 1
            }
        }
        
        // 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                countdownNumber = 0
            }
            
            // Start breathing exercise after countdown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCountdown = false
                    hasStarted = true
                }
                startBreathingCycle()
            }
        }
    }
    
    func startBreathingCycle() {
        // Start timer
        startCountdownTimer()
        
        // Small delay to ensure UI is ready, then trigger first inhale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            breathingPhase = .inhale
            performInhale()
        }
    }
    
    func startCountdownTimer() {
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                } else {
                    cycleTimer?.invalidate()
                    // Show completion overlay and let the user dismiss
                    // explicitly via the "Done" button for a smoother experience.
                    showCompletionMessage = true
                }
            }
        }
    }
    
    func performInhale() {
        breathingPhase = .inhale
        createInhaleParticles()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            performHold()
        }
    }
    
    func performHold() {
        breathingPhase = .hold
        airParticles.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.performExhale()
        }
    }
    
    func performExhale() {
        breathingPhase = .exhale
        createExhaleParticles()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.performHoldAfter()
        }
    }
    
    func performHoldAfter() {
        breathingPhase = .holdAfter
        airParticles.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if self.secondsRemaining > 0 {
                self.performInhale()
            }
        }
    }
    
    func createInhaleParticles() {
        airParticles.removeAll()
        
        // Create particles flowing upward into lungs
        for i in 0..<20 {
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let startX = 200 + CGFloat.random(in: -40...40)
                let particle = AirParticle(
                    id: UUID(),
                    position: CGPoint(x: startX, y: 500),
                    size: CGFloat.random(in: 12...20),
                    opacity: 0.6
                )
                airParticles.append(particle)
                
                // Animate upward into lungs
                withAnimation(.easeInOut(duration: 3.5)) {
                    if let index = airParticles.firstIndex(where: { $0.id == particle.id }) {
                        airParticles[index].position = CGPoint(x: 200 + CGFloat.random(in: -30...30), y: 200)
                        airParticles[index].size *= 0.5
                    }
                }
                
                // Fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        if let index = airParticles.firstIndex(where: { $0.id == particle.id }) {
                            airParticles[index].opacity = 0
                        }
                    }
                }
            }
        }
    }
    
    func createExhaleParticles() {
        airParticles.removeAll()
        
        // Create particles flowing downward out of lungs
        for i in 0..<20 {
            let delay = Double(i) * 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let startX = 200 + CGFloat.random(in: -30...30)
                let particle = AirParticle(
                    id: UUID(),
                    position: CGPoint(x: startX, y: 200),
                    size: CGFloat.random(in: 8...14),
                    opacity: 0.6
                )
                airParticles.append(particle)
                
                // Animate downward out of lungs
                withAnimation(.easeInOut(duration: 3.5)) {
                    if let index = airParticles.firstIndex(where: { $0.id == particle.id }) {
                        airParticles[index].position = CGPoint(x: 200 + CGFloat.random(in: -50...50), y: 500)
                        airParticles[index].size *= 1.4
                    }
                }
                
                // Fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        if let index = airParticles.firstIndex(where: { $0.id == particle.id }) {
                            airParticles[index].opacity = 0
                        }
                    }
                }
            }
        }
    }
}

struct AirParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

// MARK: - Grade Card
struct GradeCard: View {
    let grade: AssignmentGrade
    let onTap: () -> Void
    
    private var gradeColor: Color {
        if let numeric = grade.numericGrade {
            if numeric >= 90 { return Color(hex: "#4CAF50") } // A - Green
            if numeric >= 80 { return Color(hex: "#8BC34A") } // B - Light green
            if numeric >= 70 { return Color(hex: "#FFC107") } // C - Yellow
            if numeric >= 60 { return Color(hex: "#FF9800") } // D - Orange
            return Color(hex: "#F44336") // F - Red
        }
        // Letter grade parsing
        if grade.grade.starts(with: "A") { return Color(hex: "#4CAF50") }
        if grade.grade.starts(with: "B") { return Color(hex: "#8BC34A") }
        if grade.grade.starts(with: "C") { return Color(hex: "#FFC107") }
        if grade.grade.starts(with: "D") { return Color(hex: "#FF9800") }
        return Color(hex: "#F44336")
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(grade.grade)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(gradeColor)
                    Spacer()
                    VStack(spacing: 4) {
                        if grade.photoData != nil {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundStyle(gradeColor.opacity(0.6))
                        }
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(gradeColor.opacity(0.6))
                    }
                }
                
                Text(grade.assignmentName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MF.primaryTextColor)
                    .lineLimit(2)
                
                Text(grade.dateSubmitted, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradeColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(gradeColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grade Folder View
struct GradeFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    let assignments: [CalendarEvent]
    @Binding var grades: [AssignmentGrade]
    let onAddGrade: (AssignmentGrade) -> Void
    
    @State private var selectedClass: String?
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    // Group assignments by class - ONLY show classes from Profile
    private var assignmentsByClass: [(className: String, assignments: [CalendarEvent], classColor: String)] {
        // Only include assignments that have a className matching a class in Profile
        let validAssignments = assignments.filter { assignment in
            guard let className = assignment.className else { return false }
            return studentClasses.contains(where: { $0.name == className })
        }
        
        let grouped = Dictionary(grouping: validAssignments) { assignment in
            assignment.className!
        }
        
        return grouped.map { className, classAssignments in
            let classColor = studentClasses.first(where: { $0.name == className })?.color ?? "#9E9E9E"
            return (className: className, assignments: classAssignments.sorted { $0.start < $1.start }, classColor: classColor)
        }
        .sorted { $0.className < $1.className }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if assignmentsByClass.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                            Text("No classes with assignments")
                                .font(.headline)
                            Text("Add classes in Profile → My Classes, then assign them to your assignments in the Calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(40)
                    } else {
                        // Class Cards
                        ForEach(assignmentsByClass, id: \.className) { classGroup in
                            NavigationLink(destination: ClassAssignmentsView(
                                className: classGroup.className,
                                classColor: classGroup.classColor,
                                assignments: classGroup.assignments,
                                grades: $grades,
                                onAddGrade: onAddGrade,
                                store: store
                            )) {
                                ClassCard(
                                    className: classGroup.className,
                                    classColor: classGroup.classColor,
                                    assignmentCount: classGroup.assignments.count,
                                    gradedCount: classGroup.assignments.filter { assignment in
                                        grades.contains(where: { $0.assignmentId == assignment.id })
                                    }.count
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Grade Folder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Class Card
struct ClassCard: View {
    let className: String
    let classColor: String
    let assignmentCount: Int
    let gradedCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Class color circle with initial
            Circle()
                .fill(Color(hex: classColor))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(className.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
            
            // Class info
            VStack(alignment: .leading, spacing: 6) {
                Text(className)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    Label("\(assignmentCount)", systemImage: "doc.text")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Label("\(gradedCount) graded", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: classColor).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: classColor).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Class Assignments View
struct ClassAssignmentsView: View {
    let className: String
    let classColor: String
    let assignments: [CalendarEvent]
    @Binding var grades: [AssignmentGrade]
    let onAddGrade: (AssignmentGrade) -> Void
    let store: DataStore
    
    @State private var selectedAssignment: CalendarEvent?
    @State private var selectedGrade: AssignmentGrade?
    @State private var showGradeAnalysis = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(assignments) { assignment in
                    let grade = grades.first(where: { $0.assignmentId == assignment.id })
                    AssignmentGradeRow(
                        assignment: assignment,
                        hasGrade: grade != nil,
                        grade: grade,
                        onAddGrade: {
                            selectedAssignment = assignment
                        },
                        onViewGrade: {
                            selectedGrade = grade
                            showGradeAnalysis = true
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle(className)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAssignment) { assignment in
            AddGradeSheet(
                assignment: assignment,
                store: store,
                onSave: { grade in
                    onAddGrade(grade)
                    selectedAssignment = nil
                }
            )
        }
        .sheet(isPresented: $showGradeAnalysis) {
            if let grade = selectedGrade {
                GradeAnalysisView(grade: grade, store: store, grades: $grades)
            }
        }
    }
}

// MARK: - Assignment Grade Row
struct AssignmentGradeRow: View {
    let assignment: CalendarEvent
    let hasGrade: Bool
    let grade: AssignmentGrade?
    let onAddGrade: () -> Void
    let onViewGrade: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.headline)
                Text(assignment.start, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if hasGrade, let grade = grade {
                HStack(spacing: 8) {
                    Text(grade.grade)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onViewGrade()
                }
            } else {
                Text("Add Grade")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FFB347"))
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .onTapGesture {
                        onAddGrade()
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MF.isNightTime ? Color.white.opacity(0.05) : Color(.systemGray6))
        )
    }
}

// MARK: - Add Grade Sheet
struct AddGradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let assignment: CalendarEvent
    let store: DataStore
    let onSave: (AssignmentGrade) -> Void
    
    @State private var gradeInput: String = ""
    @State private var selectedGradeType: GradeType = .letter
    @State private var gradePhoto: UIImage?
    @State private var showBreathingExercise = false
    @State private var showStudyProfile = false
    @State private var showBadgeDetail = false
    @State private var shootingStars: [ShootingStar] = []
    @State private var showFilePicker = false
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showImagePicker = false
    @AppStorage("studentProfileData") private var studentProfileData: Data = Data()
    
    enum GradeType {
        case letter, percentage, points
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment") {
                    Text(assignment.title)
                        .font(.headline)
                    Text(assignment.start, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Grade") {
                    Picker("Grade Type", selection: $selectedGradeType) {
                        Text("Letter (A, B, C)").tag(GradeType.letter)
                        Text("Percentage (0-100)").tag(GradeType.percentage)
                        Text("Points").tag(GradeType.points)
                    }
                    
                    TextField("Enter grade", text: $gradeInput)
                        .keyboardType(selectedGradeType == .letter ? .default : .decimalPad)
                }
                
                Section {
                    VStack(spacing: 12) {
                        if let photo = gradePhoto {
                            // Show uploaded photo
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Photo uploaded")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button("Change Photo") {
                                showPhotoOptions = true
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            // Show upload button
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                
                                Text("Add Photo (Optional)")
                                    .font(.headline)
                                    .foregroundStyle(MF.primaryTextColor)
                                
                                Text("Upload a photo of your graded work to earn achievement badges")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 20)
                            
                            Button {
                                showPhotoOptions = true
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Add Photo")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("Proof of Grade (Optional)")
                } footer: {
                    Text("Add a photo to verify your grade and earn achievement badges")
                }
                
                Section {
                    Button("Save Grade") {
                        saveGrade()
                    }
                    .disabled(gradeInput.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Choose from Files") {
                    showFilePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $gradePhoto, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $gradePhoto, sourceType: .camera)
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    loadImage(from: url)
                case .failure(let error):
                    print("File picker error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadImage(from url: URL) {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Load image data
        if let imageData = try? Data(contentsOf: url),
           let image = UIImage(data: imageData) {
            gradePhoto = image
        }
    }
    
    private func saveGrade() {
        let numericGrade = calculateNumericGrade()
        let weekData = generateWeekAnalysis()
        
        // Get existing grades from parent view for class-specific badge calculation
        // Note: This will be passed from the parent StudyView context
        let existingGrades: [AssignmentGrade] = []
        
        // Only award badges for tests and exams, not regular assignments
        let earnedBadge: AchievementBadge?
        if assignment.category == "Tests" || assignment.category == "Exams" {
            earnedBadge = AchievementBadge.classSpecificBadge(
                for: gradeInput,
                numericGrade: numericGrade,
                className: assignment.className,
                existingGrades: existingGrades
            )
        } else {
            earnedBadge = nil
        }
        
        // Convert photo to data
        let photoData = gradePhoto?.jpegData(compressionQuality: 0.8)
        
        let grade = AssignmentGrade(
            assignmentId: assignment.id,
            assignmentName: assignment.title,
            className: assignment.className,
            grade: gradeInput,
            numericGrade: numericGrade,
            dateSubmitted: Date(),
            weekLeadingUpData: weekData,
            badge: earnedBadge,
            photoData: photoData
        )
        
        onSave(grade)
        dismiss()
    }
    
    private func calculateNumericGrade() -> Double? {
        switch selectedGradeType {
        case .percentage:
            return Double(gradeInput)
        case .letter:
            // Convert letter grade to numeric
            let grade = gradeInput.uppercased()
            if grade.starts(with: "A") { return grade.contains("+") ? 97 : grade.contains("-") ? 90 : 93 }
            if grade.starts(with: "B") { return grade.contains("+") ? 87 : grade.contains("-") ? 80 : 83 }
            if grade.starts(with: "C") { return grade.contains("+") ? 77 : grade.contains("-") ? 70 : 73 }
            if grade.starts(with: "D") { return grade.contains("+") ? 67 : grade.contains("-") ? 60 : 63 }
            if grade.starts(with: "F") { return 50 }
            return nil
        case .points:
            return nil // Would need max points to calculate
        }
    }
    
    private func generateWeekAnalysis() -> WeekAnalysisData {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: assignment.start) ?? assignment.start
        
        // Get moods from the week leading up to assignment
        let weekMoods = store.moods.filter { mood in
            mood.date >= weekAgo && mood.date <= assignment.start
        }
        
        let averageMood = weekMoods.isEmpty ? 5.0 : Double(weekMoods.map { $0.mood }.reduce(0, +)) / Double(weekMoods.count)
        
        // Calculate mood trend
        let firstHalf = weekMoods.prefix(weekMoods.count / 2)
        let secondHalf = weekMoods.suffix(weekMoods.count / 2)
        let firstAvg = firstHalf.isEmpty ? 5.0 : Double(firstHalf.map { $0.mood }.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? 5.0 : Double(secondHalf.map { $0.mood }.reduce(0, +)) / Double(secondHalf.count)
        
        let moodTrend: String
        if secondAvg > firstAvg + 0.5 { moodTrend = "improving" }
        else if secondAvg < firstAvg - 0.5 { moodTrend = "declining" }
        else { moodTrend = "stable" }
        
        // Estimate study time (would need actual tracking)
        let totalStudyTime = 0 // Placeholder
        
        // Determine stress level from mood
        let stressLevel: String
        if averageMood <= 3 { stressLevel = "high" }
        else if averageMood <= 5 { stressLevel = "moderate" }
        else { stressLevel = "low" }
        
        // Generate recommendations based on data
        var recommendations: [String] = []
        var strengths: [String] = []
        var improvements: [String] = []
        
        if moodTrend == "declining" {
            recommendations.append("Your mood declined during this period. Consider taking more breaks and practicing self-care.")
            improvements.append("Mood management during study periods")
        } else if moodTrend == "improving" {
            strengths.append("Your mood improved while working on this assignment")
        }
        
        if stressLevel == "high" {
            recommendations.append("High stress detected. Try the breathing exercises or brain breaks more frequently.")
            improvements.append("Stress management techniques")
        } else if stressLevel == "low" {
            strengths.append("You maintained low stress levels throughout")
        }
        
        if weekMoods.count < 4 {
            recommendations.append("Log your mood more consistently to get better insights.")
        } else {
            strengths.append("Consistent mood tracking")
        }
        
        // Analyze completed assignments in the week leading up
        let completedInWeek = store.events.filter { event in
            (event.category == "Assignments" || event.category == "Tests" || event.category == "Exams") &&
            event.isCompleted &&
            event.start >= weekAgo && event.start <= assignment.start
        }
        
        var completedAssignments: [CompletedAssignmentInfo] = []
        for completed in completedInWeek {
            // Since we don't track exact completion date yet, we'll use the due date
            // This feature will show completed assignments and can be enhanced later with actual completion tracking
            let completionDate = completed.start
            let daysBeforeDue = 0
            
            // For now, mark all as "on-time" since we don't have completion date tracking
            let timing = "on-time"
            
            completedAssignments.append(CompletedAssignmentInfo(
                id: completed.id,
                name: completed.title,
                dueDate: completed.start,
                completionDate: completionDate,
                daysBeforeDue: daysBeforeDue,
                completionTiming: timing
            ))
        }
        
        // Add productivity recommendations
        if !completedAssignments.isEmpty {
            strengths.append("Completed \(completedAssignments.count) assignment(s) during this period")
            
            // Add anti-procrastination recommendations
            recommendations.append("💡 Complete assignments 1-2 days before the due date to reduce last-minute stress and feel less cluttered.")
            recommendations.append("🔔 Enable calendar reminders to start assignments 3-5 days before they're due.")
            recommendations.append("📋 Break large assignments into smaller tasks and tackle them across multiple days.")
            
            improvements.append("Time management: Start assignments earlier to avoid feeling rushed")
        } else {
            // If no assignments completed, encourage better planning
            recommendations.append("📅 Plan ahead: Set reminders to start assignments well before the due date.")
            recommendations.append("✅ Check off assignments as you complete them to track your progress.")
        }
        
        return WeekAnalysisData(
            averageMood: averageMood,
            totalStudyTime: totalStudyTime,
            moodTrend: moodTrend,
            studyConsistency: Double(weekMoods.count) / 7.0,
            stressLevel: stressLevel,
            recommendations: recommendations,
            strengths: strengths,
            areasForImprovement: improvements,
            completedAssignments: completedAssignments.isEmpty ? nil : completedAssignments
        )
    }
}

// MARK: - Grade Analysis View
struct GradeAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    var grade: AssignmentGrade
    let store: DataStore
    @Binding var grades: [AssignmentGrade]
    
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeOpacity: Double = 0
    @State private var badgeGlow: CGFloat = 0
    @State private var showBadgeFullScreen = false
    
    private var isExcellentGrade: Bool {
        if let numeric = grade.numericGrade {
            return numeric >= 90
        }
        return grade.grade.starts(with: "A")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Grade Header
                        VStack(spacing: 12) {
                            // Badge display
                            if let badge = grade.badge, !showBadgeFullScreen {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: badge.gradientColors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                        .shadow(color: badge.color.opacity(badgeGlow), radius: 20, x: 0, y: 0)
                                    
                                    Image(systemName: badge.icon)
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                }
                                .scaleEffect(badgeScale)
                                .opacity(badgeOpacity)
                            }
                            
                            Text(grade.grade)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(gradeColor)
                        
                        Text(grade.assignmentName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text(grade.dateSubmitted, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if isExcellentGrade {
                            Text("Outstanding Work! 🌟")
                                .font(.headline)
                                .foregroundStyle(gradeColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(gradeColor.opacity(0.2))
                                )
                        }
                        
                        // Show grade photo
                        if let photoData = grade.photoData, let uiImage = UIImage(data: photoData) {
                            VStack(spacing: 8) {
                                Text("Grade Proof")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(gradeColor.opacity(0.5), lineWidth: 2)
                                    )
                                    .shadow(color: gradeColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    
                    if let weekData = grade.weekLeadingUpData {
                        // Week Analysis
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Week Leading Up Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // Mood Section
                            AnalysisCard(
                                icon: "face.smiling",
                                title: "Mood Analysis",
                                color: Color(hex: "#FF9AA2")
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Average Mood:")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(format: "%.1f/10", weekData.averageMood))
                                            .fontWeight(.semibold)
                                    }
                                    
                                    HStack {
                                        Text("Trend:")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(weekData.moodTrend.capitalized)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(trendColor(weekData.moodTrend))
                                    }
                                    
                                    HStack {
                                        Text("Stress Level:")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(weekData.stressLevel.capitalized)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(stressColor(weekData.stressLevel))
                                    }
                                }
                            }
                            
                            // Strengths
                            if !weekData.strengths.isEmpty {
                                AnalysisCard(
                                    icon: "star.fill",
                                    title: "Your Strengths",
                                    color: Color(hex: "#FFD700")
                                ) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(weekData.strengths, id: \.self) { strength in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                Text(strength)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Recommendations
                            if !weekData.recommendations.isEmpty {
                                AnalysisCard(
                                    icon: "lightbulb.fill",
                                    title: "AI Recommendations",
                                    color: Color(hex: "#90CAF9")
                                ) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(weekData.recommendations, id: \.self) { recommendation in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                Text(recommendation)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Areas for Improvement
                            if !weekData.areasForImprovement.isEmpty {
                                AnalysisCard(
                                    icon: "arrow.up.circle.fill",
                                    title: "Growth Opportunities",
                                    color: Color(hex: "#8BC34A")
                                ) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(weekData.areasForImprovement, id: \.self) { area in
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                Text(area)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Completed Assignments Section
                            if let completedAssignments = weekData.completedAssignments, !completedAssignments.isEmpty {
                                AnalysisCard(
                                    icon: "checkmark.circle.fill",
                                    title: "Completed Assignments",
                                    color: Color(hex: "#4CAF50")
                                ) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(completedAssignments) { assignment in
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(assignment.name)
                                                    .font(.headline)
                                                
                                                HStack {
                                                    Text("Due:")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                    Text(assignment.dueDate, style: .date)
                                                        .font(.caption)
                                                }
                                                
                                                HStack {
                                                    Image(systemName: timingIcon(assignment.completionTiming))
                                                        .foregroundStyle(timingColor(assignment.completionTiming))
                                                    Text(timingText(assignment))
                                                        .font(.subheadline)
                                                        .foregroundStyle(timingColor(assignment.completionTiming))
                                                }
                                                
                                                if assignment != completedAssignments.last {
                                                    Divider()
                                                        .padding(.top, 4)
                                                }
                                            }
                                        }
                                        
                                        // Summary and recommendations
                                        VStack(alignment: .leading, spacing: 12) {
                                            Divider()
                                                .padding(.vertical, 4)
                                            
                                            Text("Tips to Stay Ahead:")
                                                .font(.headline)
                                                .padding(.top, 4)
                                            
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack(alignment: .top, spacing: 8) {
                                                    Text("💡")
                                                    Text("Complete assignments 1-2 days before the due date. This gives you breathing room and reduces that cramped, rushed feeling.")
                                                        .font(.subheadline)
                                                }
                                                
                                                HStack(alignment: .top, spacing: 8) {
                                                    Text("🔔")
                                                    Text("Set calendar reminders to start assignments 3-5 days early. This helps you avoid procrastination and spread out your workload.")
                                                        .font(.subheadline)
                                                }
                                                
                                                HStack(alignment: .top, spacing: 8) {
                                                    Text("📋")
                                                    Text("Break large assignments into smaller tasks. Tackle them across multiple days to feel less overwhelmed and more in control.")
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Grade Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Only show badge animation if it hasn't been shown before
                if grade.badge != nil && !grade.badgeShown {
                    showBadgeFullScreen = true
                    startBadgeAnimation()
                    markBadgeAsShown()
                }
            }
                
                // Full-screen badge overlay
                if showBadgeFullScreen, let badge = grade.badge {
                    ZStack {
                        // Semi-transparent dark background
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            // Badge
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: badge.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 200, height: 200)
                                    .shadow(color: badge.color.opacity(badgeGlow), radius: 40, x: 0, y: 0)
                                
                                Image(systemName: badge.icon)
                                    .font(.system(size: 100))
                                    .foregroundStyle(.white)
                            }
                            .scaleEffect(badgeScale)
                            
                            // Badge name
                            Text(badge.rawValue)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("Achievement Unlocked!")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .opacity(badgeOpacity)
                    }
                }
            }
        }
    }
    
    private func startBadgeAnimation() {
        // Phase 1: Badge appears full screen with glow (0-1 second)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
        }
        
        // Pulse glow effect - longer duration
        withAnimation(.easeInOut(duration: 1.0).repeatCount(4, autoreverses: true)) {
            badgeGlow = 0.8
        }
        
        // Phase 2: After 3.5 seconds, shrink and move to position above grade
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showBadgeFullScreen = false
                badgeScale = 1.0
                badgeGlow = 0.3
            }
        }
    }
    
    private func markBadgeAsShown() {
        // Update the grade in the grades array to mark badge as shown
        if let index = grades.firstIndex(where: { $0.id == grade.id }) {
            grades[index].badgeShown = true
        }
    }
    
    private var gradeColor: Color {
        if let numeric = grade.numericGrade {
            if numeric >= 90 { return Color(hex: "#4CAF50") }
            if numeric >= 80 { return Color(hex: "#8BC34A") }
            if numeric >= 70 { return Color(hex: "#FFC107") }
            if numeric >= 60 { return Color(hex: "#FF9800") }
            return Color(hex: "#F44336")
        }
        if grade.grade.starts(with: "A") { return Color(hex: "#4CAF50") }
        if grade.grade.starts(with: "B") { return Color(hex: "#8BC34A") }
        if grade.grade.starts(with: "C") { return Color(hex: "#FFC107") }
        if grade.grade.starts(with: "D") { return Color(hex: "#FF9800") }
        return Color(hex: "#F44336")
    }
    
    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "improving": return .green
        case "declining": return .red
        default: return .secondary
        }
    }
    
    private func stressColor(_ level: String) -> Color {
        switch level {
        case "low": return .green
        case "moderate": return .orange
        case "high": return .red
        default: return .secondary
        }
    }
    
    private func timingIcon(_ timing: String) -> String {
        switch timing {
        case "early": return "checkmark.circle.fill"
        case "on-time": return "clock.fill"
        case "last-minute": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
    
    private func timingColor(_ timing: String) -> Color {
        switch timing {
        case "early": return .green
        case "on-time": return .blue
        case "last-minute": return .orange
        default: return .secondary
        }
    }
    
    private func timingText(_ assignment: CompletedAssignmentInfo) -> String {
        let days = assignment.daysBeforeDue
        if days >= 3 {
            return "Completed \(days) days early ✨"
        } else if days >= 1 {
            return "Completed \(days) day(s) before due"
        } else if days == 0 {
            return "Completed on due date"
        } else {
            return "Completed \(abs(days)) day(s) late"
        }
    }
    
    private func oldStressColor(_ level: String) -> Color {
        switch level {
        case "low": return .green
        case "moderate": return .orange
        case "high": return .red
        default: return .secondary
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let userBadge: UserBadge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: userBadge.badge.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: userBadge.badge.color.opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: userBadge.badge.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            
            Text(userBadge.badge.rawValue)
                .font(.caption2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            Text(userBadge.assignmentName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(userBadge.badge.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(userBadge.badge.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Badge Earned Overlay
struct BadgeEarnedOverlay: View {
    let badge: AchievementBadge
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Badge Earned!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [badge.color.opacity(0.6), badge.color.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: badge.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: badge.color.opacity(0.8), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                
                Text(badge.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Analysis Card
struct AnalysisCard<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            
            content
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BronchialTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Main bronchi from trachea
        let centerX = width * 0.5
        let tracheaBottom = height * 0.25
        
        // Left main bronchus
        path.move(to: CGPoint(x: centerX, y: tracheaBottom))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.4))
        
        // Left bronchial branches
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.28, y: height * 0.5))
        
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.32, y: height * 0.55))
        
        path.move(to: CGPoint(x: width * 0.32, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.65))
        
        path.move(to: CGPoint(x: width * 0.32, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.68))
        
        // Right main bronchus
        path.move(to: CGPoint(x: centerX, y: tracheaBottom))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.4))
        
        // Right bronchial branches
        path.move(to: CGPoint(x: width * 0.65, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.5))
        
        path.move(to: CGPoint(x: width * 0.65, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.55))
        
        path.move(to: CGPoint(x: width * 0.68, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.65))
        
        path.move(to: CGPoint(x: width * 0.68, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.68))
        
        return path
    }
}

struct LungsShape: Shape {
    var expansion: CGFloat = 1.0 // 0.6 to 1.0
    
    var animatableData: CGFloat {
        get { expansion }
        set { expansion = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Use expansion to make lungs slightly wider when "full"
        let widthExpansion = 0.9 + (expansion - 0.6) * 0.2 // gentle change
        let centerX = width * 0.5

        // MARK: - Left lung (soft, rounded lobe)
        let leftLung = Path { p in
            let top = CGPoint(x: centerX - width * 0.07, y: height * 0.12)
            let outerTop = CGPoint(x: centerX - width * 0.22 * widthExpansion, y: height * 0.2)
            let outerMid = CGPoint(x: centerX - width * 0.24 * widthExpansion, y: height * 0.55)
            let outerBottom = CGPoint(x: centerX - width * 0.16 * widthExpansion, y: height * 0.82)
            let innerBottom = CGPoint(x: centerX - width * 0.04, y: height * 0.9)

            p.move(to: top)
            // Outer curve down
            p.addQuadCurve(to: outerTop,
                           control: CGPoint(x: centerX - width * 0.2 * widthExpansion, y: height * 0.05))
            p.addQuadCurve(to: outerMid,
                           control: CGPoint(x: centerX - width * 0.3 * widthExpansion, y: height * 0.4))
            p.addQuadCurve(to: outerBottom,
                           control: CGPoint(x: centerX - width * 0.3 * widthExpansion, y: height * 0.7))
            // Bottom and inner curve up toward center
            p.addQuadCurve(to: innerBottom,
                           control: CGPoint(x: centerX - width * 0.1, y: height * 0.95))
            p.addQuadCurve(to: top,
                           control: CGPoint(x: centerX - width * 0.02, y: height * 0.3))
        }
        path.addPath(leftLung)

        // MARK: - Right lung (mirror of left)
        let rightLung = Path { p in
            let top = CGPoint(x: centerX + width * 0.07, y: height * 0.12)
            let outerTop = CGPoint(x: centerX + width * 0.22 * widthExpansion, y: height * 0.2)
            let outerMid = CGPoint(x: centerX + width * 0.24 * widthExpansion, y: height * 0.55)
            let outerBottom = CGPoint(x: centerX + width * 0.16 * widthExpansion, y: height * 0.82)
            let innerBottom = CGPoint(x: centerX + width * 0.04, y: height * 0.9)

            p.move(to: top)
            p.addQuadCurve(to: outerTop,
                           control: CGPoint(x: centerX + width * 0.2 * widthExpansion, y: height * 0.05))
            p.addQuadCurve(to: outerMid,
                           control: CGPoint(x: centerX + width * 0.3 * widthExpansion, y: height * 0.4))
            p.addQuadCurve(to: outerBottom,
                           control: CGPoint(x: centerX + width * 0.3 * widthExpansion, y: height * 0.7))
            p.addQuadCurve(to: innerBottom,
                           control: CGPoint(x: centerX + width * 0.1, y: height * 0.95))
            p.addQuadCurve(to: top,
                           control: CGPoint(x: centerX + width * 0.02, y: height * 0.3))
        }
        path.addPath(rightLung)

        // MARK: - Simple trachea stem
        let trachea = Path { p in
            let stemWidth = width * 0.07
            let stemTop = CGPoint(x: centerX, y: height * 0.0)
            let stemBottom = CGPoint(x: centerX, y: height * 0.16)

            p.move(to: CGPoint(x: stemTop.x - stemWidth / 2, y: stemTop.y))
            p.addLine(to: CGPoint(x: stemTop.x + stemWidth / 2, y: stemTop.y))
            p.addLine(to: CGPoint(x: stemBottom.x + stemWidth / 2, y: stemBottom.y))
            p.addLine(to: CGPoint(x: stemBottom.x - stemWidth / 2, y: stemBottom.y))
            p.closeSubpath()
        }
        path.addPath(trachea)

        return path
    }
}

// Note: BrainBreakActivityView full implementation moved to top of file
// Keeping this section for reference but body is now defined above

/*
struct BrainBreakActivityView_FullImplementation: View {
    let activity: BrainBreakActivity
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var userInput = ""
    @State private var showCompletion = false
    
    var body_DISABLED: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [activity.color.opacity(0.2), activity.color.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Icon
                Image(systemName: activity.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(activity.color)
                
                // Title
                Text(activity.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                // Content based on activity type
                activityContent
                
                Spacer()
                
                // Action button
                if !showCompletion {
                    Button(currentStep < stepCount - 1 ? "Next" : "Complete") {
                        if currentStep < stepCount - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            showCompletion = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(activity.color)
                    .font(.headline)
                    .padding(.bottom, 40)
                }
            }
            
            // Completion overlay
            if showCompletion {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        
                        Text("Great job!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Your mind is refreshed")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                }
                .transition(.opacity)
            }
        }
    }
    
    @ViewBuilder
    private var activityContent: some View {
        switch activity {
        case .fiveSenses:
            fiveSensesContent
        case .soundEscape:
            soundEscapeContent
        case .creativePrompt:
            creativePromptContent
        case .stretch:
            stretchContent
        case .gratitude:
            gratitudeContent
        case .focusGame:
            focusGameContent
        case .mentalDeclutter:
            mentalDeclutterContent
        case .visualReset:
            visualResetContent
        }
    }
    
    private var stepCount: Int {
        switch activity {
        case .fiveSenses: return 5
        case .stretch: return 4
        default: return 1
        }
    }
    
    private var fiveSensesContent: some View {
        VStack(spacing: 20) {
            let prompts = [
                "Name 5 things you can see",
                "Name 4 things you can touch",
                "Name 3 things you can hear",
                "Name 2 things you can smell",
                "Name 1 thing you can taste"
            ]
            
            Text(prompts[currentStep])
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Take your time and really notice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var soundEscapeContent: some View {
        VStack(spacing: 20) {
            Text("Close your eyes and imagine...")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🌊 Ocean waves gently lapping")
                Text("🌧️ Soft rain on leaves")
                Text("🔥 Crackling fireplace")
                Text("☕ Quiet café ambiance")
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundStyle(.secondary)
            .padding()
            
            Text("Let your mind drift for a moment")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
    
    private var creativePromptContent: some View {
        VStack(spacing: 20) {
            let prompts = [
                "Draw what your thoughts feel like right now",
                "Write a one-sentence story using the word 'light'",
                "Pick one color that matches your mood",
                "Describe your day in three words",
                "If your stress was an object, what would it be?"
            ]
            
            Text(prompts[Int.random(in: 0..<prompts.count)])
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            TextField("Your response...", text: $userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .lineLimit(3...6)
        }
    }
    
    private var stretchContent: some View {
        VStack(spacing: 20) {
            let stretches = [
                ("Shoulder Rolls", "Roll your shoulders back 5 times"),
                ("Neck Stretch", "Gently tilt your head side to side"),
                ("Wrist Circles", "Rotate your wrists in circles"),
                ("Stand & Reach", "Stand up and reach for the sky")
            ]
            
            VStack(spacing: 16) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 50))
                    .foregroundStyle(activity.color)
                
                Text(stretches[currentStep].0)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(stretches[currentStep].1)
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Text("Feel the space around you expand")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
    
    private var gratitudeContent: some View {
        VStack(spacing: 20) {
            Text("What's one small thing going right today?")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            TextField("Type here...", text: $userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .lineLimit(2...4)
            
            Text("Even tiny wins matter")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
    
    private var focusGameContent: some View {
        VStack(spacing: 20) {
            Text("Follow the breathing circle")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Circle()
                .fill(activity.color.opacity(0.3))
                .frame(width: 100, height: 100)
                .scaleEffect(1.5)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: showCompletion)
            
            Text("Focus on the expanding circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            // Trigger animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCompletion = false
            }
        }
    }
    
    private var mentalDeclutterContent: some View {
        VStack(spacing: 20) {
            Text("What's taking up too much space in your mind right now?")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            TextField("Let it out...", text: $userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
                .lineLimit(3...6)
            
            Text("Release it and let it float away")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
    
    private var visualResetContent: some View {
        VStack(spacing: 20) {
            Text("Watch the calming animation")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(activity.color.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(CGFloat(i + 1) * 0.5)
                        .opacity(1.0 - Double(i) * 0.3)
                        .animation(
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.5),
                            value: showCompletion
                        )
                }
            }
            .frame(height: 150)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showCompletion = false
                }
            }
            
            Text("Breathe and let your mind rest")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
        }
    }
}
*/

// MARK: - 5 Senses Grounding Exercise
struct FiveSensesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var userInputs: [String] = Array(repeating: "", count: 5)
    @State private var showCompletion = false
    
    private let steps = [
        (count: 5, sense: "SEE", prompt: "Name 5 things you can see around you", icon: "eye.fill", color: Color(hex: "#9C27B0")),
        (count: 4, sense: "TOUCH", prompt: "Name 4 things you can touch", icon: "hand.raised.fill", color: Color(hex: "#673AB7")),
        (count: 3, sense: "HEAR", prompt: "Name 3 things you can hear", icon: "ear.fill", color: Color(hex: "#3F51B5")),
        (count: 2, sense: "SMELL", prompt: "Name 2 things you can smell", icon: "nose.fill", color: Color(hex: "#2196F3")),
        (count: 1, sense: "TASTE", prompt: "Name 1 thing you can taste", icon: "mouth.fill", color: Color(hex: "#03A9F4"))
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [steps[currentStep].color.opacity(0.3), steps[currentStep].color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showCompletion {
                completionView
            } else {
                VStack(spacing: 30) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 80))
                        .foregroundStyle(steps[currentStep].color)
                        .shadow(color: steps[currentStep].color.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 8) {
                        Text("\(steps[currentStep].count)")
                            .font(.system(size: 100, weight: .bold, design: .rounded))
                            .foregroundStyle(steps[currentStep].color)
                        
                        Text(steps[currentStep].sense)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(steps[currentStep].prompt)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    TextField("Type here...", text: $userInputs[currentStep])
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)
                        .font(.title3)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index <= currentStep ? steps[currentStep].color : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Button {
                        if currentStep < 4 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            withAnimation {
                                showCompletion = true
                            }
                        }
                    } label: {
                        Text(currentStep < 4 ? "Next" : "Complete")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(steps[currentStep].color)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
            
            Text("Well Done!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("You're grounded and present")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Stretch & Move Exercise
struct StretchMoveView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentExercise = 0
    @State private var countdown = 30
    @State private var timer: Timer?
    @State private var showCompletion = false
    
    private let exercises = [
        (name: "Neck Rolls", instruction: "Slowly roll your head in circles. 5 times each direction", duration: 30, icon: "figure.mind.and.body"),
        (name: "Shoulder Shrugs", instruction: "Lift shoulders to ears, hold 3 seconds, release. Repeat!", duration: 30, icon: "figure.arms.open"),
        (name: "Lunges", instruction: "Step forward, lower your back knee. Alternate legs. Keep your balance!", duration: 30, icon: "figure.walk"),
        (name: "Arm Circles", instruction: "Extend arms out. Make big circles! Forward then backward", duration: 30, icon: "figure.flexibility"),
        (name: "Torso Twist", instruction: "Hands on hips. Twist left and right. Feel the stretch!", duration: 30, icon: "figure.core.training"),
        (name: "Standing Stretch", instruction: "Reach for the sky! Then touch your toes. Nice and easy", duration: 30, icon: "figure.stand"),
        (name: "Shake It Out!", instruction: "Shake your whole body! Let go of all that tension!", duration: 20, icon: "figure.dance")
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4CAF50").opacity(0.3), Color(hex: "#8BC34A").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showCompletion {
                completionView
            } else {
                VStack(spacing: 30) {
                    HStack {
                        Button {
                            timer?.invalidate()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Image(systemName: exercises[currentExercise].icon)
                        .font(.system(size: 100))
                        .foregroundStyle(Color(hex: "#4CAF50"))
                        .shadow(color: Color(hex: "#4CAF50").opacity(0.3), radius: 20)
                    
                    Text(exercises[currentExercise].name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#4CAF50"))
                    
                    Text(exercises[currentExercise].instruction)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(countdown <= 5 ? .orange : Color(hex: "#4CAF50"))
                    
                    Spacer()
                    
                    // Skip button
                    Button {
                        skipExercise()
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Exercise")
                        }
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#4CAF50"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#4CAF50").opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 8)
                    
                    Text("Exercise \(currentExercise + 1) of \(exercises.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: Double(currentExercise), total: Double(exercises.count - 1))
                        .tint(Color(hex: "#4CAF50"))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        countdown = exercises[currentExercise].duration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                if currentExercise < exercises.count - 1 {
                    currentExercise += 1
                    countdown = exercises[currentExercise].duration
                } else {
                    timer?.invalidate()
                    withAnimation {
                        showCompletion = true
                    }
                }
            }
        }
    }
    
    private func skipExercise() {
        timer?.invalidate()
        
        if currentExercise < exercises.count - 1 {
            currentExercise += 1
            startTimer()
        } else {
            withAnimation {
                showCompletion = true
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.cooldown")
                .font(.system(size: 100))
                .foregroundStyle(Color(hex: "#4CAF50"))
            
            Text("Amazing!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("Your body thanks you!")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#4CAF50"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Mental Declutter (Puzzle Game)
struct MentalDeclutterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tiles: [Int] = Array(1...8) + [0]
    @State private var moves = 0
    @State private var showCompletion = false
    @State private var startTime = Date()
    
    let gridSize = 3
    let winningOrder = Array(1...8) + [0]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#673AB7").opacity(0.3), Color(hex: "#9C27B0").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Moves: \(moves)")
                        .font(.headline)
                }
                .padding()
                
                Spacer()
                
                Text("Sliding Puzzle")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#673AB7"))
                
                Text("Arrange the numbers 1-8 in order")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize), spacing: 8) {
                    ForEach(0..<9) { index in
                        if tiles[index] == 0 {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 100)
                        } else {
                            Button {
                                moveTile(at: index)
                            } label: {
                                Text("\(tiles[index])")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 100)
                                    .background(Color(hex: "#673AB7"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(radius: 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Button {
                    shuffleTiles()
                } label: {
                    Text("Shuffle")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#673AB7"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#673AB7").opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .onAppear {
            shuffleTiles()
        }
        .sheet(isPresented: $showCompletion) {
            completionView
        }
    }
    
    private func moveTile(at index: Int) {
        let emptyIndex = tiles.firstIndex(of: 0)!
        let row = index / gridSize
        let col = index % gridSize
        let emptyRow = emptyIndex / gridSize
        let emptyCol = emptyIndex % gridSize
        
        if (abs(row - emptyRow) == 1 && col == emptyCol) || (abs(col - emptyCol) == 1 && row == emptyRow) {
            withAnimation(.spring(response: 0.3)) {
                tiles.swapAt(index, emptyIndex)
                moves += 1
            }
            
            if tiles == winningOrder {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCompletion = true
                }
            }
        }
    }
    
    private func shuffleTiles() {
        tiles = Array(1...8) + [0]
        tiles.shuffle()
        moves = 0
        startTime = Date()
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 100))
                .foregroundStyle(Color(hex: "#673AB7"))
            
            Text("Mind Cleared!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            Text("Solved in \(moves) moves")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#673AB7"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Gratitude Moment View
struct GratitudeMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @State private var gratitudeText: String = ""
    @State private var showCompletion = false
    
    private var moodBasedPrompt: String {
        guard let currentMood = store.moods.first?.mood else {
            return "What are you grateful for today?"
        }
        
        switch currentMood {
        case 1: // Angry
            return "Even when angry, what's one thing that's still good in your life?"
        case 2: // Sad
            return "In this difficult moment, what small comfort can you appreciate?"
        case 3: // Overwhelmed
            return "Amidst the chaos, what's one thing that went right today?"
        case 4: // Drained
            return "What gave you even a tiny bit of energy or joy today?"
        case 5: // Anxious
            return "What's one thing that feels stable or safe right now?"
        case 6: // Okay
            return "What made today better than just 'okay'?"
        case 7: // Good
            return "What made you smile today?"
        case 8: // Amazing
            return "What are you most excited or grateful for right now?"
        default:
            return "What are you grateful for today?"
        }
    }
    
    private var moodBasedSubtitle: String {
        guard let currentMood = store.moods.first?.mood else {
            return "Take a moment to reflect"
        }
        
        switch currentMood {
        case 1, 2, 3: // Negative moods
            return "Finding gratitude in hard times builds resilience"
        case 4, 5: // Low energy/anxious
            return "Small appreciations can shift your perspective"
        case 6, 7: // Neutral to good
            return "Gratitude amplifies the good in your life"
        case 8: // Amazing
            return "Celebrate what's going well!"
        default:
            return "Take a moment to reflect"
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#E91E63").opacity(0.3), Color(hex: "#F06292").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showCompletion {
                completionView
            } else {
                VStack(spacing: 30) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(Color(hex: "#E91E63"))
                        .shadow(color: Color(hex: "#E91E63").opacity(0.3), radius: 20)
                    
                    Text("Gratitude Moment")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#E91E63"))
                    
                    Text(moodBasedPrompt)
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                    
                    Text(moodBasedSubtitle)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your thoughts:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        TextEditor(text: $gratitudeText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#E91E63").opacity(0.3), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showCompletion = true
                        }
                    } label: {
                        Text("Complete")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#E91E63"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color(hex: "#E91E63"))
            
            Text("Beautiful!")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            
            if !gratitudeText.isEmpty {
                Text("You wrote:")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(gratitudeText)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Gratitude shifts perspective")
                .font(.subheadline)
                .italic()
                .foregroundStyle(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#E91E63"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Sound Escape View
struct SoundEscapeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @AppStorage("calmingMusicGenre") private var calmingMusicGenre: String = "Nature Sounds"
    @State private var isPlaying = false
    @State private var countdown = 180
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#2196F3").opacity(0.3), Color(hex: "#03A9F4").opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                HStack {
                    Button {
                        timer?.invalidate()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Image(systemName: "headphones")
                    .font(.system(size: 100))
                    .foregroundStyle(Color(hex: "#2196F3"))
                    .shadow(color: Color(hex: "#2196F3").opacity(0.3), radius: 20)
                
                Text("Sound Escape")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#2196F3"))
                
                Text("Now playing: \(calmingMusicGenre)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text(timeString)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#2196F3"))
                
                Button {
                    isPlaying.toggle()
                    if isPlaying {
                        startTimer()
                    } else {
                        timer?.invalidate()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color(hex: "#2196F3"))
                }
                
                Text(isPlaying ? "Tap to pause" : "Tap to start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var timeString: String {
        let minutes = countdown / 60
        let seconds = countdown % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer?.invalidate()
                isPlaying = false
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack { StudyView() }
}
