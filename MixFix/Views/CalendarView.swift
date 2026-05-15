//
//  CalendarView.swift
//  MixFix
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showDayDetail = false
    @State private var showDatePicker = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    @State private var activeBlock: StudyBlock?
    @State private var activeClassCheckInBlock: StudyBlock?
    @State private var showSession: Bool = false
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @AppStorage("moodBasedScheduleEnabled") private var moodBasedScheduleEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button at top
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }
            
            // Header with selected date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(yearString)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(selectedDateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Only the calendar icon is clickable
                Button {
                    showDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .padding(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray5))
            
            // Month navigation
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
            }
            .padding()
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        Button {
                            selectedDate = date
                            showDayDetail = true
                        } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.body)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                                )
                                .foregroundStyle(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                        }
                    } else {
                        Text("")
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            }
        }
        .sheet(isPresented: $showDayDetail) {
            DayDetailView(selectedDate: selectedDate, currentMonth: $currentMonth)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Jump to Date")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .onChange(of: selectedDate) { oldValue, newDate in
                            // Only dismiss if the date actually changed
                            if oldValue != newDate {
                                // Auto-dismiss and update month when date is selected
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentMonth = newDate
                                    showDatePicker = false
                                }
                            }
                        }
                    
                    Spacer()
                }
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $activeBlock) { block in
            StudySessionView(block: block)
                .environmentObject(dataStore)
                .environmentObject(timerManager)
        }
        .sheet(item: $activeClassCheckInBlock) { block in
            ClassCheckInView(block: block)
        }
    }
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM dd"
        return formatter.string(from: selectedDate)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).uppercased()
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }
        
        // Add all days in the month
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    var selectedDate: Date
    @Binding var currentMonth: Date
    var showCloseButton: Bool = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var timerManager: PomodoroTimerManager
    
    @State private var localSelectedDate: Date
    @State private var selectedTab: String
    @State private var showAddEvent = false
    @State private var dateText: String = ""
    @State private var isEditingDate = false
    @State private var isWeekMode: Bool = true
    @State private var activeBlock: StudyBlock?
    @State private var activeClassCheckInBlock: StudyBlock?
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("classSchedulesData") private var classSchedulesData: Data = Data()
    @AppStorage("classDataVersion") private var classDataVersion: Int = 0
    private var showScheduleMode: Bool = false
    private var tabs: [String] {
        showScheduleMode ? ["Schedule", "Extra Curriculars"] : ["Classes", "Extra Curriculars"]
    }
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    init(selectedDate: Date, currentMonth: Binding<Date>, initialTab: String = "Classes", showCloseButton: Bool = false, showScheduleMode: Bool = false) {
        self.showScheduleMode = showScheduleMode
        self.selectedDate = selectedDate
        self._currentMonth = currentMonth
        self._localSelectedDate = State(initialValue: selectedDate)
        self._selectedTab = State(initialValue: showScheduleMode ? "Schedule" : initialTab)
        self.showCloseButton = showCloseButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            calendarSection
            dateDisplaySection
            
            tabSelector
            contentArea
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAddEvent) {
            addEventSheet
        }
        .onAppear {
            // Ensure dataStore has modelContext before rendering
            if dataStore.events.isEmpty {
                dataStore.loadData()
            }
            // Run the heavy class resync only once per DayDetailView lifetime
            // so opening Study Schedule doesn't redo weeks of work every time.
            resyncClassEventsFromSchedulesIfNeeded()
        }
        .onChange(of: classDataVersion) { _, _ in
            // If class data changed elsewhere (e.g. Profile), refresh once.
            resyncClassEventsFromSchedulesIfNeeded(force: true)
        }
        .fullScreenCover(item: $activeBlock) { block in
            StudySessionView(block: block)
                .environmentObject(dataStore)
                .environmentObject(timerManager)
        }
        .sheet(item: $activeClassCheckInBlock) { block in
            ClassCheckInView(block: block)
        }
    }
    
    private var visibleDays: [Date?] {
        if !isWeekMode {
            return daysInMonth
        }
        // Week mode: show only the current week containing localSelectedDate
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: localSelectedDate)
        components.weekday = calendar.firstWeekday
        let startOfWeek = calendar.date(from: components) ?? calendar.startOfDay(for: localSelectedDate)
        return (0..<7).map { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private var calendarSection: some View {
        VStack(spacing: 12) {
            monthNavigationHeader
            daysOfWeekHeader
            calendarGrid
        }
        .background(Color(.systemBackground))
    }
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                if isWeekMode {
                    changeWeek(by: -1)
                } else {
                    changeMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.headline)
            
            Spacer()
            
            Button {
                if isWeekMode {
                    changeWeek(by: 1)
                } else {
                    changeMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.primary)
            }
            
            if showCloseButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 8)
            }
            
            // Toggle between week and month views
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isWeekMode.toggle()
                }
            } label: {
                Image(systemName: isWeekMode ? "square.grid.2x2" : "rectangle.split.3x1")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    private func resyncClassEventsFromSchedulesIfNeeded(force: Bool = false) {
        let existingClassEvents = dataStore.events.filter { $0.category == "Classes" }
        if !force && !existingClassEvents.isEmpty {
            return
        }

        guard
            let decodedClasses = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData),
            let decodedSchedules = try? JSONDecoder().decode([UUID: ClassScheduleInfo].self, from: classSchedulesData)
        else { return }

        for event in existingClassEvents {
            dataStore.deleteEvent(event)
        }

        let calendar = Calendar.current
        guard
            let startDate = calendar.date(byAdding: .day, value: -7, to: Date()),
            let endDate = calendar.date(byAdding: .month, value: 4, to: Date())
        else { return }
        
        for classItem in decodedClasses {
            guard let schedule = decodedSchedules[classItem.id] else { continue }
            var currentDate = startDate
            while currentDate <= endDate {
                let weekday = calendar.component(.weekday, from: currentDate)
                let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let currentDay = dayNames[weekday - 1]
                
                if schedule.days.contains(currentDay) {
                    let startComponentsTime = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
                    var startComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    startComponents.hour = startComponentsTime.hour
                    startComponents.minute = startComponentsTime.minute
                    
                    if let eventStart = calendar.date(from: startComponents) {
                        let endComponentsTime = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
                        var endComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                        endComponents.hour = endComponentsTime.hour
                        endComponents.minute = endComponentsTime.minute
                        
                        if let eventEnd = calendar.date(from: endComponents) {
                            dataStore.addEvent(
                                title: classItem.name,
                                start: eventStart,
                                end: eventEnd,
                                category: "Classes",
                                className: classItem.name
                            )
                        }
                    }
                }
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func changeWeek(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value * 7, to: localSelectedDate) {
            localSelectedDate = newDate
            // Keep currentMonth aligned with the visible week
            if !calendar.isDate(newDate, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = newDate
            }
        }
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(visibleDays.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    calendarDayButton(for: date)
                } else {
                    Text("")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    // Only trigger if horizontal swipe is dominant
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount < 0 {
                            // Swipe left - go to next week/month
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isWeekMode {
                                    changeWeek(by: 1)
                                } else {
                                    changeMonth(by: 1)
                                }
                            }
                        } else {
                            // Swipe right - go to previous week/month
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if isWeekMode {
                                    changeWeek(by: -1)
                                } else {
                                    changeMonth(by: -1)
                                }
                            }
                        }
                    }
                }
        )
    }
    
    private func calendarDayButton(for date: Date) -> some View {
        Button {
            localSelectedDate = date
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.body)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(calendar.isDate(date, inSameDayAs: localSelectedDate) ? Color.blue.opacity(0.3) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .foregroundStyle(.primary)
        }
    }
    
    private var dateDisplaySection: some View {
        HStack(spacing: 12) {
            if isEditingDate {
                dateTextField
            } else {
                // Non-clickable date text
                Text(formattedDate)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            // Only the calendar icon is clickable
            Button {
                isEditingDate = true
                dateText = formattedDateForEditing
            } label: {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var dateTextField: some View {
        DatePicker(
            "Select Date",
            selection: $localSelectedDate,
            displayedComponents: .date
        )
        .labelsHidden()
        .datePickerStyle(.compact)
        .padding(.horizontal, 4)
        .onChange(of: localSelectedDate) { oldValue, newDate in
            // Only auto-dismiss if the date actually changed
            if oldValue != newDate {
                // Update month and dismiss after a brief delay to allow the picker to close smoothly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    currentMonth = newDate
                    isEditingDate = false
                }
            }
        }
    }
    
    private var dateDisplayButton: some View {
        Button {
            isEditingDate = true
            dateText = formattedDateForEditing
        } label: {
            Text(formattedDate)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .background(Color(.systemGray6))
    }
    
    private func tabButton(for tab: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Text(tab)
                .font(.subheadline)
                .fontWeight(selectedTab == tab ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(selectedTab == tab ? Color.blue : Color.clear),
                    alignment: .bottom
                )
        }
        .foregroundStyle(.primary)
    }
    
    private var contentArea: some View {
        ZStack(alignment: .bottomTrailing) {
            eventsListView
            // Only show add button for non-Classes tabs
            if selectedTab != "Classes" {
                floatingActionButton
            }
        }
    }
    
    private var studyScheduleView: some View {
        AIStudyScheduleView(
            selectedDate: localSelectedDate,
            onBackToCalendar: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = showScheduleMode ? "Schedule" : "Classes"
                }
            },
            onStartSession: { block in
                if block.type == "Classes" {
                    activeClassCheckInBlock = block
                } else if block.type == "Extra Curriculars" {
                    // Extra Curriculars are just activities, not study sessions
                    // Do nothing - they're reference blocks only
                    return
                } else {
                    // Only open study session for actual study blocks
                    activeBlock = block
                }
            }
        )
        .environmentObject(dataStore)
        .id(localSelectedDate) // Force refresh when date changes
    }

    private var sortedFilteredEvents: [CalendarEvent] {
        let selectedDateStart = calendar.startOfDay(for: localSelectedDate)
        let selectedDateEnd = calendar.date(byAdding: .day, value: 1, to: selectedDateStart) ?? localSelectedDate

        let filtered = dataStore.events.filter { event in
            guard event.start >= selectedDateStart && event.start < selectedDateEnd else {
                return false
            }

            if showScheduleMode {
                if selectedTab == "Schedule" {
                    return true
                }
                if selectedTab == "Classes" {
                    return event.category == "Classes"
                }
                if selectedTab == "Extra Curriculars" {
                    return event.category == "Extra Curriculars"
                }
                return false
            }

            if selectedTab == "Classes" {
                return event.category == "Classes"
            }
            if selectedTab == "Extra Curriculars" {
                return event.category == "Extra Curriculars"
            }
            return false
        }

        return filtered.sorted { $0.start < $1.start }
    }
    
    private var eventsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if sortedFilteredEvents.isEmpty {
                    Text("No events for this day")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(Array(sortedFilteredEvents.enumerated()), id: \.element.id) { index, event in
                        EventRow(
                            event: event,
                            selectedDate: localSelectedDate,
                            isLast: index == sortedFilteredEvents.count - 1,
                            onToggle: {
                                dataStore.toggleEventCompletion(event)
                            }
                        )
                    }
                }
            }
            .padding()
            .padding(.bottom, 60)
        }
    }
    
    private var floatingActionButton: some View {
        Button {
            showAddEvent = true
        } label: {
            if (selectedTab == "Schedule" && showScheduleMode) || (selectedTab == "Classes" && showScheduleMode) {
                studyHoursButton
            } else {
                addButton
            }
        }
        .padding()
    }
    
    private var studyHoursButton: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", studyHoursToday))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("hrs")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 56, height: 56)
        .background(Circle().fill(Color.orange))
        .shadow(radius: 4)
    }
    
    private var addButton: some View {
        Image(systemName: "plus")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color.blue))
            .shadow(radius: 4)
    }
    
    private var addEventSheet: some View {
        AddEventSheet(category: selectedTab, selectedDate: localSelectedDate) { title, time, dates, actualCategory, className in
            for date in dates {
                // Use the date directly - it already has the correct time
                dataStore.addEvent(
                    title: title,
                    start: date,
                    end: date,
                    category: actualCategory,
                    timeString: time,
                    className: className
                )
            }
        }
    }
    
    private func parseTimeString(_ timeString: String, for date: Date) -> Date? {
        let calendar = Calendar.current
        let lowercased = timeString.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Try to parse time formats like "3:30pm", "11:00am", "5pm"
        let timePattern = #/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/#
        
        if let match = lowercased.firstMatch(of: timePattern) {
            var hour = Int(match.1) ?? 0
            let minute = match.2.map { Int($0) ?? 0 } ?? 0
            let isPM = match.3?.lowercased() == "pm"
            
            // Convert to 24-hour format
            if isPM && hour != 12 {
                hour += 12
            } else if !isPM && hour == 12 {
                hour = 0
            }
            
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        }

        return nil
    }
    
    private func checkIfDueToday(event: CalendarEvent, selectedDate: Date) -> Bool {
        // Parse the timeString for due dates like "Due @ 11pm 11/1" or "11/1/25"
        let timeString = event.timeString.lowercased()
        
        // Extract date patterns like "11/1", "11/1/25", "11/01/2025"
        let datePattern = #/(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?/#
        
        if let match = timeString.firstMatch(of: datePattern) {
            let month = Int(match.1) ?? 0
            let day = Int(match.2) ?? 0
            var year = calendar.component(.year, from: Date())
            
            if let yearMatch = match.3 {
                let yearInt = Int(yearMatch) ?? 0
                year = yearInt < 100 ? 2000 + yearInt : yearInt
            }
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            
            if let dueDate = calendar.date(from: components) {
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
        }
        
        return false
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: localSelectedDate)
    }
    
    private var formattedDateForEditing: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: localSelectedDate)
    }
    
    private func parseAndJumpToDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        if let newDate = formatter.date(from: dateText) {
            localSelectedDate = newDate
            currentMonth = newDate
        }
        
        isEditingDate = false
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).uppercased()
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var studyHoursToday: Double {
        // Calculate total study hours from the study schedule for the selected date
        let selectedDateStart = calendar.startOfDay(for: localSelectedDate)
        
        // Safety check: return 0 if dataStore isn't ready
        guard !dataStore.events.isEmpty else { return 0.0 }
        
        // Get all incomplete tests, exams, and assignments due on or after selected date
        let schoolWork = dataStore.events.filter { event in
            (event.category == "Tests" || event.category == "Exams" || event.category == "Assignments") &&
            !event.isCompleted &&
            event.start >= selectedDateStart
        }
        
        // Calculate study duration based on urgency (simplified version of the algorithm)
        let maxBlocksPerDay = 8
        var totalMinutes = 0
        for work in schoolWork.prefix(maxBlocksPerDay) {
            let daysUntilDue = calendar.dateComponents([.day], from: selectedDateStart, to: calendar.startOfDay(for: work.start)).day ?? 0
            
            let baseDuration: Int
            switch work.category {
            case "Tests", "Exams":
                baseDuration = daysUntilDue <= 2 ? 50 : 40
            case "Assignments":
                baseDuration = 35
            default:
                baseDuration = 30
            }
            
            let duration: Int
            if daysUntilDue <= 1 {
                duration = min(baseDuration + 10, 50)
            } else if daysUntilDue <= 3 {
                duration = baseDuration
            } else {
                duration = max(baseDuration - 10, 25)
            }
            
            totalMinutes += duration
        }
        
        // Add 20 minutes for each class review
        let todayClasses = dataStore.events.filter { event in
            calendar.isDate(event.start, inSameDayAs: localSelectedDate) &&
            event.category == "Classes"
        }
        totalMinutes += todayClasses.count * 20
        
        return Double(totalMinutes) / 60.0 // Convert to hours
    }
}

