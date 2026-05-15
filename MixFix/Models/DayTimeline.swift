//
//  DayTimeline.swift
//  MixFix
//
//  Single source of truth for all daily scheduling
//

import Foundation

// MARK: - Time Block Protocol
protocol TimeBlock: Identifiable {
    var id: UUID { get }
    var startMinute: Int { get }
    var endMinute: Int { get }
    var blockType: TimeBlockType { get }
}

extension TimeBlock {
    var duration: Int { endMinute - startMinute }
    
    func overlaps(with other: any TimeBlock) -> Bool {
        startMinute < other.endMinute && endMinute > other.startMinute
    }
}

// MARK: - Block Types
enum TimeBlockType: String {
    case scheduledClass = "Class"
    case extracurricular = "Activity"
    case studyBlock = "Study"
    case reviewBlock = "Review"
    case breakBlock = "Break"
    case sleepWindow = "Sleep"
    case customStudy = "Custom"
    case assignment = "Assignment"
}

// MARK: - Concrete Time Block
struct ScheduleBlock: TimeBlock {
    let id: UUID
    let startMinute: Int
    let endMinute: Int
    let blockType: TimeBlockType
    let title: String
    let subject: String?
    let className: String?
    let classColorHex: String?
    let dueDate: Date?
    let priority: StudyPriority?
    let strategy: String?
    let isLocked: Bool // Classes, sleep, commitments can't be moved
    let parentBlockId: UUID? // For reviews/breaks that belong to a study block
    
    init(
        id: UUID = UUID(),
        startMinute: Int,
        endMinute: Int,
        blockType: TimeBlockType,
        title: String,
        subject: String? = nil,
        className: String? = nil,
        classColorHex: String? = nil,
        dueDate: Date? = nil,
        priority: StudyPriority? = nil,
        strategy: String? = nil,
        isLocked: Bool = false,
        parentBlockId: UUID? = nil
    ) {
        self.id = id
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.blockType = blockType
        self.title = title
        self.subject = subject
        self.className = className
        self.classColorHex = classColorHex
        self.dueDate = dueDate
        self.priority = priority
        self.strategy = strategy
        self.isLocked = isLocked
        self.parentBlockId = parentBlockId
    }
}

// MARK: - Hashable Conformance
extension ScheduleBlock: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScheduleBlock, rhs: ScheduleBlock) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Day Timeline (Single Source of Truth)
class DayTimeline {
    let date: Date
    private(set) var blocks: [ScheduleBlock] = []
    
    // Time bounds
    let dayStartMinute: Int // e.g., 0 for midnight, 360 for 6am
    let dayEndMinute: Int   // e.g., 1440 for midnight, 1320 for 10pm
    
    init(date: Date, earliestHour: Int = 6, latestHour: Int = 23) {
        self.date = date
        self.dayStartMinute = earliestHour * 60
        self.dayEndMinute = latestHour * 60
    }
    
    // MARK: - Core Operations
    
    /// Add a block with strict overlap validation
    func addBlock(_ block: ScheduleBlock) throws {
        // Validate bounds
        guard block.startMinute >= dayStartMinute && block.endMinute <= dayEndMinute else {
            throw TimelineError.outOfBounds(block: block, bounds: (dayStartMinute, dayEndMinute))
        }
        
        // Validate duration
        guard block.endMinute > block.startMinute else {
            throw TimelineError.invalidDuration(block: block)
        }
        
        // Check for overlaps
        if let conflict = findOverlap(for: block) {
            throw TimelineError.overlap(new: block, existing: conflict)
        }
        
        blocks.append(block)
        sortBlocks()
    }
    
    /// Force add a block without validation (for urgent work)
    func forceAddBlock(_ block: ScheduleBlock) {
        blocks.append(block)
        sortBlocks()
    }
    
    /// Find the first overlapping block
    func findOverlap(for block: ScheduleBlock) -> ScheduleBlock? {
        blocks.first { existing in
            existing.id != block.id && block.overlaps(with: existing)
        }
    }
    
