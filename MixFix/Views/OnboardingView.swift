//
//  OnboardingView.swift
//  MixFix
//
//  Created on 10/29/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var appSession: AppSession
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isGuestUser") private var isGuestUser: Bool = false
    @AppStorage("hasCompletedStudentOnboarding") private var hasCompletedStudentOnboarding = false
    @AppStorage("hasCompletedExamOnboarding") private var hasCompletedExamOnboarding = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("gradeLevel") private var gradeLevel: String = ""
    @AppStorage("studentType") private var studentType: String = "highschool"
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("classSchedulesData") private var classSchedulesData: Data = Data()
    @AppStorage("studyRemindersEnabled") private var studyRemindersEnabled: Bool = true
    @AppStorage("reminderFrequency") private var reminderFrequency: String = "daily"
    @AppStorage("customReminderDays") private var customReminderDaysData: Data = Data()
    @AppStorage("earliestStudyHour") private var earliestStudyHour: Int = 7
    @AppStorage("latestStudyHour") private var latestStudyHour: Int = 22
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "sage"
    @AppStorage("studyMode") private var studyMode: String = "student" // "student" or "exam"
    @AppStorage("googleCalendarConnected") private var googleCalendarConnected: Bool = false
    @AppStorage("googleClassroomConnected") private var googleClassroomConnected: Bool = false
    @AppStorage("preferredReelTopics") private var preferredReelTopicsData: Data = Data()
    
    // Exam-specific settings
    @AppStorage("examType") private var examType: String = ""
    @AppStorage("examDate") private var examDate: Date = Date()
    @AppStorage("examHasStartedStudying") private var examHasStartedStudying: Bool = false
    @AppStorage("examComfortLevel") private var examComfortLevel: Double = 3
    @AppStorage("examDailyStudyHours") private var examDailyStudyHours: Double = 2
    @AppStorage("examNoStudyDays") private var examNoStudyDaysData: Data = Data()
    
    @State private var currentStep = 1
    @State private var tempUserName = ""
    @State private var tempGradeLevel = ""
    @State private var tempStudentType = "highschool"
    @State private var tempClasses: [(classInfo: StudentClass, schedule: String, days: Set<String>, startTime: Date, endTime: Date)] = []
    @State private var showAddClass = false
    @State private var tempRemindersEnabled = true
    @State private var tempReminderFrequency = "daily"
    @State private var tempCustomReminderDays: Set<String> = []
    @State private var tempEarliestHour = 7
    @State private var tempLatestHour = 22
    @State private var notificationPermissionGranted = false
    @State private var hasRequestedNotificationsThisSession = false
    @State private var tempStudyMode: String? = nil
    @State private var tempExamType: String = ""
    @State private var tempExamDate: Date = Date()
    @State private var tempExamHasStartedStudying: Bool = false
    @State private var tempExamComfortLevel: Double = 3
    @State private var tempExamDailyStudyHours: Double = 2
    @State private var tempExamNoStudyDays: Set<String> = []
    @State private var tempSelectedReelTopics: Set<String> = []
    
    private let totalSteps = 8
    
    // Available reel topics for user preference
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
    
    // Computed property for selected theme gradient
    private var selectedThemeGradient: LinearGradient {
        availableColors.first(where: { $0.name == profileCircleColorName })?.gradient ??
        LinearGradient(colors: [Color(hex: "#C8F0A8"), Color(hex: "#8AB86D"), Color(hex: "#4A7C2F")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack {
            // Background gradient - changes based on selected theme
            selectedThemeGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: profileCircleColorName)
            
            VStack(spacing: 0) {
                // Cancel button
                HStack {
                    Spacer()
                    Button {
                        cancelOnboarding()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Progress bar
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Step content
                        Group {
                            switch currentStep {
                            case 0:
                                modeSelectionStep
                            case 1:
                                welcomeStep
                            case 2:
                                classesStep
                            case 3:
                                remindersStep
                            case 4:
                                schedulePreferencesStep
                            case 5:
                                colorCustomizationStep
                            case 6:
                                reelPreferencesStep
                            case 7:
                                notificationsStep
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                    }
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            withAnimation {
                                currentStep -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    
                    Button {
                        handleNext()
                    } label: {
                        Text(currentStep == totalSteps - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .foregroundStyle(Color(hex: "#4A7C2F"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1.0 : 0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showAddClass) {
            AddClassSheet { newClass, schedule, days, startTime, endTime in
                tempClasses.append((classInfo: newClass, schedule: schedule, days: days, startTime: startTime, endTime: endTime))
            }
        }
    }
    
    // MARK: - Step Views
    
    private var modeSelectionStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "sparkles")
                .font(.system(size: 70))
                .foregroundStyle(.white)
            
            Text("How do you want to use MixFix?")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Pick the mode that best fits what you're working on right now. You can switch later in Settings.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Button {
                    tempStudyMode = "student"
                    studyMode = "student"
                    appSession.mode = .student
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Student Mode")
                                .font(.headline)
                            Spacer()
                            if tempStudyMode == "student" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        Text("Daily classes, homework, assignments, quizzes, and normal school life.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tempStudyMode == "student" ? Color.white : Color.white.opacity(0.2), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var googleConnectStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)

                Text("You're all set for Student Mode")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Next we'll add your classes so MixFix can build a realistic schedule around your real life.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var examDetailsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Tell us about your exam")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("We'll use this to build a realistic plan that fits your life.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 20) {
                // Exam date
                VStack(alignment: .leading, spacing: 8) {
                    Text("When is your test?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    DatePicker("Exam Date", selection: $tempExamDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                }
                
                // Started studying
                VStack(alignment: .leading, spacing: 8) {
                    Text("Have you started studying yet?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Toggle("Yes, I've started", isOn: $tempExamHasStartedStudying)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
                
                // Comfort level (only if started)
                if tempExamHasStartedStudying {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How comfortable do you feel about this exam?")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        HStack {
                            Slider(value: $tempExamComfortLevel, in: 1...5, step: 1)
                            Text("\(Int(tempExamComfortLevel))/5")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                
                // Desired daily hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("On a typical day, how many hours would you like to study for this test?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack {
                        Slider(value: $tempExamDailyStudyHours, in: 0.5...8, step: 0.5)
                        Text(String(format: "%.1f h", tempExamDailyStudyHours))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                
                // No-study days
                VStack(alignment: .leading, spacing: 12) {
                    Text("Are there any days you don't want to study for this test?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                            Button {
                                if tempExamNoStudyDays.contains(day) {
                                    tempExamNoStudyDays.remove(day)
                                } else {
                                    tempExamNoStudyDays.insert(day)
                                }
                            } label: {
                                Text(day.prefix(3))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(tempExamNoStudyDays.contains(day) ? Color(hex: "#4A7C2F") : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tempExamNoStudyDays.contains(day) ? Color.white : Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 70))
                .foregroundStyle(.white)
            
            Text("Welcome to MixFix")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
            
            Text("Your brain's dashboard for better studying")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 20) {
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should we call you?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    TextField("Enter your name", text: $tempUserName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .font(.body)
                }
                
                // Student Type / Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("What type of student are you?")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Picker("Student Type", selection: $tempStudentType) {
                        Text("High School").tag("highschool")
                        Text("College").tag("college")
                        Text("Graduate").tag("graduate")
                        Text("Other").tag("other")
                    }
                    .pickerStyle(.segmented)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                }
                
                // Exam Type (for Exam mode only). No need to ask for specific grade anymore.
                if isExamModeWithSupportedStudentType {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What exam are you studying for?")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Picker("Exam Type", selection: $tempExamType) {
                            ForEach(examTypeOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .font(.body)
                    }
                }
            }
            .padding(.top, 20)
        }
    }
    
    private var classesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Add Your Classes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Let's set up your class schedule so we can help you stay organized")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            if tempClasses.isEmpty {
                VStack(spacing: 16) {
                    Text("No classes added yet")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.vertical, 40)
                    
                    Button {
                        showAddClass = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Your First Class")
                        }
                        .font(.headline)
                        .foregroundStyle(Color(hex: "#4A7C2F"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(tempClasses.enumerated()), id: \.offset) { index, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.classInfo.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(item.schedule)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Button {
                                tempClasses.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    Button {
                        showAddClass = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Another Class")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var remindersStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Study Reminders")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Get smart reminders based on your AI-generated study schedule")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 16) {
                Toggle(isOn: $tempRemindersEnabled) {
                    Text("Enable Study Reminders")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .tint(Color(hex: "#4A7C2F"))
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                
                if tempRemindersEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Frequency")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Picker("Frequency", selection: $tempReminderFrequency) {
                            Text("Daily").tag("daily")
                            Text("Weekdays Only").tag("weekdays")
                            Text("Custom").tag("custom")
                        }
                        .pickerStyle(.segmented)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        
                        // Custom days selection
                        if tempReminderFrequency == "custom" {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Days")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.top, 8)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                                        Button {
                                            if tempCustomReminderDays.contains(day) {
                                                tempCustomReminderDays.remove(day)
                                            } else {
                                                tempCustomReminderDays.insert(day)
                                            }
                                        } label: {
                                            Text(day)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(tempCustomReminderDays.contains(day) ? Color(hex: "#4A7C2F") : .white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(tempCustomReminderDays.contains(day) ? Color.white : Color.white.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var colorCustomizationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Choose Your Theme")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Pick a color that represents you. This will customize your profile and home screen")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(availableColors, id: \.name) { colorOption in
                        Button {
                            withAnimation {
                                profileCircleColorName = colorOption.name
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(colorOption.gradient)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                            .opacity(profileCircleColorName == colorOption.name ? 1 : 0)
                                    )
                                    .shadow(radius: 4)
                                
                                Text(colorOption.name.capitalized)
                                    .font(.caption)
                                    .fontWeight(profileCircleColorName == colorOption.name ? .bold : .regular)
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
        }
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
        ("ruby", LinearGradient(colors: [Color(hex: "#FF7370"), Color(hex: "#A61818")], startPoint: .topLeading, endPoint: .bottomTrailing))
    ]
    
    private var schedulePreferencesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Study Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("When do you prefer to study? We'll generate your schedule within these hours")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Earliest Study Time")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Picker("Earliest", selection: $tempEarliestHour) {
                        ForEach(5...12, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest Study Time")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Picker("Latest", selection: $tempLatestHour) {
                        ForEach(18...23, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var reelPreferencesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Customize Your Feed")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Select topics you're interested in to personalize your study reel content")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            VStack(spacing: 12) {
                ForEach(availableReelTopics, id: \.self) { topic in
                    Button {
                        if tempSelectedReelTopics.contains(topic) {
                            tempSelectedReelTopics.remove(topic)
                        } else {
                            tempSelectedReelTopics.insert(topic)
                        }
                    } label: {
                        HStack {
                            Image(systemName: tempSelectedReelTopics.contains(topic) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.white)
                            
                            Text(topic.capitalized)
                                .foregroundStyle(.white)
                            
                            Spacer()
                        }
                        .padding()
                        .background(tempSelectedReelTopics.contains(topic) ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
            }
            
            Text("Select at least 3 topics to continue")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 4)
        }
    }
    
    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: notificationPermissionGranted ? "checkmark.circle.fill" : "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Text("Enable Notifications")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(notificationPermissionGranted && hasRequestedNotificationsThisSession ? 
                     "Great! You'll receive study reminders to help you stay on track" :
                     "Allow notifications so you never miss a study session")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            if !(notificationPermissionGranted && hasRequestedNotificationsThisSession) {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Smart study reminders")
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Assignment due date alerts")
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Upcoming test notifications")
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                
                Button {
                    requestNotificationPermission()
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Allow Notifications")
                    }
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#4A7C2F"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            
            if notificationPermissionGranted && hasRequestedNotificationsThisSession {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                    
                    Text("You're all set!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Tap 'Get Started' to begin your journey")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    // MARK: - Helper Functions
    
    private var gradeLevelPrompt: String {
        switch tempStudentType {
        case "highschool":
            return "What grade are you in?"
        case "college":
            return "What year are you in?"
        case "graduate":
            return "What program are you in?"
        default:
            return "What level are you at?"
        }
    }
    
    private var gradeLevelPlaceholder: String {
        switch tempStudentType {
        case "highschool":
            return "e.g., 9, 10, 11, 12"
        case "college":
            return "e.g., Freshman, Sophomore, Junior, Senior"
        case "graduate":
            return "e.g., Master's, PhD"
        default:
            return "Enter your level"
        }
    }
    
    private var isExamModeWithSupportedStudentType: Bool {
        let effectiveStudyMode = tempStudyMode ?? studyMode
        return effectiveStudyMode == "exam" && (tempStudentType == "highschool" || tempStudentType == "college")
    }
    
    private var examTypeOptions: [String] {
        if tempStudentType == "college" {
            return [
                "GRE (Graduate Record Examination)",
                "GMAT (Graduate Management Admission Test)",
                "LSAT (Law School Admission Test)",
                "MCAT (Medical College Admission Test)",
                "DAT (Dental Admission Test)",
                "OAT (Optometry Admission Test)",
                "PCAT (Pharmacy College Admission Test)"
            ]
        } else {
            return [
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
    }
    
    private var isExamMode: Bool {
        let effectiveStudyMode = tempStudyMode ?? studyMode
        return effectiveStudyMode == "exam"
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            // Require the user to pick a study mode (student or exam)
            return tempStudyMode != nil
        case 1:
            // Welcome step - require a name, and exam type if in Exam mode for supported types
            let hasName = !tempUserName.trimmingCharacters(in: .whitespaces).isEmpty
            if isExamModeWithSupportedStudentType {
                return hasName && !tempExamType.isEmpty
            }
            return hasName
        case 2:
            // Classes step - require at least one class
            return !tempClasses.isEmpty
        case 3:
            // Reminders step - always allow proceeding (optional feature)
            return true
        case 4, 5:
            // Schedule preferences and color customization
            return true
        case 6:
            // Reel preferences - require at least 3 topics
            return tempSelectedReelTopics.count >= 3
        case 7:
            // Notifications step
            return true
        default:
            return false
        }
    }
    
    private func handleNext() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        // Save all settings
        userName = tempUserName
        // userEmail is already saved from authentication
        gradeLevel = tempGradeLevel
        studentType = tempStudentType
        // Save exam settings if applicable
        if isExamModeWithSupportedStudentType {
            examType = tempExamType
        }
        if isExamMode {
            examDate = tempExamDate
            examHasStartedStudying = tempExamHasStartedStudying
            examComfortLevel = tempExamComfortLevel
            examDailyStudyHours = tempExamDailyStudyHours
            let daysArray = Array(tempExamNoStudyDays)
            if let encoded = try? JSONEncoder().encode(daysArray) {
                examNoStudyDaysData = encoded
            }
        }
        studyRemindersEnabled = tempRemindersEnabled
        reminderFrequency = tempReminderFrequency
        earliestStudyHour = tempEarliestHour
        latestStudyHour = tempLatestHour
        
        // Save custom reminder days
        if tempReminderFrequency == "custom" {
            let daysArray = Array(tempCustomReminderDays)
            if let encoded = try? JSONEncoder().encode(daysArray) {
                customReminderDaysData = encoded
            }
        }
        
        // Save classes
        let classesToSave = tempClasses.map { $0.classInfo }
        if let encoded = try? JSONEncoder().encode(classesToSave) {
            studentClassesData = encoded
        }
        
        // Save class schedules
        var schedules: [UUID: ClassScheduleInfo] = [:]
        for classItem in tempClasses {
            let scheduleInfo = ClassScheduleInfo(
                days: classItem.days,
                startTime: classItem.startTime,
                endTime: classItem.endTime
            )
            schedules[classItem.classInfo.id] = scheduleInfo
        }
        if let encoded = try? JSONEncoder().encode(schedules) {
            classSchedulesData = encoded
        }
        
        // Save reel preferences
        let topicsArray = Array(tempSelectedReelTopics)
        if let encoded = try? JSONEncoder().encode(topicsArray) {
            preferredReelTopicsData = encoded
        }
        
        // Initialize user reel preferences in SwiftData
        initializeReelPreferences()
        
        // Create calendar events for classes
        createClassEvents()
        
        // Mark onboarding as complete for the active mode
        if isExamMode {
            hasCompletedExamOnboarding = true
        } else {
            hasCompletedStudentOnboarding = true
        }
        hasCompletedOnboarding = true
        showOnboarding = false
        
        // Sync user settings to Firestore (if not guest)
        if !isGuestUser {
            Task {
                await syncUserSettingsToFirestore()
            }
        }
    }
    
    private func cancelOnboarding() {
        // Reset guest user flag
        isGuestUser = false
        // Reset onboarding flag
        hasCompletedOnboarding = false
        // Close onboarding to return to auth
        showOnboarding = false
    }
    
    private func createClassEvents() {
        let calendar = Calendar.current
        let today = Date()
        
        // Map short day names to weekday numbers (1 = Sunday, 2 = Monday, etc.)
        let dayMapping: [String: Int] = [
            "Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7
        ]
        
        print("🎓 Creating class events for \(tempClasses.count) classes")
        
        // Create events for the next 16 weeks (one semester)
        for classItem in tempClasses {
            print("📚 Processing class: \(classItem.classInfo.name)")
            print("   Days: \(classItem.days)")
            
            for day in classItem.days {
                guard let weekday = dayMapping[day] else { 
                    print("   ⚠️ Invalid day: \(day)")
                    continue 
                }
                
                // Extract time from startTime and endTime
                let startHour = calendar.component(.hour, from: classItem.startTime)
                let startMinute = calendar.component(.minute, from: classItem.startTime)
                let endHour = calendar.component(.hour, from: classItem.endTime)
                let endMinute = calendar.component(.minute, from: classItem.endTime)
                
                // Create events for each week
                var eventsCreated = 0
                
                // Find the first occurrence of this weekday
                var searchComponents = DateComponents()
                searchComponents.weekday = weekday
                
                // Start from yesterday to include today if it matches
                let startDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                
                if var nextOccurrence = calendar.nextDate(after: startDate, matching: searchComponents, matchingPolicy: .nextTime) {
                    // Create events for the next 16 weeks
                    for _ in 0..<16 {
                        // Create start and end dates with the class times
                        var startComponents = calendar.dateComponents([.year, .month, .day], from: nextOccurrence)
                        startComponents.hour = startHour
                        startComponents.minute = startMinute
                        
                        var endComponents = calendar.dateComponents([.year, .month, .day], from: nextOccurrence)
                        endComponents.hour = endHour
                        endComponents.minute = endMinute
                        
                        if let eventStartDate = calendar.date(from: startComponents),
                           let eventEndDate = calendar.date(from: endComponents) {
                            
                            // Format time string
                            let timeFormatter = DateFormatter()
                            timeFormatter.dateFormat = "h:mm a"
                            let timeString = "\(timeFormatter.string(from: eventStartDate)) - \(timeFormatter.string(from: eventEndDate))"
                            
                            // Add event to store
                            store.addEvent(
                                title: classItem.classInfo.name,
                                start: eventStartDate,
                                end: eventEndDate,
                                category: "Classes",
                                timeString: timeString,
                                className: classItem.classInfo.name
                            )
                            
                            eventsCreated += 1
                        }
                        
                        // Move to the next week (add 7 days)
                        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: nextOccurrence) {
                            nextOccurrence = nextWeek
                        } else {
                            break
                        }
                    }
                }
                
                print("   ✅ Created \(eventsCreated) events for \(day)")
            }
        }
        
        print("🎉 Finished creating class events")
    }
    
    private func initializeReelPreferences() {
        guard let modelContext = DataStoreAccessor.shared.modelContext else {
            print("❌ No model context available for reel preferences")
            return
        }
        
        // Get current user ID
        let userId = store.userId
        
        // Check if preferences already exist
        let descriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if (try? modelContext.fetch(descriptor).first) != nil {
            print("🎬 User reel preferences already exist")
            return
        }
        
        // Create initial topic affinities with positive scores for selected topics
        var topicAffinities: [String: Double] = [:]
        for topic in tempSelectedReelTopics {
            topicAffinities[topic] = 5.0 // Start with positive affinity
        }
        
        // Create new preferences
        let newPreferences = UserReelPreferencesSD(
            userId: userId,
            topicAffinities: topicAffinities,
            typeAffinities: [:], // Will be learned over time
            recentlyShownReelIds: [],
            blockedTags: [],
            exploreRate: 0.2
        )
        
        modelContext.insert(newPreferences)
        
        do {
            try modelContext.save()
            print("✅ Initialized reel preferences with \(tempSelectedReelTopics.count) preferred topics")
        } catch {
            print("❌ Error saving reel preferences: \(error)")
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("🔔 Notification status check: \(settings.authorizationStatus.rawValue)")
                print("🔔 .notDetermined = 0, .denied = 1, .authorized = 2, .provisional = 3")
                notificationPermissionGranted = settings.authorizationStatus == .authorized
                print("🔔 notificationPermissionGranted set to: \(notificationPermissionGranted)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        print("🔔 Requesting notification permission...")
        hasRequestedNotificationsThisSession = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                notificationPermissionGranted = granted
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else {
                    print(granted ? "✅ Notification permission GRANTED by user" : "❌ Notification permission DENIED by user")
                }
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func syncUserSettingsToFirestore() async {
        do {
            var settings: [String: Any] = [:]
            
            // User identity
            settings["userName"] = userName
            settings["userEmail"] = userEmail
            settings["gradeLevel"] = gradeLevel
            settings["studentType"] = studentType
            
            // User preferences
            settings["profileCircleColor"] = profileCircleColorName
            
            // Classes data (encode as base64 for Firestore)
            if !studentClassesData.isEmpty {
                settings["studentClassesData"] = studentClassesData.base64EncodedString()
            }
            
            // Study settings
            settings["studyRemindersEnabled"] = studyRemindersEnabled
            settings["reminderFrequency"] = reminderFrequency
            settings["earliestStudyHour"] = earliestStudyHour
            settings["latestStudyHour"] = latestStudyHour
            
            // Reel preferences (encode as base64 for Firestore)
            if !preferredReelTopicsData.isEmpty {
                settings["preferredReelTopics"] = preferredReelTopicsData.base64EncodedString()
            }
            
            try await FirestoreService.shared.syncUserSettings(settings)
            print("✅ Synced user settings to Firestore")
        } catch {
            print("❌ Error syncing user settings: \(error.localizedDescription)")
        }
    }
}

// MARK: - Add Class Sheet
struct AddClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (StudentClass, String, Set<String>, Date, Date) -> Void
    
    @State private var className = ""
    @State private var classSchedule = ""
    @State private var selectedDays: Set<String> = []
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Class Details") {
                    TextField("Class Name", text: $className)
                    TextField("Schedule (e.g., MWF 9:00-10:30)", text: $classSchedule)
                }
                
                Section("Days") {
                    HStack(spacing: 12) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Button {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                                updateScheduleString()
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
                    .padding(.vertical, 4)
                }
                
                Section("Time") {
                    FiveMinuteTimePicker(date: $startTime, label: "Start Time")
                        .onChange(of: startTime) { _, newStartTime in
                            // Automatically set end time to 1 hour after start time
                            endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) ?? newStartTime
                            updateScheduleString()
                        }
                    FiveMinuteTimePicker(date: $endTime, label: "End Time")
                        .onChange(of: endTime) { _, _ in updateScheduleString() }
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newClass = StudentClass(
                            id: UUID(),
                            name: className,
                            color: "#4CAF50"
                        )
                        onAdd(newClass, classSchedule, selectedDays, startTime, endTime)
                        dismiss()
                    }
                    .disabled(className.isEmpty || classSchedule.isEmpty)
                }
            }
        }
    }
    
    private func updateScheduleString() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let daysString = selectedDays.sorted().joined()
        let startString = timeFormatter.string(from: startTime)
        let endString = timeFormatter.string(from: endTime)
        
        classSchedule = "\(daysString) \(startString)-\(endString)"
    }
}