struct EventCard: View {
    let event: CalendarEvent
    let selectedDate: Date
    var onToggle: () -> Void
    
    @State private var showEditSheet = false
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox (hidden for Classes)
            if event.category != "Classes" {
                Button {
                    onToggle()
                } label: {
                    Image(systemName: event.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(event.isCompleted ? Color.secondary : Color.blue)
                }
            }
            
            Button {
                showEditSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .strikethrough(event.isCompleted, color: .secondary)
                        .foregroundStyle(event.isCompleted ? .secondary : .primary)
                    Text(event.timeString)
                        .font(.subheadline)
                        .strikethrough(event.isCompleted, color: .secondary)
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            
            // Show category label for Tests and Assignments
            if event.category == "Tests" || event.category == "Assignments" {
                if isOverdue {
                    Text("Overdue")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                } else if isDueToday {
                    Text("Due Today")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                } else {
                    Text(categoryLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showEditSheet) {
            EditEventSheet(event: event)
        }
    }
    
    private var isOverdue: Bool {
        // Check if event is past due time and not completed
        return event.start < Date() && !event.isCompleted
    }
    
    private var isDueToday: Bool {
        // Check if the selected date matches a due date in the timeString
        let timeString = event.timeString.lowercased()
        
        // Extract date patterns like "11/1", "11/1/25", "11/01/2025"
        let datePattern = #/(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?/#
        
        if let match = timeString.firstMatch(of: datePattern) {
            let month = Int(match.1) ?? 0
            let day = Int(match.2) ?? 0
            var year = calendar.component(.year, from: Date())
            
            if let yearMatch = match.3 {
                let yearInt = Int(yearMatch) ?? 0
                year = yearInt < 100 ? 2000 + yearInt : yearInt
            }
            
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            
            if let dueDate = calendar.date(from: components) {
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
        }
        
        return false
    }
    
    private var categoryLabel: String {
        switch event.category {
        case "Tests": return "Test"
        case "Assignments": return "Assignment"
        default: return ""
        }
    }
}

// MARK: - Add Event Sheet
struct AddEventSheet: View {
    let category: String
    let selectedDate: Date
    var onAdd: (String, String, [Date], String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var dueDate: Date
    @State private var endDate: Date
    @State private var showRepeatOptions = false
    @State private var repeatOption: RepeatOption = .none
    @State private var schoolWorkType: String = "Assignments" // Default to Assignments
    @State private var selectedClass: String = "None"
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("classSchedulesData") private var classSchedulesData: Data = Data()
    @State private var classSchedules: [UUID: ClassScheduleInfo] = [:]
    @FocusState private var isTitleFocused: Bool
    @State private var showDebugAlert = false
    @State private var debugMessage = ""
    
    init(category: String, selectedDate: Date, onAdd: @escaping (String, String, [Date], String, String?) -> Void) {
        self.category = category
        self.selectedDate = selectedDate
        self.onAdd = onAdd
        
        // Initialize dueDate with a default time component
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = 12
        components.minute = 0
        let dateWithTime = calendar.date(from: components) ?? selectedDate
        _dueDate = State(initialValue: dateWithTime)
        
        // Initialize endDate to 1 hour after start time
        let endTime = calendar.date(byAdding: .hour, value: 1, to: dateWithTime) ?? dateWithTime
        _endDate = State(initialValue: endTime)
    }
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Only show category for School Work (which has sub-types)
                    if category == "School Work" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category: \(category)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter name", text: $title)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Date Picker (not shown for Extra Curriculars - they use selectedDate)
                    if category != "Extra Curriculars" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category == "Classes" ? "Date" : "Due Date")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .padding(.horizontal)
                        }
                    } else {
                        // For Extra Curriculars, show the date but make it read-only
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            Text(selectedDate, style: .date)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Time Pickers (for Classes and Extra Curriculars)
                    if category == "Classes" || category == "Extra Curriculars" {
                        FiveMinuteTimePicker(date: $dueDate, label: "Start Time")
                            .padding(.horizontal)
                            .onChange(of: dueDate) { _, newStartTime in
                                // Automatically set end time to 1 hour after start time
                                endDate = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) ?? newStartTime
                            }
                        
                        FiveMinuteTimePicker(date: $endDate, label: "End Time")
                            .padding(.horizontal)
                    } else {
                        // Time Picker for other categories
                        FiveMinuteTimePicker(date: $dueDate, label: "Time")
                            .padding(.horizontal)
                    }
                    
                    // Class Picker (only shown for School Work category)
                    if category == "School Work" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            Picker("Class", selection: $selectedClass) {
                                Text("None").tag("None")
                                ForEach(studentClasses) { classItem in
                                    Text(classItem.name).tag(classItem.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal)
                            .onChange(of: selectedClass) { _, newClass in
                                updateTimeForClass(newClass)
                            }
                        }
                    }
                    
                    // School Work Type Picker (only shown for School Work category)
                    if category == "School Work" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                            
                            Picker("Type", selection: $schoolWorkType) {
                                Text("Assignment").tag("Assignments")
                                Text("Test").tag("Tests")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Repeat Options
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            showRepeatOptions.toggle()
                        } label: {
                            HStack {
                                Text("Repeats")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(repeatOption.displayName)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        if !title.isEmpty {
                            addEventsWithRepeat()
                            dismiss()
                        }
                    } label: {
                        Text("Add \(categoryName)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Group {
                                    if title.isEmpty {
                                        Color.gray
                                    } else {
                                        Color.blue
                                    }
                                }
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(title.isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.never)
            .navigationTitle("Add \(categoryName)")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isTitleFocused = true
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showRepeatOptions) {
                RepeatOptionsSheet(selectedOption: $repeatOption)
            }
            .onAppear {
                loadClassSchedules()
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(false)
        .alert("Debug Info", isPresented: $showDebugAlert) {
            Button("OK") { }
        } message: {
            Text(debugMessage)
        }
    }
    
    private func addEventsWithRepeat() {
        // Use dueDate directly for all categories (same as Classes)
        let finalDate = dueDate
        
        // Debug output
        let debugFormatter = DateFormatter()
        debugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("🔍 Save Debug (\(category)):")
        print("  📅 selectedDate: \(debugFormatter.string(from: selectedDate))")
        print("  ⏰ dueDate: \(debugFormatter.string(from: dueDate))")
        print("  ✅ finalDate: \(debugFormatter.string(from: finalDate))")
        
        let dates = repeatOption.generateDates(from: finalDate, count: repeatOption.occurrenceCount)
        let actualCategory = category == "School Work" ? schoolWorkType : category
        let className = (selectedClass != "None") ? selectedClass : nil
        
        // Format the date/time as a string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy h:mm a"
        let timeString = dateFormatter.string(from: finalDate)
        
        // Keep console logging for debugging, but do not show any user-facing alert
        print("  💾 timeString being saved: \(timeString)")
        
        onAdd(title, timeString, dates, actualCategory, className)
    }
    
    private var categoryName: String {
        switch category {
        case "School Work": 
            return schoolWorkType == "Tests" ? "Test" : "Assignment"
        case "Classes": return "Class"
        case "Extra Curriculars": return "Activity"
        case "Tests": return "Test"
        case "Assignments": return "Assignment"
        default: return "Event"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
        return formatter.string(from: dueDate)
    }
    
    private var titlePlaceholder: String {
        switch category {
        case "Classes": return "Class name"
        case "Extra Curriculars": return "Activity name"
        case "School Work": return schoolWorkType == "Tests" ? "Test name" : "Assignment name"
        default: return "Title"
        }
    }
    
    private func loadClassSchedules() {
        if let decoded = try? JSONDecoder().decode([UUID: ClassScheduleInfo].self, from: classSchedulesData) {
            classSchedules = decoded
        }
    }
    
    private func updateTimeForClass(_ className: String) {
        guard className != "None",
              let selectedClassItem = studentClasses.first(where: { $0.name == className }),
              let schedule = classSchedules[selectedClassItem.id] else {
            return
        }
        
        // Get the day of week for the selected date
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: dueDate)
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let selectedDay = dayNames[weekdayIndex - 1]
        
        // Check if the class meets on this day
        if schedule.days.contains(selectedDay) {
            // Update the dueDate with the class start time
            let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            if let newDate = calendar.date(from: dateComponents) {
                dueDate = newDate
            }
        }
    }
}

// MARK: - Repeat Options
enum RepeatOption: CaseIterable {
    case none
    case daily
    case everyOtherDay
    case weekly
    case biWeekly
    case monthly
    case biMonthly
    
    var displayName: String {
        switch self {
        case .none: return "Never"
        case .daily: return "Every Day"
        case .everyOtherDay: return "Every Other Day"
        case .weekly: return "Weekly"
        case .biWeekly: return "Bi-Weekly"
        case .monthly: return "Monthly"
        case .biMonthly: return "Bi-Monthly"
        }
    }
    
    var occurrenceCount: Int {
        switch self {
        case .none: return 1
        case .daily: return 30 // 30 days
        case .everyOtherDay: return 15 // 30 days worth
        case .weekly: return 12 // ~3 months
        case .biWeekly: return 6 // ~3 months
        case .monthly: return 6 // 6 months
        case .biMonthly: return 3 // 6 months
        }
    }
    
    func generateDates(from startDate: Date, count: Int) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<count {
            let date: Date?
            switch self {
            case .none:
                date = startDate
            case .daily:
                date = calendar.date(byAdding: .day, value: i, to: startDate)
            case .everyOtherDay:
                date = calendar.date(byAdding: .day, value: i * 2, to: startDate)
            case .weekly:
                date = calendar.date(byAdding: .weekOfYear, value: i, to: startDate)
            case .biWeekly:
                date = calendar.date(byAdding: .weekOfYear, value: i * 2, to: startDate)
            case .monthly:
                date = calendar.date(byAdding: .month, value: i, to: startDate)
            case .biMonthly:
                date = calendar.date(byAdding: .month, value: i * 2, to: startDate)
            }
            
            if let date = date {
                dates.append(date)
            }
        }
        
        return dates
    }
}

// MARK: - Repeat Options Sheet
struct RepeatOptionsSheet: View {
    @Binding var selectedOption: RepeatOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(RepeatOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Edit Event Sheet
struct EditEventSheet: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    
    @State private var title: String
    @State private var time: String
    @State private var eventDate: Date
    @State private var selectedCategory: String
    @State private var selectedClass: String = "None"
    @State private var repeatOption: RepeatOption = .none
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @FocusState private var isTitleFocused: Bool
    
    private let categories = ["Classes", "Extra Curriculars", "Tests", "Assignments"]
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    init(event: CalendarEvent) {
        self.event = event
        self._title = State(initialValue: event.title)
        self._time = State(initialValue: event.timeString)
        self._eventDate = State(initialValue: event.start)
        self._selectedCategory = State(initialValue: event.category)
        self._selectedClass = State(initialValue: event.className ?? "None")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date: \(formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter title", text: $title)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Time input - DatePicker for Classes, TextField for others
                if selectedCategory == "Classes" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        FiveMinuteTimePicker(date: $eventDate, label: "Time")
                            .padding(.horizontal)
                    }
                } else {
                    TextField("Time (e.g., 5:06pm or 7/2/25)", text: $time)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                
                // Class Picker (only for Tests and Assignments)
                if selectedCategory == "Tests" || selectedCategory == "Assignments" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Class")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        Picker("Class", selection: $selectedClass) {
                            Text("None").tag("None")
                            ForEach(studentClasses) { classItem in
                                Text(classItem.name).tag(classItem.name)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // Repeat Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repeat")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Picker("Repeat", selection: $repeatOption) {
                        Text("Never").tag(RepeatOption.none)
                        Text("Every Day").tag(RepeatOption.daily)
                        Text("Every Other Day").tag(RepeatOption.everyOtherDay)
                        Text("Weekly").tag(RepeatOption.weekly)
                        Text("Bi-Weekly").tag(RepeatOption.biWeekly)
                        Text("Monthly").tag(RepeatOption.monthly)
                        Text("Bi-Monthly").tag(RepeatOption.biMonthly)
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Button {
                        deleteEvent()
                    } label: {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    
                    Button {
                        saveChanges()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Group {
                                    if title.isEmpty || time.isEmpty {
                                        Color.gray
                                    } else {
                                        Color.blue
                                    }
                                }
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(title.isEmpty || time.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            }
            .navigationTitle("Edit \(categoryName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveChanges() {
        // Format time string based on category
        let timeString: String
        if selectedCategory == "Classes" {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            timeString = formatter.string(from: eventDate)
        } else {
            timeString = time
        }
        
        // Convert "None" to nil for className
        let className = (selectedClass != "None") ? selectedClass : nil
        
        // If repeat is set to something other than "None", create additional events
        if repeatOption != .none {
            let dates = repeatOption.generateDates(from: event.start, count: repeatOption.occurrenceCount)
            
            // Update the original event with className
            dataStore.updateEventFull(event, newTitle: title, newStart: eventDate, newEnd: eventDate, newTimeString: timeString, newCategory: selectedCategory, newClassName: className)
            
            // Create new events for the remaining dates (skip first as it's the original)
            for date in dates.dropFirst() {
                let startDate = parseTimeString(timeString, for: date) ?? date
                dataStore.addEvent(
                    title: title,
                    start: startDate,
                    end: startDate,
                    category: selectedCategory,
                    timeString: timeString,
                    className: className
                )
            }
        } else {
            // Just update the single event with className
            dataStore.updateEventFull(event, newTitle: title, newStart: eventDate, newEnd: eventDate, newTimeString: timeString, newCategory: selectedCategory, newClassName: className)
        }
        dismiss()
    }
    
    private func parseTimeString(_ timeString: String, for date: Date) -> Date? {
        let calendar = Calendar.current
        let lowercased = timeString.lowercased().trimmingCharacters(in: .whitespaces)
        
        let timePattern = #/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/#
        
        if let match = lowercased.firstMatch(of: timePattern) {
            var hour = Int(match.1) ?? 0
            let minute = match.2.map { Int($0) ?? 0 } ?? 0
            let isPM = match.3?.lowercased() == "pm"
            
            if isPM && hour != 12 {
                hour += 12
            } else if !isPM && hour == 12 {
                hour = 0
            }
            
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        }
        
        return nil
    }
    
    private func deleteEvent() {
        dataStore.deleteEvent(event)
        dismiss()
    }
    
    private var categoryName: String {
        switch event.category {
        case "Classes": return "Class"
        case "Extra Curriculars": return "Activity"
        case "Tests": return "Test"
        case "Assignments": return "Assignment"
        default: return "Event"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: event.start)
    }
    
    private var titlePlaceholder: String {
        switch selectedCategory {
        case "Classes": return "Class name"
        case "Extra Curriculars": return "Activity name"
        case "Tests": return "Test name"
        case "Assignments": return "Assignment name"
        default: return "Title"
        }
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: CalendarEvent
    let selectedDate: Date
    let isLast: Bool
    let onToggle: () -> Void
    
    @EnvironmentObject var dataStore: DataStore
    @State private var showEditSheet = false
    
    private var timeString: String {
        guard let start = event.start as Date? else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: start)
    }
    
    private var dateString: String {
        guard let start = event.start as Date? else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: start)
    }
    
    private var isSchoolWork: Bool {
        return event.category == "Assignments" || event.category == "Tests" || event.category == "Exams"
    }
    
    var body: some View {
        // Safety check: only render if we have valid data
        if event.title.isEmpty {
            EmptyView()
        } else {
            eventRow
        }
    }
    
    private var eventRow: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline column
            VStack(spacing: 0) {
                // Time label (or date for school work)
                Text(isSchoolWork ? dateString : timeString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.top, 4)
                
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            
            // Dot and line column
            VStack(spacing: 0) {
                // Dot
                Circle()
                    .fill(
                       LinearGradient(
                            colors: [Color.blue.opacity(0.7), Color.blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Vertical line
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }
            .frame(width: 12)
            
            // Event card
            Button {
                showEditSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            // Show due time for school work
                            if isSchoolWork {
                                Text("Due: \(timeString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(0.7))
                            }
                            
                            HStack(spacing: 8) {
                                // Category badge (only for school work, not Classes/Extra Curriculars)
                                if event.category != "Classes" && event.category != "Extra Curriculars" {
                                    Text(categoryDisplayName(for: event.category))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(categoryColor(for: event.category))
                                        )
                                }
                                
                                // Show location only for Classes/Extra Curriculars, not for Tests/Assignments
                                if event.category == "Classes" || event.category == "Extra Curriculars" {
                                    if let location = event.location, !location.isEmpty, !location.contains("NSManagedObject") {
                                        HStack(spacing: 4) {
                                            Image(systemName: "location.fill")
                                                .font(.caption2)
                                            Text(location)
                                                .font(.caption)
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Show className badge for school work ONLY (not for Classes/Extra Curriculars)
                        if isSchoolWork, let className = event.className, !className.isEmpty, className.uppercased() != "NONE" {
                            Text(className)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }
                        
                        // Only show checkbox for school work
                        if isSchoolWork {
                            Button {
                                onToggle()
                            } label: {
                                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(event.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, isLast ? 0 : 12)
        .sheet(isPresented: $showEditSheet) {
            EditEventSheet(event: event)
                .environmentObject(dataStore)
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Assignments": return Color.orange
        case "Tests", "Exams": return Color.red
        case "Classes": return Color.purple
        case "Extra Curriculars": return Color.green
        default: return Color.blue
        }
    }
    
    private func categoryDisplayName(for category: String) -> String {
        switch category {
        case "Assignments": return "Assignment"
        case "Tests": return "Test"
        case "Exams": return "Exam"
        default: return category
        }
    }
}

// MARK: - AI Study Schedule View
struct AIStudyScheduleView: View {
    let selectedDate: Date
    var onBackToCalendar: (() -> Void)? = nil
    var onStartSession: ((StudyBlock) -> Void)? = nil
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.modelContext) private var modelContext
    @Query private var customStudyBlocksQuery: [CustomStudyBlockSD]
    @AppStorage("earliestStudyHour") private var earliestStudyHour: Int = 7
    @AppStorage("latestStudyHour") private var latestStudyHour: Int = 22
    @AppStorage("reminderDaysAhead") private var reminderDaysAhead: Int = 7
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @AppStorage("showReviewBlocks") private var showReviewBlocks: Bool = true
    @State private var studyBlocks: [StudyBlock] = []
    @State private var expandedBlocks: Set<UUID> = []
    @State private var focusToday: Bool = false
    @State private var showAddCustomBlock: Bool = false
    @State private var dayTimeline: DayTimeline? = nil
    @State private var overlapWarnings: [String] = []
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        // Debug: Print current classes to verify updates
        print("📚 Study Schedule - Current classes: \(decoded.map { $0.name })")
        return decoded
    }

    private func classColorHex(for className: String?) -> String? {
        guard let name = className else { return nil }
        return studentClasses.first(where: { $0.name == name })?.color
    }
    
    var body: some View {
        // Force view to update when studentClassesData changes
        let _ = studentClassesData // Access to create dependency
        
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView {
                if studyBlocks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                        Text("No study sessions needed today!")
                            .font(.headline)
                        Text("You're all caught up. Enjoy your free time!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        // Show overlap warnings if any
                        if !overlapWarnings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Schedule Conflicts")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                }
                                
                                ForEach(overlapWarnings, id: \.self) { warning in
                                    Text(warning)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 8)
                        }
                        
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "target")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.blue)
                                Text("Focus Today")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Toggle("", isOn: $focusToday)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6).opacity(0.5))
                        )
                        .padding(.horizontal, 8)

                        VStack(alignment: .leading, spacing: 24) {
                            // Show current time indicator before first block if we're before schedule starts
                            if shouldShowCurrentTimeBeforeFirstBlock {
                                currentTimeIndicator
                                    .id("currentTime")
                            }
                            
                            ForEach(Array(studyBlocks.enumerated()), id: \.element.id) { index, block in
                                let isExpanded = expandedBlocks.contains(block.id)
                                let isFocusTarget: Bool = {
                                    if !focusToday { return true }
                                    if block.isCompact { return true }
                                    // Focus Today: Only show work due within 2 days (today or tomorrow)
                                    // Blur everything due 2+ days from now
                                    if let daysUntilDue = block.daysUntilDue {
                                        return daysUntilDue <= 1  // 0 = today, 1 = tomorrow
                                    }
                                    return true  // Show if no due date
                                }()

                                StudyBlockCard(
                                    block: block,
                                    isExpanded: isExpanded,
                                    onToggleExpanded: {
                                        if isExpanded {
                                            expandedBlocks.remove(block.id)
                                        } else {
                                            expandedBlocks.insert(block.id)
                                        }
                                    }
                                )
                                .opacity(isFocusTarget ? 1.0 : 0.25)
                                .padding(.vertical, 4)
                                .id(block.id)
                                .onTapGesture {
                                    onStartSession?(block)
                                }
                                
                                // Show "Current Time" indicator if we're in free time between blocks
                                if shouldShowCurrentTimeAfter(block: block, nextBlock: studyBlocks[safe: index + 1]) {
                                    currentTimeIndicator
                                        .id("currentTime")
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showAddCustomBlock) {
                QuickAddStudyBlockSheet(selectedDate: selectedDate, modelContext: modelContext, userId: dataStore.userId) {
                    regenerateSchedule()
                }
            }
            .onAppear {
                if studyBlocks.isEmpty {
                    regenerateSchedule()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
            .onChange(of: dataStore.events.count) { _, _ in
                regenerateSchedule()
            }
            .onChange(of: reminderDaysAhead) { _, _ in
                regenerateSchedule()
            }
            .onChange(of: studentClassesData) { _, _ in
                // Regenerate schedule when classes are added/removed in My Classes
                print("📚 Study Schedule - Classes changed, regenerating schedule")
                regenerateSchedule()
            }
            .onChange(of: selectedDate) { _, _ in
                // Regenerate schedule when date changes
                print("📚 Study Schedule - Date changed, regenerating schedule")
                regenerateSchedule()
            }
            .onChange(of: studyBlocks.count) { _, _ in
                // Re-scroll when blocks change
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
            .onChange(of: customStudyBlocksQuery.count) { _, _ in
                // Regenerate schedule when custom blocks change
                regenerateSchedule()
            }
            }
            
            // Floating + button
            Button(action: {
                showAddCustomBlock = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var shouldShowCurrentTimeBeforeFirstBlock: Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if we're viewing today
        guard calendar.isDateInToday(selectedDate) else { return false }
        
        // Check if there are any blocks
        guard let firstBlock = studyBlocks.first else { return false }
        
        // Show indicator if current time is before the first block starts
        return now < firstBlock.startTime
    }
    
    private func shouldShowCurrentTimeAfter(block: StudyBlock, nextBlock: StudyBlock?) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let blockEndTime = calendar.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        
        // Check if current time is after this block ends
        guard now >= blockEndTime else { return false }
        
        // If there's a next block, check if current time is before it starts
        if let next = nextBlock {
            return now < next.startTime
        }
        
        // If no next block, show indicator once after the final block when viewing today
        // so the user still sees "Current Time" even after the last session.
        return calendar.isDateInToday(selectedDate)
    }
    
    private var currentTimeIndicator: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time on the left
            Text(currentTimeString)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 2, height: 30)
            }
            
            // Content block
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Time")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Free Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
            )
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let now = Date()
        let calendar = Calendar.current
        
        // First, check if we're currently IN a block
        for block in studyBlocks {
            let blockEndTime = calendar.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
            
            // If we're currently in this block (between start and end time)
            if now >= block.startTime && now < blockEndTime {
                withAnimation {
                    proxy.scrollTo(block.id, anchor: .center)
                }
                return
            }
        }
        
        // Second, check if we're in free time (currentTime indicator is showing)
        for (index, block) in studyBlocks.enumerated() {
            if shouldShowCurrentTimeAfter(block: block, nextBlock: studyBlocks[safe: index + 1]) {
                // Scroll to the current time indicator
                withAnimation {
                    proxy.scrollTo("currentTime", anchor: .center)
                }
                return
            }
        }
        
        // Finally, find the next upcoming block
        for block in studyBlocks {
            if now < block.startTime {
                withAnimation {
                    proxy.scrollTo(block.id, anchor: .center)
                }
                return
            }
        }
    }
    
    // MARK: - Timeline-Based Schedule Generation (Strict Overlap Prevention)
    private func regenerateSchedule() {
        let timeline = DayTimeline(date: selectedDate, earliestHour: earliestStudyHour, latestHour: latestStudyHour)
        dayTimeline = timeline
        overlapWarnings = []
        
        let calendar = Calendar.current
        
        // STEP 1: Add all locked blocks first (classes, extracurriculars, sleep)
        let scheduledEvents = dataStore.events.filter { event in
            calendar.isDate(event.start, inSameDayAs: selectedDate) &&
            (event.category == "Classes" || event.category == "Extra Curriculars")
        }
        
        for event in scheduledEvents {
            let startMinute = DayTimeline.dateToMinutes(date: event.start, calendar: calendar)
            let endMinute = startMinute + 60 // Default 1 hour for classes
            
            let block = ScheduleBlock(
                startMinute: startMinute,
                endMinute: endMinute,
                blockType: event.category == "Classes" ? .scheduledClass : .extracurricular,
                title: event.title,
                subject: nil,
                className: event.category == "Classes" ? event.title : event.className,
                classColorHex: classColorHex(for: event.category == "Classes" ? event.title : event.className),
                isLocked: true
            )
            
            do {
                try timeline.addBlock(block)
            } catch {
                overlapWarnings.append("⚠️ Couldn't add \(event.title): \(error.localizedDescription)")
            }
        }
        
        // STEP 2: Add custom study blocks (if they don't overlap)
        let customBlocks = customStudyBlocksQuery.filter { customBlock in
            calendar.isDate(customBlock.startTime, inSameDayAs: selectedDate) &&
            customBlock.userId == dataStore.userId
        }
        
        for customBlock in customBlocks {
            let startMinute = DayTimeline.dateToMinutes(date: customBlock.startTime, calendar: calendar)
            let endMinute = startMinute + customBlock.duration
            
            let block = ScheduleBlock(
                startMinute: startMinute,
                endMinute: endMinute,
                blockType: .customStudy,
                title: customBlock.title,
                subject: customBlock.className,
                className: customBlock.className,
                classColorHex: classColorHex(for: customBlock.className),
                priority: .medium,
                strategy: "Your custom study time"
            )
            
            do {
                try timeline.addBlock(block)
            } catch {
                overlapWarnings.append("⚠️ Custom block '\(customBlock.title)' conflicts with scheduled event")
            }
        }
        
        // STEP 3: Get school work to schedule
        let selectedDateStart = calendar.startOfDay(for: selectedDate)
        let schoolWork = dataStore.events.filter { event in
            let lower = event.category.lowercased()
            let isSchoolWork = lower == "tests" || lower == "exams" || lower == "test" || 
                               lower == "exam" || lower == "assignments" || lower == "assignment"
            guard isSchoolWork && !event.isCompleted else { return false }
            
            let eventDueDate = calendar.startOfDay(for: event.start)
            let daysFromSelected = calendar.dateComponents([.day], from: selectedDateStart, to: eventDueDate).day ?? 0
            return daysFromSelected >= 0 && daysFromSelected <= reminderDaysAhead
        }.sorted { $0.start < $1.start }
        
        print("🔍 TIMELINE DEBUG - School work found: \(schoolWork.count)")
        schoolWork.forEach { work in
            let daysUntil = calendar.dateComponents([.day], from: selectedDateStart, to: calendar.startOfDay(for: work.start)).day ?? 0
            print("  - \(work.title): due in \(daysUntil) days, category: \(work.category)")
        }
        
        let prioritizedWork = prioritizeBySpacedRepetition(schoolWork, selectedDate: selectedDate, calendar: calendar)
        print("🔍 TIMELINE DEBUG - Prioritized work count: \(prioritizedWork.count)")
        
        // STEP 4: Use fit-first logic to place study blocks
        let todayMood = getRecentMood(for: selectedDate)
        let cognitiveCapacity = calculateCognitiveCapacity(mood: todayMood)
        let maxDailyStudyMinutes = calculateMaxStudyTime(mood: todayMood, cognitiveCapacity: cognitiveCapacity)
        
        print("🔍 TIMELINE DEBUG - Max daily study minutes: \(maxDailyStudyMinutes)")
        print("🔍 TIMELINE DEBUG - Available windows: \(timeline.getAvailableWindows().count)")
        timeline.getAvailableWindows().forEach { window in
            let startTime = DayTimeline.minutesToTime(minutes: window.start)
            let endTime = DayTimeline.minutesToTime(minutes: window.end)
            print("  Window: \(startTime.hour):\(String(format: "%02d", startTime.minute)) - \(endTime.hour):\(String(format: "%02d", endTime.minute)) (\(window.duration) mins)")
        }
        
        var totalStudyMinutes = 0
        
        for work in prioritizedWork {
            let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: selectedDate), 
                                                       to: calendar.startOfDay(for: work.start)).day ?? 0
            let isUrgent = daysUntilDue <= 1 // Due today or tomorrow
            
            // Urgent work always gets scheduled
            if !isUrgent && totalStudyMinutes >= maxDailyStudyMinutes {
                print("🔍 TIMELINE DEBUG - Skipping '\(work.title)' - hit daily limit (not urgent)")
                break
            }
            
            let optimalDuration = calculateOptimalSessionDuration(
                for: work,
                daysUntilDue: daysUntilDue,
                cognitiveCapacity: cognitiveCapacity,
                timeOfDay: Date()
            )
            
            let adjustedDuration = isUrgent ? optimalDuration : min(optimalDuration, maxDailyStudyMinutes - totalStudyMinutes)
            
            print("🔍 TIMELINE DEBUG - Processing '\(work.title)': days=\(daysUntilDue), urgent=\(isUrgent), optimal=\(optimalDuration), adjusted=\(adjustedDuration)")
            
            let strategy = getStudyStrategy(for: work, daysUntilDue: daysUntilDue, mood: todayMood)
            let priority = getPriority(daysUntilDue: daysUntilDue)
            
            // Try to fit the block
            if let fitted = timeline.fitBlock(
                duration: adjustedDuration,
                blockType: .studyBlock,
                title: work.title,
                subject: work.className ?? "General",
                className: work.className,
                classColorHex: classColorHex(for: work.className),
                dueDate: work.start,
                priority: priority,
                strategy: strategy
            ) {
                totalStudyMinutes += fitted.duration
                print("✅ TIMELINE DEBUG - Successfully fitted '\(work.title)' (\(fitted.duration) mins)")
            } else if isUrgent {
                // URGENT WORK: Force schedule even if no window exists
                print("⚠️ URGENT - Forcing '\(work.title)' onto schedule")
                
                // Find the largest available window or create one at earliest hour
                let windows = timeline.getAvailableWindows()
                let startMinute: Int
                
                if let bestWindow = windows.max(by: { $0.duration < $1.duration }) {
                    startMinute = bestWindow.start
                } else {
                    // No windows - schedule at earliest study hour
                    startMinute = timeline.dayStartMinute
                }
                
                let block = ScheduleBlock(
                    startMinute: startMinute,
                    endMinute: startMinute + adjustedDuration,
                    blockType: .studyBlock,
                    title: work.title,
                    subject: work.className ?? "General",
                    className: work.className,
                    classColorHex: classColorHex(for: work.className),
                    dueDate: work.start,
                    priority: priority,
                    strategy: strategy
                )
                
                // Force add without validation for urgent work
                timeline.forceAddBlock(block)
                totalStudyMinutes += adjustedDuration
                print("✅ FORCED - Added urgent '\(work.title)' at \(startMinute) mins (\(adjustedDuration) mins)")
            } else {
                print("❌ TIMELINE DEBUG - Failed to fit '\(work.title)' - no available window")
                overlapWarnings.append("⚠️ Couldn't fit study block for '\(work.title)' - no available time")
            }
        }
        
        print("🔍 TIMELINE DEBUG - Final total study minutes: \(totalStudyMinutes)")
        
        // STEP 5: Convert timeline blocks to StudyBlocks for rendering
        studyBlocks = timeline.getSortedBlocks().map { scheduleBlock in
            let startTime = DayTimeline.minutesToDate(minutes: scheduleBlock.startMinute, 
                                                      onDay: selectedDate, calendar: calendar)
            
            return StudyBlock(
                id: scheduleBlock.id,
                title: scheduleBlock.title,
                subject: scheduleBlock.subject ?? scheduleBlock.blockType.rawValue,
                startTime: startTime,
                duration: scheduleBlock.duration,
                dueDate: scheduleBlock.dueDate,
                daysUntilDue: scheduleBlock.dueDate != nil ? 
                    calendar.dateComponents([.day], from: selectedDate, to: scheduleBlock.dueDate!).day : nil,
                priority: scheduleBlock.priority ?? .medium,
                strategy: scheduleBlock.strategy ?? "",
                type: scheduleBlock.blockType == .scheduledClass ? "Classes" : 
                      scheduleBlock.blockType == .extracurricular ? "Extra Curriculars" :
                      scheduleBlock.blockType == .customStudy ? "Custom" : "Study",
                classColorHex: scheduleBlock.classColorHex,
                isCompact: scheduleBlock.blockType == .scheduledClass || scheduleBlock.blockType == .extracurricular
            )
        }
        
        // Log warnings if any
        if !overlapWarnings.isEmpty {
            print("⚠️ TIMELINE WARNINGS:")
            overlapWarnings.forEach { print($0) }
        }
    }
    
    private func generateOptimizedStudySchedule(for date: Date) -> [StudyBlock] {
        let calendar = Calendar.current
        var blocks: [StudyBlock] = []
        
        // Debug: Log all events to understand data state
        print("📊 STUDY SCHEDULE DEBUG - Total events in dataStore: \(dataStore.events.count)")
        let categoryCounts = Dictionary(grouping: dataStore.events, by: { $0.category })
            .mapValues { $0.count }
        print("📊 STUDY SCHEDULE DEBUG - Events by category: \(categoryCounts)")
        print("📊 STUDY SCHEDULE DEBUG - All event titles: \(dataStore.events.map { "\($0.title) (\($0.category))" })")
        
        // Get all incomplete tests, exams, AND assignments
        let selectedDateStart = calendar.startOfDay(for: date)
        
        let schoolWork = dataStore.events.filter { event in
            // Check category - be flexible with capitalization
            let lower = event.category.lowercased()
            let isSchoolWork = lower == "tests" ||
                               lower == "exams" ||
                               lower == "test" ||
                               lower == "exam" ||
                               lower == "assignments" ||
                               lower == "assignment"

            // Always include incomplete school work in the schedule, even if
            // no class is assigned or the class no longer exists in My Classes.
            guard isSchoolWork && !event.isCompleted else {
                return false
            }

            let eventDueDate = calendar.startOfDay(for: event.start)

            // Calculate days from the SELECTED DATE to the event
            let daysFromSelected = calendar.dateComponents([.day], from: selectedDateStart, to: eventDueDate).day ?? 0

            // Show events that are:
            // 1. On or after the selected date (daysFromSelected >= 0)
            // 2. Within the reminder window (daysFromSelected <= reminderDaysAhead)
            // Example: If reminderDaysAhead = 3 and viewing 11/8, show test on 11/11 (3 days away)
            return daysFromSelected >= 0 && daysFromSelected <= reminderDaysAhead
        }.sorted { $0.start < $1.start }
        
        print("📊 STUDY SCHEDULE DEBUG - School work found: \(schoolWork.count)")
        if schoolWork.isEmpty {
            print("⚠️ STUDY SCHEDULE DEBUG - No assignments/tests/exams found!")
            print("⚠️ To generate study blocks, add assignments, tests, or exams from the + button")
        } else {
            schoolWork.forEach { work in
                let daysUntil = calendar.dateComponents([.day], from: selectedDateStart, to: calendar.startOfDay(for: work.start)).day ?? 0
                print("  - \(work.title): due in \(daysUntil) days, category: \(work.category), completed: \(work.isCompleted)")
            }
        }
        
        // Get classes and extracurriculars for the selected date
        let scheduledEvents = dataStore.events.filter { event in
            calendar.isDate(event.start, inSameDayAs: date) &&
            (event.category == "Classes" || event.category == "Extra Curriculars")
        }.sorted { $0.start < $1.start }
        
        // Get user's most recent mood (within 6 hours) to adjust cognitive load
        let todayMood = getRecentMood(for: date)
        let cognitiveCapacity = calculateCognitiveCapacity(mood: todayMood)
        
        // Calculate available study time slots with mood-aware optimization
        let availableSlots = calculateAvailableTimeSlots(on: date, avoiding: scheduledEvents, cognitiveCapacity: cognitiveCapacity)
        
        // EBBINGHAUS PRINCIPLE: Prioritize by spaced repetition intervals
        let prioritizedWork = prioritizeBySpacedRepetition(schoolWork, selectedDate: date, calendar: calendar)
        
        // NEWPORT PRINCIPLE: Limit total deep work to 4 hours max
        let maxDailyStudyMinutes = calculateMaxStudyTime(mood: todayMood, cognitiveCapacity: cognitiveCapacity)
        
        var slotIndex = 0
        var totalStudyMinutesToday = 0
        var currentTime: Date? = nil // Track actual current time for accurate scheduling
        
        for work in prioritizedWork {
            // Stop if we've run out of time slots or hit daily limit
            guard slotIndex < availableSlots.count,
                  totalStudyMinutesToday < maxDailyStudyMinutes else {
                break
            }
            
            let daysUntilDue = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: work.start)).day ?? 0
            
            // Determine actual start time: use currentTime if set, otherwise use slot time
            let actualStartTime = currentTime ?? availableSlots[slotIndex].start
            
            // CSIKSZENTMIHALYI PRINCIPLE: Match session length to flow state capacity
            let duration = calculateOptimalSessionDuration(
                for: work,
                daysUntilDue: daysUntilDue,
                cognitiveCapacity: cognitiveCapacity,
                timeOfDay: actualStartTime
            )
            
            // Don't exceed daily limit
            let adjustedDuration = min(duration, maxDailyStudyMinutes - totalStudyMinutesToday)
            guard adjustedDuration >= 15 else { continue } // Skip if less than minimum productive session
            
            let strategy = getStudyStrategy(for: work, daysUntilDue: daysUntilDue, mood: todayMood)
            
            blocks.append(StudyBlock(
                id: UUID(),
                title: work.title,
                subject: work.className ?? "General",
                startTime: actualStartTime,
                duration: adjustedDuration,
                dueDate: work.start,
                daysUntilDue: daysUntilDue,
                priority: getPriority(daysUntilDue: daysUntilDue),
                strategy: strategy,
                type: work.category,
                classColorHex: classColorHex(for: work.className)
            ))
            
            totalStudyMinutesToday += adjustedDuration
            
            // Calculate actual end time of this block
            let blockEndTime = calendar.date(byAdding: .minute, value: adjustedDuration, to: actualStartTime) ?? actualStartTime
            
            // NEWPORT PRINCIPLE: Add mandatory breaks between deep work sessions
            if adjustedDuration >= 40 {
                // Add 15-minute break after long sessions
                currentTime = calendar.date(byAdding: .minute, value: 15, to: blockEndTime)
            } else {
                // Next block starts immediately after this one
                currentTime = blockEndTime
            }
            
            // Move to next slot if current time has passed beyond current slot
            while slotIndex < availableSlots.count - 1 && 
                  (currentTime ?? actualStartTime) >= availableSlots[slotIndex + 1].start {
                slotIndex += 1
            }
            
            // If we've used up the current slot, move to next
            if let ct = currentTime, ct > availableSlots[slotIndex].start {
                slotIndex += 1
                currentTime = nil // Reset to use next slot's time
            }
        }
        
        // EBBINGHAUS PRINCIPLE: Add spaced review sessions for recent classes (if enabled)
        if showReviewBlocks {
            let reviewBlocks = generateSpacedReviewSessions(
                scheduledEvents: scheduledEvents,
                date: date,
                calendar: calendar,
                availableSlots: availableSlots,
                usedSlotIndices: Set(0..<slotIndex)
            )
            blocks.append(contentsOf: reviewBlocks)
        }
        
        // Add scheduled events (classes and extracurriculars) as reference blocks
        for event in scheduledEvents {
            blocks.append(StudyBlock(
                id: UUID(),
                title: event.title,
                subject: event.category == "Classes" ? "Class" : "Activity",
                startTime: event.start,
                duration: 60,
                dueDate: nil,
                daysUntilDue: nil,
                priority: .medium,
                strategy: "",
                type: event.category,
                classColorHex: classColorHex(for: event.category == "Classes" ? event.title : event.className),
                isCompact: true
            ))
        }
        
        // Add custom study blocks created by user (filter out conflicts with scheduled events)
        let customBlocks = customStudyBlocksQuery.filter { customBlock in
            guard calendar.isDate(customBlock.startTime, inSameDayAs: date) &&
                  customBlock.userId == dataStore.userId else {
                return false
            }
            
            // Check for overlap with scheduled classes/extracurriculars
            let blockEndTime = calendar.date(byAdding: .minute, value: customBlock.duration, to: customBlock.startTime) ?? customBlock.startTime
            
            for event in scheduledEvents {
                let eventEndTime = calendar.date(byAdding: .hour, value: 1, to: event.start) ?? event.start
                
                // Check if times overlap
                let overlaps = (customBlock.startTime < eventEndTime && blockEndTime > event.start)
                if overlaps {
                    return false // Filter out this custom block
                }
            }
            
            return true
        }
        
        for customBlock in customBlocks {
            blocks.append(StudyBlock(
                id: customBlock.id,
                title: customBlock.title,
                subject: customBlock.className ?? "Custom Study",
                startTime: customBlock.startTime,
                duration: customBlock.duration,
                dueDate: nil,
                daysUntilDue: nil,
                priority: .medium,
                strategy: "Your custom study time",
                type: "Custom",
                classColorHex: customBlock.className != nil ? classColorHex(for: customBlock.className) : "#00A8E8",
                isCompact: false
            ))
        }
        
        // Add all classes from My Classes (even without scheduled times or assignments)
        // This shows students all their classes as reference points in the schedule
        print("📚 Study Schedule - Total classes in My Classes: \(studentClasses.count)")
        print("📚 Study Schedule - Class names: \(studentClasses.map { $0.name })")
        
        let scheduledClassNames = Set(scheduledEvents.filter { $0.category == "Classes" }.map { $0.title })
        print("📚 Study Schedule - Scheduled class names: \(scheduledClassNames)")
        
        let unscheduledClasses = studentClasses.filter { !scheduledClassNames.contains($0.name) }
        print("📚 Study Schedule - Unscheduled classes: \(unscheduledClasses.map { $0.name })")
        
        // Add unscheduled classes as reference blocks
        // Use first available slot if exists, otherwise use earliest study hour
        if !unscheduledClasses.isEmpty {
            let baseTime: Date
            if let firstSlot = availableSlots.first {
                baseTime = firstSlot.start
            } else {
                // No available slots - use earliest study hour as fallback
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = earliestStudyHour
                components.minute = 0
                baseTime = calendar.date(from: components) ?? date
            }
            
            var classTime = baseTime
            for studentClass in unscheduledClasses {
                blocks.append(StudyBlock(
                    id: UUID(),
                    title: studentClass.name,
                    subject: "Class",
                    startTime: classTime,
                    duration: 60,
                    dueDate: nil,
                    daysUntilDue: nil,
                    priority: .medium,
                    strategy: "",
                    type: "Classes",
                    classColorHex: studentClass.color,
                    isCompact: true
                ))
                // Space classes 1 hour apart
                classTime = calendar.date(byAdding: .hour, value: 1, to: classTime) ?? classTime
            }
        }
        
        // Sort all blocks by start time to show chronological schedule
        let sortedBlocks = blocks.sorted { $0.startTime < $1.startTime }
        print("📚 Study Schedule - Total blocks generated: \(sortedBlocks.count)")
        print("📚 Study Schedule - Block types: \(sortedBlocks.map { "\($0.title) (\($0.type))" })")
        return sortedBlocks
    }
    
    private func calculateAvailableTimeSlots(on date: Date, avoiding events: [CalendarEvent], cognitiveCapacity: Double = 1.0) -> [TimeSlot] {
        let calendar = Calendar.current
        var slots: [TimeSlot] = []
        
        // Generate study periods based on user preferences
        // Optimize study times based on cognitive science (Dunlosky principles)
        // 1. Spaced practice throughout the day
        // 2. Avoid studying immediately after meals (post-lunch dip)
        // 3. Include breaks between sessions
        // 4. Consider commute/transition time
        
        // Create study periods within user's preferred time range
        var studyPeriods: [(hour: Int, label: String)] = []
        
        // Map hours to labels
        let hourLabels: [Int: String] = [
            5: "Early Morning", 6: "Early Morning", 7: "Early Morning",
            8: "Mid-Morning", 9: "Mid-Morning", 10: "Mid-Morning",
            11: "Late Morning", 12: "Late Morning",
            13: "Early Afternoon", 14: "Early Afternoon",
            15: "Afternoon", 16: "Late Afternoon",
            17: "Late Afternoon", 18: "Early Evening",
            19: "Evening", 20: "Evening", 21: "Evening",
            22: "Late Evening", 23: "Late Evening"
        ]
        
        // Generate periods every 2 hours within user's range
        var currentHour = earliestStudyHour
        while currentHour <= latestStudyHour {
            let label = hourLabels[currentHour] ?? "Study Time"
            studyPeriods.append((hour: currentHour, label: label))
            currentHour += 2
        }
        
        for period in studyPeriods {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = period.hour
            components.minute = 0
            
            if let slotStart = calendar.date(from: components) {
                // Debug: Verify slot times are correct
                let debugFormatter = DateFormatter()
                debugFormatter.dateFormat = "MMM d, h:mm a"
                print("🕐 Creating time slot: \(debugFormatter.string(from: slotStart))")
                
                // Check if this time conflicts with scheduled events
                // Include buffer for transitions/commutes (30 min before, 15 min after)
                let hasConflict = events.contains { event in
                    let eventStart = event.start
                    let eventEnd = calendar.date(byAdding: .hour, value: 1, to: eventStart) ?? eventStart
                    let bufferStart = calendar.date(byAdding: .minute, value: -30, to: eventStart) ?? eventStart
                    let bufferEnd = calendar.date(byAdding: .minute, value: 15, to: eventEnd) ?? eventEnd
                    
                    return slotStart >= bufferStart && slotStart < bufferEnd
                }
                
                if !hasConflict {
                    slots.append(TimeSlot(start: slotStart, label: period.label))
                }
            }
        }
        
        return slots
    }
    
    private func calculateStudyDuration(for event: CalendarEvent, daysUntilDue: Int) -> Int {
        // Optimize duration based on Dunlosky's research:
        // - Distributed practice (shorter, frequent sessions)
        // - 25-50 min optimal for focus before break needed
        // - Avoid marathon sessions (diminishing returns)
        
        let baseDuration: Int
        
        switch event.category {
        case "Tests", "Exams":
            // Active recall and practice testing work best in 40-50 min blocks
            baseDuration = daysUntilDue <= 2 ? 50 : 40
        case "Assignments":
            // Focused work sessions: 30-40 min
            baseDuration = 35
        default:
            baseDuration = 30
        }
        
        // Adjust based on urgency and spacing principles
        if daysUntilDue <= 1 {
            // Urgent but avoid burnout - cap at 50 min with breaks between
            return min(baseDuration + 10, 50)
        } else if daysUntilDue <= 3 {
            // Optimal spacing - standard duration
            return baseDuration
        } else {
            // Early prep - shorter sessions for initial encoding
            return max(baseDuration - 10, 25)
        }
    }
    
    private func getPriority(daysUntilDue: Int) -> StudyPriority {
        if daysUntilDue <= 1 {
            return .urgent
        } else if daysUntilDue <= 3 {
            return .high
        } else if daysUntilDue <= 7 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func getStudyStrategy(for event: CalendarEvent, daysUntilDue: Int, mood: Int? = nil) -> String {
        // Format the due date
        let dueDateFormatter = DateFormatter()
        dueDateFormatter.dateFormat = "MMM d 'at' h:mm a"
        let dueDateString = dueDateFormatter.string(from: event.start)
        
        let dueText: String
        if daysUntilDue == 0 {
            dueText = "today at \(dueDateFormatter.string(from: event.start).components(separatedBy: " at ").last ?? "")"
        } else if daysUntilDue == 1 {
            dueText = "tomorrow at \(dueDateFormatter.string(from: event.start).components(separatedBy: " at ").last ?? "")"
        } else {
            dueText = "on \(dueDateString)"
        }
        
        // MOOD-BASED STUDY STRATEGIES (dynamic framework based on user's reminder preference)
        // Calculate which day in the prep cycle we're on (1 to reminderDaysAhead)
        let rawDayInCycle = max(1, min(reminderDaysAhead, reminderDaysAhead + 1 - daysUntilDue))
        
        // Map to 7-day framework (strategy functions only handle days 1-7)
        let dayInCycle = min(7, Int(ceil(Double(rawDayInCycle) / Double(reminderDaysAhead) * 7.0)))
        
        // Get mood-specific strategy
        let moodStrategy = getMoodBasedStrategy(mood: mood, dayInCycle: dayInCycle)
        
        // Combine with task-specific guidance
        let taskGuidance: String
        let isTest = event.category.lowercased() == "tests" || event.category.lowercased() == "test" || event.category.lowercased() == "exams" || event.category.lowercased() == "exam"
        
        if daysUntilDue == 0 {
            if isTest {
                taskGuidance = "Final prep for '\(event.title)' due \(dueText)."
            } else {
                taskGuidance = "Complete '\(event.title)' due \(dueText)."
            }
        } else if daysUntilDue <= 2 {
            if isTest {
                taskGuidance = "Study for '\(event.title)' due \(dueText)."
            } else {
                taskGuidance = "Work on '\(event.title)' due \(dueText)."
            }
        } else if daysUntilDue <= 4 {
            taskGuidance = "Work on '\(event.title)' due \(dueText)."
        } else {
            if isTest {
                taskGuidance = "Begin prep for '\(event.title)' due \(dueText)."
            } else {
                taskGuidance = "Start '\(event.title)' due \(dueText)."
            }
        }
        
        return "\(taskGuidance) \(moodStrategy)"
    }
    
    // MARK: - Mood-Based Study Strategy (7-Day Framework)
    private func getMoodBasedStrategy(mood: Int?, dayInCycle: Int) -> String {
        // If mood-based schedule is disabled, use MixFix Study Flow
        if !moodBasedScheduleEnabled {
            return getMixFixStudyFlowStrategy(dayInCycle: dayInCycle)
        }
        
        guard let mood = mood else {
            // Default to "Good" mood strategies if no mood logged
            return getGoodMoodStrategy(dayInCycle: dayInCycle)
        }
        
        switch mood {
        case 9: return getAmazingMoodStrategy(dayInCycle: dayInCycle)
        case 8: return getGoodMoodStrategy(dayInCycle: dayInCycle)
        case 7: return getOkayMoodStrategy(dayInCycle: dayInCycle)
        case 6: return getAnnoyedMoodStrategy(dayInCycle: dayInCycle)
        case 5: return getOverwhelmedMoodStrategy(dayInCycle: dayInCycle)
        case 4: return getDrainedMoodStrategy(dayInCycle: dayInCycle)
        case 3: return getOverwhelmedMoodStrategy(dayInCycle: dayInCycle)
        case 2: return getSadMoodStrategy(dayInCycle: dayInCycle)
        case 1: return getAngryMoodStrategy(dayInCycle: dayInCycle)
        default: return getGoodMoodStrategy(dayInCycle: dayInCycle)
        }
    }
    
    private func getMixFixStudyFlowStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "📘 Learn It: Go through everything once. Make simple notes or flashcards. Quiz yourself lightly to start memory building."
        case 2: return "⏱ Review It: Use 25 min on / 5 min off cycles. Test yourself instead of rereading. Write down anything you still forget."
        case 3: return "⚡ Practice It: Do practice problems, essays, or examples. Push your focus, but stop before burnout."
        case 4: return "🧭 Deep Focus: Turn off distractions. Work only on your hardest topic. Then take a real break — walk, stretch, breathe."
        case 5: return "🌿 Mix It Up: Morning: 30 min light review. Afternoon: rest or do something creative. Evening: 60 min test or quiz practice."
        case 6: return "🔁 Refresh: Review your weak spots. One more round of recall and testing."
        case 7: return "😌 Rest + Recall: Skim key notes or flashcards once. Stop early — sleep does the rest."
        default: return "Follow the MixFix Study Flow for optimal learning."
        }
    }
    
    private func getAmazingMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Deep Dive: Learn new material, outline everything, and make flashcards."
        case 2: return "Apply It: Practice questions or mock problems. End with quick reflection."
        case 3: return "Refine: Focus on what felt tricky yesterday. Use a timer (3 × 25 min Pomodoros)."
        case 4: return "Deep Work: No distractions. Do a timed practice test. Celebrate with a long walk or treat."
        case 5: return "Flow Review: Mix new + old topics for variety. Teach it out loud."
        case 6: return "Mastery Check: Full review test. Track accuracy & write final notes."
        case 7: return "Recharge: Light recap, clean workspace, sleep early."
        default: return "Review and practice with full focus."
        }
    }
    
    private func getGoodMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Review class notes, highlight key ideas."
        case 2: return "Flashcards or mini quizzes."
        case 3: return "Practice problems."
        case 4: return "Deep focus block: hardest topic."
        case 5: return "Review mistakes + explain concepts out loud."
        case 6: return "Light review with Pomodoro cycles."
        case 7: return "Quick recap + rest."
        default: return "Steady, consistent practice."
        }
    }
    
    private func getOkayMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Reorganize notes & do light review."
        case 2: return "One Pomodoro of recall practice."
        case 3: return "Small quiz or review questions."
        case 4: return "Practice the hardest topic briefly."
        case 5: return "Mix light review with one test question."
        case 6: return "Read summaries aloud; keep moving."
        case 7: return "Relaxed recap."
        default: return "Gentle, consistent progress."
        }
    }
    
