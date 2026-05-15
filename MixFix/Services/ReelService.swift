//
//  ReelService.swift
//  MixFix
//

import Foundation
import SwiftData
import Combine

class ReelService: ObservableObject {
    @Published var currentFeed: [Reel] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private let userId: String
    private var cachedReels: [Reel] = []
    
    // Scoring constants
    private let SCORE_LIKE: Double = 5.0
    private let SCORE_SAVE: Double = 4.0
    private let SCORE_VIEW_TIME: Double = 2.0
    private let SCORE_MORE_LIKE_THIS: Double = 3.0
    private let SCORE_UNLIKE: Double = -5.0
    private let SCORE_LESS_LIKE_THIS: Double = -3.0
    private let SCORE_FAST_SKIP: Double = -2.0
    
    private let BATCH_SIZE = 20
    private let PRELOAD_COUNT = 3
    private let DEDUP_WINDOW = 100  // Track last 100 reels to minimize short-term repeats
    private let MIN_VIEW_TIME_MS = 3000
    private let FAST_SKIP_THRESHOLD_MS = 800
    
    init(userId: String) {
        self.userId = userId
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("🎬 ReelService: Model context set")
        loadSeedContent()
    }
    
    // MARK: - Feed Generation
    func getNextBatch() async -> [Reel] {
        guard modelContext != nil else {
            print("🎬 ReelService: ❌ No model context in getNextBatch")
            return []
        }
        
        print("🎬 ReelService: Getting next batch...")
        
        isLoading = true
        defer { isLoading = false }
        
        // Get user preferences
        let preferences = getUserPreferences()
        print("🎬 ReelService: Recently shown reels: \(preferences.recentlyShownReelIds.count)")
        
        // Get candidate reels (excluding recently viewed reels)
        var candidates = getCandidateReels(excluding: preferences.recentlyShownReelIds)
        print("🎬 ReelService: Found \(candidates.count) candidate reels")
        
        // If no candidates found, reset the exclusion list so reels can repeat
        if candidates.isEmpty {
            print("🎬 ReelService: All reels shown, resetting to show them again...")
            clearRecentlyShown()
            candidates = getCandidateReels(excluding: [])
            print("🎬 ReelService: After reset, found \(candidates.count) candidate reels")
        }
        
        guard !candidates.isEmpty else {
            print("🎬 ReelService: ❌ No candidates found even after reset!")
            return []
        }
        
        // Score and rank
        let scored = candidates.map { reel in
            (reel: reel, score: scoreReel(reel, preferences: preferences))
        }.sorted { $0.score > $1.score }
        
        // Apply variety rules and select batch
        let selected = applyVarietyRules(scored.map { $0.reel }, preferences: preferences)
        print("🎬 ReelService: Selected \(selected.count) reels for batch")
        
        // Update recently shown
        updateRecentlyShown(reelIds: selected.map { $0.id })
        
        let batch = Array(selected.prefix(BATCH_SIZE))
        print("🎬 ReelService: ✅ Returning batch of \(batch.count) reels")
        return batch
    }
    
    private func getCandidateReels(excluding: [UUID]) -> [Reel] {
        guard let modelContext = modelContext else {
            print("🎬 getCandidateReels: No model context")
            return []
        }
        
        let descriptor = FetchDescriptor<ReelSD>()
        
        // Try to fetch and handle errors explicitly
        do {
            let reelSDs = try modelContext.fetch(descriptor)
            print("🎬 getCandidateReels: ✅ Fetched \(reelSDs.count) reels from DB")
            
            if reelSDs.isEmpty {
                // Double check with count
                if let count = try? modelContext.fetchCount(descriptor) {
                    print("🎬 getCandidateReels: ⚠️ Fetch returned empty but count shows \(count) reels")
                }
            }
            
            print("🎬 getCandidateReels: Excluding \(excluding.count) reels")
            
            let filtered = reelSDs.filter { !excluding.contains($0.id) }
            print("🎬 getCandidateReels: \(filtered.count) reels after exclusion filter")
            
            let converted = filtered.map { Reel(from: $0) }
            print("🎬 getCandidateReels: \(converted.count) reels after conversion to Reel")
            
            return converted
        } catch {
            print("🎬 getCandidateReels: ❌ Fetch error: \(error)")
            return []
        }
    }
    
