//
//  SessionDebugView.swift
//  MixFix
//
//  Debug view to show session breakdown and why recommended time is calculated
//

import SwiftUI

struct SessionDebugView: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var stats: StudySessionStats = .empty
    @State private var last7DaysSessions: [StudySessionLog] = []
    
    var body: some View {
        NavigationStack {
            List {
                // Current Recommendation
                Section("Current Recommendation") {
                    HStack {
                        Text("Recommended Today")
                        Spacer()
                        Text("\(Int(sessionManager.recommendedStudyMinutesToday)) min")
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    HStack {
                        Text("Actual Today")
                        Spacer()
                        Text("\(sessionManager.todayStudyMinutes) min")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    HStack {
                        Text("Updating")
                        Spacer()
                        if sessionManager.isUpdating {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                // 7-Day Statistics
                Section("Last 7 Days Stats") {
                    HStack {
                        Text("Total Minutes")
                        Spacer()
                        Text("\(stats.last7DaysMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Session Count")
                        Spacer()
                        Text("\(stats.sessionCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Avg Daily")
                        Spacer()
                        Text("\(Int(stats.avgDailyMinutes)) min/day")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Avg Session Length")
                        Spacer()
                        Text("\(Int(stats.avgSessionLength)) min")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Completion Rate")
                        Spacer()
                        Text("\(Int(stats.completionRate * 100))%")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Last 3 Days (Higher Weight)
                Section("Last 3 Days (70% weight)") {
                    HStack {
                        Text("Total Minutes")
                        Spacer()
                        Text("\(stats.last3DaysMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Recent Sessions
                Section("Recent Sessions (Last 7 Days)") {
                    if last7DaysSessions.isEmpty {
                        Text("No sessions yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(last7DaysSessions) { session in
                            SessionRowView(session: session)
                        }
                    }
                }
                
                // Edge Cases
                Section("System Info") {
                    HStack {
                        Text("Min Daily")
                        Spacer()
                        Text("30 min")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Max Daily")
                        Spacer()
                        Text("360 min (6 hrs)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Max Change Per Day")
                        Spacer()
                        Text("±20%")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Smoothing Factor")
                        Spacer()
                        Text("30% new, 70% old")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Session Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await sessionManager.refreshStats()
                            await loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        stats = sessionManager.getDetailedStats()
        last7DaysSessions = sessionManager.getSessionsForLastDays(7)
    }
}

// MARK: - Session Row
struct SessionRowView: View {
    let session: StudySessionLog
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dateFormatter.string(from: session.startTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(session.durationMinutes) min")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            HStack {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text(session.status.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .cornerRadius(4)
                
                if let preset = session.timerPreset {
                    Text(preset)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if session.plannedDurationMinutes > 0 {
                    Text("\(Int(session.completionRate * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var statusIcon: String {
        switch session.status {
        case .completed: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle"
        case .paused: return "pause.circle"
        case .autoEnded: return "clock.fill"
        }
    }
    
    private var statusColor: Color {
        switch session.status {
        case .completed: return .green
        case .abandoned: return .red
        case .paused: return .orange
        case .autoEnded: return .gray
        }
    }
}
