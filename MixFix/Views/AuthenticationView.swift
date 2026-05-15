//
//  AuthenticationView.swift
//  MixFix
//
//  Authentication screen for login/signup
//

import SwiftUI
import FirebaseAuth
import FirebaseCore

// View extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var userSession: UserSession
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLogin = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSkipWarning = false
    @Binding var showOnboarding: Bool
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""
    @AppStorage("gradeLevel") private var gradeLevel: String = ""
    @AppStorage("studentType") private var studentType: String = "highschool"
    @AppStorage("profileCircleColor") private var profileCircleColorName: String = "blue"
    @AppStorage("moodColorsEnabled") private var moodColorsEnabled: Bool = true
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("preferredReelTopicsData") private var preferredReelTopicsData: Data = Data()
    @AppStorage("favoriteGenresData") private var favoriteGenresData: Data = Data()
    @AppStorage("studentProfileData") private var studentProfileData: Data = Data()
    @AppStorage("studyRemindersEnabled") private var studyRemindersEnabled: Bool = true
    @AppStorage("reminderDaysAhead") private var reminderDaysAhead: Int = 7
    @AppStorage("customReminderDaysAhead") private var customReminderDaysAhead: Int = 7
    @AppStorage("reminderFrequency") private var reminderFrequency: String = "daily"
    @AppStorage("reminderHour") private var reminderHour: Int = 18
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("earliestStudyHour") private var earliestStudyHour: Int = 7
    @AppStorage("latestStudyHour") private var latestStudyHour: Int = 22
    @AppStorage("moodBasedScheduleEnabled") private var moodBasedScheduleEnabled: Bool = true
    @AppStorage("showReviewBlocks") private var showReviewBlocks: Bool = true
    @AppStorage("timerFocusLockEnabled") private var timerFocusLockEnabled: Bool = false
    @AppStorage("calmingMusicGenre") private var calmingMusicGenre: String = "Nature Sounds"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isGuestUser") private var isGuestUser: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#87CEEB"), Color(hex: "#E0F6FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("MixFix")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Your AI-powered study companion")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Login/Sign Up Form
                VStack(spacing: 20) {
                    // Email Field
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .foregroundStyle(.black)
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textContentType(isLogin ? .password : .newPassword)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .foregroundStyle(.black)
                        
                        // Password requirement hint (only for signup)
                        if !isLogin {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.leading, 4)
                        }
                    }
                    
                    // Confirm Password Field (only for signup)
                    if !isLogin {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .foregroundStyle(.black)
                    }
                    
                    // Login/Sign Up Button
                    Button {
                        handleAuthentication()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(isLogin ? "Log In" : "Sign Up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(12)
                    .disabled(isButtonDisabled())
                    .opacity(isButtonDisabled() ? 0.6 : 1.0)
                    
                    // Toggle between Login/Sign Up
                    Button {
                        withAnimation {
                            isLogin.toggle()
                        }
                    } label: {
                        Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    
                    // Skip Button
                    Button {
                        showSkipWarning = true
                    } label: {
                        Text("Skip for now")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .underline()
                    }
                    
                    // Test Firebase Button (for debugging)
                    Button {
                        testFirebaseConnection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.caption2)
                            Text("Test Connection")
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Warning", isPresented: $showSkipWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Continue Without Account") {
                // Enter guest mode: skip Firebase auth and go straight to onboarding/main app
                isGuestUser = true
                showOnboarding = true
            }
        } message: {
            Text("Your data will not be saved without an account. You'll lose all your information if you delete the app.")
        }
    }
    
    private func handleAuthentication() {
        // Validate email
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        // Validate password
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        // For signup, validate password confirmation
        if !isLogin {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                showError = true
                return
            }
        }
        
        if isLogin {
            // Handle Login
            login()
        } else {
            // Handle Sign Up
            signUp()
        }
    }
    
    private func isButtonDisabled() -> Bool {
        if isLoading {
            return true
        }
        
        return email.isEmpty || password.isEmpty || (!isLogin && confirmPassword.isEmpty)
    }
    
    private func login() {
        isLoading = true
        
        Task {
            do {
                print("🔐 ===== LOGIN ATTEMPT =====")
                print("🔐 Email: \(email)")
                print("🔐 Firebase configured: \(FirebaseApp.app() != nil)")
                
                // IMPORTANT: Sign out any existing user first to prevent auth conflicts
                if Auth.auth().currentUser != nil {
                    print("🔐 Existing user session found, signing out first...")
                    try? firebaseManager.signOut()
                }
                
                print("🔐 Attempting to sign in...")
                try await firebaseManager.signIn(email: email, password: password)
                print("✅ Sign in successful")
                
                // Validate the session to ensure token is ready before accessing Firestore
                print("🔐 Validating auth token...")
                let isValid = await firebaseManager.validateCurrentSession()
                guard isValid else {
                    throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication validation failed"])
                }
                print("✅ Auth token validated")

                await MainActor.run {
                    // IMPORTANT: Set hasCompletedOnboarding BEFORE setting uid
                    // This prevents the app from showing onboarding when uid changes
                    hasCompletedOnboarding = true
                    isGuestUser = false
                    userEmail = email
                    isLoading = false
                }

                // Clear old user's AppStorage data before loading new user's data
                await MainActor.run {
                    clearPreviousUserData()
                }
                
                // Set uid AFTER hasCompletedOnboarding to prevent onboarding from showing
                // This will trigger MixFixApp.onChange which clears old data and downloads new data
                await MainActor.run {
                    userSession.uid = firebaseManager.currentUser?.uid
                }
                
                // Small delay to ensure auth token has propagated before downloading settings
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Download and apply user settings (name, preferences, etc.)
                // Note: MixFixApp.onChange handles downloadAllUserData when uid changes
                print("📥 Downloading user settings from Firestore for \(email)...")
                await downloadUserSettings()
                print("✅ Login complete")
            } catch {
                print("❌ ===== LOGIN ERROR =====")
                print("❌ Error: \(error)")
                print("❌ LocalizedDescription: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ Domain: \(nsError.domain)")
                    print("❌ Code: \(nsError.code)")
                    print("❌ UserInfo: \(nsError.userInfo)")
                }
                
                await MainActor.run {
                    // Show the actual error message for debugging
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                print("📝 ===== SIGNUP ATTEMPT =====")
                print("📝 Email: \(email)")
                print("📝 Password length: \(password.count)")
                print("📝 Firebase configured: \(FirebaseApp.app() != nil)")
                
                // IMPORTANT: Sign out any existing user first to prevent auth conflicts
                if Auth.auth().currentUser != nil {
                    print("📝 Existing user session found, signing out first...")
                    try? firebaseManager.signOut()
                }
                
                print("📝 Attempting to create account...")
                try await firebaseManager.signUp(email: email, password: password)
                print("✅ Sign up successful - account created")
                
                // Clear any previous user's data from AppStorage
                await MainActor.run {
                    clearPreviousUserData()
                }
                
                await MainActor.run {
                    // Mark onboarding as incomplete so the root router shows OnboardingView
                    hasCompletedOnboarding = false
                    showOnboarding = true
                    userEmail = email
                    // Clear any existing guest flag now that a real account exists
                    isGuestUser = false

                    // Ensure the root router sees this brand-new account as authenticated
                    userSession.uid = firebaseManager.currentUser?.uid

                    isLoading = false
                }
            } catch {
                print("❌ ===== SIGNUP ERROR =====")
                print("❌ Error: \(error)")
                print("❌ LocalizedDescription: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ Domain: \(nsError.domain)")
                    print("❌ Code: \(nsError.code)")
                    print("❌ UserInfo: \(nsError.userInfo)")
                }
                
                await MainActor.run {
                    // Show the actual error message for debugging
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func testFirebaseConnection() {
        print("🧪 ===== FIREBASE CONNECTION TEST =====")
        print("🧪 Firebase App configured: \(FirebaseApp.app() != nil)")
        
        if let app = FirebaseApp.app() {
            print("🧪 Firebase App Name: \(app.name)")
            print("🧪 Firebase Options:")
            if let apiKey = app.options.apiKey {
                print("   - API Key: \(apiKey.prefix(10))...")
            }
            print("   - Project ID: \(String(describing: app.options.projectID))")
            print("   - Bundle ID: \(app.options.bundleID)")
            print("   - GCM Sender ID: \(app.options.gcmSenderID)")
        } else {
            print("🧪 ❌ Firebase App is NOT configured!")
        }
        
        print("🧪 Auth instance: \(Auth.auth())")
        print("🧪 Current user: \(Auth.auth().currentUser?.email ?? "none")")
        print("🧪 ===== TEST COMPLETE =====")
        
        errorMessage = "Check Xcode console for Firebase test results"
        showError = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func clearPreviousUserData() {
        print("🧽 Clearing previous user's data from AppStorage")
        
        // Clear user identity
        let oldName = userName
        userName = ""
        if !oldName.isEmpty {
            print("  - Cleared userName: '\(oldName)' → ''")
        }
        
        // Clear user preferences
        profileCircleColorName = "blue"
        
        // Clear student data
        let oldClassesSize = studentClassesData.count
        studentClassesData = Data()
        if oldClassesSize > 0 {
            print("  - Cleared \(oldClassesSize) bytes of class data")
        }
        gradeLevel = ""
        studentType = "highschool"
        
        // Clear reel preferences
        preferredReelTopicsData = Data()
        
        print("✅ Cleared previous user data, ready for new user's data")
    }
    
    private func downloadUserSettings() async {
        do {
            guard let settings = try await FirestoreService.shared.fetchUserSettings() else {
                print("📥 No user settings found in Firestore")
                return
            }
            
            print("📥 Downloaded user settings from Firestore")
            
            await MainActor.run {
                // Apply user identity
                if let name = settings["userName"] as? String {
                    userName = name
                    print("✅ Set userName to: \(name)")
                }
                if let email = settings["userEmail"] as? String {
                    userEmail = email
                }
                if let phone = settings["userPhone"] as? String {
                    userPhone = phone
                }
                if let level = settings["gradeLevel"] as? String {
                    gradeLevel = level
                }
                if let type = settings["studentType"] as? String {
                    studentType = type
                }
                
                // Apply UI preferences
                if let color = settings["profileCircleColor"] as? String {
                    profileCircleColorName = color
                }
                if let moodColors = settings["moodColorsEnabled"] as? Bool {
                    moodColorsEnabled = moodColors
                }
                
                // Apply study settings
                if let remindersEnabled = settings["studyRemindersEnabled"] as? Bool {
                    studyRemindersEnabled = remindersEnabled
                }
                if let reminderDays = settings["reminderDaysAhead"] as? Int {
                    reminderDaysAhead = reminderDays
                }
                if let customDays = settings["customReminderDaysAhead"] as? Int {
                    customReminderDaysAhead = customDays
                }
                if let frequency = settings["reminderFrequency"] as? String {
                    reminderFrequency = frequency
                }
                if let hour = settings["reminderHour"] as? Int {
                    reminderHour = hour
                }
                if let minute = settings["reminderMinute"] as? Int {
                    reminderMinute = minute
                }
                if let earliestHour = settings["earliestStudyHour"] as? Int {
                    earliestStudyHour = earliestHour
                }
                if let latestHour = settings["latestStudyHour"] as? Int {
                    latestStudyHour = latestHour
                }
                if let moodBased = settings["moodBasedScheduleEnabled"] as? Bool {
                    moodBasedScheduleEnabled = moodBased
                }
                if let showReview = settings["showReviewBlocks"] as? Bool {
                    showReviewBlocks = showReview
                }
                
                // Apply timer lock setting (enabled state only)
                if let timerLock = settings["timerFocusLockEnabled"] as? Bool {
                    timerFocusLockEnabled = timerLock
                }
                
                // Apply music preferences
                if let musicGenre = settings["calmingMusicGenre"] as? String {
                    calmingMusicGenre = musicGenre
                }
                
                // Apply Data objects from base64
                if let classesBase64 = settings["studentClassesData"] as? String,
                   let classesData = Data(base64Encoded: classesBase64) {
                    studentClassesData = classesData
                    print("✅ Loaded \(classesData.count) bytes of class data")
                }
                
                if let reelTopicsBase64 = settings["preferredReelTopicsData"] as? String,
                   let reelTopicsData = Data(base64Encoded: reelTopicsBase64) {
                    preferredReelTopicsData = reelTopicsData
                    print("✅ Loaded reel preferences")
                }
                
                if let genresBase64 = settings["favoriteGenresData"] as? String,
                   let genresData = Data(base64Encoded: genresBase64) {
                    favoriteGenresData = genresData
                    print("✅ Loaded favorite genres")
                }
                
                if let profileBase64 = settings["studentProfileData"] as? String,
                   let profileData = Data(base64Encoded: profileBase64) {
                    studentProfileData = profileData
                    print("✅ Loaded student profile")
                }
                
                print("✅ User settings applied successfully")
            }
        } catch {
            print("❌ Error downloading user settings: \(error.localizedDescription)")
        }
    }
}