    private func scoreReel(_ reel: Reel, preferences: UserReelPreferences) -> Double {
        var score: Double = 0.0
        var scoreBreakdown: [String] = []
        
        // Base popularity score
        let popularityScore = Double(reel.globalLikes) / max(Double(reel.globalViews), 1.0)
        let popularityPoints = popularityScore * 10
        score += popularityPoints
        scoreBreakdown.append("Popularity: +\(String(format: "%.1f", popularityPoints))")
        
        // Topic affinity
        var topicScore: Double = 0
        for tag in reel.topicTags {
            if let affinity = preferences.topicAffinities[tag] {
                topicScore += affinity
                scoreBreakdown.append("Topic '\(tag)': \(affinity > 0 ? "+" : "")\(String(format: "%.1f", affinity))")
            }
        }
        score += topicScore
        
        // Type affinity
        if let typeAffinity = preferences.typeAffinities[reel.type.rawValue] {
            score += typeAffinity
            scoreBreakdown.append("Type '\(reel.type.rawValue)': \(typeAffinity > 0 ? "+" : "")\(String(format: "%.1f", typeAffinity))")
        }
        
        // Recency boost (newer content gets slight boost)
        let daysSinceCreation = Date().timeIntervalSince(reel.createdAt) / 86400
        if daysSinceCreation < 7 {
            let recencyBoost = (7 - daysSinceCreation) * 0.5
            score += recencyBoost
            scoreBreakdown.append("Recency: +\(String(format: "%.1f", recencyBoost))")
        }
        
        // Penalty for blocked tags
        for tag in reel.topicTags {
            if preferences.blockedTags.contains(tag) {
                score -= 100 // Effectively removes it
                scoreBreakdown.append("Blocked tag '\(tag)': -100")
            }
        }
        
        // Log every 5th reel to avoid spam
        if Int.random(in: 0..<5) == 0 {
            print("📊 Scoring reel \(reel.type.rawValue): Total=\(String(format: "%.1f", score)) [\(scoreBreakdown.joined(separator: ", "))]")
        }
        
        return score
    }
    
    private func applyVarietyRules(_ reels: [Reel], preferences: UserReelPreferences) -> [Reel] {
        var selected: [Reel] = []
        var lastType: Reel.ReelType?
        var sameTypeCount = 0
        var exploreInserted = 0
        
        for (_, reel) in reels.enumerated() {
            // Don't show same type more than 2 times in a row
            if reel.type == lastType {
                sameTypeCount += 1
                if sameTypeCount >= 2 {
                    continue
                }
            } else {
                sameTypeCount = 0
                lastType = reel.type
            }
            
            selected.append(reel)
            
            // Insert explore reel every 5 items
            if (selected.count + 1) % 5 == 0 && exploreInserted < 3 {
                if let exploreReel = getExploreReel(excluding: selected.map { $0.id }, preferences: preferences) {
                    selected.append(exploreReel)
                    exploreInserted += 1
                }
            }
            
            if selected.count >= BATCH_SIZE {
                break
            }
        }
        
        return selected
    }
    
    private func getExploreReel(excluding: [UUID], preferences: UserReelPreferences) -> Reel? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<ReelSD>()
        guard let reelSDs = try? modelContext.fetch(descriptor) else { return nil }
        
        // Find reels with tags user hasn't seen much
        let lowAffinityReels = reelSDs
            .filter { !excluding.contains($0.id) }
            .map { Reel(from: $0) }
            .filter { reel in
                reel.topicTags.allSatisfy { tag in
                    (preferences.topicAffinities[tag] ?? 0) < 2.0
                }
            }
        
