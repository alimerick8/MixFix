//
//  ContentView.swift
//  MixFix
//
//  Created by Ava Limerick on 10/1/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @State private var selectedTab = 0
    
    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        // Always show main app - onboarding is handled in MixFixApp
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(selectedTab: $selectedTab) }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            NavigationStack { StudyView() }
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Study")
                }
                .tag(1)
            
            ReelsView(userId: store.userId)
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Reels")
                }
                .tag(2)
                .environmentObject(store)

            NavigationStack { ProfileView() }
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // If locked, block tab change
            if timerManager.isLockedSession {
                selectedTab = oldValue
                // Haptic feedback to indicate lock
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
        .onAppear {
            // Customize tab bar spacing
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Reduce item spacing
            appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
            appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
            
            // Apply very compact spacing
            UITabBar.appearance().itemSpacing = 4 // More compact
            UITabBar.appearance().itemWidth = 45 // Narrower items
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// Wrapper to show DayDetailView directly in the Calendar tab
struct CalendarTabView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var currentMonth = Date()
    
    var body: some View {
        DayDetailView(selectedDate: Date(), currentMonth: $currentMonth)
            .environmentObject(dataStore)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
