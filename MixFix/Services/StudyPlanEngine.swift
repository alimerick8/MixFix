import Foundation

struct ExamProfile: Identifiable, Codable {
    var id: String
    var examId: String
    var examName: String
    var examDate: Date
    var targetScore: Int?
    var diagnosticScore: Int?
    var hoursPerWeekAvailable: Double
    var preferredBlockMinutes: Int
    var hasTeacher: Bool
    var hasTutor: Bool
    var resources: [String]
    var sections: [ExamSectionProfile]
}

struct ExamSectionProfile: Identifiable, Codable {
    var id: String
    var name: String
    var confidence: Double
    var mastery: Double
    var priorityWeight: Double
}

enum StudyActivityType: String, Codable {
    case content
    case practiceProblems
    case timedSection
    case reviewAndRecall
    case misc
}

struct StudySession: Identifiable, Codable {
    var id: String
    var examProfileId: String
    var sectionId: String
    var date: Date
    var activityType: StudyActivityType
    var plannedDurationMinutes: Int
    var actualDurationMinutes: Int?
    var selfRating: Int?
    var questionsAttempted: Int?
    var questionsCorrect: Int?
    var notes: String?
}

struct StudyPlanDay: Identifiable, Codable {
    var id: String
    var examProfileId: String
    var date: Date
    var items: [StudyPlanItem]
}

struct StudyPlanItem: Identifiable, Codable {
    var id: String
    var sectionId: String
    var activityType: StudyActivityType
    var durationMinutes: Int
    var description: String
    var isCompleted: Bool
}

struct StudyPlanEngine {
    func generateStudyPlanDay(
        for profile: ExamProfile,
        on date: Date,
        history: [StudySession]
    ) -> StudyPlanDay {
        let calendar = Calendar.current
        let startToday = calendar.startOfDay(for: date)
        let daysUntilExam = calendar.dateComponents([.day], from: startToday, to: calendar.startOfDay(for: profile.examDate)).day ?? 0
        let phase = phaseForDaysLeft(daysUntilExam)
        let activityMix = activityMixForPhase(phase)
        let dailyMinutes = dailyMinutesTarget(hoursPerWeek: profile.hoursPerWeekAvailable)
        let blocks = makeBlocks(totalMinutes: dailyMinutes, blockSize: profile.preferredBlockMinutes)
        let sections = normalizedSections(profile.sections)
        let items = makeItems(blockCount: blocks.count, blockSize: profile.preferredBlockMinutes, phase: phase, mix: activityMix, sections: sections)
        let adjustedItems = adjustLastBlockDuration(items: items, totalMinutes: dailyMinutes)
        return StudyPlanDay(
            id: "\(profile.id)_\(dateFormatter.string(from: startToday))",
            examProfileId: profile.id,
            date: startToday,
            items: adjustedItems
        )
    }
    
    private enum Phase {
        case far
        case mid
        case close
        case lastWeek
    }
    
    private func phaseForDaysLeft(_ days: Int) -> Phase {
        if days > 60 { return .far }
        if days > 30 { return .mid }
        if days > 7 { return .close }
        return .lastWeek
    }
    
    private func activityMixForPhase(_ phase: Phase) -> [(StudyActivityType, Double)] {
        switch phase {
        case .far:
            return [(.content, 0.6), (.practiceProblems, 0.3), (.reviewAndRecall, 0.1)]
        case .mid:
            return [(.content, 0.4), (.practiceProblems, 0.4), (.reviewAndRecall, 0.2)]
        case .close:
            return [(.content, 0.2), (.practiceProblems, 0.4), (.timedSection, 0.2), (.reviewAndRecall, 0.2)]
        case .lastWeek:
            return [(.content, 0.1), (.practiceProblems, 0.35), (.timedSection, 0.35), (.reviewAndRecall, 0.2)]
        }
    }
    
    private func dailyMinutesTarget(hoursPerWeek: Double) -> Int {
        let weeklyMinutes = hoursPerWeek * 60.0
        let daily = weeklyMinutes / 6.0
        return max(30, Int(daily.rounded()))
    }
    
    private func makeBlocks(totalMinutes: Int, blockSize: Int) -> [Int] {
        let clampedBlock = max(20, min(blockSize, 90))
        var remaining = totalMinutes
        var blocks: [Int] = []
        while remaining > 0 && blocks.count < 6 {
            let next = min(clampedBlock, remaining)
            blocks.append(next)
            remaining -= next
        }
        if blocks.count < 2 && totalMinutes >= clampedBlock {
            return [clampedBlock, max(15, totalMinutes - clampedBlock)]
        }
        return blocks
    }
    