        return lowAffinityReels.randomElement()
    }
    
    // MARK: - User Preferences
    private func getUserPreferences() -> UserReelPreferences {
        guard let modelContext = modelContext else {
            return createDefaultPreferences()
        }
        
        let descriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let preferencesSD = try? modelContext.fetch(descriptor).first {
            return UserReelPreferences(from: preferencesSD)
        } else {
            return createDefaultPreferences()
        }
    }
    
    private func createDefaultPreferences() -> UserReelPreferences {
        UserReelPreferences(
            from: UserReelPreferencesSD(
                userId: userId,
                topicAffinities: [:],
                typeAffinities: [
                    "study_tip": 2.0,
                    "burnout": 1.5,
                    "health_fact": 1.0,
                    "motivation": 1.0
                ],
                exploreRate: 0.2
            )
        )
    }
    
    private func updateRecentlyShown(reelIds: [UUID]) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let preferencesSD = try? modelContext.fetch(descriptor).first {
            var recent = preferencesSD.recentlyShownReelIds
            recent.append(contentsOf: reelIds)
            // Keep last 100 reels to minimize short-term repeats while allowing cycling
            preferencesSD.recentlyShownReelIds = Array(recent.suffix(DEDUP_WINDOW))
            try? modelContext.save()
            print("🎬 ReelService: ✅ Tracking last \(preferencesSD.recentlyShownReelIds.count) viewed reels")
        }
    }
    
    func clearRecentlyShown() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let preferencesSD = try? modelContext.fetch(descriptor).first {
            preferencesSD.recentlyShownReelIds = []
            try? modelContext.save()
            print("🎬 ReelService: ✅ Cleared recently shown list")
        }
    }
    
    func markReelsAsShown(reelIds: [UUID]) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let preferencesSD = try? modelContext.fetch(descriptor).first {
            var recent = preferencesSD.recentlyShownReelIds
            recent.append(contentsOf: reelIds)
            // Keep last 100 reels to minimize short-term repeats
            preferencesSD.recentlyShownReelIds = Array(recent.suffix(DEDUP_WINDOW))
            try? modelContext.save()
            print("🔄 ReelService: Marked \(reelIds.count) reels as shown. Total tracked: \(preferencesSD.recentlyShownReelIds.count)")
        }
    }
    
    // MARK: - Interactions
    func logInteraction(reelId: UUID, liked: Bool? = nil, saved: Bool? = nil, viewTimeMs: Int? = nil, skipped: Bool = false) {
        guard let modelContext = modelContext else { return }
        
        print("💾 ReelService.logInteraction called for userId: \(userId), reelId: \(reelId)")
        
        // Find or create interaction
        let descriptor = FetchDescriptor<UserReelInteractionSD>(
            predicate: #Predicate { $0.userId == userId && $0.reelId == reelId }
        )
        
        let interaction: UserReelInteractionSD
        if let existing = try? modelContext.fetch(descriptor).first {
            interaction = existing
            print("💾 ReelService: Found existing interaction")
        } else {
            interaction = UserReelInteractionSD(userId: userId, reelId: reelId)
            modelContext.insert(interaction)
            print("💾 ReelService: Created new interaction")
        }
        
        // Update interaction
        if let liked = liked {
            interaction.liked = liked
            print("💾 ReelService: Updated liked=\(liked) for reel \(reelId)")
        }
        if let saved = saved {
            interaction.saved = saved
            print("💾 ReelService: Updated saved=\(saved) for reel \(reelId)")
        }
        if let viewTimeMs = viewTimeMs {
            interaction.viewTimeMs = viewTimeMs
            interaction.completed = viewTimeMs >= MIN_VIEW_TIME_MS
            interaction.skippedFast = viewTimeMs < FAST_SKIP_THRESHOLD_MS
        }
        
        do {
            try modelContext.save()
            print("💾 ReelService: ✅ Successfully saved interaction to database")
        } catch {
            print("💾 ReelService: ❌ Error saving interaction: \(error)")
        }
        
        // Update preferences based on interaction
        updatePreferencesFromInteraction(reelId: reelId, interaction: interaction)
    }
    
    private func updatePreferencesFromInteraction(reelId: UUID, interaction: UserReelInteractionSD) {
        guard let modelContext = modelContext else { return }
        
        // Get the reel
        let reelDescriptor = FetchDescriptor<ReelSD>(
            predicate: #Predicate { $0.id == reelId }
        )
        guard let reelSD = try? modelContext.fetch(reelDescriptor).first else { return }
        
        // Get preferences
        let prefDescriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        let preferences: UserReelPreferencesSD
        if let existing = try? modelContext.fetch(prefDescriptor).first {
            preferences = existing
        } else {
            preferences = UserReelPreferencesSD(userId: userId)
            modelContext.insert(preferences)
        }
        
        // Calculate score delta
        var scoreDelta: Double = 0
        if interaction.liked { scoreDelta += SCORE_LIKE }
        if interaction.saved { scoreDelta += SCORE_SAVE }
        if interaction.completed { scoreDelta += SCORE_VIEW_TIME }
        if interaction.skippedFast { scoreDelta += SCORE_FAST_SKIP }
        
        // Update topic affinities
        for tag in reelSD.topicTags {
            let current = preferences.topicAffinities[tag] ?? 0
            preferences.topicAffinities[tag] = current + scoreDelta
        }
        
        // Update type affinity
        let currentType = preferences.typeAffinities[reelSD.type] ?? 0
        preferences.typeAffinities[reelSD.type] = currentType + scoreDelta
        
        preferences.lastUpdated = Date()
        try? modelContext.save()
    }
    
    func provideFeedback(reelId: UUID, moreLikeThis: Bool) {
        guard let modelContext = modelContext else { return }
        
        print("👍👎 provideFeedback called: \(moreLikeThis ? "MORE" : "LESS") like this for reel \(reelId)")
        
        let reelDescriptor = FetchDescriptor<ReelSD>(
            predicate: #Predicate { $0.id == reelId }
        )
        guard let reelSD = try? modelContext.fetch(reelDescriptor).first else {
            print("👍👎 ❌ Reel not found")
            return
        }
        
        print("👍👎 Reel type: \(reelSD.type), topics: \(reelSD.topicTags)")
        
        let prefDescriptor = FetchDescriptor<UserReelPreferencesSD>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        let preferences: UserReelPreferencesSD
        if let existing = try? modelContext.fetch(prefDescriptor).first {
            preferences = existing
        } else {
            preferences = UserReelPreferencesSD(userId: userId)
            modelContext.insert(preferences)
        }
        
        let scoreDelta = moreLikeThis ? SCORE_MORE_LIKE_THIS : SCORE_LESS_LIKE_THIS
        
        print("👍👎 Applying score delta: \(scoreDelta > 0 ? "+" : "")\(scoreDelta)")
        
        // Update topic affinities
        for tag in reelSD.topicTags {
            let oldScore = preferences.topicAffinities[tag] ?? 0
            let newScore = oldScore + scoreDelta
            preferences.topicAffinities[tag] = newScore
            print("👍👎   Topic '\(tag)': \(oldScore) → \(newScore)")
        }
        
        // Update type affinity
        let oldTypeScore = preferences.typeAffinities[reelSD.type] ?? 0
        let newTypeScore = oldTypeScore + scoreDelta
        preferences.typeAffinities[reelSD.type] = newTypeScore
        print("👍👎   Type '\(reelSD.type)': \(oldTypeScore) → \(newTypeScore)")
        
        do {
            try modelContext.save()
            print("👍👎 ✅ Preferences saved successfully")
        } catch {
            print("👍👎 ❌ Error saving preferences: \(error)")
        }
    }
    
    // MARK: - Seed Content
    private func loadSeedContent() {
        guard let modelContext = modelContext else {
            print("🎬 ReelService: ❌ No model context for seed content")
            return
        }
        
        // Check if content already exists
        let descriptor = FetchDescriptor<ReelSD>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            print("🎬 ReelService: Seed content already exists (\(count) reels)")
            return
        }
        
        print("🎬 ReelService: Creating seed content...")
        
        // Create seed reels
        let seedReels = createSeedReels()
        for reelSD in seedReels {
            modelContext.insert(reelSD)
        }
        
        do {
            try modelContext.save()
            print("🎬 ReelService: ✅ Saved \(seedReels.count) seed reels")
            
            // Verify the save by immediately fetching
            let verifyDescriptor = FetchDescriptor<ReelSD>()
            if let savedCount = try? modelContext.fetchCount(verifyDescriptor) {
                print("🎬 ReelService: ✅ Verified: \(savedCount) reels in DB after save")
            }
        } catch {
            print("🎬 ReelService: ❌ Error saving seed content: \(error)")
        }
    }
    
    private func createSeedReels() -> [ReelSD] {
        return [
            // Study Tips
            ReelSD(
                type: "study_tip",
                topicTags: ["study-skills", "memory", "productivity"],
                textBody: "Pomodoro with a twist: Study 25 min, then teach it to yourself out loud for 5 min. Speaking = deeper memory.",
                actionPrompt: "Try this now: Set a 25-min timer and explain your last topic out loud after."
            ),
            ReelSD(
                type: "study_tip",
                topicTags: ["note-taking", "study-skills"],
                textBody: "Handwrite your notes, even if you have a laptop. Your brain processes writing differently than typing.",
                actionPrompt: "Next class: Bring a notebook and handwrite key concepts.",
                sourceLink: "Princeton University Study, 2014"
            ),
            ReelSD(
                type: "study_tip",
                topicTags: ["test-prep", "memory"],
                textBody: "Quiz yourself BEFORE you feel ready. Testing = learning, not just assessment. Fail early, remember longer.",
                actionPrompt: "Right now: Close your notes and write down 3 things you just studied."
            ),
            ReelSD(
                type: "study_tip",
                topicTags: ["focus", "productivity", "time-management"],
                textBody: "Study in 90-min blocks max. Your brain's ultradian rhythm peaks at 90 min, then needs a break.",
                actionPrompt: "Set a 90-min timer. When it rings, take a real 15-min break."
            ),
            ReelSD(
                type: "study_tip",
                topicTags: ["procrastination", "productivity"],
                textBody: "Can't start? Do the 2-minute rule: commit to just 2 minutes. Starting is the hardest part.",
                actionPrompt: "Open your work and do literally 2 minutes. That's it."
            ),
            
            // Burnout
            ReelSD(
                type: "burnout",
                topicTags: ["burnout", "mental-health", "stress"],
                textBody: "Feeling drained? Your brain needs glucose. Grab a snack + 10 min walk. Movement + fuel = reset.",
                actionPrompt: "Stand up right now. Walk for 2 minutes. Eat something."
            ),
            ReelSD(
                type: "burnout",
                topicTags: ["burnout", "rest"],
                textBody: "Burnout isn't fixed by a weekend. It's fixed by daily micro-rests. 5 min every 2 hours > one long break.",
                actionPrompt: "Set a recurring alarm: every 2 hours, stop for 5 minutes."
            ),
            ReelSD(
                type: "burnout",
                topicTags: ["stress", "anxiety"],
                textBody: "Overwhelmed? Write down everything you need to do. Your brain stops looping when it's on paper.",
                actionPrompt: "Open your notes app. Brain dump everything for 3 minutes."
            ),
            ReelSD(
                type: "burnout",
                topicTags: ["burnout", "boundaries"],
                textBody: "You don't have to respond immediately. Delayed response ≠ bad student. Protect your focus time.",
                actionPrompt: "Turn off non-urgent notifications for the next hour."
            ),
            
            // Health Facts
            ReelSD(
                type: "health_fact",
                topicTags: ["sleep", "health", "memory"],
                textBody: "Sleep < 7 hrs? Your memory consolidation drops 40%. One extra hour = better recall tomorrow.",
                actionPrompt: "Tonight: Set a bedtime alarm 8 hours before you wake up.",
                sourceLink: "Sleep Research Society"
            ),
            ReelSD(
                type: "health_fact",
                topicTags: ["hydration", "health", "focus"],
                textBody: "Dehydration = brain fog. Even 2% dehydration reduces cognitive performance. Water > coffee for focus.",
                actionPrompt: "Drink a full glass of water right now."
            ),
            ReelSD(
                type: "health_fact",
                topicTags: ["exercise", "health", "stress"],
                textBody: "20 min of movement = 2 hours of reduced anxiety. Your body processes stress through motion.",
                actionPrompt: "Next break: Walk, stretch, or dance for 5 minutes."
            ),
            ReelSD(
                type: "health_fact",
                topicTags: ["nutrition", "health", "energy"],
                textBody: "Protein + complex carbs = sustained energy. Sugar crash = focus crash. Choose snacks wisely.",
                actionPrompt: "Next snack: Pick something with protein (nuts, yogurt, cheese)."
            ),
            
            // Student Facts
            ReelSD(
                type: "student_fact",
                topicTags: ["student-life", "study-skills"],
                textBody: "Students who handwrite notes score 23% higher on concept tests vs laptop typers.",
                actionPrompt: "Try handwriting your next set of notes.",
                sourceLink: "Princeton Study"
            ),
            ReelSD(
                type: "student_fact",
                topicTags: ["student-life", "time-management"],
                textBody: "The average student checks their phone 96 times per day. That's every 10 minutes during waking hours.",
                actionPrompt: "Put your phone in another room for the next study session."
            ),
            ReelSD(
                type: "student_fact",
                topicTags: ["student-life", "productivity"],
                textBody: "Peak cognitive performance happens 2-4 hours after waking. Schedule hard tasks for your morning.",
                actionPrompt: "Tomorrow: Do your hardest task within 3 hours of waking up."
            ),
            
            // Motivation
            ReelSD(
                type: "motivation",
                topicTags: ["motivation", "mindset"],
                textBody: "You're not behind. You're exactly where you need to be. Progress > perfection.",
                actionPrompt: "Write down one thing you did well today. Just one."
            ),
            ReelSD(
                type: "motivation",
                topicTags: ["motivation", "growth"],
                textBody: "Every expert was once a beginner who didn't quit. Your confusion today = your clarity tomorrow.",
                actionPrompt: "Keep going. You're learning, even when it feels hard."
            ),
            ReelSD(
                type: "motivation",
                topicTags: ["motivation", "self-compassion"],
                textBody: "Bad study session? That's data, not failure. Adjust and try again. You're experimenting, not failing.",
                actionPrompt: "What's one small thing you can change for next time?"
            ),
            ReelSD(
                type: "motivation",
                topicTags: ["motivation", "resilience"],
                textBody: "The difference between good and great students? Great students keep showing up on bad days.",
                actionPrompt: "Show up today, even if it's just for 10 minutes."
            ),
            
            // Micro-Meditations
            ReelSD(
                type: "micro_meditation",
                topicTags: ["focus", "mindfulness", "stress"],
                textBody: "Close your eyes. Breathe in for 4, hold for 4, out for 6. Repeat 3x. Your nervous system just reset.",
                actionPrompt: "Do it now: 4-4-6 breathing, three times."
            ),
            ReelSD(
                type: "micro_meditation",
                topicTags: ["focus", "mindfulness"],
                textBody: "Can't focus? Name 5 things you can see, 4 you can touch, 3 you can hear. Instant presence.",
                actionPrompt: "Try it: 5-4-3 grounding technique, right now."
            ),
            ReelSD(
                type: "micro_meditation",
                topicTags: ["stress", "mindfulness"],
                textBody: "Tense every muscle for 5 seconds, then release. Progressive relaxation = instant calm.",
                actionPrompt: "Tense your whole body. Hold. Release. Feel the difference."
            ),
            ReelSD(
                type: "micro_meditation",
                topicTags: ["focus", "productivity"],
                textBody: "Before you start: Set an intention. 'For the next 25 min, I'm focusing on X.' Clarity = momentum.",
                actionPrompt: "Say out loud: 'For the next 25 minutes, I'm working on _____.'"
            )
        ]
    }
}
