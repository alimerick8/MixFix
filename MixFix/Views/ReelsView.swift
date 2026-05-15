//
//  ReelsView.swift
//  MixFix
//

import SwiftUI

struct ReelsView: View {
    @StateObject private var reelService: ReelService
    @EnvironmentObject var store: DataStore
    @Environment(\.modelContext) private var modelContext
    @State private var reels: [Reel] = []
    @State private var likedReels: Set<UUID> = []
    @State private var savedReels: Set<UUID> = []
    @State private var viewStartTimes: [UUID: Date] = [:]
    @State private var isLoadingMore = false
    @State private var showWhyThisSheet = false
    @State private var isRefreshing = false
    @AppStorage("hasSeenReelsIntro") private var hasSeenReelsIntro = false
    
    init(userId: String) {
        _reelService = StateObject(wrappedValue: ReelService(userId: userId))
    }
    
    var body: some View {
        ZStack {
            if reels.isEmpty && !isLoadingMore {
                // Empty state
                emptyStateView
                    .ignoresSafeArea()
            } else {
                // Reels feed with snap scrolling (TikTok/Instagram style)
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(reels.enumerated()), id: \.element.id) { index, reel in
                                ReelCardView(
                                    reel: reel,
                                    isLiked: Binding(
                                        get: { likedReels.contains(reel.id) },
                                        set: { newValue in
                                            if newValue {
                                                likedReels.insert(reel.id)
                                            } else {
                                                likedReels.remove(reel.id)
                                            }
                                        }
                                    ),
                                    isSaved: Binding(
                                        get: { savedReels.contains(reel.id) },
                                        set: { newValue in
                                            if newValue {
                                                savedReels.insert(reel.id)
                                            } else {
                                                savedReels.remove(reel.id)
                                            }
                                        }
                                    ),
                                    onLike: {
                                        handleLike(reelId: reel.id)
                                    },
                                    onSave: {
                                        handleSave(reelId: reel.id, isSaved: savedReels.contains(reel.id))
                                    },
                                    onMoreLikeThis: {
                                        handleMoreLikeThis(reelId: reel.id)
                                    },
                                    onLessLikeThis: {
                                        handleLessLikeThis(reelId: reel.id)
                                    },
                                    onWhyThis: {
                                        showWhyThisSheet = true
                                    }
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .containerRelativeFrame(.vertical)
                                .id(reel.id)
                                .onAppear {
                                    handleReelAppear(reel: reel, index: index)
                                }
                                .onDisappear {
                                    handleReelDisappear(reel: reel)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .ignoresSafeArea()
                }
            }
            
            // First time prompt (show immediately, don't wait for loading)
            if !hasSeenReelsIntro {
                FirstTimePromptView(onDismiss: {
                    withAnimation {
                        hasSeenReelsIntro = true
                    }
                })
            }
            
            // Loading indicator (only show if we've seen intro and still loading)
            if hasSeenReelsIntro && reels.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // Refresh button (TikTok style)
            if !reels.isEmpty && hasSeenReelsIntro {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            refreshReels()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Refresh")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea() // Extend content to all edges
        .task {
            print("🎬 ReelsView: Task started")
            reelService.setModelContext(modelContext)
            if reels.isEmpty {
                print("🎬 ReelsView: Fetching reels...")
                let newReels = await reelService.getNextBatch()
                print("🎬 ReelsView: Received \(newReels.count) reels")
                reels = newReels
                print("🎬 ReelsView: State updated with \(reels.count) reels")
            }
        }
        .sheet(isPresented: $showWhyThisSheet) {
            WhyThisReelSheet()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                
                Text("Loading your feed...")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Personalized tips coming right up")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadInitialReels() {
        guard reels.isEmpty else { return }
        
        isLoadingMore = true
        Task {
            let newReels = await reelService.getNextBatch()
            await MainActor.run {
                reels = newReels
                isLoadingMore = false
            }
        }
    }
    
    private func refreshReels() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        Task {
            // Mark all current reels as "recently shown" so they don't appear again
            let currentReelIds = await MainActor.run { reels.map { $0.id } }
            
            if !currentReelIds.isEmpty {
                print("🔄 Refresh: Marking \(currentReelIds.count) reels as recently shown to avoid repeats")
                
                // Mark as shown AND provide negative feedback for all current reels
                // This tells the algorithm the user didn't like this batch
                await MainActor.run {
                    reelService.markReelsAsShown(reelIds: currentReelIds)
                    
                    // Provide "less like this" feedback for each reel
                    for reelId in currentReelIds {
                        reelService.provideFeedback(reelId: reelId, moreLikeThis: false)
                    }
                }
                print("🔄 Refresh: Provided negative feedback for refreshed reels")
            }
            
            // Clear current reels from view
            await MainActor.run {
                reels = []
            }
            
            // Fetch fresh batch (will exclude recently shown reels and adjust for negative feedback)
            let newReels = await reelService.getNextBatch()
            print("🔄 Refresh: Fetched \(newReels.count) new reels")
            
            await MainActor.run {
                reels = newReels
                isRefreshing = false
            }
        }
    }
    
    private func loadMoreReels() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            let newReels = await reelService.getNextBatch()
            await MainActor.run {
                reels.append(contentsOf: newReels)
                isLoadingMore = false
            }
        }
    }
    
    // MARK: - Event Handlers
    private func handleReelAppear(reel: Reel, index: Int) {
        viewStartTimes[reel.id] = Date()
        
        // Preload more reels if approaching end
        if index >= reels.count - 3 {
            loadMoreReels()
        }
    }
    
    private func handleReelDisappear(reel: Reel) {
        guard let startTime = viewStartTimes[reel.id] else { return }
        
        let viewTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)
        reelService.logInteraction(reelId: reel.id, viewTimeMs: viewTimeMs)
        
        viewStartTimes.removeValue(forKey: reel.id)
    }
    