    private func getOverwhelmedMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Choose one subject; skim overview."
        case 2: return "2 small Pomodoros on that topic."
        case 3: return "Do easy practice questions."
        case 4: return "Add one more topic."
        case 5: return "Practice recall on both topics."
        case 6: return "Write summary notes."
        case 7: return "Light flashcard review, early rest."
        default: return "Take it slow, one step at a time."
        }
    }
    
    private func getAnnoyedMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Physical reset + easy wins (clean notes)."
        case 2: return "Medium difficulty tasks."
        case 3: return "One tough challenge — burn the frustration productively."
        case 4: return "Mix light + hard tasks (Pomodoro style)."
        case 5: return "Work through mistakes calmly."
        case 6: return "Fun recap: music + flashcards."
        case 7: return "Chill quiz, reward yourself."
        default: return "Channel energy into focused work."
        }
    }
    
    private func getSadMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Watch a video lesson."
        case 2: return "Gentle note rewrite with calming music."
        case 3: return "Do a short quiz."
        case 4: return "Review flashcards in bed or outside."
        case 5: return "Revisit what you actually enjoy learning."
        case 6: return "Light recap; journal one thing you learned."
        case 7: return "Rest, reflect, be proud you stayed consistent."
        default: return "Be kind to yourself, gentle progress."
        }
    }
    
    private func getDrainedMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Read summaries only."
        case 2: return "Flashcards or audio review."
        case 3: return "One small topic focus."
        case 4: return "Rest more, short recap."
        case 5: return "Quick test + early stop."
        case 6: return "Light review before bed."
        case 7: return "Full reset."
        default: return "Minimum effort, maximum recovery."
        }
    }
    
    private func getAngryMoodStrategy(dayInCycle: Int) -> String {
        switch dayInCycle {
        case 1: return "Do a workout, then study one tough topic."
        case 2: return "Timed practice test; let adrenaline help."
        case 3: return "Fix your mistakes — controlled, calm focus."
        case 4: return "Alternate hard questions and breaks."
        case 5: return "Work through summaries with music."
        case 6: return "Short review, then move again."
        case 7: return "Chill recap; decompress fully."
        default: return "Channel intensity into structured work."
        }
    }
    
    // MARK: - Mood-Based Cognitive Capacity (Csikszentmihalyi Flow Principles)
    private func calculateCognitiveCapacity(mood: Int?) -> Double {
        guard let mood = mood else { return 0.7 } // Default moderate capacity if no mood logged
        
        switch mood {
        case 9: return 1.0  // Amazing - peak performance, optimal flow state
        case 8: return 0.95 // Good - high capacity, ready for deep work
        case 7: return 0.75 // Okay - moderate capacity, can handle standard sessions
        case 6: return 0.6  // Annoyed - reduced capacity, shorter sessions needed
        case 5: return 0.55 // Anxious - lower capacity, need structured breaks
        case 4: return 0.5  // Drained - low energy, minimal deep work
        case 3: return 0.45 // Overwhelmed - very low capacity, light tasks only
        case 2: return 0.4  // Sad - minimal capacity, gentle approach
        case 1: return 0.35 // Angry - lowest capacity, avoid demanding work
        default: return 0.7
        }
    }
    
    // MARK: - Maximum Daily Study Time (Newport's Deep Work Limits)
    private func calculateMaxStudyTime(mood: Int?, cognitiveCapacity: Double) -> Int {
        // Cal Newport: 4 hours of deep work is the maximum for most people
        // Adjust based on mood and cognitive capacity
        let baseMaxMinutes = 240 // 4 hours maximum
        
        // Mood-based adjustments
        let adjustedMax = Int(Double(baseMaxMinutes) * cognitiveCapacity)
        
        // Never go below 60 minutes (one productive session) or above 240 minutes
        return max(60, min(adjustedMax, 240))
    }
    
    // MARK: - Get Most Recent Mood
    @AppStorage("moodBasedScheduleEnabled") private var moodBasedScheduleEnabled: Bool = true
    
    private func getRecentMood(for date: Date) -> Int? {
        // If mood-based schedule is disabled, return "Good" mood (8) for optimized schedule
        if !moodBasedScheduleEnabled {
            return 8
        }
        // Get the most recently logged mood (no time restriction for study schedule)
        return dataStore.moods.first?.mood
    }
    
    // MARK: - Optimal Session Duration (Mood-Based Dynamic Framework)
    private func calculateOptimalSessionDuration(for event: CalendarEvent, daysUntilDue: Int, cognitiveCapacity: Double, timeOfDay: Date) -> Int {
        // Calculate which day in the prep cycle we're on (1 to reminderDaysAhead)
        let rawDayInCycle = max(1, min(reminderDaysAhead, reminderDaysAhead + 1 - daysUntilDue))
        
        // Map to 7-day framework (arrays only have 7 values)
        // For longer prep periods, map proportionally to the 7-day cycle
        let dayInCycle = min(7, Int(ceil(Double(rawDayInCycle) / Double(reminderDaysAhead) * 7.0)))
        let safeIndex = min(dayInCycle - 1, 6) // Ensure index is 0-6
        
        // If mood-based schedule is disabled, use the MixFix Study Flow default
        if !moodBasedScheduleEnabled {
            // MixFix Study Flow (optimized 7-day framework)
            // Day 1: Learn It (90-120 min) - average 105
            // Day 2: Review It (60 min)
            // Day 3: Practice It (75-90 min) - average 82
            // Day 4: Deep Focus (60 min)
            // Day 5: Mix It Up (90 min total)
            // Day 6: Refresh (45-60 min) - average 52
            // Day 7: Rest + Recall (20-30 min) - average 25
            let defaultDurations = [105, 60, 82, 60, 90, 52, 25]
            return defaultDurations[safeIndex]
        }
        
        // Get user's current mood from the data store
        let todayMood = getRecentMood(for: Date())
        
        // MOOD-BASED DURATIONS (from 7-day framework)
        var baseDuration: Int
        
        switch todayMood {
        case 9: // Amazing
            baseDuration = [90, 90, 75, 100, 80, 90, 45][safeIndex]
        case 8: // Good
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        case 7: // Okay
            baseDuration = [45, 45, 60, 45, 50, 40, 25][safeIndex]
        case 6: // Annoyed
            baseDuration = [50, 60, 45, 50, 60, 45, 30][safeIndex]
        case 5: // Overwhelmed
            baseDuration = [30, 40, 35, 40, 45, 30, 20][safeIndex]
        case 4: // Drained
            baseDuration = [20, 25, 30, 20, 25, 20, 15][safeIndex]
        case 3: // Overwhelmed (same as 5)
            baseDuration = [30, 40, 35, 40, 45, 30, 20][safeIndex]
        case 2: // Sad
            baseDuration = [25, 30, 35, 25, 30, 25, 20][safeIndex]
        case 1: // Angry
            baseDuration = [50, 60, 45, 55, 50, 45, 30][safeIndex]
        default: // No mood logged - use Good mood defaults
            baseDuration = [60, 70, 60, 60, 70, 60, 30][safeIndex]
        }
        
        // Return exact mood-based duration (no time-of-day adjustments)
        return baseDuration
    }
    
    // MARK: - Spaced Repetition Prioritization (Ebbinghaus Forgetting Curve)
    private func prioritizeBySpacedRepetition(_ events: [CalendarEvent], selectedDate: Date, calendar: Calendar) -> [CalendarEvent] {
        // Ebbinghaus: Memory retention follows exponential decay
        // Optimal review intervals: 1 day, 3 days, 7 days, 14 days, 30 days
        
        return events.sorted { event1, event2 in
            let days1 = calendar.dateComponents([.day], from: calendar.startOfDay(for: selectedDate), to: calendar.startOfDay(for: event1.start)).day ?? 0
            let days2 = calendar.dateComponents([.day], from: calendar.startOfDay(for: selectedDate), to: calendar.startOfDay(for: event2.start)).day ?? 0
            
            // Priority scoring based on Ebbinghaus intervals
            let score1 = calculateSpacedRepetitionScore(daysUntilDue: days1, category: event1.category)
            let score2 = calculateSpacedRepetitionScore(daysUntilDue: days2, category: event2.category)
            
            return score1 > score2
        }
    }
    
    private func calculateSpacedRepetitionScore(daysUntilDue: Int, category: String) -> Int {
        // Higher score = higher priority
        var score = 0
        
        // Urgency component
        if daysUntilDue <= 0 {
            score += 1000 // Critical: due today or overdue
        } else if daysUntilDue == 1 {
            score += 500 // Very urgent: due tomorrow
        } else if daysUntilDue <= 3 {
            score += 200 // Urgent: optimal spacing window
        } else if daysUntilDue <= 7 {
            score += 100 // Important: one week window
        } else if daysUntilDue <= 14 {
            score += 50 // Moderate: two week window
        } else {
            score += 20 // Low: early preparation
        }
        
        // Task type component (tests need more spaced review)
        if category == "Tests" || category == "Exams" {
            score += 30
        } else if category == "Assignments" {
            score += 20
        }
        
        return score
    }
    
    // MARK: - Spaced Review Sessions (Ebbinghaus Application)
    private func generateSpacedReviewSessions(scheduledEvents: [CalendarEvent], date: Date, calendar: Calendar, availableSlots: [TimeSlot], usedSlotIndices: Set<Int>) -> [StudyBlock] {
        var reviewBlocks: [StudyBlock] = []
        var reservedIndices = usedSlotIndices
        
        // For each class today, schedule immediate review (within 24 hours = 80% retention)
        let todayClasses = scheduledEvents.filter { $0.category == "Classes" }
        
        for classEvent in todayClasses {
            // Class is modeled as 1 hour; end time is start + 1h
            let classEndTime = calendar.date(byAdding: .hour, value: 1, to: classEvent.start) ?? classEvent.start

            // Try to schedule review within 30 minutes to 4 hours after class ends
            let minReviewTime = calendar.date(byAdding: .minute, value: 30, to: classEndTime) ?? classEndTime
            let maxReviewTime = calendar.date(byAdding: .hour, value: 4, to: classEndTime) ?? classEndTime

            var reviewSlot = availableSlots.enumerated().first(where: { index, slot in
                !reservedIndices.contains(index) &&
                slot.start >= minReviewTime &&
                slot.start <= maxReviewTime
            })
            
            // Fallback: If no slot in preferred window, find any available slot after class
            if reviewSlot == nil {
                reviewSlot = availableSlots.enumerated().first(where: { index, slot in
                    !reservedIndices.contains(index) &&
                    slot.start >= classEndTime
                })
            }
            
            if let reviewSlot = reviewSlot {
                reviewBlocks.append(StudyBlock(
                    id: UUID(),
                    title: "Review \(classEvent.title)",
                    subject: classEvent.title,
                    startTime: reviewSlot.element.start,
                    duration: 20, // 20 min review session
                    dueDate: nil,
                    daysUntilDue: nil,
                    priority: .high, // High priority: immediate review prevents 50% forgetting
                    strategy: "🧠 Ebbinghaus Review: Consolidate today's \(classEvent.title) material while it's fresh. Summarize key points, test yourself on main concepts. This prevents 50% memory loss within 24 hours.",
                    type: "Review",
                    classColorHex: classColorHex(for: classEvent.title)
                ))
                reservedIndices.insert(reviewSlot.offset)
            }
        }
        
        return reviewBlocks
    }
    
    private func getDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }
        
        // Add all days in the month
        let range = calendar.range(of: .day, in: .month, for: date)!
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(dayDate)
            }
        }
        
        return days
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Timeline Block View
struct TimelineBlockView: View {
    let block: StudyBlock
    let isFirst: Bool
    
