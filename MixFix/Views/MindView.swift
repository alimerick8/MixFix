//
//  MindView.swift
//  MixFix
//
import SwiftUI
import SwiftData

struct MindView: View {
    @EnvironmentObject var store: DataStore
    @State private var showBreathingExercise = false
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("moodColorsEnabled") private var moodColorsEnabled: Bool = true
    
    private var moodColor: Color {
        guard let latestMood = store.moods.first?.mood else {
            return Color(.systemGray6)
        }
        switch latestMood {
        case 6: return Color(hex: "#7A4FB0") // Amazing - Purple
        case 5: return Color(hex: "#F4D03F") // Good - Darker Yellow
        case 4: return Color(hex: "#A3BFD9") // Okay - Light Blue
        case 3: return Color(hex: "#595775") // Overwhelmed - Dark Gray
        case 2: return Color(hex: "#1F3A93") // Sad - Dark Blue
        case 1: return Color(hex: "#800000") // Angry - Maroon
        default: return Color(.systemGray6)
        }
    }
    
    private var moodGradient: LinearGradient {
        guard let latestMood = store.moods.first?.mood else {
            return LinearGradient(colors: [Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        switch latestMood {
        case 6: return LinearGradient(colors: [Color(hex: "#9D50BB"), Color(hex: "#6E48AA")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 5: return LinearGradient(colors: [Color(hex: "#F4D03F"), Color(hex: "#F39C12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 4: return LinearGradient(colors: [Color(hex: "#A3BFD9"), Color(hex: "#6FA3D9")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3: return LinearGradient(colors: [Color(hex: "#595775"), Color(hex: "#3E3E52")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [Color(hex: "#1F3A93"), Color(hex: "#0F2557")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(colors: [Color(hex: "#800000"), Color(hex: "#500000")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var todayMoods: [MoodEntry] {
        let calendar = Calendar.current
        return store.moods.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date } // Most recent first
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😡"
        case 2: return "☹️"
        case 3: return "😵‍💫"
        case 4: return "🫠"
        case 5: return "😰"
        case 6: return "😒"
        case 7: return "😐"
        case 8: return "🙂"
        case 9: return "😄"
        default: return "😐"
        }
    }
    
    private func moodLabel(for mood: Int) -> String {
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Breathing Break Section
                breathingBreakSection
            }
            .padding()
        }
        .gradientHeader(title: "Mind", subtitle: "Breathe, reflect, recharge", gradient: MFHeaderStyle.unifiedHeaderGradient(
            moodColorsEnabled: moodColorsEnabled,
            hasRecentMood: !store.moods.isEmpty,
            latestMood: store.moods.first?.mood,
            profileCircleColorName: profileCircleColorName
        ))
        .background(MF.appBackground())
        .fullScreenCover(isPresented: $showBreathingExercise) {
            BreathingExerciseView()
        }
    }
    
    private var breathingBreakSection: some View {
        Button {
            showBreathingExercise = true
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Breathing Break")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "#2C5F7F"))
                    
                    Text("In 4s · Hold 4s · Out 4s")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color(hex: "#5B9BD5"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("1 minute")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: "#5B9BD5").opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "#5B9BD5").opacity(0.5))
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#E8F4F8"),
                            Color(hex: "#D4E8F0")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "#5B9BD5").opacity(0.2), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#90CAF9").opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Mood Tracker Card with Dial
struct MoodTrackerCard: View {
    let moods: [MoodEntry]
    let moodColor: Color
    let moodGradient: LinearGradient
    
    private var latestMood: MoodEntry? {
        moods.first
    }
    
    private var averageMood: Double {
        guard !moods.isEmpty else { return 3.5 }
        let sum = moods.prefix(7).reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(min(moods.count, 7))
    }
    
    private var checkInStreak: Int {
        guard !moods.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if user logged today
        let hasLoggedToday = moods.contains { mood in
            calendar.isDate(mood.date, inSameDayAs: today)
        }
        
        // If no log today, streak is 0
        guard hasLoggedToday else { return 0 }
        
        var streak = 0
        var currentDate = today
        
        // Count consecutive days backwards from today
        while true {
            let hasLoggedOnDate = moods.contains { mood in
                calendar.isDate(mood.date, inSameDayAs: currentDate)
            }
            
            if hasLoggedOnDate {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        ZStack {
            MF.glassBackground()
            VStack(spacing: 12) {
                Text("Mood Tracker")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 20) {
                    // Dial Visualization
                    ZStack {
                        // Background arc
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(135))
                        
                        // Mood arc
                        Circle()
                            .trim(from: 0, to: moodProgress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: moodGradientColors),
                                    center: .center,
                                    startAngle: .degrees(135),
                                    endAngle: .degrees(405)
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(135))
                        
                        // Center emoji
                        VStack(spacing: 4) {
                            Text(currentEmoji)
                                .font(.system(size: 36))
                            Text(moodLabel)
                                .font(.caption2)
                                .foregroundStyle(MF.secondaryTextColor)
                        }
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current")
                                .font(.caption)
                                .foregroundStyle(MF.secondaryTextColor)
                            Spacer()
                            Text(currentEmoji)
                                .font(.title3)
                        }
                        
                        HStack {
                            Text("7-day avg")
                                .font(.caption)
                                .foregroundStyle(MF.secondaryTextColor)
                            Spacer()
                            Text(String(format: "%.1f", averageMood))
                                .font(.headline)
                        }
                        
                        HStack {
                            Text("Check-in Streak")
                                .font(.caption)
                                .foregroundStyle(MF.secondaryTextColor)
                            Spacer()
                            HStack(spacing: 2) {
                                Text("\(checkInStreak)")
                                    .font(.headline)
                                Text("🔥")
                                    .font(.caption)
                                    .opacity(checkInStreak > 0 ? 1 : 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Emoji scale reference - show all 9 moods
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(1...9, id: \.self) { i in
                            VStack(spacing: 2) {
                                Text(emoji(for: i))
                                    .font(.caption)
                                Text(moodName(for: i))
                                    .font(.system(size: 8))
                                    .foregroundStyle(MF.secondaryTextColor)
                            }
                            .frame(minWidth: 50)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(moodGradient, lineWidth: 4)
        )
    }
    
    private var moodProgress: CGFloat {
        guard let latest = latestMood else { return 0.5 }
        return CGFloat(latest.mood - 1) / 8.0 * 0.75
    }
    
    private var currentEmoji: String {
        guard let latest = latestMood else { return "😐" }
        return emoji(for: latest.mood)
    }
    
    private var moodLabel: String {
        guard let latest = latestMood else { return "No data" }
        return moodName(for: latest.mood)
    }
    
    private var moodGradientColors: [Color] {
        [
            Color.red,
            Color.orange,
            Color.yellow,
            Color.green,
            Color.blue,
            Color.purple
        ]
    }
    
    private func emoji(for i: Int) -> String {
        switch i {
        case 1: return "😡"      // Angry
        case 2: return "☹️"      // Sad
        case 3: return "😵‍💫"    // Overwhelmed
        case 4: return "🫠"      // Drained
        case 5: return "😰"      // Anxious
        case 6: return "😒"      // Annoyed
        case 7: return "😐"      // Okay
        case 8: return "🙂"      // Good
        case 9: return "😄"      // Amazing
        default: return "😐"
        }
    }
    
    private func moodName(for i: Int) -> String {
        switch i {
        case 1: return "Angry"
        case 2: return "Sad"
        case 3: return "Overwhelmed"
        case 4: return "Drained"
        case 5: return "Anxious"
        case 6: return "Annoyed"
        case 7: return "Okay"
        case 8: return "Good"
        case 9: return "Amazing"
        default: return "Okay"
        }
    }
}

// MARK: - Journal Entry View
struct JournalEntryView: View {
    let prompt: String
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var journalText = ""
    @State private var title = ""
    @State private var showJournalHistory = false
    @State private var showPasswordSetup = false
    @AppStorage("journalPassword") private var journalPassword: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Night background
                MF.appBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Prompt header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection Prompt")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.6))
                            .textCase(.uppercase)
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.3))
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Title field
                    TextField("Entry Title (optional)", text: $title)
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.clear)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Journal text editor
                    ZStack(alignment: .topLeading) {
                        if journalText.isEmpty {
                            Text("What's on your mind? What do you want to reflect on?")
                                .foregroundColor(.black.opacity(0.4))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $journalText)
                            .font(.body)
                            .foregroundColor(.black)
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                    .background(Color.clear)
                }
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        showJournalHistory = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.caption)
                            Text("History")
                                .font(.caption)
                        }
                        .foregroundStyle(.purple)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Check if password needs to be set
                        if journalPassword.isEmpty {
                            showPasswordSetup = true
                        } else {
                            let entryTitle = title.isEmpty ? nil : title
                            store.addJournalEntry(title: entryTitle, content: journalText)
                            dismiss()
                        }
                    }
                    .disabled(journalText.isEmpty)
                }
            }
            .sheet(isPresented: $showJournalHistory) {
                JournalPasswordGateView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPasswordSetup) {
                JournalPasswordSetupView(
                    journalText: journalText,
                    title: title,
                    onPasswordSet: { password in
                        journalPassword = password
                        let entryTitle = title.isEmpty ? nil : title
                        store.addJournalEntry(title: entryTitle, content: journalText)
                        dismiss()
                    }
                )
            }
        }
    }
}

