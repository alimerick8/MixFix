//
//  DataStore.swift
//  MixFix
//

import Foundation
import Combine
import SwiftData
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class DataStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var events: [CalendarEvent] = []
    @Published var moods: [MoodEntry] = []
    @Published var habits: [Habit] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var classCheckIns: [ClassCheckIn] = []
    
    var userId: String {
        return Auth.auth().currentUser?.uid ?? "guest_user"
    }
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext?, seed: Bool = false) {
        self.modelContext = modelContext
        if let modelContext = modelContext, seed {
            Task { @MainActor in
                PersistenceController.shared.seedData(context: modelContext)
            }
        }
        if modelContext != nil {
            loadData()
        }
    }

    // MARK: - Class Check-Ins
    func upsertClassCheckIn(date: Date,
                            classId: UUID?,
                            className: String,
                            understandingScore: Int,
                            energyScore: Int,
                            notes: String?) {
        guard let modelContext = modelContext else { return }
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let currentUserId = userId
        let descriptor = FetchDescriptor<ClassCheckInSD>(
            predicate: #Predicate { item in
                item.userId == currentUserId && item.date == dayStart && item.className == className
            }
        )
        let existing = try? modelContext.fetch(descriptor).first
        let now = Date()
        let scoreClamp: (Int) -> Int = { max(0, min(100, $0)) }
        if let existing = existing {
            existing.classId = classId
            existing.understandingScore = scoreClamp(understandingScore)
            existing.energyScore = scoreClamp(energyScore)
            existing.notes = notes
            existing.updatedAt = now
        } else {
            let checkIn = ClassCheckInSD(
                userId: currentUserId,
                date: dayStart,
                classId: classId,
                className: className,
                understandingScore: scoreClamp(understandingScore),
                energyScore: scoreClamp(energyScore),
                notes: notes,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(checkIn)
        }
        try? modelContext.save()
        loadClassCheckIns()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        DataStoreAccessor.shared.modelContext = context
        loadData()
    }
    
    // MARK: - Load from SwiftData
    func loadData() {
        loadTasks()
        loadEvents()
        loadMoods()
        loadHabits()
        loadJournalEntries()
        loadClassCheckIns()
    }
    
    private func loadTasks() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<TaskItemSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            tasks = items.map { 
                var task = TaskItem(title: $0.title, priority: $0.priority, isDone: $0.isDone)
                task.notificationTime = $0.notificationTime
                task.notificationIdentifier = $0.notificationIdentifier
                return task
            }
        }
    }
    
    private func loadEvents() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.start)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            // Load current valid class names from AppStorage
            let validClassNames = getValidClassNames()
            
            // If there are no saved classes yet, don't filter anything out.
            // This prevents the schedule from going blank when the class list is empty
            // (e.g., after first install or a data reset).
            if validClassNames.isEmpty {
                events = items.map { eventSD in
                    let cleanClassName: String? = eventSD.assignedClass.isEmpty ? nil : eventSD.assignedClass
                    return CalendarEvent(
                        id: eventSD.id,
                        title: eventSD.title,
                        start: eventSD.start,
                        end: eventSD.end,
                        location: eventSD.location,
                        category: eventSD.category,
                        timeString: eventSD.timeString,
                        isCompleted: eventSD.isCompleted,
                        status: AssignmentStatus(rawValue: eventSD.status) ?? .notStarted,
                        className: cleanClassName
                    )
                }
                return
            }
            
            events = items.compactMap { eventSD in
                // Convert empty string back to nil for the view model
                let cleanClassName: String? = eventSD.assignedClass.isEmpty ? nil : eventSD.assignedClass

                // Filter logic when we *do* have classes:
                // 1. For "Classes" category, only include if the title matches a current class
                // 2. For all other categories (Assignments, Tests, Exams, etc.), **never** filter them out
                //    just because the class was renamed or deleted. This prevents assignments from
                //    disappearing when class data changes.
                let shouldInclude: Bool
                if eventSD.category == "Classes" {
                    shouldInclude = validClassNames.contains(eventSD.title)
                } else {
                    shouldInclude = true
                }

                guard shouldInclude else { return nil }

                return CalendarEvent(
                    id: eventSD.id,
                    title: eventSD.title,
                    start: eventSD.start,
                    end: eventSD.end,
                    location: eventSD.location,
                    category: eventSD.category,
                    timeString: eventSD.timeString,
                    isCompleted: eventSD.isCompleted,
                    status: AssignmentStatus(rawValue: eventSD.status) ?? .notStarted,
                    className: cleanClassName
                )
            }
        }
    }
    
    private func getValidClassNames() -> Set<String> {
        // Read current classes from AppStorage
        guard let data = UserDefaults.standard.data(forKey: "studentClassesData"),
              let classes = try? JSONDecoder().decode([StudentClass].self, from: data) else {
            return []
        }
        return Set(classes.map { $0.name })
    }
    
    private func loadMoods() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<MoodEntrySD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            moods = items.map { MoodEntry(date: $0.date, mood: $0.mood, note: $0.note) }
        }
    }
    
    private func loadHabits() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<HabitSD>(
            predicate: #Predicate { $0.userId == currentUserId }
        )
        if let items = try? modelContext.fetch(descriptor) {
            habits = items.map { Habit(title: $0.title, streak: $0.streak) }
        }
    }

    private func loadClassCheckIns() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<ClassCheckInSD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            classCheckIns = items.map { item in
                ClassCheckIn(
                    id: item.id,
                    date: item.date,
                    classId: item.classId,
                    className: item.className,
                    understandingScore: item.understandingScore,
                    energyScore: item.energyScore,
                    notes: item.notes,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt
                )
            }
        }
    }
    
    // MARK: - Actions
    func addMood(_ mood: Int, note: String? = nil) {
        guard let modelContext = modelContext else { return }
        let entry = MoodEntrySD(userId: userId, mood: mood, note: note)
        modelContext.insert(entry)
        try? modelContext.save()
        loadMoods()
        
        // Sync to Firestore ONLY when a real Firebase user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                try? await FirestoreService.shared.syncMoodEntry(entry)
            }
        }
    }
    
    func addTask(title: String, priority: Int) {
        guard let modelContext = modelContext else { return }
        let task = TaskItemSD(userId: userId, title: title, priority: priority)
        modelContext.insert(task)
        try? modelContext.save()
        loadTasks()
    }
    
    func toggleTask(_ task: TaskItem) {
        guard let modelContext = modelContext else { return }
        let taskTitle = task.title
        let descriptor = FetchDescriptor<TaskItemSD>(predicate: #Predicate { $0.title == taskTitle })
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            item.isDone.toggle()
            try? modelContext.save()
            loadTasks()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        guard let modelContext = modelContext else { return }
        let taskTitle = task.title
        let descriptor = FetchDescriptor<TaskItemSD>(predicate: #Predicate { $0.title == taskTitle })
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            modelContext.delete(item)
            try? modelContext.save()
            loadTasks()
        }
    }
    
    func updateTask(_ task: TaskItem) {
        guard let modelContext = modelContext else { return }
        let taskTitle = task.title
        let descriptor = FetchDescriptor<TaskItemSD>(predicate: #Predicate { $0.title == taskTitle })
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            item.notificationTime = task.notificationTime
            item.notificationIdentifier = task.notificationIdentifier
            item.isDone = task.isDone
            try? modelContext.save()
            loadTasks()
        }
    }
    
    func addEvent(title: String, start: Date, end: Date, location: String? = nil, category: String = "", timeString: String = "", className: String? = nil) {
        guard let modelContext = modelContext else { return }
        let event = CalendarEventSD(userId: userId, title: title, start: start, end: end, location: location, category: category, timeString: timeString, isCompleted: false, status: "notStarted", className: className)
        print("💾 Adding event '\(title)' with className: '\(className ?? "nil")'")
        modelContext.insert(event)
        try? modelContext.save()
        loadEvents()
        
        // Sync to Firestore ONLY when a real Firebase user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                try? await FirestoreService.shared.syncCalendarEvent(event)
            }
        }
    }
    
    func toggleEventCompletion(_ event: CalendarEvent) {
        guard let modelContext = modelContext else { return }
        let eventTitle = event.title
        let eventStart = event.start
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.title == eventTitle && $0.start == eventStart }
        )
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            item.isCompleted.toggle()
            try? modelContext.save()
            loadEvents()
            
            // Sync to Firestore ONLY when a real Firebase user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    try? await FirestoreService.shared.syncCalendarEvent(item)
                }
            }
        }
    }
    
    func updateEventStatus(_ event: CalendarEvent, status: AssignmentStatus) {
        guard let modelContext = modelContext else { return }
        let eventTitle = event.title
        let eventStart = event.start
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.title == eventTitle && $0.start == eventStart }
        )
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            item.status = status.rawValue
            item.isCompleted = (status == .completed)
            try? modelContext.save()
            loadEvents()
            
            // Sync to Firestore
            Task {
                try? await FirestoreService.shared.syncCalendarEvent(item)
            }
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) {
        guard let modelContext = modelContext else { return }
        let eventTitle = event.title
        let eventStart = event.start
        let eventId = event.id
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.title == eventTitle && $0.start == eventStart }
        )
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            modelContext.delete(item)
            try? modelContext.save()
            loadEvents()
            
            // Delete from Firestore ONLY when a real Firebase user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    try? await FirestoreService.shared.deleteCalendarEvent(id: eventId)
                }
            }
        }
    }
    
    func updateEvent(_ event: CalendarEvent, newTitle: String, newTimeString: String, newCategory: String) {
        guard let modelContext = modelContext else { return }
        let eventTitle = event.title
        let eventStart = event.start
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.title == eventTitle && $0.start == eventStart }
        )
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            item.title = newTitle
            item.timeString = newTimeString
            item.category = newCategory
            try? modelContext.save()
            loadEvents()
        }
    }
    
    func updateEventFull(_ event: CalendarEvent, newTitle: String, newStart: Date, newEnd: Date, newTimeString: String, newCategory: String, newClassName: String?) {
        guard let modelContext = modelContext else { return }
        let eventId = event.id
        print("🔍 Looking for event with ID: \(eventId), className to save: '\(newClassName ?? "nil")'")
        let descriptor = FetchDescriptor<CalendarEventSD>(
            predicate: #Predicate { $0.id == eventId }
        )
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            print("✏️ Found event '\(item.title)' in DB, current assignedClass: '\(item.assignedClass)'")
            item.title = newTitle
            item.start = newStart
            item.end = newEnd
            item.timeString = newTimeString
            item.category = newCategory
            item.assignedClass = newClassName ?? "" // Store empty string instead of nil
            print("📝 Set assignedClass to: '\(item.assignedClass)'")
            do {
                try modelContext.save()
                print("💿 Database saved successfully")
            } catch {
                print("❌ Save error: \(error)")
            }
            
            // Force reload on main thread with a small delay to ensure persistence
            Task { @MainActor in
                // Notify observers
                objectWillChange.send()
                
                // Small delay to ensure SwiftData persistence completes
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                // Reload events
                loadEvents()
                
                // Verify the className persisted
                print("🔄 Events reloaded, checking if className persisted...")
                if let reloadedItem = try? modelContext.fetch(descriptor).first {
                    print("✅ Verification: assignedClass in DB is now '\(reloadedItem.assignedClass)'")
                }
            }
        } else {
            print("❌ Event not found in database with ID: \(eventId)")
        }
    }
    
    private func loadJournalEntries() {
        guard let modelContext = modelContext else { return }
        let currentUserId = userId
        let descriptor = FetchDescriptor<JournalEntrySD>(
            predicate: #Predicate { $0.userId == currentUserId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            journalEntries = items.map { JournalEntry(id: $0.id, title: $0.title, content: $0.content, createdAt: $0.createdAt) }
        }
    }
    
    func addJournalEntry(title: String?, content: String) {
        guard let modelContext = modelContext else { return }
        do {
            let entry = JournalEntrySD(userId: userId, title: title, content: content)
            modelContext.insert(entry)
            try modelContext.save()
            loadJournalEntries()
            
            // Sync to Firestore ONLY when a real Firebase user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    try? await FirestoreService.shared.syncJournalEntry(entry)
                }
            }
        } catch {
            print("Error saving journal entry: \(error)")
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        guard let modelContext = modelContext else { return }
        let entryID = entry.id
        let descriptor = FetchDescriptor<JournalEntrySD>(predicate: #Predicate { $0.id == entryID })
        if let items = try? modelContext.fetch(descriptor), let item = items.first {
            modelContext.delete(item)
            try? modelContext.save()
            loadJournalEntries()
        }
    }
    
    // MARK: - Firestore Download/Restore
    func downloadAllUserData() async {
        // Only download when we have a real Firebase user (no guest mode sync)
        guard let modelContext = modelContext, Auth.auth().currentUser != nil else { return }
        
        print("📥 Starting data download from Firestore...")
        
        do {
            // Download events
            let eventsData = try await FirestoreService.shared.fetchCalendarEvents()
            print("📥 Downloaded \(eventsData.count) events")
            
            for eventDict in eventsData {
                guard let idString = eventDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = eventDict["title"] as? String,
                      let startTimestamp = eventDict["start"] as? Timestamp,
                      let endTimestamp = eventDict["end"] as? Timestamp,
                      let category = eventDict["category"] as? String,
                      let timeString = eventDict["timeString"] as? String,
                      let isCompleted = eventDict["isCompleted"] as? Bool,
                      let status = eventDict["status"] as? String else {
                    continue
                }
                
                let location = eventDict["location"] as? String
                let assignedClass = eventDict["assignedClass"] as? String
                
                // Check if event already exists
                let descriptor = FetchDescriptor<CalendarEventSD>(
                    predicate: #Predicate { $0.id == id }
                )
                let existingEvents = try? modelContext.fetch(descriptor)
                
                if existingEvents?.isEmpty ?? true {
                    // Create new event
                    let event = CalendarEventSD(
                        id: id,
                        userId: userId,
                        title: title,
                        start: startTimestamp.dateValue(),
                        end: endTimestamp.dateValue(),
                        location: location,
                        category: category,
                        timeString: timeString,
                        isCompleted: isCompleted,
                        status: status,
                        className: assignedClass
                    )
                    modelContext.insert(event)
                }
            }
            
            // Download moods
            let moodsData = try await FirestoreService.shared.fetchMoodEntries()
            print("📥 Downloaded \(moodsData.count) mood entries")
            
            for moodDict in moodsData {
                guard let idString = moodDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let mood = moodDict["mood"] as? Int,
                      let dateTimestamp = moodDict["date"] as? Timestamp else {
                    continue
                }
                
                let note = moodDict["note"] as? String
                
                // Check if mood already exists
                let descriptor = FetchDescriptor<MoodEntrySD>(
                    predicate: #Predicate { $0.id == id }
                )
                let existingMoods = try? modelContext.fetch(descriptor)
                
                if existingMoods?.isEmpty ?? true {
                    let moodEntry = MoodEntrySD(
                        id: id,
                        userId: userId,
                        date: dateTimestamp.dateValue(),
                        mood: mood,
                        note: note
                    )
                    modelContext.insert(moodEntry)
                }
            }
            
            // Download journals
            let journalsData = try await FirestoreService.shared.fetchJournalEntries()
            print("📥 Downloaded \(journalsData.count) journal entries")
            
            for journalDict in journalsData {
                guard let idString = journalDict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let content = journalDict["content"] as? String,
                      let createdAtTimestamp = journalDict["createdAt"] as? Timestamp else {
                    continue
                }
                
                let title = journalDict["title"] as? String
                
                // Check if journal already exists
                let descriptor = FetchDescriptor<JournalEntrySD>(
                    predicate: #Predicate { $0.id == id }
                )
                let existingJournals = try? modelContext.fetch(descriptor)
                
                if existingJournals?.isEmpty ?? true {
                    let journalEntry = JournalEntrySD(
                        id: id,
                        userId: userId,
                        title: title,
                        content: content,
                        createdAt: createdAtTimestamp.dateValue()
                    )
                    modelContext.insert(journalEntry)
                }
            }
            
            // Save all downloaded data
            try modelContext.save()
            
            // Reload all data
            loadData()
            
            print("✅ Data download complete!")
            
        } catch {
            print("❌ Error downloading data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clear All Data
    func clearAllData() {
        guard let modelContext = modelContext else { return }
        
        print("🗑️ Clearing all SwiftData...")
        
        // Delete all tasks
        let taskDescriptor = FetchDescriptor<TaskItemSD>()
        if let tasks = try? modelContext.fetch(taskDescriptor) {
            for task in tasks {
                modelContext.delete(task)
            }
        }
        
        // Delete all events
        let eventDescriptor = FetchDescriptor<CalendarEventSD>()
        if let events = try? modelContext.fetch(eventDescriptor) {
            for event in events {
                modelContext.delete(event)
            }
        }
        
        // Delete all moods
        let moodDescriptor = FetchDescriptor<MoodEntrySD>()
        if let moods = try? modelContext.fetch(moodDescriptor) {
            for mood in moods {
                modelContext.delete(mood)
            }
        }
        
        // Delete all habits
        let habitDescriptor = FetchDescriptor<HabitSD>()
        if let habits = try? modelContext.fetch(habitDescriptor) {
            for habit in habits {
                modelContext.delete(habit)
            }
        }
        
        // Delete all journal entries
        let journalDescriptor = FetchDescriptor<JournalEntrySD>()
        if let journals = try? modelContext.fetch(journalDescriptor) {
            for journal in journals {
                modelContext.delete(journal)
            }
        }
        
        // Save changes
        try? modelContext.save()
        
        // Clear published arrays
        tasks = []
        events = []
        moods = []
        habits = []
        journalEntries = []
        classCheckIns = []
        
        print("✅ All local data cleared")
    }
}
