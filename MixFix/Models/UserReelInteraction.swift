//
//  UserReelInteraction.swift
//  MixFix
//

import Foundation
import SwiftData

// MARK: - User Interaction Tracking
@Model
class UserReelInteractionSD {
    var userId: String
    var reelId: UUID
    var liked: Bool
    var saved: Bool
    var shown: Bool
    var viewTimeMs: Int
    var completed: Bool
    var skippedFast: Bool
    var reported: Bool
    var timestamp: Date
    
    init(
        userId: String,
        reelId: UUID,
        liked: Bool = false,
        saved: Bool = false,
        shown: Bool = true,
        viewTimeMs: Int = 0,
        completed: Bool = false,
        skippedFast: Bool = false,
        reported: Bool = false,
        timestamp: Date = Date()
    ) {
        self.userId = userId
        self.reelId = reelId
        self.liked = liked
        self.saved = saved
        self.shown = shown
        self.viewTimeMs = viewTimeMs
        self.completed = completed
        self.skippedFast = skippedFast
        self.reported = reported
        self.timestamp = timestamp
    }
}

// MARK: - In-Memory Interaction Model
struct UserReelInteraction: Codable {
    let userId: String
    let reelId: UUID
    var liked: Bool
    var saved: Bool
    var shown: Bool
    var viewTimeMs: Int
    var completed: Bool
    var skippedFast: Bool
    var timestamp: Date
    
    init(from interactionSD: UserReelInteractionSD) {
        self.userId = interactionSD.userId
        self.reelId = interactionSD.reelId
        self.liked = interactionSD.liked
        self.saved = interactionSD.saved
        self.shown = interactionSD.shown
        self.viewTimeMs = interactionSD.viewTimeMs
        self.completed = interactionSD.completed
        self.skippedFast = interactionSD.skippedFast
        self.timestamp = interactionSD.timestamp
    }
}

// MARK: - User Preferences Model
@Model
class UserReelPreferencesSD {
    @Attribute(.unique) var userId: String
    var topicAffinities: [String: Double] // tag -> score
    var typeAffinities: [String: Double] // type -> score
    var recentlyShownReelIds: [UUID]
    var blockedTags: [String]
    var exploreRate: Double
    var lastUpdated: Date
    
    init(
        userId: String,
        topicAffinities: [String: Double] = [:],
        typeAffinities: [String: Double] = [:],
        recentlyShownReelIds: [UUID] = [],
        blockedTags: [String] = [],
        exploreRate: Double = 0.2,
        lastUpdated: Date = Date()
    ) {
        self.userId = userId
        self.topicAffinities = topicAffinities
        self.typeAffinities = typeAffinities
        self.recentlyShownReelIds = recentlyShownReelIds
        self.blockedTags = blockedTags
        self.exploreRate = exploreRate
        self.lastUpdated = lastUpdated
    }
}

// MARK: - In-Memory Preferences Model
struct UserReelPreferences: Codable {
    let userId: String
    var topicAffinities: [String: Double]
    var typeAffinities: [String: Double]
    var recentlyShownReelIds: [UUID]
    var blockedTags: [String]
    var exploreRate: Double
    var lastUpdated: Date
    
    init(from preferencesSD: UserReelPreferencesSD) {
        self.userId = preferencesSD.userId
        self.topicAffinities = preferencesSD.topicAffinities
        self.typeAffinities = preferencesSD.typeAffinities
        self.recentlyShownReelIds = preferencesSD.recentlyShownReelIds
        self.blockedTags = preferencesSD.blockedTags
        self.exploreRate = preferencesSD.exploreRate
        self.lastUpdated = preferencesSD.lastUpdated
    }
}
