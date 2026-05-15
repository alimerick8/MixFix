import Foundation
import Combine
import SwiftUI
// Study plan engine for adaptive Exam Mode
// (pure logic; UI uses helpers on ExamState to call into this)

// Global app mode for branching between Student and Exam experiences.
enum AppMode: String {
    case student
    case exam
}

// MARK: - Exam Section Templates

enum ExamSectionTemplates {
    static func templates(for examName: String) -> [ExamSectionTemplate] {
        let key = examName.lowercased()
        
        func contains(_ s: String) -> Bool { key.contains(s) }
        
        // Graduate / Professional School
        if contains("mcat") {
            return [
                .init(id: "bio_biochem", label: "Bio & Biochem"),
                .init(id: "chem_phys", label: "Chem & Physics"),
                .init(id: "psych_soc", label: "Psych & Soc"),
                .init(id: "cars", label: "Reading Passages")
            ]
        }
        if contains("lsat") {
            return [
                .init(id: "logic_games", label: "Logic Games"),
                .init(id: "reading_comp", label: "Reading Passages"),
                .init(id: "logical_reasoning", label: "Arguments & Reasoning")
            ]
        }
        if contains("gre") {
            return [
                .init(id: "quant", label: "Math Skills"),
                .init(id: "quant_word", label: "Word Problems"),
                .init(id: "verbal", label: "Vocabulary & Reading")
            ]
        }
        if contains("gmat") {
            return [
                .init(id: "quant", label: "Math Skills"),
                .init(id: "verbal", label: "Reading & Grammar"),
                .init(id: "data_insights", label: "Data & Charts"),
                .init(id: "integrated_reasoning", label: "Logic Problems")
            ]
        }
        if contains("dat") {
            return [
                .init(id: "natural_sciences", label: "Natural Sciences"),
                .init(id: "perceptual", label: "Visual Skills"),
                .init(id: "reading", label: "Reading Passages"),
                .init(id: "math", label: "Math Skills")
            ]
        }
        if contains("oat") {
            return [
                .init(id: "natural_sciences", label: "Natural Sciences"),
                .init(id: "physics", label: "Physics"),
                .init(id: "reading", label: "Reading Passages"),
                .init(id: "math", label: "Math Skills")
            ]
        }
        if contains("pcat") {
            return [
                .init(id: "biology", label: "Biology"),
                .init(id: "chemistry", label: "Chemistry"),
                .init(id: "reading", label: "Reading Passages"),
                .init(id: "writing", label: "Writing Skills"),
                .init(id: "math", label: "Math Skills")
            ]
        }
        if contains("fe ") || contains("fe exam") {
            return [
                .init(id: "math_tools", label: "Math Tools"),
                .init(id: "eng_basics", label: "Engineering Basics"),
                .init(id: "systems_materials", label: "Systems & Materials"),
                .init(id: "problem_solving", label: "Problem Solving")
            ]
        }
        if contains("cfa") {
            return [
                .init(id: "quant_methods", label: "Math & Finance"),
                .init(id: "financial_reporting", label: "Accounting Basics"),
                .init(id: "investments", label: "Markets & Investments"),
                .init(id: "ethics", label: "Ethics & Rules")
            ]
        }
        if contains("cpa") || contains("aud ") || contains("far ") || contains("reg ") || contains("bec ") {
            // We do not distinguish sub-exams here; this is a generic CPA template set.
            return [
                .init(id: "auditing_basics", label: "Auditing Basics"),
                .init(id: "risk_evidence", label: "Risk & Evidence"),
                .init(id: "reports_ethics", label: "Reports & Ethics"),
                .init(id: "financial_statements", label: "Financial Statements"),
                .init(id: "transactions", label: "Transactions"),
                .init(id: "gov_nonprofit", label: "Government & Nonprofit"),
                .init(id: "tax_basics", label: "Tax Basics"),
                .init(id: "business_law", label: "Business Law"),
                .init(id: "ethics_procedures", label: "Ethics & Procedures"),
                .init(id: "business_concepts", label: "Business Concepts"),
                .init(id: "writing", label: "Writing Skills"),
                .init(id: "finance_ops", label: "Finance & Operations")
            ]
        }
        if contains("security+") || contains("security plus") {
            return [
                .init(id: "sec_fundamentals", label: "Security Basics"),
                .init(id: "threats", label: "Threats & Attacks"),
                .init(id: "networks", label: "Networks"),
                .init(id: "risk_response", label: "Risk & Response")
            ]
        }
        if contains("cisa") {
            return [
                .init(id: "it_audit", label: "IT Auditing"),
                .init(id: "risk_controls", label: "Risk & Controls"),
                .init(id: "systems_review", label: "Systems Review"),
                .init(id: "security_checks", label: "Security Checks")
            ]
        }
        if contains("cissp") {
            return [
                .init(id: "sec_concepts", label: "Security Concepts"),
                .init(id: "risk_controls", label: "Risk & Controls"),
                .init(id: "network_security", label: "Network Security"),
                .init(id: "software_systems", label: "Software & Systems")
            ]
        }
        if contains("nclex") {
            return [
                .init(id: "safe_care", label: "Safe Care"),
                .init(id: "medications", label: "Medications"),
                .init(id: "health_problems", label: "Health Problems"),
                .init(id: "patient_support", label: "Patient Support")
            ]
        }
        if contains("usmle step 1") {
            return [
                .init(id: "science_foundations", label: "Science Foundations"),
                .init(id: "body_systems", label: "Body Systems"),
                .init(id: "mechanisms", label: "Mechanisms & Pathways")
            ]
        }
        if contains("usmle step 2") {
            return [
                .init(id: "diagnosis", label: "Diagnosis"),
                .init(id: "treatment", label: "Treatments"),
                .init(id: "patient_cases", label: "Patient Cases")
            ]
        }
        if contains("toefl") || contains("ielts") {
            return [
                .init(id: "reading", label: "Reading"),
                .init(id: "listening", label: "Listening"),
                .init(id: "speaking", label: "Speaking"),
                .init(id: "writing", label: "Writing")
            ]
        }
        if contains("duolingo") {
            return [
                .init(id: "reading", label: "Reading"),
                .init(id: "listening", label: "Listening"),
                .init(id: "writing", label: "Writing"),
                .init(id: "speaking", label: "Speaking"),
                .init(id: "interactive", label: "Interactive Tasks")
            ]
        }
        
        // General college exams and fallbacks
        if contains("midterm") || contains("final") || contains("cumulative") {
            return [
                .init(id: "lecture_content", label: "Lecture Content"),
                .init(id: "key_terms", label: "Key Terms"),
                .init(id: "practice_problems", label: "Practice Problems"),
                .init(id: "past_tests", label: "Past Tests Review")
            ]
        }
        if contains("psych") {
            return [
                .init(id: "concepts_theories", label: "Concepts & Theories"),
                .init(id: "studies", label: "Experiments & Studies"),
                .init(id: "applied_examples", label: "Applied Examples")
            ]
        }
        if contains("econ") {
            return [
                .init(id: "graphs_models", label: "Graphs & Models"),
                .init(id: "key_terms", label: "Key Terms"),
                .init(id: "practice_problems", label: "Practice Problems")
            ]
        }
        if contains("calculus") {
            return [
                .init(id: "formulas", label: "Formulas"),
                .init(id: "derivatives", label: "Derivatives"),
                .init(id: "integrals", label: "Integrals"),
                .init(id: "practice_problems", label: "Practice Problems")
            ]
        }
        if contains("biology") {
            return [
                .init(id: "cells_systems", label: "Cells & Systems"),
                .init(id: "processes", label: "Processes"),
                .init(id: "diagrams", label: "Diagrams"),
                .init(id: "practice_questions", label: "Practice Questions")
            ]
        }
        
        // Default generic breakdown if we don't recognize the exam
        return [
            .init(id: "content", label: "Content"),
            .init(id: "practice", label: "Practice Problems"),
            .init(id: "review", label: "Review & Recall")
        ]
    }
}