// MARK: - Monthly Mood Chart View
struct MonthlyMoodChartView: View {
    let moods: [MoodEntry]
    @Environment(\.dismiss) private var dismiss
    
    private var moodColor: Color {
        guard let latestMood = moods.first?.mood else {
            return Color(.systemBackground)
        }
        switch latestMood {
        case 6: return Color(hex: "#7A4FB0") // Amazing - Purple
        case 5: return Color(hex: "#F4D03F") // Good - Darker Yellow
        case 4: return Color(hex: "#A3BFD9") // Okay - Light Blue
        case 3: return Color(hex: "#595775") // Overwhelmed - Dark Gray
        case 2: return Color(hex: "#1F3A93") // Sad - Dark Blue
        case 1: return Color(hex: "#800000") // Angry - Maroon
        default: return Color(.systemBackground)
        }
    }
    
    private var textColor: Color {
        guard let latestMood = moods.first?.mood else {
            return .primary
        }
        // Use white text for dark backgrounds
        return (latestMood == 1 || latestMood == 2 || latestMood == 3 || latestMood == 6) ? .white : .primary
    }
    
    private var moodsThisMonth: [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        return moods.filter { mood in
            calendar.isDate(mood.date, equalTo: now, toGranularity: .month)
        }
    }
    
    private var averageMood: Double {
        guard !moods.isEmpty else { return 0 }
        let last7 = moods.prefix(7)
        let sum = last7.reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(last7.count)
    }
    
