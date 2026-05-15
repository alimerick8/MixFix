
//
//  EditAssignmentSheet.swift
//  MixFix
//

import SwiftUI

struct EditAssignmentSheet: View {
    let event: CalendarEvent
    let store: DataStore
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var dueDate: Date
    @State private var category: String
    @State private var className: String
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @FocusState private var isTitleFocused: Bool
    
    init(event: CalendarEvent, store: DataStore) {
        self.event = event
        self.store = store
        _title = State(initialValue: event.title)
        _dueDate = State(initialValue: event.start)
        _category = State(initialValue: event.category)
        // Filter out NSManagedObject corruption
        let cleanClassName = event.className ?? "None"
        let initialClassName = cleanClassName.contains("NSManagedObject") ? "None" : cleanClassName
        print("🎬 EditAssignmentSheet init - Event className: '\(event.className ?? "nil")', Setting to: '\(initialClassName)'")
        _className = State(initialValue: initialClassName)
    }
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    private var categoryDisplayName: String {
        switch category {
        case "Assignments": return "Assignment"
        case "Tests": return "Test"
        case "Exams": return "Exam"
        case "Classes": return "Class"
        case "Extra Curriculars": return "Activity"
        default: return "Event"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Enter title", text: $title)
                    
                    Picker("Type", selection: $category) {
                        Text("Assignment").tag("Assignments")
                        Text("Test").tag("Tests")
                        Text("Exam").tag("Exams")
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                    
                    FiveMinuteTimePicker(date: $dueDate, label: "Due Time")
                    
                    HStack {
                        Text("Class")
                        Spacer()
                        Picker("", selection: $className) {
                            Text("None").tag("None")
                            ForEach(studentClasses) { classItem in
                                Text(classItem.name).tag(classItem.name)
                            }
                        }
                        .labelsHidden()
                    }
                    .onChange(of: className) { oldValue, newValue in
                        print("🔄 Class picker changed from '\(oldValue)' to '\(newValue)'")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        store.deleteEvent(event)
                        dismiss()
                    } label: {
                        Text("Delete \(categoryDisplayName)")
                    }
                }
            }
            .navigationTitle("Edit \(categoryDisplayName)")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isTitleFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        // Small delay to ensure save completes before dismissing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        // Format the date/time as a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy h:mm a"
        let timeString = dateFormatter.string(from: dueDate)
        
        // Clean className - never save "None" or anything containing "NSManagedObject"
        let cleanClassName: String?
        if className == "None" || className.isEmpty || className.contains("NSManagedObject") {
            cleanClassName = nil
        } else {
            cleanClassName = className
        }
        
        print("💾 Saving - Title: \(title), Class: \(cleanClassName ?? "nil"), Category: \(category)")
        print("💾 Raw className state value: '\(className)'")
        
        // Update the event with all fields
        store.updateEventFull(
            event,
            newTitle: title,
            newStart: dueDate,
            newEnd: dueDate,
            newTimeString: timeString,
            newCategory: category,
            newClassName: cleanClassName
        )
        
        print("✅ Save complete - className passed: \(cleanClassName ?? "nil")")
    }
    
    private var titlePlaceholder: String {
        switch category {
        case "Tests": return "Test name"
        case "Exams": return "Exam name"
        case "Assignments": return "Assignment name"
        case "Classes": return "Class name"
        case "Extra Curriculars": return "Activity name"
        default: return "Title"
        }
    }
}
