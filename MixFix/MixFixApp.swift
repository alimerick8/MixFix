//
//  MixFixApp.swift
//  MixFix
//
//  Created by Ava Limerick on 10/1/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import FirebaseCore
import FirebaseAuth

// AppDelegate for Firebase Phone Auth
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
}

// MARK: - Model Container Configuration
func makeModelContainer() -> ModelContainer {
    let schema = Schema([
        TaskItemSD.self,
        CalendarEventSD.self,
        MoodEntrySD.self,
        HabitSD.self,
        JournalEntrySD.self,
        ClassCheckInSD.self,
        WeeklyReportSD.self,
        ReelSD.self,
        UserReelInteractionSD.self,
        UserReelPreferencesSD.self,
        StudySessionLogSD.self,
        CustomStudyBlockSD.self
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true
    )
    
    // FORCE DELETE DATABASE IF IT'S CORRUPTED (temporary fix)
    #if DEBUG
    let url = modelConfiguration.url
    if FileManager.default.fileExists(atPath: url.path) {
        print("🗑️ DEBUG: Force deleting existing database to fix schema...")
        try? FileManager.default.removeItem(at: url)
        
        let baseURL = url.deletingPathExtension()
        try? FileManager.default.removeItem(at: baseURL.appendingPathExtension("store-wal"))
        try? FileManager.default.removeItem(at: baseURL.appendingPathExtension("store-shm"))
    }
    #endif
    
    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        print("❌ Failed to create ModelContainer: \(error)")
        // If migration fails, delete the store and try again (development only)
        #if DEBUG
        print("🔄 Attempting to delete old store and recreate...")
        let url = modelConfiguration.url
        
        // Delete the main store file
        try? FileManager.default.removeItem(at: url)
        
        // Also delete related files (WAL, SHM, etc.)
        let baseURL = url.deletingPathExtension()
        let walURL = baseURL.appendingPathExtension("store-wal")
        let shmURL = baseURL.appendingPathExtension("store-shm")
        try? FileManager.default.removeItem(at: walURL)
        try? FileManager.default.removeItem(at: shmURL)
        
        print("🗑️ Deleted database files, creating fresh database...")
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("❌ Failed to create ModelContainer even after cleanup: \(error)")
        }
        #else
        fatalError("Failed to create ModelContainer: \(error)")
        #endif
    }
}