// Shared session state, injected as an EnvironmentObject.
final class AppSession: ObservableObject {
    @Published var mode: AppMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appMode")
        }
    }
    
    init() {
        if let stored = UserDefaults.standard.string(forKey: "appMode"),
           let parsed = AppMode(rawValue: stored) {
            // TEMP: force student mode even if exam mode was previously stored.
            // This keeps exam functionality dormant until explicitly re-enabled.
            mode = parsed == .exam ? .student : parsed
        } else {
            mode = .student
        }
    }
}

// MARK: - Exam Models

/// Simple template that maps an exam type to user-friendly section labels.
struct ExamSectionTemplate {
    let id: String      // internal ID
    let label: String   // simple label shown to user
}

struct ExamSection: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    /// Section confidence 0–1 (UI can convert to percentage)
    var confidence: Double
    /// Knowledge level 0–1 (for future use / additional analytics)
    var knowledgeLevel: Double
    
    init(id: UUID = UUID(), name: String, confidence: Double = 0.0, knowledgeLevel: Double = 0.0) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.knowledgeLevel = knowledgeLevel
    }
}

struct ExamInfo: Identifiable, Hashable, Codable {
    let id: UUID
    var examName: String
    var examDate: Date
    var sections: [ExamSection]
    /// Overall confidence 0-1 (can be formatted as percentage in UI)
    var overallConfidence: Double
    /// Optional class or course this exam is tied to (e.g. "Econ", "Psychology")
    var associatedClass: String?
    