    /// Get all available windows (gaps between locked blocks)
    func getAvailableWindows() -> [TimeWindow] {
        var windows: [TimeWindow] = []
        let lockedBlocks = blocks.filter { $0.isLocked }.sorted { $0.startMinute < $1.startMinute }
        
        var currentMinute = dayStartMinute
        
        for locked in lockedBlocks {
            if currentMinute < locked.startMinute {
                windows.append(TimeWindow(start: currentMinute, end: locked.startMinute))
            }
            currentMinute = max(currentMinute, locked.endMinute)
        }
        
        // Add final window
        if currentMinute < dayEndMinute {
            windows.append(TimeWindow(start: currentMinute, end: dayEndMinute))
        }
        
        return windows
    }
    
    /// Try to fit a block into available windows using fit-first logic
    func fitBlock(duration: Int, preferredStart: Int? = nil, blockType: TimeBlockType, title: String, subject: String? = nil, className: String? = nil, classColorHex: String? = nil, dueDate: Date? = nil, priority: StudyPriority? = nil, strategy: String? = nil) -> ScheduleBlock? {
        
        let windows = getAvailableWindows()
        
        // Try preferred start first
        if let preferred = preferredStart {
            for window in windows {
                if preferred >= window.start && preferred + duration <= window.end {
                    let block = ScheduleBlock(
                        startMinute: preferred,
                        endMinute: preferred + duration,
                        blockType: blockType,
                        title: title,
                        subject: subject,
                        className: className,
                        classColorHex: classColorHex,
                        dueDate: dueDate,
                        priority: priority,
                        strategy: strategy
                    )
                    try? addBlock(block)
                    return block
                }
            }
        }
        
        // Find first window that fits
        for window in windows {
            if window.duration >= duration {
                let block = ScheduleBlock(
                    startMinute: window.start,
                    endMinute: window.start + duration,
                    blockType: blockType,
                    title: title,
                    subject: subject,
                    className: className,
                    classColorHex: classColorHex,
                    dueDate: dueDate,
                    priority: priority,
                    strategy: strategy
                )
                try? addBlock(block)
                return block
            }
        }
        
        return nil // Couldn't fit
    }
    
    /// Remove a block by ID
    func removeBlock(id: UUID) {
        blocks.removeAll { $0.id == id }
    }
    
    /// Get blocks sorted by start time
    func getSortedBlocks() -> [ScheduleBlock] {
        blocks.sorted { $0.startMinute < $1.startMinute }
    }
    
    private func sortBlocks() {
        blocks.sort { $0.startMinute < $1.startMinute }
    }
    
    // MARK: - Time Conversion Utilities
    
    static func minutesToTime(minutes: Int) -> (hour: Int, minute: Int) {
        (minutes / 60, minutes % 60)
    }
    
    static func timeToMinutes(hour: Int, minute: Int) -> Int {
        hour * 60 + minute
    }
    
    static func dateToMinutes(date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
    
    static func minutesToDate(minutes: Int, onDay date: Date, calendar: Calendar = .current) -> Date {
        let (hour, minute) = minutesToTime(minutes: minutes)
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Time Window
struct TimeWindow {
    let start: Int // minutes from day start
    let end: Int
    
    var duration: Int { end - start }
}

// MARK: - Timeline Errors
enum TimelineError: Error, LocalizedError {
    case overlap(new: ScheduleBlock, existing: ScheduleBlock)
    case outOfBounds(block: ScheduleBlock, bounds: (Int, Int))
    case invalidDuration(block: ScheduleBlock)
    
    var errorDescription: String? {
        switch self {
        case .overlap(let new, let existing):
            return "Block '\(new.title)' overlaps with '\(existing.title)'"
        case .outOfBounds(let block, let bounds):
            return "Block '\(block.title)' is outside day bounds (\(bounds.0)-\(bounds.1))"
        case .invalidDuration(let block):
            return "Block '\(block.title)' has invalid duration"
        }
    }
}