    private var moodStreak: Int {
        guard !moods.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for mood in moods.sorted(by: { $0.date > $1.date }) {
            let moodDate = calendar.startOfDay(for: mood.date)
            if calendar.isDate(moodDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if moodDate < currentDate {
                break
            }
        }
        return streak
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Cards
                    HStack(spacing: 16) {
                        StatBox(title: "7-Day Average", value: String(format: "%.1f", averageMood), textColor: textColor)
                        StatBox(title: "Logging Streak", value: "\(moodStreak) days", textColor: textColor)
                    }
                    .padding(.horizontal)
                    
                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Mood Chart")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(textColor)
                            .padding(.horizontal)
                        
                        MoodChartView(moods: moodsThisMonth, textColor: textColor)
                            .frame(height: 300)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .background(moodColor)
            .navigationTitle("Mood Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(textColor)
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(textColor)
            Text(title)
                .font(.caption)
                .foregroundStyle(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MoodChartView: View {
    let moods: [MoodEntry]
    let textColor: Color
    
    private var chartData: [(day: Int, mood: Int)] {
        let calendar = Calendar.current
        
        // Group moods by day and calculate average mood for each day
        let grouped = Dictionary(grouping: moods) { mood in
            calendar.component(.day, from: mood.date)
        }
        
        // Calculate average mood for each day and sort by day
        return grouped.map { (day, dayMoods) -> (day: Int, mood: Int) in
            let avgMood = Double(dayMoods.map { $0.mood }.reduce(0, +)) / Double(dayMoods.count)
            return (day: day, mood: Int(round(avgMood)))
        }.sorted { $0.day < $1.day }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGray6).opacity(0.3)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 0) {
                    // Chart area
                    ZStack(alignment: .leading) {
                        // Y-axis emojis (10-point scale)
                        VStack(spacing: 0) {
                            ForEach([10, 9, 8, 7, 6, 5, 4, 3, 2, 1], id: \.self) { mood in
                                Text(emoji(for: mood))
                                    .font(.caption)
                                    .frame(width: 35, height: 35)
                                    .background(Circle().stroke(textColor.opacity(0.5), lineWidth: 1))
                                    .frame(height: geometry.size.height / 10)
                            }
                        }
                        .frame(width: 40)
                        
                        // Grid lines (10 levels)
                        VStack(spacing: 0) {
                            ForEach(0..<10) { _ in
                                Divider()
                                    .background(textColor.opacity(0.3))
                                    .frame(height: geometry.size.height / 10)
                            }
                        }
                        .padding(.leading, 40)
                        
                        // Line chart with gradient fill
                        if !chartData.isEmpty {
                            ZStack {
                                // Filled area under the line
                                MoodAreaShape(data: chartData, maxDay: 31, chartHeight: geometry.size.height)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.3),
                                                Color.purple.opacity(0.2),
                                                Color.green.opacity(0.1)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                // Line connecting points
                                MoodLineShape(data: chartData, maxDay: 31, chartHeight: geometry.size.height)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple, Color.green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 3
                                    )
                                
                                // Dots at each data point
                                ForEach(Array(chartData.enumerated()), id: \.offset) { index, point in
                                    let xScale = (geometry.size.width - 40) / CGFloat(31)
                                    let yScale = geometry.size.height / 10.0
                                    let x = CGFloat(point.day - 1) * xScale + 40
                                    let y = CGFloat(10 - point.mood) * yScale + (yScale / 2)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )
                                        .position(x: x, y: y)
                                }
                            }
                            .padding(.leading, 40)
                        }
                    }
                    
                    // X-axis days
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: 40)
                        ForEach([1, 4, 7, 10, 13, 16, 19, 22, 25, 28], id: \.self) { day in
                            Text("\(day)")
                                .font(.subheadline)
                                .foregroundStyle(textColor.opacity(0.7))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
    }
    
    private func emoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😡"
        case 2: return "☹️"
        case 3: return "😵‍💫"
        case 4: return "🫠"
        case 5: return "😰"
        case 6: return "😒"
        case 7: return "😐"
        case 8: return "🙂"
        case 9: return "😄"
        case 10: return "🤩"
        default: return "😐"
        }
    }
}