    init(id: UUID = UUID(), examName: String, examDate: Date, sections: [ExamSection] = [], overallConfidence: Double = 0.0, associatedClass: String? = nil) {
        self.id = id
        self.examName = examName
        self.examDate = examDate
        self.sections = sections
        self.overallConfidence = overallConfidence
        self.associatedClass = associatedClass
    }
}

/// Container for all exams and the currently selected exam ID.
struct ExamProfileStore: Codable {
    var exams: [ExamInfo]
    var selectedExamId: UUID?
}

// Observable exam state, injected where needed in Exam Mode.
final class ExamState: ObservableObject {
    @Published var exams: [ExamInfo] {
        didSet { persistProfile() }
    }
    @Published var selectedExamId: UUID? {
        didSet { persistProfile() }
    }
    
    private let storageKey = "examInfoData"
    private let planEngine = StudyPlanEngine()
    
    /// The currently active exam (defaults to first exam if selection is missing).
    var activeExam: ExamInfo {
        if let id = selectedExamId, let match = exams.first(where: { $0.id == id }) {
            return match
        }
        return exams.first ?? Self.fallbackExam()
    }
    
    init(examInfo: ExamInfo? = nil) {
        if let info = examInfo {
            // Explicit single exam provided (e.g. for previews)
            self.exams = [info]
            self.selectedExamId = info.id
            persistProfile()
        } else if let restored = Self.loadPersistedProfile(storageKey: storageKey) {
            self.exams = restored.exams.isEmpty ? [Self.fallbackExam()] : restored.exams
            self.selectedExamId = restored.selectedExamId ?? restored.exams.first?.id
        } else if let legacy = Self.loadLegacySingleExam(storageKey: storageKey) {
            // Migrate from old single-exam storage
            self.exams = [legacy]
            self.selectedExamId = legacy.id
            persistProfile()
        } else {
            // Seed from persisted onboarding data if available
            let defaults = UserDefaults.standard
            let storedName = defaults.string(forKey: "examType") ?? "Your Exam"
            let storedDate = defaults.object(forKey: "examDate") as? Date
            let defaultDate = storedDate ?? Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
            let storedComfort = defaults.double(forKey: "examComfortLevel")
            let comfortNormalized: Double
            if storedComfort > 0 {
                // examComfortLevel was stored on 1–5 scale
                comfortNormalized = min(max(storedComfort / 5.0, 0), 1)
            } else {
                comfortNormalized = 0.0
            }
            let templates = ExamSectionTemplates.templates(for: storedName)
            let seededSections = templates.map { ExamSection(name: $0.label) }
            let initial = ExamInfo(examName: storedName, examDate: defaultDate, sections: seededSections, overallConfidence: comfortNormalized)
            self.exams = [initial]
            self.selectedExamId = initial.id
            persistProfile()
        }
    }
    