    private func normalizedSections(_ sections: [ExamSectionProfile]) -> [ExamSectionProfile] {
        guard !sections.isEmpty else { return [] }
        var scores: [Double] = []
        for s in sections {
            let weakness = (100.0 - s.mastery) * 0.6 + (100.0 - s.confidence) * 0.4
            scores.append(max(0, weakness))
        }
        let minFloor = 0.15
        var adjusted = scores
        let total = scores.reduce(0, +)
        if total > 0 {
            for idx in scores.indices {
                let p = scores[idx] / total
                adjusted[idx] = max(minFloor, p)
            }
        } else {
            adjusted = Array(repeating: 1.0 / Double(sections.count), count: sections.count)
        }
        let sumAdjusted = adjusted.reduce(0, +)
        return sections.enumerated().map { (index, section) in
            let weight = sumAdjusted > 0 ? adjusted[index] / sumAdjusted : 1.0 / Double(sections.count)
            return ExamSectionProfile(
                id: section.id,
                name: section.name,
                confidence: section.confidence,
                mastery: section.mastery,
                priorityWeight: weight
            )
        }
    }
    
    private func makeItems(
        blockCount: Int,
        blockSize: Int,
        phase: Phase,
        mix: [(StudyActivityType, Double)],
        sections: [ExamSectionProfile]
    ) -> [StudyPlanItem] {
        guard blockCount > 0 else { return [] }
        var items: [StudyPlanItem] = []
        let activities = expandedActivities(blockCount: blockCount, mix: mix)
        let orderedSections = orderedSectionsForBlocks(count: blockCount, sections: sections)
        for i in 0..<blockCount {
            let activity = activities[i]
            let section = orderedSections[i]
            let description = descriptionTemplate(sectionName: section.name, activity: activity)
            let item = StudyPlanItem(
                id: UUID().uuidString,
                sectionId: section.id,
                activityType: activity,
                durationMinutes: blockSize,
                description: description,
                isCompleted: false
            )
            items.append(item)
        }
        return items
    }
    
    private func expandedActivities(blockCount: Int, mix: [(StudyActivityType, Double)]) -> [StudyActivityType] {
        if blockCount <= 0 { return [] }
        var result: [StudyActivityType] = []
        let totalWeight = mix.reduce(0.0) { partial, pair in partial + pair.1 }
        for (activity, weight) in mix {
            let portion = totalWeight > 0 ? weight / totalWeight : 1.0 / Double(mix.count)
            let count = Int((portion * Double(blockCount)).rounded())
            result.append(contentsOf: Array(repeating: activity, count: max(1, count)))
        }
        while result.count > blockCount { _ = result.popLast() }
        while result.count < blockCount { result.append(result.last ?? .content) }
        return Array(result.prefix(blockCount))
    }
    
    private func orderedSectionsForBlocks(count: Int, sections: [ExamSectionProfile]) -> [ExamSectionProfile] {
        guard !sections.isEmpty else { return [] }
        let sorted = sections.sorted { $0.priorityWeight > $1.priorityWeight }
        var result: [ExamSectionProfile] = []
        var index = 0
        while result.count < count {
            result.append(sorted[index])
            index = (index + 1) % sorted.count
        }
        return result
    }
    
    private func descriptionTemplate(sectionName: String, activity: StudyActivityType) -> String {
        switch activity {
        case .content:
            return "Review \(sectionName) content. Pick 1–2 weak topics, use notes or a lesson, and write a short 3–4 sentence summary."
        case .practiceProblems:
            return "Do a \(sectionName) practice set (~20 questions). Move at exam pace, then mark missed questions."
        case .timedSection:
            return "Complete one full timed \(sectionName) section under real exam timing. Do not pause the timer."
        case .reviewAndRecall:
            return "Review missed \(sectionName) questions from recent practice. Write why the correct answer is right and your choice was wrong."
        case .misc:
            return "Work on any supporting task for \(sectionName): organize notes, formula sheets, or flashcards."
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    private func adjustLastBlockDuration(items: [StudyPlanItem], totalMinutes: Int) -> [StudyPlanItem] {
        guard !items.isEmpty else { return items }
        let perBlock = items.first!.durationMinutes
        let expectedTotal = perBlock * items.count
        let delta = totalMinutes - expectedTotal
        if abs(delta) < 5 { return items }
        var updated = items
        var last = updated.removeLast()
        last.durationMinutes = max(15, last.durationMinutes + delta)
        updated.append(last)
        return updated
    }
}