struct MoodLineShape: Shape {
    let data: [(day: Int, mood: Int)]
    let maxDay: Int
    let chartHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !data.isEmpty else { return path }
        
        let xScale = rect.width / CGFloat(maxDay)
        let yScale = chartHeight / 10.0
        
        // Start at first point
        let firstPoint = data[0]
        let startX = CGFloat(firstPoint.day - 1) * xScale
        // Mood 10 (top) should be at y=0, Mood 1 (bottom) should be at y=chartHeight
        let startY = CGFloat(10 - firstPoint.mood) * yScale + (yScale / 2)
        path.move(to: CGPoint(x: startX, y: startY))
        
        // Draw lines to subsequent points
        for point in data.dropFirst() {
            let x = CGFloat(point.day - 1) * xScale
            let y = CGFloat(10 - point.mood) * yScale + (yScale / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct MoodAreaShape: Shape {
    let data: [(day: Int, mood: Int)]
    let maxDay: Int
    let chartHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !data.isEmpty else { return path }
        
        let xScale = rect.width / CGFloat(maxDay)
        let yScale = chartHeight / 10.0
        
        // Start at bottom left of first point
        let firstPoint = data[0]
        let startX = CGFloat(firstPoint.day - 1) * xScale
        path.move(to: CGPoint(x: startX, y: chartHeight))
        
        // Draw up to first data point
        let firstY = CGFloat(10 - firstPoint.mood) * yScale + (yScale / 2)
        path.addLine(to: CGPoint(x: startX, y: firstY))
        
        // Draw lines through all data points
        for point in data.dropFirst() {
            let x = CGFloat(point.day - 1) * xScale
            let y = CGFloat(10 - point.mood) * yScale + (yScale / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Draw down to bottom right and close the path
        let lastPoint = data.last!
        let endX = CGFloat(lastPoint.day - 1) * xScale
        path.addLine(to: CGPoint(x: endX, y: chartHeight))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Today's Moods View
struct TodayMoodsView: View {
    let moods: [MoodEntry]
    @Environment(\.dismiss) private var dismiss
    
    private var groupedMoods: [(date: String, moods: [MoodEntry], sortDate: Date)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: moods) { mood in
            calendar.startOfDay(for: mood.date)
        }
        
        return grouped.map { (date, moods) in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return (formatter.string(from: date), moods.sorted { $0.date > $1.date }, date)
        }
        .sorted { $0.sortDate > $1.sortDate }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😡"
        case 2: return "☹️"
        case 3: return "😵‍💫"
        case 4: return "🫠"
        case 5: return "😰"
        case 6: return "😒"
        case 7: return "😐"
        case 8: return "🙂"
        case 9: return "😄"
        default: return "😐"
        }
    }
    
    private func moodLabel(for mood: Int) -> String {
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
    
    var body: some View {
        NavigationStack {
            List {
                if moods.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 60))
                            .foregroundStyle(MF.secondaryTextColor)
                        Text("No moods logged")
                            .font(.headline)
                            .foregroundStyle(MF.secondaryTextColor)
                        Text("Check in to track your mood")
                            .font(.subheadline)
                            .foregroundStyle(MF.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(groupedMoods, id: \.date) { group in
                        NavigationLink(destination: DayMoodsView(date: group.date, moods: group.moods)) {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.date)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Text("\(group.moods.count) mood\(group.moods.count == 1 ? "" : "s") logged")
                                        .font(.caption)
                                        .foregroundStyle(MF.secondaryTextColor)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Mood Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Day Moods View
struct DayMoodsView: View {
    let date: String
    let moods: [MoodEntry]
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func moodEmoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😡"
        case 2: return "☹️"
        case 3: return "😵‍💫"
        case 4: return "🫠"
        case 5: return "😰"
        case 6: return "😒"
        case 7: return "😐"
        case 8: return "🙂"
        case 9: return "😄"
        default: return "😐"
        }
    }
    
    private func moodLabel(for mood: Int) -> String {
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
    
    var body: some View {
        List {
            ForEach(moods, id: \.id) { mood in
                HStack(spacing: 12) {
                    Text(moodEmoji(for: mood.mood))
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodLabel(for: mood.mood))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(MF.primaryTextColor)
                        Text(formatTime(mood.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(date)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Journal Password Setup View
struct JournalPasswordSetupView: View {
    let journalText: String
    let title: String
    let onPasswordSet: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.purple)
                    
                    Text("Protect Your Journal")
                        .font(.title2.bold())
                    
                    Text("Create a password to keep your journal entries private and secure.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    SecureField("Create Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    if showError {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Button {
                    if password == confirmPassword && !password.isEmpty {
                        onPasswordSet(password)
                        dismiss()
                    } else {
                        showError = true
                    }
                } label: {
                    Text("Set Password & Save Entry")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(password.isEmpty || password != confirmPassword ? Color.gray : Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(password.isEmpty || password != confirmPassword)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Journal Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Journal Password Gate View
struct JournalPasswordGateView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("journalPassword") private var journalPassword: String = ""
    @AppStorage("journalPasswordEnabled") private var journalPasswordEnabled: Bool = true
    @State private var enteredPassword = ""
    @State private var showError = false
    @State private var isUnlocked = false
    
    var body: some View {
        if !journalPasswordEnabled || journalPassword.isEmpty {
            // Password disabled or no password set yet, show history directly
            JournalHistoryView()
                .environmentObject(store)
        } else if isUnlocked {
            JournalHistoryView()
                .environmentObject(store)
        } else {
            NavigationStack {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                        
                        Text("Journal Locked")
                            .font(.title2.bold())
                        
                        Text("Enter your password to view your journal entries.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        SecureField("Enter Password", text: $enteredPassword)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .onSubmit {
                                checkPassword()
                            }
                        
                        if showError {
                            Text("Incorrect password")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Button {
                        checkPassword()
                    } label: {
                        Text("Unlock")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(enteredPassword.isEmpty ? Color.gray : Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(enteredPassword.isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationTitle("Enter Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func checkPassword() {
        if enteredPassword == journalPassword {
            withAnimation {
                isUnlocked = true
            }
        } else {
            showError = true
            enteredPassword = ""
        }
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let moods: [MoodEntry]
    let events: [CalendarEvent]
    @EnvironmentObject var store: DataStore
    @State private var showClassCheckIn = false
    @State private var refreshTrigger = UUID()
    
    private var isMoodStreakFrozen: Bool {
        guard !moods.isEmpty else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hasLoggedToday = moods.contains { mood in
            calendar.isDate(mood.date, inSameDayAs: today)
        }
        return !hasLoggedToday && moodStreak > 0
    }
    
    private var moodStreak: Int {
        guard !moods.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if user logged today
        let hasLoggedToday = moods.contains { mood in
            calendar.isDate(mood.date, inSameDayAs: today)
        }
        
        // If no log today, check yesterday to show frozen streak
        if !hasLoggedToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            let hasLoggedYesterday = moods.contains { mood in
                calendar.isDate(mood.date, inSameDayAs: yesterday)
            }
            // If logged yesterday, calculate yesterday's streak (frozen)
            if hasLoggedYesterday {
                var streak = 0
                var currentDate = yesterday
                while true {
                    let hasLoggedOnDate = moods.contains { mood in
                        calendar.isDate(mood.date, inSameDayAs: currentDate)
                    }
                    if hasLoggedOnDate {
                        streak += 1
                        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                        currentDate = previousDay
                    } else {
                        break
                    }
                }
                return streak
            }
            return 0
        }
        
        var streak = 0
        var currentDate = today
        
        // Count consecutive days backwards from today
        while true {
            let hasLoggedOnDate = moods.contains { mood in
                calendar.isDate(mood.date, inSameDayAs: currentDate)
            }
            
            if hasLoggedOnDate {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    private var isClassStreakFrozen: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let checkIns = store.classCheckIns
        let hasCheckedInToday = checkIns.contains { checkIn in
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
        return !hasCheckedInToday && classStreak > 0
    }
    
    private var classStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get class check-ins from DataStore (explicitly depend on published property)
        let checkIns = store.classCheckIns
        
        // Debug: Print check-ins to verify data
        print("📚 Class Check-Ins Count: \(checkIns.count)")
        if let latest = checkIns.first {
            print("📚 Latest Check-In: \(latest.className) on \(latest.date)")
        }
        
        guard !checkIns.isEmpty else { return 0 }
        
        // Check if user checked in today
        let hasCheckedInToday = checkIns.contains { checkIn in
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
        
        // If no check-in today, check yesterday to show frozen streak
        if !hasCheckedInToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            let hasCheckedInYesterday = checkIns.contains { checkIn in
                calendar.isDate(checkIn.date, inSameDayAs: yesterday)
            }
            // If checked in yesterday, calculate yesterday's streak (frozen)
            if hasCheckedInYesterday {
                var streak = 0
                var currentDate = yesterday
                while true {
                    let hasCheckedInOnDate = checkIns.contains { checkIn in
                        calendar.isDate(checkIn.date, inSameDayAs: currentDate)
                    }
                    if hasCheckedInOnDate {
                        streak += 1
                        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                        currentDate = previousDay
                    } else {
                        break
                    }
                }
                return streak
            }
            return 0
        }
        
        var streak = 0
        var currentDate = today
        
        // Count consecutive days backwards from today
        while true {
            let hasCheckedInOnDate = checkIns.contains { checkIn in
                calendar.isDate(checkIn.date, inSameDayAs: currentDate)
            }
            
            if hasCheckedInOnDate {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    private var isStudyStreakFrozen: Bool {
        guard let data = UserDefaults.standard.data(forKey: "studySessionCompletions"),
              let completions = try? JSONDecoder().decode([Date].self, from: data) else {
            return false
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hasCompletedToday = completions.contains { date in
            calendar.isDate(date, inSameDayAs: today)
        }
        return !hasCompletedToday && studySessionStreak > 0
    }
    
    private var studySessionStreak: Int {
        // Get study session completion data from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "studySessionCompletions"),
              let completions = try? JSONDecoder().decode([Date].self, from: data) else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if user completed a session today
        let hasCompletedToday = completions.contains { date in
            calendar.isDate(date, inSameDayAs: today)
        }
        
        // If no completion today, check yesterday to show frozen streak
        if !hasCompletedToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            let hasCompletedYesterday = completions.contains { date in
                calendar.isDate(date, inSameDayAs: yesterday)
            }
            // If completed yesterday, calculate yesterday's streak (frozen)
            if hasCompletedYesterday {
                var streak = 0
                var currentDate = yesterday
                while true {
                    let hasCompletedOnDate = completions.contains { date in
                        calendar.isDate(date, inSameDayAs: currentDate)
                    }
                    if hasCompletedOnDate {
                        streak += 1
                        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                        currentDate = previousDay
                    } else {
                        break
                    }
                }
                return streak
            }
            return 0
        }
        
        var streak = 0
        var currentDate = today
        
        // Count consecutive days backwards from today
        while true {
            let hasCompletedOnDate = completions.contains { date in
                calendar.isDate(date, inSameDayAs: currentDate)
            }
            
            if hasCompletedOnDate {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Streaks")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(MF.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 0)
            
            // Three individual streak cards
            VStack(spacing: 8) {
                // Mood Log Streak Card
                HStack(spacing: 12) {
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.purple)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Mood Logs")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(MF.primaryTextColor)
                        Text("Daily check-in streak")
                            .font(.system(size: 10))
                            .foregroundStyle(MF.primaryTextColor.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(moodStreak)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(moodStreak > 0 ? .purple : MF.primaryTextColor.opacity(0.3))
                        Image(systemName: isMoodStreakFrozen ? "snowflake" : "flame.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isMoodStreakFrozen ? .cyan.opacity(0.6) : (moodStreak > 0 ? .orange : MF.primaryTextColor.opacity(0.2)))
                            .offset(y: -1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(MF.glassBackground())
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                
                // Class Attendance Streak Card
                Button {
                    showClassCheckIn = true
                } label: {
                    let _ = store.classCheckIns.count // Force dependency on array changes
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Class Logs")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(MF.primaryTextColor)
                            Text("Daily attendance streak")
                                .font(.system(size: 10))
                                .foregroundStyle(MF.primaryTextColor.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(classStreak)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(classStreak > 0 ? .blue : MF.primaryTextColor.opacity(0.3))
                            Image(systemName: isClassStreakFrozen ? "snowflake" : "flame.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isClassStreakFrozen ? .cyan.opacity(0.6) : (classStreak > 0 ? .orange : MF.primaryTextColor.opacity(0.2)))
                                .offset(y: -1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(MF.glassBackground())
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                
                // Study Session Streak Card
                HStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Study Sessions")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(MF.primaryTextColor)
                        Text("Daily completion streak")
                            .font(.system(size: 10))
                            .foregroundStyle(MF.primaryTextColor.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(studySessionStreak)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(studySessionStreak > 0 ? .green : MF.primaryTextColor.opacity(0.3))
                        Image(systemName: isStudyStreakFrozen ? "snowflake" : "flame.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isStudyStreakFrozen ? .cyan.opacity(0.6) : (studySessionStreak > 0 ? .orange : MF.primaryTextColor.opacity(0.2)))
                            .offset(y: -1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(MF.glassBackground())
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 0)
        }
        .sheet(isPresented: $showClassCheckIn) {
            ClassCheckInSheet(onSave: {
                refreshTrigger = UUID()
            })
            .environmentObject(store)
        }
        .id(refreshTrigger)
    }
}

// MARK: - Class Check-In Sheet
struct ClassCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    var onSave: () -> Void = {}
    
    @State private var selectedClass: String = ""
    @State private var understanding: Double = 5
    @State private var energy: Double = 5
    @State private var notes: String = ""
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Today's Class") {
                    Picker("Class", selection: $selectedClass) {
                        ForEach(studentClasses, id: \.name) { classItem in
                            Text(classItem.name).tag(classItem.name)
                        }
                    }
                }
                
                Section("How did it go?") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Understanding")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $understanding, in: 1...10, step: 1)
                            Text("High")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Energy / Engagement")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $energy, in: 1...10, step: 1)
                            Text("High")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Notes for Future You") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Class Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCheckIn()
                    }
                    .disabled(selectedClass.isEmpty)
                }
            }
            .onAppear {
                if selectedClass.isEmpty, let firstClass = studentClasses.first {
                    selectedClass = firstClass.name
                }
            }
        }
    }
    
    private func saveCheckIn() {
        // Save the check-in to DataStore
        guard !selectedClass.isEmpty else { return }
        
        // Find the class ID
        let classId = studentClasses.first(where: { $0.name == selectedClass })?.id
        
        store.upsertClassCheckIn(
            date: Date(),
            classId: classId,
            className: selectedClass,
            understandingScore: Int(understanding),
            energyScore: Int(energy),
            notes: notes
        )
        
        // Trigger refresh callback
        onSave()
        
        dismiss()
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let store = DataStore(modelContext: controller.container.mainContext, seed: true)
    return NavigationStack { 
        MindView()
            .environmentObject(store)
    }
}