    var daysUntilExam: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: activeExam.examDate)
        let comps = cal.dateComponents([.day], from: start, to: end)
        return comps.day ?? 0
    }
    
    // MARK: - Adaptive Study Plan Bridge
    /// Build a lightweight ExamProfile for the active exam using existing exam data
    /// and onboarding settings (hours per day). This is used by StudyPlanEngine.
    private func makeExamProfile() -> ExamProfile {
        let info = activeExam
        let defaults = UserDefaults.standard
        let dailyHours = defaults.double(forKey: "examDailyStudyHours")
        // If not set, assume 1.0 hour/day → ~6 hours/week
        let hoursPerWeek = (dailyHours > 0 ? dailyHours : 1.0) * 6.0
        let storedBlock = defaults.integer(forKey: "preferredExamBlockMinutes")
        let allowedBlocks = [25, 30, 45, 60]
        let preferredBlock = allowedBlocks.contains(storedBlock) ? storedBlock : 30
        
        let sectionProfiles: [ExamSectionProfile] = info.sections.map { section in
            // Existing confidence / knowledgeLevel are stored 0–1; convert to 0–100 scale.
            let confPct = max(0, min(100, section.confidence * 100.0))
            let masteryPct = max(0, min(100, section.knowledgeLevel * 100.0))
            return ExamSectionProfile(
                id: section.id.uuidString,
                name: section.name,
                confidence: confPct,
                mastery: masteryPct,
                priorityWeight: 0
            )
        }
        
        return ExamProfile(
            id: info.id.uuidString,
            examId: info.examName,
            examName: info.examName,
            examDate: info.examDate,
            targetScore: nil,
            diagnosticScore: nil,
            hoursPerWeekAvailable: hoursPerWeek,
            preferredBlockMinutes: preferredBlock,
            hasTeacher: false,
            hasTutor: false,
            resources: [],
            sections: sectionProfiles
        )
    }
    
    /// Deterministically generate a StudyPlanDay for the active exam on a given date.
    /// This is pure logic: we currently pass an empty history; later we can persist
    /// StudySession records and feed them back in.
    func studyPlanDay(for date: Date) -> StudyPlanDay {
        let profile = makeExamProfile()
        // TODO: hook in real history of StudySession once we track sessions.
        let history: [StudySession] = []
        return planEngine.generateStudyPlanDay(for: profile, on: date, history: history)
    }
    
    /// Update basic info for the currently active exam.
    func updateActiveExam(examName: String, examDate: Date, associatedClass: String?) {
        guard let index = exams.firstIndex(where: { $0.id == activeExam.id }) else { return }
        var updated = exams[index]
        updated.examName = examName
        updated.examDate = examDate
        updated.associatedClass = associatedClass
        exams[index] = updated
    }
    
    /// Add a brand new exam based on simple name/date/class inputs.
    func addExam(examName: String, examDate: Date, associatedClass: String?) {
        let templates = ExamSectionTemplates.templates(for: examName)
        let seededSections = templates.map { ExamSection(name: $0.label) }
        let newExam = ExamInfo(examName: examName.isEmpty ? "Your Exam" : examName,
                               examDate: examDate,
                               sections: seededSections,
                               overallConfidence: 0.0,
                               associatedClass: associatedClass)
        exams.append(newExam)
        selectedExamId = newExam.id
    }
    
    private func persistProfile() {
        let store = ExamProfileStore(exams: exams, selectedExamId: selectedExamId)
        do {
            let data = try JSONEncoder().encode(store)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print(" Failed to persist ExamProfileStore: \(error)")
        }
    }
    
    private static func loadPersistedProfile(storageKey: String) -> ExamProfileStore? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(ExamProfileStore.self, from: data)
        } catch {
            return nil
        }
    }
    
    /// Backward-compat: load legacy single-ExamInfo payloads.
    private static func loadLegacySingleExam(storageKey: String) -> ExamInfo? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(ExamInfo.self, from: data)
        } catch {
            return nil
        }
    }
    
    private static func fallbackExam() -> ExamInfo {
        ExamInfo(examName: "Your Exam", examDate: Date(), sections: [], overallConfidence: 0)
    }
}
