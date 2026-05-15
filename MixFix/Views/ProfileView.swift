//
//  ProfileView.swift
//  MixFix
//

import SwiftUI
import SwiftData
import UserNotifications
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var appSession: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    @State private var showJournalEntry = false
    @State private var showJournalHistory = false
    @State private var showHelpSheet = false
    @State private var showDeleteAccountAlert = false
    @State private var showTodayMoods = false
    @State private var showBreathingExercise = false
    @State private var showMoodChart = false
    @State private var shootingStars: [ShootingStar] = []
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("userName") private var userName: String = "User"
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
        case "blue": return Color(hex: "#5B9BD5")
        case "lavender": return Color(hex: "#9B8FC4")
        case "pink": return Color(hex: "#E89AC7")
        case "green": return Color(hex: "#6BBF59")
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
        // Use the same unified logic's mood vs profile behavior but expose just the mood-based colors
        // When mood colors are disabled or no recent mood, we fall back to headerGradient
        guard moodColorsEnabled, hasRecentMood, let latestMood = store.moods.first?.mood else {
            return headerGradient
        }
        // Recreate just the mood-based branch from MFHeaderStyle so the dial matches the header
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
        default: return headerGradient
        }
    }
    
    private var todayMoods: [MoodEntry] {
        let calendar = Calendar.current
        return store.moods.filter { calendar.isDateInToday($0.date) }
            .sorted { $0.date > $1.date } // Most recent first
    }
    
    private var weeklyAssignments: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return store.events.filter { event in
            event.category == "Assignments" &&
            !event.isCompleted &&
            event.start >= today &&
            event.start < weekEnd
        }
    }
    
    private var weeklyAssessments: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        return store.events.filter { event in
            (event.category == "Tests" || event.category == "Exams") &&
            event.start >= today &&
            event.start < weekEnd
        }
    }
    
    private var journalPrompt: String {
        guard let latestMood = store.moods.first?.mood else {
            return "What's one thing that stressed you today? How did you respond?"
        }
        switch latestMood {
        case 1: // Angry
            return "Why are you angry? Is the thing you're angry over worth this energy? Why or why not?"
        case 2: // Sad
            return "What's making you feel sad right now? What would help you feel a little better?"
        case 3: // Overwhelmed
            return "What's overwhelming you today? Can you break it down into smaller, manageable steps?"
        case 4: // Drained
            return "What's draining your energy? What do you need to recharge and feel like yourself again?"
        case 5: // Anxious
            return "What's making you anxious? What's within your control right now, and what isn't?"
        case 6: // Annoyed
            return "What's bothering you? Is this something you can change, or do you need to let it go?"
        case 7: // Okay
            return "How are you really feeling? Is there anything you need to process or let go of?"
        case 8: // Good
            return "What went well today? What are you grateful for right now?"
        case 9: // Amazing
            return "What made today so amazing? How can you carry this energy forward?"
        default:
            return "What's one thing that stressed you today? How did you respond?"
        }
    }
    
    var body: some View {
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
            
            // Settings button overlay
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .blur(radius: 8)
                            
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                Spacer()
            }
            .zIndex(100)
            
            // Main content with gradient header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Streak Tracker
                    StreakCard(moods: store.moods, events: store.events)
                        .padding(.horizontal, 24)
                        .padding(.top, 80)
                        .padding(.bottom, 8)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    
                    // Three-column card grid
                    HStack(spacing: 12) {
                        // Mood Log Card
                        Button {
                            showTodayMoods = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                    Spacer()
                                    Text("\(todayMoods.count)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(MF.primaryTextColor)
                                }
                                
                                Text("Mood Log")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MF.primaryTextColor)
                                
                                Text("Entries today")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(MF.primaryTextColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 120)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                                    .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Journal Entry Card
                        Button {
                            showJournalEntry = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.title3)
                                        .foregroundStyle(.purple)
                                    Spacer()
                                }
                                
                                Text("Journal")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MF.isNightTime ? .white : MF.primaryTextColor)
                                
                                Text("Reflect today")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(MF.isNightTime ? .white.opacity(0.7) : MF.primaryTextColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 120)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        MF.isNightTime ?
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            LinearGradient(
                                                colors: [Color.white, Color.white],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(MF.isNightTime ? 0.3 : 0.2), lineWidth: 1)
                            )
                        }
                        
                        // Breathing Break Card
                        Button {
                            showBreathingExercise = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "wind")
                                        .font(.title3)
                                        .foregroundStyle(Color(hex: "#5B9BD5"))
                                    Spacer()
                                }
                                
                                Text("Breathe")
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MF.primaryTextColor)
                                
                                Text("1 minute")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(MF.primaryTextColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 120)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                                    .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#5B9BD5").opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Weekly Overview - Two-column grid
                    HStack(spacing: 12) {
                        // Weekly Assignments Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text("\(weeklyAssignments.count)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(MF.primaryTextColor)
                            }
                            
                            Text("Assignments")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(MF.primaryTextColor)
                            
                            Text("Due this week")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(MF.primaryTextColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                                .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                        
                        // Weekly Assessments Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "graduationcap.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                                Spacer()
                                Text("\(weeklyAssessments.count)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(MF.primaryTextColor)
                            }
                            
                            Text("Assessments")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(MF.primaryTextColor)
                            
                            Text("This week")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(MF.primaryTextColor.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 120)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MF.isNightTime ? Color.white.opacity(0.08) : Color.white)
                                .shadow(color: Color.black.opacity(MF.isNightTime ? 0.3 : 0.06), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 100)
            }
            .gradientHeader(title: "Profile", subtitle: "Your personal dashboard", gradient: headerGradient)
        }
        .sheet(isPresented: $showSettings) {
            ProfileSettingsView()
                .environmentObject(store)
                .environmentObject(appSession)
                .environmentObject(userSession)
        }
        .sheet(isPresented: $showJournalEntry) {
            JournalEntryView(prompt: journalPrompt)
                .environmentObject(store)
        }
        .sheet(isPresented: $showJournalHistory) {
            JournalPasswordGateView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            BreathingExerciseView()
        }
        .sheet(isPresented: $showMoodChart) {
            MonthlyMoodChartView(moods: store.moods)
        }
        .sheet(isPresented: $showTodayMoods) {
            TodayMoodsView(moods: store.moods)
        }
        .onAppear {
            if MF.isNightTime {
                startShootingStarAnimation()
            }
        }
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
}

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var appSession: AppSession
    @EnvironmentObject var userSession: UserSession
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedEntry: JournalEntry?
    @State private var showJournalHistory = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("gradeLevel") private var gradeLevel: String = ""
    @AppStorage("studentType") private var studentType: String = "highschool"
    @AppStorage("moodColorsEnabled") private var moodColorsEnabled: Bool = true
    @AppStorage("studentProfileData") private var studentProfileData: Data = Data()
    @AppStorage("calmingMusicGenre") private var calmingMusicGenre: String = "Nature Sounds"
    @AppStorage("favoriteGenresData") private var favoriteGenresData: Data = Data()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCompletedStudentOnboarding") private var hasCompletedStudentOnboarding: Bool = false
    @AppStorage("hasCompletedExamOnboarding") private var hasCompletedExamOnboarding: Bool = false
    @State private var showClassManagement = false
    @State private var selectedMode: AppMode = .student
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("preferredReelTopics") private var preferredReelTopicsData: Data = Data()
    @AppStorage("journalPasswordEnabled") private var journalPasswordEnabled: Bool = false
    @AppStorage("journalPassword") private var journalPassword: String = ""
    @AppStorage("isGuestUser") private var isGuestUser: Bool = false
    @AppStorage("timerFocusLockEnabled") private var timerFocusLockEnabled: Bool = false
    @AppStorage("timerLockPIN") private var timerLockPIN: String = ""
    @State private var showPasswordPrompt = false
    @State private var enteredPassword = ""
    @State private var showPasswordError = false
    @State private var showChangeNameSheet = false
    @State private var showChangePasswordSheet = false
    @State private var showTimerPINSetup = false
    @State private var showSavedReels = false
    @State private var showReelPreferences = false
    @State private var newTimerPIN: String = ""
    @State private var confirmTimerPIN: String = ""
    @State private var timerPINErrorMessage: String = ""
    @State private var showDeleteAccountAlert = false
    @State private var isLoading = false
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    private var displayEmail: String {
        // First, prefer the email from the reactive UserSession profile
        if let sessionEmail = userSession.currentUser?.email, !sessionEmail.isEmpty {
            return sessionEmail
        }
        // Fallback: AppStorage email if available
        if !userEmail.isEmpty {
            return userEmail
        }
        // Last resort: FirebaseManager's current user
        return FirebaseManager.shared.currentUser?.email ?? "No email"
    }
    
    private var displayName: String {
        // Prefer an explicit name from UserSession profile or AppStorage
        if let sessionName = userSession.currentUser?.name, !sessionName.isEmpty {
            return sessionName
        }
        if !userName.isEmpty {
            return userName
        }
        // Otherwise, derive from the best-known email (session/AppStorage/Firebase)
        let email = displayEmail
        if let atIndex = email.firstIndex(of: "@") {
            let username = String(email[..<atIndex])
            // Extract first name (before any dot, underscore, or number)
            let firstName = username.components(separatedBy: CharacterSet(charactersIn: "._0123456789")).first ?? username
            return firstName.capitalized
        }
        return "User"
    }
    
    private let availableColors: [(name: String, gradient: LinearGradient)] = [
        ("sage", LinearGradient(colors: [Color(hex: "#B5D99C"), Color(hex: "#5F8052")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("terracotta", LinearGradient(colors: [Color(hex: "#E89580"), Color(hex: "#A03C2E")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("sand", LinearGradient(colors: [Color(hex: "#F0DDB8"), Color(hex: "#B89968")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("clay", LinearGradient(colors: [Color(hex: "#C99A6E"), Color(hex: "#6B4423")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("moss", LinearGradient(colors: [Color(hex: "#A8B968"), Color(hex: "#4A5A1F")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("stone", LinearGradient(colors: [Color(hex: "#B8B8B8"), Color(hex: "#5A5A5A")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("olive", LinearGradient(colors: [Color(hex: "#C4BC88"), Color(hex: "#6B6B3C")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("cream", LinearGradient(colors: [Color(hex: "#FFF5E1"), Color(hex: "#C4A57B")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("slate", LinearGradient(colors: [Color(hex: "#8FA3B0"), Color(hex: "#3A4A5A")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("taupe", LinearGradient(colors: [Color(hex: "#D4A889"), Color(hex: "#7A5239")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("lavender", LinearGradient(colors: [Color(hex: "#D4C4F0"), Color(hex: "#7B5FA0")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("periwinkle", LinearGradient(colors: [Color(hex: "#BCC8F0"), Color(hex: "#5968B0")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("amethyst", LinearGradient(colors: [Color(hex: "#C48FD8"), Color(hex: "#5D2E6F")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("sky", LinearGradient(colors: [Color(hex: "#B3E5FC"), Color(hex: "#3D8DB8")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("ocean", LinearGradient(colors: [Color(hex: "#7DB8E8"), Color(hex: "#2A5A98")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("indigo", LinearGradient(colors: [Color(hex: "#8B9FEB"), Color(hex: "#2A3F85")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("rose", LinearGradient(colors: [Color(hex: "#FFC8D8"), Color(hex: "#D8537F")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("blush", LinearGradient(colors: [Color(hex: "#FFD8E1"), Color(hex: "#FF6F83")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("coral", LinearGradient(colors: [Color(hex: "#FFB8A0"), Color(hex: "#FF4F41")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("peach", LinearGradient(colors: [Color(hex: "#FFCBB1"), Color(hex: "#FF6A45")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("tangerine", LinearGradient(colors: [Color(hex: "#FFD76D"), Color(hex: "#FF7800")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("crimson", LinearGradient(colors: [Color(hex: "#FF9393"), Color(hex: "#B31F1F")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("ruby", LinearGradient(colors: [Color(hex: "#FF7370"), Color(hex: "#A61818")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("mint", LinearGradient(colors: [Color(hex: "#98D8C8"), Color(hex: "#2E8B7A")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("burgundy", LinearGradient(colors: [Color(hex: "#B8697D"), Color(hex: "#6B2737")], startPoint: .topLeading, endPoint: .bottomTrailing))
    ]
    
    private var selectedGradient: LinearGradient {
        availableColors.first(where: { $0.name == profileCircleColorName })?.gradient ?? 
        LinearGradient(colors: [Color(hex: "#5B9BD5"), Color(hex: "#3A7BC8")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var studentProfile: StudentProfile {
        guard let decoded = try? JSONDecoder().decode(StudentProfile.self, from: studentProfileData) else {
            return .default
        }
        return decoded
    }
    
    private var studentProfileSummary: String {
        let profile = studentProfile
        return "Average: \(profile.gradeAverage.rawValue.components(separatedBy: " ").first ?? "B")"
    }
    
    private var accountSection: some View {
        Section("Account") {
            HStack {
                Circle()
                    .fill(selectedGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(displayName.prefix(1).uppercased()))
                            .font(.headline)
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.body)
                    Text(displayEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !userPhone.isEmpty {
                        Text(userPhone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                showChangeNameSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(.blue)
                    Text("Change Name")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showChangePasswordSheet = true
            } label: {
                HStack {
                    Image(systemName: "lock.rotation")
                        .foregroundStyle(.blue)
                    Text("Change Password")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var customizeProfileSection: some View {
        Section("Customize your Profile") {
            Toggle("Mood Colors", isOn: $moodColorsEnabled)
            
            // Journal History
            Button {
                showJournalHistory = true
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Journals")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(store.journalEntries.count) entries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Saved Reels
            Button {
                showSavedReels = true
            } label: {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved Tips")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Your bookmarked reels")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Reel Preferences
            Button {
                showReelPreferences = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reel Preferences")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Customize your feed topics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(availableColors, id: \.name) { colorOption in
                    Button {
                        withAnimation {
                            profileCircleColorName = colorOption.name
                        }
                    } label: {
                        Circle()
                            .fill(colorOption.gradient)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .opacity(profileCircleColorName == colorOption.name ? 1 : 0)
                            )
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                customizeProfileSection
            
            Section {
                Button {
                    showClassManagement = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#4CAF50"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Classes")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(studentClasses.isEmpty ? "No classes added" : "\(studentClasses.count) class\(studentClasses.count == 1 ? "" : "es")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Academic")
            } footer: {
                Text("Manage your classes and professors for better grade tracking")
            }

            Section("Privacy") {
                Toggle(isOn: Binding(
                    get: { journalPasswordEnabled },
                    set: { newValue in
                        // If turning OFF and password exists, require authentication
                        if !newValue && !journalPassword.isEmpty && journalPasswordEnabled {
                            showPasswordPrompt = true
                        } else {
                            // Turning ON or no password set - allow immediately
                            journalPasswordEnabled = newValue
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Journal Password")
                        Text("Require password to view journal entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Toggle(isOn: .constant(true)) {
                    Text("Personalized suggestions")
                }
                Toggle(isOn: .constant(false)) {
                    Text("Share anonymized analytics")
                }
                Button("Export Data") {}
                Button("Delete Account") {
                    showDeleteAccountAlert = true
                }
                .foregroundStyle(.red)
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your MixFix account and all cloud data associated with it. Local data on this device will also be cleared. This action cannot be undone.")
            }
            
            Section {
                Toggle(isOn: $timerFocusLockEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timer Focus Lock")
                        Text("Lock the app to the study timer until the session ends or you enter your PIN.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button("Set 4-Digit Timer PIN") {
                    showTimerPINSetup = true
                }
            } header: {
                Text("Focus Lock")
            } footer: {
                Text("Lock-in to your StudySession. Unlock to access phone's other functions")
            }
            
            Section {
                Button {
                    logout()
                } label: {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .foregroundStyle(.red)
            }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkNotificationPermission()
            }
            .sheet(isPresented: $showJournalHistory) {
                JournalPasswordGateView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showClassManagement) {
                ClassManagementView(studentClassesData: $studentClassesData)
            }
            .sheet(isPresented: $showChangeNameSheet) {
                ChangeNameSheet(userName: $userName)
            }
            .sheet(isPresented: $showChangePasswordSheet) {
                ChangePasswordSheet()
            }
            .sheet(isPresented: $showSavedReels) {
                SavedReelsView(userId: store.userId)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showReelPreferences) {
                ReelPreferencesEditor()
            }
            .alert("Enter Password", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $enteredPassword)
                Button("Cancel", role: .cancel) {
                    enteredPassword = ""
                    showPasswordError = false
                }
                Button("Confirm") {
                    verifyPasswordToDisable()
                }
            } message: {
                Text("Enter your journal password to disable password protection")
            }
            .alert("Incorrect Password", isPresented: $showPasswordError) {
                Button("OK") {
                    showPasswordError = false
                    showPasswordPrompt = true
                }
            } message: {
                Text("The password you entered is incorrect. Please try again.")
            }
            .sheet(isPresented: $showTimerPINSetup) {
                NavigationStack {
                    Form {
                        Section("Timer PIN") {
                            SecureField("New 4-digit PIN", text: $newTimerPIN)
                                .keyboardType(.numberPad)
                            SecureField("Confirm PIN", text: $confirmTimerPIN)
                                .keyboardType(.numberPad)
                            if !timerPINErrorMessage.isEmpty {
                                Text(timerPINErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .navigationTitle("Set Timer PIN")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showTimerPINSetup = false
                                newTimerPIN = ""
                                confirmTimerPIN = ""
                                timerPINErrorMessage = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveTimerPIN()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func verifyPasswordToDisable() {
        if enteredPassword == journalPassword {
            // Password correct - disable protection
            journalPasswordEnabled = false
            enteredPassword = ""
            showPasswordError = false
        } else {
            // Password incorrect - show error
            enteredPassword = ""
            showPasswordError = true
        }
    }
    
    // MARK: - Study Mode Handling
    private func handleStudyModeChange(newMode: AppMode) {
        let currentMode = appSession.mode
        
        // If switching into Exam mode without exam onboarding, show mode-specific onboarding
        if newMode == .exam && !hasCompletedExamOnboarding {
            appSession.mode = .exam
            UserDefaults.standard.set("exam", forKey: "studyMode")
            selectedMode = currentMode
            // Don't reset hasCompletedOnboarding - user has already completed general onboarding
            // The OnboardingView will detect the mode change and show exam-specific screens
            return
        }
        
        // If switching into Student mode without student onboarding, show mode-specific onboarding
        if newMode == .student && !hasCompletedStudentOnboarding {
            appSession.mode = .student
            UserDefaults.standard.set("student", forKey: "studyMode")
            selectedMode = currentMode
            // Don't reset hasCompletedOnboarding - user has already completed general onboarding
            // The OnboardingView will detect the mode change and show student-specific screens
            return
        }
        
        // Otherwise allow immediate mode switch and persist choice
        appSession.mode = newMode
        let modeString = newMode == .exam ? "exam" : "student"
        UserDefaults.standard.set(modeString, forKey: "studyMode")
    }
    
    private func saveTimerPIN() {
        // Ensure PIN is exactly 4 digits
        let isNumeric = newTimerPIN.count == 4 && newTimerPIN.allSatisfy { $0.isNumber }
        guard isNumeric else {
            timerPINErrorMessage = "PIN must be exactly 4 digits."
            return
        }
        guard newTimerPIN == confirmTimerPIN else {
            timerPINErrorMessage = "PINs do not match."
            return
        }
        timerLockPIN = newTimerPIN
        timerFocusLockEnabled = true
        newTimerPIN = ""
        confirmTimerPIN = ""
        timerPINErrorMessage = ""
        showTimerPINSetup = false
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func logout() {
        Task {
            do {
                // 1. SYNC ALL DATA TO FIRESTORE FIRST (critical to prevent data loss!)
                print("💾 Syncing all data to Firestore before logout...")
                await MainActor.run {
                    isLoading = true
                }
                
                // Collect all user settings to sync
                var settings: [String: Any] = [:]
                
                // User identity
                settings["userName"] = userName
                settings["userEmail"] = userEmail
                settings["userPhone"] = userPhone
                settings["gradeLevel"] = gradeLevel
                settings["studentType"] = studentType
                
                // UI preferences
                settings["profileCircleColor"] = profileCircleColorName
                settings["moodColorsEnabled"] = moodColorsEnabled
                
                // Timer lock (enabled state only, not PIN for security)
                settings["timerFocusLockEnabled"] = timerFocusLockEnabled
                
                // Music preferences
                settings["calmingMusicGenre"] = calmingMusicGenre
                
                // Base64 encode Data objects
                if !studentClassesData.isEmpty {
                    settings["studentClassesData"] = studentClassesData.base64EncodedString()
                }
                if !preferredReelTopicsData.isEmpty {
                    settings["preferredReelTopicsData"] = preferredReelTopicsData.base64EncodedString()
                }
                if !favoriteGenresData.isEmpty {
                    settings["favoriteGenresData"] = favoriteGenresData.base64EncodedString()
                }
                if !studentProfileData.isEmpty {
                    settings["studentProfileData"] = studentProfileData.base64EncodedString()
                }
                
                // Note: Intentionally NOT syncing security-sensitive data:
                // - journalPassword (user privacy/security)
                // - timerLockPIN (user privacy/security)
                
                // Fetch all SwiftData objects for the current user
                let currentUserId = store.userId
                let eventDescriptor = FetchDescriptor<CalendarEventSD>(
                    predicate: #Predicate { $0.userId == currentUserId }
                )
                let moodDescriptor = FetchDescriptor<MoodEntrySD>(
                    predicate: #Predicate { $0.userId == currentUserId }
                )
                let journalDescriptor = FetchDescriptor<JournalEntrySD>(
                    predicate: #Predicate { $0.userId == currentUserId }
                )
                
                guard let modelContext = DataStoreAccessor.shared.modelContext else {
                    throw NSError(domain: "DataStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
                }
                
                let events = (try? modelContext.fetch(eventDescriptor)) ?? []
                let moods = (try? modelContext.fetch(moodDescriptor)) ?? []
                let journals = (try? modelContext.fetch(journalDescriptor)) ?? []
                
                print("💾 Found \(events.count) events, \(moods.count) moods, \(journals.count) journals to sync")
                
                // Sync all user data to Firestore
                try await FirestoreService.shared.syncAllUserData(
                    events: events,
                    moods: moods,
                    journals: journals
                )
                
                // Sync user settings
                try await FirestoreService.shared.syncUserSettings(settings)
                
                print("✅ All data synced to Firestore successfully")
                
                // 2. Now safe to clear local data/state
                await MainActor.run {
                    store.clearAllData()
                    userSession.clearUserData()
                    clearUserAppStorage()
                    
                    isGuestUser = false
                    hasCompletedOnboarding = true
                    isLoading = false
                    dismiss()
                }
                
                // 3. Sign out from Firebase
                try FirebaseManager.shared.signOut()
                print("✅ Logout complete")
            } catch {
                print("❌ Error during logout: \(error)")
                await MainActor.run {
                    isLoading = false
                    // Still allow logout even if sync fails - better than being stuck
                    store.clearAllData()
                    userSession.clearUserData()
                    clearUserAppStorage()
                    isGuestUser = false
                    hasCompletedOnboarding = true
                    dismiss()
                }
                try? FirebaseManager.shared.signOut()
            }
        }
    }
    
    private func clearUserAppStorage() {
        // Clear user identity
        userName = ""
        userEmail = ""
        userPhone = ""
        
        // Clear user preferences
        profileCircleColorName = "blue"
        moodColorsEnabled = true
        
        // Clear student data
        studentProfileData = Data()
        studentClassesData = Data()
        
        // Clear reel preferences
        preferredReelTopicsData = Data()
        
        // Clear music preferences
        calmingMusicGenre = "Nature Sounds"
        favoriteGenresData = Data()
        
        // Clear journal security
        journalPasswordEnabled = false
        journalPassword = ""
        
        // Don't clear onboarding flags - let the new user skip onboarding
        // hasCompletedOnboarding stays true
        // hasCompletedStudentOnboarding stays as is
        // hasCompletedExamOnboarding stays as is
        
        print("🧹 Cleared all user-specific AppStorage values")
    }

    private func deleteAccount() {
        Task {
            do {
                // 1. Clear all local data/state for current user
                await MainActor.run {
                    store.clearAllData()
                    hasCompletedOnboarding = false
                }

                // 2. Delete the Firebase user account (this also signs them out)
                if let user = Auth.auth().currentUser {
                    try await user.delete()
                }
                
                // 3. Clear user session and guest flag to show auth screen
                await MainActor.run {
                    isGuestUser = false
                    userSession.clearUserData()
                    dismiss()
                }
            } catch {
                print("❌ Error deleting account: \(error)")
            }
        }
    }
}

// MARK: - Music Preferences View
struct MusicPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var calmingMusicGenre: String
    
    private let musicGenres = [
        ("Nature Sounds", "🌊", "Ocean waves, rain, forest"),
        ("Lo-fi Beats", "🎵", "Chill hip-hop instrumentals"),
        ("Classical", "🎻", "Peaceful orchestral music"),
        ("Ambient", "🌌", "Atmospheric soundscapes"),
        ("Piano", "🎹", "Gentle piano melodies"),
        ("Jazz", "🎷", "Smooth jazz vibes"),
        ("Meditation", "🧘", "Guided meditation sounds"),
        ("White Noise", "⚪", "Pure focus sounds")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(musicGenres, id: \.0) { genre in
                        Button {
                            calmingMusicGenre = genre.0
                        } label: {
                         HStack(spacing: 16) {
                                Text(genre.1)
                                    .font(.system(size: 40))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(genre.0)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(genre.2)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if calmingMusicGenre == genre.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "#2196F3"))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Choose Your Calming Sound")
                } footer: {
                    Text("This will be played during Sound Escape sessions to help you relax and reset")
                }
            }
            .navigationTitle("Music Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Journal History View
struct JournalHistoryView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: JournalEntry?
    
    var body: some View {
        NavigationStack {
            List {
                if store.journalEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No journal entries yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Start journaling to see your entries here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(store.journalEntries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title ?? "Untitled")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(entry.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                Text(entry.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            store.deleteJournalEntry(store.journalEntries[index])
                        }
                    }
                }
            }
            .navigationTitle("My Journals")
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
            .sheet(item: $selectedEntry) { entry in
                JournalDetailView(entry: entry)
            }
        }
    }
}

// MARK: - Journal Detail View
struct JournalDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    if let title = entry.title {
                        Text(title)
                            .font(.title.bold())
                    }
                    
                    // Date
                    Text(entry.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Content
                    Text(entry.content)
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Badge Customization View
struct BadgeCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var studentProfileData: Data
    
    @State private var profile: StudentProfile
    
    init(studentProfileData: Binding<Data>) {
        self._studentProfileData = studentProfileData
        
        if let decoded = try? JSONDecoder().decode(StudentProfile.self, from: studentProfileData.wrappedValue) {
            self._profile = State(initialValue: decoded)
        } else {
            self._profile = State(initialValue: .default)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personalized Achievement System")
                            .font(.headline)
                        Text("Answer these questions to customize your badge rewards. Badges will be awarded when you exceed your personal average, encouraging continuous improvement!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("What's your current grade average?") {
                    Picker("Grade Average", selection: $profile.gradeAverage) {
                        ForEach(StudentProfile.GradeAverage.allCases, id: \.self) { average in
                            Text(average.rawValue).tag(average)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("How do you prefer to work?") {
                    Picker("Work Style", selection: $profile.workStyle) {
                        ForEach(StudentProfile.WorkStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("What environment helps you focus best?") {
                    Picker("Study Environment", selection: $profile.studyEnvironment) {
                        ForEach(StudentProfile.StudyEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("How long do you typically study?") {
                    Picker("Study Duration", selection: $profile.studyDuration) {
                        ForEach(StudentProfile.StudyDuration.allCases, id: \.self) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("How motivated are you to improve?") {
                    Picker("Motivation Level", selection: $profile.motivationLevel) {
                        ForEach(StudentProfile.MotivationLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Badge Thresholds")
                            .font(.headline)
                        
                        BadgeThresholdRow(
                            badge: .platinum,
                            description: "15+ points above your average",
                            example: exampleGrade(for: 15)
                        )
                        
                        BadgeThresholdRow(
                            badge: .gold,
                            description: "10-14 points above your average",
                            example: exampleGrade(for: 10)
                        )
                        
                        BadgeThresholdRow(
                            badge: .silver,
                            description: "5-9 points above your average",
                            example: exampleGrade(for: 5)
                        )
                        
                        BadgeThresholdRow(
                            badge: .bronze,
                            description: "2-4 points above your average",
                            example: exampleGrade(for: 2)
                        )
                    }
                } header: {
                    Text("Your Personalized Rewards")
                } footer: {
                    Text("Based on your \(profile.gradeAverage.rawValue) average, you'll earn badges for grades that exceed your typical performance. Keep improving to unlock milestone rewards!")
                }
            }
            .navigationTitle("Badge Customization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exampleGrade(for improvement: Double) -> String {
        let targetGrade = profile.gradeAverage.numericValue + improvement
        if targetGrade >= 97 { return "A+" }
        if targetGrade >= 93 { return "A" }
        if targetGrade >= 90 { return "A-" }
        if targetGrade >= 87 { return "B+" }
        if targetGrade >= 83 { return "B" }
        if targetGrade >= 80 { return "B-" }
        if targetGrade >= 77 { return "C+" }
        if targetGrade >= 73 { return "C" }
        return "C-"
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            studentProfileData = encoded
        }
    }
}

// MARK: - Badge Threshold Row
struct BadgeThresholdRow: View {
    let badge: AchievementBadge
    let description: String
    let example: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: badge.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(badge.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Example: \(example)")
                    .font(.caption2)
                    .foregroundStyle(badge.color)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Class Management View
struct ClassManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: DataStore
    @Binding var studentClassesData: Data
    @State private var classes: [StudentClass] = []
    @State private var showAddClass = false
    @State private var showEditClass = false
    @State private var editingClass: StudentClass?
    @State private var newClassName = ""
    @State private var newTeacherName = ""
    @State private var selectedColor = "#4CAF50"
    @State private var showCustomColorPicker = false
    @State private var customColor: Color = Color(hex: "#4CAF50")
    @AppStorage("classSchedulesData") private var classSchedulesData: Data = Data()
    @State private var classSchedules: [UUID: ClassScheduleInfo] = [:]
    @State private var selectedDays: Set<String> = []
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    private let classColors = [
        "#4CAF50", "#2196F3", "#FF9800", "#9C27B0",
        "#F44336", "#00BCD4", "#FFEB3B", "#E91E63",
        "#FF6B6B", "#4ECDC4", "#AA96DA", "#A8D8EA"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                if classes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Classes Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add your classes to track grades by subject")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(classes) { classItem in
                        Button {
                            editingClass = classItem
                            showEditClass = true
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: classItem.color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(classItem.name.prefix(1)))
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(classItem.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let teacher = classItem.teacher, !teacher.isEmpty {
                                        Text(teacher)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let schedule = classSchedules[classItem.id] {
                                        Text(formatSchedule(schedule))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteClass)
                }
            }
            .navigationTitle("My Classes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddClass = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadClasses()
                loadSchedules()
                // Sync all existing classes to calendar
                syncAllClassesToCalendar()
            }
            .sheet(isPresented: $showAddClass) {
                NavigationStack {
                    Form {
                        Section("Class Information") {
                            TextField("Class Name", text: $newClassName)
                            TextField("Professor/Teacher (Optional)", text: $newTeacherName)
                        }
                        
                        Section("Color") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                                ForEach(classColors, id: \.self) { color in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedColor = color
                                            showCustomColorPicker = false
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 50, height: 50)
                                                .shadow(color: Color(hex: color).opacity(0.4), radius: 6, x: 0, y: 3)
                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                            
                                            // Selection indicator
                                            if selectedColor == color {
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: 4)
                                                    .frame(width: 58, height: 58)
                                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 22, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        }
                                        .scaleEffect(selectedColor == color ? 1.05 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Custom color picker button
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showCustomColorPicker = true
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                            .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        
                                        Image(systemName: "paintpalette.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                        
                                        // Selection indicator
                                        if showCustomColorPicker {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 4)
                                                .frame(width: 58, height: 58)
                                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .scaleEffect(showCustomColorPicker ? 1.05 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                        }
                        .sheet(isPresented: $showCustomColorPicker) {
                            NavigationStack {
                                VStack(spacing: 24) {
                                    // Large color preview
                                    Circle()
                                        .fill(customColor)
                                        .frame(width: 120, height: 120)
                                        .shadow(color: customColor.opacity(0.5), radius: 20, x: 0, y: 10)
                                        .padding(.top, 24)
                                    
                                    // ColorPicker with labels hidden to show picker directly
                                    ColorPicker("", selection: $customColor, supportsOpacity: false)
                                        .labelsHidden()
                                        .padding(.horizontal)
                                        .onChange(of: customColor) { _, newColor in
                                            selectedColor = newColor.toHex() ?? "#4CAF50"
                                        }
                                    
                                    Spacer()
                                }
                                .navigationTitle("Custom Color")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            showCustomColorPicker = false
                                        }
                                    }
                                }
                            }
                            .presentationDetents([.large])
                        }
                        
                        Section("Schedule (Optional)") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Days of Week")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                        Button {
                                            if selectedDays.contains(day) {
                                                selectedDays.remove(day)
                                            } else {
                                                selectedDays.insert(day)
                                            }
                                        } label: {
                                            Text(day)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                                                .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            
                            FiveMinuteTimePicker(date: $startTime, label: "Start Time")
                                .onChange(of: startTime) { _, newStartTime in
                                    // Automatically set end time to 1 hour after start time
                                    endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) ?? newStartTime
                                }
                            FiveMinuteTimePicker(date: $endTime, label: "End Time")
                        }
                    }
                    .navigationTitle("Add Class")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddClass = false
                                resetForm()
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Button("Add") {
                                addClass()
                            }
                            .disabled(newClassName.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditClass) {
                if let classToEdit = editingClass {
                    EditClassSheet(
                        classItem: classToEdit,
                        schedule: classSchedules[classToEdit.id],
                        onSave: { updatedClass, updatedSchedule in
                            if let index = classes.firstIndex(where: { $0.id == updatedClass.id }) {
                                classes[index] = updatedClass
                                if let schedule = updatedSchedule {
                                    classSchedules[updatedClass.id] = schedule
                                    // Remove old calendar events for this class and recreate with updated schedule
                                    let existingEvents = store.events.filter { event in
                                        event.category == "Classes" && event.title == updatedClass.name
                                    }
                                    for event in existingEvents {
                                        store.deleteEvent(event)
                                    }
                                    createRecurringClassEvents(for: updatedClass, schedule: schedule)
                                } else {
                                    classSchedules.removeValue(forKey: updatedClass.id)
                                }
                                saveClasses()
                                saveSchedules()
                            }
                            showEditClass = false
                        }
                    )
                }
            }
        }
    }
    
    private func loadClasses() {
        print("📚 ClassManagementView: Loading classes from AppStorage (\(studentClassesData.count) bytes)")
        if let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) {
            classes = decoded
            print("📚 ClassManagementView: Loaded \(classes.count) classes: \(classes.map { $0.name })")
        } else {
            print("📚 ClassManagementView: No classes found or failed to decode")
        }
    }
    
    private func addClass() {
        let newClass = StudentClass(
            name: newClassName,
            color: selectedColor,
            teacher: newTeacherName.isEmpty ? nil : newTeacherName
        )
        classes.append(newClass)
        
        // Save schedule if days are selected
        if !selectedDays.isEmpty {
            let schedule = ClassScheduleInfo(
                days: selectedDays,
                startTime: startTime,
                endTime: endTime
            )
            classSchedules[newClass.id] = schedule
            saveSchedules()
            
            // Create recurring calendar events for this class
            createRecurringClassEvents(for: newClass, schedule: schedule)
        }
        
        saveClasses()
        showAddClass = false
        resetForm()
    }
    
    private func createRecurringClassEvents(for classItem: StudentClass, schedule: ClassScheduleInfo) {
        let calendar = Calendar.current
        
        // Create events from 1 week ago to 4 months in the future
        // This ensures we have events for the current week even if added mid-week
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        guard let endDate = calendar.date(byAdding: .month, value: 4, to: Date()) else { return }
        
        var currentDate = startDate
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let currentDay = dayNames[weekday - 1]
            
            // Check if class meets on this day
            if schedule.days.contains(currentDay) {
                // Create event for this day with the scheduled time
                let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                if let eventStart = calendar.date(from: dateComponents) {
                    let endTimeComponents = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
                    var endDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    endDateComponents.hour = endTimeComponents.hour
                    endDateComponents.minute = endTimeComponents.minute
                    
                    if let eventEnd = calendar.date(from: endDateComponents) {
                        // Check if event already exists to avoid duplicates
                        let existingEvent = store.events.first { event in
                            event.title == classItem.name &&
                            event.category == "Classes" &&
                            calendar.isDate(event.start, inSameDayAs: eventStart) &&
                            calendar.component(.hour, from: event.start) == calendar.component(.hour, from: eventStart) &&
                            calendar.component(.minute, from: event.start) == calendar.component(.minute, from: eventStart)
                        }
                        
                        if existingEvent == nil {
                            // Add event to DataStore
                            store.addEvent(
                                title: classItem.name,
                                start: eventStart,
                                end: eventEnd,
                                category: "Classes",
                                className: classItem.name
                            )
                        }
                    }
                }
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    private func syncAllClassesToCalendar() {
        // Full resync: remove all existing class events, then recreate from current schedules
        let existingClassEvents = store.events.filter { $0.category == "Classes" }
        for event in existingClassEvents {
            store.deleteEvent(event)
        }
        
        for classItem in classes {
            if let schedule = classSchedules[classItem.id] {
                createRecurringClassEvents(for: classItem, schedule: schedule)
            }
        }
    }
    
    private func deleteClass(at offsets: IndexSet) {
        classes.remove(atOffsets: offsets)
        saveClasses()
    }
    
    private func saveClasses() {
        print("📚 ClassManagementView: Saving \(classes.count) classes: \(classes.map { $0.name })")
        if let encoded = try? JSONEncoder().encode(classes) {
            studentClassesData = encoded
            print("📚 ClassManagementView: Saved \(encoded.count) bytes to AppStorage")
        } else {
            print("📚 ClassManagementView: ❌ Failed to encode classes")
        }
    }
    
    private func loadSchedules() {
        if let decoded = try? JSONDecoder().decode([UUID: ClassScheduleInfo].self, from: classSchedulesData) {
            classSchedules = decoded
        }
    }
    
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(classSchedules) {
            classSchedulesData = encoded
        }
    }
    
    private func formatSchedule(_ schedule: ClassScheduleInfo) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let daysString = schedule.days.sorted().joined(separator: ", ")
        let startString = timeFormatter.string(from: schedule.startTime)
        let endString = timeFormatter.string(from: schedule.endTime)
        return "\(daysString) • \(startString)-\(endString)"
    }
    
    private func resetForm() {
        newClassName = ""
        newTeacherName = ""
        selectedColor = "#4CAF50"
        showCustomColorPicker = false
        customColor = Color(hex: "#4CAF50")
        selectedDays = []
        startTime = Date()
        endTime = Date()
    }
}

// MARK: - Edit Class Sheet
struct EditClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    let classItem: StudentClass
    let schedule: ClassScheduleInfo?
    let onSave: (StudentClass, ClassScheduleInfo?) -> Void
    
    @State private var className: String
    @State private var teacherName: String
    @State private var selectedColor: String
    @State private var showCustomColorPicker = false
    @State private var customColor: Color
    @State private var selectedDays: Set<String>
    @State private var startTime: Date
    @State private var endTime: Date
    
    private let classColors = [
        "#4CAF50", "#2196F3", "#FF9800", "#9C27B0",
        "#F44336", "#00BCD4", "#FFEB3B", "#E91E63",
        "#FF6B6B", "#4ECDC4", "#AA96DA", "#A8D8EA"
    ]
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    init(classItem: StudentClass, schedule: ClassScheduleInfo?, onSave: @escaping (StudentClass, ClassScheduleInfo?) -> Void) {
        self.classItem = classItem
        self.schedule = schedule
        self.onSave = onSave
        
        _className = State(initialValue: classItem.name)
        _teacherName = State(initialValue: classItem.teacher ?? "")
        _selectedColor = State(initialValue: classItem.color)
        _customColor = State(initialValue: Color(hex: classItem.color))
        _selectedDays = State(initialValue: schedule?.days ?? [])
        _startTime = State(initialValue: schedule?.startTime ?? Date())
        _endTime = State(initialValue: schedule?.endTime ?? Date())
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            NavigationStack {
                Form {
                Section("Class Information") {
                    TextField("Class Name", text: $className)
                    TextField("Professor/Teacher (Optional)", text: $teacherName)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(classColors, id: \.self) { color in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = color
                                    showCustomColorPicker = false
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: Color(hex: color).opacity(0.4), radius: 6, x: 0, y: 3)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    
                                    // Selection indicator
                                    if selectedColor == color {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 4)
                                            .frame(width: 58, height: 58)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .scaleEffect(selectedColor == color ? 1.05 : 1.0)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Custom color picker button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCustomColorPicker = true
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                Image(systemName: "paintpalette.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                
                                // Selection indicator
                                if showCustomColorPicker {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 4)
                                        .frame(width: 58, height: 58)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .scaleEffect(showCustomColorPicker ? 1.05 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
                .sheet(isPresented: $showCustomColorPicker) {
                    NavigationStack {
                        VStack(spacing: 24) {
                            // Large color preview
                            Circle()
                                .fill(customColor)
                                .frame(width: 120, height: 120)
                                .shadow(color: customColor.opacity(0.5), radius: 20, x: 0, y: 10)
                                .padding(.top, 24)
                            
                            // ColorPicker with labels hidden to show picker directly
                            ColorPicker("", selection: $customColor, supportsOpacity: false)
                                .labelsHidden()
                                .padding(.horizontal)
                                .onChange(of: customColor) { _, newColor in
                                    selectedColor = newColor.toHex() ?? "#4CAF50"
                                }
                            
                            Spacer()
                        }
                        .navigationTitle("Custom Color")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showCustomColorPicker = false
                                }
                            }
                        }
                    }
                    .presentationDetents([.large])
                }
                
                Section("Schedule") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(daysOfWeek, id: \.self) { day in
                                Button {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                } label: {
                                    Text(day)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedDays.contains(day) ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    FiveMinuteTimePicker(date: $startTime, label: "Start Time")
                        .onChange(of: startTime) { _, newStartTime in
                            // Automatically set end time to 1 hour after start time
                            endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) ?? newStartTime
                        }
                    FiveMinuteTimePicker(date: $endTime, label: "End Time")
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(className.isEmpty)
                }
            }
            }
        }
    }
    
    private func saveChanges() {
        let updatedClass = StudentClass(
            id: classItem.id,
            name: className,
            color: selectedColor,
            teacher: teacherName.isEmpty ? nil : teacherName
        )
        
        let updatedSchedule: ClassScheduleInfo? = selectedDays.isEmpty ? nil : ClassScheduleInfo(
            days: selectedDays,
            startTime: startTime,
            endTime: endTime
        )
        
        onSave(updatedClass, updatedSchedule)
    }
}

// MARK: - Change Name Sheet
struct ChangeNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userName: String
    @State private var newName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter your name", text: $newName)
                        .textContentType(.name)
                } header: {
                    Text("New Name")
                } footer: {
                    Text("This name will be displayed in your profile")
                }
            }
            .navigationTitle("Change Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userName = newName
                        dismiss()
                    }
                    .disabled(newName.isEmpty)
                }
            }
            .onAppear {
                newName = userName
            }
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("Current Password")
                }
                
                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("New Password")
                } footer: {
                    Text("Password must be at least 6 characters")
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        changePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func changePassword() {
        // Validate new password
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await FirebaseManager.shared.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Saved Reels View
struct SavedReelsView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var store: DataStore
    @State private var savedReels: [Reel] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if savedReels.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Saved Tips Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tap the bookmark icon on any reel to save it here")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedReels) { reel in
                                SavedReelCard(reel: reel, userId: userId)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSavedReels()
            }
        }
    }
    
    private func loadSavedReels() async {
        print("💾 SavedReelsView: Loading saved reels for user \(userId)")
        
        // Query for all interactions where saved = true
        let descriptor = FetchDescriptor<UserReelInteractionSD>(
            predicate: #Predicate { interaction in
                interaction.userId == userId && interaction.saved == true
            }
        )
        
        guard let interactions = try? modelContext.fetch(descriptor) else {
            print("💾 SavedReelsView: ❌ Failed to fetch interactions")
            isLoading = false
            return
        }
        
        print("💾 SavedReelsView: Found \(interactions.count) saved interactions")
        
        // Get the reel IDs
        let savedReelIds = interactions.map { $0.reelId }
        print("💾 SavedReelsView: Saved reel IDs: \(savedReelIds)")
        
        // Fetch the actual reels
        let reelDescriptor = FetchDescriptor<ReelSD>()
        guard let allReels = try? modelContext.fetch(reelDescriptor) else {
            print("💾 SavedReelsView: ❌ Failed to fetch reels")
            isLoading = false
            return
        }
        
        print("💾 SavedReelsView: Total reels in database: \(allReels.count)")
        
        // Filter to only saved reels and convert to Reel model
        let filteredReels = allReels
            .filter { savedReelIds.contains($0.id) }
            .map { Reel(from: $0) }
            .sorted { _, _ in false } // Keep original order
        
        print("💾 SavedReelsView: ✅ Loaded \(filteredReels.count) saved reels")
        
        await MainActor.run {
            savedReels = filteredReels
            isLoading = false
        }
    }
}

// MARK: - Saved Reel Card
struct SavedReelCard: View {
    let reel: Reel
    let userId: String
    @Environment(\.modelContext) private var modelContext
    @State private var isSaved = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category badge and unsave button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: reel.type.icon)
                        .font(.caption)
                    Text(reel.type.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: reel.type.gradientColors[0]))
                )
                
                Spacer()
                
                Button {
                    unsaveReel()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
            }
            
            // Title (if exists)
            if let title = reel.textTitle {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            // Body text
            Text(reel.textBody)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
            
            // Action prompt
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color(hex: reel.type.gradientColors[0]))
                Text(reel.actionPrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Source link if available
            if let source = reel.sourceLink {
                HStack {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text(source)
                        .font(.caption2)
                        .italic()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: reel.type.gradientColors[0]).opacity(0.2), lineWidth: 1)
        )
        .opacity(isSaved ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isSaved)
    }
    
    private func unsaveReel() {
        // Find the interaction and update it
        let descriptor = FetchDescriptor<UserReelInteractionSD>(
            predicate: #Predicate { interaction in
                interaction.userId == userId && interaction.reelId == reel.id
            }
        )
        
        guard let interaction = try? modelContext.fetch(descriptor).first else { return }
        
        withAnimation {
            isSaved = false
        }
        
        // Delay the actual removal for smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            interaction.saved = false
            try? modelContext.save()
        }
    }
}

// MARK: - Reel Preferences Editor
struct ReelPreferencesEditor: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredReelTopicsData") private var preferredReelTopicsData: Data = Data()
    @State private var selectedTopics: Set<String> = []
    
    private let availableReelTopics = [
        "study-skills",
        "productivity",
        "memory",
        "focus",
        "motivation",
        "mental-health",
        "burnout",
        "stress",
        "sleep",
        "health",
        "time-management",
        "test-prep",
        "procrastination"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Customize Your Feed")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select topics you're interested in to personalize your study reel content. Choose at least 3 topics.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack(spacing: 12) {
                        ForEach(availableReelTopics, id: \.self) { topic in
                            Button {
                                toggleTopic(topic)
                            } label: {
                                HStack {
                                    Image(systemName: selectedTopics.contains(topic) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedTopics.contains(topic) ? .purple : .secondary)
                                        .font(.title3)
                                    
                                    Text(formatTopicName(topic))
                                        .foregroundStyle(.primary)
                                        .font(.body)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(selectedTopics.contains(topic) ? Color.purple.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("\(selectedTopics.count) topic\(selectedTopics.count == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundStyle(selectedTopics.count >= 3 ? Color.secondary : Color.red)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Reel Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                    }
                    .disabled(selectedTopics.count < 3)
                }
            }
            .onAppear {
                loadCurrentPreferences()
            }
        }
    }
    
    private func formatTopicName(_ topic: String) -> String {
        topic.split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    private func toggleTopic(_ topic: String) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
    }
    
    private func loadCurrentPreferences() {
        guard let decoded = try? JSONDecoder().decode([String].self, from: preferredReelTopicsData) else {
            return
        }
        selectedTopics = Set(decoded)
    }
    
    private func savePreferences() {
        let topicsArray = Array(selectedTopics)
        if let encoded = try? JSONEncoder().encode(topicsArray) {
            preferredReelTopicsData = encoded
        }
        dismiss()
    }
}

    //#Preview {
    //    let controller = PersistenceController(inMemory: true)
    //    let store = DataStore(modelContext: controller.container.mainContext, seed: true)
    //    return NavigationStack {
    //        ProfileView()
    //            .environmentObject(store)
    //    }
    //}