    private func handleLike(reelId: UUID) {
        let isNowLiked = likedReels.contains(reelId)
        reelService.logInteraction(reelId: reelId, liked: isNowLiked)
    }
    
    private func handleSave(reelId: UUID, isSaved: Bool) {
        print("💾 handleSave called for reel \(reelId), isSaved: \(isSaved)")
        reelService.logInteraction(reelId: reelId, saved: isSaved)
        print("💾 Logged interaction with saved=\(isSaved)")
    }
    
    private func handleMoreLikeThis(reelId: UUID) {
        print("👍 User tapped 'More like this' for reel \(reelId)")
        reelService.provideFeedback(reelId: reelId, moreLikeThis: true)
    }
    
    private func handleLessLikeThis(reelId: UUID) {
        print("👎 User tapped 'Less like this' for reel \(reelId)")
        reelService.provideFeedback(reelId: reelId, moreLikeThis: false)
    }
}

// MARK: - First Time Prompt
struct FirstTimePromptView: View {
    let onDismiss: () -> Void
    @State private var selectedPreferences: Set<String> = []
    
    let preferenceOptions = [
        ("Study Skills", "book.fill", "study-skills"),
        ("Burnout Help", "flame.fill", "burnout"),
        ("Health Tips", "heart.fill", "health"),
        ("Motivation", "star.fill", "motivation"),
        ("Focus", "leaf.fill", "focus"),
        ("Productivity", "checkmark.circle.fill", "productivity")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)
                    
                    Text("Welcome to Reels")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Get personalized tips, facts, and motivation")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("What do you want more of?")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(preferenceOptions, id: \.2) { option in
                            PreferenceButton(
                                title: option.0,
                                icon: option.1,
                                isSelected: selectedPreferences.contains(option.2)
                            ) {
                                if selectedPreferences.contains(option.2) {
                                    selectedPreferences.remove(option.2)
                                } else {
                                    selectedPreferences.insert(option.2)
                                }
                            }
                        }
                    }
                }
                
                Button {
                    onDismiss()
                } label: {
                    Text("Start Exploring")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
        }
    }
}

struct PreferenceButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#667eea") : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Why This Sheet
struct WhyThisReelSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How Your Feed Works")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.top, 8)
                    
                    InfoSection(
                        icon: "heart.fill",
                        title: "Likes & Saves",
                        description: "When you like or save a reel, we show you more content like it."
                    )
                    
                    InfoSection(
                        icon: "hand.thumbsup.fill",
                        title: "Feedback",
                        description: "Use 'More like this' or 'Less like this' to fine-tune your feed instantly."
                    )
                    
                    InfoSection(
                        icon: "clock.fill",
                        title: "Watch Time",
                        description: "The longer you watch, the more we know you're interested in that topic."
                    )
                    
                    InfoSection(
                        icon: "sparkles",
                        title: "Explore",
                        description: "We occasionally show new topics to help you discover helpful content."
                    )
                    
                    Text("Your feed gets better the more you use it. Like what helps, skip what doesn't.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: "#667eea"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
