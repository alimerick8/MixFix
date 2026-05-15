//
//  Reel.swift
//  MixFix
//

import Foundation
import SwiftData

// MARK: - Reel Content Model
@Model
class ReelSD {
    @Attribute(.unique) var id: UUID
    var type: String // study_tip, burnout, health_fact, student_fact, motivation, micro_meditation
    var topicTags: [String]
    var difficultyLevel: String?
    var textTitle: String?
    var textBody: String
    var actionPrompt: String
    var sourceLink: String?
    var createdAt: Date
    var language: String
    var globalLikes: Int
    var globalViews: Int
    var safetyFlags: [String]
    
    init(
        id: UUID = UUID(),
        type: String,
        topicTags: [String],
        difficultyLevel: String? = nil,
        textTitle: String? = nil,
        textBody: String,
        actionPrompt: String,
        sourceLink: String? = nil,
        createdAt: Date = Date(),
        language: String = "en",
        globalLikes: Int = 0,
        globalViews: Int = 0,
        safetyFlags: [String] = []
    ) {
        self.id = id
        self.type = type
        self.topicTags = topicTags
        self.difficultyLevel = difficultyLevel
        self.textTitle = textTitle
        self.textBody = textBody
        self.actionPrompt = actionPrompt
        self.sourceLink = sourceLink
        self.createdAt = createdAt
        self.language = language
        self.globalLikes = globalLikes
        self.globalViews = globalViews
        self.safetyFlags = safetyFlags
    }
}

// MARK: - In-Memory Reel Model
struct Reel: Identifiable, Codable {
    let id: UUID
    let type: ReelType
    let topicTags: [String]
    let difficultyLevel: String?
    let textTitle: String?
    let textBody: String
    let actionPrompt: String
    let sourceLink: String?
    let createdAt: Date
    let language: String
    var globalLikes: Int
    var globalViews: Int
    
    enum ReelType: String, Codable, CaseIterable {
        case studyTip = "study_tip"
        case burnout = "burnout"
        case healthFact = "health_fact"
        case studentFact = "student_fact"
        case motivation = "motivation"
        case microMeditation = "micro_meditation"
        
        var displayName: String {
            switch self {
            case .studyTip: return "Study Skills"
            case .burnout: return "Burnout"
            case .healthFact: return "Health"
            case .studentFact: return "Student Life"
            case .motivation: return "Motivation"
            case .microMeditation: return "Focus"
            }
        }
        
        var icon: String {
            switch self {
            case .studyTip: return "book.fill"
            case .burnout: return "flame.fill"
            case .healthFact: return "heart.fill"
            case .studentFact: return "lightbulb.fill"
            case .motivation: return "star.fill"
            case .microMeditation: return "leaf.fill"
            }
        }
        
        var gradientColors: [String] {
            switch self {
            case .studyTip: return ["#667eea", "#764ba2"]
            case .burnout: return ["#f093fb", "#f5576c"]
            case .healthFact: return ["#4facfe", "#00f2fe"]
            case .studentFact: return ["#43e97b", "#38f9d7"]
            case .motivation: return ["#fa709a", "#fee140"]
            case .microMeditation: return ["#30cfd0", "#330867"]
            }
        }
    }
    
    init(from reelSD: ReelSD) {
        self.id = reelSD.id
        self.type = ReelType(rawValue: reelSD.type) ?? .studyTip
        self.topicTags = reelSD.topicTags
        self.difficultyLevel = reelSD.difficultyLevel
        self.textTitle = reelSD.textTitle
        self.textBody = reelSD.textBody
        self.actionPrompt = reelSD.actionPrompt
        self.sourceLink = reelSD.sourceLink
        self.createdAt = reelSD.createdAt
        self.language = reelSD.language
        self.globalLikes = reelSD.globalLikes
        self.globalViews = reelSD.globalViews
    }
}
