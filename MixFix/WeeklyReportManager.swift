import Foundation
import SwiftData
import Combine

@MainActor
final class WeeklyReportManager: ObservableObject {
    static let shared = WeeklyReportManager()
    
    private let calendar = Calendar.current
    private var modelContext: ModelContext? { DataStoreAccessor.shared.modelContext }
    
    func generateReportIfNeeded(for referenceDate: Date = Date()) {
        guard let modelContext = modelContext else { return }
        let week = weekBounds(for: referenceDate.addingTimeInterval(-7 * 24 * 60 * 60))
        let weekStart = week.start
        let weekEnd = week.end
        // Check if a report already exists for this week
        let descriptor = FetchDescriptor<WeeklyReportSD>()
        if let existing = try? modelContext.fetch(descriptor),
           existing.contains(where: { $0.weekStartDate == weekStart && $0.weekEndDate == weekEnd }) {
            return
        }
        // For now, just create metadata record; aggregation UI can compute on the fly later.
        let report = WeeklyReportSD(weekStartDate: week.start, weekEndDate: week.end)
        modelContext.insert(report)
        try? modelContext.save()
    }
    
    func fetchAllReports() -> [WeeklyReportSD] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<WeeklyReportSD>(sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func markViewed(_ report: WeeklyReportSD) {
        guard let modelContext = modelContext else { return }
        report.isViewed = true
        try? modelContext.save()
    }
    
    private func weekBounds(for date: Date) -> (start: Date, end: Date) {
        // Define week as Monday-Sunday in user locale
        var calendar = calendar
        calendar.firstWeekday = 2 // Monday
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return (weekStart, weekEnd)
    }
}

@MainActor
final class DataStoreAccessor {
    static let shared = DataStoreAccessor()
    var modelContext: ModelContext?
}