@main
struct MixFixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var persistenceController: PersistenceController?
    
    init() {
        // Configure Firebase synchronously to prevent glitches
        print("🔥 Configuring Firebase...")
        FirebaseApp.configure()
        
        if let app = FirebaseApp.app() {
            print("✅ Firebase configured successfully")
            print("✅ App name: \(app.name)")
            print("✅ Project ID: \(app.options.projectID ?? "NONE")")
            print("✅ Bundle ID: \(app.options.bundleID)")
            print("✅ API Key exists: \(app.options.apiKey != nil)")
        } else {
            print("❌ Firebase configuration FAILED!")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
                .task {
                    if persistenceController == nil {
                        persistenceController = await MainActor.run {
                            PersistenceController.shared
                        }
                    }
                }
        }
        .modelContainer(makeModelContainer())
    }
}

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: DataStore
    @StateObject private var timerManager = PomodoroTimerManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var userSession = UserSession()
    @StateObject private var appSession = AppSession()
    @StateObject private var examState = ExamState()
    @State private var showLaunchScreen = true
    @State private var showOnboarding = false
    @State private var isCheckingAuth = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isGuestUser") private var isGuestUser: Bool = false
    
    init() {
        // Initialize store with environment's model context (will be set later)
        _store = StateObject(wrappedValue: DataStore(modelContext: nil, seed: false))
        
        print("🔍 INIT - Firebase user: \(FirebaseManager.shared.currentUser?.email ?? "NONE")")
    }
    
    private var isAuthenticated: Bool {
        // Authenticated if we have a Firebase uid OR we're in explicit guest mode.
        // Firestore calls are still guarded by Auth.auth().currentUser, so guests remain local-only.
        let authenticated = (userSession.uid != nil) || isGuestUser
        print("🔍 isAuthenticated check: \(authenticated), uid: \(userSession.uid ?? "NONE"), guest: \(isGuestUser)")
        return authenticated
    }
    
    private var timeBasedGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 4..<12: // Morning
            return LinearGradient(
                colors: [Color(hex: "#87CEEB"), Color(hex: "#E0F6FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 12..<17: // Afternoon
            return LinearGradient(
                colors: [Color(hex: "#FFB347"), Color(hex: "#FFCC80")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 17..<20: // Evening
            return LinearGradient(
                colors: [Color(hex: "#FF6B9D"), Color(hex: "#C44569")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default: // Night
            return LinearGradient(
                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43"), Color(hex: "#2C5364")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        let _ = print("🔍🔍🔍 APP BODY RENDER - isCheckingAuth: \(isCheckingAuth), isAuthenticated: \(isAuthenticated), hasCompletedOnboarding: \(hasCompletedOnboarding), showOnboarding: \(showOnboarding), isGuestUser: \(isGuestUser)")
        
        ZStack {
            // Background color to prevent white screen flash
            timeBasedGradient
                .ignoresSafeArea()
            
            // Show authentication, onboarding, or main app (hidden behind launch screen initially)
            Group {
                if isCheckingAuth {
                    // Show nothing while checking authentication
                    Color.clear
                } else if !isAuthenticated {
                    // ALWAYS show authentication screen if not logged in
                    let _ = print("📱 SHOWING: AuthenticationView")
                    AuthenticationView(showOnboarding: $showOnboarding)
                        .environmentObject(store)
                        .environmentObject(userSession)
                        .environmentObject(appSession)
                        .environmentObject(examState)
                } else if showOnboarding || !hasCompletedOnboarding {
                    // Show onboarding for brand new sign ups OR any authenticated user
                    // who has not yet completed onboarding (extra safety guard)
                    let _ = print("📱 SHOWING: OnboardingView (showOnboarding=\(showOnboarding), hasCompletedOnboarding=\(hasCompletedOnboarding))")
                    OnboardingView(showOnboarding: $showOnboarding)
                        .environmentObject(store)
                        .environmentObject(userSession)
                        .environmentObject(appSession)
                        .environmentObject(examState)
                } else {
                    // Show main app - user is authenticated and has completed onboarding
                    // Wrap in lock enforcement container to control navigation when study session is locked
                    let _ = print("📱 SHOWING: ContentView (Main App)")
                    let _ = print("🔍 hasCompletedOnboarding: \(hasCompletedOnboarding)")
                    let _ = print("🔍 showOnboarding: \(showOnboarding)")
                    LockEnforcementContainer {
                        ContentView()
                            .environmentObject(store)
                            .environmentObject(userSession)
                            .environmentObject(appSession)
                            .environmentObject(examState)
                    }
                    .environmentObject(store)
                    .environmentObject(timerManager)
                    .environmentObject(userSession)
                    .environmentObject(appSession)
                    .environmentObject(examState)
                }
            }
            .opacity(showLaunchScreen ? 0 : 1)
            .animation(.easeIn(duration: 0.5), value: showLaunchScreen)
            
            // Launch screen overlay (shown first to prevent white screen)
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            }
            
            // Global timer alert overlay
            if timerManager.showAlert {
                ZStack {
                    // Blur background
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .blur(radius: 10)
                    
                    VStack(spacing: 20) {
                        // Icon
                        Image(systemName: timerManager.timerMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.3), radius: 10)
                        
                        Text(timerManager.alertMessage)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(timerManager.timerMode == .focus ? "25 minutes of focus" : "5 minute break")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(50)
                    .background(
                        ZStack {
                            // Glass morphism effect
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    (timerManager.timerMode == .focus ? 
                                        Color(hex: "#8B7D6B") : 
                                        Color.green)
                                    .opacity(0.6)
                                )
                                .blur(radius: 20)
                            
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.5),
                                                    .white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        }
                    )
                    .shadow(color: (timerManager.timerMode == .focus ? Color(hex: "#8B7D6B") : Color.green).opacity(0.4), radius: 30, x: 0, y: 10)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerManager.showAlert)
            }
        }
        .onAppear {
            // Set the model context for the store
            store.setModelContext(modelContext)
            
            // Configure SessionManager
            SessionManager.shared.configure(modelContext: modelContext, userId: store.userId)

            // Validate existing auth session on app launch
            Task {
                if userSession.uid != nil {
                    print("🔍 User session exists, validating token...")
                    let isValid = await firebaseManager.validateCurrentSession()
                    
                    await MainActor.run {
                        if isValid {
                            print("🔍 Token valid - marking onboarding complete")
                            hasCompletedOnboarding = true
                        } else {
                            print("🔍 Token invalid - clearing session")
                            userSession.clearUserData()
                        }
                    }
                }
                
                // Check authentication status after validation
                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isCheckingAuth = false
                    }
                }
            }
            
            // Dismiss launch screen after simplified animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
            
            // Clear notification badge after a delay to prevent crash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    try? await UNUserNotificationCenter.current().setBadgeCount(0)
                }
            }
        }
        .onChange(of: userSession.uid) { oldUid, newUid in
            Task {
                // Whenever the Firebase uid changes, fully reset local data
                await MainActor.run {
                    store.clearAllData()
                }

                // If we now have a logged-in user, pull their data from Firestore.
                if newUid != nil {
                    // Reconfigure SessionManager for new user
                    await MainActor.run {
                        SessionManager.shared.configure(modelContext: modelContext, userId: store.userId)
                    }
                    
                    // If user is logging in (not signing up), they've completed onboarding
                    if oldUid == nil && newUid != nil {
                        await MainActor.run {
                            // User is logging back in - mark onboarding complete
                            hasCompletedOnboarding = true
                        }
                    }
                    await store.downloadAllUserData()
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Clear badge when app becomes active
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Task {
                        try? await UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                }
                WeeklyReportManager.shared.generateReportIfNeeded()
                
                // Refresh session stats when app becomes active
                Task {
                    await SessionManager.shared.refreshStats()
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