    private var isCurrentBlock: Bool {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        return now >= block.startTime && now < endTime
    }
    
    private var isPastBlock: Bool {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        return now >= endTime
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline column
            VStack(spacing: 0) {
                // Top connector line (hidden for first block)
                if !isFirst {
                    Rectangle()
                        .fill(isPastBlock ? Color.gray.opacity(0.3) : blockColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 20)
                }
                
                // Time label
                Text(timeString)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(isCurrentBlock ? Color.green : (isPastBlock ? .secondary : blockColor))
                    .frame(width: 50)
                    .padding(.vertical, 2)
                
                // Timeline dot
                ZStack {
                    Circle()
                        .fill(isCurrentBlock ? Color.green : (isPastBlock ? Color.gray.opacity(0.3) : blockColor))
                        .frame(width: 10, height: 10)
                    
                    if isCurrentBlock {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 4)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.vertical, 4)
                
                // Bottom connector line
                Rectangle()
                    .fill(isPastBlock ? Color.gray.opacity(0.3) : blockColor.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 60)
            
            // Content card
            VStack(alignment: .leading, spacing: 12) {
                // Header: Icon + Time + Badge
                HStack(spacing: 10) {
                    // Cute icon bubble
                    ZStack {
                        Circle()
                            .fill(blockColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: blockIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(blockColor)
                    }
                    
                    Text(timeString)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isCurrentBlock ? Color.green : blockColor)
                    
                    Spacer()
                    
                    // Cute badge
                    if isCurrentBlock {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Live")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else if !block.isCompact {
                        Text(badgeText)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .tracking(0.3)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(
                                ZStack {
                                    // Strong gradient background
                                    LinearGradient(
                                        colors: [
                                            blockColor.opacity(0.5),
                                            blockColor.opacity(0.8),
                                            blockColor,
                                            blockColor.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    // Visible border
                                    Capsule()
                                        .strokeBorder(blockColor.opacity(0.6), lineWidth: 0.5)
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(color: blockColor.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                
                // Title with emoji-style presentation
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(blockColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cleanTitle(block.title))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(isPastBlock ? .secondary : .primary)
                            .lineLimit(2)
                        
                        // Subject (if different from title)
                        if !block.subject.isEmpty && block.subject != block.title {
                            Text(block.subject)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Bottom info row with cute icons
                HStack(spacing: 16) {
                    // Duration bubble
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(blockColor.opacity(0.15))
                                .frame(width: 24, height: 24)
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(blockColor)
                        }
                        Text("\(block.duration) min")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    
                    if let daysUntilDue = block.daysUntilDue {
                        // Due date bubble
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill((daysUntilDue <= 1 ? Color.red : Color.orange).opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Image(systemName: daysUntilDue <= 1 ? "exclamationmark.circle.fill" : "calendar")
                                    .font(.system(size: 11))
                                    .foregroundStyle(daysUntilDue <= 1 ? .red : .orange)
                            }
                            Text(dueText(days: daysUntilDue))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(daysUntilDue <= 1 ? .red : .primary)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: blockColor.opacity(0.1), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: isCurrentBlock ? [Color.green, Color.green.opacity(0.5)] : [blockColor.opacity(0.3), blockColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isCurrentBlock ? 2.5 : 1.5
                    )
            )
            .opacity(isPastBlock ? 0.6 : 1.0)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: block.startTime)
    }
    
    private var blockColor: Color {
        // Use class color if available for classes and reviews
        if let hex = block.classColorHex, (block.type == "Classes" || block.type == "Review") {
            return Color(hex: hex)
        }
        
        if block.isCompact {
            return block.type == "Classes" ? .purple : .green
        }
        
        switch block.type {
        case "Review": return .blue
        case "Study": return .orange
        default: return .purple
        }
    }
    
    private var blockIcon: String {
        switch block.type {
        case "Classes": return "book.fill"
        case "Extra Curriculars": return "figure.run"
        case "Review": return "arrow.clockwise"
        case "Study": return "brain.head.profile"
        default: return "pencil"
        }
    }
    
    private var badgeText: String {
        if block.isCompact {
            return block.type == "Classes" ? "CLASS" : "ACTIVITY"
        }
        
        guard let days = block.daysUntilDue else { return block.type.uppercased() }
        
        if days == 0 { return "DUE TODAY" }
        if days == 1 { return "DUE TOMORROW" }
        return block.type.uppercased()
    }
    
    private func cleanTitle(_ title: String) -> String {
        title.replacingOccurrences(of: " - Review", with: "")
            .replacingOccurrences(of: " Review", with: "")
    }
    
    private func dueText(days: Int) -> String {
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \\(days) days"
    }
}

// MARK: - Study Block Card
struct StudyBlockCard: View {
    let block: StudyBlock
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    
    private var isCurrentBlock: Bool {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        return now >= block.startTime && now < endTime
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: block.startTime)
    }
    
    var body: some View {
        if block.isCompact {
            // Compact view for classes/activities
            compactView
        } else {
            if isExpanded {
                fullView
            } else {
                collapsedView
            }
        }
    }
    
    private var compactView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time on the left with refined styling
            Text(timeString)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            
            // Timeline dot and line with glow
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrentBlock ? Color.green : blockColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: isCurrentBlock ? Color.green.opacity(0.5) : blockColor.opacity(0.4), radius: 4, x: 0, y: 0)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [blockColor.opacity(0.4), blockColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 35)
            }
            
            // Content block with premium styling
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(cleanTitle(block.title))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                // Category identifier on the right
                VStack(spacing: 4) {
                    Image(systemName: blockIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(blockColor)
                    Text(categoryDescription)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // Subtle gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    blockColor.opacity(0.08),
                                    blockColor.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                        .blur(radius: 0.5)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                blockColor.opacity(0.3),
                                blockColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: blockColor.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
    
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time range header with colored accent
            HStack(spacing: 10) {
                // Current time indicator
                if isCurrentBlock {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                // Icon for block type
                Image(systemName: blockIcon)
                    .font(.body)
                    .foregroundStyle(isCurrentBlock ? Color.green : blockColor)
                
                // Time block
                VStack(alignment: .leading, spacing: 1) {
                    Text(timeRangeString)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if let daysUntilDue = block.daysUntilDue {
                        Text(dueText(days: daysUntilDue))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Badge - show NOW for current block, otherwise show type/priority
                if isCurrentBlock {
                    Text("NOW")
                        .font(.caption2)
                        .fontWeight(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                } else {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(blockColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isCurrentBlock ? Color.green.opacity(0.1) : blockColor.opacity(0.08))
            
            // Content section
            VStack(alignment: .leading, spacing: 8) {
                // Assignment title and subject
                Text(cleanTitle(block.title))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                
                Text(cleanSubject(block.subject))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Study strategy - only show if not empty
                if !block.strategy.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                        
                        Text(block.strategy)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Button(action: onToggleExpanded) {
                HStack(spacing: 4) {
                    Text("Show less")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.up")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isCurrentBlock ? 
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [blockColor, blockColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: isCurrentBlock ? 2.5 : 2
                )
        )
        .shadow(color: blockColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 8)
    }
    
    private var collapsedView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Time on the left with refined styling
            Text(timeString)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            
            // Timeline dot and line with glow effect
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrentBlock ? Color.green : blockColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: isCurrentBlock ? Color.green.opacity(0.5) : blockColor.opacity(0.4), radius: 4, x: 0, y: 0)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [blockColor.opacity(0.4), blockColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 35)
            }
            
            // Content block with premium styling
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cleanTitle(block.title))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    // Due date information
                    if let daysUntilDue = block.daysUntilDue {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(dueText(days: daysUntilDue))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(action: onToggleExpanded) {
                        HStack(spacing: 4) {
                            Text("Show details")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(blockColor)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(blockColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(blockColor.opacity(0.12))
                        )
                    }
                }
                
                Spacer()
                
                // Category identifier on the right
                VStack(spacing: 4) {
                    Image(systemName: blockIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(blockColor)
                    Text(categoryDescription)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // Subtle gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    blockColor.opacity(0.08),
                                    blockColor.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.5))
                        .blur(radius: 0.5)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                blockColor.opacity(0.3),
                                blockColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: blockColor.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
    
    private var isScheduledEvent: Bool {
        block.type == "Classes" || block.type == "Extra Curriculars"
    }
    
    private var blockIcon: String {
        switch block.type {
        case "Classes":
            return "book.fill"
        case "Extra Curriculars":
            return "figure.run"
        case "Tests", "Exams":
            return "doc.text.fill"
        case "Assignments":
            return "pencil"
        case "Review":
            return "arrow.clockwise"
        default:
            return "pencil"
        }
    }
    
    private var blockColor: Color {
        // Use class color if available for classes and reviews
        if let hex = block.classColorHex, (block.type == "Classes" || block.type == "Review") {
            return Color(hex: hex)
        }
        
        if isScheduledEvent {
            if block.type == "Classes" {
                return .blue  // Fallback if no class color
            } else {
                // Extra Curriculars
                return .purple
            }
        } else {
            // Use calmer colors based on type, not urgency
            switch block.type {
            case "Tests", "Exams":
                return .orange  // Orange for tests instead of red
            case "Assignments":
                return .blue    // Blue for assignments
            case "Review":
                return .green   // Green for reviews (fallback if no class color)
            default:
                return .blue
            }
        }
    }
    
    private var badgeText: String {
        if isScheduledEvent {
            return block.type == "Classes" ? "CLASS" : "ACTIVITY"
        } else {
            // Show type instead of priority
            switch block.type {
            case "Tests", "Exams":
                return "TEST"
            case "Assignments":
                return "ASSIGNMENT"
            case "Review":
                return "REVIEW"
            default:
                return "STUDY"
            }
        }
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let endTime = Calendar.current.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        
        let startString = formatter.string(from: block.startTime)
        let endString = formatter.string(from: endTime)
        
        return "\(startString) - \(endString)"
    }
    
    private var nextActivityHint: String? {
        // Suggest what comes after this study session
        let calendar = Calendar.current
        let endTime = calendar.date(byAdding: .minute, value: block.duration, to: block.startTime) ?? block.startTime
        let hour = calendar.component(.hour, from: endTime)
        
        // Provide contextual suggestions based on time
        if hour >= 8 && hour < 12 {
            return "Then: Morning classes or activities"
        } else if hour >= 12 && hour < 13 {
            return "Then: Lunch break"
        } else if hour >= 13 && hour < 17 {
            return "Then: Afternoon classes"
        } else if hour >= 17 && hour < 19 {
            return "Then: Dinner or extracurriculars"
        } else if hour >= 19 && hour < 22 {
            return "Then: Evening activities or relaxation"
        } else {
            return "Then: Rest and recharge"
        }
    }
    
    private var priorityColor: Color {
        switch block.priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    private func dueText(days: Int) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let isTest = block.type == "Tests" || block.type == "Exams"
        
        guard let dueDate = block.dueDate else {
            // Fallback if no due date
            if days == 0 {
                return isTest ? "Today" : "Due today"
            } else if days == 1 {
                return isTest ? "Tomorrow" : "Due tomorrow"
            } else {
                return isTest ? "In \(days) days" : "Due in \(days) days"
            }
        }
        
        let timeString = timeFormatter.string(from: dueDate)
        
        if days == 0 {
            return isTest ? "Today at \(timeString)" : "Due today at \(timeString)"
        } else if days == 1 {
            return isTest ? "Tomorrow at \(timeString)" : "Due tomorrow at \(timeString)"
        } else {
            return isTest ? "In \(days) days at \(timeString)" : "Due in \(days) days at \(timeString)"
        }
    }
    
    private func cleanTitle(_ title: String) -> String {
        // Remove any NSManagedObject references or unwanted text
        var cleaned = title.replacingOccurrences(of: "NSManagedObject", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // For assignments, remove "Study for" prefix if present
        if block.type == "Assignments" && cleaned.lowercased().hasPrefix("study for ") {
            cleaned = String(cleaned.dropFirst(10)) // Remove "Study for " (10 characters)
        }
        
        return cleaned
    }
    
    private func cleanSubject(_ subject: String) -> String {
        // Remove any NSManagedObject references or unwanted text
        return subject.replacingOccurrences(of: "NSManagedObject", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private var categoryDescription: String {
        switch block.type {
        case "Classes":
            return "Class"
        case "Extra Curriculars":
            return "Activity"
        case "Tests", "Exams":
            return "Test"
        case "Assignments":
            return "Assignment"
        case "Review":
            return "Review Session"
        default:
            return "Study Session"
        }
    }
}

// MARK: - Study Session View
struct StudySessionView: View {
    let block: StudyBlock
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var timerManager: PomodoroTimerManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var showExtensionOptions = false
    @State private var showCompletionPrompt = false
    @State private var showActiveSessionClosePrompt = false
    @State private var showUnlockPINPrompt = false
    @State private var enteredTimerPIN: String = ""
    @State private var showTimerPINError: Bool = false
    @AppStorage("moodBasedScheduleEnabled") private var moodBasedScheduleEnabled: Bool = true
    @AppStorage("timerFocusLockEnabled") private var timerFocusLockEnabled: Bool = false
    @AppStorage("timerLockPIN") private var timerLockPIN: String = ""
    
    private var mood: Int? {
        dataStore.moods.first?.mood
    }

    private enum UnlockSource {
        case close            // unlocking to show close options
        case endSession       // unlocking to immediately end session
        case lockIconUnlock   // unlocking via lock button
        case lockIconLock     // locking via lock button (confirm PIN)
    }

    @State private var unlockSource: UnlockSource = .close
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection
                timerSection
                Spacer()
                sessionControls
            }
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        handleCloseTapped()
                    }
                }
            }
            .onAppear {
                // Ensure we have permission to show local notifications so
                // focus/break switches can appear even when the app is not active.
                timerManager.requestNotificationPermission()
                
                // Only configure the timer when starting a brand-new study session.
                // If a session is already in progress or paused, keep its state
                // (seconds remaining, mode, cycles) so the user can resume later.
                if !timerManager.inStudySession {
                    configureTimerForBlock()
                }
                // Always start new study session views in an unlocked state.
                timerManager.isLockedSession = false
            }
            .onChange(of: timerManager.didCompleteFocusInSession) { _, completed in
                if completed {
                    showCompletionPrompt = true
                }
            }
            .confirmationDialog("Session complete!", isPresented: $showCompletionPrompt, actions: {
                Button("End Session", role: .destructive) {
                    endSession()
                }
                Button("Extend Session (\\(timerManager.sessionExtensionMinutes) min)") {
                    extendSession(minutes: timerManager.sessionExtensionMinutes)
                }
                Button("Choose Extension Length") {
                    showExtensionOptions = true
                }
                Button("Cancel", role: .cancel) {
                    timerManager.didCompleteFocusInSession = false
                }
            })
            .confirmationDialog("Choose extension length", isPresented: $showExtensionOptions, actions: {
                ForEach([5, 10, 15, 20, 25], id: \.self) { minutes in
                    Button("\\(minutes) minutes") {
                        timerManager.sessionExtensionMinutes = minutes
                        extendSession(minutes: minutes)
                    }
                }
                Button("Cancel", role: .cancel) {}
            })
            .confirmationDialog(
                "You have an active session",
                isPresented: $showActiveSessionClosePrompt,
                titleVisibility: .visible
            ) {
                Button("Pause and Close") {
                    // Pause without resetting; keep remaining time.
                    timerManager.stopTimer()
                    // Keep inStudySession = true so we know this session exists
                    // when the user reopens the sheet.
                    timerManager.inStudySession = true
                    dismiss()
                }
                Button("End Session", role: .destructive) {
                    endSession()
                }
                Button("Cancel", role: .cancel) { }
            }
            // In-view pop-up for phase changes (Break Time / Focus Time / Session Complete)
            .overlay(
                Group {
                    if timerManager.showAlert {
                        ZStack {
                            Color.black.opacity(0.25)
                                .ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text(timerManager.alertMessage)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(timerManager.timerMode == .focus ? "Focus Timer" : "Break Time")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 20)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                    }
                }
            )
            // Prevent swipe-to-dismiss while a focus-locked session is active
            .interactiveDismissDisabled(timerFocusLockEnabled && timerManager.isLockedSession)
            // PIN prompt for creating/unlocking/closing a focus session (custom sheet so TextField always shows)
            .sheet(isPresented: $showUnlockPINPrompt) {
                VStack(spacing: 20) {
                    Text("Focus Session PIN")
                        .font(.headline)
                    
                    Text(showTimerPINError
                         ? "Incorrect PIN. Try again."
                         : (timerLockPIN.isEmpty && unlockSource == .lockIconLock
                            ? "Create a 4-digit PIN to lock and unlock this session."
                            : "Enter your 4-digit PIN to unlock this session."))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(showTimerPINError ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    TextField("4-digit PIN", text: $enteredTimerPIN)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                    
                    VStack(spacing: 12) {
                        Button(timerLockPIN.isEmpty && unlockSource == .lockIconLock ? "Set PIN" : "Unlock") {
                            validateTimerPIN()
                            if !showTimerPINError {
                                showUnlockPINPrompt = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        // Always show Cancel button
                        Button("Cancel") {
                            enteredTimerPIN = ""
                            showTimerPINError = false
                            showUnlockPINPrompt = false
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .presentationDetents([.height(300)])
                .interactiveDismissDisabled(timerFocusLockEnabled && timerManager.isLockedSession)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(block.type.uppercased())
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(Color.blue)
                    .clipShape(Capsule())
                
                if !block.subject.isEmpty {
                    Text(block.subject)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(block.title)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text("Recommended: \(block.duration) min")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var timerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.5),
                                Color.purple.opacity(0.5),
                                Color.blue.opacity(0.5)
                            ]),
                            center: .center
                        ),
                        lineWidth: 10
                    )
                    .frame(width: 180, height: 180)
                    .opacity(0.3)
                
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 150, height: 150)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                Text(String(format: "%02d:%02d", timerManager.seconds / 60, timerManager.seconds % 60))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            
            // Preset selector
            Menu {
                ForEach(PomodoroPreset.allCases) { preset in
                    Button {
                        timerManager.changePreset(preset)
                    } label: {
                        HStack {
                            Image(systemName: preset.icon)
                            VStack(alignment: .leading) {
                                Text(preset.rawValue)
                                Text(preset.description(customFocus: timerManager.customFocusMinutes, customBreak: timerManager.customBreakMinutes))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: timerManager.currentPreset.icon)
                    Text(timerManager.currentPreset.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray5))
                )
            }

            // Custom preset controls
            if timerManager.currentPreset == .custom {
                VStack(spacing: 8) {
                    // Custom focus length row
                    VStack(spacing: 4) {
                        Text("Custom focus length")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                let newValue = max(5, timerManager.customFocusMinutes - 5)
                                updateCustomFocus(to: newValue)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.blue)
                            }

                            Text("\(timerManager.customFocusMinutes) min")
                                .font(.subheadline.weight(.medium))
                                .frame(minWidth: 60)

                            Button {
                                let newValue = min(180, timerManager.customFocusMinutes + 5)
                                updateCustomFocus(to: newValue)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.blue)
                            }
                        }
                    }

                    // Custom break length row
                    VStack(spacing: 4) {
                        Text("Custom break length")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                let newValue = max(1, timerManager.customBreakMinutes - 1)
                                updateCustomBreak(to: newValue)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.green)
                            }

                            Text("\(timerManager.customBreakMinutes) min")
                                .font(.subheadline.weight(.medium))
                                .frame(minWidth: 60)

                            Button {
                                let newValue = min(60, timerManager.customBreakMinutes + 1)
                                updateCustomBreak(to: newValue)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                }
            }

            // Start / Pause / Reset controls
            HStack(spacing: 16) {
                Button(primaryTimerLabel) {
                    handlePrimaryTimerTap()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    timerManager.resetTimer()
                }
                .buttonStyle(.bordered)
            }
            
            // Mode indicator with lock icon
            HStack(spacing: 8) {
                Text(timerManager.timerMode == .focus ? "Focus Session" : "Break Time")
                    .font(.caption)
                    .foregroundStyle(timerManager.timerMode == .focus ? Color.primary : Color.green)
                
                // Lock toggle - only show if focus lock feature is enabled
                if timerFocusLockEnabled {
                    Button(action: handleLockToggleTapped) {
                        Image(systemName: timerManager.isLockedSession ? "lock.fill" : "lock.open")
                            .font(.title3)
                            .foregroundStyle(timerManager.isLockedSession ? Color.red : Color.blue)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var sessionControls: some View {
        VStack(spacing: 10) {
            Button(primaryTimerLabel) {
                handlePrimaryTimerTap()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
            
            Button("End Session") {
                if timerFocusLockEnabled && timerManager.isLockedSession {
                    unlockSource = .endSession
                    showUnlockPINPrompt = true
                } else {
                    endSession()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.red)
        }
        .padding(.bottom, 24)
    }
    
    private var primaryTimerLabel: String {
        if timerManager.isRunning {
            return "Pause"
        } else if timerManager.inStudySession {
            return "Resume Session"
        } else {
            return "Start Session"
        }
    }
    
    private func handlePrimaryTimerTap() {
        if timerManager.isRunning {
            timerManager.stopTimer()
        } else {
            timerManager.inStudySession = true
            timerManager.startTimer()
        }
    }
    
    private func configureTimerForBlock() {
        // Align timer with mood-based presets and block context without
        // forcing the UI into the "Custom" preset. The visible preset
        // pill should always reflect either the mood-based recommendation
        // or what the user explicitly chose from the menu.

        if moodBasedScheduleEnabled {
            // This updates `currentPreset` (classic/extended/study/etc.) based on mood
            timerManager.updatePresetBasedOnMood(mood)
        }

        // Ensure the timer starts in focus mode with the same duration as
        // the recommended block (which already incorporates mood and
        // schedule logic). The preset pill still reflects the
        // mood-based recommendation, but the countdown itself matches
        // the block's recommended minutes.
        timerManager.timerMode = .focus
        timerManager.seconds = block.duration * 60
        // Marking inStudySession stays false until the user actually taps
        // Start/Resume. This keeps the primary button label correct
        // ("Start Session" on first open) and ensures a fresh session
        // always uses the block's recommended duration.
        timerManager.didCompleteFocusInSession = false
    }

    private func updateCustomFocus(to minutes: Int) {
        timerManager.customFocusMinutes = minutes
        // If we're not currently running and in focus mode, update the visible countdown
        if !timerManager.isRunning && timerManager.timerMode == .focus {
            timerManager.seconds = PomodoroPreset.custom.focusDuration(customFocus: minutes)
        }
    }

    private func updateCustomBreak(to minutes: Int) {
        timerManager.customBreakMinutes = minutes
        // If we're not currently running and in break mode, update the visible countdown
        if !timerManager.isRunning && timerManager.timerMode == .break_ {
            timerManager.seconds = PomodoroPreset.custom.breakDuration(customBreak: minutes)
        }
    }
    
    private func extendSession(minutes: Int) {
        timerManager.didCompleteFocusInSession = false
        timerManager.seconds = minutes * 60
        timerManager.timerMode = .focus
        timerManager.startTimer()
    }
    
    private func endSession() {
        // Record study session completion for streak tracking (only if focus was completed)
        if timerManager.didCompleteFocusInSession {
            recordStudySessionCompletion()
        }
        
        timerManager.stopTimer()
        timerManager.inStudySession = false
        timerManager.didCompleteFocusInSession = false
        timerManager.isLockedSession = false
        timerManager.persistLockedSession() // This will clear persisted state since isLockedSession is now false
        dismiss()
    }
    
    private func recordStudySessionCompletion() {
        // Load existing completions
        var completions: [Date] = []
        if let data = UserDefaults.standard.data(forKey: "studySessionCompletions"),
           let decoded = try? JSONDecoder().decode([Date].self, from: data) {
            completions = decoded
        }
        
        // Add today's completion
        completions.append(Date())
        
        // Clean up old completions (keep last 365 days)
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        completions = completions.filter { $0 > oneYearAgo }
        
        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(completions) {
            UserDefaults.standard.set(encoded, forKey: "studySessionCompletions")
        }
    }
    
    private func validateTimerPIN() {
        // Only accept exact 4-digit numeric codes
        let isNumericFour = enteredTimerPIN.count == 4 && enteredTimerPIN.allSatisfy { $0.isNumber }
        guard isNumericFour else {
            enteredTimerPIN = ""
            showTimerPINError = true
            return
        }

        // If no PIN is set yet and we're locking via the icon, treat this as PIN creation
        if timerLockPIN.isEmpty && unlockSource == .lockIconLock {
            timerLockPIN = enteredTimerPIN
            enteredTimerPIN = ""
            showTimerPINError = false
            timerManager.isLockedSession = true
            return
        }

        // From here on, a stored PIN must exist and match
        guard !timerLockPIN.isEmpty, enteredTimerPIN == timerLockPIN else {
            enteredTimerPIN = ""
            showTimerPINError = true
            return
        }

        // Correct existing PIN
        enteredTimerPIN = ""
        showTimerPINError = false
        switch unlockSource {
        case .close:
            // Unlock and show the standard close options
            timerManager.isLockedSession = false
            showActiveSessionClosePrompt = true
        case .endSession:
            // Unlock and immediately end the session
            timerManager.isLockedSession = false
            endSession()
        case .lockIconUnlock:
            // Unlock via lock button
            timerManager.isLockedSession = false
        case .lockIconLock:
            // Confirm PIN and turn lock ON
            timerManager.isLockedSession = true
        }
    }

    // MARK: - Lock Toggle Handling
    private func handleLockToggleTapped() {
        print("🔒 StudySession: Lock toggle tapped. Current state: isLockedSession=\(timerManager.isLockedSession), focusLockEnabled=\(timerFocusLockEnabled)")
        
        // Reset any previous PIN entry state
        enteredTimerPIN = ""
        showTimerPINError = false

        if timerManager.isLockedSession {
            // Session is currently locked: require PIN to UNLOCK
            unlockSource = .lockIconUnlock
            showUnlockPINPrompt = true
        } else {
            if timerLockPIN.isEmpty {
                // First time: CREATE a new 4-digit PIN, then lock
                unlockSource = .lockIconLock
                showUnlockPINPrompt = true
            } else {
                // PIN already exists: lock immediately with no prompt
                print("🔒 StudySession: Locking session immediately (PIN exists)")
                timerManager.isLockedSession = true
            }
        }
    }

    // MARK: - Close Handling
    private func handleCloseTapped() {
        if timerFocusLockEnabled && timerManager.isLockedSession {
            // Require PIN before allowing the user to close a focus-locked session.
            unlockSource = .close
            showUnlockPINPrompt = true
        } else if timerManager.isRunning {
            // Ask the user whether to pause or end the active session.
            showActiveSessionClosePrompt = true
        } else {
            // Timer is not running (either never started or already paused).
            // Just dismiss the sheet and leave the timer state as-is so
            // it can be resumed later.
            dismiss()
        }
    }
}
// MARK: - Class Check-In View
struct ClassCheckInView: View {
    let block: StudyBlock
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    @State private var selectedClassId: UUID?
    @State private var selectedClassName: String = ""
    @State private var understanding: Double = 60
    @State private var engagement: Double = 60
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Today's Class")) {
                    Picker("Class", selection: $selectedClassId) {
                        ForEach(availableClasses, id: \.id) { cls in
                            Text(cls.name).tag(Optional(cls.id))
                        }
                        Text(selectedClassName).tag(Optional<UUID>(nil))
                    }
                    .onChange(of: selectedClassId) { _, newValue in
                        if let id = newValue, let match = availableClasses.first(where: { $0.id == id }) {
                            selectedClassName = match.name
                        }
                    }
                }

                Section("How did it go?") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Understanding")
                            .font(.subheadline)
                        Slider(value: $understanding, in: 0...100, step: 5) {
                            Text("Understanding")
                        }
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Energy / Engagement")
                            .font(.subheadline)
                        Slider(value: $engagement, in: 0...100, step: 5) {
                            Text("Engagement")
                        }
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes for Future You") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .navigationTitle("Class Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCheckIn()
                    }
                }
            }
            .onAppear {
                preselectClassFromBlock()
                loadExistingCheckInIfAny()
            }
        }
    }
    
    private var availableClasses: [StudentClass] {
        (try? JSONDecoder().decode([StudentClass].self, from: studentClassesData)) ?? []
    }
    
    private var checkInDate: Date {
        Calendar.current.startOfDay(for: block.startTime)
    }
    
    private func saveCheckIn() {
        let name = selectedClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            dismiss()
            return
        }
        let u = Int(understanding)
        let e = Int(engagement)
        dataStore.upsertClassCheckIn(
            date: checkInDate,
            classId: selectedClassId,
            className: name,
            understandingScore: u,
            energyScore: e,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }

    private func preselectClassFromBlock() {
        // If a class is already selected, don't override it
        if selectedClassId != nil || !selectedClassName.isEmpty { return }
        // First try to match the block's *title* to a known class name (e.g. "Quant")
        if let match = availableClasses.first(where: { $0.name == block.title }) {
            selectedClassId = match.id
            selectedClassName = match.name
        } else {
            // Next try matching on subject, but ignore generic labels like "Class" or "Activity"
            if !block.subject.isEmpty,
               block.subject != "Class",
               block.subject != "Activity",
               let match = availableClasses.first(where: { $0.name == block.subject }) {
                selectedClassId = match.id
                selectedClassName = match.name
            } else {
                // Fallback: just use the more specific non-empty value as a display name
                if !block.subject.isEmpty, block.subject != "Class", block.subject != "Activity" {
                    selectedClassName = block.subject
                } else {
                    selectedClassName = block.title
                }
            }
        }
    }

    private func loadExistingCheckInIfAny() {
        // Look for an existing check-in for this class on this date and prefill
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: checkInDate)
        // Use the current selectedClassName if set; otherwise try block.subject
        let targetName: String
        if !selectedClassName.isEmpty {
            targetName = selectedClassName
        } else if !block.subject.isEmpty {
            targetName = block.subject
        } else {
            targetName = block.title
        }
        if let existing = dataStore.classCheckIns.first(where: {
            calendar.startOfDay(for: $0.date) == dayStart && $0.className == targetName
        }) {
            selectedClassId = existing.classId
            selectedClassName = existing.className
            understanding = Double(existing.understandingScore)
            engagement = Double(existing.energyScore)
            notes = existing.notes ?? ""
        }
    }
}
// MARK: - Quick Add Study Block Sheet
struct QuickAddStudyBlockSheet: View {
    let selectedDate: Date
    let modelContext: ModelContext
    let userId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var title: String = ""
    @State private var selectedClass: StudentClass? = nil
    @State private var selectedWorkType: String? = nil
    @State private var startTime: Date = Date()
    @State private var duration: Int = 60
    @AppStorage("studentClassesData") private var studentClassesData: Data = Data()
    
    private let durationOptions = [15, 30, 45, 60, 90, 120]
    private let workTypeOptions = ["Test", "Exam", "Assignment"]
    
    private var studentClasses: [StudentClass] {
        guard let decoded = try? JSONDecoder().decode([StudentClass].self, from: studentClassesData) else {
            return []
        }
        return decoded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Study Details") {
                    TextField("What are you studying?", text: $title)
                    
                    // Quick class picker buttons
                    if !studentClasses.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Select:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(studentClasses, id: \.id) { studentClass in
                                        Button(action: {
                                            selectedClass = studentClass
                                        }) {
                                            Text(studentClass.name)
                                                .font(.subheadline)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    selectedClass?.id == studentClass.id ?
                                                    Color(hex: studentClass.color) :
                                                    Color(hex: studentClass.color).opacity(0.2)
                                                )
                                                .foregroundStyle(
                                                    selectedClass?.id == studentClass.id ?
                                                    .white :
                                                    Color(hex: studentClass.color)
                                                )
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Work Type (Optional):")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(workTypeOptions, id: \.self) { type in
                                Button(action: {
                                    if selectedWorkType == type {
                                        selectedWorkType = nil
                                    } else {
                                        selectedWorkType = type
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: iconForWorkType(type))
                                            .font(.system(size: 12))
                                        Text(type)
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedWorkType == type ?
                                        colorForWorkType(type) :
                                        colorForWorkType(type).opacity(0.15)
                                    )
                                    .foregroundStyle(
                                        selectedWorkType == type ?
                                        .white :
                                        colorForWorkType(type)
                                    )
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { mins in
                            Text("\(mins) min").tag(mins)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Button(action: saveBlock) {
                        HStack {
                            Spacer()
                            Text("Add Study Block")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Custom Study Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Set start time to selected date with rounded hour
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: selectedDate)
                if let rounded = calendar.date(from: components) {
                    startTime = calendar.date(byAdding: .hour, value: 1, to: rounded) ?? selectedDate
                }
            }
        }
    }
    
    private func saveBlock() {
        let calendar = Calendar.current
        
        // Combine selected date with chosen time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        guard let finalStartTime = calendar.date(from: dateComponents) else { return }
        
        let customBlock = CustomStudyBlockSD(
            title: title,
            className: selectedClass?.name,
            workType: selectedWorkType,
            startTime: finalStartTime,
            duration: duration,
            userId: userId
        )
        
        modelContext.insert(customBlock)
        try? modelContext.save()
        
        // If workType is selected, also add to assignments page
        if let workType = selectedWorkType {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d/yy h:mm a"
            let timeString = dateFormatter.string(from: finalStartTime)
            
            // Map workType to plural category format
            let category: String
            switch workType {
            case "Test": category = "Tests"
            case "Exam": category = "Exams"
            case "Assignment": category = "Assignments"
            default: category = "Assignments"
            }
            
            dataStore.addEvent(
                title: title,
                start: finalStartTime,
                end: finalStartTime,
                category: category,
                timeString: timeString,
                className: selectedClass?.name
            )
        }
        
        dismiss()
        
        // Delay to allow SwiftData query to update before regenerating schedule
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSave()
        }
    }
    
    private func iconForWorkType(_ type: String) -> String {
        switch type {
        case "Test": return "doc.text"
        case "Exam": return "graduationcap.fill"
        case "Assignment": return "pencil.and.list.clipboard"
        default: return "circle"
        }
    }
    
    private func colorForWorkType(_ type: String) -> Color {
        switch type {
        case "Test": return .orange
        case "Exam": return .red
        case "Assignment": return .blue
        default: return .gray
        }
    }
}

// MARK: - Study Block Model
struct StudyBlock: Identifiable {
    let id: UUID
    let title: String
    let subject: String
    let startTime: Date
    let duration: Int // minutes
    let dueDate: Date?
    let daysUntilDue: Int?
    let priority: StudyPriority
    let strategy: String
    let type: String
    let classColorHex: String?
    var isCompact: Bool = false // For classes/activities - show in compact format
}

enum StudyPriority: String {
    case urgent = "urgent"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

struct TimeSlot {
    let start: Date
    let label: String
}

// Safe array subscript extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack { CalendarView() }
}
